# 42 · 参数列表：cl-defun、cl-defmacro 与 &key

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/42-argument-lists.el`

上一章弄清了 `cl-lib` 的来历与边界，从这一章起进入手册正文。第一站是**参数列表**——它排在手册第 3 章「Program Structure」的开头，因为后面所有东西（宏、广义变量、`cl-loop`、`cl-defstruct`）的参数都靠它描述。

原生 `defun` 的参数列表只认两个标记：`&optional` 和 `&rest`。`&optional` 只能写变量名，想要默认值就得在函数体开头补一段 `(unless b (setq b ...))`；想知道调用者到底传没传，还得再加一个变量手工记录。Common Lisp 把这些需求直接做进了参数列表，`cl-lib` 把它们原样搬了过来。

先看完整语法。手册第 3.1 节给出的骨架是：

```elisp
(var...
 &optional (var initform svar)...
 &rest var
 &key ((keyword var) initform svar)...
 &aux (var initform)...)
```

七个位置，记住三件事就够了：

1. **必选参数**在最前，`var` 直接写名字；
2. **`&optional` / `&key` 的每个参数都可以写成三元组** `(变量 默认值 是否传入)`，三个位置都能单独省略；
3. **出现顺序固定**：`&optional` → `&rest` → `&key` → `&aux`，不能颠倒。

`cl-defun` 与 `defun` 的差别不只是参数列表——它还顺手给函数体加了一层块（block）。这一点先讲，因为它是理解 `cl-return-from` 的前提。

## 42.1 cl-defun：defun 加一个隐式 block

示例第 1 节：

```elisp
(princ "== 1) cl-defun：defun 加一个隐式 block ==\n")
(cl-defun find-first-odd (numbers)
  (dolist (x numbers)
    (when (cl-oddp x)
      (cl-return-from find-first-odd x)))
  nil)
(princ (format "  (find-first-odd '(2 4 5 6)) = %S\n" (find-first-odd '(2 4 5 6))))
(princ "  cl-defun 除了照常定义函数，还在函数体外面包了一层\n")
(princ "  (cl-block 函数名 ...)，所以函数体里可以直接 cl-return-from。\n")
(princ "  展开一次就能看见这层 block：\n")
(princ (format "  %S\n"
               (macroexpand-1 '(cl-defun f (x) (cl-return-from f x)))))
(princ "  普通 defun 展开后没有 cl-block，写 cl-return-from 就找不到出口。\n")
(princ "  注意 cl-return-from 是词法作用域：块名在定义处就固定了。\n")
```

运行结果：

```
== 1) cl-defun：defun 加一个隐式 block ==
  (find-first-odd '(2 4 5 6)) = 5
  cl-defun 除了照常定义函数，还在函数体外面包了一层
  (cl-block 函数名 ...)，所以函数体里可以直接 cl-return-from。
  展开一次就能看见这层 block：
  (defun f (x) (cl-block f (cl-return-from f x)))
  普通 defun 展开后没有 cl-block，写 cl-return-from 就找不到出口。
  注意 cl-return-from 是词法作用域：块名在定义处就固定了。
```

逐点读：

**`find-first-odd` 是本章唯一一个「像样」的函数。** 它遍历列表，找到第一个奇数就用 `cl-return-from` 立刻返回；循环结束后返回 `nil`。如果用原生 `catch`/`throw`，你得自己起一个标签；`cl-defun` 已经替你起好了——标签就是函数名。

**`macroexpand-1` 只展开一层，所以看得最清楚。** 输入是 `(cl-defun f (x) (cl-return-from f x))`，输出是：

```elisp
(defun f (x) (cl-block f (cl-return-from f x)))
```

也就是说 `cl-defun` 做的工作就是「`defun` + 在函数体外包一层 `cl-block`」。`cl-block` 展开后才变成 `catch`/`throw`，但那已经是下一层的事了。

**块名是函数名，不是 `nil`。** 这带来一个实际后果：如果函数里嵌套了另一个 `cl-defun` 定义的函数，内层同名块会遮蔽外层。`cl-return-from` 按**词法**就近查找块名，不是动态查找——所以它在编译期就能确定跳到哪一层，不需要运行期搜索。

**普通 `defun` 里写 `cl-return-from` 会失败。** 示例没有把这条失败打印出来（报错信息是一句难懂的「变量未绑定」），但原因很简单：`cl-return-from` 展开成对块变量的引用，而 `defun` 没建立那个块变量。要非局部退出，用原生 `catch`/`throw`，或者把函数改成 `cl-defun`。

**块与 `&optional` 无关。** 这一节先讲块，是因为后面每一节的函数都用 `cl-defun` 定义；知道它多了什么，才不会误以为 `cl-return-from` 是「函数返回」的通用写法（它不是，它只跳出一个具名块）。

## 42.2 &optional：默认值与「是否传入」

示例第 2 节：

```elisp
(princ "\n== 2) &optional：默认值与「是否传入」 ==\n")
(cl-defun describe-arg (a &optional (b (* a 10)) (c "缺省" c-supplied-p))
  (list a b c c-supplied-p))
(princ "  (cl-defun describe-arg (a &optional (b (* a 10)) (c \"缺省\" c-supplied-p)) ...)\n")
(princ (format "  (describe-arg 3)            = %S\n" (describe-arg 3)))
(princ (format "  (describe-arg 3 7)          = %S\n" (describe-arg 3 7)))
(princ (format "  (describe-arg 3 7 \"x\")      = %S\n" (describe-arg 3 7 "x")))
(princ (format "  (describe-arg 3 7 nil)      = %S\n" (describe-arg 3 7 nil)))
(princ "  每个可选参数可以写成三元组 (变量 默认值 是否传入)：\n")
(princ "    变量      —— 函数体里用的名字；\n")
(princ "    默认值    —— 没传时求值得到的值，省略则默认 nil；\n")
(princ "    是否传入  —— 绑定 t/nil，表示调用者到底写没写这个实参。\n")
(princ "  最后一行传了显式 nil，所以 c 是 nil 但 c-supplied-p 是 t——\n")
(princ "  「值为 nil」和「没传」是两件事，这正是第三个位置存在的理由。\n")
```

运行结果：

```
== 2) &optional：默认值与「是否传入」 ==
  (cl-defun describe-arg (a &optional (b (* a 10)) (c "缺省" c-supplied-p)) ...)
  (describe-arg 3)            = (3 30 "缺省" nil)
  (describe-arg 3 7)          = (3 7 "缺省" nil)
  (describe-arg 3 7 "x")      = (3 7 "x" t)
  (describe-arg 3 7 nil)      = (3 7 nil t)
  每个可选参数可以写成三元组 (变量 默认值 是否传入)：
    变量      —— 函数体里用的名字；
    默认值    —— 没传时求值得到的值，省略则默认 nil；
    是否传入  —— 绑定 t/nil，表示调用者到底写没写这个实参。
  最后一行传了显式 nil，所以 c 是 nil 但 c-supplied-p 是 t——
  「值为 nil」和「没传」是两件事，这正是第三个位置存在的理由。
```

逐点读：

**`(b (* a 10))` 同时做了两件事**：声明 `b` 是可选参数，并规定「没传时用 `a` 的十倍」。`b` 的默认值不是常量，而是一个**在调用时求值的表达式**——这一点与函数体里的代码没有区别。

**第三个位置 `c-supplied-p` 是布尔标记。** 命名习惯来自 Common Lisp：`-p` 结尾表示谓词，`-supplied-p` 表示「实参是否被提供」。它只可能是 `t` 或 `nil`，与参数本身的值无关。

**最后两行是这一节的重点。** `(describe-arg 3 7 nil)` 传了三个实参，第三个就是 `nil`，于是 `c` 是 `nil`、`c-supplied-p` 是 `t`。如果只写 `(c nil)`，你永远无法区分「调用者明确要求 `nil`」和「调用者没写这个参数」——很多 API 的「重置为默认值」语义就死在这里。

**省略写法完全合法。** `(b)` 等价于 `(b nil nil)`，`(b 10)` 等价于 `(b 10 nil)`。只要不需要「是否传入」，写二元组就够。

**默认值只在没传时求值。** 传了实参，默认值表达式根本不会执行；所以它可以放心调用有副作用的函数（虽然不推荐）。

## 42.3 默认值可以引用前面的参数

示例第 3 节：

```elisp
(princ "\n== 3) 默认值可以引用前面的参数 ==\n")
(princ "  上一节 (b (* a 10)) 里的 a 就是从左边已经绑定好的参数，\n")
(princ "  默认值按从左到右的顺序求值，能看见所有更靠左的参数。\n")
(cl-defun box-volume (&optional (w 1) (h w) (d (* w h)))
  (list w h d))
(princ (format "  (box-volume)          = %S\n" (box-volume)))
(princ (format "  (box-volume 2)        = %S\n" (box-volume 2)))
(princ (format "  (box-volume 2 3)      = %S\n" (box-volume 2 3)))
(princ "  h 的默认值是 w，d 的默认值是 (* w h)：三层依赖，一次调用就串起来。\n")
```

运行结果：

```
== 3) 默认值可以引用前面的参数 ==
  上一节 (b (* a 10)) 里的 a 就是从左边已经绑定好的参数，
  默认值按从左到右的顺序求值，能看见所有更靠左的参数。
  (box-volume)          = (1 1 1)
  (box-volume 2)        = (2 2 4)
  (box-volume 2 3)      = (2 3 6)
  h 的默认值是 w，d 的默认值是 (* w h)：三层依赖，一次调用就串起来。
```

逐点读：

**参数按从左到右的顺序绑定**，每个参数的默认值都能看见它左边的所有参数。所以 `h` 可以用 `w`，`d` 可以用 `w` 和 `h`。

**`(box-volume)` 得到 `(1 1 1)`。** `w` 取默认值 `1`，`h` 取「`w` 的当前值」也是 `1`，`d` 算 `1×1`。默认值不是一次性全部算完再绑定，而是**边绑定边算**。

**`(box-volume 2)` 得到 `(2 2 4)`。** 传了 `w=2`，`h` 默认取 `w` 即 `2`，`d` 得 `4`。这正是「立方体」的语义：只给边长，高和体积自动推出来。

**`(box-volume 2 3)` 得到 `(2 3 6)`。** 传了前两个，`d` 才真正按 `(* 2 3)` 求值。

**这条规则对 `&key` 同样成立。** 关键字参数的默认值也能引用左边的必选参数和更早的关键字参数；但不能引用右边还没绑定的参数——那会变成「变量未绑定」错误。

## 42.4 &rest 与点对参数列表

示例第 4 节：

```elisp
(princ "\n== 4) &rest 与点对参数列表 ==\n")
(cl-defun tally (first &rest others)
  (list first (length others) others))
(princ (format "  (tally 1 2 3 4)  = %S\n" (tally 1 2 3 4)))
(princ (format "  (tally 1)        = %S\n" (tally 1)))
(princ "  &rest 变量绑定一个列表，可以是空表；它后面不能再有必选参数。\n")
(cl-defun dotted (a b . rest)
  (list a b rest))
(princ "  点对形式 (a b . rest) 与 (a b &rest rest) 完全等价：\n")
(princ (format "  (dotted 1 2 3 4) = %S\n" (dotted 1 2 3 4)))
(princ (format "  (dotted 1 2)     = %S\n" (dotted 1 2)))
```

运行结果：

```
== 4) &rest 与点对参数列表 ==
  (tally 1 2 3 4)  = (1 3 (2 3 4))
  (tally 1)        = (1 0 nil)
  &rest 变量绑定一个列表，可以是空表；它后面不能再有必选参数。
  点对形式 (a b . rest) 与 (a b &rest rest) 完全等价：
  (dotted 1 2 3 4) = (1 2 (3 4))
  (dotted 1 2)     = (1 2 nil)

```

逐点读：

**`&rest` 收集的是「剩余全部实参」组成的列表。** `(tally 1 2 3 4)` 里 `first` 是 `1`，`others` 是 `(2 3 4)`。一个都不剩时，`others` 是 `nil`（空表），不是「未绑定」。

**`&rest` 之后不能再出现必选参数。** 这是语法层面的限制，因为「剩余」已经没有边界了。但 `&rest` 后面可以跟 `&key`——下一节就会看到，那时 `&rest` 拿到的是整串关键字。

**点对写法是同一件事的另一种拼法。** Common Lisp 允许把参数列表写成 `(a b . rest)`，含义与 `(a b &rest rest)` 完全相同。`cl-lib` 接受这种写法，是因为从 CL 移植过来的代码里到处都是它。

**`&rest` 与 `apply` 是一对。** 想把一个列表当作实参传进去，就用 `(apply #'tally '(1 2 3 4))`；反过来，`&rest` 把实参收成列表。写包装函数时这两个方向都会用到。

## 42.5 &key：默认关键字

示例第 5 节：

```elisp
(princ "\n== 5) &key：默认关键字 ==\n")
(cl-defun open-window (title &key (width 80) (mode 'text-mode mode-p))
  (list title width mode mode-p))
(princ "  &key 后面的每个参数自动对应一个关键字，名字就是 :变量名。\n")
(princ (format "  (open-window \"a\")                    = %S\n" (open-window "a")))
(princ (format "  (open-window \"a\" :width 100)          = %S\n" (open-window "a" :width 100)))
(princ (format "  (open-window \"a\" :mode nil)           = %S\n" (open-window "a" :mode nil)))
(princ (format "  (open-window \"a\" :mode 'fundamental-mode) = %S\n"
               (open-window "a" :mode 'fundamental-mode)))
(princ "  关键字参数与 &optional 一样支持三元组，所以 :mode 也能问「传了没有」。\n")
(princ "  关键字不区分书写顺序，但都必须在 &key 之后、&aux 之前。\n")
```

运行结果：

```
== 5) &key：默认关键字 ==
  &key 后面的每个参数自动对应一个关键字，名字就是 :变量名。
  (open-window "a")                    = ("a" 80 text-mode nil)
  (open-window "a" :width 100)          = ("a" 100 text-mode nil)
  (open-window "a" :mode nil)           = ("a" 80 nil t)
  (open-window "a" :mode 'fundamental-mode) = ("a" 80 fundamental-mode t)
  关键字参数与 &optional 一样支持三元组，所以 :mode 也能问「传了没有」。
  关键字不区分书写顺序，但都必须在 &key 之后、&aux 之前。
```

逐点读：

**`&key` 后面每写一个变量，就自动多出一个同名关键字。** 声明 `width`，调用时写 `:width`；声明 `mode`，调用时写 `:mode`。不用另外登记。

**关键字参数可以不传、可以乱序、可以只传一部分。** 三次调用分别省略了 `width`、显式传 `nil`、显式传符号，结果都符合预期。

**`(open-window "a" :mode nil)` 的 `mode-p` 是 `t`。** 又一次印证第 2 节的结论：`nil` 是值，不是「缺席」。如果 `mode` 的默认值不是 `nil` 而是别的，这个区别就更重要了。

**关键字必须成对出现。** 每个 `:keyword` 后面都要跟一个值，少一个会报「参数个数不匹配」。关键字只对 `&key` 里的参数生效；`&optional` 参数不能用关键字传。

**顺序限制只针对声明，不针对调用。** 声明时 `&key` 必须在 `&optional`/`&rest` 之后；调用时关键字之间的顺序随意。

## 42.6 &key 的别名：换一个关键字名

示例第 6 节：

```elisp
(princ "\n== 6) &key 的别名：换一个关键字名 ==\n")
(cl-defun make-stroke (x &key ((:color c) "red" c-p) (width 1))
  (list x c width c-p))
(princ "  参数写成 ((:color c) 默认值 是否传入) 时，外部用 :color 调用，\n")
(princ "  函数体里用短名字 c——这就是关键字的别名。\n")
(princ (format "  (make-stroke 0 :color \"blue\")  = %S\n" (make-stroke 0 :color "blue")))
(princ (format "  (make-stroke 0)                = %S\n" (make-stroke 0)))
(princ (format "  直接写 :c 会怎样：%S\n"
               (condition-case err
                   (make-stroke 0 :c "blue")
                 (error (error-message-string err)))))
(princ "  别名只影响调用方用的关键字，不影响变量名；:c 并不存在。\n")
```

运行结果：

```
== 6) &key 的别名：换一个关键字名 ==
  参数写成 ((:color c) 默认值 是否传入) 时，外部用 :color 调用，
  函数体里用短名字 c——这就是关键字的别名。
  (make-stroke 0 :color "blue")  = (0 "blue" 1 t)
  (make-stroke 0)                = (0 "red" 1 nil)
  直接写 :c 会怎样："Keyword argument :c not one of (:color :width)"
  别名只影响调用方用的关键字，不影响变量名；:c 并不存在。
```

逐点读：

**`((:color c) "red" c-p)` 的第一个位置从「变量名」变成了「`(关键字 变量名)`」。** 于是对外暴露的是 `:color`，函数体里用的是短名 `c`。

**别名不是「两个关键字都能用」。** 示例故意用 `:c` 调用，报错信息列出这个函数认识的关键字只有 `(:color :width)`——`:c` 根本不在名单里。别名是替换，不是新增。

**为什么需要别名？** 两个现实原因：一是关键字想写得比变量更具体（`:color` vs `c`），二是想沿用已有的调用约定（外部用 `:foreground`，内部想叫 `color`）。Common Lisp 里这是常见写法，所以 `cl-lib` 支持。

**默认值与「是否传入」在别名里照常工作。** `(make-stroke 0)` 的 `c` 取 `"red"`，`c-p` 为 `nil`；传了 `:color` 则 `c-p` 为 `t`，与普通 `&key` 参数没有区别。

## 42.7 重复关键字与未知关键字

示例第 7 节：

```elisp
(princ "\n== 7) 重复关键字与未知关键字 ==\n")
(cl-defun pick (&key a)
  a)
(princ "  同一个关键字传两次时，cl-lib 取第一次的值：\n")
(princ (format "  (pick :a 1 :a 2) = %S\n" (pick :a 1 :a 2)))
(princ "  传了不认识的关键字，默认报错：\n")
(princ (format "  (pick :b 1) = %S\n"
               (condition-case err (pick :b 1)
                 (error (error-message-string err)))))
(princ "  三种放行办法，效果各不相同：\n")
(princ (format "  1. 调用时加 :allow-other-keys t → %S\n"
               (condition-case err (pick :b 1 :allow-other-keys t)
                 (error (error-message-string err)))))
(cl-defun pick-loose (&key a &allow-other-keys)
  a)
(princ (format "  2. 定义时加 &allow-other-keys   → %S\n" (pick-loose :b 1 :a 2)))
(princ "  3. 用 &rest 自己接管整个关键字列表（下一节）。\n")
(princ "  注意第 1 种只对这一次调用有效，第 2 种对这个函数永久有效。\n")
```

运行结果：

```
== 7) 重复关键字与未知关键字 ==
  同一个关键字传两次时，cl-lib 取第一次的值：
  (pick :a 1 :a 2) = 1
  传了不认识的关键字，默认报错：
  (pick :b 1) = "Keyword argument :b not one of (:a)"
  三种放行办法，效果各不相同：
  1. 调用时加 :allow-other-keys t → nil
  2. 定义时加 &allow-other-keys   → 2
  3. 用 &rest 自己接管整个关键字列表（下一节）。
  注意第 1 种只对这一次调用有效，第 2 种对这个函数永久有效。
```

逐点读：

**重复关键字取第一次的值。** `(pick :a 1 :a 2)` 返回 `1` 而不是 `2`。这与很多人的直觉相反（后写的覆盖先写的），但 Common Lisp 就是这么规定的，`cl-lib` 照搬。写包装函数把参数层层转交时，要注意这个语义。

**未知关键字默认报错。** 报错信息长这样：`Keyword argument :b not one of (:a)`。它把该函数认识的全部关键字列了出来，排错时很有用。

**放行办法一：调用时写 `:allow-other-keys t`。** 效果是「这一次调用别查未知键」，返回值是 `nil`（因为 `a` 没传）。这个开关可以被层层传递：外层函数把 `:allow-other-keys` 原样转交，内层也会放行。

**放行办法二：定义时写 `&allow-other-keys`。** 它放在 `&key` 参数之后，表示「这个函数永远不检查未知键」。示例里 `(pick-loose :b 1 :a 2)` 返回 `2`，`:b` 被静默忽略。

**放行不等于处理。** 两种办法都只是「不报错」，未知键的值不会自动绑定到任何变量。真要处理，就得用 `&rest` 自己接管——下一节。

**手册还提到 `safety` 为 0 时关闭参数个数与关键字检查。** 这条只在**字节编译**的代码里生效：解释执行时，`cl-defun` 展开出的检查代码已经写死在函数里，改 `safety` 也去不掉。具体怎么声明 `safety`，留到第 43 章讲 `cl-declaim` 时实测。

## 42.8 &rest 与 &key 并存

示例第 8 节：

```elisp
(princ "\n== 8) &rest 与 &key 并存 ==\n")
(cl-defun both (&rest rest &key a b)
  (list a b rest))
(princ "  &rest 与 &key 同时出现时，&rest 拿到的是原始的关键字序列，\n")
(princ "  而 a、b 是从同一串序列里解析出来的——两者不是二选一。\n")
(princ (format "  (both :a 1 :b 2) = %S\n" (both :a 1 :b 2)))
(princ "  这让函数可以「先按关键字取值，再把整串转交给别人」，\n")
(princ "  典型用法是包装函数：自己认一部分键，剩下的原样传下去。\n")
```

运行结果：

```
== 8) &rest 与 &key 并存 ==
  &rest 与 &key 同时出现时，&rest 拿到的是原始的关键字序列，
  而 a、b 是从同一串序列里解析出来的——两者不是二选一。
  (both :a 1 :b 2) = (1 2 (:a 1 :b 2))
```

逐点读：

**`&rest` 拿到的是「原样的一串」，不是「解析后的关联表」。** `(both :a 1 :b 2)` 里 `rest` 是 `(:a 1 :b 2)`，`a` 是 `1`，`b` 是 `2`。同一批实参被用了两遍。

**这个组合的用途是转发。** 典型场景是包装函数：自己认领一两个关键字，把其余原样交给下层。下面这段可以单独跑（`inner` 只是占位，真实代码里换成被包装的函数）：

```elisp
(defun inner (&rest args) args)

(cl-defun wrapper (&rest args &key verbose &allow-other-keys)
  (when verbose (princ "  （下层调用前先做点事）\n"))
  (let ((rest (cl-loop for (k v) on args by #'cddr
                       unless (eq k :verbose)
                       append (list k v))))
    (apply #'inner rest)))

(wrapper :verbose t :a 1 :b 2)   ; => (:a 1 :b 2)
(wrapper :a 1)                   ; => (:a 1)
```

`cl-loop` 那句按两两一组遍历 `args`，把 `:verbose` 这一对剔除，剩下的重新拼成 plist 交给 `apply`。不写 `&rest` 就做不到这一点——你只能看到解析后的 `verbose`，看不到「其余」。

**`&rest` 与 `&key` 并存时，`&key` 的解析不会消耗 `&rest` 的列表。** 两者看到的是同一份数据，`&rest` 绑定的是原始序列，`&key` 绑定的是从中提取的值。所以不必担心「谁先谁后」。

## 42.9 &aux：顺带绑定的局部变量

示例第 9 节：

```elisp
(princ "\n== 9) &aux：顺带绑定的局部变量 ==\n")
(cl-defun rect (w h &aux (area (* w h)) (kind (if (= w h) 'square 'rect)))
  (list w h area kind))
(princ "  &aux 后面是普通 let 绑定：不占实参位置，也拿不到「是否传入」。\n")
(princ (format "  (rect 3 4) = %S\n" (rect 3 4)))
(princ (format "  (rect 4 4) = %S\n" (rect 4 4)))
(princ "  &aux 变量在函数体开头就已绑定，可以省掉一层 let。\n")
```

运行结果：

```
== 9) &aux：顺带绑定的局部变量 ==
  &aux 后面是普通 let 绑定：不占实参位置，也拿不到「是否传入」。
  (rect 3 4) = (3 4 12 rect)
  (rect 4 4) = (4 4 16 square)
  &aux 变量在函数体开头就已绑定，可以省掉一层 let。
```

逐点读：

**`&aux` 后面的东西不是参数，是 `let` 绑定。** `area` 和 `kind` 不出现在调用方的实参列表里，只在函数体内可见。它们的位置在参数表最后，因为要能看见前面所有参数。

**`(rect 4 4)` 的 `kind` 是 `square`。** `kind` 的默认值表达式 `(if (= w h) ...)` 引用 `w` 和 `h`，在绑定 `kind` 时两者都已就绪。

**`&aux` 不支持三元组。** 写 `(area (* w h) area-p)` 不会得到「是否传入」标记——`&aux` 没有调用方，谈何传入。第三个别名位置在这里无意义，写了也只会被当成多余元素。

**它省的是 `let`，不是参数。** 如果计算只在一个分支里用，放函数体里的 `let` 更清楚；如果每个分支都要用，`&aux` 能少一层缩进。这是风格问题，没有性能差别。

## 42.10 解构参数与 &whole

示例第 10 节：

```elisp
(princ "\n== 10) 解构参数与 &whole ==\n")
(cl-defun spread ((a b) &optional (c 3))
  (list a b c))
(princ "  参数位置写成列表时，实参本身会被再拆一层：\n")
(princ (format "  (spread '(1 2)) = %S\n" (spread '(1 2))))
(cl-defun pair-info ((key . value))
  (list key value))
(princ (format "  (pair-info '(x . 42)) = %S\n" (pair-info '(x . 42))))
(cl-defun nested-args ((a (b c)) &optional ((d e) '(4 5)))
  (list a b c d e))
(princ (format "  (nested-args '(1 (2 3))) = %S\n" (nested-args '(1 (2 3)))))
(princ "  解构可以嵌套，也可以给整组解构参数写默认值，规则与 &optional 相同。\n")
(cl-defun whole-in-destructuring ((&whole form a b))
  (list form a b))
(princ (format "  (&whole) 在解构列表里可用：(whole-in-destructuring '(1 2)) = %S\n"
               (whole-in-destructuring '(1 2))))
(princ "  但顶层参数表不接受 &whole，宏展开阶段就会拒绝：\n")
(princ (format "  %S\n"
               (condition-case err
                   (macroexpand '(cl-defun whole-demo (&whole all a b)
                                   (list all a b)))
                 (error (error-message-string err)))))
(princ "  想在函数体里拿到「整个实参表」，用 &rest 即可，不必用 &whole。\n")
```

运行结果：

```
== 10) 解构参数与 &whole ==
  参数位置写成列表时，实参本身会被再拆一层：
  (spread '(1 2)) = (1 2 3)
  (pair-info '(x . 42)) = (x 42)
  (nested-args '(1 (2 3))) = (1 2 3 4 5)
  解构可以嵌套，也可以给整组解构参数写默认值，规则与 &optional 相同。
  (&whole) 在解构列表里可用：(whole-in-destructuring '(1 2)) = ((1 2) 1 2)
  但顶层参数表不接受 &whole，宏展开阶段就会拒绝：
  "&whole not currently implemented"
  想在函数体里拿到「整个实参表」，用 &rest 即可，不必用 &whole。
```

逐点读：

**`(spread '(1 2))` 只传了「一个」实参**，但这个实参是列表。参数表写成 `((a b) ...)` 时，`cl-defun` 会先把这个列表拆成 `a` 和 `b`。所以 `a` 得 `1`，`b` 得 `2`，`c` 取默认值 `3`。

**点对解构 `((key . value))` 用于关联项。** 传入 `(x . 42)`，`key` 得 `x`，`value` 得 `42`。这正是 `alist` 里每一项的形状，处理配置表时很顺手。

**解构可以嵌套，也可以带默认值。** `((a (b c)) &optional ((d e) '(4 5)))` 里，第一个实参 `(1 (2 3))` 拆成 `a=1`、`b=2`、`c=3`；第二个可选参数整组默认 `(4 5)`，拆成 `d=4`、`e=5`。默认值写在整个解构模式的位置上，不是写给某个子变量的。

**`&whole` 只在解构列表内部有效。** 写成 `((&whole form a b))` 时，`form` 绑定「还没被拆的整个实参」，所以结果是 `((1 2) 1 2)`。

**顶层参数表拒绝 `&whole`。** 示例用 `macroexpand` 捕获了错误：`&whole not currently implemented`。手册明确说明这一点：`&whole` 是给解构模式用的，函数/宏的顶层参数表没有「整个实参表」这个概念（顶层本来就没有被拆的对象）。

**`&whole` 与 `&rest` 的区别。** `&rest` 收集「剩下的」，是一段；`&whole` 保留「完整的原始值」，是一份。在解构里，`&whole` 拿到的往往是一个列表或点对，而不是剩余参数。

**解构是 `cl-defun` 相对 `defun` 的实打实增益。** 原生 `defun` 的参数表不接受嵌套列表；用 `cl-defun` 就不必在函数体里写一堆 `(nth 0 ...)`、`(nth 1 ...)`。

## 42.11 cl-defmacro：&body 与 &environment

示例第 11 节：

```elisp
(princ "\n== 11) cl-defmacro：&body 与 &environment ==\n")
(cl-defmacro my-when (condition &body body)
  `(if ,condition (progn ,@body) nil))
(princ "  &body 是 &rest 的同义词，只多一个作用：告诉编辑器缩进时\n")
(princ "  把后面的形式当作代码体，缩进 2 格而不是对齐到参数列。\n")
(princ (format "  (macroexpand-all '(my-when t 1 2)) = %S\n"
               (macroexpand-all '(my-when t 1 2))))
(cl-defmacro env-has-fn-p (name &environment env)
  (if (assq name env) t nil))
(princ "  &environment 把「展开点周围的词法环境」绑给一个变量，\n")
(princ "  宏可以据此判断某个名字在当前作用域里有没有局部定义：\n")
(princ (format "  顶层 (env-has-fn-p foo) = %S\n" (env-has-fn-p foo)))
(cl-flet ((foo () 1))
  (princ (format "  cl-flet 内 (env-has-fn-p foo) = %S\n" (env-has-fn-p foo))))
(princ (format "  离开 cl-flet 后 = %S\n" (env-has-fn-p foo)))
(princ "  env 是一个关联列表，cl-flet 会把局部函数挂进去，所以 assq 能查到。\n")
```

运行结果：

```
== 11) cl-defmacro：&body 与 &environment ==
  &body 是 &rest 的同义词，只多一个作用：告诉编辑器缩进时
  把后面的形式当作代码体，缩进 2 格而不是对齐到参数列。
  (macroexpand-all '(my-when t 1 2)) = (if t (progn 1 2) nil)
  &environment 把「展开点周围的词法环境」绑给一个变量，
  宏可以据此判断某个名字在当前作用域里有没有局部定义：
  顶层 (env-has-fn-p foo) = nil
  cl-flet 内 (env-has-fn-p foo) = t
  离开 cl-flet 后 = nil
  env 是一个关联列表，cl-flet 会把局部函数挂进去，所以 assq 能查到。
```

逐点读：

**`cl-defmacro` 与 `cl-defun` 共享同一套参数列表。** `&optional`、`&rest`、`&key`、`&aux`、解构，全都能用。区别只在宏的返回值是「要展开成的代码」，不是运行结果。

**`&body` 与 `&rest` 在求值上完全等价。** `my-when` 的 `body` 就是一个列表，`(macroexpand-all '(my-when t 1 2))` 得到 `(if t (progn 1 2) nil)`——说明 `,@body` 把两个形式拼进了 `progn`。`&body` 唯一的作用是给编辑器一个缩进提示：`&body` 之后的内容按代码体缩进，`&rest` 之后按数据缩进。

**`&environment` 把展开点的词法环境交给你。** 在顶层，`env` 是 `nil`；在 `cl-flet` 里，`cl-flet` 会把局部函数名以关联项的形式挂进 `env`，所以 `(assq 'foo env)` 非空。示例里 `env-has-fn-p` 据此返回 `t`/`nil`。

**这个能力的实际用途是「让宏尊重局部绑定」。** 比如一个宏想判断某个函数名在当前作用域是否被 `cl-flet` 改写；如果被改写，就不能把调用优化成直接调用全局函数。`cl-lib` 自己的 `cl-flet` 就依赖类似的机制。

**`cl-defmacro` 也有隐式块，块名是宏名。** 它和 `cl-defun` 一样展开成 `cl-block`，所以宏体里可以 `cl-return-from`。不过宏代码通常在编译期跑，非局部退出很少用。

## 42.12 cl-defsubst 与 cl-function

示例第 12 节：

```elisp
(princ "\n== 12) cl-defsubst 与 cl-function ==\n")
(cl-defsubst square (x)
  (* x x))
(princ "  cl-defsubst = cl-defun + 一条 compiler macro，编译时尽量内联。\n")
(princ (format "  (square 5) = %S\n" (square 5)))
(princ (format "  它登记的 compiler macro：%S\n"
               (function-get 'square 'compiler-macro)))
(princ "  compiler macro 的名字是「函数名--cmacro」，第 43 章会自己写一个。\n")
(princ "  lambda 默认只支持 &optional/&rest；要写完整参数表就套 cl-function：\n")
(princ "  (funcall (cl-function (lambda (a &key (b 2)) (list a b))) 1 :b 5)\n")
(princ (format "    = %S\n"
               (funcall (cl-function (lambda (a &key (b 2)) (list a b))) 1 :b 5)))
(princ "  cl-function 是宏，它在编译期把 lambda 改写成普通函数，没有运行期开销。\n")
```

运行结果：

```
== 12) cl-defsubst 与 cl-function ==
  cl-defsubst = cl-defun + 一条 compiler macro，编译时尽量内联。
  (square 5) = 25
  它登记的 compiler macro：square--cmacro
  compiler macro 的名字是「函数名--cmacro」，第 43 章会自己写一个。
  lambda 默认只支持 &optional/&rest；要写完整参数表就套 cl-function：
  (funcall (cl-function (lambda (a &key (b 2)) (list a b))) 1 :b 5)
    = (1 5)
  cl-function 是宏，它在编译期把 lambda 改写成普通函数，没有运行期开销。
```

逐点读：

**`cl-defsubst` 定义出来的仍是一个普通函数。** `(square 5)` 返回 `25`，你可以 `funcall` 它、把它传给 `mapcar`。它没有变成宏，调用方不必改写法。

**额外登记的东西叫 compiler macro。** `(function-get 'square 'compiler-macro)` 返回符号 `square--cmacro`，说明 `cl-defsubst` 顺手定义了这么一条「编译期改写规则」。字节编译器遇到 `(square x)` 时，会先用这条规则把调用点替换成 `(* x x)`，省掉一次函数调用。

**内联是「尽量」，不是「一定」。** 参数个数不对、或者处于 `(optimize (notinline ...))` 区域时，编译器会放弃内联，退回普通调用。所以 `cl-defsubst` 永远不改变语义，只影响生成的代码。

**`cl-function` 解决的是 lambda 的参数表问题。** 原生 `lambda` 只支持 `&optional`/`&rest`，写 `&key` 会报错。`(cl-function (lambda (a &key (b 2)) ...))` 在编译期把 lambda 改写成「接受 `&rest`、自己解析关键字」的普通函数，于是完整参数表就能用了。

**它没有运行期开销。** `cl-function` 是宏，展开后就是普通 `lambda`，不会在每次调用时多包一层。示例里 `(funcall ... 1 :b 5)` 返回 `(1 5)`，`b` 按关键字取到 `5`。

## 42.13 小结

| 主题 | 结论 |
|---|---|
| `cl-defun` | `defun` + 完整参数列表 + 隐式块（块名=函数名），可用 `cl-return-from` |
| `&optional` 三元组 | `(变量 默认值 是否传入)`；`nil` 是值，`是否传入` 才是「传没传」 |
| 默认值求值 | 从左到右，可引用左侧已绑定的参数；只在没传时求值 |
| `&rest` | 收集剩余实参为列表；点对写法 `(a b . rest)` 等价 |
| `&key` | 默认关键字 `:变量名`；可乱序、可省略；必须成对出现 |
| 关键字别名 | `((:color c) init svar)`；外部 `:color`，内部 `c`；`:c` 不存在 |
| 重复关键字 | 取第一次的值，不是最后一次 |
| 未知关键字 | 默认报错；`&allow-other-keys` 或调用时 `:allow-other-keys t` 放行 |
| `&rest` + `&key` | 两者看同一份实参：`&rest` 拿原始序列，`&key` 拿解析后的值 |
| `&aux` | 函数体内的 `let` 绑定，不占实参、没有「是否传入」 |
| 解构 | 参数位置可写列表/点对/嵌套，可嵌套默认值；`&whole` 仅在解构内有效 |
| `cl-defmacro` | 参数表同 `cl-defun`；`&body` = `&rest` + 缩进提示；`&environment` 暴露词法环境 |
| `cl-defsubst` | 函数 + compiler macro；编译期内联，语义不变 |
| `cl-function` | 让 `lambda` 支持完整参数表；编译期改写，无运行期开销 |

参数列表是「声明」，下一章要讲的是「这些声明在什么时机生效」。`cl-eval-when` 能精确控制一段代码是编译期跑、加载期跑还是求值期跑；`cl-once-only` 解决宏展开时实参被求值两次的经典陷阱；`cl-define-compiler-macro` 则是自己动手写这一章见过的 `--cmacro`。这三样合起来，才算真正会写宏。

上一章：[41 · cl-lib 是什么：来历、加载、命名与移植](41-cl-lib-overview.md)　｜　下一章：[43 · 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro](43-macro-tools.md)　｜　返回：[Emacs 扩展开发指南](README.md)
