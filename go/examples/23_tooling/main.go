// 23_tooling：运行时环境、构建信息注入、pprof/trace、构建标签。
// 本目录还有一个 version_windows.go——构建标签只让它在 Windows 编译。
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"runtime/pprof"
	"runtime/trace"
	"sync"
	"time"
)

// buildNote 由构建期注入：go build -ldflags "-X main.buildNote=正式版" .
var buildNote = "开发版（未注入 -X）"

// BuildSummary 从二进制里读构建元数据（go version -m 看的就是同一份）。
func BuildSummary() (goVer string, hasVCS bool) {
	bi, ok := debug.ReadBuildInfo()
	if !ok {
		return "", false
	}
	goVer = bi.GoVersion
	for _, s := range bi.Settings {
		if s.Key == "vcs.revision" {
			hasVCS = true // go build 默认从 git 仓库带上版本信息
		}
	}
	return goVer, hasVCS
}

// ProfileCPU 采样约 200ms 的 CPU 画像写入临时文件（go tool pprof 查看）。
func ProfileCPU() (string, error) {
	f, err := os.CreateTemp("", "cpu-*.prof")
	if err != nil {
		return "", err
	}
	defer f.Close()
	if err := pprof.StartCPUProfile(f); err != nil {
		return "", err
	}
	defer pprof.StopCPUProfile()

	start := time.Now()
	x := 1.0001
	for time.Since(start) < 200*time.Millisecond { // 制造可采样的负载
		x *= 1.0000001
	}
	_ = x
	return f.Name(), nil
}

// WriteTrace 写执行跟踪：goroutine 调度、GC、阻塞一目了然（go tool trace 查看）。
func WriteTrace() (string, error) {
	f, err := os.CreateTemp("", "trace-*.out")
	if err != nil {
		return "", err
	}
	defer f.Close()
	if err := trace.Start(f); err != nil {
		return "", err
	}
	defer trace.Stop()

	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			sum := 0
			for i := range 1_000_000 {
				sum += i
			}
			_ = sum
		})
	}
	wg.Wait()
	return f.Name(), nil
}

func must(err error) {
	if err != nil {
		fmt.Println("出错了:", err)
		os.Exit(1)
	}
}

func main() {
	fmt.Println("== 运行时环境 ==")
	fmt.Println("OS/Arch:", runtime.GOOS, runtime.GOARCH)
	fmt.Println("CPU 数:", runtime.NumCPU(), "GOMAXPROCS:", runtime.GOMAXPROCS(0))
	fmt.Println("编译器版本:", runtime.Version())

	fmt.Println("== 构建信息 ==")
	goVer, hasVCS := BuildSummary()
	fmt.Println("构建用 Go:", goVer, "带 VCS 信息:", hasVCS)
	fmt.Println("注入的版本串:", buildNote)
	fmt.Println("平台专属常量:", platformNote) // 来自 version_windows.go

	fmt.Println("== CPU profile / 执行跟踪 ==")
	profPath, err := ProfileCPU()
	must(err)
	tracePath, err := WriteTrace()
	must(err)
	defer os.Remove(profPath)
	defer os.Remove(tracePath)
	st1, err := os.Stat(profPath)
	must(err)
	st2, err := os.Stat(tracePath)
	must(err)
	fmt.Println("cpu profile:", filepath.Base(profPath), st1.Size(), "字节 → go tool pprof 24_tooling.exe <文件>")
	fmt.Println("trace:      ", filepath.Base(tracePath), st2.Size(), "字节 → go tool trace <文件>")
}
