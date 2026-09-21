;;;; ============================================================
;;;; examples/19_clos/main.lisp — CLOS I：类、泛型函数与方法
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defclass 槽选项全家：:initarg / :initform / :accessor / :reader
;;;;   2. make-instance / slot-value / with-slots / with-accessors
;;;;   3. defgeneric + defmethod：按**参数类型**分派
;;;;   4. 多分派：按两个参数的类型组合选方法（CLOS 的招牌）
;;;;   5. 继承 + call-next-method
;;;;   6. :default-initargs 与 :initform 的分工
;;;;   7. print-object：自定义打印（跨实现一致的输出就靠它）
;;;;   8. initialize-instance :after：构造校验钩子
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. defclass
;;; ----------------------------------------------------------

;; initform 里引用的变量必须**先**定义（SBCL 在编译期就查）
(defparameter *person-counter* 0)

(defclass person ()
  ((name  :initarg :name
          :initform "无名氏"
          :accessor person-name
          :documentation "姓名")
   (age   :initarg :age
          :initform 0
          :accessor person-age
          :type integer
          :documentation "年龄")
   (id    :reader person-id           ; 只读槽：外面不能 setf
          :initform (incf *person-counter*)))
  (:documentation "人员基类"))

;; 槽选项速记：
;;   :initarg  make-instance 时的关键字
;;   :initform 没传时的默认值（每次构造时求值）
;;   :accessor/:reader/:writer  自动生成的泛型访问方法
;;   :type     类型声明（配合 (optimize (safety 3)) 才强制检查）
;;   :allocation :class  类级共享槽（20 章演示）

(let ((p1 (make-instance 'person :name "张三" :age 30))
      (p2 (make-instance 'person)))                  ; 全默认
  (format t "p1: ~A，~A 岁~%" (person-name p1) (person-age p1))
  (format t "p2 默认: ~A，~A 岁~%" (person-name p2) (person-age p2))
  (setf (person-age p1) 31)
  (format t "setf 访问器改槽: ~A~%" (person-age p1))
  (format t "只读槽 id 各自递增: p1=~A p2=~A~%" (person-id p1) (person-id p2)))


;;; ----------------------------------------------------------
;;; 2. slot-value 与 with-slots
;;; ----------------------------------------------------------

(let ((p (make-instance 'person :name "直取" :age 20)))
  ;; slot-value 绕过访问器直接读写（调试用；正式代码走访问器）
  (format t "slot-value 直取: ~A~%" (slot-value p 'name))
  (setf (slot-value p 'age) 21)
  (format t "slot-value 直写: ~A~%" (slot-value p 'age))
  (format t "slot-boundp: name ~A，email(不存在该槽) → 报错被抓住: ~A~%"
          (slot-boundp p 'name)
          (handler-case (slot-boundp p 'email)
            (error () :槽不存在))))

;; with-slots 把槽当局部变量用（内部是 symbol-macrolet，15 章埋过伏笔）
(defun show-person (p)
  (with-slots (name age) p
    (format t "with-slots: ~A / ~A~%" name age)))
(show-person (make-instance 'person :name "王五" :age 28))

;; with-accessors 走访问器（名字可以和槽不同）
(defun show-person-2 (p)
  (with-accessors ((n person-name) (a person-age)) p
    (format t "with-accessors: ~A / ~A~%" n a)))
(show-person-2 (make-instance 'person :name "赵六" :age 40))


;;; ----------------------------------------------------------
;;; 3. 泛型函数：按参数类型分派
;;; ----------------------------------------------------------

;; 名字不能叫 describe——它是 CL 标准函数，defgeneric 直接拒绝
;; （报 DESCRIBE already names an ordinary function，--non-interactive
;;  下整个文件终止；SBCL 对 CL 包还有包锁）
(defgeneric describe-thing (obj)
  (:documentation "按类型分派的描述。"))

(defmethod describe-thing ((p person))
  (format nil "人员 ~A（~A 岁）" (person-name p) (person-age p)))
(defmethod describe-thing ((s string))
  (format nil "字符串，长 ~A" (length s)))
(defmethod describe-thing ((n integer))
  (format nil "整数 ~A" n))

;; 调用演示挪到第 5 节之后：CLISP 对「给已调用过的泛型追加方法」
;; 会发 WARNING（第 5 节还要给 employee 加方法），先把方法都定义齐
;; 没有任何方法匹配 → no-applicable-method 错误（20 章演示怎么接）


;;; ----------------------------------------------------------
;;; 4. 多分派：两个参数一起决定方法
;;; ----------------------------------------------------------

(defclass dog () ())
(defclass cat () ())
(defclass robot () ())

(defgeneric meet (a b)
  (:documentation "两个角色相遇；方法按两个参数的**类型组合**选择。"))

(defmethod meet ((a dog) (b dog)) "狗和狗：摇尾巴转圈")
(defmethod meet ((a dog) (b cat)) "狗和猫：猫炸毛")
(defmethod meet ((a cat) (b robot)) "猫和机器人：无视")
(defmethod meet (a b) "其他组合：互相打量")          ; 无特化 = 兜底

(let ((d (make-instance 'dog)) (c (make-instance 'cat)) (r (make-instance 'robot)))
  (format t "多分派: ~A | ~A | ~A~%"
          (meet d d) (meet d c) (meet c r))
  (format t "兜底: ~A~%" (meet r d)))
;; 单分派语言（Java/C++）里这得写成 a.meet(b) 再在 b 上做二次
;; instanceof/visitor——CLOS 把它做成了语言原生能力


;;; ----------------------------------------------------------
;;; 5. 继承与 call-next-method
;;; ----------------------------------------------------------

(defclass employee (person)
  ((company :initarg :company :accessor employee-company :initform "自由职业"))
  (:default-initargs :age 18))     ; 该类实例的默认 :age（见第 6 节）

(defmethod describe-thing ((e employee))
  (format nil "~A｜就职于 ~A"
          (call-next-method)        ; 复用 person 的方法（沿着类链）
          (employee-company e)))

(let ((e (make-instance 'employee :name "孙八" :company "ACME")))
  (format t "继承+复用: ~A~%" (describe-thing e))
  (format t "类链: employee 的 age 用了类默认 18 → ~A~%" (person-age e)))

;; typep 对类一样工作；实例的类型检查跨实现
(let ((e (make-instance 'employee)))
  (format t "typep 继承链: 是 employee ~A，也是 person ~A~%"
          (typep e 'employee) (typep e 'person)))

;; 现在方法定义齐了，把第 3 节欠的分派演示补上
(format t "分派: ~A | ~A | ~A~%"
        (describe-thing (make-instance 'person :name "钱七" :age 35))
        (describe-thing "hello")
        (describe-thing 42))


;;; ----------------------------------------------------------
;;; 6. :default-initargs vs :initform
;;; ----------------------------------------------------------

;; :initform 是「这个槽的默认值」（槽级，谁实例化都用它）；
;; :default-initargs 是「make-instance 没传某 :initarg 时补什么」
;;（类级，会**压过**槽的 :initform）。
;; 坑：default-initargs 的表达式是普通词法形式，**不能引用同一次
;; 构造的其他 initarg**（两实现一个报未定义变量、一个悄悄给 NIL）
;; ——需要联动的默认值请放进 initialize-instance :after
(defclass account ()
  ((owner :initarg :owner :accessor account-owner :initform "槽级默认")
   (label :initarg :label :accessor account-label :initform "槽级默认"))
  (:default-initargs :owner "类级默认" :label "类级默认"))

(let ((a (make-instance 'account))
      (b (make-instance 'account :owner "李雷" :label "工资卡")))
  (format t "default-initargs 压过 initform: ~A / ~A~%"
          (account-owner a) (account-label a))
  (format t "显式传入优先: ~A / ~A~%" (account-owner b) (account-label b)))


;;; ----------------------------------------------------------
;;; 7. print-object：自定义打印
;;; ----------------------------------------------------------

;; #<...> 形态是「不可读回」对象的标准样子；print-unreadable-object
;; 负责包上 #<类名 ...>。自定义之后，跨实现打印一个对象就完全可控
(defmethod print-object ((p person) stream)
  (print-unreadable-object (p stream :type t :identity nil)
    (format stream "~A/~A岁" (person-name p) (person-age p))))

(let ((p (make-instance 'person :name "打印测试" :age 33)))
  (format t "print-object: ~A~%" p)
  (format t "print-object(~S): ~S~%" p p))


;;; ----------------------------------------------------------
;;; 8. initialize-instance :after：构造校验
;;; ----------------------------------------------------------

(defmethod initialize-instance :after ((p person) &key)
  ;; 所有槽已按 initarg/initform 填好，这里是校验/补正的最后机会
  (when (> (person-age p) 150)
    (error 'simple-error
           :format-control "年龄 ~A 超出合理范围"
           :format-arguments (list (person-age p)))))

(format t "构造校验通过: ~A~%"
        (describe-thing (make-instance 'person :name "百岁" :age 100)))
(format t "构造校验拦截: ~A~%"
        (handler-case (make-instance 'person :name "妖" :age 999)
          (error () :年龄越界被拦)))


(format t "==== 19 结束 ====~%")
