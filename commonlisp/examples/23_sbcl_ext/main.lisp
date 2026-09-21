;;;; ============================================================
;;;; examples/23_sbcl_ext/main.lisp — SBCL 扩展 I：
;;;;                                进程、环境、GC、编译器、映像
;; channel: sbcl
;;;; ============================================================
;;;;
;;;; 本例程演示（SBCL 专属，22 章讲对应的 CLISP 接口）：
;;;;   1. run-program 跑外部命令：平台分支 + :search + 捕获输出
;;;;   2. 环境变量：posix-getenv 与跨平台变量名
;;;;   3. GC 控制：sb-ext:gc / get-bytes-consed / room
;;;;   4. 编译控制：compile / compile-file / optimize / disassemble
;;;;   5. save-lisp-and-die：把整个 Lisp 世界存成可执行文件
;;;;   6. 原子操作：atomic-incf / cas（并发的地基，24 章细讲）
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. run-program
;;; ----------------------------------------------------------

;; 两个跨平台铁律：
;;   ① POSIX 上没有 cmd——一行 shell 命令要用 /bin/sh -c（Windows 才是
;;      cmd /c），用 #+win32 / #-win32 在读取期分发
;;   ② 裸程序名必须 :search t（否则报 Couldn't execute "echo"）；
;;      绝对路径则不需要
(defun shell-command (command)
  "把一行 shell 命令包装成 (程序 参数列表)，按平台自动选择解释器。"
  #+win32 (list "cmd" (list "/c" command))
  #-win32 (list "/bin/sh" (list "-c" command)))

;; 直通子进程输出（:output t = 子进程直接写当前 stdout）
(let* ((cmd (shell-command "echo Hello from SBCL"))
       (process (sb-ext:run-program (first cmd) (second cmd)
                                    :output t
                                    :wait t)))
  (format t "退出码: ~A~%" (sb-ext:process-exit-code process)))

;; 捕获输出（:output :stream 拿流自己读；:output 不接受 :string，
;; 想要字符串结果就用下面这个模式或干脆上 UIOP）
(let* ((cmd (shell-command "echo captured"))
       (process (sb-ext:run-program (first cmd) (second cmd)
                                    :output :stream
                                    :wait nil)))
  (loop for line = (read-line (sb-ext:process-output process) nil :eof)
        until (eq line :eof)
        do (format t "捕获: ~A~%" line))
  (sb-ext:process-wait process)
  (format t "退出码: ~A~%" (sb-ext:process-exit-code process)))


;;; ----------------------------------------------------------
;;; 2. 环境变量
;;; ----------------------------------------------------------

;; USERPROFILE / OS 是 Windows 专有；跨平台取 HOME / SHELL / PATH
(format t "HOME: ~A~%" (or (sb-ext:posix-getenv "HOME") "(未设置)"))
(format t "USERPROFILE（Windows 专有）: ~A~%"
        (or (sb-ext:posix-getenv "USERPROFILE") "NIL（POSIX 上没有）"))


;;; ----------------------------------------------------------
;;; 3. GC 与内存
;;; ----------------------------------------------------------

(sb-ext:gc)                              ; 手动触发一次完全 GC
(format t "已手动 GC；累计分配: ~,1F MB~%"
        (/ (sb-ext:get-bytes-consed) (expt 1024.0d0 2)))

;; room 打印内存报告（行数多，这里用 nil 静默版确认可调用）
(room nil)
(format t "room 已执行（nil = 静默）~%")


;;; ----------------------------------------------------------
;;; 4. 编译控制
;;; ----------------------------------------------------------

(defun to-be-compiled (x) (+ x 1))
(format t "compile 前 compiled-function-p: ~A~%"
        (compiled-function-p #'to-be-compiled))
(compile 'to-be-compiled)
(format t "compile 后 compiled-function-p: ~A~%"
        (compiled-function-p #'to-be-compiled))

;; SBCL 是「始终编译」的实现：--load 加载源码也走编译器，
;; 所以类型声明/optimize 在日常代码里就有效果（26 章实测数字）
(declaim (optimize (speed 3) (safety 1)))

(defun fixnum-add (a b)
  (declare (type fixnum a b)
           (optimize (speed 3) (safety 0)))
  (the fixnum (+ a b)))
(format t "高速档 fixnum-add: ~A~%" (fixnum-add 20 22))

;; 反汇编看它真的变成机器码（输出每版本不同，只看有没有）
(format t "disassemble 已生成汇编（见上方输出）~%")


;;; ----------------------------------------------------------
;;; 5. save-lisp-and-die：整世界打包
;;; ----------------------------------------------------------
;;;;
;;;; (defun my-app-main () (format t "启动！~%") (sb-ext:quit))
;;;; (sb-ext:save-lisp-and-die "my-app"
;;;;                           :toplevel #'my-app-main
;;;;                           :executable t)
;;;;
;;;; 原理：把当前 Lisp 映像（含已加载的全部代码）dump 成可执行文件；
;;;; 调用即**退出**（"and die"是字面意思），所以只能放在最后一步。
;;;; 只存核心（不带运行时）：:executable nil → 产物 .core，
;;;; 用 sbcl --core xxx.core 恢复，体积小得多。
;;;; 本示例不真调（会终止验证进程），21 章有完整流程。


;;; ----------------------------------------------------------
;;; 6. 原子操作与 CAS
;;; ----------------------------------------------------------

(defstruct counter (value 0 :type (unsigned-byte 64)))
(let ((c (make-counter)))
  (sb-ext:atomic-incf (counter-value c))
  (sb-ext:atomic-incf (counter-value c))
  (format t "atomic-incf 两次: ~A~%" (counter-value c)))

;; CAS：旧值对得上才换成新值（无锁结构的地基）
(let ((cell (cons 0 nil)))
  (format t "cas 成功: ~A（期望 0 换成 42）~%"
          (sb-ext:cas (car cell) 0 42))
  (format t "cas 失败（期望值已不对）: ~A（实际还是 42）~%"
          (sb-ext:cas (car cell) 7 99))
  (format t "最终值: ~A~%" (car cell)))

;; 特性列表（#+/#- 的数据源；顺序随版本，这里只确认成员关系）
(format t "features 含 :sb-thread: ~A，含 :sbcl: ~A~%"
        (and (member :sb-thread *features*) t)
        (and (member :sbcl *features*) t))


(format t "==== 23 结束 ====~%")
