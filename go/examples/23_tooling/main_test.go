package main

import (
	"os"
	"runtime"
	"strings"
	"testing"
)

func TestBuildSummary(t *testing.T) {
	goVer, _ := BuildSummary()
	if goVer == "" {
		t.Error("ReadBuildInfo 应拿到 Go 版本")
	}
	if runtime.GOOS == "" || runtime.GOARCH == "" {
		t.Error("GOOS/GOARCH 不该为空")
	}
	// 平台断言不能写死 windows/amd64：教程在 windows/amd64 与 darwin/amd64 上都验证，
	// 写死一个平台会让另一个平台必挂。这里只断言「构建标签挑出来的那份常量」
	// 与当前 GOOS 一致——这条在任一平台都成立，而且才真正测到了构建标签。
	isWindowsConst := strings.Contains(platformNote, "Windows 专属")
	if isWindowsConst != (runtime.GOOS == "windows") {
		t.Errorf("构建标签挑错了 platformNote：GOOS=%s 却拿到 %q", runtime.GOOS, platformNote)
	}
	if platformNote == "" {
		t.Error("平台常量不该为空")
	}
}

func TestProfileCPU(t *testing.T) {
	path, err := ProfileCPU()
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(path)
	st, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if st.Size() == 0 {
		t.Error("profile 文件不该为空")
	}
}

func TestWriteTrace(t *testing.T) {
	path, err := WriteTrace()
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(path)
	if st, err := os.Stat(path); err != nil || st.Size() == 0 {
		t.Errorf("trace 文件异常: %v", err)
	}
}
