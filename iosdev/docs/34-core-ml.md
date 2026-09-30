# 34 · Core ML：一个模型文件的 46 个字节、一次断言、和一条走不通的摄像头路

> 示例：`examples/34_core_ml/main.swift`（同级 `tiny_scaler.swift` —— `coremlcompiler generate` 的原样产物、`Frameworks`，以及 `probes/` 4 支探针 + `run.sh`）
> 实测输出见 `build/34_core_ml/stdout.debug.txt`

《跟着项目学iOS应用开发：基于Swift 4》的第 15 章是全书**最后一章**，也是唯一一章把
「别人算好的东西」放进 App：`第15章 机器学习和Core-ML`。它的开场就把这一章的野心说清楚了
——「通过苹果最新的机器学习框架，我们可以在应用程序开发中让我们的应用更加智能。在2017年6月
WWDC开发者大会上，苹果发布了机器学习……本章先会向大家介绍什么是机器学习（Machine Learning）……
然后会向大家介绍当前可以使用的不同类型的机器学习……最后我们会通过实战练习会教给大家如何使用
Core-ML在iOS中用Swift语言去实现可视化的识别」。节次是：

- **15.1 介绍机器学习**：15.1.1 机器学习 / 15.1.2 监督式学习 / 15.1.3 非监督式学习 /
  15.1.4 强化学习 —— 四节全是概念，一行代码都没有；
- **15.2 Core-ML——整合机器学习到iOS应用中**：15.2.1 什么是Core-ML / 15.2.2 Core-ML能做什么 /
  15.2.3 如何识别图像并反馈结果 / 15.2.4 判断图片中的食物。

实战项目叫 **SeeFood**：拍一张照片，问模型「这是热狗吗」。原书 15.2 那条流水线是：

1. **15.2.1**「我们将会把预先训练好的数据模型转换到.mlmodel文件之中，它是一个**完全的开放**的
   文件格式，并且包含了所有的输入输出」；Core-ML 允许两件事 —— 载入一个预先训练好的模型
   （并「将这个模型转换为一个类，让这个类在Xcode中使用」），以及「做一个断言（Predication）」；
   同一节还写明了它**不能**做什么：「我们不能使用自己的应用生成的那些数据样本来训练机器。
   当我们安装了一个提前训练好的模型时，它就相当于一个静态模型」「Core-ML不加密」。
2. **15.2.2** 从 `developer.apple.com/machine-learning` 下载 Inception V3（「它能够检测出一千种
   物体」），拖进工程，「一旦我们将Inceptionv3.mlmodel文件添加到项目之中，在项目导航中单击该
   文件以后，在编辑窗口中我们就可以看到Xcode已经为该模型创建了一个**Model Class**」；
   然后 `import CoreML` / `import Vision`、`UIImagePickerController` 拍照、`sourceType = .camera`，
   并在 步骤3 补 `Privacy - Camera Usage Description` —— 因为不补就
   「应用程序会发生崩溃……reason：'Source type 1 not available'」。
3. **15.2.3**「我们需要将从照片获取器得到的UIImage对象转换为CIImage对象，因为它是标准的
   Core Image图像，而且**在使用Vision和Core-ML框架中的方法时，必须要用这种特定类型**」，
   然后三行：
   ```swift
   guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { fatalError("载入CoreML模型失败") }
   let request = VNCoreMLRequest(model: model) { (request, error) in
       guard let results = request.results as? [VNClassificationObservation] else { fatalError("模型处理图像失败") }
       print(results)
   }
   let handler = VNImageRequestHandler(ciImage: image)
   try! handler.perform([request])
   ```
4. **15.2.4**「我们需要获取其中的第一个元素……注意，第一个元素所提供的信息是相似度最高的」：
   ```swift
   if let firstResult = results.first {
       if firstResult.identifier.contains("hotdog") { self.navigationItem.title = "热狗！" }
       else { self.navigationItem.title = "不是热狗！" }
   }
   ```
   判据仍是这一类：**「构建并运行项目」**，然后看图 15-15 那串控制台输出
   （「与猕猴（macaque）有97.9313%相似度」）。

## 15.1 介绍机器学习：先把书本那四节说透

这一节**不压缩**。书本用四节篇幅讲「机器学习是什么」，本章后面每一节里那些名词（训练样本、
标签、分类、概率、特征）都是从这儿来的；把它们压成一句「模型输入→输出」，§13~§14 那些
断言就没有可读的对象了。原书的写法是每个概念配一个比喻，下面逐个把比喻讲完，再逐个接回
本章在字节层量到的对应物。

### 15.1.1 「使计算机能够在没有明确编程的情况下进行学习」

书本的起手式是先把自己这一路的对立面的活儿描述清楚：「本书自始至终都是教大家如何使用Swift
语言进行程序开发，执行指令的设备不是计算机而是iPhone或者iPad。我们用一些明确的指令告诉它们
要做什么，比如我们之前所做的Quizzler项目的应用，只有在用户单击了正确答案以后，iPhone才会
显示一个对勾，告诉用户他答对了。这里我们使用了条件判断语句。」——这就是「明确编程」：
**规则是人写的，写在源代码里**，第 30 章那个 `if` 就是它。

然后书本提出反面的做法：「如果反过来，我们让计算机去回答这些问题，然后我们就像教自己的孩子
一样，教会计算机这些知识哪些是对的，哪些是错的，通过不断地体验来积累它们的知识技能，这就是
机器学习。」

紧接着是那个 BB-8 的比喻（图 15-1），它把两种做法的差别摊得很开：

- **明确编程**：「我们可以编写程序，让它先往前走，当遇到障碍物无法向前走的时候让它向右转」，
  书本立刻指出这套写法的死穴 ——「如果遮挡物移动到了其他位置，我们的程序代码就没有任何意义了，
  因为BB 8还是会按照原来的程序流程进行移动」。你可以补规则（先确定终点坐标、用路由算法求最短路、
  遇到障碍就左右躲闪），但每一条都得你预先想到。
- **机器学习**：「我们可以只是简单地告诉BB 8你需要到达标旗终点就可以了。在这一过程中，它可能会
  走一些弯路，也有可能会走出不同的线路。一旦它到达终点，我们就会告诉它：All right，你走到了
  目的地。随着时间的流逝，如果我们让BB 8保持这种不断的训练，它就会通过学习，来减少遇到遮挡物的
  次数，并找出最短的路由到达终点。而整个过程我们都不需要编写明确的代码，这就是机器学习的本质。」

书本随后给出定义并署名：「使计算机能够在没有明确编程的情况下进行学习。说这句话的人叫
亚瑟·塞缪尔，他是机器学习的先驱之一，他第一个编写了能够称之为机器学习的算法。他在不给计算机
编写任何明确代码的情况下，让机器自己去尝试和学习如何下国际象棋，然后再不断地重复游戏并提高
自己的下棋水平。」最后落一句分类学：「机器学习通常被分为两个类别：一个是监督式学习，另一个是
非监督式学习，这与我们要如何训练机器模型相关。」（下一小节还要补第三种：强化学习。）

**这四样东西在字节层分别是什么**，是本章 §1 要量的。把上面那段话拆成零件：

| 概念 | 书本的说法 | 在本章的一份 `.mlmodel` 里剩下的东西 |
| --- | --- | --- |
| 规则 | 「明确指令」「条件判断语句」 | **不在文件里**。它在 App 源代码里，而 Core ML 的模型文件里没有 if |
| 学习的结果 | 「积累知识技能」 | 一组**数字**：§1 那两个 double（`offset=10`、`scale=2`），§13 那 26 559 字节的树 |
| 训练 | 「不断地体验」「保持这种不断的训练」 | **没有**。§13 实测 `isUpdatable=false`，15.2.1 自己就写了「不能用自己的数据训练」 |
| 体验的接口 | 「告诉它你走到了目的地」 | 一次 `prediction(from:)`：§5 的 `scaler.prediction(x: 0.5).y` |

这里有一条诚实的观察，值得单独说：**本章 §1 手写的这份「模型」其实就是一段明确编程** ——
`y = (x + 10) × 2`，两个数是**我**写进去的（§5 用四组物理量把它们反读出来，实测
`offset=10.0 scale=2.0 x=0.5 -> y=21.0  与 21.0 相等`）。它之所以能当机器学习的例子用，
不在于这条式子有多简单，而在于**在真流程里那两个人是从数据里算出来的**：写死在 Swift 源码里
的加 10 乘 2，是「明确编程」；同样一条式子、同样两个数，从 `.mlmodel` 的字节里读出来，就是
「一个预先训练好的模型」。**文件与代码的区别不是复杂度，是谁来决定那两个人。** 这条界线
在 §1 的 hex 上看得见：那 46 个字节里没有任何控制流，只有「规格版本 + 输入输出表 + 一组参数」。

### 15.1.2 监督式学习：每个训练样本都带标签

书本的定义：「监督式学习（Supervised Learning），相当于你要手把手教计算机要学习的东西。
一个最著名的例子就是教计算机如何识别一只猫。」

它把「手把手」这件事拆成三步，每步都对应一个后面会用到的名词：

1. **带标签的样本**。「我们为计算机提供了非常多的猫的图片，并且在提供图片的同时，还为它提供了
   一个标签（Label），告诉它这张图片里的动物是猫。通过标签和图像的混合数据，机器便知道了这是
   一只猫。这也就是为什么在监督式机器学习中，**所有训练样本都是带标签的**。」
2. **泛化**。「直到有一次我们只提供给计算机猫的一部分的图片（图 15-3），即使在没有标签的情况下，
   机器也能够识别出它是一只猫，因为这张图片包含了很多猫的特性，并与之前所提供猫的图片非常类似。」
3. **模型 / 训练样本 / 测试数据 / 输出 这四个词**。「在训练机器学习模型（Machine Learning Model）
   的时候，我们实际上会提供很多的图片，而且每张图片都会带有一个非常明确的标签。例如我们将一大堆
   狗的图片、一大堆猫的图片和一大堆奶牛的图片，都灌进机器学习模型之中……机器通过之前的学习经验，
   开始去分类这些图片，把它们都放在独立的分组中（图 15-4）。在这种情况下，**模型**就是机器中与
   学习相关的事情。你提供的图片就是**训练样本**。一旦我们完成了训练，再给机器提供一张训练样本中
   没有的图片，机器可以基于之前的学习，识别出这是一张狗的图片，并且最终拼写出答案——这是一只狗。
   在这里，我们管这张机器从来没有见过的图片叫**测试数据**，我们管输出的内容叫**输出（output）**。
   输出可以有各种形式，比如文字、在棋盘上所走的一步棋等。输出的结果依赖于我们如何训练模型，
   以及我们想要它做什么。」

然后是这一节最锋利的一段 —— **分类为什么难**（书本用苹果和梨）：「你想让计算机学习关于苹果和梨
之间的不同。这对于人类来说是一件非常容易的事情。但是在程序中，我们必须要告诉计算机，在苹果和梨
之间都有哪些不同。其实，这是一个非常复杂的问题，因为你需要让计算机将这两张图放大到可以看到
每一个像素，一般来说，苹果图片趋向于更多的红色，而梨趋向于更多的绿色。但是如果我们又提供给
计算机一个绿色的苹果，那么计算机可能就会基于之前的学习，把它标识为梨。所以说，我们需要用更多的
代码去设置苹果的特性，比如我们会说苹果比梨更圆一些、更红一些等。」
再加一句关于**没见过的东西**：「你可以尝试着给计算机呈现一些它之前没有见过的东西，比如说桃，
这相当于一种异常事件，因为它既不属于苹果，也不属于梨。计算机会使用我们之前所设定的规则，
尝试着将它分类。」

书本接着讲**复用**和那条**临界线**（垃圾邮件）：「有关机器学习模型有一件非常好的事情，就是可以
复用它。我们可以创建一个泛型分类，将手写数字识别成整型数，也就是相当于OCR。同时你可以使用
相同的范型分类，再次进行更深层次的训练。」然后是那段最有工程味道的描述：「我们可以创建这样
一个图表。图表中有一条线代表**临界值**，如果电子邮件达到了临界值以上，该邮件就会进入垃圾邮件，
否则会进入收件箱。这个临界值是如何生成的呢？我们会有一个垃圾的智能过滤程序，我们在训练这个
模型的时候使用了大批的邮件，并且为这些邮件都提供了垃圾或者是非垃圾的标签……机器学习模型的
工作就是尝试着去绘制这样一条线，通过所提供的训练样本，**找出链接是多少的这个临界点**。比如说，
这个邮件中的链接数少于5个，那它可能就是正常的邮件……这只是分辨垃圾邮件时涉及的众多特性中的一个，
我们还可以通过邮件内容中的图片数量或者是邮件中『销售』『购买』等关键字的数量来确定。这样的学习
会持续很长的时间。在邮箱中，每一次被标记为垃圾的邮件，都相当于给了机器学习一次机会。机器还会
根据新的数据或者新的特性，来增加判断的准确性。」

把这段翻译成本章的术语，一件一件都对得上，而且都能在运行时读出来：

- **标签（Label）** → §13 那份真模型里的 `classLabels`，实测 `有 2 项：["0", "1"]`。
  「监督式」的意思就是训练时有人把每张图/每行数据报了一个类别名；这个名字表会跟着文件走。
- **特征（特性 / feature）** → 书本说「链接数」「图片数量」「苹果更圆一些」，Core ML 里就叫
  input feature，而且**名字写在文件里**：§13 实测
  `五个输入特征：["battery_duration_1", "battery_duration_2", "battery_duration_3", "battery_duration_4", "plugin_battery_level"]`。
  这正是书本那段「众多特性」在本机的形状：这份模型选了五个电池量当特征，每个是 double（§13
  逐条断言 `battery_duration_1 是 double`）。
- **输出 / 判决** → `predictedFeatureName`，实测 `next_discharge_is_shallow`。
- **那条临界线** → 书本画的是一条直线（链接数 vs 垃圾与否）。§1 那份 scaler 就是它的**代数形式**：
  `y = (x + 10) × 2`，一条直线、两个参数。所谓「模型的工作是找出这个临界点」，落到字节上就是
  「找出这两个 double」；§5 那四组对照实测把它们反读回来（`offset=0.0 scale=1.0 -> y=0.5`、
  `offset=10.0 scale=2.0 -> y=21.0`）。书本画的那条线在 §8 里也照样是线：一次喂六个元素，
  每个元素各自过同一条直线。
- **「相似度」** → 书本 15.2.3 那句「排在输出第一位的就是相似度最高的名称」，§14 量到它的真身：
  一张**归一化的概率字典**，实测 `[0: 0.7953935062846612, 1: 0.20460649371533882]`，
  并且 `概率求和 1.0 == 1`。换句话说，「相似度」不是原始得分，是被除过总和的。
- **复用 / 再训练** → 书本说「可以复用它……再次进行更深层次的训练」。§13 实测
  `isUpdatable=false`：**设备端这份文件不带再训练的能力**。复用能做到（同一份模型可以喂很多
  种输入、可以被多个 App 打包带走），但「更深层次的训练」不在 Core ML 的运行时代码里，
  那一步在训练机上，在书外。

### 15.1.3 非监督式学习：不知道类别名字也要分组

书本先给差别：「非监督式学习与监督学习的不同之处在于，**事先没有任何的训练样本**，而需要直接
对数据进行建模。这听起来似乎有点不可思议，但是在我们自身认识世界的过程中有很多地方都用到了
非监督式学习。」

然后是那个画展的比喻：「比如我们去参观一个画展，我们对艺术一无所知，但是欣赏完多幅作品之后，
我们也能把它们分成不同的派别，比如哪些画更朦胧一点，哪些画更写实一些。即使我们不知道什么叫
朦胧派，什么叫写实派，但是至少我们能把它们分为两类。」

再点名典型算法并给出它的唯一要求：「非监督式学习里典型的例子就是**聚类（Clustering）**了。
聚类的目的在于把相似的东西聚在一起，而**我们并不关心这一类是什么**。因此，一个聚类算法通常
**只需要知道如何计算相似度**就可以了。」

最后是那句「什么时候用哪种」的回答与它的补丁：「如果我们在分类的过程中有训练样本
（Training Data），则可以考虑用监督式学习方法；如果没有训练样本，那就不可能用监督式学习了。
但是事实上，我们在针对一个现实问题进行解答的过程中，即使没有现成的训练样本，我们也能够凭借
自己的双眼，从待分类的数据中人工标注一些样本，并把它们作为训练样本，这样的话就可以用监督式
学习的方法来做了。」

这一节在本章**没有对应的实测**，而且值得直说为什么没有：

- 监督式的产物形状是「输入 → 类别/数值 + 概率」，§13/§14 那份真模型就是这个形状，
  所以能用一个断言卡住（第一名对不对、概率加成 1 不等于 1）。
- 聚类的产物是「分组」本身，类别**没有名字**，所以没有任何外部标签可以对表。它照样能装进一个模型文件
  （§1 那棵树里 `Model` 的参数位是一个 oneof，苹果自己那份真模型用的是决策树 `f402`， scaler 用的是 `f604`，
  神经网络是 `f500` —— 这三号都是读回来的），但本章的判据是
  「能不能被一条与输入无关、又与机器无关的断言卡住」——一个分组结果没有「对不对」，
  只有「像不像」。书本自己那句话就是这一节的结论：**非监督式学习里我们不关心这一类是什么**；
  一旦不关心「是什么」，本章这种「读名字、读概率」的量法就失效了。
- 所以这一节在本仓库留下的唯一可执行痕迹是 §8：一个六元素的张量进、六个数出，
  「相似度」这件事在 API 里能读到的最原始形态就是一串数。把一串数当成距离去分组，
  是那串数**出去之后**的代码要做的活儿，归第 6 章那类 Foundation 集合操作，不归 Core ML。

顺带把书本那句补丁记牢，因为它解释了为什么现实里监督式占了绝大多数：没有标签就自己标。
书本 15.2.1 提到苹果那个模型页「提供了已经训练好的『即插即用』的模型」，说的正是这件事的
省事版 —— 别人（和别的数据量）替你标完了。

### 15.1.4 强化学习：让奖赏代替标签

书本用两个体感的例子开场，一负一正。负的那个先讲代价：「如果我们在使用烤箱烘焙食物的时候，
用手指触碰了里面非常热的东西，这个时候我们就会被灼伤，在未来的一段时间，我们就不会再触碰它了。
因为疼痛的灼伤感，强化了我们对这个操作的记忆。但是这种记忆方式是比较残酷的，这可能导致我们
自身受到很多的伤害，因此像这种负能量的学习是不可取的（图 15-6）。」
正的那个给出常规做法：「我们使用更多的强化学习方式是**正向奖赏**，例如我们训练一只狗，让它
按照我们的要求做出某些动作，当我们在给狗下达『坐下』指令以后，它按照要求坐下，我们就会给它
一定的奖赏，让它知道，自己做了一件正确的事情。这就是强化学习。」

然后是那个把「奖赏」变成可计算量的棋局描述：「在强化学习中，一个最具代表性的应用就是下棋。
假设棋盘左方的选手是使用了强化学习算法的机器。它会持续地去计算下棋期间**赢的可能性**。
如果它实际走一步棋，并且这一步棋增加了赢的可能性，那么这就是**正向强化**。如果对手此时进行了
有效还击，并减少了机器赢的可能性，这就是**负向强化**。机器通过与人下非常多的棋，并通过非常多
的训练周期，就能够学到如何下每一步棋，从而让机器赢的可能性增加。现在世界上最著名的强化学习
的应用程序就是谷歌的AlphaGo。」

和前三种比一下，就能看出它在设备端为什么完全不出场：

| 种类 | 监督信号 | 数据形状 | 本章能不能量 |
| --- | --- | --- | --- |
| 监督式 | 每个样本一个标签 | `(特征…, 标签)` 的表 | 能（§13/§14：`classLabels` + 概率字典） |
| 非监督式 | 无（只给相似度） | 一堆样本 | 判据失效（上面说了为什么） |
| 强化学习 | 一整串动作之后的一次奖赏 | 状态→动作→奖赏的**序列**，而且是边玩边采 | **不能**：它要的是「多次试验＋不断调整」，而 15.2.1 明写「它就相当于一个静态模型」 |

强化学习要求「持续的尝试」，Core ML 给的是「一次前向计算」：§5 那行
`scaler.prediction(x: 0.5).y`、§6 那批 `predictions(inputs:)` 里没有任何位置能塞进
「这一步走完再告诉我好不好」。所以书本这一段在本章只剩一个间接痕迹 —— 「赢的可能性」这句话
的形状就是 §14 那个 **0 到 1 之间、加总为 1 的数**：只要一个模型对外报「把握」，
它在 API 里就必须长成概率的样子，这一点在三种学习里是共用的。

### 15.1 的账：四节概念里，本章能卡住的是哪几条

- 能卡（有断言）：模型 = 输入输出表 + 参数（§1、§7）、特征名与类型（§7、§13）、
  标签表（§13）、归一化概率与第一名（§14）、一次前向计算（§5、§6）。
- 不能卡：训练（设备端没有这条路，15.2.1 自己说了）、聚类的「分组对不对」（判据不存在）、
  强化学习的「试多次」（接口不存在）。

## 15.2 这一章的换法（每条都有实测支撑）

本机跑不动原书那条流水线上的三处：**没有 Xcode 工程**（本仓库每条示例只是一次 `swiftc` 调用
加 `xcrun simctl spawn`，见 `run-all.sh`），所以「拖进去自动出现的 Model Class」没人替你生成；
**不联网**，那个几十兆的 Inception v3 下载不下来；**模拟器没有摄像头**，`UIImagePickerController`
那半条路只能量成三个布尔值。

但这一章的核心一句话就能保住：**Core ML 吃的是磁盘上一份 protobuf，模型类只是那段 protobuf 的
Swift 语法糖**。于是本章换成同一批角色在本机的对应物：

| 书 15.2 里的东西 | 本机对应物 | 量它的 § |
| --- | --- | --- |
| 「预先训练好的模型」从网站下载 | 在 Swift 里**逐字节手写**一份规格（46 字节，附 hex 和一份自带的 wire 解码器） | §1；探针 g01 |
| 系统里那份现成的真模型 | 只读复用 `/System/Library/PrivateFrameworks/PowerUI.framework/…/shallow_model.mlmodel`（26 881 字节） | §13、§14 |
| 「拖进 Xcode 就自动编译」 | 设备上那条公开 API：`MLModel.compileModel(at:)` | §2、§3 |
| 「转换成一个 Model Class」 | 同一条 `xcrun coremlcompiler generate --language Swift` 的产物，原样提交进仓库并真的调用它 | §5；探针 a01 |
| 「做一个断言（Predication）」 | `scaler.prediction(x: 0.5).y`，外加批量那条 `predictions(inputs:)` | §5、§6 |
| `UIImage` → `CIImage` → Vision | 第 29 章那套 Quartz 2D 画一张四色图，走书本那三行的同一条通路 | §11 |
| 「相似度最高的第一个元素」 | 真分类器的概率字典 + argmax（书本那个 `results.first` 就是它） | §14 |
| 拍照（`sourceType = .camera`）＋ Info.plist 权限描述 | 三个能力布尔值 + 一次授权状态读数 | §15 |
| 「在设备上跑」（书本没提 ANE） | `availableComputeDevices` 只有 cpu/gpu，四种 `computeUnits` 输出逐字节一致 | §16 |
| 图 15-15 那串控制台输出 | 没有 UI：判据换成「同一段字节的三条入口都跑通、且结果不依赖优化配置与芯片选择」 | §19 |

三处「本机做不到」最后变成了三条钉死位置的墙（§18 + 探针 a01/r01），它们不是遗憾，
是这一章的**边界条件**：手写不出带分类头的图像模型，结构自省只吃编译产物，
`coremlcompiler` 是主机程序、示例跑在设备上。

## 本章的账本结构

```
字节   §1  一个 .mlmodel 就是 46 个字节：写出来，再读回来
字节   §2  compileModel(at:)：.mlmodel → .mlmodelc，产物里只有两样东西
字节   §3  载入只吃 .mlmodelc：把 .mlmodel 直接递过去会怎样
入口   §4  MLModelAsset(specification: Data)：连临时文件都不用的第二条入口
入口   §5  Model Class：46 字节进去，293 行 Swift 出来，然后真的用它断言一次
入口   §6  predictions(inputs:)：三行输入一次跑完
自省   §7  modelDescription：输入输出表在运行时读回来
自省   §8  多维数组特征：shape 与 dataType 是读出来的，不是代码里规定的
自省   §9  手写一层神经网络：LayerParams 的字段号 130 是 activation
自省   §10 MLModelStructure：层的名字、类型、进出张量（只有编译产物有这一层）
通路   §11 Vision：一张自己画的图，走书本 15.2.3 那条通路
通路   §12 原书那句 as? [VNClassificationObservation] 的 guard 到底在挡什么
真模型 §13 只读复用一份真模型：26 881 个字节的决策树分类器
真模型 §14 概率字典与第一名：书本那个「相似度最高的第一个元素」
边界   §15 UIImagePickerController 那半条路：原书为什么「必须运行在真机上」
边界   §16 computeUnits 与 availableComputeDevices：ANE 在模拟器里不存在
宽容   §17 喂进去的东西：多余的被忽略，窄化的被接受，类型跨不过去
收口   §18 手写不出来 / 跑不起来的东西：把墙的位置钉死
收口   §19 本章唯一一条「模型接上了」的判据
```

## 复现

```bash
cd iosdev
./run-all.sh 34                          # 主线：两配置各编一遍 + 模拟器跑 + 六条判定 + 两份 stdout 比对
bash examples/34_core_ml/probes/run.sh              # 全部 4 支探针
bash examples/34_core_ml/probes/run.sh a01 g01      # 只跑编号前缀匹配的
```

本章是全书第一例**不提交任何模型文件**的 ML 章节：`.mlmodel` 的字节由 Swift 现场写出来、
落成临时文件、在模拟器里编译。目录里只有四样东西：

- `main.swift` —— 主线，19 节；
- `tiny_scaler.swift` —— **例外**，它是 `coremlcompiler generate` 的原样产物（293 行、
  10 961 字节，头部那句 `This file was automatically generated and should not be edited.` 也在），
  提交进来是因为主线要**用它**（§5）；书本 15.2.2 那个「自动出现的类」在本机没人替你生成；
- `Frameworks` —— `CoreML / Vision / CoreVideo / AVFoundation / CoreImage` 五行，
  `run-all.sh` 逐行拼成 `-framework X`；
- `probes/` —— 4 支探针与 `run.sh`。

`probes/run.sh` 的三族分工写在它自己头部注释里，本文末尾「探针记录」逐支抄了原文：

- `aNN_*` 主机工具链现场 —— macOS 上直接跑 `xcrun coremlcompiler`，抄命令原文、退出码、
  产物字节数（主线跑在模拟器里，碰不到那个可执行文件）；
- `rNN_*` 运行期现场 —— 编成模拟器可执行文件再 `simctl spawn`，抄 stdout / stderr / 退出码 /
  崩溃原文；这一族**故意**摔在错误路径上；
- `gNN_*` 字节层取证 —— 同样在模拟器里跑（真模型只在设备侧的 `/System` 分区里可读），
  把 `.mlmodel` 的 protobuf 树整个摊开看字段号。

四处跑法上的细节，都是本章实测踩出来的：

1. **主线不能有地址、耗时、容器路径。** §3 那条错误原文的前半截是模拟器的容器绝对路径，
   所以主线只断言它**包含** `Compile the model with Xcode`，打印的是那句判断句的尾巴；
   探针 r01 里那条完整原文（带 `/Users/xulun/Library/Developer/CoreSimulator/Devices/…`）
   留在这里，不进主线；
2. **`__MLModelStructure` 要 iOS 17.4，`MLModelAsset(specification:)` 要 iOS 16**，
   而部署目标是 `x86_64-apple-ios15.0-simulator` —— 所以这两处包在 `if #available` 里；
   本机的模拟器是 18.3，两支都真的执行到了（不是走 else 分支「跳过」）；
3. **顶层代码里 `guard #available` 不收窄作用域**：探针 r01 第一版写的是 `guard … else { exit(0) }`，
   `swiftc` 照样报 `'__MLModelStructure' is only available in iOS 17.4 or newer`（退出码 1）。
   换成 `if #available(iOS 17.4, *) { … }` 才编得过 —— 函数里那种写法可以，顶层不行；
4. **r01 那支必须等回调才有意义**。它调用 `loadContents(of:)` 之后立刻 exit 的话，退出码是 0、
   stderr 全空，看起来像「它没报错」；加上 20 秒等待之后才看到 signal 6。异步崩溃是这类
   探针最容易读错的一种。

---

## §1 一个模型文件就是 46 个字节，而且它「完全的开放」

**书本**（15.2.1）：「我们将会把预先训练好的数据模型转换到.mlmodel文件之中，它是一个完全的
开放的文件格式，并且包含了所有的输入输出。」这句话有两个可量的断言：**完全开放**（任何程序
都能读，不需要 Apple 的私钥）和**包含所有输入输出**（名字、类型都在文件里）。

**本机怎么量**：`.mlmodel` 不是 Apple 的私有格式，它就是一份 protobuf（Protocol Buffers）
序列化出来的字节。protobuf 的二进制规则小得惊人，每条字段只写三样东西：

- tag = `(字段号 << 3) | 线型`，本身用 varint 编码；
- 线型 0：一个 varint 整数（枚举、int32/int64/bool 都走这里）；
- 线型 1：8 个字节（double 定长小端）；
- 线型 2：先一个 varint 说「后面有多少字节」，再紧跟那堆字节 —— 字符串、字节数组、
  **以及嵌套消息**全都用它（消息套消息就是 LEN 前面再套一层 LEN）。

varint 就是「每字节低 7 位是数据，最高位说还要不要继续读下一字节」，所以 1 个字节写 0…127，
两个字节写 128…16383。**字段号是规格里定的，跟名字没有关系** —— 名字只存在于 `.proto`
那份 schema 里，而 schema 在本机一个字节都拿不到（没有 coremltools，也不联网）。于是本章
所有字段号只能来自两处：苹果自己的真模型（用同一个解码器读出来的树，见探针 g01），
以及 `coremlcompiler` 校验器摔回来的那句原话（见 §18）。

主线里有一个 46 行的编码器（`enum PB`）和一个 60 行的**解码器**（`enum Wire`）。模型选的是
规格里最小的那一种可运行种类：scaler（字段号 604），两个 double 参数 —— 它就是 15.1.2 那条
「临界线」。

```swift
func scalerSpec(offset: Double, scale: Double) -> Bytes {
    modelSpec(inputs: [("x", ftDouble())], outputs: [("y", ftDouble())], predicted: "y",
              paramsField: 604, params: PB.dbl(1, offset) + PB.dbl(2, scale))
}
```

**实测**：

```
== §1 一个 .mlmodel 就是 46 个字节：写出来，再读回来 ==
  ok   手写规格 46 个字节，一个字节不多：模型 = 规格版本 + 输入输出表 + 一个 scaler
hex: 080112150a070a01781a02120052070a01791a0212005a0179e22512090000000000002440110000000000000040
  f1 varint 1
  f2 msg len=21
    f1 msg len=7
      f1 str "x"
      f3 msg len=2
        f2 bytes len=0 
    f10 msg len=7
      f1 str "y"
      f3 msg len=2
        f2 bytes len=0 
    f11 str "y"
  f604 msg len=18
    f1 double 10.0 [0000000000002440]
    f2 double 2.0 [0000000000000040]
  ok   第一行是 f1 varint 1 —— Model 的字段 1 就是 specificationVersion
  ok   输入的名字就躺在描述里（这里读回来是字符串 "x"）
  ok   scaler 的第一个 double 是 10.0，8 字节小端，规格里没有 .proto 也能读出来
```

**读这棵树**（这就是那张「所有输入输出」的表，一个字节都不多）：

| 树里的位置 | 它是什么 | 号是哪儿来的 |
| --- | --- | --- |
| `f1 varint 1` | `Model.specificationVersion` | g01：真模型第一个字段同样是 `f1 varint 1` |
| `f2 msg len=21` | `Model.description`（ModelDescription） | 真模型的 `f2 msg len=312` |
| `f2.f1` | `ModelDescription.input`（repeated FeatureDescription） | 真模型里它出现 5 次 |
| `f2.f10` | `ModelDescription.output`（repeated） | 真模型里 2 次 |
| `f2.f11 str "y"` | `predictedFeatureName` | 真模型是 `f11 str "next_discharge_is_shallow"` |
| `f2.f12` | `predictedProbabilitiesName` —— 本章没写它，§13 读到它（g01 里真模型有这行） |
| `f2.f100` | `metadata`（repeated StringToStringMapEntry） | 真模型 `f100 msg len=73`，§13 那五行元数据就是从它来的 |
| `FeatureDescription.f1` / `f2` / `f3` | name / shortDescription / type | §7 实测 `MLFeatureDescription 上只有 name/type/可选标记和三个约束` |
| `FeatureType` 的 oneof：`1` int64、`2` double、`3` string、`4` image、`5` multiArray、`6` dictionary | `f3 msg len=2` 里面那个 `f2` 就是 double | §7 从运行时读回的号（`x 的类型 2`）与 g01 从真模型读回的成员（`f2 bytes len=0`）互证 |
| `f604` | `Model.scaler` | §18 三段原话 + 真模型的 402（树）与 500（神经网络）同一层 |

**最锋利的一条**：`f2 bytes len=0` 里**一个字节都没有**。oneof 靠「这个字段号出现过没有」
来表示类型，所以类型成员本身是空的。这条的直接后果写在主线那句说明里：

> 说明：oneof 的类型成员（上面那个 f2/f3 msg len=0）里一个字节都没有 —— 光看字节分不清
> 是 double 还是 int64，字段号到名字的映射只存在于 `.proto` 那份 schema 里。

所以「完全开放」这句话要说得精确一点：**格式开放（任何人能读），语义不免费（不看 schema
你只知道号，不知道名字）**。§7 会把名字读回来，§13 会读真模型的名字，两处都不需要 `.proto` ——
名字本来就写在字节里（`f1 str "x"`），需要 schema 的只是「号→字段名」那一份对照表。

## §2 `MLModel.compileModel(at:)`：书本里 Xcode 点 Build 时偷偷做的那一步

**书本**：15.2.2 步骤2 把 `.mlmodel` 拖进工程，之后一切自动发生 —— 它没有说这一步发生了什么。
**本机**：这一步有名字，而且在设备上是公开的类方法。

```swift
let compiledURL = try MLModel.compileModel(at: tinyURL)
```

**实测**：

```
== §2 MLModel.compileModel(at:)：把 .mlmodel 换成能载入的 .mlmodelc ==
  ok   编译产物只有两样东西：analytics, coremldata.bin
  ok   产物目录的后缀是 .mlmodelc —— 拖进 Xcode 时那个「自动编译」干的就是这一步
  ok   coremldata.bin 123 个字节，比 46 字节的规格大 —— 编译期把「规格」换成了「引擎能执行的计划」
```

注意那个 123 对 46：规格字节被**展开**成了执行计划。主机上同一条命令（`xcrun coremlcompiler
compile`）的产物多一个 `metadata.json`，三样东西的字节数在探针 a01 里逐字抄着：
`analytics/coremldata.bin` 141、`coremldata.bin` 123、`metadata.json` 898。
设备上那条 API 造的目录只有两样（`analytics` 是个目录，`contentsOfDirectory(atPath:)` 数不到
它里面的东西），这是本章第一次看见「编译产物 ≠ 模型文件」的形状 —— 后面 §3、§10 全部
由这条界线决定。

## §3 载入只吃 `.mlmodelc`：错误原话直接告诉你缺了哪一步

**本机**：故意把 §1 那份 `.mlmodel` 直接递给 `MLModel(contentsOf:)`。

```
== §3 载入只吃 .mlmodelc：把 .mlmodel 直接递过去会怎样 ==
  ok   错误原话直接告诉你缺了哪一步：l. Compile the model with Xcode or `MLModel.compileModel(at:)`. 
  ok   domain=com.apple.CoreML code=0 —— 载入失败是 Core ML 自己报的，不是文件系统
```

那句 `firstLine(...)` 打的是原文最后 64 个字符，因为前半截是模拟器的容器绝对路径
（每台机器不同，六条判定扛不住）。它留下的这半句恰好是最有价值的部分：Apple 在错误里
直接写出了解法 —— **要么用 Xcode，要么自己调 `compileModel(at:)`**。`domain` 是
`com.apple.CoreML`、`code` 是 0，说明这是框架自己的判断，不是文件读不到（那种会是
`NSPOSIXErrorDomain` 或 `NSCocoaErrorDomain`）。

## §4 第二条入口：`MLModelAsset(specification: Data)`

书本 15.2.1 那张图（图 15-8）画的是「模型文件 → Xcode → App」。本机连「模型文件」这一环
都可以省：iOS 16 起可以**直接把规格字节交给 asset**，连临时文件都不写。

```swift
let asset = try MLModelAsset(specification: Data(tiny))
let m = try await MLModel.load(asset: asset, configuration: MLModelConfiguration())
```

```
== §4 MLModelAsset(specification: Data)：规格字节直接在内存里变成模型 ==
  ok   内存里的一段字节就造出了 asset，并且异步 load 成功：输入=["x"]
  ok   同一段 46 字节走第二条入口，预测照样是 21.0
```

两条入口的差别值得记：`load(asset:)` **只有 async 版**（同步的 `MLModel(contentsOf:)` 那条
对应的是 `.mlmodelc` 目录）；而 `MLModelAsset` 吃的是**规格字节**，所以 §3 那条「只吃编译产物」
的限制在这条路上不存在。书本那句「载入了模型」在本机有两套写法，一套要落盘、一套不用，
`y` 都是 21.0。

## §5 书本的「Model Class」：46 字节进去，293 行 Swift 出来

**书本**（15.2.2 步骤2）：「在项目导航中单击该文件以后，在编辑窗口中我们就可以看到Xcode已经
为该模型创建了一个Model Class……单击Model Class中Inceptionv3右侧的箭头，就可以看到类的相关代码。」

那个类不是魔法，它就是一条公开命令的产物：

```bash
xcrun coremlcompiler generate --language Swift tiny_scaler.mlmodel 输出目录
```

产物原样躺在本目录里（`tiny_scaler.swift`，一行没改），里面有三个类（探针 a01 把 grep 原文
抄了一遍）：`tiny_scalerInput : MLFeatureProvider`（`var x: Double`）、
`tiny_scalerOutput : MLFeatureProvider`（`var y: Double { get }` 从内部 provider 读）、
`tiny_scaler`（`let model: MLModel` + 一堆 init/load + `prediction(input:)` +
`predictions(inputs:)`）。也就是说书本说的「转换成一个类」，转的是**§1 那 46 个字节的输入输出表**：
类里每个属性名都是描述里那两个字，一个字都不多。

```
== §5 Model Class：同一条规格生成的 tiny_scaler.swift 现在被真的用起来 ==
  这份规格的输入字节数：46（生成物的字节数见探针 a01，它是主机上的编译期事实）
  ok   生成类的输入表里只有 ["x"] —— 属性名就是 §1 描述里那个字
  ok   生成类内部那个 `let model: MLModel` 运行时给的是 MLDelegateModel —— 声明是 MLModel，实际是它的私有子类；语法糖下面还是 §4 那台引擎
  offset scale   x      y        期望的 (x+offset)*scale
  ok   offset=0.0 scale=1.0 x=0.5 -> y=0.5  与 0.5 相等
  ok   offset=10.0 scale=1.0 x=0.5 -> y=10.5  与 10.5 相等
  ok   offset=0.0 scale=2.0 x=0.5 -> y=1.0  与 1.0 相等
  ok   offset=10.0 scale=2.0 x=0.5 -> y=21.0  与 21.0 相等
  ok   书本那句「使用模型去做断言」在代码里就是这么一行：scaler.prediction(x: 0.5).y = 21.0
```

那四行对照是**反推公式**：把规格里两个 double 换成四组组合，逐组编一份模型跑一次断言，
得到 `y = (x + offset) × scale`。这一格的用处不只是「scaler 是什么」，而是本章的方法论：
**没有 `.proto`、没有文档、没有网络，参数含义照样能读出来 —— 用输入输出实验把它夹出来。**
这正是 15.1.1 那句「没有明确编程」的反面操作：我们不看它的代码，只看它的行为。

`MLDelegateModel` 那行是第 27 章（Objective-C 运行时）的回声：生成的类里声明的是 `MLModel`，
运行时真正装进去的是它的私有子类。**语法糖下面还是那台引擎**，Model Class 没有任何
运行时特权，它只是把 `MLDictionaryFeatureProvider` 的拼装活儿写成了 Swift 属性。

## §6 批量断言：一次喂进去好几条「训练样本」

书本一次只拍一张照片，所以它只需要一个 `prediction`。但 API 里一直有批量的那一半
（`MLModel` 上的批量入口，类里就是生成的 `predictions(inputs:)`）。「一堆样本」正是
15.1.2 说监督式学习时的那个东西：一次给很多带标签的样本。

```
== §6 predictions(inputs:)：三行输入一次跑完 ==
  ok   三条输入 -> 3 条输出
  ok   批量结果 = [20.0, 21.0, 40.0]（还是同一个 (x+10)*2）
  ok   批量提供器自己数出 3 条 —— 它就是那批「样本」的容器
```

`MLArrayBatchProvider(array:)` 是那个容器（这个 SDK 里它的前身叫 `featureProviderArray:`，
主线用的新名字）。注意批量结果的形状：**输出条数 = 输入条数**，一条不多一条不少；
所谓「模型见过这堆样本」在 API 层就是这一串数组，「见过」本身仍然只在训练机上。

## §7 不要 Model Class 也能跑：`modelDescription`

15.2.1 那句「包含了所有的输入输出」到底能不能在运行时兑现？把生成物扔掉，只用一个裸
`MLModel` 试：

```
== §7 modelDescription：输入输出表在运行时读回来 ==
  ok   输入名读回来是 ["x"]
  ok   输出名读回来是 ["y"]
  ok   predictedFeatureName=y —— §1 那个 f11 就是它
  ok   x 的类型 2 就是 FeatureType 的 oneof 成员号
  ok   x 不是可选特征（规格里没写可选标记），所以少喂一个就报错 —— 见 §17
  ok   name 读回来就是 x —— MLFeatureDescription 上只有 name/type/可选标记和三个约束，没有别处可藏信息
  ok   三个约束全是 nil：一个 double 特征不需要任何约束对象
类型号对照（MLFeatureType）：0 invalid / 1 int64 / 2 double / 3 string / 4 image / 5 multiArray / 6 dictionary / 7 sequence / 8 state
```

三件值得记的事：

1. **`type.rawValue` 就是 §1 那个 oneof 成员号**（2 = double）。字节层的号和 API 层的枚举
   在这里对上了，这是「文件里写了什么，运行时就能读出什么」最干净的一条证据；
2. `MLFeatureDescription` 上**没有** `shortDescription` 之外的藏身处：`name` / `type` /
   可选标记 / 三个约束。规格里那个字段 2（shortDescription）本章没写，也就读不到；
3. 「类型号对照」那一行是**运行时读的枚举 rawValue**，不是抄文档 —— 所以 sequence(7) 与
   state(8) 这两个 15.2 时代没有的新成员也一起露出来了（它们是 15.1.4 那种「带状态的序列」
   在 Core ML 里的现代形状，书本成书时还不存在）。

## §8 张量：形状和元素类型也写在文件里

`MultiArrayFeatureType{1 **打包的** shape, 2 dataType}`。这里给一个长度 6 的 float32 数组，
模型参数还是那个 scaler —— 所以它把六个元素各自过一遍 15.1.2 那条临界线。

```
== §8 多维数组特征：shape 与 dataType 是读出来的，不是代码里规定的 ==
  ok   shape 读回来 [6]
  ok   dataType rawValue 65568 == float32（MLMultiArrayDataType 那一套号）
  ok   约束对象自己的描述是「Float32, 6」—— 类型在前，形状在后
  ok   输出形状 [6]
  输入 = 0, 1/7, 2/7, …, 5/7（float32）
  ok   第一个元素 20.0 —— 加 10 再乘 2
  ok   六个元素：[20.0, 20.28571429848671, 20.57142859697342, 20.857142865657806, 21.14285719394684, 21.428571462631226]
  后五个的小数尾巴（20.28571429848671 而不是 20.285714285714285）就是 float32 的精度痕迹：
  2/7 这种数在 float32 里存不精确，被读成 double 之后尾巴就露出来了。
```

这一节有本章最容易读错的一格。**「20.28571429848671」不是模型的输出**，而是
「模型输出 float32，主线用 `doubleValue` 读」。`MLMultiArray` 的元素是 NSNumber，
`doubleValue` 那次加宽把 float32 的精度痕迹放大成了可见的尾巴。结论有两条：

- 断言只敢卡在**第一个元素**（20.0 在 float32 里精确）；
- 真模型的分数同理 —— §14 那些 `0.7953935062846612` 是全精度的，因为那份模型的输出字典
  键值是 double。设备端读到的「相似度」精度取决于模型声明的 dtype，不取决于 Swift 侧
  你以为的类型。

顺带一条边界（探针 r02）：scaler 这种逐元素的参数**只接受一维数组**。二维的那一份连
`compileModel` 都过不去：

```
-- shape = [2, 3]（2 维）
  compileModel 就失败：domain=com.apple.CoreML code=3 compiler error: Error reading protobuf spec. validator error: Only 1 dimensional arrays input features are supported by the scaler.
```

**「规格能不能被收下」这一关是在编译期判的，不是等到预测时才判** —— 这条对 §17 那批
运行时宽容是个重要补充：校验器管结构，输入检查管值。

## §9 手写一层神经网络：`LayerParams` 的字段号 130 是 activation

神经网络在规格里是一个**层的列表**：`NeuralNetwork{1 重复的 LayerParams}`，而
`LayerParams{1 name, 2 input, 3 output, <oneof 层类型>}`。层类型的号同样是读出来的：
100 convolution、120 pool、130 activation、160 normalize、210 upsample、230/245 elementwise；
`activation` 里面又是一个 oneof，成员 10 = RELU（空消息）。

```swift
let nnSpec = modelSpec(inputs: [("image", ftImage(2, 2))], outputs: [("out1", ftImage(2, 2))],
                       predicted: nil, paramsField: 500,
                       params: layerParams("act0", "image", "out1", 130, PB.msg(10, Bytes())))
```

```
== §9  NeuralNetwork：LayerParams 的字段号 130 是 activation ==
  ok   一层 RELU 的完整模型 70 个字节
  字段树里和「层」有关的那几行：
        f1 str "image"
        f1 str "out1"
    f500 msg len=26
        f1 str "act0"
        f2 str "image"
        f3 str "out1"
  ok   图像约束读回来 2x2
  ok   色空间规格里写的是 20（RGB 一族），运行时读回来是 FourCharCode 1111970369 == "BGRA"
  ok   尺寸约束类型 rawValue=2（0 任意 / 2 枚举 / 3 范围）
  ok   枚举尺寸 1 个
  pixelsWideRange 是 NSRange：location=2 length=1 —— 枚举型约束下面这个范围没用，别拿它当尺寸读。
```

一层完整的神经网络 = **70 个字节**。这个数字的用处是把「神经网络」这个词从神秘感里拉出来：
它就是一个层的数组，每层三个名字加一个类型成员号。书本 15.2.1 说 Inception v3
「能够通过大量的图片训练出来……检测出一千种物体」，那是**层多、权重大**；格式的骨架与这
70 字节完全相同（g01 里那份 26 881 字节的真模型也是同一棵树）。

三个读回来的细节都带一条「别按字面猜」：

- 色空间：规格里 `colorspace = 20`（RGB 一族），运行时读回来是 FourCharCode
  `1111970369` = `'BGRA'`。**规格里的枚举和 API 里的像素格式不是同一套号**，
  中间那次换算由编译期做掉；
- `sizeConstraint.type = 2` = 枚举（enumerated），`enumeratedImageSizes` 1 个；
- `pixelsWideRange` 是 `NSRange`，`location=2 length=1` —— 在枚举型约束下面这个范围是
  填充值，**别拿它当尺寸读**（读尺寸就读 `enumeratedImageSizes`）。

## §10 结构自省：只有编译产物有这一层

iOS 17.4 起有一个内部暴露的 `__MLModelStructure`，能把层的名字和类型读回来 —— 也就是说
§9 那棵树在**编译之后**还有一份可读的形式。

```
== §10 MLModelStructure：把层的名字、类型、进出张量读回来 ==
  ok   读到 1 层：name=act0 type=activation in=["image"] out=["out1"]
  ok   层类型读回来是字符串 "activation"，不是枚举 —— 所以规格里那个 130 只能来自真模型
  ok   没有报错
```

`type` 是**字符串**（"activation"）而不是枚举 —— 这条恰好印证 §1 那句「语义不免费」：
字节里的 130 要有人翻译成名字，翻译表在编译产物里，不在 `.mlmodel` 里。

这一层只吃 `.mlmodelc`。喂 `.mlmodel` 源文件不会抛错，而是**当场 abort（signal 6）**；
而且那个异常是**异步到达**的 —— 调用会先返回。主线因此不试，探针 r01 专门量它，
原文（带本机容器路径）抄在探针记录里。这是本章最贵的一条边界：**Swift 的 `try/catch`
接不住 C++ 异常，而「接不住」不能靠调用点后面一句 print 来验证**（探针第一版就是这么
被骗过去的：不等回调时退出码 0、stderr 全空）。

## §11 Vision：一张自己画的图，走书本 15.2.3 那条通路

**书本**（15.2.3 步骤1）：「我们需要将从照片获取器得到的UIImage对象转换为CIImage对象，
因为它是标准的Core Image图像，而且在使用Vision和Core-ML框架中的方法时，必须要用这种特定类型。」

原书这里从 `UIImagePickerController` 拿一张照片；模拟器没有摄像头（§15），所以输入图像改用
第 29 章那套 Quartz 2D 直接画：四个色块，240 pt，scale 3。关键还是那句「必须要用 CIImage」，
于是画完先转 CIImage 再交给 handler —— 书本那五行代码一行没改：

```swift
let vnModel = try VNCoreMLModel(for: nn)          // 书本：Inceptionv3().model
let request = VNCoreMLRequest(model: vnModel)
let handler = VNImageRequestHandler(ciImage: ciImage!, options: [:])
try handler.perform([request])
let observations = request.results ?? []
```

```
== §11 Vision：一张自己画的图，走书本 15.2.3 那条通路 ==
  ok   UIImage -> CIImage 这一步和原书一样：guard let ciimage = CIImage(image: …)
  ok   点尺寸 (240.0, 240.0) × scale 3.0 = 像素 720x720 —— 模型说的是像素，不是点
  ok   书本那个 request.results 有 1 条
  ok   它的实际类型是 VNPixelBufferObservation，不是 VNClassificationObservation
  ok   输出缓冲 2x2 —— 模型的输出图像多大，观察结果就多大
  ok   像素格式 BGRA
  ok   数据 128 个字节 = bytesPerRow 64 × 高 2 —— 行是按 16 字节对齐铺的，不是 2×4
  ok   confidence=1.0：图像观察结果没有「把握」这回事，它永远是 1
  整块缓冲的字节和 = 3074（四个色块被缩到 2x2 之后的像素值全都落在这里，可复现，所以敢断言）
```

三条书本看不到、本节能量到的东西：

1. **点 vs 像素**。`UIGraphicsImageRenderer(size: 240×240)` 是点，scale 3 之后 `CIImage.extent`
   是 720×720 像素。模型约束说的是**像素**（§9 那 2×2），所以「拍张照扔进去」这句话里
   藏着一次缩放；书本从没提它，因为 Inception v3 自己会 resize。
2. **`bytesPerRow ≠ width × 4`**。2×2 的 BGRA 图像「应该是」16 个字节，实测一行 64 字节、
   整块 128 字节。读 `CVPixelBufferGetBaseAddress` 时按 `bytesPerRow` 走步，这是第 29 章
   量过的那条规则在视频域的回声。
3. **`confidence` 永远是 1.0**。书本 15.2.3 那句「相似度最高的名称」里的「相似度」，
   在这个观察结果类型上**不存在** —— 图像观察结果（`VNPixelBufferObservation`）没有把握
   这回事。把握只属于分类观察结果，那是 §12 的事。

## §12 原书那句 `as? [VNClassificationObservation]` 的 guard 到底在挡什么

**书本**（15.2.3 步骤2）：

```swift
guard let results = request.results as? [VNClassificationObservation] else {
    fatalError("模型处理图像失败")
}
```

书本从没让它进过 else 分支（它用的是真分类器，图 15-15 那串输出就是 then 分支的产物）。
而本节的 §9 手写的模型不是分类器 —— 于是 else 分支第一次**真的被走到**，而且有**两种**走法：

```
== §12 原书那句 `as? [VNClassificationObservation]` 的 guard 到底在挡什么 ==
  ok   (a) 书本那个 `request.results as? [VNClassificationObservation]` 在这里给 nil —— 它的 fatalError 就是从这一步来的
  ok   (b) 分类请求被拒：domain=NSOSStatusErrorDomain code=-1
     原文：Failed to create espresso context.
  ok   同一条通路、同一张图，换个模型类型就换个观察结果类型 —— 「图像识别」四个字在 API 里其实是两件不同的事
```

- **(a) 类型不对**：结果实际是 `VNPixelBufferObservation`，`as?` 直接给 nil。
  书本那句 fatalError 的文案「模型处理图像失败」在这种情形下是**误导**的 ——
  模型处理得好好的，只是它给的不是你以为的那个类型；
- **(b) 请求不对**：换成 Vision 自己的 `VNClassifyImageRequest()`，它要求模型带分类头，
  于是**执行请求的那一刻**就失败：`domain=NSOSStatusErrorDomain code=-1`，原文
  `Failed to create espresso context.`（espresso 是 Core ML 内部那个图执行引擎的名字，
  这句原话等于告诉你：引擎按分类器建上下文，建不出来）。

这是本章最锋利的一条：**原书那三行「图像识别」的代码里，「识别」这个词同时指两件不同的事**
—— 「模型输出什么类型的观察结果」由**模型**决定，「你发哪种请求」由**你**决定，
两边不一致时，一边给 nil、一边直接摔错误。书本用真分类器把这两件事糊成了一个。

## §13 只读复用一份真模型：26 881 个字节的决策树分类器

**书本**（15.2.1）：「通过浏览器可以访问 https://developer.apple.com/machine-learning/ 网址……
网页中最有趣的部分是模型的下载，这里面提供了已经训练好的『即插即用』的模型。」

本机不联网，但**模拟器那份 sysroot 里就躺着一批训练好的 `.mlmodel`**，PowerUI 那份是电池行为
模型，只有 26 KB，所以敢在示例里真跑（只读，不复制、不改动）。这条证明的不是「苹果有模型」，
而是书本那句「载入一个预先训练好的模型」的本来形状：**载入 = 读一段字节；训练好的东西全在
字节里，App 代码一行都不带。**

```
== §13 只读复用一份真模型：26 881 个字节的决策树分类器 ==
  ok   系统分区里那份模型在场，扩展名照样是 .mlmodel
  ok   它 26881 个字节 —— 比 §1 的 46 字节大五百多倍，但结构一模一样（探针 g01 能把它读成同一棵树）
  ok   五个输入特征：["battery_duration_1", "battery_duration_2", "battery_duration_3", "battery_duration_4", "plugin_battery_level"]
  ok   predictedFeatureName=next_discharge_is_shallow —— 书本说文件「包含了所有的输入输出」，就是这些名字
  ok     battery_duration_1 是 double
  ok     battery_duration_2 是 double
  ok     battery_duration_3 是 double
  ok     battery_duration_4 是 double
  ok     plugin_battery_level 是 double
  元数据（模型文件自带的说明书，运行时从描述里读）：
    MLModelAuthorKey = 
    MLModelCreatorDefinedKey = coremltoolsVersion=3.3, model_version=hvrfemuutc
    MLModelDescriptionKey = Shallow model
    MLModelLicenseKey = 
    MLModelVersionStringKey = 
  ok   描述键在场
  ok   作者给它写的说明读回来是「Shallow model」
  ok   MLModelAuthorKey / MLModelLicenseKey 读回来是空串（"" /""）：苹果自己的模型也没填这两栏
  ok   predictedProbabilitiesName=classProbability —— 书本那个「相似度最高的第一名」，规格里专门留了一个字段说概率表在哪
  ok   classLabels 有 2 项：["0", "1"] —— 类别名确实写进了文件里
  ok   两项不一样，所以「第 0 类」「第 1 类」各有自己的名字：["0", "1"]
  ok   isUpdatable=false —— 设备端只做推断；书本 15.1 那套「不断的训练」不在 Core ML 的运行时代码里
```

这一节是 15.1 那四节概念的**总兑现处**，一条一条对：

- **特征**：那五个名字就是 15.1.2 说的「特性」。苹果选的量是「电池当前电量 + 四段放电时长」，
  一条业务假设写成了五个 double；
- **标签表**：`classLabels` 有 2 项，值是 `"0"` 与 `"1"` —— 这位作者没给类别起名字
  （对比书本那个模型的 `hotdog` / `nohotdog`）。标签表**确实跟着文件走**，
  这就是「监督式」三个字留下的化石；
- **概率表的位置**：`predictedProbabilitiesName=classProbability` —— 规格里专门有一个字段
  （ModelDescription 的字段 12，g01 里看得见 `f12 str "classProbability"`）说概率字典叫什么。
  书本 15.2.4 那句「第一个元素是相似度最高的」之所以能成立，靠的就是这一头；
- **训练**：`isUpdatable=false`。这份模型是 15.2.1 说的那个「静态模型」，字面意义；
- **元数据**：五行里三行是空的（`MLModelAuthorKey`、`MLModelLicenseKey`、
  `MLModelVersionStringKey`），`MLModelCreatorDefinedKey` 里那两个 KV
  （`coremltoolsVersion=3.3`、`model_version=hvrfemuutc`）是**训练侧**唯一漏到设备端的痕迹 ——
  coremltools 就是那套「在另一台机器上把这两个 double / 这棵树算出来」的工具，
  它留在文件里的版本号，正是 15.1.2 那句「不断地训练」的落款。

还有一个隐身的种类：`g01` 把这份模型读成 `f402 msg len=26559`，里面是一整排
`f1 msg` 的树节点（每个节点两个 varint 加两个 double —— 哪个特征、阈值多少、左右子树）。
所以「决策树分类器」在本机的形状是：**一个 26 KB 的参数块，里面没有任何控制流代码**，
判断全在数据里。这正是 15.1.1 那句「没有明确编程」在字节层的最终形态。

## §14 「相似度最高的第一名」：热狗判决在本机的形状

15.2.4 的全部逻辑就两句：取 `results.first`，看它的 `identifier` 里有没有 `"hotdog"`。
书本看不到那个数组是怎么排出来的；一份真分类器的概率字典把它摊开了。

```
== §14 概率字典与第一名 ==
  ok   classProbability 是字典特征
  ok   它的键类型读回来是 int64（rawValue 1）
  ok   类别键是 [0, 1] —— 两类的分类器
  ok   概率求和 1.0 == 1：所谓「相似度」是归一化过的，不是原始得分
  ok   字典里的第一名 0 与 next_discharge_is_shallow=0 是同一个 —— 书本那个 results.first 就是它
  第一名 0 的概率 0.7953935062846612，第二名 1 的概率 0.20460649371533882
  查 §13 那张表：第 0 类在这里写作「0」
  ok   换一组输入，概率照样加成 1
  换输入之后：第一名=0 标签=0 各项=["0: 0.9462305918901958", "1: 0.05376940810980427"]
  ok   样本判决「不是浅放电」—— 换到书本的比喻就是一句「不是热狗！」
```

四条：

1. 「相似度」= 归一化概率（`和 == 1.0`，实测两组输入都成立）。15.1.4 那个「赢的可能性」
   在 API 里就必须长成这个样子；
2. **第一名与标签是同一个东西**：`argmax(prob) == 0 == next_discharge_is_shallow`。
   书本那个 `results.first` 就是这条等式的运行时形状 —— 排序不是 Vision 的恩赐，
   是模型自己先算完的；
3. **键是整数，名字要查表**：`classProbability` 的键类型是 int64，而 §13 那张 `classLabels`
   里存的是字符串 `"0"` / `"1"`。书本能直接写 `identifier.contains("hotdog")`，是因为它的
   模型把 `classLabel` 那一头声明成了字符串特征。换到这份模型上，「热狗」这个词
   在文件里根本不存在，判决只能是「第 0 类」；
4. 判决的**方向**随输入变：把电量压到 5、四段时长拉到 9，第一名仍是 0，但概率从
   `0.20460649371533882` 涨到 `0.05376940810980427` —— 这就是 15.1.2 那条「临界线」的
   活体版：线没动，点在动。

## §15 摄像头那半条路：原书为什么要「必须运行在真机上」

**书本**（15.2.2 步骤6~7 与其后的崩溃记录）：`imagePicker.sourceType = .camera`、
`present(imagePicker, …)`，然后「因为在项目中使用了摄像头，所以需要运行在真机上面。
但是在构建并运行项目的时候，应用程序会发生崩溃，从控制台可以看出是这因为
reason：'Source type 1 not available'。因为我们所运行的项目试图访问一个敏感数据
而没有使用描述。」接着步骤3 补 `Privacy - Camera Usage Description`，并给了一条
「技巧」：「如果将imagePicker的sourceType属性修改为.photoLibrary，则可以在模拟器中打开
该项目，然后通过照片库来载入图像。」

本章没有窗口，所以这里量的是**能力**，不是 UI：

```
== §15 UIImagePickerController 那半条路：原书为什么要「必须运行在真机上」 ==
  ok   sourceType = .camera 在模拟器里不可用（false）—— 那句 'Source type 1 not available' 就是它的崩溃现场
  ok   照片库/已存相册可用（true/true）—— 原书那条「技巧：把 sourceType 改成 .photoLibrary 就能在模拟器里跑」是真的
  ok   AVCaptureDevice.default(for: .video) 是 nil
  ok   枚举出来的视频设备 0 台
  ok   授权状态 rawValue=2 == .denied（枚举顺序：0 未决定 / 1 受限 / 2 拒绝 / 3 已授权）—— 模拟器里相机是「被拒绝」的，不是「已授权」
```

三条读法：

1. 书本那句崩溃 `'Source type 1 not available'` 里 **1 就是 `.camera`** 的 rawValue，
   而它之所以 available=false，是因为压根没有设备（DiscoverySession 枚举出 0 台，
   `AVCaptureDevice.default(for: .video)` 是 nil）。也就是说那条「技巧」不是绕开权限，
   是**换了一个本来就存在的数据源**；
2. `authorizationStatus(for: .video)` 在模拟器里是 **`.denied`（rawValue 2）**。这个枚举的
   顺序很容易记错（0 未决定 / 1 受限 / **2 拒绝** / 3 已授权），本章特意把 rawValue 打出来
   对着断言。书本靠 Info.plist 里那行描述换来的弹窗，在模拟器里根本不会出现 ——
   没有摄像头可授权，系统直接给「拒绝」；
3. 第 19 章（权限与通知）讲过 `NSCameraUsageDescription` 缺失时的崩溃；本节把它接到底层：
   **权限决定「允不允许」，能力决定「有没有」，两回事**。

## §16 计算设备：GPU/CPU 在场，神经引擎缺席

书本 15.2 全程没提硬件（2017 年 A11 的 ANE 才刚发布）。这一节量的是那句
「一旦用户下载并使用了你的应用程序，它就能使用模型去做断言」里的「使用」发生在**哪块芯片**上。

```
== §16 computeUnits 与 availableComputeDevices：ANE 在模拟器里不存在 ==
  ok   本机可用计算设备 2 个
  ok   设备标签读回来 ["cpu", "gpu"]
  ok   里面没有任何「神经引擎」标签 —— 书本反复强调的那块专用电路（Apple Neural Engine）在模拟器里不存在
  cpuOnly[0: 0.7953935062846612, 1: 0.20460649371533882]  cpuAndGPU[…] 同一串  all[…] 同一串  cpuAndNeuralEngine[…] 同一串
  ok   4 种 computeUnits 出来的概率字典完全一致 —— 选哪块芯片是性能问题，不是结果问题
```

（那一行四个字典的键完全相同，主线把它们并排打印出来；这里为了排版折叠了后三段。）

两条：

- `MLModel.availableComputeDevices`（iOS 17 起）在本机给 2 个设备，Swift 侧的标签读回来是
  `["cpu", "gpu"]`。为什么用 `Mirror` 读标签而不是 `is MLGPUComputeDevice`：Swift 把两种设备
  都装进同一个 `MLComputeDevice`，那个 cast 会被编译器警告「永远失败」，而它的 `description`
  里带指针地址 —— 那是每台机器每轮都不同的东西，六条判定扛不住；
- **四种 `computeUnits` 的输出逐字节一致**。这条不只是一句「性能与结果无关」，
  它是本章**方法论**的落点：run-all.sh 要比对 debug(-Onone) 与 release(-O) 两份 stdout，
  靠的就是「模型的输出既不依赖优化配置、也不依赖跑在哪块芯片上」。§19 那条判据把这句话
  正式钉死。

## §17 喂进去的东西：多余的被忽略，窄化的被接受，类型跨不过去

书本从没让它失败（它一次只喂一张照片）。这一节故意喂错四次，量 Core ML 的**宽容度**在哪：

```
== §17 喂进去的东西：多余的被忽略，窄化的被接受，类型跨不过去 ==
  ok   多喂一个描述里没有的特征 zzz：**没报错**，被静默忽略 —— 拼错特征名不会有任何提示
  ok   int64 喂给 double 特征：被接受并自动加宽，17 × 2 = 34.0
  ok   跨到图像这一族就拦住了：The model expects input feature image to be an image, but the input (Double : 1) is of type Image.
  userInfo 的键 = ["NSLocalizedDescription"]
  ok   缺特征报的是「Feature 'battery_duration_1' not provided.」—— domain=com.apple.CoreML code=0，它只点名五个缺失特征里的第一个
```

- **拼错特征名不会有任何提示**：多喂一个描述里没有的 `zzz`，`MLDictionaryFeatureProvider`
  照常构造、预测照常返回。这是本章最实用的一条 ——「模型跑通了」不等于「喂对了」；
- **加宽被接受**：`MLFeatureValue(int64: 7)` 喂给 double 特征，拿到 34.0（(7+10)×2）；
- **跨类型族被拦住**：double 喂给图像特征会抛 `com.apple.CoreML` code 1，原文里那句
  `but the input (Double : 1) is of type Image.` 把自己也念进去了（注意它念的方向：
  「期望 image 是图像，而输入是 Image 类型的 Double」，读时要绕一下）；
- **缺特征只点名第一个**：五个特征只喂一个，错误是 `Feature 'battery_duration_1' not provided.`，
  而不是五连报。而且这句在 `localizedDescription` 里 —— 这一族 NSError 的 userInfo
  **只有** `NSLocalizedDescription` 一个键，没有 AppKit 习惯里那个 `NSLocalizedFailureReason`
  （主线把 userInfo 的键表打印出来了，就是为了这一格：第一版照着习惯去读那个键，读到空串）。

## §18 手写不出来 / 跑不起来的东西：把墙的位置钉死

三堵墙，每堵都有原文。

**墙一：这不是「任何文本文件都能改一改」。** 递一份不是 protobuf 的字节进去：

```
  墙一 畸形 protobuf：Failed to parse the model specification. Error: Field number 14 has wireType 4, which is not supported.
  ok     → domain=com.apple.mlassetio code=1（是「读规格」这一步就失败了）
```

错误里连**字段号和线型**都报了 —— 它真的在按 protobuf 走，不是「认不出就拒绝」的黑箱。
（主机上 `coremlcompiler compile` 给的是同一句话，见探针 a01 最后一格：
`Field number 4 has wireType 3, which is not supported.` —— 同一个解析器，两份文件。）

**墙二：书本要的「图像分类器」在本机手写不出来。** 三段原文来自同一份「一层 RELU +
一个输出」的规格，只换输出类型：

```
  墙二 输出=「图像」：compiler error: Error reading protobuf spec. validator error: Unsupported type "MLFeatureTypeType_imageType" for feature "o". Should be one of: MLFeatureTypeType_doubleType, MLFeatureTypeType_multiArrayType.
  墙二 输出=「字符串」：compiler error: Error reading protobuf spec. validator error: Unsupported type "MLFeatureTypeType_stringType" for feature "o". Should be one of: MLFeatureTypeType_doubleType, MLFeatureTypeType_multiArrayType.
  墙二 输出=「字典」：compiler error: Error reading protobuf spec. validator error: Unsupported type "MLFeatureTypeType_dictionaryType" for feature "o". Should be one of: MLFeatureTypeType_doubleType, MLFeatureTypeType_multiArrayType.
  ok     → 只有 multiArray 输出能过：字段号 303（neuralNetworkClassifier）编过了，但输出类型仍是数组，拿不到分类观察结果
```

校验器把**合法集合直接念出来了**：`double` 或 `multiArray`。而分类观察结果
（`VNClassificationObservation`）要的恰恰是 `string`（classLabel）+ `dictionary`
（classProbability）—— 那正是被拒的两项。所以：

> 用这份工具链手写不出一个能产出 `VNClassificationObservation` 的图像分类器。
> 书本 15.2.4 那句 `identifier.contains("hotdog")` 在本机没有对应的模型可造。

这就是本章为什么绕道 §13/§14：热狗判决从**苹果训练好的真分类器**的概率字典里读，
而不是从手写的字节里造。还有一条顺手量到的边界：把 `Model` 的参数字段号写成 303
（`neuralNetworkClassifier`）时，`multiArray` 输出**能编过**，但种类被念成 regressor ——
**「分类器」这个身份不是由那个号单独决定的，而是由「参数种类 + 输出特征形状」共同决定的**。

顺带一条自己的墙（值得记，因为它是工具用法而非框架限制）：§18 第一版把 303 那份的层
输出名写成 `"o"`，而描述里声明的输出叫 `"classProbability"`，于是连 multiArray 那份也编不过，
原话只有一句 `Error in declaring output classProbability with error -1.` ——
**层的 `output` 必须等于声明的输出特征名**，校验器不会替你改名。

**墙三：那条「拖进来就有一个类」的命令只认磁盘上一份已存在的 `.mlmodel`，而且是主机程序。**
命令形式还是位置参数，语言名要写全称；`--output-path`、`--language swift` 这类写法当场被拒
（原话见探针 a01）。这条不是 Core ML 的墙，是本机工具链的墙，它划出了本章为什么把生成物
**提交进仓库**（§5）而不是在示例里现跑一条命令 —— 示例是在**模拟器里**跑的，
而 `coremlcompiler` 是 macOS 上的主机程序。

```
  ok     → 墙三记在探针 a01/r01：coremlcompiler 的命令行原话、以及结构自省喂 .mlmodel 会让进程当场 abort（signal 6）
```

## §19 本章唯一一条「模型接上了」的判据

书本这一章的成功判据是「屏上导航栏写出热狗/不是热狗」。本仓库没有屏，所以判据换成同一条
因果链上能被卡住的那一环：一段我自己写出来的字节、一个我自己生成出来的类、和一份苹果训练好
的模型，三者各自跑通，而且输出不依赖优化配置、也不依赖跑在哪块芯片上。

```
== §19 本章唯一一条「模型接上了」的判据 ==
  ok   手写的 46 字节：单条与批量断言都对
  ok   张量与神经网络：形状/层数都按规格里写的那个数
  ok   真分类器：第一名与概率和都对
  ok   Vision 通路在，摄像头不在 —— 这就是本章能走到书本 15.2.3 的哪一步
```

四条各自回收前面哪几节：

1. **§1 + §2 + §4 + §5 + §6**：字节 → 编译 → 载入 → 生成类 → 单条与批量断言，
   全链路没有一行来自下载；
2. **§8 + §9 + §10**：张量的形状、神经网络那一层、以及编译产物里那份结构自省，
   全都和规格里写的那个数一致；
3. **§13 + §14**：别人的模型、别人的特征名、别人的标签表，判决与概率读得通，
   `argmax == predictedFeatureName`；
4. **§11 + §12 + §15**：Vision 那条通路是通的（画出来的图进得去、观察结果出得来），
   摄像头那半条在模拟器里不存在 —— 所以本章走到 15.2.3 的**第三步**（`handler.perform`）
   为止，最后一步「导航栏写字」按本仓库的规矩换成一条断言。

---

## 本章开头那些换法，现在的账目

| 换法 | 兑现处 | 一句话结果 |
| --- | --- | --- |
| 模型从网上下载 → 字节手写 | §1 + 探针 g01 | 46 字节；hex 与树都打出来了，oneof 成员是**空消息** |
| Xcode 替你生成 Model Class → 提交生成物 | §5 + 探针 a01 | 生成物 293 行 / 10 961 字节，与仓库里那份逐字节一致 |
| 载入模型 → 三条入口各量一次 | §2 / §3 / §4 | 编译产物只两样；裸 `.mlmodel` 被拒且原话给出解法；`MLModelAsset` 连临时文件都不写 |
| 「做一个断言」→ 单条 + 批量 | §5 / §6 | `y = 21.0`；批量三条进三条出 |
| Inception v3 → 系统里那份真模型 | §13 / §14 | 26 881 字节、`f402` 那一块是一整排树节点；概率加总 1.0 |
| `UIImage → CIImage → Vision` → 自己画的图 | §11 / §12 | 通路在；观察结果类型由**模型**决定，`confidence` 对图像输出恒为 1 |
| 拍照 + Info.plist → 三个布尔值 + 一次授权读数 | §15 | `.camera` false、照片库 true、授权 `.denied` |
| （书本没提的硬件层） | §16 | 2 个设备（cpu/gpu），ANE 缺席；四种 `computeUnits` 输出逐字节一致 |

## 症状 ↔ 本机量到的真因

| 症状 | 本机量到的真因 | 证据 |
| --- | --- | --- |
| 「`.mlmodel` 拖进项目，`MLModel(contentsOf:)` 报错了」 | 载入只吃编译产物 `.mlmodelc`；原话直接教你补 `compileModel(at:)` | §2、§3 |
| 「模型文件里明明写着类型，为什么读出来只知道号」 | oneof 类型成员是**空消息**，号→名字的表在 `.proto`/编译产物里 | §1、§10 |
| 「`request.results as? [VNClassificationObservation]` 一直是 nil」 | 模型不是分类器，它给的是 `VNPixelBufferObservation`；不是「处理失败」 | §11、§12(a) |
| 「换成 `VNClassifyImageRequest` 直接抛错」 | 执行请求那一刻建分类上下文失败：`Failed to create espresso context.` | §12(b) |
| 「导航栏写不出热狗」 | 手写的分类器过不了校验器（输出类型合法集合只有 double/multiArray）；`classLabel` 那一头需要字符串特征 | §18 墙二 |
| 「参数块换了个号，编不过了 / 种类变了」 | 种类由「参数种类 + 输出特征形状」共同决定；303 + multiArray 被念成 regressor | §18 墙二 |
| 「`identifier.contains("hotdog")` 在我的模型上不适用」 | 这份模型的键是 int64，类别名表里是 `"0"`/`"1"`；名字要按序号查 `classLabels` | §13、§14 |
| 「模型在模拟器里没报错，但结构自省拿不到东西」 | `__MLModelStructure` 只吃 `.mlmodelc`；喂 `.mlmodel` 会**异步** abort（signal 6） | §10 + 探针 r01 |
| 「多喂了一个特征，什么都没发生」 | 描述里没有的特征被静默忽略；拼错名字没有提示 | §17 |
| 「少了特征，错误信息里只有一个名字」 | `Feature '<第一个缺失>' not provided.`，只点名一个 | §17 |
| 「照着 AppKit 习惯读 `NSLocalizedFailureReason` 读到空串」 | 这一族 NSError 的 userInfo 只有 `NSLocalizedDescription` 一个键 | §17 |
| 「断言 `20.285714285714285` 却得到 `20.28571429848671`」 | 模型声明 float32，`doubleValue` 加宽时精度尾巴露出来 | §8 |
| 「2×2 的 BGRA 图像算出 16 字节，实测 128」 | 行按 `bytesPerRow`（64）对齐铺，不是 `width × 4` | §11 |
| 「`sourceType = .camera` 在模拟器里崩」 | 没有摄像头设备（枚举 0 台、`default(for:)` 是 nil），且授权状态直接是 `.denied` | §15 |
| 「`computeUnits = .cpuAndNeuralEngine` 是不是会换结果」 | 不会：四种配置的概率字典逐字节一致（但 ANE 在模拟器里根本不在设备表上） | §16 |
| 「`coremlcompiler generate` 报 missing destination path」 | 它是位置参数；`--output-path` 被忽略，`--language swift` 大小写不对 | 探针 a01 |
| 「生成物写不出来：unable to open output file」 | 目标目录**必须已存在**，coremlcompiler 不替你创建 | 探针 a01 |
| 「结构自省那支探针看起来没崩（退出码 0）」 | 崩溃是异步到达的；调用完就 exit 会漏掉它 | §10 + 探针 r01 |

## 探针记录（4 支，逐字抄自现跑输出）

三族分工见「复现」。下面每支抄的是 `probes/run.sh` 的完整输出（临时目录
`${TMPDIR}/iosdev34probes` 里的路径每次不同，抄录时把那一段缩成 `/var/folders/…/`；
其余逐字）。

### `a01_coremlcompiler_cli` —— `xcrun coremlcompiler` 的原话：compile 的产物、generate 的字节数、四条拒答（§2、§5、§18）

```
$ xcrun -f coremlcompiler
退出码 = 0   （找到可执行文件）
--- stdout ---
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlcompiler
--- stderr ---（空）

$ 由 hex 还原：<46 字节的 hex>
文件 /var/folders/…/iosdev34a01/tiny_scaler.mlmodel = 46 个字节

$ xcrun coremlcompiler compile …/tiny_scaler.mlmodel …/compiled
退出码 = 0   （把 .mlmodel 编成 .mlmodelc）
--- stdout ---
/var/folders/…/iosdev34a01/compiled/tiny_scaler.mlmodelc/coremldata.bin
--- 产物 ---
  ./tiny_scaler.mlmodelc
  ./tiny_scaler.mlmodelc/analytics
  ./tiny_scaler.mlmodelc/analytics/coremldata.bin
  ./tiny_scaler.mlmodelc/coremldata.bin
  ./tiny_scaler.mlmodelc/metadata.json
  各文件字节数：
       141 ./tiny_scaler.mlmodelc/analytics/coremldata.bin
       123 ./tiny_scaler.mlmodelc/coremldata.bin
       898 ./tiny_scaler.mlmodelc/metadata.json

$ xcrun coremlcompiler generate --language Swift …/tiny_scaler.mlmodel …/gen
退出码 = 0   （生成 Swift 模型类）
--- stdout ---
/var/folders/…/iosdev34a01/gen/tiny_scaler.swift
--- 生成物 ---
  路径 /var/folders/…/iosdev34a01/gen/tiny_scaler.swift
  字节数 10961
  行数 293
--- 生成物里的类与属性（grep 原文）---
  12:class tiny_scalerInput : MLFeatureProvider {
  15:    var x: Double
  35:class tiny_scalerOutput : MLFeatureProvider {
  41:    var y: Double {
  65:class tiny_scaler {
  66:    let model: MLModel
  209:    func prediction(input: tiny_scalerInput) throws -> tiny_scalerOutput {
  226:    func prediction(input: tiny_scalerInput, options: MLPredictionOptions) throws -> tiny_scalerOutput {
--- 与提交进仓库的那份（../tiny_scaler.swift）是否逐字节一致 ---
  一致 —— 仓库里那份就是这条命令的产物，一行没改
```

四条拒答的原文（§18 墙三）：

```
$ xcrun coremlcompiler
coremlcompiler: error: usage: coremlcompiler <command> <inputdocument> <outputpath> [options ...]

$ xcrun coremlcompiler generate --language swift …
coremlcompiler: error: unrecognized target language "swift".  Expected one of: Swift, Objective-C.
coremlcompiler: error: usage: coremlcompiler <command> <inputdocument> <outputpath> [options ...]

$ xcrun coremlcompiler generate --language Swift --output-path … <模型>
Warning: ignoring unrecognized command line argument --output-path /var/folders/…/refuse
coremlcompiler: error: generate command missing destination path

$ xcrun coremlcompiler compile <模型>            # 少了目标目录
coremlcompiler: error: compile command missing destination path
```

还有一格是本探针**跑出来才补上的**：第一版没 `mkdir` 目标目录，得到的是

```
coremlcompiler: error: unable to open output file: /var/folders/…/gen/tiny_scaler.swift
```

—— 目标目录必须先存在。另外最后那一格「喂一份不是 protobuf 的文件」（把 `run.sh` 自己
递进去）给的是 `Failed to parse the model specification. Error: Field number 4 has
wireType 3, which is not supported.`，与 §18 墙一那条（字段 14 / 线型 4）是同一句
模板、两份不同的文件 —— 这是「解析器真的在按 protobuf 走」的第二个证据。

### `g01_wire_tree_of_real_model` —— 把两份 `.mlmodel` 读成同一棵树（§1、§13、§18）

主线 §1 那份 46 字节的规格，从它自己的 hex 还原回来，和苹果那份真模型喂给**同一个**解码器：

```
46 字节的 hex 还原出来是 46 个字节：对得上
== 手写规格 scaler（字段号 604）（46 个字节）==
hex 前 96 字节: 080112150a070a01781a02120052070a01791a0212005a0179e22512090000000000002440110000000000000040
字段树（前 14 行）:
  f1 varint 1
  f2 msg len=21
    f1 msg len=7
      f1 str "x"
      f3 msg len=2
        f2 bytes len=0 
    f10 msg len=7
      f1 str "y"
      f3 msg len=2
        f2 bytes len=0 
    f11 str "y"
  f604 msg len=18
    f1 double 10.0 [0000000000002440]
    f2 double 2.0 [0000000000000040]
全文里露出来的 ASCII 串（前 2 个，按出现顺序）:
  "x", "y"
  共 2 个不同的串

== 苹果真模型 /System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/Resources/assets_251/shallow_model.mlmodel（26881 个字节）==
hex 前 96 字节: 080112b8020a1a0a14706c7567696e5f626174746572795f6c6576656c1a0212000a180a12626174746572795f6475726174696f6e5f311a0212000a180a12626174746572795f6475726174696f6e5f321a0212000a180a1262617474657279
字段树（前 120 行，已按预算截断）:
  f1 varint 1
  f2 msg len=312
    f1 msg len=26
      f1 str "plugin_battery_level"
      f3 msg len=2
        f2 bytes len=0 
    …（另外四个输入同样是 f1 msg / f1 str / f3 msg len=2 / f2 bytes len=0）
    f10 msg len=31
      f1 str "next_discharge_is_shallow"
      f3 msg len=2
        f1 bytes len=0 
    f10 msg len=24
      f1 str "classProbability"
      f3 msg len=4
        f6 msg len=2 0a00（到深度上限，不再深入）
    f11 str "next_discharge_is_shallow"
    f12 str "classProbability"
    f100 msg len=73
      f1 str "Shallow model"
      f100 msg len=25
        f1 str "coremltoolsVersion"
        f2 str "3.3"
      f100 msg len=27
        f1 str "model_version"
        f2 str "hvrfemuutc"
  f402 msg len=26559
    f1 msg len=29
      f3 varint 1
      f10 varint 1
      f11 double 0.03058207780122757 [00000080e8509f3f]
      f12 varint 1
      f13 varint 2
      f14 varint 1
      f30 double 209582.25 [0000000072950941]
    f1 msg len=31
      f2 varint 1
      f3 varint 1
      f10 varint 1
      f11 double 0.005383005365729332 [000000807d0c763f]
      …
全文里露出来的 ASCII 串（前 12 个，按出现顺序）:
  "plugin_battery_level", "battery_duration_1", "battery_duration_2", "battery_duration_3", "battery_duration_4", "next_discharge_is_shallow", "classProbability", "Shallow model", "coremltoolsVersion", "3.3", "model_version", "hvrfemuutc"
  共 12 个不同的串
```

这张树是本节所有字段号的出处，逐条对得上 §13 从运行时读回的东西：

- 两份文件**前三个字段一模一样**：`f1 varint 1`（规格版本）、`f2 msg`（描述）、
  然后各自挂一个参数块（`f604` scaler / `f402` 那份树）；
- 五个输入全是 `f1 msg / f1 str <名字> / f3 msg len=2 / f2 bytes len=0` ——
  **`f2` 那个空成员就是 double**，与 §1 手写的规格逐字节同形。这一下 §7 那个
  `x 的类型 2` 就不再是「读枚举」，而是「读同一份字节」；
- `next_discharge_is_shallow` 那一头是 `f1 bytes len=0` —— **`f1` = int64**，
  与 §14 实测的 `int64Value` 对上；
- `classProbability` 那一头是 `f6 msg len=2 / 0a00`：`f6` = dictionary，
  里面 `0a00` 是「字段 1、长度 0」那个**空的键消息** —— 键是 int64，与 §14 的
  `keyType 读回来是 int64（rawValue 1）` 对上；
- `f12` 是 `predictedProbabilitiesName`（§13 读到 `classProbability`）、`f100` 是 metadata
  （§13 那五行元数据、以及 `coremltoolsVersion=3.3` 就躺在这里）；
- `f402` 那 26 559 个字节是模型本体：一排排 `f1 msg` 的节点，每个里面两个 varint
  （哪个特征、什么方向）和两个 double（阈值、叶子的值）。**「训练出来的知识」在文件里
  就是这个形状：没有一行代码，只有数。**

### `r01_structure_on_mlmodel` —— 结构自省喂 `.mlmodel` 会 abort，而且崩溃是**异步到达**的（§10、§18 墙三）

```
$ <主线那套 swiftc 命令> -module-name core_ml -framework CoreML -framework Foundation main.swift -o r01_structure_on_mlmodel
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
写出 scaler.mlmodel：46 个字节。它是 .mlmodel **源文件**，不是 .mlmodelc 目录
规格版本字段 f1=1、输入 x / 输出 y 都是 double、模型参数是字段 604（scaler）
下面调用 __MLModelStructure.loadContents(of:) —— 它会立刻返回
   调用已经返回（说明异常不是在这儿摔的）。现在等回调 —— 等到的将是 abort
--- stderr ---
libc++abi: terminating due to uncaught exception of type std::__1::ios_base::failure: Failed to open file: /Users/xulun/Library/Developer/CoreSimulator/Devices/2C5E3D2C-…/data/tmp/ch34r01/scaler.mlmodel/coremldata.bin. It is not a valid .mlmodelc file. : unspecified iostream_category error
Child process terminated with signal 6: Abort trap
```

读这四件事：

1. **退出码 134 = 128 + 6**，`signal 6`（Abort trap）。`try/catch` 接不住：那是一抛在
   libc++ 层的 C++ 异常，不在 Swift 的 Error 体系里；
2. 它按 `.mlmodelc` 的目录结构去开 `coremldata.bin` —— 传进去的是**文件**，于是路径变成
   `scaler.mlmodel/coremldata.bin`（把一个文件当目录）。这句原文就是 §3 那条「载入只吃
   编译产物」的底层版本：不是策略，是**实现只会这一种**；
3. **崩溃是异步的**：stdout 停在「现在等回调」那行，说明调用已经返回、下一行 print 也打了，
   进程随后才没顶。探针第一版调用完就 exit，得到的是退出码 0、stderr 全空 ——
   所以「它没报错」这个结论在这类 API 上是**测不出来**的；
4. 那句 error 里带着本机的容器绝对路径，这正是它不能进主线的原因之一（主线只能断言
   「喂 .mlmodelc 时读到 1 层」，见 §10）。

### `r02_scaler_2d_input` —— scaler 对二维输入怎么说：校验期就拒，不在预测期（§8、§17）

```
-- shape = [6]（1 维）
  compileModel 过了（产物 s1_83639488-F835-47C1-9039-9AF5809ED6BF.mlmodelc）
  载入过了，约束读回来：Optional(Float32, 6)
  预测成功：输出形状 [6]，前两个元素 20.0、22.0
-- shape = [2, 3]（2 维）
  compileModel 就失败：domain=com.apple.CoreML code=3 compiler error: Error reading protobuf spec. validator error: Only 1 dimensional arrays input features are supported by the scaler.
```

对照主线 §8（一维的那份跑通，`Float32, 6`）：换成二维，同一套代码走不完第二步 —— 红在
**校验期**（`code=3`、那句 `Error reading protobuf spec. validator error:` 与 §18 墙二同一族），
而不是像 §17 那样等到 `prediction(from:)` 才报。所以「什么时候开始管你」这件事在本机有
两个明确的层次：

- 结构层（编译期）：模型种类允许的输入/输出形状、参数的维度 —— 原话带 `validator error:`；
- 值层（预测期）：名字对不对、类型跨不跨族、少没少喂 —— 原话带 `Feature '…' not provided.`。

## 本章能带走的东西

- **「模型文件」这四个字被量成了两件东西：规格（`.mlmodel`，protobuf）和编译产物
  （`.mlmodelc`，引擎计划）。** 46 字节进去、123 字节的 `coremldata.bin` 出来；
  §3、§10、探针 r01 三条墙全都只由这一条界线决定 —— 载入、结构自省只吃后者。
  Xcode 替你做的就是这一步，而它有公开的名字（`compileModel(at:)`、`coremlcompiler compile`）。
- **「完全的开放」要说得精确：格式开放，语义不免费。** oneof 的类型成员是**空消息**
  （`f2 bytes len=0`），光看字节分不清 double 还是 int64；号→名字的表在 `.proto` 里。
  但**名字本身躺在字节里**（`f1 str "x"`），所以 §7、§13 不靠任何 schema 就能把输入输出表
  读回来 —— 书本那句「包含了所有的输入输出」到这里才兑现。
- **Model Class 是语法糖，而且是可提交的语法糖。** 一条 `coremlcompiler generate` 生成 293 行；
  本章把它原样提交并真的调用它（§5），因为它内部的 `let model: MLModel` 运行时是
  `MLDelegateModel` —— 那个类没有任何运行时特权，把 §4 那台引擎的输入输出表写成了 Swift 属性。
  所以「没有 Xcode」不等于「不能像书本那样用一个类」。
- **没有 `.proto`、没有文档、没有网络，参数含义照样能读出来 —— 用输入输出实验把它夹出来。**
  §5 那四组 offset/scale 对照、§8 那条「float32 精度尾巴」、§14 那句「概率加总为 1」，
  全都是夹出来的。这一条也正是 15.1.1「没有明确编程」的反面操作：不看它的代码，只看它的行为。
- **「图像识别」在 API 里是两件事，而书本把它们糊成了一件。** 观察结果的类型由**模型**
  决定（§11：图像进、图像出 ⇒ `VNPixelBufferObservation`、`confidence` 恒为 1），
  你发的**请求**类型由你决定（§12(b)：`VNClassifyImageRequest` 要求分类头，否则
  `Failed to create espresso context.`）。原书那句 `as? [VNClassificationObservation]`
  的 guard 不是「以防万一」，它挡的是这条类型分界；本章把它量成了两种不同的失败。
- **「相似度」是归一化过的概率，第一名是 argmax，而这两件事在模型里就算完了。**
  §14 实测 `argmax(classProbability) == next_discharge_is_shallow`、两组输入都满足
  `和 == 1.0`。书本 15.2.3 那句「排在输出第一位的就是相似度最高的名称」，
  本机的等价断言就是这两条。
- **设备端只做推断，这一条被量成了两个读数**：`isUpdatable=false`（§13）和
  元数据里那行 `coremltoolsVersion=3.3`。书本 15.2.1 自己写了「不能用自己的数据训练」，
  而 15.1.1 那句「保持这种不断的训练」讲的是**训练机上**的事 —— 这两句话在本章
  第一次有了可对表的实测形状。
- **「结果不依赖芯片」不是信念，是一条断言**（§16）。四种 `computeUnits` 概率字典逐字节一致，
  这也是 run-all.sh 能拿 debug 与 release 两份 stdout 做比对的前提。模拟器里没有 ANE
  （设备表只有 `["cpu", "gpu"]`），所以在本机「挑哪块芯片」这个问题只有性能意义。
- **宽容度要背下来，因为它不会告诉你**：多喂的特征被**静默忽略**（拼错名字没有任何提示）、
  int64 喂给 double 被自动加宽接受、跨到图像族才拦、缺特征只点名**第一个**，
  而那句话在 `localizedDescription` 里（这族 NSError 没有 `NSLocalizedFailureReason` 键）。
  再叠上「结构层的账在编译期判」（§8 + 探针 r02）：**校验器管形状，输入检查管值，
  两者都不管你拼错名字。**
- **诚实处理边界**。本章覆盖的是「Core ML 怎么吃一段字节、怎么跑一次断言」，以下几件
  它一条都没验证：模型训练与导出（coremltools 在本机不存在，`f402`/`f604` 那些参数是谁
  算出来的、怎么算的，全在书外）；书本那个 Inception v3（几十兆、要联网，本章用一份
  26 KB 的苹果模型代替，**它不是图像分类器**，所以 §14 的判决是电池行为，不是热狗）；
  真机摄像头那条路（§15 只量了能力）；ANE 上的实际性能（模拟器里不存在那块电路）；
  序列/状态模型（§7 那行类型号里的 sequence(7)、state(8)，本章没有任何实测）；
  以及 Core ML 的**可更新模型**（`isUpdatable` 的另一侧，规格里那一族字段本章只在断言里
  读过它是 false）。还有一条已经钉死为本章做不到的：**用这份工具链手写不出能产出
  `VNClassificationObservation` 的图像分类器**（§18 墙二把合法集合念全了），
  所以书本 15.2.4 那句 `identifier.contains("hotdog")` 在本机没有对应的模型可造 ——
  本章绕道真模型的概率字典，把「热狗判决」做成了 §14 那三条断言。
