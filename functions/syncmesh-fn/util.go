package function

import (
	"bytes"
	"compress/gzip"
	"errors"
	handler "github.com/openfaas/templates-sdk/go-http"
	"github.com/umahmood/haversine"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"sort"
)

// calculateNodeDistance between two nodes using the haversine formula
func calculateNodeDistance(node1 SyncmeshNode, node2 SyncmeshNode) float64 {
	loc1 := haversine.Coord{
		Lon: node1.Lon,
		Lat: node1.Lat,
	}
	loc2 := haversine.Coord{
		Lon: node2.Lon,
		Lat: node2.Lat,
	}
	_, km := haversine.Distance(loc1, loc2)
	return km
}

// findOwnNode in a list of nodes
func findOwnNode(nodes []SyncmeshNode) (error, SyncmeshNode, []SyncmeshNode) {
	for i, node := range nodes {
		if node.OwnNode {
			nodes[i] = nodes[len(nodes)-1]
			return nil, node, nodes[:len(nodes)-1]
		}
	}
	return errors.New("no own node found"), SyncmeshNode{}, nodes
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

//zip a body using gzip and write it into a byte buffer
func zip(body []byte) (*bytes.Buffer, error) {
	var buf bytes.Buffer
	var err error
	g := gzip.NewWriter(&buf)
	if _, err = g.Write(body); err != nil {
		return nil, err
	}
	if err = g.Close(); err != nil {
		return nil, err
	}
	return &buf, nil
}

// zipRequest by zipping the body and setting it in the request with corresponding header
func zipRequest(method string, url string, body []byte) (*http.Request, error) {
	buffer, err := zip(body)
	req, err := http.NewRequest(method, url, buffer)
	req.Header.Set("Content-Encoding", "gzip")
	return req, err
}

// unzipResponse by decompressing the response body and returning the bytestream
func unzipResponse(resp *http.Response) ([]byte, error) {
	switch resp.Header.Get("Content-Encoding") {
	case "gzip":
		reader, err := gzip.NewReader(resp.Body)
		defer func(reader io.ReadCloser) {
			err := reader.Close()
			if err != nil {
				log.Println(err)
			}
		}(reader)
		buf := new(bytes.Buffer)
		_, err = buf.ReadFrom(reader)
		if err != nil {
			return nil, err
		}
		return buf.Bytes(), err
	default:
		return ioutil.ReadAll(resp.Body)
	}
}

func filterExternalNodes(externalNodes []SyncmeshNode, ownNode SyncmeshNode, radius float64) []SyncmeshNode {
	var filteredNodes []SyncmeshNode
	for _, node := range externalNodes {
		// if distance is not available (i.e. 0)...
		if node.Distance == 0 {
			// calculate the distance to our own node and update the node in the database
			node.Distance = calculateNodeDistance(ownNode, node)
		}
		// if distance is inside radius, add id to the filtered nodes
		if node.Distance <= radius {
			filteredNodes = append(filteredNodes, node)
		}
	}
	// sort the filtered nodes by distance, if possible
	sort.Slice(filteredNodes, func(i, j int) bool {
		return filteredNodes[i].Distance < filteredNodes[j].Distance
	})
	return filteredNodes
}

// functionResponse handles a generic function response with included error handling
func functionResponse(body string, err error) (handler.Response, error) {
	log.Printf("%s is the request body", body)
	var statusCode int
	if err != nil {
		statusCode = http.StatusInternalServerError
	} else {
		statusCode = http.StatusOK
	}
	return handler.Response{
		Body:       []byte(body),
		StatusCode: statusCode,
	}, err
}

// getRequestType determines the syncmesh request type: meta, event, or regular (default) request
func getRequestType(response map[string]interface{}) string {
	if _, ok := response["meta_type"]; ok {
		return Meta
	} else if _, ok := response["operationType"]; ok {
		return Event
	} else {
		return Default
	}
}
