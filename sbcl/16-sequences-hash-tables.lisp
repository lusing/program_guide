;;;; ============================================================
;;;; 16-sequences-hash-tables.lisp — 序列与哈希表实战
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

(format t "~%=== 例程 16 执行完毕 ===~%")
