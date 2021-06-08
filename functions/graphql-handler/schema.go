package function

import (
	"log"

	"github.com/graphql-go/graphql"
)

// Init the schema of GraphQL
func initSchema() graphql.Schema {
	graphqlSchema, err := graphql.NewSchema(graphql.SchemaConfig{
		Query: graphql.NewObject(graphql.ObjectConfig{
			Name: "Query",
			Fields: graphql.Fields{
				"getAllUsers": &graphql.Field{
					Type:    graphql.NewList(UserType),
					Args:    graphql.FieldConfigArgument{},
					Resolve: getUsers,
				},
				"getUser": &graphql.Field{
					Type: UserType,
					Args: graphql.FieldConfigArgument{
						"_id": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.ID),
						}},
					Resolve: getUser,
				},
			},
		}),
		Mutation: graphql.NewObject(graphql.ObjectConfig{
			Name: "Mutation",
			Fields: graphql.Fields{
				"addUser": &graphql.Field{
					Type: UserType,
					Args: graphql.FieldConfigArgument{
						"name": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.String),
						},
						"surname": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.String),
						}},
					Resolve: addUser,
				},
				"deleteUser": &graphql.Field{
					Type: UserType,
					Args: graphql.FieldConfigArgument{
						"_id": &graphql.ArgumentConfig{
							Type: graphql.NewNonNull(graphql.ID),
						}},
					Resolve: deleteUser,
				}},
		}),
		Types: []graphql.Type{graphql.ID},
	})
	if err != nil {
		log.Fatal(err)
	}
	return graphqlSchema

}
