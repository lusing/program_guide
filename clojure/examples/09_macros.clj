;; ==========================================================================
;; 09_macros.clj - 宏与元编程
;; ==========================================================================
;; 主题：Clojure 的宏系统
;; 内容：
;;   1. 宏基础（defmacro）
;;   2. syntax-quote 与 unquote
;;   3. unquote-splicing
;;   4. macroexpand 与 macroexpand-1
;;   5. gensym 与卫生宏
;;   6. 常用宏：unless、postfix、swap-vars
;;   7. 宏 vs 函数
;;
;; 运行方式：
;;   clojure -M 09_macros.clj
;; ==========================================================================

(ns clojure-tutorial.09-macros)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 宏基础 ----
;; 宏在编译时展开，操作的是代码（S-表达式）本身
;; 宏接收未求值的参数（代码），返回新代码

(section 1 "Macro Basics")

;; unless：if 的否定版本
(defmacro unless [test body]
  (list 'if (list 'not test) body))

(say "(unless false \"runs\"):" (unless false "runs"))
(say "(unless true \"runs\"):" (unless true "runs"))

;; 更好的写法使用 syntax-quote
(defmacro unless2 [test body]
  `(if (not ~test) ~body))

(say "(unless2 false \"runs2\"):" (unless2 false "runs2"))
(say "(unless2 true \"runs2\"):" (unless2 true "runs2"))

;; ---- 2) syntax-quote 与 unquote ----
;; syntax-quote (`) 引用整个表达式，防止求值
;; unquote (~) 在引用中插入求值结果
;; 这类似 Common Lisp 的反引号

(section 2 "syntax-quote and unquote")

(def x 42)

;; quote 完全不求值
(say "'(+ 1 2):" '(+ 1 2))

;; syntax-quote 也不求值，但支持 unquote
(say "`(+ 1 2):" `(+ 1 2))
(say "`(+ 1 ~x):" `(+ 1 ~x))
(say "`(~x ~x ~x):" `(~x ~x ~x))

;; unquote 在结构中使用
(def name "Alice")
(say "`(Hello ~name):" `(Hello ~name))

;; ---- 3) unquote-splicing ----
;; ~@ 将列表展开为多个元素
;; 类似于 Common Lisp 的 ,@

(section 3 "unquote-splicing")

(def args '[1 2 3])

(say "`(~@args):" `(~@args))
(say "`(+ ~@args):" `(+ ~@args))
(say "`[~@args 4 5]:" `[~@args 4 5])

;; 实际应用：构建函数调用
(defmacro call-with-args [f & args]
  `(~f ~@args))

(say "(call-with-args + 1 2 3):" (call-with-args + 1 2 3))
(say "(call-with-args str \"a\" \"b\" \"c\"):"
     (call-with-args str "a" "b" "c"))

;; ---- 4) macroexpand 与 macroexpand-1 ----
;; macroexpand-1：展开一层宏
;; macroexpand：递归展开所有宏

(section 4 "macroexpand")

(say "(macroexpand-1 '(unless true \"x\")):"
     (macroexpand-1 '(unless true "x")))
(say "(macroexpand '(unless true \"x\")):"
     (macroexpand '(unless true "x")))
(say "(macroexpand '(unless2 true \"x\")):"
     (macroexpand '(unless2 true "x")))
(say "(macroexpand '(and 1 2 3)):" (macroexpand '(and 1 2 3)))
(say "(macroexpand '(or 1 2 3)):" (macroexpand '(or 1 2 3)))
(say "(macroexpand '(-> 5 (+ 3) (* 2))):"
     (macroexpand '(-> 5 (+ 3) (* 2))))

;; ---- 5) gensym 与卫生宏 ----
;; 宏中定义的变量名可能与调用者的变量冲突
;; gensym 创建唯一的符号，避免命名冲突
;; # 后缀是自动 gensym 的语法糖

(section 5 "gensym and Hygiene")

;; 不安全的宏：临时变量可能冲突
(defmacro swap-vars-bad [a b]
  `(let [tmp# ~a]
     (set! ~a ~b)
     (set! ~b tmp#)))

;; 安全的宏：使用 gensym（# 后缀自动 gensym）
(defmacro my-when [test & body]
  `(if ~test (do ~@body) nil))

(say "(my-when true (println \"ran\") 42):" (my-when true (println "ran") 42))
(say "(my-when false (println \"ran\") 42):" (my-when false (println "ran") 42))

;; ---- 6) 常用宏示例 ----

(section 6 "Practical Macros")

;; postfix：将后缀表达式转为前缀
;; (postfix (1 2 +)) -> (+ 1 2)
(defmacro postfix [[a b op]]
  (list op a b))

(say "(postfix (1 2 +)):" (postfix (1 2 +)))
(say "(postfix (3 4 *)):" (postfix (3 4 *)))
(say "(postfix (10 2 -)):" (postfix (10 2 -)))

;; my-or：实现 or 宏（短路求值）
(defmacro my-or
  ([] nil)
  ([x] x)
  ([x & rest]
   `(let [e# ~x]
      (if e# e# (my-or ~@rest)))))

(say "(my-or):" (my-or))
(say "(my-or nil):" (my-or nil))
(say "(my-or nil 42):" (my-or nil 42))
(say "(my-or nil false 99):" (my-or nil false 99))

;; my-and：实现 and 宏（短路求值）
(defmacro my-and
  ([] true)
  ([x] x)
  ([x & rest]
   `(when ~x (my-and ~@rest))))

(say "(my-and):" (my-and))
(say "(my-and true):" (my-and true))
(say "(my-and true false):" (my-and true false))
(say "(my-and true true 42):" (my-and true true 42))

;; with-logging：在执行前后添加日志
(defmacro with-logging [label & body]
  `(do
     (println "[START]" ~label)
     (let [result# (do ~@body)]
       (println "[END]" ~label "=>" result#)
       result#)))

(say "(with-logging \"task\" (+ 1 2)):" (with-logging "task" (+ 1 2)))

;; ---- 7) 宏 vs 函数 ----
;; 宏在编译时展开，操作代码
;; 函数在运行时执行，操作值
;; 有些功能只能用宏实现（短路求值、延迟求值）

(section 7 "Macros vs Functions")

;; 这个不能用函数实现：参数需要不被求值
;; (if-fn true (println "yes") (println "no"))
;; 如果是函数，两个 println 都会执行
(defmacro my-if [test then else]
  `(if ~test ~then ~else))

(say "(my-if true \"yes\" \"no\"):" (my-if true "yes" "no"))
(say "(my-if false \"yes\" \"no\"):" (my-if false "yes" "no"))

;; 线程优先宏 -> 的展开
(say "macroexpand (-> 5 inc):" (macroexpand '(-> 5 inc)))
(say "macroexpand (-> 5 (+ 3)):" (macroexpand '(-> 5 (+ 3))))
(say "macroexpand (->> 5 (+ 3)):" (macroexpand '(->> 5 (+ 3))))

(defn -main [& args]
  (println "")
  (println "==== 09 jieshu ===="))

(-main)
