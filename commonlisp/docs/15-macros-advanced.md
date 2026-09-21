# 15 · 宏 II：卫生、捕获与宏工程

> 配套示例：[`examples/15_macros_adv/`](../examples/15_macros_adv/main.lisp)（channel: both）

## 15.1 变量捕获：现场复现

反面教材（示例 15 完整复现）：

```lisp
(defmacro bad-swap (a b)
  `(let ((temp ,a))
     (setf ,a ,b)
     (setf ,b temp)))
```

展开 `(bad-swap tmp x)`——用户变量恰好叫 `tmp`，被宏的 `let` **捕获**：

```lisp
(macroexpand-1 '(bad-swap tmp x))
; => (LET ((TMP TMP))        ← 用户传进来的 tmp 被这里绑死了！
;      (SETF TMP X)
;      (SETF X TMP))
(let ((tmp 1) (x 2)) (bad-swap tmp x) (list tmp x))
; => (1 2)     ← 期望 (2 1)：交换悄悄变成了「读 A 写 A」的乌龙
```

**这种 bug 特别阴险**：换个不撞名的变量就「正常」，测试用例一换名字就翻车。

## 15.2 gensym 修法

```lisp
(defmacro good-swap (a b)
  (let ((tmp (gensym "SWAP-")))       ; 关键：宏体里一次算出来，再插进去
    `(let ((,tmp ,a))
       (setf ,a ,b)
       (setf ,b ,tmp))))
(let ((temp 1) (val 2)) (good-swap temp val))     ; 真正交换
```

展开里出现 `#:SWAP-123` 这种**无归属符号**——它在任何包里都没 intern 过，
用户代码里永远不会出现与它同名的符号（06 章 make-symbol 的性质）。

三个相关事实：

```lisp
(gensym)                    ; => #:G264   ← 编号每次运行都不同（别打印它做输出比对）
(gensym "TMP")              ; => #:TMP269
(symbol-package (gensym))   ; => NIL      ← 无归属
```

**宏体里 `(gensym)` 只能调一次存进变量**——写两次得到两个不同符号，宏就错了。

## 15.3 with-gensyms：把卫生写法模板化

每个宏都手写 `(let ((g (gensym))) ...)` 太啰嗦——把它做成宏（宏写宏）：

```lisp
(defmacro my-with-gensyms (names &body body)
  `(let ,(mapcar (lambda (n) `(,n (gensym ,(string n)))) names)
     ,@body))

(defmacro silent-swap (a b)
  (my-with-gensyms (tmp)
    `(let ((,tmp ,a)) (setf ,a ,b) (setf ,b ,tmp))))
```

**⚠️ 实现差异（实测）**：CLISP 的 `EXT` 包自带 `with-gensyms`（pprint 模块），
重定义它会发 WARNING 到 stderr——所以示例里改名叫 `my-with-gensyms`；
实际项目直接用 `alexandria:with-gensyms`（21 章 Quicklisp 一键装）。

## 15.4 once-only：用户表达式别偷偷算两遍

另一个经典坑——宏把用户给的表达式**展开成两份**，副作用就跑两遍：

```lisp
(defmacro bad-twice (expr) `(list ,expr ,expr))
(let ((n 0))
  (bad-twice (progn (incf n) n)))     ; => (1 2)   ← 副作用跑了两次！
```

once-only 的手工实现：先求值一次存进 gensym，再引用 gensym：

```lisp
(defmacro once-only-twice (expr)
  (my-with-gensyms (val)
    `(let ((,val ,expr))
       (list ,val ,val))))
(let ((n 0)) (once-only-twice (progn (incf n) n)))     ; => (1 1)   ← 只算一次
```

完整版 `once-only`（alexandria 里有）处理「用户符号也要保持 hygiene」的
一般情形——原理相同，多绕一层展开。

## 15.5 符号宏

`symbol-macrolet` 让一个**名字**在词法范围内展开成表达式——它看起来是变量，
每次出现都被替换：

```lisp
(let ((table (make-hash-table)))
  (setf (gethash :hits table) 0)
  (symbol-macrolet ((hits (gethash :hits table)))
    (incf hits)          ; 展开成 (incf (gethash :hits table))
    (incf hits)
    hits))               ; => 2
```

它替换的是「名字的位置」——不能对非位置的符号宏 setf；
`define-symbol-macro` 定义全局版。CLOS 的 `with-slots`（19 章）
就是拿它实现的。

## 15.6 eval-when：三态开关

顶层形式默认在「编译/加载」时生效；`eval-when` 精确控制三个阶段：

```lisp
(eval-when (:execute) ...)                         ; 只在直接执行时跑
(eval-when (:compile-toplevel :load-toplevel :execute) ...)   ; 三态全开 = 普通 defun
```

经典用途：**同一个文件里「先定义宏、后面就用」**在 `compile-file` 时会翻车——
宏定义要配 `:compile-toplevel` 才在编译期可见（示例 15 用三态全开演示）。
`--load` 加载源文件不走「编译该文件」这个阶段，`:compile-toplevel` 单独
使用时的行为容易违反直觉——拿不准就三态全开。

## 15.7 调试宏与「什么时候不要写宏」

调试三板斧：

1. `(macroexpand-1 '你的调用)` 看展开对不对（SLIME/sly 里光标上 TAB 即可）；
2. `compile-file` 静态兜底：括号错位、shape 错配当场报出来；
3. 展开正确再查运行期——问题就一定不在宏本身。

不要写宏的场景（宁函数勿宏）：

- 参数本来就该求值（函数语义就够）；
- 只想「少打几个字」——普通函数/局部函数更好；
- **运行期才拿得到「要生成什么代码」**——宏是编译期的，这时用闭包；
- 需要当一等公民传来传去——宏不能 funcall（14 章）。

## 15.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 宏换了个变量名就翻车 | 变量捕获 | gensym / with-gensyms |
| 用户表达式副作用跑了两次 | 展开成两份 | once-only 模式 |
| CLISP 加载告警 `with-gensyms` 重定义 | EXT 包里自带同名宏 | 改名或用 alexandria |
| `setf` 符号宏报「not a symbol」 | 替换结果是表达式不是位置 | 用可 setf 的位置（gethash 等） |
| 编译期「宏未定义」 | 宏定义没到 :compile-toplevel | eval-when 三态全开 |
