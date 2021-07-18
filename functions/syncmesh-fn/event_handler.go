package function

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
)

type DocKey struct {
	ID string `bson:"_id"`
}

type StreamEvent struct {
	OperationType string                 `bson:"operationType"` // can be "insert", "update" or "delete"
	FullDocument  map[string]interface{} `bson:"fullDocument"`
	DocumentKey   DocKey                 `bson:"documentKey"`
}

func handleStreamEvent(ctx context.Context, event StreamEvent) (interface{}, error) {
	db := getSyncmeshDB(ctx)
	defer db.closeDB()
	nodes, err := db.getSyncmeshNodes()
	if err != nil {
		return nil, err
	}
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
			_, err = http.NewRequest("POST", node.Address, bytes.NewBuffer(jsonBody))
			if err != nil {
				return nil, err
			}
		}
	}
	return "requests sent to subscribed nodes", nil
}
