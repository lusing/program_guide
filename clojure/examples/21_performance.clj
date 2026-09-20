;; ==========================================================================
;; 21_performance.clj - 性能与优化
;; ==========================================================================
;; 主题：让 Clojure 跑得更快
;; 内容：
;;   1. time 宏与 JIT 预热
;;   2. 反射 vs 类型提示（^String / ^long）
;;   3. 原始类型数学与 loop/recur
;;   4. 瞬态集合（transient / persistent!）
;;   5. Java 数组（int-array / aget / areduce）
;;   6. memoize 缓存纯函数
;;   7. 字符串拼接的代价
;;
;; 运行方式：
;;   clojure -M 21_performance.clj     # macOS/Linux（Clojure CLI）
;;   见 build.ps1 / build.sh           # 本教程统一验证入口
;;
;; 注意：耗时数字随机器不同而不同，看相对倍数，不看绝对值。
;; ==========================================================================

(ns clojure-tutorial.21-performance
  (:require [clojure.string :as str]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; 打开反射警告：之后任何需要反射的调用都会在 stderr 打印
;; Reflection warning, 21_performance.clj:XX - reference to field ...
(set! *warn-on-reflection* true)

;; ---- 1) time 宏与 JIT 预热 ----
;; time 宏打印 "Elapsed time: ... msecs"。
;; JVM 先用 C1 编译（快但慢），热点代码再升级到 C2（慢但快）。
;; 所以基准测试前必须先跑几轮"预热"。

(section 1 "time and JIT warmup")

(defn bench-sum [n]
  (reduce + (range n)))

(dotimes [_ 3] (bench-sum 100000))          ;; 预热
(say "Warming up done. Now the timed run:")
(time (bench-sum 1000000))

;; ---- 2) 反射 vs 类型提示 ----
;; Clojure 是动态语言：(.length s) 里 s 到底是什么类型，编译期常常不知道，
;; 只能在运行时反射查找方法 → 每次调用都慢。
;; 加 ^String 提示后编译成直接的 invokevirtual，快一个数量级。

(section 2 "reflection vs type hint")

(defn len-reflect [s]
  (.length s))                              ;; 触发反射（看 stderr 的警告）

(defn len-hint ^long [^String s]
  (.length s))                              ;; 直接调用，无反射

(len-reflect "warm")
(len-hint "warm")

(say "(len-reflect \"hello\"):" (len-reflect "hello"))
(say "(len-hint \"hello\"):" (len-hint "hello"))

(println "reflect version:")
(time (dotimes [_ 2000000] (len-reflect "hello")))

(println "hinted version:")
(time (dotimes [_ 2000000] (len-hint "hello")))

;; ---- 3) 原始类型数学与 loop/recur ----
;; 函数参数默认装箱为 Long 对象；^long 提示让参数以原始 long 传入，
;; 配合 loop/recur 可以整条循环都不装箱。

(section 3 "primitive math")

(defn sum-boxed [n]
  (loop [i (long 0) acc (long 0)]
    (if (= i n)
      acc
      (recur (inc i) (+ acc i)))))

(defn sum-primitive [^long n]
  (loop [i 0 acc 0]
    (if (= i n)
      acc
      (recur (unchecked-inc i) (unchecked-add acc i)))))

(sum-boxed 10) (sum-primitive 10)           ;; 预热

(say "(sum-boxed 1000000):"      (sum-boxed 1000000))
(say "(sum-primitive 1000000):"  (sum-primitive 1000000))

(println "boxed (safe +, overflow check):")
(time (dotimes [_ 10] (sum-boxed 1000000)))

(println "primitive (unchecked ops):")
(time (dotimes [_ 10] (sum-primitive 1000000)))

;; ---- 4) 瞬态集合 transient ----
;; 大批量构建集合时，每次 assoc/conj 都返回新的持久化结构（结构共享，
;; 不是全量拷贝，但仍有节点分配开销）。
;; transient 在单线程内临时转为可变结构，构建完再 persistent! 转回去，
;; 语义仍是"不可变进、不可变出"，但中间少分配。

(section 4 "transient collections")

(def n-items 1000000)

(println "persistent conj x" n-items ":")
(time (def v-persistent (reduce conj [] (range n-items))))

(println "transient conj! x" n-items ":")
(time (def v-transient (persistent! (reduce conj! (transient []) (range n-items)))))

(say "Same result?" (= v-persistent v-transient))
(say "Count:" (count v-transient))

;; ---- 5) Java 数组 ----
;; 性能关键路径可以退回 Java 数组：O(1) 无装箱访问。
;; areduce / amap 是编译宏，生成原始类型循环。

(section 5 "Java arrays")

(def arr (int-array (range 1000000)))

(defn sum-vector [v]
  (reduce + v))

(defn sum-array ^long [^ints a]
  (areduce a i ret (long 0) (unchecked-add ret (aget a i))))

(sum-vector [1 2 3]) (sum-array (int-array [1 2 3]))  ;; 预热

(println "reduce over vector:")
(time (dotimes [_ 10] (sum-vector (vec arr))))

(println "areduce over int-array:")
(time (dotimes [_ 10] (sum-array arr)))

;; amap 直接吃 def 出来的 var 会拿不到类型（上面的反射警告就是这么来的），
;; 绑定到局部并加 ^ints 提示后就是纯原始类型循环：
(let [^ints a arr]
  (say "amap (double every element, first 5):"
       (vec (take 5 (amap a i ret (* 2 (aget a i)))))))

;; ---- 6) memoize ----
;; 纯函数可以用 memoize 缓存：相同参数只算一次。

(section 6 "memoize")

(defn slow-square [x]
  (Thread/sleep 2)                          ;; 假装在辛苦计算
  (* x x))

(def fast-square (memoize slow-square))

(say "First run (cold cache):")
(time (doall (map fast-square (range 30))))

(say "Second run (all cached):")
(time (doall (map fast-square (range 30))))

;; ---- 7) 字符串拼接 ----
;; 字符串不可变，(str acc x) 循环是 O(n^2)。
;; 正确姿势：StringBuilder（有状态、快）或函数式的 apply str / str/join。

(section 7 "string building")

(println "naive (str acc c) loop x 8000:")
(time (loop [i 0 acc ""]
         (if (< i 8000)
           (recur (inc i) (str acc "x"))
           (count acc))))

(println "StringBuilder x 100000:")
(time (let [sb (StringBuilder.)]
         (dotimes [_ 100000] (.append sb "x"))
         (.length sb)))

(println "functional (str/join) x 100000:")
(time (count (str/join (repeat 100000 "x"))))

;; ---- 总结 ----
(println)
(say "Takeaways:")
(say " 1. Profile first: (time ...), or use criterium for serious benchmarks")
(say " 2. Type hints kill reflection: ^String ^long ^ints")
(say " 3. loop/recur with primitive math avoids boxing")
(say " 4. transient for bulk collection building")
(say " 5. Java arrays for hot loops; memoize for pure functions")

(defn -main [& args]
  (println "")
  (println "==== 21 jieshu ===="))

(-main)
