# 75 · 传递化：刚性与有秩关系

> 本章提炼冯琦 §1.10，第一卷的收官性结构理论。序数理论的核心
> 事实——"同构的序数相等"（71 章）、"每个秩序唯一同构于序数"
> （72 章表示定理）——在此推广为两个大定理：**传递集合刚性定理**
> （定理 1.95：E-同构的传递集合不仅同构而且**相等**，且同构映射
> 就是恒等）与**传递化定理**（定理 1.97/1.100：任何自同一
> [extensional] 的有秩结构 (A,E) 都唯一坍缩到传递集合 M，坍缩映射
> π(a) = {π(y) | y E a}——序数是"秩序坍缩"的特例，V_α 是"∈ 坍缩"
> 的身份情形）。工具链：∈-归纳法（TC + 极小原理）、∈-递归定义
> （定理 1.96）、秩映射定理（定理 1.98：有秩关系必有典型秩函数
> ρ(a) = sup{ρ(y)+1}）。与 11 章（Jech 的 Mostowski 坍缩）与 09 章
> （秩层级）互为表里：Jech 把坍缩用在传递模型与绝对性，冯琦把它
> 讲成"传递集合 = 带 ∈ 的标准形"的第一性原理。

## 75.1 ∈-归纳与 ∈-递归

> **定理 1.94（∈-归纳法）** 若 Φ(∅) 且 ∀α (∀y∈α Φ(y) → Φ(α))，
> 则 ∀α Φ(α)。*证明*：反例 α 的 TC({α}) 里取 ∈-极小反例，其元素
> 全部满足 Φ，条件给出 Φ——矛盾。∎

——70 章极小原理的重装版：它不仅给"极小元"，还给**全域归纳**。
序数的超限归纳（71 章定理 1.54）是其限缩到 Ord 的截面。

> **定理 1.96（∈-递归定义）** 对类函数 G 存在唯一类函数 F：
> F(α) = G(F↾α)——**对一切集合**（不只序数）。
> 证明骨架与 71 章定理 1.56 相同：传递集上的"部分解"由映像存在
> 原理收集、和谐拼接；唯一性用 ∈-极小反例。∎

机器锚点：Isabelle/ZF 的 `Transset_induct` 与 `transrec` 正是这两条
定理的官方化身——73 章自建 oexp 时已经天天在用它们（transrec2
是 transrec 的三情形包装）。Agda 通道则给出定理 1.94 的**构造性
化身**：HF 玫瑰树上的结构归纳就是 ∈-归纳本身——经典证明里"取
极小反例"的排中论证，在构造世界换成可达性证据直接长在数据里：

```agda
hf-ind : ∀ (P : HF → Set) →
         (∀ h → (∀ c → c ∈l children h → P c) → P h) →
         ∀ h → P h
hf-ind P step h = step h (go h)
  where
  go : ∀ h → ∀ c → c ∈l children h → P c
  go (hfset cs) c m = aux cs c m
    where
    aux : ∀ ds → ∀ c → c ∈l ds → P c
    aux (c' ∷ ds') c here = hf-ind P step c'
    aux (c' ∷ ds') c (there m') = aux ds' c m'
```

## 75.2 传递集合的刚性

> **定理 1.95（刚性定理）** f: (M,∈) ≅ (N,∈)（M, N 传递）⟹
> **M = N 且 f = id**。
> *证明*：对 a ∈ M 用 ∈-归纳证 f(a) = a：f↾a 恒等给出 f(a) ⊆ a
> （保 ∈）；反向 a ⊆ f(a)：取 y ∈ f(a)，由双射 y = f(b) 且 b ∈ a，
> 归纳给出 y = f(b) = b ∈ a。故 f(a) = a，M = N。∎

序数的"同构即相等"是它的特例（序数是传递集）。刚性 = **结构
自决**：传递集合身上没有任何"换名"的自由。这是"集合论标准形
理论"的支柱——后面一切唯一性（坍缩唯一、序型唯一）都从这里来。

Isabelle/ZF 通道（ST75/Collapse.thy）把最小非平凡实例全程证出：
2 = {0,1} 上的 ∈-同构只有恒等——证明是冯琦"双围"的逐字复刻，
连 0∈1、0∈2 这类底层成员事实都用 `succI1`/`succI2` 显式记账
（二元素情形拆解靠 `elem2E`：x∈2 分为 x=0、x=1 两案，由
`succE`+`emptyE` 两条 elim 规则驱动）：

```isabelle
lemma rigid_2:
  assumes f: "f ∈ 2 → 2"
      and pres: "∀x∈2. ∀y∈2. x∈y ⟷ f`x ∈ f`y"
      and surj: "∀y∈2. ∃x∈2. f`x = y"
  shows "∀x∈2. f`x = x"
```

f`0 = 0 的论证：f`0 ∈ 2 故 f`0 ∈ {0,1}；若 f`0 = 1 则 0 ∈ f`0，
满射给出 z 使 f`z = 0，保关系反向给出 z ∈ 0——矛盾。f`1 = 1 的
论证：若 f`1 = 0 则 0 ∈ 1 经保关系正向给出 f`0 ∈ f`1 = 0——矛盾。

**定义 1.99（自同一 / extensional）**：非空 A 自同一 ⟺
∀x,y∈A (x∩A = y∩A → x = y)——**外延公理在 A 的相对化**。
例 1.34：传递集都自同一；A = {ω, ⋃ω∪{ω}} 自同一但既非传递亦非
序数集；A = {2,3,{2}} **不**自同一——2∩A = ∅，3∩A = {2} = {2}∩A，
但 3 ≠ {2}：外延性在 A 内失效。

## 75.3 传递化定理（集合版）

> **定理 1.97（传递化定理，A 上的 ∈）** A 自同一 ⟹ 存在唯一 π 与
> 唯一传递 M：π: (A,∈) ≅ (M,∈)，且 A 的传递子集 B 上 π↾B = id。
> *证明*：唯一性由刚性。存在性：∈-递归定义
> **π(a) = {π(y) | y ∈ a∩A}**；
> M = π[A] 自动传递；π 单射——若 π(a) = π(y) 而 a ≠ y，自同一性
> 给 x ∈ (a∩A)−(y∩A)，追 ∈-极小反例穿帮。B 传递时 a ∈ B →
> a∩A = a → π(a) = a。∎

**例 1.35**：E = {2n | n ∈ ω} 的传递化像是 ω，π(2n) = n——
"偶数宇宙"坍缩成自然数宇宙。坍缩 = **撕掉冗余的皮，只留 ∈-骨架**。

机器通道把坍缩做成可执行算法。Python 版（examples/python/
75_collapse.py，Julia/Prolog 同构）的核心引擎只有一层记忆化递归：

```python
def collapse(nodes, ext):
    """π 的记忆化递归；返回 (π, M=像)。"""
    pi = {}
    def go(a):
        if a not in pi:
            pi[a] = frozenset(go(z) for z in ext.get(a, EMPTY))
        return pi[a]
    for a in nodes:
        go(a)
    return pi, frozenset(pi.values())
```

π(a) = {π(z) | z ∈ ext(a)} 就是定理 1.97 的递归式逐字——嵌套
frozenset 的 HF 世界（70 章的 V_ω）是现成的像空间。验收三条件
（像传递、π 保关系、π 单射）逐条断言。四个现场：

**现场一（例 1.35 的有限段）**：偶数链 {0,2,4,6} 配 ∈-限缩
ext(2n) = {2k | k<n}，机器给出 π(2n) = n（冯诺伊曼数字），像
M = {0,1,2,3} = 4——传递 ✓。

**现场二（刚性的计算面）**：{0,2,4,6} 与 {1,3,5,7}——同构不同
集——坍缩到**同一个** M = 4。刚性定理说传递像上无换名自由，
机器直接算给你看。

**现场三（例 1.34 的相撞）**：{2,3,{2}} 不自同一，坍缩引擎照样
能跑（递归式不需要前提），但 π(3) = π({2}) = {∅}——两个节点
同一个像，"同构"当场穿帮：**自同一性这条前提缺一不可**，机器
把反例钉死。

**现场四（非序数的传递集合）**：外延 DAG（a:∅ ← b:{a} ← c:{a,b}，
d:{a,c}）坍缩出 π(d) = {0, 2}——一个不是序数的传递集合居民，
坍缩像的宇宙比序数塔宽。

Coq 通道（Ch75_collapse.v）把 HF 做成归纳类型 `HFset (list HF)`
——玫瑰树。可判等是第一场硬仗：`Scheme Equality` 拒绝嵌套 list
归纳（8.20 实测），互归手写被 guard 拒（交换位置递归），stdlib 又
无 list_beq——三无路之后落在**参数化列表 beq + 高阶嵌套递归**
（`hfl_beq HF_beq`：guard 认高阶形态）：

```coq
Fixpoint hfl_beq (f : HF -> HF -> bool) (la lb : list HF) : bool := ...
Fixpoint HF_beq (a b : HF) {struct a} : bool :=
  match a with
  | HFset la => match b with
                | HFset lb => hfl_beq HF_beq la lb
                end
  end.
```

配套的手工归纳原理 `HF_mut_ind`（玫瑰树的元素级 IH 不会自动
生成，必须外层 fix + 内层 list 归纳手工立）上岗即证
`HF_beq_eq`/`HF_beq_refl`/`HF_eq_dec` 三件套。坍缩器（燃料法
`pi_f`）在四个现场全部 `reflexivity`/`vm_compute` 对拍：
π(2n) = vn n、像 = vn 4、两链同像、相撞现场、DAG 全覆盖。

## 75.4 有秩关系：良基的抽象

> **定义 1.100（有秩关系）** R 是 A 上的有秩关系（well-founded）
> ⟺ A 的每个非空子集有 R-极小元。
> **定义 1.101（秩函数）** f: A → α 使 (x,y) ∈ R → f(x) < f(y)。

例 1.36：∈ 是任何集合上的有秩关系（= ∈-极小原理！正则公理的
内容）；秩序是线性有秩关系。例 1.37：秩序集的 W → ot(W[a]) 是
秩函数——72 章的序型是本节秩函数的特例。

> **定理 1.98（秩映射定理）** (A,R) 有秩 ⟹ 存在**典型**秩函数
> ρ: A → α：ρ(a) = sup{ρ(y)+1 | y R a}。反之，存在秩函数 ⟹ 有秩。
> *证明*：分层逼近——类递归定义 F(0) = ∅，
> F(β+1) = {a ∈ A | ∀b (b R a → b ∈ F(β))}（前驱已入层者），
> 极限取并；断言一 F(β) 单调递增；断言二（R-极小反例 + 替换公理）
> 每个 a ∈ A 落进某层；ρ(a) := 最小层。∎

——这就是 71 章累积层次 V_α 的**相对化**：F(α) 是"R-秩 < α"者，
例 1.38 验证 V_α 本身就是 (V,∈) 的分层，ρ 即 RK 的相对化。**良基
= 可分层 = 可归纳**，三位一体。

机器通道把分层器做成判定器（Python/Julia/Prolog 同款）：

```python
def rank_layers(nodes, ext):
    """定理 1.98 的分层迭代：F(0)=∅，F(β+1) = {a | ext(a) ⊆ F(β)}。"""
    covered, rank = set(), {}
    layer = 0
    while len(covered) < len(nodes):
        new = [a for a in nodes if a not in covered
               and all(z in covered for z in ext.get(a, EMPTY))]
        if not new:
            return rank, [a for a in nodes if a not in covered]
        for a in new:
            rank[a] = layer
        covered.update(new)
        layer += 1
    return rank, []
```

偶数链分层 [0,1,2,3]（秩 = 位次）；DAG 分层 a:0, b:1, c:2, d:3；
**2-循环 x⇄y 的覆盖率永远为零**——"非有秩 ⟺ 不可分层"的反向
见证，机器把定理 1.98 的逆命题也跑成了判定算法。Lean 的官方锚点
则是 `ZFSet.rank` 全家桶（examples/lean/Settheory/Ch75Collapse.lean）
——命题 1.21 三恒等式与定理 1.61/引理 1.12 的官方形态：

```lean
theorem rank_lt {x y : ZFSet} (h : y ∈ x) : rank y < rank x := rank_lt_of_mem h
theorem rank_singleton' (x : ZFSet) : rank {x} = Order.succ (rank x) :=
  rank_singleton x
theorem exists_mem_V (x : ZFSet) : ∃ o, x ∈ V_ o := exists_mem_vonNeumann x
theorem mem_V_iff {x : ZFSet} {o : Ordinal} : x ∈ V_ o ↔ rank x < o :=
  mem_vonNeumann
```

`mem_V_iff` 正是"每个集合住在第 RK(x)+1 层"；`rank` 的递归方程
rank(a) = ⋃{succ(rank y) | y ∈ a} 就是定理 1.98 的 ρ 定义式——
mathlib 里 `IsWellFounded.rank` 是一般良基秩，`ZFSet.rank` 是它的
∈ 特例，定理 1.98 的一般形态由此官方在案。

> **定义 1.102** R 自同一 ⟺ A 内 R-外延相同者相等
> （ext_R(a) := {y ∈ A | y R a}）。
> **定理 1.99（有秩递归定义）** (A,R) 有秩、G 类函数 ⟹ 存在唯一
> F: A → V 使 F(a) = G(a, F↾ext_R(a))。
> **定理 1.100（传递化定理，一般版）** (A,R) 有秩 + 自同一 ⟹
> 存在唯一传递 M 与唯一同构 π: (A,R) ≅ (M,∈)：
> **π(a) = {π(z) | z ∈ ext_R(a)}**。
> （秩序坍缩成序数 = 72 章定理 1.64；∈ 坍缩成传递集 = 定理 1.97。）

冯琦称 π 为（A,E）的**传递化映射或雪崩映射**——雪崩意象第三次
出现（68 章无界子集、72 章序数集、本章坍缩），一以贯之：**从下面
逐层推上去，每一步只依赖已成的下层**。Mostowski 坍缩在 11 章
（Jech 线）承担传递模型论的重活；此处它是"外延 + 良基 ⇒ 标准形"
的结构代数。Agda 通道的收尾件是"序数是传递集合"的有限化身——
冯诺伊曼数字的传递性经 hf-ind 风格的归纳全程机器化：

```agda
vn-transitive : ∀ n → transitive (vn n)
vn-transitive zero = trans-vn0
vn-transitive (suc n) = trans-vn n (vn-transitive n)
```

## 75.5 机器通道与实测坑

| 通道 | 承载 | 实测坑 |
|---|---|---|
| Lean | `ZFSet.rank`/`V_` 塔官方锚点 | — |
| Isabelle/ZF | `Transset_induct`/`transrec`/rank 锚点、刚性 at 2 全证、坍缩方程样板 | 0∈2 须 `succI2 [OF succI1]` 手工链（succI2 非 simp 规则） |
| Coq | HF 玫瑰树 + 可判等 + 燃料坍缩器四现场 | **Scheme Equality 拒嵌套 list**；互归 beq 被 guard 拒（高阶 `hfl_beq HF_beq` 解毒）；stdlib 无 list_beq |
| Agda | hf-ind（1.94 构造性化身）、vn 传递性 | `[_]` 单例记号要显式 import；`subst` 方向：x≡vn 0 要 `sym` |
| Julia/Python | 坍缩引擎 + 三验收 + 四现场 | 菱形 DAG 不自同一被引擎当场抓包（设计插图变教学案例） |
| Prolog | ordset HF + assoc 记忆化坍缩 | M=0 槽位式子句老坑未犯；`forall` 不导出绑定老坑绕行 |

## 75.6 收束：第一卷的结构论完成

冯琦第 1 章至此闭环：从 67 章的语言与公理出发，传递集合是唯一
组织概念——自然数（68）、整数有理数（69）、V_ω（70）是它的第一
层展开；序数（71）与秩序（72）是它的骨架；快速增长层次（73）是
骨架上的证明论刻度；基数（74）是骨架上的计数刻度；本章的坍缩
定理宣布：**一切外延良基结构都与某个传递集合同构，且唯一**。
论域的标准形 = 累积层次，结构的标准形 = 传递集合。第 2 章（76-79
章）带着这套标准形冲向选择公理与不可数基数理论；第 3 章（80-83
章）则回到实数轴——把 69 章的有理数补全成 ℝ，正则性、波兰空间、
投影集、博弈，最终在两条"另类直线"处收卷。

---

上一章：[74 基数：和、积与典型秩序](74-cardinals.md) · 下一章：[76 选择公理与无穷和积不等式](76-choice.md)
