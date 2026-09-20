# 08 · 字符串与 Unicode

> 对应示例：`examples/08_strings/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

字符串是 Elixir 里最容易「在 ASCII 世界一切正常，一上生产碰到 emoji 和德语就崩」的地方。
本章把这片深水区一次走透。先记住一句话：

> **Elixir 字符串就是 UTF-8 编码的二进制（`is_binary/1` 为真），除此之外没有任何隐藏结构。**

所有困惑都来自「二进制」和「人眼中的文本」之间隔着三层单位。

## 8.1 三个单位：字节 / 码点 / 字素簇

| 单位 | 取法 | 含义 |
|---|---|---|
| 字节 | `byte_size/1` | UTF-8 编码后的原始字节，1～4 字节一个码点 |
| 码点（codepoint） | `length(String.codepoints/1)` | Unicode 码位，一个整数 |
| 字素簇（grapheme） | `String.length/1`、`String.graphemes/1` | 人眼看到的「一个字符」 |

实测（1.20 / OTP 29）：

```text
e-acute NFC (U+00E9)        bytes=2  codepoints=1  graphemes=1
e-acute NFD (e + U+0301)    bytes=3  codepoints=2  graphemes=1
wave emoji U+1F44B          bytes=4  codepoints=1  graphemes=1
thumbs-up + 肤色修饰         bytes=8  codepoints=2  graphemes=1
family ZWJ sequence         bytes=18 codepoints=5  graphemes=1
```

记住三对关系：

- ASCII：三单位恒等，所以纯英文测试永远发现不了坑；
- 带重音的拉丁字母：1 个字素可能是 1 个码点（NFC）或 2 个（NFD）；
- emoji：1 个字素可以是多个码点（修饰符、ZWJ 拼接）、十几字节。

「一家人」👨‍👩‍👧 在字符串里是 5 个码点（男人、ZWJ U+200D、女人、ZWJ、女孩）、
18 个字节，但 `String.length/1` 说是 1——它数的是字素。

## 8.2 规范化：同一文本的多种字节编码

`é` 有两种标准的 Unicode 表示：

- NFC：单个码点 U+00E9（2 字节）；
- NFD：`e` + 组合重音 U+0301（2 个码点，3 字节）。

```text
NFC == NFD（逐字节）          => false
String.equivalent?(NFC, NFD)  => true
:unicode.characters_to_nfc_binary(NFD) == NFC => true
```

后果非常实际：macOS HFS+ 文件系统给 NFD、Linux 给 NFC，同一个文件名在不同机器上字节不同；
Web 表单、外部 API 发来的文本规范化形式未知。**要按「文本是否相同」比较，用
`String.equivalent?/2`，或先 `:unicode.characters_to_nfc_binary/1` 归一化再 `==`。**

本教程源码层面也有一条相关纪律：示例里所有非 ASCII 字面量都写成 `\uXXXX` 转义
（NFC 字面量 `"é"`、ASCII 转义 `"\u00E9"`、ZWJ 序列 `"\u{1F468}\u200D..."`），不信任编辑器对源文件的规范化。

## 8.3 大小写：长度会变、不可逆、语种相关

直觉里 `downcase(upcase(s)) == s` 是公理。Unicode 里不是：

```text
case_report("straße") => %{up: "STRASSE", down: "strasse", roundtrip?: false, delta: 1}
```

德语 ß（U+00DF）大写规则是展开成两个字母 `SS`——**长度都变了**，再小写回不去。
大小写还跟**语种**有关：

```text
String.downcase("I")              => "i"
String.downcase("I", :turkic)     => "ı"   # U+0131 土耳其语无点 i
String.upcase("é", :default)      => "É"
String.upcase("é", :ascii)        => "é"   # :ascii 只动 A-Z/a-z
```

实践建议：

- 大小写转换用于**展示**，不要用作数据归一化的唯一手段（比较前归一化用 Unicode 规范化，
  不是 upper/lower）；
- 处理协议常量、标识符用 `:ascii` 模式，行为可预测；
- 文件名、邮箱这类东西的大小写折叠规则查对应标准（邮箱有专门规则），别拍脑袋。

## 8.4 按字节切 vs 按字素切

UTF-8 是多字节编码，**按字节位置切字符串等于随机切割**：

```elixir
String.at("é", 0)          # => "é"  字素索引，安全
binary_part("é", 0, 1)     # => <<195>>  只有 0xC3 这一个字节
String.valid?(<<195>>)     # => false  半字符，非法 UTF-8
```

```text
first_grapheme(e-acute)  => "é"
first_byte(e-acute)      => 195
头一字节是合法 UTF-8 吗   => false
```

经典事故：用 `Kernel.binary_part/3` 或按字节 `:binary.split` 截「前 N 个字符」，截在 emoji
中间，下游 `Jason.encode!` 直接炸（合法 JSON 必须是合法 UTF-8）。规则：

- 面向**文本**的操作一律用 `String.*`（字素/码点感知）；
- 只有在解析**二进制协议/文件格式**时才用字节级操作（17 章）。

## 8.5 二进制模式：按码点或字节遍历

第 04 章见过二进制前缀匹配。处理字符串时两类「游标」要分清：

```elixir
# 每次吃一个完整码点（1～4 字节），绑定码点整数
defp codepoint_ints(<<cp::utf8, rest::binary>>, acc), do: ...
# 推导式每次吃一个字节
for <<b <- bin>>, do: b
# 反过来，码点整数 -> UTF-8 二进制
<<cp::utf8>>
```

```text
codepoint_ints(NFD e-acute)  => [101, 769]
byte_ints(e-acute)           => [195, 169]        # 0xC3 0xA9
byte_ints(wave emoji)        => [240, 159, 145, 139]  # F0 9F 91 8B
from_codepoint(0x1F44B)      => "👋"
```

UTF-8 编码本身是自同步的（首字节与后续字节区间不重叠），所以从字节流中间进入也能重新
对齐——这是按字节扫描时的安全网。

## 8.6 iodata：不拼接也能输出

`IO.puts/1`、`:gen_tcp.send/2`、`Plug` 响应体接受的不是只有二进制，而是 **iodata**：
二进制与「码点整数列表」可以任意嵌套：

```elixir
data = ["a", ~c"b", [?c], "é"]
IO.iodata_to_binary(data)   # => "abcé"
IO.iodata_length(data)      # => 5（按拼起来后的字节计，不实际拼接）
```

> 注意 1.20 起单引号 charlist 字面量已弃用，写 `~c"b"`（见坑位 7）。

高并发服务器里这是个真实的性能杠杆：模板是 `"前缀" <> 变量 <> "后缀"` 的嵌套列表，
直接丢给 socket，由运行时写出，省掉每请求一次大二进制分配。要的是码点列表（老 Erlang
库如 `:httpc` 的接口）时用 charlist（`String.to_charlist/1`），其余场合用二进制。

## 8.7 常用操作（全部字素感知）

```text
words("  a   b c ")                         => ["a", "b", "c"]   # trim + split(trim: true)
String.pad_leading("42", 5, "0")            => "00042"
String.reverse("a👋b")                       => "b👋a"            # 字素反转，emoji 完好
String.ends_with?("a.txt", ".txt")          => true（大小写敏感）
String.replace("hello Ada", "Ada", "***")   => "hello ***"
```

老语言按字节 reverse UTF-8 会把多字节字符倒成乱码；Elixir 的 `String.reverse/1` 按字素反
转。连续空格用 `String.split/3` 的 `trim: true`，别自己 `Enum.reject(&(&1 == ""))`。

## 8.8 数字解析：会崩的与会「部分成功」的

```text
String.to_integer("42px")   # ** (ArgumentError)
Integer.parse("42")         => {:ok, 42, ""}
Integer.parse("42px")       => {:ok, 42, "px"}   # 前缀数字被吃掉，剩余串还给你
Integer.parse("abc")        => :error
```

处理用户输入用 `Integer.parse/1`（配 `with` 正好，见 06 章）；只有在「必须整串都是数字」
的强约束下才用 `String.to_integer/1` 配合异常。浮点对应 `Float.parse/1`。

## 8.9 IO 编码：本章所有示例的第一条纪律

BEAM 的 stdio 编码取自系统 locale；`LANG`/`LC_ALL` 未设时退回 latin1，`IO.puts("结束")`
会被打成 `\x{7ED3}\x{675F}` 这样的字面转义。每个示例工程的两处固定设置把它钉死：

```elixir
# run.exs 第 1 行、test/test_helper.exs
:io.setopts(:standard_io, encoding: :utf8)
```

这样脚本的输出与开发机的环境变量无关——这也是 `run-all.sh` 第 5 层（两次运行逐字节
比对）能成立的前提。读写文件时对应选项是 `File.stream!(path, [:utf8])`；读外部来源的
原始字节先过 `String.valid?/1`，不要假设它合法。

## 8.10 坑位清单

1. **三个长度别混用**：`byte_size`（字节）、码点数（`codepoints`）、`String.length`
   （字素）。「字符串长度」的业务含义 99% 是字素，但数据库 `VARCHAR(n)` 限制常是码点或
   字节——跨边界要对齐定义。

2. **规范化形式不统一时 `==` 不可靠**：NFC/NFD 的同一文本字节不同。比较前
   `String.equivalent?/2` 或统一 NFC。外部输入（文件名、表单、JSON）默认不可信。

3. **大小写转换不可逆且语种相关**：`straße => STRASSE`、土耳其语 I、希腊语终西格玛。
   展示可用，别拿它做身份比较的唯一归一化。

4. **禁止按字节截字符串**：截出来的可能是非法 UTF-8，JSON 编码/写库/网络发送全链崩。
   文本用 `String.*`；字节级操作只留给协议解析。

5. **`String.length/1` 是 O(n)**：它要遍历整个二进制数字素。判空用 `== ""` 或模式
   `<<>>`，守卫里判空字符串可以直接 `when binary != ""`；热路径上别循环调 length。

6. **charlist 是码点列表，不是字符串**：`~c"abc" == [97,98,99]`，`is_binary` 为假。
   Erlang 互操作时会碰到，别对它调用 String 函数。

7. **1.20 弃用单引号 charlist**：`'b'` 告警，写 `~c"b"`。

8. **源码里的非 ASCII 用 `\u` 转义**：编辑器/工具链可能改写规范化形式（本教程写作中
   实际踩过），固定写法 `"\u00E9"`（ASCII 转义）、`"\u{1F44B}"`，而不是直接贴特殊字符。

9. **stdin/stdout 显式 `encoding: :utf8`**：别让脚本输出依赖机器 locale。

---

下一章：[09 · 集合](09-collections.md)
