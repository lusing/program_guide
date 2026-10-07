# 25 · 文本三件套：strings / bytes / strconv

> 对应示例：`examples/25_strings/`。标准库篇的开始：01–24 章把语言讲完了，25–35 章按《Go 标准库示例》的地图把最常用的包补齐。

## 25.1 拼接：`+` 的代价与 strings.Builder

```go
var b strings.Builder
b.Grow(64)                  // 预估容量，省掉中途扩容拷贝
for _, ln := range lines {
    b.WriteString(ln)
    b.WriteByte('\n')
}
s := b.String()             // 零拷贝：直接把内部缓冲转成 string
```

循环里 `s += x` 每轮都分配新串（string 只读，没法原地追加）。Builder 就是官方的替代品——写完 `String()` 直接把内部 `[]byte` 转成 string，不复制。**Builder 用完即弃，不许拷贝**（拷贝后再写会 panic，这是故意的防御）。

读串也能沾光：`strings.Reader` 把 string 包装成 `io.Reader`——20 章的整个 IO 世界（bufio、compress、json.Decoder……）都能直接吃字符串。

## 25.2 切分与合并：Split 家族、Fields、Cut

```go
strings.Split("a,b,c", ",")        // [a b c]
strings.SplitN("a,b,c", ",", 2)    // [a b,c]     n 限段数，最后一段吃掉剩余
strings.SplitAfter("a,b,c", ",")   // [a, b, c]   分隔符留在段尾

strings.Fields("  a  b\n c\t")     // [a b c]     按空白切，不限一种
strings.FieldsFunc(s, unicode.IsPunct)   // 自定义"什么算空白"

strings.Join([]string{"a","b"}, "-")      // a-b

// 1.24+：只 range 一遍就别建中间切片——迭代器版（13 章的 iter.Seq）
for field := range strings.SplitSeq("a,b,c", ",") { ... }
for i, ln := range strings.Lines(text) { ... }   // 按行迭代，ln 带尾部 \n

k, v, ok := strings.Cut("host:8080", ":") // host, 8080, true
before, found := strings.CutPrefix(s, "--") // 1.20+
_, found = strings.CutSuffix(s, ".go")
```

**Split 切空白要传空串**：`Split("a b", "")` 按空白切是 **错的**——空分隔符按 **UTF-8 序列逐字符切**。切空白用 `Fields`。

`Cut` 是 1.18 加入的"一次切割"——取代 `Index(s, sep)` + 手工切片的老三样，`ok` 直接告诉你分隔符在不在，**解析 `key=value` 类文本的首选**。

## 25.3 查找与替换

```go
strings.Contains(s, "go")            // 子串
strings.ContainsRune(s, 'x')
strings.ContainsAny(s, "0123456789") // 字符集合中任一字符

strings.HasPrefix / HasSuffix / EqualFold(s, "GO")  // EqualFold：Unicode 忽略大小写比较
strings.Index(s, "go") / LastIndex / IndexByte / IndexAny
strings.Count(s, "go")               // 不重叠计数；Count(s, "") = RuneCountInString(s)+1

strings.Replace(s, "a", "b", 2)      // 只换前 2 处；-1 = 全部
strings.ReplaceAll(s, "a", "b")      // 全部

// 替换表大或反复用：预编译的 Replacer（并发安全）
rep := strings.NewReplacer("老", "新", "--", "—")
rep.Replace(s)                       // 单趟扫描完成所有替换，比链式 Replace 快
```

## 25.4 修剪与大小写

```go
strings.TrimSpace(s)                 // 两头空白（Unicode 定义）
strings.Trim(s, "0x")                // 两头削掉 cutset 里出现的任何字符！
strings.TrimLeft / TrimRight / TrimPrefix / TrimSuffix
strings.TrimFunc(s, unicode.IsDigit)

strings.ToUpper / ToLower / ToUpperSpecial / ToTitle
```

**`Trim(s, "-")` 不是去掉两端的字面量 `-` 字符串**——第二个参数是**字符集合**，`Trim("--x--", "-x")` 会把 `x` 也削掉。要削"整个后缀"用 `TrimSuffix`。

`strings.Title`（词首大写）**1.18 起废弃**——它处理不了 Unicode 边界，新代码自己写或用 `golang.org/x/text/cases`。

## 25.5 bytes：[]byte 的镜像与 Buffer

`bytes` 包几乎是 strings 的镜像：`bytes.Contains / Index / Split / Trim / EqualFold / Cut……` 参数全换成 `[]byte`。**处理从文件/网络读来的字节流时用它**，省掉 `string(b)` 的一次拷贝。

两者之间的桥：

```go
[]byte(s)      // 拷贝一份（string 只读，必须复制才能改）
string(b)      // 又拷贝一份——热路径上这个代价会翻倍（35 章 unsafe 讲零拷贝的正道与代价）
```

`bytes.Buffer` 是双向的（既能 `Write` 又能 `Read`，实现 `io.ReadWriter`）；`strings.Builder` 只写但 `String()` 零拷贝。**拼串用 Builder，当缓冲区用（还要读回来）用 Buffer。**

## 25.6 strconv：字符串 ↔ 基本类型

```go
n, err := strconv.Atoi("42")              // ASCII→int 快路径
n, err := strconv.ParseInt("0x1F", 0, 64) // base=0 自动认 0x/0o/0b 前缀；指定位宽
f, err := strconv.ParseFloat("3.14", 64)  // 64 = float64，32 = float32
b, err := strconv.ParseBool("true")       // 认 1/t/TTRUE/true 等

strconv.Itoa(42)                          // int→string
strconv.FormatInt(255, 16)                // ff（base 2–36）
strconv.FormatFloat(f, 'f', 2, 64)        // 定点两位小数；'e' 科学/'g' 自适应/'x' 十六进制浮点

strconv.Quote(`a"b`)                      // "a\"b"——按 Go 字符串字面量转义
strconv.Unquote(`"a\tb"`)                 // 真正的制表符

// 分配敏感的热路径：往 []byte 尾上追加而不是返回新 string
buf = strconv.AppendInt(buf[:0], n, 10)
```

解析失败的错误是 `*strconv.NumError`，带三个字段：`Func`（谁报的）、`Num`（原串）、`Err`（`ErrSyntax` 语法错 / `ErrRange` 溢出）——区分"格式不对"和"数太大"看 `errors.Is(err, strconv.ErrRange)`。

## 25.7 选型速查

| 需求 | 用法 |
|---|---|
| 循环拼串 | `strings.Builder`（+Grow） |
| key=value 解析 | `strings.Cut` + `TrimSpace` |
| 按空白切 | `Fields`（不是 Split） |
| 多对替换反复做 | `strings.NewReplacer` |
| 字节流处理 | `bytes` 镜像函数 / `bytes.Buffer` |
| 字符串喂给 IO API | `strings.NewReader` |
| 带前缀的数字 | `ParseInt(s, 0, 64)` |
| 转义成字面量 | `strconv.Quote` |

## 25.8 坑位清单

1. **循环里 `s += x`**：每轮一次分配——Builder 是唯一正解。
2. **`Split(s, "")` 想切空白**：空分隔符 = 逐字符切；空白要 `Fields`。
3. **`Trim` 当成去前后缀**：第二参数是字符集合不是子串——`TrimSuffix/TrimPrefix` 才是按"整个串"削。
4. **Builder 拷贝后继续写**：panic（use of copied Builder）——按值传参前先 `String()`。
5. **`Atoi("0x10")` 失败**：Atoi 只认十进制——十六进制用 `ParseInt(s, 0, 64)`（base 0 吃 0x/0o/0b）。
6. **`string(b)` / `[]byte(s)` 到处转**：每次全量拷贝——算法层面统一用一种表示，过界才转（35 章的 unsafe.String 是受控的例外）。
7. **`strings.Title`**：1.18 废弃——Unicode 场景它就是错的。

---

---

上一章：[24 ⭐实战：迷你 grep](24-minigrep.md) · 下一章：[26 正则表达式](26-regexp.md)
