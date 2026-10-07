# 06 自然变换与函子范畴

> 对书：贺伟《范畴论》1.3（自然变换）/《高级范畴论》4.5–4.6（自然
> 变换及其 Godement 积）/ Simmons 3.4–3.5（定义与例子）。
> 代码：`examples/06_natural/`。

## 6.1 一族交换的态射

自然变换是「函子之间的态射」：对每个对象 a 给一条态射
`η_a : F a → G a`，并且对**每条**态射 f : a → b 方块交换：

```text
自然性：  F f ; η_b = η_a ; G f
```

```coq
Record NT {C D} (F G : Functor C D) : Type := mkNT {
  ncomp : forall a, Hom D (FObj F a) (FObj G a);
  nlaw : forall {a b} (f : Hom C a b),
           comp D (FHom F f) (ncomp b) = comp D (ncomp a) (FHom G f)
}.
```

Eilenberg–Mac Lane 说「范畴是为了定义函子、函子是为了定义自然
变换」——三层塔到这里封顶。

## 6.2 垂直复合与函子范畴

NT 的垂直复合（分量逐个复合）的自然性证明是本章第一仗——
五步追图（每步一个 cong）：

```text
Ff;(α_b;β_b)  →并组  (Ff;α_b);β_b  →α律  (α_a;Gf);β_b
  →拆组  α_a;(Gf;β_b)  →β律  α_a;(β_a;Hf)  →并组  (α_a;β_a);Hf
```

**于是 [C, D] 是范畴**——但「是范畴」的定律需要 NT 之间的相等，
这里撞上全书最重要的机器裂缝：

> **NT 的 nlaw 字段类型依赖 ncomp 字段**——两个 NT 的相等是
> 依赖字段上的异构相等问题。

三家的三种命运（这是本章的教学核心）：

| | 路线 | 结果 |
|---|---|---|
| Coq | f_equal / rewrite | 被「Abstracting leads to ill-typed」挡住 |
| Coq | PI 公理（证明无关性）| 无原始投影时仍卡在异构性——**定律降为分量级** |
| Agda | 自定义 `_≈NT_`（分量相等）| setoid 风格（agda-categories 的现实路线） |
| Lean | `cases + congr 1` | **真 record 相等**：nlaw 字段被内核 PI 拍平，只剩分量目标 |

Lean 版的对照实现：

```lean
theorem vcomp_assoc ... : vcomp (vcomp α β) γ = vcomp α (vcomp β γ) := by
  cases α
  cases β
  cases γ
  simp only [vcomp]
  congr 1
  · exact funext fun a => D.assoc _ _ _    -- nlaw 被 PI 自动拍平
```

## 6.3 Godement 积（水平复合）

《高级范畴论》4.6 的专节：α : F ⇒ G（C→D 内）、β : H ⇒ K（D→E 内）
的水平复合

```text
β ⋆ α : H∘F ⇒ K∘G，分量 (β ⋆ α)_a = H(α_a) ; β_{G a}
```

自然性证明是全书到目前为止最长的追图——七步：
并组 → 函子性进 H（Fcomp 反向）→ α 的自然性 → 函子性出 H
（Fcomp 正向）→ 拆组 → β 的自然性（在 Gf 处！）→ 并组。

三家实测：**零公理**（纯方块追图）。「进函子再出来」的模式
（Fcomp 反向再正向）是伴随章（13 章）三角恒等式的预演。

## 6.4 一个具体的自然变换：reverse

`reverse : List ⇒ List` 是自然的（`rev ∘ map f = map f ∘ rev`）——
教科书第一例的机器版：

```agda
revNT : NT ListFun ListFun
revNT = record { ncomp = λ A → reverse {A = A} ; nlaw = λ f → funext (rev-map f) }
```

`rev-map` 的归纳证明在三家分别用 `map_app`/`map-++`/`List.map_append`
展开——引理名随库漂移，点式自证最稳（这是 typetheory「方向学」
教训在列表上的重演：Agda stdlib 的 `*` 递归在第一参数，`*-suc`
的右端还是 `m + m*n` 方向）。

## 坑位速记

1. **依赖字段的 record 相等**是本章主角：Coq 无原始投影无解
   （分量级止步）、Agda setoid、Lean 结构 η + 内核 PI 免费拿到。
2. Coq 的 vcomp/vid/compFun/hcomp 必须 `Defined`——后续
   unfold/ι-折叠要透明（ Qed 挡 delta）。
3. Coq funext 需要**依赖版**（funextd）：NT 分量住在依赖函数空间
   `∀ a, Hom D (F a) (G a)`，非依赖版 unify 不上。
4. Agda 子句体只能引用**模式里绑定的变量**：隐式 C/D/F/G 要在
   等式左侧具名绑定（`vcomp {D = D} {F = F} {G = G} {H = H} α β`），
   否则 NotInScope。
5. Agda `FHom _ f` 的下划线会留死 meta——一律具名展开写全。
6. Lean `(compFun H F).FHom f` 的投影不自动折叠——
   `rw [show ... from rfl]` 先行展开再追图。
7. Coq hcomp 追图里的复合发生在 D 层：`Fcomp H (FHom F f) (ncomp α b)`
   传两个态射（不是先复合），中间那步最易写错。

---

上一章：[05 函子](05-functors.md) · 下一章：[07 范畴的等价与同构](07-equivalence.md)
