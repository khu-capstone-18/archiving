package model

import (
	"time"
)

type Session struct {
	ID             int           `json:"session_id"`
	UserId         int           `json:"user_id"`
	Distance       float64       `json:"total_distance"`
	Time           string        `json:"total_time"`
	StartTime      string        `json:"start_time"`
	EndTime        string        `json:"end_time"`
	AveragePace    time.Duration `json:"average_pace"`
	CaloiresBurned int           `json:"calories_burned"`
	Route          []*Point
}

type Realtime struct {
	UserID         int           `json:"user_id"`
	Distance       float64       `json:"total_distance"`
	CaloiresBurned int           `json:"calories_burned"`
	AveragePace    time.Duration `json:"average_pace"`
	StartTime      string        `json:"start_time"`
	ElapsedTime    string        `json:"elapsed_time"`
	Latitude       float64       `json:"latitude"`
	Longitude      float64       `json:"longitude"`
	Route          []*Point      `json:"route"`
	Exit           bool          `json:"exit"`
}
