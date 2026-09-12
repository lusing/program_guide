;;;; ============================================================
;;;; 03-control-structures.lisp — 控制结构
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 条件分支（if / when / unless / cond / case）
;;;;   2. 循环（dolist / dotimes / loop / do）
;;;;   3. 跳转（return / return-from / block / tagbody）
;;;;   4. 多值（values / multiple-value-bind）
;;;;   5. 非局部退出（catch / throw）
;;;;
;;;; 运行方式：sbcl --script 03-control-structures.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 条件分支
;;; ----------------------------------------------------------

(format t "~%=== 条件分支 ===~%")

;; if — 最基本的分支（只有 then 和 else）
(if (> 3 2)
    (format t "3 > 2，成立~%")
    (format t "不成立~%"))

;; when — 条件为真时执行多个表达式
(when (> 3 2)
  (format t "when: 条件为真~%")
  (format t "when: 可以执行多个表达式~%"))

;; unless — 条件为假时执行
(unless (< 3 2)
  (format t "unless: 条件为假时执行~%"))

;; cond — 多路分支
(defun grade (score)
  (cond ((>= score 90) "优秀")
        ((>= score 80) "良好")
        ((>= score 60) "及格")
        (t             "不及格")))

(format t "95分: ~A~%" (grade 95))
(format t "75分: ~A~%" (grade 75))
(format t "30分: ~A~%" (grade 30))

;; case / ecase / typecase
(defun describe-day (day)
  (case day
    (:monday    "星期一")
    (:tuesday   "星期二")
    (:wednesday "星期三")
    (:thursday  "星期四")
    (:friday    "星期五")
    (:saturday  "星期六")
    (:sunday    "星期日")
    (otherwise  "未知")))

(format t "~A~%" (describe-day :monday))
(format t "~A~%" (describe-day :friday))

;; ecase — 无匹配时抛出错误
;; (ecase 5 ((1 2) "小") ((3 4) "大"))  ; 这会报错

;; typecase — 按类型分支
(defun process (x)
  (typecase x
    (integer (format t "整数: ~A~%" x))
    (string  (format t "字符串: ~A~%" x))
    (list    (format t "列表，长度 ~A~%" (length x)))
    (t       (format t "其他类型: ~A~%" (type-of x)))))

(process 42)
(process "hello")
(process '(1 2 3))


;;; ----------------------------------------------------------
;;; 2. 循环
;;; ----------------------------------------------------------

(format t "~%=== 循环 ===~%")

;; dolist — 遍历列表
(format t "dolist: ")
(dolist (item '(apple banana cherry))
  (format t "~A " item))
(terpri)

;; dolist 带返回值
(let ((result (dolist (x '(1 2 3) 'done)
                (format t "~A " x))))
  (format t "~%dolist 返回值: ~A~%" result))

;; dotimes — 固定次数循环
(format t "dotimes: ")
(dotimes (i 5)
  (format t "~A " i))
(terpri)

;; loop — 强大的迭代宏
(format t "~%--- loop 基本用法 ---~%")

;; 简单计数
(loop for i from 1 to 10
      do (format t "~A " i))
(terpri)

;; 收集结果
(let ((squares (loop for i from 1 to 5 collect (* i i))))
  (format t "平方: ~A~%" squares))

;; 遍历列表
(loop for item in '(a b c d)
      do (format t "~A " item))
(terpri)

;; 带索引遍历
(loop for item in '(x y z)
      for i from 0
      do (format t "[~A]=~A " i item))
(terpri)

;; 条件过滤
(let ((evens (loop for i from 1 to 20
                   when (evenp i)
                   collect i)))
  (format t "偶数: ~A~%" evens))

;; 累加
(format t "1到100的和: ~A~%"
        (loop for i from 1 to 100 sum i))

;; 找最大值/最小值
(format t "最大值: ~A~%"
        (loop for x in '(3 1 4 1 5 9 2 6) maximize x))

;; 计数
(format t "偶数个数: ~A~%"
        (loop for i from 1 to 20 count (evenp i)))

;; loop 遍历哈希表
(let ((ht (make-hash-table)))
  (setf (gethash 'a ht) 1
        (gethash 'b ht) 2)
  (loop for k being the hash-keys of ht
        using (hash-value v)
        do (format t "~A=~A " k v))
  (terpri))

;; loop 提前退出
(loop for i from 1 to 100
      when (> i 5)
      do (return)
      do (format t "~A " i))
(terpri)

;; do — 更底层的循环
(format t "~%--- do 循环 ---~%")
(do ((i 0 (1+ i))
     (sum 0 (+ sum i)))
    ((>= i 10) (format t "do 循环 sum=~A~%" sum))
  (format t "  i=~A sum=~A~%" i sum))

;; do* — 变量按顺序绑定
(do* ((x 1 (1+ x))
      (y x (* 2 x)))
     ((> x 5))
  (format t "x=~A y=~A~%" x y))


;;; ----------------------------------------------------------
;;; 3. 跳转
;;; ----------------------------------------------------------

(format t "~%=== 跳转 ===~%")

;; block / return-from — 具名块退出
(block outer
  (dotimes (i 10)
    (when (= i 5)
      (format t "在 i=5 时退出 block~%")
      (return-from outer "提前退出"))
    (format t "i=~A " i)))

;; 隐式块：defun 自动创建与函数同名的 block
(defun find-first-even (lst)
  (dolist (x lst)
    (when (evenp x)
      (return-from find-first-even x)))
  nil)

(format t "第一个偶数: ~A~%" (find-first-even '(1 3 5 8 9 10)))

;; tagbody / go — 类似 goto（不常用，但有时有用）
(format t "~%tagbody 示例:~%")
(let ((i 0))
  (tagbody
   start
     (format t "i=~A " i)
     (incf i)
     (when (< i 5) (go start)))
  (terpri))


;;; ----------------------------------------------------------
;;; 4. 多值
;;; ----------------------------------------------------------

(format t "~%=== 多值 ===~%")

;; values — 返回多个值
(defun divide (a b)
  (values (floor a b) (mod a b)))

;; multiple-value-bind — 接收多个值
(multiple-value-bind (q r) (divide 17 5)
  (format t "17 ÷ 5 = ~A 余 ~A~%" q r))

;; multiple-value-list — 将多值转为列表
(format t "多值列表: ~A~%" (multiple-value-list (divide 17 5)))

;; nth-value — 获取第 N 个值
(format t "第二个值: ~A~%" (nth-value 1 (divide 17 5)))


;;; ----------------------------------------------------------
;;; 5. 非局部退出（catch / throw）
;;; ----------------------------------------------------------

(format t "~%=== catch / throw ===~%")

(defun process-items (items)
  (catch :done
    (dolist (item items)
      (when (eq item 'stop)
        (format t "遇到 stop，抛出 :done~%")
        (throw :done "被 throw 终止"))
      (format t "处理: ~A~%" item))
    "正常完成"))

(format t "结果: ~A~%" (process-items '(a b c)))
(format t "结果: ~A~%" (process-items '(a b stop c d)))

;; unwind-protect — 确保清理代码执行
(format t "~%unwind-protect 示例:~%")
(catch 'exit
  (unwind-protect
       (progn
         (format t "  执行主要逻辑~%")
         (throw 'exit "退出"))
    (format t "  清理代码总是执行~%")))

(format t "~%=== 例程 03 执行完毕 ===~%")
