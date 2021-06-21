package function

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
)

//handleSyncMeshRequest by instantiating one of the request types
func handleSyncMeshRequest(request SyncMeshRequest, ownResponse string) *bytes.Buffer {
	b := new(bytes.Buffer)
	switch request.Type {
	case "aggregate":
		startAggregating(request, ownResponse, b)
	case "collect":
		startCollecting(request, ownResponse, b)
	}
	return b
}

type SensorResponse struct {
	sensors []SensorModel
}

type GraphQLResponse struct {
	data SensorResponse
}

//startCollecting the data from external nodes
func startCollecting(request SyncMeshRequest, ownResponse string, b *bytes.Buffer) {
	combinedResponse := ownResponse
	//start iterating through all external nodes
	for _, address := range request.ExternalNodes {
		//prepare SyncMesh Request body for the external request
		requestStruct := &SyncMeshRequest{Query: request.Query, Database: request.Database, Collection: request.Collection}
		jsonBody, err := json.Marshal(requestStruct)
		if err != nil {
			log.Println(err)
			continue
		}
		//make a POST request to external nodes, fetching the data
		req, err := http.NewRequest("POST", address, bytes.NewBuffer(jsonBody))
		if err != nil {
			log.Println(err)
			continue
		}
		req.Header.Set("Content-Type", "application/json")
		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			log.Println(err)
			continue
		}

		//read the response
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Println(err)
			continue
		}
		// convert response to response struct
		out := GraphQLResponse{}
		err = json.Unmarshal(body, &out)
		// convert the combined response to response struct
		combined := GraphQLResponse{}
		err = json.Unmarshal([]byte(combinedResponse), &combined)

		// merge combined and external node responses
		combined.data.sensors = append(combined.data.sensors, out.data.sensors...)
		outputJSON, _ := json.Marshal(combined)
		combinedResponse = string(outputJSON)
		if err != nil {
			log.Println(err)
			continue
		}

		err = resp.Body.Close()
		if err != nil {
			log.Println(err)
			continue
		}
	}
	err := json.NewEncoder(b).Encode(combinedResponse)
	if err != nil {
		log.Fatal(err)
	}
}

//startAggregating the data from external nodes
func startAggregating(request SyncMeshRequest, ownResponse string, b *bytes.Buffer) {

}
