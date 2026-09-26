# 30 · 一般递归

对应示例：`../examples/30_general_recursion.v`

### 30.1 结构递归的边界

第 10 章立过规矩：Fixpoint 必须在**结构子项**上递归，守卫检查是机械判据。日常算法里偏偏有一批不守这套的：

```coq
Fail Fixpoint log2_bad (n : nat) : nat :=
  match n with
  | 0 => 0 | 1 => 0
  | _ => S (log2_bad (Nat.div n 2))
  end.
```

`n / 2` 不是 n 的子项——拒绝。但这个函数显然会终止（参数实际在变小）！「显然」不行，Coq 要**可检查的证据**。本章按书第 15 章的顺序给三件武器：燃料、良基递归、Program Fixpoint。

### 30.2 方法一：有界递归（燃料）

加一个人工参数当「燃料」，每步严格减一，递归改成对燃料结构递归：

```coq
Fixpoint half_fuel (fuel n : nat) : nat :=
  match fuel with
  | 0 => 0                              (* 燃料烧完：默认值 *)
  | S f => match n with
           | 0 => 0 | 1 => 0
           | S (S m) => S (half_fuel f m)
           end
  end.

Lemma half_fuel_ok : forall f n, n <= f -> half_fuel f n = Nat.div2 n.
```

正确性引理一句话：**燃料给够（≥ n），结果就对**；默认值 0 在工作区间内永远不出场。`Compute (half_fuel 100 41) = 20`。

代价：每次调用前要算/传一个界，抽取出的代码背着燃料参数跑。但别急着嫌弃它——**自反证明（第 31 章）的最爱正是燃料**：它的计算可以被归约机制完整执行，这正是 reflexivity 需要的性质。

### 30.3 方法二：良基递归

更本质的武器。一个关系**良基**（well-founded），指不存在无穷下降链；Coq 里它通过**可达性谓词**定义：

```coq
Inductive Acc (A : Type) (R : A -> A -> Prop) (x : A) : Prop :=
| Acc_intro : (forall y : A, R y x -> Acc R y) -> Acc R x.

Definition well_founded R := forall a, Acc R a.
```

直觉：x 可达 = 它的所有 R-前驱都可达。`<` 在 nat 上良基（标准库 `lt_wf` 已证好）。

**递归在 m - n 上、参数却变小靠的是算术**的欧氏除法（书 15.2.6 精简版）：

```coq
Definition wf_div : forall m n : nat, 0 < n ->
  {q : nat & {r : nat | m = q * n + r /\ r < n}}.
Proof.
  induction m as [m IH] using (well_founded_induction lt_wf).
  ...
Defined.
```

`well_founded_induction` 给的 IH 是「对所有**更小**的 y 都成立」——比结构归纳的 IH 强一档，`m - n < m` 这种算术递减直接可用。注意本章实测的一个区分：`well_founded_ind` 是 **Prop 版**归纳原理，定义函数要用 **Set 版递归子 `well_founded_induction`**——书里正是这一对名字，取错了报元变量类型错误。

成品 `wf_div` 是强规范除法（商、余数、四条性质全打包），`Compute` 直接算：2000 ÷ 31 = 64。

### 30.4 方法三：Program Fixpoint（现代利器）

日常首选。`{measure n}` 声明「按度量 n 递减」，递归参数随便写，Coq 自动生成终止性**义务**（obligation）：

```coq
Program Fixpoint plog2 (n : nat) {measure n} : nat :=
  match le_gt_dec 2 n with
  | left _ => S (plog2 (Nat.div2 n))
  | right _ => 0
  end.
Next Obligation.
  apply Nat.lt_div2. lia.
Qed.
```

义务就一条：`2 <= n` 时 `Nat.div2 n < n`——`Nat.lt_div2` 给主结论，副条件 `0 < n` 由 lia 从前提收走。还完债，plog2 就是合法的良规定义。`Compute (plog2 1000) = 9`（2⁹ = 512 ≤ 1000 < 1024）。

实测坑：定义里若写 `if Nat.leb 2 n`，义务会变成**布尔等式** `Nat.leb 2 n = true`，lia 读不懂——用 `le_gt_dec` 让前提直接是 Prop，义务跟着变成线性算术。

### 30.5 三种方法怎么选

| | 燃料 | 良基递归 | Program Fixpoint |
|---|---|---|---|
| 代码贴近算法本意 | 差（背着界） | 好 | 好 |
| 证明负担 | 轻（界够即可） | 重（Acc 记号繁琐） | 中（义务自动化） |
| 抽取代码干净度 | 差 | 好 | 好 |
| 特长 | 自反证明（可完全归约） | 理论根基、定制关系 | 日常工程 |

两条进阶路线点到为止（书 15.3/15.4）：对良基函数直接推理很难，实战常**先证不动点方程**（f x = 展开式）再对方程做归纳；还可以为单个函数**定制归纳谓词**描述其定义域——部分函数（在定义域外发散）也能这样精确建模。

### 30.6 本章坑位清单（实测）

1. **`well_founded_ind` vs `well_founded_induction`**：前者 Prop 版（P : A -> Prop）后者 Set 版（P : A -> Set）——定义函数取错报 `Cannot instantiate metavariable`；
2. **`{q : nat & P q}` 是 sigT**：取值用 `projT1`，不是 `proj1_sig`（那是 sig 的）；
3. **`0 < 31` 这种前提的现成证明**：`Nat.lt_0_succ 30`（0 < S 30），别手搭；
4. **Program 义务里的布尔条件**：leb 产生的等式假设 lia 用不了——定义里换 le_gt_dec；
5. **Next Obligation 的上下文已自动引入变量**：`intros n H.` 会报 `n is already used`——要么不 intros，要么换名；
6. **良基函数直接 simpl 不动**：递归藏在 Acc 结构里，化简行为与普通 Fixpoint 完全不同——证性质优先走不动点方程路线。

---
上一章：[29 · 余归纳与无限数据](29-coinductive.md) ｜ 下一章：[31 · 自反证明](31-reflection.md) ｜ 返回：[README](../README.md)
