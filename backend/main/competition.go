package main

import (
	"fmt"
	"khu-capstone-18-backend/competition"
	"net/http"
)

func CompetitionHandler(w http.ResponseWriter, r *http.Request) {
	if err := competition.GetCompetitionsFromWebsite("http://www.roadrun.co.kr/schedule/list.php"); err != nil {
		fmt.Println("CRAWLING ERR:", err)
		return
	}
}
