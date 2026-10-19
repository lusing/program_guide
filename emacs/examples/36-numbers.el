;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 36 - 数字：整数、浮点、取整、位运算与格式化
;;;   对应 Elisp 参考手册 Numbers 一章，把「数字的脾气」逐个实测出来
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "36-numbers.el")'
;;; 运行：emacs -Q --batch -l 36-numbers.el
;;; ============================================================
(require 'cl-lib)
;;; 下面第 6 节要在运行时调用 byte-compile 抓一条警告，所以这里先把 bytecomp
;;; 加载进来：它里面的 (defvar byte-compile-log-warning-function) 会让这个变量
;;; 变成「特殊变量」，否则 let 绑它会被当成词法变量，运行时再 defvar 就报错。
(require 'bytecomp)

;;; ---------- 1) 两种数字：整数与浮点 ----------
(princ "== 1) 整数与浮点 ==\n")
(dolist (v (list 42 -7 3.14 1.0e+INF 1.0e+NaN))
  (princ (format "  %-12S type=%-8S integerp=%-5S floatp=%S\n"
                 v (type-of v) (integerp v) (floatp v))))

;;; ---------- 2) 除法：一个运算符，两种语义 ----------
;;; (/) 只要有一个参数是浮点就返回浮点；全是整数就做「截断整除」。
(princ "\n== 2) 除法与取余 ==\n")
(princ (format "  (/ 7 2)   = %S\n" (/ 7 2)))
(princ (format "  (/ 7 2.0) = %S\n" (/ 7 2.0)))
(princ (format "  (/ 7.0 2) = %S\n" (/ 7.0 2)))
(princ (format "  (/ -7 2)  = %S   ; 朝零截断，不是向下取整\n" (/ -7 2)))
(princ (format "  (mod 7 2) = %S   ; 余数符号跟除数\n" (mod 7 2)))
(princ (format "  (%% 7 2)  = %S   ; 余数符号跟被除数\n" (% 7 2)))
(princ (format "  (mod -7 2) = %S  (%% -7 2) = %S\n" (mod -7 2) (% -7 2)))
(princ (format "  (mod 7 -2) = %S  (%% 7 -2) = %S\n" (mod 7 -2) (% 7 -2)))

;;; ---------- 3) 取整四兄弟 ----------
;;; truncate 朝零、floor 朝负无穷、ceiling 朝正无穷、round 四舍五入。
;;; 注意 round 用的是「银行家舍入」：遇到 .5 时取最近的偶数。
(princ "\n== 3) 取整 ==\n")
(dolist (x (list 1.7 -1.7 2.5 3.5 -2.5))
  (princ (format "  %-6S truncate=%-4S floor=%-4S ceiling=%-4S round=%S\n"
                 x (truncate x) (floor x) (ceiling x) (round x))))
(princ "  --- 两参数版：自带「先除后取整」---\n")
(princ (format "  (/ 5 2)=%S  (floor 5 2)=%S  (truncate 5 2)=%S  (mod 5 2)=%S\n"
               (/ 5 2) (floor 5 2) (truncate 5 2) (mod 5 2)))
(princ "  --- 名字前面加 f 的版本返回浮点 ---\n")
(princ (format "  (truncate 1.7)=%S   (ftruncate 1.7)=%S\n"
               (truncate 1.7) (ftruncate 1.7)))
(princ (format "  (ffloor 1.7)=%S  (fceiling 1.7)=%S  (fround 1.7)=%S\n"
               (ffloor 1.7) (fceiling 1.7) (fround 1.7)))

;;; ---------- 4) bignum：整数不会溢出 ----------
;;; fixnum 是「机器字内能放下」的小整数，超了自动升级成 bignum（任意精度）。
(princ "\n== 4) fixnum 与 bignum ==\n")
(princ (format "  most-positive-fixnum = %S\n" most-positive-fixnum))
(princ (format "  fixnump=%S  integerp=%S\n"
               (fixnump most-positive-fixnum) (integerp most-positive-fixnum)))
(let ((big (1+ most-positive-fixnum)))
  (princ (format "  (1+ most-positive-fixnum) = %S\n" big))
  (princ (format "     fixnump=%S  integerp=%S  bignump=%S\n"
                 (fixnump big) (integerp big) (bignump big))))
(princ (format "  (expt 2 100) = %S\n" (expt 2 100)))
(princ (format "  (* (expt 2 62) 8) = %S   ; 换别的语言这里早溢出了\n"
               (* (expt 2 62) 8)))
(princ (format "  (abs most-negative-fixnum) = %S  fixnump=%S\n"
               (abs most-negative-fixnum) (fixnump (abs most-negative-fixnum))))

;;; ---------- 5) 浮点：不能当精确数用 ----------
(princ "\n== 5) 浮点的精度与特殊值 ==\n")
(princ (format "  (+ 0.1 0.2)        = %S\n" (+ 0.1 0.2)))
(princ (format "  (= (+ 0.1 0.2) 0.3) = %S   ; 直接比相等是错的\n"
               (= (+ 0.1 0.2) 0.3)))
(princ (format "  差值 = %S\n" (- (+ 0.1 0.2) 0.3)))
(let ((eps 1e-9))
  (princ (format "  (< (abs (- (+ 0.1 0.2) 0.3)) %S) = %S   ; 用容差比较\n"
                 eps (< (abs (- (+ 0.1 0.2) 0.3)) eps))))
(princ (format "  (sqrt -1) = %S   (/ 1.0 0) = %S   (/ 0.0 0.0) = %S\n"
               (sqrt -1) (/ 1.0 0) (/ 0.0 0.0)))
(princ (format "  (= 1.0e+NaN 1.0e+NaN) = %S   ; NaN 不等于自己\n"
               (= 1.0e+NaN 1.0e+NaN)))
(princ (format "  (isnan 1.0e+NaN) = %S   (> 1.0e+INF 1.0e+308) = %S\n"
               (isnan 1.0e+NaN) (> 1.0e+INF 1.0e+308)))
(princ (format "  (- 1.0e+INF 1.0e+INF) = %S\n" (- 1.0e+INF 1.0e+INF)))
(princ (format "  (sin float-pi) = %S   ; 圆周率也是浮点，不为 0\n" (sin float-pi)))
(princ (format "  (/ 1 0) -> %S\n"
               (condition-case err (/ 1 0) (arith-error (error-message-string err)))))

;;; ---------- 6) 位运算：ash 与 lsh 的区别是分水岭 ----------
(princ "\n== 6) 位运算 ==\n")
(princ (format "  (logand 12 10)=%S (logior 12 10)=%S (logxor 12 10)=%S\n"
               (logand 12 10) (logior 12 10) (logxor 12 10)))
(princ (format "  (lognot 0)=%S   (logcount 15)=%S   (logb 8)=%S\n"
               (lognot 0) (logcount 15) (logb 8)))
(princ "  --- 左移两者一致；右移分道扬镳 ---\n")
(princ (format "  (lsh 1 2) = %S   (ash 1 2) = %S\n"
               (with-no-warnings (lsh 1 2)) (ash 1 2)))
(princ "  lsh 是逻辑移位（右移高位补 0），ash 是算术移位（右移保留符号）：\n")
(princ (format "  (lsh -8 -1) = %S\n" (with-no-warnings (lsh -8 -1))))
(princ (format "  (ash -8 -1) = %S\n" (ash -8 -1)))
(princ (format "  (lsh -1 -1) = %S\n" (with-no-warnings (lsh -1 -1))))
(princ (format "  (ash -1 -1) = %S\n" (ash -1 -1)))
;;; 字节编译器会劝你别用 lsh。把这条警告当场抓下来，而不是让它跑到 stderr 上。
(let (warns)
  (let ((byte-compile-log-warning-function
         (lambda (string &optional _position _fill _level)
           (push string warns))))
    (byte-compile '(lambda () (lsh -8 -1))))
  (princ (format "  字节编译器对 (lsh -8 -1) 的警告原文： %S\n"
                 (car (nreverse warns)))))

;;; ---------- 7) 随机数：想可复现就播种 ----------
;;; (random STRING) 用字符串给发生器播种，同一个串必然得到同一串数。
(princ "\n== 7) 随机数 ==\n")
(let (a b)
  (random "demo-seed")
  (setq a (list (random 100) (random 100) (random 100)))
  (random "demo-seed")
  (setq b (list (random 100) (random 100) (random 100)))
  (princ (format "  同一种子两次结果： %S\n" a))
  (princ (format "                    %S\n" b))
  (princ (format "  两次相等？ %S\n" (equal a b))))
(princ (format "  (random 1) = %S   ; 上限为 1 时只能是 0\n" (random 1)))

;;; ---------- 8) 解析与格式化 ----------
(princ "\n== 8) 字符串 <-> 数字 ==\n")
(princ (format "  (string-to-number \"42\")      = %S\n" (string-to-number "42")))
(princ (format "  (string-to-number \"3.5\")     = %S\n" (string-to-number "3.5")))
(princ (format "  (string-to-number \"0x1f\")    = %S   ; 默认按十进制，认不出 0x\n"
               (string-to-number "0x1f")))
(princ (format "  (string-to-number \"1f\" 16)   = %S   ; 进制是第二个参数\n"
               (string-to-number "1f" 16)))
(princ (format "  (string-to-number \"abc\")     = %S   ; 解析失败返回 0，不报错\n"
               (string-to-number "abc")))
(princ (format "  (number-to-string 42)   = %S\n" (number-to-string 42)))
(princ (format "  (number-to-string 3.0)  = %S\n" (number-to-string 3.0)))
(princ (format "  (cl-parse-integer \"42\")        = %S\n" (cl-parse-integer "42")))
(princ (format "  (cl-parse-integer \"  42abc\" :start 2 :end 4) = %S\n"
               (cl-parse-integer "  42abc" :start 2 :end 4)))
(princ "  --- format 的动词 ---\n")
(princ (format "  %s\n" (format "  %%d=%d  %%5.2f=%5.2f  %%e=%e  %%x=%x  %%o=%o  %%g=%g"
                                255 3.14159 12345.0 255 8 0.0000001)))

;;; ---------- 9) 数字上的相等性（呼应第 6 章） ----------
(princ "\n== 9) 数字上的 = / eql / equal ==\n")
(princ (format "  (= 1 1.0)     = %S   ; = 只比数值\n" (= 1 1.0)))
(princ (format "  (eql 1 1.0)   = %S   ; eql 还要求类型相同\n" (eql 1 1.0)))
(princ (format "  (equal 1 1.0) = %S\n" (equal 1 1.0)))
(princ (format "  (eql (expt 2 100) (expt 2 100)) = %S  ; bignum 按值比\n"
               (eql (expt 2 100) (expt 2 100))))
(princ (format "  (= 1.0e+INF 1.0e+INF) = %S\n" (= 1.0e+INF 1.0e+INF)))

;;; ---------- 10) 常用数学函数 ----------
(princ "\n== 10) 常用数学函数 ==\n")
(princ (format "  (sqrt 2)=%S  (exp 1)=%S  (log (exp 1))=%S\n"
               (sqrt 2) (exp 1) (log (exp 1))))
(princ (format "  (log 8 2)=%S  (expt 2 10)=%S  (expt 2 -1)=%S  (expt 2.0 0.5)=%S\n"
               (log 8 2) (expt 2 10) (expt 2 -1) (expt 2.0 0.5)))
(princ (format "  (abs -3.5)=%S  (max 1 2.5 2)=%S  (min 1 2.5 2)=%S\n"
               (abs -3.5) (max 1 2.5 2) (min 1 2.5 2)))
(princ (format "  (float 3)=%S  (float 3.5)=%S\n" (float 3) (float 3.5)))
(princ (format "  (cl-loop for i from 1 to 10 sum i) = %S\n"
               (cl-loop for i from 1 to 10 sum i)))

(princ "==== 36 结束 ====\n")
