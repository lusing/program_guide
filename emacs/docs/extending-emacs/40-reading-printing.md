# 40 · 读取与打印：read、prin1、princ 与那一堆 print-* 开关

> 所属部分：第 10 部分 · 对照参考手册补齐的主题

> 示例：`examples/40-reading-printing.el`

Lisp 有个别的语言没有的特点：**代码和数据是同一种东西**。因此「把对象变成文本」（打印）和「把文本变成对象」（读取）不是什么边角功能，而是语言的核心——`load` 就是「读一段文本 + 逐个求值」，`macroexpand` 打印出来的东西要能被 `read` 回去，`defcustom` 存进 `.emacs` 的值也要能被读回来。

本章对应参考手册的 **Reading and Printing Lisp Objects** 一章。要解决的问题很具体：

- `prin1`、`princ`、`print`、`pp` 到底差在哪？（答：引号和换行）
- 打印有六个 `print-*` 开关，各自管什么？
- `prin1` 出来的东西，`read` 一定读得回来吗？（答：不一定，而且失败得很安静）

照旧，结论全部来自本机 Emacs 31.1 的实测输出。

## 40.1 打印四兄弟：`prin1` / `princ` / `print` / `pp`

四个函数干的是同一件事（把对象变成文本），差别只在**引号**和**换行**。示例第 1 节拿同一个对象走一遍四个函数：

```elisp
(dolist (obj (list "abc" 'sym 42 '(a "b")))
  (princ (format "  对象 %S\n" obj))
  (princ (format "    prin1 -> %S\n" (with-output-to-string (prin1 obj))))
  (princ (format "    princ -> %S\n" (with-output-to-string (princ obj))))
  (princ (format "    print -> %S\n" (with-output-to-string (print obj))))
  (princ (format "    pp    -> %S\n" (pp-to-string obj))))
(princ "  prin1 保留引号、princ 脱掉引号、print 前后各加一个换行、pp 末尾加换行。\n")
(let ((obj (list (cons 'k (number-sequence 1 40)))))
  (princ (format "  长结构 prin1 -> %S\n" (prin1-to-string obj)))
  (princ (format "  长结构 pp    -> %S\n" (pp-to-string obj)))
  (princ (format "  pp 按 fill-column=%S 折行\n" fill-column)))
(princ (format "  四个函数的返回值都是被打印的对象本身: %S %S\n"
               (with-output-to-string (prin1 'aaa))
               (with-output-to-string (princ 'bbb))))
```

```
== 1) 打印四兄弟 ==
  对象 "abc"
    prin1 -> "\"abc\""
    princ -> "abc"
    print -> "
\"abc\"
"
    pp    -> "\"abc\"
"
  对象 sym
    prin1 -> "sym"
    princ -> "sym"
    print -> "
sym
"
    pp    -> "sym
"
  对象 42
    prin1 -> "42"
    princ -> "42"
    print -> "
42
"
    pp    -> "42
"
  对象 (a "b")
    prin1 -> "(a \"b\")"
    princ -> "(a b)"
    print -> "
(a \"b\")
"
    pp    -> "(a \"b\")
"
  prin1 保留引号、princ 脱掉引号、print 前后各加一个换行、pp 末尾加换行。
  长结构 prin1 -> "((k 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40))"
  长结构 pp    -> "((k 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
    26 27 28 29 30 31 32 33 34 35 36 37 38 39 40))
"
  pp 按 fill-column=70 折行
  四个函数的返回值都是被打印的对象本身: "aaa" "bbb"
```

（上面 `print` 那两行被拆成三行，是因为它的输出本身**前有一个换行、后有一个换行**——用 `%S` 打印字符串时会把真实换行显示出来。）

一句话记住：

| 函数 | 引号 | 换行 | 典型用途 |
|---|---|---|---|
| `prin1` | **保留**（能 `read` 回来） | 无 | 生成代码、写配置文件、日志里记录原值 |
| `princ` | **去掉**（人读着舒服） | 无 | 给用户看的文本、`message` 之外的纯输出 |
| `print` | 保留 | **前后各一个** | 交互式调试（`M-:` 里敲 `(print x)`） |
| `pp` | 保留 | 末尾一个，且会**按 `fill-column` 折行** | 把大结构打印成人能读的样子 |

判据只有一条：**这段文本要不要被 `read` 回去**。要，就用 `prin1`（或 `pp`）；不要，就用 `princ`。

`pp` 是「pretty-print」，长结构会折行：

同一个 40 元素的列表，`prin1` 打出一行，`pp` 在第 25 个元素后折行、下一行缩进 4 个空格——折行位置由 `fill-column` 决定（默认 70）。所以 `pp` 适合把大结构打到 `*Help*` 之类的 buffer 里给人读，而 `prin1` 适合要被 `read` 回去的场合。

## 40.2 `format` 的转换符

`format` 是最常用的「拼字符串」工具，它和 `prin1`/`princ` 的对应关系就是 `%S` / `%s`。示例第 2 节：

```elisp
(princ (format "  %%S 带引号: %S\n" (format "%S" "abc" )))
(princ (format "  %%s 脱引号: %s\n" (format "%s" "abc")))
(princ (format "  %%S 列表:   %S\n" (format "%S" '(a "b"))))
(princ (format "  %%s 列表:   %s\n" (format "%s" '(a "b"))))
(princ (format "  %%d=%S  %%o=%S  %%x=%S  %%X=%S\n"
               (format "%d" 42) (format "%o" 42)
               (format "%x" 42) (format "%X" 42)))
(princ (format "  %%c=%S  %%c 吃字符: %S\n"
               (format "%c" 65) (format "%c" ?A)))
(princ (format "  %%f=%S  %%e=%S  %%g=%S\n"
               (format "%f" 1.5) (format "%e" 1.5) (format "%g" 1.5)))
(princ (format "  %%5.2f=%S  （宽度 5、小数 2 位）\n" (format "%5.2f" 3.14159)))
(princ (format "  %%%% 才是字面百分号: %S\n" (format "%%")))
;;; 下面两行故意写错参数个数，用 with-no-warnings 挡住编译器的好心提醒。
(princ (format "  参数不够: %S\n"
               (with-no-warnings
                 (condition-case err (format "%s %s" 1)
                   (error (error-message-string err))))))
(princ (format "  参数多了: %S  （多余的直接忽略，不报错）\n"
               (with-no-warnings (format "%s" 1 2))))
```

```
== 2) format 的转换符 ==
  %S 带引号: "\"abc\""
  %s 脱引号: abc
  %S 列表:   "(a \"b\")"
  %s 列表:   (a b)
  %d="42"  %o="52"  %x="2a"  %X="2A"
  %c="A"  %c 吃字符: "A"
  %f="1.500000"  %e="1.500000e+00"  %g="1.5"
  %5.2f=" 3.14"  （宽度 5、小数 2 位）
  %% 才是字面百分号: "%"
  参数不够: "Not enough arguments for format string"
  参数多了: "1"  （多余的直接忽略，不报错）
```

速查：

| 转换符 | 含义 | 例子 |
|---|---|---|
| `%s` | `princ` 风格（脱引号） | `(format "%s" "abc")` → `abc` |
| `%S` | `prin1` 风格（带引号） | `(format "%S" "abc")` → `"abc"` |
| `%d` | 十进制 | `(format "%d" 42)` → `42` |
| `%o` / `%x` / `%X` | 八 / 十六 / 大写十六 | `52` / `2a` / `2A` |
| `%c` | 字符（吃整数或 `?x`） | `(format "%c" 65)` → `A` |
| `%f` / `%e` / `%g` | 定点 / 科学 / 自动 | `1.500000` / `1.500000e+00` / `1.5` |
| `%5.2f` | 宽度.精度（C 风格的旗标都支持） | ` 3.14` |
| `%%` | 字面的百分号 | `%` |

两个行为值得单独记住：

- **参数不够会报错**（`Not enough arguments for format string`），**参数多了却静默忽略**。`(format "%s" 1 2)` 得到 `"1"`，多余的 `2` 就丢了。这个不对称很容易让拼错参数的 bug 藏很久。
- `%%` 是转义。`(format "50%")` 会报错，必须写 `(format "50%%")`。同样的坑在 `message` 里也有一份——`message` 的格式串走的就是 `format`。

## 40.3 `print-length` / `print-level`：截断

打印一个巨大的结构时（比如 `*Backtrace*` 里那一坨），Emacs 用两个变量防止输出爆炸。示例第 3 节：

```elisp
(princ (format "  默认 print-length=%S print-level=%S（nil 就是不截断）\n"
               print-length print-level))
(let ((long (number-sequence 1 20)))
  (princ (format "  20 个元素的列表，默认: %S\n" (prin1-to-string long)))
  (princ (format "  print-length 3:         %S\n"
                 (let ((print-length 3)) (prin1-to-string long))))
  (princ (format "  print-length 对字符串无效: %S\n"
                 (let ((print-length 2)) (prin1-to-string "abcdef"))))
  (princ (format "  print-length 对向量有效: %S\n"
                 (let ((print-length 2)) (prin1-to-string [1 2 3 4])))))
(let ((deep '(1 (2 (3 (4 (5)))))))
  (princ (format "  五层嵌套，默认:      %S\n" (prin1-to-string deep)))
  (princ (format "  print-level 2:      %S\n"
                 (let ((print-level 2)) (prin1-to-string deep))))
  (princ (format "  print-level 1:      %S\n"
                 (let ((print-level 1)) (prin1-to-string deep)))))
```

```
== 3) print-length / print-level ==
  默认 print-length=nil print-level=nil（nil 就是不截断）
  20 个元素的列表，默认: "(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)"
  print-length 3:         "(1 2 3 ...)"
  print-length 对字符串无效: "\"abcdef\""
  print-length 对向量有效: "[1 2 ...]"
  五层嵌套，默认:      "(1 (2 (3 (4 (5)))))"
  print-level 2:      "(1 (2 ...))"
  print-level 1:      "(1 ...)"
```

- **`print-length`**：一个列表/向量最多打印几个元素，超了用 `...` 收尾。**对字符串无效**（字符串是原子，不是序列）。
- **`print-level`**：最多打印几层嵌套，超了整个子结构变成 `...`。
- 两者默认都是 `nil`，意思是不限制。

这两个是**全局变量**——改了会影响后面所有的打印，包括 `message` 和错误回溯。想局部生效就用 `let` 绑住（示例里就是这么做的），别 `setq`。

## 40.4 `print-circle`：环与共享结构

如果一个 cons 的 cdr 指回自己（环），`prin1` 会怎么办？示例第 4 节：

```elisp
(princ (format "  默认 print-circle=%S\n" print-circle))
(let* ((x (list 1 2))
       (circ (progn (setcdr (nthcdr 1 x) x) x)))
  (princ (format "  环形列表，默认打印: %S\n"
                 (let ((print-length 8)) (prin1-to-string circ))))
  (princ "  Emacs 不会无限循环，但那个 `#2` 读不回来。\n")
  (princ (format "  print-circle t:     %S\n"
                 (let ((print-circle t)) (prin1-to-string circ))))
  (let* ((str (let ((print-circle t)) (prin1-to-string circ)))
         (back (read str)))
    (princ (format "  读回来还是同一个环吗: %S（(nthcdr 2 r) eq r）\n"
                   (and (consp back) (eq (nthcdr 2 back) back))))))
(let* ((shared (list 9 9))
       (obj (list shared shared)))
  (princ (format "  两个位置共用同一个子表，默认: %S\n" (prin1-to-string obj)))
  (princ (format "  print-circle t:             %S\n"
                 (let ((print-circle t)) (prin1-to-string obj))))
  (let ((back (read (let ((print-circle t)) (prin1-to-string obj)))))
    (princ (format "  读回来还是共用吗: %S\n" (eq (nth 0 back) (nth 1 back)))))
  (princ (format "  不开 print-circle 就读回来: %S（变成两份拷贝）\n"
                 (eq (nth 0 (read (prin1-to-string obj)))
                     (nth 1 (read (prin1-to-string obj)))))))
```

```
== 4) print-circle ==
  默认 print-circle=nil
  环形列表，默认打印: "(1 2 1 2 . #2)"
  Emacs 不会无限循环，但那个 `#2` 读不回来。
  print-circle t:     "#1=(1 2 . #1#)"
  读回来还是同一个环吗: t（(nthcdr 2 r) eq r）
  两个位置共用同一个子表，默认: "((9 9) (9 9))"
  print-circle t:             "(#1=(9 9) #1#)"
  读回来还是共用吗: t
  不开 print-circle 就读回来: nil（变成两份拷贝）
```

- **默认不会死循环**。Emacs 检测到环就打出 `#N`（N 是「第几个子结构」的编号），但那个 `#2` **读不回来**——所以默认打印是「单向」的。
- 打开 `print-circle` 后，输出变成 `#1=(1 2 . #1#)`：`#1=` 是「给这个结构编号 1」，`#1#` 是「引用编号 1」。这个语法 `read` 认，读回来还是同一个环。
- **共享结构**同样受影响。两个位置共用同一个子表时，默认打印成两份 `((9 9) (9 9))`，读回来真的变成两份拷贝（`eq` 为 `nil`）；开了 `print-circle` 打印成 `(#1=(9 9) #1#)`，读回来仍然共用（`eq` 为 `t`）。

什么时候要开？**你要把结构存盘、或者要在日志里还原「是不是同一个对象」的时候**。平时打印给人看不用开——开了反而更难读。

## 40.5 `print-quoted` / `print-gensym`

`print-quoted` 管 `(quote x)` 打不打成 `'x`；`print-gensym` 管未 intern 的符号（[37 · 符号](37-symbols.md) 讲过 `make-symbol`）打不打 `#:` 前缀。示例第 5 节：

```elisp
(princ (format "  默认 print-quoted=%S\n" print-quoted))
(princ (format "  (prin1-to-string ''(a b))        = %S\n" (prin1-to-string ''(a b))))
(princ (format "  print-quoted nil 时:             = %S\n"
               (let ((print-quoted nil)) (prin1-to-string ''(a b)))))
(princ (format "  默认 print-gensym=%S\n" print-gensym))
(princ (format "  未 intern 的符号，默认:   %S\n" (prin1-to-string (make-symbol "foo"))))
(princ (format "  print-gensym t:           %S\n"
               (let ((print-gensym t)) (prin1-to-string (make-symbol "foo")))))
(let* ((str (let ((print-gensym t)) (prin1-to-string (make-symbol "foo"))))
       (back (read str)))
  (princ (format "  #:foo 读回来是未 intern 的符号: %S（obarray 里查不到 foo: %S）\n"
                 (symbolp back)
                 (null (intern-soft "foo")))))
```

```
== 5) print-quoted / print-gensym ==
  默认 print-quoted=t
  (prin1-to-string ''(a b))        = "'(a b)"
  print-quoted nil 时:             = "(quote (a b))"
  默认 print-gensym=nil
  未 intern 的符号，默认:   "foo"
  print-gensym t:           "#:foo"
  #:foo 读回来是未 intern 的符号: t（obarray 里查不到 foo: t）
```

- `print-quoted` 默认 `t`，所以 `''(a b)` 打印成 `'(a b)`；设成 `nil` 就老实打 `(quote (a b))`。两者 `read` 都能回来，纯粹是观感问题。
- `print-gensym` 默认 `nil`，所以 `(make-symbol "foo")` 打印出来就是一个光秃秃的 `foo`——**和 intern 过的 `foo` 长得一模一样**，读回来就变成 obarray 里的那个了（40.10 会看到这个后果）。设成 `t` 会打成 `#:foo`，`read` 认这个前缀，读回来仍然是未 intern 的符号。

写宏的时候这个开关很有用：宏展开结果里有 `gensym` 出来的符号，打开 `print-gensym` 才能看出「这个 `g123` 到底是 intern 过的还是临时的」。

## 40.6 换行与非 ASCII

示例第 6 节：

```elisp
(princ (format "  默认 print-escape-newlines=%S\n" print-escape-newlines))
(princ (format "  prin1 一个带换行的字符串: %S\n" (prin1-to-string "a\nb")))
(princ (format "  print-escape-newlines t:  %S\n"
               (let ((print-escape-newlines t)) (prin1-to-string "a\nb"))))
(princ (format "  princ 不受这个开关影响:   %S\n"
               (let ((print-escape-newlines t))
                 (with-output-to-string (princ "a\nb")))))
(princ (format "  pp 默认就把换行转义了（pp-escape-newlines=%S）: %S\n"
               pp-escape-newlines (pp-to-string "a\nb")))
(princ (format "  prin1 中文，默认:              %S\n" (prin1-to-string "中文")))
(princ (format "  print-escape-nonascii t:       %S（对 multibyte 没用）\n"
               (let ((print-escape-nonascii t)) (prin1-to-string "中文"))))
(princ (format "  print-escape-multibyte t:      %S\n"
               (let ((print-escape-multibyte t)) (prin1-to-string "中文"))))
```

```
== 6) 换行与非 ASCII ==
  默认 print-escape-newlines=nil
  prin1 一个带换行的字符串: "\"a
b\""
  print-escape-newlines t:  "\"a\\nb\""
  princ 不受这个开关影响:   "a
b"
  pp 默认就把换行转义了（pp-escape-newlines=t）: "\"a\\nb\"
"
  prin1 中文，默认:              "\"中文\""
  print-escape-nonascii t:       "\"中文\""（对 multibyte 没用）
  print-escape-multibyte t:      "\"\\x4e2d\\x6587\""
```

- **默认 `prin1` 不转义换行**——字符串里的 `\n` 会真的打出一个换行。这本身是合法的读语法（`read` 认字符串里的裸换行），但**输出会跨行**，混在日志里很难看。设 `print-escape-newlines` 为 `t` 就打成 `\n` 两个字符。
- `princ` 不受这个开关影响——它本来就原样输出。
- **`pp` 默认就转义换行**（`pp-escape-newlines` 默认 `t`）。这也是 `pp` 适合「打印给人看」的又一个理由。
- **非 ASCII**：`print-escape-nonascii` 对多字节字符**没有效果**（因为多字节字符本来就是可读的）；真正能把中文转成 `\x4e2d` 形式的是 `print-escape-multibyte`。

## 40.7 `float-output-format`

`prin1` 打印浮点数时走哪个格式，由这个变量定。示例第 7 节：

```elisp
(princ (format "  默认 float-output-format=%S\n" float-output-format))
(princ (format "  (prin1-to-string 1.0)=%S  (prin1-to-string 0.1)=%S\n"
               (prin1-to-string 1.0) (prin1-to-string 0.1)))
(princ (format "  设成 \"%%.2f\": %S\n"
               (let ((float-output-format "%.2f")) (prin1-to-string 3.14159))))
(princ (format "  设成 \"%%.3e\": %S\n"
               (let ((float-output-format "%.3e")) (prin1-to-string 3.14159))))
(princ (format "  format 的 %%s 走同一套: %S\n" (format "%s" 1.0)))
```

```
== 7) float-output-format ==
  默认 float-output-format=nil
  (prin1-to-string 1.0)="1.0"  (prin1-to-string 0.1)="0.1"
  设成 "%.2f": "3.14"
  设成 "%.3e": "3.142e+00"
  format 的 %s 走同一套: "1.0"
```

默认是 `nil`，意思是「用最短的、能无损读回来的表示」（`1.0`、`0.1`）。设成一个 `format` 风格的字符串就按它打印。

**注意这是个全局开关**：一旦设成 `"%.2f"`，你 `prin1` 出去的浮点数全都只剩两位小数，**精度就丢了**，读回来不再是原来的值。要固定小数位数，更安全的做法是在**拼接的那一步**用 `(format "%.2f" x)`，别动全局。

## 40.8 输出到哪里：`printcharfun`

`prin1` / `princ` / `print` 都有第二个参数 `printcharfun`，决定输出落到哪。示例第 8 节：

```elisp
(princ (format "  standard-output 默认=%S（nil 表示走标准输出 / echo 区）\n"
               standard-output))
(with-temp-buffer
  (prin1 '(a "b") (current-buffer))
  (princ (format "  prin1 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (princ "hi" (current-buffer))
  (princ (format "  princ 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (terpri (current-buffer))
  (princ (format "  terpri 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (write-char ?A (current-buffer))
  (princ (format "  write-char 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (insert "start")
  (prin1 '(1 2) (copy-marker (point-max)))
  (princ (format "  prin1 到 marker: %S（插在 marker 处）\n" (buffer-string))))
(princ (format "  with-output-to-string 把输出接成字符串: %S\n"
               (with-output-to-string (princ "x") (princ "y"))))
```

```
== 8) 输出到哪里 ==
  standard-output 默认=nil（nil 表示走标准输出 / echo 区）
  prin1 到 buffer: "(a \"b\")"
  princ 到 buffer: "hi"
  terpri 到 buffer: "
"
  write-char 到 buffer: "A"
  prin1 到 marker: "start(1 2)"（插在 marker 处）
  with-output-to-string 把输出接成字符串: "xy"
```

`printcharfun` 可以是：

| 取值 | 行为 |
|---|---|
| `nil`（默认） | 走 `standard-output`；在 `--batch` 下就是 stdout |
| `t` | 走 echo 区（等价于 `message` 的显示位置） |
| buffer | 插在该 buffer 的 **point 之后** |
| marker | 插在 marker 处，marker 随之移动 |
| 函数 | 每个字符（或字符串块）回调它一次 |

配套的还有 `terpri`（输出一个换行）和 `write-char`（输出一个字符），它们也吃 `printcharfun`。

最常用的组合是 **`with-output-to-string`**：把 `standard-output` 临时绑到一个字符串上，里面所有 `princ`/`prin1` 的输出都被收集起来，最后作为字符串返回。示例第 1 节就是靠它把四个打印函数的输出抓成可比较的字符串的。

## 40.9 读回来：`read` / `read-from-string`

示例第 9 节：

```elisp
(princ (format "  (read \"(+ 1 2)\")=%S\n" (read "(+ 1 2)")))
(princ (format "  (read-from-string \"(+ 1 2) rest\")=%S\n"
               (read-from-string "(+ 1 2) rest")))
(princ "  返回的是 (对象 . 结束位置)，所以能接着往下读。\n")
(princ (format "  (read-from-string \"42\")=%S\n" (read-from-string "42")))
(princ (format "  空串: %S\n"
               (condition-case err (read-from-string "")
                 (error (error-message-string err)))))
(princ (format "  没有 read-from-whole-string 这个函数: %S\n"
               (fboundp 'read-from-whole-string)))
(with-temp-buffer
  (insert "(+ 1 2)\n(* 3 4)\n")
  (goto-char (point-min))
  (princ (format "  从 buffer 读第一个: %S  point 现在=%S\n"
                 (read (current-buffer)) (point)))
  (princ (format "  再读第二个:         %S  point 现在=%S\n"
                 (read (current-buffer)) (point)))
  (princ "  read 会推进 point——这就是 `load' 能一段一段读下去的原因。\n"))
```

```
== 9) 读回来 ==
  (read "(+ 1 2)")=(+ 1 2)
  (read-from-string "(+ 1 2) rest")=((+ 1 2) . 7)
  返回的是 (对象 . 结束位置)，所以能接着往下读。
  (read-from-string "42")=(42 . 2)
  空串: "End of file during parsing"
  没有 read-from-whole-string 这个函数: nil
  从 buffer 读第一个: (+ 1 2)  point 现在=8
  再读第二个:         (* 3 4)  point 现在=16
  read 会推进 point——这就是 `load' 能一段一段读下去的原因。
```

- `read` 的参数是**流**：可以是字符串，也可以是 buffer（或 marker）。从 buffer 读时它会**推进 point**——这正是 `load` 能一段一段往下读的原理。
- **`read-from-string` 返回一个 cons**：`(对象 . 结束位置)`。`((+ 1 2) . 7)` 表示「读出了 `(+ 1 2)`，下一次从第 7 个字符开始」。想连续读就得自己拿着这个位置往下走。
- **读空内容报 `End of file during parsing`**，不是返回 `nil`。所以循环读取的正确终止条件是「到末尾了」而不是「读到 nil」——因为 `nil` 本身也是合法的读入结果（`()`）。
- 没有 `read-from-whole-string` 这个函数（`fboundp` 为 `nil`），别照抄别的方言的代码。

## 40.10 什么能原样读回来

`prin1` 和 `read` 号称是一对逆操作，但**不是所有对象都能原样往返**。示例第 10 节逐个验：

```elisp
(princ "  --- 能 ---\n")
(let ((obj '(1 "two" three (4 . 5) [6 7] :kw)))
  (princ (format "  普通结构: %S -> %S\n"
                 (prin1-to-string obj)
                 (equal obj (read (prin1-to-string obj))))))
(let ((s (propertize "hello" 'face 'bold)))
  (princ (format "  带文本属性的字符串: %S\n" (prin1-to-string s)))
  (princ (format "  读回来属性还在: %S\n"
                 (equal (get-text-property 0 'face (read (prin1-to-string s)))
                        'bold))))
(cl-defstruct demo-pt x y)
(let ((pt (make-demo-pt :x 1 :y 2)))
  (princ (format "  cl-defstruct 结构: %S\n" (prin1-to-string pt)))
  (princ "  注意它只写值不写槽名——改了 defstruct 的定义，旧数据就读错位了。\n"))
(let ((h (make-hash-table :test 'equal)))
  (puthash "a" 1 h)
  (princ (format "  equal 哈希表: %S\n" (prin1-to-string h)))
  (princ (format "  读回来 test 还在: %S\n"
                 (eq (hash-table-test (read (prin1-to-string h))) 'equal))))
(let ((h (make-hash-table :test 'equal :weakness 'value)))
  (puthash "a" 1 h)
  (princ (format "  弱表的 weakness 也写进去了，读回来: %S\n"
                 (hash-table-weakness (read (prin1-to-string h))))))
(princ "  --- 不能 ---\n")
(let ((buf (get-buffer-create " *demo-tmp*")))
  (princ (format "  buffer 打印成: %S\n" (prin1-to-string buf)))
  (princ (format "  读回来: %S\n"
                 (condition-case err (read (prin1-to-string buf))
                   (error (error-message-string err)))))
  (kill-buffer buf))
(let ((uni (make-symbol "not-interned")))
  (princ (format "  未 intern 的符号打印成 %S，读回来是同一个吗: %S\n"
                 (prin1-to-string uni)
                 (eq (read (prin1-to-string uni)) uni)))
  (princ "  打印出来只有名字，读回去变成 obarray 里的同名符号——不是同一个对象。\n"))
```

```
== 10) 什么能原样读回来 ==
  --- 能 ---
  普通结构: "(1 \"two\" three (4 . 5) [6 7] :kw)" -> t
  带文本属性的字符串: "#(\"hello\" 0 5 (face bold))"
  读回来属性还在: t
  cl-defstruct 结构: "#s(demo-pt 1 2)"
  注意它只写值不写槽名——改了 defstruct 的定义，旧数据就读错位了。
  equal 哈希表: "#s(hash-table test equal data (\"a\" 1))"
  读回来 test 还在: t
  弱表的 weakness 也写进去了，读回来: value
  --- 不能 ---
  buffer 打印成: "#<buffer  *demo-tmp*>"
  读回来: "Invalid read syntax: \"#<\""
  未 intern 的符号打印成 "not-interned"，读回来是同一个吗: nil
  打印出来只有名字，读回去变成 obarray 里的同名符号——不是同一个对象。
```

**能原样往返的**：

- 普通结构：数字、字符串、符号、cons、向量、关键字，全都能。
- **带文本属性的字符串**：打印成 `#("hello" 0 5 (face bold))` 这个读语法（`#'`、`#(` 都是 reader 的特殊语法，`#(` 表示「带属性的字符串」），读回来 `face` 属性还在。
- `cl-defstruct` 结构：打印成 `#s(demo-pt 1 2)`。**但注意它只写值、不写槽名**——你在 `cl-defstruct` 里插一个新槽、或者调整槽的顺序，旧数据读回来就错位了。序列化时这是个真实的兼容性风险。
- 哈希表：`#s(hash-table test equal data (...))`，`test` 和 `weakness` 都会写进去也都能读回来。

**不能的**：

- **buffer / window / process / frame 这类「有身份的」对象**：打印成 `#<buffer  *demo-tmp*>`，`#<` 是 reader 明确**拒绝**的读语法（`Invalid read syntax: "#<"`）。这类对象根本没法序列化——它们是活的对象，不是数据。
- **未 intern 的符号**：打印出来只是名字，读回去变成 obarray 里的同名符号，`eq` 为 `nil`。想保住就得开 `print-gensym`（40.5）。

顺带一提：上一章（[39 · 哈希表](39-hash-tables.md)）说过**自定义 `:test` 的哈希表也读不回来**——它能打出来，但 `read` 的时候那个测试函数符号不一定注册过。这是第三类失败：能打、能读、但语义不对。

## 40.11 `read` 不执行，以及文本属性会「粘」过来

示例第 11 节关两件事：

```elisp
(princ (format "  (read \"(kill-emacs)\")=%S —— 只是个列表，没被执行\n"
               (read "(kill-emacs)")))
(princ (format "  要执行得再 eval 一层: (eval (read \"(+ 1 2)\"))=%S\n"
               (eval (read "(+ 1 2)"))))
(let* ((bold (propertize "warn" 'face 'bold))
       (msg (format "value: %s" bold)))
  (princ (format "  (format \"value: %%s\" 带 face 的字符串)=%S\n" msg))
  (princ (format "  第 7 个字符的 face=%S（属性跟着一起粘进来了）\n"
                 (get-text-property 7 'face msg)))
  (princ (format "  第 0 个字符的 face=%S\n" (get-text-property 0 'face msg)))
  (let ((clean (substring-no-properties bold)))
    (princ (format "  先 substring-no-properties 再拼: %S  第7个=%S\n"
                   (format "value: %s" clean)
                   (get-text-property 7 'face (format "value: %s" clean))))))
```

```
== 11) read 不执行，以及属性粘连 ==
  (read "(kill-emacs)")=(kill-emacs) —— 只是个列表，没被执行
  要执行得再 eval 一层: (eval (read "(+ 1 2)"))=3
  (format "value: %s" 带 face 的字符串)=#("value: warn" 7 11 (face bold))
  第 7 个字符的 face=bold（属性跟着一起粘进来了）
  第 0 个字符的 face=nil
  先 substring-no-properties 再拼: "value: warn"  第7个=nil
```

**第一件事：`read` 只读不执行。** `(read "(kill-emacs)")` 得到的就是一个三元素列表 `(kill-emacs)`——一个符号，没被查函数格，更没被调用。要执行必须再套一层 `eval`。这个分离是 Lisp 的「代码即数据」能成立的基础：**读入是纯粹的解析，危险只发生在 `eval` 那一刻**。所以 `(read ...)` 一串来路不明的文本本身是安全的，`(eval (read ...))` 不是。

**第二件事：`format` 的 `%s` 会把文本属性一起带走。** `(format "value: %s" bold)` 的结果是 `#("value: warn" 7 11 (face bold))`——`bold` 那四个字符上的 `face` 属性被**粘**到了结果字符串的对应位置（第 7 到 11 个字符），而前缀 `"value: "` 干净。

这在两种地方会咬人：

1. 你把带属性的字符串拼进 `mode-line-format`，结果 mode line 上多出一截意料之外的字体（[34 · 初始化文件与 mode line](34-init-mode-line.md)）。
2. 你把带属性的字符串 `insert` 进 buffer，属性跟着一起进去（[11 · 文本属性](11-text-properties.md) 讲过这是特性，但有时候不是你想要的）。

要干净的拼接就先 `substring-no-properties`：

输出里最后一行就是这么做的。或者说，只要这个字符串**来自 buffer**（`buffer-substring`、`thing-at-point`、`match-string` 都可能带属性），拼进显示类字符串之前就该先去掉属性。

## 40.12 特殊读语法速查

最后一张表，把 reader 认的这些「# 开头的怪东西」汇总一下。示例第 12 节把它们逐个读了一遍：

```elisp
(dolist (s '("?a" "?\\n" "#b101" "#o17" "#x1f" "1.5e3" "-0.0" "1/2"
             "'(a b)" "`(a ,b)" "#'(lambda (x) x)" "[1 2 3]" "(a . b)"))
  (princ (format "  %-20S -> %S\n" s
                 (condition-case err (car (read-from-string s))
                   (error (error-message-string err))))))
(princ (format "  1/2 其实是符号而不是分数: %S\n"
               (symbolp (car (read-from-string "1/2")))))
```

```
== 12) 特殊读语法 ==
  "?a"                 -> 97
  "?\\n"               -> 10
  "#b101"              -> 5
  "#o17"               -> 15
  "#x1f"               -> 31
  "1.5e3"              -> 1500.0
  "-0.0"               -> -0.0
  "1/2"                -> 1/2
  "'(a b)"             -> '(a b)
  "`(a ,b)"            -> `(a ,b)
  "#'(lambda (x) x)"   -> #'(lambda (x) x)
  "[1 2 3]"            -> [1 2 3]
  "(a . b)"            -> (a . b)
  1/2 其实是符号而不是分数: t
```

| 写法 | 读成什么 | 备注 |
|---|---|---|
| `?a` | 字符 `a`（整数 97） | `?\n` = 10，`?\t`，`?\s`（空格）等等 |
| `#b101` / `#o17` / `#x1f` | 二进制 5 / 八进制 15 / 十六制 31 | 注意 `(string-to-number "0x1f")` 返回 0，别混用 |
| `1.5e3` | 浮点数 1500.0 | 指数记号 |
| `-0.0` | 负零 | 它 `=` 于 `0.0`，但 `eql` 不等于它 |
| `1/2` | **符号**，不是分数 | Emacs 没有有理数类型，读进来就是个名字叫 `1/2` 的符号 |
| `'(a b)` | `(quote (a b))` | 就是 `quote` |
| `` `(a ,b) `` | 反引号模板 | [38 · 求值](38-evaluation.md) 讲过它展开成 `cons`/`list`/`append` |
| `#'(lambda ...)` | `(function (lambda ...))` | `#'` 让字节编译器真的编译它 |
| `[1 2 3]` | 向量 | 不用 `quote`——向量是自求值的 |
| `(a . b)` | 点对 | [27 · cons cell](27-cons-cells.md) |
| `#s(...)` | 结构体 / 哈希表 / record | 见 40.10 |
| `#(...)` | 带文本属性的字符串 | 见 40.10 |
| `#N=` / `#N#` | 环与共享结构的标号 | 需要 `print-circle`，见 40.4 |
| `#:foo` | 未 intern 的符号 | 需要 `print-gensym`，见 40.5 |
| `#<...>` | **读不了** | 有身份的活对象，见 40.10 |

## 40.13 坑位清单

1. **`prin1` 保留引号、`princ` 脱引号** —— 要能被 `read` 回来的就用 `prin1`/`pp`；给人看的用 `princ`。
2. **`print` 前后各加一个换行、`pp` 末尾加一个** —— 拼字符串时别用 `print`，会多出空行。
3. **`format` 参数不够报错、参数多了静默忽略** —— 这个不对称让拼错参数的 bug 藏很久。
4. **`%%` 才是字面的百分号** —— `format` 和 `message` 都一样。
5. **`print-length` 对字符串无效、对向量有效** —— 它只管序列结构，字符串是原子。
6. **`print-length` / `print-level` 是全局变量** —— 要局部生效用 `let`，别 `setq`。
7. **环形结构默认打印成 `#N`，读不回来** —— 想存盘/还原共享关系就开 `print-circle`（输出 `#N=` / `#N#`）。
8. **未 intern 的符号默认打印出来和 intern 过的一模一样** —— 读回来就变成 obarray 里的那个了；开 `print-gensym` 打成 `#:foo` 才保得住。
9. **`prin1` 默认不转义换行** —— 字符串里的 `\n` 会真打出一个换行，日志会跨行；`pp` 默认就转义。
10. **`float-output-format` 是全局的** —— 设成 `"%.2f"` 之后所有浮点数打印都只剩两位，精度丢失；要固定位数在拼接那一步用 `(format "%.2f" x)`。
11. **`read` 从 buffer 读会推进 point** —— 这也是 `load` 的原理；循环读取时别自己再挪 point。
12. **`read-from-string` 返回 `(对象 . 位置)`，不是对象** —— 忘了 `car` 就会拿到一个 cons。
13. **读空内容报 `End of file during parsing`，不返回 `nil`** —— 循环终止条件要判「到末尾」，不能判「读到 nil」（`nil` 本身就是合法的读入结果）。
14. **`cl-defstruct` 打印只写值不写槽名** —— 改了定义，旧数据读回来会错位。
15. **`#<...>` 读不了** —— buffer / window / process / frame 这些「有身份的」对象没法序列化。
16. **自定义 `:test` 的哈希表打得出、读得回，但语义不对** —— `read` 时那个测试函数未必注册过。
17. **`format` 的 `%s` 会把文本属性一起粘走** —— 字符串来自 buffer 时要先 `substring-no-properties`。
18. **`read` 只读不执行** —— 危险发生在 `eval` 那一刻，不在 `read`；所以 `(eval (read ...))` 才是需要小心的写法。
19. **没有 `read-from-whole-string` 这个函数** —— 别从别的 Lisp 方言照抄。
20. **`1/2` 读进来是符号，不是分数** —— Emacs 没有有理数类型。

到这里第 10 部分就告一段落了。回头看这条主线：[36 · 数字](36-numbers.md) 讲了值的表示，[37 · 符号](37-symbols.md) 讲了名字的四格，[38 · 求值](38-evaluation.md) 讲了「什么时候求值」，[39 · 哈希表](39-hash-tables.md) 讲了大规模键值存储，本章讲「对象和文本之间怎么来回」。这五章合起来，正好把参考手册里那些「不写在主线里、但你会一天撞三次」的语言层细节补齐了。

接下来的第 11 部分换一本手册：跟随 GNU Emacs Common Lisp Emulation 手册，把 cl-lib 从来历与命名约定（[41 · cl-lib 是什么](41-cl-lib-overview.md)）一路讲到宏工具、广义变量、作用域、`cl-loop`、序列与列表、类型与结构（[48 · 类型与结构](48-types-structs.md)）。附录 A 按症状把全书（含这两部分）的坑做了一遍索引，附录 B 是命令与变量的速查表。

上一章：[39 · 哈希表：测试函数、遍历与弱引用](39-hash-tables.md)　｜　下一章：[41 · cl-lib 是什么：来历、加载、命名与移植](41-cl-lib-overview.md)　｜　返回：[Emacs 扩展开发指南](README.md)
