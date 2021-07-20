package function

import (
	"bytes"
	"context"
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
	UseMetaData   bool                   `json:"use_meta_data"`
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

	parseError := handler.Response{
		Body:       []byte("Error parsing the request"),
		StatusCode: http.StatusInternalServerError,
	}

	responseMap := make(map[string]interface{})
	err = json.Unmarshal(req.Body, &responseMap)
	if err != nil {
		return parseError, err
	}

	// if the request is a meta request, handle the operation and return
	if _, ok := responseMap["meta_type"]; ok {
		metaRequest := SyncmeshMetaRequest{}
		err = json.Unmarshal(req.Body, &metaRequest)
		if err != nil {
			return parseError, err
		}
		metaResponse, err := handleMetaRequest(req.Context(), metaRequest)
		if err != nil {
			return handler.Response{
				Body:       []byte(err.Error()),
				StatusCode: http.StatusInternalServerError,
			}, err
		}
		// encode the meta query result from bson to a bytes buffer
		b := new(bytes.Buffer)
		err = json.NewEncoder(b).Encode(metaResponse)
		return handler.Response{
			Body:       []byte(b.String()),
			StatusCode: http.StatusOK,
		}, err
	}

	// if the request is a meta request, handle the operation and return
	if _, ok := responseMap["operationType"]; ok {
		event := StreamEvent{}
		err = json.Unmarshal(req.Body, &event)
		if err != nil {
			return parseError, err
		}
		eventResponse, err := handleStreamEvent(req.Context(), event)
		if err != nil {
			return handler.Response{
				Body:       []byte(err.Error()),
				StatusCode: http.StatusInternalServerError,
			}, err
		}
		// encode the meta query result from bson to a bytes buffer
		b := new(bytes.Buffer)
		err = json.NewEncoder(b).Encode(eventResponse)
		return handler.Response{
			Body:       []byte(b.String()),
			StatusCode: http.StatusOK,
		}, err
	}

	// convert the http request to a SyncMesh request
	request := SyncMeshRequest{}
	err = json.Unmarshal(req.Body, &request)
	if err != nil {
		return parseError, err
	}
	log.Printf("Request: %v", request)

	if request.UseMetaData {
		combineExternalNodes(&request, req.Context())
		log.Printf("Exernal nodes: %v", request.ExternalNodes)
	}

	// connect to mongodb
	db = connectDB(req.Context(), request.Database, request.Collection)
	defer db.closeDB()

	// execute graphql query on own node
	result := executeQuery(request.Query, initSchema(), request.Variables)

	// encode the query result from bson to a bytes buffer
	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(result)
	if err != nil {
		return handleEncodingError(err)
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
			return handleEncodingError(err)
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

func combineExternalNodes(request *SyncMeshRequest, ctx context.Context) {
	db := getSyncmeshDB(ctx)
	savedNodes, err := db.getSyncmeshNodes()
	if err != nil {
		log.Printf(err.Error())
	}
	for _, node := range savedNodes {
		request.ExternalNodes = append(request.ExternalNodes, node.Address)
	}
	defer db.closeDB()
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

func handleEncodingError(err error) (handler.Response, error) {
	return handler.Response{
		Body:       []byte("Something went wrong encoding the result"),
		StatusCode: http.StatusInternalServerError,
	}, err
}
