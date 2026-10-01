# 04 图与交换图

> 对书：《高级范畴论》1.2（图、图同态与图自然变换——全书独有的
> 前置章）/ Simmons 2.1（Diagram chasing）。
> 代码：`examples/04_diagrams/`。

## 4.1 图 = 自由范畴的骨架

《高级范畴论》用一整节讲图，是三本书里最前置的：

```coq
Record Graph : Type := mkGraph {
  V : Type;              (* 顶点 *)
  E : Type;              (* 边 *)
  src : E -> V;          (* 起点 *)
  tgt : E -> V           (* 终点 *)
}.
```

图同态保端点——两条「最小的交换图」方程：

```coq
Record GraphHom (G H : Graph) : Type := mkGH {
  vmap : V G -> V H;
  emap : E G -> E H;
  sq_src : forall e, vmap (src G e) = src H (emap e);
  sq_tgt : forall e, vmap (tgt G e) = tgt H (emap e)
}.
```

**图 → 范畴**的免费升级：对象 = 点、态射 = 路、复合 = 拼接
（`freeCat`）。路的归纳定义：

```coq
Inductive Path (G : Graph) : V G -> V G -> Type :=
| pid : forall v, Path G v v
| pcat : forall (e : E G) (w : V G), Path G (tgt G e) w -> Path G (src G e) w.
```

拼接 `papp` 递归在第一条路。Coq 又一次撞索引 match 的墙（02 章
同款）：Fixpoint 写不出，走 `revert + induction + Defined`；定律
`papp_idR`/`papp_assoc` 对第一条路归纳。Agda/Lean 的模式匹配自动
处理索引，直接双模式完事。

一个小图 `true --e--> false` 上跑真数据：

```coq
Example pDirect2 : Path gArrow true false :=
  pcat gArrow tt false (pid gArrow false).
Example plen_direct : plen pDirect2 = 1 := eq_refl.
```

`freeCat` 是「泛构造」的第一实例：任何图免费生成范畴——
09 章的自由幺半群、14 章的自由-遗忘伴随都是它的重演。

## 4.2 交换图 = 方程组

「方块交换」听起来几何，写下来是代数：给定 `f : a→b`、`h : b→d`、
`g : a→c`、`k : c→d`，方块交换 ⟺ `f;h = g;k`。图同态的保端点
方程（4.1）就是最小的例证。

**两层验证**（TyCat 实测）：

```coq
(* 退化方格：恒等边——两边 βη 折叠成同一函数，reflexivity 白送 *)
Example square_refl :
  comp catTy (fun x => x) (fun n => 2 * n)
  = comp catTy (fun n => 2 * n) (fun x => x) := eq_refl.

(* 真方格：succ;double = double;(+2)——定义相等白送不了 *)
Example square_commutes :
  comp catTy (fun n => S n) (fun n => 2 * n)
  = comp catTy (fun n => 2 * n) (fun n => n + 2).
Proof. apply funext. intro n. simpl. lia. Qed.
```

三家的第二层：

```lean
-- Lean：funext 定理 + omega（线性算术全包）
theorem square_commutes : ... :=
  funext fun n => (by omega : 2 * (n + 1) = 2 * n + 2)
```

```agda
-- Agda：postulate funext + *-suc（stdlib 的 * 递归在第一参数！）
square-commutes = funext pointwise
  where pointwise n = begin
    2 * suc n   ≡⟨ *-suc 2 n ⟩
    2 + 2 * n   ≡⟨ +-comm 2 (2 * n) ⟩
    2 * n + 2   ∎
```

Agda 那步 `*-suc` 是被逼出来的：stdlib 2.3 的 `_*_` 递归在**第一**
参数（与 Coq 加法同款方向学），`2 * suc n` 不按教科书直觉展开成
`2 + 2*n`，引理 `*-suc 2 n : 2 * suc n ≡ 2 + 2 * n` 的右端还是反的，
要再接 `+-comm`——「方向学」从加法蔓延到了乘法。

## 4.3 抽象图表推理：只用三条定律

不落在具体范畴、只用定律推图——全书证明风格的缩影：

```coq
Lemma laws_only : forall (C : Category) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c),
  comp C (comp C f (idn C b)) g = comp C f g.
Proof. intros. rewrite (idR C f). reflexivity. Qed.
```

Simmons 2.1 的 diagram chasing 就是这种重写的图形化记法：
追着方块转圈 = 沿 assoc/idL/idR 归约方程串。后续章节的通用模式：
**具体范畴里交换图用计算（rfl/lia/omega），抽象范畴里用定律重写**。

## 4.4 本章在三书中的位置

- 《高级范畴论》1.2 讲图同态与「图自然变换」——预层理论的伏笔
  （21 章 presheaf = 图/层的推广）；
- Simmons 2.1 的 chasing 技法服务于 2.5–2.7 的方块图
  （拉回、推出）——10 章正式重逢；
- 贺伟本不单独讲图，极限（第 2 章）直接以「图表 = 函子」开题
  ——11 章采纳这个更抽象的进路。

## 坑位速记

1. Coq 的 `Path` 指定 `: Type` 而非 `: Set`——Graph 的 V/E 在
   Type 层，Set 版直接宇宙不一致。
2. Coq 构造子模式槽数含参数：`pid _ _`、`pcat _ _ _ p'`
   （Graph 参数 G 也占一槽）。
3. Lean `.pcat` 的具名参数 `Path.pcat (G := gArrow) (e := ()) (w := false) ...`
   ——匿名点号在索引上留下 metavar 时要显式钉住。
4. Agda stdlib 的 `*` 递归在第一参数：`*-suc` 的右端是 `m + m*n`
   方向，接 `+-comm` 换向——乘法版方向学。
5. Lean `simp only [Path.cat]` 展开方程式定义后再 rw 递归假设
   （iota 折叠下的子项 rw 看不见——typetheory 13 章老坑复现）；
   结构投影 `TyCat.comp` 不是 simp 定理，用 `change`/类型注解绕行。
