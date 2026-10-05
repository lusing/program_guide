# 第 30 章　四大经典数据流分析：一个幂集格统一四种问法

## 30.1 本章要解决的四个问题

### 30.1.1 编译器日复一日在问的四个问题

第 28 章把不动点求解做成了机器：方程组写下来，worklist 反复迭代，
直到没有任何点再变化。但第 25–28 章里跑的那个分析只有一个——
符号分析。这一章要回答一个更宏大的问题：**数据流分析这个"行业"
里，到底有多少种分析？它们是四台不同的机器，还是同一台机器的
四种设置？**

答案从编译器（以及大量静态工具）日复一日在问的四个问题开始。
这四个问题读者在任何一本编译原理教材里都会遇到，但通常它们
被当作四个互不相干的算法分别讲授、分别实现。本书把它们并排
放在同一章，因为并排正是看清其公共结构的前提。

**问题一：哪些变量之后还要用？** 一条赋值语句把值存进变量，
如果从这条语句出发、沿着任何执行路径走下去，这个变量在被重新
赋值之前再也不会被读取，那么这条语句存进去的值没有任何人会
消费——它是**死赋值**，可以整条删掉。要回答"哪些赋值是死的"，
需要知道在每个程序点上**哪些变量此后还会被使用**。这就是
**活跃变量分析**（live variables）：变量 x 在程序点 p 活跃，当且
仅当存在一条从 p 出发的路径，x 在这条路径上、任何对 x 的新赋值
之前被读取。注意定义里的量词——"存在一条路径"，只要有一条
路径用得着，就不能删。

**问题二：这个值是从哪来的？** 读到 `output s` 里的 s 时，s 的
值可能来自好几个不同的赋值语句——如果 s 在一个循环里被赋值，
进入循环前的赋值和循环体内的赋值都"可能"是供应商。把每个
赋值语句编号为一个**定值**（definition），**到达定值分析**
（reaching definitions）回答：在程序点 p，哪些定值**可能**未经
重新赋值而沿某条路径流到 p。它是**使用-定值链**（ud 链：一个
使用点对应哪些定值）与**定值-使用链**（du 链：一个定值喂给了
哪些使用点）的原料——没有它，"这个赋值影响哪些计算"这类问题
无从下手。

**问题三：哪些表达式已经算过、不必重算？** 如果表达式 `a+b`
在某个程序点之前已经被求值过，而且此后 a、b 都没有被重新赋值，
那么再次需要 `a+b` 时可以直接取旧值——这是**公共子表达式消除**
（CSE）的依据。**可用表达式分析**（available expressions）
回答：在程序点 p，哪些表达式"已经算过且操作数未变"，从而此刻
**一定**可以复用。注意量词换了：CSE 复用一个旧值，要求**每一条**
到达 p 的路径都算过它——只要有一条路径没算过，复用就会读到
不存在的值。这是"所有路径"的量词。

**问题四：哪些表达式每条路径都免不了要算？** 如果从某个程序点
出发，**无论**控制流怎么走，表达式 `a+b` 都会在其操作数改变之前
被求值，那么这个计算是躲不掉的——把它**提到**分支或循环之前
先算好（代码外提、循环不变量移动的基础），不会增加任何计算量。
**非常忙表达式分析**（very busy expressions）回答的正是这个：
在程序点 p，哪些表达式在**所有**从此出发的路径上都会被求值。
这又是"所有路径"的量词，但方向反过来——问的不是"过去算过
什么"，而是"未来要算什么"。

四个问题、四个分析，各有名字：活跃变量、到达定值、可用表达式、
非常忙表达式。接下来的整章都在做一件事：证明它们是**同一个
数学对象在四个参数设置下的四次实例化**，并用第 28 章的框架把
四次实例化装进一个不到二百行的驱动器里。

### 30.1.2 一个程序看四个答案

为了把四个分析放在同一份数据上对比，本章全程使用一个精心
设计的小程序。它短到能逐点人工验算，又同时给四个分析各自
提供了"有话说"的结构：一个两分支的 if（两支各算一次 `a+b`）、
一个以 `s>0` 为条件的 while 循环（循环头是汇合点兼回边源头）、
一条在循环体内改变 a 的赋值、以及循环出口处的一次输出。

```cpp
// file: programs/classic.tip
main() {
  var a, b, c, s;
  a = input;
  b = input;
  c = 0;
  if (a > 0) {
    s = a + b;
  } else {
    s = a + b;
  }
  while (s > 0) {
    s = s - 1;
    a = a + b;
  }
  output a + b;
  output c;
  return 0;
}
```

读这个程序时建议手里拿一支笔，给语句标号（输出里正是按第 14 章
CFG 的程序点编号标号的：2 是 `a=input`，5 是 if 分支，8 是 while
分支，13 是 return）。几处刻意的设计值得先点出来：

- 两条分支语句 `s = a + b` 与 `s = a + b` **文本相同**。这对
  可用表达式分析是"两支都算"的标准样本，对非常忙分析是"可
  外提"的标准样本，对到达定值分析则是"同一变量两个定值在
  汇合点相遇"的标准样本。
- 循环体里 `a = a + b` 一石三鸟：它改变 a（杀死所有含 a 的
  表达式）、它自己又计算 `a+b`（杀完立刻重新生成）、它还是
  变量 a 的第二个定值。三个分析会从各自的角度"看见"这条语句。
- `c = 0` 与 `output c` 相距很远，中间隔着整个循环——c 的
  活跃区间横跨循环，用来展示活跃变量分析"逆流而上"的追踪能力。

### 30.1.3 与 spa 原书章节的对应

spa 第 2 章以"数据流分析"为题，把上述四个分析作为迭代算法的
四个经典实例逐一给出，并指出它们的方程形式完全一致：每个程序
点上 IN 与 OUT 互相由对方经 gen/kill 生成，汇合点按 may 取并、
按 must 取交。spa 用伪代码与位向量讲解，强调"框架"一词——
四个分析共享一个迭代骨架，差异被压到四个参数上。本书把这个
"压到参数上"做成了字面意义的 C++ 结构体：一个 `DfaSpec` 五个
字段（30.5 节），一个 `runDfa` 驱动器吃下规格就吐出结果（18.6
节）。spa 留给读者的"验证四个分析收敛"的习题，本书用第 28 章
已经建立的不动点理论直接回答——四个分析的传递函数都是同一
形状的 gen/kill 函数，单调性与终止性的论证一字不改地通用。

### 30.1.4 本章的阅读路线

18.2 建立统一格视角：一张分类表把四分析压进"方向 × 合并 ×
初值"三个参数，并论证四种参数组合各有代表不是巧合；18.2.6
把 may/must 的对偶落到补运算上。18.3 处理 must 分析的三个
特殊问题——为什么从全集出发、为什么边界是空集、全集不可
枚举时怎么办——这是本章理论密度最高的一节。18.4 集中嵌入
前几章复用的前端机器，交代即可、不必重读。18.5 与 18.6 是
本章主角：`DfaSpec` 规格结构与 `runDfa` 驱动器逐函数深讲，
18.6.8 用纸上轮次表把非常忙规格从头收敛到尾。18.7 讲
main.cpp 如何把四个分析装配成一次 `--check` 运行。18.8 是
全章的重头戏：对 classic.tip 的四段真实输出逐段解读，把
"may 看存在路径、must 看全部路径"读成体感。18.9 转向消费端：
四张表各自喂养哪个优化变换。18.10 工程注意点，18.11 练习，
18.12 小结。读者若时间有限，18.2、18.3、18.6、18.8 四节
不可省。

## 30.2 统一格视角：方向、合并、gen/kill、边界

### 30.2.1 幂集格：四个分析的公共底座

先把四个分析的"事实空间"（factor space）摆出来看它们的形状：

- 活跃变量的因子是**变量名**：a、b、c、s……
- 到达定值的因子是**定值点**：d1、d2……每个赋值语句一个。
- 可用表达式的因子是**表达式的文本**：`(a+b)`、`(s>0)`……
- 非常忙表达式的因子同样是**表达式的文本**。

三个不同的因子空间，但每个空间配上"子集"偏序后都是同一个
数学结构：**幂集格**。第 26 章已经正式构造过它：元素是事实
的集合，偏序是包含，汇合运算（join）是并，meet 是交，⊥ 是
空集，⊤ 是全集。四个分析的信息状态都是"某个因子集合"——
"此处 {a,b} 活跃"、"此处到达 {d1,d3}"、"此处 {(a+b)} 可用"，
无一例外。

更关键的是，四个分析的**状态如何随控制流移动**也完全同构。
在每条语句上，新状态由旧状态经过一个"局部修补"得到：加入
这条语句**产生**的事实（gen），去掉这条语句**作废**的事实
（kill）；在分叉的汇合处，几股来流按"存在路径"或"全部路径"
的量词合并——前者是并，后者是交。gen/kill 由语句本身决定，
跟方向无关；方向和量词才是分析之间的分歧。把这些分歧收拢，
四个分析各自是一条**规格**（specification）：

```
DfaSpec {
  name      // 打印用的名字
  forward   // 信息沿 CFG 边正向传播，还是逆向
  may       // 汇合取并（存在路径），还是取交（全部路径）
  gen, kill // 语句级：这条语句产生/作废哪些因子
  initFull  // 非边界点从全集出发（must）还是空集（may）
}
```

一个分析 = 一个因子空间 + 一条这样的规格。第 28 章的 worklist
引擎稍作推广（支持逆向与 must），就能吃下任何一条规格。

### 30.2.2 统一分类表

把 18.1.1 的四个分析按规格逐项填进去，得到本章的中心表格：

| 分析 | 因子 | 方向 | 合并 | 初值（非边界） | 边界点与边界值 | gen | kill |
|------|------|------|------|----------------|----------------|-----|------|
| 活跃变量 | 变量名 | 后向 | ∪（may） | ∅ | exit，∅ | 语句使用的变量 | 被赋值的变量 |
| 到达定值 | 定值点 dN | 前向 | ∪（may） | ∅ | entry，∅ | 本定值 | 同变量的其余定值 |
| 可用表达式 | 子式文本 | 前向 | ∩（must） | 全集 U | entry，∅ | 语句计算的子式 | 含被赋值变量的子式 |
| 非常忙表达式 | 子式文本 | 后向 | ∩（must） | 全集 U | exit，∅ | 语句计算的子式 | 含被赋值变量的子式 |

逐列看这张表，每一列都只剩两种取值，而且两种取值之间的配对
规律一目了然：may 的两行初值全是 ∅，must 的两行初值全是全集；
may 的两行 gen 都是"使用/定义"这类天然离散的事实，must 的
两行 gen 都是"表达式"这类可以沿集合继承的事实。表格的纵横
交错里藏着两条原理，接下来两小节分别把它们说透。

### 30.2.3 may 与 must 的对偶：安全上界与安全下界

先说量词这一维。**may 分析**（活跃变量、到达定值）的回答
口径是"存在一条路径"：只要有一条路径使事实成立，事实就进
集合。这样算出来的集合是真实情况的**上界**——它可能多报
（把实际走不到的路径上的事实也收进来），但绝不漏报。多报
安全吗？看用途：活跃变量的消费者是死赋值删除，删除的条件是
"x **不**活跃"——may 集合多报 x，只会让"不活跃"的判定更
保守、更难成立，删错的可能是零。换句话说，**may 分析多报的
代价只是优化少做，不是做错**。这就是"安全上界"的含义：
集合大于等于真值，方向朝着"宁可多报"。

**must 分析**（可用表达式、非常忙表达式）的回答口径是"所有
路径"：每一条路径都使事实成立，事实才进集合。算出来的集合
是真实情况的**下界**——它可能漏报，但绝不虚报。虚报的危险
是实的：CSE 若复用一个并非所有路径都算过的表达式，某条路径
上就会读到根本不存在的值；外提若把一条仅部分路径需要的计算
提到分支之前，另一条路径就白算（甚至除零）。must 的消费者
直接**依据分析结果改写程序**，所以集合必须小于等于真值——
"安全下界"。

两个量词互为对偶，在数学上是同一个事实的两次投影：对因子
全集 U 取补，"存在路径使 e ∈ S"变成"所有路径使 e ∉ U∖S"，
may 在补集上读出来就是 must。本书不把对偶做成实现（补集让
"全集"从延迟变成了必需品，得不偿失），但读者应当知道这张
表的上下两半不是两套理论，而是一套理论照了两面镜子。spa 把
这个对偶表述为"may 分析的可靠性与 must 分析的可靠性互为
镜像"，本章 30.3 节处理 must 时会再次用到这一视角。

### 30.2.4 前向与后向：沿数据流与逆流问未来

再说方向这一维。**到达定值**与**可用表达式**问的都是"此时
此刻的**现状**"：哪些定值流到了这里、哪些表达式已经算好了。
现状是沿着控制流**积累**出来的——定值从赋值语句出发顺流而下，
表达式算完后保持可用直到操作数被改——所以信息沿 CFG 的边
**正向**传播，汇合点合并的是前驱们的状态。

**活跃变量**与**非常忙表达式**问的都是"**未来**"：这个变量
之后还用不用、这个表达式之后还免不免得了。未来在控制流的
下游，但分析必须把下游的答案**传回**上游——`output a+b` 处
用到 a，这个事实要传回循环开头的 `a=input` 才能说明那条赋值
不白做。所以信息沿 CFG 的边**逆向**传播，汇合点合并的是
后继们的状态。逆流不是花哨的技巧，而是"问未来"这类问题的
唯一自然解法：未来的信息只存在于未来，只能从那里取。

于是四个象限各归其位：前向 may 问"过去有什么**可能**成立"，
前向 must 问"过去有什么**一定**成立"，后向 may 问"未来有
什么**可能**成立"，后向 must 问"未来有什么**一定**成立"。

### 30.2.5 为什么"四种组合各有代表"不是巧合

2（方向）× 2（量词）= 4，而恰好四个经典分析一个萝卜一个坑。
这是巧合吗？不是——因为它对应的是编译优化的四个基础需求，
而这四个需求恰好把"过去/未来 × 存在/全部"占满：

| | 存在路径（may） | 所有路径（must） |
|---|---|---|
| **问过去（前向）** | 到达定值：值从哪来（ud/du 链） | 可用表达式：能复用吗（CSE） |
| **问未来（后向）** | 活跃变量：能删吗（死赋值删除） | 非常忙表达式：能外提吗（码移动） |

优化器要改写程序，每一步改写都踩在"删、连、复用、搬"四个
动作之一上：删除赋值需要活跃变量，连接定值与使用需要到达
定值，复用需要可用表达式，搬移需要非常忙表达式。四个动作
各自要求一种量词与一种方向——删除判定是"未来无人使用"的
存在性反问题（后向 may），链的建立是"过去可能有供应商"的
存在性问题（前向 may），复用是"过去全部算过"的全称问题
（前向 must），外提是"未来全部要算"的全称问题（后向 must）。
需求填满象限，分析填满表格——四个代表是需求的投影，不是
算法设计师的排兵布阵。

还应指出表格里的一个对称细节：活跃变量与到达定值在"定义-
使用"关系上互为镜像——"x 在 p 活跃"说的正是"p 属于某条
从定值到使用的路径"；可用表达式与非常忙表达式同样互为镜像
——"e 在 p 可用"（过去算过、还能用）与"e 在 p 非常忙"
（未来要算、躲不掉）是同一条"计算-使用"链从两端看的两次
观察。镜像关系解释了为什么表格里前向两行与后向两行的 gen/kill
形状如此相似：它们本来就是同一组语句事实，被两个方向的探照
灯各照一遍。

### 30.2.6 补集视角：同一枚硬币的两面

18.2.3 节说 may 与 must 互为对偶，这里把"对偶"落到格论的
实处。固定因子全集 U，对每个集合 S 取补集 U∖S。补运算是
幂集格到自身的一一映射，并且把序彻底翻转：S ⊆ T 当且仅当
U∖T ⊆ U∖S；同时把并变成交、交变成并——这正是德摩根律的
集合形态。于是任何一个 may 分析取补之后就是一个 must 分析，
反之亦然："存在一条路径使事实成立"的补命题恰是"所有路径
都使事实不成立"。四行分类表沿这一轴对折：活跃变量折到
它的补命题"此处哪些变量确定死亡"，可用表达式折到"此处哪些
表达式确定不可复用"，折过去的每一条都是 must 口径的陈述。

这个视角有两条实用的推论。**其一，判断一个分析的量词归属，
不看它的名字与宣传，看它的安全性方向**：若"多报无害、漏报
致命"，它是 may（漏掉一个真事实会让消费者删错、连错）；若
"漏报无害、多报致命"，它是 must（虚报一个假事实会让消费者
直接改错程序）。名字可以乱起，安全性方向不会撒谎。**其二，
工程里常见"一鱼两吃"**：跑一遍 may 版迭代，对结果取补打印，
就得到对偶 must 事实的报表——活跃变量的补集是"确定死亡"
名单，直接服务死变量清理。本书不做这个换算，原因正是
18.3.3 节的麻烦：补集要求可枚举的全集，而"全集"恰恰是 must
一节要专门解决的东西。读者日后在 spa 或其他教材里遇到
"对偶分析""镜像问题"的字样，应当能立即还原出补运算这一层。

## 30.3 must 分析的三个特殊问题

### 30.3.1 为什么从全集出发：⊤ 是最乐观的假设

may 分析从全 ∅ 出发——这一点在第 28 章已经论证过：⊥ 表示
"还没证明任何事实"，迭代只增不删，收敛到最小不动点，即精度
最高的安全上界。must 分析能不能也这样？不能，而且失败的方式
很有教学价值。

回忆 must 的汇合是**交**。若所有点从 ∅ 出发，考虑这样一个
抽象情形——表达式 e 在循环前算好，循环体内既不计算也不杀死它：

```
      e = a + b;        // gen e
      while (cond) {    // 循环头 H：汇合点
        ...             // 体：对 e 既不 gen 也不 kill
      }
```

循环头 H 有两个信息流前驱：循环前的 `e = a+b`（gen 了 e）和
循环体末尾（沿回边回来，对 e 做了纯传递）。e 在 H 可用吗？
按"所有路径"语义：无论进不进循环、转多少圈，e 都算过且操作
数未变——**可用**。正确答案来自"最大不动点"。可若从 ∅ 出发
迭代：H 的初值是 ∅，循环体的值来自 H 也是 ∅，于是 H 的汇合
是 `gen集合 ∩ ∅ = ∅`——交集里只要有一方还是 ∅，结果就是 ∅；
而循环体的 ∅ 又依赖 H 的 ∅。**两个 ∅ 互相支撑，e 永远进不
来**。迭代收敛到了一个不动点，但那是最小不动点——对 may 是
"最精确的安全上界"，对 must 却是"最悲观的错误答案"：它连
语义上确实成立的事实都丢了。

根子在于：must 的迭代应当**只降不升**。全集 ⊤ 表示"先乐观地
假定一切成立，再用 kill 逐条削减"——每轮迭代要么把某个事实
因 kill 的理由剔除，要么维持原状；集合单调下降，有限格保证
终止，收敛到**最大不动点**。上面的例子里，H 先乐观地假定 e
可用，循环体把它原样保留，汇合的交不削减它——e 活到收敛，
给出正确答案。而真正不成立的事实（例如循环体内有一条 `a = 0`
杀掉了 e）会在迭代中沿回边把削减带回来，把 e 从 H 的集合里
挤出去。乐观假设不是冒险，而是**把举证责任反转**：must 的
语义是"所有路径都成立"，否定它需要一条具体的反例路径，迭代
正是搜索反例的过程；搜不到反例的事实，就是全部路径都成立的
事实。所以规格里 must 的 `initFull = true`：初值取全集，⊥
留给 may。

### 30.3.2 为什么边界点是 ∅

四行表格里有一个乍看刺眼的细节：must 两行的非边界点从全集
出发，**边界点却取 ∅**。前向 must（可用表达式）的边界是 entry，
逆向 must（非常忙表达式）的边界是 exit——两个边界都赋空集。
为什么最乐观的出发点偏偏在边界上最悲观？

因为边界点是唯一**没有猜测余地**的地方。entry 处程序一条语句
都没执行，任何表达式都不可能"已经算过"——这不是保守，是
事实；exit 处函数已经返回，任何表达式都不可能"之后还要算"。
边界值 ∅ 是语义强加的，与乐观悲观无关。而且注意，may 两行
的边界同样是 ∅：到达定值在 entry 处还没有任何定值流入，活跃
变量在 exit 处之后没有路径、没有使用。**四个分析的边界值全
是 ∅**——边界是分析的"地锚"，四个方向的地锚恰好都钉在
零信息处，这不奇怪：∅ 是幂集格里"什么都没发生"的规范写法。

实现上有个细节值得停一步：runDfa 对边界点的处理不是"赋一次
初值就锁死"，而是让它和普通点一样参与迭代——只是边界点在
信息流方向上**没有前驱**，合并取到空集（合并代码在无前驱时
给 ∅），于是每轮重算都得到 ∅，天然稳定。用"没有前驱"来表达
"边界为空"，比加一个特判分支更干净，也顺带保证了不可达点
（无前驱的点）对 must 不会永远挂在全集上。

### 30.3.3 全集不可枚举：用 gen 因子之并作可表示全集

还有一个诚实性问题必须正面回答。may 分析的初值 ∅ 有限又
好造；must 的初值是"全集"——可表达式全集有多大？TIP 的
表达式可以任意嵌套、任意组合，语法上合法的表达式有无穷多个，
"全集"根本枚举不完。怎么办？

答案是把"全集"换成"可表示全集"。论证分三步。**第一步**，
观察传递函数的形状：`out = gen ∪ (in ∖ kill)`——它**只会**
往集合里放 gen 里的因子。从任何初值出发迭代，一个因子若从不
出现在任何语句的 gen 里，就永远没有任何机制把它放进任何集合。
**第二步**，于是取"本函数全部语句的 gen 因子之并"记作 U′，
把初值从"真全集"换成 U′：这一步**不改变不动点**——迭代轨迹
上的每个集合本来就从不含 U′ 之外的因子，把初值裁剪到 U′
只是把不可能出现的部分预先剪掉。**第三步**，U′ 有限（语句
有限、每条语句的子式有限），下降迭代在有限格上必然终止。
三步合起来：用 U′ 冒充全集，既不改变答案，又让"全集"变成
一个能写进内存的东西。

这个论证值得回味，因为它示范了抽象解释的一个日常功夫：理论
要求 ⊤，实现给不出 ⊤，就构造一个"对本次分析而言行为等同
的 ⊤"。条件是论证清楚"等同"——上面的第一步就是论证。凡
是想在实现里偷换理论对象的地方，都要走这样一条"三步"：
观察不变量、论证等同、确认有限。

### 30.3.4 一点提醒：may 与 must 的单调方向相反

may 迭代从 ∅ 单调**上升**，must 从 U′ 单调**下降**。第 28 章
的终止性论证（每次重算严格变化则状态沿序移动，格高度有限）
在这个框架里要读两遍：上升一遍、下降一遍。runDfa 的代码对
两个方向一视同仁——它只比较"变了没有"，不关心变化朝哪边——
因为单调性由 gen/kill 的形状保证，不需要驱动器操心。这也是
"框架"一词的实现含义：驱动器只保留所有分析**共享**的机制
（队列、合并、比较、重排队），一切随分析而变的东西都进规格。

### 30.3.5 一笔代价账：迭代次数与集合规模

must 下降迭代与 may 上升迭代的代价公式完全对称。每次重算
要么严格改变某点状态、要么不动；状态沿格的序移动、格的高度
有限，故总变化次数有限。幂集格的高度是 |U′| + 1——从全集
剥到空集，每个因子至多"退场"一次（may 方向则至多"进场"
一次），因此迭代总变化次数不超过"点数 × |U′|"，每次合并与
传递的代价又正比于 |U′|，整体在 O(点数 × |U′|²) 量级。这个
看似平淡的界，正是位向量实现价值所在：|U′| 个因子压进一个
机器字的 |U′| 个位，并、交、差各化为几条按位指令，|U′| 因子
缩成常数，整个分析退化为接近线性。字符串集合实现则在每个
因子上多付一次对数级的比较与一次分配——本章选它换的是
代码清晰，不是性能。

顺序影响的是**轮次**而非**终态**：第 28 章已证明任意公平的
队列顺序收敛到同一不动点。must 的经验规律与 may 对称——按
信息流方向处理（后向分析即沿 CFG 逆向），一轮就能把削减信息
推完一整条直路，收敛轮次接近"图的深度 + 回边数"；乱序则
可能多滚若干轮。runDfa 用 FIFO、首遍按点编号入队，而点编号
恰是程序顺序（第 14 章的编号约定在此再次回报）——对
classic.tip 这类顺序良好的程序几乎是最优序。18.6.8 的纸上
追踪会展示这一点：削减信息像多米诺，从边界一路倒到入口。

## 30.4 本章复用的前端机器

四个分析的输入是 CFG，CFG 的输入是 AST，AST 的输入是 ANTLR
parse tree。这条流水线在第 10–14 章逐节建成，本章原样复用、
一行不改。为了对账完整（check_docs 要求每章嵌入其示例的全部
源文件），本节把它们集中嵌入，每件配两三句"在四分析中扮演
什么角色"的交代；已读过第 10–14 章的读者可以快速滑过。

### 30.4.1 文法：TIP.g4

文法自第 4 章冻结。本章用到的只有语句层的四条——赋值、输出、
if、while——它们决定了 CFG 的形状，进而决定了四分析的方程。

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

### 30.4.2 AST 定义与构建

AST 是四个分析共用的程序表示。gen/kill 的提取（18.6.1 节）靠
`dynamic_cast` 在这些节点类型上分类——`AssignS` 给出赋值目标
（kill 的依据），右值表达式给出使用与子式（gen 的依据）。

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

构建器把 parse tree 翻成上述 AST。四分析不直接碰它，但
classic.tip 的每个语句节点都出自这里。

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

### 30.4.3 CFG：数据流的载体

第 14 章反复强调：数据流分析的载体是**图**而不是树。本章的
`flow`/`flowSucc` 两张邻接表（18.6.2 节）直接建在 `FunCfg` 的
`edges` 之上；`entry` 与 `exitNode` 两个哨兵点是前向与后向分析
各自的边界。

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

### 30.4.4 打印器与名字解析

打印器把 AST 以固定前缀式重新打印——`printDfa` 的节点标签
直接调它的单行形式。名字解析与四分析没有数据依赖（四分析按
变量**名字**为因子，不做作用域敏感的区分），但 main.cpp 仍然
先跑一遍解析，让带病程序在分析之前就被拦下。

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

## 30.5 DfaSpec：把一个分析压缩成一条规格

### 30.5.1 五个字段，一条分析

18.2.1 节说"一个分析 = 一个因子空间 + 一条规格"，现在把这句
话写成 C++。规格结构体 `DfaSpec` 一共五个字段，每个字段对应
18.2.2 分类表的一列：

```cpp
// file: src/dfa.hpp
// 四大经典数据流分析（spa 2 章传统内容，用第 28 章框架统一实现）：
//   活跃变量（后向 may）、到达定值（前向 may）、
//   可用表达式（前向 must）、非常忙表达式（后向 must）。
// 四者共用幂集格，差异只在三个参数：方向（前/后）、合并（∪ may/∩ must）、
// gen/kill 与边界条件。runDfa 按 spec 参数一次性驱动。
#pragma once

#include <functional>
#include <map>
#include <set>
#include <string>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

using FactSet = std::set<std::string>;

struct DfaSpec {
    std::string name;
    bool forward;  // true: 信息沿边正向传播；false: 逆向
    bool may;      // true: 合并取并(may)；false: 交(must)
    // gen/kill 以语句为单位：返回该语句在相应方向上产生/杀死的因子。
    std::function<FactSet(const Stmt *)> gen;
    std::function<FactSet(const Stmt *)> kill;
    // must 分析在入口/出口边界取全集还是空集，由 initFull 指定。
    bool initFull = false;
};

// 结果：程序点 → 该点沿分析方向"流出"状态（transfer 之后）。
// 打印时按点给出集合内容。
std::map<int, FactSet> runDfa(const Cfg &cfg, const DfaSpec &spec);

std::string printDfa(const Cfg &cfg, const std::map<int, FactSet> &result,
                     const DfaSpec &spec);

// gen/kill 语句分类的公共实现（四分析共用）。
std::set<std::string> exprVars(const Expr *e);      // 右值中出现的变量
std::string assignTargetName(const Stmt *s);        // 赋值目标（标量）或 ""
std::set<std::string> exprSubTerms(const Expr *e);  // 表达式的子式文本（t op u 按名）
// 语句所"计算"的表达式（赋值右值/输出/返回/分支条件）；不计算的语句返回空。
const Expr *stmtExpr(const Stmt *s);

}  // namespace tip
```

`FactSet` 是 `std::set<std::string>`——因子就是字符串。这不是
偷懒，而是本章的一次刻意选择：四个分析的因子空间不同（变量、
定值、子式），但它们在框架里的角色完全一致——可比较、可并、
可交、可差。字符串集合让四个分析共享**同一个**容器类型与
**同一份**合并/传递代码，规格之间的差异被逼进五个字段里。
代价（字符串比较比位向量慢、因子必须是可打印的名字）在教学
规模下无关紧要；到第 32 章之后需要性能时，换成位向量只需替换
`FactSet` 的定义与合并循环，`runDfa` 的骨架不动。

五个字段逐一对表：

- `name`：纯打印用，但它有一个隐性作用——输出协议里每个分析
  段以 `== name ==` 开头，对账脚本按它切段。
- `forward`：方向。true 沿边正向，false 逆向。它决定 18.6.2
  节两张邻接表怎么建、以及边界点取 entry 还是 exit。
- `may`：量词。true 合并取并，false 取交。它决定合并分支、
  传递分支，以及初值是 ∅ 还是全集。
- `gen`/`kill`：两个以语句为单位的函数对象。注意它们是**按
  语句**回答"产生什么、作废什么"，不关心方向——同一条
  `s = s - 1`，在活跃变量（后向）里 gen 是它使用的 {s}，在
  到达定值（前向）里 gen 是它自己的定值 d6；差异全在 main.cpp
  怎么填这两个函数对象，规格结构本身一视同仁。
- `initFull`：must 分析置 true，驱动器把非边界点初始化为全集
  （18.3.3 节的可表示全集 U′）。may 分析走默认 false。

字段下面还声明了四个自由函数——`exprVars`、`assignTargetName`、
`exprSubTerms`、`stmtExpr`。它们是 gen/kill 提取的**公共词表**：
四分析对"一条语句用了什么、算了什么、改了什么"的提问方式
高度重叠，公共词表避免每个分析各写一遍 AST 遍历。实现全在
dfa.cpp，18.6.1 节逐个看。

### 30.5.2 结果的读法：沿分析方向的"流出"状态

`runDfa` 返回 `map<int, FactSet>`：程序点编号 → 该点的状态。
一个必须先讲清的语义约定藏在头文件注释里：存的是该点**沿
分析方向**流出、即传递函数**之后**的状态。前向分析里，这是
传统记号的 OUT——语句执行完之后的集合；**后向分析里，这是
沿逆向流的"流出"，按程序顺序读恰好是语句执行之前的状态**——
传统记号的 IN。所以打印结果要按分析的方向读：

- 活跃变量一行 `6 s = a + b : {a,b,c}` 读作"执行这条赋值
  **之前**，{a,b,c} 活跃"；
- 到达定值一行 `2 a = input : {d1}` 读作"执行这条赋值**之后**，
  {d1} 到达"。

同一个 map，两种读法，由 `forward` 决定。这个约定让打印器
完全不用关心方向——它只负责把 map 印出来，语义解读留给读者
（以及 30.8 节的逐段讲解）。

## 30.6 runDfa 逐函数深讲

### 30.6.1 gen/kill 的公共词表

先读四个公共函数，它们把"语句的事实"从 AST 里挖出来：

```cpp
// file: src/dfa.cpp
#include "dfa.hpp"

#include <deque>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

std::set<std::string> collectVars(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        (void)x;
    } else if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        r.insert(x->name);
    } else if (dynamic_cast<const InputE *>(e)) {
        r.insert("input");
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = collectVars(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = collectVars(x->r.get());
        r.insert(rr.begin(), rr.end());
    } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
        for (const auto &a : x->args) {
            std::set<std::string> s = collectVars(a.get());
            r.insert(s.begin(), s.end());
        }
    }
    return r;
}

// 子式文本（供可用/非常忙的"因子"）：把 (a+b)*c 记成 ((a+b)*c) 的名字。
std::string termText(const Expr *e) {
    std::string out;
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        out = std::to_string(x->v);
    } else if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        out = x->name;
    } else if (dynamic_cast<const InputE *>(e)) {
        out = "input";
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        static const char *op[] = {"+", "-", "*", "/", ">", "=="};
        out = "(" + termText(x->l.get()) + op[static_cast<int>(x->op)] +
              termText(x->r.get()) + ")";
    }
    return out;
}

std::set<std::string> collectTerms(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = collectTerms(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = collectTerms(x->r.get());
        r.insert(rr.begin(), rr.end());
        r.insert(termText(e));
    }
    return r;
}

}  // namespace

std::set<std::string> exprVars(const Expr *e) { return collectVars(e); }
std::string assignTargetName(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s))
        if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
            return t->name;
    return "";
}
std::set<std::string> exprSubTerms(const Expr *e) { return collectTerms(e); }
const Expr *stmtExpr(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s)) return a->value.get();
    if (const auto *o = dynamic_cast<const OutputS *>(s)) return o->e.get();
    if (const auto *r = dynamic_cast<const ReturnS *>(s)) return r->e.get();
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return w->cond.get();
    if (const auto *i = dynamic_cast<const IfS *>(s)) return i->cond.get();
    return nullptr;
}

std::map<int, FactSet> runDfa(const Cfg &cfg, const DfaSpec &spec) {
    std::map<int, FactSet> cur;  // 每点"流出"状态（沿信息流方向施加 gen/kill 后）

    for (const FunCfg &fc : cfg.funs) {
        // 邻接表按分析方向取：flow[p]=信息流方向上为 p 供状态的前驱点，
        // flowSucc[p]=状态变化时需要重算的后继点。
        std::map<int, std::vector<int>> flow, flowSucc;
        for (const auto &[a, b] : fc.edges) {
            if (spec.forward) {
                flow[b].push_back(a);
                flowSucc[a].push_back(b);
            } else {
                flow[a].push_back(b);
                flowSucc[b].push_back(a);
            }
        }

        // 边界点：前向=entry，逆向=exit。
        const int boundary = spec.forward ? fc.entry : fc.exitNode;

        // must 分析的非边界点初始为全集；全集无法枚举时取"本函数全部
        // 语句 gen 因子之并"作为可表示的全集（有限因子假设）。
        FactSet universe;
        if (!spec.may)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt) {
                    std::set<std::string> g = spec.gen(node.stmt);
                    universe.insert(g.begin(), g.end());
                }

        // 初始化：may 从空集出发；must 的非边界点从全集出发、边界为空。
        // 全部点先入队一遍，保证初值无一被跳过。
        std::deque<int> wl;
        std::set<int> inQ;
        for (const auto &[id, node] : fc.nodes) {
            FactSet init;
            if (!spec.may && id != boundary) init = universe;
            cur[id] = init;
            wl.push_back(id);
            inQ.insert(id);
        }

        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            inQ.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            // 合并信息流前驱的流出状态（may=并，must=交；无前驱时取幺元）。
            FactSet merged;
            bool first = true;
            auto fit = flow.find(p);
            if (fit != flow.end()) {
                for (int q : fit->second) {
                    const FactSet &qs = cur[q];
                    if (first) {
                        merged = qs;
                        first = false;
                    } else if (spec.may) {
                        merged.insert(qs.begin(), qs.end());
                    } else {
                        FactSet inter;
                        for (const std::string &f : qs)
                            if (merged.count(f)) inter.insert(f);
                        merged = inter;
                    }
                }
            }

            // 施加本点 gen/kill：may=先 kill 后 gen（并）；must=保留 ∖kill 再补 gen。
            FactSet out = merged;
            if (node.stmt) {
                FactSet g = spec.gen(node.stmt);
                FactSet k = spec.kill(node.stmt);
                if (spec.may) {
                    for (const std::string &f : k) out.erase(f);
                    for (const std::string &f : g) out.insert(f);
                } else {
                    FactSet keep;
                    for (const std::string &f : out)
                        if (!k.count(f)) keep.insert(f);
                    keep.insert(g.begin(), g.end());
                    out = std::move(keep);
                }
            }

            // 只有变化才重算信息流后继（单调框架保证有界）。
            if (out != cur[p]) {
                cur[p] = out;
                auto sit = flowSucc.find(p);
                if (sit != flowSucc.end())
                    for (int s : sit->second)
                        if (!inQ.count(s)) {
                            wl.push_back(s);
                            inQ.insert(s);
                        }
            }
        }
    }
    return cur;
}

std::string printDfa(const Cfg &cfg, const std::map<int, FactSet> &result,
                     const DfaSpec &spec) {
    std::ostringstream out;
    out << "== " << spec.name << " ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) {
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << " branch  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << " branch  if " << printExpr(i->cond.get());
                else
                    out << " " << printStmtLine(*node.stmt);
            }
            out << ':';
            const FactSet &fs = result.at(id);
            if (fs.empty()) {
                out << " {}\n";
                continue;
            }
            out << " {";
            bool first = true;
            for (const std::string &f : fs) {
                if (!first) out << ",";
                out << f;
                first = false;
            }
            out << "}\n";
        }
    }
    return out.str();
}

}  // namespace tip
```

**`collectVars`（即 `exprVars`）**：递归收集表达式里出现的变量
名。活跃变量的 gen 就靠它。两处细节有讲解价值。其一，`InputE`
贡献一个伪因子 `"input"`——每次 `input` 都被视为读一次名为
input 的输入流，于是 `a = input` 这条语句"使用"了 input；
这不是为了好玩，而是为了语义诚实：`a = input` 显然不是死赋值
（它读了输入流），让 input 进 gen 集合正是这个直觉的形式化。
代价是输出里会出现 `{input}` 这样的因子（18.8.1 节的 entry 行），
读者第一次见到会愣一下，看懂伪变量的设定就不愣了。其二，
`Binop` 递归两臂、`CallE` 递归实参——Deref、FieldA 等指针/记录
节点没有出现在 collectVars 里，它们对变量名的贡献会被跳过；
这是本实现的一条已知边界（TIP 的指针分析要到后面篇章才登场），
classic.tip 恰好不含这些构造，输出不受影响。

**`termText` 与 `collectTerms`（即 `exprSubTerms`）**：可用/非常忙
两个分析的因子是"子式文本"。`termText` 把表达式打成带括号的
中缀文本——`(a+b)`、`((a+b)*c)`——括号保证因子唯一：`(a+b)`
与 `a+b` 的文本不同，`((a+b)*c)` 与 `(a*b+c)` 更是两个因子，
纯语法身份、绝不含糊。`collectTerms` 收集一棵表达式树里的
**全部**二元子式：对 `(a+b)*c` 返回 `{(a+b), ((a+b)*c)}`——
叶子（变量、常量）不算因子，因为"一个变量可用"没有复用价值，
值得记录的是每次都要花指令去算的运算。为什么把整棵子树都
算进 gen？因为 `a = a + b` 不仅计算了整个右值 `(a+b)`，也
"顺便"计算了它的子式——子式的值同样留在寄存器里可供复用。
两个表达式分析共用这一对函数，一个前向（问过去算过没有）、
一个后向（问未来要不要算），gen 的语义在两个方向上恰好都是
"这条语句会执行的求值"。

**`assignTargetName`**：给出赋值语句的标量目标名，非赋值或
非标量目标（字段、解引用）返回空串。它是两个 kill 的支点：
活跃变量的 kill 是 `{目标}`（赋值后旧值作废），表达式分析的
kill 是"所有含目标的子式"。返回空串的分支同样有语义：目标
非标量时本实现不产生 kill——又一条已知边界，同样被
classic.tip 绕开。

**`stmtExpr`**：回答"这条语句计算哪个表达式"。覆盖五类：赋值
（右值）、输出、返回、if 与 while 的条件。把分支条件算进
"语句计算的表达式"是刻意的——`while (s > 0)` 每次迭代都要求值
`s>0`，它既产生可用表达式（判完之后 `(s>0)` 刚算过）、也在
非常忙分析里属于"躲不掉的计算"（每条路径到这都要判）。output
同理。`stmtExpr` 返回 null 的语句（空块等）在 gen/kill 里自然
给出空集——没有求值就没有事实。

### 30.6.2 方向翻转：flow 与 flowSucc 两张表

下面进入驱动器主体。第一件事是把 CFG 的边翻译成**信息流方向**
的邻接表——这是全章方向语义唯一的落地点：

```cpp
std::map<int, FactSet> runDfa(const Cfg &cfg, const DfaSpec &spec) {
    std::map<int, FactSet> cur;  // 每点"流出"状态（沿信息流方向施加 gen/kill 后）

    for (const FunCfg &fc : cfg.funs) {
        // 邻接表按分析方向取：flow[p]=信息流方向上为 p 供状态的前驱点，
        // flowSucc[p]=状态变化时需要重算的后继点。
        std::map<int, std::vector<int>> flow, flowSucc;
        for (const auto &[a, b] : fc.edges) {
            if (spec.forward) {
                flow[b].push_back(a);
                flowSucc[a].push_back(b);
            } else {
                flow[a].push_back(b);
                flowSucc[b].push_back(a);
            }
        }

        // 边界点：前向=entry，逆向=exit。
        const int boundary = spec.forward ? fc.entry : fc.exitNode;
```

逐行读。`fc.edges` 里的每条边 `a → b` 是 CFG 语义的"控制可能
从 a 流到 b"。前向分析里，b 的状态由它的 CFG 前驱们供出，于是
`flow[b] += a`；a 的状态变了，受影响的是它的 CFG 后继，于是
`flowSucc[a] += b`。后向分析把两个方向都翻过来：a 的状态由
**后继** b 供出（`flow[a] += b`），b 变了要重算的是**前驱** a
（`flowSucc[b] += a`）。

两张表分工明确，正对应第 28 章 worklist 的两个角色：`flow`
在**计算**一个点时被枚举（合并谁的状态），`flowSucc` 在一个点
**变化**后被枚举（通知谁重算）。方向翻转只发生在这里——后面
的合并、传递、重排队代码对 `spec.forward` 完全无感。这就是
"方向是框架参数"的实现形态：不是散布在各处的 if，而是入口处
的一次性翻译。

`boundary` 的选取同源：前向分析的边界是 entry（信息从这进入
图），后向分析是 exitNode（逆向信息从这进入图）。第 14 章 CFG
构造时特意保留这两个哨兵点，就是为了此刻。

### 30.6.3 全集与初始化：must 乐观、may 悲观、全员入队

```cpp
        // must 分析的非边界点初始为全集；全集无法枚举时取"本函数全部
        // 语句 gen 因子之并"作为可表示的全集（有限因子假设）。
        FactSet universe;
        if (!spec.may)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt) {
                    std::set<std::string> g = spec.gen(node.stmt);
                    universe.insert(g.begin(), g.end());
                }

        // 初始化：may 从空集出发；must 的非边界点从全集出发、边界为空。
        // 全部点先入队一遍，保证初值无一被跳过。
        std::deque<int> wl;
        std::set<int> inQ;
        for (const auto &[id, node] : fc.nodes) {
            FactSet init;
            if (!spec.may && id != boundary) init = universe;
            cur[id] = init;
            wl.push_back(id);
            inQ.insert(id);
        }
```

第一段就是 18.3.3 节的"三步论证"落地：`universe` 只在 must
时构造，内容是**本函数**每条语句 gen 因子之并。注意范围是
函数级而非程序级——四分析都不跨函数传信息（TIP 的过程间分析
在后面篇章），每个函数独立解自己的方程组，U′ 也按函数各造
各的。`spec.gen(node.stmt)` 在这里被复用：构造全集与稍后传递
用的是同一个 gen 函数，"全集 = 所有 gen 之并"的不变量由构造
方式自动保证。

第二段三个动作。**赋初值**：may 全 ∅；must 非边界点取 U′、
边界点取 ∅——18.3.1 与 18.3.2 的结论各占一半。**全员入队**：
这是初学者最容易漏的一步，值得单独论证。worklist 的常规节奏
是"某点变化，后继入队"；若初始队列只放边界点，must 的非边界
点将**永远停在全集上**——它们是"待反驳的乐观假设"，必须至少
被真正计算一次（合并真实的前驱状态、施加真实的 kill），才有
机会被削减；若初始队列只放边界点，这些点从未被计算，打印出来
就是一列毫无信息量的全集。全员入队一遍，保证每个点至少获得
一次"以真实邻居为准"的重算。对 may 同样必要：从 ∅ 出发的上升
迭代，若某点从未入队，它就停在 ∅，而它的正确值未必是 ∅。
第 28 章的 solve.cpp 有同样的全员首遍入队，理由相同——那是
"初值无一被跳过"的通用要求，不因 may/must 而异。**inQ 集合**：
队列去重，一个点同时在队列里只留一份，防止同一轮里重复计算；
这与第 28 章的实现一致。

### 30.6.4 合并：may 取并、must 取交、无前驱取空集

```cpp
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            inQ.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            // 合并信息流前驱的流出状态（may=并，must=交；无前驱时取幺元）。
            FactSet merged;
            bool first = true;
            auto fit = flow.find(p);
            if (fit != flow.end()) {
                for (int q : fit->second) {
                    const FactSet &qs = cur[q];
                    if (first) {
                        merged = qs;
                        first = false;
                    } else if (spec.may) {
                        merged.insert(qs.begin(), qs.end());
                    } else {
                        FactSet inter;
                        for (const std::string &f : qs)
                            if (merged.count(f)) inter.insert(f);
                        merged = inter;
                    }
                }
            }
```

合并循环是量词参数的主场。第一个前驱的状态直接作为底（`first`
分支——这避免了"从空集开始求交"的经典错误：must 的交必须以
某股真实来流为起点，若从 ∅ 开始交，结果恒为 ∅）；后续前驱
按 `spec.may` 分派：may 往里并，must 求交（遍历新来流的因子、
只保留底里已有的）。

无前驱的分支藏在 `merged` 的默认值里：`FactSet merged;` 就是
∅。对边界点，这正是 18.3.2 要求的边界值 ∅——边界点的"合并"
就是"没有来流"，语义自然成立；对不可达点同理。代码注释里写
"取幺元"：并的幺元是 ∅，所以 may 在无来流时取 ∅ 恰是幺元律；
must 严格说幺元是全集，但"无来流"只发生在边界与不可达点，
而这两类点的语义值恰好都是 ∅，于是用 ∅ 兜底既简单又正确。
这里体现了 18.3.2 的实现红利：**边界值 ∅ 与"无前驱"的缺省值
重合，免去了特判**。

### 30.6.5 传递：先 kill 后 gen，must 先删后补

```cpp
            // 施加本点 gen/kill：may=先 kill 后 gen（并）；must=保留 ∖kill 再补 gen。
            FactSet out = merged;
            if (node.stmt) {
                FactSet g = spec.gen(node.stmt);
                FactSet k = spec.kill(node.stmt);
                if (spec.may) {
                    for (const std::string &f : k) out.erase(f);
                    for (const std::string &f : g) out.insert(f);
                } else {
                    FactSet keep;
                    for (const std::string &f : out)
                        if (!k.count(f)) keep.insert(f);
                    keep.insert(g.begin(), g.end());
                    out = std::move(keep);
                }
            }
```

两个分支写的其实是**同一条公式** `out = gen ∪ (in ∖ kill)`，
只是集合操作的组织方式不同。may 分支：在 `merged` 上先逐个
erase kill 的因子、再逐个 insert gen 的因子。must 分支：新建
`keep`，只收 `merged` 里不被 kill 的因子，然后并入 gen——
等价于 `(merged ∖ kill) ∪ gen`。

**顺序为什么重要？** 考虑 gen 与 kill 相交的语句。`s = s - 1`
在活跃变量里 kill {s}、gen {s}（右值用了 s）：先 kill 再 gen，
得到 {s}——正确，因为赋值执行前旧 s 的值正要被读；若先 gen
再 kill，s 会被误删，分析会说"这条语句执行前 s 不活跃"，从而
把一条自用的赋值误判为死赋值。到达定值里 `a = a + b` 同理：
kill 同变量的旧定值 d1、gen 新定值 d7，先杀后生成保证新定值
不被自己的 kill 误伤（kill 的构造已排除本语句，但顺序仍是
防御性的正确写法）。must 分支的"先删后补"在 classic.tip 里有
一个现成的现场：节点 10 `a = a + b` 的可用表达式传递——kill
把 `(a+b)` 删掉（含 a），gen 又把它补回来（右值恰是它），
一来一回之后 `(a+b)` 仍在流出集合里，但身份变了：从"上游算过
的旧值"变成"本语句刚算的新值"。18.8.3 节会回到这个现场。

还有一行细节：`if (node.stmt)`。entry、exit 与空块节点没有
语句，合并结果直接透传为流出状态——它们是纯粹的"管道"，
只搬运不加工。管道点的存在让边界处理与汇合处理共用同一套
代码，也是第 14 章 CFG 里哨兵点的又一次回报。

### 30.6.6 变化驱动：比较、写回、重排队

```cpp
            // 只有变化才重算信息流后继（单调框架保证有界）。
            if (out != cur[p]) {
                cur[p] = out;
                auto sit = flowSucc.find(p);
                if (sit != flowSucc.end())
                    for (int s : sit->second)
                        if (!inQ.count(s)) {
                            wl.push_back(s);
                            inQ.insert(s);
                        }
            }
        }
    }
    return cur;
}
```

收尾的套路与第 28 章逐字同构，但有一处理由在此刻更显眼：**比较
在先、写回在后**。`out != cur[p]` 不成立就什么都不做——既不写
回也不入队后继。对 must 分析这一步省得格外多：非边界点从全集
出发，早期迭代里集合大幅收缩、比较频繁成立；接近收敛时，大量
点的重算结果与旧值相同，空转被这一行挡住。变化了才重算后继，
配合 `inQ` 去重，就是"变化驱动"的完整含义：**工作量正比于
实际发生的状态迁移次数**，而单调性保证迁移次数有限（may 只升、
must 只降，格高度封顶）。终止性论证在这里只需引用 18.3.4 与
第 28 章，一个字不用改——这正是框架化的收益：理论做一次，
四个分析共用。

### 30.6.7 printDfa：按点打印的输出协议

```cpp
std::string printDfa(const Cfg &cfg, const std::map<int, FactSet> &result,
                     const DfaSpec &spec) {
    std::ostringstream out;
    out << "== " << spec.name << " ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) {
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << " branch  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << " branch  if " << printExpr(i->cond.get());
                else
                    out << " " << printStmtLine(*node.stmt);
            }
            out << ':';
            const FactSet &fs = result.at(id);
            if (fs.empty()) {
                out << " {}\n";
                continue;
            }
            out << " {";
            bool first = true;
            for (const std::string &f : fs) {
                if (!first) out << ",";
                out << f;
                first = false;
            }
            out << "}\n";
        }
    }
    return out.str();
}

}  // namespace tip
```

打印器没有任何分析逻辑，只有两条协议值得记录。其一，段头
`== spec.name ==` 用的是规格里的 `name` 字段——对账脚本按这个
头切四段，名字即协议。其二，分支节点打印成 `branch while (...)`
/ `branch if (...)` 而不是带分号的完整语句——分支点在 CFG 上
是"判断处"而不是"执行完的语句"，标签用 branch 前缀提醒读者
这一行的集合语义（尤其后向分析）是"进入判断之前"的状态。
`{}` 与非空集合两种排版保证输出逐字符确定，`std::map<int,...>`
按点编号升序遍历，行序即程序点序。

## 30.7 四个分析的总装：main.cpp

驱动器只认规格。四条规格从哪里来？main.cpp。它做三件事：
解析程序、构造 CFG，然后把四个 `DfaSpec` 逐一填好、逐次交给
`runDfa`、打印。四个分析在同一份 CFG 上先后跑四遍，各自得到
一张"程序点 → 因子集合"的表。

```cpp
// file: src/main.cpp
// 第 30 章配套程序：四大经典数据流分析总装。
//   --check FILE : 对同一程序分别跑活跃变量/到达定值/可用表达式/非常忙表达式，
//                  逐点打印"流出"因子集合
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "dfa.hpp"
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
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    Parsed p = parseFile(argv[2]);
    tip::Cfg cfg = tip::buildCfg(*p.ast);
    using tip::FactSet;

    // 活跃变量（后向 may）：gen=语句使用的变量，kill=被赋值变量。
    tip::DfaSpec live{"live variables (backward, may)", false, true,
                      [](const tip::Stmt *s) -> FactSet {
                          const tip::Expr *e = tip::stmtExpr(s);
                          if (!e) return {};
                          return tip::exprVars(e);
                      },
                      [](const tip::Stmt *s) -> FactSet {
                          std::string t = tip::assignTargetName(s);
                          if (t.empty()) return {};
                          return {t};
                      }};

    // 到达定值（前向 may）：因子=定值点编号 dN；gen=本定值，kill=同变量的其余定值。
    std::map<const tip::Stmt *, std::string> defName;
    {
        int d = 0;
        for (const tip::FunCfg &fc : cfg.funs)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt && tip::assignTargetName(node.stmt) != "")
                    defName[node.stmt] = "d" + std::to_string(++d) + "(" +
                                         tip::assignTargetName(node.stmt) + "@" +
                                         fc.name + ":" + std::to_string(id) + ")";
    }
    tip::DfaSpec reaching{"reaching definitions (forward, may)", true, true,
                          [&defName](const tip::Stmt *s) -> FactSet {
                              auto it = defName.find(s);
                              if (it == defName.end()) return {};
                              return {it->second};
                          },
                          [&defName](const tip::Stmt *s) -> FactSet {
                              auto it = defName.find(s);
                              if (it == defName.end()) return {};
                              std::string t = tip::assignTargetName(s);
                              FactSet k;
                              for (const auto &[stmt, name] : defName)
                                  if (stmt != s &&
                                      tip::assignTargetName(stmt) == t)
                                      k.insert(name);
                              return k;
                          }};

    // 可用/非常忙表达式（must）：因子=子式文本；gen=语句计算的子式，
    // kill=全程序中含被赋值变量的子式（教学实现，够用且单调）。
    std::set<std::string> allTerms;
    for (const tip::FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (node.stmt) {
                const tip::Expr *e = tip::stmtExpr(node.stmt);
                if (e) {
                    FactSet fs = tip::exprSubTerms(e);
                    allTerms.insert(fs.begin(), fs.end());
                }
            }
    auto killByTarget = [&allTerms](const tip::Stmt *s) -> FactSet {
        std::string t = tip::assignTargetName(s);
        if (t.empty()) return {};
        FactSet k;
        for (const std::string &term : allTerms)
            if (term.find(t) != std::string::npos) k.insert(term);
        return k;
    };
    auto genTerms = [](const tip::Stmt *s) -> FactSet {
        const tip::Expr *e = tip::stmtExpr(s);
        if (!e) return {};
        return tip::exprSubTerms(e);
    };
    tip::DfaSpec available{"available expressions (forward, must)", true, false,
                           genTerms, killByTarget};
    tip::DfaSpec veryBusy{"very busy expressions (backward, must)", false, false,
                          genTerms, killByTarget};

    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, live), live);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, reaching), reaching);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, available), available);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, veryBusy), veryBusy);
    return 0;
}
```

### 30.7.1 活跃变量与到达定值：两条规格的填法

**live** 的 gen 是 `exprVars(stmtExpr(s))`——语句计算的求值里
用到的变量；kill 是赋值目标。`stmtExpr` 返回 null 的语句（如
空块）gen 给空；`assignTargetName` 给空串的语句（输出、分支）
kill 给空。两个 lambda 加起来十行，把 18.1.1 问题一的直觉
原样翻译成代码。

**reaching** 的填法多了一道预处理：先扫一遍 CFG，给每个赋值
语句编号并记下它的因子名——`d1(a@main:2)` 这样的字符串把
三样信息（编号、变量、位置）压进一个因子里，打印时可读，
比较时可当唯一键。编号循环先 `fc.funs` 后 `fc.nodes`（`std::map`
按编号升序），所以 d1、d2……严格按程序点顺序产生，输出确定。
gen 查表给出本定值；kill 遍历全表、取**同变量**的其余定值——
`a = a + b` 的 kill 是 d1，虽然 d1 在程序里远在前面。注意 kill
不看"是否还在当前集合里"，把不相干的定值也列进 kill 无害：
集合运算里删一个不存在的元素等于没删。这条"kill 宁多勿漏"
的写法习惯，在下面表达式分析的 kill 里走到了极端。

### 30.7.2 可用与非常忙：一对只差一个布尔值的孪生规格

表达式分析的预处理构造 `allTerms`——**全程序**所有语句计算的
子式之并。这正是 18.3.3 节 U′ 的手工版：本实现把它提到 main
里一次构造，四个 `runDfa` 调用共享（语法上它其实应该是
`runDfa` 内部按函数构造的那份全集的等价物；全程序之并是
各函数之并的超集，多出来的因子永远进不了该函数的任何集合，
无害）。

`killByTarget` 是全文件最"粗"的一段：因子文本里**子串**含有
赋值目标名就算被杀。对 `a = ...`，`(a+b)`、`(a>0)` 都含子串
`a`，杀；连 `(a>0)` 里没有 b 也会在 `b = ...` 时被精确放过
（不含子串 b）。粗在哪里？若程序同时有变量 `a` 和 `ab`，
`a = ...` 会把 `(ab+1)` 也误杀（`ab` 含子串 `a`）。为什么敢粗？
因为**多杀对 must 只损失精度、不损失正确性**：把没被改变的
表达式误判为"不可用"，CSE 少复用一次而已；同理对非常忙只是
少报可外提的机会。这条粗化的代价与收益在 30.10 节还会提到。

`available` 与 `veryBusy` 两条规格并排看——它们共用同一对
`genTerms`/`killByTarget`，字段几乎逐字相同，**唯一差异是第二个
布尔值**：`true, false` 对 `false, false`。前向 must 与后向 must
在代码里隔着的距离只有一个参数。这正是 18.2.5 象限图的实现
回声：前向问过去、后向问未来，机器是同一台，探照灯转了 180 度。

### 30.7.3 总装的次序

末尾四行按"may 前、must 后；每个先 runDfa 后 printDfa"的节奏
把四段输出推到 stdout。四次 `runDfa` 互不共享状态——每次调用
从初值重新迭代，因为四个分析的格、初值、方向全不同，没有
可复用的中间结果；"对同一程序跑多个分析"共享的只有 CFG 与
预处理表，`Parsed` 与 `cfg` 在 main 顶部一次构造、四处使用。
解析失败（exit 2）与名字错误（exit 3）在任何分析开始前就拦下，
输出协议因此保证：只要走到了打印，输入就是通过了第 12 章全部
检查的合法程序。

## 30.8 真实输出逐段解读

现在把四段输出并排摆在桌上。先嵌入程序对应的期望输出全文，
然后逐段精读——这一节是本章的重头戏，前面所有概念都要在
这些具体行上落地。

```text
; expected: expected/output.txt
== classic.tip ==
== live variables (backward, may) ==
-- main --
  1: {input}
  2 a = input ;: {input}
  3 b = input ;: {a,input}
  4 c = 0 ;: {a,b}
  5 branch  if (> a 0): {a,b,c}
  6 s = (+ a b) ;: {a,b,c}
  7 s = (+ a b) ;: {a,b,c}
  8 branch  while (> s 0): {a,b,c,s}
  9 s = (- s 1) ;: {a,b,c,s}
  10 a = (+ a b) ;: {a,b,c,s}
  11 output (+ a b) ;: {a,b,c}
  12 output c ;: {c}
  13 return 0 ;: {}
  14: {}
== reaching definitions (forward, may) ==
-- main --
  1: {}
  2 a = input ;: {d1(a@main:2)}
  3 b = input ;: {d1(a@main:2),d2(b@main:3)}
  4 c = 0 ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4)}
  5 branch  if (> a 0): {d1(a@main:2),d2(b@main:3),d3(c@main:4)}
  6 s = (+ a b) ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6)}
  7 s = (+ a b) ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d5(s@main:7)}
  8 branch  while (> s 0): {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6),d5(s@main:7),d6(s@main:9),d7(a@main:10)}
  9 s = (- s 1) ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d6(s@main:9),d7(a@main:10)}
  10 a = (+ a b) ;: {d2(b@main:3),d3(c@main:4),d6(s@main:9),d7(a@main:10)}
  11 output (+ a b) ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6),d5(s@main:7),d6(s@main:9),d7(a@main:10)}
  12 output c ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6),d5(s@main:7),d6(s@main:9),d7(a@main:10)}
  13 return 0 ;: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6),d5(s@main:7),d6(s@main:9),d7(a@main:10)}
  14: {d1(a@main:2),d2(b@main:3),d3(c@main:4),d4(s@main:6),d5(s@main:7),d6(s@main:9),d7(a@main:10)}
== available expressions (forward, must) ==
-- main --
  1: {}
  2 a = input ;: {}
  3 b = input ;: {}
  4 c = 0 ;: {}
  5 branch  if (> a 0): {(a>0)}
  6 s = (+ a b) ;: {(a+b),(a>0)}
  7 s = (+ a b) ;: {(a+b),(a>0)}
  8 branch  while (> s 0): {(a+b),(s>0)}
  9 s = (- s 1) ;: {(a+b),(s-1)}
  10 a = (+ a b) ;: {(a+b),(s-1)}
  11 output (+ a b) ;: {(a+b),(s>0)}
  12 output c ;: {(a+b),(s>0)}
  13 return 0 ;: {(a+b),(s>0)}
  14: {(a+b),(s>0)}
== very busy expressions (backward, must) ==
-- main --
  1: {}
  2 a = input ;: {}
  3 b = input ;: {(a>0)}
  4 c = 0 ;: {(a+b),(a>0)}
  5 branch  if (> a 0): {(a+b),(a>0)}
  6 s = (+ a b) ;: {(a+b)}
  7 s = (+ a b) ;: {(a+b)}
  8 branch  while (> s 0): {(a+b),(s>0)}
  9 s = (- s 1) ;: {(a+b),(s-1)}
  10 a = (+ a b) ;: {(a+b),(s>0)}
  11 output (+ a b) ;: {(a+b)}
  12 output c ;: {}
  13 return 0 ;: {}
  14: {}
```

先约定一个全程适用的读法（18.5.2 节的结论）：**前向两段的
每行是"语句执行之后"的状态（OUT），后向两段的每行是"语句
执行之前"的状态（按程序顺序的 IN）**。每个程序一行，编号
即第 14 章 CFG 的程序点；entry 是 1、exit 是 14，return 占
13。行内集合按因子字典序排，重复读几行就能背下版式。

### 30.8.0 纸上算账：classic.tip 每个点的 gen/kill 明细

四段输出都可以从语句本身算出来——这正是"框架"给人的底气：
不看迭代过程，先把每个点的 gen 与 kill 逐条列成表，剩下的
合并与收敛只是查表劳动。下面三张表把 classic.tip 十四个程序点
的"局部事实"一次列全，随后四小节的每一行解读都能在这三张
表里找到出处。建议读者先自己拿草稿纸列一遍、再与下表对：
能独立列出三张表，等于掌握了四大分析一半的内容。

第一张表：活跃变量。gen 是语句计算的表达式里出现的变量
（`stmtExpr` 给出该表达式，`exprVars` 收集其中变量），kill 是
赋值目标；分支、输出、返回不赋值，kill 为空。注意第 2、3 行
的伪因子 input，它是"输入流"的记账，不是程序变量。

| 点 | 语句（前缀式） | gen：使用了谁 | kill：谁被赋值 |
|----|----------------|---------------|----------------|
| 2 | a = input | {input} | {a} |
| 3 | b = input | {input} | {b} |
| 4 | c = 0 | {}（常量不读变量） | {c} |
| 5 | if (a > 0) | {a} | {}（只判断） |
| 6 | s = a + b | {a, b} | {s} |
| 7 | s = a + b | {a, b} | {s} |
| 8 | while (s > 0) | {s} | {}（只判断） |
| 9 | s = s - 1 | {s} | {s} |
| 10 | a = a + b | {a, b} | {a} |
| 11 | output a + b | {a, b} | {}（只输出） |
| 12 | output c | {c} | {} |
| 13 | return 0 | {} | {} |

第二张表：到达定值。gen 只对赋值语句非空，内容是它自己的
定值编号；kill 是**同一变量在程序中所有其他定值**——包括
文本位置在它"后面"的定值（如第 2 行的 kill 里就有 d7），因为
框架按方程求解、不按文本先后求解，把将来的定值列进 kill 只是
"有备无患"，在集合运算中删不到眼前集合里的元素。

| 点 | gen：本点定值 | kill：同变量的其余定值 |
|----|---------------|--------------------------|
| 2 | d1(a) | d7(a) |
| 3 | d2(b) | （无其他 b 的定值） |
| 4 | d3(c) | （无） |
| 5 | —（不是定值） | — |
| 6 | d4(s) | d5(s), d6(s) |
| 7 | d5(s) | d4(s), d6(s) |
| 8 | — | — |
| 9 | d6(s) | d4(s), d5(s) |
| 10 | d7(a) | d1(a) |
| 11 | — | — |
| 12 | — | — |
| 13 | — | — |

第三张表：两个表达式分析共用的 gen/kill。gen 是语句计算的
全部二元子式（叶子不算："变量本身可用"没有复用价值），
kill 用子串匹配：子式文本里含赋值目标名即作废。对照程序，
表达式全集只有四个因子：(a>0)、(a+b)、(s>0)、(s-1)。

| 点 | gen：刚算过的子式 | kill：含目标名的子式 |
|----|--------------------|------------------------|
| 2 | {}（input 不是二元式） | (a>0), (a+b) |
| 3 | {} | (a+b) |
| 4 | {}（常量 0 无子式） | （无含 c 的子式） |
| 5 | (a>0) | {}（不赋值） |
| 6 | (a+b) | (s>0), (s-1) |
| 7 | (a+b) | (s>0), (s-1) |
| 8 | (s>0) | {} |
| 9 | (s-1) | (s>0), (s-1) |
| 10 | (a+b) | (a>0), (a+b) |
| 11 | (a+b) | {} |
| 12 | {}（c 是叶子） | {} |
| 13 | {} | {} |

三张表并排看，有一个细节值得先点破：第 9 行与第 10 行的
kill 里都包含"自己正在生成的同类因子"——9 杀 (s>0) 而 gen
(s-1)，10 杀 (a+b) 而 gen 又恰好是 (a+b)。这就是 18.6.5 节
强调"传递必须先 kill 后 gen"的原因：顺序反了，第 10 行刚
gen 出的 (a+b) 会被紧跟的 kill 误删。手工模拟到这两个点时
务必把顺序写对：先划掉 kill，再补上 gen。

还有一个贯穿三张表的读法：**gen 与 kill 只回答"这条语句局部
发生了什么"，方向（前驱还是后继）与量词（并还是交）完全不
进表**。同一张第 6 行的账，在活跃变量里要拿它跟 CFG 后继
合并，在到达定值里跟 CFG 前驱合并——局部事实不变，合并方向
由规格另给。把"局部账"与"合并规则"分开记，是记住四大分析
最省力的方式。

### 30.8.1 活跃变量段：逆着控制流读一遍程序

从底部往上读这段输出，就是沿控制流**逆行**——这正是后向分析
信息的实际流向。

- `13 return 0 : {}` 与 `14: {}`——边界。函数返回之后没有
  "之后"，任何变量都不再被使用。整个分析从这两行的 ∅ 出发
  向上生长。
- `12 output c : {c}`——输出 c 之前，c 必须有值。 merged 自
  下行的 ∅，gen 使用的 {c}，得到 {c}。到这里 c 的"活跃区间"
  找到了右端点。
- `11 output a+b : {a,b,c}`——多出 a、b：输出语句用了它们。
  注意集合里**没有 s**：循环出口之后 s 再无人读。
- `10 a = a+b : {a,b,c,s}`——信息流后继（8 行，循环头）报
  {a,b,c,s}（条件要用 s，出口要用 a,b,c），kill 掉 a（目标），gen 回
  {a,b}（右值）。等一下，结果里怎么还有 s？看清楚：{a,b,c,s}
  里的 s 来自 merged 而非 gen——执行这条赋值之前，s 的旧值
  仍然要喂给下一轮循环条件。a 同理：右值要读旧 a。所以这条
  语句执行前四个变量全活跃。
- `8 branch while (s>0) : {a,b,c,s}`——进入循环判断前，s 的
  两个前途（出口用 a,b,c；再进循环体用 s）合并，may 取并：
  {a,b,c} ∪ {a,b,c,s} = {a,b,c,s}。对比 `5 branch if : {a,b,c}`
  ——**同一个"分支点"，5 行里没有 s，8 行里有 s**。原因一眼
  可见：if 的两支都先给 s 赋新值才用（旧 s 必死），while 的
  条件自己就用 s（旧 s 必活）。"赋值目标在到达使用前一定
  被覆盖"在两个分支点的不同待遇，就是 kill 项在起作用。
- `6 s = a+b : {a,b,c}` 与 `7 : {a,b,c}`——**s 不在集合里**。
  这两条赋值执行前，s 的旧值无人需要（马上被覆盖），只用到
  a、b，加上更远处还欠着的 c。如果反过来问"这两条是不是
  死赋值"，答案是活跃的消费者在 8 行以后——s 在循环头被用，
  两条赋值都不死；但**旧值**死了。死赋值判定看的是"新值有
  没有人要"，那要看语句**流出**侧的状态，不在本表——本表
  只印流入侧。这也是理解后向分析打印语义的一个小练习：
  同一个判断，换个点看。
- `4 c = 0 : {a,b}`——c 被覆盖，旧值（本来就是常数 0）死；
  a、b 活；c 的**新**值要一路活到 12 行。执行前的集合里没有
  c，恰恰说明这条赋值的写入是必要的（下游 12 行在等它）。
- `3 b = input : {a,input}`、`2 a = input : {input}`——逐行
  剥离：执行 3 之前还要 a 和输入流；执行 2 之前只剩输入流。
- `1: {input}`——entry 的集合非空！因子 input 来自 2 行的
  gen 逆传上来。伪变量"输入流"在程序第一条语句之前就"活跃"
  ——严格说这是记号的边角：input 每次求值都读流，不存在
  "之前读过的 input"，把 entry 行读作"程序开工前需要输入流
  供给"即可，无碍任何判定。

整段读完，活跃变量分析的用途浮现出来：任何一个赋值 `x = e`
是否死赋值，等价于"x 是否在该语句流出侧活跃"；本段每行给出
流入侧，流出侧就是该点**信息流后继**（对后向分析即 CFG 前驱）
的行。这套表加上一次查表，就是死代码删除器的判定核心。

### 30.8.2 到达定值段：ud 链在循环头开会

这一段每行是"执行之后"哪些定值可能仍在生效。前四行单调
累积：`2 : {d1}`、`3 : {d1,d2}`、`4 : {d1,d2,d3}`——每个赋值
把自己的定值加进来，同时杀死同变量的旧定值（此处无旧定值）。
好戏在循环区：

- `6 : {...,d4(s@6)}` 与 `7 : {...,d5(s@7)}`——两条分支语句
  各自给 s 定值。流出 6 时，s 的供应商是 d4（d5 还没执行）；
  流出 7 时是 d5。
- `8 branch while : {d1..d7}`——**循环头同时到达三个 s 的
  定值：d4、d5、d6**。三个来源在 may 的并下共存：首次进循环，
  走的是 6 或 7（d4 或 d5）；再次进循环，走的是回边（d6，
  循环体里的 `s = s-1`）。`while (s>0)` 这个使用点的 ud 链
  因此有三个头——凡是要做"这个使用由哪个定值供应"的后续
  分析（常量传播、值编号），都必须处理这种多供应商。**may
  的体感在这里：不是"三选一"，而是"三个都可能在"——分析
  不告诉你哪条路径实际发生，它把所有可能如实并陈。**
- `9 s = s-1 : {d1,d2,d3,d6,d7}`——d4、d5 消失了：本语句
  重新定义 s（gen d6、kill 同变量的其余定值）。**回边后
  d6 杀死旧定值**——从这一行往后的任何使用，供应商里不再有
  分支语句 6、7。注意 d6 恰是本语句自己的定值：流出 9 时
  s 的供应商正是它自己。
- `10 a = a+b : {d2,d3,d6,d7}`——d1 消失：a 被重定义（d7）。
  循环第二圈起，a 的供应商是循环体而不是入口。
- `11 output a+b : {d1..d7}`——**d4、d5 回来了**。为什么？
  流出 8（循环不进、直接出循环的那条路径）带着 d4/d5 到 11；
  流出 10 只带 d6/d7。两股并流，七个定值齐了。这个"复活"
  是 may 分析最容易被误解的地方：kill 只在**语句执行**时
  发生，零迭代路径绕过了 9 和 10，旧定值毫发无损。若把
  `output a+b` 的使用点接到 ud 链上，a 的链头有两个——d1
  （入口读入的 a）或 d7（循环体最后写入的 a）——具体是哪个，
  取决于循环转了几圈，而分析不猜。
- `12/13/14`——三行全同：出口处七定值俱在。d4/d5 的"活着"
  与 d6/d7 的"活着"含义不同：前者只在零迭代路径上活，后者
  在任意多圈后活。表格不区分这种概率差别——那是数据流分析
  有意的抽象，量词只有"存在"。

### 30.8.3 可用表达式段：交集的边界在回边上

前向 must。逐行读，重点三处。

- `5 : {(a>0)}`——分支条件刚判完，`(a>0)` 算过且 a 未变，
  可用。前四行 `{}`：entry 边界是 ∅，而 2、3、4 三条赋值
  只做了 kill（把全集削减下来）与空 gen（input、常数无子式），
  entry 的 ∅ 传到哪都是 ∅。**must 的初值全集在这里一个也
  看不见——可见的全集只在迭代内部（18.6.3 节），收敛后
  边界 ∅ 沿前向把"乐观假设"逐段削减成事实。**
- `6/7 : {(a+b),(a>0)}`——每条分支算出 `(a+b)`，gen 进集合；
  `(a>0)` 从上游传来、未被杀（这两条赋值只动 s）。两行相同。
- `8 : {(a+b),(s>0)}`——循环头，三股来流求交：流出 6 =
  {(a+b),(a>0)}，流出 7 = 同，流出 10 = {(a+b),(s-1)}。三者
  交集 = **{(a+b)}**——`(a>0)` 出局，因为回边（经 10）上 a
  刚被改写，`(a>0)` 的旧值不再可信；然后 gen `(s>0)`（条件
  本身刚求值）。两支都算 `(a+b)`，于是它在合流点**一定**
  可用——must 取交的意义所在：单支算过的不算数，两支都算
  才留下。对比 18.8.2 的 d4/d5 在同一个循环头"三定值并存"：
  **同一个点，may 报"可能供应商有三个"，must 报"确定可复用的
  只有一个"——量词之别在同一个程序点上直接可见。**
- `9 : {(a+b),(s-1)}`、`10 : {(a+b),(s-1)}`——9 重定义 s：
  含 s 的子式 `(s>0)` 被杀，gen 补 `(s-1)`。10 重定义 a：
  含 a 的 `(a>0)` 被杀、`(a+b)` 也被杀——但 gen 恰好是
  `(a+b)`，先删后补（18.6.5 节的现场），流出集合里它还在，
  且**身份已换**：此后的 `(a+b)` 可复用的是 10 的右值刚算出
  的那份，不是分支语句的旧账。若循环体写的是 `a = s - 1`
  （gen 不含 `(a+b)`），`(a+b)` 就会从流出 10 里消失，进而
  在循环头的交集里消失——可用性沿回边被切断。读者不妨
  自行推演这个变体，检验对"交集如何沿回边传播"的直觉。
- `11 : {(a+b),(s>0)}`——流入侧就是流出 8 的 {(a+b),(s>0)}：
  `(a+b)` 在 output 之前**可用**——沿出口路径，最后一次计算
  在分支语句（6 或 7）的右值，沿循环多圈的路径，最后一次
  计算是 10 的右值（`a = a+b` 杀掉旧 `(a+b)` 的同时用右值
  补了新的），两条路走到 11 时 a、b 都未再变。output 语句
  自己也计算 `(a+b)`（18.6.1 节：output 也算"求值语句"），
  gen 与流入重合，流出集合不变。CSE 在 11 处需要 `(a+b)`
  可以直接取用。
- `12/13/14`——不变，透传到出口。

### 30.8.4 非常忙表达式段：预测未来的悲观清单

后向 must。每行是"执行之前"，从未来逆传回来的"躲不掉的计算"
清单。这段的读法与前段处处对照。

- `13/14 : {}`——exit 边界。返回之后没有计算任务。
- `12 output c : {}`、`11 output a+b : {(a+b)}`——11 行：output
  a+b 自己就要算 `(a+b)`，所以执行前它"非常忙"；合并自下行
  的 ∅ 再补 gen，只剩它。12 行 gen 为空（`c` 是变量不是子式），
  传下行的 ∅。
- `10 a = a+b : {(a+b),(s>0)}`——执行这条赋值**之前**，无论
  循环还转不转，`(a+b)`（11 的 output，或下一轮的 10 本身）
  与 `(s>0)`（8 的判断）都逃不掉。注意 `(a+b)` 的成分里有 a，
  而本语句正在改写 a——kill 先把 `(a+b)` 删了，gen 又补回来
  （右值恰是它）：补回来的含义是"本语句自己就算了它"，所以
  执行**前**它当然非常忙。同一条语句在可用表达式段（18.8.3）
  与本段呈现同形的"kill 后 gen"，两次的语义解读却完全不同
  ——前向那次是"旧账换新账"，后向这次是"未来必算、且算的
  就是本语句"。
- `9 s = s-1 : {(a+b),(s-1)}`——后继 10 一行报 {(a+b),(s>0)}；
  本语句改 s，`(s>0)` 被杀（s 要变，将来那个 `(s>0)` 用的是
  新 s，不是从这往上"预订"的旧计算），gen 补 `(s-1)`。
- `8 branch while : {(a+b),(s>0)}`——两股未来求交：走循环体
  （下行 9 报 {(a+b),(s-1)}）与走出循环（11 报 {(a+b)}），
  交集 {(a+b)}；gen 条件本身的 `(s>0)`。**从循环头出发，
  每条路径都要算 `(a+b)`**——转圈算（10 的右值），不转也
  算（11 的 output）。这是"部分冗余消除"最垂涎的形状：
  循环体内外各算一次的同一表达式。
- `6/7 : {(a+b)}`——有意思：`(s>0)` **不在**。后继 8 一行报
  {(a+b),(s>0)}；但本语句改 s，含 s 的 `(s>0)` 被杀——循环
  判断用的 s 将是**新** s，执行赋值之前的时刻谈"未来要算
  (s>0)"必须以其操作数不再变为前提，而 s 马上就变。gen 补
  回 `(a+b)`（右值）。`(a+b)` 活着：a、b 都不动，将来 10 或
  11 的求值用的正是此刻的 a、b。
- `5 branch if : {(a+b),(a>0)}`——**全段的高光行**。下行
  6、7 都报 {(a+b)}，交集 {(a+b)}；gen 条件 `(a>0)`。两条
  分支**都**要算 `(a+b)`（文本相同的两条语句不是巧合，
  18.1.2 节的设计在这里兑现），所以进入分支前它非常忙——
  把这次计算提到 if 之前做一次，两支里的重复全部消失，
  程序变快。这是**代码提升**（code hoisting / 循环不变量
  外提的前奏）的教科书现场：非常忙分析的输出就是提升的
  许可证。
- `4 c = 0 : {(a+b),(a>0)}`——透传（kill 不含 c 的命中，
  gen 为空）。提升点还可以再往上找：4 与 5 之间没有别的
  计算，提升到 4 之前同样合法。
- `3 b = input : {(a>0)}`——**(a+b) 被杀了**：本语句改 b，
  b 的值将由输入流决定；分支里将要算的 `(a+b)` 用的是**新**
  b，不能把"旧 b 参与的计算"外提到 3 之前。执行前仍然
  非常忙的只剩 `(a>0)`——判分支总要用 a。
- `2 a = input : {}`——连 `(a>0)` 也没了：本语句改 a。**对比
  3 行与 2 行是本段最锋利的一课**：两条 input 赋值形式相同，
  杀伤力却不同——`b = input` 杀 `(a+b)`（目标 b 在其中）
  保 `(a>0)`（目标不在），`a = input` 把两个全杀（a 同时是
  两个子式的操作数）。"赋值目标自身出现在子式中"是 kill
  的判据，目标落在哪些子式里，决定哪张"未来账本"作废。
  外提若无视这一点，把 `(a+b)` 提到 `b = input` 之前，算的
  就是过期的 b。
- `1: {}`——entry 透传。

### 30.8.5 并排对读：may 与 must 的体感

四段读完，把最给味道的几组并排放一次。

**同一循环头（8 行），四段四个样**。活跃变量 {a,b,c,s}：
未来四个变量都可能被读。到达定值七个 d 并存：过去的供应商
有三个可能。可用表达式 {(a+b),(s>0)}：过去所有路径都算过的
只有这两个。非常忙 {(a+b),(s>0)}：未来所有路径都要算的只有
这两个。一个程序点，四张问卷：可能有什么（后向 may）、可能
从哪来（前向 may）、一定有什么（前向 must）、一定要做什么
（后向 must）——四份答案互不重合，又互不矛盾。

**"两支都算"在两个量词下的两副面孔**。if 的两支都算 `(a+b)`：
must（可用）说合流点它**一定**可用（两支都留下）；must（非常忙）
说分支前它**一定**要算（两支都预订）。若只有一支算呢？可用
表达式在合流点会把它交掉（另一支没算），非常忙也在分支前把它
交掉（有一支不用算）——must 的两个方向同涨同落，因为"全部
路径"这个量词不关心时间方向。反观 may：活跃变量在 8 行保留 s
而 5 行不保留，取决于"未来是否有一条用到 s 的路径"——存在性
判断跟着路径走，与全称判断的机制分道扬镳。

**kill 的三种口径**。活跃变量 kill 的是**变量**（旧值作废）；
到达定值 kill 的是**同变量的其他定值**（供应商易主）；表达式
分析 kill 的是**含目标的所有子式**（涉及该值的计算全部作废）。
三条口径共享同一个来源——`assignTargetName`——却在各自的
因子空间里长成不同的集合。这也是框架的深意：gen/kill 函数
只负责"把语句翻译进因子空间"，方向与量词的机制一律上交。

**"复活"只属于 may**。d4/d5 在 11 行复活（零迭代路径绕过
kill）；可用表达式没有对应的复活——`(a>0)` 一旦在回边上被杀，
循环头交集就永远失去它。前者是存在量词的本性（有一条路就
算数），后者是全称量词的本性（少一条路都不行）。读者若能
不看上文、独立解释这两处不对称，30.2 节的对偶论证就算
真正读进去了。

## 30.9 消费端：四张表各自喂养哪个变换

四张"程序点 → 因子集合"的表本身不是目的。分析的价值要等
**优化变换**来消费才兑现：没有消费者，再精确的表也只是一段
漂亮的输出。这一节逐一看四张表的消费端——每个消费者如何
读表、读完做什么改写、改写凭什么安全——最后用一张契约表
说明：分析的方向与量词，其实是被消费者的安全需求反推出来的。

### 30.9.1 活跃变量：死赋值删除与寄存器分配

最直接的消费者是**死赋值删除**（dead store elimination）。
判定一条赋值 `x = e`（节点 p）是否可删，需要的是"流出侧"
信息：x 在 p 的 CFG 后继们看来还活不活跃。本章打印的每行是
后向分析施加 gen/kill 之后的状态，即执行 p **之前**的活跃集；
流出侧等于 p 的所有 CFG 后继"执行之前"集合的并——从打印
表上直接把后继那几行并起来即可。x 不在其中，这条赋值整条
可删，因为沿任何路径它写进去的值都等不到读者。may 的安全
上界在这里兑现成删除的合法性：分析可能多报活跃（让某些本
可删的赋值留下），却绝不会漏报而删掉一条还有消费者的赋值。

更大、也更出名的消费者是**寄存器分配**（register allocation）。
机器的寄存器数量有限，编译器要决定每个变量在每段区间里放
寄存器还是溢到栈上。做法是：先用活跃信息求出每个变量的
**活跃区间**——从它被定值的点、到它最后一次被使用的点；
两个变量若在某个点同时活跃，它们的区间相交、不能占同一个
寄存器，于是在**冲突图**（interference graph）上连一条边；
给这张图着色，颜色数等于寄存器数，着不上色的节点标记为
溢出、在分配前先把它的定义与使用改写为栈上读写。整个分配
器的输入就是逐点活跃集合——活跃变量分析是原生编译器后端
里分量最重的数据流消费者。一个值得知道的细节：区间在分支
汇合处的合并必须按 may 取并，因为"两个分支里各有一个变量
活跃"意味着汇合点之后它们都可能要读，分配器必须同时为两
者留出位置。

### 30.9.2 到达定值：ud/du 链与一串分析的索引

到达定值表的第一用途是编**使用-定值链**与**定值-使用链**。
对每个变量使用点，沿表查出"哪些定值可能流到这里"——这就
是 ud 链；反向查表即 du 链：一个定值能影响哪些使用。这两
条链是后续众多分析与变换的索引：

- 常量传播可以借助 ud 链判定：若一个使用点的所有到达定值
  都给同一变量赋同一个常量，该使用就可直接替换为该常量
  （第 29 章的做法在格上直接完成了同样的事，不依赖链）。
- **程序切片**（slicing）：从一个关心的输出点出发，沿 du 链
  反向收集"这个值依赖哪些语句"，得到决定该输出的最小语句
  子集——调试、理解遗留代码的常用工具。
- 一个使用点若**查不到任何到达定值**，说明变量在此处之前
  没有任何赋值能流到它——这正是"可能未初始化"的信号，
  第 32 章会换一种更直接的方式回答同一问题。
- 循环优化靠到达信息识别**循环携带依赖**：某次迭代读取的定
  值是否来自上一次迭代的写入，决定了循环能否交换、并行。

### 30.9.3 可用表达式：全局公共子表达式消除

可用表达式喂养的是**全局公共子表达式消除**（global CSE）。
变换的形状：若在程序点 p 又要计算表达式 e，而 e 在 p 可用
（所有到达 p 的路径都算过它、且操作数未变），那么不必重
算——让 e 第一次被计算时把结果存进一个新临时变量 t，p 处
直接引用 t。变换因此包含两个动作：在"支配性"的首次计算点
插入 `t = e`，并把后续可复用点的 e 替换为 t。"所有路径都算
过"这个 must 条件是复用安全的全部根据：少一条路径，t 在那
条路径上就没有被赋过值，复用会读到垃圾。

一个语义陷阱必须点名：**可能触发运行时错误的表达式，"算过"
不等于"白捡"**。除法就是 TIP 里的例子：把 `/ x y` 从某条路
径上复用过来，意味着原本在那条路径上也许不会执行的除法
（比如它在一个未被选中的分支里）现在被提前强制执行——若
y 在那条路径上恰为 0，复用凭空制造了一次崩溃。工业编译器
因此把"可能陷入（trap）的表达式"排除在普通 CSE 之外，或
者额外要求该表达式在所有路径上**本来也会被求值**——这恰
好是非常忙分析才能签发的许可证。另外，含 input 的式子不能
复用：input 每次求值都读新值，所以本章的因子表只收二元
子式、且 gen 构造天然不含它。CSE 还分局部（基本块内）与全
局（跨块）两级；可用表达式表服务的是全局那一级。

### 30.9.4 非常忙表达式：代码提升与循环不变量外提

非常忙表喂养**代码提升**（code hoisting）：若表达式 e 在点 p
非常忙——所有从 p 出发的路径都要在操作数改变前算它——
那么在 p 处插入 `t = e`，把下游各路径上对 e 的计算统一替换
为 t。一次计算替代多路径上的重复，程序体积变小（嵌入式场
景里这是常用的尺寸优化），运行时计算量不增反可能减少：
原来某些路径算 e、现在每条约一次。

与提升同源的另一个消费端是**循环不变量外提**（loop-invariant
code motion）：循环体内的表达式，若其操作数在整个循环中
不被修改（递归地：操作数的定值也在循环外），它每次迭代
结果相同，可提到循环的前置头（preheader）算一次。判定"操
作数不被修改"结合了到达定值与表达式分析，而外提的安全条
件正是"该表达式在循环头非常忙"——只要进入循环、无论转
多少圈它都要算，外提不增加任何执行次数；再辅以"陷入表达
式"检查（外提不能让零迭代路径凭空执行一次可能除零的计
算，所以严格的做法要求循环已知至少执行一次，或把提到循环
外的计算包在保护条件里）。

把可用表达式与非常忙表达式合起来，还能做更高级的**部分
冗余消除**（PRE）：一个表达式若只在部分路径上重复计算，
PRE 通过插入少量计算把"部分冗余"改造成"完全可复用"，再
按可用信息消除。这是优化器里最精巧的变换之一，而它的全
部输入事实就是 30.8 节那两张 must 表（外加为插入计算而劈
开关键边的 CFG 改造）。

### 30.9.5 消费端的契约：需求反推参数

把四个消费者并排，30.2 节分类表的每一列都能在这里找到
理由：

| 消费者 | 对程序做的动作 | 依赖的事实 | 量词与方向 | 判错的代价 |
|--------|----------------|------------|------------|------------|
| 死赋值删除 | 删语句 | 未来无人使用 | 后向 may | 漏报 → 删掉活赋值 |
| 寄存器分配 | 指派/溢出 | 区间同时活跃 | 后向 may | 漏报 → 两个活变量撞寄存器 |
| ud/du 链与切片 | 建索引 | 过去可能的供应商 | 前向 may | 漏报 → 依赖关系缺失 |
| 全局 CSE | 插入临时、替换 | 过去所有路径算过 | 前向 must | 虚报 → 复用未定义值 |
| 提升/外提 | 上移计算 | 未来所有路径要算 | 后向 must | 虚报 → 新增计算或陷入 |

读这张表的正确姿势是从右往左：**先问消费者承受不起哪种
错误，再决定量词；先问消费者关心过去还是未来，再决定方
向**。改写型消费者（CSE、提升）直接依据"事实成立"改程序，
一次虚报就是一次错误执行，必须用 must 下界把自己保护起
来；删除型与索引型消费者依据"事实不成立"行动（不活跃、
无供应商），一次漏报就是一次错误删除或依赖缺失，必须用
may 上界。这就是 18.2.5 节说的"分析填满象限是需求的投影"
在消费侧的兑现：参数不是分析设计师的口味，是消费者的安
全契约。

### 30.9.6 常见问题十二则

**问一："非常忙"这个名字从哪来？为什么不叫"必然表达式"？**
这是历史沿用的英文术语 very busy expressions，也有教材称
anticipatable expressions（"可预见的表达式"），后者其实更贴
近语义：站在程序点上就能预见它在下游必算。读其他教材遇
到 anticipatable，应知道与本章的 very busy 是同一个分析。

**问二：must 分析从空集出发真的会错吗，少做优化不行吗？**
不是少做优化，而是会得到一个**语义上错误**的结果：循环头
"两个空集互相支撑"使确实成立的事实永远进不来（18.3.1
节）。那不是悲观近似，是错误否定；must 必须从全集出发下降
到最大不动点。

**问三：可用表达式在 entry 处为什么是空？外部库难道没"算
过"什么吗？**
entry 处本函数一条语句都没执行；外部世界算过什么，本函数
既不知道也没有句柄引用。把入口清空是唯一自洽的地锚；若
想利用上游信息，需要过程间分析（函数入口处的摘要），那已
超出过程内框架。

**问四：活跃分析把 input 当变量，那 output 为什么不造一个
伪因子？**
input 的特殊在于语句要**读**它——`a=input` 因此不是死赋
值，需要记账；output 是只写的汇，没有"未来还要 output"之
类需要追踪的事实：语句是否执行由 CFG 决定，不需要数据流
分析回答。

**问五：到达定值为什么不管"定值之后有没有被使用"？**
那是活跃变量的职责。到达定值只回答"哪些赋值可能流到这
里"，至于是不是死赋值，要由活跃信息在另一个方向上判。
各司其职正是框架化的分工：一个分析不重复回答另一分析的
问题。

**问六：四个分析能不能合成一遍跑完？**
方向相反（两个前向、两个后向），单遍沿一个方向走无法同时
传播；格与量词也不同。能共享的是 CFG 与因子编号——实践
中可以在同一趟 CFG 遍历里预计算四套 gen/kill，但不动点求
解仍是四次。在 SSA 形式上，部分分析可以稀疏化到几乎单遍，
代价是先把程序转成 SSA。

**问七：实际编译器里 may 和 must 用得一样多吗？**
may 的两个（尤其活跃变量）在每次后端编译中都必跑；must 的
两个主要服务中端优化，优化级别低时可能关闭。调试版本（
-O0）通常只做最少的活跃分析，不做 CSE 与外提——这正是
"让调试体验符合源码顺序"的工程选择。

**问八：为什么循环头在四张表里都显得特殊？**
因为循环头同时是回边与入边的汇合点：状态总在那里与"上
一轮"合并。may 在那里见到的因子最多（旧定值沿回边与新定
值并存），must 在那里被回边削减得最狠（操作数可能在循环
里被改）。它是每张表信息密度最高的点，也是手工验算最容
易错的点。

**问九：kill 里包含文本位置靠后的定值，这种"未卜先知"合
理吗？**
框架求的是方程组的解，不模拟执行先后；kill 只是方程里的集
合参数，列多了（列入眼前集合中不存在的元素）在做集合差时
天然无效。这是用"静态枚举"换"方程简单"的写法，不是真的
预知未来。

**问十：if 和 while 节点自己的 kill 为什么是空？条件里难道
不写变量吗？**
条件只**读**不写，没有变量被赋值、旧值不作废；条件的作用
体现在 gen 里（用了操作数）与分叉上（CFG 在此一分为二）。
只有赋值语句有 kill——这是 gen/kill 模型的基本约定。

**问十一：不可达点的状态会不会污染 must 的交集？**
不可达点没有真实来流，每轮合并都得到 ∅；若它有边汇入一个
可达汇合点，那它的 ∅ 进入交集会把因子全部交掉——结果保
守（少复用），但安全。真正危险的反向情形（可达点的全集流
入下游、虚报可用性）不会发生：可达点从全集下降后，保留的
都是有真实路径支撑的因子。

**问十二：这四个分析和第 25–28 章的符号分析是什么关系？**
同一套单调框架/同一个 worklist 引擎下的不同实例。符号格不
是幂集格（元素是 {-,0,+,...} 的复合标记），所以它填不进
本章的 DfaSpec；但"方向、边界、初值、传递"的结构完全相同，
第 32 章的五元组总表会把它们并排收编。

**问十三：CSE 与提升都会动表达式，同一遍优化里会不会互相
打架？**
会，所以编译器规定流水线次序并在每轮改写后重新分析：典型
次序是先提升/外提（把计算搬到能复用的位置）、再做 CSE（消
除重复）。顺序反了，CSE 可能先把"提升后本应只算一次"的式
子当作两个独立点处理。无论怎么排序，"改一遍、重分析一遍"
的纪律不变（参见 18.9.7）。

**问十四：一元负号为什么不算表达式因子？**
本章 gen 只收二元子式，因为一元取负在多数机器上是一条极廉
的求补指令，复用收益微乎其微；而且 TIP 源码里的负号在构建
AST 时已统一改写成 `0 - E`（二元减法），它照样以二元子式
的身份进表，信息没有丢，只是因子的形态统一成了二元。

**问十五：像本例 c 那样活跃区间横跨整个循环的变量，会逼得
寄存器分配整个循环都为它占住寄存器吗？**
正是如此——区间不结束，分配器就必须保证它在循环里始终可
读；这是占寄存器的"长线变量"。若同时存在很多个这样的变量
、寄存器不够，分配器会选择代价最小的一个溢出（在循环里溢
出代价最高，所以图着色分配器给循环内的冲突边加权重，尽量
保住循环里活跃的变量）。

**问十六：`a = input` 也算 a 的一次"定值"吗？**
算。它在到达定值表里照常编号（本章 d1、d2 都是 input 赋
值）：定值只要求"这条语句给变量赋了值"，值从键盘来还是算
出来不影响身份。它的特殊之处仅在不能折叠、不能预测，体现
在常量格给 ⊤、表达式分析无 gen。

**问十七：如果程序没有任何分支和循环，四个分析的结果有什
么简化关系？**
整份程序退化为一条直线：may 与 must 不再有差别（每点只有
一股来流，并与交相等）、活跃集是"剩余语句使用变量"的简单
并。手工验算时仍建议按完整流程走一遍——直线程序是检验你
是否真正理解框架的最好样本：答案简单，但每一步的理由要能
说全。

### 30.9.7 从表到改写：两个完整走查

理论说清了，这里把"读表 → 改写"的动作各完整走一遍，让
消费者的工作方式有具体形状。

**走查一：删一条死赋值。** 假设在 classic.tip 的 `c = 0`
之前再加一行 `t = 9`（t 加进 var 声明），而程序其余地方从
不出现 t。步骤：第一，找到新赋值所在点 p（按第 14 章编号
约定，它会插在第 4 点之前、后续点号顺延）；第二，列出 p
在 CFG 上的全部后继——顺序边通向 `c = 0`，没有别的分叉；
第三，查活跃表中这些后继的"执行之前"集合：它们由后继一路
合并到出口，沿途 gen 里没有 t（程序不使用 t），故 t 不在其
中；第四，判定成立：p 写进 t 的值等不到任何读者，整条删
除。安全性论证就在 may 的上界里：分析若**多报** t 活跃
（比如错误地把某处含字母 t 的因子算进来），最坏结果只是
这条赋值没被删；而漏报才会删掉活赋值——may 上界在结构上
排除了漏报。删掉后还要重跑 CFG 与后续分析：点号变化、边
关系变化，任何后续变换都必须以改写后的程序为准，不能在旧
表上连续做决定。

**走查二：把 (a+b) 提升出 if。** 18.8.4 段的第 5 行显示
(a+b) 在分支点非常忙——两条分支都要在 a、b 未变时算它。
变换步骤：第一，在分支点（if 判断之前）插入新临时 t 的定
义 `t = a + b`；第二，把两支中"操作数未变前"对 (a+b) 的计
算替换为 t：第 6 行、第 7 行改成 `s = t`；第三，重新声明 t
（加进 var）并重跑全部分析。关键判断在"哪些下游计算能换、
哪些不能"：循环里的第 10 行、循环外的第 11 行虽然也计算
(a+b)，但第 10 行自己改写 a——它算的是**新 a** 与 b 的和，
与分支点 t 的值不是同一个值，绝不能替换；这正是 kill 信息
的用途：(a+b) 在第 10 行被 kill 后以新身份重新 gen，链条
在此明确断开。能换的只有第 6、7 行：它们与分支点之间没有
任何对 a、b 的赋值。提升的合法性由两件事共同保证：非常忙
保证这次计算在所有路径上本来就会发生（插入 t 不增加计算、
也不把任何路径上不会发生的除法之类强行提前——本例无陷入
风险）；替换保持每点读到的值与原计算逐路径相等。改写后两
支里的重复加法消失，这就是优化器里真实发生的"提升"。

两个走查合起来显出同一个工作纪律：**分析给事实，变换查事实
并改写，改写后重建一切中间结果**。任何"在旧表上连做多个
变换"的偷懒都可能在点号与依赖变化后出错——优化器因此通
常是"分析一遍、改一批、再分析一遍"的节奏，而不是一次分析
包打天下。

## 30.10 工程注意点

**因子表示：字符串集合是教学的尺子，不是工业的尺子。**
`FactSet = std::set<std::string>` 让四个分析共享容器与代码，
但字符串比较、逐次分配的代价在真实程序的因子规模（几万个
定值、几十万个子式）下不可接受。工业实现的常规做法是先给
因子编号（本章的 `defName` 预处理其实已经做了一半——把定值
编号成 d1..d7，只是又存回了字符串），再用位向量表示集合：
并、交、差各是一条按字与的指令序列。换成位向量后，30.6 节
的驱动器骨架一字不改——这正是把因子空间压进 `FactSet` 别名
的回报。

**子串匹配的 kill 知道自己的斤两。** `killByTarget` 用
`term.find(t)` 判"含被赋值变量"，变量名有前缀关系时（`a` 与
`ab`）会多杀。多杀对两个 must 分析都安全（少报可复用、少报
可外提），但对精度的影响随名字冲突率上升。改进方向有两条：
要么对每个子式预先收集变量集、kill 时做精确的成员判定；要么
把因子从文本改成结构键（运算符 + 左右子因子），让"含变量 v"
成为可索引的属性。文本因子的根本短处在于把"语法巧合"当
"语义关联"——文本相同才是同一表达式，文本不同但结构相同的
（如经不同括号化的）也算不同；对 classic.tip 无碍，对去规范化
后的真实代码会漏报复用机会。

**gen/kill 每轮重算是在拿时间换篇幅。** 传递循环里每次都调
`spec.gen(node.stmt)`、`spec.kill(node.stmt)`，而 reaching 的
kill 每次都遍历整张 `defName` 表、表达式分析的 kill 每次都扫
`allTerms`——单个语句的 gen/kill 本不随迭代变化，理应预计算
成每节点的缓存（spa 把它叫"传递函数的预计算"）。教学实现
保持 lambda 直查，为的是 gen/kill 的定义与代码逐行对应；
本书规模（十来个点、七个定值）下迭代总次数不过几十次，换
清晰的代价为零。规模一上来，第一件事就是把这两个函数对象
换成 `map<const Stmt*, pair<FactSet, FactSet>>` 的一次性预表。

**多函数程序：函数间零信息流是有意的。** `runDfa` 对每个
`FunCfg` 独立建表、独立迭代，U′ 按函数各造各的。TIP 的函数
调用在本章的因子空间里没有任何表示（调用实参不产生定值、
被调函数不杀不 gen 调用者的任何因子）——四分析都是**过程内**
的。跨函数的到达定值与可用表达式需要过程间框架（调用边上的
传递函数、全局因子空间），这是后面篇章的事；在此之前，凡
跨函数的结论一律不可从本章输出里读出。

**不可达点与"无前驱取 ∅"。** 无信息流前驱的点每轮合并都得到
∅，对 may 恰是幺元语义，对 must 则是"借了边界值的语义"——
真正的 must 幺元是全集。当前代码里"无前驱"只发生于边界点与
不可达点，两者取 ∅ 都说得通（不可达点本来就没有真实执行
经过它）；若将来需要"不可达点显示全集以暴露可疑代码"之类的
诊断行为，就得显式区分边界与不可达，不能再靠缺省值兜底。

**打印协议是契约，不是装饰。** `printDfa` 的每个排版细节——
`== name ==` 段头、`branch` 前缀、因子的字典序、空集的 `{}`——
都进入 expected/output.txt 被逐字节对账。改任何一个都要同步
改期望文件，并且要在改动说明里写清"协议变化"与"结果变化"
的区别。教学工具链的可靠性很大程度上建立在这种笨拙的
逐字节比对待遇上。

**后向表的流入侧读法要写进使用说明。** 18.8.1 节提过：死赋值
判定需要的是流出侧状态，而后向两段的每行印的是流入侧。拿本
章输出直接做死代码删除的人必须知道"流出侧 = 信息流后继那几行
的合并"，否则会把 `6 s = a+b`（流入无 s）误读成"s 的新值无人
要"。一个直接的教训：**打印语义与判定语义错位时，错位本身
要文档化。**

## 30.11 练习

1. 把循环体的 `a = a + b` 换成 `a = s - 1`，手推可用表达式段
   的 8、9、10 三行，验证 `(a+b)` 从循环头消失。再对变体跑
   `--check`，核对 18.8.3 节的反事实推演。
2. 在 `output a + b;` 之前插入 `output s;`，指出四段输出各
   有哪几行变化，并用 may/must 的语言解释每处变化。
3. 交换 if 两支的内容（6、7 两条语句互换位置），到达定值段
   与非常忙段哪些行的因子集合不变、哪些改变？因子集合不变
   说明这两个分析对分支内的**位置**敏感还是不敏感？
4. 到达定值是 may 分析，entry 边界却是 ∅ 而不是全集。这与
   "must 的边界才是 ∅"的论述矛盾吗？用 18.3.2 节的"地锚"
   论证给出不矛盾的完整说明。
5. 18.3.3 节的"三步论证"里，第一步说"传递函数只会放 gen 里
   的因子"。找出 30.6 节代码中保证这一点的具体行，并说明
   为什么 main.cpp 的四个 gen lambda 都满足这个前提。
6. 考虑程序：`main() { var x; while (input > 0) { x = 1; } output x;
   return 0; }`。写出活跃变量在循环头与 output 点的结果，并
   解释：x 在"从未进入循环"的路径上没被赋值，为什么分析仍
   说它在 output 前活跃？这与第 32 章有什么联系？
7. 证明题：(a) 证明 gen/kill 传递函数 F(S) = gen ∪ (S ∖ kill)
   关于集合包含单调；(b) 证明 may 的并、must 的交作为"多来
   流合并"也单调；(c) 由 (a)(b) 与幂集格高度有限，证明 runDfa
   必然终止，并指出终止性为什么不依赖队列顺序。
8. 设计题：把可用表达式的 gen 构造改为"只收赋值右值、不收
   if/while 条件"。列出 18.8.3 段中因此变化的所有行，先用
   18.8.0 的明细表手推、再改代码跑 `--check` 核对。讨论：这
   个改动损害 soundness 吗？损害什么？
9. 手工题：对节点 9（s = s - 1），列出它在活跃变量分析中的
   全部信息流前驱（注意方向已翻转），逐步验算打印结果
   {a,b,c,s}；再指出若漏了回边 9→8 中的哪一股信息，会得到
   什么错误集合。
10. 规模题：假设程序有 N 个节点、G 个因子。比较字符串集合
    与位向量两种表示在"合并 + 传递"上的渐近代价。再解释
    "稀疏分析"（如 SSA 上的常量传播）为什么能避免在每个点
    维护整张因子表：它把事实直接挂在什么上面？

**解题思路。**

第 6 题：活跃分析按 may 合并——存在一条路径（进过循环）在
output 前给 x 赋过值且此后要读 x，output 就是 x 的使用点，
所以 x 在 output 前活跃。分析不回答"x 是否在**所有**路径上
都有值"——那是 uninitialized 分析的问题（第 32 章）：本例
沿零迭代路径 x 确实未初始化，活跃但可能未初始化，两个结论
同时成立、互不矛盾。要点：活跃 ≠ 已初始化。

第 7 题：(a) S⊑T 时 S∖kill ⊑ T∖kill，并上同一 gen 后包含
关系保持；(b) 多一个被并的集合只会让并变大；交的情形：各
输入变大时，公共部分也不会变小（形式化：∩、∪ 对两边都单
调）；(c) 每次点状态变化都沿格的严格序移动，幂集格高度
|U|+1 有限，故每点变化次数有界、总次数有界；队列顺序只改
变"先发现哪条路径"，不改变单调收敛的终点（第 28 章已证
唯一性，因为求的是同一方程组的最小/最大不动点）。

第 8 题：变化点在 5（gen 不再有 (a>0)）、8（gen 不再有
(s>0)）及所有以它们为来流的后继交集。手推时按 18.8.0 第三
张表删去相应 gen，再沿前向重算交集。结论：不损害 soundness
——少报可用性只会让 CSE 少做；被复用的表达式仍有"所有路
径算过"的支撑。损害的是精度（条件判完后条件表达式本可复
用，比如紧随其后的分支里又出现同一判断）。

第 9 题：后向分析中节点 9 的信息流前驱是它的 CFG 后继：8
（回边）与 10（顺序边）。后继 8 的流入集是 {a,b,c,s}（条件
用 s、出口路径欠 a,b,c），后继 10 的流入集是 {a,b,c,s}；may
合并仍为 {a,b,c,s}；kill {s} 再 gen {s}，结果 {a,b,c,s}。漏掉
后继 8 那一股会丢 s（错误地以为 s 在赋值前不活跃），漏掉
10 那股会丢 a,b,c——两个错误都可能让删除器误判，故两股缺一
不可。

第 10 题：字符串集合每次合并/传递为 O(G log G) 量级（比较、
插入），位向量为 O(G/w)（w 为机器字长），且常数极小；每点
每轮代价分别 O(G log G) 与 O(G/w)。稀疏分析的关键：在 SSA
里每个变量只有一个定义点，关于变量的事实可直接挂在该定义
（及其使用）上、沿 def-use 边传播，不必在与该变量无关的程
序点上空维护"它还是不是某个值"——稠密分析在每个点复制全
局环境，稀疏分析只让事实出现在它能起作用的边上。

## 30.12 小结

本章把四个经典数据流分析装进了同一个幂集格框架。回望全章，
做了三件事。

**第一，证明了"四个分析"其实是"一个框架的四次参数化"。**
因子空间（变量、定值、子式）不同，但结构同为幂集格；方向
（前/后）、量词（may 并/must 交）、gen/kill、初值与边界五个
参数的不同取值组合出四种分析，而 2×2 的参数象限恰好被编译
优化的四个基础需求（删、连、复用、提）各占其一——这不是
巧合，是需求结构在算法空间里的投影。may 与 must 的对偶
（安全上界对安全下界）与前后向的对偶（沿数据流对逆流问未来）
是贯穿全章的两条主轴。

**第二，把 must 分析的三个特殊问题一次讲透。** must 从全集
出发，因为 must 的语义目标是最大不动点，从 ∅ 出发的上升迭代
会在"环上互相支撑的乐观假设"处卡死；边界点是 ∅，因为边界
没有猜测余地，且"无前驱取 ∅"的缺省值恰好与边界语义重合；
全集不可枚举，就用"全部 gen 因子之并"作可表示全集——观察
传递函数只放 gen 因子、论证裁剪不改变不动点、确认有限性，
三步完成理论与实践的对接。

**第三，用四段真实输出训练了"读表"的体感。** 同一循环头在
四段输出里呈现四张不同的问卷；"两支都算"在可用与非常忙里
兑换成两张不同的许可证；kill 的三种口径（变量、同变量定值、
含目标的子式）出自同一个 `assignTargetName`；d4/d5 在出口
"复活"而 `(a>0)` 在循环头一去不返——存在量词与全称量词的
不对称，在一次并排对读里现出原形。

工程侧的收获同样具体：一张规格结构体、一个方向无关的驱动器、
一对只差一个布尔的孪生规格、一份逐字节对账的输出协议。也
记下了框架的边界：传递函数若要依赖**状态本身**（如"b 可能
未初始化，则 `c = b` 使 c 也可能未初始化"），gen/kill 的
语句级抽象就不够用了——第 32 章的可能未初始化分析将手写
传递函数，作为 gen/kill 框架的第一块补丁。

读者此刻应当有能力：给定任意一个"沿图传播集合信息"的分析
需求，先问方向、量词、gen/kill、初值、边界五个问题，把答案
填进 `DfaSpec`，剩下的交给 `runDfa`。这个"先填表、再驱动"的
动作，就是数据流分析框架化的全部要义。




