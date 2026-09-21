# 07 · 列表与 cons：一根筋的数据结构、五种相等

> 配套示例：[`examples/07_lists/`](../examples/07_lists/main.lisp)（channel: both）

Lisp 的「列表」不是一种特殊容器，而是**由 cons 单元串起来的链**。搞清楚这一点，
后面所有列表函数的行为（破坏性操作、结构共享、`equal` 的边界）都能推出来。

## 7.1 cons 单元是唯一的砖

一个 cons 只有两格：`car` 和 `cdr`。

```lisp
(cons 1 2)              ; => (1 . 2)        ← 点号表示「两格都不是列表」
(cons 1 nil)            ; => (1)            ← cdr 是 nil，就打印成列表
(cons 1 (cons 2 nil))   ; => (1 2)
(cons 1 (cons 2 3))     ; => (1 2 . 3)      ← 最后一个 cdr 不是 nil，就是「点尾」
(car (cons 1 2))        ; => 1
(cdr (cons 1 2))        ; => 2
```

所以 `(1 2 3)` 的真实结构是 `(1 . (2 . (3 . nil)))`。两个术语：

- **proper list**（正规列表）：最后一个 cdr 是 `nil`；
- **dotted list**（点对列表）：最后不是 `nil`，`length` 会报错。

```lisp
(length '(1 . 2))       ; 报错：The value 2 is not of type LIST
```

`(last '(1 2 3))` 返回 `(3)`——它返回的是**最后一个 cons 单元**（尾部的子表），
不是元素 3。

## 7.2 判定的反直觉之处

```lisp
(listp '(1 . 2))     ; => T      ← 点对也算「列表」！
(listp nil)          ; => T
(consp nil)          ; => NIL    ← 这是唯一能区分 nil 的
(null nil)           ; => T
(atom '(1 2))        ; => NIL    ← atom 是「不是 cons」
(atom nil)           ; => T      ← nil 是原子
```

要点：`listp` = 「是 cons **或**是 nil」；想判断「非空列表」用 `consp`。

## 7.3 取元素：两种风格，两套代价

```lisp
(nth 1 '(a b c))     ; => B
(first '(1 2 3))     ; => 1
(rest '(1 2 3))      ; => (2 3)
(elt '(1 2 3) 1)     ; => 2      ← 通用序列函数（08 章）
(nthcdr 1 '(1 2 3))  ; => (2 3)  ← 跳 n 步后的子表，与 (cdr …) 共享存储
(last '(1 2 3))      ; => (3)    ← 尾部子表
(butlast '(1 2 3))   ; => (1 2)  ← 去掉尾元素
```

列表和向量**不能混用各自的取用函数**：

```lisp
(nth 1 #(a b c))     ; 报错：…is #(A B C), not a LIST.
(aref '(a b c) 1)    ; 报错：…is (A B C), not a VECTOR.
```

因为列表是链，`nth` 要**走 n 步**（O(n)）；向量是连续内存，`aref` 是 O(1)。
循环里频繁 `nth` 是常见性能事故——数据要按下标访问就换向量。

## 7.4 append：只拷贝「除最后一个以外」的参数

```lisp
(append '(1 2) '(3 4))    ; => (1 2 3 4)
(append '(1 2) 3)         ; => (1 2 . 3)   ← 最后一个参数原样接上，不必是列表！
```

第二条是很多人第一次踩的坑：`append` 前面所有参数的顶层 cons 被复制，
**最后一个直接共享**。证据（示例 07 实测）：

```lisp
(let* ((b (list 3 4))
       (joined (append '(1 2) b)))
  (eq (nthcdr 2 joined) b))     ; => T      ← 尾巴就是 b 本身
```

危险随之而来：改 `b` 的内容，`joined` 跟着变。要独立副本用 `copy-list`。

## 7.5 破坏性操作：`n` 开头的函数

`n` 前缀（non-consing）意味着**就地修改**，而且几乎都要求**接住返回值**：

```lisp
(defvar *l3* (list 1 2 3))
(nreverse *l3*)      ; => (3 2 1)
*l3*                 ; => (1)     ← 变量还指着旧头，而它现在是尾巴！
```

`nreverse` 之后 `*l3*` 是 `(1)`——典型症状：**破坏性函数必须用返回值**。
习惯动作：破坏前先拷贝（示例 07 的 `(nreverse (copy-list l))`）。

`nconc` 是 `append` 的破坏版——把前一个参数的尾巴**真的接上**后一个对象：

```lisp
(defvar *l1* (list 1 2))
(defvar *l2* (list 3 4))
(nconc *l1* *l2*)            ; => (1 2 3 4)
(eq (cddr *l1*) *l2*)        ; => T       ← 接的就是同一个对象
```

同族对照：`reverse`/`nreverse`、`remove`/`delete`、`subst`/`nsubst`、
`append`/`nconc`。命名规律一致：**n 版本省内存，代价是「必须接返回值」**。

## 7.6 拷贝的深浅

```lisp
(defvar *orig* (list 1 (list 2 3)))
(defvar *shallow* (copy-list *orig*))
(defvar *deep* (copy-tree *orig*))
(eq *orig* *shallow*)                       ; => NIL   ← 顶层是新对象
(eq (second *orig*) (second *shallow*))     ; => T     ← 内层共享！
(eq (second *orig*) (second *deep*))        ; => NIL   ← 深拷贝不共享
```

`copy-list` 只复制「脊椎」（顶层链），`copy-tree` 递归复制。取子表（`nthcdr`/`cdr`/
`subseq` 对列表）也是共享的——`tailp`/`ldiff` 可以检测共享（示例 07 演示）。

## 7.7 当栈用：push / pop / pushnew / adjoin

```lisp
(let ((s nil)) (push 1 s) (push 2 s) (list s (pop s) s))
; => ((2 1) 2 (1))
(adjoin 1 '(1 2))                          ; => (1 2)   ← 非破坏版 pushnew
(let ((s (list 1 2))) (pushnew 3 s) s)     ; => (3 1 2)
```

`push`/`pop`/`pushnew` 作用在**位置**（place）上——变量、`(gethash k ht)`、
`(car l)` 都行（10 章 setf 家族）；`(pushnew 3 (list 1 2))` 这种「对临时值 push」
会报 `(SETF LIST) is undefined`。

## 7.8 关联表与属性表

**关联表**（alist）= 点对的列表，按 car 查找：

```lisp
(defvar *alist* '((:a . 1) (:b . 2)))
(assoc :a *alist*)                ; => (:A . 1)
(cdr (assoc :a *alist*))          ; => 1
(assoc :z *alist*)                ; => NIL
(rassoc 2 *alist*)                ; => (:B . 2)   ← 按值反查
```

**`assoc` 默认 `eql` 比较**，字符串键必须带 `:test`：

```lisp
(assoc "a" '(("a" . 1)))                    ; => NIL
(assoc "a" '(("a" . 1)) :test #'equal)      ; => ("a" . 1)
```

**属性表**（plist）= 平铺的 `(键 值 键 值 …)`，用 `getf`：

```lisp
(defvar *plist* (list :a 1 :b 2))
(getf *plist* :a)                 ; => 1
(getf *plist* :z :默认值)         ; => :默认值
(setf (getf *plist* :c) 3)        ; 新键插到最前
```

每个**符号**自带一个属性表（`get`/`setf get`）——「给符号挂元数据」的传统做法，
现代代码一般换哈希表（09 章）。注意它是**平 plist**（`(COLOR :RED)`），
不是 alist 的 `((COLOR . :RED))`——两者易混。

## 7.9 相等：五种，各管一段

这是 CL 里必须背下来的一张表（全部实测）：

| 函数 | 比什么 | `(… 1 1.0)` | `(… "a" "a")` | `(… #(1 2) #(1 2))` |
|---|---|---|---|---|
| `eq` | 同一个对象 | `T`（注） | `NIL` | `NIL` |
| `eql` | 同一对象**或**同类型同数值 | `NIL` | `NIL` | `NIL` |
| `equal` | 结构相同（cons/字符串/位向量/路径名） | `NIL` | `T` | `NIL` |
| `equalp` | 更宽松：忽略大小写、向量比内容、数字跨类型 | `T` | `T`（且 `"AB"`=`"ab"`） | `T` |
| `=` | 数值 | `T` | 类型错误 | 类型错误 |

```lisp
(eq 'a 'a)              ; => T
(eq "a" "a")            ; => NIL   ← 两个字面量是两个对象
(eq (list 1) (list 1))  ; => NIL
(eql 1 1.0)             ; => NIL
(equal (list 1 2) (list 1 2))   ; => T
(equal "ab" "ab")               ; => T
(equal #(1 2) #(1 2))           ; => NIL    ← 向量不按内容比
(equalp #(1 2) #(1 2))          ; => T
(equalp "AB" "ab")              ; => T
(= 1 1.0)                       ; => T
```

> **注**：`(eq 1.0 1.0)` 在 SBCL 上是 `T`（小浮点是立即数），但**标准不保证**
> `eq` 对数字的行为。比较数字一律 `=`，浮点用 `eql`。
> 另：`(eq "a" "a")` 两个字面量是否共享由实现决定——**这是「未规定行为」的活标本**，
> 两个实现对不同字面量各有取舍，谁的结果都不能依赖。

结构体（defstruct）实例用 `equalp` 才按内容比（09 章实测）；CLOS 实例则连
`equalp` 都不比内容（19 章）。

**实践建议**：数字 `=`、字符 `char=`、字符串内容 `string=`/`equal`、
「是不是同一个对象」才用 `eq`。

## 7.10 树视角

列表可以任意嵌套成树。`subst` 在树里做替换（`nsubst` 是破坏版）：

```lisp
(subst 'x 'b '(a b (a b) c))     ; => (A X (A X) C)
```

## 7.11 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `(append '(1 2) 3)` 得点对 | 最后一个参数原样接上 | 最后一个参数也写列表 |
| `nreverse` 后原变量变 `(1)` | 破坏性 + 变量指旧头 | 一定用返回值 |
| `delete` 后列表「没删干净」 | 同上（08 章 delete 向量更坑） | 用返回值 |
| `(length '(1 . 2))` 报错 | 点对不是正规列表 | 用 `list-length`（对点对返回 NIL） |
| `(assoc "a" alist)` 找不到 | 默认 `eql` | `:test #'equal` |
| `(equal #(1 2) #(1 2))` 是 NIL | `equal` 不比向量内容 | 用 `equalp` |
| `nth` 在大列表里很慢 | 列表是链，O(n) | 数据按下标访问就换向量 |
| `(eq "a" "a")` 两实现结果不同 | 字面量共享是实现自由 | 比内容一律 `equal` 系 |
