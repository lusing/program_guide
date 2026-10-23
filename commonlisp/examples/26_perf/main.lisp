;;;; ============================================================
;; channel: sbcl   （SBCL 专属扩展：依赖 sb-thread / sb-alien / sb-profile）
;;;; examples/26_perf/main.lisp — 性能优化
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 类型声明（declare / declaim）
;;;;   2. 优化级别（optimize）
;;;;   3. 内联函数（inline / declaim inline）
;;;;   4. 性能分析（time / sb-profile / sb-sprof）
;;;;   5. 内存优化
;;;;   6. 数值计算优化（fixnum/浮点/矩阵 + 模运算/环绕加法/ctz）
;;;;   7. 尾调用与块编译（TCO 互递归 / start-block）
;;;;   8. 栈分配 dynamic-extent
;;;;   9. 常见性能陷阱
;;;;  10. 基准测试
;;;;
;;;; 运行方式（推荐 --load）：
;;;;   sbcl --noinform --non-interactive --no-userinit --load examples/26_perf/main.lisp
;;;;
;;;; 注：用 --script 也能跑完，但本例里的 sb-profile:report 会往 stderr
;;;;     打一行 "measuring PROFILE overhead..done"，会撞上本目录
;;;;     「stderr 必须为空」的判定；详见文件里第 4 节的注释。
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
;;   1. (sb-profile:profile fn1 fn2 ...)
;;   2. 运行代码
;;   3. (sb-profile:report)
;;   4. (sb-profile:unprofile)
;;
;; 坑：网上常见的「先 (require :sb-profile)」在本版 SBCL 上是错的。
;; SB-PROFILE 已经在**核心里**（CL-USER 默认就用着它），并没有同名的
;; contrib 模块可 require，写了会直接失败并终止：
;;   Don't know how to REQUIRE :SB-PROFILE.
;; 直接调用即可。（对比：SB-SPROF 确实是 contrib 模块，必须 require。）
;; 另外因为 CL-USER 用了 SB-PROFILE，`report` / `reset` 这类名字
;; 不能拿来给自己的函数命名，否则报包锁冲突。

(defun profile-target-1 (n)
  (loop for i from 1 to n sum i))

(defun profile-target-2 (n)
  (loop for i from 1 to n collect (* i i)))

(defun profile-target-3 (n)
  (reduce #'+ (loop for i from 1 to n collect i)))

;; 一个观察记录（不是坑，说明清楚免得误会）：
;; sb-profile:report 在生成报告前会自测一次剖析开销，打印
;;   measuring PROFILE overhead..done
;; 这一行**绕过 Lisp 的 stdout/stderr 流**直接写控制终端：
;;   --load 模式下重定向抓不到它（stdout.txt / stderr.txt 里都没有，但终端上看得见）
;;   --script 模式下它落到 stderr，会让「stderr 必须为空」的判定失败
;; 实测把 *trace-output* 或 *error-output* 绑成广播流都压不掉它，
;; 所以本目录统一按 --load 方式运行（见 run-all.sh / build.ps1）。
(sb-profile:profile profile-target-1 profile-target-2 profile-target-3)

(profile-target-1 100000)
(profile-target-2 10000)
(profile-target-3 100000)

(format t "~%--- 性能报告 ---~%")
(sb-profile:report)
(sb-profile:unprofile)

;; sb-sprof — 统计采样分析器（更准确）
;; 它**是** contrib 模块，必须 require；接口是 START-PROFILING / STOP-PROFILING
;; / REPORT / RESET 以及宏 WITH-PROFILING。
;; macOS（Darwin）上用 :mode :time（墙钟）：:mode :cpu 的剖析信号在 Darwin 上
;; 不按 CPU 用量比例投递到各线程，多线程程序可能采出空调用图。
(require :sb-sprof)

(defun sum-02 (n)
  (declare (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (loop for i fixnum from 1 to n do (incf acc i))
    acc))

;; :report nil = 只采样先不打印，宏返回 body 的值。
;; 注意：body 必须比采样间隔（默认 0.01s）跑得久，否则 with-profiling
;; 会因「一轮下来样本数没涨」打 No sampling progress 警告——所以这里
;; 故意跑一亿次（约 0.1 秒），而不是文档里的十万次。
(format t "with-profiling 跑 sum-02 一亿次: ~A~%"
        (sb-sprof:with-profiling (:max-samples 100 :report nil :mode :time)
          (sum-02 100000000)))

;; 报告走 *trace-output*，绑到 *standard-output* 免得落进 stderr 判定
(format t "--- sb-sprof flat 报告（前 5 行）---~%")
(let ((*trace-output* *standard-output*))
  (sb-sprof:report :type :flat :max 5))
(sb-sprof:reset)


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

;; 模运算优化：logand/logxor/lognot/+/-/ash 组成的表达式树，若掩码是
;; (unsigned-byte 32/64) 这样的好宽度，中间结果全按宽度截断，直接用机器指令
(defun mod-xor (x y)
  (declare (type (unsigned-byte 32) x y))
  (ldb (byte 32 0) (logxor x (lognot y))))
(format t "mod-xor 5 3 = ~A~%" (mod-xor 5 3))

;; 有符号环绕加法惯用法：先按宽度截断，再符号扩展
(defun add64-wrap (a b)
  (declare (type (signed-byte 64) a b))
  (let ((u (ldb (byte 64 0) (+ a b))))
    (logior u (- (mask-field (byte 1 63) u)))))
(format t "add64-wrap 3 4 = ~A~%" (add64-wrap 3 4))
(format t "add64-wrap max+1 = ~A（环绕回最小值）~%"
        (add64-wrap 9223372036854775807 1))

;; ctz（数尾部零）是被识别的惯用法：x86-64/arm64 上一条指令，0 按约定返回 64
(defun ctz (n)
  (declare (type (unsigned-byte 64) n))
  (integer-length (ldb (byte 64 0) (lognor n (- n)))))
(format t "ctz 8 = ~A，ctz 0 = ~A~%" (ctz 8) (ctz 0))


;;; ----------------------------------------------------------
;;; 7. 尾调用与块编译
;;; ----------------------------------------------------------

(format t "~%=== 尾调用与块编译 ===~%")

;; 局部尾递归：labels 的自调用是局部调用，编译出来和命令式循环一样好
(defun recurse-fact (n)
  (labels ((loop* (n total)
             (if (zerop n)
                 total
                 (loop* (1- n) (* n total)))))
    (loop* n 1)))
(format t "recurse-fact 5 = ~A~%" (recurse-fact 5))

;; TCO（尾调用优化）：尾位置的调用编译成「改参数 + 跳转」，不分配新栈帧。
;; 条件：尾位置（不被 let 动态绑定/catch/unwind-protect 等包裹）且 debug ≤ 2。
;; 意义：互递归的一组函数可以当状态机写，每层转移不耗栈。
;; 先 proclaim ftype，免得先定义的 even-p* 引用尚未定义的 odd-p* 触发
;; undefined-function 风格警告（会落进 stderr 判定）。
(declaim (ftype (function (fixnum) t) odd-p* even-p*))
(defun even-p* (n) (if (zerop n) t (odd-p* (1- n))))
(defun odd-p* (n) (if (zerop n) nil (even-p* (1- n))))
(format t "even-p* 1000000 = ~A（互递归一百万层没爆栈）~%" (even-p* 1000000))

;; 块编译：块内 defun 之间的全调用也变局部调用，哪怕调用点在被调函数之前；
;; 非入口函数（这里只有 bc-entry 是入口）不安装全局定义。
(declaim (ftype (function (fixnum) fixnum) bc-helper))
(declaim (sb-ext:start-block bc-entry))
(defun bc-entry (x) (bc-helper (1+ x)))
(defun bc-helper (y) (* y 2))
(declaim (sb-ext:end-block))
(format t "bc-entry 5 = ~A~%" (bc-entry 5))
;; 代价：块内调用不经过 symbol-function，重定义 bc-helper 不影响 bc-entry


;;; ----------------------------------------------------------
;;; 8. 栈分配 dynamic-extent
;;; ----------------------------------------------------------

(format t "~%=== dynamic-extent 栈分配 ===~%")

;; setq 进 DX 变量的 cons 链整条都在栈上，函数返回即释放，零 GC 压力
(defun dx-list-sum (n)
  (let ((xs nil))
    (declare (dynamic-extent xs))
    (dotimes (i n)
      (setq xs (cons (1+ i) xs)))
    (reduce #'+ xs)))
(format t "dx-list-sum 5 = ~A~%" (dx-list-sum 5))

;; &rest 列表是 dynamic-extent 最经典的用法
(defun dx-args (&rest args)
  (declare (dynamic-extent args))
  (length args))
(format t "dx-args 1 2 3 = ~A~%" (dx-args 1 2 3))

;; 构造器声明 inline 的 defstruct，实例也能整个上栈
(declaim (inline make-perf-pt))
(defstruct perf-pt x y)
(defun pt-norm-sq (a b)
  (let ((p (make-perf-pt :x a :y b)))
    (declare (dynamic-extent p))
    (+ (* (perf-pt-x p) (perf-pt-x p))
       (* (perf-pt-y p) (perf-pt-y p)))))
(format t "pt-norm-sq 3 4 = ~A~%" (pt-norm-sq 3 4))
;; 纪律：让 DX 值逃逸出动态范围 = 读垃圾甚至崩映像——声明只被信任不被检查


;;; ----------------------------------------------------------
;;; 9. 常见性能陷阱
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
;;; 10. 基准测试
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

(format t "~%==== 26 结束 ====~%")
