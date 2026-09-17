// 12_collections：slices / maps 标准库——泛型时代的集合操作。
package main

import (
	"cmp"
	"fmt"
	"maps"
	"slices"
)

type User struct {
	Name string
	Age  int
}

func main() {
	nums := []int{42, 7, 19, 3, 19}

	fmt.Println("== slices：查找 ==")
	fmt.Println("Index(19):", slices.Index(nums, 19)) // 第一个匹配下标
	fmt.Println("Contains(3/99):", slices.Contains(nums, 3), slices.Contains(nums, 99))
	i, found := slices.BinarySearch(nums, 19)
	fmt.Println("无序切片二分:", i, found, "← 不可靠！二分前必须先排序")

	fmt.Println("== slices：排序（先克隆再排，不动原切片） ==")
	sorted := slices.Clone(nums)
	slices.Sort(sorted)
	fmt.Println(nums, "→", sorted)
	i, found = slices.BinarySearch(sorted, 19)
	fmt.Println("有序后二分:", i, found)

	users := []User{{"阿G", 30}, {"阿Z", 25}, {"老王", 40}}
	slices.SortFunc(users, func(a, b User) int { return cmp.Compare(a.Age, b.Age) })
	for _, u := range users {
		fmt.Printf("%s(%d) ", u.Name, u.Age)
	}
	fmt.Println()

	fmt.Println("== slices：去重 / 插入 / 拼接 ==")
	withDup := []int{1, 2, 2, 3, 3, 3}
	fmt.Println("Compact（相邻去重）:", slices.Compact(withDup))
	fmt.Println("Insert(1, 100):", slices.Insert(sorted, 1, 100))
	fmt.Println("Concat:", slices.Concat([]int{1, 2}, []int{3, 4}))
	fmt.Println("Equal:", slices.Equal([]int{1, 2}, []int{1, 2}))

	fmt.Println("== maps：克隆与拷贝 ==")
	src := map[string]int{"a": 1, "b": 2}
	dst := maps.Clone(src) // nil 安全：克隆 nil 得 nil
	dst["c"] = 3
	fmt.Println("src:", src, "dst:", dst)

	fmt.Println("== 迭代器联动（1.23+）：Keys/Values 变成了迭代器 ==")
	m := map[string]int{"go": 2, "zig": 3, "c": 1}
	for _, k := range slices.Sorted(maps.Keys(m)) { // 排序键一步到位
		fmt.Printf("%s=%d ", k, m[k])
	}
	fmt.Println()
	vals := slices.Collect(maps.Values(m))
	slices.Sort(vals)
	fmt.Println("排序后的值:", vals)
}
