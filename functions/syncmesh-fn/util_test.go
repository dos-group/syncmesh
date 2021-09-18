package function

import (
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
	if (int(distance) > trueDistance+100) || (int(distance) < trueDistance-100) {
		t.Fail()
	}
}

// TestFindOwnNode tests the method of finding the own node in a list of nodes and returning it
func TestFindOwnNode(t *testing.T) {
	nodeList := []SyncmeshNode{{OwnNode: false}, {OwnNode: true}, {OwnNode: false}}
	err, ownNode, externalNodes := findOwnNode(nodeList)
	if err != nil {
		t.Log(err)
		t.Fail()
	}
	t.Log(externalNodes)
	if len(externalNodes) != 2 || !ownNode.OwnNode {
		t.Fail()
	}
	noOwnNodesList := []SyncmeshNode{{OwnNode: false}, {OwnNode: false}, {OwnNode: false}}
	err, _, _ = findOwnNode(noOwnNodesList)
	if err != nil {
		t.Log(err)
	} else {
		t.Fail()
	}
}

// TestCalculateSensorAverages computes the averages count of sensors and checks whether it's correct
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
	if averages != trueAverages {
		t.Log(averages)
		t.Fail()
	}
}
