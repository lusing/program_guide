;;;; ============================================================
;;;; examples/05_strings/main.lisp — 字符与字符串
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 字符是独立类型（不是小整数），#\ 语法
;;;;   2. 字符比较家族（大小写敏感 / 不敏感）
;;;;   3. 字符串 = 字符向量，下标访问与长度
;;;;   4. 构造/拼接/切割/查找/修剪全家桶
;;;;   5. 字符串比较家族
;;;;   6. 字面量字符串**不可修改**（经典坑）
;;;;   7. 码点与编码：code-char / char-code
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 字符：#\名字
;;; ----------------------------------------------------------

(format t "字符: ~A ~A ~A~%" #\a #\Space #\Newline) ; ~A 打印名字
(format t "机器视角: ~S，空格的名字: ~A~%" #\a (char-name #\Space))
(format t "charp: ~A, 字符不是数字: ~A~%"
        (characterp #\a) (numberp #\a))

;; 命名字符与「图形字符」写法等价
(format t "#\\a 与 #\\97 码点写法: ~A ~A~%"
        (char= #\a (code-char 97)) (char= #\A (code-char 65)))


;;; ----------------------------------------------------------
;;; 2. 字符比较：两套家族
;;; ----------------------------------------------------------

;; 大小写敏感：char= char< char> ...
(format t "char= 同字符: ~A~%" (char= #\a #\a))
(format t "char< 排序: ~A~%" (char< #\a #\b))
(format t "char/= 大小写不同: ~A~%" (char/= #\a #\A))

;; 大小写不敏感：char-equal char-lessp ...
(format t "char-equal 忽略大小写: ~A~%" (char-equal #\a #\A))
(format t "char-lessp 忽略大小写: ~A~%" (char-lessp #\B #\a))

;; 谓词家族（成对出现：大小写敏感/不敏感）
(format t "alpha/digit/alnum: ~A ~A ~A~%"
        (alpha-char-p #\x) (digit-char-p #\7) (alphanumericp #\5))
(format t "大小写转换: ~A ~A~%"
        (char-upcase #\a) (char-downcase #\L))


;;; ----------------------------------------------------------
;;; 3. 字符串是字符向量
;;; ----------------------------------------------------------

(let ((str "Hello, Lisp"))
  (format t "字符串: ~A~%" str)
  (format t "长度: ~A, 第 0 个: ~A~%" (length str) (char str 0))
  (format t "下标读写都走 char/aref: ~A ~A~%"
          (char str 7) (aref str 8))
  (format t "子串 subseq [0,5): ~A~%" (subseq str 0 5)))


;;; ----------------------------------------------------------
;;; 4. 构造、拼接、切割、查找、修剪
;;; ----------------------------------------------------------

(format t "拼接: ~A~%" (concatenate 'string "foo" "-" "bar"))
(format t "重复构造: ~A~%" (make-string 5 :initial-element #\*))
(format t "反转: ~A~%" (reverse "lisp"))
(format t "切割成表: ~S~%" (map 'list #'identity "abc"))

(let ((csv "name,age,city"))
  ;; position 系列找下标，subseq 按下标切
  (let ((comma (position #\, csv)))
    (format t "第一个逗号在 ~A: ~A~%" comma (subseq csv 0 comma))))

(format t "查找子串 search: ~A~%" (search "Lisp" "Hello, Lisp"))
(format t "修剪空白: [~A]~%" (string-trim " " "  hello  "))
(format t "修剪指定集合: [~A]~%" (string-trim "()" "(hello)"))

;; 替换（破坏性，先 copy-seq 保平安）
(let ((s (copy-seq "hello world")))
  (replace s "WORLD" :start1 6)
  (format t "replace: ~A~%" s))


;;; ----------------------------------------------------------
;;; 5. 字符串比较：同样两套家族
;;; ----------------------------------------------------------

(format t "string= 完全相等: ~A~%" (string= "abc" "abc"))
(format t "string= 大小写敏感: ~A~%" (string= "ABC" "abc"))
(format t "string-equal 忽略大小写: ~A~%" (string-equal "ABC" "abc"))

;; 排序家族返回的是**第一个不同处的下标**（不是 T/NIL！）
(format t "string<: ~A（k 在 s 前，差在第 1 位）~%" (string< "ak" "as"))
(format t "string>= 相等: ~A~%" (string>= "same" "same"))

;; 限定比较范围 :start/:end
(format t "限定范围比较: ~A~%"
        (string= "prefix-a" "prefix-b" :end1 6 :end2 6))


;;; ----------------------------------------------------------
;;; 6. 大小写转换与格式化
;;; ----------------------------------------------------------

(format t "UPPER: ~A  lower: ~A  Capitalized: ~A~%"
        (string-upcase "lisp")
        (string-downcase "LISP")
        (string-capitalize "hello lisp world"))

;; format 的第一个参数给 nil → 结果是字符串而不是输出
(format t "format nil 拼字符串: ~A~%"
        (format nil "~A 有 ~D 个字符" "abc" 3))


;;; ----------------------------------------------------------
;;; 7. 字面量字符串不可修改（经典坑）
;;; ----------------------------------------------------------

;; SBCL 上 (setf (char "literal" 0) #\x) 直接报错（改字面量是未定义行为）；
;; CLISP 上可能「碰巧」改成功——这就是不可移植代码的典型。
;; 正确姿势：先 copy-seq
(let ((s (copy-seq "jello")))
  (setf (char s 0) #\h)
  (format t "改副本安全: ~A~%" s))


;;; ----------------------------------------------------------
;;; 8. 码点与中文
;;; ----------------------------------------------------------

;; 字符 → 码点
(format t "char-code #\\A: ~A~%" (char-code #\A))
;; 码点 → 字符（本教程两套工具链都是 UTF-8 全量字符集）
(format t "code-char 20013: ~A~%" (code-char 20013)) ; 中文「中」

;; 字符串长度按**字符**数，不按 UTF-8 字节数
(format t "中文长度按字符: ~A~%" (length "你好世界"))

;; 数字 ↔ 字符串
(format t "parse-integer: ~A (+ 宽度): ~A~%"
        (parse-integer "42")
        (parse-integer "  99 " :junk-allowed t))
(format t "write-to-string: ~A, 16 进制: ~A~%"
        (write-to-string 255)
        (write-to-string 255 :base 16))

(format t "~%==== 05 结束 ====~%")
