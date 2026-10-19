# 08 · 字符串与正则

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/08-strings-regexp.el`

## 8.1 拼接与切分

```elisp
(concat "foo" "-" "bar")                    ; → "foo-bar"
(mapconcat #'identity '("a" "b" "c") ", ")  ; → "a, b, c"
(string-join '("a" "b" "c") ", ")           ; → "a, b, c"  （等价的现代写法）
```

```
concat: "foo-bar"
mapconcat: "a, b, c"
string-join 等价写法: "a, b, c"
```

## 8.2 【坑】split-string 的默认行为

```elisp
(split-string " a  b   c ")          ; → ("a" "b" "c")
(split-string "a,,b" ",")            ; → ("a" "b")     空串被丢掉
(split-string "a,,b" "," t)          ; → ("a" "" "b")  保留空串
```

```
默认（按空白、去空）: ("a" "b" "c")
按逗号切: ("a" "b" "c")
按逗号切并保留空串: ("a" "" "b" "c")
```

两个默认行为和直觉不符：默认分隔符是**空白**（不是逗号），而且**会丢掉空串**。
解析 CSV 这类数据时，**必须传第 3 个参数 `t`**，否则空字段会静默消失 —— 这是很严重的静默 bug。

## 8.3 取子串与裁剪

```elisp
(substring "hello world" 0 5)     ; → "hello"   下标从 0 开始，右开区间
(string-trim "  hi  ")            ; → "hi"      去两端空白
(string-pad "hi" 8)               ; → "hi      " 补齐到指定宽度
```

```
substring: "hello"
string-trim: "hi"
string-pad 补到 8 位: "hi      "
```

`substring` 的下标越界会被**截断**而不是报错（`(substring "abc" 0 99)` → `"abc"`）。

## 8.4 Emacs 正则的方言

Emacs 正则和 PCRE 有几处必须记住的差别：

| 需求 | Emacs 写法 | 类比 PCRE |
|---|---|---|
| 分组 | `\\(...\\)` | `(...)` |
| 或 | `\\|` | `\|` |
| 词首/词尾 | `\\<` / `\\>` | `\b` |
| 词组成字符 | `\\w` | `\w` |
| 非捕获 `(?:)` | **不支持** | — |

最大的一条：**分组要多写一层反斜杠**。原因是 `\\(` 在 Lisp 字符串字面量里正好是 `\(`。

## 8.5 string-match 与提取组

```elisp
(string-match "\\([a-z]+\\)=\\([0-9]+\\)" "version=31")
(match-string 0)    ; → "version=31"   整串
(match-string 1)    ; → "version"      第 1 组
(match-string 2)    ; → "31"           第 2 组
```

```
整串匹配: "version 31.1"
第 1 组: "31"，第 2 组: "1"
位置: 0..12
所有数字: ("31" "1" "2026")
匹配失败时 string-match 返回: nil
```

- 第 0 组是整串；
- 匹配失败返回 `nil`（**不会报错**），所以 `match-string` 前一定要判一下；
- 还可以用 `(match-beginning n)` / `(match-end n)` 取位置。

## 8.6 【坑】match-string 的全局状态

```elisp
(princ (format "所有数字: %S\n"
               (let ((start 0) (acc nil))
                 (while (string-match "[0-9]+" "v31.1 2026" start)
                   (push (match-string 0 "v31.1 2026") acc)
                   (setq start (match-end 0)))
                 (nreverse acc))))
```

```
所有数字: ("31" "1" "2026")
```

两个要点：

1. 「上次匹配」是**全局状态**。`match-string` 拿的是最近一次匹配的结果 —— 所以下面这段代码是错的：

   ```elisp
   (when (string-match "a" s1)
     (when (string-match "b" s2)     ; 这次匹配覆盖了上面
       (match-string 0 s1)))          ; 拿到的是 s2 里 b 的位置，不是 a
   ```

   要跨表达式保留，得自己 `(match-string 0 s)` 立刻存下来。

2. 循环找所有匹配，靠 `(setq start (match-end 0))` 推进。**不能写 `(1+ start)`** ——
   那会在零宽匹配上死循环。

## 8.7 【推荐】rx：用 S-表达式写正则

正则字符串写多了没人看得懂。`rx` 宏让你用 S-表达式构造，还能直接看它生成了什么：

```elisp
(rx "v" (one-or-more digit))          ; → "v[[:digit:]]+"
(rx bol (group (one-or-more (any "a-z"))) "=" (group (one-or-more digit)) eol)
```

```
rx 生成: "v[[:digit:]]+"
rx 复杂例子: "^\\([a-z]+\\)=\\([[:digit:]]+\\)$"
rx 匹配: 0
rx 取组: "31"
```

`rx` 生成的仍然是普通的正则字符串，所以能直接传给 `string-match` / `re-search-forward`。
好处是**不用记反斜杠的层数**、可读、有缩进。强烈建议新代码都用它。

常用的 `rx` 元件：

| 元件 | 含义 |
|---|---|
| `bol` / `eol` | 行首 / 行尾 |
| `digit` / `alpha` / `alnum` / `space` | 字符类 |
| `(one-or-more x)` / `(zero-or-more x)` / `(optional x)` | 重复 |
| `(group x)` | 捕获组 |
| `(or a b)` | 或 |
| `(any "abc")` / `(not (any "abc"))` | 字符集合 / 补集 |
| `(seq a b)` | 连接（列表形式默认就是 seq） |

## 8.8 字符与字符串互转

```elisp
(string-to-list "ab")      ; → (97 98)
(string-to-char "A")       ; → 65
(char-to-string 65)        ; → "A"
(number-to-string 31)      ; → "31"
(string-to-number "31")    ; → 31
```

```
string-to-list: (97 98)
string-to-number: 0，number-to-string: "31"
实际写代码里更常用 (format "%d" 31) = "31"
```

注意 `(string-to-number "abc")` 返回 **0**（不是 nil，也不报错）—— 判「转换是否失败」不能靠它。

---

上一章：[07 · 列表与关联结构](07-lists.md)　｜　下一章：[09 · 序列与 cl-lib](09-sequences.md)　｜　返回：[Emacs 扩展开发指南](README.md)
