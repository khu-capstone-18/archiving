package handler

import (
	"encoding/json"
	"fmt"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/database"
	"net/http"

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
