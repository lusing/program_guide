# 13 · 记录与协议

> 对应示例：`examples/11_records_protocols.clj`

> 90% 的场景用 map/vector 就够了（"数据优先"）；当你需要**按类型分发**的
> 高性能多态时，上 defprotocol + defrecord——Clojure 版的"接口 + 实现类"，
> 但实现可以事后挂到已有类型上。

## 13.1 defrecord：带字段的不可变"类型化 map"

```clojure
(defrecord Person [name age])

(->Person "Alice" 30)                 ; 位置构造 => #user.Person{:name "Alice", :age 30}
(map->Person {:name "Bob" :age 25})   ; map 构造（缺失字段为 nil）——接数据管线友好
(->P ...) 缩写：REPL 里 #p/ 打印不友好时用 (pr-str p)
```

记录**首先是 map**：关键字访问、解构、`assoc`、`count`、seq/`into` 全部可用：

```clojure
(def p (->Person "Alice" 30))
(:name p)                             ; => "Alice"
(:nick p)                             ; => nil
(assoc p :email "a@x.com")            ; 附加字段进"扩展 map"区，还是 Person
(dissoc p :email)                     ; 去扩展字段，还是 Person
(dissoc p :name)                      ; 删**声明字段** → 退化为普通 map！（身份丢失）
```

与 map 的差别就三条：

| | 普通 map | record |
|---|---|---|
| 类型 | 统一 `PersistentArrayMap/HashMap` | 每种 record 一个 Java 类 |
| 字段访问 | 哈希查找 | **编译成字段读取**（快） |
| 参与协议/类型分发 | 按其接口 | **按它的类**（13.2 的意义所在） |

**什么时候用 record**：要按类型走协议分发（下节）；或同一结构海量实例要省内存提速。否则 map 更灵活（数据形状随便变）。

## 13.2 defprotocol：类型分发的方法表

```clojure
(defprotocol Shape
  (area [this])
  (perimeter [this]))

(defrecord Circle [r]
  Shape                                ; Circle 实现 Shape（就地声明）
  (area [_] (* Math/PI r r))
  (perimeter [_] (* 2 Math/PI r)))

(defrecord Rect [w h]
  Shape
  (area [_] (* w h))
  (perimeter [_] (* 2 (+ w h))))

(map area [(->Circle 1) (->Rect 3 4)])     ; => (3.14159... 12)   一个 area，两种行为
```

协议 = **按第一个参数的类型查方法表**。比多方法（12 章）快，因为不用跑分发函数；比分发 Java 接口灵活，因为**实现可以事后挂**。

## 13.3 extend-type / extend-protocol：给已有类型挂实现

record 定义时实现只是路径之一；**已有类型**（包括 Java 类和 nil！）也能挂：

```clojure
(defprotocol Stringifiable (to-s [x]))

(extend-protocol Stringifiable          #_:schema 每个"分号段落"一个类型
  java.lang.String
  (to-s [s] s)

  java.lang.Long
  (to-s [n] (str "Number: " n))

  nil                                   ; 连 nil 都能参与分发！
  (to-s [_] "<nothing>"))

(map to-s ["hi" 42 nil])                ; => ("hi" "Number: 42" "<nothing>")
```

`extend-type` 是"一个类型挂多个协议"，`extend-protocol` 是"一个协议挂多个类型"——同一枚硬币的两面，按"新增的方向"选（加类型用前者，加协议用后者）。

**nil 参与分发**是 Clojure 协议设计的神来之笔：`nil` 走 `nil` 实现，不再 NPE——`to-s` 对任何输入都有答案。

## 13.4 reify：匿名一次性实现

```clojure
(defn make-greeter [greeting]           ; reify 捕获闭包变量 greeting
  (reify Shape
    (area [_] 42)
    (perimeter [_] 0)))

(defn make-counter-shape [n]
  (reify
    clojure.lang.IDeref
    (deref [_] n)))
```

`reify` = "实现协议的匿名对象"（≈ Java 匿名内部类 / lambda），**能闭包捕获局部变量**——record 做不到（record 字段是显式的）。一次性回调、测试替身（stub/fake）的高频工具。

## 13.5 deftype：协议的裸金属兄弟

```clojure
(deftype Point [^long x ^long y])       ; 无 map 行为：字段就是字段，可加 ^long 原生提示
```

`deftype` 不装 map（无关键字访问），字段可声明可变（`:volatile-mutable true`）、可给原生类型提示——**语言内部设施**（`core.async` 的 channel、transient 都靠它）。应用层几乎总是 record/map，deftype 留给"写库"。

## 13.6 检查与内省

```clojure
(instance? Person (->Person "A" 1))     ; => true    Java 层面判断
(satisfies? Shape (->Circle 1))         ; => true    协议层面判断
(extenders Shape)                       ; 已扩展的类型列表
(:name p)                               ; record 字段访问与 map 同形
```

## 13.7 坑位清单

1. **`dissoc` 声明字段 → record 退化成 map**：协议方法随之失效（类型变了）。附加信息放扩展区（assoc），声明字段不动。
2. **record 与普通 map 的 `=` 是 false**（实测！）：`(= (->Person "A" 1) {:name "A" :age 1})` => false——record 的相等是**类型敏感**的（同名 record 之间按内容比，与裸 map 不比）。字段访问/解构行为与 map 一致，但**相等性不互通**：record 存进 set 再用 map 查会 miss；跨边界比较先统一成同一种形态（`(into {} record)` 或两边都 map->T）。
3. **`->T` 位置构造易错位**：字段多了靠猜。数据入口统一 `map->T`（还能吃部分字段）；`->T` 只在字面量处用。
4. **record 实现的协议方法里访问"扩展 map"字段**没有编译期优化（还是哈希查找）——热点字段声明成 record 字段。
5. **协议方法名不要与 core 撞车**：`defprotocol Collection (count [this])` 会遮蔽/冲突——社区惯例加前缀（`shape-area`）或用 ns 限定调用。
6. **reify 实现不了 record 的"数据性"**：reify 对象不是 map，`:keys` 解构拿不到东西——它是纯行为对象。
7. **协议是"单参数类型分发"**：第二个参数的类型不参与（那是多方法的主场，12 章）。

---

上一章：[12 多方法](12-multimethods.md) · 下一章：[14 并发与引用类型](14-concurrency.md)
