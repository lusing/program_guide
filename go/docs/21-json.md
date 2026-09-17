# 21 · JSON

> 对应示例：`examples/21_json/`

## 21.1 Marshal / Unmarshal：一把梭

```go
type Profile struct {
	Name  string   `json:"name"`
	Age   int      `json:"age,omitempty"`    // 0 就不序列化
	Email string   `json:"email,omitempty"`  // "" 就不序列化
	Tags  []string `json:"tags,omitempty"`
	Extra map[string]string `json:"-"`       // 整个跳过：私有数据
}

b, _ := json.Marshal(p)              // {"name":"阿G","tags":["go","教程"]}
pretty, _ := json.MarshalIndent(p, "", "  ")

var back Profile
err := json.Unmarshal(b, &back)      // 注意传 &back（指针）
```

三条标签规则覆盖九成需求：**改名**（`json:"name"`）、**零值隐身**（`,omitempty`）、**除名**（`"-"`）。Unmarshal 的未知字段**默认忽略**（`pet` 悄悄消失）——严格模式要 `Decoder.DisallowUnknownFields`。

## 21.2 数字的双重人格

```go
var m map[string]any
json.Unmarshal([]byte(`{"n": 18}`), &m)
m["n"]        // float64(18)——any 通道里所有数字都是 float64！
```

解码进 `any` 的 JSON 数字一律 float64——大整数精度、int 断言全埋雷。**结构体解码没有这个问题**（目标类型明确）；真要动态就用 `json.Number`（`Decoder.UseNumber()`）。

## 21.3 Decoder：流式与增量

```go
dec := json.NewDecoder(bytes.NewBufferString(`{"name":"一"}
{"name":"二"}`))
for dec.More() {                  // 一段一段读（JSON Lines / 大响应体）
	var p Profile
	if err := dec.Decode(&p); err != nil {
		break
	}
	fmt.Println(p.Name)
}
```

网络流、日志流、多文档 JSON 用 Decoder 逐段解；小字符串 Marshal/Unmarshal 足矣。**Decoder 还有第二个身份：jsonrpc 的地基**。

## 21.4 RawMessage：先看信封再拆载荷

```go
var envelope struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`   // 延迟解析：原文 []byte 留存
}
json.Unmarshal(raw, &envelope)
// 先按 Type 分发，再把 Payload 二次 Unmarshal 到具体类型
```

多态消息（事件、协议帧）的标准姿势——不解析的部分原样保留，转发场景零损耗。

## 21.5 json/v2：1.27 默认可用的新引擎

```go
import (
	jsonv2 "encoding/json/v2"          // 语义层：Marshal/Unmarshal
	"encoding/json/jsontext"           // 文本层：Encoder/Value
)

b, _ := jsonv2.Marshal(p)                          // v1 标签照样认
var buf bytes.Buffer
enc := jsontext.NewEncoder(&buf, jsontext.WithIndent("  "))
jsonv2.MarshalEncode(enc, p)                        // 缩进走 jsontext 层
```

v1（`encoding/json`）**没有废弃**——存量代码照样跑。v2 的分层设计（语义/文本分离）、更严的 RFC 语义、错误信息全面升级；新项目可以直接选 v2，老项目混用过渡（v2 有兼容 v1 行为的选项）。**教程建议：先学 v1（看懂全世界），新代码试 v2（面向未来）**——示例 21 两个都演示了。

## 21.6 自定义序列化：Marshaler 接口

```go
func (d MyDate) MarshalJSON() ([]byte, error) {
	return []byte(`"` + d.Format("2006-01-02") + `"`), nil
}
```

实现 `json.Marshaler` / `json.Unmarshaler` 接口，该类型的序列化你说了算（v1 体系）。v2 对应 `jsonv2.Marshaler`（收 jsontext.Encoder，流式更顺）。

## 21.7 速查：结构 ↔ JSON 对照

| Go | JSON |
|---|---|
| 结构体（导出字段） | 对象 |
| 切片 / 数组 | 数组 |
| map | 对象 |
| `*T` | 与 T 相同（nil → null） |
| nil 切片 / 空切片 | `null` / `[]`（有区别！） |
| time.Time | RFC3339 字符串（自带 Marshaler） |
| any | 按运行时类型 |

## 21.8 坑位清单

1. **any 里的数字是 float64**：`m["n"].(int)` 必失败——动态场景 json.Number 或干脆定义结构体。
2. **小写字段静默消失**：Unmarshal 进小写字段填不上、Marshal 时小写字段不出场——反射只看得见导出字段。
3. **omitempty 吞 0**：`Age: 0` 真实业务值也消失——要么指针 `*int`，要么不 omitempty。
4. **nil 切片序列化成 null**：前端拿 `[]` 的预期落空——初始化 `[]T{}`。
5. **HTML 字符默认转义**：v1 Marshal 把 `<>&` 变 `<`——`Encoder.SetEscapeHTML(false)` 关掉（v2 默认不转义）。
6. **Unmarshal 忘传指针**：`json.Unmarshal(b, back)` 编译错（好设计），但 `&back` 写成 `back` 的地址以外的花样要自查。

---
