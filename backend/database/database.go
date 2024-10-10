package database

import (
	"database/sql"
	"fmt"
)

var db *sql.DB

const dbName = "testdb"
const dbUser = "postgres"
const dbPassword = "gusqls457"
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

// curl -XPOST localhost:8080/competition -d '{"competition_name":"testn124","date":"2023-01-01","details":"testdetails", "location":{"latitude":"127.012458", "longitude":"134.532553"}, "registration_link":"https://example.com"}'
