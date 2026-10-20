;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 41 - cl-lib 是什么：来历、加载、命名与移植
;;;   本章不教某个具体函数，而是先把「cl-lib 这套东西到底该怎么用」
;;;   讲清楚：它从哪来、怎么加载、命名怎么读、与 Common Lisp 的
;;;   哪些地方不一样——这些差异决定了你从别处抄来的 CL 代码
;;;   能不能直接跑。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "41-cl-lib-overview.el")'
;;; 运行：emacs -Q --batch -l 41-cl-lib-overview.el
;;; ============================================================
(require 'cl-lib)

;;; ---------- 1) 加载：一个 require，四个文件 ----------
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

;;; ---------- 2) 命名：为什么每个名字都带 cl- 前缀 ----------
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

;;; ---------- 3) 语义差异：同名不等于同义 ----------
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

;;; ---------- 4) 宏展开：可读写法不等于慢 ----------
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

;;; ---------- 5) 移植清单：CL 代码不能直接跑的地方 ----------
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

;;; ---------- 6) 什么时候该用，什么时候不该用 ----------
(princ "\n== 6) 什么时候该用，什么时候不该用 ==\n")
(princ "  该用：cl-loop、cl-defstruct、cl-flet、cl-letf、cl-incf 这类\n")
(princ "        让代码短一截、又能在编译期完全消解的写法。\n")
(princ "  不该用：为了「像 Common Lisp」而把 car 写成 cl-first、\n")
(princ "        把 mapcar 写成 cl-mapcar——原生写法读的人更熟，还少一层展开。\n")
(princ (format "  实证：(symbol-function 'cl-first) = %S（别名直接指向 car）\n"
               (symbol-function 'cl-first)))
(princ "  它只是给习惯 CL 的人看的别名，不是「更快的 car」。\n")
(princ "  本书后面八章按「参数列表 → 广义变量 → 作用域 → 控制流 →\n")
(princ "  循环 → 序列 → 列表 → 类型与结构」的顺序，把手册里真正会用到\n")
(princ "  的部分逐个实测讲透。\n")

(princ "==== 41 结束 ====\n")
