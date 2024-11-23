package model

import (
	"time"
)

type Point struct {
	ID          string    `json:"point_id"`
	CourseID    string    `json:"course_id"`
	Location    Location  `json:"location"`
	Order       int       `json:"order"`
	CurrentTime time.Time `json:"current_time"`
}
