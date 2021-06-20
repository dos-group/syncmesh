package function

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
)

//handleSyncMeshRequest by instantiating one of the request types
func handleSyncMeshRequest(request SyncMeshRequest) *bytes.Buffer {
	buffer := new(bytes.Buffer)
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
	for _, address := range request.ExternalNodes {
		requestStruct := &SyncMeshRequest{Query: request.Query, Database: request.Database, Collection: request.Collection}
		jsonBody, err := json.Marshal(requestStruct)
		if err != nil {
			log.Println(err)
			continue
		}
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
		body, _ := ioutil.ReadAll(resp.Body)
		//TODO do something with body of fetched request
		err = resp.Body.Close()
		if err != nil {
			log.Println(err)
			continue
		}
	}
}

//startAggregating the data from external nodes
func startAggregating(request SyncMeshRequest, buffer *bytes.Buffer) {

}
