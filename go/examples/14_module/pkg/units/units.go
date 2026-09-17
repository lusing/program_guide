// Package units 做单位换算。
// 放在 pkg/ 下：约定俗成的"公共库"位置，其他模块可以放心 import
// （对比 internal/ 的强制私有——两者都是目录约定，但只有 internal 有编译器撑腰）。
package units

import "fmt"

// FormatBytes 把字节数格式化成人类可读形式（512 B、4.0 KiB、4.8 MiB）。
func FormatBytes(n int64) string {
	const unit = 1024
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	div, exp := int64(unit), 0
	for m := n / unit; m >= unit; m /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(n)/float64(div), "KMGTPE"[exp])
}
