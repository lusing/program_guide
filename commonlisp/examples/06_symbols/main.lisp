;;;; ============================================================
;;;; examples/06_symbols/main.lisp — 符号与包
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 符号的三件事：名字、包、身份
;;;;   2. 关键字：自求值、自动落在 KEYWORD 包
;;;;   3. intern：字符串 → 符号（与 read 的关系）
;;;;   4. defpackage / in-package：定义自己的包
;;;;   5. 单冒号与双冒号、导出与可见性
;;;;   6. find-symbol 返回两值：符号 + 可见性状态
;;;;   7. 符号可以同时有：值、函数、宏、属性表
;;;;   8. gensym：生成保证不撞名的符号
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 符号的三件事
;;; ----------------------------------------------------------

(format t "符号名: ~S~%" (symbol-name 'hello-world))
(format t "所在包: ~A~%" (package-name (symbol-package 'hello-world)))
(format t "同一个符号（在同一个包里 intern 过）: ~A~%"
        (eq (intern "HELLO-WORLD") 'hello-world))

;; 符号不是字符串：两个包里各有一个同名符号，互不相等
(defpackage :demo-a (:use :cl) (:export #:name))
(defpackage :demo-b (:use :cl) (:export #:name))
(format t "同名不同包 → 不是同一符号: ~A~%"
        (not (eq (find-symbol "NAME" :demo-a) (find-symbol "NAME" :demo-b))))


;;; ----------------------------------------------------------
;;; 2. 关键字：:xxx
;;; ----------------------------------------------------------

;; 关键字自动 intern 到 KEYWORD 包，且求值成自己
(format t "关键字自求值: ~A~%" :size)
(format t "关键字所在包: ~A~%" (package-name (symbol-package :size)))
(format t "keywordp: ~A, 普通符号求值找值单元格: ~A~%"
        (keywordp :size)
        (boundp 'not-bound-anywhere))


;;; ----------------------------------------------------------
;;; 3. intern：字符串变符号（读取器就是这么干的）
;;; ----------------------------------------------------------

;; intern 在指定包里找/建符号
(let ((sym (intern "MADE-BY-INTERN" :demo-a)))
  (format t "intern 造出的符号: ~A, 是否已有: ~A~%"
          (symbol-name sym) (eq sym (find-symbol "MADE-BY-INTERN" :demo-a))))

;; 字符串名字一样 + 同一个包 = 同一个符号（身份由 包+名字 决定）
(format t "再 intern 一次还是它: ~A~%"
        (eq (intern "MADE-BY-INTERN" :demo-a)
            (find-symbol "MADE-BY-INTERN" :demo-a)))


;;; ----------------------------------------------------------
;;; 4. 定义一个包，放两个导出函数 + 一个内部函数
;;; ----------------------------------------------------------

(defpackage :geometry
  (:use :cl)
  (:export #:area-of          ; 导出：外面可见
           #:perimeter-of)
  (:documentation "一个演示用的小包。"))

(in-package :geometry)

(defun area-of (w h) (* w h))
(defun perimeter-of (w h) (* 2 (+ w h)))
(defun internal-helper (x) (* x x))   ; 没导出：内部实现

(in-package :cl-user)

;; 单冒号访问导出符号；双冒号能捅进内部（但别养成习惯）
(format t "面积 3x4: ~A~%" (geometry:area-of 3 4))
(format t "周长 3x4: ~A~%" (geometry:perimeter-of 3 4))

;; 没导出的符号用单冒号在**读取期**就报错（连 eval 都到不了），
;; 所以这里没法用 handler-case 演示——文档里用 REPL 实测展示。
;; 双冒号可以捅进内部，但只建议调试时用：
(format t "双冒号访问内部函数: ~A（仅限调试）~%" (geometry::internal-helper 5))


;;; ----------------------------------------------------------
;;; 5. use-package：把导出符号「引进来」直接用
;;; ----------------------------------------------------------

(defpackage :app (:use :cl :geometry))
(in-package :app)
(format t "use 后直接用: 面积 ~A~%" (area-of 5 6))
(in-package :cl-user)


;;; ----------------------------------------------------------
;;; 6. find-symbol 的两值
;;; ----------------------------------------------------------

;; 返回 符号 + :internal / :external / :inherited / NIL
(multiple-value-bind (sym status) (find-symbol "AREA-OF" :geometry)
  (format t "geometry:AREA-OF → ~A ~A~%" (symbol-name sym) status))
(multiple-value-bind (sym status) (find-symbol "INTERNAL-HELPER" :geometry)
  (format t "geometry:INTERNAL-HELPER → ~A ~A~%"
          (symbol-name sym) status))
(multiple-value-bind (sym status) (find-symbol "NOPE" :geometry)
  (format t "geometry:NOPE → ~A ~A~%" sym status))

;; 统计一个包的导出符号数（顺序无关，只数个数——跨实现稳定）
(format t "geometry 导出符号数: ~A~%"
        (loop for s being the external-symbols of :geometry count s))


;;; ----------------------------------------------------------
;;; 7. 一个符号，四个格子
;;; ----------------------------------------------------------

;; 值单元格（defparameter/defvar/setf 全局时）
(defparameter *count* 10)
;; 函数单元格
(defun *count*-transform (x) (+ x *count*))
;; 宏单元格（下一章细讲，这里只演示「互不冲突」）
(defmacro *count*-twice () '(* 2 *count*))
;; 属性表
(setf (get '*count* 'unit) "个")

(format t "值: ~A  函数: ~A  宏: ~A  属性: ~A~%"
        *count*
        (*count*-transform 5)
        (*count*-twice)
        (get '*count* 'unit))

;; boundp / fboundp / makunbound / fmakunbound
;; boundp/fboundp 返回「广义布尔」：CLISP 规矩地给 T，
;; SBCL 的 fboundp 直接把**函数对象**当真值返回——跨实现比较输出
;; 时要 (if ... T NIL) 归一成严格的 T/NIL
(format t "boundp: ~A, fboundp: ~A~%"
        (boundp '*count*)
        (if (fboundp '*count*-transform) t nil))
(makunbound '*count*)
(format t "makunbound 后 boundp: ~A~%" (boundp '*count*))


;;; ----------------------------------------------------------
;;; 8. gensym：永不撞名的符号（写宏的卫生用品）
;;; ----------------------------------------------------------

;; gensym 每次生成**全新**符号，编号随实现/会话不同——
;; 所以永远不要打印 gensym 的名字做「输出比对」，
;; 要比对的是「两个 gensym 互不相等」这个事实
(format t "两个 gensym 互不相等: ~A~%"
        (not (eq (gensym) (gensym))))
(format t "gensym 也不与任何 intern 过的符号相等: ~A~%"
        (not (eq (gensym "TEMP") (intern "TEMP314"))))

;; symbol-name 可以前缀定制，适合调试时辨认（编号部分随会话变，
;; 所以只展示「去掉数字后的前缀」）
(let ((g (gensym "SWAP-VAR-")))
  (format t "gensym 名字的可读前缀: ~A~%"
          (remove-if #'digit-char-p (symbol-name g))))


(format t "~%==== 06 结束 ====~%")
