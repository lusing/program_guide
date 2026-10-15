# 46 · Viale 路线第一站：拓扑、正则开集与预序字典

> 从本章起进入第八篇。Jech 路线（16-22 章）已经用偏序、泛型扩张、
> 完备布尔代数、V^B 把力迫的**骨架**走通了；Viale 路线要从零重建
> 这座塔，而它的地基不是偏序，是**拓扑**——准确说，是每个拓扑空间
> 自带的那座完备布尔代数：正则开集族 RO(X)。
>
> 本章覆盖 Viale 第 2 章（预备）与附录 D.1（网收敛）的精髓。

为什么换一条路？Jech 1978 年的书先定义偏序上的力迫关系（三值递归
定义），再补完备布尔代数；Viale 2024 年的书反其道而行：**先把布尔
值语义当作一阶逻辑的自然推广**（真值从 {0,1} 换成任意布尔代数 B），
再证明力迫关系不过是这套语义的导出物。这条路的入场券是三块拓扑
事实——正则开集、预序上的"字典"（稠密/前稠密/极大反链的拓扑对照）、
序拓扑。它们就是本章的内容。

## 46.1 拓扑词汇速查

一个拓扑空间是偶对 (X, τ)，其中 τ ⊆ 𝒫(X) 含 ∅ 与 X、对任意并和
有限交封闭。围绕 τ 有一组本章反复使用的词汇：

- **基（basis）** τ 的子族 𝓑，使 τ 中每个开集都是 𝓑 的成员之并；
  **半基（semibasis）** 𝓢 只要求 𝓢 的有限交构成基。等价地，𝓢 是
  含它的最小拓扑的生成元集。
- **闭包 Cl(A)**：含 A 的最小闭集；**内部 Int(A)**：含于 A 的最大
  开集。两个幂等算子：Cl(Cl(A)) = Cl(A)，Int(Int(A)) = Int(A)。
- **孤立点** x：{x} 既开又闭（clopen）。CLOP(X, τ) 记 clopen 集族。
- 分离层级：T₂（Hausdorff，两点可用不交开集分离）、T₃（点与闭集
  可分离）、T₄（正规，两闭集可分离）。
- **0 维**：有 clopen 基；**极不连通（extremally disconnected）**：
  开集的闭包是开集。后者的 Stone 空间化身（Stonean 空间）正是
  完备布尔代数的拓扑对偶（48-49 章的主角）。

两个今后要用的标准事实（证明留作热身习题，见 46.7 节）：

**命题（闭包并律）** 对任意 A, B ⊆ X：
Cl(A ∪ B) = Cl(A) ∪ Cl(B)。

注意闭包对**无穷**并不并连续（Cl(⋃ₙ Aₙ) 可以严格大于 ⋃ₙ Cl(Aₙ)），
这一"缺陷"正是正则开集非平凡性的来源。

**命题（乘积 Hausdorff）** ⨉ᵢ Xᵢ 是 Hausdorff 当且仅当每个 Xᵢ 是。

## 46.2 正则开集：定义与点态刻画

**定义（正则开）** 开集 A 称为**正则开（regular open）**，若
A = Int(Cl(A))。对任意 A ⊆ X，记
Reg(A) := Int(Cl(A))，
称为 A 的**正则化**。RO(X, τ) 记正则开集全族。

**例（欧氏直线上）** 任何开区间 (a,b) 正则；但
U = (1,2) ∪ (2,3) 不正则：Cl(U) = [1,3]，Int(Cl(U)) = (1,3) ≠ U。
点 2 被"缝合"回来了——正则化把"可缝合的裂缝"填平。

正则开集有一个极其好用的**点态刻画**：

**引理（Viale Lemma 2.1.4）** 对开集 A：
Reg(A) = { x ∈ X : 存在开集 U ∋ x 使 A ∩ U 在 U 中稠密 }。

*证明*。（⊆）取 x ∈ Reg(A)，令 U = Reg(A)。U 是含 x 的开集，且
A ∩ U 在 U 中稠密：A 在 Cl(A) 中稠密，而 U = Int(Cl(A)) ⊆ Cl(A)
是开集，故 A ∩ U 在 U 中稠密。
（⊇）设 U ∋ x 开且 A ∩ U 在 U 中稠密，则 A ∩ U 也在 Cl(U) 中稠密
（Cl(A∩U) = Cl(U)），于是 U ⊆ Cl(A)，从而 x ∈ Int(Cl(A))。∎

这个刻画解释了欧氏例子：x = 2 有邻域 U 使 U ∩ ((1,2)∪(2,3)) 在
U 中稠密（比如 U = (1.5, 2.5)），故 2 ∈ Reg((1,2)∪(2,3)) = (1,3)；
而 x = 1、x = 3 找不到这样的邻域——它们在 A 的"外侧"。

**注（Viale Remark 2.1.6）** 若 U 见证 x ∈ Reg(A)，则 U 的任何
含 x 的开子邻域 V 同样见证：A ∩ W 对 W ⊆ U 开是稠密的。这说明
Reg(A) 是"局部可判定"的性质——力迫语义里"条件加强仍保持力迫"
的拓扑雏形。

## 46.3 补运算 ⊥ 与五律

**记号** 对 V ⊆ X，令
V⊥ := X ∖ Cl(V)。
约定"⊥ 优先左结合"：U⊥⊥ 表示 (U⊥)⊥。U⊥ 是**开**集（闭集之余），
且 V ↦ V⊥ 在有限拓扑演算中扮演布尔补的角色——只是要叠两次才
落回正则开世界。本节的核心是五个恒等式（Viale Fact 2.1.10）：

**定理（⊥ 五律）** 对拓扑空间 (X, τ) 的任意子集 U, V：
1. U ⊆ V ⟹ V⊥ ⊆ U⊥（反单调，任意 U, V）；
2. (U ∪ V)⊥ = U⊥ ∩ V⊥（De Morgan，任意 U, V）；
3. **Reg(V) = V⊥⊥**（任意 V——双 ⊥ 就是正则化）；
4. U 开 ⟹ **U⊥⊥⊥ = U⊥**（一次 ⊥ 已正则）；
5. U, V 开 ⟹ (U ∩ V)⊥⊥ = U⊥⊥ ∩ V⊥⊥。

*证明*。
(1) U ⊆ V ⟹ Cl(U) ⊆ Cl(V) ⟹ X∖Cl(V) ⊆ X∖Cl(U)。
(2) 用闭包并律：X∖Cl(U∪V) = X∖(Cl(U)∪Cl(V)) = U⊥ ∩ V⊥。
(3) 逐点等价链：x ∈ Reg(V) ⟺ x 有开邻域 N ⊆ Cl(V) ⟺ x 有开邻域
N 与 X∖Cl(V) 不交 ⟺ x ∉ Cl(X∖Cl(V)) ⟺ x ∈ X∖Cl(X∖Cl(V)) = V⊥⊥。
第三个 ⟂ 用了"N 与 A 不交且 N 开 ⟹ N ⊆ X∖A"。
(4) U 开 ⟹ U ⊆ Int(Cl(U)) = Reg(U) = U⊥⊥（记为 (2.1)）。对
(2.1) 用 (1)：U ⊆ U⊥⊥ 给出 U⊥⊥⊥ ⊆ U⊥。再把 (2.1) 用到 U⊥
（它开）：U⊥ ⊆ U⊥⊥⊥。两个包含合并。
(5) 由引理 2.1.4：x ∈ Reg(U)∩Reg(V) 取公共邻域 W 使 U∩W、V∩W
都在 W 中稠密，则 (U∩V)∩W 在 W 中稠密，x ∈ Reg(U∩V)；反向同理。
再用 (3) 把 Reg 换成 ⊥⊥。∎

> **勘误笔记**：本书 PDF 提取文本把 ⊥ 记号全部吃掉，五律 (3)(4)
> 的字面形态不可直接读出。我们在 4 点有限拓扑上用模型检查反推：
> 若把 (3) 误读成 "Reg(V)⊥⊥ = V⊥"，取 V = ∅ 立即矛盾（左边 ∅、
> 右边 X）；再由证明文本的四重等价链锁定真形态 (3) Reg(V) = V⊥⊥、
> (4) U⊥⊥⊥ = U⊥。多通道教学在这里当场兑现了它的防错价值。

**推论 A（幂等性）** Reg(Reg(V)) = Reg(V) —— 由 (3)(4) 直接得出：
正则化是幂等算子，RO(X) 恰是它的不动点集。

**推论 B（RO 对交封闭）** 两个正则开集的交正则开——由 (5)，
两个不动点之交仍是不动点。

注意 RO(X) 对**并**不封闭：Reg((1,1.5)∪(1.5,2)) ≠ (1,1.5)∪(1.5,2)
（后者根本不是"闭包取内部"的不动点）。所以 RO(X) 上的"并"必须定义为
U ∨ V := Reg(U ∪ V)——这不是病，而是 49 章完备布尔代数结构的种子。
Python/Julia 通道将在小拓扑上把五律逐条机器验证（见 46.6）。

## 46.4 预序字典：序论概念 × 拓扑对照

**定义（预序）** 拟序/预序 (P, ≤)：自反、传递。反对称时称偏序。
严格关系 x < y := (x ≤ y 且 y ≰ x)。**相容** x∥y：存在 z ≤ x 且
z ≤ y；否则**不相容**，记 x ⊥ y。链/反链/上界/上确界 ⋁/下确界 ⋀
照常。**Zorn 引理**：链均有上界的预序有极大元（选择公理的等价形）。

对偏序 P 上的子集 D：
- D **稠密**：∀x∈P ∃y∈D (y ≤ x)；
- D **前稠密（predense）**：其下闭包 ↓D = {q : ∃d∈D, q ≤ d} 稠密；
- D **极大反链**：前稠密的反链。

**定义（分离性与无原子性）** P **可分离（separative）**：若
x ≰ y，则存在 z ≤ x 使 z ⊥ y。P **无原子（atomless）**：∀p∃q<r≤p
（每个条件都可真正劈开）。**原子**：极小元。

两个小事实在力迫里反复出现（证明一行，但要点破）：

**事实（Viale Fact 2.2.13）** 原子 a 属于 P 的每个稠密集 D。
*证*：D 稠密 ⟹ D ∩ ↓{a} ≠ ∅，而 ↓{a} = {a}。∎
——所以对含原子的偏序，"泛型"是平凡的：原子自动穿过一切稠密集。

**事实（Viale Fact 2.2.14，稠密的传递性）** D ⊆ E ⊆ F，D 在 E 中
稠密、E 在 F 中稠密 ⟹ D 在 F 中稠密。∎

**序拓扑。** 预序自带拓扑：以 ↓p = {q : q ≤ p} 为**基**生成 τ_P
（Viale Def. 4.2.3）。它有四条性格：
1. 开集 = 下闭集；闭集 = 上闭集（取余）。
2. ↓p 是 p 的最小开邻域。
3. D ⊆ P 序论稠密 ⟺ D 在序拓扑中拓扑稠密。
4. 开集族对**任意交**封闭（下闭集族如此）——远超一般拓扑。

于是序论字典与拓扑字典逐条对译（Viale Fact 2.2.16）：

| 序论 | 序拓扑 |
|---|---|
| D 稠密 | D 拓扑稠密 |
| X 下闭 | X 开 |
| X 前稠密 | ↓X 稠密开 |
| X 极大反链 | 前稠密 + 两两不交（的"开补"形态）|
| X 在 p 下方稠密 | X ∩ ↓p 在 ↓p 中稠密 |

**态射三档。** 预序间映射 i : P → Q 分三档（Viale Def. 2.2.17）：
保序（morphism）、保序且保不相容（embedding）、把前稠密集映为
前稠密集（complete embedding）。第三档在 20 章（Jech 路线的积力迫）
见过，49 章布尔补全里它将以"稠密像"的形式再现。注意 embedding
**不必单射**——(τ∖{∅}, ⊆_dense) 到其 RO 的映射就是典型非单射例
（Viale Remark 4.2.10）。

**驱动例子（Cohen 偏序的雏形）** 令 2^<ω = 全体 0-1 有限串，
s ≤ t := t ⊆ s（t 是 s 的初始段）。这是**可数、可分离、无原子**
的预序（Viale Exercise 2.2.12）：若 s ≰ t（t 不是 s 的初始段），
则 s 与 t 的"最长公共初始段"的延长中可找到与 t 不相容者。另一面，
映射 s ↦ N_s = {f ∈ 2^ω : s ⊆ f} 把 2^<ω 序保持、反序保持地嵌入
(τ∖{∅}, ⊆) 且像稠密（{N_s} 是乘积拓扑的基）——Viale Exercise
2.2.18。这条嵌入在 49 章升级为"2^<ω 的布尔补全是 RO(2^ω)"。

## 46.5 与第三篇的接口

第三篇 16 章从"偏序 + 稠密集 + 泛型滤子"直接进入力迫。本章给同一
套概念换了拓扑底座：

- 16 章的"D-泛型滤子"在拓扑语言里是"穿过一族稠密开集的相容链"；
  Viale 5.1 节（50 章）将证明泛型滤子引理恰是紧 Hausdorff 空间上
  的 **Baire 纲定理**。
- 17 章手工构造的 r.o.(P)（正则割/Dedekind 割法）在 Viale 路线里
  是定理：**布尔补全唯一性定理**（49 章，Viale Thm 4.2.4），其
  构造正是 j(p) = Reg(↓p) ⊆ RO(P, τ_P)。
- 21 章链条件（ccc）的拓扑意义：RO(X) 的 ccc ⟺ X 无不可数族两两
  不交的非空开集（49 章 Lemma 4.3.2 的字典转译）。

读者现在可以把 16-22 章的记忆挂到这三种挂钩上重走一遍。

## 46.6 机器通道

本章程式量小、语义重，七个通道各取一块可判定碎片。

**Lean（`Settheory/Ch46Regopen.lean`）**：mathlib 没有现成的
RegularOpen 文件，我们自己定义并证明两条通用定理——幂等性与
"内部-闭包对偶"。核心代码：

```lean
/-- 正则开集：A = int (cl A) -/
def IsRegularOpen (s : Set X) : Prop := interior (closure s) = s

/-- 幂等性：Reg(Reg(V)) = Reg(V)（Viale Fact 2.1.10 推论 A） -/
theorem reg_reg (s : Set X)
    (h : IsOpen s) : IsRegularOpen (interior (closure s)) := by
  -- 关键：int (cl (int (cl s))) = int (cl s)，
  -- 用 cl (int (cl s)) = cl s（int (cl s) 在 cl s 中稠密）
  ...
```

`reg_reg` 的证明骨架：`interior (closure (interior (closure s))) =
interior (closure s)` 的难点是反向包含，需要 `cl (interior (cl s)) =
cl s`，而这正是"开集 U 在 Cl(A) 中稠密当且仅当 U ⊆ Cl(A) 开且
A ⊆ Cl(U)"的特例——mathlib 的 `dense_iff_interior_closure` 系列
引理可拼出。文件里再补一条 `reg_inter_of_regular`（正则开集是
开集）作为 RO(X) 世界的小门卫。

**Julia（`examples/julia/46_regopen.jl`）**：在 4 点有限空间上枚举
一个非平凡拓扑，实现 `cl/int/reg/⊥` 四个算子，然后**逐条验证五律
加两推论**。节选：

```julia
regularize(U) = int_(cl(U, opens, Ω), opens)
perp(U) = setdiff(Ω, cl(U, opens, Ω))

# 五律 (2)：(U ∪ V)⊥ == U⊥ ∩ V⊥
@assert perp(union(U, V)) == intersect(perp(U), perp(V))
# 五律 (5)：开集上 (U ∩ V)⊥⊥ == U⊥⊥ ∩ V⊥⊥
@assert perp(perp(intersect(U, V))) ==
        intersect(perp(perp(U)), perp(perp(V)))
```

全空间幂集有 16 个子集、拓扑 5 个开集，全部断言 `@assert` 跑通后
打印"五律 OK"。这是**决定性有限验证**：命题在有限模型上逐点核对。

**Python（`examples/python/46_regopen.py`）**：换 Sierpiński 空间
{0,1}（开集 {∅,{1},{0,1}}）与一个 4 点空间，验证引理 2.1.4 的点态
刻画与 Fact 2.1.8（U∩V ≠ ∅ ⟺ U∩Reg(V) ≠ ∅）：

```python
def reg(A, opens, Omega):
    return interior(closure(A, opens, Omega), opens)

for U in opens:
    for V in opens:
        assert bool(U & V) == bool(U & reg(V, opens, Omega))
```

Sierpiński 空间虽小，却已非平凡：{1} 是开的非闭集，Reg({1}) = {1}
但 Cl({1}) = {0,1}——它是"极不连通"概念的最小反例素材。

**Coq（`examples/coq/Ch46_regopen.v`）**：同一 3 点拓扑上的**决定性
验证**——不是抽样，而是把五律作为全称命题证明。架构分三层：

```coq
(* 清点引理：In l tau 换成 "l = ∅ ∨ l = {0} ∨ … ∨ l = Ω" *)
Lemma tau_cases : forall l, In l tau -> l = nil \/ … \/ l = Omega.

(* 布尔反射：In l tau ⟺ in_tau l = true（可计算谓词） *)
Lemma in_tau_In : forall l, in_tau l = true -> In l tau.

(* 定律：先 subst 消元，再 vm_compute 断真 *)
Lemma law2 : forall U V, In U subsets -> In V subsets ->
  perp (unionl U V) = interl (perp U) (perp V).
Proof. … subst U; subst V; vm_compute; reflexivity. Qed.
```

集合用升序列表表示，`unionl/interl/compl` 的输出统一过 `norm`
（去重 + 插入排序）——否则 `{0,1}∪{0,2}` 会算成 `[2;0;1]` 而
与规范形 `[0;1;2]` 失配。两个抽样引理展示正则化的两种极端：
`reg [0;1] = Ω`（{0,1} 在本拓扑中稠密）与 `reg [1] = ∅`
（非开集 {1}：Cl = {1} 但 Int({1}) = ∅）。

**Agda（`examples/agda/Ch46_agda`……见 `Ch46_regopen.agda`）**：
有限预序字典：在 2^<3（8 个 0-1 串的前缀序）上定义
dense/predense/antichain/filter，验证 Fact 2.2.13（原子进一切稠密集）
与 Fact 2.2.14（稠密传递）的有限形式。

**Prolog（`examples/prolog/46_regopen.pl`）**：同一 2^<4 前缀序上
写 `dense/1、predense/1、compatible/2`，查询"找出全部极大反链"、
"验证空根 Δ 系统的稠密性"，为 50 章 Δ 引理的 Prolog 搜索热身。

**Isabelle/ZF（`examples/isabelle/ST46/Regopen.thy`）**：ZF
object-logic 没有拓扑库，正好做纯序论部分：定义 `dense/predense/
max_antichain/filter`，Isar 证明 Fact 2.2.13 与 2.2.14：

```isabelle
lemma atom_in_dense: "[| a ∈ P; is_atom(P, a); dense(P, D) |] ==> a ∈ D"
```

两事实的证明各五行——但要在 ZF 里把"↓{a} = {a}"写对，牵出
`Inter` 与下闭包的定义细节，这正是 object-logic 的教学价值。

## 46.7 习题

1. **（纸笔）** 补全 46.1 的闭包并律证明（两个包含各自一行）。
2. **（纸笔）** 证明 2^<ω 是可分离预序（Viale Ex 2.2.12 的提示：
   先证 s ⊥ t ⟺ s⌢t 不是函数 ⟺ s、t 互不为初始段）。
3. **（纸笔）** 证明 (τ∖{∅}, ⊆) 不是可分离的（取两个开集
   U ⊊ V 但 V∖U 无处稠密）。
4. **（机器）** 把 Julia 通道的拓扑换成 4 点空间的另两个非同构
   拓扑，重跑五律断言（提示：拓扑由开集族列表直接给出）。
5. **（纸笔）** 序拓扑的开集族对任意交封闭——用它证明：若 P 有
   两点 p ≠ q 且 p ≤ q，则序拓扑不 Hausdorff（Viale Remark 2.2.15）。
6. **（纸笔）** 证明 Fact 2.1.7：U∩V 在 V 中稠密 ⟺ Reg(V) ⊆ Reg(U)
   （两个方向都用引理 2.1.4 的邻域判据）。

---

上一章：[45 DST 中的力迫](45-dstforcing.md) · 下一章：[47 布尔代数](47-ba.md)
