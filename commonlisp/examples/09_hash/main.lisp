;;;; ============================================================
;;;; examples/09_hash/main.lisp — 哈希表与结构体
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 哈希表基本操作：setf gethash / 两值返回 / remhash / clrhash
;;;;   2. :test 选择：eql（默认）/ equal（字符串键）必须选对
;;;;   3. 遍历：哈希表**没有顺序**——跨实现/跨运行都不一样，
;;;;      输出必须先排序（可移植性铁律之一）
;;;;   4. 词频统计：incf + gethash 的经典计数模式
;;;;   5. defstruct：一次得到构造器/读取器/谓词/拷贝器
;;;;   6. defstruct :include 继承
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 基本操作
;;; ----------------------------------------------------------

(let ((ht (make-hash-table)))
  (setf (gethash 'name ht) "Common Lisp")
  (setf (gethash 'year ht) 1984)

  ;; gethash 返回两个值：值 + 是否找到（区分「存了 NIL」与「没有」）
  (multiple-value-bind (v found) (gethash 'name ht)
    (format t "name → ~A (found=~A)~%" v found))
  (multiple-value-bind (v found) (gethash 'missing ht)
    (format t "missing → ~A (found=~A)，gethash 默认值: ~A~%"
            v found (gethash 'missing ht :默认)))

  ;; 计数、删除、清空
  (format t "count: ~A~%" (hash-table-count ht))
  (remhash 'year ht)
  (format t "remhash 后 count: ~A~%" (hash-table-count ht))
  (clrhash ht)
  (format t "clrhash 后 count: ~A~%" (hash-table-count ht)))


;;; ----------------------------------------------------------
;;; 2. :test 决定「键相等」的语义
;;; ----------------------------------------------------------

;; 默认 eql：数字/字符按 eql —— 字符串键会**找不到**（除非同一个对象）
(let ((eql-table (make-hash-table)))
  (setf (gethash 42 eql-table) :数字键没问题)
  (format t "eql 数字键: ~A~%" (gethash 42 eql-table)))

(let ((equal-table (make-hash-table :test 'equal)))
  (setf (gethash "lisp" equal-table) :字符串键要equal)
  (format t "equal 字符串键: ~A~%" (gethash "lisp" equal-table)))

;; sxhash：哈希函数的 ANSI 面孔（equal 语义的键 → 同一哈希）
(format t "sxhash 字符串: ~A~%"
        (= (sxhash "abc") (sxhash (copy-seq "abc"))))


;;; ----------------------------------------------------------
;;; 3. 遍历：先排序再输出
;;; ----------------------------------------------------------

;; 哈希表的遍历顺序是**未规定的**：不同实现、不同容量、不同插入
;; 历史都会变——凡是「输出哈希表」的代码必须对键排序
(defun hash-keys-sorted (table)
  (sort (loop for k being each hash-key of table collect k)
        #'string<
        :key (lambda (k) (format nil "~A" k))))

(let ((ht (make-hash-table :test 'equal)))
  (setf (gethash "banana" ht) 2
        (gethash "apple" ht) 1
        (gethash "cherry" ht) 3)
  (format t "排序后的键: ~S~%" (hash-keys-sorted ht))
  ;; maphash 本身不保证顺序；这里只遍历「已排序的键」取值
  (dolist (k (hash-keys-sorted ht))
    (format t "  ~A × ~A~%" k (gethash k ht))))


;;; ----------------------------------------------------------
;;; 4. 词频统计：incf + gethash 计数模式
;;; ----------------------------------------------------------

(defun word-frequency (words)
  (let ((table (make-hash-table :test 'equal)))
    (dolist (w words table)
      (incf (gethash w table 0)))))   ; 找不到给 0，再 +1

(let* ((words '("lisp" "macro" "lisp" "sbcl" "clisp" "lisp" "macro"))
       (freq (word-frequency words))
       (sorted (sort (loop for k being each hash-key of freq
                           collect (cons k (gethash k freq)))
                     #'string< :key #'car)))
  (format t "词频（按词排序）:~%")
  (dolist (pair sorted)
    (format t "  ~A → ~A 次~%" (car pair) (cdr pair))))


;;; ----------------------------------------------------------
;;; 5. defstruct：一行定义一个「记录类型」
;;; ----------------------------------------------------------

;; 默认构造器 make-person、谓词 person-p、读取器 person-name...、
;; 拷贝器 copy-person 全部自动生成
(defstruct person
  name
  (age 0)                          ; 带默认值的槽
  (email "" :type string))         ; 带类型声明的槽

(let ((p (make-person :name "张三" :age 30 :email "z@example.com")))
  (format t "结构体打印: ~S~%" p)
  (format t "读取: 名字 ~A 年龄 ~A~%" (person-name p) (person-age p))
  (setf (person-age p) 31)
  (format t "setf 读取器改字段: ~A~%" (person-age p))
  (format t "谓词: person-p → ~A，别的结构 → ~A~%"
          (person-p p) (person-p (list :name "不是")))
  ;; 拷贝是浅拷贝
  (let ((q (copy-person p)))
    (setf (person-age q) 99)
    (format t "浅拷贝互不影响（简单槽）: 原 ~A 拷 ~A~%"
            (person-age p) (person-age q))))

;; 缺省参数：没给的槽用默认值
(format t "只给名字: ~S~%" (make-person :name "无名氏"))


;;; ----------------------------------------------------------
;;; 6. defstruct :include 继承
;;; ----------------------------------------------------------

(defstruct (student (:include person))
  (school "未知")
  (grade 1))

(let ((s (make-student :name "李四" :age 20 :school "北大" :grade 3)))
  (format t "继承打印: ~S~%" s)
  (format t "父槽照用: ~A，子槽: ~A ~A~%"
          (person-name s) (student-school s) (student-grade s))
  ;; 谓词链：student 也是 person
  (format t "student-p ~A，且 person-p 也认: ~A~%"
          (student-p s) (person-p s)))

(format t "~%==== 09 结束 ====~%")
