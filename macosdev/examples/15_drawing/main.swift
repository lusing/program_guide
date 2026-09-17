// ============================================================
// 15 - 绘图：NSRect 运算、NSBezierPath、颜色、位图
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name drawing main.swift -o 15_drawing \
//          -framework Foundation -framework AppKit
// 运行：
//   ./15_drawing
//
// AppKit 的绘图是「即时模式」：系统准备好一个图形上下文，然后在你的
// draw(_:) 里调用 NSBezierPath / NSColor / NSString 的绘制方法。
// 本章不真的开窗口画（那需要 WindowServer），而是把所有「可算的」部分
// —— 几何、路径、颜色、位图像素 —— 拿出来算清楚。
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

func round1(_ v: CGFloat) -> CGFloat { (v * 10).rounded() / 10 }

// MARK: - 1) NSRect 的几何函数

print("== NSRect 运算 ==")
let base = NSRect(x: 10, y: 20, width: 100, height: 50)
expect(base.maxX == 110, "maxX = origin.x + width（实际 \(base.maxX)）")
expect(base.maxY == 70, "maxY = origin.y + height（实际 \(base.maxY)）")
expect(base.midX == 60, "midX 是水平中心（实际 \(base.midX)）")
expect(base.midY == 45, "midY 是垂直中心（实际 \(base.midY)）")

let inset = base.insetBy(dx: 5, dy: 5)
print("  insetBy(5,5) = \(inset)")
expect(inset == NSRect(x: 15, y: 25, width: 90, height: 40), "内缩 5 点")

let offset = base.offsetBy(dx: 3, dy: -4)
expect(offset == NSRect(x: 13, y: 16, width: 100, height: 50), "平移不改变尺寸")

let a = NSRect(x: 0, y: 0, width: 50, height: 50)
let b = NSRect(x: 25, y: 25, width: 50, height: 50)
let union = a.union(b)
let intersection = a.intersection(b)
print("  union = \(union)")
print("  intersection = \(intersection)")
expect(union == NSRect(x: 0, y: 0, width: 75, height: 75), "并集覆盖两个矩形")
expect(intersection == NSRect(x: 25, y: 25, width: 25, height: 25), "交集是重叠部分")
expect(a.contains(NSPoint(x: 10, y: 10)), "点在矩形内")
expect(a.contains(NSPoint(x: 60, y: 10)) == false, "点在外就不算")
// 不相交时 intersection 是零矩形，不是 nil
expect(NSRect(x: 0, y: 0, width: 10, height: 10).intersection(b).isEmpty, "不相交时交集是空矩形")

// 坑：NSRect 的 width/height 可以是负数，很多运算因此得到「看着对但反了」的结果。
// 需要规范化时用 standardized / integral。
let flippedRect = NSRect(x: 100, y: 100, width: -20, height: -20)
print("  standardized(\(flippedRect)) = \(flippedRect.standardized)")
expect(flippedRect.standardized == NSRect(x: 80, y: 80, width: 20, height: 20), "standardized 把负尺寸转正")

// MARK: - 2) NSBezierPath

print("")
print("== NSBezierPath ==")
let rectPath = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 60, height: 30))
print("  矩形路径 bounds = \(rectPath.bounds), 元素数 = \(rectPath.elementCount)")
// 坑：elementCount 不是 API 契约的一部分 —— 矩形在某些版本上是 6
// （收笔被拆成 lineto + closepath），别拿具体数字做断言。
expect(rectPath.elementCount >= 4, "矩形路径至少有 4 个元素（起笔 + 转角 + 收笔）")
expect(rectPath.bounds == NSRect(x: 0, y: 0, width: 60, height: 30), "bounds 就是那个矩形")
expect(rectPath.contains(NSPoint(x: 30, y: 15)), "中心点在路径内")
expect(rectPath.contains(NSPoint(x: 100, y: 100)) == false, "外面的点不在路径内")

let oval = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 40, height: 40))
expect(oval.bounds == NSRect(x: 0, y: 0, width: 40, height: 40), "椭圆的 bounds 是外接矩形")
expect(oval.contains(NSPoint(x: 20, y: 20)), "圆心在椭圆内")
expect(oval.contains(NSPoint(x: 2, y: 2)) == false, "角上的点在椭圆外")

// 手写路径
let hand = NSBezierPath()
hand.move(to: NSPoint(x: 0, y: 0))
hand.line(to: NSPoint(x: 10, y: 0))
hand.line(to: NSPoint(x: 10, y: 10))
hand.close()
print("  手绘路径 元素数 = \(hand.elementCount), bounds = \(hand.bounds)")
expect(hand.elementCount >= 3, "手绘路径至少 3 个元素（起笔 + 两笔 + 收笔）")
expect(hand.bounds.width == 10 && hand.bounds.height == 10, "bounds 覆盖所有点")

hand.lineWidth = 2
expect(hand.lineWidth == 2, "线宽可以设置")
hand.lineJoinStyle = .round
expect(hand.lineJoinStyle == .round, "连接样式可设置")
hand.lineCapStyle = .butt
expect(hand.lineCapStyle == .butt, "端点样式可设置")

// 曲线
let curve = NSBezierPath()
curve.move(to: NSPoint(x: 0, y: 0))
curve.curve(to: NSPoint(x: 100, y: 0),
            controlPoint1: NSPoint(x: 30, y: 60),
            controlPoint2: NSPoint(x: 70, y: 60))
expect(curve.elementCount == 2, "曲线段算一个元素")
print("  曲线 bounds 高 = \(round1(curve.bounds.height))")
expect(curve.bounds.height > 0, "控制点把 bounds 撑高了")

// 圆角矩形
let rounded = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 80, height: 40),
                           xRadius: 8, yRadius: 8)
expect(rounded.bounds == NSRect(x: 0, y: 0, width: 80, height: 40), "圆角矩形的 bounds 不变")

// MARK: - 3) 颜色

print("")
print("== NSColor ==")
// 坑：NSColor 可能是任意色彩空间，直接取组件会崩或得到奇怪的值。
// 想读 RGB 分量，必须先转到已知空间。
let red = NSColor.systemRed.usingColorSpace(.sRGB)!
print("  systemRed(sRGB) r=\(round1(red.redComponent)) g=\(round1(red.greenComponent)) "
    + "b=\(round1(red.blueComponent)) a=\(round1(red.alphaComponent))")
expect(red.redComponent > 0.5, "红色的红分量高")
expect(red.greenComponent < red.redComponent, "绿分量比红分量低")
expect(red.alphaComponent == 1, "默认不透明")

let half = red.withAlphaComponent(0.5)
expect(half.alphaComponent == 0.5, "withAlphaComponent 返回一个新颜色")
expect(red.alphaComponent == 1, "原颜色不变（NSColor 是值语义的不可变对象）")

// 系统语义色：跟着深色模式变，不要写死 RGB
let label = NSColor.labelColor
print("  labelColor 类型 = \(type(of: label))")
expect(label != NSColor.textBackgroundColor, "语义色各不相同")

// CGColor 与 NSColor 可以互转（Core Graphics / Core Animation 用 CGColor）
let cg = red.cgColor
expect(cg.alpha == 1, "转成 CGColor 后 alpha 还是 1")

// MARK: - 4) 位图

print("")
print("== 位图与 NSImage ==")
// 直接造一个位图表示（image rep），逐个像素读写 —— 完全不需要图形上下文
let width = 4, height = 4
let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                          pixelsWide: width,
                          pixelsHigh: height,
                          bitsPerSample: 8,
                          samplesPerPixel: 4,
                          hasAlpha: true,
                          isPlanar: false,
                          colorSpaceName: .deviceRGB,
                          bytesPerRow: 0,
                          bitsPerPixel: 0)!
print("  size = \(rep.size), samplesPerPixel = \(rep.samplesPerPixel)")
expect(rep.pixelsWide == 4 && rep.pixelsHigh == 4, "位图尺寸 4x4")
expect(rep.samplesPerPixel == 4, "RGBA 四个通道")
expect(rep.bitsPerPixel == 32, "每像素 32 位（实际 \(rep.bitsPerPixel)）")

// 写像素再读回来。
// 坑：不要指望 NSBitmapImageRep.setColor(_:atX:y:) —— 在 deviceRGB / 32bpp 的
// 位图上它会在 stderr 打 "Unrecognized colorspace number -1" 并且**写不进去**
// （读回来是全 0）。要改像素就直接写 bitmapData。
let stride = rep.bytesPerRow
if let pixels = rep.bitmapData {
    pixels[0 * stride + 0 * 4 + 0] = 255   // R
    pixels[0 * stride + 0 * 4 + 1] = 0     // G
    pixels[0 * stride + 0 * 4 + 2] = 0     // B
    pixels[0 * stride + 0 * 4 + 3] = 255   // A
}
let back = rep.colorAt(x: 0, y: 0)!
print("  (0,0) = r=\(round1(back.redComponent)) g=\(round1(back.greenComponent)) a=\(round1(back.alphaComponent))")
expect(back.redComponent > 0.5, "直接写 bitmapData 的红色能读回来")
expect(back.greenComponent < 0.5, "绿分量是低的")
expect(stride >= rep.pixelsWide * 4, "每行字节数 >= 宽 x 4（行尾可能有对齐填充）")

// NSImage 是「容器」，里面装若干个表示（不同分辨率、不同格式）
let image = NSImage(size: NSSize(width: 4, height: 4))
image.addRepresentation(rep)
expect(image.representations.count == 1, "加进去一个表示")
expect(image.size == NSSize(width: 4, height: 4), "NSImage 有自己的逻辑尺寸")
image.isTemplate = true
expect(image.isTemplate, "模板图会跟随系统色调（菜单栏图标常用）")

// 坑：NSImage 的 size 和表示的像素尺寸可以不一样 —— 2x 图就是这么放的。
let doubleRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 8,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0)!
image.addRepresentation(doubleRep)
expect(image.representations.count == 2, "可以放两个不同分辨率的表示")
expect(image.size == NSSize(width: 4, height: 4), "逻辑尺寸仍然是 4x4")

// MARK: - 5) 变换

print("")
print("== 变换 ==")
let transform = NSAffineTransform()
transform.translateX(by: 10, yBy: 20)
let moved = transform.transform(NSPoint(x: 0, y: 0))
print("  平移后 = \(moved)")
expect(moved == NSPoint(x: 10, y: 20), "平移生效")

transform.scale(by: 2)
let scaled = transform.transform(NSPoint(x: 5, y: 5))
print("  再缩放后 = \(scaled)")
expect(scaled == NSPoint(x: 20, y: 30), "变换按应用顺序累积（先平移后缩放）")

let rotated = NSAffineTransform()
rotated.rotate(byDegrees: 90)
let turned = rotated.transform(NSPoint(x: 10, y: 0))
print("  旋转 90° 后 = (\(round1(turned.x)), \(round1(turned.y)))")
expect(abs(turned.x) < 0.001, "x 变成 0（实际 \(round1(turned.x))）")
expect(abs(turned.y - 10) < 0.001, "y 变成 10（实际 \(round1(turned.y))）")

// MARK: - 6) 视图层与绘制

print("")
print("== 视图层 ==")
final class CanvasView: NSView {
    var drawCount = 0
    override func draw(_ dirtyRect: NSRect) {
        drawCount += 1
        NSColor.white.setFill()
        dirtyRect.fill()
    }
    override var isOpaque: Bool { true }
    override var wantsDefaultClipping: Bool { false }
}
let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
expect(canvas.isOpaque, "声明不透明可以让系统省掉一次合成")
expect(canvas.drawCount == 0, "自测里不去触发真正的绘制")
// 层支持：wantsLayer 打开后视图由 CALayer 负责合成
canvas.wantsLayer = true
expect(canvas.wantsLayer, "可以打开层支持")
expect(canvas.layer != nil, "打开后就有了 CALayer")
canvas.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
expect(canvas.layer?.backgroundColor != nil, "层的背景色可以设置")

// 需要重绘时是「打标记」而不是立刻画：系统在下一个绘制周期统一处理
canvas.needsDisplay = true
expect(canvas.needsDisplay == false, "读 needsDisplay 总是 false（它是只写标记）")

print("==== 15 结束 ====")
exit(failures == 0 ? 0 : 1)
