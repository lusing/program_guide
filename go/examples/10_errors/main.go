// 10_errors：哨兵错误、errors.Is/As、%w 包装链、errors.Join、panic/recover。
package main

import (
	"errors"
	"fmt"
	"strconv"
)

// 哨兵错误：包级变量，调用方用 errors.Is 识别。
var ErrNotFound = errors.New("记录不存在")

// FieldError 携带结构化信息：调用方用 errors.As 提取。
type FieldError struct {
	Field string
	Why   string
}

func (e *FieldError) Error() string {
	return fmt.Sprintf("字段 %s 不合法：%s", e.Field, e.Why)
}

// LoadRecord 演示 %w 包装：底层错误原样保留，外面套上下文。
func LoadRecord(id int) (string, error) {
	if id <= 0 {
		return "", fmt.Errorf("加载记录 %d：%w", id, ErrNotFound)
	}
	return fmt.Sprintf("记录#%d", id), nil
}

// ParseAge 校验 + 转换：数字错误包装底层，业务错误用结构化类型。
func ParseAge(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, fmt.Errorf("年龄必须是数字：%w", err)
	}
	if n < 0 || n > 150 {
		return 0, &FieldError{Field: "age", Why: "超出 0..150"}
	}
	return n, nil
}

// SafeRun 把 panic 转成错误：recover 只在 defer 里有效，
// 且只该在边界做（HTTP handler、goroutine 顶层、库的公开入口）。
func SafeRun(f func()) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic 已恢复: %v", r)
		}
	}()
	f()
	return nil
}

func main() {
	fmt.Println("== 哨兵错误 + errors.Is（穿透包装层） ==")
	if _, err := LoadRecord(-1); err != nil {
		fmt.Println("错误链:", err)
		fmt.Println("是 ErrNotFound 吗？", errors.Is(err, ErrNotFound))
	}

	fmt.Println("== 结构化错误 + errors.As ==")
	_, err := ParseAge("两百")
	var fe *FieldError
	fmt.Println("非数字错误是 FieldError 吗？", errors.As(err, &fe))
	if _, err := ParseAge("200"); errors.As(err, &fe) {
		fmt.Println("As 提取:", fe.Field, "→", fe.Why)
	}

	fmt.Println("== errors.Join：一次报多个（1.20+） ==")
	_, e1 := ParseAge("两百")
	joined := errors.Join(e1, ErrNotFound)
	fmt.Println(joined)
	fmt.Println("Is 穿透 Join:", errors.Is(joined, ErrNotFound))

	fmt.Println("== panic/recover：边界兜底 ==")
	if err := SafeRun(func() { panic("炸了") }); err != nil {
		fmt.Println("边界捕获:", err)
	}
	fmt.Println("程序还活着，继续跑")
}
