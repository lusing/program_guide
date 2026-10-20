;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 43 - 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro
;;;   上一章用 cl-defmacro 写了几个宏，但那些宏都只在「解释执行」
;;;   时跑过。真正要写一个能编译的宏，还需要三样工具：控制求值
;;;   时机的 cl-eval-when、避免实参重复求值的 cl-once-only、以及
;;;   在编译期改写函数调用的 compiler macro。本章把 cl-lib 里这
;;;   一组「写宏的宏」全部实测一遍，每个结论都来自 Emacs 31.1。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "43-macro-tools.el")'
;;; 运行：emacs -Q --batch -l 43-macro-tools.el
;;; ============================================================
(require 'cl-lib)
(require 'bytecomp)

;; 下面各节用 run3 编译/加载临时源文件，那些文件里用 eval-and-compile
;; 定义了这几个全局变量。这里先声明（不带初值），只为告诉字节编译器
;; 它们是动态变量，免得 reset 里的 set 触发「free variable」警告。
(defvar pp2-log)
(defvar pp6-ctr)
(defvar pp6-val)

;;; ---------- 1) 测量装置：run3 ----------
;; 后面几节要比较「同一段源码」在三个时刻的行为：
;;   编译阶段   —— byte-compile-file 编译时求值了什么；
;;   载入 .elc  —— 编译产物加载时又执行了什么；
;;   载入 .el   —— 不编译、直接解释加载时执行了什么。
;; run3 把这三步串起来：BODY 是一段源码文本，READ 读全局状态，
;; RESET 把状态清零。返回 (编译后 载入elc后 载入el后) 三个读数。
(defun ch43-run3 (body read reset)
  (let* ((dir (make-temp-file "ch43-" t))
         (src (expand-file-name "probe.el" dir))
         (elc (concat src "c")))
    (unwind-protect
        (progn
          (with-temp-file src
            (insert ";;; -*- lexical-binding: t; -*-\n")
            (insert "(require 'cl-lib)\n")
            (insert body))
          (funcall reset)
          (let ((inhibit-message t)
                (byte-compile-warnings nil))
            (byte-compile-file src))
          (let ((a (funcall read)))
            (funcall reset)
            (load elc nil t)
            (let ((b (funcall read)))
              (funcall reset)
              (delete-file elc)
              (load src nil t)
              (list a b (funcall read)))))
      (delete-directory dir t))))

(princ "== 1) 测量装置 run3 ==\n")
(princ "  run3 把同一段源码走三个时刻：编译、载入 .elc、载入 .el，\n")
(princ "  每个时刻读一次全局状态。下面各节都靠它给出实测结果。\n")

;;; ---------- 2) cl-eval-when 在解释执行时展开成什么 ----------
(princ "\n== 2) cl-eval-when 解释执行时的展开 ==\n")
(princ "  cl-eval-when 的参数是 (COMPILE LOAD EVAL) 的子集：\n")
(princ "    compile —— 字节编译该文件时求值；\n")
(princ "    load    —— 编译产物被加载时求值；\n")
(princ "    eval    —— 解释执行（或非顶层）时求值。\n")
(princ "  解释器里 macroexp-compiling-p 为 nil，所以只有 eval/:execute 留下：\n")
(dolist (w '((compile) (load) (eval) (:execute) (compile load eval)))
  (princ (format "  (macroexpand-1 '(cl-eval-when %S (foo))) → %S\n"
                 w (macroexpand-1 `(cl-eval-when ,w (foo))))))
(princ "  (compile) 和 (load) 展开成 nil：解释执行时它们本来就不该跑。\n")

;;; ---------- 3) 七种组合的三阶段实测 ----------
(princ "\n== 3) 七种组合：编译 / 载入 .elc / 载入 .el ==\n")
(let ((body (concat
            "(eval-and-compile (defvar pp2-log nil))\n"
            "(eval-and-compile (defmacro pp2-rec (n) `(push ,n pp2-log)))\n"
            "(cl-eval-when (compile) (pp2-rec 1))\n"
            "(cl-eval-when (load) (pp2-rec 2))\n"
            "(cl-eval-when (eval) (pp2-rec 3))\n"
            "(cl-eval-when (compile load) (pp2-rec 4))\n"
            "(cl-eval-when (compile eval) (pp2-rec 5))\n"
            "(cl-eval-when (load eval) (pp2-rec 6))\n"
            "(cl-eval-when (compile load eval) (pp2-rec 7))\n"))
      (read (lambda () (sort (copy-sequence (symbol-value 'pp2-log)) #'<)))
      (reset (lambda () (set 'pp2-log nil))))
  (let ((r (ch43-run3 body read reset)))
    (princ (format "  源码：(cl-eval-when (compile) (pp2-rec 1)) ... 共七种组合\n"))
    (princ (format "  编译阶段记录   = %S\n" (nth 0 r)))
    (princ (format "  载入 .elc 记录 = %S\n" (nth 1 r)))
    (princ (format "  载入 .el  记录 = %S\n" (nth 2 r)))))
(princ "  编译阶段 (1 4 5 7)：凡带 compile 的都当场求值。\n")
(princ "  载入 .elc (2 4 6 7)：注意没有 3！单独的 (eval) 在编译期\n")
(princ "  展开成 (progn nil)，根本不会进入字节码；(load) 编译期展开成\n")
(princ "  (if nil nil body)，载入时才跑。带 compile+load 的 4、7 两边都记。\n")
(princ "  载入 .el (3 5 6 7)：凡带 eval 的都跑，与 compile 无关。\n")

;;; ---------- 4) 函数体内只认 eval ----------
(princ "\n== 4) 函数体内：只有 eval 生效 ==\n")
(princ (format "  %S\n"
               (macroexpand-all
                '(lambda () (cl-eval-when (compile) (a)) (cl-eval-when (eval) (b))))))
(princ (format "  %S\n"
               (macroexpand-all
                '(lambda () (cl-eval-when (load) (c)) (cl-eval-when (:execute) (d))))))
(princ "  文档原文：compile/load 只在「顶层」起作用；函数体里非顶层，\n")
(princ "  所以 compile、load 全被丢掉，只剩 eval/:execute 的 (progn ...)。\n")

;;; ---------- 5) eval-when-compile 与 eval-and-compile ----------
(princ "\n== 5) eval-when-compile 与 eval-and-compile ==\n")
(princ (format "  (macroexpand-1 '(eval-when-compile 3))          → %S\n"
               (macroexpand-1 '(eval-when-compile 3))))
(princ (format "  (macroexpand-all '(lambda () (eval-when-compile 3))) → %S\n"
               (macroexpand-all '(lambda () (eval-when-compile 3)))))
(princ (format "  (macroexpand-1 '(eval-and-compile 3))           → %S\n"
               (macroexpand-1 '(eval-and-compile 3))))
(princ "  eval-when-compile 编译时求值，结果对编译器呈现为 quoted 常量\n")
(princ "  （lambda 体里直接变成 '3）；解释执行时等价于 progn。\n")
(princ "  eval-and-compile = cl-eval-when (compile load eval)：宏定义\n")
(princ "  的标准包装，保证「编译时展开需要它、运行时展开也需要它」。\n")

;;; ---------- 6) compile-only 的 body 不会进入加载产物 ----------
(princ "\n== 6) 顶层 defvar 与 compile-only body ==\n")
(let ((body (concat
            "(eval-and-compile (defvar pp5-seen nil))\n"
            "(cl-eval-when (compile) (defvar pp5-var 42) (setq pp5-seen t))\n"))
      (read (lambda ()
              (list (if (boundp 'pp5-var) (symbol-value 'pp5-var) 'unbound)
                    (if (boundp 'pp5-seen) (symbol-value 'pp5-seen) 'unbound))))
      (reset (lambda ()
               (when (boundp 'pp5-var) (makunbound 'pp5-var))
               (when (boundp 'pp5-seen) (makunbound 'pp5-seen)))))
  (let ((r (ch43-run3 body read reset)))
    (princ "  源码：(cl-eval-when (compile) (defvar pp5-var 42) (setq pp5-seen t))\n")
    (princ (format "  三阶段读数 (pp5-var pp5-seen) = %S\n" r))))
(princ "  编译阶段 (42 t)：cl-eval-when (compile) 的 body 被显式 eval，defvar\n")
(princ "  与 setq 都跑了。载入 .elc/.el 都是 (unbound nil)：pp5-var 只在\n")
(princ "  compile 阶段出现，纯 compile 的 body 不向字节码输出任何代码，加载后\n")
(princ "  它不存在；而 pp5-seen 由 eval-and-compile 的 defvar 绑定，会进加载\n")
(princ "  产物，所以每次加载又被设回 nil。两者的去向，正好对照出 compile 与\n")
(princ "  eval-and-compile 的区别。\n")

;;; ---------- 7) cl-load-time-value ----------
(princ "\n== 7) cl-load-time-value：只在加载时算一次 ==\n")
(let ((body (concat
            "(eval-and-compile (defvar pp6-ctr 0))\n"
            "(eval-and-compile (defvar pp6-val nil))\n"
            "(defun pp6-bump () (setq pp6-ctr (1+ pp6-ctr)) (list 'stamp pp6-ctr))\n"
            "(cl-load-time-value (setq pp6-val (list (pp6-bump))))\n"))
      (read (lambda () (list (symbol-value 'pp6-ctr) (symbol-value 'pp6-val))))
      (reset (lambda () (set 'pp6-ctr 0) (set 'pp6-val nil) (fmakunbound 'pp6-bump))))
  (let ((r (ch43-run3 body read reset)))
    (princ "  源码：(cl-load-time-value (setq pp6-val (list (pp6-bump))))\n")
    (princ (format "  三阶段读数 (pp6-ctr pp6-val) = %S\n" r))))
(princ "  编译阶段 (0 nil)：编译时完全不算，结果「推迟到加载」。\n")
(princ "  载入 .elc 后 ctr=1：整个 form 只求值一次，结果当常量用。\n")
(princ "  典型用途：(cl-load-time-value (build-big-table)) 只在加载时建一次表，\n")
(princ "  之后每次调用都直接引用那个常量，而不是每次重建。\n")

;;; ---------- 8) 宏的实参被求值两次 ----------
(princ "\n== 8) 反面教材：实参重复求值 ==\n")
(defvar ch43-calls 0)
(defun ch43-next (n)
  "返回 N，顺便把 ch43-calls 加一，用来数求值次数。"
  (setq ch43-calls (1+ ch43-calls))
  n)
(defmacro ch43-square-bad (x)
  `(* ,x ,x))
(princ "  (defmacro ch43-square-bad (x) `(* ,x ,x))\n")
(princ "  (ch43-square-bad (ch43-next 3)) 展开后 x 出现两次：\n")
(princ (format "  %S\n" (macroexpand '(ch43-square-bad (ch43-next 3)))))
(let ((ch43-calls 0))
  (princ (format "  结果 (值 求值次数) = %S\n"
                 (list (ch43-square-bad (ch43-next 3)) ch43-calls))))
(princ "  (9 2)：平方本该只算一次，副作用却发生了两次。\n")
(princ "  实参是常量时看不出问题，是 (pop l) 这类表达式时就是 bug。\n")

;;; ---------- 9) cl-once-only ----------
(princ "\n== 9) cl-once-only：实参只求值一次 ==\n")
(defun ch43-norm (form)
  "把 FORM 里的 gensym 统一显示成 G1、G2……方便对比。"
  (let ((seen nil))
    (cl-labels ((walk (x)
                  (cond
                   ((consp x) (cons (walk (car x)) (walk (cdr x))))
                   ((and (symbolp x) (not (eq x (intern (symbol-name x)))))
                    (let ((cell (assq x seen)))
                      (unless cell
                        (setq cell (cons x (intern (format "G%d" (1+ (length seen))))))
                        (push cell seen))
                      (cdr cell)))
                   (t x))))
      (walk form))))
(defmacro ch43-square-ok (x)
  (cl-once-only (x)
    `(* ,x ,x)))
(princ "  (defmacro ch43-square-ok (x) (cl-once-only (x) `(* ,x ,x)))\n")
(princ "  cl-once-only 展开后的样子（gensym 归一化为 G1）：\n")
(princ (format "  %S\n"
               (ch43-norm (macroexpand '(ch43-square-ok (ch43-next 3))))))
(let ((ch43-calls 0))
  (princ (format "  结果 (值 求值次数) = %S\n"
                 (list (ch43-square-ok (ch43-next 3)) ch43-calls))))
(princ "  (9 1)：实参先绑到 gensym，体里两个 G1 只是变量引用。\n")
(princ "  cl-once-only 的名字是 (NAME FORM) 或 NAME；展开期 NAME 绑 gensym，\n")
(princ "  生成的代码里 FORM 只求值一次并绑到同一个 gensym。\n")

;;; ---------- 10) cl-with-gensyms ----------
(princ "\n== 10) cl-with-gensyms：手写卫生宏的样板 ==\n")
(defmacro ch43-let-sq (value &rest body)
  "把 VALUE 绑到临时变量 TMP，再执行 BODY（TMP 用 gensym 防捕获）。"
  (cl-with-gensyms (tmp)
    `(let ((,tmp ,value))
       (* ,tmp ,tmp)
       ;; 真实宏里这里会是 BODY；为演示求值次数，直接平方
       ,@body)))
(princ "  (defmacro ch43-let-sq (value &rest body)\n")
(princ "    (cl-with-gensyms (tmp) `(let ((,tmp ,value)) (* ,tmp ,tmp) ,@body)))\n")
(princ "  cl-with-gensyms 把 NAMES 逐个绑到 uninterned 符号，展开期用：\n")
(princ (format "  %S\n"
               (ch43-norm (macroexpand '(ch43-let-sq (ch43-next 3)) ))))
(let ((ch43-calls 0))
  (princ (format "  (ch43-let-sq (ch43-next 3)) 结果 (值 次数) = %S\n"
                 (list (ch43-let-sq (ch43-next 3)) ch43-calls))))
(princ "  与 once-only 的区别：with-gensyms 只负责「造一个不会撞名的符号」，\n")
(princ "  实参只求值一次要靠你自己把它放进 let；once-only 两件事都做了。\n")
(princ "  变量名 tmp 打印成裸名 G1：print-gensym 默认 nil，gensym 看起来\n")
(princ "  像普通符号，但它不 intern，永远不会和调用方的同名变量撞车。\n")

;;; ---------- 11) cl-destructuring-bind ----------
(princ "\n== 11) cl-destructuring-bind：宏参数列表的解构 ==\n")
(princ "  宏里拿到一个「参数列表形状的」数据，想直接按名字取，用这个宏：\n")
(princ (format "  %S\n"
               (macroexpand-all
                '(cl-destructuring-bind (&whole w a b) x
                   (list w a b)))))
(princ "  展开用 --cl-rest-- 接住整个列表，再逐个 pop；长度不对就报\n")
(princ "  wrong-number-of-arguments，错误信息里带上原始参数列表：\n")
(princ (format "  少一个：%S\n"
               (condition-case err
                   (cl-destructuring-bind (a b) '(1) (list a b))
                 (error (error-message-string err)))))
(princ (format "  多一个：%S\n"
               (condition-case err
                   (cl-destructuring-bind (&whole w a b) '(1 2 3) (list w a b))
                 (error (error-message-string err)))))
(princ "  它就是 cl-defmacro 参数解构的运行期版本：宏展开期常用它把\n")
(princ "  &rest 收到的形式拆成 (op arg1 arg2) 这样的具名变量。\n")

;;; ---------- 12) cl-define-compiler-macro ----------
(princ "\n== 12) cl-define-compiler-macro：编译期改写函数调用 ==\n")
(let ((body (concat
            "(defun ch43-trace (a b) (list 'runtime a b))\n"
            "(cl-define-compiler-macro ch43-trace (a b) `(list 'compiled ,a ,b))\n"
            "(defun pp7-call () (ch43-trace 2 5))\n"))
      (read (lambda ()
              (list (if (fboundp 'pp7-call) (pp7-call) nil)
                    (not (null (get 'ch43-trace 'compiler-macro))))))
      (reset (lambda ()
               (fmakunbound 'ch43-trace)
               (fmakunbound 'pp7-call)
               (put 'ch43-trace 'compiler-macro nil))))
  (let ((r (ch43-run3 body read reset)))
    (princ "  源码：defun ch43-trace + compiler macro + (defun pp7-call () (ch43-trace 2 5))\n")
    (princ (format "  三阶段读数 (pp7-call 结果 是否登记cmacro) = %S\n" r))
    (princ (format "  登记的符号属性：%S\n"
                   (if (get 'ch43-trace 'compiler-macro) 'ch43-trace--cmacro nil)))))
(princ "  三阶段都是 (compiled 2 5)：在 31.1 里 compiler macro 连解释执行\n")
(princ "  都拦不住——解释器会把 lambda 即时编译成字节码，调用点照样展开。\n")
(princ "  想拿到「原始调用」直接 funcall 函数本体：\n")
(princ (format "  (funcall (symbol-function 'ch43-trace) 2 5) = %S\n"
               (funcall (symbol-function 'ch43-trace) 2 5)))
(princ (format "  (cl-compiler-macroexpand '(ch43-trace 2 5)) = %S\n"
               (cl-compiler-macroexpand '(ch43-trace 2 5))))
(princ "  名字规律：compiler macro 存成「函数名--cmacro」，挂在函数符号的\n")
(princ "  compiler-macro 属性上；cl-define-compiler-macro 内部就是\n")
(princ "  eval-and-compile + define-symbol-prop。第 42 章 square 的\n")
(princ "  byte-optimizer 属性，正是 cl-defsubst 自动登记的这条 cmacro。\n")

;;; ---------- 13) cl-proclaim 与 cl-declaim ----------
(princ "\n== 13) cl-proclaim 与 cl-declaim：对编译器下指令 ==\n")
(princ (format "  (macroexpand-1 '(cl-declaim (optimize (safety 0)))) → %S\n"
               (macroexpand-1 '(cl-declaim (optimize (safety 0))))))
(princ (format "  cl-proclaim 是函数：%S；cl-declaim 是宏：%S\n"
               (functionp 'cl-proclaim) (macrop 'cl-declaim)))
(princ "  cl-declaim 只是把参数 quoted 后转给 cl-proclaim，所以直接\n")
(princ "  把 optimize 裸写进 cl-proclaim 会当函数求值而报错：\n")
(princ (format "  (cl-proclaim (optimize (safety 0))) → %S\n"
               (condition-case err
                   (eval '(cl-proclaim (optimize (safety 0))))
                 (error (error-message-string err)))))
(princ "  正确姿势是 (cl-proclaim '(optimize ...))，或干脆用宏 cl-declaim。\n")
(princ "  在动态绑定里试 (optimize (speed 3) (safety 0))，看它改了哪些变量：\n")
(princ (format "  %S\n"
               (let ((cl--optimize-speed nil)
                     (cl--optimize-safety nil)
                     (byte-optimize nil)
                     (byte-compile-delete-errors nil))
                 (cl-declaim (optimize (speed 3) (safety 0)))
                 (list cl--optimize-speed cl--optimize-safety
                       byte-optimize byte-compile-delete-errors))))
(princ "  speed 3 → byte-optimize=t；safety 0 → byte-compile-delete-errors=t，\n")
(princ "  同时 cl--optimize-speed/safety 记下数值，供后面两节验证。\n")

;;; ---------- 14) optimize (safety) 对 &key 检查的影响 ----------
(princ "\n== 14) safety 0 关掉关键字检查，safety 3 保留 ==\n")
(let ((body (concat
            "(cl-declaim (optimize (safety 0)))\n"
            "(cl-defun ch43-fast (&key a) a)\n"
            "(cl-declaim (optimize (safety 3)))\n"
            "(cl-defun ch43-safe (&key a) a)\n"))
      (read (lambda ()
              (list (if (fboundp 'ch43-fast)
                        (condition-case err
                            (list 'returned (ch43-fast :zz 1))
                          (error (error-message-string err)))
                      nil)
                    (if (fboundp 'ch43-safe)
                        (condition-case err
                            (list 'returned (ch43-safe :zz 1))
                          (error (error-message-string err)))
                      nil))))
      (reset (lambda ()
               (fmakunbound 'ch43-fast)
               (fmakunbound 'ch43-safe))))
  (let ((r (ch43-run3 body read reset)))
    (princ "  源码：safety 0 定义 ch43-fast，safety 3 定义 ch43-safe，各传未知关键字 :zz\n")
    (princ (format "  编译阶段   = %S\n" (nth 0 r)))
    (princ (format "  载入 .elc  = %S\n" (nth 1 r)))
    (princ (format "  载入 .el   = %S\n" (nth 2 r)))))
(princ "  载入 .elc 那一行最能说明问题：fast 不检查直接返回 nil，\n")
(princ "  safe 报 \"Keyword argument :zz not one of (:a)\"。\n")
(princ "  载入 .el 两者都报错：解释执行时检查代码总被生成，safety 管不着。\n")
(princ "  这就是手册说的「safety 0 允许删掉运行期检查」——省检查，\n")
(princ "  但拼错关键字也悄悄吞掉，务必只在热路径上用。\n")

;;; ---------- 15) inline / notinline / warn / special ----------
(princ "\n== 15) 其余四种 proclamation ==\n")
(let ((byte-compile-warnings t)
      (byte-compile-bound-variables nil))
  (cl-declaim (inline ch43-demo-fn))
  (princ (format "  inline    → byte-optimizer 属性 = %S\n"
                 (get 'ch43-demo-fn 'byte-optimizer)))
  (cl-declaim (notinline ch43-demo-fn))
  (princ (format "  notinline → 属性被清成 = %S\n"
                 (get 'ch43-demo-fn 'byte-optimizer)))
  (cl-declaim (warn (unused-variable 0)))
  (princ (format "  warn 0    → byte-compile-warnings = %S\n"
                 byte-compile-warnings))
  (cl-declaim (warn (unused-variable 1)))
  (princ (format "  warn 1    → 恢复为 %S\n" byte-compile-warnings))
  (cl-declaim (special ch43-sp))
  (princ (format "  special   → (memq 'ch43-sp byte-compile-bound-variables) = %S\n"
                 (memq 'ch43-sp byte-compile-bound-variables))))
(princ "  inline 把 byte-compile-inline-expand 挂上，编译时内联展开；\n")
(princ "  notinline 摘掉它；warn 等级 0 禁用、1 启用对应警告；\n")
(princ "  special 把名字登记进 byte-compile-bound-variables，\n")
(princ "  让编译器知道它是动态变量，别按词法变量优化掉。\n")

;;; ---------- 16) cl-the 与 cl-assert ----------
(princ "\n== 16) cl-the 与 cl-assert：类型与断言检查 ==\n")
(princ (format "  cl-the 展开：%S\n"
               (macroexpand-all '(cl-the integer (+ 1 2)))))
(princ (format "  (cl-the integer \"abc\") → %S\n"
               (condition-case err
                   (cl-the integer "abc")
                 (error (error-message-string err)))))
(princ (format "  cl-assert 展开：%S\n"
               (macroexpand-all '(cl-assert (= 1 2)))))
(princ (format "  (cl-assert (= 1 2)) → %S\n"
               (condition-case err
                   (cl-assert (= 1 2))
                 (error (error-message-string err)))))
(princ "  两者都受 speed/safety 控制：speed 3 且 safety 不为 3 时整个\n")
(princ "  检查消失，只留原表达式。cl-the 返回检查过的值，cl-assert 返回 nil。\n")

;;; ---------- 17) 哪些 cl- 名字已经废弃 ----------
(princ "\n== 17) 废弃名单：只查属性，绝不实际调用 ==\n")
(dolist (sym '(cl-gensym cl-locally cl-declare cl-with-accessors))
  (princ (format "  %-16s byte-obsolete-info = %S\n"
                 sym (get sym 'byte-obsolete-info))))
(princ "  (旧名 新名 版本) 三元组：cl-gensym 让位给 gensym，cl-locally\n")
(princ "  让位给 progn（31.1 起废弃）；cl-with-accessors 还没废弃。\n")
(princ "  判断一个 cl- 名字能不能用，查这个属性即可，不必真调用它。\n")

(princ "==== 43 结束 ====\n")
