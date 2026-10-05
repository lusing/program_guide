# 第 37 章　区间格：第一块非有限高度的格

## 37.1 本章要解决的问题

到第 35 章为止，本书已经造好了一条完整的流水线：ANTLR4 把源程序变成
AST，名字解析把每个使用点绑到声明，CFG 把树形的函数体摊成程序点与边，
worklist 在这张图上求单调方程组的最小不动点。这条流水线本身与"分析
什么"无关——换一块格、换一组传递函数，同一个求解器就能回答新的问题。
第 32 章的常量传播与第 33 章的四大经典分析，都是对这个事实的两次验证。

但此前出现过的每一块格都有一个共同的、当时没有特别强调的性质：**它们
都是有限高度的**。符号格只有 {−, 0, +, ⊥, ⊤} 五个元素，常量格是"具体
整数加 ⊥、⊤"的扁格，幂集格的底是有限的程序点集合——从 ⊥ 出发沿严格
上升的方向走，步数有一个可以事先算出来的上限。worklist 的终止性证明
正是靠这条性质：每次状态变化都沿格严格上升，而严格上升的链有尽头。
本章要第一次离开这个安全区，引入一块读者在任何真实的静态分析工具里
都会遇到的格——**区间格**（interval lattice），并且亲眼看到：当格不具
备有限高度时，此前"一定终止"的承诺是怎么失效的，失效时的输出又是
什么形状。这次"失败"不是事故，而是第 38 章 widening（拓宽）的全部
动机。

### 37.1.1 常量格为什么不够用

先说为什么需要区间格。第 32 章的常量格只能回答一个非常强硬的问题：
"在这个程序点，变量 x *恰好*等于某个已知常量吗？"答案三选一：⊥
（不可达）、具体值 c、⊤（不是唯一常量）。考虑下面几类很普通的问题：

- `y = x + 1` 之后 `output y`，已知 x 来自用户输入、但在前面的分支里
  已经被限制成正数——y 的范围是什么？
- `z = 100 / x`：x 在这个点是否可能为 0？如果不可能为 0，商的最小、
  最大值落在哪？
- 一段循环把计数器从 1 加到"某个输入值"，循环结束后计数器最大能是
  多少？

常量格对这些问题一律回答 ⊤，因为变量在这些点都不是唯一常量。但 ⊤ 是
一句信息量为零的判词："不是常量"并不意味着"什么都可以说"。正数集合、
区间 [1, 100]、非零整数——这些都是比 ⊤ 精确得多、又不需要唯一值的
描述。要表达它们，抽象值必须是**值的集合**而不是单个值。

在所有"值集合"的形状里，区间是最简单、也最常用的一种：它只记两个
端点——最小值与最大值。"x 是正数"写成 [1, +∞]，"x ∈ {1,…,100}"写成
[1, 100]，"x 非零"无法用单个区间表达（要写成 [−∞,−1] 与 [1,+∞] 的并，
这是区间分析精度的固有边界，37.8 节还会提到）。优化与校验中大量的问题
恰好只关心两端：除零关心下界是否 ≤ 0 ≤ 上界，循环次数关心上界，代码
生成中的范围分析（range analysis）关心每个变量需要多大的机器宽度。
区间格以每个变量两个整数的极低代价，给这些问题提供可靠（sound）的
答案。

### 37.1.2 本章的演示程序

本章配套示例 `20_interval` 使用的程序是 `programs/loop.tip`：

```
main() {
  var x;
  x = 1;
  while (input > 0) {
    x = x + 1;
  }
  output x;
  return 0;
}
```

程序做的事很直白：x 初值为 1；只要用户输入正数，就把 x 加一后继续问；
输入非正时循环结束，打印 x。循环执行多少轮完全由输入决定——可能一轮
不转（第一次就输入 0），也可能转任意多轮。因此循环结束时 x 的真值集合
是 {1, 2, 3, …}，用区间写就是 [1, +∞]。这正是我们希望分析器算出的
结果。

读完本章后读者会看到一个似乎矛盾的现象：正确答案 [1,+∞] 简单明确，
但朴素的不动点迭代在有限时间内算不出它。迭代从 [1,1] 走到 [1,2]、
[1,3]、……每轮只放宽一个单位，永远在"逼近"的路上。问题不在答案，而在
**逼近的路径没有有限的尽头**。要理解这件事，需要先把区间格本身严格地
定义出来。

## 37.2 区间格的形式化

### 37.2.1 具体域与抽象域

先约定被近似的对象。机器整数是 32 位有符号整数，集合为

> C = { INT_MIN, INT_MIN+1, …, INT_MAX−1, INT_MAX }

其中 INT_MIN = −2³¹、INT_MAX = 2³¹−1。抽象分析在数学上通常把整数看成
ℤ 来推理，因为把边界 INT_MIN/INT_MAX 纳入每条公式只会使论证臃肿；本章
沿用这个惯例，但用两个**哨兵值**（sentinel）INT_MIN、INT_MAX 同时承担
"机器边界"与"−∞、+∞"两个角色，20.2.3 小节会专门核对这种一物两用是否
会损害可靠性。结论先给：不会，但有一个必须显式接受的精度代价。

区间抽象域的元素形如 Iv{lo, hi}，其中 lo、hi 各是一个 32 位整数：

- 当 lo ≤ hi 时，Iv{lo,hi} 表示整数集合 { n ∈ C : lo ≤ n ≤ hi }，端点
  若为哨兵则读法向无穷开放：lo=INT_MIN 表示左端不设界，hi=INT_MAX
  表示右端不设界；
- 当 lo > hi 时，该元素不表示任何状态，它编码底元素 ⊥，含义是
  "程序点不可达"或"尚无信息"。

用一对整数、靠 lo>hi 这一个条件额外编码 ⊥，而不是给结构体加一个
bool 标记，是因为对一切 lo ≤ hi 的数对，区间的含义都无歧义、数对与
区间一一对应；可表示的合法区间没有任何"浪费"的编码。⊥ 只在迭代起点
和不可达点出现，取一个最醒目的非法数对 Iv{1,0} 即可——底具体是哪个
lo>hi 的数对无关紧要，因为所有这样的数对在格运算里都按同一条规则
处理（20.2.4 小节），不会参与区间之间的数值计算。

顶元素 ⊤ 是 Iv{INT_MIN, INT_MAX}，即 (−∞,+∞)：它表示整个整数集合，
含义是"这个点可达，但对变量的值一无所知"。注意 ⊥ 与 ⊤ 的对照：⊥ 说
"执行到不了这里"，⊤ 说"执行到得了这里、值可能是任意整数"。两者绝不可
混——把不可达点当 ⊤ 会凭空为不可达路径报警，把可达点当 ⊥ 会漏掉真实
状态。

### 37.2.2 偏序与最小上界

区间格上的偏序就是**集合包含**：a ⊑ b 当且仅当 a 所表示的整数集合包含于
b 所表示的集合。信息论的读法照旧：a ⊑ b 表示 a 的信息更精确，b 是对
同一批可能状态更宽松的描述。用端点写出来，对两个非底区间：

> Iv{la,ha} ⊑ Iv{lb,hb} 当且仅当 lb ≤ la 且 ha ≤ hb

方向值得停一下：下界越大、上界越小，区间越窄，信息越准，所以它在序上
越小（越靠近 ⊥）。底元素是最小元：⊥ ⊑ 一切；顶是最大元：一切 ⊑ ⊤。

最小上界（join，⊔）是包含两个区间的最窄区间，即端点的**包络**：

> Iv{la,ha} ⊔ Iv{lb,hb} = Iv{ min(la,lb), max(ha,hb) }

任何同时包含两个输入区间的区间，其下界不超过两个下界的较小者、上界不
小于两个上界的较大者，所以包络确实是"最小"的上界。与底取 join 返回
另一个元素（⊥ 是单位元）；与顶取 join 必然得顶。

### 37.2.3 哨兵一物两用的可靠性核对

INT_MIN 既是真实可表示的机器整数，又在端点处读作 −∞，这会不会让
[INT_MIN, 5] 产生歧义？需要把抽象元素的"具体化函数"（concretization）
写清楚。定义 γ：区间 → C 的幂集，仍按 {n : lo ≤ n ≤ hi} 收集，其中哨兵
不享受任何特权——INT_MIN 就是整数 INT_MIN。那么：

- 读作"−∞ 端"时，意图表示的是 ℤ 中一切 ≤ hi 的整数；但小于 INT_MIN
  的整数在 C 中根本不存在，所以这个意图在 C 上收集出来的集合，恰好
  就是 {n ∈ C : INT_MIN ≤ n ≤ hi}，与按真实 INT_MIN 收集完全相同。
  INT_MAX 端同理。

也就是说，"无穷"只是证明时的语言；落到 32 位机器上，−∞ 端的实际外延
与真实 INT_MIN 端一致，不存在任何一个被两种读法区分的具体状态。抽象
运算只要保证：哨兵参与加减乘时结果仍被正确地包络，γ 就不会"漏人"。
本章的做法是让一切越过哨兵的运算**饱和钳位**（saturate）到 INT_MIN 或
INT_MAX（37.3 节），而不是发生溢出回绕（wrap around）。回绕会得到一个
数值很小甚至变号的结果，反而落到错误的窄区间里，是区间分析中典型的
不可靠来源；钳位保持结果区间单调扩大，因而是可靠的。

精度代价也要明说：当某次具体运算的真实机器结果恰因溢出而回绕时
（例如 INT_MAX+1 在机器上得到 INT_MIN），抽象分析给的是钳位后的
+∞ 端而不是真实回绕值。这意味着分析不再逐位重现溢出语义，而是把溢出
情形统一归入"值可能很大"。这是静态分析普遍接受的折中：我们关心的
优化与校验几乎都不想在溢出回绕的精确比特模式上做文章；若某次分析确实
需要，应当把"是否发生溢出"本身作为一个独立的抽象事实另行跟踪。

### 37.2.4 为什么这是一个格

包络 join 满足格所需的定律，这里给出核对的思路，读者可自行补全证明：
交换律、结合律来自 min/max 的相应性质；幂等律 a⊔a=a 显然；底是单位元
（⊥⊔a=a）；吸收律 a⊔(a⊓b)=a 可由"包络不会比输入更窄"直接得到。因此
带 ⊥、⊤ 的区间集合构成一个完备格：任意一簇区间的 join 就是它们全体
端点的包络（空簇的 join 为 ⊥）。完备格意味着 Knaster–Tarski 定理的
全部前提成立——**单调函数的最小不动点一定存在**。请记住这句话，37.6 节
会揭示它与"算法能否在有限步内找到不动点"是两个独立的命题。

### 37.2.5 环境格：变量到区间的逐点提升

单个变量的区间还不是程序状态。程序点上的状态要同时描述函数里所有
局部变量，它是 `IvEnv = map<string, Iv>`：变量名 → 区间。环境格直接
用第 29 章的 maps 构造得到——固定键集（函数声明的变量与参数集合），
每个键上各取区间格，join 逐变量做包络、序为逐变量包含、缺键按 ⊥。

这正是第 29 章那套"格构造器"的复用：本章没有为环境新写任何格代码，
只在调用求解器时以区间格为参数生成映射格。`lattice.hpp` 中的泛型
`Lattice<A>` 与四类构造因此是本章的直接基础设施，会在 37.11 节随实现
一起给出。

## 37.3 抽象运算：从区间到区间

有了区间格，表达式的抽象求值 `evalIv` 就是第 32 章常量折叠的"区间版"：
输入一个表达式与环境，逐语法结构把变量替换成区间、把运算符替换成区间
运算，输出一个区间。构造原则与常量折叠一致——**结果区间必须包含所有
可选择的具体运算结果**——但因为每个操作数是一批值而不是一个值，二元
运算的结果要对端点的组合取包络。

### 37.3.1 常量、变量与输入

基础情形最直接：整数字面量 v 求成单点区间 [v,v]；变量 x 在环境中查它
的区间，环境里没有该键时返回 ⊥（这与第 32 章"未绑定即 ⊥"的处理一致：
出现这种情形只可能是前驱尚未传播或路径不可达）；`input` 求成顶区间
[INT_MIN, INT_MAX]——用户可以输入任意整数，不掌握任何信息时这是唯一
可靠的选择。

### 37.3.2 加法与减法：端点对端点

若左操作数区间为 [la,ha]、右为 [lb,hb]，且两者都不是 ⊥，加法的最小
可能结果是 la+lb、最大是 ha+hb，因此：

> [la,ha] + [lb,hb] = [ sat(la+lb), sat(ha+hb) ]

中间值会不会取得更小或更大？不会：两个加数分别在各自区间内独立选取，
和随两个加数单调增长，极值必在端点取得。减法同理但右端要交换：

> [la,ha] − [lb,hb] = [ sat(la−hb), sat(ha−lb) ]

差随被减数增长、随减数减小而增长，所以最小差用 la−hb、最大差用
ha−lb。这里的 sat 是 20.2.3 小节承诺的饱和钳位：用 64 位 long long
做中间运算，越过 INT_MAX 钳成 INT_MAX、低于 INT_MIN 钳成 INT_MIN。
64 位中间值保证两个 32 位数相加绝不溢出，钳位判断因此总是可信。

### 37.3.3 乘法：四种端点组合

乘法比加减法麻烦，因为积对乘数不是全局单调的——负负得正，最小值可能
由"一正一负"的组合取得。可靠而简单的做法是**穷举端点**：从 {la,ha} ×
{lb,hb} 的四个组合各算一个积，结果区间取四个积的最小值与最大值。
连续函数在矩形区域上的极值若不在内部临界点取得，就在边界取得；xy 在
矩形内部没有极值点（偏导 y、x 不同时为 0 除非退化为 0），所以四个角
已经涵盖最坏情况。

哨兵参与乘法时不能直接相乘再比较：INT_MAX × INT_MAX 会在真实运算中
溢出，而 long long 装得下两个 32 位数的积（约 2⁶²），所以四个积先在
64 位下算出再钳位即可；而当某一端是 ±∞ 意图（哨兵）、另一端符号未知
时，积的符号本身不确定，实现里按同号为同号无穷、异号为异号无穷、乘以
0 为 0 的规则分别给出端点（`mulLo`/`mulHi` 两个辅助函数），规则的依据
仍是极限的符号：x→+∞ 时 xy 的趋向完全由 y 的符号决定。

### 37.3.4 除法：本章的保守选择

除法是本章唯一无法靠"端点组合"简单处理的运算，原因有两个。其一，除数
区间若包含 0，则在选取除数为 0 的那些具体执行中运算直接抛出动态错误，
商不存在；分析不能假装这些执行有一个有限的商。其二，整数截断除法
（C 语言语义：向 0 取整）在除数接近 0 时商的绝对值可以任意大，即使
除数区间只是 [-1,2] 这样的小范围（不含 0 端点时除外）。

本章实现选择最简单可靠的策略，分三种情况：

1. 除数区间包含 0（r.lo ≤ 0 ≤ r.hi）：商可能不存在也可能任意大，
   直接返回顶 [INT_MIN, INT_MAX]；
2. 分子、除数都是单点常量：具体值非零时精确折叠成单点；
3. 其余一切情况：同样保守返回顶。

第 3 条显然牺牲了不少精度——例如 100 除以 [6,7] 明明可以确定商在
{14,…,16}。这种牺牲是有意的：本章的主题是格的高度与迭代终止性，不想
让除法的端点分析分散注意力；第 39 章会把除法升级为"除数区间排除 0
时，对四个端点组合取截断商的包络"，读者在那里可以对照看到同一条
可靠性原则下两种精度的实现。**先求可靠、再按章节主题决定精度投入**，
这是贯穿全书的节奏。

### 37.3.5 比较运算与其余情况

`>` 与 `==` 在本章求值中也保守地返回顶：它们的具体结果是 0/1，理论上
可以给 [0,1] 甚至按操作数区间判定，但单知道"这个比较表达式本身的
区间"对后续分析用处不大——真正有用的信息是**沿分支的条件精炼**（比较
成立时操作数区间应如何收窄），那需要在 CFG 的边上动手脚，是第 21、
22 章的内容。本章在表达式层面返回顶，却在 37.6 节的追踪中保持控制流
两支都被遍历：求解器不依赖条件的真假来剪枝，这正保证了即使条件是
`input > 0` 这种完全未知的比较，循环的所有轮次效应也都不会被漏掉。

## 37.4 朴素迭代器：把第 31 章的引擎用在新区间上

### 37.4.1 方程组

第 31 章把 forward 分析的方程写成两句话，这里原样照搬，只把事实格换
成区间环境格。对每个程序点 l：

- 流入事实 in(l) = ⊔ { out(q) : q → l 是 CFG 边 }，即所有前驱出口事实
  的 join；入口点没有前驱，in(entry) 取边界条件——本章 main 无参，边界
  为空环境（若有参数，可靠的边界是把每个参数绑成顶区间）；
- 流出事实 out(l) = F_l( in(l) )，其中 F_l 是该点的传递函数：赋值点
  `x = e` 在流入环境上抽象求值 e，把 x 绑定为结果区间；其余节点（分支、
  输出、连接点）的传递函数是恒等。

这与第 32 章常量传播的方程组形状完全一致，再一次体现"引擎与域无关"。
区别只在底层的 join：常量格把两个不同值合并成 ⊤，一步到位；区间格把
两个区间合并成包络，只放宽到"恰好包含两者"的宽度。这个区别正是 20.6
节全部现象的根源。

### 37.4.2 round-robin 调度

本章没有直接复用 worklist，而是写了一个更朴素的调度，目的是让"轮"这个
概念在输出中清晰可见：**round-robin（循环赛）迭代**——每一轮按节点号
从小到大把所有程序点重算一遍，重算时从当前的 out 表读取前驱。若一整
轮里没有任何点的结果发生变化，方程组在所有点上同时成立，已经到达不动
点，停机；否则进入下一轮。

轮数与 worklist 的"节点处理次数"不同：一轮处理全部节点。选择 round-
robin 是为了让配套输出里的 iter k 与"信息沿循环回流了 k 次"严格对应，
便于手工核对；终止性和正确性结论对 worklist 同样成立，两种调度在
有限高度格上都终止，在无限高度格上都可能不终止。

### 37.4.3 循环头的选取与轨迹记录

为了把不终止"演出来"，求解器每轮记录一个观察点的环境并最终打印。观察
点取**循环头**——程序中第一条 while 语句对应的分支节点。在 loop.tip 的
CFG 上，编号规则与第 14 章一致：entry=1，函数体语句按先序从 2 开始
（x=1 是节点 2，while 分支是节点 3，循环体 x=x+1 是节点 4，循环之后的
output x 是节点 5），return 与 exit 接在最后。因此输出里写明
`loop head: node 3`。循环头是所有"循环携带信息"的汇合点：每多转一轮，
新的 x 区间都在这里与上一轮的区间 join。盯着这一个点，就足以看清迭代
序列的形状。

## 37.5 手工追踪：iter k 的 x=[1,k+1] 是怎么来的

在看真实输出之前，先把前几轮手算一遍。记号 x_n 表示节点 n 的出口环境
中 x 的区间；节点 2 是 `x = 1`，节点 3 是 while 分支（恒等传递），节点 4
是 `x = x + 1`，节点 5 是 output。边为 1→2→3，3→4，4→3，3→5。

**第 0 轮。** 节点 2：in 为空（entry 边界空），传递后 x_2=[1,1]。
节点 3：前驱只有节点 2 已算，x_3=[1,1]。节点 4：in=[1,1]，加一得
x_4=[2,2]。节点 5：前驱是节点 3，得到 [1,1]。轮末记录循环头：iter 0:
x=[1,1]。这一轮里节点 4 的 [2,2] 已经算出，但它要到下一轮才被节点 3
读到——round-robin 一轮之内新值不回头使用。

**第 1 轮。** 节点 3 的 in 现在是两个前驱的 join：节点 2 仍给 [1,1]，
节点 4 给上一轮的 [2,2]，包络为 [1,2]。节点 4 随即在此基础上加一，得
[2,3]；节点 5 从节点 3 收到 [1,2]。轮末记录：iter 1: x=[1,2]。

**第 2 轮。** 节点 3 join [1,1] 与 [2,3] 得 [1,3]；节点 4 得 [2,4]。
记录 iter 2: x=[1,3]。

规律已经清楚：归纳地，若第 k 轮循环头为 [1,k+1]，则节点 4 算出
[2,k+2]，下一轮节点 3 把它与 [1,1] 包络，得 [1,k+2]。于是

> iter k : x = [1, k+1]（k = 0, 1, 2, …）

每一轮严格变宽一个单位，从不重复。output 点（节点 5）每轮从循环头
收到同样的 [1,k+1]：这与 20.1.2 小节对真值集合 {1,2,3,…} 的判断一致
——事实上迭代正在逐一枚举真实的可能值，枚举得完全正确。问题只剩下
一个：枚举不完。

## 37.6 不终止：有限高度前提的失效

### 37.6.1 真实输出的形状

配套 `expected/output.txt` 是一次真实运行的逐字结果（标题行
`== loop.tip ==` 由测试框架添加）：程序先报告循环头是节点 3，随后依次
打印 iter 0 到 iter 49 的 50 条轨迹，每条形如 `iter k: x=[1,k+1]`，最后
一行是：

> DID NOT CONVERGE after 50 rounds: chain [1,1] <= [1,2] <= [1,3] <= ... has no end

50 这个数字不是分析结论，而是运行前设下的安全闸（maxRounds）：到达
上限仍未见任何两轮之间完全静止，求解器停止并明确报告"未收敛"，而不是
静默返回一个中间值冒充不动点。把上限设得再大——500、5000——也只是把
同一条链打印得更长；手工追踪的归纳式对一切 k 成立，没有任何一轮会出现
`changed = false`。

### 37.6.2 第 31 章终止性证明的哪一条前提失效了

回顾有限高度格上的终止性论证：每次状态更新若发生变化，新值严格大于
旧值；从任意起点出发的严格上升链长度有一个仅依赖格的有限上界 H；
把全部节点上的上升次数相加，更新总数因此被 H × 节点数 封顶，调度器
必然在这么多次更新内停机。

区间格上第一个分句仍然成立——每轮 x 确实严格变宽；失效的是第二个
分句：链 [1,1] ⊏ [1,2] ⊏ [1,3] ⊏ … 长度没有有限上界。用第 29 章的术语说，
区间格**不满足上升链条件**（Ascending Chain Condition, ACC）：存在一条
无限的严格上升链。"每次都在进步"与"进步能够穷尽"被这条链分离开来，
终止性证明的计数法由此失去分母。

严格地说，在 32 位机器整数上区间格其实是有限的——区间总数约 2⁶³ 量级，
链 [1,k] 走到 INT_MAX 也会停。但这个"有限"对算法毫无安慰意义：等待
2³¹ 轮与等待无限轮在实践中不可区分，而一个编译器分析必须在毫秒级完成。
因此在工程与理论叙述中，区间格都按"无限高度"对待：数学上把具体域看成
ℤ，ACC 确实失效；机器上即使复活 ACC，高度也大到不可使用。第 38 章的
widening 对这两种读法给出同一个修复。

### 37.6.3 Tarski 保证的是"存在"，不是"可达"

这里要澄清一个常见的误解。20.2.4 小节说过，Knaster–Tarski 定理保证单调
函数的最小不动点在完备格上**存在**。对 loop.tip，最小不动点甚至可以直接
写出来：循环头 x=[1,+∞]、output 点 x=[1,+∞]——它正是链 [1,1] ⊏ [1,2]
⊏ … 在格中的上确界（极限）。但 Kleene 迭代 x_{n+1}=F(x_n) 给出的是
链上的第 n 个元素；要取得极限，需要**超限迭代**（transfinite iteration）：
在第一个极限序数 ω 处取整条链的 join，然后才可能继续。普通 worklist 与
round-robin 只执行后继步骤，没有"在极限处取上确界"这一步。

所以本章演示的精确表述是：**不动点存在且可描述，但从 ⊥ 出发的有限步
Kleene 迭代到不了它。**这不是分析器实现得不好，而是"不动点存在"与"迭代
方法完备"本来就是两件事。让有限计算可靠地逼近极限的办法有两类，恰好
对应第 38 章的两个关键词：人为加速上升过程使链在有限步内走完
（widening，∇），再在加速到达的点附近有限地向下修正（narrowing，Δ）。
本章的 50 轮失败输出就是为这两个算子准备的"问题现场"。

## 37.7 正确性论证思路

本章不要求新的求解器，正确性论证因此可以分成三层分别核对，每层的结论
都只依赖少量具体事实。

**第一层：抽象运算的局部可靠。** 要证明的命题是：若具体整数 n_l 落在
区间 a 内、n_r 落在区间 b 内，则对每种运算符，具体运算结果（在其有
定义时）落在 evalIv 给出的结果区间内。加减法由单调性与端点选取核对；
乘法由"矩形上的极值在四角"核对；除法在本章按"含 0 或非单点即顶"核对
——顶包含一切具体整数，命题平凡成立；输入取顶也同理。饱和钳位在这里
的作用是保证溢出情形仍被结果区间包含：真实回绕值虽未被精确预测，但
它属于整数全集，而钳位给出的区间在溢出情形必然已放宽到哨兵端、包含了
"结果可能任意大"的描述。需要强调：这保证的是**成员包含**（soundness），
不保证精确；本章的除法与溢出都用精度换来了论证的简单。

**第二层：传递函数单调。** 环境格上的赋值传递 F(x=e)(S) 只在 x 一处
改变环境、其余原样保留；evalIv 对其环境参数单调——区间变宽时，端点
组合的包络不会变窄。恒等传递当然单调。单调性是不动点存在与第三层论证
的共同前提。

**第三层：不动点对所有执行可靠。** 设分析已在某个（近似）不动点上。
对任意一次具体执行，按其长度归纳：入口处具体初始状态满足边界条件
（无参时平凡）；若执行到节点 l 之前的具体状态被 in(l) 包含，局部可靠
保证经过 l 后被 out(l) 包含，而不动点方程保证 out(l) 正是由 in(l) 经传递
得到；CFG 边覆盖了一切可能的控制流，因此执行无论沿哪条边行进，归纳
都不断。结论：执行在每个程序点观察到的具体值，都落在该点分析结果的
区间内。对本章的朴素迭代，严格地说还要补一句——迭代在 50 轮处停止时
拿到的不是不动点，因此这条结论只在"迭代真正收敛"时无条件成立；第 38 章用 widening 恢复收敛后，`--verify-soundness` 会以真实执行为证据把这
条结论实测一遍。本章演示的价值恰在于展示缺少收敛时不能声称可靠：
未收敛的中间结果只能称为"迭代轨迹"，不能称为分析答案。

与路径合流（MOP）的关系也顺带说一句：沿每条具体路径依次复合传递函数、
最后对所有路径 join 的结果称为 MOP 解，它精确但路径数可能无限、不可
计算；逐点 join 前驱再传递的 MFP（最大不动点）解在格上比 MOP 更宽
（信息量更少），但可以计算。合流越早，精度损失越大，可靠性不变——
第 33 章讲过的这条关系，在区间格上一字不改。

## 37.8 工程注意点

第一，**一切抽象算术都要在更宽的整数类型里做中间运算**。两个 int 之积
在 int 里求和会溢出回绕，得到符号错误的端点；本章统一用 long long 承装
再钳位。比较与减法（取负）同理：−INT_MIN 在 int 里溢出，必须先转 long
long。

第二，**把迭代上限当作必需的安全设施，而不是调试开关**。面对无限高度
格，任何循环都必须有轮数或更新次数的封顶，否则分析器可以在病态输入上
挂死整个编译流程。触发上限时正确的做法是显式报告未收敛（本章的
DID NOT CONVERGE），让调用方知道结果不完整；绝不能把最后一轮的中间值
默默当答案——37.7 节解释过，那一声称没有可靠性保证。

第三，**观察点的环境打印只遍历声明变量集合**。envText 对键集合中缺失的
变量补成 ⊥ 而不是直接读 map，可以保证多函数、多轮次的输出列对齐、可
逐行 diff；这种确定性是让 expected 文件能被机器对账的前提。

第四，**保守化的精度代价要在章节层面规划，而不是随手为之**。本章除法
一律退顶，简单可靠但会让依赖商范围的下游分析失去信息；改进放在第 39 章与条件精炼一起落地。类似地，比较运算在表达式层面返回顶，把真正的
信息让给分支边。知道"哪里保守、为什么、在哪一章偿还"，比在一个示例里
把所有运算做到最精确更重要。

第五，**循环条件不参与剪枝反而是可靠性的来源**。`while (input > 0)` 的
真值静态不可知，求解器让 true/false 两支都参与合流，循环体每一轮的
效应都被计入。若某实现草率地把无法判定的条件按某一支处理，就会系统性
地遗漏路径——这类错误不报错、不挂死，只在对照真实执行时暴露。

## 37.9 练习

1. 用端点定义验证区间 join 的结合律，并说明 ⊥ 为什么是 join 的单位元
   而顶不是。
2. 把 loop.tip 的循环体改为 `x = x + 2`，给出 iter 0、1、2 的循环头
   区间并写出 iter k 的通式；再把初值改为 x=3，通式如何变化？
3. 证明：若 [la,ha]、[lb,hb] 都不含 0 端点且同号，乘法结果的最小值
   与最大值必在四个端点组合中取得。异号时这个结论还成立吗？
4. 本章除法对"分子与除数都是单点"才精确折叠。试修改 evalIv：当除数
   区间排除 0 且分子两端有限时，对四个端点组合算截断商并取包络。先
   写可靠性论证，再动手；与第 39 章的实现对照。
5. 解释 [INT_MIN, INT_MAX] 作为顶与 Iv{1,0} 作为底在迭代中各自的角色。
   若把底误设为顶，37.5 节的追踪从第 0 轮起会变成什么？
6. 在 32 位机器整数上，链 [1,1]⊏[1,2]⊏… 的真实长度是多少？以一轮
   1 毫秒估算，朴素迭代走到头需要多长时间？这个数字说明了什么？
7. 语言中若增加负数区间也无法表达的事实（如"x 非零"），你会如何扩
   展抽象值？给出两种方案（区间的有限并、新增独立布尔事实）并比较
   join 的实现代价。

## 37.10 小结

- 区间格以两个端点描述变量的值域：join 为包络，序为包含；lo>hi 编码
  不可达底，哨兵 INT_MIN/INT_MAX 编码无穷端，一物两用在 32 位具体域上
  不改变外延、因而可靠，代价是不重现溢出回绕。
- 区间格不满足上升链条件：存在无限严格上升链。第 31 章终止性证明依赖
  的"高度有限"前提首次失效；Tarski 定理仍保证最小不动点存在（此处即
  [1,+∞]），但有限步 Kleene 迭代只产出链上元素、到不了极限。
- 朴素 round-robin 迭代在 loop.tip 上给出 iter k: x=[1,k+1]，封顶 50 轮
  后明确报告 DID NOT CONVERGE。答案正确但不可达——这就是第 38 章
  widening/narrowing 要解决的问题现场。
- 正确性论证分三层：运算局部可靠（端点选取 + 饱和钳位 + 保守除法）、
  传递函数单调、不动点对一切具体执行可靠；未收敛时只能称轨迹、不能称
  答案。

## 37.11 本章实现：逐文件说明

下面把 `20_interval` 的全部文件整文件给出。每个文件嵌入前先说明它在
本章承担的角色与阅读重点；所有嵌入内容与示例目录中的文件逐字节一致，
读者无需再对照源码即可阅读全书。前端文件（文法、AST、构建器、符号表、
CFG、打印器）自第 4 章起冻结，此处给出是为了让本章自包含；阅读时可
快速略过其实现细节，重点放在 `lattice.hpp`、`interval.hpp/cpp` 与
`main.cpp` 上。

### 37.11.1 TIP.g4：本章实际使用的文法切片

文法自第 4 章冻结后没有再改动，这里整文件给出以便章节自包含。阅读本章
只需关注语句层的四条产生式：赋值、输出、if、while。它们决定了 CFG 的
形状——赋值产生一个程序点，if 与 while 各产生一个分叉点并在图上形成
汇合与环；表达式层的优先级链（乘法先于加减、比较最后）保证抽象求值
递归下降时运算符的解释与程序员的直觉一致。与常量传播那一章相比，文法
没有任何"为区间分析"做的扩展：新区间完全是在不变的语法之上更换值域
得到的，这正印证了第 29–31 章的分层——前端、图、引擎各自独立。

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

### 37.11.2 ast.hpp：冻结的语法树节点

AST 头文件列出了全部表达式与语句节点。本章分析只会实际遇到其中的一小
部分：IntLit、VarRef、InputE、Binop，以及 AssignS、OutputS、WhileS、
BlockS。其余节点（调用、指针、记录）由文法允许、本章程序不使用；
`evalIv` 对未显式处理的节点统一返回顶区间，因此即使分析一个含这些构造
的程序，分析器也不会报错或漏算，只会在相应位置丢失精度。阅读时注意每个
节点持有的是 unique_ptr 子节点：AST 的所有权是一棵树，CFG 节点中只保存
指向语句的裸指针做观察，分析期间 AST 始终存活、裸指针不悬垂。

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

### 37.11.3 ast_build.hpp：从 parse tree 到 AST 的构建器接口

这个头文件只有接口规模。注释里记录了一个工具链事实：ANTLR 的 C++
visitor 以 std::any 传值，无法持有 unique_ptr，因此构建器不使用 visitor
机制，而是直接在 parse-tree 上下文类上手工递归下降。对本章而言，选择
哪种遍历方式与分析精度无关；要点是构建器输出的 ProgramA 与后续所有阶段
（名字、CFG、区间）之间唯一的数据结构，接口的稳定让换格换引擎都无需
回头修改前端。

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

### 37.11.4 ast_build.cpp：节点翻译的逐备选实现

实现里每个 `dynamic_cast<TIPParser::XxxContext>` 对应文法中的一个标签
备选（# intExpr、# addExpr……）。值得对照文法看的两处：其一，负号
`-E` 没有专门的抽象语法，被翻译成 Binop(Sub, IntLit(0), E)，因此区间
分析不需要为"一元负"写任何特例——它只是减法运算；其二，函数体被统一
包成 BlockS，返回语句单独挂在 FunDecl.ret 上，这解释了 CFG 编号时为
什么"函数体 + 一个 return 节点"会被分别处理。本章程序的解析路径只经过
intExpr、varExpr、inputExpr、addExpr 与 assign/while/output 几个分支，
读者可在通读后用这条路径快速复查。

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

### 37.11.5 symtab.hpp：作用域与名字绑定的结构

符号表定义了三层符号（函数、参数、局部）、链状作用域以及解析结果
Bindings。区间分析在语义解释上已经不再直接查询符号表——evalIv 只按
变量名在环境 map 中取区间；名字解析仍是不可跳过的前置阶段：它保证程序
中每个变量都有唯一声明，函数体"声明变量集合"由此确定，而这个集合正是
环境格的键集与轨迹打印的列集。Bindings 持有全部函数作用域的所有权，
uses 表里的裸指针才在解析结束后继续有效。

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

### 37.11.6 symtab.cpp：两遍名字解析

解析分两遍：先把全部函数名注册进全局作用域（因此允许前向调用），再逐
函数开局部作用域、登记参数与局部变量、遍历函数体。对本章的意义有两点：
一是未声明、重复声明在分析开始前就以退出码 3 拦下，区间求解不必处理
"名字不知指什么"的病态情形；二是 resolver 遍历表达式的顺序与后续分析
完全一致（先左后右、先目标后右值），全书对同一棵 AST 的每一次递归
下降都维持这个形状，降低读者在章节之间切换时的心智负担。

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

### 37.11.7 cfg.hpp：控制流图的数据结构

CfgNode 只有四个成分：编号、种类（entry/exit/assign/输出/分支/返回）、
以及指向对应语句的观察指针。FunCfg 持有节点表与边表，Cfg 聚合所有
函数。注意节点编号是**每个函数各自从 1 开始**的：本章程序只有 main，
没有暴露这个问题；第 37、38 章处理多个函数时，状态必须按函数名分桶，
根源就在这个编号规则上。边不携带 true/false 标记——分支点的两条出边
在数据结构上没有区别；本章不需要区别它们（两支都要合流），第 38 章
恢复分支信息时会说明这个限制的后果与绕法。

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

### 37.11.8 cfg.cpp：两遍编号与连边

构造器的两遍结构值得细读：第一遍 numberStmt 严格按 AST 先序分配编号，
保证输出与程序点编号确定；第二遍 wireStmt 自外向内传入"后继点集合"
连边。while 的连法是本章追踪的图上依据——分支点 n 既连循环体（循环体
末尾回到 n），又连循环之后的后继，因此 n 有两个上游：初始化路径经节点
2 到达，循环携带路径经节点 4 到达；37.5 节手算的每次 join 都对应这条
结构。边在最后用 set 去重排序，保证同一张图构建多次得到逐字节相同的
结果。

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

### 37.11.9 pretty.hpp：打印器接口

打印器提供两类输出：完整的前缀式程序打印，与单行的语句打印。本章没有
在 --check 输出中直接使用它（求解器自己生成轨迹行），但区间分析的
debug 通常需要在节点旁边标注语句，printStmtLine 就是为此预留的通用
工具；第 49 章的过程间打印会实际调用它。

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

### 37.11.10 pretty.cpp：前缀式语法的重现

实现把每个运算符映射回固定的前缀写法（(+ a b)、(* a b)……）。阅读
这个文件的一个副产品是核对 AST 与具体语法之间没有信息丢失：给定一棵
AST，打印结果再解析应得到等价结构。这种"解析—打印"对称性是前端正确性
的快速 sanity 检查；它与本章的区间分析没有逻辑耦合，却同属"让每个
中间结果可见"的工程习惯——抽象环境、CFG、AST 在本书里都有自己的打印
形式。

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

### 37.11.11 lattice.hpp：格的统一接口与四类构造（本章基础设施之一）

这是第 29 章的成品、本章直接复用的文件。泛型 Lattice<A> 把一块格所需
的五个成分（顶、底、相等、偏序、join）打包；lift、product、maps、
powerset 展示四种把简单格拼成复合格的方式。本章用到两处：区间格本身
按 Lattice<Iv> 的形状提供五成分（见 interval.cpp 的 ivLattice），环境
格的构造思想对应 maps——固定键集、逐点 join。第 38 章引入 widening
时读者会看到格接口的边界：∇ 不是 meet 也不是 join，无法塞进这五个
成分，需要在求解器层面另行参数化；因此本章把"新区间装进旧接口"作为
最后一次纯粹复用记住。

```cpp
// file: src/lattice.hpp
// 格的统一接口与四类通用构造（spa 第 4 章）。
// 一个"格"只需提供：顶/底两个边界、相等判定、偏序、最小上界。
// 提升(lift)、积(product)、映射(maps)、幂集(powerset)能把简单格组装成
// 程序状态所需的复合格——抽象环境就是"变量集合 → 值格"的映射格。
#pragma once

#include <functional>
#include <map>
#include <optional>
#include <set>
#include <tuple>
#include <utility>

namespace tip {

template <class A>
struct Lattice {
    A topV;
    A botV;
    std::function<bool(const A &, const A &)> eqF;
    std::function<bool(const A &, const A &)> leqF;
    std::function<A(const A &, const A &)> joinF;

    const A &top() const { return topV; }
    const A &bot() const { return botV; }
    bool eq(const A &a, const A &b) const { return eqF(a, b); }
    bool leq(const A &a, const A &b) const { return leqF(a, b); }
    A join(const A &a, const A &b) const { return joinF(a, b); }
};

// ---- 提升：给 A 加一个新底 ⊥=nullopt（"还没有值"） ----
template <class A>
Lattice<std::optional<A>> lift(const Lattice<A> &l) {
    using O = std::optional<A>;
    return Lattice<O>{
        O{l.top()}, O{std::nullopt},
        [](const O &a, const O &b) { return a == b; },
        [l](const O &a, const O &b) {
            if (!b.has_value()) return a == b;        // ⊥ 最小
            if (!a.has_value()) return true;
            return l.leq(*a, *b);
        },
        [l](const O &a, const O &b) {
            if (!a.has_value()) return b;
            if (!b.has_value()) return a;
            return O{l.join(*a, *b)};
        }};
}

// ---- 积：分量各自取 join，序为逐分量序 ----
template <class T, std::size_t... Is, class LTuple>
T tupleJoin(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return T{std::get<Is>(lats).join(std::get<Is>(a), std::get<Is>(b))...};
}
template <class T, std::size_t... Is, class LTuple>
bool tupleLeq(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return (... && std::get<Is>(lats).leq(std::get<Is>(a), std::get<Is>(b)));
}

template <class... As>
Lattice<std::tuple<As...>> product(const Lattice<As> &... ls) {
    using T = std::tuple<As...>;
    auto lats = std::make_tuple(ls...);
    T topT{ls.top()...};
    T botT{ls.bot()...};
    return Lattice<T>{
        std::move(topT), std::move(botT),
        [](const T &a, const T &b) { return a == b; },
        [lats](const T &a, const T &b) {
            return tupleLeq<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        },
        [lats](const T &a, const T &b) {
            return tupleJoin<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        }};
}

// ---- 映射：固定键集上逐点 join；键缺失按底处理 ----
template <class K, class V>
Lattice<std::map<K, V>> maps(const Lattice<V> &l, const std::set<K> &keys) {
    using M = std::map<K, V>;
    M topM, botM;
    for (const K &k : keys) {
        topM.emplace(k, l.top());
        botM.emplace(k, l.bot());
    }
    auto getOrBot = [&botM](const M &m, const K &k) {
        auto it = m.find(k);
        if (it != m.end()) return it->second;
        return botM.at(k);
    };
    return Lattice<M>{
        topM, botM,
        [](const M &a, const M &b) { return a == b; },
        [=](const M &a, const M &b) {
            for (const K &k : keys)
                if (!l.leq(getOrBot(a, k), getOrBot(b, k))) return false;
            return true;
        },
        [=](const M &a, const M &b) {
            M r;
            for (const K &k : keys) r.emplace(k, l.join(getOrBot(a, k), getOrBot(b, k)));
            return r;
        }};
}

// ---- 幂集：join=并，meet=交，序=包含；顶=给定全集（默认为空集） ----
template <class K>
Lattice<std::set<K>> powerset(const std::set<K> &universe = {}) {
    using S = std::set<K>;
    return Lattice<S>{
        universe, S{},
        [](const S &a, const S &b) { return a == b; },
        [](const S &a, const S &b) {
            for (const K &k : a)
                if (!b.count(k)) return false;
            return true;
        },
        [](const S &a, const S &b) {
            S r = a;
            r.insert(b.begin(), b.end());
            return r;
        }};
}

}  // namespace tip
```

### 37.11.12 interval.hpp：区间元素、环境与求解结果的接口

头注释浓缩了本章的逻辑链条：区间回答两端问题，lo>hi 编码底，区间格
高度无穷，Tarski 仍保证不动点存在、朴素迭代却不保证到达。接口分四组：
Iv 结构与相等判定；ivLattice 给出格；ivText 负责显示（[-inf,+inf] 与
bottom 两种特殊文本）；evalIv 抽象求值；NaiveResult 承载收敛标志、
实际轮数、逐轮轨迹与循环头编号。注意 IvEnv 的缺键语义与符号环境一致：
map 中没有的变量被当作 ⊥，这条约定让"前驱尚未传播"与"不可达"共用同一
个表示，和第 31 章的处理一脉相承。

```cpp
// file: src/interval.hpp
// 第 37 章配套：区间格与朴素迭代的不终止演示（spa 第 4→5 章的衔接）。
// 区间 [lo,hi] 回答"这个变量最小/最大能取多少"；lo>hi 编码 ⊥（不可达）。
// 与符号格不同，区间格**高度无穷**：[1,1] ⊑ [1,2] ⊑ [1,3] ⊑ … 没有尽头。
// Tarski 定理仍保证最小不动点存在，但朴素迭代不再保证在有限步内到达它——
// 本章用封顶 50 轮的朴素迭代把这个不终止"演出来"，为第 38 章 widening 铺路。
#pragma once

#include <climits>
#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "lattice.hpp"

namespace tip {

// INT_MIN/INT_MAX 哨兵表示 -∞/+∞；lo>hi 表示 ⊥。
struct Iv {
    int lo, hi;
};
inline bool operator==(const Iv &a, const Iv &b) {
    return a.lo == b.lo && a.hi == b.hi;
}

// 区间格：join 取包络（min lo, max hi），序为逐界包含。
Lattice<Iv> ivLattice();

// 区间文本：[1,3]、[1,+inf]、bottom。
std::string ivText(const Iv &v);

// 抽象环境：变量 → 区间；缺键按 ⊥。
using IvEnv = std::map<std::string, Iv>;

// 抽象求值：常量→[v,v]；input→全区间；加/减/乘按端点组合取包络；
// 除与未支持的运算保守取全区间。
Iv evalIv(const Expr *e, const IvEnv &env);

// 封顶轮数的朴素迭代轨迹：每轮记录"循环头"点（第一条 while 语句所在节点）
// 的完整环境，用于演示迭代序列如何一路变松而不收敛。
struct NaiveResult {
    bool converged = false;
    int rounds = 0;                       // 实际执行的轮数（含未收敛时的上限）
    std::vector<std::string> trace;       // 每轮循环头环境的文本
    int headNode = -1;                    // 循环头节点号（无循环时 -1）
};

NaiveResult runNaiveInterval(const Cfg &cfg, const ProgramA &program,
                             int maxRounds);

}  // namespace tip
```

### 37.11.13 interval.cpp：格、运算与朴素迭代的全部实现

这是本章篇幅最重、也最需要逐段对照正文的文件。建议的阅读顺序：先读
ivLattice（约 53–70 行），把顶、底、序、join 四条 lambda 与 37.2 节的
定义一一对应；再读 satAdd/mulLo/mulHi 与 evalIv（84–126 行），核对
每种运算符"端点组合取包络、含零除法退顶、输入取顶"的规则与 37.3 节的
可靠性论证；最后读 runNaiveInterval（128–189 行），注意三件事：循环头
的查找、前驱表的构建、以及每轮"join 前驱 → 参数边界 → 赋值传递 → 比较
旧值"的固定四步。轨迹行由 envText 按声明变量集合生成，缺键补 ⊥。20.5
节的手算可以直接在这段代码上逐行重演。

```cpp
// file: src/interval.cpp
#include "interval.hpp"

#include <algorithm>
#include <sstream>
#include <vector>

namespace tip {
namespace {

// 端点饱和加/减/乘：越过哨兵一律钳到 ±∞。
int satAdd(long long a, long long b) {
    long long r = a + b;
    if (r > INT_MAX) return INT_MAX;
    if (r < INT_MIN) return INT_MIN;
    return static_cast<int>(r);
}
int satMul(long long a, long long b) {
    long long r = a * b;
    if (r > INT_MAX) return INT_MAX;
    if (r < INT_MIN) return INT_MIN;
    return static_cast<int>(r);
}
// "未知符号"端的保守处理：与 ±∞ 相乘的有限端按同号无穷估计。
int mulLo(int a, int b) {
    if (a == 0 || b == 0) return 0;
    if (a == INT_MIN || b == INT_MIN) return INT_MIN;
    if (a == INT_MAX || b == INT_MAX) return (a > 0) == (b > 0) ? INT_MAX : INT_MIN;
    return satMul(a, b);
}
int mulHi(int a, int b) {
    if (a == 0 || b == 0) return 0;
    if (a == INT_MIN || b == INT_MIN) return (a > 0) == (b > 0) ? INT_MAX : INT_MIN;
    if (a == INT_MAX || b == INT_MAX) return INT_MAX;
    return satMul(a, b);
}

std::string envText(const IvEnv &env, const std::set<std::string> &keys) {
    std::ostringstream out;
    bool first = true;
    for (const std::string &k : keys) {
        if (!first) out << " ";
        out << k << "=" << ivText(env.count(k) ? env.at(k) : Iv{1, 0});
        first = false;
    }
    return out.str();
}

}  // namespace

Lattice<Iv> ivLattice() {
    return Lattice<Iv>{
        Iv{INT_MIN, INT_MAX},  // 顶：全区间（什么信息都没有）
        Iv{1, 0},              // 底：lo>hi 编码 ⊥（不可达）
        [](const Iv &a, const Iv &b) { return a.lo == b.lo && a.hi == b.hi; },
        [](const Iv &a, const Iv &b) {
            if (a.lo > a.hi) return true;   // ⊥ ⊑ 一切
            if (b.lo > b.hi) return false;
            return a.lo >= b.lo && a.hi <= b.hi;  // 区间包含 = 信息更准
        },
        [](const Iv &a, const Iv &b) {
            if (a.lo > a.hi) return b;
            if (b.lo > b.hi) return a;
            return Iv{std::min(a.lo, b.lo), std::max(a.hi, b.hi)};  // 包络
        }};
}

std::string ivText(const Iv &v) {
    if (v.lo > v.hi) return "bottom";
    std::ostringstream out;
    out << "[";
    if (v.lo == INT_MIN)
        out << "-inf";
    else
        out << v.lo;
    out << ",";
    if (v.hi == INT_MAX)
        out << "+inf";
    else
        out << v.hi;
    out << "]";
    return out.str();
}

Iv evalIv(const Expr *e, const IvEnv &env) {
    Lattice<Iv> lat = ivLattice();
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        return Iv{x->v, x->v};
    }
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        if (it == env.end()) return lat.bot();  // 没有区间信息 → ⊥（不可达路径近似）
        return it->second;
    }
    if (dynamic_cast<const InputE *>(e)) {
        return Iv{INT_MIN, INT_MAX};  // 任意整数
    }
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        Iv l = evalIv(x->l.get(), env);
        Iv r = evalIv(x->r.get(), env);
        if (l.lo > l.hi || r.lo > r.hi) return lat.bot();
        // 除法端点含 0 时商可爆掉，直接保守取全区间。
        if (x->op == BOp::Div) {
            if (r.lo <= 0 && r.hi >= 0) return Iv{INT_MIN, INT_MAX};
            // 非零除数也只对"两个都是常量"给出精确端点，其余取全区间。
            if (l.lo == l.hi && r.lo == r.hi)
                return Iv{std::min(l.lo / r.lo, l.hi / r.lo),
                          std::max(l.lo / r.lo, l.hi / r.lo)};
            return Iv{INT_MIN, INT_MAX};
        }
        if (x->op == BOp::Add)
            return Iv{satAdd(l.lo, r.lo), satAdd(l.hi, r.hi)};
        if (x->op == BOp::Sub)
            return Iv{satAdd(l.lo, -static_cast<long long>(r.hi)),
                      satAdd(l.hi, -static_cast<long long>(r.lo))};
        if (x->op == BOp::Mul) {
            int los[4] = {mulLo(l.lo, r.lo), mulLo(l.lo, r.hi),
                          mulLo(l.hi, r.lo), mulLo(l.hi, r.hi)};
            int his[4] = {mulHi(l.lo, r.lo), mulHi(l.lo, r.hi),
                          mulHi(l.hi, r.lo), mulHi(l.hi, r.hi)};
            return Iv{*std::min_element(los, los + 4),
                      *std::max_element(his, his + 4)};
        }
        return Iv{INT_MIN, INT_MAX};  // 比较/其余：只给真假信息，这里不精炼
    }
    return Iv{INT_MIN, INT_MAX};
}

NaiveResult runNaiveInterval(const Cfg &cfg, const ProgramA &program,
                             int maxRounds) {
    Lattice<Iv> lat = ivLattice();
    NaiveResult res;

    // 找循环头：第一条 while 语句所在节点（演示程序单函数单循环）。
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (dynamic_cast<const WhileS *>(node.stmt) && res.headNode < 0)
                res.headNode = id;

    const FunCfg &fc = cfg.funs[0];
    std::map<int, std::vector<int>> preds;
    for (const auto &[a, b] : fc.edges) preds[b].push_back(a);

    // 声明的变量集合（循环头打印环境用）。
    std::set<std::string> vars(program.funs[0]->vars.begin(),
                               program.funs[0]->vars.end());

    // 朴素迭代：round-robin 按节点号顺序重算每个点，封顶 maxRounds 轮。
    std::map<int, IvEnv> out;
    for (int round = 0; round < maxRounds; ++round) {
        bool changed = false;
        for (const auto &[id, node] : fc.nodes) {
            IvEnv in;
            auto pit = preds.find(id);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    const IvEnv &qs = out[q];
                    for (const auto &[k, v] : qs)
                        in[k] = lat.join(in.count(k) ? in[k] : lat.bot(), v);
                }
            }
            // entry 边界：参数视为全区间（此处演示程序无参）。
            for (const std::string &p : program.funs[0]->params)
                in[p] = lat.join(in.count(p) ? in[p] : lat.bot(),
                                 Iv{INT_MIN, INT_MAX});

            IvEnv o = in;
            if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
                if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                    o[t->name] = evalIv(a->value.get(), in);
            if (out.count(id) == 0 || !(out[id] == o)) {
                out[id] = o;
                changed = true;
            }
        }
        res.rounds = round + 1;
        if (res.headNode >= 0) {
            std::ostringstream line;
            line << "iter " << round << ": "
                 << envText(out.count(res.headNode) ? out[res.headNode] : IvEnv{},
                            vars);
            res.trace.push_back(line.str());
        }
        if (!changed) {
            res.converged = true;
            break;
        }
    }
    return res;
}

}  // namespace tip
```

### 37.11.14 main.cpp：命令行入口与输出组装

main 与前几章保持同一形状：--check 解析文件、构建 CFG、调用求解器，
然后按固定格式打印标题、循环头、逐轮轨迹与收敛结论。退出码约定不变：
1 为用法或文件错误，2 为语法错误，3 为语义错误，0 为成功。注意未收敛
时退出码仍是 0——"迭代到上限仍不收敛"对本演示程序是预期内的结果而非
运行错误，DID NOT CONVERGE 文本本身就是交付物；第 38 章修复后，--check
应在同一程序上报告 CONVERGED，读者可用这一行的变化确认 widening 的
效果。

```cpp
// file: src/main.cpp
// 第 37 章配套程序：区间格 + 朴素迭代的不终止演示。
//   --check FILE : 打印每轮朴素迭代在循环头的区间环境，封顶 50 轮；
//                  未收敛时打印 DID NOT CONVERGE（这正是第 38 章 widening 的动机）
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "interval.hpp"
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

    const int maxRounds = 50;
    tip::NaiveResult r = tip::runNaiveInterval(cfg, *p.ast, maxRounds);

    std::cout << "== interval lattice, naive iteration (cap " << maxRounds
              << " rounds) ==\n";
    std::cout << "loop head: node " << r.headNode << "\n";
    for (const std::string &line : r.trace) std::cout << line << "\n";
    if (r.converged)
        std::cout << "CONVERGED after " << r.rounds << " rounds\n";
    else
        std::cout << "DID NOT CONVERGE after " << r.rounds
                  << " rounds: chain [1,1] <= [1,2] <= [1,3] <= ... has no end\n";
    return 0;
}
```

### 37.11.15 expected/output.txt：一次真实运行的逐字记录

最后嵌入的是测试对账用的期望输出：首行 == loop.tip == 由测试框架在
调用 --check 前添加，随后是 50 条 iter 轨迹与未收敛结论。这不是手工
编写的"理想答案"，而是程序真实运行的重定向结果；check_example 会重新
运行并逐字节比较。读这份文件时建议把注意力放在三段：开头确定循环头、
中段确认 iter k 的线性增长规律（抽查若干行即可，50 行形状完全一致）、
结尾的未收敛声明。第 38 章的对应文件将在同一个程序上变成有限几行的
CONVERGED——两份 expected 并排，就是"无限高度问题"与"widening 解"最
直接的对照。

```
; expected: expected/output.txt
== loop.tip ==
== interval lattice, naive iteration (cap 50 rounds) ==
loop head: node 3
iter 0: x=[1,1]
iter 1: x=[1,2]
iter 2: x=[1,3]
iter 3: x=[1,4]
iter 4: x=[1,5]
iter 5: x=[1,6]
iter 6: x=[1,7]
iter 7: x=[1,8]
iter 8: x=[1,9]
iter 9: x=[1,10]
iter 10: x=[1,11]
iter 11: x=[1,12]
iter 12: x=[1,13]
iter 13: x=[1,14]
iter 14: x=[1,15]
iter 15: x=[1,16]
iter 16: x=[1,17]
iter 17: x=[1,18]
iter 18: x=[1,19]
iter 19: x=[1,20]
iter 20: x=[1,21]
iter 21: x=[1,22]
iter 22: x=[1,23]
iter 23: x=[1,24]
iter 24: x=[1,25]
iter 25: x=[1,26]
iter 26: x=[1,27]
iter 27: x=[1,28]
iter 28: x=[1,29]
iter 29: x=[1,30]
iter 30: x=[1,31]
iter 31: x=[1,32]
iter 32: x=[1,33]
iter 33: x=[1,34]
iter 34: x=[1,35]
iter 35: x=[1,36]
iter 36: x=[1,37]
iter 37: x=[1,38]
iter 38: x=[1,39]
iter 39: x=[1,40]
iter 40: x=[1,41]
iter 41: x=[1,42]
iter 42: x=[1,43]
iter 43: x=[1,44]
iter 44: x=[1,45]
iter 45: x=[1,46]
iter 46: x=[1,47]
iter 47: x=[1,48]
iter 48: x=[1,49]
iter 49: x=[1,50]
DID NOT CONVERGE after 50 rounds: chain [1,1] <= [1,2] <= [1,3] <= ... has no end
```

## 37.12 再形式化一层：从常量格到区间格的精度阶梯

前面各节把区间格当作"新的事实集合"直接使用。这里退后一步，用第 29 章
已经准备好、第 70 章才系统展开的眼光，把区间格与具体整数集合、常量格
三者摆在一起，看清"换格"在数学上到底做了什么。这个视角也解释了：既然
区间比常量精确，为什么不直接使用"整数集合"本身作为事实，一步到位得到
完美精度。

### 37.12.1 具体化与抽象：α 与 γ 的第一次见面

任意一个区间 a 对应一批具体整数，这个对应就是**具体化函数** γ：

> γ(Iv{lo,hi}) = { n ∈ C : lo ≤ n ≤ hi }，γ(⊥) = ∅

γ 的方向是从抽象到具体：它回答"这个抽象事实允许哪些运行状态"。可靠性的
全部要求可以压缩成一句话：**抽象运算的 γ，必须包含具体运算的真实结果。**
反过来，给定一批具体整数 S（例如某次理想分析在某点算出的精确值集合），
能包含它的最窄区间称为 S 的**抽象** α：

> α(S) = Iv{ min S, max S }（S 非空）；α(∅) = ⊥

α 把一批值"压"成两个端点。注意压缩丢失了什么：S={1,3} 与 S={1,2,3}
有相同的 α，但 γ(α(S)) 对前者给出 {1,2,3}——多出来的 2 是压缩凭空
加入的"幻影值"。37.14 节会用一个完整程序把幻影值的产生手算一遍。
一般地，γ∘α 不会让集合变小（S ⊆ γ(α(S))），这是可靠性的集合论表述；
等号只在 S 本身就是区间时成立。

### 37.12.2 常量格、区间格、精确集合格的三方对照

常量格的 γ 只产生三种集合：空集（⊥）、单点集 {c}、全集 C（⊤）。区间格
的 γ 产生一切区间形状的集合。于是区间格严格地比常量格"能说"：常量格的
每一种事实都能被区间格等价表达（⊥→⊥、{c}→[c,c]、⊤→[INT_MIN,INT_MAX]），
反之，[1,100] 无法用常量格不失真地表达。代价对照也很直接：

- 常量格每变量存一个标签（加一个可能的整数）；
- 区间格每变量存两个整数；
- 若继续追求精度，允许"至多 m 个区间的有限并"，每变量要存 2m 个端点，
  join 还要做有序区间列表的合并，代价随 m 线性增长、而 m 本身可能随分析
  轮次增长；
- 极限情形是直接以 C 的幂集（一切整数子集）为事实——γ 恒等、精度完美，
  但 C 有 2³² 个元素，幂集不可枚举、方程不可计算。

这张阶梯给出的规律是：**精度不是免费的，且在到达"完美"之前计算性就已经
丧失。**静态分析的工程决策始终是在这张阶梯上选一级：事实结构多复杂、
join 多贵、能回答哪类问题。区间（两个端点）之所以成为工业界最普及的
选择，正因为它以最小的结构增量（单值 → 两端）跨越了"只知道唯一值"与
"知道值域"的鸿沟。

### 37.12.3 为什么区间 join"恰好不损失更多"

第 33 章的幂集 join 是集合之并；区间 join 是包络。两者关系值得写明：
对任意两个区间 a、b，

> γ(a ⊔ b) = γ(a) ∪ γ(b)

两个区间之并若不是区间（例如 [1,2] ∪ [4,5]），等式仍成立吗？成立——
包络 [1,5] 的 γ 是 {1,2,3,4,5}，严格大于右端之并 {1,2,4,5}。这里第一次
出现"γ 不保持 join"：抽象 join 不得不引入幻影 3，因为抽象域里不存在
"两个分离区间"这个元素。请记住这个失败发生的准确位置：它不是实现的
缺陷，而是**抽象域表达能力**的边界。第 70 章会用伽瓦伊斯连接（Galois
connection）的语言说明：当 γ 保持 join 时抽象传递函数可以做到最精确；
失去这条性质时，逐点 join（MFP）比路径合并（MOP）多出的精度损失，
全部来自这些"不得不补全的空隙"。

## 37.13 区间分析在工业编译器中的位置

本书的实验台是教学用的 TIP，但区间（范围）分析是少数在生产编译器中
几乎全线配备的数据流分析。了解它在真实工具链中的位置，有助于读者把
本章的每一个设计决策与"工业界为什么这样选"对应起来。

### 37.13.1 GCC 的 VRP 与 LLVM 的范围分析

GCC 中最接近本章的是 VRP（Value Range Propagation，值范围传播）：它沿
IR 维护每个名字的取值范围，并利用条件语句中的比较主动收窄范围（即本书
第 30、31 章的条件精炼）。VRM 维护的范围允许至多两个子区间（形如
[1,3] ∪ [5,7]），专门用来表达"非零"这类高频事实——这正是 20.12 阶梯上
"有限并"取 m=2 的折中。VRP 的结果被用于：判定分支恒真恒假（进而消去
不可达分支）、线程化跳转（jump threading）、以及为除法与内存访问排除
异常情形。LLVM 中有对应思路的 AR（Range Analysis）与 LazyValueInfo，
后者按需（lazy）在给定分支上下文里查询范围，避免全程序计算的开销。

注意一个共同的工程选择：这些分析无一例外地实现了形式的 widening——
范围在循环处不会一单位一单位地增长，而是直接跳到一组预设阈值
（0、1、代码中出现的常量、±∞）。本章的朴素迭代在工业实现中不会出现；
第 38 章的阈值 widening 才是生产级形态。先读"失败"再读"修复"的顺序
因此不是教学法上的奢侈：widening 那几个看似任意的选择，只有对照本章
无限链的形状才显得自然。

### 37.13.2 范围信息喂养哪些优化与校验

区间信息在编译器中的下游用户包括：除零检查与除法优化（除数范围排除
0 后可省去运行时检查）；不可达与恒假分支消除；机器指令选择中需要的
宽度判断（8/16/32/64 位）；高层综合（HLS）中用范围决定硬件位宽；
数组下标检查（在含数组的语言中）。各类 lint 与 bug 查找工具则把区间
用于有符号/无符号转换、移位计数、缓冲区大小等校验。TIP 没有数组与
移位，本章只演示了除零这一个出口，但同一条"两端点"信息在上述每个场景
中的用法形状一致：把一个待判定的命题（为 0？越界？宽度够吗？）翻译
成对区间端点的检查。

### 37.13.3 循环的另一条技术路线：归纳变量

对循环，工业编译器还有一条与"不动点迭代"并列的路线：识别**归纳变量**
（induction variables）——形如 i = i + c 的计数器及其线性派生量——直接
用符号表达式（初始值 + 步长 × 轮数）描述，再由目标循环的退出条件解出
轮数范围。GCC 与 LLVM 的 SCEV（Scalar Evolution）子系统即此路线。它对
规整计数循环比通用区间迭代精确（能保留符号关系），但只适用于被识别为
仿射形式的变量；通用区间分析对任意赋值都适用、不挑形状。本书第 38 章
走通用路线（widening），读者日后阅读真实编译器源码时会同时遇到两套
机制，知道它们解决同一问题的不同侧面即可。

## 37.14 合流点手算：分支程序怎样产生幻影值

37.5 节追踪了循环；这里把同一套求解器用在一个只有 if 的程序上，目的有
两个：看清"合流"这个动作在端点上具体做了什么，以及看清区间分析在什么
意义上必然说谎（幻影值）。程序是：

> main() { var x; x = 1; if (input > 0) { x = 3; } output x; return 0; }

### 37.14.1 编号与方程

编号规则不变：entry=1，x=1 为节点 2，if 分支点为节点 3，分支内 x=3 为
节点 4，output x 为节点 5，return 接在最后。边为 2→3，3→4，4→5，
3→5（条件为假时分支点直接到输出点）。关键的合流发生在节点 5：它有
两个前驱 4 与 3，两个区间在这join。

### 37.14.2 两轮迭代

第 0 轮：节点 2 给出 x=[1,1]；节点 3 收到 [1,1]；节点 4 把 x 改成
[3,3]；节点 5 这一轮只有节点 3 的值已被读取（round-robin 顺序里节点 4
刚刚算出），得到 [1,1]。

第 1 轮：节点 5 的 in 是两个前驱的 join：节点 3 给 [1,1]（条件为假的那
条路径，x 未被修改），节点 4 给 [3,3]（条件为真的路径），包络为
[1,3]。其余节点不变。一整轮无其他变化，收敛。

### 37.14.3 真值集合、结果区间与幻影 2

这个程序运行到 output 时，x 的真值集合是 {1, 3}——条件为假是 1，为真是
3，没有任何执行让 x=2。分析给出的 [1,3] 包含幻影 2。幻影从哪里来已经
可以精确指出：α 在合流点把两个集合 {1}、{3} 各压成端点，γ 还原时只能
"填满中间"。这不是算错——可靠性要求的是"真值 ⊆ 结果集合"，{1,3} ⊆
{1,2,3} 成立——而是抽象域表达力的固有账单，20.12.3 小节已经预告过。

这个小例子同时印证三件事。其一，**只有分支、没有循环的程序，迭代必然
终止**：节点数有限、每条路径只合流一次，链的长度由程序结构预先封顶；
真正制造无限链的是循环把"任意多轮"压回同一个点。其二，合流越早幻影
越多：若把分支条件的信息保留到 output 再合并（路径敏感），可以给出
{1} 或 {3} 的分流答案；MFP 在节点 5 就合并，付出幻影代价。其三，若想
消除"x 永不为 2"这类幻影，抽象域必须升级到区间的有限并（VRP 的 m=2
即用 [1,1]∪[3,3] 精确表达本例）——精度阶梯的下一级长什么样，在这个
程序上看得很具体。

## 37.15 练习参考思路

以下给出 37.9 节练习的参考思路，鼓励读者先自行推演再对照。

**练习 1。** 结合律：(a⊔b)⊔c 的下界是 min(min(la,lb),lc)=min(la,lb,lc)，
上界同理，与括号位置无关。⊥ 为单位元：⊥⊔a=a 来自 join 实现对底的
显式分支；顶不是单位元：⊤⊔a=⊤。

**练习 2。** +2 版本：iter 0 [1,1]，iter 1 由节点 4 的 [3,3] 与 [1,1] 包络
得 [1,3]，iter 2 得 [1,5]；通式 iter k: x=[1,2k+1]。初值 x=3 时通式变为
[3, 2k+3]。要点：步长改变链中相邻元素的差距，但链仍然无限，不终止的
结论不变。

**练习 3。** 同号时 xy 在矩形上对两个变量分别单调（同正同向、同负对
x、y 各反向），极值在角上；异号时单调性按象限翻转，四角仍涵盖极值
（内部无驻点），结论依然成立——这正是穷举四个端点无需先判符号的原因。

**练习 4。** 可靠性命题：除数区间排除 0 后，每个端点组合的截断商都
有限；真实商是连续选取分子、分母的结果，截断除法在固定符号的矩形上
极值在边界取得。实现：四组合各算 long long 除法、钳位、取 min/max。
与第 39 章对照时注意 22 章还处理了哨兵除数（按真实 INT_MIN/MAX 参与
除法）。

**练习 5。** ⊥ 在迭代中是"尚无值"的起点，⊤ 是"可达但任意"的宽事实。
若起点误为 ⊤：节点 2 的赋值仍会改写成 [1,1]（赋值传递会覆盖），追踪
从 iter 0 起看起来相同；但任何**不被赋值覆盖就合流**的点都会一直为 ⊤
不再收窄——底与顶的根本区别是 join 行为：⊥ 被任何事实吸收，⊤ 吸收
一切。

**练习 6。** 长度约 INT_MAX = 2³¹−1；1 毫秒/轮约 24.8 天。说明有限高度
若高度不可使用，工程上等同无限——这是 widening 的现实理由。

**练习 7。** 方案一：区间有限并（有序、互不相邻的区间列表），join 为
列表合并后吞并相邻区间，精确但要维护列表形状。方案二：在环境里并列一个
"非零"布尔事实格（{⊥,true}），join 为逻辑与/或的单调组合，便宜但只能
表达预设事实。实践中两者常并存（VRP 即区间并为主、谓词事实为辅）。

## 37.16 常见问题

**问：为什么不直接记录"变量可能取的所有值"的集合？**
答：20.12.2 的阶梯——有限机器上集合可达 2³² 规模，join 与存储都不可行；
更根本的是含输入的程序中这个集合本就是无限的（ℤ 语义），无法枚举。

**问：[INT_MIN,5] 到底是"−∞ 到 5"还是"INT_MIN 到 5"？**
答：在 32 位具体域上两种读法的外延相同：小于 INT_MIN 的整数不存在。
证明按 ℤ 叙述时读成 −∞，实现按真实哨兵存储与计算；20.2.3 已核对。

**问：饱和钳位为什么不会漏掉真实的溢出结果？**
答：钳位不保证重现回绕值，保证的是结果区间包含"可能溢出"这一情形；
真实回绕值是某个具体整数，而溢出情形下结果区间已放宽到哨兵端（全集
类型的描述），成员包含成立。需要精确回绕语义时要另行建模。

**问：未收敛为什么退出码还是 0？**
答：对本演示，50 轮不收敛是预期交付物、不是运行失败；标题文本
DID NOT CONVERGE 是明确信号。若把未收敛当错误，自动化测试反而无法把
"正确地演示了问题"与真正的崩溃区分开。

**问：区间分析说 [1,3]，但 x 实际只会是 1 或 3，这不是错吗？**
答：这是精度损失（幻影 2）不是可靠性错误；静态分析保证真值 ⊆ 预测集合，
不保证反向。要消除幻影需升级抽象域（区间的并），见 20.14。

**问：output 点出现 ⊥ 说明什么？**
答：该点在当前迭代里还没有任何一条已处理路径到达——可能只是前驱尚未
传播（迭代中间状态），若收敛后仍为 ⊥ 才可断言"点不可达"。两者必须按
是否收敛区分。

**问：条件是 input>0、真假完全不知，分析为什么还能可靠？**
答：求解器不试图判定条件，让两条出边都参与合流；未知条件下两支都可能
发生，保留两支正可靠。草率剪掉某一支才会系统性漏路径。

**问：round-robin 和 worklist 到底该用哪个？**
答：终止性与正确性相同；worklist 只重算受影响点、效率高，round-robin
轮次语义清晰、便于教学追踪。生产实现用 worklist 及其变体。

**问：为什么上限选 50？**
答：仅为让输出可读且足够展示规律；任何固定上限都不改变结论。生产分析
的上限通常按"更新次数 × 节点数"设置，并在触发时报未收敛。

**问：除法一律退顶会不会太浪费？**
答：本章有意如此，以隔离主题；第 39 章偿还。可靠性论证中"退顶"永远
合法（顶包含一切），因此保守化是随时可用、但需记账的手段。

**问："x 非零"为什么不能用一个区间表达？**
答：非零集合在 0 处断开，是两个区间之并；单区间若要包含 −1 与 1 就
必然包含 0。要么升级到区间并，要么加独立谓词事实。

**问：区间分析能证明循环终止吗？**
答：不能。区间只描述值集合，不含"轮数有限"的判断；事实上 loop.tip 的
循环可因无限输入而任意长。终止性需要独立的秩函数（ranking function）
类分析。

**问：乘以 0 与 ±∞ 端点怎么处理？**
答：具体 0 乘任何值都为 0，且极限情形 0·∞ 在分析意图上取 0（结果恒
为 0，与另一因子无关）；实现的 mulLo/mulHi 先判 0 即此规则。

**问：−INT_MIN 为什么是高危写法？**
答：−INT_MIN 在 int 中溢出回绕（仍为 INT_MIN）；抽象与具体实现都应先
转 long long 再取负。减法右端点公式里用的就是 long long。

**问：比较运算在本章返回顶，信息不是白丢了？**
答：表达式层面的"比较值"用处有限，真正的价值在分支边上（成立时如何
收窄操作数）；第 30、31 章在边上利用它，比在表达式上给 [0,1] 有用得多。

## 37.17 术语对照

- Interval lattice / 区间格：以 [lo,hi] 为元素的值域抽象。
- Sentinel / 哨兵：兼任 ±∞ 的 INT_MIN、INT_MAX。
- Saturating arithmetic / 饱和运算：越界即钳到边界而非回绕。
- Envelope / 包络：多区间 join 的 (min lo, max hi)。
- ACC（Ascending Chain Condition）/ 上升链条件：任意严格上升链有限；
  区间格在 ℤ 上不满足。
- Phantom value / 幻影值：γ(α(S))∖S 中凭空多出的元素，如合流后出现的 2。
- MOP vs MFP：沿路径合并（精确、不可计算）与逐点不动点（可计算、较宽）。
- VRP / SCEV：GCC 的值范围传播与归纳变量符号演化，对应本章与另一条
  循环分析路线。

## 37.18 第二个工作示例：绝对值程序上的两章对照

本节把同一套求解器用在一个新程序上，重点从"迭代为什么不停"转向"精度
在哪里损失、第 39 章将如何偿还"。程序是：

> main() {
>   var x, y;
>   x = input;
>   if (x > 0) { y = x; } else { y = 0 - x; }
>   output y;
>   return 0;
> }

这是一个手写的绝对值函数：条件为真时 y=x（正数），为假时 y=−x（非负数）。
具体执行到 output 时 y 的真值集合是 {0,1,2,…}。

### 37.18.1 CFG 与本章求解器的结果

编号：entry=1；x=input 为 2；if 分支点为 3；分支内 y=x 为 4；else 分支
y=0−x 为 5；output y 为 6；return 接在最后。边为 2→3，3→4→6，3→5→6。
节点 6 是合流点。

按本章（无条件精炼）的方程推演：节点 2 把 x 绑为顶 [INT_MIN,INT_MAX]。
节点 4 中 y=x，evalIv 给顶；节点 5 中 y=0−x，从顶减出顶。合流点 6 的
join 仍是顶。于是分析对 output y 的预测是 (−∞,+∞)——可靠但贫瘠：它甚至
没能说出"y 不会为负"。

### 37.18.2 损失发生在准确的位置

贫瘠的根源不在 join（两支合流并没有引入比顶更宽的东西），而在**分支边
上没有利用条件**。具体地：沿 3→4（条件成立）这条边，x>0 已被保证，x
应当被收窄成 [1,+∞]；沿 3→5（条件不成立）这条边，x≤0，−x 即 [0,+∞]。
合流后本应得到 [0,+∞]。要做到这一点，事实必须在边上做条件精炼，而
CFG 的边在数据结构里没有 true/false 标记、我们的 CFG 又自第 14 章起冻结；
第 30、31 章将用"在求解器内部恢复分支信息"的方式补上。

这个例子的教学价值是把三类机制的分工显形：**区间运算**负责"值集合怎么
算"，**条件精炼**负责"控制流事实怎么改变值集合"，**widening** 负责"无限
高度怎么收敛"。本章只具备第一类，因此对绝对值程序只能给顶；第 39 章
三类齐备后，同一程序的 output 将精确为 [0,+∞]。读者可把这两章在该程序
上的 expected 输出直接对比。

### 37.18.3 若把程序改回直线代码

把程序改成不含分支的直线版本（x=input; y=x; output y），分析同样给顶，
但这里的顶是**精确**的结论：输入任意、直接传递，y 的真值集合就是全集。
对比可见：同样一个"顶"，可能是"信息不足的保守"（绝对值程序），也可能
是"真值集合本就如此"（直线传递）。读分析结果时必须结合程序结构区分这
两种顶——这也是为什么本书坚持输出要带上程序点与语句、而不能只看区间。

## 37.19 乘法的端点分类：为什么四个角总是够

20.3.3 小节声称穷举四个端点组合即可得到乘法的可靠区间，本节把背后的
分类补全，使读者能独立验证这一结论，而不是记住一个口号。

### 37.19.1 按符号的四种情形

设左区间 [la,ha]、右区间 [lb,hb]，均为有限端点（哨兵情形见 20.19.2）。

- 两个区间都为非负：xy 对 x、y 都单调增，最小积 la·lb、最大积 ha·hb；
- 两个区间都为非正：xy 对两个变量都单调减，乘积为正，最小积（最小的
  正数）ha·hb，最大积 la·lb（两个最负数的积最大）；
- 左非正、右非负：xy 对 x 单调减、对 y 单调增，最小积 la·hb，最大积
  ha·lb；
- 左非负、右非正：最小积 ha·lb，最大积 la·hb。

四种情形各给出两个对角的端点组合；而实现不判符号、直接计算全部四角
{la,ha}×{lb,hb} 再取 min/max，等价于"让符号情形自己竞争"——错误符号
配对的积不会成为极值，枚举成本固定为四次乘法。这是一个通用技巧：**当
按情形分类的成本高于穷举、且组合数有小的常数上界时，穷举端点比分类
更简单可靠**；它同时免去了"区间跨零属于哪一类"的麻烦——跨零区间同时
触及正负，四角中的两个对角（负×正、正×负）会自动给出负值与正值极值。

### 37.19.2 含 0 与含哨兵的情形

含 0 的处理规则：若某一区间包含 0，则四角中有组合取到 0；0 是积的一个
候选极值（当其他组合符号混合时，0 既可能成为上界也可能成为下界）。
因此实现的 mulLo/mulHi 先判 0 是保守且必要的：例如左区间 [0,ha] 全
非负、右区间跨零，最小积为 0，漏掉 0 候选会给出错误的正下界。

含哨兵（±∞ 意图）的情形不能真的把 INT_MAX 相乘后在 int 内比较：实现
先按 64 位乘积计算有限端，对真正的哨兵组合按极限符号给无穷：x→+∞、
y→−∞ 时 xy→−∞。一个特例在 20.16 已述——乘以具体 0 恒为 0，即使另一
端是无穷意图；这与"极限的乘积"在数学上的不定式不同，但从程序语义看
0·任何机器值都为 0，分析按 0 处理既可靠又精确。

### 37.19.3 一个核对练习的答案形状

以 [−2,3] × [4,5] 为例，四角积为 −8、−10、12、15，结果区间 [−10,15]。
用 20.19.1 的分类（左跨零），负值极值由最负左端与最大右端取得
(−2·5=−10)，正值极值由最大左端与最大右端取得 (3·5=15)，与穷举一致。
读者可自行构造 [−3,−1]×[−6,−4]：四角 18、12、6、4，结果 [4,18]——
负负得正区间，顺序与直觉相反，正是这类例子最值得亲手算一遍的原因。

## 37.20 历史脉络与延伸阅读

区间作为静态分析事实的历史与抽象解释框架本身一样长。Patrick 与 Radhia
Cousot 在 1977 年的论文《Abstract Interpretation: A Unified Lattice Model
for Static Analysis of Programs by Construction or Approximation of
Fixpoints》中，把静态分析统一定义为对具体语义不动点的近似构造，区间
是其中最自然的抽象域示例；同期 William Harrison 的工作已将范围分析用于
编译器优化。本书 spa.pdf 第 4 章对格与单调框架的介绍，是这套理论的
教科书化叙述。

本章刻意停在"可靠的区间运算 + 朴素迭代失败"，没有提前引入第 38 章的
widening——尽管 Cousot 的 widening 概念与抽象解释同时诞生。这样的顺序
保留了"问题先于工具"的历史与逻辑次序：widening 在 1970 年代的论文中
也是作为"Kleene 迭代在无限高度格上失效"的直接回应提出，而不是凭空
设计的算子。希望深入理论的读者可在读完第 47、48 章后回看 Cousot 的
原始论文；那时本章的每一个现象（ACC 失效、γ 不保持 join、极限点）都
会在伽瓦伊斯连接的语言中重新出现一次。

## 37.21 自测二十题

以下题目用于快速检验是否掌握本章，建议先作答再看每题后括注中的要点。

1. 区间格的顶与底分别用什么编码？（顶 [INT_MIN,INT_MAX]；底 lo>hi）
2. 为什么不用单独的 bool 字段编码底？（合法数对一一对应、⊥ 统一处理）
3. ⊑ 用端点怎么写？（lb≤la 且 ha≤hb，越窄越小）
4. join 为什么是"包络"？（包含两者的最窄区间）
5. 哨兵为什么能兼任无穷？（小于 INT_MIN 的具体整数不存在，外延相同）
6. 溢出情形为何钳位而非回绕？（回绕破坏包含，钳位保持单调扩大）
7. 加减法极值为什么在端点？（运算对两操作数单调）
8. 乘法为什么穷举四角？（矩形内部无驻点，极值在边界）
9. 除数含 0 时为何退顶？（商可能不存在或绝对值任意大）
10. input 求成什么区间？（顶）
11. 比较运算本章如何处理？（退顶，信息留给分支边）
12. round-robin 的一轮指什么？（按编号把全部点重算一遍）
13. 停机条件是什么？（一整轮无变化）
14. loop.tip 的循环头是几号节点？（3）
15. iter k 的通式？（x=[1,k+1]）
16. 第 31 章终止证明的哪条前提失效？（高度有限，即 ACC）
17. Tarski 在本章保证什么、不保证什么？（不动点存在；不保证有限迭代可达）
18. 可靠性论证分哪三层？（运算局部可靠、传递单调、不动点对执行可靠）
19. 什么是幻影值？（γ(α(S))∖S，如 {1,3} 合流后出现的 2）
20. 未收敛的中间结果能称为分析答案吗？（不能，只能称迭代轨迹）

## 37.22 50 轮输出的全景解读

expected 文件中 50 条轨迹形状一致，不必逐行阅读；本节给出一种分组读法，
使读者抽查任意一行都能立刻确认它是否正确，也为第 38 章对比输出做准备。

### 37.22.1 三个固定成分

每行轨迹 `iter k: x=[1,k+1]` 含三个固定成分。iter 的编号即轮数，与"循环
携带信息回流的次数"对应；变量名 x 是 envText 按声明变量集合输出的列，
本例只有一列，若函数声明多个变量，每轮行会并列多列、列顺序按名字固定；
区间右端 k+1 是唯一随轮数变化的成分，来自 37.5 节归纳的每轮 +1。

### 37.22.2 按十位分组的抽查

第 0–9 行：右端从 1 走到 10。这一组对应"循环至多转 9 轮"的信息已全部
枚举——第 k 轮的区间恰好包含循环实际转 0 至 k 轮时 x 的全部取值。
第 25–35 行：右端 11 到 20，形状与第一组完全平行，说明迭代进入"纯粹
线性外推"阶段：没有新的语法结构参与（循环体每轮的作用相同），只是端点
被同一条规则不断推开。第 37–70、38–51、49–63 三组同样平行。抽查时只需
确认每组首行衔接（如 iter 10 接 iter 9 后右端恰好 +1）与末行数值即可。

### 37.22.3 这条链在数学上的两个读法

读为 ℤ 上的链：它无限延伸、上确界 [1,+∞] 在第 ω 个位置，需要超限步骤
取得。读为 int32 上的链：它在右端 INT_MAX 处终止，长度 2³¹−1，第 38 章
widening 后输出将直接是有限几行（循环头 [1,+∞]、output [1,+∞]、
CONVERGED）。两份文件并排时注意：widening 不是"算出了链上更远的元素"，
而是**跳过链上的元素**——它在少数几步内走到一个可靠（包含最小不动点）但
可能更宽的点，再由 narrowing 向下修正。本章链的线性形状因此是第 38 章
一切跳跃的参照系。

## 37.23 十个容易出错的认识

以下辨析针对初次接触区间分析时最常见的混淆，每条先指出错误认识，再给
正确表述。

**其一，"区间分析就是估个大概，不需要严格证明。"** 错误。抽象值的每一步
运算都要满足成员包含；"大概"指精度可损失，不指可靠性可商量。没有可靠
性论证的范围估计只是猜数。

**其二，"底和顶都表示不知道，可以互换。"** 错误。⊥ 是否定存在（不可达、
无信息），⊤ 是承认存在但放弃描述；二者 join 行为相反，互换会在合流点
产生系统性错误。

**其三，"格是有限高度的，因为 int 是 32 位。"** 形式上成立、工程上不成立。
高度 2³¹ 量级不可使用；分析理论按 ℤ 叙述时更是无限。第 38 章的必要性不
依赖这个文字之争。

**其四，"迭代没收敛，把最后一轮结果拿来用应该差不多。"** 危险。最后一轮
不是不动点，后继节点可能尚未反映最新合流；37.7 节第三层的归纳依赖方程
在每个点成立。未收敛结果只能内部参考，不能对外声称。

**其五，"乘法要先判断区间正负才能算。"** 不需要。四角穷举让符号情形
自动竞争；先分类反而要处理跨零区间的归属。分类（20.19）用于理解，穷举
用于实现。

**其六，"除法退顶说明分析器什么都没做。"** 它做了可靠的决定：承认无法
给出有限范围。退顶是合法事实、且不阻断其他变量的分析；精度债有明确的
偿还章节。

**其七，"条件真假未知时循环分析不了。"** 正相反：未知条件让两支都保留，
分析覆盖全部轮次；试图判定不可知条件才是漏路径的开端。

**其八，"[1,3] 包含 2，所以分析是错的。"** 可靠性只要求单向包含。称其为
错误是把"精确"与"可靠"混为一谈；幻影值是表达力的账单，可以用更丰富的域
减少、用幂集消除但不可计算。

**其九，"worklist 比 round-robin 好，所以本章用 round-robin 是落后。"**
两者求解的是同一个解、终止性相同；本章需要"轮"在输出里清晰可核对。
生产实现普遍 worklist，是效率选择而非正确性差异。

**其十，"区间能回答关于变量的一切值域问题。"** 不能。离散事实（非零、
奇偶、只能取某几个值）超出单区间表达；需要区间并、同余格或谓词域。
知道区间域的边界与知道它的能力同样重要。

## 37.24 本章对后续章节导出的接口

本章代码虽是教学快照，但第 30、31 章直接在其文件之上扩展；这里把"哪些
名字被后续复用、各自的契约是什么"集中列出，方便读者在后续章节中识别
"这是旧约定"与"这是新增"。

- Iv{lo,hi} 与相等判定：区间元素的表示与编码规则在后续两章原样保留
  （哨兵、lo>hi），不引入新的编码。
- ivLattice()：格的五成分不变；第 38 章的 widen/narrow 不属于格接口，
  在求解器层面另设。
- ivText：区间显示规则（-inf/+inf/bottom）在第 30、31 章输出中沿用。
- IvEnv（变量→区间）与缺键即 ⊥：环境表示不变。
- evalIv：第 39 章仅升级除法分支（除数排除 0 时按端点组合给截断商
  包络），其余运算规则不变；升级必须保持 37.7 节第一层的局部可靠命题。
- 程序点编号与前驱表构造：第 30、31 章的求解器沿用编号规则，并在内部
  恢复 CFG 边缺失的 true/false 信息（通过复现编号逻辑），不修改 cfg 文件。
- NaiveResult 的轨迹思想被第 38 章的 WidenedResult 取代：同样记录循环
  头与轮数，但收敛标志应在有限轮内变为真。

契约之外还有一条方法论的传递：**每一次精度升级先写可靠性命题、再写实现、
最后用真实执行（--verify-soundness）实测**。第 38 章起每个章节都维持这一
节奏；本章是它第一次完整演示的地方——包括"未收敛不得声称可靠"这条否定
性纪律。

## 37.25 三个小程序的预测：把规则再用三遍

本节用三个更小的程序把本章规则独立应用三次，每个案例都给出"本章结果"与
"后续章节结果"的对照，读者可借此检验自己能否在不看 37.5 节的情况下独立
推演。

### 37.25.1 案例一：分支内输出

程序：

> main() { var x; x = input; if (x > 10) { output x; } return 0; }

output 语句在条件成立的分支内。CFG 上该输出点只有一个前驱（分支点的
true 边），本章求解器不区分边的真假，只按前驱环境给值：x 在节点 2 被绑
为顶，所以 output x 的预测是顶。这个预测可靠（真实执行到该点时 x 可以是
任意大于 10 的整数，集合确实无界），但可以精确得多——沿 true 边条件
x>10 已成立，第 39 章精炼后预测为 [11,+∞]。注意本例没有循环、迭代必然
收敛；精度损失的唯一来源是边信息，与无限高度无关。这个区分再次说明：
**收敛性问题（第 38 章）与精度问题（第 39 章）即使在同一分析里也是两个
独立维度。**

### 37.25.2 案例二：区间分析算出常量

程序：

> main() { var x, y; x = 5; y = x * 3; output y; return 0; }

直线代码。节点 x=5 给 [5,5]；y=x*3 中 evalIv 对两个单点区间走乘法：
四角皆为 15，结果 [15,15]；output 预测 15。这个案例的意义是确认区间分析
**包含**常量传播的能力：凡常量格能确定的值，区间格以单点区间同样确定，
而且在同一轮内完成、不需要额外机制。反过来常量格对本章 loop.tip 只会
给 ⊤，区间格能给 [1,k+1] 的中间形状——这就是 20.12.2 阶梯上"区间严格更
能说"的最小证据。

### 37.25.3 案例三：递减循环的镜像链

程序：

> main() { var x; x = 10; while (input > 0) { x = x - 1; } output x; return 0; }

它是 loop.tip 的递减镜像：每轮 x 减一，循环可转任意多轮，循环头的真值
集合 (−∞,10]。手算：iter 0 循环头 [10,10]，循环体算出 [9,9]；iter 1 合流
得 [9,10]；iter 2 得 [8,10]。归纳地 iter k: x=[10−k,10]，又是一条无限严格
链，只是这次是下界不断下降。朴素迭代同样不终止；第 38 章 widening 在
循环头将直接给出 [−∞,10]。

对比递增与递减两条链值得写一句：它们是区间格上方向相反、结构相同的无限
链，widening 对两端的处理因此必须对称（下界取不大于当前值的阈值、上界
取不小于当前值的阈值）。本章把两个方向都演出来，第 38 章引入阈值时读者
就不会误以为 widening 只针对"越界增长"。

### 37.25.4 三个案例的共同读法

三个案例的预测可归为三类：精确单点（案例二）、可靠的顶（案例一、三的
朴素形式）、以及无限链的中间元素（案例三每轮轨迹）。本章希望读者建立的
习惯是：拿到任何一个输出区间，先问三个问题——该点的前驱是谁、合流是否
发生、附近有无循环头；这三个问题决定了区间是"精确结论""保守结论"还是
"未完成的轨迹"。能把输出这样归类，比记住任何一条具体公式都更接近真实
分析工作的日常。

## 37.26 关键命题的证明骨架

本节把散见全章的三个核心命题的证明骨架完整写出，供希望动手做形式化
论证的读者参考。证明只用序、集合包含与归纳，不引入新概念。

### 37.26.1 命题一：evalIv 对环境单调

**命题。** 对任意表达式 e 与环境 S₁、S₂，若 S₁ ⊑ S₂（每个变量在 S₁ 的
区间包含于其在 S₂ 的区间），则 evalIv(e,S₁) ⊑ evalIv(e,S₂)。

**证明骨架，按 e 的结构归纳。** 字面量与 input 的结果不依赖环境，两边
相同。变量情形即假设本身。二元运算情形：由归纳假设，左子式结果 a₁ ⊑
a₂、右子式结果 b₁ ⊑ b₂；区间运算（加、减、乘的端点函数）对其区间参数
单调——端点的包络随输入区间扩大只向外移动——因此 op(a₁,b₁) ⊑
op(a₂,b₂)。退顶分支（除法含零、比较）两边同为顶。证毕。这个命题是
赋值传递单调、进而不动点存在的关键一环；它之所以成立，根源是 37.3 节
选取的每条运算规则都是"向外包络"而非"向内猜测"。

### 37.26.2 命题二：运算的局部可靠

**命题。** 若具体整数 n ∈ γ(a)、m ∈ γ(b)，且具体运算 n op m 有定义，
则 n op m ∈ γ(evalIv(op,a,b))（退顶分支下右端为全集，平凡成立）。

**证明骨架。** 加法：n ≥ a.lo、m ≥ b.lo 故 n+m ≥ a.lo+b.lo；上界同理；
γ 的端点按 sat 计算，而 n+m 是真实机器结果、其值必在 [INT_MIN,INT_MAX]
或发生溢出——不溢出时落在端点之间；溢出时 sat 结果为对应哨兵、该端点
在 ℤ 读法上包含一切趋向该侧的值，命题按"溢出情形归入无界端"成立。减法
相同，注意右端点交换。乘法：(n,m) 位于矩形 γ(a)×γ(b) 内；xy 在矩形上
的极值在四角（内部无驻点；含零边时零为候选，实现已纳入），故 n·m
不小于四角积的最小值、不大于最大值。除法在本章按三种退顶/单点规则
处理：含零退顶（商不存在的情形不要求、存在的情形属于全集）、单点精确、
其余退顶。证毕。

命题中"商不存在的情形不要求"对应动态语义：除以 0 直接抛错、不会产生
一个需要被包含的后续状态；分析对这类执行的责任是在除数区间含零时*能够
指出风险*（第 39 章的告警），而不是为错误状态预测一个值。

### 37.26.3 命题三：收敛时不动点对全部执行可靠

**命题。** 若分析在每个程序点的结果构成方程的不动点，则对任意一次具体
执行，其在每个点观察到的状态被该点结果包含。

**证明骨架，对执行长度归纳。** 基始：执行入口处具体初始状态被边界条件
包含——无参平凡；有参时每个参数的具体值属于顶区间。归纳步：执行从
节点 l 的某个前驱 q 沿边 q→l 到达；由归纳假设，在 q 的状态被 out(q)
包含；l 的流入事实 in(l) 是**所有**前驱 out 的 join，故它包含 out(q)，进而
包含当前具体状态；局部可靠（命题二）给出经过传递后状态被 out(l) 包含。
边 q→l 是真实控制流的一步，CFG 构造保证它存在；归纳不断。证毕。

三个命题的依赖链条值得最后复述一次：命题一（单调）保证不动点存在并使
归纳中的传递合法；命题二（局部可靠）是归纳步唯一使用的具体事实；命题
三把二者与 CFG 的覆盖性组合成对执行的保证。而本章刻意保留的否定结论
也在此链条中有精确位置——**命题三的前提是"结果构成不动点"**；50 轮
截断处该前提不成立，因此即使前 50 轮的每个区间都正确，也不能援引命题
三。第 38 章恢复的正是这个前提；那时同一条证明将通过 --verify-soundness
获得真实执行的证据。

## 37.27 章末回顾：十八个短要点

以下要点用最短的句子重述本章，每条独立成行，可作为复习卡片。

1. 常量格只能确认唯一值。
2. 区间格回答两端：最小与最大。
3. 元素是 Iv{lo,hi}。
4. lo≤hi 时表示两端之间的全部整数。
5. lo>hi 编码底，取 Iv{1,0}。
6. 顶是 [INT_MIN,INT_MAX]。
7. 底说不可达，顶说可达但未知。
8. 序是区间包含，越窄越小。
9. join 是端点包络。
10. 哨兵兼任无穷，外延不冲突。
11. 抽象算术一律 64 位中间值。
12. 溢出钳位，绝不回绕。
13. 加减取端点对，乘取四角穷举。
14. 除法含零即退顶，本章只精确单点。
15. input 与比较在本章都给顶。
16. round-robin 每轮扫完全部节点。
17. iter k: x=[1,k+1]，链无终点。
18. ACC 失效；不动点存在但有限迭代不可达。

在进入第 38 章前，建议用自己的话把第 17 与 18 条各解释一遍：
能说清"存在"与"可达"的分别，widening 的引入就不会显得是技巧堆砌；
能指出链的无限性来自"任意多轮循环合流于同一点"，也就理解了为什么
widening 只需在循环头施加，而不必在每个程序点上干预。这两点是本章
与下一章之间真正的桥梁，其余公式都会在后续章节的反复使用中自然巩固。

## 37.28 本章符号速记

- C：32 位机器整数的具体集合。
- ℤ：数学整数，理论叙述使用的具体域。
- Iv：区间元素类型，含 lo 与 hi 两个字段。
- lo：区间左端点（下界）。
- hi：区间右端点（上界）。
- ⊥：底，表示不可达或尚无信息。
- ⊤：顶，表示可达但取值任意。
- Iv{1,0}：本章对底的具体编码。
- [INT_MIN,INT_MAX]：本章对顶的具体编码。
- INT_MIN：−2³¹，兼任 −∞ 哨兵。
- INT_MAX：2³¹−1，兼任 +∞ 哨兵。
- ⊑：偏序，本章为区间包含。
- ⊔：最小上界，本章为端点包络。
- min/max：包络两端使用的运算。
- sat：饱和钳位，越界即贴边。
- satAdd：饱和加法的实现名。
- satMul：饱和乘法的中间运算。
- mulLo：乘法下界候选的辅助函数。
- mulHi：乘法上界候选的辅助函数。
- 四角：{la,ha}×{lb,hb} 四个端点组合。
- γ：具体化，区间到具体整数集合。
- α：抽象，整数集合到最窄区间。
- 幻影值：压缩后凭空补出的元素。
- ACC：上升链条件，区间格不满足。
- Kleene 迭代：x_{n+1}=F(x_n) 的后继迭代。
- 超限迭代：在极限序数处取链上确界。
- MOP：沿路径复合再合并的精确解。
- MFP：逐点 join 的不动点解。
- IvEnv：变量名到区间的环境 map。
- 缺键即 ⊥：环境的统一缺省约定。
- round-robin：每轮扫全部点的调度。
- maxRounds：50，安全截断上限。
- NaiveResult：收敛标志、轮数、轨迹的承载结构。
- 未收敛声明：DID NOT CONVERGE。
- VRP：GCC 的值范围传播。
- SCEV：编译器的归纳变量演化子系统。
- 条件精炼：沿分支边收窄区间，第 39 章主题。
- widening：加速上升链，第 38 章主题。

到此本章的概念、形式化、实现、输出与论证已形成闭环：读者既看到了
区间格能可靠回答什么，也看到了它在什么意义上停止不前，以及后续两章
将分别从哪里接手。下一章的起点，就是这行未收敛声明；下一章的终点，
是同一个程序上一份有限长度、明确 CONVERGED 的输出。

## 37.29 结语：从"算得对"到"停得下"

本章的旅程可以用三句话收束。

第一句关于价值。
区间把静态分析从"只确认常量"带到"描述值域"。
两个端点的代价极小，能回答的问题极多。

第二句关于边界。
区间格没有有限高度。
朴素迭代沿一条无限正确的链无限前行。
不动点在极限处等待，有限计算到不了。

第三句关于下一步。
我们不改变程序、不改变格、不改变方程。
只改变上升的节奏。
让链在少数几步内跨过无限的距离。
这就是 widening。
再让到达高处的结果有限地下探。
这就是 narrowing。

第 38 章将正式构造这两个算子，
并在 loop.tip 上给出本章没能给出的输出：
循环头 [1,+∞]，
output [1,+∞]，
以及一行确定的 CONVERGED。
届时读者可以把两章并排放着读：
左边是问题，右边是解，
中间只隔着"上升节奏"这一件事。

## 37.30 进入下一章前的核对清单

读完本章后，若下列每一项都能独立完成，即可开始第 38 章。

- 默写区间格的顶、底编码与序、join 定义。
- 解释哨兵一物两用为何不损害可靠性。
- 在纸上对一个加法、一个乘法给出端点运算。
- 说明除法退顶的三条分支。
- 把 loop.tip 的前两轮迭代手算一遍。
- 写出 iter k 的通式并证明归纳步。
- 指出终止性证明失效的具体前提。
- 区分"不动点存在"与"迭代可达"。
- 说明幻影值从 α、γ 的哪一步产生。
- 解释未收敛时为何不能对外声称可靠。

这份清单没有一项要求记忆实现细节；全部要求理解机制。
若有任一项卡壳，建议回到对应小节：
前两项对应 20.2，
第三、四项对应 20.3，
第五至七项对应 20.4–20.6，
第八项对应 20.6.3，
第九、十项对应 20.12 与 20.7。
全书的章节设计允许这样按问题反向定位，
因为每一章的命题、实现与输出都在正文中被显式对照过。
