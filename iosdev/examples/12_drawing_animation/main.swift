// ============================================================
// 12 - SwiftUI 绘制与动画：Shape / Path / Canvas / 自定义可动画 Shape / 过渡
//
// SwiftUI 的矢量绘制建立在两个类型上：
//   Path  ：一段矢量轮廓（move/addLine/addRect/addArc/close…），可量 boundingRect
//   Shape ：一个「能在给定 rect 里产出 Path」的东西（Rectangle/Circle/自定义）
// 内置 Shape 都提供 .path(in:)，于是绘制**几何**可以 headless 精确断言。
//
// 动画的本质：SwiftUI 对「可插值的值」在时间上取样、逐帧重算 body。Shape 只要暴露
// animatableData（一个 VectorArithmetic），就能被逐帧插值 —— 本示例直接改 animatableData
// 看 Path 怎么变，等价于看动画的某一帧。
//
// headless：验证 Path 几何（boundingRect、isEmpty、trim、offset）、自定义 Shape 的
// path(in:)、以及 animatableData 驱动 Path。真实的时间曲线/帧调度需要 run loop，不在此测。
// ============================================================

import Foundation
import SwiftUI

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func eq(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }
func eqRect(_ r: CGRect, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Bool {
    eq(r.minX, x) && eq(r.minY, y) && eq(r.width, w) && eq(r.height, h)
}

line("== 12 绘制与动画 ==")

let box = CGRect(x: 0, y: 0, width: 100, height: 100)

// ---------------------------------------------------- 1) Path：矢量轮廓
line("")
line("-- Path：从空到有 --")
var empty = Path()
line("  空 Path：isEmpty=\(empty.isEmpty)，boundingRect=\(empty.boundingRect)")
expect(empty.isEmpty, "刚建的 Path 是空的")
// 空 Path 的 boundingRect 是 (inf, inf, 0, 0)——一个「无效」矩形，别拿它当尺寸用
expect(empty.boundingRect.width == 0 && empty.boundingRect.height == 0, "空 Path 的 boundingRect 宽高为 0")

var line1 = Path()
line1.move(to: CGPoint(x: 0, y: 0))
line1.addLine(to: CGPoint(x: 50, y: 50))
line("  一条 (0,0)→(50,50) 的线：boundingRect=\(line1.boundingRect)")
expect(!line1.isEmpty, "加了线段后不再为空")
expect(eqRect(line1.boundingRect, 0, 0, 50, 50), "boundingRect 正好框住这条线：0,0,50,50")

var rectPath = Path()
rectPath.addRect(CGRect(x: 10, y: 10, width: 20, height: 30))
expect(eqRect(rectPath.boundingRect, 10, 10, 20, 30), "addRect 的 boundingRect 就是那个矩形")

// ---------------------------------------------------- 2) Path 变换：offset / trim
line("")
line("-- Path 变换：offsetBy / trimmedPath --")
let moved = rectPath.offsetBy(dx: 5, dy: 5)
line("  addRect 后 offsetBy(5,5) → \(moved.boundingRect)")
expect(eqRect(moved.boundingRect, 15, 15, 20, 30), "offsetBy 把 boundingRect 平移 (10,10)→(15,15)")

let halfCircle = Circle().path(in: box).trimmedPath(from: 0, to: 0.5)
line("  Circle 取前一半 trim(0→0.5) → \(halfCircle.boundingRect)")
expect(eqRect(halfCircle.boundingRect, 0, 50, 100, 50), "trim 前半圈得到下半圆：boundingRect 0,50,100,50")

// ---------------------------------------------------- 3) 内置 Shape：path(in:) 的几何
line("")
line("-- 内置 Shape：Rectangle / Circle / Ellipse / Capsule / RoundedRectangle --")
expect(eqRect(Rectangle().path(in: box).boundingRect, 0, 0, 100, 100), "Rectangle 填满整个 rect")
expect(eqRect(Circle().path(in: box).boundingRect, 0, 0, 100, 100), "Circle 在正方形里内切，boundingRect 仍是 100×100")
let ellipse = Ellipse().path(in: CGRect(x: 0, y: 0, width: 100, height: 50)).boundingRect
line("  Ellipse in 100×50 → \(ellipse)")
expect(eqRect(ellipse, 0, 0, 100, 50), "Ellipse 填满给定的非正方形 rect")
let capsule = Capsule().path(in: CGRect(x: 0, y: 0, width: 100, height: 40)).boundingRect
expect(eqRect(capsule, 0, 0, 100, 40), "Capsule（两端半圆的胶囊）填满 rect")
expect(!Circle().path(in: box).isEmpty, "Circle 的 Path 非空")

// ---------------------------------------------------- 4) 自定义 Shape
line("")
line("-- 自定义 Shape：实现 path(in:) --")
// 一个菱形（diamond）：在给定 rect 里连四个边的中点。
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))     // 上
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))   // 右
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))   // 下
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))   // 左
        p.closeSubpath()
        return p
    }
}
let diamond = Diamond().path(in: box)
line("  Diamond in 100×100 → boundingRect \(diamond.boundingRect)")
expect(eqRect(diamond.boundingRect, 0, 0, 100, 100), "菱形四个顶点在四条边中点，boundingRect 仍是整个 rect")
expect(!diamond.isEmpty, "自定义 Shape 产出了非空 Path")

// ---------------------------------------------------- 5) 可动画 Shape：animatableData 驱动 Path
line("")
line("-- animatableData：动画就是逐帧改这个值 --")
// 一个「进度条」形状：宽度 = rect 宽 × progress。progress 是 animatableData，
// SwiftUI 做动画时就是在 0→1 之间逐帧插值它，每帧重算 path。
struct ProgressBar: Shape {
    var progress: CGFloat                 // 0...1
    // 告诉 SwiftUI：动画时插值这个属性
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY,
                    width: rect.width * progress, height: rect.height))
    }
}
var bar = ProgressBar(progress: 0)
expect(eq(bar.path(in: box).boundingRect.width, 0), "progress=0：宽度 0（动画起始帧）")
bar.animatableData = 0.5                  // 相当于动画进行到一半那一帧
expect(eq(bar.path(in: box).boundingRect.width, 50), "animatableData=0.5：宽度 50（中间帧）")
bar.animatableData = 1.0                  // 动画结束帧
expect(eq(bar.path(in: box).boundingRect.width, 100), "animatableData=1：宽度 100（结束帧）")
line("  改 animatableData → Path 跟着变，这就是形状动画的每一帧")

// ---------------------------------------------------- 6) 填充/描边/Canvas：都是视图
line("")
line("-- fill / stroke / Canvas 是视图 --")
let filled = Circle().fill(Color.blue)
let stroked = Circle().stroke(Color.red, lineWidth: 2)
let canvas = Canvas { ctx, size in
    ctx.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(.green))
}
func tn(_ v: some View) -> String { String(describing: type(of: v)) }
expect(tn(filled).contains("Shape"), "fill 返回一个可绘制视图")
expect(tn(stroked).contains("Shape") || tn(stroked).contains("Stroke"), "stroke 返回一个可绘制视图")
expect(tn(canvas).contains("Canvas"), "Canvas 是即时模式绘制视图（拿到 GraphicsContext 自己画）")

// ---------------------------------------------------- 7) 动画/过渡的值类型
line("")
line("-- Animation / Transition 是值，可组合 --")
let anim = Animation.easeInOut(duration: 0.3)
let animType = String(describing: type(of: anim))
line("  Animation.easeInOut 类型 = \(animType)")
expect(animType.contains("Animation"), "Animation 是一个值（曲线 + 时长）")
// .animation(_:value:) 修饰符：值变化时用指定曲线过渡
let animated = Text("x").animation(anim, value: 0)
expect(tn(animated).contains("ModifiedContent"), ".animation 是包一层的修饰符")
// 过渡：视图插入/移除时的效果
let trans = AnyTransition.opacity
expect(String(describing: type(of: trans)).contains("AnyTransition"), "AnyTransition 描述插入/移除的过渡")

// ---------------------------------------------------- 8) 小结
line("")
line("-- 心智模型 --")
line("  Path 是矢量轮廓，可量 boundingRect / isEmpty / trim / offset")
line("  Shape = 「在 rect 里产出 Path」；内置的和自定义的都走 .path(in:)")
line("  形状动画 = SwiftUI 逐帧插值 animatableData，每帧重算 path(in:)")
line("  Canvas 是即时模式（自己拿 GraphicsContext 画）；Shape 是声明式")
expect(true, "以上均有几何或类型断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 12 结束 ====")
exit(failures == 0 ? 0 : 1)
