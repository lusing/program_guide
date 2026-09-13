;;;; ============================================================
;;;; 11-sbcl-extensions.lisp — SBCL 专有扩展
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. sb-ext 包概览
;;;;   2. 保存与恢复 Lisp 映像（save-lisp-and-die）
;;;;   3. 运行外部程序（run-program）
;;;;   4. 环境变量与命令行参数
;;;;   5. GC 控制与内存信息
;;;;   6. 编译器控制
;;;;   7. 调试与检查工具
;;;;   8. 其他实用扩展
;;;;
;;;; 运行方式：sbcl --script 11-sbcl-extensions.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. sb-ext 包概览
;;; ----------------------------------------------------------

(format t "~%=== sb-ext 包 ===~%")

;; sb-ext 是 SBCL 的扩展包，包含 SBCL 特有的功能
;; 常用符号：
;;   sb-ext:quit              — 退出
;;   sb-ext:save-lisp-and-die — 保存映像
;;   sb-ext:run-program       — 运行外部程序
;;   sb-ext:*posix-argv*      — 命令行参数
;;   sb-ext:posix-getenv      — 环境变量
;;   sb-ext:gc                — 垃圾回收
;;   sb-ext:gc-time           — GC 时间
;;   sb-ext:lock-package      — 锁定包
;;   sb-ext:unlock-package    — 解锁包

(format t "SBCL 版本: ~A~%" (lisp-implementation-version))
(format t "实现类型: ~A~%" (lisp-implementation-type))
(format t "机器类型: ~A~%" (machine-type))
(format t "机器版本: ~A~%" (machine-version))
(format t "软件类型: ~A~%" (software-type))
(format t "软件版本: ~A~%" (software-version))


;;; ----------------------------------------------------------
;;; 2. 保存与恢复 Lisp 映像
;;; ----------------------------------------------------------

(format t "~%=== save-lisp-and-die ===~%")

;; save-lisp-and-die 将当前 Lisp 进程保存为可执行文件
;;
;; 参数：
;;   :executable t       — 生成独立可执行文件
;;   :toplevel #'fn      — 启动时调用的函数
;;   :save-runtime-options t — 保存运行时选项
;;   :compression t      — 压缩（需要 SBCL 编译时启用）
;;   :purify t           — 净化（将静态数据移到只读页）
;;
;; 示例（在 REPL 中执行）：
;;
;;   (defun my-app-main ()
;;     (format t "我的应用启动了！~%")
;;     (sb-ext:quit))
;;
;;   (sb-ext:save-lisp-and-die "my-app"
;;                             :toplevel #'my-app-main
;;                             :executable t)
;;
;; 然后可以直接运行：./my-app

(format t "save-lisp-and-die 用法见注释~%")

;; 保存核心映像（不含运行时，体积更小）
;; (sb-ext:save-lisp-and-die "core-file.core")
;; 恢复：sbcl --core core-file.core


;;; ----------------------------------------------------------
;;; 3. 运行外部程序
;;; ----------------------------------------------------------

(format t "~%=== run-program ===~%")

;; run-program 运行外部程序
;; 参数：
;;   program   — 程序路径
;;   args      — 参数列表
;;   :output   — 输出目标（:stream, t, pathname, nil）
;;   :input    — 输入源
;;   :wait     — 是否等待完成
;;   :search   — 是否在 PATH 中搜索

;; 简单调用（Windows 环境）
(let ((process (sb-ext:run-program "cmd" '("/c" "echo Hello from SBCL")
                                   :output :stream
                                   :wait t)))
  (when process
    (format t "退出码: ~A~%" (sb-ext:process-exit-code process))))

;; 捕获输出
(let* ((process (sb-ext:run-program "cmd" '("/c" "echo captured output")
                                     :output :stream
                                     :wait nil))
       (stream (sb-ext:process-output process)))
  (when stream
    (loop for line = (read-line stream nil :eof)
          until (eq line :eof)
          do (format t "捕获: ~A~%" line))
    (sb-ext:process-wait process)
    (format t "退出码: ~A~%" (sb-ext:process-exit-code process))))

;; 异步执行
(let ((process (sb-ext:run-program "cmd" '("/c" "timeout /t 1 >nul && echo done")
                                    :wait nil)))
  (format t "进程已启动，PID: ~A~%" (sb-ext:process-pid process))
  (format t "进程存活: ~A~%" (sb-ext:process-alive-p process))
  (sb-ext:process-wait process)
  (format t "进程结束，退出码: ~A~%" (sb-ext:process-exit-code process)))


;;; ----------------------------------------------------------
;;; 4. 环境变量与命令行参数
;;; ----------------------------------------------------------

(format t "~%=== 环境变量 ===~%")

;; 获取环境变量
(format t "USERPROFILE: ~A~%" (sb-ext:posix-getenv "USERPROFILE"))
(format t "OS: ~A~%" (sb-ext:posix-getenv "OS"))

;; 命令行参数
(format t "命令行参数: ~A~%" sb-ext:*posix-argv*)

;; 获取程序名
(format t "程序名: ~A~%" (first sb-ext:*posix-argv*))

;; 获取参数（跳过程序名和 --script）
(defun get-script-args ()
  "获取脚本参数（跳过 sbcl 自身参数）。"
  (let ((args sb-ext:*posix-argv*))
    (if (and (second args) (string= (second args) "--script"))
        (cddr args)
        (cdr args))))

(format t "脚本参数: ~A~%" (get-script-args))


;;; ----------------------------------------------------------
;;; 5. GC 控制与内存信息
;;; ----------------------------------------------------------

(format t "~%=== GC 与内存 ===~%")

;; 手动触发 GC
(format t "触发 GC...~%")
(sb-ext:gc)

;; 获取 GC 统计信息
(format t "GC 时间: ~A 秒~%"
        (/ (sb-ext:get-bytes-consed) (expt 1024 2)))

;; 内存使用
(room t)  ; 简要内存报告

;; 完整内存报告
;; (room)  ; 详细内存报告

;; 获取已分配字节数
(format t "已分配: ~A MB~%"
        (/ (sb-ext:get-bytes-consed) (expt 1024 2)))


;;; ----------------------------------------------------------
;;; 6. 编译器控制
;;; ----------------------------------------------------------

(format t "~%=== 编译器 ===~%")

;; 编译单个函数
(defun slow-function (x)
  (+ x 1))

(format t "编译前: ~A~%" (compiled-function-p #'slow-function))
(compile 'slow-function)
(format t "编译后: ~A~%" (compiled-function-p #'slow-function))

;; 编译文件
;; (compile-file "my-file.lisp")
;; (load "my-file.fasl")

;; 优化声明
(declaim (optimize (speed 3) (safety 1) (debug 0)))

(defun fast-add (a b)
  (declare (type fixnum a b)
           (optimize (speed 3) (safety 0)))
  (+ a b))

(format t "fast-add: ~A~%" (fast-add 10 20))

;; 查看编译器笔记
;; (compile-file "file.lisp" :verbose t)

;; 反汇编
(format t "~%反汇编 fast-add:~%")
(disassemble #'fast-add)


;;; ----------------------------------------------------------
;;; 7. 调试与检查工具
;;; ----------------------------------------------------------

(format t "~%=== 调试工具 ===~%")

;; describe — 查看对象信息
(describe 'sb-ext:quit)

;; inspect — 交互式检查（在 REPL 中使用）
;; (inspect (make-hash-table))

;; trace — 跟踪函数调用
(defun traced-function (x)
  (* x 2))

(trace traced-function)
(traced-function 21)
(untrace traced-function)

;; step — 单步执行（在 REPL 中使用）
;; (step (+ 1 2 3))

;; time — 测量执行时间
(format t "~%time 宏:~%")
(time (loop for i from 1 to 1000000 sum i))

;; 获取内部时间
(let ((start (get-internal-real-time)))
  (loop for i from 1 to 1000000 sum i)
  (let ((end (get-internal-real-time)))
    (format t "耗时: ~,3F 秒~%"
            (/ (- end start) internal-time-units-per-second))))

;; 获取通用时间
(format t "当前时间: ~A~%" (get-universal-time))
(multiple-value-bind (sec min hour day month year dow dst tz)
    (decode-universal-time (get-universal-time))
  (format t "~A-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D~%"
          year month day hour min sec)
  (format t "星期: ~A, 夏令时: ~A, 时区: ~A~%" dow dst tz))


;;; ----------------------------------------------------------
;;; 8. 其他实用扩展
;;; ----------------------------------------------------------

(format t "~%=== 其他扩展 ===~%")

;; 退出
;; (sb-ext:quit)                    ; 正常退出
;; (sb-ext:quit :unix-status 1)     ; 带错误码退出
;; (sb-ext:exit :code 0 :abort t)   ; 立即退出

;; 获取所有线程
(format t "当前线程: ~A~%" sb-thread:*current-thread*)

;; 原子操作
(defstruct counter (value 0 :type (unsigned-byte 64)))
(let ((c (make-counter)))
  (sb-ext:atomic-incf (counter-value c))
  (sb-ext:atomic-incf (counter-value c))
  (format t "原子计数: ~A~%" (counter-value c)))

;; CAS（比较并交换）
(let ((cell (cons 0 nil)))
  (sb-ext:cas (car cell) 0 42)
  (format t "CAS 后: ~A~%" (car cell)))

;; 取消 finalization
;; (sb-ext:finalize object function)
;; (sb-ext:cancel-finalization object)

;; 浮点信息
(format t "浮点基数: ~A~%" (float-radix 1.0d0))

;; 字节序
(format t "字节序: ~A~%"
        #+little-endian "小端"
        #+big-endian "大端")

;; 特性列表（条件编译）
(format t "~%特性列表（部分）:~%")
(dolist (f (subseq *features* 0 (min 15 (length *features*))))
  (format t "  ~A~%" f))

(format t "~%=== 例程 11 执行完毕 ===~%")
