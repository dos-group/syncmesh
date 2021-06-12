package function

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/graphql-go/graphql"
	handler "github.com/openfaas/templates-sdk/go-http"
	"net/http"
)

var db mongoDB

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	var err error

	// connect to mongodb
	db = connectDB()
	defer db.closeDB()

	// execute graphql query
	result := executeQuery(string(req.Body), initSchema())

	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(result)
	if err != nil {
		return handler.Response{
			Body:       []byte("Something went wrong"),
			StatusCode: http.StatusInternalServerError,
		}, err
	}

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
