// ============================================================
// §31 —— 书 7.5 那句话的兑现版控制器
//
// 7.5 写的是：「数据模型与视图永远不会直接发生联系……如果这个项目在法国运行，
// 需要把数据模型的内容从英文换成法文，你完全可以直接修改数据模型，而不用考虑
// 其他代码」。§29 刚用 29 道题那三处字面量证明这句话在书自己的代码里**不成立**；
// 这一处的差别只有一条：手里的 Model 是 `QuestionSource` 这个协议，
// 于是「一共有几道题」这件事在整台控制器里只有**一个**来源。
//
// 换句话说：MVC 这句话能不能兑现，跟目录结构、跟 import 了谁都没关系，
// 取决于「同一个意思被写了几遍」。这就是本章最后要量的那件事。
// ============================================================

import UIKit

final class SourceQuizViewController: UIViewController {

    /// 唯一的改动在这里：类型是协议，不是某个具体的题库类。
    private let source: QuestionSource

    private(set) var questionNumber: Int = 0
    private(set) var score: Int = 0
    /// 答完那一刻的分数；还没答完是 -1，好让 §31 能区分「0 分」和「没答完」。
    private(set) var finishedScore: Int = -1

    let questionLabel = UILabel()
    let progressLabel = UILabel()
    let progressBar = UIView()

    init(source: QuestionSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented —— 本章没有故事板，见第 31 章")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(questionLabel)
        view.addSubview(progressLabel)
        view.addSubview(progressBar)
        nextQuestion()
    }

    /// 书里这里是 answerPressed(_ sender: UIButton)，靠 tag 换算下标；
    /// 那一层在本章 §17/§26 已经量过了，这一处直接收下标，只看状态推进。
    func answer(option: Int) {
        // 守卫问的是 Model，不是某个写死的数字 —— 这一行就是 §29 那三处的替代品。
        guard questionNumber < source.questionCount else {
            Trace.log.append("已经答完，这一次点空了：游标 \(questionNumber)")
            return
        }
        score += source.score(at: questionNumber, option: option)
        questionNumber += 1
        nextQuestion()
    }

    func nextQuestion() {
        if questionNumber < source.questionCount {
            questionLabel.text = source.text(at: questionNumber)
            updateUI()
        } else {
            finishedScore = score
            Trace.log.append("全部答完：\(questionNumber) 题、\(score) 分")
        }
    }

    /// 三处数字（守卫、分母、label 里那个）现在都是同一个 `source.questionCount`。
    func updateUI() {
        progressLabel.text = "\(questionNumber + 1) / \(source.questionCount)"
        progressBar.frame.size.width = view.frame.size.width / CGFloat(source.questionCount)
            * CGFloat(questionNumber + 1)
        Trace.log.append("updateUI：\(questionNumber)")
    }
}
