# 22 · 综合实战：成绩分析管线

> 对应示例：`examples/20_project.clj`

> 一个完整的数据管线：CSV 进 → 报告出。前 21 章的工具箱在这里
> 总装：解构、高阶函数、spec、聚合、EDN。**"数据从管线流过"**
> 是 Clojure 日常工作的典型形状。

## 22.1 需求与形状

输入（CSV 文本，成绩 0-100，科目任意）：

```text
101,Alice,Math:90,Physics:85
102,Bob,Math:55
103,Cara,Math:77,English:92,Art:60
```

输出：每个学生的均分/评级 + 各科统计 + EDN 报告落盘。

**管线设计**——先把形状画出来，每一步的输入输出都是普通数据：

```
CSV 文本 --parse--> 学生 map 序列 --validate--> 合法序列
         --enrich--> 带均分/评级 --aggregate--> 科目统计
         --report--> 文本 + EDN
```

## 22.2 数据建模：map 而不是类

```clojure
(defn make-student [id name grade & subjects]   ; subjects: ["Math:90" ...]
  {:id (parse-long id)
   :name name
   :grade grade
   :subjects (parse-subjects subjects)})

(defn parse-subjects [pairs]
  (into {}                                   ; ["Math:90"] -> {:Math 90}
        (map (fn [s]
               (let [[k v] (str/split s #":")]
                 [k (parse-long v)])))
        pairs))

(defn parse-csv-line [line] (str/split line #","))

(defn parse-csv [csv-text]
  (->> (str/split csv-text #"\n")            ; 09 章线程宏铺开
       (map str/trim)
       (remove empty?)
       (map parse-csv-line)
       (map #(apply make-student %))))
```

`(into {} (map f) coll)` 是 **transducer 收集**（20 章）——`map` 直接嵌进 `into`。

## 22.3 验证：边界处把关

```clojure
(defn validate-student [{:keys [id name subjects] :as s}]
  (cond
    (nil? id)      {:ok false :error "id 缺失/非数字" :data s}
    (empty? name)  {:ok false :error "名字为空" :data s}
    (some #(or (nil? %) (not (< 0 % 100))) (vals subjects))
                   {:ok false :error "分数越界" :data s}
    :else          {:ok true :data s}))

;; 管线里分流：合法的继续，非法的收集报告
(let [{goods true, bads false} (group-by :ok (map validate-student students))]
  ...)
```

`(group-by :ok ...)` 一行完成"分流"（09 章）——没有 if/continue 循环，**分流也是数据变换**。（生产级边界用 spec，19 章。）

## 22.4 富化：每条数据变胖一步

```clojure
(defn student-average [{:keys [subjects]}]
  (if (empty? subjects) 0 (/ (reduce + (vals subjects)) (count subjects))))

(defn enrich-student [s]
  (let [avg (student-average s)]
    (assoc s
           :average avg
           :grade-level (cond (>= avg 90) :A (>= avg 80) :B (>= avg 70) :C :else :D))))

(map enrich-student goods)          ; 每个学生 map 长出 :average/:grade-level
```

`assoc` 长出新字段（05 章）——"富化"就是 map 的自然生长。

## 22.5 聚合：group-by 双子星

```clojure
(defn subject-stats [students]
  (->> students
       (mapcat :subjects)                        ; {:Math 90} 展平成 Entry 流
       (group-by key)                            ; 按科目分组
       (map (fn [[subject entries]]
              {:subject subject
               :count (count entries)
               :average (/ (reduce + (map val entries)) (count entries))}))
       (sort-by :average >)))
```

`mapcat` 摊平 + `group-by` 分组 + map 整形——**报表逻辑四行**。这就是 09 章说的"两行完成统计报表"的实貌。

排名（并列同名次）：

```clojure
(defn rank-students [students]
  (->> students (sort-by :average >)
       (map-indexed (fn [i s] (assoc s :rank (inc i))))))
```

## 22.6 报告：pr-str 落盘

```clojure
(defn generate-edn-report [students stats]
  {:generated-at (java.time.Instant/now)
   :total (count students)
   :average-of-averages (/ (reduce + (map :average students)) (count students))
   :subject-stats stats
   :students students})

(spit "report.edn" (pr-str (generate-edn-report ranked stats)))
;; 下游随时 (edn/read-string (slurp "report.edn")) 无损拿回（16 章）
```

## 22.7 总装：analyze-students

```clojure
(defn analyze-students [csv-text]
  (let [students (parse-csv csv-text)
        {goods true, bads false} (group-by :ok (map validate-student students))
        enriched (map (comp enrich-student :data) goods)
        stats    (subject-stats enriched)
        ranked   (rank-students enriched)]
    {:valid (count enriched)
     :invalid (count bads)
     :errors (map :error bads)
     :stats stats
     :ranked ranked}))
```

**每一步的输出都是下一步的输入**，`analyze` 只是"命名每一段"——这是管线的全部结构。改需求（加科目、改评级线）只动对应的一个小函数。

## 22.8 设计复盘：用到了哪些章

| 环节 | 技术 | 章 |
|---|---|---|
| 解析 | `->>` 线程宏、`map`/`remove` | 09 |
| 建模 | map/`into` + transducer | 05/20 |
| 分流 | `group-by :ok` | 09 |
| 富化 | `assoc`、`cond` 评级 | 05/07 |
| 聚合 | `mapcat`/`group-by`/`sort-by` | 09 |
| 落盘 | `pr-str`/`spit`/EDN | 16 |
| （升级路径） | spec 验证、core.async 并行分片 | 19/24 |

## 22.9 坑位清单（管线设计常见病）

1. **中间数据"变格式"太多次**：map → vector → map 来回倒腾是设计味道——定一个"主形状"（学生 map）贯穿全程。
2. **异常混进管线**：`parse-long` 对脏数据返回 nil，后面 `(+ nil 1)` 才炸——**解析处就地标记**（validate-student），别让 nil 往下游漂。
3. **`/` 除零**：`(average [])` 没防护——空集合在入口处过滤或给哨兵值。
4. **浮点均分比较**：`(= 85.0 (/ 170 2))` 分数比值与 double 混比——统一在出口 `double`（04 章）。
5. **CSV 手撕只适合教学**：引号/转义/多行字段要用 `clojure.data.csv` 库（27 章）——手撕版处理不了 `"a,b"` 字段。
6. **`Instant/now` 进报告影响测试**——固定时钟注入或测试里忽略该字段。

---

上一章：[21 经典算法](21-algorithms.md) · 下一章：[23 性能与优化](23-performance.md)
