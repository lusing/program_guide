# 21 · 经典算法

> 对应示例：`examples/19_algorithms.clj`

> 用函数式写一遍经典算法：排序、查找、递推、筛法、图算法。
> 目的不是背算法，而是看**"不可变数据 + 递归 + 惰性"如何重塑算法的形状**——
> 快排短得像伪代码，筛法天然惰性。

## 21.1 函数式快排：三路分区

```clojure
(defn quicksort [coll]
  (when-let [p (first coll)]
    (let [rest (rest coll)]
      (concat (quicksort (filter #(< % p) rest))
              [p]
              (quicksort (filter #(>= % p) rest))))))

(quicksort [3 1 4 1 5 9 2 6])       ; => (1 1 2 3 4 5 6 9)
```

 Haskell 教科书同款两路版有个隐藏退化：大量重复元素时（`>=` 一边）递归深度 O(n)。**三路分区版**把"等于基准"单独放中间，重复元素不再进递归：

```clojure
(defn quicksort-3way [coll]
  (lazy-seq
   (when (seq coll)
     (let [pivot (first coll)
           resto  (rest coll)
           smaller (filter #(< % pivot) resto)
           equal   (filter #(= % pivot) resto)
           larger  (filter #(> % pivot) resto)]
       (concat (quicksort-3way smaller)
               (cons pivot equal)          ; ← pivot 必须并回 equal！
               (quicksort-3way larger))))))

(quicksort-3way [3 1 2 3 1 2 3 3])   ; => (1 1 2 2 3 3 3 3)
```

> 实测事故存档：本示例初版漏了 `(cons pivot equal)`——`equal` 只含 rest 里的重复项，**每一层递归都把 pivot 弄丢**，`[3 1 2 3 1 2 3 3]` 排成 `[1 2 3 3 3]`（8 个进 5 个出）。程序不报错、标记正常打印——"跑完"和"排对"是两回事，`(#(= (sort x) (f x)) data)` 这类**对账断言**才是算法测试的底线。

**函数式排序的代价观**：非原地（每次 filter/concat 造新 seq）、空间 O(n log n)——换来的是"没有下标越界、没有 swap 顺序、可并行（两半独立）"。生产排序用内建 `sort`（合并排序，Java 数组底层）；这里写快排是为了**读形状**。

## 21.2 归并排序：reduce 收尾

```clojure
(defn merge-sorted [a b]
  (lazy-seq                                        ; 惰性合并：流式消费
    (cond
      (empty? a) b
      (empty? b) a
      :else (let [[x & xs] a, [y & ys] b]
              (if (<= x y)
                (cons x (merge-sorted xs b))
                (cons y (merge-sorted a ys)))))))

(defn merge-sort [coll]
  (if (< (count coll) 2)
    coll
    (let [mid (quot (count coll) 2)
          [l r] (split-at mid coll)]               ; 不可变切半
      (merge-sorted (merge-sort l) (merge-sort r)))))

(merge-sort [5 2 8 1 9 3])          ; => (1 2 3 5 8 9)
```

Clojure 内建 `sort` 就是 merge-sort 家族——这也是它**稳定**（相等元素保序）的原因。

## 21.3 二分查找：loop/recur 的标准姿势

```clojure
(defn binary-search [v target]
  (loop [lo 0, hi (dec (count v))]
    (if (> lo hi)
      -1                                            ; 未找到
      (let [mid (quot (+ lo hi) 2)
            x (nth v mid)]
        (cond
          (= x target) mid
          (< x target) (recur (inc lo) mid)         ; 注意：只改一侧边界
          :else      (recur lo (dec mid)))))))

(binary-search [1 3 5 7 9 11] 7)    ; => 3
```

要点：`loop` 绑定就是"循环变量"，`recur` 只更新变化的那一侧；`(quot (+ lo hi) 2)` 防溢出写法（long 世界的纪律）。**前提：序列有序**——`sorted-vec`（05 章）出来的数据直接可用。

## 21.4 斐波那契三连：同一段递推的三种代价

```clojure
(defn fib-naive [n]                       ; O(φ^n)：教学反面教材
  (if (< n 2) n (+ (fib-naive (- n 1)) (fib-naive (- n 2)))))

(def fib-memo (memoize fib-naive))        ; 记忆化：O(n) 时间 + O(n) 空间
(fib-memo 80)                             ; 瞬间

(defn fib-iter [n]                        ; 迭代：O(n) 时间 O(1) 空间（正解）
  (loop [i 0, a 0N, b 1N]                 ; 0N：BigInt 起步，免溢出心智负担
    (if (= i n) a (recur (inc i) b (+ a b)))))

(take 10 (map first (iterate (fn [[a b]] [b (+ a b)]) [0 1])))   ; 惰性序列版（10 章）
```

`memoize`（23 章实测 546 倍）把指数爆炸压成线性——但注意缓存常驻内存；迭代版连缓存都不要。

## 21.5 埃氏筛：惰性的主场

```clojure
(defn primes-up-to [n]
  (loop [sieve (set (range 2 (inc n))), p 2]
    (if (> (* p p) n)
      (sort sieve)
      (recur (remove #(zero? (mod % p))  ;; 筛掉 p 的倍数
                     (disj sieve p))      ;; p 保留，从筛子里拿出来
             (inc p)))))

(primes-up-to 30)     ; => (2 3 5 7 11 13 17 19 23 29)

(defn prime? [n] (> 2 (count (filter #(zero? (mod n %)) (range 2 n)))))  ; 试除版（教学）
```

**惰性无限素数流**（进阶形状，10 章 lazy-seq + 20 章 transducer 的合奏）：

```clojure
(def primes
  (fn primes []                          ; (def primes (primes)) 版本见示例
    ((fn step [candidates]
       (lazy-seq
        (when-let [p (first candidates)]
          (cons p (step (remove #(zero? (mod % p)) candidates))))))
     (iterate inc 2))))
(take 10 primes)     ; => (2 3 5 7 11 13 17 19 23 29)
```

## 21.6 拓扑排序：Kahn 算法

```clojure
(defn topo-sort [edges]                  ; edges: #{[前驱 后继]}，如 #{[:a :b]}
  (loop [edges edges
         todo (set (concat (map first edges) (map second edges)))
         out []]
    (let [;; 入度为 0：从不作为"后继"出现的节点
          no-dep (sort (remove (set (map second edges)) todo))]
      (cond
        (empty? todo)  out
        (empty? no-dep) :cycle!          ; 剩下的节点互相依赖 → 有环
        :else (recur (remove #(contains? (set no-dep) (first %)) edges)
                     (remove (set no-dep) todo)
                     (into out no-dep))))))

(topo-sort #{[:html :css] [:css :js] [:js :deploy] [:html :deploy]})
; => (:html :css :js :deploy)    —— 构建顺序
(topo-sort #{[:a :b] [:b :a]})           ; => :cycle!
```

集合运算（05 章 `set` + `remove` + `contains?`）表达"入度为零"——不需要邻接表下标。**坑位存档**：如果每轮的节点集从"剩余边"重算，最后一批无后继的节点（示例的 `:deploy`）会在边清空时跟着消失——所以要单独维护 `todo` 集合。

## 21.7 Dijkstra：reduce 驱动的主循环

```clojure
(defn dijkstra [graph start]              ; graph: {:a {:b 3 :c 7}} 无负权
  (let [nodes (set (concat (keys graph) (mapcat keys (vals graph))))
        init  (into {} (for [n nodes] [n ##Inf]))]     ; 全部初始化为无穷远
    (loop [dist (assoc init start 0), unvisited nodes]
      (if (empty? unvisited)
        dist
        (let [cands (filter #(not= ##Inf (dist %)) unvisited)]   ; 只挑可达的
          (if (empty? cands)
            dist                          ; 剩下的不可达，提前收工
            (let [u  (apply min-key dist cands)       ; 可达者中距离最小
                  du (dist u)]
              (recur (reduce (fn [d [v w]]            ; 松弛所有邻居
                               (update d v min (+ du w)))
                             dist (get graph u))
                     (disj unvisited u))))))))

(dijkstra {:a {:b 3 :c 7} :b {:c 1} :c {}} :a)
; => {:a 0, :b 3, :c 4}     a→b→c 比 a→c 短
```

**为什么先灌 `##Inf`**：`(apply min-key dist unvisited)` 里 map 缺键时 `(dist u)` 是 nil，`min-key` 比较 nil 直接 NPE——不可达节点必须有个可比较的"距离"（教学版用 `##Inf` 占位 + 过滤；生产版用优先队列）。`(update d v min (+ du w))` 是"松弛"的直译。

## 21.8 函数式算法的三条心法

1. **变换而非修改**：每步的数据变换（filter/merge/update）描述"下一状态长什么样"，不用描述"怎么原地改"。
2. **递归 + recur 替代下标循环**：循环变量进 `loop` 绑定，边界条件进 `if` 出口。
3. **惰性要边界**：无限流（primes）配 `take`，有限收集用 `into`/`vec` 收口。

## 21.9 坑位清单

1. **教学快排的性能陷阱**：重复元素多的数据用两路版退化为 O(n²)——三路分区（21.1）或直接 `sort`。
2. **`(sort sieve)` 返回 seq 不是 set**——去重/查找语义变了要心里有数。
3. **BigInt 从第一层就要**：`fib` 用 long 到 fib 92 溢出；`0N`/`+'` 提前上保险（04 章）。
4. **`(mod n 2)` 对负数**：`(mod -3 2)` => 1（mod 总带除数符号的"地板"语义）；要 C 语义用 `rem`。
5. **Dijkstra 的 `min-key` 吃 map**：节点不在 dist 里（不可达）时 `apply min-key` 抛异常——图不连通要先过滤 `(filter dist unvisited)`。
6. **memoize 的缓存永不过期**：参数域无限增长的调用（如用户输入的字符串）会撑爆内存——限定参数域或用 LRU。

---

上一章：[20 Transducer](20-transducers.md) · 下一章：[22 综合实战：成绩分析管线](22-project.md)
