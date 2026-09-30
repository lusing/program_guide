// 探针 e03：Model 的字段写成 `let` 之后，编译器接管了哪两件事
//
// 书 7.2 把 Question 的两个属性写成 let（它没有别的选择：判断题的答案不该改），
// 主线 §2/§3 用「可变性来自声明用 let 还是 var」来讲这件事，并为此造了一个
// MutableQuestion（var + didSet）。这一支抄的是那条纪律的**编译器一侧**原文，两问：
//   [1] 「控制器把当前题的答案改一下」—— 不能赋值；
//   [2] 「那就挂个观察者看着它」—— 常量根本不允许挂观察者，
//       所以 MutableQuestion 那个类是**被迫**存在的：要可观察，先得是可变的。
// 这两条都是类型检查阶段的错误，所以一次编译能同时报出来（对照 e04：那条要等
// 类型检查全过了才会轮到它 —— 一个文件里两类检查不会同时说话）。
//
// 跑法：bash probes/run.sh e03
import Foundation

final class Question {
    let questionText: String
    let answer: Bool

    init(text: String, correctAnswer: Bool) {
        questionText = text
        answer = correctAnswer
    }

    // [2] 想「不改它但看着它」：常量上挂不了观察者
    let wrongWayToWatch: String {
        didSet { print("变了") }
    }
}

// [1] 想改它
var q = Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
q.answer = false
q = Question(text: "换一道题。", correctAnswer: false)   // ← 这一行合法：let 不在 q 上
