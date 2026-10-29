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

`Scheme` 命令让系统按你的要求造原理：

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

顺带一提 Scheme 的另一个用途：`Induction for ... Sort Prop` 生成**最大**归纳原理，系统默认给的是**精简**版。差别在哪？拿 `even`（偶数谓词）实测对照——精简版 `even_ind` 的谓词是 `P : nat -> Prop`，只看索引：

```text
even_ind : forall P : nat -> Prop,
  P 0 -> (forall n, even n -> P n -> P (S (S n))) ->
  forall n, even n -> P n
```

`Scheme even_max := Induction for even Sort Prop.` 造出的最大版，谓词多一个参数——**证据本身**：

```text
even_max : forall P : forall n : nat, even n -> Prop,
  P 0 even_O ->
  (forall (n : nat) (e : even n), P n e -> P (S (S n)) (even_SS n e)) ->
  forall (n : nat) (e : even n), P n e
```

也就是说默认原理假设「证明无关」：命题只谈 `n`，不谈证据 `e` 长什么样；要证「所有证据都有某种形状」之类的命题，就得上最大版。

### 27.4 嵌套归纳：树与树列表

换个思路：子节点直接用标准库 list 装树，不再自造森林类型：

```coq
Inductive ltree (A : Type) : Type :=
| lnode : A -> list (ltree A) -> ltree A.
```

类型更省，代价是默认归纳原理照样没有列表中各子树的 IH。数节点也会遇到新限制：互 Fixpoint 跨 list 类型会被守卫检查拒绝，解法是在树上的递归里嵌一个列表上的匿名 `fix`（示例 27.6 的 `lcount`）。归纳原理同样可用嵌套 fix 手工构造；`ltree_ind2` 是「归纳原理就是递归函数」的现场演示。

### 27.5 当前 Rocq 的兼容写法：显式谓词与嵌套归纳原理

旧资料可能使用 `Scheme All for list.` 自动注册「每个元素都满足 P」的谓词，或用 `#[schemes=...]` 控制方案生成；当前实测环境不接受这两种语法。兼容做法是把谓词直接写出来：

```coq
Inductive list_all (A : Type) (PA : A -> Type) : list A -> Type :=
| nil_all : list_all A PA []
| cons_all : forall a, PA a -> forall l, list_all A PA l ->
             list_all A PA (a :: l).

Inductive rose : Type :=
| node : list rose -> rose.
```

默认 `rose_ind` 的 `node` 前提仍只有 `P (node l)`，没有子树 IH。因此示例仿照 `ltree_ind2` 构造 `rose_ind2`：树上的递归负责产生 `P r`，内部列表递归负责产生 `Q l`，两者在 `cons` 分支把 `P t` 与 `Q tl` 合成 `Q (t :: tl)`。使用 `induction ... using rose_ind2 with (Q := ...)` 即可得到完整归纳假设。

消费 `list_all` 则是普通的列表归纳：空列表直接结束，`cons` 分支用 `inversion` 拆开 `cons_all`，分别取得头部元素的性质与尾部列表的性质。示例 27.8 的 `rcount_pos` 和 `rcount_node_ge` 给出了完整证明。

### 27.6 正性约束：不是什么归纳都能定义

```coq
Fail Inductive T_bad : Type := bad : (T_bad -> T_bad) -> T_bad.
(* Error: Non strictly positive occurrence of "T_bad" in
   "(T_bad -> T_bad) -> T_bad". （9.3.0 实测原文） *)
```

被定义类型出现在构造子参数的**箭头左边**（负位置）会被拒。为什么这么严？假设放行，三步就能造出不停机的项：

1. 构造子 `bad : (T_bad -> T_bad) -> T_bad` 把函数包成值；归纳类型的匹配给出反向拆包 `un t := match t with bad f => f end`，类型 `T_bad -> (T_bad -> T_bad)`，满足 `un (bad f) = f`——包装和解包都在手；
2. 定义自应用项 `omega := bad (fun x => un x x)`：内层 `fun x => un x x` 的类型恰是 `T_bad -> T_bad`，类型检查顺利通过；
3. 看归约：`un omega omega` 一步 ι-归约成 `(fun x => un x x) omega`，再一步 β-归约又回到 `un omega omega`——**永不停止**。

强规范化是类型安全的承重墙：它塌了，类型检查不可判定（等价性要靠归约判，归约不停就判不了），把这套搬进 Prop 还能直接推出 `False`。反过来 `(nat -> T_bad) -> T_bad` 合法——`T_bad` 只出现在箭头右边（严格正位置），凑不齐自应用的材料。

### 27.7 本章坑位清单（实测）

1. **默认归纳原理对互引/嵌套类型是摆设**：先把 `Print xxx_ind.` 打出来看一眼有没有 IH，没有就上 Scheme 或手工原理；
2. **跨类型互 Fixpoint 被守卫拒绝**：ltree 式「树的列表」用内部不动点（嵌套匿名 fix）写；
3. **嵌套归纳先检查 IH**：当前 Rocq 不接受旧资料的 `Scheme All` 与 `schemes` 属性；显式定义 `list_all`，并手写 `ltree_ind2`/`rose_ind2` 式原理，再用 `induction ... using`；
4. **`induction ... using 自定义原理` 记得给 P0/Q 实例**：不指定的话元变量悬空，报错很隐晦；用 `as [a l IHl | | t IHt l IHl]` 命名 IH；
5. **正性检查报错位置难懂**：`Non strictly positive occurrence` 指的是「被定义类型出现在自己构造子的负位置」——改型的方向是把递归挪到箭头右边；
6. **`length_app` 的名字**：8.20 前 `app_length`，之后改名 `length_app`——旧资料先 Check。

---
上一章：[26 · 依赖类型与强规范](26-dependent.md) ｜ 下一章：[28 · 二叉搜索树实战](28-bst.md) ｜ 返回：[README](../README.md)
