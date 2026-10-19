# 27 · cons 单元与列表的内存模型

> 所属部分：第 7 部分 · 跟随 eintr：内存模型与递归

> 示例：`examples/27-cons-cells.el`

第 7 章已经用过 `cons`、`car`、`cdr`，但只停留在「怎么写」。这一章换个角度：把列表**画出来**，看清楚它在内存里到底长什么样。看懂这张图之后，`setcar`、共享结构、`eq`/`equal` 的区别，以及「符号为什么既是变量又是函数」，都会变成同一件事的不同侧面。

这一章对应 eintr 第 1 章（List Processing）和第 7 章（`car`/`cdr`/`cons`）的核心，但全部用 Emacs 31.1 实测重写。

## 27.1 一个 cons 单元就是两个格子

Lisp 里最小的数据结构不是「列表」，而是 **cons 单元**（cons cell）。一个 cons 单元里有两个格子，分别叫 `car` 和 `cdr`，每个格子可以放一个任意对象（一个数、一个字符串，或者一个指向别的 cons 单元的「箭头」）。

`(cons 1 2)` 造出的就是一个这样的单元：

```
    +---+---+
    | 1 | 2 |     <- (cons 1 2)
    +---+---+
     car cdr
```

这段图和下面的输出，都是示例的第一节直接打印出来的：

```elisp
;;; 1) 一个 cons 单元就是两个格子：car 和 cdr。
;;;    (cons 1 2) 造出一个点对，打印成 (1 . 2)。
(princ "一个 cons 有两个格子：\n")
(princ "    +---+---+\n")
(princ "    | 1 | 2 |     <- (cons 1 2)\n")
(princ "    +---+---+\n")
(princ "     car cdr\n\n")

(princ (format "(cons 1 2)   = %S\n" (cons 1 2)))
(princ (format "car of it   = %S\n" (car (cons 1 2))))
(princ (format "cdr of it   = %S\n" (cdr (cons 1 2))))
```

输出：

```
一个 cons 有两个格子：
    +---+---+
    | 1 | 2 |     <- (cons 1 2)
    +---+---+
     car cdr

(cons 1 2)   = (1 . 2)
car of it   = 1
cdr of it   = 2
```

`(1 . 2)` 中间那个点，就是「这是一个点对（dotted pair），cdr 不是一个列表」的记号。**这不是语法糖，而是 cons 单元的诚实写法**：cdr 格子里装的就是数字 `2` 本身。

## 27.2 列表是一条以 nil 收尾的链

普通的「列表」是 cons 单元被 `cdr` 串起来的一条链，最后的 `cdr` 指向 `nil`（空表）：

```
    +---+---+    +---+---+    +---+---+
    | 1 | *-+--> | 2 | *-+--> | 3 |nil|
    +---+---+    +---+---+    +---+---+
```

所以 `(list 1 2 3)` 和 `(cons 1 (cons 2 (cons 3 nil)))` 造出来的是**同一个东西**——不是「类似」，是逐一相等：

```elisp
;;; 2) 列表是一条以 nil 收尾的 cons 链。
;;;    (list 1 2 3) 与 (cons 1 (cons 2 (cons 3 nil))) 是同一个东西。
(princ (format "手工搭出来 = %S\n" (cons 1 (cons 2 (cons 3 nil)))))
(princ (format "list 搭出来 = %S\n" (list 1 2 3)))
(princ (format "两者 equal  = %S\n" (equal (cons 1 (cons 2 (cons 3 nil))) (list 1 2 3))))
```

输出：

```
手工搭出来 = (1 2 3)
list 搭出来 = (1 2 3)
两者 equal  = t
```

理解了这一点，`(1 2 3)` 那种「省略掉的点」就不再神秘了：它只是 `(1 . (2 . (3 . nil)))` 的简写，**点后面紧跟一个 cons 或 `nil` 时，点可以省略**。

## 27.3 剥链：car/cdr 一层层往下走

链表的操作全是「取头」和「取尾」。一直取 `cdr`，`nil` 出现的地方就是链尾：

```elisp
;;; 3) 一层一层剥：cdr 一直走到 nil，就说明到尾巴了。
(let ((lst (list 'a 'b 'c)))
  (princ (format "起点   : %S\n" lst))
  (princ (format "cdr    : %S\n" (cdr lst)))
  (princ (format "cddr   : %S\n" (cddr lst)))
  (princ (format "cdddr  : %S   <- 空表 nil，链条到头的标志\n" (cdddr lst)))
  (princ (format "caddr  : %S   <- 等价于 (car (cdr (cdr x)))\n" (caddr lst))))
```

输出：

```
起点   : (a b c)
cdr    : (b c)
cddr   : (c)
cdddr  : nil   <- 空表 nil，链条到头的标志
caddr  : c   <- 等价于 (car (cdr (cdr x)))
```

`caddr` 读作 `c-a-d-d-r`：从右往左读，先 `d` 再 `d` 再 `a`，也就是 `(car (cdr (cdr x)))`。Emacs 规定 `c` 与 `r` 之间最多四个 `a`/`d`。

**任何「遍历列表」的循环，骨架都是这个**：当前节点取 `car` 用一用，然后 `(setq lst (cdr lst))` 走到下一个节点，直到 `lst` 变成 `nil`。第 28 章的递归只是把「循环」换成了「自己调用自己」，骨架完全一样。

## 27.4 就地修改：setcar

`setcar` 把某个 cons 单元的 `car` 格子换成新值。注意它**不返回新列表**，而是直接改掉那个格子，返回值只是「改动后的那个 cons」：

```elisp
;;; 4) setcar / setcdr 就地改格子（破坏性）。
;;;    先看 setcar：把链表的第一个 car 换掉。
(let ((lst (list 1 2 3)))
  (setcar lst 'one)
  (princ (format "\nsetcar 之后       : %S\n" lst)))
```

输出：

```
setcar 之后       : (one 2 3)
```

## 27.5 就地修改：setcdr

`setcdr` 改的是 `cdr` 格子，也就是那个「箭头」。把箭头指向另一条链，就完成了**拼接**——这正是 `nconc` 在底层干的事：

```elisp
;;; 5) setcdr 把 cdr 指向另一条链 —— 这就是「拼接」的底层动作。
(let ((lst (list 1 2 3))
      (tail (list 'x 'y)))
  (setcdr lst tail)
  (princ (format "setcdr 接上尾巴   : %S\n" lst)))
```

输出：

```
setcdr 接上尾巴   : (1 x y)
```

画成图，`setcdr` 做的事就是把第一个单元右边的箭头从 `(2 . …)` 改指向 `tail`：

```
改之前： [1|*]--> [2|*]--> [3|nil]
                  ^
                  |
                tail 用不上

改之后： [1|*]--------------------+
                                  |
        [2|*]--> [3|nil]  （被丢弃） |
                                  v
                                 [x|*]--> [y|nil]
```

因为箭头可以指向任何对象，`setcdr` 也可以指向一个**非列表**，结果就成了点对：

```elisp
;;; 6) setcdr 也可以指向一个非列表，结果就是点对（不正规列表）。
(let ((p (cons 1 2)))
  (setcdr p 3)
  (princ (format "setcdr 指向数字   : %S\n" p)))
```

输出：

```
setcdr 指向数字   : (1 . 3)
```

## 27.6 【坑】共享结构

这是全章最该记住的一节。**赋值不会复制列表，只复制「指向链头的指针」**。两个变量可以指向同一条子链：

```elisp
;;; 7) 【坑】共享结构：两个列表指向同一个子链，改一个另一个也变。
(let* ((common (list 'a 'b))
       (one (list 1 common))
       (two (list 2 common)))
  (setcar common 'shared)
  (princ (format "\n共享子链改之前 one/two 都指同一个对象\n"))
  (princ (format "one = %S\n" one))
  (princ (format "two = %S   <- common 被改，两个都跟着变\n" two)))
```

输出：

```
共享子链改之前 one/two 都指同一个对象
one = (1 (shared b))
two = (2 (shared b))   <- common 被改，两个都跟着变
```

画出来是这样的——`one` 和 `two` 的第二个格子都指向**同一个** cons：

```
one: [1|*]---+
             +--> [a|*]  ← 只有一个「a 单元」，common 指的是它
two: [2|*]---+
```

`setcar` 改的是这个被共享的单元，所以 `one` 和 `two` 同时变了。这类 bug 在改配置 alist、缓存结构时特别隐蔽：**改动发生在看似无关的地方**。

规避手段就是第 7 章说过的：要独立副本，用 `copy-sequence`（浅拷贝一层）或 `copy-tree`（递归深拷贝）。

## 27.7 eq 还是 equal：内存模型给了答案

现在可以正面回答第 6 章留下的问题了：

```elisp
;;; 8) eq 判断的是「是不是同一个对象」，equal 判断的是「长得一样」。
(let ((x (list 1 2))
      (y (list 1 2)))
  (princ (format "\n两份内容相同的列表：eq = %S，equal = %S\n"
                 (eq x y) (equal x y))))
(let* ((x (list 1 2))
       (y x))
  (princ (format "同一份对象：eq = %S，equal = %S\n" (eq x y) (equal x y))))
```

输出：

```
两份内容相同的列表：eq = nil，equal = t
同一份对象：eq = t，equal = t
```

- `eq` 问的是「这两个变量指向**同一个盒子**吗」—— `(list 1 2)` 调用了两次，造了两串盒子，所以是 `nil`；
- `equal` 问的是「把两条链逐格比下去，内容一样吗」—— 一样，所以是 `t`。

一句话记忆：**`eq` 比箭头，`equal` 比内容**。所以在自己写的代码里判断两个列表是否「相同」，几乎总是该用 `equal`。

## 27.8 符号：一组抽屉柜

最后一个模型。eintr 用「**符号是一组抽屉柜**」来解释 Elisp 的符号：一个符号名字上挂着几个不同的格子，各装各的东西。

```elisp
;;; 9) 符号是一组抽屉柜：名字上挂着「值格」「函数格」「属性表」。
;;;    这是 Elisp 最独特的设计，也是「同名变量与函数互不干扰」的原因。
(defvar demo-drawer 'initial-value)
(defun demo-drawer-fn (x) (* x 2))
(put 'demo-drawer 'color 'blue)
(put 'demo-drawer 'size 3)
```

这里对同一个符号 `demo-drawer` 做了两件互不干扰的事：`defvar` 往**值格**里放 `initial-value`，`put` 往**属性表**（property list）里放 `color` 和 `size`。再加一个同名的 `demo-drawer-fn`，那是另一个符号，用来说明「函数也有自己的格子」——事实上 `demo-drawer` 本身就可以同时是变量名和函数名。

把三个抽屉读出来：

```elisp
(princ "\n符号 demo-drawer 的抽屉：\n")
(princ (format "  值格   : %S\n" demo-drawer))
(princ (format "  属性表 : %S\n" (symbol-plist 'demo-drawer)))
(princ (format "  取属性 : color = %S\n" (get 'demo-drawer 'color)))
(let ((demo-drawer 'changed))
  (princ (format "  值格先被临时改写为 %S\n" demo-drawer)))
(princ (format "  let 结束后值格回到 %S   <- 动态作用域，出了 let 就还原\n"
               demo-drawer))
(princ (format "函数格里存的是函数对象：car -> %S\n" (symbol-function 'car)))
(princ (format "文档字符串也挂在符号上：%S\n"
               (substring (documentation 'car) 0 20)))
```

输出：

```
符号 demo-drawer 的抽屉：
  值格   : initial-value
  属性表 : (color blue size 3)
  取属性 : color = blue
  值格先被临时改写为 changed
  let 结束后值格回到 initial-value   <- 动态作用域，出了 let 就还原
函数格里存的是函数对象：car -> #<subr car>
文档字符串也挂在符号上："Return the car of LI"
```

逐条解释：

- **值格**：`defvar` 放的那个值，读它就是写个符号名。`let` 临时改写它，出了 `let` 就还原——因为 `defvar` 定义的变量是**特殊变量**（special variable），`let` 对它做的是动态绑定，而不是造一个独立的局部变量。
- **属性表**：一个 plist（第 7 章讲过）。`(symbol-plist 'demo-drawer)` 得到 `(color blue size 3)`；`get`/`put` 是最常用的读写入口。Emacs 内部大量使用属性表，比如 `(get 'sym 'face)` 拿默认 face。
- **函数格**：`symbol-function` 读出来的。`car` 的函数格里是一个**内置子程序对象** `#<subr car>`（Lisp 实现的函数则会显示成 `#<subr>` 之外的 lambda 或字节码对象）。
- **文档字符串**：也是挂在符号上的一个格子（用 `C-h f` 看到的那段文字）。

「符号是抽屉柜」这个模型的价值在于：它解释了为什么 Emacs 里可以 `(setq foo 1)` 又 `(defun foo ...)`，为什么 `(put 'x 'y 'z)` 不和变量打架，以及为什么 `symbol-plist` 能被 `defvar` 之外的东西随意附加数据。

## 27.9 小结

| 概念 | 记法 |
|---|---|
| cons 单元 | 两个格子：`car` 和 `cdr` |
| `(1 . 2)` | 点对；cdr 不是列表 |
| `(1 2 3)` | `(1 . (2 . (3 . nil)))` 的简写 |
| 列表结尾 | 一定是 `nil` |
| `setcar` / `setcdr` | 就地改格子，破坏性，不返回新链 |
| 共享结构 | 赋值只复制指针，改一处影响多处 |
| `eq` / `equal` | 比箭头 / 比内容 |
| 符号 | 值格 + 函数格 + 属性表 + 文档 |

下一章把这个模型用起来：**递归**。它是 eintr 的绝对核心，也是「遍历一棵 cons 树」最自然的写法。

---

上一章：[26 · 完整示例：一个 todo 扩展](26-todo-demo.md)　｜　下一章：[28 · 递归：让函数调用自己](28-recursion.md)　｜　返回：[Emacs 扩展开发指南](README.md)
