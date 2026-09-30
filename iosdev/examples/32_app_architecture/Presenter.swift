// ============================================================
// §21~§23 的对照组：把状态机的「出口」换成另外三种机制
//
// 书 7.6~7.11 的控制器只有**一条**出口：在自己的方法里手动调 updateUI()。
// 这不是缺陷， MVC 本来就是这么设计的（7.5 那句话）。但一旦项目长大，人们会往这条
// 路上加别的机制 —— 于是本章要量的是：每加一种，「谁持有谁」「谁必须记得 post」
// 「忘了写会怎样」跟着变成另一套答案。
//
// 下面两个变体的**状态推进逻辑与书完全一致**（判卷 → 游标 +1 → 显示下一题），
// 只有「改完之后怎么让别人知道」这一处不同。注意它们都不是 UIViewController：
// §1 那条断言在这里再兑现一次 —— 一台完整的小测验状态机可以完全不碰 UIKit 的
// 视图控制器那一层（这里 import UIKit 只为了一个 UILabel 当靶子）。
// ============================================================

import Foundation
import UIKit

// ------------------------------------------------------------
// 第 4 种·代理（delegate）
// ------------------------------------------------------------

/// 代理协议：AnyObject 是硬要求 —— 代理必须是**引用类型**，
/// 不然 `weak` 无从谈起（值类型无法被弱引用）。
protocol QuizDelegate: AnyObject {
    func quiz(_ quiz: DelegatedQuiz, didAnswer index: Int, correct: Bool)
    func quiz(_ quiz: DelegatedQuiz, didFinishWithScore score: Int)
}

/// 「可选方法」在 Swift 里的写法：给协议扩展一份默认实现。这里让它往 Trace 上记一笔，
/// 好把「没实现」这件事量出来 —— 调用**照样发生**，只是落到的是这份默认实现。
/// 它和 OC 的 `@objc optional` 不是一回事：后者是**运行期**用 respondsToSelector 查表，
/// 没实现就根本不发这条消息（第 27 章）。§21 第三条断言量的就是这个差别。
extension QuizDelegate {
    func quiz(_ quiz: DelegatedQuiz, didAnswer index: Int, correct: Bool) {
        Trace.log.append("协议扩展的默认实现：didAnswer \(index)")
    }
}

/// §21 的接收方：只实现「答完了」那一个方法，另一个留给协议扩展的默认实现。
final class FinishRecorder: QuizDelegate {
    var finishes: [Int] = []
    func quiz(_ quiz: DelegatedQuiz, didFinishWithScore score: Int) {
        finishes.append(score)
    }
}

final class DelegatedQuiz {
    /// 书里没有这一行；而且它必须是 weak，否则两边互相持有（§21 第三条断言）。
    weak var delegate: QuizDelegate?

    let list: [Question]
    var questionNumber = 0
    var score = 0
    let label = UILabel()

    init(list: [Question]? = nil) {
        self.list = list ?? QuestionBank().list
    }

    /// 与书 7.6 的 answerPressed 同形：判卷 → 游标推进 → 显示下一题。
    /// 唯一的区别是最后不是调自己的 updateUI，而是**问外面有没有人**。
    func answer(chosen: Int) {
        let correct = list[questionNumber].answer
        let picked = (chosen == 1)
        if picked == correct { score += 1 }
        delegate?.quiz(self, didAnswer: questionNumber, correct: picked == correct)
        questionNumber += 1
        if questionNumber < list.count {
            label.text = list[questionNumber].questionText
        } else {
            delegate?.quiz(self, didFinishWithScore: score)
        }
    }
}

// ------------------------------------------------------------
// 第 5 种·闭包回调
// ------------------------------------------------------------

final class CallbackQuiz {

    /// 书 7.9 的 UIAlertAction handler 就是这一族：把「之后要做的事」存成一个值。
    var onFinish: ((Int) -> Void)?
    var onScoreChanged: ((Int) -> Void)?

    let list: [Question]
    var questionNumber = 0
    var score = 0
    let label = UILabel()

    init(list: [Question]? = nil) {
        self.list = list ?? QuestionBank().list
    }

    func answer(chosen: Int) {
        let correct = list[questionNumber].answer
        if (chosen == 1) == correct {
            score += 1
            onScoreChanged?(score)
        }
        questionNumber += 1
        if questionNumber < list.count {
            label.text = list[questionNumber].questionText
        } else {
            onFinish?(score)
        }
    }
}
