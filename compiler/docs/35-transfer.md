# 第 35 章　传递函数收官：状态依赖的传递函数与第四篇总表

## 35.1 本章目标

第 31 章造好了 worklist 不动点求解器——方程组从此有了通用的解法；
第 32 章换一块格（平格上的常量分析）复用同一引擎，验证了"引擎与
域无关"；第 33 章用 gen/kill 三元组把活变量、到达定值、可用表达式、
忙碌表达式四大经典数据流分析统一成同一框架的四个实例，验证了"传
递函数也有公共形状"。到此为止，第四篇的每一次落地都停留在同一类
传递函数上：**函数不看状态**——gen 与 kill 在分析开始前就已确定，
F(S) = (S ∖ kill) ∪ gen 对任何输入状态 S 都执行同一套固定的增删。
本章要跨过这条线：给出一个传递函数**必须看状态**才能写对的分析，
用它收官传递函数理论，然后把 31–35 章的全部七种分析放进一张五元
组分类总表，作为第四篇的收束。

这个"必须看状态"的例子就是 spa 24.1 节的**可能未初始化分析**
（possibly-uninitialized）。考虑一小段 TIP：`if (a > 0) { b = 1; }`
之后紧跟 `c = b`。变量 b 只在条件分支里被赋值，条件可能为假，所以
沿"跳过分支"的那条路径，b 到达 `c = b` 时从未被赋值——b **可能未
初始化**。更要紧的是 `c = b` 这句本身：它把 b 的值抄给 c，而 b 的值
可能根本不存在。分析必须回答：执行过这句之后，c 还算"可能未初始
化"吗？第 33 章的 gen/kill 框架在这里给出错误的答案——无论 gen 和
kill 怎么选，静态增删都表达不出"c 继承了 b 的嫌疑"这件事，因为
**gen 是否包含 c，取决于流入状态里有没有 b**。这就是状态依赖传递
函数的最小天然例子：多一行代码都不需要，gen/kill 就力竭了。

本章的第二个任务是把视野拉远。第四篇跑了四章，先后出现了七种分
析：符号格（28–31 章的主角）、常量分析（17 章）、四大经典（18 章）、
可能未初始化（本章）。它们共用同一个 worklist 引擎，却各有各的格、
各有各的方向、各有各的边界条件与传递函数。把这些差异压进
MonotoneFramework 的**五元组**——格、方向、边界条件、初值、传递
函数族——就得到一张只有七行的分类总表。同一个引擎加不同的五元组
等于七种分析，这张表既是本章的结论，也是第四篇的总结：此后每一
种新分析，都只需要回答五元组的五个问题，而不需要再写一个求解器。

### 35.1.1 与 spa 原书章节的对应

可能未初始化分析在 spa 里出现在第 24 章 24.1 节，作为"TIP 语言上的
数据流分析应用"一节的第一个演示：书上用几行伪代码给出传递函数，
指出它是 may 分析、前向、合并用并集，随后笔锋转向插桩与指针分析。
本书把这一个例子从 24.1 节**提前**到第四篇收官处完整落地，理由有
二。第一，它的理论位置恰好在这里：它是"传递函数依赖状态"的最小
例子，是 gen/kill（18 章）与一般单调框架之间的分水岭；放在 24.1 节
一笔带过，反而看不出它为什么要单独存在。第二，它需要一个完整五
元组才能说清楚——边界条件里"声明变量减参数"的细节、污染规则的
正确性、may 方向的安全性论证——这些 spa 都留给读者，本书逐项补
全到可以直接对账的程度。五元组本身是 spa 第 2 章与第 4 章的
MonotoneFramework 定义，本书在 15、16 两章已经用它的前四项工作过，
本章第一次把五项**同时**写全并打印成对账输出。

### 35.1.2 本章的阅读路线

19.2 从一个具体误判出发，引出状态依赖传递函数的形式化定义，并说
清 gen/kill 与它的关系——后者是前者的静态特例。19.3 把五元组对本
分析逐项实例化。19.4 给正确性定理：单调性保证 worklist 收敛到最小
不动点、最小不动点可靠近似合并过所有路径的 MOP 解；在此基础上分
别论证"不漏报"与"不虚报"两个方向，并单独论证污染规则为什么既
不漏也不虚。19.5 集中过一遍本章复用的十个前端与基础文件，19.6 逐
函数深讲新增的 init.hpp 与 init.cpp，19.7 讲 main.cpp 的流水线总装。
19.8 解读真实输出：逐点 in/out 集合、三条警告、五元组打印段、以及
七行分类总表的逐行阅读。19.9 工程注意点，19.10 小结。

读者需要的全部前置是：第 31 章的 worklist 纪律（变化才入队、单调
保证有界）、第 33 章的 gen/kill 记号与 CFG 程序点编号（1=entry）。
除此之外本章自足——不需要回头重读格的构造章节，本章用到的幂集
格在第 29 章已经作为最简单的一块积木出现过。

## 35.2 当传递函数必须看状态：污染传播

### 35.2.1 从一个误判说起：gen/kill 在这里失灵

先把失败方案具体化，失败在哪里看清楚了，正确的形式化才有着落点。
假设我们坚持用第 33 章的 gen/kill 三元组表达 `c = b` 这句赋值。
gen/kill 框架对赋值语句的通用形状是：kill 目标变量（它被覆写了），
gen 视分析而定。对本分析，"可能未初始化"集合里出现一个变量表示
"它的值可能不存在"，赋值覆写 c，所以 kill 必须包含 c——这一点
没有争议。争议全在 gen：

> **方案一**：gen = ∅。`c = b` 之后 c 被视为已初始化。
> **方案二**：gen = {c}。`c = b` 之后 c 总是被视为可能未初始化。

两个方案各错在一个方向。方案一漏报：若 b 可能未初始化，赋值之后
c 里装的是"不存在的值"，下游 `output c` 读到的仍然是一个不存在
的值——把 b 的嫌疑洗掉是错误的。方案二虚报：若 b 在所有到达路径
上都已初始化（比如 `b = 0; c = b;`），c 明明干干净净，报告却永远
举着它——一个每天都喊狼来了的告警工具很快会被用户关掉。两个方
案合起来暴露了问题的本质：**gen 里该不该有 c，不取决于这条赋值
语句本身，而取决于流入状态里 b 的处境**。第 33 章的框架里 gen 与
kill 是语句的静态属性，分析开始前就已定死；这里需要的是让传递函
数在运行时"看一眼"当前状态再决定加什么。

顺带把 19.1 的引子程序补全：误判不只发生在 `c = b` 一处。b 自身
的读取点（`output b`）需要 may 分析报告"b 可能未初始化"；c 的读取
点需要分析把 b 的嫌疑传染给 c 再在 c 的读取点报告。一个正确分析
的输出应当同时覆盖这两类报告——35.8 节的真实输出将逐条兑现这个
预期。

### 35.2.2 状态依赖传递函数的形式化

修正的方法直截了当：把传递函数从"固定增删"升级为"读状态的函
数"。对前向分析，传递函数以流入状态 S（一个"可能未初始化变量"
集合）为自变量，返回流出状态。逐类语句写出来：

> **赋值 x = e**：F_S(x = e) = (S ∖ {x}) ∪ ({x} 若 vars(e) ∩ S ≠ ∅)，
> 其中 vars(e) 是表达式 e 读取的变量集合。
>
> **其余语句**（output、return、分支条件、entry/exit 空点）：F_S = S，
> 原样传递。

赋值规则分两步读。第一步 S ∖ {x}：x 被覆写，旧的嫌疑一笔勾销——
这一步与 gen/kill 的 kill 完全相同。第二步条件性的 {x}：若右值 e
读取的变量中**任何一个**正在当前状态的嫌疑集合里，那么 e 的值可
能不存在，x 抄到的也就是一个不存在的值——x 重新进入嫌疑集合。
注意"任何一个"对应的是 may 语义：只要存在一条路径让右值缺失，
x 就算嫌疑；它不需要右值的所有变量都缺失。这就是**污染传播**：
嫌疑沿数据流从右值传染给左值，如同染色剂沿水流扩散。

这个函数是**单调的**，值得当场验证，因为单调性是 35.4 节全部正确
性论证的前提。设 S ⊆ T：第一步 (S ∖ {x}) ⊆ (T ∖ {x}) 显然；第二
步，若 vars(e) ∩ S ≠ ∅ 则 vars(e) ∩ T ≠ ∅（交集只会变大），于是
条件成立时左边加 {x}、右边也加 {x}。两步都保持子集关系，故
F_S(x = e) 单调。恒等传递显然单调。整个传递函数族单调，框架的前
提成立。

还有一个值得驻足的细节：赋值规则先删 x 再有条件地加回 x——如果
条件成立，净效应是 S 原封不动；如果条件不成立，净效应是删掉 x。
在 35.8 节的输出里，`c = b` 这一点会呈现出 in 集合与 out 集合完全
相等的现象，读者那时不要误以为"这条赋值没起作用"——它 kill 了
c 又立刻污染回来，两步都执行了，只是相互抵消。这个"先杀后染"的
两步形状，正是状态依赖传递函数与 gen/kill 的分界线：gen/kill 只
能表达"删一些、加一些"的固定动作，表达不了"删掉之后**看情况**
加回来"。

### 35.2.3 gen/kill 是状态依赖传递函数的静态特例

把新旧两种传递函数放进同一个坐标系，第四篇的版图就完整了。
gen/kill 传递函数 F(S) = (S ∖ kill) ∪ gen 是状态依赖传递函数的
特例：当"加什么、删什么"与 S 无关时，一般形式退化为静态形式。
具体地，本章的 F_S(x = e) 在 vars(e) = ∅（右值是常量、input 等不
读变量的表达式）时退化为 F_S = S ∖ {x}——一个纯 kill，第 33 章
的"到达定值"等分析用的正是这类。反过来不成立：vars(e) ∩ S ≠ ∅
的条件项没有任何 gen/kill 三元组能表达，19.2.1 的两个失败方案已
经从两侧把它夹死了。

这个包含关系有实际的工程含义。第一，**能力边界有了精确刻划**：
什么时候必须放弃 gen/kill 框架？当传递函数需要根据状态决定增删
时。第二，**复用边界也有了精确刻划**：第 31 章的 worklist 引擎不
需要任何修改就能跑状态依赖传递函数——引擎只要求"给它一个输入
状态，它返回一个输出状态"，从不假设函数内部长什么样。第 32 章
换格不动引擎，本章换传递函数形状依然不动引擎：引擎的普适性到本
章才算真正验收完毕。第三，理论谱系上，gen/kill 对应的位向量框架
（bit-vector framework）是单调框架的子族，spa 用"分配性"刻划它
的精确范围——19.4.4 节会回到这个词。

### 35.2.4 边界条件：声明变量减参数

状态依赖传递函数回答了"点与点之间怎么传"，还差一个"链条从哪里
开始"——边界条件。本分析的规则是：

> **entry(f) = 声明变量 ∖ 参数**：函数入口处，每个声明的局部变量
> 都进入"可能未初始化"集合，参数不进入。

规则的依据是 TIP 的调用约定。TIP 不给局部变量默认初值——`var a,
b, c;` 只是登记名字，没有赋任何值，所以局部变量从出生起就带着
"值可能不存在"的嫌疑。参数不同：函数体执行的前提是有人调用它，
而 TIP 的调用 `f(e1, ..., en)` 在进入函数体之前就把全部实参求值
并绑定给形参——形参在入口处**必然**持有值，把它们放进嫌疑集合
是对调用约定视而不见，会制造纯虚报。

这个边界条件值得与第四篇此前的边界条件对读一遍。符号格分析
（28–31 章）的边界是"参数 = ⊤、局部 = ⊥"：同一个调用约定，翻
译成符号域就是"实参可以是任何符号（⊤）、局部变量尚无任何信息
（⊥）"。常量分析（17 章）同理。可见**边界条件是调用约定在各个域
里的翻译**：约定只有一句"参数有值、局部没有"，到了幂集格里表现
为"参数不在嫌疑集合、局部在"；到了符号格里表现为"参数取 ⊤、局
部取 ⊥"。35.8 节的分类总表里这一列的对比，读的就是这件事。

may 分析的其余程序点从 ⊥ = ∅ 出发。幂集格的 ⊥ 是空集，语义是
"还没有任何变量被证明可能未初始化"——与第 31 章"⊥ 是尚未证明
任何事实"的读法完全一致。迭代只做两件事：并前驱（合并路径）、
施加传递函数（保守传染），从不凭空往集合里放变量。因此收敛值里
的每个成员都有推导链，35.4 节把这条链 formal 化为"落到一条具体
路径上"。

## 35.3 单调框架五元组的完整实例化

spa 把一个过程内数据流分析的形式化规格压缩成五元组
MonotoneFramework ⟨L, direction, boundary, init, F⟩。五元组的价值
在于它是一张**填空题**：选定一个分析问题，只要五道空都填得出
（且传递函数族单调、格高度有限），其余一切——求解算法、终止性、
正确性——全部由框架白送。本节把这五道空对本分析逐一填掉；19.8.4
节再与 main.cpp 打印的五元组段逐行对照，纸面与机器互为印证。

### 35.3.1 五道空逐一填掉

**第一空：格 L。** 变量全集 Vars 的幂集 𝒫(Vars)，序取子集 ⊆。
合并（join，may 语义）是并集 ∪：两条路径各自带来的嫌疑合并后取
并——任一路径上的嫌疑都算数。⊥ = ∅（什么嫌疑都还没证明），⊤ =
Vars（所有变量都有嫌疑，最保守）。格的高度是 |Vars| + 1：每次传
递要么让集合严格变大、要么不动，而集合最多从空涨到全变量集，这
是 19.4.2 终止性论证的全部度量。第 29 章把幂集格作为映射格的特例
讲过，本章原样取用——分析史上最老牌的域至今仍是最好用的域之一。

**第二空：方向。** 前向。理由在数据的流向里："可能未初始化"是一
个**随执行向前携带**的性质——赋值把它从右值搬到左值，覆写把它
抹掉。信息沿 CFG 的边从入口流向出口，状态自然挂在每条边的**源点
流出**与**终点流入**上。对照第 33 章的活变量分析（信息逆执行流回
流，backward），方向的判定标准从来都是一句话：性质的产生方向。

**第三空：边界条件。** entry(f) = 声明变量 ∖ 参数（19.2.4 已论证）。
形式上它是"特殊点的特殊值"：入口点的流入状态不由前驱合并而来，
而是直接赋这个手工给定的值。

**第四空：初值。** 除入口（以及无前驱的点，它们同样取边界值）外，
一切程序点从 ⊥ = ∅ 出发。这一空决定解的品位：从 ⊥ 出发只向上
爬，到达的是**最小不动点**——所有不动点中最精确的那个；若从 ⊤
出发，得到的是最大不动点，may 分析里那等于"所有变量处处有嫌疑"，
毫无可用性。第 31 章 16.2.3 用符号格推过同一件事，那里的结论在这
里逐字成立。

**第五空：传递函数族 F。** 每个程序点一个函数，形状由 19.2.2 给
出：赋值点用状态依赖的两步规则，其余点恒等。与 gen/kill 框架相
比，唯一的新自由度是函数体可以读自变量 S——框架的接口签名没有
任何变化。

五空填毕，方程组随之确定：对每个程序点 n，

> in(n) = ⋃ { out(p) | p ∈ pred(n) }（n 无前驱时取边界值），
> out(n) = F_n(in(n))。

这组方程的解就是分析的全部答案：in(n) 告诉你"到达 n 时哪些变量
可能未初始化"，out(n) 告诉你"离开 n 时呢"。35.6 节的
runInitAnalysis 逐字实现了这两行——读者可以先记住方程再读代码，
一一对应。

### 35.3.2 为什么是五元组而不是别的

五元组的五个槽位不是凑数，它们恰好把"换一个分析要改什么"枚举
干净。31–35 章的实践反过来验证了这一点：第 32 章换的是第一空
（幂集格换成平格）与第五空；第 33 章四个分析换的是第二、三、四
空（方向、边界、初值）与第五空的形状（gen/kill）；本章换的是第
五空的**本质**（状态依赖）与第三空的细节（减参数）。第一空和第
五空合起来是"分析的语义"，第二、三、四空合起来是"分析的调度"。
五元组把语义与调度正交化——worklist 引擎只消费调度信息，对语义
完全盲。这就是 19.1 说的"同一个引擎加不同五元组等于七种分析"的
机制基础，也是 19.8.5 分类总表按列组织的原因：每一列正好对应一
个或两个槽位。

## 35.4 正确性定理

### 35.4.1 定理陈述

把 19.2 与 19.3 的准备工作收拢，可以陈述本章的中心定理了。陈述
里 MOP（merge-over-paths，路径合并解）指"按路径枚举定义的精确
解"：对每条从入口到点 n 的 CFG 路径，把边界条件沿路径逐点施加传
递函数，得到该路径的贡献状态；MOP(n) 是全部路径贡献的并。它是
路径语义下的理想答案，但按定义不可直接计算——19.4.5 节解释为什么。

> **定理 19.1（单调框架的可靠性与精度）** 设传递函数族单调、格高
> 度有限。则：
>
> （1）（终止）从边界条件与其余点 ⊥ 出发的 worklist 迭代在有限步
> 内终止，终止时各点状态构成方程组的最小不动点 MFP。
>
> （2）（可靠近似）MFP ⊒ MOP：任何沿 CFG 路径可推导的"可能未初
> 始化"事实都包含在 MFP 中。对 may 分析，子集序下"更大"就是"更
> 安全"，故这是**不漏报**方向。
>
> （3）（分配性升级）若传递函数族进一步是分配性的——
> F(S₁ ∪ S₂) = F(S₁) ∪ F(S₂)——则 MFP = MOP：计算结果与路径枚举
> 的理想解逐点相等，每个被报告的事实都能落到一条具体路径上，
> 即**不虚报**。
>
> 本章分析的传递函数族是分配性的，三条同时成立。main.cpp 打印的
> 定理段只承诺了（1）（2）——框架给出的一般保证——而本分析凭分配
> 性自动享受（3），35.8 节读输出时可以看到这一点落在具体警告上。

注意"路径"一词的精确含义：指 CFG 上的一条路径，不保证该路径在
条件相关性意义下可执行（两个 if 的条件是否可能同时为真，图上看
不出来）。定理担保的是**路径级事实**——合并算子与传递函数绝不
凭空造出任何路径上都不存在的嫌疑；条件相关的不可行路径仍可能带
来多余警告，这是第 2 章不可判定性划定的固有边界，全篇所有图分析
共享。

### 35.4.2 论证一：终止——单调加有界

第（1）条的论证第 31 章已经完整给出（31.4 节的三段归纳：不变量、
终止、最小性），本章只核对前提。不变量段：迭代中任何点的状态永
远 ⊒ 该点的初始值（⊥ 或边界值），且每次重算用的是"并前驱 + 单
调传递"，结果 ⊒ 旧值——单调性保证输入变大时输出不会变小。终止
段：每次实质更新让某点状态**严格**上升（不变就不入队，35.6 节的
代码里能看到这个守卫），而高度 |Vars| + 1 有限，严格上升的总次数
有限，队列必然排空。最小性段：迭代从不引入方程组不可推导的事实，
故收敛值 ⊑ 任何不动点，即最小不动点。三条前提——单调、有界、
从 ⊥ 出发——本章全部满足，结论整体继承。

### 35.4.3 论证二：MFP 覆盖所有路径——不漏报

第（2）条用对路径长度的归纳。奠基：长度为零的路径停在入口，其
贡献就是边界值，而入口点在不动点处的状态恰好等于边界值——贡献
⊑ 状态。归纳步：设路径 p = p′ → n，p′ 的贡献 ⊑ MFP(p′ 的终点)。
不动点处 out(n) ⊒ F_n(in(n)) ⊒ F_n(MFP(终点 p′))——第一步因为
MFP 是方程组的解，第二步对 in(n) = ⋃ out(前驱) 应用单调性，路径
p′ 的贡献是它前驱 out 的一个"分量"，单调函数保持 ⊑。于是 p 的
贡献 = F_n(p′ 的贡献) ⊑ out(n)。归纳完毕：每条路径的贡献都 ⊑ 该
路径终点的 MFP 状态，取并即 MOP ⊆ MFP。

这一条对 may 分析是安全性的全部：假如存在一条真实（路径级）的
use-before-init——某路径上 b 未初始化却到达了读取点——归纳保证
b 必在该读取点的 in 集合里，警告必然发出。**宁可多报，不可漏报**
的次序在定理里成形：MFP 比 MOP 大的部分正是"多余的警告"，它们
是合并付出的代价，永远方向正确。

### 35.4.4 论证三：分配性——本章为何两全

第（3）条是本章分析的额外红利，值得完整论证，因为它精确回答
"什么时候 worklist 不损失任何精度"。先验证本章传递函数的分配性。
对赋值点，分情况：若 vars(e) ∩ (S₁ ∪ S₂) ≠ ∅，则交集非空必然来
自 S₁ 或 S₂ 至少一方非空，两侧都得到 (S₁ ∪ S₂ ∖ {x}) ∪ {x} 与
(F(S₁) ∪ F(S₂)) 的对应并——逐元素核对相等；若交集为空，则两侧
条件项都不出现，退化为纯删除的分配性，显然。恒等函数显然分配。

分配性给结论（3）的论证补上另一半。19.4.3 已证 MOP ⊆ MFP；现在
反证 MOP 本身是方程组的一个解：对每个点 n，把 MOP(n) 按"路径的
最后一条边"分组，得 MOP(n) = ⋃_{p∈pred(n)} F_n(MOP(p))——因为
分配性允许把"先合并再传递"改写成"先传递再合并"，路径贡献恰好
按最后一条边拆开重组。MOP 是解，MFP 是最小解，故 MFP ⊆ MOP。
两头夹拢，MFP = MOP。

推论落在警告上：MFP 里的每个成员都能落到一条具体路径。于是本章
的每一条警告都是"实的"——能指认一条使它成立的路径——19.8.3 的
三条警告将逐条给出指认。附带一提：第 33 章的四个 gen/kill 分析
全是分配性的（位向量框架的标准结论），所以那一章的分析同样
MFP = MOP；不分配的是符号格与常量分析——join 表把 (−2, +2) 压成
⊤ 的那一刻，路径信息被有损压缩，MFP 严格大于 MOP 的可能就此出
现。精度损失发生在**域的合并**里，而不是发生在**迭代算法**里——
这个定位常常被初学者弄反，值得写进结论。

### 35.4.5 为什么不追求精确 MOP：路径爆炸

既然 MOP 是精确解，为什么不直接算它？因为它的定义就不可执行。
第一重是指数：k 个二分支的程序有 2^k 条路径，逐路径求值的代价随
分支数指数增长；twenty 行的程序就能让任何机器破产。第二重更深：
循环让路径数**无穷**——一个 while 就能把"进入循环体几圈"的组合
铺成无限条路径；虽然格有限使"所有路径的并"塌缩成"简单路径的
并"（重复绕圈只重复贡献已并入的元素），枚举仍然不可行。第三重是
工程性的：路径枚举无法与程序点的结构共享计算，而 worklist 把指
数条路径的信息压缩进 |点数| × 高度 的表里，每条路径的代价被摊薄
到它经过的点上。

所以正确的问法不是"如何算 MOP"，而是"如何在多项式时间内得到
MOP 的可靠近似"。单调框架的回答：把"逐路径求值再合并"换成
"点上合并再逐点传递"，代价 O(点数 × 高度 × 单次传递代价)，安全
性由 19.4.3 保证；精度由 19.4.4 划界——传递函数分配则分文不损，
不分配则损失有界且方向安全。MOP 在整个体系里的角色因此是**精度
的上限标尺**：任何图分析宣称"精度",都要回答它与 MOP 差多远、差
在哪里。第 51 章的 IFDS 会把这个问题再推进一步——存在一类分析
（可分配到路径边上的）连 MOP 都能在多项式时间内精确算出，那是
后话。

### 35.4.6 污染规则的正确性：c 继承 b 的嫌疑，既不漏也不虚

19.2.2 的污染规则值得单独一段论证，因为它是全章唯一的非平凡传
递规则，而"继承嫌疑"听上去像一句直觉口号。把它落到路径语义上，
口号就有了骨架。

**不漏的方向。** 设执行到 `c = b` 时，存在一条路径使 b 未初始化。
19.4.3 的归纳保证 b ∈ in(该点)（否则那条路径就漏报了，与定理矛
盾）。传递函数看到 vars(e) = {b} 与 in ∋ b 相交非空，把 c 加进
out。关键一步在具体语义：赋值执行后 c 持有的值恰是 b 持有的值，
而 b 的值不存在，所以"c 的值存在"为假——c 在那条路径（延长一条
边）上确实未初始化。抽象规则的加入动作与具体语义的路径延长**一
一对应**：抽象加进集合的每个变量，具体语义都有一条路径背书。

**不虚的方向。** 反过来，传递函数把 c 加进 out 当且仅当 vars(e)
∩ in ≠ ∅，即 in 里确有 b；由分配性（19.4.4），in 里的 b 落在某条
到达路径上，那条路径延长一条边就是"c 未初始化"的见证。规则的
每个加入动作都被路径收账，没有一个凭空。

一个容易忽略的建模决策也在这条规则里：**未初始化的值被当作"毒
值"（poison）传播，而不是被当作"某个任意的值"**。后一种读法在
机器层面也说得通——b 虽未赋值，内存里总有某个比特模式，抄给 c
之后 c 就"有值"了——但那样 `output c` 就不再报警，而用户通常希
望看到报警：下游对 c 的每次使用都同样危险。把"读到未初始化值"
本身定性为病、把病随数据流传染下去，正是 LLVM 的 poison/undef
语义与众多静态分析工具的共同选择。本分析选择传染，19.8.3 的第三
条警告就是传染的直接体现。

### 35.4.7 与前两篇分析的可靠性承诺对读

在进入工程落地之前，把定理 19.1 的承诺与第三、四篇已经见过的分析
对读一遍，可靠性这张版图就完整了。

先看承诺的方向。19.2–19.4 的论证对本分析给出"不漏且不虚"——
may 方向保证所有路径级事实被覆盖，分配性保证报告的每条事实有路径
背书。请与第 32 章常量分析对比：常量分析同样有 may 框架的不漏承诺，
但它不享受不虚——MFP 里 TOP 之下掩盖了什么，路径信息在 join 时
已被压扁，某个变量被报 TOP 是"算不出来"，而不是"有路径见证它
非常量"（虽然这种见证事实上存在，但框架没有指认）。承诺强弱的
差别只在一个性质：传递函数分配与否。

再看承诺的对象。定理保护的是路径级事实，不是可执行级事实。这一点
第 28–31 章的符号格分析同样如此：if 两个条件在图上可以任意组合，
分析不去判定条件之间的相关性。把承诺读到"每条警告在某次真实输入下
发生"是过度解读——正确读法是"每条警告在某条 CFG 路径上发生，
该路径是否有输入能实现，不在分析知识范围内"。这条边界由第 2 章
停机问题划定，不可由算法改进消除；第 39 章的路径精炼能缩小一部分
差距，但不能消灭。

最后看承诺与用途的匹配。未初始化警告通常直接面向用户：它要足够实，
否则告警泛滥被关掉；又必须全，漏掉一个 use-before-init 可能就是
一次现场崩溃。定理（2）（3）恰好对应这两个用途，这解释了 spa 为什么
把这个例子作为数据流应用的首个演示——它是少数"两个方向的承诺
都被实际需要、且都能被框架兑现"的分析。理解可靠性论证的正确
姿势因此不是记公式，而是先问：这个分析的消费者需要什么承诺，框架
与传递函数能不能给出？

## 35.5 复用的十个前端与基础文件

19.2–19.4 在纸面上把分析讲完了：传递函数、五元组、正确性定理。从本节
开始进入工程落地。落地的第一件事不是写新代码，而是清点家底——本章
示例的 src/ 目录下共有十二个 C++ 文件，其中只有两个（init.hpp 与
init.cpp）是本章新增，其余十个文件连同 TIP.g4 全部沿用自前面的章节：
词法语法、AST、名字解析、CFG、美化打印，这条前端流水线从第 4 章搭好
之后就再没有为某一个分析改过。复用不是偷懒，而是单调框架在工程上的
直接推论：框架把"分析的语义"全部隔离进传递函数与格，分析之外的代码
自然一个字都不需要动。

本节把这十个文件连同文法逐个嵌入并交代：它是什么时候造的、在本章
流水线里承担什么角色、读者这次重读时应当注意哪些与分析有关的侧面。
每个文件先给一段角色说明，再整文件嵌入，嵌入之后再点几处值得驻足的
关键行。读者如果已经跟着前面的章节亲手跑过这条流水线，可以快速浏览
本节，把注意力留给 19.6 的新增代码；如果是中途加入，本节足以补齐全部
上下文——不需要回头翻其他章节的源码。

### 35.5.1 TIP.g4：一切的起点

先嵌入文法 TIP.g4。它定义在第 4 章，此后一字未改——本章分析的全部
语句形状（赋值、输出、if、while、块）与表达式形状（整数、变量、
input、二元运算、调用、指针与记录）都在这份文法里。本章的传递函数
只覆盖其中一个子集：指针、记录、动态分配在状态依赖规则里没有专门
条款，具体理由放在嵌入后的说明里。

```cpp
// file: TIP.g4
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
AND        : '&' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

读这份文法时请带着 19.2 的传递函数对照，有三处值得驻足。

第一处是第 9–14 行的 stmt 产生式。本章状态依赖规则的逐类语句分派
恰好按这五个备选展开：assignStmt 走两步污染规则，outputStmt 与
ifStmt、whileStmt 的条件读取参与"右值读到 S 中变量"的判定但语句本身
不改变状态，blockStmt 在 CFG 构造时被展平、分析器根本看不到它。
文法里有多少语句类，传递函数就该有多少条款——漏掉任何一个，框架的
单调性论证都在那个缺口处失效。

第二处是第 27–43 行的 expr 产生式。usesOf（35.6 节将读到）对表达式
的递归形状与这组备选一一对应：IntLit 与 INPUT 不读变量，IDENT 读一个
变量，其余备选递归进子表达式。文法的优先级也在这里声明——乘法
STAR/DIV 绑定紧于加法 PLUS/MINUS、紧于比较 GT/EQ——因此 AST 上的
括号结构已经正确，usesOf 不需要自己判断优先级，只需照树收集。

第三处是第 30–32 行的 lvalue。赋值目标在文法上已被限定为
IDENT（可带字段）或 STAR expr（可带字段）两种，这解释了传递函数为什么
敢写"o.erase(t->name)"——本章只处理 VarRef 目标，Deref 目标意味着
通过指针间接写，没有指针分析就无法判断写中了谁，强行 erase 任何一个
具名变量都是虚报或漏报。教学实现的选择是：Deref/FieldA 目标的赋值
原样传递状态（既不 kill 也不污染目标），这是一个保守但 sound 的缺口；
第 41、42 章的指针分析会把它补上。

还有第四处藏在文件末尾的词法规则里，容易被读语法的人略过。第 50–52
行三类空白——WS、块注释、行注释——全部 skip；注释里写的代码不进
AST，分析器自然也看不见。第 50–63 行关键字 token 的声明顺序在
IDENT（第 50 行）之前：ANTLR 按声明顺序优先匹配，因此 `input` 这样
的字符序列被切成 INPUT 而不是 IDENT，程序里不可能出现名为 input 的
变量。这个次序本身就是语言语义的一部分——它保证了第 9–14 行语句中
的关键字不会与普通标识符混淆，ast_build 里靠标签备选区分语句时
才无歧义。读文法请连同词法部分一起读：语法决定形状，词法决定
哪些形状可能出现。

### 35.5.2 ast.hpp：冻结的中间表示

TIP.g4 之后是 AST 定义 ast.hpp。词法语法分析的产物是 parse tree——
带着括号、分号、优先级的语法树；AST 是剥掉语法噪音之后的程序结构，
也是名字解析、CFG、以及全部数据流分析共同工作的台面。这个文件从
定义之日起冻结：接口冻结意味着每个分析都只是在既有节点类上挂新
行为，从不为某个分析增删节点。

```cpp
// file: src/ast.hpp
// AST 定义：AST 是去掉了括号、分号等语法噪音的程序结构。
// 接口自本章起冻结，后续所有分析（名字、CFG、类型、格……）都在此之上工作。
#pragma once

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace tip {

enum class BOp { Add, Sub, Mul, Div, Gt, Eq };

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr {
    int v;
    explicit IntLit(int value) : v(value) {}
};
struct VarRef : Expr {
    std::string name;
    explicit VarRef(std::string n) : name(std::move(n)) {}
};
struct InputE : Expr {};
struct Binop : Expr {
    BOp op;
    std::unique_ptr<Expr> l, r;
    Binop(BOp o, std::unique_ptr<Expr> lhs, std::unique_ptr<Expr> rhs)
        : op(o), l(std::move(lhs)), r(std::move(rhs)) {}
};
struct CallE : Expr {
    std::unique_ptr<Expr> callee;
    std::vector<std::unique_ptr<Expr>> args;
    CallE(std::unique_ptr<Expr> fn, std::vector<std::unique_ptr<Expr>> as)
        : callee(std::move(fn)), args(std::move(as)) {}
};
struct Deref : Expr {
    std::unique_ptr<Expr> e;
    explicit Deref(std::unique_ptr<Expr> p) : e(std::move(p)) {}
};
struct AddrOf : Expr {                       // spa: & Id
    std::string name;
    explicit AddrOf(std::string n) : name(std::move(n)) {}
};
struct AllocE : Expr {
    std::unique_ptr<Expr> e;
    explicit AllocE(std::unique_ptr<Expr> init) : e(std::move(init)) {}
};
struct NullE : Expr {};
struct RecLit : Expr {
    std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
    explicit RecLit(std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fs)
        : fields(std::move(fs)) {}
};
struct FieldA : Expr {
    std::unique_ptr<Expr> e;
    std::string field;
    FieldA(std::unique_ptr<Expr> record, std::string f)
        : e(std::move(record)), field(std::move(f)) {}
};

struct Stmt {
    virtual ~Stmt() = default;
};
// target 只会是 VarRef / FieldA / Deref，文法 lvalue 已限定。
struct AssignS : Stmt {
    std::unique_ptr<Expr> target, value;
    AssignS(std::unique_ptr<Expr> t, std::unique_ptr<Expr> v)
        : target(std::move(t)), value(std::move(v)) {}
};
struct OutputS : Stmt {
    std::unique_ptr<Expr> e;
    explicit OutputS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};
struct IfS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> then, els;
    IfS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> t, std::unique_ptr<Stmt> e)
        : cond(std::move(c)), then(std::move(t)), els(std::move(e)) {}
};
struct WhileS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> body;
    WhileS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> b)
        : cond(std::move(c)), body(std::move(b)) {}
};
struct BlockS : Stmt {
    std::vector<std::unique_ptr<Stmt>> ss;
    explicit BlockS(std::vector<std::unique_ptr<Stmt>> v) : ss(std::move(v)) {}
};
struct ReturnS : Stmt {
    std::unique_ptr<Expr> e;
    explicit ReturnS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};

struct FunDecl {
    std::string name;
    std::vector<std::string> params;
    std::vector<std::string> vars;
    std::unique_ptr<Stmt> body;
    std::unique_ptr<ReturnS> ret;
};

struct ProgramA {
    std::vector<std::unique_ptr<FunDecl>> funs;
};

}  // namespace tip
```

重读 ast.hpp，与本章分析直接相关的有三处。

第一处是第 21–49 行的表达式层次。注意每个节点都以 std::unique_ptr
持有子节点、析构虚函数在基类 Expr 上声明——整棵树靠根节点析构
自动回收，分析器拿到的裸指针（const Expr*）随 AST 存活，本章把它们
存进警告信息里也不会悬垂。第 32 行的 CallE 与指针、记录节点本章
用不到，但它们占着文法位置；前面说的"传递函数要覆盖全部语句类"
对表达式同样成立——usesOf 对不认识的节点必须保守，好在它的默认
返回值是空集：一个不读变量的节点，不参与污染判定，这是 sound 的。

第二处是第 63–95 行的语句层次。第 67 行 AssignS 的注释点明 target
只会是 VarRef、FieldA、Deref 三种——传递函数的动态分派正是围绕这
三种展开。第 88 行 BlockS 只在 CFG 构造期有意义：CFG 连边之后程序点
之间没有"块"的概念，分析器看到的节点都是扁平的。

第三处是第 97–103 行的 FunDecl。请特别注意第 100 行的 vars 与第 101
行的 params 是两个独立列表——19.2.4 的边界条件"声明变量减参数"
就是在这两个列表上做集合差。第 102 行 ret 是单独保存的返回语句：
CFG 构造器（马上读到的 cfg.cpp）为它单建一个 Return 节点，编号排在
函数体所有节点之后。本章输出里节点 9 的 return 与节点 10 的 exit
就是这样来的。

关于所有权也值得补一句：所有节点之间的边都是 unique_ptr 单向持有，
树中不存在共享——因此不存在两个节点争着释放同一子树的可能，也用不到
引用计数。分析器拿到的 const 裸指针是"借"：AST 主程序持有全部所有权，
借用方既不能延长生命、也无须负责释放。本章把这种借用指针存进警告文本
之外的任何长期结构都是危险的；判断准则一句话——**谁比 AST 活得久，
谁就不能只存裸指针**。本章所有产物（InitResult 里的字符串集合）都不
引用 AST 节点以外的长期状态，警告只拷贝语句的文本，因此即使 AST
先于结果释放（本例不会），输出文本依然成立。

### 35.5.3 ast_build.hpp：parse tree 到 AST 的桥梁

下一个文件 ast_build.hpp 很短，它声明 AstBuilder——一个在 ANTLR
生成的 parse-tree 上下文对象上手工递归的构建器。文件头注释解释了
为什么不用 ANTLR 的 visitor 机制：本工具链 C++ runtime 的 visitor 以
std::any 传值，而 std::any 无法持有 unique_ptr，于是直接在上下文类
上做一次结构化遍历反而更干净。

```cpp
// file: src/ast_build.hpp
// AST 构建器：在 ANTLR 生成的 parse-tree 上下文节点上手工递归下降。
// （本工具链 C++ runtime 的 visitor 以 std::any 传值，而 std::any 不能持有
// unique_ptr，因此不使用 visitor 机制：parse-tree 的上下文类本身信息完整，
// 用 dynamic_cast 区分 #标签备选，自己做一次结构化遍历同样直接。）
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "TIPParser.h"
#include "antlr4-runtime.h"
#include "ast.hpp"

namespace tip {

struct AstBuilder {
    std::unique_ptr<ProgramA> build(TIPParser::ProgramContext *tree);

private:
    std::unique_ptr<FunDecl> buildFun(TIPParser::FunctionContext *ctx);
    std::unique_ptr<Expr> buildExpr(TIPParser::ExprContext *ctx);
    std::unique_ptr<Stmt> buildStmt(TIPParser::StmtContext *ctx);
    // lvalue 翻译成赋值目标表达式：VarRef / Deref，可再包一层 FieldA。
    std::unique_ptr<Expr> buildLvalue(TIPParser::LvalueContext *lv);
};

// 便捷入口：parse tree 的 program 节点 -> 完整 AST。
std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree);

}  // namespace tip
```

这个头文件对本章分析的意义全在第 18 行的 build 签名上：输入
parse tree 根节点，输出 ProgramA。main.cpp 的流水线
（解析 → buildAst → resolveNames → buildCfg → runInitAnalysis）
中它是第二环，之后所有环节都只依赖 AST，parse tree 的上下文对象
随 parser 一起消亡。对分析作者来说，这条边界值得记住：**一旦进入
AST，语法层面的信息（token、备选标签、源码位置）就全部不可见了**；
如果某条分析规则需要源码位置（比如警告里报行号），必须在 AST 节点
上预留字段，而不能指望事后回到 parse tree。本章的警告只报 CFG 节点
号，就是遵循这条边界。

### 35.5.4 ast_build.cpp：结构化遍历的实现

ast_build.hpp 的实现。buildExpr 对 expr 的每个标签备选逐一翻译，
buildStmt 对 stmt 同样处理，buildLvalue 专门处理文法限定的两种
左值。建议读者对照 19.5.1 的文法产生式读这个文件——每个 dynamic_cast
对应一个 `#` 标签备选，逐一核对能确认翻译没有遗漏。

```cpp
// file: src/ast_build.cpp
#include "ast_build.hpp"

#include <utility>
#include <vector>

namespace tip {

std::unique_ptr<ProgramA> AstBuilder::build(TIPParser::ProgramContext *tree) {
    auto program = std::make_unique<ProgramA>();
    for (auto *fc : tree->function()) program->funs.push_back(buildFun(fc));
    return program;
}

std::unique_ptr<FunDecl> AstBuilder::buildFun(TIPParser::FunctionContext *ctx) {
    auto f = std::make_unique<FunDecl>();
    f->name = ctx->IDENT()->getText();
    if (ctx->params()) {
        for (auto *p : ctx->params()->IDENT()) f->params.push_back(p->getText());
    }
    if (ctx->varDecls()) {
        for (auto *v : ctx->varDecls()->IDENT()) f->vars.push_back(v->getText());
    }

    std::vector<std::unique_ptr<Stmt>> body;
    for (auto *sc : ctx->stmt()) body.push_back(buildStmt(sc));
    f->body = std::make_unique<BlockS>(std::move(body));

    f->ret = std::make_unique<ReturnS>(buildExpr(ctx->expr()));
    return f;
}

std::unique_ptr<Expr> AstBuilder::buildLvalue(TIPParser::LvalueContext *lv) {
    std::unique_ptr<Expr> base;
    std::string field;
    if (auto *d = dynamic_cast<TIPParser::DirectLvalueContext *>(lv)) {
        base = std::make_unique<VarRef>(d->IDENT(0)->getText());
        if (d->IDENT().size() == 2) field = d->IDENT(1)->getText();
    } else {
        auto *p = dynamic_cast<TIPParser::PointerLvalueContext *>(lv);
        base = std::make_unique<Deref>(buildExpr(p->expr()));
        if (p->IDENT()) field = p->IDENT()->getText();
    }
    if (!field.empty())
        return std::make_unique<FieldA>(std::move(base), std::move(field));
    return base;
}

std::unique_ptr<Expr> AstBuilder::buildExpr(TIPParser::ExprContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::IntExprContext *>(ctx))
        return std::make_unique<IntLit>(std::stoi(c->INT()->getText()));
    if (auto *c = dynamic_cast<TIPParser::VarExprContext *>(ctx))
        return std::make_unique<VarRef>(c->IDENT()->getText());
    if (dynamic_cast<TIPParser::InputExprContext *>(ctx))
        return std::make_unique<InputE>();
    if (dynamic_cast<TIPParser::NullExprContext *>(ctx))
        return std::make_unique<NullE>();
    if (auto *c = dynamic_cast<TIPParser::ParenExprContext *>(ctx))
        return buildExpr(c->expr());

    if (auto *c = dynamic_cast<TIPParser::AddExprContext *>(ctx)) {
        const BOp op = c->PLUS() ? BOp::Add : BOp::Sub;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::MulExprContext *>(ctx)) {
        const BOp op = c->STAR() ? BOp::Mul : BOp::Div;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::CmpExprContext *>(ctx)) {
        const BOp op = c->GT() ? BOp::Gt : BOp::Eq;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::NegExprContext *>(ctx)) {
        // TIP 没有负数字面量 token，-E 即 0-E。
        return std::make_unique<Binop>(BOp::Sub, std::make_unique<IntLit>(0),
                                       buildExpr(c->expr()));
    }
    if (auto *c = dynamic_cast<TIPParser::CallExprContext *>(ctx)) {
        std::vector<std::unique_ptr<Expr>> args;
        if (c->args())
            for (auto *a : c->args()->expr()) args.push_back(buildExpr(a));
        return std::make_unique<CallE>(buildExpr(c->expr()), std::move(args));
    }
    if (auto *c = dynamic_cast<TIPParser::FieldExprContext *>(ctx))
        return std::make_unique<FieldA>(buildExpr(c->expr()), c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::DerefExprContext *>(ctx))
        return std::make_unique<Deref>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::AddrExprContext *>(ctx))
        return std::make_unique<AddrOf>(c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::AllocExprContext *>(ctx))
        return std::make_unique<AllocE>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::RecExprContext *>(ctx)) {
        std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
        for (auto *fc : c->field())
            fields.emplace_back(fc->IDENT()->getText(), buildExpr(fc->expr()));
        return std::make_unique<RecLit>(std::move(fields));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<Stmt> AstBuilder::buildStmt(TIPParser::StmtContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::AssignStmtContext *>(ctx))
        return std::make_unique<AssignS>(buildLvalue(c->lvalue()), buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::OutputStmtContext *>(ctx))
        return std::make_unique<OutputS>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::IfStmtContext *>(ctx)) {
        std::unique_ptr<Stmt> els;
        if (c->stmt().size() == 2) els = buildStmt(c->stmt(1));
        return std::make_unique<IfS>(buildExpr(c->expr()), buildStmt(c->stmt(0)),
                                     std::move(els));
    }
    if (auto *c = dynamic_cast<TIPParser::WhileStmtContext *>(ctx))
        return std::make_unique<WhileS>(buildExpr(c->expr()), buildStmt(c->stmt()));
    if (auto *c = dynamic_cast<TIPParser::BlockStmtContext *>(ctx)) {
        std::vector<std::unique_ptr<Stmt>> ss;
        for (auto *sc : c->stmt()) ss.push_back(buildStmt(sc));
        return std::make_unique<BlockS>(std::move(ss));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree) {
    return AstBuilder{}.build(tree);
}

}  // namespace tip
```

三处与本章分析有关的细节。

第一处是第 48–98 行的 buildExpr。第 60–71 行把二元运算的三个优先级
（加减、乘除、比较）翻译成统一的 Binop 节点、运算符存进 BOp 枚举——
usesOf 因此只需识别 Binop 一种节点就能覆盖全部六类二元运算，这种
"语法上多形态、AST 上单形态"的翻译大大简化了后续每个分析。第 72–76
行处理负号：TIP 没有负数字面量，`-E` 被显式翻译成 `0-E`，所以分析
永远不会遇到"负的 IntLit"，右值收集到的仍是一次普通二元减法。

第二处是第 100–119 行的 buildStmt。第 105–110 行处理 if 没有 else 的
情形——没有 else 时 els 保持 nullptr。CFG 构造器会为这种 if 补一条
"条件点直穿后继"的边，本章演示程序的 if 正是无 else 形状：输出里
节点 3（if）既有边到节点 4（b=1），也有边直穿到节点 5（output a），
两条路径在节点 5 之前汇合，b 的嫌疑就是沿直穿边带下来的。

第三处是第 29–71 行的 buildFun。第 50–52 行把函数体的语句列表包成
一个 BlockS——每个函数体在 AST 上恒为块，CFG 构造器与符号表解析器
都依赖这个不变量。第 28 行单独构建返回语句，与函数体分开持有，
再次印证 19.5.2 说的编号顺序：体先、return 后。

### 35.5.5 cfg.hpp：数据流分析的载体

AST 是树，树表达不了循环——while 在树上是"条件指向身体"的层次
结构，看不出"身体末尾回到条件"的回边。CFG 把函数体展开成程序点
与边的图，环在图上显式可见，数据流分析因此有了真正的载体。
cfg.hpp 给出节点与函数图的结构。

```cpp
// file: src/cfg.hpp
// 控制流图（CFG, spa 第 2 章）：把函数体从树形语法展开为"程序点 + 边"的图。
// 数据流分析的载体是图而不是树：循环在图上是环，条件在图上是分叉。
#pragma once

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"

namespace tip {

struct CfgNode {
    int id = 0;
    enum class Kind { Entry, Exit, Assign, Output, Branch, Return } kind;
    const Stmt *stmt = nullptr;  // Assign/Output/Branch 指向对应语句
};

struct FunCfg {
    std::string name;
    int entry = -1;
    int exitNode = -1;
    std::map<int, CfgNode> nodes;
    std::vector<std::pair<int, int>> edges;
};

struct Cfg {
    std::vector<FunCfg> funs;
};

Cfg buildCfg(const ProgramA &program);
std::string printCfg(const Cfg &cfg);

}  // namespace tip
```

两个结构值得驻足。

第一处是第 29–33 行的 CfgNode。每个节点除编号外有一个 Kind 标签与
一个可能为空的 stmt 指针：Entry、Exit 是空点；Assign、Output、Branch、
Return 各指向对应语句。本章传递函数的第一步就是查 kind——入口点
取边界值，赋值点走污染规则，其余点恒等。stmt 为 nullptr 的节点
（entry/exit）不可能误触发语句规则，这个表示让"空点"与"语句点"
在类型层面就可区分。

第二处是第 37–52 行的 FunCfg。第 24 行节点用 std::map<int, CfgNode>
持有——节点因此总是按编号有序，分析器按 for 循环遍历节点即是按
编号顺序，输出确定性由此保证。第 25 行边是 pair 列表，构造器会做
去重与排序。记住第 22 行的 entry：本章 worklist 的初始队列与边界
判定都从它出发（恒为编号 1）。

### 35.5.6 cfg.cpp：先编号、再连边

CFG 的构造实现。文件头注释说明了两遍策略的理由：先按 AST 先序给所有
程序点编号（保证编号严格按源码顺序），再回头连边。如果边构造边造
后继节点，后继会抢在前面编号，输出与编号都会失去确定性。

```cpp
// file: src/cfg.cpp
#include "cfg.hpp"

#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"

namespace tip {
namespace {

// 两遍构造：第一遍按 AST 先序给所有程序点分配固定编号；第二遍连边。
// 先编号再连边，是为了让编号严格按源码顺序（连边时若先构造后继节点，
// 后继会抢在前面编号），从而输出与程序点编号都是确定的。
class CfgBuilder {
public:
    explicit CfgBuilder(const ProgramA &program) : program_(program) {}

    Cfg run() {
        Cfg cfg;
        for (const auto &fun : program_.funs) {
            FunCfg fc;
            cur_ = &fc;
            cur_->name = fun->name;
            nextId_ = 1;
            stmtId_.clear();

            const int entry = addNode(CfgNode::Kind::Entry);
            cur_->entry = entry;
            numberStmt(fun->body.get());
            const int retId = addNode(CfgNode::Kind::Return, fun->ret.get());
            const int exitId = addNode(CfgNode::Kind::Exit);
            cur_->exitNode = exitId;

            // 连边：语句构造返回它自己的入口点集合；空块没有节点，直接透传后继。
            std::vector<int> bodyEntries = wireStmt(fun->body.get(), {retId});
            if (bodyEntries.empty()) bodyEntries = {retId};
            link(entry, bodyEntries);
            link(retId, {exitId});

            // set 去重并排序：CFG 边不允许重复，输出顺序固定。
            std::set<std::pair<int, int>> uniq(cur_->edges.begin(), cur_->edges.end());
            cur_->edges.assign(uniq.begin(), uniq.end());
            cfg.funs.push_back(std::move(*cur_));
        }
        return cfg;
    }

private:
    const ProgramA &program_;
    FunCfg *cur_ = nullptr;
    int nextId_ = 1;
    std::map<const Stmt *, int> stmtId_;

    int addNode(CfgNode::Kind kind, const Stmt *stmt = nullptr) {
        const int id = nextId_++;
        cur_->nodes.emplace(id, CfgNode{id, kind, stmt});
        return id;
    }

    // ---- 第一遍：编号 ----
    void numberStmt(const Stmt *s) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            for (const auto &x : b->ss) numberStmt(x.get());
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->then.get());
            numberStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->body.get());
            return;
        }
        if (dynamic_cast<const AssignS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Assign, s);
            return;
        }
        if (dynamic_cast<const OutputS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Output, s);
        }
    }

    // ---- 第二遍：连边。返回进入该语句时首先到达的程序点集合 ----
    std::vector<int> wireStmt(const Stmt *s, const std::vector<int> &succ) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            std::vector<int> cur = succ;
            for (auto it = b->ss.rbegin(); it != b->ss.rend(); ++it)
                cur = wireStmt(it->get(), cur);
            return cur;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            const int n = stmtId_[x];
            std::vector<int> targets = wireStmt(x->then.get(), succ);
            if (targets.empty()) targets = succ;
            if (x->els) {
                std::vector<int> e = wireStmt(x->els.get(), succ);
                if (e.empty()) e = succ;
                targets.insert(targets.end(), e.begin(), e.end());
            } else {
                targets.insert(targets.end(), succ.begin(), succ.end());
            }
            link(n, targets);
            return {n};
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            const int n = stmtId_[x];
            // 循环体执行完回到条件点；空体时条件点连一条自边（等于死循环）。
            std::vector<int> bodyEntries = wireStmt(x->body.get(), {n});
            if (bodyEntries.empty()) bodyEntries = {n};
            link(n, bodyEntries);
            link(n, succ);
            return {n};
        }
        const int n = stmtId_[s];
        link(n, succ);
        return {n};
    }

    void link(int from, const std::vector<int> &to) {
        for (int t : to) cur_->edges.emplace_back(from, t);
    }
};

const char *kindName(CfgNode::Kind kind) {
    switch (kind) {
        case CfgNode::Kind::Entry: return "entry";
        case CfgNode::Kind::Exit: return "exit";
        case CfgNode::Kind::Assign: return "assign";
        case CfgNode::Kind::Output: return "output";
        case CfgNode::Kind::Branch: return "branch";
        case CfgNode::Kind::Return: return "return";
    }
    return "?";
}

}  // namespace

Cfg buildCfg(const ProgramA &program) { return CfgBuilder(program).run(); }

std::string printCfg(const Cfg &cfg) {
    std::ostringstream out;
    for (const FunCfg &f : cfg.funs) {
        out << "== " << f.name << " ==\n";
        out << "nodes:\n";
        for (const auto &[id, node] : f.nodes) {
            out << "  " << id << ": " << kindName(node.kind);
            if (node.stmt) out << "  " << printStmtLine(*node.stmt);
            out << "\n";
        }
        out << "edges:\n";
        for (const auto &[a, b] : f.edges) out << "  " << a << " -> " << b << "\n";
    }
    return out.str();
}

}  // namespace tip
```

这个文件是读懂 35.8 节输出编号的钥匙，四处细节。

第一处是第 28–71 行的 run。第 26 行 nextId_ 从 1 起；第 37–43 行的
顺序是 entry → 函数体 → return → exit。对照本章演示程序：entry=1；
体按源码先序编号 2–9（a=input 是 2、if 条件点是 3、b=1 是 4、
output a 是 5、output b 是 6、c=b 是 7、output c 是 8、return 是 9）；
exit=10。35.8 节输出的左列编号可以逐一对上。

第二处是第 63–86 行的 numberStmt。注意第 68–73 行处理 if 时为条件
建 Branch 节点、然后递归 then 与 els；无 else 时 els 为空、什么都不
递归——这正是节点编号里没有"else 占位点"的原因。第 74–78 行 while
的条件点编号在身体之前，身体递归展开后，回边在第二遍连。

第三处是第 89–122 行的 wireStmt。第 110–118 行 while 最关键：身体的
后继被指定为条件点本身（第 113 行 wireStmt(body, {n})），于是身体
末尾连回 n，回边成形；同时第 116 行条件点连向循环之后的 succ，
循环出口成形。一个条件点因此有两类出边：进身体、出循环。

第四处是第 124–126 行的 link 与第 61–63 行的去重。所有边先收集再
按 set 去重排序——CFG 保证无重边，后继列表里同一节点不会出现两次，
分析器的并集操作因此不需要自己防重复。

最后把多函数的情形提前交代，因为第 37、38 章要反复用到。注意第 26
行 nextId_ 在每个函数开始时重置为 1——节点编号只在函数内唯一：
main 的节点 2 与另一个函数的节点 2 互不相干。本章过程内分析对此无感
（它逐函数跑、状态表也逐函数重建）；但一旦分析要跨函数（第 49 章
起），所有以节点编号为键的状态都必须再带上函数名做第一层分桶，
否则两个函数的同号点会被合并成一个，结论全盘皆错。读者可以现在就
把这条规则记住：**CFG 节点的全局名字是 (函数名, 局部编号)，从来不是
编号本身**。

### 35.5.7 pretty.hpp：AST 的第一个消费者

美化打印器的头文件。它是 AST 的第一个消费者：把程序以固定的前缀式
语法重新打印，供人核对 AST 的结构是否正确。本章只用到它的一个
能力——printStmtLine，警告信息与逐点输出里每条语句后面的文本都由
它产生。

```cpp
// file: src/pretty.hpp
// Pretty-printer：把 AST 以固定的前缀式语法重新打印出来。
// 它是 AST 的第一个消费者，也为后续各章提供"程序结构可视化"的通用工具。
#pragma once

#include <string>

#include "ast.hpp"

namespace tip {

std::string printExpr(const Expr *e);
std::string printProgram(const ProgramA &program);

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printStmtLine(const Stmt &stmt);

}  // namespace tip
```

头文件虽短，有一个设计决定值得注意：printExpr 与 printStmtLine 都以
const 指针/引用接收，打印器不修改树。这确立了一条贯穿全书的惯例：
**所有分析与展示工具都在 const AST 上工作**。分析可以保存指向节点
的裸指针、可以把语句文本拼进输出，但从不改动树——这使得多个分析
可以先后在同一棵树上运行而互不干扰（第 35.8 节总表打印之后若再加
一个分析，树依然原封不动）。

### 35.5.8 pretty.cpp：前缀式的固定语法

pretty.hpp 的实现。表达式打印为 `(op left right)` 的前缀形式，语句
带缩进打印。本章输出里 if 的文本是 `if ((> a 0))` 跨多行显示——
正是 printStmtLine 调用 stmtText 时保留的换行；警告收集时语句文本
也带着这个形状。

```cpp
// file: src/pretty.cpp
#include "pretty.hpp"

#include <string>

namespace tip {

namespace {

// 表达式打印为前缀式：运算符与符号的对照表。
std::string exprText(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return std::to_string(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) return x->name;
    if (dynamic_cast<const InputE *>(e)) return "input";
    if (dynamic_cast<const NullE *>(e)) return "null";

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const char *sym = "+";
        switch (x->op) {
            case BOp::Add: sym = "+"; break;
            case BOp::Sub: sym = "-"; break;
            case BOp::Mul: sym = "*"; break;
            case BOp::Div: sym = "/"; break;
            case BOp::Gt: sym = ">"; break;
            case BOp::Eq: sym = "=="; break;
        }
        return "(" + std::string(sym) + " " + exprText(x->l.get()) + " " +
               exprText(x->r.get()) + ")";
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        std::string s = "(call " + exprText(x->callee.get());
        for (const auto &a : x->args) s += " " + exprText(a.get());
        return s + ")";
    }
    if (const auto *x = dynamic_cast<const Deref *>(e))
        return "(* " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const AddrOf *>(e)) return "(& " + x->name + ")";
    if (const auto *x = dynamic_cast<const AllocE *>(e))
        return "(alloc " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const FieldA *>(e))
        return "(. " + exprText(x->e.get()) + " " + x->field + ")";
    if (const auto *x = dynamic_cast<const RecLit *>(e)) {
        std::string s = "{";
        for (size_t i = 0; i < x->fields.size(); ++i) {
            if (i) s += ", ";
            s += x->fields[i].first + ": " + exprText(x->fields[i].second.get());
        }
        return s + "}";
    }
    return "<unknown expr>";
}

std::string indent(int level) { return std::string(static_cast<size_t>(level) * 2, ' '); }

// 语句打印带缩进，一条语句一行（块内多行）。
void stmtText(const Stmt *s, int level, std::string &out) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        out += indent(level) + exprText(x->target.get()) + " = " +
               exprText(x->value.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        out += indent(level) + "output " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
        out += indent(level) + "return " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        out += indent(level) + "if (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->then.get(), level + 1, out);
        if (x->els) {
            out += indent(level) + "else\n";
            stmtText(x->els.get(), level + 1, out);
        }
        return;
    }
    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        out += indent(level) + "while (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->body.get(), level + 1, out);
        return;
    }
    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        out += indent(level) + "{\n";
        for (const auto &st : x->ss) stmtText(st.get(), level + 1, out);
        out += indent(level) + "}\n";
        return;
    }
    out += indent(level) + "<unknown stmt>\n";
}

}  // namespace

std::string printExpr(const Expr *e) { return exprText(e); }

std::string printProgram(const ProgramA &program) {
    std::string out;
    for (const auto &f : program.funs) {
        std::string paramList;
        for (size_t i = 0; i < f->params.size(); ++i) {
            if (i) paramList += ",";
            paramList += f->params[i];
        }
        out += f->name + "(" + paramList + ") {\n";
        if (!f->vars.empty()) {
            out += indent(1) + "var ";
            for (size_t i = 0; i < f->vars.size(); ++i) {
                if (i) out += ",";
                out += f->vars[i];
            }
            out += " ;\n";
        }
        // 函数体是 BlockS；打印其内部语句而不是再嵌一层花括号。
        const auto *body = dynamic_cast<const BlockS *>(f->body.get());
        for (const auto &st : body->ss) stmtText(st.get(), 1, out);
        stmtText(f->ret.get(), 1, out);
        out += "}\n";
    }
    return out;
}

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printStmtLine(const Stmt &stmt) {
    std::string out;
    stmtText(&stmt, 0, out);
    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
}

}  // namespace tip
```

三处与输出直接相关的细节。

第一处是第 14–64 行的 exprText。第 31–54 行六类二元运算共用一段
包装：运算符字符按 BOp 查表，左右递归。输出里 a>0 显示成
`(> a 0)`、a=input 显示成 `a = input`，读 35.8 节时对照这个前缀
形式就不会把 `(> a 0)` 误读成奇怪的表达式。

第二处是第 55–90 行的 stmtText。第 69–77 行 if 打印为条件行加缩进的
then 与可选 else；本章演示程序的 if 无 else，输出里节点 3 之后直接
跟着 `{ b = 1 ; }` 两行，就是这里产生的形状。printStmtLine 在第 123–
128 行去掉末尾换行，让单行场景干净。

第三处是第 96–120 行的 printProgram。它在本章没有被调用（本章只按
节点打印语句），但理解它有助于读懂编号：第 114 行取函数体 BlockS
后直接遍历内部语句、不再嵌一层花括号——与 CFG "体先于 return" 的
处理同构。整个打印器无状态、纯函数式：同一段 AST 永远打印同一串
文本，expected 输出因此可以稳定复现。

### 35.5.9 symtab.hpp：名字从哪里来

符号表头文件。名字解析把每个 VarRef 绑定到它的声明（函数、参数或
局部变量），并产出未声明、重复声明的诊断。本章分析虽然只按变量名
字符串工作（集合里存的是名字），但仍然依赖名字解析这一环：未声明
的程序在语义分析处直接拒绝，不会带着悬空名字进入数据流分析。

```cpp
// file: src/symtab.hpp
// 符号表与名字解析：把 AST 上的每个 VarRef 绑定到它的声明
// （函数 / 参数 / 局部变量），同时产出未声明、重复声明诊断。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Symbol {
    enum Kind { Fun, Param, Local } kind;
    std::string name;
    const FunDecl *fun;          // Fun: 指向自身声明; Param/Local: 指向所属函数
};

struct Scope {
    Scope *parent;
    std::map<std::string, Symbol> table;

    explicit Scope(Scope *p = nullptr) : parent(p) {}
    const Symbol *lookup(const std::string &name) const;
};

struct Diag {
    std::string text;
};

struct Bindings {
    Scope global;                                  // 函数名所在的全局作用域
    // 各函数作用域由 Bindings 持有所有权：uses 中的 Symbol* 才不会悬垂。
    std::vector<std::unique_ptr<Scope>> scopes;
    std::vector<Diag> errors;
    std::map<const VarRef *, const Symbol *> uses;  // 解析成功的使用点
};

// 两遍解析：先注册全部函数名（支持前向调用），再逐函数解析函数体。
Bindings resolveNames(ProgramA &program);

}  // namespace tip
```

两个结构值得驻足。

第一处是第 28–32 行的 Symbol。它携带种类、名字与所属函数指针——
名字解析的产物比本章需要的丰富，uses 表（第 36 行）精确记录每个
使用点指向哪个声明。本章的传递函数按字符串集合操作，没有直接消费
这些绑定；但请设想反过来：如果分析要区分"嫌疑来自参数还是局部"，
绑定信息已经现成，只需在环境上换一种键。这就是把前端做厚、把分析
做薄的好处。

第二处是第 35–51 行的 Scope。词法作用域以父指针串成链，lookup
沿链回溯——函数名在全局作用域，参数与局部在函数作用域。第 39–49
行 Bindings 持有全部作用域的所有权，uses 中的裸指针因此不会在解析
结束后悬垂。所有权设计与 AST 如出一辙：谁产出节点，谁负责让它们
活得比消费者久。

### 35.5.10 symtab.cpp：两遍解析

符号表的实现。resolveNames 分两遍：先把全部函数名注册进全局作用域
（这样函数可以前向互相调用），再逐函数开作用域、登记形参与局部、
遍历函数体解析使用点。

```cpp
// file: src/symtab.cpp
#include "symtab.hpp"

#include <utility>

namespace tip {

namespace {

// 解析器在遍历 AST 的同时完成绑定与诊断收集。
struct Resolver {
    Bindings bindings;
    Scope *current = nullptr;
    const FunDecl *owner = nullptr;

    void declare(const std::string &name, Symbol::Kind kind) {
        if (current->table.count(name)) {
            bindings.errors.push_back({"error: redeclared '" + name + "'"});
            return;  // 保留先声明者，后声明被忽略
        }
        current->table.emplace(name, Symbol{kind, name, owner});
    }

    void resolveExpr(const Expr *e) {
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            const Symbol *s = current->lookup(x->name);
            if (!s) {
                bindings.errors.push_back({"error: undeclared '" + x->name + "'"});
            } else {
                bindings.uses[x] = s;
            }
            return;
        }
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            resolveExpr(x->l.get());
            resolveExpr(x->r.get());
            return;
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            resolveExpr(x->callee.get());
            for (const auto &a : x->args) resolveExpr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const AllocE *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            resolveExpr(x->e.get());  // 字段名不是变量，无需解析
            return;
        }
        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &f : x->fields) resolveExpr(f.second.get());
            return;
        }
        // IntLit / InputE / AddrOf / NullE：无变量使用。
    }

    void resolveStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            resolveExpr(x->target.get());
            resolveExpr(x->value.get());
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->then.get());
            if (x->els) resolveStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) resolveStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) return resolveExpr(x->e.get());
    }
};

}  // namespace

const Symbol *Scope::lookup(const std::string &name) const {
    auto it = table.find(name);
    if (it != table.end()) return &it->second;
    return parent ? parent->lookup(name) : nullptr;
}

Bindings resolveNames(ProgramA &program) {
    Resolver resolver;
    resolver.bindings.global = Scope(nullptr);
    Scope *global = &resolver.bindings.global;

    // 第一遍：所有函数名进入全局作用域。
    for (const auto &f : program.funs) {
        if (global->table.count(f->name)) {
            resolver.bindings.errors.push_back({"error: redeclared '" + f->name + "'"});
            continue;
        }
        global->table.emplace(f->name, Symbol{Symbol::Fun, f->name, f.get()});
    }

    // 第二遍：每个函数开自己的作用域，父作用域是全局表；
    // 作用域所有权交给 Bindings，遍历结束后符号依然存活。
    for (const auto &f : program.funs) {
        auto functionScope = std::make_unique<Scope>(global);
        resolver.current = functionScope.get();
        resolver.owner = f.get();

        for (const std::string &p : f->params) resolver.declare(p, Symbol::Param);
        for (const std::string &v : f->vars) resolver.declare(v, Symbol::Local);

        resolver.resolveStmt(f->body.get());
        resolver.resolveStmt(f->ret.get());

        resolver.current = nullptr;
        resolver.bindings.scopes.push_back(std::move(functionScope));
    }
    return std::move(resolver.bindings);
}

}  // namespace tip
```

三处与本章流水线有关的细节。

第一处是第 90–102 行的第一遍。所有函数先注册——main 调用的函数无论
定义先后都找得到。对本章分析更重要的是副作用：函数名与变量名共享
同一个标识符词法，但存在不同作用域，所以函数体内若有与函数同名的
局部变量并不冲突；本章的嫌疑集合只装变量，函数名永远不会混进来。

第二处是第 106–119 行的第二遍。第 111–112 行形参、局部的登记顺序
与 FunDecl 中的列表一致；第 114–115 行函数体与返回语句分别遍历——
ret 不在 body 里，解析器必须记得单独遍历它，否则返回表达式中的
变量使用会漏绑。init.cpp 里 stmtUses 覆盖 ReturnS，与此处的分别
遍历互相呼应。

第三处是第 30–71 行的 resolveExpr。注意第 53 行注释列出的
IntLit/InputE/AddrOf/NullE 无变量使用——这与 usesOf 的基例完全
一致。两个函数（一个为名字绑定服务、一个为污染判定服务）对"什么
表达式读变量"给出同一个答案并非巧合：它们实现的是同一个语言事实
的两个投影，任何一边漏了一种节点，另一边的正确性都会打折扣。

## 35.6 本章新增：init.hpp 与 init.cpp

十个复用文件过完，本节进入本章唯一的新代码。文件命名为 init，取
"initialized"之意：它实现 19.3 五元组的全部内容——幂集格上的前向
may 分析、边界条件、状态依赖传递函数，以及求完不动点后的警告收集。
头文件先给出数据形状，实现文件再给出 worklist 算法。请读者把
19.3.1 的方程组放在手边：in(n)=并前驱、out(n)=F_n(in(n))，接下来
会看到这两行如何逐字落成代码。

### 35.6.1 init.hpp：分析结果的形状

先嵌入头文件。InitResult 把分析产物分成三块：每个程序点的流入状态
inState、流出状态 outState，以及警告列表。两个状态都以节点编号为键、
以"可能未初始化变量名集合"为值；这正是 19.3 幂集格元素的直接表示
——std::set<std::string>，序就是 std::includes 意义下的子集，并集
就是 insert 全部元素。

```cpp
// file: src/init.hpp
// 第 35 章配套：可能未初始化分析（spa 9.1 的经典例子，作为"传递函数"一节的落地）。
// 与第 33 章 gen/kill 框架的关键差别：这里的传递函数依赖状态本身——
// "c = b" 当 b 可能未初始化时 c 也必须标记为可能未初始化（污染沿数据流传播）。
// 因此本章手写 worklist 求解器，并保存每个点的流入状态供警告定位使用。
#pragma once

#include <map>
#include <set>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

struct InitResult {
    // 程序点 → 流入/流出的"可能未初始化变量"集合（前向 may，幂集格）。
    std::map<int, std::set<std::string>> inState;
    std::map<int, std::set<std::string>> outState;
    // 不动点求完之后统一收集的 use-before-init 警告。
    std::vector<std::string> warnings;
};

InitResult runInitAnalysis(const Cfg &cfg, const ProgramA &program);

std::string printInit(const Cfg &cfg, const ProgramA &program,
                      const InitResult &r);

}  // namespace tip
```

三处设计决定值得驻足。

第一处是为什么同时保存 in 与 out 两份状态。worklist 迭代真正反复
读写的只是 out——in 每次都由前驱 out 现算。但警告判定必须在 in 上：
"读取一个到达时可能未初始化的变量"，规则读的是语句执行**之前**的
状态。若只存 out，第 105 行 `res.inState[p] = in` 这一步记下的信息
就要么丢失、要么从 out 反推（赋值点的 out 已被覆写改写，反推不可行）。
用一点内存换掉一次反推，而且让打印输出同时呈现两个状态供教学核对，
是值得的。

第二处是第 25 行 runInitAnalysis 同时接收 cfg 与 program。CFG 提供
点与边，program 提供函数声明——边界条件"声明变量减参数"在 AST 的
FunDecl 上，不在 CFG 上。两个来源缺一不可，这也再次说明 CFG 不是
程序的完整压缩，它只保留了流，声明信息仍要回 AST 查。

第三处是第 27 行 printInit 的 program 参数在实现里未使用（以注释
形参名消警告）。打印逐点状态只需要 CFG 与结果；保留参数是为了与
其他章节打印函数签名一致——调用点全部统一成 print(cfg, program, ...)
的形状，读者在不同章节间切换时没有意外。

### 35.6.2 init.cpp（上）：变量收集与边界条件

实现文件较长，分三段讲。先嵌入全文，随后按"辅助收集—边界—worklist—
警告"的顺序逐段交代。

```cpp
// file: src/init.cpp
#include "init.hpp"

#include <algorithm>
#include <deque>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

// 表达式中出现的变量（与第 33 章的 exprVars 同型，本章自带一份以保持自包含）。
std::set<std::string> usesOf(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        r.insert(x->name);
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = usesOf(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = usesOf(x->r.get());
        r.insert(rr.begin(), rr.end());
    } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
        for (const auto &a : x->args) {
            std::set<std::string> s = usesOf(a.get());
            r.insert(s.begin(), s.end());
        }
    }
    return r;  // IntLit/InputE 不读变量
}

// 语句读取了哪些变量（警告定位用：赋值看右值，输出/返回看表达式，分支看条件）。
std::set<std::string> stmtUses(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s))
        return usesOf(a->value.get());
    if (const auto *o = dynamic_cast<const OutputS *>(s)) return usesOf(o->e.get());
    if (const auto *r = dynamic_cast<const ReturnS *>(s)) return usesOf(r->e.get());
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return usesOf(w->cond.get());
    if (const auto *i = dynamic_cast<const IfS *>(s)) return usesOf(i->cond.get());
    return {};
}

std::string joinSet(const std::set<std::string> &s) {
    if (s.empty()) return "{}";
    std::ostringstream out;
    out << "{";
    bool first = true;
    for (const std::string &v : s) {
        if (!first) out << ",";
        out << v;
        first = false;
    }
    out << "}";
    return out.str();
}

}  // namespace

InitResult runInitAnalysis(const Cfg &cfg, const ProgramA &program) {
    InitResult res;

    // 每个函数的边界条件：声明的局部变量出发时"可能未初始化"，
    // 参数视为已初始化（调用方必然提供实参），所以不在集合里。
    std::map<const FunCfg *, std::set<std::string>> entryState;
    for (size_t i = 0; i < cfg.funs.size(); ++i) {
        const FunCfg &fc = cfg.funs[i];
        const FunDecl &fd = *program.funs[i];
        std::set<std::string> s(fd.vars.begin(), fd.vars.end());
        for (const std::string &p : fd.params) s.erase(p);
        entryState[&fc] = s;
    }

    for (const FunCfg &fc : cfg.funs) {
        // 邻接表：succ[p] = 前向流后继。
        std::map<int, std::vector<int>> preds, succs;
        for (const auto &[a, b] : fc.edges) {
            preds[b].push_back(a);
            succs[a].push_back(b);
        }

        // worklist 不动点：may 分析从空集出发，边界点带函数入口状态。
        std::map<int, std::set<std::string>> out;
        std::deque<int> wl;
        std::set<int> inQ;
        for (const auto &[id, node] : fc.nodes) {
            wl.push_back(id);
            inQ.insert(id);
        }
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            inQ.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            // 流入 = 各前驱流出状态之并（may）；无前驱时边界 = 入口状态。
            std::set<std::string> in;
            auto pit = preds.find(p);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    const std::set<std::string> &qs = out[q];
                    in.insert(qs.begin(), qs.end());
                }
            } else {
                in = entryState[&fc];
            }
            res.inState[p] = in;

            // 传递函数：赋值 x = e 时 (S ∖ {x}) ∪ ({x} 若 e 读到 S 中变量)；
            // 其余语句原样传递。
            std::set<std::string> o = in;
            if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
                if (const auto *t = dynamic_cast<const VarRef *>(a->target.get())) {
                    o.erase(t->name);
                    std::set<std::string> rhs = usesOf(a->value.get());
                    for (const std::string &v : rhs)
                        if (in.count(v)) {
                            o.insert(t->name);  // 污染：右值可能未初始化
                            break;
                        }
                }
            out[p] = o;

            // 状态变化才重算后继（单调保证有界）。
            auto prev = res.outState.find(p);
            if (prev == res.outState.end() || prev->second != o) {
                res.outState[p] = o;
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int q : sit->second)
                        if (!inQ.count(q)) {
                            wl.push_back(q);
                            inQ.insert(q);
                        }
            }
        }

        // 不动点之后统一收集警告：语句读取的任何变量 ∈ 流入状态即为
        // "存在一条路径先读后写"。
        for (const auto &[id, node] : fc.nodes) {
            if (!node.stmt) continue;
            std::set<std::string> uses = stmtUses(node.stmt);
            std::set<std::string> bad;
            for (const std::string &v : uses)
                if (res.inState[id].count(v)) bad.insert(v);
            if (bad.empty()) continue;
            std::ostringstream w;
            w << "node " << id << ": " << printStmtLine(*node.stmt)
              << "  possibly uninitialized:";
            for (const std::string &v : bad) w << " " << v;
            res.warnings.push_back(w.str());
        }
    }
    return res;
}

std::string printInit(const Cfg &cfg, const ProgramA & /*program*/,
                      const InitResult &r) {
    std::ostringstream out;
    out << "== possibly-uninitialized (forward, may) ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt)
                out << " " << printStmtLine(*node.stmt);
            out << ": in " << joinSet(r.inState.at(id))
                << " out " << joinSet(r.outState.at(id)) << "\n";
        }
    }
    out << "-- warnings --\n";
    if (r.warnings.empty()) {
        out << "  (none)\n";
    } else {
        for (const std::string &w : r.warnings) out << "  " << w << "\n";
    }
    return out.str();
}

}  // namespace tip
```

第一段是第 17–71 行的两个收集函数，它们实现传递函数需要的全部
"语法查询"。

usesOf（第 28–70 行）收集表达式读取的变量。三个分支对应三类有结构
的表达式：VarRef 收一个名字；Binop 递归左右后合并；CallE 不把被调
函数名算作变量读取（它在全局作用域），但递归收集所有实参——实参
若读到嫌疑变量，调用语句本身同样处在危险区域。基例 IntLit 与
InputE 返回空集：input 产生一个新值，不读任何变量，因此 `a = input`
一句之后 a 的嫌疑被无条件洗掉，这与具体语义一致——input 语句必定
返回一个值。

stmtUses（第 40–52 行）把语句翻译成它读取的变量集合，五个分支
逐句首注释里已经点名：赋值看右值（目标不算读取——赋值是写）、
输出与返回看整表达式、while 与 if 看条件。这个函数只在警告收集时
使用，但它与传递函数内联调用的 usesOf 共享同一套语义，19.4.6 的
"每个加入动作都被路径收账"靠的就是两处口径一致。

joinSet（第 51–71 行）是集合的文本化，输出里 `{a,b,c}` 的花括号与
逗号由它产生；空集打印成 `{}`。它不参与分析逻辑，只是让输出确定。

第二段是第 58–70 行的边界条件构造。第 67 行从 fd.vars 拷贝出声明
变量集合，第 68 行逐一 erase 形参——19.2.4 的集合差逐字落在这里。
注意第 69–71 行假定 cfg.funs[i] 与 program.funs[i] 按相同顺序排列：
两个文件都按程序中的声明顺序构造函数，这是流水线建立以来的不变量；
靠下标配对比靠名字查表脆弱，本章为省一次查表用了下标，并在此显式
注明前提。

### 35.6.3 init.cpp（下）：worklist 与警告收集

第三段是第 72–134 行的 worklist 主循环，第 31 章的纪律在这里完整
重演，但请注意一个初始化上的差别。

第 84–87 行把全部节点先放进队列：不是只放入口。这样写的原因是边界
判定走"无前驱即边界"的路径——entry 之外，若还有其他无前驱节点
（本例没有，但循环外的多入口结构理论上可能），它们同样需要按边界
处理，全节点入队保证一个都不漏。第一轮遍历等价于一轮混沌初始化，
之后严格按变化传播，与第 31 章从入口起步的算法在结果上一致，多花
的只是第一轮的常数代价。

第 95–104 行计算流入状态：有前驱则取前驱 out 之并，第 99–100 行直接
把集合元素 insert 进来——may 的合并就是集合并，一个字符都不多。
没有前驱时取该函数的边界状态（第 103 行）。第 105 行把 in 存进结果，
这是警告与打印的依据。

第 109–120 行是状态依赖传递函数的真身，建议逐字符对照 19.2.2 的
规则。第 112 行先 erase 目标——第一步 S∖{x}；第 113 行求右值读取的
变量；第 114–118 行逐个检查，只要右值中有一个变量落在 in 集合里，
就把目标 insert 回来并立刻 break——"任何一个"正是 may 语义，找到
第一个就足够。读到这里请回头看 19.2.2 末尾"先杀后染"的说法：
第 112 行杀、第 116 行染，两步在代码里同样清晰。

第 123–133 行是变化守卫：新 out 与旧 outState 不同才写回并把后继入队，
inQ 防止同一节点在队列里重复。单调性（19.2.2 已证）保证每次变化都
是集合严格变大、变大次数受 |Vars|+1 限制——终止性不是靠运气。

第四段是第 138–150 行的警告收集，放在不动点求完之后统一做。第 140
行取语句读取的变量，第 142–143 行逐个问它是否在该点 in 集合中；
命中的收进 bad，第 146–149 行拼成固定格式：
`node N: 语句文本  possibly uninitialized: 变量...`。警告在全部状态
稳定之后才收集，杜绝了"早报警、状态后来又变了"的时序问题。

第 155–176 行的 printInit 是输出格式化：逐函数、逐节点打印 in/out，
再附警告段。它只做拼装，不含任何分析判断——分析逻辑与展示逻辑的
分离让 expected 输出的每一行都能回指到前面某一处具体代码。

### 35.6.4 求解器有意不做的三件事

讲完代码做什么，同样有价值的是点明它有意**不做**什么——这些缺口
不是疏漏，而是边界划分，提前说清能避免读者在后续章节里找错位置。

第一，它不做分支条件精炼。节点 3 的条件 `a>0` 在真边、假边上携带
不同的事实（真边可知 a>0），但本分析的事实语言里只有"变量是否
可能未初始化"，条件的真假不改变这种事实——无论 a>0 与否，未赋值
的 b 都还是未赋值。条件精炼是第 39 章区间分析的武器；对本分析，
沿真假边分流不会带来任何更精确的嫌疑集合，徒增状态。分析只该
携带它的格能表达的信息，这是选择五元组第一空时就要想清楚的。

第二，它不跨函数。调用在本章的 usesOf 里只递归实参，被调函数的
体完全不可见——因此一个在被调函数内部完成的赋值，本章无法用来
洗清实参之外任何变量的嫌疑。这是第 37、38 章的主题；本章的位置
是过程内基线：先把单函数的 MFP 与警告做到可对账，过程间分析才有
可对照的起点。

第三，它不区分嫌疑的"强弱"。集合论的事实只有在与不在：b 一次
未初始化与 b 在十条路径里九条未初始化，在幂集格里是同一个成员。
这种区分需要概率或比例的域，超出 may 分析的承诺；本分析回答的
问题从来只是"是否存在一条路径"，不是"有多大概率"。把问题的
形态与格的表达力对齐，是填五元组时反复出现的主题——格选得比
问题丰富则浪费，选得比问题贫乏则结论变形。

## 35.7 总装：main.cpp

所有部件齐备，最后看流水线如何在 main.cpp 里串起来。本章 main 的
结构与前几章同型：参数解析、parseFile、buildCfg、调用分析、打印，
外加一段本章特有的五元组文本与分类总表。先嵌入全文。

```cpp
// file: src/main.cpp
// 第 35 章配套程序：可能未初始化分析 + 单调框架五元组/分类总表输出。
//   --check FILE : 打印各程序点可能未初始化集合、use-before-init 警告，
//                  以及本分析在 MonotoneFramework 五元组下的形式化描述
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "init.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
    }
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);

    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);

    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

// 第 31–35 章所有分析按五元组（格、方向、边界、初值、传递函数族）归位。
// 一张总表看懂"同一个 worklist 引擎为什么能跑出七种分析"。
void printFrameworkTable() {
    std::cout <<
        "== monotone framework classification (chapters 16-19) ==\n"
        "analysis         direction merge boundary            transfer\n"
        "sign lattice     forward   join  entry: params=TOP   abstract arith tables\n"
        "constant (flat)  forward   join  entry: params=TOP   constant folding\n"
        "live variables   backward  union exit: {}            gen/kill\n"
        "reaching defs    forward   union entry: {}           gen/kill\n"
        "available exprs  forward   inter entry: {}           gen/kill\n"
        "very busy exprs  backward  inter exit: {}            gen/kill\n"
        "possibly-uninit  forward   union entry: decls\\params state-dependent\n";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    Parsed p = parseFile(argv[2]);
    tip::Cfg cfg = tip::buildCfg(*p.ast);

    tip::InitResult r = tip::runInitAnalysis(cfg, *p.ast);
    std::cout << tip::printInit(cfg, *p.ast, r);

    std::cout <<
        "-- monotone framework (five-tuple), possibly-uninitialized --\n"
        "  lattice  : powerset of program variables, order = subset,\n"
        "             join = union, bottom = {}\n"
        "  direction: forward\n"
        "  boundary : entry(f) = declared vars \\ params (params arrive initialized)\n"
        "  init     : every other point starts at bottom {}\n"
        "  transfer : x = e  ->  (S \\ {x}) plus {x} if e reads a variable in S\n"
        "             others ->  S\n"
        "  theorem  : all transfer functions are monotone, so the worklist least\n"
        "             fixpoint approximates merge-over-paths; every reported\n"
        "             use-before-init occurs on at least one real execution path.\n";

    printFrameworkTable();
    return 0;
}
```

四处值得交代。

第一处是第 18–69 行的 CollectErrorListener 与 parseFile，这是从第 12 章起逐章复制的前端样板：ANTLR 流上挂自定义错误收集器，语法错走
退出码 2；buildAst 之后 resolveNames，语义错走退出码 3。退出码约定
（0 成功、1 用法/文件、2 语法、3 语义）让脚本可以只凭返回码判断
失败层次，run-all 脚本与 check_example 都依赖它。

第二处是第 88–92 行的参数门。本章只支持 --check 单一模式，参数个数
不对立刻打印用法并返回 1——在解析任何文件之前拒绝，避免半执行状态。

第三处是第 94–98 行的主干，整个流水线压成四行：解析、构造 CFG、
runInitAnalysis、printInit。请特别注意 runInitAnalysis 是一个纯函数：
输入 CFG 与 AST，输出 InitResult，不修改任何输入、不持有全局状态、
不依赖执行环境。这意味着想再加一个分析，复制这一行换成另一个纯
函数即可——19.8.5 总表的七行在工程上对应的就是七个这样的纯函数。

第四处是第 100–113 行的两段静态文本与 printFrameworkTable。五元组
描述（第 100–111 行）是 19.3.1 五道空的英文打印版，与中文正文逐行
对应；第 73–84 行 printFrameworkTable 内联了七行分类总表，空格对齐
是手工排过的——列宽按最长的分析名与边界描述预留，读者若新增一行
需要保持同样的列起始位置。总表放在最后打印，作为全章输出的收束。

再从测试者的角度看这个文件，它天然具备可回归性，有三个特征值得在
自己的工程中模仿。其一，全部输入来自命令行指定的文件，不依赖当前
工作目录之外的环境——同一条命令在任何目录、任何时间跑出同样结果，
回归脚本因此不需要准备运行环境。其二，退出码语义分层固定：成功 0、
用法错误 1、语法 2、语义 3——CI 可以按码区分"程序写错了"与
"工具自己坏了"，两者的处置完全不同。其三，分析与输出之间没有
隐藏状态：第二次调用 runInitAnalysis 拿到与第一次逐字节相同的结果，
回归可以重复运行任意次而互不污染。可测试性不是事后加出来的，它是
纯函数流水线的自然属性；写 main 时把这三点当作约束，测试几乎免费。

## 35.8 真实输出逐行解读

理论、五元组、代码都过完了，本节把程序与真实执行的输出并排摆在
桌上逐行读。先嵌入演示程序——它短到可以一眼看全：一个 input、一个
无 else 的 if、三次 output，加上一句关键的 `c = b`。

```cpp
// file: programs/init.tip
main() {
  var a, b, c;
  a = input;
  if (a > 0) {
    b = 1;
  }
  output a;
  output b;
  c = b;
  output c;
  return 0;
}
```

读这个程序时先在脑中走两条路径。a>0 为真时：b 在第 5 行被赋值，
此后 output b 读到 1、c=b 读到 1、output c 读到 1，一切正常。a>0
为假时：if 的身体被跳过，b 从未出现于任何赋值左边——output b 读
到一个不存在的值，c=b 把这个"不存在"抄给 c，output c 同样危险。
分析要回答的全部问题就是：静态地把两条路径合并，哪些点该举牌？

下面嵌入完整输出。它由 `tipa --check programs/init.tip` 产生、
原样保存在 expected/output.txt 中，check_example 每次回归都会重跑
并逐字节比对。

```text
; expected: expected/output.txt
== init.tip ==
== possibly-uninitialized (forward, may) ==
-- main --
  1: in {a,b,c} out {a,b,c}
  2 a = input ;: in {a,b,c} out {b,c}
  3 if ((> a 0))
  {
    b = 1 ;
  }: in {b,c} out {b,c}
  4 b = 1 ;: in {b,c} out {c}
  5 output a ;: in {b,c} out {b,c}
  6 output b ;: in {b,c} out {b,c}
  7 c = b ;: in {b,c} out {b,c}
  8 output c ;: in {b,c} out {b,c}
  9 return 0 ;: in {b,c} out {b,c}
  10: in {b,c} out {b,c}
-- warnings --
  node 6: output b ;  possibly uninitialized: b
  node 7: c = b ;  possibly uninitialized: b
  node 8: output c ;  possibly uninitialized: c
-- monotone framework (five-tuple), possibly-uninitialized --
  lattice  : powerset of program variables, order = subset,
             join = union, bottom = {}
  direction: forward
  boundary : entry(f) = declared vars \ params (params arrive initialized)
  init     : every other point starts at bottom {}
  transfer : x = e  ->  (S \ {x}) plus {x} if e reads a variable in S
             others ->  S
  theorem  : all transfer functions are monotone, so the worklist least
             fixpoint approximates merge-over-paths; every reported
             use-before-init occurs on at least one real execution path.
== monotone framework classification (chapters 16-19) ==
analysis         direction merge boundary            transfer
sign lattice     forward   join  entry: params=TOP   abstract arith tables
constant (flat)  forward   join  entry: params=TOP   constant folding
live variables   backward  union exit: {}            gen/kill
reaching defs    forward   union entry: {}           gen/kill
available exprs  forward   inter entry: {}           gen/kill
very busy exprs  backward  inter exit: {}            gen/kill
possibly-uninit  forward   union entry: decls\params state-dependent
```

### 35.8.1 逐点状态：合并在何处发生

输出第 3–16 行是 main 的逐点 in/out，对照 19.5.6 的编号表逐行读。

节点 1（entry）：in 与 out 都是 {a,b,c}——边界条件 19.2.4：三个声明
变量全部带着嫌疑，main 无参数，集合差之后一个都没去掉。入口是
起点，它的 in 不是并前驱算来的，而是直接赋边界值；out 不经语句
传递，原样。

节点 2（a = input）：in {a,b,c}，out {b,c}——右值 input 不读变量，
传递函数执行第一步删掉 a、第二步的条件不成立（vars(e)=∅），a 的
嫌疑被洗净。这是输出里唯一一个集合缩小的赋值，请与节点 7 对照。

节点 3（if 条件点）：in/out 都是 {b,c}。条件 `a>0` 读取 a，而 a 不在
嫌疑集合——条件本身安全；分支语句不改变状态，原样透传。注意图上
从节点 3 有两条边：到节点 4（条件真）和直穿节点 5（条件假）。

节点 4（b = 1）：in {b,c}、out {c}——常量右值不读变量，b 的嫌疑被
洗净。但这只是**条件真那条路径**上的状态；关键在汇合点。

节点 5（output a）：in {b,c}。它的前驱有两个：节点 4（真路，out {c}）
与节点 3（假路，out {b,c}）——并集是 {b,c}。看，b 的嫌疑正是经
"跳过 if"的假路穿过汇合点活下来的：真路洗了 b，假路没洗，may
合并取并，嫌疑不灭。output a 本身只读 a（安全），状态原样。

节点 6–8：{b,c} 一路不变。节点 6 output b 读取 b——警告点；节点 7
c=b 是全章的戏眼：in {b,c}，右值读到 in 中的 b，传递函数先删 c 再
把 c 染回来，out 仍是 {b,c}，与 19.2.2"相互抵消"的预言一字不差；
节点 8 output c 读取 c——c 的嫌疑是从节点 7 新得来的。

节点 9（return 0）与节点 10（exit）：{b,c} 原样带到出口。返回常量
零不读嫌疑变量；出口状态不再被使用，但打印它让数据流的终点可见。

### 35.8.2 状态表的另一种读法：不变量核对

逐点表还可以倒过来读——把它当作正确性不变量的实例核对，19.4 的
三条定理在每一行都应当成立。

核对"不凭空"：任取集合中一个变量，沿前驱回追，最终必停在边界
集合 {a,b,c} 上。比如节点 8 in 中的 c：前驱节点 7 的 out 有 c，节点
7 的 c 是从 in 中 b 的污染来的，b 又从节点 6、5 一路回追到汇合点，
汇合点的 b 来自节点 3 的假路，节点 3 的 b 直追到入口边界。链条
完整，没有一环是机器自己加的——这正是 19.4.4"每个成员能落到
一条具体路径"的手工验证。

核对"不丢失"：任取一条路径，沿路径写下传递结果，终点状态应是
表中状态的子集。假路（1→2→3→5→6→7→8）逐点得到
{b,c}→{b,c}→{b,c}→...，全部被表中状态包含；真路经过节点 4 时
b 被洗净，但汇合后重新拿到假路的 b。两条路径各自核对，无一漏网。

核对"单调"：从节点 1 到 10，沿任何边比较状态的子集关系；非赋值
边状态恒等，赋值边只删不染（节点 2）或先删后染（节点 7）——
没有任何一处出现"流入没有、凭空流出"的反转。三条核对全部通过，
表才算是一份可信的不动点而不只是打印输出。

### 35.8.3 三条警告：两类危险，一次传染

输出第 32–37 行是警告段，恰有三条。它们分成两类，分类本身就是
19.4.6 论证的实例。

第一条，`node 6: output b ... possibly uninitialized: b`——直接
读取一个嫌疑变量。b 的嫌疑从入口经假路直达此处（19.8.1 已追过
链条），警告成立且落在"假路"这一条具体路径上。这是未初始化分析
最原始的职责：抓 use-before-def。

第二条，`node 7: c = b ... possibly uninitialized: b`——警告的对象
是右值里的 b，不是目标 c。语句尚未执行时，右值 b 已在 in 集合中；
分析在这一步如实报告"这次赋值读到了嫌疑值"。请注意警告收集在
in 状态上做（19.6.3 第四段），所以报告的是 b；c 的问题要等执行
之后，在下一条警告里出现。

第三条，`node 8: output c ... possibly uninitialized: c`——c 在上
一点刚被 b 传染，嫌疑沿数据流走了一跳。这一条是全章存在的理由：
如果传递函数只会 kill，第三条永远不会出现，`c=b` 的病被赋值动作
悄悄洗白，用户在 output c 处崩溃却收不到任何警告。19.2.1 的
方案一漏掉的就是它。

三条警告合起来演示了污染传播的完整生命周期：**嫌疑从边界出生
（入口）、沿不赋值的边存活（假路）、在读取点被报告（节点 6）、
在赋值点跨过右值传染给左值（节点 7→c）、在下游读取点再次被报告
（节点 8）**。没有第四条：output a 与 return 0 读取的 a 已被 input
洗净，a>0 的条件读取时 a 也已安全。警告不多不少，每一条都有路径
可指——19.4.4 的不虚报在此可见。

### 35.8.4 五元组打印段：纸面与机器对表

输出第 29–39 行把 19.3.1 的五元组按英文固定格式重新打印一遍。逐行
对表：lattice 行对应第一空（幂集、子集序、并集、空集底）；
direction 行对应第二空（forward）；boundary 行对应第三空，并在括号
里补了理由——params arrive initialized；init 行对应第四空；transfer
行对应第五空，规则写法与 init.cpp 第 109–119 行同形。

最后 theorem 行值得单独读：它只承诺框架白送的一般结论——传递函数
单调，故 worklist 最小不动点可靠近似 MOP，每个报告的 use-before-init
至少落在一条真实执行路径上。前半句是 19.4.1 的（1）（2），后半句
其实用到了本章的分配性（19.4.4（3））——一般框架不白送这后半句，
是本分析凭传递函数形状挣来的。把"框架保证"与"本分析额外满足"
在输出里区分不开是有意的：对使用者而言结论只有一句"报告是实的"，
论证层次是教科书读者才需要关心的事。

### 35.8.5 七行分类总表：第四篇收官

最后第 40–52 行是分类总表，七行分析按五元组归位。这是全章也是
第四篇的结论，逐列读。

analysis 列：七行恰好是 31–35 章出现过的全部分析——sign lattice
（28–31）、constant flat（17）、四大经典（18）、possibly-uninit
（本章）。没有第八行：第四篇没有引入这张表装不下的分析。

direction 列：四前向、两反向——方向由性质的产生方向决定，
19.3.1 第二空的判定标准在此一览无余：携带向前的性质（定值、
表达式可用性、未初始化嫌疑）前向，向后携带的（未来还要用、
未来会忙）反向。

merge 列：union 与 join/inter 三种写法。union 是 may，inter 是 must
（available、very busy），sign/constant 用各自格上的 join——四种
合并在 worklist 引擎里是同一个操作点（"合并前驱"），引擎不区分
may/must，语义全部压在格的 join 函数里。

boundary 列：三种边界——params=TOP（参数可以是任何值）、空集
（无事实）、decls\params（本章）。19.2.4 说过"边界是调用约定在
各个域里的翻译"，这一列把三种翻译并排放好：同一个约定，进符号
域是 TOP、进幂集 may 域是空集或声明差。

transfer 列：三类传递——抽象运算表（28–31 的符号算术）、常量折叠
（17）、gen/kill（18 四行）、state-dependent（本章）。四类形状的
包含关系 19.2.3 已建立：gen/kill 是状态依赖的静态特例，而抽象运算
表与常量折叠都可视为"在各自格上重算表达式"的同型函数。

横看七行，第四篇的全部论点收束成一句话：**一个 worklist 引擎、
七组五元组、七种分析**。此后要新增分析，正确动作不是复制一个
求解器，而是填一张五元组——格是什么、方向朝哪、边界给什么、
初值放哪、传递函数长什么样。表格的最后一行 state-dependent 提醒
读者第五空的自由度有多大：函数可以读状态本身。第五篇将开始
使用这份自由度处理更丰富的域，但"填表、交框架"的工作方式
不会再变。

### 35.8.6 两个思想实验：改动程序，输出如何随之变化

读到这里，理解的最终检验是预测——不运行程序，预言输出随源码
改动如何变化。给出两个小改动，请先自行回答再读解释。

**实验一：给 if 补一个 else。** 把程序改成
`if (a>0) { b=1; } else { b=0; }`，其余不动。三条警告还剩几条？

答案：一条不剩。汇合点节点 5 的两个前驱现在都来自对 b 赋值的
分支：真路 out {c}（节点 4 洗了 b），假路 else 里 b=0 同样洗 b；
并集不再含 b。节点 6 的 output b 安全；节点 7 的 c=b 右值读不到
嫌疑变量，污染条件不成立，c 不被染；节点 8 同样安全。这个实验
精确展示了 may 分析的算术：**嫌疑在汇合点被"每条路径都洗"时
才会熄灭，只要有一条路径没洗，它就活**——并集对"全员安全"
的要求是 ∩ 的味道，这正是初学者常把 may/must 在汇合点处弄混的
地方，值得亲手推一遍。

**实验二：在 c=b 之后加一句无条件赋值。** 在节点 7 与节点 8 之间
插入 `c = 1;`，警告如何变化？

答案：前两条（节点 6 报 b、节点 7 报右值 b）保留，第三条消失——
新赋值的右值是常量，传递函数第一步删 c、条件不成立，c 的嫌疑
被无条件洗净，output c 不再举牌。b 的嫌疑并未因此消失，它仍在
集合里一路带到出口，只是 c 不再继承。这个实验区分了两类警告的
独立性：**右值读取的警告（报源）与下游使用的警告（报果）由中间
语句逐个决定**，一次干净的覆写能切断传染链而不影响源头。两个
实验合起来说明：分析的输出不是一张静态标签表，而是可以随程序
结构逐点推导的演算结果——这正是"教程"与"规则清单"的区别。

## 35.9 工程注意点

最后是几点工程上的注意事项，都来自本章实现与理论之间的接缝处。

**警告要在不动点求完之后统一收集。** 迭代中途状态不稳定，过早
收集会出现两类时序问题：某些点先报了警、后来前驱状态变化又把
嫌疑洗掉（误报）；某些点暂时干净、后来回边把嫌疑带回来（漏报）。
本章把警告收集放在 worklist 完全排空之后，用最终 in 状态判定，
代价只是多遍历一次节点，换来输出与不动点严格一致。任何基于迭代
的分析都该遵守同样的次序：先收敛、后报告。

**边界条件与初值是两个槽位，不要混填。** 边界回答"链条从哪里
开始"——入口与其他无前驱点的手工值；初值回答"迭代从什么高度
起步"——其余点的 ⊥ 或全集。may 分析里初值放成全集会让所有点
一开始就顶在最保守状态，虽然仍然 sound，但最小不动点的精度可能
因"先入为主"丢失（实现若只做严格上升的话，⊤ 起步直接导致无解
可算）。两个槽位分别对应调用约定与收敛品位，填表时分开想。

**传递函数可以读状态，但不能修改全局状态。** 状态依赖指的是函数
输出依赖输入 S，不是函数在求值过程中往全局表里写东西。本章
usesOf 之类的查询全是纯函数；一旦传递函数有了可观察的副作用，
同一节点被重算多次可能给出不同结果，单调性论证随之失效，
worklist 的终止性也失去依据。保持传递函数纯粹，是框架对第五空
唯一的隐性要求。

**缺口要保守，不要留空。** 本章对 Deref/FieldA 目标、对嵌套在
复杂表达式中的特殊形式没有专门规则，处理方式是"原样传递状态"
而不是"不处理"——两者在代码层面只差一个默认分支，在 soundness
上差之千里：漏掉节点意味着状态在该处被重置为空（等价于声称
"一切已初始化"），那是漏报。扩展语言时，新语法构造的默认条款
应当永远是"什么都不改变"，等有了精确分析再收紧。

**输出格式本身也是回归资产。** expected/output.txt 被逐字节比对：
它既验证分析结果，也验证打印格式没有漂移。改一句提示文案、
动一个空格对齐都会被回归捕获——这看似严苛，实则防止"输出悄悄
变化，下游脚本解析失配"。教学实现与生产工具一样：把输出当成
接口对待，改动需有意、需可审。

**依赖顺序假设时要在本地注释里钉死。** init.cpp 第 69–71 行用
相同下标同时索引 cfg.funs 与 program.funs，前提是两者都按声明
顺序构造。这条假设不在任何类型签名里，只在注释中——它是正确的
做法：轻量假设配以就地说明，比为一次使用引入名字查表更清晰。
但反过来，若任何一个文件的构造顺序可能改变（比如 CFG 按调用图
重排函数），这条假设必须先被发现，方法是让注释与代码一同被
检索——grep 构造点、读注释。工程代码里"显然的下标对应"永远
值得一行注释，代价一行，避免的是跨文件静默错位。

把这六点合起来看，它们指向同一个工程姿态：**分析代码只负责
精确，边界处的保守、时序上的次序、接口上的稳定则由纪律负责**。
正确性论证保证的是"按规格写对"，而工程纪律保证的是"规格之外
的接缝处不出意外"。二者缺一，一个理论上 sound 的分析在实际系统
里仍可能输出不可信的结果。带着同样的眼光去读工业界的分析工具
（编译器告警、静态检查器、lint 系列），会发现它们的可信度差异
往往不在算法多先进，而在这些接缝处的纪律被执行得多彻底——
这是本章工程部分真正想留给读者的东西。

## 35.10 练习

1. **手工核对不动点。** 不看 19.8 的输出，对 init.tip 手工写出
worklist 第一轮（全节点初始入队、初值空集）每个节点处理后的
out 状态；再写出第二轮，指出哪些节点被重新入队、第二轮之后
是否已经收敛。与 expected 输出逐行核对，并解释为什么两轮即足。

   解题要点：第一轮各节点按编号处理，节点 2 洗 a、节点 4 洗 b，
汇合点第一次并前驱时假路状态已是 {b,c}；第二轮全部节点状态不变，
无人入队，收敛。关键在"边界状态在第一次处理 entry 时即注入"，
后继沿编号顺序一轮内全部拿到贡献。

2. **把污染规则反过来用。** 修改传递函数，让 output 语句不改变
状态但把"输出过的嫌疑变量"记入一个新集合；讨论这个集合能回答
什么分析问题（提示：哪些未初始化值已经被外部观察到，后果不可
撤回）。说明它与原警告是 may 还是 must 关系。

   解题要点：新集合是前向 may——"可能已带着未初始化值对外输出"；
它是原警告的下游投影，一旦某点加入则其后所有路径都保留（不可
撤回），可用在错误严重性分级：已外显的病比尚未外显的更紧急。

3. **证明或证伪一个加强规则。** 有人提议把污染条件从
"vars(e)∩S≠∅"加强为"vars(e)⊆S"（右值变量**全部**有嫌疑才
传染）。用 19.4.6 的路径语义论证它是否 sound；若不 sound，构造
一个具体反例程序，并指出该规则对应 may 还是 must 的误读。

   解题要点：不 sound。例：`if (a>0) b=1; c=b+d; output c;`，
d 从未赋值、b 可能未初始化；vars(e)={b,d} 不全在 S（若路径上
b 已洗）则不传染，但 d 的缺失仍使 c 无值。该规则把"任何一个"
（may）误换成"所有"（must 的 ∩ 直觉），反例即漏报路径。

4. **扩展到一种新语句。** 设想 TIP 增加 `assert e;`——条件为假时
程序中止。给出它在本分析中的传递函数与它产生的警告，并讨论：
中止语句对后继状态的可达性有什么影响？要利用这种影响，需要
第 39 章的什么机制？

   解题要点：传递恒等、警告同条件语句（读取的嫌疑变量要报）；
assert 为假时后继不可达，沿真边可把"e 读不到嫌疑"的信息用于
精炼——这正是第 39 章分支边条件精炼的同型机制，需要在边上带
条件并按真假两侧收缩状态。

5. **量化上下文无关的边界。** 若把演示程序里的 `c = b` 换成
`c = b; d = c; e = d; output e;`（嫌疑沿赋值链传播三跳），预测
output e 的警告文本；再讨论：污染链条长度在源码中任意增长时，
为什么分析的代价仍然只与变量数、节点数相关，而不与链长的路径
组合数相关——用 19.4.5 的语言回答。

   解题要点：警告报 e；分析在"点"上合并而非在"路径"上枚举，
链式赋值是直线、没有分叉，路径数始终为一，每跳的代价摊在对应
节点上，总成本 O(节点数×变量数界)；指数代价只来自分支的路径
组合，直线链不产生组合。

## 35.11 本章小结

本章从一个 gen/kill 写不对的例子出发，跨过了第四篇最重要的一条
理论边界。

在概念层面，第 33 章的 gen/kill 框架把传递函数限定为"固定增删"：
gen 与 kill 是语句的静态属性。`c=b` 暴露了它的边界——c 该不该继承
b 的嫌疑，取决于流入状态，于是正确的传递函数必须读状态：
F(x=e)=(S∖{x})∪({x} 当右值读到 S 中的变量)。这个"先杀后染"的
两步规则是污染传播的最小形状，也是 gen/kill 作为静态特例被包含
于其中的一般形式。边界条件"声明变量减参数"则把 TIP 的调用约定
翻译成幂集格语言：局部变量出生即嫌疑，参数携值而至。

在框架层面，本章第一次把 MonotoneFramework 五元组五项同时写全：
幂集格、前向、边界、⊥ 初值、状态依赖传递族。正确性的三层结论
随之落地——单调加有限高度保证 worklist 终止于最小不动点；
MFP⊒MOP 保证不漏报；传递族的分配性进一步给出 MFP=MOP，每条
警告都能指认一条具体路径。精度损失发生在域的合并里、而非迭代
算法里——这个定位是本章留给后续章节的重要判据。

在工程层面，十二个源文件中十个连同文法整建制复用，新增仅
init.hpp/cpp 一对纯函数；main.cpp 的流水线因此只需换一个分析
函数。七行分类总表把第四篇收成一句话：一个引擎、七组五元组、
七种分析。

最后值得把本章反复出现的一条思维线索单独点出：**问题的形态决定
五元组，而不是反过来**。先有"未初始化值会不会到达这个读取点"
的问题，才有幂集格（只表达在与不在）、前向方向（性质随执行携带）、
集合差边界（调用约定的翻译）与污染规则（赋值的具体语义）。如果
拿着现成的五元组去找问题，常见的变形是格选得过于丰富（带着用不
到的维度迭代，代价虚高）或过于贫乏（承诺表达不了问题需要的事实，
结论被迫含糊）。本章每一处设计决定——为什么不做条件精炼、为什么
不区分强弱、为什么缺口处原样传递——都可以回到"问题需要什么"
这一问上重新推导出来。带着这条线索进入后续章节：区间分析要回答
"值会不会越过某个界"，指针分析要回答"这个写会不会落到那块存储"，
问题形态一变，五元组随之重填，但"先理解问题、再装配框架"的
工作次序不变。
这也是本章最希望被带走的东西：方法比结论持久。

下一篇的视野将从"一个函数内的图"扩展到"整个程序"：第 37 章
先处理一个更实际的域——区间，以及它带来的新问题（无限高格与
widening）；第 37、38 章再回到过程边界，处理调用与上下文。
届时"填五元组、交框架"的工作方式不变，变化的只是格与传递函数
的复杂度。第五篇，开始。

---

上一章：[34 到达定值与非常忙](34-reaching-verybusy.md) · 下一章：[36 数据流框架定理](36-dfa-framework.md)
