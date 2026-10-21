;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 50 - defclass 详解：槽选项、继承规则与类选项
;;;   49 章用最小例子走通了 EIEIO 全流程，本章把 defclass
;;;   的每个部件拆开讲：槽的 :initarg/:initform/:type 三
;;;   要素、访问器与定制选项、:printer、类共享槽、继承时
;;;   的覆写规则，以及类级别的 :abstract 等选项。同时指出
;;;   31.1 与老手册的差异：定义期类型校验、:protection
;;;   不再强制、:metaclass 与 :default-initargs 被静默
;;;   忽略。所有行为都在 Emacs 31.1 上实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "50-eieio-defclass.el")'
;;; 运行：emacs -Q --batch -l 50-eieio-defclass.el
;;; ============================================================
(require 'eieio)

;;; ---------- 1) 槽三要素：:initarg、:initform、:type ----------
(princ "== 1) 槽三要素：:initarg、:initform、:type ==\n")
;; :initarg 给槽开一把构造时的“钥匙”，:initform 是没给钥匙
;; 时的默认值，:type 声明类型
(defclass account ()
  ((owner :initarg :owner :initform "匿名" :type string)
   (balance :initarg :balance :initform 0 :type number))
  "银行账户。")
(let ((a (account :owner "张三")))
  (princ (format "  只给 :owner，其余走默认值 → %S %S\n"
                 (slot-value a 'owner) (slot-value a 'balance))))
;; 没有 :initarg 的槽，构造时无法指定
(defclass no-key ()
  ((secret :initform 42 :type number))
  "演示无 initarg。")
(princ (format "  无 :initarg 的槽只能吃默认值 → %S\n"
               (slot-value (no-key) 'secret)))
;; 31.1 新行为：定义类时就校验 :initform 与 :type 是否匹配
(condition-case err
    (eval '(defclass bad-slot () ((n :initform "oops" :type number))))
  (error (princ (format "  initform 与 type 不符 → 定义期即报 %S\n"
                        (car err)))))

;;; ---------- 2) 文档与访问器 ----------
(princ "== 2) :documentation 与访问器 :accessor/:reader/:writer ==\n")
;; :accessor 生成一个读写函数；:reader 与 :writer 拆成只读、
;; 只写两个函数
(defclass config-item ()
  ((key :initarg :key :initform "unnamed" :type string
        :accessor cfg-key
        :documentation "键名。")
   (value :initarg :value :initform 0 :type number
          :reader cfg-value :writer cfg-set-value))
  "配置项。")
(let ((o (config-item :key "width" :value 80)))
  (setf (cfg-key o) "height")          ; accessor 可 setf
  (cfg-set-value o 88)                 ; writer 只负责写
  (princ (format "  accessor 读回 %S；reader 读回 %S\n"
                 (cfg-key o) (cfg-value o))))
;; reader-only 的槽没有 setf 方法，setf 相当于调用不存在的
;; (setf cfg-value) 函数
(defvar tmp-cfg (config-item)
  "reader-only 演示用对象。")
(condition-case err
    (eval '(setf (cfg-value tmp-cfg) 99))
  (error (princ (format "  对 reader-only 槽 setf → %S\n" (car err)))))

;;; ---------- 3) 定制选项 ----------
(princ "== 3) 定制选项 :custom/:label/:group 存进槽描述符 ==\n")
;; 这三个选项服务于 M-x customize 界面：:custom 是控件类
;; 型，:label 是显示名，:group 是归属组。它们被收进槽描
;; 描述符的 props 里，用 eieio-class-slots 可以看到（31.1
;; 返回描述符的列表）
(defclass ui-field ()
  ((title :initarg :title :initform "无题" :type string
          :custom string :label "标题" :group eieio))
  "带定制信息的槽。")
(princ (format "  title 的槽描述符 → %S\n"
               (car (eieio-class-slots 'ui-field))))

;;; ---------- 4) :printer 与 object-write ----------
(princ "== 4) :printer：object-write 时的自定义打印 ==\n")
;; :printer 接受一个单参数函数：object-write 序列化对象
;; 时对它调用 (funcall printer 槽值)，函数必须自己 princ
;; 到 standard-output，返回值被忽略
(defclass stamped ()
  ((label :initarg :label :initform "无" :type string)
   (year :initarg :year :initform 1970 :type number
         :printer (lambda (v) (princ (format "「%d年」" v))))
   (cache :initform nil))
  "带自定义打印的类。")
;; object-write 只写「有 :initarg 且当前值 ≠ initform」的
;; 槽；eieio-print-object-name 绑 nil 则不写名字行
(let ((eieio-print-object-name nil))
  (princ "  object-write 输出：")
  (object-write (stamped :label "纪念" :year 2024)))
;; year 保持默认 1970 与无 :initarg 的 cache 都不会写出
(let ((eieio-print-object-name nil))
  (princ "  默认值槽被跳过：  ")
  (object-write (stamped :label "纪念")))

;;; ---------- 5) :allocation :class ----------
(princ "== 5) :allocation :class：全类共享一份 ==\n")
;; 实例槽每个对象一份；:allocation :class 的槽全类共用同
;; 一份存储，从任何一个实例写，其他实例都能读到
(defclass counted ()
  ((name :initarg :name :initform "x" :type string)
   (total :allocation :class :initform 0 :type number))
  "带类槽的类。")
(let ((a (counted :name "甲"))
      (b (counted :name "乙")))
  (setf (slot-value a 'total) 5)
  (princ (format "  从 a 写入 5，从 b 读到 → %S\n"
                 (slot-value b 'total))))

;;; ---------- 6) :protection 与 :allow-nil-initform ----------
(princ "== 6) :protection 与 :allow-nil-initform 的现状 ==\n")
;; 老手册说 :protection :protected/:private 会限制外部访
;; 问；31.1 已不再强制，只当文档用
(defclass legacy ()
  ((priv :initarg :priv :initform 42 :type number
         :protection :protected))
  "老代码遗留写法。")
(princ (format "  :protection 槽仍可外部直读 → %S\n"
               (slot-value (legacy) 'priv)))
;; :allow-nil-initform 只豁免“定义期”对 nil 默认值的类
;; 型检查；注意类选项是平铺写法，不要加括号
(defclass maybe-name ()
  ((nick :initarg :nick :initform nil :type string))
  "允许 nil 默认值。"
  :allow-nil-initform t)
(princ (format "  nil initform + :allow-nil-initform → 默认 %S\n"
               (slot-value (maybe-name) 'nick)))
;; 但运行期给 nil 仍受 :type 约束
(let ((sig (condition-case err
               (progn (maybe-name :nick nil) nil)
             (error (car err)))))
  (princ (format "  构造时显式给 nil → %S（string 类型不含 nil）\n" sig)))
;; 真要让槽接受 nil，把类型写成 (or null string)
(defclass maybe-name2 ()
  ((nick :initarg :nick :initform nil :type (or null string)))
  "类型层面允许 nil。")
(princ (format "  :type (or null string) 给 nil → %S\n"
               (slot-value (maybe-name2 :nick nil) 'nick)))

;;; ---------- 7) 继承规则 ----------
(princ "== 7) 继承：覆写默认值、:type 不可改、多继承顺序 ==\n")
;; 子类可以重声明父类的槽：改 :initform、改文档，但不许
;; 改 :type
(defclass shape ()
  ((color :initarg :color :initform "黑" :type string
          :documentation "颜色。"))
  "图形。")
(defclass red-shape (shape)
  ((color :initform "红" :documentation "覆写后的颜色。"))
  "红色图形。")
(princ (format "  子类覆写 initform → %S\n"
               (slot-value (red-shape) 'color)))
;; 改 :type 会在定义期直接报错
(condition-case err
    (eval '(defclass bad-shape (shape)
             ((color :initform 1 :type number))
             "改类型的子类。"))
  (error (princ (format "  改父类槽的 :type → %s\n" (cadr err)))))
;; 多继承出现同名槽时，排在前面的父类获胜
(defclass left () ((tag :initform "左" :type string)) "左。")
(defclass right () ((tag :initform "右" :type string)) "右。")
(defclass both (left right) () "多继承。")
(princ (format "  (both left right) 同名槽取前位父类 → %S\n"
               (slot-value (both) 'tag)))

;;; ---------- 8) 类选项 ----------
(princ "== 8) 类选项：:abstract、自定义 tag、被忽略的选项 ==\n")
;; :abstract t 声明抽象类：只能被继承，不能被实例化
(defclass widget-base ()
  ((x :initarg :x :initform 0 :type number))
  "抽象基类。"
  :abstract t)
(princ (format "  实例化抽象类 → %s\n"
               (condition-case err (progn (widget-base) "没拦住")
                 (error (cadr err)))))
;; 除预定义选项外还能挂任意自定义 tag；读回要用内部函数
;; eieio--class-option（老的公开函数 class-option 已被删
;; 除）
(defclass tagged ()
  ((x :initarg :x :initform 0 :type number))
  "带自定义 tag。"
  :domain "demo")
(princ (format "  自定义类选项读回 → %S\n"
               (eieio--class-option (find-class 'tagged) :domain)))
;; 老手册里的 :metaclass 与 :default-initargs：31.1 不报
;; 错，但会被静默忽略
(defclass old-style ()
  ((x :initarg :x :type number))
  "老写法。"
  :default-initargs (:x 99)
  :metaclass standard-class)
(princ (format "  :default-initargs 生效？x 绑定 → %S\n"
               (slot-boundp (old-style) 'x)))
(princ (format "  :metaclass 生效？类对象仍是 → %S\n"
               (type-of (find-class 'old-style))))

(princ "==== 50 结束 ====\n")
