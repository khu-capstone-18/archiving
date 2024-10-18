package model

type User struct {
	UserID       string  `json:"user_id"`
	Username     string  `json:"username"`
	ProfileImage string  `json:"profile_image"`
	WeeklyGoal   string  `json:"weekly_goal"`
	Email        string  `json:"email"`
	Nickname     string  `json:"nickname"`
	Weight       float64 `json:"weight"`
}
