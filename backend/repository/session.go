package repository

import (
	"database/sql"
	"strconv"
	"time"
)

type Session struct {
	ID             int           `json:"session_id"`
	UserId         int           `json:"user_id"`
	Distance       float64       `json:"total_distance"`
	Time           string        `json:"total_time"`
	StartTime      string        `json:"start_time"`
	EndTime        string        `json:"end_time"`
	AveragePace    time.Duration `json:"average_pace"`
	CaloiresBurned int           `json:"calories_burned"`
	Route          []*Point
}

type Realtime struct {
	UserID         int           `json:"user_id"`
	Distance       float64       `json:"total_distance"`
	CaloiresBurned int           `json:"calories_burned"`
	AveragePace    time.Duration `json:"average_pace"`
	StartTime      string        `json:"start_time"`
	ElapsedTime    string        `json:"elapsed_time"`
	Latitude       float64       `json:"latitude"`
	Longitude      float64       `json:"longitude"`
	Route          []*Point      `json:"route"`
	Exit           bool          `json:"exit"`
}

func GetBestRecordByUserId(userId string) (*Session, error) {
	record := Session{}
	r := db.QueryRow(`SELECT distance, time FROM sessions WHERE user_id='` + userId + `' ORDER BY distance DESC LIMIT 1`)
	err := r.Scan(&record.Distance, &record.Time)
	r.Scan()
	if err == sql.ErrNoRows {
		return &record, nil
	}
	if err != nil {
		return &record, err
	}
	return &record, nil
}

func GetTotalSessions(userId string) (*[]Session, error) {
	records := []Session{}
	record := Session{}
	r, err := db.Query(`SELECT distance, time FROM sessions WHERE user_id='` + userId + `'`)
	if err == sql.ErrNoRows {
		return &records, nil
	}
	if err != nil {
		return nil, err
	}
	defer r.Close()

	for r.Next() {
		err := r.Scan(&record.Distance, &record.Time)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}
	return &records, nil
}

func GetSessions(userId string) (*[]Session, error) {
	sessions := []Session{}
	session := Session{}
	r, err := db.Query(`SELECT id, distance, time, start_time, end_time, average_pace, calories_burned FROM sessions WHERE user_id=` + userId)
	if err != nil {
		return nil, err
	}
	defer r.Close()

	for r.Next() {
		err := r.Scan(&session.ID, &session.Distance, &session.Time, &session.StartTime, &session.EndTime, &session.AveragePace, &session.AveragePace)
		if err != nil {
			return nil, err
		}
		sessions = append(sessions, session)
	}
	return &sessions, nil
}

func PostSession(ses *Session) error {
	if _, err := db.Exec(`INSERT INTO sessions (user_id, distance, time, start_time, end_time, average_pace, calories_burned) VALUES (` + strconv.Itoa(ses.UserId) + `, '` + strconv.FormatFloat(ses.Distance, byte('f'), 2, 64) + `', '` + ses.Time + `', '` + ses.StartTime + `', '` + ses.EndTime + `', '` + ses.AveragePace.String() + `', '` + strconv.Itoa(ses.CaloiresBurned) + `')`); err != nil {
		return err
	}
	return nil
}
