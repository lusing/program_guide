# 第 80 章 真理理论：Tarski 不可定义与 Kripke 不动点

> 对书：Müller-Stach《The Code of Mathematics》ch 2「Tarski's
> Theory of Truth」+ ch 9「Semantics and Reality」（p134-140）。
> 本章通道：C（`examples/80_truth/ex80_truth.v`）/
> L（`examples/80_truth/ex80_truth.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `tschema_chain` | T-模式 T(⌜φ⌝)↔φ 的小宇宙全枚举对账 | C/L |
| `allPreds`/`agrees` | 「全枚举含真集自身」的**诚实失败现场**（有限/无限分界） | C |
| `flipAt`/`diag_flip` | **对角逃逸的逐位化**：每个可定义集在自己的对角位装不下真集 | C/L |
| `t3neg`/`t3or`/`t3and` | 强 Kleene 三值求值器（U∨T=T 与 U∨L=U 的对照表） | C/L |
| `iterK`/`stepK` | Kripke 跳跃的**单调迭代**+收敛账（说谎者环恒 U） | C/L |
| `vT`/`fixed_vT` | 诚实者的**扩张不动点**（「本句真」双固定点） | C/L |
| `iterTop`/`top_oscillates` | 从全真起步的**振荡现场**（周期 4，不收敛） | C/L |

79 章讲了「证不出」；这一章讲「**说不清**」——真理这个概念
本身能否在对象语言里定义。Müller-Stach 把这条线贯穿全书：
ch 2 从 Leibniz 的普遍语言梦引出 Tarski，ch 9 用 Kripke 的不
动点收束「Finding the Truth」——本章把两章合并成一个自包含
的真理理论专题：Tarski 分层（真谓词必须住进更富的元语言）、
不可定义性定理（真句子集逃出全部算术可定义集）、Kripke 1975
（让自指进来，代价是第三个真值）。

**先辨析同名两物**：16 章的「Kripke 语义」是**直觉主义/模态
逻辑的可能世界语义**（世界+偏序+强迫关系）；本章的 Kripke
是 **1975 年真理论的不动点构造**（"Outline of a Theory of
Truth"）。同一个人、两套理论、互不依赖——Müller-Stach 书里
也分别在两处出现（p141 模态完备性、p136 真理论）。

## 一、T-模式：真谓词钉在语义上

Tarski 1933「Der Wahrheitsbegriff in den formalisierten
Sprachen」的回答分两层。第一层是**约定 (T)**：对对象语言的
每个句子 p，元语言必须证明

> T(⌜p⌝) ↔ p

——「『雪是白的』为真，当且仅当雪是白」。T-模式不是真谓词
的定义，是**任何合格定义必须满足的 adequacy 条件**。机器面
的小宇宙版（六个句子、真值表给定）：

```coq
Definition TRUTH : list bool :=
  [true; false; true; false; true; false].

Definition tsat (i : nat) : bool := nth i TRUTH false.

Example tschema_chain :
  map (fun i => Bool.eqb (tsat i) (nth i TRUTH false)) (seq 0 6)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.
```

平凡？正是重点——T-模式的全部内容就是「真谓词的读数与语义
表逐位一致」。**麻烦在第二层**：这个谓词必须住在**元语言**
里。对象语言（如算术 L_ar）自己装不下它——这就是不可定义性
定理。

## 二、不可定义性：真集逃出全部可定义集

**定理（Tarski 不可定义性，书 p139-140）**：Th(ℕ)——在标准
模型 ℕ 里为真的句子的 Gödel 数集——**不是算术可定义的**：
不存在算术公式 True(x) 使 ∀n(True(n̄) ↔ n∈Th(ℕ))。

证明骨架与 78 章对角引理同源，只换一个谓词：对角引理给出句
子 D 使 D ↔ ¬True(⌜D⌝) 可证；问 D 真不真——真则 True(⌜D⌝)
真则 ¬D，矛盾；假则 ¬True(⌜D⌝) 真则 D，矛盾。**Gödel 用
「我不可证」逃证明系统，Tarski 用「我不真」逃定义系统——一
个对角、两种逃逸**（79 章的亲兄弟）。推论（书 p140）：真
Gödel 数集甚至不可算术枚举——由 H10 不可判定性（82 章
DPRM），diophantine 集 ⊆ 算术集，而可证集与真集的分离在每
一层都可感。

机器面先做一个**诚实失败现场**（教程惯例——失败比成功教学
价值更高）：

```coq
Definition allPreds : list (list bool) := (* 6 位布尔表全枚举：64 个 *)
  ...

Example tarski_shadow :
  forallb (fun P => negb (agrees P)) allPreds = false.
Proof. reflexivity. Qed.
```

**结果 false**：64 个布尔表里恰有一个就是 TRUTH 自身！这是
有限宇宙与无限算术的分界现场——「全枚举」在小宇宙里包含真
集自己；Tarski 的定理要在「**式子可定义**的谓词族」上做——
可定义集的可数族永远比全谓词族（不可数，或有限宇宙里的全枚
举）小，真集正是从缝隙里逃走。

修正后的机制账——对角化的逐位化：

```coq
Fixpoint flipAt (k : nat) (l : list bool) : list bool :=
  match l with
  | [] => []
  | x :: t => match k with
              | 0 => negb x :: t
              | S k' => x :: flipAt k' t
              end
  end.

Example diag_flip :
  map (fun k => negb (Bool.eqb (nth k (flipAt k TRUTH) false)
                               (nth k TRUTH false)))
      (seq 0 6)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.
```

读法：假设真集 = 第 k 个可定义集 P_k 的 extension。对角句
flipAt k TRUTH（「我不在 P_k 里」的逐位化）在位置 k 与真集
**相反**——P_k 想在自己对角位上与真集重合，被强制翻转。每
个可定义集都被自己的对角句逼出去：**对角化的语义侧影子**
（77/78/79 章的证明侧对角在此翻面）。分层是唯一出路——真
谓词住进元语言（通常 ZF），对象语言的「真」由元语言**定义**
：Müller-Stach 的话，「语义被祛魅：无非是更丰富演绎系统中的
可证性」。这正是 123 章三基础互译圆环的起点。

## 三、强 Kleene 三值：让自指进来

Tarski 分层把自指逐出对象语言；Kripke 1975 反其道——**让自
指进来，代价是第三个真值 U（undefined/未定）**。语义骨架是
强 Kleene 三值逻辑：

```coq
Inductive t3 : Type := TF | TU | TL.   (* 真/未定/假 *)

Definition t3or (x y : t3) : t3 :=
  match x, y with
  | TF, _ => TF | _, TF => TF     (* 有真即真 *)
  | TL, z => z | z, TL => z       (* 有假则取决于对方 *)
  | _, _ => TU                    (* 双未定 *)
  end.
```

关键的两行对照（`k3_table`）：**U∨T=T**（部分信息足以决出
——未定与真的析取恒真）而 **U∨L=U**（定不了——未定与假的析
取取决于未定者）。合取按 De Morgan 镜像（U∧L=L——未定与假
的合取恒假，因为无论未定者真假结果都是假）。**能定的定、
定不了的悬置**——这是「部分信息传播」的完整纪律。

## 四、Kripke 跳跃：从全未定到不动点

把一组自指句子做成数据（本章的六句宇宙——说谎者环、诚实者、
混合接地句）：

```coq
(* 0=「句1假」 1=「句0真」（说谎者环）；2=「句3假」 3=「句3假」；
   4=「句4真」（诚实者）；5=「句4假 ∨ 句2真」 *)
Inductive claim : Type :=
| cf (i : nat) | ct (i : nat) | cor (c1 c2 : claim).

Definition stepK (v : list t3) : list t3 := map (ev v) SENTS.
```

`stepK` 是 **Kripke 跳跃**：在当前估值 v 下对每句重新求值。
迭代从**全未定**起步：

```coq
Fixpoint iterK (n : nat) : list t3 :=
  match n with
  | 0 => [TU; TU; TU; TU; TU; TU]
  | S n' => stepK (iterK n')
  end.
```

三条账本：

1. **单调性**（`kripke_monotone`）：迭代只把 TU 变确定、绝不
   翻面（已定的真保持真、假保持假）——信息只增不减。这是
   最小不动点存在的命脉（Knaster–Tarski 的可数情形：单调
   算子的最小不动点 = 从底元起 ω 链的上确界——与 94 章 μ
   演算的最小不动点语法同一结构）。
2. **收敛**（`kripke_fixpoint`）：有限句集在第 3 步停摆——
   `iterK 2 = iterK 3 = iterK 4`。真实语言里收敛要 ω 步
   （Tarski 层级的每层对应一轮跳跃——「语言塔 L₁⊂L₂⊂…的
   极限」的书 p136 表述正是这个迭代）。
3. **说谎者恒 U**（`liar_undefined`）：最小不动点上六句全
   TU——说谎者环「句0 假且句1 真」怎么定都翻车，最小不动点
   给它 U：**既不真也不假——无根基（ungrounded）**。Kripke
   的解法：不硬分真假，让它悬着。

**诚实者的双固定点**（`fixed_vT`/`truth_teller_double`）：句
4=「句4真」。最小不动点上它是 U；但估值 vT=[U;U;U;U;**T**;U]
**也是 stepK 的不动点**——句 4 定真则「句4真」自我兑现，其
余句子不受牵连。「本句真」有两种稳定读法（U 或 T）——二值化
后即真假两读，这正是它悖论感更隐蔽的原因（说谎者怎么定都翻
车，诚实者定不定两可）。

**振荡现场**（`top_oscillates`）：若从**全真**起步做跳跃，说
谎者环 0/1 在 T/L 之间周期 4 摆动、永不收敛——

```
iterTop 0 = [T,T,T,T,T,T]
iterTop 1 = [L,T,L,L,T,T]
iterTop 2 = [L,L,T,T,T,T]
iterTop 3 = [T,L,L,L,T,T]
iterTop 4 = [T,T,T,T,T,T]   ← 回到起点，周期 4
```

最小不动点路径（全 U 起步）单调可收敛；换起点立刻失灵——
**Kripke 构造的命脉在「从无知出发」**。

## 五、真理相对主义与不变性（文档线，书 ch9 尾声）

- **Hösle 的自驳反驳**：极端真理相对主义（「一切真理皆相对」）
  自指自驳——这句宣言自身凭什么绝对成立？performative self-
  contradiction。
- **Weyl 的不变性判据**：用**等价类给真理分类**——「稳定/绝对」
  的真理是在一切合理范式转移下不变的命题（「地球近似球形」
  在任何坐标系变换下不变）。数学的 Γ⊢A 判断是相对的，但其
  不变核（可证性的等价类）是绝对的——**结构主义的真理观**，
  与 122 章「同构即同一」合流。
- **现实的符号构造**（Weyl/Democritus）：物理学用规范群
  A↦g⁻¹Ag+g⁻¹dg 这样的**符号机器**构造现实——数学真理的
  「有效性」最终锚在不变性上，而非柏拉图空间。

## 小结

Tarski 与 Kripke 是真理理论的两个极点：**分层**（真谓词住进
元语言，自指被逐出）与**不动点**（自指进来，三值兜底）——共
识是「经典二值+自指+自身真谓词三者不可兼得」。机器面五个现
场全部可跑：T-模式全枚举、全枚举失败现场（有限/无限分界的
诚实账）、对角逐位化、强 Kleene 表、最小不动点迭代（单调/
收敛/说谎者恒 U）加双固定点与振荡对照。79 章「证不出」与本
章「说不清」在 123 章合流：三基础互译圆环里，语义=更富语法，
真理=不动点——Leibniz 之梦的现代读法。下一章转向构造性：
当「存在」必须携带见证，逻辑的面貌如何改写。

## 注记：真值分层——「可定义」的层级账（Takeuti 轮补）

本章的定理「PA 真理在 PA 内不可定义」与第 73 章（二阶算术证明论）
的「S₁ 内可定义 PA 真」并不冲突——**Tarski 禁区按语言分层**。
分层真值定义（truthDef，Takeuti §21 的 T_n 谱系）逐层放宽：
第 n 层公式（量词深度/复杂度 ≤n）的真谓词可在第 n+1 层内定义，
每一层都是「诚实的部分真」，而全真谓词 T=∪T_n 越过一切层——
正是本章对角线的用武之地：若 T 本身可定义，对角化立即矛盾。
两章对读的正确姿势：73 章给「部分真可定义」的构造性上限，
本章给「全真不可定义」的否定性下限，二者合成完整的分层图景。


---

上一章：[79 Gödel 第二不完备与一致性扩张](docs/79-goedel2.md) · 下一章：[81 构造性与 Heyting 语义](docs/81-constructive.md)
