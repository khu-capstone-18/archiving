package repository

import (
	"khu-capstone-18-backend/model"
	"strconv"

	"github.com/google/uuid"
)

type Course struct {
	ID           int
	UserID       string            `json:"user_id"`
	Name         string            `json:"course_name"`
	Route        []*model.Location `json:"route"`
	Description  string            `json:"description"`
	CopyCourseID string            `json:"copy_course_id"`
	Public       bool              `json:"public"`
}

type Point struct {
	ID        int
	CourseID  int
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func PostCourse(crs *Course) (string, error) {
	id := uuid.NewString()
	_, err := db.Exec(`INSERT INTO courses (id, creator_id, name, description, public, copy_course_id) VALUES ('` + id + `', '` + crs.UserID + `', '` + crs.Name + `', '` + crs.Description + `', ` + strconv.FormatBool(crs.Public) + `, '` + crs.CopyCourseID + `')`)

	return id, err
}

func PostPoint(loc *model.Location, courseId string, order int) error {
	id := uuid.NewString()
	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + id + `', '` + courseId + `', ` + strconv.FormatFloat(loc.Latitude, byte('f'), 6, 64) + `, ` + strconv.FormatFloat(loc.Longitude, byte('f'), 6, 64) + `, ` + strconv.Itoa(order) + `)`); err != nil {
		return err
	}
	return nil
}

func GetCourses() ([]*model.CourseTest, error) {
	r, err := db.Query(`SELECT id, name, creator_id from courses WHERE public = true`)
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
	if _, err := db.Exec(`INSERT INTO coursestest (id, creator_id, copy_course_id) VALUES ('` + crs.CourseID + `', '` + crs.CreatorID + `', '` + crs.CopyCourseID + `')`); err != nil {
		return err
	}

	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + crs.CourseID + `', '` + crs.CourseID + `', '` + strconv.FormatFloat(crs.Location.Latitude, 'f', 6, 64) + `', '` + strconv.FormatFloat(crs.Location.Longitude, 'f', 6, 64) + `', 1)`); err != nil {
		return err
	}

	return nil
}

func CreateCourseEnd(public bool, courseId string) error {
	if _, err := db.Exec(`UPDATE courses SET public = ` + strconv.FormatBool(public) + ` WHERE id = '` + courseId + `'`); err != nil {
		return err
	}

	return nil
}

func CreatePoint(pnt *model.Point) error {
	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + pnt.ID + `', '` + pnt.CourseID + `', '` + strconv.FormatFloat(pnt.Location.Latitude, 'f', 6, 64) + `', '` + strconv.FormatFloat(pnt.Location.Longitude, 'f', 6, 64) + `', ` + strconv.Itoa(pnt.Order) + `)`); err != nil {
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
	r, err := db.Query(`SELECT id, latitude, longitude, "order", "current_time" FROM points WHERE course_id = '` + courseId + `' ORDER BY "order" ASC`)
	if err != nil {
		return nil, err
	}

	pnts := []*model.Point{}
	count := 0

	for r.Next() {
		if length != 0 && count == length {
			break
		}
		pnt := model.Point{}
		r.Scan(&pnt.ID, &pnt.Location.Latitude, &pnt.Location.Longitude, &pnt.Order, &pnt.CurrentTime)
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
