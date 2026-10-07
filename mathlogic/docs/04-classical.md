# 04 经典加成：等价矩阵与六家账本

> 对书：Mints §2.9 / §3（Glivenko 预告）/ Huth&Ryan §1.2.5 / Mendelson §1.2
> 通道：C/A/L/I/H4/T（HoTT 首秀）

03 章的结尾留了一笔账：`pbc` 和 `lem_use` 依赖 `classic` 公理，
而全部构造件 Closed。本章把这笔记账升级为一张**矩阵**：五条
经典原理两两互相可推，而且**每条「A ⟹ B」的推导本身都是构造性
的**。这五条原理本体才是经典内核的特权——但「它们等价」这件事
本身不需要任何经典假设。把这个区分看穿，就拿到了理解经典逻辑
的钥匙。

## 五条原理，五副面孔

先逐个认识五位主角。它们表面差异很大，本章证明它们是同一条
「经典性」的五种化身。

**LEM（排中律，law of excluded middle）**：`P ∨ ¬P`。
动机：数学里最常用的分情况——「若 n 是平方数…否则…」。它断言
每个命题非真即假，**但不告诉你是哪边**。

**DNE（双否消去，double negation elimination）**：`¬¬P → P`。
动机：「找不到反例」就当作「成立」——数学里「xxx 不可能不
存在」式的论证全靠它。03 章见过它的逆（`nn_i`）是构造白送；
正向才是分水岭。

**Peirce（皮尔士律）**：`((P → Q) → P) → P`。
动机最隐晦：「如果『P 推出任何东西』就能推出 P，那 P 成立」。
它没有 ¬，却是纯蕴含世界里经典性的试金石——02 章判定器
报告它恒真（语义层），而构造演算证不出（演算层），
**缝就在这里**。

**Clavius**：`(¬P → P) → P`。
动机：「假设 ¬P 却能推出 P，那就 P 吧」——反证法的浓缩形态
（与 PBC 只差一步 ¬e）。

**经典 de Morgan（对偶方向）**：`¬(P ∧ Q) → ¬P ∨ ¬Q`。
03 章证过反方向是构造的；这个方向要把「合取证伪器」变成
「一支具体的否定析取」——需要知道**到底哪一支**假，构造世界
给不出这个信息。

## 矩阵骨架：每条 ⟹ 都是构造的

戏核在这：把 A 塞进 `Section Variable`（Coq）/定理参数（Lean），
用纯 NJp 手段推 B——`Print Assumptions` 全部 Closed。五条边
（`examples/04_classical/ex04_classical.v`）：

```text
LEM ⟹ DNE      对 LEM P 分情况：左支白拿 P，右支 ¬P 与 ¬¬P 对撞 exfalso
LEM ⟹ Peirce   对 LEM P 分情况：右支把 (P→Q) 的构造喂 ¬P 得矛盾
LEM ⟹ Clavius  对 LEM P 分情况：右支 ¬P 经 (¬P→P) 回手得 P 再对撞
DNE ⟹ LEM      把 DNE 施用到 (P ∨ ¬P) 上：¬¬(P∨¬P) 构造可证
DNE ⟹ Clavius  ¬¬P 由 (¬P→P) 与 ¬P 现场组装矛盾
Peirce ⟹ DNE   Peirce P False：把 ¬P 喂给 (P→False) 即 (¬P→⊥)
```

读两个代表。**LEM ⟹ DNE**——最直白的一边：

```coq
Section FromLEM.
Variable LEM : forall P : Prop, P \/ ~ P.

Theorem lem_to_dne : forall P : Prop, ~ ~ P -> P.
Proof.
  intros P Hnn. destruct (LEM P) as [HP | HNP].
  - exact HP.
  - exfalso. apply Hnn. exact HNP.
Qed.
```

手里有 ¬¬P，LEM 把世界劈成两半：P 成立就直接交货；¬P 成立
就与 ¬¬P 对撞出 ⊥，exfalso 交货。注意整个证明只用了 ∨e
（`destruct`）、¬e（`apply Hnn`）、⊥e（`exfalso`）——纯 NJp。

**DNE ⟹ LEM**——全场最漂亮的一步。要用 DNE 证 `P ∨ ¬P`，
先得 `¬¬(P ∨ ¬P)`——而它**构造可证**：

```coq
Theorem dne_to_lem : forall P : Prop, P \/ ~ P.
Proof.
  intros P. apply DNE. intros HNP. apply HNP. right.
  intros HP. apply HNP. left. exact HP.
Qed.
```

项形式看更清楚（Lean 版同款）：`fun h => h (Or.inr (fun hp => h (Or.inl hp)))`。
读法：h 是「P∨¬P 证伪器」。先造一个 ¬P：任给 hp:P，用 `inl`
注入成 P∨¬P 喂 h 得矛盾——于是 `inr` 把这个 ¬P 注入成 P∨¬P
再喂 h，矛盾收工。**自指喂食**：证伪器两次吃到由它自己担保
存在的析取。这是「经典性的半个事实」——LEM 的双重否定在构造
世界免费，去掉双重否定才收费（DNE）。11 章 Glivenko 定理
把这个观察推广成定律：命题逻辑里，每个经典可证式的 ¬¬ 化都
直觉可证。

**LEM ⟹ Peirce** 也值得逐行读——它是「没有 ¬ 的经典性」怎么
从排中流出来的答案：

```coq
Theorem lem_to_peirce : forall P Q : Prop, ((P -> Q) -> P) -> P.
Proof.
  intros P Q H. destruct (LEM P) as [HP | HNP].
  - exact HP.
  - exfalso. apply HNP. apply H. intros HP. exfalso. apply HNP. exact HP.
Qed.
```

左支 P 白拿。右支 ¬P 才是戏：手里 H 是「(P→Q) 就能换 P」的
兑换机，可我们偏不直接用它换 P——而是先给它造一个 P→Q
（`intros HP` 后与 ¬P 对撞 exfalso，P→Q 空洞成立），H 吐出
P，再与 ¬P 对撞出 ⊥。**兑换机被用了一次，吐出来的东西当场
销毁**——只为了向 ¬P 示威。这种「用假设制造矛盾而非制造结论」
的姿态是反证法的精髓。

**Peirce ⟹ DNE** 是对偶的魔术：实例化 Q:=False，Peirce 变成
`((P→False)→P)→P` 即 `(¬P→P)→P`（就是 Clavius！——可见
Peirce 与 Clavius 的距离只有一步定义展开）。给它 ¬P→P：
¬¬P 即 ¬P→⊥，把 ¬P 的持有者喂进去得 ⊥，于是 ¬P→P 空洞
成立——Peirce 吐出 P。代码里 `apply (Peirce P False)` 这一步
的实例化选择是全部机智所在。

## 矩阵为什么闭

五条边够了：DNE 是枢纽——LEM⟹DNE 与 Peirce⟹DNE 进，
DNE⟹LEM 与 DNE⟹Clavius 出；Clavius 自己 ⟹ DNE 也只需一步
（把 ¬¬P 拆成 (¬P→⊥) 再配 Clavius 形状的实例）。矩阵闭包后
得到结论：**五原理两两等价**——任取一条当公理，其余四条全部
免费。这就是为什么各家经典库随手选一条当种子：Coq 的
`classic` 是 LEM，`NNPP` 是 DNE，互相导出。

而原理**本体**的账完全是另一本（同一文件后半）：

```coq
Theorem classical_dne : forall P : Prop, ~ ~ P -> P.
Proof. intros P. apply NNPP. Qed.

Print Assumptions classical_dne.           (* classic *)
```

矩阵零公理，本体记 classic——**「等价」是构造事实，「成立」是
经典特权**。13 章将给出反方向的封顶：构造内核下这些本体**真的**
证不出来（Kripke 两世界反模型）。

## 六家账本对照

| 家 | 矩阵（A⟹B） | 原理本体 | 记账方式 |
|---|---|---|---|
| Rocq | Closed（Section Variable） | `From Stdlib Require Classical_Prop` 后可证 | `Print Assumptions` 列 `classic` |
| Agda | 零公理 | **写不出来** | 无公理机制（只能 postulate，本章不引） |
| Lean | 零公理（原理作参数） | `by_cases`/`Classical.em` | `#print axioms` 列 `Classical.choice, propext, Quot.sound` |
| HoTT | 零公理 | 形态修正：LEM 只对 `IsHProp` | 同 Rocq（泛等公理另册，11/12 章） |
| Isabelle | blast 直证 | **内核白送，零额外公理** | 无账单（经典性在内核） |
| HOL4 | PROVE_TAC 直证 | **内核白送** | 无账单 |

Agda 一行值得停顿：它不是「拒绝经典」，而是**没有公理设施**——
想经典只能 `postulate`，而 postulate 会污染所有用到它的定义的
计算行为。所以本章 Agda 只交矩阵，不交本体。

## HoTT 的形态修正

排中律在 HoTT 里不能对「一切类型」声明。类型论里 `A + ¬A`
判定的是**证据**（要么给 A 的居民，要么给 A 的证伪器），而
HoTT 的视角下高阶类型（h-level ≥ 2）的居民可以是路径、路径的
路径……「任意类型非有证据即被证伪」与泛等公理冲突（HoTT 书
定理 3.2.2 一带）。合法形态只对 h-level 1 的** mere proposition **
（截断层，所有居民相等）声明：

```coq
Definition LEM_hprop :=
  forall A : Type, IsHProp A -> A + (A -> Empty).
```

截断是 HoTT 给「哪些类型配叫命题」的精确回答。`dne→lem` 桥
在 HoTT 里还要多证一步 `IsHProp (A + ¬A)`（析取的截断性）——
12 章收这条伏笔。

## 本章小结

- 五经典原理：LEM/DNE/Peirce/Clavius/经典 deMorgan——五种
  「经典性」的化身，动机各异。
- 等价矩阵的每条边都是**构造性**证明（Section Variable 手法）；
  原理本体才需要经典公理。等价≠成立。
- `¬¬(P∨¬P)` 的自指喂食是全场最漂亮的构造步，也是 Glivenko
  现象（11 章）的预演。
- 六家三种记账文化：显式公理（Coq/Lean/HoTT）、无公理设施
  （Agda）、内核白送（Isabelle/HOL4）。
- HoTT 给 LEM 加了形态条件：只有 mere proposition 配排中。

## 坑位速记

- **Coq/Rocq**：`apply NNPP` 之后 `intros` 留下的目标是
  **False**，不是你想要的析取——`right` 立刻报「Not an
  inductive goal」；¬¬(P∨¬P) 的自指步是 `apply HNP. right.
  intros HP. apply HNP. left. …`。
- **Lean**：`DNE` 施用到 `p ∨ ¬p`（不是 `p`）——泛型原理的
  实例化目标别选错层；`¬¬(p∨¬p)` 的项是
  `fun h => h (Or.inr (fun hp => h (Or.inl hp)))`。
- **HoTT**：库顶层没有 `HoTT.Prelude`（旧版布局）——用
  `HoTT.HoTT` 元文件；`~` = `fun A => A -> Empty`。
- **矩阵自检**：每个 ⟹ 的证明体里只许用 NJp 手段（03 章的
  手段清单）——一旦偷偷用了经典手法，「零公理」就成了假账。
  验收命令永远是 `Print Assumptions` / `#print axioms`，
  不是「看起来没引 Classical」。

---

上一章：[03 自然演绎 NJp](03-njp.md) · 下一章：[05 Hilbert 系统](05-hilbert.md)
