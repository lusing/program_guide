;;;; ============================================================
;;;; 14-performance.lisp — 性能优化
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 类型声明（declare / declaim）
;;;;   2. 优化级别（optimize）
;;;;   3. 内联函数（inline / declaim inline）
;;;;   4. 性能分析（time / sb-profile）
;;;;   5. 内存优化
;;;;   6. 数值计算优化
;;;;   7. 常见性能陷阱
;;;;   8. 基准测试
;;;;
;;;; 运行方式：sbcl --script 14-performance.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 类型声明
;;; ----------------------------------------------------------

(format t "~%=== 类型声明 ===~%")

;; 类型声明帮助编译器生成更高效的代码
;; SBCL 是少数能真正利用类型声明进行优化的 Lisp 实现

;; 未优化的函数
(defun slow-add (a b)
  (+ a b))

;; 使用 declare 声明参数类型
(defun fast-add (a b)
  (declare (type fixnum a b)
           (optimize (speed 3) (safety 0)))
  (+ a b))

(format t "slow-add: ~A~%" (slow-add 10 20))
(format t "fast-add: ~A~%" (fast-add 10 20))

;; fixnum — 机器字大小的整数（最快）
;; (integer 0 100) — 范围整数
;; single-float / double-float — 浮点数
;; simple-array — 简单数组（无 fill-pointer，不可调）
;; (simple-array single-float (100)) — 特定类型的数组

;; 数组类型声明
(defun sum-array (arr)
  (declare (type (simple-array double-float (*)) arr)
           (optimize (speed 3) (safety 0)))
  (let ((sum 0.0d0))
    (declare (type double-float sum))
    (dotimes (i (length arr) sum)
      (incf sum (aref arr i)))))

(let ((arr (make-array 1000 :element-type 'double-float
                            :initial-element 1.0d0)))
  (format t "数组和: ~A~%" (sum-array arr)))

;; declaim — 全局声明
(declaim (optimize (speed 2) (safety 2) (debug 1)))

;; 为特定函数声明类型
(declaim (ftype (function (fixnum fixnum) fixnum) typed-add))
(defun typed-add (a b)
  (+ a b))


;;; ----------------------------------------------------------
;;; 2. 优化级别
;;; ----------------------------------------------------------

(format t "~%=== 优化级别 ===~%")

;; optimize 声明的四个维度（0-3）：
;;   speed   — 执行速度
;;   space   — 代码大小
;;   safety  — 安全检查（类型检查、边界检查）
;;   debug   — 调试信息

;; 常用组合：
;;   开发时：(optimize (speed 1) (safety 3) (debug 3))
;;   发布时：(optimize (speed 3) (safety 1) (debug 0))
;;   极限性能：(optimize (speed 3) (safety 0) (debug 0))

;; 示例：不同优化级别的影响
(defun benchmark-function (n)
  (declare (type fixnum n))
  (let ((sum 0))
    (declare (type fixnum sum))
    (dotimes (i n sum)
      (incf sum i))))

(format t "benchmark(1000000) = ~A~%" (benchmark-function 1000000))

;; 查看编译器输出（在 REPL 中）
;; (compile 'benchmark-function)
;; (disassemble #'benchmark-function)


;;; ----------------------------------------------------------
;;; 3. 内联函数
;;; ----------------------------------------------------------

(format t "~%=== 内联函数 ===~%")

;; declaim inline — 建议编译器内联
(declaim (inline square))
(defun square (x)
  (declare (type double-float x))
  (* x x))

(defun distance (x1 y1 x2 y2)
  (declare (type double-float x1 y1 x2 y2)
           (optimize (speed 3) (safety 0)))
  (sqrt (+ (square (- x2 x1)) (square (- y2 y1)))))

(format t "distance(0,0,3,4) = ~A~%" (distance 0.0d0 0.0d0 3.0d0 4.0d0))

;; notinline — 禁止内联
(declaim (notinline slow-add))

;; definline — SBCL 特有的内联定义宏
;; (sb-ext:definline my-inline-fn (x) (* x x))


;;; ----------------------------------------------------------
;;; 4. 性能分析
;;; ----------------------------------------------------------

(format t "~%=== 性能分析 ===~%")

;; time 宏 — 最基本的性能测量
(format t "--- time 宏 ---~%")
(time (loop for i from 1 to 1000000 sum i))

;; 更精确的计时
(defmacro measure-time (&body body)
  "测量执行时间并返回结果和耗时。"
  (let ((start (gensym "START"))
        (end (gensym "END"))
        (result (gensym "RESULT")))
    `(let ((,start (get-internal-real-time))
           (,result (progn ,@body))
           (,end (get-internal-real-time)))
       (values ,result
               (/ (- ,end ,start)
                  (float internal-time-units-per-second))))))

(multiple-value-bind (result elapsed)
    (measure-time
      (loop for i from 1 to 1000000 sum i))
  (format t "结果: ~A, 耗时: ~,4F 秒~%" result elapsed))

;; sb-profile — SBCL 内置的性能分析器
;; 使用步骤：
;;   1. (require :sb-profile)
;;   2. (sb-profile:profile fn1 fn2 ...)
;;   3. 运行代码
;;   4. (sb-profile:report)
;;   5. (sb-profile:unprofile)

(require :sb-profile)

(defun profile-target-1 (n)
  (loop for i from 1 to n sum i))

(defun profile-target-2 (n)
  (loop for i from 1 to n collect (* i i)))

(defun profile-target-3 (n)
  (reduce #'+ (loop for i from 1 to n collect i)))

(sb-profile:profile profile-target-1 profile-target-2 profile-target-3)

(profile-target-1 100000)
(profile-target-2 10000)
(profile-target-3 100000)

(format t "~%--- 性能报告 ---~%")
(sb-profile:report)
(sb-profile:unprofile)

;; sb-sprof — 统计采样分析器（更准确）
;; (require :sb-sprof)
;; (sb-sprof:with-profiling (:max-samples 1000)
;;   (your-code-here))


;;; ----------------------------------------------------------
;;; 5. 内存优化
;;; ----------------------------------------------------------

(format t "~%=== 内存优化 ===~%")

;; 避免不必要的内存分配
;; 使用 nconc 代替 append（破坏性操作）
;; 使用 delete 代替 remove
;; 使用 vector-push-extend 代替频繁创建新向量

;; 预分配数组
(let ((vec (make-array 1000 :element-type 'fixnum :initial-element 0)))
  (dotimes (i 1000)
    (setf (aref vec i) (* i i)))
  (format t "预分配向量[999] = ~A~%" (aref vec 999)))

;; 使用动态向量避免重复分配
(let ((vec (make-array 0 :adjustable t :fill-pointer 0)))
  (dotimes (i 100)
    (vector-push-extend i vec))
  (format t "动态向量长度: ~A~%" (length vec)))

;; 对象池模式
(defstruct object-pool
  (objects '())
  (create-fn nil)
  (reset-fn nil))

(defun pool-get (pool)
  (or (pop (object-pool-objects pool))
      (funcall (object-pool-create-fn pool))))

(defun pool-return (pool obj)
  (when (object-pool-reset-fn pool)
    (funcall (object-pool-reset-fn pool) obj))
  (push obj (object-pool-objects pool)))

;; 使用对象池
(let ((pool (make-object-pool
             :create-fn (lambda () (make-array 100 :initial-element 0))
             :reset-fn (lambda (arr) (fill arr 0)))))
  (let ((obj (pool-get pool)))
    (setf (aref obj 0) 42)
    (format t "池对象[0] = ~A~%" (aref obj 0))
    (pool-return pool obj))
  (let ((obj (pool-get pool)))
    (format t "复用对象[0] = ~A~%（已重置）" (aref obj 0))
    (pool-return pool obj)))

;; 查看内存使用
(format t "~%内存概况:~%")
(room t)


;;; ----------------------------------------------------------
;;; 6. 数值计算优化
;;; ----------------------------------------------------------

(format t "~%=== 数值计算优化 ===~%")

;; 使用 fixnum 运算（避免 bignum）
(defun fixnum-sum (n)
  (declare (type fixnum n)
           (optimize (speed 3) (safety 0)))
  (let ((sum 0))
    (declare (type fixnum sum))
    (dotimes (i n sum)
      (incf sum i))))

;; 使用 double-float 运算
(defun float-sum (n)
  (declare (type fixnum n)
           (optimize (speed 3) (safety 0)))
  (let ((sum 0.0d0))
    (declare (type double-float sum))
    (dotimes (i n sum)
      (incf sum (float i 1.0d0)))))

(multiple-value-bind (result elapsed)
    (measure-time (fixnum-sum 10000000))
  (format t "fixnum-sum: ~A, ~,4F 秒~%" result elapsed))

(multiple-value-bind (result elapsed)
    (measure-time (float-sum 10000000))
  (format t "float-sum: ~A, ~,4F 秒~%" result elapsed))

;; 矩阵运算优化
(defun matrix-multiply (a b c n)
  (declare (type (simple-array double-float (* *)) a b c)
           (type fixnum n)
           (optimize (speed 3) (safety 0)))
  (dotimes (i n)
    (dotimes (j n)
      (let ((sum 0.0d0))
        (declare (type double-float sum))
        (dotimes (k n)
          (incf sum (* (aref a i k) (aref b k j))))
        (setf (aref c i j) sum)))))

(let ((n 50)
      (a (make-array '(50 50) :element-type 'double-float :initial-element 1.0d0))
      (b (make-array '(50 50) :element-type 'double-float :initial-element 2.0d0))
      (c (make-array '(50 50) :element-type 'double-float :initial-element 0.0d0)))
  (multiple-value-bind (result elapsed)
      (measure-time (matrix-multiply a b c n))
    (declare (ignore result))
    (format t "50x50 矩阵乘法: ~,4F 秒~%" elapsed)))


;;; ----------------------------------------------------------
;;; 7. 常见性能陷阱
;;; ----------------------------------------------------------

(format t "~%=== 性能陷阱 ===~%")

;; 陷阱 1：在循环中创建列表
;; 差：
(defun bad-collect (n)
  (let ((result '()))
    (dotimes (i n)
      (setf result (append result (list i))))  ; O(n²)
    result))

;; 好：
(defun good-collect (n)
  (let ((result '()))
    (dotimes (i n)
      (push i result))  ; O(n)
    (nreverse result)))

(multiple-value-bind (r1 t1) (measure-time (bad-collect 1000))
  (declare (ignore r1))
  (format t "append 方式: ~,4F 秒~%" t1))

(multiple-value-bind (r2 t2) (measure-time (good-collect 1000))
  (declare (ignore r2))
  (format t "push 方式: ~,4F 秒~%" t2))

;; 陷阱 2：不必要的类型转换
;; 差：
(defun bad-string-concat (strings)
  (let ((result ""))
    (dolist (s strings result)
      (setf result (concatenate 'string result s)))))

;; 好：
(defun good-string-concat (strings)
  (with-output-to-string (out)
    (dolist (s strings)
      (write-string s out))))

(let ((strings (loop for i from 1 to 1000 collect (format nil "item~A " i))))
  (multiple-value-bind (r1 t1) (measure-time (bad-string-concat strings))
    (declare (ignore r1))
    (format t "concatenate 方式: ~,4F 秒~%" t1))
  (multiple-value-bind (r2 t2) (measure-time (good-string-concat strings))
    (declare (ignore r2))
    (format t "with-output-to-string 方式: ~,4F 秒~%" t2)))

;; 陷阱 3：在热点路径上使用通用函数
;; 差：对 fixnum 使用 generic +
;; 好：使用类型声明让编译器生成专用代码

;; 陷阱 4：过多的 GC 压力
;; 差：在循环中创建大量临时对象
;; 好：重用对象、使用对象池

;; 陷阱 5：使用 eq 比较数字
;; (eq 1000 1000) 可能返回 nil（bignum）
;; 应该用 eql 或 =

(format t "eq 1000: ~A~%" (eq 1000 1000))
(format t "eql 1000: ~A~%" (eql 1000 1000))
(format t "= 1000: ~A~%" (= 1000 1000))


;;; ----------------------------------------------------------
;;; 8. 基准测试
;;; ----------------------------------------------------------

(format t "~%=== 基准测试 ===~%")

(defun benchmark (name fn &optional (iterations 3))
  "运行基准测试并报告平均时间。"
  (let ((times '()))
    (dotimes (i iterations)
      (multiple-value-bind (result elapsed)
          (measure-time (funcall fn))
        (declare (ignore result))
        (push elapsed times)))
    (let ((avg (/ (reduce #'+ times) (length times)))
          (min-time (reduce #'min times))
          (max-time (reduce #'max times)))
      (format t "~A:~%  平均: ~,4F 秒~%  最小: ~,4F 秒~%  最大: ~,4F 秒~%"
              name avg min-time max-time))))

;; 比较不同实现
(benchmark "loop sum"
           (lambda () (loop for i from 1 to 1000000 sum i)))

(benchmark "dotimes sum"
           (lambda () (let ((s 0)) (dotimes (i 1000000 s) (incf s i)))))

(benchmark "reduce sum"
           (lambda () (reduce #'+ (loop for i from 1 to 1000000 collect i))))

(benchmark "mapcar square"
           (lambda () (mapcar (lambda (x) (* x x))
                              (loop for i from 1 to 100000 collect i))))

(benchmark "loop collect square"
           (lambda () (loop for i from 1 to 100000 collect (* i i))))

(format t "~%=== 例程 14 执行完毕 ===~%")
