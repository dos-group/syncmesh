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
	"os"
	"strings"
)

var db mongoDB

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	var err error

	responseMap := make(map[string]interface{})
	err = json.Unmarshal(req.Body, &responseMap)
	if err != nil {
		return functionResponse(err.Error(), err)
	}

	// handle the request depending on its type
	switch requestType := getRequestType(responseMap); requestType {
	case Meta:
		return handleSpecialRequest(req, true)
	case Event:
		return handleSpecialRequest(req, false)
	default:
		break
	}

	// convert the http request to a SyncMesh request
	request := SyncMeshRequest{}
	err = json.Unmarshal(req.Body, &request)
	if err != nil {
		return functionResponse(err.Error(), err)
	}
	log.Printf("Request: %v", request)

	// set default collection and db if not given
	if request.Database == "" {
		request.Database = DefaultDB
	}
	if request.Collection == "" {
		request.Collection = DefaultCollection
	}

	if request.UseMetaData {
		combineExternalNodes(&request, req.Context())
		log.Printf("Exernal nodes: %v", request.ExternalNodes)
	}

	// connect to mongodb
	db = connectDB(req.Context(), request.Database, request.Collection)
	defer db.closeDB()

	// if request is aggregate, force the aggregation by replacing the query to aggregate
	if !strings.Contains(request.Query, "sensorsAggregate") && request.Type == "aggregate" {
		request.Query = strings.Replace(request.Query, "sensors", "sensorsAggregate", 1)
		request.Query = strings.Replace(request.Query, "humidity", "average_humidity", 1)
		request.Query = strings.Replace(request.Query, "temperature", "average_temperature", 1)
		request.Query = strings.Replace(request.Query, "pressure", "average_pressure", 1)
	}

	// execute graphql query on own node
	result := executeQuery(request.Query, initSchema(), request.Variables)

	// encode the query result from bson to a bytes buffer
	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(result)
	if err != nil {
		return functionResponse(err.Error(), err)
	}

	// if the request type is aggregate, calculate the averages from the data
	if request.Type == "aggregate" {
		// convert response to response struct
		out := GraphQLAveragesResponse{}
		err = json.Unmarshal([]byte(b.String()), &out)
		if err != nil {
			log.Fatal(err)
		}
		averages := out.Data.Averages
		b.Reset()
		err = json.NewEncoder(b).Encode(averages)
		if err != nil {
			return functionResponse(err.Error(), err)
		}
	}

	// if external nodes specified, attempt to fetch external data
	if len(request.ExternalNodes) > 0 {
		b = handleSyncMeshRequest(request, b.String())
	}

	var body []byte
	header := make(http.Header)
	// if gzip enabled, zip the request and add a header, otherwise
	_, present := os.LookupEnv("gzip")
	if !present {
		log.Println("gzip not enabled")
		body = b.Bytes()
	} else {
		log.Println("gzip enabled, zipping request response...")
		// zip the query result
		buffer, err := zip(b.Bytes())
		if err != nil {
			return functionResponse(err.Error(), err)
		}
		body = buffer.Bytes()
		// set a gzip header
		header = http.Header{"Content-Encoding": []string{"gzip"}}
	}

	// return the query result
	return handler.Response{
		Body:       body,
		StatusCode: http.StatusOK,
		Header:     header,
	}, err
}

func handleSpecialRequest(req handler.Request, isMeta bool) (handler.Response, error) {
	var err error
	var resp interface{}
	if isMeta {
		body := SyncmeshMetaRequest{}
		err = json.Unmarshal(req.Body, &body)
		if err != nil {
			return functionResponse(err.Error(), err)
		}
		resp, err = handleMetaRequest(req.Context(), body)
		if err != nil {
			return functionResponse(err.Error(), err)
		}
	} else {
		body := StreamEvent{}
		err = json.Unmarshal(req.Body, &body)
		if err != nil {
			return functionResponse(err.Error(), err)
		}
		resp, err = handleStreamEvent(req.Context(), body)
		if err != nil {
			return functionResponse(err.Error(), err)
		}
	}
	// encode the meta query result from bson to a bytes buffer
	b := new(bytes.Buffer)
	err = json.NewEncoder(b).Encode(resp)
	return functionResponse(b.String(), err)
}

// combineExternalNodes by applying range filtering and sorting by distance
// appends locally stored nodes to those specified in the request
func combineExternalNodes(request *SyncMeshRequest, ctx context.Context) {
	var filteredNodes []SyncmeshNode

	db := getSyncmeshDB(ctx)
	savedNodes, err := db.getSyncmeshNodes()
	if err != nil {
		log.Printf(err.Error())
		return
	}
	err, ownNode, externalNodes := findOwnNode(savedNodes)
	if err == nil && request.Radius > 0 {
		filteredNodes = filterExternalNodes(externalNodes, ownNode, float64(request.Radius))
		for _, node := range filteredNodes {
			// map node to node without ID
			syncmeshNode := SyncmeshNodeNoId{
				Address:    node.Address,
				Lat:        node.Lat,
				Lon:        node.Lon,
				Distance:   node.Distance,
				OwnNode:    node.OwnNode,
				Subscribed: node.Subscribed,
			}
			// update the node in the database for reducing overhead in the future
			_, errUpdate := db.updateCreateNode(syncmeshNode, node.ID)
			if errUpdate != nil {
				log.Printf(errUpdate.Error())
			}
		}
	} else {
		log.Printf(err.Error())
		filteredNodes = savedNodes
	}
	// append the filtered nodes to the external nodes
	for _, node := range filteredNodes {
		request.ExternalNodes = append(request.ExternalNodes, node.Address)
	}
	defer db.closeDB()
}

// execute a GraphQL query on the local mongodb instance
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
