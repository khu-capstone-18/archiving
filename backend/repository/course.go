package repository

import (
	"khu-capstone-18-backend/model"
	"strconv"

	"github.com/google/uuid"
)

type Course struct {
	ID           string         `json:"id"`
	UserID       string         `json:"user_id"`
	Name         string         `json:"course_name"`
	Location     model.Location `json:"location"`
	Description  string         `json:"description"`
	CopyCourseID string         `json:"copy_course_id"`
	Public       bool           `json:"public"`
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

func CreateCourseStart(crs *Course) error {
	if _, err := db.Exec(`INSERT INTO courses (id, creator_id, public, copy_course_id) VALUES ('` + crs.ID + `', '` + crs.UserID + `', ` + strconv.FormatBool(crs.Public) + `,'` + crs.CopyCourseID + `')`); err != nil {
		return err
	}

	pointId := uuid.NewString()
	if _, err := db.Exec(`INSERT INTO points (id, course_id, latitude, longitude, "order") VALUES ('` + pointId + `', '` + crs.ID + `', ` + strconv.FormatFloat(crs.Location.Latitude, byte('f'), 6, 64) + `, ` + strconv.FormatFloat(crs.Location.Longitude, byte('f'), 6, 64) + `, 1)`); err != nil {
		return err
	}
	return nil
}

func GetCourses() ([]*model.CourseList, error) {
	r, err := db.Query(`SELECT id, name, creator_id from courses WHERE public = true`)
	if err != nil {
		return nil, err
	}

	courses := []*model.CourseList{}
	for r.Next() {
		crs := model.CourseList{}
		r.Scan(&crs.CourseID, &crs.CourseName, &crs.CreatorID)
		pnts, _ := GetPoints(crs.CourseID, 0)
		crs.Location = pnts
		courses = append(courses, &crs)
	}

	return courses, nil
}

func CreateCourseEnd(public bool, courseId, courseName string) error {
	if _, err := db.Exec(`UPDATE courses SET name = '` + courseName + `', public = ` + strconv.FormatBool(public) + ` WHERE id = '` + courseId + `'`); err != nil {
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

// func GetCourseDistance(courseID string) (string, error) {
// 	r, err := db.Query(`SELECT id, name, creator_id, latitude, longitude, "current_time" FROM coursestest WHERE id = '` + crs.CourseID + `'`)
// 	if err != nil {
// 		return nil, err
// 	}

// 	course := model.CourseTest{}
// 	courses := []*model.CourseTest{}

// 	for r.Next() {
// 		r.Scan(&course.CourseID, &course.CourseName, &course.CreatorID, &course.Location.Latitude, &course.Location.Longitude, &course.CurrentTime)
// 		courses = append(courses, &course)
// 	}

// 	return &courses, nil
// }

func GetParentCourseID(id string) (string, bool, error) {
	r := db.QueryRow(`SELECT copy_course_id FROM courses WHERE id = '` + id + `'`)
	cid := ""
	if err := r.Scan(&cid); err != nil {
		return "", false, err
	}

	if cid == "" {
		return "", false, nil
	}
	return cid, true, nil
}

func GetCourseName(id string) string {
	r := db.QueryRow(`SELECT name FROM courses WHERE id = '` + id + `'`)
	name := ""
	r.Scan(&name)
	return name
}
