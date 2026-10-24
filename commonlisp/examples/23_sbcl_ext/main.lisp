;;;; ============================================================
;;;; examples/23_sbcl_ext/main.lisp — SBCL 扩展 I：
;;;;                                进程、环境、GC、编译器、映像
;; channel: sbcl
;;;; ============================================================
;;;;
;;;; 本例程演示（SBCL 专属，22 章讲对应的 CLISP 接口）：
;;;;   1. run-program 跑外部命令：平台分支 + :search + 捕获输出
;;;;   2. 环境变量：posix-getenv 与跨平台变量名
;;;;   3. GC 控制：sb-ext:gc / get-bytes-consed / after-gc-hooks / finalize / 弱指针
;;;;   4. 编译控制：compile / compile-file / optimize / disassemble
;;;;   5. save-lisp-and-die：把整个 Lisp 世界存成可执行文件
;;;;   6. 原子操作与 CAS：atomic-incf / atomic-push（car 盒子）/ cas 用户扩展
;;;;   7. 限时三件套：wait-for / with-deadline / with-timeout
;;;;   8. 包锁：lock-package / unlock-package / package-locked-p
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

;; *after-gc-hooks*：2.6.9 里钩子在 finalizer 系统线程**异步**执行，
;; gc 返回时钩子多半还没跑——必须主动同步等待
(defvar *gc-hook-count* 0)
(push (lambda () (incf *gc-hook-count*)) sb-ext:*after-gc-hooks*)
(sb-ext:gc :full t)
(loop repeat 100
      when (plusp *gc-hook-count*) do (return)
      do (sleep 0.01))
(format t "after-gc-hook 已跑 ~A 次（finalizer 线程异步执行）~%" *gc-hook-count*)
(pop sb-ext:*after-gc-hooks*)                ; 我们的钩子在最上面，直接 pop

;; finalize：对象没引用后由 finalizer 线程调用善后函数。
;; 纪律：闭包抓句柄，别抓对象自己（抓了对象就永远回收不掉）
(defstruct (wrapped-handle (:constructor make-wrapped-handle (handle)))
  handle)
(let* ((handle 42)
       (object (make-wrapped-handle handle)))
  (sb-ext:finalize object (lambda () (format t "释放句柄 ~A~%" handle)))
  (format t "finalize 注册后撤销: ~A~%" (sb-ext:cancel-finalization object)))

;; 弱指针：引用不续命，GC 后 value 变 NIL
(let ((wp (sb-ext:make-weak-pointer (list :temporary))))
  (sb-ext:gc :full t)
  (format t "弱指针指向的对象已被回收: ~A~%" (null (sb-ext:weak-pointer-value wp))))


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

;; 普通变量不是可 CAS 位置（编译报 Invalid place to CAS）；
;; 想要「变量语义」的原子盒子，拿 cons 的 car 当
(let ((box (cons nil nil)))
  (sb-ext:atomic-push 1 (car box))
  (sb-ext:atomic-push 2 (car box))
  (format t "atomic-push 两次后 pop: ~A，剩余: ~A~%"
          (sb-ext:atomic-pop (car box)) (car box)))

;; atomic-update：读-改-写一体，update-fn 竞争下可能重试，必须无副作用
(let ((x (cons :count 0)))
  (sb-ext:atomic-update (cdr x) #'+ 10)
  (format t "atomic-update +10: ~A~%" (cdr x)))

;; cas 的用户扩展：定义 (sb-ext:cas 位置名) 函数；只认 (名字 ...) 复合 place
(defvar *foo-cell* 0)
(defun foo-cell () *foo-cell*)
(defun (sb-ext:cas foo-cell) (old new)
  (sb-ext:cas (symbol-value '*foo-cell*) old new))
(format t "自定义 cas place: 旧值 ~A，新值 ~A~%"
        (sb-ext:cas (foo-cell) 0 42) *foo-cell*)


;;; ----------------------------------------------------------
;;; 7. 限时三件套（安全性递减，能用前者就别用后者）
;;; ----------------------------------------------------------

;; ① 调用点 :timeout / wait-for：最安全
(format t "wait-for 立刻成立: ~A~%" (sb-ext:wait-for t :timeout 1))
(format t "wait-for 超时: ~A~%" (sb-ext:wait-for nil :timeout 0.1))

;; ② with-deadline：动态范围共享时间预算，尊重 deadline 的操作都会被掐
(format t "deadline 掐掉 sleep 5: ~A~%"
        (handler-case
            (sb-sys:with-deadline (:seconds 0.2)
              (sleep 5)
              :slept)
          (sb-sys:deadline-timeout () :deadline)))

;; ③ with-timeout：异步打断，最能干也最危险（unwind 可能打在任意指令之间）
(format t "with-timeout 掐掉 sleep 5: ~A~%"
        (handler-case
            (sb-ext:with-timeout 0.2
              (sleep 5)
              :slept)
          (sb-ext:timeout () :timed-out)))


;;; ----------------------------------------------------------
;;; 8. 包锁：防止误改他人包（防手滑的护栏，不是安全机制）
;;; ----------------------------------------------------------

(format t "COMMON-LISP 包默认上锁: ~A~%"
        (sb-ext:package-locked-p (find-package "COMMON-LISP")))

(let* ((p (make-package "CH23-LOCK-DEMO" :use nil))
       (foo (intern "FOO" p)))             ; 锁上后连 intern 新符号都违规，先 intern 好
  (sb-ext:lock-package p)
  (format t "上锁: ~A；锁着定义函数: ~A~%"
          (sb-ext:package-locked-p p)
          ;; 编译器撞锁时会向 *error-output* 打汇总行，演示时静音掉
          (let ((*error-output* (make-broadcast-stream)))
            (handler-case (eval `(defun ,foo () 1))
              (sb-ext:package-lock-violation () :blocked))))
  (sb-ext:unlock-package p)
  (format t "解锁后定义并调用: ~A~%"
          (progn (eval `(defun ,foo () 2)) (funcall foo)))
  (delete-package p))

;; 特性列表（#+/#- 的数据源；顺序随版本，这里只确认成员关系）
(format t "features 含 :sb-thread: ~A，含 :sbcl: ~A~%"
        (and (member :sb-thread *features*) t)
        (and (member :sbcl *features*) t))


(format t "==== 23 结束 ====~%")
