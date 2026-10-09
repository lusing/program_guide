# 第 51 章 Gödel 第二不完备与一致性扩张

> 对书：Müller-Stach《The Code of Mathematics》ch 6「Deductive
> Systems and Incompleteness」Gödel II 节（p93-95）。本章通道：C
> （`examples/51_goedel2/ex51_goedel2.v`）/
> L（`examples/51_goedel2/ex51_goedel2.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `bachEncode`/`bachDecode` | **BACH↦8647201500 素数幂编码**（书 p91 原例；Coq 走二进制 N）+唯一分解回环全表 | C/L |
| `prov`/`provC` | 句子宇宙的 MP 闭包算子（公理+规则表 BFS） | C/L |
| `con_ladder` | **一致性扩张梯子**：T0→+Con→+Con+Con 的 Gödel 句逐层逃逸账 | C/L |
| `con_undeducible` | Con(T0) 本身逃出 T0——Gödel II 的直接陈述 | C/L |
| `d1_shadow` | Hilbert–Bernays D1 可导性条件的机制账 | C/L |
| `sound_shadow` | 三级理论的定理全真（Con 为真句的语义根据） | C/L |

50 章（原 44，算术化与不完备）证明了第一不完备性「是什么」；
这一章进入第二不完备性——**理论证不出自身的一致性**——以及它
的历史现场与哲学回声。Müller-Stach ch 6 用三页（p93-95）给出
了教科书少见的细节：von Neumann 的独立发现、Hilbert 与 Gödel
本人对「纲领是否终结」的双双否定、一致性扩张的迭代、直到
Gödel–Lucas–Penrose 的心智论证与 Davis/Feferman 的反驳。本章
把这些全部提炼成自包含的叙述，机器面承载两个可跑的账本：书
里最可爱的 BACH 编码与一致性扩张梯子。

## 一、BACH↦8647201500：Gödel 编码的素数幂版

书 p91 给出 Gödel 1931 编码方案的教学版：符号编号 A→1、B→2、
…、H→8，一个词编码为**逐位素数幂连乘**——第 i 个字母的编号
作第 i 个素数的指数：

```coq
Fixpoint encAt (i : nat) (l : list N) : N :=
  match l with
  | [] => 1
  | x :: t => (nthPrime i) ^ x * encAt (S i) t
  end.

Definition bachEncode (l : list N) : N := encAt 0 l.
```

书的原例：**BACH ↦ 2²·3¹·5³·7⁸ = 8647201500**：

```coq
Example bach_bach : bachEncode [2; 1; 3; 8] = 8647201500.
Proof. reflexivity. Qed.
```

注意这个数字：86 亿。**Coq 的默认自然数是一元 nat**——86 亿个
S 构造子连内存都装不下。本章第一节全部走**二进制 N**（Stdlib
的 BinNat）：86 亿的二进制乘除是毫秒级。由此撞出本轮的一组
实测坑（CHEATSheet 入账）：`Open Scope N_scope` 之后 **nat 参
数的 match 数字模式 `0` 被劫持为 N 构造子**（改写构造子 O）、
`S e` 的 nat 后继撞上 N（改 `N.succ e`）、nat 字面量表被整体
劫持（分段 `Open Scope nat_scope` 切回）。解码侧用唯一分解：
逐素数剥最大指数（`peel` 找最大 e 使 p^e 整除 n），回环全表
七件样本全部通过（`bach_roundtrip_table`）。

与 49 章平方配对 `cpe` 的对照：**素数幂编码靠算术基本定理保
证单射，平方配对靠二次式保证单射**——两条独立通往 Gödel 编码
的路。49 章选平方配对是因为它在 unary nat 下温和（多项式大小）；
素数幂编码增长更快，但书选它有个教学优点：**每一步剥指数都
在重演唯一分解定理**——编码的可逆性不是设计出来的，是数论
定理的白送。

## 二、Gödel II：从「Q 不可证」到「Con 不可证」

第二不完备性的现代陈述：设 T 是包含算术的一致递归可公理化
理论，则 **T ⊬ Con(T)**，其中 Con(T) 是「T 无矛盾」的算术化
句子——标准写法 ¬Proof(⌜0=1⌝)：「不存在编码为 x 的证明，其
结论是 0=1」。

证明的重读只有一行：50 章的 Gödel 句 Q 满足 **T ⊢ Con(T)→Q**
（Q 说「我不可证」，而「不可证」与「无 0=1 的证明」在一致理
论下等价——Hilbert–Bernays 可导性条件把这个蕴含做成了 T 内
可证的形式命题）。于是若 T ⊢ Con(T)，则 T ⊢ Q——与 Q 不可证
矛盾。

书里的历史现场（p93-94，全部提炼于此）：

- **原稿未含证明**。Gödel 1931 只说「将在续篇给出」；
  von Neumann 1930 年 11 月 20 日的信里**独立发现**了完整的
  第二定理（从 Gödel I 的证明细节直接读出），Gödel 随后自己也
  得到——续篇从未写出，陈述进了 1931 论文、证明由 Hilbert 与
  Bernays 1939 在《Grundlagen der Mathematik》II 里首次完整
  发表（可导性条件 D1–D3 就是他们的形式化脚手架）。
- **Hilbert 不认输**。Hilbert 1934：「我不认为我的纲领已经
  被终结」——出路的思路：用比 T 弱的元理论证 T 的一致性
  （Gentzen 1936 用 PRA+ε₀ 超限归纳证 PA 一致性，55 章的全部
  内容）。Gödel 本人也说第二定理**不**排除有限主义纲领的某
  种复活。
- **扩张迭代**。加 Con(T) 得到真扩张 T′=T+Con(T)——它一致、
  更强、能证出 T 证不出的句子（包括 Con(T) 自己与 Gödel 句
  Q）；但 T′ 有**自己的** Con(T′) 与新的 Gödel 句。Turing
  后来证明：沿这个方向做**超越限迭代**（对每个递归序数 α 加
  Con 的 α 层塔）仍然得不完备的理论——梯子永远差一级。

## 三、一致性扩张梯子：句子宇宙的机器账

机器面把扩张迭代做成**句子宇宙**：九个句子编号，语义（标准
模型真值）预先给定，推理用 MP 规则表，理论=公理集，可证性=
闭包算子：

```coq
Definition TRUTH : list bool :=
  [ false; true; true; true; true; true; true; true; true ].
(* 0=crash「0=1」（假） 1,2=基础公理 3=Con(T0) 4=G(T0)
   5=Con(T1) 6=G(T1) 7=「Con(T0)→G(T0)」 8=「Con(T1)→G(T1)」 *)

Definition mpTable : list (nat * (nat * nat)) :=
  [ (7, (3, 4));      (* Con(T0)→G(T0) 与 Con(T0) 得 G(T0) *)
    (8, (5, 6)) ].    (* Con(T1)→G(T1) 与 Con(T1) 得 G(T1) *)
```

设计的关键是句子 7/8——两条蕴含式「Con→Gödel 句」。它们在
**最弱的理论 T0 里已是公理**：这正是 Hilbert–Bernays D 条件
的宇宙化身（第二定理的蕴含式本身是弱理论可证的）。闭包算子
从公理集出发做 BFS：

```coq
Fixpoint prov (d : nat) (ax : list nat) : list nat :=
  match d with
  | O => ax
  | S d' => mpStep (prov d' ax)
  end.
```

三级理论与梯子账本：

```coq
Definition T0 : list nat := [1; 2; 7; 8].    (* 基础公理+蕴含式 *)
Definition T1 : list nat := [3] ++ T0.       (* +Con(T0) *)
Definition T2 : list nat := [5; 3] ++ T0.    (* +Con(T1)+Con(T0) *)

Example con_ladder :
  [ negb (inN 4 (provC T0))     (* G(T0) 逃出 T0 —— Gödel I *)
  ; inN 4 (provC T1)            (* T0+Con(T0) ⊢ G(T0)：蕴含式点火 *)
  ; negb (inN 6 (provC T1))     (* G(T1) 仍逃出 T1 —— II 再来 *)
  ; inN 6 (provC T2)            (* T1+Con(T1) ⊢ G(T1) *)
  ; conOf T0; conOf T1; conOf T2 ]  (* 三级全一致：加 Con 不塌 *)
  = [true; true; true; true; true; true; true].
Proof. reflexivity. Qed.
```

`Compute` 的三级闭包账一目了然：

```
provC T0 = [1; 2; 7; 8]              （G(T0)=4 逃逸中）
provC T1 = [3; 1; 2; 7; 8; 4]        （4 被收编；G(T1)=6 新逃逸）
provC T2 = [5; 3; 1; 2; 7; 8; 4; 6]  （6 收编；句子宇宙到边界）
```

每级理论：收编上一级的逃逸句（加 Con 让蕴含式点火）、又长出
新的逃逸句（新理论有自己的 Gödel 句）、自身保持一致（crash=0
永不出现）。「**真理之梯永远差一级**」在 9 个句子的宇宙里跑
出完整机制。诚实边界：真实算术的句子无穷、每级都有新 Con；
本宇宙在 T2 处收满——有限影子的墙，与 44 章程序表宇宙同一
纪律。`con_undeducible` 补上直接陈述：Con(T0)=3 本身逃出 T0。

**D1 的机制账**（`d1_shadow`）：可导性条件 D1 说「φ 与 φ→ψ
可证则 ψ 可证」——闭包算子的定义就是它的兑现：3∈prov(T1)、
7∈prov(T1)，于是 4 自动∈prov(T1)。**soundness 影子**
（`sound_shadow`）：三级理论的定理全部为真——T2 的闭包逐位
过 TRUTH 表。这是「Con 为真句」的语义根据：一致的理论（在
标准模型里）证不出假句子，所以 ¬Proof(⌜0=1⌝) 为真——**第二
定理的真值读法：有一个真句子，T 证不出**。与 50 章不完备性
合流。

## 四、Gödel–Lucas–Penrose：心智论证与它的裂缝（文档线）

书 p94-95 给出这段哲学史的紧凑叙述（提炼如下）：

- **Gödel 自己的谨慎**（1951 Gibbs 演讲遗稿）：析取结论——
  「要么人心（甚至纯数学意义上）无限超越任何有限机器，要么
  存在绝对不可解的 diophantine 问题」。Gödel 特意注明**两个
  枝条都是他不愿细说的**，且第二枝并不直接来自第一定理。
- **Lucas 1961 / Penrose 1989-94 的强读**：从「我们看出 Gödel
  句为真而机器证不出」推断「人心非机械」。裂缝在「我们**看出**
  Q 为真」——Q 的真依赖 T 的一致性，而人对 T 一致的把握本身
  无法形式化为 T 内的证明（否则机器同样拥有它）。
- **Davis 与 Feferman 的反驳**：论证需要「人心一致」或「人心
  能认识自身一致」的前提——两者都恰是第二定理禁止的。Müller-
  Stach 的裁决：论证有漏洞，且至今无人补上。
- **Penrose 的赌注**：意识需要量子引力式的非算法物理（波函数
  坍缩）——但脑内维持量子相干的物理条件（温度、退相干时标）
  远比 Penrose 设想的苛刻，目前无证据。
- **Voevodsky 2010 的怀疑**（在 IAS 演讲）：PA 可能不一致、
  我们只是「尚未发现矛盾」；**Nelson**（普林斯顿）后半生试图
 严格证明 PA 不一致——未果而终。这两个事件提示：第二定理的
  「一致性信念」在数学家群体里也不是铁板一块——它最终是经验
  与证明论的合谋（55 章 Gentzen 的 ε₀ 界是最好的安抚）。

## 小结

第二不完备性是第一定理的「自我意识」版本：理论对自身一致
性的无知，恰好等于它对真理的无知。机器面把两个现场结成账
本：BACH↦8647201500（素数幂编码+唯一分解回环，二进制 N 的
必要性本身成了 50 章 unary 撞墙家族的新条目）与九句宇宙的
扩张梯子（逐层收编-逐层逃逸-始终一致）。历史线（von Neumann
的信、Hilbert 的不认输、Turing 的超越限迭代）与哲学线
（Gödel 的析取、Lucas–Penrose 的裂缝、Voevodsky/Nelson 的怀
疑）全部自包含于正文。下一章从「证不出」转向「说不清」——
真理本身：Tarski 的分层与不可定义性、Kripke 的不动点。

---

上一章：[50 哥德尔不完备性：可表示性、算术化与对角化](docs/50-incompleteness.md) · 下一章：[52 真理理论：Tarski 不可定义与 Kripke 不动点](docs/52-truth.md)
