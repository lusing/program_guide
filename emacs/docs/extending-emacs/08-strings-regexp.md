# 08 · 字符串与正则

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/08-strings-regexp.el`

字符串操作是写扩展的日常。本章覆盖「拼接/切分/裁剪 → 正则方言 → 匹配与取组 → rx」。所有输出都是示例真跑出来的。

## 8.1 拼接与连接

```elisp
(princ (format "concat: %S\n" (concat "foo" "-" "bar")))
(princ (format "mapconcat: %S\n" (mapconcat #'identity '("a" "b" "c") ", ")))
(princ (format "string-join 等价写法: %S\n" (string-join '("a" "b" "c") ", ")))
```

```
concat: "foo-bar"
mapconcat: "a, b, c"
string-join 等价写法: "a, b, c"
```

`concat` 是万能的拼接（还能拼字符串和字符、列表和列表）。把一个列表用分隔符连成字符串有两个写法：`mapconcat` 是内置函数，`string-join`（subr-x）是语义更直白的等价物——传「字符串列表 + 分隔符」即可。

## 8.2 【坑】split-string 的三个默认行为

```elisp
(princ (format "默认（按空白、去空）: %S\n" (split-string "  a  b   c ")))
(princ (format "按逗号切（保留空串）: %S\n" (split-string "a,,b,c" ",")))
(princ (format "按逗号切且丢掉空串: %S\n" (split-string "a,,b,c" "," t)))
```

```
默认（按空白、去空）: ("a" "b" "c")
按逗号切（保留空串）: ("a" "" "b" "c")
按逗号切且丢掉空串: ("a" "b" "c")
```

三个默认行为，逐个说清：

1. **不传分隔符时，按空白切**（变量 `split-string-default-separators`，值通常是 `"[ \f\t\n\r\v]+"`），而且此时 `OMIT-EMPTY` 被强制为 `t`——首尾空白被吃掉，空字段不存在。所以 `(split-string "  a  b   c ")` 得到干净的三元素列表。
2. **给了显式分隔符时，`OMIT-EMPTY` 默认 `nil`——空串被保留。** 这正是解析 CSV 需要的行为：`"a,,b,c"` 按逗号切出 `("a" "" "b" "c")`，中间的空字段老老实实在。
3. **要显式丢掉空串，才传第三个参数 `t`**：`("a" "b" "c")`。

> 注意第三个参数叫 `OMIT-EMPTY`——「省略空串」。传 `t` 是**丢掉**空串，不是保留。这个参数名和直觉的方向感很容易搞反，写 CSV 解析时盯一下。

## 8.3 取子串与裁剪

```elisp
(princ (format "substring: %S\n" (substring "hello world" 0 5)))
(princ (format "string-trim: %S\n" (string-trim "  hi  ")))
(princ (format "string-pad 补到 8 位: %S\n" (string-pad "hi" 8)))
```

```
substring: "hello"
string-trim: "hi"
string-pad 补到 8 位: "hi      "
```

`substring` 的下标越界会被**截断**而不是报错（`(substring "abc" 0 99)` → `"abc"`）——方便，但也意味着写错下标不报错。`string-trim` 去两端空白（可以传第二个参数指定裁哪些字符）；`string-pad` 右侧补齐到指定宽度（第三个参数可指定填充字符）。

## 8.4 Emacs 正则的方言

Emacs 正则和 PCRE 有几处必须记住的差别：

| 需求 | Emacs 写法 | 类比 PCRE |
|---|---|---|
| 分组 | `\\(...\\)` | `(...)` |
| 或 | `\\|` | `\|` |
| 行首/行尾锚 | `^` / `$`（或 rx 的 `bol`/`eol`） | `^` / `$` |
| 词首/词尾 | `\\<` / `\\>` | `\b` |
| 词组成字符 | `\\w` / `\\s-` / `\\sw` | `\w` |
| 非捕获组 `(?:...)` | **不支持** | — |

最大的一条：**分组要多写一层反斜杠**。原因是 `\\(` 在 Lisp 字符串字面量里转义后正好是 `\(`。忘了这一层，正则不会被当成分组，`match-string` 取组会静默出错。

## 8.5 string-match 与提取组

```elisp
(defvar demo-text "version 31.1 build 2026")
(when (string-match "version \\([0-9]+\\)\\.\\([0-9]+\\)" demo-text)
  (princ (format "整串匹配: %S\n" (match-string 0 demo-text)))
  (princ (format "第 1 组: %S，第 2 组: %S\n"
                 (match-string 1 demo-text) (match-string 2 demo-text)))
  (princ (format "位置: %S..%S\n"
                 (match-beginning 0) (match-end 0))))
```

```
整串匹配: "version 31.1"
第 1 组: "31"，第 2 组: "1"
位置: 0..12
```

`string-match` 在第 2 个参数里搜第 1 个参数，返回**起始下标**（不是 `t`）或 `nil`：

- 第 0 组是整串，1、2… 是各个 `\\(...\\)` 分组；
- 位置用 `(match-beginning n)` / `(match-end n)` 取（右开区间，所以 0..12 表示 12 个字符）；
- **匹配失败返回 `nil`，不报错**——所以 `match-string` 前一定要判一下 `when`/`if`。

## 8.6 【坑】match data 是全局状态，而且失败不清空

「上次匹配的结果」是**全局状态**。它有两条反直觉的规则，都是实测出来的：

```elisp
(let ((s1 "aaa"))
  (string-match "a" s1)
  (princ (format "   先成功匹配: %S\n" (match-string 0 s1)))
  (princ (format "   失败匹配返回: %S\n" (string-match "zzz" s1)))
  (princ (format "   失败后 match-string 还在: %S\n" (match-string 0 s1)))
  (princ (format "   不传字符串会怎样: %S\n"
                 (condition-case err (match-string 0) (error err)))))
```

```
   先成功匹配: "a"
   失败匹配返回: nil
   失败后 match-string 还在: "a"
   不传字符串会怎样: (args-out-of-range #<buffer *scratch*> 0 1)
```

1. **匹配失败（返回 `nil`）并不会清理 match data** —— 上一次成功匹配的结果还在。
   所以「忽略返回值直接读 `match-string`」会读到**上一次**的脏数据，这是最隐蔽的一类 bug；
2. **字符串匹配之后，`match-string` 必须传字符串**。不传的话它默认去**当前 buffer** 里按
   那些位置取文本 —— 而字符串匹配的位置是 0 开始的，buffer 位置是 1 开始的，于是直接
   `args-out-of-range` 报错。反过来，buffer 匹配之后**不能**传字符串。

要跨表达式保留结果，必须**匹配之后立刻** `(match-string 0 s)` 取出存好。这也是为什么上面 8.5 的代码把 `match-string` 全写在 `when` 里面。

循环找所有匹配，靠 `match-end` 推进起点，**不能写 `(1+ start)`**——那会在零宽匹配上死循环：

```elisp
(let ((pos 0) (hits nil))
  (while (string-match "[0-9]+" demo-text pos)
    (push (match-string 0 demo-text) hits)
    (setq pos (match-end 0)))
  (princ (format "所有数字: %S\n" (nreverse hits))))
```

```
所有数字: ("31" "1" "2026")
```

## 8.7 【推荐】rx：用 S-表达式写正则

正则字符串写多了没人看得懂。`rx` 宏让你用 S-表达式构造，还能直接看它生成了什么：

```elisp
(princ (format "rx 生成: %S\n" (rx "v" (one-or-more digit))))
(princ (format "rx 复杂例子: %S\n"
               (rx line-start (group (one-or-more (any "a-z")))
                   "=" (group (one-or-more digit)) line-end)))
```

```
rx 生成: "v[[:digit:]]+"
rx 复杂例子: "^\\([a-z]+\\)=\\([[:digit:]]+\\)$"
```

`rx` 生成的仍然是普通正则字符串，能直接传给 `string-match` / `re-search-forward`。好处是**不用数反斜杠的层数**、可读、有缩进。新代码强烈建议用它。

常用的 `rx` 元件：

| 元件 | 含义 |
|---|---|
| `bol` / `line-start` | 行首（两者是别名） |
| `eol` / `line-end` | 行尾（两者是别名） |
| `string-start` / `buffer-start` | 字符串/缓冲区开头 |
| `digit` / `alpha` / `alnum` / `space` / `blank` | 字符类 |
| `(one-or-more x)` / `(zero-or-more x)` / `(optional x)` | 重复 |
| `(** 2 4 digit)` | 重复 2 到 4 次 |
| `(group x)` | 捕获组 |
| `(or a b)` | 或 |
| `(any "abc")` / `(not (any "abc"))` | 字符集合 / 补集 |
| `(seq a b)` | 连接（列表形式默认就是 seq） |

## 8.8 字符与字符串互转

```elisp
(princ (format "string-to-list: %S\n" (string-to-list "ab")))
(princ (format "string-to-number: %S，number-to-string: %S\n"
               (string-to-number "0x1f") (number-to-string 31)))
```

```
string-to-list: (97 98)
string-to-number: 0，number-to-string: "31"
```

`string-to-list` 把字符串拆成字符（整数）列表；反方向是 `(mapconcat #'char-to-string lst "")`——字符转字符串的函数是 `char-to-string`（Elisp 里**没有** `integer-to-char` 这个函数）。

`string-to-number` 有个静默陷阱：**它只按十进制解析，解析不动就返回 0**——`"0x1f"` 得到 0（不是 31），`"abc"` 也得到 0。所以「转换成功了吗」不能靠它判断。数字转字符串优先用 `(format "%d" 31)`，语义更明确。要按其他进制解析，用 `(string-to-number "1f" 16)`。

## 8.9 字面量查找与替换：不用正则的现代函数

只是「找个子串在哪」或「把某个子串全换成另一个」，没必要写正则：

```elisp
(princ (format "string-search: %S\n" (string-search "lo" "hello")))
(princ (format "string-replace: %S\n" (string-replace "a" "X" "banana")))
```

```
string-search: 3
string-replace: "bXnXnX"
```

- `string-search` 返回子串的起始下标，找不到返回 `nil`——比 `string-match` 语义干净（不用分组反斜杠），且不需要转义特殊字符；
- `string-replace` 把**所有**出现都换掉（没有「只换第一个」的选项，要只换第一个自己切子串再拼）。

查找前缀/后缀用 `string-prefix-p` / `string-suffix-p`（第 6 章）。

## 8.10 本章小结

| 想干什么 | 用什么 |
|---|---|
| 拼接 | `concat` / `mapconcat` / `string-join` |
| 切分 | `split-string`（记住 `OMIT-EMPTY` 的方向） |
| 裁剪/补宽 | `string-trim` / `string-pad` / `substring` |
| 模式匹配 | `string-match` + `match-string` |
| 写正则 | `rx`（优先）或字符串（注意 `\\(` 双层） |
| 字面量查找/替换 | `string-search` / `string-replace` |
| 数字 ↔ 字符串 | `number-to-string` / `format "%d"`（慎用 `string-to-number`） |

---

上一章：[07 · 列表与关联结构](07-lists.md)　｜　下一章：[09 · 序列与 cl-lib](09-sequences.md)　｜　返回：[Emacs 扩展开发指南](README.md)
