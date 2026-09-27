package main

import (
	"encoding/xml"
	"reflect"
	"strings"
	"testing"
)

func TestCSVRoundtrip(t *testing.T) {
	in := []Row{{"张三", 30, "北京"}, {"Li, Si", 25, `Say "hi"`}}
	text := WriteCSV(in)
	// 转义必须发生：带逗号的字段要被引号包住
	if !strings.Contains(text, `"Li, Si"`) {
		t.Errorf("逗号字段未被引号保护:\n%s", text)
	}
	got, err := ReadCSV(text)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, in) {
		t.Errorf("往返 = %v, want %v", got, in)
	}
}

func TestCSVMalformed(t *testing.T) {
	// 裸引号：默认严格模式应报错
	bad := "name,age\n\"a\"b,1\n"
	if _, err := ReadCSV(bad); err == nil {
		t.Error("怪引号在严格模式应报错")
	}
}

func TestXMLRoundtrip(t *testing.T) {
	b := Book{ID: 7, Lang: "zh", Title: "T", Authors: []string{"甲", "乙"}}
	data, err := xml.MarshalIndent(b, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	var back Book
	if err := xml.Unmarshal(data, &back); err != nil {
		t.Fatal(err)
	}
	// XMLName 解码后才填上（原始值是零值），逐字段比
	if back.XMLName.Local != "book" || back.ID != b.ID || back.Lang != b.Lang ||
		back.Title != b.Title || !reflect.DeepEqual(back.Authors, b.Authors) {
		t.Errorf("往返 = %+v", back)
	}
	if !strings.Contains(string(data), `id="7"`) {
		t.Errorf(",attr 未生效:\n%s", data)
	}
}

func TestXMLEmptyOmit(t *testing.T) {
	data, _ := xml.Marshal(Book{ID: 1}) // Lang 为空
	if strings.Contains(string(data), "lang") {
		t.Errorf("空属性应被 omitempty 剔除:\n%s", data)
	}
}

func TestGobInterfaceRoundtrip(t *testing.T) {
	in := []Notification{Email{"a@b.com"}, SMS{"138"}}
	blob, err := EncodeNotifications(in)
	if err != nil {
		t.Fatal(err)
	}
	got, err := DecodeNotifications(blob)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 || got[0].Text() != "邮件→a@b.com" || got[1].Text() != "短信→138" {
		t.Errorf("gob 往返 = %v", got)
	}
}
