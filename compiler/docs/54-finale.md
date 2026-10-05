# 第 54 章　收官：对照表、中端协作与阅读地图

## 54.1 四十八章之后，剩下什么

### 54.1.1 收官章的两个问题

一本教程的最后一章要回答两个问题：
读者手里现在多了什么？
下一步往哪里走？
第一个问题的答案不是
"三十个分析器"——
那是过程产物。
真正的答案是一套**世界观**：
任何静态分析都是
"具体语义 + 抽象域 + 不动点"的三件套，
可靠性都是
α(C) ⊑ A 的一个拼写，
精度都是保守度的一个定价。
第四十七章把这个世界观
钉成了定理；
本章把它铺成一张表，
让五十四章的每个成员
在表里各有一行、
每行四列——
域、方向、敏感维、可靠性。

第二个问题的答案是
一张阅读地图加三个
出发方向（30.5 与 30.7）。
地图不长——
静态分析是成熟的领域，
坐标就那么几座。

### 54.1.2 本章的机器：一张表与一段流水线

本章示例是全书最小的一个，
但两样东西都是新的。
其一，survey.cpp：
把十一个分析的结构化数据
（名称、章节、域、方向、
敏感维、可靠性一句话）
存成表、由 --check 打印——
"分析的分析"第一次成为
程序的数据。
其二，expected/opt/ 的
流水线对账：
tipa --emit-ir 吐出模块、
opt 的 mem2reg→SCCP→
simplifycfg 三段加工、
grep 抓出六个
"IR Dump After" 头——
教程第一次让**外部工具**
（LLVM 中端）进入对账链，
静态分析与优化变换的协作
从叙述变成可复现的实验。

### 54.1.3 与计划、与前章的对应

本章兑现教程计划的最后一格：
Galois 重看对照表
（十一行）与
LLVM 中端协作终览。
前接第 53 章（词汇表的来源）
与第 12 章（IR 与 ORC 的老家）。
附录收录全部十七个文件，
其中十四个是前端与 IR 的
原样复用——
收官章不给前端添新债。



## 54.2 对照表：十一行四列

### 54.2.1 表的构造：surveyRows 的形状

survey.cpp 用一个
vector<SurveyRow> 承载全表，
每行六个字段：
name（分析名）、
chapters（覆盖章）、
domain（抽象域）、
direction（迭代方向/
求解方式）、
sensitivity（敏感维）、
soundness（可靠性一句话）。
打印层 printSurvey
逐行展开成五行的块——
标题行加四行属性行。
数据与打印分离的
老纪律（第 42 章起）
最后一次执行。

值得想清楚的是
"表为什么是数据而不是散文"：
散文里的对照难以核对，
数据化的表可以被
程序枚举、对账、扩展——
读者加第十二个分析时
加的是一行结构体，
不是一段要斟酌措辞的段落。
**知识一旦结构化，
维护成本就从
"重写"降到"追加"**——
这是收官章用代码
承载总结的用意。

### 54.2.2 十一行的选择理由

表的行不是目录的镜像
（五十四章压缩成二十六行），
压缩的粒度是"分析家族"：
类型推断（第 17–20 章四合一行，
因为它们是一个算法的
四个阶段）；
符号（21–25 同理）；
常量单独一行
（它是 IDE 与 17 章的
交汇点，值得独立）；
活跃与可用表达式各一行
（第 26 章的两台经典机）；
区间（30–31）；
路径敏感执行（22）；
IFDS（25）与 IDE（26）分行
（布尔档与值档的
分界值得表上可见）；
0-CFA（27）与
Andersen（28）分行
（约束式家族的两支）。
Steensgaard 不单列——
它是 Andersen 行的
保守变体，
soundness 一栏里
一句话交代。
十一行、四个家族
（合一、格、制表、约束），
行是家族的成员、
列是家族的比较轴。

### 54.2.3 列读之一：域列——保守度的定价表

把域列单独抽出来从上往下读，
它是一张"保守度价目表"。
类型项的等价类：
不设保守——合一就是全部信息
（代价是不可判定的
递归类型需要 occurs 检查）。
五点符号格：
把整数压成五档，
价格是"同档不分家"。
平坦常量格：
只认唯一值或全不知，
价格是"两个常量相遇即废"。
幂集（活跃/可用）：
集合本身当格，
交半格的"越并越少"。
区间格：
无限高度，
价格是必须 widen
（第 31 章的账）。
路径条件下的状态：
不折叠路径，
价格是路径爆炸。
边缘函数的 L：
函数当格点，
价格是构造子的表达力边界。
loc→标签集与
var→分配点集：
两个幂集投影，
价格分别是
上下文合并与流序压扁。
十一个域、十种代价——
**选域就是选你能承受的
那种不精确**，
这张列读出来的是
工程预算的菜单。

### 54.2.4 列读之二：方向列——信息往哪流

方向列回答"工作表里流动的是什么"。
前向：符号、常量、可用、
区间、路径、IFDS、IDE——
信息从入口往出口走，
消费者是"到达点状态"。
后向：活跃变量——
信息从出口往入口倒流，
消费者是寄存器分配。
合一：类型——
没有方向，只有等价类的
彼此靠拢。
约束闭包：0-CFA、Andersen——
方向藏在包含关系里
（子集边单向），
工作表流动的是
"集合成员的到达"。
四种流动形状
覆盖了全书的求解器——
第 24 章的"方向是分析的
第一属性"
在表上得到最后一次确认。

### 54.2.5 列读之三：敏感维列——三个开关

敏感维列是三个布尔开关的
压缩编码：
流敏感（语句顺序是否区分）、
路径敏感（分支是否分开）、
上下文敏感
（调用点是否分开）。
表上读出三组样本：
全关——常量、0-CFA、
Andersen、活跃变量的
流不敏感版：
状态最省、合并最多。
只开流敏感——符号、
区间、可用：
区分前后但不分岔，
经典数据流的标配。
全开或接近——路径敏感执行、
IFDS/IDE 的配对路径：
精度档的天花板，
代价也是。
开关的每一档
在书中都有正反两个程序
（24 章 k=0/1、
22 章路径合并/分离）——
表上的每个格点
背后是一对可运行的证据。

### 54.2.6 列读之四：可靠性列——同一句话的十一种拼写

可靠性列最有意思：
十一行读下来，
它们全是同一定理的
域特化拼写。
类型行是"替换后无冲突"
（合一的一致性）；
符号行直书
α(C[[p]]) ⊑ A
（第 53 章的原文）；
常量行是"预测 c 处
具体值恰为 c"
（等式的 ⊑）；
活跃行是"超集"
（幂集上的 ⊑）；
区间行是"落在区间内"
（序关系的 ⊑）；
路径行是"可满足处有效"
（逻辑的 ⊑）；
IFDS 行最张扬——
"无假阳性无假阴性"
（可分配性买到的等式）；
IDE 行回到"函数求值 ⊒
真实变换"；
0-CFA 与 Andersen 回到
"⊆ 预测集合"。
**十一种拼写、一个方向：
分析的承诺永远
盖住现实的可能**——
第 53 章的定理
在表上排成纵队，
这是收官章
最想留给读者的画面。

### 54.2.7 对角读：家族的世系

按对角线（家族）读，
表讲出世系故事。
格家族一脉：
符号→常量→区间→路径，
同一台工作表、
换四次域、
精度步步升、
代价步步涨——
第 13 到 22 章的
十章是一个连续的
爬坡。
制表家族一脉：
IFDS→IDE，
布尔档换值档，
机器没换——
第 25/26 章的两章
是一台机器的
两个档位。
约束家族一脉：
0-CFA→Andersen→
（表外：Steensgaard），
幂集单调增长一种骨架、
三种工程化——
第 27/28 章互为镜像。
合一家族孤行：
类型推断独走一路，
它与格家族在
"环境"上遥相呼应
（第 19 章的合一与
第 45 章的并查集
在机制上同源）。
四个家族、
两次汇流——
汇流的地点
都在第 53 章的定理上。

### 54.2.8 survey.cpp 逐段走读

survey.cpp 全文不到七十行，
三段结构。
第一段是 surveyRows：
静态的 vector 初始化列表、
十一行数据、
每行六个字符串字段。
数据按家族顺序排列
（合一、格四、经典二、
区间、路径、制表二、
约束二）——
打印序即家族序，
读表的人先见世系
再见成员。
第二段是 printSurvey：
标题行、
计数器、
逐行的
"[n/11] 名 (ch范围)"
加四行属性行。
缩进四空格、
标签右对齐到十六字符——
纯手工排版，
无依赖、
无变动。
第三段什么都不做——
文件到此为止。
**收官新件的全部代码
不到一百行**，
因为它的工作是
承载结论而不是
计算结论：
五十四章算完了，
表只是把它们
摆整齐。

### 54.2.9 计数 "[N/11]" 的契约含义

标题行的方括号计数
（[1/26] 到 [26/26]）
不只是装饰：
对账脚本逐字节比对，
计数锁定行数；
读者扫一眼末行
"[26/26]" 即知表全。
练习一加第十二行时，
若计数硬编码，
打印会自相矛盾
（[12/11]）——
这个自相矛盾
恰是练习设计的
陷阱与教学点：
动态计数
（surveyRows().size()）
才是对的修法。
契约字段"自校验"
是一个值得偷走的
小设计。

###### 54.2.10 表的最后一行读法

安德森行的
soundness 栏末尾
藏着全表唯一的
"复合承诺"：
"Steensgaard 合并
只会更大不会不可靠"。
它把第 45 章的
保守变体
收编进主行——
**一个域、两种求解、
可靠性共享**。
这一读法提示读者：
表的行是
"问题"而不是
"算法"——
同一行可以长出
多个求解器
（Andersen/Steensgaard、
工作表/方程），
行与算法的
多对一关系
是表的结构性
留白，
也是它比目录
更接近本质的
原因。

## 54.3.7 一张纪念性的小图景

收官的时刻值得
一张小图景：
fold.tip 的六行程序
在 tipa --emit-ir 里
变成满页的
alloca 与 load/store，
被 opt 的三段流水线
一层层洗掉——
mem2reg 拿走槽、
SCCP 把 3+4*2
折成 11、
simplify 收起空块。
六行源代码
进、
更少的指令出——
中间的每一步判断
（槽能不能拿、
常量是不是真、
块空不空）
都是五十四章里
某一台机器的
工业亲戚
在加班。
静态分析
从来不是
教科书里的
一章习题，
它是每一次
"程序变快"
背后的
那次"没改错"
的担保。

## 54.4.4 会议与期刊的地图

论文往哪里找、
往哪里投，
一张小地图。
POPL：程序语言理论的
最高会——
连接、
类型、
语义的
数学前沿。
PLDI：编译实现的
最高会——
中端算法、
优化流水线的
工程前沿。
SAS：静态分析
专题会——
教程引用的
论文半数在此
与它的姊妹会
（VMCAI、TACAS）。
OOPSLA：对象与
函数式程序的语言
分析会——
0-CFA 与
指针分析的
很多族谱页在这里。
期刊一行：
TOPLAS 承接
会议版的完整论文。
找文献的入口技巧：
在 dblp 搜
"Cousot" 或
"Reps" 的引用网络，
一跳之内
覆盖教程四族
的源头。

## 54.5.3 每章一句话

五十四章各一句话，
作为回顾的最小粒度——
读者可用它自测
（每句话能否展开成
五分钟的复述）。

第 1 章：静态分析是
不运行程序的推理。
第 2 章：Rice 定理
决定了推理必须保守。
第 3 章：TIP 小到
能装进一页，
大到能出真问题。
第 4 章：文法是
分析器的第一份合同。
第 5 章：正则式
经 Thompson 与
子集构造
变成最小 DFA。
第 6 章：FIRST/FOLLOW
撑起 LL(1) 的
一眼决策。
第 7 章：项集与
移进-归约
把 LR 变成表。
第 9 章：属性文法
让语义按依赖图
求值。
第 8 章：AST 把语法树
变成类型安全的内存。
第 10 章：作用域决定
名字属于谁。
第 11 章：CFG 把树
摊成图，循环才可谈。
第 12 章：LLVM 执行台
让"具体"有了证人。
第 13 章：三地址码
与基本块是
优化的通用货币。
第 14 章：跟踪把块序
变成一次
有账可查的优化。
第 15 章：活动记录
给函数调用安家。
第 16 章：可达性
让垃圾回收
只丢无主之物。
第 17 章：类型是
值的集合。
第 18 章：约束生成
把程序翻成方程。
第 19 章：合一解方程，
并查集是它的钱包。
第 20 章：递归类型
与多态把合一推向边界。
第 21 章：五点格，
"保守"的第一个家。
第 22 章：域是代数，
可以组装。
第 23 章：不动点：
方程的答案、
无限的刹车。
第 24 章：工作表：
只追变化，
单调即止。
第 25 章：常量与符号
同台，
强更新是精度的
发动机。
第 26 章：活跃变量
倒着走，
可用表达式顺着走，
交半格管住精度。
第 27 章：到达定值
与非常忙
补全四大经典。
第 29 章：MFP ⊑ MOP，
分配性取等。第 28 章：转移函数
是语义的表格化。
第 30 章：区间：
宽度换高度。
第 31 章：加宽止损、
收窄找零。
第 32 章：路径敏感：
把分支的账分开记。
第 33 章：支配树是
控制流的骨架。
第 34 章：φ 与改名
让每个名字
唯一定值。
第 35 章：控制依赖
是分岔的骨架，
SSA 来回双证。
第 36 章：DAG 把
块内冗余
登记成共享。
第 37 章：外提与
归纳变量
瞄准循环。
第 38 章：能证明
安全的检查
一条不留。
第 39 章：六方程
解出“最晚且一次”。第 40 章：跨函数：
摘要与内联的两难。
第 41 章：上下文：
k 的价格表。
第 42 章：IFDS：
配对路径上的
精确可达。
第 43 章：IDE：
给事实带上值。
第 44 章：0-CFA：
调用图是分析
出来的。
第 45 章：指针：
包含与合一的
两种保守。
第 46 章：前缀法与
vtable 是
对象派发的几何。
第 47 章：闭包把
环境装箱，
惰性按需算。
第 48 章：干涉图着色
把变量装进
有限的盒子。
第 49 章：树覆盖与
窥孔走完
到汇编的最后一级。
第 50 章：依赖划界，
调度填槽。
第 51 章：猜分支、
提前取——
替机器赌未来。
第 52 章：交换买空间，
分块买时间。第 53 章：α 与 γ：
保守写成定理。
第 54 章：一张表：
三十章的
四列答案。

## 54.3 LLVM 中端：分析—变换协作的终览

### 54.3.1 为什么要看中端

教程的 LLVM 用法到本章为止
是"执行台"（第 12 章）与
"IR 生成目标"（各章 irgen）——
编译器的后端视角。
但静态分析的**工业雇主**
主要是中端：
优化流水线里每个 pass
都在消费某种分析的结果、
又都可能把别的分析
缓存作废。
本章用 fold.tip 走一遍
最小的中端协作：
mem2reg、SCCP、
simplifycfg 三段，
正好对应教程造过的
三种分析。

fold.tip 的六行程序
是老朋友（第 25 章起
的折叠样例）：
a = 3+4*2、
b = a*2+input、
两次 output。
它未经优化的 IR 里
全是 alloca/load/store——
教科书式的
"待 mem2reg 抢救"形状。

### 54.3.2 三段流水线的对账形态

expected/opt/fold.cmd
是两行 shell：
导出 PATH（DLL 与 opt）、
把 tipa --emit-ir 的输出
管道给
opt -passes=mem2reg,
sccp,simplifycfg
-print-after-all -o /dev/null，
再 grep 出
"IR Dump After" 头。
fold.out 锁定六行输出：
main 与 entry 两个函数、
各三个 pass 名——
PromotePass（mem2reg 的
实现名）、SCCPPass、
SimplifyCFGPass。
check_example 的 opt 对账
分支执行 .cmd 并逐字节
比对——
**外部工具的行为
第一次进入教程的
对账契约**，
其代价是输出依赖
本机 LLVM 版本
（22.1.8）——
换版本头行变、
对账红、
更新期望即可。
版本敏感换来的是
"教程的流水线
真的在跑真的优化器"。

### 54.3.3 PromotePass：mem2reg 与活跃变量的血缘

mem2reg 把 alloca 槽
提升为 SSA 值，
条件是槽的 def-use
形态规整
（无逃逸、无部分访问）。
它的内部用到的
dominance frontiers
计算与活跃性判断，
与第 26 章的活跃变量分析
同源——
后向的 use/def 传播
找出"哪些 load
能看到哪个 store"。
教程没实现支配边界
（SSA 构造的钥匙），
但第 26 章给读者的是
同一片 use/def 的土壤：
mem2reg 是在
那片土壤上盖的房。

### 54.3.4 SCCPPass：第 43 章 IDE 的工业亲戚

SCCP（Sparse Conditional
Constant Propagation）
是中端里最"分析味"的
优化：它同时跑
常量传播与控制流可达，
一边算值、
一边用值剪分支，
两个信息源互相喂。
 lattice 是三值的
（未知/常量/非常量）——
与第 43 章的 L 同构；
传播沿 SSA 的 def-use 边
（稀疏性由此来）——
对应 IDE 的边缘函数复合；
分支剪除
（条件为常量时
另一边标不可达）——
第 43 章刻意没做的
路径信息，SCCP 做了。
所以对照表上
IDE 行的 soundness 栏
写"三值常量格上
机器检验"，
而 SCCP 在同格上
多拿了路径的一票——
**分析连优化
之间的精度差，
就在表外的那一票**。

### 54.3.5 SimplifyCFGPass 与分析信息的失效

simplifycfg 消费的是
控制流形状信息：
不可达块删除
（SCCP 的产出）、
空块跳转压缩、
分支合并。
它也是**失效问题**的
最佳教具：
它改动 CFG 后，
任何以块为单位缓存的
分析结果（支配树、
后必经、可达性）
全部作废，
LLVM 的 pass manager
以依赖声明
（analysis group）处理
"谁倒了谁的缓存"。
教程的分析器都是
一次性的
（跑完即丢、无缓存），
避开了这整章问题——
工业流水线的真实复杂度
不在单个 pass 的算法
（教程全造过原型），
而在 pass 之间
**信息的新鲜度管理**。
这是收官章把读者
送向 LLVM 文档前
要说的最后一句实话。

### 54.3.6 从对账红看版本依赖

一个值得预告的实验：
升级 LLVM 后重跑
check_example 30，
fold.out 大概率红
（pass 改名或顺序变）。
处理流程：
重跑 .cmd 看新头行、
更新 fold.out、
全绿恢复。
这次"红—更新—绿"
本身是教程方法的
最后一次演练：
**对账不是永恒不变的碑，
是可维护的契约**——
红是契约在履行职责
（告诉你世界变了），
不是契约失效。
读者将来维护
自己的分析基建时，
"允许红的契约"
比"从不红的祈祷"
可靠得多。

## 54.4 延伸阅读地图

### 54.4.1 三本主教材

教程的骨架书 spa
（Møller & Schwartzbach
《Static Program Analysis》）
之后的三本主教材，
按角色分。

Dragon（Aho 等
《编译原理》）：
前端与中端的
全景教科书——
教程第 3–12 章的
每个话题在它那里
有正式的章节；
读它的收益是把
"教程造过的玩具"
放进工业语法的
真实复杂度里校准。

Cooper & Torczon
《Engineering a
Compiler》：
工程派的圣经——
SSA、支配边界、
pass manager 的
正式叙述；
30.3 的失效话题
在它第 17 章有完整展开。

Nielson–Nielson–Hankin
《Principles of Program
Analysis》：
分析派的标准文本——
格、连接、
抽象解释的
严格课程；
第 53 章的定理
在它那里是
四章的前置结论。

三本的读法顺序
建议：
回头补基础选 Dragon、
向优化工程走选 Cooper、
向理论深处走选 NNA——
三条路都从
本教程的某个终点出发，
没有一条要你重来。

### 54.4.2 两份在线资源

LLVM 的
"Writing an LLVM Pass"
与 opt 手册：
中端协作的官方课——
30.3 的三段流水线
在文档里是完整的一章。
读法：
边读边给教程的 tipa
加一个真的
LLVM pass
（比如把第 25 章常量分析
包成 pass）——
一天工作量，
教程与工业的距离
就地消零。

Soufflé 与 Doop 的
文档（datalog.
souffle-lang.org、
doop.googlecode 前身
已迁 github）：
声明式分析的入口——
第 45 章 28.14.1 的
九行规格
在 Doop 里是
几百行规则的现实版。
读法：
拿 ptr.tip 的约束
写第一个 Soufflé 程序
（第 45 章练习十六），
再读 Doop 的
context-sensitivity
开关族。

### 54.4.3 三篇论文

按年代排的三篇
"如果只读三篇"：
Reps–Horwitz–Sagiv 1995
（IFDS，第 42 章的
全部内容在八页里）；
Cousot & Cousot 1977
（抽象解释，
第 53 章的地基）；
Andersen 1994
（包含式指针分析，
第 45 章半边）。
三篇的共同点：
提出的机器
至今仍在生产环境跑——
读经典的意义
不是考古，
是认出今天工具里的
那些名字。

## 54.5 全书回顾：七篇三十章

### 54.5.1 七篇的划分与递进

第一篇（1–2 章）
立地基：
不可判定性划定
静态分析的能力边界——
一切"保守"的总开关。
第二篇（3–8 章）
造机器：
TIP 语言、ANTLR 文法、
AST、作用域、CFG、
LLVM 执行台——
六个可独立运行的台阶。
第三篇（9–12 章）
第一类分析：
类型推断——
不靠格的合一世界。
第四篇（21–28 章）
格分析的全套：
域、构造、不动点、
工作表、符号、常量、
经典双向流、
转移函数系统。
第五篇（30–32 章）
精度的深水：
区间、加宽收窄、
路径敏感。
第六篇（40–45 章）
跨函数的世界：
过程间、上下文、
制表双档、
约束双支。
第七篇（53–54 章）
收束：
定理与对照表。

七篇的递进逻辑是
"从能算什么到算得多好"：
先把分析器造出来
（二到四篇），
再谈精度的代价
（五篇），
再谈跨函数的扩展
（六篇），
最后回到"一切分析
共通的是什么"（七篇）。

### 54.5.2 每篇的"一台机器"

七篇各有一台
可指认的机器：
第一篇是归约机
（Rice 定理的证明装置）、
第二篇是执行台
（ANTLR+LLVM）、
第三篇是合一机、
第四篇是工作表、
第五篇是加宽的工作表、
第六篇是制表机与
约束求解器、
第七篇是收集对表机。
**七台机器、
三种骨架**
（归纳、格上不动点、
单调闭包）——
骨架的重复出现
是教程最大的伏笔，
收官章把它挑明：
认骨架比认机器重要，
机器会过时、
骨架不过。

### 54.5.4 三种骨架的使用次数

把三十章按骨架归档、
数使用次数：
格上不动点——
13、14、15、16、17、
18、19、20、21、29
共十章；
单调闭包（约束式）——
10、11、12、27、28
共五章；
归纳与配对（制表式）——
22、25、26 共三章；
其余（1–9、23、24、30）
是地基与桥梁。
骨架的使用频率
就是它的重要性权重——
工作表（不动点骨架的
执行形态）出现得最多，
也最值得
闭着眼能写。
读者分配复习时间时，
照这个权重排：
一半给工作表家族、
四分之一给约束、
四分之一给制表。

### 54.5.5 三十章的三个"第一次"

回忆的另一个抓手：
每篇的"第一次"。
第一次造出机器：
第 12 章 tipa 跑通
main 的那一刻——
静态世界第一次
有了证人。
第一次看见保守：
第 21 章 ⊤ 吞掉 +
的那一刻——
"不精确"从缺点
变成方法。
第一次证明：
第 53 章定理行
HOLDS 的那一刻——
工程第一次升格为
数学。
三个时刻连线，
就是教程的
情绪曲线：
能跑、
能让、
能证。
读者若在自己的
复刻路上也守住
这三个时刻，
教程的传递
就完整了。

## 54.6 从教程到实践：三个出发方向

### 54.6.1 方向一：给自己的语言写分析器

教程的全套零件
可以直接搬到
任何小语言上：
ANTLR 文法（4 章）、
AST 构造（5 章）、
名字解析（6 章）、
CFG（7 章）、
工作表框架（16 章）、
选一个域（13/17/20 章）。
一个周末能跑通
第一版符号分析，
一个假期能到
过程间档。
建议的第一个目标：
自己写过的解释型语言
（lisp 方言、
玩具脚本）——
分析"哪些变量在
循环里恒正"、
"哪些函数无副作用"，
两个问题
分别对应符号与
0-CFA 的最小版。

### 54.6.2 方向二：进入 LLVM 生态

给真实编译器写 pass
是分析技术的
最大雇主市场。
路径：
本地构建 LLVM、
跟官方 tutorial 走
HelloWorld pass、
然后挑一个教程分析
（推荐第 25 章常量）
包成 FunctionPass——
IR 的遍历在教程里
是 irgen 的反向
（生成 vs 读取），
两天熟悉。
进阶方向：
给 SCCP 报
不精确的格点
（对照第 43 章的
IDE 精度）——
工业 pass 的精度
批评是真实存在的
研究入门题。

### 54.6.3 方向三：声明式与查询

第三条路把分析
当数据库问题：
Datalog 规则当查询、
程序事实当表。
Soufflé 的学习曲线
一周以内，
之后第 27/28 章的
每个分析都可以
"翻译重跑"——
翻译的过程
就是对自己理解的
终极检验
（写不出规则
= 没懂约束）。
这条路通往
Doop/Soufflé 的
研究前沿
（包含式指针分析的
精度/性能边界），
也通往工业的
代码查询
（CodeQL 一族——
语义化 grep）。

三个方向的共同底座
都是教程的三件套：
域、约束、不动点。
方向之间的切换成本
远小于入门成本——
**先学会一个，
再挑贵的做**。

## 54.7 练习

练习一：给 surveyRows
加第十二行：
Steensgaard
（域=并查集等价类、
方向=合一、
敏感维=流不敏感、
可靠性="真实指向 ⊆
等价类标签并，
且 ⊇ Andersen 的解"）。
打印层的
"[N/11]" 计数要同步改
（或改成动态计数——
更好的选择）。

练习二：把对照表
导出为 Markdown 表格
（新加 --check --md？）
——但注意输出契约：
加开关而非改默认，
否则 expected 全红。
这个练习的要点是
"扩展不破坏契约"
的工程习惯。

练习三：给 opt 流水线
加第四段
-instcombine，
重生成 fold.cmd 与
fold.out。
数一数新增的
Dump 头行数，
解释 instcombine
为什么可能
改变后续 pass 的
触发（提示：
它折叠指令、
给 SCCP 造新常量）。

练习四：对照表对角题。
从表里挑任意两行，
写出它们共享的骨架
（不动点/制表/闭包/合一）
与不同的部件
（域/方向/敏感维）。
全表 C(11,2)=55 对，
挑十对做完——
收官章的
"温故"量到此足矣。

练习五：毕业论文题。
选一个教程没做的分析
（字符串污点、
锁持有、
资源泄漏任一），
按三件套设计：
选域、写约束、
跑不动点、
配 soundness 检验
（对表第 12 章执行台）。
规模控制在
一个新示例目录 +
一篇 200 行文档——
你已经有过一次
全套经验
（读完本教程），
第二次应当
只需要十分之一的时间。

### 54.7.1 练习六到八

练习六：把 30.5.3 的
三十句拷出来，
遮住右半边，
只看章号自测
能否说出那句话。
错过的章
就是回读的坐标——
这个自测的
边际成本十分钟，
信息量
却等于一次
全书摸底。

练习七：给对照表加
第五列"教程示例目录"
（examples/NN_*），
用脚本从
docs 目录名
自动抽取生成——
加列本身十分钟，
工程点在于
"表的数据源
能否自动化"：
能自动化的表
永远新鲜，
手工的表
第一个月就开始撒谎。

练习八：终笔题。
写一篇 500 字的
"给后学的信"：
假设读者只学过
变量与循环，
向他解释
静态分析是什么、
为什么必须保守、
以及你最想让他
记住的一个分析。
写完后与
第 1、2 章对照——
你比当时的作者
（教程的自己）
多说的那部分，
就是这三十章
真正住进你脑子
的部分。

### 54.6.4 三个方向的决策树

临别的选择辅助：
如果你的日常语言
是自造的小语言——
选方向一
（自给自足）；
如果你在写
或想写编译器、
JIT——
选方向二
（LLVM 生态）；
如果你面对的
是"百万行、
查语义"的
存量代码——
选方向三
（声明式查询）。
三者不互斥，
但第一个深入
最好只挑一个——
教程的经验
（一次造一台机器）
同样适用于
一次走一条路。

## 54.8 小结

三十章的旅程
在一张表上结束。
表的四列是
四个古老的问题：
在哪算（域）、
往哪流（方向）、
分多细（敏感维）、
凭什么信（可靠性）。
表的十一行是
教程亲手造过的
十一种回答，
它们共用三种骨架、
汇于一条定理。
中端的三段流水线
把分析放回
它的工业岗位——
优化器身边、
失效问题中间。
阅读地图与三个方向
把下一步铺开：
无论往工程、
往生态、
还是往声明式走，
行李都是这套
三件套加一张表。

最后一句话留给
坚持到这里的读者：
静态分析的
全部秘密
写在第 53 章的
一个偏序符号里——
分析的承诺
永远盖住现实的可能；
其余三十章，
只是让这句话
可以被造出来、
跑起来、
对上账。

### 54.8.1 动手验证本章

`bash tools/example_build.sh
examples/54_finale` 构建，
`python tools/check_example.py
examples/54_finale`
对账两层：
--check 的表输出
对 expected/output.txt
（fold.tip 会先过一遍前端、
打一行 frontend OK）、
opt 流水线的六个 Dump 头
对 expected/opt/fold.out
（需要 UCRT64 的 opt
在 PATH——.cmd 自带
导出行）。
docs 对账由 check_docs.py
覆盖十七个文件。
升级 LLVM 后的
红—更新—绿流程
见 30.3.6。

### 54.8.2 一页纸

表四列、
骨架三根、
方向两向、
敏感三维、
定理一句：
α(C) ⊑ A。
流水线三段：
mem2reg 抢救槽、
SCCP 算常量、
simplify 收拾形状。
书三本、
论文三篇、
路三条。
三十章一句话：
先学会算，
再学会保守，
最后学会证明保守。

## 54.9 本章配套文件

以下整文件收录
examples/54_finale 的全部内容：
文法与程序、
收官新件（survey）与驱动、
IR 生成、
前端基础件、
期望输出（含 opt 流水线）。

### 54.9.0 附录导览与使用方式

十七个收录文件按
"新件 → 驱动 → IR → 前端 → 期望"
排列。
新件（survey 两个）是
本章的增量、
其余是复用——
复用件在本章的
接触面只有三处：
irgen 供 --emit-ir
（30.3 流水线的源头）、
cfg 供 --check 的
frontend OK 行、
前端五件供解析。
三处接触面
与第 53 章 29.14.13 的
清单同构——
收官章与抽象解释章
共享"复用半径最小"的
美德。
使用方式与前章同：
通读配导语、
查阅按文件名、
实验拷底版——
特别推荐把
survey.cpp 的表数据
当实验底版：
改一行数据、
跑一次对账、
看红在哪层
（example 的 output.txt
与 docs 的嵌入同时红），
"数据即契约"的
反馈闭环
五分钟一圈。

### 54.9.1 文法 TIP.g4

与第 42–53 章相同；
本章程序只用整数运算，
其余产生式在位未触及。

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

### 54.9.2 程序 programs/fold.tip

第 25 章以来的折叠样例；
本章它多了一个角色——
中端流水线的输入。

```cpp
// file: programs/fold.tip
main() {
  var a, b;
  a = 3 + 4 * 2;
  b = a * 2 + input;
  output a;
  output b;
  return 0;
}
```

### 54.9.3 收官新件 survey.hpp 与 survey.cpp

对照表的数据与打印。
全章的"分析的分析"。

```cpp
// file: src/survey.hpp
// 第 54 章配套：全教程九类（十一行）分析的 Galois 视角总表。
// 每行回答四个问题：抽象域是什么、不动点沿哪个方向迭代、对什么敏感
//（对什么不敏感）、可靠性的陈述是哪一句话。收官章用它把 30 章压回
// 一页：换域 = 换分析，换方向 = 换用途，换敏感维 = 换精度与代价。
#pragma once

#include <string>
#include <vector>

namespace tip {

struct SurveyRow {
    std::string name;     // 分析名
    std::string chapters; // 覆盖章节
    std::string domain;   // 抽象域
    std::string direction;// 迭代方向 / 求解方式
    std::string sensitivity; // 敏感维（流/路径/上下文/不敏感）
    std::string soundness;   // 可靠性的一句话陈述
};

const std::vector<SurveyRow> &surveyRows();

// 固定文本总表：--check 打印，期望文件逐字节对账。
std::string printSurvey();

}  // namespace tip
```

```cpp
// file: src/survey.cpp
#include "survey.hpp"

#include <sstream>

namespace tip {

const std::vector<SurveyRow> &surveyRows() {
    static const std::vector<SurveyRow> rows = {
        {"类型推断", "17-20",
         "类型项（类型变量、函数/记录构造子）上的等价类；无高度、靠合一合并",
         "约束收集后单向合一（合一不动点）",
         "表达式位置敏感；无格序，等价类只增不减",
         "推断类型与所有使用约束一致：替换后程序不再有类型冲突"},
        {"符号分析", "21-25",
         "五点符号格 ⊥ ⊏ −,0,+ ⊏ ⊤（每个整型变量一格）",
         "前向工作表，沿 CFG 求最小不动点",
         "流敏感；路径与上下文均合并",
         "α(C[[p]]) ⊑ A：具体值符号必在预测格点之下（第 53 章机器检验）"},
        {"常量传播", "25",
         "平坦常量格 ⊥ ⊏ c₁,c₂,… ⊏ ⊤",
         "前向工作表，强更新 + join 合并",
         "流敏感；路径与上下文均合并",
         "预测为单点 c 的变量，任何具体执行取值恰为 c"},
        {"活跃变量", "26",
         "2^Var 幂集格（交为 join，全集为 ⊥）",
         "后向工作表：use 生成、def 清除",
         "流敏感；路径与上下文均合并",
         "离开程序点仍活跃的变量，其当前值沿某条后续路径会被使用"},
        {"可用表达式", "26",
         "2^Expr 幂集格（交为 join，全集为 ⊥）",
         "前向工作表：表达式计算生成、操作数重写清除",
         "流敏感；路径与上下文均合并",
         "集合中的表达式在该点必然已算出且操作数未被改写，可直接复用"},
        {"区间分析", "30-31",
         "区间格 [l,u]（无限高度，widen 加宽求收敛、narrow 收窄）",
         "前向工作表，循环头处加宽",
         "流敏感；路径与上下文均合并",
         "具体值落在预测区间内；加宽只丢精度不丢可靠性"},
        {"路径敏感执行", "32",
         "每条路径一个状态；合并即分离（路径条件合取约束状态）",
         "前向，沿展开的路径图（exploded graph）",
         "路径敏感；上下文可配 call-string",
         "状态在路径条件可满足处有效；假阳性只来自路径合并，永不来自传递"},
        {"IFDS 可达事实", "42",
         "有限事实域 D ∪ {零事实}，D 上幂集",
         "超级图前向 tabulation（路径边制表）",
         "过程间全路径；流函数可分配 ⇒ 完全",
         "事实沿有效路径可达 ⟺ 表格含该路径边（无假阳性无假阴性）"},
        {"IDE 值流动", "43",
         "事实 × 环境格 L（边缘函数 λ:L→L，常量/恒等/复合闭包）",
         "超级图前向 tabulation，边缘函数沿边复合",
         "过程间全路径 + 事实携带值",
         "边缘函数求值 ⊒ 真实值变换（三值常量格上机器检验）"},
        {"0-CFA 闭包流", "44",
         "loc → 函数名集合（幂集），缓存即抽象堆",
         "约束系统单调增长（立方工作表）",
         "流不敏感、上下文不敏感（k=0）",
         "每个调用点的真实 callee 集合 ⊆ 预测集合"},
        {"Andersen 指针", "45",
         "变量 → 分配点集合（包含约束的幂集解）",
         "子集约束闭包（最坏 O(n³) 工作表）",
         "流不敏感；语句顺序无关",
         "真实指向集合 ⊆ 预测集合；Steensgaard 合并只会更大不会不可靠"},
        {"到达定值", "27",
         "定值集合（TAC 行号标识）",
         "前向工作表（may：并合并）",
         "流敏感；路径与上下文均合并",
         "ud 链必含真实到达者：可能多报、永不漏报"},
        {"非常忙表达式", "27",
         "表达式键集合（空格分界）",
         "后向工作表（must：交合并）",
         "流敏感；路径与上下文均合并",
         "集合中的表达式沿每条路径必在操作数改写前被使用"},
        {"数据流框架", "29",
         "任意半格 + 单调转移函数（may/must/常量三口径）",
         "轮转迭代到最大不动点（MFP）",
         "由实例自定（四大经典全部齐备）",
         "MFP ⊑ MOP：分配性（gen/kill）取等，常量传播严格粗（菱形反例机器检验）"},
        {"基本块 DAG", "36",
         "值图：运算结点 + 名字标签（结点即值）",
         "单遍贪心登记（恒等式折叠 + 交换律规范键）",
         "块内（局部）；不跨块",
         "多名一结点 = 公共子表达式；恒等式按整数语义逐条成立"},
        {"循环不变式", "37",
         "指令集合（循环内/外二分）",
         "自然循环识别 + 三判据外提（迭代两轮）",
         "循环级；preheader 为唯一落点",
         "steps 下降 + outputs 不变（解释器对账）；判据缺一即语义翻车"},
        {"部分冗余消除", "39",
         "表达式集合 × 六个方程（antic/avail/earliest/post/used/latest）",
         "三向方程联立（前向 must + 后向 must + 后向 may）",
         "流敏感；分支几何即优化几何",
         "latest 落点保证安全（操作数必已定值）且至多一算（复用区间）"},
        {"干涉图着色", "48",
         "变量集合上的干涉图（边 = 活跃重叠）",
         "Chaitin–Briggs 压弹栈（度 < k 摘除）",
         "分配级（寄存器压力的画像）",
         "相邻异色机器逐边校验；溢出如实报告为保守回退"},
        {"依赖 DAG 调度", "50",
         "指令集合 + RAW/WAR/WAW/MEM 边",
         "关键路径优先表调度（宽度 1/2）",
         "块内；重排不改语义",
         "重放校验：发射序满足全部依赖（机器证人）"},
        {"跟踪线性化", "14",
         "块覆盖序（贪心 Algorithm 8.3）",
         "终结符四规则处置（删跳/翻转/补跳）",
         "布局级（块序即布局）",
         "gotos 下降 + outputs 不变（跳转计数与解释器双证人）"},
        {"控制依赖图", "35",
         "后支配集（逆图支配迭代）",
         "FOW 沿后支配树上行",
         "分岔结构（与支配边界对偶）",
         "SSA 三方对账 tac==ssa==back（构造与拆解双向背书）"},
        {"guard 消除", "38",
         "分母的循环不变性/归纳单调性",
         "两规则删 guard（区间推理是完全体）",
         "循环级",
         "guards 下降 + outputs 不变（插入-删除往返无损）"},
        {"对象派发", "46",
         "类层级 + vtable 槽表（前缀法布局）",
         "虚调用沿 vtable 取槽；静态沿链直呼",
         "0-CFA 口径的静态类型收敛",
         "目标集 = 全部子类实现（去虚化即收缩）"},
        {"闭包转换", "47",
         "λ 的自由变量集（相对自身参数）",
         "装箱清单 = 捕获集（env 记录上堆）",
         "词法作用域（不可变让抄即共享）",
         "尾调用栈不增长；need ≤ value 求值计数对账"},
        {"分支预测/预取", "51",
         "二位饱和状态机 / ⌈延迟/迭代⌉ 距离",
         "静态启发式（后向 taken）；软件预取指令",
         "控制流历史 / 访存流水",
         "循环命中率 > 乱序（状态序列逐事件可验）"},
        {"缓存局部性", "52",
         "仿射访问（方向向量 + GCD 检验）",
         "循环交换合法性 + 分块（块内行优先）",
         "迭代空间级",
         "变换合法 ⟺ 无 '<' 逆序依赖；miss 对比由模拟器对账"},
    };
    return rows;
}

std::string printSurvey() {
    std::ostringstream out;
    out << "== static analyses and transformations in this tutorial, seen through Galois eyes ==\n";
    int i = 0;
    for (const SurveyRow &r : surveyRows()) {
        out << "[" << ++i << "/" << surveyRows().size() << "] " << r.name
            << " (ch" << r.chapters << ")\n";
        out << "    domain       : " << r.domain << "\n";
        out << "    direction    : " << r.direction << "\n";
        out << "    sensitivity  : " << r.sensitivity << "\n";
        out << "    soundness    : " << r.soundness << "\n";
    }
    return out.str();
}

}  // namespace tip
```

### 54.9.4 驱动 main.cpp

--check 打表（带 FILE 时
先过前端）、--emit-ir
供 opt 实验取材。

```cpp
// file: src/main.cpp
// 第 54 章配套程序：收官总装。
//   --check [FILE] : 打印全教程分析的 Galois 视角总表（固定文本）；
//                    给 FILE 时顺带确认该程序能通过前端（解析+名字解析+CFG）
//   --emit-ir FILE : 打印未优化 LLVM 模块——供 opt 中端流水线实验取材
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "irgen.hpp"
#include "survey.hpp"
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

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 2 && std::string(argv[1]) == "--check") {
        if (argc >= 3) {
            // 收官章不引入新分析：只确认样例程序过前端、CFG 可建，
            // 然后输出总表。前端可用性本身就是 30 章成果的一部分。
            Parsed p = parseFile(argv[2]);
            tip::Cfg cfg = tip::buildCfg(*p.ast);
            std::cout << "frontend OK: " << cfg.funs.size()
                      << " function(s) built into CFG\n";
        }
        std::cout << tip::printSurvey();
        return 0;
    }

    if (argc >= 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }

    std::cerr << "usage: tipa --check [FILE] | tipa --emit-ir FILE\n";
    return 1;
}
```

### 54.9.5 IR 生成 irgen.hpp 与 irgen.cpp

第 12 章基线原样；
30.3 的三段流水线
消费它吐出的模块。

```cpp
// file: src/irgen.hpp
// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 44 章以后扩展，遇到时直接报错。
#pragma once

#include <map>
#include <memory>
#include <string>

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

struct IRGen {
    // 三者均以 unique_ptr 持有：JIT 需要接管 Module 与 Context 的所有权。
    std::unique_ptr<llvm::LLVMContext> ctx;
    std::unique_ptr<llvm::Module> mod;
    std::unique_ptr<llvm::IRBuilder<>> b;

    const Bindings *bindings = nullptr;
    const FunDecl *cur = nullptr;
    std::map<const Symbol *, llvm::AllocaInst *> locals;

    IRGen();

    // 生成全部 TIP 函数 + C main（main 改名 tip_main）。
    // 结束后模块必须通过 verify。
    void gen(const ProgramA &program, const Bindings &resolved);

    llvm::Value *expr(const Expr *e);
    void stmt(const Stmt *s);

    bool verify() const;
    std::string dump() const;

  private:
    llvm::FunctionCallee rtInput_, rtOutput_;

    void genFun(const FunDecl *f, Scope *scope);
    void genWrapper(const FunDecl *mainFun);
};

}  // namespace tip
```

```cpp
// file: src/irgen.cpp
#include "irgen.hpp"

#include <stdexcept>
#include <utility>
#include <vector>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace tip {

IRGen::IRGen()
    : ctx(std::make_unique<LLVMContext>()),
      mod(std::make_unique<Module>("tip", *ctx)),
      b(std::make_unique<IRBuilder<>>(*ctx)) {
    // 运行时入口先声明：input 无参返回 i32，output 吃一个 i32。
    auto *i32 = Type::getInt32Ty(*ctx);
    rtInput_ = mod->getOrInsertFunction(
        "tip_input", FunctionType::get(i32, false));
    rtOutput_ = mod->getOrInsertFunction(
        "tip_output", FunctionType::get(Type::getVoidTy(*ctx), {i32}, false));
}

namespace {

// TIP 的 main 改名 tip_main：真正的 @main 是我们生成的 C 入口。
std::string emitName(const std::string &name) {
    return name == "main" ? "tip_main" : name;
}

}  // namespace

void IRGen::gen(const ProgramA &program, const Bindings &resolved) {
    bindings = &resolved;

    // 先创建全部函数（含类型），函数体互相前向调用时也能查到声明。
    auto *i32 = Type::getInt32Ty(*ctx);
    for (const auto &f : program.funs) {
        std::vector<Type *> args(f->params.size(), i32);
        auto *ft = FunctionType::get(i32, args, false);
        Function::Create(ft, Function::ExternalLinkage,
                         emitName(f->name), *mod);
    }

    for (size_t i = 0; i < program.funs.size(); ++i) {
        const auto &f = program.funs[i];
        cur = f.get();
        genFun(f.get(), resolved.scopes[i].get());
    }

    const FunDecl *mainFun = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFun = f.get();
    if (!mainFun) throw std::runtime_error("program has no main");
    genWrapper(mainFun);
}

void IRGen::genFun(const FunDecl *f, Scope *scope) {
    auto *fn = llvm::cast<Function>(mod->getFunction(emitName(f->name)));
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    // 形参：alloca 槽位 + 存入实参；var 局部：alloca + 零初始化。
    for (size_t j = 0; j < f->params.size(); ++j) {
        const Symbol *s = &scope->table.at(f->params[j]);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, f->params[j]);
        b->CreateStore(fn->getArg(j), slot);
        locals[s] = slot;
    }
    for (const std::string &v : f->vars) {
        const Symbol *s = &scope->table.at(v);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, v);
        b->CreateStore(b->getInt32(0), slot);
        locals[s] = slot;
    }

    stmt(f->body.get());
    b->CreateRet(expr(f->ret->e.get()));
}

Value *IRGen::expr(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e))
        return ConstantInt::get(b->getInt32Ty(), x->v, true);

    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        const Symbol *s = bindings->uses.at(x);
        return b->CreateLoad(b->getInt32Ty(), locals.at(s), x->name);
    }

    if (dynamic_cast<const InputE *>(e))
        return b->CreateCall(rtInput_);

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        Value *l = expr(x->l.get());
        Value *r = expr(x->r.get());
        switch (x->op) {
            case BOp::Add: return b->CreateAdd(l, r);
            case BOp::Sub: return b->CreateSub(l, r);
            case BOp::Mul: return b->CreateMul(l, r);
            case BOp::Div: return b->CreateSDiv(l, r);
            case BOp::Gt: {
                Value *p = b->CreateICmpSGT(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
            case BOp::Eq: {
                Value *p = b->CreateICmpEQ(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
        }
    }

    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        const auto *nameUse = dynamic_cast<const VarRef *>(x->callee.get());
        if (!nameUse)
            throw std::runtime_error("ch12: 间接调用留待第 44 章");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("ch12: 间接调用留待第 44 章");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("ch12: 指针与记录构造留待第 44 章");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        const auto *target = dynamic_cast<const VarRef *>(x->target.get());
        if (!target)
            throw std::runtime_error("ch12: 经指针/字段写入留待第 44 章");
        const Symbol *sym = bindings->uses.at(target);
        b->CreateStore(expr(x->value.get()), locals.at(sym));
        return;
    }

    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        b->CreateCall(rtOutput_, {expr(x->e.get())});
        return;
    }

    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *thenBB = BasicBlock::Create(*ctx, "then", fn);
        auto *elseBB = BasicBlock::Create(*ctx, "else", fn);
        auto *mergeBB = BasicBlock::Create(*ctx, "merge", fn);

        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, thenBB, elseBB);

        b->SetInsertPoint(thenBB);
        stmt(x->then.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);

        b->SetInsertPoint(elseBB);
        if (x->els) {
            stmt(x->els.get());
            if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);
        } else {
            b->CreateBr(mergeBB);
        }
        b->SetInsertPoint(mergeBB);
        return;
    }

    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *header = BasicBlock::Create(*ctx, "wh.cond", fn);
        auto *bodyBB = BasicBlock::Create(*ctx, "wh.body", fn);
        auto *exitBB = BasicBlock::Create(*ctx, "wh.exit", fn);

        b->CreateBr(header);
        b->SetInsertPoint(header);
        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, bodyBB, exitBB);

        b->SetInsertPoint(bodyBB);
        stmt(x->body.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(header);

        b->SetInsertPoint(exitBB);
        return;
    }

    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        for (const auto &st : x->ss) stmt(st.get());
        return;
    }

    if (const auto *x = dynamic_cast<const ReturnS *>(s))
        b->CreateRet(expr(x->e.get()));
}

void IRGen::genWrapper(const FunDecl *mainFun) {
    // C 入口：按 TIP main 形参数目读 input，再调用 tip_main。
    // 不命名为 main——MinGW 目标会向 main 注入对 CRT 符号 __main 的调用。
    auto *fn = Function::Create(FunctionType::get(b->getInt32Ty(), false),
                                Function::ExternalLinkage, "tip_entry", *mod);
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    std::vector<Value *> args;
    for (size_t j = 0; j < mainFun->params.size(); ++j)
        args.push_back(b->CreateCall(rtInput_));
    Value *r = b->CreateCall(mod->getFunction("tip_main"), args);
    b->CreateRet(r);
}

bool IRGen::verify() const {
    std::string err;
    llvm::raw_string_ostream os(err);
    bool bad = llvm::verifyModule(*mod, &os);
    os.str();
    return !bad;
}

std::string IRGen::dump() const {
    std::string out;
    llvm::raw_string_ostream os(out);
    mod->print(os, nullptr);
    return os.str();
}

}  // namespace tip
```

### 54.9.6 前端基础件：ast 与 ast_build 两个文件

第 8 章原样。

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

### 54.9.7 前端基础件：symtab 两个文件

第 10 章原样。

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

### 54.9.8 前端基础件：cfg 两个文件

第 11 章原样；
--check 的
frontend OK 行由它背书。

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

### 54.9.9 前端基础件：pretty 两个文件

打印工具原样。

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

### 54.9.10 期望输出 expected/output.txt

--check 的完整表输出，
30.2 逐列解读的底稿。

```text
; expected: expected/output.txt
== fold.tip ==
frontend OK: 1 function(s) built into CFG
== static analyses and transformations in this tutorial, seen through Galois eyes ==
[1/26] 类型推断 (ch17-20)
    domain       : 类型项（类型变量、函数/记录构造子）上的等价类；无高度、靠合一合并
    direction    : 约束收集后单向合一（合一不动点）
    sensitivity  : 表达式位置敏感；无格序，等价类只增不减
    soundness    : 推断类型与所有使用约束一致：替换后程序不再有类型冲突
[2/26] 符号分析 (ch21-25)
    domain       : 五点符号格 ⊥ ⊏ −,0,+ ⊏ ⊤（每个整型变量一格）
    direction    : 前向工作表，沿 CFG 求最小不动点
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : α(C[[p]]) ⊑ A：具体值符号必在预测格点之下（第 53 章机器检验）
[3/26] 常量传播 (ch25)
    domain       : 平坦常量格 ⊥ ⊏ c₁,c₂,… ⊏ ⊤
    direction    : 前向工作表，强更新 + join 合并
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : 预测为单点 c 的变量，任何具体执行取值恰为 c
[4/26] 活跃变量 (ch26)
    domain       : 2^Var 幂集格（交为 join，全集为 ⊥）
    direction    : 后向工作表：use 生成、def 清除
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : 离开程序点仍活跃的变量，其当前值沿某条后续路径会被使用
[5/26] 可用表达式 (ch26)
    domain       : 2^Expr 幂集格（交为 join，全集为 ⊥）
    direction    : 前向工作表：表达式计算生成、操作数重写清除
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : 集合中的表达式在该点必然已算出且操作数未被改写，可直接复用
[6/26] 区间分析 (ch30-31)
    domain       : 区间格 [l,u]（无限高度，widen 加宽求收敛、narrow 收窄）
    direction    : 前向工作表，循环头处加宽
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : 具体值落在预测区间内；加宽只丢精度不丢可靠性
[7/26] 路径敏感执行 (ch32)
    domain       : 每条路径一个状态；合并即分离（路径条件合取约束状态）
    direction    : 前向，沿展开的路径图（exploded graph）
    sensitivity  : 路径敏感；上下文可配 call-string
    soundness    : 状态在路径条件可满足处有效；假阳性只来自路径合并，永不来自传递
[8/26] IFDS 可达事实 (ch42)
    domain       : 有限事实域 D ∪ {零事实}，D 上幂集
    direction    : 超级图前向 tabulation（路径边制表）
    sensitivity  : 过程间全路径；流函数可分配 ⇒ 完全
    soundness    : 事实沿有效路径可达 ⟺ 表格含该路径边（无假阳性无假阴性）
[9/26] IDE 值流动 (ch43)
    domain       : 事实 × 环境格 L（边缘函数 λ:L→L，常量/恒等/复合闭包）
    direction    : 超级图前向 tabulation，边缘函数沿边复合
    sensitivity  : 过程间全路径 + 事实携带值
    soundness    : 边缘函数求值 ⊒ 真实值变换（三值常量格上机器检验）
[10/26] 0-CFA 闭包流 (ch44)
    domain       : loc → 函数名集合（幂集），缓存即抽象堆
    direction    : 约束系统单调增长（立方工作表）
    sensitivity  : 流不敏感、上下文不敏感（k=0）
    soundness    : 每个调用点的真实 callee 集合 ⊆ 预测集合
[11/26] Andersen 指针 (ch45)
    domain       : 变量 → 分配点集合（包含约束的幂集解）
    direction    : 子集约束闭包（最坏 O(n³) 工作表）
    sensitivity  : 流不敏感；语句顺序无关
    soundness    : 真实指向集合 ⊆ 预测集合；Steensgaard 合并只会更大不会不可靠
[12/26] 到达定值 (ch27)
    domain       : 定值集合（TAC 行号标识）
    direction    : 前向工作表（may：并合并）
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : ud 链必含真实到达者：可能多报、永不漏报
[13/26] 非常忙表达式 (ch27)
    domain       : 表达式键集合（空格分界）
    direction    : 后向工作表（must：交合并）
    sensitivity  : 流敏感；路径与上下文均合并
    soundness    : 集合中的表达式沿每条路径必在操作数改写前被使用
[14/26] 数据流框架 (ch29)
    domain       : 任意半格 + 单调转移函数（may/must/常量三口径）
    direction    : 轮转迭代到最大不动点（MFP）
    sensitivity  : 由实例自定（四大经典全部齐备）
    soundness    : MFP ⊑ MOP：分配性（gen/kill）取等，常量传播严格粗（菱形反例机器检验）
[15/26] 基本块 DAG (ch36)
    domain       : 值图：运算结点 + 名字标签（结点即值）
    direction    : 单遍贪心登记（恒等式折叠 + 交换律规范键）
    sensitivity  : 块内（局部）；不跨块
    soundness    : 多名一结点 = 公共子表达式；恒等式按整数语义逐条成立
[16/26] 循环不变式 (ch37)
    domain       : 指令集合（循环内/外二分）
    direction    : 自然循环识别 + 三判据外提（迭代两轮）
    sensitivity  : 循环级；preheader 为唯一落点
    soundness    : steps 下降 + outputs 不变（解释器对账）；判据缺一即语义翻车
[17/26] 部分冗余消除 (ch39)
    domain       : 表达式集合 × 六个方程（antic/avail/earliest/post/used/latest）
    direction    : 三向方程联立（前向 must + 后向 must + 后向 may）
    sensitivity  : 流敏感；分支几何即优化几何
    soundness    : latest 落点保证安全（操作数必已定值）且至多一算（复用区间）
[18/26] 干涉图着色 (ch48)
    domain       : 变量集合上的干涉图（边 = 活跃重叠）
    direction    : Chaitin–Briggs 压弹栈（度 < k 摘除）
    sensitivity  : 分配级（寄存器压力的画像）
    soundness    : 相邻异色机器逐边校验；溢出如实报告为保守回退
[19/26] 依赖 DAG 调度 (ch50)
    domain       : 指令集合 + RAW/WAR/WAW/MEM 边
    direction    : 关键路径优先表调度（宽度 1/2）
    sensitivity  : 块内；重排不改语义
    soundness    : 重放校验：发射序满足全部依赖（机器证人）
[20/26] 跟踪线性化 (ch14)
    domain       : 块覆盖序（贪心 Algorithm 8.3）
    direction    : 终结符四规则处置（删跳/翻转/补跳）
    sensitivity  : 布局级（块序即布局）
    soundness    : gotos 下降 + outputs 不变（跳转计数与解释器双证人）
[21/26] 控制依赖图 (ch35)
    domain       : 后支配集（逆图支配迭代）
    direction    : FOW 沿后支配树上行
    sensitivity  : 分岔结构（与支配边界对偶）
    soundness    : SSA 三方对账 tac==ssa==back（构造与拆解双向背书）
[22/26] guard 消除 (ch38)
    domain       : 分母的循环不变性/归纳单调性
    direction    : 两规则删 guard（区间推理是完全体）
    sensitivity  : 循环级
    soundness    : guards 下降 + outputs 不变（插入-删除往返无损）
[23/26] 对象派发 (ch46)
    domain       : 类层级 + vtable 槽表（前缀法布局）
    direction    : 虚调用沿 vtable 取槽；静态沿链直呼
    sensitivity  : 0-CFA 口径的静态类型收敛
    soundness    : 目标集 = 全部子类实现（去虚化即收缩）
[24/26] 闭包转换 (ch47)
    domain       : λ 的自由变量集（相对自身参数）
    direction    : 装箱清单 = 捕获集（env 记录上堆）
    sensitivity  : 词法作用域（不可变让抄即共享）
    soundness    : 尾调用栈不增长；need ≤ value 求值计数对账
[25/26] 分支预测/预取 (ch51)
    domain       : 二位饱和状态机 / ⌈延迟/迭代⌉ 距离
    direction    : 静态启发式（后向 taken）；软件预取指令
    sensitivity  : 控制流历史 / 访存流水
    soundness    : 循环命中率 > 乱序（状态序列逐事件可验）
[26/26] 缓存局部性 (ch52)
    domain       : 仿射访问（方向向量 + GCD 检验）
    direction    : 循环交换合法性 + 分块（块内行优先）
    sensitivity  : 迭代空间级
    soundness    : 变换合法 ⟺ 无 '<' 逆序依赖；miss 对比由模拟器对账
```

### 54.9.11 opt 对账 expected/opt/fold.out

六个 IR Dump 头，
30.3.2 的版本敏感契约。

```text
; expected: expected/opt/fold.out
; *** IR Dump After PromotePass on tip_main ***
; *** IR Dump After SCCPPass on tip_main ***
; *** IR Dump After SimplifyCFGPass on tip_main ***
; *** IR Dump After PromotePass on tip_entry ***
; *** IR Dump After SCCPPass on tip_entry ***
; *** IR Dump After SimplifyCFGPass on tip_entry ***
```
