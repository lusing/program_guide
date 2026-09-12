;;;; ============================================================
;;;; 12-threads.lisp — 多线程编程（sb-thread）
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 创建与管理线程
;;;;   2. 互斥锁（mutex）
;;;;   3. 条件变量（condition variable）
;;;;   4. 信号量（semaphore）
;;;;   5. 屏障（barrier）
;;;;   6. 线程本地存储
;;;;   7. 原子操作
;;;;   8. 实用并发模式
;;;;
;;;; 注意：SBCL 的线程支持需要编译时启用（默认启用）
;;;; 运行方式：sbcl --script 12-threads.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. 创建与管理线程
;;; ----------------------------------------------------------

(format t "~%=== 创建线程 ===~%")

;; sb-thread:make-thread 创建线程
(let ((thread (sb-thread:make-thread
               (lambda ()
                 (format t "线程 ~A 开始~%"
                         (sb-thread:thread-name sb-thread:*current-thread*))
                 (sleep 1)
                 (format t "线程结束~%"))
               :name "worker-1")))
  (format t "创建了线程: ~A~%" thread)
  (format t "线程名: ~A~%" (sb-thread:thread-name thread))
  (format t "线程存活: ~A~%" (sb-thread:thread-alive-p thread))
  ;; 等待线程结束
  (sb-thread:join-thread thread)
  (format t "线程已结束~%"))

;; 多个线程
(format t "~%--- 多线程并行 ---~%")
(let ((threads '()))
  (dotimes (i 5)
    (push (sb-thread:make-thread
           (let ((id i))
             (lambda ()
               (format t "线程 ~A 执行~%" id)
               (sleep (random 0.5))
               (format t "线程 ~A 完成~%" id)))
           :name (format nil "worker-~A" i))
          threads))
  ;; 等待所有线程完成
  (dolist (thread threads)
    (sb-thread:join-thread thread))
  (format t "所有线程完成~%"))

;; 列出所有线程
(format t "~%所有线程:~%")
(dolist (thread (sb-thread:list-all-threads))
  (format t "  ~A (存活: ~A)~%"
          (sb-thread:thread-name thread)
          (sb-thread:thread-alive-p thread)))


;;; ----------------------------------------------------------
;;; 2. 互斥锁（Mutex）
;;; ----------------------------------------------------------

(format t "~%=== 互斥锁 ===~%")

;; 创建互斥锁
(let ((lock (sb-thread:make-mutex :name "my-lock"))
      (shared-counter 0))

  ;; 使用 with-mutex 自动加锁/解锁
  (defun increment-counter ()
    (sb-thread:with-mutex (lock)
      (let ((old shared-counter))
        (sleep 0.001)  ; 模拟耗时操作
        (setf shared-counter (1+ old))
        shared-counter)))

  ;; 启动多个线程并发递增
  (let ((threads '()))
    (dotimes (i 10)
      (push (sb-thread:make-thread
             (lambda ()
               (dotimes (j 100)
                 (increment-counter))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (format t "最终计数（有锁）: ~A~%" shared-counter)))

;; 不使用锁的对比
(let ((shared-counter 0))
  (let ((threads '()))
    (dotimes (i 10)
      (push (sb-thread:make-thread
             (lambda ()
               (dotimes (j 100)
                 (let ((old shared-counter))
                   (sleep 0.001)
                   (setf shared-counter (1+ old))))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (format t "最终计数（无锁）: ~A~%（可能不等于1000）" shared-counter)))

;; 尝试获取锁（不阻塞）
(let ((lock (sb-thread:make-mutex)))
  (format t "获取锁: ~A~%" (sb-thread:grab-mutex lock))
  (format t "再次获取（非阻塞）: ~A~%"
          (sb-thread:grab-mutex lock :waitp nil))
  (sb-thread:release-mutex lock))


;;; ----------------------------------------------------------
;;; 3. 条件变量（Condition Variable）
;;; ----------------------------------------------------------

(format t "~%=== 条件变量 ===~%")

;; 生产者-消费者模式
(let ((queue '())
      (lock (sb-thread:make-mutex :name "queue-lock"))
      (not-empty (sb-thread:make-waitqueue :name "not-empty"))
      (finished nil))

  ;; 消费者线程
  (let ((consumer (sb-thread:make-thread
                   (lambda ()
                     (loop
                       (sb-thread:with-mutex (lock)
                         (loop while (and (null queue) (not finished))
                               do (sb-thread:condition-wait not-empty lock))
                         (when (and (null queue) finished)
                           (return))
                         (let ((item (pop queue)))
                           (format t "  消费: ~A~%" item))))
                     (format t "消费者结束~%"))
                   :name "consumer")))

    ;; 生产者线程
    (let ((producer (sb-thread:make-thread
                     (lambda ()
                       (dotimes (i 10)
                         (sb-thread:with-mutex (lock)
                           (push i queue)
                           (format t "  生产: ~A~%" i)
                           (sb-thread:condition-notify not-empty))
                         (sleep 0.1))
                       (sb-thread:with-mutex (lock)
                         (setf finished t)
                         (sb-thread:condition-broadcast not-empty))
                       (format t "生产者结束~%"))
                     :name "producer")))

      (sb-thread:join-thread producer)
      (sb-thread:join-thread consumer)
      (format t "生产者-消费者示例完成~%"))))


;;; ----------------------------------------------------------
;;; 4. 信号量（Semaphore）
;;; ----------------------------------------------------------

(format t "~%=== 信号量 ===~%")

;; 信号量控制并发数量
(let ((semaphore (sb-thread:make-semaphore :count 3 :name "pool"))
      (active 0)
      (lock (sb-thread:make-mutex)))

  (defun limited-task (id)
    (sb-thread:wait-on-semaphore semaphore)
    (sb-thread:with-mutex (lock)
      (incf active)
      (format t "  任务 ~A 开始（活跃: ~A）~%" id active))
    (sleep 0.5)
    (sb-thread:with-mutex (lock)
      (decf active)
      (format t "  任务 ~A 结束（活跃: ~A）~%" id active))
    (sb-thread:signal-semaphore semaphore))

  (let ((threads '()))
    (dotimes (i 8)
      (push (sb-thread:make-thread
             (let ((id i))
               (lambda () (limited-task id))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (format t "信号量示例完成~%")))


;;; ----------------------------------------------------------
;;; 5. 屏障（Barrier）
;;; ----------------------------------------------------------

(format t "~%=== 屏障 ===~%")

;; 屏障让多个线程在某个点同步
(let ((barrier (sb-thread:make-barrier 3))
      (results (make-array 3 :initial-element nil))
      (lock (sb-thread:make-mutex)))

  (dotimes (i 3)
    (let ((id i))
      (sb-thread:make-thread
       (lambda ()
         (format t "  线程 ~A 第一阶段~%" id)
         (sleep (random 0.3))
         (sb-thread:with-mutex (lock)
           (setf (aref results id) (format nil "线程~A完成" id)))
         (format t "  线程 ~A 等待屏障~%" id)
         (sb-thread:barrier barrier)
         (format t "  线程 ~A 通过屏障，继续执行~%" id)))))

  (sleep 2)
  (format t "屏障示例完成~%"))


;;; ----------------------------------------------------------
;;; 6. 线程本地存储
;;; ----------------------------------------------------------

(format t "~%=== 线程本地存储 ===~%")

;; 使用 special 变量实现线程本地存储
(defvar *thread-local-value* nil)

(let ((threads '()))
  (dotimes (i 3)
    (push (sb-thread:make-thread
           (let ((id i))
             (lambda ()
               (let ((*thread-local-value* (format nil "线程~A的值" id)))
                 (format t "  线程 ~A: ~A~%" id *thread-local-value*)
                 (sleep 0.1)
                 (format t "  线程 ~A 再次读取: ~A~%" id *thread-local-value*)))))
          threads))
  (dolist (thread threads)
    (sb-thread:join-thread thread)))

;; 使用 sb-thread 的 thread-local 存储
;; SBCL 没有内置的 thread-local 存储 API，
;; 但可以用哈希表 + 线程对象作为键来实现
(let ((tls (make-hash-table :test 'eq))
      (lock (sb-thread:make-mutex)))

  (defun tls-get (key)
    (sb-thread:with-mutex (lock)
      (gethash (list sb-thread:*current-thread* key) tls)))

  (defun tls-set (key value)
    (sb-thread:with-mutex (lock)
      (setf (gethash (list sb-thread:*current-thread* key) tls) value)))

  (let ((threads '()))
    (dotimes (i 3)
      (push (sb-thread:make-thread
             (let ((id i))
               (lambda ()
                 (tls-set 'id id)
                 (sleep 0.1)
                 (format t "  TLS 线程 ~A: id=~A~%" id (tls-get 'id)))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))))


;;; ----------------------------------------------------------
;;; 7. 原子操作
;;; ----------------------------------------------------------

(format t "~%=== 原子操作 ===~%")

;; atomic-incf / atomic-decf — 原子递增/递减
(defstruct atomic-counter (value 0 :type fixnum))

(let ((counter (make-atomic-counter)))
  (let ((threads '()))
    (dotimes (i 10)
      (push (sb-thread:make-thread
             (lambda ()
               (dotimes (j 1000)
                 (sb-ext:atomic-incf (atomic-counter-value counter)))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (format t "原子计数: ~A~%" (atomic-counter-value counter))))

;; CAS（比较并交换）
(let ((cell (cons 0 nil)))
  (let ((threads '()))
    (dotimes (i 5)
      (push (sb-thread:make-thread
             (let ((id i))
               (lambda ()
                 (loop
                   (let ((old (car cell)))
                     (when (sb-ext:cas (car cell) old (1+ old))
                       (return)))))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (format t "CAS 计数: ~A~%" (car cell))))


;;; ----------------------------------------------------------
;;; 8. 实用并发模式
;;; ----------------------------------------------------------

(format t "~%=== 实用并发模式 ===~%")

;; --- 模式 1: 线程池 ---
(defstruct thread-pool
  (workers '())
  (task-queue '())
  (lock (sb-thread:make-mutex))
  (not-empty (sb-thread:make-waitqueue))
  (shutdown nil))

(defun make-pool (num-workers)
  (let ((pool (make-thread-pool)))
    (dotimes (i num-workers)
      (push (sb-thread:make-thread
             (lambda ()
               (loop
                 (let ((task nil))
                   (sb-thread:with-mutex ((thread-pool-lock pool))
                     (loop while (and (null (thread-pool-task-queue pool))
                                      (not (thread-pool-shutdown pool)))
                           do (sb-thread:condition-wait
                               (thread-pool-not-empty pool)
                               (thread-pool-lock pool)))
                     (when (thread-pool-shutdown pool)
                       (return))
                     (setf task (pop (thread-pool-task-queue pool))))
                   (when task
                     (funcall task)))))
             :name (format nil "pool-worker-~A" i))
            (thread-pool-workers pool)))
    pool))

(defun pool-submit (pool task)
  (sb-thread:with-mutex ((thread-pool-lock pool))
    (push task (thread-pool-task-queue pool))
    (sb-thread:condition-notify (thread-pool-not-empty pool))))

(defun pool-shutdown (pool)
  (sb-thread:with-mutex ((thread-pool-lock pool))
    (setf (thread-pool-shutdown pool) t)
    (sb-thread:condition-broadcast (thread-pool-not-empty pool)))
  (dolist (worker (thread-pool-workers pool))
    (sb-thread:join-thread worker)))

;; 使用线程池
(let ((pool (make-pool 3)))
  (dotimes (i 10)
    (let ((id i))
      (pool-submit pool
                   (lambda ()
                     (format t "  池任务 ~A 在线程 ~A 执行~%"
                             id (sb-thread:thread-name sb-thread:*current-thread*))
                     (sleep 0.1)))))
  (sleep 1)
  (pool-shutdown pool)
  (format t "线程池示例完成~%"))

;; --- 模式 2: 并行 map ---
(defun pmap (fn list &optional (num-threads 4))
  "并行版本的 mapcar。"
  (let* ((chunks (loop with chunk-size = (ceiling (length list) num-threads)
                       for i from 0 below (length list) by chunk-size
                       collect (subseq list i (min (+ i chunk-size) (length list)))))
         (results (make-array (length chunks) :initial-element nil))
         (lock (sb-thread:make-mutex))
         (threads '()))
    (loop for chunk in chunks
          for idx from 0
          do (push (sb-thread:make-thread
                    (let ((c chunk) (i idx))
                      (lambda ()
                        (let ((result (mapcar fn c)))
                          (sb-thread:with-mutex (lock)
                            (setf (aref results i) result))))))
                   threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (apply #'append (coerce results 'list))))

(format t "并行 map: ~A~%"
        (pmap (lambda (x) (* x x)) (loop for i from 1 to 20 collect i)))

;; --- 模式 3: future / promise ---
(defstruct promise
  (value nil)
  (done nil)
  (lock (sb-thread:make-mutex))
  (ready (sb-thread:make-waitqueue)))

(defun make-promise (fn)
  (let ((p (make-promise)))
    (sb-thread:make-thread
     (lambda ()
       (let ((result (funcall fn)))
         (sb-thread:with-mutex ((promise-lock p))
           (setf (promise-value p) result
                 (promise-done p) t)
           (sb-thread:condition-broadcast (promise-ready p))))))
    p))

(defun promise-get (p)
  (sb-thread:with-mutex ((promise-lock p))
    (loop while (not (promise-done p))
          do (sb-thread:condition-wait (promise-ready p) (promise-lock p)))
    (promise-value p)))

;; 使用 promise
(let ((p1 (make-promise (lambda () (sleep 0.5) (* 6 7))))
      (p2 (make-promise (lambda () (sleep 0.3) (+ 1 2 3)))))
  (format t "promise 1: ~A~%" (promise-get p1))
  (format t "promise 2: ~A~%" (promise-get p2)))

(format t "~%=== 例程 12 执行完毕 ===~%")
