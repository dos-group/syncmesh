package function

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/graphql-go/graphql"
	handler "github.com/openfaas/templates-sdk/go-http"
	"log"
	"net/http"
)

var db mongoDB

type SyncMeshRequest struct {
	Query      string `json:"query"`
	Database   string `json:"database"`
	Collection string `json:"collection"`
}

// Handle a function invocation
/**
Example request (picking JSON in OpenFaaS is important):
{
"query": "{getAllUsers{name}}",
"database": "demo",
"collection": "users"
}
*/
func Handle(req handler.Request) (handler.Response, error) {
	var err error

	// convert the http request to a SyncMesh request
	request := SyncMeshRequest{}
	err = json.Unmarshal(req.Body, &request)
	if err != nil {
		return handler.Response{
			Body:       []byte("Error parsing the request"),
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	log.Printf("Request: %v", request)

	// connect to mongodb
	db = connectDB(req.Context(), request.Database, request.Collection)
	defer db.closeDB()

	// execute graphql query
	result := executeQuery(request.Query, initSchema())

	// encode the query result from bson to a bytes buffer
	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(result)
	if err != nil {
		return handler.Response{
			Body:       []byte("Something went wrong"),
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	// return the query result
	return handler.Response{
		Body:       []byte(b.String()),
		StatusCode: http.StatusOK,
	}, err
}

func executeQuery(query string, schema graphql.Schema) *graphql.Result {
	result := graphql.Do(graphql.Params{
		Schema:        schema,
		RequestString: query,
	})
	if len(result.Errors) > 0 {
		fmt.Printf("Unexpected errors: %v", result.Errors)
	}
	return result
}
