package function

import (
	b64 "encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"strings"
	"testing"
	"time"

	handler "github.com/openfaas/templates-sdk/go-http"
	"github.com/stretchr/testify/assert"
)

// TestHandlerError by not passing anything in the request and forcing an error
func TestHandlerError(t *testing.T) {
	req := handler.Request{}
	resp, err := Handle(req)
	log.Println(string(resp.Body))
	assert.Error(t, err)
}

func TestHanderWithNoNodes(t *testing.T) {
	actualBody := []byte("example body")
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("Got a request")
		if request.Query == "hello there" {
			res.Write(actualBody)
		} else {
			res.Write([]byte("Hello from the other side"))
		}
	}))
	defer func() { testServer.Close() }()

	requestStruct := &SyncMeshRequest{
		Query:         "query",
		Database:      "database",
		Collection:    "request.Collection",
		Type:          "no type",
		ExternalNodes: []string{testServer.URL},
		TestData:      "Home Node",
	}
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte("Home Node"),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
}

func TestHandlerWithMultipleNodes(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("Got a request")
		res.Write([]byte(`{"data": {"sensors": [
			{
				"lat": 123,
				"lon": 123,
				"pressure": 123,
				"temperature": 12,
				"humidity": 12,
				"timestamp": "2017-07-01T00:02:09Z"
			}
		]}}`))
	}))
	defer func() { testServer.Close() }()

	requestStruct := &SyncMeshRequest{
		Query:         "query",
		Database:      "database",
		Collection:    "request.Collection",
		Type:          "collect",
		ExternalNodes: []string{testServer.URL, testServer.URL},
		TestData: `{"Data": {"Sensors": [
			{
				"Lat": 123,
				"Lon": 123,
				"Pressure": 123,
				"Temperature": 12,
				"Humidity": 12,
				"Timestamp": "2017-07-01T00:02:09Z"
			}
		]}}`,
	}
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte(`{"data":{"sensors":[{"lat":123,"lon":123,"pressure":123,"temperature":12,"humidity":12,"timestamp":"2017-07-01T00:02:09Z"},{"lat":123,"lon":123,"pressure":123,"temperature":12,"humidity":12,"timestamp":"2017-07-01T00:02:09Z"},{"lat":123,"lon":123,"pressure":123,"temperature":12,"humidity":12,"timestamp":"2017-07-01T00:02:09Z"}]}}` + "\n"),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
}

func sensorDataHelper(sensorCount int) string {
	var sb strings.Builder
	sb.WriteString(`{"data":{"sensors":[`)
	for i := 0; i < sensorCount; i++ {
		sb.WriteString(`{"lat":123,"lon":123,"pressure":123,"temperature":12,"humidity":12,"timestamp":"2017-07-01T00:02:09Z"}`)
		if i+1 < sensorCount {
			sb.WriteString(",")
		}

	}
	sb.WriteString(`]}}` + "\n")
	return sb.String()
}

func TestHandlerWithMassiveNodesParallel(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("Got a request")
		time.Sleep(100 * time.Millisecond)
		res.Write([]byte(sensorDataHelper(1)))
	}))
	defer func() { testServer.Close() }()

	nodes := make([]string, 40)
	for i := range nodes {
		nodes[i] = testServer.URL
	}
	requestStruct := &SyncMeshRequest{
		Query:         "query",
		Database:      "database",
		Collection:    "request.Collection",
		Type:          "collect",
		ExternalNodes: nodes,
		TestData: sensorDataHelper(1),
	}
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}
	timeout := time.After(500 * time.Millisecond)
    done := make(chan bool)
	// Test Parallism
    go func() {
		resp, err := Handle(req)
		assert.NoError(t, err)
		assert.Equal(t,
			handler.Response(handler.Response{
				Body:       []byte(sensorDataHelper(41)),
				StatusCode: 200,
				Header:     http.Header(http.Header{}),
			}),
			resp)
        done <- true
    }()

    select {
    case <-timeout:
        t.Fatal("Test didn't finish in time")
    case <-done:
    }


}

func TestHandlerWithMassiveData(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("TestServer: Got a request")
		res.Write([]byte(sensorDataHelper(20000)))
		log.Printf("TestServer: Send answer")

	}))
	defer func() { testServer.Close() }()

	nodeCount := 12
	println(nodeCount)
	nodes := make([]string, nodeCount)
	for i := range nodes {
		nodes[i] = testServer.URL
	}
	requestStruct := &SyncMeshRequest{
		Query:         "query",
		Database:      "database",
		Collection:    "request.Collection",
		Type:          "collect",
		ExternalNodes: nodes,
		TestData:      sensorDataHelper(1),
	}
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte(sensorDataHelper(nodeCount*20000 + 1)),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
	// assert.Equal(t, true, false)
}

func TestHandlerExternalFunction(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("Got a request")
		res.Write([]byte(`{"test": "Function Output"}`))
	}))
	defer func() { testServer.Close() }()

	requestStruct := &SyncMeshRequest{
		ExternalFunctionsName: []string{"echoit"},
		OverwriteGateway:      testServer.URL,
		TestData:              `{"test":"Home Node"}`,
	}
	print(testServer.URL)
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte(`{"test":"Function Output"}` + "\n"),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
}

func TestHandlerExternalFunctionMultiple(t *testing.T) {
	i := 0
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		log.Printf("Got a request")
		res.Write([]byte(`{"test": "Function Output` + fmt.Sprint(i) + `"}`))
		i++
	}))
	defer func() { testServer.Close() }()

	requestStruct := &SyncMeshRequest{
		ExternalFunctionsName: []string{"echoit", "test2", "test3"},
		OverwriteGateway:      testServer.URL,
		TestData:              `{"test":"Home Node"}`,
	}
	print(testServer.URL)
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte(`{"test":"Function Output2"}` + "\n"),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
}

func TestHandlerExternalFunctionWithDeployment(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		b, err := httputil.DumpRequest(req, true)
		// b, err := ioutil.ReadAll(resp.Body)  Go.1.15 and earlier
		if err != nil {
			log.Fatalln(err)
		}
		log.Printf("Test Server Called:")
		log.Printf("%s", b)
		time.Sleep(2 * time.Second)
		request := SyncMeshRequest{}
		body, err := ioutil.ReadAll(req.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(body, &request)
		assert.NoError(t, err)
		// defer req.Body.Close()

		res.WriteHeader(200)
		res.Write([]byte(`{"test": "Function Output"}`))
	}))
	defer func() { testServer.Close() }()

	print("Starting Request")
	requestStruct := &SyncMeshRequest{
		ExternalFunctionsName: []string{"echoit"},
		DeployFunctionImage:   "ghcr.io/openfaas/alpine:latest",
		Password:              "lxw92pNSyKfHJAAx7vezLzkLnwkA9eqyMM58TRMF1CIyMN36YuDGkJwfvqhqln8",
		// OverwriteGateway:      "http://35.193.158.133:8080",
		OverwriteGateway: testServer.URL,
		TestData:         `{"test":"Home Node"}`,
	}
	print(b64.StdEncoding.EncodeToString([]byte("admin:lxw92pNSyKfHJAAx7vezLzkLnwkA9eqyMM58TRMF1CIyMN36YuDGkJwfvqhqln8")))
	jsonBody, err := json.Marshal(requestStruct)
	assert.NoError(t, err)
	req := handler.Request{
		Body: jsonBody,
	}

	resp, err := Handle(req)
	assert.NoError(t, err)
	assert.Equal(t,
		handler.Response(handler.Response{
			Body:       []byte(`{"test":"Function Output"}` + "\n"),
			StatusCode: 200,
			Header:     http.Header(http.Header{}),
		}),
		resp)
}
