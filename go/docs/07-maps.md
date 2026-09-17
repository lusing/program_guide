# 07 · map

> 对应示例：`examples/07_maps/`

## 7.1 基本操作

```go
ages := map[string]int{"阿G": 18, "阿Z": 25}   // 字面量
m := make(map[string]int)                      // 空映射（非 nil）

ages["新同学"] = 30          // 增/改
v := ages["阿G"]             // 查：缺失返回零值 0
delete(ages, "阿G")          // 删：缺键不报错（幂等）
n := len(ages)               // 键值对数
```

map 是**引用类型**：传参、赋值共享同一份底层数据（哈希表）。给函数里的 map 加键，外面看得见。

## 7.2 逗号 ok：判断存在的唯一正道

```go
if age, ok := ages["阿Q"]; ok {
	fmt.Println("在:", age)
} else {
	fmt.Println("不在（age 是零值", age, "——不能拿值当存在性依据）")
}
```

缺失的键返回**值类型的零值**——`m["缺"]` 是 0、`""`、false。0 分和"没这人"是两回事，必须看 ok。计数器惯用法则反过来利用零值：

```go
counts := make(map[string]int)
for _, w := range words {
	counts[w]++    // 不用先判存在：缺键读出 0，加 1 存回
}
```

## 7.3 遍历无序 + 有序姿势

```go
for k, v := range m { }   // 顺序随机，每次运行都不同（语言故意设计）
```

需要有序输出：先取键排序再查值（12 章有一步到位的现代版）：

```go
keys := make([]string, 0, len(m))
for k := range m { keys = append(keys, k) }
sort.Strings(keys)
for _, k := range keys { fmt.Println(k, m[k]) }
```

## 7.4 nil map：读不慌，写就炸

```go
var m map[string]int
v := m["x"]        // 0：读 nil map 合法
_ = len(m)         // 0：合法
m["x"] = 1         // panic: assignment to entry in nil map！
```

声明 `var m map[K]V` 只有零值 nil，**必须 make 或字面量初始化才能写**。函数返回 map 时返回 nil 是常见事故（调用方一写就炸）。

## 7.5 set 惯用法

```go
type Set map[string]struct{}   // struct{} 零字节：值不占内存

s := Set{"go": {}, "zig": {}}
s.Add("rust")
if _, ok := s["go"]; ok { }    // 存在性
delete(s, "zig")
```

Go 没有内置 set——`map[T]struct{}` 就是 set。1.21 后追求性能/语义的可看 `unique` 包（句柄化）。

## 7.6 键的类型约束

| 键可用 | 键不可用 |
|---|---|
| 全部可比较类型：int/string/bool/指针/数组/结构体（字段全可比较）/接口 | **切片、map、函数**（不可比较） |

键是结构体时按**值相等**（字段逐一相等即同键）——`(x, y)` 坐标做键的惯例写法：

```go
grid := map[[2]int]string{{1, 2}: "起点"}
```

## 7.7 值的取舍

map 的值**不可寻址**：`m[k].Field = 1` 编译不过（值可能随 rehash 搬家，地址不保）。改结构体字段要先取副本改完放回，或**存指针** `map[K]*V`。

## 7.8 坑位清单

1. **nil map 写入 panic**：`var m map[string]int` 后就写是最常见翻车；make 一下再写。
2. **拿零值当"不存在"**：`if m[k] == 0` 分不清"值是 0"和"没有这个键"——逗号 ok。
3. **遍历顺序随机**：连着两次遍历顺序都不同，别在输出/测试里赌顺序。
4. **并发读写 map 直接 panic**（fatal error，recover 都救不回）：要并发就上锁或 `sync.Map`（18 章）。
5. **键含切片编译错**：`map[[dynamic]int]…` 之类想象出来的写法不存在；切片做键先转字符串。
6. **`m[k].Field = x` 编译不过**：值不可寻址——存 `*T` 或取改放回。
7. **1.24 起 map 换了 swiss table 内核**：性能更好，但迭代无序的语义没变。

---
