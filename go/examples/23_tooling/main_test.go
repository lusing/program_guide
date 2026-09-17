package main

import (
	"os"
	"runtime"
	"testing"
)

func TestBuildSummary(t *testing.T) {
	goVer, _ := BuildSummary()
	if goVer == "" {
		t.Error("ReadBuildInfo 应拿到 Go 版本")
	}
	if runtime.GOOS != "windows" || runtime.GOARCH != "amd64" {
		t.Errorf("本机验证环境应是 windows/amd64: %s/%s", runtime.GOOS, runtime.GOARCH)
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
