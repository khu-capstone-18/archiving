package repository

import (
	"fmt"
	"khu-capstone-18-backend/model"
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

func CreateCourseStart(crs *model.CourseTest) error {
	if err := createCourse(crs); err != nil {
		fmt.Println(fmt.Println("Create Course Start Handler Err:", err))
	}
	return nil
}

func CreateCourseEnd(crs *model.CourseTest) (*[]*model.CourseTest, error) {
	if err := createCourse(crs); err != nil {
		fmt.Println(fmt.Println("Create Course Start Handler Err:", err))
		return nil, err
	}

	return GetCoursesTest(crs)
}

func createCourse(crs *model.CourseTest) error {
	if _, err := db.Exec(`INSERT INTO coursestest (id, name, creator_id, latitude, longitude, current_time) VALUES (` + crs.CourseID + `, '` + crs.CourseName + `', '` + crs.UserID + `', '` + strconv.Itoa(int(crs.Location.Latitude)) + `', '` + strconv.Itoa(int(crs.Location.Longitude)) + `', '` + crs.CurrentTime.String() + `')`); err != nil {
		return err
	}
	return nil
}

func GetCoursesTest(crs *model.CourseTest) (*[]*model.CourseTest, error) {
	r, err := db.Query(`SELECT id, name, creator_id, latitude, longitude, current_time FROM coursestest WHERE id = '` + crs.CourseID + `' ORDER BY current_time DESC`)
	if err != nil {
		return nil, err
	}

	course := model.CourseTest{}
	courses := []*model.CourseTest{}

	for r.Next() {
		r.Scan(&course.CourseID, &course.CourseName, &course.UserID, &course.Location.Latitude, &course.Location.Longitude, &course.CurrentTime)
		courses = append(courses, &course)
	}

	return &courses, nil
}
