// 探针 r01：书 7.7 结尾那句「完成最后一道题目的选择后程序崩溃」的现场
//
// 这一支是**未加守卫**的那一版控制器 —— 也就是 7.7 的原样（7.8 才加 `<= 12`）。
// 主线 §8 量的是不崩的那一半（合法下标到几、守卫什么时候够用），因为判定 2/3
// 不允许崩溃现场进主线：一次 `Fatal error` 会把它后面所有输出全带走。
//
// 要看的是两件事：
//   1) 崩在哪一句 —— 栈里那行是 nextQuestion() 还是 checkAnswer()，
//      这决定了「是谁在替一个没人管的游标买单」；
//   2) 崩之前 stdout 上最后一题是第几题（编号差一格，§10 那条，在这儿也会照出来）。
//
// 跑法：bash probes/run.sh r01（期望：退出码 132 = signal 4（SIGILL，Swift 的 fatalError 走的是 trap），stderr 里是 Fatal error 原文。
// 与 m02 那种 Objective-C 异常的 134 = signal 6（SIGABRT）不是一回事，两支对照着看）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

final class Question {
    let questionText: String
    let answer: Bool
    init(text: String, correctAnswer: Bool) { questionText = text; answer = correctAnswer }
}

final class QuestionBank {
    var list = [Question]()
    init() {
        list.append(Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true))
        list.append(Question(text: "喝白酒时最好喝茶水。", correctAnswer: false))
        list.append(Question(text: "空腹最好不吃柿子。", correctAnswer: true))
        list.append(Question(text: "在野外遇到雷雨天气时……", correctAnswer: true))
        list.append(Question(text: "参加运动会，临赛前一定要吃饱……", correctAnswer: false))
        list.append(Question(text: "面膜做的时间越久越好。", correctAnswer: false))
        list.append(Question(text: "晕船时应尽量将头部固定……", correctAnswer: true))
        list.append(Question(text: "被鱼刺卡住以后应该猛吃食物……", correctAnswer: false))
        list.append(Question(text: "红眼病病人是可以与他人共用生活用品……", correctAnswer: false))
        list.append(Question(text: "身上着火后，应迅速用灭火器灭火。", correctAnswer: false))
        list.append(Question(text: "创伤伤口内有玻璃碎片等大块异物时……", correctAnswer: false))
        list.append(Question(text: "发生煤气中毒时，首先应将门、窗打开通风换气。", correctAnswer: true))
        list.append(Question(text: "进行人工呼吸前，应先清除患者口腔内的痰……", correctAnswer: true))
    }
}

/// 书 7.7 的控制器原样：没有 7.8 那句守卫。
final class QuizViewController7_7 {
    let allQuestions = QuestionBank()
    var pickedAnswer = false
    var questionNumber = 0
    var score = 0

    func answerPressed(tag: Int) {
        pickedAnswer = (tag == 1)
        checkAnswer()
        questionNumber += 1
        nextQuestion()
    }

    func checkAnswer() {
        if allQuestions.list[questionNumber].answer == pickedAnswer { score += 1 }
    }

    /// 7.7 这一版没有守卫：直接拿游标去读题库。
    func nextQuestion() {
        print("屏幕上第 \(questionNumber + 1) 题：\(allQuestions.list[questionNumber].questionText)")
    }
}

let vc = QuizViewController7_7()
vc.nextQuestion()                       // viewDidLoad 里那一次出题：第 1 题
for tag in [1, 2, 1, 1, 2, 2, 1, 2, 2, 2, 2, 1, 1, 2] {   // 十三道题，每颗按钮对应一个 tag
    vc.answerPressed(tag: tag)
}
print("跑到了这里：questionNumber = \(vc.questionNumber)")
