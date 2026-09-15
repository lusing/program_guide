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

;;; 9) cl-case 需要 cl-lib，比 cond 更紧凑；见 09-sequences.el
(princ (format "cond 也能做同样的事: %S\n"
               (let ((k 'b))
                 (cond ((eq k 'a) "A") ((eq k 'b) "B") (t "?")))))

(princ "==== 05 结束 ====\n")
