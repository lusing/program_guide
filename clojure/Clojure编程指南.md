# Clojure 编程指南

一本从零到能用的 Clojure 教程，28 章。每一章的代码都可以直接运行——macOS/Linux 用 Clojure CLI（`clojure` 1.12.6）+ `build.sh`，Windows 用 Leiningen 2.13 + OpenJDK 26 + `build.ps1`，两边依赖声明（`deps.edn` / `project.clj`）完全一致。

## Clojure 是什么

Clojure 是一门运行在 Java 虚拟机（JVM）上的 Lisp 方言，由 Rich Hickey 于 2007 年创建。它以函数式编程为核心，强调不可变数据和纯函数，同时通过瞬态（transient）数据和引用类型（reference types）提供可变状态的安全管理。

Clojure 的核心设计哲学可以概括为以下几点：

**不可变优先**：Clojure 的所有核心数据结构（列表、向量、映射、集合）都是不可变的。对数据的任何"修改"操作都会返回一个新数据结构，原数据结构保持不变。底层使用持久化数据结构（persistent data structures）实现结构共享，使这一设计在时间和空间上都非常高效。

**函数式范式**：Clojure 鼓励使用纯函数（无副作用的函数）进行数据转换。`map`、`filter`、`reduce` 等高阶函数是日常编程的核心工具。Clojure 也支持可变状态，但通过 `atom`、`ref`、`agent` 等引用类型将其限制在可控范围内。

**REPL 驱动开发**：Clojure 的交互式开发环境（REPL）允许开发者随时求值表达式、检查状态、试验代码。这种"即时反馈"的开发方式是 Clojure（以及整个 Lisp 家族）的标志性体验。

**Java 互操作**：Clojure 与 Java 无缝互操作。可以直接调用 Java 方法、使用 Java 类库、实现 Java 接口、处理 Java 异常。这使 Clojure 既能享受函数式编程的优雅，又能利用 JVM 庞大的生态系统。

**并发设计**：Clojure 从语言层面为并发编程提供了强有力的支持。软件事务内存（STM）让多个引用的协调更新变得安全而简洁；`atom` 提供了高效的原子更新；`future` 和 `promise` 支持异步计算。

### 与 Common Lisp / Scheme 的对比

| | Clojure | Common Lisp (SBCL) | Scheme (R7RS) |
|---|---|---|---|
| 宿主平台 | JVM (也支持 CLR/JS) | 原生编译 | 多种实现 |
| 数据结构 | 持久化不可变 | 可变列表/向量 | 可变列表/向量 |
| 并发模型 | STM / atom / agent | 锁/线程变量 | 锁/并发模块 |
| 求值策略 | 严格求值 | 严格求值 | 严格求值 |
| 命名空间 | ns（基于 Java 包） | 包（package） | 模块（module） |
| 宏卫生 | 是（syntax-quote + gensym） | 是（gensym） | 是（卫生宏） |
| 字面量集合 | `{}` 映射、`#{}` 集合、`[]` 向量 | 无（需 `#(hash-table ...)`） | 无 |

与 Common Lisp 相比，Clojure 的数据字面量语法更丰富——向量用 `[]`、映射用 `{}`、集合用 `#{}`，不再需要 `list` 或 `vector` 函数调用来创建这些结构。Clojure 的不可变持久化数据结构是 Common Lisp 没有的核心特性，这让函数式风格在实践中更加自然。

与 Scheme 相比，Clojure 同样是 Lisp-1（函数与变量共用一个命名空间，函数就是普通的值），但引入了 Var 系统：`def` 定义的是 Var 而非直接绑定值，这让重新定义、动态作用域 Var（`^:dynamic`）成为可能。与 Common Lisp（Lisp-2，函数与变量分属两个命名空间）相比，Clojure 里 `first-class` 函数的传递不需要 `#'` 取函数对象。

## 目录

- [第 1 章 认识 Clojure](#第-1-章-认识-clojure)
- [第 2 章 工具链与运行方式](#第-2-章-工具链与运行方式)
- [第 3 章 Hello World 与基本输出](#第-3-章-hello-world-与基本输出)
- [第 4 章 数据类型](#第-4-章-数据类型)
- [第 5 章 集合](#第-5-章-集合)
- [第 6 章 函数与闭包](#第-6-章-函数与闭包)
- [第 7 章 控制流](#第-7-章-控制流)
- [第 8 章 解构](#第-8-章-解构)
- [第 9 章 高阶函数](#第-9-章-高阶函数)
- [第 10 章 惰性序列](#第-10-章-惰性序列)
- [第 11 章 宏与元编程](#第-11-章-宏与元编程)
- [第 12 章 多方法](#第-12-章-多方法)
- [第 13 章 记录与协议](#第-13-章-记录与协议)
- [第 14 章 并发与引用类型](#第-14-章-并发与引用类型)
- [第 15 章 Java 互操作](#第-15-章-java-互操作)
- [第 16 章 文件与 I/O](#第-16-章-文件与-io)
- [第 17 章 命名空间](#第-17-章-命名空间)
- [第 18 章 测试](#第-18-章-测试)
- [第 19 章 clojure.spec](#第-19-章-clojurespec)
- [第 20 章 Transducer](#第-20-章-transducer)
- [第 21 章 经典算法](#第-21-章-经典算法)
- [第 22 章 综合实战：成绩分析管线](#第-22-章-综合实战成绩分析管线)
- [第 23 章 性能与优化](#第-23-章-性能与优化)
- [第 24 章 core.async](#第-24-章-coreasync)
- [第 25 章 Web 开发实战：Ring](#第-25-章-web-开发实战ring)
- [第 26 章 Leiningen 项目实战](#第-26-章-leiningen-项目实战)
- [第 27 章 生态与工具](#第-27-章-生态与工具)
- [第 28 章 综合实战：MiniLisp 解释器](#第-28-章-综合实战minilisp-解释器)

---

## 第 1 章 认识 Clojure

Clojure 是 Lisp 家族在现代编程语言舞台上的重要一员。它将 Lisp 的 S-表达式语法、代码即数据（homoiconicity）理念和，与现代软件工程的需求——不可变数据、并发安全、平台生态——结合起来。

Lisp 家族的核心特征是 S-表达式（Symbolic Expression）。所有代码都写成 `(operator operand1 operand2 ...)` 的嵌套括号形式，运算符在前、操作数在后，这种表示法叫做前缀表达式（波兰表示法）。

```clojure
(+ 1 2)          ;; => 3
(* 3 (+ 1 2))    ;; => 9
(println "Hi")   ;; 输出 Hi
```

Clojure 在传统 Lisp 语法的基础上增加了几种集合字面量：

- `'()` 或 `(list ...)` 创建列表
- `[]` 创建向量（可随机访问的数组）
- `{}` 创建映射（键值对）
- `#{}` 创建集合（无重复元素）
- `:keyword` 创建关键字（自引用的符号）

---

## 第 2 章 工具链与运行方式

Clojure 的官方工具链是 `clojure` CLI（也称为 Clojure CLI tools）。它负责下载依赖、启动 REPL、运行脚本和构建项目。

### 三种运行模式

| 模式 | 命令 | 用途 |
|------|------|------|
| `-M` | `clojure -M script.clj` | 运行脚本（main 模式） |
| `-X` | `clojure -X namespace/function` | 执行函数（exec 模式） |
| `-A` | `clojure -A:alias` | 使用别名（兼容旧模式） |

### REPL

```bash
clojure              # 启动 REPL
```

在 REPL 中可以直接求值表达式：

```clojure
user=> (+ 1 2)
3
user=> (println "Hello!")
Hello!
nil
```

### deps.edn

项目根目录下的 `deps.edn` 文件描述依赖和路径配置：

```clojure
{:deps {org.clojure/clojure {:mvn/version "1.12.6"}}
 :paths ["src"]}
```

本教程的 `deps.edn` 除 Clojure 本体外，只为第 24 章（core.async）和第 25 章（Ring）引入两个额外依赖。

### Leiningen：另一个主流工具链

Leiningen 是社区最早的构建工具，用 `project.clj` 描述工程，职责与 Clojure CLI 等价：

| | Clojure CLI | Leiningen |
|---|---|---|
| 配置文件 | `deps.edn`（EDN 数据） | `project.clj`（Clojure 代码） |
| 运行脚本 | `clojure -M script.clj` | `lein run -m 命名空间` |
| 跑测试 | `clojure -M:test` | `lein test` |
| 打包 | 需额外工具（如 depstar） | `lein uberjar`（内置） |
| REPL | `clojure` | `lein repl` |

本教程双轨并行：macOS/Linux 走 Clojure CLI（`build.sh`），Windows 走 Leiningen（`build.ps1`），两边依赖声明一致。Leiningen 的工程化用法见[第 26 章](#第-26-章-leiningen-项目实战)。

> Windows 实测注意：Leiningen 2.13 的启动器会给 JVM 传 `--enable-native-access=ALL-UNNAMED`，PATH 里的 Java 8/11 不认识会直接崩；`lein.bat` 只认 `JAVA_CMD` 环境变量（不认 `JAVA_HOME`），需要设成 JDK 16+ 的完整路径。

---

## 第 3 章 Hello World 与基本输出

（对应示例：`01_hello.clj`）

Clojure 提供四种主要输出函数：

| 函数 | 换行 | 字符串引号 | 用途 |
|------|------|-----------|------|
| `println` | 是 | 不显示 | 人类可读输出 |
| `print` | 否 | 不显示 | 不换行输出 |
| `prn` | 是 | 显示 | 机器可读输出 |
| `pr` | 否 | 显示 | 机器可读不换行 |

```clojure
(println "Hello, Clojure!")     ;; Hello, Clojure!
(prn "Hello, Clojure!")         ;; "Hello, Clojure!"
(str "a" "b" 123)               ;; "ab123"
(format "%s = %d" "pi" 3)      ;; "pi = 3"
```

`def` 定义全局绑定，`defn` 定义函数：

```clojure
(def hello "Hello, Clojure!")

(defn greet [name]
  (str "Hello, " name "!"))

(greet "World")                 ;; => "Hello, World!"
```

---

## 第 4 章 数据类型

（对应示例：`02_data_types.clj`）

### 数字

Clojure 的数字类型基于 Java 但有所扩展：

- **整数**：`42`（long）、`0xFF`（十六进制）、`999...N`（BigInteger）
- **浮点**：`3.14`（double）、`1.5e3`（科学计数法）
- **比值**：`(/ 1 3)` → `1/3`（精确分数，自动约分）
- **BigDecimal**：`3.14M`（精确十进制，适合财务）

比值是 Clojure 的独特特性。`(/ 1 3)` 不等于 `0.333...`，而是精确的 `1/3`。

```clojure
(+ 1/3 1/3)         ;; => 2/3
(* 1/3 3)           ;; => 1
(double 1/3)        ;; => 0.3333333333333333
```

### 关键字

关键字以冒号开头，是一种自引用的符号。关键字相等的判定是身份比较，非常高效，常用于映射的键和枚举值。

```clojure
:hello              ;; 简单关键字
:user/name          ;; 命名空间关键字
::name              ;; 自动命名空间关键字

(:name {:name "Alice"})  ;; => "Alice"（关键字可作为函数取值）
```

### 布尔值与 nil

在布尔上下文中，只有 `nil` 和 `false` 是假值。`0`、空字符串 `""`、空集合 `[]` 都是真值。

```clojure
(if 0 :truthy :falsy)       ;; => :truthy
(if nil :truthy :falsy)     ;; => :falsy
(if [] :truthy :falsy)      ;; => :truthy
```

---

## 第 5 章 集合

（对应示例：`03_collections.clj`）

Clojure 有四种核心集合类型，全部不可变、持久化：

| 类型 | 字面量 | 特点 | conj 位置 |
|------|--------|------|----------|
| 列表 | `'(1 2 3)` | 单向链表，头部 O(1) | 头部 |
| 向量 | `[1 2 3]` | 随机访问 O(1) | 尾部 |
| 映射 | `{:a 1}` | 键值对，哈希表 | 不适用 |
| 集合 | `#{1 2}` | 无序无重复 | 不适用 |

### 不可变性与持久化

操作返回新集合，原集合不变。底层使用结构共享，内存高效：

```clojure
(def original [1 2 3])
(def updated (conj original 4))
;; original => [1 2 3]
;; updated  => [1 2 3 4]
```

### 映射操作

```clojure
(def m {:name "Alice" :age 30})

(:name m)                    ;; => "Alice"
(assoc m :age 31)           ;; => {:name "Alice" :age 31}
(update m :age inc)         ;; => {:name "Alice" :age 31}
(dissoc m :age)             ;; => {:name "Alice"}
(merge m {:city "NYC"})     ;; => {:name "Alice" :age 30 :city "NYC"}
```

### 集合运算

需要 `clojure.set` 命名空间：

```clojure
(require '[clojure.set :as set])

(set/union #{1 2} #{3 4})           ;; => #{1 2 3 4}
(set/intersection #{1 2 3} #{2 3 4}) ;; => #{2 3}
(set/difference #{1 2 3} #{2})      ;; => #{1 3}
```

---

## 第 6 章 函数与闭包

（对应示例：`04_functions.clj`）

### 参数模型

Clojure 支持多参数体（arity overloading）和可变参数：

```clojure
(defn multiply
  ([] 0)
  ([x] x)
  ([x y] (* x y))
  ([x y & more] (apply * x y more)))
```

### 匿名函数

```clojure
(fn [a b] (+ a b))    ;; 完整形式
#(+ %1 %2)            ;; 简写形式（% = 第一个参数, %& = 所有参数）
```

### 闭包

闭包捕获其定义环境的变量，每次调用 `make-counter` 创建一个独立的状态：

```clojure
(defn make-counter [init]
  (let [state (atom init)]
    (fn [] (swap! state inc))))

(def c1 (make-counter 0))
(c1)  ;; => 1
(c1)  ;; => 2
```

### apply 与 partial

```clojure
(apply + [1 2 3 4 5])     ;; => 15
(def add-10 (partial + 10))
(add-10 5)                 ;; => 15
```

---

## 第 7 章 控制流

（对应示例：`05_control_flow.clj`）

Clojure 的控制流结构都是表达式，有返回值。

### if / when

```clojure
(if test then else?)
(when test body)
(if-let [x (first coll)] x "empty")
(when-let [x (first coll)] body)
```

### cond / case

```clojure
(cond
  (neg? n) "negative"
  (zero? n) "zero"
  :else "positive")

(case color
  :red "#FF0000"
  :blue "#0000FF"
  "#000000")
```

### and / or 短路求值

`and` 返回第一个假值或最后一个值；`or` 返回第一个真值或最后一个值：

```clojure
(and 1 2 3)         ;; => 3
(or nil false 3)    ;; => 3
```

### loop / recur

Clojure 没有传统 for 循环。使用 `loop`/`recur` 实现函数式循环（尾递归优化）：

```clojure
(defn factorial [n]
  (loop [i n, acc 1]
    (if (zero? i)
      acc
      (recur (dec i) (* acc i)))))
```

---

## 第 8 章 解构

（对应示例：`06_destructuring.clj`）

解构是 Clojure 最实用的特性之一，可以在 `let` 绑定和函数参数中直接提取嵌套数据。

### 顺序解构

```clojure
(let [[a b c] [1 2 3]] ...)         ;; a=1, b=2, c=3
(let [[a b & rest] [1 2 3 4 5]] ...) ;; a=1, b=2, rest=(3 4 5)
(let [[a b :as all] [1 2 3]] ...)    ;; a=1, b=2, all=[1 2 3]
```

### 关联解构

```clojure
(let [{:keys [name age]} {:name "Alice" :age 30}] ...)
(let [{:keys [name] :or {name "N/A"}} {}] ...)  ;; name="N/A"
```

### 函数参数中的解构

```clojure
(defn distance [[x1 y1] [x2 y2]]
  (Math/sqrt (+ (Math/pow (- x2 x1) 2)
                (Math/pow (- y2 y1) 2))))

(defn make-url [{:keys [host port] :or {port 80}}]
  (str "http://" host ":" port))
```

---

## 第 9 章 高阶函数

（对应示例：`07_higher_order.clj`）

高阶函数是 Clojure 数据转换的核心工具。

### map / filter / reduce

```clojure
(map inc [1 2 3])              ;; => (2 3 4)
(filter even? [1 2 3 4 5 6])   ;; => (2 4 6)
(reduce + [1 2 3 4 5])        ;; => 15
```

### partial / complement / comp

```clojure
(def add-10 (partial + 10))
(def not-even? (complement even?))
(def f (comp inc #(* % 3)))    ;; 先乘3再+1
```

### 线程宏

`->`（thread-first）和 `->>`（thread-last）让数据管线更易读：

```clojure
(->> [1 2 3 4 5]
     (map inc)
     (filter even?)
     (reduce +))
;; 等价于 (reduce + (filter even? (map inc [1 2 3 4 5])))
```

### juxt / group-by / frequencies

```clojure
((juxt min max) 3 1 4 1 5 9)   ;; => [1 9]
(group-by even? [1 2 3 4 5])    ;; => {true [2 4] false [1 3 5]}
(frequencies "aababc")         ;; => {\a 3 \b 2 \c 1}
```

---

## 第 10 章 惰性序列

（对应示例：`08_lazy_seqs.clj`）

Clojure 的序列操作返回惰性序列（LazySeq），元素按需计算。这使得无限序列成为可能。

### 无限序列

```clojure
(take 5 (range))                        ;; => (0 1 2 3 4)
(take 5 (iterate inc 0))                ;; => (0 1 2 3 4)
(take 10 (iterate (fn [[a b]] [b (+ a b)]) [0 1]))  ;; 斐波那契
```

### lazy-seq 自定义

```clojure
(defn naturals
  ([] (naturals 1))
  ([n] (lazy-seq (cons n (naturals (inc n))))))
```

### for 列表推导

```clojure
(for [x [:a :b] y [1 2]] [x y])
;; => ([:a 1] [:a 2] [:b 1] [:b 2])

(for [x (range 10) :when (even? x)] x)
;; => (0 2 4 6 8)
```

---

## 第 11 章 宏与元编程

（对应示例：`09_macros.clj`）

宏在编译时展开，操作的是代码本身（S-表达式）。这是 Lisp 家族代码即数据（homoiconicity）理念的直接体现。

### syntax-quote 与 unquote

```clojure
(def x 42)
`(+ 1 ~x)            ;; => (clojure.core/+ 1 42)
`(+ ~@[1 2 3])       ;; => (clojure.core/+ 1 2 3)
```

### defmacro

```clojure
(defmacro unless [test body]
  `(if (not ~test) ~body))

(defmacro my-or
  ([] nil)
  ([x] x)
  ([x & rest]
   `(let [e# ~x]
      (if e# e# (my-or ~@rest)))))
```

### macroexpand

```clojure
(macroexpand '(-> 5 (+ 3) (* 2)))
;; => (* (+ 5 3) 2)
```

### gensym 与卫生宏

`#` 后缀自动生成唯一符号（gensym），避免变量名冲突：

```clojure
(defmacro my-when [test & body]
  `(if ~test (do ~@body) nil))
```

---

## 第 12 章 多方法

（对应示例：`10_multimethods.clj`）

多方法（multimethods）允许根据分发函数的结果选择不同的实现，支持任意维度分发和层级关系。

```clojure
(defmulti area :shape)

(defmethod area :rectangle [{:keys [width height]}]
  (* width height))

(defmethod area :circle [{:keys [radius]}]
  (* Math/PI radius radius))
```

### 层级关系

```clojure
(derive ::dog ::animal)
(derive ::cat ::animal)

(isa? ::dog ::animal)    ;; => true
```

### 多方法 vs 协议

多方法灵活但性能略低；协议性能好但只能按类型分发。选择取决于场景。

---

## 第 13 章 记录与协议

（对应示例：`11_records_protocols.clj`）

### defrecord

记录是带有命名字段的不可变数据类型，类似映射但更高效：

```clojure
(defrecord Person [name age email])

(->Person "Alice" 30 "alice@example.com")
(map->Person {:name "Bob" :age 25 :email "bob@x.com"})
```

### defprotocol

协议定义一组方法签名，记录可以实现协议：

```clojure
(defprotocol Shape
  (area [this])
  (perimeter [this]))

(defrecord Circle [radius]
  Shape
  (area [this] (* Math/PI radius radius)))
```

### reify

`reify` 创建实现协议的匿名对象，类似 Java 匿名内部类：

```clojure
(reify Shape
  (area [this] 42))
```

### extend-protocol / extend-type

为已有类型实现协议：

```clojure
(extend-protocol Stringifiable
  java.lang.String
  (to-string [this] this)

  java.lang.Number
  (to-string [this] (str "Number: " this)))
```

---

## 第 14 章 并发与引用类型

（对应示例：`12_concurrency.clj`）

Clojure 提供四种引用类型，分别适用于不同的并发场景：

| 类型 | 语义 | 适用场景 |
|------|------|---------|
| `atom` | 独立同步更新 | 计数器、缓存 |
| `ref` | 协调同步更新（STM） | 多值事务更新 |
| `agent` | 异步更新 | 日志、后台任务 |
| `future` | 延迟执行 | 并行计算 |

### atom

```clojure
(def counter (atom 0))
(swap! counter inc)     ;; @counter => 1
(reset! counter 100)    ;; @counter => 100
```

### ref / dosync（STM）

```clojure
(def account-a (ref 1000))
(def account-b (ref 500))

(dosync
  (alter account-a - 200)
  (alter account-b + 200))
```

### future

```clojure
(def result (future (Thread/sleep 100) (+ 1 2 3)))
@result    ;; => 6（阻塞直到完成）
```

### pmap

```clojure
(pmap #(* % %) (range 10))  ;; 并行映射
```

---

## 第 15 章 Java 互操作

（对应示例：`13_java_interop.clj`）

Clojure 与 Java 的互操作是无缝的。

### 实例方法与字段

```clojure
(.length "hello")            ;; => 5
(.substring "hello" 0 3)    ;; => "hel"
```

### 静态方法与字段

```clojure
(Math/sqrt 16)               ;; => 4.0
Math/PI                      ;; => 3.14159...
(Integer/parseInt "42")      ;; => 42
```

### doto / ..

```clojure
(doto (StringBuffer.)
  (.append "Hello")
  (.append ", World!"))

(.. (File. "/tmp") (getAbsolutePath))
```

### 异常处理

```clojure
(try
  (Integer/parseInt "abc")
  (catch NumberFormatException e
    -1)
  (finally
    (println "cleanup")))

(throw (ex-info "Custom error" {:code 42}))
```

### proxy

```clojure
(proxy [Runnable] []
  (run [] (println "Running!")))
```

---

## 第 16 章 文件与 I/O

（对应示例：`14_file_io.clj`）

### slurp / spit

```clojure
(spit "file.txt" "content")
(slurp "file.txt")             ;; => "content"
```

### with-open

```clojure
(with-open [r (clojure.java.io/reader "file.txt")]
  (count (line-seq r)))
```

### EDN

EDN（Extensible Data Notation）是 Clojure 的数据序列化格式，类似 JSON 但支持 Clojure 的所有数据类型：

```clojure
(pr-str {:a 1 :b [2 3]})      ;; => "{:a 1 :b [2 3]}"
(clojure.edn/read-string "{:a 1 :b [2 3]}")
```

---

## 第 17 章 命名空间

（对应示例：`15_namespaces.clj`）

`ns` 宏是命名空间定义的主要方式：

```clojure
(ns my-app.core
  (:require [clojure.string :as str]
            [clojure.set :as set])
  (:import [java.util Date]))
```

| 选项 | 说明 |
|------|------|
| `:as` | 命名空间别名 |
| `:refer` | 引入特定符号 |
| `:require` | 加载其他命名空间 |
| `:import` | 导入 Java 类 |

```clojure
(str/upper-case "hello")    ;; 使用别名
```

---

## 第 18 章 测试

（对应示例：`16_testing.clj`）

`clojure.test` 是 Clojure 内置的测试框架：

```clojure
(deftest test-add
  (is (= 4 (+ 2 2)))
  (is (thrown? ArithmeticException (/ 1 0))))

(are [n expected] (= expected (fib n))
  0 0
  1 1
  2 1
  3 2)
```

`run-tests` 执行当前命名空间的所有测试，返回结果映射。

---

## 第 19 章 clojure.spec

（对应示例：`17_spec.clj`）

`clojure.spec.alpha` 是 Clojure 的数据验证和函数规范系统：

```clojure
(s/def ::id pos-int?)
(s/def ::name string?)
(s/def ::age (s/and int? #(>= % 0) #(< % 150)))

(s/def ::person
  (s/keys :req [::id ::name ::age]))

(s/valid? ::person {::id 1 ::name "Alice" ::age 30})  ;; => true
(s/explain ::person {::id -1 ::name "Alice" ::age 30}) ;; 报告错误
```

### 函数规范

```clojure
(s/fdef add-numbers
  :args (s/cat :a number? :b number?)
  :ret number?)
```

---

## 第 20 章 Transducer

（对应示例：`18_transducers.clj`）

Transducer 是「转换函数的函数」，与数据源无关，可在不同上下文中复用。

```clojure
(def xf (comp (map inc)
              (filter even?)
              (take 3)))

(into [] xf (range 100))     ;; => [2 4 6]
(transduce xf + 0 (range 100)) ;; => 12
```

Transducer 的优势：

1. 无中间序列，内存高效
2. 可以提前终止
3. 可复用，与数据源无关
4. 可用于不同上下文（`into`、`transduce`、`sequence`、core.async channel）

---

## 第 21 章 经典算法

（对应示例：`19_algorithms.clj`）

本章使用 Clojure 实现了多种经典算法：

- 函数式快速排序（三路分区处理重复元素）
- 归并排序（惰性序列版本）
- 二分查找
- 斐波那契（朴素递归 / 记忆化 / 迭代）
- 埃拉托斯特尼筛法
- 拓扑排序（Kahn 算法）
- Dijkstra 最短路径

函数式排序的特点是代码简洁、表达力强，但非原地排序。在生产环境中应使用内置 `sort` 函数。

---

## 第 22 章 综合实战：成绩分析管线

（对应示例：`20_project.clj`）

综合运用记录、CSV 解析、spec 验证、高阶函数、数据聚合、EDN 报告等特性，构建了一个学生成绩数据分析管线。

完整流程：CSV 解析 → 数据富化 → 验证 → 聚合统计 → 报告生成。

---

## 第 23 章 性能与优化

（对应示例：`21_performance.clj`）

Clojure 默认"够快"，但热点路径值得优化。本章的每个结论都在示例里实测过（数字为 OpenJDK 26 上的一次实测，看相对倍数）。

### 先测量：time 宏与 JIT 预热

JVM 先用 C1 编译（编译快、优化浅），热点再升级 C2。基准前必须预热，否则测的是解释器：

```clojure
(dotimes [_ 3] (bench-sum 100000))   ;; 预热
(time (bench-sum 1000000))           ;; "Elapsed time: 4.3 msecs"
```

### 反射 vs 类型提示（实测 537 倍）

Clojure 是动态语言，`(.length s)` 编译期常常不知道 `s` 的类型，只能运行时反射。打开警告后每处反射都会现形：

```clojure
(set! *warn-on-reflection* true)

(defn len-reflect [s] (.length s))            ;; Reflection warning ...
(defn len-hint ^long [^String s] (.length s)) ;; 直接 invokevirtual
```

实测（200 万次调用）：反射版 **2281ms**，提示版 **4.3ms**。生产项目应在 `project.clj` 的 dev profile 里全局打开 `*warn-on-reflection*`。

### 原始类型数学

参数默认装箱为 `Long` 对象；`^long` 提示 + `unchecked-inc`/`unchecked-add` 让循环完全不装箱。实测百万次求和：装箱版 33ms，原始版 6ms。注意 `unchecked-*` 会静默溢出，只用于确知不会溢出的热循环。

```clojure
(defn sum-primitive [^long n]
  (loop [i 0 acc 0]
    (if (= i n) acc
        (recur (unchecked-inc i) (unchecked-add acc i)))))
```

### 瞬态集合

大批量构建集合时，`conj!`/`assoc!` 在 transient 上原地写，完成后 `persistent!` 转回。实测百万元素构向量：23.8ms → 12.4ms，结果完全一致：

```clojure
(persistent! (reduce conj! (transient []) (range 1000000)))
```

### Java 数组（实测 26 倍）

热循环里退回原始数组：`int-array` + `areduce`（编译宏，生成原始循环）。实测百万元素求和：`reduce +` 向量 221ms，`areduce` 数组 8.3ms：

```clojure
(defn sum-array ^long [^ints a]
  (areduce a i ret (long 0) (unchecked-add ret (aget a i))))
```

注意：`areduce`/`amap` 直接吃 def 出来的 var 拿不到类型会触发反射，先绑定到 `^ints` 局部。

### memoize（实测 546 倍）

纯函数加缓存，第二次调用 93ms → 0.17ms。适合"参数域小、计算重"的场景；参数域大时缓存本身成为内存负担。

### 字符串拼接

`(str acc x)` 循环是 O(n²)（8000 次已经能测出差距）；正确姿势是 `StringBuilder` 或 `clojure.string/join` / `(apply str coll)`。

---

## 第 24 章 core.async

（对应示例：`22_core_async.clj`；依赖 `org.clojure/core.async` 1.9.x）

core.async 把 Go 语言的 CSP 并发模型带到 JVM：**用 channel 在独立执行体之间传值，而不是用锁共享内存**。

### channel 与阻塞读写

```clojure
(chan)      ;; 无缓冲：写阻塞直到有人读
(chan 3)    ;; 缓冲 3 个
(>!! c 42)  ;; 阻塞写（!! 后缀 = 阻塞）
(<!! c)     ;; 阻塞读
```

无缓冲 channel 在同一线程里先写后读会死锁——写和读必须在不同执行体上。

### go 块与停车（parking）

`go` 把 body 编译成状态机，`<!`/`>!` 是**停车**而非阻塞线程：等待时线程被释放去跑别的 go 块。一个线程可以承载几万个 go 块。`go` 返回装着结果的 channel：

```clojure
(<!! (go (+ 6 7)))          ;; => 13
(let [c (chan)]
  (go (>! c (* 6 7)))       ;; 另一个执行体里写
  (<!! c))                  ;; => 42
```

### close! 的语义

关闭后读**立即返回 nil**（先排空缓冲），**写返回 false**。`nil` 因此成为标准的"流结束"信号：

```clojure
(close! c)
(<!! c)      ;; => nil（不阻塞、不抛错）
(>!! c :x)   ;; => false
```

### go-loop 工作池

channel 天然就是线程安全的任务队列。N 个 worker 循环取任务，`close!` 是停机信号：

```clojure
(let [jobs (chan 10) results (chan 10)]
  (dotimes [_ 4]
    (go-loop []
      (when-some [job (<! jobs)]      ;; 关闭后 <! 返回 nil，worker 退出
        (>! results (* job job))
        (recur))))
  (doseq [job (range 1 11)] (>!! jobs job))
  (close! jobs)
  (sort (repeatedly 10 #(<!! results))))
;; => (1 4 9 16 25 36 49 64 81 100)
```

### alts!! 多路选择与 timeout

`alts!!`（go 里用 `alts!`）同时等多个 channel，返回 `[值 端口]`。`timeout` 是一次性 channel，配合起来就是"限期等待"：

```clojure
(let [never (chan)
      t (timeout 80)
      [v port] (alts!! [never t])]  ;; 80ms 内 never 不会有数据
  (nil? v))                          ;; => true
```

### go 与 thread 怎么选

| | `go` | `thread` |
|---|---|---|
| 等待方式 | 停车（不占线程） | 阻塞线程 |
| 适合 | 协调逻辑、channel 编排 | 真正的阻塞 IO / CPU 密集计算 |

`thread` 返回 channel，用法类似 `future`：`(<!! (thread (do-work)))`。

### pipeline：transducer 会师 channel

`(pipeline n out xf in)` 从 `in` 读、过 transducer、写 `out`——第 20 章的 `(map inc)` 原封不动地用在了流上：

```clojure
(let [in (chan 10) out (chan 10)]
  (a/pipeline 4 out (map inc) in)
  (thread (doseq [x (range 5)] (>!! in x)) (close! in))
  (sort (take 5 (repeatedly #(<!! out)))))  ;; => (1 2 3 4 5)
```

### 缓冲策略

| 缓冲 | 满了之后 | 场景 |
|---|---|---|
| `(chan n)` | 写阻塞（背压） | 生产消费速率要匹配 |
| `(dropping-buffer n)` | 丢**新**元素 | 传感器采样 |
| `(sliding-buffer n)` | 丢**旧**元素 | 行情、日志尾部 |

```clojure
(let [c (chan (sliding-buffer 2))]
  (doseq [x [1 2 3 4 5]] (>!! c x))
  [(<!! c) (<!! c)])            ;; => [4 5] 只留最新两个
```

---

## 第 25 章 Web 开发实战：Ring

（对应示例：`23_ring_web.clj`；依赖 `ring/ring-core` + `ring/ring-jetty-adapter` 1.15.x）

Clojure 的 Web 生态全部建立在 Ring 上——一个类似 Python WSGI 的 HTTP 抽象层。

### Ring 模型：一切都是 map

handler 是一个普通函数：吃 request map、吐 response map。没有基类、没有注解、没有框架魔法：

```clojure
(defn handler [request]
  {:status 200
   :headers {"Content-Type" "text/plain"}
   :body "Hello, Ring!"})
```

request 里有什么：`:request-method`（`:get`/`:post`）、`:uri`、`:query-string`、`:headers`、`:body`（InputStream）。

### 路由就是 cond

Ring 本身不带路由，`method + uri` 只是两个 map 键：

```clojure
(defn app [request]
  (let [{:keys [request-method uri query-params]} request]
    (cond
      (and (= request-method :get) (= uri "/hello"))
      (-> (response (str "Hello, " (get query-params "name" "World") "!"))
          (content-type "text/plain"))
      :else (not-found "No route"))))
```

Compojure、Reitit 等路由库替换的只是这段 `cond`，下面的中间件、handler、服务器全部不变。

### 中间件：handler 的高阶函数

```clojure
(defn wrap-counter [handler]
  (fn [request]
    (swap! request-count inc)
    (-> (handler request)
        (assoc-in [:headers "X-Request-Count"] (str @request-count)))))

(def app+ (-> app wrap-params wrap-counter))   ;; 自内向外包裹
```

标准库的 `wrap-params` 把 `:query-string` 解析成 `:query-params`。**注意坑**：POST 不带 `Content-Type` 时 HttpURLConnection 默认按 `application/x-www-form-urlencoded` 发送，`wrap-params` 会把 body 解析掉——示例里显式设 `text/plain` 保住原始 body。

### 不起服务器也能测

直接函数调用 handler 就是一个完整的"HTTP 测试"——这是 Ring 架构最大的红利：

```clojure
(:status (app+ {:request-method :get :uri "/hello" :query-string "name=Middleware"}))
;; => 200
```

### 真服务器 + 真请求

`run-jetty` 把 handler 挂到嵌入式 Jetty 12 上（`:join? false` 让主线程继续跑），示例里用 JDK 自带的 `HttpURLConnection` 发真实请求验证了 GET/POST/JSON/404/中间件头全链路：

```clojure
(def server (run-jetty app+ {:port 18899 :join? false}))
;; ... 请求验证 ...
(.stop server)
```

Jetty 12 只带 SLF4J API 没带实现，启动时的几行 "No SLF4J providers" 警告无害；生产加 logback 依赖即可。

---

## 第 26 章 Leiningen 项目实战

（对应工程：`lein-lab/`；验证链 `lein test` → `lein run` → `lein uberjar` → `java -jar`）

本章用一个小而完整的工程演示 Leiningen 的标准工作流。`lein-lab` 是个 mini 文本统计工具：两个源码命名空间 + 一个测试命名空间。

### 工程布局：命名空间 ↔ 路径的映射规则

```text
lein-lab/
├── project.clj                    工程描述（依赖、入口、profile）
├── src/lein_lab/core.clj          命名空间 lein-lab.core
├── src/lein_lab/text.clj          命名空间 lein-lab.text
└── test/lein_lab/core_test.clj    命名空间 lein-lab.core-test
```

规则：命名空间的 `-` 对应文件名的 `_`，`.` 对应目录分隔。`(require 'lein-lab.text)` 会在 classpath 的 `lein_lab/text.clj` 找文件。

### project.clj

```clojure
(defproject lein-lab "1.0.0"
  :description "Leiningen 工作流实验：源码布局 / 测试 / profile / uberjar"
  :dependencies [[org.clojure/clojure "1.12.6"]]
  :main lein-lab.core                       ;; lein run / java -jar 的入口
  :profiles {:dev     {:global-vars {*warn-on-reflection* true}}
             :uberjar {:aot :all}}           ;; 打包前全量 AOT 编译
  :target-path "target")
```

### 四步验证链（build.ps1 -Lab 全自动跑）

```bash
lein test        # 跑 test/ 下所有 *-test 命名空间 → 6 tests, 15 assertions
lein run         # 调用 lein-lab.core/-main，支持 -- 分隔传参
lein uberjar     # AOT 编译 + 打包含全部依赖的 standalone jar
java -jar target/lein-lab-1.0.0-standalone.jar arg1 arg2   # 只要有 JVM 就能跑
```

`:gen-class` + `:aot :all` 让 `lein-lab.core` 编译出真正的 Java 类，jar 的 `Main-Class` 落在它上面——这就是 Clojure 程序"编译成 exe 思路"的 JVM 版本（再进一步是 GraalVM native-image）。

### profile

`:profiles` 里的配置只在对应场景叠加：`:dev` 在 `lein test`/`lein repl` 时生效，`:uberjar` 只在打包时生效。`lein with-profile +dev run` 显式叠加。典型用法：dev 打开反射警告、uberjar 开 AOT、生产 profile 换日志实现。

---

## 第 27 章 生态与工具

### 构建工具

| 工具 | 定位 |
|------|------|
| Clojure CLI | 官方工具链，`deps.edn` 配置，轻量组合式 |
| Leiningen | 社区元老，`project.clj` 配置，内置 uberjar/test 全流程 |
| shadow-cljs | ClojureScript 构建（接 npm 生态） |
| tools.build | 官方构建库（CI 里用程序描述构建） |

### 编辑器

| 编辑器 | 插件 |
|--------|------|
| Emacs | CIDER（最成熟的 REPL 驱动体验） |
| VS Code | Calva |
| IntelliJ | Cursive |
| Vim | vim-fireplace / conjure |

### 核心库

| 库 | 用途 |
|------|------|
| `core.async` | CSP 并发模型（第 24 章） |
| `core.match` | 模式匹配 |
| `core.logic` | 逻辑编程（miniKanren 移植） |
| `test.check` | 属性测试（QuickCheck 风格） |
| `spec.alpha` | 数据验证与规范（第 19 章） |
| Ring / Reitit | Web 抽象层 / 高性能路由（第 25 章） |
| next.jdbc | 数据库访问 |
| http-kit / aleph | 高并发 HTTP 服务器与客户端 |

### ClojureScript

Clojure 编译到 JavaScript 的方言，同一门语言写前端：不可变数据结构 + React（re-frame/reagent）是主流组合，shadow-cljs 负责与 npm 生态互通。代码层面与本章 Clojure 几乎一致，差异集中在宿主互操作（`js/...`）与异步宏。

---

## 第 28 章 综合实战：MiniLisp 解释器

（对应示例：`24_minilisp.clj`；33 个断言全过）

压轴实战：用约 200 行 Clojure 实现一门 Scheme 风格的小语言。这是"元循环"练习——Lisp 的代码就是数据，所以用 Lisp 解释 Lisp 出奇地短。也是全书知识的总装：高阶函数、解构、 recur、atom、`case`、异常、宏式脱糖全用上了。

### 阶段一：tokenize + parse —— 代码即数据的现场证明

```clojure
(defn tokenize [s]
  (->> (str/replace s #"(?m);[^\n]*" "")          ;; 剥注释
       (re-seq #"-?\d+|[()]|\"[^\"]*\"|[^\s()]+") ;; 整数/括号/字符串/符号
       vec))

(parse-string "(+ 1 (* 2 3))")   ;; => ((+ 1 (* 2 3)))  ← 普通 Clojure 数据！
```

解析结果就是嵌套的 Clojure list/symbol/long——没有 AST 类，没有访问者模式。

### 阶段二：环境链 = 词法作用域

环境是 `{:vars {符号 值} :parent 父环境}` 的 atom 链。查变量沿链上溯（`env-lookup`），`let`/函数调用创建子环境，`def` 写到根。闭包就是一个捕获了定义环境的普通 map：

```clojure
{:op 'closure :params params :body body :env env}
```

### 阶段三：求值器 + 尾调用优化

`case` 分发 special forms（`quote`/`if`/`def`/`fn`/`let`/`do`/`and`/`or`），其余全是函数应用。关键技巧：求值器主体是 `(loop [form env] ...)`，**尾位置的表达式用 `recur` 继续循环**——于是 MiniLisp 免费获得了它自己语法里根本没有的尾调用优化：

```clojure
(def loop-down (fn (n) (if (= n 0) (quote done) (loop-down (- n 1)))))
(loop-down 1000000)      ;; => done，百万层递归不爆栈（实测约 1 秒）
```

`and`/`or` 用"脱糖"实现——`(and a b c)` 求值时改写成 `(if a (and b c) a)` 再递归，这就是宏的本质。

### 实测彩蛋：Symbol 是可调用的

开发中真实踩到的坑：把内置表写成 `{'* '* ...}`（值也加了 quote），于是 `*` 查到的是**符号**而不是函数。Clojure 的 Symbol 实现了 IFn——`('* 2 3)` 等价 `(get 2 * 3)` 返回默认值 3——于是 `(fact 10)` 算出 1 而不是 3628800，全程无异常。这类"静默出错"只能靠测试断言抓住。

### 运行效果

```clojure
(def fact (fn (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
(fact 25)     ;; => 15511210043330985984000000（*' 自动升 BigInteger）
(def mymap (fn (f xs) (if (null? xs) (quote ())
                        (cons (f (car xs)) (mymap f (cdr xs))))))
(mymap (fn (x) (* x x)) (list 1 2 3 4 5))   ;; => (1 4 9 16 25)
```

---

## 实战章节索引（已验证）

下面这些配套源码已全部通过运行验证——24 个示例脚本 + 1 个 Leiningen 工程（25 个验证单元全绿）：

1. `01_hello.clj`：Hello World、基本输出、def/defn、运算
2. `02_data_types.clj`：数字、比值、字符串、字符、关键字、布尔、nil
3. `03_collections.clj`：列表、向量、映射、集合、队列
4. `04_functions.clj`：参数模型、匿名函数、闭包、apply/partial
5. `05_control_flow.clj`：if/when/cond/case、loop/recur
6. `06_destructuring.clj`：顺序解构、关联解构、:as/:or/:keys
7. `07_higher_order.clj`：map/filter/reduce、partial/comp、juxt
8. `08_lazy_seqs.clj`：惰性序列、range/iterate/for、无限序列
9. `09_macros.clj`：defmacro、syntax-quote、unquote、macroexpand
10. `10_multimethods.clj`：defmulti/defmethod、derive/isa?
11. `11_records_protocols.clj`：defrecord/defprotocol/reify
12. `12_concurrency.clj`：atom/ref/agent/future、STM、pmap
13. `13_java_interop.clj`：Java 方法/字段、doto/proxy、异常（已修 /tmp 跨平台问题）
14. `14_file_io.clj`：slurp/spit/with-open/edn（临时目录已移入 build/tmp）
15. `15_namespaces.clj`：ns/require/:as、clojure.walk/pprint
16. `16_testing.clj`：deftest/is/are/testing、异常测试
17. `17_spec.clj`：s/def/s/valid?/s/conform、s/fdef
18. `18_transducers.clj`：comp/transduce/into、自定义 transducer
19. `19_algorithms.clj`：快速排序、归并排序、二分查找、斐波那契、筛法
20. `20_project.clj`：综合实战——成绩数据分析管线
21. `21_performance.clj`：类型提示（实测 537 倍）、瞬态、原始数组、memoize
22. `22_core_async.clj`：channel/go/go-loop 工作池/alts!!/pipeline/缓冲策略
23. `23_ring_web.clj`：Ring 模型/手写路由/中间件/嵌入式 Jetty 真实 HTTP 验证
24. `24_minilisp.clj`：MiniLisp 解释器（tokenizer/parser/env/TCO，33 断言）
25. `lein-lab/`：Leiningen 工程（test → run → uberjar → java -jar 全链路）

统一验证命令：

```bash
# Windows（Leiningen 2.13 + JDK 16+，见 build.ps1 头部说明）
cd G:\code\guide\clojure
pwsh build.ps1 -All          # 24 示例 + lein-lab 全链路
pwsh build.ps1 -File 24      # 单跑一个示例
pwsh build.ps1 -Lab          # 只跑 lein-lab

# macOS / Linux（Clojure CLI）
cd /path/to/guide/clojure
./build.sh --all
```

---

## 标准库参考

Clojure 的核心命名空间：

| 命名空间 | 用途 |
|----------|------|
| `clojure.core` | 核心函数（默认引入） |
| `clojure.string` | 字符串操作 |
| `clojure.set` | 集合运算 |
| `clojure.walk` | 嵌套数据遍历 |
| `clojure.pprint` | 美化打印 |
| `clojure.java.io` | 文件 I/O |
| `clojure.edn` | EDN 读写 |
| `clojure.test` | 单元测试 |
| `clojure.spec.alpha` | 数据规范 |
| `clojure.repl` | REPL 工具 |
| `clojure.data` | 数据比较 |
| `clojure.xml` | XML 解析 |
| `clojure.zip` | 函数式 zipper |

## 最佳实践

1. **数据优先**：使用映射/向量/集合等基本数据结构，而非过早定义类。
2. **函数式风格**：优先使用 `map`/`filter`/`reduce` 和线程宏，而非 `loop`/`recur`。
3. **不可变优先**：默认使用不可变数据，需要可变状态时使用 `atom`/`ref`。
4. **解构代替取值**：使用解构从映射/向量中提取数据，而非多层 `get`。
5. **关键字作为键**：映射的键优先使用关键字（`:keyword`），因为关键字可以作为函数使用。
6. **spec 验证边界**：在系统边界使用 spec 验证输入，内部代码信任数据。
7. **REPL 驱动开发**：随时在 REPL 中求值、试验、调试，保持快速反馈循环。
8. **命名空间清晰**：每个文件一个命名空间，使用 `:as` 别名而非 `:refer`。
9. **测试并行编写**：使用 `clojure.test` 编写测试，与代码同步开发。
10. **善用 Transducer**：在数据管线中使用 Transducer 避免中间序列。
