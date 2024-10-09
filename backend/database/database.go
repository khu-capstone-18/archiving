package database

import (
	"database/sql"
	"fmt"
)

var db *sql.DB

const dbName = "testdb"
const dbUser = "postgres"
const dbPassword = "tester1234"
const dbHost = "localhost"

func ConnectDB() error {
	src := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", dbHost, 5432, dbUser, dbPassword, dbName)
	database, err := sql.Open("postgres", src)

	if err != nil {
		return err
	}

	db = database
	return nil
}

func TestDB() error {
	if err := db.Ping(); err != nil {
		fmt.Println("DB PING ERR:", err)
		return err
	}
	return nil
}

// curl -X POST -H "Content-Type: application/json" -d '{"username":"user","password":"password","email":"test@naver.com","nickname":"testnick"}' http://localhost:8080/auth/signup
