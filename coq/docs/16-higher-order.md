# 16 · 高阶函数及其证明

对应示例：`../examples/16_higher_order.v`

### 16.1 函数是一等值

前几章已经反复出现「函数当参数传」（map、filter、fold），现在正式立牌坊：**函数是值**——可以存进变量、当参数传、当结果返回、放进数据结构。以函数为参数/结果的函数叫**高阶函数**。

```coq
Definition apply_twice {A : Type} (f : A -> A) (x : A) : A :=
  f (f x).

Compute (apply_twice (fun n => n * 2) 5).   (* = 20 *)
```

高阶函数是复用的基本单位：`map` 一个定义覆盖「对每种数据各做一件事」的无限需求。而**组合**是高阶函数的代数：

```coq
Definition compose {A B C : Type} (f : B -> C) (g : A -> B) : A -> C :=
  fun x => f (g x).
```

「先 g 后 f」打包成一个新函数——数学记号 f∘g 的可执行版。

### 16.2 高阶函数的定律

高阶函数不止能跑，还能**证**。三条经典定律（示例 16 全部证毕）：

```coq
(* 融合律：两次 map 可合一次 *)
map_compose : map (compose f g) xs = map f (map g xs)

(* 长度保持：map 不丢不重 *)
map_length  : length (map f xs) = length xs

(* 幂等律：筛过的再筛不变 *)
filter_idem : filter p (filter p xs) = filter p xs
```

以融合律为例看证明——你期待的新东西一件都没有：

```coq
Theorem map_compose : forall (A B C : Type)
                                 (f : B -> C) (g : A -> B) (xs : list A),
  map (compose f g) xs = map f (map g xs).
Proof.
  intros A B C f g xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

对 xs 归纳、基例计算、步例用 IH——与第 12 章证 `n + 0 = n` 的剧本**一字不差**。「函数当参数」完全不改变证明形状，因为归纳发生在列表的结构上，而函数对结构一无所知。这是本章的核心信息：**数据决定证明，函数只是数据上的乘客**。

### 16.3 destruct eqn：对付 filter 的标准姿势

`filter_idem` 的证明藏着一个值得单说的技术：

```coq
Theorem filter_idem : forall (A : Type) (p : A -> bool) (xs : list A),
  filter p (filter p xs) = filter p xs.
Proof.
  intros A p xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. destruct (p x) eqn:E.
    + simpl. rewrite E. rewrite IH. reflexivity.
    + exact IH.
Qed.
```

麻烦在于 `filter` 的定义里有 `if p x`：`simpl` 展开后 `p x` 卡在判断里（p 是变量，算不出）。`destruct (p x) eqn:E` 按它的值分情况——但注意**展开内层 filter 时 `if p x` 会再次出现**（第一次 destruct 替换的是当时可见的那处），所以再 `simpl` 暴露新的 `if` 后，要用 `E : p x = true` 来 `rewrite E` 消掉它。这套「**destruct eqn → simpl → rewrite E**」的连环是所有涉及 bool 判断的函数（filter、find、partition……）证明的通用解法，第 23 章排序证明会再次依赖它。

### 16.4 用 fold 造一切

`fold_right`（第 8 章）的威力值得再强调——它是一切「遍历攒结果」的归一形式：

```coq
Theorem fold_cons : forall (A : Type) (xs : list A),
  fold_right (fun x acc => x :: acc) [] xs = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

把 `cons` 本身当叠法，fold 就退化成恒等；换 `Nat.add` 是求和，换 `orb` 是存在判断，换 `(fun x acc => if p x then x :: acc else acc)` 是手写 filter。**理解一个 fold，等于理解一族函数**——这是函数式编程的复利。

### 16.5 本章坑位清单（实测）

1. **filter 展开后 `if` 复活**：`destruct (p x)` 一次不够，`eqn:E` + `rewrite E` 才能收干净（16.3 的完整演示）；
2. **对「函数相等」想当然**：`fun x => x + 0` 与 `fun x => x` 在 Coq 里**不能互推为相等**（函数外延性不是内建公理）——但两条**定律**（对任意输入结果相同）照证不误，本教程始终证定律；
3. **compose 的参数顺序**：`compose f g` 是先 g 后 f（与数学 f∘g 一致），写成「先 f 后 g」会证出反向定律，名字起清楚很重要。

---
上一章：[15 · 谓词逻辑与 reflect](15-predicates.md) ｜ 下一章：[17 · Option：安全建模](17-option.md) ｜ 返回：[README](../README.md)
