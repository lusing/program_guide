;;;; ============================================================
;;;; examples/14_macros/main.lisp — 宏 I：定义、反引号、展开
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defmacro：宏接收「没求值的代码」，返回「新代码」
;;;;   2. 反引号模板：` , ,@ 三件套
;;;;   3. macroexpand / macroexpand-1：把宏看穿
;;;;      （只展开自己的宏——内置宏的展开形态是实现细节，22 章）
;;;;   4. 宏 vs 函数：什么时候必须用宏
;;;;   5. &body 与宏参数解构
;;;;   6. 实用宏五连：inc / repeat / aif / lazy / 生成 HTML 的 DSL
;;;;   7. 编译期计算：宏在展开时就把活干完
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. defmacro 基础
;;; ----------------------------------------------------------

;; 宏 = 代码 → 代码 的函数。参数是**未求值的形式**，返回值会被编译
(defmacro my-when (condition &body body)
  "类似 when：条件为真时按顺序执行 body。"
  `(if ,condition (progn ,@body) nil))

(my-when (> 3 2)
  (format t "my-when: 成立~%")
  (format t "my-when: 可以有多条~%"))

;; 宏参数**不求值**——这正是宏存在的意义
(defmacro show-expr (expr)
  "同时展示表达式本身和它的值（函数做不到：实参早就被求值了）"
  `(progn
     (format t "  表达式: ~S~%" ',expr)
     (format t "  值:     ~S~%" ,expr)))

(show-expr (+ 1 2 3))
(show-expr (list 'a 'b))


;;; ----------------------------------------------------------
;;; 2. 反引号模板
;;; ----------------------------------------------------------

;; ` 模板 ,插值 ,@拼列表——宏代码 90% 长这样
(let ((x 10) (items '(1 2 3)))
  (let ((*print-pretty* nil))
    (format t "模板结果: ~S~%" `(start ,x mid ,@items end))
    ;; 等价的手工构造：
    (format t "手工等价: ~S~%"
            (append (list 'start x 'mid) items (list 'end)))))

;; 嵌套模板与 ,. （破坏性拼接，少用）认得即可；
;; 规则记住一条：模板里**只有** , 和 ,@ 后面的东西被求值


;;; ----------------------------------------------------------
;;; 3. macroexpand：看穿宏
;;; ----------------------------------------------------------

(let ((*print-pretty* nil))
  (format t "my-when 一层展开: ~S~%"
          (macroexpand-1 '(my-when (> 3 2) (print :a) (print :b))))
  ;; macroexpand 一路展开到不再是宏为止
  (format t "完全展开:         ~S~%"
          (macroexpand '(my-when t (my-when t 42)))))

;; 内置宏也能展开，但各实现形态不同（SBCL 的 when 展成 if，CLISP 展成
;; if+progn）——所以：调试时看展开没问题，**程序逻辑别依赖它**


;;; ----------------------------------------------------------
;;; 4. 宏 vs 函数
;;; ----------------------------------------------------------

;; 函数：实参先求值。想写 (inc x)「原地自增」的函数版本？不可能——
;; 函数拿不到「x 这个位置」，只拿得到值
(defmacro inc (place &optional (delta 1))
  `(setf ,place (+ ,place ,delta)))

(let ((x 10))
  (inc x)
  (format t "inc 后 x=~A~%" x)
  (inc x 5)
  (format t "inc 5 后 x=~A~%" x))

;; 判断标准：需要「位置」（setf）、需要「不求值」（短路 and/or）、
;; 需要「新语法」（loop）→ 宏；其余 → 函数


;;; ----------------------------------------------------------
;;; 5. &body 与参数解构
;;; ----------------------------------------------------------

;; &body = &rest 的别名，但明确表示「这是代码体」，编辑器缩进会配合
(defmacro my-progn (&body body)
  `(progn ,@body))

(my-progn
  (format t "解构宏第一行~%")
  (format t "解构宏第二行~%"))

;; 宏参数可以像解构绑定一样「拆形状」
(defmacro with-point ((x y) pair &body body)
  `(let ((,x (car ,pair))
         (,y (cdr ,pair)))
     ,@body))

(with-point (head tail) '(1 2 3)
  (format t "解构点对: head=~A tail=~S~%" head tail))


;;; ----------------------------------------------------------
;;; 6. 实用宏五连
;;; ----------------------------------------------------------

;; ① repeat：新控制结构
(defmacro repeat (n &body body)
  (let ((i (gensym)))
    `(dotimes (,i ,n) ,@body)))
(repeat 3 (format t "repeat ×3~%"))

;; ② aif（anaphoric if）：把测试结果暴露成 it——宏才能玩的把戏
(defmacro aif (test then &optional else)
  `(let ((it ,test))
     (if it ,then ,else)))
(aif (find 3 '(1 2 3 4))
     (format t "aif 找到: ~A~%" it)
     (format t "aif 没找到~%"))

;; ③ lazy / force：延迟求值
(defmacro lazy (expr)
  `(lambda () ,expr))
(let ((promise (lazy (progn
                       (format t "  [惰性值：现在才计算]~%")
                       (* 6 7)))))
  (format t "先创建，不计算~%")
  (format t "force 得到: ~A~%" (funcall promise)))

;; ④ 生成代码的宏：一次定义一批函数
(defmacro def-checker (name pred)
  `(defun ,name (x) (if (funcall ,pred x) :是 :否)))
(def-checker positive? #'plusp)
(def-checker long-list? (lambda (l) (and (listp l) (> (length l) 2))))
(format t "代码生成: (positive? 3) → ~A，(long-list? '(1 2 3)) → ~A~%"
        (positive? 3) (long-list? '(1 2 3)))

;; ⑤ 迷你 HTML DSL：把数据直接「写」成输出代码
(defmacro html (&body tags)
  `(progn
     ,@(mapcar (lambda (tag)
                 (let ((name (string-downcase (symbol-name (first tag)))))
                   `(format t "<~A>~A</~A>~%" ,name ,@(rest tag) ,name)))
               tags)))
(html
  (:title "宏教程")
  (:body "DSL 演示"))


;;; ----------------------------------------------------------
;;; 7. 编译期计算
;;; ----------------------------------------------------------

;; 宏在**展开期**求值——展开期干的活不占运行时间
(defmacro sum-1-to-100 ()
  (let ((result (loop for i from 1 to 100 sum i)))
    `',result))

(format t "编译期算好的 5050: ~A~%" (sum-1-to-100))
;; disassemble 看得见常量折叠（SBCL 上）——26 章细讲


(format t "~%==== 14 结束 ====~%")
