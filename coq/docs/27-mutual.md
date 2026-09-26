# 27 · 互归纳：树与森林

对应示例：`../examples/27_mutual.v`

### 27.1 互引归纳类型

有些数据结构天然成对：树的节点装着**森林**（树的列表），森林的构造子又装着**树**——两个类型互相引用。`with` 把它们绑成一个定义：

```coq
Inductive ntree (A : Type) : Type :=
| nnode : A -> nforest A -> ntree A
with nforest (A : Type) : Type :=
| nnil  : nforest A
| ncons : ntree A -> nforest A -> nforest A.
```

互引 Fixpoint 同理：`size` 算树的节点数，`size_f` 算森林的，两个 `with` 连体定义。

### 27.2 默认归纳原理：不能用

互引定义生成归纳原理时，Coq 每个类型只管自己：

```text
ntree_ind : forall (A : Type) (P : ntree A -> Prop),
  (forall (a : A) (n : nforest A), P (nnode a n)) ->
  forall n : ntree A, P n
```

看清问题了吗——`nnode` 的前提里**没有**「森林里的树满足 P」。归纳假设被整个吞掉，这个原理证不了任何与子树有关的性质。对 nforest 的默认原理同样残废。

### 27.3 Scheme：生成真正的互归纳原理

`Scheme` 命令让系统按你的要求造原理（书 14.1.6）：

```coq
Scheme ntree_mutind := Induction for ntree Sort Prop
with nforest_mutind := Induction for nforest Sort Prop.
```

得到的 `ntree_mutind` 带着**两个谓词** P（树）、P0（森林）：每个构造子一个前提，跨类型的 IH 全部在场：

```text
(forall a n, P0 n -> P (nnode a n)) ->
P0 nnil ->
(forall n, P n -> forall n0, P0 n0 -> P0 (ncons n n0)) ->
forall n, P n
```

用的时候 `induction t using ntree_mutind with (P0 := ...)`——P0 要**显式实例化**（它对森林说什么只有你知道），`as [...]` 模式给 IH 命名。示例 27.5 用它证明了「树的大小 = 拍平后的长度」：树的命题与森林的命题互为对偶，一次归纳同时收两份。

顺带一提 Scheme 的另一个用途：`Induction for ... Sort Prop` 生成**最大**归纳原理（Prop 谓词的完整版），系统默认给的是**精简**版——证明无关性裁剪过的（书 14.1.5 的 even_ind 对照）。

### 27.4 嵌套归纳：树与树列表

换个思路：子节点直接用标准库 list 装树，不再自造森林类型：

```coq
Inductive ltree (A : Type) : Type :=
| lnode : A -> list (ltree A) -> ltree A.
```

类型更省，代价升级成两个：

1. **默认归纳原理照样没用**（列表里的子树不产生 IH）；
2. **Scheme 也帮不了**——嵌套在别的类型里的递归，Scheme 视而不见（书 14.3.3）。

数节点都要新招：互 Fixpoint 跨 list 类型**会被守卫检查拒绝**（实测报 `Recursive call to lcount has principal argument equal to "t" instead of "l'"`）——解法是**内部不动点**：在树上的递归里嵌一个列表上的匿名 `fix`（示例 27.6 的 `lcount`）。归纳原理同样要手工造：`ltree_ind2` 用嵌套 fix 写出——这段代码值得逐行读，它是「归纳原理就是递归函数」的现场演示。

### 27.5 正性约束：不是什么归纳都能定义

```coq
Fail Inductive T_bad : Type := bad : (T_bad -> T_bad) -> T_bad.
```

被定义类型出现在构造子参数的**箭头左边**（负位置）会被拒。为什么这么严？接受这个类型就能造出 `t_omega`——一个 β-归约**永不停止**的项，强规范化没了，类型检查不可判定，甚至能推出 False（书 14.1.2.2 的完整推演）。反过来 `(nat -> T_bad) -> T_bad` 合法——只出现在箭头右边（严格正位置）就行。

### 27.6 本章坑位清单（实测）

1. **默认归纳原理对互引/嵌套类型是摆设**：先把 `Print xxx_ind.` 打出来看一眼有没有 IH，没有就上 Scheme 或手工原理；
2. **跨类型互 Fixpoint 被守卫拒绝**：ltree 式「树的列表」用内部不动点（嵌套匿名 fix）写；
3. **Scheme 管不了嵌套归纳**：类型递归出现在 list 等容器**里面**时，归纳原理只能手写（书 14.3.3 的 ltree_ind2 模板）；
4. **`induction ... using 自定义原理` 记得给 P0/Q 实例**：不指定的话元变量悬空，报错很隐晦；用 `as [a l IHl | | t IHt l IHl]` 命名 IH；
5. **正性检查报错位置难懂**：`Non strictly positive occurrence` 指的是「被定义类型出现在自己构造子的负位置」——改型的方向是把递归挪到箭头右边；
6. **`length_app` 的名字**：8.20 前 `app_length`，之后改名 `length_app`——旧资料先 Check。

---
上一章：[26 · 依赖类型与强规范](26-dependent.md) ｜ 下一章：[28 · 二叉搜索树实战](28-bst.md) ｜ 返回：[README](../README.md)
