package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"net/http"
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
		log.Println("MongoDB url not found, defaulting to localhost")
		mongoUrl = "localhost:27017/?directConnection=true" // default mongodb location if no env passed
	}
	syncmeshBaseUrl, present := os.LookupEnv("syncmesh_url")
	if !present {
		log.Println("Syncmesh function base url not found, defaulting to localhost")
		mongoUrl = "localhost:8080" // default mongodb location if no env passed
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
		url := fmt.Sprintf("%s/functions/syncmesh-fn", syncmeshBaseUrl)
		jsonBody, err := json.Marshal(&data)
		stopFatal(err)
		_, err = http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
		stopFatal(err)
	}
}

// logPanic is a fatal log if the error is not nil
func stopFatal(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
