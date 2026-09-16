;;;; ============================================================
;;;; 16-sequences-hash-tables.lisp — 序列与哈希表实战
;;;;
;;;; 本例程演示：
;;;;   1. 序列的筛选与映射（remove-if-not / mapcar / reduce）
;;;;   2. 哈希表的建立与遍历（make-hash-table / maphash）
;;;;   3. 词频统计的完整小例子
;;;;
;;;; 运行方式：
;;;;   sbcl --noinform --non-interactive --no-userinit \
;;;;        --load 16-sequences-hash-tables.lisp
;;;; ============================================================

(format t "~%=== 序列与哈希表 ===~%")

;; 序列转换与筛选
(let* ((numbers '(1 2 3 4 5 6))
       (evens (remove-if-not #'evenp numbers))
       (squares (mapcar (lambda (x) (* x x)) evens)))
  (format t "原始: ~A~%" numbers)
  (format t "偶数: ~A~%" evens)
  (format t "平方: ~A~%" squares))

;; 向量处理
(let* ((v (vector 10 20 30 40))
       (sum (reduce #'+ v)))
  (format t "向量: ~A, sum=~A~%" v sum))

;; 哈希表示例：词频统计
(defun word-frequency (words)
  (let ((table (make-hash-table :test 'equal)))
    (dolist (w words table)
      (incf (gethash w table 0)))))

(let* ((words '("lisp" "sbcl" "lisp" "macro" "sbcl" "lisp"))
       (freq (word-frequency words)))
  (maphash (lambda (k v)
             (format t "~A => ~A~%" k v))
           freq))

(format t "~%==== 16 结束 ====~%")
