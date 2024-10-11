package database

type Route struct {
	ID        int
	SessionID int
	Latitude  string `json:"latitude"`
	Longitude string `json:"longitude"`
	Order     int
}
