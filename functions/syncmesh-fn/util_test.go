package function

import (
	"github.com/stretchr/testify/assert"
	"io"
	"net/http"
	"strings"
	"testing"
)

// TestCalculateNodeDistance tests the distance calculation between two nodes
func TestCalculateNodeDistance(t *testing.T) {
	trueDistance := 6381   // approximate "true" distance using maps
	node1 := SyncmeshNode{ // Berlin
		Lat: 52.520008,
		Lon: 13.404954,
	}
	node2 := SyncmeshNode{ // NYC
		Lat: 40.730610,
		Lon: -73.935242,
	}
	distance := calculateNodeDistance(node1, node2)
	t.Log(distance)
	assert.False(t, (int(distance) > trueDistance+100) || (int(distance) < trueDistance-100))
}

// TestFindOwnNode tests the method of finding the own node in a list
// of nodes and returning it
func TestFindOwnNode(t *testing.T) {
	nodeList := []SyncmeshNode{{OwnNode: false}, {OwnNode: true}, {OwnNode: false}}
	err, ownNode, externalNodes := findOwnNode(nodeList)
	assert.NoError(t, err)
	t.Log(externalNodes)
	assert.True(t, len(externalNodes) == 2 && ownNode.OwnNode)

	noOwnNodesList := []SyncmeshNode{{OwnNode: false}, {OwnNode: false}, {OwnNode: false}}
	err, _, _ = findOwnNode(noOwnNodesList)
	assert.Error(t, err)
}

// TestCalculateSensorAverages computes the averages count of sensors
// and checks whether it's correct
func TestCalculateSensorAverages(t *testing.T) {
	sensorData := []SensorModelNoId{
		{Humidity: 2, Temperature: 1, Pressure: 9},
		{Humidity: 4, Temperature: 2, Pressure: 9},
		{Humidity: 6, Temperature: 3, Pressure: 8},
		{Humidity: 8, Temperature: 4, Pressure: 8},
	}
	trueAverages := AveragesResponse{
		AveragePressure:    8.5,
		AverageHumidity:    5,
		AverageTemperature: 2.5,
	}
	averages := calculateSensorAverages(sensorData)
	assert.True(t, averages == trueAverages)
}

// TestZip does a test gzip encoding
func TestZip(t *testing.T) {
	body := []byte("Some test body")
	buffer, err := zip(body)
	assert.NoError(t, err)
	t.Log(buffer.String())
}

// TestUnzipResponse tests unzipping a gzipped HTTP response
func TestUnzipResponse(t *testing.T) {
	initialString := "Some test body"
	// zip an example body
	body := []byte(initialString)
	buffer, err := zip(body)
	assert.NoError(t, err)

	testResponse := http.Response{
		Body:   io.NopCloser(strings.NewReader(buffer.String())),
		Header: http.Header{"Content-Encoding": []string{"gzip"}},
	}
	bytes, err := unzipResponse(&testResponse)
	assert.NoError(t, err)
	assert.True(t, string(bytes) == initialString)
}

// TestFilterNodes tests the radius node filtering algorithm.
// uncomment the mongodb update lines to test properly
func TestFilterNodes(t *testing.T) {
	radius := 30 // 30km
	nodeList := []SyncmeshNode{{
		Lat:     52.476318, // grunewald
		Lon:     13.236049,
		OwnNode: false,
	}, {
		Lat:     52.503008, // Berlin, closest to own node
		Lon:     13.334111,
		OwnNode: false,
	}, {
		Lat:     52.515127, // Berlin
		Lon:     13.368466,
		OwnNode: true,
	}, {
		Lat:     52.403192, // Potsdam
		Lon:     13.102689,
		OwnNode: false,
	}, {
		Lat:     52.373047, // Hanover
		Lon:     9.732859,
		OwnNode: false,
	}}
	err, ownNode, externalNodes := findOwnNode(nodeList)
	assert.NoError(t, err)
	filteredNodes := filterExternalNodes(externalNodes, ownNode, float64(radius))
	t.Log(filteredNodes)
	assert.True(t, len(filteredNodes) == 3)
	assert.True(t, filteredNodes[0].Distance < filteredNodes[2].Distance)
}
