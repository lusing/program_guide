;;;; ============================================================
;;;; 06-clos.lisp — CLOS 面向对象编程
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defclass 定义类
;;;;   2. make-instance 创建实例
;;;;   3. defgeneric / defmethod 泛型函数与方法
;;;;   4. 继承与多态
;;;;   5. 方法组合（:before / :after / :around）
;;;;   6. slot-value 与访问器
;;;;   7. 类重定义与实例更新
;;;;   8. 常用内置方法（print-object / initialize-instance）
;;;;
;;;; 运行方式：sbcl --script 06-clos.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. defclass 定义类
;;; ----------------------------------------------------------

(format t "~%=== defclass ===~%")

(defclass person ()
  ((name    :initarg :name
            :initform "无名氏"
            :accessor person-name
            :documentation "姓名")
   (age     :initarg :age
            :initform 0
            :accessor person-age
            :type integer
            :documentation "年龄")
   (email   :initarg :email
            :initform ""
            :accessor person-email
            :documentation "邮箱"))
  (:documentation "人员基类"))

;; :initarg  — 创建实例时的关键字参数
;; :initform — 默认值
;; :accessor — 自动生成读写方法
;; :reader   — 只生成读方法
;; :writer   — 只生成写方法
;; :type     — 类型声明
;; :allocation :class — 类级别槽（所有实例共享）


;;; ----------------------------------------------------------
;;; 2. make-instance 创建实例
;;; ----------------------------------------------------------

(format t "~%=== make-instance ===~%")

(let ((p1 (make-instance 'person :name "张三" :age 30))
      (p2 (make-instance 'person :name "李四" :age 25 :email "li@example.com")))
  (format t "p1: ~A, ~A岁~%" (person-name p1) (person-age p1))
  (format t "p2: ~A, ~A岁, ~A~%" (person-name p2) (person-age p2) (person-email p2))

  ;; 修改槽值
  (setf (person-age p1) 31)
  (format t "修改后 p1 年龄: ~A~%" (person-age p1)))


;;; ----------------------------------------------------------
;;; 3. defgeneric / defmethod
;;; ----------------------------------------------------------

(format t "~%=== 泛型函数与方法 ===~%")

;; defgeneric 定义泛型函数接口
(defgeneric describe (obj)
  (:documentation "描述对象"))

;; defmethod 为特定类型实现方法
(defmethod describe ((p person))
  (format nil "~A，~A岁" (person-name p) (person-age p)))

(let ((p (make-instance 'person :name "王五" :age 28)))
  (format t "~A~%" (describe p)))

;; 为内置类型定义方法
(defmethod describe ((s string))
  (format nil "字符串，长度 ~A" (length s)))

(defmethod describe ((n integer))
  (format nil "整数 ~A" n))

(format t "~A~%" (describe "hello"))
(format t "~A~%" (describe 42))


;;; ----------------------------------------------------------
;;; 4. 继承与多态
;;; ----------------------------------------------------------

(format t "~%=== 继承 ===~%")

;; 单继承
(defclass employee (person)
  ((company   :initarg :company :accessor employee-company :initform "")
   (salary    :initarg :salary  :accessor employee-salary  :initform 0)
   (position  :initarg :position :accessor employee-position :initform "职员"))
  (:documentation "员工类，继承自 person"))

;; 多继承
(defclass manager (employee)
  ((team-size :initarg :team-size :accessor manager-team-size :initform 0))
  (:documentation "经理类"))

;; 子类方法覆盖
(defmethod describe ((e employee))
  (format nil "~A（~A的员工，职位：~A）"
          (call-next-method)  ; 调用父类方法
          (employee-company e)
          (employee-position e)))

(defmethod describe ((m manager))
  (format nil "~A，管理 ~A 人团队"
          (call-next-method)
          (manager-team-size m)))

(let ((emp (make-instance 'employee
                          :name "赵六" :age 35
                          :company "ABC科技" :position "工程师"))
      (mgr (make-instance 'manager
                          :name "钱七" :age 40
                          :company "ABC科技" :position "技术总监"
                          :team-size 15)))
  (format t "~A~%" (describe emp))
  (format t "~A~%" (describe mgr)))

;; 类级别槽（所有实例共享）
(defclass counter ()
  ((count :allocation :class
          :initform 0
          :accessor counter-count)))

(let ((c1 (make-instance 'counter))
      (c2 (make-instance 'counter)))
  (incf (counter-count c1))
  (incf (counter-count c1))
  (incf (counter-count c2))
  (format t "共享计数: ~A~%" (counter-count c1)))  ; => 3


;;; ----------------------------------------------------------
;;; 5. 方法组合
;;; ----------------------------------------------------------

(format t "~%=== 方法组合 ===~%")

(defclass shape ()
  ((name :initarg :name :initform "形状" :accessor shape-name)))

(defclass circle (shape)
  ((radius :initarg :radius :initform 1 :accessor circle-radius)))

(defclass colored-circle (circle)
  ((color :initarg :color :initform "红" :accessor circle-color)))

;; :before — 在主方法之前执行
(defmethod draw :before ((s shape))
  (format t "  [before] 准备绘制 ~A~%" (shape-name s)))

;; 主方法
(defmethod draw ((s shape))
  (format t "  [primary] 绘制 ~A~%" (shape-name s)))

(defmethod draw ((c circle))
  (format t "  [primary] 绘制圆形，半径 ~A~%" (circle-radius c)))

(defmethod draw ((cc colored-circle))
  (format t "  [primary] 绘制 ~A 色圆形~%" (circle-color cc)))

;; :after — 在主方法之后执行
(defmethod draw :after ((s shape))
  (format t "  [after] 绘制完成~%"))

;; :around — 包裹主方法
(defmethod draw :around ((c circle))
  (format t "  [around] 开始绘制圆形~%")
  (call-next-method)
  (format t "  [around] 圆形绘制结束~%"))

(format t "~%--- 绘制 shape ---~%")
(draw (make-instance 'shape :name "矩形"))

(format t "~%--- 绘制 circle ---~%")
(draw (make-instance 'circle :name "圆" :radius 5))

(format t "~%--- 绘制 colored-circle ---~%")
(draw (make-instance 'colored-circle :name "彩圆" :radius 3 :color "蓝"))


;;; ----------------------------------------------------------
;;; 6. slot-value 与访问器
;;; ----------------------------------------------------------

(format t "~%=== slot-value ===~%")

(let ((p (make-instance 'person :name "测试" :age 20)))
  ;; slot-value 直接访问槽
  (format t "slot-value: ~A~%" (slot-value p 'name))

  ;; slot-boundp 检查槽是否已绑定
  (format t "slot-boundp: ~A~%" (slot-boundp p 'name))

  ;; slot-makunbound 使槽未绑定
  ;; (slot-makunbound p 'name)
  ;; (format t "slot-boundp after unbound: ~A~%" (slot-boundp p 'name))
  )

;; with-slots — 简化槽访问
(defmethod print-info ((p person))
  (with-slots (name age email) p
    (format t "姓名:~A 年龄:~A 邮箱:~A~%" name age email)))

(print-info (make-instance 'person :name "测试者" :age 25 :email "test@test.com"))

;; with-accessors — 通过访问器简化
(defmethod print-info-v2 ((p person))
  (with-accessors ((name person-name)
                   (age person-age))
      p
    (format t "姓名:~A 年龄:~A~%" name age)))

(print-info-v2 (make-instance 'person :name "测试者2" :age 30))


;;; ----------------------------------------------------------
;;; 7. 常用内置方法
;;; ----------------------------------------------------------

(format t "~%=== 内置方法 ===~%")

;; print-object — 自定义打印方式
(defmethod print-object ((p person) stream)
  (print-unreadable-object (p stream :type t)
    (format stream "~A, ~A岁" (person-name p) (person-age p))))

(let ((p (make-instance 'person :name "自定义打印" :age 33)))
  (format t "~A~%" p)
  (format t "~S~%" p))

;; initialize-instance — 初始化后钩子
(defclass validated-person (person)
  ())

(defmethod initialize-instance :after ((p validated-person) &key)
  (when (< (person-age p) 0)
    (error "年龄不能为负数"))
  (when (string= (person-name p) "")
    (setf (person-name p) "未命名"))
  (format t "  [init] 创建了人员: ~A~%" (person-name p)))

(make-instance 'validated-person :name "验证者" :age 25)
(make-instance 'validated-person :age 30)  ; name 默认为 "无名氏"


;;; ----------------------------------------------------------
;;; 8. 实用示例：简单的图形系统
;;; ----------------------------------------------------------

(format t "~%=== 综合示例 ===~%")

(defclass drawable-shape ()
  ((x :initarg :x :initform 0 :accessor shape-x)
   (y :initarg :y :initform 0 :accessor shape-y)))

(defgeneric area (s))
(defgeneric render (s))

(defclass rectangle (drawable-shape)
  ((width  :initarg :width  :accessor rect-width)
   (height :initarg :height :accessor rect-height)))

(defclass triangle (drawable-shape)
  ((base   :initarg :base   :accessor tri-base)
   (height :initarg :height :accessor tri-height)))

(defmethod area ((r rectangle))
  (* (rect-width r) (rect-height r)))

(defmethod area ((tri triangle))
  (/ (* (tri-base tri) (tri-height tri)) 2))

(defmethod render ((r rectangle))
  (format t "  渲染矩形 (~A,~A) ~Ax~A, 面积=~A~%"
          (shape-x r) (shape-y r)
          (rect-width r) (rect-height r)
          (area r)))

(defmethod render ((tri triangle))
  (format t "  渲染三角形 (~A,~A) 底~A 高~A, 面积=~A~%"
          (shape-x tri) (shape-y tri)
          (tri-base tri) (tri-height tri)
          (area tri)))

(let ((shapes (list (make-instance 'rectangle :x 0 :y 0 :width 10 :height 5)
                    (make-instance 'triangle :x 5 :y 5 :base 8 :height 6)
                    (make-instance 'rectangle :x 20 :y 20 :width 3 :height 3))))
  (dolist (s shapes)
    (render s))
  (format t "总面积: ~A~%" (reduce #'+ (mapcar #'area shapes))))

(format t "~%=== 例程 06 执行完毕 ===~%")
