package function

import (
	"log"

	"github.com/graphql-go/graphql"
)

// Init the schema of Sensor data in GraphQL
func initSchema() graphql.Schema {
	graphqlSchema, err := graphql.NewSchema(graphql.SchemaConfig{
		Query: graphql.NewObject(graphql.ObjectConfig{
			Name: "Query",
			Fields: graphql.Fields{
				"sensors": &graphql.Field{
					Type:    graphql.NewList(SensorType),
					Args:    graphql.FieldConfigArgument{},
					Resolve: getSensors,
				},
				"sensor": &graphql.Field{
					Type: SensorType,
					Args: graphql.FieldConfigArgument{
						"_id": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.ID),
						}},
					Resolve: getSensor,
				},
				"sensorsInTimeRange": &graphql.Field{
					Type: graphql.NewList(SensorType),
					Args: graphql.FieldConfigArgument{
						"start_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						},
						"end_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						}},
					Resolve: getSensorsInTimeRange,
				},
			},
		}),
		Types: []graphql.Type{graphql.ID},
	})
	if err != nil {
		log.Fatal(err)
	}
	return graphqlSchema
}
