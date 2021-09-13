package function

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func handleStreamEvent(ctx context.Context, event StreamEvent) (interface{}, error) {
	db := getSyncmeshDB(ctx)
	defer db.closeDB()
	nodes, err := db.getSyncmeshNodes()
	if err != nil {
		return nil, err
	}
	successCounter := 0
	requestCounter := 0
	for _, node := range nodes {
		if node.Subscribed {
			request := SyncMeshRequest{
				Query:         "{sensors(limit: 1, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-08-01T00:00:00Z\"){temperature humidity timestamp}}",
				Database:      "syncmesh",
				Collection:    "sensor_data",
				Type:          "collect",
				UseMetaData:   false,
				Variables:     nil,
				ExternalNodes: nil,
			}
			jsonBody, err := json.Marshal(&request)
			if err != nil {
				return nil, err
			}
			req, err := http.NewRequest("POST", node.Address, bytes.NewBuffer(jsonBody))
			if err != nil {
				return nil, err
			}
			req.Header.Set("Content-Type", "application/json")
			client := &http.Client{}
			resp, err := client.Do(req)
			requestCounter += 1
			if err != nil {
				return err, nil
			}
			// read the response
			if resp.StatusCode == 200 {
				successCounter += 1
			}
			body, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				continue
			}
			err = resp.Body.Close()
			if err != nil {
				continue
			}
			log.Println(string(body))
		}
	}
	results := fmt.Sprintf("Total of %v requests sent, %v successful", requestCounter, successCounter)
	return results, nil
}
