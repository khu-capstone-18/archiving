package repository

import (
	"khu-capstone-18-backend/model"
	"strconv"
	"time"

	"github.com/google/uuid"
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

func GetCourses() ([]*model.CourseTest, error) {
	r, err := db.Query(`SELECT id, name, creator_id WHERE public = true and copy_course_id = ''`)
	if err != nil {
		return nil, err
	}

	courses := []*model.CourseTest{}
	for r.Next() {
		crs := model.CourseTest{}
		r.Scan(&crs.CourseID, &crs.CourseName, &crs.CreatorID)
		courses = append(courses, &crs)
	}

	return courses, nil
}

func CreateCourseStart(crs *model.CourseTest) error {
	if _, err := db.Exec(`INSERT INTO coursestest (id, name, creator_id, copy_course_id, public) VALUES ('` + crs.CourseID + `', '` + crs.CreatorID + `', '` + crs.CreatorID + `', '` + crs.CopyCourseID + `', false)`); err != nil {
		return err
	}

	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + crs.CourseID + `', '` + crs.CourseID + `', '` + strconv.FormatFloat(crs.Location.Latitude, 'f', 6, 64) + `', '` + strconv.FormatFloat(crs.Location.Longitude, 'f', 6, 64) + `', 1)`); err != nil {
		return err
	}

	return nil
}

func CreateCourseEnd(crs *model.CourseTest) (*[]*model.CourseTest, error) {
	if err := createCourse(crs); err != nil {
		return nil, err
	}

	return GetCoursesTest(crs)
}

func CreatePoint(pnt *model.Point) error {
	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + pnt.ID + `', '` + pnt.CourseID + `', '` + strconv.FormatFloat(pnt.Location.Latitude, 'f', -1, 64) + `', '` + strconv.FormatFloat(pnt.Location.Longitude, 'f', -1, 64) + `', ` + strconv.Itoa(pnt.Order) + `)`); err != nil {
		return err
	}
	return nil
}

func GetLatestPointOrder(courseId string) int {
	r := db.QueryRow(`SELECT "order" FROM points WHERE course_id = '` + courseId + `' ORDER BY "order" desc LIMIT 1`)
	order := -1
	r.Scan(&order)

	return order
}

func GetPoints(courseId string, length int) ([]*model.Point, error) {
	r, err := db.Query(`SELECT id, latitude, longitude, "order", "current_time" FROM points WHERE course_id = '` + courseId + `'`)
	if err != nil {
		return nil, err
	}

	pnts := []*model.Point{}
	count := 0

	for r.Next() {
		if count != 0 && count == length {
			break
		}
		pnt := model.Point{}
		t := ""
		r.Scan(&pnt.ID, &pnt.Location.Latitude, &pnt.Location.Longitude, &pnt.Order, &t)
		ct, _ := time.Parse("2006-01-02 15:04:05", t)
		pnt.CurrentTime = ct
		pnts = append(pnts, &pnt)
		count += 1
	}

	return pnts, nil
}

func createCourse(crs *model.CourseTest) error {
	id := uuid.NewString()
	if _, err := db.Exec(`INSERT INTO coursestest (id, name, creator_id, current_time) VALUES ('` + crs.CourseID + `', '` + crs.CourseName + `', '` + crs.CreatorID + `')`); err != nil {
		return err
	}

	if _, err := db.Exec(`INSERT INTO points (id, user_id, course_id, latitude, longitude, start_point, end_point, "order") VALUES ('` + id + `', '` + crs.CreatorID + `', '` + crs.CourseID + `', ` + strconv.FormatFloat(crs.Location.Latitude, 'f', -1, 64) + `, ` + strconv.FormatFloat(crs.Location.Longitude, 'f', -1, 64) + `, 'true', 'false', 1)`); err != nil {
		return err
	}

	return nil
}

func GetCoursesTest(crs *model.CourseTest) (*[]*model.CourseTest, error) {
	r, err := db.Query(`SELECT id, name, creator_id, latitude, longitude, "current_time" FROM coursestest WHERE id = '` + crs.CourseID + `'`)
	if err != nil {
		return nil, err
	}

	course := model.CourseTest{}
	courses := []*model.CourseTest{}

	for r.Next() {
		r.Scan(&course.CourseID, &course.CourseName, &course.CreatorID, &course.Location.Latitude, &course.Location.Longitude, &course.CurrentTime)
		courses = append(courses, &course)
	}

	return &courses, nil
}
