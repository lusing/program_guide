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
同样是 0——22 章加法范畴会重逢。

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

## 3.6 section、retraction 与「自动补逆」（Simmons 2.2.1）

《高级范畴论》讲了 split mono 的一侧；Simmons 2.2 把账记全：

| 箭头性质 | 消去性质 | 分裂版本 | 终点 |
|---|---|---|---|
| mono | 左可消去 | ∃r, f;r = id（有 retraction） | ↘ |
| epi | 右可消去 | ∃s, s;f = id（有 section） | ↗ |
| iso | 双侧可消去 | 双侧逆 | 两侧同时分裂 |

分裂 ⇒ 消去（03.2 的旗舰）。反方向不成立——但两条分裂性质
**合起来**会升级：**section 若还是 epi，自动补出另一侧逆**（2.2.1a）。
证明只有一行箭头论：从 `s;r = id` 出发，把 `(s;r);s = s;id` 两边
按 `s;? = s;?` 对齐，用 epi 消去 s，得 `r;s = id`。机器版：

```coq
Lemma section_epi_iso : forall (C : Category) (a b : Obj C) (s : Hom C b a),
  Epi C b a s -> forall r : Hom C a b,
  comp C s r = idn C b -> IsIso C b a s.
Proof.
  intros C a b s Hepi r Hsr.
  exists r. split.
  - exact Hsr.
  - apply (Hepi a (comp C r s) (idn C a)).
    rewrite <- (assoc C s r s), Hsr, idL, idR. reflexivity.
Qed.
```

`Print Assumptions` 报 Closed——零公理。对偶命题（retraction 若
还是 mono 也是 iso）由 02 章的对偶原理免费。

## 3.7 封闭八律与消去演算（Simmons 2.2.4 / 2.2.10）

这批箭头性质在复合下的封闭性像乘法表，值得全表机器化
（`mono_comp`、`mono_of_comp`、`epi_comp`、`epi_of_comp` +
四条分裂版；全部零公理）：

| 前提 | 结论 |
|---|---|
| f mono、g mono | g∘f mono |
| g∘f mono | f mono |
| f epi、g epi | g∘f epi |
| g∘f epi | g epi |
| 分裂版同理 | (m.iii/iv、e.iii/iv) |

注意**不对称**：g∘f mono 只保证**前段** f mono；g∘f epi 只保证
**后段** g epi——方向相反。书里 2.2.4(c) 的反例提醒另一面：
`A →(嵌入) B →(满射) C`（A、C 单点、B 更大）时 g∘f 是同构，
但 f 不满、g 不单。

消去性质的**组合拳**（2.2.10 的五格图）抽象成一条引理：
外层等式 `m;u;e = m;v;e`（e 单、m 满）⟹ `u = v`——先消 m 再消 e，
各一次：

```coq
Lemma mono_epi_cancel : forall (C : Category) (A B X Y : Obj C)
  (e : Hom C A B) (u v : Hom C B X) (m : Hom C X Y),
  Epi C A B e -> Mono C X Y m ->
  comp C (comp C e u) m = comp C (comp C e v) m -> u = v.
Proof.
  intros C A B X Y e u v m He Hm H.
  rewrite !assoc in H.
  exact (Hm B u v (He Y (comp C u m) (comp C v m) H)).
Qed.
```

书里的图版证明（沿五个格子追箭头、两端各消去一次）就是这条
引理在具体布局下的展开——图是给人看的，消去链是给机器看的。

## 3.8 满而不单、单而不满（Simmons 2.2.5–2.2.8）

在 Set 里 mono = 单、epi = 满（3.3 节）；离开 Set，两条
等式各崩一半，经典反例都值得亲手核一遍：

**ℕ ↪ ℤ 在 Mon 里是 epi**（2.2.5）。设 f, g : ℤ → A 是幺半群
态射且在 ℕ 上一致，要证 f(−m) = g(−m)。链条：

```text
g(−m) = g(−m)·ι = g(−m)·f(0) = g(−m)·f(m+(−m))
      = g(−m)·f(m)·f(−m) = g(−m)·g(m)·f(−m)
      = g(−m+m)·f(−m) = g(0)·f(−m) = f(−m)
```

中间那步 `f(m) = g(m)` 是唯一用到前提的地方——负数的信息被
幺半群结构从正数「挤」出来。同款技巧证 **ℤ ↪ ℚ 在 Rng 里是 epi**
（2.2.6：对 n ≠ 0 先证 g(1/n) = f(1/n)，再乘 m）。

**稠密 + T₂ 在 Top 里是 epi**（2.2.8b）。设 ϵ[T] 稠密、φϵ = ψϵ、
R 豪斯多夫。若 φ(s) ≠ ψ(s)，取不相交开集 U ∋ φ(s)、V ∋ ψ(s)，
则 φ⁻¹(U) ∩ ψ⁻¹(V) 是含 s 的非空开集，必交稠密集 ϵ[T] 于某 t，
于是 φϵ(t) ∈ U 且 ψϵ(t) ∈ V 同点——矛盾。附带 2.2.8(a) 的提醒：
**连续双射不必是同胚**（离散化的恒等映射 S_d → S）。

**反过来，mono = 单在结构集范畴里有统一解释**（2.2.7）：若
范畴有**选择子** (S, ⋆)——一个由单元素生成万有的对象——则
mono ⟹ 单射。各家选择子：Set/Pos/Top 用 1 元结构、Mon 用
(ℕ,+,0)、Grp 用 (ℤ,+,1)、Rng 用 ℤ[X]、Set-R 用 R 自身。证明
是 3.3 节「元素即态射」的推广：把 a₁、a₂ 编成两条从 S 出发的
箭头，消去律回收单射性。

## 3.9 平衡范畴：mono+epi ≠ iso（Simmons 2.2.2 / 2.2.3）

「单且满」在集合论里就是双射，在范畴论里**未必是同构**。
最小反例就是 02 章的行走箭头：瘦范畴里平行箭头恒相等（Hom
至多一条），于是**一切箭头自动既 mono 又 epi**：

```coq
Lemma thin_mono : forall a b (f : twoHom a b), Mono catTwo a b f.
Proof.
  intros a b f c g h _.
  destruct c, a; cbn in g, h; try destruct g; try destruct h; reflexivity.
Qed.
```

但 `0 → 1` 没有反向箭头（`twoHom true false` 就是
`Empty_set`），成不了 iso——`arr_not_iso` 三个字母
（`destruct g`）就把「无逆」判掉。所以 **catTwo 不平衡**。
书里的两个配套事实：预序（作为范畴）平衡 ⟺ 离散；幺半群（作为
单对象范畴）平衡 ⟺ 可消去元素成群。「mono+epi 却不是 iso」
因此是衡量范畴离 Set 有多远的**第一个标尺**——Abel 范畴
（22 章）会要求平衡，那正是它们「像 Set」的地方。

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
7. Coq IsIso 的合取顺序：先 `comp f g = id a` 后 `comp g f = id b`
   ——section_epi_iso 里 bullet 顺序填反会报 unify 错。
8. `apply (Hepi a)` 会把整个左侧当 g——消去律应用要显式给
   两个参数 `apply (Hepi a (comp C r s) (idn C a))`。
9. Agda 的 `r , Hsr , <begin…∎>` 解析不了：元组与推理链混排
   要拆 where 局部名；各家 assoc 字段方向可能相反——链式
   重写前先看字段声明（本仓三个 ex03 文件两种方向都有）。
10. Lean 结论是数据（IsIso 是 structure）时用 `def` 不能用
    `theorem`；`rw` 按第一匹配走，双侧重写写两遍
    `rw [C.assoc, C.assoc]`，别赌 simp。

---

上一章：[02 反范畴与对偶原理](02-opposite.md) · 下一章：[04 图与交换图](04-diagrams.md)
