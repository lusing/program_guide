;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 37 - 符号：四个格子、属性表与 obarray
;;;   符号不只是「名字」，它是一个有四个格子的对象。本章把四个格子
;;;   逐个打开看，并讲清 intern / make-symbol / gensym 的分工。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "37-symbols.el")'
;;; 运行：emacs -Q --batch -l 37-symbols.el
;;; ============================================================
(require 'cl-lib)
;;; 第 7 节要在运行时调用 byte-compile 抓一条「过时函数」的警告，所以这里
;;; 先把 bytecomp 加载进来，让 byte-compile-log-warning-function 成为特殊变量。
(require 'bytecomp)

;;; 下面要用到的全局符号先声明，免得字节编译器报「自由变量」。
(defvar demo-four-cell nil)
(defvar demo-a nil)
(defvar demo-b nil)
(defvar demo-c 10)

;;; ---------- 1) 一个符号，四个格子 ----------
;;; 名字格（print name）、变量格（value）、函数格（function）、属性表（plist）。
(princ "== 1) 符号的四个格子 ==\n")
(fset 'demo-four-cell (lambda () "我是函数格"))
(set 'demo-four-cell 42)
(princ (format "  (symbol-name 'demo-four-cell)     = %S\n"
               (symbol-name 'demo-four-cell)))
(princ (format "  (symbol-value 'demo-four-cell)    = %S\n"
               (symbol-value 'demo-four-cell)))
(princ (format "  (symbol-function 'demo-four-cell) = %S\n"
               (symbol-function 'demo-four-cell)))
(princ (format "  (symbol-plist 'demo-four-cell)    = %S\n"
               (symbol-plist 'demo-four-cell)))
(princ "  --- Lisp-2：同一个名字，两种取法 ---\n")
(princ (format "  直接写名字    -> %-14S ; 取变量格\n" demo-four-cell))
(princ (format "  写成 (名字)   -> %-14S ; 取函数格\n"
               (with-no-warnings (demo-four-cell))))

;;; ---------- 2) set 与 setq ----------
;;; set 对第一个参数求值（所以要先 quote）；setq 不求值，但第一个参数
;;; 必须是字面上的符号。
(princ "\n== 2) set 与 setq ==\n")
(setq demo-a 1)
(set 'demo-b 2)
(princ (format "  (setq demo-a 1)   -> demo-a = %S\n" demo-a))
(princ (format "  (set 'demo-b 2)   -> demo-b = %S\n" demo-b))
(princ "  --- set 的第一个参数会被求值，所以能「运行时决定改哪个」---\n")
(let ((which (if (> 1 0) 'demo-a 'demo-b)))
  (set which 99)
  (princ (format "  (setq which 'demo-a) 然后 (set which 99)：demo-a=%S  demo-b=%S\n"
                 demo-a demo-b)))
(princ (format "  (setq (car '(a b)) 1) -> %S\n"
               (condition-case err (eval '(setq (car '(a b)) 1))
                 (error (error-message-string err)))))

;;; ---------- 3) 变量格：boundp / 局部变量 / makunbound ----------
(princ "\n== 3) 变量格 ==\n")
(princ (format "  (boundp 'no-such-var)          = %S\n" (boundp 'no-such-var)))
(princ (format "  (default-boundp 'no-such-var)  = %S\n" (default-boundp 'no-such-var)))
(princ (format "  defvar 后：(boundp 'demo-c)=%S  (default-value 'demo-c)=%S\n"
               (boundp 'demo-c) (default-value 'demo-c)))
(make-local-variable 'demo-c)
(setq demo-c 20)
(princ (format "  make-local + setq 后：当前值=%S 默认值=%S 是局部变量？=%S\n"
               demo-c (default-value 'demo-c) (local-variable-p 'demo-c)))
(makunbound 'demo-c)
(princ (format "  makunbound 后：(boundp 'demo-c)=%S  (default-boundp 'demo-c)=%S\n"
               (boundp 'demo-c) (default-boundp 'demo-c)))

;;; ---------- 4) 函数格：函数、宏、特殊形式、C 原语、autoload ----------
(princ "\n== 4) 函数格 ==\n")
(princ (format "  (fboundp 'no-such-fn) = %S\n" (fboundp 'no-such-fn)))
(fset 'demo-fn (lambda (x) (* x 2)))
(princ (format "  fset 后：(fboundp 'demo-fn)=%S  (demo-fn 21)=%S\n"
               (fboundp 'demo-fn) (with-no-warnings (demo-fn 21))))
(princ (format "  (functionp 'demo-fn)=%S  (macrop 'demo-fn)=%S\n"
               (functionp 'demo-fn) (macrop 'demo-fn)))
(princ "  --- 宏、特殊形式、C 原语，函数格里的东西长得都不一样 ---\n")
(defmacro demo-macro (x) (list '* x x))
(princ (format "  宏 demo-macro：(macrop)=%S  (car (symbol-function))=%S  (consp …)=%S\n"
               (macrop 'demo-macro)
               (car (symbol-function 'demo-macro))
               (consp (symbol-function 'demo-macro))))
(princ (format "  特殊形式 if：(special-form-p 'if)=%S\n" (special-form-p 'if)))
(princ (format "  C 原语 car：(subrp (symbol-function 'car))=%S  (functionp 'car)=%S\n"
               (subrp (symbol-function 'car)) (functionp 'car)))
(princ "  --- autoload：函数格里先放一张「欠条」 ---\n")
(princ (format "  (autoloadp (symbol-function 'tetris)) = %S\n"
               (autoloadp (symbol-function 'tetris))))
(princ (format "  (nth 1 (symbol-function 'tetris))     = %S   ; 该去哪个文件里找\n"
               (nth 1 (symbol-function 'tetris))))
(princ (format "  (car (indirect-function 'tetris))     = %S\n"
               (car (indirect-function 'tetris))))

;;; ---------- 5) 属性表：给符号挂私有数据 ----------
(princ "\n== 5) 属性表（plist） ==\n")
(put 'demo-fn 'demo-note "这是我挂上去的说明")
(put 'demo-fn 'demo-count 3)
(princ (format "  (get 'demo-fn 'demo-note)  = %S\n" (get 'demo-fn 'demo-note)))
(princ (format "  (get 'demo-fn 'demo-count) = %S\n" (get 'demo-fn 'demo-count)))
(princ (format "  (get 'demo-fn '没有的键)   = %S\n" (get 'demo-fn '没有的键)))
(princ (format "  (symbol-plist 'demo-fn)    = %S\n" (symbol-plist 'demo-fn)))
(princ (format "  (plist-get (symbol-plist 'demo-fn) 'demo-count) = %S\n"
               (plist-get (symbol-plist 'demo-fn) 'demo-count)))
(princ "  --- function-put / function-get：和 put / get 是同一个命名空间 ---\n")
(function-put 'demo-fn 'demo-kind '工具函数)
(princ (format "  (function-get 'demo-fn 'demo-kind) = %S\n"
               (function-get 'demo-fn 'demo-kind)))
(princ (format "  (get 'demo-fn 'demo-kind)          = %S   ; 同一个格子，能直接取到\n"
               (get 'demo-fn 'demo-kind)))
(princ (format "  (symbol-plist 'demo-fn) 现在 = %S\n" (symbol-plist 'demo-fn)))
(fmakunbound 'demo-fn)
(princ (format "  fmakunbound 只清函数格，属性表还在：%S\n"
               (symbol-plist 'demo-fn)))

;;; ---------- 6) intern、make-symbol 与 obarray ----------
(princ "\n== 6) intern 与 obarray ==\n")
(princ (format "  (eq (intern \"foo\") (intern \"foo\"))           = %S\n"
               (eq (intern "foo") (intern "foo"))))
(princ (format "  (eq (make-symbol \"foo\") (make-symbol \"foo\")) = %S\n"
               (eq (make-symbol "foo") (make-symbol "foo"))))
(princ (format "  两者打印出来一模一样： %S / %S\n"
               (make-symbol "foo") (intern "foo")))
(princ (format "  (intern-soft \"no-such-symbol-xyz\") = %S\n"
               (intern-soft "no-such-symbol-xyz")))
(princ (format "  obarray 的 type-of=%S  obarrayp=%S\n"
               (type-of obarray) (obarrayp obarray)))
(princ "  --- 自建一张 obarray，看它怎么存符号 ---\n")
(let ((o (obarray-make)))
  (intern "aa" o)
  (intern "bb" o)
  (intern "cc" o)
  (let ((n 0) names)
    (mapatoms (lambda (s) (setq n (1+ n)) (push (symbol-name s) names)) o)
    (princ (format "  自建 obarray：%S 个符号，名字=%S\n" n (sort names #'string<)))))
(princ "  --- unintern 在 Emacs 31 里要两个参数 ---\n")
(let ((sym (intern "demo-tmp-symbol")))
  (princ (format "  intern 之后 (intern-soft \"demo-tmp-symbol\") = %S\n"
                 (intern-soft "demo-tmp-symbol")))
  (unintern sym obarray)
  (princ (format "  unintern 之后                              = %S\n"
                 (intern-soft "demo-tmp-symbol"))))

;;; ---------- 7) 造一个全新的符号：gensym 与 print-gensym ----------
(princ "\n== 7) 造一个全新的符号 ==\n")
(princ (format "  (gensym)         = %S\n" (gensym)))
(princ (format "  (gensym \"x-\")    = %S\n" (gensym "x-")))
(princ (format "  print-gensym 默认 = %S\n" print-gensym))
(princ (format "  设成 t 再打印未 intern 的符号： %S\n"
               (let ((print-gensym t)) (prin1-to-string (make-symbol "tmp")))))
(princ (format "  默认情况下打印同一个符号：     %S   ; 看不出它没被 intern\n"
               (prin1-to-string (make-symbol "tmp"))))
;;; cl-lib 里那个老名字已经过时了，把字节编译器的提醒当场抓下来。
(let (warns)
  (let ((byte-compile-log-warning-function
         (lambda (string &optional _position _fill _level)
           (push string warns))))
    (byte-compile '(lambda () (cl-gensym "x-"))))
  (princ (format "  字节编译器对 cl-gensym 的提醒： %S\n" (car (nreverse warns)))))

;;; ---------- 8) 关键字符号 ----------
(princ "\n== 8) 关键字符号 ==\n")
(princ (format "  :foo 求值结果 = %S   (keywordp :foo) = %S\n" (eval :foo) (keywordp :foo)))
(princ (format "  (symbol-name :foo) = %S   (symbol-value ':foo) = %S\n"
               (symbol-name :foo) (symbol-value ':foo)))
(princ (format "  (eq :foo :foo) = %S   ; 同一张 obarray 里的同一个符号\n" (eq :foo :foo)))

;;; ---------- 9) t 与 nil 是常量 ----------
(princ "\n== 9) t 与 nil 不能被赋值 ==\n")
(princ (format "  (symbol-value 'nil) = %S   (symbol-value 't) = %S\n"
               (symbol-value 'nil) (symbol-value 't)))
(princ (format "  (set 'nil 1) -> %S\n"
               (condition-case err (set 'nil 1) (error (error-message-string err)))))
(princ (format "  (set 't 1)   -> %S\n"
               (condition-case err (set 't 1) (error (error-message-string err)))))

(princ "==== 37 结束 ====\n")
