# 18 泛等的应用 —— 结构沿等价搬运

> 本章代码：[`examples/18_univalence_apps.v`](../examples/18_univalence_apps.v)

第 11 章确立了泛等：`A ≃ B` 给出 `A = B`。这一章回答"那又怎样"。
答案是数学实践里最常用却最少被形式化的原则——**同构的东西有相同的性质**——
在 HoTT 里成了一行代码。不用再为每种结构、每种性质分别证明"同构保持它"。

本章全程需要泛等：`Require Import HoTT.Axioms.Univalence.`

## 18.1 第一原则

任何 `S : Type -> Type` 都可以看成"类型上的一种结构或性质"：`S X` 可以是
"`X` 是集合""`X` 上的一个二元运算""`X` 上的群结构""`X` 可判定"。

若 `e : X ≃ Y`，泛等给出 `path_universe e : X = Y`，然后 `transport S` 把 `S X` 搬到 `S Y`：

```coq
Check univalent_transport.   (* forall (S : Type -> Type) X Y, X <~> Y -> S X -> S Y *)
```

就这么简单。这一步的代价只有一个：公理。没有泛等，`S X -> S Y` 对一般的 `S`
是**证不出来**的——类型论内部不知道"等价的类型表现一致"。

## 18.2 性质的搬运：截断层级

最常用的 `S` 是截断层级。等价保持"是集合""是命题"：

```coq
Check istrunc_equiv_istrunc.   (* A <~> B -> IsTrunc n A -> IsTrunc n B *)

Definition hset_preserved {A B : Type} (e : A <~> B) `{IsHSet A} : IsHSet B
  := istrunc_equiv_istrunc (n := 0) A e.
```

有趣的是，这一条其实**不需要泛等**——等价保持路径结构，所以直接就能证。
但它展示了原则的形态。对任意的、没有特殊结构的 `S`，就必须用 `univalent_transport`。

## 18.3 结构的搬运：把 `Bool` 的运算搬到任意两元素类型上

给任意 `X` 和 `e : Bool ≃ X`，`X` 上自动有一个"取反"：

```coq
Definition transported_negb (X : Type) (e : Bool <~> X) : X <~> X
  := (e oE negb_equiv) oE (equiv_inverse e).
```

即 `e ∘ negb ∘ e⁻¹`——**共轭**。合取也一样：

```coq
Definition andb_transported (X : Type) (e : Bool <~> X) : X -> X -> X
  := fun x y => e (andb (e^-1 x) (e^-1 y)).
```

取 `X := Bool`、`e := 1`，它们退化回原来的 `negb` 和 `andb`：

```coq
Compute transported_negb Bool (equiv_idmap Bool) true.   (* = false *)
Compute andb_transported Bool (equiv_idmap Bool) true false.   (* = false *)
```

注意这两个定义直接用复合写出，没有经过 `path_universe`，所以能 `Compute`。
它们是搬运的"手工版"。泛等的作用是**证明手工版就是 `transport` 给出的那个**：

```coq
Check transport_arrow_toconst_path_universe.
(* transport (fun E => E -> A) (path_universe w) f = fun x => f (w^-1 x) *)
```

即沿泛等路径搬运一个函数，就是预复合逆等价。这正是共轭。
对于更复杂的 `S`（函数类型嵌套、Σ 类型），`transport` 沿泛等路径的行为由一组
`transport_*_path_universe` 引理逐层给出。

## 18.4 结构同一性原理

上面的例子是**结构同一性原理**（Structure Identity Principle，SIP）的雏形。完整表述：

> 对一类"结构化类型"（比如群、环、偏序集），两个结构化类型相等，
> 当且仅当它们之间存在保结构的等价（同构）。

HoTT 书第 9.8 节证明了它对所有"标准记号结构"成立。意义在于：
**数学里的"在同构意义下唯一"在 HoTT 里就是"唯一"**。不需要再说"实数域在同构意义下唯一"——
它就是唯一的，因为同构的实数域相等。

库里的 `univalent_transport` 搬的是数据；SIP 还要保证搬运后**定律**也成立
（比如结合律）。做法是把定律本身也写成 `Type -> Type` 的谓词，一并搬运。
这些工作是机械的，泛等保证它们总能完成。

## 18.5 `ap` 作用在泛等路径上

把等价变成路径后，可以让类型函子（比如 `fun Z => A * Z`）作用在这条路径上。
结果应该和"让函子作用在等价上"一致：

```coq
Check ap_prod_l_path_universe.
(* equiv_path (A * B) (A * C) (ap (prod A) (path_universe f)) = equiv_functor_prod_l f *)
Check ap_equiv_path_universe.
(* equiv_path (A <~> B) (A <~> C) (ap (Equiv A) (path_universe f)) = equiv_functor_equiv 1 f *)
```

读法：左边把等价 `f` 变成路径，用 `ap` 挪到乘积上，再用 `equiv_path` 变回等价；
右边是直接构造的 `equiv_functor_prod_l f`。两者相等。
这是"`ap` 对路径的函子性"与"类型构造器对等价的函子性"（第 14 章）之间的翻译。
搬运代数结构时需要它们来验证搬运的结果确实是预期的。

## 18.6 为什么不能计算，以及怎么办

泛等是公理。`path_universe e` 不会归约，于是 `transport S (path_universe e) s` 也卡住。
这是泛等的已知代价：**HoTT 加泛等后失去了规范性**（canonicity）——
存在不能归约成构造子形式的闭项。（立方类型论解决了这个问题，但那是另一个系统。）

实践中的应对：所有关于 `path_universe` 的推理都通过一组行为律进行，而不靠计算：

| 引理 | 内容 |
|---|---|
| `transport_path_universe` | `transport idmap (path_universe f) z = f z` |
| `transport_idmap_path_universe` | 同上的函数形式 |
| `eta_path_universe` | `path_universe (equiv_path p) = p` |
| `path_universe_transport_idmap` | `path_universe (transport idmap p) = p` |
| `transport_arrow_toconst_path_universe` | 函数类型上的搬运是共轭 |

规律：**凡是卡在 `path_universe` 上的表达式，`simpl` 都救不了。想清楚要在哪一层化开，
然后找名字带 `_path_universe` 的引理。**

## 18.7 一个更大的图景

泛等的三类应用：

1. **搬运**（本章）：性质和结构沿等价自动传递。
2. **计算路径空间**（第 13 章）：`Type` 里的路径就是等价，于是可以用自等价造覆叠。
3. **高阶结构**（第 20 章）：范畴的对象之间"同构即相等"（单叶范畴）是泛等在范畴层面的回声。

三者的共同点：泛等让 `Type` 成为一个**行为良好的宇宙**——它的路径结构有数学意义，
而不是形式系统的偶然。

## 小结

- `univalent_transport S e : S X -> S Y`：任何结构沿等价搬运，一行搞定。
- 搬运的手工版是共轭（`e ∘ op ∘ e⁻¹`）；泛等保证手工版与 `transport` 一致。
- 结构同一性原理：结构化类型的相等就是同构。"在同构意义下唯一"升级为"唯一"。
- `path_universe` 不可计算；用 `_path_universe` 系列行为律代替。

## 常见误区

1. **以为"等价保持性质"在类型论里自动成立**。对一般的 `S : Type -> Type` 它需要泛等。
2. **期待 `Compute` 穿过 `path_universe`**。不会；改用行为律。
3. **混淆 `istrunc_equiv_istrunc` 与 `istrunc_isequiv_istrunc` 的参数顺序**。
   前者先给 `A B` 再给等价，后者先给函数。`Check` 一下。
4. **以为 SIP 只是哲学**。它是定理，并且有可执行的后果：对一个具体群证明的任何事，
   对所有同构的群自动成立，不需要重做。

## 练习

1. 定义 `S X := X -> X`，用 `univalent_transport` 把 `negb` 搬到 `Unit + Unit` 上，
   然后用 `transport_arrow_*` 引理证明结果等于某个显式定义的函数。
2. 证明：若 `Decidable X`（即 `X + (X -> Empty)`）且 `X <~> Y`，则 `Decidable Y`。
   不用泛等能做到吗？
3. 思考：为什么搬运"是集合"不需要泛等，而搬运"有一个二元运算"需要？
   （提示：前者关于路径，后者关于任意函数 `X -> X -> X`。）

---

**上一章**：[17 截断映射与嵌入](17-trunc-maps.md)
**下一章**：[19 余极限](19-colimits.md)
