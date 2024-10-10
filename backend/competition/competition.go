package competition

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/PuerkitoBio/goquery"
	"golang.org/x/text/encoding/korean"
	"golang.org/x/text/transform"
)

type Competition struct {
	Name     string `json:"competition_name"`
	Date     string `json:"date"`
	Details  string `json:"details"`
	Location struct {
		Latitude  string `json:"latitude"`
		Longitude string `json:"longitude"`
	} `json:"location"`
	Link string `json:"registration_link"`
}

func GetCompetitionsFromWebsite(url string) error {
	res, err := http.Get(url)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		log.Fatalf("status code error: %d %s", res.StatusCode, res.Status)
	}

	if err != nil {
		log.Fatalf("Failed to convert body to UTF-8: %v", err)
	}

	bt, _ := io.ReadAll(res.Body)

	result, _, _ := transform.String(korean.EUCKR.NewDecoder(), string(bt))

	doc, err := goquery.NewDocumentFromReader(strings.NewReader(result))
	if err != nil {
		log.Fatal(err)
	}

	doc.Find("p table tbody tr td p table tbody tr td table tbody").Each(func(index int, row *goquery.Selection) {
		row.Find("tr").Each(func(i int, r *goquery.Selection) {
			r.Find("td").Each(func(i2 int, r2 *goquery.Selection) {
				if i2 == 0 && i%2 != 1 {
					date := r2.Find("div b").Eq(0).Text()
					day := r2.Find("div font").Eq(1).Text()
					fmt.Println("Date:", date)
					fmt.Println("Day:", day)
				}
				if i2 == 1 {
					name := r2.Find("b font a").Eq(0).Text()
					fmt.Println("Name:", name)
				}
				if i2 == 2 {
					l := r2.Find("div").Eq(0).Text()
					fmt.Println("Location:", l)
				}
				if i2 == 3 {
					h := r2.Find("div").Eq(0).Text()
					before, after, _ := strings.Cut(h, "\t")
					before, _ = strings.CutSuffix(before, "\n")
					after, _ = strings.CutSuffix(after, "\n")
					after, _ = strings.CutPrefix(after, " ")
					before, _ = strings.CutPrefix(before, " ")
					fmt.Println("Holder:", before)
					fmt.Println("Phone:", after)
				}
			})
		})
	})

	return nil
}
