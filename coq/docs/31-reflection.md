# 31 · 自反证明

对应示例：`../examples/31_reflection.v`

### 31.1 思想：用计算代替推理

你其实一直在用自反证明（proof by reflection）：`0 + m = m` 从没手写过归纳——`reflexivity` 的本质是「两边都能**归约**到同一个项」，转换检查替你算了。自反证明把这个思路放大成方法：

> 把一串推理步骤，换成「一个算得出答案的函数 + 一条桥定理」。
> 具体实例的证明只剩 apply + reflexivity——**证明项的大小与数据规模无关**。

对比朴素做法：`repeat rewrite` 构造的证明项随表达式长大，检查时间跟着膨胀；自反证明的证明项恒定——计算不出现在证明项里，只在类型检查时跑一次。第 20 章的 ring/lia 内部正是这套机制。

自反证明主要吃两类场景：**可判定谓词**（写一个函数算出真假，再证「函数说真则命题成立」）与**代数等式**（写一个函数把表达式规格化，再证「规格化不改语义」）。本章各走一遍。

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

任务：只靠加法结合律证 `x+((y+z)+w) = (x+y)+(z+w)`。朴素做法 `repeat rewrite plus_assoc` 每次重写都往证明项里添一块。自反做法三步走：

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

本章只走到结合律。同一套思路继续往前推，还有四级台阶——实现篇幅都不小，但每一级的想法都可以说清楚：

1. **类型与操作符通用化**。本章的 bin/flatten/bin_nat 全部焊死在 `nat` 与 `+` 上。用 Section 把「载体类型 A + 二元操作 op + op 的结合律定理」参数化，同一套规格化基建就能服务 Z 的乘法、实数的加法……只需把桥定理重证一次（证明脚本几乎不变，只是 rewrite 的结合律换了一条）。

2. **表达式里混入乘法**。bin 只有 node 一个算符；支持 `*` 要给语法树加第二种节点（或给 node 挂算符标签）。规格化目标随之升级：不再只是「括号全部右移」，而是「按**分配律**把乘法全部展开，化成单项之和」——规格化函数先递归展开乘法（`x * (y + z)` ↦ `x*y + x*z`），再对每个加法链做右结合化。桥定理的证明里，结合律、交换律、分配律各出场**一次**（在规格化函数的正确性引理中），之后每个具体等式仍是一行 change + apply + reflexivity。

3. **交换律：变量排序**。结合律只规整形状，`y + x` 与 `x + y` 的右结合树仍不相同。要模掉交换律，得给叶子定一个**规范次序**（比如按变量名字典序），在 flatten 之上再叠一个排序 pass（插入排序即可），把叶子排成规范序列。两条代数定律合并成一条桥定理「规格化（含排序）不改值」——排序引理通常借助「排序是原序列的排列、加法对排列不变」来完成。

4. **环等式的完整自反证明**。把 1–3 合起来就是「模环公理的等式判定器」：语法树带变量索引、算符有加减乘（减转加负、幂转连乘），规格化器把一切表达式化成**多项式的规范形**——比如按 Horner 嵌套形式排列的、变量有序的单项之和；两个环表达式相等，当且仅当它们的规范形**语法相同**。证明结构与第 31.3 节完全同构：解释函数把语法树读回环元素，桥定理证「规格化在环公理下保持语义」，策略层负责把目标表达式倒模成语法树。

标准库的 **`ring` 策略正是这一思路的工业实现**（Grégoire–Mahboubi 的多项式方法）：规格化到 Horner 范式，对任意声明过 `Ring` 结构的载体类型通用，减法与幂都有处理。你每次敲 `ring`，跑的就是本章这套「倒模—规格化—桥定理—reflexivity」的流水线，只是引擎大得多。

### 31.6 本章坑位清单（实测）

1. **flatten 引理的 rewrite 顺序**：`bin_nat (flatten_aux t1 (flatten_aux t2 t'))` 要先 rewrite 外层 IH1 再内层 IH2——反着来 `Found no subterm matching`（内外嵌套时从外往里剥）；
2. **Ltac 构造项忘写 `constr:(...)`**：报语法错或构造出策略而非项——Ltac 的函数应用与 Gallina 的应用是两个世界；
3. **`model` 里的 `?X1 =>` 分支放最后**：放前面会把 `X1 + X2` 整个当叶子匹配走——模式从具体到宽泛排；
4. **桥定理的 Qed 没关系，但判定函数要透明**：evenb 是 Fixpoint 本来就透明；若用 Definition 包一层证明式定义，记得 Defined；
5. **想当然用 vm_compute 提速前先测**：自反证明的归约量集中在 reflexivity 一步，lazy 与 vm 的差距案例而异。比换求值器更治本的优化是**换数制**：判定类函数（比如素数判定里的试除）若先把一元 nat 转成二进制表示（Z/N）再做运算，通常比一元表示直接算快几个数量级——自反证明的瓶颈在归约本身，数据表示越小、每步归约越便宜，整体越快。

---
上一章：[30 · 一般递归](30-general-recursion.md) ｜ 下一章：[32 · 综合实战：表达式解释器与优化器](32-project.md) ｜ 返回：[README](../README.md)
