;;;; ============================================================
;;;; examples/20_clos_adv/main.lisp — CLOS II：方法组合与元对象
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. :before / :after / :around 的完整执行顺序（审计日志实战）
;;;;   2. 标准方法组合的展开形态：最特化优先、call-next-method 链
;;;;   3. :allocation :class 类级共享槽
;;;;   4. eql 特化器：按**特定值**分派（ DSL/单例的利器）
;;;;   5. no-applicable-method：兜住「没有任何方法」的调用
;;;;   6. 非标准方法组合：+ / and / or / list / max / progn
;;;;   7. MOP 的一小步：class-of / find-class / 类的运行期操作
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. :before / :after / :around 完整顺序
;;; ----------------------------------------------------------

(defclass shape ()
  ((name :initarg :name :accessor shape-name :initform "?")))
(defclass circle (shape)
  ((radius :initarg :radius :accessor circle-radius :initform 1)))

(defgeneric draw (s)
  (:documentation "画出图形；观察方法组合的顺序。"))

(defmethod draw :around ((s shape))
  (format t "  [around 入] ~A~%" (shape-name s))
  (prog1 (call-next-method)
    (format t "  [around 出] ~A~%" (shape-name s))))

(defmethod draw :before ((s shape))
  (format t "  [before] 开画布~%"))

(defmethod draw ((s shape))
  (format t "  [primary] 画一个通用形状~%"))

(defmethod draw :after ((s shape))
  (format t "  [after] 收画布~%"))

;; 子类主方法：只覆盖 primary，其余照常继承生效
(defmethod draw ((c circle))
  (format t "  [primary] 画圆，半径 ~A~%" (circle-radius c)))

(format t "-- shape --~%")
(draw (make-instance 'shape :name "矩形"))
(format t "-- circle --~%")
(draw (make-instance 'circle :name "大圆" :radius 5))
;; 顺序规则（标准组合）：最特化的 :around → 所有 :before（最特化先）
;; → 最特化的 primary（call-next-method 往上走）→ 所有 :after
;;（**最泛化先**，与 before 相反）→ :around 收尾


;;; ----------------------------------------------------------
;;; 2. call-next-method 链
;;; ----------------------------------------------------------

(defclass a () ())
(defclass b (a) ())
(defclass c (b) ())

(defgeneric who (x))
(defmethod who ((x a)) "A")
(defmethod who ((x b)) (format nil "B→~A" (call-next-method)))
(defmethod who ((x c)) (format nil "C→~A" (call-next-method)))
;; call-next-method 就是「沿特化顺序调下一个可适用的 primary」；
;; 没有「下一个」还调用 → 报错；next-method-p 可以先探一下。
;; 坑（CLISP）：给**已经调用过**的泛型追加方法会发 WARNING 到
;; stderr——方法定义要放在第一次调用之前
(defmethod who :around ((x c))
  (if (next-method-p) (call-next-method) :孤家寡人))

(format t "方法链: ~A~%" (who (make-instance 'c)))
(format t "next-method-p 探测: ~A~%" (who (make-instance 'c)))


;;; ----------------------------------------------------------
;;; 3. :allocation :class
;;; ----------------------------------------------------------

(defclass counter ()
  ((hits :allocation :class      ; 所有实例共享同一份存储
         :initform 0
         :accessor counter-hits)))

(let ((c1 (make-instance 'counter))
      (c2 (make-instance 'counter)))
  (incf (counter-hits c1))
  (incf (counter-hits c1))
  (incf (counter-hits c2))
  (format t "类级槽: c1 看到 ~A，c2 也看到 ~A（同一份）~%"
          (counter-hits c1) (counter-hits c2)))


;;; ----------------------------------------------------------
;;; 4. eql 特化器：按值分派
;;; ----------------------------------------------------------

(defparameter *current-mode* :admin)   ; 单例/配置值的分派

(defgeneric permission (mode resource)
  (:documentation "不同模式对不同资源的权限。"))

(defmethod permission ((mode (eql :admin)) resource) :全权)
(defmethod permission (mode (resource (eql :公开页))) :可读)
(defmethod permission (mode resource) :无权限)

(format t "eql 特化: admin+任何 → ~A，来宾+公开页 → ~A，来客+别的 → ~A~%"
        (permission *current-mode* :数据库)
        (permission :guest :公开页)
        (permission :guest :数据库))


;;; ----------------------------------------------------------
;;; 5. no-applicable-method
;;; ----------------------------------------------------------

(defgeneric only-for-string (x))

(defmethod only-for-string ((s string))
  (format nil "收到: ~A" s))

;; 没有方法匹配时的统一入口（SBCL/CLISP 都支持这个标准泛型）
(defmethod no-applicable-method ((g (eql #'only-for-string)) &rest args)
  (declare (ignore args))
  :不支持这种参数)

(format t "正常: ~A~%" (only-for-string "ok"))
(format t "兜底: ~A~%" (only-for-string 42))


;;; ----------------------------------------------------------
;;; 6. 非标准方法组合
;;; ----------------------------------------------------------

;; + 组合：所有可适用 primary 的返回值**加起来**
(defgeneric score (x) (:method-combination +))

(defclass judge () ())
(defclass strict-judge (judge) ())

(defmethod score + ((j judge)) 1)
(defmethod score + ((j strict-judge)) 2)

(let ((j (make-instance 'strict-judge)))
  (format t "+ 组合: ~A（1 + 2，两层类链都算）~%" (score j)))

;; and 组合：从最特化开始，遇到 NIL 就停
(defgeneric check (x) (:method-combination and))
(defmethod check and ((x judge)) t)
(defmethod check and ((x strict-judge)) :严格通过)

(format t "and 组合: ~A~%" (check (make-instance 'strict-judge)))

;; list 组合：收集所有返回值
(defgeneric voices (x) (:method-combination list))
(defmethod voices list ((x judge)) :基类意见)
(defmethod voices list ((x strict-judge)) :子类意见)

(format t "list 组合: ~S~%" (voices (make-instance 'strict-judge)))
;; 内置还有 or / max / min / progn / append / nconc；自定义组合走 MOP


;;; ----------------------------------------------------------
;;; 7. MOP 的一小步（可移植子集）
;;; ----------------------------------------------------------
;;;;
;;;; 「元对象协议」（MOP）让 CLOS 自己可以用 CLOS 描述——改类、改分派
;;;; 机制都行。但 MOP 的入口包名不跨实现（SBCL 是 SB-MOP、CLISP 是
;;;; CLOS），可移植代码只用下面这些 ANSI 面：
;;;;   class-of / find-class / class-name / make-instance / typep

(let ((c (make-instance 'circle :radius 2)))
  (format t "class-of → ~A~%" (class-name (class-of c)))
  ;; find-class 第二个参数 errorp：默认实现不一（SBCL 直接报错、
  ;; CLISP 发 WARNING）——想要安静的 NIL 就显式传 nil
  (format t "find-class 圆存在: ~A~%" (not (null (find-class 'circle))))
  (format t "find-class 静默失败: ~S~%" (find-class 'no-such-class-xyz nil)))

;; 运行期「造类」的合法姿势：make-instance 一个已存在的类，
;; 或者 defclass 求值（宏也是运行期可调的普通函数家族）
(eval '(defclass late-class () ((slot :accessor late-slot))))
(format t "运行期 defclass: ~A~%"
        (typep (make-instance 'late-class) 'late-class))


(format t "==== 20 结束 ====~%")
