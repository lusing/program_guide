;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 51 - 对象与槽访问：构造、读写、绑定状态与互操作
;;;   49 章讲了 slot-value 的基本读写，本章把「对象日常
;;;   操作」补齐：构造参数的各种形态、oref/oset 宏、槽的
;;;   绑定状态（boundp/makeunbound）、运行期类型校验、类
;;;   槽默认值、with-slots 词法绑定、列表槽工具，以及
;;;   EIEIO 函数用在 cl-defstruct 上时的边界。所有行为都
;;;   在 Emacs 31.1 上实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "51-eieio-slots.el")'
;;; 运行：emacs -Q --batch -l 51-eieio-slots.el
;;; ============================================================
(require 'eieio)

;;; ---------- 1) 构造参数全景 ----------
(princ "== 1) 构造参数全景 ==\n")
(defclass emp ()
  ((name :initarg :name :initform "无名氏" :type string)
   (age :initarg :age :initform 0 :type number))
  "雇员。")
(princ (format "  给定 initarg        → %S\n"
               (emp :name "张三" :age 30)))
(princ (format "  缺省走 initform     → %S\n" (emp)))
;; 给了类里不存在的 initarg：运行期报 invalid-slot-name
(let ((sig (condition-case err
               (progn (emp :bogus 1) nil)
             (error (car err)))))
  (princ (format "  未知 initarg        → %S\n" sig)))
;; make-instance 与构造函数等价，但第一参数必须是「类符号」
(princ (format "  make-instance 类符号 → %S\n"
               (make-instance 'emp :name "李四")))
;; 传 find-class 返回的类对象不行：31.1 没有匹配它的方法
(let ((sig (condition-case err
               (progn (make-instance (find-class 'emp)) nil)
             (error (car err)))))
  (princ (format "  make-instance 类对象 → %S\n" sig)))

;;; ---------- 2) slot-value 与 oref/oset ----------
(princ "== 2) slot-value 与 oref/oset ==\n")
(let ((o (emp :name "王五" :age 25)))
  (princ (format "  slot-value 读 → %S %S\n"
                 (slot-value o 'name) (slot-value o 'age)))
  (setf (slot-value o 'age) 26)      ; slot-value 是广义变量
  (princ (format "  setf 写后     → %S %S\n"
                 (slot-value o 'name) (slot-value o 'age)))
  ;; oref/oset 是老式宏写法，31.1 依然可用（未废弃）；
  ;; 槽名不用加引号（宏自动 quote）
  (oset o age 27)
  (princ (format "  oref/oset 宏  → %S %S\n"
                 (oref o name) (oref o age))))

;;; ---------- 3) 绑定状态 ----------
(princ "== 3) 绑定状态：slot-boundp 与 slot-makeunbound ==\n")
;; 没有 :initform 的槽，构造时没给 initarg 就处于「未绑定」
(defclass task ()
  ((title :initarg :title :initform "待办" :type string)
   (note :initarg :note :type string))
  "任务。")
(let ((o (task)))
  (princ (format "  未绑定槽 boundp   → %S\n" (slot-boundp o 'note)))
  (let ((sig (condition-case err
                 (progn (slot-value o 'note) nil)
               (error (car err)))))
    (princ (format "  读未绑定槽        → %S\n" sig)))
  (setf (slot-value o 'note) "周五前交")
  (princ (format "  赋值后 boundp     → %S\n" (slot-boundp o 'note)))
  (slot-makeunbound o 'note)
  (princ (format "  makeunbound 后    → %S\n" (slot-boundp o 'note))))

;;; ---------- 4) 槽名检查 ----------
(princ "== 4) 槽名检查：slot-exists-p 与 invalid-slot-name ==\n")
;; slot-exists-p 返回槽的索引（真值）或 nil
(princ (format "  slot-exists-p → %S / %S\n"
               (slot-exists-p (task) 'title)
               (slot-exists-p (task) 'nosuch)))
;; 访问不存在的槽报 invalid-slot-name；槽名放进变量里，
;; 字节编译器就不会提前警告（演示错误时有用）
(let ((sn 'nosuch))
  (let ((sig (condition-case err
                 (progn (slot-value (task) sn) nil)
               (error (car err)))))
    (princ (format "  访问不存在槽  → %S\n" sig))))

;;; ---------- 5) 运行期类型校验 ----------
(princ "== 5) 运行期类型校验：invalid-slot-type ==\n")
;; 50 章见过定义期校验；构造与 setf 时同样校验 :type
(let ((sig1 (condition-case err
                (progn (emp :age "三十") nil)
              (error (car err))))
      (sig2 (let ((o (emp :age 30)))
              (condition-case err
                  (progn (setf (slot-value o 'age) "三十") nil)
                (error (car err))))))
  (princ (format "  构造时类型不符 → %S\n" sig1))
  (princ (format "  setf 时类型不符 → %S\n" sig2)))

;;; ---------- 6) 类槽默认值 ----------
(princ "== 6) 类槽默认值：oref-default 与 oset-default ==\n")
;; oref-default/oset-default 读写类槽的「默认值」；字节编
;; 译器要求槽必须是 :allocation :class（实例槽会警告）
(defclass meter ()
  ((name :initarg :name :initform "m" :type string)
   (base :allocation :class :initform 0 :type number))
  "仪表。")
(princ (format "  改前默认           → %S\n" (oref-default 'meter base)))
(oset-default 'meter base 100)
(princ (format "  oset-default 写    → %S\n" (oref-default 'meter base)))
(princ (format "  新实例读到新默认   → %S\n"
               (slot-value (meter) 'base)))

;;; ---------- 7) with-slots ----------
(princ "== 7) with-slots：把槽当局部变量 ==\n")
;; with-slots 用 symbol-macrolet 把槽名绑成词法变量，setq
;; 与 setf 都会写回对象
(let ((o (emp :name "赵六" :age 40)))
  (with-slots (name age) o
    (setq age (1+ age))
    (princ (format "  原名绑定 → %S %S\n" name age)))
  (princ (format "  写回对象 → %S\n" (slot-value o 'age))))
;; 也可以 (变量 槽) 换名绑定
(let ((o (emp :name "孙七" :age 22)))
  (with-slots ((n name) (a age)) o
    (princ (format "  换名绑定 → %S %S\n" n a))))

;;; ---------- 8) 列表槽工具 ----------
(princ "== 8) 列表槽：object-add-to-list 与 object-remove-from-list ==\n")
;; 这两个函数操作的是「对象里装着列表的那个槽」：
;; (object-add-to-list 对象 槽 元素 &optional 追加?)
(defclass bag ()
  ((items :initarg :items :initform nil))
  "口袋。")
(let ((o (bag)))
  (object-add-to-list o 'items "苹果")
  (object-add-to-list o 'items "香蕉")
  (object-add-to-list o 'items "苹果")     ; 已存在则不加
  (princ (format "  add 三次（一次重复）→ %S\n" (oref o items)))
  (object-add-to-list o 'items "栗子" t)   ; 第四参 t 追加到末尾
  (princ (format "  append 到末尾         → %S\n" (oref o items)))
  (object-remove-from-list o 'items "苹果")
  (princ (format "  remove                → %S\n" (oref o items))))

;;; ---------- 9) 与 cl-defstruct 的互操作 ----------
(princ "== 9) 与 cl-defstruct 的互操作 ==\n")
;; EIEIO 对象底层就是记录，slot-value/setf 也能用在
;; cl-defstruct 实例上；但并非所有 EIEIO 函数都支持
(cl-defstruct (spoint (:constructor mk-spoint)) x y)
(let ((s (mk-spoint :x 1 :y 2)))
  (princ (format "  slot-value 读 struct → %S\n" (slot-value s 'x)))
  (setf (slot-value s 'x) 10)
  (princ (format "  slot-value 写 struct → %S\n" (spoint-x s)))
  (let ((sig1 (condition-case err
                  (progn (slot-boundp s 'x) nil)
                (error (car err))))
        (sig2 (condition-case err
                  (progn (make-instance 'spoint) nil)
                (error (car err)))))
    (princ (format "  slot-boundp 不支持  → %S\n" sig1))
    (princ (format "  make-instance 不支持 → %S\n" sig2))))

(princ "==== 51 结束 ====\n")
