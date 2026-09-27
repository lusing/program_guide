# 27 · Unicode 与 UTF-8/16

> 对应示例：`examples/27_unicode/`。06 章说过"string 是只读字节切片"——这一章讲清这些字节按什么规则变成"字符"。

## 27.1 string 的真身：UTF-8 编码的文本

```go
s := "Go语言"
len(s)                          // 8：字节数（G,o 各 1，语/言 各 3）
for i, r := range s { ... }     // i 是字节下标，r 是 rune（解码出的 Unicode 码点）
utf8.RuneCountInString(s)       // 4：字符数
[]rune(s)                       // 解码成 []rune，可下标按"字符"访问
```

`range` 字符串**每次迭代解一个 rune**（下标按字节跳）——`s[i]` 拿到的是字节不是字符。**"第几个字符"的操作先 `[]rune(s)`**（代价：一次完整解码 + 分配）。

非法字节不会被炸出来：解码失败产 `U+FFFD`（�）且消耗 1 字节继续走——所以"合法 UTF-8 输入"要用 `utf8.Valid([]byte(s))` 自己验。

## 27.2 unicode 包：码点分类

```go
unicode.IsLetter('A')           // true
unicode.IsDigit('7') / IsNumber('⑦')   // IsDigit 只认十进制数字字符
unicode.IsSpace('\t') / IsPunct('，') / IsHan('语')

unicode.Is(unicode.Han, r)      // 通用形式：传 RangeTable
// 包里预置一批表：unicode.Han（汉字）/ Latin / Hiragana / Hangul / Emoji ...
unicode.In(r, unicode.Han, unicode.Hiragana)   // 命中任一表

unicode.ToUpper('a') / ToLower / ToTitle       // 单 rune 的大小写（有映射才变）
unicode.SimpleFold('A')        // 'a'——大小写折叠的下一步（循环枚举同一字母的变体）
```

25 章的 `strings.TrimFunc(s, unicode.IsDigit)`、`FieldsFunc(s, unicode.IsPunct)` 就是这些谓词的用武之地——**判断逻辑自己写，切分/修剪交给字符串包**。

## 27.3 utf8 包：编解码原语

```go
b := []byte("语言")
r, size := utf8.DecodeRune(b)        // r='语'（U+8BED），size=3
r, size = utf8.DecodeLastRune(b)

buf := make([]byte, 4)
n := utf8.EncodeRune(buf, '🚀')      // n=4：emoji 是 4 字节
utf8.RuneLen('语')                   // 3
utf8.Valid(buf)                      // 字节序是否合法 UTF-8
utf8.ValidString(s)
```

UTF-8 是变长（1–4 字节，首字节的高位模式暗示长度）——**兼容 ASCII、自同步（从任意字节找回边界）、无字节序问题**，这是 Go 字符串选它的原因。处理"半个字符"（字节流截断在多字节字符中间）时，DecodeRune 返回 `(RuneError, 1)`——网络分帧/streaming 解析里常见的边界状况。

## 27.4 utf16：代理对与外部世界

```go
u16 := utf16.Encode([]rune("Go🚀"))  // [71 111 55357 56464]——🚀 变两个码元
rs  := utf16.Decode(u16)             // 还原
utf16.IsSurrogate(r)                 // 是否代理区（U+D800–DFFF）
```

UTF-16 是 Java/C#/Windows API 的内部表示，**BMP 外的字符**（多数 emoji）要拆成一对"代理"（surrogate pair）表示。跟 Windows API、Java 桥接，或解析 `LittleEndian` 的 JSON `🚀` 转义时才需要它——日常文本处理用不上，知道它在哪就行。

## 27.5 速查

| 需求 | 写法 |
|---|---|
| 字符数 | `utf8.RuneCountInString(s)`（不是 len） |
| 按字符下标 | `[]rune(s)` 后再取 |
| 汉字/假名判断 | `unicode.Is(unicode.Han, r)` |
| 解第一个字符 | `utf8.DecodeRune(b)` |
| 字节流合法性 | `utf8.Valid(b)` |
| 截断的半个字符 | DecodeRune 得 `(U+FFFD, 1)` |
| 与 UTF-16 世界桥接 | `utf16.Encode/Decode` |

## 27.6 坑位清单

1. **`len(s)` 当字符数**：中文/emoji 场景必错——是字节数；字符数用 `RuneCountInString`。
2. **`s[i]` 取"字符"**：拿到 byte——先 `[]rune(s)`，或 range。
3. **range 的下标当字符序号**：`for i, r := range s` 的 i 是**字节偏移**，会从 2 跳到 5——要序号自己 ++。
4. **字符串截子串切断多字节字符**：`s[:5]` 可能切在"语"的中间，尾字节变垃圾——按 rune 边界切（`[]rune` 后重组）。
5. **IsDigit 与 IsNumber 混用**：IsDigit 只认 0-9 及各文字的十进制位，IsNumber 还含 ⑦、½ 这类数字字符——校验"能转 int"用 IsDigit 语义。
6. **大小写转换后长度变了**：rune 级 ToUpper 单字符不变长，但 `ß`.ToUpper() 之类特例存在——strings.ToUpper 处理整串，别逐字符拼。

---
