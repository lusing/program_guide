# 11 泛等公理 —— 等价就是相等

> 本章代码：[`examples/11_univalence.v`](../examples/11_univalence.v)

这是 HoTT 的心脏。泛等公理（univalence axiom）用一句话说完：

> 对任意类型 `A B`，**`(A = B) ≃ (A ≃ B)`**。两个类型相等，当且仅当它们等价。

这一章解释这句话的精确含义、它为什么合理、它带来的第一个震撼结论（`Type` 不是集合），
以及日常使用它的方式。

## 11.1 一个免费的方向：相等给出等价

先看不需要公理的那一半。若 `p : A = B`，沿 `p` 搬运（以 `idmap : Type -> Type` 为族）
给出 `transport idmap p : A -> B`，它是等价——路径归纳：`p = 1` 时它就是恒等。

```coq
Check equiv_path.                    (* forall A B : Type, A = B -> A <~> B *)
Print Assumptions equiv_path.        (* Closed under the global context *)
```

这和第 07 章的"路径与等价构成平行的群胚"相呼应：`equiv_path` 是从路径群胚到等价群胚的
一个自然的函子。

## 11.2 泛等：这个方向是等价

泛等公理断言：`equiv_path A B` 本身是等价。

```coq
Class Univalence : Type0.
Axiom isequiv_equiv_path : Univalence -> forall A B : Type, IsEquiv (equiv_path A B).
```

于是有逆映射，把等价变成路径：

```coq
Check path_universe_uncurried.   (* A <~> B -> A = B *)
Check path_universe.             (* forall f : A -> B, IsEquiv f -> A = B *)
Check equiv_path_universe.       (* (A <~> B) <~> (A = B) *)
```

两者互逆：

```coq
Check eta_path_universe.          (* path_universe (equiv_path p) = p *)
Check equiv_path_path_universe.   (* equiv_path (path_universe f) = f *)
```

和函数外延一样，泛等做成空类型类 `Univalence`，需要它的定理写 `Context `{Univalence}`，
或者导入 `HoTT.Axioms.Univalence` 拿到全局实例 `univalence_axiom`。

## 11.3 它为什么合理

**从数学实践看**：数学家一直把同构的结构当成相同的——"ℝ 的完备有序域在同构意义下唯一"
之后，就放心地说"**那个**实数域"。泛等把这个习惯变成了形式系统里的定理：
等价的类型字面上相等，所以关于一个类型证明的任何性质自动对等价的类型成立（第 18 章）。

**从同伦论看**：把 `Type` 想成"所有空间构成的空间"。在这个空间里，两个点（空间）
之间的一条路径应该是什么？同伦论的答案是同伦等价。泛等说：`Type` 的路径结构
就是等价结构。它让类型论的 `Type` 真的像一个"分类空间"（对象分类子）。

**从一致性看**：泛等在 Voevodsky 的单纯集模型里成立，所以加上它不会导致矛盾。
它和经典逻辑里的排中律相容，但与 UIP 不相容（下一节）。

## 11.4 第一个后果：`Type` 不是集合

如果 `Type` 是集合，那么 `Bool = Bool` 的任意两条路径相等。但泛等给出两条不同的路径：
一条来自恒等等价，一条来自取反。

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition negb_path : Bool = Bool := path_universe negb_equiv.
```

要证 `negb_path ≠ 1`，就用第 05 章的套路：找一个区分它们的"观测"。
沿 `negb_path` 搬运 `true` 得到 `false`，沿 `1` 搬运得到 `true`，而 `true ≠ false`。

```coq
Definition negb_path_neq_1 : negb_path <> 1.
Proof.
  intro h.                     (* 假设 h : negb_path = 1 *)
  apply true_ne_false.         (* 目标：true = false *)
  exact ((1 @ (ap (fun p : Bool = Bool => transport idmap p true) h)^)
           @ transport_path_universe negb_equiv true).
Defined.
```

证明里两条路径接起来：

- `ap (fun p => transport idmap p true) h : transport idmap negb_path true = transport idmap 1 true`，
  右边按定义就是 `true`；取逆得 `true = transport idmap negb_path true`；
- `transport_path_universe negb_equiv true : transport idmap negb_path true = negb_equiv true`，
  右边是 `false`。

于是 `true = false`。库里的现成版本叫 `not_hset_Type`。

这个结论的意义：**宇宙 `Type` 有非平凡的路径结构**。它至少是 1-型（事实上任何层级都不是——
`Type` 里有任意高阶的同伦）。于是"两个类型相等"这件事本身有内容：
`Bool = Bool` 恰好有两个元素，对应 `Bool` 的两个自同构。

## 11.5 泛等的计算律

泛等是公理，`path_universe` 不会归约。它唯一的"计算规则"是搬运的行为：

```coq
Check transport_path_universe.
(* transport idmap (path_universe f) z = f z *)
Check transport_path_universe_V.
(* transport idmap (path_universe f)^ z = f^-1 z *)
```

读法：**沿"由等价 `f` 造出的路径"搬运，就是作用 `f`。** 这是泛等与 transport 的接口，
库里所有关于 `path_universe` 的推理最终都化到这两条上。第 13 章与第 24 章会一再使用。

其他行为律把路径运算和等价运算对应起来：

| 引理 | 内容 |
|---|---|
| `path_universe_1` | `path_universe 1 = 1` |
| `path_universe_V` | `path_universe f^-1 = (path_universe f)^` |
| `path_universe_compose` | `path_universe (g oE f) = path_universe f @ path_universe g` |

这正是说 `path_universe` 是群胚之间的函子——第 07 章的那张对照表，现在合为一张。

## 11.6 对等价做归纳

有了泛等，第 07 章的 `equiv_ind` 升级成真正的"等价归纳"：
要对所有 `V` 和所有 `w : U <~> V` 证明 `P V w`，只需对 `(U, 1)` 证明。

```coq
Check equiv_induction.
(* forall P : forall V, U <~> V -> Type, P U 1 -> forall V (w : U <~> V), P V w *)
```

证明思路：把 `w` 变成路径 `path_universe w`，对路径做归纳，再变回来。
这意味着**关于等价的所有性质，只要在恒等等价上成立就处处成立**——
和路径归纳一样强大，也一样要求终点自由。

## 11.7 结构沿等价搬运（预告）

泛等最实用的后果：任何 `S : Type -> Type` 定义的结构都能沿等价搬运。

```coq
Check univalent_transport.   (* forall (S : Type -> Type) X Y, X <~> Y -> S X -> S Y *)
```

`S X` 可以是"X 上的一个群结构""X 是集合""X 上有一个判定相等的算法"——
只要 `X ≃ Y`，`Y` 就自动拥有同样的东西。第 18 章展开这件事。

## 小结

- `equiv_path : A = B -> A <~> B` 零公理；泛等说它是等价，逆映射是 `path_universe`。
- 泛等让 `Type` 的路径结构等于等价结构：数学里"同构即相同"的形式化。
- `Type` 不是集合：`Bool = Bool` 有两条不同的路径（恒等与取反）。
- 唯一的计算律：`transport idmap (path_universe f) z = f z`。
- 等价归纳：关于等价的性质在恒等等价上成立即可。

## 常见误区

1. **以为泛等让所有等价的类型"变成同一个"**。不是。`Bool` 和 `Bool` 之间有两条路径，
   路径是有内容的；泛等增加了相等的证据，而不是抹平差别。
2. **期待 `path_universe` 能计算**。它是公理，`simpl`、`Compute` 都不会动它；
   只能用 `transport_path_universe` 系列引理改写。
3. **混淆 `path_universe` 与 `path_universe_uncurried`**。前者接受函数加 `IsEquiv` 实例，
   后者接受 `A <~> B`。
4. **以为泛等与排中律冲突**。不冲突；泛等与命题层面的排中律相容。它冲突的是 UIP。

## 练习

1. 用 `path_universe` 造出 `Bool + Bool = Bool * Bool` 的一条路径。
2. 证明 `IsHSet Type -> Empty`，直接复用 `negb_path_neq_1`。
3. 思考：`Unit = Unit` 有几个元素？`Bool = Bool` 有几个？`nat = nat` 呢？
   （后者在泛等下等价于 `nat` 的所有自同构构成的类型。）

---

**上一章**：[10 函数外延](10-funext.md)
**下一章**：[12 HIT 入门：区间](12-hit-interval.md)
