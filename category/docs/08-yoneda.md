# 08 Yoneda 引理与可表函子

> 对书：贺伟《范畴论》1.6（Yoneda 引理与可表达函子）/《高级范畴论》
> 4.3（hom-函子）/ Simmons 3.5（自然变换的例子）。
> 代码：`examples/08_yoneda/`——本书第一个旗舰定理。

## 8.1 陈述

对任意函子 `F : C → Set` 与任意对象 a：

```text
Nat(Hom(a, -), F)  ≅  F a
```

自然变换的全体与 F 在 a 处的**元素**一一对应。证明给出两个映射：

```text
φ(X)  := X_a(id_a)        （在 id 处取样）
ψ(x)_b(g) := F g(x)       （沿 g 搬运取样）
```

## 8.2 机器证明

**ψ 是自然变换**：对 f : b → c，逐点验证
`F g;F f (x) = F f (F g x)`——就是 Fcomp 的反方向：

```lean
nlaw := by
  intro a₀ b₀ f
  funext g
  show F.FHom (C.comp g f) x = F.FHom f (F.FHom g x)
  rw [F.Fcomp g f]
```

**往返 1**（φ∘ψ = id）：`F id_a(x) = x`——Fid 白送。

**往返 2**（ψ∘φ = id）：对每个 b、每条 g : a → b：
`F g(X_a(id_a)) = X_b(g)`——把 X 的自然性方程**作用到 id_a 上取样**：

```lean
have h : Xc b (C.comp (C.idn a) g) = F.FHom g (Xc a (C.idn a)) :=
  congrFun (Xl g) (C.idn a)
rw [C.idL g] at h
exact h.symm
```

教科书里这步写「把 g 拆成 id_a;g，用自然性方块」——机器版是
`congrFun 取样 + idL 换向`。**Yoneda 是平凡的，但平凡得深刻**：
它说的是「一个对象与世界（所有 hom 集）的交互方式，完全决定了
它自己」。

## 8.3 record 相等的完整版（Lean 独享）

往返 2 的完整陈述是 NT 相等——06 章的依赖字段裂缝。Lean 版：

```lean
theorem yoneda_round2 ... : yonedaTo (yonedaFrom X) = X := by
  obtain ⟨Xc, Xl⟩ := X
  simp only [yonedaTo, yonedaFrom]
  congr 1
  funext b
  funext g
  ...   -- 分量等式；nlaw 字段被内核 PI 拍平
```

Coq 版止步于分量级（`yoneda_round2_pointwise`）、Agda 版走
`≈NT`——三家对同一裂缝的三种缝法在旗舰定理上正面会师。
`#print axioms`：Lean 两方向只用 `[Quot.sound]`（funext 的地基）；
Coq 的 round2 证明本身零新公理（继承 funextd）。

## 8.4 推论与可表函子

- **Yoneda 嵌入** `y : C^op → [C, Set]`（a ↦ Hom(a,-)）全忠实
  ——「范畴可以完全嵌入函子范畴」；
- 取 F := Hom(a, -)：`Nat(Hom a, Hom a) ≅ Hom(a, a)`——
  hom-函子的自变换 = 中对象的自态射；
- **可表函子**（贺伟 1.6）：F 可表 ⟺ F ≅ Hom(a, -)，代表对象 a
  「就是」F 的泛元素——12 章将用它证明「可表函子保持极限」。

Yoneda 嵌入全忠实的机器化需要同构数据在 NT 层的搬运（含 06 章
全部基础设施的联动），本教程作为边界记录；分量级的全部材料
（两个 round trip）已机器验证。

## 8.5 三家写法对照（本章精华）

| | ψ 的自然性 | 往返 2 的关键步 | record 相等 |
|---|---|---|---|
| Coq | funextd + Fcomp 反向 | f_equal 取样 + idL | 分量级 |
| Agda | funext + cong (λk→k x) | cong (λ k → k id) 取样 | ≈NT（setoid） |
| Lean | funext + show 折叠 | congrFun 取样 + idL | **完整**（congr 1） |

## 坑位速记

1. Coq 的 yonedaTo 分量要**双层注解**：外层 lambda 对齐
   `Hom catTy (FObj homF b) (FObj F b)`（期望类型带元变量时）。
2. Agda 的 `yonedaFrom {F = F} {a = a} (yonedaTo {F = F} {a = a} x)`
   要把 F、a 全钉死——留一个下划线就是 UnsolvedConstraints。
3. Agda 的函数级引理（Fcomp）用在点级要 `cong (λ k → k x)`；
   Lean 用 `show` 把投影链折叠到点级再 rw。
4. Lean `simp only [yonedaTo, yonedaFrom]` 先展开定义，
   `congr 1` 才能在结构层拆分——直接 cases/congr 会停在
   yonedaTo 应用的层面。
5. homFun 的宇宙钉死 `Category.{0,0}`/`Category 0ℓ 0ℓ`：
   Hom C a b 要当 Set 层的对象用——源范畴高一格全盘错位。
