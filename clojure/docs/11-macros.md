# 11 · 宏与元编程 ⭐

> 对应示例：`examples/09_macros.clj`

> Lisp 的终极武器：代码是数据（homoiconicity），所以**写生成代码的代码**
> 和写普通函数一样自然。`when`、`->`、`or` 全是宏——Clojure 没有魔法语法，
> 只有别人替你写好的宏。

## 11.1 为什么需要宏

函数做不到的两件事，宏都能：

1. **控制求值时机**：`or` 的第二个参数在第一个为真时**根本不求值**；函数调用永远先求值所有参数。
2. **定义新绑定/语法形状**：`let`、`for`、`doseq` 的 `[x xs]` 形状不是函数参数能表达的。

```clojure
;; 这两行都合法，因为 when 是宏
(when false (println "never runs") (/ 1 0))     ; => nil，body 完全没求值
;; 如果 when 是函数：(/ 1 0) 先炸
```

**决策规则**：能用函数就别用宏（函数可组合、可当值传、好测试）；宏留给"必须操作代码结构"的场合。

## 11.2 quote 家族：代码即数据

```clojure
(+ 1 2)                 ; => 3          求值
(quote (+ 1 2))         ; => (+ 1 2)    不求值：列表本身
'(+ 1 2)                ; 同上（' 是 quote 的读取器简写）

(list '+ 1 2)           ; => (+ 1 2)    和 quote 结果相等的数据
```

`'` 停在"拿到形状"这一步。**syntax-quote `` ` ``** 则更进一步——符号带命名空间限定 + 允许反引用：

```clojure
`(+ 1 2)                ; => (clojure.core/+ 1 2)   符号被当前 ns 限定！
`(a b)                  ; => (my-ns/a my-ns/b)
`(~a b)                 ; unquote：a 回到"求值"世界
`(~@[1 2 3])            ; unquote-splicing：把 seq 拼进列表
`(~@[1 2] ~@[3])        ; => (1 2 3)
```

记忆：`` ` `` 开个"模板世界"的口子，`~` 钻回"运行时世界"，`~@` 钻回去还把列表摊平。

## 11.3 defmacro：第一个宏

```clojure
(defmacro unless
  "test 为假才执行 body。"
  [test & body]
  `(if (not ~test)
     (do ~@body)))            ; body 是多个表达式 → ~@ 摊开塞进 do

(macroexpand-1 '(unless (= 1 2) :a :b))
; => (if (not (= 1 2)) (do :a :b))

(unless (= 1 2) :a :b)        ; => :a
```

宏的参数**不求值直接到手**——你拿到的是 `(:a :b)` 这样的代码形状，加工后返回新代码，编译器接着编译你的返回值。`~@body` 把 body 摊平进 `do` 是最常用宏模板。

## 11.4 卫生与 gensym：`x#`

宏展开的代码如果引入 `let`，名字可能撞上调用方的变量：

```clojure
(defmacro twice [expr] `(let [x ~expr] (+ x x)))     ; 坏：撞名风险
(let [x 5] (twice (inc x)))                          ; 展开后 x 语义被劫持

(defmacro twice [expr] `(let [x# ~expr] (+ x# x#)))  ; 好：每次展开自动 gensym
```

`x#` 在**同一个 syntax-quote 里**是同一个唯一符号（`x__1234`），不同展开互不冲突。这是 Clojure 的"够用版卫生宏"——比 Scheme 的全卫生少点自动、多点直白。

## 11.5 实战级宏：my-or

Clojure 的 `or` 语义：返回第一个真值，短路。自己写一遍，三个技术点全上：

```clojure
(defmacro my-or
  ([] nil)
  ([x] x)
  ([x & rest]
   `(let [e# ~x]                     ; 1) 只求值一次（缓存到 gensym 局部）
      (if e# e# (my-or ~@rest)))))   ; 2) 短路：假才递归  3) 尾位置展开

(my-or nil false 3 (explode))        ; => 3   （explode 不会被调用）
```

**"只求值一次"**是宏的经典坑：直接写 `(if ~x ~x ...)` 会让 `x` 求值两次（副作用翻倍、开销翻倍）——`let`+gensym 缓存是标准解法。

## 11.6 调试宏：macroexpand

```clojure
(macroexpand '(when c a b))
; => (if c (do (a b)))

(macroexpand-1 '(when c a b))        ; 只展开一层
; => (if c (do a b))

(macroexpand '(-> 5 inc (- 3)))
; => 6 ？不 —— -> 展开是 (- (inc 5) 3)，macroexpand 只管宏：
; => (- (inc 5) 3)

(macroexpand-1 '(->> [1 2] (map inc)))
; => (map inc [1 2])
```

写宏的循环：`macroexpand-1` 看一层 → 改 → 再看。`macroexpand` 展到不再是宏为止（但不会展开普通函数调用）。**展开结果可以 `eval` 验证语义**：`(eval (macroexpand-1 '(unless false 42)))`。

## 11.7 内置宏都长什么样

打开 `clojure.core` 源码（REPL 里 `(source when)`）会发现核心"语法"全是宏：

```clojure
;; when = if + do
(defmacro when [test & body] `(if ~test (do ~@body)))

;; and 的真身（脱糖成嵌套 if —— 28 章解释器里我们手写过同款！）
(and a b c) ≡ (let [x a] (if x (let [y b] (if y c y)) x))
```

**理解宏 → 理解语言的边界**：Clojure 的"语法糖"没有特权，你的宏和 Hickey 的宏同等待遇。

## 11.8 坑位清单

1. **参数多次求值**：`~x` 出现两次 = 求值两次。副作用/昂贵计算参数必须 `let`+gensym 缓存（11.5）。
2. **忘记 `~@body` 的 body 是"多表达式"**：body 塞进 `(do ...)`，否则只有最后一个属于你的结构。
3. **gensym 忘记 `#`**：`` `(let [x_ ~x] ...) `` 手写 `gensym` 拼接也行，但 `x#` 自动且同一 syntax-quote 内一致——别用固定名。
4. **syntax-quote 的命名空间限定**：`` `(str x) `` 生成 `(clojure.string/str ...)`?? —— 不，`str` 限定为 `clojure.core/str` ✓；但你想引用**调用方命名空间**的符号时要用 `~'sym`（unquote-quote 保留裸符号）。
5. **宏不是函数**：不能 `map my-macro xs`——宏没有运行时身份。需要"值化"就包一层函数。
6. **编译期 vs 运行期混淆**：宏体在**编译时**跑，里面不能碰运行时数据——传给宏的只能是代码形状。
7. **递归宏要小心展开规模**：`my-or` 的递归展开是编译期展开，参数列表极长时展开树也极长（罕见但知道即可）。

---

上一章：[10 惰性序列](10-lazy-seqs.md) · 下一章：[12 多方法](12-multimethods.md)
