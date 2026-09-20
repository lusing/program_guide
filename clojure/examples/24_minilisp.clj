;; ==========================================================================
;; 24_minilisp.clj - 综合实战压轴：用 Clojure 写一个 Lisp 解释器
;; ==========================================================================
;; 主题：MiniLisp——一门运行在 Clojure 里的 Scheme 风格小语言
;;
;; 这是一个"元循环"（metacircular）式的练习：Lisp 的代码就是数据，
;; 所以用 Lisp 解释 Lisp，词法分析器、求值器、环境都只是一两百行。
;;
;; 组成：
;;   1. 词法分析 tokenize：字符串 → token 序列
;;   2. 语法分析 parse：token → 嵌套列表（就是普通 Clojure 数据）
;;   3. 环境：{符号 → 值} 的链表（子环境 → 父环境）
;;   4. 求值器 ml-eval：special forms + 函数应用，支持尾调用优化
;;   5. 内置函数：算术 / 比较 / 表操作
;;   6. 测试与演示：阶乘、斐波那契、闭包、高阶函数、百万次尾递归
;;
;; 支持的 special forms：
;;   (quote e)   (if test then else?)   (def sym e)
;;   (fn [params] body)                 (let (sym e ...) body ...)
;;   (do e ...)   (and e ...)   (or e ...)
;;
;; 运行方式：
;;   clojure -M 24_minilisp.clj     # macOS/Linux（Clojure CLI）
;;   见 build.ps1 / build.sh           # 本教程统一验证入口
;; ==========================================================================

(ns clojure-tutorial.24-minilisp
  (:require [clojure.string :as str]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ==========================================================================
;; 1) 词法分析与语法分析
;; ==========================================================================

(section 1 "tokenizer and parser (code is data)")

;; tokenize：剥掉 ; 注释，然后用正则切出括号 / 整数 / 字符串 / 符号
;; #t / #f 两个布尔字面量先按符号切出来，read-atom 再识别。
(defn tokenize [s]
  (->> (str/replace s #"(?m);[^\n]*" "")       ;; ; 到行尾是注释
       (re-seq #"-?\d+|[()]|\"[^\"]*\"|[^\s()]+")
       vec))

(defn read-atom [t]
  (cond
    (re-matches #"-?\d+" t) (Long/parseLong t)  ;; 整数字面量
    (.startsWith ^String t "\"") (subs t 1 (dec (count t))) ;; 字符串去引号
    (= t "#t") true
    (= t "#f") false
    :else (symbol t)))                          ;; 其余全是符号

(declare parse-form)

;; parse-until：读到右括号为止，把元素收集成 Clojure list
(defn parse-until [tokens acc]
  (if (= (first tokens) ")")
    [(apply list acc) (rest tokens)]
    (let [[form remaining] (parse-form tokens)]
      (recur remaining (conj acc form)))))

;; parse-form：解析一个表达式，返回 [表达式 剩余token]
(defn parse-form [tokens]
  (let [t (first tokens)]
    (cond
      (= t "(") (parse-until (rest tokens) [])
      (= t ")") (throw (ex-info "Unexpected )" {:tokens tokens}))
      :else [(read-atom t) (rest tokens)])))

;; parse-string：整段源码 → 表单列表
(defn parse-string [s]
  (loop [toks (tokenize s), forms ()]
    (if (empty? toks)
      (reverse forms)
      (let [[f remaining] (parse-form toks)]
        (recur remaining (conj forms f))))))

;; 展示"代码即数据"：解析结果就是普通的嵌套 Clojure 列表
(say "(parse-string \"(+ 1 (* 2 3))\") =>"
     (pr-str (parse-string "(+ 1 (* 2 3))")))
(say "(parse-string \"(let (x 1) x)\") =>"
     (pr-str (parse-string "(let (x 1) x)")))

;; ==========================================================================
;; 2) 环境：符号表组成的链
;; ==========================================================================

(section 2 "environments")

;; 每个环境是一个 atom：{:vars {符号 值} :parent 父环境或 nil}
;; atom 让 def 能改写全局环境（闭包持有环境引用，因此能看到后来的定义）
(defn make-env [parent]
  (atom {:vars {} :parent parent}))

(defn env-set! [env sym val]
  (swap! env assoc-in [:vars sym] val))

;; 查找：沿 :parent 链向上走 —— 这就是词法作用域
(defn env-lookup [env sym]
  (loop [e env]
    (cond
      (nil? e)
      (throw (ex-info (str "Unbound symbol: " sym) {:sym sym}))

      (contains? (:vars @e) sym)
      (get-in @e [:vars sym])

      :else
      (recur (:parent @e)))))

(defn env-root [env]
  (if-let [p (:parent @env)] (recur p) env))

;; MiniLisp 的 def 永远定义在根（全局）环境
(defn env-define! [env sym val]
  (env-set! (env-root env) sym val))

;; ==========================================================================
;; 3) 求值器
;; ==========================================================================

(section 3 "evaluator with tail-call optimization")

;; MiniLisp 的真值语义：只有 #f 和 nil 为假（沿用 Clojure/Scheme 习惯）
(defn truthy? [v]
  (boolean v))

;; 闭包就是普通 map —— 再次印证"一切都是数据"
(defn closure? [x]
  (and (map? x) (= (:op x) 'closure)))

(declare ml-eval)

(defn ml-eval [form env]
  (loop [form form                            ;; loop/recur 实现尾调用优化：
         env   env]                           ;; 尾位置的表达式不压栈
    (cond
      ;; 自求值类型
      (or (number? form) (string? form) (boolean? form) (keyword? form)) form

      ;; 符号：查环境
      (symbol? form) (env-lookup env form)

      ;; 列表：special form 或函数应用
      (seq? form)
      (let [[op & args] form]
        (case op
          ;; (quote e)：不求值，原样返回
          quote (first args)

          ;; (if test then else?)：尾位置递归求值
          if (let [test (ml-eval (first args) env)]
               (if (truthy? test)
                 (recur (second args) env)
                 (when-some [alt (nth args 2 nil)]
                   (recur alt env))))

          ;; (def sym e)：全局定义（返回值）
          def (let [sym (first args)
                    val (ml-eval (second args) env)]
                (env-define! env sym val)
                val)

          ;; (fn (参数...) body)：构造闭包，捕获当前环境
          fn (let [[params body] args]
               {:op 'closure :params params :body body :env env})

          ;; (let (sym e ...) body...)：子环境 + 顺序绑定
          let (let [child (make-env env)]
                (doseq [[sym expr] (partition 2 (first args))]
                  (env-set! child sym (ml-eval expr child)))
                (doseq [f (butlast (rest args))]  ;; 先求非尾表达式
                  (ml-eval f child))
                (when-some [last-form (last (rest args))]
                  (recur last-form child)))

          ;; (do e ...)：顺序求值，最后一个进尾位置
          do (do (doseq [f (butlast args)]
                   (ml-eval f env))
                 (when-some [last-form (last args)]
                   (recur last-form env)))

          ;; (and a b ...) 展开为 (if a (and b ...) a) —— 宏式脱糖
          and (case (count args)
                0 true
                1 (recur (first args) env)
                (recur (list 'if (first args)
                             (cons 'and (rest args))
                             (first args))
                        env))

          ;; (or a b ...) 展开为 (let (g a) (if g g (or b ...)))
          or (case (count args)
               0 nil
               1 (recur (first args) env)
               (let [g (gensym "or_")]
                 (recur (list 'let (list g (first args))
                              (list 'if g g (cons 'or (rest args))))
                        env)))

          ;; 函数应用
          (let [callee (ml-eval op env)
                argv   (mapv #(ml-eval % env) args)]
            (if (closure? callee)
              ;; 闭包：新建子环境绑定形参，尾位置求值函数体
              (let [child (make-env (:env callee))]
                (doseq [[p a] (map vector (:params callee) argv)]
                  (env-set! child p a))
                (recur (:body callee) child))
              ;; 内置函数：直接 apply Clojure 函数
              (apply callee argv)))))

      :else (throw (ex-info (str "Cannot eval: " (pr-str form))
                            {:form form})))))

;; ==========================================================================
;; 4) 内置函数
;; ==========================================================================

(section 4 "builtins")

(defn ml-print [x]
  ;; pr-str 保真打印（字符串带引号、列表有括号）
  (println (pr-str x))
  x)

(def global-env (make-env nil))

;; 注意键要加 quote（存的是符号），值不能加（存的是函数本身）——
;; 写成 '* '* 会把【符号 *】存进去：Symbol 也是可调用的（等价 get 查找），
;; (* 2 3) 会诡异地返回 3 而不是 6，这是个真实的调试案例。
;; +' *' 是"自动升位"版本：溢出 long 时自动转 BigInteger。
(doseq [[sym f] {'+ +' '- - '* *' '/ / 'mod mod
                 '= = '< < '> > '<= <= '>= >= 'not not
                 'list list 'car first 'cdr rest 'cons cons
                 'null? (fn [l] (= l '())) 'length count
                 'print ml-print}]
  (env-set! global-env sym f))

(say "Builtins installed:" (count (:vars @global-env)))

(defn ml-eval-string [s]
  (last (map #(ml-eval % global-env) (parse-string s))))

;; ==========================================================================
;; 5) 测试与演示
;; ==========================================================================

(section 5 "MiniLisp programs")

(def pass-count (atom 0))
(def fail-count (atom 0))

(defn check [src expected]
  (let [got (try
              (ml-eval-string src)
              (catch Exception e
                (str "ERROR: " (.getMessage e))))]
    (if (= got expected)
      (do (swap! pass-count inc)
          (say "PASS" src "=>" (pr-str got)))
      (do (swap! fail-count inc)
          (say "FAIL" src)
          (say "     expected:" (pr-str expected))
          (say "     got:     " (pr-str got))))))

;; --- 算术与真值 ---
(check "(+ 1 2 (* 3 4))" 15)
(check "(- 5)" -5)
(check "(/ 1 3)" 1/3)                            ;; 精确比值
(check "(mod 10 3)" 1)
(check "(if (< 1 2) 10 99)" 10)
(check "(if #f 10 99)" 99)
(check "(if 0 10 99)" 10)                        ;; 0 是真值！

;; --- quote 与表操作 ---
(check "(quote (a b c))" '(a b c))
(check "(car (quote (a b c)))" 'a)
(check "(cdr (quote (a b c)))" '(b c))
(check "(cons 1 (quote (2 3)))" '(1 2 3))
(check "(null? (quote ()))" true)
(check "(length (list 1 2 3 4))" 4)
(check "\"hello\"" "hello")

;; --- let / do / and / or ---
(check "(let (x 2 y 3) (* x y))" 6)
(check "(let (x 1) (print x) (+ x 10))" 11)      ;; 多体 let
(check "(do (print 1) (print 2) 3)" 3)
(check "(and 1 2 3)" 3)                          ;; 返回最后一个真值
(check "(and 1 #f 3)" false)                     ;; 短路：3 不会被求值
(check "(or #f (and 1 2) 3)" 2)                  ;; 短路：3 不会被求值
(check "(and)" true)
(check "(or)" nil)

;; --- 短路语义验证：else 分支有未绑定符号也不炸 ---
(check "(and #f (this-is-unbound))" false)
(check "(or 7 (this-is-unbound))" 7)

;; --- 闭包与词法作用域 ---
(check "((fn (x) (* x x)) 7)" 49)
(check "(let (x 100) ((fn (y) (+ x y)) 1))" 101) ;; 捕获定义时的环境

;; --- def + 递归 ---
(check "(def fact (fn (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
        (fact 10)" 3628800)

(check "(def fib (fn (n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2))))))
        (fib 15)" 610)

;; --- 大整数：20! 就溢出 long，*' 自动升 BigInteger ---
(check "(def fact (fn (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
        (fact 25)" 15511210043330985984000000N)

;; --- 加法器工厂：返回闭包的闭包 ---
(check "(def adder (fn (n) (fn (x) (+ x n))))
        ((adder 10) 5)" 15)

;; --- MiniLisp 里写的 map：高阶函数 ---
;; 注意 MiniLisp 没有 'x 简写，空表要写成 (quote ())
(check "(def mymap (fn (f xs)
          (if (null? xs)
            (quote ())
            (cons (f (car xs)) (mymap f (cdr xs))))))
        (mymap (fn (x) (* x x)) (list 1 2 3 4 5))"
       '(1 4 9 16 25))

;; --- let 绑定函数再用 ---
(check "(let (sq (fn (x) (* x x)))
          (sq 12))" 144)

;; ==========================================================================
;; 6) 尾调用优化验证
;; ==========================================================================

(section 6 "tail-call optimization")

;; MiniLisp 自己没有 loop/recur，但求值器把「尾位置的调用」变成
;; Clojure 的 recur —— 于是 MiniLisp 获得了真正的尾调用优化：
;; 百万层递归不爆栈。这是解释器结构带来的免费午餐。

(say "Running (loop-down 1000000) in MiniLisp ...")
(let [sw (System/currentTimeMillis)
      result (ml-eval-string
               "(def loop-down (fn (n) (if (= n 0) (quote done) (loop-down (- n 1)))))
                (loop-down 1000000)")]
  (say "result:" result)
  (say "elapsed:" (- (System/currentTimeMillis) sw) "ms")
  (if (= result 'done)
    (swap! pass-count inc)
    (swap! fail-count inc)))

;; 对照：非尾位置的递归（(fact 100000)）会构造深层嵌套乘法，
;; 这里不做演示——MiniLisp 没有栈检查，会真把 JVM 栈吃满。

;; ==========================================================================
;; 7) 总结
;; ==========================================================================

(println)
(say "MiniLisp test summary: pass =" @pass-count ", fail =" @fail-count)
(when (pos? @fail-count)
  (throw (ex-info "MiniLisp tests FAILED" {:fail @fail-count})))

(say "Takeaways:")
(say " 1. Homoiconicity: MiniLisp source parses into plain Clojure data")
(say " 2. Environments are just {:vars {:parent}} chains - lexical scope")
(say " 3. Closures are maps capturing the defining environment")
(say " 4. Special forms are a case dispatch; everything else is application")
(say " 5. loop/recur in the evaluator gives MiniLisp free TCO")
(say " 6. and/or are desugared into if/let at eval time - mini macros!")

(defn -main [& args]
  (println "")
  (println "==== 24 jieshu ===="))

(-main)
