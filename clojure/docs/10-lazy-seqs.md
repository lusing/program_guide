# 10 · 惰性序列 ⭐

> 对应示例：`examples/08_lazy_seqs.clj`

> Clojure 序列默认**按需生产**——`map` 不立刻算完，`range` 可以没有尽头。
> 惰性是 Clojure 表达力的半壁江山（无限序列、大文件流式处理），
> 也是内存泄漏的头号现场（头部驻留）。

## 10.1 惰性是什么意思

```clojure
(def xs (map inc (range 1000000)))    ; 瞬间返回 —— 一个元素都还没算！
(realized? xs)                        ; => false
(take 3 xs)                           ; => (1 2 3)   只算需要的
```

`map` 返回的是 **LazySeq**：一个"承诺"。你 `take`/`first` 时才生产对应元素；生产过的部分**缓存**（第二次 `take` 不重算）。

```clojure
(def naturals (iterate inc 0))        ; 无限序列！
(take 5 naturals)                     ; => (0 1 2 3 4)
(drop 1000000 naturals)               ; => 惰性的，仍然瞬时
(nth naturals 10)                     ; => 10
```

**"无限"能当值用**是惰性的直接红利：定义时不管多长，消费多少生产多少。

## 10.2 生成器全家

| 函数 | 语义 | 例 |
|---|---|---|
| `(range)` | 0,1,2,… 无限 | `(take 3 (range))` → (0 1 2) |
| `(range 5)` `(range 1 10 2)` | 有限/步进 | (0 1 2 3 4) / (1 3 5 7 9) |
| `(iterate f x)` | x, (f x), (f (f x))… | `(take 4 (iterate #(* 2 %) 1))` → (1 2 4 8) |
| `(repeat 3 :x)` `(repeat :x)` | 重复 n 次 / 无限 | (:x :x :x) |
| `(cycle [1 2])` | 无限循环 | (1 2 1 2 …) |
| `(repeatedly #(rand-int 10))` | 反复调 thunk | 无限随机流 |

经典斐波那契（iterate + 解构）：

```clojure
(take 10 (map first (iterate (fn [[a b]] [b (+ a b)]) [0 1])))
; => (0 1 1 2 3 5 8 13 21 34)
```

## 10.3 消费控制

```clojure
(take 5 xs)          ; 前 n 个          (take-while neg? [-2 -1 0 -3])  => (-2 -1)
(drop 5 xs)          ; 跳过 n 个        (drop-while neg? [-2 -1 0])    => (0)
(take-nth 3 xs)      ; 每 3 取 1
(take-last 2 xs)     ; 末尾（要走到头）
(split-at 3 xs)      ; [前3 其余]
```

**急切化**（把惰性"压实"）：

```clojure
(doall xs)           ; 全部实现，返回 seq（要拿结果时）
(dorun xs)           ; 全部实现，返回 nil（只要副作用时——省去保持结果的内存）
(vec xs) (into [] xs) ; 转具体集合本身就是实现
```

`dorun` vs `doall`：同样走完全程，前者丢结果更省——副作用循环 `(dorun (map prn xs))`。

## 10.4 lazy-seq：自己造惰性

```clojure
(defn naturals
  ([] (naturals 0))
  ([n] (lazy-seq (cons n (naturals (inc n))))))     ; 核心：cons 一个元素 + 递归的 lazy-seq

(take 5 (naturals 10))                ; => (10 11 12 13 14)

(defn fibs [a b]
  (lazy-seq (cons a (fibs b (+ a b)))))
(take 8 (fibs 0 1))                   ; => (0 1 1 2 3 5 8 13)

(defn file-lines [rdr]
  (lazy-seq
   (when-let [line (.readLine rdr)]   ; 读一行
     (cons line (file-lines rdr)))))  ; 用到才读下一行 —— 流式大文件
```

模板：`(lazy-seq (cons 头 (递归 尾)))`。**惰性里的递归不占栈**——`lazy-seq` 把递归切成一小块一小块，消费时逐块执行。副作用（读文件）放 lazy-seq 里要小心消费时机（10.6 的坑 4）。

## 10.5 for：列表推导

```clojure
(for [x [:a :b] y [1 2]] [x y])          ; 笛卡尔积
; => ([:a 1] [:a 2] [:b 1] [:b 2])

(for [x (range 10) :when (even? x)] x)   ; :when 过滤
; => (0 2 4 6 8)

(for [x (range 10) :while (< x 5)] x)    ; :while 触界即停（之后的绑定层不再走）
; => (0 1 2 3 4)

(for [x (range 3) :let [x2 (* x x)]] x2) ; :let 中途绑定
; => (0 1 4)
```

`:when` vs `:while`：when 是"跳过这个"；while 是"这一层到此为止"。`for` 返回惰性 seq——它是 `map`+`filter`+嵌套循环的语法糖，二维组合优先用 `for`。

## 10.6 chunking：惰性的批量实现

实现细节但影响行为：`map`/`filter`/`range` 等**chunked seq**（一次生产 32 个）：

```clojure
(def n (atom 0))
(def xs (map (fn [x] (swap! n inc) x) (range)))   ; 0 个副作用（还没消费）
(take 3 xs)                                         ; 仍然 0 个！take 也只是建 lazy
(pr-str (take 3 xs))                                ; 消费 3 个 → @n 变成 32！
```

实测：消费 1 个元素，`@n` 是 **32**（整块 chunk 被生产）。副作用在管线里时会被"多跑一截"——纯函数管线无所谓；副作用敏感的代码把 `map` 换成显式 `loop`/`doseq`，或消费侧立刻 `doall` 隔离。

## 10.7 坑位清单

1. **头部驻留（holding onto the head）—— 头号内存泄漏**：
   ```clojure
   (loop [xs (map inc (range 1e7))]     ; 错误示范
     (when (seq xs) (recur (rest xs)))) ; xs 链一直被下一轮引用，1e7 个元素全钉在内存
   ```
   正解：递归时不携带"头"——`(recur (next xs))` 也没救（还是同一根链），要改写为消费式（`doseq`/`reduce`），或让中间变量失效。原则：**长管线别在循环里持有整条 seq**。
2. **`take` 不触发，打印才触发**：REPL 里 `(take 3 (map inc (range)))` 显示前几个是打印行为（`*print-length*` 默认无限但 REPL 通常只实现一部分）；程序里不消费就不算。
3. **副作用 + chunk = 多执行**：上面 10.6。`map` 里的 `prn`/`swap!` 可能跑满 32 个一组。
4. **惰性 seq 里的异常延迟爆炸**：`(def xs (map #(/ 1 %) [1 0 2]))` 定义成功，消费到 0 那一刻才抛——错误现场离案发地点很远。边界数据先验证（19 章）。
5. **`with-open` + 惰性 = use-after-close**：`(with-open [r (reader f)] (line-seq r))` 返回的 seq 在 with-open 结束后才消费 → IOException。文件流要在 with-open 里做实（`doall`）或用 16 章的 reduce-over-lines 模式。
6. **无限 seq 喂给急切函数**：`(count (range))`、`(vec (cycle [1]))`、`(apply max naturals)` 都是挂死——消费端必须有界（take/reduce+reduced）。
7. **`realized?` 只能问"实现过没"**，不能问"多长"——无限 seq 没有 length 概念。

---

上一章：[09 高阶函数](09-higher-order.md) · 下一章：[11 宏与元编程](11-macros.md)
