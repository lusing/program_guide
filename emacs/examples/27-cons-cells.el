;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 27 - cons 单元与列表的内存模型
;;;   盒图、共享结构、setcar/setcdr、符号抽屉柜
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "27-cons-cells.el")'
;;; 运行：emacs -Q --batch -l 27-cons-cells.el
;;; ============================================================

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

;;; 2) 列表是一条以 nil 收尾的 cons 链。
;;;    (list 1 2 3) 与 (cons 1 (cons 2 (cons 3 nil))) 是同一个东西。
(princ "\n列表是一条以 nil 收尾的链：\n")
(princ "    +---+---+    +---+---+    +---+---+\n")
(princ "    | 1 | *-+--> | 2 | *-+--> | 3 |nil|\n")
(princ "    +---+---+    +---+---+    +---+---+\n\n")
(princ (format "手工搭出来 = %S\n" (cons 1 (cons 2 (cons 3 nil)))))
(princ (format "list 搭出来 = %S\n" (list 1 2 3)))
(princ (format "两者 equal  = %S\n" (equal (cons 1 (cons 2 (cons 3 nil))) (list 1 2 3))))

;;; 3) 一层一层剥：cdr 一直走到 nil，就说明到尾巴了。
(let ((lst (list 'a 'b 'c)))
  (princ (format "起点   : %S\n" lst))
  (princ (format "cdr    : %S\n" (cdr lst)))
  (princ (format "cddr   : %S\n" (cddr lst)))
  (princ (format "cdddr  : %S   <- 空表 nil，链条到头的标志\n" (cdddr lst)))
  (princ (format "caddr  : %S   <- 等价于 (car (cdr (cdr x)))\n" (caddr lst))))

;;; 4) setcar / setcdr 就地改格子（破坏性）。
;;;    先看 setcar：把链表的第一个 car 换掉。
(let ((lst (list 1 2 3)))
  (setcar lst 'one)
  (princ (format "\nsetcar 之后       : %S\n" lst)))

;;; 5) setcdr 把 cdr 指向另一条链 —— 这就是「拼接」的底层动作。
(let ((lst (list 1 2 3))
      (tail (list 'x 'y)))
  (setcdr lst tail)
  (princ (format "setcdr 接上尾巴   : %S\n" lst)))

;;; 6) setcdr 也可以指向一个非列表，结果就是点对（不正规列表）。
(let ((p (cons 1 2)))
  (setcdr p 3)
  (princ (format "setcdr 指向数字   : %S\n" p)))

;;; 7) 【坑】共享结构：两个列表指向同一个子链，改一个另一个也变。
(let* ((common (list 'a 'b))
       (one (list 1 common))
       (two (list 2 common)))
  (setcar common 'shared)
  (princ (format "\n共享子链改之前 one/two 都指同一个对象\n"))
  (princ (format "one = %S\n" one))
  (princ (format "two = %S   <- common 被改，两个都跟着变\n" two)))

;;; 8) eq 判断的是「是不是同一个对象」，equal 判断的是「长得一样」。
(let ((x (list 1 2))
      (y (list 1 2)))
  (princ (format "\n两份内容相同的列表：eq = %S，equal = %S\n"
                 (eq x y) (equal x y))))
(let* ((x (list 1 2))
       (y x))
  (princ (format "同一份对象：eq = %S，equal = %S\n" (eq x y) (equal x y))))

;;; 9) 符号是一组抽屉柜：名字上挂着「值格」「函数格」「属性表」。
;;;    这是 Elisp 最独特的设计，也是「同名变量与函数互不干扰」的原因。
(defvar demo-drawer 'initial-value)
(defun demo-drawer-fn (x) (* x 2))
(put 'demo-drawer 'color 'blue)
(put 'demo-drawer 'size 3)

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

(princ "==== 27 结束 ====\n")
