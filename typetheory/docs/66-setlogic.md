# 66 集合与逻辑：mere 命题与截断

> 对应读本：HoTT 书第 3 章全部（sets 与 n-types、mere proposition、
> 经典 vs 直觉、子集与 resizing、命题逻辑、命题截断、选择公理、
> 恰一选择、合同性）。代码：`examples/66_setlogic/`——**cubical
> Agda 主力**（∥·∥ 是真 HIT、LEM⇔DNE 机器证明、AC 方向、
> 合同性引理群）+ **Lean 对照**（Prop 宇宙=内核化的 mere prop、
> Nonempty=免费截断、choice 账单对照）。

上一章说「等价要带相干」。本章处理一个更基础的分裂：**类型论
的命题是带证明的空间，而逻辑学的命题是或真或假的裸值**。HoTT
的答案不是抛弃 Curry–Howard，而是**分层**：把「不携带信息」的
类型圈出来（mere proposition），把任何类型**压平**成这样的命题
（截断）。数学的全部家常话（与或非、存在、选择、唯一）在这一层
重新校准。

## 66.1 h-level 的头两级（书 3.1/3.3/3.11）

三个定义层层递进（cubical 侧与 67 章的层级塔相接）：

```agda
isProp A := (x y : A) → x ≡ y      -- 任意两点相等：无信息
isSet  A := (x y : A) → isProp (x ≡ y)   -- 路径空间无信息
isContr A := Σ( a : A ). ∀ x → a ≡ x     -- 一点加全员收缩
```

合同（contractible）是 mere prop 的「有据版」——引理 3.11.3
三者互通：合同 ⟺ 是 prop 且有元素 ⟺ 等价于单元。样本与封闭律
（cubical 文件全机器化）：⊥ 是 prop（两点皆由 ⊥-elim）、⊤ 是
prop **且合同**、否定 `A → ⊥` 总是 prop（3.6.1：⊥ 的唯一性 +
funext）、**prop 族的 Π 是 prop**（例 3.6.2）。以及本章最美的
小定理（3.11.8）：

> **单端点路径空间合同**：Σ(x:A). a ≡ x 合同，中心 (a, refl)。

cubical 版只需两行——Σ 路径是**分量式**的（`p i , λ j → p (i∧j)`），
不需要书 2.7 的拆解引理；这是「cubical 的路径原生」的又一次
兑现。它也是 5.8 节恒等系统（68 章）的种子。

诚实清单：3.11.4（isContr A 自身是 prop）完整机器版需要「度规
恒等式」u ≡ sym(p x)·p y 与依赖 funext 的 PathP 化，与 64 章
4.2.6 同列回填（67 章纤维合同性机械就位后）；本章给出它的
半程 `isContr-isProp`（合同 ⇒ prop：sym(p x)·p y 经中心连线）。

## 66.2 命题截断：真 HIT（书 3.7）

**本章的技术高潮**。把任意类型压成 mere prop：

```agda
data ∥_∥ (A : Set) : Set where
  ∣_∣    : A → ∥ A ∥
  squash : (x y : ∥ A ∥) → x ≡ y    -- 所有元素被「挤」相等
```

`squash` 是**路径构造子**——在 Coq mini-HoTT 里它必须公理化
（67 章的对照组），在 cubical Agda 里它是数据，且**有计算行为**：
`isProp ∥A∥ = squash` 一行（全谓词就是构造子本身）。消去原理
（3.7.3）同样原生：

```agda
∥∥-rec : isProp B → (A → B) → ∥ A ∥ → B   -- 非依赖版
∥∥-elim : (P : ∥A∥ → Set) → (∀z. isProp (P z))
        → (∀a. P ∣a∣) → ∀z. P z            -- 依赖版
```

squash 分支的处理是教科书级的一课：**prop 族上的依赖路径可由
普通等式制造**（`pathOverProp`：J 一步把 PathP 降为 isProp）。
对照书 3.7 的公理化三件套（构造子+消除子+计算律）——cubical
里只有第一件，后两件由模式匹配自动派生。69 章（HIT 总论）会
把这套机制命名为区间应用/ IApply 并展开。

## 66.3 逻辑记号表（书 3.7.1）

mere prop 的层上，家常逻辑全部重装：

| 记号 | 定义 | 备注 |
|---|---|---|
| ⊤ / ⊥ | 单元 / 空类型 | prop |
| P ∧ Q | P × Q | prop 的积是 prop |
| P ⇒ Q, ¬P | P → Q, P → ⊥ | 否定总 prop |
| **P ∨ Q** | **∥ P + Q ∥** | 析取必须截断！ |
| **∃ x. P x** | **∥ Σ x. P x ∥** | 存在必须截断！ |
| ∀ x. P x | Π x. P x | prop 族保 prop |

∨ 与 ∃ 的截断是本章的哲学落点：未截断的 `P + Q` 记得「是左边
还是右边」（证据携带信息），`∥·∥` 把这信息抹掉——**「或」的真
义是不确定哪边**。这一层逻辑与 21 章（λC 编码线）的二阶编码
形成三代对照：Church 编码（∨ 即 ΠC 双延续）→ Leibniz 层
（TTAFP）→ 截断层（HoTT）。三代做同一件事：把「信息量」从
命题里挤出去。

## 66.4 经典 vs 直觉：LEM ⇔ DNE（书 3.4）

正确的排中律只对 mere prop 主张（LEM∞ 对任意类型与泛等冲突
——书 3.2.2 的悖论）：

> **LEM** := Π(A:U). isProp A → (A + ¬A)
> **DNE** := Π(A:U). isProp A → (¬¬A → A)

两者的等价在 cubical 文件里**完整机器化**，钥匙是一块构造性
垫脚石：

```agda
isProp-sum¬ : isProp A → isProp (A ⊎ ¬ A)  -- 四情形：跨侧靠 ⊥-elim
nn-sum¬    : ¬ ¬ (A ⊎ ¬ A)                 -- 构造性成立（21 章同型）
DNE→LEM dne A pA = dne (A ⊎ ¬A) (isProp-sum¬ pA) nn-sum¬
```

即「A+¬A 自己是 prop」加上「它的双重否定免费」——DNE 一转
即得 LEM。反向 `LEM→DNE` 是标准分类讨论。可判定性（3.4.3：
decidable/hasDecEq）以 Bool 为样板：**true ≠ false 的 cubical
证法是「谓词分离」**——定义 T true = ⊤、T false = ⊥，一条
true≡false 的路径把 tt 搬进 ⊥。这是 69 章（S¹ 的非平凡环）、
70 章（loop ≠ refl 的编码-解码）将反复使用的核心招式。

## 66.5 子集与 resizing（书 3.5）

子集 = Σ(x:A). P x，其中 P 逐点 mere prop（引理 3.5.1：第一
分量相等即元素相等——proof 携带的信息为零，所以「成员资格」
良定义）。子宇宙 Set_U := Σ(A:U). isSet A、Prop_U 同理。书
3.5.5 的 **propositional resizing**（Prop_U ↪ Prop_{U+1} 是
等价）作为可选公理陈述——它是 mere prop 层的非直谓性，本书
大多数章节不用（保持直谓）。对照 25 章（λD 子集即谓词）：三
代子集观——谓词本体（TTAFP）/Σ 带见证（MLTT，33 章）/Σ 且
见证无信息（HoTT 本章）。

## 66.6 选择公理：AC 在 HoTT 里的正确形状（书 3.8/3.9）

书 3.8 的著名桥段：**AC 写对了形状它依然需要公理——但恰一
选择（unique choice）变成免费定理**。集族版的 AC（3.8.3）：

> (Πx:X. ∥Y x∥) → ∥Πx:X. Y x∥（X、Y 皆集合）

两个方向一免费一公理，机器面两世界同构：

```agda
-- 免费方向（3.8.4 右推左）：一次截断给全部，逐点拆包
∥Π∥→Π∥ : ∥Π Y∥ → Π x → ∥Y x∥     -- cubical：∥∥-rec + ∣g x∣
```

```lean
theorem freeDir ... : Nonempty ((x : X) → Y x) → Nonempty (Y x) :=
  fun e x => e.elim fun g => ⟨g x⟩   -- Lean：同样零公理！
```

（Lean 侧 `#print axioms freeDir` → does not depend on any
axioms——与 cubical 侧同一天平。）而 AC 本身（左推右）是公理
级：AC 作为假设类型陈述，不在 cubical 文件里假设。

**恰一选择免费**（3.9 的形状）：

```agda
uniqueChoice : (∀x. isContr (P x)) → ∥Π P∥ → Π P   -- 见证 g 原样可用
isContr-Π    : (∀x. isContr (P x)) → isContr (Π P)  -- 3.11.6
```

`isContr-Π` 值得驻足：收缩**逐点**进行（`contrs x .snd (f x) i`）
——它正是函数外延的化身（书 3.11.6 的评注：此引理等价于
funext；cubical 里 funext 是 λ i j → h j i，isContr-Π 于是水
到渠成）。与 21 章（ι 需要古典 choice 的账单）对照：**恰一性
把账单清零**——HoTT 对「描述子」问题给出了比集合论更精细的
答案。25 章（TTAFP 的 ι）——17 章（Farmer 的 I）——本章
（unique choice 免费）：描述子的三部曲在本书内闭合。

Lean 对照的账单正是反衬：`pick`（一般选择）记账
[Classical.choice]，而 HoTT 侧恰一时零公理——**两个世界把
「选择」放在不同的位置**：Lean 放在公理（均匀地收税），HoTT
放在结构（唯一性即免税）。

## 66.7 机器面导读

**cubical Agda（`ex66_setlogic.agda`，~300 行）**：六段——
mini-cubical 前奏；h-level 定义与样本（含 pathOverProp 小
引理）；**∥·∥ 真 HIT**（squash/rec/elim 全套）；逻辑记号表
（∨/∧/¬/∃ 语法声明）；**LEM⇔DNE 完整机器证明**（isProp-sum¬
的跨侧 ⊥-elim 技巧 + nn-sum¬ + 双向装配）与 Bool 可判定等式
（谓词分离）；AC 免费方向 + isContr-Π + uniqueChoice。

**Lean（`ex66_setlogic.lean`，~100 行）**：五组对照——
proof irrelevance/propext（内核化的 mere prop）；Nonempty =
免费截断；pick 的 choice 账单 vs 恰一免税；LEM⇔DNE 的 Lean
版（Classical.em + Diaconescu 账单）；freeDir 零公理（与
cubical 同构）。

> **坑位速记**
> ① cubical 的区间 `_∧_`/`_∨_` renaming 与逻辑 `_∧_`/`_∨_`
>   **撞名**——本章起逻辑记号当道，区间改名 `_∧ᵢ_`/`_∨ᵢ_`；
> ② Agda 点-free 定义体内隐式参不在辖域（**本章两踩**：
>   pathOverProp 的 Q、∃-syntax 的 A）——子句模式显式
>   `{Q = Q}` 绑定；
> ③ ⊤ 撞 builtin Unit 的同名导出——直接 `open … using (⊤; tt)`；
> ④ HIT 的 squash 分支匹配：非 prop 目标用 `isProp x y i`
>   逐 i 索引，**矛盾分支**（跨侧）把 `⊥-elim` 当**整条路径**
>   返回（不带 i）——带 i 会被端点锚定拒绝；
> ⑤ Lean `Nonempty.elim` 的消去目标必须是 Prop——目标
>   `Nonempty (Y x)` 合法、`Y x`（Type）非法；外层不要再包
>   `⟨·⟩`；
> ⑥ Lean 关系版签名 `P : α → α → Prop` 别写成 `α → Prop`
>   再套两层；
> ⑦ `Bool.noConfusion h` 的类型是任意 C——`isFalse` 的证明
>   直接 `fun h => Bool.noConfusion h`，不需要再绕。

---

上一章：[65 泛等](65-univalence.md) · 下一章：[67 截断与 n-类型](67-truncation.md)
