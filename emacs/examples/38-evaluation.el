;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 38 - 求值：quote、backquote、eval 与 funcall
;;;   「什么时候求值、求几次」是写宏和写 DSL 的地基。本章把
;;;   quote / ` / , / ,@ / eval / funcall / apply 逐个实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "38-evaluation.el")'
;;; 运行：emacs -Q --batch -l 38-evaluation.el
;;; ============================================================
(require 'cl-lib)
;;; 第 2、3 节要在运行时调用 byte-compile 抓警告，所以先加载 bytecomp，
;;; 让 byte-compile-log-warning-function 成为特殊变量。
(require 'bytecomp)

(defvar demo-dyn 7)

;;; 抓字节编译器警告的小工具：把警告接成字符串列表，不让它跑到 stderr 上。
(defun demo-capture-warning (form)
  "字节编译 FORM，返回它产生的第一条警告；没有则返回 nil。"
  (let (warns)
    (let ((byte-compile-log-warning-function
           (lambda (string &optional _position _fill _level)
             (push string warns))))
      (byte-compile form))
    (car (nreverse warns))))

;;; ---------- 1) 三种 form：自求值、符号、列表 ----------
(princ "== 1) 三种 form ==\n")
(dolist (v (list 42 "字符串" :keyword [1 2] ?A))
  (princ (format "  自求值 %-10S -> %S\n" v (eval v))))
(princ (format "  符号 demo-dyn              -> %S\n" (eval 'demo-dyn)))
(princ (format "  列表 (+ 1 2)               -> %S\n" (eval '(+ 1 2))))
(princ (format "  列表 (1 2) 会当成函数调用  -> %S\n"
               (condition-case err (eval '(1 2))
                 (error (error-message-string err)))))
(princ (format "  空表 ()                    -> %S\n" (eval '())))

;;; ---------- 2) quote：阻止求值（以及别改它） ----------
(princ "\n== 2) quote ==\n")
(princ (format "  '(+ 1 2)        = %S\n" '(+ 1 2)))
(princ (format "  (quote (+ 1 2)) = %S\n" (quote (+ 1 2))))
(princ (format "  ''a             = %S   它的 car = %S\n" ''a (car ''a)))
(princ (format "  (eval '(+ 1 2)) = %S\n" (eval '(+ 1 2))))
(princ "  --- quote 出来的列表是「常量」，改它后果未定义 ---\n")
(princ (format "  运行时改一下： %S\n"
               (let ((l '(1 2 3)))
                 (with-no-warnings (setcar l 99))
                 l)))
(princ (format "  字节编译器的警告： %S\n"
               (demo-capture-warning
                '(lambda () (let ((l '(1 2 3))) (setcar l 99) l)))))

;;; ---------- 3) #' 与 ' 对 lambda 的区别 ----------
(princ "\n== 3) #' 与 ' ==\n")
(princ (format "  (functionp #'(lambda (x) x)) = %S\n" (functionp #'(lambda (x) x))))
(princ (format "  用 #' 的那个照样能 funcall： %S\n" (funcall #'(lambda (x) (* x 2)) 5)))
;;; 下面故意演示「用 ' 包 lambda」。为了让本文件自己编译得干净，这个被 quote
;;; 的 lambda 用 list 现场拼出来——with-no-warnings 压不住这条警告。
(let ((quoted-lambda (list 'lambda '(x) '(* x 2))))
    (princ (format "  (functionp %S) = %S，也照样能 funcall： %S\n"
                 (list 'quote quoted-lambda)
                 (functionp quoted-lambda) (funcall quoted-lambda 5))))
(princ "  --- 区别在编译期：' 包 lambda 编译器就不再编译它 ---\n")
;;; 用 list 现场拼出 (functionp '(lambda (x) x))，免得源码里真的出现被 quote 的 lambda
(princ (format "  字节编译器的警告： %S\n"
               (demo-capture-warning
                (list 'functionp (list 'quote (list 'lambda '(x) 'x))))))

;;; ---------- 4) backquote：模板 + 挖洞 ----------
;;; 用 macroexpand 看它到底展开成什么。
(princ "\n== 4) backquote ==\n")
(dolist (form (list '`(a b)
                    '`(a ,b)
                    '`(a ,b ,@c)
                    '`(a ,b ,@c . d)
                    '`(a ,(list 1 2))))
  (princ (format "  %-16S 展开成 %S\n" form (macroexpand form))))
(princ "  --- 实际求值的结果 ---\n")
(princ (format "  b=2, c=nil     -> `(a ,b ,@c) = %S\n"
               (let ((b 2) (c nil)) `(a ,b ,@c))))
(princ (format "  b=2, c=(1 2)   -> `(a ,b ,@c) = %S\n"
               (let ((b 2) (c '(1 2))) `(a ,b ,@c))))
(princ (format "  ,@ 只展开一层：c=((1 2)) -> %S\n"
               (let ((c '((1 2)))) `(a ,@c))))
(princ "  --- 求值次数：, 里的式子每次都求 ---\n")
(princ (format "  %S\n"
               (let ((n 0))
                 (list (list `(a ,(setq n (1+ n))) `(a ,(setq n (1+ n)))) n))))

;;; ---------- 5) eval：把数据当代码跑 ----------
(princ "\n== 5) eval ==\n")
(princ (format "  (eval '(+ 1 2))      = %S\n" (eval '(+ 1 2))))
(princ (format "  (eval (list '+ 1 2)) = %S  ; 现场拼出来的也行\n" (eval (list '+ 1 2))))
(princ (format "  (eval '(car '(1 2))) = %S\n" (eval '(car '(1 2)))))
(princ "  --- eval 看不见词法变量 ---\n")
(let ((demo-lex 1))
  (princ (format "  let 里的词法变量 demo-lex 本身 = %S\n" demo-lex))
  (princ (format "  但 (eval 'demo-lex) -> %S\n"
                 (condition-case err (eval 'demo-lex)
                   (error (error-message-string err)))))
  (princ (format "  (eval 'demo-dyn)    -> %S   ; defvar 过的是动态变量，看得见\n"
                 (eval 'demo-dyn))))
(princ "  --- 第二个参数决定用哪种作用域 ---\n")
(princ (format "  (eval '(let ((a 5)) (lambda () a)) nil) 再调用 -> %S\n"
               (condition-case err
                   (let ((f (eval '(let ((a 5)) (lambda () a)) nil)))
                     (funcall f))
                 (error (error-message-string err)))))
(princ (format "  (eval '(let ((a 5)) (lambda () a)) t)   再调用 -> %S\n"
               (condition-case err
                   (let ((f (eval '(let ((a 5)) (lambda () a)) t)))
                     (funcall f))
                 (error (error-message-string err)))))

;;; ---------- 6) funcall / apply / apply-partially ----------
(princ "\n== 6) funcall 与 apply ==\n")
(princ (format "  (funcall '+ 1 2)        = %S\n" (funcall '+ 1 2)))
(princ (format "  (funcall #'+ 1 2)       = %S\n" (funcall #'+ 1 2)))
(princ (format "  (apply '+ '(1 2))       = %S\n" (apply '+ '(1 2))))
(princ (format "  (apply '+ 1 2 '(3))     = %S   ; 最后一个参数必须是表\n"
               (apply '+ 1 2 '(3))))
(princ (format "  (apply '+ 1 2 3)        -> %S\n"
               (condition-case err (apply '+ 1 2 3)
                 (error (error-message-string err)))))
(princ (format "  (apply #'max '(1 5 3))  = %S\n" (apply #'max '(1 5 3))))
(princ (format "  (funcall (apply-partially '+ 1 2) 3) = %S\n"
               (funcall (apply-partially '+ 1 2) 3)))
(princ (format "  (func-arity #'car) = %S  (func-arity (lambda (a &optional b) (list a b))) = %S\n"
               (func-arity #'car)
               (func-arity (lambda (a &optional b) (list a b)))))

;;; ---------- 7) 宏展开发生在求值之前 ----------
(princ "\n== 7) 宏展开做一层还是做彻底 ==\n")
(princ (format "  macroexpand      : %S\n" (macroexpand '(when t (when t 1)))))
(princ (format "  macroexpand-all  : %S\n" (macroexpand-all '(when t (when t 1)))))
(princ (format "  展开后再求值      : %S\n"
               (eval (macroexpand-all '(when t (when t 1))))))

;;; ---------- 8) 谁会被求值 ----------
(princ "\n== 8) 谁会被求值 ==\n")
(princ (format "  (if t 1 (error \"不该执行\")) = %S   ; 特殊形式，else 分支不求值\n"
               (if t 1 (error "不该执行"))))
(princ (format "  (+ 1 (error \"x\"))          -> %S   ; 函数形式，每个参数都要求\n"
               (condition-case err (+ 1 (error "x"))
                 (error (error-message-string err)))))
(princ (format "  (and nil (error \"x\"))      = %S   ; and/or 也短路\n"
               (and nil (error "x"))))
(princ (format "  (list 1 (error \"x\"))       -> %S   ; 换成 list 就照样报错\n"
               (condition-case err (list 1 (error "x"))
                 (error (error-message-string err)))))

(princ "==== 38 结束 ====\n")
