package main

import (
	"fmt"
	"khu-capstone-18-backend/handler"
	"khu-capstone-18-backend/repository"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

func main() {
	if err := repository.ConnectDB(); err != nil {
		fmt.Println("START")
		fmt.Println("DB CONNECTION ERR:", err)
		return
	}

	if err := repository.TestDB(); err != nil {
		fmt.Println("DB PING ERR:", err)
		return
	}

	r := mux.NewRouter()
	r.HandleFunc("/auth/signup", handler.SignUpHandler).Methods("POST")
	r.HandleFunc("/auth/login", handler.LoginHandler).Methods("POST")
	r.HandleFunc("/auth/logout", handler.LogoutHandler).Methods("POST")
	r.HandleFunc("/{any:.+}", handler.OptionHandler).Methods("OPTIONS")
	r.HandleFunc("/competitions", handler.CompetitionHandler).Methods("GET")
	r.HandleFunc("/competition", handler.PostCompetitionHandler).Methods("POST")

	r.HandleFunc("/users/{userId}/profile", handler.ProfileHandler).Methods("GET")
	r.HandleFunc("/profile", handler.UpdateProfileHandler).Methods("PUT")

	r.HandleFunc("/users/{userId}/sessions", handler.GetSessionHandler).Methods("GET")
	r.HandleFunc("/users/{userId}/real-time", handler.StartRealtimeHandler).Methods("POST")
	r.HandleFunc("/courses", handler.GetCoursesHandler).Methods("GET")
	r.HandleFunc("/course", handler.PostCourseHandler).Methods("POST")

	r.HandleFunc("/course/start", handler.CreateCourseStartHandler).Methods("POST")
	r.HandleFunc("/courses/{courseId}/child/start", handler.CreateChildCourseStartHandler).Methods("POST")
	r.HandleFunc("/courses/{courseId}/location", handler.CreateCourseLocaionHandler).Methods("POST")
	r.HandleFunc("/courses/{courseId}/childs/{childId}/location", handler.CreateCourseLocaionHandler).Methods("POST")

	r.HandleFunc("/courses/{courseId}/end", handler.CreateCourseEndHandler).Methods("POST")

	// r.HandleFunc("/test/{userId}", handler.UpdateProfileHandler).Methods("GET")
	// r.HandleFunc("/auth/reset-password", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/user/profile", handler.LogoutHandler).Methods("PUT")
	// r.HandleFunc("/user/{user_id}/real-time", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/competition", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("GET")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("DELETE")

	log.Fatal(http.ListenAndServe(":8080", r))
}
