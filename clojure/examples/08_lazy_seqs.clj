;; ==========================================================================
;; 08_lazy_seqs.clj - 惰性序列
;; ==========================================================================
;; 主题：Clojure 的惰性序列与序列函数
;; 内容：
;;   1. seq 与序列抽象
;;   2. range
;;   3. iterate
;;   4. cycle / repeat
;;   5. take / drop / take-while / drop-while
;;   6. lazy-seq 自定义惰性序列
;;   7. for 列表推导
;;   8. 无限序列的实际应用
;;
;; 运行方式：
;;   clojure -M 08_lazy_seqs.clj
;; ==========================================================================

(ns clojure-tutorial.08-lazy-seqs)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) seq 与序列抽象 ----
;; seq 将集合转换为序列（Seq）
;; Clojure 的所有集合都可以转换为 Seq

(section 1 "seq and Sequence Abstraction")

(say "(seq [1 2 3]):" (seq [1 2 3]))
(say "(seq '(:a :b :c)):" (seq '(:a :b :c)))
(say "(seq {:a 1 :b 2}):" (seq {:a 1 :b 2}))
(say "(seq #{1 2 3}):" (seq #{1 2 3}))
(say "(seq \"hello\"):" (seq "hello"))
(say "(seq []):" (seq []))
(say "(if (seq []) :non-empty :empty):" (if (seq []) :non-empty :empty))

;; 序列操作返回 LazySeq
(say "(type (map inc [1 2 3])):" (type (map inc [1 2 3])))

;; ---- 2) range ----
;; range 生成惰性的数字序列
;; (range)         -> 无限序列 0 1 2 3 ...
;; (range end)     -> 0..end-1
;; (range start end) -> start..end-1
;; (range start end step) -> 带步长

(section 2 "range")

(say "(range 5):" (range 5))
(say "(range 2 8):" (range 2 8))
(say "(range 0 10 2):" (range 0 10 2))
(say "(range 10 0 -1):" (range 10 0 -1))
(say "(range 0 1 0.25):" (range 0 1 0.25))
(say "(take 5 (range)):" (take 5 (range)))
(say "(take 3 (range 100 200)):" (take 3 (range 100 200)))

;; ---- 3) iterate ----
;; iterate 生成无限惰性序列
;; (iterate f x) -> x, (f x), (f (f x)), ...

(section 3 "iterate")

(say "(take 5 (iterate inc 0)):" (take 5 (iterate inc 0)))
(say "(take 5 (iterate #(* 2 %) 1)):" (take 5 (iterate #(* 2 %) 1)))
(say "(take 4 (iterate #(mod (* % %) 17) 3)):"
     (take 4 (iterate #(mod (* % %) 17) 3)))

;; 斐波那契数列
(def fib-seq
  (map first
       (iterate (fn [[a b]] [b (+ a b)]) [0 1])))
(say "(take 10 fib-seq):" (take 10 fib-seq))

;; ---- 4) cycle / repeat ----
;; cycle 无限循环集合
;; repeat 无限重复元素
;; (repeat n x) 重复 n 次

(section 4 "cycle / repeat")

(say "(take 7 (cycle [:a :b :c])):" (take 7 (cycle [:a :b :c])))
(say "(take 5 (repeat :x)):" (take 5 (repeat :x)))
(say "(repeat 3 \"hi\"):" (repeat 3 "hi"))
(say "(interleave [:a :b :c] [1 2 3]):" (interleave [:a :b :c] [1 2 3]))

;; ---- 5) take / drop / take-while / drop-while ----
;; take：取前 n 个
;; drop：丢弃前 n 个
;; take-while：取满足条件的前缀
;; drop-while：丢弃满足条件的前缀

(section 5 "take / drop / take-while / drop-while")

(say "(take 3 [1 2 3 4 5]):" (take 3 [1 2 3 4 5]))
(say "(drop 2 [1 2 3 4 5]):" (drop 2 [1 2 3 4 5]))
(say "(take 5 (range 100)):" (take 5 (range 100)))
(say "(drop 95 (range 100)):" (drop 95 (range 100)))

(say "(take-while #(< % 5) [1 2 3 4 5 6 7]):"
     (take-while #(< % 5) [1 2 3 4 5 6 7]))
(say "(drop-while #(< % 5) [1 2 3 4 5 6 7]):"
     (drop-while #(< % 5) [1 2 3 4 5 6 7]))

;; split-at / split-with
(say "(split-at 3 [1 2 3 4 5]):" (split-at 3 [1 2 3 4 5]))
(say "(split-with #(< % 4) [1 2 3 4 5]):"
     (split-with #(< % 4) [1 2 3 4 5]))

;; ---- 6) lazy-seq 自定义惰性序列 ----
;; lazy-seq 创建自定义的惰性序列
;; 这是构建无限序列的核心

(section 6 "lazy-seq")

;; 自然数序列
(defn naturals
  ([] (naturals 1))
  ([n] (lazy-seq (cons n (naturals (inc n))))))

(say "(take 5 (naturals)):" (take 5 (naturals)))
(say "(take 3 (naturals 100)):" (take 3 (naturals 100)))

;; 斐波那契数列（lazy-seq 版本）
(defn fib []
  (letfn [(fib* [a b]
            (lazy-seq (cons a (fib* b (+ a b)))))]
    (fib* 0 1)))

(say "(take 10 (fib)):" (take 10 (fib)))

;; 平方序列
(defn squares []
  (lazy-seq
    (map #(* % %) (drop 1 (range)))))

(say "(take 5 (squares)):" (take 5 (squares)))

;; ---- 7) for 列表推导 ----
;; for 是 Clojure 的列表推导
;; 注意：for 返回序列，不是循环！

(section 7 "for (List Comprehension)")

(say "(for [x [1 2 3]] (* x x)):" (for [x [1 2 3]] (* x x)))

;; 笛卡尔积
(say "(for [x [:a :b] y [1 2]] [x y]):"
     (for [x [:a :b] y [1 2]] [x y]))

;; 带过滤 :when
(say "(for [x (range 10) :when (even? x)] x):"
     (for [x (range 10) :when (even? x)] x))

;; 带 :while 条件
(say "(for [x [1 2 3 4 5] :while (< x 4)] x):"
     (for [x [1 2 3 4 5] :while (< x 4)] x))

;; 多变量推导
(say "(for [x [1 2] y [10 20] z [100 200]] (+ x y z)):"
     (for [x [1 2] y [10 20] z [100 200]] (+ x y z)))

;; 生成映射
(say "(for [name [\"Alice\" \"Bob\"] age [25 30]] {:name name :age age}):"
     (for [name ["Alice" "Bob"] age [25 30]] {:name name :age age}))

;; ---- 8) 无限序列的实际应用 ----
;; 利用无限序列解决实际问题

(section 8 "Practical Applications")

;; 前 10 个素数
(defn prime? [n]
  (and (> n 1)
       (not-any? #(zero? (mod n %)) (range 2 (inc (Math/sqrt n))))))

(def primes
  (filter prime? (drop 2 (range))))

(say "First 10 primes:" (vec (take 10 primes)))

;; 前 10 个完全平方数
(say "First 10 perfect squares:"
     (vec (take 10 (for [x (range 1)] (* x x)))))

;; 前几个 2 的幂
(say "Powers of 2 (first 8):"
     (vec (take 8 (iterate #(* 2 %) 1))))

;; 斐波那契的前 15 个
(say "First 15 Fibonacci numbers:"
     (vec (take 15 (fib))))

;; 自然数的阶乘序列
(def factorials
  (reductions * (drop 1 (range))))
(say "First 10 factorials:" (vec (take 10 factorials)))

;; partition-by 和 partition
(say "(partition 2 [1 2 3 4 5 6]):" (partition 2 [1 2 3 4 5 6]))
(say "(partition-all 2 [1 2 3 4 5]):" (partition-all 2 [1 2 3 4 5]))
(say "(partition-by even? [1 1 2 2 3 3]):"
     (partition-by even? [1 1 2 2 3 3]))

(defn -main [& args]
  (println "")
  (println "==== 08 jieshu ===="))

(-main)
