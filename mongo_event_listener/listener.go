package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

type DocKey struct {
	ID string `bson:"_id"`
}

type StreamEvent struct {
	OperationType string                 `bson:"operationType" json:"operationType"` // can be "insert", "update" or "delete"
	FullDocument  map[string]interface{} `bson:"fullDocument" json:"fullDocument"`
	DocumentKey   DocKey                 `bson:"documentKey" json:"documentKey"`
}

// main is a running change stream listener for mongodb change events in the default collection (syncmesh/sensor_data)
func main() {
	log.Println("Starting mongoDB change stream listener...")
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
		syncmeshBaseUrl = "http://localhost:8080" // default mongodb location if no env passed
	}
	uri := fmt.Sprintf("mongodb://%s", mongoUrl)
	log.Printf("Full mongodb url: %s", uri)
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
		fmt.Printf("%v\n", data)
		url := fmt.Sprintf("%s/function/syncmesh-fn", syncmeshBaseUrl)
		jsonBody, err := json.Marshal(&data)
		stopFatal(err)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
		stopFatal(err)
		req.Header.Set("Content-Type", "application/json")
		client := &http.Client{}
		resp, err := client.Do(req)
		stopFatal(err)
		log.Printf("Response status code %v", resp.StatusCode)
		body, err := ioutil.ReadAll(resp.Body)
		stopFatal(err)
		err = resp.Body.Close()
		stopFatal(err)
		log.Println(string(body))
	}
}

// stopFatal is a fatal log if the error is not nil
func stopFatal(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
