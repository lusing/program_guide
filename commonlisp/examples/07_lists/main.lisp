;;;; ============================================================
;;;; examples/07_lists/main.lisp — cons 与列表、五种相等
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. cons 单元：唯一的砖，点对与链表
;;;;   2. 构造与取值：list / first..tenth / nth / last / nthcdr
;;;;   3. append 的拷贝语义与尾部共享
;;;;   4. 破坏性操作：n 开头（nreverse / nconc）必须接返回值
;;;;   5. 当栈用：push / pop / pushnew / adjoin
;;;;   6. 查找：member / assoc / 关联表与属性表
;;;;   7. 相等：eq / eql / equal / equalp / = 各管一段
;;;;   8. 树视角：copy-tree / subst
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. cons 单元
;;; ----------------------------------------------------------

(let ((pair (cons 1 2)))
  (format t "点对: ~S  car: ~A  cdr: ~A~%" pair (car pair) (cdr pair)))

;; 列表 = 右边接着 cons 的链；(1 2 3) 就是 (cons 1 (cons 2 (cons 3 nil)))
(let ((*print-pretty* nil))
  (format t "手搭的链: ~S~%" (cons 1 (cons 2 (cons 3 nil))))
  (format t "list 函数搭的: ~S~%" (list 1 2 3)))

;; 混合嵌套
(format t "嵌套: ~S~%" (list 1 (list 2 3) 4))
(format t "谓词: consp ~A listp ~A atom ~A null ~A~%"
        (consp '(1)) (listp '(1)) (atom 5) (null nil))

;; NIL 是唯一「既是符号又是列表」的东西
(format t "cdr 到底是 NIL: ~A，'(1) 的 cdr: ~S~%"
        (null (cdr '(1))) (cdr '(1)))


;;; ----------------------------------------------------------
;;; 2. 取值全家桶
;;; ----------------------------------------------------------

(let ((l '(a b c d e)))
  (format t "first..third: ~A ~A ~A~%" (first l) (second l) (third l))
  (format t "nth 0/3: ~A ~A，nth 越界得 NIL: ~S~%"
          (nth 0 l) (nth 3 l) (nth 99 l))
  (format t "nthcdr 2: ~S，last: ~S（注意 last 给的是**表**）~%"
          (nthcdr 2 l) (last l))
  (format t "butlast 去尾: ~S  length: ~A~%" (butlast l) (length l)))


;;; ----------------------------------------------------------
;;; 3. append：只拷贝「除最后一个以外」的参数
;;; ----------------------------------------------------------

(let* ((b (list 3 4))
       (joined (append '(1 2) b)))
  (format t "append: ~S~%" joined)
  ;; 前面的参数被拷贝，最后一个是**直接共享**的——证据：
  (format t "尾部与 b 共享同一存储: ~A~%" (eq (nthcdr 2 joined) b)))

;; 所以「改 b 的内容，append 的结果跟着变」；改前面的拷贝则不影响
(let* ((b (list 3 4))
       (joined (append '(1 2) b)))
  (setf (car b) :改了)
  (format t "改 b 后 joined 也变: ~S（共享的代价）~%" joined))


;;; ----------------------------------------------------------
;;; 4. 破坏性操作：n 开头
;;; ----------------------------------------------------------

;; nreverse 原地翻转让旧引用「部分失效」——必须接返回值
(let* ((l (list 1 2 3))
       (r (nreverse l)))
  (format t "nreverse 结果: ~S~%" r))

;; 习惯：破坏前先 copy-list
(let* ((l (list 1 2 3))
       (r (nreverse (copy-list l))))
  (format t "拷贝后再破坏，原表完好: 原 ~S 翻 ~S~%" l r))

;; nconc = append 的破坏版
(format t "nconc: ~S~%" (nconc (list 1 2) (list 3) (list 4 5)))


;;; ----------------------------------------------------------
;;; 5. 当栈用
;;; ----------------------------------------------------------

(let ((stack '()))
  (push 1 stack)
  (push 2 stack)
  (push 3 stack)
  (format t "push 三次: ~S~%" stack)
  (pop stack)
  (format t "pop 一次:   ~S~%" stack)
  (pushnew 2 stack)                      ; 已存在就不重复压
  (pushnew 9 stack)
  (format t "pushnew:    ~S~%" stack)
  (format t "adjoin(非破坏版 pushnew): ~S~%"
          (adjoin 1 stack)))


;;; ----------------------------------------------------------
;;; 6. 查找：member / assoc / rassoc
;;; ----------------------------------------------------------

(format t "member 3: ~S（返回从命中处开始的**子表**）~%"
        (member 3 '(1 2 3 4)))
(format t "member :test 自定义: ~S~%"
        (member "b" '("a" "b") :test #'string=))
(format t "member-if: ~S~%" (member-if #'evenp '(1 3 6 8)))

;; 关联表 alist：(键 . 值) 点对的表
(let ((scores '((alice . 95) (bob . 87) (carol . 92))))
  (format t "assoc bob: ~S~%" (assoc 'bob scores))
  (format t "取值用 cdr: ~A~%" (cdr (assoc 'bob scores)))
  (format t "查不到得 NIL: ~S~%" (assoc 'dave scores))
  ;; rassoc 按值反查
  (format t "rassoc 92: ~S~%" (rassoc 92 scores)))

;; 属性表 plist：交错 (键 值 键 值)，配 getf
(let ((pl '(name "李雷" :age 31 :lang "lisp")))
  (format t "getf :age: ~A~%" (getf pl :age))
  (format t "getf 默认值: ~A~%" (getf pl :city "未填")))


;;; ----------------------------------------------------------
;;; 5+2. tailp / ldiff：共享检测
;;; ----------------------------------------------------------

(let ((l '(1 2 3 4)))
  (format t "tailp '(3 4) '(1 2 3 4): ~A~%" (tailp '(3 4) l))
  (format t "tailp 用 nthcdr 的结果必然成立: ~A~%"
          (tailp (nthcdr 2 l) l))
  (format t "ldiff 前缀: ~S~%" (ldiff l (nthcdr 2 l))))


;;; ----------------------------------------------------------
;;; 7. 五种相等
;;; ----------------------------------------------------------

;; eq   同一对象（符号、小整数可靠；字符串/列表别赌）
(format t "eq 同一符号: ~A~%" (eq 'a 'a))
;; eql  eq + 同类型数字/字符
(format t "eql 同值浮点: ~A，跨类型: ~A~%"
        (eql 2.0 2.0) (eql 2 2.0))
;; equal 结构相同（列表、字符串逐项比）
(format t "equal 两张同构表: ~A~%" (equal '(1 (2 3)) (list 1 (list 2 3))))
(format t "equal 同内容字符串: ~A~%" (equal "abc" "abc"))
(format t "equal 向量不吃这套: ~A~%" (equal #(1 2) #(1 2)))
;; equalp equal + 忽略大小写 + 数值 = + 结构递归（向量也进来了）
(format t "equalp 同构向量: ~A，忽略字符串大小写: ~A~%"
        (equalp #(1 2) #(1 2)) (equalp "ABC" "abc"))
;; =  只比数字，跨类型按数值比
(format t "= 2 与 2.0: ~A~%" (= 2 2.0))

;; 经典反面教材：两个 "abc" 字面量是否 eq 是**未规定的**——
;; 有的实现共享字面量（T），有的各自分配（NIL），千万别写这种代码
(format t "字面量是否 eq 未规定 → 用 equal 才安全~%")


;;; ----------------------------------------------------------
;;; 8. 树视角
;;; ----------------------------------------------------------

;; 表可以任意嵌套成树；copy-list 只拷「脊椎」，copy-tree 深拷贝
(let* ((tree (list 1 (list 2 3)))
       (shallow (copy-list tree))
       (deep (copy-tree tree)))
  (setf (car (second tree)) :改了)
  (format t "浅拷贝跟着变: ~S~%" shallow)
  (format t "深拷贝不受影响: ~S~%" deep))

;; subst 在树里替换
(format t "subst: ~S~%" (subst 'x 'b '(a b (a b) c)))

(format t "~%==== 07 结束 ====~%")
