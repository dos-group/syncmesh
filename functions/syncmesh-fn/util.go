package function

import (
	"bytes"
	"compress/gzip"
	"errors"
	"io"
	"io/ioutil"
	"log"
	"math"
	"net/http"
)

const earthRadius = 6371

// rad calculates a degree to radians using highly advanced maths (pi and 180)
func rad(a float64) float64 {
	return a * math.Pi / 180
}

// calculateNodeDistance between two nodes using the haversine formula
func calculateNodeDistance(node1 SyncmeshNode, node2 SyncmeshNode) float64 {
	latDeltaRadians := rad(node1.Lat - node2.Lat)
	lonDeltaRadians := rad(node1.Lon - node2.Lon)

	a := math.Pow(math.Sin(latDeltaRadians/2), 2) +
		(math.Cos(rad(node1.Lat)) * math.Cos(rad(node2.Lat)) * math.Pow(math.Sin(lonDeltaRadians/2), 2))
	b := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	distance := earthRadius * b
	return math.Pow(distance, 2)
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

// zipRequest by turning a json byte array into a gzipped byte buffer
func zipRequest(method string, url string, body []byte) (*http.Request, error) {
	var buf bytes.Buffer
	var err error
	g := gzip.NewWriter(&buf)
	if _, err = g.Write(body); err != nil {
		return nil, err
	}
	if err = g.Close(); err != nil {
		return nil, err
	}
	req, err := http.NewRequest(method, url, &buf)
	req.Header.Set("Compression", "gzip")
	return req, err
}

// unzipResponse by decompressing the response body and returning the bytestream
func unzipResponse(resp *http.Response) ([]byte, error) {
	switch resp.Header.Get("Compression") {
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
