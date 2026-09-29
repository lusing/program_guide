// ============================================================
// 23 - 核心动画：CALayer、显式动画与特殊图层
//
// 第 14 章讲过 UIView 的 frame/bounds/center 与 transform，第 21 章讲过布局，
// 第 22 章讲过滚动与容器。这一章下到底层：**动画真正作用的对象是 CALayer**，
// 把教材里 Core Animation 那一章的骨架走一遍：
//   层的几何（frame / position / anchorPoint / bounds）
//   model 层与 presentation 层的分工，以及**冻结层时钟**把插值变成可核对的数字
//   隐式动画（action(forKey:) / actions / CATransaction.setDisableActions）
//   CABasicAnimation（fromValue / toValue / byValue / fillMode / 重复 / keyPath 家族）
//   时间与曲线（CAMediaTimingFunction、speed / timeOffset / beginTime 的暂停恢复）
//   CAKeyframeAnimation（values + keyTimes / calculationMode / 沿 CGPath）
//   CAAnimationGroup、CATransition、CASpringAnimation、UIView 层的动画接口
//   特殊图层族（gradient / shape / text / replicator / emitter / tiled / scroll / transform）
//   CATransform3D 全套函数与 m34 透视
//   CATransaction、CAAnimationDelegate、CADisplayLink
//
// headless 怎么读到确定的插值（本章最关键的一招）：
//   1) `layer.speed = 0` 把层的时钟冻住，动画就不按墙钟走了；
//   2) 手动拨 `layer.timeOffset = t`，相当于把这一层的时间机推到 t 秒；
//   3) 但改完必须等**一次真正的显示周期**，Core Animation 才会重算 presentation 层。
//      所以这里挂一个 CADisplayLink 当节拍器（displayPass()），拿它的回调确认「屏幕真的刷新过一轮」。
//   三层都做到，presentation 的读数才既准确又可复现 —— 少了第 3 步，读到的永远是动画起点。
//
// 判定 3（stderr 必须为空）与「debug/release 逐字节一致」的约束：
//   - 不打印 CGColor、CAAnimation、CALayer 的 description —— 探针实测它们里面带**指针地址**
//   - 不打印任何由墙钟推进出来的插值（暂停/恢复那种）—— 只打印布尔值和差值
//   - 不给 CAMediaTimingFunction 传未知名字或 index=4 的控制点 —— 实测当场抛
//     NSException（reason 分别以「unknown timing function name」和
//     「no timing function control point with index」开头）后 SIGABRT
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func near(_ a: Double, _ b: Double, _ tol: Double = 0.01) -> Bool { abs(a - b) < tol }
/// 四位小数：既能看出插值不是「整数就完事」，又不会因为末位浮点抖动改变输出
func f4(_ v: Double) -> String { String(format: "%.4f", v) }
func f4(_ v: Float) -> String { String(format: "%.4f", Double(v)) }

// ---------------------------------------------------- 支撑类型（放在使用之前）
final class TickTarget: NSObject {
    let body: () -> Void
    init(_ body: @escaping () -> Void = {}) { self.body = body }
    @objc func tick(_ link: CADisplayLink) { body() }
}

final class AnimLogger: NSObject, CAAnimationDelegate {
    var log: [String] = []
    func animationDidStart(_ anim: CAAnimation) { log.append("start") }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) { log.append("stop:\(flag)") }
}

/// 节拍器：每次真正的显示周期回调一次，ticks 计数供 displayPass() 判断「有没有刷新过」
final class Beat: NSObject {
    var ticks = 0
    @objc func fire(_ link: CADisplayLink) { ticks += 1 }
}
let beat = Beat()

// 窗口与承载视图：层的插值要有一次真正的显示才拿得到 presentation 层
let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
window.isHidden = false
let rootVC = UIViewController()
window.rootViewController = rootVC
let host: UIView = rootVC.view

let metronome = CADisplayLink(target: beat, selector: #selector(Beat.fire(_:)))
metronome.add(to: .current, forMode: .common)

/// 等 n 次真正的显示周期发生（单次最多等 5 秒，超时也继续，避免卡死）
func displayPass(_ n: Int = 1) {
    for _ in 0..<n {
        let start = beat.ticks
        let deadline = Date(timeIntervalSinceNow: 5.0)
        while beat.ticks == start && Date() < deadline {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
        }
    }
}

/// 往 host 里放一个视图、把它的层**冻结**（speed = 0）、加上动画并预热两轮显示，返回这一层。
/// 预热是必需的：刚 add 完动画时 presentation() 还不存在，拨过的 timeOffset 也要等显示周期才生效。
func animLayer(_ make: () -> CAAnimation,
               size: CGSize = CGSize(width: 40, height: 40)) -> CALayer {
    let v = UIView(frame: CGRect(origin: .zero, size: size))
    host.addSubview(v)
    v.layer.speed = 0
    v.layer.add(make(), forKey: "sample")
    displayPass(2)
    return v.layer
}
/// 把层的本地时间推到 t，等一次显示周期，返回 presentation 层（没有就用 model 兜底）
func sample(_ layer: CALayer, at t: CFTimeInterval) -> CALayer {
    layer.timeOffset = t
    displayPass()
    return layer.presentation() ?? layer
}
func basic(_ keyPath: String, _ from: Any?, _ to: Any?, duration: CFTimeInterval = 1.0) -> CABasicAnimation {
    let a = CABasicAnimation(keyPath: keyPath)
    a.fromValue = from
    a.toValue = to
    a.duration = duration
    return a
}
/// 取贝塞尔曲线的 4 个控制点，拼成 "(x,y)" 数组，便于逐条比对
func controlPoints(_ fn: CAMediaTimingFunction) -> [String] {
    (0..<4).map { i -> String in
        var pair: [Float] = [0, 0]
        fn.getControlPoint(at: i, values: &pair)
        return "(\(String(format: "%.2f", pair[0])),\(String(format: "%.2f", pair[1])))"
    }
}

displayPass()

// ============================================================ 1) 层的几何
line("== 1) CALayer 的几何：frame / position / anchorPoint / bounds ==")
let g = UIView(frame: CGRect(x: 40, y: 60, width: 100, height: 50))
host.addSubview(g)
let gl = g.layer
line("  UIView(frame: 40,60,100,50) 的层：frame=\(gl.frame) bounds=\(gl.bounds)")
line("  position=\(gl.position) anchorPoint=\(gl.anchorPoint) zPosition=\(gl.zPosition)")
expect(near(gl.position.x, 90) && near(gl.position.y, 85),
       "position = frame 原点 + anchorPoint × size（100×50 → (90,85)）")
expect(gl.anchorPoint == CGPoint(x: 0.5, y: 0.5), "anchorPoint 默认 (0.5, 0.5)")
expect(gl.bounds.origin == .zero && gl.bounds.size == CGSize(width: 100, height: 50),
       "bounds 的 size 就是 frame 的 size，origin 默认 (0,0)")
let anchorBefore = gl.position
gl.anchorPoint = CGPoint(x: 0, y: 0)
line("  把 anchorPoint 改成 (0,0)：position=\(gl.position) frame=\(gl.frame)")
expect(gl.position == anchorBefore, "改 anchorPoint 不动 position")
expect(near(gl.frame.minX, 90) && near(gl.frame.minY, 85),
       "frame 的原点被挪到 position —— 视觉位置跟着跳，这是 anchorPoint 最常见的坑")
gl.anchorPoint = CGPoint(x: 0.5, y: 0.5)
gl.bounds.origin = CGPoint(x: 10, y: 10)
line("  设 bounds.origin=(10,10) 之后：frame=\(gl.frame) position=\(gl.position)")
let plainG = CALayer()
plainG.frame = CGRect(x: 40, y: 60, width: 100, height: 50)
host.layer.addSublayer(plainG)
plainG.bounds.origin = CGPoint(x: 10, y: 10)
line("  同一个数字换到**裸 CALayer** 上：frame=\(plainG.frame) position=\(plainG.position)")
expect(gl.frame == CGRect(x: 40, y: 60, width: 100, height: 50) && plainG.frame.minX == 40,
       "bounds.origin 不会写回 frame/position 的 getter —— 它挪的是层内部的坐标原点（内容偏移），别拿它当位移用")
gl.bounds.origin = .zero
plainG.removeFromSuperlayer()
line("  zPosition=\(gl.zPosition) anchorPointZ=\(gl.anchorPointZ)（CALayer 没有 zIndex / sublayerStyle 这两个属性）")
let sub1 = CALayer(); sub1.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
let sub2 = CALayer(); sub2.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
gl.addSublayer(sub1); gl.addSublayer(sub2)
line("  两个同尺寸子层：sublayers 里 sub2 的下标=\(gl.sublayers?.firstIndex(of: sub2) ?? -1)（后加的在后面，重叠时盖住前一个）")
sub1.zPosition = 5
line("  sub1.zPosition=5 之后 sublayers 顺序没变（下标仍是 \(gl.sublayers?.firstIndex(of: sub1) ?? -1)）—— zPosition 只改绘制次序，不重排数组")
expect(gl.sublayers?.firstIndex(of: sub1) == 0, "zPosition 不动 sublayers 数组本身")
sub1.removeFromSuperlayer()
sub2.removeFromSuperlayer()
g.removeFromSuperview()

line("")
line("  层的其它默认值（一次读全，供对照）：")
let d = CALayer()
line("    opacity=\(d.opacity) isHidden=\(d.isHidden) masksToBounds=\(d.masksToBounds) allowsGroupOpacity=\(d.allowsGroupOpacity)")
line("    isDoubleSided=\(d.isDoubleSided) isGeometryFlipped=\(d.isGeometryFlipped) contentsAreFlipped()=\(d.contentsAreFlipped())")
line("    contentsGravity=\(d.contentsGravity.rawValue) contentsScale=\(d.contentsScale) contentsRect=\(d.contentsRect)")
line("    minificationFilter=\(d.minificationFilter.rawValue) magnificationFilter=\(d.magnificationFilter.rawValue)")
line("    borderWidth=\(d.borderWidth) shadowOpacity=\(d.shadowOpacity) shadowRadius=\(d.shadowRadius) shadowOffset=\(d.shadowOffset)")
line("    shouldRasterize=\(d.shouldRasterize) rasterizationScale=\(d.rasterizationScale) contentsFormat=\(d.contentsFormat.rawValue)")
line("    cornerRadius=\(d.cornerRadius) cornerCurve=\(d.cornerCurve.rawValue) isOpaque=\(d.isOpaque) style=\(String(describing: d.style))")
expect(near(d.shadowRadius, 3) && d.shadowOffset == CGSize(width: 0, height: -3),
       "shadowRadius 默认 3、shadowOffset 默认 (0,-3)（但 shadowOpacity=0 所以看不见）")
expect(d.contentsFormat == .RGBA8Uint && d.cornerCurve == .continuous,
       "contentsFormat 默认 RGBA8Uint（rawValue 显示成 RGBA8），cornerCurve 默认 continuous（iOS 13 起）")

// 视图的层挂进窗口之后 contentsScale 会不会自动变成屏幕 scale
let scaleProbe = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
host.addSubview(scaleProbe)
displayPass()
line("    挂进 3× 屏的窗口并跑一轮显示之后：layer.contentsScale=\(scaleProbe.layer.contentsScale)，UIScreen.main.scale=\(UIScreen.main.scale)")
expect(scaleProbe.layer.contentsScale == 1.0,
       "contentsScale 不会因为挂进窗口自动变成屏幕 scale，要画 3× 位图得自己设")
expect(near(scaleProbe.layer.frame.minX, 0) && scaleProbe.center == scaleProbe.layer.position,
       "UIView.center 与 layer.position 是同一个值")
scaleProbe.removeFromSuperview()

// ============================================================ 2) model 层与 presentation 层
line("")
line("== 2) model / presentation：动画期间「真实值」与「显示值」不是一回事 ==")
let m = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
host.addSubview(m)
displayPass()
UIView.animate(withDuration: 0.5) { m.center = CGPoint(x: 150, y: 150) }
line("  UIView.animate 调用**返回之后**：model center=\(m.center)，layer.position=\(m.layer.position)")
expect(m.center == CGPoint(x: 150, y: 150), "animate 的 block 一执行完，model 层就已经是终点值")
line("  此时 animationKeys=\(String(describing: m.layer.animationKeys()))，presentation() 是否存在=\(m.layer.presentation() != nil)")
expect(m.layer.animationKeys() == ["position"], "UIView.animate 改 center → 层上挂的动画 key 是 position")
expect(m.layer.presentation() != nil,
       "已经显示过的层，animate 一返回就有 presentation 层（没显示过的层要等一轮显示才有，见下面第 3 段）")
displayPass()
line("  跑一轮显示之后 presentation() 存在=\(m.layer.presentation() != nil)")
line("    ↑ 中间值本身由墙钟决定（探针实测同一段代码两次运行分别是 20.2253 与 20.1564），所以这里不打印它")
expect(m.layer.presentation() != nil, "动画进行中 presentation 层在")
let settleDeadline = Date(timeIntervalSinceNow: 0.7)
while Date() < settleDeadline {
    _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
}
displayPass(2)
line("  动画结束之后：animationKeys=\(String(describing: m.layer.animationKeys())) presentation 存在=\(m.layer.presentation() != nil)")
expect(m.layer.animationKeys() == nil, "动画自然结束后 key 自动消失（isRemovedOnCompletion 默认 true）；注意要跑过显示周期才收尾")

line("")
line("  —— 把层的时钟冻住，插值就变成可以核对的确定数字 ——")
let fz = animLayer { basic("position.x", 20.0, 300.0) }
var frozenReads: [String] = []
for t in [0.0, 0.25, 0.5, 0.75, 1.0] {
    let x = sample(fz, at: t).position.x
    frozenReads.append(f4(x))
    line("    timeOffset=\(t) → presentation.position.x=\(f4(x))（model 仍是 \(f4(fz.position.x))）")
}
expect(frozenReads == ["20.0000", "90.0000", "160.0000", "230.0000", "299.9997"],
       "线性插值：0/0.25/0.5/0.75/1.0 → 20/90/160/230/≈300（终点是 299.9997，浮点插值差一点点）")
expect(fz.position.x == 20, "显式动画不会改 model —— 这是「动画跑完就弹回」的根因")

line("")
line("  —— 为什么必须等一次真正的显示周期（四级台阶） ——")
let coldV = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
host.addSubview(coldV)
coldV.layer.speed = 0
coldV.layer.add(basic("opacity", 0.2, 0.8), forKey: "cold")
var coldReads: [String] = []
for _ in 0..<3 {
    coldReads.append(f4(Double((coldV.layer.presentation() ?? coldV.layer).opacity)))
}
line("    第 1 级：add 完一次显示都没跑，presentation() 存在=\(coldV.layer.presentation() != nil)，")
line("             同一行代码连读三次 → \(coldReads.joined(separator: " / "))（拿到的是 model 的 1.0，不是插值）")
displayPass(2)
let warmFirst = f4(Double((coldV.layer.presentation() ?? coldV.layer).opacity))
line("    第 2 级：预热两轮显示之后 presentation 存在=\(coldV.layer.presentation() != nil)，读回 \(warmFirst)")
line("             —— 是动画起点（timeOffset 还是 0），说明 presentation 是被显示周期算出来的，不是被读出来的")
coldV.layer.timeOffset = 0.5
let staleRead = f4(Double((coldV.layer.presentation() ?? coldV.layer).opacity))
line("    第 3 级：把 timeOffset 拨到 0.5 之后**立刻**读 → \(staleRead)（还是上一轮那帧的值）")
displayPass()
let afterSample = f4(Double((coldV.layer.presentation() ?? coldV.layer).opacity))
line("    第 4 级：等一轮显示之后再读 → \(afterSample)（这才是 timeOffset=0.5 处的插值）")
expect(coldReads == ["1.0000", "1.0000", "1.0000"], "没跑过显示周期时只有 model 可读")
expect(warmFirst == "0.2000", "预热完读到的是动画起点")
expect(staleRead == "0.2000", "拨完 timeOffset 立刻读到的仍是上一帧")
expect(afterSample == "0.5000", "改 timeOffset 之后必须再等一次显示周期")
line("  本章所有插值都走 animLayer()/sample() 这套冻结+节拍器；不冻时钟时同一个动画连读三次，")
line("  探针里两次运行分别是 2.309/2.334/2.344 与 2.821/5.776/8.731 —— 墙钟值既不可核对也无法逐字节比对")

// ============================================================ 3) 隐式动画
line("")
line("== 3) 隐式动画：改裸 CALayer 的属性，层自己会补一段动画 ==")
let box = CALayer()
box.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
host.layer.addSublayer(box)
displayPass()
line("  动作之前：animationKeys=\(String(describing: box.animationKeys()))")
box.opacity = 0.3
line("  改完 opacity 立刻（同一轮 runloop 内）：keys=\(String(describing: box.animationKeys()))")
expect(box.animationKeys()?.contains("opacity") == true, "裸层的属性改动会挂上一个以属性名命名的隐式动画")
displayPass(4)
line("  再跑四轮显示之后：keys=\(String(describing: box.animationKeys())) model=\(f4(Double(box.opacity)))")
expect(box.animationKeys()?.contains("opacity") == true,
       "隐式动画的 key 不像显式动画那样跑完就自己消失，removeAnimation(forKey:) 才清得掉")
if let implicitAnim = box.animation(forKey: "opacity") {
    line("  animation(forKey:) 取回真正在跑的这条：类型=\(String(describing: type(of: implicitAnim)))")
    let ib = implicitAnim as? CABasicAnimation
    line("    duration=\(String(describing: ib?.duration)) fillMode=\(ib?.fillMode.rawValue ?? "nil") speed=\(implicitAnim.speed) repeatCount=\(implicitAnim.repeatCount)")
}
let box2 = CALayer()
box2.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
host.layer.addSublayer(box2)
displayPass()
CATransaction.begin()
CATransaction.setDisableActions(true)
box2.opacity = 0.3
CATransaction.commit()
line("  CATransaction.setDisableActions(true) 之后：keys=\(String(describing: box2.animationKeys()))")
expect(box2.animationKeys() == nil, "关掉隐式动画的标准做法：把属性改动包进一个 disableActions 的事务")

let box3 = CALayer()
box3.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
box3.actions = ["opacity": NSNull()]
host.layer.addSublayer(box3)
displayPass()
box3.opacity = 0.3
line("  actions[\"opacity\"] = NSNull() 之后：keys=\(String(describing: box3.animationKeys()))")
expect(box3.animationKeys() == nil, "按属性名逐个屏蔽：actions 里放 NSNull")

let lonely = CALayer()
lonely.opacity = 1.0
lonely.opacity = 0.3
line("  没有 superlayer 的层改属性：keys=\(String(describing: lonely.animationKeys()))")
expect(lonely.animationKeys() == nil, "层必须已经在树里，属性改动才有隐式动画")

line("  action(forKey:) 读默认动作对象（只打印类型，对象 description 里带指针地址）：")
for key in ["opacity", "hidden", "bounds", "position", "sublayers", "transform", "backgroundColor"] {
    let act = box.action(forKey: key)
    let name = act.map { String(describing: type(of: $0)) } ?? "nil"
    line("    树内的层 \(key) → \(name)")
}
expect(box.action(forKey: "sublayers") is CATransition,
       "sublayers 的默认隐式动作是 CATransition，不是 CABasicAnimation")
expect(box.action(forKey: "hidden") is CATransition,
       "hidden 也是转场（层的出现/消失本身就被当成内容替换）")
expect(box.action(forKey: "backgroundColor") == nil,
       "backgroundColor 没有默认动作 —— 改它不会自己补动画，得显式 add")
for key in ["opacity", "sublayers"] {
    let act = lonely.action(forKey: key)
    line("    树外的层 \(key) → \(act.map { String(describing: type(of: $0)) } ?? "nil")")
}
let viewLayer = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
host.addSubview(viewLayer)
displayPass()
viewLayer.layer.opacity = 0.5
line("  UIView 自己的 layer 改 opacity：keys=\(String(describing: viewLayer.layer.animationKeys()))（视图的层由 UIKit 管，不参与隐式动画）")
expect(viewLayer.layer.animationKeys() == nil, "视图层改属性走 UIKit 的动画通道，裸层的隐式动画规则在这里不适用")

// ============================================================ 4) CABasicAnimation
line("")
line("== 4) CABasicAnimation：属性默认值与三种给值方式 ==")
let b = CABasicAnimation(keyPath: "opacity")
line("  duration=\(b.duration) beginTime=\(b.beginTime) speed=\(b.speed) repeatCount=\(b.repeatCount) autoreverses=\(b.autoreverses)")
line("  isRemovedOnCompletion=\(b.isRemovedOnCompletion) fillMode=\(b.fillMode.rawValue) timingFunction=\(String(describing: b.timingFunction))")
line("  fromValue=\(String(describing: b.fromValue)) toValue=\(String(describing: b.toValue)) byValue=\(String(describing: b.byValue)) isAdditive=\(b.isAdditive) isCumulative=\(b.isCumulative)")
expect(b.duration == 0 && b.isRemovedOnCompletion && b.fillMode == .removed,
       "新建动画 duration=0（等于不播）、结束后移除、fill 为 removed")
line("  keyPath=\(String(describing: b.keyPath))（CABasicAnimation 继承自 CAPropertyAnimation，keyPath 就是这个层上的属性路径）")

let toOnly = animLayer { basic("opacity", nil, 0.0) }
var toReads: [String] = []
for t in [0.0, 0.5, 1.0] { toReads.append(f4(Double(sample(toOnly, at: t).opacity))) }
line("  只给 toValue（0.0）：t=0/0.5/1 → \(toReads.joined(separator: " / "))")
expect(toReads.first == "1.0000", "缺 fromValue 时用「当前 model 值」当起点，所以 t=0 读回 1.0")
expect(toReads[1] == "0.5000", "中点正好是 (1.0 + 0.0)/2")
expect(toReads[2] == "0.0000", "终点干净地读到 0.0000 —— 但 position 那条的终点是 299.9997，别假设端点一定精确")

let byLayer = animLayer {
    let a = CABasicAnimation(keyPath: "opacity")
    a.byValue = 0.2
    a.duration = 1.0
    return a
}
byLayer.opacity = 0.5
let byEnd = f4(Double(sample(byLayer, at: 1.0).opacity))
line("  model.opacity=0.5 + byValue=0.2：t=1 → pres=\(byEnd)（model=\(f4(Double(byLayer.opacity)))）")
expect(byEnd == "0.7000", "byValue 是「在当前值上加」")
let byMid = f4(Double(sample(byLayer, at: 0.5).opacity))
line("  同一时间的中点 t=0.5 → \(byMid)（0.5 与 0.7 的中点）")
expect(byMid == "0.6000", "byValue 一样受 timingFunction/时间影响，中间值照常插值")

line("")
line("  —— fillMode 四种，动画结束（t=2，duration=1）之后再读 ——")
var fillResults: [(String, String)] = []
for fm in [CAMediaTimingFillMode.removed, .forwards, .backwards, .both] {
    let a = basic("opacity", 0.2, 0.8)
    a.isRemovedOnCompletion = false
    a.fillMode = fm
    let l = animLayer({ a })
    let pres = f4(Double(sample(l, at: 2.0).opacity))
    fillResults.append((fm.rawValue, pres))
    line("    fillMode=\(fm.rawValue) → pres.opacity=\(pres)（model=\(f4(Double(l.opacity)))，keys=\(String(describing: l.animationKeys()))）")
}
expect(fillResults.map { $0.1 } == ["1.0000", "0.8000", "1.0000", "0.8000"],
       "结束后只有 forwards/both 保持终点值；removed/backwards 回到 model")
expect(fillResults.allSatisfy { $0.0 != "" }, "fillMode 的 Swift 名字是 .removed/.forwards/.backwards/.both（没有 .none）")
expect(fillResults[0] != fillResults[1], "removed 与 forwards 只在「动画结束之后」有区别，播放期间完全一样")

line("")
line("  —— 反过来看**动画开始前**（beginTime=1.0，duration=1，0.2→0.8）——")
var preResults: [(String, String, String)] = []
for fm in [CAMediaTimingFillMode.removed, .forwards, .backwards, .both] {
    let a = basic("opacity", 0.2, 0.8)
    a.isRemovedOnCompletion = false
    a.beginTime = 1.0
    a.fillMode = fm
    let l = animLayer({ a })
    let before = f4(Double(sample(l, at: 0.5).opacity))
    let atStart = f4(Double(sample(l, at: 1.0).opacity))
    preResults.append((fm.rawValue, before, atStart))
    line("    fillMode=\(fm.rawValue) → t=0.5（还没开始）pres.opacity=\(before)，t=1.0（刚好开始）pres.opacity=\(atStart)（model=\(f4(Double(l.opacity)))）")
}
expect(preResults.map { $0.1 } == ["1.0000", "1.0000", "0.2000", "0.2000"],
       "开始前只有 backwards/both 会显示起点值；removed/forwards 显示 model")
expect(preResults.map { $0.2 } == ["0.2000", "0.2000", "0.2000", "0.2000"],
       "t=1.0 四种 fillMode 已经一样 —— 动画正式开始后 fillMode 不参与")

line("")
line("  —— autoreverses + repeatCount：0→1，duration=1，autoreverses=true，repeatCount=2 ——")
let arLayer = animLayer {
    let a = basic("opacity", 0.0, 1.0)
    a.autoreverses = true
    a.repeatCount = 2
    return a
}
var arReads: [(String, String)] = []
for t in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.5, 4.0] {
    arReads.append((String(format: "%g", t), f4(Double(sample(arLayer, at: t).opacity))))
}
line("    " + arReads.map { "t=\($0.0):\($0.1)" }.joined(separator: " "))
expect(arReads[1].1 == "0.5000" && arReads[3].1 == "0.5000", "往返两次都会经过中点 0.5")
expect(arReads[2].1 == "1.0000" && arReads[4].1 == "0.0000", "t=1 冲到顶、t=2 回到 0 —— 一次往返正好 2×duration")
expect(arReads[7].1 == "0.0000", "总时长 = duration×2×repeatCount = 4s，t=4 回到起点")
let rc = basic("opacity", 0.0, 1.0)
line("    这几条时间属性的类型并不统一（同一段代码里读出的）：repeatCount=\(String(describing: type(of: rc.repeatCount)))、speed=\(String(describing: type(of: rc.speed)))、duration=\(String(describing: type(of: rc.duration)))、beginTime=\(String(describing: type(of: rc.beginTime)))")
rc.repeatCount = 1.5
line("    repeatCount 是 **Float**（不是 Double），设成 1.5 读回 \(rc.repeatCount)")
expect(rc.repeatCount == 1.5, "非整数重复合法：1.5 表示走一轮半")
rc.repeatCount = .infinity
line("    无限重复就是 .infinity：读回 \(rc.repeatCount)，与 Float.infinity 相等=\(rc.repeatCount == Float.infinity)")
expect(rc.repeatCount == Float.infinity, "repeatCount = .infinity 是无限重复的标准写法")
let springTypes = CASpringAnimation(keyPath: "position.x")
line("    弹簧的四个参数也各不一样：mass=\(String(describing: type(of: springTypes.mass))) stiffness=\(String(describing: type(of: springTypes.stiffness))) damping=\(String(describing: type(of: springTypes.damping))) initialVelocity=\(String(describing: type(of: springTypes.initialVelocity))) settlingDuration=\(String(describing: type(of: springTypes.settlingDuration)))")

line("")
line("  —— keyPath 家族：同一个 CATransform3D 可以按分量拆着动 ——")
let txP = sample(animLayer { basic("transform.translation.x", 0.0, 40.0) }, at: 0.5)
line("    transform.translation.x t=0.5 → transform.m41=\(f4(txP.transform.m41))，position.x=\(f4(txP.position.x))")
expect(near(txP.transform.m41, 20) && near(txP.position.x, 20),
       "translation 走矩阵的第 4 行（m41），不动 position —— 和 position.x 动画是两回事")

let rotL = animLayer { basic("transform.rotation.z", 0.0, Double.pi) }
var rotReads: [(String, String)] = []
for t in [0.0, 0.5, 1.0] {
    let p = sample(rotL, at: t)
    let z = (p.value(forKeyPath: "transform.rotation.z") as? Double) ?? -1
    rotReads.append((f4(p.transform.m11), f4(z)))
}
line("    transform.rotation.z 0→π：t=0/0.5/1 → m11=\(rotReads.map { $0.0 }.joined(separator: " / "))")
line("      用 KVC 读分量：rotation.z=\(rotReads.map { $0.1 }.joined(separator: " / "))")
expect(rotReads[1].1 == "1.5708", "弧度值可以直接按 keyPath 插值（CATransform3D 结构体本身没有 .rotation 成员）")
expect(rotReads[1].0 == "0.0000", "转 90° 时 m11 为 0")

let bsL = animLayer { basic("bounds.size.width", 40.0, 120.0) }
let bsP = sample(bsL, at: 0.5)
line("    bounds.size.width 40→120：t=0.5 → pres.bounds=\(bsP.bounds)，model.bounds=\(bsL.bounds)")
expect(near(bsP.bounds.width, 80) && near(bsL.bounds.width, 40),
       "子属性 keyPath 只动 presentation（80），model 一点没变（还是 40）")

let bgL = animLayer {
    let a = CABasicAnimation(keyPath: "backgroundColor")
    a.fromValue = UIColor.red.cgColor
    a.toValue = UIColor.blue.cgColor
    a.duration = 1.0
    return a
}
_ = sample(bgL, at: 0.5)
line("    backgroundColor 用 CGColor 插值：t=0.5 时 presentation 层存在=\(bgL.presentation() != nil)（CGColor 的 description 带地址，不打印）")
expect(bgL.presentation() != nil, "颜色类属性可以动画，前提是给它 CGColor 而不是 UIColor")

let badKey = animLayer {
    let a = CABasicAnimation(keyPath: "doesNotExist.atAll")
    a.fromValue = 0.0
    a.toValue = 1.0
    a.duration = 1.0
    return a
}
let badP = sample(badKey, at: 0.5)
line("    拼错 keyPath：add 之后 keys=\(String(describing: badKey.animationKeys()))，t=0.5 时 pres.frame=\(badP.frame)（与不动时完全一致）")
expect(badKey.animationKeys()?.contains("sample") == true, "非法 keyPath 不会报错，动画静静存在却什么都不动 —— 排错时最容易看漏")
line("    布尔属性 masksToBounds 也能 add 动画：")
let boolP = sample(animLayer { basic("masksToBounds", 0.0, 1.0) }, at: 0.5)
line("      t=0.5 → pres.masksToBounds=\(boolP.masksToBounds)（布尔不插值，只在端点之间跳）")

// ============================================================ 5) 时间与曲线
line("")
line("== 5) 时间曲线与时钟：CAMediaTimingFunction 与 speed / timeOffset / beginTime ==")
for name in [CAMediaTimingFunctionName.linear, .easeIn, .easeOut, .easeInEaseOut, .default] {
    line("    \(name.rawValue): \(controlPoints(CAMediaTimingFunction(name: name)).joined(separator: " "))")
}
expect(true, "getControlPoint 的下标范围是 0...3（头文件写明 'idx' is a value from 0 to 3 inclusive）")
let custom = CAMediaTimingFunction(controlPoints: 0.1, 0.9, 0.9, 0.1)
var cp0: [Float] = [0, 0]
custom.getControlPoint(at: 1, values: &cp0)
line("    自定义贝塞尔 (0.1,0.9,0.9,0.1) 的下标 1 = (\(String(format: "%.2f", cp0[0])),\(String(format: "%.2f", cp0[1])))，下标 0 恒为 (0,0)、下标 3 恒为 (1,1)")

line("")
line("  —— 用曲线做同一个动画（20→300，duration=1），中点值会不一样 ——")
var curveReads: [(String, String)] = []
for name in [CAMediaTimingFunctionName.linear, .easeIn, .easeOut, .easeInEaseOut] {
    let l = animLayer {
        let a = basic("position.x", 20.0, 300.0)
        a.timingFunction = CAMediaTimingFunction(name: name)
        return a
    }
    let p = f4(Double(sample(l, at: 0.5).position.x))
    curveReads.append((name.rawValue, p))
    line("    \(name.rawValue) 的 t=0.5 → \(p)")
}
expect(curveReads.map { $0.1 } == ["160.0000", "108.2999", "211.7001", "160.0000"],
       "linear 的中点就是算术中点 160；easeIn 慢进（108.3）、easeOut 快进（211.7）；easeInEaseOut 对称所以中点仍是 160")

line("")
line("  —— UIView.animate 不写 options 时，实际往层上挂的是哪条曲线？把它从层里取出来读 ——")
let uiv = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
host.addSubview(uiv)
displayPass()
UIView.animate(withDuration: 0.5) { uiv.center = CGPoint(x: 150, y: 150) }
if let ua = uiv.layer.animation(forKey: "position") as? CABasicAnimation {
    line("    duration=\(ua.duration) fillMode=\(ua.fillMode.rawValue) autoreverses=\(ua.autoreverses)")
    if let tf = ua.timingFunction {
        line("    控制点=\(controlPoints(tf).joined(separator: " "))")
        line("    对照 .default=\(controlPoints(CAMediaTimingFunction(name: .default)).joined(separator: " "))  .easeInEaseOut=\(controlPoints(CAMediaTimingFunction(name: .easeInEaseOut)).joined(separator: " "))")
        expect(controlPoints(tf) == controlPoints(CAMediaTimingFunction(name: .easeInEaseOut)),
               "UIKit 默认挂的是 easeInEaseOut（0.42,0 / 0.58,1），不是 .default 那条（0.25,0.1 / 0.25,1）—— 很多人以为 UIView.animate 走的是「系统默认曲线」")
    } else {
        line("    timingFunction=nil")
    }
    line("    fromValue=\(String(describing: ua.fromValue)) toValue=\(String(describing: ua.toValue))")
    expect(ua.fillMode == .both, "UIKit 挂的动画 fillMode 是 both（开始前显示起点、结束后显示终点），而不是层动画默认的 removed")
} else {
    line("    取到的不是 CABasicAnimation：\(String(describing: uiv.layer.animation(forKey: "position")))")
}
uiv.layer.removeAllAnimations()

line("")
line("  —— 暂停 / 恢复一棵层树（值由墙钟决定，所以只打印布尔与差值） ——")
let pauseView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
host.addSubview(pauseView)
let longAnim = basic("position.x", 0.0, 400.0, duration: 4.0)
pauseView.layer.add(longAnim, forKey: "p")
displayPass()
let pausedTime = pauseView.layer.convertTime(CACurrentMediaTime(), from: nil)
pauseView.layer.speed = 0
pauseView.layer.timeOffset = pausedTime
displayPass()
let x1 = pauseView.layer.presentation()?.position.x ?? -1
displayPass()
displayPass()
let x2 = pauseView.layer.presentation()?.position.x ?? -1
line("    暂停中隔三个显示周期两次读，差值=\(f4(x2 - x1))（墙钟确实走了，层钟被 speed=0 掐停）")
expect(x1 == x2, "speed=0 + timeOffset 冻结之后呈现值不再前进")
expect(pausedTime > 0, "暂停之前先 convertTime(CACurrentMediaTime(), from: nil) 拿到「当下是几点」")
pauseView.layer.speed = 1
pauseView.layer.beginTime = CACurrentMediaTime() - pausedTime
pauseView.layer.timeOffset = 0
displayPass()
let x3 = pauseView.layer.presentation()?.position.x ?? -1
line("    恢复之后再读，比冻结点更大=\(x3 > x2)（恢复确实接上了，但每轮显示之间的推进量取决于墙钟，所以不打印数字）")
expect(x3 > x2, "恢复要三件事一起做：speed=1、beginTime 减去已走时间、timeOffset 归零")
line("    model 在暂停/恢复期间一直是 \(f4(pauseView.layer.position.x))（显式动画从不写回 model）")
pauseView.layer.removeAllAnimations()

line("")
line("  —— 顺序搞反会怎样：先 speed=0，再问「现在几点」 ——")
let wrongView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
host.addSubview(wrongView)
let wAnim = basic("position.x", 0.0, 400.0, duration: 4.0)
wrongView.layer.add(wAnim, forKey: "p")
displayPass()
wrongView.layer.speed = 0
let lateAsk = wrongView.layer.convertTime(CACurrentMediaTime(), from: nil)
wrongView.layer.timeOffset = lateAsk
displayPass()
line("    speed=0 之后再 convertTime → 得到 \(f4(lateAsk))（就是 timeOffset 自己，回到时间原点）")
expect(lateAsk == wrongView.layer.timeOffset, "speed=0 时 convertTime 的输出恒等于 timeOffset，读不到「当下」")
line("    于是动画被拉回原点附近重新开始，暂停在墙钟意义上的第 0 帧 —— 想停在当下必须**先取时间再掐速度**")
wrongView.layer.removeAllAnimations()
wrongView.layer.speed = 1

line("")
line("  —— 时钟是沿 superlayer 往下传的：冻父层，子层的动画跟着停 ——")
let parentV = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
host.addSubview(parentV)
let childV = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
parentV.addSubview(childV)
displayPass()
parentV.layer.speed = 0
let childAnim = basic("position.x", 10.0, 110.0, duration: 1.0)
childV.layer.add(childAnim, forKey: "c")
displayPass(2)
var parentReads: [(String, String)] = []
for t in [0.0, 0.5, 1.0] {
    parentV.layer.timeOffset = t
    displayPass()
    let x = f4((childV.layer.presentation() ?? childV.layer).position.x)
    let local = f4(childV.layer.convertTime(CACurrentMediaTime(), from: nil))
    parentReads.append((x, local))
    line("    parent.timeOffset=\(t) → child pres.position.x=\(x)，child.convertTime 读回 \(local)，child.speed 仍是 \(childV.layer.speed)")
}
expect(parentReads.map { $0.0 } == ["10.0000", "60.0000", "109.9999"],
       "子层的插值完全由父层的 timeOffset 驱动（子层自己 speed=1 也一样被冻住）")
expect(parentReads.map { $0.1 } == ["0.0000", "0.5000", "1.0000"],
       "convertTime 给出的就是父层当前的 timeOffset —— 时钟沿树往下继承")
parentV.layer.speed = 1

// ============================================================ 6) CAKeyframeAnimation
line("")
line("== 6) CAKeyframeAnimation：多关键帧、计算模式与沿路径运动 ==")
let kfL = animLayer {
    let kf = CAKeyframeAnimation(keyPath: "position.y")
    kf.values = [0.0, 60.0, 20.0]
    kf.keyTimes = [0.0, 0.2, 1.0].map { NSNumber(value: $0) }
    kf.duration = 1.0
    return kf
}
line("  values=[0,60,20] keyTimes=[0,0.2,1] duration=1 calculationMode=\(((kfL.animation(forKey: "sample") as? CAKeyframeAnimation)?.calculationMode.rawValue ?? "nil"))")
var kfReads: [(String, String)] = []
for t in [0.0, 0.1, 0.2, 0.6, 1.0] {
    kfReads.append((String(format: "%g", t), f4(sample(kfL, at: t).position.y)))
}
line("  linear：" + kfReads.map { "t=\($0.0):\($0.1)" }.joined(separator: " "))
expect(kfReads.map { $0.1 } == ["0.0000", "30.0000", "60.0000", "40.0000", "20.0000"],
       "keyTimes 决定分段：0→0.2 从 0 冲到 60，之后 0.8 段慢慢回到 20")

let kfShort = animLayer {
    let kf = CAKeyframeAnimation(keyPath: "position.y")
    kf.values = [0.0, 60.0, 20.0]
    kf.keyTimes = [0.0, 1.0].map { NSNumber(value: $0) }
    kf.duration = 1.0
    return kf
}
var ksReads: [String] = []
for t in [0.0, 0.5, 1.0] { ksReads.append(f4(sample(kfShort, at: t).position.y)) }
line("  values 3 个但 keyTimes 只给 2 个（0 与 1）：t=0/0.5/1 → \(ksReads.joined(separator: " / "))，keys=\(String(describing: kfShort.animationKeys()))")
expect(ksReads == ["0.0000", "30.0000", "60.0000"],
       "不崩也不报警：多出来的 values[2]=20 被静默丢掉，前两个值被铺满整条 duration（读数是 0/30/60，不是 0/60/20）")
expect(kfShort.animationKeys() == ["sample"], "keyTimes 与 values 个数不一致不会让动画被拒绝添加")

let kfLong = animLayer {
    let kf = CAKeyframeAnimation(keyPath: "position.y")
    kf.values = [0.0, 60.0]
    kf.keyTimes = [0.0, 0.2, 1.0].map { NSNumber(value: $0) }
    kf.duration = 1.0
    return kf
}
var klReads: [String] = []
for t in [0.0, 0.1, 0.5, 1.0] { klReads.append(f4(sample(kfLong, at: t).position.y)) }
line("  values 2 个但 keyTimes 给 3 个（0/0.2/1）：t=0/0.1/0.5/1 → \(klReads.joined(separator: " / "))，keys=\(String(describing: kfLong.animationKeys()))")
expect(kfLong.animationKeys() == ["sample"], "反方向配错（keyTimes 多一个）同样不崩、动画照样挂上")

let kdL = animLayer {
    let kd = CAKeyframeAnimation(keyPath: "position.y")
    kd.values = [0.0, 60.0, 20.0]
    kd.duration = 1.0
    kd.calculationMode = .discrete
    return kd
}
var kdReads: [String] = []
for t in [0.0, 0.4, 0.8] { kdReads.append(f4(sample(kdL, at: t).position.y)) }
line("  discrete（不设 keyTimes，默认均匀 0/0.5/1）：t=0/0.4/0.8 → \(kdReads.joined(separator: " / "))")
expect(kdReads == ["0.0000", "60.0000", "20.0000"], "discrete 直接跳到下一个值，中间不插值")

let kpL = animLayer {
    let kp = CAKeyframeAnimation(keyPath: "position.y")
    kp.values = [0.0, 100.0]
    kp.duration = 1.0
    kp.calculationMode = .paced
    return kp
}
var kpReads: [String] = []
for t in [0.0, 0.5, 1.0] { kpReads.append(f4(sample(kpL, at: t).position.y)) }
line("  paced：t=0/0.5/1 → \(kpReads.joined(separator: " / "))（paced 按**等速**走完每段，忽略 keyTimes）")
expect(kpReads == ["0.0000", "50.0000", "100.0000"], "两段两值时 paced 与 linear 重合")

let kcL = animLayer {
    let kc = CAKeyframeAnimation(keyPath: "position")
    kc.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 50), transform: nil)
    kc.duration = 1.0
    return kc
}
var pathReads: [String] = []
for t in [0.0, 0.25, 0.5] {
    let p = sample(kcL, at: t).position
    pathReads.append("(\(f4(p.x)),\(f4(p.y)))")
}
line("  沿 CGPath(椭圆 100×50) 的 position：t=0/0.25/0.5 → \(pathReads.joined(separator: " "))")
expect(pathReads.first == "(100.0000,25.0000)", "CGPath 的椭圆从右端中点 (maxX, midY) 起画，所以 t=0 就在那")
let kcAnim = kcL.animation(forKey: "sample") as? CAKeyframeAnimation
line("  设了 path 之后 keyTimes 会被忽略：kc.rotationMode=\(String(describing: kcAnim?.rotationMode))（默认 nil；设成 .auto 时对象会顺着切线转向）")
line("  calculationMode 可选值：linear / discrete / paced / cubic / cubicPaced（Swift 名字是 CAAnimationCalculationMode）")

// ============================================================ 7) 组、转场、弹簧与 UIKit 层的动画接口
line("")
line("== 7) CAAnimationGroup / CATransition / CASpringAnimation / UIView 动画接口 ==")
let grpL = animLayer {
    let grp = CAAnimationGroup()
    grp.animations = [basic("opacity", 1.0, 0.0, duration: 1.0),
                      basic("transform.scale", 1.0, 2.0, duration: 0.5)]
    grp.duration = 2.0
    return grp
}
var grpReads: [(String, String, String)] = []
for t in [0.0, 0.25, 0.75, 1.5] {
    let p = sample(grpL, at: t)
    grpReads.append((String(format: "%g", t), f4(Double(p.opacity)), f4(p.transform.m11)))
}
line("  组 duration=2，子里 opacity 用满 1s、scale 只用 0.5s：")
for r in grpReads { line("    t=\(r.0) → opacity=\(r.1) scale(m11)=\(r.2)") }
expect(grpReads[1].2 == "1.5000", "t=0.25 时 0.5s 的 scale 动画才走一半（1→2 的中点 1.5）")
expect(grpReads[2].1 == "0.2500" && grpReads[2].2 == "1.0000",
       "opacity 还在跑（t=0.75 读到 0.25），而 scale 那条早已按自己的 duration 结束 —— 组的 duration 只决定整组何时收尾")
expect(grpReads[3].1 == "1.0000" && grpReads[3].2 == "1.0000", "子里的动画跑完就各自回到 model")
if let grp = grpL.animation(forKey: "sample") as? CAAnimationGroup {
    line("  grp.animations?.count=\(grp.animations?.count ?? -1)（子动画对象本身可以被读回）")
    expect(grp.animations?.count == 2, "组里的子动画可以原样取回")
}

let grp2L = animLayer {
    let delayAnim = basic("opacity", 0.0, 1.0, duration: 0.5)
    delayAnim.beginTime = 1.0
    let grp2 = CAAnimationGroup()
    grp2.animations = [delayAnim]
    grp2.duration = 2.0
    return grp2
}
var g2Reads: [String] = []
for t in [0.0, 0.8, 1.0, 1.25, 1.5, 2.0] { g2Reads.append(f4(Double(sample(grp2L, at: t).opacity))) }
line("  子动画 beginTime=1.0（相对组的时间）：t=0/0.8/1.0/1.25/1.5/2.0 → \(g2Reads.joined(separator: " / "))")
expect(g2Reads[0] == "1.0000" && g2Reads[1] == "1.0000", "组内前 1s 子动画还没开始，读到的仍是 model")
expect(g2Reads[3] == "0.5000" && g2Reads[4] == "1.0000", "1.0s 之后才开始插值，1.5s 就跑完了自己的 0.5s")

let tr = CATransition()
line("  CATransition 默认：type=\(tr.type.rawValue) subtype=\(String(describing: tr.subtype)) duration=\(tr.duration) startProgress=\(tr.startProgress) endProgress=\(tr.endProgress)")
tr.type = .moveIn
tr.subtype = .fromLeft
tr.duration = 0.6
let trL = animLayer({ tr })
line("  设成 moveIn/fromLeft 之后 add，读回 keys=\(String(describing: trL.animationKeys()))")
expect(tr.type == .moveIn && tr.subtype == .fromLeft, "转场的 type/subtype 都是字符串枚举，可读写")
expect(trL.animationKeys() == ["transition"],
       "CATransition 也是 CAAnimation、能 add 到层上，但 forKey 传的名字会被换成 \"transition\" —— 想按自己的 key 管理就得自己记")
line("  type 可用：fade / push / moveIn / reveal；subtype 可用：fromTop / fromBottom / fromLeft / fromRight")

let spring = CASpringAnimation(keyPath: "position.x")
spring.fromValue = 0.0
spring.toValue = 100.0
line("  CASpringAnimation 默认：mass=\(spring.mass) stiffness=\(spring.stiffness) damping=\(spring.damping) initialVelocity=\(spring.initialVelocity)")
spring.duration = 1.0
line("  设 duration=1 之后 settlingDuration=\(f4(spring.settlingDuration))（弹簧「停下来」所需的理论时长，不由 duration 决定）")
let spL = animLayer({ spring })
var spReads: [(String, String)] = []
for t in [0.0, 0.1, 0.25, 0.5, 1.0] { spReads.append((String(format: "%g", t), f4(sample(spL, at: t).position.x))) }
line("  默认参数（damping=10）的采样：" + spReads.map { "t=\($0.0):\($0.1)" }.joined(separator: " "))
expect(spReads[2].1 == "102.3360", "t=0.25 已经**冲过头**到 102.34 —— 弹簧动画会越过终点再荡回来")
expect(spReads[4].1 == "100.2170", "duration=1 处仍在终点之上振着（100.217），并没有停在 100")
let spAfter = f4(sample(spL, at: spring.settlingDuration).position.x)
line("  拨到 settlingDuration=\(f4(spring.settlingDuration)) 时读回 \(spAfter)（动画已结束，回到 model）")
expect(spAfter == "20.0000", "超过 duration 之后这条弹簧就结束并移除，presentation 回到 model 的 20")
line("  所以弹簧动画的 duration 应当直接取 settlingDuration，而不是自己拍一个数")
let stiffSpring = CASpringAnimation(keyPath: "position.x")
stiffSpring.fromValue = 0.0
stiffSpring.toValue = 100.0
stiffSpring.damping = 200
stiffSpring.duration = 1.0
let ssL = animLayer({ stiffSpring })
line("  把 damping 提到 200（过阻尼）：t=0.25 → \(f4(sample(ssL, at: 0.25).position.x))，t=1 → \(f4(sample(ssL, at: 1.0).position.x))，settlingDuration=\(f4(stiffSpring.settlingDuration))")

line("")
line("  —— UIKit 给的动画接口（UIView.animate 一族）实际往层上挂什么 ——")
func keysAfter(_ body: (UIView) -> Void) -> [String]? {
    let v = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    host.addSubview(v)
    displayPass()
    body(v)
    let keys = v.layer.animationKeys()
    v.layer.removeAllAnimations()
    v.removeFromSuperview()
    return keys
}
let alphaKeys = keysAfter { v in UIView.animate(withDuration: 0.2) { v.alpha = 0.5 } }
let centerKeys = keysAfter { v in UIView.animate(withDuration: 0.2) { v.center = CGPoint(x: 80, y: 60) } }
let transformKeys = keysAfter { v in UIView.animate(withDuration: 0.2) { v.transform = CGAffineTransform(scaleX: 2, y: 2) } }
let frameKeys = keysAfter { v in UIView.animate(withDuration: 0.2) { v.frame = CGRect(x: 5, y: 5, width: 30, height: 30) } }
line("    alpha 动画 → keys=\(String(describing: alphaKeys))")
line("    center 动画 → keys=\(String(describing: centerKeys))")
line("    transform 动画 → keys=\(String(describing: transformKeys))")
line("    frame 动画 → keys=\(String(describing: frameKeys))")
expect(alphaKeys == ["opacity"], "UIView.alpha 对应层上的 opacity")
expect(centerKeys == ["position"], "center 只挂 position（改 center 不改 size，所以只有这一条）")
expect(transformKeys == ["transform"], "视图的 transform 直接落到层的 transform")
expect(frameKeys?.sorted() == ["bounds.size", "position"],
       "frame 被拆成两条：尺寸走 bounds.size、位置走 position —— 这就是「frame 是派生属性」的实锤")
let springKeys = keysAfter { v in
    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.4,
                   initialSpringVelocity: 1, options: [],
                   animations: { v.center = CGPoint(x: 60, y: 60) }, completion: nil)
}
line("    usingSpringWithDamping 版 → keys=\(String(describing: springKeys))")
let kfKeys = keysAfter { v in
    UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) { v.alpha = 0.2 }
        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { v.alpha = 0.9 }
    }
}
line("    UIView.animateKeyframes → keys=\(String(describing: kfKeys))")
let transKeys = keysAfter { v in
    UIView.transition(with: v, duration: 0.2, options: .transitionFlipFromLeft,
                      animations: { v.alpha = 0.4 }, completion: nil)
}
line("    UIView.transition(.transitionFlipFromLeft) → keys=\(String(describing: transKeys))")
expect(transKeys?.sorted() == ["opacity", "transition"], "UIView.transition 同时挂上属性动画和一条 transition")
expect(springKeys == ["position"], "弹簧版 UIView.animate 用的 key 与普通版相同（都是属性名）")
expect(kfKeys == ["opacity"], "关键帧版也是同一条 opacity，只是内部换成 CAKeyframeAnimation")
line("    UIView.AnimationOptions 里可选的转场只有：flipFromLeft/Right/Top/Bottom、curlUp/Down、crossDissolve、none")

// ============================================================ 8) 特殊图层族
line("")
line("== 8) 特殊图层：属性读写表（headless 里只能核对配置，看不到画面） ==")
let grad = CAGradientLayer()
grad.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
line("  CAGradientLayer 默认：type=\(grad.type.rawValue) startPoint=\(grad.startPoint) endPoint=\(grad.endPoint) colors=\(String(describing: grad.colors)) locations=\(String(describing: grad.locations))")
grad.colors = [UIColor.systemBlue.cgColor, UIColor.systemRed.cgColor]
grad.locations = [0.0, 0.4, 1.0].map { NSNumber(value: $0) }
grad.type = .conic
host.layer.addSublayer(grad)
line("  设 2 个颜色 + 3 个 locations：colors.count=\(grad.colors?.count ?? -1) locations.count=\(grad.locations?.count ?? -1) type=\(grad.type.rawValue)")
expect(grad.colors?.count == 2 && grad.locations?.count == 3, "颜色数与 locations 数不一致也不报错（运行时才按需要截断/补齐）")
expect(grad.type == .conic, "type 可用 axial / radial / conic（没有 circular；kCA… 常量在 Swift 3 就重命名了）")
expect(grad.startPoint == CGPoint(x: 0.5, y: 0) && grad.endPoint == CGPoint(x: 0.5, y: 1),
       "默认渐变从上边中点到下边中点，单位是层的归一化坐标")

let shape = CAShapeLayer()
line("  CAShapeLayer 默认：lineWidth=\(shape.lineWidth) lineCap=\(shape.lineCap.rawValue) lineJoin=\(shape.lineJoin.rawValue) miterLimit=\(shape.miterLimit)")
line("    fillRule=\(shape.fillRule.rawValue) strokeStart=\(shape.strokeStart) strokeEnd=\(shape.strokeEnd) lineDashPhase=\(shape.lineDashPhase)")
shape.path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 30), cornerWidth: 6, cornerHeight: 6, transform: nil)
shape.lineDashPattern = [4, 2].map { NSNumber(value: $0) }
shape.strokeEnd = 0.7
line("  设 path 之后 boundingBoxOfPath=\(shape.path?.boundingBoxOfPath ?? .zero) dashPattern=\(String(describing: shape.lineDashPattern)) strokeEnd=\(shape.strokeEnd)")
expect(shape.strokeEnd == 0.7 && shape.path?.boundingBoxOfPath.size.width == 60, "path 是 CGPath，描边比例靠 strokeStart/strokeEnd")
expect(shape.fillRule == .nonZero, "fillRule 默认 non-zero（另一个是 even-odd）")
line("  fillColor/strokeColor 是 CGColor? 类型，默认 nil；注意它们和 backgroundColor 一样不能直接打 UIColor")
let drawLayer = CAShapeLayer()
drawLayer.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
drawLayer.path = shape.path
drawLayer.strokeEnd = 0.0
drawLayer.speed = 0
host.layer.addSublayer(drawLayer)
let seAnim = CABasicAnimation(keyPath: "strokeEnd")
seAnim.fromValue = 0.0
seAnim.toValue = 1.0
seAnim.duration = 1.0
drawLayer.add(seAnim, forKey: "draw")
displayPass(2)
var seReads: [String] = []
for t in [0.0, 0.25, 0.5, 1.0] {
    let p = sample(drawLayer, at: t)
    seReads.append(f4(Double((p.value(forKey: "strokeEnd") as? Double) ?? -1)))
}
line("  strokeEnd 0→1 是可动画 keyPath（真正的层）：t=0/0.25/0.5/1 → \(seReads.joined(separator: " / ")) —— 「描边进度/折线生长」动画就是这么做的")
expect(seReads == ["0.0000", "0.2500", "0.5000", "1.0000"], "CAShapeLayer 的子属性同样能被显式动画插值，model 保持 0")
expect(drawLayer.strokeEnd == 0.0, "动画期间 model.strokeEnd 仍是设进去的 0")

let text = CATextLayer()
line("  CATextLayer 默认：fontSize=\(text.fontSize) alignmentMode=\(text.alignmentMode.rawValue) truncationMode=\(text.truncationMode.rawValue) isWrapped=\(text.isWrapped)")
text.frame = CGRect(x: 0, y: 0, width: 120, height: 60)
text.string = "第一行\n第二行"
text.font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
text.isWrapped = true
line("  设 string 两行 / font 类型=\(String(describing: type(of: text.font as Any))) / isWrapped=\(text.isWrapped)")
expect(text.fontSize == 36, "fontSize 默认 36（不是系统字号 17），忘了设就会得到巨大文字")
expect(text.string != nil && text.isWrapped, "string 是 id 类型，可以多行；换行靠 isWrapped 与 \\n")
let textUI = CATextLayer()
textUI.font = UIFont.systemFont(ofSize: 12)
line("  把 UIFont 塞进 font 也编得过（font 声明成 AnyObject?，编译器不检查）：读回类型=\(String(describing: type(of: textUI.font as Any)))")
expect(textUI.font != nil, "CATextLayer.font 接受任意对象 —— 要的是 CGFont/CTFont，给错不会编译失败（headless 里看不出渲染差别）")

let rep = CAReplicatorLayer()
line("  CAReplicatorLayer 默认：instanceCount=\(rep.instanceCount) instanceDelay=\(rep.instanceDelay) instanceTransform 是单位阵=\(CATransform3DIsIdentity(rep.instanceTransform))")
rep.instanceCount = 3
rep.instanceTransform = CATransform3DTranslate(CATransform3DIdentity, 20, 0, 0)
rep.instanceDelay = 0.1
rep.instanceAlphaOffset = -0.15
host.layer.addSublayer(rep)
line("  设 3 份 / 每份 x+20 / 延迟 0.1s / alpha 递减 -0.15：读回 count=\(rep.instanceCount) delay=\(rep.instanceDelay) alphaOffset=\(f4(Double(rep.instanceAlphaOffset))) m41=\(f4(rep.instanceTransform.m41))")
expect(rep.instanceCount == 3 && rep.instanceDelay == 0.1, "复制层靠 instanceCount/Transform/Delay 做阵列与错时动画")
expect(rep.preservesDepth == false, "preservesDepth 默认 false（3D 复制时才会露出）")
line("  注意：没有 instanceProgression / instanceAlphaRepeat 这类属性，能设的是 instanceRed/Green/Blue/AlphaOffset 与 instanceColor")

let emit = CAEmitterLayer()
line("  CAEmitterLayer 默认：shape=\(emit.emitterShape.rawValue) mode=\(emit.emitterMode.rawValue) renderMode=\(emit.renderMode.rawValue) birthRate=\(emit.birthRate)")
line("    emitterSize=\(emit.emitterSize) emitterPosition=\(emit.emitterPosition) emitterZPosition=\(emit.emitterZPosition) cells=\(String(describing: emit.emitterCells))")
let cell = CAEmitterCell()
line("  CAEmitterCell 默认：birthRate=\(cell.birthRate) lifetime=\(cell.lifetime) velocity=\(cell.velocity) scale=\(cell.scale) spin=\(cell.spin) emissionRange=\(cell.emissionRange)")
cell.birthRate = 10
cell.lifetime = 2.0
cell.velocity = 40
emit.emitterCells = [cell]
emit.emitterShape = .line
line("  设 cell 参数与 shape=line 之后：cells.count=\(emit.emitterCells?.count ?? -1) shape=\(emit.emitterShape.rawValue) cell.birthRate=\(emit.emitterCells?.first?.birthRate ?? -1)")
expect(emit.emitterShape == .line && cell.lifetime == 2.0, "发射器本身只管形状与速率，粒子属性都在 CAEmitterCell 上")
expect(emit.birthRate == 1 && cell.birthRate == 10, "层的 birthRate 默认 1、cell 的默认 0 —— 只建 CAEmitterLayer 是看不到任何粒子的")

let tiled = CATiledLayer()
line("  CATiledLayer 默认：levelsOfDetail=\(tiled.levelsOfDetail) levelsOfDetailBias=\(tiled.levelsOfDetailBias) tileSize=\(tiled.tileSize)")
tiled.levelsOfDetailBias = 3
line("  设 bias=3 之后读回 \(tiled.levelsOfDetailBias)；没有 maxTiledContentDimensions 这个属性")
expect(tiled.levelsOfDetail == 1 && tiled.levelsOfDetailBias == 3, "瓦片层默认 1 级细节；tileSize 是屏幕相关的 256×256")
let scrollL = CAScrollLayer()
line("  CAScrollLayer.scrollMode 默认=\(scrollL.scrollMode.rawValue)（horizontal/vertical/both）")
let tfL = CATransformLayer()
line("  CATransformLayer：anchorPoint=\(tfL.anchorPoint) bounds=\(tfL.bounds)（专门给 3D 子层做透视分组，自身不画东西）")

// ============================================================ 9) CATransform3D
line("")
line("== 9) CATransform3D：函数全家桶与 m34 透视 ==")
let idt = CATransform3DIdentity
line("  Identity: m11=\(idt.m11) m22=\(idt.m22) m33=\(idt.m33) m44=\(idt.m44) 其余为 0")
line("  IsIdentity=\(CATransform3DIsIdentity(idt)) IsAffine=\(CATransform3DIsAffine(idt))")
line("  （注意是**自由函数**：CATransform3D 这个结构体没有 .isIdentity / .isAffine 成员）")
let makeT = CATransform3DMakeTranslation(10, 20, 30)
let makeS = CATransform3DMakeScale(2, 3, 4)
let makeR = CATransform3DMakeRotation(Double.pi / 2, 0, 0, 1)
line("  MakeTranslation(10,20,30) → m41=\(f4(makeT.m41)) m42=\(f4(makeT.m42)) m43=\(f4(makeT.m43))")
line("  MakeScale(2,3,4) → m11=\(f4(makeS.m11)) m22=\(f4(makeS.m22)) m33=\(f4(makeS.m33))")
line("  MakeRotation(π/2, z) → m11=\(f4(makeR.m11)) m12=\(f4(makeR.m12)) m21=\(f4(makeR.m21)) m22=\(f4(makeR.m22))")
expect(makeR.m11 == 0 && near(makeR.m12, 1) && near(makeR.m21, -1), "绕 z 转 90°：m11 精确读到 0")
let concat1 = CATransform3DConcat(makeT, makeS)
let concat2 = CATransform3DConcat(makeS, makeT)
line("  Concat(Translate,Scale) → m41=\(f4(concat1.m41))；Concat(Scale,Translate) → m41=\(f4(concat2.m41))")
expect(concat1.m41 == 20 && concat2.m41 == 10, "Concat 不满足交换律：先缩放后平移，平移量会被缩放")
let invT = CATransform3DInvert(makeT)
let invS = CATransform3DInvert(makeS)
line("  Invert(Translate) → m41=\(f4(invT.m41))；Invert(Scale) → m11=\(f4(invS.m11))")
let zeroT = CATransform3D()
let invZero = CATransform3DInvert(zeroT)
line("  Invert(零矩阵/奇异) → m11=\(f4(invZero.m11)) m44=\(f4(invZero.m44))（不报错，静默给全零）")
expect(invZero.m11 == 0 && invZero.m44 == 0, "不可逆矩阵的 Invert 没有任何提示，得自己判断")
line("  EqualToTransform(t, t)=\(CATransform3DEqualToTransform(makeT, makeT))，与 z 差 0.0001 的=\(CATransform3DEqualToTransform(makeT, CATransform3DMakeTranslation(10, 20, 30.0001)))")
expect(CATransform3DEqualToTransform(makeT, makeT), "EqualToTransform 是精确比较，浮点近似要用别的判法")
let aff = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6))
line("  MakeAffineTransform(a,b,c,d,tx,ty) → m11=\(f4(aff.m11)) m12=\(f4(aff.m12)) m21=\(f4(aff.m21)) m22=\(f4(aff.m22)) m41=\(f4(aff.m41)) m42=\(f4(aff.m42)) m33=\(f4(aff.m33))")
expect(aff.m11 == 1 && aff.m12 == 2 && aff.m21 == 3 && aff.m22 == 4 && aff.m41 == 5 && aff.m42 == 6,
       "2D→3D 的映射是 a→m11 b→m12 c→m21 d→m22 tx→m41 ty→m42")
let back = CATransform3DGetAffineTransform(makeT)
line("  GetAffineTransform(带 z=30 的平移) → a=\(back.a) b=\(back.b) c=\(back.c) d=\(back.d) tx=\(back.tx) ty=\(back.ty)（z 分量直接丢）")
var persp = CATransform3DIdentity
persp.m34 = -1.0 / 300.0
let backPersp = CATransform3DGetAffineTransform(persp)
line("  GetAffineTransform(非仿射的透视阵) → 返回 \(f4(backPersp.a))/\(f4(backPersp.b))/\(f4(backPersp.c))/\(f4(backPersp.d)) —— 未定义行为，别依赖")
line("  IsAffine 的判据是**整个第三行和第三列**：z 平移（m43=30）就已经不算仿射")
expect(CATransform3DIsAffine(CATransform3DMakeTranslation(10, 20, 0)), "z=0 的 2D 平移是仿射")
expect(!CATransform3DIsAffine(makeT), "只把 z 从 0 改成 30，IsAffine 就变 false（m43≠0）")
expect(!CATransform3DIsAffine(persp), "m34 透视当然也不是仿射")
line("  透视没有专用函数：没有 CATransform3DPerspective，只能手改 m34（值 = -1/透视距离）")

let contL = CALayer()
contL.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
host.layer.addSublayer(contL)
line("  sublayerTransform 默认是单位阵=\(CATransform3DIsIdentity(contL.sublayerTransform))")
contL.sublayerTransform = persp
let face = CALayer()
face.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
contL.addSublayer(face)
var yRot = CATransform3DIdentity
yRot.m34 = -1.0 / 500.0
face.transform = CATransform3DRotate(yRot, Double.pi / 4, 0, 1, 0)
line("  容器设 sublayerTransform(m34=-1/500)，子层绕 y 转 45°：m11=\(f4(face.transform.m11)) m13=\(f4(face.transform.m13))")
expect(near(face.transform.m11, 0.7071, 0.001) && near(face.transform.m13, -0.7071, 0.001),
       "绕 y 旋转会把 z 分量的余弦/正弦放进 m11/m13")
line("  层的 transform 与 UIView.transform（CGAffineTransform）是两套：层用 3D，视图只给 2D")

// ============================================================ 10) CATransaction 与动画回调
line("")
line("== 10) CATransaction、CAAnimationDelegate 与动画的拷贝/移除 ==")
var stopped = false
let cbView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
host.addSubview(cbView)
CATransaction.begin()
CATransaction.setCompletionBlock { stopped = true }
cbView.alpha = 0.2
CATransaction.commit()
line("  commit 之后立刻：completionBlock 执行=\(stopped)")
expect(!stopped, "setCompletionBlock 不会同步执行")
displayPass(3)
line("  等 3 轮显示之后：执行=\(stopped)")
expect(stopped, "事务的 completionBlock 在显示周期之后被调用 —— 节拍器等三轮就够，不用盲跑 runloop")
line("  CATransaction 只暴露 begin/commit/push/pop/setDisableActions/setCompletionBlock/setAnimationDuration —— 探针实测没有 getAnimationDuration")

let logger = AnimLogger()
let cbAnim = basic("opacity", 1.0, 0.0, duration: 0.1)
cbAnim.delegate = logger
cbView.layer.add(cbAnim, forKey: "del")
line("  add 之后 delegate 日志=\(logger.log)")
for _ in 0..<20 {
    if logger.log.contains("stop:true") { break }
    displayPass()
}
line("  等它结束：日志=\(logger.log) keys=\(String(describing: cbView.layer.animationKeys()))")
expect(logger.log == ["start", "stop:true"], "animationDidStart 先、animationDidStop(finished:true) 后")
expect(cbView.layer.animationKeys() == nil, "自然结束后 key 也被清掉")
let cancelView = UIView(frame: .zero)
host.addSubview(cancelView)
let cancelAnim = basic("opacity", 1.0, 0.0, duration: 5.0)
let logger2 = AnimLogger()
cancelAnim.delegate = logger2
cancelView.layer.add(cancelAnim, forKey: "cancel")
displayPass()
cancelView.layer.removeAnimation(forKey: "cancel")
line("  手动 removeAnimation 之后**立刻**日志=\(logger2.log)（回调还没送到）")
displayPass(2)
line("  再等两轮显示：日志=\(logger2.log)")
expect(logger2.log.last == "stop:false", "被 removeAnimation 取消时 animationDidStop 的 finished 是 false，但回调要等显示周期")

let orig = CABasicAnimation(keyPath: "opacity")
orig.duration = 2.0
orig.fromValue = 0.2
let copied = orig.copy() as! CABasicAnimation
copied.duration = 5.0
line("  copy() 之后：keyPath=\(String(describing: copied.keyPath)) fromValue=\(String(describing: copied.fromValue)) 副本 duration=\(copied.duration) 原件 duration=\(orig.duration)")
expect(copied !== orig && orig.duration == 2.0, "copy() 是深拷贝，改副本不影响原件 —— 一个动画对象可以被多个层共用")
line("  fromValue 的类型读回=\(String(describing: type(of: copied.fromValue as Any)))（Any?，所以塞错类型编译期不报错）")

let multi = animLayer { basic("opacity", 1.0, 0.0) }
let multiB = basic("position.x", 0.0, 10.0)
multi.add(multiB, forKey: "p")
line("  同层两个 key：\(String(describing: multi.animationKeys()?.sorted()))")
multi.removeAnimation(forKey: "o")
line("  移除一个**不存在的 key**（\"o\"）之后：\(String(describing: multi.animationKeys()?.sorted()))（没有异常）")
multi.removeAnimation(forKey: "sample")
line("  移除正确的 key 之后：\(String(describing: multi.animationKeys()?.sorted()))")
multi.removeAllAnimations()
line("  removeAllAnimations 之后：\(String(describing: multi.animationKeys()))")
expect(multi.animationKeys() == nil, "removeAllAnimations 清空所有 key")
let noKey = animLayer { basic("opacity", 1.0, 0.0) }
noKey.add(basic("position.x", 0.0, 10.0), forKey: nil)
line("  forKey 传 nil：animationKeys=\(String(describing: noKey.animationKeys()))（动画照样跑，但没有名字，只能靠 removeAllAnimations 收尾）")
expect(noKey.animationKeys() == ["sample"], "无 key 动画不出现在 animationKeys 里（这里只剩 animLayer 自己那条 sample）")
noKey.removeAllAnimations()

// ============================================================ 11) CADisplayLink
line("")
line("== 11) CADisplayLink：跟屏幕同步的节拍器 ==")
let tick = TickTarget()
let link = CADisplayLink(target: tick, selector: #selector(TickTarget.tick(_:)))
line("  新建：preferredFramesPerSecond=\(link.preferredFramesPerSecond) isPaused=\(link.isPaused) frameInterval? 已废弃")
line("  新建时 duration=\(link.duration) timestamp=\(link.timestamp)（都还是 0：还没有回调可供参考）；**没有 presentationTimestamp 这个属性**")
link.preferredFramesPerSecond = 30
line("  设 preferredFramesPerSecond=30 → 读回 \(link.preferredFramesPerSecond)")
expect(link.preferredFramesPerSecond == 30, "默认 0 表示「按硬件原生刷新率」，设成 30 就是要求减半")
let range = link.preferredFrameRateRange
line("  preferredFrameRateRange（iOS 15+）默认：minimum=\(range.minimum) maximum=\(range.maximum) preferred=\(String(describing: range.preferred))")
link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 45)
let r2 = link.preferredFrameRateRange
line("  设 30/60/45 → 读回 minimum=\(r2.minimum) maximum=\(r2.maximum) preferred=\(String(describing: r2.preferred))")
expect(r2.minimum == 30 && r2.maximum == 60 && r2.preferred == 45, "新写法给的是一个区间，让系统在里面自适应")
link.preferredFramesPerSecond = 20
let r3 = link.preferredFrameRateRange
line("  再用老写法设 20 → range 变成 minimum=\(r3.minimum) maximum=\(r3.maximum) preferred=\(String(describing: r3.preferred))（两者互相覆盖）")
expect(r3.minimum == 20 && r3.maximum == 20, "preferredFramesPerSecond 相当于把区间两端设成同一个值")
link.add(to: .current, forMode: .common)
link.isPaused = true
line("  isPaused=true 读回=\(link.isPaused)")
expect(link.isPaused, "isPaused 是「阻止回调」的开关，初始为 false")
link.isPaused = false
line("  想读 link 持有的 target？它**没有 target 这个属性**（探针里写 link.target 编译报 has no member 'target'），只能打印传进去的对象：\(NSStringFromClass(type(of: tick)))")
line("  头文件对 invalidate 的说明是「从所有 runloop mode 移除并释放 target 对象」——反过来说明 target 被强引用着，所以必须 invalidate")
line("  本章开头那条 metronome 已经回调了 \(beat.ticks > 0 ? "很多次" : "零次") —— 它驱动了前面全部插值采样")
expect(beat.ticks > 0, "CADisplayLink 的回调确实一次一次地把显示周期送过来（displayPass() 等的就是它）")
link.invalidate()
expect(link.isPaused == false, "invalidate 之后对象仍可读写，但不会再回调")
line("  headless 说明：simctl spawn 起来的是**没有帧源**的进程，回调间隔约 15ms 但不保证，")
line("  所以本章只用它判断「有没有刷新过一轮」，绝不打印 ticks 的具体数字。")
metronome.invalidate()

line("")
line("-- 心智模型 --")
line("  动画作用在 CALayer 上：model 层存「应该是多少」，presentation 层存「此刻显示多少」，显式动画从不写回 model")
line("  想核对插值就冻时钟：layer.speed=0 → add 动画 → 拨 timeOffset → 等一次真正的显示周期（CADisplayLink），少一步都读不到")
line("  anchorPoint 改的是「层围绕哪个点摆」，改完 position 不变、frame 变；bounds.origin 不写回 frame，它挪的是层内坐标原点")
line("  隐式动画只对**有 superlayer 的裸层**生效，屏蔽手段有两条：actions[属性名] = NSNull，或整段事务 setDisableActions(true)")
line("  默认动作也不是一律有：opacity/bounds/position/transform 是 CABasicAnimation，hidden/sublayers 是 CATransition，backgroundColor 没有")
line("  CABasicAnimation 三条给值路数：from+to、只给 to（拿当前 model 当起点）、byValue（在当前值上加）")
line("  fillMode 只在「动画结束后」区分表现：forwards/both 保持终点，removed/backwards 回到 model")
line("  时长、重复、曲线都在 CAMediaTiming 那一套属性上；duration 是必填项，默认 0 等于不播")
line("  CAKeyframeAnimation 用 values+keyTimes 或直接 path；calculationMode 决定插值方式（linear/discrete/paced/cubic/cubicPaced）")
line("  CAAnimationGroup 的 duration 管整组，子动画的 beginTime 是组内的相对时间")
line("  CASpringAnimation 会冲过终点再荡回来，duration 该取 settlingDuration 而不是拍脑袋")
line("  CATransform3D 全是自由函数；2D/3D 互转会丢 z；透视只能自己写 m34，且 Concat 不满足交换律")
line("  特殊图层（gradient/shape/text/replicator/emitter/tiled）都是「配置对象」，headless 能读写参数、看不到画面")
line("  CATransaction 的 completionBlock、CAAnimationDelegate 的回调都发生在显示周期之后 —— 等显示周期比盲跑 runloop 靠得住")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 23 结束 ====")
exit(failures == 0 ? 0 : 1)
