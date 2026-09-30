// ============================================================
// 32 - 应用架构：MVC 三层里，状态到底住在谁的哪一次赋值里
//
// 《跟着项目学iOS应用开发：基于Swift 4》第 7 章（使用 Model-View-Controller
// 设计模式制作小测验 App）是全书第一处谈「架构」的地方。它要交付的东西很具体：
//   7.2 Model 层第一个文件 Question.swift（class + 两个 let + init）；
//   7.4 Model 层第二个文件 QuestionBank.swift（一个 [Question] + init 里 append 十三道判断题）；
//   7.5 三段讲解「谁是 M、谁是 V、谁是 C」，结论是「数据模型与视图永远不会直接发生联系」；
//   7.6~7.11 Controller 里那台状态机：questionNumber / pickedAnswer / score 三个属性，
//        answerPressed(_:) → checkAnswer() → questionNumber += 1 → nextQuestion() → updateUI()；
//        以及书里**明写在正文**的三个 bug（7.7 越界崩、7.9 重做后丢一题、7.11 类型不匹配）。
//   7.12 把一个 Objective-C 写的第三方库（ProgressHUD）拖进 Swift 工程；
//   7.13 同一套引擎再走一条产品线（29 题的情商测试：选项个数不固定、按分值区间给结论）。
//
// 原书的判据全是「构建并运行项目，如图 7-xx 所示」，三个 bug 也都要跑起来才看见。
// 本章把它换成命令行可断言的形态。判据还是本仓库那六条（见 run-all.sh 头部与 README：
// 编译日志为空、退出码 0、stderr 为空、stdout 非空、无多余控制字符、结尾
// `==== 32 结束 ====`，外加 debug(-Onone) 与 release(-O) 两份 stdout 逐字节一致）。
// 因此原书所有「会崩 / 编译器会红一条」的写法都不进本文件，改由 probes/ 现跑并抄原文
// （编号见 probes/run.sh 头部：eNN 编译期、rNN 运行期、cNN 配置对照、mNN 混编）：
//   7.7 的 list[13] 是 `Fatal error: Index out of range`，退出码 132（探针 r01）；
//   7.11 的 `scoreLabel.text = score` 是编译期诊断（探针 e02；判定 1 要求日志为空）；
//   7.12 那句「黄色叹号警告不影响功能」，在本仓库里恰恰是**硬失败**（探针 m01）——
//   这是本章顺手给工程流程的一条真结论。
// 探针跑下来还有三处**原书的说法与本机构建器给的不一样**，就地写在对应小节：
//   §2（红点在类声明上，不在构造行）、§15（错在除号，且消息与「一单一整」无关）、
//   §19（编译器不拒绝纯 Swift 属性的 KVO，只警告；崩在注册那一句 —— r05）。
//
// 本章最值得记住的一条：**「MVC 分层」不是一个目录结构，而是一句可以逐条验证的
// 数据流断言**。分层是否成立，看三件事能不能被量出来 —— Model 不认识 UIKit（§1）、
// 视图永远等控制器来问而不是自己会动（§12/§18）、换掉 Model 而控制器一行不改
// 还能跑通（§29 给出反例、§31 给出成立的那一面）。这三件事在本章都有对应的断言，
// 而不只是示意图。
//
// 后半章（§26~§31）走书 7.13 那条「挑战」产品线（29 题情商测试）和书 7.12 的
// Objective-C 第三方库：前者把「换 Model」从口号变成一个可以数出错的地方，
// 后者是 Swift 工程里第一次真的接触 OC 运行时。
// ============================================================

import Foundation
import UIKit

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func section(_ n: Int, _ title: String) { print("\n== §\(n) \(title) ==") }

// 本章全部时间相关的东西都不参与判断：整个流程没有 runloop、没有窗口、没有动画。

// ============================================================
// §1 Model 层不 import UIKit：一个不碰界面的层能走多远
// ============================================================
section(1, "Model 层不碰 UIKit：书 7.2 那句「Foundation 比 UIKit 轻很多」的运行时落点")
// 书 7.2 结尾用一整段解释「为什么 Question.swift 里 import 的是 Foundation 而不是 UIKit」，
// 结论是「要根据需求来选择导入的框架库」。这句话在原书里没有判据 —— 它是个风格建议。
// 本章把它换成一个可跑的事实：Model 层的 13 道题、整台答题状态机、计分与越界处理，
// 全程在没有窗口、没有 UIApplication.shared、没有 runloop 的进程里跑完。
// 先确认这个前提是真的（UIApplication.shared 在本章这类产物里取不到，第 31 章 §16 同一条根）。
let app: UIApplication? = UIApplication.shared
expect(app == nil,
       "这是一个裸可执行文件：\(String(describing: app)) —— 没有共享应用对象、没有窗口、没有 runloop。下面每一条 Model 与状态机的断言，都发生在这种进程里")
let bank = QuestionBank()
expect(bank.list.count == 13,
       "书 7.4 的 QuestionBank 只有两样东西：var list = [Question]() 和一个往里面 append 十三道题的 init() —— 实际数量 \(bank.list.count)")
var seenTrue = 0
for q in bank.list where q.answer { seenTrue += 1 }
expect(seenTrue == 6,
       "十三道判断题里答案成立的是 \(seenTrue) 道、不成立的是 \(bank.list.count - seenTrue) 道（Model 层一次读回，全程没碰 UIView）")
expect(bank.list[0].questionText == "吃烧烤不能喝啤酒。" && bank.list[12].questionText.hasPrefix("进行人工呼吸前"),
       "首题「\(bank.list[0].questionText)」与末题「\(bank.list[12].questionText.prefix(8))…」逐字对得上书 7.4 的 append 次序 —— 数组是有序的，这就是 §4 那条「顺序即题号」的依据")

// ============================================================
// §2 class Question 的三段形状：书里那一格「报错」到底报在哪
// ============================================================
section(2, "class Question 的三段形状：无 init、有默认值、有 init（书 7.2 的三步）")
// 书 7.2 依次给了三个版本，并说第一个「会报错，如图 7-8」。这一条探针跑下来，
// 原文与「红点在构造那一行」的直觉**相反**：编译器先指着**类声明**说
// `class 'Question' has no initializers`（并在两行属性上各补一句 note：
// stored property without initial value prevents synthesized initializers），
// 然后才在构造那一行说 `cannot be constructed because it has no accessible initializers`。
// 两句是同一件事的两半：原因写在类型上，症状写在调用处 —— 排查时先读哪一句，
// 决定了人是去改属性还是去改 init（原文见探针 e01）。
let bookShape = Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
expect(bookShape.questionText == "吃烧烤不能喝啤酒。" && bookShape.answer,
       "书 7.2 的最终形态（两个 let + init(text:correctAnswer:)）造出来的对象，两个属性都读得回来：\"\(bookShape.questionText)\" / \(bookShape.answer)")
// 第二个版本（给默认值）合法但没用：常量已经写死，每个对象都说同一句话。
let defaulted = QuestionWithDefault()
let another = QuestionWithDefault()
expect(defaulted.questionText == another.questionText && defaulted.answer == another.answer,
       "书 7.2 中间那步（把默认值写进属性）编译得过，但两个实例一字不差：\"\(defaulted.questionText)\" / \(defaulted.answer) —— 值定在**类型**上而不是**对象**上，所以这条走不通")
expect(Question(text: "甲", correctAnswer: true).questionText != Question(text: "乙", correctAnswer: true).questionText,
       "换成 init 传参之后，两个实例第一次可以不一样 —— 这就是「数据模型负责构建和管理数据」这句话在代码里的最小落点")

// ============================================================
// §3 init 里的赋值不算「变化」：didSet 不触发，Model 的观察者会漏掉出厂那一次
// ============================================================
section(3, "两阶段初始化的运行时那一半：init 里那两次赋值，didSet 一次都不跑")
// 书 7.2 只说「属性都赋完值才不报错」。这条规矩还带出一个架构后果：给 Model 的属性挂
// 观察（didSet / willSet / KVO）时，**构造阶段的那几次写入不会被当作变化**。
// 于是「观察者在 init 里就注册，然后指望它抓到初始值」的写法一律抓空（探针 e04 量
// 编译器那一半：init 里把 self 交给闭包会当场拒绝）。还有一条更硬的前置：
// 想看着它，它就得是可变的 —— 探针 e03 抄的是「`let` 上根本挂不了观察者」那句原文，
// 这就是本节这个 MutableQuestion 类**被迫存在**的理由。
let mutable = MutableQuestion(text: "空腹最好不吃柿子。", correctAnswer: true)
expect(mutable.mutations == 0,
       "init 里确实赋了两个属性，可 didSet 的计数是 \(mutable.mutations) —— Swift 规定初始化阶段的写入不走观察者")
mutable.questionText = "空腹最好吃东西。"
mutable.answer = false
expect(mutable.mutations == 2,
       "构造完成之后再改，两次都记上了（\(mutable.mutations)）—— 观察者的有效区间是从 init 结束那一刻开始的")
expect(mutable.questionText == "空腹最好吃东西。",
       "属性本身是可变的（var），改完读回来是新值；对照 §2 那两个 let：同一个 Model，可变性来自声明用 let 还是 var（而「常量上根本挂不了观察者」是编译器的原话，见探针 e03 —— MutableQuestion 这个类是被那条限制逼出来的）")

// ============================================================
// §4 题库的出厂清点：顺序就是题号
// ============================================================
section(4, "十三道题的出厂清点：顺序就是题号，而 lldb 那一屏为什么搬不过来")
// 书 7.8 的判据是在 lldb 里敲 `print allQuestions.list`，它给出 13 行，每行前面是一个
// 指针地址（0x000060c00045e5a0 之类）。地址不能进本章的输出 —— 两个进程各自分配，
// debug 与 release 那份逐字节比对当场就裂。所以这里换成三条不依赖地址的问法：
// 是不是 13 个、是不是 13 个**互不相同**的对象、顺序是不是 append 的顺序。
let mirroredChildren = Mirror(reflecting: bank.list).children.count
expect(mirroredChildren == 13,
       "Mirror 数出来 \(mirroredChildren) 个元素 —— 这是 lldb 那一屏的「[0] … [12]」在当前进程里的等价物（它连每行前面那个地址一起给，而地址每次都换）")
let identityCount = Set(bank.list.map { ObjectIdentifier($0) }).count
expect(identityCount == 13,
       "十三个元素两两不是同一个对象（去重之后还是 \(identityCount) 个）—— 7.4 那句「创建十三个 Question 对象」的「对象」二字，量的就是这个")
expect(bank.list[0] === bank.list[0] && bank.list[0] !== bank.list[1],
       "`===` 问的是身份：同一个下标两次取回同一个对象，不同下标取回不同对象 —— 题号（下标）与题目（对象）是一对一绑死的，这就是 §8 那台状态机敢只用一个整数当游标的全部依据")
var orderKept = true
for (index, question) in bank.list.enumerated() where question !== bank.list[index] { orderKept = false }
expect(orderKept,
       "enumerated() 给出的 (下标, 元素) 与直接按下标取一致 —— 数组是有序的，书 7.6 那句「[0] 是第一题、[1] 是第二题」在 Swift 的 Array 里是硬保证（Dictionary 就没有，第 30 章量过它每次进程换遍历顺序）")

// ============================================================
// §5 游标该住在谁的家里：Model 推进一次 + Controller 推进一次 = 少一题
// ============================================================
section(5, "状态的主人只能有一个：游标住在 Controller（书写法）与住在 Model（常见写法）差多少")
// 书 7.4 的 QuestionBank 里**没有游标**，推进它的是 ViewController 的 questionNumber（7.7）。
// 市面上同一套课的另一半实现把游标放进了 Model（bank.getNextQuestion() 自己推进）。
// 两种单独都自洽；混在一起（Model 会推、Controller 也推）就是本章最容易写错的那种架构 bug。
// 下面用同一份三题的题库跑两遍，用户每次都答对**屏幕上那一题**。
let three = [Question(text: "甲", correctAnswer: true),
             Question(text: "乙", correctAnswer: false),
             Question(text: "丙", correctAnswer: true)]
// 设计 A：书里的样子 —— Model 只有数据，游标在控制器手上。
var cursorA = 0
var scoreA = 0
var pairsA: [String] = []
for _ in 0..<three.count {
    let shownIndex = cursorA                              // 屏幕上的是这一题
    let pick = three[shownIndex].answer                    // 用户看着它答，答对了
    pairsA.append("屏幕\(shownIndex)/判卷\(cursorA)")
    if pick == three[cursorA].answer { scoreA += 1 }        // checkAnswer 读 questionNumber
    cursorA += 1                                           // answerPressed 里那句 += 1
}
expect(scoreA == 3,
       "设计 A（游标只有一个主人）：三题全答对，得分 \(scoreA)")
expect(pairsA == ["屏幕0/判卷0", "屏幕1/判卷1", "屏幕2/判卷2"],
       "而且「屏幕上那一题」与「判卷时读的那一题」每一轮都是同一题（\(pairsA.joined(separator: " "))）—— 这就是单一数据源的样子")
// 设计 B：bank 自己推进（getNextQuestion 推一次），控制器照抄另一份教程又 += 1。
let bankB = QuestionBankWithCursor(list: three)
var scoreB = 0
var pairsB: [String] = []
for _ in 0..<three.count {
    let shown = bankB.getNextQuestion()                                 // 返回当前题，游标 +1
    let shownIndex = three.firstIndex { $0 === shown } ?? -1
    let checkedIndex = bankB.questionNumber                             // checkAnswer 读的是**推进之后**的游标
    pairsB.append("屏幕\(shownIndex)/判卷\(checkedIndex)")
    if bankB.checkAnswer(userAnswer: shown.answer) { scoreB += 1 }
}
expect(scoreB == 1,
       "设计 B（游标有两个主人）：用户同样每答必对屏幕上那一题，得分却是 \(scoreB) —— 每判一题都看的是**下一题**的答案")
expect(pairsB == ["屏幕0/判卷1", "屏幕1/判卷2", "屏幕2/判卷0"],
       "错位是成体系的（\(pairsB.joined(separator: " "))）：最后一题被拿去和第一题比。书 7.5 说「控制器负责数据模型与视图之间的沟通」，这句话的工程含义是**沟通的中间人只能有一个**，否则同一份数据会被两条路各推一次")

// ============================================================
// §6 Model 用 class 还是 struct：「我改了它，谁看得见」的两种答案
// ============================================================
section(6, "值语义与引用语义在 Model 层的分岔：同一份题库，两种「改一次影响谁」")
// 书 7.2 直接选了 class，7.3 那节给的理由是「面向对象」。但 Question 只有两个只读字段，
// struct 完全够用 —— 差别不在能不能跑，而在下面这四条断言。
var copiedList = bank.list
copiedList.removeAll()
expect(bank.list.count == 13 && copiedList.isEmpty,
       "数组本身是**值**：拷一份再清空，原题库还是 \(bank.list.count) 道 —— 这一条与元素是 class 还是 struct 无关")
let firstFromCopy = bank.list[0]
expect(firstFromCopy === bank.list[0],
       "可数组里的元素是**引用**：换一条路径拿到的是同一个 Question 对象 —— 于是「拷一份题库」根本不算隔离，§12 那条「改了 Model 界面不动」的病根就在这儿")
var valueList = [QuestionValue(text: "甲", correctAnswer: true), QuestionValue(text: "乙", correctAnswer: false)]
var valueCopy = valueList
valueCopy[0] = QuestionValue(text: "甲改", correctAnswer: false)
expect(valueList[0].questionText == "甲",
       "换成 struct 的 Model：改副本里第 0 题，原件一个字没动（\"\(valueList[0].questionText)\"）—— 值类型 + 数组的值语义，隔离是彻底的")
func bump(_ counter: ValueCounter) -> ValueCounter { var c = counter; c.n += 1; return c }
var byValue = ValueCounter()
byValue = bump(byValue)
expect(byValue.n == 1,
       "把状态传进函数再改：struct 版必须**把改完的那份接回来**才有 \(byValue.n) —— 忘了接回来就等于什么都没做，这是值语义 Model 的唯一代价")
func bumpReference(_ quiz: QuizViewController) { quiz.questionNumber += 1 }
let referenceProbe = QuizViewController()
bumpReference(referenceProbe)
bumpReference(referenceProbe)
expect(referenceProbe.questionNumber == 2,
       "class 版（书里 ViewController 就是 class）不需要接回来，函数内那句 += 直接落在同一个对象上（现在 \(referenceProbe.questionNumber)）—— 「状态住在谁的哪一次赋值里」这句话，class 与 struct 给的是两个答案")

// ============================================================
// §7 let 修饰的控制器，属性照样在变：三个状态住在哪一层
// ============================================================
section(7, "书 7.6 那四行属性：let 锁的是引用，不是里面的数据")
let quiz = QuizViewController()
quiz.loadViewIfNeeded()
expect(quiz.questionNumber == 0 && !quiz.pickedAnswer && quiz.score == 0,
       "出厂状态：questionNumber=\(quiz.questionNumber) pickedAnswer=\(quiz.pickedAnswer) score=\(quiz.score) —— 三个都是 var，全部住在控制器这一层（Model 层一个都没有，见 §5）")
quiz.answerPressed(quiz.yesButton)
expect(quiz.questionNumber == 1 && quiz.score == 1,
       "点一次「是」之后：游标 \(quiz.questionNumber)、分数 \(quiz.score) —— 第一次读回的是**改过之后**的值，因为改的是同一个对象；控制器是 class 这条前提，决定了「谁拿到它都能改」")
let more = QuestionBank()
expect(more.list.count == 13, "另一个 QuestionBank 实例自带十三道题：init() 里的 append 每造一个就跑一遍（不是共享的一份，§28 的单例对照从这里开始有意义）")
quiz.allQuestions.list.append(Question(text: "多出来的一题。", correctAnswer: true))
expect(quiz.allQuestions.list.count == 14 && more.list.count == 13,
       "`let allQuestions = QuestionBank()` 里那个 let 只锁引用：它拦不住 list 被 append（现在 \(quiz.allQuestions.list.count) 题），也拦不住别的实例（\(more.list.count) 题）—— 书 7.6 那句 let 给的安全感，边界就在这里")

// ============================================================
// §8 越界：7.7 那次崩溃，以及 7.8 那句守卫到底拦住了什么
// ============================================================
section(8, "list[13] 的下场：崩溃原文进探针，守卫的等价性留在这里量")
// 书 7.7 结尾：「构建并运行项目……直到在完成最后一道题目的选择后程序崩溃」。那条
// `Fatal error: Index out of range` 由探针 r01 现跑现抄（判定 2/3 不允许它进主线）。
// 这里量的是**不崩的那一半**：边界在哪儿、7.8 的写法什么时候够用。
expect(bank.list.indices.contains(12) && !bank.list.indices.contains(13),
       "合法下标到 \(bank.list.indices.last!) 为止，13 已经出界 —— 而 7.7 的代码在答完第十三题后正好把 questionNumber 推到 13")
var guardsAgree = true
for n in 0...14 where ((n <= 12) != bank.list.indices.contains(n)) { guardsAgree = false }
expect(guardsAgree,
       "在十三道题的题库上，`questionNumber <= 12` 与 `indices.contains(questionNumber)` 对 0…14 每个取值都同真同假 —— 7.8 那句修法的**这一半**是对的：它确实拦住了崩溃")
expect(bank.list.last?.questionText.hasPrefix("进行人工呼吸前") == true,
       "最后一题（下标 12）读得回来：「\(String(bank.list.last?.questionText.prefix(8) ?? ""))…」；探针 r01 里越界那一下就是想要它的下一题")

// ============================================================
// §9 抄来的边界：写死 12 的守卫，遇到三题的题库就露馅
// ============================================================
section(9, "`<= 12` 里的 12 是从题库长度抄来的：抄来的边界不跟着源头动")
// 7.8 的修法把「十三道题」这个事实写成了字面量。同一份代码换题库长度，守卫立刻
// 放行一批不存在的下标 —— 这里换不成会崩的题，所以改成「数有多少个放行但不合法」。
let threeBank = QuestionBankWithCursor(list: three)
var letSlide = 0
for n in 0...14 where (n <= 12) && !threeBank.list.indices.contains(n) { letSlide += 1 }
expect(letSlide == 10,
       "三题的题库配上写死的 `<= 12`：下标 3…12 这 \(letSlide) 个取值会被守卫放行，可它们一个都不存在 —— 崩不崩只取决于运行到不到那里，不取决于守卫")
var safeSlide = 0
for n in 0...14 where (n < threeBank.list.count) != threeBank.list.indices.contains(n) { safeSlide += 1 }
expect(safeSlide == 0,
       "换成 `questionNumber < list.count`：与 indices.contains 全表同真假（差异 \(safeSlide) 处）—— 边界要么从源头算，要么就不算")
expect(three.count == 3 && bank.list.count == 13,
       "顺带一条本章反复要用的事实：题目数量是可问的（\(three.count) / \(bank.list.count)），所以任何写死它的地方都是**抄的**，不是问的（书 7.11 那行 progressLabel 里的 13、7.13 步骤 5 里改成的 29，都是同一类抄写）")

// ============================================================
// §10 「/ 13」前面那个 +1 从哪来：两套编号在界面上撞车
// ============================================================
section(10, "progressLabel 那句 \"\\(questionNumber + 1) / 13\"：游标从 0 数、人话从 1 数")
let counting = QuizViewController()
counting.loadViewIfNeeded()
expect(counting.progressLabel.text == "1 / 13",
       "刚进界面（questionNumber=\(counting.questionNumber)）显示的是「\(counting.progressLabel.text ?? "nil")」—— 第 1 题的游标是 0，那个 +1 是**给被人看的那一行**加的，不是给下标加的")
counting.answerPressed(counting.yesButton)
expect(counting.questionNumber == 1 && counting.progressLabel.text == "2 / 13",
       "答完一题：游标 \(counting.questionNumber)、显示「\(counting.progressLabel.text ?? "nil")」—— 两者始终差 1，这正是 7.11 正文里那句「需要将其加 1，以便显示其真正的题目序号」")
let drained = QuizViewController()
drained.loadViewIfNeeded()
for _ in 0..<13 { drained.answerPressed(drained.noButton) }
expect(drained.questionNumber == 13 && drained.progressLabel.text == "13 / 13",
       "十三题走完：游标被推到 \(drained.questionNumber)（已经出界），而屏幕上仍是「\(drained.progressLabel.text ?? "nil")」—— 因为 else 分支里根本没调 updateUI，界面上那一行停在最后一次合法更新")
expect(drained.questionLabel.text == bank.list[12].questionText,
       "题目文字也停在最后一题（「\(String(drained.questionLabel.text?.prefix(9) ?? ""))…」）：状态已经走到 13，视图还留在 12 —— 这一对错位就是 §11 那个 bug 的完整形状")

// ============================================================
// §11 改了状态不等于改了界面：书 7.9 结尾那个 bug 的两步分离
// ============================================================
section(11, "「重置 questionNumber 却不更新界面」：书里明写的那个 bug，量成两次读数的差")
// 书 7.9 结尾：「当用户单击重新开始按钮以后，会执行 startOver（）方法，此时 questionNumber
// 的值会重置为 0。而当前屏幕上的题目还停留在第一轮的最后一道，没有进行更新，当用户单击按钮
// 以后才会更新题目。在调用 answerPressed（_sender：UIButton）方法的时候，会先执行
// questionNumber+=1 代码，此时 questionNumber 的值变为了 1，再执行 nextQuestion（），
// 这就意味着从第 2 轮开始，重新开始以后永远无法显示题库中的第 2 道题。」
// 这段话的**过程**逐字可验（下面四条断言就是它），最后一句的编号本身是错的：被跨过去、
// 从此不再显示的是下标 0 那一题，按人话数叫「第 1 道题」。本章按跑出来的结果写。
let restartBug = QuizViewController()
restartBug.loadViewIfNeeded()
for _ in 0..<13 { restartBug.answerPressed(restartBug.noButton) }
restartBug.startOverWithoutRefresh()   // 未修版：只清状态
expect(restartBug.questionNumber == 0 && restartBug.score == 0,
       "重置之后状态确实归零了（游标 \(restartBug.questionNumber)、分数 \(restartBug.score)）—— bug 不在这一步")
expect(restartBug.questionLabel.text == bank.list[12].questionText,
       "可屏幕上还是第十三题（「\(String(restartBug.questionLabel.text?.prefix(9) ?? ""))…」）：状态是 0，视图是 12 —— **没人再喂它一次**")
restartBug.answerPressed(restartBug.yesButton)
expect(restartBug.questionLabel.text == bank.list[1].questionText,
       "再答一次才跳：屏幕直接到了第 2 题（「\(String(restartBug.questionLabel.text?.prefix(6) ?? ""))…」）—— 这一轮里永远不会出现的是**第 1 题**（下标 0 被那句 += 1 直接跨过去了）")
expect(restartBug.progressLabel.text == "2 / 13",
       "进度那一行也跟着跳到「\(restartBug.progressLabel.text ?? "nil")」：从第 2 轮起，第 1 题既看不见也答不着，整套题只剩 12 道可答")
expect(restartBug.score == 1,
       "而这一次点击判的是**下标 0** 那道题（用户眼前明明看着第 13 题作答）：判卷与屏幕错开了整整一题，\(restartBug.score) 分是这么来的 —— 书里只说了「题目不更新」，没说同一次点击里评分用的也不是屏幕上那题")
let fixed = QuizViewController()
fixed.loadViewIfNeeded()
for _ in 0..<13 { fixed.answerPressed(fixed.noButton) }
fixed.startOver()                      // 修版：清完状态顺手 nextQuestion()
expect(fixed.questionNumber == 0 && fixed.questionLabel.text == bank.list[0].questionText,
       "修法（7.9 最后加的那一行 nextQuestion()）：状态与界面一起回到第 1 题（游标 \(fixed.questionNumber)、屏幕是「\(String(fixed.questionLabel.text?.prefix(8) ?? ""))…」）—— 归零之后必须重新走一次「把状态搬到视图上」")

// ============================================================
// §12 视图不会自己动：改了 Model，label 上一个字都不会变
// ============================================================
section(12, "书 7.5 那句「数据模型与视图永远不会直接发生联系」的可执行版")
let sharedQuestion = MutableQuestion(text: "面膜做的时间越久越好。", correctAnswer: false)
let shownOnScreen = UILabel()
shownOnScreen.text = sharedQuestion.questionText
sharedQuestion.questionText = "面膜做得越久越好。"
expect(shownOnScreen.text == "面膜做的时间越久越好。",
       "Model 改了（现在是「\(sharedQuestion.questionText)」），label 上仍是旧的那句「\(shownOnScreen.text ?? "nil")」—— 视图**不会**自己跟着动，这是好事：它就是 7.5 那句话的意思")
shownOnScreen.text = sharedQuestion.questionText
expect(shownOnScreen.text == "面膜做得越久越好。",
       "再喂一次才更新 —— 于是「什么时候再喂」成了架构问题：书 7.11 的答案是「在 nextQuestion() 里手动调 updateUI()」，§17 与 §19~§22 量另外五种（target-action、KVO、通知中心、代理、闭包）")
var holder = [sharedQuestion]
holder.removeAll()
expect(sharedQuestion.questionText == "面膜做得越久越好。",
       "把对象交出去之后再销毁容器（holder 里现在 \(holder.count) 项），对象还活着：引用计数不归容器管 —— 这也是本章能用「另起一个 bank」做隔离测试的前提（§28 的依赖注入）")

// ============================================================
// §13 没有窗口的时候，控制器的 view 是哪儿来的、有多大
// ============================================================
section(13, "loadViewIfNeeded 给的那块 view：书里「屏幕宽度」这件事在没有 UIWindow 时到底是什么")
// 书 7.11 那行进度条代码要读 view.frame.size.width，原书写的是「还需要知道屏幕的宽度值」。
// 在 Xcode 工程里这句话不用证 —— 应用启动后 view 被放进窗口，宽度是屏幕宽度。
// 本章的进程里没有 UIApplication.shared（§1），所以要亲眼看一屏：这块 view 还在不在、
// 多宽、安全区给的是什么。这几条数字后面 §14 要拿来算进度。
let geometry = QuizViewController()
geometry.loadViewIfNeeded()
let screenWidth = geometry.view.frame.size.width
line("  geometry.view.frame=\(geometry.view.frame) bounds=\(geometry.view.bounds) safeAreaInsets=\(geometry.view.safeAreaInsets)")
expect(geometry.isViewLoaded,
       "loadViewIfNeeded 之后 isViewLoaded=true，view 确实造出来了（\(String(describing: type(of: geometry.view!)))）—— 没有窗口也能有 view：第 31 章说的那条边界在这一层同样成立")
expect(screenWidth > 0,
       "view.frame.size.width=\(screenWidth) —— 一个没有窗口、没有根视图控制器的 view 仍然有非零宽度，它来自 UIScreen.main.bounds（第 31 章 §16 量过这台模拟器给的是 402×874），不是来自「被显示出来」")
expect(geometry.view.safeAreaInsets.top == 0 && geometry.view.safeAreaInsets.bottom == 0,
       "可安全区全是 0（top=\(geometry.view.safeAreaInsets.top) bottom=\(geometry.view.safeAreaInsets.bottom)）：宽度是屏幕给的，内缩是窗口给的 —— 没有窗口就没有内缩")
expect(geometry.progressBar.frame.origin == .zero && geometry.progressBar.frame.height == 0 && geometry.progressBar.frame.width == screenWidth / 13,
       "出厂时 progressBar.frame=\(geometry.progressBar.frame)：四个数里只有**宽度**不是 0，而它来自 viewDidLoad → nextQuestion → updateUI 那一行算术 —— origin 和 height 一直是 0（书 2.2 里这两样是故事板给的 frame，第 31 章 §13 量的是同一件事的另一半）：这一节把「谁拥有这个 frame 的哪一部分」拆成了可数的格子")

// ============================================================
// §14 进度条的 13 格：满格发生在「看到」最后一题时，不是答完时
// ============================================================
section(14, "progressBar 宽度全表：书 7.11 那句「完成全部13道题目以后宽度与屏幕一致」的准确落点")
// 书的原文是「构建并运行项目……当完成全部13道题目以后黄色进度条的宽度与屏幕宽度一致」。
// 眼睛看到的结果对得上，但原因和这句话说的不一样：updateUI 只在 nextQuestion 的
// **合法分支**里被调，所以满格是在显示第 13 题的那一刻到达的；答完第 13 题之后
// 走的是 else 分支，一行界面都没再更新（§10 已经量过游标出界）。
let barWatch = QuizViewController()
barWatch.loadViewIfNeeded()
let unitWidth = geometry.view.frame.size.width / 13
line("  屏幕宽度 \(screenWidth)，13 等分之后每格 \(String(format: "%.4f", unitWidth))")
var barWidths: [Double] = []
for _ in 0..<13 {
    barWatch.answerPressed(barWatch.noButton)
    barWidths.append(barWatch.progressBar.frame.size.width)
}
line("  逐题答完之后的宽度：\(barWidths.map { String(format: "%.2f", $0) }.joined(separator: " "))")
expect(barWidths.count == 13 && abs(barWidths[12] - screenWidth) < 1e-9,
       "第 13 次点击之后宽度是 \(String(format: "%.2f", barWidths[12]))，正好等于屏幕宽度 —— 但它不是「答完 13 题」算出来的：这一次点击走的是 else 分支（没调 updateUI），这个宽度是**显示第 13 题时**（questionNumber=12，(12+1)/13）留下的")
expect(abs(barWidths[0] - unitWidth * 2) < 1e-9,
       "第 1 次点击后的宽度 \(String(format: "%.2f", barWidths[0])) = 2 格：因为 answerPressed 先 += 1 再 nextQuestion，屏幕上已经是第 2 题了 —— 进度条跟着「显示到第几题」走，不跟着「答完几题」走")
var monotonic = true
for i in 1..<barWidths.count where barWidths[i] < barWidths[i - 1] { monotonic = false }
expect(monotonic,
       "整条序列单调不减（\(barWidths.count) 个采样点）：把宽度写成 frame 的算术而不是查表，好处就在这儿 —— 但它也意味着宽度这个状态**只有这一行代码知道**（§28 换题库长度时要改的正是这个 13）")
barWatch.startOver()
expect(abs(barWatch.progressBar.frame.size.width - unitWidth) < 1e-9,
       "书 7.11 还说「单击重新开始以后，进度条又回到最初的宽度」—— 实测回到 \(String(format: "%.4f", barWatch.progressBar.frame.size.width))，即**一格**：它和出厂那一格（§13 读到的同一个数）相等，但绝不是 0 —— 「回到最初」在代码里是重新走一遍 updateUI，不是把宽度擦掉")

// ============================================================
// §15 那一行为什么必须写 CGFloat()：能被量的那一半
// ============================================================
section(15, "CGFloat 与 Int 的混算：编译器的红点进探针，能算的账留在这儿")
// 书 7.11 先给了 `progressBar.frame.size.width = (view.frame.size.width / 13) * questionNumber`，
// 说「此时的代码行会报错……在乘号（*）的两侧不能一边是单精度值，一边却是整型值」。
// 那是编译期诊断，判定 1 要求日志为空，所以原文进探针 e05 —— 而原文**与书里的解释对不上**：
// 本机的 Swift 把光标放在**除号**上，消息是
// 「referencing operator function '/' on 'DurationProtocol' requires that 'CGFloat'
// conform to 'DurationProtocol'」，一个和进度条毫无关系的协议。
// 真正对应「一单一整」的是最小样本 `CGFloat * Int`（同一支探针的第二段），
// 那句才说 "binary operator '*' cannot be applied to operands of type 'CGFloat' and 'Int'"。
// 换句话说：重载消解失败时，编译器报的是它**试到最后的那个候选**，不一定是写错的那一下。
// 这里量能算的那一半：为什么 Swift 拦下这一下是有道理的 —— 因为 Int 的除法会截断。
let intDivision = screenWidth.truncatingRemainder(dividingBy: 1)
line("  屏幕宽度 \(screenWidth) 除以 13 = \(String(format: "%.10f", unitWidth))；宽度对 1 取余 = \(intDivision)")
let asIntWidth = Int(screenWidth)
expect(unitWidth * 13 != 0 && abs(unitWidth * 13 - screenWidth) < 1e-9,
       "CGFloat 的除法保住了小数：\(String(format: "%.10f", unitWidth)) × 13 = \(unitWidth * 13)，回到屏幕宽度 —— 换成 Int 的除法（本机屏幕宽度是整数 \(asIntWidth)）就只剩 \(asIntWidth / 13)，一格短了 \(String(format: "%.2f", screenWidth - Double(asIntWidth / 13) * 13)) 像素，13 格走完离屏幕宽度还差这么多")
expect(Double(12 + 1) == 13.0,
       "书里改法同时做了两件事：加 CGFloat() 和把 questionNumber 换成 questionNumber+1 —— 前一件是**类型**，后一件是**编号**（§10 那条），混在一起说容易让人以为报错是 +1 引起的。探针 e05 的两段原文里没有任何一句提到 1 与 13 的编号差：它说的是类型，甚至连出错的那个运算符都没指对")
let asFloat = Float(barWatch.questionNumber + 1) / Float(13)
line("  换成 UIProgressView 的话，同一件事写作 progress=\(String(format: "%.6f", asFloat))：它吃 0...1 的比例，不吃像素")
barWatch.progressValue.progress = asFloat
expect(barWatch.progressValue.progress == asFloat && asFloat > 0 && asFloat <= 1,
       "对照组 UIProgressView 吃的是**比例**：写 \(String(format: "%.6f", asFloat)) 就读回 \(String(format: "%.6f", barWatch.progressValue.progress))，长度由系统按控件宽度画 —— 书 7.11 用 UIView 的**宽度**当进度（像素、控制器自己算），UIProgressView 用 0...1（视图自己画）：这两种写法对「谁拥有这个数」的回答不同，前者只有 updateUI 那一行知道总共有 13 格，后者连 13 都不用说")

// ============================================================
// §16 tag 当身份：书 7.13 把「点了哪颗按钮」压成一个整数
// ============================================================
section(16, "`pickedAnswer = sender.tag - 1`：按钮的身份是一个可以在 Inspector 里填错的整数")
// 书 7.13 步骤 3 让三颗按钮的 tag 分别填 1、2、3，代码写 `sender.tag - 1` 当数组下标。
// 这一节量这个减一：它对得上什么、错了会怎样。越界那一下归探针 r02。
let optionCount = 3
var tagMapping: [(Int, Int)] = []
for tag in [1, 2, 3] { tagMapping.append((tag, tag - 1)) }
line("  tag → 下标：\(tagMapping.map { "\($0.0)→\($0.1)" }.joined(separator: " "))")
expect(tagMapping.map { $0.1 } == [0, 1, 2],
       "tag 填 1/2/3 时，减一得到 0/1/2 —— 正好是 \(optionCount) 个选项的下标集：这个减一是把「Interface Builder 里的编号（从 1 起）」换成「Swift 数组的下标（从 0 起）」，和本章 §10 那个 +1 是同一件事的反方向")
let untouched = UIButton(type: .system)
expect(untouched.tag == 0 && untouched.tag - 1 == -1,
       "忘了在 Inspector 里填 tag 的那颗按钮：tag 出厂是 \(untouched.tag)，减一成了 \(untouched.tag - 1) —— 它是负数，下标运算当场越界（原文见探针 r02：负数与超出末尾是同一句 `Index out of range`）。编译器拦不住，因为 tag 的类型是 Int，不是「合法下标」")
let sameTagA = UIButton(type: .system); sameTagA.tag = 1
let sameTagB = UIButton(type: .system); sameTagB.tag = 1
expect(sameTagA !== sameTagB && sameTagA.tag == sameTagB.tag,
       "两颗不同的按钮可以有同一个 tag（同一份题分）—— tag 是**抄在界面里的编号**，不是身份：§7 那个 let 拦不住 append，这里的 Int 也保证不了唯一")
let eqView = QuizViewController()
eqView.loadViewIfNeeded()
eqView.pickedAnswer = false          // 假装上一题用户点的是「否」
eqView.yesButton.tag = 7             // Inspector 里把这颗「是」的 tag 填错
eqView.answerPressed(eqView.yesButton)
expect(!eqView.pickedAnswer && eqView.questionNumber == 1,
       "回到书 7.6 的写法（if tag==1 置 true / else if tag==2 置 false）：把 yesButton 的 tag 改成 7 再点，pickedAnswer 仍是上一轮的 \(eqView.pickedAnswer)，可游标照样走到 \(eqView.questionNumber) —— 两个分支都不成立，它**静默地**拿旧值判了卷。7.13 换成 tag-1 当数组下标之后，同一处填错从「静默」变成「崩溃」：一个更难查，一个更早响")

// ============================================================
// §17 裸进程里按钮不派发事件：主线只能自己调方法
// ============================================================
section(17, "把主线改成「真点一下」会怎样：sendActions 在这条路上过不去，所以本章直调方法")
// 本章前面每一次「点按钮」都是直接调 answerPressed(_:)。这一步把这层糊掉的地方挑明，
// 并且**先试原路**：给按钮挂上 target-action，再用 UIControl 那句「照着表打一遍」。
// 第 31 章 §16 已经量过一次「不派发」，这一节量的是它在 MVC 语境下的后果 ——
// 控制器的逻辑一步不少，缺的只是「谁去叫它第一步」。
let wired = QuizViewController()
wired.loadViewIfNeeded()
wired.yesButton.addTarget(wired, action: #selector(QuizViewController.answerPressed(_:)), for: .touchUpInside)
let beforeWired = wired.questionNumber
wired.yesButton.sendActions(for: .touchUpInside)
line("  发一次 sendActions(for: .touchUpInside)，游标从 \(beforeWired) 走到 \(wired.questionNumber)（这个方法返回 Void，本身不报告有没有命中）")
expect(beforeWired == 0 && wired.questionNumber == 0,
       "表里确实登记了（下面读得到 allEvents=64），可游标一步没动 —— 派发要过 UIApplication.shared，而它是 nil（§1）。第 31 章 §16 那条边界与界面文件无关，在这里以同样的方式现形")
line("  wired.yesButton.allControlEvents.rawValue=\(wired.yesButton.allControlEvents.rawValue)（.touchUpInside=\(UIControl.Event.touchUpInside.rawValue)）；superview=\(String(describing: wired.yesButton.superview))")
expect(wired.yesButton.allControlEvents == UIControl.Event.touchUpInside,
       "allEvents 读得回 \(wired.yesButton.allControlEvents.rawValue)：addTarget 这一步是**成功**的，目标、动作、事件三样都在表上 —— 崩的不是接线，是接线之上的事件管线")
wired.answerPressed(wired.yesButton)
expect(wired.questionNumber == 1 && wired.pickedAnswer,
       "同一个对象、同一个方法，直接调就全走通了（游标 \(wired.questionNumber)、pickedAnswer=\(wired.pickedAnswer)）—— 这就是本章的换法：把「点一下看看」换成「调这个方法，然后读它写进视图的那几个值」，被跳过的只有路由，一行逻辑都没少")
expect(wired.yesButton.superview == nil,
       "顺带一条能解释上面两行的事实：yesButton 从来没被 addSubview 过（superview 是 \(String(describing: wired.yesButton.superview))）—— 书 2.2 摆在故事板上的按钮在这里只是控制器持有的一个对象；没有父视图、没有窗口，它永远不可能自己收到一次触摸")

// ============================================================
// §18 六种「视图怎么知道该更新了」的第一种：书里那种手动调
// ============================================================
section(18, "第 1 种·手动：一次点击到底改了几处界面（updateUI 被叫到的次数）")
// §12 留下的问题：改了 Model，视图不动，所以得有人再喂一次。书 7.11 的答案是
// 「在 nextQuestion() 里手写一句 updateUI()」。这一节先给这一种记账，§19~§22
// 用同一套账目去量另外四种机制 —— 四节的判据都是「谁被叫到、叫了几次」。
Trace.reset()
let counted = QuizViewController()
counted.loadViewIfNeeded()
func uiCalls() -> [String] { Trace.log.filter { $0.hasPrefix("updateUI") } }
func gradeCalls() -> [String] { Trace.log.filter { $0.hasPrefix("回答正确") || $0.hasPrefix("错误") } }
expect(uiCalls() == ["updateUI：0"],
       "刚 loadViewIfNeeded 完（viewDidLoad → nextQuestion → updateUI）：界面更新 \(uiCalls().count) 次 —— \(uiCalls().joined(separator: " "))。一次点击进入的状态机里，「改数据」和「改界面」是两句分开的话，各记一笔")
for _ in 0..<12 { counted.answerPressed(counted.noButton) }
expect(uiCalls().count == 13 && gradeCalls().count == 12,
       "再点 12 次：界面更新累计 \(uiCalls().count) 次、判卷 \(gradeCalls().count) 次 —— 两者只差出厂那一次（那时候还没有用户动作，只有第一题上屏）")
counted.answerPressed(counted.noButton)
expect(uiCalls().count == 13 && Trace.log.contains("弹框：全部答完"),
       "第 13 次点击：界面更新仍是 \(uiCalls().count) 次（没有新增），新增的是「弹框：全部答完」—— else 分支不喂视图，这条 §10/§11 已经付过代价，这里给它记账的口径")
expect(counted.questionLabel.text != nil && counted.scoreLabel.text != nil && counted.progressBar.frame.width > 0,
       "updateUI 里那三行各写一处界面（题面、分数、进度条宽度）：现在三处都有值（\"\(String(counted.questionLabel.text!.prefix(6)))…\" / \"\(counted.scoreLabel.text ?? "")\" / \(String(format: "%.1f", counted.progressBar.frame.width))px）—— 手动这一种的代价是**界面有几处，这个方法就有几行**，加一个控件就有人忘记加一行（§11 那个 bug 是它的对偶：清状态的人没清界面）")

expect(counted.scoreLabel.text == "分数：\(counted.score)",
       "三行里的第二行展开来看是「\(counted.scoreLabel.text ?? "")」—— 那个插值不是装饰：UILabel.text 的类型是 String?，而 score 是 Int，中间没有自动换算。书 7.11 第一次就写成了 `scoreLabel.text = score`，编译器原文见探针 e02（「cannot assign value of type 'Int' to type 'String?'」）。这也是「控制器与视图之间传的是字符串，不是数字」这句话的最小落点：数字要说什么话，由控制器那一行决定")

// ============================================================
// §19 第 2 种：KVO —— 把「谁改了 score」交给运行时
// ============================================================
section(19, "第 2 种·KVO：观察者是注册上去的，不是写在那三行之后的")
// KVO 与本章的关系很直接：它让「改了 score」这件事能被**别人**看见，控制器不需要
// 知道谁在看。代价是属性必须先暴露给 Objective-C 运行时（QuizViewController 里
// 那句 @objc dynamic，第 27 章讲的 isa-swizzling 就发生在这类属性上）。
// 「代价」这两个字要说准：编译器**并不拒绝**少写那两个词的版本 —— 探针 e06 抄到的
// 是一条 warning（`passing reference to non-'@objc dynamic' property ... may lead to
// unexpected behavior or runtime trap`），编译退出码 0；而探针 r05 把这句话的后半跑完了：
// 真的走到注册那一句就当场 trap（`Could not extract a String from KeyPath \PlainQuiz.score`，
// 退出码 132）。也就是说这条限制**不是编译期给的**，是运行时给的，而警告在判定 1 这里
// 同样是硬失败 —— 本章 §30 讲 OC 混编时会再遇到同一种「黄色叹号在这里不许进来」。
let kv = QuizViewController()
kv.loadViewIfNeeded()
var kvoHits: [String] = []
let token = kv.observe(\.score, options: [.old, .new]) { _, change in
    kvoHits.append("\(change.oldValue ?? -1)→\(change.newValue ?? -1)")
}
expect(kvoHits.isEmpty,
       "注册观察者之后、任何操作之前：命中 \(kvoHits.count) 次 —— 出厂那次 score=0 的赋值发生在 init 里，和 §3 的 didSet 一样不在观察范围内")
kv.score = 1
kv.score = 2
expect(kvoHits == ["0→1", "1→2"],
       "两次赋值两次命中，且 oldValue/newValue 都拿得到（\(kvoHits.joined(separator: " "))）—— 这里没有任何一句 updateUI，改动是被运行时「通知」出去的")
Trace.reset()
kv.answerPressed(kv.yesButton)
expect(!Trace.log.filter({ $0.hasPrefix("updateUI") }).isEmpty && kvoHits.count == 3,
       "点一次按钮：手动那一路照常记到 updateUI（\(Trace.log.filter { $0.hasPrefix("updateUI") }.count) 次），KVO 那边同时多命中 1 次（现在 \(kvoHits.count)）—— 两种机制会**同时**成立，于是同一处界面更新可能被喂两遍：这就是「通知机制只能选一种当主线」的实际理由")
token.invalidate()
let beforeInvalidate = kvoHits.count
kv.score = 99
expect(kvoHits.count == beforeInvalidate && kv.score == 99,
       "token.invalidate() 之后 score 照样变（现在是 \(kv.score)），可观察者一条都不收（仍是 \(kvoHits.count) 条）—— 观察是有寿命的：注册方负责取消，否则它比被观察的对象活得久就是悬垂（§20/§22 各有一种更隐蔽的形态）")

// ============================================================
// §20 第 3 种：NotificationCenter —— 控制器连「有没有人听」都不知道
// ============================================================
section(20, "第 3 种·NotificationCenter：post 是同步的，而发送方不认识接收方")
let center = NotificationCenter.default
let nc = QuizViewController()
nc.loadViewIfNeeded()
var ncHits: [String] = []
let observer = center.addObserver(forName: .init("QuizScoreChanged"), object: nc, queue: nil) { note in
    ncHits.append("\(note.object is QuizViewController ? "同一位" : "不是这位"):\(note.userInfo?["score"] ?? "?")")
}
nc.score = 5
expect(ncHits.isEmpty,
       "改了 score 而没人 post：命中 \(ncHits.count) 条 —— 这一种和 KVO 的**根本**差别在这儿：KVO 挂在属性上，赋值即通知；通知中心挂在「有人显式 post」上，忘 post 就一个字都不会响")
center.post(name: .init("QuizScoreChanged"), object: nc, userInfo: ["score": nc.score])
expect(ncHits.count == 1 && ncHits[0] == "同一位:5",
       "post 之后同一行代码里就能读到命中（\(ncHits.joined(separator: " "))）—— 默认 queue=nil 时 post 是**同步**的：不发到别的线程去，谁 post 谁就把观察者跑完再回来，所以「post 返回」等于「视图已经更新完」")
center.post(name: .init("QuizScoreChanged"), object: QuestionBank(), userInfo: nil)
expect(ncHits.count == 1,
       "换一位发送者（object 传一个 QuestionBank）、连 userInfo 都不给：观察者一条都不收（还是 \(ncHits.count) 条）—— object 是**过滤条件**，不是文档；这一格填错的表现和 §17 那句「静默」一模一样：不报错，就是不响")
center.removeObserver(observer)
center.post(name: .init("QuizScoreChanged"), object: nc, userInfo: ["score": 7])
expect(ncHits.count == 1,
       "removeObserver 之后再 post：命中不增加（\(ncHits.count) 条）—— 和 §19 的 invalidate 同一个道理，只是这一种的注册在**全局**的中心上：忘了摘，观察者连同它捕获的东西一起永远摘不掉（§22 的闭包那一节会当场看到后果）")

// ============================================================
// §21 第 4 种：代理 —— 回调写在一句 weak 属性后面
// ============================================================
section(21, "第 4 种·代理：谁持有谁，写在两行声明里")
// 代理是 UIKit 用得最多的机制（第 22 章的 UIScrollViewDelegate 就是它）。书里的小测验
// **一个代理都没有** —— 它只有手动那一种。这一节拿一个同形的控制器补上，量三件事：
// 回调什么时候到、代理断了会怎样、Swift 的「可选方法」和 OC 的差在哪。
Trace.reset()
let delegated = DelegatedQuiz(list: Array(bank.list.prefix(3)))
var recorder: FinishRecorder? = FinishRecorder()
delegated.delegate = recorder
delegated.answer(chosen: 1)
expect(Trace.log.filter { $0.hasPrefix("协议扩展的默认实现") }.count == 1,
       "答第一题：didAnswer 这个方法 recorder 一个字都没写，可它照样被调到了（Trace 里有 \(Trace.log.filter { $0.hasPrefix("协议扩展的默认实现") }.count) 条「\(Trace.log.first ?? "")」）—— Swift 的「可选方法」是**编译期**给了一份默认实现，调用照发；OC 的 @objc optional 是**运行期**查表，没实现就根本不发消息（第 27 章）。表现一样，出事的地方不一样")
delegated.answer(chosen: 2)
delegated.answer(chosen: 1)
expect(recorder?.finishes == [3],
       "三题跑完（最后一题答完游标出界）：didFinishWithScore 只在越界那一次被叫到，收到 \(recorder?.finishes.count ?? -1) 次、分数 \(recorder?.finishes.first.map(String.init) ?? "无") —— 代理的价值就在这儿：控制器**不知道**外面有几个人、叫什么名字，它只按协议问一句")
expect(delegated.delegate === recorder,
       "delegated.delegate 与 recorder 是同一个对象（\(delegated.delegate === recorder ? "===" : "!==")）—— 这一句看着普通，却是本章唯一一处 UIKit 式写法：属性声明成 weak（Presenter.swift 里那句），等下 §22 会给出如果没有 weak 的下场")
recorder = nil
delegated.questionNumber = 0        // 回到合法区间再答一次（否则就是探针 r01 那个越界）
let beforeDrop = Trace.log.count
delegated.answer(chosen: 1)
expect(Trace.log.count == beforeDrop && delegated.delegate == nil,
       "把代理对象放掉（recorder = nil）之后 delegate 自己变成 \(String(describing: delegated.delegate))，再答一题：Trace 一条都没多（\(beforeDrop) → \(Trace.log.count)）—— weak 属性归零、回调静默消失，不崩也不报错。UIKit 里「代理忘了设」的全部症状就是这一条：界面照常能动，只是没人收尾")

// ============================================================
// §22 第 5 种：闭包 —— 书 7.9 那个 handler 的同族
// ============================================================
section(22, "第 5 种·闭包：把「之后要做的事」存成一个属性，代价是它连对象一起存")
// 书 7.9 正文专门讲过：handler 参数给的「不是值也不是对象，而是一段代码」，
// 「因为闭包有其独立的生存期……所以在闭包之中需要使用 self 关键字指明要执行当前类中的
//  startOver() 方法」。这段话的账，量出来是下面几条。
// 判据在这里换一个：不是「用内存工具看一眼」，而是「函数返回之后那个 weak 变量还是不是
// nil」—— 它是可打印、可断言、-Onone 与 -O 必须给同一个答案的形态（ARC 不做环检测，
// 这一条不依赖优化级别，也不依赖时机）。
let cb = CallbackQuiz(list: Array(bank.list.prefix(3)))
var hits: [Int] = []
cb.onScoreChanged = { value in hits.append(value) }
cb.onFinish = { value in hits.append(1000 + value) }
weak var weakCB = cb
let traceBeforeCb = Trace.log.count
cb.answer(chosen: 1)
expect(hits == [1],
       "闭包这一种**答完就响**：第 1 题答对，onScoreChanged 收到 \(hits) —— 和 §20 的通知中心一样是同步的，但不需要全局 center，也不看 object 过滤")
cb.answer(chosen: 1)
cb.answer(chosen: 1)
expect(hits == [1, 2, 1002],
       "三题跑完（第 2 题答错，因为屏幕上那题的正确答案是「否」）：\(hits) —— 前两个是每次加分给的，末尾那个 1002 是 onFinish 给的「总分 2」。书 7.9 把这两种合成了一处：弹窗上那颗「重新开始」按钮的 handler 就是一个闭包属性（§24/§25 再把它拆开）")
expect(weakCB != nil && Trace.log.count == traceBeforeCb,
       "这两条闭包只抓了主线里的 hits，没有反过来抓 cb：对象仍归主线持有（weak 读回\(weakCB == nil ? "已释放" : "还在")）；而控制器的账本从 \(traceBeforeCb) 条到 \(Trace.log.count) 条一条没多 —— 闭包这一种**不在任何账本上留痕**，回调发生在谁身上、发生了几次，全靠读那个被捕获的数组。这是它比手动 updateUI 更难查的地方")
// —— 书 7.9 必须写 self 的那一半：闭包捕获了谁 ——
weak var cycleProbe: CallbackQuiz?
func makeStrongCapture() {
    let quiz = CallbackQuiz(list: Array(bank.list.prefix(3)))
    quiz.onFinish = { _ in quiz.label.text = "闭包替我把对象养着" }   // 强捕获 quiz
    cycleProbe = quiz
    quiz.onFinish?(0)
}
makeStrongCapture()
expect(cycleProbe != nil,
       "把闭包写成强捕获（书 7.9 的 self 就是这个形状）：函数一结束，外部最后一条强引用没了，对象却还活着（weak 读回 \(cycleProbe == nil ? "nil" : "非 nil")）—— quiz 抓着闭包、闭包抓着 quiz，环上的计数永远不归零；ARC 只数引用，不做环检测")
weak var weakCaptureProbe: CallbackQuiz?
func makeWeakCapture() {
    let quiz = CallbackQuiz(list: Array(bank.list.prefix(3)))
    quiz.onFinish = { [weak quiz] _ in quiz?.label.text = "弱捕获：抓不住也不报错" }
    weakCaptureProbe = quiz
    quiz.onFinish?(0)
}
makeWeakCapture()
expect(weakCaptureProbe == nil,
       "同一处换成 [weak quiz]：函数一结束就释放干净（weak 读回 \(String(describing: weakCaptureProbe))）—— 书 7.9 那句「因为闭包有其独立的生存期……所以必须写 self」讲的是**编译器为什么要求你写 self**，而它顺手埋下的正是上面那个环：写了 self 就写死了强捕获")

// ============================================================
// §23 分层不是编译器保证的：KVC 能从任意方向把墙捅穿
// ============================================================
section(23, "书 7.5 那句「永远不会直接发生联系」的边界：纪律，不是机制")
// 7.5 的原文是「数据模型与视图永远不会直接发生联系」。§12 证的是**默认情形**（不喂就不动）。
// 这一节证另一面：在 OC 运行时面前，这句话没有任何强制力 —— KVC 一句 setValue 就跨过去了。
let kvc = QuizViewController()
kvc.loadViewIfNeeded()
Trace.reset()
kvc.questionLabel.setValue("Model 直接写进视图的一行", forKey: "text")
expect(kvc.questionLabel.text == "Model 直接写进视图的一行",
       "对 label 用 KVC 写 text，读回来是「\(kvc.questionLabel.text ?? "nil")」—— 没有 updateUI、没有 nextQuestion，视图照样变了")
expect(Trace.log.isEmpty,
       "而这一整节的 Trace 是空的（\(Trace.log.count) 条）：控制器的账本上**根本看不见**这次更新 —— 「视图被谁改了」这件事，一旦允许绕过控制器，就再也数不出来了。这就是那句话的真实分量：它保证不了，只能守")
let readBack = kvc.value(forKey: "score") as? Int
expect(readBack == kvc.score,
       "反过来也通：从视图外侧用 KVC 读控制器的 score（\(String(describing: readBack))，直接读是 \(kvc.score)）—— Model、Controller、View 之间没有围墙，只有方向约定（第 27 章量过 KVC 这套约定的代价：key 拼错是运行期的事）")
expect(kvc.responds(to: Selector(("setScore:"))),
       "KVC 之所以能写进来，是因为 score 被声明成了 @objc dynamic（§19 那句）：它在 OC 运行时里有 setScore: 这个 setter（responds=\(kvc.responds(to: Selector(("setScore:"))))）—— 「暴露给 KVO」和「暴露给 KVC」在运行时里是同一件事，分层要多薄就有多薄，全在声明那一行")

// ============================================================
// §24 弹窗：书 7.9 那个 UIAlertController 在这里是一堆可读的属性
// ============================================================
section(24, "把「弹出一个警告窗口」换成可读的对象：title / message / actions / preferredStyle")
// 书 7.9 的判据是「构建并运行项目……会弹出一个警告窗口，如图 7-17」。本章没有窗口，
// 于是把那句话拆成四问：弹的是什么、上面写了什么、有几颗按钮、点了会怎样。
// 前三个这一节量，第四个交给 §25。
Trace.reset()
let alerting = QuizViewController()
alerting.loadViewIfNeeded()
for _ in 0..<12 { alerting.answerPressed(alerting.noButton) }
expect(alerting.alert == nil && Trace.log.filter { $0.hasPrefix("弹框") }.isEmpty,
       "前 12 次点击（游标现在 \(alerting.questionNumber)）：弹窗对象还是 \(String(describing: alerting.alert))，Trace 里也没有「弹框」那笔 —— 弹窗是 else 分支的产物，合法区间一次都不会碰它")
alerting.answerPressed(alerting.noButton)
let gotAlert = alerting.alert
expect(gotAlert != nil && gotAlert?.title == "了不起！" && gotAlert?.preferredStyle == .alert,
       "第 13 次点击之后 presentFinishedAlert 造出了对象：title=「\(gotAlert?.title ?? "nil")」、preferredStyle=\(gotAlert.map { $0.preferredStyle.rawValue } ?? -1)（alert=\(UIAlertController.Style.alert.rawValue) / actionSheet=\(UIAlertController.Style.actionSheet.rawValue)）—— 书里那句「警告窗口」在代码里就是这几个字段")
expect(gotAlert?.message == "你已经完成了所有的题目，是否想重新开始呢？",
       "message 逐字对得上书 7.9 的那一行（「\(gotAlert?.message ?? "nil")」）—— 这一条是给「界面文案也要有判据」准备的：原书靠看图，本章靠读回字符串")
expect(gotAlert?.actions.count == 1 && gotAlert?.actions.first?.title == "重新开始",
       "actions 有 \(gotAlert?.actions.count ?? -1) 项、第一项标题「\(gotAlert?.actions.first?.title ?? "nil")」、style=\(gotAlert?.actions.first?.style.rawValue ?? -1)（default=\(UIAlertAction.Style.default.rawValue)）—— 书里只加了一颗按钮，所以这个数组长度本身就是一条规格")
expect(alerting.presentedViewController == nil && alerting.view.window == nil,
       "可 `present(alert, animated: true, completion: nil)` 那句的效果是空的：presentedViewController=\(String(describing: alerting.presentedViewController))、view.window=\(String(describing: alerting.view.window)) —— 第 22 章量过「在没有窗口的 VC 上 present 不生效」，这一节把它当成前提用：弹窗的**内容**可读，弹窗的**出现**不可，所以本章判的是内容")
line("  stderr 在这一步也没有任何东西（第 22 章那条实测在这里同样成立：不生效 ≠ 报错）")

// ============================================================
// §25 handler：那颗按钮真正做的事，以及书 7.9 那句「必须写 self」的代价
// ============================================================
section(25, "UIAlertAction 的 handler 读不回来，所以本章存了一份闭包：调它 = 点那颗按钮")
let restartAction = alerting.alert?.actions.first
expect(restartAction?.title == "重新开始" && alerting.restartHandler != nil,
       "按钮对象上读得到标题（「\(restartAction?.title ?? "nil")」），读不到闭包 —— handler 不是 UIAlertAction 的公开属性（原文见探针 e07），所以本章在造它之前先存了一份（\(alerting.restartHandler == nil ? "没存上" : "存的是同一个值")）。这不是绕开书：递出去的和存下的**是同一个闭包值**，调哪一份跑的都是同一段代码")
let beforeHandler = (alerting.questionNumber, alerting.score, alerting.questionLabel.text ?? "")
alerting.restartHandler?(restartAction!)
expect(alerting.questionNumber == 0 && alerting.score == 0,
       "调一次那份闭包：游标 \(beforeHandler.0)→\(alerting.questionNumber)、分数 \(beforeHandler.1)→\(alerting.score) —— 这是 startOver() 的效果，它是**闭包**干的事，不是 UIAlertController 干的")
expect(alerting.questionLabel.text == bank.list[0].questionText,
       "屏幕也回到了第 1 题（「\(String(alerting.questionLabel.text?.prefix(8) ?? ""))…」）：handler 里那句 self.startOver() 连 nextQuestion() 一起走 —— §11 的修法和 §25 的这段闭包是同一段代码，本章两次读到它")
expect(Trace.log.filter { $0.hasPrefix("handler") }.count == 1,
       "Trace 上多了一条「handler：重新开始」（\(Trace.log.filter { $0.hasPrefix("handler") }.count) 条）—— 判据从「图上有个窗口」换成了「这个闭包被调到、它改了这四个值」")
// —— 书 7.9 那句「必须写 self」在这里是有代价的 ——
weak var escaped: QuizViewController?
func makeAndRelease() {
    let vc = QuizViewController()
    vc.loadViewIfNeeded()
    for _ in 0..<13 { vc.answerPressed(vc.noButton) }   // 最后一次越界 → 造弹窗、挂 handler
    escaped = vc                                        // 主线只留一条**弱**引用
}   // vc 这条强引用到这儿就该结束了
makeAndRelease()
expect(escaped != nil,
       "函数一返回，局部强引用没了，可弱引用还指着对象（\(escaped == nil ? "没了" : "还在")）—— 控制器抓着 alert、alert 抓着 UIAlertAction、handler 里那句 self 又抓着控制器：§22 那个环在这一处是**三方**的，而它的起点就是本章为了能读回弹窗内容而多加的那个属性（书里的 alert 是个局部变量，函数一结束只剩 UIKit 自己那份引用，dismiss 就全清了）")
escaped?.releaseAlert()
expect(escaped?.alert == nil && escaped?.restartHandler == nil,
       "releaseAlert() 之后两个属性都读回 nil（alert=\(escaped?.alert == nil ? "nil" : "还在")、restartHandler=\(escaped?.restartHandler == nil ? "nil" : "还在")）—— 环**确实**断了：控制器不再抓着弹窗，也不再抓着那段闭包")
// 「断环」和「当场回收」是两件事，而后者不能写进本章的断言：探针 c01 把同一句
// releaseAlert() 放进三种位置（顶部作用域、包进函数、外面套一层 autoreleasepool），
// 三种读回来都是「还在」，两种配置（-Onone / -O）一字不差。原因不在 ARC 数错了引用，
// 而在弹窗是 UIKit 工厂方法造出来的：它自己那一份引用落在**哪一层自动释放池**里，
// 决定了它什么时候真的被收 —— [7]「连创建都在池子里」那一格才收得干净，
// 所以下面这一段照 [7] 的写法测，测出来两种配置都是 nil。
weak var pooled: QuizViewController?
func makeInsidePool() {
    autoreleasepool {
        let vc = QuizViewController()
        vc.loadViewIfNeeded()
        for _ in 0..<13 { vc.answerPressed(vc.noButton) }   // alert 在这层池子里造出来
        pooled = vc
    }
}
func releaseInsidePool() { autoreleasepool { pooled?.releaseAlert() } }
makeInsidePool()
line("  换成 c01 [7] 的写法（创建也放进 autoreleasepool）：函数返回后 weak=\(pooled == nil ? "没了" : "还在")（环还在，所以「还在」这一格两种配置都一样）")
releaseInsidePool()
expect(pooled == nil,
       "断环 + 池子退出之后 weak=\(pooled == nil ? "nil" : "还在") —— 这才是一条配置无关的「回收」判据：你控制不了对象被 autorelease 进哪一层池子，能控制的是**在池子的边界上**断环")

// ============================================================
// §26 书 7.13：同一条骨架换 Model —— 29 题的情商测试
// ============================================================
section(26, "书 7.13 的第二条产品线：两个数组、tag 减一、以及「最大 EQ 为 154 分」这句话")

/// 按给定的选项下标序列把一整轮跑完（序列不够长就用最后一项补齐）。
/// 跑完最后一题时游标越界进 else 分支，结论弹窗的内容留在属性上。
func runEQRound(_ picks: [Int], bank: QuestionBankEQ = QuestionBankEQ())
    -> (score: Int, title: String?, message: String?, progressText: String?, barWidth: CGFloat, vc: EQTestViewController) {
    let vc = EQTestViewController(bank: bank)
    vc.loadViewIfNeeded()
    let buttons = [vc.answerOneButton, vc.answerTwoButton, vc.answerThreeButton]
    for n in 0..<bank.list.count {
        vc.answerPressed(buttons[min(picks[n % picks.count], buttons.count - 1)])
    }
    return (vc.score, vc.resultAlert?.title, vc.resultAlert?.message,
            vc.progressLabel.text, vc.progressBar.frame.size.width, vc)
}

/// 想要总分 t（必须是 3 的倍数、0 ≤ t ≤ 174），该怎么答？
/// 三档分是 6/3/0，写成 3×(2a+b)，a=选第一档的题数、b=第二档的题数，
/// 令 q = t/3，取 a = max(0, q-29)、b = q-2a，剩下填第三档 —— 一定凑得出来。
func picks(forScore t: Int) -> [Int] {
    let q = t / 3
    let a = max(0, q - 29)
    let b = q - 2 * a
    return Array(repeating: 0, count: a) + Array(repeating: 1, count: b) + Array(repeating: 2, count: 29 - a - b)
}

Trace.reset()
let eqBank = QuestionBankEQ()
expect(eqBank.list.count == 29,
       "题库有 \(eqBank.list.count) 道题 —— 书 7.13 开头那句「这个应用共有29道题，测试时间20分钟，最大EQ为154分」里的第一个数字对得上")
expect(eqBank.list[0].questionText == "我有能力克服各种困难。" && eqBank.list[1].questionText == "如果我能到一个新的环境，我要把生活安排得：",
       "前两题的文本逐字照抄书 7.13 步骤 2 那段 init()（「\(eqBank.list[0].questionText)」和「\(eqBank.list[1].questionText)」）；其余 27 题在 GitHub 的初始化项目里、书上没印，这里用「第3题…第29题」占位 —— 本章要量的是那组**数字**和那四个区间，不是那 27 行文字")
expect(eqBank.mismatchedCount == 0,
       "每一题的选项个数和分值个数都相等（不一致的有 \(eqBank.mismatchedCount) 题）—— 书 7.13 步骤 2 末尾那句「questionOption 和 questionScore 这两个数组的元素个数必须一致，否则会超出数组范围，导致应用程序崩溃」说的就是这两个数：它们不是同一份数据，是两份，没人强制它们对齐")
line("  每题最高那一档是 \(eqBank.list[0].questionScore.max() ?? -1) 分，29 题全取最高档 = \(eqBank.maxPossibleScore) 分")
expect(eqBank.maxPossibleScore == 174,
       "于是「最大 EQ」按这份题库算是 \(eqBank.maxPossibleScore) 分，而书上写的是 154 —— 差的不是某一道题的分值，是**整句话的口径**：154 既不是 29×6，也不是 29×3，下面这条更狠")
let allYes = runEQRound([0])
let allMaybe = runEQRound([1])
let allNo = runEQRound([2])
line("  三种整轮答法：全「是的」→ \(allYes.score) 分、全「不一定」→ \(allMaybe.score) 分、全「不是」→ \(allNo.score) 分")
expect(allYes.score == 174 && allMaybe.score == 87 && allNo.score == 0,
       "全取 6 分得 \(allYes.score)、全取 3 分得 \(allMaybe.score)、全取 0 分得 \(allNo.score) —— 三个数都是 3 的倍数，而这不是巧合：每题的三档分是 {6, 3, 0}，任何一轮的总分都是它们的整数组合，结果只能是 3 的倍数（0 到 \(eqBank.maxPossibleScore) 之间的每一个 3 的倍数都取得到，§27 现造分数给下面那四条区间用）")
expect(154 % 3 != 0,
       "154 % 3 = \(154 % 3) —— 所以 154 不只是一个「偏小的最大值」，它连一个**可达的分数**都不是。按这份题库，答到顶是 174，而 154 这一档谁都拿不到。书 7.13 开头那句话里三个数字，只有 29 是对的（「测试时间20分钟」是人的事，代码里不存在）")
// —— 书 7.13 步骤 2：tag 是这套「按位置取分」的唯一桥梁 ——
Trace.reset()
let eqFactory = EQTestViewController()
line("  出厂（还没 loadView）：questionNumber=\(eqFactory.questionNumber)、pickedAnswer=\(eqFactory.pickedAnswer)、score=\(eqFactory.score)")
expect(eqFactory.pickedAnswer == -1,
       "pickedAnswer 的出厂值这里是 -1（书 7.13 没给这一行的初始值，只给了类型）—— 挑 -1 是为了让「一次都没点」在数值上是可辨认的，因为本节下面那条式子会把 tag 减一：没填 tag 的按钮算出来的正是 -1")
eqFactory.loadViewIfNeeded()
line("  三颗按钮的 tag：\(eqFactory.answerOneButton.tag) / \(eqFactory.answerTwoButton.tag) / \(eqFactory.answerThreeButton.tag)（书 7.13 步骤 2：故事板 Inspector 里从上到下填 1、2、3）")
expect(eqFactory.questionLabel.text == eqBank.list[0].questionText && eqFactory.progressLabel.text == "1 / 29",
       "loadViewIfNeeded 走完 viewDidLoad 里那句 nextQuestion()：屏幕上第 1 题是「\(String(eqFactory.questionLabel.text?.prefix(9) ?? ""))…」、进度文字是「\(eqFactory.progressLabel.text ?? "nil")」—— 注意这个「1」是 `questionNumber + 1` 来的，游标本身还是 \(eqFactory.questionNumber)（§10 那条编号差在 29 题这一版里一模一样）")
let beforeFirstTap = eqFactory.score
eqFactory.answerPressed(eqFactory.answerTwoButton)
expect(eqFactory.pickedAnswer == 1 && eqFactory.score == beforeFirstTap + eqBank.list[0].questionScore[1],
       "点第二颗按钮：`pickedAnswer = sender.tag - 1` 把 tag \(eqFactory.answerTwoButton.tag) 变成下标 \(eqFactory.pickedAnswer)，score 从 \(beforeFirstTap) 走到 \(eqFactory.score) —— 这一行代码把「界面上的第几颗按钮」和「数据里的第几档分值」焊在一起，焊点是 Inspector 里那个手填的数字")
let tapLine = Trace.log.firstIndex(of: "点选：tag=2 → pickedAnswer=1") ?? -1
expect(tapLine > 0 && Trace.log[tapLine + 1] == "updateUI：1",
       "Trace 上这一笔记的是「\(Trace.log[tapLine])」紧跟着「\(Trace.log[tapLine + 1])」（这一节之前还有 \(tapLine) 条，是 viewDidLoad 那次出题）—— 顺序就是 answerPressed 里那四行的顺序：定 pickedAnswer、判卷、推游标、更新界面。上一节那条「忘了在 Inspector 里填 tag」在这里是同一个 bug 的第二种形态：tag 出厂是 0，减一得 -1，`questionScore[-1]` 当场越界（原文见探针 r02）")

// ============================================================
// §27 书 7.13 步骤 6：那四个结论区间，边界上到底谁接住了
// ============================================================
section(27, "四个 else if 之间的缝：108/111、129/132 各测一次，其中一格没人接")
// 书 7.13 步骤 6 给的是四条互不相连的判断：
//   score < 70 / score >= 70 && score < 109 / score >= 110 && score < 129 / score >= 130
// 请注意第二、三、四条的左边界是 70、110、130，而右边界是 109、129 —— 中间各留了一道缝。
// 缝要不要紧，取决于**有没有一个可达的分数正好掉在缝里**。§26 那条「都是 3 的倍数」
// 在这里正好用上：109、110 都不是 3 的倍数，所以那道缝永远落不到人身上；
// 而 129 = 3 × 43，它是可达的。
for target in [0, 69, 72, 108, 111, 126, 129, 132, 174] {
    let round = runEQRound(picks(forScore: target))
    line("  总分 \(String(format: "%3d", round.score))（\(target % 3 == 0 ? "3 的倍数，可达" : "不可达")）→ title=「\(round.title ?? "nil")」message 长度 \((round.message ?? "").count)")
}
let lowEdge = runEQRound(picks(forScore: 69))
let midEdge = runEQRound(picks(forScore: 72))
expect(lowEdge.title == "你的EQ较低" && midEdge.title == "你的EQ一般",
       "70 那道缝两侧：69 分 →「\(lowEdge.title ?? "nil")」，72 分 →「\(midEdge.title ?? "nil")」—— 因为可达分数只落在 3 的倍数上，`< 70` 和 `>= 70` 之间根本没有整数分数会被漏掉，这条缝是无害的")
let highMid = runEQRound(picks(forScore: 108))
let nextMid = runEQRound(picks(forScore: 111))
expect(highMid.title == "你的EQ一般" && nextMid.title == "你的EQ较高",
       "109/110 那道缝两侧：\(highMid.score) 分 →「\(highMid.title ?? "nil")」，\(nextMid.score) 分 →「\(nextMid.title ?? "nil")」—— 书里写的是 `< 109` 和 `>= 110`，中间的 109 谁也接不到，可 109 不是 3 的倍数，这道缝同样落不到任何人身上")
let hole = runEQRound(picks(forScore: 129))
expect(hole.score == 129 && hole.title == "" && hole.message == "",
       "而 129 分（= 3 × 43，答法：14 题「是的」+ 15 题「不一定」）是**可达**的，它正好掉在 `< 129` 和 `>= 130` 之间：title=「\(hole.title ?? "nil")」、message=「\(hole.message ?? "nil")」，两个都是空串 —— 书 7.13 步骤 6 那行 `var title = \"\"` 的初值在这里第一次真的被用上了")
line("  掉进缝里的那一轮，Trace 记的是「\(Trace.log.filter { $0.hasPrefix("结论") }.last ?? "nil")」—— 程序不崩、按钮照常、弹窗照弹，只是上面一个字都没有")
line("  这一格里还有一条 UIKit 的小事实：空串递进 UIAlertController 之后读回来是 \(String(describing: hole.title))，也就是**空串**而不是 nil —— 「这个弹窗有 title 字段、它是空的」和「它没有 title」在 API 上是两回事（第 31 章量过 UILabel 那一侧的同一区分）")
let above = runEQRound(picks(forScore: 132))
expect(above.title == "你就是个EQ高手",
       "132 分往上就有人接了：「\(above.title ?? "nil")」—— 所以这条缝是**一条缝**而不是**一堵墙**：129 一个人掉下去，130 以上（这里指 132）全都好好的")
expect(hole.vc.resultAlert != nil && hole.vc.resultAlert?.actions.count == 1 && hole.vc.resultAlert?.actions.first?.title == "重新开始",
       "空弹窗也仍然带着那颗按钮：actions=\(hole.vc.resultAlert?.actions.count ?? -1) 项、标题「\(hole.vc.resultAlert?.actions.first?.title ?? "nil")」—— 用户看到的是「一个空白框 + 重新开始」，而 §24 那条规格（actions 有 1 项）在这一格照样成立：区间漏了，流程没漏")
let maxRound = runEQRound(picks(forScore: 174))
expect(maxRound.title == "你就是个EQ高手" && maxRound.message == "你的情商高超不但是你事业的助手，更是你事业有成的一个重要前提条件。",
       "满轮下来（全答第一档）分数 \(maxRound.score)、结论「\(maxRound.title ?? "nil")」，message 逐字对得上书 7.13 步骤 6 的第四段 —— 这一条是给「界面文案也要有判据」准备的，和 §24 那条同一个用途")
line("  顺带一句：满档 \(maxRound.score) 分对应的书面上限是 154，按书那套区间，一个自称 154 满分的问卷，`>= 130` 那一档从 130 就开始、一直盖到 154 —— 换成真实上限 \(maxRound.score)，`>= 130` 这一档往上还要再接 \(maxRound.score - 130) 分（130 到 174 含两端是 45 个整数分）。区间和上限是两处写的，改一处不会带动另一处（§29 量同一件事的另一半）")

// ============================================================
// §28 书 7.13 步骤 3：二选一和三选一混在一份题库里
// ============================================================
section(28, "「29 道题中有一部分是二选一，还有一部分是三选一」：那段 enumerated() 循环的三颗按钮")
let mixedBank = QuestionBankEQ(mixedCount: 29)
line("  混排题库：第 1 题 \(mixedBank.list[0].questionOption.count) 个选项、第 2 题 \(mixedBank.list[1].questionOption.count) 个、第 3 题 \(mixedBank.list[2].questionOption.count) 个……")
expect(mixedBank.list.filter { $0.questionOption.count == 2 }.count == 14 && mixedBank.mismatchedCount == 0,
       "偶数题被造成二选一（共 \(mixedBank.list.filter { $0.questionOption.count == 2 }.count) 道）、奇数题三选一，而每一题的两个数组**仍然成对**（不一致 \(mixedBank.mismatchedCount) 题）—— 书里那句警告防的不是「选项少一个」，是「选项和分值这两个数组个数不一样」")
let mixed = EQTestViewController(bank: mixedBank)
mixed.loadViewIfNeeded()
expect(mixed.answerOneButton.isHidden == false && mixed.answerTwoButton.isHidden == false && mixed.answerThreeButton.isHidden == false,
       "第 1 题（三选一）上屏之后三颗按钮的 isHidden：\(mixed.answerOneButton.isHidden)/\(mixed.answerTwoButton.isHidden)/\(mixed.answerThreeButton.isHidden)，标题「\(mixed.answerOneButton.title(for: .normal) ?? "nil")」「\(mixed.answerTwoButton.title(for: .normal) ?? "nil")」「\(mixed.answerThreeButton.title(for: .normal) ?? "nil")」")
mixed.answerPressed(mixed.answerOneButton)
expect(mixed.answerThreeButton.isHidden == true,
       "第 2 题（二选一）上屏之后第三颗按钮 isHidden=\(mixed.answerThreeButton.isHidden)，标题还留着上一题的「\(mixed.answerThreeButton.title(for: .normal) ?? "nil")」—— 书 7.13 步骤 3 那段循环的做法是**每次先把三颗全隐藏**，再按 enumerated() 迭代出来的个数逐颗打开；隐藏而不重置标题，正是它能让第 3 颗「消失」的全部机制")
expect(mixed.answerOneButton.title(for: .normal) == "和从前相仿" && mixed.answerTwoButton.title(for: .normal) == "不一定",
       "第二题的两颗是「\(mixed.answerOneButton.title(for: .normal) ?? "nil")」「\(mixed.answerTwoButton.title(for: .normal) ?? "nil")」—— 这两个字符串来自 mixedBank.list[1].questionOption，也就是书上那句「根据 Question 对象提供的选项内容来动态修改按钮的标题」")
expect(mixedBank.list[1].questionScore.count == 2 && mixed.answerThreeButton.tag - 1 >= mixedBank.list[1].questionScore.count,
       "可第三颗按钮的 tag 减一 = \(mixed.answerThreeButton.tag - 1)，而屏幕上这一题（第 2 题）的 questionScore 只有 \(mixedBank.list[1].questionScore.count) 档 —— 这一调用本章**不执行**：`questionScore[2]` 当场 `Fatal error: Index out of range`（原文见探针 r03）。裸进程里 sendActions 不派发（第 31 章 §16、本章 §17），真实 App 里用户摸不到那颗隐藏按钮；这一格量的是**代码路径**而不是用户路径：`isHidden = true` 挡住的是一只手，挡不住一个方法调用，判卷层从头到尾不知道屏幕上少了一颗按钮")
mixed.startOver()
mixed.answerPressed(mixed.answerThreeButton)
expect(mixed.pickedAnswer == 2 && mixed.score == 0 && mixed.questionNumber == 1 && mixed.answerThreeButton.isHidden,
       "同一颗第三颗按钮按在**三选一**的那一题上（startOver 把屏幕送回第 1 题）：pickedAnswer=\(mixed.pickedAnswer)、这一档是 \(mixedBank.list[0].questionScore[2]) 分，score=\(mixed.score)、游标 \(mixed.questionNumber) —— 同一个方法、同一个 tag，安全还是崩溃完全取决于「题库里这一题恰好有几个选项」。这就是书 7.13 步骤 3 那段循环存在的理由，也是它把保护放在视图层的全部风险；答完这一题又回到二选一，第三颗按钮再次 isHidden=\(mixed.answerThreeButton.isHidden)")

// ============================================================
// §29 「把之前的 13 修改为 29」：这句轻描淡写的话在代码里是几处
// ============================================================
section(29, "书 7.13 步骤 5 那句「只需将之前的13修改为29即可」—— 那个「只需」值多少")
// 数一遍 EQTestViewController 里跟「29」有关的地方（源码里的字面量，本章用读回的值印证）：
//   nextQuestion() 的 `questionNumber <= 28`、updateUI() 的 `/ 29`、
//   progressLabel 那句 `"\(questionNumber + 1) / 29"`。
let oneRound = EQTestViewController(bank: QuestionBankEQ(count: 29))
oneRound.loadViewIfNeeded()
expect(abs(oneRound.progressBar.frame.size.width - 402.0 / 29.0) < 1e-9,
       "第 1 题的进度条宽度 \(oneRound.progressBar.frame.size.width)（= 屏宽 402 / 29 × 1）—— 这个「/ 29」是 updateUI() 里写死的，它和题库的真实条数是两条互不相干的事实")
var eqWidths: [CGFloat] = []
for _ in 0..<29 {
    eqWidths.append(oneRound.progressBar.frame.size.width)
    if oneRound.questionNumber < 28 { oneRound.answerPressed(oneRound.answerOneButton) } else { break }
}
line("  逐题的宽度：\(eqWidths.map { String(format: "%.2f", $0) }.joined(separator: " "))")
let eqFull = EQTestViewController(bank: QuestionBankEQ())
eqFull.loadViewIfNeeded()
for _ in 0..<28 { eqFull.answerPressed(eqFull.answerOneButton) }
expect(eqFull.questionNumber == 28 && abs(eqFull.progressBar.frame.size.width - 402.0) < 1e-9 && eqFull.progressLabel.text == "29 / 29",
       "答完 28 题、屏幕上正显示第 29 题（游标 \(eqFull.questionNumber)）的那一刻：宽度已经是 \(eqFull.progressBar.frame.size.width)（屏幕宽 402）、进度文字「\(eqFull.progressLabel.text ?? "nil")」—— 和 §14 那条一模一样的结论：满格出现在**还在显示最后一题**时，而不是最后一题答完之后。写 `questionNumber + 1` 的人顺手把它填成了「1-based」，进度条因此提前一格到头")
eqFull.answerPressed(eqFull.answerOneButton)
expect(eqFull.questionNumber == 29 && eqFull.resultAlert != nil,
       "第 29 题答完：游标 \(eqFull.questionNumber) —— `<= 28` 不再放行，走 else 分支造出结论弹窗（title=「\(eqFull.resultAlert?.title ?? "nil")」）。到这里 29 这道题的闭环是完整的，代价是**再点一次就崩**：answerPressed 里 `checkAnswer()` 读的是 `list[questionNumber]`，而它已经是 list.count —— 探针 r01 量过 13 题那一版的同一句话，29 题这一版一个字符都没变")
// —— 把题库换成 13 道，控制器一行不改 ——
let wrongCount = QuestionBankEQ(count: 13)
let mismatchVC = EQTestViewController(bank: wrongCount)
mismatchVC.loadViewIfNeeded()
for _ in 0..<12 { mismatchVC.answerPressed(mismatchVC.answerOneButton) }
expect(mismatchVC.questionNumber == 12 && mismatchVC.progressLabel.text == "13 / 29",
       "同一台控制器换上一份 13 道的题库、答满 12 题之后（游标 \(mismatchVC.questionNumber)，屏幕上正是它的最后一题）：进度文字写的是「\(mismatchVC.progressLabel.text ?? "nil")」—— 这个数字来自 updateUI() 里那处写死的 29，它和题库的真实条数是两条互不相干的事实，界面已经在报一个不存在的位置")
expect(12 + 1 <= 28 && wrongCount.list.count == 13,
       "而守卫看不见这件事：再答一次，游标推到 \(mismatchVC.questionNumber + 1)，`13 <= 28` 成立（\(13 <= 28)），于是 nextQuestion() 会去读 `list[13]` —— 这份题库的合法下标只到 \(wrongCount.list.count - 1)。这一撞本章不执行（`Fatal error: Index out of range`，原文见探针 r04），但它就是书 7.13 步骤 5 那句「我们只需将之前的13修改为29即可」的账单：那句话数下来是**三处**字面量（守卫里的 28、除法里的 29、label 里那个字符串），它们说的是同一件事（题库有几条），却写成三个互不相干的数，漏改任何一个都不报错")
expect(abs(mismatchVC.progressBar.frame.size.width - 402.0 / 29.0 * 13.0) < 1e-9,
       "同一时刻进度条宽度 \(mismatchVC.progressBar.frame.size.width)（= 402 / 29 × 13）—— 一份 13 道的题库在这里走到最后一题时只填到 \(String(format: "%.1f", mismatchVC.progressBar.frame.size.width / 402.0 * 100))%，永远到头不了。三处字面量的下场各不相同：守卫那一处（28）撞上越界，除法与 label 这两处（29）不报错、只是把 13 道题画成 13/29 和「13 / 29」—— 这就是「同一个意思写三遍」的代价，而 §31 的 QuestionSource 接口把这件事收成一个 `questionCount`")

// ============================================================
// §30 书 7.12：一份 Objective-C 的第三方库拖进 Swift 工程，两侧各看到什么
// ============================================================
section(30, "书 7.12 的 ProgressHUD：桥接头、方法名转换、nullability、单例、以及反方向那条桥")
// 这座桥在这份示例里只由两样东西搭成：目录里的 Bridging.h（内容就是书里那一行
// `#import "ProgressHUD.h"`），和 Needs-Swift-Header 这个空标记文件（它让 run-all.sh
// 给 swiftc 加 -emit-objc-header-path，产出 build/32_app_architecture/SwiftBridge-Swift.h，
// ProgressHUD.m 再 #import 那份产物）。Xcode 里那个「Would you like to configure an
// Objective-C bridging header?」对话框，在命令行这边就是这两样。
// 前面 29 节里每一台控制器答过的题都往同一本账上记了一笔，这里先把账清掉。
ProgressHUD.reset()
HUDSink.shared().clear()
let hudVC = QuizViewController()
hudVC.loadViewIfNeeded()
hudVC.answerPressed(hudVC.yesButton)   // 第 1 题「吃烧烤不能喝啤酒。」答案是真的 → 答对
hudVC.answerPressed(hudVC.yesButton)   // 第 2 题「喝白酒时最好喝茶水。」答案是假的 → 答错
// 头文件里那句 `NSArray` 没带元素类型，所以 Swift 接到的是 `[Any]`（外面还包着一层
// 隐式解析可选）。这一行**不能**写成 `let hudLines: [String] = ProgressHUD.history()`，
// 编译器原文交给探针 e09 —— 下面那一行同样的赋值在 ProgressHUDStrict 上就是合法的。
let hudLines: [Any] = ProgressHUD.history()
expect(hudLines.count == 2 && (hudLines[0] as? String) == "success：正确" && (hudLines[1] as? String) == "error：错误！",
       "书 7.12 改完之后，checkAnswer() 里那两行的效果读得回来：\(hudLines.count) 条、内容是「\(hudLines.compactMap { $0 as? String }.joined(separator: "」「"))」—— 上一节那条「Xcode 控制台只显示正确与否，最终用户看不到」的反馈，在这里第一次有了一个用户摸得着的出口（虽然这个进程里没有用户）。请注意每个元素都得过一次 `as? String`：那个 NSArray 没写元素类型，Swift 只能给 [Any]，类型信息在**头文件**那一侧就丢了")
ProgressHUDStrict.showSuccess("正确")
let strictLines: [String] = ProgressHUDStrict.history()
expect(strictLines.count == 1 && strictLines[0] == "success(严格)：正确",
       "同一件事在带 NS_ASSUME_NONNULL 的那个类上是另一种写法：\(strictLines.count) 条、第一条「\(strictLines[0])」，而且这一行**没有**任何 as? —— 头文件里写的是 `NSArray<NSString *> *`，Swift 直接给 `[String]`。两份实现走的是同一个 hud_record（.m 只有一个文件），差别全在头文件那几行声明上：桥这一侧拿到什么类型，是**头文件**决定的，不是 .m 决定的")
let hudSel = NSStringFromSelector(#selector(ProgressHUD.showSuccess(_:)))
expect(hudSel == "showSuccess:",
       "同一段代码在两种语言里是三个名字：OC 头文件里写 `+ (void)showSuccess:(NSString *)success`，Swift 里调 `ProgressHUD.showSuccess(_:)`，而运行时真正拿去查表的那个名字是「\(hudSel)」—— §21 那条「OC 的 @objc optional 是运行期查表」用的是同一张表（第 27 章量过它的代价：拼错不报错，只是没人应答）")
let hudA = ProgressHUD.shared()
let hudB = ProgressHUD.shared()
expect(hudA === hudB,
       "单例：两次 `shared()` 拿回来是**同一个**对象（=== 成立）—— 地址这种读不回的东西本章一律用同一性代替（§7 那条口径）")
expect(hudA.frame == UIScreen.main.bounds,
       "它自己的 frame 是 \(hudA.frame)（= UIScreen.main.bounds）—— 「铺满全屏」这一半是真的：书里那个 HUD 的几何确实建起来了")
expect(hudA.window == nil && hudA.superview == nil && !ProgressHUD.onScreen(),
       "可它的 window 和 superview 都是 \(String(describing: hudA.window))，`onScreen` 返回 \(ProgressHUD.onScreen()) —— 原库是靠 keyWindow 把自己加上去的，而这个进程里根本没有 window（§1 那句 UIApplication.shared == nil 的同一条根）。于是「HUD 弹出来了」这句话在这里被拆成两半：调用**全都成功**（history 一行不少），屏幕上**什么都没有**。这和 §24 那条 present 不生效、§17 那条 sendActions 不派发是同一条边界的三种长相")
ProgressHUD.showError(nil)
let afterNil = ProgressHUD.history().compactMap { $0 as? String }
expect(afterNil.count == 3 && afterNil[2] == "error：(nil)",
       "把 nil 递给那个 `_Null_unspecified` 参数，Swift 编译器一个字都没说（对照：同样的调用写在带 NS_ASSUME_NONNULL 的 ProgressHUDStrict 上是编译期错误，原文见探针 e08）；OC 那侧 hud_record 里有一句 `?:` 兜住了它，history 收下的是「\(afterNil[2])」。这就是「未声明 nullability」的真实含义：**nil 能不能进来不是由类型决定的，是由另一侧有没有防决定的**（探针 m02 量的是没防的那种 —— 同一个 nil 递到 NSMutableArray 的 addObject: 上是运行期异常，退出码 134 / SIGABRT，与 rNN 那几支的 132 / SIGILL 不是一类）")
let sunk = HUDSink.shared().allNotes()
expect(sunk.count == afterNil.count + 1 && sunk.last == afterNil.last && sunk.contains("success(严格)：正确"),
       "而 HUDSink 里读到了 \(sunk.count) 条、最后一条是「\(sunk.last ?? "nil")」—— 这一笔是 **OC 写进来的**：ProgressHUD.m 顶部 #import 那份 SwiftBridge-Swift.h，然后调 `[[HUDSink shared] note:]`。数目对不上是**故意的**，而且对不上的这一格本身就是结论：两个类各有一份 history，可 Sink 只有**一份**（loose 的 \(afterNil.count) 条 + 严格版那 1 条）。书 7.12 只搭了 Swift → OC 那半条桥，反方向这一半的条件写在 HUDBridge.swift 的类声明上：NSObject 子类 + @objc，缺任何一个，那个类根本不会出现在生成的头文件里（不是「调不到」，是「看不见」）")
expect(hudA.isKind(of: UIView.self) && ProgressHUD.superclass() == UIView.self,
       "这个类的 superclass 是「\(String(describing: ProgressHUD.superclass()))」，实例那句 `isKind(of: UIView.self)` 是 \(hudA.isKind(of: UIView.self)) —— 它自己就是一个 UIView 子类。现在回头看 §23 那条纪律：7.5 说「数据模型与视图永远不会直接发生联系」，而 7.12 之后 checkAnswer()（Controller）里直接写了一句 ProgressHUD.showSuccess —— 三层图在这里少的不是 M↔V 那条边，是 C 直接抓住了一个 V 的**类**，还是走全局单例的那种（没有可以塞替身的缝）")
line("  顺带一个坑：拿**类对象**去问 `ProgressHUD.isKind(of: UIView.self)` 读回来是 \(ProgressHUD.isKind(of: UIView.self))，和上面实例那一句相反 —— isKind 问的是「我这个对象是不是某个类的实例」，而类对象自己也是一颗对象，它属于 metaclass（第 27 章 isa 那一层）。这一句在混编代码里最容易顺手写错，而且它不报错，只是永远给你 false")
let hudVC2 = QuizViewController()
hudVC2.loadViewIfNeeded()
hudVC2.answerPressed(hudVC2.noButton)
expect(ProgressHUD.history().count == afterNil.count + 1,
       "换一个**全新的**控制器答一题，history 从 \(afterNil.count) 条走到 \(ProgressHUD.history().count) 条 —— 单例就是全局可变状态：两台控制器共用同一本账。这一条和 §20 的 NotificationCenter 是同一类耦合（都是「谁都不声明，谁都能写」），只是这一处更安静：连一个通知名都不用写")
line("  书 7.12 开头那句「你可能会遇到一些与这个库有关的黄色叹号警告……它们并不会影响应用程序的功能」在本仓库里恰恰是**硬失败**（判定 1 要求编译日志为空），可它的触发条件不是「头文件没标」：探针 m03 把**整份都不标**的那个类单独编一次，swiftc 日志为空、退出码 0，连那句 `record(nil)` 编译期都没人拦截。真正会响的是**标了一半**——m01 那份头文件里 `NS_ASSUME_NONNULL` 包了一个类，旁边没包的那个就被逐条点出 -Wnullability-completeness（原文交给 m01 现跑现抄）。第三种答案是本主线 ProgressHUD.h 的写法：宏一个不写，每个指针手着标 `_Null_unspecified` —— Swift 侧的类型和 m03 一样（还是隐式解析可选），日志也一样干净。「不影响功能」和「不许进来」这两种态度，差的就是构建脚本里那一行判定")

// ============================================================
// §31 兑现第三条断言：一个协议、两份 Model、同一台控制器
// ============================================================
section(31, "书 7.5 那句「换数据不用考虑其他代码」：一个协议、两份 Model、同一台控制器")
// SourceQuizViewController 与前面那两台控制器的差别只有一行：手里的 Model 是
// QuestionSource 这个协议，于是「一共有几道题」在整个类里只有一个来源。
Trace.reset()
let trueCount = bank.list.filter { $0.answer }.count
let src13 = SourceQuizViewController(source: QuestionBank())
src13.loadViewIfNeeded()
expect(src13.questionLabel.text == bank.list[0].questionText && src13.progressLabel.text == "1 / 13",
       "把 13 道判断题的库递进去：屏幕上「\(String(src13.questionLabel.text?.prefix(8) ?? ""))…」、进度文字「\(src13.progressLabel.text ?? "nil")」—— 那个「13」不是写死的，是从 source.questionCount 读回来的")
let src29 = SourceQuizViewController(source: QuestionBankEQ())
src29.loadViewIfNeeded()
expect(src29.progressLabel.text == "1 / 29" && src29.questionLabel.text == "我有能力克服各种困难。",
       "换一份 29 道题的 EQ 库、**同一个类**再造一个实例：进度文字「\(src29.progressLabel.text ?? "nil")」、第 1 题「\(src29.questionLabel.text ?? "nil")」—— 控制器那边一个字都不用改，两份 Model 各自的题数、选项个数、计分规则全在协议后面")
expect(String(describing: type(of: src13)) == String(describing: type(of: src29)),
       "「一行没改」的判据不是我说没改：两个实例的运行时类型是同一个「\(String(describing: type(of: src13)))」，只有构造参数不同。书里为这件事写了两个 ViewController（7.6 的 Quizzler 与 7.13 的 EQTest），在这里它们合并成一个类型加两份 Model —— 这就是 §29 那三处字面量的对偶")
for _ in 0..<13 { src13.answer(option: 0) }
for _ in 0..<29 { src29.answer(option: 0) }
expect(src13.finishedScore == trueCount && src13.questionNumber == 13,
       "全答第一档跑完：判断题那边游标 \(src13.questionNumber)、分数 \(src13.finishedScore) —— 这份库里有 \(trueCount) 道题的正确答案是「是」，所以全答第一档就得 \(trueCount) 分。换算写在 QuestionBank 的 score(at:option:) 里（「答对给 1 分」），协议这一侧只管要一个数")
expect(src29.finishedScore == 174 && src29.questionNumber == 29,
       "EQ 那边游标 \(src29.questionNumber)、分数 \(src29.finishedScore)（每题第一档 6 分 × 29）—— 同一个 answer(option:) 调用、同一台控制器，两份 Model 各自的计分规则互不知道对方存在。§26 那句「154 还是 174」的账在这台上也不用改代码：它读的就是 Model 给的数")
Trace.reset()
src13.answer(option: 0)
expect(src13.questionNumber == 13 && Trace.log == ["已经答完，这一次点空了：游标 13"],
       "答完**再点一次**：§29 那一撞（`list[13]` 越界）在这里没有发生 —— answer() 开头那句 guard 问的是 questionCount，于是这一笔落在 Trace 上（\(Trace.log.count) 条：「\(Trace.log.first ?? "nil")」），游标和分数都停在原位。把「有几道题」收成一个数据源，代码路径上就多出来这一条边：越界从一个运行期崩溃变成一次可以被记录的无操作")
let mixedForSource = QuestionBankEQ(mixedCount: 29)
let srcMixed = SourceQuizViewController(source: mixedForSource)
srcMixed.loadViewIfNeeded()
for n in 0..<29 { srcMixed.answer(option: n % 2) }
// 期望值不在这里手算：把这份题库自己的分值加起来，用同一份数据算第二遍。
let expectedMixed = (0..<29).reduce(0) { $0 + mixedForSource.list[$1].questionScore[$1 % 2] }
expect(srcMixed.questionNumber == 29 && srcMixed.finishedScore == expectedMixed,
       "第三份 Model（§28 那盘二选一/三选一混排，这里只答前两档）也照样跑得完：游标 \(srcMixed.questionNumber)、分数 \(srcMixed.finishedScore)（这份库自己的分值累加出来是 \(expectedMixed)）—— §28 那一撞（隐藏按钮的 tag 对着只有两档的题）在这台控制器上不会发生，因为下标是它自己传进去的，不是从 Inspector 上读来的。**注意这不是「协议消灭了 bug」**，它消灭的是「控制器和界面各自猜一个数字」这一类 bug")
line("")
line("== 本章开头那三句话，现在的账目 ==")
line("  1) **Model 不认识 UIKit** —— §1 的证据：整章跑完 UIApplication.shared 都是 nil，而 13 道题、29 道题、四种结论区间、三台控制器全部走完；Question.swift 和 QuestionBank.swift 这两个文件里连 UIView 这个名字都没出现过（只有 import Foundation）")
line("  2) **视图不会自己动** —— §12/§18 的证据：改 Model 的那个 var，屏幕上一个字都没变；界面唯一的入口是控制器那句 updateUI()，而它被叫到几次是数得出来的（§18 那一本账）")
line("  3) **换掉 Model 而控制器一行不改** —— §31 就是它，§29 是它的反例：同一件事（题库有几条）写成三处字面量，换 Model 就得改三处，漏一处要么崩要么骗人")
line("  三句话里第三句最脆。它成立的条件不是「项目用了 MVC 这个说法」，而是「**同一个意思只有一个来源**」—— 这一条在 7.13 那份代码里没做到，在 7.5 那句话里也没说，本章把它换成两个数字：§29 里三处字面量、§31 里一个 questionCount")
line("  本章没做到的事（记在这里，别让它们看起来像已经验证过）：真实触摸的派发（§17 量的 sendActions 不派发）、present 出来的窗口（§24）、故事板与 xib 的装配（第 31 章）、图层渲染和动画时序、以及由 UIApplication/NSRunLoop 驱动的完整生命周期。这一半只能上真机或模拟器 GUI，命令行产物里给不出对应证据")

line("")
if failures == 0 {
    line("全部断言通过。")
} else {
    line("有 \(failures) 条断言失败。")
}
print("==== 32 结束 ====")
exit(failures == 0 ? 0 : 1)
