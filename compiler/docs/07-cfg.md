# 第 07 章　控制流图：把"可能的执行"画成图

## 7.1 树回答不了"下一步去哪"

第 05 章得到的 AST 是一棵树，它擅长表达**嵌套**：循环体包含在 while 节点里，
分支语句包含条件与两个子语句。但程序的执行是另一回事——执行是**时序**的，
它只关心一个问题：**执行完这里，下一步去哪？**

拿 TIP 的三种基本构造各问一遍这个问题，树都不能直接给出答案。

- 对 `if (E) S1 else S2`，执行完 `S1` 后不会去执行 `S2`，而是与执行完
  `S2` 一样，去往 if 语句**之后**的位置——两条岔路要在某处**汇合**。
  树只告诉你 `S1`、`S2` 是两个并列子节点，没说它们"之后去哪"。
- 对 `while (E) S`，执行完循环体 `S` 后的下一步不是"后面的语句"，而是
  **回到条件表达式 `E`** 重新判断——这是一条向后指的边，树形结构里根本
  不存在"回去"的方向：树的边永远从父到子。
- 条件为假时，`then` 分支被整个跳过——执行从条件点**直接**去往汇合点。

这三点的共同结论是：需要一种显式表达"下一步关系"的数据结构。把程序中
每个"可能停留的位置"做成**节点**，把"执行可能从这里直接去到那里"做成
**有向边**，所得有向图就是**控制流图（Control Flow Graph，CFG）**。
教材 spa.pdf 第 2.5 节给出的直觉是一条直线：入口节点 → 一条语句 → 一条语句
→ 出口节点；条件让直线**分叉**，循环让分叉**绕回来成环**。本章的工作就是
把这个直觉形式化、构造出来，并论证它对"真实执行"是可靠的。

为什么静态分析需要这张图？因为从第 17 章开始的每一个数据流分析，本质都是
在回答"沿所有可能的路径走到这里时，我们累计知道什么"。"沿路径走"要求
执行的空间是图：循环在图上是环，信息才能一圈一圈地累计；条件在图上是分叉，
信息才会在岔路口合并。没有 CFG，数据流分析没有可以站立的平面。

顺带说明本章与 spa.pdf 叙述顺序的对应与差异，便于读者对照原书。spa.pdf 在
第 2 章介绍语法后立即给出 CFG 作为后续分析的工作对象；本书则用了第 03–06 章
先把文法工程、AST、名字解析逐层做实，才在本章构造 CFG。差异纯粹是工程展开
的需要——spa 以伪代码表述分析、假定前端可得，本书要求每个分析都在真实可构建
的工具链上运行，前端因此必须先行。但 CFG 的形式定义、四种形状、以及它与
"所有路径"语义的关系，本书与 spa 完全一致；读者对照阅读时不会遇到概念分歧。

### 7.1.1 从流程图到 CFG：这个想法的来历

"程序可以画成图"不是静态分析的发明。早期程序设计（1940–50 年代）直接用
**流程图（flowchart）**表达算法：方框是处理步骤、菱形是判断、箭头是控制方向。
流程图就是程序本身；但当高级语言出现，程序以文本书写，图反而需要从文本推导
出来——控制流分析（control-flow analysis）作为一门技术由此诞生，Frances Allen
1970 年的《Control Flow Analysis》系统化了从程序文本构造流图、并在图上做
优化的方法。

本书的 CFG 与流程图有两点本质改进，值得点破。其一，流程图的箭头可以任意
连接（包括乱跳），而我们的图由有限的语法构造按固定规则产生——边的形状是
语言语义决定的，因此可以被归纳证明。其二，流程图不区分函数边界，而我们
每个函数一张图、通过 Entry/Exit 与调用点组合——模块化使分析可以先函数内、
再过程间地逐步加强（第 21 章）。理解这两点，读者就明白为什么后面所有分析
的可靠性都能归结为"构造规则 + 归纳"，而不是对任意箭头逐一核对。

### 7.1.2 在 ite 的 AST 上具体地失败一次

抽象地说"树回答不了下一步"还不够痛，亲手对 ite 的 AST 问一次更能说明问题。
ite 的 AST 形状是：FunDecl(ite) 的 body 指向一个 BlockS，BlockS 的子列表是
`[AssignS(f=1), WhileS]`；WhileS 的 body 又是 BlockS，子列表是
`[AssignS(f=f*n), AssignS(n=n-1)]`。

现在模拟执行到 `n = n-1` 这一步，问 AST："下一个节点是谁？"沿树边能做的
只有：向上回到 WhileS（父），再向上回到外层 BlockS——但父节点没有任何字段
记录"我执行完了该去哪个兄弟"。树能告诉你的是组成关系（WhileS 由条件与体
组成），而问题问的是**时序后继**，两类信息在树里根本不共存。为了回答，
算法不得不做一次"跳出 AST"的推理："我是循环体的最后一条语句，while 语义
规定回到条件表达式"——这条知识属于语言语义，不属于树的遍历。

CFG 的作用正是把这次"跳出推理"的**结果预先固化**：边 `5→3` 替你完成了
那次推理，之后任何消费者（分析器、优化器）只需沿边走，不必重复理解 while
语义。换言之，CFG 是把语义中的"局部后继关系"编译成数据结构；语义只在
构造时被使用一次，之后的全部分析都在结构上进行。这也解释了为什么构造器必须
由懂语义的人写对、并由归纳证明担保——它是语义与所有下游分析之间唯一的
翻译层，错一次，污染全部。

### 7.1.3 本章的两个运行样例

本章所有讨论围绕 `07_cfg/programs/` 下两个小程序展开，先在此完整认识它们，
后文逐一引用，读者不必自己去翻源码。

第一个是 **branch.tip**：函数 `absval` 用 if-else 求参数的绝对值——条件
`x > 0` 为真时 `r = x`，为假时 `r = 0 - x`，最后 `return r`；`main` 读入
一个参数 `x`，调用 `absval(x)`，`output` 结果并返回。它是**分叉与汇合**
的最小标本：absval 的图必然是一张菱形（条件点分出两条边、两个赋值点在
return 前汇合），main 的图则是一条直线（调用在函数内视角下只是一步）。

第二个是 **ite.tip**：函数 `ite` 计算阶乘——`f = 1` 后进入
`while (n>0)`，循环体内 `f = f*n; n = n-1;`，退出后 `return f`。它是**环**
的最小标本：图上必然出现一条从循环体末尾指回条件点的回边，且条件点另有一条
退出边。这个程序在第 08 章还会被真实执行（输入 5 得 120、输入 0 得 1），
本章则只画它的图——但正因为它的执行结果已知，7.11 节可以用真实执行旁证
"图上路径与运行一一吻合"。

选这两个程序而非更大的程序，是教学有意为之：CFG 的全部形状只有四种
（直线、分叉、汇合、环），两个样例恰好各覆盖一半；任何更大程序的图，都只
是这四种形状在不同语句上的重复嵌套。读者若能徒手默画出这两张图，就已经掌握
了本章构造规则的全部内容。

## 7.2 形式化：节点、程序点与函数级图

先给出本章冻结的数据结构定义。

每个节点 `CfgNode` 有三个字段：整数编号 `id`、种类 `kind`、以及一个指向
AST 语句的负载指针 `stmt`。节点种类共六种，前两种与后四种的角色不同：

- **Entry（入口）与 Exit（出口）**标记一次函数调用的边界：执行从 Entry
  开始，到 Exit 结束。它们不对应任何语句，`stmt` 为空。
- **Assign、Output、Branch、Return** 对应函数体中真正"做事"的位置：
  一条赋值、一次输出、一个条件点（if 或 while）、一条返回。

这里有一个值得专门说明的分层：**节点是图上的位置，语句是在那个位置发生的
事情**。同一个位置概念只出现一次（节点），而"做什么"直接复用第 05 章的
AST 语句指针，不重复存储任何文本。节点因此极轻，AST 也无须为画图改动分毫。

每个函数对应一张图 `FunCfg`：记下函数名、入口编号 `entry`、出口编号
`exitNode`、编号到节点的映射 `nodes`，以及边集合 `edges`（边是编号的有序
对）。一个完整程序的 CFG 就是各函数图的序列。

编号（教材称**程序点，program point**）有两个约定。其一，从 **1** 开始，
每个函数独立编号——纯约定，好处是 0 可以在算法内部留作"尚未编号"的哨兵，
输出里也不会出现 0 号点。其二，编号在函数内部才有意义；本章不构造跨函数的
全局编号，第 21 章做过程间分析时再处理函数之间的连接。

关于边，有一个初看奇怪、实则关键的设计：Branch 节点的两条出边**不标注**
哪条是"条件真"、哪条是"条件假"。CFG 只回答一个问题——"可能去哪"；
至于这次执行走哪条，取决于运行时的条件值。把真假标注省掉，图就保持在最简的
"可能性关系"上；能够判定条件真假的分析（如第 18 章常量传播）可以自行忽略
那条不可达的边。这是贯穿全书的分工：**基础结构只提供可能性，额外的信息由
需要它的分析自己算出来。**

还有一个过程间的留白要交代：`a = absval(x)` 在本章的图里只是**一个** Assign
节点——我们不把"跳入被调函数、再跳回来"画进这张图。每个函数一张**函数内
（intraprocedural）**图，调用被当作"一步完成"。第 21 章会把这些图沿调用
关系连接起来，那时 Entry/Exit 节点正是挂边的位置。

### 7.2.1 路径：执行在图上的数学形状

节点与边定义好之后，"执行"这个概念就可以被精确地说成**路径**：一个有限
节点序列 n₀, n₁, …, n_k 称为一条路径，当相邻的每对 (n_i, n_{i+1}) 都是图中
的边。路径可以无限延伸（n₀, n₁, … 没有终点），对应不终止的执行——这正是
图相比树的优势，无限序列在数学上没有任何困难，而树无法表达"无限次绕环"。

由此可以定义一个后面反复使用的概念：程序点 n 的**可达路径集合** Path(n) 是
从 Entry 出发、到 n 结束的**全部**路径。说 n 可达，就是说 Path(n) 非空。
一次具体运行不只是一条路径，它还在每个节点携带当时的状态（各变量的值）；
但路径抽出了"控制位置"这一层，使我们可以暂时忘掉状态、单独讨论控制结构。

数据流分析的全部问题几乎都能改写成对 Path(n) 的量化。"走到 n 时 x 一定是
正数"的精确含义是：**对 Path(n) 中的每一条路径、沿该路径的每一次运行**，
到达 n 时 x 都为正。第 17 章会看到，直接操纵这个"所有路径"的无穷集合
不可行，分析器改用格上的合并运算来一次概括——但那个运算的正确性，始终要
对照这里的 ∀-路径定义来论证。CFG 提供路径，分析提供对路径集合的概括，二者
的接口在本节已经就位。

### 7.2.2 与 LLVM 自己的 CFG 对照

第 08 章生成的 LLVM IR 里其实已经有一张 CFG，值得与本章的图对照，因为它
展示了同一概念的另一种主流表示。LLVM 的图节点是**基本块（BasicBlock）**：
块内是一串直线执行的指令、块的最后一条指令必须是**终结指令**（条件/无条件
跳转或返回）。对照 `ite.tip` 的 IR：

- `entry` 块以 `br label %wh.cond` 结尾（无条件跳转）；
- `wh.cond` 块算出条件后以 `br i1 %3, label %wh.body, label %wh.exit` 结尾
  （条件分叉）；
- `wh.body` 块以 `br label %wh.cond` 结尾（回边）；
- `wh.exit` 块以 `ret` 结尾。

与我们的表示相比有两处差异。其一，LLVM 没有独立的"条件节点"——条件的
计算与分叉分别是块内最后一条普通指令和终结指令，合起来对应我们的一个 Branch
节点。其二，LLVM 把许多条直线指令收在同一个块里，而我们的每条语句独占一个
节点。可以给两种表示一个精确的联系：**基本块是直线程序点按"中间无分叉"
划分的等价类**——把我们图上每条最长的无分叉路径压成一个点，就得到 LLVM
风格的块图；反过来把块按指令展开，就回到我们的细粒度图。

本书选择语句粒度的理由是教学上的：TIP 语句种类少、每步只做一件事，让每个
"可能位置"都可见、可编号、可在上面单独放置分析结果；而工业编译器需要压缩
表示以减少节点与边的数量。理解了这层同构，读者阅读 LLVM 的 `opt -passes=*`
输出时就能把块图直接翻译回本章的程序点图，后面与工业分析（SCCP 等）对照时
不会因表示不同而误判分析结果的差异。

### 7.2.3 三层"程序图"不要混淆

本书到目前为止出现了三种描述程序的图，它们的节点与边各不相同，提前分清可以
避免后面章节错用。

- **AST**：节点是语法构造，边是"包含"（父到子），无环；回答"程序由什么
  组成"。
- **函数内 CFG（本章）**：节点是程序点，边是"控制可能直接转移"，可以有
  环；回答"执行在一个函数内部怎么流动"。
- **调用图（第 21 章才建立）**：节点是函数，边是"谁调用谁"；回答"控制
  在函数之间怎么流动"。

本章的 `Cfg` 把各函数图按 **AST 中的函数声明顺序**排列，纯粹是列表顺序，不含
函数之间的边。main 的图中节点 2 写着 `(call absval x)`，但从 main 的图到
absval 的图**没有边**——那条信息此刻只作为语句文本存在；第 21 章扫描全部
CallE 节点、把调用点与被调函数的 Entry/Exit 连起来，才得到过程间的完整结构。
坚持先分层、再连接，是因为大部分分析在函数内就能完成，过早合并会让所有图都
背上过程间的复杂度。

### 7.2.4 为什么每个函数恰好一张图：粒度选择的论证

"每个函数一张图"也可以有别的选择，值得把替代方案与取舍说清楚，因为这
关系到第 21–24 章过程间分析的全部展开方式。

替代方案一是**全程序一张图**：把所有函数的节点放进同一编号空间，调用点
直接连到被调函数入口。问题在 TIP 支持**一等函数**（函数可作为值传递，调用
目标运行时才确定）：在做指针/函数分析（第 27 章）之前，很多调用点根本无法
确定目标函数，图就无从连起。方案一让"画图"依赖"最难的分析"，形成死锁。

替代方案二是**每个基本块一张图（无函数边界）**：彻底放弃函数概念。这会
丢掉作用域与参数边界信息，所有变量成为全局名字——第 06 章辛苦建立的绑定
无法在图上定位，分析精度与实现简洁性双输。

本章的方案——函数内图 + 调用点原子化——打破死锁的方式是分层：**先用零
过程间信息构造函数内图（永远可行，因为不依赖调用目标），再让过程间分析逐步
决定如何沿调用关系连接它们**。第 21 章的上下文不敏感分析给出最粗的连接
（调用点连所有可能目标），第 22–24 章逐步加上调用串上下文以恢复精度。每
一层分析都复用上一层的图，而不是推倒重来。这就是"每函数一图"真正的论证：
它不是语言的强制，而是让"可构造性"与"可逐步加精"同时成立的唯一粒度。

## 7.3 构造的总原则：先编号，再连边

构造 CFG 最直接的想法是"边遍历 AST 边建节点、边连边"。这个想法在遇到循环
前都工作，但一动手就会发现编号乱了：为了连一条语句的出边，必须先知道它的
后继节点，于是我们会**先访问后面的语句**——后继的编号反而比前驱小，节点编号
不再按源码顺序排列。对 while 更尴尬：回边指向的条件点必须在循环体之前就存在。

本书用一个干净的两遍构造解决，其原理是把"发号"与"连边"两件事彻底分开：

1. **第一遍编号**：对 AST 做一次纯粹的先序遍历，按**源码出现顺序**给每个
   需要节点的语句发一个编号。这一遍完全不看边。
2. **第二遍连边**：从函数尾部的 return 节点开始，**倒着**把"后继关系"
   穿起来。这一遍编号已定，只负责连边。

两遍的接口是第二遍中那个贯穿始终的返回值——`wireStmt(s, succ)` 返回
**进入语句 `s` 时首先到达的程序点集合**，而参数 `succ` 是"`s` 执行完后
要去的位置"。换句话说，连边从句子的**出口侧**往**入口侧**倒推：告诉一条
语句"你的后面是这些点"，它内部连好边后回答"那么进入我时先到这些点"。
这个"后继集合 → 入口集合"的函数是整个算法的核心，7.5 节逐构造展开。

为什么第一遍必须是先序？因为编号是输出契约的一部分（`expected/output.txt`
逐字节对账），而"按源码顺序"是读者阅读节点列表时唯一自然的预期。先编号
之后，第二遍无论以什么顺序访问语句，都不会再破坏这个顺序。

两遍分离还带来一个实现层面的切实好处：**每一遍的失败模式单一、可单独测试**。
第一遍只可能错在"漏编号或编号顺序"，用一张"语句 → 期望编号"表即可核对
（7.9.1、7.9.3 的编号表正是这种核对的产物）；第二遍只可能错在"边"，用边
集合核对。若两遍交织，一次错误的输出会同时暴露编号与边的混乱，定位要困难
得多。把一条复杂的不变量拆成两个各自平凡的不变量，与 7.6 节"单一事实
来源"、7.9.2 节"选最简单表示"是同一种工程美学：**让每个组件只对一件事
负责，组件间的接口窄到可以写在一行里**（wireStmt 的签名即此接口）。

还可以从依赖的角度重述这个设计。第一遍产出的 stmtId_ 表是第二遍的只读输入；
第二遍不调用任何"发号"操作。这意味着两遍之间没有环依赖——数据流严格单向，
因而可以分别替换：将来想换一套编号规则（例如改成基本块编号），只动第一遍；
想加新的边（例如异常边），只动第二遍。本书虽不做这些替换，但让"可替换"
免费可得的接口形状，正是好设计与坏设计的分界。

## 7.4 第一遍：哪些构造产生节点

第一遍的编号规则对应"执行会在哪些位置停留"，逐一列出。

- **块 `BlockS` 不产生节点**。这是第一个反直觉点：花括号在执行中不是一个
  停留位置，执行穿过块时不停留，所以 CfgNode 的六种里没有 Block。遍历时
  直接进入块内语句，块是"透明"的。
- **if**：产生**一个** Branch 节点（条件点），然后继续编号 then 与 else
  两个分支内部的语句。注意：整个 if 只有条件点是图上的分叉位置。
- **while**：同样产生**一个** Branch 节点（条件点），但只继续编号循环体；
  条件为假后的"出口位置"不在 while 内部，编号阶段无须知道它。
- **赋值与输出**：各产生一个节点（Assign/Output）。

第一遍同时维护一张映射 `stmtId_`：语句指针 → 它的编号。第二遍遇到某条已经
见过的语句时（典型就是 while 的条件点，循环体要连回它），通过这张表查到
编号，而不必重新建节点。函数级的 Entry 在遍历前编号、Return 与 Exit 在遍历
后编号，于是节点在列表中的排列固定为：entry → 体内语句（按源码序）→ return
→ exit。

### 7.4.1 编号承诺什么，又不承诺什么

编号看似机械，它的形式性质却被后续分析依赖，值得明确列出。

编号**承诺**三件事。第一，**唯一性**：函数内每个需要停留的位置恰好得到一个
编号，stmtId_ 中不冲突——addNode 只发新号、不复用。第二，**先序性**：若
源码中位置 p 出现在 q 之前，则 id(p) < id(q)。这一性质在分支处细化为：
then 分支内全部编号小于 else 分支内全部编号（numberStmt 先遍历 then），体内
全部编号在循环头之后。第三，**完备性**：执行会停留的每个位置都在编号表里，
不存在"走到一个没有编号的语句"的可能——这由第一遍对五种语句的穷尽分派
保证。

编号**不承诺**两件事，误信会导致算法错误。其一，编号**不是**关于边的拓扑序：
回边 `5→3` 公然从大号指向小号，任何假设"后继编号更大"的处理都会在循环上
失败。其二，编号**不跨函数连续**：每个函数都从 1 重新开始，"ite 的 3 号点"
与"main 的 3 号点"毫无关系，跨函数引用必须带函数名（第 21 章的做法）。

这组承诺与不承诺，本质上是 7.2 节"图只提供最小信息"在编号层面的复述：
编号只负责按源码序给位置命名，方向与环的全部信息都在边里。

### 7.4.2 为什么表达式不编号，而 Entry/Exit 要编号

第一遍规则里有两个看似不对称的决定，值得专门论证：表达式**不**给节点，
Entry/Exit **却**给节点。

表达式不编号，是因为"执行停留的位置"在 TIP 语义中只在**语句边界**存在。
求值 `f * n + 1` 的过程中，机器内部当然有中间步骤，但语言语义把"求一个
表达式的值"定义为一步原子操作：没有任何语法手段能让控制在表达式中途分叉
或跳出（无短路、无异常抛出、表达式中不允许调用以外的语句）。给这些中间步骤
编号，就是在图上添加语义中不存在的位置，后续分析反而无法回答"那个点上
语句是什么"。一句话：**节点的粒度由语言语义中可观察的控制位置决定，不由
实现的内部步骤决定。**

Entry/Exit 编号，则是因为函数调用在第 21 章要成为**可连接的端点**。设想
没有这两个点：函数图只有体内节点，那么"调用点连到函数的哪里、函数返回连
回哪里"就只能回答"连到体内第一个/最后一个语句"——但函数体可能为空、
可能以 return 提前结束，"第一个语句"未必存在。Entry/Exit 把这两个端点
**实体化**：任何函数，无论体是什么形状，入口与出口都确定存在且唯一。它们
是图上的零语句节点，作用同网络协议里的"端口"——为跨边界的连接提供一个
稳定的、与内部结构无关的锚点。

把这两个决定并置，可见编号规则遵循一条统一的判据：**一个位置被编号，当且
仅当它要么是一次语句执行（语义中的原子控制步骤），要么是一个将来要被边连接
的边界端点。** 表达式既非语句边界、也非连接端点，故不编号；块只是语句的
容器、同样不新增位置，故透明穿过。这条判据在第 27 章扩展指针语句时还会被
再次使用：每新增一种语句，只需回答"它是不是一个新的原子停留位置"。

## 7.5 第二遍：后继如何被穿起来（核心）

第二遍是本章算法最值得细读的部分。统一形式是

> `wireStmt(s, succ)`：已知语句 `s` 执行完后去往 `succ` 这组程序点，
> 在 `s` 内部连好全部边，返回进入 `s` 时首先到达的程序点集合。

下面按构造逐一说明规则，每一条都可以在脑中模拟一次执行来核对。读这部分时
有一个统一的抓手：不要从"代码怎么写"出发，而要始终问两个语义问题——
"进入这个构造时控制在哪里？""它执行完后控制可能被交还给谁？"两个答案
确定后，边只是把答案画出来。规则一旦从语义推出，代码就是规则的逐行翻译，
反过来背诵代码则无法应对任何新构造。这也是本节把规则写在代码嵌入（7.10 节）
之前的原因。

**直线语句（赋值、输出）**：执行它，然后去它的后继。所以只有一条边
"本节点 → succ"，返回本节点自己。这是最简单的情形，也是其他构造折叠到
最后的形状。

**块**：块不停留，只做顺序拼接。做法是从块内**最后一条**语句开始，把
`succ` 交给它，拿回它的入口点；再把这组入口点交给倒数第二条语句……如此
从尾向头折叠，最终返回块内**第一条**语句的入口点。这正是"顺序执行"的
形状：每条语句的后继恰是下一条语句的入口。空块没有语句可折叠，原样返回
`succ`——后继关系直接穿过空块，这就是"透传"。

**if**：设条件点编号为 n。then 与 else 两个分支执行完后去往**同一个**
汇合点 `succ`，所以分别把 `succ` 交给两个分支、各自连好内部的边，拿回
两个分支的入口点；条件点 n 向这两组入口点各连一条边。没有 else 时，条件
为假的执行应当**直接**到达汇合点，所以除了连 then 的入口，还让条件点 n
直连 `succ`。最后返回 n：进入 if 就是先到达条件点。

**while**：设条件点（循环头）为 n。这里 `succ` 是条件为假、退出循环后
要去的位置，而循环体执行完后不是去 `succ`，而是**回到 n**。因此把后继
`{n}` 交给循环体，连好体内的边并拿回循环体的入口点；然后条件点 n 连向
循环体入口（条件真），**同时**连向 `succ`（条件假）。循环体为空时，交给
它的后继 `{n}` 没有任何语句接收，拿回的入口集合为空——此时让条件点连一条
指向**自己**的边，精确表达"条件为真时无处可去、只能重新判断"，即空体
while 是死循环。返回 n：进入 while 先到条件点。

函数级的收尾在两遍之外：把 return 节点的后继设为 Exit（唯一一条
return→exit 边），再把整个函数体的入口集合与 Entry 相连。若函数体是空块，
穿回来的入口集合为空，就让 Entry 直连 return 节点——空函数体仍然合法。

### 7.5.1 规则总表：每个构造连什么、返回什么

上面的文字规则浓缩为下表，日后实现新语言构造时可以对照检查"内部边、后继、
入口"三项是否都已确定。

| 构造 | 内部新增的边 | 交给子构造的后继 | 返回的入口集合 |
|---|---|---|---|
| 赋值/输出 | 本点 → succ | —（无子构造） | {本点} |
| 块 | 无（块无节点） | 逆序折叠：后一条的入口即前一条的后继 | 首条语句的入口；空块返回 succ |
| if | 条件点 → 两分支入口；无 else 时条件点 → succ | 两分支都收到同一个汇合点 succ | {条件点} |
| while | 循环头 → 体入口；循环头 → succ | 循环体收到后继 {循环头} | {循环头}；空体时头连头 |
| 函数（外层） | entry → 体入口；return → exit | 函数体收到后继 {return} | — |

表中每一行都可以用一句话验证：**真实执行在这个构造内部可能走的每一步，都
对应表中一条边；执行离开构造时，落点恰是收到的后继。** 这句话正是 7.8 节
归纳证明在每个分支上要检查的内容——表格不是速查装饰，它就是证明义务的清单。

特别对照三种容易写错的边界：空块（第二行末列，原样透传）、if 无 else
（第三行，条件点必须亲自补一条到汇合点的边）、while 空体（第四行，以自环
代替"体入口"）。三个边界都是"子构造不存在"时退化出的形状，7.9.1 节的
手工模拟则展示了非退化情形的完整过程。

### 7.5.2 为什么后继始终是"集合"而不是"一个点"

wireStmt 的后继参数类型是节点编号的**集合**，即使在直线程序里它只含一个
元素。这个选择不是泛型癖，而是被三种真实形状逼出来的。

- **汇合点的共享**：if 的两个分支收到同一个 succ 集合；若 succ 本身只有
  一个点，两个分支就都连向它，这正是菱形的底尖。用集合表达"多个来源汇入
  同一组点"无需任何特殊情形。
- **空集合的语义**：空体 while 把 `{n}` 交给空体后拿回**空集**，这个空集
  是触发"自环"退化规则的信号。若接口只有"一个点"，就不得不用哨兵编号
  或可空类型表达"没有入口"，而哨兵恰恰是 7.2 节编号约定想留给算法内部的
  资源；用空集表达"无"最干净。
- **未来语言的多后继**：C 风格的 `goto`、算法语言的 `break/continue` 会
  让一条语句的后继天然是多个点。集合接口在扩展时无须改动既有全部规则。

集合上也隐去了顺序：wireStmt 不依赖 succ 中元素的排列，边的最终顺序统一
由 7.6 节的 `std::set` 决定。于是第二遍连边可以按任何递归次序展开（本书
从尾部倒推，仅因为这是穿起后继最自然的方向），输出不受影响。接口中"集合"
一词同时承诺了三件事：后继可多个、可为零、次序无关——这三件事使规则表
（7.5.1）的每一行都能用同一种记号书写。

## 7.6 边为什么要去重并排序

连边结束后，算法把全部边收集进 `std::set`，再取回成有序列表。这一步同时
服务语义与输出两层要求。

语义上，**重复的边不携带任何信息**："执行可能从 2 到 4"说一遍与说两遍
完全等价——CFG 的边表达的是"存在一种可能"，这是个是非判断，没有次数。
重复边只可能来自多条规则恰好覆盖同一种转移（如空体自环、或分支汇合），
应当合并。

输出上，`std::set` 让边按 `(起点, 终点)` 字典序排列。本章所有程序的图都
被逐字节对账，边列表的顺序必须是确定的；排序之后，即使连边的遍历次序将来
调整，输出也不受影响。

### 7.6.1 支配关系：如何从图里识别循环

构造出带环的图后，自然要问：算法如何判断哪些边构成循环？这个问题的标准答案
依赖**支配（dominance）**概念：节点 d 支配节点 n，当且仅当从 Entry 到 n 的
**每一条**路径都经过 d。Entry 支配所有节点，每个节点支配它自己。在 ite.tip
的图上，节点 3 支配 4、5（到达它们必须先过循环头），但不支配 6——因为路径
`1→2→3→6` 表明不经 4、5 也能到 6。

有了支配，**回边（back edge）**定义为满足"终点支配起点"的边 a→b。ite 图中
`5→3` 是回边（3 支配 5），而 `3→6` 不是（6 不支配 3）。每条回边对应一个
**自然循环（natural loop）**：循环头是 b，循环体是"不经过 b 就能到达 a"的
全部节点加上 a、b 自己。这个定义之所以重要，是因为它给出的循环结构唯一、
且嵌套关系良序——工业编译器（LLVM 的 LoopInfo、GCC）都以它识别循环、安排
循环优化。

本章不实现支配分析：数据流框架（第 17 章起）直接在带环图上工作到不动点即可，
无须先识别循环——这是有意的 YAGNI。但支配概念在此先建立，有两个后用之处：
第 18 章讨论不可达边与循环优化对照时会用到，而理解"循环头是进入循环的唯一
入口"也有助于读懂 while 在 wireStmt 中的连边规则——节点 3 支配循环体，
正是"进入体必先经过条件点"这一事实的形式表达。

#### 支配关系如何实际计算

支配的定义用了"每一条路径"，字面上要枚举路径——但它本身可以作为一个
数据流问题高效求解，这里给出其方程形状，作为第 17 章数据流框架的一次
"预演"，读者此刻只需感受方程的形式。

设 Dom(n) 为支配 n 的节点集合。Entry 的支配集只含自己：
Dom(Entry) = {Entry}；对其他节点 n：

> Dom(n) = {n} ∪ ⋂_{p ∈ pred(n)} Dom(p)

含义直观：一个点支配 n，要么它就是 n 自己，要么它必须支配 n 的**每一个**
前驱——因为到达 n 的路径必经某个前驱，若有一个前驱不被 d 支配，就存在一条
绕过 d 的路径。这是一组联立方程（n 的答案依赖前驱的答案），循环处形成环，
用第 16 章的不动点迭代求解：先把所有 Dom(n) 初始化为"全部节点"，再反复
按方程收缩，直到一轮中不再变化。

在 ite 图上迭代会稳定为：Dom(1)={1}，Dom(2)={1,2}，Dom(3)={1,2,3}，
Dom(4)={1,2,3,4}，Dom(5)={1,2,3,4,5}，Dom(6)={1,2,3,6}，
Dom(7)={1,2,3,6,7}。对照定义验证节点 6：前驱 3 与 5 的支配集之交是
{1,2,3}，加上自己恰得 {1,2,3,6}——4、5 不在其中，这就是"3 不支配 6"
的算法来源。这个例子也提前展示了数据流分析的两大母题：**方程从语义定义
机械导出，答案靠不动点迭代求得**；第 17 章起的每个分析都是同一模式更换
格的定义。

### 7.6.2 一个最小的去重实例

去重规则听起来平凡，用一个具体情形核对可以确认它确实会被触发。考虑空体
while：wireStmt 对空体拿回空的体入口集合，按退化规则连一条条件点指向自己的
边；同时函数级外层若以同一条件点作为 succ 的一部分，规则可能第二次请求同一条
自环。集合中同一有序对只保留一份，输出里就恰好出现一次 `n -> n`。没有去重
时，输出会因"规则被触发的次数"而变化——而那个次数只是实现细节，与语义
无关。

更一般地，去重把边集合从"规则调用的轨迹"（multiset，含次数、含顺序）变成
"可能性的关系"（set，无次数、有确定序）。这两个集合的差别对应两个不同的
问题："这条边被几条规则覆盖"与"这条边存不存在"。CFG 回答且只回答后者；
前者在调试规则时也许有趣，但不应进入图的定义。坚持这一区分，图就能保持为
一个纯粹的数学关系，可以直接被集合运算（交、并、可达性）操纵——第 17 章的
数据流方程在节点集合上书写，前提正是边不携带次数。

## 7.7 图节点的文字：复用第 05 章的打印器

图构造出来还需要让人读懂。打印一个函数时，每个节点先输出编号与种类名；
若节点负载着语句（Assign/Output/Branch/Return），再把语句打印在同一行后面。
语句的打印直接调用第 05 章 pretty-printer 的单行接口 `printStmtLine`，
没有为 CFG 重新发明任何打印逻辑。

Branch 节点是多行的：`printStmtLine` 作用在 IfS 或 WhileS 上，会把完整的
条件语句（条件、then、else/循环体）按缩进打印出来，所以在节点列表里，一个
branch 节点会占若干行。这样安排的好处是读者看到分支点时，同时能看到它守卫
的是哪些语句——图的"位置"与程序的"文本"在同一处对上。这正是 7.2 节
坚持"节点负载语句指针"的回报：打印图时，AST 是唯一的文本来源。

### 7.7.1 图的结构不变量：构造代码的自检清单

除了语义层面的可靠性，构造代码还应维护一组纯结构性的不变量，它们可以在不运行
程序的情况下被机械检查，是发现实现错误的廉价防线。值得逐条列出并说明来源。

- **端点存在且唯一**：每张图恰有一个 entry、一个 exitNode，二者都在 nodes 中。
  来源是 7.4 节函数级补编号的固定流程。
- **边的两端合法**：每条边 (a,b) 的 a、b 都是本函数 nodes 中存在的编号——
  不允许悬空边，也不允许跨函数引用。这是 addEdge 只接受已编号节点的后果。
- **出度形状**：exit 出度为 0；entry 与直线语句出度为 1；branch 出度为 2。
  这一不变量直接复述执行可能性的数目（7.12 节的反向检查），任何出度为 0 的
  非 exit 节点都意味着某条执行路径被"截断"，是漏连边的典型信号。
- **可达性**：从 entry 出发，除 exit 外的所有节点都应可达。这条比前几条弱
  一些——本章规则不产生因条件恒假而不可达的节点（每个节点都由某条语法路径
  可达），所以"全部可达"在本章是不变量；扩展到更激进的变换后才可能被打破。

这些不变量与可靠性的关系要分清：它们是可靠性的**必要非充分条件**——满足全部
不变量的图仍可能连错边（比如把回边连到错误的点，出度仍是 2）。它们的价值
在于几乎零成本：遍历一次边表即可核对，且经验上能截获绝大多数笔误。本章没有
把它们写成独立的校验器（YAGNI：编译期类型系统 + 逐字节输出对账已覆盖同类
错误），但第 17 章建立分析框架时，"先验证结构性质、再求解"会成为标准动作。

## 7.8 正确性论证：CFG 对真实执行可靠

本章要保证的性质可以一句话陈述：

> **对任意输入，程序的任何一次真实运行，它经过的节点序列都对应图上的一条
> 路径——即运行中每一次"从一个程序点到下一个程序点"的转移，图中都有边。**

这叫 CFG 的**可靠性**。注意它与第 02 章"可靠但不完备"的概念完全对接：
我们只声称"真实的转移都在图里"，不声称"图上的路径都能真实发生"。

论证对语句结构做**结构归纳**。归纳假设：对一条语句的所有子语句，其内部真实
执行的转移都不脱离子语句自己连好的边。在此假设下逐构造检查：

- **赋值/输出（基础情形）**：执行只有一种走向——做完后去它的后继，而图中
  恰有一条到后继的边。成立。
- **块**：一次块执行依次经过各语句。相邻语句之间，后一条的入口正是前一条
  折叠时拿到的后继，有边；首尾由归纳假设覆盖。成立。
- **if**：真实运行只可能走条件的一个分支。条件点与两个分支入口都有边
  （无 else 时条件点直连汇合点），两个分支执行完都到汇合点 `succ`，有边。
  所以无论这次条件真假，路径都在图上。成立。
- **while**：每次判断后二选一——为真则进入循环体，而体执行完回到条件点
  有边；为假则退出，条件点到 `succ` 有边。无论迭代多少次，每次往返都在
  图上。成立。

由这四种构造归纳到函数级：Entry 与函数体入口相连、return 与 Exit 相连，
于是一次从进入函数到离开函数的完整运行，全程都在图的某条路径上。

**反向不成立**，而且这正是我们想要的：if 的两条出边都画出，即使某次运行
条件恒真、另一条边永不被走；while 的退出边画出，即使循环实际上是死循环。
图包含**可能路径的超集**。多画的边不会让任何真实运行脱离图，却给后续分析
留出了"万一"的空间——数据流分析在超集上工作，结论因此对所有真实运行成立，
代价只是对不可达路径做了无用功。可靠性与精度的这层取舍，本书后面会反复遇到。

### 7.8.1 CFG 有意不建模的三类流动

说清一张图包含什么，同样要说清它有意排除什么，否则后续分析容易把图当作
"执行的完整描述"而做出过强假设。本章的 CFG 不建模三类流动。

- **表达式内部没有控制流**。TIP 表达式没有副作用：`input` 之外，子表达式
  的求值次序不影响结果，语言也没有短路求值（`a > b` 中两边都会被求值）。
  因此求值一个任意复杂的表达式只是"一步"，无须为它画节点与边。若语言含
  短路的 `&&`，`a && b` 就必须展开成条件分叉——这是语言设计改变 CFG 形状
  的典型例子，值得记住。
- **异常与中断流动不建模**。TIP 中除数为零在语义上使程序进入错误状态，但
  本章的图把除法当作普通一步、不画"出错边"。依赖此图的分析若要检测除零
  （第 18 章会做），必须自己在除法节点附加判断，而不能假设图已把该路径
  分离出去。
- **调用内部不建模**：如 7.2 节所述，调用是一个节点；被调函数内部的路径
  不在本图内。

这三条统一在一个原则下：**CFG 只表达语言中由语法构造显式决定的正常控制转移**。
任何额外的流动要么在语言中不存在，要么留给专门的分析与后续章节。这个克制的
边界让本章的归纳证明简洁——需要覆盖的构造种类是有限、可见的五种语句，而不
是一个不断膨胀的"所有可能出事的地方"清单。

### 7.8.2 论证的形式陈述：边与小步转移的对应

7.8 节的归纳论证用自然语言给出，这里把它写成更形式化的形状，便于读者对照
教材 spa.pdf 的论证风格，也为第 09 章以后更复杂的可靠性证明预热。

设程序的**小步语义**是配置之间的转移关系：配置是"当前所处的语法位置 +
状态 σ（变量到值的映射）"，一步转移记作 (p, σ) → (p′, σ′)，描述执行一步
后位置与状态如何变化。对每条语句 s，形式地划定它的**入口位置** Ent(s)
（控制刚进入 s 时所在的语法点）与**出口事件** Exit(s)（s 执行完毕、控制权
交还外层）。我们要对每个 s 证明命题 R(s)：

1. 从 Ent(s) 出发的每一小步，只要控制尚未离开 s，它在 CFG 上对应的两个程序
   点之间都有边；
2. 控制通过 Exit(s) 离开时，它到达的程序点恰是 wireStmt 收到的后继集合中的
   某个点；
3. 状态的变化（σ 与 σ′ 的差别）只发生在该语句语义规定的变量上——这一条
   保证 CFG 虽不携带状态，却不会遗漏状态相关的分叉（所有分叉都来自显式条件）。

R(s) 的证明对 s 的结构归纳：五种语法构造恰为五种情形，每种情形中，小步语义
规定的转移可以逐一与 7.5.1 表格里的边配对——这就是归纳步骤的全部内容。
得到 R(s) 后，对函数体应用一次，再配上 entry 与 return→exit 两条外层边，
即得 7.8 节的结论：**任何运行诱导的路径都是图上路径**。

形式化同时把**不完备**说得同样精确：图上的一条边不承诺存在一个状态 σ 使
相应的小步转移真正发生——边的定义是 ∃-形状的语法可能性（"条件取这个分支
在语法上允许"），而非 ∃-形状的可实现性（"存在状态使条件取这个分支"）。
可靠方向（运行 ⊆ 图）与缺口方向（图 ⊄ 运行）在同一套记号下各归其位，这一
书写模式——小步关系作具体侧、结构规则作抽象侧、归纳连接两侧——第 17 章
论证分析可靠性时将原样复用，只是抽象侧换成格元素。

### 7.8.3 可靠性论证的方法论意义

值得停一步指出，CFG 的可靠性证明是全书后续所有可靠性证明的"模板"，看清
它的结构，比记住结论本身更重要。这个证明有三个可分离的部件。

- **具体侧（concrete side）**：被近似的对象——这里是小步执行诱导的节点
  序列。具体侧的定义回答"什么是真实"。
- **抽象侧（abstract side）**：构造出来的数学对象——这里是节点与边的集合。
  抽象侧的定义回答"我们声称知道什么"。
- **连接两侧的关系**：这里是"诱导序列是图上路径"的包含关系；其证明用
  结构归纳，每一步检查"具体侧的一次转移在抽象侧都有对应"。

第 17 章做符号分析时，这三个部件会原样重现：具体侧是运行中变量的实际值
集合，抽象侧是 `{+,−,0}` 的子集，连接关系是"实际值落在抽象集合内"；证明
同样逐构造检查。抽象解释（Abstract Interpretation）理论把这一模式发展成
完整数学——具体域与抽象域之间的伽洛夫连接（Galois connection）、传递函数
的单调性保证——第 20 章会正式建立。本章没有这些术语，但读者已经在最简形式
下见过了全部思想：**所谓可靠的分析，就是构造一个抽象对象，并证明任何具体
执行都不脱离它所声称的范围。**

也正因为模板在此已立，本书后面遇到更复杂的分析（区间、指针、0-CFA）时，
论证虽长，骨架不会变：换具体域、换抽象域、逐构造检查对应关系。读者可以把
"这次的具体侧、抽象侧、连接关系是什么"作为阅读每个分析章节的固定三问。

## 7.9 工程注意点

以下五条都是原理落地时的具体注意，不是与原理并列的"坑"清单：每条都能
回溯到本章已证的形式性质。

- **构造 CFG 是纯函数**：输入不可变 AST、输出一个新的 Cfg，不修改 AST、不
  依赖外部状态。因此它可以在同一份 AST 上被反复调用，结果一致；这同时使
  构造天然可并行（不同函数互不影响）、可缓存。
- **节点负载用裸指针、不拥有语句**：AST 的寿命覆盖全部分析且节点地址稳定
  （第 05 章结论），图无须参与释放，只保存索引。
- **程序点编号只在函数内有效**：需要跨函数标识位置时不要复用这个整数，第
  21 章会引入函数维度。
- **边不标注真假、不记录次数**：保持"可能性关系"的最简形状，真假判定交给
  有能力的分析。
- **打印格式即输出契约**：节点行、多行 branch、边列表均逐字节对账，改动
  cfg.cpp 的打印必须同步更新 expected。

### 7.9.1 手工模拟：在 ite 上跑一遍两遍算法

算法读起来抽象，手工模拟一次就能看清"倒向线程"到底在做什么。以 ite 函数
为例，函数体是两条语句：赋值 `f=1` 与 while；while 体是两条赋值。

**第一遍编号**只沿 AST 向下走，产出如下对应表，顺序即源码出现顺序：

| 编号 | 种类 | 来源 |
|---|---|---|
| 1 | entry | 函数入口 |
| 2 | assign | `f = 1` |
| 3 | branch | while 的条件点 |
| 4 | assign | `f = f * n` |
| 5 | assign | `n = n - 1` |
| 6 | return | `return f` |
| 7 | exit | 函数出口 |

注意 while 之后没有语句，编号 6（return）与 7（exit）在函数级补上。

**第二遍连边**从 return 节点的后继开始，按代码里的实际调用次序展开。
缩进表示嵌套调用，每行给出这一步连的边与返回的入口集合：

1. 函数级先确定 `6 → 7`，对函数体块调用 `wireStmt(块, {6})`。
2. 块从最后一个子语句倒着折叠，先处理 while：`wireStmt(while, {6})`。
3. while 对其循环体块调用 `wireStmt(体块, {3})`——体的后继是循环头 3。
4. 体块倒序处理 `n=n-1`：连 `5 → 3`，返回 {5}。
5. 再处理 `f=f*n`：连 `4 → 5`，返回 {4}；体块返回 {4}。
6. 回到 while：bodyEntries={4} 非空，连 `3 → 4`（条件真）；再连
   `3 → 6`（条件假）；返回 {3}。
7. 回到函数体块，处理第一个子语句 `f=1`：连 `2 → 3`，返回 {2}；块返回 {2}。
8. 函数级最后连 `1 → 2`。

得到的边按生成顺序是 `6→7, 5→3, 4→5, 3→4, 3→6, 2→3, 1→2`；经 `std::set`
去重排序后，正是输出中 `1→2, 2→3, 3→4, 3→6, 4→5, 5→3, 6→7` 的列表。
模拟揭示了 wireStmt 的本质：**每一层只关心"我的后继是谁"，递归返回后本层
只补"我连向谁"**——顺序语句由折叠方向保证、汇合点由共享同一 succ 保证、
回边由 while 层把后继强制改成 {3} 保证。三种边都是同一条规则的局部应用。

### 7.9.2 表示法的取舍：边集合、邻接表与基本块

冻结实现前比较过三种图表示，各自的代价值得说明。

- **边集合（本章所用）**：全部边存在一个有序对列表中，节点存在映射中。
  求某节点的后继需要扫描全部边。结构最少、只有一处事实来源，不会出现
  "edges 与 succ 表不一致"这类内部矛盾。
- **succ/pred 邻接表**：每个节点直接存后继、前驱向量，查询 O(出度)，是
  数据流分析最顺手的形状。代价是双重存储：加一条边要同时更新两张表，任何
  漏更新都是静默错误。
- **基本块 + 终结指令（LLVM 风格）**：节点数最少，但构造时需要判断"哪些
  语句必须成为块边界"，打印与编号都更复杂。

本章的选择是让**构造期**用最简单的边集合（单一事实来源、便于去重排序），
而把"按需派生邻接表"的自由留给具体分析：第 17 章的分析器会在自己一侧
扫描一次边、建好 succ/pred 映射后再迭代。派生数据可以随时丢弃重建，无须
作为图的不变量维护。这条取舍与 7.2 节"基础结构只提供最小信息"一脉相承——
图只负责说真话，各种便利视图由消费者临时生成。

### 7.9.3 手工模拟：在 branch 上穿菱形

ite 的模拟覆盖了环，这里补上 branch.tip 中 absval 的模拟，覆盖分叉与汇合。
absval 的体是三条语句：var 声明不产生节点；第一条是 if，if 两个分支各是
一个单语句块，块内分别为 `r = x` 与 `r = 0 - x`；第三条是 `return r`。

**编号**结果（函数级补齐 1 与 6）：

| 编号 | 种类 | 来源 |
|---|---|---|
| 1 | entry | 函数入口 |
| 2 | branch | if 的条件点 |
| 3 | assign | then 块中 `r = x` |
| 4 | assign | else 块中 `r = 0 - x` |
| 5 | return | `return r` |
| 6 | exit | 函数出口 |

注意先序性的体现：then 分支的 3 号严格小于 else 分支的 4 号，尽管真实执行
每次只走其中一个。

**连边**的完整调用链：

1. 函数级确定 `5 → 6`，对体块调用 `wireStmt(块, {5})`。
2. 体块倒序折叠，先处理 if：`wireStmt(if, {5})`——汇合点是 5。
3. if 先处理 else 块（实现中两个分支都要穿）：`wireStmt(else块, {5})`，
   块内 `r = 0 - x` 连 `4 → 5`，返回 {4}。
4. 再处理 then 块：`wireStmt(then块, {5})`，块内 `r = x` 连 `3 → 5`，
   返回 {3}。
5. if 拿到两个分支入口 {3} 与 {4}，连 `2 → 3` 与 `2 → 4`；本例有 else，
   条件点**不**直连汇合点；返回 {2}。
6. 回到体块，if 之前没有其他可执行语句（var 声明跳过），块返回 {2}。
7. 函数级连 `1 → 2`。

排序后边为 `1→2, 2→3, 2→4, 3→5, 4→5, 5→6`，与输出中 absval 的图逐边
吻合。这张菱形图最值得注意的是边 `3 → 5` 与 `4 → 5`：两个互斥的执行点
连向同一个后继，"互斥"信息图不保留（两条边都在），但这丝毫不影响可靠性
——任何一次运行只走其中一条；而"汇合"是真实的：无论走哪条，下一步确实
都是 5 号 return。把本例与 ite 例并放，读者就集齐了 7.5.1 规则表中除退化
边界外的全部情形。

## 7.10 本章代码

本章示例 `07_cfg` 由四部分组成：第 04 章冻结的文法、第 05 章的 AST 与
打印器、第 06 章的符号表，以及本章新增的 `cfg.hpp/cfg.cpp`。下面按依赖
顺序嵌入全部文件，每个文件即编译器实际构建所用的完整内容。

阅读这批文件时建议带着三个问题，它们分别对应三层结构。其一，**数据如何
流动**：main 从解析得到 AST，经符号表补全名字，最后交给 CfgBuilder——三个
阶段顺序固定、每阶段输出不可变对象。其二，**新增代码如何复用旧代码**：cfg.cpp
不解析任何文本，它的输入只有 AST 节点与第 06 章的 Bindings（事实上函数内
CFG 连 Bindings 都不直接依赖，它只看语句形状；Bindings 是 main 在打印调用
文本时才需要的）。其三，**规则在代码中的落点**：7.5 节的规则表对应 cfg.cpp
中 `numberStmt` 与 `wireStmt` 两个分派函数，每种语句恰有一个分支；读代码时
把表格行与函数分支逐一对上，即完成"原理 → 实现"的核对。

每个嵌入文件首行的 `// file: 路径` 标记不是注释装饰：仓库的 check_docs 工具
据此把围栏内容与磁盘上的真实文件逐字节比对，因此正文所引代码与构建所用代码
不可能悄悄漂移。读者也可以把这一机制当作阅读索引——想跳到磁盘对应文件，
按标记中的路径即可。

### 文法

文法与第 04 章完全相同，前端自第 04 章起复用、本章不做任何改动。

```antlr
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

### 配套程序

`main.cpp` 是前六章流水线的延长：解析、AST、名字解析三步全部通过后，才在
AST 上构造 CFG 并打印。任何一步出错都按第 04 章约定的退出码结束（2 为语法
层、3 为语义层），不会带着错误程序去画图。

```cpp
// file: src/main.cpp
// 第 07 章配套程序：解析 -> AST -> 名字解析 -> 构造控制流图。
// 名字无误时打印每个函数的程序点与边；词法/语法错误退出码 2，语义错误 3。
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
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    std::ifstream src(argv[2]);
    if (!src) {
        std::cerr << "cannot open " << argv[2] << '\n';
        return 1;
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
        return 2;
    }

    std::unique_ptr<tip::ProgramA> ast = tip::buildAst(tree);
    tip::Bindings bindings = tip::resolveNames(*ast);
    if (!bindings.errors.empty()) {
        for (const tip::Diag &d : bindings.errors) std::cout << d.text << '\n';
        return 3;
    }

    tip::Cfg cfg = tip::buildCfg(*ast);
    std::cout << tip::printCfg(cfg);
    return 0;
}
```

### AST 节点定义

AST 定义沿用第 05 章冻结的版本，本章不改动。重列于此是为了让读者在读
`cfg.cpp` 时能直接对照节点种类。

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

### AST 构建器

构建器接口与实现沿用第 05 章版本。CFG 的第二遍要反复按 `dynamic_cast`
识别语句种类，这里可以先看到所有语句节点是如何产生的。

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

### Pretty-printer

打印器在第 05 章版本之上多出两个单行接口 `printExpr` 与 `printStmtLine`，
本章 CFG 打印节点时使用后者。注意 `printStmtLine` 会去掉语句文本末尾的换行，
使节点编号与语句出现在同一行。

```cpp
// file: src/pretty.hpp
// Pretty-printer：把 AST 以固定的前缀式语法重新打印出来。
// 它是 AST 的第一个消费者，也为后续各章提供"程序结构可视化"的通用工具。
#pragma once

#include <string>

#include "ast.hpp"

namespace tip {

std::string printProgram(const ProgramA &program);

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printExpr(const Expr &expr);
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

std::string printExpr(const Expr &expr) { return exprText(&expr); }

std::string printStmtLine(const Stmt &stmt) {
    std::string out;
    stmtText(&stmt, 0, out);
    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
}

}  // namespace tip
```

### 符号表

CFG 构造不直接使用符号绑定结果，但 `main.cpp` 在画图前必须先通过名字解析，
以保证所有调用与变量都有意义。符号表沿用第 06 章版本。

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

### CFG：本章新增接口

`cfg.hpp` 即 7.2 节形式化的落地：节点六分种类、函数图持有节点映射与边。
对外只有两个函数：`buildCfg` 构造、`printCfg` 打印。

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

### CFG：两遍构造的完整实现

`cfg.cpp` 对应 7.3–7.7 节的全部讨论。读代码时建议沿三个标记分段：`numberStmt`
是第一遍、`wireStmt` 是第二遍、文件末尾的 `printCfg` 是输出。

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

## 7.11 真实输出

以下是对两个示例程序运行 `tipa --check` 的完整输出，即机器对账的基准文本。
每个源文件前的 `== 文件名 ==` 由对账脚本添加，其后每个函数的节点与边由
`printCfg` 产生。

阅读这份输出前先说明它的三重身份，避免把它当作普通日志。其一，它是
**构造代码的实际产物**——由本章嵌入的 cfg.cpp 在真实程序上跑出，任何规则
理解上的偏差都会在这里现形。其二，它是**逐字节对账基准**：expected/output.txt
与此处围栏内容、与每次构建的实际输出三者必须完全一致，机器校验、不容手改
调和。其三，它是**自测题的答案册**：7.1.3 节要求读者徒手默画的两张图，
答案就在下面；建议先画完再翻对。

输出虽长，读法只有两步：先看每个函数的 nodes 段、对照 7.4 节编号规则逐行
确认"这个位置该不该有、顺序对不对"；再看 edges 段、对照 7.5 节规则逐边
确认"这条边由哪条规则产生"。两张图加起来只有 13 条边，十分钟内可以逐条
核完——这十分钟是把规则表从"读懂"变成"会用"的最短路径。

```text
; expected: expected/output.txt
== branch.tip ==
== absval ==
nodes:
  1: entry
  2: branch  if ((> x 0))
  {
    r = x ;
  }
else
  {
    r = (- 0 x) ;
  }
  3: assign  r = x ;
  4: assign  r = (- 0 x) ;
  5: return  return r ;
  6: exit
edges:
  1 -> 2
  2 -> 3
  2 -> 4
  3 -> 5
  4 -> 5
  5 -> 6
== main ==
nodes:
  1: entry
  2: assign  a = (call absval x) ;
  3: output  output a ;
  4: return  return a ;
  5: exit
edges:
  1 -> 2
  2 -> 3
  3 -> 4
  4 -> 5
== ite.tip ==
== ite ==
nodes:
  1: entry
  2: assign  f = 1 ;
  3: branch  while ((> n 0))
  {
    f = (* f n) ;
    n = (- n 1) ;
  }
  4: assign  f = (* f n) ;
  5: assign  n = (- n 1) ;
  6: return  return f ;
  7: exit
edges:
  1 -> 2
  2 -> 3
  3 -> 4
  3 -> 6
  4 -> 5
  5 -> 3
  6 -> 7
```

### 7.11.1 经验侧：执行台如何旁证路径性质

归纳证明覆盖所有运行，经验核对则提供可见的具体实例，第 08 章的执行台正好
承担这一角色。把同样形状的程序交给 ORC JIT 真实执行，每次运行都诱导一条
具体路径：输入 `n=5` 时路径绕环五次后经 `3→6` 离开；`n=0` 时路径在第一次
判断就走退出边。这些观察到的路径逐一落在图的边列表中——证明说"必然如此"，
执行台说"这次确实如此"，两者各管一层，与第 05 章建立的三层方法论一致。

怎样让这种经验核对可以系统化地重复？原理上有三步：其一，在 JIT 执行时记录
经过的程序点（可以在每个 AST 语句对应的执行位置插入计数钩子，第 08 章注入
宿主函数的机制同样适用）；其二，把记录的序列与边集合比对——每对相邻点都
必须是一条边；其三，对多组输入重复，覆盖"循环 0 次/多次""分支走真/走假"
这些形状。本章未在代码中加入路径钩子（避免为一次教学核对污染执行台），但
第 17 章起的 `--verify-soundness` 通道会把这种"具体结果 ↔ 抽象预测"的核对
自动化；此处读者只需理解：**CFG 的可靠性虽然不依赖测试，但测试能抓住构造
代码与规则之间的现实偏差**，正如 check_example 用逐字节输出所做的那样。

值得提前避免一个误用：执行再多输入也只覆盖有限路径，因此不能用"跑了很多
次都没脱图"替代归纳证明——无穷的程序与输入空间决定了测试永远是抽样。
经验核对的正确位置是证明的补充而非替身，这个次序第 02 章已从 ∀/∃ 的角度
论证过，此处是它在 CFG 上的又一次落地。

## 7.12 把图读回执行

输出分两段：节点列表给出"有哪些位置"，边列表给出"位置之间的可能转移"。
逐图核对一遍，可以验证 7.8 节的可靠性在直觉上也成立。

**branch.tip 的 absval 是一个完整的菱形。** 节点 2 是条件点，它有两条出边：
`2→3`（条件真，执行 `r = x`）与 `2→4`（条件假，执行 `r = 0-x`）。节点 3
与 4 又都指向节点 5——两条岔路在 return 前**汇合**。一次真实运行只经过其中
一条：`2→3→5` 或 `2→4→5`，两条都是图上的路径，且没有第三种走法。注意节点
5 的文本是 `return  return r ;`——第一个 "return" 是节点种类名，第二个
来自负载语句 `printStmtLine` 的输出，并非重复打印。

**同一文件的 main 是一条直线。** 节点 2 的负载是 `a = (call absval x)`：
调用在本章只占一个节点，执行视为一步完成，不跳入 absval 的图。节点 2→3→4
依次是赋值、输出、返回，每点只有一条出边。Entry 直连节点 2、节点 4 连 Exit，
全程没有分叉。

**ite.tip 是本章唯一含环的图。** 对照 while 规则逐边读：节点 3 是循环头，
`3→4` 是条件为真、进入循环体；体内 `4→5` 顺序执行两条赋值；**`5→3` 是
回边**，体执行完回到条件点重新判断；`3→6` 是条件为假、退出循环到 return。
模拟输入 `n=5`，执行走出的序列是 `1,2,3,4,5,3,4,5,3,…,3,6,7`——每一步
相邻转移都能在边列表中找到。若 `n` 一开始就是 0，序列则是 `1,2,3,6,7`：
退出边 `3→6` 立即被使用，循环体从未进入。两种运行都在图上，再次印证
7.8 节的结论。

还可以做一个反向检查：**从边列表数每个节点的出度，与该构造的执行可能对照**。
直线节点（assign/output/return）出度恒为 1；branch 节点出度恒为 2（ite.tip
的节点 3：到 4 与到 6）；entry 出度 1、exit 出度 0。这个简单的计数规则是
CFG 结构健全性的直观旁证，也是人工审查一张新图时最快的抓手。

最后值得重提图中"多画"的部分：absval 的两条分支边都在，即使调用者可能
只传入正数；ite 的退出边 `3→6` 也在，即使没有输入能让循环立刻终止。这些边
对应**可能但未必发生**的执行——它们不影响可靠性（真实路径仍在图内），却是
后续分析精度损失的来源。第 18 章的常量传播将第一次展示：分析器如何识别出
"这条边其实不可走"，从而把图收缩得更紧。

### 7.12.1 从 CFG 到数据流方程：下一篇的入口

本章是工程篇的终点，也是分析篇的起点，在此把两者之间的桥一次性搭完。
数据流分析将在每个程序点 n 放置一个**事实**（如"x 的符号集合""x 是否常量"），
事实如何由图的结构决定，可以直接从 CFG 读出三条规则。

- **直线边**：事实经一条语句时按该语句的语义变换——赋值后 x 的事实要重新
  计算，输出不改变任何变量。这个变换叫**传递函数**。
- **分叉点**：条件点不改变变量，事实原样分送两个后继；真假信息默认丢失。
- **汇合点**：这是关键。absval 的节点 5 同时从 3、4 收到事实，但分析结论
  必须对"走任一条分支"都成立，因此要把两路事实**合并**：要求"一定为正"
  就取两路都保证的部分，要求"可能的值"就取两路的并。合并运算（格上的
  meet/join）的定义完全由"结论要对所有路径成立"这一要求决定——它的
  可靠性证明就是 7.2.1 节 ∀-路径量化在算子层面的重现。

于是分析被写成一个方程：每个节点的事实 = 对其所有前驱传来的事实先合并、
再施加本节点的传递函数。方程含环（回边 5→3 使节点 3 的事实依赖自己），
不能一次代入解出，而是从"什么都不知道"的初始事实出发反复应用方程，直到
事实不再变化——**不动点**。第 13–16 章将为"反复应用必然停下、停下时
得到的解可靠"建立整套数学工具（格、单调性），本章的图则是那套工具的操作
对象。读者在进入第三篇前只需记住这一对应：**CFG 决定方程的形状，格决定
事实如何合并与终止，而可靠性始终回溯到"对所有路径、所有运行成立"。**

### 7.12.2 常见疑问再答

本章概念初学时有几个反复出现的问题，在此集中回答，它们大多指向"图与执行
之间到底保留了多少信息"。

**问：既然一条边对应一次可能的转移，为什么不在边上写转移条件？**
答：可以写（Branch 的两条边天然对应条件真/假），但这会迫使每种边都携带
一段布尔表达式，而大部分边（直线边）的条件就是"恒真"。把条件放在边上，
等于让图结构承担一次路径敏感分析；本书坚持把这类信息推迟到分析侧——分析器
需要时用第 20 章的路径敏感技术自己恢复。结构与分析的这条分界线一旦模糊，
图就会从"所有分析共享的底座"退化成"某一个分析的专用表示"。

**问：函数有多条 return，图怎么画？**
答：每个 ReturnS 产生一个 return 节点并各自连向 Exit——Exit 是唯一的，于是
Exit 可有多个前驱。真实运行只执行其中一个 return 节点，但图不预判是哪个。
这正是 Exit 必须实体化的又一理由（7.4.2 节）：多个返回点共享同一个出口。

**问：空块、空体这些退化形状真的需要支持吗？**
答：它们在 TIP 文法中合法（`stmt*` 允许零条），一个声称对全部合法程序可靠
的构造器就必须为它们给出语义正确的形状——空块透传、空体自环。退化情形不是
边角余料，而是归纳证明的基础情形；规则表（7.5.1）如果在这些格子上含糊，
整个归纳就留下了缺口。

**问：CFG 画好后还能增量更新吗？编辑了一行要重建全图吗？**
答：本章实现是整体重建的——CFG 构造是 AST 上的纯函数、代价与程序大小成
线性比例，重建远比维护"哪条边因这次编辑而增减"简单可靠。工业 IDE 为实时
响应才做增量分析，那是一组独立的工程技术；本书规模下，"便宜到随时可重建"
正是选择简单表示（7.9.2）带来的自由。

**问：节点编号为什么不让 Exit 恒为最大号？**
答：本章实际上 Exit 就是最大号（return 与 exit 在编号后补），但这只是先序
遍历的副产品，不是可供依赖的契约——7.4.1 节明确编号只承诺先序性。跨函数、
增量编号等场景下"Exit 最大号"随时失效，分析代码应通过 `exitNode` 字段
访问出口，而不是猜测编号。

**问：本章的构造算法在有递归函数时会失效吗？**
答：不会。递归（函数直接或间接调用自己）是**函数之间**的关系，而函数内
CFG 把一切调用原子化为一个节点——调用谁、是否递归，对本图毫无影响。递归
带来的真正挑战在分析侧：过程间不动点必须保证沿递归调用链收敛，那是第 21 章
处理的问题；本章的构造对此既不需要知道、也不会出错。这再次印证 7.2.4 节的
分层论证：把函数间信息挡在构造之外，构造因此对所有程序形状都可行。

## 7.13 小结

本章把第 05 章的树形 AST 展开成了控制流图：每个函数一张图，六种节点标记
入口、出口与语句位置，有向边表达"执行可能的直接转移"。构造采用干净的两遍
算法——先按源码先序编号、再从函数尾部倒向线程后继，`wireStmt` 以"后继
集合 → 入口集合"的方式统一处理顺序、分叉、汇合与回环。

回顾全章组织，可以再次看到一条贯穿的推进线：7.1 从树的失败提出问题、7.2
冻结数据结构并定义路径、7.3–7.6 给出构造及其形式性质、7.7 解决可读性、
7.8 用结构归纳完成可靠性论证并精确标出不完备的缺口、7.9–7.12 分别从工程、
手工模拟、真实输出、数据流前瞻四个角度回嚼同一组规则。原理在前、实现随后、
输出对账的次序没有一处颠倒——读者若习惯了这种"问题 → 形式化 → 论证 →
落地 → 核对"的节奏，也就掌握了阅读本书后续每一章的地图。

本章同时第二次实践了全书的方法论：先形式化要保的性质，再用结构归纳论证它对
**所有**输入与**所有**运行成立，最后以确定性的真实输出做经验核对。CFG 的
可靠性——真实运行不脱图——以及它有意的不完备——图含不可达路径——正是第
02 章"可靠分析在可能性超集上工作"在程序结构层面的具体形态。

至此，第二篇（第 03–08 章）的前置工程全部完成：语言、文法、AST、名字、
控制流、以及第 08 章的 LLVM 执行台。从下一章起进入第三篇，正式开始做分析。
第一个分析对象是**类型**：我们将看到一种不用逐行运行、而是通过收集并求解
约束来推断程序性质的方法——类型约束与 CFG 一样是"先建立结构、再在结构上
求解"的思路，但求解的对象从"可能的路径"换成了"必须成立的等式"。

离开本章前，把可独立检验的结论收成一张"带走清单"，读者可以用它自测，而
无须重读全文：

1. 能默写六种节点种类，并说出只有 Assign/Output/Branch/Return 负载语句、
   Entry/Exit 是零语句的边界端点。
2. 能解释两遍构造为何分开：先序编号保证输出契约，倒向连边解决"后继尚不存在"
   的依赖问题。
3. 能对任意一条语句执行 wireStmt 的局部规则：知道它内部连什么边、给子构造
   什么后继、返回什么入口集合——即不看表复述 7.5.1 的五行。
4. 能徒手画出 if-else 菱形与 while 环图，并正确处理三种退化：空块透传、
   无 else 补边、空体自环。
5. 能用"可靠但不完备"表述 CFG 与真实执行的关系：真实路径必在图上，图上
   路径未必发生；并说明多画的边是精度而非正确性的代价。
6. 能指出支配与回边的定义、以及为什么本章不实现它们也能完成数据流分析。
7. 能区分 AST、函数内 CFG、调用图三者，并说明调用图要等第 21 章。

本章的概念地图也可用一句话概括：**语句形状（语法）决定节点与边（结构），
节点与边决定路径（可能性），路径上的 ∀-量化决定一切分析性质的最终含义。**
第 17 章之后出现的每一种分析——符号、常量、区间、指针——更换的只是放在
程序点上的"事实"及其合并方式，而"事实必须对所有路径上的所有运行成立"
这一最终裁判，从本章起不再改变。





