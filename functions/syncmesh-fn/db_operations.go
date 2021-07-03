package function

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
	"time"
)

func (db mongoDB) getSensors(limit int) (interface{}, error) {
	var sensors []SensorModel
	var err error

	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	cur, err := db.collection.Find(ctx, bson.D{}, options.Find().SetLimit(int64(limit)))
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

func (db mongoDB) getSensorsInTimeRange(startTime primitive.DateTime, endTime primitive.DateTime, limit int) (interface{}, error) {
	var sensors []SensorModel
	var err error

	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	cur, err := db.collection.Find(ctx, bson.M{
		"sale_date": bson.M{
			"$gt": startTime,
			"$lt": endTime,
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
