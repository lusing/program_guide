# 84 · 收官：CHEATSheet（暂名，F9 扩四书总表）

> 全部正文章（00-45 Jech 路线 + 46-55 Viale 路线 + 56-66 Makinson 路线 + 收官）走完了
> Jech 44 节、Viale 7 章 + 附录 A/B/C/D、Makinson 11 章的全部旅程——
> 从 ZFC 公理到力迫、大基数、描述集合论，再到布尔值逻辑
> 的完整重建。这是速查与总账。

## 84.1 全书结构总表

| 篇 | 章 | 底本 | 主题 |
|---|---|---|---|
| 导引 | 00 | — | 机器证明的七通道立场 |
| 一 公理 | 01-09 | Jech §1-9 | ZFC、序数、基数、实数、AC、基数算术、滤子、奇异、正则 |
| 二 传递模型 | 10-15 | Jech §10-15 | 绝对性、坍缩、L、AC+GCH 在 L、Σₙ、OD |
| 三 力迫 | 16-22 | Jech §16-21 | 泛型扩张、cBa、V^B、CH/AC 独立、积、对称 |
| 四 应用 | 23-27 | Jech §22-26 | Suslin、MA、迭代、组合、cBa 对应 |
| 五 可测 | 28-33 | Jech §27-32 | 测度、超幂、分划、0#、L[U]、弱紧 |
| 六 大基数 | 34-39 | Jech §33-38 | 紧、实值可测、饱和、GCH、力迫应用、超滤 |
| 七 DST | 40-45 | Jech §39-44 | Borel、投影、L 中的投影、Solovay、AD、力迫 |
| **八 Viale 路线** | **46-55** | **Viale 全书** | **布尔值逻辑重建力迫** |
| **九 Makinson 路线** | **56-66** | **Makinson 全书** | **计算者的离散数学与逻辑工具箱** |

## 84.2 Viale 路线篇总表（46-55）

| 章 | 标题 | Viale 节 | 核心定理 |
|---|---|---|---|
| 46 | 预备：正则开集与预序字典 | Ch2+D.1 | ⊥ 五律（勘误版） |
| 47 | 布尔代数：恒等式与 PIT | Ch3.1-3.7 | 有限 BA ≅ 𝒫(atoms) |
| 48 | Stone 对偶与布尔环 | Ch3.8-3.11+D.3 | B ≅ CLOP(St B) |
| 49 | 完备 BA：补全唯一性 | Ch4 | RO(Q, τ_Q) 的普适性 |
| 50 | 泛型滤子/Fn(X,Y)/Δ 引理 | Ch5 | 泛型滤子引理 = Baire |
| 51 | 布尔值语义：可靠性/完备性 | Ch6.1-6.2 | 可证 = 全 B-有效 |
| 52 | 商/满性/Łoś/混合性质 | Ch6.3-6.4 | Łoś ⟺ 满性 |
| 53 | V^B：名的宇宙 | Ch7.1 | 混合引理 + 最大原理 |
| 54 | 力迫定理与 CH 独立性 | Ch7.2-7.4+C | 外 = 内；¬CH + CH |
| 55 | 绝对性：H_χ/Lévy/Shoenfield | App A+B | ZFC⁺ 消除 |

## 84.3 通道分工速查

| 通道 | 角色 | Viale 篇典型锚点 |
|---|---|---|
| Lean+mathlib | 主证明 | Stonean/BooleanRing/AsBoolAlg/CompleteLattice |
| Isabelle/ZF | 二证明 | 谓词式嵌入（Collect-blast 十撞的教训总账） |
| Coq | 三证明 | 决定性 vm_compute + 浅嵌入 BA/名字/公理证书 |
| Agda | 构造性 | 混合性质构造版/check 名复原/泛型链 |
| Julia | 计算 | V^B 有限化身/L⁺ 混合拼装/sin-cos 裁决剧场 |
| Python | 计算 | MALG 数值/超积实验室/树表征实验 |
| Prolog | 有限模型 | 钻石代数真值表/力迫递归定律/双宇宙求值 |

## 84.4 数学工具箱（两线合流）

| 工具 | 章 | 两线表述 |
|---|---|---|
| Cantor κ < 2^κ | 03 | — |
| Schröder-Bernstein | 03 | Embedding.antisymm |
| Zorn 引理 | 05 | zorn_le / PIT（Viale 3.7.4） |
| 超穷归纳/递归 | 02 | WellFoundedLT.induction / Viale A.1 递归保绝对性 |
| Mostowski 坍缩 | 11 | 四通道 / Viale Thm 7.2.4 商-坍缩同构 |
| 布尔补全唯一性 | 17/49 | r.o.(P) 手工 / RO(Q,τ_Q) 定理化 |
| Δ 引理 | 26/50 | 尺寸归纳 / Viale 初等版 |
| **力迫定理** | 18/54 | p ⊩ φ 三值递归 / b ≤ ⟦φ⟧ = 外 = 内 |
| 泛型滤子引理 | 16/50 | 可数族可满足 / = Baire 纲定理 |
| 混合引理 | —/53 | —（Jech 路线无对应） |
| 最大原理 | —/53 | ∃ 的完美名字见证 |
| Łoś 定理 | —/52 | 超积特例 / 满性刻画 |
| ZFC 九公理证书 | —/54 | 九个名字构造（up/∪τ/P^B(τ)/分离名…） |

## 84.5 Viale 篇关键库锚点

**Lean（mathlib v4.33.1 钉版）**：
- `Mathlib.Topology.Category.Stonean.Basic`（Stonean 空间）
- `Mathlib.Algebra.Ring.BooleanRing`（BooleanRing.mul_self/add_self/mul_one_add_self/AsBoolAlg）
- `Mathlib.Order.BooleanAlgebra.Basic`（compl_unique/compl_compl/compl_sup）
- `Mathlib.Order.CompleteBooleanAlgebra`（Set 的 CompleteLattice）
- `Mathlib.Topology.Closure`（closure_union/interior_compl/closure_compl）

**Isabelle/ZF（2025-2）**：
- 无 BA 库——谓词式自建（47-49 章）
- `trans_onD`（Trancl.thy——传递性的显式实例化）
- ZF `function` 小写（非 `Function`）
- `Collect_def` 展开配合 blast 需限量（第十撞总结）

## 84.6 Viale 篇坑位总账（TOP 20）

| # | 坑 | 通道 |
|---|---|---|
| 1 | ⊥ 记号被 PDF 吃掉：五律 (3)(4) 的真形态由有限模型反推 | 全局 |
| 2 | 因子格恒分配：Div(18) 崩在**补律**非分配律 | Julia |
| 3 | 预滤定义须全体有限交>⊥——只查两两有三元反例 | Python |
| 4 | 𝒫({1,2,3}) 超滤子=3（非 8）：主超滤仅原子 | Julia |
| 5 | ZF blast 否定方向 iff 用法死循环（十撞家谱） | Isabelle |
| 6 | Collect 折叠进 blast 搜索空间是灾难——谓词式 Nmem 1 秒通过 | Isabelle |
| 7 | trans 传递性 blast 死循环——trans_onD 显式实例化 | Isabelle |
| 8 | `le` 撞 ZF/Arith 常量名——变量改名 rel | Isabelle |
| 9 | ZF `function` 小写（非 `Function`） | Isabelle |
| 10 | `axiomatization where` 语法（非 `axiomatization X:`） | Isabelle |
| 11 | if-then-else 集合定义的 case 分裂要补 w∈A0 | Isabelle |
| 12 | power 自定义（Coq 无 PG/install） | Coq |
| 13 | `repeat split; vm_compute`（and 非自反——`split` 先行） | Coq |
| 14 | 嵌套 In 的 `[<-|...]` 模式末项要裸（无包装） | Coq |
| 15 | 结构递归名字类型不用索引归纳（dependent match 撞墙） | Coq |
| 16 | Julia 1.13 移除 Random.sample——自写采样器 | Julia |
| 17 | Julia docstring 内 `\ c` 转义序列——用 `∖` | Julia |
| 18 | Prolog forall 不外传绑定——根从首对绑定+余对否定校验 | Prolog |
| 19 | Agda Data.List.all 弃用——自写 allB（沿 #19 套路） | Agda |
| 20 | Agda if_then_else_ 避开——布尔蕴涵 impb 替代 | Agda |

## 84.7 结语

这部教程把 Jech《Set Theory》44 节与 Viale《The Forcing Method
in Set Theory》7 章 + 附录全部覆盖，用七个机器通道逐章验证。
两条路线在 54 章合流：Jech 的偏序-递归力迫（18 章）与 Viale 的
布尔值-语义力迫（46-55 章）被 Cohen 力迫定理统一——
**外定义（谈泛型扩张）= 内定义（谈布尔真值）**。

Viale 路线的教学价值在于把力迫的三个"魔法"（泛型滤子存在、
真值引理、可定义性）还原为布尔代数与拓扑的**定理**：
- 泛型滤子存在 = Baire 纲定理（50 章）
- 真值引理 = Łoś 定理 + 满性（52 章）
- 可定义性 = V^B 的 Δ₁ 名字身份（53 章 + 55 章反射）

**数学事实是唯一的，但表达它的方式是多样的**——这是
"多通道集合论"的教学价值，也是从 00 到 56 的不变主题。

---

上一章：[66 相关性](66-relevance.md) · 下一章：（完）
