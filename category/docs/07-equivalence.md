# 07 范畴的等价与同构

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
「元素即态射」（03 章）的列表版：`[x]` 是从单点出发的探针态射。

List 函子**不满**（`[A] → [B]` 的函数未必逐点Cons）、**不本质满**
（无限类型不被 List 覆盖）——反例记录在文档层。

## 7.3 等价的三个面孔（陈述，不机器化）

**定理**（等价判据）：以下等价——
1. F 全忠实 + 本质满；
2. F 有拟逆 G（G∘F ≅ Id、F∘G ≅ Id 的**自然**同构）；
3. 存在伴随等价。

(1) ⟹ (2) 需要**选择公理**（为每个对象挑同构）——构造性数学
要额外结构。本教程机器化到 (1) 为止，(1)⟹(2) 作为诚实边界
（15 章伴随函子定理会正面讨论 Solution Set 条件）。

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
