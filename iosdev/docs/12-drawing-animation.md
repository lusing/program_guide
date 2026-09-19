# 12 · SwiftUI 绘制与动画：Shape / Path / Canvas / animatableData

> 示例：`examples/12_drawing_animation/main.swift`
> 实测输出见 `build/12_drawing_animation/stdout.debug.txt`

SwiftUI 的矢量绘制建立在两个类型上：

- **`Path`**：一段矢量轮廓（move / addLine / addRect / addArc / close…），可以量
  `boundingRect`、`isEmpty`，可以 trim、offset、套变换。
- **`Shape`**：一个「能在给定 rect 里产出 `Path`」的东西。`Rectangle`、`Circle` 是
  内置的，你也可以自定义。

因为内置和自定义 `Shape` 都提供 `.path(in:)`，绘制的**几何**可以 headless 精确断言——
本章所有数字都是本机跑出来的。

## 1) Path：从空到有

```swift
var empty = Path()
empty.isEmpty            // true
empty.boundingRect       // (inf, inf, 0, 0) —— 一个「无效」矩形

var line = Path()
line.move(to: CGPoint(x: 0, y: 0))
line.addLine(to: CGPoint(x: 50, y: 50))
line.boundingRect        // (0, 0, 50, 50)

var rect = Path()
rect.addRect(CGRect(x: 10, y: 10, width: 20, height: 30))
rect.boundingRect        // (10, 10, 20, 30)
```

```
-- Path：从空到有 --
  空 Path：isEmpty=true，boundingRect=(inf, inf, 0.0, 0.0)
  ok   刚建的 Path 是空的
  ok   空 Path 的 boundingRect 宽高为 0
  一条 (0,0)→(50,50) 的线：boundingRect=(0.0, 0.0, 50.0, 50.0)
  ok   boundingRect 正好框住这条线：0,0,50,50
  ok   addRect 的 boundingRect 就是那个矩形
```

> **坑**：空 `Path` 的 `boundingRect` 是 `(inf, inf, 0, 0)`——`minX/minY` 是 `inf`。
> 别拿它当尺寸用；先判 `isEmpty`。

`Path` 是**值类型**（struct），`move`/`addLine` 这些是 mutating 方法，改的是自己。

## 2) Path 变换：offsetBy / trimmedPath

```swift
let moved = rect.offsetBy(dx: 5, dy: 5)          // 整体平移，返回新 Path
let half  = Circle().path(in: box).trimmedPath(from: 0, to: 0.5)   // 取轮廓的一段
```

```
-- Path 变换：offsetBy / trimmedPath --
  addRect 后 offsetBy(5,5) → (15.0, 15.0, 20.0, 30.0)
  ok   offsetBy 把 boundingRect 平移 (10,10)→(15,15)
  Circle 取前一半 trim(0→0.5) → (0.0, 50.0, 100.0, 50.0)
  ok   trim 前半圈得到下半圆：boundingRect 0,50,100,50
```

- `offsetBy(dx:dy:)` / `applying(CGAffineTransform)` 返回**变换后的新 Path**。
- `trimmedPath(from:to:)` 取轮廓的 `[from, to]` 段（0…1 的归一化弧长）。一个整圆
  `trim(0, 0.5)` 得到**半圈**——boundingRect 从 `0,0,100,100` 变成 `0,50,100,50`
  （只剩下半圆）。这正是「画进度环」「描边动画」的基础：`trim` 的终点从 0 动画到 1。

## 3) 内置 Shape：path(in:) 的几何

```swift
Rectangle().path(in: box).boundingRect          // (0,0,100,100) 填满
Circle().path(in: box).boundingRect             // (0,0,100,100) 正方形里内切
Ellipse().path(in: 100×50).boundingRect         // (0,0,100,50)  填满非正方形
Capsule().path(in: 100×40).boundingRect         // (0,0,100,40)  胶囊
RoundedRectangle(cornerRadius: 10).path(in: box) // (0,0,100,100)
```

```
-- 内置 Shape --
  ok   Rectangle 填满整个 rect
  ok   Circle 在正方形里内切，boundingRect 仍是 100×100
  Ellipse in 100×50 → (0.0, 0.0, 100.0, 50.0)
  ok   Ellipse 填满给定的非正方形 rect
  ok   Capsule（两端半圆的胶囊）填满 rect
```

要点：`Shape` 的 `path(in rect:)` 拿到的是**上层布局给的 rect**（第 10 章的「提议」），
在这个 rect 里画自己。`Circle` 在正方形里内切，在非正方形 rect 里其实会变成 `Ellipse`
的行为——想要正圆，先 `.frame(width:height:)` 成正方形，或用 `.aspectRatio(1, contentMode: .fit)`。

## 4) 自定义 Shape

自定义 `Shape` 只需实现 `path(in:)`：

```swift
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))     // 上
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))  // 右
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))  // 下
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))  // 左
        p.closeSubpath()
        return p
    }
}
```

```
-- 自定义 Shape --
  Diamond in 100×100 → boundingRect (0.0, 0.0, 100.0, 100.0)
  ok   菱形四个顶点在四条边中点，boundingRect 仍是整个 rect
  ok   自定义 Shape 产出了非空 Path
```

菱形四个顶点落在 rect 四条边的中点，所以 boundingRect 仍是整个 rect。自定义 Shape
一旦实现，就能像内置的一样 `.fill()`、`.stroke()`、参与动画。

## 5) animatableData：形状动画的每一帧

**动画的本质**：SwiftUI 对一个「可插值的值」在时间上取样，逐帧重算 `body`。对 `Shape`
来说，这个可插值的值就是 `animatableData`（一个 `VectorArithmetic`）。你只要暴露它，
SwiftUI 就能在起始值和结束值之间逐帧插值，每帧重算 `path(in:)`。

```swift
struct ProgressBar: Shape {
    var progress: CGFloat                 // 0...1
    var animatableData: CGFloat {         // 告诉 SwiftUI：动画时插值这个
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY,
                    width: rect.width * progress, height: rect.height))
    }
}
```

我们直接改 `animatableData`，等价于「跳到动画的某一帧」：

```
-- animatableData：动画就是逐帧改这个值 --
  ok   progress=0：宽度 0（动画起始帧）
  ok   animatableData=0.5：宽度 50（中间帧）
  ok   animatableData=1：宽度 100（结束帧）
```

`animatableData` 从 0 → 0.5 → 1，`path(in:)` 产出的宽度就是 0 → 50 → 100。真实动画里
SwiftUI 会在几十帧内平滑地扫过这个区间。要做「进度环」，就把 `progress` 换成 `trim`
的终点；要做「形变」，就让 `animatableData` 是一个 `AnimatablePair`（多个可插值分量）。

> **不暴露 animatableData 会怎样？** Shape 仍然能画，但改 `progress` 时不会平滑过渡，
> 而是「啪」地跳变。`animatableData` 是形状动画能「动起来」的关键。

## 6) fill / stroke / Canvas

```swift
Circle().fill(Color.blue)                       // 声明式：填充
Circle().stroke(Color.red, lineWidth: 2)        // 声明式：描边
Canvas { ctx, size in                           // 即时模式：自己拿 GraphicsContext 画
    ctx.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(.green))
}
```

```
-- fill / stroke / Canvas 是视图 --
  ok   fill 返回一个可绘制视图
  ok   stroke 返回一个可绘制视图
  ok   Canvas 是即时模式绘制视图（拿到 GraphicsContext 自己画）
```

两种绘制哲学：

- **`Shape` + `fill`/`stroke`（声明式）**：你描述「形状是什么」，SwiftUI 负责画、负责
  动画。适合规则图形、需要动画的图形。
- **`Canvas`（即时模式）**：闭包里给你一个 `GraphicsContext`，你**命令式**地一笔笔画
  （类似 UIKit 的 `draw(_:)` / Core Graphics）。适合大量动态图元（粒子、图表、成千上
  万个点）——比等量的 Shape 视图树高效得多，但动画要自己驱动。

## 7) Animation / Transition 是值

```swift
let anim = Animation.easeInOut(duration: 0.3)   // 曲线 + 时长，是个值
Text("x").animation(anim, value: someValue)      // someValue 变化时用 anim 过渡
let trans = AnyTransition.opacity                // 视图插入/移除的过渡
```

```
-- Animation / Transition 是值，可组合 --
  Animation.easeInOut 类型 = Animation
  ok   Animation 是一个值（曲线 + 时长）
  ok   .animation 是包一层的修饰符
  ok   AnyTransition 描述插入/移除的过渡
```

- **`Animation`** 描述「怎么变」（曲线、时长、延迟、弹簧）。它是**值**，可组合
  （`.delay()`、`.repeatForever()`、`.speed()`）。
- **`.animation(_:value:)`**：当 `value` 变化时，用指定动画过渡这个视图的可动画属性。
  这是「隐式动画」。
- **`withAnimation { state = newValue }`**：显式动画——把状态变更包进去，这次变更引发的
  所有视图变化都带动画。
- **`AnyTransition`**：视图**出现/消失**时的过渡（`.opacity`、`.slide`、`.scale`、
  `.move(edge:)`，可 `.combined(with:)`）。配合 `if`/`ForEach` 的增删使用。

> headless 边界：`Animation`/`Transition` 的**值与类型**可以断言，但真实的**时间曲线
> 逐帧调度**需要 run loop 和显示刷新，本示例不测——那要打包成真 App 跑（第 20 章）。
> 我们用 `animatableData` 直接「跳帧」验证了形状动画的每一帧几何，这是确定性最强的部分。

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 空 Path 的 boundingRect 是 inf | 空 Path 的 boundingRect 无效；先判 `isEmpty` |
| Circle 画成了椭圆 | 给的 rect 不是正方形；用 `.frame` 或 `.aspectRatio(1,.fit)` |
| 改了 progress 却「啪」地跳变，不平滑 | Shape 没暴露 `animatableData` |
| 描边进度环不动 | 用 `trim(from:to:)` + 对 `to` 做动画，别整圈重画 |
| 大量图元卡顿 | 用 `Canvas` 即时模式，别建等量的 Shape 视图树 |
| `.animation()` 无效果 | 用了不带 `value:` 的老写法，或状态变化没被观察到 |

## 小结

- `Path` 是矢量轮廓（值类型），可量 `boundingRect`/`isEmpty`，可 `offsetBy`/`trim`/变换。
- `Shape` = 「在 rect 里产出 Path」；内置和自定义都走 `.path(in:)`，拿到的是布局提议的 rect。
- **形状动画 = SwiftUI 逐帧插值 `animatableData`，每帧重算 `path(in:)`**——不暴露它就跳变。
- `fill`/`stroke` 是声明式绘制；`Canvas` 是即时模式，适合海量动态图元。
- `Animation`/`AnyTransition` 是可组合的值；真实帧调度需 run loop，headless 只测值与几何。
- 下一章（13）讲 **SwiftUI ⇄ UIKit 互操作**，那是本教程「SwiftUI 为主、UIKit 补充」
  两条线交汇的地方。
