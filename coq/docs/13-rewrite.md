# 13 · 重写、化简与分情况讨论

对应示例：`../examples/13_rewrite.v`

前两章的证明只用了五种策略。本章补齐日常证明的另外几件兵器：`destruct`、`symmetry`/`transitivity`、`discriminate`/`injection`，并把 `rewrite` 的方向问题讲透。

### 13.1 rewrite 的方向与「哪侧好匹配」

`rewrite H` 把 H **左边**的模式替换成右边；`rewrite <- H` 反向。方向的选择标准：

> **让「你要找的那个模式」处在复合模式（有结构）的一侧。**

标准库给了绝佳的对照样本：

```coq
Check Nat.add_0_r.   (* forall n, n + 0 = n —— 左侧复合：找 n + 0 *)
Check plus_n_O.      (* forall n, n = n + 0 —— 左侧裸变量！ *)
```

- `rewrite Nat.add_0_r`（正向）：在目标里**找 `?x + 0`**、替换为 `?x`——匹配唯一，行为完全可预期；
- `rewrite plus_n_O`（正向）：要在目标里「找裸变量 ?x」——几乎任何子项都匹配得上，行为微妙（可能原地不动，也可能把每个 n 都膨胀成 n + 0，实测两种都遇到过）；
- `rewrite <- plus_n_O`（反向）：找的模式来自右侧 `?x + 0`——又是复合模式，干净。

实测案例（示例 13）：想把假设 `H : n + 0 = m` 里的 `n + 0` 消掉，写 `rewrite plus_n_O in H` 无声无息什么都没发生；换 `rewrite Nat.add_0_r in H` 或 `rewrite <- plus_n_O in H` 立刻成功。

```coq
Theorem rw_in : forall n m : nat, n + 0 = m -> n = m.
Proof.
  intros n m H.
  rewrite Nat.add_0_r in H.   (* 假设里的 n + 0 换成 n *)
  exact H.                    (* H : n = m，正好是目标 *)
Qed.
```

### 13.2 simpl：只算不猜

`simpl` 把目标里的函数应用按定义展开（第 11 章已见）。两个要点：

1. **它只做符号计算**：`0 + n` 能化（定义如此），`n + 0` 不能（定义在第一个参数递归）——证明的工作量分布由此决定（第 12.5 节）；
2. **它可以作用于假设**：`simpl in H` 把假设里的可计算部分也展开——第 15 章 `simpl in H` 后接 `discriminate` 是高频连招。

`simpl` 打多了无害（最多费点算力），打少了 rewrite 匹配不上模式。卡住时先 simpl 一下是零成本的尝试。

### 13.3 destruct：分情况讨论

不需要归纳假设时，用 `destruct`——「把变量按构造子裂开，每种情况一个目标」：

```coq
Theorem negb_involutive : forall b : bool, negb (negb b) = b.
Proof.
  intros b. destruct b.
  - reflexivity.   (* b := true *)
  - reflexivity.   (* b := false *)
Qed.
```

`destruct n`（nat）则裂成 `0` 与 `S k`。**destruct 与 induction 的关系**：induction = destruct + 自动附赠归纳假设 IH。枚举两三种情况够用 destruct；结论需要「对更小的同类值成立」就必须 induction。

destruct 也能作用于**假设**（假设是 `P \/ Q` 时裂出两个分支，第 14 章）——这与「对变量 destruct」是同一个动作：把一个项按它的构造子拆开。

### 13.4 symmetry 与 transitivity：等式的姿态

```coq
Theorem sym_ex : forall n m : nat, n = m -> m = n.
Proof.
  intros n m H. symmetry. exact H.
Qed.

Example chain_ex : 2 + 2 = 4.
Proof.
  transitivity (3 + 1).
  - reflexivity.
  - reflexivity.
Qed.
```

- **`symmetry`** 把目标 `a = b` 翻转成 `b = a`——手里证据方向与目标相反时的标准动作（apply 反向定理前常先转身）；
- **`transitivity t`** 把目标 `a = c` 裂成 `a = t` 与 `t = c`——需要中转站时用。日常频率不高，但 `<=` 类目标的「夹逼」证明全靠它。

### 13.5 discriminate 与 injection：构造子的纪律落到实处

第 9 章说过构造子「单射、不相交」。对应的策略：

**`discriminate H`**——H 两边是**不同构造子**（如 `0 = 1`、`[] = x :: xs`）时，H 是矛盾，用它关闭**任何**目标：

```coq
Theorem zero_neq_one : 0 <> 1.
Proof.
  intros H.            (* <> 展开为 0 = 1 -> False *)
  discriminate H.
Qed.

Theorem nil_neq_cons : forall (A : Type) (x : A) (xs : list A),
  [] <> x :: xs.
Proof.
  intros A x xs H. discriminate H.
Qed.
```

**`injection H`**——H 两边是**同一构造子**（如 `S n = S m`）时，提取「参数相等」的新假设：

```coq
Theorem inj_ex : forall n m : nat, S n = S m -> n = m.
Proof.
  intros n m H.
  injection H as H2.   (* 从 S n = S m 里抽出 n = m *)
  exact H2.
Qed.
```

两者合起来就是「构造子纪律」的可操作版本。经典应用是证**不可能的等式**（如 `S n <> n`）与从等式解构数据——第 15 章证 `evenb 1 = true -> even 1` 时，`simpl in H. discriminate H.` 一击毙命。

### 13.6 本章策略速查表

| 策略 | 作用对象 | 干什么 |
|---|---|---|
| `intros` | 目标的 forall/-> | 收变量/假设进上下文（可带解构模式） |
| `simpl`（`in H`） | 目标或假设 | 按定义展开计算 |
| `rewrite H`（`<-`/`in H`） | 目标或假设 | 按等式替换（注意方向，见 13.1） |
| `reflexivity` | 目标 | 两边可化简为同值即关闭 |
| `destruct x`（`as 模式`） | 变量或假设 | 按构造子分情况（无 IH） |
| `induction x` | 变量 | 分情况 + 赠送 IH |
| `apply 定理` | 目标 | 按结论对齐，前提变新目标 |
| `exact 项` | 目标 | 直接交出证明项 |
| `symmetry` | 目标 | 翻转等式 |
| `transitivity t` | 目标 | 拆两段等式 |
| `discriminate H` | 假设 | 不同构造子的等式 = 矛盾，关任何目标 |
| `injection H as H2` | 假设 | 同构造子等式 → 参数等式 |

这张表覆盖了 80% 的日常证明。第 18 章再补自动化与控制流。

### 13.7 本章坑位清单（实测）

1. **rewrite 裸变量方向**：定理一侧是裸变量时正向 rewrite 行为不稳定（可能没动作、可能膨胀）——用复合模式那侧，或反向（13.1 的实测案例）；
2. **`rewrite ... in H` 忘了 `in H`**：改了目标没改假设，还以为定理是错的——看清楚上下文里哪边需要变；
3. **discriminate 拿错东西**：`discriminate H` 要求 H 恰好是「不同构造子相等」；H 形如 `S n = S m` 时该用 injection；
4. **injection 之后忘 intro**：`injection H.` 不带 `as` 会把 `n = m` 放进目标（变成待 intro 的形式）——用 `injection H as H2` 直接收为假设更顺手；
5. **对 Prop 用 destruct**：`destruct` 只拆归纳类型；`~P` 是定义不是构造子，intro 模式进不去（第 14 章的实测坑）。

---
上一章：[12 · 归纳证明](12-induction.md) ｜ 下一章：[14 · 命题逻辑](14-logic.md) ｜ 返回：[README](../README.md)
