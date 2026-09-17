# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 for：唯一的循环，四种形态

```go
for i := 0; i < 3; i++ { }  // ① 经典三段式
for n < 3 { n++ }           // ② 只有条件（= 其他语言的 while）
for i := range 3 { }        // ③ range 整数（1.22+）：i = 0,1,2
for { break }               // ④ 无限循环（= while(true)）
```

Go 没有 while、没有 do-while——`for` 全包了。新代码里 ②③ 是主力，① 只在需要非 0 起步/步进时出现。

## 4.2 range 家族

```go
for i, v := range slice { }    // 下标 + 值
for k, v := range amap { }     // 键 + 值；顺序故意随机！
for k := range amap { }        // 只要键
for i, r := range "你好" { }   // 字符串：按 rune 迭代，i 是字节下标
for i, v := range slices.Backward(s) { } // 反向（13 章迭代器）
for ch := range ch { }         // channel：收到 close 为止（17 章）
```

两把最常见的钥匙：**不需要的那半用 `_` 丢掉**；**map 遍历无序是语言故意设计**（逼你别依赖顺序，顺带哈希实现可以随机化）。

## 4.3 if：条件不用括号，作用域精确到分支

```go
if q, err := Div(7, 2); err != nil {   // 带初始化语句
	fmt.Println("出错:", err)           // q、err 只活在 if/else 链里
} else {
	fmt.Println("结果:", q)
}
```

"声明 + 判断 + 使用"圈在一个 if 里，是 Go 消灭"半途变量"的招牌手法，错误处理里天天用。

## 4.4 switch：默认不穿透

```go
switch lang := "go"; lang {   // 带初始化
case "go", "zig":             // 一个 case 多个值
	fmt.Println("系统语言")
default:
	fmt.Println("其他")
}

switch {                      // 无表达式：case 写条件（if-else 链的优雅版）
case n%15 == 0: return "FizzBuzz"
case n%3 == 0:  return "Fizz"
}
```

C 的 switch 不 break 就穿透是万恶之源，Go 反转默认：**case 结束即跳出**，要穿透必须显式写 `fallthrough`（还不判断下个 case 的条件——基本没人用）。

类型 switch 给 `any` 分流：

```go
switch x := v.(type) {
case nil:      ...
case int:      fmt.Println(x + 1)   // 这个分支里 x 自动是 int
case string:   fmt.Println(len(x))  // 这里 x 是 string
default:       fmt.Printf("%T", x)
}
```

## 4.5 标签：break 2 的替代品

```go
outer:
	for r, row := range grid {
		for c, v := range row {
			if v == target {
				row, col = r, c
				break outer       // 一步跳出双层
			}
		}
	}
```

Go 没有 `break 2`，标签（label）顶上。标签还能配 `continue`（跳到外层循环下一轮）和 goto（别用）。注意：**声明了不用的标签是编译错**。

## 4.6 && || 与短路

和 C 一致：短路求值。Go 增补位运算 `& | ^ << >>`，`^` 兼任异或和按位取反（一元）。

## 4.7 坑位清单

1. **map 遍历顺序随机**：两次运行顺序都不同——需要有序输出先 `slices.Sorted(maps.Keys(m))`（12 章）。
2. **range 字符串的下标是字节位**：`for i, r := range "你好"` 的 i 是 0、3——拿"第几个字符"要自己数或转 []rune。
3. **range 的 v 是副本**：`for _, v := range items { v.X = 1 }` 改不动原切片——要改就 `items[i].X = 1` 或 range 下标。
4. **fallthrough 不看条件**：穿进下一个 case 时条件根本不评估，`case 99` 也照进——99% 是 bug，剩下 1% 也建议重写。
5. **标签必须被引用**：`outer:` 写了没人 break/continue 它，编译错"label defined and not used"。

---
