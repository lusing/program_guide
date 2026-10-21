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

类型更省，代价升级成两个：

1. **默认归纳原理照样没用**（列表里的子树不产生 IH）；
2. **9.2 之前 Scheme 也帮不了**——嵌套在别的类型里的递归，Scheme 视而不见；9.2 起有官方解法（Scheme All，见 27.5），手写原理降级为备选手艺。

数节点都要新招：互 Fixpoint 跨 list 类型**会被守卫检查拒绝**（实测报 `Recursive call to lcount has principal argument equal to "t" instead of "l'"`）——解法是**内部不动点**：在树上的递归里嵌一个列表上的匿名 `fix`（示例 27.6 的 `lcount`）。归纳原理在 9.2 之前同样要手工造：`ltree_ind2` 用嵌套 fix 写出——这段代码值得逐行读，它是「归纳原理就是递归函数」的现场演示，也是忘记注册 All 时的兜底手艺。

### 27.5 9.2 新特性：Scheme All 让嵌套归纳原理自动化

9.2 把上一节的手工活收编了。机制分两半：先给**容器类型**注册一个 All 方案——「每个元素都满足 P」的谓词：

```coq
Scheme All for list.
```

```text
list_all : forall A : Type, (A -> Type) -> list A -> Type

(* Print list_all 实测：两个构造子 *)
nil_all  : list_all A PA []
cons_all : forall a, PA a -> forall l, list_all A PA l -> list_all A PA (a :: l)
```

然后**再定义**嵌套类型（顺序很关键）：

```coq
Inductive rose : Type :=
| node : list rose -> rose.
```

9.2 自动生成的 `rose_ind` 直接带上嵌套 IH（实测）：

```text
rose_ind : forall P : rose -> Prop,
  (forall l : list rose, list_all rose P l -> P (node l)) ->
  forall r : rose, P r
```

`node` 前提里的 `list_all rose P l` 就是「列表里每棵子树都满足 P」——上一节手写 `ltree_ind2` 才有的东西，现在白送。`induction r as [l IH]` 之后 `IH : list_all rose (fun r => P r) l` 直接躺在上下文里；消费它就是普通的列表归纳，cons 分支用 `inversion` 拆开 `cons_all` 拿到头和尾的证明（示例 27.8 的 `rcount_node_ge` 是完整示范）。

忘了先注册会怎样？定义 `rose` 时立刻收到警告，且生成的原理退回残废版（示例里 `ltree` 就是活标本，编译时能看到）：

```text
Warning: rose is nested using list. No scheme for list is registered as All.
It can be generated using command "Scheme All" e.g. "Scheme All for list.".
[register-all,automation,default]
```

配套小开关：`#[schemes=none]` 让定义时**一个方案都不生成**（连 `_ind` 都没有，给只需要类型本身的场景用），`#[schemes=default]` 是默认行为（示例 27.8 末尾有对照实测）。

```coq
#[schemes=none]
Inductive quietly : Type := q1 : quietly.
Fail Check quietly_ind.   (* 确实没生成 *)
```

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
3. **嵌套归纳先注册 All 再定义类型（9.2 起）**：`Scheme All for list.` 放前面，自动生成的原理自带 `list_all` 形 IH；忘了注册会吃 `register-all` 警告且原理退成残废版——9.2 之前的办法是手写 `ltree_ind2` 式原理 + `induction ... using`；
4. **`induction ... using 自定义原理` 记得给 P0/Q 实例**：不指定的话元变量悬空，报错很隐晦；用 `as [a l IHl | | t IHt l IHl]` 命名 IH；
5. **正性检查报错位置难懂**：`Non strictly positive occurrence` 指的是「被定义类型出现在自己构造子的负位置」——改型的方向是把递归挪到箭头右边；
6. **`length_app` 的名字**：8.20 前 `app_length`，之后改名 `length_app`——旧资料先 Check。

---
上一章：[26 · 依赖类型与强规范](26-dependent.md) ｜ 下一章：[28 · 二叉搜索树实战](28-bst.md) ｜ 返回：[README](../README.md)
