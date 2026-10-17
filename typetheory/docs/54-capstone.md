# 54 压轴：π₁(S¹) 与编码-解码方法

> 对应读本：HoTT 书 §8.1（π₁(S¹)=ℤ 完整证明）+ **§8.9
>（编码-解码的一般陈述）**；coq-hott 教程 13 章（完整
> encode-decode）与 59 章压轴（螺旋覆叠）。
> 代码：`examples/54_capstone/ex54_capstone.v`——`iterate_add`
> 完整机器证明，依赖公理只有 S¹ 的构造子（Print Assumptions）；
> 53 章 cubical 件已给 loop 的两行定义与幂塔（本 章 的
> cubical 前哨）。

## 54.1 任务：绕 m+n 圈 = 先绕 m 圈再绕 n 圈

```coq
Fixpoint iterate (n : nat) : base == base :=
  match n with 0 => idpath | S m => loop · iterate m end.

Theorem iterate_add (m n : nat)
  : iterate (m + n) == (iterate m) · (iterate n).
Proof.
  induction m as [| m IH]; simpl.
  - exact idpath.                  (* 基例：两侧都定义折叠 *)
  - refine (ap (fun X => loop · X) IH · _).
    exact (inverse (concat_assoc loop (iterate m) (iterate n))).
Defined.
```

证明的两块原料都是 47 章的路径代数：`ap`（把 IH 顶到 `loop ·_`
下）+ `concat_assoc`（括号右移，单步 J）。**这是 π₁(S¹) 加法
结构的第一块基石**——它说明「圈数」对加法保持。

## 54.2 通往 π₁(S¹) = ℤ：还差什么

完整的编码-解码（encode-decode）证明链：

```text
code : S¹ → U（每点配一个「解码空间」：base ↦ ℤ，loop ↦ +1 同构）
encode : (x == base) → code x           —— transport 的特化
decode : code x → (x == base)           —— circle_rec 按 code 走
两者互逆（在 base：ℤ ≃ Ω(S¹)）⇒ loop ≠ idpath（1 ↦ loop 不塌）
```

本迷你库做到 `iterate_add`；encode-decode 需要完整的泛等
计算规则与截断机械——**完整机器版在本仓库 coq-hott 教程
19 章**（基于官方 HoTT 库，含 `loop ≠ 1` 与螺旋覆叠压轴）。
两个教程互为表里：typetheory 讲原理的最小化，coq-hott 讲
工业级完整版。

## 54.3 诚实的「未机器化清单」

| 陈述 | 状态 | 出处 |
|---|---|---|
| `iterate_add` | ✅ 本章机器证明 | 零额外公理（除 S¹ 构造子） |
| `! iterate n == iterate (0-n)` | 正文练习（组装同 iterate_add） | 53 章坑位 |
| `loop ≠ idpath` | ❌ 需 encode-decode | coq-hott 19 章 |
| funext-from-interval | ❌ 需 eta/计算规则配合 | HoTT 书 4.9/6.3 |

公理的**用量与去向**全部 `Print Assumptions` 公示——读者可以
逐条审计「这个定理到底信了什么」。这是 mini-HoTT 的教学立场：
不求全，但求每一行都清楚来路。

## 54.4 第五部分总结：类型论的几何面

47 章起五步走：路径（J 的群律）→ 泛等（等价即相等）→
截断（层级塔）→ HIT（造空间）→ 环路代数（同伦群雏形）。
一条暗线贯穿：**「相等」从 Prop 搬到 Type，换来的是整个
高维世界**——这也是 cubical Agda / 新一代内核的进化方向。

> **坑位速记**
> ① `concat_assoc` 的 motive 引用 q 必须retype（q 做 match
> 参数）——25 章 ap_pp 同款；
> ② `iterate (S m + n)` 的 `simpl` 时机：基例靠定义折叠免证，
> 归纳步 refine 的两段组装要在 simpl 后一次拼好；
> ③ `Print Assumptions` 是公理审计的日常工具——mini 开发
> 每章收尾都跑一遍（本指南全五部分的惯例）。

## 54.5b 编码-解码的一般形式（书 8.9）

本章的方法抽象成一个模式（书 8.9 的正式陈述）：

> 给定点 x₀ : X 与族 code : X → Type，若每点的
> **解码** dec x : code x ≃ (x₀ = x) 且 dec x₀ 把基点送到
> id（基点一致），则 Ω(X,x₀) ≃ code x₀——**用 code 的代数
> 换取环路空间的代数**。

四步曲（本章机器面的骨架即其特化）：① 定 code（本章：ℤ 的
旗帜模型）；② 定 enc（用 J 从 refl 出发）；③ 定 dec 与等价
证明；④ 基点验证。方法论的普适性在 55 章全面兑现——
Freudenthal、π_k<n(S^n)、Hopf 纤维的三大主定理全是
encode-decode 的变奏。**为什么它总能工作**：code 是「可计算
的替身」（ℤ 有归纳原理），等价把环路空间的「拓扑」翻译成
code 的「代数」——这是同伦论里 Brown 代表性定理的类型论版。

## 54.5c cubical 前哨的近况（诚实清单）

53 章 cubical 件已机器定义 loop（`merid false ∙ sym
(merid true)`）与幂塔 loop^。完整的 cubical encode-decode
（code : S¹ → Set 的 S¹-elim 上方形一致性 + dec 的等价证明）
在 plain cubical Agda 里可行但工程量是 Coq 版的两倍（每一处
「公理化计算规则」都要展开成 Glue/hcomp 的显式计算）——本
章以 Coq 版为正典（公理账目已最小化），cubical 全版列入回填
清单（55 章 Freudenthal 陈述级的同批）。

## 54.5 encode-decode 四步曲逐步展开（书 8.1 完整数学）

**第一步：code 的旗帜模型**。覆叠空间 p : R → S¹（螺旋线）
的类型论化身是族 code : S¹ → U：

> code(base) := ℤ（整面旗帜：基点上的纤维是 ℤ 层楼）
> code 沿 loop 搬运 := succ 的等价（上一层楼）

ℤ 本身用 triumph 架构（free group on one generator 的集合
版）：pos n / neg n 两支，见书 8.1 的 int 类型——加减法在
两支间穿越（succ (pos n) 与 neg 的边界翻转），本章 Coq 侧
用 nat 差值表示同构地实现。

**第二步：enc 由 J 白送**。enc x : (base = x) → code x 定义为
transport code p（对 p 归纳）：enc(refl) := pos 0（基点住在
零层）。**「编码」就是「搬家」**——泛等之前它已是程序。

**第三步：dec 是圆的归纳原理**。dec x : code x → (base = x)
用 circle_ind 构造：base 分支给 iterate（n 层楼 = 绕 n 圈，
本章机器件的正典）；loop 分支要给 PathP——「loop 上方 code
的搬运 = succ，iterate 对 succ 保持」——正是 iterate_add +
iterate_succ 的串接。**消去子的路径分支是整个证明的技术
心脏**：它把「覆叠的单值性」编进类型论。

**第四步：互逆与基点一致**。dec∘enc：对 p 归纳（enc refl =
pos 0、dec base (pos 0) = refl 的定义级坍缩 + transport 的
融合）；enc∘dec：对 ℤ 归纳（pos/suc 的逐层解析——书 8.1.6/
8.1.7 的两条引理）。基点验证 dec(base)(pos 0) ≡ refl 由定义
给出。于是 Ω(S¹, base) = (base = base) ≃ ℤ。

**推论（loop ≠ refl）**：若 loop = refl，则 enc loop = enc
refl = pos 0；但 enc loop = succ (pos 0) = pos 1 ≠ pos 0
（ℤ 两支的判别性——51 章 Hedberg 的样本）。**圆上真的有非
平凡的路**——58 章宣布的「天花板」在此兑现。

## 54.5d ℤ 的旗帜模型（code 的地基）

code(base) = ℤ 的具体安装（书 8.1 的 int 类型——「旗帜」指
ℤ 立在 0 处的一根旗杆，正负两层）：

```text
data ℤ : Set where
  pos  : ℕ → ℤ        （+0, +1, +2, …）
  neg  : ℕ → ℤ        （…, −2, −1）——注意 neg 0 = −0 ≡ 0 的
                       衔接约定（书用 negsuc：负数从 −1 起）
succ (pos n) = pos (suc n)
succ (negsuc n) = negsuc n 的前驱/或回正——边界翻转会师
```

succ 的「翻转会师」（negsuc 0 → pos 0）是全部代数的引擎：
loop 的搬运 code 沿 loop = succ ⇒ iterate n ↦ iterate (succ n)
的对应由此逐层展开。54.1 的 iterate_add 是这个对应的加法面。
（Coq 侧用 nat 的「m+n/n−m 差值表示」实现同构旗帜——旗帜
的任何两个实现都 succ-等变，编码-解码对此不敏感。）

## 54.6 π₁(S¹) = ℤ 与主定理的地图（书 8.1.10 及其后）

书 8.1.10 的正式陈述：**π₁(S¹) = ℤ**——把 Ω ≃ ℤ 截断成群
同构（0-截断 + 群结构搬运）。其后的推广线（55 章的入口）：

- 8.1.11：π₁₊ₙ(Sⁿ⁺¹) = π_n(Sⁿ⁺¹) 的样板（高维球面）；
- **8.9 的方法化**：encode-decode 作为可复用的定理模板；
- 55 章：连通性机器（8.2）、纤维序列（8.4）、Hopf（8.5）、
  Freudenthal（8.6）、van Kampen（8.7）、Whitehead（8.8）。

本指南的分工：**54 章把「一条非平凡的路」证到底**（数学的
完整性），**55 章把「一族的定理」做成地图与陈述级机器**
（工程的范围诚实）。

## 54.7 机器面导读

- **Coq（`ex54_capstone.v`，正典）**：iterate 的定义 +
  iterate_add 的两段组装（ap 顶置 + assoc 右移）+ Print
  Assumptions（仅 S¹ 构造子公理）；
- **cubical（`ex53_hitc.agda` 尾段，前哨）**：loop 的两行
  定义（merid 的错位差）、loop^ 的幂塔——54.5 的第零步在
  cubical 世界免费成立，其余三步见 54.5c 的诚实清单；
- **coq-hott 教程（外部续读）**：完整版（含 loop ≠ 1 与螺旋
  覆叠）——本仓库 README 的「已知边界」标注的正式去向。

> **坑位速记（本章新增）**
> ① encode 的基点值（pos 0）与 dec 的基点坍缩（iterate 0 =
  refl）必须在**定义级**对齐——基点验证若需引理，整条等价
  的归纳负担加倍；
> ② loop 分支的 PathP 计算依赖「iterate_succ 即搬运」——
  Coq 侧用 apD 表述（53 章坑位同源），cubical 侧是方形
  分支的 pm 字段。

## 54.7b 环路空间的群结构（书 8.1 收尾）

π₁ 的「群」身份：Ω(S¹) ≃ ℤ 之后，群的乘法（环路合成 · ）与
ℤ 的加法（succ 旗帜的逐层）的对应由 iterate_add 严格建立
（54.1 的机器件正是乘法对加法的分配面）。逆对应 ·⁻¹ ↦ −n
（iterate 反向）。**同伦结合律**（(p·q)·r = p·(q·r)）是
47 章 concat_assoc 的直接搬运——「群」在 HoTT 里从不含糊：
Ω 的合成 + 三条群律全是定理（47.3 的免费机械），非公设。
这与经典拓扑的「同伦群需要高阶相干选择」对照——HoTT 的
∞-群胚结构自带全部相干（Coherence 定理免费），是 55 章
全部定理群的隐形地基。

---

上一章：[53 高阶归纳类型](53-hit.md) · 下一章：[55 同伦论进阶](55-homotopy.md)
