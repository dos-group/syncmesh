package function

import "math"

const earthRadius = 6371

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
