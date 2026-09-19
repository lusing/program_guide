// ============================================================
// 07 - Swift 与 Objective-C 混编（双向）
//
// 混编要在两个方向上都走通：
//   Swift → OC：靠 bridging header（Bridging.h，swiftc -import-objc-header 传入）
//   OC → Swift：靠 swiftc 生成的 <Module>-Swift.h（-emit-objc-header-path 产出）
// Xcode 帮你配好了这两样，命令行要自己拼（run-all.sh 里就是这么拼的）。
//
// 本文件是 Swift 入口（main.swift，含顶层代码），驱动两个方向各演示一遍。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 07 Swift ⇄ Objective-C 混编 ==")

// ------------------------------------------------ 方向一：Swift 调用 OC
line("")
line("-- Swift → OC（经 Bridging.h）--")
// Greeter 加了 NS_ASSUME_NONNULL，所以 Swift 看到的是非可选 String，不是 String!。
let greeter = Greeter(name: "iOS")
let g = greeter.greet("开发者")           // greet: → Swift 的 greet(_:)
expect(g.contains("iOS") && g.contains("开发者"), "调用 OC 实例方法 greet(_:)")

// BOOL + NSError** 的 OC 方法，Swift 自动翻译成 throws。
do {
    try greeter.loadNames(from: "a,b,c")   // loadNamesFrom:error: → loadNames(from:) throws
    expect(greeter.names == ["a", "b", "c"], "throws 版 OC 方法成功路径")
} catch {
    expect(false, "不应抛错：\(error)")
}
do {
    try greeter.loadNames(from: "")
    expect(false, "空输入本应抛错")
} catch {
    expect(true, "OC 返回 NO+NSError 被翻译成 Swift 抛错")
}

// 轻量泛型：names 在 Swift 里是 [String]，不是 [Any]。
let firstUpper = greeter.names.first?.uppercased()
expect(firstUpper == "A", "OC 的 NSArray<NSString*> 在 Swift 里是 [String]（无需 as?）")

// nullability 反面教材：LegacyNote 没加注解，Swift 端 text() 返回 String!。
let legacy = LegacyNote()
let legacyText: String = legacy.text()      // 隐式解包，编译器放行
expect(legacyText.contains("老字符串"), "无注解的 OC API 也能用，但类型是 String!（危险）")
let safeText: String? = legacy.text()       // 显式声明成可选才安全
expect(safeText != nil, "显式声明成 String? 就能安全判空")

// ------------------------------------------------ 方向二：OC 调用 Swift
line("")
line("-- OC → Swift（经生成的 -Swift.h）--")
let caller = ObjcCaller()
let total = caller.runCounter(withFirst: 5, second: 2)   // OC 里 new 了 SwiftCounter
expect(total == 7, "OC 调用 Swift 的 SwiftCounter 累加成 7（5+2）")
expect(caller.describeTheme(1) == "dark", "Swift 的 @objc enum 在 OC 里是 NS_ENUM（dark）")
expect(caller.describeTheme(0) == "light", "light 分支也正确")

// Swift 侧也直接用同一个 SwiftCounter（证明它对两边都可见）
let counter = SwiftCounter()
counter.increment(by: 3)
expect(counter.count == 3 && counter.describe() == "count=3", "Swift 侧自增 3，describe 正确")

// ------------------------------------------------ 混编规则小结（打印）
line("")
line("-- 混编规则 --")
line("  Swift→OC：Bridging.h 里 #import 的 OC 头，全模块可见")
line("  OC→Swift：只有 @objc + NSObject 子类的 Swift 声明才进 -Swift.h")
line("  nullability：加了是 String，不加是 String!（定时炸弹）")
line("  轻量泛型：NSArray<NSString*> → [String]；不写泛型 → [Any]")
expect(true, "两个方向都跑通")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 07 结束 ====")
exit(failures == 0 ? 0 : 1)
