# 28 · 压轴实战：MiniLisp 解释器 ⭐

> 对应示例：`examples/24_minilisp.clj`（33 断言全过，含百万次尾递归验证）

> 用约 200 行 Clojure 实现一门 Scheme 风格小语言。这是全书知识点的
> 总装仪式，也是 Lisp 精神的终极体验：**代码即数据，所以解释器
> 不过是一个"数据加工管线"**。

## 28.1 为什么压轴是解释器

- **homoiconicity 的现场证明**：MiniLisp 源码解析出来就是 Clojure 数据——没有 AST 类、没有访问者模式。
- **知识点全覆盖**：解析（正则/递归下降）、环境（map + atom 链）、求值（case 分发 + loop/recur）、闭包（捕获环境的 map）。
- **元循环**（metacircular）：用 Lisp 解释 Lisp——SICP 第四章的核心练习。

MiniLisp 语言规格：

```scheme
(def fact (fn (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
(fact 10)                              ; => 3628800
(let (x 2 y 3) (* x y))                ; => 6
(and 1 #f (explode))                   ; => #f（短路，explode 不求值）
(def mymap (fn (f xs) (if (null? xs) (quote ())
                         (cons (f (car xs)) (mymap f (cdr xs))))))
(mymap (fn (x) (* x x)) (list 1 2 3))  ; => (1 4 9)
```

special forms：`quote if def fn let do and or`；内置：`+ - * / mod = < > <= >= not list car cdr cons null? length print`。

## 28.2 阶段一：tokenize + parse

```clojure
(defn tokenize [s]
  (->> (str/replace s #"(?m);[^\n]*" "")            ; 剥注释
       (re-seq #"-?\d+|[()]|\"[^\"]*\"|[^\s()]+")   ; 整数/括号/字符串/符号
       vec))

(parse-string "(+ 1 (* 2 3))")     ; => ((+ 1 (* 2 3)))   <- 普通 Clojure 数据！
```

递归下降解析器——`(` 进入递归收集、`)` 收尾回传；括号串变成 `(apply list acc)`（代码表用 Clojure list，符号用 symbol，数字用 long）。**这一步之后再也没有"语法"这回事**——求值器面对的是纯数据。

## 28.3 阶段二：环境链 = 词法作用域

```clojure
(defn make-env [parent] (atom {:vars {} :parent parent}))

(defn env-lookup [env sym]            ; 沿 :parent 链上溯 —— 这就是词法作用域
  (loop [e env]
    (cond (nil? e) (throw ...)
          (contains? (:vars @e) sym) (get-in @e [:vars sym])
          :else (recur (:parent @e)))))
```

环境是 `{:vars {符号 值} :parent 父环境}` 的 **atom 链**：

- `let`/函数调用 → `make-env` 建子环境（06 章闭包的"环境"实物化）。
- `def` → 永远写根环境（walk to root）。
- atom 让"后来的定义"对**已创建的闭包**可见——递归 `def` 因此成立：闭包捕获的是全局环境**引用**，swap! 之后 `(fact (- n 1))` 查得到 fact 自己。

## 28.4 阶段三：求值器 + 免费的尾调用优化 ⭐

```clojure
(defn ml-eval [form env]
  (loop [form form env env]                 ;; loop/recur 是 TCO 的载体
    (cond
      (number? form) form                   ; 自求值类型直通
      (symbol? form) (env-lookup env form)
      (seq? form)
      (let [[op & args] form]
        (case op
          quote (first args)
          if (let [t (ml-eval (first args) env)]
               (if (truthy? t)
                 (recur (second args) env)          ;; 尾位置 → recur！
                 (when-some [alt (nth args 2 nil)]
                   (recur alt env))))
          fn {:op 'closure :params (first args) :body (second args) :env env}
          ;; ... def let do and or ...
          ;; 兜底：函数应用
          (let [callee (ml-eval op env)
                argv (mapv #(ml-eval % env) args)]
            (if (closure? callee)
              (let [child (make-env (:env callee))]
                (doseq [[p a] (map vector (:params callee) argv)]
                  (env-set! child p a))
                (recur (:body callee) child))       ;; 调用体也走 recur
              (apply callee argv))))))))
```

**关键技巧**：求值器主体是 `(loop [form env] ...)`，所有**尾位置**的表达式（if 分支、函数体）用 `recur` 回到循环头——栈不增长。于是：

```scheme
(def loop-down (fn (n) (if (= n 0) (quote done) (loop-down (- n 1)))))
(loop-down 1000000)                   ; => done，实测约 1 秒，栈深度恒定
```

MiniLisp 自己没有 `loop`/`recur`，但**求值器送了它尾调用优化**——这是解释器结构带来的免费午餐（JVM 不做通用 TCO，Clojure 程序员用 recur 绕过，解释器作者用"求值循环"绕过，一脉相承）。

**闭包就是一个 map**（捕获定义环境）：`{:op 'closure :params ... :body ... :env env}`——13 章"reify 捕获局部"的数据版注脚。

## 28.5 and/or：宏式脱糖

```clojure
;; (and a b c) 在求值时被改写为 (if a (and b c) a)，再递归
and (case (count args)
      0 true
      1 (recur (first args) env)
      (recur (list 'if (first args)
                   (cons 'and (rest args))
                   (first args))
              env))
;; (or a b) => (let (g a) (if g g (or b)))   g 是 gensym
```

**改写代码再求值** = 宏的本质（11 章）。`gensym`（`or_` 前缀）防变量名冲突——11 章卫生宏的现场复刻。

## 28.6 实测彩蛋：Symbol 是可调用的（真事）

开发中真实踩到的坑，值得讲给每个人听：

```clojure
;; 内置表笔误写成 {'* '* ...}（值也加了 quote）
;; 于是 MiniLisp 的 * 查到的是【符号】而不是函数
```

Clojure 的 Symbol 实现了 IFn（06 章）——`('* 2 3)` 不抛异常，等价 `(get 2 * 3)`：**在 2 里查键 `*` 查不到，返回默认值 3**。于是：

```scheme
(fact 10)   ; 算出 1 而不是 3628800 —— (* n (fact (- n 1))) 每层都"返回第二个参数"
```

全程无异常、无警告，只有结果错——这类静默 bug 只有**断言测试**能抓（18 章的 `check` 33 条断言逮住了它）。教训：① 高阶位置喂函数前 `(fn? f)` 断言；② 关键路径必须有数字对账。

## 28.7 大整数与 BigInt

内置算术用 `+'`/`*'`（04 章自动升位版），于是：

```scheme
(fact 25)   ; => 15511210043330985984000000   —— 20! 就溢出 long，25! 轻松算
```

语言设计的"细节慈悲"在解释器里也能透出来。

## 28.8 扩展练习

按难度递增，每个都是一次知识复用：

1. **字符串转义**：tokenizer 支持 `\"`/`\\`（正则 + 后处理）。
2. **`defn` 语法糖**：`(defn f (x) body)` 脱糖成 `(def f (fn (x) body))`——28.5 的同款手法。
3. **宏 `my-when`**：`(my-when t body)` → `(if t body #f)`——注意：参数**不求值**直传（quote 进来）。
4. **非尾递归的深度限制**：给 `(fib 30)` 这种树形递归加深度计数器抛友好错误（对比 TCO 路径为何不需要）。
5. **真 gensym 宏系统**：`defmacro` + 求值期展开（把 28.5 硬编码的脱糖变成用户可写）。
6. **REPL**：`read-line` 循环 + `try/catch` 打错误继续——`clojure.main/repl` 的源码是参考答案。

## 28.9 坑位清单

1. **环境用 atom 而"子环境也 atom"**：每层 env 一个独立 atom（示例做法）——图省事共享一个 atom 会把 let 变量泄漏成全局。
2. **`def` 写当前环境而不是根**：递归定义找不到自己（闭包捕获的是当时的快照语义错乱）——def 的语义就是"全局定义"。
3. **apply 一个非函数静默错**（28.6 全文）——`fn?` 断言或测试对账。
4. **`(quote ())` 写成 `'()`**：MiniLisp 没有 reader 简写，`'` 会被 tokenize 成普通符号——教学解释器先明确支持哪些糖。
5. **TCO 只覆盖尾位置**：`(do (f x) 1)` 的 `(f x)` 不在尾位——树形递归照爆栈（28.8 练习 5 的铺垫）。
6. **测试期望值写错比实现错更早被发现**：本章实测中 `(+ 1 2 (* 3 4))` 的期望值先写错成 13——**先验算期望，再怀疑实现**。

---

上一章：[27 生态与工具](27-ecosystem.md) · [回到目录](../README.md)
