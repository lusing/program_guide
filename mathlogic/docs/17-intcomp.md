# 第 17 章 直觉主义完备性：Kripke 语义与 Heyting 代数

> 对书：Takeuti《Proof Theory》2e §8（p52-74）：LJ' 与临界推理（Def 8.12/
> Prop 8.13）、Kripke 结构与力迫（Def 8.14）、可靠性与典范反模型（Prop
> 8.15/8.16、Thm 8.17）、cHa 与 Rasiowa-Sikorski（Def 8.19、Thm 8.25）、
> Kripke↔cHa 对应（Thm 8.27）、Takeuti-Titani [0,1] 完备性（Def 8.29–
> Thm 8.31，文档线）。本章通道：C（`examples/17_intcomp/ex17_intcomp.v`）/
> L（`examples/17_intcomp/ex17_intcomp.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `kfw` | **力迫求值器**（Def 8.14 b)-e) 命题部分：否定/蕴含的「全未来世界」量词） | C/L |
| `monoOk` | 赋值单调性检查（Def 8.14(3)：Kripke 结构的定义性约束） | C/L |
| `ikValid` | **全枚举有效性**：固定有限偏序上全单调赋值×全世界——完备性的可判定核心 | C/L |
| `kRefute` | **反例搜索器**：小偏序族+全部单调赋值自动找出 LEM/DNE/Peirce 的反模型 | C/L |
| `bracketOf`/`upClose` | **[A] 上集账**（Thm 8.27 引理 1)-3)：力迫集=上集、∧ 对交、∨ 对并） | C/L |
| `sup2` | Sierpinski 开集格的 Heyting 蕴含（Ex 8.20 Galois 伴随） | C/L |
| `gdv`/`gdValid` | **有限线序 cHa**（Gödel-Dummett 语义）：前线性有效——Int < GD < Cl 谱系现场 | C/L |

16 章造了 Kripke 反例模型回答「经典原理为什么直觉主义证不出」；63 章在
Heyting 代数（开集格）上看到了同一批公式的失效。本章把两条线焊成完整的
元定理：**直觉主义逻辑对 Kripke 语义可靠且完备**（Takeuti Thm 8.17）——
「证不出」从此不仅是「有反例」，而是「有反例**当且仅当**证不出」。这是
直觉主义逻辑的「语义执照」：演算没有漏掉任何 Kripke 有效式，Kripke 语义
也没有虚构任何不可证式。

## 一、LJ' 与临界推理：完备性的语法准备

Takeuti 的证明不用 LJ 本尊，而用 Maehara 的多后件系统 **LJ'**：对 LK（后
件可多公式）作一条限制——¬:right、→:right、∀:right 这三条**临界推理**
（critical inferences）只允许在后件恰为该主公式单公式时使用。两条等价性：
LJ' 矢列 Γ→B₁,…,Bₙ 读作 Γ→B₁∨…∨Bₙ 即与 LJ 等价；切消对 LJ' 照样成立。

为什么恰恰是这三条？看力迫条款就明白：**¬、→、∀ 的后件引入语义上都要求
「全部未来世界」**，矢列层面它们天然携带「尚无反例、留待将来」的信息——
所以归约树构造（28 章的经典版）在直觉主义版里**恰好删去这三条的后件归约
阶段**。临界推理=「未来可能被强制」的语法指纹。机器面不直接实现 LJ'，而
是把同样的不对称做进力迫语义（下一节），效果等价。

## 二、力迫：知识状态上的真

Def 8.14 的命题部分（机器件 `kfw`）：

```coq
Fixpoint kfw (n : nat) (le : nat -> nat -> bool)
             (v : nat -> nat -> bool) (a : kform) (w : nat) : bool :=
  match a with
  | kp p     => v w p
  | kand b c => andb (kfw n le v b w) (kfw n le v c w)
  | kor  b c => orb  (kfw n le v b w) (kfw n le v c w)
  | kneg b   => forallb (fun q => implbb (le w q) (negb (kfw n le v b q)))
                        (worldsOf n)
  | kimp b c => forallb (fun q =>
                  implbb (le w q)
                       (implbb (kfw n le v b q) (kfw n le v c q)))
                      (worldsOf n)
  end.
```

设计只有一处要盯住：∧/∨ 在**当下世界**点态计算，而 **¬ 与 → 不看当下、
看全部将来**——`kfw` 对 ¬/→ 遍历所有满足 `le w q` 的未来世界 q。这就是
16 章「知识状态」直觉的形式化：说「¬p」不是「p 现在假」，而是「到任何
可到达的将来 p 都不会真」。谓词版还有两条更尖的不对称（文档线）：∃ 的
见证必须**当下**就在域里（`U_p`），∀ 要对**未来域** `U_q` 验证——机器面
限命题片段，这两条留在 docs 讲清楚。

赋值本身有约束（Def 8.14(3)）：原子一旦在某世界真，就在所有未来世界真
——`monoOk` 逐对检查：

```coq
Definition monoOk (n : nat) (le : nat -> nat -> bool)
                  (v : nat -> nat -> bool) (maxp : nat) : bool :=
  forallb (fun w => forallb (fun q => forallb (fun p =>
    implbb (andb (le w q) (v w p)) (v q p)) (seq 0 maxp)) (worldsOf n))
    (worldsOf n).
```

这个「单调」约束不是装饰——它是**可靠性方向的引擎**（Prop 8.15 的归纳
恰在此处用单调性），也是本章机器面第一个坑的来源（见第五节）。

## 三、完备性：可靠方向与典范反模型

**可靠性**（Prop 8.15）：LJ' 可证的矢列在一切 Kripke 结构有效——对推理
数归纳，每条规则逐条过闸。**完备性**（Thm 8.17）走典范反模型路线：对不可
证矢列建归约树（删去三个临界后件归约阶段），Prop 8.13 保证树上有一条全不
可证的**分支**；以分支为阶段造偏序（Γ₀ 中每个 ¬/→/∀ 型后件公式张出一个
直接后继阶段），赋值取「原子出现在分支前件」，真值引理（Prop 8.16）逐公式
归纳验证「前件真、后件假」。无穷矢列与广义 König 引理是 Takeuti 版的两个
特色（适用于不可数语言）——机器面取而代之的是完备性的**可判定核心**：

```coq
Definition ikValid (n : nat) (le : nat -> nat -> bool)
                   (maxp : nat) (a : kform) : bool :=
  forallb (fun v => implbb (monoOk n le v maxp)
                        (forallb (fun w => kfw n le v a w) (worldsOf n)))
          (enumVals maxp (Nat.pow 2 (n * maxp))).
```

命题 Kripke 语义有**有限模型性质**（Thm 8.17 典范模型构造的副产品）：反例
若存在，则存在于有限偏序上。于是「有效性」变成可计算：全枚举赋值×世界。
`ikValid` 的账例——直觉主义有效式三连：

```coq
Example ikValidNotNotIntro :   (* p -> ~~p：直觉主义有效 *)
  ikValid 3 le3v 1
    (kimp (kp 0) (kneg (kneg (kp 0)))) = true.
Example ikValidConjImp :   (* (p->q)->(p/\q->q) *)
  ikValid 3 le3v 2
    (kimp (kimp (kp 0) (kp 1))
          (kimp (kand (kp 0) (kp 1)) (kp 1))) = true.
```

反方向（不可证⟹有反例）由**搜索器** `kRefute` 承载——对两点链与三点 V
形两族偏序、全部单调赋值，找一个 `(v,w)` 使力迫为假：

```coq
Example kRefuteLem : kRefute (kor (kp 0) (kneg (kp 0))) = true.
Example kRefuteDne :
  kRefute (kimp (kneg (kneg (kp 0))) (kp 0)) = true.
Example kRefutePeirce :   (* Peirce：经典有效直觉无效 *)
  kRefute (kimp (kimp (kimp (kp 0) (kp 1)) (kp 0)) (kp 0)) = true.
```

LEM 与 DNE 共用同一个反例模型（两点链，p(0)=F、p(1)=T）：`¬p(0)` 因世界 1
见证 p 真而为假，于是 `p∨¬p` 在 0 假；`¬¬p(0)` 反而真（p 在将来真），于是
`¬¬p→p` 在 0 假。**反例模型的选择本身是教学点**——对照组「p 处处假」的
模型里 `¬¬p` 也假、蕴含空真：

```coq
Example dneVacuous :
  kfw 2 le2 (fun _ _ => false) (kimp (kneg (kneg (kp 0))) (kp 0)) 0 = true.
```

不是随便找个「p 假」的模型就能 refute——要找的是**前件被力迫而后件不被
力迫**的模型。这一条直觉在考试和科研里同样救命。

## 四、cHa 与 Rasiowa-Sikorski：代数侧的完备性

第二重完备性把语义换成**完备 Heyting 代数**（cHa，Def 8.19）：完备格满足
无穷分配律 p∧(∨qᵢ)=∨(p∧qᵢ)，蕴含 p⇒q:=∨{r : p∧r≤q}。Def 8.21 给 Ω-值
结构：谓词取值于 Ω，量词=完备格的交/并。**Thm 8.25（Rasiowa-Sikorski）**
：LJ 不可证 ⟹ 存在 cHa 与 Ω-值结构使前件全 1、后件全 ≠1。证明的引擎是
**Lindenbaum 代数**：公式按「Γ,A⊢_LJ B」取商等价类 |A|，连接词代表交并
蕴含（→ 的伴随性恰由 LJ 的 → 规则给出），两条 sup 性质（∀/∃ 的交并账）
把量词装进代数；最后用 Rasiowa-Sikorski 嵌入引理（素理想 Stone 空间→
拓扑 Boole 代数→正则开集，Ex 8.26）把 H 换成保无穷交并的 cHa。

机器面在两点链上把这套代数摸实：两点链的全部**上集**恰三个——∅、{1}、
{0,1}——即 **Sierpinski 开集格**（63 章的老朋友在 Kripke 世界里的化身）。
Thm 8.27 的核心是 [A] 引理：每个公式对应其力迫世界集

```coq
Definition bracketOf (n : nat) (le : nat -> nat -> bool)
                     (v : nat -> nat -> bool) (a : kform) : list nat :=
  filter (fun w => kfw n le v a w) (worldsOf n).
```

三条账：**[A] 是上集**（`bracketUpset` 用 inclb 双向验证——单调性 Prop
8.15 的集合面）、**[A∧B]=[A]∩[B]**（`bracketAnd`：[p]={1}、[¬¬p]={0,1}、
交回 {1}）、**[A∨B]=[A]∪[B]**（`bracketOr`）。上集族对交并封闭、蕴含按
Galois 伴随定义——Heyting 代数就长在 Kripke 结构上。Sierpinski 的蕴含
`sup2`（满足 S∩U⊆T 的最大上集）：

```coq
Definition sup2 (S T : list nat) : list nat :=
  if inclb (interl S [0; 1]) T then [0; 1]
  else if inclb (interl S [1]) T then [1]
  else [].
```

Ex 8.20 的 Galois 性质 p∧r≤q ⟺ r≤(p⇒q) 三组样本：`{1}⇒{0,1}`=顶、
`{1}⇒∅`=∅、`∅⇒T`=顶——「从大到小试上集」的实现把「最大性」变成搜索。

## 五、Takeuti-Titani 一瞥：[0,1] 上的直觉主义

书 §8 尾给出单无穷 cHa 上可公理化的范例：LJ_I = LJ + 四条公理 + 一条
规则，对 [0,1] 线序 cHa（a∧b=min、∨=sup、⇒ 为 Gödel 蕴含）完备（Thm
8.31）。其命题公理 1+2 合成**前线性** (A→B)∨(B→A)（Prop 8.28(1)）——
Gödel-Dummett 逻辑的血统。完备性证明的饱和集构造与密度论证（Prop 8.30：
取 p̂∈(|C|,|B|) 之间的实数）记文档线〔⚠〕（公理 4 的形状在扫描件中残缺，
docs 按 Prop 8.28(4) 反推，机器面不覆盖〕。

机器面用**有限线序 cHa**（4 点链）采样这个谱系：蕴含 p⇒q = p≤q ? 顶 : q
（`gdv`），有效性全枚举（`gdValid`）。三个账例拼出逻辑谱系的现场：

```coq
Example gdPrelinear :
  gdValid (kor (kimp (kp 0) (kp 1)) (kimp (kp 1) (kp 0))) = true.
Example prelinearNotInt :
  ikValid 3 le3v 2 (kor (kimp (kp 0) (kp 1)) (kimp (kp 1) (kp 0))) = false.
Example gdDneInvalid :
  gdValid (kimp (kneg (kneg (kp 0))) (kp 0)) = false.
```

前线性在链上有效、在分叉偏序（三点 V 形）上无效、DNE 在链上照样失效——
**Int ⊂ GD ⊂ Cl** 三层谱系在三个检查器上现形。Takeuti 在本节开头提出的
两个开问题（对一般 cHa Ω 的 LJ_Ω 可公理化性）至今仍是研究前沿的入口。

## 六、本章机器面的两个坑（实录）

第一个坑在**赋值枚举**：`ikValid`/`kRefute` 最初枚举全部赋值（含非单调
的），非单调赋值下 p→¬¬p 会出现假反例——Kripke 结构的「单调」是定义的一
部分，不是可选项。修正后枚举器只认 `monoOk` 通过的赋值。第二个坑在**搜索
器的过滤方向**：跳过非单调赋值的条件写成 `implbb (monoOk …) (…)` 会让非
单调赋值恒真通过（implb 假前件恒真）——搜索器「找到」的其实是非单调赋值
本身；必须用 `andb (monoOk …) (…)`。判定方向与有效性方向看似对称，取反
的一瞬间就翻车——这是「可靠/完备双向账」在工程里的镜像。

## 小结

力迫把「知识状态」变成数学对象；LJ' 的临界推理划出「未来」的语法指纹；
完备性把演算与语义焊死（可靠+典范反模型）；Lindenbaum 代数与上集账把
Kripke 结构翻译成 cHa（Thm 8.27 的逐句对应）；[0,1] 与有限链把谱系延伸到
Int 与 Cl 之间。下一章（18 章）回到经典世界的历史系统；28 章将把本章的
归约树姊妹篇——经典完备性的证明论路线——完整机器化。

---

上一章：[16 Kripke 语义：不可证性的机器证据](docs/16-kripke.md) · 下一章：[18 三段论与传统逻辑](docs/18-syllogism.md)
