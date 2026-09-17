# 12 · slices 与 maps：标准库集合操作

> 对应示例：`examples/12_collections/`

1.21 之前，Go 的集合操作散落在 `sort`（只能排特定类型）和手写循环里。泛型落地后 `slices`/`maps` 两个包把日常操作一网打尽——**新代码的默认选择**。

## 12.1 slices：查找

```go
nums := []int{42, 7, 19, 3, 19}
slices.Index(nums, 19)        // 2：第一个匹配；没有则 -1
slices.Contains(nums, 3)      // true
slices.Equal(a, b)            // 逐元素相等
i, found := slices.BinarySearch(sorted, 19)   // 二分：前提是有序！
```

**BinarySearch 不检查有序性**——无序切片上跑二分返回垃圾值不报错（示例 12 专门演示了这个坑）。

## 12.2 slices：排序

```go
s := slices.Clone(nums)     // 不动原切片：先克隆再排
slices.Sort(s)              // 升序，原地
slices.SortStable(s)        // 稳定版（相等元素保持原序）
slices.Reverse(s)           // 原地反转

// 自定义比较：SortFunc 收一个 cmp 风格函数（负/零/正）
slices.SortFunc(users, func(a, b User) int { return cmp.Compare(a.Age, b.Age) })
```

`SortFunc` 的比较函数返回 **int**（不是 bool！）：`cmp.Compare(x, y)` 一行生成。要次级排序键，先比主键再比次键（示例 12 的测试里有完整写法）。

老的 `sort.Slice(s, less)` 传 bool 函数，和 `slices.SortFunc` 的 int 函数**签名不同**——抄代码看清是哪家的。

## 12.3 slices：变形操作

| 函数 | 干什么 | 备注 |
|---|---|---|
| `Clone(s)` | 深复制切片 | nil 安全 |
| `Compact(s)` | 相邻去重 | 排序后 = 全量去重 |
| `Insert(s, i, v...)` | 插入 | 返回新切片 |
| `Delete(s, i, j)` | 删除区间 | 尾部元素可能残留（置零） |
| `Concat(a, b...)` | 拼接 | 1.22+ |
| `Replace(s, i, j, v...)` | 区间替换 | |
| `Grow(s, n)` | 预留容量 | 防中途搬家 |
| `Max/Min(s)` | 最值 | 1.21+ |

## 12.4 maps：三个函数

```go
maps.Clone(m)                    // 浅克隆（值是指针时只拷指针）；nil 安全
maps.Copy(dst, src)              // 批量塞入（覆盖同名键）
maps.DeleteFunc(m, func(k, v) bool)  // 按谓词删除
```

maps 包就这些——刻意的小。

## 12.5 迭代器联动：Keys/Values（1.23+）

```go
m := map[string]int{"go": 2, "zig": 3, "c": 1}

for _, k := range slices.Sorted(maps.Keys(m)) {   // 排序键一步到位
	fmt.Println(k, m[k])
}
vals := slices.Collect(maps.Values(m))            // 迭代器 → 切片
```

`maps.Keys/Values` 返回**迭代器**（`iter.Seq`）而不是切片——配合 `slices.Sorted`/`Collect` 消费，不给中间垃圾留内存。这是 1.23 前后 API 的显著差异：老教程写 `maps.Keys(m)` 当切片用，新版本要 Collect（13 章专讲迭代器）。

## 12.6 选型速查

| 需求 | 选择 |
|---|---|
| 有序去重 | Sort → Compact |
| 按字段找 | `slices.IndexFunc(s, pred)` |
| 集合运算 | map[T]struct{} + 循环（没有现成的 set 包） |
| 稳定排序 | `slices.SortStable` |
| 堆 / 链表 | `container/heap`、`container/list`（老但能用，非泛型） |
| 多键排序 | SortFunc 里逐键比（示例 12 测试） |

## 12.7 坑位清单

1. **BinarySearch 前忘排序**：不报错、给垃圾——上二分先问自己"这切片凭什么有序"。
2. **SortFunc 返回 bool**：那是 `sort.Slice` 的签名；`slices.SortFunc` 要 int（`cmp.Compare`）。
3. **Sort 改的是原切片**：要保留原序先 `Clone`（示例 12 的测试专门验证这一点）。
4. **Delete 尾部残留**：`slices.Delete` 把删掉的元素置零但底层数组不缩——对内存敏感的场景用 `Clear`+`Truncate` 惯用法。
5. **maps.Keys 不是切片**：1.23+ 返回迭代器，老教程当 []K 用的代码直接编译错——套 `slices.Collect` 或 `slices.Sorted`。
6. **Compact 只去相邻**：`[1,2,1]` 压完还是仨——先 Sort 再 Compact。

---
