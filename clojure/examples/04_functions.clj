;; ==========================================================================
;; 04_functions.clj - 函数与闭包
;; ==========================================================================
;; 主题：Clojure 的函数定义与闭包
;; 内容：
;;   1. defn 基本用法
;;   2. 参数模型（固定参数、多参数体、可变参数）
;;   3. 匿名函数
;;   4. 闭包
;;   5. apply 与 partial
;;   6. 函数作为一等公民
;;   7. 前置/后置条件
;;
;; 运行方式：
;;   clojure -M 04_functions.clj
;; ==========================================================================

(ns clojure-tutorial.04-functions)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) defn 基本用法 ----
;; defn 定义一个有名字的函数
;; 格式：(defn name docstring? meta? [params] body)
;; 函数体可以有多个表达式，最后一个表达式的值作为返回值

(section 1 "defn Basics")

(defn add [a b] (+ a b))
(defn greet
  "Greet someone by name."
  [name]
  (str "Hello, " name "!"))

(say "(add 3 4):" (add 3 4))
(say "(greet \"World\"):" (greet "World"))

;; ---- 2) 参数模型 ----
;; Clojure 支持多种参数模式

(section 2 "Arity and Variadic")

;; 多参数体（arity overloading）
(defn multiply
  ([] 0)
  ([x] x)
  ([x y] (* x y))
  ([x y & more] (apply * x y more)))

(say "(multiply):" (multiply))
(say "(multiply 5):" (multiply 5))
(say "(multiply 2 3):" (multiply 2 3))
(say "(multiply 2 3 4):" (multiply 2 3 4))
(say "(multiply 2 3 4 5):" (multiply 2 3 4 5))

;; 可变参数 & 收集为列表
(defn sum-all [& nums] (apply + nums))
(say "(sum-all 1 2 3 4 5):" (sum-all 1 2 3 4 5))
(say "(sum-all):" (sum-all))

;; 固定参数 + 可变参数
(defn first-and-rest
  "First arg fixed, rest collected."
  [first & rest]
  {:first first :rest rest})
(say "(first-and-rest 1 2 3):" (first-and-rest 1 2 3))

;; ---- 3) 匿名函数 ----
;; fn 创建匿名函数
;; #(...) 是匿名函数的简写（reader macro）

(section 3 "Anonymous Functions")

(def anon-add (fn [a b] (+ a b)))
(say "(anon-add 3 4):" (anon-add 3 4))

;; 简写形式：#(...)
;; % 表示第一个参数, %2 第二个, %& 所有参数
(say "(#(+ %1 %2) 3 4):" (#(+ %1 %2) 3 4))
(say "(#(* 2 %) 5):" (#(* 2 %) 5))
(say "(#(* %1 %2 %3) 1 2 3):" (#(* %1 %2 %3) 1 2 3))
(say "(#(apply + %&) 1 2 3 4):" (#(apply + %&) 1 2 3 4))

;; 作为高阶函数的参数
(say "(map #(* % %) [1 2 3 4]):" (map #(* % %) [1 2 3 4]))
(say "(filter #(> % 2) [1 2 3 4]):" (filter #(> % 2) [1 2 3 4]))
(say "(reduce #(+ %1 %2) [1 2 3 4]):" (reduce #(+ %1 %2) [1 2 3 4]))

;; ---- 4) 闭包 ----
;; 闭包：函数捕获其定义环境中的变量
;; 每次调用 make-counter 创建一个独立的计数器

(section 4 "Closures")

(defn make-counter
  "Create a counter function that captures its own state."
  [init]
  (let [state (atom init)]
    (fn []
      (swap! state inc))))

(def c1 (make-counter 0))
(def c2 (make-counter 100))

(say "(c1):" (c1))
(say "(c1):" (c1))
(say "(c1):" (c1))
(say "(c2):" (c2))                    ;; c2 独立于 c1
(say "(c1):" (c1))

;; 另一个闭包示例
(defn make-adder [n]
  (fn [x] (+ x n)))

(def add-5 (make-adder 5))
(def add-10 (make-adder 10))
(say "(add-5 3):" (add-5 3))
(say "(add-10 3):" (add-10 3))

;; ---- 5) apply 与 partial ----
;; apply：将列表展开为参数
;; partial：偏应用（固定部分参数）

(section 5 "apply and partial")

(say "(apply + [1 2 3 4 5]):" (apply + [1 2 3 4 5]))
(say "(apply + 1 2 [3 4 5]):" (apply + 1 2 [3 4 5]))
(say "(apply max [3 1 4 1 5 9 2 6]):" (apply max [3 1 4 1 5 9 2 6]))

(def add-10 (partial + 10))
(say "(add-10 5):" (add-10 5))
(say "(add-10 5 10 20):" (add-10 5 10 20))

(def only-gt-2 (partial filter #(> % 2)))
(say "(only-gt-2 [1 2 3 4 5]):" (only-gt-2 [1 2 3 4 5]))

;; ---- 6) 函数作为一等公民 ----
;; 函数可以作为参数传递、作为返回值、存储在集合中

(section 6 "Functions as First-Class Citizens")

(def ops [+ - * /])
(say "((ops 0) 2 3):" ((ops 0) 2 3))
(say "((ops 1) 2 3):" ((ops 1) 2 3))
(say "((ops 2) 2 3):" ((ops 2) 2 3))

;; 函数组合
(defn compose [f g]
  (fn [x] (f (g x))))

(def add-1 (fn [x] (+ x 1)))
(def double-it (fn [x] (* x 2)))
(def add-1-then-double (compose double-it add-1))
(say "(add-1-then-double 5):" (add-1-then-double 5))

;; 内置 comp 函数
(def add-1-then-double-builtin (comp double-it add-1))
(say "(comp version)(add-1-then-double-builtin 5):"
     (add-1-then-double-builtin 5))

;; comp 多个函数
(def f (comp #(* % 2) #(+ % 1) #(- % 3)))
(say "(comp 3 fns) ((comp #(* % 2) #(+ % 1) #(- % 3)) 10):" (f 10))

;; identity 函数
(say "(identity 42):" (identity 42))
(say "(map identity [1 2 3]):" (map identity [1 2 3]))

;; constantly 函数
(def always-42 (constantly 42))
(say "(always-42 \"ignored\"):" (always-42 "ignored"))
(say "(always-42 nil):" (always-42 nil))

;; ---- 7) 前置/后置条件 ----
;; 使用 :pre 和 :post 进行断言
;; 违反条件会抛出 AssertionError

(section 7 "Pre/Post Conditions")

(defn safe-div
  "Divide with preconditions."
  [a b]
  {:pre [(not= b 0)]}
  (/ a b))

(say "(safe-div 10 2):" (safe-div 10 2))
;; (safe-div 10 0)  ;; 会抛出 AssertionError

(defn clamp-0-100
  "Clamp value with postcondition."
  [x]
  {:post [(<= 0 % 100)]}
  (max 0 (min 100 x)))

(say "(clamp-0-100 50):" (clamp-0-100 50))
(say "(clamp-0-100 -10):" (clamp-0-100 -10))
(say "(clamp-0-100 200):" (clamp-0-100 200))

(defn -main [& args]
  (println "")
  (println "==== 04 jieshu ===="))

(-main)
