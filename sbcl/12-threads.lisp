;;;; ============================================================
;;;; 12-threads.lisp — 多线程编程（sb-thread）
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   0. 线程安全的打印（自己写一个 SAY）
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
;;;;   等价、且不依赖 shebang 的写法（验证脚本用的就是这个）：
;;;;   sbcl --noinform --non-interactive --no-userinit --load 12-threads.lisp
;;;;
;;;; ------------------------------------------------------------
;;;; 为什么本文件到处用 SAY 而不是 (format t ...)
;;;; ------------------------------------------------------------
;;;; 一次 FORMAT 会按格式指令拆成**多次**写操作，中间可以被别的线程插进来：
;;;;
;;;;   线程A: "  任务 2 在线程 "    线程B: "  任务 2 在线程 "
;;;;   线程B: "pool-worker-0 执行"  线程A: "pool-worker-1 执行"
;;;;   → "  任务 2 在线程   任务 2 在线程 pool-worker-0 执行pool-worker-1 执行"
;;;;
;;;; 更麻烦的是：SBCL 往 fd-stream 写多字节字符时会分块，
;;;; 汉字被两个线程各写走一半，stdout 里就出现**非法 UTF-8 序列**。
;;;; 后果不是「难看」而已 —— 某些 locale 下的文本工具（例如 macOS 上
;;;; UTF-8 locale 的 tr）碰到非法序列会直接报
;;;;   tr: Illegal byte sequence
;;;; 并**截断输入**，后面的内容整段丢失，判定脚本于是误报「缺结束标记」。
;;;;
;;;; 所以：所有输出都走 SAY，用一把全局打印锁把「一次 FORMAT」变成
;;;; 原子操作，再 FINISH-OUTPUT 保证整行真的落到 fd 上。
;;;;
;;;; 并发程序输出的**顺序**本身不确定（谁先抢到锁谁先打印），这是正常
;;;; 现象；但「内容集合」和「汇总数字」是确定的。因此关键结论都放在
;;;; JOIN 之后由主线程统一打印。
;;;;
;;;; ------------------------------------------------------------
;;;; 已知不确定性：每次运行都可能不同的行（并发固有，不是 bug）
;;;; ------------------------------------------------------------
;;;;   * 各线程打印的先后顺序
;;;;       §1「线程 N 执行 / 完成」  §3「生产 / 消费」
;;;;       §5「等待屏障 / 通过屏障」  §8「池任务 N 在线程 X 执行」
;;;;   * §2「最终计数（无锁）」—— 竞态丢失多少个更新本来就不确定
;;;;   * §4「同时活跃过的最大值」—— 正常应为 3，可被保证不会超过 3
;;;;   * §8 里哪个 worker 抢到哪个任务
;;;;
;;;; 除以上之外都是确定的，每次运行逐字节相同：
;;;;   原子计数 10000 / CAS 计数 5000 / 提交 10 个执行 10 个 /
;;;;   「未超过上限 3」= T / §4 排序后的完成编号 (0 1 2 3 4 5 6 7)
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 0. 线程安全的打印
;;; ----------------------------------------------------------

(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))

(defun say (fmt &rest args)
  "线程安全地往 *standard-output* 打印。
   加锁保证一次 FORMAT 不会被别的线程插进来；FINISH-OUTPUT 保证整行
   真的写出去（否则多个线程共用一个缓冲区，flush 时仍会把内容撕开）。"
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))


;;; ----------------------------------------------------------
;;; 1. 创建与管理线程
;;; ----------------------------------------------------------

(say "~%=== 创建线程 ===~%")

;; sb-thread:make-thread 创建线程
(let ((thread (sb-thread:make-thread
               (lambda ()
                 (say "线程 ~A 开始~%"
                      (sb-thread:thread-name sb-thread:*current-thread*))
                 (sleep 1)
                 (say "线程结束~%"))
               :name "worker-1")))
  ;; 直接 (format t "~A" thread) 会打印 #<THREAD tid=4099 ... waiting on:
  ;; #<MUTEX "print-lock" ...>> 这种东西 —— tid 每次运行都不同，线程此刻
  ;; 阻塞在哪个锁上也随时在变，输出因此不可重复。要展示对象就取稳定的部分。
  (say "线程对象类型: ~A~%" (type-of thread))
  (say "线程名: ~A~%" (sb-thread:thread-name thread))
  (say "线程存活: ~A~%" (sb-thread:thread-alive-p thread))
  ;; 等待线程结束
  (sb-thread:join-thread thread)
  (say "线程已结束~%")
  ;; JOIN 之后再问「还活着吗」
  (say "结束后存活: ~A~%" (sb-thread:thread-alive-p thread)))

;; 多个线程。
;;
;; 坑：线程一旦跑完就 join 掉了，想用 LIST-ALL-THREADS 把它们列出来，
;; 必须保证「列表时它们都还没结束」。靠 SLEEP 撞运气是不可靠的
;; （线程可能比预期快），所以这里用一个计数为 0 的信号量当**起跑闸**：
;; 每个 worker 先 WAIT-ON-SEMAPHORE 卡住，主线程数完线程再逐个放行。
(say "~%--- 多线程并行 ---~%")
(let ((threads '())
      (go (sb-thread:make-semaphore :count 0)))
  (dotimes (i 5)
    (push (sb-thread:make-thread
           (let ((id i))
             (lambda ()
               (sb-thread:wait-on-semaphore go)   ; 等主线程放行
               (say "线程 ~A 执行~%" id)
               (sleep (random 0.5))
               (say "线程 ~A 完成~%" id)))
           :name (format nil "worker-~A" i))
          threads))

  ;; 此刻 5 个 worker 都卡在起跑闸后面，一定还活着。
  ;; 名字排序后打印 —— 否则 LIST-ALL-THREADS 的顺序不稳定。
  (say "~%当前所有线程（按名字排序）:~%")
  (dolist (name (sort (mapcar #'sb-thread:thread-name
                              (sb-thread:list-all-threads))
                      #'string<))
    (say "  ~A~%" name))

  ;; 放行，然后等它们全部结束
  (dotimes (i 5) (sb-thread:signal-semaphore go))
  (dolist (thread threads)
    (sb-thread:join-thread thread))
  (say "所有线程完成~%")
  (say "剩余线程: ~A~%"
       (sort (mapcar #'sb-thread:thread-name (sb-thread:list-all-threads))
             #'string<)))


;;; ----------------------------------------------------------
;;; 2. 互斥锁（Mutex）
;;; ----------------------------------------------------------

(say "~%=== 互斥锁 ===~%")

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
    (say "最终计数（有锁）: ~A~%" shared-counter)))

;; 不使用锁的对比。
;;
;; 这个数字**每次运行都可能不同**（1000 到 1000 以下之间）—— 因为
;; 「读-改-写」三步之间可以被别的线程插入，丢失更新。这正是要演示的
;; 竞态，不要去修它；所以下面只断言「它没到 1000」。
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
    (say "最终计数（无锁）: ~A~%（因为是竞态，每次运行的值都可能不同，通常 < 1000）~%"
         shared-counter)
    (say "无锁计数丢失了更新: ~A~%" (< shared-counter 1000))))

;; 判断「当前线程是否已经持有这把锁」
;;
;; 坑：不要用 (sb-thread:grab-mutex lock :waitp nil) 来「试探性加锁」。
;; SBCL 的 GRAB-MUTEX 是非重入的：同一个线程**再次**加锁（哪怕 :waitp nil）
;; 不是返回 NIL，而是直接报错并终止文件：
;;   Recursive lock attempt #<SB-THREAD:MUTEX owner: ... main thread ...>
;; 想检查持有情况用 HOLDING-MUTEX-P / MUTEX-OWNER。
(let ((lock (sb-thread:make-mutex)))
  (say "初始是否持有: ~A~%" (sb-thread:holding-mutex-p lock))
  (sb-thread:grab-mutex lock)
  (say "加锁后是否持有: ~A~%" (sb-thread:holding-mutex-p lock))
  (say "持有者是否本线程: ~A~%"
       (eq (sb-thread:mutex-owner lock) sb-thread:*current-thread*))
  (sb-thread:release-mutex lock)
  (say "释放后是否持有: ~A~%" (sb-thread:holding-mutex-p lock)))


;;; ----------------------------------------------------------
;;; 3. 条件变量（Condition Variable）
;;; ----------------------------------------------------------

(say "~%=== 条件变量 ===~%")

;; 生产者-消费者模式
;;
;; 注意 CONDITION-WAIT 的用法：它**必须**在持有锁的情况下调用，
;; 返回时锁仍是持有的。等待前要再检查一次条件（while，不是 if）。
(let ((queue '())
      (lock (sb-thread:make-mutex :name "queue-lock"))
      (not-empty (sb-thread:make-waitqueue :name "not-empty"))
      (produced 0)
      (consumed 0)
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
                           (incf consumed)
                           (say "  消费: ~A~%" item))))
                     (say "消费者结束~%"))
                   :name "consumer")))

    ;; 生产者线程
    (let ((producer (sb-thread:make-thread
                     (lambda ()
                       (dotimes (i 10)
                         (sb-thread:with-mutex (lock)
                           (push i queue)
                           (incf produced)
                           (say "  生产: ~A~%" i)
                           (sb-thread:condition-notify not-empty))
                         (sleep 0.1))
                       (sb-thread:with-mutex (lock)
                         (setf finished t)
                         (sb-thread:condition-broadcast not-empty))
                       (say "生产者结束~%"))
                     :name "producer")))

      (sb-thread:join-thread producer)
      (sb-thread:join-thread consumer)
      (say "生产者-消费者示例完成~%")
      ;; 出队顺序取决于调度（队列是 LIFO 的），但这三个数字是确定的
      (say "  生产 ~A 个，消费 ~A 个，全部消费完: ~A~%"
           produced consumed (and (= produced consumed) (null queue))))))


;;; ----------------------------------------------------------
;;; 4. 信号量（Semaphore）
;;; ----------------------------------------------------------

(say "~%=== 信号量 ===~%")

;; 信号量控制并发数量：初始计数 3，最多只允许 3 个任务同时在跑。
;; 每个任务结束都会 SIGNAL-SEMAPHORE，把名额还回去。
(let ((semaphore (sb-thread:make-semaphore :count 3 :name "pool"))
      (active 0)
      (peak 0)
      (done 0)
      (finished '())
      (lock (sb-thread:make-mutex)))

  (defun limited-task (id)
    (sb-thread:wait-on-semaphore semaphore)
    (sb-thread:with-mutex (lock)
      (incf active)
      (setf peak (max peak active)))
    (sleep 0.5)
    (sb-thread:with-mutex (lock)
      (decf active)
      (incf done)
      (push id finished))
    (sb-thread:signal-semaphore semaphore))

  (let ((threads '()))
    (dotimes (i 8)
      (push (sb-thread:make-thread
             (let ((id i))
               (lambda () (limited-task id))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (say "信号量示例完成~%")
    (say "  完成任务数: ~A~%" done)
    ;; 完成顺序不确定，排序后打印；集合本身是确定的
    (say "  完成的编号（已排序）: ~A~%" (sort finished #'<))
    ;; 谁先拿到名额不确定，但「同时最多 3 个」是信号量保证的 —— 断言它
    (say "  同时活跃过的最大值: ~A~%" peak)
    (say "  未超过上限 3: ~A~%" (<= peak 3))))


;;; ----------------------------------------------------------
;;; 5. 屏障（Barrier）
;;; ----------------------------------------------------------

(say "~%=== 屏障 ===~%")

;; 屏障让多个线程在某个点同步：所有人都到了，才一起放行。
;; 这里用「计数到 3 就发 3 次信号量」实现。
(let ((results (make-array 3 :initial-element nil))
      (lock (sb-thread:make-mutex))
      (release (sb-thread:make-semaphore :count 0))
      (arrived 0)
      (threads '()))

  (dotimes (i 3)
    (let ((id i))
      (push (sb-thread:make-thread
             (lambda ()
               (say "  线程 ~A 第一阶段~%" id)
               (sleep (random 0.3))
               (sb-thread:with-mutex (lock)
                 (setf (aref results id) (format nil "线程~A完成" id)))
               (say "  线程 ~A 等待屏障~%" id)
               (sb-thread:with-mutex (lock)
                 (incf arrived)
                 (when (= arrived 3)
                   (dotimes (j 3)
                     (sb-thread:signal-semaphore release))))
               (sb-thread:wait-on-semaphore release)
               (say "  线程 ~A 通过屏障，继续执行~%" id)))
            threads)))

  ;; 坑：原版这里只写了 (sleep 2) 就往下走 —— 主线程既没 JOIN 也没等，
  ;; 屏障里的线程可能还在打印，主线程就已经开始跑下一节、甚至打到结束
  ;; 标记后面去了。真正等它们结束要用 JOIN。
  (dolist (thread threads)
    (sb-thread:join-thread thread))
  (say "屏障示例完成~%")
  ;; 到达屏障的顺序不确定，谁先通过也不确定；
  ;; 但「三个人都填好了自己的结果」是确定的，按编号统一打印。
  (dotimes (i 3)
    (say "  结果 ~A: ~A~%" i (aref results i))))


;;; ----------------------------------------------------------
;;; 6. 线程本地存储
;;; ----------------------------------------------------------

(say "~%=== 线程本地存储 ===~%")

;; 使用 special 变量实现线程本地存储：
;; LET 动态绑定在 SBCL 里是**每线程独立**的 —— 一个线程重新绑定
;; *thread-local-value*，看不见别的线程的绑定。
(defvar *thread-local-value* nil)

(let ((threads '())
      (seen (make-array 3 :initial-element nil)))
  (dotimes (i 3)
    (push (sb-thread:make-thread
           (let ((id i))
             (lambda ()
               (let ((*thread-local-value* (format nil "线程~A的值" id)))
                 (sleep 0.1)
                 ;; SLEEP 之后读到的仍是自己那份绑定
                 (setf (aref seen id) *thread-local-value*))))
           :name (format nil "tls-~A" i))
          threads))
  (dolist (thread threads)
    (sb-thread:join-thread thread))
  (dotimes (i 3)
    (say "  线程 ~A 的绑定: ~A~%" i (aref seen i))))

;; 使用哈希表 + 线程对象作为键，模拟真正的 thread-local 存储
;; （SBCL 没有内置的 thread-local 存储 API）
(let ((tls (make-hash-table :test 'eq))
      (lock (sb-thread:make-mutex))
      (threads '())
      (seen (make-array 3 :initial-element nil)))

  (defun tls-get (key)
    (sb-thread:with-mutex (lock)
      (gethash (list sb-thread:*current-thread* key) tls)))

  (defun tls-set (key value)
    (sb-thread:with-mutex (lock)
      (setf (gethash (list sb-thread:*current-thread* key) tls) value)))

  (dotimes (i 3)
    (push (sb-thread:make-thread
           (let ((id i))
             (lambda ()
               (tls-set 'id id)
               (sleep 0.1)
               ;; 每个线程读到的都是自己存进去的那个 id
               (setf (aref seen id) (tls-get 'id))))
           :name (format nil "tls2-~A" i))
          threads))
  (dolist (thread threads)
    (sb-thread:join-thread thread))
  (dotimes (i 3)
    (say "  TLS 线程 ~A: id=~A~%" i (aref seen i)))
  (say "  主线程查自己的槽位: ~A~%（主线程没存过）~%" (tls-get 'id)))


;;; ----------------------------------------------------------
;;; 7. 原子操作
;;; ----------------------------------------------------------

(say "~%=== 原子操作 ===~%")

;; atomic-incf / atomic-decf — 原子递增/递减
(defstruct atomic-counter (value 0 :type (unsigned-byte 64)))

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
    (say "原子计数: ~A（应为 10000）~%" (atomic-counter-value counter))))

;; CAS（比较并交换）：比较失败就重试，所以不需要锁
(let ((cell (cons 0 nil)))
  (let ((threads '()))
    (dotimes (i 5)
      (push (sb-thread:make-thread
             (lambda ()
               (loop
                 (let ((old (car cell)))
                   (when (sb-ext:cas (car cell) old (1+ old))
                     (return))))))
            threads))
    (dolist (thread threads)
      (sb-thread:join-thread thread))
    (say "CAS 计数: ~A（应为 5000）~%" (car cell))))


;;; ----------------------------------------------------------
;;; 8. 实用并发模式
;;; ----------------------------------------------------------

(say "~%=== 实用并发模式 ===~%")

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
                     (setf task (pop (thread-pool-task-queue pool))))
                   ;; 取不到任务 = 队列已空且已 SHUTDOWN → 这时才退出
                   (if task
                       (funcall task)
                       (return)))))
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
  ;; JOIN 保证返回时队列真的被排空了
  (dolist (worker (thread-pool-workers pool))
    (sb-thread:join-thread worker)))

;; 使用线程池
;;
;; 坑：worker 的退出条件是「队列空**且**已 SHUTDOWN」，不能只判断 SHUTDOWN
;; 就 RETURN —— 那样 SHUTDOWN 一到，队列里还没跑的任务会被直接丢掉。
;; 正确顺序是：先把任务取出来（取不到才是真的空了），有任务就干活，
;; 没任务才退出。这样 SHUTDOWN 之后不需要靠 SLEEP 等它们，直接 JOIN。
(let ((pool (make-pool 3))
      (executed 0)
      (count-lock (sb-thread:make-mutex)))
  (dotimes (i 10)
    (let ((id i))
      (pool-submit pool
                   (lambda ()
                     (sb-thread:with-mutex (count-lock)
                       (incf executed))
                     ;; 哪个 worker 抢到哪个任务是不确定的（所以这几行的
                     ;; 顺序、以及 worker 编号每次运行都可能不同）
                     (say "  池任务 ~A 在线程 ~A 执行~%"
                          id (sb-thread:thread-name sb-thread:*current-thread*))
                     (sleep 0.1)))))
  (pool-shutdown pool)
  (say "线程池示例完成~%")
  (say "  提交 10 个任务，实际执行 ~A 个~%" executed))

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
    ;; 按分片下标拼回去，结果与顺序调用 MAPCAR 完全一致
    (apply #'append (coerce results 'list))))

(say "并行 map: ~A~%"
        (pmap (lambda (x) (* x x)) (loop for i from 1 to 20 collect i)))
(say "串行 map: ~A~%"
        (mapcar (lambda (x) (* x x)) (loop for i from 1 to 20 collect i)))

;; --- 模式 3: future / promise ---
(defstruct promise
  (value nil)
  (done nil)
  (lock (sb-thread:make-mutex))
  (ready (sb-thread:make-waitqueue)))

(defun spawn-promise (fn)
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

;; 使用 promise：取值时才阻塞等待，先取 p1 不会拖慢 p2 的计算
(let ((p1 (spawn-promise (lambda () (sleep 0.5) (* 6 7))))
      (p2 (spawn-promise (lambda () (sleep 0.3) (+ 1 2 3)))))
  (say "promise 1: ~A~%" (promise-get p1))
  (say "promise 2: ~A~%" (promise-get p2)))

(say "~%==== 12 结束 ====~%")
