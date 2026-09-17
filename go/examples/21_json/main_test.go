package main

import (
	"bytes"
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"testing"
)

func TestRoundtrip(t *testing.T) {
	p := Profile{Name: "阿G", Age: 30, Tags: []string{"x"}}
	data, err := json.Marshal(p)
	if err != nil {
		t.Fatal(err)
	}
	back, err := FromJSON[Profile](data)
	if err != nil {
		t.Fatal(err)
	}
	if back.Name != "阿G" || back.Age != 30 || len(back.Tags) != 1 || back.Tags[0] != "x" {
		t.Errorf("往返丢失: %+v", back)
	}
}

func TestOmitEmpty(t *testing.T) {
	b, err := json.Marshal(Profile{Name: "n"})
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if bytes.Contains(b, []byte("age")) {
		t.Errorf("零值 age 应被 omitempty 略去: %s", s)
	}
	if !bytes.Contains(b, []byte(`"name":"n"`)) {
		t.Errorf("应有 name 字段: %s", s)
	}
}

func TestPrivateFieldExcluded(t *testing.T) {
	b, err := json.Marshal(Profile{Name: "n", Extra: map[string]string{"k": "v"}})
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(b, []byte("Extra")) || bytes.Contains(b, []byte(`"k"`)) {
		t.Errorf("json:\"-\" 的字段不该出场: %s", b)
	}
}

func TestUnknownFieldIgnored(t *testing.T) {
	if _, err := FromJSON[Profile]([]byte(`{"name":"x","whatever":1}`)); err != nil {
		t.Errorf("未知字段默认应忽略: %v", err)
	}
}

func TestV2Roundtrip(t *testing.T) {
	p := Profile{Name: "阿G", Age: 20}
	b, err := jsonv2.Marshal(p)
	if err != nil {
		t.Fatal(err)
	}
	var back Profile
	if err := jsonv2.Unmarshal(b, &back); err != nil {
		t.Fatal(err)
	}
	if back.Name != "阿G" || back.Age != 20 {
		t.Errorf("v2 往返: %+v", back)
	}
}
