# 第 54 章 截消定理与序数分析

> 对书：张寅生《证明方法与理论》9.7 节根岑自然演绎系统 G 与截消证明
> 方法（p106-113）+13.8 节（p216-221）+13.9 节算术系统的相容性
> （p221-238）+5.3 节超穷归纳法（p68-72）。本章通道：C（`examples/
> 54_cutelim/ex54_cutelim.v`）/ L（`examples/54_cutelim/ex54_cutelim.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `seqSem` | 矢列语义有效性（∧Γ→∨Δ，256 赋值枚举） | C/L |
| `inversion_check` | 反演定理命题侧：八条逻辑规则的语义可逆性账 | C/L |
| `ex915_chain` | 例 9.15 七步矢列链重演（含书中勘误教学点） | C/L |
| `cutDemo`/`cut_sound` | cut 的插入演例：两侧前提有效⟹cut 后矢列有效 | C/L |
| `grade`/`case3_grade_drop` | 级（Grade）与情形 3 主公式分裂的级下降单例 | C/L |
| `cnfLt`/`natSum`/`cutOrd` | CNF 序数+自然和+序数指派 o(P) 的**降序单例** | C/L |
| `tiOn`/`leastCounter` | 超穷归纳 TI 有限影子+良序最小元反证账 | C/L |
| `ladder` | 83 层相容性层级表（12 层节选） | C/L |

06 章讲矢列演算时留了一句「cut 消去定理（Hauptsatz）本教程不机器
化」；51 章造好了 ε₀ 的序数机器却只用在 Goodstein 定理上。本章把
这两条线接通：**cut 的消去如何一步步执行，消去的每步为什么在下降，
下降的度量为什么恰好是 ε₀ 以内的序数，以及这一切如何换来「PA 相
容」**——Hilbert 纲领最接近成功的一次冲刺（Gentzen 1936）。

## 一、矢列演算 G 的第二系统

根岑 1932-35 年的双重发明里，第二系统（书 9.7 节式 9.19-9.30）是
**矢列**（sequent）间的推理：Γ⊢Δ 读作「Γ 的合取蕴涵 Δ 的析取」（书
p111 的约定）。十二条规则分两类：结构规则（弱化/凝缩/交换）与逻辑
规则（∧∨¬→ 的左右引入）。机器面先立语义标尺：

```coq
Definition gseq : Type := list gform * list gform.   (* Γ ⊢ Δ *)

Definition seqSem (s : gseq) : bool :=
  forallb (fun asg => implb (allEv (fst s) asg) (anyEv (snd s) asg))
    (seq 0 256).
```

**反演定理**（书定理 9.1）：除弱化外，规则皆可逆——底部矢列有效当
且仅当顶部矢列有效。命题侧的机器验证：

```coq
Definition invPairs : list (gseq * gseq) :=
  [ (([GAnd (GVar 0) (GVar 1)], []), ([GVar 0], []))   (* ∧L *)
  ; (([], [GAnd (GVar 0) (GVar 1)]), ([], [GVar 0; GVar 1]))  (* ∧R *)
  ; ...                                                (* 八条代表 *) ].

Example inversion_check :
  forallb (fun p => Bool.eqb (seqSem (fst p)) (seqSem (snd p))) invPairs
  = true.
```

每条逻辑规则的「上矢列/下矢列」对在全部赋值下同真假——规则不只是
**保真**，而且**不增不减**。这正是矢列演算优于 Hilbert 系统的结构性
质：分析性（analyticity）的萌芽——推理不生产新信息，只拆解公式。

书中例 9.15（p112）在 G 中证明 ⊢¬(P∧Q)→¬P∨¬Q，七步链重演：

```coq
Definition ex915_chain : list (gseq * nat) :=
  [ (([GVar 0], [GVar 0]), 1)                                (* P⊢P *)
  ; (([GVar 0], [GVar 0; GNeg (GVar 1)]), 2)                 (* 弱化右 *)
  ; ...
  ; (([GNeg (GVar 1); GAnd (GVar 0) (GVar 1)], [GVar 0]), 6) (* ∧左引入 *)
  ; (([GAnd (GVar 0) (GVar 1)], [GVar 0; GNeg (GVar 1)]), 7) (* ¬右引入 *)
  ].

Example ex915_steps_valid : forallb (fun st => seqSem (fst st)) ex915_chain
  = true.
```

书里第六步原文标「∧右引入」而公式形状是∧**左**引入——张书自己加了
脚注勘误。这个勘误是绝佳的教学点：**规则名与公式形状必须对榫**——
右侧引入的主公式出现在矢列右端，左侧引入出现在左端；机器件按形状
而不是按名字核对（`ex915_chain` 的第六步主公式 P∧Q 在左端）。

## 二、cut：引理的调用与展开

结构规则的第四条是本章的主角——**截消规则**（cut，式 9.22）：

```
Γ ⊢ Θ, D      D, Δ ⊢ Λ
────────────────────── (cut)
     Γ, Δ ⊢ Θ, Λ
```

书定义 9.10 给出截消证明方法的本质结构：`(A⊢L)&(A,L⊢T)⟹(A⊢T)`
——**cut 就是引理 L 的调用**；cut 消去就是把引理展开回原地去掉调用。
机器演例：

```coq
Definition cutDemo : gseq :=
  cutApply ([GVar 0], [GOr (GVar 0) (GVar 0)])      (* p ⊢ p∨p *)
           ([GOr (GVar 0) (GVar 0)], [GVar 0])      (* p∨p ⊢ p *)
           (GOr (GVar 0) (GVar 0)).

Example cut_sound : [ ...; ...; seqSem cutDemo ] = [true; true; true].
```

两侧前提有效则 cut 后矢列有效——cut 的**语义可靠性**无懈可击。问题
在句法侧：cut 让证明可以「走捷径」（引用任意已证引理），破坏了分析
性——引理 D 的内部结构可能与结论无关。Gentzen 的 Hauptsatz 断言：
**每条 G 中的证明都可以改写成不用 cut 的证明**。

消去怎么执行？书 13.9 节（p226-230）给出情形分析。核心是**双重归
纳**：对 cut 公式的**级**（grade）与证明的**秩**（rank）做归纳。级
的定义（定义 13.26）：

```coq
Fixpoint grade (f : gform) : nat :=
  match f with
  | GVar _ => 1
  | GImp a b | GAnd a b | GOr a b => Nat.max (S (grade a)) (S (grade b))
  | GNeg a => S (grade a)
  end.
```

**情形 3**（主公式 A→B 的关键情形）：上矢列以 →右引入产生
Θ,A→B、下矢列以 →左引入消费它。消去时把这个 cut **分裂**成两个
更小的 cut（对 A 与对 B），级的账：

```coq
Example case3_grade_drop :
  Nat.ltb (Nat.max (grade (GVar 0)) (grade (GImp (GVar 1) (GVar 2))))
          (grade m3) = true.      (* m3=(p→q)→r：级 3 → 子公式级 ≤2 *)
```

书中的完整证明是情形 1a 到 13b 的全分类（预备情形=弱化/凝缩吸附；
rank=2 的六个主公式情形；rank>2 的秩下降情形）——Hauptsatz 的机械
全貌记文档线：**每一步变换要么级降、要么同级秩降、要么秩同级升但
结构简化**，三参数字典序保证终止。

## 三、序数指派：下降的度量

消去过程「显然在下降」——但下降的度量是什么？Gentzen 1936 年的答案
（书定理 13.7）：给每条证明 P 指派一个 **<ε₀ 的序数** o(P)，使每次
消去步骤严格下降。机器面用 51 章 CNF 序数树的最小版：

```coq
(* <ω^ω 的 CNF：低位在前。[2;0;0;1] = ω³+2 *)
Definition cnfAdd1 (c : list nat) : list nat := ...   (* +1 *)
Fixpoint natSum (a b : list nat) : list nat :=        (* 自然和 #：逐位 max *)
```

**自然和**（natural sum，#）是降序定理的关键运算：普通序数和不交
换（1+ω=ω≠ω+1），自然和对齐指数取 max、可交换——它允许「部分项下
降但总和仍降」的账目。指派规则的骨架：

```coq
(* 初始矢列 o=1；弱化不变；逻辑推理 o=子证明+1；
   cut 处 o = ω^(级差) # 两侧 *)
Definition cutOrd : list nat :=
  natSum [0;0;0;1] (natSum (ordLogical [1]) (ordLogical [1])).  (* ω³+2 *)
Definition cutfreeOrd : list nat :=
  ordLogical (natSum [1] [2]).                                  (* 3 *)

Example descent_check : cnfLt cutfreeOrd cutOrd = true.          (* 3 < ω³+2 *)
```

消去后序数从 ω³+2 掉到 3——**跨指数层下降**。Gentzen 定理 13.7 的
一般形式：有 cut 的证明 P 消去一步后 o(P′)<o(P)。序数不会无穷下降
（良序！），所以消去终止——Hauptsatz 得证。

## 四、超穷归纳与 PA 相容性

「<ε₀ 的序数不无穷下降」本身就是一条**超穷归纳**（TI）——书 5.3 节
定义 5.4：

> (Φ(0) ∧ ∀a<b (Φ(a)→Φ(b))) → ∀x Φ(x)

定理 5.3 的证明用**良序最小元反证**：若有反例，反例集有最小元 x₀，
但 Φ(0) 与步进在 x₀ 前处成立推出 Φ(x₀)——矛盾。机器件的有限影子：

```coq
Example ti_finite :
  forallb (fun n => implb (tiOn p n) (holdsUpto p n)) (seq 0 8) = true.

Example least_counter_exists : ...   (* 反例存在 ⟹ 最小反例存在 *)
```

**Gentzen 相容性证明的完整弧线**（书 13.9，p223-232）：PA 相容 ⟺
空矢列 → 不可证；→ 只能由 cut+凝缩产生；Hauptsatz 说一切证明可无
cut 化；cut 消去的终止性由 <ε₀ 的 TI 担保；而 **<ε₀ 的 TI 恰好不
能在 PA 内证明**（否则违反 Gödel II——49 章）——所以 Gentzen 的证
明「超越」了 PA 一个序数量级，却仍是**有穷主义可接受**的（定理 13.4：
<ε₀ 的超穷归纳可归约为原始递归的串值归纳）。相容性买了回来，代价
是一张明确的序数账单。四版证明史（1934 撤销/1936 <ε₀/1938/1943）+
Ackermann 1940+Novikov 1943+Gödel 1941 的 HA≡PA（负翻译——49 章
的 DPA⟺HA）——1930 年代的证明论在这一个定理上汇聚。

## 五、相容性层级：83 层的天梯

书 13.9.2（附录 1）列出哥德尔整理的 **83 层相容性链**。机器件收
12 层节选：

```coq
Definition ladder : list nat := [1;2;3;4;5;6;7;8;9;10;11;12].
(* EFA < PRA < RCA₀ < WKL₀ < IΣ₁ < PA < ACA₀ < ATR₀ < Π¹₁-CA₀
   < Z₂ < ZFC < 不可达基数…… *)
```

读法：**每层的相容性由上一层的超穷归纳担保**。Gentzen 把 PA（第 6
层）的相容性押在 ε₀ 的序数分析上；逆数学（RCA₀/WKL₀ 的层级——
52 章的 PH 与 R(3,3) 已在 RCA₀ 的地界活动）把「定理回到公理」的
距离也做成了同样的刻度。链的尽头没有「绝对相容」——Gödel II 在每
一层都生效（49 章）。这张天梯是 Hilbert 纲领的墓志铭，也是它最成
功的遗产：**我们买不到绝对的相容，但可以给每一层标价**。

## 小结

本章把 06 章的矢列演算推进到它的证明论核心：反演定理（规则不增不
减）、cut 即引理（调用与展开）、级与秩的双重归纳（情形 3 的分裂
账）、序数指派（下降的度量——自然和与 ω 指数）、超穷归纳（终止性
的来源）、相容性层级（Gentzen 遗产的全景）。下一章（55 章）回到算
术的模型侧；而 cut 消去的另一支血脉——结构证明论与 Curry–Howard
的「规范化=消去」——已在 13 章留下伏笔，在类型论指南里全面展开。

---

上一章：[53 PA 与 ε₀](docs/53-epsilon.md) · 下一章：[55 算术的模型](docs/55-models.md)
