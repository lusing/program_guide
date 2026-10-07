# 32 · 应用架构：MVC 三层里，状态到底住在谁的哪一次赋值里

> 示例：`examples/32_app_architecture/main.swift`（同级 `Question.swift`、`QuestionBank.swift`、`QuizViewController.swift`、`EQTestViewController.swift`、`Presenter.swift`、`SourceQuizViewController.swift`、`HUDBridge.swift`，混编三件 `Bridging.h` / `ProgressHUD.h` / `ProgressHUD.m` 加一个空标记 `Needs-Swift-Header`，以及 `probes/` 18 支探针 + `run.sh`）
> 实测输出见 `build/32_app_architecture/stdout.debug.txt`

《跟着项目学iOS应用开发：基于Swift 4》的第 7 章是全书**第一处谈「架构」**的地方，也是它
第一次给出一个完整的 App：「使用 Model-View-Controller 设计模式制作小测验 App」。它要交付
的东西很具体，本章一节一节照着走：

- **7.2** Model 层的第一个文件 `Question.swift`：一个 `class`、两个 `let`、一个
  `init(text:correctAnswer:)`，并且专门解释了一句「为什么这里 import 的是 Foundation
  而不是 UIKit」；
- **7.4** Model 层的第二个文件 `QuestionBank.swift`：一个 `var list = [Question]()`
  加一个往里 `append` 十三道判断题的 `init()`；
- **7.5** 三段讲「谁是 M、谁是 V、谁是 C」，结论是那句被反复引用的
  **「数据模型与视图永远不会直接发生联系……如果项目在法国运行，可以把数据从英文换成
  法文而不用考虑其他代码」**；
- **7.6~7.11** Controller 里那台状态机：`questionNumber` / `pickedAnswer` / `score`
  三个属性，`answerPressed(_:)` → `checkAnswer()` → `questionNumber += 1` →
  `nextQuestion()` → `updateUI()`，四节里一节长一样东西；
- **7.12** 把一个 Objective-C 写的第三方库（ProgressHUD）拖进 Swift 工程；
- **7.13** 「挑战：制作情商测试应用」——同一套骨架换一份 Model，29 道题、选项个数不固定、
  按分数区间给四种结论。

原书的判据从头到尾是同一类：**「构建并运行项目，如图 7-xx 所示」**。连上了就显示，
答完了就弹框，而它明写在正文里的三个 bug（7.7 越界崩、7.9 重做后丢一题、7.11 类型不匹配）
也全部要跑起来、盯着屏幕才看得见。

本教程的产物是一个**裸可执行文件**：`swiftc` 编一次，`xcrun simctl spawn` 在 iPhone
模拟器里跑一遍，六条判定卡住（见 `run-all.sh` 头部与 `README.md`：编译日志为空、退出码 0、
stderr 为空、stdout 非空、无多余控制字符、结尾标记 `==== 32 结束 ====`，外加 debug(-Onone)
与 release(-O) 两份 stdout 逐字节一致）。所以「跑起来看一眼」在这里必须换成一句句能打印、
能断言的话，而「会崩 / 编译器会红一条」的写法天生进不了主线（判定 1/2/3 直接把它抓住），
改由 `probes/` 现跑并抄原文。

## 这一章的换法（每条都有实测支撑，逐节展开）

下面每一条都是「书里怎么说」对「本机 Swift 6.0.3 + Xcode 16.2 + iOS 18.2 模拟器上实际是
什么」。其中有四条是**探针跑下来发现本章初稿或书里的解释与编译器实际给的不一致**，它们就地
写在对应小节，改成了实测的写法：

- 书 7.2「第一个版本会报错，如图 7-8」：**红点不在你预期的那一行**。编译器先指着**类声明**
  说 `class 'Question' has no initializers`，再在两行属性上各补一句 note，最后才在构造处
  说 `cannot be constructed because it has no accessible initializers`。原因写在类型上，
  症状写在调用处（§2，原文见探针 e01）；
- 书 7.11「在乘号（\*）的两侧不能一边是单精度值，一边却是整型值」：**本机的编译器把光标
  放在除号上**，给的消息是
  `referencing operator function '/' on 'DurationProtocol' requires that 'CGFloat' conform to
  'DurationProtocol'` —— 一个和进度条毫无关系的协议。真正对应「一单一整」的是同一支探针里
  那个最小样本 `CGFloat * Int`（§15，原文见探针 e05）；
- 「纯 Swift 属性不能挂 KVO，编译器会拒绝」：**不拒绝**。e06 抄到的是一条 warning、编译退出码
  0；真正的拒绝在运行时 —— `observe(\.score)` 走到注册那一句当场 trap
  （`Could not extract a String from KeyPath \PlainQuiz.score`，退出码 132，探针 r05）。
  这条限制不是编译期给的，是运行时给的（§19）；
- 书 7.9「因为闭包有其独立的生存期……所以在闭包之中需要使用 self 关键字」：这句话讲的是
  **编译器为什么要求你写 self**，而它顺手埋下的是引用环 —— 强捕获那一版函数返回之后对象
  照样活着，换成 `[weak quiz]` 才释放干净（§22 两条断言，配合 §25 那个三方环与探针 c01）。

另有三处是「原书那句判据在这个工具链上根本给不出」的换法：

- 书 7.8 的判据是**在 lldb 里敲 `print allQuestions.list`**，它给出 13 行、每行前面带一个
  指针地址。地址不能进本章的输出（两个进程各自分配，debug 与 release 一比就裂），换成三条
  不依赖地址的问法：几个元素、几个**互不相同**的对象、顺序是不是 `append` 的顺序（§4）；
- 书 7.9/7.13 的「弹出一个警告窗口」：`present` 在没有窗口的进程里**不生效**（第 22 章量过），
  于是本章判的是弹窗的**内容** —— `title` / `message` / `preferredStyle` / `actions.count`
  四个字段逐个读回，文案逐字对书（§24）。而「用户点了那颗按钮」更读不回来：
  `handler` 不是 `UIAlertAction` 的公开属性（探针 e07），所以控制器在造按钮**之前**先把那段
  闭包存了一份，递出去的和存下的是同一个值 —— 调它 = 点那颗按钮（§25）；
- 书 7.12「你可能会遇到一些与这个库有关的黄色叹号警告……它们并不会影响应用程序的功能」：
  这句话在本仓库里恰恰是**硬失败**，判定 1 要求编译日志为空。而它的触发条件不是「没标」：
  m01 现跑现抄的那条 `-Wnullability-completeness` 只在**标了一半**的头文件上响，
  m03 把标了的那一半整个去掉，swiftc 日志为空、退出码 0。也就是说三种态度各自成文时
  （整份不标 / `NS_ASSUME_NONNULL` 全套 / 逐个指针手着标 `_Null_unspecified`）都安静，
  **响的是把它们混进同一份文件**；而它们在 Swift 侧给出的类型两两相同（§30）。

## 本章的账本结构

```
前提   §1  Model 层不碰 UIKit：UIApplication.shared == nil 的进程里能走多远
Model  §2  class Question 的三段形状：无 init / 有默认值 / 有 init
Model  §3  两阶段初始化的运行时那一半：init 里的赋值，didSet 一次都不跑
Model  §4  十三道题的出厂清点：顺序就是题号（lldb 那一屏的等价物）
分层   §5  状态的主人只能有一个：游标住 Controller 与住 Model 差多少
分层   §6  值语义与引用语义在 Model 层的分岔：改一次影响谁
分层   §7  书 7.6 那四行属性：let 锁的是引用，不是里面的数据
状态机 §8  list[13] 的下场：崩溃进探针，守卫的等价性留在这里量
状态机 §9  `<= 12` 里那个 12 是从题库长度**抄**来的
状态机 §10 progressLabel 那句 `"\(questionNumber + 1) / 13"`：两套编号撞车
状态机 §11 「重置 questionNumber 却不更新界面」：书里明写的那个 bug
状态机 §12 书 7.5 那句「模型与视图永不直接发生联系」的可执行版
几何   §13 loadViewIfNeeded 给的那块 view：没有窗口时「屏幕宽度」是什么
几何   §14 progressBar 宽度全表：满格发生在哪一刻
几何   §15 CGFloat 与 Int 的混算：编译器原文进探针，能算的账留在这儿
接线   §16 `pickedAnswer = sender.tag - 1`：按钮的身份是一个可填错的整数
接线   §17 sendActions 在这条路上过不去，所以本章直调方法
通知   §18 第 1 种·手动：一次点击到底改了几处界面
通知   §19 第 2 种·KVO：观察者是注册上去的
通知   §20 第 3 种·NotificationCenter：post 是同步的
通知   §21 第 4 种·代理：谁持有谁写在两行声明里
通知   §22 第 5 种·闭包：代价是它连对象一起存
边界   §23 分层是纪律不是机制：KVC 从任意方向把墙捅穿
弹窗   §24 把「警告窗口」换成可读的对象：四个字段
弹窗   §25 handler 读不回来，所以本章存了一份闭包 + 一个三方环
7.13   §26 第二条产品线：两个数组、tag 减一、「最大 EQ 为 154 分」这句话
7.13   §27 四个 else if 之间的缝：其中一格没人接
7.13   §28 二选一与三选一混排：那段 enumerated() 循环的三颗按钮
7.13   §29 「只需将之前的 13 修改为 29」—— 那个「只需」值多少
7.12   §30 ProgressHUD：桥接头、方法名转换、nullability、单例、反方向那条桥
兑现   §31 一个协议、两份 Model、同一台控制器
```

## 复现

```bash
cd iosdev
./run-all.sh 32_app_architecture                       # 主线：两配置编译 + 模拟器跑 + 六条判定 + 逐字节比对
bash examples/32_app_architecture/probes/run.sh        # 全部 18 支探针
bash examples/32_app_architecture/probes/run.sh e05 r03 # 只跑编号前缀匹配的
```

`probes/run.sh` 的四支族分工写在其头部注释里，本文末尾「探针记录」逐支抄了原文：

- `eNN_*` Swift 编译期诊断 —— 只看 `swiftc` 说了什么，不运行；
- `rNN_*` 运行期现场 —— 编好放进模拟器跑，抄 stdout / stderr / 退出码 / 崩溃原文；
- `cNN_*` 配置对照 —— 同一份源码 `-Onone` 与 `-O` 各编各跑，逐格比对两份输出**是否一致**；
- `mNN_*` 混编 —— 同名 `.h` 当桥接头、同名 `.m` 一起交给 `swiftc`（驱动会替它调 clang 并链接）。

三处脚本层面的细节，都是本章实测踩出来的：

1. **每支探针的 `.swift` 都要先复制成 `main.swift` 才允许顶层语句**。直接
   `swiftc e01_uninitialized_let.swift` 报的是 `expressions are not allowed at the top level`，
   和这一节要量的东西毫无关系；
2. **`-module-name` 与主线一致**（都是 `app_architecture`）。混编那一族尤其要紧：
   `ProgressHUD.m` 里 `#import` 的那份生成头必须和主线生成的是同一套符号；
3. **`eNN` 是两趟编译**。`run.sh` 先给 `-typecheck`，被放过的再走完整代码生成 —— 这不是图快：
   definite-initialization 那一类诊断（e04 的「`self` 被闭包抓住时成员还没初始化完」）
   **只在真正发射函数时**才打印，`-typecheck` 一声不吭。这一条本身就是本章 §3 的姊妹结论。

主线里的混编段也是两条开关凑出来的：示例目录里放一个 `Bridging.h`，`run-all.sh` 就给
`swiftc` 传 `-import-objc-header`（这就是书 7.12 那个「Create Bridging Header」对话框生成的
文件，内容只有书里那一行 `#import "ProgressHUD.h"`）；再放一个**空文件** `Needs-Swift-Header`，
脚本就额外传 `-emit-objc-header-path`，产出 `build/32_app_architecture/SwiftBridge-Swift.h`
给 `ProgressHUD.m` 去 `#import`。Xcode 里这两件事都是自动的，命令行这边只有这两个文件名。

---

## §1 Model 层不碰 UIKit：书 7.2 那句「Foundation 比 UIKit 轻很多」的运行时落点

书 7.2 结尾用一整段解释「为什么 `Question.swift` 里 import 的是 Foundation 而不是 UIKit」，
结论是「要根据需求来选择导入的框架库」。这句话在原书里没有判据 —— 它是个风格建议。本章把它
换成一个可跑的事实：**Model 层的 13 道题、整台答题状态机、计分与越界处理，全程在一个没有窗口、
没有共享应用对象、没有 runloop 的进程里跑完**。

先确认这个前提是真的（第 31 章 §16 量过同一条根）：

```swift
let app: UIApplication? = UIApplication.shared
expect(app == nil,
       "这是一个裸可执行文件：\(String(describing: app)) —— 没有共享应用对象、没有窗口、没有 runloop。…")
let bank = QuestionBank()
expect(bank.list.count == 13, "书 7.4 的 QuestionBank 只有两样东西：… —— 实际数量 \(bank.list.count)")
var seenTrue = 0
for q in bank.list where q.answer { seenTrue += 1 }
expect(seenTrue == 6, "十三道判断题里答案成立的是 \(seenTrue) 道、不成立的是 \(bank.list.count - seenTrue) 道（Model 层一次读回，全程没碰 UIView）")
```

```
== §1 Model 层不碰 UIKit：书 7.2 那句「Foundation 比 UIKit 轻很多」的运行时落点 ==
  ok   这是一个裸可执行文件：nil —— 没有共享应用对象、没有窗口、没有 runloop。下面每一条 Model 与状态机的断言，都发生在这种进程里
  ok   书 7.4 的 QuestionBank 只有两样东西：var list = [Question]() 和一个往里面 append 十三道题的 init() —— 实际数量 13
  ok   十三道判断题里答案成立的是 6 道、不成立的是 7 道（Model 层一次读回，全程没碰 UIView）
  ok   首题「吃烧烤不能喝啤酒。」与末题「进行人工呼吸前，…」逐字对得上书 7.4 的 append 次序 —— 数组是有序的，这就是 §4 那条「顺序即题号」的依据
```

逐条展开：

- **`UIApplication.shared` 在这个进程里就是 `nil`**。这不是「取不到所以放弃」，而是本章要的
  那个前提本身：`Question.swift` 与 `QuestionBank.swift` 这两个文件里连 `UIView` 这个名字都没
  出现过（只有 `import Foundation`），所以它们在这种进程里被完整使用不构成任何依赖缺口。
  「Foundation 比 UIKit 轻很多」这句话的运行时落点就是这个：**轻不轻，看它能不能在没有应用
  环境的进程里跑完**；
- **`bank.list.count == 13`**。书 7.4 那个类只有两样东西，而这两样就足够把「数据模型负责构建
  和管理数据」兑现：`var list = [Question]()` 是「管理」，`init()` 里那十三行 `append` 是
  「构建」。注意这一节一次都没有构造 `UILabel`；
- **6 真 / 7 假**是把 Model 当成**可读的数据**问出来的第一个问题 —— 在原书里这个数字要等你把
  十三道题一道道答完、看分数 label 才知道；这里一次读回。这条口径后面 §31 还要用（那台控制器
  全答第一档得 6 分，就是因为这个数是 6）；
- **首题与末题逐字对得上**。`bank.list[0].questionText == "吃烧烤不能喝啤酒。"`、
  `bank.list[12].questionText.hasPrefix("进行人工呼吸前")`。数组是有序的，这是硬保证，
  也是 §4「顺序即题号」和 §8「敢只用一个整数当游标」的全部依据。

这一节后面再也没有单独检查过 `UIApplication.shared`，但整章 31 节的断言都发生在这个前提下。
文档末尾那三条「本章没做到的事」（真实触摸的派发、present 出来的窗口、由 runloop 驱动的完整
生命周期）根源都在这里。

## §2 class Question 的三段形状：书里那一格「报错」到底报在哪

书 7.2 依次给了三个版本，并说第一个「会报错，如图 7-8」。三个版本的代码都在
`Question.swift` 里躺着（第一个不能编译，所以它在探针 e01 里）：

```swift
// 版本一（探针 e01）：两个 let 都没有初值，也没有 init
class Question {
    let questionText: String
    let answer: Bool
}
let q = Question()          // ← 原书说「红点在这一行」

// 版本二（主线里的 QuestionWithDefault）：把默认值写进属性
final class QuestionWithDefault {
    let questionText: String = "你还是你吗？"
    let answer: Bool = true
}

// 版本三（主线里的 Question，书 7.2 的最终形态）：init 传参
class Question {
    let questionText: String
    let answer: Bool
    init(text: String, correctAnswer: Bool) {
        questionText = text
        answer = correctAnswer
    }
}
```

探针 e01 跑下来，原文与「红点在构造那一行」的直觉**相反**：

```
/var/folders/.../main.swift:15:7: error: class 'Question' has no initializers
15 | class Question {
   |       `- error: class 'Question' has no initializers
16 |     let questionText: String
   |         `- note: stored property 'questionText' without initial value prevents synthesized initializers
17 |     let answer: Bool
   |         `- note: stored property 'answer' without initial value prevents synthesized initializers

/var/folders/.../main.swift:21:9: error: 'Question' cannot be constructed because it has no accessible initializers
21 | let q = Question()
   |         `- error: 'Question' cannot be constructed because it has no accessible initializers
```

两句是同一件事的两半：**原因写在类型上，症状写在调用处**。排查时先读哪一句，决定了人是去改
属性（补默认值 / 写 init）还是去改调用（换个构造方式）。原书只说「会报错」，这一条在本章是
实测出来的两句。

主线量的是版本二与版本三的**运行后果**：

```swift
let bookShape = Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
expect(bookShape.questionText == "吃烧烤不能喝啤酒。" && bookShape.answer, "…")
let defaulted = QuestionWithDefault()
let another = QuestionWithDefault()
expect(defaulted.questionText == another.questionText && defaulted.answer == another.answer,
       "书 7.2 中间那步（把默认值写进属性）编译得过，但两个实例一字不差：…")
expect(Question(text: "甲", correctAnswer: true).questionText != Question(text: "乙", correctAnswer: true).questionText,
       "换成 init 传参之后，两个实例第一次可以不一样 —— …")
```

```
== §2 class Question 的三段形状：无 init、有默认值、有 init（书 7.2 的三步） ==
  ok   书 7.2 的最终形态（两个 let + init(text:correctAnswer:)）造出来的对象，两个属性都读得回来："吃烧烤不能喝啤酒。" / true
  ok   书 7.2 中间那步（把默认值写进属性）编译得过，但两个实例一字不差："你还是你吗？" / true —— 值定在**类型**上而不是**对象**上，所以这条走不通
  ok   换成 init 传参之后，两个实例第一次可以不一样 —— 这就是「数据模型负责构建和管理数据」这句话在代码里的最小落点
```

- **版本二「编译得过但等于没写」**，这是本章对书里那三步最实的一条读数。把默认值写进属性之后
  报错确实消失了，可那个值是定在**类型**上的：造两个对象，`questionText` 与 `answer` 一字不差。
  十三道题需要一个数组装十三个不同的对象，这一步走不通，所以 7.4 才要那个 `init()`；
- **版本三的价值只有一句**：`Question(text: "甲", …)` 与 `Question(text: "乙", …)` 第一次可以
  不一样。「数据模型负责构建和管理数据」这句听起来像口号的话，在代码里的最小落点就是
  「每个对象能带自己的值进来」；
- 顺带一条 §3 要用、e03 抄了原文的边界：这两个属性是 `let`，于是**它们既不能改、也挂不了
  观察者**（`'let' declarations cannot be observing properties`）。书里选 `let` 是对的
  （判断题的答案不该被改），但「不改它、只看着它」这条路同时被关上了 —— 这就是本章为什么要
  另外造一个 `MutableQuestion`。

## §3 两阶段初始化的运行时那一半：init 里那两次赋值，didSet 一次都不跑

书 7.2 只说「属性都赋完值才不报错」。这条规矩还带出一个架构后果：给 Model 的属性挂观察
（`didSet` / `willSet` / KVO）时，**构造阶段的那几次写入不会被当作变化**。

```swift
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
        questionText = text      // ← 这两句都赋了值
        answer = correctAnswer
    }
}
```

```
== §3 两阶段初始化的运行时那一半：init 里那两次赋值，didSet 一次都不跑 ==
  ok   init 里确实赋了两个属性，可 didSet 的计数是 0 —— Swift 规定初始化阶段的写入不走观察者
  ok   构造完成之后再改，两次都记上了（2）—— 观察者的有效区间是从 init 结束那一刻开始的
  ok   属性本身是可变的（var），改完读回来是新值；对照 §2 那两个 let：同一个 Model，可变性来自声明用 let 还是 var（而「常量上根本挂不了观察者」是编译器的原话，见探针 e03 —— MutableQuestion 这个类是被那条限制逼出来的）
```

三条读数各自管一件事：

1. **`mutations == 0`**：`init` 里那两次赋值真实发生了（属性有值），可观察者一次都没被叫到。
   「所以给 Model 挂 KVO / `didSet`，然后指望它抓到初始值」的写法一律抓空 —— §19 的 KVO
   断言里会**再看到同一个现象**（注册之后命中 0 次，因为出厂那次 `score = 0` 在 `init` 里）；
2. **改两次记两次**：观察者的有效区间是从 `init` 结束那一刻开始的。这条界线在架构上的意义是
   「**出厂状态不算一次变更**」，凡是在 UI 上「进入界面就 +1」之类的 bug，根都在这里；
3. **可变性来自声明**：`let` 与 `var` 决定「能不能改」，也决定「能不能被看着」。编译器那句
   原话（`'let' declarations cannot be observing properties`）在这里是**结构性**的限制，
   它逼出了 `MutableQuestion` 这个类。而想绕过它、在 `init` 里就把 `self` 交给观察者，
   编译器同样不放过（探针 e04：`'self' captured by a closure before all members were
   initialized`，并补一句 note `'self.answer' not initialized`）。

e04 这一支还顺手证明了「本章为什么必须用两趟编译问探针」：那条诊断**只在发射函数那一路才打印**，
`-typecheck` 一声不吭。探针记录里它的第一行就是
`（-typecheck 一声不吭：再用完整编译问一遍）`。

## §4 十三道题的出厂清点：顺序就是题号，而 lldb 那一屏为什么搬不过来

书 7.8 的判据是在 lldb 里敲 `print allQuestions.list`，它给出 13 行，每行前面是一个指针地址
（`0x000060c00045e5a0` 之类）。**地址不能进本章的输出**：两个进程各自分配，debug 与 release
那份逐字节比对当场就裂。所以这里换成三条不依赖地址的问法。

```swift
let mirroredChildren = Mirror(reflecting: bank.list).children.count
expect(mirroredChildren == 13, "Mirror 数出来 \(mirroredChildren) 个元素 —— …")
let identityCount = Set(bank.list.map { ObjectIdentifier($0) }).count
expect(identityCount == 13, "十三个元素两两不是同一个对象（去重之后还是 \(identityCount) 个）—— …")
expect(bank.list[0] === bank.list[0] && bank.list[0] !== bank.list[1], "`===` 问的是身份：…")
var orderKept = true
for (index, question) in bank.list.enumerated() where question !== bank.list[index] { orderKept = false }
expect(orderKept, "enumerated() 给出的 (下标, 元素) 与直接按下标取一致 —— …")
```

```
== §4 十三道题的出厂清点：顺序就是题号，而 lldb 那一屏为什么搬不过来 ==
  ok   Mirror 数出来 13 个元素 —— 这是 lldb 那一屏的「[0] … [12]」在当前进程里的等价物（它连每行前面那个地址一起给，而地址每次都换）
  ok   十三个元素两两不是同一个对象（去重之后还是 13 个）—— 7.4 那句「创建十三个 Question 对象」的「对象」二字，量的就是这个
  ok   `===` 问的是身份：同一个下标两次取回同一个对象，不同下标取回不同对象 —— 题号（下标）与题目（对象）是一对一绑死的，这就是 §8 那台状态机敢只用一个整数当游标的全部依据
  ok   enumerated() 给出的 (下标, 元素) 与直接按下标取一致 —— 数组是有序的，书 7.6 那句「[0] 是第一题、[1] 是第二题」在 Swift 的 Array 里是硬保证（Dictionary 就没有，第 30 章量过它每次进程换遍历顺序）
```

- **为什么用 `ObjectIdentifier` 而不是打印地址**：`Set(bank.list.map { ObjectIdentifier($0) }).count`
  给出 13，说的是「十三个元素是十三个**互不相同**的对象」。这正是 7.4 那十三行 `append` 里
  「对象」二字的含义 —— 如果 `Question` 是 `struct`，这个集合会退化成「十三个值相等的元素」，
  `===` 根本编译不过（§6 量值语义那一版时用的是另一套断言）；
- **`===` 那一句看着像废话，其实是 §8 的地基**：`list[0] === list[0]` 为真、
  `list[0] !== list[1]` 为真，说明「下标」和「那道题」是一对一绑死的。整台状态机只用一个
  `Int` 当游标，靠的就是这条：`questionNumber` 是唯一身份，不需要另外记「当前是哪道题」；
- **`enumerated()` 与按下标取一致**这条是 Swift `Array` 的硬保证，也正是本章后面所有
  「用下标当题号」的写法成立的前提。对照组在第 30 章：`Dictionary` 每次进程换遍历顺序，
  所以那种容器里**不能**用「第几个」当身份；
- **地址为什么搬不过来**：lldb 那一屏的信息量其实只有「有几个、顺序是什么」，
  地址是它的副产品。本仓库的判定 6（两配置逐字节一致）把这个副产品变成毒药，所以本章
  用身份（`===` / `ObjectIdentifier`）代替地址 —— 这条口径在 §30 的单例断言上再用一次。

## §5 状态的主人只能有一个：游标住在 Controller（书写法）与住在 Model（常见写法）差多少

书 7.4 的 `QuestionBank` 里**没有游标**，推进它的是 ViewController 的 `questionNumber`（7.7
加的）。市面上同一套课的另一半实现把游标放进了 Model（`bank.getNextQuestion()` 自己推进）。
两种单独都自洽；**混在一起**（Model 会推、Controller 也推）就是本章最容易写错的那类架构 bug。
`QuestionBankWithCursor` 就是那个「另一半写法」：

```swift
final class QuestionBankWithCursor {
    var list = [Question]()
    var questionNumber = 0

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
```

同一份三题的题库跑两遍，用户每次都答对**屏幕上那一题**：

```swift
// 设计 A：书里的样子 —— Model 只有数据，游标在控制器手上。
for _ in 0..<three.count {
    let shownIndex = cursorA                              // 屏幕上的是这一题
    let pick = three[shownIndex].answer                    // 用户看着它答，答对了
    pairsA.append("屏幕\(shownIndex)/判卷\(cursorA)")
    if pick == three[cursorA].answer { scoreA += 1 }        // checkAnswer 读 questionNumber
    cursorA += 1                                           // answerPressed 里那句 += 1
}
// 设计 B：bank 自己推进（getNextQuestion 推一次），控制器照抄另一份教程又 += 1。
for _ in 0..<three.count {
    let shown = bankB.getNextQuestion()                     // 返回当前题，游标 +1
    let shownIndex = three.firstIndex { $0 === shown } ?? -1
    let checkedIndex = bankB.questionNumber                 // checkAnswer 读的是**推进之后**的游标
    pairsB.append("屏幕\(shownIndex)/判卷\(checkedIndex)")
    if bankB.checkAnswer(userAnswer: shown.answer) { scoreB += 1 }
}
```

```
== §5 状态的主人只能有一个：游标住在 Controller（书写法）与住在 Model（常见写法）差多少 ==
  ok   设计 A（游标只有一个主人）：三题全答对，得分 3
  ok   而且「屏幕上那一题」与「判卷时读的那一题」每一轮都是同一题（屏幕0/判卷0 屏幕1/判卷1 屏幕2/判卷2）—— 这就是单一数据源的样子
  ok   设计 B（游标有两个主人）：用户同样每答必对屏幕上那一题，得分却是 1 —— 每判一题都看的是**下一题**的答案
  ok   错位是成体系的（屏幕0/判卷1 屏幕1/判卷2 屏幕2/判卷0）：最后一题被拿去和第一题比。书 7.5 说「控制器负责数据模型与视图之间的沟通」，这句话的工程含义是**沟通的中间人只能有一个**，否则同一份数据会被两条路各推一次
```

这一节是全章最「架构」的一条，值得把 B 的那三对数字读透：

- **A 的得分是 3、B 的得分是 1**，而用户的行为在两边**一模一样**（每次都答对屏幕上那道题）。
  分数不是被用户答掉的，是被「谁推进游标」这件事吃掉的；
- **B 的错位是成体系的**：`屏幕0/判卷1`、`屏幕1/判卷2`、`屏幕2/判卷0`。前两轮判的是**下一题**
  的答案，最后一题被拿去和第一题比（因为 `getNextQuestion` 在最后一题把游标绕回 0）。
  这不是随机错误，是一个偏移量为 1 的**系统**错位 —— 现场表现为「我明明答对了怎么不给分」，
  而且答错反而给分；
- 这个形状和 §11 那个正文 bug（判卷与屏幕错开一题）、§28 那个隐藏按钮的下标错位，
  都是**同一类 bug 的三个实例**：同一份数据被两条路各推一次，或者两条路读的不是同一格。
  书 7.5 那句「控制器负责数据模型与视图之间的沟通」的工程含义就在这里 ——
  **沟通的中间人只能有一个**；
- 值得注意的是 A 与 B 都是「能跑的代码」。`QuestionBankWithCursor` 单独用完全自洽
  （它就是那套课原版的写法），错的不是它，是**同时**存在两个推进者。这一条无法靠类型系统
  检查出来，只能靠「谁拥有这个状态」的约定 —— §31 那个协议是它唯一可执行的解法。

## §6 值语义与引用语义在 Model 层的分岔：同一份题库，两种「改一次影响谁」

书 7.2 直接选了 `class`，7.3 那节给的理由是「面向对象」。但 `Question` 只有两个只读字段，
`struct` 完全够用 —— 差别不在能不能跑，而在下面这五条断言。

```swift
var copiedList = bank.list
copiedList.removeAll()                      // 拷一份题库再清空
let firstFromCopy = bank.list[0]
var valueList = [QuestionValue(text: "甲", correctAnswer: true), QuestionValue(text: "乙", correctAnswer: false)]
var valueCopy = valueList
valueCopy[0] = QuestionValue(text: "甲改", correctAnswer: false)   // struct 版：改副本里的元素

func bump(_ counter: ValueCounter) -> ValueCounter { var c = counter; c.n += 1; return c }
var byValue = ValueCounter()
byValue = bump(byValue)                      // struct：必须把改完的那份接回来

func bumpReference(_ quiz: QuizViewController) { quiz.questionNumber += 1 }
let referenceProbe = QuizViewController()
bumpReference(referenceProbe)
bumpReference(referenceProbe)                // class：不用接回来
```

```
== §6 值语义与引用语义在 Model 层的分岔：同一份题库，两种「改一次影响谁」 ==
  ok   数组本身是**值**：拷一份再清空，原题库还是 13 道 —— 这一条与元素是 class 还是 struct 无关
  ok   可数组里的元素是**引用**：换一条路径拿到的是同一个 Question 对象 —— 于是「拷一份题库」根本不算隔离，§12 那条「改了 Model 界面不动」的病根就在这儿
  ok   换成 struct 的 Model：改副本里第 0 题，原件一个字没动（"甲"）—— 值类型 + 数组的值语义，隔离是彻底的
  ok   把状态传进函数再改：struct 版必须**把改完的那份接回来**才有 1 —— 忘了接回来就等于什么都没做，这是值语义 Model 的唯一代价
  ok   class 版（书里 ViewController 就是 class）不需要接回来，函数内那句 += 直接落在同一个对象上（现在 2）—— 「状态住在谁的哪一次赋值里」这句话，class 与 struct 给的是两个答案
```

- **前两条要连起来读，它们是一对陷阱**。`Array` 是值类型，所以 `copiedList.removeAll()` 伤不到
  原题库 —— 这一步很多人以为「我隔离了」。可 `bank.list[0] === bank.list[0]`（第二条断言）
  说明**元素是引用**：换一条路径拿到的是同一个 `Question` 对象。于是「拷一份题库」在
  class-element 的模型里**根本不算隔离**：你隔离了容器，没隔离内容物。本章 §12 那条
  「改了 Model，界面上一个字都没变」的病根就在这儿 —— 控制器、题库、`label` 之间传的
  全是同一批引用；
- **struct 那一版的隔离是彻底的**（第三条）：`valueCopy[0] = QuestionValue(text: "甲改", …)`
  之后原件读回来还是 `"甲"`。值类型 + 数组的值语义，两层叠起来才叫隔离；
- **代价写在第四条**：`bump(byValue)` 里面改的是副本，外面必须 `byValue = bump(byValue)`
  把返回值接回来。忘了接 = 什么都没做，而且不报错。这是值语义 Model 唯一的、也是最常踩的坑
  （第 30 章 §6「函数的输出」量的就是这句返回值不接的情形）；
- **第五条回到书里那个选择**：`QuizViewController` 是 `class`，所以 `bumpReference(quiz)`
  里那句 `+= 1` 直接落在调用方那个对象上，两次调用读回 2。书里选 class 不是错，但
  「状态住在谁的哪一次赋值里」这句话，class 与 struct 给的答案正好相反。本章后面
  §22 那个闭包引用环、§25 那个三方环，都以「控制器是 class」为前提 —— 值类型上挂
  闭包属性不会成环（第 30 章 §20）。

## §7 书 7.6 那四行属性：let 锁的是引用，不是里面的数据

7.6 到 7.11 是一节长一样东西的过程，`QuizViewController.swift` 把这个「慢慢长出来」的过程
原样保留了下来：

```swift
final class QuizViewController: UIViewController {
    let allQuestions = QuestionBank()      // 7.6：控制器直接持有题库
    var pickedAnswer: Bool = false         // 7.6：用户这一次点的是「是」还是「否」
    var questionNumber: Int = 0            // 7.7：游标
    @objc dynamic var score: Int = 0       // 7.11：分数（@objc dynamic 是 §19 加的，见那节）

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(questionLabel)
        …
        yesButton.tag = 1                  // 书里这两格填在故事板的 Inspector 里
        noButton.tag = 2
        nextQuestion()                     // 7.10 的重构点：原本是 list[0] + 一行赋值
    }

    @objc func answerPressed(_ sender: UIButton) {
        if sender.tag == 1 { pickedAnswer = true }
        else if sender.tag == 2 { pickedAnswer = false }
        checkAnswer()
        questionNumber += 1
        nextQuestion()
    }
}
```

```
== §7 书 7.6 那四行属性：let 锁的是引用，不是里面的数据 ==
  ok   出厂状态：questionNumber=0 pickedAnswer=false score=0 —— 三个都是 var，全部住在控制器这一层（Model 层一个都没有，见 §5）
  ok   点一次「是」之后：游标 1、分数 1 —— 第一次读回的是**改过之后**的值，因为改的是同一个对象；控制器是 class 这条前提，决定了「谁拿到它都能改」
  ok   另一个 QuestionBank 实例自带十三道题：init() 里的 append 每造一个就跑一遍（不是共享的一份，§28 的单例对照从这里开始有意义）
  ok   `let allQuestions = QuestionBank()` 里那个 let 只锁引用：它拦不住 list 被 append（现在 14 题），也拦不住别的实例（13 题）—— 书 7.6 那句 let 给的安全感，边界就在这里
```

- **三个状态全是 `var`，全在控制器**。这是本章第一个可以数的架构事实：`Question` 与
  `QuestionBank` 这两个 Model 文件里没有一个「答到第几题」的属性（§5 那个对照组类除外，
  它就是故意把游标搬进 Model 的那一版）。书 7.5 的三层划分落到代码上就是这个区别；
- **点一次「是」读回的是改过之后的值**（游标 1、分数 1）。断言写的是
  `quiz.answerPressed(quiz.yesButton)` 之后立刻读 `quiz.questionNumber`。这条看着普通，
  但它是 §11 那个 bug 能成立的前提：改的是同一个对象，所以「谁都能改」；
- **每造一个 `QuestionBank` 就跑一遍那十三行 `append`**。`let more = QuestionBank()`
  自带 13 道题，而不是「和 quiz 手里那份共享的 13 道」。这条是 §28/§30 那个单例对照的起点
  （书 7.12 那个 HUD 库用的是 `shared`，两台控制器共用同一本账），也是本章能用
  「另起一个 bank」做隔离测试的前提；
- **`let` 拦不住 `list.append`**。`quiz.allQuestions.list.append(…) → 14` 而
  `more.list.count == 13`：那个 `let` 锁的是「allQuestions 这个名字不能再指向别的对象」，
  不是「里面那份数据不能变」。书 7.6 写这行时给的唯一理由是「题库不需要换」，而这一条断言
  把那句安全感的确切边界画出来了 —— 要真锁住内容，得把 `var list` 换成 `let list`，
  或者换 §31 那种只暴露读口的协议。

## §8 list[13] 的下场：崩溃原文进探针，守卫的等价性留在这里量

书 7.7 结尾的原话是「构建并运行项目，在完成了最后一道题目的选择以后，程序崩溃了」。
那条 `Fatal error: Index out of range` 由探针 r01 现跑现抄（判定 2/3 不允许它进主线，
原文在文末「探针记录」）；这里量的是**不崩的那一半**：边界到底在哪儿、7.8 那句守卫什么时候够用。

```swift
// 书 7.7 的 nextQuestion 没有守卫；7.8 加上的是这一句：
func nextQuestion() {
    if questionNumber <= 12 {                 // 12 是**抄**来的（见 §9）
        questionLabel.text = allQuestions.list[questionNumber].questionText
        updateUI()
    } else {
        …                                      // 7.9 在这里换成弹窗
    }
}
```

```
== §8 list[13] 的下场：崩溃原文进探针，守卫的等价性留在这里量 ==
  ok   合法下标到 12 为止，13 已经出界 —— 而 7.7 的代码在答完第十三题后正好把 questionNumber 推到 13
  ok   在十三道题的题库上，`questionNumber <= 12` 与 `indices.contains(questionNumber)` 对 0…14 每个取值都同真同假 —— 7.8 那句修法的**这一半**是对的：它确实拦住了崩溃
  ok   最后一题（下标 12）读得回来：「进行人工呼吸前，…」；探针 r01 里越界那一下就是想要它的下一题
```

- **为什么会崩在这一步**：`answerPressed` 的顺序是「判卷 → `questionNumber += 1` →
  `nextQuestion()`」，而 `checkAnswer()` 读的是 `allQuestions.list[questionNumber]`。
  第十三题答完之后游标是 13，`nextQuestion()` 有守卫所以不去取 `list[13]`，可用户再点一次
  按钮，`checkAnswer()` 就取了 —— 崩溃点其实**不在守卫那一行**（r01 抄到的现场就是这样：
  十三行「屏幕上第 N 题」全打完了才 abort）；
- **`<= 12` 与 `indices.contains(…)` 在 13 题这一版上同真同假**，这是一条**等价性**断言，
  不是巧合：它把 0…14 每个取值都跑了一遍。所以 7.8 那句修法是有效的 —— 本章不推翻它，
  只给它记账（下一节量它的**适用边界**）；
- **为什么主线只量「合法下标到 12」**：因为「崩」这件事在本仓库是**另一个进程的产物**。
  主线断言的是不崩那部分的边界，rNN 那五支断言崩的形状，两边合起来才是这一节的完整结论。

## §9 `<= 12` 里的 12 是从题库长度抄来的：抄来的边界不跟着源头动

7.8 的修法把「十三道题」这个事实写成了字面量。同一份代码换题库长度，守卫立刻放行一批
根本不存在的下标。这里不换会崩的题，改成**数有多少个「放行但不合法」的取值**：

```swift
let threeBank = QuestionBankWithCursor(list: three)     // 只有 3 道题
var letSlide = 0
for n in 0...14 where (n <= 12) && !threeBank.list.indices.contains(n) { letSlide += 1 }

var safeSlide = 0
for n in 0...14 where (n < threeBank.list.count) != threeBank.list.indices.contains(n) { safeSlide += 1 }
```

```
== §9 `<= 12` 里的 12 是从题库长度抄来的：抄来的边界不跟着源头动 ==
  ok   三题的题库配上写死的 `<= 12`：下标 3…12 这 10 个取值会被守卫放行，可它们一个都不存在 —— 崩不崩只取决于运行到不到那里，不取决于守卫
  ok   换成 `questionNumber < list.count`：与 indices.contains 全表同真假（差异 0 处）—— 边界要么从源头算，要么就不算
  ok   顺带一条本章反复要用的事实：题目数量是可问的（3 / 13），所以任何写死它的地方都是**抄的**，不是问的（书 7.11 那行 progressLabel 里的 13、7.13 步骤 5 里改成的 29，都是同一类抄写）
```

- **10 个放行值、0 个存在值**。这条数字是本章后面 §29 的预演：写死的边界不会跟着源头动，
  它的危险程度取决于「运行到不到那里」，而不是取决于守卫本身；
- **「崩不崩只取决于运行到不到那里」**这一句值得单独记住。这类 bug 在测试里的表现是
  「跑得挺正常」，在灰度里的表现是「换了份配置就崩」，因为守卫拦的是**下标**、
  而它对题库有几道题一无所知；
- **换成 `count` 之后全表同真假**：这不是「更安全」的风格建议，是一条可测的等价性。
  要么从源头算，要么就不算（第三种写法是 §31 的 `source.questionCount`，它把「源头」
  收成了一个读口）；
- **第三条断言是本章出现频率最高的一句**：题目数量是**可问的**（`three.count` → 3、
  `bank.list.count` → 13），所以任何写死它的地方都是**抄的**。书里三处抄写：
  7.8 守卫里的 12、7.11 progressLabel 里的 13、7.13 步骤 5 里改成的 29（守卫 28、除法 29、
  label 字符串 29），三处抄写、三种下场，§29 一处一处数。

## §10 progressLabel 那句 "\\(questionNumber + 1) / 13"：游标从 0 数、人话从 1 数

```swift
func updateUI() {
    scoreLabel.text = "分数：\(score)"
    progressLabel.text = "\(questionNumber + 1) / 13"
    progressBar.frame.size.width = (view.frame.size.width / 13) * CGFloat(questionNumber + 1)
    Trace.log.append("updateUI：\(questionNumber)")
}
```

```swift
let counting = QuizViewController()
counting.loadViewIfNeeded()
expect(counting.progressLabel.text == "1 / 13", "刚进界面（questionNumber=\(counting.questionNumber)）显示的是「…")
counting.answerPressed(counting.yesButton)
expect(counting.questionNumber == 1 && counting.progressLabel.text == "2 / 13", "答完一题：…")
let drained = QuizViewController()
drained.loadViewIfNeeded()
for _ in 0..<13 { drained.answerPressed(drained.noButton) }
expect(drained.questionNumber == 13 && drained.progressLabel.text == "13 / 13", "十三题走完：…")
expect(drained.questionLabel.text == bank.list[12].questionText, "题目文字也停在最后一题（…）：…")
```

```
== §10 progressLabel 那句 "\(questionNumber + 1) / 13"：游标从 0 数、人话从 1 数 ==
  ok   刚进界面（questionNumber=0）显示的是「1 / 13」—— 第 1 题的游标是 0，那个 +1 是**给被人看的那一行**加的，不是给下标加的
  ok   答完一题：游标 1、显示「2 / 13」—— 两者始终差 1，这正是 7.11 正文里那句「需要将其加 1，以便显示其真正的题目序号」
  ok   十三题走完：游标被推到 13（已经出界），而屏幕上仍是「13 / 13」—— 因为 else 分支里根本没调 updateUI，界面上那一行停在最后一次合法更新
  ok   题目文字也停在最后一题（「进行人工呼吸前，应…」）：状态已经走到 13，视图还留在 12 —— 这一对错位就是 §11 那个 bug 的完整形状
```

- **「1 / 13」出现在游标为 0 的时候**，这是所有 off-by-one 争论的源头。那个 `+1` 是
  **给人看的那一行**加的，不是给下标加的 —— 两者始终差 1，所以任何一处把界面上那个数字
  当游标用（或者反过来）的代码都会错一格。§16 那个 `tag - 1` 是同一件事的**反方向**；
- **第四条断言是这一节真正的收获**：游标 13、屏幕 12。这不是「界面落后一题」，而是
  「状态与视图**脱钩**了」——因为 `else` 分支压根没调 `updateUI()`。这一对错位是 §11 那个
  bug 的完整形状，也是 §18 那本账（「界面更新 13 次、判卷 12 次」）的由来；
- 原书 7.11 对这一行的解释是「需要将其加 1，以便显示其真正的题目序号」。这句话本身没错，
  但它让很多人以为进度条/label 上的数字「就是题号」。在这一版代码里它**不是**题号，
  它是「已经显示到第几题」，两者的差在 §14 那条「满格提前一格」上现形。

## §11 「重置 questionNumber 却不更新界面」：书里明写的那个 bug，量成两次读数的差

书 7.9 结尾有一段专门描述这个 bug（原文照抄在 `main.swift` 的注释里）：重置之后
「当前屏幕上的题目还停留在第一轮的最后一道，没有进行更新……这就意味着从第 2 轮开始，
重新开始以后永远无法显示题库中的第 2 道题」。这一节把它的**过程**逐条量成五组读数，
并且顺手发现了一条书里没写的后果。

```swift
func startOverWithoutRefresh() {   // 未修版：只清状态
    score = 0
    questionNumber = 0
}
func startOver() {                 // 修版：清完状态顺手 nextQuestion()
    score = 0
    questionNumber = 0
    nextQuestion()
}
```

```swift
let restartBug = QuizViewController()
restartBug.loadViewIfNeeded()
for _ in 0..<13 { restartBug.answerPressed(restartBug.noButton) }
restartBug.startOverWithoutRefresh()          // 只清状态，不喂视图
expect(restartBug.questionNumber == 0 && restartBug.score == 0, "重置之后状态确实归零了（…）—— bug 不在这一步")
expect(restartBug.questionLabel.text == bank.list[12].questionText, "可屏幕上还是第十三题（…）")
restartBug.answerPressed(restartBug.yesButton)
expect(restartBug.questionLabel.text == bank.list[1].questionText, "再答一次才跳：屏幕直接到了第 2 题（…）")
expect(restartBug.progressLabel.text == "2 / 13", "进度那一行也跟着跳到「2 / 13」：…")
expect(restartBug.score == 1, "而这一次点击判的是**下标 0** 那道题（…）")
```

```
== §11 「重置 questionNumber 却不更新界面」：书里明写的那个 bug，量成两次读数的差 ==
  ok   重置之后状态确实归零了（游标 0、分数 0）—— bug 不在这一步
  ok   可屏幕上还是第十三题（「进行人工呼吸前，应…」）：状态是 0，视图是 12 —— **没人再喂它一次**
  ok   再答一次才跳：屏幕直接到了第 2 题（「喝白酒时最好…」）—— 这一轮里永远不会出现的是**第 1 题**（下标 0 被那句 += 1 直接跨过去了）
  ok   进度那一行也跟着跳到「2 / 13」：从第 2 轮起，第 1 题既看不见也答不着，整套题只剩 12 道可答
  ok   而这一次点击判的是**下标 0** 那道题（用户眼前明明看着第 13 题作答）：判卷与屏幕错开了整整一题，1 分是这么来的 —— 书里只说了「题目不更新」，没说同一次点击里评分用的也不是屏幕上那题
  ok   修法（7.9 最后加的那一行 nextQuestion()）：状态与界面一起回到第 1 题（游标 0、屏幕是「吃烧烤不能喝啤酒…」）—— 归零之后必须重新走一次「把状态搬到视图上」
```

逐条读这六句：

1. **状态归零是对的**，`questionNumber == 0 && score == 0`。这一条断言存在的理由很实际：
   很多人第一眼会怀疑「重置没生效」。生效了，bug 在后面；
2. **视图停在第 13 题**（读回的 `questionLabel.text` 等于 `bank.list[12].questionText`）。
   状态是 0、视图是 12 —— 中间那个「把状态搬到视图上」的一步没人走。这就是 §12 那条纪律的
   反面教材，也是本章给「改了数据不等于改了界面」找到的最便宜的样本；
3. **再答一次才跳，而且跳到第 2 题**。`answerPressed` 的顺序是判卷 → `+= 1` →
   `nextQuestion()`，游标从 0 推到 1 之后才出题，所以**下标 0 那道题在这一轮里永远不会
   出现**。这里要指出原书那句「永远无法显示题库中的第 2 道题」的**编号是错的**：
   被跨过去的是 `list[0]`，按人话数它叫**第 1 道题**。本章按跑出来的结果写；
4. **进度那一行跟着跳到「2 / 13」**：整套题只剩 12 道可答。这个后果比「少显示一题」重，
   因为它同时影响得分上限；
5. **第五条是本章新量出来的**（书里没写）：那一次点击判卷用的是**下标 0** 那道题的答案，
   而用户眼前看着的是第 13 题。所以那 1 分不是「用户答对了第 13 题」，
   是「系统拿第 1 题的答案给第 13 题打了分」。判卷与屏幕错开整整一题 —— 这条和 §5 那个
   设计 B 的错位、§28 那个隐藏按钮的下标，是同一类 bug 的第三次现形；
6. **修法只有一行**：`nextQuestion()`。它做的事就是「重新走一次把状态搬到视图上」。
   §25 那颗「重新开始」按钮的 handler 里调的就是这个修好的 `startOver()`，
   同一段代码本章读到两次。

## §12 书 7.5 那句「数据模型与视图永远不会直接发生联系」的可执行版

7.5 的结论那句「数据模型与视图永远不会直接发生联系」在原书里是**一句话**，没有判据。
它在这章的可执行版本短得惊人：

```swift
let sharedQuestion = MutableQuestion(text: "面膜做的时间越久越好。", correctAnswer: false)
let shownOnScreen = UILabel()
shownOnScreen.text = sharedQuestion.questionText   // 屏幕上摆的是这一句
sharedQuestion.questionText = "面膜做得越久越好。"  // Model 改了
expect(shownOnScreen.text == "面膜做的时间越久越好。", "Model 改了（…），label 上仍是旧的那句（…）")
shownOnScreen.text = sharedQuestion.questionText    // 再喂一次
expect(shownOnScreen.text == "面膜做得越久越好。", "再喂一次才更新 —— 于是「什么时候再喂」成了架构问题：…")
var holder = [sharedQuestion]
holder.removeAll()
expect(sharedQuestion.questionText == "面膜做得越久越好。", "把对象交出去之后再销毁容器（…）")
```

```
== §12 书 7.5 那句「数据模型与视图永远不会直接发生联系」的可执行版 ==
  ok   Model 改了（现在是「面膜做得越久越好。」），label 上仍是旧的那句「面膜做的时间越久越好。」—— 视图**不会**自己跟着动，这是好事：它就是 7.5 那句话的意思
  ok   再喂一次才更新 —— 于是「什么时候再喂」成了架构问题：书 7.11 的答案是「在 nextQuestion() 里手动调 updateUI()」，§17 与 §19~§22 量另外五种（target-action、KVO、通知中心、代理、闭包）
  ok   把对象交出去之后再销毁容器（holder 里现在 0 项），对象还活着：引用计数不归容器管 —— 这也是本章能用「另起一个 bank」做隔离测试的前提（§28 的依赖注入）
```

- **这句话不是描述一个事实，而是描述一个约定**。「视图不会自己动」在 UIKit 里是真的
  —— `UILabel.text` 存的是一份拷贝（`String?`），它不观察任何人。所以 7.5 那句话的第一半
  其实是白送的，**不需要架构就有**；
- **第二半才是问题**：既然视图不会自己动，那「谁在什么时候再喂一次」就变成了一个必须
  有人回答的问题。书 7.11 的回答是「在 `nextQuestion()` 里手动调 `updateUI()`」，
  而 §18~§22 把另外五种机制（target-action、KVO、NotificationCenter、代理、闭包）
  用同一本账量了一遍 —— 这一节就是那五节的**问题来源**；
- **第三条讲的是引用计数**：`holder.removeAll()` 之后对象还活着。这条看起来和 MVC 无关，
  其实是本章能做隔离实验的前提（另起一个 `QuestionBank` 不影响原来那台控制器），
  也是 §31「把 Model 递进控制器」（依赖注入）能成立的机制 —— 容器不是主人。

## §13 loadViewIfNeeded 给的那块 view：书里「屏幕宽度」这件事在没有 UIWindow 时到底是什么

书 7.11 那行进度条代码要读 `view.frame.size.width`，原书写的是「还需要知道屏幕的宽度值」。
在 Xcode 工程里这句话不用证 —— 应用启动后 view 被放进窗口，宽度就是屏幕宽度。本章的进程里
没有 `UIApplication.shared`（§1），所以要亲眼看一屏，**这几条数字后面 §14 要拿来算进度**：

```swift
let geometry = QuizViewController()
geometry.loadViewIfNeeded()
let screenWidth = geometry.view.frame.size.width
line("  geometry.view.frame=\(geometry.view.frame) bounds=\(geometry.view.bounds) safeAreaInsets=\(geometry.view.safeAreaInsets)")
```

```
== §13 loadViewIfNeeded 给的那块 view：书里「屏幕宽度」这件事在没有 UIWindow 时到底是什么 ==
  geometry.view.frame=(0.0, 0.0, 402.0, 874.0) bounds=(0.0, 0.0, 402.0, 874.0) safeAreaInsets=UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
  ok   loadViewIfNeeded 之后 isViewLoaded=true，view 确实造出来了（UIView）—— 没有窗口也能有 view：第 31 章说的那条边界在这一层同样成立
  ok   view.frame.size.width=402.0 —— 一个没有窗口、没有根视图控制器的 view 仍然有非零宽度，它来自 UIScreen.main.bounds（第 31 章 §16 量过这台模拟器给的是 402×874），不是来自「被显示出来」
  ok   可安全区全是 0（top=0.0 bottom=0.0）：宽度是屏幕给的，内缩是窗口给的 —— 没有窗口就没有内缩
  ok   出厂时 progressBar.frame=(0.0, 0.0, 30.923076923076923, 0.0)：四个数里只有**宽度**不是 0，而它来自 viewDidLoad → nextQuestion → updateUI 那一行算术 —— origin 和 height 一直是 0（书 2.2 里这两样是故事板给的 frame，第 31 章 §13 量的是同一件事的另一半）：这一节把「谁拥有这个 frame 的哪一部分」拆成了可数的格子
```

- **`loadViewIfNeeded()` 是本章最重要的一个换法**。书里的时序是「app 启动 → 窗口 →
  根控制器的 view 上屏 → `viewDidLoad`」，这一句在没有窗口的进程里把
  `loadView` → `viewDidLoad` 这一段**单独触发**出来，于是 §7 之后每一次「点按钮」都不需要
  屏幕。第 31 章那条「界面文件不依赖窗口，装配依赖」的边界在这一层同样成立；
- **宽度 402 是真的，安全区 0 也是真的**。`frame` 来自 `UIScreen.main.bounds`（这台 iPhone
  模拟器给 402×874），而 `safeAreaInsets` 全是 0 —— 因为内缩是**窗口**给的，
  这个进程没有窗口。「屏幕宽度」这句话在代码里其实是两个不同的来源，
  本章 §14 只用前者，所以算得出确定的数；
- **第四条那种 frame 拆格子**是全章最「UIKit」的一条：`progressBar.frame` 出厂是
  `(0.0, 0.0, 30.923076923076923, 0.0)`。四个数里只有宽度不是 0，而那一格宽度来自
  `updateUI()` 那行算术；`origin` 与 `height` 一直是 0 —— 书 2.2 里这两样是故事板给的
  frame。这一节把「谁拥有这个 frame 的哪一部分」拆成了可数的格子（第 31 章 §13 量的
  是同一件事的另一半：界面文件里那些 `<rect>` 有几格真生效）。

## §14 progressBar 宽度全表：书 7.11 那句「完成全部13道题目以后宽度与屏幕一致」的准确落点

书里的原文是「构建并运行项目……当完成全部13道题目以后黄色进度条的宽度与屏幕宽度一致」。
眼睛看到的结果对得上，但**原因和这句话说的不一样**。13 次点击逐一采样：

```swift
let barWatch = QuizViewController()
barWatch.loadViewIfNeeded()
let unitWidth = geometry.view.frame.size.width / 13
var barWidths: [Double] = []
for _ in 0..<13 {
    barWatch.answerPressed(barWatch.noButton)
    barWidths.append(barWatch.progressBar.frame.size.width)
}
line("  逐题答完之后的宽度：\(barWidths.map { String(format: "%.2f", $0) }.joined(separator: " "))")
barWatch.startOver()
```

```
== §14 progressBar 宽度全表：书 7.11 那句「完成全部13道题目以后宽度与屏幕一致」的准确落点 ==
  屏幕宽度 402.0，13 等分之后每格 30.9231
  逐题答完之后的宽度：61.85 92.77 123.69 154.62 185.54 216.46 247.38 278.31 309.23 340.15 371.08 402.00 402.00
  ok   第 13 次点击之后宽度是 402.00，正好等于屏幕宽度 —— 但它不是「答完 13 题」算出来的：这一次点击走的是 else 分支（没调 updateUI），这个宽度是**显示第 13 题时**（questionNumber=12，(12+1)/13）留下的
  ok   第 1 次点击后的宽度 61.85 = 2 格：因为 answerPressed 先 += 1 再 nextQuestion，屏幕上已经是第 2 题了 —— 进度条跟着「显示到第几题」走，不跟着「答完几题」走
  ok   整条序列单调不减（13 个采样点）：把宽度写成 frame 的算术而不是查表，好处就在这儿 —— 但它也意味着宽度这个状态**只有这一行代码知道**（§28 换题库长度时要改的正是这个 13）
  ok   书 7.11 还说「单击重新开始以后，进度条又回到最初的宽度」—— 实测回到 30.9231，即**一格**：它和出厂那一格（§13 读到的同一个数）相等，但绝不是 0 —— 「回到最初」在代码里是重新走一遍 updateUI，不是把宽度擦掉
```

- **最后一行的 402.00 是重复的**（倒数第二个也是 402.00）。这一格就是整节的落点：
  满格不是在「答完第 13 题」那一刻算出来的，而是在「**显示**第 13 题」那一刻算出来的
  （`questionNumber == 12` 时 `(12+1)/13` 刚好满格）；
- **第一个采样点是 2 格而不是 1 格**，因为它读的是「点完第一次之后」的界面：
  `answerPressed` 先 `+= 1` 再 `nextQuestion()`，屏幕上已经是第 2 题了。
  所以「进度条跟着显示到第几题走，不跟着答完几题走」—— 这句和 §10 那条编号差是同一件事；
- **单调不减**这条是这种写法的**优点**：宽度写成 `frame` 的算术而不是查表，
  不会出现「第 7 格比第 6 格短」这类表填错。代价是「总共 13 格」这个事实**只存在于
  `updateUI()` 那一行里**（§29 换题库长度时要改的正是它）；
- **「回到最初的宽度」= 一格，绝不是 0**。这条是本节最容易被读者误解的一句：
  书里说「回到最初」，代码里做的是「重新走一遍 `updateUI()`」（`startOver()` →
  `nextQuestion()` → `updateUI()`，`questionNumber` 是 0，所以 `CGFloat(0 + 1)` 那一格）。
  所以「进度条清零」这件事在这份代码里从来没发生过 —— 出厂宽度与重做后的宽度是**同一个数**
  （§13 与这里的 30.9231），而它不是 0。

## §15 CGFloat 与 Int 的混算：编译器的红点进探针，能算的账留在这儿

书 7.11 先给了这一行：

```swift
progressBar.frame.size.width = (view.frame.size.width / 13) * questionNumber   // 报错
```

原书的解释是「在乘号（\*）的两侧不能一边是单精度值，一边却是整型值」。那是编译期诊断，
判定 1 要求日志为空，所以原文进探针 e05 —— 而**原文与书里的解释对不上**：本机的 Swift 把
光标放在**除号**上，给的是

```
error: referencing operator function '/' on 'DurationProtocol' requires that 'CGFloat' conform to 'DurationProtocol'
```

一个和进度条毫无关系的协议。真正对应「一单一整」的是同一支探针里的最小样本
`CGFloat * Int`，那句才说 `binary operator '*' cannot be applied to operands of type 'CGFloat' and 'Int'`。
换句话说：**重载消解失败时，编译器报的是它试到最后的那个候选，不一定是写错的那一下**。
这句话比书里那句解释实用得多，但它只有跑一遍才拿得到。

主线量能算的那一半 —— 为什么 Swift 拦下这一下是有道理的，因为 Int 的除法会截断：

```swift
let unitWidth = geometry.view.frame.size.width / 13        // CGFloat 的除法
let asIntWidth = Int(screenWidth)                           // 本机屏幕宽度是整数 402
expect(unitWidth * 13 != 0 && abs(unitWidth * 13 - screenWidth) < 1e-9, "…")
```

```
== §15 CGFloat 与 Int 的混算：编译器的红点进探针，能算的账留在这儿 ==
  屏幕宽度 402.0 除以 13 = 30.9230769231；宽度对 1 取余 = 0.0
  ok   CGFloat 的除法保住了小数：30.9230769231 × 13 = 402.0，回到屏幕宽度 —— 换成 Int 的除法（本机屏幕宽度是整数 402）就只剩 30，一格短了 12.00 像素，13 格走完离屏幕宽度还差这么多
  ok   书里改法同时做了两件事：加 CGFloat() 和把 questionNumber 换成 questionNumber+1 —— 前一件是**类型**，后一件是**编号**（§10 那条），混在一起说容易让人以为报错是 +1 引起的。探针 e05 的两段原文里没有任何一句提到 1 与 13 的编号差：它说的是类型，甚至连出错的那个运算符都没指对
  换成 UIProgressView 的话，同一件事写作 progress=0.076923：它吃 0...1 的比例，不吃像素
  ok   对照组 UIProgressView 吃的是**比例**：写 0.076923 就读回 0.076923，长度由系统按控件宽度画 —— 书 7.11 用 UIView 的**宽度**当进度（像素、控制器自己算），UIProgressView 用 0...1（视图自己画）：这两种写法对「谁拥有这个数」的回答不同，前者只有 updateUI 那一行知道总共有 13 格，后者连 13 都不用说
```

- **「一格短了 12.00 像素」这条要在真机上重跑**。它用的是本机 `UIScreen.main.bounds.width`
  恰为整数 402 这一事实（402/13 = 30 余 12）。换一台 390 宽的机器，数字变了，
  **性质不变**：Int 除法截掉的部分会被 13 格累加起来，满格那条线永远到不了；
- **第二条断言拆的是书里那段解释的合并**：7.11 的改法同时做了两件事 ——
  `CGFloat(questionNumber + 1)` 里加了类型转换，也把 `questionNumber` 换成 `questionNumber + 1`。
  两件事混在一句话里说，容易让人以为报错是那个 `+1` 引起的。e05 的两段原文里没有任何一句
  提到 1 与 13 的编号差；
- **UIProgressView 那一组是对照实验**，也是本节给 §29 埋的伏笔：`progress` 吃的是
  0...1 的比例，控件自己按宽度画，所以「总共 13 格」这件事在这个写法里**根本不需要说出口**。
  书 7.11 那种「控制器算像素」的写法把总格数写进了 `updateUI()`，于是它成了三处抄写之一。

## §16 `pickedAnswer = sender.tag - 1`：按钮的身份是一个可以在 Inspector 里填错的整数

书 7.13 步骤 3 让三颗按钮的 tag 分别填 1、2、3，代码里写 `pickedAnswer = sender.tag - 1`
当数组下标。这一节量这个**减一**：它对得上什么、填错了会怎样。

```swift
// 7.6 那一版（if-else 认 tag）：
if sender.tag == 1 { pickedAnswer = true }
else if sender.tag == 2 { pickedAnswer = false }

// 7.13 那一版（tag 直接当下标）：
pickedAnswer = sender.tag - 1
score = score + allQuestions.list[questionNumber].questionScore[pickedAnswer]
```

```
== §16 `pickedAnswer = sender.tag - 1`：按钮的身份是一个可以在 Inspector 里填错的整数 ==
  tag → 下标：1→0 2→1 3→2
  ok   tag 填 1/2/3 时，减一得到 0/1/2 —— 正好是 3 个选项的下标集：这个减一是把「Interface Builder 里的编号（从 1 起）」换成「Swift 数组的下标（从 0 起）」，和本章 §10 那个 +1 是同一件事的反方向
  ok   忘了在 Inspector 里填 tag 的那颗按钮：tag 出厂是 0，减一成了 -1 —— 它是负数，下标运算当场越界（原文见探针 r02：负数与超出末尾是同一句 `Index out of range`）。编译器拦不住，因为 tag 的类型是 Int，不是「合法下标」
  ok   两颗不同的按钮可以有同一个 tag（同一份题分）—— tag 是**抄在界面里的编号**，不是身份：§7 那个 let 拦不住 append，这里的 Int 也保证不了唯一
  ok   回到书 7.6 的写法（if tag==1 置 true / else if tag==2 置 false）：把 yesButton 的 tag 改成 7 再点，pickedAnswer 仍是上一轮的 false，可游标照样走到 1 —— 两个分支都不成立，它**静默地**拿旧值判了卷。7.13 换成 tag-1 当数组下标之后，同一处填错从「静默」变成「崩溃」：一个更难查，一个更早响
```

- **那个减一是两套编号之间的换算**，和 §10 那个 `+1` 是同一件事的反方向：
  Interface Builder 里的编号从 1 起，Swift 数组的下标从 0 起。把这条讲清楚之后，
  「为什么 tag 要填 1 而不是 0」就不再是一个需要背的约定；
- **`UIButton.tag` 的出厂值是 0**，而 `0 - 1 == -1`。这一格填错的下场是当场越界，
  探针 r02 抄的现场值得看一眼：`tag = 0，减一得到下标 -1`、`这一题有 3 档分值：[6, 3, 0]`，
  然后 `Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range`。
  **负数下标和超出末尾下标报的是同一句话** —— 运行时不告诉你它越的是哪一边，
  也就是说 Swift 里「数组下标」是**一个**检查，不是两个；
- **为什么编译器拦不住**：`tag` 的类型是 `Int`，不是「合法下标」。这一条和 §7 那个
  `let` 拦不住 `append` 属于同一类：类型系统只关心类型，不关心「这个数是从哪抄来的」；
- **第四条那个对照才是本节的目的**：书 7.6 的 `if tag == 1 / else if tag == 2` 写法遇到
  `tag = 7` 时，**两个分支都不成立、什么都不说**，`pickedAnswer` 保留上一轮的旧值，
  而游标照样 `+= 1` —— 于是这一次点击拿旧答案判了卷，界面继续往前跑。
  7.13 换成 `tag - 1` 当数组下标之后，**同一处填错从「静默」变成「崩溃」**。
  两种都不好，但一个更难查、一个更早响：崩溃至少会当场把位置告诉你。

## §17 把主线改成「真点一下」会怎样：sendActions 在这条路上过不去，所以本章直调方法

本章前面每一次「点按钮」都是直接调 `answerPressed(_:)`。这一节把这层糊掉的地方挑明，
并且**先试原路**：给按钮挂上 target-action，再用 `UIControl` 那句「照着表打一遍」。
第 31 章 §16 已经量过一次「不派发」，这里量的是它在 MVC 语境下的后果。

```swift
let wired = QuizViewController()
wired.loadViewIfNeeded()
wired.yesButton.addTarget(wired, action: #selector(QuizViewController.answerPressed(_:)), for: .touchUpInside)
let beforeWired = wired.questionNumber
wired.yesButton.sendActions(for: .touchUpInside)      // ← 原书那一下「点按钮」的等价物
line("  发一次 sendActions(for: .touchUpInside)，游标从 \(beforeWired) 走到 \(wired.questionNumber)（这个方法返回 Void，本身不报告有没有命中）")
```

```
== §17 把主线改成「真点一下」会怎样：sendActions 在这条路上过不去，所以本章直调方法 ==
  发一次 sendActions(for: .touchUpInside)，游标从 0 走到 0（这个方法返回 Void，本身不报告有没有命中）
  ok   表里确实登记了（下面读得到 allEvents=64），可游标一步没动 —— 派发要过 UIApplication.shared，而它是 nil（§1）。第 31 章 §16 那条边界与界面文件无关，在这里以同样的方式现形
  wired.yesButton.allControlEvents.rawValue=64（.touchUpInside=64）；superview=nil
  ok   allEvents 读得回 64：addTarget 这一步是**成功**的，目标、动作、事件三样都在表上 —— 崩的不是接线，是接线之上的事件管线
  ok   同一个对象、同一个方法，直接调就全走通了（游标 1、pickedAnswer=true）—— 这就是本章的换法：把「点一下看看」换成「调这个方法，然后读它写进视图的那几个值」，被跳过的只有路由，一行逻辑都没少
  ok   顺带一条能解释上面两行的事实：yesButton 从来没被 addSubview 过（superview 是 nil）—— 书 2.2 摆在故事板上的按钮在这里只是控制器持有的一个对象；没有父视图、没有窗口，它永远不可能自己收到一次触摸
```

四条读数把「本章为什么直调方法」讲完了：

1. **`addTarget` 是成功的**：`allControlEvents.rawValue` 读回 64，正是 `.touchUpInside`。
   目标、动作、事件三样都登记在表上 —— 接线没问题；
2. **`sendActions(for:)` 一个都不派发**，游标一步没动。派发要过共享应用对象，而它是 `nil`
   （§1 那条前提在这里现形）。注意 `sendActions` 返回 `Void`，**它自己不说有没有命中**，
   所以这一格必须靠读游标才知道；
3. **直调就全走通**（游标 1、`pickedAnswer = true`）。被跳过的只有路由，
   一行状态机逻辑都没少 —— 这就是本章所有断言的方法学依据；
4. **`superview` 是 nil**：这颗按钮从来没被 `addSubview` 过。这一条解释了上面两条为什么
   不冲突：书 2.2 摆在故事板上的按钮，在这里只是控制器持有的一个对象；
   没有父视图、没有窗口，它永远不可能自己收到一次触摸。
   这条边界与第 31 章那条「界面文件不依赖窗口」的边界是同一族的两个方向 ——
   装配能成，派发不能成。

## §18 第 1 种·手动：一次点击到底改了几处界面（updateUI 被叫到的次数）

§12 留下的问题是「改了 Model，视图不动，得有人再喂一次」。书 7.11 的答案是
「在 `nextQuestion()` 里手写一句 `updateUI()`」。这一节先给这一种**记账**，
§19~§22 用同一套账目去量另外四种机制 —— 五节的判据都是「谁被叫到、叫了几次」。
账本本身是一个全局数组（`Trace.log`），每次更新界面/判卷/弹窗都留一行：

```swift
enum Trace {
    static var log: [String] = []
    static func reset() { log = [] }
}

func updateUI() {
    scoreLabel.text = "分数：\(score)"
    progressLabel.text = "\(questionNumber + 1) / 13"
    progressBar.frame.size.width = (view.frame.size.width / 13) * CGFloat(questionNumber + 1)
    Trace.log.append("updateUI：\(questionNumber)")
}
```

```
== §18 第 1 种·手动：一次点击到底改了几处界面（updateUI 被叫到的次数） ==
  ok   刚 loadViewIfNeeded 完（viewDidLoad → nextQuestion → updateUI）：界面更新 1 次 —— updateUI：0。一次点击进入的状态机里，「改数据」和「改界面」是两句分开的话，各记一笔
  ok   再点 12 次：界面更新累计 13 次、判卷 12 次 —— 两者只差出厂那一次（那时候还没有用户动作，只有第一题上屏）
  ok   第 13 次点击：界面更新仍是 13 次（没有新增），新增的是「弹框：全部答完」—— else 分支不喂视图，这条 §10/§11 已经付过代价，这里给它记账的口径
  ok   updateUI 里那三行各写一处界面（题面、分数、进度条宽度）：现在三处都有值（"进行人工呼吸…" / "分数：7" / 402.0px）—— 手动这一种的代价是**界面有几处，这个方法就有几行**，加一个控件就有人忘记加一行（§11 那个 bug 是它的对偶：清状态的人没清界面）
  ok   三行里的第二行展开来看是「分数：7」—— 那个插值不是装饰：UILabel.text 的类型是 String?，而 score 是 Int，中间没有自动换算。书 7.11 第一次就写成了 `scoreLabel.text = score`，编译器原文见探针 e02（「cannot assign value of type 'Int' to type 'String?'」）。这也是「控制器与视图之间传的是字符串，不是数字」这句话的最小落点：数字要说什么话，由控制器那一行决定
```

- **「界面更新 13 次 / 判卷 12 次」这一对数字是全章的账本基线**。差的那一次是出厂那次
  （`viewDidLoad → nextQuestion → updateUI`），那时候还没有用户动作，只有第一题上屏。
  有了这一对，§19~§22 那四种机制的「命中几次」才有对照物；
- **第 13 次点击不增加界面更新次数**，新增的是「弹框：全部答完」这一笔。这就是 §10/§11
  那条错位的**记账口径**：else 分支不喂视图，所以游标出界而界面停在第 12 题；
- **「界面有几处，这个方法就有几行」是手动这一种的代价**。加一个控件就有人忘记加一行；
  而 §11 那个 bug 是它的对偶形态 —— 清状态的人没清界面。这两句话合起来就是
  「手动维护的同步，靠的是有人记得」；
- **最后一条把书 7.11 那个正文 bug 落到了类型上**：`scoreLabel.text = score` 报的是
  `error: cannot assign value of type 'Int' to type 'String?'`（探针 e02 的原文）。
  插值 `"分数：\(score)"` 里那个 `\(score)` 不是装饰，它是 Int → String 的唯一转换点。
  「控制器与视图之间传的是字符串，不是数字」这句话的最小落点就在这里：
  **数字要说什么话，由控制器那一行决定**。

## §19 第 2 种·KVO：观察者是注册上去的，不是写在那三行之后的

KVO 与本章的关系很直接：它让「改了 `score`」这件事能被**别人**看见，控制器不需要知道谁在看。
代价是属性必须先暴露给 Objective-C 运行时 —— 这就是 `QuizViewController` 里那行
`@objc dynamic var score` 存在的全部理由（第 27 章讲的 isa-swizzling 就发生在这类属性上）。

```swift
@objc dynamic var score: Int = 0          // 主线里的声明

let kv = QuizViewController()
kv.loadViewIfNeeded()
var kvoHits: [String] = []
let token = kv.observe(\.score, options: [.old, .new]) { _, change in
    kvoHits.append("\(change.oldValue ?? -1)→\(change.newValue ?? -1)")
}
kv.score = 1
kv.score = 2
```

```
== §19 第 2 种·KVO：观察者是注册上去的，不是写在那三行之后的 ==
  ok   注册观察者之后、任何操作之前：命中 0 次 —— 出厂那次 score=0 的赋值发生在 init 里，和 §3 的 didSet 一样不在观察范围内
  ok   两次赋值两次命中，且 oldValue/newValue 都拿得到（0→1 1→2）—— 这里没有任何一句 updateUI，改动是被运行时「通知」出去的
  ok   点一次按钮：手动那一路照常记到 updateUI（1 次），KVO 那边同时多命中 1 次（现在 3）—— 两种机制会**同时**成立，于是同一处界面更新可能被喂两遍：这就是「通知机制只能选一种当主线」的实际理由
  ok   token.invalidate() 之后 score 照样变（现在是 99），可观察者一条都不收（仍是 3 条）—— 观察是有寿命的：注册方负责取消，否则它比被观察的对象活得久就是悬垂（§20/§22 各有一种更隐蔽的形态）
```

- **「代价」这两个字要说准**：编译器**并不拒绝**少写 `@objc dynamic` 的版本。
  探针 e06 抄到的是一条 warning（`passing reference to non-'@objc dynamic' property 'score'
  to KVO method 'observe(_:options:changeHandler:)' may lead to unexpected behavior or
  runtime trap`），**编译退出码 0**；而探针 r05 把这句话的后半跑完了：真的走到注册那一句
  就当场 trap（`Foundation/NSObject.swift:132: Fatal error: Could not extract a String from
  KeyPath \PlainQuiz.score`，退出码 132）。所以这条限制不是编译期给的，是运行时给的 ——
  而那条 warning 在本仓库判定 1 这里同样是硬失败，这与 §30 讲 OC 混编时会再遇到的
  「黄色叹号在这里不许进来」是同一件事；
- **第一条断言与 §3 是同一个现象的两种机制**：注册之后命中 0 次，因为出厂那次赋值发生在
  `init` 里。Swift 的 `didSet` 和 OC 运行时的 KVO 在「初始值算不算一次变化」上给了同一个答案，
  这不是巧合，是「观察者挂在已构造完成的对象上」这一件事的两种写法；
- **第三条是这一节最实用的一条**：`kv.answerPressed(…)` 一次点击同时记到 `updateUI`（1 次）
  和 KVO（第 3 条命中）。两种机制会**同时成立**，于是同一处界面可能被喂两遍。
  「通知机制只能选一种当主线」这句话的实际理由就是这个，而不是风格；
- **第四条给出取消的责任方**：`token.invalidate()` 之后 `score` 照样变（99），可观察者一条
  都不收。观察是有寿命的，**注册方负责取消**。这一条在 §20 有一种更隐蔽的形态
  （注册在全局中心上的观察者忘了摘就永远摘不掉），在 §22 有第三种（闭包连同捕获的东西一起
  被环养着）。

## §20 第 3 种·NotificationCenter：post 是同步的，而发送方不认识接收方

```swift
let center = NotificationCenter.default
var ncHits: [String] = []
let observer = center.addObserver(forName: .init("QuizScoreChanged"), object: nc, queue: nil) { note in
    ncHits.append("\(note.object is QuizViewController ? "同一位" : "不是这位"):\(note.userInfo?["score"] ?? "?")")
}
nc.score = 5                                                   // 改了属性，没人 post
center.post(name: .init("QuizScoreChanged"), object: nc, userInfo: ["score": nc.score])
center.post(name: .init("QuizScoreChanged"), object: QuestionBank(), userInfo: nil)
center.removeObserver(observer)
center.post(name: .init("QuizScoreChanged"), object: nc, userInfo: ["score": 7])
```

```
== §20 第 3 种·NotificationCenter：post 是同步的，而发送方不认识接收方 ==
  ok   改了 score 而没人 post：命中 0 条 —— 这一种和 KVO 的**根本**差别在这儿：KVO 挂在属性上，赋值即通知；通知中心挂在「有人显式 post」上，忘 post 就一个字都不会响
  ok   post 之后同一行代码里就能读到命中（同一位:5）—— 默认 queue=nil 时 post 是**同步**的：不发到别的线程去，谁 post 谁就把观察者跑完再回来，所以「post 返回」等于「视图已经更新完」
  ok   换一位发送者（object 传一个 QuestionBank）、连 userInfo 都不给：观察者一条都不收（还是 1 条）—— object 是**过滤条件**，不是文档；这一格填错的表现和 §17 那句「静默」一模一样：不报错，就是不响
  ok   removeObserver 之后再 post：命中不增加（1 条）—— 和 §19 的 invalidate 同一个道理，只是这一种的注册在**全局**的中心上：忘了摘，观察者连同它捕获的东西一起永远摘不掉（§22 的闭包那一节会当场看到后果）
```

四句断言其实是一句结论的四个面：**这一种机制的每一次失效都是「不响」，从不报错**。

- **改属性不通知**（第一条）。这是 KVO 与通知中心的**根本**差别，也是很多人从 KVO 迁到
  通知中心后第一批 bug 的来源：KVO 挂在属性上、赋值即通知；通知中心挂在「有人显式 post」上，
  忘 post 就一个字都不会响；
- **post 是同步的**（第二条）。`queue: nil` 时谁 post 谁就把观察者跑完再回来，
  所以「post 返回」等于「视图已经更新完」。这一条在同一行代码里就能读到（命中数组当场
  非空），不需要等下一个 runloop —— 这也是为什么本章把它放在「手动」之后第二位讲：
  行为上它和 `updateUI()` 一样即时，区别只在「谁决定要叫」；
- **`object` 是过滤条件，不是文档**（第三条）。传了一个别的对象当 `object`，观察者一条都不收。
  这一格填错的表现和 §16/§17 那句「静默」一模一样：不报错，就是不响。
  和第 31 章那条「outlet 名写错是运行期异常」相比，通知中心这一族要更安静得多；
- **注册在全局中心上的观察者，忘了摘就永远摘不掉**（第四条）。`addObserver(forName:object:queue:using:)`
  交回的是一个 `NSObjectProtocol` token，必须显式 `removeObserver`；它连同闭包捕获的一切
  一起被中心持有。§22 会当场看到后果（那条环）。

## §21 第 4 种·代理：谁持有谁，写在两行声明里

代理是 UIKit 用得最多的机制（第 22 章的 `UIScrollViewDelegate` 就是它）。**书里的小测验一个
代理都没有** —— 它只有手动那一种。这一节拿一个同形的控制器（`Presenter.swift` 里的
`DelegatedQuiz`）补上，量三件事：回调什么时候到、代理断了会怎样、Swift 的「可选方法」和 OC 的
差在哪。

```swift
protocol QuizDelegate: AnyObject {          // AnyObject 是硬要求：代理必须是引用类型
    func quiz(_ quiz: DelegatedQuiz, didAnswer index: Int, correct: Bool)
    func quiz(_ quiz: DelegatedQuiz, didFinishWithScore score: Int)
}

extension QuizDelegate {                    // Swift 的「可选方法」= 协议扩展给一份默认实现
    func quiz(_ quiz: DelegatedQuiz, didAnswer index: Int, correct: Bool) {
        Trace.log.append("协议扩展的默认实现：didAnswer \(index)")
    }
}

final class DelegatedQuiz {
    weak var delegate: QuizDelegate?        // 必须是 weak，否则两边互相持有
    …
}
```

```
== §21 第 4 种·代理：谁持有谁，写在两行声明里 ==
  ok   答第一题：didAnswer 这个方法 recorder 一个字都没写，可它照样被调到了（Trace 里有 1 条「协议扩展的默认实现：didAnswer 0」）—— Swift 的「可选方法」是**编译期**给了一份默认实现，调用照发；OC 的 @objc optional 是**运行期**查表，没实现就根本不发消息（第 27 章）。表现一样，出事的地方不一样
  ok   三题跑完（最后一题答完游标出界）：didFinishWithScore 只在越界那一次被叫到，收到 1 次、分数 3 —— 代理的价值就在这儿：控制器**不知道**外面有几个人、叫什么名字，它只按协议问一句
  ok   delegated.delegate 与 recorder 是同一个对象（===）—— 这一句看着普通，却是本章唯一一处 UIKit 式写法：属性声明成 weak（Presenter.swift 里那句），等下 §22 会给出如果没有 weak 的下场
  ok   把代理对象放掉（recorder = nil）之后 delegate 自己变成 nil，再答一题：Trace 一条都没多（3 → 3）—— weak 属性归零、回调静默消失，不崩也不报错。UIKit 里「代理忘了设」的全部症状就是这一条：界面照常能动，只是没人收尾
```

- **`FinishRecorder` 只实现了 `didFinishWithScore` 那一个方法**，`didAnswer` 一个字没写，
  可它照样被调到 —— 落到的是协议扩展那份默认实现。这一格是和 OC 的关键区别：
  `@objc optional` 是运行期用 `respondsToSelector:` 查表，**没实现就根本不发这条消息**
  （第 27 章量过这张表）。两种写法表现一样（「可选」），出事的地方不一样：
  Swift 这一种调用发生了、只是做了默认的事；OC 那一种调用根本没发生；
- **`protocol QuizDelegate: AnyObject` 不是风格**：代理必须是引用类型，不然 `weak` 无从谈起
  （值类型无法被弱引用）。这一条与 §6 那个 class/struct 分岔是同一件事的两端；
- **第三条那句 `===` 看着普通，它是本章唯一一处 UIKit 式写法**（`weak var delegate`）。
  它存在的理由由 §22 给出反面；
- **第四条是 UIKit 里「代理忘了设」的全部症状**：把代理对象放掉之后 `delegate` 自己变成
  `nil`，再答一题，`Trace` 一条都没多（3 → 3）。**不崩、不报错、界面照常能动，只是没人收尾**。
  这一格是本章四条「静默」里最典型的一条，也是排查「为什么 didFinish 没被叫到」时唯一能靠的
  读数：读那个 weak 属性是不是 nil。

## §22 第 5 种·闭包：把「之后要做的事」存成一个属性，代价是它连对象一起存

书 7.9 正文专门讲过：handler 参数给的「不是值也不是对象，而是一段代码」，
「因为闭包有其独立的生存期……所以在闭包之中需要使用 self 关键字指明要执行当前类中的
`startOver()` 方法」。这段话的账，量出来是下面五条。

这一节的判据换一个：不是「用内存工具看一眼」，而是「**函数返回之后那个 weak 变量还是不是
nil**」—— 它是可打印、可断言、`-Onone` 与 `-O` 必须给同一个答案的形态（ARC 不做环检测，
这一条不依赖优化级别，也不依赖时机）。

```swift
let cb = CallbackQuiz(list: Array(bank.list.prefix(3)))
var hits: [Int] = []
cb.onScoreChanged = { value in hits.append(value) }
cb.onFinish = { value in hits.append(1000 + value) }
weak var weakCB = cb

weak var cycleProbe: CallbackQuiz?
func makeStrongCapture() {
    let quiz = CallbackQuiz(list: Array(bank.list.prefix(3)))
    quiz.onFinish = { _ in quiz.label.text = "闭包替我把对象养着" }   // 强捕获 quiz
    cycleProbe = quiz
    quiz.onFinish?(0)
}
func makeWeakCapture() {
    let quiz = CallbackQuiz(list: Array(bank.list.prefix(3)))
    quiz.onFinish = { [weak quiz] _ in quiz?.label.text = "弱捕获：抓不住也不报错" }
    weakCaptureProbe = quiz
    quiz.onFinish?(0)
}
```

```
== §22 第 5 种·闭包：把「之后要做的事」存成一个属性，代价是它连对象一起存 ==
  ok   闭包这一种**答完就响**：第 1 题答对，onScoreChanged 收到 [1] —— 和 §20 的通知中心一样是同步的，但不需要全局 center，也不看 object 过滤
  ok   三题跑完（第 2 题答错，因为屏幕上那题的正确答案是「否」）：[1, 2, 1002] —— 前两个是每次加分给的，末尾那个 1002 是 onFinish 给的「总分 2」。书 7.9 把这两种合成了一处：弹窗上那颗「重新开始」按钮的 handler 就是一个闭包属性（§24/§25 再把它拆开）
  ok   这两条闭包只抓了主线里的 hits，没有反过来抓 cb：对象仍归主线持有（weak 读回还在）；而控制器的账本从 3 条到 3 条一条没多 —— 闭包这一种**不在任何账本上留痕**，回调发生在谁身上、发生了几次，全靠读那个被捕获的数组。这是它比手动 updateUI 更难查的地方
  ok   把闭包写成强捕获（书 7.9 的 self 就是这个形状）：函数一结束，外部最后一条强引用没了，对象却还活着（weak 读回 非 nil）—— quiz 抓着闭包、闭包抓着 quiz，环上的计数永远不归零；ARC 只数引用，不做环检测
  ok   同一处换成 [weak quiz]：函数一结束就释放干净（weak 读回 nil）—— 书 7.9 那句「因为闭包有其独立的生存期……所以必须写 self」讲的是**编译器为什么要求你写 self**，而它顺手埋下的正是上面那个环：写了 self 就写死了强捕获
```

- **前两条给的是「闭包作为通知机制」的行为**：答完就响、同步、不需要全局中心、
  不看 `object` 过滤。`[1, 2, 1002]` 这三个数里，1002 是「总分 2」加了偏移，
  为的是让「每次加分」和「最后一次完成」在同一根数组里可分辨 —— 这一节没有别的读数口；
- **第三条是这一种机制最贵的一条结论**：`Trace.log` 从 3 条到 3 条，**一条都没多**。
  闭包回调不在任何账本上留痕，「回调发生在谁身上、发生了几次」全靠读那个被捕获的数组。
  这是它比手动 `updateUI()` 更难查的地方 —— §18 那本账在这一种机制上完全不工作；
- **第四条量的就是书 7.9 那句话的形状**：`makeStrongCapture()` 一返回，外部最后一条强引用
  没了，可 `cycleProbe`（weak）读回**非 nil**。`quiz` 抓着 `onFinish`、`onFinish` 里的
  `quiz` 又抓着 `quiz`，环上的计数永远不归零。**ARC 只数引用，不做环检测**；
- **第五条换成 `[weak quiz]`，函数一结束就释放干净**（weak 读回 `nil`）。
  书 7.9 那句「因为闭包有其独立的生存期……所以必须写 self」讲的是**编译器为什么要求你写
  `self`**（逃逸闭包不能隐式捕获），而它顺手埋下的正是上面那个环 —— 写了 `self` 就写死了
  强捕获。这一对断言（非 nil / nil）用的是同一个判据、只差捕获列表一行，
  这就是本章为什么要用 weak 变量而不是内存工具。

`UIAlertAction` 的那个 handler 是这一族的实例，而它在本章有两个额外麻烦：读不回来（§25），
以及造出它的那个对象是 UIKit 工厂方法给的 —— 于是那条环从两方变成三方，
而「什么时候真的被收」这件事也不再由引用计数单独回答了。下一节就量这两件事。

## §23 书 7.5 那句「永远不会直接发生联系」的边界：纪律，不是机制

7.5 的原文是「数据模型与视图永远不会直接发生联系」。§12 证的是**默认情形**（不喂就不动）。
这一节证另一面：在 OC 运行时面前，这句话没有任何强制力 —— KVC 一句 `setValue` 就跨过去了。

```swift
let kvc = QuizViewController()
kvc.loadViewIfNeeded()
Trace.reset()
kvc.questionLabel.setValue("Model 直接写进视图的一行", forKey: "text")   // 绕过 updateUI
let readBack = kvc.value(forKey: "score") as? Int                        // 反方向
expect(kvc.responds(to: Selector(("setScore:"))), "…")
```

```
== §23 书 7.5 那句「永远不会直接发生联系」的边界：纪律，不是机制 ==
  ok   对 label 用 KVC 写 text，读回来是「Model 直接写进视图的一行」—— 没有 updateUI、没有 nextQuestion，视图照样变了
  ok   而这一整节的 Trace 是空的（0 条）：控制器的账本上**根本看不见**这次更新 —— 「视图被谁改了」这件事，一旦允许绕过控制器，就再也数不出来了。这就是那句话的真实分量：它保证不了，只能守
  ok   反过来也通：从视图外侧用 KVC 读控制器的 score（Optional(0)，直接读是 0）—— Model、Controller、View 之间没有围墙，只有方向约定（第 27 章量过 KVC 这套约定的代价：key 拼错是运行期的事）
  ok   KVC 之所以能写进来，是因为 score 被声明成了 @objc dynamic（§19 那句）：它在 OC 运行时里有 setScore: 这个 setter（responds=true）—— 「暴露给 KVO」和「暴露给 KVC」在运行时里是同一件事，分层要多薄就有多薄，全在声明那一行
```

- **第三条那句 `Optional(0)` 不是排版**：`value(forKey:)` 交回 `Any?`，
  用 `String(describing:)` 打印非 String 的可选就长成这样。本章保留它，因为它正是
  「KVC 这条路没有类型」的直接读数（第 30 章 §18 讲可选盒子时量过同一种打印）；
- **第四条把 §19 与 §23 焊在一起**：`@objc dynamic` 让 `score` 在 OC 运行时里有了
  `setScore:` 这个 setter，于是它同时暴露给 KVO 和 KVC。「暴露给运行时」是一个开关，
  不是两件独立的事 —— 分层要多薄就有多薄，全在声明那一行；
- 这一节给出的不是建议而是**边界的位置**：MVC 那句话在 Swift/OC 运行时里**没有任何强制力**。
  它的成立只有两个来源 —— 约定（谁都不写那句 `setValue`）和账本（`Trace` 这种「谁被叫到」的
  记录）。而第二条断言说的正是：一旦允许绕过，连账本也数不出来。
  第 27 章量过这套约定的代价（key 拼错是运行期的事：`NSUnknownKeyException`），
  这一节量的是它的**无防**：key 写对的时候，墙根本不在。

## §24 把「弹出一个警告窗口」换成可读的对象

书 7.9 的判据是一整句话加一张图：「构建并运行项目，当用户答完最后一道题之后，会弹出一个
警告窗口，如图 7-17 所示」。本章没有窗口，于是把那句话拆成四问 —— **弹的是什么**（哪种样式）、
**上面写了什么**（title 与 message）、**有几颗按钮**（actions 数组）、**点了会怎样**（handler）。
前三问这一节量，第四问交给 §25。

```swift
Trace.reset()
let alerting = QuizViewController()
alerting.loadViewIfNeeded()
for _ in 0..<12 { alerting.answerPressed(alerting.noButton) }   // 12 次都在合法区间里
expect(alerting.alert == nil && Trace.log.filter { $0.hasPrefix("弹框") }.isEmpty, "…")
alerting.answerPressed(alerting.noButton)                        // 第 13 次：游标推到 13
let gotAlert = alerting.alert
// 读的是 UIAlertController 这四个字段：preferredStyle / title / message / actions
```

```
== §24 把「弹出一个警告窗口」换成可读的对象：title / message / actions / preferredStyle ==
  ok   前 12 次点击（游标现在 12）：弹窗对象还是 nil，Trace 里也没有「弹框」那笔 —— 弹窗是 else 分支的产物，合法区间一次都不会碰它
  ok   第 13 次点击之后 presentFinishedAlert 造出了对象：title=「了不起！」、preferredStyle=1（alert=1 / actionSheet=0）—— 书里那句「警告窗口」在代码里就是这几个字段
  ok   message 逐字对得上书 7.9 的那一行（「你已经完成了所有的题目，是否想重新开始呢？」）—— 这一条是给「界面文案也要有判据」准备的：原书靠看图，本章靠读回字符串
  ok   actions 有 1 项、第一项标题「重新开始」、style=0（default=0）—— 书里只加了一颗按钮，所以这个数组长度本身就是一条规格
  ok   可 `present(alert, animated: true, completion: nil)` 那句的效果是空的：presentedViewController=nil、view.window=nil —— 第 22 章量过「在没有窗口的 VC 上 present 不生效」，这一节把它当成前提用：弹窗的**内容**可读，弹窗的**出现**不可，所以本章判的是内容
  stderr 在这一步也没有任何东西（第 22 章那条实测在这里同样成立：不生效 ≠ 报错）
```

- **第一条先把「弹窗什么时候该出现」钉住**：连点 12 次之后 `alert` 还是 `nil`，
  `Trace` 里连「弹框」那一笔都没有。这不是多余的断言，它排除的是一个常见误读 ——
  「跑到最后弹了个窗」听起来像流程的自然结果，代码里它是 `nextQuestion()` 那个 `else` 分支
  的产物，而分支的条件是 §9 那道守卫。守卫没放开的时候，弹窗这条路径一次都没被走过；
- **第二条把「警告窗口」这四个字翻译成字段**：`UIAlertController.Style` 有两个值，
  `alert` 的 rawValue 是 1、`actionSheet` 是 0（这一行把两个数都打出来了，免得读者去猜）。
  书 7.9 步骤里那句「Alert 控制器样式选择 Alert」在代码里就是这一个枚举值，读回来是 1；
- **第三条是本章判据的换法本身**：原书靠看图确认文案，这里靠 `gotAlert?.message == "…"`
  逐字比。为什么值得为一句文案写一条断言？因为 message 是**唯一的**「答完了」这件事对用户
  的说明，而它是手写字符串 —— 手写的字面量没有类型，改错了编译器不会说话。第 31 章量过
  故事板里同类文案的另一种命运（改了 xib 不改代码，编译器同样不知道）；
- **第四条把弹窗当成规格来读**：`actions` 是个数组，长度 1 就是「屏幕上只有一颗按钮」，
  `style` 读回 0 就是 `UIAlertAction.Style.default`（`UIAlertAction.Style.default.rawValue`
  打在同一行里，两个数都是现读的）。
  书里只加了一颗按钮，所以数组长度本身可以当断言用 —— 这是「界面结构」唯一能被读回来的
  那种形式：**数量**，不是长相；
- **最后一条是本章的边界声明**：`present(_:animated:completion:)` 调了，而且调用本身成功了
  （没崩、没报错、stderr 空），但 `presentedViewController` 是 `nil`、`view.window` 也是 `nil`。
  第 22 章量过这条：没有窗口的视图控制器 present 不生效。这一节把它当**前提**用 ——
  弹窗的内容可读、弹窗的出现不可读，所以本章判的全是内容。
  「不生效 ≠ 报错」那句要再读一遍：这一格里 stdout 有五条 ok，stderr 一个字都没有。
  真实 App 里「弹窗不出现」这类 bug 的读数长相就是这样 —— **什么都没发生，包括错误**。

## §25 UIAlertAction 的 handler 读不回来，所以本章存了一份闭包

书 7.9 步骤 3 那句「在 Action 的 handler 里调用 startOver()」是全章第一个**闭包**，
而它在这台机器上有两个麻烦：一是从 `UIAlertAction` 上读不回来，二是那句「必须写 `self`」
造出一个三方环。这一节把这两件事分开量。

先看第一个麻烦。探针 e07 把 `UIAlertAction` 上那几个公开属性挨个读了一遍，
想顺手读 `handler`：

```
--- swiftc 输出 ---
/var/folders/…/iosdev32probes/main.swift:21:14: error: value of type 'UIAlertAction' has no member 'handler'
19 | print(action.title ?? "nil")
20 | print(action.isEnabled)
21 | print(action.handler)
   |              `- error: value of type 'UIAlertAction' has no member 'handler'
swiftc 退出码 = 1
（编译未通过：不运行）
```

编译器原文就是这么直白：`handler` 不是它的公开属性（`UIAlertAction` 对外只有
`title`、`style`、`isEnabled`）。于是主线在**造** `UIAlertAction` 之前先把那段闭包存了一份
在控制器属性上（`QuizViewController.swift` 里的 `restartHandler`），递给 UIKit 的是同一个值：

```swift
let block: (UIAlertAction) -> Void = { _ in
    Trace.log.append("handler：重新开始")
    self.startOver()
}
restartHandler = block
let restartAction = UIAlertAction(title: "重新开始", style: .default, handler: block)
```

```
== §25 UIAlertAction 的 handler 读不回来，所以本章存了一份闭包：调它 = 点那颗按钮 ==
  ok   按钮对象上读得到标题（「重新开始」），读不到闭包 —— handler 不是 UIAlertAction 的公开属性（原文见探针 e07），所以本章在造它之前先存了一份（存的是同一个值）。这不是绕开书：递出去的和存下的**是同一个闭包值**，调哪一份跑的都是同一段代码
  ok   调一次那份闭包：游标 13→0、分数 7→0 —— 这是 startOver() 的效果，它是**闭包**干的事，不是 UIAlertController 干的
  ok   屏幕也回到了第 1 题（「吃烧烤不能喝啤酒…」）：handler 里那句 self.startOver() 连 nextQuestion() 一起走 —— §11 的修法和 §25 的这段闭包是同一段代码，本章两次读到它
  ok   Trace 上多了一条「handler：重新开始」（1 条）—— 判据从「图上有个窗口」换成了「这个闭包被调到、它改了这四个值」
```

- **第一条要说清「这不是绕开书」**：`restartHandler` 和递给 `UIAlertAction(title:style:handler:)`
  的那个参数是**同一个闭包值**，不是两份代码。所以「调这份」和「用户点那颗按钮」跑的是同一段
  `startOver()`。这一句很重要，因为读代码的人看到属性上存着闭包，容易以为它是测试专用的替身；
- **第二条把责任分开了**：`游标 13→0、分数 7→0` 是 `startOver()` 干的，而 `startOver()` 在闭包里。
  `UIAlertController` 从头到尾没改过一个状态 —— 它是容器，闭包才是行为。
  「弹窗自己会重新开始」是界面直觉里最容易出现的一种错账，这一条断言就是防它的；
  注意分数是 7 不是 13：连点 `noButton` 十三次，答对的是「答案为否」那 7 道题
  （§31 那条 `trueCount` 读回这份库有 6 道题答案是「是」，13 − 6 = 7）；
- **第三条接到 §11**：`questionLabel.text` 回到了题库第一题。书 7.9 修的那个 bug
  （重置了状态却没更新界面）之所以在这里不用修，是因为 `startOver()` 里那句 `nextQuestion()`
  —— §11 量的是**没有**这一行的那一版。本章两次读到同一段代码，一次通过属性、一次通过闭包；
- **第四条是判据换法的落点**：原来那句话是「图上有个窗口」，现在是「这个闭包被调到，
  并且它改了游标、分数、label、进度文字这四个值」。前者不可复现（要人眼看图），
  后者是可数的（`Trace.log.filter { $0.hasPrefix("handler") }.count == 1`）。

### 那个环是三方形的

书 7.9 里有一句提醒：handler 闭包里访问 `self` **必须显式写**。这一节量它的代价。

```swift
weak var escaped: QuizViewController?
func makeAndRelease() {
    let vc = QuizViewController()
    vc.loadViewIfNeeded()
    for _ in 0..<13 { vc.answerPressed(vc.noButton) }   // 最后一次越界 → 造弹窗、挂 handler
    escaped = vc                                        // 主线只留一条**弱**引用
}   // vc 这条强引用到这儿就该结束了
makeAndRelease()
```

```
  ok   函数一返回，局部强引用没了，可弱引用还指着对象（还在）—— 控制器抓着 alert、alert 抓着 UIAlertAction、handler 里那句 self 又抓着控制器：§22 那个环在这一处是**三方**的，而它的起点就是本章为了能读回弹窗内容而多加的那个属性（书里的 alert 是个局部变量，函数一结束只剩 UIKit 自己那份引用，dismiss 就全清了）
  ok   releaseAlert() 之后两个属性都读回 nil（alert=nil、restartHandler=nil）—— 环**确实**断了：控制器不再抓着弹窗，也不再抓着那段闭包
```

- **为什么必须写 `self`**：闭包如果会**逃逸**（这里它存在属性上、递给了 UIKit，
  一定在 `presentFinishedAlert()` 返回之后才被调用），编译器就要求它用到的每一个实例成员
  都写明来自谁 —— `startOver()` 这种不带接收者的写法在逃逸闭包里过不了编译，
  必须写成 `self.startOver()`。而这一句 `self` 就是在闭包里存了一条指向控制器的强引用，
  ARC 的账本上多出一条边。同族的另一条诊断在探针 e04 里：
  「`'self'` captured by a closure before all members were initialized」——
  那里的问题是**抓的时机**（属性还没初始化完就抓），这里是**抓了谁**，两条都要认得；
- **三条边的形状**：`vc.alert → UIAlertController → [UIAlertAction] → handler → vc`。
  §22 那个是两方（对象↔自己的闭包属性），这一处是三方，而且中间那一方是 **UIKit 造的对象**。
  「中间那一方不是你 `new` 出来的」这个区别，就是下面那条「回收时机」的全部来源；
- **第二条的断环写在哪一行**：`releaseAlert()` 只做两件事 —— `alert = nil`、`restartHandler = nil`。
  两条边都断掉，环就不成环了。这一格读的是两个属性都归 `nil`，**没有**读「对象被收了」。
  这不是本章偷懒，理由在下面。

### 「断环」和「当场回收」是两件事

探针 `c01_dealloc_timing.swift` 把同一句「把两条属性置空」放进七种位置里，各用
`-Onone` 和 `-O` 编一遍、跑一遍。写这一支探针的最初动机是一个想当然：
「断环之后弱引用就该当场变 nil，而这件事大概会随优化等级变」。
**实测把它否了**，两份 stdout 逐字一致，真正在起作用的另一个变量露出来 —— 池子的层次。

```
[5] 正主线的形状：UIViewController + UIAlertController（UIKit 工厂方法）+ 抓 self 的 handler
    函数返回后：weak=还在（q→alert→action→handler→q）
    顶部作用域 release 之后：weak=还在
    换成包在函数里 release 之后：weak=还在
[6] 同样的 release，外面包一层 autoreleasepool：
    进池之前：weak=还在
    池子退出之后：weak=还在
[7] 连**创建**都放进池子里（书里那个 alert 就是这种：局部变量 + 一次 release 全清）：
    创建函数返回后：weak=还在
    断环 + 池子退出之后：weak=nil
```

（上面这三格是 debug 那一份的输出；release 那一份从头到尾一个字都没差，
 完整两份都在本文末尾的「探针记录」里。）

主线因此照 [7] 的写法测最后那一格：

```swift
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
```

```
  换成 c01 [7] 的写法（创建也放进 autoreleasepool）：函数返回后 weak=还在（环还在，所以「还在」这一格两种配置都一样）
  ok   断环 + 池子退出之后 weak=nil —— 这才是一条配置无关的「回收」判据：你控制不了对象被 autorelease 进哪一层池子，能控制的是**在池子的边界上**断环
```

- **[5] 那三行是本节的主证据**：把 `alert = nil; restartHandler = nil` 这一句写在
  顶部作用域、包进函数、再外面套一层池子 —— 三种写法读回来都是「还在」。
  环确实断了（§24 那两条属性都空了，前面已经断言过），对象却没被收；
- **[7] 与前三种的差别只有一处**：`let vc = QuizViewController()` 那一句也在池子里。
  也就是说，把对象**造出来**时所在的池子层次决定了它什么时候真的被收，
  把**置空**那一句挪进挪出池子都不管用；
- **为什么创建位置会管事**：`UIAlertController(title:…)`、`UIAlertAction(title:…)` 这类
  Cocoa 工厂方法给回来的对象按约定会被 `autorelease` 进**当时最内层**那层池子。
  主线在 `makeAndRelease()` 里造它，外面没有可辨认的池子边界，于是归掉它的时机交给运行时
  自己那几层池子；[7] 里创建与断环都在同一层可辨认的边界内，池子退出时那一份引用一起走。
  **ARC 的引用计数一次都没数错**，变的只是池子的边界；
- **两种配置读数一致这件事本身值得记一笔**：它把「这是编译器优化造成的」这个第一反应排除了。
  凡是写「忘了写 `self` 会导致内存泄漏」这类结论的地方，都值得用这个读数复核一遍 ——
  泄漏的**必要条件**是环，而回收的**时机**不由环单独决定，也不由 `-O` 决定。
  所以本章的判据写成「断环 + 池子退出之后 weak=nil」，并把这句话叫作一条**配置无关**的判据：
  这一句是量出来的，不是推出来的。

## §26 书 7.13 的第二条产品线：两个数组、tag 减一、以及「最大 EQ 为 154 分」

书第 7 章的最后一节（7.13「挑战：制作情商测试应用」）是原书留给读者的作业，
也是这一章的第二个完整可运行程序。它和 7.6~7.11 那台状态机的关系是
**同一套骨架换了一个 Model**，差别一共六条，全在 `EQTestViewController.swift` 里：

- `Question` 多了两个数组属性（`questionOption`、`questionScore`），答案不再是一个 `Bool`；
- 题库从 13 题变成 29 题；
- 屏幕上三颗按钮，Inspector 里的 tag 依次填 1、2、3；
- 判卷从「对/错加一分」变成 `score = score + list[questionNumber].questionScore[pickedAnswer]`；
- 答完弹的不是「是否重新开始」，而是按分数区间给的四种 EQ 结论；
- 重置沿用 7.9 那一段。

`EQTestViewController.swift` 顶部注释里那句「书 7.5 那句话到底值多少，就体现在这个文件里有
几处 29 是被写死的」，量的落点在 §29。这一节先把**数字**清点出来。

### 题库的形状：两份数组，没人强制它们对齐

```swift
final class Question {
    let questionText: String
    let questionOption: [String]     // 「是的」「不一定」「不是」
    let questionScore: [Int]         // 6 / 3 / 0 —— 和上面那份**一一对应**
}
```

书 7.13 步骤 2 末尾有一句警告：「questionOption 和 questionScore 这两个数组的元素个数必须
一致，否则会超出数组范围，导致应用程序崩溃」。这一节把这句话量成一条可数的断言。

主线还要能「整轮跑完」，所以有两个辅助函数：

```swift
/// 按给定的选项下标序列把一整轮跑完（序列不够长就用最后一项补齐）。
/// 跑完最后一题时游标越界进 else 分支，结论弹窗的内容留在属性上。
func runEQRound(_ picks: [Int], bank: QuestionBankEQ = QuestionBankEQ())
    -> (score: Int, title: String?, message: String?, progressText: String?, barWidth: CGFloat, vc: EQTestViewController)

/// 想要总分 t（必须是 3 的倍数、0 ≤ t ≤ 174），该怎么答？
/// 三档分是 6/3/0，写成 3×(2a+b)，a=选第一档的题数、b=第二档的题数，
/// 令 q = t/3，取 a = max(0, q-29)、b = q-2a，剩下填第三档 —— 一定凑得出来。
func picks(forScore t: Int) -> [Int]
```

`picks(forScore:)` 这个注释里的推导值得停一下，因为 §27 那四条区间边界全靠它喂分数：
每题给 6、3 或 0 分，所以总分一定是 3 的倍数，写成 `3 × (2a + b)`；
想要 `t`，令 `q = t/3`，先尽量用 6 分档（`a = max(0, q - 29)`），剩下的用 3 分档补
（`b = q - 2a`），再剩下的填 0 分档。`0 ≤ t ≤ 174` 且 `t % 3 == 0` 时这个构造一定成立 ——
于是「某个分数可达」这件事在这章不用猜。

```
== §26 书 7.13 的第二条产品线：两个数组、tag 减一、以及「最大 EQ 为 154 分」这句话 ==
  ok   题库有 29 道题 —— 书 7.13 开头那句「这个应用共有29道题，测试时间20分钟，最大EQ为154分」里的第一个数字对得上
  ok   前两题的文本逐字照抄书 7.13 步骤 2 那段 init()（「我有能力克服各种困难。」和「如果我能到一个新的环境，我要把生活安排得：」）；其余 27 题在 GitHub 的初始化项目里、书上没印，这里用「第3题…第29题」占位 —— 本章要量的是那组**数字**和那四个区间，不是那 27 行文字
  ok   每一题的选项个数和分值个数都相等（不一致的有 0 题）—— 书 7.13 步骤 2 末尾那句「questionOption 和 questionScore 这两个数组的元素个数必须一致，否则会超出数组范围，导致应用程序崩溃」说的就是这两个数：它们不是同一份数据，是两份，没人强制它们对齐
  每题最高那一档是 6 分，29 题全取最高档 = 174 分
  ok   于是「最大 EQ」按这份题库算是 174 分，而书上写的是 154 —— 差的不是某一道题的分值，是**整句话的口径**：154 既不是 29×6，也不是 29×3，下面这条更狠
```

- **第一条只做一件事**：把书 7.13 开头那句话里的第一个数字钉死。这句话里有三个数字
  （29 道题、20 分钟、最大 EQ 154 分），这一节把它们一个个对上代码，结果是只有 29 对得上；
- **第二条是本仓库处理「书上有删节」的一贯做法**：原书 7.13 步骤 2 只印了前两题的
  `Question` 构造代码，剩下 27 题让读者去 GitHub 的初始化项目里拿。这里照抄能照抄的，
  其余用「第3题…」占位，**并把这件事写在断言里**，不让它看起来像验证过全题库文本。
  要量的是数字和区间，那 27 行文字不影响任何一条断言；
- **第三条才是那句警告的落点**：`mismatchedCount` 把 29 道题挨个查了一遍两个数组的长度，
  读回 0。请注意这本书的措辞是「必须一致」—— 「必须」两个字在代码里没有任何执行者：
  `Question` 的这两个属性都是独立的 `let`，构造时没人比对，类型系统也看不出关系。
  它是一条**约定**，和 §23 那句「Model 与 View 不发生联系」同样没有强制力。
  违反它的现场在探针 r03（下一节的混排题库正好造一份「选项比分值多」的形状）；
- **第四条那句「每题最高那一档是 6 分」是读回来的**：`eqBank.list[0].questionScore.max()`，
  而 `maxPossibleScore` 是把 29 题各自的最大档累加，不是 `29 × 6` 手算 ——
  这是本章一贯的口径：**用同一份数据算第二遍**，别让结论和源码各写一次。
  于是 174 这个数字是从题库里长出来的，而书上那句「最大EQ为154分」是另外一句话。

### 「154」不只是偏小，它根本拿不到

```
  三种整轮答法：全「是的」→ 174 分、全「不一定」→ 87 分、全「不是」→ 0 分
  ok   全取 6 分得 174、全取 3 分得 87、全取 0 分得 0 —— 三个数都是 3 的倍数，而这不是巧合：每题的三档分是 {6, 3, 0}，任何一轮的总分都是它们的整数组合，结果只能是 3 的倍数（0 到 174 之间的每一个 3 的倍数都取得到，§27 现造分数给下面那四条区间用）
  ok   154 % 3 = 1 —— 所以 154 不只是一个「偏小的最大值」，它连一个**可达的分数**都不是。按这份题库，答到顶是 174，而 154 这一档谁都拿不到。书 7.13 开头那句话里三个数字，只有 29 是对的（「测试时间20分钟」是人的事，代码里不存在）
```

- **这一格是本条产品线最值钱的一处发现，而它只需要一次取余**：`154 % 3 = 1`。
  三档分值都是 3 的倍数，任何一轮的总分必然是 3 的倍数，所以 154 不是「一个偏高的上限」，
  而是**一个不可能出现的分数**。书 7.13 步骤 6 那套结论区间（§27）里最上面那一档写的是
  `score >= 130`，读者按 154 满分去理解它，会以为这段跨度是 24 分，实际是 44 分；
- **注意推理的强度**：「三个数都是 3 的倍数」是三条整轮跑出来的实测；
  「只能是 3 的倍数」是从 `{6,3,0}` 的整数组合性质推的；
  「0 到 174 之间每一个 3 的倍数都取得到」是 `picks(forScore:)` 那个构造给的，
  §27 就是拿它现造 9 个分数去喂那四条区间。**三层各管一件事，谁也没替谁**。

### tag 减一：界面与数据之间的那道焊缝

书 7.13 步骤 4 的那一行是 `pickedAnswer = sender.tag - 1`，而 tag 是故事板 Inspector 里
手填的数字。这一节把这一行量成三格读数。

```swift
@objc func answerPressed(_ sender: UIButton) {
    pickedAnswer = sender.tag - 1
    Trace.log.append("点选：tag=\(sender.tag) → pickedAnswer=\(pickedAnswer)")
    checkAnswer()                       // 读的是**当前**那一题，所以必须跑在 += 1 之前
    questionNumber += 1
    nextQuestion()
}
```

```
  出厂（还没 loadView）：questionNumber=0、pickedAnswer=-1、score=0
  ok   pickedAnswer 的出厂值这里是 -1（书 7.13 没给这一行的初始值，只给了类型）—— 挑 -1 是为了让「一次都没点」在数值上是可辨认的，因为本节下面那条式子会把 tag 减一：没填 tag 的按钮算出来的正是 -1
  三颗按钮的 tag：1 / 2 / 3（书 7.13 步骤 2：故事板 Inspector 里从上到下填 1、2、3）
  ok   loadViewIfNeeded 走完 viewDidLoad 里那句 nextQuestion()：屏幕上第 1 题是「我有能力克服各种困…」、进度文字是「1 / 29」—— 注意这个「1」是 `questionNumber + 1` 来的，游标本身还是 0（§10 那条编号差在 29 题这一版里一模一样）
  ok   点第二颗按钮：`pickedAnswer = sender.tag - 1` 把 tag 2 变成下标 1，score 从 0 走到 3 —— 这一行代码把「界面上的第几颗按钮」和「数据里的第几档分值」焊在一起，焊点是 Inspector 里那个手填的数字
  ok   Trace 上这一笔记的是「点选：tag=2 → pickedAnswer=1」紧跟着「updateUI：1」（这一节之前还有 1 条，是 viewDidLoad 那次出题）—— 顺序就是 answerPressed 里那四行的顺序：定 pickedAnswer、判卷、推游标、更新界面。上一节那条「忘了在 Inspector 里填 tag」在这里是同一个 bug 的第二种形态：tag 出厂是 0，减一得 -1，`questionScore[-1]` 当场越界（原文见探针 r02）
```

- **`pickedAnswer` 的初值为什么是 -1 而不是 0**：书 7.13 只给了类型 `var pickedAnswer: Int`，
  没写初值（原书 7.6 那一版是 `false`）。这里挑 -1 是为了让「一次都没点」在数值上**可辨认** ——
  因为 `sender.tag - 1` 这个式子里，忘了填 tag 的按钮算出来的正好是 -1。
  于是「出厂值」和「填错的下场」撞在同一个数上，这本身就是一个读数；
- **`-1` 越界会怎样，交给探针 r02 现跑现抄**（下一节 §28 的 r03 是同族）：
  Swift 的数组下标检查只有一条消息，负数和超界给的是同一句 `Index out of range`，
  这一点在 §8 已经量过（两个不同的越界动作，读回的 `Fatal error` 完全一样）；
- **第二条那格把「屏幕上的第 1 题」和「游标 0」分开写**：`progressLabel.text` 是
  `"1 / 29"`，而 `questionNumber` 还是 0。§10 在 13 题那一版量过同一个编号差，
  这一处说明它不是笔误而是**写法**：`questionNumber + 1` 是给「从 1 数起的人」看的，
  游标是给数组下标用的。这两个数同时出现在一行字符串里，是本章最容易读错的一格；
- **第三条那句「焊点是 Inspector 里那个手填的数字」是本节的结论**：
  `tag` 是 `UIView` 上的一个 `Int`，编译器、类型系统、故事板都不保证它等于「选项序号 + 1」。
  这条焊缝的两头（界面摆放顺序、题库数组顺序）各自可以改，改一边不改另一边，
  得到的不是错误而是**另一个答案的分**；
- **第四条用 `Trace` 把四行的顺序钉下来**：`点选：tag=2 → pickedAnswer=1` 之后紧跟
  `updateUI：1`。这一条看着琐碎，它防的是 §11 那一族 bug 的镜像写法 ——
  如果 `checkAnswer()` 写在 `questionNumber += 1` 之后，判卷读的就是**下一题**。
  顺序在源码里看得见，在输出里更可数：那一笔前后各是什么。

## §27 四个 `else if` 之间的缝：108/111、129/132 各测一次

书 7.13 步骤 6 给的是四条互不相连的判断，原文一个字符没改（`EQTestViewController.swift`
里 `presentResult()` 那一段）：

```swift
if score < 70 { … }
else if score >= 70 && score < 109 { … }
else if score >= 110 && score < 129 { … }
else if score >= 130 { … }
```

请注意**左边界是 70、110、130，右边界是 109、129** —— 第二、三条之间留着 109 与 110 那道缝，
第三、四条之间留着 129 与 130 那道缝。这类「边界差一个数」的写法最容易漏，
也最难靠看图发现（要跑出一个正好落在缝里的分数才能看见）。
**缝要不要紧，取决于有没有一个可达的分数正好掉在缝里** —— §26 那条「都是 3 的倍数」
在这里正好用上：`picks(forScore:)` 现造 9 个分数，把每一条边界两侧各喂一次。

```
  总分   0（3 的倍数，可达）→ title=「你的EQ较低」message 长度 108
  总分  69（3 的倍数，可达）→ title=「你的EQ较低」message 长度 108
  总分  72（3 的倍数，可达）→ title=「你的EQ一般」message 长度 69
  总分 108（3 的倍数，可达）→ title=「你的EQ一般」message 长度 69
  总分 111（3 的倍数，可达）→ title=「你的EQ较高」message 长度 60
  总分 126（3 的倍数，可达）→ title=「你的EQ较高」message 长度 60
  总分 129（3 的倍数，可达）→ title=「」message 长度 0
  总分 132（3 的倍数，可达）→ title=「你就是个EQ高手」message 长度 33
  总分 174（3 的倍数，可达）→ title=「你就是个EQ高手」message 长度 33
```

这张表里只有一格是坏的，而它坏得很安静。逐条看断言：

```
== §27 四个 else if 之间的缝：108/111、129/132 各测一次，其中一格没人接 ==
  ok   70 那道缝两侧：69 分 →「你的EQ较低」，72 分 →「你的EQ一般」—— 因为可达分数只落在 3 的倍数上，`< 70` 和 `>= 70` 之间根本没有整数分数会被漏掉，这条缝是无害的
  ok   109/110 那道缝两侧：108 分 →「你的EQ一般」，111 分 →「你的EQ较高」—— 书里写的是 `< 109` 和 `>= 110`，中间的 109 谁也接不到，可 109 不是 3 的倍数，这道缝同样落不到任何人身上
  ok   而 129 分（= 3 × 43，答法：14 题「是的」+ 15 题「不一定」）是**可达**的，它正好掉在 `< 129` 和 `>= 130` 之间：title=「」、message=「」，两个都是空串 —— 书 7.13 步骤 6 那行 `var title = ""` 的初值在这里第一次真的被用上了
  掉进缝里的那一轮，Trace 记的是「结论：（四个区间都没接住）」—— 程序不崩、按钮照常、弹窗照弹，只是上面一个字都没有
  这一格里还有一条 UIKit 的小事实：空串递进 UIAlertController 之后读回来是 Optional("")，也就是**空串**而不是 nil —— 「这个弹窗有 title 字段、它是空的」和「它没有 title」在 API 上是两回事（第 31 章量过 UILabel 那一侧的同一区分）
  ok   132 分往上就有人接了：「你就是个EQ高手」—— 所以这条缝是**一条缝**而不是**一堵墙**：129 一个人掉下去，130 以上（这里指 132）全都好好的
  ok   空弹窗也仍然带着那颗按钮：actions=1 项、标题「重新开始」—— 用户看到的是「一个空白框 + 重新开始」，而 §24 那条规格（actions 有 1 项）在这一格照样成立：区间漏了，流程没漏
  ok   满轮下来（全答第一档）分数 174、结论「你就是个EQ高手」，message 逐字对得上书 7.13 步骤 6 的第四段 —— 这一条是给「界面文案也要有判据」准备的，和 §24 那条同一个用途
  顺带一句：满档 174 分对应的书面上限是 154，按书那套区间，一个自称 154 满分的问卷，`>= 130` 那一档从 130 就开始、一直盖到 154 —— 换成真实上限 174，`>= 130` 这一档往上还要再接 44 分（130 到 174 含两端是 45 个整数分）。区间和上限是两处写的，改一处不会带动另一处（§29 量同一件事的另一半）
```

- **第一条那处「70 那道缝」要说清它为什么无害**：`score < 70` 与 `score >= 70` 是**互补**的，
  中间没有整数。我把它叫「缝」是为了和下面两条对齐，其实这一条根本没有缝。
  69 和 72 是它两侧最近的一对**可达**分数（70 本身不是 3 的倍数，取不到）；
- **第二条才是第一种缝**：`< 109` 与 `>= 110` 之间漏掉 109。它无害的原因是**运气** ——
  109 不是 3 的倍数。这一条要读成：这段代码的正确性依赖一个源码里没写的性质
  （「分值都是 3 的倍数」）。把某一题的分值改成 1，这段依赖立刻塌；
- **第三条是本节的落点**：129 = 3 × 43，可达，答法是 `picks(forScore: 129)` 给的
  14 题「是的」（14×6=84）+ 15 题「不一定」（15×3=45），合计 129。
  它掉在 `< 129` 和 `>= 130` 之间，`var title = ""` 那个初值**第一次真的被用上** ——
  而这一行代码的写法是「先给个空串兜底」，兜底的后果是一个空白弹窗。
  这一格不崩、不报错、不退出（`退出码` 全程 0），是本章四条「静默」里最像真实事故的一条；
- **中间那行 `Optional("")`**：`title` 是 `String?`，空串进去读回来是 `Optional("")`
  而不是 `nil`。第 30 章讲可选盒子时量过同一种打印，第 31 章在 `UILabel.text` 那侧量过
  「空串 ≠ 没设」。这一区分在排查时是**能用的信息**：读到 `Optional("")` 说明代码走过了
  赋值那一步（赋的是初值），读到 `nil` 才说明压根没设过；
- **第四条给出「缝」和「墙」的区别**：132 有人接。所以这不是整个高档位失效，
  是一个孤立点掉下去。这一格是为什么本章要把边界**成对**测：只测 129 会以为整段坏了，
  只测 132 会以为全好；
- **第五条把 bug 拉回界面**：`actions` 仍然有 1 项。区间漏了、流程没漏，
  用户看到的不是错误而是一个**空白框 + 一颗「重新开始」**。
  书 7.13 步骤 6 的判据是「弹出的窗口如图 7-20 所示」—— 这一格恰恰是「看图」最容易糊过去的
  一种 bug，因为图上什么都有，只是字没出来；
- **最后那句「区间和上限是两处写的」把 §26 和 §27 焊上**：`>= 130` 里的 130 是按 154 满分
  设计的（那一档在书面口径里只盖 130~154），而这一份题库的真实满档是读回来的 174，
  同一档要多接 44 分。那句「45 个整数分」是把 130 和 174 都算进去的个数 ——
  两种说法本章都写进了同一行输出，因为**跨度**和**格数**在区间问题上最容易混；
  关键是这一行里没有任何一个数字是从上一行抄来的，而源码里的 130 和 154 是两处字面量。
  §29 量的正是这类「同一个意思写在几处」的账单。

## §28 「29 道题中有一部分是二选一，还有一部分是三选一」：那段 `enumerated()` 循环

书 7.13 步骤 3 的做法是给三颗固定按钮配一段循环：每次先把三颗全隐藏，
再按 `questionOption` 迭代出来的个数逐颗打开、逐颗设标题。
这一节拿一份**混排**题库（偶数题 2 个选项、奇数题 3 个）跑给它看。

```swift
func nextQuestion() {
    if questionNumber <= 28 {
        …
        answerOneButton.isHidden = true
        answerTwoButton.isHidden = true
        answerThreeButton.isHidden = true
        for (index, option) in allQuestions.list[questionNumber].questionOption.enumerated() {
            if index == 0 { answerOneButton.isHidden = false; answerOneButton.setTitle(option, for: UIControl.State.normal) }
            else if index == 1 { … } else if index == 2 { … }
        }
        updateUI()
    } else { presentResult() }
}
```

```
== §28 「29 道题中有一部分是二选一，还有一部分是三选一」：那段 enumerated() 循环的三颗按钮 ==
  混排题库：第 1 题 3 个选项、第 2 题 2 个、第 3 题 3 个……
  ok   偶数题被造成二选一（共 14 道）、奇数题三选一，而每一题的两个数组**仍然成对**（不一致 0 题）—— 书里那句警告防的不是「选项少一个」，是「选项和分值这两个数组个数不一样」
  ok   第 1 题（三选一）上屏之后三颗按钮的 isHidden：false/false/false，标题「是的」「不一定」「不是」
  ok   第 2 题（二选一）上屏之后第三颗按钮 isHidden=true，标题还留着上一题的「不是」—— 书 7.13 步骤 3 那段循环的做法是**每次先把三颗全隐藏**，再按 enumerated() 迭代出来的个数逐颗打开；隐藏而不重置标题，正是它能让第 3 颗「消失」的全部机制
  ok   第二题的两颗是「和从前相仿」「不一定」—— 这两个字符串来自 mixedBank.list[1].questionOption，也就是书上那句「根据 Question 对象提供的选项内容来动态修改按钮的标题」
  ok   可第三颗按钮的 tag 减一 = 2，而屏幕上这一题（第 2 题）的 questionScore 只有 2 档 —— 这一调用本章**不执行**：`questionScore[2]` 当场 `Fatal error: Index out of range`（原文见探针 r03）。裸进程里 sendActions 不派发（第 31 章 §16、本章 §17），真实 App 里用户摸不到那颗隐藏按钮；这一格量的是**代码路径**而不是用户路径：`isHidden = true` 挡住的是一只手，挡不住一个方法调用，判卷层从头到尾不知道屏幕上少了一颗按钮
  ok   同一颗第三颗按钮按在**三选一**的那一题上（startOver 把屏幕送回第 1 题）：pickedAnswer=2、这一档是 0 分，score=0、游标 1 —— 同一个方法、同一个 tag，安全还是崩溃完全取决于「题库里这一题恰好有几个选项」。这就是书 7.13 步骤 3 那段循环存在的理由，也是它把保护放在视图层的全部风险；答完这一题又回到二选一，第三颗按钮再次 isHidden=true
```

- **第一条先把混排题库的构造写清楚**：`QuestionBankEQ(mixedCount: 29)` 造出来的是
  14 道二选一、15 道三选一（`filter { $0.questionOption.count == 2 }.count` 读回 14）。
  而 `mismatchedCount` 还是 0 —— 这一格是那句警告的**准确边界**：书里那句「必须一致」
  防的不是「这一题只有两个选项」（这是本节刻意要的），而是「选项数组和分值数组长度不同」。
  混排题库两个数组都跟着选项个数一起缩，所以它是**合法**的数据，崩的是控制器；
- **第三条那句「隐藏而不重置标题」是这段循环真正的机制**：第三颗按钮的 `title` 读回来
  还是上一题的「不是」。`isHidden` 只是视图层的开关，标题、tag、target-action 全都原封不动。
  这一句可以直接当排查手册用：「按钮不见了」≠「按钮失效了」；
- **第五条那一格本章刻意不执行**：`answerPressed(mixed.answerThreeButton)` 会让
  `questionScore[2]` 当场越界，所以主线只断言数字关系（`tag - 1 == 2 >= count == 2`），
  崩的现场交给探针 r03 现跑现抄（原因见 §17：裸进程里 `sendActions` 不派发，
  主线跑不了真实点击；这里直调方法就会真的崩掉整个进程，一条断言都留不下）。
  **这一格量的不是用户路径而是代码路径** —— 真实 App 里用户摸不到隐藏按钮，
  但任何一句代码都摸得到，包括 §31 之前那种「控制器自己算下标」的写法；
- **第六条把风险定位说清楚了**：同一颗按钮、同一个方法调用，在三选一那一题上是 0 分，
  在二选一那一题上是崩溃。安全与否完全取决于「题库里这一题恰好有几个选项」，
  而判卷层（`checkAnswer()`）从头到尾**不知道**屏幕上少了一颗按钮 ——
  保护被放在视图层（`isHidden`），而视图层的数据（tag）又被判卷层当作可信输入。
  这一处是本章「同一个意思写几遍」主题的另一半：
  §29 写的是**数字**写了几遍，这里写的是**「这一题有几个选项」这件事**在两层各猜一次；
- 注意第六条结尾那句「答完这一题又回到二选一，第三颗按钮再次 isHidden=true」：
  这一格把「隐藏」这件事证明成**每轮重算**的，不是持久状态。这正是那段循环写得对的地方 ——
  它也提示了修法是同一处：把「有几颗按钮可选」变成判卷层要问的一个数（§31 的协议给了它）。

## §29 书 7.13 步骤 5 那句「只需将之前的 13 修改为 29 即可」

这是全章最轻描淡写的一句话，也是最值得数一数的。原文的语境是：把 7.11 那台控制器的
进度显示从 13 题改成 29 题，「我们只需将之前的 13 修改为 29 即可」。
在 `EQTestViewController.swift` 里跟「题库有几条」这件事有关的字面量一共**三处**：

| 位置 | 源码 | 说的是什么 | 改错的下场 |
| --- | --- | --- | --- |
| `nextQuestion()` 的守卫 | `questionNumber <= 28` | 题库有 29 条 | 越界崩溃（探针 r01/r04） |
| `updateUI()` 的除法 | `view.frame.size.width / 29` | 题库有 29 条 | 不报错，进度条永远到头不了 |
| `updateUI()` 的字符串 | `"\(questionNumber + 1) / 29"` | 题库有 29 条 | 不报错，界面报一个不存在的位置 |

三处说的是同一件事，写成三个互不相干的数。这一节把它们一处一数量出来。

```swift
let oneRound = EQTestViewController(bank: QuestionBankEQ(count: 29))
oneRound.loadViewIfNeeded()
expect(abs(oneRound.progressBar.frame.size.width - 402.0 / 29.0) < 1e-9, "…")
// …答满 28 题、再答第 29 题…
// —— 把题库换成 13 道，控制器一行不改 ——
let wrongCount = QuestionBankEQ(count: 13)
let mismatchVC = EQTestViewController(bank: wrongCount)
mismatchVC.loadViewIfNeeded()
for _ in 0..<12 { mismatchVC.answerPressed(mismatchVC.answerOneButton) }
expect(mismatchVC.questionNumber == 12 && mismatchVC.progressLabel.text == "13 / 29", "…")
```

```
== §29 书 7.13 步骤 5 那句「只需将之前的13修改为29即可」—— 那个「只需」值多少 ==
  ok   第 1 题的进度条宽度 13.862068965517242（= 屏宽 402 / 29 × 1）—— 这个「/ 29」是 updateUI() 里写死的，它和题库的真实条数是两条互不相干的事实
  逐题的宽度：13.86 27.72 41.59 55.45 69.31 83.17 97.03 110.90 124.76 138.62 152.48 166.34 180.21 194.07 207.93 221.79 235.66 249.52 263.38 277.24 291.10 304.97 318.83 332.69 346.55 360.41 374.28 388.14 402.00
  ok   答完 28 题、屏幕上正显示第 29 题（游标 28）的那一刻：宽度已经是 402.0（屏幕宽 402）、进度文字「29 / 29」—— 和 §14 那条一模一样的结论：满格出现在**还在显示最后一题**时，而不是最后一题答完之后。写 `questionNumber + 1` 的人顺手把它填成了「1-based」，进度条因此提前一格到头
  ok   第 29 题答完：游标 29 —— `<= 28` 不再放行，走 else 分支造出结论弹窗（title=「你就是个EQ高手」）。到这里 29 这道题的闭环是完整的，代价是**再点一次就崩**：answerPressed 里 `checkAnswer()` 读的是 `list[questionNumber]`，而它已经是 list.count —— 探针 r01 量过 13 题那一版的同一句话，29 题这一版一个字符都没变
  ok   同一台控制器换上一份 13 道的题库、答满 12 题之后（游标 12，屏幕上正是它的最后一题）：进度文字写的是「13 / 29」—— 这个数字来自 updateUI() 里那处写死的 29，它和题库的真实条数是两条互不相干的事实，界面已经在报一个不存在的位置
  ok   而守卫看不见这件事：再答一次，游标推到 13，`13 <= 28` 成立（true），于是 nextQuestion() 会去读 `list[13]` —— 这份题库的合法下标只到 12。这一撞本章不执行（`Fatal error: Index out of range`，原文见探针 r04），但它就是书 7.13 步骤 5 那句「我们只需将之前的13修改为29即可」的账单：那句话数下来是**三处**字面量（守卫里的 28、除法里的 29、label 里那个字符串），它们说的是同一件事（题库有几条），却写成三个互不相干的数，漏改任何一个都不报错
  ok   同一时刻进度条宽度 180.20689655172416（= 402 / 29 × 13）—— 一份 13 道的题库在这里走到最后一题时只填到 44.8%，永远到头不了。三处字面量的下场各不相同：守卫那一处（28）撞上越界，除法与 label 这两处（29）不报错、只是把 13 道题画成 13/29 和「13 / 29」—— 这就是「同一个意思写三遍」的代价，而 §31 的 QuestionSource 接口把这件事收成一个 `questionCount`
```

- **第一条那个小数点后面一堆 6 是本仓库判定 6 的常客**：`402.0 / 29.0` 在 `-Onone` 和 `-O`
  两份输出里必须逐字一样，而浮点除法的字符串化正是最容易随编译选项漂移的一种读数。
  这一格是「为什么进度条用除法而不是乘法表」的实测答案：能过，但每一节都要重新看一眼；
- **第二条那张宽度表是本节给 §14 的复证**：29 格逐题的宽度排成等差，最后一格 402.00 ——
  满格出现在游标 28（屏幕上还显示着第 29 题）时。
  这件事在 13 题那一版量过一次，在 29 题这一版**一模一样**，因为它是 `questionNumber + 1`
  和守卫 `<= N-1` 相互作用的结构后果，与题数无关。这一条是本章少见的「换个 Model 结论不变」；
- **第三条把闭环和代价写在同一格里**：`<= 28` 在游标 29 时不再放行，`else` 分支造出结论弹窗，
  整个流程是完整的。代价写在同一句里 —— 「再点一次就崩」。
  这里的因果值得慢读一遍：崩的原因不是弹窗，是**弹窗之后那颗按钮还挂在屏幕上**，
  而 `answerPressed` 里没有守卫（守卫在 `nextQuestion()` 里，而 `checkAnswer()` 跑在它之前）。
  探针 r01 在 13 题那一版量的是同一句 `list[questionNumber]`；
- **第四条把「13 / 29」这一行界面上的谎话读回来**：换上一份 13 道的题库、答完它的最后一题，
  `progressLabel.text` 是 `"13 / 29"`。这个数字不来自任何数据 —— 它就是 `updateUI()`
  里那个字符串字面量。界面已经在报一个不存在的位置，而这一条断言能成立，
  恰恰因为它**不报错**：如果这里会崩，反而不需要写断言了；
- **第五条给出「漏改一处」的完整账单**：守卫那一处没改（还是 28），于是 `13 <= 28` 成立，
  `nextQuestion()` 去读 `list[13]` —— 越界，本章不执行，现场在探针 r04。
  这一格是本节最实用的一句：**「只需把 13 改成 29」这句话在代码里是三处，
  而编译器不会陪你数**。改代码的人只会去看屏幕上那行「13 / 29」对不对，
  而守卫那一处不在屏幕上；
- **第六条给出三种下场**：一处崩溃（守卫），两处静默骗人（除法、label）。
  「只填到 44.8%」那个百分比是现算的（`宽度 / 402 × 100`，读回 44.8）。
  这就是「同一个意思写三遍」的代价 —— 而且两遍是**不会报错**的那两遍。
  §31 把这件事收成一个 `questionCount`，收的就是这三处。

## §30 书 7.12 的 ProgressHUD：一座桥的两侧各看到什么

书 7.12 是原书第一次把一份 Objective-C 的第三方库拖进 Swift 工程：
拖进来 `ProgressHUD` 那几个文件，Xcode 问「Would you like to configure an Objective-C
bridging header?」，点 Yes，然后写 `#import "ProgressHUD.h"`，最后在 `checkAnswer()` 里加两行
`ProgressHUD.showSuccess("正确")` / `showError("错误！")`。

命令行这边这座桥只由两样东西搭成（`probes/run.sh` 与 `run-all.sh` 认的就是这两个标记）：
目录里的 `Bridging.h`（内容就是书里那一行 `#import "ProgressHUD.h"`），
和一个空文件 `Needs-Swift-Header`（它的存在让构建脚本加
`-emit-objc-header-path build/32_app_architecture/SwiftBridge-Swift.h`，
`ProgressHUD.m` 顶部再 `#import` 那份**产物** —— 反方向那条桥就靠它）。

```swift
ProgressHUD.reset(); HUDSink.shared().clear()
let hudVC = QuizViewController(); hudVC.loadViewIfNeeded()
hudVC.answerPressed(hudVC.yesButton)   // 第 1 题答对 → showSuccess
hudVC.answerPressed(hudVC.yesButton)   // 第 2 题答错 → showError
let hudLines: [Any] = ProgressHUD.history()      // 不能写成 [String]，原文见探针 e09
ProgressHUDStrict.showSuccess("正确")
let strictLines: [String] = ProgressHUDStrict.history()   // 同一份 .m，头文件不同
```

```
== §30 书 7.12 的 ProgressHUD：桥接头、方法名转换、nullability、单例、以及反方向那条桥 ==
  ok   书 7.12 改完之后，checkAnswer() 里那两行的效果读得回来：2 条、内容是「success：正确」「error：错误！」—— 上一节那条「Xcode 控制台只显示正确与否，最终用户看不到」的反馈，在这里第一次有了一个用户摸得着的出口（虽然这个进程里没有用户）。请注意每个元素都得过一次 `as? String`：那个 NSArray 没写元素类型，Swift 只能给 [Any]，类型信息在**头文件**那一侧就丢了
  ok   同一件事在带 NS_ASSUME_NONNULL 的那个类上是另一种写法：1 条、第一条「success(严格)：正确」，而且这一行**没有**任何 as? —— 头文件里写的是 `NSArray<NSString *> *`，Swift 直接给 `[String]`。两份实现走的是同一个 hud_record（.m 只有一个文件），差别全在头文件那几行声明上：桥这一侧拿到什么类型，是**头文件**决定的，不是 .m 决定的
  ok   同一段代码在两种语言里是三个名字：OC 头文件里写 `+ (void)showSuccess:(NSString *)success`，Swift 里调 `ProgressHUD.showSuccess(_:)`，而运行时真正拿去查表的那个名字是「showSuccess:」—— §21 那条「OC 的 @objc optional 是运行期查表」用的是同一张表（第 27 章量过它的代价：拼错不报错，只是没人应答）
  ok   单例：两次 `shared()` 拿回来是**同一个**对象（=== 成立）—— 地址这种读不回的东西本章一律用同一性代替（§7 那条口径）
  ok   它自己的 frame 是 (0.0, 0.0, 402.0, 874.0)（= UIScreen.main.bounds）—— 「铺满全屏」这一半是真的：书里那个 HUD 的几何确实建起来了
  ok   可它的 window 和 superview 都是 nil，`onScreen` 返回 false —— 原库是靠 keyWindow 把自己加上去的，而这个进程里根本没有 window（§1 那句 UIApplication.shared == nil 的同一条根）。于是「HUD 弹出来了」这句话在这里被拆成两半：调用**全都成功**（history 一行不少），屏幕上**什么都没有**。这和 §24 那条 present 不生效、§17 那条 sendActions 不派发是同一条边界的三种长相
  ok   把 nil 递给那个 `_Null_unspecified` 参数，Swift 编译器一个字都没说（对照：同样的调用写在带 NS_ASSUME_NONNULL 的 ProgressHUDStrict 上是编译期错误，原文见探针 e08）；OC 那侧 hud_record 里有一句 `?:` 兜住了它，history 收下的是「error：(nil)」。这就是「未声明 nullability」的真实含义：**nil 能不能进来不是由类型决定的，是由另一侧有没有防决定的**（探针 m02 量的是没防的那种 —— 同一个 nil 递到 NSMutableArray 的 addObject: 上是运行期异常，退出码 134 / SIGABRT，与 rNN 那几支的 132 / SIGILL 不是一类）
  ok   而 HUDSink 里读到了 4 条、最后一条是「error：(nil)」—— 这一笔是 **OC 写进来的**：ProgressHUD.m 顶部 #import 那份 SwiftBridge-Swift.h，然后调 `[[HUDSink shared] note:]`。数目对不上是**故意的**，而且对不上的这一格本身就是结论：两个类各有一份 history，可 Sink 只有**一份**（loose 的 3 条 + 严格版那 1 条）。书 7.12 只搭了 Swift → OC 那半条桥，反方向这一半的条件写在 HUDBridge.swift 的类声明上：NSObject 子类 + @objc，缺任何一个，那个类根本不会出现在生成的头文件里（不是「调不到」，是「看不见」）
  ok   这个类的 superclass 是「Optional(UIView)」，实例那句 `isKind(of: UIView.self)` 是 true —— 它自己就是一个 UIView 子类。现在回头看 §23 那条纪律：7.5 说「数据模型与视图永远不会直接发生联系」，而 7.12 之后 checkAnswer()（Controller）里直接写了一句 ProgressHUD.showSuccess —— 三层图在这里少的不是 M↔V 那条边，是 C 直接抓住了一个 V 的**类**，还是走全局单例的那种（没有可以塞替身的缝）
  顺带一个坑：拿**类对象**去问 `ProgressHUD.isKind(of: UIView.self)` 读回来是 false，和上面实例那一句相反 —— isKind 问的是「我这个对象是不是某个类的实例」，而类对象自己也是一颗对象，它属于 metaclass（第 27 章 isa 那一层）。这一句在混编代码里最容易顺手写错，而且它不报错，只是永远给你 false
  ok   换一个**全新的**控制器答一题，history 从 3 条走到 4 条 —— 单例就是全局可变状态：两台控制器共用同一本账。这一条和 §20 的 NotificationCenter 是同一类耦合（都是「谁都不声明，谁都能写」），只是这一处更安静：连一个通知名都不用写
  书 7.12 开头那句「你可能会遇到一些与这个库有关的黄色叹号警告……它们并不会影响应用程序的功能」在本仓库里恰恰是**硬失败**（判定 1 要求编译日志为空），可它的触发条件不是「头文件没标」：探针 m03 把**整份都不标**的那个类单独编一次，swiftc 日志为空、退出码 0，连那句 `record(nil)` 编译期都没人拦截。真正会响的是**标了一半**——m01 那份头文件里 `NS_ASSUME_NONNULL` 包了一个类，旁边没包的那个就被逐条点出 -Wnullability-completeness（原文交给 m01 现跑现抄）。第三种答案是本主线 ProgressHUD.h 的写法：宏一个不写，每个指针手着标 `_Null_unspecified` —— Swift 侧的类型和 m03 一样（还是隐式解析可选），日志也一样干净。「不影响功能」和「不许进来」这两种态度，差的就是构建脚本里那一行判定
```

这一节的信息密度是全章最高的，逐条走：

- **第一、第二条合起来是本节的主线**：`ProgressHUD.history()` 返回 OC 的 `NSArray`，
  没写元素类型，Swift 只能给 `[Any]`（外面还包一层隐式解析可选），
  所以每个元素都得过 `as? String`；`ProgressHUDStrict.history()` 的头文件写的是
  `NSArray<NSString *> *`，Swift 直接给 `[String]`，那一行**没有任何 `as?`**。
  **两份实现走的是同一个 `.m`**（`hud_record` 只有一个），差别全在头文件那几行声明上。
  这一格把「桥这一侧看到什么类型」这件事彻底归给了头文件；
  写成 `let hudLines: [String] = ProgressHUD.history()` 的编译器原文在探针 e09；
- **第三条那座桥的两侧各有名字，运行时用第三个**：OC 声明是 `+ (void)showSuccess:(NSString *)success`，
  Swift 侧的调用写成 `ProgressHUD.showSuccess(_:)`，而 `NSStringFromSelector(#selector(…))`
  读回来的是 `"showSuccess:"` —— 第三个名字才是运行时查表用的那一个。
  这一条接 §21 和 §23（那张表）：第 27 章量过它的代价，拼错不报错，只是没人应答；
- **第四、五、六条是同一个对象的三格读数**：`shared()` 两次拿到同一个实例（`===`）；
  `frame` 真的是 `UIScreen.main.bounds`（0,0,402,874）；但 `window`、`superview` 都是 `nil`，
  `onScreen` 是 `false`。这三行合起来是本章边界声明里最完整的一格：
  **调用全都成功，屏幕上什么都没有**。原库靠 `keyWindow` 把自己 addSubview 上去，
  而这个进程里没有 window（和 §1 那句 `UIApplication.shared == nil` 同一条根）。
  「HUD 弹出来了」这句自然语言在这里必须拆成两半才说得清；
- **第七条是 nullability 三种态的落点**：`ProgressHUD.h` 里那几个参数标的是 `_Null_unspecified`
  （第三种：宏不写、每个指针手着标）。把 `nil` 递给 Swift 侧那个隐式解析可选，
  编译器一个字都没说；OC 那侧 `hud_record` 里有一句 `?:` 兜住了它，于是 history 收下
  `"error：(nil)"`。对照：同样的调用写在带 `NS_ASSUME_NONNULL` 的类上是**编译期错误**（探针 e08）。
  而探针 m02 量的是「另一侧没防」的那种：同一个 `nil` 递到 `NSMutableArray` 的 `addObject:` 上，
  运行期 `NSInvalidArgumentException`，**退出码 134 / SIGABRT** ——
  这一串数字和 rNN 那几支的 **132 / SIGILL** 不是一类崩溃（Swift 的 `Fatal error` 走 `fatalError()` →
  SIGILL，OC 异常走 `objc_exception_throw` → SIGABRT）。
  三种态度（不标 / 标了但兜住 / 标了且不兜）在代码里只差几行声明，在下场那边差一个信号；
- **第八条是全节唯一一处「反方向」**：`HUDSink` 里读到 4 条，最后一条是 `error：(nil)`，
  而 `ProgressHUD` 自己的 history 是 3 条。数目差 1 是**故意的**，
  因为 Sink 收到了 loose 的 3 条**加上**严格版那 1 条（两份 history 各一份，Sink 只有一份）。
  这一笔是 OC 写进来的 —— `ProgressHUD.m` 顶部 `#import` 那份生成的 `SwiftBridge-Swift.h`，
  然后 `[[HUDSink shared] note:]`。书 7.12 只搭了 Swift → OC 那半条桥；
  反方向的条件写在 `HUDBridge.swift` 的类声明上：`@objc final class HUDSink: NSObject`，
  **缺任何一个，那个类根本不会出现在生成的头文件里**（不是「调不到」，是「看不见」——
  这一格是混编排查时最容易走错的方向：你会以为方法签名有问题，其实那个类没进头文件）；
- **第九条接回 §23 那条纪律**：`ProgressHUD.superclass()` 读回 `Optional(UIView)`、
  实例的 `isKind(of: UIView.self)` 是 `true` —— 它自己就是个 UIView 子类。
  而 7.12 之后 `checkAnswer()`（Controller）里直接写了 `ProgressHUD.showSuccess`。
  所以 7.5 那张三层图在这里少的**不是 M↔V 那条边**，是 **C 直接抓住了一个 V 的类**，
  还是走全局单例那种（没有可以塞替身的缝）。这句话是本对第三方库的架构评价，
  而它只能通过读回 superclass 才看得见；
- **第十条那一行的坑在混编代码里最常写错**：`ProgressHUD.isKind(of: UIView.self)`（拿**类对象**问）
  读回 `false`，和实例那一句相反。`isKind` 问的是「我这个对象是不是某个类的实例」，
  而类对象本身也是一颗对象，属于 metaclass（第 27 章 isa 那一层量过）。
  它不报错，只是永远给你 `false`；
- **第十一条把单例归回架构**：换一台全新控制器答一题，history 从 3 条走到 4 条。
  单例就是全局可变状态，两台控制器共用同一本账 —— 和 §20 的 `NotificationCenter` 同类耦合，
  只是这一处更安静（连通知名都不写）。这一格同时也是本章**测试口径**的一部分：
  为什么 §30 开头要先 `ProgressHUD.reset()` 和 `HUDSink.shared().clear()` ——
  因为前面 29 节每一台控制器答过的题都往同一本账上记了一笔；
- **最后那句是原书与构建脚本的一次正面冲突**：书 7.12 开头说那些黄色叹号「并不会影响
  应用程序的功能」。在本仓库里它们恰恰是**硬失败** —— 判定 1 要求编译日志为空。
  `m01` 现跑现抄的那条 `-Wnullability-completeness` 就是这张黄色叹号的原文，
  而它的触发条件是「**标了一半**」：整份都不标（探针 `m03`）与标了全套（`NS_ASSUME_NONNULL`
  包住整个文件）都不响，只有一标一不标并排在同一份文件里时才响；
- **顺带把那条告警的触发条件写准**（这一条特别容易记错）：
  `-Wnullability-completeness` **不是**「头文件里没写 nullability」就报的，
  它要求这份头文件里**已经有**标注 —— 也就是「标了一半」。
  `m01` 那份源码就是这么造的：`HUDLoose` 什么都不标，紧跟着 `NS_ASSUME_NONNULL_BEGIN` 里
  一个 `HUDStrict`，于是 loose 那两行的每一个裸指针都被逐条点出来
  （探针原文里 `+ (void)record:(NSString *)text;` 那一行给了 1 warning、退出码仍是 0）。
  反过来那一半由 `m03` 量：把标了的那一侧整个去掉，只留一份**从头到尾不标**的头文件，
  `swiftc` 日志为空、退出码 0 —— 也就是说「第三方库完全没标」这一种情况在本仓库里连判定 1
  都碰不到。这正是书 7.12 的现场容易踩的原因：库整个没标并不响，工程里另一处标了、
  两边一撞才叫起来。
  第三种答案（宏不写、每个指针手着标 `_Null_unspecified`）在主线那份 `ProgressHUD.h` 里，
  它的凭据是主线编译日志为空，而 Swift 侧类型与 `m03` 那个不标的类完全相同
  （都是隐式解析可选）。
  拿 `String(reflecting:)` 打印 m01 那两个 `record` 方法，给的是
  `(Optional<String>) -> ()` 与 `(String) -> ()` —— 类型信息确实是从头文件那侧带过来的。

## §31 兑现书 7.5 那句话：一个协议、两份 Model、同一台控制器

7.5 的原文是：「如果这个项目在法国运行，需要把数据模型的内容从英文换成法文，
你完全可以直接修改数据模型，而不用考虑其他代码」。§29 刚用三处字面量证明这句话
在书自己的代码里**不成立**；这一节给出它的兑现版，差别只有一条 ——
手里的 Model 是一个**协议**。

```swift
protocol QuestionSource {
    var questionCount: Int { get }
    func text(at index: Int) -> String
    func score(at index: Int, option: Int) -> Int
}

final class SourceQuizViewController: UIViewController {
    private let source: QuestionSource          // 唯一的改动在这里：类型是协议
    init(source: QuestionSource) { self.source = source; super.init(nibName: nil, bundle: nil) }

    func answer(option: Int) {
        guard questionNumber < source.questionCount else {      // 守卫问的是 Model
            Trace.log.append("已经答完，这一次点空了：游标 \(questionNumber)"); return
        }
        score += source.score(at: questionNumber, option: option)
        questionNumber += 1
        nextQuestion()
    }

    func updateUI() {
        progressLabel.text = "\(questionNumber + 1) / \(source.questionCount)"   // 三处数字一个来源
        …
    }
}
```

`QuestionBank`（13 道判断题）和 `QuestionBankEQ`（29 道 EQ 题）各自实现这三个方法，
于是「一共有几道题」「这一题显示什么」「这一档给几分」三件事全部退到协议后面。

```
== §31 书 7.5 那句「换数据不用考虑其他代码」：一个协议、两份 Model、同一台控制器 ==
  ok   把 13 道判断题的库递进去：屏幕上「吃烧烤不能喝啤酒…」、进度文字「1 / 13」—— 那个「13」不是写死的，是从 source.questionCount 读回来的
  ok   换一份 29 道题的 EQ 库、**同一个类**再造一个实例：进度文字「1 / 29」、第 1 题「我有能力克服各种困难。」—— 控制器那边一个字都不用改，两份 Model 各自的题数、选项个数、计分规则全在协议后面
  ok   「一行没改」的判据不是我说没改：两个实例的运行时类型是同一个「SourceQuizViewController」，只有构造参数不同。书里为这件事写了两个 ViewController（7.6 的 Quizzler 与 7.13 的 EQTest），在这里它们合并成一个类型加两份 Model —— 这就是 §29 那三处字面量的对偶
  ok   全答第一档跑完：判断题那边游标 13、分数 6 —— 这份库里有 6 道题的正确答案是「是」，所以全答第一档就得 6 分。换算写在 QuestionBank 的 score(at:option:) 里（「答对给 1 分」），协议这一侧只管要一个数
  ok   EQ 那边游标 29、分数 174（每题第一档 6 分 × 29）—— 同一个 answer(option:) 调用、同一台控制器，两份 Model 各自的计分规则互不知道对方存在。§26 那句「154 还是 174」的账在这台上也不用改代码：它读的就是 Model 给的数
  ok   答完**再点一次**：§29 那一撞（`list[13]` 越界）在这里没有发生 —— answer() 开头那句 guard 问的是 questionCount，于是这一笔落在 Trace 上（1 条：「已经答完，这一次点空了：游标 13」），游标和分数都停在原位。把「有几道题」收成一个数据源，代码路径上就多出来这一条边：越界从一个运行期崩溃变成一次可以被记录的无操作
  ok   第三份 Model（§28 那盘二选一/三选一混排，这里只答前两档）也照样跑得完：游标 29、分数 132（这份库自己的分值累加出来是 132）—— §28 那一撞（隐藏按钮的 tag 对着只有两档的题）在这台控制器上不会发生，因为下标是它自己传进去的，不是从 Inspector 上读来的。**注意这不是「协议消灭了 bug」**，它消灭的是「控制器和界面各自猜一个数字」这一类 bug
```

- **第一条只讲一个数字的来历**：`"1 / 13"` 里那个 13 是 `source.questionCount` 读回来的。
  §29 那三处字面量在这里合并成一处，而这台控制器和 `EQTestViewController` 的代码长度差不多 ——
  省掉的不是行数，是**互不相干的来源数**；
- **第二条是 7.5 那句话的可执行版本**：换一份 Model（13 → 29 道题，判断题 → EQ 题），
  进度文字跟着变 `"1 / 29"`，控制器源码一行没改。注意这一句的成立**跟目录结构无关**
  —— `SourceQuizViewController.swift` 里连 `QuestionBank` 这个名字都没出现，
  但它出现的次数从来不是分层的判据；
- **第三条给出「一行没改」的判据**：`String(describing: type(of:))` 两个实例读回同一个名字。
  这一条把话说成可核对的形式 —— 「控制器没改」不是我的说法，是「两个实例的运行时类型相同、
  只有构造参数不同」。书里这件事的成本是两个 ViewController 文件（7.6 的 Quizzler、
  7.13 的 EQTest），这里是一个类型 + 两份 Model；
- **第四、第五条量「计分规则藏在协议后面」**：判断题全答第一档得 6 分，
  因为 `trueCount`（`bank.list.filter { $0.answer }.count`）读回这份库里有 6 道题答案是「是」；
  EQ 那一版是 174（6 分 × 29）。同一个 `answer(option: 0)` 调用给出两个完全不同的数，
  而控制器对两边都一无所知 ——
  这正是 §26 那句「154 还是 174」在这台控制器上不用改代码的原因。
  判断题那一版的期望值也不是手算的：`trueCount` 用同一份数据算第二遍（本章一贯口径）；
- **第六条是本章最实用的架构结论**：答完再点一次，越界**没有发生**，
  因为 `answer()` 开头那句 `guard questionNumber < source.questionCount` 问的是 Model。
  §29 那一撞（崩，132 / SIGILL）在这里变成 Trace 上一条可记录的无操作。
  这一格的因果要说准：**把「有几道题」收成一个数据源**，守卫和界面用的是同一个数，
  于是「守卫放过、界面越界」那种错配在结构上就组不出来了；
- **第七条把 §28 那一撞也收掉，同时给协议划清界限**：混排题库（14 道二选一）在这台控制器上
  跑得完，游标 29、分数 132（期望值同样不手算：`(0..<29).reduce` 用这份库自己的分值累加第二遍）。
  不会崩的原因是**下标是控制器自己传进去的**，不是从 `sender.tag` 读来的。
  但这一条必须反过来读：协议**没有**消灭 bug，它消灭的是
  「控制器和界面各自猜一个数字」这一类 bug。若 `score(at:option:)` 的实现里越界，
  协议一点忙也帮不上（探针 r03 量的是这种）。

## 本章开头那三句话，现在的账目

主线最后把这章开头的三条断言逐条结账，输出长这样：

```
== 本章开头那三句话，现在的账目 ==
  1) **Model 不认识 UIKit** —— §1 的证据：整章跑完 UIApplication.shared 都是 nil，而 13 道题、29 道题、四种结论区间、三台控制器全部走完；Question.swift 和 QuestionBank.swift 这两个文件里连 UIView 这个名字都没出现过（只有 import Foundation）
  2) **视图不会自己动** —— §12/§18 的证据：改 Model 的那个 var，屏幕上一个字都没变；界面唯一的入口是控制器那句 updateUI()，而它被叫到几次是数得出来的（§18 那一本账）
  3) **换掉 Model 而控制器一行不改** —— §31 就是它，§29 是它的反例：同一件事（题库有几条）写成三处字面量，换 Model 就得改三处，漏一处要么崩要么骗人
  三句话里第三句最脆。它成立的条件不是「项目用了 MVC 这个说法」，而是「**同一个意思只有一个来源**」—— 这一条在 7.13 那份代码里没做到，在 7.5 那句话里也没说，本章把它换成两个数字：§29 里三处字面量、§31 里一个 questionCount
  本章没做到的事（记在这里，别让它们看起来像已经验证过）：真实触摸的派发（§17 量的 sendActions 不派发）、present 出来的窗口（§24）、故事板与 xib 的装配（第 31 章）、图层渲染和动画时序、以及由 UIApplication/NSRunLoop 驱动的完整生命周期。这一半只能上真机或模拟器 GUI，命令行产物里给不出对应证据
```

最后一行是本仓库每章都要写的一条「没做到的事」，第 32 章这一份里它最长。
它必须和前面那 31 节一样被读：这三十一条 ok 覆盖的是**状态、类型、桥接、回收**这四件事，
不覆盖**渲染、事件、生命周期**。上一章（第 31 章 §16）量到的那条 `sendActions` 不派发，
本章在 §17、§24、§30 又踩了三次同一条边界 —— 三个症状（按钮不响应、弹窗不出现、HUD 不显示）
是同一个原因（这个产物里没有 window 和事件循环）。



## 探针记录（18 支，逐字抄自现跑输出）

跑法与环境：

```bash
bash examples/32_app_architecture/probes/run.sh            # 全部 18 支
bash examples/32_app_architecture/probes/run.sh e07 r03     # 按编号挑
```

探针用的模块名与主线一致（`-module-name app_architecture`），SDK 是
`xcrun -sdk iphonesimulator --show-sdk-path`，target 是 `x86_64-apple-ios15.0-simulator`，
运行走 `xcrun simctl spawn`。`eNN_*` 那一族有个不显眼的细节：先 `-typecheck`，
它一声不吭时再用完整编译问一遍 —— definite-initialization 那一类诊断（e04）**只在真正
发射函数时**才打印，`-typecheck` 那条路一个字都不给。`mNN_*` 一律走完整编译
（要链接同名 `.m`、要产出二进制）。

三件记档口径，抄的时候要知道：

- 诊断里的源文件路径统一是 `/var/folders/…/iosdev32probes/main.swift`
  （探针的 `.swift` 必须先复制成 `main.swift` 才允许顶层语句，见上面「复现」第 1 条），
  行列号是这一份临时文件的，不是仓库里那个探针文件的；
- **退出码 132 = 信号 4（SIGILL）**，Swift 运行时断言与 `fatalError()` 都走这一路（rNN 五支全是）；
  **退出码 134 = 信号 6（SIGABRT）**，未被捕获的 Objective-C 异常走这一路（m02）。
  两族的原文长相也不同：前者是 `Swift/ContiguousArrayBuffer.swift:675: Fatal error: …`，
  后者是 `*** Terminating app due to uncaught exception 'NSInvalidArgumentException'`。
  m02 那一支的调用点是 `[arr addObject:text]`，可异常原文点名的是
  `*** -[__NSArrayM insertObject:atIndex:]: object cannot be nil` ——
  `addObject:` 在 `NSMutableArray` 上就是转发到那个原语，所以「哪个方法」在两处不一样，
  读异常时按后者搜才搜得到；
- 探针留档**不走主线那一次地址脱敏**，所以崩溃原文里的 `0x…` 每次重跑都会变。
  比对以消息文本、帧号与符号名为准。

### `c01_dealloc_timing` —— 断环那一句写完，对象是不是**当场**被收？七种位置各跑两遍配置（§25）

```
===== c01_dealloc_timing (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
[1] 环由一个**函数**里的局部强引用建成，断环也写在函数里：
    函数内 drop 之前：weak=还在
    h.drop() 之后、函数还没返回：weak=还在（局部 n 这条强引用还没走完）
  deinit：n1 被收了
    函数返回之后：weak=nil
[2] 只有环、别处没有强引用，而断环那一句写在**顶部作用域**：
    造完之后：weak=还在（环成立，局部强引用没了也收不掉）
    顶部作用域 drop 之后：weak=nil
[3] 同一个环，把断环那一句包进**函数**：
    函数返回之后：weak=nil
[4] 顶部作用域：先断环，再测第二次（同一个 weak 变量，隔一句再看）
    造完之后：weak=还在
    drop 这一句之后立刻读：weak=nil
    隔一句再读：weak=nil
[5] 正主线的形状：UIViewController + UIAlertController（UIKit 工厂方法）+ 抓 self 的 handler
    函数返回后：weak=还在（q→alert→action→handler→q）
    顶部作用域 release 之后：weak=还在
    换成包在函数里 release 之后：weak=还在
[6] 同样的 release，外面包一层 autoreleasepool：
    进池之前：weak=还在
    池子退出之后：weak=还在
[7] 连**创建**都放进池子里（书里那个 alert 就是这种：局部变量 + 一次 release 全清）：
    创建函数返回后：weak=还在
    断环 + 池子退出之后：weak=nil
==== c01 结束 ====
--- stderr ---（空）

===== c01_dealloc_timing (release)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
[1] 环由一个**函数**里的局部强引用建成，断环也写在函数里：
    函数内 drop 之前：weak=还在
    h.drop() 之后、函数还没返回：weak=还在（局部 n 这条强引用还没走完）
  deinit：n1 被收了
    函数返回之后：weak=nil
[2] 只有环、别处没有强引用，而断环那一句写在**顶部作用域**：
    造完之后：weak=还在（环成立，局部强引用没了也收不掉）
    顶部作用域 drop 之后：weak=nil
[3] 同一个环，把断环那一句包进**函数**：
    函数返回之后：weak=nil
[4] 顶部作用域：先断环，再测第二次（同一个 weak 变量，隔一句再看）
    造完之后：weak=还在
    drop 这一句之后立刻读：weak=nil
    隔一句再读：weak=nil
[5] 正主线的形状：UIViewController + UIAlertController（UIKit 工厂方法）+ 抓 self 的 handler
    函数返回后：weak=还在（q→alert→action→handler→q）
    顶部作用域 release 之后：weak=还在
    换成包在函数里 release 之后：weak=还在
[6] 同样的 release，外面包一层 autoreleasepool：
    进池之前：weak=还在
    池子退出之后：weak=还在
[7] 连**创建**都放进池子里（书里那个 alert 就是这种：局部变量 + 一次 release 全清）：
    创建函数返回后：weak=还在
    断环 + 池子退出之后：weak=nil
==== c01 结束 ====
--- stderr ---（空）
```

### `e01_uninitialized_let` —— 书 7.2 那个没有 init 的 `Question`：`let` 没给值，红点落在哪一行（§2）

```
===== e01_uninitialized_let (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:15:7: error: class 'Question' has no initializers
13 | import Foundation
14 | 
15 | class Question {
   |       `- error: class 'Question' has no initializers
16 |     let questionText: String
   |         `- note: stored property 'questionText' without initial value prevents synthesized initializers
17 |     let answer: Bool
   |         `- note: stored property 'answer' without initial value prevents synthesized initializers
18 | }
19 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:21:9: error: 'Question' cannot be constructed because it has no accessible initializers
19 | 
20 | // 书 7.4 的 QuestionBank 里就是这一句在造对象：
21 | let q = Question()
   |         `- error: 'Question' cannot be constructed because it has no accessible initializers
22 | print("q.questionText = \(q.questionText)")
23 | 
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e02_label_text_int` —— `questionLabel.text = 123`：界面属性吃的是 `String?`（§12）

```
===== e02_label_text_int (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:18:25: error: cannot assign value of type 'Int' to type 'String?'
16 | 
17 |     func updateUI() {
18 |         scoreLabel.text = score
   |                         `- error: cannot assign value of type 'Int' to type 'String?'
19 |     }
20 | }
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e03_let_model_field` —— `let` 的 Model 字段：能不能改、能不能被观察（§19）

```
===== e03_let_model_field (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:25:33: error: 'let' declarations cannot be observing properties
23 | 
24 |     // [2] 想「不改它但看着它」：常量上挂不了观察者
25 |     let wrongWayToWatch: String {
   |                                 `- error: 'let' declarations cannot be observing properties
26 |         didSet { print("变了") }
27 |     }

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:32:3: error: cannot assign to property: 'answer' is a 'let' constant
15 | final class Question {
16 |     let questionText: String
17 |     let answer: Bool
   |     `- note: change 'let' to 'var' to make it mutable
18 | 
19 |     init(text: String, correctAnswer: Bool) {
   :
30 | // [1] 想改它
31 | var q = Question(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
32 | q.answer = false
   |   `- error: cannot assign to property: 'answer' is a 'let' constant
33 | q = Question(text: "换一道题。", correctAnswer: false)   // ← 这一行合法：let 不在 q 上
34 | 
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e04_observer_in_init` —— 属性还没初始化完就把 `self` 交给逃逸闭包（§22、§25 的邻居）

```
===== e04_observer_in_init (debug)
（-typecheck 一声不吭：再用完整编译问一遍）
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:28:20: error: 'self' captured by a closure before all members were initialized
20 | final class ObserverRegistersSelf {
21 |     var questionText: String
22 |     var answer: Bool
   |         `- note: 'self.answer' not initialized
23 |     var onChange: ((ObserverRegistersSelf) -> Void)?
24 | 
   :
26 |         questionText = text
27 |         // 观察者「现在」就登记：闭包会逃逸（存在属性上），而 self 此刻还没交出来。
28 |         onChange = { model in print(model.questionText, self.answer) }
   |                    `- error: 'self' captured by a closure before all members were initialized
29 |         answer = correctAnswer
30 |     }
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e05_cgfloat_times_int` —— `view.frame.size.width / 13 * CGFloat(...)` 那一行的混算（§15）

```
===== e05_cgfloat_times_int (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:34:16: error: binary operator '*' cannot be applied to operands of type 'CGFloat' and 'Int'
32 | let unit: CGFloat = 30.923076923076923
33 | let count = 13
34 | let raw = unit * count                // ← 书里那句「一单一整」指的正是这一行
   |                |- error: binary operator '*' cannot be applied to operands of type 'CGFloat' and 'Int'
   |                `- note: overloads for '*' exist with these partially matching parameter lists: (CGFloat, CGFloat), (Int, Int)
35 | print(raw)
36 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:27:63: error: referencing operator function '/' on 'DurationProtocol' requires that 'CGFloat' conform to 'DurationProtocol'
25 | 
26 |     func bookLine() {
27 |         progressBar.frame.size.width = (view.frame.size.width / 13) * questionNumber
   |                                                               `- error: referencing operator function '/' on 'DurationProtocol' requires that 'CGFloat' conform to 'DurationProtocol'
28 |     }
29 | }

Swift.DurationProtocol:2:17: note: where 'Self' = 'CGFloat'
1 | @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
2 | public protocol DurationProtocol : AdditiveArithmetic, Comparable, Sendable {
  |                 `- note: where 'Self' = 'CGFloat'
3 |     static func / (lhs: Self, rhs: Int) -> Self
4 |     static func /= (lhs: inout Self, rhs: Int)
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e06_kvo_on_plain_property` —— KVO 挂在纯 Swift 属性上：编译器给的是 warning，退出码 0（§19）

```
===== e06_kvo_on_plain_property (debug)
（-typecheck 一声不吭：再用完整编译问一遍）
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:22:57: warning: expression implicitly coerced from 'Int?' to 'Any'
20 | 
21 | let plain = PlainQuiz()
22 | let token = plain.observe(\.score) { _, change in print(change.newValue) }
   |                                                         |      |- note: provide a default value to avoid this warning
   |                                                         |      |- note: force-unwrap the value to avoid this warning
   |                                                         |      `- note: explicitly cast to 'Any' with 'as Any' to silence this warning
   |                                                         `- warning: expression implicitly coerced from 'Int?' to 'Any'
23 | print(token)
24 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:22:19: warning: passing reference to non-'@objc dynamic' property 'score' to KVO method 'observe(_:options:changeHandler:)' may lead to unexpected behavior or runtime trap
20 | 
21 | let plain = PlainQuiz()
22 | let token = plain.observe(\.score) { _, change in print(change.newValue) }
   |                   `- warning: passing reference to non-'@objc dynamic' property 'score' to KVO method 'observe(_:options:changeHandler:)' may lead to unexpected behavior or runtime trap
23 | print(token)
24 | 
swiftc 退出码 = 0
（编译类探针：到此为止，不运行）
```

### `e07_alertaction_handler` —— `UIAlertAction` 上读不回 `handler` —— §25 那份「自己存一份闭包」的凭据

```
===== e07_alertaction_handler (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:21:14: error: value of type 'UIAlertAction' has no member 'handler'
19 | print(action.title ?? "nil")
20 | print(action.isEnabled)
21 | print(action.handler)
   |              `- error: value of type 'UIAlertAction' has no member 'handler'
22 | 
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e08_nil_to_nonnull` —— `nil` 递给 `NS_ASSUME_NONNULL` 里的参数（§30）

```
===== e08_nil_to_nonnull (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:16:31: error: 'nil' is not compatible with expected argument type 'String'
14 | 
15 | ProgressHUD.showSuccess(nil)          // 合法：Swift 侧的类型是 String!
16 | ProgressHUDStrict.showSuccess(nil)    // ← 这一行才是这一支要量的：编译器拒绝
   |                               `- error: 'nil' is not compatible with expected argument type 'String'
17 | 
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e09_history_element_type` —— `NSArray` 没写元素类型 → Swift 拿到 `[Any]`，递给 `[String]`（§30）

```
===== e09_history_element_type (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:16:35: error: cannot assign value of type '[Any]' to type '[String]'
14 | import UIKit
15 | 
16 | let loose: [String] = ProgressHUD.history()
   |                                   |- error: cannot assign value of type '[Any]' to type '[String]'
   |                                   `- note: arguments to generic parameter 'Element' ('Any' and 'String') are expected to be equal
17 | let strict: [String] = ProgressHUDStrict.history()
18 | print(loose, strict)
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `m01_nullability_warning` —— 书 7.12 那句「黄色叹号」的原文：`-Wnullability-completeness`（§30）

```
===== m01_nullability_warning (debug)
--- swiftc 输出 ---
In file included from /Volumes/mac004/code/programming/iosdev/examples/32_app_architecture/probes/m01_nullability_warning.m:4:
/Volumes/mac004/code/programming/iosdev/examples/32_app_architecture/probes/m01_nullability_warning.h:21:26: warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [-Wnullability-completeness]
   21 | + (void)record:(NSString *)text;
      |                          ^
/Volumes/mac004/code/programming/iosdev/examples/32_app_architecture/probes/m01_nullability_warning.h:21:26: note: insert '_Nullable' if the pointer may be null
   21 | + (void)record:(NSString *)text;
      |                          ^
      |                           _Nullable
/Volumes/mac004/code/programming/iosdev/examples/32_app_architecture/probes/m01_nullability_warning.h:21:26: note: insert '_Nonnull' if the pointer should never be null
   21 | + (void)record:(NSString *)text;
      |                          ^
      |                           _Nonnull
1 warning generated.
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
HUDLoose.record 的 Swift 类型：(Optional<String>) -> ()
HUDStrict.record 的 Swift 类型：(String) -> ()
loose history：(
    "\U6765\U81ea Swift \U7684\U4e00\U884c"
)
strict history：["来自 Swift 的一行"]
==== m01 结束 ====
--- stderr ---（空）
```

### `m02_addobject_nil` —— `nil` 递到 `NSMutableArray` 的 `addObject:`：运行期异常，134 / SIGABRT（§30）

```
===== m02_addobject_nil (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
history 现在有 1 条
Swift 侧 record 的参数类型：(Optional<String>) -> ()
下面这一句要递的是 nil（编译期无人拦截）：
--- stderr ---
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[__NSArrayM insertObject:atIndex:]: object cannot be nil'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   CoreFoundation                      0x00007ff8003b1511 -[__NSArrayM removeObjectAtIndex:] + 0
	3   probe.debug                         0x0000000103008755 +[HistoryNoGuard record:] + 85
	4   probe.debug                         0x0000000103008374 main + 1476
	5   dyld                                0x0000000103010478 start_sim + 10
	6   ???                                 0x000000010aafa345 0x0 + 4474250053
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

### `m03_unannotated_header` —— **整份**头文件都不标 nullability：swiftc 日志为空，`record(nil)` 也照样放行（§30）

```
===== m03_unannotated_header (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
record 的 Swift 类型：(Optional<String>) -> ()
history 的 Swift 类型：Array<Any>
收下 1 条，第一条：来自 Swift 的一行
下面这一句递的是 nil（整份都没标，编译期无人拦截）：
仍然收下 2 条，最后一条：(nil)
==== m03 结束 ====
--- stderr ---（空）
```

### `r01_index_out_of_range` —— 书 7.7 结尾「完成最后一道题目的选择后，程序会崩溃」的现场（§8）

```
===== r01_index_out_of_range (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 132
--- stdout ---
屏幕上第 1 题：吃烧烤不能喝啤酒。
屏幕上第 2 题：喝白酒时最好喝茶水。
屏幕上第 3 题：空腹最好不吃柿子。
屏幕上第 4 题：在野外遇到雷雨天气时……
屏幕上第 5 题：参加运动会，临赛前一定要吃饱……
屏幕上第 6 题：面膜做的时间越久越好。
屏幕上第 7 题：晕船时应尽量将头部固定……
屏幕上第 8 题：被鱼刺卡住以后应该猛吃食物……
屏幕上第 9 题：红眼病病人是可以与他人共用生活用品……
屏幕上第 10 题：身上着火后，应迅速用灭火器灭火。
屏幕上第 11 题：创伤伤口内有玻璃碎片等大块异物时……
屏幕上第 12 题：发生煤气中毒时，首先应将门、窗打开通风换气。
屏幕上第 13 题：进行人工呼吸前，应先清除患者口腔内的痰……
--- stderr ---
Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range
Child process terminated with signal 4: Illegal instruction
```

### `r02_negative_tag` —— 忘了在 Inspector 里填 tag：`sender.tag - 1` 算出 -1（§26）

```
===== r02_negative_tag (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 132
--- stdout ---
tag = 0，减一得到下标 -1
这一题有 3 档分值：[6, 3, 0]
--- stderr ---
Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range
Child process terminated with signal 4: Illegal instruction
```

### `r03_hidden_third_option` —— 二选一那一题上调用第三颗按钮：`isHidden` 挡住手，挡不住方法调用（§28）

```
===== r03_hidden_third_option (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 132
--- stdout ---
第 1 题（三选一）按第三颗：0 分 —— 同一条调用在三选一上是安全的
第 2 题（二选一，第三颗按钮 isHidden=true）按第三颗：
--- stderr ---
Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range
Child process terminated with signal 4: Illegal instruction
```

### `r04_wrong_guard_boundary` —— 守卫漏改那一处的下场：13 道题配上 `<= 28`（§29）

```
===== r04_wrong_guard_boundary (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 132
--- stdout ---
屏幕上第 2 题：第2题
屏幕上第 3 题：第3题
屏幕上第 4 题：第4题
屏幕上第 5 题：第5题
屏幕上第 6 题：第6题
屏幕上第 7 题：第7题
屏幕上第 8 题：第8题
屏幕上第 9 题：第9题
屏幕上第 10 题：第10题
屏幕上第 11 题：第11题
屏幕上第 12 题：第12题
屏幕上第 13 题：第13题
--- stderr ---
Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range
Child process terminated with signal 4: Illegal instruction
```

### `r05_kvo_without_dynamic` —— KVO 挂在纯 Swift 属性上的运行时读数：注册那一句当场 trap（§19）

```
===== r05_kvo_without_dynamic (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev32probes/main.swift:38:21: warning: passing reference to non-'@objc dynamic' property 'score' to KVO method 'observe(_:options:changeHandler:)' may lead to unexpected behavior or runtime trap
36 | 
37 | print("下面这一句是注册那个**纯 Swift** 属性的观察者，进程还活着：")
38 | let plainToken = vc.observe(\.score, options: [.old, .new]) { _, change in
   |                     `- warning: passing reference to non-'@objc dynamic' property 'score' to KVO method 'observe(_:options:changeHandler:)' may lead to unexpected behavior or runtime trap
39 |     hits.append("plain \(change.oldValue ?? -1)→\(change.newValue ?? -1)")
40 | }
swiftc 退出码 = 0
运行退出码 = 132
--- stdout ---
对照（@objc dynamic）：改两次命中 2 次 → strict 0→1 strict 1→2
下面这一句是注册那个**纯 Swift** 属性的观察者，进程还活着：
--- stderr ---
Foundation/NSObject.swift:132: Fatal error: Could not extract a String from KeyPath \PlainQuiz.score
Child process terminated with signal 4: Illegal instruction
```

## 「跑起来没反应」排查表

这张表是本章 31 节、148 条断言加 18 支探针的用法说明：**症状 → 本机量到的真因 → 证据位置**。
左列尽量按书里（以及真机上会遇到的）说法写，右两列是本章能给出的、可复现的答案。
凡写「静默」的行，意思是**退出码 0、stderr 为空、stdout 一切正常**，
只有断言读得出来 —— 这类格子必须自己在代码里加账本（本章的 `Trace` 就是干这个的）。

| 症状 | 本机量到的真因 | 证据 |
| --- | --- | --- |
| 答完最后一题再点一下就崩 | `answerPressed` 里 `checkAnswer()` 跑在守卫之前，读的是 `list[questionNumber]`，而它已经等于 `count` | §8；探针 r01（13 题版）、r04（漏改守卫那版） |
| 崩了，但看不出是负数下标还是超界 | Swift 的数组下标只有一处检查，两种越界给的是同一句 `Index out of range` | §8；对照 r01 与 r02 |
| 退出码 132 / 信号 4（SIGILL） | `fatalError()` 那一路（含 Swift 运行时断言失败） | 探针 r01–r05 全是这一类 |
| 退出码 134 / 信号 6（SIGABRT） | OC 异常未被捕获（`NSInvalidArgumentException`），和上面不是同一类 | 探针 m02 |
| 按钮点了没反应 | `sendActions(for:)` 在这条路上不派发 —— 这个产物里没有 window 和事件循环，所以主线直调方法 | §17；第 31 章 §16 |
| 弹窗没出现，日志里什么都没有 | 在没有窗口的 VC 上 `present` 不生效，而且**不报错**：`presentedViewController` 与 `view.window` 都是 `nil`，stderr 空 | §24；第 22 章 |
| HUD 调了、`history` 一行不少，屏幕上什么都没有 | 原库靠 `keyWindow` 把自己 addSubview 上去；本进程没有 window。`frame` 是真的，`window`/`superview` 是 `nil` | §30 |
| 改了 Model，屏幕一个字都没变 | 视图不会自己动 —— 唯一的入口是控制器那句 `updateUI()`（这正是 7.5 那句话的**可执行版**，不是 bug） | §12、§18 |
| `updateUI` 到底被叫了几次数不出来 | 手动那一种没有回执：只有加了账本才数得出 | §18 |
| KVO 注册了却一次都不回调 | 观察的是纯 Swift 属性：编译器只给一条 warning（退出码 0），真拒绝在运行时——注册那一句当场 trap | §19；探针 e06 → r05 |
| `let` 的 Model 字段改不了 / 不能被观察 | `let` 锁的是「不可改」，KVO 需要可换的 setter | 探针 e03 |
| `questionLabel.text = 123` 编不过 | `text` 是 `String?`；`cannot assign value of type 'Int' to type 'String?'` | 探针 e02 |
| 进度条提前一格到头 | `questionNumber + 1` 和守卫 `<= N-1` 相互作用的结构后果，与题数无关 | §14（13 题）、§29（29 题） |
| 换了题库，界面报「13 / 29」 | `updateUI()` 里那个 29 是字面量，和题库条数是两条互不相干的事实 | §29 |
| 结论弹窗是个空白框 | 129 分（可达，= 3×43）正好掉在 `< 129` 与 `>= 130` 之间，落到 `var title = ""` 的初值 | §27 |
| 「最大 EQ 154」按代码怎么都算不出来 | 三档分值都是 3 的倍数，任何一轮总分必是 3 的倍数；`154 % 3 = 1` | §26 |
| 明明只该出现两个选项，程序却崩在下标 2 | `isHidden = true` 挡住的是手，挡不住一个方法调用；判卷层不知道屏幕上少了一颗按钮 | §28；探针 r03 |
| 忘了在 Inspector 里填 tag | `sender.tag - 1` 用出厂值 0 算出 -1，`questionScore[-1]` 当场越界 | §16、§26；探针 r02 |
| 代理回调静默消失 | 代理对象被放掉之后 `weak var delegate` 自己归 `nil`：不崩、不报错、界面照常能动 | §21 |
| 闭包回调不触发 | 环（对象↔闭包↔对象），或者那份闭包压根没被存下来；`UIAlertAction` 上的 `handler` 读不回来 | §22、§25；探针 e07 |
| 断环之后对象还在内存里 | 决定回收时机的是「对象在哪一层自动释放池里造出来」，不是优化等级、也不是引用计数数错 | §25；探针 c01 [5][6][7] |
| Swift 里写 `ProgressHUD.xxx` 找不到这个名字 | 桥接头没被递进去：本仓库认的标记是目录里有 `Bridging.h`（→ `-import-objc-header`） | 「复现」一节 |
| OC 那侧调不到 Swift 的类（连编译都过不了） | 那个类没有同时满足 `NSObject` 子类 + `@objc`，于是**根本不会出现在生成的头文件里**（不是「调不到」，是「看不见」） | §30；`HUDBridge.swift` |
| `history()` 拿回来是 `[Any]`，每个元素都得 `as?` | 头文件里的 `NSArray` 没写元素类型 —— 类型信息在头文件那一侧就丢了 | §30；探针 e09 |
| 递 `nil` 过去编译器一个字都不说 | 参数标的是 `_Null_unspecified`：能不能进来由**另一侧有没有防**决定 | §30；探针 e08（标了nonnull 的那一侧）、m02（没防的那一侧） |
| 一堆黄色叹号「不影响功能」 | `-Wnullability-completeness` 只在**标了一半**的头文件上触发；整份都不标反而安静 | §30；探针 m01（告警原文）、m03（整份不标 → 日志为空） |
| 第三方库整份都不标，日志干净，`nil` 却一路走到底 | 不标 ⇒ Swift 侧是隐式解析可选，编译期无人拦截；出事与否看 OC 那侧有没有防 | §30；探针 m03（有 `?:` 兜住）、m02（没防 → 134 / SIGABRT） |
| `ProgressHUD.isKind(of: UIView.self)` 永远给 `false` | 拿的是**类对象**，它属于 metaclass；实例那一句才是 `true` | §30 |
| 两台控制器共用同一本账 | 单例就是全局可变状态；所以 §30 开头必须先 `reset()` | §30、对照 §20 |
| 一句 `setValue` 就跨过了分层 | MVC 那句话在运行时里没有任何强制力，只有约定和账本两个来源 | §23 |

## 本章能带走的东西

- **分层不是目录，是「同一个意思被写了几遍」。** 这是本章最后剩下的那一条，
  它有两次实测支撑：§29（同一件事写成三处字面量，一处崩、两处静默骗人）
  和 §31（收成一个 `questionCount`，越界变成一次可记录的无操作）。
  `import` 了谁、文件放在哪个 group、类名叫不叫 Model，都不影响这件事。
- **「谁持有谁」在五种机制里是五个不同的答案**，而每种都能当场验：
  手动（谁都不持有，靠记得调用，§18）、KVO（观察者被 token 持有，注册方必须 `@objc dynamic`，§19）、
  NotificationCenter（互不认识，post 是同步的，§20）、代理（必须 `weak`，且协议要 `AnyObject`，§21）、
  闭包（抓住它引用的一切，§22/§25）。
  前三种的失败模式是「忘了写就没有」，后两种的失败模式是「写了就多一条边」。
- **「静默」在本章有四格，每一格的读数都不一样**：`sendActions` 不派发（§17）、
  `present` 不生效（§24）、代理归 nil（§21）、129 掉进区间缝里（§27）。
  它们的共同点是退出码 0、stderr 空。**所以本章的判据一律是读回值**，
  而读回值需要一个账本 —— `Trace`、`progressLabel.text`、`weak var`、`resultAlert` 这四个角色，
  就是本章把「看图」换成「读数」的全部手段。
- **崩溃要分两族**：Swift 的运行时断言（`Fatal error` → 132 / SIGILL）和
  OC 异常（`NSInvalidArgumentException` → 134 / SIGABRT）。
  两族的退出码、信号、原文长相都不同，混编代码里先看数字再看措辞能省下大量时间。
  另外「下标越界」只有一句话，负数和超界分不清 —— 所以排查时**先看是哪一处下标**，
  而不是指望消息告诉你方向（§8）。
- **回收时机不由引用计数单独决定**（§25 + 探针 c01）。这句话值得从本章单独带走：
  「有环 → 泄漏」是对的，「断环 → 当场回收」是不对的。
  Cocoa 工厂方法给回来的对象会进**当时最内层**的自动释放池，
  所以你控制得了的是**在池子的边界上断环**，控制不了它被 autorelease 进哪一层。
- **混编的类型信息由头文件决定，不由实现决定**（§30 第一、二条：同一个 `.m`，
  两份头文件，Swift 侧一个是 `[Any]` 一个是 `[String]`）。
  反方向那条桥的准入条件是 `NSObject` 子类 + `@objc`，不满足时那个类**不会出现在头文件里**。
  连告警的开关也在头文件这一侧，而且它管的不是「没标」：`-Wnullability-completeness`
  只惩罚**一份文件里标了一半**的写法（m01 响；整份都不标的 m03、逐指针手着标的主线都不响），
  所以「拖进来的库一个字没标」在项目里是安静的那一种。
- 本章与前面几章的三条接口：运行时那张表（第 27 章：`responds(to:)`、KVC 的代价、metaclass）、
  字符串即接口（第 31 章：故事板里那些名字，本章 §16 的 tag 是同一族的手填版）、
  可选盒子（第 30 章：`Optional("")` 与 `nil` 的区别在 §27 那一格用上了）。
- **诚实处理边界**：这一章覆盖的是状态、类型、桥接、回收四件事；
  渲染、事件派发、生命周期三件事它一条都没验证（结尾那行「本章没做到的事」是判据的一部分，
  不是免责声明）。三处「不生效」（§17/§24/§30）来自同一个缺失的 window，
  所以任何一条「没反应」先问这一格是不是依赖那个不存在的运行循环。

---

上一章：[31 Interface Builder：故事板、XIB 与代码之间的接线](31-interface-builder.md) · 下一章：[33 依赖管理：`import` 那一行背后，谁在算模块搜索路径](33-dependency-management.md)
