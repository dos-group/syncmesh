package function

import "github.com/graphql-go/graphql"

func getUsers(_ graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}

	results, err = db.getUsers()
	if err != nil {
		return nil, err
	}
	return results, nil
}

func getUser(p graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}

	id := p.Args["_id"].(string)
	results, err = db.getUser(id)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func addUser(p graphql.ResolveParams) (interface{}, error) {
	var err error
	var user interface{}

	name := p.Args["name"].(string)
	surname := p.Args["surname"].(string)

	user, err = db.addUser(name, surname)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func deleteUser(p graphql.ResolveParams) (interface{}, error) {
	var err error
	var results interface{}

	id := p.Args["_id"].(string)
	results, err = db.deleteUser(id)
	if err != nil {
		return nil, err
	}
	return results, nil
}
