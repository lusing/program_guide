# 28 · 递归：让函数调用自己

> 所属部分：第 7 部分 · 跟随 eintr：内存模型与递归

> 示例：`examples/28-recursion.el`

**递归**是 eintr 的绝对核心——原书从第 11 章开始的绝大部分代码都是递归写的。理由很简单：Lisp 的基本数据结构是 cons 链，而 cons 链的定义本身就是递归的（「一条链是 `nil`，或者是一个 `cons`，它的 `cdr` 又是一条链」）。用递归处理递归定义的数据，代码几乎就是把定义抄一遍。

这一章从最小的递归函数讲到三种经典模式，全部在 Emacs 31.1 上实测。

## 28.1 递归函数的最小形状

递归函数由两部分组成：

- **基本情况**（base case）：问题小到可以直接回答，不再递归；
- **递归情况**（recursive case）：把问题**缩小一点**，交给自己去解决，然后用返回值拼出当前答案。

数一数列表里有几个元素，是最小的例子：

```elisp
;;; ---------- 1) 最小形状：数一数列表里有几个元素 ----------
;;; 基本情况：空表里没有元素，答案是 0。
;;; 递归情况：非空表的元素数 = 1 + 剩下那条链的元素数。
(defun my-count-elements (lst)
  "递归数出 LST 的元素个数。"
  (if (null lst)
      0
    (+ 1 (my-count-elements (cdr lst)))))
```

```elisp
(princ "== 1) 递归数元素 ==\n")
(princ (format "my-count-elements '(a b c d) = %S\n" (my-count-elements '(a b c d))))
(princ (format "my-count-elements nil         = %S\n" (my-count-elements nil)))
```

输出：

```
== 1) 递归数元素 ==
my-count-elements '(a b c d) = 4
my-count-elements nil         = 0
```

把这行代码和第 27 章的定义对照着读：

| cons 链的定义 | 对应的代码 |
|---|---|
| 空表是 `nil` | `(null lst)` → 返回 `0` |
| 非空表 = 一个元素 + 一条更短的链 | `(+ 1 (my-count-elements (cdr lst)))` |

**缩小问题的动作就是 `(cdr lst)`**。写递归时最容易犯的错，是忘了把参数往「基本情况」方向推一步——那样函数会永远递归下去。

## 28.2 递归的展开顺序：一路钻到底，再一路回来

光看代码感觉不出递归怎么跑。在函数里插一行打印，把「进入」和「返回」都记下来，顺序就一目了然了：

```elisp
;;; ---------- 2) 递归的展开：每一步都推迟到「回来」再算 ----------
;;; 在函数里插一行打印，就能看到「先一路钻到底，再一路回来」的顺序。
(defvar my-trace-depth 0)
(defun my-count-traced (lst)
  "和 my-count-elements 一样，但把每一步的进入/返回打印出来。"
  (princ (format "%s进入：处理 %S\n"
                 (make-string (* 2 my-trace-depth) ?\s) lst))
  (let ((my-trace-depth (1+ my-trace-depth)))
    (if (null lst)
        (progn
          (princ (format "%s基本情况：返回 0\n"
                         (make-string (* 2 my-trace-depth) ?\s)))
          0)
      (let ((rest (my-count-traced (cdr lst))))
        (princ (format "%s返回：1 + %d = %d\n"
                       (make-string (* 2 my-trace-depth) ?\s) rest (1+ rest)))
        (1+ rest)))))
```

```elisp
(princ "\n== 2) 递归的展开顺序 ==\n")
(princ (format "结果 = %S\n" (my-count-traced '(a b))))
```

输出：

```
== 2) 递归的展开顺序 ==
进入：处理 (a b)
  进入：处理 (b)
    进入：处理 nil
      基本情况：返回 0
    返回：1 + 0 = 1
  返回：1 + 1 = 2
结果 = 2
```

两条规律，看这段输出就明白了：

1. **进入是「向内」的**，缩进越来越深，直到撞上基本情况；
2. **返回是「向外」的**，缩进越来越浅，每一层才把 `1 +` 这个加法补上。

也就是说，`(+ 1 …)` 里的那个加法被**推迟**了——它必须等内层的递归返回之后才能做。这就是「推迟求值」（deferment）。`my-trace-depth` 用的是 `defvar`，所以 `let` 对它是动态绑定，递归进下一层时读到的才是加深后的值（这是第 3 章的动态作用域在这里派上用场的少数场合之一）。

## 28.3 推迟求值的经典例子：阶乘

```elisp
;;; ---------- 3) 推迟求值的经典例子：阶乘 ----------
;;; (* n (my-factorial (1- n))) 里那个乘法，要等递归回来才做。
(defun my-factorial (n)
  "阶乘：(my-factorial 4) = 4*3*2*1。"
  (if (= n 0)
      1
    (* n (my-factorial (1- n)))))
```

```elisp
(princ "\n== 3) 阶乘 ==\n")
(princ (format "4! = %S\n" (my-factorial 4)))
(princ (format "6! = %S\n" (my-factorial 6)))
```

输出：

```
4! = 24
6! = 720
```

`(my-factorial 4)` 展开成：

```
(* 4 (* 3 (* 2 (* 1 1))))
```

乘法是**从里往外**做的：先算出最深处的 `1`，再一层层乘回来。任何「先要子结果、再拼出父结果」的算法都是这个形状——目录树遍历、表达式求值、解析嵌套结构，全是它。

## 28.4 同一个问题：循环 vs 递归

三角形数 `1 + 2 + … + n` 用两种写法都能解，对照看最容易理解两者的关系：

```elisp
;;; ---------- 4) 同一个问题，循环版与递归版 ----------
;;; 三角形数 1+2+...+n，两种写法对照着看。
(defun my-triangle-loop (n)
  "循环版三角形数。"
  (let ((total 0))
    (while (> n 0)
      (setq total (+ total n))
      (setq n (1- n)))
    total))

(defun my-triangle-recursive (n)
  "递归版三角形数。"
  (if (= n 0)
      0
    (+ n (my-triangle-recursive (1- n)))))
```

```elisp
(princ "\n== 4) 循环 vs 递归 ==\n")
(princ (format "循环版 1..10  = %S\n" (my-triangle-loop 10)))
(princ (format "递归版 1..10  = %S\n" (my-triangle-recursive 10)))
```

输出：

```
循环版 1..10  = 55
递归版 1..10  = 55
```

两者可以互相翻译：

| 循环的零件 | 递归的对应物 |
|---|---|
| `total` 累积变量 | 递归的返回值（每层返回一部分和） |
| `(setq n (1- n))` 推进 | `(my-triangle-recursive (1- n))` 缩小参数 |
| `(while (> n 0) …)` 循环条件 | `(if (= n 0) 0 …)` 基本情况 |

**能用循环写的地方，都能用递归写，反之亦然。**选择标准是「数据长什么样」：数据是线性列表，循环更省内存；数据是树（嵌套列表、表达式、目录），递归写出来会短得多、也清楚得多。

## 28.5 三种经典递归模式

eintr 的《Recursion》附录把最常见的递归用法归纳成四种模式。这里用现代写法重写前三种，它们分别对应 `seq-every-p`、`mapcar` 和 `seq-filter` 的底层动作。

### 模式一：every（全部满足）

```elisp
;;; ---------- 5) 模式一：every —— 全部满足才返回 t ----------
(defun my-evenp (n)
  "N 是偶数时返回 t。"
  (= 0 (mod n 2)))

(defun my-every (pred lst)
  "当 LST 中每个元素都满足 PRED 时返回 t。"
  (if (null lst)
      t
    (and (funcall pred (car lst))
         (my-every pred (cdr lst)))))
```

```elisp
(princ "\n== 5) every 模式 ==\n")
(princ (format "全是偶数？%S\n" (my-every #'my-evenp '(2 4 6 8))))
(princ (format "全是偶数？%S\n" (my-every #'my-evenp '(2 4 5 8))))
```

输出：

```
全是偶数？t
全是偶数？nil
```

关键在于**基本情况返回 `t`**：「空表里每个元素都满足条件」这句话在逻辑上为真（空真命题）。再配合 `and` 的短路：只要有一个元素不满足，立刻返回 `nil`，后面的递归根本不会发生。

### 模式二：accumulate（加工后收集）

```elisp
;;; ---------- 6) 模式二：accumulate —— 把每个元素加工后收集起来 ----------
(defun my-accumulate (fn lst)
  "对 LST 中每个元素调用 FN，把结果 cons 成一串返回。"
  (if (null lst)
      nil
    (cons (funcall fn (car lst))
          (my-accumulate fn (cdr lst)))))
```

```elisp
(princ "\n== 6) accumulate 模式 ==\n")
(princ (format "每个数平方：%S\n" (my-accumulate (lambda (x) (* x x)) '(1 2 3 4))))
```

输出：

```
每个数平方：(1 4 9 16)
```

**基本情况返回 `nil`**（空表），递归情况**把加工结果 `cons` 到已处理部分的头上**。因为 `cons` 都发生在「向外返回」的路上，输出的顺序和输入一致。这正是 `mapcar` 的定义方式。

### 模式三：keep（过滤）

```elisp
;;; ---------- 7) 模式三：keep —— 过滤 ----------
(defun my-keep (pred lst)
  "只保留 LST 中满足 PRED 的元素，保持原顺序。"
  (if (null lst)
      nil
    (let ((rest (my-keep pred (cdr lst))))
      (if (funcall pred (car lst))
          (cons (car lst) rest)
        rest))))
```

```elisp
(princ "\n== 7) keep 模式 ==\n")
(princ (format "只留正数：%S\n" (my-keep (lambda (x) (> x 0)) '(-3 1 -7 2 9))))
```

输出：

```
只留正数：(1 2 9)
```

先把「剩下那条链过滤后的结果」求出来存进 `rest`，再决定要不要把当前元素拼在最前面。这就是 `seq-filter` / `remove-if-not` 的递归原型。

### 第四种：no-deferment（不推迟）

还有一种是**累积器**写法：把中间结果当作参数传下去，不做推迟计算。它的好处是「返回时不需要再做事」——理论上最省栈。后面 28.7 会看到，Emacs Lisp 并没有因此获得好处，但作为模式仍然值得认识。

## 28.6 递归真正不可替代的地方：树

列表里可以套列表。这种嵌套结构（树）用循环写会非常别扭，而递归写出来几乎是直译：

```elisp
;;; ---------- 8) 树的递归：递归真正不可替代的地方 ----------
;;; 列表里还可以套列表。用循环写会很别扭，用递归是天然的。
(defun my-sum-tree (tree)
  "求一棵嵌套列表里所有数字之和。"
  (cond
   ((null tree) 0)
   ((numberp tree) tree)
   ((consp (car tree))
    (+ (my-sum-tree (car tree)) (my-sum-tree (cdr tree))))
   ((numberp (car tree))
    (+ (car tree) (my-sum-tree (cdr tree))))
   (t (my-sum-tree (cdr tree)))))
```

```elisp
(princ "\n== 8) 递归处理一棵树 ==\n")
(princ (format "my-sum-tree '(1 (2 (3 4)) 5) = %S\n"
               (my-sum-tree '(1 (2 (3 4)) 5))))
(princ (format "同一棵树换个写法 '(1 2 (3 (4 5)) 6) = %S\n"
               (my-sum-tree '(1 2 (3 (4 5)) 6))))
```

输出：

```
my-sum-tree '(1 (2 (3 4)) 5) = 15
同一棵树换个写法 '(1 2 (3 (4 5)) 6) = 21
```

`cond` 的分支就是树的可能形态：

1. `nil` —— 空，贡献 0；
2. 本身是数字 —— 就是一片叶子，返回它自己；
3. 头是子列表 —— 分别递归头和尾，相加；
4. 头是数字 —— 加上头，再递归尾巴；
5. 其它（字符串、符号……）—— 跳过，只递归尾巴。

**每一条 `cond` 分支对应一种节点形态**，这是写递归处理结构时的通用套路。Emacs 内部到处是这样的代码：`elisp--eval` 里对各类表达式做分派、`find-function-search-for-symbol` 里对源码做分派，都是这个形状。

## 28.7 边界：Emacs Lisp 没有尾递归优化

必须说清楚的一条：**Emacs Lisp 不把尾递归优化成循环**。递归深度由 `max-lisp-eval-depth` 限制，超了就报错：

```elisp
;;; ---------- 9) 边界：Emacs Lisp 没有尾递归优化 ----------
;;; 递归深度受 max-lisp-eval-depth 限制，太深就会报错。
;;; 报错能被 condition-case 接住，所以不会让脚本崩掉。
(princ "\n== 9) 深递归的边界 ==\n")
(princ (format "max-lisp-eval-depth = %S\n" max-lisp-eval-depth))
(let ((result
       (condition-case err
           (my-count-elements (make-list 100000 'x))
         (error (format "递归太深，被拦住：%S" (car err))))))
  (princ (format "十万元素的递归结果：%S\n" result)))
```

输出：

```
max-lisp-eval-depth = 1600
十万元素的递归结果："递归太深，被拦住：excessive-lisp-nesting"
```

十万元素的列表并不大，但递归需要一万层栈帧，远超上限 1600，于是被 `condition-case` 拦了下来。这带来两条实践规则：

- **处理「可能很长」的线性数据（缓冲区文本、大文件行列表）时，用循环**（`while` / `dolist` / `seq-*`），不要用递归；
- **处理层次有限的结构（嵌套列表、表达式、抽象语法树）时，放心用递归**，配合 `condition-case` 兜住意外。

需要更深时可以临时抬高这个上限：

```elisp
(let ((max-lisp-eval-depth 100000))
  (my-count-elements (make-list 50000 'x)))
```

但真正的深递归即使抬了上限也很慢（每层都要分配栈帧），工程上不如直接换成循环或显式的栈。

## 28.8 小结

| 要素 | 写法 |
|---|---|
| 基本情况 | 最小的问题，直接给答案（`nil` 链 / 数字 0 / 空真） |
| 递归情况 | 参数往基本情况推一步（`cdr`、`1-`） |
| 推迟求值 | 内层结果返回后，外层再拼装 |
| every / accumulate / keep | `seq-every-p` / `mapcar` / `seq-filter` 的递归原型 |
| 树 | 用 `cond` 为每种节点形态写一个分支 |
| 深度上限 | `max-lisp-eval-depth`（默认 1600）；长线性数据改用循环 |

下一章换一种学习方法：不再自己写函数，而是**拿着 Emacs 自带的真实源码逐行读**——这是 eintr 后半部分最重要的技能。

---

上一章：[27 · cons 单元与列表的内存模型](27-cons-cells.md)　｜　下一章：[29 · 读懂真实函数：三个 buffer 命令的走查](29-read-source.md)　｜　返回：[Emacs 扩展开发指南](README.md)
