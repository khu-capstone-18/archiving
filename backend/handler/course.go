package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/model"
	"khu-capstone-18-backend/repository"
	"khu-capstone-18-backend/util"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

func PostCourseHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	_, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	req := repository.Course{
		StartPoint: &repository.Point{},
		EndPoint:   &repository.Point{},
		Route:      []*repository.Point{},
	}

	b, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	courseId := repository.PostCourse(&req)
	if err != nil {
		fmt.Println("POST COURSE ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	err = repository.PostPoints(&req, courseId)
	if err != nil {
		fmt.Println("POST POINTS ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	response := struct {
		Message  string `json:"message"`
		CourseID string `json:"course_id"`
	}{
		Message:  "Course created successfully.",
		CourseID: strconv.Itoa(courseId),
	}

	resp, err := json.Marshal(response)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

func GetCoursesHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]

	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	_, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	crs, err := repository.GetCourses(userId)
	if err != nil {
		fmt.Println("GET USER COURSES ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	resp, err := json.Marshal(crs)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

// {
// 	user_id: string,
// 	location: [
//     {
//       latitude: double(float),
//       longitude: double(float),
// 	  },
// 	],
// 	current_time: string,
// }

func CreateCourseStartHandler(w http.ResponseWriter, r *http.Request) {
	req := model.CourseTest{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	req.CourseID = uuid.NewString()

	if err := repository.CreateCourseStart(&req); err != nil {
		fmt.Println("Create Course Start Handler Err:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		CourseID string `json:"course_id"`
	}{
		CourseID: req.CourseID,
	}

	data, _ := json.Marshal(resp)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func CreateCourseEndHandler(w http.ResponseWriter, r *http.Request) {
	req := model.CourseTest{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	courses, err := repository.CreateCourseEnd(&req)
	if err != nil {
		fmt.Println("ERR CREATECOURSESTESTEND : ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	var totalDistance float64
	var startTime time.Time
	var endTime time.Time
	var beforeLatitude float64
	var beforeLongitude float64

	for i, c := range *courses {
		if i == len(*courses)-1 {
			startTime = c.CurrentTime
		}
		if i == 0 {
			endTime = c.CurrentTime
			beforeLatitude = c.Location.Latitude
			beforeLongitude = c.Location.Longitude
			continue
		}

		// 두 쌍의 경도, 위도 사이 거리 계산
		totalDistance += util.CalculateDistance(
			model.Location{
				Longitude: beforeLongitude,
				Latitude:  beforeLatitude,
			},
			model.Location{
				Longitude: c.Location.Longitude,
				Latitude:  c.Location.Latitude,
			},
		)
		beforeLatitude = c.Location.Latitude
		beforeLongitude = c.Location.Longitude
	}

	totalTime := endTime.Sub(startTime)
	totalPaceSecond := totalTime.Seconds() / totalDistance
	m := int(totalPaceSecond / 1)
	s := int((totalPaceSecond - float64(int(totalPaceSecond))) * 60)
	totalPace := fmt.Sprint("%d:%d", m, s)
	if err != nil {
		fmt.Println("ERR PARSING TIME:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		TotalPace     string        `json:"total_pace"`
		TotalDistance string        `json:"total_distance"`
		TotalTime     time.Duration `json:"total_time"`
	}{
		TotalPace:     totalPace,
		TotalDistance: fmt.Sprint("%.2fkm", totalDistance),
		TotalTime:     totalTime,
	}

	data, _ := json.Marshal(resp)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}
