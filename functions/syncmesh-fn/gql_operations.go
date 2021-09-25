package function

import (
	"github.com/graphql-go/graphql"
	"time"
)

// getSensors with a limit and optional end or start time
func getSensors(p graphql.ResolveParams) (interface{}, error) {
	limit := p.Args["limit"]
	if limit == nil {
		limit = 0
	}
	endTime := p.Args["end_time"]
	if endTime == nil { // default is now if no end time given
		endTime = time.Now()
	}
	startTime := p.Args["start_time"]
	if startTime == nil { // default is golang zero time if no start time given
		startTime = time.Time{}
	}
	return response(db.getSensorsInTimeRange(startTime.(time.Time), endTime.(time.Time), limit.(int)))
}

// aggregateSensors for sensor data averages with an optional end or start time
func aggregateSensors(p graphql.ResolveParams) (interface{}, error) {
	start := p.Args["start_time"]
	end := p.Args["end_time"]
	return response(db.aggregateSensorsInTimeRange(start, end))
}

// getSensor using an id
func getSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	return response(db.getSensor(id))
}

// deleteSensor using an id
func deleteSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	return response(db.deleteSensorById(id))
}

// deleteReplicaSensor using a replica id
func deleteReplicaSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["replicaID"].(string)
	return response(db.deleteSensorByReplicaId(id))
}

// createSensors using a sensor list
func createSensors(p graphql.ResolveParams) (interface{}, error) {
	sensors := p.Args["sensors"].([]interface{})
	return response(db.createSensors(sensors))
}

// getDocEstimate to get the estimated number of documents
func getDocEstimate(_ graphql.ResolveParams) (interface{}, error) {
	return response(db.getDocEstimate())
}

// deleteInTimeRange for deleting sensors in a given time range
func deleteInTimeRange(p graphql.ResolveParams) (interface{}, error) {
	startTime := p.Args["start_time"].(time.Time)
	endTime := p.Args["end_time"].(time.Time)
	return response(db.deleteInTimeRange(startTime, endTime))
}

type SensorInput struct {
	replicaID string
}

// update a syncmesh node with ID and optional replica ID
func update(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	replicaID := p.Args["sensor"].(SensorInput).replicaID
	sensor := p.Args["sensor"].(interface{})
	return response(db.update(id, sensor, replicaID))
}

// response handles a generic db operation response with error check
func response(result interface{}, err error) (interface{}, error) {
	if err != nil {
		return nil, err
	}
	return result, nil
}
