package main

import "testing"

func TestFizzBuzz(t *testing.T) {
	cases := map[int]string{
		1: "1", 3: "Fizz", 5: "Buzz", 15: "FizzBuzz", 30: "FizzBuzz",
	}
	for n, want := range cases {
		if got := FizzBuzz(n); got != want {
			t.Errorf("FizzBuzz(%d) = %q, want %q", n, got, want)
		}
	}
}

func TestClassify(t *testing.T) {
	cases := []struct {
		in   any
		want string
	}{
		{nil, "空值"},
		{42, "整数 42"},
		{"嗨", "字符串 嗨"},
		{[]string{"a", "b"}, "字符串切片，长度 2"},
		{3.14, "其他类型 float64"},
	}
	for _, c := range cases {
		if got := Classify(c.in); got != c.want {
			t.Errorf("Classify(%v) = %q, want %q", c.in, got, c.want)
		}
	}
}

func TestFind(t *testing.T) {
	grid := [][]int{{1, 2}, {3, 4}, {5, 6}}
	if r, c, ok := Find(grid, 4); !ok || r != 1 || c != 1 {
		t.Errorf("Find(4) = (%d,%d,%v), want (1,1,true)", r, c, ok)
	}
	if _, _, ok := Find(grid, 99); ok {
		t.Error("Find(99) 不该找到")
	}
}
