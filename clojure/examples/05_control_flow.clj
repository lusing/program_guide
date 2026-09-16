;; ==========================================================================
;; 05_control_flow.clj - 控制流
;; ==========================================================================
;; 主题：Clojure 的控制流结构
;; 内容：
;;   1. if / if-not
;;   2. when / when-not / when-let / if-let
;;   3. cond / condp
;;   4. case
;;   5. 逻辑运算（and / or / not）
;;   6. do（副作用分组）
;;   7. while / doseq / dotimes / loop-recur
;;
;; 运行方式：
;;   clojure -M 05_control_flow.clj
;; ==========================================================================

(ns clojure-tutorial.05-control-flow)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) if / if-not ----
;; if 是表达式，有返回值
;; (if test then else?)
;; 注意：if 是表达式，不是语句！

(section 1 "if / if-not")

(say "(if true :yes :no):" (if true :yes :no))
(say "(if false :yes :no):" (if false :yes :no))
(say "(if nil :yes :no):" (if nil :yes :no))
(say "(if 0 :truthy :falsy):" (if 0 :truthy :falsy))
(say "(if [] :truthy :falsy):" (if [] :truthy :falsy))

;; if 没有 else 分支时返回 nil
(say "(if false :yes):" (if false :yes))

;; if-not 是 if 的否定版本
(say "(if-not false :yes :no):" (if-not false :yes :no))
(say "(if-not nil :yes :no):" (if-not nil :yes :no))

;; if 表达式赋值
(def status (if true :active :inactive))
(say "status:" status)

;; ---- 2) when / when-not / when-let / if-let ----
;; when 只有一个分支（then），无 else
;; when-let 绑定 + 条件

(section 2 "when / when-not / when-let / if-let")

(say "(when true \"yes\"):" (when true "yes"))
(say "(when false \"yes\"):" (when false "yes"))

;; when 有多个表达式体
(when true
  (say "inside when: line 1")
  (say "inside when: line 2")
  "return value")

;; when-not
(say "(when-not nil \"not nil\"):" (when-not nil "not nil"))

;; when-let：绑定 + 测试
;; 如果 test 为真，绑定并执行 body
(say "(when-let [x (first [1 2 3])] x):" (when-let [x (first [1 2 3])] x))
(say "(when-let [x (first [])] x):" (when-let [x (first [])] x))

;; if-let：绑定 + 条件 + then/else
(say "(if-let [x (first [1 2 3])] x \"empty\"):"
     (if-let [x (first [1 2 3])] x "empty"))
(say "(if-let [x (first [])] x \"empty\"):"
     (if-let [x (first [])] x "empty"))

;; ---- 3) cond / condp ----
;; cond：多分支条件（类似 if-else if-else）
;; 每个分支是 (test expr) 对
;; :default 是默认分支

(section 3 "cond / condp")

(defn classify [n]
  (cond
    (neg? n) "negative"
    (zero? n) "zero"
    (< n 10)  "small"
    (< n 100) "medium"
    :else     "large"))

(say "(classify -5):" (classify -5))
(say "(classify 0):" (classify 0))
(say "(classify 5):" (classify 5))
(say "(classify 50):" (classify 50))
(say "(classify 500):" (classify 500))

;; condp：带谓词的 cond
(defn day-type [day]
  (condp = day
    :mon :weekday
    :tue :weekday
    :wed :weekday
    :thu :weekday
    :fri :weekday
    :sat :weekend
    :sun :weekend
    :unknown))

(say "(day-type :mon):" (day-type :mon))
(say "(day-type :sat):" (day-type :sat))
(say "(day-type :xyz):" (day-type :xyz))

;; ---- 4) case ----
;; case 是编译时常量匹配（类似 switch）
;; 更高效但不支持复杂条件
;; 必须穷尽所有可能（或提供 default）

(section 4 "case")

(defn color-code [color]
  (case color
    :red    "#FF0000"
    :green  "#00FF00"
    :blue   "#0000FF"
    "#000000"))                      ;; default

(say "(color-code :red):" (color-code :red))
(say "(color-code :green):" (color-code :green))
(say "(color-code :blue):" (color-code :blue))
(say "(color-code :pink):" (color-code :pink))

;; ---- 5) 逻辑运算 ----
;; and / or 是宏，短路求值
;; and 返回第一个假值或最后一个值
;; or 返回第一个真值或最后一个值

(section 5 "Logical Operations")

(say "(and true false):" (and true false))
(say "(and true true):" (and true true))
(say "(and 1 2 3):" (and 1 2 3))
(say "(and nil 2 3):" (and nil 2 3))
(say "(or nil false 3):" (or nil false 3))
(say "(or nil false nil):" (or nil false nil))
(say "(not true):" (not true))
(say "(not nil):" (not nil))
(say "(not 0):" (not 0))

;; and/or 的短路特性
(and (say "and: this prints") true)
(or (say "or: this prints") true)

;; 短路：and 的第一个为假就不求值后面的
(and false (say "and: this won't print"))

;; 短路：or 的第一个为真就不求值后面的
(or true (say "or: this won't print"))

;; nil 或 false 检查
(say "(true? (and true true)):" (true? (and true true)))

;; ---- 6) do ----
;; do 将多个表达式分组，返回最后一个
;; 用于需要副作用的场景

(section 6 "do")

(defn process [x]
  (do
    (say "processing:" x)
    (say "step 1 done")
    (say "step 2 done")
    (* x 2)))

(say "(process 5):" (process 5))

;; ---- 7) 循环结构 ----
;; Clojure 没有传统 for 循环
;; 使用 doseq / dotimes / while / loop-recur

(section 7 "Loop Structures")

;; dotimes：执行 n 次
(println)
(println "dotimes:")
(dotimes [i 5]
  (say "  i =" i))

;; doseq：遍历集合
(println)
(println "doseq (list):")
(doseq [x [10 20 30]]
  (say "  x =" x))

;; doseq 多个绑定（笛卡尔积）
(println)
(println "doseq (Cartesian):")
(doseq [x [:a :b]
        y [1 2]]
  (say "  " x y))

;; doseq with :when 过滤
(println)
(println "doseq with :when:")
(doseq [x (range 10)
        :when (even? x)]
  (say "  even:" x))

;; doseq with :while
(println)
(println "doseq with :while:")
(doseq [x (range 10)
        :while (< x 5)]
  (say "  x =" x))

;; while 循环
(println)
(println "while:")
(def counter (atom 0))
(while (< @counter 3)
  (say "  counter =" @counter)
  (swap! counter inc))

;; loop / recur：函数式循环（尾递归优化）
(println)
(println "loop/recur (factorial):")
(defn factorial [n]
  (loop [i n
         acc 1]
    (if (zero? i)
      acc
      (recur (dec i) (* acc i)))))
(say "  (factorial 5):" (factorial 5))
(say "  (factorial 0):" (factorial 0))
(say "  (factorial 10):" (factorial 10))

;; loop/recur 累加
(println)
(println "loop/recur (sum):")
(defn sum-to [n]
  (loop [i n
         acc 0]
    (if (zero? i)
      acc
      (recur (dec i) (+ acc i)))))
(say "  (sum-to 100):" (sum-to 100))

(defn -main [& args]
  (println "")
  (println "==== 05 jieshu ===="))

(-main)
