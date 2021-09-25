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

// handleStreamEvent handles the stream event request type
// it sends queries to subscribed external nodes to maintain data replication
func handleStreamEvent(ctx context.Context, event StreamEvent) (interface{}, error) {
	db := getSyncmeshDB(ctx)
	defer db.closeDB()
	// fetch external nodes
	nodes, err := db.getSyncmeshNodes()
	if err != nil {
		return nil, err
	}
	// create the event request body
	request := SyncMeshRequest{
		Query:      "",
		Database:   DefaultDB,
		Collection: DefaultCollection,
	}
	// find own and external nodes
	err, ownNode, externalNodes := findOwnNode(nodes)
	if err != nil {
		return nil, err
	}
	// set the replica id of the document, so it can be found when processing events
	replicaID := event.DocumentKey.ID + ownNode.Address
	event.FullDocument["replicaID"] = replicaID

	resp, err := json.Marshal(event.FullDocument)
	if err != nil {
		log.Println(err)
		return nil, err
	}
	// construct GraphQL query for data replication
	switch event.OperationType {
	case "insert":
		request.Query = fmt.Sprintf("mutation{addSensors(sensors: [%s])}", string(resp))
	case "update":
		request.Query = fmt.Sprintf("mutation{update(_id: %s, sensor: %s){temperature}}", event.DocumentKey.ID, string(resp))
	case "delete":
		request.Query = fmt.Sprintf("mutation{deleteReplicaSensor(replicaID: \\\"%s\\\"){temperature}}", replicaID)
	default:
		return nil, err
	}
	jsonBody, err := json.Marshal(&request)
	if err != nil {
		return nil, err
	}

	// iterate through saved external nodes and send out request
	successCounter := 0
	requestCounter := 0
	for _, node := range externalNodes {
		if node.Subscribed {
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
