// ============================================================
// Model 层第二个文件 —— 书 7.4 的 QuestionBank.swift
//
// 书里这个类**只有两样东西**：一个 `var list = [Question]()` 和一个往里 append 十三道
// 判断题的 init()。请注意这一点：推进到下一题的游标（questionNumber）不在这里，
// 它在 ViewController 里（7.6 加的第三个属性）。「状态该住在 Model 还是 Controller」
// 是这一章真正要教的东西，而书里恰好给了一个可以直接对照的样本 —— 见 §5。
// ============================================================

import Foundation

/// 书 7.4 原样：一个数组 + 一个无参 init。
class QuestionBank {

    var list = [Question]()

    init() {
        // 下面十三道判断题逐条照抄书 7.4 的 init()，含它的两种写法：
        // 先 `let item = Question(...)` 再 append，以及直接在 append 的参数里造对象。
        let item = Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
        list.append(item)

        list.append(Question(text: "喝白酒时最好喝茶水。", correctAnswer: false))
        list.append(Question(text: "空腹最好不吃柿子。", correctAnswer: true))
        list.append(Question(text: "在野外遇到雷雨天气时，感觉自己的头发竖起来了，皮肤发热，要立刻就地卧倒，不可继续站立。", correctAnswer: true))
        list.append(Question(text: "参加运动会，临赛前一定要吃饱，这样可以增加体能取得好成绩。", correctAnswer: false))
        list.append(Question(text: "面膜做的时间越久越好。", correctAnswer: false))
        list.append(Question(text: "晕船时应尽量将头部固定，不要让头部来回晃动。", correctAnswer: true))
        list.append(Question(text: "被鱼刺卡住以后应该猛吃食物，迅速咽下。", correctAnswer: false))
        list.append(Question(text: "红眼病病人是可以与他人共用生活用品和学习用品的。", correctAnswer: false))
        list.append(Question(text: "身上着火后，应迅速用灭火器灭火。", correctAnswer: false))
        list.append(Question(text: "创伤伤口内有玻璃碎片等大块异物时，到医院救治前，可自行取出。", correctAnswer: false))
        list.append(Question(text: "发生煤气中毒时，首先应将门、窗打开通风换气。", correctAnswer: true))
        list.append(Question(text: "进行人工呼吸前，应先清除患者口腔内的痰、血块和其他杂物等，以保证呼吸道通畅。", correctAnswer: true))
    }
}

/// §5 的对照组：把游标搬进 Model 的那一类写法（这套课的原版 Quizzler 与市面上大量
/// 教程都是这么写的：bank 自己发题、自己推进）。
///
/// 它与书里的写法**在同一个操作序列下会给出不同的分数**，原因就藏在
/// 「谁推进 questionNumber」这件事只能有一个主人 —— 主线 §5 量的就是这个差。
final class QuestionBankWithCursor {

    var list = [Question]()
    var questionNumber = 0

    init(list: [Question]? = nil) {
        if let list { self.list = list; return }
        self.list = QuestionBank().list
    }

    /// 返回当前题并把游标推到下一题；到最后一题就回零。
    func getNextQuestion() -> Question {
        let question = list[questionNumber]
        if questionNumber == list.count - 1 {
            questionNumber = 0
        } else {
            questionNumber += 1
        }
        return question
    }

    /// 检查的是「当前游标指向的那一题」—— 注意它和上面那个方法各自都会动游标。
    func checkAnswer(userAnswer: Bool) -> Bool {
        userAnswer == list[questionNumber].answer
    }
}

// ============================================================
// 书 7.13 挑战题的题库（29 道、每题三档分）
//
// 书里只给了前两题的文本，剩下的写在 GitHub 上。本章要量的不是那些文字，而是
// 「29 题 × 每题最高 6 分」这组数字能不能对上书 7.13 开头那句「最大 EQ 为 154 分」，
// 以及那四个结论区间的边界 —— 所以这里造的是**同形状**的 29 题（文本用序号占位），
// 并把这一点在 §26 里明说。
// ============================================================

final class QuestionBankEQ {

    var list = [QuestionEQ]()

    /// 书 7.13 只把前两题的文字印在纸上（步骤 2 那段 init() 里，其余 27 题在 GitHub 的
    /// 初始化项目里）。这里逐字抄那两道，剩下的用序号占位 —— §26 要的判据是
    /// 「29 题 × 每题最高 6 分」这组数字和结论区间的边界，不是那 27 行文字。
    static let knownFromBook: [(text: String, option: [String], score: [Int])] = [
        ("我有能力克服各种困难。", ["是的", "不一定", "不是"], [6, 3, 0]),
        ("如果我能到一个新的环境，我要把生活安排得：", ["和从前相仿", "不一定", "和从前不一样"], [6, 3, 0]),
    ]

    /// 每题都是「是的 / 不一定 / 不是」= 6 / 3 / 0 分，共 29 题。
    init(count: Int = 29, perOption: [Int] = [6, 3, 0]) {
        for n in 1...count {
            if n <= Self.knownFromBook.count {
                let known = Self.knownFromBook[n - 1]
                list.append(QuestionEQ(text: known.text, option: known.option, score: known.score))
            } else {
                let labels = Array(["是的", "不一定", "不是"].prefix(perOption.count))
                list.append(QuestionEQ(text: "第\(n)题", option: labels, score: perOption))
            }
        }
    }

    /// §26 的第二条题库：书 7.13 步骤 3 明说「29 道题中有一部分是二选一，还有一部分是三选一」。
    /// 这里按 odd/even 交错造出两种形状，选项与分值**总是成对给出**——
    /// 因为书 7.13 步骤 2 末尾那句警告说的是：这两个数组长度不一致就「超出数组范围，导致应用程序崩溃」。
    init(mixedCount: Int, perOption: [Int] = [6, 3, 0]) {
        for n in 1...mixedCount {
            let keep = (n % 2 == 0) ? 2 : perOption.count
            if n <= Self.knownFromBook.count {
                let known = Self.knownFromBook[n - 1]
                list.append(QuestionEQ(text: known.text,
                                       option: Array(known.option.prefix(keep)),
                                       score: Array(known.score.prefix(keep))))
            } else {
                let labels = Array(["是的", "不一定", "不是"].prefix(keep))
                list.append(QuestionEQ(text: "第\(n)题", option: labels, score: Array(perOption.prefix(keep))))
            }
        }
    }

    /// 全取最高档能得多少分 —— 书 7.13 说「最大 EQ 为 154 分」。
    var maxPossibleScore: Int {
        list.reduce(0) { $0 + ($1.questionScore.max() ?? 0) }
    }

    /// 有多少题的两个数组长度不一致（书里那句警告的可数形态）。
    var mismatchedCount: Int { list.filter { !$0.shapeMatched }.count }
}

/// §31 用：把「题库」这件事抽象成一个接口，控制器只认接口、不认具体的那一个类。
/// 7.5 那句「如果项目在法国运行，可以把数据从英文换成法文而不用考虑其他代码」
/// 在代码里就是这个接口的两个实现（主线 §31 拿它跑完一整轮）。
protocol QuestionSource {
    var questionCount: Int { get }
    func text(at index: Int) -> String
    func score(at index: Int, option: Int) -> Int
}

extension QuestionBank: QuestionSource {
    var questionCount: Int { list.count }
    func text(at index: Int) -> String { list[index].questionText }
    /// 判断题只有两个选项：option 0 = 答「是」、1 = 答「否」。
    /// 这一层换算就是「同一个接口，两种 Model 各自怎么解释选项下标」的全部自由度 ——
    /// 控制器那边永远只写 `score(at: questionNumber, option: sender.tag - 1)`。
    func score(at index: Int, option: Int) -> Int {
        (list[index].answer == (option == 0)) ? 1 : 0
    }
}

extension QuestionBankEQ: QuestionSource {
    var questionCount: Int { list.count }
    func text(at index: Int) -> String { list[index].questionText }
    func score(at index: Int, option: Int) -> Int { list[index].questionScore[option] }
}
