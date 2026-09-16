;;;; ============================================================
;;;; 02-data-types.lisp — Common Lisp 数据类型
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 数字（整数、有理数、浮点数、复数）
;;;;   2. 字符与字符串
;;;;   3. 符号（symbol）
;;;;   4. cons 单元与列表
;;;;   5. 数组与向量
;;;;   6. 哈希表
;;;;   7. 结构体（defstruct）
;;;;   8. 类型判断与类型转换
;;;;
;;;; 运行方式：sbcl --script 02-data-types.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 数字（Numbers）
;;; ----------------------------------------------------------

;; 整数 — 任意精度，不会溢出
(format t "~%=== 数字 ===~%")
(format t "大整数: ~A~%" (expt 2 100))

;; 有理数（分数）— Lisp 自动保持精确
(format t "分数: ~A~%" (/ 1 3))          ; => 1/3
(format t "分数运算: ~A~%" (+ 1/3 1/6))  ; => 1/2

;; 浮点数
(format t "单精度: ~A~%" 3.14f0)
(format t "双精度: ~A~%" 3.14d0)
(format t "float 转换: ~A~%" (float 1/3 1.0d0))

;; 复数
(format t "复数: ~A~%" #C(3 4))
(format t "复数模: ~A~%" (abs #C(3 4)))  ; => 5.0

;; 常用数学函数
(format t "平方根: ~A~%" (sqrt 16))
(format t "幂: ~A~%" (expt 2 10))
(format t "取余: ~A~%" (mod 17 5))
(format t "整除: ~A~%" (floor 17 5))     ; 返回两个值：商和余数
(format t "向上取整: ~A~%" (ceiling 4.3))
(format t "向下取整: ~A~%" (floor 4.7))
(format t "四舍五入: ~A~%" (round 4.5))

;; 多值返回示例
(multiple-value-bind (quotient remainder) (floor 17 5)
  (format t "17 ÷ 5 = ~A 余 ~A~%" quotient remainder))


;;; ----------------------------------------------------------
;;; 2. 字符与字符串
;;; ----------------------------------------------------------

(format t "~%=== 字符与字符串 ===~%")

;; 字符字面量以 #\ 开头
(format t "字符: ~A~%" #\a)
(format t "空格字符: ~A~%" #\Space)
(format t "换行字符: ~A~%" #\Newline)

;; 字符比较
(format t "char=: ~A~%" (char= #\a #\a))
(format t "char<: ~A~%" (char< #\a #\b))
(format t "char-equal(忽略大小写): ~A~%" (char-equal #\A #\a))

;; 字符串是字符向量
(let ((str "Hello, Lisp"))
  (format t "字符串: ~A~%" str)
  (format t "长度: ~A~%" (length str))
  (format t "第0个字符: ~A~%" (char str 0))
  (format t "子串: ~A~%" (subseq str 0 5))
  (format t "大写: ~A~%" (string-upcase str))
  (format t "小写: ~A~%" (string-downcase str))
  (format t "首字母大写: ~A~%" (string-capitalize "hello world"))
  (format t "反转: ~A~%" (reverse str))
  (format t "拼接: ~A~%" (concatenate 'string "foo" "-" "bar"))
  (format t "查找: ~A~%" (search "Lisp" str))
  (format t "去除空白: [~A]~%" (string-trim " " "  hello  ")))

;; 字符串比较
(format t "string=: ~A~%" (string= "abc" "abc"))
(format t "string-equal(忽略大小写): ~A~%" (string-equal "ABC" "abc"))


;;; ----------------------------------------------------------
;;; 3. 符号（Symbols）
;;; ----------------------------------------------------------

(format t "~%=== 符号 ===~%")

;; 符号是 Lisp 的一等公民
(format t "符号: ~A~%" 'hello)
(format t "符号名: ~A~%" (symbol-name 'hello))
(format t "symbolp: ~A~%" (symbolp 'hello))

;; 关键字符号（自求值）
(format t "关键字: ~A~%" :keyword)
(format t "keywordp: ~A~%" (keywordp :test))

;; gensym — 生成唯一符号（宏编程中常用）
(format t "gensym: ~A~%" (gensym "TEMP"))

;; intern — 字符串转符号
(format t "intern: ~A~%" (intern "MY-SYMBOL"))


;;; ----------------------------------------------------------
;;; 4. cons 单元与列表
;;; ----------------------------------------------------------

(format t "~%=== cons 与列表 ===~%")

;; cons 是 Lisp 的基本构建块
(let ((pair (cons 1 2)))
  (format t "cons: ~A~%" pair)
  (format t "car: ~A~%" (car pair))
  (format t "cdr: ~A~%" (cdr pair)))

;; 列表是由 cons 链构成的
(let ((lst (list 1 2 3 4 5)))
  (format t "列表: ~A~%" lst)
  (format t "first: ~A~%" (first lst))
  (format t "rest: ~A~%" (rest lst))
  (format t "second: ~A~%" (second lst))
  (format t "last: ~A~%" (last lst))
  (format t "nth 2: ~A~%" (nth 2 lst))
  (format t "长度: ~A~%" (length lst))
  (format t "反转: ~A~%" (reverse lst))
  (format t "追加: ~A~%" (append '(1 2) '(3 4)))
  (format t "cons 到头部: ~A~%" (cons 0 lst))
  (format t "member: ~A~%" (member 3 lst))
  (format t "assoc: ~A~%" (assoc 'b '((a . 1) (b . 2) (c . 3)))))

;; mapcar — 对每个元素应用函数
(format t "mapcar: ~A~%" (mapcar #'1+ '(1 2 3 4 5)))
(format t "mapcar lambda: ~A~%" (mapcar (lambda (x) (* x x)) '(1 2 3)))

;; remove-if / remove-if-not — 过滤
(format t "偶数: ~A~%" (remove-if-not #'evenp '(1 2 3 4 5 6)))
(format t "去掉偶数: ~A~%" (remove-if #'evenp '(1 2 3 4 5 6)))

;; reduce — 归约
(format t "reduce +: ~A~%" (reduce #'+ '(1 2 3 4 5)))
(format t "reduce max: ~A~%" (reduce #'max '(3 1 4 1 5 9 2 6)))


;;; ----------------------------------------------------------
;;; 5. 数组与向量
;;; ----------------------------------------------------------

(format t "~%=== 数组与向量 ===~%")

;; 一维数组（向量）
(let ((vec (make-array 5 :initial-element 0)))
  (setf (aref vec 0) 10)
  (setf (aref vec 1) 20)
  (format t "向量: ~A~%" vec)
  (format t "aref 0: ~A~%" (aref vec 0)))

;; 字面量向量
(let ((v #(1 2 3 4 5)))
  (format t "字面量向量: ~A~%" v)
  (format t "长度: ~A~%" (length v)))

;; 二维数组
(let ((mat (make-array '(3 3) :initial-element 0)))
  (setf (aref mat 0 0) 1)
  (setf (aref mat 1 1) 1)
  (setf (aref mat 2 2) 1)
  (format t "矩阵: ~A~%" mat)
  (format t "mat[1,1]: ~A~%" (aref mat 1 1)))

;; 可调大小的向量
(let ((v (make-array 0 :adjustable t :fill-pointer 0)))
  (vector-push-extend 10 v)
  (vector-push-extend 20 v)
  (vector-push-extend 30 v)
  (format t "动态向量: ~A~%" v))


;;; ----------------------------------------------------------
;;; 6. 哈希表
;;; ----------------------------------------------------------

(format t "~%=== 哈希表 ===~%")

(let ((ht (make-hash-table)))
  ;; 设置值
  (setf (gethash 'name ht) "SBCL")
  (setf (gethash 'version ht) "2.4")
  (setf (gethash 'year ht) 2024)

  ;; 读取值
  (format t "name: ~A~%" (gethash 'name ht))
  (format t "version: ~A~%" (gethash 'version ht))

  ;; gethash 返回两个值：值和是否存在的布尔值
  (multiple-value-bind (val found) (gethash 'missing ht)
    (format t "missing: val=~A found=~A~%" val found))

  ;; 遍历哈希表
  (maphash (lambda (k v) (format t "  ~A => ~A~%" k v)) ht)

  ;; 删除
  (remhash 'year ht)
  (format t "删除后数量: ~A~%" (hash-table-count ht)))

;; equal 哈希表（可以用字符串做键）
(let ((ht (make-hash-table :test 'equal)))
  (setf (gethash "hello" ht) 42)
  (format t "字符串键: ~A~%" (gethash "hello" ht)))


;;; ----------------------------------------------------------
;;; 7. 结构体（defstruct）
;;; ----------------------------------------------------------

(format t "~%=== 结构体 ===~%")

(defstruct person
  name
  (age 0)
  (email "" :type string))

(let ((p (make-person :name "张三" :age 30 :email "zhang@example.com")))
  (format t "结构体: ~A~%" p)
  (format t "姓名: ~A~%" (person-name p))
  (format t "年龄: ~A~%" (person-age p))
  ;; 修改字段
  (setf (person-age p) 31)
  (format t "修改后年龄: ~A~%" (person-age p))
  (format t "person-p: ~A~%" (person-p p)))


;;; ----------------------------------------------------------
;;; 8. 类型判断与类型转换
;;; ----------------------------------------------------------

(format t "~%=== 类型判断 ===~%")

(format t "type-of 42: ~A~%" (type-of 42))
(format t "type-of \"hello\": ~A~%" (type-of "hello"))
(format t "type-of 'sym: ~A~%" (type-of 'sym))
(format t "type-of #'car: ~A~%" (type-of #'car))

(format t "integerp: ~A~%" (integerp 42))
(format t "stringp: ~A~%" (stringp "hello"))
(format t "listp: ~A~%" (listp '(1 2 3)))
(format t "consp: ~A~%" (consp '(1 . 2)))
(format t "null: ~A~%" (null nil))
(format t "numberp: ~A~%" (numberp 3.14))
(format t "functionp: ~A~%" (functionp #'car))

;; typecase — 按类型分支
(defun describe-type (x)
  (typecase x
    (integer "这是一个整数")
    (string "这是一个字符串")
    (list   "这是一个列表")
    (t      "其他类型")))

(format t "~A~%" (describe-type 42))
(format t "~A~%" (describe-type "hello"))
(format t "~A~%" (describe-type '(1 2)))
(format t "~A~%" (describe-type #\a))

;; 类型转换
(format t "parse-integer: ~A~%" (parse-integer "42"))
(format t "write-to-string: ~A~%" (write-to-string 42))
(format t "coerce to list: ~A~%" (coerce "abc" 'list))
(format t "coerce to string: ~A~%" (coerce '(#\a #\b #\c) 'string))

(format t "~%==== 02 结束 ====~%")
