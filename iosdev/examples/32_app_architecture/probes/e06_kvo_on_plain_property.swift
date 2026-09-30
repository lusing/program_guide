// 探针 e06：想让 Controller 之外的东西**观察** score，就得给它加那两个词
//
// 主线 QuizViewController.swift 里 `var score` 前面多写了 `@objc dynamic`，
// 注释说这不是风格改动：§19/§20 用 KVO（`observe(\.score)`）来量「谁在这次数变化时
// 被叫到」，而 KVO 是靠 isa-swizzling 换掉 setter 实现的（第 27 章），
// 一个纯 Swift 的属性根本不会被换。
// 这一支抄的是「不加那两个词」的编译器原文 —— 它是那条限制的凭据。
// 第二小段是对照：加了 @objc 但用字符串 keyPath（老 API）会怎样。
//
// 跑法：bash probes/run.sh e06
import UIKit

final class PlainQuiz: UIViewController {
    var score: Int = 0
}

final class ObjCQuiz: UIViewController {
    @objc dynamic var score: Int = 0
}

let plain = PlainQuiz()
let token = plain.observe(\.score) { _, change in print(change.newValue) }
print(token)

// 这一支只量**不合法**的那一句：同一个表达式写在带 @objc dynamic 的属性上
// （主线 QuizViewController 的 score）是编译通过的，§19 的断言就是它。
