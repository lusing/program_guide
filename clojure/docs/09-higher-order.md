# 09 · 高阶函数 ⭐

> 对应示例：`examples/07_higher_order.clj`

> `map` / `filter` / `reduce` 三板斧 + 线程宏。Clojure 日常代码的
> 八成是"数据从管线里流过"——本章是那把管钳。

## 9.1 三板斧

```clojure
(map inc [1 2 3])                    ; => (2 3 4)
(map + [1 2 3] [10 20 30])           ; => (11 22 33)   多集合按位并行！
(map + [1 2] [10 20 30])             ; => (11 22)      短的先尽，多出的丢弃

(filter even? (range 10))            ; => (0 2 4 6 8)
(remove even? (range 10))            ; => (1 3 5 7 9)  remove 是反 filter
(filter #(> (:score %) 80) users)    ; 结构化数据照样过

(reduce + [1 2 3 4])                 ; => 10           无初值：首元素起步
(reduce + 100 [1 2 3])               ; => 106          带初值
(reduce (fn [acc x] (if (> x 2) (reduced acc)   ; reduced：提前终止
                     (conj acc x)))
        [] [1 2 3 4])                ; => [1 2]        见到 3 就收手
```

`reduce` 心智模型：`(f (f (f init x1) x2) x3)`——一切"把集合折叠成一个值"的问题（求和、建 map、分组、状态机）都是 reduce。`(reduced x)` 包装器让它能提前退出——无限 seq 上 reduce 必须带它。

## 9.2 map 的亲戚

```clojure
(mapcat reverse [[3 2 1] [6 5 4]])   ; => (1 2 3 4 5 6)   map 后拍扁
(keep #(when (even? %) (inc %)) (range 6))  ; => (1 3 5)  过滤 nil（filter+map 合体）
(some even? [1 3 4])                 ; => true   找到第一个满足的"值"（不是 bool！）
(some :stopped tasks)                ; => 第一个 :stopped 非-nil 的值 —— "查找"惯用法
(every? pos? [1 2])                  ; => true
(not-any? neg? [1 2])                ; => true
```

`some` 返回**第一个真值谓词结果**，配合关键字是"按序查找"神器：`(some #{:stop :cancel} signals)`。

## 9.3 组织函数：comp / partial / juxt / complement

```clojure
((comp str inc) 41)                  ; => "42"    从右往左：先 inc 再 str
(def title-case (comp clojure.string/capitalize clojure.string/trim))

((partial conj #{:a}) :b)            ; => #{:a :b}   预填左参数（06 章）

((juxt :first :last) {:first "A" :last "B"})   ; => ["A" "B"]  多视图一次取
(apply max ((juxt count :age) u))    ; juxt 产出向量，直接喂 apply

((complement even?) 3)               ; => true    反转谓词
```

`juxt` 的直觉："把一个值从多个角度同时观察"——`(juxt min max)`、`(juxt :x :y)`、`(juxt :ok :errors)`。写库时批量导出字段极顺手。

## 9.4 线程宏：管线可读化 ⭐

没有线程宏的嵌套（从里往外读，反人类）：

```clojure
(reduce + (filter even? (map inc (range 10))))
```

**`->>` thread-last**（元素在**最后**——`map`/`filter`/`reduce` 的世界）：

```clojure
(->> (range 10)
     (map inc)
     (filter even?)
     (reduce +))                     ; => 30
```

**`->` thread-first**（元素在**第一**——Java 互操作 `(.method x)` 的世界）：

```clojure
(-> "hello"
    clojure.string/upper-case        ; (clojure.string/upper-case "hello")
    (.replace "L" "1")               ; (.replace "HELLO" "L" "1")
    (subs 0 3))                      ; => "HE1"
```

变体家族：

```clojure
(as-> 40 x                           ; 自己命名占位（位置乱跳时用）
  (inc x) (* x x))                   ; => 1681
(some-> user :addr :city)            ; 任一环 nil → 整体 nil（防空短路）
(cond-> x                            ; 条件为真才把表达式接进管线
  (neg? x) (- x)                     ; 负数取反
  (> x 100) (/ x 100))
(doto (StringBuilder.)               ; 每步都返回原对象（Java builder 风格）
  (.append "a") (.append "b"))
```

**选型直觉**：seq 管线用 `->>`；对象/Java 互操作用 `->`；数据可能中途变 nil 用 `some->`/`get-in`。

## 9.5 分组与切割

```clojure
(group-by even? (range 6))           ; {true [0 2 4], false [1 3 5]}
(group-by :dept users)               ; 按字段分组（高频）
(frequencies "aababc")               ; {\a 3, \b 2, \c 1}
(partition 2 [1 2 3 4 5])            ; ((1 2) (3 4))      丢尾
(partition-all 2 [1 2 3 4 5])        ; ((1 2) (3 4) (5))  留尾
(partition-by pos? [-1 -2 3 4 -5])   ; ((-1 -2) (3 4) (-5)) 值变号处切
(split-at 2 [1 2 3 4])               ; [(1 2) (3 4)]
(split-with neg? [-2 -1 3 -4])       ; [(-2 -1) (3 -4)]   谓词连续真段切割
(interleave [:a :b] [1 2])           ; (:a 1 :b 2)
(interpose ", " ["a" "b"])           ; ("a" ", " "b")
```

`group-by` + `frequencies` 是"两行完成统计报表"的双子星（22 章实战大量使用）。

## 9.6 排序

```clojure
(sort [3 1 2])                            ; (1 2 3)
(sort-by :age users)                      ; 按字段
(sort-by :score > users)                  ; 降序（传比较器）
(sort-by (juxt :dept :salary) users)      ; 多级排序！juxt 产出向量，字典序天然多键
(sort-by #(- %) [1 3 2])                  ; 自定义 keyfn
(compare "a" "b")                         ; -1   通用比较协议（数字/串/向量/关键字）
```

**多级排序的 `(juxt a b)` 技巧**值得单独记：向量按字典序比较——`(sort-by (juxt :dept :salary))` = 先按 dept 再按 salary，无需写比较器。

## 9.7 惯用管线模板

```clojure
; ETL 模板：解析 → 清洗 → 转换 → 聚合
(->> raw-lines
     (map parse-csv-line)
     (filter valid?)
     (map enrich)
     (group-by :dept)
     (map (fn [[dept rows]] {:dept dept :avg (average (map :score rows))}))
     (sort-by :avg >)
     (take 5))
```

**from→to 的心智**：每一环吃上一环的输出形状。写不出下一步时，先 `prn` 中间产物看形状——REPL 工作流（02 章）与管线天然互补。

## 9.8 坑位清单

1. **`map`/`filter` 是惰性的**（10 章）：不消费就没有任何计算发生——`(map prn xs)` 在 REPL 里"不打印"是正常的（只实现 32 个 chunk）。
2. **`reduce` 无初值时空集合抛异常**（`(+ )` 特例返回 0/1 的单位元素，自定义 `f` 不行）——显式给 init。
3. **`sort` 是实时的**（不是惰性），立即排序——无限 seq 进 `sort` 死循环。
4. **`(sort-by :k)` 的 nil 值不炸但会"沉底/冒头"**：`compare` 对 nil 有定义（nil 最小，实测 `(compare nil 1)` => -1），缺 `:k` 的记录全部排最前——顺序出乎意料但合法；要 nil 排最后用 `(sort-by #(or (:k %) ##-Inf))` 或先过滤。
5. **`->` 与关键字**：`(-> m :a)` 合法（关键字当函数），但 `(->> m :a)` 把 m 放最后变 `(:a m 之外的)` ——搞反线程方向是最常见的"类型错误"。
6. **`some` 返回的不是布尔**：`(if (some pred xs) ...)` 能用（真值语义），但别拿它当 `true?` 断言。
7. **`group-by` 的值是 vector**（急切），键无序——要确定性输出再 `(into (sorted-map) ...)`。

---

上一章：[08 解构](08-destructuring.md) · 下一章：[10 惰性序列](10-lazy-seqs.md)
