;; ==========================================================================
;; 03_collections.clj - 集合
;; ==========================================================================
;; 主题：Clojure 的四大核心集合类型
;; 内容：
;;   1. 列表（List）
;;   2. 向量（Vector）
;;   3. 映射（Map）
;;   4. 集合（Set）
;;   5. 队列（Queue）
;;   6. 集合的不可变性与持久化结构
;;   7. 集合通用操作
;;
;; 运行方式：
;;   clojure -M 03_collections.clj
;; ==========================================================================

(ns clojure-tutorial.03-collections
  (:require [clojure.set :as set]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 列表（List）----
;; 列表是单向链表，头部添加/删除是 O(1)
;; 用 () 或 list 创建
;; 元素以链表形式存储，适合从头遍历

(section 1 "List")

(def lst1 '(1 2 3 4 5))              ;; quote 创建
(def lst2 (list 10 20 30))           ;; list 函数创建
(def lst3 (cons 0 '(1 2)))           ;; cons 在头部添加

(say "lst1:" lst1)
(say "lst2:" lst2)
(say "lst3:" lst3)
(say "First (first lst1):" (first lst1))
(say "Rest (next lst1):" (next lst1))
(say "Rest (rest lst1):" (rest lst1))
(say "Cons (cons 0 lst1):" (cons 0 lst1))
(say "Nth (nth lst1 2):" (nth lst1 2))
(say "Count (count lst1):" (count lst1))
(say "List? (list? lst1):" (list? lst1))

;; conj 对列表是在头部添加
(say "(conj lst1 0):" (conj lst1 0))

;; ---- 2) 向量（Vector）----
;; 向量是类似数组的结构，尾部添加 O(1)，随机访问 O(1)
;; 用 [] 创建
;; 适合按索引访问

(section 2 "Vector")

(def vec1 [1 2 3 4 5])
(def vec2 (vector 10 20 30))
(def vec3 (vec '(1 2 3)))            ;; 从列表转换

(say "vec1:" vec1)
(say "vec2:" vec2)
(say "vec3:" vec3)
(say "First (first vec1):" (first vec1))
(say "Last (last vec1):" (last vec1))
(say "Nth (nth vec1 2):" (nth vec1 2))
(say "Get (get vec1 2):" (get vec1 2))
(say "Get with default (get vec1 10 \"N/A\"):" (get vec1 10 "N/A"))

;; conj 对向量是在尾部添加
(say "(conj vec1 6):" (conj vec1 6))
(say "(assoc vec1 0 99):" (assoc vec1 0 99))
(say "Subvec (subvec vec1 1 3):" (subvec vec1 1 3))

;; 向量也是函数（可以用索引调用）
(say "(vec1 2):" (vec1 2))

;; mapv 和 filterv 返回向量
(say "(mapv inc vec1):" (mapv inc vec1))

;; ---- 3) 映射（Map）----
;; 映射是键值对集合，哈希表实现
;; 用 {} 创建
;; 键通常是关键字，但可以是任何类型

(section 3 "Map")

(def m1 {:name "Alice" :age 30 :email "alice@example.com"})
(def m2 {"name" "Bob" "age" 25})     ;; 字符串键也可以
(def m3 (hash-map :a 1 :b 2 :c 3))
(def m4 (sorted-map :c 3 :a 1 :b 2)) ;; 排序映射

(say "m1:" m1)
(say "m2:" m2)
(say "m3:" m3)
(say "m4 (sorted):" m4)

;; 取值
(say "(:name m1):" (:name m1))
(say "(get m1 :name):" (get m1 :name))
(say "(:missing m1):" (:missing m1))
(say "(:missing m1 \"N/A\"):" (:missing m1 "N/A"))
(say "(m1 :name):" (m1 :name))

;; 更新
(say "(assoc m1 :age 31):" (assoc m1 :age 31))
(say "(assoc m1 :phone \"123\"):" (assoc m1 :phone "123"))
(say "(dissoc m1 :email):" (dissoc m1 :email))
(say "(update m1 :age inc):" (update m1 :age inc))
(say "(update m1 :age + 5):" (update m1 :age + 5))

;; merge
(say "(merge m1 {:city \"NYC\"}):" (merge m1 {:city "NYC"}))
(say "(merge m1 {:age 31} {:phone \"123\"}):"
     (merge m1 {:age 31} {:phone "123"}))

;; merge-with
(say "(merge-with + {:a 1 :b 2} {:a 3 :c 4}):"
     (merge-with + {:a 1 :b 2} {:a 3 :c 4}))

;; 遍历
(say "Keys (keys m1):" (keys m1))
(say "Vals (vals m1):" (vals m1))
(say "Seq (seq m1):" (seq m1))

;; ---- 4) 集合（Set）----
;; 集合是无序、无重复的集合
;; 用 #{} 创建

(section 4 "Set")

(def s1 #{1 2 3 4 5})
(def s2 (hash-set 3 4 5 6 7))
(def s3 (sorted-set 5 3 1 4 2))      ;; 排序集合

(say "s1:" s1)
(say "s2:" s2)
(say "s3 (sorted):" s3)

;; 集合操作
(say "(contains? s1 3):" (contains? s1 3))
(say "(s1 3):" (s1 3))
(say "(conj s1 6):" (conj s1 6))
(say "(disj s1 3):" (disj s1 3))

;; 集合运算
(say "Union (set/union s1 s2):"
     (set/union s1 s2))
(say "Intersection (set/intersection s1 s2):"
     (set/intersection s1 s2))
(say "Difference (set/difference s1 s2):"
     (set/difference s1 s2))

;; ---- 5) 队列（Queue）----
;; 队列是先进先出（FIFO）结构
;; 用 clojure.lang.PersistentQueue 创建

(section 5 "Queue")

(def q1 (conj clojure.lang.PersistentQueue/EMPTY 1 2 3))
(say "q1 (seq):" (seq q1))
(say "Peek (peek q1):" (peek q1))
(say "Pop (pop q1) (seq):" (seq (pop q1)))
(say "Count (count q1):" (count q1))

;; ---- 6) 不可变性与持久化 ----
;; Clojure 集合是不可变的：操作返回新集合，原集合不变
;; 底层使用持久化数据结构（结构共享），内存高效

(section 6 "Immutability and Persistence")

(def original [1 2 3])
(def updated (conj original 4))

(say "original:" original)
(say "updated:" updated)
(say "Identical? (identical? original updated):"
     (identical? original updated))
(say "original unchanged after conj")

;; ---- 7) 集合通用操作 ----
;; count, empty?, not-empty, seq, into, distinct

(section 7 "Common Collection Operations")

(say "(count [1 2 3]):" (count [1 2 3]))
(say "(count #{1 2 3}):" (count #{1 2 3}))
(say "(count {:a 1 :b 2}):" (count {:a 1 :b 2}))
(say "(empty? []):" (empty? []))
(say "(empty? [1]):" (empty? [1]))
(say "(not-empty []):" (not-empty []))
(say "(not-empty [1 2]):" (not-empty [1 2]))
(say "(seq []):" (seq []))
(say "(seq [1 2 3]):" (seq [1 2 3]))
(say "(into [] '(1 2 3)):" (into [] '(1 2 3)))
(say "(into #{} [1 2 1 3 2]):" (into #{} [1 2 1 3 2]))
(say "(distinct [1 1 2 2 3 3]):" (distinct [1 1 2 2 3 3]))

;; into 的本质：conj 所有元素到集合
(say "(into {:a 1} [[:b 2] [:c 3]]):" (into {:a 1} [[:b 2] [:c 3]]))

(defn -main [& args]
  (println "")
  (println "==== 03 jieshu ===="))

(-main)
