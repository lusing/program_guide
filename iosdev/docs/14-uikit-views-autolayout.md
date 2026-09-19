# 14 · UIKit 视图体系与 Auto Layout

> 示例：`examples/14_uikit_views_autolayout/main.swift`
> 实测输出见 `build/14_uikit_views_autolayout/stdout.debug.txt`

从本章进入 **UIKit 补充**（14–16）。虽然本教程以 SwiftUI 为主，但 SwiftUI 底层跑的就是
UIKit + Core Animation（第 08、13 章已经见到 `_UIHostingView`、`PlatformViewHost`）。
读懂 UIKit 的视图体系与 Auto Layout，你才能：看懂老代码、调试 SwiftUI 的布局问题、
在需要时下沉到 UIKit。本章所有 `frame` 数字都是本机 Auto Layout **真解出来**的。

## 1) 一棵 UIView 树 + 三个几何量

UIKit 的界面是一棵 `UIView` 树：每个 `UIView` 通过 `addSubview` 挂到父视图上。每个
视图有三个几何量，别搞混：

```swift
let v = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 50))
v.frame     // (10, 10, 100, 50) —— 在**父视图**坐标系里的位置+尺寸
v.bounds    // (0, 0, 100, 50)   —— 在**自己**坐标系里，origin 通常 (0,0)
v.center    // (60, 35)          —— frame 的中心点（父坐标系）
```

```
-- frame / bounds / center 的关系 --
  frame=(10.0, 10.0, 100.0, 50.0)  bounds=(0.0, 0.0, 100.0, 50.0)  center=(60.0, 35.0)
  ok   frame：在**父视图**坐标系里的位置+尺寸
  ok   bounds：在**自己**坐标系里，origin 通常是 (0,0)
  ok   center = frame 的中心：(10+100/2, 10+50/2)=(60,35)
  ok   改 center → frame.origin 跟着挪（size 不变）
  ok   bounds.size 不受 center 影响
```

- **`frame`**：父坐标系里的矩形。你摆位置时最常改它。
- **`bounds`**：自己坐标系里的矩形，`origin` 一般是 `(0,0)`。改 `bounds.origin` 会
  **滚动**内容（`UIScrollView` 就是靠改 `bounds.origin` 实现滚动的）。
- **`center`**：`frame` 的中心。改 `center` 只挪位置、不改大小——做拖动动画时改
  `center` 比改 `frame` 更直接。

三者关系：`frame` 由 `bounds.size` + `center`（+ `transform`）推导。所以改 `center`，
`frame.origin` 跟着动，`bounds` 不变。

## 2) 视图层级

```swift
let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
root.addSubview(childA)     // tag=1
root.addSubview(childB)     // tag=2
root.subviews               // [childA, childB]，按添加顺序
childA.superview            // === root
root.viewWithTag(2)         // === childB
childB.removeFromSuperview()
```

```
-- 视图层级 --
  ok   root 有两个子视图
  ok   子视图的 superview 指回 root
  ok   subviews 按添加顺序排列
  ok   viewWithTag 能按 tag 找回子视图
  ok   removeFromSuperview 后少一个
  ok   移除后 superview 变 nil
```

- `subviews` 按**添加顺序**排列，后加的在上层（绘制在顶层）。想调整层叠用
  `bringSubviewToFront` / `insertSubview(_:at:)`。
- `superview` 是**弱引用**（避免父子循环引用）。`removeFromSuperview` 后变 `nil`。
- `viewWithTag(_:)` 递归找子视图——调试有用，但生产代码别拿 tag 当主要手段（易冲突）。

## 3) Auto Layout：声明约束，系统解方程

手动设 `frame` 在屏幕尺寸多变（各种 iPhone、横竖屏、分屏）时是噩梦。**Auto Layout**
让你声明「视图之间的约束关系」，系统解一组线性方程，算出每个视图的 `frame`。

用 **anchor** 写约束最直观：

```swift
let box = UIView()
box.translatesAutoresizingMaskIntoConstraints = false   // 关键：关掉旧的 autoresizing 转换
container.addSubview(box)
NSLayoutConstraint.activate([
    box.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
    box.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
    box.widthAnchor.constraint(equalToConstant: 100),
    box.heightAnchor.constraint(equalToConstant: 50),
])
container.layoutIfNeeded()
box.frame     // (20, 30, 100, 50)
```

```
-- Auto Layout：pin 到父视图四边（带 inset）--
  解出的 box.frame = (20.0, 30.0, 100.0, 50.0)
  ok   leading+20、top+30、宽100、高50 → frame (20,30,100,50)
  ok   用 Auto Layout 时该标志必须为 false
```

> **头号坑**：用 Auto Layout 必须设 `translatesAutoresizingMaskIntoConstraints = false`。
> 否则 UIKit 会把你手动设的 `frame` 自动转成一组 autoresizing 约束，跟你的 anchor
> 约束**打架**，产生冲突（`NSLog` 到 stderr）。代码里 `addSubview` 之后第一件事就是关它。

### 居中

```swift
NSLayoutConstraint.activate([
    centered.centerXAnchor.constraint(equalTo: container.centerXAnchor),
    centered.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    centered.widthAnchor.constraint(equalToConstant: 40),
    centered.heightAnchor.constraint(equalToConstant: 40),
])
// 容器 300×400，居中 40×40 → frame (130, 180, 40, 40)
```

```
-- Auto Layout：居中 --
  居中的 40×40 在 300×400 里 → (130.0, 180.0, 40.0, 40.0)
  ok   centerX=150、centerY=200 → origin (130,180)
```

算得出来：容器中心 `(150, 200)`，视图 40×40，所以 origin = `(150−20, 200−20) = (130,180)`。

### 相对约束：等宽、比例、关系

约束不只是「等于常数」，还能是「等于另一个视图的某个属性 × 系数 + 常数」：

```swift
NSLayoutConstraint.activate([
    left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
    left.widthAnchor.constraint(equalToConstant: 100),
    left.heightAnchor.constraint(equalToConstant: 30),
    left.topAnchor.constraint(equalTo: container.topAnchor, constant: 200),
    right.leadingAnchor.constraint(equalTo: left.trailingAnchor, constant: 8),  // 紧跟 left 之后 8pt
    right.widthAnchor.constraint(equalTo: left.widthAnchor, multiplier: 0.5),   // 宽度是 left 的一半
    right.heightAnchor.constraint(equalTo: left.heightAnchor),                  // 高度相等
    right.centerYAnchor.constraint(equalTo: left.centerYAnchor),
])
```

```
-- Auto Layout：相对约束（等宽 / 比例 / 关系）--
  left=(10.0, 200.0, 100.0, 30.0)  right=(118.0, 200.0, 50.0, 30.0)
  ok   left 宽 100
  ok   right 宽 = left 的一半 = 50
  ok   right.leading = left.trailing(110) + 8 = 118
  ok   right 高 = left 高（equalTo 关系）
```

`left` 宽 100、leading 10 → trailing 在 110；`right` leading = 110+8 = 118，宽 = 100×0.5
= 50。这就是「响应式布局」的基础：一个视图的尺寸/位置**依赖**另一个，屏幕变大变小时
关系不变。约束关系有 `equalTo` / `greaterThanOrEqualTo` / `lessThanOrEqualTo` 三种。

## 4) 布局循环：延迟的，不是立即的

Auto Layout 和 `layoutSubviews` 都是**延迟**执行的。理解这个循环能省掉大量困惑：

```swift
counting.setNeedsLayout()   // 只「标记」需要布局，不当场执行
counting.layoutIfNeeded()   // 如果已被标记，现在才真正 layoutSubviews
```

```
-- 布局循环：setNeedsLayout → layoutSubviews --
  layoutSubviews 调用次数：标记前=0 标记后=0 layoutIfNeeded 后=1
  ok   layoutIfNeeded 之后 layoutSubviews 至少被调了一次
  ok   setNeedsLayout 只标记，不当场触发 layoutSubviews
```

- **`setNeedsLayout()`**：打个「脏」标记。真正布局推迟到**下一个布局周期**（run loop
  的一次 pass）。连续调多次只标记一次，避免重复布局。
- **`layoutIfNeeded()`**：如果当前有「脏」标记，**立即**同步布局（否则什么都不做）。
  想马上读到解出来的 `frame`（比如做动画、或本示例的自测），就调它。
- **`layoutSubviews()`**：UIKit 在布局周期里调它，你在这里摆子视图（自定义布局）。
- 约束变了、`frame` 变了、`addSubview` 了，UIKit 都会自动 `setNeedsLayout`。

对应到约束还有 `setNeedsUpdateConstraints()` / `updateConstraintsIfNeeded()`。

## 5) intrinsicContentSize：控件的固有尺寸

有些控件（`UILabel`、`UIButton`、`UIImageView`）能根据内容算出自己「天生多大」，这就是
`intrinsicContentSize`。它**参与** Auto Layout：你只约束位置、不约束宽高，控件就用固有
尺寸定型。

```swift
let label = UILabel(); label.text = "Hello"
label.intrinsicContentSize        // (39.0, 20.33…) —— 由文本+字体算出
// 只约束 leading + top，不约束宽高：
NSLayoutConstraint.activate([
    label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
    label.topAnchor.constraint(equalTo: host.topAnchor),
])
host.layoutIfNeeded()
label.frame.width                 // == intrinsicContentSize.width
```

```
-- intrinsicContentSize：固有尺寸 --
  UILabel("Hello").intrinsicContentSize = (39.0, 20.333333333333332)
  ok   UILabel 有正的固有尺寸（由文本+字体算出）
  ok   没约束宽高时，label 用 intrinsicContentSize 定宽
```

> 这正是 SwiftUI 布局协商（第 10 章）里「子视图自己决定多大」的底层机制之一。
> 固有尺寸有**内容拥抱优先级**（content hugging，抗变大）和**抗压缩优先级**
> （compression resistance，抗变小），当固有尺寸和别的约束冲突时，靠这两个优先级裁决。

## 6) safeAreaInsets：安全区

刘海、灵动岛、Home 指示条会侵占屏幕边缘。**安全区**是不被这些侵占的区域，
`safeAreaInsets` 告诉你四边各要让开多少：

```
-- safeAreaInsets --
  未挂窗口时 safeAreaInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
  ok   没挂进窗口/屏幕时，安全区 inset 是 0（真机上有刘海才非零）
```

headless（没挂进窗口/屏幕）时 inset 是 0；真机上带刘海的 iPhone 顶部会有非零 inset。
布局时用 `safeAreaLayoutGuide` 而不是硬编码，内容才不会被刘海遮住。SwiftUI 默认就
尊重安全区（`.ignoresSafeArea()` 才忽略）。

## 心智模型小结

```
frame 在父坐标系；bounds 在自己坐标系；center 是 frame 中心
Auto Layout = 声明约束、系统解方程算 frame；用 anchor 写约束最直观
用 Auto Layout 必须 translatesAutoresizingMaskIntoConstraints = false
布局是延迟的：setNeedsLayout 标记，下一次 layout 周期才 layoutSubviews
控件的 intrinsicContentSize 参与约束（label 不写宽高也能定尺寸）
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 约束全不生效 / frame 是 0 | 忘了 `translatesAutoresizingMaskIntoConstraints = false` |
| 控制台刷 "Unable to simultaneously satisfy constraints" | 约束互相冲突（且会打到 stderr）；检查是否多约束了宽高、优先级 |
| 改了约束 frame 没变 | 没 `layoutIfNeeded()`；布局是延迟的 |
| `setNeedsLayout` 后立刻读 frame 还是旧值 | 它只标记；要立即读得调 `layoutIfNeeded` |
| label 被压扁/截断 | 抗压缩优先级不够，被别的约束挤小；调 `contentCompressionResistancePriority` |
| 内容被刘海遮住 | 用了 `layoutMarginsGuide`/硬编码而非 `safeAreaLayoutGuide` |
| `bounds.origin` 改了画面「滚动」了 | `bounds.origin` 就是滚动偏移（UIScrollView 的原理） |

## 小结

- UIView 树 + `frame`（父坐标）/`bounds`（自坐标）/`center`（frame 中心）三个几何量。
- Auto Layout 声明约束、系统解方程算 frame；用 anchor 写；**必须**关掉
  `translatesAutoresizingMaskIntoConstraints`，且不要制造冲突约束。
- 布局**延迟**：`setNeedsLayout` 标记，`layoutIfNeeded` 立即解，`layoutSubviews` 摆子视图。
- `intrinsicContentSize` 让控件不写宽高也能定型，是 SwiftUI 布局协商的底层之一。
- `safeAreaInsets` 决定内容要避开的边缘。下一章讲 **UIKit 控件与列表**
  （`UITableView` / `UICollectionView` / diffable data source）。
