# 第 56 章 Boole 代数与逻辑电路

> 对书：Jongsma ch7（§7.3–7.6）。本章通道：C（`examples/50_boole/ex56_boole.v`）/
> L（`examples/50_boole/ex56_boole.lean`）/ P（`examples/50_boole/ex56_boole.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `b_*` 十公理 | B={0,1} 是 Boole 代数（书 §7.3.3 例 7.3.3） | C/L |
| 推论律全家 | 幂等/湮灭/吸收/De Morgan/联动（iff）/冗余/共识/消去（书 Prop 7.3.1–7.3.9） | C/L |
| `nand`/`nor`/`xnor` 门 | 门动物园的 De Morgan 形与可接受串（书 Table 7.1） | C/L |
| `ha`/`fa`/`add2` + 正确性 | 半加器/全加器/两位行波进位（书例 7.4.9/7.4.10） | C/L |
| `lit`/`minterm_accept`/`dnf2` | minterm 表示定理：任意 f 等于其接受行的展开（书 Thm 7.5.1） | C/L |
| `qmc_primes`/`min_covers` | Quine-McCluskey 两阶段（书 §7.6.5 例 7.6.8/7.6.9） | P |

第 55 章把偏序走到 Boole 格（有补分配格）就停了；这一章把「格」字
拆掉，只留运算：**Boole 代数**是一套满足十条公理的抽象运算结构
（+, ·, 补, 0, 1），Boole 格是它的一个模型，命题逻辑是另一个，开关
电路是第三个。本章前半（§7.3）把公理系立起来并推演出全部常用律；
中段（§7.4–7.5）从代数走到函数与电路——门、加法器、minterm 展开
定理；尾段（§7.6）解决工程问题：如何把布尔函数化到最简。三个通道
分工明确：Coq/Lean 管定理（公理模型、加法器正确性、表示定理），
Prolog 管算法（Quine-McCluskey 的合并与覆盖两阶段）。

## 一、从 Boole 格到 Boole 代数

书 §7.3.1 先回答「Boole 格长什么样」：**Stone 表示定理**（Thm 7.3.1）
说有限 Boole 格的每个非零元素都是它下方原子（atom，紧贴 0 的极小元，
Defn 7.3.1）的 join，且原子组合唯一——所以有限 Boole 格与某个
P(S), ⊆ 同构，基数必为 2ⁿ。55 章的五点菱形不是 Boole 格（中间三点
互为补，补不唯一），而 2 点、4 点、8 点格都是——1, 2, 4, 8 这个
序列就是 2ⁿ。反向（§7.3.2/7.3.5）：把 Boole 格的 meet/join/补当作
运算（由唯一性合法），就得到运算结构；反过来由运算定义序
x ≤ y ⟺ x·y = x 也能复原格（Thm 7.3.2）——格与代数互相生成，
一个闭环。

**Boole 代数的公理系**（书 §7.3.3）：两条交换律、两条结合律、两条
分配律、两条单位元律、两条补律——共十条，作用于任意集 A 上的
两个二元运算 + 与 ·、一个一元运算补、两个常数 0 与 1。它对模型
一视同仁：幂集格（∪, ∩, 补集, ∅, U）是模型，命题逻辑（∨, ∧, ¬,
假, 真）是模型，B = {0,1}（max, min, 1−x, 0, 1，书例 7.3.3）是
最小非平凡模型。本章机器化选 B——在 Coq/Lean 里就是 `bool`：
orb=+、andb=·、negb=补。十条公理逐条验证，每条都是穷举两三个
布尔值：

```lean
theorem b_dist_or : ∀ x y z : Bool,
    (x || (y && z)) = ((x || y) && (x || z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl
```

这一条是**第二分配律**——+ 对 · 分配。普通算术没有它（书中反例：
1 + 2·3 = 7 ≠ 12 = (1+2)(1+3)），它是 Boole 代数的身份标志之一。
十公理的验证无任何技巧，但「模型检查 = 定理证明」的等价性在这类
有限结构上是真实的：穷举 2³ = 8 格真值表，就是最严格的证明。

## 二、公理的推论：从十条到一整册

书 Prop 7.3.1–7.3.9 按依赖顺序给出常用律（「只能用公理和已证
命题」——抽象证明的训练场）。机器面上它们在 B 里全部退化为穷举，
其中大部分一行结束：

```coq
Lemma b_demorgan_and : forall x y, negb (andb x y) = orb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.
```

三条值得停下来细看。

**运算联动律**（Prop 7.3.6）不是等式族而是**普遍双条件**：
xy = x ⟺ x + y = y ⟺ xy = 0 ⟺ x + y = 1——四个条件两两等价。
机器版取其中一支做 iff：

```lean
theorem b_linkage : ∀ x y : Bool, (x && y) = x ↔ (x || y) = y := by
  intro x y
  match x, y with
  | true, true => exact ⟨fun h => h, fun h => h⟩
  | true, false => exact ⟨fun h => Bool.noConfusion h,
                           fun h => Bool.noConfusion h⟩
  | false, _ => exact ⟨fun _ => rfl, fun _ => rfl⟩
```

注意它就是 55 章 Thm 7.3.2 的桥梁：x ≤ y 定义为 x·y = x，
等价地 x + y = y——序被翻译成运算语言，靠的正是这条律。

**消去律**（Prop 7.3.9）：xy = xz 且 x + y = x + z 蕴含 y = z，
两个前提缺一不可（书的 Exercise 26b 让读者构造单前提反例）。
机器证明把「两个前提各管一半」说得明明白白：

```lean
theorem b_cancel : ∀ x y z : Bool,
    (x && y) = (x && z) → (x || y) = (x || z) → y = z := by
  intro x y z h1 h2
  cases x with
  | false => exact h2
  | true => exact h1
```

x = 0 时乘法等式是废话（0·y = 0·z 恒真），真正起作用的是加法等式
（0 + y = 0 + z 就是 y = z）；x = 1 时对调。`exact` 能直接把假设
交给目标，因为 `false || y` 与 `true && y` 对 y 是**定义性相等**。

**共识律**（Prop 7.3.8a）给本章贡献了最重要的一条工程教训。书上
的定理是 xy + x̄z + yz = xy + x̄z——第三项 yz 是前两项的「共识项」，
可删。但 PDF 的文本层**丢掉了上杠**，提取出来是「xy + xz + yz =
xy + xz」——一个假命题（x=0, y=z=1 时左边 1 右边 0）。机器当场
抓包：

```coq
Lemma b_consensus : forall x y z,
    orb (orb (andb x y) (andb (negb x) z)) (andb y z)
    = orb (andb x y) (andb (negb x) z).
Proof. intros; destruct x, y, z; reflexivity. Qed.
```

初版不带 `negb x` 的写法在第一个反例上就拒绝编译。§7.3 的命题
排印全用上杠记补，提取文本全部裸奔；冗余律（Prop 7.3.7：
x(x̅+y) = xy）同病。**取材自 PDF 文本层时，涉及补运算的公式必须
按数学实体校读，机器验证是唯一的裁判**——这也是本章把全部定律
做成机器件的额外理由：一册 Boole 恒等式表，抄错任何一条都过不了
destruct。

顺带一提**对偶原理**（书 Exercise 7.3.28）：每条 Boole 恒等式把
+ 与 · 互换、0 与 1 互换后仍是恒等式。看上面的清单：交换/结合/
分配/De Morgan 全部成对出现，正是对偶的化身——公理本身对偶，
所以从公理出发的证明逐行取对偶仍是合法证明。

## 三、Boole 的逻辑观

书 §7.3.4 是历史性的：Boole 1847 年起用代数做逻辑——类代数里
「所有 X 都是 Y」写成方程 X = XY，Barbara 三段论（例 7.3.4）
就成了一行代数演算 X = XY = X(YZ) = (XY)Z = XZ。例 7.3.5 用
代数从排中律推矛盾律：X + X̄ = 1 两边乘 X̄，得 X̄X + X̄X̄ = X̄，
即 0 + X̄ = X̄——补律消化了双反。命题逻辑作为 Boole 代数的模型
（例 7.3.6）：把句子变量映到代数变量、∨/∧/¬ 映到 +/·/补、
逻辑真/假映到 1/0，全部公理为真。第 2 章里我们用真值表做过同样
的翻译；现在它有了代数身份：**PL 的等值替换规则 = Boole 代数的
恒等式**。54 章 congN 的「换代表元不改变结果」在这里变成「换
等值式不改变函数」——minterm 表示定理（第六节）把它做成机器件。

## 四、门动物园：从 Shannon 到电路

§7.4 的故事从 Shannon 1938 年的硕士论文讲起：开关的串联是 ·、
并联是 +、常闭开关是补——Boole 代数第一次接了地气。现代版本是
逻辑门（Table 7.1）：AND/OR/NOT 是基本门，XOR/NAND/NOR/XNOR
是复合门，每个门由「可接受串」（输出 1 的输入行）与布尔表达式
双重定义。机器面取三件代表：

```coq
Definition nand (x y : bool) : bool := negb (andb x y).
Definition nor (x y : bool) : bool := negb (orb x y).
Definition xnor (x y : bool) : bool := negb (xorb x y).

Lemma nand_form : forall x y, nand x y = orb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma xnor_accept : forall x y, xnor x y = true <-> x = y.
Proof.
  intros x y; destruct x, y; simpl; split; intro H;
    (reflexivity || discriminate H).
Qed.
```

NAND 的 De Morgan 形（x·y 的补 = x̄ + ȳ）说明它是 NOT+OR 的
合并封装；XNOR 可接受 00 与 11——它就是等值连接词的门化身
（书 Exercise 7.4.6 问的「别名」）。门可以互相模拟：AND 用
NOT+OR 造（De Morgan 取对偶），NOT 用 NAND 造（两个输入并联），
而 NAND 单门通用（Exercise 7.4.40）——这也是它在集成电路里
地位特殊的原因。

## 五、加法器：布尔电路做算术

§7.4.7 是全章的高光时刻：逻辑返回 Boole 用算术做逻辑的礼，
用**逻辑做算术**。二进制加法逐位进行，每个数位需要一个组合电路。
半加器（书例 7.4.9）加两个位：和位是 XOR、进位是 AND——
1+1=10 的两个输出正好用两个门。全加器（例 7.4.10）加三个位
（多一个来自低位的进位），由两个半加器拼装。正确性陈述把布尔侧
接回 nat：给每个位赋值 `bval`，声明电路输出位按二进制解读后
等于输入位之和：

```lean
def ha (x y : Bool) : Bool × Bool := (xor x y, x && y)

theorem ha_correct : ∀ x y : Bool,
    bval (ha x y).1 + 2 * bval (ha x y).2 = bval x + bval y := by
  intro x y; cases x <;> cases y <;> rfl

def fa (w x y : Bool) : Bool × Bool :=
  ((ha w (ha x y).1).1, (ha x y).2 || (ha w (ha x y).1).2)

theorem fa_correct : ∀ w x y : Bool,
    bval (fa w x y).1 + 2 * bval (fa w x y).2
    = bval w + bval x + bval y := by
  intro w x y; cases w <;> cases x <;> cases y <;> rfl
```

`fa` 的定义体就是书例 7.4.10 的电路图直译：第一级半加器吃 x、y，
第二级半加器吃 w 与第一级的和位；总进位是两个进位的 OR。证明是
2² 与 2³ 格真值表的逐格检查——`rfl` 让机器把每一格算到 nat 等式
为止。再上一级：两位行波进位加法器 `add2`（低位半加器出进位、
高位全加器吃进位），正确性是 2⁴ = 16 格的检查：

```coq
Lemma add2_correct : forall a1 a0 b1 b0,
    bval (snd (add2 a1 a0 b1 b0))
    + 2 * bval (snd (fst (add2 a1 a0 b1 b0)))
    + 4 * bval (fst (fst (add2 a1 a0 b1 b0)))
    = (2 * bval a1 + bval a0) + (2 * bval b1 + bval b0).
Proof. intros; destruct a1, a0, b1, b0; reflexivity. Qed.
```

`10 + 01 = 11` 的冒烟（`Compute (add2 true false false true)` 输出
`(false, true, true)`）验证了整条链路。注意 Coq 的三元组
(a,b,c) 是嵌套对 ((a,b),c)，`fst/snd` 要逐层取——本教程初版
在这里写反过一次。位宽再往上是同一模式的重复（书 Exercise
7.4.44 让读者铺三位），机器面点到两位为止：行波进位的「低位
进位逐级传播」结构已经完整呈现，而 49 章的归纳工具随时可以把
它推广到任意位宽——那是另一个教程的事了。

## 六、minterm 表示定理：每个布尔函数都有标准形

§7.5 的中心结果（Thm 7.5.1/7.5.2）：**每个非零布尔函数（从而每个
布尔表达式）都唯一地等于其接受行 minterm 之和**。minterm 是每个
变量恰出现一次（正或反文字）的积（Defn 7.5.2），单个 minterm 恰
接受一个输入串（Prop 7.5.2 的核心）。机器版把「文字」定义成
数据：

```coq
Definition lit (s x : bool) : bool := if s then x else negb x.
```

s 是「规格位」：s=1 取正文字、s=0 取反文字。单个 minterm 的接受性
（`minterm_accept`）：`(lit s1 x1 && lit s2 x2) = true ↔ x1 = s1 ∧ x2 = s2`——
16 格穷举，每格非 reflexivity 即 discriminate。重头戏是 n=2 的
**一般定理**——对任意 f（包括所有还没写出来的布尔函数）：

```lean
theorem dnf2 (f : Bool → Bool → Bool) : ∀ x y : Bool,
    f x y =
      ((lit true x && lit true y) && f true true)
      || ((lit true x && lit false y) && f true false)
      || ((lit false x && lit true y) && f false true)
      || ((lit false x && lit false y) && f false false) := by
  intro x y
  cases x <;> cases y <;> simp [lit]
```

读法：把 f 的四行真值表当作系数，右端就是「接受行的 minterm 展开」。
证明只分四种情形：x、y 落在哪一格，哪一格的 minterm 存活（其余
minterm 含假文字归零），幸存格的系数 f(该格) 复原左端——**定理
的证明就是「查表」这件事本身**。两个实现细节值得记：系数写在
minterm 右侧（`&&` 与 `||` 都从左侧模式匹配，字面量在左才能让
死项先归 false）；幸存项若不在 or 链末端，链会在 f 的不透明应用
处卡住，Lean 侧交给 `simp [lit]` 全套归约收尾，Coq 侧则是
`try rewrite orb_false_r; reflexivity`。三元多数函数（书例
7.5.5/7.5.6）是实例：`maj = xy + xz + yz` 的 minterm 展开是
`xyz + xyz̄ + xȳz + x̄yz`——`maj_dnf` 八格穷举。这同时是书
§7.5.5 的桥梁：**PL 公式的析取范式 = 布尔函数的 minterm 展开**，
第 2 章的真值表技术在代数侧拿到了它的存在性与唯一性证明。

## 七、化简：K-map 与 Quine-McCluskey

§7.6 处理工程侧的问题：minterm 展开是标准形但通常不最简。K-map
（二维到四维）把相邻 1 格圈成 2ᵏ 大小的块，每块对应少 k 个文字的
积项——视觉方法，文档级讲解，机器不参与。**Quine-McCluskey**
（§7.6.5）是 K-map 的算法化：把 minterm 写成位串，按 1 的个数
分组；相邻组中恰差一位的两串合并（该位变杠 `-`），反复合并到
不动点；**从未被合并吸收的模式就是素蕴涵项**（prime implicant，
不能再变短的蕴含项）；第二阶段建覆盖表，先取 essential（独占
某 minterm 的素蕴涵项），再补足覆盖。Prolog 是这套「生成-检查」
的天然宿主：

```prolog
combine([A|T], [B|T2], [-|T]) :- opp(A, B), T = T2.
combine([A|T], [A|T2], [A|T3]) :- combine(T, T2, T3).

qmc_primes(Ps, Primes) :-
    combine_step(Ps, News, Used),
    ( News == []
    -> Primes = Ps
    ;  subtract(Ps, Used, Keep),
       qmc_primes(News, Sub),
       append(Keep, Sub, P0),
       sort(P0, Primes) ).
```

`combine/3` 的两条子句就是「恰差一位」的定义：头部互补则尾部
必须全同，否则头部相同、往尾部递归找那一位。`qmc_primes/2` 的
不动点递归里，`Keep`（未被吸收的旧模式）逐层累积成素蕴涵项集。
第二阶段 `min_covers/3` 枚举素蕴涵项子集、过滤覆盖全部 minterm
者、按大小取极小。两个书的例子跑出与手算一致的结果：

```text
minterms [3,5,6,7]
  primes         : [xy,xz,yz]
  minimal covers : [[xy,xz,yz]]
  matches book result
minterms [1,3,4,5,6,7]
  primes         : [x,z]
  minimal covers : [[x,z]]
  matches book result
```

第一例是三元多数函数（书例 7.6.8）：四个 minterm 两两合并出
三个双文字素蕴涵项，每个都 essential（各独占一个 minterm），
极小覆盖唯一。第二例（书例 7.6.9）展示两轮合并：第一轮出七个
双文字项，第二轮把它们合成 x 与 z 两个单文字项——K-map 上的
四格块，算法上是一道杠的传播。调试记录里有一条值得写进教程：
合并参与者的采集必须**双向**（`U \== V` 而非 `U @< V`）——位串
111 在任何合并对里都是较大的那方，单向采集会让它漏网、以
「素蕴涵项 xyz」的假身份混进结果。对称性要靠对称的搜索保证。

## 坑位速记（本章实测）

- **PDF 文本层丢上杠**——§7.3 命题的补运算排印全部裸奔：共识律
  照提取文本抄是假命题（x=0,y=z=1 反例），中间项必须 x̄；冗余律
  x(x̅+y)=xy 同病。处方：涉及补的公式按数学实体校读，机器验证
  是唯一裁判。
- **Coq：`bool` 构造子序 true 在前**——`destruct x` 先弹 true 支，
  与「0 先」的直觉相反；b_cancel 的弹序曾接反。
- **Coq：三元组是嵌套对**——(c1,s1,s0) 即 ((c1,s1),s0)，`fst/snd`
  逐层取；直接 `(fst …)` 取到的是对不是标量。
- **Lean：系数写在 minterm 右侧**——`&&`/`||` 从左模式匹配，
  字面量在左死项才能先归 false、让 or 链逐层收缩；`f ss` 卡在
  or 左参数时，全 `simp [lit]` 一发收（`simp only` 的残局是
  decide 归一化的陶陶然式 `(decide (b = false) || b) = true`，
  自己凑引理族不如交全 simp）。
- **Lean：xor 的全名是根名 `xor`**（`Bool.xor` 是导出别名）；
  `Bool.not_true/not_false/or_false/false_or/true_and/false_and/
  and_true/and_false` 全家在裸 core 可用。
- **Prolog：对称合并要双向采集参与者**——`U @< V` 的单向搜索让
  最大模式（111）永不入 Used、以假素蕴涵项身份漏网；改
  `U \== V` 双向。
- **数学先于打印**：add2 的冒烟期望值先手算——10+01=11 是
  (false,true,true)，初版注释写成 (false,true,false)。

## 小结

Boole 代数把 55 章的格公理化成运算十条律，B={0,1} 上穷举即证明；
恒等式册（幂等到共识）全部机器入册，PDF 丢杠的假命题当场伏法。
Shannon 的接线让代数落地为门与加法器——`bval` 把布尔侧接回 nat，
半加器/全加器/行波进位的正确性是真值表的机器版。minterm 表示
定理给每个布尔函数一个唯一标准形（定理证明就是查表本身），
PL 的 DNF 与 K-map 的相邻格在此会师；QMC 把化简变成生成-检查
两阶段的纯算法，Prolog 十几行落地。代数、逻辑、电路、算法——
四条线在 Bⁿ 上打成一个结。下一章转到 ch8 的图论：欧拉路、
哈密顿圈、平面性与四色，组合数学的最小画布。

---

上一章：[55 偏序与格](docs/55-posetlattice.md) · 下一章：[57 图论专题](docs/57-graphs.md)
