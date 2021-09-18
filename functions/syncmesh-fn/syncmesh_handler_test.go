package function

import "testing"

// TestCalculateAverages calculates the average of averages responses
func TestCalculateAverages(t *testing.T) {
	averages := []AveragesResponse{
		{AveragePressure: 1, AverageHumidity: 2, AverageTemperature: 3},
		{AveragePressure: 2, AverageHumidity: 3, AverageTemperature: 4},
		{AveragePressure: 3, AverageHumidity: 4, AverageTemperature: 5},
	}
	trueAverages := AveragesResponse{
		AverageHumidity:    3,
		AverageTemperature: 4,
		AveragePressure:    2,
	}
	calcAverages := calculateAverages(averages)
	if trueAverages != calcAverages {
		t.Log(calcAverages)
		t.Fail()
	}
	calcAverages = calculateAverages([]AveragesResponse{})
	emptyAverages := AveragesResponse{AveragePressure: 0, AverageTemperature: 0, AverageHumidity: 0}
	if calcAverages != emptyAverages {
		t.Log(calcAverages)
		t.Fail()
	}
}
