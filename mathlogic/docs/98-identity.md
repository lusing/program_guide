# 第 98 章 同一性与结构主义

> 对书：Müller-Stach《The Code of Mathematics》ch 1「Fundamental
> Questions」（p14-28）+ ch 3 数系/附加法节（p44-52）+ ch 9 收束节
> （p148-152）。本章通道：C（`examples/98_identity/ex98_identity.v`）/
> L（`examples/98_identity/ex98_identity.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `leib`/`leib_eq` | **Leibniz 等词编码**（∀P. P a→P b）与内建 eq 的零公理双向等价 | C/L |
| `blockOf`/`hume_blocks` | **Hume 原理有限宇宙**：子集按「存在双射」（同基数）分块=1,3,3,1 | C/L |
| `vn`/`ze`/`zdepth` | **ℕ 三化身对照**：von Neumann/Zermelo 编码+计数读法逐位一致账 | C/L |
| `fermat`/`fermat_identity` | **Fermat 数素数无穷另证**：平方递推+积恒等式+两两互素 10 对账 | C/L |
| `euler_breaks_fermat` | F₅=641·6700417（Euler 拆解，N/GMP 通道） | C/L |
| `paireq`/`z_mul_welldefined` | **Z 的商构造**：(a,b)~(c,d)⟺a+d=b+c+乘法良定义 | C/L |
| `dmul`/`dual_leibniz` | **对偶数环** d²=0：(1+d)²=1+2d（Leibniz 法则机械流出） | C/L |

全教程的倒数第二章回到起点问题——**「5=5」与「5=3+2」是两种
什么不同的等式？数学对象到底是什么东西？**Müller-Stach 的书从
这里出发（ch 1）、在这里收束（ch 9）——本章把这个首尾合拢做完整：
从 Leibniz 的替换原理到 Frege 的数概念、从 Benacerraf 两难到结
构主义与 univalence，机器面七件套把「同一性」的每个转折都做成
可跑的账本。

## 一、两种等式：定义同一与命题相等

「5=5」是**定义性同一**（同一符号的两个写法）；「5=3+2」是**命
题等式**（需要计算/证明才见分晓）。这个区分直通类型论的两种
等式（转换规则 vs 恒等类型）——也是 Frege 涵义/指称之分（晨星
=暮星：指称同一、涵义不同）的数学版。

Leibniz 的等值原理（书 p17，拉丁原文照录）：

> Eadem sunt quorum unum potest substitui alteri salva veritate
> ——凡可在**真值保持**下互相替换者，是同一的。

机器面：把「任何性质都从 a 传递到 b」写成谓词，与内建等式**零
公理双向等价**：

```coq
Definition leib (a b : nat) : Prop :=
  forall P : nat -> Prop, P a -> P b.

Theorem leib_eq : forall a b, leib a b <-> a = b.
Proof.
  intros a b. split.
  - intros H. apply (H (fun x => a = x)). reflexivity.
  - intros H P HP. rewrite <- H. exact HP.
Qed.
```

两个方向的机制都值得细看：**→** 用 P := fun x => a = x 的对角
化——「任何性质都传递」直接兑现为「等式性质也传递」（P a 就是
a=a，由 reflexivity 免费）；**←** 就是替换本身。书 p123 的原话：
类型论的 Id-elim（路径归纳）正是这条替换规则的深远推广——53 章
的等词逻辑在此找到它的哲学源头。Leibniz 的另一半（分开看不可
分辨则相似——等价概念的雏形）与替换的循环依赖（替换预设真理
概念）记文档线：**用「真」定义「同」还是用「同」定义「真」**
——Tarski（56 章）与 Leibniz 在这里握手。

## 二、Frege 的数概念：Hume 原理与 Caesar 问题

Frege《算术基础》(1884) 的三层构造（书 p25-27 全部提炼）：

1. **数陈述是关于概念的陈述**：「木星有四颗卫星」说的不是卫星
   这个或那个，是「木星卫星」这个概念的实例数；
2. **Hume 原理**：概念 F 与 G 等数 ⟺ 存在双射 F→G——数由等数
   关系定义，不依赖「数是什么实体」；
3. **Number(F) = {G | G≅F}**——数是等数等价类。

机器面：{0,1,2} 的八个子集按「存在双射」（有限集=同基数）分块：

```coq
Definition blockOf (x : list nat) : list (list nat) :=
  filter (sameCard x) sub3.

Example hume_blocks :
  [ blockOf []; blockOf [0]; blockOf [0;1]; blockOf [0;1;2] ]
  = [ [[]]; [[0]; [1]; [2]]; [[0;1]; [0;2]; [1;2]]; [[0;1;2]] ].
Proof. reflexivity. Qed.
```

完整分块 **1,3,3,1**（二项式系数）——「数 3」就是那块三个单例
的等价类。**Caesar 问题**紧随而来（Frege 自己发现的裂缝）：等
数抽象定义了数 3 这个类，但凭什么断定「Julius Caesar ∉ 3」？—
—抽象原理只区分「等数/不等数」，给不出元素级的身份判定。Frege
的救援方案（数=概念的外延，即集合）撞上了下一块礁石。

**Russell 悖论**（书 p28 的通信史照录）：1902 年 6 月 16 日
Russell 致 Frege 信（「自己不是自己的成员的类」），Frege 6 月
22 日回信：「算术 shaken……Law V 是假的」——逻辑主义在两个
星期内从内部爆裂。历史注脚：**Zermelo 比 Russell 更早发现**（
Hilbert 1903 年信中记录），Poincaré 从另一侧攻击（「归纳是综
合先天判断，不是逻辑」）。新逻辑主义（neologicism，书 p28）的
救援：只公理化 Hume 原理即可恢复 PA（Frege 定理，Wright/Hale
1983-）——但 Hume 原理本身是不是「纯逻辑」仍有争议——Caesar
问题换了身衣服继续在场。

## 三、ℕ 三化身：Benacerraf 两难与结构主义

同一条 Dedekind–Peano 公理，至少三个集合实现（书 ch9 p136-
137）：

| 化身 | 0 | S |
|---|---|---|
| von Neumann | ∅ | Sx = x ∪ {x}（集合=全部前驱） |
| Zermelo | ∅ | Sx = {x}（单层嵌套） |
| Dedekind | 二阶 (X, s, z) 链——不可集合编码 |

机器面两化身的对照账：

```coq
Fixpoint vn (n : nat) : list nat :=
  match n with 0 => [] | S k => k :: vn k end.

Inductive zset : Type := zleaf | znode (x : zset).
Fixpoint ze (n : nat) : zset :=
  match n with 0 => zleaf | S k => znode (ze k) end.
```

（实现注记：Zermelo 编码的**嵌套深度依赖值**——扁平 list 装不
下（每层类型都不同），必须用归纳树类型忠实编码——类型系统在
替集合论背书「层数」这个依赖信息。）两账本：`vn_faces`（vn 的
四化身 ∅,[0],[1;0],[2;1;0]）与 `faces_agree`（vn 的元素数与 ze
的嵌套深度逐位一致——都恰为位置索引）。

**Benacerraf 两难**（1965，书 ch1 p23-24）：vn 3=[2;1;0] 与 ze
3=znode³(∅) 是两个完全不同的集合，却承载同一个数。「**数到底
是哪一个集合？**」没有答案——若说都是，3 就有两个身份；若说
只其一，选择无根据。朴素集合论的外延性缺陷（书 p23-24 的例子：
{Jan 的狗, Heike 的猫} 与同构的 {Erik 的狗,…}——交运算依赖元素
本身，同构不保交）加深了怀疑。

**结构主义出口**：数不是实体，是**结构中的位置**——「3」=
「Dedekind–Peano 结构第三个位置」，vn/ze 是同一个结构的两个实
现。数学命题的真假只依赖结构（同构不变量）——这与 Weyl 的不
变性真理观（56 章）合流。**univalence**（指向类型论指南）：类
型论把「等价可升级为同一」做成公理——Leibniz 的 salva veritate
在类型宇宙层的终极形态；同伦解释（h-层级）给「相等」一个光谱
而非开关。Müller-Stach 的裁决（书 p151）：三种基础（集合/类型/
高阶范畴）互为对象/元语言、互相解释——「同一性」没有唯一答案，
只有**相对于基础的身份**。

## 四、Fermat 数：素数无穷的另证（结构主义之外的一站）

书 ch3（p44-45）给的数论样本，做成本章的第四件：

```coq
Fixpoint fermat (m : nat) : nat :=
  match m with
  | 0 => 3
  | S k => let h := fermat k - 1 in h * h + 1   (* (F_k−1)²+1 *)
  end.
```

三张账：**恒等式** F₄=F₀F₁F₂F₃+2（3·5·17·257+2=65537 ✓）；**两
两互素**（10 对 gcd 全 1——证明一瞥：d|F_i 且 d|F_j ⟹ d|2，而
Fermat 数全奇 ⟹ d=1）；**素数无穷另证**：每个 F_m 带新素因子。
与 86 章 Euclid 证法（n!+1）对照——同构的骨架，不同的尺。

**Euler 的反转**（1732）：F₅=2³²+1=4294967297=**641·6700417**—
—「F_m 全素」的 Fermat 猜想一击毙命（`euler_breaks_fermat`，
42.9 亿走 N/GMP 通道——55 章的惯例：unary nat 装不下，Coq 分段
scope 三坑全数适用；素数无穷另证不受影响，它只要互素不要素性）。
数论的教训与本章主题同构：**Fermat 看到的模式（F₀..F₄ 全素）
不是结构的必然**——前四个样本的「同一性」在第五回合碎裂。

## 五、商构造：同一性的三次让位

数系塔的每层都在重演「同一性让位于结构」（书 ch3 p46-52）：

**负数=等价类**。整数的 Grothendieck 构造：(a,b) 表示 a−b，
(a,b)~(c,d) ⟺ a+d=b+c：

```coq
Definition paireq (u v : nat * nat) : bool :=
  Nat.eqb (fst u + snd v) (snd u + fst v).

Definition pairmul (u v : nat * nat) : nat * nat :=
  (fst u * fst v + snd u * snd v,
   fst u * snd v + snd u * fst v).
```

账本：−3 的两写法 (2,5)~(7,10)、真负例 (2,5)⊄(0,1)、乘法**良定
义**（同类对各自相乘仍同类：(2,5)·(3,1)=(7,10)·(3,1)=(11,17)
=−6）。「−3 是哪对数？」——Benacerraf 两难的整数版，答案相同：
它是等价类，不是实体。

**无穷小=商环元素**。附加法两步（书 p50-52）：加自由变元得
R[T]，再加关系得 R[T]/(f)——f=T²−2 给 √2 的算术；f=T² 给
**Leibniz 无穷小环**：

```coq
Definition dmul (u v : nat * nat) : nat * nat :=
  (fst u * fst v, fst u * snd v + snd u * fst v).

Example d_squared_zero : dmul (0, 1) (0, 1) = (0, 0).
Example dual_leibniz : dmul (1, 1) (1, 1) = (1, 2).
```

d²=0 被焊进乘法表；(1+d)²=1+2d——**平方项被商关系吞掉**。微积
分的 Leibniz 乘法法则 (fg)'=fg'+f'g 不再是极限的比喻，是商环
的机械推论：(f+df)(g+dg)−fg 展开、d² 项归零、剩 f·dg+g·df。
「dx 是什么？」——又一个让位于结构的同一性。

## 六、收束：同一性的光谱（文档线）

Müller-Stach 的全书弧线在本章合拢（p150-152）：

- **哲学巡礼的尺度**：Leibniz 的磨坊（走进大脑只见机器、不见
  思想）、Heidegger/Fichte/Hume 的人格同一性（「心灵是剧场」）
  ——本章只点到为止，它们是数学同一性问题的语境而非内容；
- **等价=同一性的解构**（书 p148-150）：真理怀疑主义的相对化
  （Γ⊢A 的「相对真」）与 Hösle 的自驳反驳（56 章）、Weyl 的
  不变性判据——「稳定/绝对」的真理=范式转移下的不变量；
- **三基础圆环**：集合论（96 章 NBG）、类型论（univalence 一
  瞥）、高阶范畴论——互为对象/元语言；同一性相对于基础，结构
  主义是共同的精神底色。

机器面的总账：Leibniz 等词=替换（零公理）、Hume 分块=基数等价
类、三化身=同构对照、Fermat 数=模式的幸与不幸、Z 商构造=良定义、
对偶数=d²=0——**同一性的每个数学转折都留下了可跑的账本**。

## 小结

「A=A」从来不是废话——它是整座大厦的地基问题。Leibniz 用替换
定义同一，Frege 用等数定义数，Russell 炸掉了外延救援，Benacerraf
追问「数是哪个集合」，结构主义回答「数是位置」，univalence 把
「等价即同一」做成公理。机器面七件套让每一步都可执行：替换原
理的零公理双向、等数分块的 1,3,3,1、三化身的同构账、Fermat 数
的互素与 Euler 反例、负数与无穷小的商构造。下一章（80）收官全
教程：七轮扩充的图景、频谱、总坑位，与 Leibniz 之梦的当代读法。

---

上一章：[97 算术与几何的公理系统](docs/97-axioms.md) · 下一章：[99 收官：从命题到不完备性——全教程图景（九轮合拢）](docs/99-wrapup.md)
