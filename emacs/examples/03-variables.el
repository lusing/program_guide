;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 03 - 变量：setq / defvar / let / let*、动态作用域、buffer-local
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "03-variables.el")'
;;; 运行：emacs -Q --batch -l 03-variables.el
;;; ============================================================

;;; 1) setq 做赋值（可同时赋多个），setq 赋给「已存在的变量」。
;;;    本文件开了 lexical-binding，直接用 setq 建全局变量会让字节编译器报
;;;    「reference to free variable」，所以顶层变量一律先 defvar。
(defvar demo-counter 0)
(setq demo-counter 10)
(princ (format "setq 之后：demo-counter = %S\n" demo-counter))

;;; 2) 【坑】defvar 只在变量「还没有值」时赋初值。
;;;    重复求值 defvar 不会覆盖已有值 —— 这正是「用户配置不该被重新加载覆盖」的基础。
(defvar demo-counter 999)          ; 不会生效，上一行的 10 还在
(princ (format "再次 defvar 999 之后：demo-counter = %S\n" demo-counter))

;;; 3) let 建局部绑定；let* 的后续初值能看到前面的绑定。
;;;    本文件是词法绑定（首行 lexical-binding: t），let 产生的是**词法**绑定。
(princ (format "let: %S\n" (let ((a 1) (b 2)) (+ a b))))
(princ (format "let*: %S\n" (let* ((a 10) (b (* a 2))) b)))
;;;    用 let 写 (let ((a 10) (b (* a 2))) ...) 会报 void-variable a：
;;;    let 先把所有初值求值完，再统一绑定，此时 a 还没绑上。

;;; 4) 变量遮蔽：内层 let 挡住外层，出了 let 恢复
(princ (format "遮蔽：%S\n"
               (let ((x "外层"))
                 (list x (let ((x "内层")) x) x))))

;;; 5) 【关键区别】被 defvar 声明过的变量是「special」，let 对它做的是
;;;    **动态绑定**：临时值在函数内部也看得见。这是 Emacs 扩展里
;;;    「让函数临时改变行为」的标准手法（见 13-interactive.el 的 inhibit-read-only）。
(defvar demo-greeting "hello")
(defun demo-say () (concat demo-greeting " world"))
(princ (format "平常：%S\n" (demo-say)))
(princ (format "let 动态绑定后：%S\n" (let ((demo-greeting "hi")) (demo-say))))
(princ (format "出了 let：%S\n" (demo-say)))

;;; 6) 没被 defvar 的变量是词法绑定：lambda 捕获的是「当时的值」，形成闭包
(defun demo-make-adder (n) (lambda (x) (+ x n)))
(princ (format "闭包：(adder 10) 5 = %S, (adder 3) 4 = %S\n"
               (funcall (demo-make-adder 10) 5)
               (funcall (demo-make-adder 3) 4)))

;;; 7) 【坑】setq-default / setq-local 与 buffer-local 变量。
;;;    defvar-local 声明的变量，每个 buffer 各有一份；setq 改的是「当前 buffer 那份」，
;;;    setq-default 改的是「新 buffer 的默认值」，两者互不影响。
(defvar-local demo-indent 4)
(setq-default demo-indent 4)
(let ((other (generate-new-buffer "demo-other")))
  (with-temp-buffer
    (setq demo-indent 8)
    (princ (format "buffer 内 = %S, 默认值 = %S, 另一个 buffer = %S\n"
                   demo-indent
                   (default-value 'demo-indent)
                   (buffer-local-value 'demo-indent other))))
  (kill-buffer other))
;;;    注意 buffer-local-value 读的是「另一个 buffer 的那份」，上面它仍是默认值 4。

;;; 8) boundp 判有没有绑定，makunbound 解除绑定
(princ (format "boundp demo-counter = %S, boundp 不存在的 = %S\n"
               (boundp 'demo-counter) (boundp 'demo-never-defined)))

(princ "==== 03 结束 ====\n")
