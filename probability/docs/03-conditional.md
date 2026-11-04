# 03 条件概率、全概率与贝叶斯

条件概率研究一个核心问题：获得新信息后，概率如何更新。经济数据中
信息几乎总是逐步到来的：今天知道失业率、明天知道央行公告，今天知道
检验结果、下周知道复查结果，玩家先选门、主持人再开门。新信息不会
凭直觉“随意改变概率”，它按一条精确规则把旧概率空间切割、归一化，
再重新计算。

## 03.1 条件概率的定义

设 $(\Omega,\mathcal F,P)$ 是概率空间，$A,B\in\mathcal F$ ，且
$P(B)>0$ 。给定 $B$ 已发生时，$A$ 的条件概率定义为

$$P(A\mid B)=\frac{P(A\cap B)}{P(B)}.$$

这个定义有三个关键点。

第一，$B$ 把样本空间从 $\Omega$ 缩小到 $B$ 。原来 $B$ 外面的
结果已知不可能发生，计算 $A$ 时只保留 $A\cap B$ 。

第二，分母 $P(B)$ 重新归一化。无条件概率中全空间质量为 1；条件化
后，新的全空间是 $B$ ，所以所有落在 $B$ 中的概率都要除以 $P(B)$ 。

第三，本章要求 $P(B)>0$ 。若 $P(B)=0$ ，不能用这个初等公式除以零。
连续随机变量中“给定单点值”的条件分布需要正则条件分布或条件密度处理；
本教程在条件分布和条件期望章节再讨论。

若有一个含 25 个等可能点的有限空间，事件 $A$ 含 15 点，$B$ 含
7 点，$A\cap B$ 含 5 点，则

$$P(A)=\frac{15}{25},\quad P(B)=\frac7{25},\quad P(A\cap B)=\frac5{25},$$

因而

$$P(A\mid B)=\frac{5/25}{7/25}=\frac57,\qquad P(B\mid A)=\frac{5/25}{15/25}=\frac13.$$

这说明 $P(A\mid B)$ 与 $P(B\mid A)$ 一般不相等。医学诊断中
“患者呈阳性时患病的概率”和“患者患病时呈阳性的概率”方向相反；
混淆二者是常见错误。

## 03.2 条件概率是一个新概率测度

对固定的 $B$ ，定义 $Q(A)=P(A\mid B)$ 。它满足概率公理：

- 非负性来自 $P(A\cap B)\ge0$ ；
- 规范性来自
  $Q(\Omega)=P(\Omega\cap B)/P(B)=P(B)/P(B)=1$ ；
- 若 $A_1,A_2,\ldots$ 两两不交，则
  $(A_i\cap B)$ 也两两不交，故

$$Q\left(\bigcup_i A_i\right) =\frac{P((\bigcup_i A_i)\cap B)}{P(B)} =\sum_i\frac{P(A_i\cap B)}{P(B)} =\sum_i Q(A_i).$$

因此无条件概率成立的补律、加法公式、Boole 不等式等，在条件概率中也
成立。例如

$$P(A^c\mid B)=1-P(A\mid B).$$

证明为

$$P(B)=P((A\cup A^c)\cap B) =P(A\cap B)+P(A^c\cap B),$$

两边除以 $P(B)$ 即得。

条件化不是改变历史事实，而是换信息集。未观测到 $B$ 时使用全空间
$\Omega$ ；观测到 $B$ 后，所有概率都在新的信息集 $B$ 中重算。

## 03.3 乘法法则与链式法则

由定义移项得到乘法法则：

$$P(A\cap B)=P(A\mid B)P(B)\qquad(P(B)>0),$$

或等价地

$$P(A\cap B)=P(B\mid A)P(A)\qquad(P(A)>0).$$

它把联合概率拆成“某事件概率”乘“已知该事件后另一事件概率”。

从 52 张牌中无放回抽取两张，两张都是 A 的概率为

$$P(A_1\cap A_2)=P(A_1)P(A_2\mid A_1) =\frac4{52}\cdot\frac3{51} =\frac1{221}.$$

第一张是 A 后，牌堆只剩 51 张，其中只有 3 张 A。条件结构精确反映了
无放回抽样导致的概率变化。

一般地，若所需条件概率都有定义，则有链式法则：

$$P(A_1\cap A_2\cap\cdots\cap A_n) = P(A_1)P(A_2\mid A_1)P(A_3\mid A_1\cap A_2)\cdots P(A_n\mid A_1\cap\cdots\cap A_{n-1}).$$

它按信息到达顺序展开联合概率。时间序列分析中，$P(A_t\mid A_1,\ldots,A_{t-1})$ 可解释为在历史信息集下预测下一期事件；似然函数也常通过
链式法则写成一串条件概率或条件密度的乘积。

## 03.4 全概率公式

若事件 $B_1,\ldots,B_n$ 两两不交且

$$\bigcup_{i=1}^n B_i=\Omega,$$

则它们构成 $\Omega$ 的一个分割。若再要求 $P(B_i)>0$ ，对任意事件
$A$ 有有限全概率公式：

$$P(A)=\sum_{i=1}^n P(A\mid B_i)P(B_i).$$

可数分割版本为

$$P(A)=\sum_{i=1}^{\infty}P(A\mid B_i)P(B_i).$$

证明分两步。先由分割得到

$$A=A\cap\Omega =A\cap\left(\bigcup_i B_i\right) =\bigcup_i(A\cap B_i).$$

这些 $A\cap B_i$ 两两不交，所以由可加性

$$P(A)=\sum_iP(A\cap B_i).$$

再用乘法法则 $P(A\cap B_i)=P(A\mid B_i)P(B_i)$ 。

全概率公式的读法是“分情况求全”：先在每种状态 $B_i$ 下计算 $A$ 的
概率，再按状态自身概率加权。它也常称为排除法。

例如把借款人分成高、中、低风险三类，违约率在各类内部不同。总体违约率
不是三类违约率的简单平均，而要用三类人群占比加权。忽略权重正是基率
错误的来源。

## 03.5 Bayes 公式

在同样的分割下，Bayes 公式为

$$P(B_j\mid A) = \frac{P(A\mid B_j)P(B_j)} {\sum_iP(A\mid B_i)P(B_i)}.$$

分母就是全概率公式给出的 $P(A)$ 。证明只有两行：

$$P(B_j\mid A)=\frac{P(B_j\cap A)}{P(A)}, \qquad P(B_j\cap A)=P(A\mid B_j)P(B_j).$$

Bayes 公式中的四项各有名称：

- $P(B_j)$ ：先验概率，即观测证据 $A$ 前的信念；
- $P(A\mid B_j)$ ：似然，即若状态为 $B_j$ ，证据出现的概率；
- $P(A)$ ：证据的总概率；
- $P(B_j\mid A)$ ：后验概率，即观测证据后的更新信念。

Bayes 更新不是“凭结果倒推因果”。条件概率表示预测和证据关系，不自动
表示因果。要把后验解释成因果效应，还需要理论模型、实验设计或识别
假设。

## 03.6 医学检验：为什么 95% 准确不等于 95% 患病

设某种病在人群中的患病率为

$$P(H)=\frac1{1000},$$

检验灵敏度为 $P(+\mid H)=0.95$ ，假阳性率为 $P(+\mid H^c)=0.05$ 。
若某人检验呈阳性，真正患病的概率是多少？

真正阳性和假阳性的联合概率分别为

$$P(H\cap +)=0.95\cdot\frac1{1000}=\frac{95}{100000},$$

$$P(H^c\cap +)=0.05\cdot\frac{999}{1000} =\frac{4995}{100000}.$$

因此

$$P(H\mid +) =\frac{95}{95+4995} =\frac{19}{1018} \approx0.0187.$$

即使检验“95% 灵敏”，阳性后真病概率仍只有约 1.87%，因为健康人基数
远大于患者基数，5% 的假阳性落在大量健康人上会产生许多假阳性。这个
例子不是说检验无用，而是说必须结合基率解释检验结果。复查通常使用
另一种独立或高度相关但不完全相同的检验，后验会再次更新。

`examples/python/03_conditional.py` 用 `Fraction` 做精确计算，核心
代码如下：

```python
prev = Fraction(1, 1000)
tp = Fraction(95, 100)
fp = Fraction(5, 100)
true_pos = tp * prev
false_pos = fp * (1 - prev)
evidence = true_pos + false_pos
post = true_pos / evidence
assert post == Fraction(19, 1018)
```

这里没有浮点舍入。`19/1018` 是有理数精确答案，程序另外计算有限表
$P(A\mid B)=5/7$ 与无放回两张 A 的 $1/221$ 。

## 03.7 Monty Hall：主持人的规则就是信息

三扇门后有一车两羊。你最初选 1 号门。主持人知道车在哪里，并在你
选择后打开另一扇有羊的门。假设你看到主持人打开 3 号门，是否应改选
2 号门？

令 $C_i$ 表示车在第 $i$ 扇门后，先验为

$$P(C_1)=P(C_2)=P(C_3)=\frac13.$$

令 $H$ 表示主持人按规则打开 3 号门。

- 若车在 1 号门，主持人可在 2、3 号门中任选，故
  $P(H\mid C_1)=1/2$ ；
- 若车在 2 号门，主持人不能开 2 号门，也不能开车门，只能开 3 号，
  故 $P(H\mid C_2)=1$ ；
- 若车在 3 号门，主持人不能开 3 号，故 $P(H\mid C_3)=0$ 。

于是

$$P(H)=\frac12\cdot\frac13+1\cdot\frac13+0\cdot\frac13=\frac12,$$

$$P(C_2\mid H) =\frac{1\cdot1/3}{1/2} =\frac23.$$

换门赢车概率是 $2/3$ ，不换只有 $1/3$ 。错误答案“两门各 1/2”
忽略了主持人不是随机开门：他必须避开车门和玩家选择的门。这个规则
使开门动作携带信息。

若主持人也不知道车在哪里，只是随机开了另一扇门，并且碰巧开到羊，
条件结构就变了。此时要把“主持人碰巧没开到车”纳入证据。在该条件下
换门赢率为 $1/2$ 。同一个表面情节，只要数据生成规则不同，答案就
可能不同。

`examples/julia/03_conditional.jl` 同时模拟知情主持人和不知情主持人：

```julia
function monty_knows(switch; trials = 100_000)
    win = 0
    for _ in 1:trials
        car = rand(1:3)
        pick = rand(1:3)
        options = filter(d -> d != car && d != pick, 1:3)
        opened = rand(options)
        if switch
            pick = filter(d -> d != pick && d != opened, 1:3)[1]
        end
        pick == car && (win += 1)
    end
    win / trials
end
```

知情主持人的合法门从“既不是车门也不是玩家门”的集合中选择；模拟
频率在 $1/3$ 与 $2/3$ 附近。不知情版本中若主持人开到车就丢弃
本轮，只在“开到羊”的条件下统计，换门频率接近 $1/2$ 。固定随机
种子后，模拟频率可复现，但它是渐近直觉，不是精确证明；精确答案由
Bayes 公式给出。

Prolog 通道直接枚举合法的“车门—主持开门”组合：

```prolog
host_opens(Car, Opened) :-
    between(2, 3, Opened),
    Opened =\= Car.

check_monty :-
    p_host_cond(2, 3, PC_H), P_C is 1 rdiv 3,
    Num is PC_H * P_C,
    D13 is 1 rdiv 2 * 1 rdiv 3,
    D23 is 1 * 1 rdiv 3,
    Den is D13 + D23,
    Post is Num / Den,
    Post =:= 2 rdiv 3.
```

`host_opens` 把主持人的规则写成逻辑约束。枚举得到四条合法路径；
三囚徒问题使用相同结构：狱卒不能暴露被赦免者，也不能直接提问者本人，
因此“另一个人被处决”的名字同样携带信息。

## 03.8 Bayes 公式的经济解释

经济预测常从一个先验模型出发，再被新数据更新。评级模型可先根据收入、
负债和历史信用给出违约概率；观测到逾期后再更新。营销模型可先估计
消费者属于某类偏好的比例，再根据购买记录更新。宏观预测可先给出不同
增长状态的概率，再根据就业、订单和通胀数据更新。

使用 Bayes 公式时要检查三件事：

1. 分割是否真正穷尽且互斥；
2. 似然 $P(A\mid B_i)$ 是否在同一数据生成规则下定义；
3. 先验来自频率估计、主观信念还是可识别的模型假设。

Bayes 方法的争议通常不在公式本身——公式只是条件概率定义和全概率的
推论——而在先验从哪里来、模型集合是否完备、似然是否稳定。明确这些
来源，比把“贝叶斯方法”神秘化更重要。

## 03.9 证明器中的条件概率

Lean 文件 `examples/lean/Probability/Ch03Conditional.lean` 登记
mathlib 中条件测度的核心引理：

- `ProbabilityTheory.cond_apply`：条件概率的商形式；
- `cond_mul_eq_inter`：乘法法则；
- `cond_eq_inv_mul_cond_mul`：Bayes 型反向关系。

同一文件用 `norm_num` 精确检查医学检验的 $19/1018$ 与 Monty Hall
的 $2/3$ 。Isabelle 会话 `MT03` 中的
`examples/isabelle/MT03/T03_Conditional.thy` 登记 HOL-Probability 的
`cond_prob_def` 与相关条件概率定理。两个证明器提供形式锚点，有理数
和枚举通道提供数值直觉。

## 03.10 本章要点

1. $P(A\mid B)=P(A\cap B)/P(B)$ 表示在新样本空间 $B$ 中重新归一。
2. 固定 $B$ 后，$P(\cdot\mid B)$ 本身是概率测度，因此补律和可加性
   继续成立。
3. 乘法链按信息到达顺序展开联合概率。
4. 全概率公式把任意事件按互斥穷尽状态加权平均。
5. Bayes 公式用“先验 × 似然 / 证据”得到后验；它处理证据更新，不
   自动证明因果。
6. Monty Hall 的关键不是玩家心理，而是主持人的选择规则。
7. 医学检验案例表明基率可以压倒表面准确率；$P(+\mid H)$ 不等于
   $P(H\mid +)$ 。

*对应示例：`examples/lean/Probability/Ch03Conditional.lean`、
`examples/isabelle/MT03/T03_Conditional.thy`、
`examples/julia/03_conditional.jl`、
`examples/python/03_conditional.py`、
`examples/prolog/03_conditional.pl`。*

---

上一章：[02 概率公理、解释与基本定律](02-axioms.md) · 下一章：[04 独立性、条件独立与信息](04-independence.md)
