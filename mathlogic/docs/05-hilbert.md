# 05 Hilbert 系统与演绎定理

> 对书：Mendelson §1.4 / Ben-Ari 3e §3.3 / H&R §1.4.3-1.4.4（可靠完备对照）
> 通道：C/A/L/I/H4（深浅嵌入对照点）

03 章的自然演绎「好用」：每条规则对应一个证明构造动作。本章的
Hilbert 系统反着来：**公理一大堆、规则只有一条**，写证明像在
针尖上跳舞——但它换来的东西无可替代：**元定理好证**。演绎定理
（「Γ,p ⊢ q ⟹ Γ ⊢ p→q」）在 ND 里是设计内建的规则（→i），
在 Hilbert 系统里是一个需要证明的**元定理**，而这个证明是全书
「对推导结构做归纳」这一机器证法的范本。

## 系统 L：三条公理 + 一条规则

Mendelson 的系统 L（命题层）：

```text
A1  p → (q → p)
A2  (p → (q → r)) → ((p → q) → (p → r))
A3  (¬q → ¬p) → (p → q)
MP  从 p → q 与 p 得 q
```

读这三条公理的最好视角是**组合子**（12 章 Curry–Howard 会正式
展开）：A1 是 K 组合子（`fun x y => x`：丢弃第二个参数），
A2 是 S 组合子（`fun f g x => f x (g x)`：把参数复制一份分头喂）。
直觉主义逻辑只需要 A1/A2 两条；A3 是经典部分——倒逆否形态
「(¬q→¬p) → (p→q)」自带双否消去的气息，它就是 04 章矩阵
在 Hilbert 世界的代表。

为什么 Hilbert 系统「难用」？想证 `p → p` 试试——没有 →i 可用，
只能用 A1/A2 拼五步（下文 identity 现场）。为什么「好证元定理」？
因为推导的形态只有三种：是假设、是公理、是 MP 一步。**对推导
归纳只有三个分支**——元理论的全部内容。

## 演算作为数据：推导关系归纳定义

机器化 Hilbert 系统的手法与 02 章一脉相承：公式是归纳类型，
**推导也是归纳类型**（`examples/05_hilbert/ex05_hilbert.v`）：

```coq
Inductive hform : Type :=
| HVar : nat -> hform
| HImp : hform -> hform -> hform
| HNeg : hform -> hform.

Definition isAxiom (A : hform) : Prop :=
  (exists p q, A = HImp p (HImp q p))
  \/ (exists p q r, A = HImp (HImp p (HImp q r))
                             (HImp (HImp p q) (HImp p r)))
  \/ (exists p q, A = HImp (HImp (HNeg q) (HNeg p)) (HImp p q)).

Inductive derives (G : list hform) : hform -> Prop :=
| dHyp : forall A, In A G -> derives G A
| dAx  : forall A, isAxiom A -> derives G A
| dMP  : forall p A, derives G (HImp p A) -> derives G p -> derives G A.
```

三个构造子对应推导的三种形态：`dHyp` 假设引用、`dAx` 公理
实例（`isAxiom` 把「公理模式」定义成谓词——模式=存在一组
子公式使等式成立）、`dMP` 规则应用。注意 `derives G A` 的
**读法**：「在假设集 G 下可推 A」——它不是命题 A 的证据，
而是一棵**推导树**的类型。每个 Hilbert 证明都是这棵树的
一个具体居民。

## 热身两件套：weak_K 与 identity

**弱化引理**（weak_K）：「推得出 A，就推得出 B→A」——A1 +
MP 一步。它是演绎定理的公理分支的全部内容：

```coq
Lemma weak_K : forall G A B, derives G A -> derives G (HImp B A).
Proof.
  intros G A B H. eapply dMP.
  - apply dAx. left. exists A, B. reflexivity.
  - exact H.
Qed.
```

**identity**：`p → p` 的五步拼装。这是 Hilbert 系统「难用」的
标准展品，也是组合子代数 I = S K K 的命题版：

```coq
Lemma identity : forall G p, derives G (HImp p p).
```

推导的文本形态（s1–s5 五步）：

```text
s1 = A1 p (p→p)            p → ((p→p) → p)
s2 = A2 p (p→p) p          (p→((p→p)→p)) → ((p→(p→p)) → (p→p))
s3 = MP s2 s1              (p→(p→p)) → (p→p)
s4 = A1 p p                p → (p→p)
s5 = MP s3 s4              p → p
```

读法：A2 把「p 对 (p→p) 的 K」拆成「p 对 p 的 K」的组合；
两次 MP 把三段链成恒等。组合子视角：`S K K x = K x (K x) = x`——
命题版的同一笔账。一个关键工程细节：identity 必须对**任意上下文
G** 成立（不只是空上下文），因为演绎定理的假设分支要在「p::G
里的旧假设」上用它。

## 演绎定理：对推导结构归纳

**定理**（deduction theorem）：`derives (p :: Γ) q → derives Γ (p → q)`。
直觉：把「用到假设 p 的推导」改写成「不用 p 但结论多扛一个
p→」的推导。这是把 ND 的 →i **事后补票**进 Hilbert 系统的定理。

证明对推导归纳，三分支（`ex05_hilbert.v` 的 `deduction`）：

- **dHyp 分支**（用到的假设）：若 q 就是 p 自己，输出
  `identity`（p→p 的五步）；若 q 是 Γ 里的旧假设，`weak_K`
  一步弱化——「原来的假设引用变成公理式弱化」。
- **dAx 分支**（公理）：公理无所谓上下文，`weak_K` 白送。
- **dMP 分支**（规则步，全场唯一有内容的）：归纳假设给出
  `Γ ⊢ p→(r→A)`（IH₁）与 `Γ ⊢ p→r`（IH₂），要 `Γ ⊢ p→A`。
  A2 恰好是「柯里化分配」：

```text
A2 实例： (p → (r → A)) → ((p → r) → (p → A))
MP 吃 IH₁ 得： (p → r) → (p → A)
MP 吃 IH₂ 得： p → A
```

机器证明里这三步是 `assert s2 / assert t1 / eapply dMP` 的接力。
**A2 的存在意义这一刻才显形**：它是「MP 在 → 前件下封闭」的
公理化表述——没有它，演绎定理的 MP 分支无从下手。

## 演绎定理省三页纸

同一文件的 Example 给出对照：「`X → X` 形公理实例」用演绎
定理两步收（假设引用+升格），不用则要手工铺 A1/A2 的 MP 链
（identity 五步的加长版）：

```coq
Example use_deduction : forall p q r,
  derives [] (HImp (HImp p (HImp q r)) (HImp p (HImp q r))).
Proof.
  intros p q r. apply deduction. apply dHyp. left. reflexivity.
Qed.
```

这就是为什么实用 Hilbert 系统都把演绎定理当**元规则**用：
它不增加可证式集合（定理告诉我们这点），只压缩证明长度。

## 深浅两种嵌入

本章是六通道里唯一上演「嵌入深度」对照的一章：

- **深嵌入**（Coq/Agda/Lean/Isabelle）：语言是 datatype，推导是
  归纳谓词，元定理对推导归纳——演绎定理是**真的定理**，有
  完整的证明对象。
- **浅嵌入**（HOL4）：公理模式直接是内核定理（`L1/L2/L3` 用
  `TAUT` 或内层推导立起），MP 是 `MATCH_MP`，而 →I 长在内核
  规则 `DISCH` 上——演绎定理「免费」：它**就是**内核的
  假设放电规则。这正是 LCF 设计哲学：元规则即内核规则，
  元定理变成立刻可用的战术。

两种嵌入的取舍：深嵌入能**谈论**演算（证可靠性、完备性——
06/22 章的活），浅嵌入能**使用**演算（顺手、自动化程度高）。
本教程两条腿都走。

## 可靠与完备：Hilbert 侧的两道缝

系统 L 的可靠性（「可推皆有效」）是便宜的：公理模式逐个查
真值表恒真，MP 保真，对推导归纳三分支收工——**这就是为什么
公理要挑「显然真」的**：可靠性的账单集中在公理身上，模式越
少越好核。完备性（「有效皆可推」）是贵的：Mendelson §1.4 的
证法是先建演绎定理，再用「极大一致集」把无效式逐出——这条
路的完整版在 22 章（Henkin 构造，FOL 层）。H&R §1.4.3/1.4.4
在 ND 上演示同一对定理，与本章构成演算对照：同一对元定理，
ND 证可靠性要对每条引入/消除规则分别归纳（规则多、分支多），
Hilbert 只有三分支；但 ND 的演绎定理免费、Hilbert 要先补票。
**演算设计就是在「规则多而直观」与「规则少而元理论便宜」之间
选边**。

## 本章小结

- Hilbert 系统：多公理+单规则（MP）；A1/A2 是组合子 K/S 的
  命题版，A3 是经典部分。
- 「难用但好证元定理」：推导只有三种形态，归纳只有三分支。
- 演绎定理的证明是「对推导归纳」的范本；A2 是它的命门。
- identity = SKK：五步拼装是 Hilbert 风格的入门仪式。
- 深嵌入证元定理，浅嵌入用演算；HOL4 的 DISCH 让演绎定理免费。

## 坑位速记

- **Coq/Rocq**：`induction H as [A HIn | A HAx | r A H1 IH1 H2 IH2]`
  ——dMP 的 IH 跟在各自递归参数后面；identity 要在**任意上下文**
  立（演绎定理的假设分支要用，不只是 `[]`）；dMP 构造子先给
  (p→A) 再给 p——`eapply` 的子目标顺序别反。
- **Lean**：构造子的 intro 模式是「全部字段在前、IH 在后」：
  `| @mp r A h₁ h₂ ih₁ ih₂`（写成 h₁ ih₁ h₂ ih₂ 会张冠李戴）；
  `@` 前缀具名隐式。
- **Agda**：函数级隐式 {Γ p} 必须在子句里具名绑定
  （`deduction {Γ} {p} (mp …)`）——子句体看不见未绑定的隐式。
- **Isabelle**：`inductive derives for Γ` 把上下文钉成参数；
  公理模式用 `definition + ∃`（fun 的模式写不了结构等式）；
  dMP 分支 `with dMP … by (metis derives.dMP)`——把 A2 实例
  与全部 IH 一起喂给 metis。
- **HOL4**：浅嵌入下「公理模式」就是 `!p q. p ==> (q ==> p)`
  形态的定理；`MATCH_MP` 的方向是「定理在前、待消项在后」。
- **通用**：演绎定理 MP 分支的 A2 实例化方向——
  `(p → (r → A)) → ((p → r) → (p → A))`，p 是被剥离的假设。

---

上一章：[04 经典加成：等价矩阵与六家账本](docs/04-classical.md) · 下一章：[06 矢列演算 G：双向上下文与经典性](docs/06-sequent.md)
