;;;; ============================================================
;;;; examples/08_sequences/main.lisp — 数组、向量与序列函数
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 向量：make-array、字面量 #(...)、fill-pointer 动态向量
;;;;   2. 多维数组：#2A、aref 多下标、array-dimensions
;;;;   3. 序列抽象：列表/向量/字符串通吃的函数族
;;;;   4. map 家族与 map-into
;;;;   5. 查找/计数/过滤/替换
;;;;   6. sort 与 stable-sort（破坏性！必须接返回值）
;;;;   7. every/some/search/mismatch
;;;;   8. coerce：列表 ↔ 向量 ↔ 字符串
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 向量
;;; ----------------------------------------------------------

(let ((v (make-array 5 :initial-element 0)))
  (setf (aref v 0) 10)
  (setf (aref v 1) 20)
  (format t "向量: ~S  aref 0: ~A  长度: ~A~%" v (aref v 0) (length v)))

;; 字面量向量：#(...) ——注意它是**常量**，别对它做破坏性修改
(format t "字面量: ~S~%" #(1 2 3))

;; 动态向量：:adjustable + :fill-pointer，配 vector-push-extend
(let ((v (make-array 0 :adjustable t :fill-pointer 0 :element-type 'integer)))
  (vector-push-extend 10 v)
  (vector-push-extend 20 v)
  (vector-push-extend 30 v)
  (format t "动态向量: ~S  fill-pointer: ~A~%" v (fill-pointer v))
  (vector-pop v)
  (format t "vector-pop 后: ~S~%" v))

;; vector 函数直接造
(format t "vector 函数: ~S~%" (vector :a :b :c))


;;; ----------------------------------------------------------
;;; 2. 多维数组
;;; ----------------------------------------------------------

(let ((mat (make-array '(3 3) :initial-element 0)))
  (setf (aref mat 0 0) 1)
  (setf (aref mat 1 1) 1)
  (setf (aref mat 2 2) 1)
  (format t "矩阵: ~S~%" mat)
  (format t "维度: ~S  总元素: ~A  mat[1,1]: ~A~%"
          (array-dimensions mat) (array-total-size mat) (aref mat 1 1))
  (format t "row-major 顺序访问第 4 个: ~A~%" (row-major-aref mat 3)))

;; 字面量写法 #2A
(format t "#2A 字面量: ~S~%" #2A((1 2) (3 4)))


;;; ----------------------------------------------------------
;;; 3. 序列抽象：一份 API，三种容器
;;; ----------------------------------------------------------

;; length / elt / subseq 对列表、向量、字符串都成立
(flet ((seq-info (s)
         (format t "类型 ~A → 长度 ~A，第 0 个 ~S，前两段 ~S~%"
                 (if (listp s) "列表" (if (stringp s) "字符串" "向量"))
                 (length s) (elt s 0) (subseq s 0 2))))
  (seq-info '(10 20 30))
  (seq-info #(10 20 30))
  (seq-info "abc"))

;; copy-seq / reverse / count / position 通用
(format t "reverse 字符串: ~A，count 元素: ~A~%"
        (reverse "lisp") (count 1 '(1 2 1 3 1)))


;;; ----------------------------------------------------------
;;; 4. map 家族
;;; ----------------------------------------------------------

;; map 指定**返回类型**；mapcar 只返回列表
(format t "map → list: ~S~%" (map 'list #'+ '(1 2 3) #(10 20 30)))
(format t "map → vector: ~S~%" (map 'vector #'* '(1 2) '(3 4)))
(format t "map → string: ~S~%" (map 'string #'char-upcase "abc"))
(format t "mapcar 多表: ~S~%" (mapcar #'list '(a b) '(1 2)))

;; mapc（只要副作用）/ mapcan（nconc 拼接结果）
(mapc (lambda (x) (format t "  访问 ~A~%" x)) '(p q))
(format t "mapcan: ~S~%" (mapcan (lambda (x) (list x (* x 10))) '(1 2)))

;; map-into：破坏性地写回第一个参数（省内存的写法）
(let ((target (vector 0 0 0)))
  (map-into target #'+ #(1 2 3) #(10 10 10))
  (format t "map-into: ~S~%" target))

;; reduce：:initial-value 与 :from-end
(format t "reduce +: ~A~%" (reduce #'+ '(1 2 3 4 5)))
(format t "reduce - 从尾: ~A~%"
        (reduce #'- '(1 2 3) :from-end t :initial-value 10))


;;; ----------------------------------------------------------
;;; 5. 查找 / 计数 / 过滤 / 替换
;;; ----------------------------------------------------------

(format t "find 3: ~S  find-if 偶数: ~S~%"
        (find 3 '(1 2 3)) (find-if #'evenp '(1 3 6 8)))
(format t "position-if: ~A  count-if: ~A~%"
        (position-if #'evenp '(1 3 6 8)) (count-if #'evenp '(1 2 3 4 5 6)))

;; remove 系非破坏，delete 系破坏（同 n 前缀规则）。
;; delete 对**列表**的行为可移植（真的删掉元素）；对定长向量的
;; 效果是「实现定义」的（SBCL 会挪动元素、CLISP 保持不动）——
;; 所以破坏性操作永远接返回值用，且别对简单向量 delete
(format t "remove 1: ~S  remove-if 奇数: ~S~%"
        (remove 1 '(1 2 1 3)) (remove-if #'oddp '(1 2 3 4)))
(format t "delete 列表（接返回值）: ~S~%" (delete 2 (list 1 2 3 2)))

;; remove-duplicates 保留**最后**一次出现
(format t "remove-duplicates: ~S~%"
        (remove-duplicates '(a b a c b)))

;; substitute / substitute-if
(format t "substitute: ~S~%" (substitute :x 2 '(1 2 3 2)))
(format t "substitute-if: ~S~%"
        (substitute-if 0 #'evenp '(1 2 3 4) ))


;;; ----------------------------------------------------------
;;; 6. sort 与 stable-sort：破坏性！
;;; ----------------------------------------------------------

;; sort 会重排原序列，必须**接返回值**使用
(format t "sort 拷贝: ~S~%" (sort (copy-list '(3 1 4 1 5 9 2 6)) #'<))
(format t "sort 向量: ~S~%" (sort (vector 3 1 2) #'>))
(format t "按字符串: ~S~%"
        (sort (list "banana" "apple" "cherry") #'string<))

;; 多键排序：主键相等时按次键（stable-sort 保证等价元素原顺序）
(format t "stable-sort 两键: ~S~%"
        (stable-sort (list (list 2 :b) (list 1 :x) (list 2 :a))
                     (lambda (p q) (< (first p) (first q)))))

;; merge：归并两个**已排序**序列
(format t "merge: ~S~%"
        (merge 'list (list 1 3 5) (list 2 4 6) #'<))


;;; ----------------------------------------------------------
;;; 7. 谓词与搜索
;;; ----------------------------------------------------------

(format t "every 偶: ~A  some 偶: ~A  notany 偶: ~A~%"
        (every #'evenp '(2 4)) (some #'evenp '(1 4)) (notany #'evenp '(1 3)))
(format t "search 子序列: ~A  mismatch 首异处: ~A~%"
        (search '(2 3) '(1 2 3 4)) (mismatch '(1 2 3) '(1 2 9)))


;;; ----------------------------------------------------------
;;; 8. coerce：序列之间换形态
;;; ----------------------------------------------------------

(format t "表→向量: ~S~%" (coerce '(1 2 3) 'vector))
(format t "向量→表: ~S~%" (coerce #(1 2 3) 'list))
(format t "字符表→串: ~S~%" (coerce '(#\h #\i) 'string))
(format t "串→字符表: ~S~%" (coerce "hi" 'list))

(format t "~%==== 08 结束 ====~%")
