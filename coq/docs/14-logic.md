# 14 · 命题逻辑

对应示例：`../examples/14_logic.v`

### 14.1 Prop 世界的数据结构

第 4 章埋的线现在收：`Prop` 住着命题。命题本身也是**归纳类型**，有自己的构造子：

| 写法 | 真身 | 构造子 | 证明它的策略 | 使用它的策略 |
|---|---|---|---|---|
| `P /\ Q`（且） | `and P Q` | `conj : P -> Q -> P /\ Q` | `split` | `destruct` |
| `P \/ Q`（或） | `or P Q` | `or_introl` / `or_intror` | `left` / `right` | `destruct` |
| `P -> Q`（蕴含） | 函数类型 | （就是函数） | `intros` | `apply` |
| `~ P`（非） | `not P := P -> False` | （就是函数） | `intros` | `apply` |
| `P <-> Q`（当且仅当） | `(P -> Q) /\ (Q -> P)` | （是合取） | `split` 后各证 | `destruct` |
| `True` | 单构造子 `I` | `I : True` | `exact I` | 无用武之地 |
| `False` | **无构造子** | （不存在） | （证不了） | `destruct`（爆炸） |

这张表是本章全部内容的压缩版。注意每个「证明它的策略」恰好是 Curry–Howard 的体现：**造值用构造子，拆值用 match（destruct），函数靠 apply**——Prop 世界与数据世界共用同一套规则，没有新东西。

### 14.2 合取：split 与 destruct

```coq
Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q H.
  destruct H as [HP HQ].   (* 拆开「且」的假设：两个证据 *)
  split.                   (* 拆开「且」的目标：两个子目标 *)
  - exact HQ.
  - exact HP.
Qed.
```

读法与第 6 章的元组完全同构：`/\` 就像 `*`（积类型），`split` 造对偶，`destruct as [HP HQ]` 拆对偶。三层子弹的完整体验（`and_assoc`，交换结合顺序的接线练习）：

```coq
Theorem and_assoc : forall P Q R : Prop,
  (P /\ Q) /\ R <-> P /\ (Q /\ R).
Proof.
  intros P Q R. split.
  - intros [[HP HQ] HR]. split.
    + exact HP.
    + split.
      * exact HQ.
      * exact HR.
  - intros [HP [HQ HR]]. split.
    + split.
      * exact HP.
      * exact HQ.
    + exact HR.
Qed.
```

`intros [[HP HQ] HR]` 的嵌套模式一次拆到底（与 `let (a, (b, c)) := ...` 同款语法）。逻辑证明写多了你会发现：**一半的逻辑证明其实是「拆线再接线」的手工活**，模式匹配的熟练度直接决定速度。

### 14.3 析取：left / right 与带 | 的 destruct

```coq
Theorem or_comm : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof.
  intros P Q H.
  destruct H as [HP | HQ].   (* 或：两个分支，走哪支拿哪支的证据 *)
  - right. exact HP.
  - left. exact HQ.
Qed.
```

- 目标是 `P \/ Q` 时，`left`/`right` **选择**你要证哪边（对应构造子 or_introl/or_intror）——注意这两个词与子弹毫无关系；
- 假设是 `P \/ Q` 时，`destruct as [HP | HQ]` 裂成两个分支——**竖线 | 就是「或」**，在 as 模式里含义完全一致（对比合取的 `[HP HQ]` 空格并排）。

析取像第 9 章的变体（sum 类型 `A + B` 的 Prop 版）——同构关系贯穿始终。

### 14.4 蕴含与否定：它们就是函数

**蕴含**在第 1 章就剧透过，现在正式编译它——注意这个证明**一个策略都不用**，直接写出函数：

```coq
Definition modus_ponens (P Q : Prop) (hpq : P -> Q) (hp : P) : Q :=
  hpq hp.
```

「P 蕴含 Q」的证明是函数；「肯定前件」（拿 P 的证明喂给它）就是函数应用。策略风格同一件事：

```coq
Theorem modus_ponens' (P Q : Prop) : (P -> Q) -> P -> Q.
Proof.
  intros hpq hp.    (* 蕴含的前提就是函数参数，intros 收下 *)
  apply hpq.        (* 目标 Q，hpq 造得出，前提 P 变新目标 *)
  exact hp.
Qed.
```

**否定**没有新东西——`Print not.` 揭底：

```coq
Print not.
(* not A := A -> False *)
```

`~P` 是「P 推出假」的缩写。所以证 `~P` 就是 `intros`（收下 P 的证明再构造 False）；用 `~P` 的证据就是 `apply`（把 P 喂给它，得到 False）。经典一例（P 与「非 P」不同时成立）：

```coq
Theorem not_and_true : forall P : Prop, ~ (P /\ ~ P).
Proof.
  intros P [HP HnP].
  (* 注意：~ P 不再往下解构——~ 是定义不是构造子，
     intro 模式进不去，直接收下当函数用（实测坑） *)
  apply HnP.        (* 目标 ~P 即 P -> False：喂个 P 进去 *)
  exact HP.
Qed.
```

### 14.5 True、False 与爆炸原理

- `True` 有唯一证明 `I`，随叫随到（`exact I`）——所以它当「免费赠品」出现在合取里（`P /\ True <-> P`）；
- `False` **没有构造子**——所以永远证不出它，但**假设里有它时什么都能证**：

```coq
Theorem from_false : forall P : Prop, False -> P.
Proof.
  intros P H. destruct H.   (* False 零构造子，destruct 无分支可走，
                               直接关闭任意目标 *)
Qed.
```

这就是**爆炸原理**（ex falso quodlibet）：从矛盾出发，一切皆可证。它与第 13 章的 `discriminate` 一脉相承——discriminate 本质是「发现矛盾假设 → 引爆」。`~P` 定义成 `P -> False` 的设计因此完全自洽：「非 P」=「P 能引爆整个系统」。

### 14.6 <->：一次 split，两个方向

`P <-> Q` 展开是 `(P -> Q) /\ (Q -> P)`——所以策略组合固定：`split` 后各证一个蕴含。示例 14 的 `and_true_iff`：

```coq
Theorem and_true_iff : forall P : Prop, P /\ True <-> P.
Proof.
  intros P. split.
  - intros [HP _]. exact HP.   (* _ 丢弃不需要的 I *)
  - intros HP. split.
    + exact HP.
    + exact I.
Qed.
```

写 iff 证明的节奏感：**先 split，两个方向各自独立作战**。命名习惯上方向叫「→ 方向」「← 方向」（或 forward/backward），与 `rewrite` 的方向用语一致。

### 14.7 经典逻辑 vs 构造逻辑（一段重要的题外话）

Coq 的逻辑是**构造逻辑**（intuitionistic）：证明 `P \/ Q` 必须给出**到底哪一边**——没有「排中律」`forall P, P \/ ~ P`（不添加公理的话）。这不是缺陷而是立场：

- 构造性证明**携带信息**：`P \/ ~P` 的构造性证明就是「判断 P 真假的算法」——对任意命题这种算法不存在；
- 需要经典推理时可以 `Require Import Classical`，引入排中律公理——代价是证明里多了公理依赖（`Print Assumptions` 会显示，第 25 章）。

初学阶段（也是本教程全程）**只用构造逻辑**，不碰 Classical。判断自己是否在「越界」的信号：想证 `~ ~ P -> P` 或 `P \/ ~ P`——这两个都是经典逻辑标志，构造逻辑里证不出。

### 14.8 本章坑位清单（实测）

1. **对 `~P` 用 intro 解构模式**：`intros [HP [HnP]]` 在 `~(P /\ ~P)` 上报 `Expects a disjunctive pattern with 0 branches`——`~` 是定义（函数），不是构造子，模式进不去；先 `intros P [HP HnP]` 拆到 `~P` 为止；
2. **left/right 与子弹混淆**：它们是「选构造子」，不是目标管理——嵌套时该用子弹还是用子弹；
3. **_iff 忘了 split**：直接对 `P <-> Q` 的目标 apply 单方向引理会失败——先 split；
4. **把 False 当成可证目标硬证**：证 `False` 只能靠上下文矛盾（destruct 假设 / discriminate）；
5. **试图证排中律**：构造逻辑里不可能；需要经典逻辑用 Classical 库并接受公理依赖。

---
上一章：[13 · 重写、化简与分情况讨论](13-rewrite.md) ｜ 下一章：[15 · 谓词逻辑与 reflect](15-predicates.md) ｜ 返回：[README](../README.md)
