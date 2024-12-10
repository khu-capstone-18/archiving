package handler

import (
	"encoding/json"
	"fmt"
	"khu-capstone-18-backend/competition"
	"net/http"
)

func CompetitionHandler(w http.ResponseWriter, r *http.Request) {
	// authHeader := r.Header.Get("Authorization")
	// if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
	// 	fmt.Println("NO JWT TOKEN EXIST ERROR")
	// 	w.WriteHeader(http.StatusUnauthorized)
	// 	return
	// }

	// // Bearer 토큰 추출
	// t := authHeader[7:]

	// _, err := auth.ValidateJwtToken(t)
	// if err != nil {
	// 	fmt.Println("JWT TOKEN VALIDATION ERR:", err)
	// 	w.WriteHeader(http.StatusUnauthorized)
	// 	return
	// }

	competitions, err := competition.GetCompetitionsFromWebsite("http://www.roadrun.co.kr/schedule/list.php")
	if err != nil {
		fmt.Println("CRAWLING ERR:", err)
		return
	}

	b, _ := json.Marshal(competitions)
	w.WriteHeader(http.StatusOK)
	w.Write(b)
}
