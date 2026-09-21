;;;; ============================================================
;;;; examples/15_macros_adv/main.lisp — 宏 II：卫生、捕获与宏工程
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 变量捕获：写宏最容易犯的错（现场复现 + 修法）
;;;;   2. gensym：保证不撞名的临时符号
;;;;   3. with-gensyms：宏工程的标准开场白（自己实现一遍）
;;;;   4. 一次求值（once-only）：用户给的表达式别偷偷算两遍
;;;;   5. 符号宏 symbol-macrolet / define-symbol-macro
;;;;   6. eval-when：编译期 / 加载期 / 运行期的三态开关
;;;;   7. 宏的调试与「什么时候不要写宏」
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 变量捕获：现场复现
;;; ----------------------------------------------------------

;; 天真的 swap：临时变量写死叫 temp
(defmacro bad-swap (a b)
  `(let ((temp ,a))
     (setf ,a ,b)
     (setf ,b temp)))

;; 展开（无 gensym，可安全打印对照）：
(let ((*print-pretty* nil))
  (format t "bad-swap 展开: ~S~%" (macroexpand-1 '(bad-swap x y))))

;; 调用者恰好也叫 temp → 宏体内的 temp **捕获**了用户的 temp，
;; 交换悄悄变成「读 A 写 A」的乌龙
(let ((temp 1) (val 2))
  (bad-swap temp val)
  (format t "踩坑现场: temp=~A val=~A（val 根本没变）~%" temp val))

;; 没撞名时碰巧正常——所以这种 bug 特别阴险：测试用例一换名字就翻车
(let ((x 1) (y 2))
  (bad-swap x y)
  (format t "不撞名时正常: x=~A y=~A~%" x y))


;;; ----------------------------------------------------------
;;; 2. gensym 修法
;;; ----------------------------------------------------------

(defmacro good-swap (a b)
  (let ((tmp (gensym "SWAP-")))
    `(let ((,tmp ,a))
       (setf ,a ,b)
       (setf ,b ,tmp))))

;; 再撞名也不怕：gensym 生成的符号与任何 intern 过的符号都不同
(let ((temp 1) (val 2))
  (good-swap temp val)
  (format t "修好后: temp=~A val=~A（真正的交换）~%" temp val))


;;; ----------------------------------------------------------
;;; 3. with-gensyms：把卫生写法模板化
;;; ----------------------------------------------------------

;; 每个宏都手写 (let ((g1 (gensym)) ...)) 太啰嗦——把它做成宏。
;; 注意改名：CLISP 的 EXT 包里自带一个 with-gensyms（重定义会告警），
;; 所以这里叫 my-with-gensyms；实际项目直接用 alexandria:with-gensyms
(defmacro my-with-gensyms (names &body body)
  `(let ,(mapcar (lambda (n)
                   `(,n (gensym ,(string n))))
                 names)
     ,@body))

;; 用宏写宏：标准姿势
(defmacro silent-swap (a b)
  (my-with-gensyms (tmp)
    `(let ((,tmp ,a))
       (setf ,a ,b)
       (setf ,b ,tmp))))

(let ((p 10) (q 20))
  (silent-swap p q)
  (format t "with-gensyms 版: p=~A q=~A~%" p q))


;;; ----------------------------------------------------------
;;; 4. once-only：用户表达式别算两遍
;;; ----------------------------------------------------------

;; 又一个经典坑：(twice expr) 想把 expr 的值用两次
(defmacro bad-twice (expr)
  `(list ,expr ,expr))          ; expr 被展开成两份 → 副作用跑两遍

(let ((n 0))
  (format t "bad-twice: ~S，副作用跑了 ~A 次~%"
          (bad-twice (progn (incf n) n)) n))

;; once-only 的手工实现：先求值一次存进 gensym，再引用 gensym
(defmacro once-only-twice (expr)
  (my-with-gensyms (val)
    `(let ((,val ,expr))
       (list ,val ,val))))

(let ((n 0))
  (format t "once-only: ~S，副作用只跑 ~A 次~%"
          (once-only-twice (progn (incf n) n)) n))


;;; ----------------------------------------------------------
;;; 5. 符号宏
;;; ----------------------------------------------------------

;; symbol-macrolet：让一个「符号」展开成表达式——变量看起来是变量，
;; 其实每次出现都被替换
(let ((table (make-hash-table)))
  (setf (gethash :hits table) 0)
  (symbol-macrolet ((hits (gethash :hits table)))
    (incf hits)
    (incf hits)
    (format t "符号宏 hits → ~A（自动展开成 gethash/setf）~%" hits)))

;; define-symbol-macro 定义全局的；它就是 defvar 背后的机制之一，
;; CLOS 的 with-slots 也拿它实现（19 章会用到）


;;; ----------------------------------------------------------
;;; 6. eval-when：三态开关
;;; ----------------------------------------------------------

;; 顶层形式默认只在**加载/编译**时执行；eval-when 可以精确控制
(eval-when (:execute)
  ;; 只在「运行期」求值——compile-file 时不执行，load 时也不执行，
  ;; 只有把这段代码当程序直接跑（或 REPL 里求值）才执行
  (format t "eval-when :execute → 只有直接执行时看得见这行~%"))

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; 三态全开 = 通常的 defun/defmacro 行为
  (defun helper-from-eval-when ()
    :定义于-eval-when))

(format t "三态全开的定义可用: ~A~%" (helper-from-eval-when))
;; 经典用途：编译期需要的宏/常量，配 :compile-toplevel，否则
;; 「同一个文件里先定义宏、后面就用」在 compile-file 时会翻车


;;; ----------------------------------------------------------
;;; 7. 调试宏 & 什么时候不要写宏
;;; ----------------------------------------------------------
;;;;
;;;; 调试三板斧：
;;;;   1. (macroexpand-1 '你的调用) 看展开对不对（SLIME/sly 里 TAB 即可）
;;;;   2. compile-file 静态兜底：括号错位、shape 错配当场报出来
;;;;   3. 展开正确再查运行期——问题就一定不在宏本身
;;;;
;;;; 不要写宏的场景（宁函数勿宏）：
;;;;   · 参数本来就该求值（函数语义就够）
;;;;   · 只是想「少打几个字」——写个普通函数/局部函数更好
;;;;   · 运行期才拿得到「要生成什么代码」——宏是编译期的，用闭包
;;;;   · 需要当一等公民传来传去——宏不能 funcall，函数可以


(format t "~%==== 15 结束 ====~%")
