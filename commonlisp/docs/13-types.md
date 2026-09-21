# 13 · 类型系统与声明

> 配套示例：[`examples/13_types/`](../examples/13_types/main.lisp)（channel: both）

CL 是动态类型语言，但它的类型系统**比多数静态语言的表达力还强**：
类型是运行期的一等对象（可以 `typep`、可以当参数传），说明符可以组合、
可以自定义，还能向编译器做**承诺**换性能（26 章）。

## 13.1 typep / subtypep：类型是活的

```lisp
(typep 42 'integer)                ; => T
(typep 3.14 'float)                ; => T
(typep "ab" 'string)               ; => T
(subtypep 'fixnum 'integer)        ; => T      ← 两值：是否子类型 + 是否可判定
(subtypep 'integer 'number)        ; => T
(nth-value 0 (subtypep 'string 'number))     ; => NIL
```

## 13.2 数值塔的层级

```lisp
integer ⊂ rational ⊂ real ⊂ number     （float 与 rational 并列在 real 下）
(typep 1/3 'rational)    ; => T     （有理数也是 real）
(typep 1/3 'real)        ; => T
(typep #c(1 2) 'number)  ; => T
(typep #c(1 2) 'real)    ; => NIL   （复数不是实数）
```

fixnum/bignum 的分界是**实现自由**（SBCL 62 位 / CLISP 48 位，01 章实测），
但「小整数是 fixnum、超界自动升 bignum」跨实现成立：

```lisp
(typep 100 'fixnum)                    ; => T
(typep (expt 2 100) 'bignum)           ; => T
```

## 13.3 类型说明符的四种写法

```lisp
(typep 5 'integer)                              ; ① 名字
(typep :north '(member :north :south))          ; ② 成员列表
(typep 3 '(integer 1 10))                       ; ③ 区间（(1) 表示开区间下界）
(typep 4 '(satisfies evenp))                    ; ④ 满足谓词
(typep 42 '(and (integer 1 100) (satisfies evenp)))   ; 组合：and/or/not
(typep 0 '(not null))                           ; => T
```

区间写法细节：`(integer 1 10)` 闭区间；`(integer (1) 10)` 下界开；
`(integer 1 *)` 上界无限。

**坑**：`(list integer)` 这种「带元素类型的 list」**不是**合法类型说明符——
`vector`/`array` 可以带元素类型，`list` 不行（SBCL 与 CLISP 都报
`bad thing to be a type specifier`）。想要「元素类型受限的表」用 satisfies
谓词（示例 13 的 `list-of-integer`）。

## 13.4 deftype：自定义类型说明符

`deftype` 像 defmacro 一样**展开成类型说明符**，还能带参数：

```lisp
(deftype int-at-least (n)
  "不小于 N 的整数。"
  `(and integer (integer ,n)))

(typep 5 '(int-at-least 3))    ; => T
(typep 2 '(int-at-least 3))    ; => NIL
```

## 13.5 三道防线：check-type / assert / ecase

```lisp
(check-type x integer)               ; 不满足就地报 type-error（可修正）
(assert (= 1 2) () "说明文字")         ; 断言失败报错
(ecase key (分支…))                   ; 无匹配报错（12 章）
```

`check-type` 的错误带期望类型（`type-error-expected-type` 可取），
配合 handler-case 就能接住并转译（18 章）。注意**编译期推导**：
SBCL 能在编译期看出 `(let ((x "s")) (check-type x integer))` 必然失败，
警告直接进 stderr——想让检查留到运行期，把值藏进函数参数（示例 13 的写法）。

## 13.6 the 与 declare：给编译器的承诺

```lisp
(defun fast-double (x)
  (declare (type integer x))     ; 承诺参数类型
  (the integer (* x 2)))          ; 承诺返回类型
```

`the` **不做任何检查**——只是承诺；承诺错了是未定义行为（SBCL 高速档下
可能直接算错）。与 check-type 的对照：**check-type 是检查（错了报错），
the 是承诺（错了自担）**。声明的性能收益在 SBCL 上是真实的（26 章实测），
CLISP 主要解释执行、收益有限——性能代码看实现（22/26 章）。

## 13.7 type-of：认得，别用

`type-of` 返回「能唯一确定该值的最窄类型」，但**形态是实现自由**：

```lisp
(type-of "ab")
;; SBCL  => (SIMPLE-ARRAY CHARACTER (2))
;; CLISP => (SIMPLE-BASE-STRING 2)
```

做类型判断用 `typep`；`typep` 对类（CLOS）一样工作（19 章）。
`coerce` 负责类型间换形态（08 章序列、05 章字符串）。

## 13.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `bad thing to be a type specifier: (LIST X)` | list 不接受元素类型参数 | satisfies 谓词 / 换 vector |
| check-type 的警告打爆 stderr | SBCL 编译期类型推导成功 | 把值藏进函数参数 |
| `(the fixnum …)` 结果悄悄错了 | the 是承诺不是检查 | safety 高档下才检查（26 章） |
| 两实现 type-of 输出不同 | 形态是实现自由 | 判断用 typep |
| satisfies 的谓词写了 lambda | satisfies 只接受符号 | defun 一个具名谓词 |
