package function

import (
	"github.com/graphql-go/graphql"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SensorType containing location, pressure and humidity data
var SensorType = graphql.NewObject(graphql.ObjectConfig{
	Name: "Sensor",
	Fields: graphql.Fields{
		"_id": &graphql.Field{
			Type: graphql.ID,
		},
		"lat": &graphql.Field{
			Type: graphql.Float,
		},
		"lon": &graphql.Field{
			Type: graphql.Float,
		},
		"pressure": &graphql.Field{
			Type: graphql.Float,
		},
		"temperature": &graphql.Field{
			Type: graphql.Float,
		},
		"humidity": &graphql.Field{
			Type: graphql.Float,
		},
	},
})

// SensorModel struct for parsing json/bson objects
type SensorModel struct {
	ID          primitive.ObjectID `bson:"_id" json:"_id,omitempty"`
	Name        string             `bson:"name" json:"name,omitempty"`
	Surname     string             `bson:"surname" json:"surname,omitempty"`
	Lat         float64            `bson:"lat" json:"lat,omitempty"`
	Lon         float64            `bson:"lon" json:"lon,omitempty"`
	Pressure    float64            `bson:"pressure" json:"pressure,omitempty"`
	Temperature float64            `bson:"temperature" json:"temperature,omitempty"`
	Humidity    float64            `bson:"humidity" json:"humidity,omitempty"`
}
