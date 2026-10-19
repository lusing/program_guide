;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 28 - 递归：让函数调用自己
;;;   基本情况、推迟求值、三种经典模式、深递归的边界
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "28-recursion.el")'
;;; 运行：emacs -Q --batch -l 28-recursion.el
;;; ============================================================

;;; ---------- 1) 最小形状：数一数列表里有几个元素 ----------
;;; 基本情况：空表里没有元素，答案是 0。
;;; 递归情况：非空表的元素数 = 1 + 剩下那条链的元素数。
(defun my-count-elements (lst)
  "递归数出 LST 的元素个数。"
  (if (null lst)
      0
    (+ 1 (my-count-elements (cdr lst)))))

(princ "== 1) 递归数元素 ==\n")
(princ (format "my-count-elements '(a b c d) = %S\n" (my-count-elements '(a b c d))))
(princ (format "my-count-elements nil         = %S\n" (my-count-elements nil)))

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

(princ "\n== 2) 递归的展开顺序 ==\n")
(princ (format "结果 = %S\n" (my-count-traced '(a b))))

;;; ---------- 3) 推迟求值的经典例子：阶乘 ----------
;;; (* n (my-factorial (1- n))) 里那个乘法，要等递归回来才做。
(defun my-factorial (n)
  "阶乘：(my-factorial 4) = 4*3*2*1。"
  (if (= n 0)
      1
    (* n (my-factorial (1- n)))))

(princ "\n== 3) 阶乘 ==\n")
(princ (format "4! = %S\n" (my-factorial 4)))
(princ (format "6! = %S\n" (my-factorial 6)))
;;;    递归的「形状」可以让程序自己打印出来：不去算乘法，而是把**要算的那个
;;;    表达式**构造出来 —— 一眼就能看出乘法是被推迟到「回来」之后才做的。
(defun my-factorial-shape (n)
  "返回 (my-factorial N) 真正会展开成的那个嵌套表达式。"
  (if (= n 0)
      1
    (list '* n (my-factorial-shape (1- n)))))
(princ (format "4! 展开成: %S\n" (my-factorial-shape 4)))

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

(princ "\n== 4) 循环 vs 递归 ==\n")
(princ (format "循环版 1..10  = %S\n" (my-triangle-loop 10)))
(princ (format "递归版 1..10  = %S\n" (my-triangle-recursive 10)))

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

(princ "\n== 5) every 模式 ==\n")
(princ (format "全是偶数？%S\n" (my-every #'my-evenp '(2 4 6 8))))
(princ (format "全是偶数？%S\n" (my-every #'my-evenp '(2 4 5 8))))

;;; ---------- 6) 模式二：accumulate —— 把每个元素加工后收集起来 ----------
(defun my-accumulate (fn lst)
  "对 LST 中每个元素调用 FN，把结果 cons 成一串返回。"
  (if (null lst)
      nil
    (cons (funcall fn (car lst))
          (my-accumulate fn (cdr lst)))))

(princ "\n== 6) accumulate 模式 ==\n")
(princ (format "每个数平方：%S\n" (my-accumulate (lambda (x) (* x x)) '(1 2 3 4))))

;;; ---------- 7) 模式三：keep —— 过滤 ----------
(defun my-keep (pred lst)
  "只保留 LST 中满足 PRED 的元素，保持原顺序。"
  (if (null lst)
      nil
    (let ((rest (my-keep pred (cdr lst))))
      (if (funcall pred (car lst))
          (cons (car lst) rest)
        rest))))

(princ "\n== 7) keep 模式 ==\n")
(princ (format "只留正数：%S\n" (my-keep (lambda (x) (> x 0)) '(-3 1 -7 2 9))))

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

(princ "\n== 8) 递归处理一棵树 ==\n")
(princ (format "my-sum-tree '(1 (2 (3 4)) 5) = %S\n"
               (my-sum-tree '(1 (2 (3 4)) 5))))
(princ (format "同一棵树换个写法 '(1 2 (3 (4 5)) 6) = %S\n"
               (my-sum-tree '(1 2 (3 (4 5)) 6))))

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
;;;    需要更深时可以临时抬高这个上限 —— 实测：5000 个元素在默认上限下被拦，
;;;    抬到 100000 之后就能跑完。但真正的深递归即使抬了上限也很慢（每层都要
;;;    分配栈帧），工程上不如直接换成循环。
(princ (format "默认上限下 5000 个元素: %S\n"
               (condition-case err
                   (my-count-elements (make-list 5000 'x))
                 (error (car err)))))
(princ (format "把上限抬到 100000 之后: %S\n"
               (let ((max-lisp-eval-depth 100000))
                 (condition-case err
                     (my-count-elements (make-list 5000 'x))
                   (error (car err))))))

(princ "==== 28 结束 ====\n")
