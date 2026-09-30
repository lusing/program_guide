// 探针 e05：书 7.11 那行进度条算式，现代 Swift 报的不是书里说的那个位置
//
// 书 7.11 先写
//     progressBar.frame.size.width = (view.frame.size.width / 13) * questionNumber
// 正文的解释是「在乘号（*）的两侧不能一边是单精度值，一边却是整型值」，
// 给出的修法是「改成 CGFloat(questionNumber + 1)」。
//
// [1] 就是那一行原样。量出来的原文和书里的说法**对不上两处**：
//     · 光标落在**除号**上，不是乘号；
//     · 消息讲的是「DurationProtocol 要求 CGFloat  conform」，一个与本题无关的协议
//       —— 这是重载消解失败时编译器的「最后一搏」，不是「单精度乘整型」这句话。
//   所以 §15 不能引书里的解释：类型这一侧真正的原因是 CGFloat 与 Int 之间**没有**
//   任何混算重载，编译器只能挨个试、然后把试到最后那个奇怪的候选说给你听。
// [2] 是为了把这件事和「书里的说法」分干净而做的最小样本：单看乘号，
//   CGFloat * Int 的原文是哪一句。
//
// 主线 §15 量的是能被算出来的那一半（Int 除法会截掉多少像素），这里只留编译器说的话。
//
// 跑法：bash probes/run.sh e05
import UIKit

final class QuizViewController: UIViewController {
    let progressBar = UIView()
    var questionNumber: Int = 0

    func bookLine() {
        progressBar.frame.size.width = (view.frame.size.width / 13) * questionNumber
    }
}

// [2] 最小样本：只有乘号两侧类型不同，看它单独报哪一句
let unit: CGFloat = 30.923076923076923
let count = 13
let raw = unit * count                // ← 书里那句「一单一整」指的正是这一行
print(raw)
