;; ==========================================================================
;; 02_data_types.clj - 数据类型
;; ==========================================================================
;; 主题：Clojure 的核心数据类型
;; 内容：
;;   1. 整数与浮点数
;;   2. 比值（Ratio）
;;   3. 字符串与字符
;;   4. 关键字（Keyword）
;;   5. 布尔值与 nil
;;   6. BigDecimal
;;   7. 类型谓词
;;
;; 运行方式：
;;   clojure -M 02_data_types.clj
;; ==========================================================================

(ns clojure-tutorial.02-data-types)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) 整数与浮点数 ----
;; Clojure 整数可以是 int, long, bigint, BigInteger
;; 默认整数字面量是 long（64 位有符号整数）
;; 浮点数字面量默认是 double（64 位 IEEE 754）

(section 1 "Integers and Floats")

(def int-num 42)
(def long-num 9223372036854775807)   ;; Long/MAX_VALUE
(def big-int 99999999999999999999999N) ;; N 后缀 -> BigInteger
(def hex-num 0xFF)                    ;; 十六进制 255
(def oct-num (Integer/parseInt "40" 8))  ;; 八进制 32
(def bin-num (Integer/parseInt "1010" 2)) ;; 二进制 10
(def float-num 3.14)
(def sci-num 1.5e3)                    ;; 科学计数法 1500.0
(def float-d 3.14M)                    ;; M 后缀 -> BigDecimal

(say "int-num:" int-num "(type:" (type int-num) ")")
(say "hex-num:" hex-num)
(say "bin-num:" bin-num)
(say "float-num:" float-num "(type:" (type float-num) ")")
(say "sci-num:" sci-num)
(say "float-d (BigDecimal):" float-d "(type:" (type float-d) ")")

;; ---- 2) 比值（Ratio）----
;; Clojure 的独特特性：精确分数运算
;; (/ 1 3) 不等于 0.333... 而是精确的 1/3

(section 2 "Ratios")

(def one-third (/ 1 3))
(def two-sixths (/ 2 6))    ;; 自动约分为 1/3

(say "(/ 1 3):" one-third "(type:" (type one-third) ")")
(say "(/ 2 6):" two-sixths)
(say "(+ 1/3 1/3):" (+ 1/3 1/3))
(say "(* 1/3 3):" (* 1/3 3))
(say "(double 1/3):" (double 1/3))
(say "(/ 10 3):" (/ 10 3))
(say "Rational? (rational? (/ 1 3)):" (rational? (/ 1 3)))

;; ---- 3) 字符串与字符 ----
;; 字符串用双引号，字符用反斜杠前缀
;; 字符串是 Java String，不可变
;; 字符是 Java Character

(section 3 "Strings and Characters")

(def str-normal "Hello World")
(def str-escape "line1\nline2\ttabbed")
(def str-multi "multi
line
string")                              ;; 多行字符串

(say "str-normal:" str-normal)
(say "str-escape:" str-escape)
(say "Length:" (count str-normal))
(say "Concat:" (str "abc" "def" 123))
(say "Substring (.substring):" (.substring "hello" 1 3))
(say "Uppercase:" (.toUpperCase "hello"))
(say "Split:" (clojure.string/split "a,b,c" #","))
(say "Join:" (clojure.string/join "-" ["a" "b" "c"]))

;; 字符
(def char-a \a)
(def char-newline \newline)
(def char-tab \tab)
(def char-unicode \u03BB)             ;; lambda

(say "char-a:" char-a "(type:" (type char-a) ")")
(say "char-newline:" (int char-newline))
(say "char-unicode:" char-unicode)
(say "(str char-a):" (str char-a))

;; ---- 4) 关键字（Keyword）----
;; 关键字以冒号开头，是一种「自引用符号」
;; 关键字相等的判定是身份（identity），非常高效
;; 常用作映射的键、枚举值、函数分发

(section 4 "Keywords")

(def kw1 :hello)
(def kw2 :hello)
(def kw-ns :user/name)                ;; 命名空间关键字
(def kw-auto ::name)                 ;; 自动命名空间（当前 ns）

(say "kw1:" kw1)
(say "kw2:" kw2)
(say "Identical? (identical? kw1 kw2):" (identical? kw1 kw2))
(say "= kw1 kw2:" (= kw1 kw2))
(say "kw-ns:" kw-ns)
(say "kw-auto:" kw-auto)
(say "Name (name kw1):" (name kw1))
(say "Namespace (namespace kw-ns):" (namespace kw-ns))
(say "Keyword? (keyword? kw1):" (keyword? kw1))

;; 关键字作为函数（从映射中取值）
(def person {:name "Alice" :age 30})
(say "(:name person):" (:name person))
(say "(:age person):" (:age person))
(say "(:missing person):" (:missing person))
(say "(:missing person \"default\"):" (:missing person "default"))

;; ---- 5) 布尔值与 nil ----
;; true 和 false 是布尔值
;; nil 是空值（类似 null，但更安全）
;; 在布尔上下文中，nil 和 false 是假值，其他都是真值

(section 5 "Booleans and nil")

(say "true:" true)
(say "false:" false)
(say "nil:" nil)
(say "Boolean true?:" (true? true))
(say "Boolean false?:" (false? false))
(say "Nil? (nil? nil):" (nil? nil))
(say "Some? (some? nil):" (some? nil))       ;; some? = not nil
(say "Some? (some? 0):" (some? 0))            ;; 0 是真值！
(say "Some? (some? \"\"):" (some? ""))        ;; 空字符串是真值！
(say "Some? (some? []):" (some? []))          ;; 空集合是真值！

;; if 中只有 nil 和 false 为假
(say "(if 0 :truthy :falsy):" (if 0 :truthy :falsy))
(say "(if nil :truthy :falsy):" (if nil :truthy :falsy))
(say "(if false :truthy :falsy):" (if false :truthy :falsy))
(say "(if [] :truthy :falsy):" (if [] :truthy :falsy))

;; ---- 6) BigDecimal ----
;; 精确十进制运算，适合财务计算
;; M 后缀创建 BigDecimal 字面量

(section 6 "BigDecimal")

(def bd1 3.14M)
(def bd2 0.1M)
(def bd3 0.2M)

(say "bd1:" bd1 "(type:" (type bd1) ")")
(say "(+ 0.1 0.2) double:" (+ 0.1 0.2))
(say "(+ 0.1M 0.2M) BigDecimal:" (+ 0.1M 0.2M))
(say "(* 3M 3.14M):" (* 3M 3.14M))

;; ---- 7) 类型谓词 ----
;; Clojure 提供丰富的类型检查函数

(section 7 "Type Predicates")

(say "(integer? 42):" (integer? 42))
(say "(integer? 42.0):" (integer? 42.0))
(say "(float? 3.14):" (float? 3.14))
(say "(double? 3.14):" (double? 3.14))
(say "(ratio? 1/3):" (ratio? 1/3))
(say "(rational? 1/3):" (rational? 1/3))
(say "(rational? 42):" (rational? 42))
(say "(string? \"hi\"):" (string? "hi"))
(say "(char? \\a):" (char? \a))
(say "(keyword? :hi):" (keyword? :hi))
(say "(symbol? 'x):" (symbol? 'x))
(say "(number? 42):" (number? 42))
(say "(boolean? true):" (boolean? true))
(say "(nil? nil):" (nil? nil))
(say "(fn? +):" (fn? +))
(say "(coll? [1 2]):" (coll? [1 2]))
(say "(sequential? [1 2]):" (sequential? [1 2]))
(say "(associative? {:a 1}):" (associative? {:a 1}))

;; ---- 调用 -main ----
(defn -main [& args]
  (println "")
  (println "==== 02 jieshu ===="))

(-main)
