package function

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
	"time"
)

func (db mongoDB) getUsers() (interface{}, error) {
	var users []UserModel
	var err error

	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	cur, err := db.users.Find(ctx, bson.D{}, options.Find())
	if err != nil {
		return nil, err
	}
	for cur.Next(ctx) {
		var user UserModel
		err = cur.Decode(&user)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	if err = cur.Err(); err != nil {
		return nil, err
	}
	err = cur.Close(ctx)
	if err != nil {
		return nil, err
	}
	return users, nil
}

func (db mongoDB) getUser(_id string) (interface{}, error) {
	var user UserModel
	var err error

	id, err := primitive.ObjectIDFromHex(_id)
	if err != nil {
		return nil, err
	}
	q := bson.M{"_id": id}
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	err = db.users.FindOne(ctx, q).Decode(&user)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (db mongoDB) addUser(name string, surname string) (interface{}, error) {
	var err error
	var user UserModel

	user.ID = primitive.NewObjectID()
	user.Name = name
	user.Surname = surname
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	_, err = db.users.InsertOne(ctx, user)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (db mongoDB) deleteUser(_id string) (interface{}, error) {
	var err error
	var user UserModel

	id, err := primitive.ObjectIDFromHex(_id)
	if err != nil {
		return nil, err
	}
	q := bson.M{"_id": id}
	ctx, _ := context.WithTimeout(context.Background(), 30*time.Second)
	err = db.users.FindOneAndDelete(ctx, q).Decode(&user)
	if err != nil {
		return nil, err
	}
	return user, nil
}
