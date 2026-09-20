# 23 · 性能与优化 ⭐

> 对应示例：`examples/21_performance.clj`（OpenJDK 26 实测，看倍数不看绝对值）

> Clojure 默认"够快"。优化前先记住三条军规：**先测量**、
> **反射是头号大盗**、**装箱是二号大盗**。本章每条都有实测数字。

## 23.1 先测量：time + JIT 预热

JVM 分层编译：先解释执行 → C1（快编译浅优化）→ C2（慢编译深优化）。**不预热的基准测的是解释器**，结论全错：

```clojure
(dotimes [_ 3] (bench-sum 100000))     ; 预热：触发 C2
(time (bench-sum 1000000))             ; "Elapsed time: 4.3 msecs"
```

`time` 是 REPL 快测；认真基准用 `criterium` 库（自动预热 + 多轮 + 方差），别拿单次 `time` 做决策。

## 23.2 反射 vs 类型提示：实测 537 倍 ⭐

动态类型意味着 `(.length s)` 编译期常常不知道 `s` 是什么——只能运行时反射查方法。打开警告让它们现形：

```clojure
(set! *warn-on-reflection* true)      ; 编译期打印所有反射点（dev 常开）

(defn len-reflect [s] (.length s))            ; Reflection warning ...
(defn len-hint ^long [^String s] (.length s)) ; 直接 invokevirtual
```

实测（200 万次调用）：反射 **2281ms**，提示后 **4.3ms** —— **537 倍**。

提示加在哪：

```clojure
(defn f ^long [^String s] ...)        ; 返回值提示 + 参数提示
(let [^String s (get-name)] ...)      ; 局部绑定提示
(defn g [^longs arr] ...)             ; 数组提示（15 章）
```

**纪律**：`project.clj` 的 dev profile 全局开 `*warn-on-reflection*`（26 章的 lein-lab 就这么配的），警告逐个消灭；生产代码零反射警告是可达成的正常状态。

## 23.3 装箱与原始数学：实测 5 倍

数字默认是装箱的 `Long` 对象（堆分配 + 拆箱算术）。热循环三件套：`^long` 参数 + 原始初值 + `unchecked-*`：

```clojure
(defn sum-boxed [n]                        ; 装箱版（安全 + 检查溢出）
  (loop [i (long 0) acc (long 0)]
    (if (= i n) acc (recur (inc i) (+ acc i)))))

(defn sum-primitive [^long n]              ; 原始版
  (loop [i 0 acc 0]
    (if (= i n) acc
        (recur (unchecked-inc i) (unchecked-add acc i)))))
```

实测百万次求和：装箱 33ms → 原始 6ms。注意：

- `loop` 绑定初值是字面量 `0` 时 local 已是原始 long——装箱主要发生在**函数参数**和跨调用边界。
- `unchecked-*` 静默溢出（04 章）——只用于确知范围的循环。
- `(set! *unchecked-math* true)` 全局切换（编译期生效）。

## 23.4 transient：实测 2 倍的批量构建

百万次 `conj` 持久 vector：23.8ms；同数量 `conj!` 瞬态：12.4ms：

```clojure
(def v (persistent! (reduce conj! (transient []) (range 1000000))))
```

语义不变（不可变进、不可变出），中间少分配。适用条件：**单线程批量构建**（reduce/loop 收尾一次 `persistent!`）；中途读、跨线程共享都是错——transient 不是"可变集合给你用"，是"构建期优化"。

map 同款：`(persistent! (reduce (fn [t [k v]] (assoc! t k v)) (transient {}) pairs))`。

## 23.5 Java 数组：实测 26 倍

求和百万元素：`reduce +` 向量 221ms，`areduce` 数组 8.3ms：

```clojure
(defn sum-array ^long [^ints a]
  (areduce a i ret (long 0) (unchecked-add ret (aget a i))))
```

细节（15 章 + 实测坑）：

- `areduce`/`amap` 是编译宏；**吃 `def` 出来的 var 拿不到类型会反射**——先绑定 `^ints` 局部。
- `int-array`/`long-array`/`doubles` 造原生数组；`(vec arr)` 回 Clojure 世界。
- `(vector-of :int ...)` 未装箱 vector：折中方案（seq 接口 + 存储未装箱）。

## 23.6 memoize：实测 546 倍

```clojure
(defn slow-square [x] (Thread/sleep 2) (* x x))
(def fast-square (memoize slow-square))
;; 首轮（冷缓存）93ms；二轮（全命中）0.17ms
```

适用判据（三条全中才值）：**纯函数** + 参数可哈希 + 参数域有限。参数域无限的调用（任意字符串）会撑爆缓存。

## 23.7 字符串与杂项

- 循环 `(str acc x)` 是 O(n²)——`StringBuilder` / `str/join` / `(apply str coll)`。
- `format` 比 `str` 慢一个量级——热路径用 `str`，可读性优先用 `format`。
- 大 map 频繁 `assoc` 单键：考虑 `transient`（23.4）或换 `java.util.HashMap` + 收口（最后转回）。
- `pmap` 只在任务粒度够大时赚（14 章）；小任务调度开销倒贴。

## 23.8 优化决策树

```
慢？（criterium 确认）
 ├─ 反射警告？→ 类型提示（性价比最高，先做这个）
 ├─ 热循环装箱？→ ^long / 原始数组 / unchecked-*
 ├─ 批量构建集合？→ transient
 ├─ 重复计算纯函数？→ memoize
 ├─ 中间序列巨大？→ transducer（20 章）
 └─ 还不够？→ 上数组/Java 段落重写热点（15 章），或接受现状
```

**先 profile 再动手**：`time`/criterium 定位热点，90% 的收益来自前三步；过早优化是时间黑洞（clone 不是耻辱，反射才是）。

## 23.9 坑位清单

1. **预热不足的基准全是噪声**——至少跑几千次再计时；单次 time 只配做"数量级判断"。
2. **`^long` 提示在不匹配时抛错**：传 Double 给 `^long` 参数 → ClassCastException——接口边界（外部输入）别乱标。
3. **`unchecked-math` 全局开的传染性**：第三方代码也被影响——只在 profile/命名空间局部开。
4. **transient 被共享**：把 transient 存进 atom/传来传去 = 语义灾难（单线程构建期产物）。
5. **memoize 吃掉异常语义**：原函数抛异常，memoize 不缓存异常但每次重跑——"看起来好了又没好"。
6. **`amap`/`areduce` 吃 var 触发反射**（23.5 实测坑）——先 `(let [^ints a arr] ...)`。
7. **JMH 才是终审**：微基准的所有坑（死代码消除、逃逸分析）JMH 都处理了——发论文级结论前跑 JMH（via `jmh-clojure`）。

---

上一章：[22 综合实战：成绩分析管线](22-project.md) · 下一章：[24 core.async](24-core-async.md)
