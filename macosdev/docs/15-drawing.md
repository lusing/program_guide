# 15 · 绘图：NSRect、NSBezierPath、NSColor、NSImage

> 示例：`examples/15_drawing/main.swift`
> 实测输出见 `build/15_drawing/stdout.clt.txt`

AppKit 的绘图分两条路：**NSBezierPath**（老式、简单）和 **Core Graphics**（`CGContext`）。
自定义 view 时在 `draw(_:)` 里画。本章讲几何、路径、颜色、位图这些基本功。

## 1) NSRect 运算

```swift
let r = NSRect(x: 10, y: 20, width: 100, height: 50)
r.maxX        // 110   = origin.x + width
r.midX        // 60
r.insetBy(dx: 5, dy: 5)
r.offsetBy(dx: 3, dy: 4)
r.union(other)
r.intersection(other)
r.contains(NSPoint(...))
r.standardized          // 把负尺寸转正
```

实测：

```
  insetBy(5,5) = (15.0, 25.0, 90.0, 40.0)
  union = (0.0, 0.0, 75.0, 75.0)
  intersection = (25.0, 25.0, 25.0, 25.0)
  standardized((100.0, 100.0, -20.0, -20.0)) = (80.0, 80.0, 20.0, 20.0)
  ok   standardized 把负尺寸转正
```

> **坑**：**不相交时 `intersection` 返回「空矩形」**
> （`NSRect.null`，不是 nil）：

```
  ok   不相交时交集是空矩形
```

判断用 `r.isEmpty` 或 `r.isNull`，不要拿 width 去比 0。

## 2) NSBezierPath

```swift
let rectPath = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 60, height: 30))
rectPath.bounds          // (0, 0, 60, 30)
rectPath.contains(NSPoint(x: 30, y: 15))   // true
```

手写路径：

```swift
let hand = NSBezierPath()
hand.move(to: NSPoint(x: 0, y: 0))
hand.line(to: NSPoint(x: 10, y: 0))
hand.line(to: NSPoint(x: 10, y: 10))
hand.close()
hand.lineWidth = 2
hand.lineJoinStyle = .round
hand.lineCapStyle  = .butt
```

实测：

```
  矩形路径 bounds = (0.0, 0.0, 60.0, 30.0), 元素数 = 5
  ok   矩形路径至少有 4 个元素（起笔 + 转角 + 收笔）
  ok   椭圆的 bounds 是外接矩形（按 epsilon 比，原点有浮点噪声）
  手绘路径 元素数 = 5, bounds = (0.0, 0.0, 10.0, 10.0)
  ok   线宽可以设置
  ok   连接样式可设置
  ok   端点样式可设置
```

> **坑**：`elementCount` **不是 API 契约的一部分**。
> 矩形路径在本机（macOS 14 / SDK 15.2）是 5，某些版本上是 6
> （收笔被拆成 lineto + closepath），别拿具体数字做断言。
>
> **坑**：`NSBezierPath(ovalIn:)` 的 `bounds` **不能写 `==` 精确比较**。
> 椭圆是用四段三次贝塞尔曲线逼近的，`bounds` 由「拍平曲线」算出来，
> 原点会带上 `1e-16` 量级的浮点噪声（本机实测 `origin.x ≈ -4.1e-16`，
> 甚至四舍五入后出现 `-0.0`），宽高倒是精确的。老 SDK 上原点恰好是 `0`，
> 新 SDK 上就不是了 —— 必须按 epsilon 断言（示例里的 `nearlySameRect`）。
> 这也是「只断言性质、不断言环境相关的精确数字」这条纪律的又一个例子。
>
> **坑**：`.roundLineJoinStyle` / `.buttLineCapStyle` 是 **Swift 4.2 之前**的旧名，
> 现在是 `.round` / `.butt`。照抄老代码会编译告警。

曲线：

```swift
let curve = NSBezierPath()
curve.move(to: p0)
curve.curve(to: p3, controlPoint1: p1, controlPoint2: p2)
```

**控制点会撑大 bounds**：

```
  曲线 bounds 高 = 45.0
  ok   控制点把 bounds 撑高了
```

贝塞尔曲线的 `bounds` 是包含控制点的**保守估计**，不是曲线的精确包围盒。

### NSBezierPath vs CGPath

- `NSBezierPath` 更 Swift/OC 友好，`stroke()` / `fill()` 一把梭
- `CGPath` / `CGContext` 更底层，能和 Core Animation、PDF 打通
- 现代代码里 `NSBezierPath` 仍然够用；需要阴影、渐变、混合模式时用 CG

## 3) NSColor

```swift
NSColor.systemRed        // 语义色（随系统外观/配色变）
NSColor(calibratedRed: 1, green: 0.3, blue: 0.2, alpha: 1)
color.withAlphaComponent(0.5)   // 返回新颜色，原色不变
color.cgColor
```

实测：

```
  systemRed(sRGB) r=1.0 g=0.2 b=0.2 a=1.0
  ok   红色的红分量高
  ok   默认不透明
  ok   withAlphaComponent 返回一个新颜色
  ok   原颜色不变（NSColor 是值语义的不可变对象）
  labelColor 类型 = NSDynamicSystemColor
  ok   语义色各不相同
  ok   转成 CGColor 后 alpha 还是 1
```

**语义色（`labelColor`、`systemRed`、`controlBackgroundColor`…）**
是 `NSDynamicSystemColor` 的实例：它的 RGB **不是一个固定值**，
而是「在深色模式下取深色、浅色模式下取浅色」。
这就是为什么你要用 `NSColor.labelColor` 而不是 `NSColor.black`。

> **坑**：不要缓存语义色的 RGB 分量。跨外观切换（浅色 ↔ 深色）它就过期了。
> 要画的时候再取。

## 4) 位图：NSBitmapImageRep

```swift
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 4, pixelsHigh: 4,
                           bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
```

改像素**直接写 `bitmapData`**：

```swift
let stride = rep.bytesPerRow
if let pixels = rep.bitmapData {
    pixels[0 * stride + 0 * 4 + 0] = 255   // R
    pixels[0 * stride + 0 * 4 + 1] = 0     // G
    pixels[0 * stride + 0 * 4 + 2] = 0     // B
    pixels[0 * stride + 0 * 4 + 3] = 255   // A
}
let back = rep.colorAt(x: 0, y: 0)!
```

实测：

```
  (0,0) = r=1.0 g=0.0 a=1.0
  ok   直接写 bitmapData 的红色能读回来
  ok   每行字节数 >= 宽 x 4（行尾可能有对齐填充）
```

> **坑**：不要用 `NSBitmapImageRep.setColor(_:atX:y:)`。
> 在 deviceRGB / 32bpp 的位图上它会在 **stderr** 打
> `Unrecognized colorspace number -1` 并且**写不进去**（读回来全 0）。
> 要改像素就写 `bitmapData`。
>
> **坑**：每行字节数（`bytesPerRow`）**不等于** `宽 × 4` ——
> 行尾可能有对齐填充。索引必须用 `bytesPerRow` 算。

## 5) NSImage：容器，不是位图

`NSImage` 是「一个逻辑图 + 若干种表示（representation）」：

```swift
let image = NSImage(size: NSSize(width: 4, height: 4))
image.addRepresentation(rep)          // 1x
image.addRepresentation(rep2x)        // 2x
image.size                            // 仍是 4x4（逻辑尺寸）
image.isTemplate = true               // 模板图：跟随系统色调
```

实测：

```
  ok   加进去一个表示
  ok   NSImage 有自己的逻辑尺寸
  ok   模板图会跟随系统色调（菜单栏图标常用）
  ok   可以放两个不同分辨率的表示
  ok   逻辑尺寸仍然是 4x4
```

- **菜单栏图标一定要 `isTemplate = true`**，否则深色菜单栏下看不清。
- SF Symbols（`NSImage(systemSymbolName:)`）默认就是模板图。

## 6) 变换：NSAffineTransform

```swift
let t = NSAffineTransform()
t.translateX(by: 10, yBy: 20)
t.scaleX(by: 2, yBy: 1.5)
t.rotate(byDegrees: 90)
t.transform(NSPoint(x: 10, y: 0))
```

实测：

```
  平移后 = (10.0, 20.0)
  再缩放后 = (20.0, 30.0)
  旋转 90° 后 = (0.0, 10.0)
```

> **坑**：变换**按应用顺序累积**。先平移再缩放 ≠ 先缩放再平移。
> 上面的例子：点 (0,0) 先平移到 (10,20)，再缩放 (×2, ×1.5) → (20,30)。

## 7) 视图层与绘制

```swift
view.wantsLayer = true
view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
view.canDrawConcurrently = false
view.isOpaque = true          // 声明不透明 → 省掉一次合成
view.needsDisplay = true      // 标记需要重绘（只写属性）
```

实测：

```
  ok   声明不透明可以让系统省掉一次合成
  ok   可以打开层支持
  ok   打开后就有了 CALayer
  ok   层的背景色可以设置
  ok   读 needsDisplay 总是 false（它是只写标记）
```

自定义绘制：

```swift
final class MyView: NSView {
    override var isOpaque: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        let path = NSBezierPath(ovalIn: bounds.insetBy(dx: 4, dy: 4))
        NSColor.systemBlue.setFill()
        path.fill()
    }
    override var intrinsicContentSize: NSSize { NSSize(width: 64, height: 64) }
}
```

> **坑**：**永远不要自己调 `draw(_:)`**。要重绘就设 `needsDisplay = true`，
> 系统在合适的时机调你。
>
> **坑**：`draw(_:)` 里收到的 `dirtyRect` 是**脏区域**，
> 不是整个 bounds。只画它里面的内容能省时间，但别假设它等于 bounds。

## 8) 坑清单

| 现象 | 原因 |
| --- | --- |
| 画出来的图上下颠倒 | AppKit 原点在左下（CGContext 在左上，混用时最明显） |
| `setColor(_:atX:y:)` 写不进去 | 该方法在 deviceRGB 位图上有 bug，直接写 `bitmapData` |
| 像素行错位 | 用了 `宽×4` 当 stride，应该用 `bytesPerRow` |
| 深色模式下颜色不对 | 用了固定色而不是语义色（`NSColor.labelColor`） |
| 菜单栏图标看不清 | 没设 `image.isTemplate = true` |
| `draw(_:)` 不执行 | view 尺寸是 0，或者没被加进窗口 |
| 老代码里的 `.roundLineJoinStyle` 报错 | Swift 4.2 改名成 `.round` |

## 小结

- `intersection` 不相交时返回**空矩形**，不是 nil。
- `elementCount` 不是契约；`.roundLineJoinStyle` 是旧名。
- 语义色是动态的，别缓存它的 RGB。
- 改像素写 `bitmapData`，用 `bytesPerRow` 算索引。
- `NSImage` 是容器；`isTemplate` 用于菜单栏图标。
- 重绘设 `needsDisplay`，绝不自己调 `draw(_:)`。
