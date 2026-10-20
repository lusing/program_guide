;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 45 - 作用域与控制流：cl-flet、cl-block 与多值
;;;   第 44 章解决了「值能存进哪里」；这一章解决「名字在什么范围内
;;;   指向什么」。cl-lib 把 Common Lisp 的局部函数绑定（cl-flet /
;;;   cl-labels）、局部宏绑定（cl-macrolet / cl-symbol-macrolet）、
;;;   运行时动态绑定（cl-progv）、符号分派（cl-case 家族）、具名
;;;   非局部退出（cl-block / cl-return-from）和迭代宏（cl-do 家族）
;;;   全部搬进 Emacs，对应手册 5.3–5.6；外加 5.8 的「多值」——
;;;   它在 Emacs 里其实是列表模拟，这一章也实测给你看。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "45-scoping-control.el")'
;;; 运行：emacs -Q --batch -l 45-scoping-control.el
;;; ============================================================
(require 'cl-lib)

(defvar ch45-bar nil)
(defvar ch45-v1 'outside)
(defvar ch45-v2 'outside)

;;; ---------- 1) cl-flet 与 cl-labels：局部函数绑定 ----------
(princ "== 1) cl-flet 与 cl-labels：局部函数绑定 ==\n")
(defun ch45-outer () "global")
(defun ch45-call-outer () (ch45-outer))
(princ (format "  (cl-flet ((ch45-outer () \"local\")) (ch45-outer)) → %S\n"
               (cl-flet ((ch45-outer () "local")) (ch45-outer))))
(princ (format "  #' 引用也走局部绑定：%S\n"
               (cl-flet ((ch45-outer () "local")) (funcall #'ch45-outer))))
(princ (format "  出了 flet 体 → %S\n" (ch45-outer)))
(princ (format "  被调函数体内看不到 cl-flet 绑定 → %S\n"
               (cl-flet ((ch45-outer () "local")) (ch45-call-outer))))
(defun ch45-self () "global-self")
(princ (format "  cl-flet 体内自调用走的是全局（非递归）：%S\n"
               (cl-flet ((ch45-self () (list 'local (ch45-self))))
                 (ch45-self))))
(princ (format "  cl-labels 递归阶乘 5! = %S\n"
               (cl-labels ((fact (n) (if (< n 2) 1 (* n (fact (1- n))))))
                 (fact 5))))
(princ (format "  cl-labels 互相递归 ev(6) = %S\n"
               (cl-labels ((ev (n) (if (= n 0) t (od (1- n))))
                           (od (n) (if (= n 0) nil (ev (1- n)))))
                 (ev 6))))
(princ "  cl-flet：词法、非递归；cl-labels：词法、可递归/互相递归。\n")
(princ "  两者都要求所有引用「物理地」出现在体内（词法作用域）。\n")

;;; ---------- 2) cl-macrolet 与 cl-symbol-macrolet ----------
(princ "\n== 2) cl-macrolet 与 cl-symbol-macrolet ==\n")
(princ (format "  cl-macrolet 局部宏：(double 21) → %S\n"
               (cl-macrolet ((double (x) `(+ ,x ,x))) (double 21))))
(setq ch45-bar '(5 . 9))
(cl-symbol-macrolet ((foo (car ch45-bar)))
  (cl-incf foo))
(princ (format "  symbol-macrolet + cl-incf：ch45-bar → %S\n" ch45-bar))
(setq ch45-bar '(5 . 9))
(cl-symbol-macrolet ((foo (car ch45-bar)))
  (setq foo 4))
(princ (format "  对符号宏 setq 等同 setf：ch45-bar → %S\n" ch45-bar))
(princ "  cl-macrolet 是「let 版的 defmacro」；cl-symbol-macrolet 把\n")
(princ "  变量引用替换成任意形式——foo 看起来是变量，其实是 (car ch45-bar)。\n")

;;; ---------- 3) cl-progv：运行时算出变量名的动态绑定 ----------
(princ "\n== 3) cl-progv：运行时算出变量名的动态绑定 ==\n")
(let ((names (list 'ch45-v1 'ch45-v2))
      (vals '(10)))
  (cl-progv names vals
    (princ (format "  体内 ch45-v1=%S ch45-v2=%S（值不够补 nil）\n"
                   ch45-v1 ch45-v2)))
  (princ (format "  体外 ch45-v1=%S ch45-v2=%S\n" ch45-v1 ch45-v2)))
(princ "  let 绑的是编译期已知的名字；cl-progv 接收两个「列表」：\n")
(princ "  符号列表 + 值列表，运行时才决定绑谁——动态作用域专属。\n")

;;; ---------- 4) cl-case：符号/常量分派 ----------
(princ "\n== 4) cl-case：符号/常量分派 ==\n")
(dolist (k (list ?a ?b ?\r 'x))
  (princ (format "  key=%S → %S\n" k
                 (cl-case k
                   (?a "do-a")
                   (?b "do-b")
                   ((?\r ?\n) "do-ret")
                   (t "do-other")))))
(princ (format "  otherwise 与 t 等价：%S\n"
               (cl-case 'z (a "A") (otherwise "OTH"))))
(princ (format "  想匹配字面符号 t 就得包列表：%S\n"
               (cl-case 't ((t) "literal-t") (t "fallback"))))
(princ "  比较用 eql；单键可不包列表，但 t/nil/cons 必须包。\n")
(princ "  无匹配返回 nil（手册 5.4）。\n")

;;; ---------- 5) cl-ecase：不匹配即报错 ----------
(princ "\n== 5) cl-ecase：不匹配即报错 ==\n")
(princ (format "  (cl-ecase 'b (a 1) (b 2)) → %S\n" (cl-ecase 'b (a 1) (b 2))))
(princ (format "  无匹配 → %S\n"
               (condition-case err
                   (cl-ecase 'c (a 1) (b 2))
                 (error (error-message-string err)))))
(princ "  cl-ecase = cl-case + 「必须穷尽」：漏分支当场炸，不静默返回 nil。\n")

;;; ---------- 6) cl-typecase 与 cl-etypecase ----------
(princ "\n== 6) cl-typecase 与 cl-etypecase ==\n")
(dolist (v (list 1 1.0 "42" '(1)))
  (princ (format "  %S → %S\n" v
                 (cl-typecase v
                   (integer "int")
                   (float "float")
                   (string (number-to-string (1+ (string-to-number v))))
                   ((or symbol cons) "sym-or-cons")
                   (t "anything")))))
(princ (format "  cl-etypecase 无匹配 → %S\n"
               (condition-case err
                   (cl-etypecase :kw (integer "int"))
                 (error (error-message-string err)))))
(princ "  cl-typecase 按键的类型（cl-typep）分派；(or …) 可合并多个类型。\n")

;;; ---------- 7) cl-block 与 cl-return-from ----------
(princ "\n== 7) cl-block 与 cl-return-from：具名非局部退出 ==\n")
(princ (format "  双层循环命中即整体退出：%S\n"
               (cl-block ch45-blk
                 (let ((hits nil))
                   (dolist (i '(1 2 3))
                     (dolist (j '(10 20 30))
                       (push (list i j) hits)
                       (when (= j 20)
                         (cl-return-from ch45-blk (nreverse hits)))))
                   :not-found))))
(princ (format "  不触发时返回最后一个形式：%S\n" (cl-block ch45-b2 1 2 3)))
(princ (format "  体内 lambda 里也能 return-from：%S\n"
               (cl-block ch45-b3
                 (funcall (lambda () (cl-return-from ch45-b3 'from-lambda))))))
(princ (format "  展开看机制：块名被做成一个词法变量：%S\n"
               (macroexpand '(cl-block ch45-b4 (cl-return-from ch45-b4 1)))))
(princ (format "  块名不在词法范围内 → 引用不存在的块变量：%S\n"
               (condition-case err
                   (eval '(cl-return-from ch45-nowhere) t)
                 (error (error-message-string err)))))
(princ "  cl-block 底层确实是 catch，但标签被藏进词法变量 --cl-block-名--；\n")
(princ "  出了块体，变量不存在，别的函数休想逃进来——这就是词法配对。\n")

;;; ---------- 8) cl-return 与隐式 nil 块 ----------
(princ "\n== 8) cl-return 与隐式 nil 块 ==\n")
(princ (format "  cl-dolist 里 (cl-return 72)：%S\n"
               (cl-dolist (x '(1 2 3)) (when (= x 2) (cl-return 72)) 'cont)))
(princ (format "  原生 dolist 里没有隐式 nil 块，cl-return 报错：%S\n"
               (condition-case err
                   (eval '(dolist (x '(1 2 3)) (when (= x 2) (cl-return 72))) t)
                 (error (error-message-string err)))))
(princ (format "  手册里的裸 return 在 31.1 根本不存在：(fboundp 'return) = %S\n"
               (fboundp 'return)))
(princ (format "  cl-loop 简单形态（手册 5.6 的无限循环）：%S\n"
               (let ((n 0))
                 (cl-loop (setq n (1+ n))
                          (if (>= n 3) (cl-return n))))))
(princ "  cl-return ≡ (cl-return-from nil …)；cl-dolist/cl-dotimes/cl-loop\n")
(princ "  都自带隐式 nil 块；原生 dolist/while 没有。手册示例里的裸 return\n")
(princ "  只在废弃 cl.el 有，Emacs 正路是 cl-return。\n")

;;; ---------- 9) cl-tagbody：标签与 go ----------
(princ "\n== 9) cl-tagbody：标签与 go ==\n")
(princ (format "  累加到 sum≥10 停止：%S\n"
               (let ((i 0) (sum 0))
                 (cl-tagbody
                   top
                   (setq i (1+ i))
                   (setq sum (+ sum i))
                   (when (< sum 10) (go top)))
                 (list i sum))))
(princ "  tagbody 是「带词法标签的 goto」：Common Lisp 循环的底层骨架，\n")
(princ "  Emacs 里日常少见，但读懂它才算读懂 cl-do 的展开。\n")

;;; ---------- 10) cl-do 与 cl-do* ----------
(princ "\n== 10) cl-do 与 cl-do*：通用迭代 ==\n")
(defun ch45-f (a b) (+ a b))
(let ((foo '(1 2 3)) (bar '(10 20 30)))
  (princ (format "  cl-do（手册例：无 body，全靠 step）：%S\n"
                 (cl-do ((x foo (cdr x))
                         (y bar (cdr y))
                         (z nil (cons (ch45-f (car x) (car y)) z)))
                        ((or (null x) (null y))
                         (nreverse z))))))
(let ((foo '(1 2 3)) (bar '(10 20 30)))
  (princ (format "  cl-do*（串行 step + body push）：%S\n"
                 (cl-do* ((xp foo (cdr xp))
                          (yp bar (cdr yp))
                          (x (car xp) (car xp))
                          (y (car yp) (car yp))
                          z)
                         ((or (null xp) (null yp))
                          (nreverse z))
                         (push (ch45-f x y) z)))))
(princ "  cl-do 的 step 并行赋值（≡ cl-psetq），cl-do* 串行（≡ setq）；\n")
(princ "  end-test 为真时求值 result 形式，整个循环包在隐式 nil 块里。\n")

;;; ---------- 11) cl-dolist 与 cl-dotimes ----------
(princ "\n== 11) cl-dolist 与 cl-dotimes ==\n")
(let ((total 0))
  (princ (format "  cl-dolist 累加：%S（result 形式 'done）\n"
                 (cl-dolist (x '(1 2 3) 'done) (setq total (+ total x)))))
  (princ (format "  累加结果 = %S\n" total)))
(princ (format "  cl-dotimes 提前退出：%S\n"
               (cl-dotimes (i 10) (when (= i 4) (cl-return i)))))
(princ (format "  cl-dotimes 不带 result 跑完：%S\n"
               (cl-dotimes (i 3) i)))
(princ "  与原生 dolist/dotimes 的差别只有一句话：多了隐式 nil 块，\n")
(princ "  所以体内能用 cl-return。手册还提醒 dotimes 的 result 已废弃。\n")

;;; ---------- 12) 多值：cl-values 家族用列表模拟 ----------
(princ "\n== 12) 多值：cl-values 家族用列表模拟 ==\n")
(princ (format "  (cl-values 1 2 3) 就是列表：%S\n" (cl-values 1 2 3)))
(princ (format "  cl-multiple-value-bind 按列表位置绑定：%S\n"
               (cl-multiple-value-bind (a b) (cl-values 1 2 3) (list a b))))
(princ (format "  变量多了补 nil、值多了丢弃：%S\n"
               (cl-multiple-value-bind (a b c d) (cl-values 1 2) (list a b c d))))
(let (x y)
  (cl-multiple-value-setq (x y) (cl-values 8 9))
  (princ (format "  cl-multiple-value-setq 赋给已有变量：x=%S y=%S\n" x y)))
(princ (format "  cl-multiple-value-list 原样返回：%S\n"
               (cl-multiple-value-list (cl-values 1 2 3))))
(princ (format "  cl-multiple-value-call 把列表摊平成实参：%S\n"
               (cl-multiple-value-call #'+ (cl-values 1 2 3))))
(princ (format "  31.1 里原生 values 已不存在：(fboundp 'values) = %S\n"
               (fboundp 'values)))
(princ "  手册 5.8 原话：Emacs 不模拟「真」多值——cl-values ≡ list，\n")
(princ "  cl-multiple-value-bind 只认列表；旧版原生的 values 家族在\n")
(princ "  31.1 已整体移除（实测 fboundp 为 nil），返回列表就是唯一正路。\n")

(princ "==== 45 结束 ====\n")
