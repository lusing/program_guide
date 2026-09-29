// ============================================================
// 29 - Quartz 2D 直接绘制：把每一个像素量出来
//
// 《iOS开发从入门到精通》第 16 章（移动绘图）整章在讲「怎么往屏幕上抹颜色」：
// 绘制周期、坐标系与点/像素、颜色空间、绘画模型、图形上下文、路径、变换、阴影、
// 梯度、透明层、PDF，最后落在基本图形、花瓣曲线、画板三个案例上。那一章的判据是
// 「眼睛看效果」；这一章把同样的条目逐条做成可断言的实验 —— 判据换成回读缓冲区里
// 的那四个字节。
//
// 为什么拿 CGBitmapContext 当量具：UIKit 的 draw(_:) 底下是同一个 CGContext，但它把
// 缓冲区攥在自己手里，测试进程读不到像素（§20 实测：那个上下文的 width/bytesPerRow
// 全是 0，data 是 nil）。CGBitmapContext 允许我们自己提供缓冲区，于是「填充一个矩形」
// 这种说法可以变成「内存第 N 行第 M 列是不是 (255, 0, 0, 255)」。
// 本章每一条 ok 背后都是一次真实回读。
//
// 六条判定带来的写法约束：
//   - 不打印缓冲区地址、文件字节数、耗时；只打印像素值、坐标、尺寸这类可复现的量。
//     图片体积对比（PNG vs JPEG）只在 §23 的探针记录里以叙述出现，不进 stdout；
//   - 内存行号与用户空间 y 是镜像关系（行 0 = 最高的 y）。本章用两个读法把它们分开：
//     at() 按用户空间读、mem() 按内存行读。混用会得出「什么都没画上去」的假结论 ——
//     这是本章最初几遍探针白跑的原因；
//   - 会造成崩溃或未定义行为的写法（行距写小还继续用、iOS 上已被标 unavailable 的
//     CGContext 文本 API、CGContext 那一堆不存在的 getter）一律只写进 §23 探针记录；
//   - 颜色默认用上下文自己的 sRGB 分量造法，避免设备色空间转换带来的字节抖动；
//     需要演示色彩管理时（§4）故意换成另一种造法。
// ============================================================

import CoreGraphics
import CoreText
import Foundation
import UIKit

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// ---------- 量具 ----------

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
typealias RGBA = (Int, Int, Int, Int)

/// 用「本上下文自己的色空间」的分量造色，落盘字节可预测
func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

/// 一块自带缓冲区的画布：既能画，也能读
final class Surface {
    let w: Int
    let h: Int
    let buf: UnsafeMutablePointer<UInt8>
    let ctx: CGContext

    init(_ w: Int, _ h: Int) {
        self.w = w
        self.h = h
        buf = UnsafeMutablePointer<UInt8>.allocate(capacity: w * h * 4)
        buf.initialize(repeating: 0, count: w * h * 4)
        ctx = CGContext(data: buf, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: w * 4, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }

    /// 按内存行号读：row 0 = 缓冲区首行 = 用户空间最高的那一行
    func mem(_ x: Int, _ row: Int) -> RGBA {
        let o = row * w * 4 + x * 4
        return (Int(buf[o]), Int(buf[o + 1]), Int(buf[o + 2]), Int(buf[o + 3]))
    }

    /// 按用户空间读（y=0 = 左下角那一行）；上下文被翻转过就别用它
    func at(_ x: Int, _ y: Int) -> RGBA { mem(x, h - 1 - y) }

    func inked(_ x: Int, _ y: Int) -> Bool { at(x, y).3 > 200 }

    /// 铺一层不透明白底
    func primeWhite() {
        ctx.setFillColor(col(1, 1, 1))
        ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
    }

    /// 数一下有多少个不透明像素（只用于「同一块画布上多与少」的比较）
    /// 白底上「变暗」的像素数：文本墨量这种相对量用它数，别用 inkPixels
    func darkPixels() -> Int {
        var n = 0
        for y in 0..<h { for x in 0..<w where at(x, y).3 > 200 && at(x, y).0 < 128 { n += 1 } }
        return n
    }

    func inkPixels() -> Int {
        var n = 0
        for y in 0..<h { for x in 0..<w where at(x, y).3 > 200 { n += 1 } }
        return n
    }

    var image: CGImage { ctx.makeImage()! }
    var bytes: Data { Data(bytes: buf, count: w * h * 4) }

    deinit { buf.deallocate() }
}

/// 读 CGImage 的像素（行序 = 内存序，自上而下）
func px(_ img: CGImage, _ x: Int, _ y: Int) -> RGBA {
    let data = img.dataProvider!.data!
    let base = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
    let o = y * img.bytesPerRow + x * (img.bitsPerPixel / 8)
    return (Int(base[o]), Int(base[o + 1]), Int(base[o + 2]), Int(base[o + 3]))
}

func fmt(_ v: CGFloat) -> String {
    let r = (v * 100).rounded() / 100
    return r == r.rounded() ? String(format: "%.0f", r) : String(format: "%.2f", r)
}
func rectStr(_ r: CGRect) -> String {
    "(\(fmt(r.origin.x)), \(fmt(r.origin.y)), \(fmt(r.width))×\(fmt(r.height)))"
}
func ctmStr(_ t: CGAffineTransform) -> String {
    "a=\(fmt(t.a)) b=\(fmt(t.b)) c=\(fmt(t.c)) d=\(fmt(t.d)) tx=\(fmt(t.tx)) ty=\(fmt(t.ty))"
}
func spaceName(_ c: CGColorSpace?) -> String {
    guard let n = c?.name else { return "（无）" }
    return n as String
}

// ============================================================
line("\n== §1 位图上下文：自己给缓冲区，才读得回像素 ==")

do {
    let s = Surface(8, 4)
    line("  造一块 8×4 的位图上下文：bitsPerComponent=\(s.ctx.bitsPerComponent) bytesPerRow=\(s.ctx.bytesPerRow)")
    expect(s.ctx.width == 8 && s.ctx.height == 4,
           "width/height 是「像素」而不是点：\(s.ctx.width)×\(s.ctx.height)")
    expect(s.ctx.bytesPerRow == s.w * 4,
           "行距是我们自己传进去的 \(s.ctx.bytesPerRow) = 8 像素 × 4 字节 —— 自带缓冲时，内存布局由你负责")
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 1))
    expect(s.at(0, 0) == (255, 0, 0, 255),
           "sRGB 分量 (1,0,0) 填进去，读回来就是 (255, 0, 0, 255)：一个字节都不差")
    expect(s.at(6, 0) == (0, 0, 0, 0),
           "没画到的地方保持缓冲区初值 (0, 0, 0, 0)：透明黑，不是白")
    expect(s.mem(1, 3) == (255, 0, 0, 255) && s.mem(1, 0) == (0, 0, 0, 0),
           "同一次填充按内存行读：红落在最后一行（行 3），行 0 是空的")
    expect(s.mem(1, 1) == s.at(1, 2),
           "内存行 1 与用户 y=2 是同一行（\(s.mem(1, 1))）：row = h-1-y，行号与 y 互为镜像")
}

do {
    let auto = CGContext(data: nil, width: 20, height: 10, bitsPerComponent: 8, bytesPerRow: 0,
                         space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let w21 = CGContext(data: nil, width: 21, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let w32 = CGContext(data: nil, width: 32, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    line("  bytesPerRow 传 0 让 CG 自己分配：宽 20 → \(auto.bytesPerRow)，宽 21 → \(w21.bytesPerRow)，宽 32 → \(w32.bytesPerRow)")
    expect(auto.bytesPerRow >= 20 * 4 && w21.bytesPerRow > 21 * 4,
           "CG 把每行向上对齐：宽 21 理论上 84 字节，它给 \(w21.bytesPerRow) —— 永远别假设 bytesPerRow == width × 4")
    expect(w32.bytesPerRow >= 32 * 4,
           "宽 32 给 \(w32.bytesPerRow)：对齐后可能刚好等于理论值，但那不是恒等式")
    let img = auto.makeImage()!
    expect(img.bytesPerRow == auto.bytesPerRow,
           "makeImage 出来的 CGImage 与上下文字节对齐：img 不是紧凑数组，只有 \(img.bytesPerRow) 这个字段可信")
    let mine = UnsafeMutablePointer<UInt8>.allocate(capacity: 20 * 10 * 4)
    mine.initialize(repeating: 0, count: 20 * 10 * 4)
    let bad = CGContext(data: mine, width: 20, height: 10, bitsPerComponent: 8,
                        bytesPerRow: 20 * 3, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    expect(bad == nil,
           "行距写小（60 < 80）时 CG 直接拒绝创建、给 nil：它不返回错误码，所以每个创建点都得判空")
    mine.deallocate()
}

do {
    let bgra = CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
                         space: cs,
                         bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                     | CGBitmapInfo.byteOrder32Little.rawValue)!
    bgra.setFillColor(col(1, 0, 0))
    bgra.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    let p = bgra.data!.assumingMemoryBound(to: UInt8.self)
    let bytes = (0..<4).map { Int(p[$0]) }
    let word = p.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
    line("  premultipliedFirst + byteOrder32Little（常说的 BGRA）：行距 \(bgra.bytesPerRow)，首 4 字节 \(bytes)")
    expect(bytes == [0, 0, 255, 255],
           "同一支纯红，字节序变成 B,G,R,A = \(bytes)：位图布局是「色空间 × alpha 摆法 × 字节序」三件事的乘积")
    expect(String(word, radix: 16) == "ffff0000",
           "按 UInt32 读同一个元素 = 0x\(String(word, radix: 16))：小端把 alpha 放在最高字节，对接 GPU/别的图像库时这里最容易反")
}

// ============================================================
line("\n== §2 两套原点：Quartz 左下，UIKit 左上 ==")

do {
    let s = Surface(8, 8)
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 1))
    expect(s.mem(1, 7) == (255, 0, 0, 255) && s.mem(1, 0) == (0, 0, 0, 0),
           "默认（Quartz 语义）fill 用户 y∈[0,1)：墨在缓冲区最后一行（行 7），行 0 空 —— 原点就在左下角")
    let t = Surface(8, 8)
    t.ctx.translateBy(x: 0, y: 8)
    t.ctx.scaleBy(x: 1, y: -1)
    expect(t.ctx.ctm == CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 8),
           "「translate(0,h) 再 scale(1,-1)」得到的 CTM 是 \(ctmStr(t.ctx.ctm))：UIKit 那套左上原点的真身就是这条矩阵")
    t.ctx.setFillColor(col(1, 0, 0))
    t.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 1))
    expect(t.mem(1, 0) == (255, 0, 0, 255) && t.mem(1, 7) == (0, 0, 0, 0),
           "翻转之后同一条 fill 落到内存首行（行 0）：代码一个字没改，只是 CTM 变了，图像就上下颠倒")
    expect(t.at(1, 0) == (0, 0, 0, 0),
           "翻转后再用「未翻转的读法」at(1,0) 读到 \(t.at(1, 0))：这就是把两套 y 混用的下场，别拿它当证据")
}

do {
    let fmt1 = UIGraphicsImageRendererFormat()
    fmt1.scale = 1
    fmt1.opaque = true
    var insideCTM = CGAffineTransform.identity
    _ = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: fmt1).image { rc in
        insideCTM = rc.cgContext.ctm
        rc.cgContext.setFillColor(col(1, 0, 0))
        rc.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 1))
    }
    expect(insideCTM == CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 8),
           "renderer 交给你的上下文，开局 CTM 就是 \(ctmStr(insideCTM))：UIKit 不另建坐标系，它就是那条翻转矩阵")

    // 手写翻转的位图 vs renderer：同一串绘制指令应当逐字节相同
    func manual(_ side: Int) -> Data {
        let s = Surface(side, side)
        s.ctx.translateBy(x: 0, y: CGFloat(side))
        s.ctx.scaleBy(x: 1, y: -1)
        let g = CGGradient(colorsSpace: cs,
                           colors: [col(1, 0, 0, 1), col(0, 0, 1, 1)] as CFArray,
                           locations: [0, 1])!
        s.ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: CGFloat(side), y: CGFloat(side)),
                                 options: [.drawsAfterEndLocation])
        s.ctx.setStrokeColor(col(0, 1, 0, 1))
        s.ctx.setLineWidth(1.5)
        s.ctx.addEllipse(in: CGRect(x: 2, y: 2, width: CGFloat(side) - 4, height: CGFloat(side) - 4))
        s.ctx.strokePath()
        return s.bytes
    }
    func viaRenderer(_ side: Int) -> (Data, Int) {
        let f = UIGraphicsImageRendererFormat()
        f.scale = 1
        f.opaque = true
        let img = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: f).image { rc in
            let c = rc.cgContext
            let g = CGGradient(colorsSpace: cs,
                               colors: [col(1, 0, 0, 1), col(0, 0, 1, 1)] as CFArray,
                               locations: [0, 1])!
            c.drawLinearGradient(g, start: .zero, end: CGPoint(x: CGFloat(side), y: CGFloat(side)),
                                 options: [.drawsAfterEndLocation])
            c.setStrokeColor(col(0, 1, 0, 1))
            c.setLineWidth(1.5)
            c.addEllipse(in: CGRect(x: 2, y: 2, width: CGFloat(side) - 4, height: CGFloat(side) - 4))
            c.strokePath()
        }
        let cg = img.cgImage!
        let d = cg.dataProvider!.data!
        return (Data(bytes: (d as NSData).bytes.assumingMemoryBound(to: UInt8.self),
                     count: cg.bytesPerRow * cg.height), cg.bytesPerRow)
    }
    let mA = manual(16)
    let (mB, strideB) = viaRenderer(16)
    let aBytes = [UInt8](mA)
    let bBytes = [UInt8](mB)
    var diff = 0
    for y in 0..<16 {
        for x in 0..<16 {
            for k in 0..<3 {
                let ia = y * 64 + x * 4 + k
                let ib = y * strideB + x * 4 + k
                if aBytes[ia] != bBytes[ib] { diff += 1 }
            }
        }
    }
    line("  同样的指令：一边是自己翻转的位图上下文（行距 64），一边是 renderer（行距 \(strideB)）")
    expect(diff == 0,
           "逐像素比 RGB：不同的字节数 = \(diff) —— 两者完全等价，UIKit 的绘制栈底下就是 Quartz 2D")
}

// ============================================================
line("\n== §3 点与像素：线宽怎么落进格子 ==")

do {
    let s = Surface(8, 6)
    s.ctx.setStrokeColor(col(1, 0, 0))
    s.ctx.setLineWidth(1)
    s.ctx.move(to: CGPoint(x: 0, y: 1))
    s.ctx.addLine(to: CGPoint(x: 8, y: 1))
    s.ctx.strokePath()
    line("  1pt 宽的线画在整数 y=1：用户 y=0 \(s.at(3, 0))｜y=1 \(s.at(3, 1))｜y=2 \(s.at(3, 2))")
    expect(s.at(3, 1).3 == 127 && s.at(3, 0).3 == 127 && s.at(3, 2).3 == 0,
           "线中心压在整数 y 上 → 墨被平分给相邻两行，各得 alpha 127：「1px 线要 +0.5」这套说法的物理原因")
    s.ctx.move(to: CGPoint(x: 0, y: 4.5))
    s.ctx.addLine(to: CGPoint(x: 8, y: 4.5))
    s.ctx.strokePath()
    expect(s.at(3, 4) == (255, 0, 0, 255) && s.at(3, 5).3 == 0,
           "同一条线挪到 y=4.5 → 正好占满 y=4 那一行，alpha 255、相邻行干净")
    let t = Surface(9, 6)
    t.ctx.setStrokeColor(col(1, 0, 0))
    t.ctx.setLineWidth(3)
    t.ctx.move(to: CGPoint(x: 0, y: 2))
    t.ctx.addLine(to: CGPoint(x: 9, y: 2))
    t.ctx.strokePath()
    line("  3pt 宽的线画在 y=2：y0 \(t.at(4, 0))｜y1 \(t.at(4, 1))｜y2 \(t.at(4, 2))｜y3 \(t.at(4, 3))｜y4 \(t.at(4, 4))")
    expect(t.at(4, 2).3 == 255 && t.at(4, 4).3 == 0 && t.at(4, 0).3 > 0 && t.at(4, 0).3 < 255,
           "线宽覆盖 y∈[0.5, 3.5)：中间整行满色，被切到的边缘行半透明 —— 覆盖量按「面积」算，不是按「中心点」")
}

do {
    func diagonal(_ aa: Bool) -> [Int] {
        let s = Surface(8, 8)
        s.ctx.setShouldAntialias(aa)
        s.ctx.setStrokeColor(col(1, 0, 0))
        s.ctx.setLineWidth(1)
        s.ctx.move(to: CGPoint(x: 0, y: 0))
        s.ctx.addLine(to: CGPoint(x: 8, y: 8))
        s.ctx.strokePath()
        return [s.at(3, 3).3, s.at(4, 3).3, s.at(3, 4).3]
    }
    let on = diagonal(true), off = diagonal(false)
    line("  斜线 1pt 沿对角线：抗锯齿开 \(on)，关 \(off)")
    expect(on.contains { $0 > 0 && $0 < 255 },
           "开抗锯齿时斜边出现中间值（\(on)）：像素只能整块上色，于是用 alpha 表达「被盖住多少」")
    expect(off.allSatisfy { $0 == 0 || $0 == 255 },
           "关抗锯齿后只剩 0 和 255 两种（\(off)）：锯齿换性能，像素画/位图工具的场合反而要它")
    let d = Surface(8, 8)
    expect(d.ctx.interpolationQuality == .default && d.ctx.interpolationQuality.rawValue == 0,
           "新建上下文的插值质量默认是 .default（rawValue \(d.ctx.interpolationQuality.rawValue)）而不是「不插值」：含义是「按目标上下文的默认策略走」")
    expect(CGInterpolationQuality.none.rawValue == 1 && CGInterpolationQuality.low.rawValue == 2
           && CGInterpolationQuality.medium.rawValue == 4 && CGInterpolationQuality.high.rawValue == 3,
           "这套枚举的真实编号是 default=0、none=1、low=2、high=3、medium=4：medium 与 high 的大小顺序和数值顺序是反的，别拿 rawValue 比「质量高低」")
}

// ============================================================
line("\n== §4 色彩管理：同一支「红」，三种字节 ==")

do {
    let s = Surface(6, 1)
    s.ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 2, y: 0, width: 2, height: 1))
    s.ctx.setFillColor(UIColor.red.cgColor)
    s.ctx.fill(CGRect(x: 4, y: 0, width: 2, height: 1))
    line("  三处都写「纯红」，落盘分别是：CGColor(red:green:blue:) \(s.mem(0, 0))｜sRGB 分量造法 \(s.mem(2, 0))｜UIColor.red \(s.mem(4, 0))")
    expect(s.mem(2, 0) == (255, 0, 0, 255),
           "只有用上下文自己的 sRGB 分量造的那支，读回来才是 (255, 0, 0, 255)")
    expect(s.mem(0, 0) != s.mem(2, 0),
           "CGColor(red:green:blue:) 用的是「设备 RGB」色空间，被转换过（\(s.mem(0, 0))）：同一种颜色写法，差 38 个绿分量")
    expect(s.mem(4, 0) == (255, 0, 0, 255),
           "UIColor.red 在这里恰好与 sRGB 同值（\(s.mem(4, 0))）—— 但那是巧合，见下一条")
    let redName = spaceName(UIColor.red.cgColor.colorSpace)
    let sysName = spaceName(UIColor.systemRed.cgColor.colorSpace)
    let ownName = spaceName(col(1, 0, 0).colorSpace)
    line("  色空间名回读：UIColor.red → \(redName)｜UIColor.systemRed → \(sysName)｜自己造的 → \(ownName)")
    expect(redName != ownName,
           "刚才落盘字节恰好相同的 UIColor.red，色空间其实是 \(redName)，与我们的 \(ownName) 不是同一个：字节相等不等于色空间相等，反过来「同一支红」在不同色空间里字节也会变")
    expect(sysName == ownName,
           "但 UIColor.systemRed 就在 \(sysName) 里：一族「红」的色空间并不统一，判等之前必须逐个问色空间")

    let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
    let d = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    d.initialize(repeating: 0, count: 8)
    let p3ctx = CGContext(data: d, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                          space: p3, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    p3ctx.setFillColor(col(1, 0, 0))
    p3ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    p3ctx.setFillColor(UIColor.systemRed.cgColor)
    p3ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
    let r0 = (0..<4).map { Int(d[$0]) }, r1 = (4..<8).map { Int(d[$0]) }
    line("  把 sRGB 的纯红画进 P3 画布 → \(r0)；把「扩展 sRGB」的系统红画进 P3 → \(r1)")
    expect(r0 != [255, 0, 0, 255],
           "sRGB 红进了 P3 上下文会被转换（\(r0)）：sRGB 是 P3 的子集，转换后不可能还是同一串字节")
    d.deallocate()

    let graySpace = CGColorSpace(name: CGColorSpace.linearGray)!
    let gd = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
    gd.initialize(repeating: 0, count: 4)
    let gctx = CGContext(data: gd, width: 4, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                         space: graySpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    gctx.setFillColor(col(1, 0, 0))
    gctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    line("  同一支红画进「线性灰度 + 无 alpha」上下文：首字节 \(Int(gd[0]))")
    expect(Int(gd[0]) > 0 && Int(gd[0]) < 255,
           "彩色转灰不是「取平均」，是按权重合成再换 gamma（这里给 \(Int(gd[0]))）：灰盒子的字节是算出来的，猜不得")
    gd.deallocate()
}

do {
    let s = Surface(4, 2)
    s.ctx.setFillColor(col(1, 0, 0, 0.5))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 2))
    expect(s.at(1, 1) == (128, 0, 0, 128),
           "「50% 不透明的红」在 premultipliedLast 缓冲里存成 \(s.at(1, 1))：RGB 也被 alpha 乘过一遍")
    let t = Surface(4, 2)
    t.ctx.setFillColor(col(1, 0, 0, 1))
    t.ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 2))
    t.ctx.setFillColor(col(0, 0, 1, 0.5))
    t.ctx.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
    expect(t.at(1, 1) == (127, 0, 128, 255),
           "半透明蓝叠在不透明红上 → \(t.at(1, 1))：源在上、按 alpha 在两个颜色之间线性插值，这就是默认的 .normal")
}

// ============================================================
line("\n== §5 绘画模型：后画的盖住先画的 ==")

do {
    let s = Surface(8, 8)
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
    s.ctx.setBlendMode(.destinationOver)
    s.ctx.setFillColor(col(0, 0, 1))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    s.ctx.setBlendMode(.normal)
    expect(s.at(3, 3) == (255, 0, 0, 255),
           "destinationOver 铺一整幅蓝之后，红块还在（(3,3)=\(s.at(3, 3))）：这条混合模式是「把自己垫到已有内容之下」")
    expect(s.at(0, 0) == (0, 0, 255, 255),
           "红块之外的地方留下了蓝（(0,0)=\(s.at(0, 0))）：「垫底」只在上面没东西的地方露出来")

    let t = Surface(8, 8)
    t.ctx.setFillColor(col(1, 0, 0))
    t.ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
    t.ctx.setFillColor(col(0, 0, 1))
    t.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(t.at(3, 3) == (0, 0, 255, 255),
           "同样两笔、去掉 destinationOver（默认 .normal），红块直接被盖没（(3,3)=\(t.at(3, 3))）：调用顺序就是层序")

    let u = Surface(8, 8)
    u.ctx.setFillColor(col(1, 0, 0))
    u.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let base = u.image
    u.ctx.setFillColor(col(0, 0, 1))
    u.ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    u.ctx.draw(base, in: CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(u.at(1, 1) == (255, 0, 0, 255),
           "把「旧内容」当图片 draw 回去，它会盖在刚画的新内容之上（\(u.at(1, 1))）：这就是「每帧重画」必须自己管层序的原因")
}

// ============================================================
line("\n== §6 当前路径与 CGPath：能问的只有这几样 ==")

do {
    let path = CGMutablePath()
    path.move(to: .zero)
    path.addLine(to: CGPoint(x: 10, y: 0))
    path.addLine(to: CGPoint(x: 10, y: 10))
    path.closeSubpath()
    var elements = 0
    path.applyWithBlock { _ in elements += 1 }
    line("  三角形路径：元素数 \(elements)，包围盒 \(rectStr(path.boundingBoxOfPath))，isEmpty=\(path.isEmpty)")
    expect(elements == 4,
           "move + 两条 line + close 是 4 个元素：closeSubpath 自己也是一个元素，不是一段线")
    expect(path.boundingBoxOfPath == CGRect(x: 0, y: 0, width: 10, height: 10) && !path.isEmpty,
           "boundingBoxOfPath 给 (0,0,10×10)，isEmpty 是 \(path.isEmpty)")

    let s = Surface(8, 8)
    expect(s.ctx.isPathEmpty && s.ctx.boundingBoxOfPath.isNull,
           "新上下文的当前路径：isPathEmpty = \(s.ctx.isPathEmpty)，bbox 是「空矩形」（isNull = \(s.ctx.boundingBoxOfPath.isNull)）")
    s.ctx.addRect(CGRect(x: 2, y: 2, width: 3, height: 3))
    expect(s.ctx.boundingBoxOfPath == CGRect(x: 2, y: 2, width: 3, height: 3),
           "加了一个矩形之后 bbox = \(rectStr(s.ctx.boundingBoxOfPath))：这是「当前路径」的查询口，不是内容查询口")
    expect(s.ctx.pathContains(CGPoint(x: 3, y: 3), mode: .fill)
           && !s.ctx.pathContains(CGPoint(x: 7, y: 7), mode: .fill),
           "pathContains 能判点是否落在路径内：(3,3) 命中、(7,7) 不命中 —— 命中测试不必真的画出来")
    s.ctx.beginPath()
    expect(s.ctx.isPathEmpty,
           "beginPath() 清掉当前路径（isPathEmpty = \(s.ctx.isPathEmpty)）：路径是上下文的状态，不是一支可以到处传的 CGPath 对象")
    s.ctx.addRect(CGRect(x: 1, y: 1, width: 2, height: 2))
    s.ctx.fillPath()
    expect(s.ctx.isPathEmpty,
           "fillPath() 之后路径也被吃掉（isPathEmpty = \(s.ctx.isPathEmpty)）：想对同一条路径既填又描，得先 copy 出来或再 addPath 一遍")

    let empty = Surface(4, 4)
    empty.ctx.addQuadCurve(to: CGPoint(x: 3, y: 3), control: CGPoint(x: 0, y: 0))
    expect(empty.ctx.boundingBoxOfPath.isNull && empty.ctx.isPathEmpty,
           "在没有起点的空路径上直接 addQuadCurve：什么都没加进去（bbox isNull = \(empty.ctx.boundingBoxOfPath.isNull)）—— 曲线需要当前点，而它静默失败、不报错")
    let moved = Surface(4, 4)
    moved.ctx.move(to: CGPoint(x: 1, y: 1))
    moved.ctx.addQuadCurve(to: CGPoint(x: 3, y: 3), control: CGPoint(x: 0, y: 0))
    expect(!moved.ctx.isPathEmpty,
           "补一个 move(to:) 之后同一条 addQuadCurve 就成立了（bbox = \(rectStr(moved.ctx.boundingBoxOfPath))）")
    let cubic = Surface(12, 12)
    cubic.ctx.move(to: CGPoint(x: 1, y: 1))
    cubic.ctx.addCurve(to: CGPoint(x: 10, y: 10), control1: CGPoint(x: 1, y: 10), control2: CGPoint(x: 10, y: 0))
    line("  三次贝塞尔（端点 (1,1)/(10,10)，控制点 (1,10)/(10,0)）的包围盒 = \(rectStr(cubic.ctx.boundingBoxOfPath))")
    expect(cubic.ctx.boundingBoxOfPath.minY < 1 && cubic.ctx.boundingBoxOfPath.maxY == 10,
           "盒子的下边被控制点 (10,0) 顶到 y=\(fmt(cubic.ctx.boundingBoxOfPath.minY))，比两个端点（y=1 与 y=10）都低（\(rectStr(cubic.ctx.boundingBoxOfPath))）：包围盒是按「端点 + 控制点」算的保守外框，不是曲线的真实极值 —— 裁剪区、命中区不能只按端点算，但也别把它当成紧贴曲线的外接矩形")
}

// ============================================================
line("\n== §7 填充规则：非零绕数 vs 奇偶 ==")

do {
    let ring = CGMutablePath()
    ring.addRect(CGRect(x: 1, y: 1, width: 10, height: 10))
    ring.addRect(CGRect(x: 4, y: 4, width: 4, height: 4))
    let a = Surface(12, 12), b = Surface(12, 12)
    a.ctx.addPath(ring); a.ctx.fillPath()
    b.ctx.addPath(ring); b.ctx.fillPath(using: .evenOdd)
    line("  两个同向嵌套矩形：默认 winding 中心 \(a.at(6, 6))｜even-odd 中心 \(b.at(6, 6))")
    expect(a.at(6, 6) == (0, 0, 0, 255) && b.at(6, 6) == (0, 0, 0, 0),
           "同向两矩形在 winding 下并成实心（fillPath 的默认规则就是它），even-odd 才挖出洞：「用路径挖洞」必须显式换规则")
    expect(a.at(2, 2) == (0, 0, 0, 255) && b.at(2, 2) == (0, 0, 0, 255),
           "环上那点两种规则都填（\(b.at(2, 2))）：差别只出现在绕数大于 1 的区域")

    let mix = CGMutablePath()
    mix.addRect(CGRect(x: 1, y: 1, width: 10, height: 10))
    mix.addEllipse(in: CGRect(x: 4, y: 4, width: 4, height: 4))
    let c = Surface(12, 12)
    c.ctx.addPath(mix); c.ctx.fillPath(using: .winding)
    expect(c.at(6, 6) == (0, 0, 0, 255),
           "矩形里加个椭圆、两者同向 → winding 仍然实心（\(c.at(6, 6))）：绕数要靠「方向相反」才会抵消，不是靠「里面还有一条子路径」")

    let opp = CGMutablePath()
    opp.addRect(CGRect(x: 1, y: 1, width: 10, height: 10))
    opp.addRect(CGRect(x: 4, y: 4, width: 4, height: 4), transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 12, ty: 0))
    let o = Surface(12, 12)
    o.ctx.addPath(opp); o.ctx.fillPath(using: .winding)
    expect(o.at(6, 6) == (0, 0, 0, 0),
           "把内框用 mirror 变换反着加（绕数 -1）→ winding 也挖出了洞（\(o.at(6, 6))）：这就是 Photoshop 那类工具「反向子路径抠洞」的原理")
}

do {
    func fan(_ clockwise: Bool) -> (RGBA, RGBA, RGBA) {
        let s = Surface(12, 12)
        s.ctx.setFillColor(col(1, 0, 0))
        s.ctx.move(to: CGPoint(x: 6, y: 6))
        s.ctx.addArc(center: CGPoint(x: 6, y: 6), radius: 5,
                     startAngle: 0, endAngle: .pi / 2, clockwise: clockwise)
        s.ctx.closePath()
        s.ctx.fillPath()
        return (s.at(9, 6), s.at(6, 9), s.at(3, 3))
    }
    let ccw = fan(false), cw = fan(true)
    line("  同一句「从 0° 到 90°」：clockwise:false → (9,6)=\(ccw.0) (6,9)=\(ccw.1)；clockwise:true → (9,6)=\(cw.0) (6,9)=\(cw.1)")
    expect(ccw.0.3 == 255 && ccw.1.3 == 255 && cw.0.3 == 0 && cw.1.3 == 0,
           "clockwise 决定「走这 90° 还是走另一侧的 270°」，不是决定弧凹凸：要第一象限的扇形就得传 false")
    expect(cw.2.3 == 255,
           "clockwise:true 那版反而把第三象限填上了（(3,3)=\(cw.2)）：角度参数不变，扫过的区域完全变了")
}

// ============================================================
line("\n== §8 变换：CTM 是乘法，乘法讲顺序 ==")

do {
    func cols(_ ops: (CGContext) -> Void) -> [Int] {
        let s = Surface(16, 4)
        ops(s.ctx)
        s.ctx.setFillColor(col(1, 0, 0))
        s.ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return (0..<16).filter { s.mem($0, 3).3 > 200 }
    }
    let a = cols { $0.translateBy(x: 4, y: 0); $0.scaleBy(x: 2, y: 2) }
    let b = cols { $0.scaleBy(x: 2, y: 2); $0.translateBy(x: 4, y: 0) }
    line("  单位方块 1×1：先 translate(4,0) 后 scale(2,2) → 亮列 \(a)；反过来 → 亮列 \(b)")
    expect(a == [4, 5] && b == [8, 9],
           "两句指令互换顺序，落点从列 4-5 变成 8-9：变换作用在坐标系上，先写的平移会被后写的缩放放大")

    let s1 = Surface(4, 4), s2 = Surface(4, 4)
    s1.ctx.translateBy(x: 4, y: 0); s1.ctx.scaleBy(x: 2, y: 2)
    s2.ctx.scaleBy(x: 2, y: 2); s2.ctx.translateBy(x: 4, y: 0)
    line("  对应的矩阵：先平移 \(ctmStr(s1.ctx.ctm))｜先缩放 \(ctmStr(s2.ctx.ctm))")
    expect(s1.ctx.ctm != s2.ctx.ctm,
           "两个 CTM 不相等：矩阵乘法不满足交换律，只有同轴纯缩放/纯平移这类特例才可换")
    expect(s1.ctx.ctm.tx == 4 && s2.ctx.ctm.tx == 8,
           "tx 分别是 \(fmt(s1.ctx.ctm.tx)) 与 \(fmt(s2.ctx.ctm.tx))：写在 scale 之后的平移，位移量本身也被缩放")

    let r = Surface(4, 4)
    r.ctx.rotate(by: .pi / 2)
    let unitBox = CGRect(x: 0, y: 0, width: 1, height: 1).applying(r.ctx.ctm)
    line("  rotate(π/2)：ctm \(ctmStr(r.ctx.ctm))，单位方块变成 \(rectStr(unitBox))")
    expect(abs(r.ctx.ctm.b - 1) < 1e-9 && abs(r.ctx.ctm.c + 1) < 1e-9,
           "π/2 不是精确的 90°：a/d 里留着 6.12e-17 这种残差（这里 a=\(fmt(r.ctx.ctm.a)) d=\(fmt(r.ctx.ctm.d))），判断「整数角度」必须留容差")
    expect(unitBox.minX < -0.99 && abs(unitBox.maxX) < 0.01,
           "单位方块旋到 x∈[\(fmt(unitBox.minX)), \(fmt(unitBox.maxX))]（\(rectStr(unitBox))）：绕原点转就把图形送到了负坐标区，负坐标完全合法，只是超出缓冲区的那部分落不到像素上")
    r.ctx.scaleBy(x: 2, y: 1)
    expect(r.ctx.userSpaceToDeviceSpaceTransform.a != 0 || r.ctx.userSpaceToDeviceSpaceTransform.b != 0,
           "userSpaceToDeviceSpaceTransform = \(ctmStr(r.ctx.userSpaceToDeviceSpaceTransform))：这是「用户空间 → 设备空间」的合成矩阵，比自己乘 CTM 可靠")

    let t = CGAffineTransform(a: 2, b: 0, c: 0, d: 2, tx: 10, ty: 0)
    let p = CGPoint(x: 5, y: 5).applying(t)
    expect(p == CGPoint(x: 20, y: 10),
           "同一个矩阵作用在点上：(5,5) → (\(fmt(p.x)), \(fmt(p.y)))，即先 ×2 再 +10：applying 走的就是 CTM 那套乘序")
    let det = t.a * t.d - t.b * t.c
    expect(det != 0 && t.inverted().concatenating(t).isIdentity,
           "可逆矩阵串上自己的逆等于单位阵：行列式 \(fmt(det)) 非 0 才有逆")
    let deg = CGAffineTransform(a: 2, b: 0, c: 0, d: 0, tx: 10, ty: 0)
    let degInv = deg.inverted()
    expect(deg.a * deg.d - deg.b * deg.c == 0 && degInv == deg,
           "Swift 的 CGAffineTransform 没有 isInvertible，只能用 a*d-b*c 自己判：退化矩阵（d=0）问 inverted() 既不报错也不给单位阵，它把原矩阵原样还给你（\(ctmStr(degInv))）")
    let degPoint = CGPoint(x: 5, y: 5).applying(degInv)
    expect(degPoint == CGPoint(x: 20, y: 0),
           "拿这张「假逆」去映射 (5,5) 得 (\(fmt(degPoint.x)), \(fmt(degPoint.y)))：那是正向变换的结果，被压扁的那一维再也回不来")
}

// ============================================================
line("\n== §9 裁剪：只会越裁越小，解除只能靠状态栈 ==")

do {
    let s = Surface(8, 8)
    s.ctx.saveGState()
    s.ctx.clip(to: CGRect(x: 2, y: 2, width: 6, height: 6))
    s.ctx.clip(to: CGRect(x: 0, y: 0, width: 4, height: 8))
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(s.at(3, 3) == (255, 0, 0, 255) && s.at(5, 5).3 == 0 && s.at(1, 1).3 == 0,
           "两次 clip 取交集：只有 x∈[2,4)、y∈[2,8) 有墨（(3,3)=\(s.at(3, 3))，(5,5)=\(s.at(5, 5))，(1,1)=\(s.at(1, 1))）")
    expect(s.ctx.boundingBoxOfClipPath == CGRect(x: 2, y: 2, width: 2, height: 6),
           "boundingBoxOfClipPath = \(rectStr(s.ctx.boundingBoxOfClipPath))（[2,4)×[2,8) 那一条）：这是「现在还能往哪儿画」的查询口")
    s.ctx.clip(to: CGRect(x: 0, y: 0, width: 8, height: 8))
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(s.at(7, 7).3 == 0,
           "第三次 clip 给的是全幅，白给：(7,7) 依然 \(s.at(7, 7)) —— 裁剪只能求交，扩不回去")
    s.ctx.restoreGState()
    s.ctx.setFillColor(col(0, 1, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(s.at(7, 7) == (0, 255, 0, 255),
           "restoreGState() 才解除裁剪，绿铺到 (7,7)=\(s.at(7, 7))：想撤掉裁剪，唯一手段是保存/恢复状态")

    s.ctx.clear(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(s.at(4, 4) == (0, 0, 0, 0),
           "clear() 无视当前颜色，把区域内写成全透明（\(s.at(4, 4))）：它等价于用 .clear 混合模式填一笔")
}

do {
    let ring = CGMutablePath()
    ring.addRect(CGRect(x: 1, y: 1, width: 8, height: 8))
    ring.addRect(CGRect(x: 3, y: 3, width: 4, height: 4))
    let a = Surface(10, 10)
    a.ctx.saveGState()
    a.ctx.addPath(ring); a.ctx.clip(using: .evenOdd)
    a.ctx.setFillColor(col(1, 0, 0))
    a.ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    a.ctx.restoreGState()
    expect(a.at(2, 2).3 == 255 && a.at(5, 5).3 == 0,
           "路径裁剪 + even-odd：环上有墨（\(a.at(2, 2))）、洞心透明（\(a.at(5, 5))）—— 圆角头像、异形蒙版就是这么来的")
    let b = Surface(10, 10)
    b.ctx.saveGState()
    b.ctx.addPath(ring); b.ctx.clip(using: .winding)
    b.ctx.setFillColor(col(1, 0, 0))
    b.ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    b.ctx.restoreGState()
    expect(b.at(5, 5).3 == 255,
           "同一条路径换成 winding 就不留洞（\(b.at(5, 5))）：clip(using:) 的规则参数与 fillPath(using:) 是同一件事")

    let maskSrc = Surface(2, 4)
    maskSrc.ctx.setFillColor(col(0, 0, 0))
    maskSrc.ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 4))
    let mask = maskSrc.image
    let m = Surface(8, 8)
    m.ctx.clip(to: CGRect(x: 0, y: 0, width: 8, height: 8), mask: mask)
    m.ctx.setFillColor(col(1, 0, 0))
    m.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    expect(m.at(0, 4).3 == 255 && m.at(6, 4).3 == 0,
           "clip(to:mask:) 用灰度图当蒙版：留得下东西的是蒙罩里「有墨」的那半幅（\(m.at(0, 4)) / \(m.at(6, 4))）—— 8 位蒙版还能给半透明边缘")
}

do {
    let s = Surface(10, 10)
    s.ctx.setLineWidth(2)
    s.ctx.addRect(CGRect(x: 3, y: 3, width: 4, height: 4))
    s.ctx.replacePathWithStrokedPath()
    expect(!s.ctx.isPathEmpty,
           "描边化之后路径还在（bbox = \(rectStr(s.ctx.boundingBoxOfPath))）：它只是把「线」改写成「形」，不消耗路径")
    s.ctx.clip()
    expect(s.ctx.isPathEmpty,
           "无参数的 clip() 拿当前路径当蒙版，用完就清（isPathEmpty = \(s.ctx.isPathEmpty)）：它和 fill/stroke 一样属于「吃路径」的指令，剪完还想用这条路径，得提前留一份 CGPath")
    s.ctx.setFillColor(col(0, 1, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    expect(s.at(3, 5) == (0, 255, 0, 255) && s.at(5, 5) == (0, 0, 0, 0) && s.at(1, 1).3 == 0,
           "把 2pt 的方框描边变成裁剪区：线环上有色、中心留洞、框外全空（\(s.at(3, 5)) / \(s.at(5, 5)) / \(s.at(1, 1))）—— 「只描边区域可画」是镂空文字类效果的做法")

    let t = Surface(10, 10)
    t.ctx.addRect(CGRect(x: 3, y: 3, width: 4, height: 4))
    t.ctx.clip(to: CGRect(x: 0, y: 0, width: 5, height: 5))
    expect(t.ctx.isPathEmpty,
           "矩形版 clip(to:) 根本用不着那条路径，可它照样给清了（isPathEmpty = \(t.ctx.isPathEmpty)）：别指望 clip 之后还能把原路径接着拿去 fill")
}

// ============================================================
line("\n== §10 描边：线宽居中、端帽与连接 ==")

do {
    func capDemo(_ cap: CGLineCap) -> RGBA {
        let s = Surface(12, 6)
        s.ctx.setStrokeColor(col(0, 0, 1))
        s.ctx.setLineWidth(3)
        s.ctx.setLineCap(cap)
        s.ctx.move(to: CGPoint(x: 6, y: 3))
        s.ctx.addLine(to: CGPoint(x: 6, y: 3))
        s.ctx.strokePath()
        return s.at(6, 3)
    }
    let round = capDemo(.round), butt = capDemo(.butt), square = capDemo(.square)
    line("  零长度线段（move 与 addLine 同一点）：round \(round)｜butt \(butt)｜square \(square)")
    expect(round.3 > 0 && butt.3 == 0 && square.3 > 0,
           "butt 帽不画零长度线段（圆点画不出来不是 bug，是帽型决定的）；要「一个点」就用 round 帽或直接填充小方块")

    func joinDemo(_ join: CGLineJoin, miter: CGFloat? = nil) -> (RGBA, RGBA) {
        let s = Surface(12, 12)
        s.ctx.setStrokeColor(col(1, 0, 0))
        s.ctx.setLineWidth(4)
        s.ctx.setLineJoin(join)
        if let m = miter { s.ctx.setMiterLimit(m) }
        s.ctx.move(to: CGPoint(x: 2, y: 2))
        s.ctx.addLine(to: CGPoint(x: 6, y: 6))
        s.ctx.addLine(to: CGPoint(x: 10, y: 2))
        s.ctx.strokePath()
        return (s.at(6, 7), s.at(6, 8))
    }
    let miter = joinDemo(.miter), bevel = joinDemo(.bevel), roundJ = joinDemo(.round)
    let capped = joinDemo(.miter, miter: 1.0)
    line("  折点外侧两格 (6,7)/(6,8)：miter \(miter.0) / \(miter.1)｜bevel \(bevel.0) / \(bevel.1)｜round \(roundJ.0) / \(roundJ.1)｜miterLimit=1 \(capped.0) / \(capped.1)")
    expect(miter.1.3 > 0 && bevel.1.3 == 0 && roundJ.1.3 == 0,
           "只有 miter 把尖角顶到 (6,8)（\(miter.1)），bevel 与 round 在那里都是空的（\(bevel.1) / \(roundJ.1)）：miter 是「两条外边延长到相交」，能顶到线宽之外")
    expect(miter.0.3 > 0 && bevel.0.3 > 0 && roundJ.0.3 > bevel.0.3,
           "折点紧外一格 (6,7)：三种连接都有墨，但 round 把转角垫成圆弧（\(roundJ.0)）比 bevel 切平的三角（\(bevel.0)）实得多，miter 在这里最满（\(miter.0)）—— 手绘轨迹线用 round 才没有毛刺")
    expect(capped.0 == bevel.0 && capped.1 == bevel.1,
           "同样的 miter，把 miterLimit 压到 1 之后与 bevel 逐字节相同（\(capped.0) / \(capped.1)）：夹角太尖、超出「对角线长/线宽」这个比值时，尖角直接改切成平角")

    let w = Surface(10, 10)
    w.ctx.setLineWidth(4)
    w.ctx.move(to: CGPoint(x: 1, y: 5)); w.ctx.addLine(to: CGPoint(x: 9, y: 5))
    w.ctx.replacePathWithStrokedPath()
    expect(abs(w.ctx.boundingBoxOfPath.minY - 3) < 0.01 && abs(w.ctx.boundingBoxOfPath.maxY - 7) < 0.01,
           "replacePathWithStrokedPath 把 4pt 的线变成 \(rectStr(w.ctx.boundingBoxOfPath)) 的细长矩形：描边「实体化」成可填充、可裁剪的路径")
    w.ctx.setFillColor(col(1, 0, 0))
    w.ctx.fillPath()
    expect(w.at(5, 5).3 == 255 && w.at(5, 7).3 == 0,
           "填充这条路径等于描一遍这条线（线内 \(w.at(5, 5))，线外 \(w.at(5, 7))）：同一份几何，两种用法")
}

// ============================================================
line("\n== §11 点线：图案是循环序列，phase 是相位 ==")

do {
    func dashCols(_ phase: CGFloat, _ lens: [CGFloat]) -> [Int] {
        let s = Surface(20, 6)
        s.ctx.setStrokeColor(col(1, 0, 0))
        s.ctx.setLineWidth(1)
        s.ctx.setLineDash(phase: phase, lengths: lens)
        s.ctx.move(to: CGPoint(x: 0, y: 2.5))
        s.ctx.addLine(to: CGPoint(x: 20, y: 2.5))
        s.ctx.strokePath()
        return (0..<20).filter { s.at($0, 2).3 > 200 }
    }
    let p0 = dashCols(0, [2, 2]), p1 = dashCols(1, [2, 2])
    line("  [2,2] phase=0 亮列 \(p0)")
    line("  [2,2] phase=1 亮列 \(p1)")
    expect(p0 == [0, 1, 4, 5, 8, 9, 12, 13, 16, 17],
           "数组按「实-空-实-空」交替、从实开始：两格实两格空，正好这 10 列")
    expect(p1 != p0 && p1.contains(4) && p1.contains(7),
           "phase=1 改变起点在图案中的位置（\(p1)）：蚂蚁线/进度虚线动画动的就是这个数，不是重画路径")
    let p5 = dashCols(5, [2, 2])
    expect(p5 == p1,
           "phase=5（超过图案总长 4）与 phase=1 完全一致：相位对图案总长取模，动画里累加 phase 不用担心溢出")
    let p3 = dashCols(0, [3, 1, 1, 1])
    line("  [3,1,1,1] 亮列 \(p3)")
    expect(p3 == [0, 1, 2, 4, 6, 7, 8, 10, 12, 13, 14, 16, 18, 19],
           "四个元素读作「实3 空1 实1 空1」循环，不是「三种线宽」：数组只描述沿路径的长度")
    let single = dashCols(0, [2])
    expect(single == p0,
           "只给一个元素 [2] 时结果与 [2,2] 完全一样（\(single)）：元素个数为奇数时 Quartz 把数组复制一份")
    let solid = dashCols(0, [])
    expect(solid.count == 20,
           "空数组 = 取消点线、回到实线（亮列数 \(solid.count)）：关掉虚线不是把参数设 0，是传空数组")
    let neg = dashCols(-1, [2, 2])
    expect(neg != p0,
           "负相位同样有效（\(neg)）：它等价于把图案往反方向挪，取模之后与 phase=0 不同")
    let zeroDash = dashCols(0, [0, 2])
    expect(zeroDash.isEmpty,
           "实长写 0、空写 2：整条线都在「空」里，一格墨都没有（\(zeroDash)）：配置里的 0 会悄悄把线画没")
    let longPhase = dashCols(0, [4, 1])
    expect(longPhase.prefix(4) == [0, 1, 2, 3],
           "[4,1] 的前四列 \(longPhase.prefix(4)) 是实段：段长单位是「用户空间长度」，会被 CTM 缩放（§8），不是像素")
}

// ============================================================
line("\n== §12 曲线、圆角与平面度 ==")

do {
    let s = Surface(12, 12)
    s.ctx.setStrokeColor(col(1, 0, 0))
    s.ctx.setLineWidth(1)
    s.ctx.move(to: CGPoint(x: 1, y: 1))
    s.ctx.addArc(tangent1End: CGPoint(x: 11, y: 1), tangent2End: CGPoint(x: 11, y: 11), radius: 3)
    s.ctx.addLine(to: CGPoint(x: 11, y: 11))
    s.ctx.strokePath()
    let sharp = Surface(12, 12)
    sharp.ctx.setStrokeColor(col(1, 0, 0))
    sharp.ctx.setLineWidth(1)
    sharp.ctx.move(to: CGPoint(x: 1, y: 1))
    sharp.ctx.addLine(to: CGPoint(x: 11, y: 1))
    sharp.ctx.addLine(to: CGPoint(x: 11, y: 11))
    sharp.ctx.strokePath()
    line("  拐角在 (11,1)、半径 3：圆弧与两条直边相切于 (8,1) 与 (11,4)，切点之间用弧顶替尖角")
    expect(sharp.at(10, 1).3 == 255 && s.at(10, 1) != sharp.at(10, 1),
           "紧挨拐角的 (10,1)：直边相连时是满墨（\(sharp.at(10, 1))），换成半径 3 的圆弧只剩 \(s.at(10, 1))：圆角把「尖角那一小块」让了出去")
    expect(s.at(9, 2).3 > 0 && sharp.at(9, 2).3 == 0,
           "反过来，弧会凸到直角折线的外侧：(9,2) 在直角版里是空的（\(sharp.at(9, 2))），圆角版里却有墨（\(s.at(9, 2))）—— 圆角不是「减一块」，是换一条曲线")
    expect(s.at(5, 1) == sharp.at(5, 1) && s.at(11, 6) == sharp.at(11, 6),
           "离拐角超过半径的地方逐字节相同（\(s.at(5, 1)) / \(s.at(11, 6))）：addArcToPoint 只重写拐角附近那一段，直边照原样")

    func arcEdge(_ flatness: CGFloat) -> Int {
        let c = Surface(12, 12)
        c.ctx.setFlatness(flatness)
        c.ctx.setFillColor(col(1, 0, 0))
        c.ctx.move(to: CGPoint(x: 6, y: 6))
        c.ctx.addArc(center: CGPoint(x: 6, y: 6), radius: 5,
                     startAngle: 0, endAngle: .pi / 2, clockwise: false)
        c.ctx.closePath()
        c.ctx.fillPath()
        return c.at(9, 9).3
    }
    let fine = arcEdge(0.001), coarse = arcEdge(5), zero = arcEdge(0)
    line("  1/4 圆弧扇形，取弦外侧那点 (9,9)：flatness=0.001 → alpha \(fine)｜flatness=5 → \(coarse)｜flatness=0 → \(zero)")
    expect(coarse < fine,
           "平面度越大、折线越糙，同一点被覆盖的程度就不同（\(coarse) < \(fine)）：flatness 是「曲线用多长的直线段去凑」的容差，单位是用户空间长度")
    expect(fine > 0 && fine < 255,
           "精细逼近下这点是半覆盖（\(fine)）：弧边正好从这一格切过去")
    expect(zero == fine,
           "flatness 传 0 与传 0.001 结果相同（\(zero)）：0 不是「无误差」，是退回默认精度 —— 想更精细得给正数")

    let e = Surface(12, 12)
    e.ctx.setFillColor(col(1, 0, 0))
    e.ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 10, height: 10))
    expect(e.at(6, 6).3 == 255 && e.at(1, 1).3 == 0 && e.at(1, 6).3 > 200,
           "内切椭圆：中心满色（\(e.at(6, 6))）、方框角落空（\(e.at(1, 1))）、边中贴线处有色（\(e.at(1, 6))）：fillEllipse 只是「加椭圆路径 + 填充」的快捷写法")
    let ell = Surface(12, 12)
    ell.ctx.addEllipse(in: CGRect(x: 1, y: 1, width: 10, height: 10))
    expect(abs(ell.ctx.boundingBoxOfPath.width - 10) < 0.1,
           "椭圆路径的 bbox = \(rectStr(ell.ctx.boundingBoxOfPath))：贝塞尔凑出来的圆，包围盒与几何外接矩形差在小数点后（这就是 4 段近似的精度）")
}

// ============================================================
line("\n== §13 状态栈：save/restore 搬动了什么 ==")

do {
    let s = Surface(8, 8)
    expect(s.ctx.ctm.isIdentity,
           "新建上下文的 CTM 是单位阵（\(ctmStr(s.ctx.ctm))）：所有「原点变了」都是你自己乘上去的")
    expect(s.ctx.boundingBoxOfClipPath == CGRect(x: 0, y: 0, width: 8, height: 8),
           "新建上下文的裁剪区默认就是整幅：\(rectStr(s.ctx.boundingBoxOfClipPath))")
    s.ctx.saveGState()
    s.ctx.translateBy(x: 0, y: 8)
    s.ctx.scaleBy(x: 1, y: -1)
    s.ctx.clip(to: CGRect(x: 1, y: 1, width: 2, height: 2))
    s.ctx.setAlpha(0.5)
    s.ctx.setBlendMode(.destinationOut)
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let inside = s.mem(1, 1)
    s.ctx.restoreGState()
    expect(s.ctx.ctm.isIdentity,
           "restore 把 CTM 收了回来（现在 \(ctmStr(s.ctx.ctm))）：栈里存的是「变换 + 裁剪区 + 全部绘制参数」整包，不是只有颜色")
    expect(inside == (0, 0, 0, 0),
           "save 段里那一笔确实是在「擦」（\(inside)）：.destinationOut + 翻转 + 小裁剪三条状态同时生效，出栈后一起消失")
    s.ctx.setFillColor(col(0, 0, 1))
    s.ctx.fill(CGRect(x: 6, y: 6, width: 2, height: 2))
    expect(s.at(6, 6) == (0, 0, 255, 255),
           "restore 之后 alpha 与混合模式也回到 save 时的值：这一笔正常上色（\(s.at(6, 6))），没被擦掉")
}

do {
    let s = Surface(8, 8)
    s.ctx.saveGState()
    s.ctx.clip(to: CGRect(x: 1, y: 1, width: 6, height: 6))
    s.ctx.saveGState()
    s.ctx.clip(to: CGRect(x: 3, y: 3, width: 2, height: 2))
    s.ctx.setFillColor(col(0, 0, 1))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let inner = s.inkPixels()
    s.ctx.restoreGState()
    s.ctx.setFillColor(col(1, 1, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let middle = s.inkPixels()
    s.ctx.restoreGState()
    s.ctx.setFillColor(col(0, 1, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let outer = s.inkPixels()
    line("  两层 save + 两次收紧裁剪，再一层层退回来：内层墨量 \(inner) → 退一层 \(middle) → 退到底 \(outer)")
    expect(inner == 4 && middle == 36 && outer == 64,
           "墨量分别是 \(inner)/\(middle)/\(outer)：restore 一次只退一层，裁剪区回到「上一个 save 时的收紧结果」—— LIFO，不是「回到干净状态」")
    expect(s.ctx.boundingBoxOfClipPath == CGRect(x: 0, y: 0, width: 8, height: 8),
           "两次 restore 配平后裁剪区回到整幅（\(rectStr(s.ctx.boundingBoxOfClipPath))）：save/restore 不配对，裁剪就会一路漏到后面的绘制里")
}

// ============================================================
line("\n== §14 全局 alpha 与透明层：图层是用来消「接缝」的 ==")

do {
    let s = Surface(4, 1)
    s.ctx.setAlpha(0.5)
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
    expect(s.at(0, 0) == (128, 0, 0, 128),
           "setAlpha(0.5) × 不透明红 = \(s.at(0, 0))：全局 alpha 与颜色 alpha 相乘，且写进缓冲时已经预乘")
    expect(s.at(3, 0) == (0, 0, 0, 0),
           "没画到的地方仍是 (0,0,0,0)：全局 alpha 不会凭空上色，它只缩放你要画的东西")

    func seam(_ useLayer: Bool) -> [RGBA] {
        let c = Surface(12, 6)
        c.ctx.setFillColor(col(1, 0, 0))
        c.ctx.fill(CGRect(x: 0, y: 0, width: 12, height: 6))
        c.ctx.setAlpha(0.5)
        if useLayer { c.ctx.beginTransparencyLayer(auxiliaryInfo: nil) }
        c.ctx.setFillColor(col(0, 0, 1))
        c.ctx.fill(CGRect(x: 1, y: 1, width: 5, height: 4))
        c.ctx.fill(CGRect(x: 4, y: 1, width: 5, height: 4))
        if useLayer { c.ctx.endTransparencyLayer() }
        return [c.at(2, 2), c.at(5, 2), c.at(10, 2)]
    }
    let noLayer = seam(false), withLayer = seam(true)
    line("  进层前 alpha 0.5，两块半透明蓝首尾相接 —— 不开图层：单块 \(noLayer[0]) 重叠 \(noLayer[1])")
    line("  \u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}\u{3000}开图层：单块 \(withLayer[0]) 重叠 \(withLayer[1])")
    expect(noLayer[0] != noLayer[1],
           "不开图层时重叠处更深（\(noLayer[1]) ≠ \(noLayer[0])）：每一笔各自与底图合成，接缝就露出来了")
    expect(withLayer[0] == withLayer[1],
           "开图层后两处一致（\(withLayer[0])）：层内的笔先彼此合成成一张完整的图，最后整层一次性贴到底上")
    expect(withLayer[2] == (255, 0, 0, 255),
           "层外的底色一点没被影响（\(withLayer[2])）：透明层是一块临时画布，不是在图层树上加了个节点")

    let q = Surface(12, 6)
    q.ctx.setFillColor(col(1, 0, 0))
    q.ctx.fill(CGRect(x: 0, y: 0, width: 12, height: 6))
    q.ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    q.ctx.setAlpha(0.25)
    q.ctx.setFillColor(col(0, 0, 1))
    q.ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 2))
    q.ctx.endTransparencyLayer()
    line("  进层前不设 alpha、层内设 0.25：结果 \(q.at(3, 3))")
    let rgb = q.at(3, 3)
    expect(rgb != (255, 0, 0, 255) && rgb.0 > 150 && rgb.2 < 128,
           "出层时按「进层之前」的 alpha（这里是 1）整层合成，层内的 0.25 只参与层内合成：层里那块淡淡的蓝整层原样贴下来，红底还剩红通道 \(rgb.0)、蓝通道只到 \(rgb.2)，并不是被一层不透明的蓝盖掉")
    expect(rgb == (191, 0, 64, 255),
           "字节可算：层内 0.25 的蓝先落在透明的层底上（预乘后仍是 0,0,64，alpha 64/255≈0.25），出层时按外层 alpha 1 与红底合成 → 255×0.75=\(rgb.0)、0+0=\(rgb.1)、0+64=\(rgb.2)")
    expect(q.ctx.ctm.isIdentity,
           "begin/endTransparencyLayer 不改 CTM（\(ctmStr(q.ctx.ctm))）：它是「离屏合成」，不是「开一个子坐标系」")
}

// ============================================================
line("\n== §15 混合模式：公式作用在逐通道的字节上 ==")

do {
    let s = Surface(8, 4)
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 4))
    let modes: [(String, CGBlendMode, (CGFloat, CGFloat, CGFloat))] = [
        ("multiply", .multiply, (0, 1, 0)),
        ("screen", .screen, (0, 0, 1)),
        ("darken", .darken, (0, 1, 0)),
        ("lighten", .lighten, (0, 0, 1)),
        ("difference", .difference, (0, 1, 0)),
        ("plusLighter", .plusLighter, (0, 0, 1)),
        ("overlay", .overlay, (0, 0, 1)),
        ("color", .color, (0, 1, 0)),
    ]
    for (i, item) in modes.enumerated() {
        s.ctx.setBlendMode(item.1)
        s.ctx.setFillColor(col(item.2.0, item.2.1, item.2.2))
        s.ctx.fill(CGRect(x: i, y: 0, width: 1, height: 4))
    }
    s.ctx.setBlendMode(.normal)
    for (i, item) in modes.enumerated() {
        line("  底是纯红，源 \(item.2) 用 \(item.0) → \(s.at(i, 2))")
    }
    expect(s.at(0, 2) == (0, 0, 0, 255),
           "multiply（红 × 绿）= \(s.at(0, 2))：逐通道相乘，任何色与黑相乘得黑 —— 阴影/叠暗角用它")
    expect(s.at(1, 2) == (255, 0, 255, 255),
           "screen（红 + 蓝）= \(s.at(1, 2))：反相再相乘，任何色与白相加得白 —— 光效/发光用它")
    expect(s.at(2, 2) == (0, 0, 0, 255) && s.at(3, 2) == (255, 0, 255, 255),
           "darken 取逐通道较小值（\(s.at(2, 2))）、lighten 取较大值（\(s.at(3, 2))）：这俩不是「稍微暗一点/亮一点」，是 min/max")
    expect(s.at(4, 2) == (255, 255, 0, 255),
           "difference = |底 − 源| 逐通道（\(s.at(4, 2))）：同色相减得黑，「反色重影」「对位检查」特效的骨架")
    expect(s.at(5, 2) == (255, 0, 255, 255),
           "plusLighter 是相加并截断（\(s.at(5, 2))）：这一例与 screen 结果撞车，公式其实不同（screen 是 1−(1−a)(1−b)），换个源色就分道")
    expect(s.at(6, 2) == (255, 0, 0, 255),
           "overlay 以底的明暗为条件（\(s.at(6, 2))）：底是纯红（亮）时走 dodge 分支，源的蓝几乎没进来")
    expect(s.at(7, 2) != (0, 255, 0, 255),
           "color 只带走源的色相与饱和、明度留自底（\(s.at(7, 2))）：调色类滤镜用它，别用 sourceOver 硬盖")

    let e = Surface(8, 8)
    e.ctx.setFillColor(col(1, 0, 0))
    e.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    e.ctx.setBlendMode(.destinationOut)
    e.ctx.setFillColor(col(0, 0, 0))
    e.ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
    e.ctx.setBlendMode(.normal)
    expect(e.at(4, 4) == (0, 0, 0, 0) && e.at(1, 1).3 == 255,
           "destinationOut：源只当「橡皮的形状」用，把底擦穿（\(e.at(4, 4))），没碰的地方保持原样（\(e.at(1, 1))）—— 抠洞、生成 mask 图靠它")
    let f = Surface(8, 8)
    f.ctx.setFillColor(col(1, 0, 0))
    f.ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    f.ctx.setBlendMode(.clear)
    f.ctx.setFillColor(col(0, 0, 1))
    f.ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
    expect(f.at(4, 4) == (0, 0, 0, 0),
           ".clear 与 clear() 殊途同归（\(f.at(4, 4))）：区别是 .clear 受当前路径/裁剪/alpha 约束，clear() 只吃矩形")

    let g = Surface(4, 2)
    g.ctx.setFillColor(col(1, 0, 0, 0.5))
    g.ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 2))
    g.ctx.setBlendMode(.copy)
    g.ctx.setFillColor(col(0, 0, 1, 0.5))
    g.ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
    g.ctx.setBlendMode(.destinationIn)
    g.ctx.setFillColor(col(0, 1, 0))
    g.ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 2))
    g.ctx.setBlendMode(.sourceAtop)
    g.ctx.setFillColor(col(1, 1, 0))
    g.ctx.fill(CGRect(x: 2, y: 0, width: 1, height: 2))
    g.ctx.setBlendMode(.normal)
    line("  底色是 50% 红（没被碰的第 3 列 = \(g.at(3, 1))）")
    expect(g.at(0, 1) == (0, 0, 128, 128),
           ".copy 连底下的像素一起丢掉、只留源（\(g.at(0, 1))）：整幅刷新时先 copy 可以省一次清屏")
    expect(g.at(1, 1) == (128, 0, 0, 128),
           ".destinationIn 保留底色的色与 alpha、按源的 alpha 裁形（\(g.at(1, 1))）：给图形套形状蒙版的经典一笔")
    expect(g.at(2, 1) == (128, 128, 0, 128),
           ".sourceAtop 把源染进底已有的 alpha 区（\(g.at(2, 1))）：图标染色、渐变内填色用它")
}

// ============================================================
line("\n== §16 阴影：偏移实测走设备轴 ==")

do {
    let s = Surface(20, 20)
    s.primeWhite()
    s.ctx.setShadow(offset: CGSize(width: 3, height: 3), blur: 0, color: col(0, 0, 0, 1))
    s.ctx.setFillColor(col(1, 0, 0))
    s.ctx.fill(CGRect(x: 5, y: 5, width: 5, height: 5))
    expect(s.at(7, 7) == (255, 0, 0, 255),
           "形状自己（用户 (7,7)）还是红：\(s.at(7, 7))")
    expect(s.at(11, 11) == (0, 0, 0, 255) && s.at(3, 3) == (255, 255, 255, 255),
           "不翻转时 offset=(3,3) 的影落在 +y 那一侧：\(s.at(11, 11)) / 反方向 \(s.at(3, 3))")
    expect(s.at(8, 8) == (255, 0, 0, 255),
           "形状与影重叠的那格是纯红（\(s.at(8, 8))）：同一条绘制指令里阴影先画、形状后压，重叠处不会被影盖住")

    let t = Surface(20, 20)
    t.ctx.translateBy(x: 0, y: 20)
    t.ctx.scaleBy(x: 1, y: -1)
    t.ctx.setFillColor(col(1, 1, 1))
    t.ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
    t.ctx.setShadow(offset: CGSize(width: 3, height: 3), blur: 0, color: col(0, 0, 0, 1))
    t.ctx.setFillColor(col(1, 0, 0))
    t.ctx.fill(CGRect(x: 5, y: 5, width: 5, height: 5))
    expect(t.mem(7, 7) == (255, 0, 0, 255),
           "翻转后同一条绘制指令，形状落在内存行 5..9（行 7 = \(t.mem(7, 7))）")
    expect(t.mem(11, 4) == (0, 0, 0, 255) && t.mem(11, 11) == (255, 255, 255, 255),
           "可阴影落在内存行 4（\(t.mem(11, 4))）而不是行 11（\(t.mem(11, 11))）：偏移不跟着 CTM 的翻转走，它是加在设备轴上的")
    line("  实践含义：在 UIKit 的 draw(_:) 里写正的 y 偏移，屏幕上的阴影是「往上」的；这与 CALayer.shadowOffset 的方向直觉相反")

    let u = Surface(16, 16)
    u.primeWhite()
    u.ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 4, color: col(0, 0, 1, 0.5))
    u.ctx.setFillColor(col(1, 0, 0))
    u.ctx.fill(CGRect(x: 6, y: 6, width: 4, height: 4))
    expect(u.at(8, 8) == (255, 0, 0, 255),
           "blur 不改变形状自身（\(u.at(8, 8))）：扩散的是影，不是被画的图")
    expect(u.at(4, 8).3 == 255 && u.at(4, 8).2 > 200,
           "中心外扩 3 格还有蓝影（\(u.at(4, 8))）：blur 是高斯扩散，没有硬边界但有作用半径")
    expect(u.at(0, 8) == (255, 255, 255, 255),
           "外扩 8 格已经完全干净（\(u.at(0, 8))）：blur 的代价是「脏区要往外扩」，绘制矩形与缓存尺寸都得算上这个半径")

    let v = Surface(24, 12)
    v.primeWhite()
    v.ctx.saveGState()
    v.ctx.setShadow(offset: CGSize(width: 1, height: 1), blur: 0, color: col(0, 0, 0, 0.5))
    v.ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    v.ctx.setLineWidth(3)
    v.ctx.setStrokeColor(col(1, 0, 0))
    v.ctx.stroke(CGRect(x: 3, y: 3, width: 8, height: 6))
    v.ctx.stroke(CGRect(x: 6, y: 5, width: 8, height: 6))
    v.ctx.endTransparencyLayer()
    v.ctx.restoreGState()
    expect(v.at(9, 8) == (255, 0, 0, 255) && v.at(12, 3) != (255, 0, 0, 255),
           "阴影 + 透明层：层内两笔重叠处是干净的一层红（\(v.at(9, 8))），阴影按「整层轮廓」只出现一次（\(v.at(12, 3))）—— 逐笔画阴影会叠成脏块，图层是标准解法")

    let w = Surface(16, 16)
    w.primeWhite()
    w.ctx.setShadow(offset: CGSize(width: 2, height: 2), blur: 0)
    w.ctx.setFillColor(col(1, 0, 0))
    w.ctx.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
    let w2 = Surface(16, 16)
    w2.primeWhite()
    w2.ctx.setShadow(offset: CGSize(width: 2, height: 2), blur: 0, color: col(0, 0, 0, 1.0 / 3.0))
    w2.ctx.setFillColor(col(1, 0, 0))
    w2.ctx.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
    expect(w.at(8, 8) != (255, 255, 255, 255),
           "不给 color 时阴影有默认值（纯影区 \(w.at(8, 8))）：「不传参数」不等于「没有阴影」")
    expect(w.at(8, 8) == w2.at(8, 8),
           "默认阴影就是「黑、alpha 约 1/3」：与手工传 black 0.333 的结果逐字节相同（\(w.at(8, 8))）")
    expect(w.at(5, 5) == (255, 0, 0, 255),
           "默认影与形状重叠处同样是干净的红（\(w.at(5, 5))）：半透明的影也一样，形状永远压在自家阴影之上")
}

// ============================================================
line("\n== §17 梯度：位置、扩展选项与停靠点 ==")

do {
    let grad = CGGradient(colorsSpace: cs,
                          colors: [col(1, 0, 0, 1), col(0, 0, 1, 1)] as CFArray,
                          locations: [0, 1])!
    let s = Surface(20, 4)
    s.ctx.drawLinearGradient(grad, start: CGPoint(x: 5, y: 2), end: CGPoint(x: 15, y: 2), options: [])
    line("  无扩展：x=1 \(s.at(1, 2))｜起点格 x=5 \(s.at(5, 2))｜中点 x=10 \(s.at(10, 2))｜终点格 x=15 \(s.at(15, 2))")
    expect(s.at(1, 2) == (0, 0, 0, 0) && s.at(15, 2) == (0, 0, 0, 0),
           "起止点之外一格都不画（\(s.at(1, 2)) / \(s.at(15, 2))）：默认「只在两段之间插值」，两端是留白的")
    expect(s.at(5, 2).0 > 240 && s.at(5, 2).2 < 30,
           "起点那一格读回 \(s.at(5, 2))，不是纯粹的 (255,0,0,255)：因为采样取的是像素中心 (5.5)，它已经在梯度里走了 5% —— 这就是「边界差半格」的来处")
    expect(s.at(10, 2).0 > 100 && s.at(10, 2).2 > 100,
           "中点是两头混合（\(s.at(10, 2))）：插值发生在色空间分量上，所以中间会出现「脏紫」，需要时得加停靠点")
    expect(s.at(14, 2).2 > 200 && s.at(14, 2).0 < 30,
           "接近终点就基本是蓝（\(s.at(14, 2))）：位置参数是几何坐标，不是百分比")

    let t = Surface(20, 4)
    t.ctx.drawLinearGradient(grad, start: CGPoint(x: 5, y: 2), end: CGPoint(x: 15, y: 2),
                             options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    expect(t.at(1, 2) == (255, 0, 0, 255) && t.at(18, 2) == (0, 0, 255, 255),
           "加上两个扩展选项，两端用端点色平铺（\(t.at(1, 2)) / \(t.at(18, 2))）：整幅背景梯度一定要记得开，否则边缘是透明的")

    let rad = CGGradient(colorsSpace: cs,
                         colors: [col(1, 0, 0, 1), col(0, 0, 1, 1)] as CFArray,
                         locations: [0, 1])!
    let r = Surface(20, 20)
    r.ctx.drawRadialGradient(rad, startCenter: CGPoint(x: 10, y: 10), startRadius: 0,
                             endCenter: CGPoint(x: 10, y: 10), endRadius: 5,
                             options: [.drawsAfterEndLocation])
    expect(r.at(10, 10).0 > 200 && r.at(10, 10).2 < 60,
           "起始半径 0 → 圆心就是起始色（\(r.at(10, 10))）：半径给 0 是「实心球」的写法，负半径非法")
    expect(r.at(18, 10).2 > 200,
           "半径 5 之外被尾扩展填成结束色（\(r.at(18, 10))）：两个圆心/半径不相同时得到「偏心球」，那是另一种高光做法")

    let three = CGGradient(colorsSpace: cs,
                           colors: [col(1, 0, 0, 1), col(0, 1, 0, 1), col(0, 0, 1, 1)] as CFArray,
                           locations: [0, 0.9, 1])!
    let q = Surface(10, 1)
    q.ctx.drawLinearGradient(three, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0),
                             options: [.drawsAfterEndLocation])
    line("  停靠点 [0, 0.9, 1]：x=0 \(q.at(0, 0))｜x=4 \(q.at(4, 0))｜x=9 \(q.at(9, 0))")
    expect(q.at(4, 0).1 > 80 && q.at(9, 0).2 > q.at(0, 0).2,
           "绿被挤到 90% 之后：x=4 已经明显偏绿（\(q.at(4, 0))），x=9 才开始转蓝（\(q.at(9, 0))）—— 停靠点决定「色变发生在哪一段长度上」")

    let ring = CGGradient(colorsSpace: cs,
                          colors: [col(1, 0, 0, 1), col(1, 0, 0, 0), col(0, 0, 1, 1)] as CFArray,
                          locations: [0, 0.5, 1])!
    let h = Surface(20, 20)
    h.ctx.drawRadialGradient(ring, startCenter: CGPoint(x: 10, y: 10), startRadius: 0,
                             endCenter: CGPoint(x: 10, y: 10), endRadius: 10, options: [])
    expect(h.at(10, 10).0 > 200 && h.at(10, 10).3 > 200,
           "圆心是不透明红（\(h.at(10, 10))）：alpha 与颜色一样是被插值的通道")
    expect(h.at(10, 5).3 < 60,
           "半径一半处（(10,5) 距圆心 5）几乎全透明（\(h.at(10, 5))）：这就是「中间停靠点 alpha=0」造出的光环/暗角")
    expect(h.at(19, 19) == (0, 0, 0, 0),
           "半径外的角落完全透明（\(h.at(19, 19))）：不开扩展选项时，梯度是一支「有形状的笔」，不是矩形背景")
}

// ============================================================
line("\n== §18 文本：CGContext 的文本 API 在 iOS 不可用，改用 CoreText ==")

do {
    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12),
                                                .foregroundColor: UIColor.black]
    let latin = CTLineCreateWithAttributedString(NSAttributedString(string: "Hi", attributes: attrs))
    let s = Surface(60, 20)
    s.primeWhite()
    s.ctx.textMatrix = .identity
    s.ctx.textPosition = CGPoint(x: 2, y: 6)
    CTLineDraw(latin, s.ctx)
    let darkLatin = (0..<20).reduce(0) { acc, y in acc + (0..<60).filter { s.at($0, y).0 < 128 }.count }
    let wLatin = CGFloat(CTLineGetTypographicBounds(latin, nil, nil, nil))
    line("  CTLineDraw(\"Hi\", 12pt)：暗像素 \(darkLatin) 个，排版宽 \(fmt(wLatin))pt")
    expect(darkLatin > 0,
           "CTLineDraw 直接画进了位图上下文（暗像素 \(darkLatin) > 0）：画前把 textMatrix 归 identity、textPosition 设成基线原点")
    expect(wLatin > 8 && wLatin < 20,
           "「Hi」排版宽 = \(fmt(wLatin))pt：这是排版宽度（含字距），既不是字形包围盒也不是整数，别直接当 UILabel 尺寸用")

    let cjk = CTLineCreateWithAttributedString(NSAttributedString(
        string: "中文", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.black]))
    let t = Surface(60, 20)
    t.primeWhite()
    t.ctx.textMatrix = .identity
    t.ctx.textPosition = CGPoint(x: 2, y: 4)
    CTLineDraw(cjk, t.ctx)
    let darkCJK = (0..<20).reduce(0) { acc, y in acc + (0..<60).filter { t.at($0, y).0 < 128 }.count }
    let wCJK = CGFloat(CTLineGetTypographicBounds(cjk, nil, nil, nil))
    line("  CTLineDraw(\"中文\", 14pt)：暗像素 \(darkCJK) 个，排版宽 \(fmt(wCJK))pt")
    expect(darkCJK > darkLatin,
           "汉字笔画密，同尺寸下墨量更大（\(darkCJK) > \(darkLatin)）：墨像素只能相对比较，绝对值随字体版本变，别写进断言")
    expect(abs(wCJK - 28) < 1.5,
           "两个 14pt 汉字的排版宽 ≈ \(fmt(wCJK))，接近 2×字号：CJK 的推进宽度大致等于字号，拉丁完全不行")

    let mb = NSMutableAttributedString(string: "红蓝",
                                       attributes: [.font: UIFont.systemFont(ofSize: 14)])
    mb.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 1))
    mb.addAttribute(.foregroundColor, value: UIColor.blue, range: NSRange(location: 1, length: 1))
    let mixed = CTLineCreateWithAttributedString(mb)
    let m = Surface(40, 20)
    m.primeWhite()
    m.ctx.textMatrix = .identity
    m.ctx.textPosition = CGPoint(x: 1, y: 2)
    CTLineDraw(mixed, m.ctx)
    var redPx = 0, bluePx = 0
    for y in 0..<20 {
        for x in 0..<40 {
            let p = m.at(x, y)
            if p.0 > 200 && p.2 < 100 { redPx += 1 }
            if p.2 > 200 && p.0 < 100 { bluePx += 1 }
        }
    }
    expect(redPx > 0 && bluePx > 0,
           "一段属性串里的逐段前景色被 CTLine 完整保留（红字 \(redPx) 格、蓝字 \(bluePx) 格）：富文本画进 CGContext 走的就是这条路")
    expect(CTLineGetGlyphCount(mixed) == 2,
           "CTLineGetGlyphCount = \(CTLineGetGlyphCount(mixed))：两个字两个字形。这里 1:1 只是中文的情况，连写字母会裂成多个字形")

    let u = Surface(60, 20)
    u.primeWhite()
    UIGraphicsPushContext(u.ctx)
    ("Hi" as NSString).draw(at: CGPoint(x: 2, y: 4), withAttributes: attrs)
    UIGraphicsPopContext()
    let darkUI = (0..<20).reduce(0) { acc, y in acc + (0..<60).filter { u.at($0, y).0 < 128 }.count }
    expect(darkUI > 0,
           "把 UIKit 上下文推进去之后，NSString.draw(at:) 也落到同一块缓冲区（暗像素 \(darkUI)）：UIKit 的文本 API 只是 CoreText 的包装")
    expect(darkUI != darkLatin,
           "同一段文字两条路径的墨量不同（CoreText \(darkLatin) / UIKit \(darkUI)）：差别在坐标系 —— 后者把 y=4 解释成「距顶 4」，字形落到了别的行上")

    let v = Surface(60, 20)
    v.primeWhite()
    UIGraphicsPushContext(v.ctx)
    ("Hello world" as NSString).draw(in: CGRect(x: 2, y: 2, width: 20, height: 18), withAttributes: attrs)
    UIGraphicsPopContext()
    let narrow = v.darkPixels()
    v.ctx.setFillColor(col(1, 1, 1))
    v.ctx.fill(CGRect(x: 0, y: 0, width: 60, height: 20))
    UIGraphicsPushContext(v.ctx)
    ("Hello world" as NSString).draw(in: CGRect(x: 2, y: 2, width: 56, height: 18), withAttributes: attrs)
    UIGraphicsPopContext()
    let wide = v.darkPixels()
    expect(wide > narrow,
           "窄矩形里 draw(in:) 会折行/截断（墨量 \(narrow)），给足宽度就变成 \(wide)：文本的占地永远是被框约束出来的")
    let typoWidth = CTLineGetTypographicBounds(latin, nil, nil, nil)
    line("  「Hi」在 12pt 下的排版宽 = \(fmt(typoWidth))，下面按 60 宽的框算三种对齐")
    let flushLeft = CTLineGetPenOffsetForFlush(latin, 0, 60)
    let flushMiddle = CTLineGetPenOffsetForFlush(latin, 0.5, 60)
    let flushRight = CTLineGetPenOffsetForFlush(latin, 1, 60)
    expect(flushLeft == 0 && abs(flushMiddle - flushRight / 2) < 0.01,
           "CTLineGetPenOffsetForFlush 给的是「起笔 x 相对框左边要挪多少」：flush 0 → \(fmt(abs(flushLeft)))、0.5 → \(fmt(flushMiddle))、1 → \(fmt(flushRight))，也就是 60 减排版宽之后的 0、一半、全量。做右对齐的「¥ 12.00」这类手动排版就靠它 —— 注意它只管横向，行与行的纵向距离还得自己按 ascender/descender/leading 累加")
    expect(abs(flushRight - (60 - typoWidth)) < 0.01,
           "右对齐的偏移量恰好是框宽减排版宽（\(fmt(flushRight)) = 60 − \(fmt(typoWidth))）：排版宽包含行尾空白，所以「看着没对齐」常常是这一位差")
}

// ============================================================
line("\n== §19 图像：CGImage、UIImage、插值与平铺 ==")

do {
    let s = Surface(16, 8)
    s.ctx.setFillColor(col(0.5, 0.25, 1))
    s.ctx.fill(CGRect(x: 0, y: 0, width: 16, height: 8))
    let img = s.image
    line("  makeImage()：\(img.width)×\(img.height) bpc=\(img.bitsPerComponent) bpp=\(img.bitsPerPixel) bytesPerRow=\(img.bytesPerRow) alphaInfo=\(img.alphaInfo.rawValue)")
    expect(img.width == 16 && img.height == 8 && img.bitsPerPixel == 32,
           "同一块缓冲区变成不可变的 CGImage：尺寸来自上下文，位深来自 bitmapInfo（\(img.bitsPerPixel) bpp）")
    expect(img.alphaInfo == .premultipliedLast,
           "alphaInfo 回读 \(img.alphaInfo.rawValue)（1 = premultipliedLast）：CGImage 把「alpha 怎么摆」写进了元数据，读像素之前必须先看它")
    let p = px(img, 3, 2)
    expect(abs(p.0 - 128) <= 1 && abs(p.1 - 64) <= 1 && p.2 == 255 && p.3 == 255,
           "按 CGImage 自己的行距读回 (3,2) = \(p)：分量 (0.5, 0.25, 1) 对应 (128, 64, 255)，转换有 ±1 的取整抖动")
    let ui = UIImage(cgImage: img)
    expect(ui.size == CGSize(width: 16, height: 8) && ui.scale == 1,
           "UIImage(cgImage:) 默认 scale=1，size 按「1 点 = 1 像素」给（\(ui.size.width)×\(ui.size.height)）：@2x 素材必须显式传 scale，否则界面里会大一倍")
    let ui2 = UIImage(cgImage: img, scale: 2, orientation: .up)
    expect(ui2.size == CGSize(width: 8, height: 4) && ui2.cgImage?.width == 16,
           "scale=2 时 size 变 \(ui2.size.width)×\(ui2.size.height)，像素仍是 \(ui2.cgImage?.width ?? 0) 宽：UIImage 的 size 是点，两者靠 scale 换算")

    let small = Surface(2, 2)
    small.ctx.setFillColor(col(1, 0, 0))
    small.ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
    small.ctx.setFillColor(col(0, 0, 1))
    small.ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 2))
    let tiny = small.image
    func upscale(_ q: CGInterpolationQuality) -> [RGBA] {
        let c = Surface(8, 8)
        c.ctx.interpolationQuality = q
        c.ctx.draw(tiny, in: CGRect(x: 0, y: 0, width: 8, height: 8))
        return [c.at(0, 4), c.at(3, 4), c.at(4, 4), c.at(7, 4)]
    }
    let hard = upscale(.none), soft = upscale(.high)
    line("  2×2 放大到 8×8 —— .none \(hard)")
    line("  \u{3000}\u{3000}\u{3000}\u{3000}\u{3000}    .high \(soft)")
    expect(hard.allSatisfy { $0 == (255, 0, 0, 255) || $0 == (0, 0, 255, 255) },
           ".none（最近邻）只搬运原色：\(hard) 里只有红蓝两种，边缘硬 —— 像素画、色块图必用")
    expect(soft.contains { $0 != (255, 0, 0, 255) && $0 != (0, 0, 255, 255) },
           ".high 在接缝处混出第三种颜色（\(soft[1])）：照片要平滑就付这个代价，UI 图标混了色就变脏")

    let tile = Surface(4, 1)
    for i in 0..<4 {
        tile.ctx.setFillColor(i.isMultiple(of: 2) ? col(1, 0, 0) : col(0, 0, 1))
        tile.ctx.fill(CGRect(x: CGFloat(i), y: 0, width: 1, height: 1))
    }
    let tileImg = tile.image
    func rowAt(_ rect: CGRect) -> String {
        let c = Surface(12, 3)
        c.ctx.draw(tileImg, in: rect, byTiling: true)
        return (0..<12).map { x in
            let q = c.at(x, 1)
            return q.3 < 40 ? "-" : (q.2 > 128 ? "b" : "r")
        }.joined()
    }
    let baseRow = rowAt(CGRect(x: 0, y: 0, width: 4, height: 3))
    let shiftRow = rowAt(CGRect(x: 1, y: 0, width: 4, height: 3))
    let oddRow = rowAt(CGRect(x: 0, y: 0, width: 5, height: 3))
    line("  byTiling，目标矩形 (0,0,4,3) → \(baseRow)")
    line("  byTiling，目标矩形 (1,0,4,3) → \(shiftRow)")
    line("  byTiling，目标矩形 (0,0,5,3) → \(oddRow)")
    expect(baseRow == "rbrbrbrbrbrb",
           "平铺结果每 4 列重复一次源（\(baseRow)）：瓦片的尺寸就是「目标矩形」的尺寸，而且铺满整个裁剪区、不只铺那个矩形")
    expect(shiftRow != baseRow,
           "目标矩形起点挪 1，整幅图案跟着相位走（\(shiftRow)）：平铺以目标矩形为原点，不是以画布原点")
    expect(oddRow.contains("rr") || oddRow.contains("bb"),
           "把瓦片拉成 5 宽，图案被拉伸并出现同色相邻（\(oddRow)）：byTiling 不做整数对齐，瓦片尺寸要给对")
}

do {
    let f = UIGraphicsImageRendererFormat()
    f.scale = 1
    f.opaque = true
    let img = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: f).image { rc in
        rc.cgContext.setFillColor(col(1, 0, 0))
        rc.cgContext.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }
    expect(img.cgImage!.alphaInfo == .noneSkipLast,
           "format.opaque = true 让 CG 省掉 alpha 通道：alphaInfo = \(img.cgImage!.alphaInfo.rawValue)（4 = noneSkipLast）—— 不需要透明的整屏背景该开，省内存也省合成")
    let header = img.pngData()!.prefix(8).map { Int($0) }
    expect(header == [137, 80, 78, 71, 13, 10, 26, 10],
           "PNG 前 8 字节 = \(header)（137 + \"PNG\" + 三个控制字节）：识别图片格式看文件头，不看扩展名")
    let jpg = img.jpegData(compressionQuality: 1)!
    let jhead = jpg.prefix(2).map { Int($0) }, jtail = jpg.suffix(2).map { Int($0) }
    expect(jhead == [255, 216] && jtail == [255, 217],
           "JPEG 头 \(jhead) 尾 \(jtail)（FFD8 / FFD9）：SOI 与 EOI 两个标记，缺尾就是截断文件")

    let half = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { rc in
        rc.cgContext.clear(CGRect(x: 0, y: 0, width: 4, height: 4))
        rc.cgContext.setFillColor(col(1, 0, 0, 0.5))
        rc.cgContext.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }
    let pngBack = UIImage(data: half.pngData()!)!
    let jpgBack = UIImage(data: half.jpegData(compressionQuality: 1)!)!
    let pa = px(pngBack.cgImage!, 0, 0), ja = px(jpgBack.cgImage!, 0, 0)
    expect(pa.3 < 255,
           "同一张半透明图存 PNG 再读回：首像素 \(pa)，alpha 还在（无损 + 透明是 PNG 的地盘）")
    expect(ja.3 == 255 && ja.0 > 200,
           "存 JPEG 再读回：首像素 \(ja)，alpha 被拍平到底上（\(jpgBack.cgImage!.alphaInfo.rawValue) 已不是透明通道）—— 编码那一刻 alpha 就丢了")
    let s3 = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { rc in
        rc.cgContext.clear(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    let fileBack = UIImage(data: s3.pngData()!)!
    expect(fileBack.cgImage!.width == s3.cgImage!.width,
           "PNG 往返不丢像素（\(fileBack.cgImage!.width)×\(fileBack.cgImage!.height)）；但「几个像素当 1 个点」这个信息不在文件里，回读的 UIImage 被当成 1x 图")
}

// ============================================================
line("\n== §20 绘制周期与 renderer：headless 下自己驱动 ==")

do {
    let s = Surface(8, 8)
    expect(s.ctx.width == 8 && s.ctx.data != nil,
           "自己造的位图上下文问得出 width/data（\(s.ctx.width) / data 非空）：这是我们能读像素的前提")
    var probeWidth = -1, probeBpr = -1, probeData = true, probeCTM = CGAffineTransform.identity
    let fmt1 = UIGraphicsImageRendererFormat()
    fmt1.scale = 1
    _ = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: fmt1).image { rc in
        let c = rc.cgContext
        probeWidth = c.width
        probeBpr = c.bytesPerRow
        probeData = c.data != nil
        probeCTM = c.ctm
    }
    expect(probeWidth == 0 && probeBpr == 0 && !probeData,
           "renderer 给的上下文：width=\(probeWidth) bytesPerRow=\(probeBpr) data=\(probeData ? "非nil" : "nil") —— 它不是位图上下文，读不到缓冲区")
    expect(!probeCTM.isIdentity,
           "但它的 CTM 有内容（\(ctmStr(probeCTM))）：坐标语义照样是 UIKit 那套，只是像素被藏进了 UIKit 私有的一层")
    var madeSize = CGSize.zero
    _ = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: fmt1).image { rc in
        rc.cgContext.setFillColor(col(0, 0, 1))
        rc.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        if let im = rc.cgContext.makeImage() { madeSize = CGSize(width: im.width, height: im.height) }
    }
    expect(madeSize == CGSize(width: 8, height: 8),
           "在 renderer 闭包里 makeImage() 仍然可用，拿到 \(Int(madeSize.width))×\(Int(madeSize.height))：想「中途取一张图」不必退出闭包")

    let dflt = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { rc in
        rc.cgContext.clear(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    expect(dflt.scale == UIScreen.main.scale,
           "不传 format 时 renderer 用「屏幕 scale」（本机 \(dflt.scale)）：同一行代码在不同 dpi 的设备上给出不同的像素数，这是 @2x/@3x 素材尺寸失控的常见源头")
    expect(dflt.size == CGSize(width: 10, height: 10) && dflt.cgImage!.width == Int(10 * dflt.scale),
           "UIImage.size 始终是点（\(dflt.size.width)），像素数 = 点 × scale（\(dflt.cgImage!.width)）：这两件事必须分开记")

    final class CountView: UIView {
        var draws = 0
        var lastRect = CGRect.null
        override func draw(_ rect: CGRect) {
            draws += 1
            lastRect = rect
            guard let cur = UIGraphicsGetCurrentContext() else { return }
            cur.setFillColor(col(0, 0, 1))
            cur.fill(rect)
        }
    }
    let v = CountView(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
    v.setNeedsDisplay()
    expect(v.draws == 0,
           "headless 进程里 setNeedsDisplay() 之后 draws=\(v.draws)：没有窗口系统与跑循环，系统不会回来调 draw(_:) —— 绘制周期里「调度重绘」这一环在 UIKit 手里，不在 Quartz 手里")
    v.draw(v.bounds)
    expect(v.draws == 1 && v.lastRect == CGRect(x: 0, y: 0, width: 20, height: 10),
           "手动调一次 draw(_:) 就跑了（draws=\(v.draws)，收到的 rect=\(rectStr(v.lastRect))）：参数是「待重画区域」，实测给的是整幅 bounds")
    v.setNeedsDisplay()
    v.layer.display()
    expect(v.draws == 2,
           "layer.display() 又触发一次（draws=\(v.draws)）：它绕过脏标记，叫一次画一次")
    v.layer.display()
    expect(v.draws == 3,
           "连续两次 display() 中间不 setNeedsDisplay 也照样重画（draws=\(v.draws)）：layer 不帮你去重，脏区判断只在 setNeedsDisplay 那条链上")
    let out = Surface(20, 10)
    out.primeWhite()
    let before = out.at(5, 5)
    UIGraphicsPushContext(out.ctx)
    v.draw(v.bounds)
    UIGraphicsPopContext()
    expect(out.at(5, 5) != before && out.at(5, 5).2 > 200,
           "UIGraphicsPushContext 之后，draw(_:) 里取到的「当前上下文」就是我们推进去的那块缓冲区（\(before) → \(out.at(5, 5))）：这就是无窗口环境下测试自定义绘制的通道")
    let popped = UIGraphicsGetCurrentContext()
    expect(popped == nil,
           "Pop 之后当前上下文回到 nil（\(popped == nil ? "nil" : "非nil")）：Push/Pop 必须配对，漏一次 Pop 会让后面的绘制全落进你的缓冲区")
}

// ============================================================
line("\n== §21 PDF 上下文：同一套绘制指令，另一种后端 ==")

do {
    let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("iosdev29-\(UUID().uuidString).pdf")
    var mediaBox = CGRect(x: 0, y: 0, width: 120, height: 60)
    guard let pdf = CGContext(tmp as CFURL, mediaBox: &mediaBox, nil) else {
        expect(false, "PDF 上下文创建失败"); exit(1)
    }
    expect(pdf.width == 0 && pdf.height == 0,
           "PDF 上下文的 width/height 回读 \(pdf.width)/\(pdf.height)：它没有「像素尺寸」这个概念，页面大小由 mediaBox 决定")
    pdf.beginPDFPage(nil as CFDictionary?)
    pdf.setFillColor(col(0, 0, 1))
    pdf.fill(CGRect(x: 10, y: 10, width: 30, height: 20))
    pdf.setLineWidth(2)
    pdf.setStrokeColor(col(1, 0, 0))
    pdf.addRect(CGRect(x: 40, y: 5, width: 30, height: 30))
    pdf.strokePath()
    pdf.endPDFPage()
    pdf.beginPDFPage(nil as CFDictionary?)
    pdf.setFillColor(col(0, 1, 0))
    pdf.fill(CGRect(x: 0, y: 0, width: 120, height: 60))
    pdf.endPDFPage()
    pdf.closePDF()

    let raw = try! Data(contentsOf: tmp)
    let magic = String(data: raw.prefix(8), encoding: .ascii) ?? "?"
    expect(magic.hasPrefix("%PDF-"), "写出的文件以 \(magic) 开头：PDF 上下文真的落盘了")
    guard let doc = CGPDFDocument(tmp as CFURL) else {
        expect(false, "PDF 打不开"); exit(1)
    }
    expect(doc.numberOfPages == 2 && !doc.isEncrypted && doc.allowsCopying && doc.allowsPrinting,
           "读回：\(doc.numberOfPages) 页、加密=\(doc.isEncrypted)、允许复制=\(doc.allowsCopying)、允许打印=\(doc.allowsPrinting)")
    if let p = doc.page(at: 1) {
        expect(p.getBoxRect(.mediaBox) == CGRect(x: 0, y: 0, width: 120, height: 60)
               && p.getBoxRect(.cropBox) == p.getBoxRect(.mediaBox),
               "第 1 页 mediaBox=\(rectStr(p.getBoxRect(.mediaBox)))、cropBox=\(rectStr(p.getBoxRect(.cropBox)))、rotate=\(p.rotationAngle)：不指定时 crop 继承 media（box 要按类型问 getBoxRect(_:)，没有单一 boxRect 属性）")
        expect(p.pageNumber == 1 && p.dictionary != nil,
               "页号从 1 开始（这里读到 \(p.pageNumber)）：page(at:) 与 pageNumber 是同一套 1 起的编号，不是数组下标 —— 传 0 会拿到 nil")
        let tFit = p.getDrawingTransform(.cropBox, rect: CGRect(x: 0, y: 0, width: 60, height: 30),
                                         rotate: 0, preserveAspectRatio: true)
        expect(tFit.a == 0.5 && tFit.d == 0.5,
               "等比塞进 60×30 → \(ctmStr(tFit))：120×60 到 60×30 正好 0.5，这就是「把一页画进 UIView」要乘的矩阵")
        let tRot = p.getDrawingTransform(.cropBox, rect: CGRect(x: 0, y: 0, width: 60, height: 30),
                                         rotate: 90, preserveAspectRatio: true)
        expect(tRot.a == 0 && abs(tRot.b) == 0.25 && abs(tRot.c) == 0.25,
               "rotate:90 之后 a=\(fmt(tRot.a)) b=\(fmt(tRot.b)) c=\(fmt(tRot.c))：旋转直接写进矩阵，长短边互换，缩放系数也跟着变小")
        let tWide = p.getDrawingTransform(.cropBox, rect: CGRect(x: 0, y: 0, width: 200, height: 30),
                                          rotate: 0, preserveAspectRatio: true)
        expect(tWide.a == tWide.d && tWide.a == 0.5,
               "目标框比例不符（200×30）时按短边缩：a=d=\(fmt(tWide.a))，左右留白 —— preserveAspectRatio 传 false 才会被拉扁")

        let canvas = Surface(60, 30)
        canvas.primeWhite()
        canvas.ctx.saveGState()
        canvas.ctx.concatenate(tFit)
        canvas.ctx.drawPDFPage(p)
        canvas.ctx.restoreGState()
        expect(canvas.at(8, 8) == (0, 0, 255, 255) && canvas.at(12, 8) == (0, 0, 255, 255),
               "缩放后把整页画进 60×30 位图：页里 (10,10) 起的一块蓝落在 (8,8)=\(canvas.at(8, 8))、(12,8)=\(canvas.at(12, 8))（原坐标乘 0.5）")
        expect(canvas.at(8, 15) == (255, 255, 255, 255),
               "同一格 (8,15) 却是白底（\(canvas.at(8, 15))）：蓝块乘完 0.5 只覆盖到 y=15 为止 —— 取样要按换算后的范围挑，照页里的原坐标找会一无所获")
        expect(canvas.at(58, 15) == (255, 255, 255, 255),
               "页里没有内容的地方保住我们的白底（\(canvas.at(58, 15))）：PDF 页自己是透明的，不会替你铺背景")

        let raw2 = Surface(60, 30)
        raw2.primeWhite()
        raw2.ctx.drawPDFPage(p)
        expect(raw2.at(15, 15) == (0, 0, 255, 255) && raw2.at(1, 1) == (255, 255, 255, 255),
               "不做变换直接 drawPDFPage：120×60 的页按 1:1 贴，蓝块出现在它自己的坐标上（(15,15)=\(raw2.at(15, 15))），而 (1,1) 是空的（\(raw2.at(1, 1))）—— 想塞进小视图就得先 concatenate 那个 0.5 的矩阵，「PDF 显示不全」九成是忘了这一步")
    } else {
        expect(false, "取不到第 1 页")
    }

    let encURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("iosdev29-\(UUID().uuidString).pdf")
    var encBox = CGRect(x: 0, y: 0, width: 50, height: 50)
    let aux: CFDictionary = [
        kCGPDFContextOwnerPassword: "owner",
        kCGPDFContextUserPassword: "user",
        kCGPDFContextAllowsPrinting: false,
        kCGPDFContextAllowsCopying: false,
    ] as CFDictionary
    if let pdfE = CGContext(encURL as CFURL, mediaBox: &encBox, aux) {
        pdfE.beginPDFPage(nil as CFDictionary?)
        pdfE.setFillColor(col(0, 0, 0))
        pdfE.fill(CGRect(x: 5, y: 5, width: 10, height: 10))
        pdfE.endPDFPage()
        pdfE.closePDF()
        if let d = CGPDFDocument(encURL as CFURL) {
            expect(d.isEncrypted && !d.allowsCopying && !d.allowsPrinting,
                   "带权限字典写出再读回：encrypted=\(d.isEncrypted)、复制=\(d.allowsCopying)、打印=\(d.allowsPrinting) —— 这些开关在创建上下文时给，不在页字典里")
        } else {
            expect(false, "加密 PDF 读不回来")
        }
    } else {
        expect(false, "带密码字典的 PDF 上下文创建失败")
    }

    let infoURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("iosdev29-\(UUID().uuidString).pdf")
    var infoBox = CGRect(x: 0, y: 0, width: 40, height: 40)
    let infoAux: CFDictionary = [
        kCGPDFContextTitle: "教程标题",
        kCGPDFContextAuthor: "iosdev",
        kCGPDFContextCreator: "Quartz 2D",
    ] as CFDictionary
    if let pdfM = CGContext(infoURL as CFURL, mediaBox: &infoBox, infoAux) {
        pdfM.beginPDFPage(nil as CFDictionary?)
        pdfM.setFillColor(col(0, 0, 0))
        pdfM.fill(CGRect(x: 4, y: 4, width: 8, height: 8))
        pdfM.endPDFPage()
        pdfM.closePDF()
        if let d = CGPDFDocument(infoURL as CFURL), let info = d.info {
            func dictString(_ key: String) -> String? {
                var ref: CGPDFStringRef?
                guard key.withCString({ CGPDFDictionaryGetString(info, $0, &ref) }), let r = ref else { return nil }
                let n = CGPDFStringGetLength(r)
                guard let bytes = CGPDFStringGetBytePtr(r) else { return nil }
                let data = Data(bytes: bytes, count: n)
                if n >= 2 && data[data.startIndex] == 0xFE && data[data.startIndex + 1] == 0xFF {
                    return String(data: data.dropFirst(2), encoding: .utf16BigEndian)
                }
                return String(data: data, encoding: .isoLatin1)
            }
            let title = dictString("Title") ?? "无"
            expect(CGPDFDictionaryGetCount(info) >= 3 && title == "教程标题",
                   "文档信息字典（\(CGPDFDictionaryGetCount(info)) 个键）里读回 Title=\(title)、Author=\(dictString("Author") ?? "无")：iOS 头文件里没有 kCGPDFContextInfo 这个总键，这些字段是平铺在 auxiliary 字典里的")
            expect(dictString("NoSuchKey") == nil,
                   "查不存在的键给 nil（CGPDFDictionaryGetString 返回 false）：读 PDF 字典的每一层都要判返回值")
        } else {
            expect(false, "没读到信息字典")
        }
    } else {
        expect(false, "带信息字典的 PDF 上下文创建失败")
    }
    try? FileManager.default.removeItem(at: tmp)
    try? FileManager.default.removeItem(at: encURL)
    try? FileManager.default.removeItem(at: infoURL)
}

// ============================================================
line("\n== §22 案例：画板（缓冲区 + 实时层 + 提交 + 撤销） ==")

do {
    /// 书本 16.3.5 的「画板」：正在拖的这一笔不能直接写进最终图，得有一层实时帧
    final class Pad {
        let w: Int, h: Int
        let buf: Surface
        var liveFrom: CGPoint?
        var liveTo: CGPoint?
        var strokeCount = 0

        init(_ w: Int, _ h: Int) {
            self.w = w; self.h = h
            buf = Surface(w, h)
            buf.primeWhite()
        }
        private func stroke(_ c: CGContext, _ a: CGPoint, _ b: CGPoint) {
            c.setStrokeColor(col(0, 0, 0))
            c.setLineWidth(2)
            c.setLineCap(.round)
            c.move(to: a)
            c.addLine(to: b)
            c.strokePath()
        }
        func begin(_ p: CGPoint) { liveFrom = p; liveTo = p }
        func move(_ p: CGPoint) { liveTo = p }
        func end() {
            guard let a = liveFrom, let b = liveTo else { return }
            stroke(buf.ctx, a, b)
            liveFrom = nil; liveTo = nil
            strokeCount += 1
        }
        /// 实时帧 = 已确定的缓冲区 + 正在拖的这一笔；不动缓冲区
        func frame(_ target: Surface) {
            target.ctx.setFillColor(col(1, 1, 1))
            target.ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
            target.ctx.draw(buf.image, in: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
            if let a = liveFrom, let b = liveTo { stroke(target.ctx, a, b) }
        }
        func erase() {
            buf.ctx.setBlendMode(.clear)
            buf.ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
            buf.ctx.setBlendMode(.normal)
        }
    }

    let pad = Pad(24, 24)
    pad.begin(CGPoint(x: 4, y: 4))
    pad.move(CGPoint(x: 8, y: 8))
    let live = Surface(24, 24)
    pad.frame(live)
    expect(live.at(6, 6).0 < 128 && pad.buf.at(6, 6) == (255, 255, 255, 255),
           "拖动中：实时帧上这一笔已经出现（\(live.at(6, 6))），缓冲区还是白的（\(pad.buf.at(6, 6))）—— 「手指看到的」和「已经定稿的」是两张图")
    pad.move(CGPoint(x: 12, y: 12))
    pad.end()
    expect(pad.buf.at(10, 10).0 < 128 && pad.buf.at(6, 6).0 < 128 && pad.strokeCount == 1,
           "抬手提交：整条线进了缓冲区（(10,10)=\(pad.buf.at(10, 10))，(6,6)=\(pad.buf.at(6, 6))），计 \(pad.strokeCount) 笔")
    let after = Surface(24, 24)
    pad.frame(after)
    expect(after.at(6, 6).0 < 128 && after.at(10, 10).0 < 128,
           "再合成一帧没有重影（\(after.at(6, 6)) / \(after.at(10, 10))）：实时笔已经清空，同一格不会被画两遍 —— 这就是「抬手后画面不跳」的实现要点")
    let saved = UIImage(cgImage: pad.buf.image).pngData()!
    let back = UIImage(data: saved)!
    let inkRow = 24 - 1 - 6          // 用户 y=6 在内存里是第 17 行
    expect(back.cgImage!.width == 24 && px(back.cgImage!, 6, inkRow).0 < 200,
           "缓冲区直接出图、存成 PNG 再读回：\(back.cgImage!.width)×\(back.cgImage!.height)，墨迹还在（用户 (6,6) = 内存行 \(inkRow) 的 \(px(back.cgImage!, 6, inkRow))）—— 无损往返，画板存档可以就这么做")
    pad.erase()
    expect(pad.buf.at(6, 6) == (0, 0, 0, 0),
           "清空用 .clear 整幅填充：(6,6) = \(pad.buf.at(6, 6)) 全透明。注意它没有回到白底 —— 「擦除」与「重置背景」是两件事")
    pad.buf.primeWhite()
    expect(pad.buf.at(6, 6) == (255, 255, 255, 255),
           "重新铺白底才拿到干净画布（\(pad.buf.at(6, 6))）：不透明底色要自己维护，CG 不会替你留一个「背景层」")

    // 撤销：Quartz 没有 undo，历史要自己存
    var history: [CGImage] = []
    let pad2 = Pad(16, 16)
    pad2.begin(CGPoint(x: 2, y: 2)); pad2.move(CGPoint(x: 10, y: 2)); pad2.end()
    history.append(pad2.buf.image)
    pad2.begin(CGPoint(x: 2, y: 6)); pad2.move(CGPoint(x: 14, y: 6)); pad2.end()
    expect(pad2.buf.at(3, 6).0 < 128, "第二笔提交后 (3,6) 有墨：\(pad2.buf.at(3, 6))")
    let snapshot = history.last!
    pad2.buf.ctx.setFillColor(col(1, 1, 1))
    pad2.buf.ctx.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
    pad2.buf.ctx.draw(snapshot, in: CGRect(x: 0, y: 0, width: 16, height: 16))
    expect(pad2.buf.at(3, 6).0 > 200,
           "撤销 = 铺白底再把上一帧快照贴回来（(3,6) 回到 \(pad2.buf.at(3, 6))）：代价是每笔存一张图，所以真要撤销栈得限制深度或改存「指令」")
}

// ============================================================
line("\n== §23 本章的边界：哪些量出来了，哪些只能记下来 ==")

line("  实测并可断言（§1–§22，每条都靠回读缓冲区判定）：")
line("    位图上下文的尺寸/行距/字节序；两种原点与翻转 CTM 的逐字节等价；1pt 线的半格落位；抗锯齿开关；")
line("    三种「红」的字节差异与色空间转换；预乘存储；绘画模型的层序；路径元素数与包围盒；winding 与 even-odd；")
line("    CTM 乘法顺序；裁剪求交与状态栈解除；蒙版裁剪；描边转路径后裁剪；端帽与三种连接；点线图案与相位取模；")
line("    addArcToPoint 圆角；平面度；全局 alpha 与透明层的接缝消除；8 种混合模式的逐通道结果与擦除类模式；")
line("    阴影默认色、偏移的设备轴、blur 的作用半径；梯度的边界留白、扩展选项、停靠点与 alpha 插值；")
line("    CoreText 直画与 UIKit 文本两条通路；CGImage 元数据、插值质量、平铺的目标矩形语义；")
line("    PNG/JPEG 签名与 alpha 存失；renderer 的 scale 与 opaque；headless 下的绘制周期驱动；")
line("    PDF 的写出、读回、box 查询、缩放矩阵、权限字典、信息字典；画板的缓冲区/实时层/提交/清空/撤销。")
line("")
line("  探针记录（不适合进可重复断言，只做事实登记）：")
line("    1) 书本 16.3.3 的文本画法（selectFont / showText / showTextAtPoint）在本机 SDK 头文件里被标成")
line("       @available(*, unavailable)（iOS 2 引入、iOS 7 废弃后从 Swift 侧彻底封死）。Swift 工程画文本只剩两条路：")
line("       CoreText 的 CTLineCreateWithAttributedString + CTLineDraw（§18 用它），或者 UIGraphicsPushContext 之后用")
line("       NSString 的 draw(at:)/draw(in:)（§18 也验了）。textPosition / textMatrix 两个属性仍可用；textDrawingMode 在本机 iOS SDK 的 Swift 映射里不存在（探针 14 记录），但 CTLineDraw 默认就是填充模式，不影响结果。")
line("    2) CGContext 只开了这几个查询口：ctm、currentPointOfPath、boundingBoxOfPath、boundingBoxOfClipPath、")
line("       interpolationQuality、userSpaceToDeviceSpaceTransform，外加位图上下文的 width/height/bytesPerRow/data。")
line("       lineWidth、lineCap、lineJoin、miterLimit、两种颜色、blendMode、shadow、globalAlpha、")
line("       shouldAntialias 全都「只写不读」。所以任何绘图封装都要自己留一份状态，否则代码会长成")
line("       「设过什么完全想不起来」的样子 —— 这是本章踩得最多的坑。")
line("    3) 非法的位图参数组合一律给 nil，不崩、不报错、不打日志（探针实测）：sRGB + .last（非预乘 RGBA）→ nil；")
line("       sRGB + .none（想 3 字节紧凑排列）→ nil；灰度 + premultipliedLast → nil；灰度 + .none → 建成。")
line("       行距小于 width × bytesPerPixel 同样直接 nil。想要非预乘的 RGBA，得换路子（例如自己处理 CGImage 字节）。")
line("    4) 阴影偏移（§16）实测是加在设备轴上的：翻转 CTM 之后，正的 y 偏移仍然让影子上移。")
line("       这与 Apple 文档「在当前用户空间坐标系中」的措辞不一致，也和 CALayer.shadowOffset 的方向直觉相反，")
line("       是本章唯一一条「照文档写会画反」的条目 —— 上真机时请再目视确认一次。")
line("    5) PDF 里写链接（setURL(_:for:)、addDestination(_:at:)、setDestination(_:for:)）三个调用都成功、")
line("       文件也能被 CGPDFDocument 打开，但把文件字节转成字符串搜 \"/URI\"、\"/GoTo\" 一个都搜不到：")
line("       内容进了压缩流。要验链接得用真正的 PDF 解析器读注释数组，Quartz 这一侧只能验「写得进去」。")
line("       另外 iOS 头文件里没有 kCGPDFContextInfo：Title/Author/Subject/Keywords/Creator 要平铺在")
line("       auxiliary 字典里（§21 按此测通）。CGPDFDocument 也没有 allowsContentExtraction 这类属性。")
line("    6) renderer 给的 cgContext 不是位图上下文（§20 实测 width/bytesPerRow 为 0、data 为 nil），")
line("       所以「读像素验证 UIKit 绘制」要么自己造缓冲区再 PushContext，要么从产出的 UIImage.cgImage 的")
line("       dataProvider 读。另外默认 format 用 UIScreen.main.scale 且 opaque=false，跨设备结果会差 3 倍。")
line("    7) 字体栅格化的墨像素绝对值随 iOS 版本/字体版本变，所以 §18 只断言「有没有墨」「谁比谁多」和")
line("       排版宽的近似区间。本章所有像素结论来自 x86_64-apple-ios15.0-simulator + iPhone 16 Pro 运行时；")
line("       换 arm64 真机后 §4/§18 的绝对数值会动，而 §1/§2/§3/§7–§17 的结构性结论（原点与镜像行号、")
line("       面积覆盖、交集裁剪、相位取模、预乘、min/max 类混合、设备轴偏移）不会变。")
line("    8) 本章刻意没测的：需要窗口与跑循环的 setNeedsDisplay 调度节奏、真机 Metal 光栅化路径上的性能数字、")
line("       以及 CIFilter 那套 GPU 通路（属第 23 章之后的另一条线）。书本「花瓣曲线」案例在本章是 §12 的")
line("       贝塞尔 + §8 的旋转变换，「基本图形」分散在 §6/§7/§10/§12，「画板」在 §22。")
line("")
line("  下一步：把本章的原语交给 CALayer.contents（第 23 章）就是「离屏绘制 + 缓存」，交给 draw(_:) 就是")
line("  「每帧重绘」；两者的差别、线程约束与位图上下文的可复用性，是第 23 章要量的东西。")

if failures == 0 {
    line("\n全部断言通过。")
} else {
    line("\n有 \(failures) 条断言失败。")
}
print("==== 29 结束 ====")
exit(failures == 0 ? 0 : 1)
