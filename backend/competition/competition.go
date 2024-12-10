package competition

import (
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/PuerkitoBio/goquery"
	"golang.org/x/text/encoding/korean"
	"golang.org/x/text/transform"
)

type Competition struct {
	Date     string `json:"date"`
	Day      string `json:"day"`
	Name     string `json:"name"`
	Location string `json:"location"`
	Holder   string `json:"holder"`
	Phone    string `json:"phone"`
}

func GetCompetitionsFromWebsite(url string) ([]Competition, error) {
	competitions := []Competition{}
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

	doc.Find("p table tbody tr td p table tbody tr td table").Each(func(index int, row *goquery.Selection) {
		if index == 5 {
			row.Find("tbody").Each(func(index2 int, r3 *goquery.Selection) {
				r3.Find("tr").Each(func(i int, r *goquery.Selection) {
					tmp := Competition{}
					r.Find("td").Each(func(i2 int, r2 *goquery.Selection) {
						if i2 == 0 && i%2 != 1 {
							date := r2.Find("div b").Eq(0).Text()
							day := r2.Find("div font").Eq(1).Text()
							if day == "" || date == "" {
							}
							tmp.Date = date
							tmp.Day = day
						}
						if i2 == 1 {
							name := r2.Find("b font a").Eq(0).Text()
							tmp.Name = name
						}
						if i2 == 2 {
							l := r2.Find("div").Eq(0).Text()
							tmp.Location = l
						}
						if i2 == 3 {
							h := r2.Find("div").Eq(0).Text()
							before, after, _ := strings.Cut(h, "\t")
							before, _ = strings.CutSuffix(before, "\n")
							after, _ = strings.CutSuffix(after, "\n")
							after, _ = strings.CutPrefix(after, " ")
							before, _ = strings.CutPrefix(before, " ")
							tmp.Holder = before
							tmp.Phone = after
						}
					})
					if tmp.Name != "" {
						competitions = append(competitions, tmp)
					}
				})
			})
		}
	})
	return competitions, nil
}
