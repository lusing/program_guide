;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 04 - 函数：defun、&optional、&rest、lambda、funcall / apply、#'
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "04-functions.el")'
;;; 运行：emacs -Q --batch -l 04-functions.el
;;; ============================================================

;;; 1) 基本定义。docstring 一定要写：C-h f、eldoc、checkdoc 都读它。
;;;    约定：第一行一句话说完，且不超过 80 列。
(defun demo-square (n)
  "返回 N 的平方。"
  (* n n))
(princ (format "square(7) = %S\n" (demo-square 7)))

;;; 2) &optional 可选参数。调用时省略则为 nil，判 nil 再给默认值。
(defun demo-greet (name &optional greeting)
  "用 GREETING（默认 \"Hello\"）问候 NAME。"
  (format "%s, %s!" (or greeting "Hello") name))
(princ (format "%S / %S\n" (demo-greet "Emacs") (demo-greet "Emacs" "你好")))

;;; 3) &rest 收拢剩余参数为列表。apply 是它的天然搭档。
(defun demo-sum (&rest numbers)
  "返回 NUMBERS 的和。"
  (apply #'+ numbers))
(princ (format "sum(1 2 3 4) = %S，sum() = %S\n" (demo-sum 1 2 3 4) (demo-sum)))

;;; 4) 没有多返回值。要返回多个就返回 list 或 cons，再用 let + 解构取值。
(defun demo-divmod (a b)
  "返回 (商 . 余)。"
  (cons (/ a b) (mod a b)))
(princ (format "divmod(17 5) = %S\n" (demo-divmod 17 5)))

;;; 5) lambda 与 funcall / apply。
;;;    funcall 逐个传参，apply 最后一个参数必须是列表（会被展开）。
(princ (format "funcall: %S\n" (funcall (lambda (x) (* x 2)) 21)))
(princ (format "apply:   %S\n" (apply #'max '(3 9 2))))
(princ (format "apply 混着传: %S\n" (apply #'list 1 2 '(3 4))))

;;; 6) 【坑】#' 和 ' 在 lambda 上差别巨大：
;;;    #' 提示字节编译器「这是个函数，请编译它」；' 只会留一个裸列表，
;;;    字节编译时不会编译、也不会检查，还容易被当成 quote 优化掉。
;;;    凡是「把函数当值传」的地方，一律写 #'。
(princ (format "mapcar + #': %S\n" (mapcar #'demo-square '(1 2 3 4))))

;;; 7) 函数也能「存」进变量和数据结构，实现简单的分派表
(defvar demo-ops (list (cons "+" #'+) (cons "*" #'*)))
(princ (format "分派表: %S\n"
               (mapcar (lambda (cell) (funcall (cdr cell) 6 7)) demo-ops)))

;;; 8) 内置高阶函数：mapcar / mapc（只要副作用）/ funcall / apply-partially
(princ (format "apply-partially: %S\n"
               (funcall (apply-partially #'* 10) 5)))

;;; 9) defalias：给函数起别名；declare 提供编译器元信息
(defalias 'demo-sq #'demo-square)
(princ (format "defalias 别名: %S, functionp = %S\n"
               (demo-sq 9) (functionp #'demo-square)))

(princ "==== 04 结束 ====\n")
