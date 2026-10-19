# 20 · 子进程

> 所属部分：第 4 部分 · 与外部世界
>
> **本部分导读**：扩展能力的天花板，很大程度上取决于它能不能调用外部工具、能不能处理时间、能不能优雅地失败。 这三章分别对应 `process`、`timer` 和错误处理。

> 示例：`examples/20-processes.el`

## 20.1 跨平台前提

```elisp
(princ (format "0) shell = %S, switch = %S\n" shell-file-name shell-command-switch))
```

```
0) shell = "/bin/bash", switch = "-c"
```

**不要写死 `cmd.exe` / `/bin/sh`。** 用 `shell-file-name` 和 `shell-command-switch`，
Emacs 会填好当前平台的值。这是让扩展跨平台的第一个前提。

## 20.2 同步调用

```elisp
(call-process "echo" nil t nil "hello")        ; 输出进当前 buffer，同步等待
(shell-command-to-string "echo hello")         ; 只想要输出字符串
(call-process "make" nil "*out*" nil "all")    ; 输出进指定 buffer
(call-process "make" nil "/tmp/log.txt" nil "all")   ; 输出直接进文件
```

```
1) call-process 退出码 = 0，输出 = "sync-hello"
2) shell-command-to-string: "from-shell"
3) 文件里的结果: "written-to-file"
```

`call-process` 的参数是 `(program &optional infile destination display &rest args)`：

| destination | 含义 |
|---|---|
| `nil` | 丢弃输出 |
| `t` | 插到当前 buffer 的 point 处 |
| 字符串 | 这是 buffer 名（不存在则新建） |
| `(file . name)` | 写进文件 |
| 函数 | 用函数接收输出 |

**同步调用会卡住 Emacs。** 只适合几毫秒能返回的命令。跑 `make` / `git` / 语言服务器一律用异步。

## 20.3 【坑】命令和参数必须分开传

```elisp
;; 正确
(call-process "git" nil t nil "log" "--oneline")

;; 错误：把整串交给 shell，文件名里有空格/引号就会出问题
(call-process shell-file-name nil t nil "-c" "git log --oneline")
```

理由：分开传时**不经过 shell**，所以参数里的空格、引号、`$`、`;` 都是普通字符，不需要转义，
也不会有命令注入风险。只有确实需要 shell 特性（管道、重定向、通配符）时，才显式地用 shell。

## 20.4 先查可执行文件

```elisp
(executable-find "echo")        ; → "/bin/echo"
(executable-find "no-such-bin") ; → nil
```

```
5) executable-find "echo" = "/bin/echo"
   找一个不存在的: nil
```

**调用外部程序之前一定先查一次**，查不到就给出清晰的错误提示（而不是让用户看到
`Searching for program: No such file or directory`）。

## 20.5 异步进程：make-process

```elisp
(make-process
 :name "demo"
 :buffer nil                              ; nil = 不自动插进 buffer
 :command (list "echo" "async-hello")
 :filter (lambda (proc chunk) ...)        ; 收到输出时调用
 :sentinel (lambda (proc event) ...))     ; 状态变化时调用
```

```
6) 异步收到: "async-hello"，进程还活着吗: nil
```

它是**立刻返回**的：Emacs 不会阻塞，进程的输出通过 `:filter` 回调送达。

## 20.6 【坑】sentinel 的 event 末尾带换行

```elisp
(defun demo-sentinel (proc event)
  (princ (format "7) sentinel 收到的 event: %S\n" event)))
```

```
7) sentinel 收到的 event: ("finished
")
   退出码 = 0
```

`event` 是形如 `"finished\n"` / `"exited abnormally with code 1\n"` 的字符串 ——
**末尾有换行**。要判断状态别用 `string=` 整串比，用 `string-match-p` 或者
`(process-exit-status proc)`。

想拿退出码用 `process-exit-status`。`process-live-p` 判是否还活着。

## 20.7 老 API：start-process

```elisp
(start-process "name" "*buffer*" "cmd" "args")
(set-process-sentinel proc #'demo-sentinel)
```

```
8) start-process 输出: "old-api

Process demo-old finished"
```

它把输出直接收集进一个 buffer（所以简单场景很方便），但没有 filter 的灵活性。
新代码优先用 `make-process`。

## 20.8 给进程喂输入

```elisp
(process-send-string proc "通过 stdin 喂进去的一行\n")
(process-send-eof proc)          ; 关掉 stdin，很多程序靠这个才开始处理
```

```
9) cat 回显: "通过 stdin 喂进去的一行"
```

**别忘了 `process-send-eof`** —— 像 `cat`、`grep` 这种从 stdin 读的程序，收不到 EOF 就会一直等着。

## 20.9 超时与杀进程

```elisp
(when (process-live-p proc)
  (delete-process proc))         ; 温和终止
;; (kill-process proc) 发信号
```

```
10) 启动 sleep 30: 活着 = (run open listen connect stop)
    delete-process 之后: 活着 = nil
```

**外部工具挂住是很常见的**（网络请求、等锁、交互式提示），所以一定要有超时兜底：

```elisp
(let ((deadline (+ (float-time) 5)))
  (while (and (process-live-p proc) (< (float-time) deadline))
    (accept-process-output proc 0.1))
  (when (process-live-p proc)
    (delete-process proc)
    (error "命令超时")))
```

## 20.10 清理

```
11) 临时目录已清理: t
```

进程、临时文件都要在结束时清理干净。写扩展时用 `unwind-protect` 包住，
或者把进程对象挂在 buffer-local 变量上、在 `kill-buffer-hook` 里清理。

---

上一章：[19 · advice：不改源码改行为](19-advice.md)　｜　下一章：[21 · 定时器](21-timers.md)　｜　返回：[Emacs 扩展开发指南](README.md)
