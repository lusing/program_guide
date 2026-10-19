;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 05 - 控制流：if / when / unless / cond / progn / while / dolist / dotimes
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "05-control-flow.el")'
;;; 运行：emacs -Q --batch -l 05-control-flow.el
;;; ============================================================

;;; 1) if：两分支。只有一个分支时用 when / unless，可读性更好。
(defun demo-sign (n)
  "返回 N 的符号描述。"
  (if (> n 0) "正" (if (< n 0) "负" "零")))
(princ (format "sign: %S / %S / %S\n" (demo-sign 5) (demo-sign -5) (demo-sign 0)))

;;; 2) cond：多分支，每个子句是 (条件  body...)，命中第一个为真者。
;;;    末尾写 (t 默认分支) 是惯例。
(defun demo-grade (score)
  "把 SCORE 转成等级。"
  (cond
   ((>= score 90) "A")
   ((>= score 60) "B")
   (t "C")))
(princ (format "grade: %S / %S / %S\n" (demo-grade 95) (demo-grade 70) (demo-grade 30)))

;;; 3) 【坑】if 的 then 只能有一个表达式。要塞多句就用 progn（或 when/unless）。
;;;    progn 返回最后一句的值。
(princ (format "progn: %S\n"
               (if t (progn (princ "  (then 分支执行了)\n") "progn 的返回值") "不会到这")))

;;; 4) when / unless 本身就是「带 progn 的 if」，不用自己包 progn
(let (log)
  (when (stringp "x") (setq log (cons "when 命中" log)))
  (unless (integerp "x") (setq log (cons "unless 命中" log)))
  (princ (format "when/unless: %S\n" (nreverse log))))

;;; 5) and / or 的短路特性常被当作控制流用：
;;;    and 一路求值到第一个 nil；or 一路求值到第一个非 nil。
(princ (format "(or nil 0 \"\" 'fallback) = %S\n" (or nil 0 "" 'fallback)))
(princ (format "(and 1 2 nil 3) = %S\n" (and 1 2 nil 3)))

;;; 5b) or 给默认值是它最常见的用途。但这里有个陷阱：Elisp 里只有 nil 是假，
;;;     所以 0 和 "" 都是真，它们会「冒充」已设置的值，把默认值顶掉。
(defun demo-greeting (name)
  "用 NAME 打招呼；NAME 为 nil 时退回默认称呼。"
  (format "你好，%s！" (or name "世界")))
(princ (format "or 默认值: %S / %S\n" (demo-greeting "小明") (demo-greeting nil)))
(princ (format "   传空字符串: %S（空串是真，所以它没被默认值替换）\n" (demo-greeting "")))

;;; 6) while 循环。没有 for，要计数器就自己 setq。
(let ((i 0) (acc 0))
  (while (< i 5)
    (setq acc (+ acc i)
          i (1+ i)))
  (princ (format "while: 0+1+2+3+4 = %S\n" acc)))

;;; 7) dotimes / dolist：最常见的两种遍历。
;;;    dotimes 的第三个位置是「返回值表达式」，循环结束后才求值。
(princ (format "dotimes 累加: %S\n"
               (let ((acc 0))
                 (dotimes (i 5)
                   (setq acc (+ acc i)))
                 acc)))

;;; 【坑】dotimes 的返回值表达式外面还包了一层 (let ((i counter)) ...)，
;;;    所以如果结果表达式里**没有**用到 i，字节编译器会报
;;;    "Unused lexical variable i"。要么别写结果表达式，要么让它用到 i。
(princ (format "dotimes 结果式: %S\n"
               (dotimes (i 3 (format "循环结束时 i = %d" i))
                 (princ (format "  遍历 i=%d\n" i)))))

(let ((total 0))
  (dolist (x '(10 20 30))
    (setq total (+ total x)))
  (princ (format "dolist 累加: %S\n" total)))

;;; 8) 【坑】dolist / dotimes 的循环变量是「词法绑定」还是「动态绑定」？
;;;    在 lexical-binding: t 的文件里是词法绑定，闭包每次拿到各自的值；
;;;    没有 lexical-binding 时是动态的，所有闭包会共享最后一个值 —— 经典陷阱。
(princ (format "dolist + 闭包: %S\n"
               (let ((fns nil))
                 (dolist (x '(1 2 3))
                   (push (lambda () x) fns))
                 (mapcar #'funcall (nreverse fns)))))

;;; 9) cl-case（cl-lib）：值的集合分派比 cond 紧凑，用 eql 比较。
;;;    字符串不能用 cl-case 分派（eql 比地址），字符串要用 pcase。
(require 'cl-lib)
(defun demo-size (kind)
  "按 KIND 返回尺码描述。"
  (cl-case kind
    ((1 2 3) "小数字")
    ((10 20) "整十")
    (t "其它")))
(princ (format "cl-case: %S / %S / %S\n"
               (demo-size 2) (demo-size 10) (demo-size 99)))

;;; 10) pcase：模式匹配。比 cond 更强的「按形状分派」。
;;;     坑：第一个子句若是裸符号（匹配一切），后面的子句全是死代码，
;;;     Emacs 31 会报 "pcase pattern X shadowed by previous pcase pattern"。
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

;;; 11) pcase-let：用模式解构绑定，比 cl-destructuring-bind 更常见
(princ (format "pcase-let: %S\n"
               (pcase-let ((`(,x ,y) (list 3 4)))
                 (+ x y))))

;;; 12) cond*（Emacs 31 新增）：cond 的扩展版，子句可以携带绑定。
;;;     规则（都很特别，逐条实测过）：
;;;     - 首元素是普通表达式的子句 = 「退出子句」，为真就带着 body 的值退出；
;;;     - 首元素是 (bind* VAR VAL ...) 的子句 = 「非退出子句」：
;;;       绑定对后续所有子句可见，第一个绑定值非 nil 时 body 才跑，然后继续往下走；
;;;     - 首元素是 t 的子句同样是非退出的 —— 所以 cond* 里没有传统 cond 的 (t ...) else。
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
;;; 13) 「裸符号打头」警告的修好版本：(and (pred ...) VAR) 组合模式，
;;;     每个子句只匹配一类值，兜底 _ 放最后，零警告。
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

(princ "==== 05 结束 ====\n")
