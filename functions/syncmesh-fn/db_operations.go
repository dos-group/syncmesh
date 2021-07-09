package function

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"time"
)

func (db mongoDB) getSensorsInTimeRange(startTime time.Time, endTime time.Time, limit int) (interface{}, error) {
	var sensors []SensorModel
	var err error

	ctx, _ := context.WithTimeout(context.Background(), 90*time.Second)
	cur, err := db.collection.Find(ctx, bson.M{
		"timestamp": bson.M{
			"$gte": startTime,
			"$lte": endTime,
		},
	}, options.Find().SetLimit(int64(limit)))
	if err != nil {
		return nil, err
	}
	for cur.Next(ctx) {
		var sensor SensorModel
		err = cur.Decode(&sensor)
		if err != nil {
			return nil, err
		}
		sensors = append(sensors, sensor)
	}
	if err = cur.Err(); err != nil {
		return nil, err
	}
	err = cur.Close(ctx)
	if err != nil {
		return nil, err
	}
	return sensors, nil
}

func (db mongoDB) getSensor(_id string) (interface{}, error) {
	var sensor SensorModel
	var err error

	id, err := primitive.ObjectIDFromHex(_id)
	if err != nil {
		return nil, err
	}
	q := bson.M{"_id": id}
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	err = db.collection.FindOne(ctx, q).Decode(&sensor)
	if err != nil {
		return nil, err
	}
	return sensor, nil
}

func (db mongoDB) deleteSensorById(_id string) (interface{}, error) {
	var sensor SensorModel
	var err error

	id, err := primitive.ObjectIDFromHex(_id)
	if err != nil {
		return nil, err
	}
	q := bson.M{"_id": id}
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	err = db.collection.FindOneAndDelete(ctx, q).Decode(&sensor)
	if err != nil {
		return nil, err
	}
	return sensor, nil
}

func (db mongoDB) createSensors(sensors []SensorModelNoId) (interface{}, error) {
	// convert sensor model structs to generic interfaces
	docs := make([]interface{}, len(sensors))
	for i := range sensors {
		docs[i] = sensors[i]
	}

	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	res, err := db.collection.InsertMany(ctx, docs, options.InsertMany().SetOrdered(false))
	if err != nil {
		log.Fatal(err)
	}
	return res.InsertedIDs, nil
}

// TODO: operation to fetch approximate amount of docs inside db
