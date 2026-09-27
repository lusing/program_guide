// 30_encoding：csv 表格、xml 标签映射、gob 自描述二进制。
// 对照 docs/30-encoding.md。
package main

import (
	"bytes"
	"encoding/csv"
	"encoding/gob"
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

// ---------- CSV ----------

// Row 是一行用户记录。
type Row struct {
	Name string
	Age  int
	City string
}

// WriteCSV 把行集写成 CSV 文本（演示自动引号转义）。
func WriteCSV(rows []Row) string {
	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	_ = w.Write([]string{"name", "age", "city"})
	for _, r := range rows {
		_ = w.Write([]string{r.Name, fmt.Sprint(r.Age), r.City})
	}
	w.Flush() // 缓冲落盘；错误记在 w.Error()
	if err := w.Error(); err != nil {
		panic(err)
	}
	return buf.String()
}

// ReadCSV 读回行集（逗号、引号都由库处理；首行是表头，跳过）。
func ReadCSV(s string) ([]Row, error) {
	r := csv.NewReader(strings.NewReader(s))
	if _, err := r.Read(); err != nil { // 表头
		return nil, err
	}
	var rows []Row
	for {
		rec, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		var age int
		if _, err := fmt.Sscanf(rec[1], "%d", &age); err != nil {
			return nil, fmt.Errorf("年龄列 %q: %w", rec[1], err)
		}
		rows = append(rows, Row{Name: rec[0], Age: age, City: rec[2]})
	}
	return rows, nil
}

// ---------- XML ----------

// Book 演示 attr / 嵌套 / omitempty。
type Book struct {
	XMLName xml.Name `xml:"book"`
	ID      int      `xml:"id,attr"`
	Lang    string   `xml:"lang,attr,omitempty"`
	Title   string   `xml:"title"`
	Authors []string `xml:"author>name"` // 嵌套路径：外包 <author>，切片重复内层 <name>
	Ignored string   `xml:"-"`
}

// ---------- gob ----------

// Notification 是接口示例：gob 编码接口值前必须 Register 具体类型。
type Notification interface{ Text() string }

// Email 是一种通知。
type Email struct{ Addr string }

func (e Email) Text() string { return "邮件→" + e.Addr }

// SMS 是另一种。
type SMS struct{ Phone string }

func (s SMS) Text() string { return "短信→" + s.Phone }

func init() {
	gob.Register(Email{})
	gob.Register(SMS{})
}

// EncodeNotifications 编码一批接口值（gob 流自描述）。
func EncodeNotifications(ns []Notification) ([]byte, error) {
	var buf bytes.Buffer
	if err := gob.NewEncoder(&buf).Encode(ns); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// DecodeNotifications 从流里读回。
func DecodeNotifications(b []byte) ([]Notification, error) {
	var ns []Notification
	if err := gob.NewDecoder(bytes.NewReader(b)).Decode(&ns); err != nil {
		return nil, err
	}
	return ns, nil
}

func main() {
	fmt.Println("== CSV：转义全自动 ==")
	text := WriteCSV([]Row{{"张三", 30, "北京"}, {"Li, Si", 25, `Say "hi"`}})
	fmt.Print(text)
	rows, err := ReadCSV(text)
	if err != nil {
		fmt.Println("读回失败:", err)
	} else {
		fmt.Printf("读回 %d 行，第二行：name=%q age=%d city=%q\n", len(rows), rows[1].Name, rows[1].Age, rows[1].City)
	}

	fmt.Println("== XML：attr / 嵌套 / omitempty ==")
	b := Book{ID: 7, Lang: "zh", Title: "Go 标准库示例", Authors: []string{"雨痕", "社区"}}
	data, _ := xml.MarshalIndent(b, "", "  ")
	fmt.Println(string(append([]byte(xml.Header), data...)))
	var back Book
	if err := xml.Unmarshal(data, &back); err != nil {
		fmt.Println("Unmarshal:", err)
	}
	fmt.Printf("读回: id=%d lang=%q title=%q authors=%v\n", back.ID, back.Lang, back.Title, back.Authors)

	fmt.Println("== gob：接口值 + Register ==")
	{
		ns := []Notification{Email{"a@b.com"}, SMS{"13800000000"}}
		blob, err := EncodeNotifications(ns)
		if err != nil {
			fmt.Println("编码:", err)
			return
		}
		got, err := DecodeNotifications(blob)
		if err != nil {
			fmt.Println("解码:", err)
			return
		}
		fmt.Printf("%d 字节；逐条: %s；%s\n", len(blob), got[0].Text(), got[1].Text())
	}
}
