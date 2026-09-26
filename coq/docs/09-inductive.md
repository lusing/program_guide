# 09 · 归纳类型：自定义数据

对应示例：`../examples/09_inductive.v`

### 9.1 Inductive：Coq 的「结构声明」

前面八章用的 nat、bool、list、option 全是 `Inductive` 声明的。现在自己写。语法骨架：

```coq
Inductive 类型名 : Type :=
| 构造子1 : 参数 -> ... -> 类型名
| 构造子2 : ...
.
```

每个构造子描述一种「造值的方式」。**类型的全部值 = 从构造子有限次组合能造出的一切**——这句话是归纳类型的语义，也是「归纳」二字的意思。

### 9.2 第一个：枚举

```coq
Inductive day : Type :=
  | monday    : day
  | tuesday   : day
  | wednesday : day
  | thursday  : day
  | friday    : day
  | saturday  : day
  | sunday    : day.

Definition next_workday (d : day) : day :=
  match d with
  | monday    => tuesday
  | tuesday   => wednesday
  | wednesday => thursday
  | thursday  => friday
  | friday    => monday
  | saturday  => monday
  | sunday    => monday
  end.

Example test_next :
  next_workday (next_workday saturday) = tuesday.
Proof. reflexivity. Qed.
```

七个构造子、零参数——枚举类型。对它的 match 必须覆盖七天（穷尽性），漏一天编译失败。类型安全到此为止已经超出多数语言：**非法日期（如 `fridayt`）根本无法书写**。

### 9.3 重新发明 bool 与 nat

构造子可以**带参数**，参数类型可以是正在定义的类型自己——递归由此而来：

```coq
Inductive mybool : Type :=
  | mytrue  : mybool
  | myfalse : mybool.

Inductive mynat : Type :=
  | mzero  : mynat
  | msucc  : mynat -> mynat.    (* 吃自己的值 —— 递归！ *)
```

`mybool` 就是 bool，`mynat` 就是 nat——标准库的 nat 不是黑魔法，是你二十行内能自己写出的东西。在 mynat 上定义函数与在 nat 上完全同构：

```coq
Fixpoint mydouble (n : mynat) : mynat :=
  match n with
  | mzero => mzero
  | msucc k => msucc (msucc (mydouble k))
  end.

Example mydouble_two : mydouble (msucc (msucc mzero))
                     = msucc (msucc (msucc (msucc mzero))).
Proof. reflexivity. Qed.
```

（注意 `Fixpoint` 不是 `Definition`——递归函数必须用前者，见第 10 章。）

### 9.4 类型参数：多态二叉树

```coq
Inductive btree (A : Type) : Type :=
  | leaf : btree A
  | node : btree A -> A -> btree A -> btree A.
```

`A` 是**类型参数**（list 的 `A` 同款）：整个声明对任意 A 成立。构造子默认**显式**携带 A——`node nat leaf 1 leaf` 很啰嗦，习惯上声明完立刻隐式化：

```coq
Arguments leaf {A}.
Arguments node {A} l a r.

Definition t1 : btree nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf).
Check (node leaf true leaf).      (* : btree bool —— 换个类型照常工作 *)
```

树上写函数，与链表同一套方法——match 递归构造子、子项上递归：

```coq
Fixpoint mirror {A : Type} (t : btree A) : btree A :=
  match t with
  | leaf => leaf
  | node l a r => node (mirror r) a (mirror l)
  end.

Example mirror_ex : mirror t1 = node (node leaf 3 leaf) 2 (node leaf 1 leaf).
Proof. reflexivity. Qed.
```

`mirror (mirror t) = t` 这类定律第 22 章的习题里会证。

### 9.5 自动生成的归纳原理

每个 Inductive 声明后，Coq 自动生成一个「归纳原理」——对该类型做归纳证明的许可证：

```coq
Check day_ind.
(* forall P : day -> Prop,
   P monday -> P tuesday -> ... -> P sunday ->
   forall d : day, P d *)
```

读法：要证「P 对每个 day 成立」，只需对七个构造子各证一次 P——枚举的「归纳」就是穷举。

```coq
Check btree_ind.
(* forall (A : Type) (P : btree A -> Prop),
   P leaf ->
   (forall b, P b -> forall a, forall b0, P b0 -> P (node b a b0)) ->
   forall b, P b *)
```

树的版本正是数学归纳法的结构推广：**证叶子 + （假设左右子树成立 ⇒ 证节点）⇒ 证一切树**。第 12 章 `induction` 策略幕后调用的就是这些自动生成的原理。现在只需记住：**声明即免费获得归纳原理**，这是 Inductive 与普通「struct/class」的本质区别。

### 9.6 构造子的三大纪律

1. **单射**：`S x = S y` 则 `x = y`（`node l a r = node l' a' r'` 则三分量各相等）；
2. **不相交**：`monday ≠ tuesday`、`O ≠ S k`、`nil ≠ cons ...`——不同构造子造的值永不相等；
3. **可判别**：任给一个值，它的构造子是哪个**可判定**——match 与 discriminate 由此成立。

第三条的威力预览——从「不同构造子相等」这个**矛盾前提**推出**任何结论**：

```coq
Example day_absurd : monday = tuesday -> 1 = 2.
Proof.
  intros H.
  discriminate H.
Qed.
```

`discriminate` 发现 H 的两边是不同构造子，逻辑系统内爆炸，任何目标随即成立（爆炸原理）。第 13 章正式讲。

### 9.7 本章坑位清单（实测）

1. **构造子的类型参数默认显式**：不写 `Arguments leaf {A}.` 就得写 `leaf nat`——自定义完立刻隐式化是习惯动作；
2. **递归函数写成 `Definition`**：报「mydouble 未在环境中找到」之类的引用错误——真正原因是 `Definition` 不允许递归，名字根本没注册；用 `Fixpoint`；
3. **构造子名全局唯一**：与字段名一样（第 6 章坑 2），`leaf` 定义过一次后第二个类型不能再用；
4. **声明末尾的句点**：`Inductive ... .` 的句点在最后一个构造子之后，漏了整段报语法错。

---
上一章：[08 · 列表](08-lists.md) ｜ 下一章：[10 · 递归函数：Fixpoint 与终止性](10-fixpoint.md) ｜ 返回：[README](../README.md)
