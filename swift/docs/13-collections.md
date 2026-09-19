# 13 · 集合

> 对应示例：`examples/13_collections/`

## 13.1 三大容器一张表

| | Array | Set | Dictionary |
|---|---|---|---|
| 结构 | 有序序列 | 无序去重集 | 键值映射 |
| 元素要求 | 任意 | `Hashable` | Key: `Hashable` |
| 下标 | `Int`（O(1)） | 无 | 键（缺键返回 nil） |
| 字面量 | `[1, 2, 3]` | `[1, 2, 3]`（类型标注 Set） | `["a": 1]` |
| 去重 | 手动 | 自动 | 键自动 |
| 典型用法 | 顺序、索引、栈队列 | 成员测试、集合代数 | 查表、计数、分组 |

三者都是 **struct（值语义）+ COW**：赋值 O(1) 共享缓冲，首次修改才复制。

## 13.2 Array：值语义与 COW 的实证

```swift
var original = [1, 2, 3, 4, 5]
let copy = original        // O(1)：共享缓冲 + 引用计数
original.append(6)         // COW 触发：此刻才真正复制
copy                       // [1, 2, 3, 4, 5] —— 没被污染
```

这是 07 章"值语义"在集合上的具体化。三个推论：

- 函数参数传数组**不会**隐式深拷贝（COW 兜底）——不必学 C++ 的 `const&` 焦虑；
- 多个拷贝只改其中一个，其余照常共享——内存友好；
- 想强制独立：`var independent = original` 后立即 `independent.append(x)` 或显式
  `mutableCopy()` 习惯不存在，Swift 里"改一下"就是复制点。

常用操作速览（示例 13.6 全部实测）：

```swift
numbers.sort()                        // 原地（mutating）
numbers.sorted()                      // 返回新数组（不改原）
numbers.first / .last / .min() / .max()
numbers.contains(8) / .firstIndex(of: 8)
numbers.filter { $0 > 4 }.reduce(0, +)
numbers.reversed() / .prefix(3) / .suffix(2) / .dropFirst()
array.insert(0, at: 0) / array.remove(at: 0) / .removeLast() / .popLast()
```

## 13.3 切片：集合第一大坑

```swift
let slice = original[1..<4]     // ArraySlice：[2, 3, 4]
slice[0]                        // ❌ 运行期崩溃！
slice[slice.startIndex]         // ✅ 2 —— 切片的起始下标是 1，不是 0
Array(slice)[0]                 // ✅ 2 —— 转正后索引重置
```

**切片继承原数组的索引**（它是原缓冲的视图，不是新数组）——`slice[0]` 在这里取到
的是"原下标 0"的位置，越界即崩。三条铁律：

1. 切片内部访问**永远用 `startIndex` / `indices`**；
2. 要当独立数组用，先 `Array(slice)` 转正；
3. `prefix`/`suffix`/`dropFirst` 返回的也是切片，同坑。

## 13.4 Set：集合代数

```swift
let primes: Set = [2, 3, 5, 7, 11]
let odds: Set = [1, 3, 5, 7, 9]

primes.union(odds)            // 并 [1, 2, 3, 5, 7, 9, 11]
primes.intersection(odds)     // 交 [3, 5, 7]
primes.subtracting(odds)      // 差 [2, 11]
primes.symmetricDifference(odds)  // 对称差 [1, 2, 9, 11]
Set([3, 5]).isSubset(of: primes)  // 成员测试
```

Set 的本命场景：**去重**（`Array(Set(xs))`）、**成员测试**（O(1)，数组是 O(n)）、
**集合代数**（权限交集、标签并集）。注意：字面量 `[3, 5]` 默认推断 Array——要 Set
方法必须显式 `Set([3, 5])` 或类型标注（实测坑）。遍历无序，要序先 `sorted()`。

## 13.5 Dictionary：默认值惯用法

```swift
var counts: [String: Int] = [:]
for word in text.split(whereSeparator: { $0.isWhitespace }) {
    counts[String(word), default: 0] += 1      // 计数的惯用一行
}

counts["to"]           // Int?——不存在的键返回 nil，不崩溃
counts["swift"] = 1    // 插入/更新
counts["to"] = nil     // 删除
```

- 下标返回 `V?`——"缺键"是正常业务（06 章哲学）。
- `[key, default: 0]` 读写都兜底——计数器、累加器的标准姿势，比"查-判-改"三行
  干净十倍。
- 遍历无序：`for (key, value) in dict`；要序排 `dict.sorted { $0.value > $1.value }`。
- 合并：`merge(_:uniquingKeysWith:)` 或手写循环（示例 `mergeCounts`）。

## 13.6 算法组合拳：词频统计

```swift
func wordFrequency(_ text: String) -> [String: Int] { ... }        // split + 计数
func topWords(_ counts: [String: Int], limit: Int) -> [(word: String, count: Int)] {
    counts
        .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
        .prefix(limit)
        .map { (word: $0.key, count: $0.value) }
}
```

`split` → `dictionary` → `sorted` → `prefix` → `map` 的管道——集合 + 闭包（11 章）
的组合是 Swift 日常代码的主力形态。排序比较器写清平局规则（次数同则字典序），
输出才确定。

## 13.7 坑位清单（含实测）

1. **切片下标不从 0 开始**（本章主演）：`slice[0]` 崩溃；用 `startIndex` 或
   `Array(slice)` 转正。`prefix/suffix/dropFirst` 全家同坑。
2. **Set 字面量默认推断 Array**（实测）：`[3, 5].isSubset(of: primes)` 编译错误——
   `Set([3, 5]).isSubset(of: primes)` 才行。
3. **`remove(at:)` 返回被删元素**，`popLast()` 返回 `Element?`（空数组得 nil），
   `removeLast()` 崩——空容器上的 last/remove 族先判 `isEmpty`。
4. **字典遍历无序**：两次遍历顺序可能不同——依赖顺序的输出先 `sorted()`。
5. **值类型键要 Hashable 才能进字典/Set**（09 章）：struct 全字段 Hashable 时自动
   合成；含非 Hashable 字段就得手写。
6. **`count` 是 O(1)**（容器缓存了计数）——`array.count == 0` 与 `isEmpty` 等价，
   惯用 `isEmpty`（对所有 Sequence 通用且意图明确）。
7. **大数组先 filter 后 sort**：`xs.filter {...}.sorted()` 远快于 `xs.sorted().filter
   {...}`——排序 O(n log n) 的 n 越小越好（管道顺序就是性能）。

上一章：[12 · 错误处理](12-errors.md) ｜ 下一章：[14 · 字符串](14-strings.md) ｜ 返回：[README](../README.md)
