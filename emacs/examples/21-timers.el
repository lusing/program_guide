;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 21 - 定时器：延迟执行、周期任务、空闲任务
;;;   run-with-timer / run-with-idle-timer / cancel-timer
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "21-timers.el")'
;;; 运行：emacs -Q --batch -l 21-timers.el
;;; ============================================================

;;; 0) 【重要前提】batch 模式没有事件循环，定时器不会「自动」触发，
;;;    必须靠 sleep-for / accept-process-output 让出控制权，Emacs 才去跑定时器。
;;;    交互模式下不需要这一步 —— 那一头一直在处理用户输入、redisplay、进程输出。
(princ "0) batch 模式下定时器要靠 sleep-for 推动\n")

;;; 1) run-with-timer：SECS 秒后执行一次。
;;;    参数依次是：延迟秒数、重复间隔（nil 表示不重复）、要调用的函数、给它的参数。
;;;    返回一个 timer 对象，可以用 cancel-timer 取消。
(defvar demo-fired 0)
(defun demo-tick ()
  "定时器到点后调用。"
  (setq demo-fired (1+ demo-fired)))
(run-with-timer 0.05 nil #'demo-tick)
(sleep-for 0.3)
(princ (format "1) 0.05 秒后触发一次，fired = %S\n" demo-fired))

;;; 2) 重复执行：第 2 个参数给间隔秒数。
(setq demo-fired 0)
(defvar demo-repeater (run-with-timer 0.02 0.05 #'demo-tick))
(sleep-for 0.25)
(princ (format "2) 每 0.05 秒一次，0.25 秒后 fired = %S\n" demo-fired))
(cancel-timer demo-repeater)
(setq demo-fired 0)
(sleep-for 0.2)
(princ (format "   cancel 之后再等 0.2 秒，fired = %S（不再增加）\n" demo-fired))

;;; 3) 给定时器传参数：run-with-timer 第 4 个参数之后就是传给函数的实参。
(defvar demo-got nil)
(defun demo-receive (a b)
  "接收定时器的参数 A 和 B。"
  (setq demo-got (list a b)))
(run-with-timer 0.02 nil #'demo-receive "hello" 42)
(sleep-for 0.15)
(princ (format "3) 定时器传过来的参数: %S\n" demo-got))

;;; 4) 【坑】timer 触发时如果函数报错，Emacs 会把错误吃掉（只写进 *Messages*），
;;;    不会打断你的编辑。好处是稳健，坏处是「定时器悄悄不工作了」很难发现。
;;;    调试时把 timer-debug 设成 t，或者干脆在函数里自己 condition-case。
(run-with-timer 0.02 nil (lambda () (ignore)))
(sleep-for 0.1)
(princ (format "4) timer 里的错误不会打断主流程（已演示）\n"))

;;; 5) 立即执行 / 尽快执行：
;;;    (run-at-time nil nil fn)  —— nil 表示「现在」
;;;    这个技巧常用于「等当前命令结束后再做某件事」，避开重入问题。
(setq demo-fired 0)
(run-at-time nil nil #'demo-tick)
(sleep-for 0.1)
(princ (format "5) run-at-time nil（立即），fired = %S\n" demo-fired))

;;; 6) 【坑】run-with-idle-timer 在 **batch 模式下永远不会触发**。
;;;    它依赖「Emacs 空闲了 N 秒」这个信号，而 batch 没有输入处理，
;;;    也就没有空闲检测。所以本示例只验证「能创建、能取消」，不验证触发。
(defvar demo-idle (run-with-idle-timer 0.05 nil #'demo-tick))
(princ (format "6) idle timer 对象: timerp=%S，已取消: %S\n"
               (timerp demo-idle)
               (progn (cancel-timer demo-idle) t)))

;;; 7) idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做。
;;;    典型写法（本示例不实际触发，只展示结构）：
;;;      (run-with-idle-timer 0.5 t #'demo-refresh)   ; t = 每次空闲都跑
;;;    注意第 2 个参数传 t 表示「重复」—— 每次空闲够久就再跑一次。

;;; 8) sit-for 与 sleep-for 的区别：
;;;    sleep-for  —— 纯等待，不处理 redisplay（batch 里用它）
;;;    sit-for    —— 等待**并处理 redisplay**，用户一按键就立刻返回
;;;    写交互式的「动画 / 进度提示」时用 sit-for，写脚本时用 sleep-for。
(princ "8) sleep-for 不处理 redisplay；sit-for 会\n")

;;; 9) 【坑】定时器持有的是**函数对象**，如果传 lambda 就取消不掉（同 advice）。
;;;    需要能取消的定时器，一律传具名函数（本示例的 demo-tick 就是）。

;;; 10) 清理：本示例创建的所有定时器都要取消掉，否则 Emacs 退出时会残留。
;;;     一个常见 bug 是「mini mode 关掉了但定时器还在跑」，
;;;     所以 minor mode 的 body 里一定要 (cancel-timer xxx)。
(princ (format "10) 当前还有 %S 个活跃 timer\n" (length timer-list)))

;;; 11) 定时器 vs 进程 filter vs post-command-hook 怎么选：
;;;     - 固定时间间隔的轮询           -> run-with-timer
;;;     - 用户输入停下来之后做          -> run-with-idle-timer
;;;     - 等外部程序的输出             -> make-process 的 filter/sentinel
;;;     - 每条命令之后都要做           -> post-command-hook（但别做重活）
(princ "11) 选择依据：轮询用 timer，空闲用 idle-timer，外部输出用 process\n")

(princ "==== 21 结束 ====\n")
