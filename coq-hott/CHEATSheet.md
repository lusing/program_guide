# Coq-HoTT 速查

> 读完教程后来查的一页纸，不是入门读物。先读 [README](README.md) 里的章节，理解概念之后再回到这里找记号和引理名字。条目后的数字指向章节。

## 1. 核心词典

| 类型论 | 同伦论 | 章 |
|---|---|---|
| 类型 `A` | 空间 | 01 |
| 元素 `x : A` | 点 | 01 |
| 路径 `p : x = y` | 道路 | 01、04 |
| 2-路径 `r : p = q` | 同伦 | 06 |
| `transport P p` | 沿道路平行移动纤维 | 05 |
| `A <~> B` | 同伦等价 | 07 |
| `hfiber f b` | 纤维 | 08 |
| `Contr` / `IsHProp` / `IsHSet` | 可缩 / 命题 / 集合（-2 / -1 / 0 层） | 09 |
| `Tr n A`、`merely A` | n-截断、命题截断 | 15 |
| HIT | 由点和路径粘出的空间 | 12、19 |
| `loops X` | 环路空间 ΩX | 21 |

## 2. 文件骨架

```coq
Require Import HoTT.                       (* 定义与定理，不含公理实例 *)
Require Import HoTT.Axioms.Univalence.     (* 需要 path_universe 时 *)
Require Import HoTT.Axioms.Funext.         (* 需要 path_forall 时（泛等已蕴含） *)
Local Open Scope path_scope.
```

或在 `Section` 内用 `Context `{Univalence}` / `Context `{Funext}` 把公理当参数。

## 3. 记号（作用域决定含义）

| 写法 | 含义 | 作用域 |
|---|---|---|
| `1` | `idpath` | `path_scope`（默认） |
| `1%equiv` | `equiv_idmap` | `equiv_scope` |
| `1%morphism` | 恒等态射 | `morphism_scope` |
| `p @ q`、`p^` | 路径复合、逆 | `path_scope` |
| `g oE f`、`e^-1` | 等价复合、逆等价 | `equiv_scope` |
| `f^-1` | 等价的反函数 `B -> A` | `function_scope` |
| `f == g` | 逐点同伦 | `type_scope` |
| `A <~> B` | 等价类型 | `type_scope` |
| `A * B`、`A + B` | 乘积、和 | `type_scope` |
| `{x : A & P x}`、`(a; p)`、`u.1`、`u.2` | Σ 类型、构造、投影 | `type_scope`、`fibration_scope` |
| `(2 + 3)%nat`、`(0 - 5)%int` | 算术 | `nat_scope`、`int_scope` |
| `(-2)%trunc`、`trunc_S n` | 截断层级 | `trunc_scope` |
| `X ->* Y`、`X <~>* Y` | 保点映射、点化等价 | `pointed_scope` |
| `x <> y` | `x = y -> Empty` | — |

数字字面量默认不是 `nat`：`0` 是截断层级、`1` 是 `idpath`。

## 4. 路径代数（04–06，零公理）

```coq
concat_p1 : p @ 1 = p         concat_1p : 1 @ p = p
concat_p_pp : p @ (q @ r) = (p @ q) @ r      concat_pp_p : 反向
concat_pV : p @ p^ = 1        concat_Vp : p^ @ p = 1
concat_V_pp : p^ @ (p @ q) = q
inv_pp : (p @ q)^ = q^ @ p^   inv_V : (p^)^ = p
ap_pp : ap f (p @ q) = ap f p @ ap f q       ap_V, ap_compose, ap_idmap, ap_const
apD f p : transport B p (f x) = f y          apD_const : apD f p = transport_const p _ @ ap f p
eckmann_hilton : forall p q : 1 = 1, p @ q = q @ p
moveR_Mp / moveR_pM / moveL_Mp / moveL_pM / moveL_1M / moveR_1M ...   (* 移项，Check 看方向 *)
```

证明路径引理：`destruct p; reflexivity`（路径归纳）。

## 5. Transport（05，零公理）

```coq
transport P p : P x -> P y
transport_const : transport (fun _ => B) p y = y
transport_pp : transport P (p @ q) u = transport P q (transport P p u)
transport_pV / transport_Vp : 来回抵消
transport_compose : transport (fun x => P (f x)) p z = transport P (ap f p) z
transport_paths_l  : transport (fun x => x = y) p q = p^ @ q
transport_paths_r  : transport (fun y => x = y) p q = q @ p
transport_paths_lr : transport (fun x => x = x) p q = p^ @ q @ p
transport_paths_FlFr : transport (fun x => f x = g x) p q = (ap f p)^ @ q @ ap g p
moveR_transport_p : u = transport P p^ v -> transport P p u = v
```

证明 `a ≠ b`：造族 `code`（`a` 上 `Unit`，`b` 上 `Empty`），`fun p => transport code p tt`。

## 6. 等价与纤维（07–08，零公理）

```coq
IsEquiv f := { equiv_inv ; eisretr : f o g == id ; eissect : g o f == id ; eisadj }
equiv_adjointify f g (f o g == id) (g o f == id) : A <~> B    (* 日常构造 *)
make_equiv.                        (* 简单情形自动 *)
equiv_idmap / equiv_compose' (oE) / equiv_inverse (^-1)
equiv_ap : IsEquiv f -> (x = y) <~> (f x = f y)
equiv_ind : IsEquiv f -> (forall a, P (f a)) -> forall b, P b
hfiber f b := {a & f a = b}
Contr A := { center ; contr : forall y, center = y }
contr_basedpaths : Contr {y & x = y}          (* 路径归纳的另一种说法 *)
isequiv_contr_map / contr_map_isequiv : 等价 ⟺ 纤维可缩
equiv_sigma_contr : (forall a, Contr (P a)) -> {a & P a} <~> A
```

## 7. 截断层级（09、15、17）

| 层 | 类型 | 映射（纤维是该层） |
|---|---|---|
| -2 | `Contr A` | 等价 |
| -1 | `IsHProp A` | 嵌入 `IsEmbedding`（⟺ `ap f` 是等价） |
| 0 | `IsHSet A` | 0-截断映射 |
| — | 0-连通 | 满射 `IsSurjection`（纤维 merely 非空） |

```coq
istrunc_paths : IsTrunc n.+1 A -> IsTrunc n (x = y)
istrunc_contr / istrunc_hprop / istrunc_leq : 往上抬
istrunc_equiv_istrunc : A <~> B -> IsTrunc n A -> IsTrunc n B
path_ishprop : IsHProp A -> x = y        hprop_allpath : 反向
hset_path2 : IsHSet A -> p = q
equiv_iff_hprop : 命题之间互相蕴含即等价
Tr n A / tr / Trunc_rec（目标须是 n-型）/ equiv_tr
merely A := Tr (-1) A      hexists P := merely {x & P x}      hor A B := merely (A + B)
isequiv_surj_emb : 满射 ∧ 嵌入 ⇒ 等价
```

## 8. 两条公理（10–11）

```coq
(* Funext *)
apD10 / ap10 : f = g -> f == g                     (* 零公理 *)
path_forall / path_arrow : f == g -> f = g         (* 需 Funext *)
(* Univalence *)
equiv_path : A = B -> A <~> B                      (* 零公理 *)
path_universe f / path_universe_uncurried e : A = B    (* 需 Univalence *)
transport_path_universe : transport idmap (path_universe f) z = f z   (* 唯一计算律 *)
transport_path_universe_V, path_universe_V, path_universe_compose, eta_path_universe
equiv_induction : P U 1 -> forall V (w : U <~> V), P V w
univalent_transport : forall S X Y, X <~> Y -> S X -> S Y    (* 结构搬运 *)
not_hset_Type : ~ IsHSet Type
Univalence_implies_Funext
```

`Print Assumptions foo`：`Closed under the global context` = 零公理。

## 9. 类型构造器的路径（14）

```coq
equiv_path_prod  : (fst z = fst z') * (snd z = snd z') <~> z = z'
equiv_path_sigma : {q : u.1 = v.1 & transport P q u.2 = v.2} <~> u = v
path_sum_inl : inl x = inl x' -> x = x'    inl_ne_inr   （造路径用 ap inl）
equiv_path_arrow : f == g <~> f = g         （需 Funext）
equiv_functor_prod' / sum / sigma / arrow（逆变）
```

## 10. HIT（12、13、16、19）

通用模板：**点构造子给值，路径构造子给 `transport P glue a = b`**；
点上的计算规则定义性成立，路径上的是命题性 `_beta_` 引理（用 `rewrite`）。

| HIT | 构造子 | 消去子 |
|---|---|---|
| `interval` | `zero`、`one`、`seg` | `interval_ind`、`interval_rec`、`interval_rec_beta_seg` |
| `Circle` | `Circle.base`、`Circle.loop` | `Circle_ind`、`Circle_rec`、`Circle_rec_beta_loop` |
| `Quotient R` | `class_of`、`qglue`、截断 | `Quotient_ind`（目标须集合）、`Quotient_ind_hprop`、`Quotient_rec` |
| `Pushout f g` | `pushl`、`pushr`、`pglue` | `Pushout_ind`、`Pushout_rec` |
| `Coeq f g` | `coeq`、`cglue` | `Coeq_ind`、`Coeq_rec`、`Coeq_rec_beta_cglue` |
| `Susp A` | `North`、`South`、`merid` | `Susp_ind`、`Susp_rec` |
| `Tr n A` | `tr`、截断 | `Trunc_ind`、`Trunc_rec` |

目标是命题时，HIT 归纳只需处理点构造子（`*_ind_hprop`）。

圆：`equiv_Circle_rec : {b & b = b} <~> (Circle -> P)`；
`equiv_loopCircle_int : (base = base) <~> Int`（需泛等）；`istrunc_Circle : IsTrunc 1 Circle`。

## 11. 覆叠类证明三步（13、24）

```coq
Definition code : Circle -> Type := Circle_rec Type X (path_universe f).

(* transport code loop x = f x *)
refine (transport_compose idmap code Circle.loop x @ _).   (* 05 *)
rewrite Circle_rec_beta_loop.                               (* 13 *)
apply transport_path_universe.                              (* 11 *)
```

绕 n 圈：对 n 归纳，归纳步 `rewrite transport_pp; rewrite IH; apply (上面的定理)`。

## 12. 点化与范畴（20–21）

```coq
Build_pType X x : pType      pt      loops X := (pt = pt, 1)
Build_pMap f (p : f pt = pt) : A ->* B        Build_pEquiv'
pmap_from_circle_loops : (pCircle ->** X) <~>* loops X    (* 需 Funext *)
pfiber : (A ->* B) -> pType
PreCategory：object / morphism（须集合）/ identity / compose（先 d→d' 后 s→d）/ 五条定律
Category := PreCategory + IsCategory（idtoiso 是等价）
```

## 13. 公理与查阅（23）

| 任务 | 做法 |
|---|---|
| 查公理 | `Print Assumptions foo` |
| 看类型 / 全貌 / 定义 / 记号 | `Check` / `About` / `Print` / `Locate "sym"` |
| 找引理 | `Search (形状) (具体类型项)`，然后 `Check` 确认方向 |
| 类型类失败 | 查公理导入 → 查截断实例（`Definition t : IsHSet X := _.`）→ 查目标形状 |
| `simpl` 不动 | `transport`/`concat` 是 `simpl nomatch`；`path_universe`/`_beta_` 是命题性；用引理 |
| 怪类型变量（`ordinal_carrier ?o`） | 类型类任意统一，给具体类型参数 |
| 对称孪生引理 | `Check`，别猜 |

## 14. 公理依赖一览

| 零公理 | `Funext` | `Univalence` |
|---|---|---|
| 路径代数、transport、等价论、纤维可缩 ⟺ 等价、乘积/Σ/和的路径、截断层级推理、HIT 消去子 | 函数相等、Π 的层级、`IsEquiv`/`IsHProp` 是命题、HIT 泛性质 | `Type` 不是集合、结构搬运、圆的覆叠、`loop ≠ 1`、π₁(S¹) = ℤ、单叶范畴 |

## 15. 源码位置

| 内容 | 文件（`theories/`） |
|---|---|
| `paths`、`transport`、`ap`、`IsEquiv`、`nat`、`hfiber` | `Basics/Overture.v` |
| 路径群胚律 | `Basics/PathGroupoids.v` |
| `IsTrunc`、`Contr` | `Basics/Trunc.v` |
| `Univalence`、`path_universe` | `Types/Universe.v` |
| `Funext`、`path_forall` | `Types/Forall.v` |
| `interval` | `HIT/Interval.v` |
| `Circle` | `Spaces/Circle.v` |
| `Quotient` | `Colimits/Quotient.v` |
| `Pushout`、`Coeq`、`GraphQuotient` | `Colimits/` |
| `Int` | `Spaces/Int.v` |
| 点化类型 | `Pointed/` |
| 范畴论 | `Categories/` |

`About foo` 的 `Declared in library ... line ...` 直接给出位置。
