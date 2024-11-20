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

type CourseTest struct {
	CreatorID    string   `json:"creator_id"`
	CourseName   string   `json:"course_name"`
	CourseID     string   `json:"course_id"`
	CopyCourseID string   `json:"copy_course_id"`
	Location     Location `json:"location"`
	CurrentTime  string   `json:"current_time"`
}

type Location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
