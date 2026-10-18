# 08 范畴的等价与同构

> 对书：《高级范畴论》4.7（范畴的同构与等价）/ Simmons 1.2.7
> （Pfn ≃ Set⊥ 手工等价）/ 贺伟 3.3（反射子范畴）前置。
> 代码：`examples/07_equivalence/`。

## 7.1 什么时候两个范畴「一样」？

严格同构（双向函子严格复合成恒等）要求对象层面也一一对应——
太稀有。范畴论的正确答案是**等价**：

- **忠实** faithful：Hom 映射单（`F f = F g ⟹ f = g`）；
- **满** full：Hom 映射满（证据是数据）；
- **本质满** essentially surjective：每个 D 对象同构于某个 F 的像。

```lean
def Faithful ... : Prop := ∀ a b (f g : C.Hom a b), F.FHom f = F.FHom g → f = g
def Full ... : Type (max u v v') :=
  ∀ a b (h : D.Hom (F.FObj a) (F.FObj b)), Σ' f : C.Hom a b, F.FHom f = h
def EssentiallySurj ... : Type (max u u' v') :=
  ∀ d : D.Obj, Σ' c : C.Obj, D.Hom (F.FObj c) d
```

注意三者的**层级**分岔：Faithful 是 Prop（纯性质）；Full/Essentially
Surj 带数据（Σ'，Lean 的 PSigma 混居数据与 Prop）；Coq 里是 sig、
Agda 里是 Σ——「证据是计算还是命题」直接决定定义落哪一层。

## 7.2 机器内容

- 恒等函子全忠实且本质满——**定义即证**（三家零公理）；
- List 函子忠实——`map f = map g ⟹ f = g`，用**单点列表当探针**：

```lean
have h2 : [f x] = [g x] := congrFun H [x]   -- map f [x] 化简为 [f x]
injection h2 with h3                          -- 头部提取
```

Coq 版同一招：`f_equal (fun k => k (x :: nil)) H` + inversion。
「元素即态射」（04 章）的列表版：`[x]` 是从单点出发的探针态射。

List 函子**不满**（`[A] → [B]` 的函数未必逐点Cons）、**不本质满**
（无限类型不被 List 覆盖）——反例记录在文档层。

## 7.3 等价的三个面孔（陈述，不机器化）

**定理**（等价判据）：以下等价——
1. F 全忠实 + 本质满；
2. F 有拟逆 G（G∘F ≅ Id、F∘G ≅ Id 的**自然**同构）；
3. 存在伴随等价。

(1) ⟹ (2) 需要**选择公理**（为每个对象挑同构）——构造性数学
要额外结构。本教程机器化到 (1) 为止，(1)⟹(2) 作为诚实边界
（18 章伴随函子定理会正面讨论 Solution Set 条件）。

## 7.4 Simmons 的 Pfn ≃ Set⊥

1.2.7 的漂亮例子：**部分函数范畴** ≃ **带点集范畴**。

```text
L：A ↦ A ∪ {⊥}，部分函数 f ↦ 补点延拓 L(f)（⊥ 映 ⊥）
M：S ↦ S − {⊥}，保点函数 φ ↦ M(φ) 限制回定义域
M ∘ L = Id 严格成立；L ∘ M = Id 严格成立——这其实是范畴同构！
Simmons 顺势问：那 Pfn 和 Set⊥ 是「本质相同」吗？
```

机器化这串需要部分函数/带点函数的范畴基础设施（Hom 带证明），
超出本教程的 mini 库规模——作为文档案例收录，读者已具备读懂
它需要的全部概念（函子定律 = 逐点等式 + funext）。

## 7.5 后记：这是同构不是等价（Simmons 3.3.16）

3.3.16 把 1.2.7 的翻译 L（添底）/M（去底）逐条验证成**函子**：
`L(g∘f) = L(g)∘L(f)` 的证明要点是「定义域的判据逐点等价」
（`L(f)(a) ∈ Y ⟺ a ∈ U`），M 同理。于是 `M∘L = Id`、
`L∘M = Id` 在对象与箭头两个层面都严格成立——**Pfn 与 Set⊥
是范畴同构**（iso），比等价（equivalence）强一档。等价的
「本质满 + 全忠实」在同构里退化为「双射 + 双射」。这也解释了
07.2 的机器边界：同构级别的验证需要部分函数范畴的完整基建
（定义域子集是数据），Mini 库里留作文档级。

## 7.6 反射定理：忠信函子「保真」的一面（高级范畴论 4.4）

07 章问「函子什么时候**保持**性质」；镜像问题是「什么时候
**反射**性质」——F(f) 有性质 ⟹ f 有性质。《高级范畴论》
4.4 给出完整判决（定理 4.4.3/4.4.4）：

| F 的强度 | 反射什么 |
|---|---|
| 忠信 | 单态射、外态射、双态射、常态射、余常态射、零态射、交换图 |
| 忠信 + 完全 | 再加 section、retraction、同构 |

机器版（ex07 新增，零公理）——忠信反射单态射的完整证明：

```coq
Lemma faithful_reflects_mono :
  forall (F : Functor C D) (Hf : Faithful C D F)
         (a b : Obj C) (f : Hom C a b),
  Mono D (FObj F a) (FObj F b) (FHom F f) -> Mono C a b f.
Proof.
  intros F Hf a b f HM c g h Hgh.
  apply (Hf c c).                  (* 忠信：Hom 层单射 *)
  apply HM.                         (* D 侧消去 *)
  unfold Hom, comp in *. simpl.
  rewrite <- !Fcomp. exact Hgh.    (* 方程沿 F 搬回 *)
Qed.
```

证明的骨架只有三步：把 C 侧的等式 g;f = h;f 沿 F 搬到 D 侧
（函子律）、在 D 侧用 F(f) 的单态射消去、再用忠信搬回。所有
「可消去性」类性质（单/外/双/常/零）都是这三步的变奏——
消去律的量词结构恰好与 Hom-单射对齐；而 section/retraction
需要「把 D 侧的逆箭头搬回 C 侧」——**完全性**（满 Hom）在
这一步上岗。**交换图的反射**同理：图形方程逐边搬运。

反射定理的实用价值：想证 C 里的箭头有性质，可以把它送到
一个「性质好验」的范畴（Set！）里去验——**下降法**
(descent) 的雏形；07 章的全忠实等价判据因此多了一个读法：
**等价保持并反射一切「Hom 层可表述」的性质**。

## 坑位速记

1. Coq `Set Implicit Arguments` 会把定义头部的范畴参数也隐化：
   `Faithful C D F` 变成 `@Faithful C D F` 才能显式应用——
   否则 C 落进 F 的槽位报类型错。
2. Lean 单点列表探针：`congrFun H [x]` + `injection`；Coq 用
   `f_equal (fun k => k (x :: nil))` + `inversion`；Agda 用
   `cong first (cong (λ k → k [ x ]) H)`，`first` 要给空列表
   兜底分支（不可达）。
3. Full 的宇宙账要算三层：a b : C.Obj（u）、C.Hom（v）、D.Hom（v'）
   —— Lean `Type (max u v v')`。
4. 本质满的完整版要求同构数据（IsIsoD）；本教程用「有态射」的
   可扩充占位（True/sig），换完整版时证明变重但结构不变。

---

上一章：[07 自然变换与函子范畴](06-natural.md) · 下一章：[09 Yoneda 引理与可表函子](08-yoneda.md)
