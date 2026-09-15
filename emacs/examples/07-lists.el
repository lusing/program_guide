;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 07 - 列表：cons 单元、car/cdr、破坏性与非破坏性操作
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "07-lists.el")'
;;; 运行：emacs -Q --batch -l 07-lists.el
;;; ============================================================

;;; 1) 列表是由 cons 单元串起来的。cons 单元有两个格子：car 和 cdr。
;;;    (1 . 2) 是一个 cons；(1 2 3) 是 (1 . (2 . (3 . nil)))。
(princ (format "(cons 1 2) = %S      <- 点对的写法\n" (cons 1 2)))
(princ (format "(list 1 2 3) = %S\n" (list 1 2 3)))
(princ (format "car = %S, cdr = %S\n" (car '(1 2 3)) (cdr '(1 2 3))))
(princ (format "cadr = %S, cddr = %S  <- c[a/d]+r 可组合，最多四层\n"
               (cadr '(1 2 3)) (cddr '(1 2 3))))

;;; 2) 构造：list / make-list / number-sequence
(princ (format "make-list: %S\n" (make-list 3 'x)))
(princ (format "number-sequence 1..5: %S，步长 2: %S\n"
               (number-sequence 1 5) (number-sequence 1 9 2)))

;;; 3) push / pop 把列表当栈用。两者都是宏，直接改变量指向的位置。
(defvar demo-stack nil)
(push 1 demo-stack)
(push 2 demo-stack)
(princ (format "push 两次: %S，pop 出 %S，剩下 %S\n"
               demo-stack (pop demo-stack) demo-stack))

;;; 4) 取元素：nth 按下标，nthcdr 跳 n 个格子，last 取最后一个 cons，
;;;    butlast 去掉末尾 n 个。
(princ (format "nth 1 = %S, nthcdr 2 = %S, last = %S, butlast = %S\n"
               (nth 1 '(a b c d)) (nthcdr 2 '(a b c d))
               (last '(a b c d)) (butlast '(a b c d) 2)))

;;; 5) 【坑】append 与 nconc：append 复制除最后一个之外的所有参数（非破坏），
;;;    nconc 直接改前一个列表的最后一个 cdr（破坏性）。
;;;    对常量列表做破坏性操作是未定义行为 —— 别写 (nconc '(1) '(2))。
(defvar demo-a (list 1 2))
(defvar demo-b (list 3 4))
(princ (format "append: %S，之后 a 仍是 %S\n" (append demo-a demo-b) demo-a))
(princ (format "nconc:  %S，之后 a 变成 %S\n" (nconc demo-a demo-b) demo-a))

;;; 6) 【坑】共享结构。setq 到同一个列表对象，改一个另一个也变。
(let ((x (list 1 2 3))
      (y nil))
  (setq y x)
  (setcar y 99)
  (princ (format "改了 y 的 car 之后，x = %S，y = %S\n" x y)))
;;;    要独立副本就用 copy-sequence（浅拷贝）或 copy-tree（深拷贝）。
(let* ((x (list 1 (list 2)))
       (shallow (copy-sequence x))
       (deep (copy-tree x)))
  (setcar (nth 1 x) 99)
  (princ (format "浅拷贝跟着变 = %S，深拷贝不变 = %S\n" shallow deep)))

;;; 7) 遍历与映射：dolist / mapcar / mapc / mapcan
(princ (format "mapcar: %S\n" (mapcar (lambda (x) (* x x)) '(1 2 3 4))))
(princ (format "mapcan（拼接结果）: %S\n"
               (mapcan (lambda (x) (list x x)) '(1 2))))
(let ((seen nil))
  (mapc (lambda (x) (push x seen)) '(a b c))
  (princ (format "mapc 只做副作用: %S\n" (nreverse seen))))

;;; 8) 【坑】remove 返回新列表（非破坏），delete 直接在原列表上删（破坏）。
;;;    用 delete 时必须接住返回值：(setq xs (delete x xs))，
;;;    因为删掉头元素时返回值会指向新的头。
(let ((xs (list 1 2 3 2)))
  (princ (format "remove 2: %S，原列表没变: %S\n" (remove 2 xs) xs)))
(let ((xs (list 1 2 3 2)))
  (princ (format "delete 2: %S，原列表已变: %S\n" (delete 2 xs) xs)))
(let ((xs (list 1 1 2)))
  (princ (format "delete 头元素必须接返回值: %S\n" (delete 1 xs))))

;;; 9) alist：元素是 (key . value) 的列表，配置类数据的首选结构
(defvar demo-conf (list (cons 'host "localhost") (cons 'port 8080)))
(princ (format "alist = %S\n" demo-conf))
(princ (format "assq 'port = %S，alist-get = %S\n"
               (assq 'port demo-conf) (alist-get 'port demo-conf)))
(princ (format "assoc-default = %S，rassoc 反查 = %S\n"
               (assoc-default 'host demo-conf) (rassoc 8080 demo-conf)))

;;; 10) plist：扁平的 key value key value ...，符号属性表就是这种结构
(princ (format "plist-get: %S\n" (plist-get '(:a 1 :b 2) :b)))
(princ (format "plist-put: %S\n" (plist-put (list :a 1) :b 2)))

(princ "==== 07 结束 ====\n")
