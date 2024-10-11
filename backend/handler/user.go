package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/database"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

func SignUpHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("SIGNUP HANDLER START")
	req := struct {
		Username string `json:"username"`
		Password string `json:"password"`
		Email    string `json:"email"`
		Nickname string `json:"nickname"`
	}{}

	b, _ := io.ReadAll(r.Body)

	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// DB에 유저 삽입
	if err := database.CreateUser(req.Username, req.Password, req.Email, req.Nickname); err != nil {
		fmt.Println("CREATE USER ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// DB에서 유저ID 조회
	id, err := database.GetUserID(req.Username)
	if err != nil {
		fmt.Println("GET UESR ID ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// JWT 토큰 생성
	token, err := auth.GenerateJwtToken(req.Username, 5*time.Minute)
	if err != nil {
		fmt.Println("GENERATE JWT TOKEN ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		Message string `json:"message"`
		UserId  string `json:"user_id"`
		Token   string `json:"token"`
	}{
		Message: "Signup successful",
		UserId:  strconv.Itoa(id),
		Token:   token,
	}

	// 응답
	response, err := json.Marshal(resp)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(response)
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("LOGIN HANDLER START")
	req := struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}{}

	b, _ := io.ReadAll(r.Body)

	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	pw, err := database.GetPassword(req.Username)
	if err != nil {
		fmt.Println("GET PASSWORD ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	if pw != req.Password {
		fmt.Println("USER " + req.Username + " TRIED TO LOGIN WITH UNCORRECT PASSWORD")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// JWT 생성
	token, err := auth.GenerateJwtToken(req.Username, 5*time.Minute)
	if err != nil {
		fmt.Println("GENERATE JWT ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	response := struct {
		Message string `json:"message"`
		Token   string `json:"token"`
	}{
		Message: "Login successful",
		Token:   token,
	}

	resp, err := json.Marshal(response)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	fmt.Println("TEST RESPONSE JWT TOKEN:", token)
	fmt.Println("TEST RESPONSE JWT TOKEN:", token)
	fmt.Println("TEST RESPONSE JWT TOKEN:", token)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

func LogoutHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	username, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// 토큰 삭제
	if _, err := auth.GenerateJwtToken(username, 0); err != nil {
		fmt.Println("JWT TOKEN REMOVE ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 클라이언트에게 만료된 토큰 반환
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf(`{"message": "%s"}`, "Logout successful")))
}

func OptionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")

	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	w.WriteHeader(http.StatusOK)
	return
}

func ProfileHandler(w http.ResponseWriter, r *http.Request) {
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

	u, err := database.GetUser(userId)
	if err != nil {
		fmt.Println("GET USER PROFILE ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	record, err := GetBestRecordByUserId(userId)
	if err != nil {
		fmt.Println("GET USER'S BEST RECORD ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	totalDistance, totalTime, err := GetTotalDistanceAndTime(userId)
	if err != nil {
		fmt.Println("GET USER'S TOTAL RECORD DATA ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	response := struct {
		UserID        string `json:"user_id"`
		Username      string `json:"username"`
		ProfileImage  string `json:"profile_image"`
		TotalDistance string `json:"total_distance"`
		TotalTime     string `json:"total_time"`
		BestRecord    struct {
			Distance string `json:"distance"`
			Time     string `json:"time"`
		} `json:"best_record"`
		WeeklyGoal string `json:"weekly_goal"`
		Nickname   string `json:"nickname"`
	}{
		UserID:        userId,
		Username:      u.Username,
		ProfileImage:  u.ProfileImage,
		TotalDistance: strconv.FormatFloat(totalDistance, byte('f'), 2, 64),
		TotalTime:     totalTime.String(),
		BestRecord: struct {
			Distance string "json:\"distance\""
			Time     string "json:\"time\""
		}{
			Distance: record.Distance,
			Time:     record.Time,
		},
		WeeklyGoal: u.WeeklyGoal,
		Nickname:   u.Nickname,
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

func UpdateProfileHandler(w http.ResponseWriter, r *http.Request) {
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

	if err := database.PutUser(userId, "nickchange", "test111", ""); err != nil {
		fmt.Println("PUT USER PROFILE ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	response := struct {
		Message string `json:"message"`
	}{
		Message: "Profile updated successfully.",
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

func GetBestRecordByUserId(userId string) (*database.Session, error) {
	return database.GetBestRecordByUserId(userId)
}

func GetTotalDistanceAndTime(userId string) (totalDistance float64, totalTime time.Duration, err error) {
	records, err := database.GetTotalSessions(userId)
	if err != nil {
		return 0, 0, err
	}

	d := 0.0
	var t time.Duration

	for _, r := range *records {
		f, _ := strconv.ParseFloat(r.Distance, 64)
		d += f
		tmp, _ := time.ParseDuration(r.Time)
		t += tmp
	}

	return d, t, nil
}
