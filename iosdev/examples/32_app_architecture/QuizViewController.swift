// ============================================================
// Controller 层 —— 书 7.6~7.11 那台状态机，原样搬过来
//
// 书里的 ViewController 一共加了四样东西（每一节一样，这个「慢慢长出来」的过程
// 本身就是本章要量的对象）：
//   7.6  let allQuestions = QuestionBank()        + var pickedAnswer = false
//   7.7  var questionNumber = 0                   + answerPressed 里 += 1
//   7.8  nextQuestion() 里那句 `questionNumber <= 12` 的守卫（7.7 崩在这儿）
//   7.11 var score = 0                             + updateUI() 那三行
//
// 这里的版本与原书有三处必要的差别，都写在注释里：
//   1) 四个 IBOutlet 用代码造（本章没有故事板，界面文件是第 31 章）；形状一致；
//   2) answerPressed 的调用不靠事件系统（裸进程里 sendActions 不派发，第 31 章 §16），
//      主线直接调这个方法，量的是它里面的状态推进；
//   3) 每次更新界面都在 Trace 上留一行 —— 书里判据是「屏幕上看到了」，
//      这里换成「updateUI 被叫了几次、label.text 是什么」。
// ============================================================

import Foundation
import UIKit

/// 「谁在什么时候被叫到」的账本。放在类型上是顶层变量的位置，几个类共用一份。
enum Trace {
    static var log: [String] = []
    static func reset() { log = [] }
}

final class QuizViewController: UIViewController {

    // ---- 书 7.6/7.7/7.11 的三个状态属性 ----
    let allQuestions = QuestionBank()
    var pickedAnswer: Bool = false
    var questionNumber: Int = 0
    /// 书 7.11 写的是 `var score: Int = 0`，这里唯一的改动是前面加了 `@objc dynamic`。
    /// 不是风格改动：§19 要用 KVO 观察它，而 KVO 是靠 isa-swizzling 换掉 setter 实现的
    /// （第 27 章），一个纯 Swift 的属性根本不会被换。
    /// 但**拦下这件事的不是编译器**：探针 e06 抄到的是它只给一条 warning（退出码 0），
    /// 真正的拒绝在运行时 —— 探针 r05 里 `observe(\.score)` 走到注册那一句当场 trap。
    @objc dynamic var score: Int = 0

    // ---- 书 2.2 摆在故事板上、7.6 第一次在代码里摸到的四个控件 ----
    let questionLabel = UILabel()
    let scoreLabel = UILabel()
    let progressLabel = UILabel()
    /// 书 7.11 里那根黄条是个**用 frame 长短表示进度的 UIView**，不是 UIProgressView。
    /// 这个区别正是 §15 要量的：谁拥有它的宽度。
    let progressBar = UIView()
    /// 对照组：真正表示进度的控件是 UIProgressView，它吃的是 0...1 的 value。
    let progressValue = UIProgressView()

    var yesButton = UIButton(type: .system)
    var noButton = UIButton(type: .system)

    // ---- 书 7.6：viewDidLoad 里先把第一题摆上屏幕 ----
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(questionLabel)
        view.addSubview(scoreLabel)
        view.addSubview(progressLabel)
        view.addSubview(progressBar)
        // 书里 tag 是在故事板的 Inspector 里填的（1 和 2），这里等价地写代码里。
        yesButton.tag = 1
        noButton.tag = 2
        // 7.10 的重构点：原本是 `let firstQuestion = allQuestions.list[0]` 加一行赋值，
        // 7.10 说这两行与 nextQuestion() 功能相同，于是改成一句 nextQuestion()。
        nextQuestion()
    }

    // ---- 书 7.6/7.7：按钮的那一个 IBAction 处理两颗按钮 ----
    @objc func answerPressed(_ sender: UIButton) {
        if sender.tag == 1 {
            pickedAnswer = true
        } else if sender.tag == 2 {
            pickedAnswer = false
        }
        checkAnswer()
        questionNumber += 1
        nextQuestion()
    }

    // ---- 书 7.6 的第一版 checkAnswer 永远拿 list[0] 比，7.7 改成当前题 ----
    // 书 7.12 又在这里插了两行 ProgressHUD：那句「Xcode 控制台的话最终用户看不到」的
    // 反馈功能。这两行是本章架构上最值钱的一处，§30 量它 —— ProgressHUD 是个
    // **UIView 子类**，于是 7.5 那张「Model / View 永不直接发生联系」的三层图里，
    // Controller 第一次直接抓住了 View 的类。
    func checkAnswer() {
        let correctAnswer = allQuestions.list[questionNumber].answer
        if correctAnswer == pickedAnswer {
            Trace.log.append("回答正确：\(questionNumber)")
            ProgressHUD.showSuccess("正确")
            score = score + 1
        } else {
            Trace.log.append("错误：\(questionNumber)")
            ProgressHUD.showError("错误！")
        }
    }

    // ---- 书 7.8 加的守卫（12 是写死的），书 7.9 在 else 里换成弹窗 ----
    func nextQuestion() {
        if questionNumber <= 12 {
            questionLabel.text = allQuestions.list[questionNumber].questionText
            updateUI()
        } else {
            Trace.log.append("弹框：全部答完")
            presentFinishedAlert()
        }
    }

    /// 书 7.9 的弹窗。**present 在裸进程里不生效**（第 22 章量过呈现需要窗口），
    /// 而「用户点了重新开始」这一件事，本章也不能从 UIAlertAction 上把闭包读回来 ——
    /// handler 不是它的公开属性（编译器原文见探针 e07）。所以这里的做法是：
    /// 造 UIAlertAction **之前**先把那段闭包存一份，递给 UIKit 的是同一个值。
    /// §24/§25 调的就是这一份。
    func presentFinishedAlert() {
        let alert = UIAlertController(title: "了不起！",
                                      message: "你已经完成了所有的题目，是否想重新开始呢？",
                                      preferredStyle: .alert)
        let block: (UIAlertAction) -> Void = { _ in
            Trace.log.append("handler：重新开始")
            self.startOver()
        }
        restartHandler = block
        let restartAction = UIAlertAction(title: "重新开始", style: .default, handler: block)
        alert.addAction(restartAction)
        self.alert = alert
        present(alert, animated: true, completion: nil)
    }

    /// 主线要读它的 title/message/actions（§24）。书 7.9 里 alert 是个局部变量，
    /// 函数一返回就只剩 UIKit 自己那份引用；本章把它存起来才能读回内容 ——
    /// 于是顺手造出一个三方环（控制器↔弹窗↔handler↔控制器），§25 拿它当样本。
    private(set) var alert: UIAlertController?

    /// 上面那句「先存一份闭包」的落点：环的第二条边。
    private(set) var restartHandler: ((UIAlertAction) -> Void)?

    /// 把弹窗从属性上放掉：环断在这一行。至于对象是不是**当场**被收，问的不是引用计数，
    /// 是它在哪一层自动释放池里造出来（探针 c01：断环写在顶部、包进函数、外面套池子，
    /// 三种都「还在」，-Onone 与 -O 两份读数一字不差），§25 因此只断言「两个属性都空了」。
    func releaseAlert() {
        alert = nil
        restartHandler = nil
    }

    // ---- 书 7.11：更新界面这件事单独一个方法 ----
    func updateUI() {
        scoreLabel.text = "分数：\(score)"
        progressLabel.text = "\(questionNumber + 1) / 13"
        progressBar.frame.size.width = (view.frame.size.width / 13) * CGFloat(questionNumber + 1)
        Trace.log.append("updateUI：\(questionNumber)")
    }

    // ---- 书 7.9 末尾那个 bug 的修法：只清 questionNumber 会少一题 ----
    func startOver() {
        score = 0
        questionNumber = 0
        nextQuestion()
    }

    /// 7.9 那个 bug 的**未修版**：重置状态却不更新界面。留着它是为了 §11 对照。
    func startOverWithoutRefresh() {
        score = 0
        questionNumber = 0
    }
}
