package function

import "github.com/graphql-go/graphql"

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
