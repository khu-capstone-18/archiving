package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"khu-capstone-18-backend/auth"
	"khu-capstone-18-backend/model"
	"khu-capstone-18-backend/repository"
	"khu-capstone-18-backend/util"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

func CreateChildCourseStartHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	userId, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	vars := mux.Vars(r)
	courseId := vars["courseId"]

	req := repository.Course{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	req.ID = uuid.NewString()
	req.UserID = userId
	req.CopyCourseID = courseId

	if err := repository.CreateCourseStart(&req); err != nil {
		fmt.Println("Create Course Start Handler Err:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		CourseID     string `json:"course_id"`
		CopyCourseID string `json:"copy_course_id"`
	}{
		CourseID:     req.ID,
		CopyCourseID: req.CopyCourseID,
	}

	data, _ := json.Marshal(resp)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func GetCoursesHandler(w http.ResponseWriter, r *http.Request) {
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

	crs, err := repository.GetCourses()
	if err != nil {
		fmt.Println("GET USER COURSES ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// 응답
	resp, err := json.Marshal(crs)
	if err != nil {
		fmt.Println("JSON MARSHALING ERR:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}

// {
// 	user_id: string,
// 	location: [
//     {
//       latitude: double(float),
//       longitude: double(float),
// 	  },
// 	],
// 	current_time: string,
// }

func CreateCourseStartHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		fmt.Println("NO JWT TOKEN EXIST ERROR")
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	// Bearer 토큰 추출
	t := authHeader[7:]

	userId, err := auth.ValidateJwtToken(t)
	if err != nil {
		fmt.Println("JWT TOKEN VALIDATION ERR:", err)
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	req := repository.Course{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	req.ID = uuid.NewString()
	req.UserID = userId

	if err := repository.CreateCourseStart(&req); err != nil {
		fmt.Println("Create Course Start Handler Err:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	resp := struct {
		CourseID string `json:"course_id"`
	}{
		CourseID: req.ID,
	}

	data, _ := json.Marshal(resp)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func CreateCourseEndHandler(w http.ResponseWriter, r *http.Request) {
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

	req := model.CourseTest{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	pnts, err := repository.GetPoints(req.CourseID, 0)
	if err != nil {
		fmt.Println("ERR GETTING POINTS : ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	var totalDistance float64
	var startTime time.Time
	var endTime time.Time
	var beforeLatitude float64
	var beforeLongitude float64

	for i, p := range pnts {
		if i == len(pnts)-1 {
			endTime = p.CurrentTime
		}
		if i == 0 {
			startTime = p.CurrentTime
			beforeLatitude = p.Location.Latitude
			beforeLongitude = p.Location.Longitude
			continue
		}

		// 두 쌍의 경도, 위도 사이 거리 계산
		totalDistance += util.CalculateDistance(
			model.Location{
				Longitude: beforeLongitude,
				Latitude:  beforeLatitude,
			},
			model.Location{
				Longitude: p.Location.Longitude,
				Latitude:  p.Location.Latitude,
			},
		)
		beforeLatitude = p.Location.Latitude
		beforeLongitude = p.Location.Longitude
	}

	totalTime := endTime.Sub(startTime)
	totalPaceSecond := totalTime.Seconds() / totalDistance
	m := int(totalPaceSecond / 1)
	s := int((totalPaceSecond - float64(int(totalPaceSecond))) * 60)
	totalPace := fmt.Sprintf("%d:%d", m, s)
	if err != nil {
		fmt.Println("ERR PARSING TIME:", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	err = repository.CreateCourseEnd(req.Public, req.CourseID)
	if err != nil {
		fmt.Println("ERR CREATECOURSESTESTEND : ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	repository.UpdateCourseRecord(req.CourseID, fmt.Sprintf("%.2f", totalDistance), totalTime)

	resp := struct {
		TotalPace     string        `json:"total_pace"`
		TotalDistance string        `json:"total_distance"`
		TotalTime     time.Duration `json:"total_time"`
	}{
		TotalPace:     totalPace,
		TotalDistance: fmt.Sprintf("%.2fkm", totalDistance),
		TotalTime:     totalTime,
	}

	data, _ := json.Marshal(resp)

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func CreateCourseLocaionHandler(w http.ResponseWriter, r *http.Request) {
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

	vars := mux.Vars(r)
	courseId := vars["courseId"]
	childId, ok := vars["childId"]

	// 요청 데이터 파싱
	req := model.Point{}
	b, _ := io.ReadAll(r.Body)
	json.Unmarshal(b, &req)

	req.CourseID = courseId
	if ok {
		req.CourseID = childId
	}
	// 다음 point 순서 계산
	order := repository.GetLatestPointOrder(req.CourseID)
	req.Order = order + 1

	// Point 생성
	req.ID = uuid.NewString()
	err = repository.CreatePoint(&req)
	if err != nil {
		fmt.Println("ERR CREATING POINT : ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	// child 코스 러닝 데이터 계산
	childPnts, err := repository.GetPoints(req.CourseID, 0)
	if err != nil {
		fmt.Println("ERR GETTING CHILD POINTS : ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	fmt.Println()
	fmt.Println("START")
	for _, p := range childPnts {
		fmt.Println(*p)
	}
	fmt.Println("END")
	fmt.Println()

	childDistance := 0.00
	childPace := 0
	var childElasedTime time.Duration
	var beforeLocation model.Location
	beforeTime := time.Time{}
	for i, p := range childPnts {
		if i == 0 {
			beforeLocation.Latitude = p.Location.Latitude
			beforeLocation.Longitude = p.Location.Longitude
			beforeTime = p.CurrentTime
			continue
		}

		dst := util.CalculateDistance(
			beforeLocation,
			model.Location{Longitude: p.Location.Longitude, Latitude: p.Location.Latitude},
		)
		childDistance += dst

		beforeLocation.Latitude = p.Location.Latitude
		beforeLocation.Longitude = p.Location.Longitude

		dur := p.CurrentTime.Sub(beforeTime)
		childElasedTime += dur

		beforeTime = p.CurrentTime
		fmt.Println("ElasedTime:", childElasedTime)
		fmt.Println("Distance:", strconv.FormatFloat(childDistance, 'f', 2, 64)+"km")
		pace := (childElasedTime.Seconds()) / childDistance
		if childDistance == 0 {
			pace = 0
		}
		fmt.Println("Pace:", int(pace))
		childPace = int(pace)
	}

	parentDistance := 0.00
	parentPace := 0
	var parentElasedTime time.Duration

	if ok {
		parentPnts, err := repository.GetPoints(courseId, len(childPnts))
		if err != nil {
			fmt.Println("ERR GETTING PARENT POINTS : ", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		var parentBeforeLocation model.Location
		parentBeforeTime := time.Time{}
		for i, p := range parentPnts {
			if i == 1 {
				parentBeforeLocation.Latitude = p.Location.Latitude
				parentBeforeLocation.Longitude = p.Location.Longitude
				continue
			}

			dst := util.CalculateDistance(
				parentBeforeLocation,
				model.Location{Longitude: p.Location.Longitude, Latitude: p.Location.Latitude},
			)
			parentDistance += dst

			parentBeforeLocation.Latitude = p.Location.Latitude
			parentBeforeLocation.Longitude = p.Location.Longitude

			dur := p.CurrentTime.Sub(parentBeforeTime)
			parentElasedTime += dur

			parentBeforeTime = p.CurrentTime

			pace := parentElasedTime / time.Duration(parentDistance)
			parentPace = int(pace.Seconds())
		}
	}

	data := struct {
		CurrentPace   int    `json:"current_pace"`
		GapPace       int    `json:"gap_pace"`
		TotalDistance string `json:"total_distance"`
		GapDistance   string `json:"gap_distance"`
		ElasedTime    int    `json:"elapsed_time"`
		GapTime       int    `json:"gap_time"`
	}{
		CurrentPace:   childPace,
		GapPace:       childPace - parentPace,
		TotalDistance: strconv.FormatFloat(childDistance, 'f', 2, 64),
		GapDistance:   strconv.FormatFloat(childDistance-parentDistance, 'f', 2, 64),
		ElasedTime:    int(childElasedTime.Seconds()),
		GapTime:       int(childElasedTime.Seconds() - parentElasedTime.Seconds()),
	}

	resp, _ := json.Marshal(data)
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(http.StatusOK)
	w.Write(resp)
}
