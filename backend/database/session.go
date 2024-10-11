package database

import (
	"strconv"
	"time"
)

type Session struct {
	ID             string        `json:"session_id"`
	Distance       float64       `json:"total_distance"`
	Time           string        `json:"total_time"`
	StartTime      string        `json:"start_time"`
	EndTime        string        `json:"end_time"`
	AveragePace    time.Duration `json:"average_pace"`
	CaloiresBurned int           `json:"calories_burned"`
}

func GetBestRecordByUserId(userId string) (*Session, error) {
	record := Session{}
	r := db.QueryRow(`SELECT distance, time FROM sessions WHERE user_id=1 ORDER BY distance DESC LIMIT 1`)
	if err := r.Scan(&record.Distance, &record.Time); err != nil {
		return &record, err
	}
	return &record, nil
}

func GetTotalSessions(userId string) (*[]Session, error) {
	records := []Session{}
	record := Session{}
	r, err := db.Query(`SELECT distance, time FROM sessions WHERE user_id=` + userId)
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

func PostSession(userId string, ses *Session) error {
	if _, err := db.Exec(`INSERT INTO sessions (user_id, distance, time, start_time, end_time, average_pace, calories_burned) VALUES (` + userId + `, '` + strconv.FormatFloat(ses.Distance, byte('f'), 2, 64) + `', '` + ses.Time + `', '` + ses.StartTime + `', '` + ses.EndTime + `', '` + ses.AveragePace.String() + `', '` + strconv.Itoa(ses.CaloiresBurned) + `')`); err != nil {
		return err
	}
	return nil
}
