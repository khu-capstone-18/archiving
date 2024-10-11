package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/database"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

var channel = make(chan database.Realtime)

func GetSessionHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]

	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	_, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	sessions, err := database.GetSessions(userId)
	if err != nil {
		fmt.Println("GET USER SESSIONS ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	resp, err := json.Marshal(sessions)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

func StartRealtimeHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]
	id, _ := strconv.Atoi(userId)

	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	_, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	req := database.Point{}
	b, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(b, &req); err != nil {
		fmt.Println("UNMARSHAL ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	rt := database.Realtime{
		UserID:    id,
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		StartTime: time.Now().Format("15h04m05s"),
		Distance:  0.00,
		Exit:      false,
		Route:     []*database.Point{},
	}

	rt.Route = append(rt.Route, &database.Point{
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
	})

	channel <- rt

	go realtimeChannel(rt)
	return
}

func realtimeChannel(rt database.Realtime) error {
	crs := rt
	weight, _ := database.GetUserWeight(crs.UserID)
	for req := range channel {
		if req.Exit {
			req := database.Session{
				Distance:       rt.Distance,
				Time:           rt.ElapsedTime,
				StartTime:      rt.StartTime,
				EndTime:        time.Now().Format("15h04m05s"),
				AveragePace:    rt.AveragePace,
				CaloiresBurned: rt.CaloiresBurned,
				Route:          rt.Route,
			}
			err := database.PostSession(&req)
			if err != nil {
				fmt.Println("POST USER SESSION ERR:", err)
				return err
			}
			break
		}
		crs.UserID = req.UserID
		dst := haversine(req.Latitude, req.Longitude, crs.Latitude, crs.Longitude)
		crs.Distance += dst
		crs.ElapsedTime = getElapsedTime(crs.StartTime)
		crs.AveragePace = getAveragePace(crs.ElapsedTime, crs.Distance)
		crs.CaloiresBurned = int(float64(weight) * req.Distance)
		crs.Route = append(crs.Route, &database.Point{
			Latitude:  req.Latitude,
			Longitude: req.Longitude,
		})
	}

	return nil
}

// 두 개의 (위도, 경도) 사이의 거리 계산
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const radiusEarthKm = 6371.0

	dLat := (lat2 - lat1) * (math.Pi / 180.0)
	dLon := (lon2 - lon1) * (math.Pi / 180.0)

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*(math.Pi/180.0))*math.Cos(lat2*(math.Pi/180.0))*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	distance := radiusEarthKm * c

	return distance
}

// 경과시간 계산
func getElapsedTime(startTime string) string {
	t, _ := time.Parse("15h04m05s", startTime)
	return t.Format("15h04m05s")
}

func getAveragePace(elapsedTime string, distance float64) time.Duration {
	d, _ := time.ParseDuration(elapsedTime)
	pace := int(d.Seconds() / distance)

	sec, err := time.ParseDuration(strconv.Itoa(pace))
	if err != nil {
		fmt.Println("CALCULATE PACE ERR:", err)
		return 0
	}

	return sec
}
