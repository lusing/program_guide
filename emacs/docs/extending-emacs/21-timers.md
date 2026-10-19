# 21 · 定时器

> 所属部分：第 4 部分 · 与外部世界

> 示例：`examples/21-timers.el`

## 21.1 【重要前提】batch 模式下定时器不会自己触发

```
0) batch 模式下定时器要靠 sleep-for 推动
```

Emacs 的 batch 模式**没有事件循环**，所以定时器不会「自己」到点执行。要让它跑，必须用
`sleep-for` 把时间推进过去：

```elisp
(let ((fired 0))
  (run-with-timer 0.05 nil (lambda () (setq fired (1+ fired))))
  (sleep-for 0.3)                ; ← 这段时间里定时器才有机会执行
  (princ (format "fired = %d\n" fired)))
```

```
1) 0.05 秒后触发一次，fired = 1
```

交互模式下不需要这个 —— 有真正的事件循环。但**写测试时这条一定要记住**，
否则会看到「定时器没跑」的假象。

## 21.2 一次性与重复

```elisp
(run-with-timer 0.05 nil #'fn)      ; 0.05 秒后一次
(run-with-timer 0.05 0.1 #'fn)      ; 0.05 秒后开始，每 0.1 秒一次
```

```
2) 每 0.05 秒一次，0.25 秒后 fired = 5
   cancel 之后再等 0.2 秒，fired = 0（不再增加）
```

第 2 个参数给间隔就是重复定时器。**重复定时器一定要 `cancel-timer`**，
否则它会在 Emacs 退出前一直跑着。

## 21.3 传参数

```elisp
(run-with-timer 0.05 nil #'demo-handle "hello" 42)
```

```
3) 定时器传过来的参数: ("hello" 42)
```

第 4 个参数之后都是传给函数的实参。

## 21.4 【坑】定时器里的错误被吃掉

```
4) timer 里的错误不会打断主流程（已演示）
```

定时器函数里报错，Emacs **不会**中断主流程，只是把错误写进 `*Messages*`。
好处是不会崩，坏处是**错误容易被忽略**。所以在定时器函数里要自己包 `condition-case` 并
至少打印出来（见第 22 章）。

## 21.5 立即 / 尽快

```elisp
(run-at-time nil nil #'fn)          ; 立即（下一轮事件循环）
(run-at-time "23:00" nil #'fn)      ; 指定绝对时间
(run-at-time "5 min" 60 #'fn)       ; 5 分钟后开始，之后每 60 秒 —— 字符串能被解析
```

```
5) run-at-time nil（立即），fired = 1
```

`run-at-time` 的第一个参数可以是秒数、`nil`（立即），或者人写的字符串（`"5 min"`、`"23:00"`）。
它比 `run-with-timer` 更通用。`run-with-timer` 只是 `run-at-time` 的便捷包装。

## 21.6 【坑】idle timer 在 batch 下永不触发

```elisp
(run-with-idle-timer 0.05 t #'fn)
```

```bash
$ emacs -Q --batch --eval '(progn (setq r 0)
                            (run-with-idle-timer 0.05 t (lambda () (setq r (1+ r))))
                            (sleep-for 0.3)
                            (princ (format "idle fired=%S\n" r)))'
idle fired=0
```

**batch 模式下 idle timer 永远不会触发** —— 因为「空闲」的定义是「没有输入事件等待处理」，
而 batch 模式没有输入的概念。实测确认是 0 次。

## 21.7 idle timer 的正经用途

```
7) idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做
```

交互模式下，它解决的是第 17.10 节的「高频 hook」问题：`post-command-hook` 每次击键都跑，
如果在里面直接做重活会卡；改成「每次击键时重设定时器，0.3 秒后执行」，
用户连续打字期间就只会执行最后一次。

## 21.8 sit-for 与 sleep-for

```elisp
(sleep-for 0.5)     ; 睡 0.5 秒，期间处理进程输出，**不重绘**
(sit-for 0.5)       ; 睡 0.5 秒，处理输入/进程输出，**会重绘**，有输入则提前返回
```

```
8) sleep-for 不处理 redisplay；sit-for 会
```

- 在脚本/batch 里推进定时器 → `sleep-for`；
- 在交互代码里想「等一下并让界面刷新」 → `sit-for`。

## 21.9 【坑】lambda 定时器取消不掉

```
9) 【坑】定时器持有的是函数对象，如果传 lambda 就取消不掉（同 advice）
```

和 advice 完全一样的道理（第 19.7 节）：`cancel-timer` 需要你**手里有那个 timer 对象**。
所以正确姿势是：

```elisp
(setq demo-timer (run-with-timer 1 1 #'demo-tick))   ; 存下来
(cancel-timer demo-timer)                            ; 才能取消
```

传 lambda 的话你就没有可靠的「同一个函数对象」可用来做判断了。

## 21.10 清理

```
10) 当前还有 0 个活跃 timer
```

`(length timer-list)` 可以看当前有多少活跃定时器。写扩展时把所有 timer 存进一个列表，
在 `kill-buffer-hook` 或扩展卸载时统一 `cancel-timer`。

## 21.11 三者怎么选

```
11) 选择依据：轮询用 timer，空闲用 idle-timer，外部输出用 process
```

| 需求 | 用什么 |
|---|---|
| 定时/轮询某件事 | `run-with-timer` |
| 「用户停下来之后」再做事 | `run-with-idle-timer`（交互模式） |
| 等外部程序的输出 | `process` + filter/sentinel |
| 「每次击键之后」 | `post-command-hook`（配合 idle timer 节流） |

---

上一章：[20 · 子进程](20-processes.md)　｜　下一章：[22 · 错误处理](22-errors.md)　｜　返回：[Emacs 扩展开发指南](README.md)
