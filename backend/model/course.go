package model

import (
	"time"
)

type Course struct {
	ID            int
	UserID        int           `json:"user_id"`
	Name          string        `json:"course_name"`
	Route         []*Point      `json:"route"`
	Description   string        `json:"description"`
	StartPoint    *Point        `json:"start_point"`
	EndPoint      *Point        `json:"end_point"`
	Length        float64       `json:"length"`
	EstimatedTime time.Duration `json:"estimated_time"`
}
