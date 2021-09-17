package function

import (
	"fmt"
	"testing"
)

// TestDegToRad checks the accuracy of the degrees to radians function
func TestDegToRad(t *testing.T) {
	deg := 123
	trueRad := "2.14675"
	calculatedRad := rad(float64(deg))
	truncatedRad := fmt.Sprintf("%.5f", calculatedRad)
	if truncatedRad != trueRad {
		t.Log(calculatedRad)
		t.Fail()
	}
}

func TestCalculateNodeDistance(t *testing.T) {
	trueDistance := 6381
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
	if int(distance) <= trueDistance+100 || int(distance) >= trueDistance-100 {
		t.Fail()
	}
}
