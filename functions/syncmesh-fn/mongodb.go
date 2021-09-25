package function

import (
	"context"
	"fmt"
	"log"
	"os"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// connectDB for connecting to the database with a specified db name and collection
func connectDB(ctx context.Context, db string, collection string) mongoDB {
	if len(db) == 0 || len(collection) == 0 {
		log.Fatal("Database and collection need to be specified")
	}
	// check mongodb value
	mongoUrl, present := os.LookupEnv("mongo_url")
	if !present {
		log.Println("MongoDB url not found, defaulting to namespace")
		mongoUrl = "openfaas-db-mongodb" // default mongodb kubernetes namespace if no env passed
	}
	uri := fmt.Sprintf("mongodb://%s", mongoUrl)
	log.Printf("MongoDB access url: %s", uri)
	// attempt connecting to mongodb
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatal(err)
	}
	// attempt performing a ping to check if database working
	err = client.Ping(context.Background(), nil)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Connected to MongoDB")
	// return a session and the collection of the mongodb instance
	return mongoDB{
		session:    client,
		collection: client.Database(db).Collection(collection),
	}
}

// closeDB to disconnect and close the session
func (db mongoDB) closeDB() {
	err := db.session.Disconnect(context.Background())
	if err != nil {
		log.Fatal(err)
	}
}
