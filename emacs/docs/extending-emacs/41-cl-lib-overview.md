# 41 · cl-lib 是什么：来历、加载、命名与移植

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/41-cl-lib-overview.el`

从这一章起，我们换一本参考书：GNU Emacs 自带的 **Common Lisp Extensions** 手册（文件名 `cl-lib`，下文简称 CL 手册）。它描述的不是「Emacs 语言本身」，而是 Emacs 附带的一套**兼容 Common Lisp 的扩展库**：`cl-loop`、`cl-defstruct`、`cl-letf`、`cl-flet`、`cl-incf`……你在真实扩展里天天见到的那些 `cl-` 开头的名字，全都出自这里。

先泼一盆冷水：**这套库不是 Common Lisp**。它是「在 Emacs Lisp 上尽量模仿 Common Lisp」的一层宏和函数。模仿到什么程度、哪些地方故意不模仿、老代码里的 `cl.el` 为什么不能再用——这些是动手写代码之前必须弄清楚的，否则你会把从别处抄来的 CL 代码贴进 Emacs，然后对着一条看不懂的报错发呆。

本章不教具体函数，只回答四个问题：

- 它由哪些文件组成，为什么只 `require` 一个？
- 命名怎么读，哪些名字是 CL 原生的、哪些是 Emacs 自己加的？
- 哪些「同名函数」的语义其实和 CL 不一样？
- 从 Common Lisp 移植代码时，哪些语法在 Emacs 里根本读不出来？

结论全部来自本机 **Emacs 31.1** 的实测输出。手册本身写于更早的 Emacs 时代，凡涉及版本的地方，本章都以 31.1 的实际行为为准。

## 41.1 一个 `require`，四个文件

示例第 1 节先看这套库的物理结构：

```elisp
(require 'cl-lib)

(princ "== 1) 加载：一个 require，四个文件 ==\n")
(princ (format "  require 之后 (featurep 'cl-lib) = %S\n" (featurep 'cl-lib)))
(princ (format "  主文件：%S\n" (file-name-nondirectory (locate-library "cl-lib"))))
(dolist (lib '("cl-extra" "cl-seq" "cl-macs" "cl-print"))
  (princ (format "  %-9s 在 load-path 里：%S\n" lib
                 (and (locate-library lib) t))))
(princ "  cl-lib 内部拆成三块：cl-lib 是基础层，cl-extra 放大而复杂的函数，\n")
(princ "  cl-seq 放序列与列表操作，cl-macs 只在编译期需要（全是宏）。\n")
(princ "  cl-print 是另一块：给调试器用的增强打印，第 48 章再讲。\n")
(princ "  cl-lib.el 里已经写好了全部 autoload，所以用户只 require 它一个。\n")
(princ (format "  旧入口 cl.el 在 obsolete 目录里：%S\n"
               (and (string-match-p "/obsolete/"
                                    (or (locate-library "cl") ""))
                    t)))
(princ "  （在 obsolete 目录里，加载它会打印 `Package cl is deprecated'，\n")
(princ "   所以本书的示例一个都不 require 它。）\n")
```

运行结果：

```
== 1) 加载：一个 require，四个文件 ==
  require 之后 (featurep 'cl-lib) = t
  主文件："cl-lib.elc"
  cl-extra  在 load-path 里：t
  cl-seq    在 load-path 里：t
  cl-macs   在 load-path 里：t
  cl-print  在 load-path 里：t
  cl-lib 内部拆成三块：cl-lib 是基础层，cl-extra 放大而复杂的函数，
  cl-seq 放序列与列表操作，cl-macs 只在编译期需要（全是宏）。
  cl-print 是另一块：给调试器用的增强打印，第 48 章再讲。
  cl-lib.el 里已经写好了全部 autoload，所以用户只 require 它一个。
  旧入口 cl.el 在 obsolete 目录里：t
  （在 obsolete 目录里，加载它会打印 `Package cl is deprecated'，
   所以本书的示例一个都不 require 它。）
```

逐点读：

**`(require 'cl-lib)` 是唯一的入口。** `featurep` 返回 `t`，说明特性已经登记。你不需要分别 require `cl-extra`、`cl-seq`、`cl-macs`——`cl-lib.el` 里为这些文件里的每个函数都写了 autoload，第一次调用时自动加载。示例之所以把四个文件都列出来，是想让你知道**它们确实存在**，而不是一套单文件库。

**四个文件各有分工。** `cl-lib.el` 是基础层（`cl-defun`、`cl-block`、`cl-letf` 等核心宏和一批小函数）；`cl-extra.el` 放「大而复杂」的函数（`cl-union`、`cl-sort` 之类）；`cl-seq.el` 放序列与列表操作；`cl-macs.el` **只包含宏**，字节编译时展开完就不再需要它了。这也是为什么只用宏的包可以把 `require` 写进 `eval-when-compile`——运行期根本用不到 `cl-macs`。

**`cl-print` 不在那三块里。** 它是后来加的增强打印模块（`cl-prin1`、`cl-print-object`），给调试器和 `*Backtrace*` 用，第 48 章单独讲。

**`cl.el` 已经搬进 `obsolete/`。** `locate-library` 找到的路径里含 `/obsolete/`，说明它是「保留但不再推荐」的旧入口。实测 `(require 'cl)` 会向 stderr 打印一行 `Package cl is deprecated`。本书的示例一律不碰它——这不是洁癖：`run-all.sh` 要求 stderr 完全为空，加载旧库直接就把示例判失败了。

这里还有一个新手常问的问题：**能不能不用 `cl-lib`？** 可以，但要放弃 `cl-loop`、`cl-defstruct`、`cl-flet` 这些宏，用原生 `while`/`dolist`/`vector` 手写。第 6 节会给出取舍标准。

## 41.2 命名：为什么每个名字都带 `cl-` 前缀

Emacs Lisp 没有包系统，所有 interned 符号共享一个 obarray。为了避免和用户代码撞名，这套库给每个来自 Common Lisp 的名字都加了 `cl-` 前缀。示例第 2 节：

```elisp
(princ "\n== 2) 命名：为什么每个名字都带 cl- 前缀 ==\n")
(princ (format "  Emacs 31.1 里以 cl- 开头且有函数定义的符号：%d 个\n"
               (length (apropos-internal "^cl-[a-z]" #'fboundp))))
(princ "  规则只有一条：Common Lisp 里叫 FOO 的，这里叫 cl-FOO。\n")
(princ (format "  cl-first (1 2 3) = %S，和 car 一样：%S\n"
               (cl-first '(1 2 3)) (car '(1 2 3))))
(princ (format "  cl-rest  (1 2 3) = %S，和 cdr 一样：%S\n"
               (cl-rest '(1 2 3)) (cdr '(1 2 3))))
(princ (format "  cl-third (1 2 3) = %S，和 nth 2 一样：%S\n"
               (cl-third '(1 2 3)) (nth 2 '(1 2 3))))
(princ "  内部实现另有 cl-- 双横线前缀，那是私有约定，别在扩展里用。\n")
(princ "  只有五个名字不是从 Common Lisp 照搬的，是 Emacs 自己的扩展：\n")
(dolist (sym '(cl-callf cl-callf2 cl-defsubst cl-letf cl-letf*))
  (princ (format "    %-11s 有定义：%S\n" sym (fboundp sym))))
```

输出：

```
== 2) 命名：为什么每个名字都带 cl- 前缀 ==
  Emacs 31.1 里以 cl- 开头且有函数定义的符号：267 个
  规则只有一条：Common Lisp 里叫 FOO 的，这里叫 cl-FOO。
  cl-first (1 2 3) = 1，和 car 一样：1
  cl-rest  (1 2 3) = (2 3)，和 cdr 一样：(2 3)
  cl-third (1 2 3) = 3，和 nth 2 一样：3
  内部实现另有 cl-- 双横线前缀，那是私有约定，别在扩展里用。
  只有五个名字不是从 Common Lisp 照搬的，是 Emacs 自己的扩展：
    cl-callf    有定义：t
    cl-callf2   有定义：t
    cl-defsubst 有定义：t
    cl-letf     有定义：t
    cl-letf*    有定义：t
```

`apropos-internal` 的那个数字只是「此刻已加载的部分」有多大：本章只 require 了 `cl-lib`，还没触发 `cl-extra`/`cl-seq` 的 autoload，所以是 267；把后面的章节跑完，这个数字会变大。重要的不是数字，而是**前缀**。

**规则只有一条：CL 里叫 `foo`，这里叫 `cl-foo`。** `car`/`cdr` 本身就在 Emacs 里，所以 CL 的 `first`/`rest` 被映射成 `cl-first`/`cl-rest`。第三、第四……直到第十个元素则是 `cl-third`、`cl-fourth`……`cl-tenth`。

**内部实现用双横线 `cl--`。** 你在手册里会看到 `cl--gensym-counter` 之类的名字，那是私有变量，随时可能改；扩展代码里不要引用。

**只有五个名字不是 CL 原生。** 手册第 1.3 节明确列出：`cl-callf`、`cl-callf2`、`cl-defsubst`、`cl-letf`、`cl-letf*`。这五个是 Emacs 自己发明的「修改广义变量」和「内联函数」工具，CL 里没有对应物。记住这一点，读别人的 CL 代码时就不会去找它们的出处。

**别名不是包装。** 第 6 节会实测 `(symbol-function 'cl-first)`，它直接返回符号 `car`，也就是说 `cl-first` 就是一个指向 `car` 的别名，不额外绕一层函数调用。这解释了为什么用 `cl-first` 不会比 `car` 慢——但也说明了它**没有性能优势**，用它纯粹是风格选择。

## 41.3 同名不等于同义：三处最容易踩的语义差

加前缀只能避免撞名，避免不了**语义**不同。示例第 3 节挑了三处最常见的：

```elisp
(princ "\n== 3) 语义差异：同名不等于同义 ==\n")
(princ (format "  (cl-equalp 3 3.0) = %S（数字不看类型）\n" (cl-equalp 3 3.0)))
(princ (format "  (cl-equalp \"abc\" \"ABC\") = %S（字符串不分大小写）\n"
               (cl-equalp "abc" "ABC")))
(princ (format "  (equal \"abc\" \"ABC\") = %S（原生 equal 分大小写）\n"
               (equal "abc" "ABC")))
(princ "  cl-member / cl-assoc 默认用 eql；原生 member / assoc 用 equal。\n")
;; 注意：以下先把字符串绑进变量再传参。直接写字面量会触发 Emacs 31.1
;; 字节编译器警告：memql/assq called with literal string that may never match。
(let ((s "a")
      (sl '("a"))
      (al '(("a" . 1))))
  (princ (format "  (member    \"a\" '(\"a\")) = %S\n" (member s sl)))
  (princ (format "  (cl-member \"a\" '(\"a\")) = %S\n" (cl-member s sl)))
  (princ (format "  (cl-member \"a\" '(\"a\") :test #'equal) = %S\n"
                 (cl-member s sl :test #'equal)))
  (princ (format "  (assoc    \"a\" '((\"a\" . 1))) = %S\n" (assoc s al)))
  (princ (format "  (cl-assoc \"a\" '((\"a\" . 1))) = %S\n" (cl-assoc s al))))
(princ "  所以从 CL 抄来的 (member x list) 往往要先想清楚「用哪种相等」。\n")
(princ (format "  (cl-values 1 2) = %S，它就是 list 的别名\n" (cl-values 1 2)))
(princ "  Emacs Lisp 函数只能返回一个值，cl-lib 用列表模拟多值，不做真多值。\n")
```

输出：

```
== 3) 语义差异：同名不等于同义 ==
  (cl-equalp 3 3.0) = t（数字不看类型）
  (cl-equalp "abc" "ABC") = t（字符串不分大小写）
  (equal "abc" "ABC") = nil（原生 equal 分大小写）
  cl-member / cl-assoc 默认用 eql；原生 member / assoc 用 equal。
  (member    "a" '("a")) = ("a")
  (cl-member "a" '("a")) = nil
  (cl-member "a" '("a") :test #'equal) = ("a")
  (assoc    "a" '(("a" . 1))) = ("a" . 1)
  (cl-assoc "a" '(("a" . 1))) = nil
  所以从 CL 抄来的 (member x list) 往往要先想清楚「用哪种相等」。
  (cl-values 1 2) = (1 2)，它就是 list 的别名
  Emacs Lisp 函数只能返回一个值，cl-lib 用列表模拟多值，不做真多值。
```

**第一处：`cl-equalp`。** CL 的 `equalp` 是一个「宽松的 equal」：数字忽略整数/浮点之分（`3` 与 `3.0` 视为相等），字符串忽略大小写，向量和 cons 递归比较。`(cl-equalp 3 3.0)` 返回 `t`，`(cl-equalp "abc" "ABC")` 也返回 `t`。而 Emacs 原生的 `equal` 对字符串是**区分大小写**的，所以同一个比较会得到 `nil`。**什么时候用？** 比较用户输入、配置里手写的字符串、从别处解析来的数字时。**什么时候别用？** 哈希表键、`eq` 语义敏感的场合——`equalp` 可能让两个「你认为不同」的对象相等。

**第二处：`cl-member` / `cl-assoc` 的默认测试。** 这是最容易静默出错的地方。CL 的 `member` 默认用 `eql`，`cl-lib` 忠实照搬；而 Emacs 原生的 `member` 默认用 `equal`。对数字和符号，两者没差别；对**字符串**，差别立刻显现：

- `(member "a" '("a"))` → `("a")`，因为 `equal` 比较字符串内容；
- `(cl-member "a" '("a"))` → `nil`，因为 `eql` 只认同一个对象（字符串不是）。

要恢复原生行为，就显式写 `:test #'equal`，第三个结果 `("a")` 就是这么来的。`cl-assoc` 同理：`assoc` 找到 `("a" . 1)`，`cl-assoc` 找不到。

> 示例代码里为什么先把 `"a"`、`'("a")` 绑进 `let` 变量再传参？因为 `cl-member` 不带 `:test` 时展开为 `memql`、`cl-assoc` 展开为 `assq`，而 Emacs 31.1 的字节编译器看到**字面量字符串**直接喂给这两个函数，会发出 `called with literal string that may never match` 警告——这正是它替你提前发现了「eql 比字符串」的坑。绑进变量后编译器不再做字面量检查，运行行为完全一样。

> 顺带纠正一个常见误解：`(member 3.0 '(3))` 在 Emacs 里也是 `nil`，因为 `equal` 同样区分数值和浮点。真正的分水岭是字符串和向量，不是数字。

**第三处：多值。** `(cl-values 1 2)` 返回 `(1 2)`——它**就是 `list` 的别名**，不是真正的多值返回。手册第 5.8 节说得很直白：Emacs Lisp 函数只能返回一个对象，这套库用列表模拟多值，只要收发双方都遵守约定（用 `cl-multiple-value-bind` 接），行为就和 CL 一致；一旦一方用了 `cl-values`、另一方直接当普通列表用，语义就偏了。第 45 章会专门讲这套约定。

## 41.4 宏展开：可读的写法不等于慢

`cl-defun`、`cl-loop`、`cl-incf` 全都是**宏**，不是解释器里的特殊形式。宏在字节编译时展开成普通 Lisp；解释执行时则每次运行都要重新展开。示例第 4 节用 `cl-prettyexpand` 把展开结果打进一个 Lisp 模式 buffer：

```elisp
(princ "\n== 4) 宏展开：可读写法不等于慢 ==\n")
(princ "  cl-defun、cl-loop 这些全是宏，字节编译后展开成普通 Lisp。\n")
(with-temp-buffer
  (emacs-lisp-mode)
  (let ((inhibit-message t))
    (cl-prettyexpand '(cl-loop for x below 3 collect x)))
  (princ (format "  (cl-loop for x below 3 collect x) 展开成：\n%s"
                 (buffer-string))))
(with-temp-buffer
  (emacs-lisp-mode)
  (let ((inhibit-message t))
    (cl-prettyexpand '(cl-incf x 2)))
  (princ (format "  (cl-incf x 2) 展开成：\n%s" (buffer-string))))
(princ "  展开结果里只有 let*、while、setq、cons 这些原生操作，没有魔法。\n")
(princ "  解释执行时每次都要现展开，所以重度使用 cl-lib 的代码应当编译。\n")
```

输出：

```
== 4) 宏展开：可读写法不等于慢 ==
  cl-defun、cl-loop 这些全是宏，字节编译后展开成普通 Lisp。
  (cl-loop for x below 3 collect x) 展开成：

(let* ((x 0)
       (--cl-var-- nil))
  (while (< x 3)
    (setq --cl-var-- (cons x --cl-var--))
    (setq x (+ x 1)))
  (nreverse --cl-var--))
  (cl-incf x 2) 展开成：

(setq x (+ x 2))
  展开结果里只有 let*、while、setq、cons 这些原生操作，没有魔法。
  解释执行时每次都要现展开，所以重度使用 cl-lib 的代码应当编译。
```

三件事值得说清楚：

**`cl-prettyexpand` 会往当前 buffer 里插入格式化的展开结果**，所以必须先在 `emacs-lisp-mode` 的临时 buffer 里调用，否则缩进是乱的。它工作时会 `message` 出 `Expanding...`/`Formatting...`，在批处理里这些会走 stderr；示例用 `(let ((inhibit-message t)) ...)` 把它们压掉，这样 `run-all.sh` 的「stderr 必须为空」才过得去。你在 `*scratch*` 里手玩时不需要这个绑定。

**`cl-loop` 展开成了一个「先倒序 cons、最后 nreverse」的 `while`。** 这就是它比手写循环好读、但不比手写循环慢的原因：编译之后只剩原生操作。临时变量 `--cl-var--` 是宏展开时生成的、不会和你的变量撞名。

**`cl-incf` 展开成一次 `setq`。** 它先求值一次 place、再加、再写回；对 `x` 这种简单变量就是 `(setq x (+ x 2))`。第 44 章会看到它对复杂 place（比如 `(aref v i)`）展开成什么样的「求值一次」保护。

由此得到一条实践规则：**大量使用 `cl-lib` 的文件一定要字节编译**。解释执行时每个 `cl-loop`、每个 `cl-incf` 都要现场展开、生成代码、执行、再把生成的代码丢掉，既慢又费 GC。

## 41.5 移植清单：CL 代码不能直接跑的地方

手册附录 C 列了一长串「Emacs Lisp 与 Common Lisp 的结构性差异」。示例第 5 节把其中**会在读入阶段就炸**的几条挑出来实测：

```elisp
(princ "\n== 5) 移植清单：CL 代码不能直接跑的地方 ==\n")
(princ (format "  大小写：'foo 与 'FOO 是不同符号：%S\n" (eq 'foo 'FOO)))
(princ (format "  CL 的向量字面量 #(a b)：%S\n"
               (condition-case err (read "#(a b)")
                 (error (error-message-string err)))))
(princ (format "  Emacs 的向量字面量 [a b]：%S\n" (read "[a b]")))
(princ (format "  CL 的字符 #\\A 在 Emacs 里读成：%S\n"
               (condition-case err (read "#\\A")
                 (error (error-message-string err)))))
(princ (format "  Emacs 的字符 ?A 是整数：%S\n" (read "?A")))
(princ (format "  CL 的有理数 1/2 在这里是符号：%S\n" (symbolp (read "1/2"))))
(princ "  另外还有四处结构性差异，写代码时躲不开：\n")
(princ "    - format：CL 是 (format t \"~a\" x)，Emacs 是 (format \"%s\" x)\n")
(princ "    - 包系统：Emacs 只有一个 obarray，靠 cl- 这种前缀分组\n")
(princ "    - 词法作用域：必须文件头写 lexical-binding: t，否则退回动态作用域\n")
(princ "    - 面向对象：没有 CLOS，对应物是 EIEIO（eieio 包）\n")
```

输出：

```
== 5) 移植清单：CL 代码不能直接跑的地方 ==
  大小写：'foo 与 'FOO 是不同符号：nil
  CL 的向量字面量 #(a b)："Invalid read syntax: \"#\""
  Emacs 的向量字面量 [a b]：[a b]
  CL 的字符 #\A 在 Emacs 里读成："Invalid read syntax: \"#\\\\\""
  Emacs 的字符 ?A 是整数：65
  CL 的有理数 1/2 在这里是符号：t
  另外还有四处结构性差异，写代码时躲不开：
    - format：CL 是 (format t "~a" x)，Emacs 是 (format "%s" x)
    - 包系统：Emacs 只有一个 obarray，靠 cl- 这种前缀分组
    - 词法作用域：必须文件头写 lexical-binding: t，否则退回动态作用域
    - 面向对象：没有 CLOS，对应物是 EIEIO（eieio 包）
```

逐条解释：

**大小写。** Common Lisp 的符号默认大小写不敏感，`foo`、`Foo`、`FOO` 是同一个；读入时通常还会被转成大写。Emacs Lisp 的符号**大小写敏感**，三个是不同的符号，`(eq 'foo 'FOO)` 为 `nil`。从 CL 移植全大写的代码时，至少要把所有调用的内置函数名改成小写，否则 `(DEFUN FOO ...)` 会试图调用一个叫 `DEFUN` 的符号。

**向量字面量。** CL 写 `#(a b)`，Emacs 写 `[a b]`。更麻烦的是，Emacs 的 `#(` 是**另一种语法**：带文本属性的字符串（第 40 章讲过 `#("hello" 0 5 (face bold))`）。所以 `#(a b)` 在 Emacs 里不是「向量」，而是「以 `a` 开头的属性字符串」，`a` 不是字符串，读入器直接报 `Invalid read syntax: "#"`。

**字符。** CL 写 `#\A`，Emacs 写 `?A`。Emacs 的 `?A` 读出来就是整数 65——Emacs 没有独立的字符类型，字符就是整数。`#\A` 在 Emacs 里同样撞上 `#` 语法，报 `Invalid read syntax: "#\\"`（错误信息里的反斜杠被转义显示成了 `\\`）。

**有理数。** CL 的 `1/2` 是有理数；Emacs 没有有理数类型，`1/2` 被读成一个**名字叫 `1/2` 的符号**。同理，CL 的复数、大整数（bignum 另说）也没有对应物。

**`format`。** CL 的 `format` 第一个参数是「目的地」（`t` 表示终端、`nil` 表示返回字符串），控制符用 `~`；Emacs 的 `format` 没有目的地参数，控制符用 `%`。这是移植时改动量最大的一处，而且改错了不会报错，只会打出奇怪的东西。

**包系统。** CL 的 `package:symbol` 在 Emacs 里只是一个名字里带冒号的普通符号；`cl-lib` 靠 `cl-` 前缀分区，而不是真正的包。

**词法作用域。** Emacs 24.1 起支持词法绑定，但**默认不是**——必须在文件第一行写 `;;; -*- lexical-binding: t; -*-`。不写的话，闭包捕获不到外层变量，CL 风格的 `lambda` 全都会出错。本书所有示例的第一行都是这一行。

**面向对象。** CLOS 没有实现；Emacs 自带的 EIEIO 提供了类似的功能，但 API 不同，不能直接照搬 `defclass`/`defgeneric`。

## 41.6 什么时候该用，什么时候不该用

示例第 6 节收尾：

```elisp
(princ "\n== 6) 什么时候该用，什么时候不该用 ==\n")
(princ "  该用：cl-loop、cl-defstruct、cl-flet、cl-letf、cl-incf 这类\n")
(princ "        让代码短一截、又能在编译期完全消解的写法。\n")
(princ "  不该用：为了「像 Common Lisp」而把 car 写成 cl-first、\n")
(princ "        把 mapcar 写成 cl-mapcar——原生写法读的人更熟，还少一层展开。\n")
(princ (format "  实证：(symbol-function 'cl-first) = %S（别名直接指向 car）\n"
               (symbol-function 'cl-first)))
(princ "  它只是给习惯 CL 的人看的别名，不是「更快的 car」。\n")
```

输出：

```
== 6) 什么时候该用，什么时候不该用 ==
  该用：cl-loop、cl-defstruct、cl-flet、cl-letf、cl-incf 这类
        让代码短一截、又能在编译期完全消解的写法。
  不该用：为了「像 Common Lisp」而把 car 写成 cl-first、
        把 mapcar 写成 cl-mapcar——原生写法读的人更熟，还少一层展开。
  实证：(symbol-function 'cl-first) = car（别名直接指向 car）
  它只是给习惯 CL 的人看的别名，不是「更快的 car」。
```

`(symbol-function 'cl-first)` 返回的是**符号 `car` 本身**，不是一个新的函数对象。这说明 `cl-first` 只是 `defalias` 出来的别名：调用它和调用 `car` 完全一样，没有任何性能收益，也没有任何性能损失。

所以取舍标准是**可读性**，不是性能：

| 场景 | 建议 |
|---|---|
| `cl-loop`、`cl-defstruct`、`cl-flet`、`cl-letf`、`cl-incf` | 用。它们把多行样板压成一行，展开后仍是原生代码 |
| `car` → `cl-first`、`mapcar` → `cl-mapcar` | 不用。原生名字更短、更常见，别名只是多一层阅读障碍 |
| 序列操作（`cl-remove-if`、`cl-find-if`、`cl-sort`） | 用。原生 Emacs 没有等价物，手写要十几行 |
| 集合运算（`cl-union`、`cl-intersection`） | 用。同上 |
| 多值（`cl-values`/`cl-multiple-value-bind`） | 谨慎。只在收发双方都遵守约定时用；对外 API 直接返回列表更清楚 |

## 41.7 小结

| 主题 | 结论 |
|---|---|
| 加载 | 只需 `(require 'cl-lib)`；内部拆成 `cl-lib`/`cl-extra`/`cl-seq`/`cl-macs`，autoload 已配好 |
| 旧入口 | `cl.el` 在 `obsolete/`，加载会打印 deprecation 警告，新代码不要用 |
| 命名 | CL 的 `foo` → `cl-foo`；内部私有名字用 `cl--` |
| 非 CL 原生 | `cl-callf`、`cl-callf2`、`cl-defsubst`、`cl-letf`、`cl-letf*` 五个 |
| `cl-equalp` | 数字忽略类型、字符串忽略大小写、结构递归比较 |
| `cl-member`/`cl-assoc` | 默认 `eql`，与原生 `member`/`assoc` 的 `equal` 不同；字符串比较要显式 `:test #'equal` |
| 多值 | 用列表模拟，`cl-values` 就是 `list` 的别名 |
| 性能 | 宏在编译期完全展开；重度使用务必字节编译 |
| 移植 | 大小写敏感、`[a b]` 而非 `#(a b)`、`?A` 而非 `#\A`、`%` 而非 `~`、必须 `lexical-binding: t` |

下一章开始进入手册正文：先讲**参数列表**。`cl-defun` 能表达 `&optional` 的默认值与「是否传了」、`&key` 的别名与重复键、`&aux` 的局部变量、以及参数解构——这些是后面所有章节的地基。

上一章：[40 · 读取与打印：read、prin1、princ 与那一堆 print-* 开关](40-reading-printing.md)　｜　下一章：[42 · 参数列表：cl-defun、cl-defmacro 与 &key](42-argument-lists.md)　｜　返回：[Emacs 扩展开发指南](README.md)
