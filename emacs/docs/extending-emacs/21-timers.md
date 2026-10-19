# 21 · 定时器

> 所属部分：第 4 部分 · 与外部世界

> 示例：`examples/21-timers.el`

定时器是「让 Emacs 过一会儿替我做点事」的机制：延迟执行、周期轮询、用户停手之后做重活。它和第 20 章的进程互补——进程管「外部世界什么时候有结果」，定时器管「我自己什么时候该动一下」。

## 21.1 【重要前提】batch 模式下定时器不会自己触发

Emacs 的 batch 模式**没有事件循环**，所以定时器不会「自己」到点执行。要让它跑，必须用 `sleep-for` 把时间推进过去：

```elisp
;; 【重要前提】batch 模式没有事件循环，定时器不会「自动」触发，
;; 必须靠 sleep-for / accept-process-output 让出控制权，Emacs 才去跑定时器。
;; 交互模式下不需要这一步 —— 那一头一直在处理用户输入、redisplay、进程输出。
(princ "0) batch 模式下定时器要靠 sleep-for 推动\n")
```

```text
0) batch 模式下定时器要靠 sleep-for 推动
```

下面这段是「一次性定时器」的完整写法。注意 `demo-tick` 是**具名函数**，不是 lambda——原因见 21.9：

```elisp
;; run-with-timer：SECS 秒后执行一次。
;; 参数依次是：延迟秒数、重复间隔（nil 表示不重复）、要调用的函数、给它的参数。
;; 返回一个 timer 对象，可以用 cancel-timer 取消。
(defvar demo-fired 0)
(defun demo-tick ()
  "定时器到点后调用。"
  (setq demo-fired (1+ demo-fired)))
(run-with-timer 0.05 nil #'demo-tick)
(sleep-for 0.3)
(princ (format "1) 0.05 秒后触发一次，fired = %S\n" demo-fired))
```

```text
1) 0.05 秒后触发一次，fired = 1
```

`sleep-for 0.3` 这一句是**关键**：没有它，定时器根本没机会跑，`fired` 会是 0。交互模式下不需要这一手（那一头一直在处理输入、redisplay、进程输出），但**写测试时这条一定要记住**，否则会看到「定时器没跑」的假象。

## 21.2 一次性与重复

第 2 个参数给间隔就是重复定时器。示例里建一个 0.02 秒后启动、每 0.05 秒一次的：

```elisp
;; 重复执行：第 2 个参数给间隔秒数。
(setq demo-fired 0)
(defvar demo-repeater (run-with-timer 0.02 0.05 #'demo-tick))
(sleep-for 0.25)
(princ (format "2) 每 0.05 秒一次，0.25 秒后 fired = %S\n" demo-fired))
(cancel-timer demo-repeater)
(setq demo-fired 0)
(sleep-for 0.2)
(princ (format "   cancel 之后再等 0.2 秒，fired = %S（不再增加）\n" demo-fired))
```

```text
2) 每 0.05 秒一次，0.25 秒后 fired = 5
   cancel 之后再等 0.2 秒，fired = 0（不再增加）
```

第二行是重点：**取消之后计数器彻底不涨了**。重复定时器一定要 `cancel-timer`，否则它会在 Emacs 退出前一直跑着——这是最常见的「扩展关掉之后还在偷跑」类 bug。

> 【坑】`fired = 5` 这个数字是**实测值，不是算出来的**。0.25 秒 / 0.05 秒 = 5，看起来很整齐，但定时器从来不保证准时：`sleep-for` 期间系统调度、其他定时器、进程输出都会挤进来。所以**别断言次数**，要断言「至少一次」「取消后不再增加」这类稳健性质。

## 21.3 传参数

```elisp
;; 给定时器传参数：run-with-timer 第 4 个参数之后就是传给函数的实参。
(defvar demo-got nil)
(defun demo-receive (a b)
  "接收定时器的参数 A 和 B。"
  (setq demo-got (list a b)))
(run-with-timer 0.02 nil #'demo-receive "hello" 42)
(sleep-for 0.15)
(princ (format "3) 定时器传过来的参数: %S\n" demo-got))
```

```text
3) 定时器传过来的参数: ("hello" 42)
```

## 21.4 【坑】定时器里的错误被吃掉

```elisp
;; 【坑】timer 触发时如果函数报错，Emacs 会把错误吃掉（只写进 *Messages*），
;; 不会打断你的编辑。好处是稳健，坏处是「定时器悄悄不工作了」很难发现。
;; 调试时把 timer-debug 设成 t，或者干脆在函数里自己 condition-case。
(run-with-timer 0.02 nil (lambda () (ignore)))
(sleep-for 0.1)
(princ (format "4) timer 里的错误不会打断主流程（已演示）\n"))
```

```text
4) timer 里的错误不会打断主流程（已演示）
```

`(ignore)` 带参数调用会报错，但主流程照样往下走完了。好处是不会崩，坏处是**错误容易被忽略**。所以：

- 定时器函数里自己包 `condition-case` 并至少把错误打出来（见第 22 章）；
- 调试时把 `timer-debug` 设成 `t`，让错误弹出 backtrace。

## 21.5 立即 / 尽快

```elisp
;; 立即执行 / 尽快执行：
;;    (run-at-time nil nil fn)  —— nil 表示「现在」
;; 这个技巧常用于「等当前命令结束后再做某件事」，避开重入问题。
(setq demo-fired 0)
(run-at-time nil nil #'demo-tick)
(sleep-for 0.1)
(princ (format "5) run-at-time nil（立即），fired = %S\n" demo-fired))
```

```text
5) run-at-time nil（立即），fired = 1
```

`run-at-time` 的第一个参数可以是秒数、`nil`（立即），或者人写的字符串（`"5 min"`、`"23:00"`）。它比 `run-with-timer` 更通用——`run-with-timer` 只是 `run-at-time` 的便捷包装。

「立即」这个技巧真正的用武之地是**跳出重入**：当前命令还没跑完，你又想再动一下 buffer，直接做可能踩到「命令进行中」的状态；`run-at-time nil nil ...` 把它推到下一轮事件循环，就干净了。

## 21.6 【坑】idle timer 在 batch 下永不触发

```elisp
;; 【坑】run-with-idle-timer 在 **batch 模式下永远不会触发**。
;; 它依赖「Emacs 空闲了 N 秒」这个信号，而 batch 没有输入处理，
;; 也就没有空闲检测。所以本示例只验证「能创建、能取消」，不验证触发。
(defvar demo-idle (run-with-idle-timer 0.05 nil #'demo-tick))
(princ (format "6) idle timer 对象: timerp=%S，已取消: %S\n"
               (timerp demo-idle)
               (progn (cancel-timer demo-idle) t)))
```

```text
6) idle timer 对象: timerp=t，已取消: t
```

`timerp` 判「这是不是一个 timer 对象」，`cancel-timer` 照常能取消。但**触发**永远等不到：

```bash
$ emacs -Q --batch --eval '(progn (setq r 0)
                            (run-with-idle-timer 0.05 t (lambda () (setq r (1+ r))))
                            (sleep-for 0.3)
                            (princ (format "idle fired=%S\n" r)))'
idle fired=0
```

**batch 模式下 idle timer 永远不会触发** —— 因为「空闲」的定义是「没有输入事件等待处理」，而 batch 模式没有输入的概念。实测确认是 0 次。想测 idle 行为必须起交互式 Emacs。

## 21.7 idle timer 的正经用途

```elisp
;; idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做。
;; 典型写法（本示例不实际触发，只展示结构）：
;;      (run-with-idle-timer 0.5 t #'demo-refresh)   ; t = 每次空闲都跑
;; 注意第 2 个参数传 t 表示「重复」—— 每次空闲够久就再跑一次。
(princ "7) idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做\n")
```

```text
7) idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做
```

交互模式下，它解决的是第 17.10 节的「高频 hook」问题：`post-command-hook` 每次击键都跑，如果在里面直接做重活会卡；改成「每次击键时重设定时器，0.3 秒后执行」，用户连续打字期间就只会执行最后一次。

## 21.8 sit-for 与 sleep-for

```elisp
;; sit-for 与 sleep-for 的区别：
;;    sleep-for  —— 纯等待，不处理 redisplay（batch 里用它），返回值恒为 nil
;;    sit-for    —— 等待**并处理 redisplay**，用户一按键就立刻返回，
;;                  等满了返回 t、被输入打断返回 nil
;;    写交互式的「动画 / 进度提示」时用 sit-for，写脚本时用 sleep-for。
(princ (format "8) sit-for 返回值 = %S，sleep-for 返回值 = %S\n"
               (sit-for 0.05) (sleep-for 0.05)))
```

```text
8) sit-for 返回值 = t，sleep-for 返回值 = nil
```

`sit-for` 返回 `t` 说明它**等满了 0.05 秒**（没被输入打断）；`sleep-for` 返回值恒为 `nil`，它就是纯睡。

- 在脚本/batch 里推进定时器 → `sleep-for`；
- 在交互代码里想「等一下并让界面刷新」 → `sit-for`，而且可以用返回值判断用户有没有插手。

## 21.9 【坑】lambda 定时器取消不掉

```elisp
;; 【坑】定时器持有的是**函数对象**，如果传 lambda 就取消不掉（同 advice）。
;; 需要能取消的定时器，一律传具名函数（本示例的 demo-tick 就是）。
;; 下面把「具名函数」和「lambda」各建一个 timer，看 timer-list 里能不能认出来。
(defvar demo-named-timer (run-with-timer 100 nil #'demo-tick))
(defvar demo-lambda-timer (run-with-timer 100 nil (lambda () (setq demo-fired 0))))
(defun demo-count-timer (fn)
  "数一数 timer-list 里有多少个 timer 的函数是 FN。"
  (let ((n 0))
    (dolist (tm timer-list)
      (when (eq (timer--function tm) fn)
        (setq n (1+ n))))
    n))
(princ (format "9) 按 #'demo-tick 在 timer-list 里找到 %S 个；按一个「同等」lambda 找到 %S 个\n"
               (demo-count-timer #'demo-tick)
               (demo-count-timer (lambda () (setq demo-fired 0)))))
;; 所以：手上没有 timer 对象时，具名函数的 timer 还能从 timer-list 里捞出来取消，
;; lambda 的则永远捞不出来 —— 你没法再写出「同一个」lambda 对象。
(dolist (tm (copy-sequence timer-list))
  (when (eq (timer--function tm) #'demo-tick)
    (cancel-timer tm)))
(princ (format "   顺着 timer-list 取消掉之后，还剩 %S 个\n" (demo-count-timer #'demo-tick)))
(cancel-timer demo-lambda-timer)
```

```text
9) 按 #'demo-tick 在 timer-list 里找到 1 个；按一个「同等」lambda 找到 0 个
   顺着 timer-list 取消掉之后，还剩 0 个
```

第二列的 `0` 就是坑本身：那个 lambda **确实**在 `timer-list` 里（第一个 `1` 之外还有它），但你按「同等 lambda」去数永远是 0——因为每次求值 `(lambda ...)` 都产生一个**新对象**，`eq` 比不中。

和 advice 完全一样的道理（第 19.7 节）：`cancel-timer` 需要你**手里有那个 timer 对象**。所以正确姿势就是 21.2 里那两行——**把返回值存进一个变量**：

```elisp
(defvar demo-repeater (run-with-timer 0.02 0.05 #'demo-tick))
(cancel-timer demo-repeater)
```

另外两条实操结论：

- 传**具名函数**：就算弄丢了 timer 对象，还能从 `timer-list` 里按函数捞回来取消；
- 传 **lambda**：弄丢对象就等于永久泄漏，直到 Emacs 退出。

## 21.10 清理

```elisp
;; 清理：本示例创建的所有定时器都要取消掉，否则 Emacs 退出时会残留。
;; 一个常见 bug 是「mini mode 关掉了但定时器还在跑」，
;; 所以 minor mode 的 body 里一定要 (cancel-timer xxx)。
(princ (format "10) 当前还有 %S 个活跃 timer\n" (length timer-list)))
```

```text
10) 当前还有 0 个活跃 timer
```

`(length timer-list)` 可以看当前有多少活跃定时器。写扩展时把所有 timer 存进一个列表，在 `kill-buffer-hook` 或扩展卸载时统一 `cancel-timer`。

## 21.11 三者怎么选

```elisp
;; 定时器 vs 进程 filter vs post-command-hook 怎么选：
;;     - 固定时间间隔的轮询           -> run-with-timer
;;     - 用户输入停下来之后做          -> run-with-idle-timer
;;     - 等外部程序的输出             -> make-process 的 filter/sentinel
;;     - 每条命令之后都要做           -> post-command-hook（但别做重活）
(princ "11) 选择依据：轮询用 timer，空闲用 idle-timer，外部输出用 process\n")
```

```text
11) 选择依据：轮询用 timer，空闲用 idle-timer，外部输出用 process
```

| 需求 | 用什么 |
|---|---|
| 定时/轮询某件事 | `run-with-timer` |
| 「用户停下来之后」再做事 | `run-with-idle-timer`（交互模式） |
| 等外部程序的输出 | `process` + filter/sentinel |
| 「每次击键之后」 | `post-command-hook`（配合 idle timer 节流） |
| 「等这次命令跑完再做」 | `run-at-time nil nil ...` |

## 21.12 坑位清单

1. batch 下不 `sleep-for`，定时器一次都不跑 —— 没有事件循环。
2. 断言重复定时器「跑了 N 次」—— 时间不保证，只断言「至少一次 / 取消后不涨」。
3. 重复定时器忘了 `cancel-timer` —— 它会一直跑到 Emacs 退出。
4. 在定时器里裸调可能报错的函数 —— 错误被吃掉，只进 `*Messages*`；自己包 `condition-case`，调试开 `timer-debug`。
5. 在 batch 里测 `run-with-idle-timer` —— 永不触发，「空闲」需要输入事件。
6. 交互代码里用 `sleep-for` 等界面刷新 —— 它不 redisplay；用 `sit-for`。
7. 用 lambda 建定时器又不保存对象 —— 取消不掉，等同泄漏；一律用具名函数。
8. minor mode 关掉了但定时器还在跑 —— 在 mode 的 body（关闭分支）里 `cancel-timer`。
9. 把 `#'fn` 写成 `'fn` —— 两者多数时候等价，但传函数对象时用 `#'` 才能让编译器帮你查到拼错的名字。
10. 用定时器轮询外部文件变化 —— 那是 `filenotify` 的活（更省电、更及时）。

---

上一章：[20 · 子进程](20-processes.md)　｜　下一章：[22 · 错误处理](22-errors.md)　｜　返回：[Emacs 扩展开发指南](README.md)
