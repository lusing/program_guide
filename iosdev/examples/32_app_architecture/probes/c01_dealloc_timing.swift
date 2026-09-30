// 探针 c01：一次「把强引用置空」的赋值之后，weak 读回来是不是**当场**就是 nil？
//
// 起因：§25 原本想把断言写成「releaseAlert() 之后弱引用当场变 nil」。这一族（cNN）的
// 定义就是把「结论随配置变」的那一类量出来，所以先别改断言，把七种位置各跑两遍。
//
// 要分开看的三件事：
//   [1][2] 还有别的强引用没走完（局部量、顶部作用域的变量）—— 这种「还在」是**语义**，
//          两种配置都该一致
//   [3][4] 断环的那一句里，编译器从 weak 属性**临时**提升到强引用的那一份存在到哪
//          （顶部作用域 vs 函数作用域）—— 这一件才是可能随配置变的地方
//   [5]    换成正主线的形状：UIViewController + UIAlertController（UIKit 工厂方法返回值）
//
// 实测结论（写在结果而不是猜测上）：[5] 与 [6] 在 -Onone 和 -O 下**都是**「还在」，
// 两份 stdout 一字不差 —— 所以决定回收时机的不是优化等级，是**对象在哪一层自动释放池里
// 造出来**（只有 [7] 那种「连创建都在池子里」才收得干净）。§25 因此把判据挪到池子边界上。
//
// 跑法：bash probes/run.sh c01 —— 同一份源码用 -Onone 和 -O 各编各跑，看两份 stdout。
import UIKit

final class Node {
    var name: String
    init(_ name: String) { self.name = name }
    deinit { print("  deinit：\(name) 被收了") }
}

final class Holder {
    var kept: Node?
    var handler: (() -> Void)?
    func drop() { kept = nil; handler = nil }
}

weak var seen: Node?

print("[1] 环由一个**函数**里的局部强引用建成，断环也写在函数里：")
func insideFunction() {
    let n = Node("n1")
    seen = n
    let h = Holder()
    h.kept = n
    h.handler = { _ = n }      // h → handler → n，而 n 上没有回指：这不是环，是 h 抓了两份
    print("    函数内 drop 之前：weak=\(seen == nil ? "nil" : "还在")")
    h.drop()
    print("    h.drop() 之后、函数还没返回：weak=\(seen == nil ? "nil" : "还在")（局部 n 这条强引用还没走完）")
}
insideFunction()
print("    函数返回之后：weak=\(seen == nil ? "nil" : "还在")")
seen = nil

print("[2] 只有环、别处没有强引用，而断环那一句写在**顶部作用域**：")
weak var escaped: Holder?
func makeCycle() {
    let h = Holder()
    escaped = h
    h.handler = { _ = h }      // h → handler → h：自己抓自己的环
}   // h 这条局部强引走到这儿结束
makeCycle()
print("    造完之后：weak=\(escaped == nil ? "nil" : "还在")（环成立，局部强引用没了也收不掉）")
escaped?.drop()                // ← 断环这一句在顶部作用域；它先做一次 weak→强 的提升
print("    顶部作用域 drop 之后：weak=\(escaped == nil ? "nil" : "还在")")

print("[3] 同一个环，把断环那一句包进**函数**：")
func dropFromFunction() { escaped?.drop() }   // 临时强引用在函数作用域里，返回就死
dropFromFunction()
print("    函数返回之后：weak=\(escaped == nil ? "nil" : "还在")")
escaped = nil

print("[4] 顶部作用域：先断环，再测第二次（同一个 weak 变量，隔一句再看）")
func makeCycle4() {
    let h = Holder()
    escaped = h
    h.handler = { _ = h }
}
makeCycle4()
print("    造完之后：weak=\(escaped == nil ? "nil" : "还在")")
escaped?.drop()
print("    drop 这一句之后立刻读：weak=\(escaped == nil ? "nil" : "还在")")
print("    隔一句再读：weak=\(escaped == nil ? "nil" : "还在")")
escaped = nil

print("[5] 正主线的形状：UIViewController + UIAlertController（UIKit 工厂方法）+ 抓 self 的 handler")
final class Quiz: UIViewController {
    var alert: UIAlertController?
    var handler: ((UIAlertAction) -> Void)?
    var touched = false
    func build() {
        let a = UIAlertController(title: "t", message: "m", preferredStyle: .alert)
        let block: (UIAlertAction) -> Void = { _ in self.touched = true }
        self.handler = block
        a.addAction(UIAlertAction(title: "ok", style: .default, handler: block))
        self.alert = a
    }
    func release() { alert = nil; handler = nil }
}
weak var seenQuiz: Quiz?
func makeQuiz() {
    let q = Quiz()
    q.build()
    seenQuiz = q
}
makeQuiz()
print("    函数返回后：weak=\(seenQuiz == nil ? "nil" : "还在")（q→alert→action→handler→q）")
seenQuiz?.release()
print("    顶部作用域 release 之后：weak=\(seenQuiz == nil ? "nil" : "还在")")
func releaseFromFunction() { seenQuiz?.release() }
makeQuiz()
releaseFromFunction()
print("    换成包在函数里 release 之后：weak=\(seenQuiz == nil ? "nil" : "还在")")
seenQuiz = nil

print("[6] 同样的 release，外面包一层 autoreleasepool：")
makeQuiz()
print("    进池之前：weak=\(seenQuiz == nil ? "nil" : "还在")")
autoreleasepool { seenQuiz?.release() }
print("    池子退出之后：weak=\(seenQuiz == nil ? "nil" : "还在")")
seenQuiz = nil

print("[7] 连**创建**都放进池子里（书里那个 alert 就是这种：局部变量 + 一次 release 全清）：")
func makeQuizInPool() { autoreleasepool { let q = Quiz(); q.build(); seenQuiz = q } }
makeQuizInPool()
print("    创建函数返回后：weak=\(seenQuiz == nil ? "nil" : "还在")")
autoreleasepool { seenQuiz?.release() }
print("    断环 + 池子退出之后：weak=\(seenQuiz == nil ? "nil" : "还在")")
seenQuiz = nil

print("==== c01 结束 ====")
