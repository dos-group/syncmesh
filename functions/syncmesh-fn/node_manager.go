package function

import (
	"context"
	"errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"strings"
	"time"
)

// handleMetaRequest to manage the querying, updating and deletion of locally stored nodes
func handleMetaRequest(ctx context.Context, request SyncmeshMetaRequest) (interface{}, error) {
	db := getSyncmeshDB(ctx)
	defer db.closeDB()
	switch request.Type {
	case "get":
		return db.getSyncmeshNodes()
	case "update":
		return db.updateCreateNode(request.Node, request.ID)
	case "delete":
		return db.deleteNode(request.ID)
	default:
		return nil, errors.New("no matching operation found. It needs to be either \"get\", \"update\" or \"delete\"")
	}
}

// getSyncmeshDB as an instance of the meta node database
func getSyncmeshDB(ctx context.Context) mongoDB {
	// connect to mongodb external node collection
	metaDB := connectDB(ctx, MetaDB, NodeCollection)
	return metaDB
}

// getSyncmeshNodes and their information currently stored in the meta db
func (db mongoDB) getSyncmeshNodes() ([]SyncmeshNode, error) {
	var err error
	var nodes []SyncmeshNode

	// query all external nodes saved in database
	ctx, _ := context.WithTimeout(context.Background(), 90*time.Second)
	cur, err := db.collection.Find(ctx, bson.D{})
	if err != nil {
		log.Fatal(err)
	}
	for cur.Next(ctx) {
		var node SyncmeshNode
		err = cur.Decode(&node)
		if err != nil {
			continue
		}
		nodes = append(nodes, node)
	}
	if err = cur.Err(); err != nil {
		return nodes, err
	}
	err = cur.Close(ctx)
	return nodes, nil
}

// updateCreateNode updates an external node entry or creates a new one, if it does not exist
func (db mongoDB) updateCreateNode(node SyncmeshNodeNoId, _id string) (interface{}, error) {
	var err error
	var id primitive.ObjectID
	var updatedNode SyncmeshNodeNoId

	if _id == "" {
		id = primitive.NewObjectID()
	} else {
		id, err = primitive.ObjectIDFromHex(_id)
		if err != nil {
			return nil, err
		}
	}

	ctx, _ := context.WithTimeout(context.Background(), 90*time.Second)
	filter := bson.M{"_id": id}
	update := bson.D{{"$set", node}}
	opts := options.FindOneAndUpdate().SetUpsert(true) // insert if no node with id found
	err = db.collection.FindOneAndUpdate(ctx, filter, update, opts).Decode(&updatedNode)
	if err != nil {
		if strings.Contains(err.Error(), "no documents in result") {
			return "new document created", nil
		}
		return nil, err
	}
	return updatedNode, nil
}

// deleteNode using its id
func (db mongoDB) deleteNode(_id string) (interface{}, error) {
	var node SyncmeshNode
	var err error

	id, err := primitive.ObjectIDFromHex(_id)
	if err != nil {
		return nil, err
	}
	q := bson.M{"_id": id}
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	err = db.collection.FindOneAndDelete(ctx, q).Decode(&node)
	if err != nil {
		return nil, err
	}
	return node, nil
}
