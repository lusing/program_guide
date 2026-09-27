package main

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"testing"
	"time"
)

// TestHelperProcess 是子进程替身（exec 包文档里的经典模式）：
// 父进程跑测试时 DEMO_CHILD 未设 → 立即返回，不干扰正常测试；
// 被 RunChild 以 -test.run=TestHelperProcess 拉起时 DEMO_CHILD 已设 → 走 childMain 退出。
func TestHelperProcess(t *testing.T) {
	if os.Getenv("DEMO_CHILD") == "" {
		return
	}
	os.Exit(childMain(os.Getenv("DEMO_CHILD")))
}

// helperArgs 返回测试二进制当子进程时的参数。
func helperArgs() []string { return []string{"-test.run=TestHelperProcess"} }

func TestRunChildExitCode(t *testing.T) {
	out, code := RunChild(os.Args[0], helperArgs(), "exit3")
	if code != 3 {
		t.Errorf("退出码 = %d, want 3", code)
	}
	if !strings.Contains(out, "正常输出") || !strings.Contains(out, "错误输出") {
		t.Errorf("合并输出缺内容: %q", out)
	}
}

func TestPipeToUpper(t *testing.T) {
	got, err := PipeToUpper(os.Args[0], helperArgs(), "hello\nworld\n")
	if err != nil {
		t.Fatal(err)
	}
	if got != "HELLO\nWORLD\n" {
		t.Errorf("PipeToUpper = %q", got)
	}
}

func TestKillAfter(t *testing.T) {
	start := time.Now()
	err := KillAfter(context.Background(), os.Args[0], helperArgs(), 50*time.Millisecond)
	if err == nil {
		t.Fatal("sleep 子进程被杀应报错")
	}
	var ee *exec.ExitError
	if !errors.As(err, &ee) {
		t.Fatalf("应是 *exec.ExitError，got %T: %v", err, err)
	}
	if elapsed := time.Since(start); elapsed > 5*time.Second {
		t.Errorf("没有及时杀掉，耗时 %v", elapsed)
	}
}

func TestNotifyContextStopCancels(t *testing.T) {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	stop() // stop 会取消 ctx——不用真发信号就能测
	if ctx.Err() == nil {
		t.Error("stop() 应取消 ctx")
	}
	select {
	case <-ctx.Done():
	default:
		t.Error("ctx.Done() 应已关闭")
	}
}

func TestEnvAppend(t *testing.T) {
	cmd := exec.Command("whatever")
	cmd.Env = append(os.Environ(), "DEMO_CHILD=upper")
	found := false
	for _, kv := range cmd.Env {
		if kv == "DEMO_CHILD=upper" {
			found = true
		}
	}
	if !found {
		t.Error("追加的环境变量应在列表里")
	}
	if len(cmd.Env) <= len(os.Environ())-1+1 { // 至少 = 原 + 1
		t.Errorf("Env 应是全量替换 + 追加，got %d 项", len(cmd.Env))
	}
}
