# 20 · 子进程

> 所属部分：第 4 部分 · 与外部世界
>
> **本部分导读**：扩展能力的天花板，很大程度上取决于它能不能调用外部工具、能不能处理时间、能不能优雅地失败。 这三章分别对应 `process`、`timer` 和错误处理。

> 示例：`examples/20-processes.el`

一个 Emacs 扩展能做的事，永远受限于 Emacs 自己实现了什么。调外部程序是突破这层天花板最直接的手段：让 `rg` 去搜、让 `clang-format` 去排版、让语言服务器去做语义分析。但进程这块有几个坑是**每次**都会踩的，本章逐个实测给你看。

## 20.1 跨平台前提

```elisp
;; 【跨平台提示】不要写死 cmd.exe / /bin/sh。
;; shell-file-name 和 shell-command-switch 会给出当前平台正确的组合，
;; 本示例统一用它们，所以 Windows 和 Unix 上都能跑。
(princ (format "0) shell = %S, switch = %S\n"
               shell-file-name shell-command-switch))
```

```text
0) shell = "/bin/zsh", switch = "-c"
```

`shell-file-name` 的值来自环境变量 `SHELL`，所以**这一行在你的机器上很可能不同**（可能是 `/bin/bash`、`/bin/sh`，Windows 上是 `cmd.exe` 之类）。这正是要点：**不要写死** `/bin/sh` 或 `cmd.exe`，用 `shell-file-name` 和 `shell-command-switch`，Emacs 会填好当前平台的值。这是让扩展跨平台的第一个前提。

## 20.2 同步调用

最简单的一种：`call-process`。它会**一直等到进程结束**才返回，返回值是退出码。

```elisp
;; 同步调用（会等到进程结束）：call-process。
;; 第 3 个参数是「输出去哪」：t = 当前 buffer，nil = 丢弃，
;; 也可以是 (REAL-DESTINATION STDERR-DESTINATION) 让两者分开。
;; 返回值是进程的退出码。
(with-temp-buffer
  (let ((rc (call-process shell-file-name nil t nil
                          shell-command-switch "echo sync-hello")))
    (princ (format "1) call-process 退出码 = %S，输出 = %S\n"
                   rc (string-trim (buffer-string))))))
```

```text
1) call-process 退出码 = 0，输出 = "sync-hello"
```

`destination`（第 3 个参数）的取值：

| destination | 含义 |
|---|---|
| `nil` | 丢弃输出 |
| `t` | 插到当前 buffer 的 point 处 |
| 字符串 | 这是 buffer 名（不存在则新建） |
| `(file . name)` / `(:file name)` | 写进文件 |
| 函数 | 用函数接收输出 |

只要输出字符串、不关心退出码时，用 `shell-command-to-string`：

```elisp
;; 【坑】它**不返回退出码**，命令失败时你拿到的是空串 + stderr 混在里面。
;; 要判断成败就用 call-process。
(princ (format "2) shell-command-to-string: %S\n"
               (string-trim (shell-command-to-string "echo from-shell"))))
```

```text
2) shell-command-to-string: "from-shell"
```

> 【坑】`shell-command-to-string` **拿不到退出码**，而且 stderr 会混进返回值里。要判断成败，一律回到 `call-process`。

要直接落盘就用 `:file`：

```elisp
(defvar demo-proc-dir (make-temp-file "emacs-proc-" t))
(defvar demo-proc-out (expand-file-name "out.txt" demo-proc-dir))
(call-process shell-file-name nil (list :file demo-proc-out) nil
              shell-command-switch "echo written-to-file")
(princ (format "3) 文件里的结果: %S\n"
               (string-trim
                (with-temp-buffer (insert-file-contents demo-proc-out) (buffer-string)))))
```

```text
3) 文件里的结果: "written-to-file"
```

**同步调用会卡住 Emacs**（整个界面停住，连 `C-g` 都很难打断）。它只适合几毫秒能返回的命令。跑 `make`、`git`、语言服务器一律走异步。

## 20.3 【坑】命令和参数必须分开传

`call-process` 的签名是 `(program &optional infile destination display &rest args)`——注意最后的 `&rest args`：参数是**逐个**传的，不是拼成一个命令行字符串。

示例里喂给 `printf` 三个「在 shell 里有特殊含义」的参数——带空格、带分号、带 `$`：

```elisp
;; 【坑】命令和参数必须**分开传**，不要拼成一个字符串再交给 shell ——
;; 分开传时不经过 shell，参数里的空格、引号、$、; 都只是普通字符，
;; 既不用转义，也没有注入风险；拼成整串则慢（多起一个 shell）、
;; 要自己转义、还会踩各家 shell 的引号差异。
;; 这里用 printf 打印三个「在 shell 里有特殊含义」的参数来验证。
(with-temp-buffer
  (call-process "printf" nil t nil "[%s]\n" "one two" "a;b" "$HOME")
  (princ (format "4) 分开传参，printf 原样收到: %S\n"
                 (string-trim (buffer-string)))))
;; 文件名带空格时差别最直观：分开传不用加引号，拼进 shell 就得自己加。
(let ((fname (expand-file-name "带 空格.txt" demo-proc-dir)))
  (call-process "touch" nil nil nil fname)
  (princ (format "   文件名带空格，分开传直接能用: %S\n" (file-exists-p fname))))
```

```text
4) 分开传参，printf 原样收到: "[one two]
[a;b]
[$HOME]"
   文件名带空格，分开传直接能用: t
```

三个参数一个没变形：`one two` 没被拆成两个参数，`a;b` 没被当成命令分隔，`$HOME` 没被展开。因为它们根本没经过 shell。

对应的错误写法是 `(call-process shell-file-name nil t nil shell-command-switch "printf '[%s]\n' 'one two'")`——整串交给 shell 之后，引号、转义、`;`、`$` 全都活过来了，你得自己按目标 shell 的规则转义一遍，稍有不慎就是命令注入。

所以：

- 参数**逐个传**，不要拼接；
- 只有确实需要 shell 特性（管道、重定向、通配符、变量展开）时，才显式地用 `shell-file-name` + `shell-command-switch`；
- 一旦走 shell，来自用户/文件名/网络的数据就必须转义（或用 `shell-quote-argument`）。

## 20.4 先查可执行文件

```elisp
;; 找可执行文件：executable-find。写扩展时启动外部程序之前一定要先查一次，
;; 找不到就给用户一个明确的错误，而不是让它抛个莫名其妙的异常。
(princ (format "5) executable-find \"echo\" = %S\n" (executable-find "echo")))
(princ (format "   找一个不存在的: %S\n" (executable-find "definitely-not-here-xyz")))
```

```text
5) executable-find "echo" = "/bin/echo"
   找一个不存在的: nil
```

它返回**绝对路径**（在 `exec-path` 里找到的第一个），找不到返回 `nil`。**调用外部程序之前一定先查一次**，查不到就给出清晰的错误提示，而不是让用户看到 `Searching for program: No such file or directory, xxx`。

## 20.5 异步进程：make-process

```elisp
;; 异步进程：make-process。它立刻返回，不阻塞 Emacs。
;; :sentinel 在进程状态变化（结束、被杀）时被调用；
;; :filter  在有输出时被调用（拿到的是**原始字节串**，可能一次给一段）。
;; 注意 batch 模式下没有事件循环，要手动 accept-process-output 推动。
(let* ((chunks nil)
       (done nil)
       (proc (make-process
              :name "demo-async"
              :command (list shell-file-name shell-command-switch "echo async-hello")
              :buffer nil                     ; nil = 不用 buffer 收集输出
              :connection-type 'pipe
              :filter (lambda (_proc text)
                        (push text chunks))
              :sentinel (lambda (_proc _event)
                          (setq done t)))))
  ;; 等到进程结束（或超时）
  (let ((waited 0))
    (while (and (not done) (< waited 50))
      (accept-process-output proc 0.05)
      (setq waited (1+ waited))))
  (princ (format "6) 异步收到: %S，进程还活着吗: %S\n"
                 (string-trim (apply #'concat (nreverse chunks)))
                 (process-live-p proc))))
```

```text
6) 异步收到: "async-hello"，进程还活着吗: nil
```

三个要点：

- `make-process` **立刻返回**，Emacs 不阻塞；
- `:filter` 是「有输出了」的回调，拿到的是**原始字节串**，而且**一次给一段**——行可能被切成两半，所以想按行处理必须自己在 filter 里攒缓冲；
- `:buffer nil` 表示不让 Emacs 自动把输出插进 buffer（有 filter 时通常就该这么设）。

> 【坑】batch 模式（`emacs -Q --batch -l xxx.el`）下**没有事件循环**，filter/sentinel 不会自动被推动。所以示例里要手动 `accept-process-output` 轮询。交互模式下 Emacs 自己会跑事件循环，不需要这一手——但这也意味着**同样的代码在 batch 和交互下节奏不同**，写测试时别忘了这一点。

## 20.6 【坑】sentinel 的 event 末尾带换行

```elisp
;; 【坑】sentinel 收到的 event 字符串末尾**带换行**，
;; 而且它可能在进程「停止 / 继续 / 结束」时被多次调用。
;; 判断真正结束要用 (process-live-p proc) 或匹配 "finished"，
;; 不要简单地「sentinel 被调用 == 结束了」。
(let* ((events nil)
       (proc (make-process
              :name "demo-evt"
              :command (list shell-file-name shell-command-switch "echo x")
              :buffer nil
              :filter #'ignore
              :sentinel (lambda (_proc event) (push event events)))))
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "7) sentinel 收到的 event: %S\n" (nreverse events)))
  (princ (format "   退出码 = %S\n" (process-exit-status proc))))
```

```text
7) sentinel 收到的 event: ("finished
")
   退出码 = 0
```

`%S` 把换行打成了字面换行，所以看起来断成了两行——**它其实是一个字符串 `"finished\n"`**。这带来三个必须记住的结论：

1. 判断状态别用 `(string= event "finished")` 整串比，用 `string-match-p` 或者干脆看 `(process-live-p proc)`；
2. sentinel **可能在进程停止/继续/结束时被多次调用**，所以「sentinel 被调用了」不等于「进程结束了」；
3. 取退出码用 `(process-exit-status proc)`，别去解析 event 字符串。

## 20.7 老 API：start-process

```elisp
;; 老 API：start-process（把输出收进一个 buffer）+ set-process-sentinel。
;; 新代码推荐 make-process，但读老包时会遇到这套。
(let* ((buf (generate-new-buffer " *demo-proc*"))
       (proc (start-process "demo-old" buf shell-file-name
                            shell-command-switch "echo old-api")))
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "8) start-process 输出: %S\n"
                 (string-trim (with-current-buffer buf (buffer-string)))))
  (kill-buffer buf))
```

```text
8) start-process 输出: "old-api

Process demo-old finished"
```

它把输出直接收集进一个 buffer（简单场景很方便），而且**进程结束后 Emacs 会往 buffer 里追加一行 `Process xxx finished`**——上面第二段空行后面的那行就是。这也是为什么实际项目里更愿意用 `:filter`：自己收的数据干净，不会混进这种状态提示。

配套的老函数是 `(set-process-sentinel proc #'demo-sentinel)`。新代码优先 `make-process`。

## 20.8 给进程喂输入

```elisp
;; 给进程发输入：process-send-string。用完要 process-send-eof 关掉 stdin，
;; 否则对端会一直等输入。
(let* ((out nil)
       (proc (make-process
              :name "demo-cat"
              :command (list "cat")
              :buffer nil
              :filter (lambda (_p s) (push s out))
              :sentinel #'ignore)))
  (process-send-string proc "通过 stdin 喂进去的一行\n")
  (process-send-eof proc)
  (while (process-live-p proc)
    (accept-process-output proc 0.05))
  (princ (format "9) cat 回显: %S\n" (string-trim (apply #'concat (nreverse out))))))
```

```text
9) cat 回显: "通过 stdin 喂进去的一行"
```

**别忘了 `process-send-eof`** —— 像 `cat`、`grep` 这种从 stdin 读的程序，收不到 EOF 就会一直等着，你的 `while` 也就永远出不来。

## 20.9 超时与杀进程

```elisp
;; 超时与杀进程。外部工具挂住是很常见的，一定要有兜底：
;;  (delete-process proc)      发信号让它退出
;;  (kill-process proc)        更强硬一点
;;  (process-live-p proc)      判活
(let ((proc (make-process :name "demo-sleep"
                          :command (list "sleep" "30")
                          :buffer nil :filter #'ignore :sentinel #'ignore)))
  (accept-process-output proc 0.05)
  (princ (format "10) 启动 sleep 30: 活着 = %S\n" (process-live-p proc)))
  (delete-process proc)
  (accept-process-output proc 0.05)
  (princ (format "    delete-process 之后: 活着 = %S\n" (process-live-p proc))))
```

```text
10) 启动 sleep 30: 活着 = (run open listen connect stop)
    delete-process 之后: 活着 = nil
```

> 【坑】`(process-live-p proc)` **返回的不是 `t`**，而是进程的状态列表（上面那串 `(run open listen connect stop)`）。它非 nil 即真，所以 `if (process-live-p p)` 没问题；但你要是把它打印给用户看、或者拿去 `equal` 比较 `t`，就会翻车。想看可读状态用 `(process-status proc)`（返回 `run` / `exit` / `signal` 这样的符号）。

三个函数：`(delete-process proc)` 温和终止、`(kill-process proc)` 更强硬、`(process-live-p proc)` 判活。

**外部工具挂住是很常见的**（网络请求、等锁、弹出交互式提示），所以一定要有超时兜底。示例里把标准写法跑了一遍——注意 `accept-process-output` 带超时参数，**它才是这段循环里真正让出控制权的地方**：

```elisp
;; 超时兜底的标准写法：deadline + 轮询 accept-process-output。
;; 外部工具挂住（等网络、等锁、弹出交互提示）是常态，所以**必须**有超时。
(let* ((proc (make-process :name "demo-timeout"
                           :command (list "sleep" "30")
                           :buffer nil :filter #'ignore :sentinel #'ignore))
       (deadline (+ (float-time) 1))
       (timed-out nil))
  (while (and (process-live-p proc) (< (float-time) deadline))
    (accept-process-output proc 0.1))
  (when (process-live-p proc)
    (setq timed-out '超时已触发)
    (delete-process proc))
  (princ (format "10b) 1 秒后仍活着 → %S，杀掉之后还活着吗: %S\n"
                 timed-out (process-live-p proc))))
```

```text
10b) 1 秒后仍活着 → 超时已触发，杀掉之后还活着吗: nil
```

## 20.10 清理

```elisp
;; 清理
(delete-directory demo-proc-dir t)
(princ (format "11) 临时目录已清理: %S\n" (not (file-exists-p demo-proc-dir))))
```

```text
11) 临时目录已清理: t
```

进程、临时文件都要在结束时清理干净。写扩展时用 `unwind-protect` 包住（第 22 章），或者把进程对象挂在 buffer-local 变量上、在 `kill-buffer-hook` 里清理。

## 20.11 坑位清单

1. 写死 `/bin/sh` / `cmd.exe` —— 用 `shell-file-name` + `shell-command-switch`。
2. 同步 `call-process` 跑长命令 —— 会卡死整个 Emacs 界面。
3. 用 `shell-command-to-string` 判成败 —— 它不返回退出码，stderr 还会混进返回值。
4. 把命令和参数拼成一个字符串交给 shell —— 慢、要转义、有注入风险；逐个传参。
5. 不查 `executable-find` 就直接启动外部程序 —— 用户只会看到一句莫名其妙的报错。
6. 以为 `make-process` 的 `:filter` 一次给一行 —— 它给的是原始字节串，行可能被切段。
7. 用 `string=` 比较 sentinel 的 `event` —— 末尾有 `\n`，而且可能被调用多次。
8. 以为「sentinel 被调用 = 进程结束」—— 停止/继续也会触发；判活看 `process-live-p`。
9. 忘了 `process-send-eof` —— `cat`/`grep` 这类程序会永远等下去。
10. 以为 `process-live-p` 返回 `t` —— 它返回的是状态列表 `(run open ...)`。
11. batch 下忘了手动 `accept-process-output` —— filter/sentinel 永远不会被推动。
12. 没有超时兜底 —— 外部工具挂住时你的扩展就跟着挂住。

---

上一章：[19 · advice：不改源码改行为](19-advice.md)　｜　下一章：[21 · 定时器](21-timers.md)　｜　返回：[Emacs 扩展开发指南](README.md)
