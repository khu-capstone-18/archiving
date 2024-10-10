package competition

// import (
// 	"encoding/json"
// 	"fmt"
// 	"log"
// 	"net/http"
// 	"strings"

// 	"github.com/PuerkitoBio/goquery"
// 	"golang.org/x/net/html/charset"
// 	"golang.org/x/text/transform"
// )

// func GetCompetitionsFromWebsite(url string) error {
// 	res, err := http.Get(url)
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	defer res.Body.Close()
// 	if res.StatusCode != 200 {
// 		log.Fatalf("status code error: %d %s", res.StatusCode, res.Status)
// 	}

// 	utf8Body, err := convertToUTF8(body, "text/html")
// 	if err != nil {
// 		log.Fatalf("Failed to convert body to UTF-8: %v", err)
// 	}

// 	doc, err := goquery.NewDocumentFromReader(utf8Body)
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	doc.Find("tbody").Each(func(i int, s *goquery.Selection) {
// 		// For each item found, get the title
// 		title := s.Find("a").Text()
// 		fmt.Printf("Review %d: %s\n", i, title)
// 	})

// 	return nil
// }

// func convertToUTF8(body []byte, contentType string) ([]byte, error) {
// 	// 기본 인코딩을 UTF-8로 설정
// 	decoder := charset.NewDecoderLabel("utf-8")

// 	// Content-Type 헤더에서 charset 추출
// 	if strings.Contains(contentType, "charset=") {
// 		parts := strings.Split(contentType, "charset=")
// 		if len(parts) > 1 {
// 			charsetName := strings.TrimSpace(parts[1])
// 			decoder = charset.NewDecoderLabel(charsetName)
// 			json.Decoder()
// 		}
// 	}

// 	// 변환 수행
// 	transformedBody, _, err := transform.Bytes(decoder, body)
// 	if err != nil {
// 		return nil, err
// 	}

// 	return transformedBody, nil
// }
