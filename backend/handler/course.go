package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/repository"
	"net/http"
	"strconv"

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
