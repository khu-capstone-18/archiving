package repository

import (
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

type User struct {
	UserID       string  `json:"user_id"`
	Username     string  `json:"username"`
	ProfileImage string  `json:"profile_image"`
	WeeklyGoal   string  `json:"weekly_goal"`
	Email        string  `json:"email"`
	Nickname     string  `json:"nickname"`
	Weight       float64 `json:"weight"`
}

func CreateUser(id, username, password, email, weight string) error {
	_, err := db.Exec(`INSERT INTO users (id, username, password, email, weight) VALUES ('` + id + `', '` + username + `', '` + password + `', '` + email + `', ` + weight + `)`)
	if err != nil {
		return err
	}

	return nil
}

func GetUserID(username string) (string, error) {
	uid := ""
	r := db.QueryRow(`SELECT id FROM users WHERE username='` + username + `'`)
	if err := r.Scan(&uid); err != nil {
		return uid, err
	}
	return uid, nil
}

func GetPasswordByUsername(username string) (password string, err error) {
	pw := ""
	r := db.QueryRow(`SELECT password FROM users WHERE username ='` + username + `'`)
	if err := r.Scan(&pw); err != nil {
		return pw, err
	}
	return pw, nil
}

func GetPasswordByEmail(email string) (password string, err error) {
	pw := ""
	r := db.QueryRow(`SELECT password FROM users WHERE email ='` + email + `'`)
	if err := r.Scan(&pw); err != nil {
		return pw, err
	}
	return pw, nil
}

func GetUser(uid string) (*User, error) {
	user := User{}
	r := db.QueryRow(`SELECT username, email, profile_image, weekly_goal, weight FROM users WHERE id='` + uid + `'`)
	if err := r.Scan(&user.Username, &user.Email, &user.ProfileImage, &user.WeeklyGoal, &user.Weight); err != nil {
		return &user, err
	}
	return &user, nil
}

func PutUser(userId, profileImage, weeklyGoal string) error {
	query := []string{}
	if profileImage != "" {
		query = append(query, `profile_image = '`+profileImage+`'`)
	}
	if weeklyGoal != "" {
		query = append(query, `weekly_goal = '`+weeklyGoal+`'`)
	}
	c := strings.Join(query, ", ")

	_, err := db.Exec(`UPDATE users SET ` + c + ` WHERE id = '` + userId + `'`)
	if err != nil {
		return err
	}

	return nil
}

func GetUserWeight(userId int) (int, error) {
	weight := 0
	r := db.QueryRow(`SELECT weight FROM users WHERE id='` + strconv.Itoa(userId) + `'`)
	if err := r.Scan(&weight); err != nil {
		return weight, err
	}
	return weight, nil
}

func UpdateCourseRecord(cid, distance string, t time.Duration) error {
	bestDst, bestTime := "", ""
	r := db.QueryRow(`SELECT total_distance, total_time FROM courses WHERE id='` + cid + `'`)
	r.Scan(&bestDst, &bestTime)

	f1, _ := strconv.ParseFloat(distance, 32)
	f2, _ := strconv.ParseFloat(bestDst, 32)
	if f1 > f2 {
		db.Exec(`UPDATE courses SET total_distance = '` + distance + `', total_time = '` + strconv.Itoa(int(t.Seconds())) + `' WHERE id = '` + cid + `'`)
	}

	return nil
}

func GetUserBestRecord(uid string) (bestDistance string, bestTime time.Duration, err error) {
	bestDst := ""
	var bTime time.Duration
	r := db.QueryRow(`SELECT total_distance, total_time FROM courses ORDER BY total_distance DESC WHERE creator_id='` + uid + `' LIMIT 1`)
	if err := r.Scan(&bestDst, &bTime); err == sql.ErrNoRows {
		return bestDst, bTime, err
	}
	fmt.Println("bestDst:", bestDst)
	fmt.Println("bestTime:", bTime)

	return bestDst, bTime, nil
}

func GetUserTotalRecord(uid string) (totaltDistance float64, totalTime time.Duration, err error) {
	tDistance := 0.0
	var tTime time.Duration
	r, err := db.Query(`SELECT total_distance, total_time FROM courses WHERE creator_id='` + uid + `'`)
	if err != nil {
		return 0.0, 0, err
	}

	for r.Next() {
		tmpDistance := 0.0
		tmpTime := ""
		r.Scan(&tmpDistance, &tmpTime)
		t, _ := time.ParseDuration(tmpTime)
		tTime += t
		tDistance += tmpDistance
	}

	return tDistance, tTime, nil
}
