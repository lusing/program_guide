;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 09 - seq.el 与 cl-lib：现代 Elisp 的两把瑞士军刀
;;;   seq-map / seq-filter / seq-reduce / cl-loop / cl-defstruct / cl-case
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "09-sequences.el")'
;;; 运行：emacs -Q --batch -l 09-sequences.el
;;; ============================================================

(require 'seq)
(require 'cl-lib)

;;; 1) seq.el 的杀手锏：同一套函数能吃 list、vector、string 三种序列。
;;;    写扩展时不必再为「传进来的是列表还是向量」分叉。
(princ (format "seq-map list:   %S\n" (seq-map #'1+ '(1 2 3))))
(princ (format "seq-map vector: %S\n" (seq-map #'1+ [1 2 3])))
(princ (format "seq-filter string: %S\n" (seq-filter (lambda (c) (= c ?a)) "banana")))

;;; 2) 常用 seq-* 一览
(princ (format "seq-remove: %S\n" (seq-remove #'cl-evenp '(1 2 3 4))))
(princ (format "seq-reduce: %S\n" (seq-reduce #'+ '(1 2 3 4) 0)))
(princ (format "seq-sort: %S\n" (seq-sort #'> '(3 1 2))))
(princ (format "seq-uniq: %S\n" (seq-uniq '(1 2 2 3 1))))
(princ (format "seq-position: %S\n" (seq-position '(a b c) 'c)))
(princ (format "seq-contains-p: %S\n" (seq-contains-p '(a b c) 'b)))
(princ (format "seq-elt / seq-length: %S / %S\n"
               (seq-elt '(10 20 30) 1) (seq-length [1 2 3])))
(princ (format "seq-take / seq-drop: %S / %S\n"
               (seq-take '(1 2 3 4) 2) (seq-drop '(1 2 3 4) 2)))
(princ (format "seq-group-by 奇偶: %S\n" (seq-group-by #'cl-evenp '(1 2 3 4))))

;;; 3) 【坑】seq.el 大多是非破坏性的，返回新序列；原序列不动。
;;;    破坏性的老函数（sort / delete / nconc）是另一套，别混着用。
(let ((xs (list 3 1 2)))
  (princ (format "seq-sort 后原列表: %S，新列表: %S\n" xs (seq-sort #'< xs))))

;;; 4) seq-doseq / seq-do 是「带类型的 dolist」
(let ((acc 0))
  (seq-do (lambda (x) (setq acc (+ acc x))) [1 2 3])
  (princ (format "seq-do 累加: %S\n" acc)))

;;; 5) cl-lib 之一：cl-loop。Common Lisp 的 loop 宏，功能极强，
;;;    这里只列 Emacs 扩展里最常用的几种写法。
(princ (format "cl-loop collect: %S\n" (cl-loop for i from 1 to 5 collect (* i i))))
(princ (format "cl-loop 带条件: %S\n"
               (cl-loop for i from 1 to 10 when (cl-evenp i) collect i)))
(princ (format "cl-loop sum: %S\n" (cl-loop for x in '(1 2 3) sum x)))
(princ (format "cl-loop 遍历字符串: %S\n"
               (cl-loop for c across "abc" collect (upcase (char-to-string c)))))
(princ (format "cl-loop 多变量: %S\n"
               (cl-loop for a in '(1 2 3) for b in '(10 20 30) collect (+ a b))))

;;; 6) cl-lib 之二：cl-incf / cl-decf，原地自增
(let ((n 0))
  (cl-incf n 5)
  (cl-incf n)
  (princ (format "cl-incf 之后 n = %S\n" n)))

;;; 7) cl-lib 之三：cl-case / cl-ecase。比 cond 紧凑，用 eql 比较。
;;;    cl-ecase 在没有分支命中时会**报错**，适合处理「理论上不该出现」的值。
(defun demo-kind (x)
  "返回 X 的类型名。"
  (cl-case x
    (:a "A 类")
    (:b "B 类")
    (t "其它")))
(princ (format "cl-case: %S / %S\n" (demo-kind :a) (demo-kind :z)))

;;; 8) cl-lib 之四：cl-defstruct 定义结构。
;;;    会生成 demo-point-p、make-demo-point、demo-point-x 等一整套函数，
;;;    还能用 (setf (demo-point-x p) 1) 赋值。
(cl-defstruct (demo-point (:constructor demo-point-new (x y)))
  "演示用结构。"
  x y)
(defvar demo-p (demo-point-new 3 4))
(princ (format "结构: %S, x = %S, 判定 = %S\n"
               demo-p (demo-point-x demo-p) (demo-point-p demo-p)))
(cl-incf (demo-point-x demo-p) 10)
(princ (format "setf 风格改字段后: %S\n" demo-p))
(princ (format "copy 出的副本: %S\n" (copy-demo-point demo-p)))

;;; 9) cl-lib 之五：cl-defun 支持 &key 关键字参数，可读性远好于 &optional
(cl-defun demo-connect (host &key (port 22) (user "root"))
  "演示 &key 参数。"
  (format "%s@%s:%d" user host port))
(princ (format "%S / %S\n" (demo-connect "h1") (demo-connect "h1" :port 80 :user "me")))

;;; 10) cl-letf 临时改写函数或变量的值，测试里非常有用（见 25-tests.el）
(princ (format "cl-letf 临时改值: %S\n"
               (let ((demo-p (demo-point-new 1 1)))
                 (cl-letf (((demo-point-x demo-p) 42))
                   (demo-point-x demo-p)))))

(princ "==== 09 结束 ====\n")
