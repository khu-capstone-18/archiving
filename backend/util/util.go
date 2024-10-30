package util

import (
	"khu-capstone-18-backend/model"
	"math"
)

func CalculateDistance(l1, l2 model.Location) float64 {
	const R = 6371.0

	lat1 := l1.Latitude * math.Pi / 180
	lat2 := l2.Latitude * math.Pi / 180
	lon1 := l1.Longitude * math.Pi / 180
	lon2 := l2.Longitude * math.Pi / 180

	dlat := lat2 - lat1
	dlng := lon2 - lon1

	a := math.Sin(dlat/2)*math.Sin(dlat/2) + math.Cos(lat1)*math.Cos(lat2)*math.Sin(dlng/2)*math.Sin(dlng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c
}
