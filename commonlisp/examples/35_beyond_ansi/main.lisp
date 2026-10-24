;;;; 35 · 超越 ANSI：SBCL 精选扩展（二）
;; channel: sbcl
;;;; 运行：env SBCL_HOME=/tmp/sbcl-home sbcl --noinform --non-interactive --load main.lisp

(defun hdr (s) (format t "~&---- ~A ----~%" s))

;;; ============================================================
;;; 1. 读取器扩展
;;; ============================================================
(hdr "1 读取器扩展")

;; 扩展包前缀：pkg::(a b c) 给列表里每个符号加包前缀，*package* 不重绑
(assert (equal 'sb-ext::(gc exit) '(sb-ext::gc sb-ext::exit)))

;; 有理数十进制：指数标记 r/R 表示「读成精确有理数」
(assert (eql (read-from-string "1.5r0") 3/2))
(assert (eql (let ((*read-default-float-format* 'rational))
               (read-from-string "1.25"))
             5/4))

;; Unicode 字符名：#\u 后跟十六进制码点
(assert (char= #\u00e1 (code-char 225)))
(format t "reader: ~S ~S ~S~%" (read-from-string "1.5r0") #\u00e1 'sb-ext::(gc))

;;; ============================================================
;;; 2. 包局部昵称（PLN）
;;; ============================================================
(hdr "2 包局部昵称")

(defpackage :foo35 (:use) (:export "X"))
(defpackage :bar35 (:use) (:export "X"))
(defpackage :quux35
  (:use :cl)
  (:local-nicknames (:f :foo35) (:b :bar35)))

;; 在 quux35 里，f:x 就是 foo35:x，b:x 就是 bar35:x，互不影响
(let ((*package* (find-package :quux35)))
  (assert (eq (read-from-string "f:x") 'foo35:x))
  (assert (eq (read-from-string "b:x") 'bar35:x))
  ;; quux35 自己并没有 use foo35/bar35
  (assert (not (member (find-package :foo35)
                       (package-use-list :quux35)))))
(format t "pln: ~S ~S~%" 'foo35:x 'bar35:x)

;;; ============================================================
;;; 3. 包锁：两类违规
;;; ============================================================
(hdr "3 包锁")

(defpackage :lock35 (:use) (:export "FOO") (:lock t))
(assert (sb-ext:package-locked-p :lock35))

;; 包级操作（intern 新符号）→ sb-ext:package-locked-error
(assert (eq (handler-case (intern "NEW" :lock35)
              (sb-ext:package-locked-error () :pkg-locked))
            :pkg-locked))

;; 符号级操作（defun 重定义已存在符号）→ sb-ext:symbol-package-locked-error
;; （用解释模式 eval：编译模式会先经编译器，错误摘要会打印到 *error-output*）
(assert (eq (let ((sb-ext:*evaluator-mode* :interpret))
              (handler-case (eval '(defun lock35:foo () 1))
                (sb-ext:symbol-package-locked-error (e)
                  (sb-ext:package-locked-error-symbol e))))
            'lock35:foo))

;; 授权解锁的两条途径
;; （注意：不能写 'lock35::new —— 读取器读这个记号时就要 intern，
;;   会在加锁的包上当场违规；比较符号名绕开读取期 intern）
(assert (string= (symbol-name (sb-ext:with-unlocked-packages (:lock35)
                                (intern "NEW" :lock35)))
                 "NEW"))
(assert (eql (let ((sb-ext:*evaluator-mode* :interpret))
               (funcall (sb-ext:without-package-locks
                          (eval '(defun lock35:foo () 1)))))
             1))
(format t "locks: 两类违规均可捕获、可授权解锁~%")

;;; ============================================================
;;; 4. 终结器、弱指针与两轮 GC 语义
;;; ============================================================
(hdr "4 终结器与弱指针")

;; 时序谱系（手册 7.5 节 + 实测）：
;;   弱指针 —— 发现死亡的当轮 GC 即失效（确定性）
;;   终结器 —— 异步执行：多线程 SBCL 里在专门的终结器线程跑，
;;             可能在任意线程、任意动态作用域被调，时点无保证
;;   弱哈希条目 —— 发现死亡后的下一轮 GC 清理（确定性）
;; 所以断言只能写「最终会跑」（轮询等待）或「取消后永不跑」；
;; 「GC 返回后还没跑」是竞态，写进测试必然偶发失败。
(defvar *fin35* nil)
(defun fin35 ()
  ;; 创建收进函数：返回后对象彻底失去引用，GC 才可能认定它死亡
  (sb-ext:finalize (list :temp) (lambda () (setf *fin35* :ran)))
  t)
(progn
  (fin35)
  (sb-ext:gc :full t)
  ;; wait-for 是宏：第一参数是未求值的测试式，不是函数
  (assert (sb-ext:wait-for (eq *fin35* :ran) :timeout 5)))

;; cancel-finalization：被取消的终结器永远不跑（负断言是确定性的）
(defvar *cfin35* nil)
(defun cfin35 ()
  (let ((obj (list :temp)))
    (sb-ext:finalize obj (lambda () (setf *cfin35* :ran)))
    obj))
(progn
  (let ((obj (cfin35)))
    (assert (sb-ext:cancel-finalization obj)))   ; 返回 T：曾有终结器
  (sb-ext:gc :full t)
  (assert (null (sb-ext:wait-for (eq *cfin35* :ran) :timeout 0.2))))

(defun wp35 () (sb-ext:make-weak-pointer (list :temp)))
(let ((wp (wp35)))
  (sb-ext:gc :full t)                    ; 当轮即失效
  (assert (equal (multiple-value-list (sb-ext:weak-pointer-value wp))
                 '(nil nil))))

;; GC 内省
(assert (integerp sb-ext:*gc-run-time*))
(assert (integerp (sb-ext:get-bytes-consed)))
(format t "gc: run-time=~A consed=~A~%"
        sb-ext:*gc-run-time* (sb-ext:get-bytes-consed))

;;; ============================================================
;;; 5. 哈希表扩展
;;; ============================================================
(hdr "5 哈希表扩展")

;; 弱哈希表：死条目要「一次表访问 + 再一轮 GC」才观察得到（三明治式）；
;; 且对象要真死——保守式栈/寄存器扫描会把残留引用当活的钉住对象
(defun wh35 ()
  (let ((ht (make-hash-table :weakness :value)))
    (setf (gethash :k ht) (list :temp))   ; 值除了表没人引用
    ht))
(let ((ht (wh35)))
  (sb-ext:gc :full t)                     ; 第一轮：值死亡被发现
  (gethash :k ht)                         ; 夹一次表访问
  (sb-ext:gc :full t)                     ; 第二轮：条目被清掉
  (assert (= (hash-table-count ht) 0)))
(assert (eq (sb-ext:hash-table-weakness (make-hash-table :weakness :value))
            :value))

;; 自定义测试：按数值相等比较键（1 和 1.0 同键）
(defun ==35 (x y) (= x y))
(sb-ext:define-hash-table-test ==35
  ;; 哈希码必须与谓词一致：1 和 1.0 的 sxhash 不同，先统一 coerce
  (lambda (x) (sxhash (coerce x 'double-float))))
(let ((ht (make-hash-table :test '==35)))
  (setf (gethash 1 ht) :one)
  (assert (eq (gethash 1.0 ht) :one)))
(format t "hash: weakness=~S test=~S~%"
        :value (hash-table-test (make-hash-table :test '==35)))

;;; ============================================================
;;; 6. 超时与截止时间
;;; ============================================================
(hdr "6 超时与截止时间")

;; sb-sys:with-deadline：阻塞点 signal deadline-timeout，可继续
(assert (eq (handler-case
                (sb-sys:with-deadline (:seconds 0.1)
                  (sleep 5))
              (sb-sys:deadline-timeout () :deadline))
            :deadline))

;; defer-deadline restart：推迟死线继续跑
(assert (eq (handler-bind
                ((sb-sys:deadline-timeout
                   (lambda (c)
                     (declare (ignore c))
                     (invoke-restart 'sb-sys:defer-deadline 0.3))))
              (sb-sys:with-deadline (:seconds 0.1)
                (sleep 0.2)
                :slept))
            :slept))

;; sb-ext:wait-for：等待谓词为真，超时返 NIL
(assert (null (sb-ext:wait-for nil :timeout 0.1)))

;; sb-ext:with-timeout：到点异步打断，signal sb-ext:timeout
(assert (eq (handler-case
                (sb-ext:with-timeout 0.1
                  (sleep 5))
              (sb-ext:timeout () :timed-out))
            :timed-out))
(format t "timeout: deadline / defer / wait-for / with-timeout~%")

;;; ============================================================
;;; 7. 定时器（sb-ext:make-timer / schedule-timer）
;;; ============================================================
(hdr "7 定时器")

;; 基本用法：创建 → 调度 → 等待触发 → 取消
(defvar *timer-ran* nil)
(let ((timer (sb-ext:make-timer (lambda () (setf *timer-ran* t))
                                :name "demo-timer")))
  ;; timer-name 取名字
  (assert (string= (sb-ext:timer-name timer) "demo-timer"))
  ;; 调度前不在等待
  (assert (null (sb-ext:timer-scheduled-p timer)))
  ;; 调度：0.1 秒后触发
  (sb-ext:schedule-timer timer 0.1)
  (assert (sb-ext:timer-scheduled-p timer))
  ;; 等到触发
  (sleep 0.3)
  (assert *timer-ran*)
  ;; 取消后不再触发
  (setf *timer-ran* nil)
  (sb-ext:schedule-timer timer 0.1)
  (sb-ext:unschedule-timer timer)
  (sleep 0.3)
  (assert (null *timer-ran*))
  (assert (null (sb-ext:timer-scheduled-p timer))))

;; 周期定时器：repeat-interval
;; （回调在别的线程跑：lambda 必须写在 let 的 body 里才能闭包捕获词法
;;   变量——init-form 在绑定建立前求值，写在那里的 lambda 捕获不到）
(let ((tick35 0))
  (let ((timer (sb-ext:make-timer (lambda () (incf tick35)))))
    (sb-ext:schedule-timer timer 0.05 :repeat-interval 0.05)
    (sleep 0.4)                              ; 大约触发 7-8 次
    (sb-ext:unschedule-timer timer)
    (assert (plusp tick35))
    (format t "timer: 周期触发 ~A 次~%" tick35)))

;; list-all-timers 返回系统里全部定时器
(assert (listp (sb-ext:list-all-timers)))

(format t "timer: make / schedule / unschedule / repeat~%")

;;; ============================================================
;;; 8. run-program
;;; ============================================================
(hdr "8 run-program")

;; 不走 shell，参数原样传递；:output :stream 拿流读输出
(let* ((p (sb-ext:run-program "/bin/echo" '("hello-run-program")
                              :output :stream :wait nil))
       (line (read-line (sb-ext:process-output p))))
  (sb-ext:process-wait p)
  (assert (string= line "hello-run-program"))
  (assert (= (sb-ext:process-exit-code p) 0))
  (sb-ext:process-close p))

(assert (= (sb-ext:process-exit-code
            (sb-ext:run-program "/usr/bin/true" nil))
           0))
(format t "run-program: echo 与 true 均 exit 0~%")

;;; ============================================================
;;; 9. Unicode（sb-unicode）
;;; ============================================================
(hdr "9 Unicode")

;; 全串大小写映射：ß → SS（可变长！）
(assert (string= (sb-unicode:uppercase "straße") "STRASSE"))
(assert (string= (sb-unicode:casefold "STRASSE") "strasse"))
(assert (sb-unicode:unicode< "apple" "banana"))

;; 规范等价：预组合 é（U+00E9）与 e+组合音符（U+0301）
(assert (sb-unicode:unicode= (string (code-char #x00e9))
                             (concatenate 'string "e" (string (code-char #x0301)))))

;; UAX #29 断词：标点和空格各自成段
(assert (equal (sb-unicode:words "hello, world 你好")
               '("hello" "," " " "world" " " "你" "好")))
(assert (equal (sb-unicode:graphemes "a家族b")
               '("a" "家" "族" "b")))

;; 字符属性
(assert (eq (sb-unicode:general-category #\a) :LL))
(assert (eq (sb-unicode:script #\u4e2d) :HAN))
(assert (= (sb-unicode:decimal-value #\4) 4))
(format t "unicode: ~A ~A ~S~%"
        (sb-unicode:uppercase "straße")
        (sb-unicode:casefold "STRASSE")
        (sb-unicode:words "the quick fox"))

;;; ============================================================
;;; 10. 泛函分发与扩展槽访问
;;; ============================================================
(hdr "10 泛函分发与槽访问")

;; sb-pcl:no-primary-method：有 :around 但无 primary 时触发
;; （零方法的泛函仍走 ANSI no-applicable-method）
(defgeneric noprim35 (x))
(defmethod noprim35 :around ((x integer)) :around-ran)
(sb-ext:without-package-locks
  (defmethod sb-pcl:no-primary-method ((gf (eql #'noprim35)) &rest args)
    (declare (ignore args))
    :no-primary))
(assert (eq (noprim35 1) :no-primary))

;; 零方法对照：走 ANSI no-applicable-method —— 注意它是被调用的泛函，
;; 不是 signal 的条件，只能加方法接住，handler-case 捕不到
(defgeneric nomethod35 (x))
(defmethod no-applicable-method ((gf (eql #'nomethod35)) &rest args)
  (declare (ignore gf args))
  :ansi-nam)
(assert (eq (nomethod35 1) :ansi-nam))

;; slot-value 通吃 condition 与 defstruct（槽名按符号精确匹配，
;; 所以条件槽要么自己 define-condition，要么用 sb-kernel: 前缀访问内置槽）
(defstruct pt35 x y)
(assert (equal (let ((p (make-pt35 :x 1 :y 2)))
                 (list (slot-value p 'x) (slot-boundp p 'y)))
               '(1 t)))
(define-condition cond35 () ((msg :initarg :msg :reader cond35-msg)))
(assert (string= (slot-value (make-condition 'cond35 :msg "hi") 'msg)
                 "hi"))
(format t "dispatch: no-primary-method / slot-value 通吃~%")

;;; ============================================================
;;; 11. 杂项扩展
;;; ============================================================
(hdr "11 杂项")

;; 可复现随机序列：seed-random-state 返回种子化后的新状态，
;; 绑到 *random-state* 上用；同种子同序列
(let ((rs1 (sb-ext:seed-random-state 42))
      (rs2 (sb-ext:seed-random-state 42)))
  (assert (equal (let ((*random-state* rs1))
                   (loop repeat 3 collect (random 100)))
                 (let ((*random-state* rs2))
                   (loop repeat 3 collect (random 100))))))

;; 删目录：SBCL 的 CL 包没有 make-directory，建目录用 ensure-directories-exist
(let ((dir "probe35-dir/sub/"))
  (ensure-directories-exist dir)
  (assert (probe-file dir))
  (sb-ext:delete-directory "probe35-dir/" :recursive t)
  (assert (null (probe-file dir))))

;; array-storage-vector：拿到底层存储向量
(let ((v (make-array 3 :fill-pointer 0 :adjustable t)))
  (assert (eq (sb-ext:array-storage-vector v)
              (sb-ext:array-storage-vector v))))

(format t "misc: 种子可复现 / delete-directory / storage-vector~%")

(format t "~&==== 35 结束 ====~%")
