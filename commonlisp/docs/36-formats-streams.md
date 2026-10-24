# 36 · 外部格式、路径名与自定义流

> 字符怎么变成字节、路径名怎么跨过 Lisp 与操作系统的边界、以及怎么用
> CLOS 亲手造一个能传给 `format` 的流——这三件事 ANSI 只给了一半答案，
> 另一半在 SBCL 手册第 8 章「External Formats」、第 10 章「Pathnames」
> 和第 11 章「Streams」里。本章把这三块一次讲透。
>
> 配套例程：[`examples/36_formats_streams/`](../examples/36_formats_streams/main.lisp)
>
> 与前面各章一样，本章**自包含**：手册对应小节的核心内容全部在正文里
> 讲清楚，所有断言值都在 SBCL 2.6.9 上实测过。

## 36.1 外部格式：字符与字节之间的翻译官

Lisp 字符串里的字符是抽象的；落到磁盘、网络、子进程管道里就是字节
序列。**外部格式**（external format）就是这个翻译的规格：用什么编码、
换行怎么处理、遇到翻不了的字节怎么办。它出现在所有「字符进出外界」
的地方：文件流、socket、`run-program` 的子进程管道（第 23 章）、
文件名、C 字符串（第 25 章）、sb-posix 接口。

三个默认值（全是 `sb-ext` 变量）：

```lisp
sb-ext:*default-external-format* ; => :UTF-8
```

- `*default-external-format*`：`open` 等大多数场合的默认；
- `*default-source-external-format*`（默认 `:default`）：读源码文件用，
  也就是 `load` / `compile-file`；
- `*default-c-string-external-format*`（默认 `:utf-8`）：FFI 的
  `c-string` 转换用（第 25 章见过）。

**外部格式指示符**（designator）有三种写法：

- `:default` —— 当前默认外部格式；
- 关键字，如 `:utf-8`、`:latin-1` —— 该编码本身；
- `(编码名 . 选项表)` —— 在编码之上叠加选项，例如
  `'(:utf-8 :replacement #\?)`。选项有两个：
  - `:newline` —— `:lf`（默认，`#\Linefeed` 就是 `#\Newline`）、
    `:cr`（`#\Return` 当换行）、`:crlf`（`\r\n` 双字节与 `#\Newline`
    互转）；
  - `:replacement` —— 遇到编/解码不了的字符时不报错，原地插入替换
    字符（任意字符串指示符）。

支持的编码：`utf-8`/`utf-16`/`utf-32`、`ucs-2`/`ucs-4`（各有
`be`/`le` 大小端变体）、`latin-1` 及整个 `latin-n` 家族、`ascii`、
`koi8-r`、`cp1250`–`cp1258`，以及日文 `euc-jp`/`shift_jis`（别名
`:sjis`/`:cp932`）、中文 `gbk`（别名 `:cp936`）等，每个编码都有
若干别名。完整清单见手册「Supported External Formats」。

## 36.2 字符串 ↔ 字节向量

不经过流，直接转换用 `sb-ext:string-to-octets` 和
`sb-ext:octets-to-string`——网络协议、加密、文件格式解析里的高频
操作。先立一个本章反复用的小工具（字面量 `#(195 169)` 的元素类型是
`T` 不是 `(unsigned-byte 8)`，直接喂给下面两个函数会吃 type-error，
必须显式建专用向量）：

```lisp
(defun ub8 (&rest xs)
  (make-array (length xs)
              :element-type '(unsigned-byte 8)
              :initial-contents xs))
(sb-ext:string-to-octets "hi") ; => #(104 105)
(sb-ext:string-to-octets "é")  ; é 在 utf-8 里是两个字节
(sb-ext:octets-to-string (ub8 195 169)) ; => "é"
```

`:external-format` 指定编码，`:start`/`:end` 只转换子串，
`:null-terminate t` 在结尾补一个 0 字节（配 C 世界的字符串用）：

```lisp
(sb-ext:string-to-octets "hi" :null-terminate t) ; => #(104 105 0)
(sb-ext:string-to-octets "abcde" :start 1 :end 3) ; => #(98 99)
(sb-ext:octets-to-string (ub8 104 105) :external-format :latin-1) ; => "hi"
```

注意**长度不守恒**：utf-8 里 `é` 是 2 字节、中文常见 3 字节，
`:null-terminate` 再加一——别假设 `(length (string-to-octets s))`
等于 `(length s)`。还有一个断言陷阱：返回的是专用
`(unsigned-byte 8)` 向量，而字面量 `#(104 105)` 的元素类型是
`T`，**`equal` 会因为元素类型不同而判 `nil`**（打印出来一模一样），
比较要用 `equalp`。

## 36.3 编解码失败：报错还是替换

ASCII 编不了 `é`，utf-8 解不了截半的字节序列。默认行为是 signal
（可继续的）错误——条件类型是 `sb-int:character-encoding-error` 和
`sb-int:character-decoding-error`（目前未正式导出文档化）：

```lisp
(handler-case (sb-ext:string-to-octets "é" :external-format :ascii)
  (sb-int:character-encoding-error () :enc-err)) ; => :ENC-ERR
(handler-case (sb-ext:octets-to-string (ub8 195) :external-format :utf-8)
  (sb-int:character-decoding-error () :dec-err)) ; => :DEC-ERR
```

处理「来路不明的半截数据」更实用的姿势是 `:replacement`：坏字节
原地换成替换字符，绝不中断。读脏日志、扫损坏文件时用它：

```lisp
(sb-ext:octets-to-string (ub8 104 195 105)          ; h + 坏字节 + i
                         :external-format '(:utf-8 :replacement #\?)) ; => "h?i"
```

同样的写法也用在 `open` 的 `:external-format` 上——手册的例子：
`(with-open-file (stream pathname :external-format '(:utf-8 :replacement #\?)) ...)`
读文件时把所有非法 utf-8 序列换成问号。

## 36.4 流上的外部格式与换行翻译

文件流创建时用 `:external-format` 指定，事后用
`stream-external-format` 查询（返回**规范化名**——你写 `:utf8` 它
也回你 `:UTF-8`）：

```lisp
(with-open-file (f "doc36-ef.txt" :direction :output
                   :if-exists :supersede)
  (stream-external-format f)) ; => :UTF-8
(delete-file "doc36-ef.txt")
```

`:newline` 选项做换行翻译——Windows 文本文件打交道时必备。对
`#\Newline`：`:crlf` 把它写成 `\r\n`，读时再还原：

```lisp
(sb-ext:string-to-octets (coerce '(#\a #\newline) 'string)
                         :external-format '(:utf-8 :newline :crlf)) ; => #(97 13 10)
```

落到文件上验证一遍——以 `:crlf` 写一行，再按**字节**读回来，
`\r\n`（13 10）原形毕露：

```lisp
(with-open-file (f "doc36-crlf.txt" :direction :output
                   :if-exists :supersede
                   :external-format '(:latin-1 :newline :crlf))
  (write-line "ab" f))
(with-open-file (f "doc36-crlf.txt" :element-type '(unsigned-byte 8))
  (let ((v (make-array 4 :element-type '(unsigned-byte 8))))
    (read-sequence v f)
    (coerce v 'list))) ; => (97 98 13 10)
(delete-file "doc36-crlf.txt")
```

## 36.5 双价流：一个流同时读写字符和字节

`open` 传 `:element-type :default` 得到**双价流**（bivalent
stream）：既能 `read-char`/`write-char`，又能
`read-byte`/`write-byte`（字节侧固定 `(unsigned-byte 8)`）：

```lisp
(with-open-file (f "doc36-bi.bin" :direction :io
                   :if-exists :supersede
                   :element-type :default :external-format :utf-8)
  (write-char #\A f)
  (write-byte 200 f)
  (file-position f 0)
  (list (read-char f) (read-byte f))) ; => (#\A 200)
(delete-file "doc36-bi.bin")
```

典型场景：先按文本读协议头（HTTP 的 `GET ... CRLF`），随后同一条
连接上收发二进制体。两点代价要知道：默认**不**开双价（有性能开销，
和内部 `fast-read-char` 批量优化不兼容）；socket 上要用双价得看
第 37 章的 `sb-bsd-sockets` 相关说明。

## 36.6 Gray 流：用 CLOS 造自己的流

ANSI 没有自定义流的标准接口；事实标准是 **Gray 流**（Gray Streams
协议），SBCL 把它内置在 `sb-gray` 包里（核心自带，不用 require）。
思路：继承基类，给一组泛函加方法，你的实例就能当普通流用——`format`、
`read`、`write-line`、`with-output-to-string` 之外的一切流消费者
都照常工作。

类层级（`sb-gray:` 前缀）一张表：

| 类 | 用途 |
|---|---|
| `fundamental-stream` | 万流之祖 |
| `fundamental-input-stream` / `fundamental-output-stream` | 方向 |
| `fundamental-character-stream` / `fundamental-binary-stream` | 字符 / 字节 |
| `fundamental-character-input-stream` 等四个组合 | 实际继承的落点 |

**必答的方法**（没有默认实现，缺了就用不了）：

- 字符输入流：`stream-read-char`（返回字符或 `:eof`）、
  `stream-unread-char`；
- 字符输出流：`stream-write-char`、`stream-line-column`（允许永远
  返回 `nil`，但方法必须存在）；
- 二进制流：`stream-read-byte` / `stream-write-byte`，
  外加可用的 `stream-element-type`。

**可选方法**（有默认实现，性能或行为不合意时再覆盖）：
`stream-peek-char`、`stream-listen`、`stream-read-char-no-hang`、
`stream-read-line`、`stream-read-sequence`、`stream-write-string`、
`stream-write-sequence`、`stream-terpri`、`stream-fresh-line`、
`stream-force-output` / `stream-finish-output` / `stream-clear-output` /
`stream-clear-input`、`stream-file-position`、`stream-line-length`、
`stream-advance-to-column`，以及 `close`。默认的逐字符实现能跑，
但 `read-sequence`/`write-sequence` 这种批量方法值得专门写——快
得多。

### 36.6.1 实例一：计数输入流

手册的经典例子：包一层现有流，顺手统计读了多少字符、多少行、当前
第几列——写解析器报「第几行第几列出错」全靠它。所有类和方法自包含
如下（注意我们不 `in-package`，全部显式限定包名，读者可直接按块敲进
REPL）。两个细节：其一，下面统一用**双冒号** `g36::` 前缀——`g36`
包没有 export 任何符号，而**单冒号** `g36:foo` 在 `foo` 尚不存在时
读取器直接报 package-error（单冒号只引用既有符号，双冒号才会 intern
新符号），`defclass` 写下的新名字必然「尚不存在」；其二，
`stream-element-type` 与 `close` **不带** `sb-gray:` 前缀——它们是
CL 包自己的泛函，`sb-gray` 只在内部碰它们、并未导出，写
`sb-gray:stream-element-type` 同样会在读取期报「not external」：

```lisp
(defpackage :g36 (:use :cl :sb-gray))
(defclass g36::wrapped-stream (sb-gray:fundamental-stream)
  ((inner :initarg :stream :reader g36::inner-of)))
(defmethod stream-element-type ((s g36::wrapped-stream))
  (stream-element-type (g36::inner-of s)))
(defmethod close ((s g36::wrapped-stream) &key abort)
  (close (g36::inner-of s) :abort abort))
(defclass g36::wrapped-char-in
    (g36::wrapped-stream sb-gray:fundamental-character-input-stream)
  ())
(defmethod sb-gray:stream-read-char ((s g36::wrapped-char-in))
  (read-char (g36::inner-of s) nil :eof))
(defmethod sb-gray:stream-unread-char ((s g36::wrapped-char-in) char)
  (unread-char char (g36::inner-of s)))
```

计数逻辑放在 `:around` 方法里，复用上面的读实现：

```lisp
(defclass g36::counting-in (g36::wrapped-char-in)
  ((chars :initform 0 :accessor g36::chars-of)
   (lines :initform 1 :accessor g36::lines-of)
   (cols :initform 0 :accessor g36::cols-of)))
(defmethod sb-gray:stream-read-char :around ((s g36::counting-in))
  (let ((c (call-next-method)))
    (unless (eql c :eof)
      (incf (g36::chars-of s))
      (if (char= c #\newline)
          (progn (incf (g36::lines-of s)) (setf (g36::cols-of s) 0))
          (incf (g36::cols-of s))))
    c))
```

它就是个普通流——`read` 照常工作（`read` 内部会跳过空白，所以计数
比 token 本身多）：

```lisp
(with-input-from-string (in "1 2
3 ")
  (let ((s (make-instance 'g36::counting-in :stream in)))
    (list (read s) (read s) (read s)))) ; => (1 2 3)
(with-input-from-string (in "1 2
3 ")
  (let ((s (make-instance 'g36::counting-in :stream in)))
    (read s) (read s) (read s)
    (list (g36::chars-of s) (g36::lines-of s) (g36::cols-of s)))) ; => (9 3 3)
```

第二个断言读起来：`read` 三次共消费 9 个字符（含空白），跨过 2 个
换行（行数 1→3），当前行读了 3 列。注意 `unread-char` 的回退计数
（手册完整版里有）生产环境记得补，否则列号会漂。

### 36.6.2 实例二：每行加前缀的输出流

日志流的标准姿势：每行行首自动打时间戳/前缀。最小实现——列号归零时
（行首）先写前缀，再写字符：

```lisp
(defclass g36::wrapped-char-out
    (sb-gray:fundamental-character-output-stream)
  ((inner :initarg :stream :reader g36::out-inner-of)
   (col :initform 0 :accessor g36::col-of)))
(defmethod sb-gray:stream-line-column ((s g36::wrapped-char-out))
  (g36::col-of s))
(defmethod sb-gray:stream-write-char ((s g36::wrapped-char-out) char)
  (write-char char (g36::out-inner-of s))
  (if (char= char #\newline)
      (setf (g36::col-of s) 0)
      (incf (g36::col-of s)))
  char)
(defclass g36::prefixed-out (g36::wrapped-char-out)
  ((prefix :initarg :prefix :reader g36::prefix-of)))
(defmethod sb-gray:stream-write-char :around ((s g36::prefixed-out) char)
  (when (zerop (g36::col-of s))
    (write-string (g36::prefix-of s) (g36::out-inner-of s)))
  (call-next-method))
```

验证：往字符串流里写两行，前缀各就各位（`search` 找得到起始下标）：

```lisp
(let ((text (with-output-to-string (out)
              (let ((s (make-instance 'g36::prefixed-out
                         :stream out :prefix "[log] ")))
                (write-line "abc" s)
                (write-line "def" s)))))
  (list (search "[log] abc" text) (search "[log] def" text))) ; => (0 10)
```

生产实现还应覆盖 `stream-write-string`（整串直写而非逐字符）和
`stream-force-output`；手册原版把前缀做成函数（打时间戳），原理相同。

手册还提到第三套扩展——**simple streams**（contrib `sb-simple-streams`，
Allegro 提案的子集实现）。SBCL 自评 alpha 品质、多数类是空壳，本章
不展开，新代码请用 Gray 流。

## 36.7 路径名扩展

### 36.7.1 home 目录说明符

目录组件里允许 `:home`（当前用户）和 `(:home "用户名")`，namestring
里就是开头的 `~/` 和 `~user/`（别处的波浪号是普通字符）：

```lisp
(pathname-directory #p"~/foo.txt") ; => (:ABSOLUTE :HOME)
```

`(:home "user")` 形式在 Windows 上 signal 错误。`sb-ext:native-namestring`
把 `:home` 展开成真实家目录再交给操作系统（所以同一个 `#p"~/x"` 在
不同机器上 `native-namestring` 出来的字符串不同）。

### 36.7.2 原生文件名：parse-native-namestring 一家

`parse-namestring` 按 Lisp 的规则解析（支持通配 `*`、`..` 之类），
但操作系统给的字符串常常**不该**这么解——文件名里的 `*` 就是字面量
星号。三个函数解决「拿 OS 字符串 ↔ Lisp 路径名」的直译（全部
`sb-ext:`）：

- `parse-native-namestring` 字符串 → 路径名（按本机惯例）；
- `native-pathname` 等价的 pathname-designator 转换；
- `native-namestring` 路径名 → 本机字符串（`:home` 在此展开）。

最经典的坑：目录字符串带不带尾斜杠，解析结果**语义不同**——

```lisp
(list (pathname-directory #P"/tmp/") (pathname-name #P"/tmp/")) ; => ((:ABSOLUTE "tmp") NIL)
(list (pathname-directory #P"/tmp") (pathname-name #P"/tmp")) ; => ((:ABSOLUTE) "tmp")
```

`/tmp/` 是「tmp 目录」，`/tmp` 是「根目录下叫 tmp 的文件」。原生
版本同样区分，但给了强制统一的旋钮——`:as-directory t` 让 `/tmp`
也按目录解析，`:as-file t` 让 `native-namestring` 把目录输出成
文件形式：

```lisp
(sb-ext:parse-native-namestring "/tmp" nil *default-pathname-defaults*
                                :as-directory t) ; => #P"/tmp/"
(sb-ext:native-namestring (sb-ext:parse-native-namestring "/tmp/")
                          :as-file t) ; => "/tmp"
```

处理 shell 输出、`readdir` 结果这类「不知道带没带尾斜杠」的输入时，
这两个参数就是救命稻草。另一个提醒：路径名 ↔ 原生串往返不保证
`equal` 回到原样，比较请用一种规范形式。

### 36.7.3 SYS 逻辑主机

SBCL 预定义了 `SYS` 逻辑路径名主机：核心源码匹配
`"SYS:SRC;**;*.*.*"`、contrib 匹配 `"SYS:CONTRIB;**;*.*.*"`。站点
可以用 `sb-ext:set-sbcl-source-location`（传 SBCL 源码顶层目录）
初始化这些翻译——配好之后，调试器里 `M-x slime-edit-definition`
式的跳转、`(ed "SYS:SRC;CODE;FDEFIN.LISP")` 才有处可去。

## 36.8 小结

- 外部格式 = 编码 + 换行策略 + 替换策略；指示符三种写法，选项就
  `:newline`（`:lf`/`:cr`/`:crlf`）和 `:replacement` 两个。
- `string-to-octets` / `octets-to-string` 直转；字面量 `#(...)` 不是
  `(unsigned-byte 8)` 向量，要显式 `make-array`；转换长度不守恒。
- 编解码失败默认 signal `sb-int:character-encoding-error` /
  `character-decoding-error`；脏数据用 `:replacement` 选项兜底。
- 文件流 `:external-format` 全程生效，`stream-external-format` 查询；
  `:crlf` 换行翻译文本文件必备。
- `:element-type :default` 开双价流，字符字节混读写；有性能代价。
- Gray 流 = 继承 `sb-gray` 基类 + 给泛函加方法；字符输入必答
  `stream-read-char`/`stream-unread-char`，字符输出必答
  `stream-write-char`/`stream-line-column`；批量方法值得手写。
- `~/` 对应目录组件 `:home`；OS 字符串用 `parse-native-namestring`
  直译，尾斜杠语义不同，`:as-directory`/`:as-file` 强制统一。
