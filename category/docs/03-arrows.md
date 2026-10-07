# 03 特殊态射与特殊对象

> 对书：贺伟《范畴论》1.4（单态射与满态射）/《高级范畴论》第 2 章
> （section、retraction 与同构；单态射、外态射与双态射；初始、终止
> 与零对象）/ Simmons 2.2（Monics and epics）、2.4。
> 代码：`examples/03_arrows/`。

## 3.1 用消去性质定义性质

不看元素的内部，看「如何被复合探测」：

```coq
Definition Mono (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C c a), comp C g f = comp C h f -> g = h.
Definition Epi (C : Category) (a b : Obj C) (f : Hom C a b) : Type :=
  forall c (g h : Hom C b c), comp C f g = comp C f h -> g = h.
```

- **单态射** mono：左侧可消去（`g;f = h;f ⟹ g = h`）；
- **满态射** epi：右侧可消去；
- **同构** iso：有双侧逆（数据，不是性质）；
- **分裂单态射** split mono：只要求一个 retraction（f;r = id）。

在 Set/FinCat/TyCat 里：mono = 单射、epi = 满射、iso = 双射——
但这些**等价**要用「元素即态射」的翻译才能机器化。

## 3.2 旗舰证明：split mono ⟹ mono

整个证明只是三条定律的重写串，在**任意**范畴成立：

```coq
Lemma split_mono_mono : forall (C : Category) (a b : Obj C) (f : Hom C a b),
  SplitMono C a b f -> Mono C a b f.
Proof.
  intros C a b f [r Hr] c g h H.
  rewrite <- (idR C g).        (* g 展成 g;id *)
  rewrite <- Hr.               (* id 展成 f;r *)
  rewrite <- (assoc C g f r).  (* (g;f);r 并成组 *)
  rewrite H.                   (* 用假设换 g 为 h *)
  rewrite (assoc C h f r).     (* 拆组 *)
  rewrite Hr.                  (* f;r 折回 id *)
  apply idR.
Qed.
```

Lean 版同一串重写一行放下：

```lean
rw [← C.idR g, ← hr, ← C.assoc g f r, H, C.assoc h f r, hr, C.idR h]
```

Agda 版用 `≡-Reasoning` 的 begin...∎ 链。`Print Assumptions` 审计：
**零公理**（Coq/Lean 实测 Closed under the global context / does not
depend on any axioms）。这就是「泛性质推理」——不涉及任何元素，
定律即全部。iso ⟹ mono、iso ⟹ epi 是同串重写的镜像（对偶）版。

## 3.3 元素即态射

在 FinCat 里把 `x : fin m` 看成 `1 → m` 的常值态射，mono 的消去律
立刻翻译成单射：

```text
mono f ⟹ 单射：  g := (λ _ → x), h := (λ _ → y) : 1 → m
                   g;f = h;f 即逐点 f x = f y（要 funext 造假设）
单射 ⟹ mono：    从 (g;f = h;f) 逐点取值 f (g z) = f (h z)
                   （「取点」三家通道不同，见坑位）
```

**funext 分岔点**：函数相等从逐点相等升级，Coq 要 `Axiom funext`、
Agda 要 `postulate`（stdlib 在 Axiom.Extensionality 有同款），
**Lean 的 funext 是核心定理**（Quot.sound 的推论）——同一章定理的
公理账目在三家不同：

```text
Coq : mono_fin_inj   → Axioms: funext
Lean: mono_inj       → depends on [propext, Quot.sound]（内建）
Agda: mono-inj       → postulate funext（入账）
```

epi 方向：满射 ⟹ epi 构造性成立（逆像处比较）；**epi ⟹ 满射**
在 Set 等价于（受限于）选择公理——本书作为诚实边界记录，不机器化。

## 3.4 特殊对象：终、始、零

```coq
Definition Terminal (C : Category) (t : Obj C) : Type :=
  forall a, { f : Hom C a t | forall g, g = f }.   (* 存在 + 唯一 *)
Definition Initial (C : Category) (i : Obj C) : Type :=
  forall a, { f : Hom C i a | forall g, g = f }.
```

FinCat 的答案：**终对象 = 1**（唯一函数映到单点集）、**初始对象 = 0**
（空集出发唯一）。唯一性的机器证明都要 funext + 目标集合的「薄度」：

```coq
intros g. apply funext. intro z.
destruct (g z) as [e|]; [destruct e | reflexivity].   (* 映到 fin 1 *)
```

零对象（既终又始）在 FinCat 不存在（0 ≠ 1）；最简例子是终范畴
`catOne` 的唯一对象。Grp 的零对象是平凡群、Abel 群范畴的零对象
同样是 0——20 章加法范畴会重逢。

对偶翻译一行：`Terminal C t → Initial (opposite C) t`——三家的
验证都是「定义层面直接翻转」，无需证明。

## 3.5 层级三分（Lean 版特有）

泛性质的定义在 Lean 里分三档：

| 性质 | 形态 | 落点 |
|---|---|---|
| Mono/Epi | `∀ ..., → g = h` | Prop |
| IsIso/SplitMono | structure（逆/收缩是数据） | Type v |
| Terminal/Initial | `∀ a, Σ' f, ∀ g, g = f` | Type (max u v) |

Σ 不收 Prop 分量、Σ'（PSigma）才混居——这是 Lean 的 Sort 层级
在设计泛性质数据结构时的直接后果。

## 坑位速记

1. mono 定义的方向：`comp g f = comp h f → g = h`——f 在复合**右侧**；
   图序书写时消去律两侧要分清。
2. 从函数相等取「点」：Lean `congrFun H z`；Coq
   `f_equal (fun k => k z) H`（β 不自动，要 simpl）；Agda
   `cong (λ k → k z) H`（β 自动）。
3. Coq 的 `fun _ => None` 类型注解放外层：`((fun _ => None) : fin a -> fin 1)`，
   写 `fun _ => None : ...` 会把注解吸进 lambda 体。
4. 空集消去：Coq `match (x : Empty_set) return fin a with end`；
   Lean `absurd z.2 (by omega)`；Agda `fin0-elim ()`。
5. Agda 的 Mono/Epi 量化 `c : Obj C`（Set o）→ 结果在 `Set (o ⊔ ℓ)`；
   SplitMono 的 Σ 谓词是 Prop 值时只升到 ℓ——层级账要算清。
6. epi ⇒ 满射需要选择：诚实边界，不硬凑构造性证明。

---

上一章：[02 反范畴与对偶原理](02-opposite.md) · 下一章：[04 图与交换图](04-diagrams.md)
