# 29 · 余归纳与无限数据

对应示例：`../examples/29_coinductive.v`

### 29.1 在有限的计算机里装无限的对象

证明助手最迷人的一点：能对**真正无限的对象**做推理。通信、能源、交通系统的执行是无限的——无限执行不是异常，是常态。Coq 用**余归纳类型**（coinductive type）接住这类模型。

归纳与余归纳是一对对偶：

| | 归纳 Inductive | 余归纳 CoInductive |
|---|---|---|
| 集合直觉 | 构造子**有限次**应用的最小集合 | 允许**无限**应用的最大集合 |
| 递归函数 | 消耗数据（Fixpoint，定义域） | 生产数据（CoFixpoint，值域） |
| 推理原理 | 归纳法（induction） | 余归纳法（coinduction，cofix） |

本章主角是**惰性列表**——既能有限（LNil 收尾）也能无限（永远 LCons）的序列：

```coq
CoInductive LList (A : Type) : Type :=
| LNil  : LList A
| LCons : A -> LList A -> LList A.
```

观察函数（head/tail/nth）照旧用 Fixpoint——递归在 nat 或结构上，每次只消耗有限前缀，没问题。

### 29.2 CoFixpoint：有限表达式，无限对象

「从 n 开始的所有自然数」没法手写，也没法用 Fixpoint（`from (S n)` 里 S n 不是 n 的子项，守卫拒绝）。CoFixpoint 合法：

```coq
CoFixpoint from (n : nat) : LList nat := LCons n (from (S n)).
CoFixpoint LAppend {A} (u v : LList A) : LList A :=
  match u with
  | LNil => v
  | LCons a u' => LCons a (LAppend u' v)
  end.
```

计算演示（示例 29.2 全部实测）：`LNth 19 (from 17) = Some 36`；`LAppend` 先吃掉有限段再接上无限流。

**guard 约束**：CoFixpoint 的递归调用必须出现在（目标余归纳类型的）**构造子的参数位**。两条经典违规（示例 29.3 用 Fail 实测）：

- `else` 分支直接返回递归调用——过滤全 false 的流时 head 发散；
- 递归调用出现在 match 的 scrutinee 位——判断是否终止需要复杂的分析，系统直接拒绝。

guard 保证每层递归至少产出一个构造子，所以 match 一个余归纳值所需的开销永远有限——**计算仍然处处终止**。

### 29.3 展开技术：分解引理

一个意外：`simpl` 不展开余递归（`Eval simpl in (repeat 33)` 原样返回）。要按需展开，用 Paulin-Mohring 的经典技巧——包一层恒等函数：

```coq
Definition LList_decompose {A} (l : LList A) : LList A :=
  match l with LNil => LNil | LCons a l' => LCons a l' end.

Lemma LList_decomposition : forall {A} (l : LList A), l = LList_decompose l.
```

`LList_decompose` 函数上是恒等，操作上逼 cofix 展开一步。用它证一族**展开引理**：

```coq
Lemma from_unfold     : forall n, from n = LCons n (from (S n)).
Lemma LAppend_LCons   : forall (A : Type) (a : A) (u v : LList A),
  LAppend (LCons a u) v = LCons a (LAppend u v).
```

证明套路是 `rewrite (LList_decomposition (要展开的项))` 再化简。**注意 `at 1`**：`repeat a = LCons a (repeat a)` 两侧都含 `repeat a`，不限定出现位置会两边一起换、越换越多（实测翻车点）。

### 29.4 余归纳谓词与 cofix 策略

「序列是无限的」本身是一个**余归纳谓词**——它的证明可以是无限项：

```coq
CoInductive Infinite (A : Type) : LList A -> Prop :=
| Infinite_cons : forall (a : A) (l : LList A),
    Infinite A l -> Infinite A (LCons a l).
```

证 `forall n, Infinite (from n)` 用 `cofix` 策略：引入余递归假设 H，rewrite 展开后把 H 喂给构造子。两条纪律：

- **H 只能出现在构造子内部**（guard 对证明同样生效）；
- 用过 `assumption`/`auto` 等自动策略后敲一下 **`Guarded.`** 命令当场检查——unguarded 的证明要拖到 Qed 才炸，中间还自以为证完了（书 13.6.3 的翻车实录）。

一个概念陷阱：把 Infinite 写成 `Inductive`（而非 CoInductive）会得到一个**永不可满足**的谓词——归纳版本要求有限次构造子应用，而它的唯一构造子永远往上递归。关键字选错，谓词直接废掉。

顺带收获：普通谓词 `Finite`（有限序列）照样用 Inductive 定义在余归纳类型上——inversion、归纳法这些老工具都还工作（书 13.5）。

### 29.5 互模拟：无限对象的「相等」

`eq` 对无限对象太强：`from 0` 和 `LAppend (LCons 0 LNil) (from 1)` 在每个位置的值都相同，但构造不同，相等证不出来。降一档用**互模拟（bisimulation）**：

```coq
CoInductive bisimilar (A : Type) : LList A -> LList A -> Prop :=
| bisim_nil  : bisimilar A LNil LNil
| bisim_cons : forall (a : A) (l l' : LList A),
    bisimilar A l l' -> bisimilar A (LCons a l) (LCons a l').
```

「每个位置都相同」的有限/无限证明。配套证明技术与数据那边完全对称：`cofix` 造无限证明。两个战果（示例 29.6）：

```coq
Theorem LAppend_assoc : ... bisimilar (LAppend u (LAppend v w))
                              (LAppend (LAppend u v) w).
Theorem infinite_absorb : Infinite u -> bisimilar u (LAppend u v).
```

LAppend 结合律——等号版对无限对象证不动，互模拟版 cofix 一气呵成；无限流吸收任何后缀，同样是余归纳的招牌结论。

### 29.6 本章坑位清单（实测）

1. **关键字是 `CoInductive`/`CoFixpoint`**（大写 I/F）：写成 `Coinductive` 报 `illegal begin of vernac`，大小写敏感；
2. **定义体内递归出现要显式带参数**：构造子里写 `Infinite l` 会被当成「把 l 当类型参数 A」——参数要么写全要么定义后 `Arguments ... {A}`；
3. **`simpl` 不展开 cofix**：用分解引理 + rewrite 的展开套路（29.3）；
4. **rewrite 两侧同形会循环展开**：`at 1` 限定出现位置；
5. **Hint Rewrite 注册含隐式 Type 参数的引理**：`Cannot infer the implicit parameter A`——把 A 改成显式参数再注册；
6. **cofix 证明里 auto 乱用 H**：unguarded 直到 Qed 才报错——中途 `Guarded.` 自检；
7. **Infinite 误写成 Inductive**：谓词永不可满足，定理看着证完实际全是空谈（能证 `~ Infinite LNil` 但什么都证不出来正着）。

---
上一章：[28 · 二叉搜索树实战](28-bst.md) ｜ 下一章：[30 · 一般递归](30-general-recursion.md) ｜ 返回：[README](../README.md)
