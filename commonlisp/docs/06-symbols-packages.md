# 06 · 符号与包：名字的身份与空间

> 配套示例：[`examples/06_symbols/`](../examples/06_symbols/main.lisp)（channel: both）

## 6.1 符号的三件事：名字、包、身份

一个符号（symbol）身上挂着三样东西，理解它们是理解包系统的前提：

1. **名字**（`symbol-name`，一个字符串）
2. **所属的包**（`symbol-package`）
3. **身份**（`eq` 比较——同名同包的符号是**同一个对象**）

```lisp
(symbol-package 'foo)          ; => #<PACKAGE "COMMON-LISP-USER">   （打印形态实现各异）
(package-name (symbol-package 'foo))   ; => "COMMON-LISP-USER"
(symbol-name 'foo)             ; => "FOO"      （03 章：读入器转大写）
(eq 'foo 'foo)                 ; => T
```

符号还挂着分开的两格「命名空间」加一个属性表：**变量值**（`symbol-value`）、
**函数值**（`symbol-function`）、**属性表**（`get`/`setf get`）。这就是 CL 里
变量和函数可以同名的原因：

```lisp
(defun scale-2x (x) (* 2 x))     ; 函数格
(defparameter scale-2x 5)        ; 变量格：同名，互不影响
(setf (get 'scale-2x 'unit) "倍")
```

关键字（keyword）是「住在 `KEYWORD` 包里、自己绑定到自己」的符号：

```lisp
:foo                       ; => :FOO      ← 自求值
(keywordp :foo)            ; => T
(symbol-value :foo)        ; => :FOO      ← 它的值就是它自己
(package-name (symbol-package :a))     ; => "KEYWORD"
```

所以关键字天生适合当「常量」与「枚举值」，不需要 `defconstant`。

## 6.2 intern：字符串变符号（有个大坑）

`intern` 把字符串变成符号，并保证「同名同包只有一个符号」：

```lisp
(intern "FOO")                        ; => FOO
(eq (intern "FOO") 'foo)              ; => T
(multiple-value-list (intern "BRAND-NEW-SYM"))   ; => (BRAND-NEW-SYM NIL)       ← 新建
(multiple-value-list (intern "BRAND-NEW-SYM"))   ; => (BRAND-NEW-SYM :INTERNAL) ← 已有
```

**坑在这里**：`(intern "foo")` 用的是**小写名字**，而 `'foo` 读入后名字是大写：

```lisp
(intern "foo")            ; => |foo|      ← 名字真的是 "foo"
(eq (intern "foo") 'foo)  ; => NIL        ← 不是同一个符号！
```

**从字符串构造符号时用 `string-upcase` 包一下**，除非你确实要大小写敏感的名字。
读取器就是这么干的：`(read-from-string "hello")` → `HELLO`。

不进符号表的临时符号用 `make-symbol`：

```lisp
(make-symbol "FOO")                    ; => #:FOO     ← #: 前缀表示「无归属」
(eq (make-symbol "FOO") (make-symbol "FOO"))   ; => NIL
(symbol-package (make-symbol "FOO"))   ; => NIL
```

`#:` 符号打印出来再读回去会变成另一个新符号——这正是 `gensym` 需要的性质（15 章）。
gensym 的编号随会话变化（`SBCL` 与 `CLISP` 编号不同），**永远别把 gensym 名字
打进输出**——要展示的是「两个 gensym 互不相等」这个事实。

## 6.3 包是什么

包是**符号名到符号的映射表**。同一时刻有一个「当前包」`*package*`：

```lisp
(package-name *package*)          ; => "COMMON-LISP-USER"
(find-package :cl)                ; => #<PACKAGE "COMMON-LISP">   （打印形态随实现）
(package-nicknames (find-package :cl))       ; => ("CL")
(let ((n 0)) (do-external-symbols (s :cl) (incf n)) n)   ; => 978   ← ANSI 标准库的规模
```

`COMMON-LISP` 包对外公开 978 个符号——这基本就是标准库的规模（ANSI 面，01 章）。

查找符号用 `find-symbol`，返回**两个值**：符号 + 状态：

```lisp
(multiple-value-list (find-symbol "CAR" :cl))     ; => (CAR :EXTERNAL)
(multiple-value-list (find-symbol "NOPE" :cl))    ; => (NIL NIL)
```

状态四种：`:internal`（本包私有）、`:external`（已导出）、`:inherited`（继承来）、
`NIL`（不存在）。**符号的名字只有在「哪个包」确定之后才有意义**——
这就是 `A::B` 记法的由来；两个包里各有一个 `NAME`，互不相等（示例 06 实测）。

## 6.4 单冒号与双冒号

| 记法 | 含义 | 用法 |
|---|---|---|
| `pkg:sym` | **导出的**符号 | 正常用法 |
| `pkg::sym` | **内部**符号 | 应急/调试，不推荐 |

关键事实（很多人不知道）：**单冒号访问未导出符号，在读取期就报错**——
连 `handler-case` 都接不住，因为错误发生在 read：

```
;; 在 CL-USER 里读 geometry:internal-helper（未导出）：
;; SBCL  → The symbol INTERNAL-HELPER is not external in package GEOMETRY
;; CLISP → similarly an error at read time
```

所以「包内私有」是真私有（读取层面），双冒号 `geometry::internal-helper` 能捅进去
但只用于调试。

## 6.5 定义自己的包

```lisp
(defpackage :shop
  (:use :cl)
  (:nicknames :shop-pkg)
  (:export #:item #:item-name #:make-item))

(in-package :shop)
(defstruct item name price)
(defun item-label (it) (format nil "~A（~A 元）" (item-name it) (item-price it)))
(export 'item-label)
(in-package :cl-user)

(shop:item-label (shop:make-item :name "书" :price 30))    ; => "书（30 元）"
(shop-pkg:make-item)                       ; => #S(SHOP:ITEM :NAME NIL :PRICE NIL)
```

`defpackage` 常用选项：

| 选项 | 作用 |
|---|---|
| `:use :cl` | 继承标准库的所有外部符号 |
| `:export #:a` | 导出符号（用 `#:` 写，避免把符号先 intern 到当前包） |
| `:nicknames` | 别名 |
| `:shadow` | 屏蔽继承来的同名符号 |
| `:import-from` | 从别的包引入特定符号 |
| `:documentation` | 包文档字符串 |

**`use-package` 之后可以直接用短名**（示例 06 演示了 `(:use :cl :geometry)`）；
文件里 `in-package` 切换后记得切回来（或把文件顶部固定为「defpackage + in-package」
的标准开头）。

## 6.6 包锁：CL 的符号不许乱改

```lisp
(defun car (x) x)
```

```
WARNING: redefining COMMON-LISP:CAR in DEFUN
Lock on package COMMON-LISP violated ...
```

**这是好事**：包锁防止你把 `car` 改掉后整个程序行为诡异。**⚠️ 双实现差异（实测）**：

- SBCL 的锁很严——连 `(flet ((1+ ...)))` 这种「局部遮蔽 CL 名字」都拦；
- CLISP 默认不锁 `COMMON-LISP` 包（重定义只发 WARNING 不报错）。

结论一致：**跨实现代码别碰 CL 包的名字**——要同名就开自己的包并 `shadow`：

```lisp
(defpackage :demo-shadow
  (:use :cl)
  (:shadow :list))
;; demo-shadow 里的 list 指向新符号，与 CL:LIST 无关
```

诊断工具 `apropos` 按关键词找符号（忘了函数名时非常顺手）：

```lisp
(subseq (apropos-list "hash-table" :cl) 0 3)
; => (HASH-TABLE HASH-TABLE-COUNT HASH-TABLE-P)   ← 顺序随实现，别依赖
```

## 6.7 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `Package FOO does not exist` | 读取了 `foo:bar` 但包不存在 | 先 `defpackage`/`require`，或 `#+` 分发（02 章） |
| 重定义 `car` 报包锁错误 | `COMMON-LISP` 被锁（SBCL 严、CLISP 松） | 换名字，或自己包里 `shadow` |
| `(intern "foo")` 与 `'foo` 不相等 | 读入器转大写 | `(intern (string-upcase s))` |
| 单冒号访问内部符号直接崩 | 错误在**读取期**，handler-case 接不住 | 要么 `:export`，要么调试用 `::` |
| 用了 `pkg::sym` 换机器就崩 | 依赖了别人的内部符号 | 只用导出符号 |
| `CLISP` 加载报「Adding method to already called generic function」 | 给已调用过的泛型追加方法（19 章） | 方法定义放在第一次调用之前 |
| 打印符号带了实现私有包前缀 | 条件类名如 `SB-INT:SIMPLE-PARSE-ERROR` vs `SYSTEM::SIMPLE-PARSE-ERROR` | 打 `(symbol-name ...)`（18 章） |
