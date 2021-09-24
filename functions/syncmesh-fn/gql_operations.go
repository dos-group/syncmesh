package function

import (
	"github.com/graphql-go/graphql"
	"time"
)

func getSensors(p graphql.ResolveParams) (interface{}, error) {
	limit := p.Args["limit"]
	if limit == nil {
		limit = 0
	}
	startDate := p.Args["start_time"].(time.Time)
	endDate := p.Args["end_time"].(time.Time)
	return response(db.getSensorsInTimeRange(startDate, endDate, limit.(int)))
}

func aggregateSensors(p graphql.ResolveParams) (interface{}, error) {
	startDate := p.Args["start_time"].(time.Time)
	endDate := p.Args["end_time"].(time.Time)
	return response(db.aggregateSensorsInTimeRange(startDate, endDate))
}

func getSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	return response(db.getSensor(id))
}

func deleteSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	return response(db.deleteSensorById(id))
}

func deleteReplicaSensor(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["replicaID"].(string)
	return response(db.deleteSensorByReplicaId(id))
}

func createSensors(p graphql.ResolveParams) (interface{}, error) {
	sensors := p.Args["sensors"].([]interface{})
	return response(db.createSensors(sensors))
}

func getDocEstimate(_ graphql.ResolveParams) (interface{}, error) {
	return response(db.getDocEstimate())
}

func deleteInTimeRange(p graphql.ResolveParams) (interface{}, error) {
	startTime := p.Args["start_time"].(time.Time)
	endTime := p.Args["end_time"].(time.Time)
	return response(db.deleteInTimeRange(startTime, endTime))
}

type SensorInput struct {
	replicaID string
}

func update(p graphql.ResolveParams) (interface{}, error) {
	id := p.Args["_id"].(string)
	replicaID := p.Args["sensor"].(SensorInput).replicaID
	sensor := p.Args["sensor"].(interface{})
	return response(db.update(id, sensor, replicaID))
}

func response(result interface{}, err error) (interface{}, error) {
	if err != nil {
		return nil, err
	}
	return result, nil
}
