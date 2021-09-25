package function

import (
	handler "github.com/openfaas/templates-sdk/go-http"
	"github.com/stretchr/testify/assert"
	"log"
	"testing"
)

// TestHandlerError by not passing anything in the request and forcing an error
func TestHandlerError(t *testing.T) {
	req := handler.Request{}
	resp, err := Handle(req)
	log.Println(string(resp.Body))
	assert.Error(t, err)
}
