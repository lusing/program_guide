# 09 · 布局：autoresizingMask、Auto Layout、StackView、ScrollView

> 示例：`examples/09_layout/main.swift`
> 实测输出见 `build/09_layout/stdout.clt.txt`

macOS 上有**两套并存**的布局系统。新代码一律 Auto Layout，
但你读老代码、读 XIB、调系统控件时还是会碰到老的 autoresizingMask。

## 1) 视图树与坐标系

```swift
let root = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
let child = NSView(frame: NSRect(x: 20, y: 30, width: 40, height: 40))
root.addSubview(child)
root.convert(NSPoint(x: 0, y: 0), from: child)   // (20, 30)
```

- `subviews` 的顺序 = 添加顺序 = 绘制顺序（后面的盖在上面）
- `isFlipped` 可以翻转某个子树的坐标系（只影响自己和后代）
- **`NSView.tag` 在 AppKit 里是只读的**（`UIView.tag` 可以写）

```
  ok   isFlipped 可以重写
  ok   默认不翻转
  ok   identifier 用来给视图做标记
  ok   NSView.tag 没有设置过时是 -1
```

> **坑**：从 iOS 转过来的人会本能地写 `view.tag = 7`。
> AppKit 里编译不过。用 `identifier`（`NSUserInterfaceItemIdentifier`）代替，
> 或者自己存引用。

## 2) autoresizingMask（老式）

规则式布局：声明「父视图变宽时我跟着变宽」。

```swift
grow.autoresizingMask = [.width, .height]   // 宽高跟着父视图变
parent.setFrameSize(NSSize(width: 400, height: 200))
```

实测：

```
  .width/.height 之后 = (10.0, 10.0, 250.0, 120.0)
  ok   父视图宽 +200，子视图宽也 +200（实际 250.0）
  ok   父视图高 +100，子视图高也 +100（实际 120.0）
  ok   左边距保持不动
  .minXMargin 之后 = (350.0, 10.0, 30.0, 20.0)
  ok   右边距保持不变，左边距被拉开（实际 350.0）
  ok   宽度不变
```

六个位：`.minXMargin` `.width` `.maxXMargin` `.minYMargin` `.height` `.maxYMargin`。
**可变的那一边**才写进去 —— 想让右边距固定，就让左边距可变（`.minXMargin`）。

它表达不了「两个视图间距固定 8」这类关系，所以被 Auto Layout 取代。
但 XIB 里 `autoresizingMask` 字段还在，而且和系统控件的默认行为有关。

## 3) Auto Layout

```swift
let box = NSView()
box.translatesAutoresizingMaskIntoConstraints = false      // ← 必须
container.addSubview(box)
NSLayoutConstraint.activate([
    box.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
    box.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
    box.widthAnchor.constraint(equalToConstant: 100),
    box.heightAnchor.constraint(equalToConstant: 40),
])
container.layoutSubtreeIfNeeded()      // 立刻求解（窗口里由 run loop 自动做）
```

> **坑**：**必须**写 `translatesAutoresizingMaskIntoConstraints = false`。
> 忘了它，AppKit 会把 frame 变成一堆隐式约束和你的手写约束打架，
> 报错信息（`Unable to simultaneously satisfy constraints`）还特别难懂。
>
> **坑**：`top` 约束的语义是「离父视图**顶部** 30」。
> AppKit 原点在左下，父视图高 200、子视图高 40 → **y = 200 - 30 - 40 = 130**。
> 从 UIKit 转过来的人会以为是 30。

实测：

```
  解出的 frame = (20.0, 130.0, 100.0, 40.0)
  ok   leading 20（实际 20.0）
  ok   尺寸来自宽高约束
  ok   top 30 换算成 y = 130（实际 130.0）
  ok   位置约束挂在共同祖先上（实际 2）
  ok   尺寸约束挂在视图自己身上（实际 2）
  ok   约束足够，没有歧义
```

### 约束挂在哪

> **坑**：约束**不是**全挂在父视图上 —— **挂给两个视图的共同祖先**。
> - `box.leading == container.leading` → 挂 `container`
> - `box.width == 100`（只涉及 box 自己）→ 挂 `box`

所以 `container.constraints.count` 是 2 不是 4。
用 `NSLayoutConstraint.activate([...])` 就不用自己算挂给谁了 —— 系统帮你挂。

### 歧义检查

```swift
container.hasAmbiguousLayout     // false = 约束够
```

`true` 表示约束不足以确定唯一布局（比如只钉了左边没给宽也没给右边）。
调试神器：

```swift
container.exerciseAmbiguityInLayout()   // 让它左右乱跳，肉眼看出哪里没定住
```

### 优先级与固有尺寸

```swift
NSLayoutConstraint.activate([
    box.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),   // 至少 80
])
label.setContentHuggingPriority(.defaultHigh, for: .horizontal)     // 尽量不被拉宽
label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
```

- **Content Hugging**：抗拉伸（我不想要更大）
- **Compression Resistance**：抗压缩（我不想要更小）

实测：

```
  label intrinsic = (31.0, 16.0)  fitting = (35.0, 16.0)
  ok   标签有固有宽度
  ok   标签有固有高度
  ok   fittingSize 不小于固有尺寸
  只钉左边的标签 = (3.0, 92.0, 17.0, 16.0)
  ok   没有宽度约束时，宽度由固有尺寸决定
```

`intrinsicContentSize` 是「我天生多大」，`fittingSize` 是「在当前约束下我多大」。
自定义 view 要重写 `intrinsicContentSize`，改了之后调 `invalidateIntrinsicContentSize()`。

## 4) NSStackView

AppKit 的「线性布局容器」，比手写一堆约束省事得多：

```swift
let stack = NSStackView(views: [label, button])
stack.orientation = .vertical
stack.spacing = 8
stack.alignment = .leading
stack.distribution = .fill
```

实测：

```
  vertical fitting = (40.0, 40.0)
  ok   装了两个视图
  ok   方向是竖向
  ok   间距 8
  horizontal fitting = (88.0, 16.0)
  ok   横向排列时更宽（实际 88.0 > 40.0）
  ok   横向排列时更矮（实际 16.0 < 40.0）
  ok   addView(_:in:) 能动态加视图
  ok   removeView 能删掉视图
```

`distribution` 选项：`fill` / `fillEqually` / `fillProportionally` /
`equalSpacing` / `equalCentering` / `gravityAreas`。

**macOS 上做表单、工具栏、设置面板，优先用 NSStackView。**
除非需要非常精确的约束关系，否则别手写那一堆。

## 5) NSScrollView

结构比想象的多一层：

```
NSScrollView
 └── NSClipView (contentView)          ← 裁剪 + 滚动
      └── documentView                 ← 真正的内容（可以很大）
```

```swift
let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
scroll.documentView = bigView          // bigView 是 200x600
scroll.hasVerticalScroller = true
```

实测：

```
  documentVisibleRect = (0.0, 0.0, 200.0, 120.0)
  contentSize = (200.0, 120.0)
  ok   文档视图装在 clip view（contentView）里
  ok   文档视图尺寸保持 200x600
  ok   contentSize 是可见区尺寸，小于文档总高
  ok   可见区域高度是滚动视图的高度
  ok   开了竖向滚动条
```

> **坑**：`scrollView.contentSize` 是**可见区（clip view）的尺寸**，不是文档总尺寸。
> 要看文档多大，读 `documentView.frame.size`。
>
> **坑**：要滚动，`documentView` 必须比 clip view 大，
> 而且（用 Auto Layout 时）要给 documentView 加**四边**约束 ——
> 加了 leading/top/width/height 就滚不动了（尺寸被钉死）。

## 6) 坑清单

| 现象 | 原因 |
| --- | --- |
| `Unable to simultaneously satisfy constraints` | 忘了 `translatesAutoresizingMaskIntoConstraints = false` |
| 子视图 y 坐标和自己算的不一样 | `top` 约束是离**父视图顶部**，AppKit 原点在左下 |
| 视图尺寸是 0 | 约束不够（hasAmbiguousLayout == true） |
| `contentSize` 比预期小 | 它是可见区尺寸，不是文档尺寸 |
| ScrollView 滚不动 | documentView 没比 clip view 大，或四边约束没给全 |
| `view.tag = 7` 编译不过 | AppKit 的 tag 只读，用 `identifier` |
| 约束改了但界面没变 | 需要 `layoutSubtreeIfNeeded()` 或等下一个 run loop |

## 小结

- Auto Layout 要先关 `translatesAutoresizingMaskIntoConstraints`。
- `top` 是离父视图顶部（原点在左下），y 要反算。
- 约束挂在**共同祖先**上；用 `NSLayoutConstraint.activate` 让系统帮你挂。
- 线性布局优先 `NSStackView`。
- `NSScrollView` 中间有一层 `NSClipView`；`contentSize` 是可见区尺寸。
