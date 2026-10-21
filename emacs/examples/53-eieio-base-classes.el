;;; 53-eieio-base-classes.el --- EIEIO 预定义基类 -*- lexical-binding: t; -*-
;;
;; 对应文档:docs/extending-emacs/53-eieio-base-classes.md
;;
;; 编译:  emacs -Q --batch -f batch-byte-compile 53-eieio-base-classes.el
;; 运行:  emacs -Q --batch -l 53-eieio-base-classes.el
;;
;; 演示:
;;   1) eieio-default-superclass:所有类的隐式父类
;;   2) eieio-named:给对象一个名字
;;   3) eieio-named 与 clone:自动改名
;;   4) eieio-singleton:单例
;;   5) eieio-instance-tracker:跟踪全部实例
;;   6) eieio-instance-inheritor:实例级继承
;;   7) eieio-persistent:把对象写进文件
;;
;; 注意:这些基类(除 default-superclass 外)都在 eieio-base.el,
;;       必须 (require 'eieio-base),只 require eieio 会报
;;       "Given parent class eieio-named is not a class"。

(require 'eieio)
(require 'eieio-base)

;;; ---- 1) eieio-default-superclass -------------------------------------

(princ "== 1) eieio-default-superclass:隐式父类 ==\n")

(defclass plain ()
  ((x :initarg :x :initform 1 :type number))
  "不写父类的普通类。")

(princ (format "  class-parents(31.1 不列出默认父类)→ %S\n"
               (eieio-class-parents 'plain)))
(princ (format "  child-of-class-p                  → %S\n"
               (child-of-class-p 'plain 'eieio-default-superclass)))

;;; ---- 2) eieio-named ---------------------------------------------------

(princ "== 2) eieio-named:对象的名字 ==\n")

(defclass person (eieio-named)
  ((age :initarg :age :initform 0 :type number))
  "带名字的人。")

(let ((p (person :object-name "张三" :age 30)))
  (princ (format "  initarg 是 :object-name → 槽 %S\n" (slot-value p 'object-name)))
  (princ (format "  eieio-object-name-string → %S\n" (eieio-object-name-string p))))
(princ (format "  缺 :object-name           → 槽 %S\n"
               (slot-value (person) 'object-name)))

;;; ---- 3) eieio-named 与 clone -------------------------------------------

(princ "== 3) named 与 clone:自动改名 ==\n")

(let ((p (person :object-name "原")))
  (princ (format "  clone 无参         → %S(自动加 -1)\n"
                 (slot-value (clone p) 'object-name)))
  (princ (format "  clone \"新\"(首参)   → %S\n"
                 (slot-value (clone p "新") 'object-name)))
  (princ (format "  clone :object-name → %S\n"
                 (slot-value (clone p :object-name "指名") 'object-name))))

;;; ---- 4) eieio-singleton -------------------------------------------------

(princ "== 4) eieio-singleton:单例 ==\n")

(defclass config (eieio-singleton)
  ((debug :initarg :debug :initform nil :type boolean))
  "全局配置,只允许一个实例。")

(let ((c1 (make-instance 'config :debug t))
      (c2 (make-instance 'config :debug nil)))
  (princ (format "  两次构造同一对象   → %S\n" (eq c1 c2)))
  (princ (format "  第二次 initarg 无效 → %S\n" (slot-value c2 'debug))))

;;; ---- 5) eieio-instance-tracker -------------------------------------------

(princ "== 5) eieio-instance-tracker:跟踪实例 ==\n")

(defvar my-connections nil
  "conn 类全部实例的列表,由跟踪器自动维护。")

(defclass conn (eieio-instance-tracker)
  ((tracking-symbol :initform 'my-connections)
   (host :initarg :host :initform "" :type string))
  "可跟踪的连接:覆写类槽 tracking-symbol 指向列表变量。")

(let ((a (conn :host "alpha"))
      (_b (conn :host "beta")))
  (princ (format "  构造即入列        → %S\n"
                 (mapcar (lambda (o) (slot-value o 'host)) my-connections)))
  (princ (format "  tracker-find beta → %S\n"
                 (slot-value
                  (eieio-instance-tracker-find "beta" 'host 'my-connections)
                  'host)))
  (delete-instance a)
  (princ (format "  delete-instance 后 → %S\n"
                 (mapcar (lambda (o) (slot-value o 'host)) my-connections))))

;;; ---- 6) eieio-instance-inheritor -------------------------------------------

(princ "== 6) eieio-instance-inheritor:实例继承 ==\n")

(defclass proto (eieio-instance-inheritor)
  ((color :initarg :color :initform "红" :type string)
   (size :initarg :size :initform 10 :type number))
  "原型对象,克隆体未设置的槽向原型取值。")

(let* ((parent (proto :color "蓝" :size 20))
       (kid (clone parent)))
  (princ (format "  未绑定槽向父取值 → %S %S\n"
                 (slot-value kid 'color) (slot-value kid 'size)))
  (setf (slot-value kid 'size) 99)
  (princ (format "  覆写后用自值     → %S %S\n"
                 (slot-value kid 'color) (slot-value kid 'size)))
  (princ (format "  父对象不受影响   → %S %S\n"
                 (slot-value parent 'color) (slot-value parent 'size)))
  (princ (format "  inheritor-boundp → %S(沿父链)\n"
                 (eieio-instance-inheritor-slot-boundp kid 'color)))
  (princ (format "  普通 slot-boundp → %S(只看自身)\n"
                 (slot-boundp kid 'color))))

;;; ---- 7) eieio-persistent ---------------------------------------------------

(princ "== 7) eieio-persistent:写进文件 ==\n")

(defclass save-me (eieio-persistent eieio-named)
  ((data :initarg :data :initform 0 :type number))
  "可持久化的命名对象。")

(let ((s (save-me :object-name "存档一" :data 42
                  :file "/tmp/eieio-53-save.el")))
  (eieio-persistent-save s)
  (princ "  --- 写出的文件内容 ---\n")
  (with-temp-buffer
    (insert-file-contents "/tmp/eieio-53-save.el")
    (princ (buffer-string)))
  (princ "  --- 文件完 ---\n")
  (let ((r (eieio-persistent-read "/tmp/eieio-53-save.el" 'save-me)))
    (princ (format "  读回 → name %S data %S\n"
                   (slot-value r 'object-name) (slot-value r 'data)))
    (princ (format "  file 槽被设为读取路径 → %S\n" (slot-value r 'file)))))

(princ "==== 53 结束 ====\n")
