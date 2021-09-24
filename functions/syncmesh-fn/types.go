package function

import (
	"github.com/graphql-go/graphql"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"time"
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
		"timestamp": &graphql.Field{
			Type: graphql.DateTime,
		},
	},
})

// AveragesType as the response of a db-side aggregation
var AveragesType = graphql.NewObject(graphql.ObjectConfig{
	Name: "SensorAverages",
	Fields: graphql.Fields{
		"average_humidity": &graphql.Field{
			Type: graphql.Float,
		},
		"average_pressure": &graphql.Field{
			Type: graphql.Float,
		},
		"average_temperature": &graphql.Field{
			Type: graphql.Float,
		},
	},
})

// SensorModel struct of a sensor measurement in the database
type SensorModel struct {
	ID          primitive.ObjectID `bson:"_id" json:"_id,omitempty"`
	Lat         float64            `bson:"lat" json:"lat,omitempty"`
	Lon         float64            `bson:"lon" json:"lon,omitempty"`
	Pressure    float64            `bson:"pressure" json:"pressure,omitempty"`
	Temperature float64            `bson:"temperature" json:"temperature,omitempty"`
	Humidity    float64            `bson:"humidity" json:"humidity,omitempty"`
	Timestamp   time.Time          `bson:"timestamp" json:"timestamp,omitempty"`
}

// SensorModelNoId is the same struct of a sensor, but without an ID
type SensorModelNoId struct {
	Lat         float64   `bson:"lat" json:"lat,omitempty"`
	Lon         float64   `bson:"lon" json:"lon,omitempty"`
	Pressure    float64   `bson:"pressure" json:"pressure,omitempty"`
	Temperature float64   `bson:"temperature" json:"temperature,omitempty"`
	Humidity    float64   `bson:"humidity" json:"humidity,omitempty"`
	Timestamp   time.Time `bson:"timestamp" json:"timestamp,omitempty"`
}

// SyncMeshRequest is the structure of the request the syncmesh function receives
type SyncMeshRequest struct {
	Query         string                 `json:"query"`
	Database      string                 `json:"database"`
	Collection    string                 `json:"collection"`
	Type          string                 `json:"request_type,omitempty"`
	Radius        int                    `json:"radius"`
	UseMetaData   bool                   `json:"use_meta_data"`
	Variables     map[string]interface{} `json:"variables,omitempty"`
	ExternalNodes []string               `json:"external_nodes,omitempty"`
}

// SyncmeshMetaRequest represents meta requests to the function for managing saved nodes
type SyncmeshMetaRequest struct {
	Type string       `json:"meta_type"`
	ID   string       `json:"id,omitempty"`
	Node SyncmeshNode `json:"node,omitempty"`
}

// DocKey is a unique ID of a document
type DocKey struct {
	ID string `bson:"_id"`
}

// A StreamEvent is a type returned by the database event listener containing the change and operation type
type StreamEvent struct {
	OperationType string                 `bson:"operationType"` // can be "insert", "update" or "delete"
	FullDocument  map[string]interface{} `bson:"fullDocument"`
	DocumentKey   DocKey                 `bson:"documentKey"`
}

// The SensorResponse is a list of sensors without an ID
type SensorResponse struct {
	Sensors  []SensorModelNoId `json:"sensors"`
	Averages AveragesResponse  `json:"sensorsAggregate"`
}

// The GraphQLResponse returned by a GraphQL query
type GraphQLResponse struct {
	Data SensorResponse `json:"data"`
}

// AveragesResponse is returned in case of data aggregation
type AveragesResponse struct {
	AverageHumidity    float64 `json:"average_humidity"`
	AverageTemperature float64 `json:"average_temperature"`
	AveragePressure    float64 `json:"average_pressure"`
}

// SyncmeshNode specifies an external or internal node entry in the database
type SyncmeshNode struct {
	ID         string  `bson:"_id" json:"_id"`
	Address    string  `bson:"address" json:"address"`
	Lat        float64 `bson:"lat" json:"lat,omitempty"`
	Lon        float64 `bson:"lon" json:"lon,omitempty"`
	Distance   float64 `bson:"distance" json:"distance,omitempty"`
	OwnNode    bool    `bson:"own_node" json:"own_node"`
	Subscribed bool    `bson:"subscribed" json:"subscribed"`
}

// mongoDB represents a mongoDB client with corresponding collection
type mongoDB struct {
	session    *mongo.Client
	collection *mongo.Collection
}
