;; ==========================================================================
;; 18_transducers.clj - Transducer
;; ==========================================================================
;; 主题：Clojure 的 Transducer（转换器）机制
;; 内容：
;;   1. 什么是 Transducer
;;   2. map / filter / take 的 Transducer 形式
;;   3. comp 组合 Transducer
;;   4. transduce / into / sequence
;;   5. cat / partition-all
;;   6. 自定义 Transducer
;;   7. Transducer vs 惰性序列
;;
;; 运行方式：
;;   clojure -M 18_transducers.clj
;; ==========================================================================

(ns clojure-tutorial.18-transducers)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 什么是 Transducer ----
;; Transducer 是「转换函数的函数」
;; 它与数据源无关，可以在不同上下文中复用
;; (map f) 返回一个 Transducer，而不是序列

(section 1 "What is a Transducer")

;; 普通的 map 接收函数和集合
(say "(map inc [1 2 3]):" (map inc [1 2 3]))

;; map 的 Transducer 形式（不传集合）
(say "(map inc):" (map inc))
(say "type of (map inc):" (type (map inc)))

;; Transducer 是可复用的转换步骤
(def xf-inc (map inc))
(say "xf-inc:" xf-inc)

;; ---- 2) 常用 Transducer ----
;; map, filter, take, drop, take-while, drop-while
;; remove, mapcat, replace, partition-all, partition-by
;; distinct, dedupe, keep, cat, halt-when, etc.

(section 2 "Common Transducers")

(say "(into [] (map inc) [1 2 3]):" (into [] (map inc) [1 2 3]))
(say "(into [] (filter even?) [1 2 3 4 5]):"
     (into [] (filter even?) [1 2 3 4 5]))
(say "(into [] (take 3) (range 100)):"
     (into [] (take 3) (range 100)))
(say "(into [] (drop 2) [1 2 3 4 5]):"
     (into [] (drop 2) [1 2 3 4 5]))
(say "(into [] (take-while #(< % 3)) [1 2 3 4 5]):"
     (into [] (take-while #(< % 3)) [1 2 3 4 5]))
(say "(into [] (drop-while #(< % 3)) [1 2 3 4 5]):"
     (into [] (drop-while #(< % 3)) [1 2 3 4 5]))
(say "(into [] (distinct) [1 1 2 2 3 3]):"
     (into [] (distinct) [1 1 2 2 3 3]))
(say "(into [] (dedupe) [1 1 2 2 1 1 3 3]):"
     (into [] (dedupe) [1 1 2 2 1 1 3 3]))
(say "(into [] (keep #(when (even? %) (* % 10))) [1 2 3 4]):"
     (into [] (keep #(when (even? %) (* % 10))) [1 2 3 4]))

;; ---- 3) comp 组合 Transducer ----
;; comp 组合多个 Transducer 为一个

(section 3 "comp with Transducers")

(def xf (comp (map inc)
              (filter even?)
              (take 3)))

(say "(into [] xf (range 100)):" (into [] xf (range 100)))

;; 线程优先宏也可以
(def xf2 (comp (map #(* % 2))
               (remove zero?)
               (mapcat list)))

(say "(into [] xf2 [0 1 2 3]):" (into [] xf2 [0 1 2 3]))

;; ---- 4) transduce ----
;; transduce 显式执行 Transducer
;; (transduce xf f init coll)
;; f 是 reduce 函数

(section 4 "transduce")

;; 求所有偶数的平方和
(def xf-sum (comp (filter even?)
                  (map #(* % %))))
(say "(transduce xf-sum + 0 [1 2 3 4 5 6]):"
     (transduce xf-sum + 0 [1 2 3 4 5 6]))

;; transduce 和 into 的关系
(say "into is like transduce with conj:"
     (transduce xf conj [] (range 10)))

;; ---- 5) sequence ----
;; sequence 将 Transducer 应用于集合，返回惰性序列

(section 5 "sequence")

(say "(sequence (map inc) [1 2 3]):"
     (sequence (map inc) [1 2 3]))
(say "(sequence (comp (map inc) (filter even?)) [1 2 3 4 5]):"
     (sequence (comp (map inc) (filter even?)) [1 2 3 4 5]))
(say "(sequence (take 5) (range 1000000)):"
     (sequence (take 5) (range 1000000)))

;; eduction：创建可重用的转换序列
(def ed (eduction (map inc) (filter even?) [1 2 3 4 5]))
(say "eduction (into [] ed):" (into [] ed))
(say "eduction (into [] ed) again:" (into [] ed))

;; ---- 6) cat / partition-all ----
;; cat：展平嵌套结构
;; partition-all：分块

(section 6 "cat / partition-all")

(say "(into [] cat [[1 2] [3 4] [5]]):"
     (into [] cat [[1 2] [3 4] [5]]))
(say "(into [] (partition-all 2) [1 2 3 4 5]):"
     (into [] (partition-all 2) [1 2 3 4 5]))
(say "(into [] (partition-by even?) [1 1 2 2 3 3]):"
     (into [] (partition-by even?) [1 1 2 2 3 3]))

;; ---- 7) 自定义 Transducer ----
;; 一个 Transducer 是一个函数：
;; 接收一个 step 函数 (result item)，返回一个新的 step 函数

(section 7 "Custom Transducer")

(defn dedupe-by
  "A transducer that removes consecutive duplicates by a key function."
  [key-fn]
  (fn [rf]
    (let [prev (volatile! ::none)]
      (fn
        ([] (rf))
        ([result] (rf result))
        ([result input]
         (let [k (key-fn input)]
           (if (= k @prev)
             result
             (do (vreset! prev k)
                 (rf result input)))))))))

(say "(into [] (dedupe-by :type)"
     " [{:type :a :val 1} {:type :a :val 2} {:type :b :val 3}]):"
     (into [] (dedupe-by :type)
           [{:type :a :val 1}
            {:type :a :val 2}
            {:type :b :val 3}
            {:type :b :val 4}
            {:type :c :val 5}]))

;; ---- 8) Transducer vs 惰性序列 ----
;; 惰性序列：函数组合产生中间序列
;; Transducer：函数组合不产生中间序列，更高效

(section 8 "Transducers vs Lazy Sequences")

(def data (range 10000))

;; 惰性序列方式（产生中间序列）
(let [start (System/nanoTime)
      _ (->> data
             (map inc)
             (filter even?)
             (take 10)
             (into [])
             (count))
      end (System/nanoTime)]
  (say "Lazy seq time (us):" (int (/ (- end start) 1000))))

;; Transducer 方式（无中间序列）
(let [start (System/nanoTime)
      _ (into []
              (comp (map inc)
                    (filter even?)
                    (take 10))
              data)
      end (System/nanoTime)]
  (say "Transducer time (us):" (int (/ (- end start) 1000))))

;; Transducer 的优势：
;; 1. 无中间序列，内存高效
;; 2. 可以提前终止（take, halt-when）
;; 3. 可复用（与数据源无关）
;; 4. 可用于不同上下文（into, transduce, sequence, chan）

(defn -main [& args]
  (println "")
  (println "==== 18 jieshu ===="))

(-main)
