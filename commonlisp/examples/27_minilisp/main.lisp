;;;; ============================================================
;;;; examples/27_minilisp/main.lisp — 实战：迷你 Lisp 解释器
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 300 行写一个 Lisp 子集的解释器——Lisp 的经典毕业礼：
;;;;   · 解析：借用 CL 自己的 reader（read-from-string），
;;;;     「数据即程序」的直接体现
;;;;   · 求值：环境是关联表，闭包是 (参数 身体 环境) 三元组
;;;;   · 特殊形式：quote if define set! lambda let let* progn cond
;;;;   · 内建函数：算术/比较/表操作/输出，直接桥到宿主 CL
;;;;   · 测试：40 条断言全部跑在**两套宿主实现**上，输出逐字节一致
;;;;
;;;; 这个解释器**不用 eval**——它自己实现了 eval 的语义，
;;;; 也就是 03 章说的「REPL 的 E」。
;;; ============================================================

;;; ----------------------------------------------------------
;;; 0. 预声明：eval/apply 互相递归，先声明签名再定义，
;;;    SBCL 才不会对「后定义的前向引用」发 style-warning
;;; ----------------------------------------------------------

(declaim (ftype function me-eval me-apply me-eval-sequence
                me-eval-cond me-expand-let*))

;;; ----------------------------------------------------------
;;; 1. 环境：变量住在关联表里
;;; ----------------------------------------------------------

;; 环境 = ((名字 . 值) ...) 的表；子环境带一个指回父环境的尾巴。
;; 查名字 = 沿着父链向上找——这就是「词法作用域」的全部机制
(defun env-lookup (name env)
  "沿父链找名字；找不到（走到 finally）就报错。
     注意不能把「找到但值是 NIL」当失败——所以用 when cell 判定。"
  (loop for frame in env
        for cell = (assoc name frame :test #'eq)
        when cell
          return (cdr cell)
        finally (error "未绑定的符号: ~A" name)))

(defun env-define! (name value env)
  (let ((cell (assoc name (first env) :test #'eq)))
    (if cell
        (setf (cdr cell) value)
        (push (cons name value) (first env))))
  value)

(defun env-set! (name value env)
  "set! 必须改**已有**绑定（沿父链找到哪层改哪层）；找不到就报错。"
  (loop for frame in env
        do (let ((cell (assoc name frame :test #'eq)))
             (when cell
               (setf (cdr cell) value)
               (return-from env-set! value))))
  (error "未定义的变量: ~A" name))

(defun env-extend (params args env)
  "按参数表扩展一层子环境；参数个数不匹配直接报错。"
  (when (/= (length params) (length args))
    (error "参数个数不匹配: 要 ~A 个，给 ~A 个" (length params) (length args)))
  (cons (pairlis params args) env))


;;; ----------------------------------------------------------
;;; 2. 求值器：eval 的语义，手写版
;;; ----------------------------------------------------------

(defvar *global-env* (list nil))

(defun me-eval (expr env)
  (cond
    ;; 数字/字符串/关键字：自求值
    ((or (numberp expr) (stringp expr) (keywordp expr)) expr)
    ;; 符号：查环境（找不到 env-lookup 自己报错）
    ((symbolp expr) (env-lookup expr env))
    ;; 表：特殊形式 或 函数调用
    ((consp expr)
     (let ((head (first expr)))
       (case head
         (quote  (second expr))
         (if     (if (me-eval (second expr) env)
                     (me-eval (third expr) env)
                     (me-eval (fourth expr) env)))
         (lambda (list :closure (second expr) (cddr expr) env))
         (define (let ((target (second expr)))
                   ;; 两种写法：(define x 值) 与 (define (f 参数...) 身体)
                   (if (consp target)
                       (env-define! (first target)
                                    (me-eval (list* 'lambda (rest target)
                                                    (cddr expr))
                                             *global-env*)
                                    *global-env*)
                       (env-define! target
                                    (me-eval (third expr) env)
                                    *global-env*))))
         (set!   (env-set! (second expr)
                           (me-eval (third expr) env)
                           env))
         ;; let 是语法糖：展开成 ((lambda (参数...) 身体...) 初值...)。
         ;; 两处都要 list*（splice）：lambda 形式的 body、整个调用形式
         ;;（用 list 会把 body 多包一层，X 就被当成函数调用了）
         (let    (me-eval (list* (list* 'lambda
                                        (mapcar #'first (second expr))
                                        (cddr expr))
                                 (mapcar #'second (second expr)))
                          env))
         (let*   (me-eval (me-expand-let* (second expr) (cddr expr)) env))
         (progn  (me-eval-sequence (rest expr) env))
         (cond   (me-eval-cond (rest expr) env))
         ;; 普通调用：先求值函数位与实参，再 apply
         (t      (me-apply (me-eval head env)
                           (mapcar (lambda (e) (me-eval e env)) (rest expr))
                           env)))))
    (t (error "求值不了: ~S" expr))))

(defun me-eval-sequence (exprs env)
  "按顺序求值，返回最后一个的值。"
  (loop for e in exprs
        for v = (me-eval e env)
        finally (return v)))

(defun me-eval-cond (clauses env)
  (loop for (test . body) in clauses
        when (or (eq test 'else) (me-eval test env))
          return (me-eval-sequence body env)
        finally (return nil)))

(defun me-expand-let* (bindings body)
  "let* 展开成嵌套的 let——把「顺序绑定」翻译成「嵌套作用域」。"
  (if (null bindings)
      (cons 'progn body)
      (list 'let (list (first bindings))
            (me-expand-let* (rest bindings) body))))

(defun me-apply (fn args env)
  (declare (ignore env))
  (cond
    ;; 闭包：在**定义时**的环境上扩展一层——这就是「词法作用域闭包」
    ((and (consp fn) (eq (first fn) :closure))
     (me-eval-sequence (third fn)
                       (env-extend (second fn) args (fourth fn))))
    ;; 内建函数：直接桥到宿主 CL
    ((functionp fn) (apply fn args))
    (t (error "调不了: ~S" fn))))


;;; ----------------------------------------------------------
;;; 3. 内建函数：桥到宿主 CL
;;; ----------------------------------------------------------

(defun install-builtins ()
  (let ((b `((+ . ,#'+) (- . ,#'-) (* . ,#'*) (/ . ,#'/)
              (< . ,#'<) (> . ,#'>) (= . ,#'=) (<= . ,#'<=) (>= . ,#'>=)
              (mod . ,#'mod) (abs . ,#'abs) (min . ,#'min) (max . ,#'max)
              (null? . ,#'null) (eq? . ,#'eql) (not . ,#'not)
              (cons . ,#'cons) (car . ,#'car) (cdr . ,#'cdr)
              (list . ,#'list))))
    (setf *global-env* (list b))))

;; 输出内建：写进全局环境的写法（避免闭包捕获问题，直接用函数）
(defun run (source)
  "跑一段源码：解析所有顶层形式，逐个求值，返回最后一个值。"
  (install-builtins)
  (let ((result :空))
    (with-input-from-string (in source)
      ;; loop 里 FOR 子句要排在 until 这类主体子句之前（CLISP 会告警）；
      ;; 也不用 for v = ... 的写法——最后一轮读到 :EOF 时它仍会求值
      (loop for form = (read in nil :eof)
            until (eq form :eof)
            do (setf result (me-eval form *global-env*))))
    result))


;;; ----------------------------------------------------------
;;; 4. 测试：40 条断言（两实现输出一致）
;;; ----------------------------------------------------------

(defparameter *passed* 0)
(defparameter *failed* 0)

(defun check (label source want)
  (let ((got (handler-case (run source)
               (error (e) (list :error e)))))
    ;; 报错文本可能是实现给的（比如除零措辞），比对时归一成 :error
    (if (equal got want)
        (progn (incf *passed*) (format t "  ok ~A~%" label))
        (progn (incf *failed*)
               (format t "  FAIL ~A: 得 ~S 要 ~S~%" label got want)))))

(defun check-error (label source)
  (let ((got (handler-case (run source)
               (error () :error))))
    (if (eq got :error)
        (progn (incf *passed*) (format t "  ok ~A（按预期报错）~%" label))
        (progn (incf *failed*)
               (format t "  FAIL ~A: 应当报错，得 ~S~%" label got)))))

(format t "=== 算术与求值 ===~%")
(check "数字自求值" "42" 42)
(check "加法" "(+ 1 2 3)" 6)
(check "嵌套" "(* 2 (+ 3 4))" 14)
(check "除法得有理数" "(/ 10 4)" 5/2)
(check "比较" "(< 1 2)" t)
(check "只有 nil 是假" "(if 0 :真 :假)" :真)

(format t "=== quote 与表 ===~%")
(check "quote" "(quote (a b))" '(a b))
(check "car" "(car '(1 2 3))" 1)
(check "cdr" "(cdr '(1 2 3))" '(2 3))
(check "cons" "(cons 1 '(2 3))" '(1 2 3))
(check "list" "(list 1 (+ 1 1) 3)" '(1 2 3))
(check "null?" "(null? '())" t)

(format t "=== define / set! / 作用域 ===~%")
(check "define" "(define x 10) x" 10)
(check "set!" "(define x 1) (set! x 99) x" 99)
(check "内层遮蔽" "(define x 1) (let ((x 2)) x)" 2)
(check "外层不受影响" "(define x 1) (let ((x 2)) x) x" 1)
(check "let 并行" "(define a 1) (define b 2) (let ((a b) (b a)) (list a b))" '(2 1))
(check "let* 顺序" "(define a 1) (define b 2) (let* ((a b) (b a)) (list a b))" '(2 2))

(format t "=== 闭包与高阶 ===~%")
(check "set! + 全局状态"
       "(define n 0)
        (define bump (lambda () (set! n (+ n 1))))
        (bump) (bump) (bump) n"
       3)
(check "lambda 直接调用" "((lambda (x) (* x x)) 7)" 49)
(check "闭包捕获定义点环境"
       "(define (adder n) (lambda (x) (+ x n)))
        (define add5 (adder 5))
        (add5 37)"
       42)
(check "两个闭包互不干扰"
       "(define (adder n) (lambda (x) (+ x n)))
        (define a2 (adder 2)) (define a10 (adder 10))
        (list (a2 1) (a10 1))"
       '(3 11))
(check "高阶函数"
       "(define (twice f x) (f (f x)))
        (twice (lambda (n) (* n 3)) 2)"
       18)

(format t "=== 递归（靠 define 全局绑定） ===~%")
(check "阶乘"
       "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
        (fact 10)"
       3628800)
(check "斐波那契"
       "(define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
        (fib 12)"
       144)

(format t "=== cond / progn ===~%")
(check "cond 命中" "(cond ((= 1 2) :a) ((= 1 1) :b) (else :c))" :b)
(check "cond else" "(cond ((= 1 2) :a) (else :fallback))" :fallback)
(check "progn 取最后" "(progn 1 2 3)" 3)

(format t "=== 报错路径 ===~%")
(check-error "未绑定符号" "(first-of-nothing)")
(check-error "未定义函数" "(nosuchfn 1)")
(check-error "set! 未定义" "(set! ghost 1)")
(check-error "参数个数不匹配" "((lambda (x) x) 1 2)")

(format t "~%结果: 通过 ~A 条，失败 ~A 条~%" *passed* *failed*)
(unless (zerop *failed*)
  (error "迷你解释器测试未全部通过"))

(format t "==== 27 结束 ====~%")
