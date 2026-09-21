# 05 · 字符与字符串

> 配套示例：[`examples/05_strings/`](../examples/05_strings/main.lisp)（channel: both）

## 5.1 字符是独立类型（不是小整数）

从 C / Rust / Elisp 过来会习惯「字符就是整数」，**CL 里不是**：

```lisp
#\a              ; => #\a
(char-code #\a)  ; => 97
(code-char 65)   ; => #\A
(eql #\a 97)     ; => NIL       ← 字符和整数是两种东西
(type-of #\a)    ; => STANDARD-CHAR
```

字面量写法是 `#\` 加字符；有名字的特殊字符：

```lisp
#\Space          ; 空格（码 32）
#\Newline        ; 换行
#\Tab            ; 制表
(char-code #\Space)   ; => 32
(char-name #\Space)   ; => "Space"
```

**⚠️ 双实现差异（实测）**：`#\Space` 用 `~S` 打印时，SBCL 输出 `"#\ "`（反斜杠+空格），
CLISP 输出 `"#\Space"`。想要一致的输出就打 `(char-name #\Space)`——本教程双通道示例
正是这么做的。`#\a` 这类图形字符两边一致。

比较用 `char=` 系列（**区分大小写**），不分大小写用 `char-equal` 系列：

```lisp
(char< #\a #\b)       ; => T
(char= #\a #\A)       ; => NIL
(char-equal #\a #\A)  ; => T
(char-upcase #\a)     ; => #\A
(digit-char-p #\7)    ; => 7        ← 是数字字符就返回数值，否则 NIL
(alpha-char-p #\x)    ; => T
```

注意 `char<` 返回 `T`/`NIL`，而**字符串**版本的 `string<` 返回的是
**第一个不同字符的下标**（5.4 节），这两个别记混。

## 5.2 字符串是字符向量

CL 的字符串不是独立类型，它就是**元素类型为 `character` 的向量**：

```lisp
(vectorp "abc")         ; => T
(stringp "abc")        ; => T
(aref "abc" 0)          ; => #\a      ← 向量取法
(char "abc" 1)          ; => #\b      ← 字符串取法
(length "abc")          ; => 3
```

这解释了两件事：为什么字符串函数和序列函数长得一样（08 章的序列抽象），
以及为什么 `map` / `subseq` / `elt` 对字符串同样适用。

**字面量字符串不可以改。** 直接改它是未定义行为——SBCL 会给出编译警告，
CLISP 可能「碰巧」改成功（这正是不可移植代码的典型样本）：

```lisp
(setf (char "abc" 0) #\A)     ; SBCL: WARNING: Destructive function called on constant data
(let ((s (copy-seq "abc"))) (setf (char s 0) #\A) s)     ; => "Abc"   ← 正确做法
```

要构造可写字符串：

```lisp
(let ((s (make-array 3 :element-type 'character :initial-element #\x)))
  (setf (char s 0) #\A) s)                               ; => "Axx"
```

## 5.3 中文与码点

现代实现的 `character` 都覆盖 Unicode 全集（SBCL、CLISP 皆然）：

```lisp
(code-char 20013)            ; => #\U4E2D   ← 即「中」；SBCL 的可读打印用码点名
(char-code #\中)             ; => 20013
(length "你好世界")           ; => 4         ← 长度按**字符**数，不按 UTF-8 字节数
(char "你好" 1)              ; => #\U597D   ← 即「好」（打印形态同理）
```

注意区分「字符数」与「字节数」：文件的字节长度是另一回事（17 章 `file-length`
的大坑）。CLISP 在非 UTF-8 locale 下会按 ASCII 处理字符集——启动时加 `-E UTF-8`
（02 章）。

## 5.4 字符串操作速查

比较是新手最容易搞错的一处：

```lisp
(string= "abc" "abc")     ; => T
(equal "abc" "abc")       ; => T        ← OK，但通用函数更慢也更宽
(eq "abc" "abc")          ; 结果**未规定**（字面量是否共享看实现）← 别赌
(string< "abc" "abd")     ; => 2        ← 返回「第一个不同字符的下标」！
(string< "abc" "abc")     ; => NIL      ← 完全相同返回 NIL
(string-equal "ABC" "abc") ; => T       ← 不分大小写
```

`string<` 返回 `2` 而不是 `T`——它是「广义布尔值」（非 nil 即真），
`(if (string< a b) ...)` 照样能用，但**别写** `(eql (string< a b) t)`。

限定范围比较：

```lisp
(string= "prefix-a" "prefix-b" :end1 6 :end2 6)    ; => T   ← 只比前 6 个字符
```

查找与切割：

```lisp
(search "lo" "hello")                  ; => 3        ← 子串搜索，找不到 NIL
(position #\l "hello")                 ; => 2
(position #\l "hello" :from-end t)     ; => 3        ← 从后往前
(subseq "Hello World" 0 5)             ; => "Hello"
(concatenate 'string "abc" "def")      ; => "abcdef"
(string-upcase "abc")                  ; => "ABC"
(string-downcase "ABC")                ; => "abc"
(string-capitalize "hello world")      ; => "Hello World"
(string-trim '(#\Space) "  hi  ")      ; => "hi"     ← 参数是字符集合
(string-trim "()" "(hi)")              ; => "hi"     ← 字符串也当字符集用
(replace (copy-seq "abcdef") "XY" :start1 1 :end1 3)   ; => "aXYdef"  （破坏性！先拷贝）
```

拼接字符串两种常用写法：

```lisp
(format nil "~A-~A" "a" 1)             ; => "a-1"
(with-output-to-string (s) (write-string "ab" s) (write 42 :stream s))   ; => "ab42"
```

`format nil` 最常用：第一个参数 `nil` 表示「返回字符串而不是打印」。
多段累积拼接用 `with-output-to-string`（17 章字符串流），比反复 `concatenate` 高效。

## 5.5 字符串 → 数据

```lisp
(parse-integer "42")                    ; => 42
(parse-integer "ff" :radix 16)          ; => 255
(parse-integer "12abc" :junk-allowed t) ; => 12       ← 允许尾部有垃圾
(parse-integer "abc")                   ; 报错（parse-error，18 章抓它）
```

`read-from-string` 能读入**任意 Lisp 形式**，返回两个值：

```lisp
(read-from-string "(1 2 3)")                       ; => (1 2 3)
(multiple-value-list (read-from-string "42 rest")) ; => (42 3)
```

**⚠️ 双实现差异（实测）**：第二个返回值（停在哪个字符）SBCL 给 `3`（下一个未读字符
的下标）、CLISP 给 `2`（已读的最后一个字符下标）——两实现恰好差 1。
做逻辑别依赖它，调试参考可以。

数字 → 字符串：

```lisp
(write-to-string 255)              ; => "255"
(write-to-string 255 :base 16)     ; => "FF"
(prin1-to-string "abc")            ; => "\"abc\""   （带引号）
```

## 5.6 `~S` 还是 `~A`：给机器还是给人

| 写法 | 字符串打印成 | 用途 |
|---|---|---|
| `prin1` / `~S` | `"abc"`（带引号、转义） | **能再读回来**，调试首选 |
| `princ` / `~A` | `abc`（原样） | 给人看 |
| `write` | 同上，但可选 `:escape` | 细控 |
| `format t` | 由指令决定 | 拼接输出（16 章全家桶） |

实用习惯：**调试日志用 `~S`**——`~A` 打印 `nil` 和 `""`、`1` 和 `"1"` 长得一样，
`~S` 能区分。

## 5.7 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `(eql #\a 97)` 是 NIL | 字符不是整数 | `char-code` / `code-char` 显式转换 |
| 改字面量字符串有时成功有时崩 | 字面量可能在只读内存（两实现行为还不同） | 先 `copy-seq` 或 `make-array` |
| `(eq "a" "a")` 结果不定 | `eq` 比对象身份，字面量共享与否实现自定 | 比内容用 `equal` / `string=` |
| `(string< a b)` 返回数字 | 返回的是差异下标（广义布尔） | 当布尔用，别和 `t` 比大小写 |
| `#\Space` 打印两实现不一致 | SBCL 用 `#\ `、CLISP 用 `#\Space` | 打 `(char-name #\Space)` |
| `(string 42)` 报错 | `string` 只接受字符/符号/字符串 | 数字用 `write-to-string` |
| CLISP 下中文报 Invalid byte | 默认编码跟 locale 走 | 启动加 `-E UTF-8` |
