package main

import (
	"testing"
	"unsafe"
)

func TestLayouts(t *testing.T) {
	var p Padded
	var q Packed
	if unsafe.Sizeof(p) != 24 {
		t.Errorf("Padded = %d, want 24（1+7填充+8+1+7填充）", unsafe.Sizeof(p))
	}
	if unsafe.Sizeof(q) != 16 {
		t.Errorf("Packed = %d, want 16（字段重排省掉一轮填充）", unsafe.Sizeof(q))
	}
	if unsafe.Offsetof(p.B) != 8 {
		t.Errorf("Padded.B 偏移 = %d, want 8", unsafe.Offsetof(p.B))
	}
	if unsafe.Offsetof(q.A) != 8 || unsafe.Offsetof(q.C) != 9 {
		t.Errorf("Packed.A/C 偏移 = %d/%d, want 8/9", unsafe.Offsetof(q.A), unsafe.Offsetof(q.C))
	}
}

func TestZeroCopyNoAlloc(t *testing.T) {
	buf := make([]byte, 1<<20) // 1MiB
	allocs := testing.AllocsPerRun(100, func() {
		_ = ZeroCopyString(buf)
	})
	if allocs != 0 {
		t.Errorf("零拷贝不应分配，got %v 次/轮", allocs)
	}
	// 对照组：标准转换每次 1 次分配
	std := testing.AllocsPerRun(100, func() {
		_ = string(buf)
	})
	if std < 1 {
		t.Errorf("string(b) 应有分配，got %v", std)
	}
}

func TestZeroCopySemantics(t *testing.T) {
	buf := []byte("hello")
	s := ZeroCopyString(buf)
	if s != "hello" {
		t.Errorf("视图 = %q", s)
	}
	if len(ZeroCopyString(nil)) != 0 {
		t.Error("空输入应得空串（SliceData 可能返回 nil，必须特判）")
	}
	view := WritableView(s)
	view[0] = 'H' // 改视图 = 改 buf：三方一份字节
	if buf[0] != 'H' || s[0] != 'H' {
		t.Errorf("可写视图未生效：buf=%q s=%q", buf, s)
	}
}

func TestReinterpretCast(t *testing.T) {
	type celsius float64
	type fahrenheit float64
	c := celsius(0)
	f := (*fahrenheit)(unsafe.Pointer(&c))
	*f = 32 // 写 f 就是写 c
	if c != 32 {
		t.Errorf("重解释后共享内存失效: c = %v", c)
	}
}
