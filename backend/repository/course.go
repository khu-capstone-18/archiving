package repository

import (
	"strconv"
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

type Point struct {
	ID        int
	CourseID  int
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func PostCourse(crs *Course) int {
	r := db.QueryRow(`INSERT INTO courses (user_id, name, description, length, estimated_time) VALUES (` + strconv.Itoa(crs.UserID) + `, '` + crs.Name + `', '` + crs.Description + `', ` + strconv.FormatFloat(crs.Length, byte('f'), 2, 64) + `, '` + crs.EstimatedTime.String() + `' RETURNING id)`)

	id := 0
	r.Scan(&id)
	return id
}

func PostPoints(crs *Course, courseId int) error {
	if _, err := db.Exec(`INSERT INTO points (course_id, latitude, longitude, start_point, end_point, order) VALUES (` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.StartPoint.Latitude, byte('f'), 6, 64) + `', '` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.StartPoint.Longitude, byte('f'), 6, 64) + `', 'true', 'false', 0)`); err != nil {
		return err
	}

	if _, err := db.Exec(`INSERT INTO points (course_id, latitude, longitude, start_point, end_point, order) VALUES (` + strconv.Itoa(courseId) + `, '` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.EndPoint.Latitude, byte('f'), 6, 64) + `', '` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.EndPoint.Longitude, byte('f'), 6, 64) + `', 'false', 'true', 0)`); err != nil {
		return err
	}

	for i, _ := range crs.Route {
		if _, err := db.Exec(`INSERT INTO points (course_id, latitude, longitude, start_point, end_point, order) VALUES (` + strconv.Itoa(courseId) + `, '` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.Route[i].Latitude, byte('f'), 6, 64) + `', '` + strconv.Itoa(courseId) + `, '` + strconv.FormatFloat(crs.Route[i].Longitude, byte('f'), 6, 64) + `', 'false', 'false', ` + strconv.Itoa(i) + `)`); err != nil {
			return err
		}
	}
	return nil
}

func GetCourses(userId string) ([]*Course, error) {
	return nil, nil
}
