# 06 · 函数与闭包 ⭐

> 对应示例：`examples/04_functions.clj`

> Clojure 是 Lisp-1：函数就是值，和 42 没有身份区别。本章讲清
> 参数模型、匿名函数两种形态、闭包，以及"什么都能调用"（IFn）的
> 广义函数观。

## 6.1 defn 全解剖

```clojure
(defn power                     ; 名字
  "x 的 n 次幂。n 为负返回比值。"  ; 文档字符串（(doc power) 可查）
  {:added "1.0" :tag long}      ; 属性 map（可选，元数据）
  ([x] (power x 2))             ; arity 1：转发到 arity 2
  ([x n] (Math/pow x n)))       ; arity 2

(power 3)                       ; => 9.0
```

**多 arity（参数个数重载）**是 Clojure 的"方法重载"——惯用法是低 arity 转发到全量 arity（补默认值）。参数个数不同的调用分发到不同函数体，比可选参数/默认参数更直白。

### pre/post 条件：函数头的断言

```clojure
(defn div [a b]
  {:pre [(not= b 0)] :post [(number? %)]}   ; 前置/后置条件
  (/ a b))
(div 1 0)      ; AssertionError：b 不能是 0
```

轻量契约，测试之外的"开发期护栏"。`:post` 里 `%` 指返回值。

## 6.2 可变参数：& 收尾

```clojure
(defn summarize [title & items]        ; items 收集剩余实参为一个 seq
  {:title title :count (count items) :items items})

(summarize "t" :a :b)                  ; => {:title "t", :count 2, :items (:a :b)}

(defn max-all [& xs] (reduce (fnil max Long/MIN_VALUE) xs))  ; 实战模样
```

`:keys 风格键值尾参`也常见（08 章解构版）：

```clojure
(defn make-user [name & {:keys [email active] :or {active true}}]
  {:name name :email email :active active})
(make-user "a" :email "a@x.com")       ; => {:name "a", :email "a@x.com", :active true}
```

## 6.3 匿名函数：两种形态

```clojure
(fn [a b] (+ a b))          ; 完整形态：可命名、可多 arity、可写 doc
#(+ %1 %2)                  ; 读取器简写：%1 %2 … %& （% 是 %1 的别名）
#(str % "-suffix")          ; 单参数最短
```

`#()` 是 reader 宏，展开成 `(fn [...] ...)`。规则与限制：

- `%` / `%1` / `%2` / … `%&` 是参数占位符；**括号里能放任意表达式**。
- **不能嵌套**：`#(map #(+ % 1) %)` 语法错——内层 `#(` 会提前闭合。嵌套场景老实用 `fn`。
- 只适合"一行能写完"的函数；长了可读性崩塌，社区风格上限约 2-3 行。

```clojure
(map #(str "<" % ">") [:a :b])       ; => ("<a>" "<b>")
(reduce #(+ %1 %2) 0 [1 2 3])        ; => 6    %1=acc %2=元素（reduce 语境）
(sort-by #(:score %) users)          ; => 按字段排序的常用形状
```

## 6.4 闭包：函数带着环境跑

```clojure
(defn make-counter [start step]
  (let [n (atom start)]               ; n 被闭包捕获
    (fn [] (swap! n + step))))        ; 返回的函数引用 n —— 每个计数器一份独立 n

(def c1 (make-counter 0 1))
(def c2 (make-counter 100 10))
[(c1) (c1) (c2)]                      ; => (1 2 100)
```

闭包 = 函数 + 定义处的环境。两次 `make-counter` 造出**互不干扰**的环境——"对象"（封装状态 + 操作）在函数式语言里可以用闭包直接表达，不需要 class。

捕获的是**变量本身**（引用），不是值的快照：

```clojure
(defn make-adder []
  (let [x (atom 0)]
    [(fn [] @x)                        ; 读
     (fn [v] (reset! x v))]))          ; 写
```

不可变绑定 + 需要变化 → atom 是标准搭配（14 章）。

## 6.5 apply 与 partial

```clojure
(apply + [1 2 3 4])               ; => 10   把 seq 拆成参数喂进去
(apply + 1 2 [3 4])               ; => 10   前面可以还有固定参数
(apply max [3 1 4])               ; => 4    "对集合求 max" 的正解

(def add10 (partial + 10))        ; 固定左边参数
(add10 5)                         ; => 15
((partial conj #{}) :a)           ; => #{:a}
```

`apply` 是"seq → 参数列表"的桥，**可变参数函数 + 集合数据**的必经之路。`partial` 造"预填参数"的新函数——配合 09 章 `comp` 组成函数级乐高。

## 6.6 万物皆 IFn：调用的广义语义

```clojure
(:name {:name "A"})        ; 关键字是函数（map 取值）
({:a 1} :a)                ; map 是函数（键查值）
([10 20] 1)                ; vector 是函数（索引取值）
(:x #{:x :y})              ; set 是函数（成员测试）
('first [1 2])             ; 符号也是 IFn —— (get coll sym default)！
(ifn? :k)                  ; => true   "可调用吗"的检查
(fn? :k)                   ; => false  fn? 只认真正的函数
```

这解释了一个**静默坑**（28 章实战实录）：`('* 2 3)` 不抛错——Symbol 是 IFn，调用等价 `(get 2 * 3)`，返回默认值 3。`*` 该是函数时拿到符号，程序继续跑，只是算错。防御法：给高阶函数喂函数前 `(fn? f)` 断言，或用测试钉住行为。

`ifn?` vs `fn?`：前者"广义可调用"（含关键字/map/vector），后者"真函数"。API 收回调参数时用 `ifn?` 更宽容。

## 6.7 私有与递归定义

```clojure
(defn- helper [] ...)             ; 私有（等价 (def ^:private helper ...)）
(declare process-node)            ; 前置声明：互递归时先"占名"
(defn walk [t] (process-node t))
(defn process-node [x] (walk x))
```

## 6.8 坑位清单

1. **`#()` 不能嵌套**——内层换 `(fn [x] ...)`。
2. **`%` 在 reduce 里是 `%1`**：`#(+ % 10)` 给 reduce 用会当单参函数用错位——reduce 回调是二元（acc, x），写 `#(+ %1 10)` 也错（丢了 x）——老实用 `(fn [acc x] ...)`。
3. **map 当函数只支持单键**：`({:a 1} :a :b)` 是"取 :a，找不到返回 :b"，不是"取两个键"。
4. **闭包捕获循环变量**：`dotimes` 里的 `i` 每轮同一 binding 复用，闭包想留住当时的值要 `(let [i i] ...)` 拷贝（for/loop 无此问题，它们每轮新 binding）。
5. **`(defn f [])` 的空参数**调用是 `(f)`——多 arity 里 `([])` 分支别漏。
6. **文档字符串后面紧跟属性 map 再跟参数**，顺序错了就成了函数体表达式。
7. **`apply` 吃惰性 seq 会全部实现**——无限 seq 传给 apply 是死循环。

---

上一章：[05 集合](05-collections.md) · 下一章：[07 控制流](07-control-flow.md)
