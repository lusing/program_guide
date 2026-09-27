// 32_process：exec 三种拿输出、退出码、CommandContext 杀进程、signal.NotifyContext。
// 子进程用"自我重入"模式：设置 DEMO_CHILD 环境变量后再跑自己，走 childMain 分支——
// 跨平台（不依赖 echo/ls 这些 Unix 命令），测试里用 TestHelperProcess 走同一条路。
// 对照 docs/32-process.md。
package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

// childMain 是子进程模式的入口：mode 决定行为，返回退出码。
func childMain(mode string) int {
	switch mode {
	case "exit3": // 往两头打印 + 退出码 3
		fmt.Println("child: 正常输出")
		fmt.Fprintln(os.Stderr, "child: 错误输出")
		return 3
	case "upper": // 读 stdin 转大写写回 stdout
		b, _ := io.ReadAll(os.Stdin)
		fmt.Print(strings.ToUpper(string(b)))
		return 0
	case "sleep": // 睡 10 秒（被父进程杀掉用）
		time.Sleep(10 * time.Second)
		fmt.Println("child: 睡醒了")
		return 0
	}
	fmt.Fprintln(os.Stderr, "child: 未知模式", mode)
	return 99
}

// RunChild 起子进程并等它结束，返回合并输出与退出码。
// args 留给测试传 -test.run=TestHelperProcess；exe 是"自己"这个可执行文件。
func RunChild(exe string, args []string, mode string) (string, int) {
	cmd := exec.Command(exe, args...)
	cmd.Env = append(os.Environ(), "DEMO_CHILD="+mode) // 追加：Env 设了就是全量替换
	out, err := cmd.CombinedOutput()
	code := 0
	if err != nil {
		var ee *exec.ExitError
		if errors.As(err, &ee) {
			code = ee.ExitCode()
		} else {
			fmt.Println("没跑起来:", err)
			return string(out), -2
		}
	}
	return string(out), code
}

// PipeToUpper 流式喂数据：StdinPipe 写完必须 Close（子进程才见 EOF）。
func PipeToUpper(exe string, args []string, input string) (string, error) {
	cmd := exec.Command(exe, args...)
	cmd.Env = append(os.Environ(), "DEMO_CHILD=upper")
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return "", err
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return "", err
	}
	if err := cmd.Start(); err != nil { // 管道模式：Start，不是 Run
		return "", err
	}
	if _, err := io.Copy(stdin, strings.NewReader(input)); err != nil {
		return "", err
	}
	if err := stdin.Close(); err != nil { // EOF 在这
		return "", err
	}
	var buf strings.Builder
	if _, err := io.Copy(&buf, stdout); err != nil { // 先读完
		return "", err
	}
	if err := cmd.Wait(); err != nil { // 后 Wait——顺序反了会死锁
		return "", err
	}
	return buf.String(), nil
}

// KillAfter 用 CommandContext 跑 sleep 子进程，d 后杀掉。
func KillAfter(ctx context.Context, exe string, args []string, d time.Duration) error {
	ctx, cancel := context.WithTimeout(ctx, d)
	defer cancel()
	cmd := exec.CommandContext(ctx, exe, args...)
	cmd.Env = append(os.Environ(), "DEMO_CHILD=sleep")
	cmd.Stdout = io.Discard
	return cmd.Run()
}

func main() {
	// 子进程分支：被自己（带着环境变量）重新拉起时走这里
	if mode := os.Getenv("DEMO_CHILD"); mode != "" {
		os.Exit(childMain(mode))
	}
	exe, args := os.Args[0], []string(nil)

	fmt.Println("== Output/CombinedOutput + 退出码 ==")
	out, code := RunChild(exe, args, "exit3")
	fmt.Printf("退出码 %d；合并输出:\n%s", code, out)

	fmt.Println("== 管道：喂 stdin 收 stdout ==")
	got, err := PipeToUpper(exe, args, "hello, 子进程\n")
	if err != nil {
		fmt.Println("管道失败:", err)
	} else {
		fmt.Printf("大写回显: %q\n", got)
	}

	fmt.Println("== CommandContext：超时杀进程 ==")
	start := time.Now()
	err = KillAfter(context.Background(), exe, args, 50*time.Millisecond)
	var ee *exec.ExitError
	if errors.As(err, &ee) {
		fmt.Printf("%v 后被杀（%T）\n", time.Since(start).Round(time.Millisecond), err)
	} else {
		fmt.Println("预期被杀出错，实际:", err)
	}

	fmt.Println("== signal.NotifyContext：信号变取消 ==")
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	fmt.Println("注册后 Ctrl-C 不再直接退出程序，而是取消这个 ctx")
	select {
	case <-ctx.Done():
		fmt.Println("收到信号（或 stop 被调）→ 优雅关停:", ctx.Err())
	case <-time.After(100 * time.Millisecond):
		fmt.Println("100ms 没信号（演示里不可能收到）→ 平时这里放正常业务")
	}
	stop() // 恢复默认行为；它同时取消 ctx
	fmt.Println("stop() 后:", ctx.Err())

	fmt.Println("== 底层：Notify channel + Stop（不关 channel） ==")
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt)
	signal.Stop(ch)
	select {
	case s, ok := <-ch:
		fmt.Println("收到:", s, "channel 还开着:", ok)
	default:
		fmt.Println("Stop 只停止投递，不关 channel——这里永远走 default")
	}
}
