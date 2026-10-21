;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 49 - EIEIO 快速上手：defclass、构造、泛型与方法
;;;   EIEIO（Enhanced Implementation of Emacs Interpreted
;;;   Objects）是 Emacs 内置的面向对象层，语法仿 Common Lisp
;;;   的 CLOS。自 Emacs 25 起它建立在 cl-defstruct 与
;;;   cl-generic 之上，因此写泛型用 cl-defgeneric、写方法用
;;;   cl-defmethod。本文件用一个最小例子走完全流程：
;;;   定义类 → 构造对象 → 读写槽 → 写方法 → 继承多态。
;;;   所有行为都在 Emacs 31.1 上实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "49-eieio-quickstart.el")'
;;; 运行：emacs -Q --batch -l 49-eieio-quickstart.el
;;; ============================================================
(require 'eieio)

;;; ---------- 1) defclass：定义一个类 ----------
(princ "== 1) defclass：定义一个类 ==\n")
;; defclass 的骨架：(defclass 类名 (父类...) ((槽 选项...)...) "文档")
(defclass person ()
  ((name :initarg :name :initform "无名氏" :type string
         :documentation "姓名")
   (age :initarg :age :initform 0 :type number
        :documentation "年龄"))
  "人类。")
(princ "  定义即得三样东西：构造函数 person、谓词 person-p、类对象。\n")
(princ (format "  构造函数已定义 → %S；谓词已定义 → %S\n"
               (fboundp 'person) (fboundp 'person-p)))
(princ (format "  (find-class 'person) 找到类对象 → %S\n"
               (not (null (find-class 'person)))))

;;; ---------- 2) 构造对象 ----------
(princ "== 2) 构造对象：构造函数与 make-instance ==\n")
(let ((a (person :name "张三" :age 30))
      (b (person))                       ; 全部用 :initform 默认值
      (c (make-instance 'person :name "李四"))) ; make-instance 等价写法
  ;; 31.1 里对象的 prin1 形态是记录语法 #s(类名 槽值...)
  (princ (format "  (person :name \"张三\" :age 30) → %S\n" a))
  (princ (format "  (person) 全默认               → %S\n" b))
  (princ (format "  make-instance 等价构造        → %S\n" c)))

;;; ---------- 3) 谓词 ----------
(princ "== 3) 谓词 ==\n")
(let ((p (person)))
  (princ (format "  person-p 认实例、拒杂项：%S / %S\n"
                 (person-p p) (person-p 42)))
  (princ (format "  eieio-object-p 认一切 EIEIO 对象：%S / %S\n"
                 (eieio-object-p p) (eieio-object-p "x")))
  (princ (format "  class-p 认类符号：%S / %S\n"
                 (class-p 'person) (class-p 'nosuch))))

;;; ---------- 4) 读写槽 ----------
(princ "== 4) 读写槽：slot-value 是广义变量 ==\n")
(let ((p (person :name "王五" :age 25)))
  (princ (format "  slot-value 读 → %S %S\n"
                 (slot-value p 'name) (slot-value p 'age)))
  (setf (slot-value p 'age) 26)          ; setf 直接写
  (princ (format "  setf 写后     → %S %S\n"
                 (slot-value p 'name) (slot-value p 'age))))

;;; ---------- 5) 泛型与方法 ----------
(princ "== 5) cl-defgeneric 与 cl-defmethod ==\n")
;; 先声明泛型（可选但推荐），再按「特化」写方法
(cl-defgeneric introduce (who)
  "自我介绍。")
(cl-defmethod introduce ((who person))
  (format "我是%s，%d岁。"
          (slot-value who 'name) (slot-value who 'age)))
(princ (format "  对 person 实例调用 → %s\n"
               (introduce (person :name "赵六" :age 40))))
;; 特化写法 (who person)：第一个参数必须是 person 或其子类的实例

;;; ---------- 6) 继承与方法覆写 ----------
(princ "== 6) 继承、覆写与 cl-call-next-method ==\n")
(defclass employee (person)
  ((dept :initarg :dept :initform "研发" :type string))
  "雇员。")
(cl-defmethod introduce ((who employee))
  (format "%s我在%s部门。" (cl-call-next-method) (slot-value who 'dept)))
(let ((e (employee :name "小明" :age 28 :dept "平台")))
  (princ (format "  employee 实例 → %s\n" (introduce e)))
  ;; 注意：person-p 只认“恰好是 person”的实例，不认子类实例
  (princ (format "  person-p 只认本类，对子类实例 → %S\n" (person-p e)))
  ;; 判断“是不是 person 或其子类”要用 cl-typep 或 object-of-class-p
  (princ (format "  cl-typep 认子类         → %S\n" (cl-typep e 'person)))
  (princ (format "  object-of-class-p 认子类 → %S\n" (object-of-class-p e 'person))))

;;; ---------- 7) 没有适用方法时 ----------
(princ "== 7) cl-no-applicable-method 信号 ==\n")
;; 泛型只对 person 有方法；给它一个数字，EIEIO 抛出
;; cl-no-applicable-method 信号，用 condition-case 接住看信号名
(let ((sig (condition-case err
               (progn (introduce 42) nil)
             (error (car err)))))
  (princ (format "  (introduce 42) 抛出信号 → %S\n" sig)))

(princ "==== 49 结束 ====\n")
