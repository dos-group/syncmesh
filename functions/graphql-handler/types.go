package function

import (
	"github.com/graphql-go/graphql"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

var UserType = graphql.NewObject(graphql.ObjectConfig{
	Name: "User",
	Fields: graphql.Fields{
		"_id": &graphql.Field{
			Type: graphql.ID,
		},
		"name": &graphql.Field{
			Type: graphql.String,
		},
		"surname": &graphql.Field{
			Type: graphql.String,
		},
	},
})

type UserModel struct {
	ID      primitive.ObjectID `bson:"_id" json:"_id,omitempty"`
	Name    string             `bson:"name" json:"name,omitempty"`
	Surname string             `bson:"surname" json:"surname,omitempty"`
}
