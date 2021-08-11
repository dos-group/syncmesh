package function

import (
	"errors"
	"math"
)

const earthRadius = 6371

// rad calculates a degree to radians using highly advanced maths (pi and 180)
func rad(a float64) float64 {
	return a * math.Pi / 180
}

// calculateNodeDistance between two nodes using the haversine formula
func calculateNodeDistance(node1 SyncmeshNode, node2 SyncmeshNode) float64 {
	latDeltaRadians := rad(node1.Lat - node2.Lat)
	lonDeltaRadians := rad(node1.Lon - node2.Lon)

	a := math.Pow(math.Sin(latDeltaRadians/2), 2) +
		(math.Cos(rad(node1.Lat)) * math.Cos(rad(node2.Lat)) * math.Pow(math.Sin(lonDeltaRadians/2), 2))
	b := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	distance := earthRadius * b
	return math.Pow(distance, 2)
}

// findOwnNode in a list of nodes
func findOwnNode(nodes []SyncmeshNode) (error, SyncmeshNode, []SyncmeshNode) {
	for i, node := range nodes {
		if node.OwnNode {
			nodes[i] = nodes[len(nodes)-1]
			return nil, node, nodes[:len(nodes)-1]
		}
	}
	return errors.New("no own node found"), SyncmeshNode{}, nodes
}
