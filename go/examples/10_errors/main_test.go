package main

import (
	"errors"
	"testing"
)

func TestLoadRecordWrap(t *testing.T) {
	_, err := LoadRecord(-1)
	if !errors.Is(err, ErrNotFound) {
		t.Errorf("包装链里应能 Is 到哨兵错误: %v", err)
	}
	if _, err := LoadRecord(1); err != nil {
		t.Errorf("合法 id 不应报错: %v", err)
	}
}

func TestParseAge(t *testing.T) {
	if n, err := ParseAge("42"); err != nil || n != 42 {
		t.Errorf("ParseAge(42) = (%d,%v)", n, err)
	}
	_, err := ParseAge("两百")
	var fe *FieldError
	if errors.As(err, &fe) {
		t.Errorf("数字解析失败不该是 FieldError: %v", err)
	}
	_, err = ParseAge("200")
	if !errors.As(err, &fe) {
		t.Errorf("越界应是 FieldError: %v", err)
	} else if fe.Field != "age" || fe.Why != "超出 0..150" {
		t.Errorf("FieldError 字段不对: %+v", fe)
	}
}

func TestSafeRun(t *testing.T) {
	if err := SafeRun(func() {}); err != nil {
		t.Errorf("不 panic 就没错误: %v", err)
	}
	if err := SafeRun(func() { panic("boom") }); err == nil {
		t.Error("panic 应被转成错误")
	}
}
