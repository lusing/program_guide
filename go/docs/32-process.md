# 32 · 进程与信号：os/exec + os/signal

> 对应示例：`examples/32_process/`。Go 程序自己当"shell"：起子进程、接管道、管超时、收信号。

## 32.1 exec.Command：起一个子进程

```go
cmd := exec.Command("git", "log", "--oneline")   // 路径 + 参数逐个列，不经过 shell
cmd.Dir = "/repo"                                // 工作目录（默认继承当前）
cmd.Env = append(os.Environ(), "LANG=C")         // 环境（默认继承；设了就全量替换！）
err := cmd.Run()                                 // 起进程 + 等结束
```

**不经过 shell**：没有管道符、通配符、重定向——要这些能力就自己拼（`sh -c "..."` 是自担风险的逃逸口）。好处是**参数注入天然免疫**：文件名带空格、带 `;` 都只是普通参数。找不到可执行文件时 `LookPath` 已替你查过（错误信息很友好）。

## 32.2 拿输出的三种姿势

```go
out, err := cmd.Output()                 // 1. 只收 stdout；err 时 stderr 塞进 ExitError.Stderr
both, err := cmd.CombinedOutput()        // 2. stdout+stderr 合流（2>&1）

stdout, _ := cmd.StdoutPipe()            // 3. 流式：管道接管，边跑边读
cmd.Start()
io.Copy(os.Stdout, stdout)
cmd.Wait()

// 或者直接指到现成的 Writer/Reader：
cmd.Stdout = &buf                        // 写进 buffer/文件/os.Stdout 都行
cmd.Stdin = strings.NewReader("input")   // 喂标准输入
stdin, _ := cmd.StdinPipe()              // 动态喂：写完必须 Close，子进程才见 EOF
```

**Start 与 Run 的分工**：Run = Start + Wait；用了 StdoutPipe 就必须 Start（Run 会等不到）。管道是操作系统给的有限缓冲（约 64KiB）——**不读完不 Wait 会死锁**：子进程写满管道阻塞，父进程死等退出。

## 32.3 退出码：ExitError

```go
err := cmd.Run()
if err != nil {
    var ee *exec.ExitError
    if errors.As(err, &ee) {
        code := ee.ExitCode()    // 非零退出码；被信号杀时 Unix 上是 -1
    }
    // 找不到程序等"没跑起来"的错误不是 ExitError——errors.As 区分两者
}
```

## 32.4 CommandContext：超时杀进程

```go
ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
defer cancel()
cmd := exec.CommandContext(ctx, "ffmpeg", ...)
err := cmd.Run()     // 超时触发：库自动 Kill 子进程，Wait 返回 ExitError
```

生产环境的子进程调用**默认都该用 CommandContext**——18 章的 context 取消链在这里直接落地。注意它杀的是直接子进程：孙进程要绝根，用 `cmd.WaitDelay`（1.20+）或进程组手法。

## 32.5 os/signal：收信号

```go
// 现代姿势（1.16+）：信号直接变 context 取消——优雅关停的标配
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()
select {
case <-ctx.Done():        // Ctrl-C 或 SIGTERM 到达（调 stop() 也会取消）
    shutdown()
case <-workDone:
}

// 底层姿势：channel
ch := make(chan os.Signal, 1)            // 带缓冲：信号不阻塞、不丢
signal.Notify(ch, os.Interrupt)
signal.Stop(ch)                          // 注销（注意：不关 channel，只是不再投递）
```

`os.Interrupt` 就是 Ctrl-C；`syscall.SIGTERM` 是服务下线的标准信号。**注册过的信号 Go 不再走默认行为**（Ctrl-C 不再直接退出）——`defer stop()` 恢复默认，别把退出权弄丢。平台差异：Windows 实际只投递 `os.Interrupt`；`SIGKILL`/`SIGSTOP` 谁都拦不住。

## 32.6 速查

| 需求 | 用 |
|---|---|
| 跑一下拿结果 | `cmd.Output()` / `CombinedOutput()` |
| 大输出流式处理 | `StdoutPipe` + `Start` + 读 + `Wait` |
| 子进程超时 | `exec.CommandContext` |
| 优雅关停 | `signal.NotifyContext` + select |
| 找程序在哪 | `exec.LookPath("git")` |

## 32.7 坑位清单

1. **StdoutPipe 后调 Run**：Run 内部等 Wait，管道被提前关——用 Start。
2. **不读管道就 Wait**：64KiB 缓冲写满即死锁——先读后 Wait。
3. **StdinPipe 不 Close**：子进程读不到 EOF 干等——写完立刻 Close。
4. **cmd.Env 设了就全量替换**：想追加必须 `append(os.Environ(), ...)` 起头。
5. **把 -1 当退出码**：Unix 上被信号杀 ExitCode 是 -1（信号不是码），看 `ee.String()`。
6. **Notify 的 channel 无缓冲**：投递时没人收就丢——`make(chan os.Signal, 1)` 起步。
7. **信号注册后忘了 stop**：Ctrl-C 不再默认退出，程序"杀不死"——`defer stop()`。
8. **依赖 shell 语义**：`Command("ls | wc")` 把整串当文件名——没有 shell 参与，管道通配符都不存在。

---

---

上一章：[31 压缩与归档](31-archive.md) · 下一章：[33 命令行与日志](33-flaglog.md)
