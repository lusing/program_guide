# CHEATSheet：范畴论速查（category 版）

> 23 章正文的浓缩。三家以 Coq / Agda / Lean 为主。

## 1 核心定义一页

```text
范畴    Obj + Hom + idn + comp + idL/idR/assoc
对偶    C^op：箭头掉头、复合倒序（idL↔idR 定律互译）
mono    g;f = h;f ⟹ g = h          epi    f;g = f;h ⟹ g = h
iso     有双侧逆                    终对象  恰一条到它的态射
积      双出泛性质（存在+唯一）      拉回    p1;f = p2;g 泛方块
极限    图=函子、锥=NT(Δc,D)、终锥   指数    curry 双射
函子    保恒等 + 保复合              NT      一族态射 + 自然性方块
Yoneda  Nat(Hom(a,-), F) ≅ F a      伴随    η/ε + 三角恒等式 ⟺ hom-双射
单子    (T, η, μ)：η·Tη = μ·Tμ 单位律 + μ 结合律
```

## 2 三家写法对照

| | Coq 8.20 | Agda 2.8 | Lean 4.25 |
|---|---|---|---|
| 范畴 | `Record Category@{u v}` + 双开关 | `record Category o ℓ` | `structure Category.{u,v}` |
| 复合 | 图序 `comp f g`（先 f） | 同 | 同 |
| record 相等 | 分量级止步 | setoid | 结构 η+内核 PI 免费 |
| funext | 公理入账 | postulate | 核心定理 |
| Σ 混居 | sig/sigT | Σ | Σ'（PSigma） |
| 索引族递归 | revert+induction+Defined | 模式匹配自动 | 方程式 + simp only |
| 点取样 | `f_equal (fun k => k z) H` | `cong (λ k → k z) H` | `congrFun H z` |

## 3 泛性质证明套路

```text
「唯一性当武器」（09/10/12 章共享）：
  1. 用泛性质取标准中介 m（对目标锥取样一次）
  2. 把候选 h 喂进唯一性（方程 reflexivity）→ h = m
  3. 把候选 h' 换向后同样喂入 → h' = m
  4. 合并：h = h'

「方块追图」（10/13/18 章共享）：
  rewrite 链按 assoc → (定律/自然性) → ←assoc 接力；
  每步方向对着目标摆正，transitivity 桥接依赖位。
```

## 4 Yoneda 的两个方向（08 章）

```text
φ(X)  = X_a(id_a)         在 id 处取样
ψ(x)_b(g) = F g(x)         沿 g 搬运
φ∘ψ = id  ← Fid 白送
ψ∘φ = id  ← X 的自然性作用到 id 上取样 + idL 换向
```

## 5 三大分岔点

1. **函数相等**：funext 的三种待遇（公理/postulate/定理）——
   所有「点式→函数级」的升级都要过这道门。
2. **依赖字段 record 相等**（NT 的 nlaw 依赖 ncomp）：三家三种
   缝法（06 章详述）——2-范畴形式化的第一道门。
3. **宇宙**：Coq 真多态要显式开关；Agda 四层 level 账；
   Lean 具名 Category.{u,v}。

## 6 精选坑位（TOP-10）

1. Coq `Set Implicit Arguments` 隐化范畴参数——应用要 @。
2. Coq 默认 @{u v} 是单态——真多态要 `Set Universe Polymorphism`。
3. Coq 字段值连隐式 binder 绑定：comp 5 个、assoc 7 个下划线。
4. Coq 依赖位 rewrite 弄病 motive——transitivity 桥/sig_ext。
5. Agda 子句体只见模式绑定——隐式 C/D/F/G 具名绑定。
6. Agda where 不能模式绑定——搬 let。
7. Agda `*` 递归在第一参数；*-suc 右端反方向（乘法方向学）。
8. Lean `/-!` 内容不能以 `-` 开头（4.25 扫描器）。
9. Lean OfNat 穿不透结构投影——`(2 : Nat)` 标注。
10. Lean rw 看不见 iota 折叠——`simp only [f]` 先暴露。

## 7 build.ps1 用法

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 08'  # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang agda'   # 单语言
```
