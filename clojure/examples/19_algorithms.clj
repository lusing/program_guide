;; ==========================================================================
;; 19_algorithms.clj - 经典算法
;; ==========================================================================
;; 主题：用 Clojure 实现经典算法
;; 内容：
;;   1. 快速排序
;;   2. 归并排序
;;   3. 二分查找
;;   4. 斐波那契（记忆化）
;;   5. 埃拉托斯特尼筛法
;;   6. 拓扑排序（Kahn 算法）
;;   7. Dijkstra 最短路径
;;
;; 运行方式：
;;   clojure -M 19_algorithms.clj
;; ==========================================================================

(ns clojure-tutorial.19-algorithms)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 快速排序 ----
;; 函数式快速排序：简单但非原地

(section 1 "Quicksort")

(defn quicksort [coll]
  (lazy-seq
    (when (seq coll)
      (let [pivot (first coll)
            rest (rest coll)
            smaller (filter #(< % pivot) rest)
            larger (filter #(>= % pivot) rest)]
        (concat (quicksort smaller)
                [pivot]
                (quicksort larger))))))

(def data1 [5 2 8 1 9 3 7 4 6])
(say "Original:" (vec data1))
(say "Quicksort:" (vec (quicksort data1)))
(say "Sorted? (= (sort data1) (quicksort data1)):"
     (= (sort data1) (quicksort data1)))

;; 三路快排（处理重复元素）
(defn quicksort-3way [coll]
  (lazy-seq
    (when (seq coll)
      (let [pivot (first coll)
            rest (rest coll)
            smaller (filter #(< % pivot) rest)
            equal (filter #(= % pivot) rest)
            larger (filter #(> % pivot) rest)]
        (concat (quicksort-3way smaller)
                equal
                (quicksort-3way larger))))))

(say "3-way Quicksort [3 1 2 3 1 2 3 3]:"
     (vec (quicksort-3way [3 1 2 3 1 2 3 3])))

;; ---- 2) 归并排序 ----

(section 2 "Merge Sort")

(defn merge-sorted [a b]
  (lazy-seq
    (cond
      (empty? a) b
      (empty? b) a
      :else (if (<= (first a) (first b))
              (cons (first a) (merge-sorted (rest a) b))
              (cons (first b) (merge-sorted a (rest b)))))))

(defn merge-sort [coll]
  (if (or (empty? coll) (empty? (rest coll)))
    coll
    (let [mid (quot (count coll) 2)
          left (take mid coll)
          right (drop mid coll)]
      (merge-sorted (merge-sort left) (merge-sort right)))))

(say "Merge Sort:" (vec (merge-sort data1)))
(say "Sorted? (= (sort data1) (merge-sort data1)):"
     (= (sort data1) (merge-sort data1)))

;; ---- 3) 二分查找 ----

(section 3 "Binary Search")

(defn binary-search
  "Return index of target in sorted vector, or nil if not found."
  [sorted-vec target]
  (loop [lo 0
         hi (dec (count sorted-vec))]
    (if (> lo hi)
      nil
      (let [mid (quot (+ lo hi) 2)
            val (nth sorted-vec mid)]
        (cond
          (= val target) mid
          (< val target) (recur (inc mid) hi)
          :else (recur lo (dec mid)))))))

(def sorted-data (vec (sort data1)))
(say "Sorted data:" sorted-data)
(say "(binary-search sorted-data 7):" (binary-search sorted-data 7))
(say "(binary-search sorted-data 5):" (binary-search sorted-data 5))
(say "(binary-search sorted-data 10):" (binary-search sorted-data 10))

;; ---- 4) 斐波那契（记忆化）----

(section 4 "Fibonacci with Memoization")

;; 朴素递归（指数时间）
(defn fib-naive [n]
  (cond
    (= n 0) 0
    (= n 1) 1
    :else (+ (fib-naive (dec n)) (fib-naive (- n 2)))))

;; 记忆化版本
(def fib-memo
  (memoize
    (fn [n]
      (cond
        (= n 0) 0
        (= n 1) 1
        :else (+ (fib-memo (dec n)) (fib-memo (- n 2)))))))

;; 迭代版本（线性时间，常数空间）
(defn fib-iter [n]
  (loop [a 0 b 1 k n]
    (if (zero? k) a (recur b (+' a b) (dec k)))))

(say "(fib-naive 10):" (fib-naive 10))
(say "(fib-memo 30):" (fib-memo 30))
(say "(fib-iter 50):" (fib-iter 50))
(say "(fib-iter 100):" (fib-iter 100))

;; ---- 5) 埃拉托斯特尼筛法 ----

(section 5 "Sieve of Eratosthenes")

(defn primes-up-to [n]
  (let [sieve (boolean-array (inc n) true)]
    (loop [i 2]
      (when (<= (* i i) n)
        (when (aget sieve i)
          (doseq [j (range (* i i) (inc n) i)]
            (aset sieve j false)))
        (recur (inc i))))
    (filter #(aget sieve %) (range 2 (inc n)))))

(say "Primes up to 50:" (vec (primes-up-to 50)))
(say "Primes up to 100:" (vec (primes-up-to 100)))
(say "Count primes up to 1000:" (count (primes-up-to 1000)))

;; 惰性素数序列（无限）
(defn prime? [n]
  (and (> n 1)
       (not-any? #(zero? (mod n %))
                 (range 2 (inc (Math/sqrt n))))))

(def lazy-primes (filter prime? (drop 2 (range))))
(say "First 20 primes:" (vec (take 20 lazy-primes)))

;; ---- 6) 拓扑排序 ----
;; Kahn's algorithm

(section 6 "Topological Sort (Kahn)")

(defn topo-sort
  "Topologically sort a directed acyclic graph.
   graph is a map of node -> set of dependency nodes.
   A node can be processed when all its dependencies are done."
  [graph]
  (let [nodes (set (concat (keys graph) (apply concat (vals graph))))
        init-degrees (into {} (for [n nodes]
                                [n (count (get graph n #{}))]))
        init-queue (filter #(zero? (init-degrees %)) nodes)]
    (loop [queue (seq init-queue)
           degrees init-degrees
           result []]
      (if (empty? queue)
        result
        (let [node (first queue)
              rest-queue (rest queue)
              dependents (filter #(contains? (get graph % #{}) node) nodes)
              new-degrees (reduce #(update %1 %2 dec) degrees dependents)
              newly-ready (filter #(and (pos? (degrees %))
                                        (zero? (new-degrees %)))
                                  dependents)]
          (recur (concat rest-queue newly-ready)
                 new-degrees
                 (conj result node)))))))

(def dag {:d #{:b :c}
          :c #{:a}
          :b #{:a}
          :a #{}})

(say "DAG:" dag)
(say "Topological sort:" (topo-sort dag))

;; ---- 7) Dijkstra 最短路径 ----

(section 7 "Dijkstra Shortest Path")

(defn dijkstra
  "Find shortest paths from start node.
   graph is a map of node -> {neighbor -> weight}."
  [graph start]
  (let [nodes (set (concat (keys graph) (mapcat keys (vals graph))))
        init-dist (into {} (for [n nodes] [n ##Inf]))
        init-dist (assoc init-dist start 0)]
    (loop [distances init-dist
           visited #{}
           unvisited (sorted-set-by #(compare (distances %1) (distances %2)) start)]
      (if (empty? unvisited)
        distances
        (let [current (first unvisited)
              rest-unvisited (disj unvisited current)
              neighbors (for [[n w] (get graph current {})
                              :when (not (contains? visited n))]
                          [n w])
              new-dist (reduce
                        (fn [m [n w]]
                          (let [new-d (+ (distances current) w)]
                            (if (< new-d (m n))
                              (assoc m n new-d)
                              m)))
                        distances
                        neighbors)]
          (recur new-dist
                 (conj visited current)
                 (into (sorted-set-by #(compare (new-dist %1) (new-dist %2))) rest-unvisited)))))))

(def weighted-graph
  {:a {:b 4 :c 2}
   :b {:c 5 :d 10}
   :c {:e 3}
   :d {:e 4 :f 11}
   :e {:d 4}
   :f {}})

(say "Weighted graph:" weighted-graph)
(say "Shortest paths from :a:" (dijkstra weighted-graph :a))

(defn -main [& args]
  (println "")
  (println "==== 19 jieshu ===="))

(-main)
