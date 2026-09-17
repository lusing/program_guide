// 21_json：encoding/json 主力（标签/流式/RawMessage）+ json/v2 一瞥。
package main

import (
	"bytes"
	"encoding/json"
	"encoding/json/jsontext"
	jsonv2 "encoding/json/v2"
	"fmt"
)

// Profile：标签控字段名，omitempty 让零值不出场，"-" 整个跳过。
type Profile struct {
	Name  string            `json:"name"`
	Age   int               `json:"age,omitempty"`   // 0 就不序列化
	Email string            `json:"email,omitempty"` // "" 就不序列化
	Tags  []string          `json:"tags,omitempty"`
	Extra map[string]string `json:"-"` // 私有数据，绝不进 JSON
}

// ToJSON 序列化（缩进版）。
func ToJSON(v any) string {
	b, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return "<错误:" + err.Error() + ">"
	}
	return string(b)
}

// FromJSON 泛型反序列化：调用方指定目标类型。
func FromJSON[T any](data []byte) (T, error) {
	var v T
	err := json.Unmarshal(data, &v)
	return v, err
}

func main() {
	p := Profile{
		Name:  "阿G",
		Tags:  []string{"go", "教程"},
		Extra: map[string]string{"私有": "不序列化"},
	}
	fmt.Println("== Marshal：标签与 omitempty ==")
	fmt.Println(ToJSON(p)) // Age=0、Email="" 都被吞掉；Extra 从未出场

	fmt.Println("== Unmarshal：未知字段默认忽略 ==")
	back, err := FromJSON[Profile]([]byte(`{"name":"阿Z","age":25,"pet":"猫"}`))
	fmt.Println(back, "err:", err) // pet 消失——不是错误

	fmt.Println("== Decoder 流式：大输入一块一块读 ==")
	stream := bytes.NewBufferString("{\"name\":\"一\"}\n{\"name\":\"二\"}\n")
	dec := json.NewDecoder(stream)
	for dec.More() {
		var p Profile
		if err := dec.Decode(&p); err != nil {
			break
		}
		fmt.Println("  读到:", p.Name)
	}

	fmt.Println("== RawMessage：先看信封再拆载荷 ==")
	var envelope struct {
		Type    string          `json:"type"`
		Payload json.RawMessage `json:"payload"` // 延迟解析，原文留存
	}
	if err := json.Unmarshal([]byte(`{"type":"user","payload":{"name":"阿G"}}`), &envelope); err != nil {
		fmt.Println(err)
	}
	fmt.Println("  类型:", envelope.Type, "载荷待分发:", string(envelope.Payload))

	fmt.Println("== json/v2（1.27 默认可用，无需 GOEXPERIMENT）==")
	b, err := jsonv2.Marshal(p)
	fmt.Println(" ", string(b), err)
	var buf bytes.Buffer
	enc := jsontext.NewEncoder(&buf, jsontext.WithIndent("  "))
	if err := jsonv2.MarshalEncode(enc, p); err != nil {
		fmt.Println(err)
	}
	fmt.Println(buf.String())
}
