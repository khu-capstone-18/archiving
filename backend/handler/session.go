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

func GetSessionHandler(w http.ResponseWriter, r *http.Request) {
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

	sessions, err := database.GetSessions(userId)
	if err != nil {
		fmt.Println("GET USER SESSIONS ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	resp, err := json.Marshal(sessions)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

func PostSessionHandler(w http.ResponseWriter, r *http.Request) {
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

	req := database.Session{}
	b, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	d, err := time.ParseDuration(req.Time)
	if err != nil {
		fmt.Println("PARSE SESSION TIME ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	pace := int(d.Seconds() / req.Distance)

	sec, err := time.ParseDuration(strconv.Itoa(pace))
	if err != nil {
		fmt.Println("CONVERT PACE TIME TO SEC ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	req.AveragePace = sec

	err = database.PostSession(userId, &req)
	if err != nil {
		fmt.Println("POST USER SESSION ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	weight, err := database.GetUserWeight(userId)
	if err != nil {
		fmt.Println("GET USER WEIGHT ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	req.CaloiresBurned = int(float64(weight) * req.Distance)

	// 응답
	response := struct {
		Message       string `json:"message"`
		SessionID     int    `json:"session_id"`
		StartTime     string `json:"start_time"`
		TotalDistance string `json:"total_distance"`
	}{
		Message:       "Running session saved successfully.",
		SessionID:     0,
		StartTime:     "",
		TotalDistance: "",
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
