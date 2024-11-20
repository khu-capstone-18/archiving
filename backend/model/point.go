package model

import "time"

type Point struct {
	ID          string    `json:"point_id"`
	CourseID    string    `json:"course_id"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	Order       int       `json:"order"`
	CurrentTime time.Time `json:"current_time"`
}
