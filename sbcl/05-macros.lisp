;;;; ============================================================
;;;; 05-macros.lisp — 宏编程
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defmacro 定义宏
;;;;   2. 反引号（backquote）与逗号
;;;;   3. macroexpand 展开宏
;;;;   4. gensym 避免变量捕获
;;;;   5. 常用宏模式
;;;;   6. &whole / &environment / &body
;;;;   7. define-symbol-macro
;;;;   8. 宏 vs 函数
;;;;
;;;; 运行方式：sbcl --script 05-macros.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. defmacro 定义宏
;;; ----------------------------------------------------------

(format t "~%=== defmacro 基础 ===~%")

;; 宏在编译时展开，生成代码
(defmacro my-when (condition &body body)
  "类似 when 的简单宏。"
  `(if ,condition
       (progn ,@body)
       nil))

(my-when (> 3 2)
  (format t "my-when: 条件为真~%")
  (format t "my-when: 执行多个表达式~%"))

;; 宏与函数的区别：宏的参数不求值
(defmacro show-expr (expr)
  `(progn
     (format t "表达式: ~S~%" ',expr)
     (format t "结果:   ~A~%" ,expr)))

(show-expr (+ 1 2 3))
(show-expr (list 'a 'b 'c))


;;; ----------------------------------------------------------
;;; 2. 反引号（backquote）与逗号
;;; ----------------------------------------------------------

(format t "~%=== 反引号 ===~%")

;; ` 反引号：类似 quote，但允许 , 和 ,@ 插入值
;; , 逗号：求值并插入
;; ,@ 逗号-at：求值并展开列表

(let ((x 10)
      (lst '(1 2 3)))
  (format t "反引号: ~A~%" `(a ,x b ,@lst c)))

;; 等价于
(let ((x 10)
      (lst '(1 2 3)))
  (format t "手动构造: ~A~%"
          (append (list 'a x 'b) lst (list 'c))))


;;; ----------------------------------------------------------
;;; 3. macroexpand 展开宏
;;; ----------------------------------------------------------

(format t "~%=== macroexpand ===~%")

;; 查看宏展开后的代码
(format t "my-when 展开:~%")
(pprint (macroexpand-1 '(my-when (> 3 2)
                          (format t "hello")
                          (format t "world"))))

(format t "~%when 展开:~%")
(pprint (macroexpand-1 '(when (> 3 2) (format t "yes"))))

(format t "~%loop 展开（部分）:~%")
(pprint (macroexpand-1 '(loop for i from 1 to 3 collect i)))

;; macroexpand 完全展开（包括嵌套宏）
(format t "~%完全展开:~%")
(pprint (macroexpand '(my-when t (when t (print 1)))))


;;; ----------------------------------------------------------
;;; 4. gensym 避免变量捕获
;;; ----------------------------------------------------------

(format t "~%=== gensym ===~%")

;; 错误示例：变量捕获
(defmacro bad-swap (a b)
  `(let ((temp ,a))
     (setf ,a ,b)
     (setf ,b temp)))

;; 如果调用者恰好有名为 temp 的变量，就会出问题
;; (let ((temp 1) (x 2))
;;   (bad-swap temp x))  ; 会出错！

;; 正确做法：使用 gensym
(defmacro good-swap (a b)
  (let ((temp (gensym "TEMP")))
    `(let ((,temp ,a))
       (setf ,a ,b)
       (setf ,b ,temp))))

(let ((x 1) (y 2))
  (good-swap x y)
  (format t "交换后: x=~A y=~A~%" x y))

;; 即使变量名是 temp 也没问题
(let ((temp 100) (val 200))
  (good-swap temp val)
  (format t "交换后: temp=~A val=~A~%" temp val))


;;; ----------------------------------------------------------
;;; 5. 常用宏模式
;;; ----------------------------------------------------------

(format t "~%=== 常用宏模式 ===~%")

;; --- 模式 1: with- 宏（资源管理）---
(defmacro with-timing (&body body)
  "测量代码块的执行时间。"
  (let ((start (gensym "START"))
        (end (gensym "END")))
    `(let ((,start (get-internal-real-time)))
       (prog1 (progn ,@body)
         (let ((,end (get-internal-real-time)))
           (format t "~%耗时: ~,3F 秒~%"
                   (/ (- ,end ,start)
                      internal-time-units-per-second)))))))

(with-timing
  (loop for i from 1 to 1000000 sum i))

;; --- 模式 2: 定义新控制结构 ---
(defmacro repeat (n &body body)
  "重复执行 body N 次。"
  (let ((i (gensym "I")))
    `(dotimes (,i ,n)
       ,@body)))

(repeat 3
  (format t "重复执行~%"))

;; --- 模式 3: 简化定义 ---
(defmacro define-constant (name value &optional doc)
  "定义常量，避免重复定义警告。"
  `(defconstant ,name
     (if (boundp ',name) (symbol-value ',name) ,value)
     ,@(when doc (list doc))))

(define-constant +app-name+ "MyApp" "应用名称")
(define-constant +version+ "1.0.0" "版本号")
(format t "应用: ~A v~A~%" +app-name+ +version+)

;; --- 模式 4: anaphoric 宏 ---
(defmacro aif (test then &optional else)
  "Anaphoric if：将测试结果绑定到 it。"
  `(let ((it ,test))
     (if it ,then ,else)))

(aif (find 3 '(1 2 3 4 5))
     (format t "找到了: ~A~%" it)
     (format t "没找到~%"))

;; --- 模式 5: 延迟求值 ---
(defmacro lazy (expr)
  "创建一个延迟求值的 thunk。"
  `(lambda () ,expr))

(defun force (thunk)
  "强制执行延迟求值。"
  (funcall thunk))

(let ((lazy-val (lazy (progn
                        (format t "  正在计算...~%")
                        (* 6 7)))))
  (format t "创建了延迟值~%")
  (format t "结果: ~A~%" (force lazy-val)))

;; --- 模式 6: 领域特定语言（DSL）---
(defmacro html (&body body)
  "简单的 HTML 生成 DSL。"
  `(progn ,@(mapcar (lambda (form)
                      (if (and (consp form) (keywordp (first form)))
                          (let ((tag (string-downcase (symbol-name (first form)))))
                            `(format t "<~A>~A</~A>~%" ,tag ,@(rest form) ,tag))
                          form))
                    body)))

(html
  (:html "页面内容")
  (:body "主体内容"))


;;; ----------------------------------------------------------
;;; 6. &whole / &body / &rest
;;; ----------------------------------------------------------

(format t "~%=== 宏参数解构 ===~%")

;; &body 与 &rest 类似，但暗示参数是代码体
(defmacro my-progn (&body body)
  `(progn ,@body))

(my-progn
  (format t "第一~%")
  (format t "第二~%"))

;; 宏参数可以解构
(defmacro with-pair ((a b) pair &body body)
  `(let ((,a (car ,pair))
         (,b (cdr ,pair)))
     ,@body))

(with-pair (left right) '(10 . 20)
  (format t "left=~A right=~A~%" left right))

;; 更实用的解构宏
(defmacro with-list ((first-elem second-elem rest-elems) list &body body)
  "解构列表的前两个元素和剩余部分。"
  `(let ((,first-elem (first ,list))
         (,second-elem (second ,list))
         (,rest-elems (cddr ,list)))
     ,@body))

(with-list (a b rest) '(1 2 3 4 5)
  (format t "a=~A b=~A rest=~A~%" a b rest))


;;; ----------------------------------------------------------
;;; 7. define-symbol-macro
;;; ----------------------------------------------------------

(format t "~%=== define-symbol-macro ===~%")

;; 符号宏：将符号展开为表达式
(symbol-macrolet ((*app-version* "2.0.0"))
(format t "版本: ~A~%" *app-version*)
)

;; 实用示例：简化访问
(let ((data (make-hash-table)))
  (setf (gethash 'name data) "SBCL")
  (symbol-macrolet ((name (gethash 'name data)))
    (format t "name = ~A~%" name)))


;;; ----------------------------------------------------------
;;; 8. 宏 vs 函数
;;; ----------------------------------------------------------

(format t "~%=== 宏 vs 函数 ===~%")

;; 函数：参数先求值，再传入
(defun func-add (a b) (+ a b))

;; 宏：参数不求值，直接替换
(defmacro macro-add (a b) `(+ ,a ,b))

;; 宏可以创建新的语法
(defmacro inc (var &optional (amount 1))
  `(setf ,var (+ ,var ,amount)))

(let ((x 10))
  (inc x)
  (format t "inc 后 x=~A~%" x)
  (inc x 5)
  (format t "inc 5 后 x=~A~%" x))

;; 宏展开发生在编译时，零运行时开销
(format t "~%编译时计算:~%")
(defmacro compile-time-calc ()
  (let ((result (loop for i from 1 to 100 sum i)))
    `,result))

(format t "编译时计算结果: ~A~%" (compile-time-calc))

(format t "~%==== 05 结束 ====~%")
