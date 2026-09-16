;;;; ============================================================
;;;; 04-functions.lisp — 函数
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defun 定义函数
;;;;   2. 参数列表（必需、可选、rest、关键字参数）
;;;;   3. lambda 匿名函数
;;;;   4. 高阶函数（mapcar / apply / funcall）
;;;;   5. 闭包（closure）
;;;;   6. 递归
;;;;   7. flet / labels 局部函数
;;;;   8. 文档字符串与函数属性
;;;;
;;;; 运行方式：sbcl --script 04-functions.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. defun 定义函数
;;; ----------------------------------------------------------

(format t "~%=== defun ===~%")

(defun add (a b)
  "简单的加法函数。"
  (+ a b))

(format t "add(3, 4) = ~A~%" (add 3 4))

;; 函数是 Lisp 的一等公民
(format t "函数对象: ~A~%" #'add)
(format t "函数名: ~A~%" (symbol-function 'add))


;;; ----------------------------------------------------------
;;; 2. 参数列表
;;; ----------------------------------------------------------

(format t "~%=== 参数列表 ===~%")

;; --- 必需参数 ---
(defun greet (name)
  (format nil "你好，~A" name))

(format t "~A~%" (greet "世界"))

;; --- 可选参数（&optional）---
(defun greet-with-title (name &optional (title "先生/女士"))
  (format nil "~A ~A，你好！" name title))

(format t "~A~%" (greet-with-title "张三"))
(format t "~A~%" (greet-with-title "张三" "博士"))

;; 可选参数可以检测是否被提供
(defun describe-person (name &optional (age nil age-supplied-p))
  (if age-supplied-p
      (format nil "~A，~A岁" name age)
      (format nil "~A，年龄未知" name)))

(format t "~A~%" (describe-person "李四"))
(format t "~A~%" (describe-person "李四" 25))

;; --- rest 参数（&rest）---
(defun sum-all (&rest numbers)
  (reduce #'+ numbers :initial-value 0))

(format t "sum-all: ~A~%" (sum-all 1 2 3 4 5))
(format t "sum-all 无参数: ~A~%" (sum-all))

;; --- 关键字参数（&key）---
(defun make-person (name &key (age 0) (email "") (active t))
  (format nil "~A (年龄:~A, 邮箱:~A, 活跃:~A)" name age email active))

(format t "~A~%" (make-person "王五"))
(format t "~A~%" (make-person "王五" :age 30))
(format t "~A~%" (make-person "王五" :email "wang@example.com" :active nil))

;; --- 混合参数 ---
(defun full-example (required &optional opt &rest rest)
  (format t "required=~A opt=~A rest=~A~%"
          required opt rest))

(full-example "必需" "可选" "rest1" "rest2" :key1 "自定义")

;; --- &aux 辅助变量 ---
(defun with-aux (x &aux (doubled (* 2 x)))
  (format nil "x=~A, doubled=~A" x doubled))

(format t "~A~%" (with-aux 21))


;;; ----------------------------------------------------------
;;; 3. lambda 匿名函数
;;; ----------------------------------------------------------

(format t "~%=== lambda ===~%")

;; lambda 创建匿名函数
(let ((square (lambda (x) (* x x))))
  (format t "lambda square 5: ~A~%" (funcall square 5)))

;; 直接调用
(format t "直接调用: ~A~%" (funcall (lambda (x y) (+ x y)) 3 4))

;; lambda 作为参数
(format t "mapcar lambda: ~A~%"
        (mapcar (lambda (x) (* x x x)) '(1 2 3 4)))


;;; ----------------------------------------------------------
;;; 4. 高阶函数
;;; ----------------------------------------------------------

(format t "~%=== 高阶函数 ===~%")

;; funcall — 调用函数对象
(format t "funcall: ~A~%" (funcall #'+ 1 2 3))

;; apply — 将列表作为参数展开调用
(format t "apply: ~A~%" (apply #'+ '(1 2 3 4 5)))
(format t "apply 混合: ~A~%" (apply #'+ 1 2 '(3 4 5)))

;; mapcar — 映射
(format t "mapcar: ~A~%" (mapcar #'1+ '(1 2 3)))

;; mapc — 只执行副作用，不收集结果
(mapc (lambda (x) (format t "  处理 ~A~%" x)) '(a b c))

;; mapcan — 映射并拼接结果
(format t "mapcan: ~A~%"
        (mapcan (lambda (x) (list x (* x 10))) '(1 2 3)))

;; maplist — 对列表的每个 cdr 应用函数
(format t "maplist: ~A~%"
        (maplist (lambda (sub) (length sub)) '(a b c d)))

;; remove-if / remove-if-not
(format t "remove-if: ~A~%" (remove-if #'oddp '(1 2 3 4 5)))
(format t "remove-if-not: ~A~%" (remove-if-not #'oddp '(1 2 3 4 5)))

;; find-if — 查找第一个满足条件的元素
(format t "find-if: ~A~%" (find-if #'evenp '(1 3 5 8 9)))

;; position-if — 查找位置
(format t "position-if: ~A~%" (position-if #'evenp '(1 3 5 8 9)))

;; count-if — 计数
(format t "count-if: ~A~%" (count-if #'evenp '(1 2 3 4 5 6)))

;; every / some / notany / notevery
(format t "every evenp: ~A~%" (every #'evenp '(2 4 6)))
(format t "some evenp: ~A~%" (some #'evenp '(1 3 4)))
(format t "notany oddp: ~A~%" (notany #'oddp '(2 4 6)))

;; sort — 排序
(format t "sort: ~A~%" (sort (list 3 1 4 1 5 9 2 6) #'<))
(format t "sort 降序: ~A~%" (sort (list 3 1 4 1 5) #'>))
(format t "sort 按字符串: ~A~%"
        (sort (list "banana" "apple" "cherry") #'string<))


;;; ----------------------------------------------------------
;;; 5. 闭包（Closure）
;;; ----------------------------------------------------------

(format t "~%=== 闭包 ===~%")

;; 闭包捕获词法作用域中的变量
(defun make-counter ()
  (let ((count 0))
    (lambda ()
      (incf count))))

(let ((counter1 (make-counter))
      (counter2 (make-counter)))
  (format t "counter1: ~A~%" (funcall counter1))  ; 1
  (format t "counter1: ~A~%" (funcall counter1))  ; 2
  (format t "counter1: ~A~%" (funcall counter1))  ; 3
  (format t "counter2: ~A~%" (funcall counter2))  ; 1（独立计数）
  )

;; 闭包实现私有状态
(defun make-bank-account (initial-balance)
  (let ((balance initial-balance))
    (lambda (operation &optional amount)
      (case operation
        (:deposit  (incf balance amount))
        (:withdraw (if (>= balance amount)
                       (decf balance amount)
                       (error "余额不足")))
        (:balance  balance)))))

(let ((account (make-bank-account 100)))
  (format t "余额: ~A~%" (funcall account :balance))
  (format t "存入50: ~A~%" (funcall account :deposit 50))
  (format t "取出30: ~A~%" (funcall account :withdraw 30))
  (format t "余额: ~A~%" (funcall account :balance)))

;; 闭包缓存（记忆化）
(defun memoize (fn)
  (let ((cache (make-hash-table)))
    (lambda (x)
      (multiple-value-bind (val found) (gethash x cache)
        (if found
            val
            (setf (gethash x cache) (funcall fn x)))))))

(let ((slow-square (memoize (lambda (x)
                              (format t "  计算 ~A 的平方...~%" x)
                              (* x x)))))
  (format t "第一次: ~A~%" (funcall slow-square 5))
  (format t "第二次(缓存): ~A~%" (funcall slow-square 5)))


;;; ----------------------------------------------------------
;;; 6. 递归
;;; ----------------------------------------------------------

(format t "~%=== 递归 ===~%")

;; 阶乘
(defun factorial (n)
  (if (<= n 1)
      1
      (* n (factorial (1- n)))))

(format t "10! = ~A~%" (factorial 10))

;; 斐波那契
(defun fib (n)
  (if (< n 2)
      n
      (+ (fib (- n 1)) (fib (- n 2)))))

(format t "fib(20) = ~A~%" (fib 20))

;; 尾递归（SBCL 会优化）
(defun sum-list (lst &optional (acc 0))
  (if (null lst)
      acc
      (sum-list (rest lst) (+ acc (first lst)))))

(format t "sum-list: ~A~%" (sum-list '(1 2 3 4 5)))


;;; ----------------------------------------------------------
;;; 7. flet / labels 局部函数
;;; ----------------------------------------------------------

(format t "~%=== flet / labels ===~%")

;; flet — 定义局部函数（不能递归）
(flet ((double (x) (* 2 x))
       (triple (x) (* 3 x)))
  (format t "double(5)=~A triple(5)=~A~%" (double 5) (triple 5)))

;; labels — 定义局部函数（可以递归和互相调用）
(labels ((even-p (n)
           (if (zerop n) t (odd-p (1- n))))
         (odd-p (n)
           (if (zerop n) nil (even-p (1- n)))))
  (format t "even-p(10)=~A~%" (even-p 10))
  (format t "odd-p(7)=~A~%" (odd-p 7)))


;;; ----------------------------------------------------------
;;; 8. 文档字符串与函数属性
;;; ----------------------------------------------------------

(format t "~%=== 文档字符串 ===~%")

(defun documented-function (x)
  "这是一个有文档的函数。

参数 X：输入值。
返回值：X 的两倍。"
  (* 2 x))

;; 获取文档字符串
(format t "文档: ~A~%" (documentation 'documented-function 'function))

;; describe 查看函数信息
(describe 'documented-function)

(format t "~%==== 04 结束 ====~%")
