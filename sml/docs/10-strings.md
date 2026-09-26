# 10 · 字符串与字符

> 对应示例：`examples/08-strings.sml`


## 10.1 基本操作

```sml
val s = "hello"
String.size s                        (* 5 *)
String.sub (s, 1)                    (* #"e" *)
String.substring (s, 1, 3)           (* "ell"：起始位置, 长度 *)
String.substring (s, 0, 1)           (* "h" *)
```

**`String.sub` 越界抛 `Subscript`**，不会返回 0 或空字符。SML 里没有「越界静默返回」这种事。

`String.substring` 的参数是**（起点，长度）**，不是（起点，终点）。这是新手最常写错的：

```sml
String.substring ("hello", 1, 3)     (* "ell" *)
String.substring ("hello", 1, 5)     (* 抛 Subscript：1+5 > 5 *)
```

## 10.2 拼接

```sml
"a" ^ "b"                                  (* "ab" *)
String.concat ["a", "b", "c"]              (* "abc" *)
String.concatWith "," ["a", "b", "c"]      (* "a,b,c" *)
```

`^` 是右结合的，但顺序对字符串拼接没影响。**要拼很多段时 `String.concat` 比一串 `^` 清楚得多。**

## 10.3 explode / implode：和 char list 互转

```sml
String.explode "abc"        (* [#"a", #"b", #"c"] *)
String.implode [#"a", #"b"] (* "ab" *)
```

这让所有列表函数都能用在字符串上：

```sml
String.implode (rev (String.explode "abc"))    (* "cba"：反转字符串 *)
```

## 10.4 map 与 translate

```sml
String.map Char.toUpper "abc"                         (* "ABC" *)
String.translate (fn c => String.str (Char.toUpper c)) "abc"   (* "ABC" *)
```

区别：`map` 是 `char -> char`（一对一），`translate` 是 `char -> string`（**可以一对多、也可以变成空串**）。

`translate` 变成空串这个能力非常有用 —— 等于**过滤**：

```sml
(* 只留下字母，其他字符"删除" *)
fun normalize (s : string) =
    String.translate (fn c => if Char.isAlpha c then String.str (Char.toLower c) else "") s
```

一行就是一个「归一化」函数，拿来做回文判断、词频统计都很顺手。

## 10.5 tokens vs fields：一个必须记住的区别

```sml
String.tokens (fn c => c = #",") "a,,c"      (* ["a", "c"]     两个！*)
String.fields (fn c => c = #",") "a,,c"      (* ["a", "", "c"] 三个 *)
```

- **`tokens` 会吞掉空字段**（连续分隔符视为一个）
- **`fields` 会保留空字段**

**解析 CSV 必须用 `fields`**，否则一行 `a,,c` 会从三个字段变成两个，后面所有列都错位。

反过来，`tokens` 适合「按空白切词」：

```sml
String.tokens Char.isSpace "  the  quick   brown  "    (* ["the","quick","brown"] *)
```

注意它连**前导和尾随**空白也一起处理掉了，不需要先 trim。

## 10.6 前缀、后缀、子串

```sml
String.isPrefix "he" "hello"         (* true *)
String.isSuffix "lo" "hello"         (* true *)
String.isSubstring "ell" "hello"     (* true *)
```

## 10.7 找子串：String.index 不通用！

Basis 里**没有**保证 `String.index` 存在。实测：

| 实现 | `String.index` |
|---|---|
| SML/NJ | 有 |
| Poly/ML | 有 |
| MLton | **没有**（`Undefined variable: String.index`）|

所以本书的手写版本：

```sml
fun indexOf (haystack : string, needle : char) =
    let
        val n = String.size haystack
        fun go i = if i >= n then NONE
                   else if String.sub (haystack, i) = needle then SOME i
                   else go (i + 1)
    in
        go 0
    end
```

十行，编译期确定，跨实现安全。**遇到「这个函数三家都有吗」的疑问，用手写版本比查文档快。**

## 10.8 字符分类

```sml
Char.isAlpha #"a"      (* true：字母（含 Unicode 字母） *)
Char.isDigit #"7"      (* true *)
Char.isSpace #" "      (* true：空格、\t、\n 等 *)
Char.isUpper #"A"      (* true *)
Char.isPunct #","      (* true *)
Char.toUpper #"a"      (* #"A" *)
Char.toLower #"A"      (* #"a" *)
```

这些函数接受**通用字符**语义，所以对 ASCII 之外的字符也可能返回 `true`。做 ASCII 解析时如果要求严格，可以自己判断范围。

## 10.9 数字解析

```sml
Int.fromString "42"        (* SOME 42 *)
Int.fromString "42abc"     (* SOME 42 —— 接受前缀！*)
Int.fromString "abc"       (* NONE *)
Int.fromString " 42"       (* SOME 42 —— 跳过前导空白 *)
Int.fromString ""          (* NONE *)
```

**`Int.fromString` 接受前缀**是很容易忽略的行为：做「整行必须是数字」的校验时，`Int.fromString` 通过**不代表**这一行是合法数字。要严格校验得自己检查：

```sml
fun strictInt (s : string) =
    case Int.fromString s of
        NONE => NONE
      | SOME v => if s = Int.toString v orelse s = "~" ^ Int.toString (~v) then SOME v else NONE
```

`Real.fromString` 是**重载**的（返回 `real option` 但 `real` 有多个实例），在 `case` 里用必须标注：

```sml
val r : real option = Real.fromString "3.5"
```

## 10.10 关于 `\ddd` 转义

SML 的字符串转义支持三种：

```sml
"\n"          (* 换行，常见的转义字符 *)
"\231"        (* 十进制 ASCII 码：这是一个字节 0xE7 *)
"\x41"        (* 十六进制 ASCII 码：0x41 = 'A' *)
```

**`\ddd` 是本书能跨实现输出中文的关键。** 三套实现都会把它解成同一个原始字节，所以：

```sml
val _ = print "==== 22 \231\187\147\230\157\159 ====\n"
```

在三家下产生**逐字节相同**的输出（`结束` 的 UTF-8 是 `E7 BB 93 E6 9D 9F` = 231,187,147,230,157,159）。

而直接写 `print "==== 22 结束 ===="` 会在 Poly/ML 和 MLton 上直接编译失败（第 2 章）。

## 10.11 Substring：不开销的切片

`Substring` 只是 `(string, start, length)` 的一个视图，**不复制字符**：

```sml
val ss = Substring.full "hello world"
val (front, back) = Substring.position " " ss
Substring.string front          (* "hello" *)
Substring.string back           (* " world" *)
Substring.string (Substring.triml 1 back)   (* "world" *)
```

`Substring.position` 返回的是「分隔符之前」和「从分隔符开始」两半。解析 `key=value` 这种格式，用它可以一次定位，不用先切全串：

```sml
fun splitKV (line : string) =
    let
        val (key, rest) = Substring.position "=" (Substring.full line)
    in
        if Substring.isEmpty rest then NONE
        else SOME (Substring.string key, Substring.string (Substring.triml 1 rest))
    end
```

`splitKV "a=b=c"` 得到 `("a", "b=c")` —— 只切第一个分隔符，正好是配置文件的语义。

---
