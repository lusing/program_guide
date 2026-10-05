# 第 5 章　正则表达式与自动机：把词法从黑盒里拆出来

## 5.1 问题：token 到底是从哪来的

第 4 章里我们写了 `TIP.g4`，
把字符流变成 token 流这件事
整个交给了 ANTLR。
文法里那些大写的词法规则——
`ID`、`INT`、`OP`——
ANTLR 拿到它们之后做了什么？
为什么一行
`letter (letter | digit)*`
就能变成一段真正能跑的识别程序？

本章把这只黑盒拆开。
拆完之后你会发现，
从"模式"到"程序"的整条路
只有三步，而且每一步都是算法：

1. 把模式写成**正则表达式**——一种能精确描述
   "什么样的一串字符算同一个 token"的小语言；
2. 把正则表达式机械地翻译成一台
   **非确定有限自动机**（NFA）；
3. 把 NFA 机械地翻译成一台
   **确定性有限自动机**（DFA），
   再把等价的状态合并掉，
   得到一张又小又快的转移表。

这张表就是词法分析器的全部。
ANTLR 生成的词法器、
UNIX 世界的老牌工具 LEX、
以及一切"按模式切文本"的工具，
内核都是它。
本章的材料取自
Aho 与 Ullman 的《Principles of Compiler Design》
（下文称"绿龙"，1977）第 3 章
与 Aho、Lam、Sethi、Ullman 的
《Compilers: Principles, Techniques, and Tools》
（下文称"紫龙"，2006）第 3 章——
但所有定义、算法与证明思路
都在正文里自包含地讲清，
你不需要翻回原书。

配套示例 `examples/05_regex_automata`
不依赖 ANTLR 也不依赖 LLVM：
它自己实现了
正则解析 → Thompson 构造 → 子集构造 → 最小化的
完整流水线，
并用它造出一台真正能切 TIP 程序的 scanner。

## 5.2 形式化之一：串、语言与正则表达式

### 5.2.1 从字符到语言

先把手头的名词说精确
（绿龙 3.3 节的口径）。

**字母表**（alphabet）
是任意有限个符号的集合。
`{0,1}` 是字母表，
ASCII 的 128 个字符是字母表，
TIP 源程序里允许出现的全体字符
也是一个字母表。

**串**（string）
是从字母表里取符号排成的有限序列。
串 x 的**长度** |x| 是符号个数。
有一个特殊的串：
**空串** ε，长度为 0。
两个串 x、y 的**拼接**写作 xy，
就是把 x 的符号抄完再抄 y。
拼接像乘法：
可以定义幂（x³ = xxx），
并约定 x⁰ = ε——
ε 在拼接下扮演乘法单位元的角色
（εx = xε = x）。

从一个串出发，
删掉尾部若干符号得到**前缀**，
删掉头部若干符号得到**后缀**，
两头各删一些得到**子串**。
abc 是 abcde 的前缀，
cde 是后缀，
cd 是子串但既非前缀也非后缀。

**语言**（language）
就是某个字母表上任意一批串的集合。
这个定义宽得惊人：
空集 ∅ 是语言，
{ε} 是语言，
"全体合法的 C 程序"也是语言。
注意语言不给串赋予意义——
赋予意义是第 9 章
语法制导翻译的事。

语言上的运算继承自串：

- **并**：L ∪ M，属于 L 或属于 M 的串；
- **拼接**：LM = { xy | x∈L, y∈M }；
- **星**（闭包）：
  L* = L⁰ ∪ L¹ ∪ L² ∪ …，
  即"从 L 里取串拼接任意多次"
  （含取零次，所以 ε ∈ L*）。

若想排除"零次"，
写 L(L*)，简记 L⁺——
"一次或多次"。

### 5.2.2 正则表达式：描述 token 的小语言

英语说"标识符是字母开头、
后面跟若干字母或数字"
并不难，
难的是没法从英语自动造出识别程序。
正则表达式把这个说法
压缩成可以机械加工的形态：

```
identifier = letter (letter | digit)*
```

竖线是"或"（并），
括号分组，
星是"零次或多次"。

正则表达式的**归纳定义**
（这是本章第一个要背下来的定义）：
给定字母表 Σ，

1. ε 是正则表达式，表示语言 {ε}；
2. 每个 a ∈ Σ 是正则表达式，表示 {a}；
3. 若 R、S 是正则表达式，
   分别表示 L(R)、L(S)，则
   - (R)|(S) 表示 L(R) ∪ L(S)，
   - (R)(S) 表示 L(R)L(S)，
   - (R)* 表示 L(R)*。

就这三条：
两条基础、三条归纳。
"正则"这个名字属于
被描述的那批语言——
能被正则表达式描述的语言
叫**正则语言**。

书写时按惯例省括号：
`*` 优先级最高，
拼接次之，
`|` 最低——
和"乘法高于加法"同构
（拼接确实是乘法，
并确实是加法）。

几个例子
（字母表取 {a,b}，
出自绿龙 Example 3.5）：

- `a*`：任意多个 a（含零个）；
- `(a|b)*`：a、b 组成的一切串——
  读者可自行验证 `(a*b*)*` 与它等价，
  这是正则代数律的一次小练习；
- `a|ba*`：单个 a，
  或 b 后跟任意多个 a；
- `(aa|ab|ba|bb)*`：长度为偶数的一切串。

正则运算满足一组好用的代数定律：

- 并交换、并结合；
- 拼接结合（但不交换：doghouse ≠ housedog）；
- 拼接对并分配；
- ε 是拼接的单位元。

TIP 的 token 用正则写出来
就是一小张表：
`if` 这样的关键字
是"符号串对符号串"的写死模式，
标识符是 `letter (letter | digit)*`，
整数是 `digit+`，
运算符逐个列出。
这张表正是
第 4 章 `TIP.g4` 里
那些词法规则的数学本体。

### 5.2.3 正则的边界：aⁿbⁿ 与泵引理直觉

正则表达式不是万能的。
经典反例：
{ aⁿbⁿ | n ≥ 0 }——
"先 n 个 a 再 n 个 b"。
直觉上为什么它不正则？
假设有台机器识别它。
机器只有有限个状态，
而 n 可以任意大，
所以读 a 的过程中
必有某个状态被重复经过。
把两次经过之间那段 a
（设长度为 k > 0）
"泵"出去任意多份，
机器照样走同样的状态轨迹、
照样接受——
但 a^(n+k)bⁿ 里 a 和 b 的个数
不再相等，
不属于这个语言。
矛盾。
这就是**泵引理**的直觉形态；
它的正式陈述与证明
属于自动机理论课，
这里记住结论就够：
**数数（配对计数）超出了
有限状态的能力**。

配对的括号、
嵌套的块结构、
形如 aⁿbⁿ 的对称——
这些要交给上下文无关文法，
也就是第 6、7 章
两章语法分析的主角。
词法层之所以"够用正则"，
是因为 token 内部
不存在递归配对结构：
一个标识符再长，
也只是"字母打头的扁平序列"。

## 5.3 形式化之二：有限自动机

### 5.3.1 NFA：允许"分身"的识别器

**非确定有限自动机**（NFA）
是一张带标注的有向图：

- 节点叫**状态**，
  其中一个叫**起始状态**，
  若干个叫**接受状态**；
- 边叫**转移**，
  标注字母表里的符号，
  **或 ε**；
- 同一个状态出发的多条边
  可以标同一个符号，
  也可以标 ε。

"非确定"的意思：
机器读到一个符号时
不必唯一决定去哪——
它允许所有可能同时成立。
NFA **接受**串 x，
当且仅当
**存在**一条从起始状态
到某接受状态的路径，
路径上边的标注依次拼出 x
（ε 边拼出空串，
对串没有贡献）。

绿龙的经典例子
（全书反复使用的跑龙套）：
`(a|b)*abb`——
"以 abb 结尾的一切 a/b 串"。
它的 NFA 有 11 个状态、
一堆 ε 边，
读 a 时 0 号状态
既可以留在 0、也可以跳去 1。
串 aabb 被接受，
因为存在一条
0→0→1→2→3 的路径
标注恰好是 a,a,b,b。

NFA 适合人写、人看，
但不适合机器直接跑：
"存在路径"意味着
真要判断接受与否，
得跟踪所有可能的分身，
最坏情况路径数
随串长指数增长。
下一段的 DFA
就是来收拾这个麻烦的。

### 5.3.2 DFA：每一步只有一条路

**确定性有限自动机**（DFA）
在 NFA 上加两条限制：

1. 没有 ε 转移；
2. 每个状态对每个输入符号，
   至多一条出边。

于是任何串
从起始状态出发
只有唯一一条走法，
走到哪算哪，
停在接受态就接受。
模拟一个 DFA
就是查表循环——
O(|串|) 时间、
每步一次数组访问。
词法器每秒要吞百万字符，
这个复杂度是刚需。

DFA 的表示就是一张**转移表**：
行是状态，列是符号，
格子里写目标状态。
本章示例的 `--check`
打印的就是这种表。

剩下的问题是：
NFA 好构造（下一节），
DFA 好执行（如上），
怎么从前者得到后者？
答案是子集构造（5.5 节）。
在那之前，
先把"NFA 好构造"兑现。

## 5.4 Thompson 构造：从表达式到 NFA

### 5.4.1 算法

**Thompson 构造**
（绿龙 Algorithm 3.2）
按正则表达式的语法树
自底向上拼装 NFA。
它维护一个关键**不变式**：
每个部件都有

- 恰好一个入口、一个出口；
- 没有边进入入口，
  没有边离开出口；
- 每个状态至多两条出边。

基础情形两种：

- ε：两个状态、一条 ε 边；
- 符号 a：两个状态、一条 a 边。

归纳情形三种
（设 N₁、N₂ 已造好）：

- **R₁|R₂**：
  新建入口 f 与出口 t，
  f 用两条 ε 边分别指向
  N₁、N₂ 的入口，
  N₁、N₂ 的出口
  各用一条 ε 边指向 t。
  任何 f→t 的路径
  必须整个穿过 N₁ 或 N₂，
  不可能两者混杂——
  这正是"或"的语义。
- **R₁R₂**：
  把 N₂ 的入口与 N₁ 的出口
  **识别为同一个状态**
  （绿龙原话："the latter disappears"）。
  路径必须先穿 N₁ 再穿 N₂，
  且由于入口无入边、
  出口无出边的不变式，
  不可能从 N₂ 折返 N₁。
- **R\***：
  新建入口 f 与出口 t；
  f 有两条 ε 边，
  一条直通 t（表达"零次"），
  一条进入 N₁；
  N₁ 的出口也两条 ε 边，
  一条回 N₁ 入口（"再来一遍"），
  一条去 t。

正确性是标准的结构归纳：
假设 N₁、N₂ 分别
恰好接受 L(R₁)、L(R₂)，
逐条检查三种拼接
接受的恰好是
L(R₁)∪L(R₂)、L(R₁)L(R₂)、L(R₁)*。
不变式也在每种拼接后保持。

状态数有公式：
每个出现的符号贡献 2 个状态，
每个 `|` 与每个 `*`
再各贡献 2 个；
拼接因为做的是状态合并，
一个都不加。
绿龙的 `(a|b)*abb`：
符号 5 个（a,b,a,b,b）→ 10，
一个 `|` 一个 `*` → 4，
合计 **11 个状态**——
与书上 Fig 3.11 完全一致。
本章示例的输出第一行
`nfa_states=11`
对的就是这个数。

"每状态至多两条出边"
不是凑巧，
是刻意的设计：
NFA 可以用一个
`(符号, 下一态1, 下一态2)` 的
三元组数组存下，
紧凑且缓存友好。
配套代码正是这么存的。

### 5.4.2 代码：Builder 与压实

`thompson` 的入口在 `re.cpp`：
先 `build` 递归拼装，
再做一次**压实**。
压实是给"状态合并"收尾的：
被合并掉的入口
成了谁也不指向的孤儿，
从起始状态做一次
可达性重编号，
孤儿就消失了。
没有这一步，
`(a|b)*abb` 会数出 14 个状态
（ε 直连版 concat 的写法），
有了它才回到书上的 11。

```cpp
        case REKind::Concat: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            // 绿龙原文：“把 N2 的入口识别为 N1 的出口，后者消失”——
            // 状态合并而不是 ε 直连，这正是书上例子状态数更少的原因。
            // 入口不变式保证没有边指向 e2 的“内部”，只需全局改指。
            n.st[x1] = n.st[e2];   // x1 继承 e2 的（至多两条）出边
            for (auto &q : n.st) {
                if (q.to1 == e2) q.to1 = x1;
                if (q.to2 == e2) q.to2 = x1;
            }
            entry = e1;
            exit_ = x2;
            break;
        }
```

以及 `thompson` 末尾的压实（被合并的入口成了孤儿，
从 start 做一次可达性重编号才回到书上的 11 态）：

```cpp
    std::vector<int> num(n.st.size(), -1);
    std::vector<int> stack = {n.start};
    num[n.start] = 0;
    int cnt = 1;
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        for (int t : {n.st[s].to1, n.st[s].to2}) {
            if (t != -1 && num[t] == -1) {
                num[t] = cnt++;
                stack.push_back(t);
            }
        }
    }
```
（5.10 节嵌入完整源码，
此处只点了骨架。）
`build` 的五个 case
与 5.4.1 的五种构造一一对应；
`Concat` 分支里的三行
就是"状态合并"：
出口继承入口的出边，
全图把指向旧入口的边改指出口。

## 5.5 子集构造：从 NFA 到 DFA

### 5.5.1 核心思想：让 DFA 的一个状态记住"NFA 此刻可能在哪"

NFA 难模拟，
是因为读完前缀 w 后
它可能同时处于好几个状态。
那就让 DFA 的一个状态
**表示 NFA 状态的一个集合**——
"NFA 读完 w 后
可能处于的所有状态"。
DFA 一步转移
= 把集合里每个状态
在输入符号下的去向
全收集起来，
再用 ε 边扩满。
这就是**子集构造**
（绿龙 Algorithm 3.1）。

先定义 **ε 闭包**：
ε-CLOSURE(T)
是从 T 出发、
只走 ε 边能到的
全部状态（含 T 自身）。
计算它是教科书级的
栈式图搜索
（绿龙 Fig 3.9）：

```
把 T 全部压栈；结果 := T
while 栈非空:
    弹出 s
    对 s 的每条 ε 出边 (s→u):
        若 u 不在结果里: 加入并压栈 u
```

眼熟的读者会心一笑：
这就是第 24 章工作表算法
在图搜索上的袖珍版——
"发现新东西就记账，
账清了就停"。
本章先见实例，
第 22、23 章
再把它升级成不动点理论。

子集构造主体：

- DFA 起始状态 =
  ε-CLOSURE({NFA 起始状态})；
- 对每个已构造的 DFA 态 S
  （它是 NFA 态集合）
  和每个输入符号 a：
  令 T = S 中各状态
  沿 a 边的去向全体，
  则 DFA 转移
  S --a--> ε-CLOSURE(T)；
- DFA 态接受
  ⟺ 它包含 NFA 的某个接受态。

正确性一句话：
对输入串长度做归纳，
"DFA 读完 w 所在状态"
恰好等于
"NFA 读完 w 可能处于的状态集"，
于是
"DFA 接受 w"
⟺
"接受态 ∈ NFA 可能集"
⟺
"存在接受路径"
⟺
"NFA 接受 w"。

### 5.5.2 绿龙例算：A、B、C、D、E

把子集构造套在
11 状态的 `(a|b)*abb` NFA 上
（绿龙 Example 3.10 的全过程，
值得在纸上演算一遍）：

- 起始 A = ε-CLOSURE({0})
  = {0,1,2,4,7}；
- A 读 a：
  去向 {3,8}，
  闭包 B = {1,2,3,4,6,7,8}；
- A 读 b：
  去向 {5}，
  闭包 C = {1,2,4,5,6,7}；
- B 读 a → B，
  B 读 b → D = {1,2,4,5,6,7,9}；
- C 读 a → B，C 读 b → C；
- D 读 a → B，
  D 读 b → E = {1,2,4,5,6,7,10}；
- E 读 a → B，E 读 b → C。

只有 E 含接受态 10，
所以 E 接受——
恰好对应"当前串以 abb 结尾"。
五个状态、每态两条转移，
就是期望输出里
`dfa_states=5` 的那行。

理论最坏情况：
NFA 有 n 个状态时
子集可达 2ⁿ 个。
但绿龙原书就强调
（工程界一个世纪的经验也佐证）：
实际出现的模式
几乎从不触发指数爆炸；
真发生了，
后面还有最小化兜底。

### 5.5.3 一个诚实的冗余：IDENT 的 28 态

看期望输出里
`IDENT: nfa=205 dfa=28 minimized=2`。
28 哪来的？
我们的 26 个字母写成
26 路 `|` 的二叉树，
子集构造给
"读完第 2 个字母后"
的每个字母都造了
一个**互不相同**的 DFA 态
（闭包集合里
各自带着自己的字母出口状态），
1 + 1 + 26 = 28。
它们的行为完全一样，
最小化后合成 1 个，
所以 `minimized=2`
（起始态 + 循环态）。

这个 28→2 不是缺陷，
是子集构造的**本性**：
它按"集合相等"区分状态，
不看"行为相等"。
行为相等要交给 5.6 节。
绿龙原书在此处的评语
值得原样转述：
子集构造不合并
"看起来显然相同"的状态，
正是最小化算法存在的理由。

## 5.6 最小化：合并一切行为相同的状态

### 5.6.1 可区分性

称串 w **区分**状态 s 与 t，
如果从 s 出发读 w
停在接受态、
而从 t 出发读 w
停在非接受态，
或者反过来。
ε（空串）区分一切
"终态 vs 非终态"对；
在 `(a|b)*abb` 的五态 DFA 里，
`bb` 区分 A 与 B
（A 经 bb 到非终态 C，
B 经 bb 到终态 E）。

最小化算法的目标：
找出所有**不可区分**的状态对，
把它们各自合并。
 Green 龙的 Algorithm 3.3
用"分割细化"实现：

1. 初始分割：
   终态一组，非终态一组
   （ε 已经能区分这两组）；
2. 对当前每个组 G、
   每个输入符号 a 检查：
   若 G 内各状态沿 a
   落进了**不同的组**，
   就把 G 按落点分裂；
3. 重复 2 直到一轮下来
   没有任何分裂。

为什么停？
组数每轮要么不变、
要么严格增加，
上界是状态数——
单调有界必终止。
这论证与第 23 章
"格高度 × 单调 ⇒ 有限步收敛"
是同一个骨架，
第 29 章会把整个数据流家族
统一到这个骨架上。

为什么正确？
两个方向：
被分开的状态确实可区分
（对分裂时用到的符号串
归纳构造区分串）；
没被分开的状态
对一切串都不可区分
（反证：取最短的区分串，
推出更短的区分串，
矛盾——这步是证明的精髓）。
最后的 DFA 在
同构意义下**唯一**——
"最简 DFA"不是搜索出来的，
是像整数分解一样确定的。

### 5.6.2 绿龙例算：{ABC}{D}{E}

五态 DFA 的最小化全程：

- 初始：{A,B,C} {E}；
- 查 b：A、B、C 里
  只有 D 的前置……
  逐态看：
  A、B、C 沿 b 都落回非终态组？
  不——
  A→C、B→D、C→C，
  D 在哪组此刻还和非终态同组
  （第一轮还没分出 D）。
  仔细按轮次走：
  第一轮，
  非
  终态组 {A,B,C,D} 里
  沿 b 落点
  A→C、B→D、C→C、D→E，
  E 在终态组——
  所以 {A,B,C,D} 分裂为
  {A,B,C} 与 {D}；
- 第二轮，
  {A,B,C} 沿 b：
  A→C、B→D、C→C，
  D 已单居一组——
  分裂为 {A,C} 与 {B}；
- 第三轮，
  {A,C} 沿 a 都到 B、
  沿 b 都到 C——
  不再分裂。
  终止。

最终分割 {A,C}{B}{D}{E}，
四态。
期望输出的
`minimized=4` 与
打印出来的 4 行转移表，
就是它——
与绿龙 Fig 3.15
（也即更早的 Fig 3.8）
完全同构。
一个有趣的细节：
书上先在 Fig 3.8
手画了这个四态 DFA、
后来才用算法把它推出来，
"猜对答案"与"算出答案"
在数学里往往是先后两件事。

### 5.6.3 color：给接受态分优先级

标准最小化只认"终态/非终态"。
词法器还需要更多：
两条规则可能
接受同一个串
（如 `<` 与 `<=` 对输入 `<`），
谁赢由**优先级**定。
于是示例把"终态布尔"
推广成 **color 整数**：
0 = 非接受，
k > 0 = 第 k 优先级的接受。
初始分割按 color 分组，
不同优先级的接受态
从第一轮起就分居两组，
永远不合并；
子集构造给 DFA 态着色时
取集合中**最小**的正类
（最高优先级）。
这是对教科书算法的
一步小推广，
改动只有初始分割一处，
5.7 节马上用到。

## 5.7 多模式 scanner：并联、最长匹配与保留字

### 5.7.1 并联

词法器要同时认识 18 条规则。
做法直白：
每条规则各自 Thompson 出一个 NFA，
再像 `R₁|R₂|…|Rₙ` 那样并联。
但 Thompson 的形状约定
"每态至多两条出边"
限制了公共起点只能挂两条 ε 边——
所以示例用**平衡二叉树**式并联：
两两配对加分叉节点，
18 条规则 17 个分叉，
深度只有 ⌈log₂18⌉，
ε 闭包走起来也浅。

每个部件的接受态
记下自己属于哪条规则
（即 5.6.3 的 color），
子集构造 + 最小化之后，
得到一台
"多模式合一"的 DFA。

### 5.7.2 最长匹配与优先级

切词主循环是**最长匹配**
（maximal munch）：
从当前位置出发
沿 DFA 尽量往前走，
记住**最后一次**
踏进接受态的位置；
走不动了，
就按那个最远的接受位置切一刀，
回退到那里。
若从头到尾
没进过接受态，
报一个 `ERR('c')`。

"最后一次"而不是"第一次"，
就是 `<=' 不会被切成
`<` 和 `=`
的原因；
而同一位置
若有多条规则同时接受，
color 里最小的赢——
这就是"先声明的规则优先"，
ANTLR 词法规则的
优先级语义与此完全一致
（紫龙 3.5.3 讲 LEX 的
冲突消解，
用的也是同一对原则）。

### 5.7.3 保留字策略

`if`、`while` 这些关键字
要不要给每条写一个模式？
绿龙 3.2 节给了漂亮的答案：
**不写**。
让关键字走 IDENT 模式切出来，
切完后查一张小小的保留字表，
命中就改判关键字。
好处有三：
模式表短、
新关键字零成本、
DFA 不因关键字数量膨胀
（想想 5.5.3 的 28 态教训：
每条字母树模式
都会在子集构造里膨胀）。
示例的输出里
`KW('if')`、`KW('alloc')`
就是 IDENT 切完升级来的。

### 5.7.4 一个真实的 authoring bug：优先级的教训

本示例开发时踩过一个坑，
值得原样留给读者。
最初 NUMBER 的模式写成：

```
0|1|2|3|4|5|6|7|8|9(0|1|...|9)*
```

结果 `42` 被切成
`NUMBER('4')` 和 `NUMBER('2')`。
为什么？
正则里 `|` 优先级最低，
上式实际分组是
`0|(1|(2|(...(9(D)*))))`——
**只有 9** 后面跟着 `(D)*`，
其余数字都是
"单字符分支"。
修法是给整个数字集合加括号：

```
(0|1|2|3|4|5|6|7|8|9)(0|1|...|9)*
```

IDENT 的初版
`a(letters)*` 同病：
字面量 `a` 被当成了
"任意字母"的 metavariable，
结果只有 a 开头的词能被切出来。
两处修改都发生在
`main.cpp` 的规则表里——
正则的"乘法高于加法"
在 authoring 时
比看上去更容易咬人。

## 5.8 期望输出解读

`--check` 的输出三段，
逐段读：

**第一段 `(a|b)*abb`**。
`nfa_states=11 dfa_states=5 minimized=4`
是全章的数字主线：
Thompson 的 11
对齐绿龙 Fig 3.11，
子集构造的 5
对齐 Fig 3.12 的 A..E，
最小化的 4
对齐 Fig 3.15。
下面的 4 行转移表
`->0`、`1`、`2`、`3*`
（箭头 = 起始，星号 = 接受）
读法：
状态 0 在 a 下到 1、b 下回 0
（"前缀随便"）；
1、2 是"见过 a / ab"的记忆；
3* 是"刚见过 abb"。
七个样例串里
`abba`、`ab`、空串被拒，
其余被收——
与"以 abb 结尾"的定义逐一对上。

**第二段 `patterns`**。
四个模式的
`nfa/dfa/minimized` 三元组。
LE 与 IFKW 各 3/3/3：
两字符的模式
本来就无冗余可压；
IDENT 的 205/28/2
是 5.5.3 讲的
"子集冗余、最小化收拾"；
NUMBER 的 77/21/2 同理。
两个 `minimized=2`
说的是同一件事：
"首字符吃进、
之后同类字符循环"——
最小的形态就是两态。

**第三段 `scanner`**。
`rules=18 alphabet=50 dfa_states=100`：
18 条规则并联后
总 DFA 一百态，
最小化已包含在内。
接着的 token 流
对着 `programs/lex.tip`
逐行可查：
`LE('<=')` 没有被拆成
`LT` + `ASSIGN`（最长匹配）；
`NUMBER('42')` 是一个
token 而不是两个（5.7.4 的修复）；
`KW('if')` … `KW('alloc')`
八个保留字全部改判成功
（保留字策略）；
`input` 后的 `LP/RP`
说明函数调用的括号
走的是标点模式。
文件末尾的 `COMMA(',')`
后面再无 token——
文件以逗号结尾这个
略怪异的写法
就是为了在期望输出里
钉住"末尾无回车不丢 token"。

## 5.9 工程注意点

- **转义**。
  正则元字符 `(`、`)`
  要按字面量匹配时必须转义。
  示例的解析器支持
  `\\(` 形式，
  规则表里 LP/RP/LB/RB
  用的就是它。
  ANTLR 文法里同样有
  一套转义约定（第 4 章）。
- **表的形状**。
  真实词法器的 DFA 表
  是行稀疏的
  （状态 × 字符的大矩阵里
  绝大多数格子是"无转移"），
  工程上会压缩成
  行指针 + 区间映射，
  紫龙 3.9.8 专门讨论
  时间换空间的各种存法。
- **更快的构造**。
  从正则语法树
  直接算 DFA
  （nullable/firstpos/lastpos/followpos，
  紫龙 3.9.2–3.9.5）
  可以跳过显式 NFA、
  少一跳状态膨胀，
  ANTLR 的词法生成器
  走的就是这类路线。
  本章仍走 Thompson + 子集构造，
  因为它每一步都能
  画在纸上、查在表里。
- **最小化的初试分割**。
  把终态布尔换成 color，
  就能承载优先级——
  这个小推广在
  任何"多模式合一"的场合都用得上，
  比如日志的高亮切分。
- **与 ANTLR 的关系**。
  第 4 章的 `TIP.g4`
  里每条词法规则
  就是一个正则；
  ANTLR 按本章的流水线
  （加直接构造优化）
  把它们编译成转移表，
  再由运行时的
  通用 DFA 解释器驱动。
  黑盒拆开，
  里面就是本章这三节。

## 5.10 本章配套文件

以下整文件收录
`examples/05_regex_automata` 的全部内容。
本章示例不使用 ANTLR 与 LLVM——
纯算法章，
构建脚本检测不到 `TIP.g4`
与 `llvm.need`
就自动退化为
单进程编译。

### 5.10.1 头文件 re.hpp

数据结构贴着绿龙伪码走：
NFA 状态就是
`(符号, 下一态1, 下一态2)` 三元组。

```cpp
// file: src/re.hpp
// file: src/re.hpp
// 第 5 章配套：正则表达式 → NFA → DFA → 最小 DFA 的完整流水线。
// 数据结构刻意贴着绿龙 Algorithm 3.1–3.3 的伪码走：
//   NFA 状态 = (符号, 下一状态1, 下一状态2) 三元组（ε 用 '\0' 表示）；
//   DFA 状态 = NFA 状态子集（子集构造的产物）；
//   最小化   = 按可区分性反复分割（Algorithm 3.3）。
#ifndef TIP_RE_HPP
#define TIP_RE_HPP

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 正则表达式的语法树 ----------
// 与绿龙 3.3 节的归纳定义一一对应：基础是 ε 与单符号 a，
// 归纳步是 R|S、RS、R* 三条。没有并集、差集之类的扩展运算——
// 教科书子集足够描述 TIP 的全部 token。
enum class REKind { Eps, Sym, Alt, Concat, Star };

struct RE {
    REKind kind;
    char ch = 0;                     // Kind::Sym 时有效
    std::unique_ptr<RE> lhs, rhs;    // Alt/Concat 用两个，Star 用 lhs

    static std::unique_ptr<RE> eps();
    static std::unique_ptr<RE> sym(char c);
    static std::unique_ptr<RE> alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> star(std::unique_ptr<RE> a);
};

// 把中缀正则串解析成语法树。文法（优先级：* 高于并置，并置高于 |）：
//   expr  → term ('|' term)*
//   term  → factor factor*
//   factor→ atom '*'?
//   atom  → '(' expr ')' | 字符
// 这本身就是一个 LL(1) 文法——第 6 章会正式认识它。
std::unique_ptr<RE> parseRE(const std::string &pat);

// ---------- NFA：绿龙式三元组表示 ----------
// Algorithm 3.2 保证每个状态至多两条出边，因此三元组就够。
// sym == '\0' 表示 ε 边；to2 == -1 表示没有第二条边。
struct NFA {
    struct State {
        char sym1 = 0; int to1 = -1;
        char sym2 = 0; int to2 = -1;
        bool accept = false;
    };
    std::vector<State> st;
    int start = 0, finish = 0;   // Thompson 构造保证单一入口/单一出口
};

// Thompson 构造（Algorithm 3.2）：按语法树归纳地拼装。
NFA thompson(const RE &re);

// ---------- DFA ----------
struct DFA {
    // 状态编号 0..n-1；trans[s][c] 缺席（-1）表示该输入下无转移。
    std::vector<std::map<char, int>> trans;
    int start = 0;
    std::vector<int> color;   // 0 = 非接受；k>0 = 第 k 优先级的接受类
    int states() const { return static_cast<int>(trans.size()); }
};

// 子集构造（Algorithm 3.1）。alphabet 显式给出，避免“隐式全集”歧义。
// stateClass 为空时按 accept 态统一给类 1；scanner 场景传入
// “NFA 态 → 规则号+1”的着色，子集的类取集合中最小者（最高优先级）。
DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass = {});

// 状态最小化（Algorithm 3.3）。初试分割按 color 分组——
// 不同优先级的接受态即使行为相同也不可合并（scanner 语义依赖优先级）。
DFA minimize(const DFA &d, const std::set<char> &alphabet);

// ---------- 多模式 scanner ----------
struct TokenRule { std::string name, pat; };

// 词法分析：把每条规则编译成一个 NFA，共用一个新起点并联；
// 子集构造时每个 DFA 态携带“所含 NFA 接受态的最高优先级规则号”；
// 主循环做最长匹配（maximal munch），平局按优先级。
class Scanner {
public:
    explicit Scanner(std::vector<TokenRule> rules, std::set<char> alphabet);
    // 对输入做一遍切词；无法成词的字符输出 ERR('c')。
    std::vector<std::string> lex(const std::string &src) const;
    // 诊断信息：供 --check 打印各阶段状态数。
    std::string stats() const;

private:
    std::vector<TokenRule> rules_;
    std::set<char> alpha_;
    DFA dfa_;
    std::vector<int> nfaStateRule_;   // NFA 态 → 规则号（-1 非接受）
};

}  // namespace tip

#endif  // TIP_RE_HPP
```

### 5.10.2 实现 re.cpp

解析、Thompson、子集构造、
最小化、scanner 五件事全在此。

```cpp
// file: src/re.cpp
// file: src/re.cpp
// 第 5 章配套：re.hpp 全部算法的实现。
#include "re.hpp"

#include <algorithm>
#include <cassert>
#include <sstream>

namespace tip {

// ---------- 语法树构造 ----------
std::unique_ptr<RE> RE::eps() {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Eps;
    return r;
}
std::unique_ptr<RE> RE::sym(char c) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Sym;
    r->ch = c;
    return r;
}
std::unique_ptr<RE> RE::alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Alt;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Concat;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::star(std::unique_ptr<RE> a) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Star;
    r->lhs = std::move(a);
    return r;
}

// ---------- 正则串的递归下降解析 ----------
namespace {
struct REParser {
    const std::string &s;
    size_t i = 0;
    explicit REParser(const std::string &src) : s(src) {}

    [[noreturn]] void fail(const char *why) const {
        std::ostringstream os;
        os << "regex 位置 " << i << ": " << why;
        throw std::runtime_error(os.str());
    }

    std::unique_ptr<RE> expr() {
        auto t = term();
        while (i < s.size() && s[i] == '|') {
            ++i;
            t = RE::alt(std::move(t), term());
        }
        return t;
    }
    std::unique_ptr<RE> term() {
        if (i >= s.size() || s[i] == '|' || s[i] == ')')
            return RE::eps();           // 空并置 = ε（允许 "(a|)" 这类宽松写法）
        auto f = factor();
        while (i < s.size() && s[i] != '|' && s[i] != ')')
            f = RE::concat(std::move(f), factor());
        return f;
    }
    std::unique_ptr<RE> factor() {
        auto a = atom();
        while (i < s.size() && s[i] == '*') {
            ++i;
            a = RE::star(std::move(a)); // 连续星 a** 同样合法：等价于 a*
        }
        return a;
    }
    std::unique_ptr<RE> atom() {
        if (i >= s.size()) fail("意外结束");
        if (s[i] == '\\') {          // 转义：下一个字符一律按字面量处理
            ++i;
            if (i >= s.size()) fail("转义后意外结束");
            return RE::sym(s[i++]);
        }
        if (s[i] == '(') {
            ++i;
            auto e = expr();
            if (i >= s.size() || s[i] != ')') fail("缺右括号");
            ++i;
            return e;
        }
        if (s[i] == ')' || s[i] == '|') fail("缺操作数");
        return RE::sym(s[i++]);
    }
};
}  // namespace

std::unique_ptr<RE> parseRE(const std::string &pat) {
    REParser p(pat);
    auto re = p.expr();
    if (p.i != pat.size()) p.fail("尾部有多余字符");
    return re;
}

// ---------- Thompson 构造（Algorithm 3.2） ----------
namespace {
struct Builder {
    NFA n;

    int fresh() {
        n.st.emplace_back();
        return static_cast<int>(n.st.size()) - 1;
    }
    // 基础：单符号 a → 两个状态一条实边；ε → 两个状态一条 ε 边。
    // 归纳：R|S 与 R* 各加两个新状态、四条 ε 边；RS 把出口 ε 直连入口。
    // 每个部件“单一入口、单一出口、入口无入边、出口无出边”的
    // 不变式由构造本身维持——这正是归纳证明能成立的原因。
    void build(const RE &re, int &entry, int &exit_) {
        switch (re.kind) {
        case REKind::Eps: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Sym: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {re.ch, exit_, 0, -1, false};
            break;
        }
        case REKind::Alt: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, e2, false};
            n.st[x1] = {0, exit_, 0, -1, false};
            n.st[x2] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Concat: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            // 绿龙原文：“把 N2 的入口识别为 N1 的出口，后者消失”——
            // 状态合并而不是 ε 直连，这正是书上例子状态数更少的原因。
            // 入口不变式保证没有边指向 e2 的“内部”，只需全局改指。
            n.st[x1] = n.st[e2];   // x1 继承 e2 的（至多两条）出边
            for (auto &q : n.st) {
                if (q.to1 == e2) q.to1 = x1;
                if (q.to2 == e2) q.to2 = x1;
            }
            entry = e1;
            exit_ = x2;
            break;
        }
        case REKind::Star: {
            int e1, x1;
            build(*re.lhs, e1, x1);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, exit_, false};
            n.st[x1] = {0, e1, 0, exit_, false};
            break;
        }
        }
    }
};
}  // namespace

NFA thompson(const RE &re) {
    Builder b;
    int entry, exit_;
    b.build(re, entry, exit_);
    b.n.st[exit_].accept = true;
    b.n.start = entry;
    b.n.finish = exit_;
    // 压实：concat 的状态合并会留下不可达的孤儿入口，
    // 从 start 做一次可达性重编号，状态数才与绿龙例子的口径一致。
    NFA &n = b.n;
    std::vector<int> num(n.st.size(), -1);
    std::vector<int> stack = {n.start};
    num[n.start] = 0;
    int cnt = 1;
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        for (int t : {n.st[s].to1, n.st[s].to2}) {
            if (t != -1 && num[t] == -1) {
                num[t] = cnt++;
                stack.push_back(t);
            }
        }
    }
    NFA packed;
    packed.st.resize(cnt);
    for (int s = 0; s < static_cast<int>(n.st.size()); ++s)
        if (num[s] != -1) {
            packed.st[num[s]] = n.st[s];
            auto &st = packed.st[num[s]];
            if (st.to1 != -1) st.to1 = num[st.to1];
            if (st.to2 != -1) st.to2 = num[st.to2];
        }
    packed.start = 0;                       // 重编号从 start 出发，start 必为 0
    packed.finish = num[n.finish];
    return packed;
}

// ---------- ε 闭包与子集构造（Algorithm 3.1） ----------
namespace {
// ε-CLOSURE(T)：从 T 出发只沿 ε 边可达的状态集（含 T 自身）。
// 绿龙 Fig 3.9 的栈式搜索——它就是第 24 章工作表算法的袖珍版。
std::set<int> epsClosure(const NFA &n, const std::set<int> &t) {
    std::set<int> got = t;
    std::vector<int> stack(t.begin(), t.end());
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        const auto &st = n.st[s];
        if (st.sym1 == 0 && st.to1 != -1 && !got.count(st.to1)) {
            got.insert(st.to1);
            stack.push_back(st.to1);
        }
        if (st.sym2 == 0 && st.to2 != -1 && !got.count(st.to2)) {
            got.insert(st.to2);
            stack.push_back(st.to2);
        }
    }
    return got;
}
}  // namespace

DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass) {
    auto cls = [&](int q) -> int {
        if (!stateClass.empty()) return stateClass[q];
        return n.st[q].accept ? 1 : 0;
    };
    DFA d;
    std::map<std::set<int>, int> id;
    std::vector<std::set<int>> work;
    auto nameOf = [&](const std::set<int> &s) {
        auto [it, fresh] = id.emplace(s, static_cast<int>(id.size()));
        if (fresh) {
            d.trans.emplace_back();
            d.color.push_back(0);
            work.push_back(s);
        }
        return it->second;
    };
    d.start = nameOf(epsClosure(n, {n.start}));
    // 只沿实符号转移扩张；ε 已被闭包吸收。
    for (size_t wi = 0; wi < work.size(); ++wi) {
        int cs = id.at(work[wi]);
        for (char c : alphabet) {
            std::set<int> next;
            for (int q : work[wi]) {
                const auto &st = n.st[q];
                if (st.sym1 == c && st.to1 != -1) next.insert(st.to1);
                if (st.sym2 == c && st.to2 != -1) next.insert(st.to2);
            }
            if (next.empty()) continue;
            nameOf(epsClosure(n, next));
            int t = id.at(epsClosure(n, next));
            d.trans[cs][c] = t;
        }
    }
    // 接受类：子集中出现的最小正类（最高优先级）。
    for (const auto &[sub, s] : id) {
        int best = 0;
        for (int q : sub)
            if (cls(q) > 0 && (best == 0 || cls(q) < best)) best = cls(q);
        d.color[s] = best;
    }
    return d;
}

// ---------- 最小化（Algorithm 3.3） ----------
DFA minimize(const DFA &d, const std::set<char> &alphabet) {
    // 初试分割按 color 分组：空串 ε 本身就能区分接受与非接受，
    // 不同优先级的接受态也必须从第一轮起就分居两组。
    auto countGroups = [](const std::vector<int> &g) {
        return static_cast<size_t>(*std::max_element(g.begin(), g.end()) + 1);
    };
    std::vector<int> group(d.states());
    {
        std::map<int, int> colorToGroup;
        for (int s = 0; s < d.states(); ++s) {
            auto [it, fresh] = colorToGroup.emplace(d.color[s],
                                                    static_cast<int>(colorToGroup.size()));
            group[s] = it->second;
        }
    }
    // 反复按“全部输入符号都落进同一组”细化，直到组数不再增长。
    // 签名以旧组号开头，因此每轮只会分裂、不会合并——
    // 单调有界，循环必然停止（与第 23 章不动点的终止论证同型）。
    while (true) {
        std::map<std::pair<int, std::vector<std::pair<char, int>>>, int> sigToGroup;
        std::vector<int> next(d.states());
        for (int s = 0; s < d.states(); ++s) {
            std::vector<std::pair<char, int>> sig;
            sig.reserve(alphabet.size());
            for (char c : alphabet) {
                auto it = d.trans[s].find(c);
                int t = (it == d.trans[s].end()) ? -1 : it->second;
                sig.emplace_back(c, t < 0 ? -1 : group[t]);
            }
            auto [it, fresh] = sigToGroup.emplace(std::make_pair(group[s], sig),
                                                  static_cast<int>(sigToGroup.size()));
            next[s] = it->second;
        }
        if (sigToGroup.size() == countGroups(group)) break;   // 稳定
        group = next;
    }
    // 重建：每组取一个代表态（编号最小者），重定向所有转移。
    int nGroups = static_cast<int>(countGroups(group));
    std::vector<int> rep(nGroups, -1);
    for (int s = 0; s < d.states(); ++s)
        if (rep[group[s]] == -1) rep[group[s]] = s;
    DFA m;
    m.trans.assign(nGroups, {});
    m.color.assign(nGroups, 0);
    m.start = group[d.start];
    for (int g = 0; g < nGroups; ++g) {
        int s = rep[g];
        m.color[g] = d.color[s];
        for (char c : alphabet) {
            auto it = d.trans[s].find(c);
            if (it != d.trans[s].end()) m.trans[g][c] = group[it->second];
        }
    }
    return m;
}

// ---------- scanner ----------
Scanner::Scanner(std::vector<TokenRule> rules, std::set<char> alphabet)
    : rules_(std::move(rules)), alpha_(std::move(alphabet)) {
    // 多模式并联：公共起点只留两条 ε 出边位（Thompson 的形状约定），
    // 因此像表达式 a|b|c|d 一样做“两两合并”的平衡树：
    // 规则 k 的入口挂到树的第 k 个叶子上，树根是整个大 NFA 的入口。
    std::vector<NFA> parts;
    std::vector<int> partStart;
    for (const auto &r : rules_) {
        NFA one = thompson(*parseRE(r.pat));
        partStart.push_back(one.start);     // 部件入口要存“部件内的编号”
        parts.push_back(std::move(one));
    }
    NFA big;
    auto fresh = [&]() {
        big.st.emplace_back();
        nfaStateRule_.push_back(-1);
        return static_cast<int>(big.st.size()) - 1;
    };
    auto offset = [&](NFA &host, int idx, int base) {
        for (auto &st : host.st) {
            if (st.to1 != -1) st.to1 += base;
            if (st.to2 != -1) st.to2 += base;
        }
        (void)idx;
    };
    // 逐个搬入并改相对编号；接受态记录所属规则（0 起的最高优先级）。
    std::vector<int> shiftedRoots;
    for (size_t k = 0; k < parts.size(); ++k) {
        int base = static_cast<int>(big.st.size());
        offset(parts[k], static_cast<int>(k), base);
        for (size_t q = 0; q < parts[k].st.size(); ++q) {
            big.st.push_back(parts[k].st[q]);
            nfaStateRule_.push_back(parts[k].st[q].accept ? static_cast<int>(k) : -1);
        }
        shiftedRoots.push_back(base + partStart[k]);
    }
    // 平衡树式并联：每合并两棵子树加一个 ε 分叉状态。
    while (shiftedRoots.size() > 1) {
        std::vector<int> next;
        for (size_t i = 0; i < shiftedRoots.size(); i += 2) {
            if (i + 1 < shiftedRoots.size()) {
                int join = fresh();
                big.st[join] = {0, shiftedRoots[i], 0, shiftedRoots[i + 1], false};
                next.push_back(join);
            } else {
                next.push_back(shiftedRoots[i]);
            }
        }
        shiftedRoots = next;
    }
    big.start = shiftedRoots[0];
    // NFA 态着色：规则号+1（0 仍表示非接受）。
    std::vector<int> stateClass;
    for (int k : nfaStateRule_) stateClass.push_back(k < 0 ? 0 : k + 1);
    dfa_ = minimize(subset(big, alpha_, stateClass), alpha_);
}

std::vector<std::string> Scanner::lex(const std::string &src) const {
    std::vector<std::string> out;
    size_t i = 0;
    while (i < src.size()) {
        if (src[i] == ' ' || src[i] == '\n' || src[i] == '\t' || src[i] == '\r') {
            ++i;
            continue;
        }
        int s = dfa_.start;
        size_t j = i;
        size_t lastAcc = std::string::npos;
        int lastColor = 0;
        if (dfa_.color[s] > 0) { lastAcc = i; lastColor = dfa_.color[s]; }
        while (j < src.size()) {
            auto it = dfa_.trans[s].find(src[j]);
            if (it == dfa_.trans[s].end()) break;
            s = it->second;
            ++j;
            if (dfa_.color[s] > 0) { lastAcc = j; lastColor = dfa_.color[s]; }
        }
        if (lastAcc == std::string::npos) {
            std::ostringstream os;
            os << "ERR('" << src[i] << "')";
            out.push_back(os.str());
            ++i;
        } else {
            std::ostringstream os;
            os << rules_[lastColor - 1].name << "('" << src.substr(i, lastAcc - i) << "')";
            out.push_back(os.str());
            i = lastAcc;
        }
    }
    return out;
}

std::string Scanner::stats() const {
    std::ostringstream os;
    os << "rules=" << rules_.size() << " alphabet=" << alpha_.size()
       << " dfa_states=" << dfa_.states();
    return os.str();
}

}  // namespace tip
```

### 5.10.3 驱动 main.cpp

`--check FILE`：
先跑 `(a|b)*abb` 全流水线，
再打印四个模式的状态数，
最后对 FILE 切词。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 5 章驱动：--check FILE 跑三组演示——
//   1) (a|b)*abb 的全流水线（对齐绿龙 Fig 3.11/3.12/3.15 的经典数字）；
//   2) TIP 各 token 模式的 NFA/DFA/最小 DFA 状态数；
//   3) 多模式最长匹配 scanner 对 FILE 切词（关键字走保留字策略）。
#include "re.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace {

std::string readFile(const std::string &path) {
    std::ifstream in(path);
    if (!in) throw std::runtime_error("打不开 " + path);
    std::ostringstream os;
    os << in.rdbuf();
    return os.str();
}

// 在 DFA 上做整串成员判定：读完且停在接受态。
bool accepts(const tip::DFA &d, const std::string &s) {
    int st = d.start;
    for (char c : s) {
        auto it = d.trans[st].find(c);
        if (it == d.trans[st].end()) return false;
        st = it->second;
    }
    return d.color[st] > 0;
}

void printTable(const tip::DFA &d, const std::set<char> &alpha) {
    std::cout << "state";
    for (char c : alpha) std::cout << ' ' << c;
    std::cout << '\n';
    for (int s = 0; s < d.states(); ++s) {
        std::cout << (s == d.start ? "->" : "  ") << s
                  << (d.color[s] > 0 ? "*" : " ");
        for (char c : alpha) {
            auto it = d.trans[s].find(c);
            if (it == d.trans[s].end()) std::cout << " .";
            else std::cout << ' ' << it->second;
        }
        std::cout << '\n';
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    const std::string src = readFile(argv[2]);

    // ---------- 演示一：(a|b)*abb 全流水线 ----------
    std::cout << "== demo: (a|b)*abb ==\n";
    auto re = tip::parseRE("(a|b)*abb");
    tip::NFA nfa = tip::thompson(*re);
    std::set<char> ab = {'a', 'b'};
    tip::DFA dfa = tip::subset(nfa, ab);
    tip::DFA mini = tip::minimize(dfa, ab);
    std::cout << "nfa_states=" << nfa.st.size()
              << " dfa_states=" << dfa.states()
              << " minimized=" << mini.states() << '\n';
    printTable(mini, ab);
    for (const char *s : {"abb", "aabb", "babb", "abba", "ab", "", "babbabb"})
        std::cout << "accepts \"" << s << "\": " << (accepts(mini, s) ? "yes" : "no") << '\n';

    // ---------- 演示二：TIP token 模式的状态数 ----------
    std::cout << "== patterns ==\n";
    struct P { const char *name, *pat; std::set<char> alpha; };
    std::vector<P> pats = {
        {"IDENT", "(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)*", {}},
        {"NUMBER", "(0|1|2|3|4|5|6|7|8|9)(0|1|2|3|4|5|6|7|8|9)*", {}},
        {"LE", "<=", {'<', '='}},
        {"IFKW", "if", {'i', 'f'}},
    };
    for (auto &p : pats) {
        if (p.alpha.empty()) {
            for (char c = 'a'; c <= 'z'; ++c) p.alpha.insert(c);
            for (char c = '0'; c <= '9'; ++c) p.alpha.insert(c);
        }
        tip::NFA pn = tip::thompson(*tip::parseRE(p.pat));
        tip::DFA pd = tip::subset(pn, p.alpha);
        tip::DFA pm = tip::minimize(pd, p.alpha);
        std::cout << p.name << ": nfa=" << pn.st.size()
                  << " dfa=" << pd.states()
                  << " minimized=" << pm.states() << '\n';
    }

    // ---------- 演示三：多模式 scanner 切词 ----------
    std::cout << "== scanner ==\n";
    std::vector<tip::TokenRule> rules = {
        {"LE", "<="}, {"GE", ">="}, {"EQ", "=="}, {"LT", "<"}, {"GT", ">"},
        {"ASSIGN", "="}, {"PLUS", "+"}, {"MINUS", "-"}, {"STAR", "*"}, {"SLASH", "/"},
        {"LP", "\\("}, {"RP", "\\)"}, {"LB", "\\{"}, {"RB", "\\}"},
        {"SEMI", ";"}, {"COMMA", ","},
        {"NUMBER", "(0|1|2|3|4|5|6|7|8|9)(0|1|2|3|4|5|6|7|8|9)*"},
        {"IDENT", "(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)*"},
    };
    std::set<char> alpha;
    for (char c = 'a'; c <= 'z'; ++c) alpha.insert(c);
    for (char c = '0'; c <= '9'; ++c) alpha.insert(c);
    for (char c : "<>=+-*/(){};,") alpha.insert(c);
    tip::Scanner sc(rules, alpha);
    std::cout << sc.stats() << '\n';
    // 关键字识别走“保留字策略”：先按 IDENT 切出，再查表升级（绿龙 3.2 节）。
    static const std::vector<std::string> kws = {
        "if", "else", "while", "return", "input", "output", "alloc", "record"};
    for (const std::string &tok : sc.lex(src)) {
        if (tok.rfind("IDENT('", 0) == 0 && tok.back() == ')') {
            std::string lexeme = tok.substr(7, tok.size() - 9);
            bool isKw = false;
            for (const auto &k : kws)
                if (k == lexeme) isKw = true;
            if (isKw) {
                std::cout << "KW('" << lexeme << "')\n";
                continue;
            }
        }
        std::cout << tok << '\n';
    }
    return 0;
}
```

### 5.10.4 输入 programs/lex.tip

一段覆盖关键字、
最长匹配陷阱、
记录语法与末尾逗号的
TIP 风格文本。

```text
// file: programs/lex.tip
if (x <= 42) { y = x*2 + 1; } else { while (y >= 0) y = y - 1; }
record point { px, pz }
alloc point
output px + input() * pz,
```

### 5.10.5 期望输出 expected/output.txt

5.8 节逐段解读的底稿。

```text
; expected: expected/output.txt
== lex.tip ==
== demo: (a|b)*abb ==
nfa_states=11 dfa_states=5 minimized=4
state a b
->0  1 0
  1  1 2
  2  1 3
  3* 1 0
accepts "abb": yes
accepts "aabb": yes
accepts "babb": yes
accepts "abba": no
accepts "ab": no
accepts "": no
accepts "babbabb": yes
== patterns ==
IDENT: nfa=205 dfa=53 minimized=2
NUMBER: nfa=77 dfa=21 minimized=2
LE: nfa=3 dfa=3 minimized=3
IFKW: nfa=3 dfa=3 minimized=3
== scanner ==
rules=18 alphabet=50 dfa_states=100
KW('if')
LP('(')
IDENT('x')
LE('<=')
NUMBER('42')
RP(')')
LB('{')
IDENT('y')
ASSIGN('=')
IDENT('x')
STAR('*')
NUMBER('2')
PLUS('+')
NUMBER('1')
SEMI(';')
RB('}')
KW('else')
LB('{')
KW('while')
LP('(')
IDENT('y')
GE('>=')
NUMBER('0')
RP(')')
IDENT('y')
ASSIGN('=')
IDENT('y')
MINUS('-')
NUMBER('1')
SEMI(';')
RB('}')
KW('record')
IDENT('point')
LB('{')
IDENT('px')
COMMA(',')
IDENT('pz')
RB('}')
KW('alloc')
IDENT('point')
KW('output')
IDENT('px')
PLUS('+')
KW('input')
LP('(')
RP(')')
STAR('*')
IDENT('pz')
COMMA(',')
```

## 5.11 小结与练习

本章把词法分析
从"ANTLR 的黑盒"
还原成三个算法：

- 正则表达式
  归纳定义了
  token 模式的全部表达力
  （以及它的边界——
  泵引理直觉）；
- Thompson 构造
  把表达式机械地变成 NFA，
  状态合并式 concat
  让 `(a|b)*abb`
  恰好用 11 个状态；
- 子集构造把 NFA
  压成可 O(n) 模拟的 DFA，
  最小化再把
  "行为相同"的状态合一，
  得到唯一的最简机器。

三步连起来，
"模式即程序"。
多模式并联 + color 优先级 +
最长匹配 + 保留字策略，
就是一台完整的词法器；
第 6 章起
token 流交给语法分析，
那里的主角
——FIRST/FOLLOW 与预测分析——
会在同样的
"归纳定义 + 机械构造"风格里登场。

练习：

1. 把 `(a*b*)*` 与 `(a|b)*`
   的等价性
   用 5.2.1 的代数律推一遍；
   再各画出最小 DFA，
   确认同构。
2. 手工对
   `(a|b)*abb` 的 NFA
   跑一遍子集构造，
   复算出 A..E 五个集合
   与 5.5.2 一致。
3. 手工对五态 DFA
   跑三轮最小化，
   复现 {A,C}{B}{D}{E}。
4. 给规则表加一条
   `NE` 模式 `!=`，
   重新生成期望输出
   （改动 `main.cpp` 后
   记得同步
   `expected/output.txt`——
   对账脚本会逐字节核对），
   观察 dfa_states 变化。
5. 构造一个正则 R
   与一个串 w，
   使 w 的某个前缀
   被 DFA 接受、
   整串也被接受、
   且最长匹配取整串——
   再构造一个
   整串不接受、
   必须回退到前缀的例子
   （提示：`if` 与标识符
   不冲突，
   但 `<a` 呢？）。
