;;; 54-eieio-introspection.el --- EIEIO 内省与工具 -*- lexical-binding: t; -*-
;;
;; 对应文档:docs/extending-emacs/54-eieio-introspection.md
;;
;; 编译:  emacs -Q --batch -f batch-byte-compile 54-eieio-introspection.el
;; 运行:  emacs -Q --batch -l 54-eieio-introspection.el
;;
;; 演示:
;;   1) 谓词族:谁在什么粒度上判断"是不是某类"
;;   2) 对象与类互查:class / class-name / find-class / parents / children
;;   3) 槽内省:eieio-class-slots 与槽描述符
;;   4) object-assoc 家族:在对象列表里按槽查找
;;   5) 交互工具:eieio-browse 与 customize-object
;;   6) 31.1 废弃清单实测

(require 'eieio)

(defclass shape ()
  ((name :initarg :name :initform "形" :type string))
  "图形基类。")
(defclass circle (shape)
  ((r :initarg :r :initform 1 :type number))
  "圆。")
(defclass square (shape)
  ((s :initarg :s :initform 1 :type number))
  "正方形。")
(defclass unit-circle (circle)
  ()
  "单位圆,circle 的子类,用于测试谓词粒度。")

;;; ---- 1) 谓词族 --------------------------------------------------------

(princ "== 1) 谓词族 ==\n")

(let ((c (circle :name "圆"))
      (u (unit-circle)))
  (princ (format "  class-p 类符号/对象/数字 → %S %S %S\n"
                 (class-p 'circle) (class-p c) (class-p 42)))
  (princ (format "  eieio-object-p 对象/符号  → %S %S\n"
                 (eieio-object-p c) (eieio-object-p 'circle)))
  (princ (format "  circle-p 本类/子类       → %S %S(自动谓词只认本类)\n"
                 (circle-p c) (circle-p u)))
  (princ (format "  cl-typep 认子类          → %S\n" (cl-typep u 'circle)))
  (princ (format "  same-class-p 本类/子类   → %S %S\n"
                 (same-class-p c 'circle) (same-class-p u 'circle)))
  (princ (format "  object-of-class-p 认子类 → %S\n" (object-of-class-p u 'circle)))
  (princ (format "  child-of-class-p 类名间  → %S %S\n"
                 (child-of-class-p 'unit-circle 'shape)
                 (child-of-class-p 'shape 'unit-circle))))

;;; ---- 2) 对象与类互查 ---------------------------------------------------

(princ "== 2) 对象与类互查 ==\n")

(let ((c (circle :name "圆")))
  (princ (format "  eieio-object-class      → %S(符号)\n" (eieio-object-class c)))
  (princ (format "  eieio-object-class-name → %S\n" (eieio-object-class-name c))))
(princ (format "  find-class 命中/未命中    → %S %S\n"
               (not (null (find-class 'circle))) (find-class 'no-such-class)))
(princ (format "  eieio-class-parents 个数  → %S(元素是类对象,不是符号)\n"
               (length (eieio-class-parents 'circle))))
(princ (format "  eieio-class-children      → %S(直接子类符号)\n"
               (eieio-class-children 'shape)))

;;; ---- 3) 槽内省 ----------------------------------------------------------

(princ "== 3) 槽内省:eieio-class-slots ==\n")

(defclass meter ()
  ((name :initarg :name :initform "m" :type string)
   (base :allocation :class :initform 0 :type number))
  "一个实例槽加一个类槽。")

(princ (format "  class-slots 个数 → %S(只含实例槽,类槽 base 不在内)\n"
               (length (eieio-class-slots 'meter))))
(princ (format "  槽名列表        → %S\n"
               (mapcar #'eieio-slot-descriptor-name (eieio-class-slots 'meter))))
(princ (format "  描述符原样      → %S\n" (car (eieio-class-slots 'meter))))

;;; ---- 4) object-assoc 家族 ----------------------------------------------

(princ "== 4) object-assoc 家族 ==\n")

(let ((group (list (circle :name "甲" :r 1)
                   (square :name "乙" :s 2)
                   (circle :name "甲" :r 3))))
  (princ (format "  object-assoc \"甲\"  → 第一个匹配,r=%S\n"
                 (slot-value (object-assoc "甲" 'name group) 'r)))
  (princ (format "  assoc 缺槽不报错    → %S\n"
                 (object-assoc 2 's group)))
  (princ (format "  object-assoc-list   → %S\n" (object-assoc-list 'name group)))
  (princ (format "  assoc-list-safe 按槽 → %S\n"
                 (mapcar #'car (object-assoc-list-safe 's group)))))

;;; ---- 5) 交互工具 ----------------------------------------------------------

(princ "== 5) 交互工具 ==\n")

(princ (format "  M-x eieio-browse       → fboundp %S\n" (fboundp 'eieio-browse)))
(princ (format "  M-x customize-object   → fboundp %S\n" (fboundp 'customize-object)))
(princ (format "  M-x eieio-help-constructor → fboundp %S\n"
               (fboundp 'eieio-help-constructor)))

;;; ---- 6) 31.1 废弃清单实测 --------------------------------------------------

(princ "== 6) 31.1 废弃清单实测 ==\n")

(princ (format "  fboundp class-option        → %S(函数已删)\n"
               (fboundp 'class-option)))
(princ (format "  fboundp set-slot-value      → %S(obsolete alias,勿用)\n"
               (fboundp 'set-slot-value)))
(princ (format "  fboundp object-name-string  → %S(obsolete alias)\n"
               (fboundp 'object-name-string)))
(princ (format "  fboundp object-p            → %S(obsolete alias)\n"
               (fboundp 'object-p)))
(princ (format "  boundp eieio-version        → %S(obsolete 变量)\n"
               (boundp 'eieio-version)))
(princ (format "  locate-library eieio-compat → %S(挪进 obsolete/,require 会告警)\n"
               (not (null (locate-library "eieio-compat")))))

(princ "==== 54 结束 ====\n")
