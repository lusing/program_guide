# 05 图与交换图

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

拼接 `papp` 递归在第一条路。Coq 又一次撞索引 match 的墙（03 章
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
11 章的自由幺半群、17 章的自由-遗忘伴随都是它的重演。

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

## 4.4 旗舰操练：五角星绕两圈（Simmons 2.1.3）

Simmons 2.1 给的看家练习值得整个机器化。五个顶点 0..4 排在
圆周上，**周长边** `p_i : i → i+1`（mod 5）、**星形弦**
`s_i : i → i+2`（mod 5）。假设五个三角形都交换：

```text
T0 : p0;p1 = s0    T1 : p1;p2 = s1    T2 : p2;p3 = s2
T3 : p3;p4 = s3    T4 : p4;p0 = s4
```

**定理**：沿周长绕两圈 = 沿星形绕一圈。书的坍缩序列（角标从
1 数起）读作：

```text
12345123451 → 1345123451 → 135123451 → 13523451 → 1352451 → 135241
   (123→13)     (345→35)     (512→52)   (234→24)   (451→41)
```

每步塌掉一个角——「绕周边两圈」的 10 步路径缩成「沿星一圈」
的 5 步路径。机器版完全按这个剧本演出（Coq）：

```coq
Theorem pentagram : perim2 = star1.
Proof.
  unfold perim2, star1.
  repeat rewrite <- ?assoc.            (* 先规范到左嵌套 *)
  rewrite T0.                          (* 123 -> 13  *)
  rewrite (assoc C s0 p2 p3), T2.      (* 345 -> 35  *)
  rewrite (assoc C (comp C s0 s2) p4 p0), T4.   (* 512 -> 52  *)
  rewrite (assoc C (comp C (comp C s0 s2) s4) p1 p2), T1.  (* 234 -> 24  *)
  rewrite (assoc C (comp C (comp C (comp C s0 s2) s4) s1) p3 p4), T3.
  reflexivity.
Qed.
```

五个 `rewrite` 与五个坍缩一一对应；每步先用一条**显式实例**的
assoc 把已坍缩的前缀「剥」到最左，再换掉暴露出的三角。为什么
要显式？Coq 的 `rewrite` 遍历选**最右侧匹配**——半显式写法
`(assoc C _ p2 p3)` 会命中链尾的同形子项，把坍缩做错位置。
Agda 版把「对齐 + 坍缩」打包成小步引理，长成一棵 cong/trans 树：

```agda
step : ∀ {o ℓ} (C : Category o ℓ) {a b c d : Obj C}
     (f : Hom C a b) (g : Hom C b c) (s : Hom C a c) (r : Hom C c d)
     → comp C f g ≡ s → comp C f (comp C g r) ≡ comp C s r
step C f g s r h = trans (sym (assoc C f g r)) (cong (λ w → comp C w r) h)
```

Lean 版则是 `simp only [← C.assoc]` 一步规范化 + 五条 rw，
与 Coq 版逐行对映。三份代码同一个定理、零公理——
**图上的推理 = 三条定律上的重写**，这句话至此有了完整机器版。

同节的另外两道操练（2.1.1/2.1.2 的多边形拼接）读者可用同样的
「规范化 + 坍缩」配方自验——它们是五角星的减少步数版。

## 4.5 本章在三书中的位置

- 《高级范畴论》1.2 讲图同态与「图自然变换」——预层理论的伏笔
  （28 章 presheaf = 图/层的推广）；
- Simmons 2.1 的 chasing 技法服务于 2.5–2.7 的方块图
  （拉回、推出）——12 章正式重逢；
- 贺伟本不单独讲图，极限（第 2 章）直接以「图表 = 函子」开题
  ——13 章采纳这个更抽象的进路。

## 4.7 图自然变换：两层结构的竖直态射（高级范畴论 1.2）

04.1 定义了图与图同态（一对保源汇的函数）。《高级范畴论》
1.2 再进一层：两个图同态 F, G : Γ → Δ 之间的**图自然变换**
α 是一族边函数——给 Γ 的每个**顶点** x 配 Δ 的一条**边**
`α_x : F(x) → G(x)`，使得每个 Γ-边 e : x → y 两侧的方块交换：

```text
    F(x) --F(e)--> F(y)
     |              |
   αx|              |αy        （Δ 中交换）
     ↓              ↓
    G(x) --G(e)--> G(y)
```

与 06 章的自然变换逐字对照：图 = 「没有复合的范畴」、图
同态 = 「没有函子律的函子」、图自然变换 = 自然变换——
**自然性方块不依赖复合律**，它在图的层面就有意义。这个
三层结构（图 → 图同态 → 图自然变换）正是**预层范畴的骨架**：
把 Γ 换成小范畴、把「Δ 的一条边」换成「集合」，就得到
[C, Set] 的态射定义（06 章的 NT record）。Graph → Cat 的
自由函子（04 章的 freeCat）与预层的「图解直觉」（01 章
1.9、27 章层）在图自然变换处会师——图是范畴的「骨架投影」，
范畴论沿着这个投影把组合结构逐层装回去。

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
6. Coq `rewrite` 的匹配遍历选最右侧/最内层：坍缩链条的每一步
   assoc 都要**完全显式实例**（把已坍缩前缀逐字写出），否则
   同形子项会被错换位置。
7. Agda 的长推理链嵌在元组/应用参数里解析不了——拆 where 局部
   名（step/step4/step2 三级）；顶层声明缩进必须归零。
8. 括号预算：右嵌套 9 层 comp 的定义，闭括号数 = 开括号数——
   数错一个，报错位置远在天边。

---

上一章：[04 特殊态射与特殊对象](03-arrows.md) · 下一章：[06 函子](05-functors.md)
