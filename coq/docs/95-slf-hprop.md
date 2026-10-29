# 95 · 堆谓词：分离逻辑的地基

对应示例：`../examples/95_slf_hprop.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

从本章起进入**实现者视角**：前两章当用户使用的 `\[]`、`\[P]`、`p ~~> v`、
`\*`、`\exists`，现在一个个拆开，从「内存的数学模型」开始重建。本章的目标
是原书 Hprop 章的核心：定义 `heap` 与 `hprop`，给出五大堆谓词组合子的**浅嵌
入**（shallow embedding——直接用 Rocq 的谓词定义，不另造语法树），证明星号的
交换律、结合律、单位元律等基本定律，并交代需要补充的两条**外延公理**。全程
只有纯粹的数学定义与证明，没有程序、没有 x-tactics——这是后面七章的逻辑地
基。

文件头照旧（本章用不到演示程序，只导 `ProgramSyntax`）：

```coq
(* 95 堆谓词 —— heap/hprop、\[] 与 \[P]、~~>、\*、hexists、外延公理与基本定律 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Hprop 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax.

Implicit Types n m : int.
Implicit Types p q : loc.
```

注意：本章在同一名空间里**重新定义**了库里已有的名字（`hprop`、`hstar`
等）——后定义遮蔽先定义，这正是原书的写法：每一章从零重建一部分框架，又不必
甩开库的其他设施。

### 95.1 状态的数学模型：heap 与 fmap

```coq
(* ---------- 95.1 状态的数学模型：heap 与 fmap ---------- *)

Definition heap : Type := fmap loc val.

Notation "h1 \u h2" := (Fmap.union h1 h2) (at level 37, right associativity).
```

一块内存 = 从位置到值的**有限映射**。库文件 `LibSepFmap`（48 章 `total_map`
的自包含版）提供四个关键操作：

- `Fmap.empty : heap`——空映射；
- `Fmap.single p v : heap`——只含一格 `p ↦ v` 的映射；
- `Fmap.union h1 h2 : heap`——并（只在两映射**定义域不相交**时行为良好）；
- `Fmap.disjoint h1 h2 : Prop`——定义域不相交。

`h1 \u h2` 是并的记号。本章证明里反复用到的有限映射引理（都来自库）：
`Fmap.union_empty_l`（空并恒等）、`Fmap.union_comm_of_disjoint`（不相交则并
可交换）、`Fmap.union_assoc`（并可结合）、`Fmap.disjoint_union_eq_l/r`（「与
并不相交」当且仅当「与两块都不相交」）。

### 95.2 堆谓词与五大组合子

```coq
(* ---------- 95.2 堆谓词与五大组合子 ---------- *)

Definition hprop : Type := heap -> Prop.

Implicit Type H : hprop.
```

**堆谓词就是「内存的谓词」**——`hprop := heap -> Prop`。全篇约定：`H` 是堆
谓词，`Q : val -> hprop` 是后条件（下一节）。五个基本组合子，每个都是一行定
义：

```coq
Definition hempty : hprop :=
  fun (h:heap) => (h = Fmap.empty).

Notation "\[]" := (hempty) (at level 0).

Definition hpure (P:Prop) : hprop :=
  fun (h:heap) => (h = Fmap.empty) /\ P.

Notation "\[ P ]" := (hpure P) (at level 0, format "\[ P ]").

Definition hsingle (p:loc) (v:val) : hprop :=
  fun (h:heap) => (h = Fmap.single p v).

Notation "p '~~>' v" := (hsingle p v) (at level 32).

Definition hstar (H1 H2 : hprop) : hprop :=
  fun (h:heap) => exists h1 h2, H1 h1
                             /\ H2 h2
                             /\ Fmap.disjoint h1 h2
                             /\ h = h1 \u h2.

Notation "H1 '\*' H2" := (hstar H1 H2) (at level 41, right associativity).

Definition hexists (A:Type) (J:A->hprop) : hprop :=
  fun (h:heap) => exists x, J x h.

Notation "'\exists' x1 .. xn , H" :=
  (hexists (fun x1 => .. (hexists (fun xn => H)) ..))
  (at level 39, x1 binder, H at level 50, right associativity,
   format "'[' '\exists' '/ '  x1  ..  xn , '/ '  H ']'").
```

逐个读它们的「语义」：

- `\[]`：只被**空映射**满足——描述「空的一块内存」；
- `\[P]`：空映射**且**命题 `P` 成立——把纯逻辑事实注入堆谓词世界；
- `p ~~> v`：只被单格映射满足——「`p` 处恰有一格，内容 `v`」；
- `H1 \* H2`（**分离合取**）：`h` 能切成**不相交**的 `h1` 与 `h2`，分别满足
  `H1`、`H2`，且拼回原样。「不相交」三个字就是整个分离逻辑的力量来源——
  93 章讲的「别名不可能」、框架规则的「无关资源原样保留」，全部从这里生长；
- `\exists x, J x`：堆谓词版存在量词——与 `exists` 的区别在于**见证可以依赖
  当前堆**（分配操作返回什么地址，要看当时堆的情况）。

值得停下来体会的是**浅嵌入**的选择：我们不为堆谓词造一套语法树（深嵌入），
而是直接用 Rocq 的函数与量词。好处：`/\`、`exists`、`=` 等全部逻辑设施直接
可用，证明短；代价：想做「语法上的归纳」（比如遍历谓词结构做自动化）要另想
办法——101 章的 WP 生成器正是在这两种需求间做取舍。

### 95.3 外延公理：两个谓词何时「相等」

定义完算子，马上遇到一个技术问题：怎么证 `H1 = H2`？两个函数在 Rocq 里默认
**外延不透明**——`H1 h <-> H2 h` 对所有 `h` 成立，推不出 `H1 = H2`。解法是补
一条标准公理：

```coq
(* ---------- 95.3 外延公理：hprop 的相等判定 ---------- *)

Axiom predicate_extensionality : forall (A:Type) (P Q:A->Prop),
  (forall x, P x <-> Q x) ->
  P = Q.

Lemma hprop_eq : forall (H1 H2:hprop),
  (forall (h:heap), H1 h <-> H2 h) ->
  H1 = H2.
Proof using. apply predicate_extensionality. Qed.
```

**谓词外延公理**：「逐点等价则相等」。`hprop_eq` 是它在 `hprop` 上的特化，
此后证谓词等式的套路固定为 `apply hprop_eq. split.`（两个方向的蕴含各证一
遍）。这条公理（连同函数外延）是经典数学里「显然成立」的那类命题，主流证明
助手社区普遍接受它；95.8 节再看它与其他公理的关系。

### 95.4 后条件与 \*+ 记号

```coq
(* ---------- 95.4 后条件与 \*+ 记号 ---------- *)

Implicit Type Q : val -> hprop.

Notation "Q \*+ H" := (fun x => hstar (Q x) H) (at level 40).

Axiom functional_extensionality : forall A B (f g:A->B),
  (forall x, f x = g x) ->
  f = g.

Lemma qprop_eq : forall (Q1 Q2:val->hprop),
  (forall (v:val), Q1 v = Q2 v) ->
  Q1 = Q2.
Proof using. apply functional_extensionality. Qed.
```

后条件类型是 `val -> hprop`（返回值 + 终态一起描述）。`Q \*+ H` 读作「给后
条件整体添一块资源」：`(Q \*+ H) x = Q x \* H`——98 章框架规则的陈述全靠它。
后条件的相等需要**函数外延公理**，配套引理 `qprop_eq` 与 `hprop_eq` 同款用
法。

### 95.5 基本算子的引入与反转引理

组合子的定义一摊开，配套的「使用说明」就是一组**引入引理**（怎么证 `H h`）
与**反转引理**（从 `H h` 里能挖出什么）。它们在后续章节里无处不在：

```coq
(* ---------- 95.5 基本算子的引入与反转引理 ---------- *)

Implicit Types P : Prop.
Implicit Types v : val.

Lemma hempty_intro :
  \[] Fmap.empty.
Proof using.
  hnf. auto.
Qed.

Lemma hpure_intro : forall P,
  P ->
  \[P] Fmap.empty.
Proof using. introv M. hnf. auto. Qed.

Lemma hsingle_intro : forall p v,
  (p ~~> v) (Fmap.single p v).
Proof using. intros. hnf. auto. Qed.

Lemma hstar_intro : forall H1 H2 h1 h2,
  H1 h1 ->
  H2 h2 ->
  Fmap.disjoint h1 h2 ->
  (H1 \* H2) (h1 \u h2).
Proof using. intros. exists* h1 h2. Qed.

Lemma hexists_intro : forall A (x:A) (J:A->hprop) h,
  J x h ->
  (\exists x, J x) h.
Proof using. introv M. hnf. eauto. Qed.
```

证明大多一行：`hnf`（head normal form）把记号下的定义展开一层，剩下的交给
`auto`/`eauto`（`exists*` 是 TLC 的「提供全部存在见证」）。反转方向：

```coq
Lemma hempty_inv : forall h,
  \[] h ->
  h = Fmap.empty.
Proof using. introv M. hnf in M. auto. Qed.

Lemma hpure_inv : forall P h,
  \[P] h ->
  P /\ h = Fmap.empty.
Proof using. introv M. hnf in M. autos*. Qed.

Lemma hsingle_inv: forall p v h,
  (p ~~> v) h ->
  h = Fmap.single p v.
Proof using. introv M. hnf in M. auto. Qed.

Lemma hstar_inv : forall H1 H2 h,
  (H1 \* H2) h ->
  exists h1 h2, H1 h1 /\ H2 h2 /\ Fmap.disjoint h1 h2 /\ h = h1 \u h2.
Proof using. introv M. hnf in M. eauto. Qed.

Lemma hexists_inv : forall A (J:A->hprop) h,
  (\exists x, J x) h ->
  exists x, J x h.
Proof using. introv M. hnf in M. eauto. Qed.
```

`hnf in M` 在假设里展开。注意 `hstar_inv` 把星号的四要素（两块、各满足、不
相交、拼回）整体交出来——它是「星号里藏着不相交」这句话的形式化版本。

### 95.6 分离合取的基本定律

星号该有的代数性质——结合律、交换律、单位元、量词与纯事实的「挤出律」——现
在逐条证明。为避免与库里的同名引理冲突，包进模块：

```coq
(* ---------- 95.6 分离合取的基本定律（含练习解答） ---------- *)

Module HpropProofs.

Lemma hstar_hexists : forall A (J:A->hprop) H,
  (\exists x, J x) \* H = \exists x, (J x \* H).
Proof using.
  intros. apply hprop_eq. split.
  { intros (h1&h2&M1&M2&D&U). destruct M1 as (x&M1). exists* x h1 h2. }
  { intros (x&M). destruct M as (h1&h2&M1&M2&D&U). exists h1 h2.
    splits~. exists* x. }
Qed.
```

第一条定律：**存在量词可以移出星号**。两个方向的证明结构相同——「外延拆
 iff、按 `hstar_inv` 的形状 intro（`(h1&h2&M1&M2&D&U)` 一次拆完）、重新组
装见证」。这些 intro 模式是本章的肌肉记忆。

**练习（3 星）hstar_hempty_l**：空谓词是星号的左单位元：

```coq
(* 练习（3 星）：空谓词是 \* 的单位元。用到 Fmap.union_empty_l。 *)

Lemma hstar_hempty_l : forall H,
  \[] \* H = H.
Proof using.
  intros. apply hprop_eq. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. subst h1.
    rewrite Fmap.union_empty_l in U. subst. auto. }
  { intros M. hnf. exists (Fmap.empty:heap) h. splits~.
    { hnf. auto. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.
```

左到右：`hnf in M1` 得 `h1 = empty`，代换后 `U : h = empty ∪ h2`，用
`Fmap.union_empty_l` 化成 `h = h2` 收场。右到左：给出见证
`(Fmap.empty, h)`——实测两处小坑：`split` 之后目标里的 `h` **已被自动引
入**（再 `intros h` 报「h is already used」）；`exists` 里的 `Fmap.empty` 要
写 `(Fmap.empty:heap)` 标注类型，否则隐式类型参数推不出。

交换律借助一个「二元算子通用对称化」引理，只需证单向：

```coq
Lemma hprop_op_comm : forall (op:hprop->hprop->hprop),
  (forall H1 H2 h, op H1 H2 h -> op H2 H1 h) ->
  (forall H1 H2, op H1 H2 = op H2 H1).
Proof using. introv M. intros. apply hprop_eq. split; apply M. Qed.

Lemma hstar_comm : forall H1 H2,
   H1 \* H2 = H2 \* H1.
Proof using.
  (* Exploit symmetry. *)
  apply hprop_op_comm.
  (* Unfold the definition of [star]. *)
  introv (h1&h2&M1&M2&D&U).
  exists h2 h1. subst. splits~.
  (* Exploit commutativity of disjoint union *)
  { rewrite Fmap.union_comm_of_disjoint; auto. }
Qed.
```

星号交换的全部实质是**不相交的并可以交换**（`Fmap.union_comm_of_disjoint`）
——「切两块」的次序本就无关紧要。

**练习（1 星，选做）hstar_assoc**：结合律。原书给了左到右，补全另一半：

```coq
(* 练习（1 星，选做）：补全结合律的另一半（右到左）。 *)

Lemma hstar_assoc : forall H1 H2 H3,
  (H1 \* H2) \* H3 = H1 \* (H2 \* H3).
Proof using.
  intros. apply hprop_eq. split.
  { intros (h'&h3&M1&M2&D&U). destruct M1 as (h1&h2&M3&M4&D'&U').
    subst h'. rewrite Fmap.disjoint_union_eq_l in D.
    exists h1 (h2 \u h3). splits.
    { apply M3. }
    { exists* h2 h3. }
    { rewrite* @Fmap.disjoint_union_eq_r. }
    { rewrite* @Fmap.union_assoc in U. } }
  { intros (h1&h23&M1&M2&D&U). destruct M2 as (h2&h3&M3&M4&D'&U').
    subst h23. rewrite Fmap.disjoint_union_eq_r in D.
    exists (h1 \u h2) h3. splits.
    { exists* h1 h2. }
    { apply M4. }
    { rewrite* @Fmap.disjoint_union_eq_l. }
    { rewrite* <- @Fmap.union_assoc in U. } }
Qed.
```

右到左是左到右的镜像：拆开重组 `(h1, h2 ∪ h3)`，三个子目标分别是「左边那
块」「右边那块重组」「不相交关系搬移」；最后一个子目标实测要 `rewrite <-`
（目标里的结合形状与 `union_assoc` 的方向相反）。右单位元由交换律白拿：

```coq
Lemma hstar_hempty_r : forall H,
  H \* \[] = H.
Proof using.
  intros. rewrite hstar_comm. rewrite hstar_hempty_l. auto.
Qed.
```

**练习（1 星）hstar_comm_assoc**：交换 + 结合的合体：

```coq
(* 练习（1 星）：交换律与结合律的合体。 *)

Lemma hstar_comm_assoc : forall H1 H2 H3,
  H1 \* H2 \* H3 = H2 \* H1 \* H3.
Proof using.
  intros. rewrite <- hstar_assoc. rewrite (hstar_comm H1 H2).
  rewrite hstar_assoc. auto.
Qed.
```

三步换位：先按**逆向**结合律把 `H1 \* (H2 \* H3)` 拢成 `(H1 \* H2) \* H3`
（注意 `\*` 是右结合记号，直接正向 `rewrite hstar_assoc` 找不到匹配模式——实
测踩过的坑），交换前两块，再正向松回去。

本章最难的一条（4 星）——**纯事实挤出律**：

```coq
(* 练习（4 星）：从星号里抽出纯事实。
   逐点相等（对每个 h 是 Prop 等价），所以先用命题外延公理。 *)

Lemma hstar_hpure_l : forall P H h,
  (\[P] \* H) h = (P /\ H h).
Proof using.
  intros. apply propositional_extensionality. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. destruct M1 as (E1&P').
    subst h1. rewrite Fmap.union_empty_l in U. subst h. splits*. }
  { intros (P'&M). hnf. exists (Fmap.empty:heap) h. splits*.
    { hnf. splits*. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.
```

微妙之处在**命题的类型**：结论 `(\[P] \* H) h = (P /\ H h)` 两边是
`Prop`（对**固定**的 `h`），不是 `hprop`——所以第一步不是 `hprop_eq` 而是
**命题外延公理**（`P <-> Q` 推 `P = Q`，95.8 节正式引入；这里直接从库拿）。
左到右：`\[P]` 那块必然是空映射，并恒等消去；右到左：反向拼装，见证
`(Fmap.empty, h)`。

```coq
End HpropProofs.
```

### 95.7 等价的另类定义（选读）

五个组合子并非全都「独立」——两条等式说明可以再省：

```coq
(* ---------- 95.7 等价的另类定义（选读） ---------- *)

Lemma hempty_eq_hpure_true :
  \[] = \[True].
Proof using.
  unfold hempty, hpure. apply hprop_eq. intros h. iff Hh.
  { auto. }
  { destruct Hh. auto. }
Qed.

Definition hempty' : hprop :=
  \[True].

Lemma hpure_eq_hexists_proof : forall P,
  \[P] = (\exists (p:P), \[]).
Proof using.
  unfold hempty, hpure, hexists. intros P.
  apply hprop_eq. intros h. iff Hh.
  { destruct Hh as (E&p). exists p. auto. }
  { destruct Hh as (p&E). auto. }
Qed.

Definition hpure' (P:Prop) : hprop :=
  \exists (p:P), \[].
```

`\[]` 等价 `\[True]`（空谓词就是「平凡事实」）；`\[P]` 等价
`\exists (p:P), \[]`——纯事实是「对 `P` 的证明做堆上存在量化」（证明不占内
存）。组合子越少、理论越精炼：**后续章节将采用 `hpure'` 的定义**，让
`hpure` 成为 `hexists` 与 `hempty` 的导出概念。

### 95.8 外延公理的推导（选读）

```coq
(* ---------- 95.8 外延公理的推导（选读） ---------- *)

Module Extensionality.

Axiom propositional_extensionality : forall (P Q:Prop),
  (P <-> Q) ->
  P = Q.

Axiom functional_extensionality : forall A B (f g:A->B),
  (forall x, f x = g x) ->
  f = g.

(* 练习（1 星）：用上面两条公理推出谓词外延公理。 *)

Lemma predicate_extensionality_derived : forall A (P Q:A->Prop),
  (forall x, P x <-> Q x) ->
  P = Q.
Proof using.
  intros A P Q H. apply functional_extensionality. intros x.
  apply propositional_extensionality. apply H.
Qed.

End Extensionality.
```

**练习（1 星）**：三条外延公理不独立——谓词外延 = 函数外延 + 命题外延。证
明两行：先按函数外延把 `P = Q` 化成逐点相等 `P x = Q x`，再按命题外延把相等
化成等价 `P x <-> Q x`，正是假设。这个模块正式给出了 95.3 用到的
`propositional_extensionality` 的身份。

### 95.9 本章小结

**概念**：

- `heap := fmap loc val`（有限映射）+ 并/单格/不相交四件套；
- `hprop := heap -> Prop`，五大组合子：`\[]`、`\[P]`、`p ~~> v`、`H1 \* H2`
  （核心：切两块 + 不相交 + 拼回）、`\exists x, J x`（见证可依赖堆）；
- 浅嵌入 vs 深嵌入的取舍；
- 外延公理三件套（谓词/函数/命题）及互相推导；`hprop_eq`、`qprop_eq` 是证
  谓词等式的标准入口；
- 引入/反转引理：星号的四要素拆装（`(h1&h2&M1&M2&D&U)` 模式）；
- 星号代数：交换律（实质是不相交并可交换）、结合律、`\[]` 单位元、量词与纯
  事实的挤出律；`\*+` 给后条件整体加资源。

**实测坑位**：

- `apply hprop_eq. split.` 之后 `h` 已被自动引入，`intros h` 会报「already
  used」；
- `exists Fmap.empty ...` 要写 `(Fmap.empty:heap)` 消除隐式类型歧义；
- `\*` 与 `\u` 都是**右结合**记号，`rewrite hstar_assoc`/`union_assoc` 的方
  向要按目标的结合形状选正反（找匹配模式的是引理的**左边**）；
- 逐点（固定 `h`）的 Prop 等式用命题外延，谓词整体的等式用谓词外延——类型
  不同别混用。

下一章（96）定义堆谓词之间的**蕴含关系** `==>` 并证明它的定律——那正是
`xsimpl` 背后的理论。
