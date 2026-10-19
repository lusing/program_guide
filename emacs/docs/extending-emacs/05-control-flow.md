# 05 · 控制流

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/05-control-flow.el`

Elisp 的控制流形式不多，但每一个都有别处不常见的细节。本章按「分支 → 布尔 → 循环 → 模式匹配」的顺序过一遍，所有输出都是示例真跑出来的。

## 5.1 if / when / unless：三种分支

`if` 是最基本的分支，**每个分支只能有一个表达式**：

```elisp
(defun demo-sign (n)
  "返回 N 的符号描述。"
  (if (> n 0) "正" (if (< n 0) "负" "零")))
(princ (format "sign: %S / %S / %S\n" (demo-sign 5) (demo-sign -5) (demo-sign 0)))
```

```
sign: "正" / "负" / "零"
```

三个数走三条路，嵌套的 `if` 就能表达多分支。但如果分支里要塞多个表达式，就必须自己包 `progn`（见 5.3），很难看。Elisp 为此准备了两个「带 progn 的 if」：

- 只有 then 分支用 `when`；
- 只有 else 分支用 `unless`。

```elisp
(let (log)
  (when (stringp "x") (setq log (cons "when 命中" log)))
  (unless (integerp "x") (setq log (cons "unless 命中" log)))
  (princ (format "when/unless: %S\n" (nreverse log))))
```

```
when/unless: ("when 命中" "unless 命中")
```

`when`/`unless` 的 body 可以有任意多条表达式，返回最后一条的值。**日常写 Elisp，90% 的「如果…就做一堆事」都应该用 `when`**，直接消灭了「缩进骗人」这个最大的新手错误源。

## 5.2 cond：多分支

`cond` 的每个子句是 `(条件 body...)`，自上而下找第一个条件为真的，执行它的 body 并返回；**末尾的 `(t ...)` 就是 else**：

```elisp
(defun demo-grade (score)
  "把 SCORE 转成等级。"
  (cond
   ((>= score 90) "A")
   ((>= score 60) "B")
   (t "C")))
(princ (format "grade: %S / %S / %S\n" (demo-grade 95) (demo-grade 70) (demo-grade 30)))
```

```
grade: "A" / "B" / "C"
```

`cond` 的子句没有「条件只能一个表达式」的限制——条件部分本身就是一个完整的布尔表达式，body 部分任意多条。它是 Elisp 里表达「按顺序试一系列条件」的标准形式。

## 5.3 【坑】if 的 then 只能有一句

这是新手最常踩的坑，而且**编译器不报错**，只会静静地做错事：

```elisp
(princ (format "progn: %S\n"
               (if t (progn (princ "  (then 分支执行了)\n") "progn 的返回值") "不会到这")))
```

```
  (then 分支执行了)
progn: "progn 的返回值"
```

`progn` 按顺序求值所有表达式，返回**最后一个**的值。上面这行是对的写法。而下面这段是错的：

```elisp
(if t
    (princ "a")
    (princ "b"))
(princ "c")        ;; ← 这行不在 if 里！它总会执行
```

缩进会让眼睛以为 `(princ "c")` 在分支里，但 Lisp 的括号不看缩进——`if` 的第三个参数是 `(princ "b")`，第四个参数不存在，`(princ "c")` 是 `if` 形式结束后的下一条语句。用 `when`/`unless` 或显式 `progn` 就不会犯这个错。

## 5.4 and / or：短路，且返回操作数本身

Elisp 的 `and`/`or` 和 C 系语言有一个大区别：**它们不求布尔值，而是直接返回决定结果的那个操作数**。

```elisp
(princ (format "(or nil 0 \"\" 'fallback) = %S\n" (or nil 0 "" 'fallback)))
(princ (format "(and 1 2 nil 3) = %S\n" (and 1 2 nil 3)))
```

```
(or nil 0 "" 'fallback) = 0
(and 1 2 nil 3) = nil
```

规则：

- `or` 一路求值，返回**第一个真值**；全假则返回最后一个操作数的值；
- `and` 一路求值，返回**第一个假值**；全真则返回最后一个操作数的值。

注意第一行：`(or nil 0 "" 'fallback)` 返回 `0` 而不是 `'fallback`——因为 **0 在 Elisp 里是真**（见 2.2 节，只有 `nil` 是假）。这个特性最常见的用途是给默认值：

示例里把这件事写实了——`demo-greeting` 用 `or` 给默认称呼：

```elisp
;; or 给默认值是它最常见的用途。但这里有个陷阱：Elisp 里只有 nil 是假，
;; 所以 0 和 "" 都是真，它们会「冒充」已设置的值，把默认值顶掉。
(defun demo-greeting (name)
  "用 NAME 打招呼；NAME 为 nil 时退回默认称呼。"
  (format "你好，%s！" (or name "世界")))
(princ (format "or 默认值: %S / %S\n" (demo-greeting "小明") (demo-greeting nil)))
(princ (format "   传空字符串: %S（空串是真，所以它没被默认值替换）\n" (demo-greeting "")))
```

```text
or 默认值: "你好，小明！" / "你好，世界！"
   传空字符串: "你好，！"（空串是真，所以它没被默认值替换）
```

最后一行就是那个陷阱：`(demo-greeting "")` 拿回的是 `"你好，！"` 而不是 `"你好，世界！"`——空串不是 `nil`，`or` 就认定「调用方给了值」。所以**用 `or` 给默认值之前，先确认合法取值里不会有 `0`、`""` 这类「看起来像没设置」的真值**；真拿不准就直接写 `(if (null x) default x)`。

## 5.5 while：唯一的通用循环

Elisp 没有 `for`。要手动控制步长、要 `while` 条件，就自己 `setq` 计数器：

```elisp
(let ((i 0) (acc 0))
  (while (< i 5)
    (setq acc (+ acc i)
          i (1+ i)))
  (princ (format "while: 0+1+2+3+4 = %S\n" acc)))
```

```
while: 0+1+2+3+4 = 10
```

顺便记两个写法：`setq` 可以一次赋多个值（上面 `i` 和 `acc` 一起赋）；`1+` 是「加一」的函数，`1-` 是减一，比 `(+ i 1)` 短，是 Elisp 的惯用写法。

## 5.6 dotimes 与 dolist：最常见的两种遍历

计数循环和列表遍历有专用形式，而且都有一个**结果表达式**（第三个位置），循环正常结束后求值、作为整个形式的返回值：

```elisp
(princ (format "dotimes 累加: %S\n"
               (let ((acc 0))
                 (dotimes (i 5)
                   (setq acc (+ acc i)))
                 acc)))
(princ (format "dotimes 结果式: %S\n"
               (dotimes (i 3 (format "循环结束时 i = %d" i))
                 (princ (format "  遍历 i=%d\n" i)))))
(let ((total 0))
  (dolist (x '(10 20 30))
    (setq total (+ total x)))
  (princ (format "dolist 累加: %S\n" total)))
```

```
dotimes 累加: 10
  遍历 i=0
  遍历 i=1
  遍历 i=2
dotimes 结果式: "循环结束时 i = 3"
dolist 累加: 60
```

`dotimes` 的 `i` 从 0 数到 N-1（不含 N）；`dolist` 遍历列表的每个元素。

### 【坑】结果表达式必须用到循环变量，否则编译警告

`dotimes` 的结果表达式外面被宏包了一层 `(let ((i counter)) ...)`。如果结果表达式里**没用到** `i`，字节编译器会报 `Unused lexical variable i`。规避办法：要么不写结果表达式（像上面第一种写法那样，在循环外面接住 `acc`），要么让结果式引用 `i`（第二种写法正是这么做的）。

### 【坑】循环变量是不是闭包捕获的「那一个」

`dolist`/`dotimes` 的循环变量是词法绑定还是动态绑定？**取决于它是否被 `defvar` 过**——和第 3 章是同一条规则。在开了 `lexical-binding: t` 的文件里它是词法绑定，每次迭代都是新绑定，闭包各自捕获各自的值：

```elisp
(princ (format "dolist + 闭包: %S\n"
               (let ((fns nil))
                 (dolist (x '(1 2 3))
                   (push (lambda () x) fns))
                 (mapcar #'funcall (nreverse fns)))))
```

```
dolist + 闭包: (1 2 3)
```

如果 `x` 恰好是个 special 变量，同样的代码三个闭包会共享**同一个** `x`，输出 `(3 3 3)`。写「给一堆元素各自挂一个回调」时这是经典陷阱——所以**永远不要 `defvar` 一个准备用作循环变量的名字**。

## 5.7 cl-case：值的集合分派

判据是「这个值等于哪几种情况之一」时，`cl-case`（cl-lib 提供）比 `cond` 紧凑得多：

```elisp
(require 'cl-lib)
(defun demo-size (kind)
  "按 KIND 返回尺码描述。"
  (cl-case kind
    ((1 2 3) "小数字")
    ((10 20) "整十")
    (t "其它")))
(princ (format "cl-case: %S / %S / %S\n"
               (demo-size 2) (demo-size 10) (demo-size 99)))
```

```
cl-case: "小数字" / "整十" / "其它"
```

每个子句的模式是「一个值或一列值」，`t` 是兜底。注意它用 `eql` 比较，**字符串不能用它分派**（`eql` 对字符串比的是身份，两个内容相同的字符串对象 `eql` 为假——见第 6 章）。字符串分派用下面的 `pcase`。

## 5.8 pcase：模式匹配

`pcase` 是 Elisp 里最强的分支形式：模式可以匹配类型、结构，还能把匹配到的部分**绑定**成变量。

```elisp
(defun demo-describe (v)
  "按 V 的形状返回描述。"
  (pcase v
    ((pred integerp) "整数")
    ((pred stringp) (concat "字符串: " v))
    (`(,a ,b) (format "两元素列表: %S 和 %S" a b))
    (_ "其它")))
(princ (format "pcase: %S / %S / %S / %S\n"
               (demo-describe 42) (demo-describe "hi")
               (demo-describe '(1 2)) (demo-describe 3.0)))
```

```
pcase: "整数" / "字符串: hi" / "两元素列表: 1 和 2" / "其它"
```

逐个子句看：

| 模式 | 含义 |
|---|---|
| `(pred integerp)` | `integerp` 返回非 nil 就匹配 |
| `(pred stringp)` | 同上；body 里的 `v` 仍是原值 |
| `` `(,a ,b) `` | **反引号解构**：值是两元素列表时匹配，并绑定 `a`=第一个、`b`=第二个 |
| `_` | 兜底，匹配一切，不绑定 |

反引号模式（第 3 部分会专门讲 `` ` `` 的机制）是 `pcase` 的杀手级特性：一条模式同时完成「检查形状」和「取出部件」。再配 `pcase-let`，解构赋值一气呵成：

```elisp
(princ (format "pcase-let: %S\n"
               (pcase-let ((`(,x ,y) (list 3 4)))
                 (+ x y))))
```

```
pcase-let: 7
```

### 【坑】Emacs 31：裸符号打头的 pcase，后面的子句全是死代码

如果第一个子句的模式是**裸符号**（比如 `(pcase v (x ...) (_ ...))`），它匹配一切，后面的子句永远走不到。Emacs 31 的字节编译器会抓住这件事，但措出奇地难懂：

示例里把裸符号打头的写法跑了一遍。这里有个演示上的取舍：**多子句的坏版本会触发 `pcase` 的 shadowed 警告，而那条警告在 Emacs 31 里由 C 层的 `macroexp-warn-and-return` 发出**——`with-no-warnings` 压不住（它只在字节编译时有效，解释执行时照样报），`byte-compile-log-warning-function` 也拦不住（那条绑定能收到警告，但警告同时还是会被打到 stderr）。所以示例只保留**单子句**的坏版本来演示运行时的后果，多子句版本的警告原文单独实测后写在本节末尾。

```elisp
;;; 12.5)【坑】裸符号打头的 pcase：它匹配一切，后面的子句全是死代码。
;;;       这里只写「一条裸符号子句」来演示运行时的后果。多写几条会触发
;;;       pcase 的 shadowed 警告，而那条警告由 C 层的 macroexp-warn-and-return
;;;       发出——with-no-warnings 压不住、byte-compile-log-warning-function
;;;       也拦不住，所以本文件不写多子句的坏版本（警告原文见 05-control-flow.md）。
(defun demo-bad-describe (v)
  "故意写坏的 pcase：裸符号 s 匹配一切，传什么进来都走这一支。"
  (pcase v
    (s (concat "字符串: " s))))                  ; 裸符号 s 匹配一切
(princ (format "坏版本(字符串): %S\n" (demo-bad-describe "hello")))
;;;    更糟的是传个数字进去：命中的仍是「字符串」那一支，于是 concat 当场炸掉。
(princ (format "坏版本(数字): %S\n"
               (condition-case err (demo-bad-describe 21)
                 (error (list '报错 (car err) (cadr err))))))
```

```
坏版本(字符串): "字符串: hello"
坏版本(数字): (报错 wrong-type-argument sequencep)
```

第二行是这个坑真正致命的地方：传 `21` 进去，命中的**还是**「字符串」那一支，`(concat "字符串: " 21)` 直接抛 `wrong-type-argument`。也就是说，裸符号子句不只是「白写了」，它会让本该走别的分支的输入走进错误的分支里。

如果坏版本写成多子句（这是真实代码里最常见的样子）：

```text
(defun demo-bad-describe (v)
  (pcase v
    (s (concat "字符串: " s))    ; 裸符号 s 匹配一切
    (n (* n 2))                  ; 死代码，永远走不到
    (_ "其它")))                 ; 死代码，永远走不到
```

字节编译器会连报两条。**注意顺序是反的**——先报最后那条 `_`，再报 `n`：

```text
In demo-bad-describe:
badpcase.el:6:6: Warning: pcase pattern _ shadowed by previous pcase pattern
badpcase.el:5:6: Warning: pcase pattern n shadowed by previous pcase pattern
```

「shadowed」想说的是「被前面的模式遮蔽了」。看到这条警告，正确反应不是换写法，而是**重新排子句顺序、把兜底放到最后**——并且用带谓词的模式代替裸符号，让每个子句都只匹配它该管的那类值：

```elisp
(princ (format "修好之后: %S / %S / %S\n"
               (pcase "hello"
                 ((and (pred stringp) s) (concat "字符串: " s))
                 ((and (pred numberp) n) (* n 2))
                 (_ "其它"))
               (pcase 21
                 ((and (pred stringp) s) (concat "字符串: " s))
                 ((and (pred numberp) n) (* n 2))
                 (_ "其它"))
               (pcase 'sym
                 ((and (pred stringp) s) (concat "字符串: " s))
                 ((and (pred numberp) n) (* n 2))
                 (_ "其它"))))
```

```
修好之后: "字符串: hello" / 42 / "其它"
```

`(and (pred stringp) s)` 是「是字符串**并且**把它绑到 `s`」的组合模式，三个子句各管一类值，`_` 兜底放最后，零警告。

另外，`t` 作为 `pcase` 兜底模式在 Emacs 31 已**废弃**（编译时提示 `Pattern t is deprecated. Use '_' instead`），新代码一律用 `_`。

## 5.9 cond*：Emacs 31 新增的扩展 cond

`cond*`（内置在 Emacs 31，`cl-lib` 之外独立提供）在 `cond` 基础上加了两种带绑定的子句，规则都很特别，逐条列明：

```elisp
(require 'subr-x)
(princ (format "cond* 大: %S\n"
               (cond*
                 ((bind* (x 5) (y (* x 2))) (princ (format "  [bind* 子句] x=%d y=%d\n" x y)))
                 ((> y 5) "y 大于 5，退出")
                 (t "兜底"))))
(princ (format "cond* 小: %S\n"
               (cond*
                 ((bind* (x nil) (y 1)) (princ (format "  [bind* 子句] x=%S\n" x)))
                 ((> y 5) "y 大于 5，退出")
                 (t "兜底"))))
```

```
  [bind* 子句] x=5 y=10
cond* 大: "y 大于 5，退出"
cond* 小: "兜底"
```

三条规则，全是实测出来的：

1. **首元素是普通表达式的子句 = 退出子句**：条件为真就带着 body 最后一个表达式的值退出整个 `cond*`，和传统 `cond` 一样。
2. **首元素是 `(bind* VAR VAL ...)` 的子句 = 非退出子句**：绑定对**后续所有子句**可见（像 `let*`）；条件在**第一个绑定的值非 nil** 时为真，为真才执行 body；执行完（或条件为假跳过 body 后）**继续往下走**，不退出。上面第一种情况：`x=5` 非 nil，body 打印 `x=5 y=10`，然后 `(> y 5)` 为真，退出，值 `"y 大于 5，退出"`。
3. **首元素是 `t` 的子句同样是非退出的**——所以 `cond*` 里**没有**传统 `cond` 的 `(t ...)` else 语义，`(t "兜底")` 只是「无条件跑一下这段，然后继续」。它能当兜底用，仅仅因为它是最后一个子句：最后一个子句的值就是整个 `cond*` 的值。

第二种情况：`x=nil`，`bind*` 子句的 body 被跳过（注意绑定本身仍然发生，`y=1` 对后面可见），`(> y 5)` 为假，落到最后的 `(t "兜底")`，值 `"兜底"`。

`cond*` 还有 `match*`/`pcase*` 条件形式（用 `cond*` 自带的模式语法，不是 `pcase` 的语法）。**Emacs 31.1 有一个坑**：在交互式加载（非字节编译）时使用 `match*`/`pcase*` 条件会直接报 `Eager macro-expansion failure: (void-function byte-compile-warn-x)`——这是上游 bug，字节编译后运行才正常。所以目前建议只用 `bind*` 形式。

## 5.10 本章小结

| 形式 | 什么时候用 |
|---|---|
| `if` | 两个分支、各一句 |
| `when` / `unless` | 只有一个分支，或分支里有多句（优先用它俩） |
| `cond` | 按顺序试多个条件 |
| `and` / `or` | 短路求值 + 返回操作数本身（默认值 idiom） |
| `while` | 条件循环 |
| `dotimes` / `dolist` | 计数 / 列表遍历 |
| `cl-case` | 按 `eql` 匹配值的集合 |
| `pcase` / `pcase-let` | 按形状匹配 + 解构绑定 |
| `cond*` | 需要把绑定传给后续子句时（Emacs 31） |

---

上一章：[04 · 函数](04-functions.md)　｜　下一章：[06 · 相等性：eq / eql / = / equal](06-equality.md)　｜　返回：[Emacs 扩展开发指南](README.md)
