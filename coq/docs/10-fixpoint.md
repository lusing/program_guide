# 10 · 递归函数：Fixpoint 与终止性

对应示例：`../examples/10_fixpoint.v`

### 10.1 Fixpoint：会检查终止的递归

Coq 里递归函数用 `Fixpoint` 声明：

```coq
Fixpoint sum_to (n : nat) : nat :=
  match n with
  | O => 0
  | S k => S k + sum_to k      (* k 是 S k 的直接子项 —— 合法 *)
  end.

Compute (sum_to 4).            (* = 10：4+3+2+1 *)
```

与 `Definition` 的唯一区别：`Fixpoint` 要求**递归调用发生在「结构更小」的子项上**，并由守卫检查器（guard condition）逐个验证。为什么这么严格？因为 Coq 的函数不仅是代码，还是**逻辑对象**——若允许不终止的递归，就能构造出假命题的证明，整个系统的一致性崩塌（这门课不展开，记住结论）。代价是某些「显然会停」的写法（如按 `n - 1` 递减的循环）会被拒，收益是**每个能编译的函数必然全函数**——数学上无懈可击。

### 10.2 {struct n}：告诉 Coq 在哪个参数上递归

多参数函数，Coq 自动猜递减参数，猜不中时手动指定：

```coq
Fixpoint power (base : nat) (exp : nat) : nat :=
  match exp with
  | O => 1
  | S e => base * power base e
  end.

Print power.
(* 打印里能看到 {struct exp} —— Coq 记录了「在 exp 上结构递归」 *)
```

需要手动写的形态：`Fixpoint f (a : nat) (b : nat) {struct b} : ...`。

### 10.3 守卫检查的真实边界（实测）

教科书的说法是「递归必须在子项上」。实测（8.20.1 与 9.1.0 行为一致），边界比这微妙：

```coq
(* 竟然能通过！ *)
Fixpoint bad_sum (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_sum (k - 1) + 1
  end.

Compute (bad_sum 3).   (* = 2 —— 注意不是 3：k=0 时 0-1 截断为 0 *)
```

为什么 `k - 1` 能过？**守卫检查器会「看穿」定义**：`k - 1` 是 `Nat.sub k 1`，把它展开后每个分支要么是常量要么是 k 的子项——「展开后全是子项」就算过关。同理 `Nat.pred k`、甚至 `Nat.pred (Nat.pred k)` 都能过（实测）。这也解释了它为什么真的终止。

但在**参数本身**上递归，无论怎么包都过不了：

```coq
Fail Fixpoint bad2 (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad2 (n - 1)
  end.
(* Recursive call to bad2 has principal argument equal to
   "n - 1" instead of "k". *)

Fail Fixpoint bad_loop (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_loop n
  end.
```

报错把「主参数应该是什么」说得明明白白（`instead of "k"`）。**实用心法：在分支里递归就用模式变量（k、tl），别用外层参数（n、xs）**——按这条写，守卫检查几乎不会找麻烦。

### 10.4 真正需要「非结构递归」时怎么办

写快排、归并这种「递归一半再一半」的算法，`n / 2` 不是子项，直写会被拒。三条出路：

1. **换形状**：很多算法有结构递归的等价版本（在 `(l, r) = split xs` 的分量上递归——split 拆出的两个表是 xs 的「逻辑子项」，配合 `program fixpoint`/`Function` 可行但繁琐）；
2. **燃料（fuel）**：多传一个 nat 参数当「剩余步数」，结构递归在燃料上——证明时处理燃料传递的繁琐；
3. **良基递归**（`well-founded`）：用 `Program Fixpoint` 或 `Function` 声明「按度量递减」，Coq 生成额外子证明。

第 23 章的插入排序不需要这些（它在表尾/表头结构上递归）；良基递归与度量递归在第 30 章正式展开——这里知道名词和适用场景即可。

### 10.5 累加器写法

尾递归形态的遍历，把「已处理部分」作为参数携带：

```coq
Fixpoint rev_acc {A : Type} (acc : list A) (xs : list A) : list A :=
  match xs with
  | [] => acc
  | h :: tl => rev_acc (h :: acc) tl    (* 递归在 tl 上 —— 合法 *)
  end.

Definition fast_rev {A : Type} (xs : list A) : list A :=
  rev_acc [] xs.

Compute (fast_rev [1; 2; 3]).   (* = [3;2;1] *)
```

注意递减依然靠 `tl`（结构子项）——累加器**不改变**终止性的判定方式，只改变「结果怎么攒」。`fast_rev xs = rev xs` 的证明（和「rev (rev xs) = xs」）在第 22 章。

### 10.6 互递归：with

两个函数互相调用，用 `with` 连接声明：

```coq
Fixpoint myeven (n : nat) : bool :=
  match n with
  | O => true
  | S k => myodd k
  end
with myodd (n : nat) : bool :=
  match n with
  | O => false
  | S k => myeven k
  end.

Compute (myeven 10).           (* = true *)
Compute (myodd 7).             (* = true *)
```

守卫检查跨 `with` 全体进行。第 15 章会把这个 bool 版与 Prop 版的偶数对照。

### 10.7 本章坑位清单（实测）

1. **`n - 1` 型递归**：直觉以为必被拒，实测（8.20.1/9.1.0）**能过**（检查器展开 `Nat.sub` 后视为子项）；但 `n - 1`（n 是参数本身）被拒——分支里递归用模式变量，别用外层参数；
2. **递归函数误用 `Definition`**：报「引用未找到」，真实原因是名字没注册；
3. **多参数猜错递减参数**：报 `Cannot guess decreasing argument of fix`——加 `{struct 参数名}`；
4. **`Fixpoint` 一行版忘句点**：`end.` 属于 match，`Fixpoint` 整体还要一个句点收尾——嵌套句点数清楚；
5. **指望尾递归优化**：Coq 不做 TCO，累加器写法是「逻辑上一次递归」，不是性能优化（性能要靠第 24 章的数系与抽取）。

---
上一章：[09 · 归纳类型：自定义数据](09-inductive.md) ｜ 下一章：[11 · 证明状态与 tactic 机理](11-proof-state.md) ｜ 返回：[README](../README.md)
