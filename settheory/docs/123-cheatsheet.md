# 123 · 收官：七书总表、三条数学轴与七通道总账

[上一章：AD^{L(ℝ)} 与全书主线汇合](122-adlr.md) · [返回目录](../README.md) · 下一章：（完）

## 1. 这一章怎样使用

本章是全书的地图书，不是把前 123 个文件压缩成名词表。

第一次阅读时，先看七底本与十三篇总表，确定自己所在的路线。

复习某个定理时，沿三条数学轴找到前置概念，再回到对应正文。

运行示例时，注意它们只验证有限三轴关系和真实目录账目。

机器证明的边界与实测坑则用于防止“编译通过”被误读成“无限定理已经形式化”。

全书包号为 00–148，共 149 章。

其中导引 00 与收官 123 不占篇内编号。

前十二篇是 01–122；第十三篇（郝兆宽·杨跃路线，入门坡道）是
124–148，章号没有断口。

本次郝/杨跃并入新增 124–148 二十五章。

## 2. 七底本总表

| 底本 | 教程范围 | 主要贡献 |
|---|---|---|
| Jech《Set Theory》第一版 | 01–45 | ZFC、L、力迫、大基数、描述集合论的七篇主干 |
| Viale《The Forcing Method in Set Theory》 | 46–55 | 以布尔代数、布尔值语义和拓扑重建力迫 |
| Makinson《Sets, Logic and Maths for Computing》 | 56–66 | 计算者使用的集合、关系、归纳、计数、概率与逻辑 |
| 冯琦《集合论导引》第一卷 | 67–83 | 以传递集合为纲，抵达 SCH、树、实数与正则性 |
| 冯琦《集合论导引》第二卷 | 84–92 | KP、传递模型、pcf、内模型、力迫与布尔值模型 |
| 冯琦《集合论导引》第三卷 | 93–122 | 高阶无穷、泛型超幂、迭代树、投影决定性与 AD |
| 郝兆宽·杨跃《集合论：对无穷概念的探索》 | 124–148 | 从罗素悖论到 L 与力迫的入门坡道 |

七份底本不是七条互不相干的课程。

Jech 给出共同语言，Viale 改写力迫的语义表达，Makinson 补足离散工具。

冯琦第一卷重建基础，第二卷深入模型，第三卷把大基数与实数正则性汇合。

底本编号只用于溯源。

正文必须能独立阅读，不能用“见原书”代替论证。

## 3. 十三篇结构总表

| 篇 | 章号 | 核心问题 |
|---|---|---|
| 一 公理集合论 | 01–09 | 集合怎样由公理构造，无穷怎样分层 |
| 二 传递模型 | 10–15 | 公式何时绝对，L 为什么满足 AC 与 GCH |
| 三 力迫 | 16–22 | 怎样增加新集合并保持真值账目 |
| 四 力迫的应用 | 23–27 | 链条件、迭代和组合原理怎样产生独立性 |
| 五 可测基数 | 28–33 | 测度、超幂、不可辨别元与 L[U] 怎样连接 |
| 六 其他大基数 | 34–39 | 紧性、饱和与连续统函数怎样相互作用 |
| 七 描述集合论 | 40–45 | 可定义实数集合有哪些正则性与决定性 |
| 八 Viale 路线 | 46–55 | 布尔值语义怎样统一力迫的外定义与内定义 |
| 九 Makinson 路线 | 56–66 | 离散数学与逻辑需要哪些可计算工具 |
| 十 冯琦第一卷 | 67–83 | 从传递集合到实数子集正则性 |
| 十一 冯琦第二卷 | 84–92 | 从可容许集到内模型和力迫 |
| 十二 冯琦第三卷 | 93–122 | 从高阶无穷到 AD^{L(ℝ)} |
| 十三 郝兆宽·杨跃路线 | 124–148 | 从 ZFC 到 L 与力迫的入门坡道 |

前七篇是 Jech 路线，但 22 章已经处理 Suslin 问题。

因此第四篇从 23 章 Martin 公理开始，到 27 章结束。

第五至第七篇分别是 28–33、34–39、40–45。

第十篇不是 79–83 五章，而是完整的 67–83。

第十一篇为 84–92，第十二篇为 93–122。

第十三篇是整体并入的郝/杨跃入门教程，占 124–148，收官 123 保持不动。

这些边界同时由 README、本章和目录扫描程序核对。

## 4. Jech 路线的七个台阶

第一段从 Russell 悖论进入 ZFC。

Cantor 定理、Schröder–Bernstein 定理和 Hartogs 定理构成基数论的起步三角。

序数给出超穷递归的坐标，选择公理给出良序和 Zorn 引理。

第二段把“真”相对化到传递模型。

Δ₀ 绝对性、Mostowski 坍缩和可构造层级共同解释相对一致性证明。

第三段引入偏序、稠密集、泛型滤子与名字。

力迫定理把扩张中的真值还原为基模型可表达的关系。

第四段展示保持定理为什么和构造扩张同样重要。

链条件保基数，支撑方式控制迭代，组合引理控制新实数。

第五至第六段用测度和初等嵌入表达高阶无穷。

可测基数不是“很大的有限式对象”，而是带正规测度或嵌入见证的无限假设。

第七段把问题转向实数集合的可定义复杂度。

Borel、解析、投影与决定性逐步替代朴素的“所有集合”。

## 5. Viale 路线总表

| 章 | 主题 | 全书中的作用 |
|---|---|---|
| 46 | 正则开集与预序 | 把偏序条件翻译成拓扑与代数 |
| 47 | 布尔代数与 PIT | 建立有限原子和素理想工具 |
| 48 | Stone 对偶与布尔环 | 连接空间、代数和环三种语言 |
| 49 | 完备化 | 使任意上确界和布尔真值可用 |
| 50 | 泛型滤子与 Fn(X,Y) | 把泛性同 Baire 纲相遇 |
| 51 | 布尔值语义 | 给出可靠性与完备性 |
| 52 | 商、满性与 Łoś | 用满性解释超积真值 |
| 53 | V^B 名字 | 混合引理与最大原理 |
| 54 | 力迫定理 | 统一外定义与内定义 |
| 55 | 绝对性 | 收束 H_χ、Lévy 与 Shoenfield |

这一路线的价值不是重复第三篇。

它说明同一个力迫事实可以用代数的真值、拓扑的稠密性和模型的泛性表达。

第 54 章因此是第三篇与第八篇的合流点。

## 6. Makinson 路线总表

| 章 | 工具 | 后续用途 |
|---|---|---|
| 56–58 | 集合、关系、函数 | 全书的对象语言 |
| 59 | 归纳与递归 | 序数、树、名字和证明的构造原则 |
| 60–61 | 计数与概率 | 有限审计、测度直觉和反例搜索 |
| 62 | 树 | 良基性、表示、策略与迭代树 |
| 63–64 | 命题与量词逻辑 | 真值表、公式复杂度和语义 |
| 65 | 证明与后承 | 区分 syntactic derivation 与 semantic consequence |
| 66 | 相关性 | 检查前提是否真正参与结论 |

第九篇可以独立阅读。

它也为有限机器件提供共同词汇。

有限树、关系闭包、布尔函数和枚举证书在后续章节反复出现。

## 7. 冯琦三卷总表

| 卷 | 章号 | 组织概念 | 终点 |
|---|---|---|---|
| 第一卷 基本理论 | 67–83 | 传递集合、递归、实数与树 | SCH、实数正则性、苏斯林直线 |
| 第二卷 | 84–92 | 传递模型、内模型、力迫 | L、pcf、MA 与布尔值模型 |
| 第三卷 高阶无穷 | 93–122 | 大基数、外模型技术、实数正则性 | 投影决定性与 AD^{L(ℝ)} |

第一卷内部又分四段。

67–76 从传递集合、自然数、递归和序数走到选择公理与基数不等式。

77–78 处理 club、非荟萃理想与奇异基数假设。

79 把树、MA 和划分定理接回组合主线。

80–83 完成实数构造、正则性、波兰空间、投影集、非标准实数和苏斯林直线。

第二卷以 KP 和传递模型起步。

86 的 pcf 把共尾谱纳入模型分析，87–89 展开 L、组合原理和兼容内模型。

90–92 用力迫与布尔值模型接到 Jech 和 Viale 两条旧线。

第三卷是本教程最后也是最长的一条新线。

93–102 建立大基数和内模型资源。

103–110 研究在这些资源上工作的力迫。

111–115 进入投影集、Solovay 模型和理论不变性。

116–119 给出荟萃塔与迭代树两种技术核心。

120–122 经过投影决定性抵达 L(ℝ) 内决定性。

## 8. 大基数强度轴：先分清对象

大基数轴谈的是额外存在假设及其一致性强度。

它不是实数大小轴，也不是“基数数值排行榜”。

更强假设通常提供更多初等嵌入、闭包或反射见证。

这些见证随后被内模型、力迫和描述集合论消费。

`0#` 必须单列。

它是一份非平凡初等嵌入或 Silver 不可辨别元的组合证书，不是一个“大基数名称”。

覆盖引理显示 `0#` 是 V 与 L 的覆盖关系发生变化的阈值。

武丁基数也不能只看一个孤立嵌入。

其定义要求一族由函数索引的局部强嵌入见证。

最后，定理中的“上方还有一个可测基数”是实际假设，不能从行文里省略。

## 9. 大基数六行教学对照

| 索引 | 教学阶段 | 主要章 | 提供的资源 |
|---|---|---|---|
| 0 | 不可达与反射背景 | 08、93 | 正则强极限与模型分层起点 |
| 1 | 可测、0# 与 L[U] | 28–33、94–98 | 正规测度、超幂、不可辨别元、覆盖阈值 |
| 2 | 强紧与超紧 | 34、99–100 | 精细测度、高目标闭包、Laver 调度 |
| 3 | 强、超强与武丁 | 101–102 | extender、局部见证族与树表示资源 |
| 4 | 武丁极限及塔/迭代树 | 116–121 | 测度塔、比较、整齐与弱整齐树 |
| 5 | 武丁序列上方可测 | 122 | AD^{L(ℝ)} 收官定理的额外资源 |

这张表是教学顺序，不是声称每一行只有一个严格等价强度层。

强紧、超紧、强、超强与武丁之间有细致的含义和一致性关系。

判断具体关系时必须回到定义和定理，不能靠表格位置代替证明。

有限源码中的 `Fin 6` 或六个构造子只记录这六行索引。

## 10. 力迫技术轴：每种技术解决什么

力迫不是一台只负责“改变 CH”的机器。

不同偏序设计用于改变共尾度、控制连续统函数、保持基数、制造泛型超幂或运输嵌入。

因此力迫轴按问题和技术组织，而不是按偏序的“大小”排列。

小力迫与 Lévy 崩塌负责保持和提升。

Prikry 与 Silver 力迫处理奇异化及连续统函数。

恰当力迫和可数支撑迭代负责在复杂扩张中保存 ω₁ 与相关结构。

非荟萃理想力迫把正测集作为条件，产生泛型超幂。

荟萃塔把不同高度的条件接成定向系统。

迭代树则不是普通偏序力迫；它是内模型比较与嵌入运输的树形组织。

把它们放在同一教学轴上，是为了看接口，不是说它们都是同一种构造。

## 11. 力迫六行教学对照

| 索引 | 技术阶段 | 主要章 | 核心账目 |
|---|---|---|---|
| 0 | 小型扩张与 Lévy 崩塌 | 103 | 提升、因子分解、可数化 |
| 1 | Prikry、Silver 与 SCH | 104–106 | 判定、支撑、共尾度、最小反例 |
| 2 | 恰当迭代与 PFA | 107–108 | 主条件、可数支撑、保持与调度 |
| 3 | 理想力迫与泛型超幂 | 109–110 | precipitous、饱和、投影反射 |
| 4 | 荟萃塔 | 116–117 | 塔序、提升/降落、临界点与表示 |
| 5 | 迭代树与可迭代性 | 118–119 | 树序、张子作用、选枝与比较终止 |

第 120–122 章仍消费力迫，但主轴已经转向表示与决定性。

泛型正确性、互补树和测度塔在这里共同工作。

“用了力迫”不是完整证明说明。

必须交代条件、泛型对象、真值转移、保持性质以及最终消费结论。

## 12. 实数正则性轴：三种性质不能混为一谈

实数子集正则性至少有三条平行传统。

Lebesgue 可测性谈测度，贝尔特性谈拓扑，完备子集特性谈连续统内的闭集结构。

解析集在 ZFC 中已有良好正则性。

更高投影层的结论需要额外假设，不能从解析层直接外推。

决定性提供另一组强结论。

一个集合确定后，可通过博弈得到多种正则性后果，但不同定理的假设与适用范围仍须逐项检查。

广泛贝尔性是对力迫扩张稳定的表示性质。

它不是投影层级中简单的“下一个点类”。

整齐与弱整齐树同样属于表示技术，不应与普通 Borel 复杂度混成单维序列。

## 13. 实数正则性六行教学对照

| 索引 | 教学阶段 | 主要章 | 关键接口 |
|---|---|---|---|
| 0 | Borel 与经典正则性 | 40、81–82 | 拓扑、测度、完备子集 |
| 1 | 解析与余解析 | 41、82、111 | 树表示、良基性、准秩序 |
| 2 | Σ¹₂ 与 Shoenfield | 112 | 绝对性、Mansfield–Solovay、可测资源 |
| 3 | Σ¹₃ 与广泛贝尔 | 113 | 双树、力迫稳定与三正则性 |
| 4 | 投影决定性 | 120–121 | 测度塔、整齐树、Martin–Steel 归纳 |
| 5 | L(ℝ) 内全部实数集合 | 122 | 泛型正确、参数极小化与 AD |

这里的“对齐”表示阅读上的资源接口。

它不表示六行两两等价，也不表示每一行自动推出下一行。

真正的推出关系写在 94–122 各主定理中。

## 14. 三轴怎样合流

大基数提供嵌入和测度。

力迫与内模型技术把这些资源运输到合适的模型。

树表示把实数集合的成员资格改写成分支、秩、测度或策略问题。

决定性最后把表示证书转成胜负策略。

这条链上任何一环都不能被“有限程序跑完”替代。

有限程序能测试某一步在固定有限实例中的形状，不能量化所有基数、所有泛型扩张或所有实数集合。

因此本章的源码只把三条轴的行号对齐。

数学含义完全由上述正文承担。

## 15. Lean：有限六行关系的内核证明

Lean 通道用一个含三个 `Fin 6` 字段的结构表示一行对照。

`closingAxis i` 把同一个索引放进三个轴。

定理分别检查三字段、六行总数和首尾行。

这些命题很小，所以可由 `decide` 或定义等号直接证明。

没有导入整个 mathlib，也没有 `sorry`。

```lean
import Mathlib.Data.Fintype.Card

/-!
# 第 123 章 · 收官：有限三轴对照表

这里只证明教程索引中的有限关系，不声称形式化大基数、力迫或决定性定理。
-/

/-- 三轴使用同一组六个索引；数学内容见第 123 章正文。 -/
structure AxisEntry where
  strength : Fin 6
  forcing : Fin 6
  regularity : Fin 6
  deriving DecidableEq, Repr

/-- 第 i 行把三个轴的第 i 个教学阶段对齐。 -/
def closingAxis (i : Fin 6) : AxisEntry := ⟨i, i, i⟩

theorem closingAxis_coherent (i : Fin 6) :
    (closingAxis i).strength = i ∧
    (closingAxis i).forcing = i ∧
    (closingAxis i).regularity = i := by
  exact ⟨rfl, rfl, rfl⟩

theorem six_axis_rows : Fintype.card (Fin 6) = 6 := by
  decide

theorem first_and_last_rows :
    closingAxis 0 = ⟨0, 0, 0⟩ ∧ closingAxis 5 = ⟨5, 5, 5⟩ := by
  decide
```

这里证明的是有限表没有错位。

它没有证明不可达、可测、超紧或武丁基数存在。

更没有证明大基数推出决定性。

`Fintype.card (Fin 6) = 6` 只是行数证书。

## 16. Isabelle/ZF：对象逻辑中的同一有限关系

Isabelle 通道保留 ZF-Constructible 会话环境。

六个阶段用自然数小于 `Six` 表示，避免把集合论对象和编程语言字符串混在一起。

三个谓词共享同一范围，因而可直接证明等价。

首尾行和“没有第七行”分别检查边界。

```isabelle
theory Topic
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 123 章：三轴共用六个有限索引。这里只核验索引关系，
不声称形式化大基数、力迫、投影决定性或 AD。\<close>

definition Six where
  "Six \<equiv> succ(succ(succ(succ(succ(succ(0))))))"

definition Strength where
  "Strength(n) \<equiv> n:nat & n<Six"

definition Forcing where
  "Forcing(n) \<equiv> n:nat & n<Six"

definition Regularity where
  "Regularity(n) \<equiv> n:nat & n<Six"

lemma axes_coincide:
  "(Strength(n) <-> Forcing(n)) & (Forcing(n) <-> Regularity(n))"
  by (simp add: Strength_def Forcing_def Regularity_def)

lemma first_row: "Strength(0)"
  by (simp add: Strength_def Six_def)

lemma last_row: "Regularity(succ(succ(succ(succ(succ(0))))))"
  by (simp add: Regularity_def Six_def)

lemma no_seventh_row:
  "Strength(Six) \<Longrightarrow> False"
  by (simp add: Strength_def Six_def)

end
```

这里的 `Strength` 只是有限索引谓词的名字。

它不是“n 是强基数”的定义。

同样，`Regularity` 也不是 Lebesgue 可测性的形式化。

使用 Constructible 父会话只表示本教程的 Isabelle 环境连续，不表示本段用到了覆盖或决定性库定理。

## 17. Coq：六构造子与链端点

Coq 用六个构造子把有限阶段做成归纳类型。

`code` 给出自然数编码，三个轴共用这份编码。

全称定理通过对 `stage` 分六种情况完成。

`next` 还记录相邻行关系以及第五行没有后继。

```coq
Require Import Arith.

(* 第 123 章：六个教学阶段上的有限三轴关系；不形式化无限数学。 *)

Inductive stage : Type :=
  stage0 | stage1 | stage2 | stage3 | stage4 | stage5.

Definition code (s : stage) : nat :=
  match s with
  | stage0 => 0 | stage1 => 1 | stage2 => 2
  | stage3 => 3 | stage4 => 4 | stage5 => 5
  end.

Definition strength_code (s : stage) : nat := code s.
Definition forcing_code (s : stage) : nat := code s.
Definition regularity_code (s : stage) : nat := code s.

Theorem three_axes_coherent :
  forall s : stage,
    strength_code s = code s /\
    forcing_code s = code s /\
    regularity_code s = code s.
Proof. intros []; repeat split; reflexivity. Qed.

Theorem six_stage_cases :
  forall s : stage,
    s = stage0 \/ s = stage1 \/ s = stage2 \/
    s = stage3 \/ s = stage4 \/ s = stage5.
Proof. intros []; intuition. Qed.

Definition next (s : stage) : option stage :=
  match s with
  | stage0 => Some stage1 | stage1 => Some stage2
  | stage2 => Some stage3 | stage3 => Some stage4
  | stage4 => Some stage5 | stage5 => None
  end.

Theorem chain_endpoints :
  next stage0 = Some stage1 /\ next stage5 = None.
Proof. split; reflexivity. Qed.
```

`six_stage_cases` 是有限类型穷尽性，不是大基数分类定理。

`chain_endpoints` 也只检查教学表的端点。

Coq 没有在此形式化任何无限力迫或投影层定理。

## 18. Agda：逐构造子的定义等号

Agda 文件与 Coq 使用相同的有限数据模型。

三个编码函数都定义为 `code`。

相干定理由 `refl` 给出，首尾编码同样由计算完成。

```agda
module Ch123_topic where

open import Data.Nat using (ℕ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 第 123 章：有限六阶段对照；不声称机器证明任何大基数定理。

data Stage : Set where
  stage0 stage1 stage2 stage3 stage4 stage5 : Stage

code : Stage → ℕ
code stage0 = 0
code stage1 = 1
code stage2 = 2
code stage3 = 3
code stage4 = 4
code stage5 = 5

strength-code : Stage → ℕ
strength-code = code

forcing-code : Stage → ℕ
forcing-code = code

regularity-code : Stage → ℕ
regularity-code = code

strength-coherent : (s : Stage) → strength-code s ≡ code s
strength-coherent s = refl

forcing-coherent : (s : Stage) → forcing-code s ≡ code s
forcing-coherent s = refl

regularity-coherent : (s : Stage) → regularity-code s ≡ code s
regularity-coherent s = refl

first-row : code stage0 ≡ 0
first-row = refl

last-row : code stage5 ≡ 5
last-row = refl
```

这里没有 `postulate`。

但“没有 postulate”只说明这些有限等式没有额外假设。

它不把正文中未形式化的无限命题偷偷变成构造性证明。

## 19. Julia：真实目录与单元公式

数值通道不再打印一个标题就结束。

Julia 先检查三轴都有六个符号行，再从 `@__DIR__` 定位教程根目录。

正则表达式只接受 `两位或三位章号-主题.md`。

扫描结果与 `0:148` 比较，郝/杨跃篇集合与 `124:148` 比较。

最后的 948 由 `869+79` 给出：前十二篇 869 单元原样保留，第十三篇
新增 79 个通道单元。

```julia
println("==== 123")

# 六行只是阅读索引，不是六个无限定理的机器证明。
strength = [:inaccessible, :measurable, :supercompact,
            :woodin, :woodin_limit, :measurable_above]
forcing = [:small, :prikry, :proper, :ideal, :tower, :iteration]
regularity = [:borel, :analytic, :sigma12, :universally_baire,
              :projective, :ad_l_r]
@assert length(strength) == length(forcing) == length(regularity) == 6
@assert collect(1:6) == [i for i in 1:6 if strength[i] isa Symbol &&
                         forcing[i] isa Symbol && regularity[i] isa Symbol]

# 直接扫描最终教程目录，避免只检查程序内部写死的章表。
docs = normpath(joinpath(@__DIR__, "..", "..", "docs"))
function chapter_number(file)
    m = match(r"^(\d{2,3})-.*\.md$", file)
    return m === nothing ? nothing : parse(Int, m.captures[1])
end
chapters = sort([chapter_number(f) for f in readdir(docs)
                 if chapter_number(f) !== nothing])
@assert chapters == collect(0:148)
@assert length(chapters) == length(unique(chapters)) == 149

# 第十三篇（郝兆宽·杨跃路线）并入：124-148，共 25 章。
hao_chapters = filter(n -> n >= 124, chapters)
@assert hao_chapters == collect(124:148)
@assert length(hao_chapters) == 25

# 前十二篇 869 单元；郝/杨跃篇新增
# lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 = 79。
hao_units = Dict(:lean => 16, :isabelle => 8, :coq => 6, :agda => 0,
                 :julia => 15, :python => 24, :prolog => 10)
@assert sum(values(hao_units)) == 79
baseline_units = 869
final_units = baseline_units + sum(values(hao_units))
@assert final_units == 948
println("docs: 149 chapters, continuous 00-148; hao=25")
println("axes: 6 aligned rows; units: 869+79=948")
println("END ====")
```

Julia 的断言直接读取最终文档目录。

若缺章、重号或出现不符合命名规范的额外章，比较会失败。

它仍不检查 Markdown 正文的数学正确性。

三轴符号也只是教学索引，不是形式化模型。

## 20. Python：独立实现的目录对拍

Python 使用 `pathlib` 与另一套生成式实现。

章号来自文件路径，而不是手工输入的 149 项列表。

郝/杨跃篇章集合和单元公式分别断言。

```python
from pathlib import Path
import re

print("==== 123")

strength = ["inaccessible", "measurable", "supercompact",
            "woodin", "woodin_limit", "measurable_above"]
forcing = ["small", "prikry", "proper", "ideal", "tower", "iteration"]
regularity = ["borel", "analytic", "sigma12", "universally_baire",
              "projective", "ad_l_r"]
assert len(strength) == len(forcing) == len(regularity) == 6
assert all(isinstance(row, tuple) and len(row) == 3
           for row in zip(strength, forcing, regularity))

# 与 Julia 分开实现目录解析；章号来自最终 Markdown 文件名。
docs = Path(__file__).resolve().parents[2] / "docs"
chapters = sorted(
    int(match.group(1))
    for path in docs.glob("*.md")
    if (match := re.fullmatch(r"(\d{2,3})-.*\.md", path.name)) is not None
)
assert chapters == list(range(149))
assert len(chapters) == len(set(chapters)) == 149

# 第十三篇（郝兆宽·杨跃路线）并入：124-148，共 25 章。
hao_chapters = [n for n in chapters if n >= 124]
assert hao_chapters == list(range(124, 149))
assert len(hao_chapters) == 25

# 前十二篇 124 章七通道 + Lean 整工程汇总 = 869；郝/杨跃篇新增
# lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 = 79。
hao_units = dict(lean=16, isabelle=8, coq=6, agda=0,
                 julia=15, python=24, prolog=10)
assert sum(hao_units.values()) == 79
baseline_units = 869
final_units = baseline_units + sum(hao_units.values())
assert final_units == 948
print("docs: 149 chapters, continuous 00-148; hao=25")
print("axes: 6 aligned rows; units: 869+79=948")
print("END ====")
```

Python 与 Julia 的目录约定相同，但解析代码独立。

这种对拍主要防止账本写错。

若两者共享一个错误的数学定义，对拍仍可能同时通过。

所以交叉实现不是数学证明的替代品。

## 21. Prolog：关系式审计

Prolog 把三轴写成六个 `row/3` 项。

`chapter_number/2` 从文件名抽取章号，`sort/2` 同时排序和去重。

连续章表、郝/杨跃篇章集合与 948 公式分别由 `must/2` 检查。

源码位置由 `source_file/2` 获得，因此从项目外部调用也能找到 docs。

```prolog
:- encoding(utf8).
/* 第 123 章：独立目录对账；有限三轴表不冒充无限定理。 */

axis_rows([
    row(inaccessible, small, borel),
    row(measurable, prikry, analytic),
    row(supercompact, proper, sigma12),
    row(woodin, ideal, universally_baire),
    row(woodin_limit, tower, projective),
    row(measurable_above, iteration, ad_l_r)
]).

chapter_number(Entry, N) :-
    file_name_extension(Base, md, Entry),
    ( sub_atom(Base, 0, 3, _, Prefix),
      sub_atom(Base, 3, 1, _, '-')
    ; sub_atom(Base, 0, 2, _, Prefix),
      sub_atom(Base, 2, 1, _, '-')
    ),
    atom_number(Prefix, N).

must(Goal, Label) :-
    ( call(Goal) -> true
    ; format('FAILED: ~w~n', [Label]), fail
    ).

main :-
    format('==== 123~n'),
    axis_rows(Rows), length(Rows, 6),
    source_file(main, File),
    file_directory_name(File, PrologDir),
    file_directory_name(PrologDir, ExamplesDir),
    file_directory_name(ExamplesDir, Root),
    directory_file_path(Root, docs, Docs),
    directory_files(Docs, Entries),
    findall(N, (member(E, Entries), chapter_number(E, N)), Found),
    sort(Found, Chapters),
    numlist(0, 148, Expected),
    must(Chapters = Expected, continuous_chapters),
    length(Chapters, 149),
    numlist(124, 148, HaoExpected),
    intersection(Chapters, HaoExpected, HaoChapters),
    must(HaoChapters = HaoExpected, hao_chapter_set),
    length(HaoChapters, 25),
    /* lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 */
    HaoUnits is 16 + 8 + 6 + 0 + 15 + 24 + 10,
    must(HaoUnits =:= 79, hao_unit_count),
    FinalUnits is 869 + HaoUnits,
    must(FinalUnits =:= 948, unit_formula),
    format('docs: 149 chapters, continuous 00-148; hao=25~n'),
    format('axes: 6 aligned rows; units: 869+79=948~n'),
    format('END ====~n').

:- initialization(main).
```

这里特别避免 `forall/2` 的绑定泄漏。

所有集合先由 `findall/3` 收集，再作具体等式和长度检查。

Prolog 的通过表示搜索与关系检查完成。

它不表示 Prolog 证明了任何 ZF 定理。

## 22. 948 单元怎样计算

前十二篇的原有账目是 869 个单元（124 章七通道加 Lean 整工程汇总）。

第十三篇并入 25 章，但它不是每章七通道全配：郝/杨跃篇新增
lean 16、isabelle 8、coq 6、julia 15、python 24、prolog 10，
没有 Agda 单元，合计 79 个通道单元。

于是最终公式是：

$$869+79=948.$$

这个公式解释同一报告结构。

它不是把失败的通道折算成通过，也不是把文档行数算成验证单元。

最终验收必须引用 `build.ps1 -All` 的真实 PASS/FAIL 输出。

本次只运行一个顺序全量构建，最终退出码为 0，真实汇总为：

> 总计 948 单元：PASS 948 / FAIL 0
>
> 全绿。

## 23. 七通道职责总表

| 通道 | 最适合承担 | 不能据此宣称 |
|---|---|---|
| Lean + mathlib | 官方数学锚点、有限全称证明、库定理连接 | 已有完整力迫或 AD 形式化 |
| Isabelle/ZF | 一阶集合论、Constructible、有限对象逻辑证书 | 任何 ZF 语句都可自动 blast |
| Coq | 可判定结构、显式计算、零公理小证明 | 超时前的搜索算完成证明 |
| Agda | 构造性有限数据、结构递归、策略证书 | 有限递归覆盖无限博弈 |
| Julia | 高效枚举、独立动态规划和反例搜索 | 数值样本证明无限命题 |
| Python | 精确算术、对拍、目录与证书审计 | 与另一程序相同就必为正确 |
| Prolog | 关系搜索、路径、策略与有限约束 | 空查询成功就是全称定理 |

七通道的价值是差异。

证明助手检查形式命题，计算通道寻找实例，关系通道保留搜索结构。

正文则负责无限数学的完整论证。

三者不可互相冒名。

## 24. 机器化边界总表

| 无限命题 | 教程中的机器内容 | 边界 |
|---|---|---|
| Cantor、序数与基数基础 | 官方库定理和完整小证明 | 部分基础可完整形式化 |
| L 中 AC/GCH | Isabelle Constructible 锚点 | 教程不重写整个 Paulson 开发 |
| 力迫定理与 CH 独立性 | 偏序、布尔代数、有限名字和泛型实验 | 不宣称完整力迫引擎 |
| Jensen 覆盖与 0# | 有限秩、组合证书和模型示意 | 覆盖定理本体由正文证明 |
| 大基数与泛型超幂 | 有限滤子、Łoś 特例、下降链证书 | 有限超滤子不是可测基数 |
| 荟萃塔与迭代树 | 有限塔链、父表、路径与选枝证书 | 不证明一般良基性或可迭代性 |
| Martin–Steel | 有限博弈、策略提升、测度证书形状 | 不冒充无限投影决定性证明 |
| AD^{L(ℝ)} | 65536 张有限收益表与参数编码 | 不证明任何无限博弈或全域 AD |

最重要的阅读规则是：看定理量词，再看程序量词。

两者范围不同，就不能把后者的 PASS 写成前者的机器证明。

## 25. 构建与文档纪律

Lean 使用定向导入。

一次 `import Mathlib` 曾造成约 3.3 GB 峰值并被内存回收器终止，定向导入则可在十几秒级完成。

重型构建一次只运行一个。

Isabelle 被杀后的 SQLite 残留需要 `build -C` 清理，不能反复启动新进程叠加负载。

构建脚本必须由 PowerShell 7 的 `pwsh.exe` 执行。

Python 用 `-I`，Prolog 文件带 UTF-8 编码声明。

管道尾命令的退出码可能掩盖前段失败，最终结论必须看构建脚本汇总。

## 26. Lean 实测坑索引

| 坑 | 收官经验 |
|---|---|
| 全量导入内存峰值 | 只导入实际需要的 mathlib 模块 |
| `native_decide` 的使用范围 | 只用于可判定有限全称命题，并如实标明 |
| 反向签名与 unusedVariables | 警告能抓出参数顺序和签名写反 |
| `omega` 不见 β-redex | 先把目标化到算术形状 |
| 投影不能穿透 def-And | 用 `obtain` 拆出证明字段 |
| `abbrev` 与 `decide` | 需要计算穿透时选可展开定义 |
| `extends` 是保留字 | 结构字段和变量避免撞语法 |
| 数字、开命名空间与 ZF 风格移植 | 不把另一系统记法直接搬入 Lean |
| `imageN` 等不可计算定义 | 必要时声明 noncomputable 并区分计算与证明 |
| 策略查询位置错误 | 先打印实际目标和实例，再改 tactic |

这些坑的共同教训是“让目标形状可见”。

猜测库名或盲目加 tactic 往往扩大问题。

## 27. Isabelle/ZF 实测坑索引

| 坑 | 收官经验 |
|---|---|
| `blast` 展开 Collect 爆炸 | 改为谓词式定义和受控规则链 |
| THE-fst 死循环 | 避免让确定性搜索进入不可控 rewrite 循环 |
| 数字 ≥3 的集合字面量 | 用 ZF 可解析的构造或 `succ` 表达式 |
| `nat_rec` 首参与 equalities | 回读实际定理签名和导入 |
| 展开后的投影形式 | 先归一成引理结论的形状 |
| 链式前提顺序 | 按实际规则的消费顺序排列 |
| `OF` 与元级推导 | 区分对象级 simp 和元级 mp |
| `image_inter` 假设后置 | 不要按 HOL 或纸面顺序猜参数 |
| 函数空间参数 | ZF 集合函数不能当元级函数随意应用 |
| `Isabelle equalityD1` | 单链使用，避免规则方向错配 |

Isabelle 的通过必须来自真实 session build。

编辑器未报错或旧缓存存在都不等于当前源文件通过。

## 28. Coq 实测坑索引

| 坑 | 收官经验 |
|---|---|
| 全表 `vm_compute; btauto` 失控 | 缩小命题或使用代表证书，不虚报穷举 |
| `lia` 不认 mod | 先消去模运算或提供线性事实 |
| `subst` 不展开定义谓词 | 显式 `unfold` 或改变目标 |
| `funext` rewrite 方向 | 函数等式需要合适方向和外延性 |
| `firstn` simpl 过展 | 用 `change` 固定目标形状 |
| `dependent destruction` | 用于索引路径唯一性，避免普通 destruct 丢依赖 |
| 全表 btauto 与代表证书 | 正文必须说明实际覆盖范围 |
| 复合键与 `in_map_iff` | 显式给出见证和等式参数 |
| guard 与递归燃料 | 结构递归不可用时明确燃料及终点判定 |
| `Print Assumptions` | 用来核对公理，不凭“Qed”猜零公理 |

代表证书不是全表证明。

第 122 章中 Coq 与 Agda 的范围就和 Lean 的全表证明明确区分。

## 29. Agda 实测坑索引

| 坑 | 收官经验 |
|---|---|
| `with` 不穿透假设或索引卡壳 | 改用 Bool 参数归纳或显式消去 |
| `where` 不见 lambda 变量 | 把依赖提升为显式参数 |
| 双层 rewrite | 等式同步后再改写，不假设自动运输 |
| stdlib any/all 重定向 | 回读当前版本导出名称 |
| `%` 需要 NonZero | 可改为有限倍数枚举，避免无关实例负担 |
| `Data.Nat` 不导出 `Nat` | 使用 `ℕ` 和当前库的实际类型名 |
| 截断减是 `_∸_` | 不把 Julia/Python 的减号直接移植 |
| 布尔合取与列表逗号 | 遵守 Agda 语法，而非 Haskell 记忆 |
| WSL 路径 | 经 `wslpath` 转换并显式给 stdlib include |

Agda 的证明相关风格很适合策略与树证书。

但有限递归的燃料必须和数学终点分开说明。

## 30. Julia 实测坑索引

| 坑 | 收官经验 |
|---|---|
| 顶层循环 global | 用函数封装状态和穷举计数 |
| 负数 `%` 与 `mod` | 按需要非负余数选择 `mod` |
| `findfirst` 返回索引 | 不把索引误当元素本身 |
| `ntuple` 参数一基 | 生成器坐标和策略表坐标保持一致 |
| Julia 1.13 移除 Random.sample | 自写明确可复现的采样器 |
| tuple(generator) | 需要固定元组时用 `ntuple` |
| struct 多行与插值 | 遵守语法并检查全角字符邻接 |
| 穷举下界 | 手写组合下界可能被机器反例纠正 |

Julia 的速度适合全表枚举。

但速度只降低实验成本，不改变命题量词。

## 31. Python 实测坑索引

| 坑 | 收官经验 |
|---|---|
| 裸分式默认整数的风险 | 需要精确有理数时明确 `Fraction` |
| GBK 输出 | 构建环境统一 UTF-8，脚本可用 `-I` |
| 不变过滤 | 逐赋值检查，避免一行过滤改变不变量 |
| 浮点三进制地址 | 精确算术优先，避免伪反例 |
| 动态规划方向 | 从终局向起点归并，玩家奇偶不可倒换 |
| 对拍独立性 | 数据结构和更新顺序尽量独立，而非复制函数 |

Python 的优势是清楚和精确类型丰富。

这使它适合给 Julia 的快速实现做第二本账。

## 32. Prolog 实测坑索引

| 坑 | 收官经验 |
|---|---|
| `forall/2` 生成—测试语义 | member 在测试侧只有存在意义，先收集再检查 |
| `forall` 不外传绑定 | 需要证书时用 findall 或显式回收 |
| `==` 与 `=:=` | 项同一性和算术求值不能混用 |
| `min3` 非内建 | 自写并测试，不凭其他 Prolog 经验猜 |
| 中缀项静默假绿 | `(A-X)-0` 可能只是项，不是预期算术 |
| 拆尾与 append | 砍尾不砍首，列表方向须由样例钉住 |
| `initialization(main)` | 项目统一 `main/0` 入口，避免 main/1 假象 |
| encoding(utf8) | 中文输出和源码必须带编码声明 |
| format 非法指令 | 清文档格式后全链重建，不能只看直接运行 |

Prolog 最容易出现“没有答案却被当成通过”。

因此关键检查必须有正例、负例和预期数量。

## 33. 数学自纠总账

机器实验也纠正过正文，而不只是纠正代码。

古德斯坦书表、Div(18) 的补律、预滤子的有限交条件和完美树密度账都经过独立计算或反例复核。

第 121 章定理 3.68(2) 上方可测基数的假设被重新标明。

第 122 章把 AD 的结论严格限制在 L(ℝ) 内，避免误读为全域 AD。

有限穷举还发现过覆盖一次不等于持续覆盖、自由位漏算和玩家坐标不一致。

这些例子说明正确流程是双向的。

数学约束程序，程序审计有限账目。

若程序与书表冲突，先回读原页和定义，再独立推导，不能为了“全绿”删反例。

## 34. 收官前阅读清单

想复习公理与基数，读 01–09、67–78。

想复习传递模型与 L，读 10–15、84–89。

想复习力迫，比较 16–22、46–55、90–92、103–110。

想复习实数正则性，沿 40–45、81–82、111–115 阅读。

想复习高阶无穷的决定性主线，依次读 94、96、100–102、109–110、116–122。

每次读主定理都先列假设。

再列证明中每个引理消费哪一条假设。

最后检查结论是 ZFC 定理、相对一致性结论，还是额外大基数假设下的定理。

## 35. 全书最后一句话

从 Cantor 对角线到 AD^{L(ℝ)}，变化的是对象、工具与假设的强度。

不变的是论证的账本：对象怎样构造，量词作用在哪里，前提在哪一步消费，结论在哪一个宇宙中成立。

七通道让这本账多出可运行的有限证书和库定理锚点。

它们没有取消纸面证明的责任，反而使证明边界更清楚。

---

上一章：[122 AD^{L(ℝ)} 与全书主线汇合](122-adlr.md) · 下一章：（完）
