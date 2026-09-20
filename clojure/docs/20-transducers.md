# 20 · Transducer ⭐

> 对应示例：`examples/18_transducers.clj`

> Transducer = **与数据源无关的转换算法**。`(map inc)` 不再绑定在某个
> 集合上，而是独立存在的"变换"，可复用到 vector、channel、回调流——
> 还省掉中间序列。09 章管线的终极进化。

## 20.1 问题：中间序列的浪费

```clojure
(->> (range 1000000) (map inc) (filter even?) (into []))
```

惰性版每步生成中间 LazySeq：百万元素 × 2 个中间 seq = 大量分配 + chunk
调度。**transduce 版零中间序列**：

```clojure
(into [] (comp (map inc) (filter even?)) (range 1000000))
;; 同样结果；元素直接"流过"变换栈进结果容器
```

## 20.2 本质：转换"归约函数"

一个 transducer 是**吃 reducing 函数、吐 reducing 函数**的函数：

```
(map inc)        实际上是 (rf) -> rf' 的变换器
```

`map`/`filter`/`take` 等的**单参数形态**返回 transducer：

```clojure
(map inc)              ; => #function[transducer]  （不是 seq！）
(filter even?)
(take 3)
(comp (map inc) (filter even?) (take 3))    ; 变换的复合，仍是 transducer
```

双参数 `(map inc coll)` 是老朋友（惰性 seq）；单参数是新世界。**同一个 `map`，两种 arity**。

## 20.3 四个消费入口

```clojure
(def xf (comp (map inc) (filter even?) (take 3)))

(into [] xf (range 100))          ; 1) 收集进集合 => [2 4 6]
(transduce xf + 0 (range 100))    ; 2) 归约：流过的元素直接 + => 12
(sequence xf (range 100))         ; 3) 惰性（要"逐步给"时）
(eduction xf (range 100))         ; 4) 可重放的迭代体（进 reduce/into 二次用）
```

| 入口 | 语义 | 什么时候 |
|---|---|---|
| `into` | 收集 | 90% 场景 |
| `transduce` | 边流边归约 | 求和/计数/建 map |
| `sequence` | 惰性管道 | 下游还要 take/drop |
| `eduction` | 可复用批次 | 同一批变换多处用 |

**channel 入口**（24 章）：`(a/pipeline 4 out xf in)`——同一套 `(map inc)` 在并发世界里无缝复用。

## 20.4 内建 transducer 一览

`map` `mapcat` `filter` `remove` `take` `take-while` `drop` `drop-while` `take-nth` `distinct` `dedupe` `partition-all` `partition-by` `keep` `keep-indexed` `map-indexed` `interpose` `cat` `random-sample` `halt-when`

两个新面孔（注意 `cat` 是**裸函数**直接进 comp，不带括号——它本身就是 rf→rf）：

```clojure
(into [] (comp (partition-all 2) cat) [1 2 3 4])  ; => [1 2 3 4]  cat：把"元素是集合"摊平
(into [] (dedupe) [1 1 2 2 1])                    ; => [1 2 1]   相邻去重
(into [] (comp (partition-all 2) (map reverse)) [1 2 3 4])
; => ([2 1] [4 3])
```

`cat` 是 transducer 王国的 `mapcat` 原料：先 `partition-all` 再 `cat` = 拍平。写 `(cat)` 会报 `Wrong number of args (0) passed to cat`（实测）。

## 20.5 早停：reduced 穿透

```clojure
(into [] (take 3) (range 1e9))     ; 瞬间 [0 1 2] —— take 短路整个管线，源头不再生产
(transduce (halt-when #{:stop}) conj [] [:a :stop :b])
;; => :stop   （实测！halt-when 默认返回"触发值"本身，不是累积结果；
;;             要拿累积结果用 (halt-when p identity) 的二参形态）
```

`(take 3)` 作为 transducer 有"停止整条流水线"的能力——上游 `range 1e9` 也只生产到第 3 个。**这是 transducer 相对惰性 seq 的调度优势**：没有 chunk 边界，说停就停。

## 20.6 有状态 transducer

`dedupe`/`distinct`/`partition-all` 需要**跨元素状态**。用 `comp` 组合时状态在"管道创建时"初始化——所以**一个 transducer 实例不要复用到多个并发源**（状态会串）：

```clojure
(def xf (dedupe))                      ; 有状态！
(into [] xf [1 1 2])                   ; ok
(into [] xf [1 1 2])                   ; "还能用"是巧合——正确姿势是每次 (into [] (dedupe) xs)
```

`completion` 语义：包一层 `(completing rf)` 处理"无 init 调用"（进阶，知道即可）。

## 20.7 自定义 transducer

形状固定：**返回函数，接收 rf，返回包装后的 rf**，三个 arity（0/1/2）：

```clojure
(defn xdouble-odd [rf]                 ; 只对奇数翻倍、偶数丢弃
  (fn
    ([] (rf))                          ; arity-0：完成（透传）
    ([result] (rf result))             ; arity-1：收尾
    ([result input]                    ; arity-2：逐元素
      (if (odd? input)
        (rf result (* 2 input))
        result))))

(into [] xdouble-odd (range 6))        ; => [2 6 10]
(into [] (comp xdouble-odd (take 2)) (range))   ; 组合照旧 => [2 6]
```

读法：`result` 是"下游累积器"，`input` 是流过的元素——你决定**传不传、怎么传给下游 rf**。这就是 `filter`（不传）和 `map`（变了再传）的全部秘密。

## 20.8 性能与选型

| | 惰性 seq（09 章） | transducer |
|---|---|---|
| 中间分配 | 每步一个 LazySeq | 零中间 |
| 提前终止 | chunk 粒度（32） | 元素级 |
| 数据源 | seq 世界 | 集合/channel/回调/迭代器 |
| 可读性 | 管线直观 | 稍抽象 |

**经验法则**：小数据/一次性脚本用惰性 seq（好读）；热路径、大集合、流式 IO、channel 并发用 transducer。写库（给别人提供"变换"）优先 transducer 形态——用户想怎么消费是他家的事。

## 20.9 坑位清单

1. **`(map inc)` 不加集合时"打印不出东西"**——它是变换不是数据；误当 seq 消费会懵。
2. **有状态 transducer 复用**（20.6）：`(def xf (partition-all 2))` 共享给两个 `into` → 状态污染。每次现场 `(comp ...)` 新建。
3. **`comp` 顺序 = 数据流顺序**（先 map 后 filter），与 `->>` 管线的阅读顺序一致——别按"函数复合从右往左"的老直觉倒着写（那是对 `comp f g` 调用序列的规则，这里恰好一致，容易绕晕）。
4. **transduce 的 init 参数**：`(transduce xf + 0 coll)` 中 `0` 是归约初值——忘写会 arity 错（或语义错）。
5. **`sequence` 返回的还是惰性**——以为"转了 transducer 就急切"是误解，要急切用 `into`。
6. **异常穿透管线**：某元素炸了，`into` 直接抛——没有"跳过坏元素"的默认行为；要跳过自己写 try-catch 包装的 transducer。

---

上一章：[19 clojure.spec](19-spec.md) · 下一章：[21 经典算法](21-algorithms.md)
