package function

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"sync"
)

// handleSyncMeshRequest by instantiating one of the request types
func handleSyncMeshRequest(request SyncMeshRequest, ownResponse string) *bytes.Buffer {
	b := new(bytes.Buffer)
	switch request.Type {
	case "aggregate":
		startAggregating(request, ownResponse, b)
	case "collect":
		startCollecting(request, ownResponse, b)
	default:
		b.WriteString(ownResponse)
	}
	return b
}

// startCollecting the data from external nodes
func startCollecting(request SyncMeshRequest, ownResponse string, b *bytes.Buffer) {
	combinedResponse := ownResponse
	// convert the combined response to response struct
	combined := GraphQLResponse{}
	err := json.Unmarshal([]byte(combinedResponse), &combined)
	if err != nil {
		log.Println(err)
	}

	requestCount := len(request.ExternalNodes)
	var wg sync.WaitGroup
	wg.Add(requestCount)
	var mutex = &sync.Mutex{}

	// start iterating through all external nodes
	for _, address := range request.ExternalNodes {
		go func(address string) {
			defer wg.Done()
			err, body := makeExternalRequest(request, address)
			if err != nil {
				log.Println(err)
			}
			// convert response to response struct
			out := GraphQLResponse{}
			err = json.Unmarshal(body, &out)
			if err != nil {
				log.Println(err)
			}
			// merge combined and external node responses
			mutex.Lock()
			combined.Data.Sensors = append(combined.Data.Sensors, out.Data.Sensors...)
			mutex.Unlock()
		}(address)
	}

	wg.Wait()
	outputJSON, _ := json.Marshal(combined)
	combinedResponse = string(outputJSON)
	err = json.NewEncoder(b).Encode(json.RawMessage(combinedResponse))
	if err != nil {
		log.Fatal(err)
	}
}

// startAggregating the data from external nodes
func startAggregating(request SyncMeshRequest, ownResponse string, b *bytes.Buffer) {
	var averagesList []AveragesResponse
	own := AveragesResponse{}
	err := json.Unmarshal([]byte(ownResponse), &own)
	if err != nil {
		return
	}
	averagesList = append(averagesList, own)
	// start iterating through all external nodes
	for _, address := range request.ExternalNodes {
		err, body := makeExternalRequest(request, address)
		if err != nil {
			log.Println(err)
			continue
		}
		// convert response to response struct
		out := AveragesResponse{}
		err = json.Unmarshal(body, &out)
		if err != nil {
			log.Println(err)
			continue
		}
		// add external node averages to averages list
		averagesList = append(averagesList, out)
	}
	finalAverages := calculateAverages(averagesList)
	outputJSON, _ := json.Marshal(finalAverages)
	err = json.NewEncoder(b).Encode(json.RawMessage(string(outputJSON)))
	if err != nil {
		log.Fatal(err)
	}
}

// makeExternalRequest to one of the syncmesh nodes
func makeExternalRequest(request SyncMeshRequest, url string) (error, []byte) {
	log.Println("Request start: " + url)
	// prepare SyncMesh Request body for the external request
	requestStruct := &SyncMeshRequest{
		Query:      request.Query,
		Database:   request.Database,
		Collection: request.Collection,
		Type:       request.Type,
	}
	jsonBody, err := json.Marshal(requestStruct)
	if err != nil {
		return err, nil
	}
	// make a POST request to external nodes, fetching the data
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return err, nil
	}
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err, nil
	}
	// read the response
	body, err := unzipResponse(resp)
	if err != nil {
		return err, nil
	}
	err = resp.Body.Close()
	if err != nil {
		return err, nil
	}
	log.Println("Request end: " + url)
	return nil, body
}

// calculateAverages of sensor data for aggregation
func calculateAverages(averagesList []AveragesResponse) AveragesResponse {
	final := AveragesResponse{AveragePressure: 0, AverageTemperature: 0, AverageHumidity: 0}
	size := float64(len(averagesList))
	if size == 0 {
		return final
	}
	// sum all values
	for _, item := range averagesList {
		final.AverageHumidity += item.AverageHumidity
		final.AverageTemperature += item.AverageTemperature
		final.AveragePressure += item.AveragePressure
	}
	// calculate the averages
	final.AverageHumidity /= size
	final.AverageTemperature /= size
	final.AveragePressure /= size
	return final
}
