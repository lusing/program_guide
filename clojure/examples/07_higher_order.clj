;; ==========================================================================
;; 07_higher_order.clj - 高阶函数
;; ==========================================================================
;; 主题：Clojure 的高阶函数与函数式组合
;; 内容：
;;   1. map
;;   2. filter / remove
;;   3. reduce
;;   4. partial / complement
;;   5. comp
;;   6. keep / mapcat
;;   7. sort-by / group-by
;;   8. juxt
;;
;; 运行方式：
;;   clojure -M 07_higher_order.clj
;; ==========================================================================

(ns clojure-tutorial.07-higher-order)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) map ----
;; map 对集合中的每个元素应用函数
;; 返回惰性序列

(section 1 "map")

(say "(map inc [1 2 3 4]):" (map inc [1 2 3 4]))
(say "(map #(* 2 %) [1 2 3]):" (map #(* 2 %) [1 2 3]))
(say "(map str [1 2 3]):" (map str [1 2 3]))

;; 多集合 map（并行处理）
(say "(map + [1 2 3] [10 20 30]):" (map + [1 2 3] [10 20 30]))
(say "(map + [1 2 3] [10 20 30] [100 200 300]):"
     (map + [1 2 3] [10 20 30] [100 200 300]))

;; map 返回映射
(say "(map :name [{:name \"A\"} {:name \"B\"}]):"
     (map :name [{:name "A"} {:name "B"}]))

;; mapv 返回向量
(say "(mapv inc [1 2 3]):" (mapv inc [1 2 3]))

;; ---- 2) filter / remove ----
;; filter 保留满足谓词的元素
;; remove 移除满足谓词的元素（filter 的反操作）

(section 2 "filter / remove")

(say "(filter even? [1 2 3 4 5 6]):" (filter even? [1 2 3 4 5 6]))
(say "(filter #(> % 3) [1 2 3 4 5]):" (filter #(> % 3) [1 2 3 4 5]))
(say "(remove odd? [1 2 3 4 5 6]):" (remove odd? [1 2 3 4 5 6]))
(say "(filter :active [{:active true} {:active false}]):"
     (filter :active [{:active true} {:active false}]))

;; ---- 3) reduce ----
;; reduce 将集合归约为单个值
;; (reduce f coll) 或 (reduce f init coll)
;; f 接收两个参数：accumulator 和 element

(section 3 "reduce")

(say "(reduce + [1 2 3 4 5]):" (reduce + [1 2 3 4 5]))
(say "(reduce + 100 [1 2 3]):" (reduce + 100 [1 2 3]))
(say "(reduce max [3 1 4 1 5 9 2 6]):" (reduce max [3 1 4 1 5 9 2 6]))
(say "(reduce min [3 1 4 1 5 9 2 6]):" (reduce min [3 1 4 1 5 9 2 6]))
(say "(reduce conj [] [1 2 3]):" (reduce conj [] [1 2 3]))

;; reduce 构建映射
(say "(reduce (fn [m [k v]] (assoc m k v)) {} [[:a 1] [:b 2]]):"
     (reduce (fn [m [k v]] (assoc m k v)) {} [[:a 1] [:b 2]]))

;; into 是 reduce + conj 的简写
(say "(into {} [[:a 1] [:b 2]]):" (into {} [[:a 1] [:b 2]]))

;; ---- 4) partial / complement ----
;; partial 固定函数的前几个参数
;; complement 取反谓词

(section 4 "partial / complement")

(def add-10 (partial + 10))
(say "(add-10 5):" (add-10 5))
(say "(add-10 5 10 20):" (add-10 5 10 20))

(def multiply-by-3 (partial * 3))
(say "(multiply-by-3 4):" (multiply-by-3 4))

;; complement
(def not-even? (complement even?))
(say "(not-even? 3):" (not-even? 3))
(say "(not-even? 4):" (not-even? 4))
(say "(filter (complement even?) [1 2 3 4 5]):"
     (filter (complement even?) [1 2 3 4 5]))

;; ---- 5) comp ----
;; comp 组合多个函数（从右到左执行）

(section 5 "comp")

(def f1 (comp inc #(* % 3)))
(say "((comp inc #(* % 3)) 5):" (f1 5))    ;; (* 5 3) -> 15, inc -> 16

(def f2 (comp str inc #(+ % 10)))
(say "((comp str inc #(+ % 10)) 5):" (f2 5))  ;; (+ 5 10)->15, inc->16, str->"16"

;; comp 多个函数
(say "((comp #(* 2 %) #(+ 1 %) #(- % 3)) 10):"
     ((comp #(* 2 %) #(+ 1 %) #(- % 3)) 10))  ;; (- 10 3)->7, (+1)->8, (*2)->16

;; 线程宏替代 comp（更易读）
;; -> 线程优先（thread-first）
(say "(-> 10 (- 3) (+ 1) (* 2)):" (-> 10 (- 3) (+ 1) (* 2)))

;; ->> 线程最后（thread-last）
(say "(->> [1 2 3 4 5] (map inc) (filter even?) (reduce +)):"
     (->> [1 2 3 4 5] (map inc) (filter even?) (reduce +)))

;; ---- 6) keep / mapcat ----
;; keep：map + filter nil（对每个元素应用函数，保留非 nil 结果）
;; mapcat：map + concat（映射后展平结果）

(section 6 "keep / mapcat")

(say "(keep #(when (even? %) (* % 10)) [1 2 3 4 5]):"
     (keep #(when (even? %) (* % 10)) [1 2 3 4 5]))

(say "(mapcat (fn [x] [x (* x 10)]) [1 2 3]):"
     (mapcat (fn [x] [x (* x 10)]) [1 2 3]))

;; ---- 7) sort-by / group-by ----
;; sort-by 按函数结果排序
;; group-by 按函数结果分组

(section 7 "sort-by / group-by")

(say "(sort-by val {:a 3 :b 1 :c 2}):"
     (sort-by val {:a 3 :b 1 :c 2}))
(say "(sort-by :age [{:age 30} {:age 20} {:age 25}]):"
     (sort-by :age [{:age 30} {:age 20} {:age 25}]))
(say "(sort-by count [\"aaa\" \"a\" \"aa\"]):"
     (sort-by count ["aaa" "a" "aa"]))

(say "(group-by even? [1 2 3 4 5 6]):"
     (group-by even? [1 2 3 4 5 6]))
(say "(group-by :type [{:type :fruit :name \"apple\"}"
                    " {:type :veg :name \"carrot\"}"
                    " {:type :fruit :name \"banana\"}]):"
     (group-by :type [{:type :fruit :name "apple"}
                      {:type :veg :name "carrot"}
                      {:type :fruit :name "banana"}]))

;; ---- 8) juxt ----
;; juxt 创建一个函数，对同一参数分别应用多个函数，
;; 返回结果向量

(section 8 "juxt")

(def min-max (juxt min max))
(say "(apply (juxt min max) [3 1 4 1 5 9 2 6]):"
     (apply (juxt min max) [3 1 4 1 5 9 2 6]))

(say "((juxt inc dec identity) 5):" ((juxt inc dec identity) 5))
(say "((juxt first last count) [1 2 3 4 5]):"
     ((juxt first last count) [1 2 3 4 5]))

;; frequencies 统计频率
(say "(frequencies [\"a\" \"b\" \"a\" \"c\" \"a\" \"b\"]):"
     (frequencies ["a" "b" "a" "c" "a" "b"]))

;; ---- 9) 综合示例：函数式数据管线 ----

(section 9 "Data Pipeline")

(def data [{:name "Alice" :age 30 :dept :eng}
           {:name "Bob" :age 25 :dept :sales}
           {:name "Carol" :age 35 :dept :eng}
           {:name "Dave" :age 28 :dept :sales}
           {:name "Eve" :age 32 :dept :eng}])

;; 按部门分组，统计平均年龄
(def avg-age-by-dept
  (->> data
       (group-by :dept)
       (map (fn [[dept people]]
              {:dept dept
               :count (count people)
               :avg-age (/ (reduce + (map :age people))
                           (count people))}))
       (sort-by :dept)))

(doseq [r avg-age-by-dept]
  (say r))

(defn -main [& args]
  (println "")
  (println "==== 07 jieshu ===="))

(-main)
