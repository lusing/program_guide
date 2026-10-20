;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 42 - 参数列表：cl-defun、cl-defmacro 与 &key
;;;   普通 defun 的参数列表只有 &optional 和 &rest。cl-defun 把它
;;;   扩成 Common Lisp 那一套：带默认值的可选参数、记录「是否传了」
;;;   的变量、关键字参数的别名、&aux 局部变量、以及参数解构。
;;;   本章把每个符号都跑一遍，并说明它们展开后到底变成了什么。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "42-argument-lists.el")'
;;; 运行：emacs -Q --batch -l 42-argument-lists.el
;;; ============================================================
(require 'cl-lib)

;;; ---------- 1) cl-defun：defun 加一个隐式 block ----------
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

;;; ---------- 2) &optional：默认值与「是否传入」 ----------
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

;;; ---------- 3) 默认值可以引用前面的参数 ----------
(princ "\n== 3) 默认值可以引用前面的参数 ==\n")
(princ "  上一节 (b (* a 10)) 里的 a 就是从左边已经绑定好的参数，\n")
(princ "  默认值按从左到右的顺序求值，能看见所有更靠左的参数。\n")
(cl-defun box-volume (&optional (w 1) (h w) (d (* w h)))
  (list w h d))
(princ (format "  (box-volume)          = %S\n" (box-volume)))
(princ (format "  (box-volume 2)        = %S\n" (box-volume 2)))
(princ (format "  (box-volume 2 3)      = %S\n" (box-volume 2 3)))
(princ "  h 的默认值是 w，d 的默认值是 (* w h)：三层依赖，一次调用就串起来。\n")

;;; ---------- 4) &rest 与点对参数列表 ----------
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

;;; ---------- 5) &key：默认关键字 ----------
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

;;; ---------- 6) &key 的别名：换一个关键字名 ----------
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

;;; ---------- 7) 重复关键字与未知关键字 ----------
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

;;; ---------- 8) &rest 与 &key 并存 ----------
(princ "\n== 8) &rest 与 &key 并存 ==\n")
(cl-defun both (&rest rest &key a b)
  (list a b rest))
(princ "  &rest 与 &key 同时出现时，&rest 拿到的是原始的关键字序列，\n")
(princ "  而 a、b 是从同一串序列里解析出来的——两者不是二选一。\n")
(princ (format "  (both :a 1 :b 2) = %S\n" (both :a 1 :b 2)))
(princ "  这让函数可以「先按关键字取值，再把整串转交给别人」，\n")
(princ "  典型用法是包装函数：自己认一部分键，剩下的原样传下去。\n")

;;; ---------- 9) &aux：顺带绑定的局部变量 ----------
(princ "\n== 9) &aux：顺带绑定的局部变量 ==\n")
(cl-defun rect (w h &aux (area (* w h)) (kind (if (= w h) 'square 'rect)))
  (list w h area kind))
(princ "  &aux 后面是普通 let 绑定：不占实参位置，也拿不到「是否传入」。\n")
(princ (format "  (rect 3 4) = %S\n" (rect 3 4)))
(princ (format "  (rect 4 4) = %S\n" (rect 4 4)))
(princ "  &aux 变量在函数体开头就已绑定，可以省掉一层 let。\n")

;;; ---------- 10) 解构参数与 &whole ----------
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

;;; ---------- 11) cl-defmacro：&body 与 &environment ----------
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

;;; ---------- 12) cl-defsubst 与 cl-function ----------
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

(princ "==== 42 结束 ====\n")
