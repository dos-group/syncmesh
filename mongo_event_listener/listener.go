package main

import (
	"context"
	"fmt"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"os"
)

type DocKey struct {
	ID string `bson:"_id"`
}

type StreamEvent struct {
	OperationType string                 `bson:"operationType"` // can be "insert", "update" or "delete"
	FullDocument  map[string]interface{} `bson:"fullDocument"`
	DocumentKey   DocKey                 `bson:"documentKey"`
}

func main() {
	ctx := context.Background()
	// check mongodb value
	mongoUrl, present := os.LookupEnv("mongo_url")
	if !present {
		log.Println("MongoDB url not found, defaulting to namespace")
		mongoUrl = "localhost:27017/?directConnection=true" // default mongodb location if no env passed
	}
	uri := fmt.Sprintf("mongodb://%s", mongoUrl)
	log.Println(uri)
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	stopFatal(err)

	opts := options.ChangeStream().SetFullDocument("updateLookup")
	sensors := client.Database("syncmesh").Collection("sensor_data")
	sensorStream, err := sensors.Watch(ctx, mongo.Pipeline{}, opts)
	stopFatal(err)
	defer func(sensorStream *mongo.ChangeStream, ctx context.Context) {
		err := sensorStream.Close(ctx)
		if err != nil {
			log.Fatal(err)
		}
	}(sensorStream, ctx)

	for sensorStream.Next(ctx) {
		var data StreamEvent
		err := sensorStream.Decode(&data)
		stopFatal(err)
		fmt.Printf("%v\n", data) // TODO: request after each change to syncmesh-fn
	}
}

// logPanic is a fatal log if the error is not nil
func stopFatal(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
