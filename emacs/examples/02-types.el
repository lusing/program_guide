;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 02 - 数据类型与判谓
;;;   type-of、各类型谓词、t/nil、字符即整数、整数除法与 bignum
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "02-types.el")'
;;; 运行：emacs -Q --batch -l 02-types.el
;;; ============================================================

;;; 1) type-of 返回类型的符号；日常更常用的是各种 xxxp 谓词
(princ (format "type-of: %S\n"
               (mapcar #'type-of (list 42 3.14 "abc" 'sym '(1 . 2) [1 2] ?A))))

;;; 2) 判谓一览：integerp / floatp / numberp / stringp / symbolp / consp /
;;;    listp / vectorp / hash-table-p / functionp / null
(princ (format "42: integerp=%S numberp=%S floatp=%S\n"
               (integerp 42) (numberp 42) (floatp 42)))
(princ (format "\"abc\": stringp=%S  'sym: symbolp=%S\n"
               (stringp "abc") (symbolp 'sym)))

;;; 3) 【坑】nil 同时扮演四个角色：空表、布尔假、符号 nil、空字符串以外的「没有值」。
;;;    于是 (null nil)、 (listp nil) 都是 t，但 (consp nil) 是 nil ——
;;;    要区分「空表」和「非空表」，用 consp，别用 listp。
(princ (format "nil: null=%S listp=%S consp=%S symbolp=%S\n"
               (null nil) (listp nil) (consp nil) (symbolp nil)))
(princ (format "'(1): listp=%S consp=%S\n" (listp '(1)) (consp '(1))))

;;; 4) 只有 nil 是假，其余全是真 —— 包括 0 和空字符串
(princ (format "0 是真是假？%S     \"\" 是真是假？%S\n"
               (if 0 "真" "假") (if "" "真" "假")))

;;; 5) 【坑】字符就是整数。?A 读作 65，没有单独的 character 类型
(princ (format "?A = %S, (char-to-string ?A) = %S, (string-to-char \"A\") = %S\n"
               ?A (char-to-string ?A) (string-to-char "A")))

;;; 6) 【坑】/ 对整数做整除。(/ 1 2) 是 0 不是 0.5；
;;;    想要浮点，让至少一个操作数是浮点。
(princ (format "(/ 1 2) = %S, (/ 1.0 2) = %S, (float 1) = %S\n"
               (/ 1 2) (/ 1.0 2) (float 1)))

;;; 7) Emacs 有原生 bignum，整数不会静默溢出（Python 风格，不是 C 风格）
(princ (format "2^70 = %S, most-positive-fixnum = %S\n"
               (expt 2 70) most-positive-fixnum))

;;; 8) 常用常量
(princ (format "t = %S, float-pi = %S, emacs-version = %S\n"
               t float-pi emacs-version))

(princ "==== 02 结束 ====\n")
