# 06 · 数组、切片与字符串

> 对应示例：`examples/06_slices/`

## 6.1 数组：值类型，基本只当切片的底座

```go
arr := [3]int{1, 2, 3}     // 长度是类型的一部分：[3]int ≠ [4]int
two := arr
two[0] = 99
fmt.Println(arr, two)      // [1 2 3] [99 2 3]——赋值是整份拷贝
```

数组是**值**：赋值、传参全量复制。真实代码里数组几乎只出现在 `[...]string{...}`（固定字面量）和底层缓冲；**动态长度一律用切片**。

## 6.2 切片：(ptr, len, cap) 三元组

```go
sl := []int{1, 2, 3, 4}    // 指向底层数组的窗口
len(sl)                    // 4：当前元素数
cap(sl)                    // 4：从头到底层数组末尾的容量
sub := sl[:2]              // 视图！不复制，共享底层数组
```

切片是底层数组的**窗口**：赋值只拷三元组，数据不拷。这是理解后面所有坑的钥匙。

## 6.3 make 与 append

```go
s := make([]int, 0, 16)    // len=0 cap=16：预分配，避免反复搬家
var s2 []int               // nil 切片：len=0，能直接 append
s2 = append(s2, 1)         // 容量不够时：分配新数组（约 2 倍扩容）+ 拷贝
```

**扩容会搬家**——旧切片的元素地址、迭代器全部作废。已知规模就 `make(0, n)` 一步到位（示例 06 逐条打印了 len/cap 的变化）。

## 6.4 共享底层数组：本世纪的经典坑

```go
a := []int{1, 2, 3, 4}
b := a[:2]
b[0] = 99                  // a 也变成 [99 2 3 4]——同一块内存

c := append(a[:2], 500)    // 更阴：a[:2] 的 cap=2？不，cap 还是 4-0=4
                          // 容量够 → 原地写 → a[2] 被覆盖成 500！
```

`append` 到底"原地续写"还是"搬家另起"取决于剩余容量——**调用方永远不该假设 append 不动原数据**。防御姿势：

```go
view := full[1:3:3]        // 三下标 [low:high:max]：cap 也限死 = 3-1 = 2
safe := append(view, 500)  // cap 不够 → 必然搬家，full 安全
dst := make([]T, len(src)) // 或者干脆 copy
copy(dst, src)
```

## 6.5 nil 与空切片

```go
var nilSlice []int         // nil
empty := []int{}           // 空，非 nil
len(nilSlice) == len(empty) == 0     // 用起来没区别
nilSlice == nil   // true
empty == nil      // false
```

**当"空"用，不判 nil**：`len(s) == 0` 才是正道。JSON 序列化时两者有别（nil → `null`，空 → `[]`），21 章再见到。

## 6.6 字符串：只读的字节切片

```go
hello := "你好 Go"
len(hello)                       // 8：字节数
utf8.RuneCountInString(hello)    // 5：字符数
hello[0]                         // 0xe4：首字节，不是'你'
[]rune(hello)[0]                 // 20320（'你'的码点）：按字符解码（复制+转换）
for i, r := range hello { }      // rune 迭代，i 跳字节

bs := []byte(hello)   // string → []byte：复制（可修改的副本）
string(bs)            // []byte → string：再复制
rs := []rune(hello)   // string → []rune：解码复制
```

字符串**不可变**：改它必须先转 `[]byte`。`string(bs)` 在 map 键、比较场景会做零拷贝优化，但语义上就是复制。**中文字符串按字符处理先 `[]rune`**——按字节切片切到汉字中间会得到乱码。

## 6.7 常用操作速查

| 需求 | 写法 |
|---|---|
| 追加 | `append(s, v)` / `append(s, others...)` |
| 插入 | `slices.Insert(s, i, v)`（12 章） |
| 删除第 i 个 | `s = append(s[:i], s[i+1:]...)`（会移动） |
| 拷贝 | `copy(dst, src)`（按短的来） |
| 克隆 | `slices.Clone(s)` |
| 清空 | `s = s[:0]`（复用底层数组）或 `clear(s)` |
| 比较 | `slices.Equal(a, b)` |

## 6.8 坑位清单

1. **append 可能覆盖兄弟切片**：`append(a[:2], x)` 在容量富余时改写 a[2]——需要隔离就三下标 `a[low:high:max]`。
2. **扩容后旧指针失效**：拿了 `&s[i]` 再 append，指针指向旧数组——缓存下标别缓存指针。
3. **range 拿到的是副本**：改循环变量改不到原切片（04 章坑位同款）。
4. **`s[i:j]` 越界的判断是 j ≤ cap**：切片表达式允许 j 到 cap 而不是 len——`a[:cap(a)]` 合法但后半是垃圾值。
5. **大字符串反复切片**：`s[100:]` 仍引用整个原串，内存不放——要释放就 `string(s[100:])` 强制复制。
6. **中文字符串 len 是字节**：显示宽度、字符数用 `utf8.RuneCountInString`；按字截断先 `[]rune`。

---
