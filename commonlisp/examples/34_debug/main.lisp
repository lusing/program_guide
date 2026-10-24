;;;; ============================================================
;; channel: sbcl   （调试器/追踪 API：sb-debug / sb-di / sb-ext 专属）
;;;; examples/34_debug/main.lisp — 调试器、追踪与单步
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 调试器的进入途径与两道钩子
;;;;   2. 程序化抓栈（sb-debug:map-backtrace / print-backtrace）
;;;;   3. TCO 与 debug 政策对栈帧的影响
;;;;   4. disable-debugger / enable-debugger 往返
;;;;   5. trace 基本用法
;;;;   6. trace :condition 与 :print
;;;;   7. trace :wherein（含尾调用坑）
;;;;   8. trace :report 自定义报告函数
;;;;   9. trace labels 局部函数与 :methods
;;;;  10. handler-bind 抓栈实战模式
;;;;
;;;; 运行方式（推荐 --load）：
;;;;   sbcl --noinform --non-interactive --no-userinit --load examples/34_debug/main.lisp
;;;;
;;;; 注：交互式调试器命令（帧选择/list-locals/breakpoint/step 等）只能在
;;;;     REPL 里边敲边看，本例程覆盖的是可以批处理验证的部分。
;;;;     所有 trace 演示都用 (let ((*trace-output* *standard-output*)) ...)
;;;;     包住，保证输出走 stdout、stderr 保持干净。
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 调试器的进入途径与两道钩子
;;; ----------------------------------------------------------

(format t "~%=== 调试器进入途径与钩子 ===~%")

;; 四条进入途径：未处理的 error、break、signal 命中 *break-on-signals*、
;; invoke-debugger。批处理里能安全演示的是 invoke-debugger ——
;; 它不做 handler 搜索，直接进调试器；进之前先过两道钩子。

;; signal 默认很安静：没人处理的 warning 只是过去，不进调试器
(format t "signal 返回值: ~S~%"
        (signal 'simple-warning :format-control "没人处理，安静通过"))

;; *debugger-hook*（ANSI）：进调试器前调用；但 break 进入时不触发。
;; sb-ext:*invoke-debugger-hook*（SBCL 扩展）：任何进入途径都触发。
;; --non-interactive 镜像在 *invoke-debugger-hook* 上装了「打栈后退出」
;; 的钩子，所以演示前要先把它绑成 NIL。
(let ((sb-ext:*invoke-debugger-hook* nil)
      (*debugger-hook* (lambda (condition hook)
                         (declare (ignore condition hook))
                         (invoke-restart 'recover))))
  (format t "钩子拦截结果: ~S~%"
          (restart-case
              (invoke-debugger (make-condition 'simple-error
                                 :format-control "演示：被钩子拦截"))
            (recover () :RECOVERED))))

;; 生产部署：--disable-debugger 让未处理错误立即非零退出，
;; 或在 *invoke-debugger-hook* 里记日志后调 restart 恢复。


;;; ----------------------------------------------------------
;;; 2. 程序化抓栈
;;; ----------------------------------------------------------

(format t "~%=== 程序化抓栈 ===~%")

;; sb-debug:map-backtrace 对每帧调一次函数；sb-di 包里是帧内省 API。
;; 收集帧名（debug-fun-name）——批处理里读栈的正确姿势。
(defun frame-names ()
  (let ((names '()))
    (sb-debug:map-backtrace
     (lambda (f) (push (sb-di:debug-fun-name (sb-di:frame-debug-fun f)) names))
     :count 10)
    (nreverse names)))

(defun caller-nontail () (cons :keep (frame-names)))  ; 非尾调用：帧留着
(defun caller-tail () (frame-names))                  ; 尾调用：帧可能被吃

(format t "非尾调用帧在栈上: ~S~%"
        (if (member 'caller-nontail (cdr (caller-nontail))) :PRESENT :GONE))
(format t "尾调用帧在栈上:   ~S~%"
        (if (member 'caller-tail (caller-tail)) :PRESENT :GONE))

;; print-backtrace 打到任意流——记日志、发告警都靠它
(let ((s (make-string-output-stream)))
  (sb-debug:print-backtrace :stream s :count 5)
  (format t "抓到回溯: ~A 字节~%" (length (get-output-stream-string s))))

;; 其他签名（交互/日志场景用）：
;;   (sb-debug:backtrace count stream)      直接打到流
;;   (sb-debug:backtrace-as-list &optional count)   每帧一个字符串
;;   (sb-debug:backtrace-all-threads)       多线程各打一份


;;; ----------------------------------------------------------
;;; 3. TCO 与 debug 政策
;;; ----------------------------------------------------------

(format t "~%=== debug 政策与 TCO ===~%")

;; 默认政策（debug 1）下尾调用帧 :GONE（上面已见）。
;; debug 3 禁尾调用合并、禁 lifetime 分析——同形状的调用帧变 :PRESENT。
(defun tco-default () (frame-names))
(format t "debug 1 尾调用帧: ~S~%"
        (if (member 'tco-default (tco-default)) :PRESENT :GONE))

(declaim (optimize (debug 3)))
(defun tco-debug3 () (frame-names))
(declaim (optimize (debug 1)))
(format t "debug 3 尾调用帧: ~S~%"
        (if (member 'tco-debug3 (tco-debug3)) :PRESENT :GONE))

;; 政策门槛（手册原文）：
;;   debug > max(speed, space)      → return / restart-frame 可用
;;   再 > compilation-speed         → 可单步（steppable）


;;; ----------------------------------------------------------
;;; 4. disable-debugger / enable-debugger
;;; ----------------------------------------------------------

(format t "~%=== 开关调试器 ===~%")

;; disable-debugger：装「打栈后退出进程」的钩子（批处理模式同款）。
;; enable-debugger：恢复正常交互调试器。两者可反复往返。
(format t "往返结果: ~S~%"
        (progn (sb-ext:disable-debugger)
               (sb-ext:enable-debugger)
               (sb-ext:disable-debugger)
               :OK))
(sb-ext:enable-debugger)   ; 例程跑完恢复默认，不影响后续章节


;;; ----------------------------------------------------------
;;; 5. trace 基本用法
;;; ----------------------------------------------------------

(format t "~%=== trace 基本用法 ===~%")

(defun fact34 (n)
  (if (zerop n) 1 (* n (fact34 (1- n)))))

(let ((*trace-output* *standard-output*))
  (trace fact34)
  (format t "fact34(3) = ~S~%" (fact34 3))
  (untrace fact34))
;; 输出形如：
;;   0: (FACT34 3)
;;     1: (FACT34 2)
;;       ...
;;       3: (FACT34 0)
;;       3: FACT34 returned 1
;;     ...
;;   0: FACT34 returned 6
;; 深度前缀 = 缩进格数 / sb-debug:*trace-indentation-step*（默认 2），
;; 缩进上限 sb-debug:*max-trace-indentation*（默认 40）。


;;; ----------------------------------------------------------
;;; 6. trace :condition 与 :print
;;; ----------------------------------------------------------

(format t "~%=== trace :condition / :print ===~%")

(defun add34 (a b) (+ a b))

(let ((*trace-output* *standard-output*))
  ;; :condition 在调用处求值；参数按位置用 (sb-debug:arg n) 取
  (trace add34 :condition (= (sb-debug:arg 0) 10)
               :print (list :args (sb-debug:arg 0) (sb-debug:arg 1)))
  (format t "add34(1,2)=~S add34(10,20)=~S~%" (add34 1 2) (add34 10 20))
  (untrace add34))
;; 只有 add34(10,20) 触发，并多打一行：
;;   0: (LIST :ARGS (ARG 0) (ARG 1)) = (:ARGS 10 20)
;; 变体：:condition-after（返回值上判断，(sb-debug:arg n) 此时指第 n 个
;; 返回值）、:condition-all（进出都判断）；:print 同样有 -after / -all。


;;; ----------------------------------------------------------
;;; 7. trace :wherein（含尾调用坑）
;;; ----------------------------------------------------------

(format t "~%=== trace :wherein ===~%")

;; :wherein 沿真实栈帧链找外层调用者名字——外层帧必须真的在栈上。
(defun inner34 (x) (* x 2))
(defun outer34 (x) (1+ (inner34 x)))     ; 非尾调用：帧留得住
;; 反例：(defun outer34 (x) (inner34 x)) 尾调用，TCO 吃掉 outer34 帧，
;; :wherein 永远匹配不上、一行都不打——排查「trace 没输出」先查这个。

(let ((*trace-output* *standard-output*))
  (trace inner34 :wherein outer34)
  (format t "直接调 inner34: ~S（不打印）~%" (inner34 5))
  (format t "经由 outer34:    ~S（打印）~%" (outer34 5))
  (untrace inner34))


;;; ----------------------------------------------------------
;;; 8. trace :report 自定义报告
;;; ----------------------------------------------------------

(format t "~%=== trace :report ===~%")

;; :report 的值必须是「函数名」（宏展开期检查，(or symbol function)），
;; 临时写 lambda 会报 "is not a valid TRACE :REPORT type"——先 defun。
;; 报告函数 5 个参数：深度、函数名、:enter/:exit、帧、值列表。
;; 输出去向由你自己决定（默认报告才走 *trace-output*）。
(defun reporter34 (depth name kind frame values)
  (declare (ignore depth frame))
  (format t "  [my-report] ~A ~A ~S~%" kind name values))

(defun noisy34 (x) (1+ x))

(trace noisy34 :report reporter34)
(format t "noisy34(41) = ~S~%" (noisy34 41))
(untrace noisy34)


;;; ----------------------------------------------------------
;;; 9. trace labels 局部函数与 :methods
;;; ----------------------------------------------------------

(format t "~%=== trace labels / :methods ===~%")

;; 局部函数的名字形式：(labels 内层名 :in 外层名)
(defun outer-labels34 (n)
  (labels ((helper (k) (if (zerop k) 0 (1+ (helper (1- k))))))
    (helper n)))

(let ((*trace-output* *standard-output*))
  (trace (labels helper :in outer-labels34))
  (format t "outer-labels34(2) = ~S~%" (outer-labels34 2))
  (untrace))

;; 泛函名字形式 (setf foo)、(:method 名 (特化...)) 同样可 trace。
;; :methods t 一次性追某个泛函的全部方法：
(defgeneric area34 (shape))
(defmethod area34 ((s integer)) (* s s))
(defmethod area34 ((s string)) (length s))

(let ((*trace-output* *standard-output*))
  (trace area34 :methods t)
  (format t "area34(3)=~S area34(\"lisp\")=~S~%" (area34 3) (area34 "lisp"))
  (untrace area34))

;; 其他选项速查：
;;   :break / :break-after / :break-all   触发时进断点（接调试器）
;;   :encapsulate {t|nil|:default}        封装方式（默认 sb-debug:
;;                                        *trace-encapsulate-default* = T）
;;   :function 形式                        追无名的函数对象
;; known return convention 不符的函数（如返回值个数非常规的）追踪报
;; 「Error tracing ...: Unknown return convention」时换 :encapsulate t。


;;; ----------------------------------------------------------
;;; 10. handler-bind 抓栈实战
;;; ----------------------------------------------------------

(format t "~%=== handler-bind 抓栈实战 ===~%")

;; 目标：错误发生时把栈抓进字符串记日志，然后恢复运行。
;; 顺序是关键——CL 从内到外找 handler：
;;   handler-bind 放内层（handler 返回 NIL、不转移控制，栈还在）；
;;   handler-case 放外层兜底（它才回卷）。
;; 反例：(handler-bind (...) (ignore-errors ...)) —— ignore-errors
;; 的 handler 更内层先跑直接回卷，handler-bind 永远抓不到栈。
(defun crash34 (x y) (+ x y))   ; 运行期传错类型才出错，编译期不警告

(let ((bt-string nil))
  (handler-case
      (handler-bind ((serious-condition
                       (lambda (c)
                         (declare (ignore c))
                         (setf bt-string
                               (with-output-to-string (s)
                                 (sb-debug:print-backtrace :stream s
                                                           :count 5))))))
        (crash34 1 "oops"))
    (serious-condition () nil))
  (format t "栈抓到了吗: ~S~%"
          (and bt-string (search "CRASH34" bt-string) t)))

(format t "~%==== 34 结束 ====~%")
