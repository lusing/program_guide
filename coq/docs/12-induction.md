# 12 · 归纳证明

对应示例：`../examples/12_induction.v`

### 12.1 为什么「显然」不够

`n + 0 = n`——「加法单位元，显然」。但在 Coq 里，`+` 是一个在第一个参数上递归的函数：`0 + m` 一步化简到 `m`（左边是 O，直接返回右边），而 `n + 0` 呢？左边是变量，`Nat.add` 的定义动不了它。**「显然」依赖的是数学知识，不是符号计算**——所以必须归纳。这恰是 Coq 的教学价值：它逼你把每个「显然」背后的原理（归纳）真正用出来。

### 12.2 归纳证明的通用剧本

第 11 章已经走过一遍，这里给出可背诵的模板：

```coq
Theorem T : forall n : nat, P n.
Proof.
  intros n. induction n as [| n IH].
  - reflexivity.                    (* 基例：算出来 *)
  - simpl. rewrite IH. reflexivity. (* 步例：展开、用 IH、收尾 *)
Qed.
```

三步：**分裂（induction）、算基例（reflexivity）、用假设（rewrite + reflexivity）**。适用面极广——nat、list、btree、任何归纳类型都行，因为 `induction` 幕后用的正是声明类型时自动生成的归纳原理（第 9 章的 `day_ind`、`btree_ind`）。

### 12.3 例 2：交换律——真实的工作量

```coq
Theorem plus_comm : forall n m : nat, n + m = m + n.
Proof.
  intros n m. induction n as [| n IH].
  - simpl. rewrite plus_n_O. reflexivity.
  - simpl. rewrite IH. rewrite plus_n_Sm. reflexivity.
Qed.
```

两个新情况，极具代表性：

**基例不是纯计算**：化简后是 `m = m + 0`——右边又是那个「动不了的 n + 0」！需要引理帮忙。这里 `rewrite plus_n_O` 用的是**本章自己证的定理**（方向 `n + 0 = n`），把 `m + 0` 替换成 `m`。

> 坑（实测）：标准库也有个 `plus_n_O`，但方向是 `n = n + 0`（反的！）。同名定理、方向不同，`rewrite` 的行为天差地别——**rewrite 之前先 `Check` 一下方向**是省时间的习惯。另外让「要找的一侧」是复合模式（`n + 0`）而不是裸变量，匹配才唯一（第 13 章展开）。

**步例需要「挪动 S」的引理**：`rewrite IH` 后目标是 `S (m + n) = m + S n`，两边各差一个 S 的位置。`plus_n_Sm : S (n + m) = n + S m` 正好搬运 S。

工作流建议：这些「搬运算子」的小引理**先 Search 再自证**（`Search (S _ + _)`、`Search (_ + S _)`），库里多半有；确实没有再手证，手证时它们往往又是一个普通归纳。

### 12.4 例 3：自定义函数的定律

对自己写的函数，同样套路：

```coq
Fixpoint double (n : nat) : nat :=
  match n with
  | O => O
  | S k => S (S (double k))
  end.

Theorem double_plus : forall n : nat, double n = n + n.
Proof.
  induction n as [| n IH].
  - reflexivity.
  - simpl. rewrite IH. rewrite <- plus_n_Sm. reflexivity.
Qed.
```

注意 `rewrite <- plus_n_Sm` 的**反向**使用：`plus_n_Sm` 把 `S (n + m)` 变成 `n + S m`，而这里需要把 `n + S n` 变回 `S (n + n)`——方向反着用。**rewrite 的方向感是本阶段最重要的肌肉记忆**，判断法：看你想消掉的模式在哪一侧。

### 12.5 例 4：列表上归纳——方法完全相同

```coq
Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys
  | h :: tl => h :: my_append tl ys
  end.

Theorem my_app_nil_r : forall (A : Type) (xs : list A),
  my_append xs [] = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.                    (* 空表拼空表 = 空表 *)
  - simpl. rewrite IH. reflexivity. (* 头保住，尾交给 IH *)
Qed.
```

和 nat 的归纳**零差别**：裂成 `[]` / `::` 两个情形，基例计算，步例用 IH。为什么 `my_append [] ys = ys` 这个「左单位元」不用证（`reflexivity` 就收）而「右单位元」要归纳？因为定义在**第一个参数**上 match——左边是 `[]` 一步化简，右边是变量动不了。**「证明的难度分布由定义的形状决定」**，这是写可证代码的第一直觉。

### 12.6 归纳的适用边界

| 想证的东西 | 用什么 |
|---|---|
| 具体数值断言 `3 + 4 = 7` | `reflexivity`（纯计算） |
| 对所有 n 的性质，函数按结构递归 | `induction`（本章） |
| 有限种情况（bool、枚举） | `destruct`（第 13 章，无 IH 的轻量归纳） |
| 「存在性/任意性」陈述 | 谓词逻辑工具（第 15 章） |

### 12.7 本章坑位清单（实测）

1. **同名定理方向相反**：本章 `plus_n_O`（n + 0 = n）与标准库 `plus_n_O`（n = n + 0）同姓不同向——rewrite 前 `Check`；
2. **归纳前把假设 intros 太多**：依赖被归纳变量的假设收进上下文后不参与一般化，步例的 IH 变弱甚至证不动（第 22 章有实例与解法 `revert`）；**口诀：要归纳的变量最后 intros**；
3. **忘记 `simpl` 直接 rewrite**：目标还是 `S n + 0` 的形状而 IH 谈的是 `n + 0`，rewrite 匹配不上——先 simpl 把形状展开；
4. **基例目标里残留变量**：`0 + m = m + 0` 的 m + 0 消不掉——Search 搬运算子方向的引理（`plus_n_O` / `Nat.add_0_r`）；
5. **induction 的 as 模式漏写**：默认给步例的假设起名 `IHn`——名字能用，但 `as [| n IH]` 显式命名后 rewrite 才顺手。

---
上一章：[11 · 证明状态与 tactic 机理](11-proof-state.md) ｜ 下一章：[13 · 重写、化简与分情况讨论](13-rewrite.md) ｜ 返回：[README](../README.md)
