package main

import (
	"fmt"
	"khu-capstone-18-backend/database"
	"khu-capstone-18-backend/handler"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

func main() {
	if err := database.ConnectDB(); err != nil {
		fmt.Println("DB CONNECTION ERR:", err)
		return
	}

	if err := database.TestDB(); err != nil {
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
	r.HandleFunc("/user/profile/{userId}", handler.ProfileHandler).Methods("GET")

	// r.HandleFunc("/auth/reset-password", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/user/profile", handler.LogoutHandler).Methods("PUT")
	// r.HandleFunc("/user/{user_id}/sessions", handler.LogoutHandler).Methods("GET")
	// r.HandleFunc("/user/{user_id}/session", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/user/{user_id}/real-time", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/courses", handler.LogoutHandler).Methods("GET")
	// r.HandleFunc("/courses", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/competition", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("POST")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("GET")
	// r.HandleFunc("/users/{user_id}/competitions/{competition_Id}", handler.LogoutHandler).Methods("DELETE")

	log.Fatal(http.ListenAndServe(":8080", r))
}
