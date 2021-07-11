package function

import (
	"log"

	"github.com/graphql-go/graphql"
)

// Init the schema of Sensor data in GraphQL
func initSchema() graphql.Schema {
	sensorInputType := graphql.NewInputObject(graphql.InputObjectConfig{
		Name: "SensorInputType",
		Fields: graphql.InputObjectConfigFieldMap{
			"timestamp": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.DateTime),
			},
			"humidity": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.Float),
			},
			"temperature": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.Float),
			},
			"pressure": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.Float),
			},
			"lat": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.Float),
			},
			"lon": &graphql.InputObjectFieldConfig{
				Type: graphql.NewNonNull(graphql.Float),
			},
		},
	})
	graphqlSchema, err := graphql.NewSchema(graphql.SchemaConfig{
		Query: graphql.NewObject(graphql.ObjectConfig{
			Name: "Query",
			Fields: graphql.Fields{
				"sensors": &graphql.Field{
					Type: graphql.NewList(SensorType),
					Args: graphql.FieldConfigArgument{
						"start_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						},
						"end_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						}, "limit": &graphql.ArgumentConfig{
							Type: graphql.Int,
						}},
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
				"docEstimate": &graphql.Field{
					Type:    graphql.Int,
					Resolve: getDocEstimate,
				},
			}}),
		Mutation: graphql.NewObject(graphql.ObjectConfig{
			Name: "Mutation",
			Fields: graphql.Fields{
				"deleteSensor": &graphql.Field{
					Type: SensorType,
					Args: graphql.FieldConfigArgument{
						"_id": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.ID),
						}},
					Resolve: deleteSensor,
				},
				"deleteInTimeRange": &graphql.Field{
					Type: graphql.Int,
					Args: graphql.FieldConfigArgument{
						"start_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						},
						"end_time": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.DateTime),
						}},
					Resolve: deleteInTimeRange,
				},
				"update": &graphql.Field{
					Type: sensorInputType,
					Args: graphql.FieldConfigArgument{
						"_id": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.ID),
						},
						"sensor": &graphql.ArgumentConfig{
							Type: sensorInputType,
						}},
					Resolve: update,
				},
				"addSensors": &graphql.Field{
					Type: graphql.NewList(graphql.String),
					Args: graphql.FieldConfigArgument{
						"sensors": &graphql.ArgumentConfig{
							Type: graphql.NewList(sensorInputType),
						}},
					Resolve: createSensors,
				}},
		}),
		Types: []graphql.Type{graphql.ID},
	})
	if err != nil {
		log.Fatal(err)
	}
	return graphqlSchema
}
