//go:build windows

package main

// platformNote 由构建标签挑选：交叉编译到 linux/darwin 时本文件不参与编译，
// 换成 version_other.go 里那份。目录里同时只活一份。
const platformNote = "Windows 专属常量（version_windows.go）"
