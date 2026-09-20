# 04 · 数据类型

> 对应示例：`examples/02_data_types.clj`

> Clojure 的类型层 = **Java 类型 + 四件 Clojure 特产**：精确比值、关键字、
> 任意大整数、以及"只有 nil/false 为假"的真值语义。这四样是日常bug高发地。

## 4.1 数字全景

| 字面量 | 类型 | 说明 |
|---|---|---|
| `42` | `java.lang.Long` | 默认整数就是 64 位 long |
| `0xFF` `017` `2r1010` | Long | 十六/八/任意进制（基数r数字） |
| `42N` | `clojure.lang.BigInt` | 任意精度整数 |
| `3.14` `1.5e3` | `java.lang.Double` | 默认浮点就是 double |
| `3.14M` | `java.math.BigDecimal` | 精确十进制（钱！） |
| `1/3` | `clojure.lang.Ratio` | **精确分数**，自动约分 |

### 比值：Clojure 的招牌

```clojure
(/ 1 3)             ; => 1/3        不是 0.333...，是精确的分数对象
(+ 1/3 1/3)         ; => 2/3
(* 1/3 3)           ; => 1          整除回整数，零误差
(double 1/3)        ; => 0.3333333333333333   要浮点时显式转
(/ 4 6)             ; => 2/3        自动约分
```

整数除不尽就升比值——这是**默认精确**的设计。对照：`(/ 1.0 3)` 直接走 double，有舍入。要精确就用整数/比值运算，出口处再 `double`。

### 溢出与自动升位

```clojure
(+ Long/MAX_VALUE 1)     ; ArithmeticException: integer overflow —— 默认抛错，静默回绕不存在
(+' Long/MAX_VALUE 1)    => 9223372036854775808N   撇号版自动升 BigInt
(*' 99999999N 99999999N) ; => 9999999800000001N    大数乘法
(inc' 0)                 ; => 1（普通值也兼容）
```

规则：**默认检查溢出并抛异常**（比 C/Java 的静默回绕安全）；`+' *' -' inc'` 是"自动升位"版。`(set! *unchecked-math* true)` 换取原始速度（23 章）。

### `=` 与 `==`

```clojure
(= 1 1.0)     ; => false   类型不同就不等（= 对数字也分类型）
(= 1 1N)      ; => true    整数族内部：数值相等即等（1 与 1N 等价）
(== 1 1.0)    ; => true    == 只给数字用：数值相等即等
(< 1 2 3)     ; => true    比较也支持 n 元链
```

## 4.2 关键字：自证身份的常量

```clojure
:name                    ; 简单关键字
:user/name               ; 带命名空间（两个名字段段不同）
::name                   ; 自动补当前命名空间 => :my-ns/name
(:name {:name "Alice"})  ; => "Alice"   关键字可以直接当函数用（取值）
(:missing {} :default)   ; => :default  还能带默认值
```

- 关键字**驻留**（interned）：同名关键字全局同一对象，`=` 即指针比较，O(1)。
- `::` 是防撞车利器——库代码里 `::id` 展开成 `:my-lib/id`，不会污染用户命名空间（spec 大量使用，19 章）。
- **关键字作 map 的键是社区铁律**：可读、可作函数、驻留比较快。字符串键只在"对接外部数据"时出现。

关键字的本质：`(keyword "abc")` 造出 `:abc`；`(namespace :a/b)` → `"a"`。它和符号（symbol，11 章宏的主角）长得像但身份不同——**关键字自求值、代表名字本身；符号要求值、代表它指向的东西**。

## 4.3 字符串与字符

```clojure
"hello\nworld"      ; JVM String，不可变，UTF-16
\a \newline \tab    ; 字符字面量（反斜杠）
(str \a \b)         ; => "ab"
(count "héllo")     ; => 5    但 count 数的是 UTF-16 code unit
```

字符串就是 `java.lang.String`——不可变、`+` 不能拼接（用 `str`）、没有插值（用 `format` 或 `str`）。`clojure.string` 是标准工具箱：`upper-case` `lower-case` `split` `join` `trim` `replace` `starts-with?`。正则是一等字面量：`#"\d+"` 是 `java.util.regex.Pattern`，`(re-find #"\d+" "a42")` → `"42"`。

## 4.4 nil 与真值：只有两个假

```clojure
(if nil :t :f)      ; => :f
(if false :t :f)    ; => :f
(if 0 :t :f)        ; => :t    0 是真！
(if "" :t :f)       ; => :t    空串是真！
(if [] :t :f)       ; => :t    空向量是真！
```

**只有 `nil` 和 `false` 为假**。从 C/Python 来的人在这栽跟头：`(if coll ...)` 判断不了"空集合"——空集合是真。查空要用 `(empty? coll)` 或 `(seq coll)`（10 章讲 `seq` 惯用法）。

`nil` 本身很能干：`(nil? x)` 判断；取值类函数对 nil 容忍——`(:k nil)` → nil、`(get nil :k)` → nil、`(first nil)` → nil——这条"nil 导航"特性让 `(-> m :a :b :c)` 链路天然防空（但真要防空短路用 `get-in`/`some->`，09 章）。

## 4.5 布尔与 NaN

```clojure
(true? true)         ; => true   严格判 true
(not= 1 2)           ; => true
(Double/isNaN ##NaN) ; => true
(= ##NaN ##NaN)      ; => false！  NaN 不等于自己（IEEE 754，所有语言同款）
```

`##NaN` / `##Inf` / `##-Inf` 是 reader 字面量。排序含 NaN 的数据要有心理准备。

## 4.6 类型检查与转换

```clojure
(int? 42) (string? "a") (keyword? :k) (map? {}) (vector? []) (seq? '(1)) (coll? #{} nil?)
(class 3.14)                  ; => java.lang.Double   任何值的运行时类型
(instance? String "a")        ; => true
(int 3.99) (long 3.99)        ; => 3   截断不是四舍五入
```

`(class x)` 是 REPL 里的"这是什么"按钮——Clojure 没有静态类型挡你，出问题先问 class。

## 4.7 坑位清单

1. **`0` / `""` / `[]` 是真值**：判空用 `(seq coll)` / `(empty? coll)`，别拿 `if` 硬判。
2. **`(/ 1 3)` 不是 0.33**：管线里混进一个 Ratio，下游 Java 库会不认识——出口处 `double` 收口。
3. **`(+ Long/MAX_VALUE 1)` 抛异常**：可能溢出的路径用 `+'`，或 BigInt 字面量 `N`。
4. **钱的计算用 double 是事故**：`(+ 0.1 0.2)` → `0.30000000000000004`；用 `M` 后缀的 BigDecimal 或整数分。
5. **`(= 1 1.0)` 是 false**：跨类型比较数字用 `==`；map 键 `1` 和 `1.0` 是两个键。
6. **`(count "😀")` 是 2**：UTF-16 代理对；要"用户视角字符数"用 `(.codePointCount "😀" 0 2)`（实测 => 1），或 `#'clojure.core/count` 前先归一化（NFC）。
7. **`::k` 在 REPL 与文件里展开不同**：当前 `*ns*` 决定前缀，跨命名空间传数据时打印出来对不上——数据里老实用 `:full/ns/keyword`。

---

上一章：[03 Hello World](03-hello.md) · 下一章：[05 集合](05-collections.md)
