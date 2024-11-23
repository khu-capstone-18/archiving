package model

type User struct {
	UserID       string `json:"user_id"`
	Username     string `json:"username"`
	Password     string `json:"password"`
	ProfileImage string `json:"profile_image"`
	WeeklyGoal   string `json:"weekly_goal"`
	Email        string `json:"email"`
	Nickname     string `json:"nickname"`
	Weight       string `json:"weight"`
}
