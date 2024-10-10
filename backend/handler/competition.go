package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/competition"
	"khu-capstone-18-backend/database"
	"net/http"
	"strconv"
)

func CompetitionHandler(w http.ResponseWriter, r *http.Request) {
	if err := competition.GetCompetitionsFromWebsite("http://www.roadrun.co.kr/schedule/list.php"); err != nil {
		fmt.Println("CRAWLING ERR:", err)
		return
	}
}

func PostCompetitionHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("PostCompetitionHandler START")
	req := competition.Competition{}
	b, _ := io.ReadAll(r.Body)

	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	fmt.Println(req.Location.Longitude)
	fmt.Println(req.Location.Latitude)

	// DB에 대회정보 삽입
	if err := database.CreateCompetition(req); err != nil {
		fmt.Println("CREATE COMPETITION ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// DB에서 대회ID 조회
	id, err := database.GetCompetitionID(req.Name, req.Date)
	if err != nil {
		fmt.Println("GET COMPETITION ID ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		Message       string `json:"message"`
		CompetitionID string `json:"competition_id"`
	}{
		Message:       "Competition registered successfully.",
		CompetitionID: strconv.Itoa(id),
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
