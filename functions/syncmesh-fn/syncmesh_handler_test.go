package function

import (
	"encoding/json"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"
)

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
	assert.True(t, trueAverages == calcAverages)

	calcAverages = calculateAverages([]AveragesResponse{})
	emptyAverages := AveragesResponse{AveragePressure: 0, AverageTemperature: 0, AverageHumidity: 0}
	assert.True(t, calcAverages == emptyAverages)
}

// TestExternalRequest makes an external request with a mock response
func TestExternalRequest(t *testing.T) {
	actualBody := []byte("example body")
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		if request.Query == "hello there" {
			res.Write(actualBody)
		} else {
			res.Write([]byte(""))
		}
	}))
	defer func() { testServer.Close() }()

	syncmeshRequest := SyncMeshRequest{Query: "hello there"}
	err, body := makeExternalRequest(syncmeshRequest, testServer.URL)
	assert.NoError(t, err)
	assert.Equal(t, actualBody, body)
}
