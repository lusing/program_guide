# 10 · SwiftUI 布局：栈、spacing、padding、frame、Spacer、对齐

> 示例：`examples/10_layout/main.swift`
> 实测输出见 `build/10_layout/stdout.debug.txt`

布局是 SwiftUI 里最容易「凭感觉写、然后对不上」的部分。本章不靠感觉——所有数字都是
**在本机模拟器里跑出来的真实尺寸**，你可以照着复算。

## 布局是一场「协商」

SwiftUI 的布局不是 CSS 那种层叠规则，而是一套自顶向下提议、自底向上汇报的**协商**：

1. **父视图给子视图一个尺寸提议**（proposed size）。
2. **子视图自己决定要多大**——可以照提议，也可以无视：`Text` 用自己的理想尺寸，
   `.frame(width:height:)` 直接固定，`Spacer`/`GeometryReader` 贪婪吃满提议。
3. **父视图按自己的规则（spacing / alignment）放置子视图**，再算出自己的尺寸，
   继续往上报。

理解这三步，下面每个数字都能推出来。

## headless 怎么量到真实尺寸

关键技巧：`UIHostingController` 的宿主视图 `intrinsicContentSize` **不需要挂窗口、
不需要跑 run loop** 就能算出内容的理想尺寸。示例里的量尺就是它：

```swift
func idealSize<V: View>(of view: V) -> CGSize {
    let host = UIHostingController(rootView: view)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    return host.view.intrinsicContentSize   // 内容的理想尺寸
}
```

于是布局可以像算术题一样被精确断言。下面所有数字都来自它。

## 1) VStack：高度 = 各子高 + spacing×(n−1)

```swift
VStack(spacing: 8) {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 100, height: 40)
}
```

```
spacing 0  → 100.0×80.0
spacing 8  → 100.0×88.0
spacing 20 → 100.0×100.0
ok   spacing 0：40+40 = 80
ok   spacing 8：40+8+40 = 88
ok   spacing 20：40+20+40 = 100
ok   VStack 宽 = 最宽子视图（都是 100）
```

- **高度** = 子高之和 + `spacing ×(子数−1)`。两个 40、spacing 8 → `40+8+40 = 88`。
  spacing 只加在**相邻子视图之间**，所以是 `n−1` 段，不是 `n` 段。
- **宽度** = 最宽的那个子视图（这里都是 100）。VStack 不会把窄的子视图拉宽。

## 2) HStack：宽度 = 各子宽 + spacing×(n−1)

```swift
HStack(spacing: 8) {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 100, height: 40)
}
```

```
HStack(spacing:8) 两个 100×40 → 208.0×40.0
ok   宽度 = 100+8+100 = 208
ok   高度 = 最高子视图 = 40
```

跟 VStack 正好转 90°：**主轴（水平）**累加子宽 + spacing，**交叉轴（垂直）**取最高子视图。

## 3) ZStack：尺寸 = 子视图宽、高各自的最大值

```swift
ZStack {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 60,  height: 80)
}
```

```
ZStack(100×40 叠 60×80) → 100.0×80.0
ok   宽 = max(100, 60) = 100
ok   高 = max(40, 80) = 80
```

ZStack 把子视图**叠在一起**（后写的在上层），外框尺寸 = 宽的 max × 高的 max。

## 4) padding：往外扩，宽高各 +2n

```swift
Text("A").frame(width: 100, height: 40).padding(10)
```

```
100×40 加 .padding(10) → 120.0×60.0
ok   宽 = 100 + 10×2 = 120
ok   高 = 40 + 10×2 = 60
```

`.padding(10)` 在**四边各加 10**，所以宽 `+20`、高 `+20`。padding 是「往外扩占位」，
内容本身尺寸不变。这也解释了修饰符顺序为什么重要：

```swift
Text("A").padding(10).background(.red)   // 红底盖住 padding 区域（含内边距）
Text("A").background(.red).padding(10)   // 红底只贴文字，padding 在红底之外
```

## 5) frame：固定尺寸就是「提议即结果」

```swift
Text("A").frame(width: 200, height: 200)
```

```
.frame(width:200,height:200) → 200.0×200.0
ok   固定 frame：说多大就多大
```

`.frame(width:height:)` 是最「强硬」的子视图——它直接无视上层提议，把自己固定成
指定尺寸。`frame(minWidth:idealWidth:maxWidth:)` 则给的是一个**区间**，让视图在提议
落在区间内时跟随、超出时夹紧。`.frame(maxWidth: .infinity)` 是「尽量撑满」的常用写法。

## 6) Spacer：吃满父给的提议空间

```swift
HStack {
    Text("A").frame(width: 50)
    Spacer()
    Text("B").frame(width: 50)
}.frame(width: 300)
```

```
HStack{50, Spacer, 50}.frame(width:300) → 300.0×20.33…
ok   Spacer 撑满提议宽度 300（两个 50 被推到两端）
ok   垂直方向 Spacer 同理撑满高度 300
```

`Spacer` 的理想尺寸是 0，但它**贪婪**：协商时会拿走父视图提议里的所有剩余空间。
外层被提议成宽 300，两个 Text 各占 50，`Spacer` 吃掉中间的 200，把两个 Text 顶到
两端。这就是「两端对齐」的标准写法。`VStack { Text; Spacer() }` 则把内容顶到上方。

## 7) alignment：只挪位置，不改外框尺寸

```swift
VStack(alignment: .leading) { … }   // 还有 .center / .trailing
```

```
leading/center/trailing 外框都是 100.0×88.0
ok   三种水平对齐，VStack 外框宽都 = 最宽子视图 100（对齐只挪子视图位置）
```

`alignment` 决定子视图在**交叉轴**上怎么摆（`.leading` 靠左、`.center` 居中、
`.trailing` 靠右），但**外框尺寸不变**——因为它始终由最宽子视图决定。想让某个子视图
用不同于默认的对齐，可以给它单独的 `.alignmentGuide`。

## 8) GeometryReader：占满提议，把真实尺寸交给你

```swift
GeometryReader { proxy in
    Text("\(Int(proxy.size.width))")   // proxy.size 是父给的可用空间
}.frame(width: 250, height: 250)
```

```
GeometryReader.frame(250×250) → 250.0×250.0
ok   GeometryReader 填满提议尺寸
```

`GeometryReader` 和 `Spacer` 一样**贪婪吃满提议**，但它在闭包里给你一个
`GeometryProxy`，能读到当前可用尺寸、安全区、以及在坐标空间里的位置。要做「按屏幕
宽度的百分比布局」「读取键盘/安全区 insets」时用它。

> **坑**：`GeometryReader` 会占满父给的**全部**空间，且默认从**左上角**开始排内容
> （不像 VStack 居中）。滥用它会打乱布局，通常包一层再对齐。

## 布局协商小结

```
1) 父给子一个尺寸提议（proposed size）
2) 子自己决定多大：Text 用理想尺寸、.frame 固定、Spacer/GeometryReader 吃满
3) 父按 spacing/alignment 放置子视图，并算出自己的尺寸往上报
```

上面每条数值断言，都对应这三步里的某一环。

## 坑清单

| 现象 | 原因 |
| --- | --- |
| spacing 改了高度对不上 | spacing 只加在**相邻**子视图之间，是 `n−1` 段 |
| 视图没撑满屏幕 | 默认按理想尺寸；要撑满用 `.frame(maxWidth:.infinity)` 或 `Spacer` |
| `padding` 后背景色没盖住边 | 顺序反了：应 `.padding().background()`，不是 `.background().padding()` |
| `GeometryReader` 把布局顶乱 | 它贪婪吃满且左上对齐；包一层或显式对齐 |
| 对齐改了外框却跟着变 | 对齐只挪子视图位置；外框尺寸由最大子视图决定，不该变 |
| 想按比例布局却写死像素 | 用 `GeometryReader` 读可用尺寸，或 `.frame(maxWidth:.infinity)` + 比例 |

## 小结

- 布局是「父提议 → 子定尺寸 → 父放置并上报」的协商，不是层叠规则。
- VStack/HStack：主轴累加 + `spacing×(n−1)`，交叉轴取最大。
- ZStack：宽高各取子视图最大值，后写的在上层。
- `padding(n)` 四边各加 n（宽高 `+2n`）；`.frame` 固定；`Spacer`/`GeometryReader` 贪婪吃满提议。
- `alignment` 只挪位置、不改外框；`GeometryReader` 能读到真实可用尺寸。
- `intrinsicContentSize` 让布局可以 headless 精确测量。下一章讲**列表与导航**。
