// ============================================================
// Model 层第一个文件 —— 书 7.2 的 Question.swift
//
// 这个文件**只 import Foundation**。这不是风格问题，本章 §1 把它当成一条断言来量：
// 一个不碰 UIKit 的层，能不能在没有窗口、没有 UIApplication 的进程里被完整使用。
// 判据：如果这个文件里的任何类型引用了 UIView/UIViewController，本章的产物在
// 构造它们时就会依赖 UIKit 的运行时环境 —— 那时 §1 的断言就无从谈起。
// ============================================================

import Foundation

/// 书 7.2 的最终形态，属性与方法逐字照搬：两个 let + 一个带外部标签的 init。
class Question {

    let questionText: String
    let answer: Bool

    init(text: String, correctAnswer: Bool) {
        questionText = text
        answer = correctAnswer
    }
}

/// 书 7.2 的中间那步：把默认值直接写进属性，报错消失但等于没写。
/// 留着它是为了量「常量在类型上定死」这件事的运行后果（主线 §2）。
final class QuestionWithDefault {

    let questionText: String = "你还是你吗？"
    let answer: Bool = true
}

/// 可变版：把 `let` 换成 `var`，才会出现「改了它，谁受影响」这个问题。
/// §3 用它的 didSet 计数，§12 用它的「改了 Model，界面上一个字都没变」。
///
/// 注意 didSet **在 init 里不触发** —— 这是 Swift 的规矩，也是给 Model 挂观察者时
/// 最常见的一次误判。编译器这一半有两条原文：常量根本挂不了观察者（探针 e03），
/// 想在 init 里就把 self 交给观察者会被当场拒绝（探针 e04）；主线 §3 量的是运行时这一半。
final class MutableQuestion {

    var questionText: String {
        didSet { mutations += 1 }
    }
    var answer: Bool {
        didSet { mutations += 1 }
    }
    /// 自己数的「被改过几次」。init 里的两次赋值不算，所以出厂值是 0。
    private(set) var mutations = 0

    init(text: String, correctAnswer: Bool) {
        questionText = text
        answer = correctAnswer
    }
}

// ============================================================
// 书 7.13 挑战题里的 Question —— 第二条产品线的 Model
//
// 与原书的 Question 只差三件事：选项是个数组、分值是个数组、答案不再是一个 Bool。
// 书 7.5 说「数据模型与视图永远不会直接发生联系……如果项目在法国运行，可以把数据
// 从英文换成法文而不用考虑其他代码」—— 7.13 就是这句话的实战版，主线 §26 拿它验证。
// ============================================================

final class QuestionEQ {

    let questionText: String
    let questionOption: [String]
    let questionScore: [Int]

    init(text: String, option: [String], score: [Int]) {
        questionText = text
        questionOption = option
        questionScore = score
    }

    /// 书 7.13 步骤 2 末尾那句警告的落点：「questionOption 和 questionScore 这两个数组的
    /// 元素个数必须一致，否则会超出数组范围，导致应用程序崩溃」。这里只是把两数读出来，
    /// 「按钮的下标对着档数更少的题」那一撞归探针 r03（主线 §28 只断言个数，不执行那一下）。
    var shapeMatched: Bool { questionOption.count == questionScore.count }
}

// ============================================================
// §6 的对照组：同一份 Model 用 struct 写
//
// 书 7.3 花了一整节讲「类是蓝图、对象是造出来的那台车」，7.2 于是把 Question 写成了
// class。这一节没有任何「必须用 class」的理由 —— 两个只读字段更适合 struct，而这不是
// 风格之争：它决定了「我改了它，别人看见吗」。§6 拿两版逐条量。
// ============================================================

struct QuestionValue {

    let questionText: String
    let answer: Bool

    init(text: String, correctAnswer: Bool) {
        questionText = text
        answer = correctAnswer
    }
}

/// 一个只有「一个整数状态」的最小宿主，用来自问「状态传进函数再改，外面看见吗」。
struct ValueCounter {
    var n = 0
}

