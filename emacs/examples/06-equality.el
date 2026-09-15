;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 06 - 相等性：eq / eql / equal / = 该用哪一个
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "06-equality.el")'
;;; 运行：emacs -Q --batch -l 06-equality.el
;;; ============================================================

(require 'seq)

;;; 1) eq —— 比「同一对象」，最快也最严格。
;;;    符号、nil、t、整数（fixnum）用 eq 安全。
(princ (format "eq 'a 'a = %S,  eq nil nil = %S,  eq 1 1 = %S\n"
               (eq 'a 'a) (eq nil nil) (eq 1 1)))

;;; 2) 【坑】eq 别用在浮点和字符串上：它比的是「同一对象」，不是「内容一样」。
;;;    下面两个都造出内容相同、但不是同一个对象的东西，eq 一律返回 nil。
;;;    （注意：直接写 (eq 1.0 1.0) 这类「字面量比字面量」的写法，
;;;     字节编译器会直接警告 "called with literal float that may never match"，
;;;     所以演示时先绑到变量上。）
(let ((a (+ 0.5 0.5)) (b (+ 1.0 0.0)))
  (princ (format "eq 两个不同的 1.0 = %S\n" (eq a b))))
(let ((a "abc") (b (copy-sequence "abc")))
  (princ (format "eq 两个内容相同的字符串 = %S，equal = %S\n"
                 (eq a b) (equal a b))))
(princ (format "eq (list 1) (list 1) = %S  <- 两个不同的 cons\n"
               (eq (list 1) (list 1))))

;;; 3) eql —— 在 eq 之外，还让「数值相等且类型相同」成立。
;;;    浮点比数值，但 -0.0 与 0.0 不等（eql 区分符号位）。
(princ (format "eql 1.0 1.0 = %S,  eql 1 1.0 = %S,  (= 1 1.0) = %S\n"
               (eql 1.0 1.0) (eql 1 1.0) (= 1 1.0)))

;;; 4) = —— 只比数，而且会做类型提升（1 和 1.0 相等）。
;;;    【坑】= 只能吃数字，喂字符串会直接报错。
(princ (format "= 3 3.0 = %S\n" (= 3 3.0)))

;;; 5) equal —— 递归比「结构」，字符串比内容，列表逐元素比。日常最常用。
(princ (format "equal \"aa\" (concat \"a\" \"a\") = %S\n"
               (equal "aa" (concat "a" "a"))))
(princ (format "equal (list 1 2) (list 1 2) = %S\n" (equal (list 1 2) (list 1 2))))
(princ (format "equal '(1 (2)) '(1 (2)) = %S\n" (equal '(1 (2)) '(1 (2)))))

;;; 6) equal 会忽略文本属性。要比属性用 equal-including-properties。
(let ((plain "abc")
      (fancy (propertize "abc" 'face 'bold)))
  (princ (format "equal = %S, equal-including-properties = %S\n"
                 (equal plain fancy)
                 (equal-including-properties plain fancy))))

;;; 7) 字符串专用：string-equal（别名 string=）比内容，且区分大小写；
;;;    compare-strings 可以忽略大小写。
(princ (format "string-equal \"a\" \"A\" = %S\n" (string-equal "a" "A")))
(princ (format "compare-strings 忽略大小写 = %S\n"
               (compare-strings "abc" 0 3 "ABC" 0 3 t)))

;;; 8) 【坑】查找函数的默认比较函数各不相同，背下来能省很多调试时间：
;;;    assq / memq / rassq        -> eq
;;;    assoc / member / rassoc    -> equal
;;;    alist-get                  -> eq  （第五个参数可换成别的）
(defvar demo-alist (list (cons "name" "emacs") (cons "ver" "31")))
(let ((k "name"))
  (princ (format "assoc  (equal)   找到: %S\n" (assoc k demo-alist)))
  (princ (format "assq   (eq)    找不到: %S\n" (assq k demo-alist)))
  (princ (format "alist-get 默认 eq    -> %S\n" (alist-get k demo-alist)))
  (princ (format "alist-get 传 equal   -> %S\n"
                 (alist-get k demo-alist nil nil #'equal))))

;;; 9) 排序要用「比较函数」，不是相等函数：string< / < / string-collate-lessp。
;;;    【坑】sort 是破坏性的，会就地重排列表；喂常量列表会被编译器警告，
;;;    要排序就先 copy-sequence（或干脆用非破坏的 seq-sort / cl-sort 的副本）。
(princ (format "sort 数字: %S\n" (sort (list 3 1 2) #'<)))
(princ (format "sort 字符串: %S\n" (sort (list "b" "a") #'string<)))
(princ (format "非破坏的 seq-sort: %S\n" (seq-sort #'< (list 3 1 2))))

(princ "==== 06 结束 ====\n")
