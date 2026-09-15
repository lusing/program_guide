;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 23 - 宏：编译期展开的代码生成器
;;;   defmacro、backquote、变量捕获、 Macroexpand
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "23-macros.el")'
;;; 运行：emacs -Q --batch -l 23-macros.el
;;; ============================================================



(require 'seq)

;;; 1) 函数和宏的根本区别：
;;;    函数 —— 参数先求值，再传进去；
;;;    宏   —— 参数**不求值**，原样传进来，宏返回一个「新的表达式」，
;;;            这个表达式在宏的位置上被求值。
;;;    所以宏能做函数做不到的事：发明新的控制结构、避免参数被多次求值之外的开销。

(defmacro demo-incr (var)
  "把 VAR 加 1（宏版本，为了演示语法）。"
  (list 'setq var (list '1+ var)))

(defvar demo-n 10)
(demo-incr demo-n)
(princ (format "1) 宏展开结果: %S，执行后 n = %S\n"
               (macroexpand-1 '(demo-incr demo-n)) demo-n))

;;; 2) 手写 list 拼表达式太痛苦，用 backquote（`）：
;;;      `  反引号开始模板
;;;      ,  逗号 = 求值并插入
;;;      ,@ 逗号@ = 求值（结果必须是列表）并**摊平**插入
;;;    上面那个宏用 backquote 写就是这样 —— 可读性天差地别。
(defmacro demo-incr2 (var)
  "把 VAR 加 1（backquote 版本）。"
  `(setq ,var (1+ ,var)))
(princ (format "2) backquote 写法展开: %S\n" (macroexpand-1 '(demo-incr2 demo-n))))
(demo-incr2 demo-n)
(princ (format "   执行后 n = %S\n" demo-n))

;;; 3) 宏的价值在于「发明控制结构」。下面这个 unless 的孪生兄弟：
;;;    只有条件为真才执行。
(defmacro demo-when-let (binding &rest body)
  "绑定 BINDING，若其值非 nil 则执行 BODY。
BINDING 形如 (VAR EXPR)。"
  (declare (indent 1) (debug (sexp body)))
  `(let ((,(car binding) ,(cadr binding)))
     (when ,(car binding)
       ,@body)))
(princ (format "3) when-let 展开: %S\n"
               (macroexpand-1 '(demo-when-let (x 5) (princ x)))))
(demo-when-let (found (seq-position '(a b c) 'b))
  (princ (format "   找到 b，位置 = %S\n" found)))
(demo-when-let (missing (seq-position '(a b c) 'z))
  (princ (format "   这行不会执行: %S\n" missing)))

;;; 4) 【大坑】变量捕获（variable capture）。
;;;    宏展开时引入的绑定名，如果正好和调用方的变量名撞上，
;;;    调用方的代码就会被「劫持」—— 而且完全看不出为什么。
(defmacro demo-bad-capture (body)
  "错误示范：宏内部用了固定的名字 x。"
  `(let ((x 99))
     ,body))
(princ (format "4) 展开式: %S\n" (macroexpand-1 '(demo-bad-capture x))))
(princ (format "   调用方 (let ((x 1)) ...) 里拿到: %S  <- 期望 (1 1)，实际第一个被劫持\n"
               (let ((x 1)) (list (demo-bad-capture x) x))))

;;; 5) 修法：用 make-symbol 造一个「未 interned」的符号，
;;;    它跟任何用户写的符号都不 eq，自然不可能撞名。
;;;    展开式里显示为 #:x 这种带 # 前缀的形式。
(defmacro demo-good-capture (body)
  "正确示范：用 make-symbol 生成唯一符号。"
  (let ((sym (make-symbol "x")))
    `(let ((,sym 99))
       ,body)))
;;;    想看清 #: 前缀，要把 print-gensym 打开（默认是 nil，
;;;    于是未 intern 的符号打印出来和普通的 x 一模一样，很容易看漏）。
(princ (format "5) 展开式: %S\n"
               (let ((print-gensym t))
                 (prin1-to-string (macroexpand-1 '(demo-good-capture x))))))
(princ (format "   调用方的 x 不受影响: %S\n"
               (let ((x 1)) (list (demo-good-capture x) x))))

;;; 6) 参数求值次数。宏的参数会被**直接塞进展开式**，
;;;    塞几次就求值几次 —— 这是新手最容易踩的雷。
(defmacro demo-bad-double (x)
  "错误示范：X 会被求值两次。"
  `(+ ,x ,x))
(defvar demo-side-effect 0)
(defun demo-bump ()
  "带副作用的函数。"
  (setq demo-side-effect (1+ demo-side-effect))
  1)
(princ (format "6) 求值两次: 结果 = %S，副作用执行了 %S 次\n"
               (demo-bad-double (demo-bump)) demo-side-effect))

;;; 7) 调试宏的三个工具：
;;;    macroexpand-1  展开一层
;;;    macroexpand    反复展开直到不再是宏
;;;    M-x pp-macroexpand-last-sexp  在 Emacs 里漂亮地打印上个性别的展开式
(princ (format "7) macroexpand-1: %S\n"
               (macroexpand-1 '(demo-when-let (a 1) a))))
(princ (format "   macroexpand:   %S\n"
               (macroexpand '(demo-when-let (a 1) a))))

;;; 8) 【坑】宏在**编译期**展开，所以它只能用到编译期已知的东西。
;;;    宏体里不能引用「运行时才知道的变量」—— 那个值根本还不存在。
;;;    如果确实需要在编译期算点东西，用 eval-when-compile 包起来。
(defmacro demo-compile-time-info ()
  "在编译期把版本信息烧进代码。"
  `,(eval-when-compile (format "compiled-by-emacs-%d" emacs-major-version)))
(princ (format "8) eval-when-compile: %S\n" (demo-compile-time-info)))

;;; 9) declare 声明：
;;;      (indent N)         告诉 Emacs 怎么缩进这个宏（1 = 像 when 一样）
;;;      (debug SPEC)       告诉 Edebug 怎么单步
;;;      (doc-string N)     第 N 个参数是文档字符串
;;;    没有 (indent 1) 的话，你的宏缩进会很丑。
(princ "9) declare (indent 1) 决定缩进，本示例的 demo-when-let 就用了\n")

;;; 10) 什么时候不该写宏：
;;;     能用函数就用函数。函数能作为值传递、能出现在 mapcar 里、
;;;     能被 advice、能进 hook —— 宏一样都不行。
;;;     只在「需要控制求值时机」或「要发明新语法」时才写宏。
(princ (format "10) 函数是 %S，宏是 %S —— 宏不能当值传\n"
               (functionp #'demo-incr)
               (macrop #'demo-incr)))

(princ "==== 23 结束 ====\n")
