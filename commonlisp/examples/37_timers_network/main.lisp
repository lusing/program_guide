;;;; 37 · 定时器与网络编程（docs/37-timers-network.md 配套例程）
;; channel: sbcl
;;;; 运行：sbcl --noinform --non-interactive --no-userinit --load main.lisp
;;;; 判定：exit 0、stderr 为空、输出末尾出现「==== 37 结束 ====」

(defun hdr (s) (format t "~&---- ~A ----~%" s))

;;; ==================================================
;;; 37.1 定时器基础：make-timer / schedule-timer / wait-for
;;; ==================================================
(hdr "37.1 定时器基础")

(defvar *fired37* nil)
(defparameter *tm37* (sb-ext:make-timer (lambda () (setf *fired37* :fired))
                                        :name :demo :thread t))
(assert (eq (sb-ext:timer-name *tm37*) :demo))
(assert (null (sb-ext:timer-scheduled-p *tm37*)))     ; 还没排程
(sb-ext:schedule-timer *tm37* 0.05)
(assert (sb-ext:timer-scheduled-p *tm37*))
(assert (member *tm37* (sb-ext:list-all-timers)))
(assert (eq (sb-ext:wait-for *fired37* :timeout 5) :fired))
(assert (null (sb-ext:timer-scheduled-p *tm37*)))     ; 一次性定时器触发完即出队

;;; ==================================================
;;; 37.2 重复定时器、绝对时间与撤销
;;; ==================================================
(hdr "37.2 重复定时器 / absolute-p / unschedule-timer")

(defvar *tick37* 0)
(defparameter *tm37r* (sb-ext:make-timer (lambda () (incf *tick37*))
                                         :thread t))
(sb-ext:schedule-timer *tm37r* 0.05 :repeat-interval 0.05)
(assert (sb-ext:timer-scheduled-p *tm37r* :delta 100)) ; 重复定时器恒为真
(assert (sb-ext:wait-for (>= *tick37* 3) :timeout 5))
(sb-ext:unschedule-timer *tm37r*)
(assert (null (sb-ext:timer-scheduled-p *tm37r*)))
(let ((n *tick37*))
  (sleep 0.2)
  (assert (= n *tick37*)))                            ; 撤销之后计数器一动不动

;; :absolute-p t —— time 是 universal time 时刻
(defvar *abs37* nil)
(sb-ext:schedule-timer (sb-ext:make-timer (lambda () (setf *abs37* :abs))
                                          :thread t)
                       (+ (get-universal-time) 1)
                       :absolute-p t)
(assert (eq (sb-ext:wait-for *abs37* :timeout 5) :abs))

;;; ==================================================
;;; 37.3 定时器在哪个线程里运行 + 动态环境警示
;;; ==================================================
(hdr "37.3 :thread 语义与动态环境")

;; 缺省：在 make-timer 时所在的线程（这里正是主线程）里跑
(defvar *thr37a* nil)
(let ((tm (sb-ext:make-timer
           (lambda () (setf *thr37a* sb-thread:*current-thread*)))))
  (sb-ext:schedule-timer tm 0.05)
  (sb-ext:wait-for *thr37a* :timeout 5)
  (assert (eq *thr37a* sb-thread:*current-thread*)))

;; :thread t：每次触发换一个新线程
(defvar *thr37b* nil)
(let ((tm (sb-ext:make-timer
           (lambda () (setf *thr37b* sb-thread:*current-thread*))
           :thread t)))
  (sb-ext:schedule-timer tm 0.05)
  (sb-ext:wait-for *thr37b* :timeout 5)
  (assert (not (eq *thr37b* sb-thread:*current-thread*))))

;; 手册警示示例：函数看到宿主线程触发那一刻的动态绑定
(defvar *foo37* nil)
(defvar *seen37* nil)
(defun show-foo37 () (push *foo37* *seen37*))
(setf *seen37* nil)
(sb-ext:schedule-timer (sb-ext:make-timer #'show-foo37) 0.05)
(sb-ext:schedule-timer (sb-ext:make-timer #'show-foo37) 0.15)
(let ((*foo37* t))
  (sleep 0.1))
(let ((*foo37* :surprise))
  (sleep 0.2))
(assert (equal (nreverse *seen37*) '(t :surprise)))

;;; ==================================================
;;; 37.4 sb-bsd-sockets 总览：加载 / 地址 / 错误体系 / 协议号
;;; ==================================================
(hdr "37.4 sb-bsd-sockets 总览")

(require :sb-bsd-sockets)
(assert (equalp (sb-bsd-sockets:make-inet-address "127.0.0.1") #(127 0 0 1)))

;; 连接没人监听的端口：signal socket-error 子类（实际是 connection-refused-error）
(assert (eq (handler-case
                (let ((s (make-instance 'sb-bsd-sockets:inet-socket
                                        :type :stream :protocol :tcp)))
                  (sb-bsd-sockets:socket-connect s #(127 0 0 1) 1)
                  :no-error)
              (sb-bsd-sockets:socket-error () :sock-err))
            :sock-err))

;; 协议号查询（多值：协议号 / 官方名 / 别名，只断言主值）
(assert (= (sb-bsd-sockets:get-protocol-by-name "tcp") 6))

;;; ==================================================
;;; 37.5 TCP 全链路：bind → listen → connect → accept → 流读写
;;; ==================================================
(hdr "37.5 TCP 全链路")

(defparameter *srv37* (make-instance 'sb-bsd-sockets:inet-socket
                                     :type :stream :protocol :tcp))
(setf (sb-bsd-sockets:sockopt-reuse-address *srv37*) t)
(assert (sb-bsd-sockets:sockopt-reuse-address *srv37*))
(sb-bsd-sockets:socket-bind *srv37* #(127 0 0 1) 0)   ; 端口 0：内核挑空闲端口
(sb-bsd-sockets:socket-listen *srv37* 5)
(assert (sb-bsd-sockets:socket-open-p *srv37*))

(let ((client (make-instance 'sb-bsd-sockets:inet-socket
                             :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-connect
   client #(127 0 0 1)
   (nth-value 1 (sb-bsd-sockets:socket-name *srv37*)))
  (multiple-value-bind (peer paddr) (sb-bsd-sockets:socket-accept *srv37*)
    (let ((cs (sb-bsd-sockets:socket-make-stream
               client :input t :output t :buffering :none :auto-close t))
          (ps (sb-bsd-sockets:socket-make-stream
               peer :input t :output t :buffering :none :auto-close t)))
      (write-line "ping37" cs)
      (let ((heard-by-server (read-line ps)))
        (write-line "pong37" ps)
        (let ((heard-by-client (read-line cs)))
          (close cs) (close ps)
          (assert (equalp (list heard-by-server heard-by-client paddr)
                          '("ping37" "pong37" #(127 0 0 1)))))))))

(sb-bsd-sockets:socket-close *srv37*)
(assert (null (sb-bsd-sockets:socket-open-p *srv37*)))

;;; ==================================================
;;; 37.6 UDP：socket-send / socket-receive（缓冲区是整个的，要 subseq）
;;; ==================================================
(hdr "37.6 UDP 收发")

(let ((a (make-instance 'sb-bsd-sockets:inet-socket
                        :type :datagram :protocol :udp))
      (b (make-instance 'sb-bsd-sockets:inet-socket
                        :type :datagram :protocol :udp)))
  (sb-bsd-sockets:socket-bind a #(127 0 0 1) 0)
  (sb-bsd-sockets:socket-bind b #(127 0 0 1) 0)
  (let ((pa (nth-value 1 (sb-bsd-sockets:socket-name a))))
    (sb-bsd-sockets:socket-send b "ping37" 6
                                :address (list #(127 0 0 1) pa))
    (multiple-value-bind (buf len from) (sb-bsd-sockets:socket-receive a nil 16)
      ;; buf 是整个 16 字符缓冲区，尾部是没读到的 NUL；实际数据要 subseq
      (assert (= (length buf) 16))
      (sb-bsd-sockets:socket-close a)
      (sb-bsd-sockets:socket-close b)
      (assert (equalp (list (subseq buf 0 len) len from)
                      '("ping37" 6 #(127 0 0 1)))))))

;;; ==================================================
;;; 37.7 半关闭：socket-shutdown，对端读到干净 EOF
;;; ==================================================
(hdr "37.7 半关闭")

(let ((srv (make-instance 'sb-bsd-sockets:inet-socket
                          :type :stream :protocol :tcp))
      (cli (make-instance 'sb-bsd-sockets:inet-socket
                          :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-bind srv #(127 0 0 1) 0)
  (sb-bsd-sockets:socket-listen srv 1)
  (sb-bsd-sockets:socket-connect cli #(127 0 0 1)
                                 (nth-value 1 (sb-bsd-sockets:socket-name srv)))
  (let* ((peer (sb-bsd-sockets:socket-accept srv))
         (ps (sb-bsd-sockets:socket-make-stream
              peer :input t :buffering :none :auto-close t)))
    (sb-bsd-sockets:socket-shutdown cli :direction :output)
    (multiple-value-bind (line missing-newline-p) (read-line ps nil :eof)
      (assert (and (eq line :eof) missing-newline-p)))
    (close ps)
    (sb-bsd-sockets:socket-close cli)
    (sb-bsd-sockets:socket-close srv)))

;;; ==================================================
;;; 37.8 local socket：同机进程间通信
;;; ==================================================
(hdr "37.8 local socket")

(let ((path "ex37-local.sock"))
  (when (probe-file path) (delete-file path))
  (let ((srv (make-instance 'sb-bsd-sockets:local-socket :type :stream)))
    (sb-bsd-sockets:socket-bind srv path)
    (sb-bsd-sockets:socket-listen srv 1)
    (let ((cli (make-instance 'sb-bsd-sockets:local-socket :type :stream)))
      (sb-bsd-sockets:socket-connect cli path)
      (let* ((peer (sb-bsd-sockets:socket-accept srv))
             (cs (sb-bsd-sockets:socket-make-stream
                  cli :input t :output t :buffering :none :auto-close t))
             (ps (sb-bsd-sockets:socket-make-stream
                  peer :input t :output t :buffering :none :auto-close t)))
        (write-line "local37" cs)
        (assert (string= (read-line ps) "local37"))
        (close cs) (close ps)
        (sb-bsd-sockets:socket-close srv)
        (delete-file path)))))

;;; ==================================================
;;; 37.9 名字服务：get-host-by-name / get-host-by-address
;;; ==================================================
(hdr "37.9 名字服务")

(let ((h (sb-bsd-sockets:get-host-by-name "localhost")))
  (assert (equalp (sb-bsd-sockets:host-ent-address h) #(127 0 0 1)))
  (assert (string= (sb-bsd-sockets:host-ent-name h) "localhost")))

;; 反查必须传真 (unsigned-byte 8) 向量；字面量 #(127 0 0 1) 元素类型是 T，会 case-failure
(assert (equalp (sb-bsd-sockets:host-ent-address
                 (sb-bsd-sockets:get-host-by-address
                  (sb-bsd-sockets:make-inet-address "127.0.0.1")))
                #(127 0 0 1)))

(format t "~&==== 37 结束 ====~%")
