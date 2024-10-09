package database

func CreateUser(username, password, email, nickname string) error {
	_, err := db.Exec(`INSERT INTO users (username, password, email, nickname) VALUES ('` + username + `', '` + password + `', '` + email + `', '` + nickname + `')`)
	if err != nil {
		return err
	}

	return nil
}

func GetUserID(username string) (int, error) {
	uid := 0
	r := db.QueryRow(`SELECT id FROM users WHERE username='` + username + `'`)
	if err := r.Scan(&uid); err != nil {
		return uid, err
	}
	return uid, nil
}

func GetPassword(username string) (string, error) {
	pw := ""
	r := db.QueryRow(`SELECT password FROM users WHERE username='` + username + `'`)
	if err := r.Scan(&pw); err != nil {
		return pw, err
	}
	return pw, nil
}
