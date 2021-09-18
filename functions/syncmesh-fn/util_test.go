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
