;;;; ============================================================
;;;; examples/10_variables/main.lisp — 变量与作用域
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defparameter 与 defvar：重求值语义不同（经典面试题）
;;;;   2. let 并行绑定 vs let* 顺序绑定
;;;;   3. 词法作用域：内层遮蔽 + 闭包捕获
;;;;   4. 动态作用域：defparameter + let 重绑，沿**调用链**生效
;;;;   5. setf 家族：incf/decf/push/rotatef/shiftf，作用在「位置」上
;;;;   6. defconstant 常量与命名约定
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. defparameter vs defvar
;;; ----------------------------------------------------------

;; 两者都定义**全局特殊变量**（动态作用域，见第 4 节）。
;; 区别在「再次执行定义形式」时：
;;   defparameter **每次都重新赋初值**
;;   defvar     **只在没有值时才赋**（已经有值就跳过）
(defparameter *param-val* 1)
(defvar *var-val* 1)

;; 模拟「再次求值定义形式」（重新加载文件就是这样的）
(eval '(defparameter *param-val* 100))   ; 重新赋成 100
(setf *var-val* 100)                     ; 先手工改成 100
(eval '(defvar *var-val* 999))           ; 已有值 → 保持 100

(format t "defparameter 重新定义 → 重置: ~A~%" *param-val*)
(format t "defvar 重新定义 → 保持: ~A~%" *var-val*)

;; 命名约定：全局变量两侧加 * （读作 "earmuffs"），
;; 提醒「这是特殊变量，别被 let 意外重绑」


;;; ----------------------------------------------------------
;;; 2. let 并行 vs let* 顺序
;;; ----------------------------------------------------------

(let ((a 1) (b 2))
  ;; let 的所有初值**在外层环境**求值 → 新绑定同时看到旧值，可以交换
  (let ((x b) (y a))
    (format t "let 并行: x=~A y=~A（都用旧值，交换成功）~%" x y)))

(let ((b 2))
  ;; let* 后面的绑定能看见前面的**新**绑定 → 顺序依赖
  (let* ((x b) (y x))
    (format t "let* 顺序: x=~A y=~A（y 看到的是新 x，交换失败）~%" x y)))


;;; ----------------------------------------------------------
;;; 3. 词法作用域与闭包
;;; ----------------------------------------------------------

;; 内层遮蔽：名字相同的新绑定暂时「盖住」外层
(let ((x 1))
  (let ((x 2))
    (format t "内层 x: ~A~%" x))
  (format t "回到外层 x: ~A~%" x))

;; 闭包：函数捕获的是**变量本身**（不是值的快照）
(defun make-counter ()
  (let ((count 0))
    (lambda () (incf count))))

(let ((c1 (make-counter))
      (c2 (make-counter)))
  (funcall c1) (funcall c1)
  (format t "c1 数到 ~A，c2 独立计数 ~A~%" (funcall c1) (funcall c2)))

;; 词法捕获在动态重绑下也不受影响（下一节对照）
(defun capture-lexical ()
  (let ((lex 10))
    (lambda () lex)))

(let ((f (capture-lexical)))
  (format t "闭包记住的是创建时的词法环境: ~A~%" (funcall f)))


;;; ----------------------------------------------------------
;;; 4. 动态作用域：特殊变量沿调用链
;;; ----------------------------------------------------------

;; *standard* 是特殊变量：函数体内看到的是**调用点**的绑定
(defparameter *scale* 1)

(defun scale-it (x) (* x *scale*))

(format t "默认刻度: ~A~%" (scale-it 5))
(let ((*scale* 10))
  (format t "let 重绑期间（沿调用链）: ~A~%" (scale-it 5)))
(format t "let 结束后恢复: ~A~%" (scale-it 5))

;; symbol-value 看到的也是「当前动态绑定」
(let ((*scale* 7))
  (format t "symbol-value 在动态绑定内: ~A~%" (symbol-value '*scale*)))

;; 经典用法：*print-case* / *package* / *standard-output* 都是特殊变量，
;; (let ((*print-case* :downcase)) ...) 包一段就是临时的打印设置
(format t "动态重绑 *print-case*: ")
(let ((*print-case* :downcase))
  (format t "~S~%" 'Hello-Up))


;;; ----------------------------------------------------------
;;; 5. setf 家族：作用在「位置」上
;;; ----------------------------------------------------------

;; setf 的第一个参数是**位置表达式**（place），不只是变量：
;; 变量、数组下标、结构体字段、哈希键、car/cdr……都行
(let ((v (vector 1 2 3))
      (l (list 1 2))
      (ht (make-hash-table)))
  (setf (aref v 1) :数组位置)
  (setf (car l) :表头)
  (setf (gethash :键 ht) :哈希位置)
  (format t "位置们: ~S ~S ~A~%"
          v l (gethash :键 ht)))

;; 复合更新
(let ((x 5))
  (incf x)          ; x = x + 1
  (decf x 10)       ; x = x - 10
  (format t "incf/decf 后: ~A~%" x))

(let ((a 1) (b 2))
  (rotatef a b)     ; 交换
  (format t "rotatef: a=~A b=~A~%" a b))

(let ((a 1) (b 2) (c 3))
  (shiftf a b c 99) ; 左移：a←b←c←99
  (format t "shiftf: a=~A b=~A c=~A~%" a b c))

;; push 作用在「位置」上同样成立（比如压入哈希键下的表）
(let ((ht (make-hash-table)))
  (push 1 (gethash :栈 ht nil))
  (push 2 (gethash :栈 ht nil))
  (format t "push 哈希里的表: ~S~%" (gethash :栈 ht)))


;;; ----------------------------------------------------------
;;; 6. defconstant 常量
;;; ----------------------------------------------------------

;; 常量只应绑定「真正恒定」的值（数字/符号/不可变结构）；
;; 名字两侧加 + 是约定
(defconstant +days-per-week+ 7)
(format t "常量: ~A~%" +days-per-week+)
;; 常量不可 setf：直接写 (setf +days-per-week+ 8) 在 SBCL 上是**编译期**
;; 错误（整个文件都加载不了）；用 eval 包起来则错误发生在运行期、可被
;; handler-case 抓住——但 SBCL 仍会把编译诊断打到 stderr。所以记住结论：
;; 常量就别 setf，注释里说清楚即可（两个实现都拒绝）


;;; ----------------------------------------------------------
;;; 7. 未绑定变量 vs 未初始化（说明）
;;; ----------------------------------------------------------
;;;;
;;;; 读一个从未绑定的变量（哪怕只是拼错名字）在**编译期**就能被抓到
;;;; （SBCL 给 warning，CLISP 运行期报错）；两个实现都不会像动态语言
;;;; 那样静默给 nil。全局特殊变量用 boundp 探测，词法变量则由编译器
;;;; 静态保证。


(format t "~%==== 10 结束 ====~%")
