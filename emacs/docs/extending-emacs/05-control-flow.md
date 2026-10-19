# 05 · 控制流

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/05-control-flow.el`

## 5.1 if / when / unless

```elisp
(if (> n 0) "正" "负")
```

```
sign: "正" / "负" / "零"
```

`if` 只接受两个分支。**只有 then 分支时用 `when`，只有 else 分支时用 `unless`** ——
它们本身就隐含了「多表达式块」，不用自己包 `progn`：

```elisp
(when (> n 0)          ; 等价于 (if (> n 0) (progn ...) nil)
  (princ "正数\n")
  (princ "继续处理\n"))
```

## 5.2 cond

```elisp
(cond ((>= score 90) "A")
      ((>= score 60) "B")
      (t "C"))
```

```
grade: "A" / "B" / "C"
```

每个子句是 `(条件 body...)`，命中第一个为真的就执行它的 body 并返回。**最后的 `t` 子句相当于 else**。

## 5.3 if 的 then 只能有一句

```elisp
(princ (format "  %S\n"
               (if t
                   (progn (princ "  (then 分支执行了)\n") "progn 的返回值")
                 "no")))
```

```
  (then 分支执行了)
progn: "progn 的返回值"
```

`progn` 按顺序求值所有表达式并返回**最后一个**的值。如果你写了

```elisp
(if t
    (princ "a")
    (princ "b"))
(princ "c")        ;; ← 这行不在 if 里！它总会执行
```

缩进会误导你以为 `(princ "c")` 在分支里，其实不是。这是新手最常犯的错，`when` / `unless` 就是为了消掉它。

## 5.4 and / or 的短路

```elisp
(or nil 0 "" 'fallback) = 0
(and 1 2 nil 3) = nil
```

它们是「返回操作数」而不是「返回 t/nil」：

- `or` 返回**第一个真值**，全假则返回最后一个值；
- `and` 返回**第一个假值**（或者最后一个值，如果全真）。

所以 `(or nil 0 "" 'fallback)` 是 `0` 而不是 `'fallback` —— 因为 0 是真（见 2.2）。
这个特性常被拿来给默认值：`(or user-value default-value)`，但必须确认 `user-value` 的合法取值里
没有 `0` 和 `""`。

## 5.5 while

```elisp
(let ((i 0) (acc 0))
  (while (< i 5)
    (setq acc (+ acc i))
    (setq i (1+ i)))
  acc)
```

```
while: 0+1+2+3+4 = 10
```

Elisp 没有 `for`，计数循环要么自己 `setq` 计数器，要么用下面的 `dotimes`。

## 5.6 dotimes 与 dolist

```elisp
(dotimes (i 5) (princ i))          ; i = 0,1,2,3,4
(dolist (x '(1 2 3)) (princ x))    ; 遍历列表
```

```
dotimes 累加: 10
  遍历 i=0
  遍历 i=1
  遍历 i=2
dotimes 结果式: "循环结束时 i = 3"
dolist 累加: 60
```

两者都有「结果表达式」：`dotimes` 的第三个位置、`dolist` 的第三个位置，在循环结束后求值并作为返回值。

### 【坑】循环变量的绑定方式

这是写循环时最容易出错的地方。`dolist` / `dotimes` 的循环变量到底是词法绑定还是动态绑定？
**取决于它是否被 `defvar` 过** —— 和 3.4 节的规则是同一条：

```elisp
;; i 没被 defvar → 词法绑定 → 每次迭代是「新的绑定」
;; 所以下面的闭包各自捕获到自己的 i
(let (fns)
  (dolist (i '(1 2 3))
    (push (lambda () i) fns))
  (mapcar #'funcall (nreverse fns)))
```

```
dolist + 闭包: (1 2 3)
```

若 `i` 是 special 变量，同样的代码会全部捕获到**同一个** `i`，输出 `(3 3 3)`。这是一个经典陷阱，
写「给一堆元素各自挂一个回调」时必踩。

### 【坑】RESULT 表达式里不用循环变量会报警告

```elisp
;; 这样写会得到 "Unused lexical variable 'i" 警告
(dotimes (i 5 acc) (setq acc (+ acc i)))
```

因为宏展开后 `acc` 被包在 `(let ((i counter)) ...)` 里，`i` 没被用到就成了未使用变量。
想避免就让 RESULT 表达式引用它（哪怕只是打印），或者改成在 body 外返回：

```elisp
(princ (format "dotimes 结果式：%S\n"
               (let ((acc 0))
                 (dotimes (i 5 acc)      ; 让结果式用上 i
                   (setq acc (+ acc i))))))
```

## 5.7 cl-case

`cl-case` 比 `cond` 紧凑，用 `eql` 比较，适合「值等于几种情况」的分派：

```elisp
(cl-case kind
  ((1 2 3) "小数字")
  ((10 20) "整十")
  (t "其它"))
```

```
cl-case: "A 类" / "其它"
```

需要 `(require 'cl-lib)`。注意 `cl-case` 用 `eql` 比，所以字符串不能用它分派（字符串要用 `pcase` + `equal`）。

## 5.8 一个对照：cond 和 cl-case 写同一件事

```
cond 也能做同样的事: "B"
```

两者都能表达，选哪个看判据是「值的集合」还是「任意谓词」：
值的集合用 `cl-case`，涉及计算或范围的用 `cond`。

---

上一章：[04 · 函数](04-functions.md)　｜　下一章：[06 · 相等性：eq / eql / = / equal](06-equality.md)　｜　返回：[Emacs 扩展开发指南](README.md)
