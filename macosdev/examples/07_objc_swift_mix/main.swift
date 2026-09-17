// ============================================================
// 07 - Objective-C 与 Swift 混编
//   桥接头（Swift → OC）/ 生成的 Swift 头文件（OC → Swift）
//   / 方法名翻译规则 / nullability / NSError** → throws / block → 闭包
//
// 编译（脚本就是这么干的，这里拆成三步方便看清发生了什么）：
//   # 1. 先编 Swift，顺便生成 OC 能用的头文件
//   swiftc -c -sdk $SDK -target x86_64-apple-macos12.0 -module-name objc_swift_mix \
//          -import-objc-header Bridging.h -emit-objc-header-path build/SwiftBridge-Swift.h \
//          main.swift SwiftCounter.swift
//   # 2. 再编 OC（它要 #import "SwiftBridge-Swift.h"）
//   clang -c -fobjc-arc -fmodules -isysroot $SDK -I build Greeter.m ObjcCaller.m
//   # 3. 一起链接
//   swiftc *.o -o 07_objc_swift_mix -framework Foundation
//
// 为什么必须分两步：OC 要 include Swift 生成的头文件，而那个头文件只有
// 编完 Swift 才存在。Xcode 的 build system 自动处理这个顺序，命令行得自己排。
// ============================================================

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

// MARK: - 1) Swift 调用 Objective-C

print("== Swift 调用 Objective-C ==")
let greeter = Greeter()
greeter.name = "Cocoa"
// 有 NS_ASSUME_NONNULL 注解，所以这里是 String 而不是 String?，不需要解包
let greeting: String = greeter.greet("Swift")
print("  greet = \(greeting)")
expect(greeting == "Cocoa says hello to Swift", "Objective-C 方法被 Swift 直接调用")

// NSArray<NSString *> 自动变成 [String]
try? greeter.loadNames(from: "Swift, Objective-C, C")
let names: [String] = greeter.names
print("  names = \(names.joined(separator: " / "))")
expect(names.count == 3, "OC 的 NSArray 到 Swift 里就是 [String]")
expect(names[0] == "Swift", "索引访问一致（逗号后的空格被 trim 掉）")

// NSError ** 参数 → Swift 的 throws，调用点要写 try
do {
    try greeter.loadNames(from: "Swift, Objective-C, C")
    expect(true, "返回 YES 时不抛错")
} catch {
    expect(false, "不该走到 catch")
}

// block → Swift 闭包，参数顺序照 OC 的签名来
var collected: [String] = []
greeter.forEachName { name, index in
    collected.append("\(index):\(name)")
}
print("  forEach = \(collected.joined(separator: " "))")
expect(collected == ["0:Swift", "1:Objective-C", "2:C"], "OC 的 block 在 Swift 里是闭包")

// MARK: - 2) 没有 nullability 注解的 API 长什么样

print("")
print("== nullability 的影响 ==")
let legacy = LegacyNote()
// 注意是 text() 而不是 text：OC 的 - (NSString *)text 只有一个参数都没有，
// 但因为没有声明成 @property，Swift 就照「方法」导入，只能加括号调用。
// LegacyNote 没加 NS_ASSUME_NONNULL，Swift 把 text 当成 String!（隐式解包可选）。
// 下面这一行能编译，是因为 Swift 会自动解包 —— 真返回 nil 时它会在这一行崩掉。
let legacyText: String = legacy.text()
print("  legacy = \(legacyText)")
expect(legacyText == "来自 OC 的老字符串", "没有注解的 API 也能用，但类型是 String!")
// 想安全地用，就自己判一次：
let safeText: String? = legacy.text()   // 显式声明成可选就不会自动解包
expect(safeText != nil, "显式声明成 String? 就能安全判空")

// MARK: - 3) Objective-C 调用 Swift

print("")
print("== Objective-C 调用 Swift ==")
let caller = ObjcCaller()
let count = caller.askSwiftForCount()
print("  OC 侧拿到的计数 = \(count)")
expect(count == 7, "OC 里两次 incrementBy 累加成 7（5 + 2）")

let themeName = caller.describeTheme(withRawValue: DisplayTheme.dark.rawValue)
print("  OC 侧描述 dark = \(themeName)")
expect(themeName == "dark", "Swift 的 @objc enum 在 OC 里是 NS_ENUM")
expect(caller.describeTheme(withRawValue: DisplayTheme.light.rawValue) == "light",
       "light 分支也正确")

// 直接用 Swift 类本身再验一遍（OC 那边操作的是另一个实例）
let counter = SwiftCounter()
counter.increment(by: 3)
expect(counter.count == 3, "Swift 侧自增 3")
expect(counter.describe() == "SwiftCounter(3)", "describe() 正确")

print("==== 07 结束 ====")
exit(failures == 0 ? 0 : 1)
