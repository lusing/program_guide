# 31 · 自反证明

对应示例：`../examples/31_reflection.v`

### 31.1 思想：用计算代替推理

你其实一直在用自反证明（proof by reflection）：`0 + m = m` 从没手写过归纳——`reflexivity` 的本质是「两边都能**归约**到同一个项」，转换检查替你算了。自反证明把这个思路放大成方法：

> 把一串推理步骤，换成「一个算得出答案的函数 + 一条桥定理」。
> 具体实例的证明只剩 apply + reflexivity——**证明项的大小与数据规模无关**。

对比朴素做法：`repeat rewrite` 构造的证明项随表达式长大，检查时间跟着膨胀；自反证明的证明项恒定——计算不出现在证明项里，只在类型检查时跑一次。第 20 章的 ring/lia 内部正是这套机制。

两类适用场景（书 16.1）：**可判定谓词**（函数算出真假）与**代数等式**（函数把表达式规格化）。

### 31.2 第一类：可判定谓词——偶数判定器

```coq
Fixpoint evenb (n : nat) : bool :=
  match n with 0 => true | 1 => false | S (S m) => evenb m end.

Lemma evenb_true : forall n, evenb n = true -> even_ n.
```

桥定理 `evenb_true` 只证**一次**（函数正确性）。之后每个偶数实例：

```coq
Example even_1024 : even_ 1024.
Proof. apply evenb_true. reflexivity. Qed.
```

对比朴素路线：`apply even_SS` 要重复 512 次。这里的 reflexivity 触发 512 步归约——**计算替你走完了推理**。

一个前置条件值得点名：判定函数必须是**纯结构递归**（归约机制要能把它一路算到底）——第 30 章的燃料法在这类场景里反倒是常客，因为它的计算可被完全执行。

### 31.3 第二类：模结合律的等式证明

任务：只靠加法结合律证 `x+((y+z)+w) = (x+y)+(z+w)`。朴素做法 `repeat rewrite plus_assoc` 每次重写都往证明项里添一块。自反做法三步走（书 16.3.1）：

**第一步：抽象语法树**。nat 上没法写「忘掉括号」的函数（plus 不是构造子，也判断不了任意 x 是不是加法的结果）——把表达式建模成二叉树：

```coq
Inductive bin : Type :=
| node : bin -> bin -> bin        (* 代表 + *)
| leaf : nat -> bin.              (* 代表叶子 *)
```

**第二步：规格化函数**。flatten 把树改成右结合形状（所有加法推到右端）：

```coq
Fixpoint flatten_aux (t fin : bin) : bin := ...
Fixpoint flatten (t : bin) : bin := ...

Compute (flatten (node (leaf 1) (node (node (leaf 2) (leaf 3)) (leaf 4)))).
(* = node (leaf 1) (node (leaf 2) (node (leaf 3) (leaf 4))) *)
```

配一个**解释函数**把树读回 nat：

```coq
Fixpoint bin_nat (t : bin) : nat :=
  match t with
  | node t1 t2 => bin_nat t1 + bin_nat t2
  | leaf n => n
  end.
```

**第三步：桥定理**。「变形不改值」：

```coq
Theorem flatten_valid : forall t, bin_nat t = bin_nat (flatten t).
```

证明里结合律出场——这正是它该出场的地方（一次，而不是每个等式重复 N 次）。

### 31.4 打包成一击必杀的策略

手写 `change (bin_nat 树1 = bin_nat 树2)` 太蠢——用 Ltac 自动「倒模」（把 nat 表达式翻成 bin 树，Ltac 构造项要 `constr:(...)` 前缀）：

```coq
Ltac model v :=
  match v with
  | ?X1 + ?X2 => let r1 := model X1 with r2 := model X2 in
                 constr:(node r1 r2)
  | ?X1 => constr:(leaf X1)
  end.

Ltac assoc_eq_nat :=
  match goal with
  | [ |- ?X1 = ?X2 ] =>
      let t1 := model X1 with t2 := model X2 in
      (change (bin_nat t1 = bin_nat t2);
       apply flatten_valid_2; reflexivity)
  end.
```

最后的 reflexivity 触发完整计算：两棵树各自 flatten 成同一个右结合形状，转换检查放行——**一步重写都没做，等式已证**：

```coq
Theorem reflection_test : forall x y z t u : nat,
  x + (y + z + (t + u)) = x + y + (z + (t + u)).
Proof. intros. assoc_eq_nat. Qed.
```

### 31.5 更远的路

本章只走到结合律。书 16.3 之后的展开方向（思路值得知道，实现篇幅大）：

- **类型与操作符通用化**：用 Section 把「载体类型 + 二元操作 + 结合律定理」参数化，同一套 flatten 基建服务 Z 的乘法、实数的加法……（`flatten_valid_A_2` 通用版）；
- **交换律：变量排序**。结合律只规整形状；加进交换律还要把叶子**排序**成规范次序——在 flatten 之上再叠一个插入排序（`sort_bin`），两条代数定律合并成「排序不改值」一条桥定理。ring 策略的内部结构正是这个思路的工业级版本。

### 31.6 本章坑位清单（实测）

1. **flatten 引理的 rewrite 顺序**：`bin_nat (flatten_aux t1 (flatten_aux t2 t'))` 要先 rewrite 外层 IH1 再内层 IH2——反着来 `Found no subterm matching`（内外嵌套时从外往里剥）；
2. **Ltac 构造项忘写 `constr:(...)`**：报语法错或构造出策略而非项——Ltac 的函数应用与 Gallina 的应用是两个世界；
3. **`model` 里的 `?X1 =>` 分支放最后**：放前面会把 `X1 + X2` 整个当叶子匹配走——模式从具体到宽泛排；
4. **桥定理的 Qed 没关系，但判定函数要透明**：evenb 是 Fixpoint 本来就透明；若用 Definition 包一层证明式定义，记得 Defined；
5. **想当然用 vm_compute 提速前先测**：自反证明的归约量集中在 reflexivity 一步，lazy 与 vm 的差距案例而异——书 16.2 的素数判定器还专门比较了两种除法函数的复杂度（转换 Z 再做二进制运算，比一元 nat 直接算快几个数量级）。

---
上一章：[30 · 一般递归](30-general-recursion.md) ｜ 下一章：[32 · 综合实战：表达式解释器与优化器](32-project.md) ｜ 返回：[README](../README.md)
