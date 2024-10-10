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
		w.WriteHeader(http.StatusInternalServerError)
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
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf(`{"message": "%s"}`, "Logout successful")))
}
