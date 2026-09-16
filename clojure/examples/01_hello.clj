;; ==========================================================================
;; 01_hello.clj - Hello World、REPL 基础与基本输出
;; ==========================================================================
;; 本文件演示 Clojure 的基本程序结构：
;;   - println / prn / print / str 等输出函数
;;   - def 定义变量
;;   - 注释（单行 ; 和块注释 #_(...)）
;;   - 函数定义（defn）
;;   - -main 入口点
;;
;; 运行方式：
;;   clojure -M 01_hello.clj        # 直接运行
;;   clojure 01_hello.clj            # 也可直接运行
;; ==========================================================================

(ns clojure-tutorial.01-hello)

;; ---- 辅助函数：统一的输出方式 ----
;; say 函数：输出一行字符串，类似 println，但语义更直观
(defn say [& args] (println (apply str (interpose " " args))))

;; ---- 1) def 绑定与基本输出 ----
;; def 定义一个 Var（全局绑定），值不可变（但 Var 本身可被重新 def）
;; 注释以分号 ; 开始，直到行尾

(def hello "Hello, Clojure!")

(say "=== Section 1: def and output ===")
(say hello)
(say "println adds a newline automatically.")

;; ---- 2) 不同的输出函数 ----
;; println  -> 输出并换行（人类可读，字符串不带引号）
;; print    -> 输出不换行
;; prn      -> 输出并换行（机器可读，字符串带引号）
;; pr       -> 输出不换行（机器可读）
;; str      -> 将参数转为字符串拼接，不输出

(say "")
(say "=== Section 2: output functions ===")
(println "println: hello" 42 true)
(print "print: no newline -> ")
(print "continues here")
(println "")
(prn "prn: string shown with quotes")
(pr "pr: no newline -> ")
(pr "continues")
(println "")
(println "str:" (str "a" "b" "c" 1 2 3))

;; ---- 3) defn 定义函数 ----
;; defn 是 def + fn 的语法糖
;; 格式：(defn name docstring? [params] body)
(defn greet
  "Return a greeting string for the given name."
  [name]
  (str "Hello, " name "!"))

(say "")
(say "=== Section 3: defn ===")
(say (greet "World"))
(say (greet "Clojure"))

;; ---- 4) 多行字符串与格式化 ----
;; Clojure 字符串支持 \n \t 等转义字符
;; 也可用 clojure.core/format（Java String.format 包装）

(def multiline "line1\nline2\ttabbed")

(say "")
(say "=== Section 4: strings and format ===")
(say multiline)
(say (format "Name: %s, Age: %d, Pi: %.2f" "Alice" 30 3.14159))

;; ---- 5) 块注释 ----
;; #_(...) 会注释掉整个表达式
;; (comment ...) 也是一个常用方式（但会返回 nil，可在代码中任意位置放置）

#_(println "This is block-commented out")

(comment
  (println "comment block: this won't run")
  (+ 1 2))

;; ---- 6) 基本运算 ----
;; Clojure 使用前缀表达式（波兰表示法）
;; 运算符在前，操作数在后

(say "")
(say "=== Section 6: arithmetic ===")
(println "(+ 1 2 3):" (+ 1 2 3))
(println "(* 4 5 6):" (* 4 5 6))
(println "(- 10 3 2):" (- 10 3 2))
(println "(/ 20 4):" (/ 20 4))
(println "(/ 22 7):" (/ 22 7))
(println "(quot 22 7):" (quot 22 7))
(println "(rem 22 7):" (rem 22 7))
(println "(mod 22 7):" (mod 22 7))
(println "(+ 1.5 2.5):" (+ 1.5 2.5))
(println "(/ 1 3):" (/ 1 3))
(println "(double (/ 1 3)):" (double (/ 1 3)))

;; ---- 7) -main 入口点 ----
;; Clojure 脚本可以直接运行，不强制要求 -main 函数
;; 但如果定义了 -main，可以作为标准入口

(defn -main
  "Entry point for this script."
  [& args]
  (say "")
  (say "=== Section 7: -main entry point ===")
  (say "args:" (vec args))
  (say "Clojure version:" (clojure-version))
  (say "Java version:" (System/getProperty "java.version"))
  (say "")
  (say "==== 01 jieshu ===="))

;; ---- 直接调用 -main ----
(-main)
