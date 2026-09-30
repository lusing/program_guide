// ============================================================
// 书 7.13「挑战：制作情商测试应用」的 ViewController —— 第二条产品线
//
// 这一节是原书第七章的收尾，也是本章 §26 的全部素材。它和 7.6~7.11 那台状态机的
// 关系是「同一套骨架，换了一个 Model」：
//   · Question 多了两个数组属性（选项、每档分值），答案不再是一个 Bool；
//   · 题库从 13 题变成 29 题；
//   · 屏幕上有三颗按钮，Inspector 里的 tag 依次是 1、2、3；
//   · 判卷从「对/错加一分」变成「把用户选中那一档的分累加」；
//   · 答完之后弹的不是「是否重新开始」，而是按分数区间给的四种 EQ 结论。
//
// 书 7.5 那句话（「可以把数据从英文换成法文而不用考虑其他代码」）到底值多少，
// 就体现在这个文件里有几处 **29 是被写死的**：`<= 28`、`/ 29`、`"\(...) / 29"`。
// §29 把这三处一处一数量出来；换 Model 而控制器一行不改的真正条件留给 §31。
//
// 与书里的差别只有本章一贯的那两样：控件用代码造（tag 也写代码里，等价于 Inspector
// 填数字），以及把弹窗内容存成可读属性（present 在裸进程里不生效，见第 22 章）。
// ============================================================

import Foundation
import UIKit

final class EQTestViewController: UIViewController {

    // ---- 书 7.13 的三个状态属性：pickedAnswer 这次是 Int，不是 Bool ----
    let allQuestions: QuestionBankEQ
    var questionNumber: Int = 0
    var pickedAnswer: Int = -1
    var score: Int = 0

    // ---- 三个按钮：书里它们是 IBOutlet，tag 在故事板 Inspector 里填 1/2/3 ----
    let answerOneButton = UIButton(type: .system)
    let answerTwoButton = UIButton(type: .system)
    let answerThreeButton = UIButton(type: .system)
    let questionLabel = UILabel()
    let progressLabel = UILabel()
    let progressBar = UIView()

    /// §26 要读结论弹窗的 title/message，而 `present` 在裸进程里不生效，
    /// handler 又不是 UIAlertAction 的公开属性（探针 e07）—— 和 §24/§25 同一套办法。
    private(set) var resultAlert: UIAlertController?
    private(set) var restartHandler: ((UIAlertAction) -> Void)?

    /// 书里这里是 `let allQuestions = QuestionBank()`（无参 init，29 题写死在题库里）。
    /// 本章必须能把**另一份** 29 题的库递进来（混排二选一的那一份），所以改成 init 参数。
    init(bank: QuestionBankEQ = QuestionBankEQ()) {
        allQuestions = bank
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented —— 本章没有故事板，见第 31 章")
    }

    // ---- 书 7.13 步骤 1 的 viewDidLoad：原文只有那三行圆角 ----
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(questionLabel)
        view.addSubview(progressLabel)
        view.addSubview(progressBar)
        view.addSubview(answerOneButton)
        view.addSubview(answerTwoButton)
        view.addSubview(answerThreeButton)
        // 通过下面的三行代码让按钮的外观变成圆角矩形（书 7.13 步骤 1 原文）
        answerOneButton.layer.cornerRadius = 25
        answerTwoButton.layer.cornerRadius = 25
        answerThreeButton.layer.cornerRadius = 25
        // tag 就是 Inspector 里那三个数字（步骤 2）
        answerOneButton.tag = 1
        answerTwoButton.tag = 2
        answerThreeButton.tag = 3
        nextQuestion()
    }

    // ---- 书 7.13 步骤 4：用 tag 确定用户选的是哪个选项 ----
    @objc func answerPressed(_ sender: UIButton) {
        pickedAnswer = sender.tag - 1
        Trace.log.append("点选：tag=\(sender.tag) → pickedAnswer=\(pickedAnswer)")
        checkAnswer()
        questionNumber += 1
        nextQuestion()
    }

    // ---- 书 7.13 步骤 4 的 checkAnswer：读的是**当前**那一题，所以必须跑在 += 1 之前 ----
    func checkAnswer() {
        score = score + allQuestions.list[questionNumber].questionScore[pickedAnswer]
    }

    // ---- 书 7.13 步骤 3：给按钮设置标题（守卫里的 28 是写死的） ----
    func nextQuestion() {
        if questionNumber <= 28 {
            questionLabel.text = allQuestions.list[questionNumber].questionText

            answerOneButton.isHidden = true
            answerTwoButton.isHidden = true
            answerThreeButton.isHidden = true

            for (index, option) in allQuestions.list[questionNumber].questionOption.enumerated() {
                if index == 0 {
                    answerOneButton.isHidden = false
                    answerOneButton.setTitle(option, for: UIControl.State.normal)
                } else if index == 1 {
                    answerTwoButton.isHidden = false
                    answerTwoButton.setTitle(option, for: UIControl.State.normal)
                } else if index == 2 {
                    answerThreeButton.isHidden = false
                    answerThreeButton.setTitle(option, for: UIControl.State.normal)
                }
            }

            updateUI()
        } else {
            presentResult()
        }
    }

    // ---- 书 7.13 步骤 5：把之前 updateUI() 里的 13 改成 29 ----
    func updateUI() {
        progressLabel.text = "\(questionNumber + 1) / 29"
        progressBar.frame.size.width = (view.frame.size.width / 29) * CGFloat(questionNumber + 1)
        Trace.log.append("updateUI：\(questionNumber)")
    }

    /// 书 7.13 步骤 6：四个区间。这里一个字符都没改，包括那三条 `else if` 之间的
    /// 缝隙（`< 109` 与 `>= 110`、`< 129` 与 `>= 130`）—— §27 量的就是这几行落到
    /// 真实分数上还剩哪些数没人接。
    func presentResult() {
        var title = ""
        var message = ""
        if score < 70 {
            title = "你的EQ较低"
            message = "你常常不能控制自己，你极易被自己的情绪所影响。很多时候，你轻易被击怒、动火、发脾气，这是非常危险的信号 ── 你的事业可能会毁于你的暴躁。对此最好的解决办法是能够给不好的东西一个好的解释，保持头脑冷静使自己心情开朗。"
        } else if score >= 70 && score < 109 {
            title = "你的EQ一般"
            message = "对于一件事，你不同时候的表现可能不一，这与你的意识有关，你比前者更具有EQ意识，但这种意识不是常常都有，因此需要你多加注意、时时提醒自己。"
        } else if score >= 110 && score < 129 {
            title = "你的EQ较高"
            message = "你是一个快乐的人，不易恐惊担忧，对于工作你热情投入、敢于负责，你为人更是正义正直、同情关怀，这是你的长处，应该努力保持。"
        } else if score >= 130 {
            title = "你就是个EQ高手"
            message = "你的情商高超不但是你事业的助手，更是你事业有成的一个重要前提条件。"
        }

        Trace.log.append("结论：\(title.isEmpty ? "（四个区间都没接住）" : title)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let block: (UIAlertAction) -> Void = { _ in
            Trace.log.append("handler：重新开始")
            self.startOver()
        }
        restartHandler = block
        alert.addAction(UIAlertAction(title: "重新开始", style: .default, handler: block))
        resultAlert = alert
        present(alert, animated: true, completion: nil)
    }

    /// 书 7.13 沿用 7.9 的重置：这里给的是**修好的那一版**（重置完立刻重新出题）。
    func startOver() {
        score = 0
        questionNumber = 0
        pickedAnswer = -1
        resultAlert = nil
        restartHandler = nil
        nextQuestion()
    }
}
