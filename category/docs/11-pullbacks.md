# 11 等化子与拉回

> 对书：贺伟《范畴论》2.2（等值子）/ 2.4（拉回与推出）/
> 《高级范畴论》3.3（回拉）/ 3.4（核与余核）/ Simmons 2.6、2.7。
> 代码：`examples/11_pullbacks/`。

## 11.1 从积到拉回

积回答「两个对象怎么一起」，拉回回答「**怎么一起且兼容**」：
给定 f : A→C、g : B→C，拉回是泛方块

```text
      P
   p1/  \p2
   A    B
    \f  /g
      C
```

`p1;f = p2;g`，且泛于一切竞争的「交换对」(u, v)。

```lean
structure IsPullback (C) (a b c p) (f g p1 p2) where
  square : C.comp p1 f = C.comp p2 g
  univ : ∀ (x) (u v), C.comp u f = C.comp v g →
    Σ' m, (C.comp m p1 = u ∧ C.comp m p2 = v) ∧
      ∀ m', C.comp m' p1 = u → C.comp m' p2 = v → m' = m
```

**等化子 = 沿对角线的拉回**（贺伟 2.2 的 `Δ : C → C × C` 之后）；
**推出 = 反范畴里的拉回**；**核 = 零态射语境下的等化子**（高级 3.4，
需要加法范畴的零对象——22 章正式化）。对偶链条在此全部就位。

## 11.2 旗舰：单态射的拉回仍是单态射

贺伟 2.4 的经典命题，抽象证明（三家零公理）：

```text
要证 p2 单：u;p2 = v;p2 ⟹ u = v
1. 造锥：u 自己的 (u;p1, u;p2) 满足锥方程（assoc + square）
2. u 是该锥的中介（唯一性第一次用）
3. v 的 v;p1 = u;p1：两边后复合 f 后用方块换向到 (u;p2);g
   （assoc → square → ←assoc → ←Huv 的接力），再由 f 单性收网
4. v 也中介同一锥 → v = u（唯一性第二次用）
```

这是「**唯一性当武器**」的完整展示——与 10 章「积唯一到同构」
同一招式的加强版。Lean 版的 Evp1 换向链：

```lean
rw [C.assoc v p1 f, C.assoc u p1 f, sq, ← C.assoc v p2 g, ← Huv]
exact C.assoc u p2 g
```

每一步 rewrite 的方向都要对着目标摆正——这是方块追图的
机器纪律。

## 11.3 TyCat 里的纤维积

`{ p : A × B | f p.1 = g p.2 }`——中介函数 `z ↦ ⟨(u z, v z), 证据⟩`。
唯一性的收尾三家的路线：

| | 路线 | 公理账 |
|---|---|---|
| Coq | `sig_ext`（自造：destruct + PI） | funext + PI |
| Lean | `Subtype.ext`（核心库）+ `Prod.ext` | funext（内建） |
| Agda | Σ 证明分量需证明无关性——**边界记录** | 不机器化 |

Agda 版止步于抽象定理 + 定义（文档说明 setoid 补全路线）——
「诚实边界」的又一次实践。

## 11.4 拉回的用途地图（文档层）

- 子对象纤维：Sub(A) ≅ Hom(-, A) 的「拉回作用」（贺伟 1.5）；
- 交换代数里 tensor 的拉回解释（高级 3.3 习题）；
- 层论的底变换（base change）：27 章的伏笔；
- Simmons 2.7 的 pushout 习题矩阵（集合的并、群的自由积）。

## 11.5 全家福：等化子、余等化子、核对、原像（Simmons 2.6/2.7）

**余等化子**（coequalizer）= 等化子的对偶：`f, g : A ⇉ B` 的
余等化子是把「f 与 g 的差」**商掉**的最小对象。Set 里：

```text
coeq(f,g) = B / ~    其中 ~ 是 f(x) ~ g(x) 生成的等价闭包
```

闭包是必须的：`f(x₀) ~ g(x₀)` 与 `f(x₁) ~ g(x₁)` 会传递性地
粘出新的等同。对照 13 章——合流模板的商只有被动认同、无需
闭包，这就是「平行对模板不合流」的代价。Grp 的余等化子 =
商掉正规闭包；Ab = 商掉子群；Top = 商拓扑。

**核对**（kernel pair）：`f : A → B` 与自己的拉回——`A ×_B A`，
「同纤维对」的空间。定理：f 单 ⟺ 核对是对角线（对角 =
等化子情形的退化拉回）。核对是「f 的等价关系」的范畴化，
商与核对的一来一回（群同态基本定理、层化的神来之笔）贯穿
后书。

**原像是拉回**：子集 `C ⊆ B` 沿 `f : A → B` 的拉回 = `f⁻¹(C)`
配包含映射。机器版点式 rfl（11.3 的纤维积里取 g := 包含）。
推论免费：**单调函数的逆像保交并**、连续映射的原像保开——
「拉回保结构」的一行特例。张量积的底变换（base change）、
子对象层的回拉（27 章）全是这一个方块的变奏。

**推出**（pushout）= 拉回的对偶：Set 里 =「沿粘合映射焊接」：

```text
A ∪_f B = (A + B) / (a ~ f(a))     （f : C → B 焊接 C 的像）
```

群论的自由积 amalgam、拓扑的粘合空间（adjunction space）、
图的并——都是它。机器化的重头戏在 13 章（合流版），非合流
版（真商）需要商集基建，文档级记录。

## 坑位速记

1. Coq 依赖位的 rewrite 会把 motive 弄病（「Abstracting leads to
   ill-typed」）：换向用 transitivity 桥接、或 sig_ext 只比第一分量；
   `destruct (m' z) eqn:Emz` + `f_equal proj1_sig Emz` 是连接
   「取样方程」与「构造子分量」的官方桥梁。
2. Coq `remember` 的 eqn 方向是 `w = 原项`；PI 公理被 Set Implicit
   Arguments 隐化首参——`@PI _ Pa Pb` 显式给。
3. Coq bullet 嵌套：外层 `-` 里的子目标用 `+`（用错层级报
   「Wrong bullet / not finished」）。
4. Lean 的 IsPullback 用 structure（equation 是 Prop、univ 是 Type，
   Prod 装不下混居）；类型实参顺序 (a b c p) (f g p1 p2)——
   subtype 的匿名构造要落在 p 槽位。
5. Agda where 模式绑定必须搬 let；≈/链的槽位方向（⟨⟩ 里的证明
   是「当前行 ≡ 下一行」）贴错就 UnequalTerms。

---

上一章：[10 积与余积](10-products.md) · 下一章：[12 极限的一般理论](12-limits.md)
