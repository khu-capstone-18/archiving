package database

import (
	"khu-capstone-18-backend/competition"
)

func CreateCompetition(cpt competition.Competition) error {
	_, err := db.Exec(`INSERT INTO competitions (name, date, latitude, longitude, link, details) VALUES ('` + cpt.Name + `', '` + cpt.Date + `', '` + cpt.Location.Latitude + `', '` + cpt.Location.Longitude + `', '` + cpt.Link + `', '` + cpt.Details + `')`)
	if err != nil {
		return err
	}

	return nil
}

func GetCompetitionID(name, date string) (int, error) {
	uid := 0
	r := db.QueryRow(`SELECT id FROM competitions WHERE name='` + name + `' and date='` + date + `'`)
	if err := r.Scan(&uid); err != nil {
		return uid, err
	}
	return uid, nil
}
