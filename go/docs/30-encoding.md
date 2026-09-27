# 30 · 编码三件套：CSV / XML / gob

> 对应示例：`examples/30_encoding/`。JSON（21 章）之外的三种常用交换格式。

## 30.1 encoding/csv：表格数据

```go
// 写：Writer 是带缓冲的——写完必须 Flush + 查 Error
var buf bytes.Buffer
w := csv.NewWriter(&buf)
w.Write([]string{"姓名", "年龄"})
w.WriteAll(records)   // 或循环 w.Write
w.Flush()
if err := w.Error(); err != nil { ... }   // Flush 只把错误记在 Error() 里，不返回

// 读：Read 一行（[]string），ReadAll 全读
r := csv.NewReader(bytes.NewReader(buf.Bytes()))
r.Comma = ';'                  // 分隔符（默认 ','）
r.FieldsPerRecord = 3          // 严格校验每行列数（默认按首行定，-1 不校验）
r.LazyQuotes = true            // 容忍裸引号（脏数据时再开，默认遇怪引号直接报错）
r.TrimLeadingSpace = true
for {
    rec, err := r.Read()
    if err == io.EOF { break }
    if err != nil { return err }   // csv.ParseError 带 StartLine/Line/Err，定位到行
}
```

字段里的逗号/引号/换行 **自动加引号转义**——手拼 CSV 字符串是数据损坏的头号来源。文件读写直接接 `os.Open` / `os.Create`（20 章）。

## 30.2 encoding/xml：标签映射

```go
type Book struct {
    XMLName xml.Name `xml:"book"`           // 根元素名（可选，推断为结构体名小写）
    ID      int      `xml:"id,attr"`        // 属性
    Lang    string   `xml:"lang,attr,omitempty"`
    Title   string   `xml:"title"`          // 子元素文本
    Authors []string `xml:"author>name"`    // 嵌套路径：外面包 <author>，切片重复内层 <name>
    Hidden  string   `xml:"-"`              // 不参与
}

data, _ := xml.MarshalIndent(b, "", "  ")
data = append([]byte(xml.Header), data...)   // 手动补 <?xml?> 声明

var out Book
xml.Unmarshal(data, &out)
```

与 JSON 对照：`xml:"name,attr"` 的 **`,attr`** 是 XML 特有；文本内容用 `,chardata`（元素里混着文本和子元素时）；`,innerxml` 拿原始片段。流式用 `xml.NewEncoder(w).Encode(v)` / `xml.NewDecoder(r).Decode(&v)`——**Decoder 是 token 级的**（`Token()` 逐事件读），大文件不必整棵树进内存。

## 30.3 encoding/gob：Go 间的二进制

```go
var buf bytes.Buffer
enc := gob.NewEncoder(&buf)
enc.Encode(state)                 // state 里若含接口值，先注册具体类型

dec := gob.NewDecoder(&buf)
dec.Decode(&restored)
```

gob 是 **Go 对 Go** 的格式：自带字段名与类型描述（**编码流自描述**，加字段老数据也能解）、二进制比 JSON 小且快、`Encode/Decode` 传 interface 时零转换。代价：**只有 Go 能读**（跨语言回 JSON/protobuf）、只编码**导出字段**、接口值必须先 `gob.Register(具体类型)`，否则报 "type not registered"。

`Encode(v)` 后紧跟的 `Decode(&x)` 把流里的类型描述带上——**同一个 Encoder 编多条、同一个 Decoder 逐条解**是最顺的用法（RPC 内部就这么干）。

## 30.4 三者对比

| | CSV | XML | gob |
|---|---|---|---|
| 形态 | 表格 | 树 | 二进制 |
| 跨语言 | 全平台 | 全平台 | 仅 Go |
| 自描述 | 无类型 | 有 | 有（流内带 schema） |
| 典型场景 | Excel/报表交换 | SOAP/老系统/配置 | 进程间缓存、RPC |

## 30.5 坑位清单

1. **csv.Writer 忘 Flush**：缓冲没落盘，文件残缺——`defer w.Flush()` 之后还要查 `w.Error()`。
2. **Flush 不返回错误**：编码错误记在 `Error()`——不查就吞了。
3. **手拼 CSV 行**：字段带逗号/引号必坏——永远走 `w.Write`。
4. **中文 CSV 用 Excel 打开乱码**：写入前先写 UTF-8 BOM `[]byte{0xEF,0xBB,0xBF}`（微软传统，只此一家要）。
5. **xml 属性忘了 `,attr`**：按元素名找，静默解出零值——Unmarshal 不报"没找到"。
6. **gob 编码非导出字段**：静默跳过，不报错——私有状态保存别指望它。
7. **gob 接口值没 Register**：Encode 直接报错 "type not registered for interface"。
8. **gob 的空值优化**：全零结构体可能编码成空——Decode 目标必须传指针，且字段名对得上才解进去。

---
