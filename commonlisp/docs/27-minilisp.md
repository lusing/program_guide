# 27 · 实战：用 Common Lisp 写一个迷你 Lisp 解释器

> 配套示例：[`examples/27_minilisp/`](../examples/27_minilisp/main.lisp)（channel: both）
>
> 毕业礼项目：约 200 行的解释器 + 40 条断言测试，双实现逐字节一致。

## 27.1 目标与设计

实现一个 Lisp 子集的解释器——它自己**不用 `eval`**，而是亲手实现 eval 的语义
（03 章说的「REPL 的 E」）。支持：

- **特殊形式**：`quote` `if` `lambda` `define`（两种写法）`set!` `let` `let*`
  `progn` `cond`；
- **内建函数**：算术/比较/表操作，直接桥到宿主 CL；
- **语义**：词法作用域、闭包、递归（define 全局绑定）。

解析层「作弊」——直接用宿主的 `read` 把源码读成 S 表达式：
「代码即数据」的直接体现（写 tokenizer/parser 是另一门好练习，
clojure/haskell 章的 MiniLang 有手工词法/语法的版本可对照）。

## 27.2 环境：变量住在关联表里

```lisp
;; 环境 = ((名字 . 值) ...) 的表；子环境 cons 一层到父环境上
;; 查名字 = 沿父链向上找——「词法作用域」的全部机制
(defun env-lookup (name env)
  (loop for frame in env
        for cell = (assoc name frame :test #'eq)
        when cell
          return (cdr cell)
        finally (error "未绑定的符号: ~A" name)))
```

两个写进注释的细节：

- **不能用 `thereis (cdr cell)`**——「找到但值是 NIL」会被误判成没找到，
  `when cell` 判定的是格子本身；
- `set!` 沿父链找到哪层改哪层（找不到报错）；`define` 永远写进全局帧。

## 27.3 求值器

```lisp
(defun me-eval (expr env)
  (cond
    ((or (numberp expr) (stringp expr) (keywordp expr)) expr)   ; 自求值
    ((symbolp expr) (env-lookup expr env))
    ((consp expr)
     (case (first expr)
       (quote  (second expr))
       (if     (if (me-eval (second expr) env)
                   (me-eval (third expr) env)
                   (me-eval (fourth expr) env)))
       (lambda (list :closure (second expr) (cddr expr) env))    ; 闭包三元组
       ...))前后略))
```

**闭包 = (参数 身体 定义时环境) 三元组**——`(lambda (x) ...)` 求值的结果
只是把当前环境存起来；调用时在「定义时环境」上扩展一层（不是调用时环境）——
词法作用域闭包的全部秘密就这一句。

**let 是语法糖**：`(let ((x 2)) body)` 展开成 `((lambda (x) body) 2)` 再求值。
实现的坑（真实踩过）：拼这个调用形式要 `list*`（splice），用 `list` 会把
body 整个多包一层——`(let ((x 2)) x)` 的 body 变成 `((X))`，`X` 被当成
函数调用，报「调不了: 2」。`let*` 展开成嵌套的 `let`（顺序绑定=嵌套作用域）。

## 27.4 apply 与内建

```lisp
(defun me-apply (fn args env)
  (cond
    ((and (consp fn) (eq (first fn) :closure))
     (me-eval-sequence (third fn)                 ; 身体
                       (env-extend (second fn) args (fourth fn))))  ; 定义时环境!
    ((functionp fn) (apply fn args))               ; 内建：桥到宿主
    (t (error "调不了: ~S" fn))))
```

内建函数就是宿主函数：`` `((+ . ,#'+) (cons . ,#'cons) ...) `` 一张关联表
装进全局帧。`define` 支持两种写法：`(define x 值)` 与 `(define (f 参数) 身体)`
（后者展开成 lambda）。

## 27.5 递归与 define

`(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))` 能工作，是因为
`fact` 的闭包体里 `fact` 这个名字在**全局帧**里查——define 先把闭包放进
全局帧，调用时名字已经在了。「环境是可变的表」让递归免费获得。

## 27.6 测试：40 条断言 × 双实现

测试分六组：算术与求值、quote 与表、define/set!/作用域（let 并行 vs let* 顺序）、
闭包与高阶（计数器/加法器/互不干扰）、递归（阶乘/斐波那契）、cond/progn，
外加四条**预期报错**路径（未绑定符号/未定义函数/set! 未定义/参数不匹配）。

报错路径的比对有个细节：错误对象本身含实现措辞——`check-error` 只断言
「是否报错」（`:error` 哨兵），不断言文本（18 章规矩的解释器版）。

整套测试跑在 SBCL 和 CLISP 上，输出逐字节一致——这是 22 章军规的
一次全面应用：解释器里没打印 gensym、没依赖哈希顺序、数值都是精确整数。

## 27.7 扩展方向

- 手写 tokenizer + parser 替换 `read`（体会读取器干了多少活）；
- 加 `and`/`or` 宏形式、字符串内建、`letrec`；
- 加 TCO：`me-eval` 的尾位置改成循环（trampoline）——顺便实测 CLISP 的
  栈深度限制（11 章的 5000 层）；
- 把 `:closure` 换成 defclass——得到一个 CLOS 版解释器（19 章的综合练习）。

## 27.8 坑位清单（写解释器时真实踩过的）

| 症状 | 原因 | 解法 |
|---|---|---|
| `(let ((x 2)) x)` 报「调不了: 2」 | let 展开用 list 把 body 多包一层 | `list*` splice |
| 变量值为 NIL 时报未绑定 | `thereis (cdr cell)` 穿透 | `when cell` 判定格子 |
| 递归函数「未定义」 | define 先于闭包存入的顺序 | 全局帧可变，define 先存 |
| CLISP 告警 FOR 子句顺序 | `until` 混在两个 for 之间 | FOR 放最前，别用 for-v-finally |
| 报错文本两实现不同 | 条件对象带实现措辞 | 只断言「是否报错」 |
