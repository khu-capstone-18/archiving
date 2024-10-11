package database

type Session struct {
	Distance string `json:"distance"`
	Time     string `json:"time"`
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
