# 07 · 字符串处理

> 示例：[`examples/07_strings/07_strings.a68`](../examples/07_strings/07_strings.a68)
> 运行：`./run-all.sh 07`

Algol 68 里没有独立的"字符串对象"——**`STRING` 就是一段字符（`CHAR`）的行（row）**，模式记作
`[]CHAR`（等价书写 `[*]CHAR`），因为长度可变，其底层是 `FLEX[1:0]CHAR`。理解这一点，字符串的
一切行为（切片、拼接、比较、下标、以及"按字节而非字符"的语义）都顺理成章。本章逐个拆开。

## 1. STRING 的本质：一段 [1:n]CHAR，UPB 取长度

```algol68
STRING s := "Hello, Algol";
print(("s = [", s, "]", new line));
print(("LWB s = ", whole(LWB s, 0), "   UPB s = ", whole(UPB s, 0), new line));
```

- `STRING` 是下标从 `1` 开始的 `CHAR` 行，即 `[1:n]CHAR`。
- **`LWB s`**（Lower Bound）取下界，恒为 `1`；**`UPB s`**（Upper Bound）取上界，即字符个数（长度）。
- 实测 `"Hello, Algol"` 的 `LWB s = 1`、`UPB s = 12`（含逗号和空格，共 12 个字符）。

> `LWB`/`UPB` 是通用的行边界运算符，对任何数组都适用；用在 `STRING` 上就是"首下标 / 长度"。
> 因为 `STRING` 从 1 起，长度恰好等于 `UPB`，不必像 0 基数组那样算 `UPB - LWB + 1`。

## 2. 切片 s[i:j] 与单字符 s[i]

```algol68
print(("s[1:5]  = [", s[1:5], "]", new line));   # Hello #
print(("s[8:12] = [", s[8:12], "]", new line));  # Algol #
print(("s[1]    = ", s[1], new line));           # H #
```

- `s[i:j]` 是**闭区间、1 基**的子串：`s[1:5]` 取第 1 到第 5 个字符（含两端）。
- `s[i]` 取单个 `CHAR`（不是长度 1 的字符串，但可直接 `print`）。
- 切片产出的仍是 `STRING`，可继续参与拼接、比较。

## 3. 拼接用 `+`（不是 `++`，也不是 CONCAT）

```algol68
STRING joined := s[1:5] + " World";
print(("joined = [", joined, "]", new line));    # Hello World #
```

字符串拼接就是加号 `+`：把切片 `"Hello"` 和字面量 `" World"` 接起来得 `"Hello World"`。

## 4. 逐字符遍历：FOR k TO UPB s

用第 06 章的 `FOR` 配合 `UPB` 就能逐字符扫描：

```algol68
print(("逐字符: "));
FOR k TO UPB s DO print((s[k])) OD;
print((new line));
```

实测把 `Hello, Algol` 一个字符一个字符打出来（连起来仍是 `Hello, Algol`）。`s[k]` 每次取第 `k` 个 `CHAR`。

## 5. 比较：= /= < <= > >=，按字典序逐字符

```algol68
print((("apple" < "banana"), " ", ("zebra" > "apple"), new line));   # T T #
```

六个关系运算符对 `STRING` 逐一按**字典序（逐字符比码位）**工作：`"apple" < "banana"` 为真，
`"zebra" > "apple"` 为真。相等的判断用 `=`（单等号）。

## 6. 按「字节」语义，以及 CJK / UTF-8 多字节的大坑

这是本章最重要的一点：**`STRING` 存的是 `CHAR`，一个 `CHAR` 就是一个字节，`UPB` 数的是字节数，
`LWB`/`UPB`/切片/下标全部按字节走——而不是按"人眼看到的字符"。**

对纯 ASCII 这没问题（1 字符 = 1 字节）。但 UTF-8 下一个汉字占 **3 个字节**。本机 a68g 3.13.3 实测：

```algol68
STRING s := "中文字";
print(("UPB = ", whole(UPB s, 0), new line));        # 9 #
print(("s[1] ABS = ", whole(ABS s[1], 0), new line)); # 228 #
print(("s = [", s, "]", new line));                   # 中文字 #
```

- `"中文字"` 只有 3 个汉字，但 **`UPB` 得 9**（3 字 × 3 字节）。
- **`s[1]` 取到的是第一个字节（码位 228 = `0xE4`），不是汉字"中"**——切片 `s[1:1]` 会切出半个字符。
- 直接 `print` 整个字符串没问题（a68g 按字节原样透传给终端，终端按 UTF-8 还原成"中文字"）。

> 结论：**别用 `s[i]` / `s[i:j]` 去"取第 i 个汉字"**。对含 CJK 的文本，字符边界与字节边界不重合，
> 按字节切片会切坏多字节序列。要处理中文得自己按 UTF-8 字节规律跳（首字节 `0xE0..0xEF` 表示 3 字节字符）。

## 7. CHAR 与码位互转：ABS / REPR

```algol68
CHAR c := "H";
print(("ABS H = ", whole(ABS c, 0), "   REPR 72 = ", REPR 72, new line));   # 72 / H #
```

- **`ABS c`**：取字符 `c` 的码位（`INT`），`ABS "H"` = 72。
- **`REPR n`**：由码位 `n` 造出对应的 `CHAR`，`REPR 72` = `"H"`。二者互为逆运算。

借此可手写大小写转换（ASCII 大写字母码位 + 32 = 小写）：

```algol68
PROC to_lower = (CHAR ch) CHAR:
  IF ch >= "A" AND ch <= "Z" THEN REPR(ABS ch + 32) ELSE ch FI;
print(("lower(HELLO) = "));
FOR k TO 5 DO print((to_lower("HELLO"[k]))) OD;    # hello #
print((new line));
```

字符本身也能用关系运算比较（`ch >= "A"`），比较的是码位。非字母原样返回（`to_lower("1") = "1"`）。

## 8. 字面量没有反斜杠转义：要嵌引号就写两遍

```algol68
STRING q := "say ""hi"" now";
print(("q = [", q, "]", new line));    # say "hi" now #
```

- **字符串字面量里没有 `\` 转义**。源码注释指出：写 `"a\tb"` 时那个反斜杠是
  `unworthy character`，直接触发**扫描错误（scanner error）**。
- 要在字符串里放一个双引号，就把它**写两遍**：`""` 表示一个 `"`。
- 换行没有 `\n`，用内建常量 **`new line`**；制表符没有 `tab` 常量，用 **`REPR 9`**。
  同理断言里用 `REPR 34` 表示双引号字符（`"` 的码位是 34）。

## 9. 从字符行造字符串：STRING([n]CHAR)

先用一个定长 `CHAR` 行逐格填字符，再整体转成 `STRING`：

```algol68
[1:5] CHAR buf;
FOR k TO 5 DO buf[k] := REPR(ABS "a" + k - 1) OD;
STRING word := STRING(buf);
print(("buf = ", buf, "   word = [", word, "]", new line));   # abcde / abcde #
```

`STRING(buf)` 把 `[1:5]CHAR` 行显式转成 `STRING`。`buf[k] := REPR(ABS "a" + k - 1)` 依次填入
`a b c d e`（`"a"` 码位 97，逐格 +1）。

## 10. 没有内建「查子串」：自己写 index_of

Algol 68 标准库没有现成的"找子串位置"函数，示例自己实现一个（找不到返回 0）：

```algol68
PROC index_of = (STRING hay, needle) INT:
  ( INT h := UPB hay, nd := UPB needle;
    IF nd = 0 OR nd > h THEN 0
    ELSE
      INT pos := 0;
      FOR i TO h - nd + 1 WHILE pos = 0 DO
        IF hay[i : i + nd - 1] = needle THEN pos := i FI
      OD;
      pos
    FI );
print(("index_of(s, ""Algol"") = ", whole(index_of(s, "Algol"), 0), new line));  # 8 #
print(("index_of(s, ""xyz"")   = ", whole(index_of(s, "xyz"), 0), new line));    # 0 #
```

要点：`(STRING hay, needle)` 是"两参数同为 `STRING`"的简写；`FOR i ... WHILE pos = 0` 用
`WHILE` 子句在找到后立即停（第 06 章 §5）；`hay[i : i + nd - 1]` 是滑动的等长切片，与 `needle` 比较。
实测 `index_of(s, "Algol")` = 8（`Algol` 从第 8 位起），`index_of(s, "xyz")` = 0（找不到）。

## 11. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 07` 中 check 通道的真实 stdout（release 通道 `-O2` 逐字节一致，即验证保证）：

```text
s = [Hello, Algol]
LWB s = 1   UPB s = 12
s[1:5]  = [Hello]
s[8:12] = [Algol]
s[1]    = H
joined = [Hello World]
逐字符: Hello, Algol
T T
ABS H = 72   REPR 72 = H
lower(HELLO) = hello
q = [say "hi" now]
buf = abcde   word = [abcde]
index_of(s, "Algol") = 8
index_of(s, "xyz")   = 0
==== 07 结束 ====
自检全部通过
```

逐行要点：

| 输出 | 为什么长这样 |
|---|---|
| `LWB s = 1   UPB s = 12` | `STRING` 下标从 1 起，`"Hello, Algol"` 共 12 字节 |
| `s[1]    = H` | `s[i]` 取单个 `CHAR`，可直接 `print` |
| `joined = [Hello World]` | 切片 `"Hello"` 用 `+` 拼接 `" World"` |
| `T T` | `("apple" < "banana")` 与 `("zebra" > "apple")` 均真，`BOOL` 打成 `T` |
| `ABS H = 72   REPR 72 = H` | `ABS`/`REPR` 互逆：码位 72 ↔ 字符 `H` |
| `q = [say "hi" now]` | 字面量里 `""` 折叠成一个 `"`，无反斜杠转义 |
| `index_of(s, "xyz")   = 0` | 找不到子串时返回约定的 0 |
| `自检全部通过` | 所有 `assert` 未累加 `fails`，退出码 0 |

## 12. 坑位清单（实测）

1. **一切按字节，不按字符**：`UPB` 是字节数；实测 `"中文字"` 的 `UPB = 9`（不是 3）。
2. **CJK 切片会切坏**：`s[1]` 取到的是首字节（实测码位 228 = `0xE4`），不是汉字"中"；
   含中文时别用 `s[i]`/`s[i:j]` 按"第几个字"取。
3. **拼接用 `+`**：不是 `++`，也没有 `CONCAT`。
4. **字面量无反斜杠转义**：`"a\tb"` 里的 `\` 是 `unworthy character`，触发 scanner error；
   嵌引号写两遍 `""`，换行用 `new line`，制表符用 `REPR 9`，双引号字符用 `REPR 34`。
5. **切片闭区间、1 基**：`s[1:5]` 含第 1 和第 5 个字符；`s[i]` 是 `CHAR` 不是子串。
6. **`ABS`/`REPR` 只对码位负责**：`REPR(ABS ch + 32)` 的大小写技巧仅对 ASCII 字母成立。
7. **没有内建查子串/替换**：`index_of` 这类操作需自己用切片 + `FOR ... WHILE` 实现。
8. **`(STRING hay, needle)`** 是多参数同模式的简写，等价 `(STRING hay, STRING needle)`。

---
上一章：[06 循环](06-loops.md) ｜ 下一章：[08 运算符](08-operators.md) ｜ 返回：[README](../README.md)
