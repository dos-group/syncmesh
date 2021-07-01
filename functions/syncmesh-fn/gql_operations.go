package function

import (
	"github.com/graphql-go/graphql"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getSensors(_ graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}
	results, err = db.getSensors()
	if err != nil {
		return nil, err
	}
	return results, nil
}

func getSensor(p graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}
	id := p.Args["_id"].(string)
	results, err = db.getSensor(id)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func getSensorsInTimeRange(p graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}
	startDate := p.Args["start_date"].(primitive.DateTime)
	endDate := p.Args["end_date"].(primitive.DateTime)
	results, err = db.getSensorsInTimeRange(startDate, endDate)
	if err != nil {
		return nil, err
	}
	return results, nil
}
