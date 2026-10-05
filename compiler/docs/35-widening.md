# 第 35 章　加宽与收窄：让无限高的格有限步收敛

## 35.1 本章目标

第 34 章把区间格搬上了数据流机器，然后当着我们的面让它失
败了：`runNaiveInterval` 对 loop.tip 迭代了 50 轮，循环头
上 x 的区间从 `[1,1]` 长到 `[1,2]`、`[1,3]`……一路变松，到
被强制中止时也没有停下来的迹象。失败不是实现错误——区间格
**高度无穷**，Knaster–Tarski 定理仍然担保最小不动点存在，
但朴素的逐轮迭代不再担保能在有限步内到达它。我们第一次撞
到了"理论上答案存在、算法上算不出来"的墙。

本章要翻过这堵墙，路线是 Cousot 学派在 1977 年给出的经典
方案，由两步组成：

1. **加宽（widening，∇）**。不改变方程组，而改变迭代到达
   不动点的走法：在指定的**加宽点**上，不直接采纳新算出的
   更宽值，而把它与旧值做一次 ∇——∇ 的结果只能落在一个预
   先选定的**有限阈值表**上。这样，迭代序列在加宽点处只能
   踩着有限多个刻度上升，整条链有了有限长度，必然在有限步
   内稳定。代价是精度：∇ 的结果通常比真正的不动点松。
2. **收窄（narrowing，Δ）**。拿到 ∇ 给出的（偏松的）不动
   点之后，用原来的方程从它出发再推一遍，但每一步用 Δ 而
   不是直接 join——Δ 只允许把 ±∞ 处的界收紧到有限值，不
   允许有限界之间互相跳。这样既不会重新引入不终止，又能把
   ∇ 丢掉的精度捡回一部分。

本章还会补上一件第 34 章就该有、但被"先把失败演出来"的
节奏推迟了的设施：**分支边上的条件精炼**。`if (x > 0)` 的
真边意味着 x 在这条边上至少为 1，假边意味着 x 至多为 0；
把这种信息写进沿边传播的区间，区间分析才真正有用。本章最
后用第 15 章造好的 ORC JIT 把程序真跑三遍，把（加宽再收窄
后的）区间预测与真实执行逐一对照——输出 `SOUND`。这是本
章要落地的第三个结论：**∇/Δ 改变的是精度，不改变可靠性；
偏松的预测仍然可靠。**

学完本章，读者应当能回答四组问题：

- 区间格上的朴素迭代为什么不终止？不终止在迭代序列上长什么
  样？（21.2）
- ∇ 的形式化定义要满足哪些性质？阈值表怎么选？加宽点为什
  么选循环头？为什么加了 ∇ 就必然终止？（21.3、21.4、
  21.5）
- Δ 的形式化定义是什么？为什么一趟收窄通常就够？（21.6）
- 条件精炼沿分支边做什么？它与 ∇/Δ 怎样协作，使收窄一趟
  就把循环头从 `[0,+∞]` 闭合到 `[0,10]`？（21.7、21.8、
  21.9）
- "预测区间包含真实执行值"为什么能证明可靠？精度的阶梯与
  可靠性的边界各是什么？（21.10、21.11）

本章的配套示例是 `examples/35_widening`，新增代码集中在
`widen.hpp` 与 `widen.cpp` 两个文件；前端（ANTLR 文法、AST、
名字解析、CFG）、区间格与区间算术（`interval.hpp/cpp`、
`lattice.hpp`）以及 LLVM IR 生成与 ORC 执行台
（`irgen.hpp/cpp`、`jitrun.hpp/cpp`）全部复用前几章的成
果，按字节复制，本章在 35.12 节统一说明它们的角色。

### 35.1.1 与 spa 原书章节的对应

spa 第 4 章在讲完单调框架、不动点存在性之后，用 4.7 与
4.8 两小节处理"格高度无限"的问题：4.7 给出 widening 的
定义、终止性论证与区间分析的阈值示例；4.8 给出 narrowing
并说明它在实践中常常只跑一遍。本章的理论骨架即这两小节，
例子换成 TIP 上一个完整可执行的 while 循环程序，并把书上
的伪代码落到我们自己的 `Lattice<Iv>` 与 round-robin 迭代器
上。条件精炼在 spa 中属于第 10 章"区间分析"一节的边语义，
本章把它提前与 ∇/Δ 放在一起讲，因为离开边精炼，本章的
收窄演示不会成立——35.7 节会详细解释这层依赖。

## 35.2 问题回顾：无限高的格与不终止的迭代

### 35.2.1 先把第 34 章的失败再看一遍

第 34 章的演示程序 loop.tip 是一个计数到 10 的循环：

```text
main() {
  var x;
  x = 1;
  while (x < 10) {
    x = x + 1;
  }
  output x;
  return 0;
}
```

朴素迭代从全部程序点取 ⊥ 开始，按节点号顺序一轮一轮地重
算每个点的流出状态。循环头（while 条件所在节点）上 x 的区
间按这样一条序列演化：

```text
[1,1] ⊑ [1,2] ⊑ [1,3] ⊑ … ⊑ [1,k] ⊑ …
```

每多迭代一轮，循环体多"被走通"一次，x 的上界就增加 1。
这就是"分析在模拟循环逐次展开"：第 k 轮的状态，近似的是
"循环最多执行 k 次"这一族执行。而真实程序的循环次数是有
限的（恰好 9 次），静态分析却不知道这个"恰好"——它只
能回答"对一切可能的执行"，而在方程被完全解出之前，"循环
可能再执行一次"永远不能被排除。

不终止的根子在格本身。回忆第 25 章证明 worklist 终止时用
的论据：格中每条严格上升链都有限——对符号格，链长至多为
格的高度（3 层）。区间格没有这个性质：对任意大的 k，
`[1,1] ⊏ [1,2] ⊏ … ⊏ [1,k]` 都是一条严格上升链，而且 k 没
有上界。格的**高度无穷**，"每次状态更新都沿严格上升链走
一步"不再能推出"更新次数有限"。第 28 章 worklist 的终止
证明在这里整体失效。

### 35.2.2 直觉：不动点存在，但我们到不了它

值得停下来分清三件被"不收敛"三个字混在一起的事情：

- **最小不动点存在**。区间格是完全格（任意子集都有上确
  界），传递函数单调，Knaster–Tarski 定理的两个条件都成
  立，方程组的最小不动点一定存在。事实上对上面的程序，答
  案我们闭着眼睛都知道：循环头 x∈[1,10]，输出点 x=10。
- **朴素迭代达不到它**。从 ⊥ 出发的逐轮迭代，极限确实是
  这个最小不动点——但"极限"在可数无穷多步之外。算法只有
  有限时间，我们需要一条有限长的路径到达某个不动点。
- **我们愿意接受更松的答案**。静态分析的用途是给出可靠的
  近似，不是给出唯一正确的答案。如果能用有限步达到一个
  "比最小不动点松、但仍然可靠"的不动点，在工程上完全可
  接受——松一点意味着少优化一点、少证明一点，不意味着出
  错。

widening 的全部设计都围绕这第三条：**人为加速上升序列，
让它几步就顶到一个（可能很松的）不动点；之后再想办法往回
收紧。**

### 35.2.3 直觉：跳台阶，只踩有限的几个刻度

想象一个人沿台阶往上走，台阶本身无限多级（这就是无限高的
格）。朴素迭代是一级一级走，永远走不完。widening 的办法
是：不一级一级走，而事先在台阶上刻有限多个**标记**——比
如只在地面、1 这个高度、以及"无穷高"三个地方刻标记；每
次想往上走时，不走到精确的下一级，而一步跨到"不低于目
标高度的最低标记"。

具体到第 34 章那条序列，在循环头对 x 做 widening：

```text
旧值 [1,1]，新值 [1,2]  → ∇ 一步跨到 [1,+∞)
```

为什么跨得这么狠？因为我们的标记只有有限几个，而"1 以上"
这个方向上唯一的标记就是 +∞。下一轮再算，新值（比如
[1,3]）不再超出 [1,+∞)，∇ 的结果不变——序列两步就稳定
了。迭代从"无限多级台阶"变成"最多踩遍所有标记"：标记有
限，步数就有限。

这自然引出三个设计问题，本章的形式化部分逐一回答：

1. 跨出去的那一步凭什么可靠？——∇ 的结果必须同时**大**
   于旧值和新值（21.3.1）。
2. 标记（阈值表）怎么选？——要在"足够少以保证终止"和
  "足够多以保住精度"之间权衡（21.3.3、21.4）。
3. 在哪些点上跨这一步？——不是每个程序点都需要 ∇；加宽
   点的选择决定精度与终止性（21.3.4）。

## 35.3 加宽的形式化

### 35.3.1 定义与两条基本性质

设 L 是完全格。算子 ∇: L × L → L 称为一个**加宽算子**
（widening operator），如果它满足：

**性质一（上界性）**。对任意 x, y ∈ L：

```text
x ⊑ x ∇ y，  且  y ⊑ x ∇ y
```

**性质二（有限上升链条件）**。对 L 中任意序列 y₀, y₁,
y₂, …，按下列递推构造的序列 x₀, x₁, x₂, … 在有限步内稳
定（存在 N，对所有 n ≥ N 有 xₙ = xₙ₊₁）：

```text
x₀ = y₀
xₙ₊₁ = xₙ ∇ yₙ₊₁     （当 yₙ₊ₑ ⊑ xₙ 时也可不做 ∇，直接取 xₙ）
```

性质一说的是直觉里"跨到不低于目标的标记"：∇ 的结果绝不
会比旧值 x 和本该采纳的新值 y 更"小"（信息更少）——因此
用 ∇ 替换 join 或直接赋值，得到的序列是朴素序列的"上界
序列"，不会漏掉任何事实，这是可靠性的形式基础。注意 ∇ **不
要求交换律、不要求结合律**：它不是格上的新运算，而是迭代
策略的一部分，参数顺序（旧值在前、新值在后）有意义。

性质二说的是终止性。它不要求 ∇ 本身在任何意义上"有限"，
而要求对**任何**输入序列，∇ 迭代都稳定——这比"对我们这
个程序稳定"强得多。21.3.3 节会看到，这条性质是怎样由阈值
表的有限性保证的。

### 35.3.2 widening 迭代在做什么

把 ∇ 嵌进第 34 章的 round-robin 迭代，差别只在加宽点：

```text
朴素：   headₙ₊₁ = headₙ ⊔ inₙ₊₁
widening：headₙ₊₁ = headₙ ∇ inₙ₊₁     （仅加宽点；其余点不变）
```

其中 inₙ₊₁ 是按原方程、用当前各点流出状态算出的"流入"
（前驱流出的 join）。由 ⊑ 的上界性质：

```text
headₙ ⊔ inₙ₊₁  ⊑  headₙ ∇ inₙ₊₁
```

所以 widening 序列每一步都在朴素序列之上——它"涨得更快"。
涨得快不是目的，**涨到顶后不动**才是：一旦 head 在 ∇ 之
后不再变化，且其余点本就在有限高的"非加宽部分"上迭代，
整轮扫描没有变化，算法终止。终止时的状态是方程组某个不动
点（验证：一轮扫描结果不变 ⇒ 每个点的方程都被满足），而
且是最小不动点的**上界**（每一步都在朴素序列之上）。这两
句话——"是不动点"和"在最小不动点之上"——合起来就是
widening 的正确性契约：答案可靠，但可能偏松。

### 35.3.3 区间上的 ∇：阈值表

现在把抽象定义落到区间格。第 34 章的区间：

```text
Iv = [lo, hi]，lo, hi ∈ ℤ ∪ {−∞, +∞}，lo ≤ hi；lo > hi 表示 ⊥
```

选一个有限的**阈值集合**（thresholds）。本章的实现取：

```text
T = {−∞, 0, 1, +∞}
```

∇ 对两个端点分别处理。给定旧区间 a = [aₗ, aₕ]，新区间
b = [bₗ, bₕ]：

```text
若 bₗ ≥ aₗ：下界不动。
若 bₗ < aₗ：新下界取 T 中"不大于 bₗ 的最大阈值"。
若 bₕ ≤ aₕ：上界不动。
若 bₕ > aₕ：新上界取 T 中"不小于 bₕ 的最小阈值"。
⊥ 情形：a 为 ⊥ 时直接取 b（第一次赋值不跳变）。
```

用 35.2 节的例子验证：a = [1,1]，b = [1,2]。下界 bₗ=1 不
小于 aₗ=1，不动；上界 bₕ=2 > aₕ=1，T 中不小于 2 的最小阈
值是 +∞，故 a ∇ b = [1,+∞)。再下一轮 b = [1,3]，bₕ=3 不大
于 +∞，不动——稳定。无限长的链，两步走完。

再验证性质一。下界只在 bₗ<aₗ 时改变，取的是 **不大于 bₗ**
的阈值，故新下界 ≤ bₗ 且 ≤ aₗ?——不，新下界 ≤ bₗ < aₗ，即
新下界在数值上更小，在序上更松，因此结果同时包含 a 与 b：
端点没被跳过的那一侧与旧值相同，跳过的那一侧跨到阈值之外
（含住新值）。上界对称。性质一成立。

性质二由阈值表的有限性推出。加宽点上，下界每变一次，都从
一个阈值移到另一个**严格更小**的阈值；上界则移到严格更大
的阈值。阈值有限，每个端点至多改变 |T|−1 次。多个变量、多
个加宽点的情形，对"变量 × 端点"逐个计数：每一步 ∇ 若改变
状态，至少有一个端点在阈值间移动，总移动次数有界 ⇒ ∇ 改变
状态的次数有界 ⇒ 序列有限步稳定。这就是性质二的全部论证，
也是第 28 章"严格上升链有限则迭代终止"的替代物：**自然的
链无限，但 ∇ 之后的链只经过有限多个阈值。**

### 35.3.4 阈值表与加宽点的选择

阈值表是 widening 精度的主要旋钮，取舍很直接：

- 阈值越**少**，每次跨得越狠，终止越快、结果越松。极端取
  T = {−∞,+∞}：任何增长都一步到 ±∞——必然终止，但 widening
  几乎不给出任何有限界。
- 阈值越**多**，跨得越精细。比如把程序中出现的所有常量都
  放进 T（`{−∞, 0, 1, 10, +∞}`），a=[1,1]、b=[1,2] 仍跨到
  +∞，但 b=[1,10] 时能停在 10——收窄之前就保住了上界。
  阈值仍然有限（程序中常量有限），终止性不受影响。
- 工程实践常见做法：**把程序里所有数值常量、以及 0/1 自动
  收进阈值表**。本章的教学实现刻意只用 `{−∞,0,1,+∞}`，让
  widening 把上界放到 +∞，再由 narrowing 与边精炼把 10 找
  回来——这样 ∇ 与 Δ 各自的贡献在输出里都看得见。

加宽点（widening points）的选择同样有讲究：

- **为什么不是每个点都 ∇？** ∇ 是有损操作。在直线代码上
  ∇ 毫无收益（节点只有一个前驱、状态只算一次，本来就终
  止），反而可能把精确结果跳松。
- **为什么是循环头？** 不终止只可能由环引起；沿任何环走
  一圈，至少要在环上的一个点做 ∇，该环上的迭代才有有限
  长度。对 while 程序，循环头（条件节点）是每个环的必经
  点，在头上 ∇ 一次，环上其余点的状态都从头推出，精度损
  失集中在一处，也最容易事后收窄。
- 一般结论（widening point theorem）：在 CFG 的每个环的
  某个节点（取一组"割点"）上施加 ∇，即可保证终止。嵌套
  循环、多个环共享节点等情形按这一原则推广；本章的程序只
  有一个循环，加宽点集合就是全部 while 条件节点。

### 35.3.5 一个形式化的小结

把上面几节压成一句话：widening 不修改方程组，它修改的是
**迭代算子**——把加宽点上的 join（⊔）换成 ∇。∇ 的上界性
保证新序列是朴素序列的上界（可靠），阈值表的有限性保证新
序列有限步稳定（终止），终止状态是原方程组某个位于最小不
动点之上的不动点（是答案，只是偏松）。35.4 节看这套形式
化怎样逐行变成 C++。

## 35.4 加宽算子的代码落地

### 35.4.1 widen.hpp：本章新增设施的总貌

本章所有新增代码都声明在 widen.hpp 中。先把这个文件完整
嵌入，然后自本节起逐组讲解：本文件里与 ∇ 直接相关的是
`widen` 函数与 `WidenedResult` 结构；`narrow`、
`refineOnBranch` 与 `narrowPass` 分别在 21.6、35.7 节讲。

```cpp
// file: src/widen.hpp
// 第 35 章配套：widening ∇ 与 narrowing Δ（spa 4.7/4.8 的区间版落地）。
// 区间格高度无穷，朴素迭代不终止；∇ 在加宽点（循环头）把发散的链
// 强行压到阈值表 {-inf,0,1,+inf} 上，有限步收敛但代价是过松；
// Δ 用原方程从 ∇ 解出发再推一遍，只把 ±∞ 处的界收回有限值。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "interval.hpp"

namespace tip {

// 单个区间的加宽/收窄算子（正文给出阈值表与规则）。
Iv widen(const Iv &a, const Iv &b);
Iv narrow(const Iv &a, const Iv &b);

// 条件精炼：进入 (x > k) 的"真"边时 x 的下界提到 k+1，
// 走"假"边时上界压到 k；(x == k) 的真边把 x 钉成 [k,k]。
IvEnv refineOnBranch(const Expr *cond, const IvEnv &env, bool taken);

struct WidenedResult {
    bool converged = false;
    int rounds = 0;
    int headNode = -1;                 // 循环头（加宽点）节点号
    std::vector<std::string> trace;    // 每轮循环头环境（∇ 已施加）
    std::map<int, IvEnv> out;          // ∇ 不动点的流出状态
};

// 带加宽的 round-robin 求解：加宽点 = 全部 while 条件节点。
WidenedResult solveWidenedInterval(const Cfg &cfg, const ProgramA &program,
                                   int maxRounds);

// 一次收窄：从 ∇ 解出发按原方程重推一遍，用 Δ 规则只收 ±∞ 端。
// 返回收窄后的流出状态（键与 widened 相同）。
std::map<int, IvEnv> narrowPass(const Cfg &cfg, const ProgramA &program,
                                const std::map<int, IvEnv> &widened);

std::string printIvEnv(const IvEnv &env, const std::set<std::string> &keys);

}  // namespace tip
```

声明的形状与 35.3 节的形式化一一对应：`widen(a,b)` 是
L×L→L 的算子（这里 L 是单个区间，环境上的 ∇ 由逐变量调
用实现）；`WidenedResult` 除了结果状态 `out`，还带着
`converged`、`rounds`、`headNode` 与 `trace`——后四者让迭
代过程本身可观察，35.5 节的轨迹分析直接使用它们。

### 35.4.2 widen 函数：阈值分支逐条对应形式化

`widen` 的实现只有二十来行，但每个分支都值得与 21.3.3 节
的规则对一次。它在 widen.cpp 中，和本章其他实现一起将在
21.4.4 节完整嵌入；先看 ∇ 本体：

```cpp
Iv widen(const Iv &a, const Iv &b) {
    if (a.lo > a.hi) return b;  // 旧值为 ⊥：直接采用新值，不跳阈值
    if (b.lo > b.hi) return a;
    Iv r = a;
    if (b.lo < a.lo) {
        // 下界阈值表 {-inf, 0, 1}：取不超过新下界的最大阈值。
        if (b.lo >= 1)
            r.lo = 1;
        else if (b.lo >= 0)
            r.lo = 0;
        else
            r.lo = INT_MIN;
    }
    if (b.hi > a.hi) {
        // 上界阈值表 {1, 0, +inf}：取不低于新上界的最小阈值。
        if (b.hi <= 0)
            r.hi = 0;
        else if (b.hi <= 1)
            r.hi = 1;
        else
            r.hi = INT_MAX;
    }
    return r;
}
```

第一行处理 ⊥：上一轮该加宽点还没有状态（a 为 ⊥），第一次
到达时直接采用新值 b，不跳阈值。这与形式化里"x₀ = y₀"对
应——没有旧值可跨，∇ 的第一条链节必须是精确的；否则连初
始赋值都会被跳成 ±∞。第二行处理新值为 ⊥ 的情形（本次流入
为空，比如所有前驱都还没算），保留旧值 a，等待下一轮。

下界分支是 21.3.3 阈值规则的直译：只有当新下界 bₗ 真的更
小（bₗ<aₗ）才动作；动作时按"不大于 bₗ 的最大阈值"选——
bₗ 还在 1 或以上，选 1；落到 0 与 1 之间，选 0；一旦需要
负数，直接 −∞（阈值表里负数方向只有 −∞）。注意选择方向的
不对称：下界取**不大于**新值的最大阈值，因此结果在数值上
≤ 新下界，区间只会更宽，不会把新值排除在外。上界分支对称
地取**不小于**新上界的最小阈值（0、1、+∞ 三档）。这就是
21.3.1 性质一（上界性）的代码兑现：每个分支要么不动，要么
跨到含住新值的阈值。

### 35.4.3 求解器：加宽点集合与逐变量 ∇

求解器 `solveWidenedInterval` 沿用第 34 章的 round-robin
骨架，改动有两处。第一处是确定加宽点集合：

```cpp
// 加宽点：所有 while 条件节点。
std::set<int> widenPoints;
for (const FunCfg &fc : cfg.funs)
    for (const auto &[id, node] : fc.nodes)
        if (dynamic_cast<const WhileS *>(node.stmt)) {
            widenPoints.insert(id);
            if (res.headNode < 0) res.headNode = id;
        }
```

判定方式是看节点 stmt 是否指向一个 `WhileS`——CFG 构造器
把 while 语句建成 Branch 节点并把原语句透传在 `stmt` 上
（第 14 章），因此不需要给 `CfgNode` 加任何新字段。第一个
while 节点同时记为 `headNode`，供轨迹打印使用。这对应
21.3.4 的结论：加宽点取每个环的必经点；对 while 程序就是
条件节点。

第二处改动是每轮在加宽点上用 ∇ 替换 join：

```cpp
if (widenPoints.count(id)) {
    // 加宽点：与上一轮状态逐变量做 ∇。
    auto prev = out.find(id);
    if (prev != out.end())
        for (auto &[k, v] : in) {
            Iv pv = prev->second.count(k) ? prev->second.at(k)
                                          : lat.bot();
            v = widen(pv, v);
        }
}

IvEnv o = in;
if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
    if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
        o[t->name] = evalIv(a->value.get(), in);
```

对照 21.3.2 的递推式 `headₙ₊₁ = headₙ ∇ inₙ₊₁`：`in` 是
按原方程（前驱 join、沿边精炼——见 21.7）算出的新流入；
`pv` 是该点上一轮的状态，变量缺失按 ⊥ 处理（正是 widen
函数里"旧值 ⊥ 直接取新值"那条规则的环境版）。逐变量做
∇ 后，环境在加宽点上只可能踩到阈值。加宽点之外（含赋值传
递 `o[t]=evalIv(...)`）一切照旧——直线部分的精度被完整保
留。

其余骨架——round-robin 按节点号扫描、每轮比较新旧状态、
无变化即 `converged`、循环头轨迹写入 `trace`——与第 34 章 `runNaiveInterval` 完全相同，这里不再重复，21.4.4 节
的完整文件中可以逐行核对。

### 35.4.4 widen.cpp 完整嵌入

下面把 widen.cpp 完整嵌入。这个文件还包含 35.6 节的
narrowPass、35.7 节的条件识别（`CondFact`/`parseCond`/
`refineOnBranch`）以及 35.8 节的 `LocalWiring`；本节阅读时
只需关注已讲解的部分，其余留到对应小节。

```cpp
// file: src/widen.cpp
#include "widen.hpp"

#include <algorithm>
#include <set>
#include <sstream>

namespace tip {
namespace {

// ---- 条件识别：把 (x > k)/(k > x)/(x == k) 归一成 {变量, 界, 比较种类} ----
enum CondKind { Cgt, Clt, Ceq };
struct CondFact {
    std::string var;
    int k = 0;
    CondKind kind = Cgt;
    bool ok = false;
};

CondFact parseCond(const Expr *cond) {
    CondFact f;
    const auto *b = dynamic_cast<const Binop *>(cond);
    if (!b) return f;
    const auto *x = dynamic_cast<const VarRef *>(b->l.get());
    const auto *c = dynamic_cast<const IntLit *>(b->r.get());
    if (!x || !c) {
        x = dynamic_cast<const VarRef *>(b->r.get());
        c = dynamic_cast<const IntLit *>(b->l.get());
    }
    if (!x || !c) return f;
    f.var = x->name;
    f.k = c->v;
    switch (b->op) {
        case BOp::Gt:
            // 原式 (x > k) 或 (k > x)：后者按 (x < k) 归一。
            f.kind = (b->l.get() == x) ? Cgt : Clt;
            f.ok = true;
            break;
        case BOp::Eq:
            f.kind = Ceq;
            f.ok = true;
            break;
        default:
            break;
    }
    return f;
}

// ---- CFG 构造器编号/连线规则的局部重建：拿到每个分支真/假边的目标 ----
// cfg.cpp 用"先序编号 + 语句透传"构造图且边不带标签；本章不动共享的
// cfg.hpp（前几章文档已按字节嵌入它），按同一规则重推一份。
struct BranchEdges {
    std::map<int, int> trueOf, falseOf;  // 分支节点号 → 真/假边目标
};

class LocalWiring {
public:
    BranchEdges run(const ProgramA &program) {
        for (const auto &fun : program.funs) {
            next_ = 2;  // entry 固定为 1
            id_.clear();
            number(fun->body.get());
            const int retId = next_++;  // 与 cfg.cpp 相同：return、exit 收尾
            (void)next_;
            wire(fun->body.get(), {retId});
        }
        return edges_;
    }

private:
    BranchEdges edges_;
    int next_ = 2;
    std::map<const Stmt *, int> id_;

    // 第一遍：先序编号（与 cfg.cpp 的 numberStmt 逐条对应）。
    void number(const Stmt *s) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            for (const auto &x : b->ss) number(x.get());
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            id_[x] = next_++;
            number(x->then.get());
            if (x->els) number(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            id_[x] = next_++;
            number(x->body.get());
            return;
        }
        if (dynamic_cast<const AssignS *>(s) || dynamic_cast<const OutputS *>(s))
            id_[s] = next_++;
    }

    // 第二遍：连边（与 cfg.cpp 的 wireStmt 逐条对应；入口点恒为单点）。
    std::vector<int> wire(const Stmt *s, std::vector<int> succ) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            std::vector<int> cur = succ;
            for (auto it = b->ss.rbegin(); it != b->ss.rend(); ++it)
                cur = wire(it->get(), cur);
            return cur;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            const int n = id_.at(x);
            std::vector<int> targets = wireOrSelf(x->then.get(), succ);
            edges_.trueOf[n] = targets[0];
            std::vector<int> rest;
            if (x->els)
                rest = wireOrSelf(x->els.get(), succ);
            else
                rest = succ;
            edges_.falseOf[n] = rest[0];
            return {n};
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            const int n = id_.at(x);
            std::vector<int> bodyEntries = wireOrSelf(x->body.get(), {n});
            edges_.trueOf[n] = bodyEntries[0];
            edges_.falseOf[n] = succ[0];
            return {n};
        }
        return {id_.at(s)};
    }
    std::vector<int> wireOrSelf(const Stmt *s, std::vector<int> succ) {
        std::vector<int> r = wire(s, succ);
        if (r.empty()) r = succ;
        return r;
    }
};

// 分支节点携带的 cond 表达式（非分支语句返回空）。
const Expr *condOf(const Stmt *s) {
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return w->cond.get();
    if (const auto *i = dynamic_cast<const IfS *>(s)) return i->cond.get();
    return nullptr;
}

}  // namespace

Iv widen(const Iv &a, const Iv &b) {
    if (a.lo > a.hi) return b;  // 旧值为 ⊥：直接采用新值，不跳阈值
    if (b.lo > b.hi) return a;
    Iv r = a;
    if (b.lo < a.lo) {
        // 下界阈值表 {-inf, 0, 1}：取不超过新下界的最大阈值。
        if (b.lo >= 1)
            r.lo = 1;
        else if (b.lo >= 0)
            r.lo = 0;
        else
            r.lo = INT_MIN;
    }
    if (b.hi > a.hi) {
        // 上界阈值表 {1, 0, +inf}：取不低于新上界的最小阈值。
        if (b.hi <= 0)
            r.hi = 0;
        else if (b.hi <= 1)
            r.hi = 1;
        else
            r.hi = INT_MAX;
    }
    return r;
}

Iv narrow(const Iv &a, const Iv &b) {
    if (a.lo > a.hi || b.lo > b.hi) return b;  // ⊥ 不收
    Iv r = a;
    if (a.lo == INT_MIN && b.lo > a.lo) r.lo = b.lo;
    if (a.hi == INT_MAX && b.hi < a.hi) r.hi = b.hi;
    return r;
}

IvEnv refineOnBranch(const Expr *cond, const IvEnv &env, bool taken) {
    CondFact f = parseCond(cond);
    if (!f.ok) return env;
    IvEnv out = env;
    auto it = out.find(f.var);
    if (it == out.end()) return out;  // ⊥ 变量无可精炼
    Iv v = it->second;
    if (v.lo > v.hi) return out;
    switch (f.kind) {
        case Cgt:  // x > k
            if (taken)
                v.lo = std::max(v.lo, f.k == INT_MAX ? INT_MAX : f.k + 1);
            else
                v.hi = std::min(v.hi, f.k);
            break;
        case Clt:  // x < k
            if (taken)
                v.hi = std::min(v.hi, f.k == INT_MIN ? INT_MIN : f.k - 1);
            else
                v.lo = std::max(v.lo, f.k);
            break;
        case Ceq:  // x == k：真边钉成 [k,k]；假边保守不动
            if (taken) {
                if (f.k < v.lo || f.k > v.hi)
                    v = Iv{1, 0};  // 与区间矛盾 → 该边不可达
                else
                    v = Iv{f.k, f.k};
            }
            break;
    }
    it->second = v;
    return out;
}

WidenedResult solveWidenedInterval(const Cfg &cfg, const ProgramA &program,
                                   int maxRounds) {
    Lattice<Iv> lat = ivLattice();
    WidenedResult res;

    // 加宽点：所有 while 条件节点。
    std::set<int> widenPoints;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (dynamic_cast<const WhileS *>(node.stmt)) {
                widenPoints.insert(id);
                if (res.headNode < 0) res.headNode = id;
            }

    BranchEdges be = LocalWiring().run(program);
    const FunCfg &fc = cfg.funs[0];

    struct PredEdge {
        int node;
        bool refine;
        bool taken;
    };
    std::map<int, std::vector<PredEdge>> preds;
    for (const auto &[a, b] : fc.edges) {
        PredEdge pe{a, false, true};
        if (be.trueOf.count(a) && be.trueOf[a] == b) pe = PredEdge{a, true, true};
        if (be.falseOf.count(a) && be.falseOf[a] == b)
            pe = PredEdge{a, true, false};
        preds[b].push_back(pe);
    }

    std::set<std::string> vars(program.funs[0]->vars.begin(),
                               program.funs[0]->vars.end());

    // 流入 = 各前驱流出（沿边精炼后）之并；无前驱点取空（参数在下方补全区间）。
    auto computeIn = [&](int p, const std::map<int, IvEnv> &out) {
        IvEnv in;
        auto pit = preds.find(p);
        if (pit != preds.end()) {
            for (const PredEdge &pe : pit->second) {
                IvEnv piece;
                auto it = out.find(pe.node);
                if (it != out.end()) piece = it->second;
                if (pe.refine)
                    piece = refineOnBranch(condOf(fc.nodes.at(pe.node).stmt),
                                           piece, pe.taken);
                for (const auto &[k, v] : piece)
                    in[k] = lat.join(in.count(k) ? in[k] : lat.bot(), v);
            }
        }
        return in;
    };

    std::map<int, IvEnv> out;
    for (int round = 0; round < maxRounds; ++round) {
        bool changed = false;
        for (const auto &[id, node] : fc.nodes) {
            IvEnv in = computeIn(id, out);
            // entry 边界：参数视为全区间。
            for (const std::string &p : program.funs[0]->params)
                in[p] = Iv{INT_MIN, INT_MAX};

            if (widenPoints.count(id)) {
                // 加宽点：与上一轮状态逐变量做 ∇。
                auto prev = out.find(id);
                if (prev != out.end())
                    for (auto &[k, v] : in) {
                        Iv pv = prev->second.count(k) ? prev->second.at(k)
                                                      : lat.bot();
                        v = widen(pv, v);
                    }
            }

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
            IvEnv head = out.count(res.headNode) ? out[res.headNode] : IvEnv{};
            res.trace.push_back("iter " + std::to_string(round) + ": " +
                                printIvEnv(head, vars));
        }
        if (!changed) {
            res.converged = true;
            break;
        }
    }
    res.out = out;
    return res;
}

std::map<int, IvEnv> narrowPass(const Cfg &cfg, const ProgramA &program,
                                const std::map<int, IvEnv> &widened) {
    Lattice<Iv> lat = ivLattice();
    const FunCfg &fc = cfg.funs[0];

    BranchEdges be = LocalWiring().run(program);
    struct PredEdge {
        int node;
        bool refine;
        bool taken;
    };
    std::map<int, std::vector<PredEdge>> preds;
    for (const auto &[a, b] : fc.edges) {
        PredEdge pe{a, false, true};
        if (be.trueOf.count(a) && be.trueOf[a] == b) pe = PredEdge{a, true, true};
        if (be.falseOf.count(a) && be.falseOf[a] == b)
            pe = PredEdge{a, true, false};
        preds[b].push_back(pe);
    }

    std::map<int, IvEnv> out = widened;
    for (const auto &[id, node] : fc.nodes) {
        IvEnv in;
        auto pit = preds.find(id);
        if (pit != preds.end()) {
            for (const PredEdge &pe : pit->second) {
                IvEnv piece;
                auto it = out.find(pe.node);
                if (it != out.end()) piece = it->second;
                if (pe.refine)
                    piece = refineOnBranch(condOf(fc.nodes.at(pe.node).stmt),
                                           piece, pe.taken);
                for (const auto &[k, v] : piece)
                    in[k] = lat.join(in.count(k) ? in[k] : lat.bot(), v);
            }
        }
        // Δ 规则：与加宽解逐变量收窄，只把 ±∞ 处的界收回有限值。
        for (auto &[k, v] : in) {
            Iv pv = widened.count(id) && widened.at(id).count(k)
                        ? widened.at(id).at(k)
                        : lat.bot();
            v = narrow(pv, v);
        }

        IvEnv o = in;
        if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
            if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                o[t->name] = evalIv(a->value.get(), in);
        out[id] = o;
    }
    return out;
}

std::string printIvEnv(const IvEnv &env, const std::set<std::string> &keys) {
    std::ostringstream out;
    bool first = true;
    for (const std::string &k : keys) {
        if (!first) out << " ";
        out << k << "="
            << (env.count(k) ? ivText(env.at(k)) : std::string("bottom"));
        first = false;
    }
    return out.str();
}

}  // namespace tip
```

## 35.5 完整迭代轨迹：四轮收敛

现在在本章真正的演示程序 widen.tip 上，把求解器跑的每一步
手工推演一遍。程序是：

```text
main() {
  var x;
  x = 0;
  while (10 > x) {
    x = x + 1;
  }
  output x;
  return 0;
}
```

注意条件写成 `10 > x`（即 x < 10），而不是第 34 章的
`x < 10`——TIP 文法没有 `<`，需要反方向写。CFG 构造器给
出的节点编号（第 14 章规则：entry=1，函数体先序编号，
return、exit 收尾）：

```text
1：entry
2：x = 0
3：while (10 > x)        分支；真边 → 4，假边 → 5
4：x = x + 1
5：output x
6：return 0
7：exit
边：1→2，2→3，3→4，3→5，4→3，5→6，6→7
```

节点 3 是唯一的加宽点。沿边精炼（35.7 节详解）在 3→4 真边
上施加"x<10"（上界 9），在 3→5 假边上施加"x≥10"（下界
10）。带着这些，逐轮推演。

### 35.5.1 第 0 轮：初始事实到达各点

- 节点 1：空环境。节点 2：流入空，赋值 x=0 ⇒ `{x:[0,0]}`。
- 节点 3：前驱只有 2 有状态，流入 `{x:[0,0]}`。上一轮该点
  不存在（prev 缺失），不做 ∇；条件节点不改变环境，流出
  `{x:[0,0]}`。
- 节点 4：流入来自 3 的真边：`[0,0]` 经"x<10"精炼仍是
  `[0,0]`；x+1 ⇒ `{x:[1,1]}`。
- 节点 5：流入来自 3 的假边：`[0,0]` 经"x≥10"精炼，下界
  提为 10 ⇒ `[10,0]`（lo>hi，⊥）——"x=0 时退出循环"不
  成立，该边此刻不可达。
- 轨迹：`iter 0: x=[0,0]`。

### 35.5.2 第 1 轮：循环体回流一次

- 节点 3：前驱为 2（`[0,0]`）与 4（`[1,1]`），流入
  join = `[0,1]`。与上一轮 `[0,0]` 做 ∇：下界不动，上界
  1>0——阈值表里不小于 1 的最小阈值是 **1**（不是 +∞！）
  ⇒ `[0,1]`。
- 节点 4：真边精炼：`[0,1]` 与 x<10 取交仍是 `[0,1]`；
  x+1 ⇒ `[1,2]`。
- 节点 5：假边精炼：`[0,1]` 提下界为 10 ⇒ `[10,1]` 仍为
  ⊥。
- 轨迹：`iter 1: x=[0,1]`。

这一步值得停一停：上界只涨到 1 而不是 +∞，因为阈值表里
**有 1 这个刻度**。21.3.3 节特意保留 0、1 两个有限阈值，
保住了"循环头 x 至少能从 0 走到 1"这一级的精度；真正的
大跳变在下一轮。

### 35.5.3 第 2 轮：∇ 一步跨到 +∞

- 节点 3：前驱 2 的 `[0,0]` 与节点 4 的 `[1,2]` join =
  `[0,2]`。与上一轮 `[0,1]` ∇：上界 2>1，阈值表中不小于 2
  的只有 +∞ ⇒ `[0,+∞]`。
- 节点 4：真边精炼：`[0,+∞]` 与 x<10 取交 ⇒ `[0,9]`；
  x+1 ⇒ `[1,10]`。
- 节点 5：假边精炼：`[0,+∞]` 提下界为 10 ⇒ `[10,+∞]`。
- 轨迹：`iter 2: x=[0,+∞]`。

这里出现了本章最关键的一个中间结果：节点 4 的流出是
**`[1,10]`，不是 `[1,+∞)`**。虽然循环头被 ∇ 放宽到了
+∞，但真边上的条件精炼把它重新截到 9，加 1 后恰好是 10。
这个有限上界是 narrowing 一趟成功的钥匙——35.6 节会看到
它怎样被节点 3 的收窄直接使用。

### 35.5.4 第 3 轮：稳定

- 节点 3：前驱 join（`[0,0]` 与 `[1,10]`）= `[0,10]`。与
  上一轮 `[0,+∞]` ∇：新上界 10 不大于 +∞，下界不动 ⇒
  `[0,+∞]` 不变。
- 节点 4、5 输入不变，结果不变。整轮无变化 ⇒
  **CONVERGED，4 轮结束**。

widening 结果：循环头 x=`[0,+∞]`，输出点（节点 5 的环境
为 `[10,+∞]`，输出表达式就是 x）预测 `[10,+∞]`。与第 34 章 50 轮不收敛对照：同一份方程，只在一个点上把 join 换成
∇，无限序列变成 4 步。但答案松了——头本应是 `[0,10]`，
输出本应是 10。35.6 节把这两块精度找回来。

## 35.6 收窄：从 ∇ 解出发把 ±∞ 拉回有限界

### 35.6.1 Δ 的形式化定义

∇ 给出的不动点可靠但偏松。能不能从它出发，用原方程再推
一遍，看松掉的界能不能自己收紧？直接重推有风险：重新做
join 的朴素迭代可能再次不终止。Cousot 的方案是配一个
**收窄算子**（narrowing operator）Δ: L × L → L，满足：

**性质一**。对任意 x, y：

```text
若 y ⊑ x，则 y ⊑ x Δ y ⊑ x
```

**性质二（有限下降链条件）**。与 ∇ 对称：对任意序列，按

```text
xₙ₊₁ = xₙ Δ yₙ₊₁
```

构造的序列有限步稳定。

性质一限定了 Δ 的使用语境：x 是上一轮（偏松的）值，y 是
按原方程用 x 推出的新值，理论上 y 应当 ⊑ x（因为 x 已是不
动点附近的上界）。Δ 的结果必须夹在 y 与 x 之间——不能比
y 更松（收了白收），也不能比 x 更紧到越过 y（那会跌破方
程、破坏可靠性）。与 ∇ 一样，Δ 不要求交换律，旧值在前。

### 35.6.2 区间上的 Δ：只收 ±∞ 端

本章实现的区间收窄规则极其克制：

```text
给定旧区间 a（∇ 解）、新算出的 b（y）：
仅当 a 的下界是 −∞ 且 b 的下界有限时，下界取 b 的下界；
仅当 a 的上界是 +∞ 且 b 的上界有限时，上界取 b 的上界；
其余一律不动。⊥ 不收。
```

代码即 widen.cpp 中的 `narrow`：

```cpp
Iv narrow(const Iv &a, const Iv &b) {
    if (a.lo > a.hi || b.lo > b.hi) return b;  // ⊥ 不收
    Iv r = a;
    if (a.lo == INT_MIN && b.lo > a.lo) r.lo = b.lo;
    if (a.hi == INT_MAX && b.hi < a.hi) r.hi = b.hi;
    return r;
}
```

为什么只收 ±∞ 端？两点理由：

- **终止性**。有限界之间不互相跳，每个端点至多改变一次
  （从 ±∞ 到某个有限值），性质二自动成立。若允许有限界
  继续收紧（比如 10 收到 9、9 收到 8……），就重新滑回了
  朴素迭代的无限链。
- **保守性换正确性**。规则之简单，使 Δ 的可靠性几乎不用
  单独证明：它要么不动，要么把一个无穷界替换成"原方程推
  出的、含在该无穷界内的有限界"——替换后仍是方程合法的
  上界（性质一）。代价是 ∇ 造成的有限界处的精度损失，Δ
  不负责修复。

### 35.6.3 一趟收窄的逐点推演

narrowPass 从 ∇ 解出发，按节点号升序扫描一遍，每点用原方
程（同样含边精炼）重算流入，再与该点的 ∇ 值做 Δ。用
21.5 的 widening 结果（节点 2: `[0,0]`；3: `[0,+∞]`；
4: `[1,10]`；5: `[10,+∞]`）推演：

- 节点 3：前驱 2 的 `[0,0]` 与前驱 4 的 `[1,10]`
  join = `[0,10]`。与 ∇ 值 `[0,+∞]` Δ：上界是 +∞ 且新上界
  10 有限 ⇒ **上界收为 10**；下界 0 本就有限，不动 ⇒
  `[0,10]`。
- 节点 4：流入来自节点 3 的真边精炼：`[0,10]` 与 x<10 取交
  ⇒ `[0,9]`。与 ∇ 值 `[1,10]` Δ：两端都有限，**不动** ⇒
  赋值后 `[1,10]`。
- 节点 5：假边精炼：`[0,10]` 提下界为 10 ⇒ `[10,10]`。与
  ∇ 值 `[10,+∞]` Δ：上界 +∞、新上界 10 有限 ⇒ **收为
  10** ⇒ `[10,10]`。

收窄结果：循环头 x=`[0,10]`，输出点预测 `[10,10]`。对照
35.9 节的真实输出（`after NARROW: head x=[0,10]  output
x=[10,10]`）完全一致——∇ 丢掉的两块精度，Δ 一趟全部找
回。

### 35.6.4 为什么一趟就够：依赖方向决定的

注意 21.6.3 里一个容易滑过去的细节：节点 3 收窄时，用的是
节点 4 的 **∇ 值 `[1,10]`**，而这个值已经是精确的——它在
widening 阶段就被真边精炼截成了有限上界（21.5.3）。因此
按节点号升序扫描时，排在 3 前面处理的节点 4 不需要先收
窄，3 就能一步闭合。这不是巧合：

- 环上的信息沿"4→3"回传，而 4 的精确性来自不涉及环的边
  精炼（条件 x<10 直接给出 9）。∇ 只在 3 一处放宽，环上
  其余点的精度从未丢失，Δ 只需修 3（以及与 3 同环境的 5）
  一个点。
- 一般情形，Δ 可能需要迭代多趟：上一趟收紧的点为下一趟
  提供更紧输入，直到稳定（有限下降链保证终止）。spa 4.8
  指出，实践中**绝大多数区间分析跑一趟 Δ 就达到实用精
  度**，多趟的收益递减。本章的教学实现只跑一趟，输出里
  能直接验证"一趟够"是本例的结论而非普遍承诺。

还要点出一个反方向的风险：Δ 结果**不一定是不动点**。
21.6.3 的收窄解恰好满足方程（可手工验证：节点 3 前驱 join
=`[0,10]` 与其值相等），但一般情况下 Δ 提前终止时，结果
是最小不动点与 ∇ 解之间的某个可靠近似，不需要是不动点。
对静态分析的用途（成员检验、告警、优化前提）这已足够。

## 35.7 分支边上的条件精炼

### 35.7.1 边语义：条件在两侧各说一句话

区间沿 CFG 边传播，而条件语句在自己的两条出边上各留下一
个事实。对整数变量 x 与常量 k：

```text
(x > k)  真边：x ≥ k+1（lo 提为 k+1）；假边：x ≤ k（hi 压为 k）
(k > x)  即 x < k：真边 x ≤ k−1；假边 x ≥ k
(x == k) 真边：x = k（钉成 [k,k]）；假边：本章保守不动
```

规则是"区间与条件所描述的半直线取交"：真边的执行必然满
足条件，假边的执行必然不满足条件；取交之后的区间精确描
述沿这条边 x 的可能值。两个边界情形要处理：

- **k+1 溢出**。k = INT_MAX 时 k+1 不能表示；代码里特判
  取 INT_MAX（lo 提到顶，与 +∞ 同义）。下界方向 k=INT_MIN
  对称。
- **取交为空**。比如真边要求 x=k，但流入区间不含 k——
  这条边在当前抽象状态下不可达，结果应为 ⊥（lo>hi）。
  代码在 `x==k` 情形显式给 `Iv{1,0}`；比较运算的取交若
  数值上越过端点（如 21.5.1 假边 `[10,0]`）同样落到 ⊥，
  无需特殊处理。

假边上的 `x==k` 只告诉我们 x≠k，对一个区间来说"去掉一个
点"在区间格内无法精确表示（会得到两个区间），保守选择是
不精炼——这是精度让位于表示能力的一个小例子。

### 35.7.2 parseCond：把三种写法归一成一个事实

条件识别先把 `Binop` 归一成 `{变量, 常量, 种类}`：

```cpp
CondFact parseCond(const Expr *cond) {
    CondFact f;
    const auto *b = dynamic_cast<const Binop *>(cond);
    if (!b) return f;
    const auto *x = dynamic_cast<const VarRef *>(b->l.get());
    const auto *c = dynamic_cast<const IntLit *>(b->r.get());
    if (!x || !c) {
        x = dynamic_cast<const VarRef *>(b->r.get());
        c = dynamic_cast<const IntLit *>(b->l.get());
    }
    if (!x || !c) return f;
    f.var = x->name;
    f.k = c->v;
    switch (b->op) {
        case BOp::Gt:
            // 原式 (x > k) 或 (k > x)：后者按 (x < k) 归一。
            f.kind = (b->l.get() == x) ? Cgt : Clt;
            f.ok = true;
            break;
        case BOp::Eq:
            f.kind = Ceq;
            f.ok = true;
            break;
        default:
            break;
    }
    return f;
}
```

两处值得讲。第一，变量与常量可能在任一侧：先按"左变量、
右常量"试，失败再试反向。`10 > x` 因此能被识别，只是
种类记为 Clt。第二，种类的判定用 `b->l.get() == x`：变量
节点确实在左侧才是 Cgt，否则是 Clt——比较的方向由变量的
位置决定，不能只看运算符。识别失败（`ok=false`，比如
`x > y` 两个都是变量、或含算术的条件）时，精炼整体放弃，
区间原样传播：仍然可靠，只是少了一条信息。

### 35.7.3 refineOnBranch：取交的逐情形实现

精炼函数按归一后的种类更新区间：

```cpp
switch (f.kind) {
    case Cgt:  // x > k
        if (taken)
            v.lo = std::max(v.lo, f.k == INT_MAX ? INT_MAX : f.k + 1);
        else
            v.hi = std::min(v.hi, f.k);
        break;
    case Clt:  // x < k
        if (taken)
            v.hi = std::min(v.hi, f.k == INT_MIN ? INT_MIN : f.k - 1);
        else
            v.lo = std::max(v.lo, f.k);
        break;
    case Ceq:  // x == k：真边钉成 [k,k]；假边保守不动
        if (taken) {
            if (f.k < v.lo || f.k > v.hi)
                v = Iv{1, 0};  // 与区间矛盾 → 该边不可达
            else
                v = Iv{f.k, f.k};
        }
        break;
}
```

每个分支都是 21.7.1 表格的直译，用 `max/min` 实现区间与
半直线的取交；取不到交集（等号情形 k 在区间外）显式置
⊥。注意函数只精炼 f.var 这一个变量，环境中其余变量原样保
留；条件里若涉及多个变量（如 x>y），parseCond 已判定识别
失败，不会走到这里。

### 35.7.4 精炼在求解器里挂在哪里

条件精炼不是节点上的传递函数，而是**边函数**：它修改沿某
条边传递的那份状态。在求解器里，这体现为前驱表的每条边带
着 `refine/taken` 标记，computeIn 取出前驱流出后、join 之
前施加精炼：

```cpp
if (pe.refine)
    piece = refineOnBranch(condOf(fc.nodes.at(pe.node).stmt),
                           piece, pe.taken);
```

这一挂载位置解释了 35.5 节若干现象：节点 4 的流入在 join
之前先被真边截到 `[0,9]`，所以它的流出在 widening 期间就
是 `[1,10]`——边精炼与 ∇ 同时工作，一个在点上放宽、一个
在边上截紧。narrowPass 用同一套前驱表与挂载方式，保证
∇/Δ 两阶段看到的边语义完全一致。

## 35.8 LocalWiring：在不改 CFG 的前提下恢复边标签

### 35.8.1 问题：CFG 的边不带真/假标记

条件精炼需要知道：分支节点 3 的两条边，哪条是真边、哪条
是假边。但第 14 章冻结的 CFG 数据结构里，边只是
`(from,to)` 整数对，没有标签字段；CFG 构造器对 if/while 的
处理（`wireStmt`）把两个目标连出去，并不记录哪个是哪个。

有三种可能的修法：

1. 给 `CfgNode` 或边加 `trueOf/falseOf` 字段——但 cfg.hpp
  与 cfg.cpp 已在第 14 章文档中按字节嵌入、接口冻结，改动
  它要回改前面的章节与示例。
2. 在运行时维护"真 CFG + 影子分析"两份结构——重复且易分
  歧。
3. **按 CFG 构造器同样的规则，把编号与连边重推一遍，从
   连边过程中直接读出真/假目标。**本章采用这一方案，即
   `LocalWiring`。

### 35.8.2 为什么编号可以复制

`LocalWiring` 的可行性建立在一个事实上：CFG 的编号与连边
是**确定性规则**，不是构造器的私有状态。第 14 章的规则可以
完整复述：

```text
编号：entry=1；对函数体做 AST 先序遍历，
      每个语句按访问顺序取下一个号；return、exit 在最后收尾。
连边：块按逆序把后继逐句透传；
      if：分支节点连真分支入口、假分支入口（无 else 时假边即后继）；
      while：分支节点真边连循环体入口，假边连后继。
```

规则只依赖 AST 的形状，不依赖任何外部输入；同一段 AST 施
加规则必然得到同一张图。因此 LocalWiring 按同样规则跑一
遍，得到的编号与 CFG 构造器**逐点相同**——它不是在猜，
而是在重算。代码中两遍结构（`number` 先序编号、`wire` 逆
序连边）与 cfg.cpp 的 `numberStmt/wireStmt` 逐条对应，注释
里标明了这层对应关系。

### 35.8.3 LocalWiring 与 cfg.cpp 的两处有意差异

对照两份代码，LocalWiring 少做了两件事，都是本章不需要
的：

- 不建 entry/exit 节点，也不建 return 节点：`next_` 从 2
  起，函数体编号后只取一个 `retId` 作为透传终点。函数体
  各节点的号不受影响（return 节点本就排在函数体之后），
  对边匹配无影响。
- 不收集完整边集合，只在 `wire` 处理分支时，把真/假目标
  记入 `trueOf/falseOf` 两张表——这正是本章需要的全部产
  出。

而保证正确性的关键两处，则严格保持一致：编号起点与顺序
（先序、从 2 开始）、while 的真边连循环体入口、假边连后
继。这样 `BranchEdges` 给出的真假边与无标签的 `fc.edges`
在求解器里按目标节点号匹配（21.4.4 中构造 PredEdge 的两
个 if），每条分支边都能被正确标记。

这一做法的一般意义在于：**当共享设施缺少某项信息、而该
信息能由设施的确定性行为重新推出时，局部重推比修改共享
接口更稳。**代价是规则被复制了一份——如果未来 cfg.cpp 的
编号规则改变，LocalWiring 必须同步。35.13 节把这一点列为
工程注意点。

## 35.9 --check 真实输出逐行解读

把 widen.tip 交给本章的 tipa，`--check` 打印的完整输出如
下（文件嵌入在后），逐行解读：

```text
== interval lattice, widening (cap 50 rounds) then narrowing ==
widening point: loop head node 3
iter 0: x=[0,0]
iter 1: x=[0,1]
iter 2: x=[0,+inf]
iter 3: x=[0,+inf]
CONVERGED after 4 rounds (with widening)
after WIDEN : head x=[0,+inf]  output x=[10,+inf]
after NARROW: head x=[0,10]  output x=[10,10]
```

- 第一行说明本轮实验台身份：区间格、上限 50 轮的扫描器、
  先 ∇ 后 Δ。`cap 50` 是保险——有了 ∇，实际只用 4 轮。
- `widening point: loop head node 3`：加宽点节点号，与
  21.5 的编号图一致。
- 四行 `iter` 是循环头环境轨迹，对应 21.5.1–21.5.4 的推
  演：`[0,0] → [0,1] → [0,+∞] → [0,+∞]`。最后一行重复
  表示扫描已稳定——这正是"有限步稳定"在输出里的样子。
- `CONVERGED after 4 rounds`：与第 34 章 `DID NOT CONVERGE
  after 50 rounds` 直接对照。同一个 `maxRounds` 参数，结
  论完全翻转。
- 倒数第二行是 ∇ 解在两个观察点（循环头、第一个 output
  点）的预测：`[0,+∞]` 与 `[10,+∞]`。注意输出点已经比头
  精确——假边精炼把下界提为 10（21.5.3）。
- 最后一行是 Δ 之后：头闭合到 `[0,10]`，输出钉死为
  `[10,10]`。预测从"x 是不小于 10 的某个整数"精确到"x
  就是 10"——而 10 正是程序真实执行会输出的值，21.10
  节用 JIT 验证这一点。

嵌入期望输出全文：

```text
; expected: expected/output.txt
== widen.tip ==
== interval lattice, widening (cap 50 rounds) then narrowing ==
widening point: loop head node 3
iter 0: x=[0,0]
iter 1: x=[0,1]
iter 2: x=[0,+inf]
iter 3: x=[0,+inf]
CONVERGED after 4 rounds (with widening)
after WIDEN : head x=[0,+inf]  output x=[10,+inf]
after NARROW: head x=[0,10]  output x=[10,10]
```

输出最前面的 `== widen.tip ==` 是全教程示例对账协议
（check_example.py）加的文件名头，`--check` 本身不打印
它；它让一个示例含多个演示程序时各段输出可区分。

## 35.10 JIT 成员检验：可靠性的经验落地

### 35.10.1 方法论：成员关系，而非相等

第 29 章建立了可靠性经验检验的范式，本章直接复用并在区间
上获得了更强的表达。检验的逻辑是：

1. 对每个输入行，用 ORC JIT 把程序**真实执行**一遍，拿到
   output 语句的具体输出值；
2. 在分析结果中，找到同一 output 点、用该点（收窄后）环
   境对输出表达式抽象求值得到的预测区间；
3. 断言具体输出值**属于**预测区间（lo ≤ v ≤ hi）。

成员关系（membership）是区间版可靠性的正确形式：分析从不
承诺"输出等于某个值"，它承诺的是"输出必在我给出的集合
内"。一次执行只能产生集合中的一个元素，检验只能"没抓住反
例"而不能"证明对所有输入成立"——这是经验检验与形式证明
的边界，35.11 节再谈。值得强调的是，∇ 解同样可以做成员
检验（`[10,+∞]` 也包含 10）：**精度的差别是"区间多宽"，
可靠性的差别是"区间是否包含真值"；本章四档结果精度不同，
但都通过检验。**

### 35.10.2 检验台的实现要点

main.cpp 的 `--verify-soundness` 分支负责检验。关键的组织
有三处：

- **output 站点的收集**。CFG 节点状态按节点号查，但 JIT
  输出按执行顺序出现；代码用一次 AST 先序 Walk 把所有
  `OutputS` 按源码顺序收集，同时建 `stmt→节点号` 的映射，
  于是 JIT 的第 k 个输出、第 k 个站点、站点的节点号三者对
  齐。
- **每轮执行的 IR 现生成**。每个输入行都重新 `gen` 一个模
  块、`verify`、移入 JIT 执行——JIT 随执行结束析构，各轮
  互不污染。
- **逐观察判定**。对每个输出：`evalIv(site->e, narrowed.
  at(nid))` 给出预测区间，区间为 ⊥ 或值落在端点外即判
  UNSOUND。注意判定读的是 **narrowed**（Δ 解）；∇ 解的检
  验结果在 21.9 的输出里已可推断（区间更宽，成员关系必然
  也成立）。

### 35.10.3 soundness 输出逐行解读

widen.tip 的 main 无参数、程序内也没有 `input` 表达式，
所以输入文件里三行 `1 / 5 / -3` 实际上不被消费——它们的
作用只是触发三次独立执行（回归协议按行计数），验证"同一
程序多次执行预测都成立"。真实输出如下：

```text
run 1: outputs 10 ; predicted [10,10] ; membership OK
run 2: outputs 10 ; predicted [10,10] ; membership OK
run 3: outputs 10 ; predicted [10,10] ; membership OK
SOUND 3 runs, 3 observations
```

三次执行的具体输出都是 10（程序确定性地计数到 10），预测
区间是收窄后的 `[10,10]`，成员关系每次成立。末行
`SOUND 3 runs, 3 observations` 汇总：3 次执行、3 个观察点
全部通过。嵌入输入与期望输出全文：

```text
; expected: expected/soundness/widen.inputs
1
5
-3
```

```text
; expected: expected/soundness/widen.txt
run 1: outputs 10 ; predicted [10,10] ; membership OK
run 2: outputs 10 ; predicted [10,10] ; membership OK
run 3: outputs 10 ; predicted [10,10] ; membership OK
SOUND 3 runs, 3 observations
```

## 35.11 正确性论证思路

本节把分散在全章的论证收拢成一条完整链条，说明"凭什么
相信加宽再收窄后的区间"。论证分四层，每层给出思路而非
堆砌符号——读者可据此自己补出严格的归纳证明。

### 35.11.1 第一层：朴素分析的局部可靠性

第 34 章的区间传递函数（含 evalIv 的端点算术）对每个具体
程序点满足：**若执行到达该点时变量的具体值落在流入区间
内，则赋值/输出后的值落在流出区间内。**算术规则按端点组
合取包络正是为此设计：区间内任意两数之和/积必在端点组合
的最小最大范围内。这是局部可靠（local soundness），沿单
条语句成立。

### 35.11.2 第二层：不动点的全局可靠性

对所有路径归纳：入口处具体值在初始区间内（参数给全区
间），每过一个节点应用局部可靠性，则**在最小不动点的每
个点上，任何到达该点的具体执行值都在该点的区间内。**前
提是分析状态取到了最小不动点——第 28 章对有限高格证明了
worklist 达到它；区间格达不到，于是需要下面两层。

### 35.11.3 第三层：widening 结果是最小不动点的上界

由 ∇ 的上界性质（21.3.1 性质一），加宽序列每一步都在朴素
序列之上。形式化地，对每个轮次 n 可归纳：朴素序列第 n 轮
的状态 ⊑ widening 序列第 n 轮的状态。取极限（或在 widening
终止处），最小不动点 ⊑ ∇ 不动点。因此：**任何在最小不动点
区间内的具体值，必然也在更宽的 ∇ 区间内。**第二层的可靠
结论通过"上界包含"原样传递给 ∇ 解——这就是 35.10 节成员
检验的形式对应物，也是"偏松仍然可靠"这句话的证明。

终止性则由阈值表有限独立保证（21.3.3 的端点移动计数），
不依赖被分析程序。

### 35.11.4 第四层：narrowing 不跌破方程

Δ 的性质一（21.6.1）限定结果夹在新算出的 y 与旧的 ∇ 值
x 之间。收窄后每个点仍含住"原方程在当前状态下推出的事
实"，因此不会排除任何具体执行值。归纳可得：**Δ 结果仍
是最小不动点的上界**（介于最小不动点与 ∇ 解之间），可靠
性不损失；有限下降链条件保证收窄本身终止。本章的收窄解
恰好本身是不动点（21.6.4），是更强的好运气，不是论证的
必需品。

### 35.11.5 经验检验在论证中的位置

35.10 节的 JIT 检验不替代上面任何一层——它只对三次具体执
行负责，原则上抓不住"其他输入/其他路径"上的反例。它的
价值有二：一是检验**实现**是否忠实于形式化（实现错误、边
匹配错误、端点算术错误都会在具体值上暴露）；二是把抽象
链条的终点落到可观察的输出上，使"可靠"不停留在纸面。形
式论证保"对所有执行成立"，经验检验保"机器算的与形式化
一致"——两者合起来，才是本章交付结论的完整方式。

## 35.12 复用基础设施逐文件说明

本章嵌入的 23 个文件中，除了 widen.hpp/widen.cpp 与三份
expected 文本，其余 18 个全部从前面章节按字节复制，未作
任何修改。本节把它们完整嵌入并逐一说明角色——读者无需回
翻前面章节，也能看清本章的新代码建立在什么之上。阅读本
节的建议方式是：先看每段散文讲清楚这个文件"拥有什么、
放弃什么"，再对照嵌入的源码印证；散文会点名关键结构与
函数，源码提供完整细节。

### 35.12.1 语言前端：文法与 AST

ANTLR 文法 TIP.g4 是第 4 章定稿的 TIP 语言全貌：整数与
`input`、六种二元运算、直接函数调用、if/while/块、
return，以及指针（`*`、`&`、`alloc`、`null`）与记录
（`{f:e}`、`.f`）的完整语法。本章程序只用到整数核心，但
文法保持完整，与其他章节的示例共享同一份语言定义。

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

逐行看这份文法，能看清"一个分析器的前端边界划在哪里"。

第 3 行 program 规则规定一个 TIP 程序是一个或多个函数、
最后 EOF；第 4 行的 singleExpr 在本章没有被命令行使用，
但保留它是为了与其他章节（表达式级实验）共享同一份文法
文件。第 5 行是函数形状：名字、括号里的可选参数列表、花
括号里的可选 var 声明、零或多条语句、最后以一个 return
表达式收尾。注意 return 是函数语法的一部分而不是普通语
句——这与 C 不同，它保证每个函数一定有一个显式返回点，
CFG 构建因此能确定地为每个函数收束到一个 Return 节点。

第 6、7 行分别收参数与局部声明：标识符用逗号分隔，局部
声明以 var 开头、分号结尾。TIP 没有块级局部变量，所有
局部名字必须在函数顶部一次性声明——这条限制让符号表可
以"进函数先开作用域、声明全部名字、再遍历函数体"，无需
在块的入口/出口反复开关作用域。

第 9–14 行是五类语句的备选（alternative），行尾的
#assignStmt 等是给备选起的标签：ANTLR 会为每个标签生成
一个独立的上下文子类，AST 构建器正是靠这些子类用
dynamic_cast 区分"这一行到底是哪种语句"。第 9 行赋值的
左边不是裸 IDENT 而是 lvalue，为的是把指针解引用写
`*p = e`、字段写 `p.f = e` 也纳入赋值；第 10 行 output
是 TIP 的可观察输出，本章 JIT 检验收集的就是它；第 11、
12 行的 if/while 是控制流分叉与环的来源，本章 widening
的全部讨论都挂在第 12 行产生的 WhileS 上；第 13 行的块
只是语句序列，不引入作用域。

第 27–29 行展开 lvalue：直接标识符（可带一个点字段名）
与 STAR 表达式（同样可带字段名）。本章程序只出现
`x = …` 这种直接形式，但文法保留完整形状。

第 24–40 行的表达式文法是理解"优先级如何不靠手写分析器
实现"的好教材：ANTLR 把备选按书写顺序赋予优先级——越靠
上的备选优先级越低。第 19 行函数调用约束最松（在最
上），随后第 20 行字段访问、第 21 行解引用、第 22 行取
地址、第 23 行 alloc、第 24 行一元负号，再到第 25 行乘
除、第 26 行加减、第 27 行比较，最下面第 33–38 行是原
子式（整数、标识符、input、null、括号、记录）。因此
`a+b*c` 自然解析成 a+(b*c)，`f(x).g` 的结合性也由规则
形状决定，文法里没有任何优先级数字。第 24 行一元负号在
语义上被当作 0−E（第 73–75 行的构建代码会印证这一
点），所以 TIP 词法没有负号整数字面量，第 51 行的 INT
只匹配数字串。

第 47–49 行处理空白与注释：空白和两类注释直接 skip，分
析器永远看不到它们。第 47–60 行是关键字；第 50 行标识
符；第 51 行非负整数；第 52–62 行是运算符与分隔符。值
得注意的是关键字必须排在 IDENT 之前——ANTLR 按声明顺序
消歧，`input` 才会被当作关键字而不是变量名。

对本章而言，这份文法的意义不在它支持多少结构，而在它把
"while 循环"以一条独立规则确定地交付给后续各阶段：词法
→解析→AST 的 WhileS→CFG 的环→∇ 的加宽点。后面每个文
件都在这条链上承担一环。

这里再补充三点容易被初学者忽略的文法知识，它们在后面的
代码里都会以间接方式出现。

第一，第 32–50 行的左递归不是手写递归下降能处理的形状
（f(x) 里的 expr 又出现在规则左首），但 ANTLR4 的自适应
LL(*) 算法会在内部把直接左递归改写成"前缀（原子式）+ 尾
部运算符序列"的形式，优先级就由备选书写顺序映射成尾部循
环的尝试顺序。所以这份文法既能保持人类可读的左递归写
法，又不需要我们实现 LR 分析器。

第二，词法规则与语法规则同名空间不同：全大写的是词法
（token），小写的是语法（parser rule）。第 47–60 行的关
键字各自占一条词法规则、只匹配固定字符串；IDENT 则匹配
一个无限集合。当输入的前缀同时满足多条词法规则时，ANTLR
先用"最长匹配"决胜，长度相同再按"声明顺序"——这就是关键
字必须声明在 IDENT 之前的完整原因。`inputx` 因最长匹配仍
归 IDENT，`input` 长度相同则归关键字。

第三，文法里没有任何关于"行"的概念：第 38 行把换行等同
于空格一并 skip。TIP 的语句边界完全由分号决定，一条语句
可以跨任意多行。这让词法分析器与源文件排版彻底解耦，后
面 AST 构建器收到的 token 流里没有任何行结构（除了错误
报告需要的行号，那是 token 对象自己保留的）。

对本章示例还值得核对一件事：widen.tip 实际只触发这份文
法的一小部分备选——assignStmt、outputStmt、whileStmt 三
类语句，intExpr、varExpr、addExpr 三类表达式。把"程序用
到的规则"与"文法允许的规则"分开看，是理解"为什么前端可
以一次建好、被所有章节共享"的关键：文法覆盖整个语言，分
析只面对当前程序真实出现的节点种类，未出现的结构无需特
例处理。

AST 节点定义 ast.hpp 从第 10 章起冻结。本章直接使用其中的
`IntLit`、`VarRef`、`Binop`（含 `BOp::Gt` 与反向写法）、
`AssignS`、`OutputS`、`WhileS` 与 `FunDecl`；指针与记录
节点虽然存在，本章分析不会遇到（widen.tip 不使用它们）。

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

读懂这份头文件，关键是抓住三件事：所有权形状、节点种类
的封闭集合、以及"语句与表达式分层"。

所有权上，整棵树只有 ProgramA 一个入口，函数声明存放于
vector 里的 unique_ptr，语句与表达式递归地以 unique_ptr
持有子节点（第 33–36 行的 Binop、第 67–71 行的
AssignS 都是典型）。这意味着树的销毁是自动的、移动是廉价
的，而拷贝被刻意禁止——程序 AST 在流水线中应当被移动与
共享只读视图，而不是被复制。CFG 节点不拥有语句，只保存
`const Stmt*` 裸指针（cfg.hpp 第 17 行），这份裸指针的
合法性由"AST 比 CFG 活得久"来保证：main.cpp 里 AST 在
整个 --check/--verify-soundness 期间都存活。

节点种类是一个封闭集合。表达式一侧（第 14–61 行）有
IntLit、VarRef、InputE、Binop、CallE、Deref、AddrOf、
AllocE、NullE、RecLit、FieldA 共 11 种；语句一侧（第
63–95 行）有 AssignS、OutputS、IfS、WhileS、BlockS、
ReturnS 共 6 种。所有"按种类分派"的代码（AST 构建、符号
解析、CFG 构建、区间求值、IR 生成、打印）都写成一长串
dynamic_cast，这是有意为之的风格：新增一种节点时，编译
器不能强制你更新所有分派点，但 grep 一个基类指针的使用
点就能找全。本章的 widen.cpp 只关心其中三种——
WhileS（识别加宽点）、AssignS（读赋值目标与右端）、
OutputS（JIT 成员检验的观察点）。

第 12 行的 BOp 枚举把六个运算符合并成一个 Binop 节点而
不是为每种运算造一个节点类：Add/Sub/Mul/Div/Gt/Eq。
比较运算 Gt/Eq 与算术运算同居一处，是因为它们在语法上都
是"左 expr 运算符 右 expr"，区别只在语义。区间求值对
Gt/Eq 的处理（不产生区间精炼——那是边函数的职责）与对
Add/Sub/Mul 的处理（端点组合）因此在同一个 Binop 分支里
按 op 分派。

第 29–47 行的 IntLit 与 VarRef 是最小的叶子：一个装
int，一个装字符串。本章手工推演中反复出现的常量 0、1、
10 在 AST 上都是 IntLit；变量 x 则是 VarRef，它的名字在
符号表解析后被绑定，但区间环境仍以名字字符串为键——这是
教学实现的简化：名字解析保证同一函数内名字不冲突（重复声
明报错），字符串键就不会串味。

第 25 行 InputE 是无字段节点：它代表"一个运行时才知道的
整数"。区间格给它最保守的全区间（interval.cpp 第 94–96
行）；IR 生成给它一次 tip_input 调用。本章 widen.tip 没
有使用 input，但 soundness 框架支持含 input 的程序——那时
预测区间会放宽到包含任意输入。

语句层值得多看一眼第 82–87 行的 WhileS：它只有 cond 与
body 两个字段，没有"退出后去哪"的信息——控制流的接续由
CFG 构建器在第二遍连边时补上（cfg.cpp 第 110–118 行：
条件点两条出边，一条进体、一条到循环后继，体出口回到条
件点）。AST 保持"程序像写出来的样子"，CFG 才补上"程序
怎么跑"。这种分工让 widening 能在 AST 上找到循环（
dynamic_cast WhileS），又在 CFG 上找到环与割点。

第 97–103 行的 FunDecl 把函数的五要素收齐：名字、参数名
列表、局部变量名列表、函数体 BlockS、单独的 ret。ret 与
body 分开存放，呼应文法里 return 不是普通语句的设计。
第 105–107 行的 ProgramA 只是函数列表——整个程序没有任
何顶层语句，执行从名为 main 的函数开始，这一点会被
irgen 的 wrapper 与 ch47 的 context 求解器共同依赖。

关于"为什么用继承体系而不是 variant 标签联合"，值得多说
一句，因为它影响后面每个文件的写法。C++17 提供了
std::variant，理论上可以把表达式写成一个 variant、访问
用 visit，编译器还能在新增种类时检查访问是否穷尽。这里仍
选择虚基类 + dynamic_cast，有两个现实理由：其一，节点要
递归持有子节点的 unique_ptr，并在基类提供虚析构，继承体
系让"树"这层结构天然成立；其二，教学代码里大量出现"我
只关心一种节点、其余一律放行"的部分访问（比如 widen.cpp
只想找 WhileS），dynamic_cast 写一个 if 即可，visit 则要
为每个种类给出处置或用 generic lambda 兜全。穷尽性检查的
好处在一个"节点集合冻结、分派点靠 grep 收全"的项目里没
有在通用产品里那么大。

再看一处小而关键的工程约定：所有节点都只提供"构造"，不
提供修改接口。字段虽然可以从外部读写（它们是 public 的），
但流水线的任何阶段都不修改 AST，CFG 持有的是 const 指
针，符号表、求解器、代码生成拿到的全是 const Expr*/Stmt*。
"构造之后即只读"让同一份 AST 能被多个分析安全地共享，第 47 章同时跑四档求解器用的正是同一棵树。本章 main.cpp 里
solveWidenedInterval 与 narrowPass 都只读 AST、把状态写进
自己的 map，互不影响。

AST 构建器 ast_build.hpp/ast_build.cpp 在 ANTLR parse tree
上手工递归下降，把语法树翻成 ast.hpp 的节点。它对所有语
法结构（含指针、记录、调用）一视同仁地构建；本章无需为
widening 改动构建器的任何一行。

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

先看头文件里一个值得追问的决定：为什么不用 ANTLR 自动生
成的 visitor？注释（第 2–4 行）直接给出了原因——本工具链
的 C++ runtime 让 visitor 通过 std::any 携带返回值，而
std::any 无法持有 unique_ptr；如果改用裸指针就要手工管理
所有节点的释放，得不偿失。ANTLR 的 parse-tree 上下文对象
本身已经保留了全部结构（子节点列表、标签备选的子类），
因此手工遍历并不比 visitor 多做工作，还能自然地返回
unique_ptr。这是"工具给了机制，但机制与所有权模型不合
时，退回最简单手段"的典型取舍。

接口面只有四个方法：build 处理整个 program，buildFun、
buildExpr、buildStmt 分别递归三层，buildLvalue 处理赋值
左值。文件尾的 buildAst 是便捷自由函数，main.cpp 调用的
就是它。

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

实现文件的结构与头文件的四个方法一一对应，阅读时顺着
"从程序到叶子"的递归顺序最清楚。

build（第 8–12 行）只是遍历顶层函数，逐个交给 buildFun，
收集进 ProgramA。真正有信息量的是 buildFun（第 26–66
行）：它先取函数名，再用两个 for 把参数与局部变量的文
本抄进字符串列表；第 47–49 行把函数体的所有语句构造成
一个 BlockS——即使文法允许函数体直接写语句序列，AST 上
也统一包一层块，后续遍历就只有一个入口；第 28 行单独构
造 return 的表达式，收进 ReturnS。整个函数没有任何类型
检查，它只负责"形状翻译"。

buildLvalue（第 37–63 行）处理一个容易忽略的细节：左值
可能是直接标识符，也可能是 STAR 解引用，两者都可再带一
个点字段。代码用 dynamic_cast 在两个上下文子类间分流，
先构造"基"（VarRef 或 Deref），再按是否出现字段名决定
要不要包一层 FieldA。这种"先基后包装"的顺序与表达式文法
的结合性一致。

buildExpr（第 48–98 行）是最长的函数，但形状高度重复：
每个 if 对应文法的一个标签备选，把上下文里的子节点递归
buildExpr 后组装成对应的 AST 节点。几个值得停留的点：第
50 行整数用 std::stoi 把文本转成 int；第 60–63 行加法规
则同时服务加法与减法，靠 PLUS() 是否存在选 BOp；第
64–67 行乘除同理；第 68–71 行比较同理——文法用一条规则
的两个 token 换来了构建代码的一小段分支。第 72–76 行的
一元负号被翻译成 0−E，印证了文法里"没有负数字面量"的
设计，于是常量折叠、区间算术都不必单独处理负号。第
77–82 行的调用先构建 callee 再构建实参向量；第 91–96 行
的记录字面量把字段名与字段值成对收集。末尾第 97 行返回
nullptr 是防御性兜底：解析成功时所有备选都已被前面的 if
覆盖，正常路径到不了这里。

buildStmt（第 100–119 行）与 buildExpr 同构。注意第
105–110 行的 if：无 else 分支时 els 保持 nullptr，AST 用
"指针为空"而不是用一个空语句来表达"没有 else"，CFG 构建
与 IR 生成都要按"els 可能不存在"处理。第 111–112 行的
while 只递归条件与体两个子节点——环的信息此刻还不存在，
它要等 cfg.cpp 的第二遍连边才显式出现。

对本章最重要的事实是：整个文件里没有一处需要知道
widening 的存在。buildStmt 产出的 WhileS 与 AssignS，与
第 10 章首次构建它们时逐字节相同。分析技术的进步不回头改
前端，这是分层带来的复利。

顺着这个文件，还可以回答两个初学者常问的问题。

其一，"解析成功"在代码里如何被保证？ANTLR 在遇到无法继
续的输入时会触发错误监听（main.cpp 的 CollectErrorListener
会记录），parseFile 随后以退出码 2 终止，构建器根本不会
在带语法错误的树上运行。因此 buildExpr/buildStmt 末尾的
nullptr 兜底确实不可达，它只是编译器视角的防御。

其二，构建器为什么不在这里顺手做常量折叠、类型检查之类
的"增值"工作？因为那会把两个应当独立变化的关注点焊死：
前端只负责"源文本是不是一个合法的 TIP 程序、它的结构是
什么"，而"这个表达式能否折叠、变量是什么类型、区间多
宽"全部是后续阶段按需要选择的分析。第 34 章需要完整保留
`x = x + 1` 的结构才能讨论循环，过早折叠反而会破坏分析对
象。一个最小、忠实、只读的 AST，是后面所有自由的来源。

也请注意一个实现细节：第 50 行 std::stoi 在整数字面量超过
int 范围时会抛异常，本教程示例没有为此专门捕获（错误会以
未捕获异常的形式中止）。生产前端通常把"字面量越界"也收
集为诊断，做法是在调用前先按字符串长度与位数判断。这属
于"错误恢复"这一大主题：好的前端应当一次报出所有可定位
的问题，而不是在第一个异常处崩溃。

### 35.12.2 符号表与 CFG

symtab.hpp/cpp 做名字解析：把每个 `VarRef` 绑到它的声明
（函数/参数/局部），并产出未声明、重复声明诊断。本章的
区间环境以**名字**为键，绑定工作是区间求值能正确查变量的
前提。

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

头文件里值得逐个确认的设计：Symbol（第 25–29 行）用枚举
区分函数、参数、局部三种符号，并保留一个指向所属函数声
明的指针；Scope（第 32–48 行）是一张表加一个父作用域指
针，lookup 的语义是"先查本表，没有就递归查父表"；
Bindings（第 36–46 行）把一次解析的全部产出捆在一起——
全局作用域、各函数作用域的所有权向量、诊断列表、以及
uses 这张"使用点→符号"的映射。特别注意第 34 行的注释：
函数作用域的所有权必须由 Bindings 持有，uses 里那些
Symbol 指针在解析器（栈上的临时对象）销毁后才不会悬垂。
第 40 行的 resolveNames 接收的是可修改的 ProgramA 引用，
但它并不改写 AST——绑定结果全部放在返回的 Bindings 里，
AST 节点保持只读。

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

实现文件展示了一次"两遍名字解析"的完整形状。

先看第 84–88 行的 lookup：本表命中就返回符号地址，否则
把查询委托给父作用域，父作用域为空才返回 nullptr。这四
行实现了词法作用域的全部规则；TIP 的函数可以前向调用同
程序里的任何函数，正因为函数名注册在全局表、而每个函数
作用域的父指针都指向全局表。

核心是匿名命名空间里的 Resolver（第 9–80 行），它持有
Bindings 与"当前作用域、当前属主函数"两个游标。declare
（第 27–35 行）处理重复声明：发现同名就记一条诊断并保留
先声明者——"后声明被忽略"是刻意的恢复策略，让一次解析
能报出尽可能多的错误而不是只报第一个。

resolveExpr（第 27–66 行）按表达式种类遍历，唯一真正做
绑定的是 VarRef 分支（第 29–37 行）：查当前作用域，查不
到记 undeclared，查到就把"这个 VarRef 指针 → Symbol 指
针"写进 uses。其余分支只是递归：Binop 走两个子节点，
CallE 走 callee 与全部实参，Deref/AllocE/FieldA 走内部表
达式，RecLit 走全部字段值。第 46 行有一句关键注释：字段
名不是变量，不需要解析——`a.f` 里的 f 只是标签。第 53 行
列出了根本不含变量使用的节点：IntLit、InputE、AddrOf
（它的名字在文法层就是 IDENT，构建时直接存了字符串）、
NullE。

resolveStmt（第 56–79 行）同构地遍历六种语句：赋值要同时
解析左值与右值（左值里的 VarRef 也是使用点），output、
return 解析一个表达式，if/while 解析条件后递归体，块逐
条递归。没有任何分支修改 AST，遍历时拿到的全是 const
指针。

resolveNames（第 90–121 行）把两遍策略落到实处。第一遍
（第 96–102 行）在任何函数体被查看之前，先把所有函数名
注册进全局表——这就是前向调用合法的原因；重名函数同样
走"报错并保留先来者"。第二遍（第 106–119 行）为每个函
数建一个以全局表为父的新作用域，把参数、局部变量依次
declare，再遍历函数体与 return；遍历结束后作用域所有权移
交进 Bindings。注意第 108–109 行两个游标的设置与第 117 行
的清空：Resolver 只在遍历期间借用作用域地址。

本章怎么用这份输出？两处：irgen 拿 uses 把 VarRef 翻成对
应的栈槽；而区间求解器其实只按名字字符串查环境——名字
解析在这里承担的是"门卫"职责：能走到求解器的程序一定没
有未声明/重复声明错误，字符串键因此无歧义。退出码 3 就
是为这一层语义错误保留的。

把这份解析器与"真正的嵌套作用域语言"对比，能看清 TIP 刻
意简化了什么。C 系语言允许在任意块里声明新变量，内层可
以遮蔽外层同名符号；那样的语言要求解析器在每次进入/退出
块时开关作用域，并且"使用点绑到哪一层声明"取决于嵌套深
度。TIP 把局部名字全部收归函数顶部、不允许块级声明也不
允许遮蔽（重复声明直接报错），于是每个函数只有一张局部
表，lookup 的递归深度恒为两层（局部→全局）。这份简化没
有损失表达"数据流"的能力，却让符号表代码短到可以完整嵌
入讲解。

另一个值得注意的点是全局表只放函数名。TIP 没有全局变
量，所有可变状态都在函数内部、随函数调用而生灭，这正是
过程间分析（第 37、38 章）可以把"状态"按函数切分的语
义前提。第一遍先注册全部函数名则保证了：函数在文本中的
书写顺序与调用关系无关——main 可以调用写在它后面的函
数，第 47 章程序里 main 恰好声明在最后，仍然一切正常。

最后留意诊断风格：所有错误文本都是小写的 "error: ..." 句
式，与语法错误的 "syntax error line ..." 区分但同属人读文
本。本教程不设计错误码体系，因为教学目标是让错误在终端
里一目了然，而不是服务某种 IDE 协议。

CFG 设施 cfg.hpp/cpp 是第 14 章冻结的图结构：每个函数一份
节点表与边表，节点透传对应语句。它是本章求解器遍历的对
象；其"边无标签"的缺口由 35.8 节的 LocalWiring 补上。

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

头文件虽小，却定下了三个被后续所有分析依赖的约定。其
一，节点有六类（第 16 行）：入口、出口、赋值、输出、分
支、返回——普通语句节点直接透传 `const Stmt*`（第 17
行），入口/出口是纯图节点没有语句。其二，每个函数一份
FunCfg，保存名字、入口号、出口号、节点表与边表（第 20–
26 行）；节点表用 map 而节点 id 是 int，因此遍历天然按
编号升序——worklist、round-robin 与本教程所有打印的确定
性都建立在这个选择上。其三，Cfg 只是 FunCfg 的向量，构
建入口 buildCfg 与打印入口 printCfg 并列声明。边本身不携
带真假标签：一个 Branch 节点只是简单地有两条出边，"哪
条是真"要靠边的对端节点结合 AST 结构恢复，35.8 节处理的
正是这件事。

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

cfg.cpp 是理解 35.8 节 LocalWiring 的唯一依据，因为
widen.cpp 复制的"编号规则"就藏在这里。开头第 25–27 行的
注释点明了整个算法为什么分两遍：必须先按 AST 先序把所有
节点编号，再连边，编号才严格按源码顺序；如果边构造时才
新建后继节点，后继会抢到小号。

run（第 25–66 行）是每个函数一遍的总控：nextId 从 1 开
始，第 29 行先加 Entry（入口号恒为 1），第 31 行对函数体
做编号，第 32 行加 Return（透传 ret 语句），第 33 行加
Exit。所以编号的完整规则是：入口=1；随后严格按 AST 先序
给函数体编号——块按子语句顺序；if 先给 Branch 再给 then
整个子树再给 else 子树；while 先给 Branch 再给 body 子
树；赋值与输出各占一个号；Return 与 Exit 排在最后。本章
widen.tip 的节点图（1 入口、2 赋值、3 分支、4 赋值、5 输
出、6 返回、7 出口）就是按这套规则机械产生的，21.5 的手
工推演直接引用这些号码。

numberStmt（第 63–86 行）是第一遍的全部内容，只做 dynamic
分派与 addNode：if/while 造 Branch 节点，赋值造 Assign，
输出造 Output。块不占节点——它只把子语句的编号串起来。
stmtId 这张"语句指针→节点号"的映射是第二遍连边的查找基
础。

wireStmt（第 89–122 行）是第二遍，也是值得慢慢读的部分。
它的契约写在注释里：参数 succ 是"语句执行完之后该流向的
后继集合"，返回"进入该语句时首先到达的节点集合"。块
（第 90–95 行）从最后一条语句反向折叠 succ，于是顺序语
句自然首尾相接。if（第 96–109 行）先把两个分支各自连到
succ，再把分支点连向两个分支的入口；空块返回空时直接用
succ 透传。while（第 110–118 行）是环出现的地方：循环体
的后继被指定为条件点 n 自身（第 113 行），体出口于是回
到头部；条件点同时连一条到循环外的 succ（第 116 行）；
空体时条件点连自边，语义上就是死循环。普通语句（第
119–121 行）只连自己的 succ。

第 51–60 行用 set 对边去重排序：CFG 不允许重复边，输出
顺序因此固定，基于"边集合相等"的状态比较才不会被顺序干
扰。第 129–139 行的 kindName 与第 145–159 行的 printCfg
把图按"函数、节点（含语句单行）、边"三段打印，21.9 的
--check 输出里节点标签的形状就是 printStmtLine 的产出。

请特别记住编号规则与连边规则这两条"隐式契约"：widen.cpp
的 LocalWiring 没有调用 buildCfg 之后的任何信息，它靠如
实重演这两套规则恢复真假边。这正是 21.13 工程注意点第 4
条的由来。

再深入一点看 wireStmt 的"后继传入"风格，它其实是一种程
序等价变换的标准写法。每个语法构造的编译规则可以表述
为：给定该构造出口处的后继块列表，产出入口块列表。块结
构用反向折叠处理（先编译最后一条、其入口是倒数第二条的
后继），if 把后继复制到两个分支，while 制造一条回边。
这种风格在真实编译器里同样常见：LLVM 自己早期的 C/C++
前端生成"显式跳转式"IR 时采用的就是后继传入；许多教学编
译器（例如各种迷你 C 编译器）构造 CFG 的代码与此处几乎
逐行对应。掌握这个套路后，遇到任何语句形式（for、do-
while、switch）都能照同一契约扩展。

例如把 for 加进 TIP：AST 上可展开成"初始化；while(条件)
{体；步进}"，CFG 构建甚至不需要新节点类型。do-while 则
需要新连边形状：体的入口同时是循环入口，体出口到条件、
条件为真回体。switch 在不支持跳转表时等价于多路 if 级
联。这些扩展都不动节点编号的核心规则——先序编号、后继
连边，只增加一种语法构造的分派。

还有一处容易忽略：Entry 与 Exit 节点没有语句，它们存在的
意义是让"函数输入状态"与"函数返回之后"各有一个确定的挂
点。第 47 章的上下文敏感分析就把参数绑定挂在 Entry 上，
返回边从 Return 扇形展开。Return 节点透传 ReturnS，使得
"返回值是什么"能在节点上直接求值。节点六类因此没有一个
是多余的。

为了让 21.8 的 LocalWiring 动机更完整，这里再讨论一个初学
者常提的替代方案："既然边没有标签，为什么不直接改
cfg.hpp 给边加一个枚举字段？"这个问题值得认真回答，因为
它触及本教程一个一以贯之的约束——**接口冻结**。

从第 14 章起，cfg.hpp/cpp 被多个章节按字节共享：常量传播
（第 29 章）、经典 DFA（第 30 章）、worklist（第 28 章）、
区间（第 34 章）以及本章的示例，链接的都是同一份 CFG。若
为"边标签"修改这两个文件，所有这些示例的嵌入都必须同步
更新，任何一处漏改，教程就出现自相矛盾。更重要的是，并
非所有分析都需要标签——活跃变量、到达定义只看边的连通与
方向，加字段对它们纯属负担。因此选择"有需要的分析自己重
推出标签"，把可变性隔离在消费者一侧，共享结构保持最小且
稳定。

这种取舍在真实系统里同样存在：编译器 IR 的每一个字段都
是所有 pass 共同承担的复杂度，给 IR 加"只被一个 pass 使用
的信息"通常被拒绝，替代方案是该 pass 维护旁路分析结果
（analysis result），按需重算或缓存。LLVM 的 pass 管理器
就明确区分"IR 本身"与"挂在 IR 上的分析结果"。本章的
LocalWiring 就是一个教学版旁路分析：它不写回 CFG，只在
widen.cpp 内部使用，生命周期与一次求解相同。

还值得比较第三种方案——在 AST 遍历时顺手记录每个条件的
真假后继。这其实与 LocalWiring 等价，区别只是信息何时计
算；本章选择在求解开始前一次性建好 trueOf/falseOf 表，迭
代循环中直接查表，避免每轮重复 dynamic 判定。表只占线性
大小，构建成本线性，属于"预先摊还"的简单优化。

pretty.hpp/cpp 提供 AST 的前缀式打印。本章 CFG 相关输出
（如 21.9 的节点行）没有直接使用它，但 widen.cpp 的
LocalWiring 不依赖打印——它被复制进示例，仅为与其他章节
的前端快照保持一致的完整构建单元；cfg.cpp 自身的构建则
include 了它（printCfg 用 printStmtLine 给节点加语句标
签），所以从编译依赖看它并非多余。

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

接口面三个函数：printExpr 打印一个表达式，printProgram
打印整个程序，printStmtLine 是单行形式——后者专门服务
"在 CFG 节点旁边写一句话"这类场合，它保证输出没有尾部换
行，方便拼进节点行。

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

实现里的 exprText（第 12–61 行）把表达式打印成统一的前
缀式：`(op left right)`。这种形式没有优先级歧义，适合做
调试与结构对照——想确认一棵 AST 是否按预期构建，读前缀
式比读源码更直接。语句打印 stmtText（第 55–90 行）按缩进
逐层展开，一条语句一行；块打印成带缩进的花括号。
printProgram（第 96–120 行）把函数头、var 声明、函数体
（注意第 114–115 行直接展开 BlockS 的内部语句，不再多嵌
一层花括号）与 return 依次输出。printStmtLine（第 123–
128 行）就是把单条语句打印后去掉末尾换行。

本教程"每个分析都能被肉眼看见"的基调，有一半工程基础在
这个文件上：CFG 节点行、诊断对照、AST 验收都复用它。

### 35.12.3 区间格与通用格接口

lattice.hpp 是第 26 章定稿的泛型格接口 `Lattice<A>`（顶/
底、相等、偏序、join）及四类构造器。本章求解器用它持有
区间格、做环境 join；泛型抽象使 widen 逻辑无需关心格的构
造细节。

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

这是本章理论与代码之间的"通用语言层"，值得花最多的笔墨。

先读 Lattice 模板（第 28–65 行）。一个格在代码里被压成
五个字段：顶值、底值、相等判定、偏序判定、最小上界函
数；三个同名方法只是转发。注意接口里没有 meet（最大下
界）——本教程的前向分析只需要 join 与 ⊑，刻意不把接口撑
大。判定与运算以 std::function 存放而不是虚函数，因此同
一个载体类型可以配不同的格规则，构造器返回的是"值"而不
是"派生类"。

四个构造器回答同一个问题：手里有简单格，怎么组装出"程序
状态"那种复杂格？

lift（第 37–66 行）给载体类型套一个 std::optional，把
nullopt 作为新底。读它的三个 lambda 能复习偏序定义：b
为空时 a⊑b 要求 a 也为空（⊥ 最小）；a 为空而 b 有值时
成立；两者都有值就委托给内格。join 里 ⊥ 是单位元：空侧
直接取另一侧。这个构造器在类型分析里承载"尚未推出"的含
义。

product（第 51–75 行）把若干格的 std::tuple 做成格：顶底
是逐分量顶底，偏序是逐分量偏序的合取，join 逐分量做。第
58–64 行的两个辅助函数用 index_sequence 展开分量，折叠
表达式 `(... && ...)` 是 C++17 的包展开技巧。想同时分析
"符号 + 常量"两个维度时，积格让两个维度的精度各自独立演
进。

maps（第 78–104 行）与本章关系最直接：在一组**固定键**上
逐点做格运算，缺失的键按底处理。第 81–85 行先为全部键预
置顶与底；getOrBot 把"map 里没有这个键"统一翻译成底；
leq 对每个键逐点检查，join 对每个键逐点合并。抽象环境
"变量→值"就是映射格——这也解释了为什么环境必须先确定键
集：声明的变量集合在函数顶部已知，映射格因此是有限高的
当且仅当值格有限高；区间格无限高时，环境格同样无限高，
这正是第 34 章不终止与第 35 章需要 ∇ 的根源。

powerset（第 107–123 行）把集合做成格：join 是并集，序
是包含，顶是调用时给出的全集。它服务"可能值集合""活跃
变量集合""到达定义集合"这类天然以集合表达的性质。

把四个构造器连起来看，就能看清本教程反复出现的一个组装
套路：先为原子性质造一个小格（常量、符号、区间），再用
maps 提升到"变量→性质"的环境，需要多个性质时用 product
并列，需要"尚未知"时用 lift。本章 ∇ 的作用对象"每个节
点一个 IvEnv"，在这个谱系里就是 maps(区间格) 的产物；∇
之所以逐变量定义，是因为映射格的任何运算本来就是逐点的。

这里再把"有限高度"这件事与四个构造器的关系讲透，因为它
是本章终止性论证（21.11）的根。

一个格的高度，粗略说就是从底到顶最长的严格上升链的长
度。常量格（只有 ⊥、若干常量点、⊤，常量之间互不相同且
不可比）高度有限；符号格（⊥、四符号、⊤）高度为 6；区
间格高度无穷——从任何点区间出发都能把上界一推再推。四
个构造器如何影响高度？lift 只加一层；product 的高度是各
分量高度之和（沿一个分量上升完再沿下一个），所以有限高
的分量们组合后仍然有限；maps 在 n 个固定键上，最坏情况
是轮流推动每个键：总高度是单值格高度的约 n 倍，单值格
有限则映射格有限；powerset 在有限全集上高度有界于全集
大小。关键结论：**没有任何一个构造器能把有限高变成无限
高；只要原子格有限高，组装出的环境格就有限高。** 反过来
也成立：原子格无限高（区间），映射格同样无限高。

这解释了为什么前 19 章的常量/符号分析用朴素迭代总能终
止，而第 34 章的区间分析不行——区别不在方程结构、不在
worklist 调度，只在原子格的高度。也解释了 ∇ 的设计层次
为什么放在原子格（区间端点）而不是环境层：在逐点的映射
格上，对环境做 widening 等价于逐键做 widening，直接在区
间上定义 ∇ 然后让环境逐点复用，规则最简洁、且不破坏
maps 构造器的通用性。

还请注意 Lattice 接口刻意不含 meet，但 21.6 的 narrowing
并不是 meet：Δ 不是"取两个信息的公共部分"（那样可能低
于方程的解），它是"在不低于方程解的前提下、沿旧解方向
试探性收回"。把 Δ 误实现成 meet 是经典的可靠性错误——
meet 的结果可能比 LFP 还低。形式化上区分二者的那句话
（y⊑x 时 y⊑xΔy⊑x）在 21.6 已给出，值得在此与接口形状
再对照一次。

再用一个具体假想把 ∇、join、meet 三者在区间上的差别一次
性钉牢，设 a=[0,1]、b=[1,2]。

join（⊔）取包络得 [0,2]：它是包含两者的最小区间，也是
方程正常迭代使用的运算；在无限高格上，反复 join 可能没有
尽头。∇ 按阈值得 [0,+∞)：它也包含两者，但故意比 join 大，
用精度换终止。meet（⊓）取交集得 [1,1]：它是两者的公共
部分，比 join 小得多；若在本该上升的迭代里误用 meet，结
果可能低于 LFP——本例里若真实路径含 0 或 2，meet 就把它
们丢了。三个运算都"合理"，但分别服务于上升逼近、终止加
速、下降交汇三种不可互换的用途。

还可以从"信息论"的直觉再看一眼格的方向：底 ⊥ 是"知道不
可达"——信息量其实很特殊（它是分析能给出的最强否定之
一），顶 ⊤ 是"一无所知"。区间越窄，在格上位置越低、信
息越具体。迭代从 ⊥ 起步，信息只增不减；∇ 是一次"主动的
信息克制"（拒绝继续增加细节、以粗粒度告终），Δ 是"在不
突破下限的前提下补回细节"。可靠性论证本质上就是在追踪：
每一步运算之后，真实状态仍然在当前信息所圈定的集合之
内。

interval.hpp/cpp 是第 34 章的区间格与区间算术：`Iv` 结
构、`ivLattice()`、`ivText` 与 `evalIv`（加/减/乘端点组
合、除的保守规则）。本章的 ∇/Δ 全部建立在这些运算之上，
未修改其中一行；widening 迭代到节点 4 时调用的正是
`evalIv`。

```cpp
// file: src/interval.hpp
// 第 34 章配套：区间格与朴素迭代的不终止演示（spa 第 4→5 章的衔接）。
// 区间 [lo,hi] 回答"这个变量最小/最大能取多少"；lo>hi 编码 ⊥（不可达）。
// 与符号格不同，区间格**高度无穷**：[1,1] ⊑ [1,2] ⊑ [1,3] ⊑ … 没有尽头。
// Tarski 定理仍保证最小不动点存在，但朴素迭代不再保证在有限步内到达它——
// 本章用封顶 50 轮的朴素迭代把这个不终止"演出来"，为第 35 章 widening 铺路。
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

读头文件先抓住区间的三个约定（第 32–48 行）：用 INT_MIN/
INT_MAX 两个哨兵编码 −∞/+∞，因此分析只覆盖 int 范围；用
lo>hi 编码 ⊥，底取 `Iv{1,0}` 这种形状；相等按两端逐点
比。第 34 行的 IvEnv 就是环境类型；第 38 行 evalIv 的契
约写在注释里：常量映射到点区间，input 映射到全区间，四
则运算用端点组合，不认识的结构保守取顶。第 48–61 行的
NaiveResult 是第 34 章朴素迭代的轨迹类型，本章 main.cpp
不再调用它，但保留声明以维持文件逐字节复制。

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

这个实现文件可以分三段读：饱和算术、格与文本、抽象求值。

饱和算术（第 14–42 行）解决"端点越过 int 边界"的问题。
satAdd/satMul 用 long long 做中间运算，越过哨兵就钳到
±∞——这保证 [INT_MAX,INT_MAX] 加 1 不会溢出回绕成负数
而产生错误区间。乘法的 mulLo/mulHi（第 29–42 行）要单独
处理无穷端：有限数与同号无穷相乘仍是同号无穷，异号则反
号；0 与无穷相乘按 0 处理（这是教学简化）。四个端点两两
组合取最小/最大，就覆盖了区间乘法的全部情形。

格 ivLattice（第 50–65 行）的定义值得与 21.3 的形式化对
照着读：顶是全区间，底是 lo>hi；偏序里先判 ⊥（⊥⊑一切）
再判区间包含——注意方向，a.lo>=b.lo 且 a.hi<=b.hi 才是
a⊑b：区间越窄信息越准、在格上越低；join 取包络（min lo、
max hi）。ivText（第 67–82 行）把哨兵打印成 -inf/+inf、
把底打印成 bottom，21.9 输出的每个区间都经它格式化。

evalIv（第 84–126 行）是区间算术的主体。常量→[v,v]；变
量查环境、缺失→⊥（把"没见过"保守当作不可达，配合从 ⊥
起步的迭代）；input→全区间。Binop 分支先递归求出左右区
间，任一为 ⊥ 则结果为 ⊥——这是"不可达路径上的运算不可
达"。除法（第 102–109 行）有两层保守：除数区间含 0 时
商可能发散，直接给全区间；即使不含 0，也只有"两个都是点
区间"时给精确商，其余给全区间——因为 C++ 整数除法在端点
上的精确包络要处理截断方向，教学实现选择不展开（第 36 章
会把"除数含 0"从放弃精度升级为主动报警）。加（第 110–111
行）端点分别相加：最小可能值来自两个最小端，最大来自两
个最大端；减（第 112–113 行）交叉配对；乘（第 115–122 行）
四端点组合取包络。第 123 行对 Gt/Eq 直接给全区间：比较的
信息不属于表达式的值，它属于条件的**两条边**，21.7 的边
函数在那里使用它——同一语言构造的信息在两个不同位置被消
化，这是本章容易看漏但很重要的设计。

runNaiveInterval（第 128–189 行）是第 34 章留下的朴素迭
代：round-robin 按节点号顺序逐点重算、封顶 50 轮，每轮记
录循环头环境。它在本章的作用只剩一个——对照。本章新求解
器沿用它的骨架（前驱收集、从 join 起步、赋值用 evalIv），
只把两处换掉：头部的 join 换成 ∇、末后再跑 Δ。对照阅读两
个文件，能精确看到"终止性补丁"到底改动了多少：传递函数
evalIv 一行未动，动的只是不动点迭代策略。这正是 Cousot 框
架"方程与迭代方式分离"的工程价值。

关于区间算术本身，再补充三个与可靠性直接相关的细节。

第一，所有算术都以"端点包络"为唯一手段，而端点包络的可
靠性依赖一个事实：四则运算在整数（或其实数包络）上对每
个参数都是单调的。正因为 a+b 对 a、b 都单调，知道 a∈[l1,
h1]、b∈[l2,h2] 才能断言 a+b∈[l1+l2, h1+h2]。如果语言含
非单调运算（例如把操作数解释为位模式做移位、或按符号分
支的除法取整），端点直配可能漏掉极值，必须像乘法那样枚
举端点组合，或像除法那样保守放弃。理解"单调性允许端点直
配"，就拿到了判断任何新运算该怎么抽象的钥匙。

第二，底的传播规则是"任一操作数为底，结果为底"。这在语
义上完全正确：底代表"这条路径根本不可达"，不可达路径上
的表达式不会被求值，给任何有限区间都是凭空捏造。迭代时
它保证不可达分支不会污染 join——⊥ 是 join 的单位元。

第三，"变量缺失按 ⊥"与"input 按全区间"是两个相反方向的
保守，初学者容易混淆。缺失意味着"在这一轮还没有任何信息
流到此处"，在从 ⊥ 起步、单调逼近 LFP 的迭代里，这是正确
的初值，后续轮次会被真实信息抬高；input 则相反：源程序
语义上它真的可以是任意整数，没有任何信息可利用，只能给
顶。前者是"暂时未知"，后者是"确实不知"。二者在迭代结束
后的含义截然不同——缺失若持续到稳定，说明该点不可达；
input 的全区间则永远不会自动变窄。

顺带一提乘法在"无穷×0"处的取舍：数学上 +∞·0 是不定式，
真实程序里若一端是有界区间、另一端含 0，极值应来自具体
端点组合；这里把"恰好与 0"直接取 0，仅在另一操作数真的
是 ±∞ 哨兵（即无界）且另一端恰为点 0 时才可能不准——
0 乘任何有限数都是 0，而无界端若参与，结果的真实包络应
按对方端点决定。更严谨的实现会把 0×无界按"对方有界区间
端点与 0 相乘"处理。教学程序里不出现这种形状，保持规则
简单是刻意的取舍。

再从"具体语义—抽象语义"对应关系的角度，把 evalIv 的可靠
性拆开讲一层，为 21.11 的第一层论证铺路。

对每个表达式构造，可靠性命题具有统一形状：若在某个具体
环境 ρ 下表达式求值为 v，且 ρ 中每个变量的具体值都属于抽
象环境 E 给出的区间，那么 v 属于 evalIv(e,E)。证明按表达
式结构归纳。

叶子情形：IntLit 求值为常量本身，必属于 [c,c]；VarRef 取
ρ(x)，前提直接给出 ρ(x)∈E(x)；input 的结果是任意整数，
全区间必含。二元情形：先对左右子式用归纳假设，得具体左
值属于左区间、具体右值属于右区间；再按运算论证"端点包
络包含一切组合结果"——加法因单调性极值在端点对端点处取
到，乘法四端点组合枚举了所有可能极值，减法交叉配对。除
法保守取全区间，包含性平凡成立。矛盾情形（操作数区间为
⊥）对应"子表达式不会在此路径被求值"，具体 v 根本不存
在，命题空洞成立。

这一层论证有两个值得强调的特点。其一，它只依赖具体整数
算术与区间包络的初等事实，不涉及不动点、循环或 widening
——局部可靠性是整章最简单的一环，却也是其他三层的地基。
其二，它精确指出每种保守处理"保守在哪里"：除法是主动放
弃端点精度，比较运算把信息让渡给边函数；任何一个分支若
被写错（例如加法误用交叉端点），归纳就在该处断裂，JIT 检
验大概率会以 UNSOUND 暴露它。形式论证因此不仅给结论，也
给"出错时去哪一层排查"的地图。

最后提示一个读代码时的对照练习：读 evalIv 每个分支时都问
一句"这里的区间若再放宽一点，可靠性还在吗？精度损失
值不值？"——例如减法若不交叉而直配端点会怎样（下溢方向
错误，可靠性破坏！这不是精度问题）。能区分"放宽但仍可
靠"与"放法错误而不可靠"，就说明真正读懂了抽象解释的可
靠性观。

### 35.12.4 LLVM 执行台

irgen.hpp/cpp 把 AST 翻译成 LLVM IR（整数核心 + 直接调
用），main 改名 tip_main 并生成 C 入口 tip_entry。21.10
节每次 JIT 执行都先调用它现生成一个可 verify 的模块。

```cpp
// file: src/irgen.hpp
// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 50 章以后扩展，遇到时直接报错。
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

头文件先交代所有权：LLVMContext、Module、IRBuilder 三者
都以 unique_ptr 持有（第 35–46 行），因为 JIT 最终要接管
模块与上下文的所有权，上下文又必须比模块活得久。locals
映射"符号→栈槽 alloca"，cur 指向当前生成的函数。接口面
gen 一次生成全部函数与 C 入口，expr/stmt 递归生成，verify
与 dump 分别做模块校验与文本转储。第 42 行的两个
FunctionCallee 是 tip_input/tip_output 的运行时声明。

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
            throw std::runtime_error("ch15: 间接调用留待第 50 章");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("ch15: 间接调用留待第 50 章");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("ch15: 指针与记录构造留待第 50 章");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        const auto *target = dynamic_cast<const VarRef *>(x->target.get());
        if (!target)
            throw std::runtime_error("ch15: 经指针/字段写入留待第 50 章");
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

构造函数（第 30–51 行）先立起上下文、模块、构建器，再预
先声明两个运行时函数：tip_input 无参返回 i32，tip_output
吃一个 i32 返回 void。它们是 JIT 侧宿主函数在 IR 里的对
应物。第 38–42 行的 emitName 做一件小事但贯穿全文：TIP
main 改名为 tip_main，把真正的 @main 名号留给我们生成的 C
入口。

gen（第 39–62 行）同样是两遍：第 50–60 行先创建全部函数
的类型与外壳（参数一律 i32、返回 i32），函数互相前向调用
时总能找到声明；第 53–61 行再逐函数生成函数体，注意第 54
行按索引取用 resolved.scopes——作用域向量的顺序与程序函数
顺序一致。第 57–61 行找到 main 并生成 wrapper，没有 main
直接抛异常。

genFun（第 64–85 行）定下"内存式"代码生成：形参各开一个
i32 槽位并存入实参，局部变量各开槽位并零初始化，槽位记进
locals；随后生成函数体，最后以 return 表达式收尾。所有变
量读写都走 store/load 而不是 SSA 寄存器——这与 TIP"变量
可变"的语义匹配，也让代码生成无需做 mem2reg。

expr（第 87–132 行）按 AST 种类翻译。常量直接造常量整
数；变量经 uses 找到符号、从对应槽位 load；input 是一次
tip_input 调用。Binop 逐条对应 LLVM 指令：CreateAdd/Sub/
Mul/SDiv；比较先产出 i1 谓词再 ZExt 成 i32——TIP 没有布
尔类型，条件真假就用整数 0/1 编码。CallE（第 118–129 行）
只接受"被调方是解析为函数符号的名字"：间接调用会在运行时
抛异常。其余指针/记录构造同样拒绝——注释里"留待第 50 章"标明了路线。

stmt（第 134–199 行）的两个结构最值得对照 CFG 看。if
（第 149–171 行）建 then/else/merge 三块：条件按"非 0 即
真"翻译成 ICmpNE，条件跳转分流，两支末尾补无条件跳转汇
合，插入点最后落在 merge 块。while（第 173–190 行）建
wh.cond/wh.body/wh.exit 三块：先进头部、头部条件跳体或出
口、体末回头部、插入点落在出口。这与 cfg.cpp 的 Branch
两条出边（真→体、假→后继）严格对应——21.7 的边精炼给真
边提下界，依赖的正是"哪条边是真"在这里的语义。块只逐条
生成；return 直接 CreateRet。

genWrapper（第 201–214 行）生成 tip_entry：按 TIP main 的
形参数目依次调用 tip_input 取值，再调用 tip_main，返回其
结果。注释解释了为什么不直接命名为 main：MinGW 目标会给
main 注入对 CRT 符号 __main 的调用，自造入口避开这条耦
合。verify（第 216–222 行）与 dump（第 224–229 行）分别包
装模块校验与打印，main.cpp 在每次 JIT 前都先 verify，把
"生成了畸形 IR"挡在执行之前。

为什么本章的经验检验非要走完整 IR + JIT 这条重路，而不
是写一个直接在 AST 上跑的解释器？三个理由都与"检验要能
对得上形式化主张"有关。

其一，JIT 执行的是与生产编译器同一条生成路径产出的真机
器码：AST→IR→（LLVM 后端）→本机代码→执行。检验因此同时
覆盖了 IR 生成：如果 IRGen 把 while 错误地翻译成只执行一
次（例如漏了回边），具体输出就会与区间预测冲突，错误会
被抓住。AST 解释器与 IR 是两套独立语义，解释器对了不能
说明 IR 对了。

其二，静态分析真正要服务的对象，正是这种"会被编译成机
器码执行"的程序。在真实后端上验证"预测包含实际"，检验的
就是分析在工具链中的真实位置，而不是一个教学模拟。

其三，LLVM 的模块验证、目标初始化、指令选择全部由库提
供，我们写的 JIT 代码不到百行；相比之下，为 TIP 写一个语
义完整（含 input 顺序、短路、整数环绕语义）的 AST 解释器
并不更短，还引入"解释器语义是否忠实"的新问题。复用 LLVM
让"具体语义"这个组件由最可靠的一方提供。

还可以留意代码生成与 CFG 的一个平行结构：IR 的基本块与
CFG 节点大致一一对应（分支、循环头各一块），但 IR 额外
需要 merge 块与插入点管理，因为 LLVM IR 要求每个块有且
仅有一个终结符。CFG 允许 Branch 直接分叉、后继隐式汇合；
IR 必须显式建 merge 并用 Br 跳过去。读两个文件时对照"图
上的汇合"与"IR 里的 merge 块"，能体会不同 IR 设计（带
phi 的 SSA、跳转式、sea-of-nodes）各自要求前端补什么。

jitrun.hpp/cpp 用 ORC LLJIT 接管模块，注入宿主函数
tip_input/tip_output，真实执行 tip_entry 并收集输出。它是
成员检验中"具体执行值"的来源。

```cpp
// file: src/jitrun.hpp
// ORC JIT 执行：把 IRGen 的模块交给 LLJIT，注入 tip_input/tip_output
// 两个宿主 C 函数，真实执行 main，收集输出序列。
#pragma once

#include <vector>

#include "irgen.hpp"

namespace tip {

// 一次执行：inputs 按出现顺序被 tip_input 消费，返回 output 值序列。
// 模块所有权随 IRGen 一起移入 JIT。
std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs);

}  // namespace tip
```

接口只有一个函数 runJit，两个要点写在注释里：inputs 按出
现顺序被 tip_input 消费，返回 output 值序列；IRGen 按值
传入（内部是三个 unique_ptr），模块所有权随这次调用整体
移入 JIT——执行结束后模块与上下文随 JIT 对象一起释放。

```cpp
// file: src/jitrun.cpp
#include "jitrun.hpp"

#include <cstdint>
#include <stdexcept>

#include "llvm/ExecutionEngine/JITSymbol.h"
#include "llvm/ExecutionEngine/Orc/Core.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/ExecutionEngine/Orc/ThreadSafeModule.h"
#include "llvm/Support/TargetSelect.h"

using llvm::StringRef;
using llvm::JITSymbolFlags;
using llvm::orc::ExecutorSymbolDef;
using llvm::JITTargetAddress;
using llvm::jitTargetAddressToFunction;
using llvm::pointerToJITTargetAddress;
using llvm::orc::LLJITBuilder;
using llvm::orc::SymbolMap;
using llvm::orc::ThreadSafeModule;
using llvm::orc::absoluteSymbols;

namespace tip {
namespace {

// JIT 模块通过这两个宿主函数与外界交换数据。
const std::vector<int> *inQueue = nullptr;
std::vector<int> *outQueue = nullptr;
size_t inPos = 0;

extern "C" int32_t tip_input() {
    if (inPos >= inQueue->size()) return 0;
    return (*inQueue)[inPos++];
}

extern "C" void tip_output(int32_t value) {
    outQueue->push_back(value);
}

void initNative() {
    // 进程内只初始化一次。
    static const bool ready = [] {
        llvm::InitializeNativeTarget();
        llvm::InitializeNativeTargetAsmPrinter();
        return true;
    }();
    (void)ready;
}

[[noreturn]] void fail(llvm::Error e) {
    std::string text = llvm::toString(std::move(e));
    throw std::runtime_error(text);
}

}  // namespace

std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs) {
    initNative();
    std::vector<int> outputs;
    inQueue = &inputs;
    outQueue = &outputs;
    inPos = 0;

    auto jitOrErr = LLJITBuilder().create();
    if (!jitOrErr) fail(jitOrErr.takeError());
    auto jit = std::move(*jitOrErr);

    auto defineHost = [&](StringRef name, void *addr) {
        SymbolMap symbols;
        symbols[jit->mangleAndIntern(name)] = ExecutorSymbolDef(
            llvm::orc::ExecutorAddr::fromPtr(addr), JITSymbolFlags());
        if (llvm::Error e =
                jit->getMainJITDylib().define(absoluteSymbols(symbols)))
            fail(std::move(e));
    };
    defineHost("tip_input", reinterpret_cast<void *>(&tip_input));
    defineHost("tip_output", reinterpret_cast<void *>(&tip_output));

    ThreadSafeModule tsm(std::move(gen.mod), std::move(gen.ctx));
    if (llvm::Error e = jit->addIRModule(std::move(tsm)))
        fail(std::move(e));

    auto mainAddr = jit->lookup("tip_entry");
    if (!mainAddr) fail(mainAddr.takeError());
    auto *entry = jitTargetAddressToFunction<int (*)()>(mainAddr->getValue());
    entry();

    return outputs;
}

}  // namespace tip
```

实现的前半段是两个宿主函数（第 36–47 行）：tip_input 从
输入向量按全局游标依次取值，取完后返回 0（对"输入不够"
的保守定义）；tip_output 把值推进输出向量。它们用
extern "C" 声明，关闭 C++ 的名字修饰，JIT 端按符号名查找
时才能对得上。initNative（第 49–66 行）用函数内 static
保证本机目标与汇编器打印只初始化一次。

runJit（第 57–89 行）的流程是本章经验检验的最后一环：建
LLJIT；defineHost（第 68–75 行）把宿主函数地址经
absoluteSymbols 注册进主 JIT 库——先 mangleAndIntern 再
绑定 ExecutorSymbolDef；把模块包成 ThreadSafeModule 移入；
lookup tip_entry 得到入口地址，用 jitTargetAddressToFunction
转成函数指针后真实调用。任何 LLVM Error 都经 fail 转成
C++ 异常，不会被静默吞掉。

这里最值得体会的是 JIT 带来的"同语言对照"：被分析的程序
与分析器是同一个 C++ 进程里的两段代码，具体执行不需要第
三方运行时、子进程或文件往返。成员检验因此可以放进普通
回归：给定输入、断言输出属于预测区间。第 35 章的可信度论
证由此闭合——形式化（21.3/21.11）给出"对所有执行成立"，
JIT 对照给出"实现确实按形式化在跑"。

值得再解释一下宿主函数为什么能这样"零仪式"地被注入。ORC
体系下，JIT 库解析一个外部符号时，除了查找已编译的模
块，还查找注册进去的绝对符号表；absoluteSymbols 把"名字
→本机地址"直接登记，于是被 JIT 代码 call 的 tip_input，
在经过一次常规的调用指令后就落进我们进程内的 C 函数。这
里没有 RPC、没有进程边界、没有编组开销，数据共享只靠同
一地址空间里的指针（inQueue/outQueue）。也正因为如此，
宿主函数必须是 extern "C" 且无捕获的纯函数：地址被当作普
通 C 调用目标，不能携带 C++ 闭包状态；状态通过文件内的静
态指针传入。

这种"编译后的程序回头调用编译器进程函数"的模式，在真实
系统里用途很广：JIT 语言的 FFI、内核 eBPF JIT 与辅助函
数、数据库的查询 JIT 调用向量化算子，结构都与此相同——
JIT 产出快路径，慢路径或与外部世界的交互留在宿主侧。本
章的两个小函数就是这一模式的最小完整实例。

也请注意 runJit 每次新建 LLJIT、每次移入独立模块：多次
执行间除了进程级的 initNative 外没有共享状态，输入队列
也逐次重置。这保证检验可以连续跑任意多行输入而不会互相
污染，任何一次失败都能精确定位到那一行。

### 35.12.5 总装 main.cpp

main.cpp 是本章的命令行总装：`--check` 构建 CFG、先跑
solveWidenedInterval 再跑 narrowPass，打印轨迹与两个观察
点的前后对照；`--verify-soundness` 收集 output 站点、逐行
执行并判定成员关系。21.4 与 21.10 的讨论都以它为落地处，
这里完整嵌入。

```cpp
// file: src/main.cpp
// 第 35 章配套程序：widening ∇ / narrowing Δ + 区间预测的可靠性检验。
//   --check FILE           : 打印 ∇ 迭代轨迹与 Δ 收窄前后的关键点区间
//   --verify-soundness FILE INPUTS : 每行输入 JIT 真执行，
//                            断言具体输出落在（收窄后的）预测区间内
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "symtab.hpp"
#include "widen.hpp"

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

std::vector<int> parseRun(const std::string &line) {
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

}  // namespace

int main(int argc, char **argv) {
    const int maxRounds = 50;

    if (argc == 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        tip::WidenedResult w = tip::solveWidenedInterval(cfg, *p.ast, maxRounds);
        std::map<int, tip::IvEnv> narrowed =
            tip::narrowPass(cfg, *p.ast, w.out);

        std::cout << "== interval lattice, widening (cap " << maxRounds
                  << " rounds) then narrowing ==\n";
        std::cout << "widening point: loop head node " << w.headNode << "\n";
        for (const std::string &line : w.trace) std::cout << line << "\n";
        std::cout << (w.converged ? "CONVERGED" : "DID NOT CONVERGE")
                  << " after " << w.rounds << " rounds (with widening)\n";

        // 关键点对照：循环头与第一个 output 点，∇ 解 vs Δ 之后。
        std::set<std::string> vars(p.ast->funs[0]->vars.begin(),
                                   p.ast->funs[0]->vars.end());
        int outputNode = -1;
        for (const auto &[id, node] : cfg.funs[0].nodes)
            if (dynamic_cast<const tip::OutputS *>(node.stmt) && outputNode < 0)
                outputNode = id;
        std::cout << "after WIDEN : head " << tip::printIvEnv(w.out[w.headNode], vars)
                  << "  output " << tip::printIvEnv(w.out[outputNode], vars) << "\n";
        std::cout << "after NARROW: head " << tip::printIvEnv(narrowed[w.headNode], vars)
                  << "  output " << tip::printIvEnv(narrowed[outputNode], vars) << "\n";
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--verify-soundness") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        tip::WidenedResult w = tip::solveWidenedInterval(cfg, *p.ast, maxRounds);
        std::map<int, tip::IvEnv> narrowed = tip::narrowPass(cfg, *p.ast, w.out);

        // output 语句 → CFG 节点（区间预测按节点状态查询）。
        std::map<const tip::Stmt *, int> nodeOf;
        for (const auto &[id, node] : cfg.funs[0].nodes)
            if (node.stmt) nodeOf[node.stmt] = id;

        // 按 AST 语句顺序收集 output 语句（与 JIT 输出顺序一一对应）。
        std::vector<const tip::OutputS *> sites;
        struct Walk {
            static void go(const tip::Stmt *s,
                           std::vector<const tip::OutputS *> &out) {
                if (const auto *b = dynamic_cast<const tip::BlockS *>(s)) {
                    for (const auto &x : b->ss) go(x.get(), out);
                } else if (const auto *i =
                               dynamic_cast<const tip::IfS *>(s)) {
                    go(i->then.get(), out);
                    if (i->els) go(i->els.get(), out);
                } else if (const auto *w =
                               dynamic_cast<const tip::WhileS *>(s)) {
                    go(w->body.get(), out);
                } else if (const auto *o =
                               dynamic_cast<const tip::OutputS *>(s)) {
                    out.push_back(o);
                }
            }
        };
        Walk::go(p.ast->funs[0]->body.get(), sites);

        int run = 0, obs = 0;
        bool allOk = true;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);
            ++run;

            bool ok = true;
            for (size_t k = 0; k < outputs.size() && ok; ++k) {
                const tip::OutputS *site = sites[k];
                int nid = nodeOf.at(site);
                // 预测区间：在该 output 点的状态下抽象求值输出表达式。
                tip::Iv predicted =
                    tip::evalIv(site->e.get(), narrowed.at(nid));
                std::cout << "run " << run << ": outputs " << outputs[k]
                          << " ; predicted " << tip::ivText(predicted);
                if (predicted.lo > predicted.hi || outputs[k] < predicted.lo ||
                    outputs[k] > predicted.hi) {
                    std::cout << " ; UNSOUND\n";
                    ok = false;
                } else {
                    std::cout << " ; membership OK\n";
                    ++obs;
                }
            }
            if (!ok) allOk = false;
        }
        std::cout << (allOk ? "SOUND " : "FAILED ") << run << " runs, " << obs
                  << " observations\n";
        return allOk ? 0 : 1;
    }

    std::cerr << "usage: tipa --check FILE | tipa --verify-soundness FILE INPUTS\n";
    return 1;
}
```

main.cpp 是把前面所有文件串成两个命令的总装，按"共享的前
端 + 两个模式"来读最清楚。

共享前端分两层。CollectErrorListener（第 29–40 行）替换
ANTLR 的默认错误监听，把语法错误收集成文本而不是直接打印
到 stderr；parseFile（第 43–75 行）是所有模式的共同入
口：打开文件（失败退 1）、跑词法/语法（语法错误退 2）、
buildAst、resolveNames（语义错误退 3）。退出码 1/2/3 的分
层让外部脚本能区分"用法/文件问题、语法问题、静态语义问
题"。parseRun（第 77–83 行）把一行文本切成整数向量，供
--verify-soundness 作为一次执行的输入。

--check 模式（第 90–117 行）对应 21.4–21.9 的内容：构
CFG，先 solveWidenedInterval 再 narrowPass；打印标题、加
宽点号、逐轮轨迹、收敛结论；然后做本章最有展示价值的
"关键点对照"——同一段输出里先给 ∇ 解的循环头与第一个
output 区间，再给 Δ 之后的同一两点。两行间的差异（头部
[0,+∞]→[0,10]、输出 [1,10]→[10,10]）就是本章精度故事的
全部。

--verify-soundness 模式（第 119–200 行）对应 21.10。三个
实现要点在代码里都找得到：第 132–134 行先建"语句→节点
号"映射，预测要按节点状态查询；第 137–156 行用一个内嵌
Walk 结构按 AST 顺序收集 output 语句，顺序必须与 JIT 的输
出序列一一对应；第 161–196 行逐行读取输入文件（空行与 #
注释行跳过），每一行都新建 IRGen、gen、verify、runJit——
新鲜 IR 模块保证多次执行互不串味。判定在第 186–187 行：
预测为 ⊥，或具体输出落在区间之外，即 UNSOUND；否则
membership OK 并计入观察数。末尾汇总 SOUND/FAILED、执行
次数与观察次数，整体成功才返回 0——因此它可以直接充当回
归断言。

把 main.cpp 与其他章节的 main.cpp 并排看，能看出一条清晰
的演化线：第 34 章总装的是 runNaiveInterval（封顶 50 轮、
报告不收敛），本章把同一个程序接上新的 ∇/Δ 两阶段并加了
成员检验，而前端 parseFile 一字未改。分析能力的每次升级，
都只是在"前端产出的 AST/CFG"与"观察输出"之间更换中间那
段求解器。

读懂了这个总装，就可以再回答一个贯穿本章的方法论问题：
为什么"打印给人看"与"断言给机器用"要分成两个模式，而不
是一个输出两用？

--check 的读者是人，它的设计目标是让轨迹可逐行研读：每轮
一行、关键点前后对照、收敛结论明确。它包含叙述性标题、
对齐的布局，并且不设失败退出（分析总能跑完）。
--verify-soundness 的读者是回归系统（以及想快速确认的
人），它的输出是一条条机读友好的判定行，末尾的 SOUND/
FAILED 直接决定进程退出码。两种用途对"冗余"和"严格"的要
求相反：人读模式宁可多给上下文，检验模式必须无歧义、可
grep、退出码可信。合成一个模式往往两头不讨好。

另外注意输入文件语法的两条约定（第 163–165 行）：空行忽
略、以 # 起首的行是注释。它们让输入文件可以带说明文字与
分段空行，而不必为测试数据另配文档。每行非注释文本代表
一次独立执行、一行内的整数序列即该次执行的全部 input
值。widen.tip 没有形参也不调用 input，所以三行输入实际上
不被消费、触发的是三次相同执行——检验的价值在于"同一程序
多次执行结果稳定地属于预测区间"，而不是靠输入改变路径。
第 36 章的程序会真正利用输入，让不同行走出不同路径。

最后是一个容易看漏的健壮性细节：--verify-soundness 在生
成 IR 后立即 verify（第 170 行），verify 失败立刻以码 1 退
出，而不是让畸形模块在 JIT 内部以晦涩错误爆掉。错误尽可
能在"离成因最近"的位置被报告，是贯穿整个工具链的风格。

### 35.12.6 文件依赖与构建顺序

把 18 个复用文件连同本章两个新文件放在一起，可以画出一条
清晰的依赖方向，理解构建系统为什么可以用一条命令完成。

最底层是语言定义 TIP.g4：ANTLR 在构建第一步读它，生成
TIPLexer、TIPParser（以及 Listener/Visitor 基类）。任何
include TIPParser.h 的文件都依赖这些生成产物，因此构建规
则必须保证"先跑 ANTLR、再编译 C++"。ast.hpp 不依赖
ANTLR，它是纯数据定义，处于与文法并列的另一条底层线。

往上一层是消费者。ast_build.hpp/cpp 同时依赖 ANTLR 生成
头与 ast.hpp，它把 parse tree 翻译成 AST，是两条底层线的
交汇点。pretty 只依赖 ast.hpp。symtab 只依赖 ast.hpp。
cfg 依赖 ast.hpp，实现文件额外依赖 pretty（打印节点语
句）。这四个模块彼此独立：它们都只读 AST，互不 include，
因此可以并行编译，也可以被任意组合使用。

再往上是分析层。interval.hpp/cpp 依赖 ast、cfg、lattice；
lattice.hpp 无任何项目内依赖。widen.hpp/cpp 依赖 cfg、
ast、interval 与 lattice——它复用 evalIv 与格接口，自己
只增加 ∇/Δ、边精炼与 LocalWiring。

执行层 irgen 依赖 ast 与 symtab（用绑定）；jitrun 依赖
irgen（按值接管其所有权）与 LLVM ORC 库。最顶层 main.cpp
依赖前端全部模块 + widen，把两档命令拼起来。

这条依赖链是严格无环的：没有任何低层模块 include 高层模
块。它的工程意义是：改动 widen 不会引起前端重编（头文件
依赖不向下传播）；替换前端实现（假设换一个解析器生成
器）只要产出同样的 AST，后面全部模块无需改动。分层一旦
在 include 关系上被严格遵守，"重构不扩散"就不是纪律要求
而是结构必然。

构建顺序由此也很机械：跑 ANTLR 生成词法/语法器；编译全部
.cpp（依赖头文件关系决定先后，但 C++ 编译单元本身彼此独
立）；链接 LLVM 核心、ORC、目标后端与 ANTLR runtime。
llvm.need 文件列出所需的 LLVM 组件，供构建脚本读取，避免
手工维护一长串库名——这是"把易变清单外置"的小技巧，
LLVM 版本升级时只改一处。

顺带说明一个构建卫生细节：ANTLR 的生成产物（TIPParser.cpp、
TIPLexer.cpp 等）与编译中间文件都不进入源码仓库，它们可
由构建随时重建。教程的嵌入规则也只要求嵌入 TIP.g4（生成
器输入）而非生成结果——生成产物依赖具体 ANTLR 版本，纳入
仓库只会制造无谓的版本冲突。判断"一个文件该不该入库"的
通用标准是：能否由已入库的文件确定性地重新生成；能，则
忽略。.gitignore 在示例目录与构建输出目录两级把这些产物
挡住。

最后用一句话把本节依赖图与 21.11 的论证层次对应起来：依
赖图的底层（文法、AST）对应分析对象的来源，中层
（CFG、格、区间算术）对应单调方程组的构造，顶层
（widen、main）对应不动点迭代与经验检验。代码的分层与可
靠性的论证层次因此是同构的——这不是巧合，而是先有论证
蓝图、再按图组织代码的结果。这也给维护者一个实用建议：
新增一个分析时，先想清楚它在依赖图上该挂在哪一层、需要
哪些只读输入，再动手写代码；如果发现要向下修改低层接
口，通常意味着分层设计本身需要重新审视，而不是硬加字
段。让代码结构持续与论证结构保持同构，是长期演化中最省
力的状态。教程每章的代码清单都按此原则摆放，读者也可
以借这一同构关系反向定位概念在代码中的位置。例如想找
∇ 的定义就进入顶层求解文件，想确认环的构造就回到 CFG 模
块，映射关系一一对应、无需猜测。

### 35.12.7 常见疑问汇编

以下汇集阅读本章材料时最常出现的疑问，集中作答，便于复
习时快速定位。

问：widening 会不会把真正可能的值"跨丢"？答：不会，依据
是上界性质 x⊑x∇y、y⊑x∇y。无论 ∇ 把区间跨得多远，两个
输入区间都被结果包含；迭代中所有曾经出现过的值仍然在新
区间里。它只可能"多报"，不可能"漏报"。阈值表只决定跨到
哪里，不改变包含关系。

问：为什么阈值里有 0 和 1，却没有 2、3？答：阈值是精度
与终止性的平衡点。加入程序中出现的全部常量通常划算（有
限集合），加入所有整数则等于没有 widening（永远选到精确
新值、链无限长）。0、1 是几乎所有循环计数都会触及的端
点，本章再放 +∞/−∞ 构成最小教学表；练习一让读者亲手加入
10，观察精度如何被提前买断。

问：narrowing 之后还需要再验证可靠性吗？答：需要论证、不
需要重跑前提。Δ 的规则保证结果不低于原方程在该点的解
（取 join 后再只收无界端），因此 Δ 输出仍然包含 LFP；
JIT 检验在 Δ 输出上做，正好把这层保证也纳入经验覆盖。

问：nested loop（嵌套循环）下加宽点怎么选？答：每个自然
循环各选一个割点——内层循环头与外层循环头都做 ∇。终止
性论证按"内层先有限、外层再有限"分层进行：内层被 ∇ 截断
后对外层相当于一个单调的有限步组件，外层 ∇ 再截断整体。
收窄往往需要多趟（外层信息依赖内层稳定），所以实现里 Δ
应写成"到稳定"的循环。

问：如果程序含不可达代码，区间会是什么样？答：不可达点
的前驱全部为 ⊥ 时，join 结果为 ⊥，该点保持底；其输出预
测也是 ⊥。注意 JIT 检验里"预测为 ⊥"被直接判为失败信号
（⊥ 声称该点不可达，而真有输出到达就说明声称错误），这
让"可达性分析错误"也能被成员检验抓住。

问：widening 与类型系统里的"泛型/多态"是不是同一种抽
象？答：不是，二者都"丢失信息"但目的不同。多态丢失的是
"具体类型"以换取对一族类型复用，它是**精确的**：对任何
具体实例化，多态结论逐点成立。widening 丢失的是"具体值
集合的形状"以换取终止，它是**近似的**：结果比可能值集合
大，不能逐点还原。

问：能否对字符串、浮点做 widening？答：可以，思路相同：
先定义无限高（或高度极大）的性质格，再选有限阈值与跨变
算子。浮点区间（含 NaN/±0）、字符串前缀/长度区间都有现
成研究；工程上更常见的是直接把这些性质映射回有限前缀域
或有界集合。核心始终是那两条：跨得过去（上界）、有限次
跨完。

问：worklist 算法里加宽点上的处理与 round-robin 有何不同
？答：迭代策略与加宽相互独立。worklist 在节点状态变化时
才重算，加宽点每次重算都对"旧值"与"新 join"做 ∇；要点
是 ∇ 的第一个参数必须是**该点上一轮的稳定值**，不能在同
一轮多次重复 ∇（那样会连续跨大步）。round-robin 天然每轮
每点一次，worklist 则需保证 ∇ 的使用频率受到轮次概念约
束——本章实现采用"轮次 + 每轮一次"的混合组织，正是为了
简单地满足这一点。

问：如果条件里是逻辑连接词（and/or）怎么办？答：TIP 没
有布尔运算，条件只含单个比较。扩展时标准做法是把
and/or 在 CFG 上展成分支点序列（短路语义），每个原子比
较各产生一对带精炼的边。区间在分支路径上逐步取交，得到
合取条件的精炼；析取则像普通分叉一样最终 join。

问：widening 之后区间里出现"端点倒置"意味着什么？答：边
精炼把区间压成 lo>hi（例如假边把上界压到下界之下），语
义上是"这条边不可能被走到"，即矛盾、路径不可达。求解器
按 ⊥ 处理它；若程序实际会走到该边（JIT 有输出），成员检
验立刻报错。这是边精炼与可达性分析互相校准的机制。

问：为什么不一开始就用最精确的可终止域（例如 Presburger
约束）？答：精确域的代价是计算复杂度——整数线性约束的一
般可满足性是高复杂度的判定问题，每步迭代都调用会使分析
在大程序上不可用。工程分析的主流是"廉价的非关系域（区
间）+ 局部关系升级（差约束/同余）"，按预算逐级加深，而
不是一步到位追求完备。可靠性从不要求精确，只要求包含。

问：∇ 的阈值表在分析中途可以扩充吗？答：可以，但要小
心。扩充阈值本身不破坏可靠性（上界性质与阈值内容无
关），却可能破坏"已经终止"的结论——新刻度允许已稳定的
端点再次移动，迭代必须重新开放。实践中阈值集在分析开始
前一次确定。

问：widening 迭代里，非加宽点节点的 join 要不要也换成什
么特殊运算？答：不要。直线节点与分支汇合点仍然用普通
join；它们不在任何环的关键回路上，经过它们的信息即使暂
时增长，也会被下游的加宽点截断。∇ 用得越少，最终精度越
高，这是一条直接的操作原则。

问：分析多个函数（但不做上下文区分）时，widening 在每个
函数内独立吗？答：是。第 46 章的过程间框架把函数调用当
作"参数流进、返回值流出"的边，每个函数体内部的环各自
配置加宽点；跨函数的递归环则需要在函数粒度上再有一个截
断（深度或上下文数上限），否则函数互相递归同样会产生无
限上下文链。本章程序只有一个函数含环，不涉及这层。

问：Δ 之后若还想继续提升精度，正规的下一步是什么？答：
不是再跑 Δ（规则已不移动），而是换更强的域（21.12.11）
或引入路径敏感（下一章）。精度的天花板由"域的表达力"与
"路径区分度"共同决定，迭代技巧只能逼近这个天花板，不能
突破它。

问：手工推演时，怎么快速判断"这一轮哪些点会变化、哪些
不用算"？答：数据流的变化沿边传播——只有前驱输出变化的
节点才可能变化。从加宽点的稳定与不稳定出发，顺边标记受
影响的下游集合即可；这正是 worklist 的手工版。21.5 的推
演里，第 3 轮头部跨到 +∞ 后，节点 4、5 依次重算，而节点
2（x=0）的前驱只有入口、永远不变，可以跳过。养成"沿边追
化"而不是"每轮全算"的习惯，对读懂大程序的分析日志很有
帮助。

问：区间端点在 widening 后会不会保留一个"其实不可能的
有限端点"？答：会，这是正常的精度损失而非错误。例如阈
值 1 保住的下界，在某条路径上或许只来自第一次进入循环，
但区间无法区分"首次"与"后续"。可靠性只要求包含可能值，
不要求每个端点都被某条路径取到——后者是"最小性"，代价
高昂且通常不追求。

问：本章方法能处理"循环次数依赖 input"的程序吗？答：终
止性没有问题（∇ 与输入无关，该跨就跨）；精度上最终区间
往往按全区间处理依赖输入的上界，Δ 收不回未知边界。若需
要"对任意输入都证明某性质"，这正是区间域的常规输出：结
论以无界形式成立，可靠但宽泛。

问：如果两种分析的输出区间一样，能说明它们精度相同吗？
答：对单个观察点而言是；对整个程序而言要比较全部点的环
境。两档技术可能恰好在某个程序上结果一致（本章 unbounded
与 k=2 在第 47 章就是如此），却具有不同的一般表达能力——
区分"这一个程序上的结果"与"方法的一般精度"，是评测分析
技术时必须保持的清醒，不要从单例推断方法等价。

问：把本章程序的循环改成 `while (x != 10)`，分析会有什
么变化？答：区间表达不了"不等"条件——边精炼对 != 无可施
为（它只能处理半直线），头部经 ∇ 仍停 [0,+∞)；Δ 也无法
利用条件收回上界，最终头部保持无界（尽管具体值确实在 10
停止）。这不是可靠性问题（10 仍在区间内），而是典型的
"条件形状超出域表达力"导致的精度损失。

问：本章可靠性论证中，"边精炼"这一层需要单独证明什么？
答：需要证明它保持成员关系——若具体值 v 属于精炼前区
间，且该边在具体执行中确实被走到（条件具有相应真值），
则 v 也属于精炼后区间。论证就是半直线取交：真边把区间
与 (k,+∞) 或 (−∞,k) 取交，具体条件真值保证 v 在该半直线
内。它与 evalIv 的局部可靠性并列，共同组成 21.11 的第一
层：信息在"节点传递"与"边条件"两处都不会把真值丢掉。

### 35.12.8 术语对照

本节把全章术语按"形式化—代码—直觉"三列对照列出，复习时
可逐条自测能否互译。

最小不动点（LFP, lfp(F)）：代码里迭代从全 ⊥ 出发单调逼近
的极限；直觉是"方程允许的最小、最准的稳定状态"。

加宽算子 ∇（widen.hpp 的 widen）：在加宽点替代 join 的跨
变；直觉是"与其一小步一小步追不上，不如一步跨过剩余的整
段"。

收窄算子 Δ（narrow）：∇ 解之上用原方程试探收回；直觉
是"大步跨过头之后，低头看看其实能收回来多少"。

加宽点（widenPoints，while 头）：环上的割点；直觉是"每
个循环只需在一个必经位置换大步走"。

阈值表 T（THR 数组）：∇ 落点的候选刻度；直觉是"尺子的
刻度，跨变只能停在刻度上"。

边函数/分支精炼（refineOnBranch）：在条件边上把区间与半
直线取交；直觉是"走到这一步时，条件刚刚告诉了我们一个
事实"。

不可达底 ⊥（Iv{1,0}）：lo>hi 的区间；直觉是"这个点根本
不会执行到"。

顶 ⊤（Iv{INT_MIN,INT_MAX}）：全区间；直觉是"什么都确定
不了"。

单调函数（传递函数族）：x⊑y⇒F(x)⊑F(y)；直觉是"知道得
更多，结论只会更准、不会反转"。

可靠/健全（sound）：预测集合包含一切真实可能值；直觉
是"可以不精确，但不能说谎"。

精度（precision）：在可靠前提下区间有多窄；直觉是"不撒
谎的前提下能多确定"。

成员关系（concrete ∈ interval）：JIT 检验的判定标准；直
觉是"不问猜得准不准，只问有没有把真值圈进来"。

### 35.12.9 复用而非重写：一份成本核算

最后做一笔本章新代码的"成本核算"，它具体展示了分层带来
的节省规模。

本章真正新写的逻辑只有五块：∇ 的阈值选择（widen 中十余
行分支）、加宽点识别（一次 AST 扫描）、Δ 的单端收紧、边
精炼（四种比较形状的归并）、LocalWiring（重演编号与连
边）。widen.cpp 全部约 370 行，其中还有相当篇幅是与
interval.cpp 同构的迭代骨架。

被免费复用的是：完整词法/语法分析（文法 + ANTLR 运行
时）、AST 与构建（约 160 行）、符号表（约 120 行）、CFG
（约 160 行）、区间算术与格（约 380 行）、IR 生成（约
230 行）、JIT 执行（约 90 行）。合计逾 1100 行久经检验的
基础设施，加上 ANTLR/LLVM 两个工业级库。

如果没有前面章节冻结的这些接口，本章要同时发明语言、图
结构、算术与执行台，widening 反而会成为最不起眼的部分。
这正是教程把工具链铺在理论之前的理由：先让"可被分析的
程序"与"可被信任的执行"就位，每个新概念才能以最小新增
代码登场，读者注意力得以集中在概念本身，而不是脚手架。

### 35.12.10 与 spa 教材的命题对照

本节把本章用到的形式结论与 spa 教材 4.7、4.8 两节的命题
逐一对照，帮助读者在教材与代码之间来回印证。

教材关于 ∇ 的第一条结论是**终止性定理**：若序列
x₀=⊥、x₁=x₀∇y₀、x₂=x₁∇y₁、… 中，yₙ 本身是某个上升序列
（具体说，yₙ 单调上升），则 xₙ 必然在有限步稳定。教材
的论证骨架与 21.3 给出的一致：∇ 的结果端点只能落在阈值
上，而阈值有限；每当序列严格变化，至少一个端点在有限阈
值集上单向移动，单调且有界的移动不可能无限继续。本章
widen.cpp 的四轮稳定是该定理的一个实例。

第二条结论是**可靠性定理**：上述 xₙ 的极限（记 X∇）满足
两条——它是原方程某个后固定点（X∇⊑F(X∇) 方向上的稳定
性，具体为 F(X∇)⊑X∇，即它"不会被方程推得更高"），并且
lfp(F)⊑X∇。前一条说明 ∇ 解确实被方程接受为一个稳定的上
界；后一条说明它覆盖最小不动点、因而包含一切真实可达状
态。21.11 的第三层论证复述的就是这两条，务必区分"固定
点"与"最小不动点"：∇ 解是（后）固定点但不是最小的。

教材关于 Δ 的结论相应有两条。其一，若 Δ 满足 y⊑x⇒y⊑xΔy⊑x
（收窄条件），则从 X∇ 出发迭代 Δ 的序列单调下降且始终在
LFP 之上——起点 X∇ 在 LFP 之上，每一步的新下界 xΔy 又包含
y（方程在 x 处的解，LFP⊑y），归纳得全程可靠。其二，该
序列有限步稳定（同样依赖 Δ 的每次变化只能沿有限方向移
动）；但稳定点不必是不动点——它只是"旧解与方程相互折中
后不再变化"的点，可能仍略高于 LFP。本章实例里它恰好也
是精确解，但这是程序形状的幸运，不是定理承诺。

把这四条定理与代码对照时，可以注意教材的论证从不依赖
"区间"这一种格：它们对任何具有 ∇/Δ 的完全格都成立。本
章选区间，是因为它无限高、需要这套技术，同时运算直观、
可手工推演。读懂了这层一般性，就能把同一套证明搬到任何
新性质域——这也是 21.12.7 中"能否对字符串/浮点 widening"
一问的理论依据。

还有一个阅读教材时容易卡住的术语点：教材称 ∇ 的迭代为
"加速"（acceleration），称 Δ 为"减速/改善"（improvement）。
这两个词描述的是"逼近不动点的速度"而非执行速度——∇ 加速
收敛（以精度为代价），Δ 改善精度（以额外迭代为代价）。
本章 main.cpp 的两阶段输出正好让"先加速、后改善"成为肉眼
可见的两行对照。

### 35.12.11 区间域的边界与后续性质域导览

本章以区间域为载体，但区间只是抽象解释家族里最简单的非
关系域之一。了解它"算不准什么"，才能理解后续章节与工业
工具为何要引入更强的域。本节做一次简短导览，全部以直觉
与表达能力为主，不展开实现。

区间域是非关系的：它为每个变量独立保存一个区间，无法表
达变量之间的关系。练习六已经展示了盲区：x∈[0,10]、y 单
独看是 [0,+∞)，即使程序保证 y=2x，区间也交不出这个等
式。后果在真实分析中随处可见：数组下标检查里 `a[i]` 与
`i<n` 的关联、缓冲区大小与已写字节数的同步，非关系域只
能分别放宽，误报率居高不下。

第一级升级是**差约束域**（difference-bound / 简单同余域）：
保存形如 x−y≤c 与 x≡r(mod m) 的有限约束。它能表达
y=2x 之外的大量线性关系中"两个变量之差有界"的部分——
循环计数、索引与边界的距离正是这种形状。约束以有界权图
存储，join 与 widening 都有标准定义，成本仅比区间高一个
量级却能显著降低误报。

第二级是**八边形域**（octagon）：允许 ±x±y≤c，即两个变
量（取正或取负）之和有界；它是差约束的对称扩展，能表达
"两变量同涨同落"，在数组区域分析中常用。

第三级是**线性凸多面域**（polyhedra）：任意线性不等式组
合，y=2x 这类等式可直接表达。表达力最强，但运算代价高，
工程上通常只在关键代码段局部启用，或用其轻量子类。

再往后是非数值方向：与本教程后面章节直接相关的，是把同
一套"格 + 不动点 + 需要时 widening"框架用于**集合性质**
——指针可能指向谁（第 51 章的 Andersen/Steensgaard）、
类型状态、信息流。载体从区间换成幂集或其近似，终止性问
题以"有界地址集合/深度截断"解决。∇/Δ 的思想一以贯之：
逼近不动点时，用一个保证有限步的上跨算子换终止，再尝试
收回。

记住这张"精度—成本谱"还有一个实际用途：遇到工具的误报
时，判断该升级哪一层。若误报源于"变量区间各自太宽但彼
此相关"，升级关系域；若源于"路径条件没有被利用"，那是下
一章路径敏感要解决的另一正交维度——关系域与路径敏感可以
叠加，它们回答的是两个不同问题："变量之间什么关系"与
"哪些路径可达"。

第 35 章在这个谱系中的位置因此很清楚：它不追求强性质，
它解决的是更基础的前提——**无论性质多强，无限高域上的不
动点迭代必须先学会终止**。这个前提对后续所有数值域同样
成立。

还可以补充一条选域的实用经验：工业静态分析器很少"全域
一档"，而是按代码片段分级——简单计数循环用区间，数组密
集代码局部提升到差约束/八边形，只在用户标注的关键函数上
才考虑多面域。这种分级的依据是各域之间存在"可靠的近似
投影"：强域的结论总能映射回弱域而不失可靠（丢掉部分约
束即可），因此不同片段以不同精度分析、在函数边界处投影视
齐，整体仍然可靠。理解了这一点，就理解了为什么本教程先
把最弱的域讲透：它是所有强域在投影后的归宿，也是工程上
最常兜底的那一层。

## 35.13 工程注意点

1. **∇ 只施加在环的割点上。**对每个自然循环至少要在一个
  必经点做 widening；while 头是最小且最易收窄的选择。滥
  用 ∇（在直线节点上也做）无终止收益，只会无谓损失精度。
2. **阈值表把程序常量收进来几乎总是划算的。**生产实现的
  常见做法是扫描程序中的整数常量（再加 0、1）自动构造阈
  值集——它仍然有限，终止性不变，却常常使 Δ 变得不必
  要。本章刻意只用四个阈值，是为了让 ∇/Δ 的各自贡献可教。
3. **Δ 通常只跑一趟，但别把它当保证。**一趟收窄是经验规
  律，不是定理；换一个程序（尤其嵌套循环）可能需要多趟。
  实现时应把收窄也写成"直到稳定"的循环并保留轮数上限。
4. **LocalWiring 是规则的复制品，不是独立的实现。**cfg.cpp
  的编号/连边规则一旦改变，widen.cpp 的 LocalWiring 必须
  同步，否则真假边会错配而程序可能仍然编译运行——这类错误
  只能靠 21.10 的成员检验兜底。保留它的决定应与"接口冻结"
  的承诺放在一起权衡。
5. **成员检验不是可靠性证明。**JIT 对照只能跑有限输入，抓
  实现错误可以，证明"对所有执行成立"要靠 21.11 的形式论
  证。把检验写进回归能防止实现退化，但不能替代抽象论证。
6. **∇ 要防"同一轮重复施加"。**一次状态更新内对同一点连续
  做两次 ∇ 会连跨两大步、损失本可保留的精度；以轮次为单位
  施加一次即可。Δ 重复施加在"只收 ±∞ 端"的规则下不会再移
  动（端点已有限），浪费的只是计算。
7. **哨兵算术要全链路一致。**INT_MIN/INT_MAX 一旦被当作真
  值参与比较或打印，分析与执行就会错位；所有读写哨兵的地
  方（饱和运算、阈值比较、ivText）都应先判哨兵再走普通分
  支。把"无穷不是一个大数"作为团队约定写在代码旁。
8. **把分析日志设计成"可重演"的。**每轮一行、节点号稳定、
  环境打印固定变量序，本章四轮序列就能被完整复制进教材与
  回归；一旦遍历顺序或打印顺序依赖容器随机状态，问题将无
  法复现。确定性不仅是输出美观问题，也是可调试性的前提。

## 35.14 练习题与解题思路

本章练习分三档：练习一至五覆盖主体（阈值、加宽点、等号
假边、Δ 终止、检验反例），建议全部动手；练习六至八为进
阶（相关变量、常量买断、失败归因）；练习九至十一面向实
战与定理细节。所有题目都给出解题思路而非完整答案，目的
是让读者先自行推演、再用思路核对方向——静态分析的学习，
亲手算过与看懂别人算，差距比想象中大得多。

解题时建议保持一个习惯：每一步都标注"信息来自哪里"——
来自条件边（半直线事实）、来自上一轮的回流（循环历史）、
还是来自赋值右端（evalIv）。本章所有精度争议，归根到底
都是这三类信息在某个节点上的组合方式；标注清楚来源后，
遇到结果与预期不符，就能迅速定位是哪类信息被漏掉或错
用，而不必从头重算。这个习惯在更复杂的过程间、路径敏感
分析里同样受用。

**练习一（阈值替换）**。把阈值表改为 T={−∞,0,1,10,+∞}
（仅加一个常量 10），重新推演 21.5 的四轮序列。哪些行不
再相同？narrowing 还能收紧什么？

*思路*：第 2 轮 ∇ 时新上界 2 仍跨 +∞（阈值 10 不小于 2
吗？——Δ 取"不小于新上界的最小阈值"，2 的候选里 10 比
+∞ 小），循环头直接停在 `[0,10]`；节点 4 流出 `[1,10]`；
Δ 无界可收。结论：把目标上界纳入阈值，∇ 一步到位，Δ 的
工作被提前完成。

**练习二（加宽点移位）**。假设把加宽点改在循环体末尾（节
点 4）而不是头上，迭代序列与最终精度有什么变化？

*思路*：节点 4 的 ∇ 作用在回流到 3 的环境上；头部的 join
仍可能逐轮增长（`[0,1]、[0,2]…`），但每轮被节点 4 的 ∇
截断，整体仍有限步终止；精度集中损失点离条件更远，一趟
Δ 闭合所需的信息流向改变，可能需要多趟。体会"加宽点越靠
近环的语义中心（条件），越易收窄"。

**练习三（假边的等号）**。为 `(x == k)` 的**假**边设计一
种比"不动"更精确的处理。在区间格内能做到多少？需要什么
扩展？

*思路*：x≠k 对区间 [l,h] 的精确结果是 [l,k−1]∪[k+1,h]
（两个区间），区间格表示不了；可扩展为"有限区间之并"的
提升域（终止性需另配阈值）；保守近似可取：当 k=l 时提下
界为 k+1，当 k=h 时压上界为 k−1，内部点不动。

**练习四（Δ 终止性）**。若把 narrow 规则放宽为"任何有限
界都允许按新值收紧"，构造一个让收窄不终止的例子。

*思路*：取第 34 章原程序，Δ 反复把头部上界收紧
（…3、2），同时环的回传又不断改变新值，形成双向无限
链；本质是重新引入了朴素迭代。据此说明"只收 ±∞ 端"是终
止性的刻意设计而非偷懒。

**练习五（成员检验的反例）**。人为把 widen 中的上界阈值
+∞ 误写成 1（即所有跨变都停在 1），预测 soundness 检验会
在哪一步、以什么形式失败。

*思路*：头部输出预测变成 `[10,1]` 之外的形态——节点 5 的
假边精炼提下界 10 后与上界冲突得 ⊥，或输出区间不含 10；
JIT 执行值 10 落在区间外，打印 UNSOUND。体会成员检验正是
为抓住这类实现偏差而存在。

**练习六（多变量循环）**。把程序改为循环体内同时更新两个
变量：`x = x+1; y = y+2;`，初始 y=0。推演 ∇ 的逐变量
行为：两个变量分别在哪一轮跨到 +∞？Δ 一趟后各自闭合到
什么？

*思路*：∇ 逐变量独立跨变，互不等待；x 第 2 轮跨 +∞，y 的
序列是 2、4，第 2 轮同样跨 +∞（阈值表无 2/4）。Δ 时边精
炼只精炼 x（条件只约束 x）；y 的上界仍 +∞，除非引入
"变量关系域"（例如差约束 y−2x 恒定）。体会非关系域对
"相关变量"的盲区：单独看每个区间都可靠，合起来却丢失了
y=2x 的关系。

**练习七（终止轮数与程序常量数）**。若把阈值表换成"程序
中出现的全部整数常量 + 0"，论证：对任何**无 input、无乘
法放大**的循环，∇ 常常在第二或第三轮就给出精确答案。什
么形状的循环会让这个结论失败？

*思路*：循环上界若直接来自程序常量 N，∇ 一步停 N。失败
形状：上界由变量相加后再放大（`x = x + step`，step 来自
input）、乘法使端点非线性增长（阈值刻度与增长值错配）、
或条件形如 x≠y（上界根本不由条件直接给出）。据此理解为
什么工业工具仍同时实现 ∇ 与 Δ：常量阈值能买断大量常见循
环，但买断不了全部。

**练习八（可靠性与检验失败的区分）**。假设某次运行 JIT 检
验报告 UNSOUND，而手工形式化论证确认规则是可靠的。举出
两类"实现层"成因，并说明为什么这类失败不能归因于理论。

*思路*：其一，LocalWiring 与 cfg.cpp 编号规则失配（边反
了/节点号错位），精炼施加到错误路径；其二，饱和算术或符
号判定写错（如比较方向反），区间被错误收窄。理论保证的
是"正确实现的规则"，检验抓的正是"实现是否正确"——两者
各司其职，UNSOUND 在此反而是检验有效的证据，而非理论被
证伪。

**练习九（空循环与 ⊤ 传播）**。考虑 `while (x > 0) { }`
（空体）配合 x=5。推演 CFG 形状与区间序列，解释为什么
这种程序在静态分析视角下等价于一个危险信号。

*思路*：cfg.cpp 对空体让条件点连自边；区间上 x 在头部每
轮不变（[0,+∞) 经 ∇），迭代稳定但语义上是死循环——没有
任何边能让 x 减小。静态分析无法直接判"死循环"（那等价于
停机问题），但可以标注"循环内没有修改 x 的赋值"这类启发
事实。体会：分析能精确报告的是结构事实，运行时结局只能
近似。

**练习十（域的选择）**。某程序的核心是 `for (i=0; i<n; i++)
a[i] = ...`，分析目标是证明下标不越界。说明区间域在哪
一步必然放宽、差约束域为什么恰好够用。

*思路*：进入循环体时需同时持有 i≥0 与 i<n。条件边精炼能
分别给出 i 的区间 [0,+∞) 上界受 n 限制（n 若来自 input
则为 +∞），非关系域无法把 i 与 n 的差锁住；校验 a[i] 时只
能用 n 的区间，误报。差约束 n−i≥1 直接编码"i 严格小于 n"，
无论 n 自身多宽，约束保证下标关系。体会"选域要看要证明
的性质本身是什么形状"。

**练习十一（∇ 结果的后固定点方向）**。用 widen.tip 的头部
说明"∇ 解被方程接受"具体指哪个不等式，并验证第 3 轮后
头部满足它。

*思路*：头部状态 X=[0,+∞)，方程 F 在头部取"前驱 join
（含经 ∇ 定义）再经条件边"；F(X) 的上界至多 +∞、下界 0，
故 F(X)⊑X（方程推不出比 X 更高的信息）。第 2 轮时头部
[0,1]，F([0,1]) 经回边得到含 2 的环境、F(X)⋠X，所以那
不是后固定点、迭代继续。亲手验证方向比背诵定理更能暴露
"⊑ 方向写反"的常见错误。

## 35.15 本章小结

第 34 章让我们看到：完全格与单调函数只保证不动点存在，
不保证朴素迭代在有限步达到它；无限高的区间格上，"模拟循
环展开"的序列没有尽头。本章用 Cousot 的两步方案翻过了这
堵墙：

- **widening ∇** 不改变方程组，只在循环头把 join 换成与有
  限阈值表相关的跨变——上界性质保证它跨得可靠，阈值有限
  保证它必然终止；四轮迭代从第 34 章的 50 轮不收变成稳定，
  代价是头部 `[0,+∞]` 的偏松。
- **narrowing Δ** 从 ∇ 解出发用原方程再推一遍，只把 ±∞ 端
  收回有限值——一趟就把头部闭合到 `[0,10]`、输出钉死为
  10，且不破坏可靠性。
- **分支边精炼**在条件两侧把区间与半直线取交；它在 widening
  期间就使循环体出口保持有限上界，是 Δ 一趟成功的隐含前
  提；LocalWiring 在不动 CFG 接口的前提下重推出真假边。
- **JIT 成员检验**把三次真实执行的输出与收窄区间对照，
  全部通过：∇/Δ 改变的是精度（区间宽度），不是可靠性（区
  间是否含真值）。

复习本章时，建议按以下四步自测，任何一步卡住就回到对应
小节。

第一步，不看代码复述 ∇ 的两条性质与"为什么阈值有限就能
终止"，并亲手在纸上验证 `[1,1]∇[1,2]=[1,+∞)`（21.3）。
第二步，照 widen.tip 的节点图（1–7）从头重演四轮迭代，
特别确认第 2 轮阈值 1 如何保住精度、第 3 轮为何跨过 2
（21.5）。第三步，解释 Δ 一趟成功的隐含前提——循环体出口
为何已是有限上界（边精炼的贡献），并指出 Δ 输出为何仍可
靠但不保证是不动点（21.6）。第四步，说出成员检验判定的
是哪种关系、它在论证体系中的位置与局限（21.10、21.11）。

若四步都能顺畅完成，再尝试练习一与练习六——它们分别考
查阈值表的作用与非关系域对相关变量的盲区，是本章最容易
"看懂了却做不对"的两处。

还可以用一种反向方式自测：刻意在脑中把每条规则"弄坏"一
次（阈值去掉 1、真假边互换、Δ 改成 meet、⊥ 的初值改成
⊤），预测输出会怎样变化、JIT 检验是否抓得住。能说清每种
破坏的后果，就说明对规则之间的咬合关系有了真正的掌握，
而不只是记住了结论；这也是从"读懂分析"走向"能设计分
析"的一道分水岭。做这种破坏实验时，把每轮头部区间写在
一列，变化方向与"为什么此时跨/不跨"标注在旁，会比单纯心
算更快地暴露理解缺口。

下一章把这套设施带到更复杂的控制流上：同一程序在"流不
敏感"与"路径精炼"两档求解器下对照，区间还要承担一个更
有现实意义的职责——根据除数区间报告除零风险。

最后留下一句贯穿全书的方法论提醒。第 34 章让我们第一次撞
到"定理保证存在、算法却到不了"的鸿沟；本章没有填平这道
鸿沟（LFP 的精确计算在无限高格上本来就不现实），而是在
鸿沟上架了两座可以严格论证的桥：一座保证"过得去且不会掉
下去"（∇：终止且可靠），一座保证"过去之后还能往回走几
步"（Δ：改善而不失足）。学会在遇到任何"迭代不终止"的问
题时，先问"我的性质格有多高、割点在哪、阈值怎么选"，而
不是把迭代上限调大一了百了——这就是本章希望沉淀下来的
思维方式。工具会更替，这套"存在性与可计算性分开处理、近
似必须可论证"的纪律不会过时。

收尾时再盘点一次本章各节的阅读权重，方便时间有限的读者
取舍：21.2 与 21.3 是概念核心（为什么会不终止、∇ 凭什么
终止且可靠），不可跳过；21.5 的四轮手工推演是把抽象定义
变成肌肉记忆的关键，建议拿纸对照演算一遍再看结论；21.6
与 21.7 是工程精度的两个独立来源（信息回流、条件事实），
理解它们的分工比记住代码更重要；21.10 与 21.11 分别从经
验与形式两侧闭合可靠性，时间紧时可先掌握成员检验的直觉
（区间含真值），形式四层留作复习。21.12 的基础设施说明可
作为参考资料按需查阅，不必顺序通读。

