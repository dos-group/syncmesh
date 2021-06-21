package function

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
)

//handleSyncMeshRequest by instantiating one of the request types
func handleSyncMeshRequest(request SyncMeshRequest, buffer *bytes.Buffer) *bytes.Buffer {
	switch request.Type {
	case "aggregate":
		startAggregating(request, buffer)
	case "collect":
		startCollecting(request, buffer)
	}
	return buffer
}

//startCollecting the data from external nodes
func startCollecting(request SyncMeshRequest, buffer *bytes.Buffer) {
	combinedResponse := ""

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
		out := map[string]interface{}{}
		err = json.Unmarshal(body, &out)
		//TODO: merge query response arrays here
		outputJSON, _ := json.Marshal(out)
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
	err := json.NewEncoder(buffer).Encode(combinedResponse)
	if err != nil {
		log.Fatal(err)
	}
}

//startAggregating the data from external nodes
func startAggregating(request SyncMeshRequest, buffer *bytes.Buffer) {

}
