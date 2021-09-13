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
				Query:      "",
				Database:   "syncmesh",
				Collection: "sensor_data",
			}
			switch event.OperationType {
			case "insert":
				resp, err := json.Marshal(event.FullDocument)
				if err != nil {
					log.Println(err)
				}
				request.Query = "mutation{addSensors(sensors: [" + string(resp) + "])}"
			case "delete":
				request.Query = "mutation{deleteSensor(_id: \\\"" + event.DocumentKey.ID + "\\\"){temperature}}"
			default:
				continue
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
