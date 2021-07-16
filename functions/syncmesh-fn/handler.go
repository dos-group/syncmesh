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
	Query         string                 `json:"query"`
	Database      string                 `json:"database"`
	Collection    string                 `json:"collection"`
	Type          string                 `json:"request_type,omitempty"`
	Variables     map[string]interface{} `json:"variables,omitempty"`
	ExternalNodes []string               `json:"external_nodes,omitempty"`
}

type SyncmeshMetaRequest struct {
	Type string       `json:"meta_type"`
	ID   string       `json:"id,omitempty"`
	Node SyncmeshNode `json:"node,omitempty"`
}

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	var err error
	var metaResponse interface{}

	// if the request is a meta request, handle the operation and return
	metaRequest := SyncmeshMetaRequest{}
	err = json.Unmarshal(req.Body, &metaRequest)
	if err == nil {
		metaResponse, err = handleMetaRequest(req.Context(), metaRequest)
		if err != nil {
			return handler.Response{
				Body:       []byte(err.Error()),
				StatusCode: http.StatusInternalServerError,
			}, err
		}
		// encode the query result from bson to a bytes buffer
		b := new(bytes.Buffer)
		err = json.NewEncoder(b).Encode(metaResponse)
		return handler.Response{
			Body:       []byte(b.String()),
			StatusCode: http.StatusOK,
		}, err
	}

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

	// execute graphql query on own node
	result := executeQuery(request.Query, initSchema(), request.Variables)

	// encode the query result from bson to a bytes buffer
	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(result)
	if err != nil {
		return catchResponseError(err)
	}

	// if the request type is aggregate, calculate the averages from the data
	if request.Type == "aggregate" {
		// convert response to response struct
		out := GraphQLResponse{}
		err = json.Unmarshal([]byte(b.String()), &out)
		if err != nil {
			log.Fatal(err)
		}
		averages := calculateSensorAverages(out.Data.Sensors)
		b.Reset()
		err = json.NewEncoder(b).Encode(averages)
		if err != nil {
			return catchResponseError(err)
		}
	}

	// if external nodes specified, attempt to fetch external data
	if len(request.ExternalNodes) > 0 {
		b = handleSyncMeshRequest(request, b.String())
	}

	// return the query result
	return handler.Response{
		Body:       []byte(b.String()),
		StatusCode: http.StatusOK,
	}, err
}

func calculateSensorAverages(sensors []SensorModelNoId) AveragesResponse {
	final := AveragesResponse{AveragePressure: 0, AverageTemperature: 0, AverageHumidity: 0}
	size := float64(len(sensors))
	// sum all values
	for _, item := range sensors {
		final.AverageHumidity += item.Humidity
		final.AverageTemperature += item.Temperature
		final.AveragePressure += item.Pressure
	}
	// calculate the averages
	final.AverageHumidity /= size
	final.AverageTemperature /= size
	final.AveragePressure /= size
	return final
}

func executeQuery(query string, schema graphql.Schema, vars map[string]interface{}) *graphql.Result {
	result := graphql.Do(graphql.Params{
		Schema:         schema,
		RequestString:  query,
		VariableValues: vars,
	})
	if len(result.Errors) > 0 {
		fmt.Printf("Unexpected errors: %v", result.Errors)
	}
	return result
}

func catchResponseError(err error) (handler.Response, error) {
	return handler.Response{
		Body:       []byte("Something went wrong encoding the result"),
		StatusCode: http.StatusInternalServerError,
	}, err
}
