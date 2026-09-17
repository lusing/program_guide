// Package store 提供极简内存 KV 存储。
// 放在 internal/ 下：编译器保证只有 layout 模块内的代码能 import 它，
// 外部模块就算写出导入路径也过不了编译——这是 Go 的硬性封装边界。
package store

import (
	"errors"
	"fmt"
	"slices"
)

// ErrNotFound 缺键哨兵错误：导出给调用方做 errors.Is 判断。
var ErrNotFound = errors.New("key not found")

// Store 内存 KV。零值可用：data 惰性初始化。
// 导出类型 + 非导出字段 = 数据结构公开、表示细节私有。
type Store struct {
	data map[string]string
}

// Get 取值；缺键时返回包裹了 ErrNotFound 的错误。
func (s *Store) Get(key string) (string, error) {
	v, ok := s.data[key] // nil map 读是安全的
	if !ok {
		return "", fmt.Errorf("get %q: %w", key, ErrNotFound)
	}
	return v, nil
}

// Set 存值。第一次写入时初始化内部 map（nil map 写会 panic）。
func (s *Store) Set(key, val string) {
	if s.data == nil {
		s.data = make(map[string]string)
	}
	s.data[key] = val
}

// Delete 删键（缺键不报错——幂等）。
func (s *Store) Delete(key string) {
	delete(s.data, key)
}

// Keys 返回排好序的键（map 遍历无序，对外输出统一走这里）。
func (s *Store) Keys() []string {
	keys := make([]string, 0, len(s.data))
	for k := range s.data {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return keys
}
