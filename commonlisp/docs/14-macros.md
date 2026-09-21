# 14 · 宏 I：定义、反引号、展开

> 配套示例：[`examples/14_macros/`](../examples/14_macros/main.lisp)（channel: both）

宏是 CL 区别于「函数式语言 + 语法糖」的关键。核心事实只有一条：

> **宏在「展开期」运行，收到的是未求值的代码；函数在「运行期」运行，收到的是值。**

## 14.1 先把这条事实实测一遍

```lisp
(defmacro noisy (form)
  (format t "  [宏展开时] 我看到的实参是 ~S~%" form)
  `(list :运行时求值 ,form))
```

调用 `(noisy (+ 1 2))`：展开时打印「我看到的实参是 (+ 1 2)」——**表达式**；
换成函数，收到的是 `3`——**值**。所以宏能做函数做不到的事：
定义新语法、控制求值次数与时机、把计算搬到编译期。

示例 14 的 `show-expr` 是最小可复用版本：同时打印表达式本身和它的值——
函数永远做不到（实参早就被求值了）。

## 14.2 反引号模板

写宏 90% 的代码长这样：

| 记法 | 名字 | 作用 |
|---|---|---|
| `` ` `` | backquote | 模板，里面的东西默认当数据 |
| `,` | comma | 求值后插进去 |
| `,@` | comma-at | 求值后摊平（必须是列表） |

```lisp
`(1 2 3)                        ; => (1 2 3)
(let ((x 2)) `(1 ,x 3))         ; => (1 2 3)
(let ((l '(a b))) `(1 ,@l 3))   ; => (1 A B 3)
```

`,@` 的等价展开是 `append`（示例 14 并排打印了模板结果和手工 append 的结果）。
**注意 `,` 求值发生在宏展开期**——插进去的到底是「代码」还是「值」，
取决于你在哪一层写。

## 14.3 macroexpand：把宏看穿

```lisp
(defmacro my-when (condition &body body)
  `(if ,condition (progn ,@body) nil))

(macroexpand-1 '(my-when (> 3 2) (print :a) (print :b)))
; => (IF (> 3 2) (PROGN (PRINT :A) (PRINT :B)))
(macroexpand '(my-when t (my-when t 42)))    ; 一路展到不再是宏
; => (IF T (PROGN (IF T (PROGN 42) NIL)) NIL)
```

- `macroexpand-1` 只展开一层；`macroexpand` 展到不是宏为止；
- 不是宏的形式原样返回：`(macroexpand '(car x))` ; => `(CAR X)`；
- 判断名字是不是宏：`(macro-function 'my-when)` 非 NIL。

**⚠️ 排版与可移植性**：REPL 里 SBCL 的 `*print-pretty*` 默认 T，展开结果会折行；
打印跨实现一致的「代码」前显式绑 `*print-pretty*` 为 nil（03 章）。
另外**内置宏的展开形态是实现自由**（SBCL 的 when 与 CLISP 的不同）——
调试看展开没问题，程序逻辑别依赖（22 章军规）。

## 14.4 宏 vs 函数：什么时候必须用宏

判断标准（15 章末尾还有完整清单）：

- 需要**位置**（`setf` 的目标）：`(inc x)` 原地自增——函数拿不到「x 这个位置」；
- 需要**不求值**：短路 `and`/`or`、条件 `when`；
- 需要**新语法**：`loop`、`with-open-file`；
- 需要**编译期计算**：见 14.6。

反过来的信号：参数的求值次数和时机无所谓 → 函数。

## 14.5 &body 与参数解构

`&body` = `&rest` 的别名，但明确表示「这是代码体」，编辑器缩进会配合。
宏形参可以像 `destructuring-bind` 一样**解构形状**：

```lisp
(defmacro with-point ((x y) pair &body body)
  `(let ((,x (car ,pair))
         (,y (cdr ,pair)))
     ,@body))
(with-point (head tail) '(1 2 3)
  (list head tail))                  ; => (1 (2 3))
```

进阶 lambda-list 关键字：`&whole`（整个调用形式，含宏名）、
`&environment`（编译环境，配 `constantp` 做编译期判断——
注意 `constantp` 对 `(+ 1 2)` 也返回 T，它判断「编译期常量形式」而非字面量）。

## 14.6 实用宏五连（示例 14 全部可跑）

1. **repeat**——新控制结构（gensym 防撞名，下一章）；
2. **aif**（anaphoric if）——把测试结果暴露成 `it`，宏独有的玩法：
   ```lisp
   (aif (find 3 '(1 2 3)) (format t "找到 ~A" it) ...)
   ```
   （代价是「隐变量」，社区对它爱恨分明；用在小范围 DSL 里合适。）
3. **lazy / force**——延迟求值：`(lazy expr)` 展开成 `(lambda () expr)`；
4. **def-checker**——生成代码的宏：一次定义一批函数；
5. **迷你 HTML DSL**——`(:title "宏教程")` 直接变成 format 调用。

**编译期计算**是宏的独门绝活——展开期干的活不占运行时间：

```lisp
(defmacro sum-1-to-100 ()
  (let ((result (loop for i from 1 to 100 sum i)))
    `',result))
(sum-1-to-100)     ; => 5050   ← 5050 在编译期就算好，运行期是个常量
```

## 14.7 宏不能当函数用

```lisp
(apply #'my-when '(t :x))     ; 编译期报错：
;; The macro MY-WHEN was found as the argument to FUNCTION.
```

宏**不是值**，不能 `funcall`/`apply`/当高阶函数参数。需要「能传的语法」用
`macrolet` 定义局部宏：`(macrolet ((m (x) `(* ,x 2))) (m 3))` ; => 6。
要传的逻辑就写函数——宏只做一层薄包装。

## 14.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 展开结果折行/两实现不同 | SBCL pretty 默认开；内置宏形态实现自由 | 打印前绑 `*print-pretty*` nil；别依赖内置宏展开 |
| `(apply #'宏 ...)` 编译报错 | 宏不是函数 | 逻辑进函数，宏做包装 |
| 宏体里 gensym 调了两次 | 每次调用都给新符号 | 一次生成、存进 let 变量 |
| `eval-when` 没按预期执行 | `--load` 不触发 `:compile-toplevel` | `(:compile-toplevel :load-toplevel :execute)` 三态全开 |
| 展开 `#:G123` 出现在输出里 | gensym 编号随会话/实现变 | 别打印 gensym 名（示例 06 的规矩） |
