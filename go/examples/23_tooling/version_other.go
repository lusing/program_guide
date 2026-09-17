//go:build !windows

package main

// platformNote 的非 Windows 版本：让交叉编译也有一份定义。
const platformNote = "其他平台常量（version_other.go）"
