# 07 · 控制流 ⭐

> 对应示例：`examples/05_control_flow.clj`

> Clojure 没有语句，**一切皆表达式**——`if` 有返回值，`when` 有返回值，
> 连 `try` 都有返回值。没有 for 循环？有更根本的 `loop`/`recur`
> （编译期保证的尾调用）。

## 7.1 if：表达式，不是语句

```clojure
(if test then else?)        ; 两个分支，最多
(defn fee [age] (if (< age 6) 0 30))     ; 直接当值用，没有"三元运算符"这种补丁
```

- **没有 `else if` 链**——那是 `cond` 的活。
- **`if` 只吃一个表达式/分支**：多步操作要 `do` 包起来——这正是 `when` 存在的原因。
- test 走真值语义（只有 nil/false 为假，04 章）。

```clojure
(if pos?
  (do (log pos) (inc pos))     ; then 多表达式要 do
  0)
```

## 7.2 when 家族：无 else + 隐式 do

```clojure
(when (seq xs)                 ; 隐式 do：body 可以多行
  (println "processing")
  (process xs))                ; 条件为假时整个返回 nil

(when-not (empty? xs) ...)     ; 反向版

(if-let [x (find-user id)]     ; 绑定 + 判空一步走：x 非 nil/false 走 then
  (greet x)
  :not-found)

(when-let [x (find-user id)]   ; 无 else 的绑定版（高频惯用法）
  (greet x))
```

`if-let`/`when-let` 是"查找并使用"的标配——省掉 `(let [x (find ...)] (if x ...))` 的双层。

## 7.3 cond / condp / case：三分支以上

```clojure
(cond                             ; 条件逐个测，:else 兜底
  (neg? n) "negative"
  (zero? n) "zero"
  :else "positive")

(condp = x                        ; 把 (test x value) 里的公共谓词提出来
  1 "one"
  2 "two"
  "other")                        ; 最后是 default（没 default 且不中 → 抛异常）

(condp some [1 2 3]               ; 谓词可换：some 版做"包含即匹配"
  #{4} ">>4"
  #{2} ">>2")
```

```clojure
(case color                       ; 分发在编译期定（hash 查表），最快
  (:red :crimson) "#FF0000"       ; 多值并列
  :blue "#0000FF"
  "#000000")                      ; default
```

`case` 的匹配值是**编译期常量**（字面量），不能传运行时变量——`(let [k 1] (case x k ...))` 报错。要运行时分发用 `condp =` 或 12 章多方法。

## 7.4 and / or：短路 + 返回值语义

它们不是"返回布尔"——是**返回第一个决定性操作数**：

```clojure
(and 1 2 3)          ; => 3     全真 → 返回最后一个
(and 1 nil 3)        ; => nil   遇假短路，3 不求值
(or nil false 3 4)   ; => 3     遇真短路，4 不求值
(or nil false)       ; => false 全假 → 最后一个
(and)                ; => true
(or)                 ; => nil
```

惯用法密集区：

```clojure
(or (get m :name) "anonymous")      ; 默认值
(and user (:email user))            ; 防空链：user 为 nil 短路，不碰 :email
(or (try-parse s) (try-parse s2) 0) ; 第一个成功的
```

`if-let` 的"否则给默认"变体：`(if-let [v (f)] v default)` 就是 `(or (f) default)`——后者更短，副作用场合别用。

## 7.5 loop / recur：受保障的尾递归

JVM 不做通用尾调用优化，Clojure 的答案：**`recur` 显式尾递归，编译器校验位置**——不在尾位置直接编译错。这是"函数式循环"的可靠形态：

```clojure
(defn factorial [n]
  (loop [i n, acc 1]               ; 绑定初值（loop 是 let 的循环版）
    (if (zero? i)
      acc                          ; 出口
      (recur (dec i) (* acc i))))) ; 尾位置重入：i、acc 全量更新
(factorial 20)                     ; => 2432902008176640000
```

规则与直觉：

- `recur` 必须在 `loop`/`defn` 的**尾位置**（`if` 分支、`do`/`when` 最后一行、`case` 结果都算）——错了是**编译错误**不是运行时炸栈。
- recur 按位置更新**全部**绑定变量，漏一个参数个数就对不上。
- `loop` 里不写 `(recur (dec i) (* i acc))` 之外的副作用——保持"状态全部在绑定里"的风格。
- 数值累加器注意 04 章溢出规则（`*'` / `unchecked-*`）。

**什么时候用 loop/recur**：性能敏感的紧密循环、或"递归结构本身就是迭代"的算法（21 章二分查找）。平时优先 `reduce` / `map`（09 章）——语义相同，可读性更高。

## 7.6 while / dotimes / doseq：为副作用而生

```clojure
(dotimes [i 3] (print i))                 ; 012   固定次数
(doseq [x [10 20] y [:a :b]] (pr [x y]))  ; 笛卡尔积遍历（for 的急切版）
(while (pos! (poll! c)) (process))        ; 极少用：条件循环
```

`doseq` 支持 `:when`/`:while`/`:let` 修饰（与 10 章 `for` 同语法）。**不要用它们收集结果**——返回 nil；收集用 `for`/`map`/`reduce`。

## 7.7 异常也是表达式

```clojure
(try
  (/ 1 0)
  (catch ArithmeticException e
    (ex-message e))                ; => "Divide by zero"   catch 分支有值
  (finally
    (println "always")))           ; finally 只为副作用

(throw (ex-info "用户不存在" {:user-id id}))   ; 带数据抛出（首选）
(ex-data e)                        ; => {:user-id 42}    把数据取回来
(ex-message e)                     ; => "用户不存在"
```

`ex-info` + `ex-data` 是 Clojure 的"结构化异常"——错误消息给人，data map 给程序。Clojure 不检查受检异常（不需要 `throws` 声明），Java 互操作里的受检异常直接 catch 即可（15 章）。

## 7.8 坑位清单

1. **`if` 两个分支写多个表达式**：`(if c (f) (g) (h))` 里 `(h)` 不属于 else——它是 if 之后的独立表达式，**永远执行**。多用 `when` 避开。
2. **`case` 匹配值是编译期字面量**：想用变量当分支 → `condp =`。
3. **`cond` 忘写 `:else` 兜底**：全不中返回 nil，静默错误；condp 无 default 直接抛异常。
4. **`recur` 不在尾位置是编译错**，报错行号指向 recur——把累积变量补进 loop 绑定即可。
5. **`(and truthy (f))` 返回的是 `(f)` 的值**，不是 true——别拿它当布尔断言，要布尔就 `(boolean (and ...))`。
6. **`while` 循环里忘了变更条件** → 死循环；它没有 `for x in range` 那样的边界。
7. **catch 顺序**：子异常类在前、父类在后（同 Java 语义），`Exception` 放最后兜底。

---

上一章：[06 函数与闭包](06-functions.md) · 下一章：[08 解构](08-destructuring.md)
