# 38 · contrib 模块巡礼

> SBCL 的发行包里除了核心系统，还有一批 **contrib 模块**：不算 ANSI
> 标准、也不算核心运行时，但随 SBCL 一起构建、一起发布，质量由 SBCL
> 团队背书。手册第 17 章专门讲它们。前面章节其实已经见过两位——
> 第 26 章的性能分析器 **sb-sprof**、第 37 章的 **sb-bsd-sockets**。
> 本章把其余值得知道的模块一次巡完：MD5、位旋转、无锁并发结构、
> 内省、POSIX 接口、CLTL2 环境查询、覆盖率工具、SIMD 向量化。
>
> 配套例程：[`examples/38_contrib/`](../examples/38_contrib/main.lisp)
>
> 与前面各章一样，本章**自包含**：手册对应章节的核心内容全部在正文里
> 讲清楚，所有断言值都在 SBCL 2.6.9 上实测过。手册与实现有出入的
> 地方（比如 `frlock-read` 的多值语义），正文会明确指出并以实现为准。

## 38.1 contrib 是什么，怎么加载

contrib 模块就是 SBCL 源码树 `contrib/` 目录下、编译时产物落在
安装目录 `contrib/` 下的一批 `.fasl` 文件。加载方式与 ASDF 一样走
`require`——给出的名字是关键字，SBCL 会去 contrib 目录找同名 fasl：

```lisp
(require :sb-md5)     ; 加载后，SB-MD5 包可用
(and (member "SB-MD5" *modules* :test #'string=) t) ; => T
```

已加载的模块名（大写字符串）记录在 `*modules*` 里。再次 `require`
是空操作，所以把 `require` 写进源文件顶部没有成本。

有一个**读取期**的坑要养成习惯避开：`require` 是运行时动作，而
`sb-md5:md5sum-string` 这样的限定符号在**读取**（read）阶段就要解析
包名。把 `(require :sb-md5)` 和引用 `SB-MD5:` 符号的代码写进同一个
文件时，`require` 必须放在文件**顶部的顶层表单**——LOAD 逐表单
边读边执行，读到后面的符号时包已经存在了。反过来，如果把引用
contrib 包的符号藏在文件中后部、require 却写在某个函数体内，
加载时就会吃到「Package SB-MD5 does not exist」。

SBCL 2.6.9 自带 22 个 contrib 模块。本章深讲 8 个，其余在 38.10
速览。

## 38.2 sb-md5：MD5 摘要

`sb-md5` 提供 MD5 算法，入口是一族 `md5sum-*` 函数。**返回值不是
十六进制字符串，而是 16 字节的 `(unsigned-byte 8)` 向量**——要给人看
需要自己格式化：

```lisp
(require :sb-md5)

(defun md5-hex (digest)
  "把 16 字节摘要向量格式化成小写十六进制字符串。"
  (format nil "~(~{~2,'0X~}~)" (coerce digest 'list)))

(md5-hex (sb-md5:md5sum-string "abc")) ; => "900150983cd24fb0d6963f7d28e17f72"
(md5-hex (sb-md5:md5sum-string ""))    ; => "d41d8cd98f00b204e9800998ecf8427e"
(length (sb-md5:md5sum-string "abc"))  ; => 16
```

`~{~2,'0X~}` 是 `format` 的迭代子句：每个字节按至少两位、补零的
十六进制大写打印，外层 `~(...~)` 再整体转小写。这两个值是公开的
MD5 测试向量，顺手验证了实现的正确性。

三个入口按输入来源区分：

```lisp
;; md5sum-sequence：只吃 (vector (unsigned-byte 8))，字符串会被拒
(md5-hex (sb-md5:md5sum-sequence
          (make-array 3 :element-type '(unsigned-byte 8)
                        :initial-contents '(97 98 99)))) ; => "900150983cd24fb0d6963f7d28e17f72"

;; md5sum-file：对文件内容算摘要
(with-open-file (s "/tmp/ex38-md5.txt" :direction :output :if-exists :supersede)
  (write-string "md5-file" s))
(md5-hex (sb-md5:md5sum-file "/tmp/ex38-md5.txt")) ; => "82c91807946785960beb35a49a73fdee"
```

注意 `md5sum-sequence` 的类型约束很严：传字符串会收到
type-error（字符串不是 ub8 向量）。对字符串要么用 `md5sum-string`，
要么先编码成字节向量。还有第四个入口 `md5sum-stream`，对二进制流
的剩余内容算摘要。

## 38.3 sb-rotate-byte：循环移位

ANSI 有 `ash`（算术移位，移出去的位丢弃），没有循环移位。
`sb-rotate-byte` 补上了这一个函数：

```lisp
(require :sb-rotate-byte)

(sb-rotate-byte:rotate-byte 2 (byte 8 0) #b00001111)  ; => 60
(sb-rotate-byte:rotate-byte -2 (byte 8 0) #b11000000) ; => 48
(sb-rotate-byte:rotate-byte 4 (byte 8 0) #b10110000)  ; => 11
(sb-rotate-byte:rotate-byte 8 (byte 16 0) #x1234)     ; => 13330
```

三个参数：旋转位数 `count`（负值反向旋转）、字节说明符
`bytespec`（同 `ldb`/`dpb` 的 `(byte 宽度 位置)`）、整数。
语义是：**只有 bytespec 圈出的那个位场参与循环**，场外的位原样
保留。第一行里 `#b00001111` 在 8 位场里左旋 2 位得到 `#b00111100`
即 60；第四行 `#x1234` 在 16 位场里旋 8 位正好高低字节互换，
得 `#x3412` 即 13330。看一个「场外保留」的例子：

```lisp
;; 只有低 4 位参与旋转：0001 左旋 1 成 0010，高 4 位 1011 不动
(sb-rotate-byte:rotate-byte 1 (byte 4 0) #b10110001) ; => 178
```

`#b10110001` = 177，低 4 位旋转后变成 `#b10110010` = 178。这个
函数在实现哈希、加密、二进制协议编解码时很常用；SBCL 对它有
编译器级优化，常量位场会编成一条 `rotate` 机器指令。

## 38.4 sb-concurrency：无锁并发结构

这是手册 17.2 节的主角，一套**无锁（lock-free）**并发数据结构。
与第 24 章的 mutex 思路相反：不抢锁，靠 CAS（compare-and-swap）
和重试保证正确，读多写少的场景下吞吐明显更好。

### 队列与信箱

`queue` 是无锁先进先出队列，`mailbox` 是带等待语义的线程间信箱：

```lisp
(require :sb-concurrency)

(let ((q (sb-concurrency:make-queue :name "q38")))
  (sb-concurrency:enqueue 1 q)
  (sb-concurrency:enqueue 2 q)
  (sb-concurrency:queue-count q)   ; => 2
  (sb-concurrency:dequeue q)       ; => 1
  (sb-concurrency:dequeue q)       ; => 2
  (sb-concurrency:queue-empty-p q) ; => T
  (sb-concurrency:dequeue q)       ; => NIL   ← 空队列出队得 NIL
  (sb-concurrency:enqueue :a q)
  (sb-concurrency:enqueue :b q)
  (sb-concurrency:list-queue-contents q)) ; => (:A :B)
```

`dequeue` 空队列返回 `NIL`（不等待、不报错），所以拿 `NIL` 当队列
元素会分不清「取到 NIL」和「队列空」——这是无锁队列的常见约定，
元素里别放 `NIL`，或者改用下面的 mailbox。

```lisp
(let ((mb (sb-concurrency:make-mailbox :name "mb38")))
  (sb-concurrency:send-message mb :hello)
  (sb-concurrency:receive-message mb :timeout 0.1) ; => :HELLO
  (sb-concurrency:mailbox-empty-p mb)              ; => T
  (sb-concurrency:receive-message mb :timeout 0.1) ; => NIL   ← 超时返回 NIL
  (sb-concurrency:send-message mb 1)
  (sb-concurrency:send-message mb 2)
  (sb-concurrency:receive-pending-messages mb)     ; => (1 2) ← 一把取光
  (sb-concurrency:mailbox-count mb))               ; => 0
```

`receive-message` 不给 `:timeout` 会**一直等到有消息为止**——这就
是 mailbox 相对 queue 多出来的等待语义：拿它做生产者-消费者队列，
消费者线程 `receive-message` 阻塞，生产者 `send-message` 唤醒。
`receive-pending-messages` 一次取走当前所有消息，适合批量处理。

### 门（gate）

gate 是最简单的同步原语：一道要么是开、要么是关的门，
`wait-on-gate` 等到门开为止：

```lisp
(let ((g (sb-concurrency:make-gate :open t)))
  (sb-concurrency:wait-on-gate g :timeout 0.1))  ; => T   ← 门本来就开着，直接通过

(let ((g (sb-concurrency:make-gate :open nil)))
  (sb-concurrency:wait-on-gate g :timeout 0.1)   ; => NIL  ← 超时了门还没开
  (sb-concurrency:gate-open-p g)                 ; => NIL
  (sb-concurrency:open-gate g)
  (sb-concurrency:wait-on-gate g :timeout 0.1)   ; => T
  (sb-concurrency:close-gate g)
  (sb-concurrency:wait-on-gate g :timeout 0.1))  ; => NIL
```

`wait-on-gate` 返回 `T` 表示「在时限内门开了」，`NIL` 表示超时。
典型用法是「起跑枪」：所有工作线程 `wait-on-gate` 堵在门口，主线
程 `open-gate` 一声令下全部开跑；或者反过来做「完成闸」：某个条
件成立后放行了了等待者。

### frlock：快速读锁

frlock（Fast Read Lock）是这套结构里最精巧的一个，思路是「读不
加锁，写加锁，读者校验」：

- **读者**进入保护区**不等待**：先取一个读令牌，读完再取一个，
  两次相同说明期间没有写者动过数据，读到的值一致；不同就重读。
- **写者**独占：同一时刻只允许一个写者，写操作会使在读者的令牌
  失效。

所以 frlock 适合**读远多于写**的场景；但它只保证「一致」不保证
「互斥」——读者和写者会并行操作同一份数据。手册特意警告：**别拿
它保护哈希表**（并行读写哈希表本身就不安全），适合保护「写者换
入一组新值、读者读出一组自洽旧值或新值」的标量组合。

接口是两个宏，第一个实参都是 `(frlock)` 这样的单元素列表：

```lisp
(defvar *fr-a* 0)
(defvar *fr-b* 0)
(defvar *fr-c* 0)
(defvar *fr-lk* (sb-concurrency:make-frlock :name "lk38"))

(defun fr-foo ()
  ;; 读侧：多个 value-form，各自求值，主值拼成多值返回
  (sb-concurrency:frlock-read (*fr-lk*) *fr-a* *fr-b* *fr-c*))

(defun fr-bar (x y)
  ;; 写侧：body 在写锁内执行
  (sb-concurrency:frlock-write (*fr-lk*)
    (setf *fr-a* x *fr-b* y *fr-c* (+ x y))))

(fr-bar 1 2)
(multiple-value-list (fr-foo)) ; => (1 2 3)
```

读者拿到的 `(1 2 3)` 一定自洽：`c` 要么是旧值（与旧的 `a`、`b`
匹配），要么是新值，不会读到 `a` 已更新而 `b` 还没更新的中间态。

这里有一处**手册与实现的出入**，值得记住：手册说 `frlock-read`
对 value-forms「返回其多值」，而 SBCL 2.6.9 的实现是**每个
value-form 只保留主值**，再把各主值拼成多值。也就是说把手册语义
理解成「包一个 `(values ...)` 单 form」会踩坑：

```lisp
;; 单个 (values ...) form：宏只取它的主值，b、c 丢失
(multiple-value-list
 (sb-concurrency:frlock-read (*fr-lk*)
   (values *fr-a* *fr-b* *fr-c*))) ; => (1)
```

正确写法就是上面 `fr-foo` 那样：想读几个值就写几个 form。

## 38.5 sb-introspect：问 SBCL 要答案

调试器和 IDE 想知道的事——「这个函数在哪定义的」「谁调用了它」
「它的参数列表长什么样」——`sb-introspect` 把它们做成了可编程的
API（SLIME 的 `M-.` 跳转就靠它）。

```lisp
(require :sb-introspect)

(defun square38 (x &optional (scale 1)) (* x x scale))
(compile 'square38)

(sb-introspect:function-lambda-list #'square38) ; => (X &OPTIONAL (SCALE 1))
(sb-introspect:function-lambda-list #'car)      ; => (LIST)
```

`function-lambda-list` 返回函数原始的 lambda list（含默认值），
比 ANSI 的通用方案直接得多。（旧名 `function-arglist` 已废弃，
见手册 18.7 的弃用清单——「函数有的是 lambda list，不是 arglist」。)

定义位置返回 `definition-source` 结构体，能取出文件、表单序号、
字符偏移：

```lisp
(let ((src (sb-introspect:find-definition-source #'square38)))
  (type-of src)) ; => SB-INTROSPECT:DEFINITION-SOURCE
```

最常用的横向查询是 `who-calls` 一族（`who-calls`、`who-binds`、
`who-references`、`who-sets`），数据来自编译器记录的交叉引用，
返回 `(定义名 . definition-source)` 的 alist。**注意要先 compile**
——解释定义的函数不产生交叉引用数据：

```lisp
(defun area38 (r) (* pi r r))
(defun describe38 (r) (area38 r))
(compile 'area38)
(compile 'describe38)

(and (member 'describe38 (sb-introspect:who-calls 'area38) :key #'car) t) ; => T
```

## 38.6 sb-posix：系统调用接口

`sb-posix` 是 POSIX 系统调用的 Lisp 封装。它和内部包 `sb-unix`
的关系要说清：`sb-unix` 是 SBCL 自己用的内部实现（手册明确说
不供用户代码使用，还在慢慢去 Unix 化），**用户程序应该用
`sb-posix`**。命名规则很机械：C 接口名去掉下划线，如 `getcwd`
对应 `sb-posix:getcwd`，`O_RDONLY` 对应常量 `sb-posix:o-rdonly`。

设计上的两个统一约定：

- **字符串 designator**：凡是 C 里收 `char*` 路径的参数，Lisp 侧
  都收「字符串 designator」——字符串、符号、路径名都行。
- **错误走 condition**：C 里返回 -1 置 `errno` 的失败，这里抛
  `sb-posix:syscall-error`，`syscall-errno` 取出 errno 数值。

```lisp
(require :sb-posix)

(stringp (sb-posix:getcwd))          ; => T
(integerp (sb-posix:getpid))         ; => T

;; 目录操作全家桶：mkdir/symlink/readlink/unlink/rmdir
(ignore-errors (sb-posix:rmdir "/tmp/ex38-dir"))   ; 幂等：先清场
(sb-posix:mkdir "/tmp/ex38-dir" #o755)
(and (probe-file "/tmp/ex38-dir") t) ; => T
(sb-posix:symlink "/tmp/ex38-dir" "/tmp/ex38-link")
(sb-posix:readlink "/tmp/ex38-link") ; => "/tmp/ex38-dir"
(sb-posix:unlink "/tmp/ex38-link")
(sb-posix:rmdir "/tmp/ex38-dir")
(null (probe-file "/tmp/ex38-dir"))  ; => T
```

`stat` 返回一个 CLOS 对象，访问器是 `stat-mode`、`stat-size`、
`stat-mtime` 等；`s-isdir` 一族谓词判定文件类型：

```lisp
(let ((st (sb-posix:stat "/tmp")))
  (list (typep st 'sb-posix:stat)
        (and (sb-posix:s-isdir (sb-posix:stat-mode st)) t))) ; => (T T)
```

错误处理演示——打开不存在的文件，`errno` 2 即 `ENOENT`：

```lisp
(handler-case (sb-posix:open "/definitely/not/here" sb-posix:o-rdonly)
  (sb-posix:syscall-error (e) (sb-posix:syscall-errno e))) ; => 2
```

`read`/`write` 这一对和 C 一样操作**原始内存**，缓冲区参数要求
SAP（system area pointer）而不是 Lisp 向量——正好和第 25 章的 FFI
知识接上：用 `sb-alien:with-alien` 分配 alien 内存，
`sb-alien:alien-sap` 取指针，`sb-alien:deref` 按索引读写：

```lisp
;; 写：alien 缓冲区 -> fd
(let ((fd (sb-posix:open "/tmp/ex38-io.bin"
                         (logior sb-posix:o-wronly sb-posix:o-creat sb-posix:o-trunc)
                         #o644)))
  (prog1
      (sb-alien:with-alien ((buf (sb-alien:array sb-alien:unsigned-char 5)))
        (dotimes (i 5) (setf (sb-alien:deref buf i) (char-code (char "hello" i))))
        (sb-posix:write fd (sb-alien:alien-sap buf) 5))
    (sb-posix:close fd)))      ; => 5

;; 读：fd -> alien 缓冲区 -> Lisp 字符串
(let ((fd (sb-posix:open "/tmp/ex38-io.bin" sb-posix:o-rdonly)))
  (prog1
      (sb-alien:with-alien ((buf (sb-alien:array sb-alien:unsigned-char 5)))
        (let ((n (sb-posix:read fd (sb-alien:alien-sap buf) 5)))
          (list n (map 'string (lambda (i) (code-char (sb-alien:deref buf i)))
                       '(0 1 2 3 4)))))
    (sb-posix:close fd)
    (delete-file "/tmp/ex38-io.bin"))) ; => (5 "hello")
```

注意 alien 类型名是 `unsigned-char`（C 的命名习惯），不是 CL 的
`unsigned-byte`。要是只处理文本，其实没必要走到这一层——第 36 章
的流 I/O 更舒服；`read`/`write` 的价值在于无缓冲、定长二进制的
场景（设备文件、定界记录）。

## 38.7 sb-cltl2：编译期环境查询

`sb-cltl2` 实现《Common Lisp the Language, 2nd Edition》提议的
环境查询 API（ANSI 没收编，SBCL 以 contrib 提供）。三个查询函数
回答「这个名字在当前环境里是什么」：

```lisp
(require :sb-cltl2)

(defvar *answer38* 42)

(multiple-value-list (sb-cltl2:variable-information '*answer38*)) ; => (:SPECIAL NIL NIL)
(multiple-value-list (sb-cltl2:variable-information 'pi))         ; => (:CONSTANT NIL NIL)
(sb-cltl2:function-information 'car)   ; => :FUNCTION
(cadr (assoc 'speed (sb-cltl2:declaration-information 'optimize))) ; => 1
```

`variable-information` 的三个值：种类（`:special`/`:lexical`/
`:global`/`:constant`/`:symbol-macro`）、是否局部绑定、声明 alist。
它的真实用途在**宏展开器**里：宏拿到 `&environment` 对象后传给
这些函数，就能区分「这个符号在展开点是词法变量还是 special」——
第 35 章讲 `synchronize-*` 系列时见过同类需求。它也参与弃用体系：
手册第 18 章的弃用状态（`:early`/`:late`/`:final`）就是通过
`variable-information`/`function-information` 的声明槽暴露的。

## 38.8 sb-cover：表达式级测试覆盖率

`sb-cover` 回答「测试到底跑到了哪些代码」。模型很轻：**编译时
插桩 + 运行 + 生成 HTML 报告**三步。关键前提：必须以
`sb-cover:store-coverage-data` 优化质量为 3 编译，而且要走
`compile-file`（只认编译文件，解释执行不插桩）：

```lisp
(require :sb-cover)

;; 1. 造一个带覆盖率插桩声明的源文件
(ensure-directories-exist "/tmp/ex38-cover/")
(with-open-file (s "/tmp/ex38-cover-src.lisp" :direction :output
                   :if-exists :supersede)
  (write-string "(declaim (optimize (sb-cover:store-coverage-data 3)))
(defun cover-fn (x) (if (plusp x) :pos :neg))
" s))

;; 2. 清旧数据，compile-file + load（插桩随编译产物进来）
(sb-cover:clear-coverage)
(compile-file "/tmp/ex38-cover-src.lisp" :verbose nil :print nil)
(load "/tmp/ex38-cover-src.fasl" :verbose nil)

;; 3. 跑测试负载
(cover-fn 1)  ; => :POS
(cover-fn -1) ; => :NEG

;; 4. 生成报告：目录下得到 cover-index.html 和每个源文件一个着色页面
(sb-cover:report "/tmp/ex38-cover/")
(and (probe-file "/tmp/ex38-cover/cover-index.html") t) ; => T

;; 5. reset-coverage 清零计数（代码保留），clear-coverage 连插桩一起撤
(sb-cover:reset-coverage)
(sb-cover:clear-coverage)
```

打开 `cover-index.html` 是全部源文件的覆盖率汇总；点开单个文件的
页面能看到**逐表达式着色**的源码：跑过的、没跑过的、部分分支没
覆盖的各是一种颜色。上面特意两个分支都调了；只调 `(cover-fn 1)`
的话，`:neg` 那个分支就会以「未执行」的颜色标出来——这正是覆盖率
工具的用途：让「测试没测到」肉眼可见。`reset-coverage` 与
`clear-coverage` 的区别：前者把计数清零但保留插桩（接着跑接着
累加），后者把插桩信息整个忘掉（函数重新编译前不再收集）。

## 38.9 sb-simd：CPU 向量指令

`sb-simd` 把 SIMD（单指令多数据）暴露成 Lisp 函数：一条指令同时
对一包（pack）数据做同一运算。型号命名 `x.y` = 元素类型 x、一包
y 个元素，如 `f32.4` 是「4 个 single-float 的 128 位包」。**每个
指令集一个包**：`sb-simd-sse`、`sb-simd-sse2`……`sb-simd-avx2`、
`sb-simd-fma`；x86-64 保证有 SSE2，更新的指令集按 CPU 支持出现。
同一名称的函数按「该指令集能支持」分布到对应包里，比如构造器
`make-f32.4` 在 SSE 包就有，而条件选择 `f32.4-if` 要到 SSE4.1
（硬件那条 `blendv` 指令）才出现。

构造、运算、拆包：

```lisp
(require :sb-simd)

(multiple-value-list
 (sb-simd-sse2:f32.4-values
  (sb-simd-sse2:f32.4+ (sb-simd-sse2:make-f32.4 1.0 2.0 3.0 4.0)
                       (sb-simd-sse2:make-f32.4 10.0 20.0 30.0 40.0)))) ; => (11.0 22.0 33.0 44.0)
```

所有运算函数对参数做**隐式类型转换**，标量会被广播成一整包——
`x` 加 5 直接写 `(f32.4+ x 5)`。实际代码里 pack 很少用构造器逐元素
拼，而是从特化数组整段装载/存储（`x.y-aref` / `(setf x.y-aref)`）：

```lisp
(let ((arr (make-array 4 :element-type 'single-float
                         :initial-contents '(1.0 2.0 3.0 4.0))))
  (setf (sb-simd-sse2:f32.4-aref arr 0)
        (sb-simd-sse2:f32.4+ (sb-simd-sse2:f32.4-aref arr 0) 1.0))  ; 标量 1.0 自动广播
  (coerce arr 'list)) ; => (2.0 3.0 4.0 5.0)
```

比较运算返回的不是布尔而是**掩码包**：对应位置全 1（真）或全 0
（假）的无符号整数。掩码喂给 `x.y-if` 做无分支选择——SIMD 没有
「每个元素各走各的 `if`」，只能两条路都算、按掩码挑：

```lisp
;; f32.4= 的掩码：相等的位置全 1（4294967295 = #xFFFFFFFF）
(multiple-value-list
 (sb-simd-sse2:u32.4-values
  (sb-simd-sse2:f32.4= (sb-simd-sse2:make-f32.4 1.0 2.0 3.0 4.0)
                       (sb-simd-sse2:make-f32.4 1.0 0.0 3.0 0.0)))) ; => (4294967295 0 4294967295 0)

;; f32.4-if：掩码为真取前者、为假取后者（SSE4.1 起）
(let* ((a (sb-simd-sse4.1:make-f32.4 1.0 2.0 3.0 4.0))
       (b (sb-simd-sse4.1:make-f32.4 10.0 20.0 30.0 40.0))
       (mask (sb-simd-sse4.1:f32.4> a 2.5)))
  (multiple-value-list
   (sb-simd-sse4.1:f32.4-values
    (sb-simd-sse4.1:f32.4-if mask a b)))) ; => (10.0 20.0 3.0 4.0)
```

每个 `x.y-op` 还有对应的标量版 `x-op`（只算一个元素），好处是
语义与 SIMD 版**逐位一致**，可以拿它当参照实现来测试向量化代码：

```lisp
(sb-simd-sse2:f32+ 1.5 2.5) ; => 4.0
```

两个工程上的注意点。其一，pack 在寄存器里存活的条件很苛刻：
编译器能静态确定类型、且不跨函数边界传递时才不装箱——实战靠
内联和「从特化数组装载、算完存回」保住性能，别把 pack 当普通
函数参数传来传去。其二，Lisp 是镜像系统：在 AVX2 机器上 dump 的
镜像可能拿到只有 SSE2 的机器上跑。`sb-simd` 为此提供
`sb-simd-internals:instruction-set-case` 宏——编译成跳转表，索引
在**镜像每次启动时**按当前 CPU 重算，一份镜像带多套实现。

## 38.10 其余模块速览

剩下这些一句话带过，用到时再查手册：

- **sb-aclrepl**——增强版 REPL（仿 Allegro 的风格，带 `:cd`、
  `:history` 这类快捷命令），交互用，启动文件里加载。
- **sb-queue**——老式无锁队列，功能已并入 **sb-concurrency**
  （38.4），新代码直接用后者。
- **sb-executable**——`sb-executable:make-executable` 把当前镜像
  落成带入口函数的独立可执行文件（`save-lisp-and-die` 的封装）。
- **sb-executable 之外的应用打包**需求一般直接调
  `sb-ext:save-lisp-and-die`（第 23 章讲过）。
- **sb-grovel**——FFI 常量/结构体提取器：生成一小段 C 程序跑出
  `sizeof`、枚举值，供 Lisp 侧精确绑定。写大型 C 库绑定时用。
- **sb-manual**——SBCL 手册自己的文档生成器（PAX 系），把 docstring
  汇总成手册。
- **sb-rt**——测试驱动器（`rt:do-tests` 那套），SBCL 自用回归
  框架；新项目通常选 FiveAM 等社区框架。
- **sb-simple-streams**——Gray 流之外的另一套流实现（承自
  Allegro 的 simple-streams 设计），高性能 I/O 场景可选。
- **sb-cltl2** 已在 38.7 讲过；**sb-bsd-sockets**（37 章）、
  **sb-sprof**（26 章）前文已深讲。
- **sb-capstone**、**sb-gmp**、**sb-mpfr**——这版手册尚未收录的
  新模块：capstone 是反汇编器绑定；gmp/mpfr 是 GNU 高精度整数/
  浮点库的加速接入。后两者 `require` 时会去找系统里的
  `libgmp`/`libmpfr` 动态库，找不到就退化成带警告的空壳——
  本机实测正是这种情况，所以用它们之前先确认系统库就位。

## 小结

- contrib 用 `(require :名字)` 加载；引用其符号的源码里 require
  必须出现在**读取该符号之前**（文件顶部顶层表单）。
- **sb-md5** 返回 16 字节向量，hex 要自己格式化；
  `md5sum-sequence` 只收 ub8 向量。
- **sb-rotate-byte** 一个函数补齐循环移位，bytespec 圈定位场、
  场外保留。
- **sb-concurrency** 无锁四件套：queue（空队出 NIL）、mailbox
  （可阻塞等待）、gate（开/关放行）、frlock（读不加锁校验重试，
  `frlock-read` 每个 value-form 只取主值）。
- **sb-introspect** 把「定义在哪、谁调用、参数列表」做成 API，
  交叉引用数据要先 compile。
- **sb-posix** 是用户代码的系统调用入口（`sb-unix` 是内部包别
  用）；错误抛 `syscall-error`；`read`/`write` 要 alien 缓冲区。
- **sb-cltl2** 查环境：变量/函数/声明信息，宏展开器的好帮手。
- **sb-cover** 表达式级覆盖率：`store-coverage-data` 3 +
  `compile-file`，跑完 `report` 出着色 HTML。
- **sb-simd** 每指令集一包，`x.y-aref` 从数组整段装载，比较出
  掩码、`x.y-if` 无分支选择，标量版 `x-op` 当参照实现。
