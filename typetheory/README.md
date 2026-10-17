# 类型论指南（typetheory）：从 λ 演算到同伦类型论

面向**会编程（任意语言背景）、想系统学类型论**的读者。以七本
读本为骨架（Hindley《Basic Simple Type Theory》、Nederpelt–
Geuvers《Type Theory and Formal Proof》、《类型和程序设计语言》
(TAPL)、Nordström 等《Martin-Löf 类型论程序设计导论》、HoTT 书、
Farmer《Simple Type Theory》、《现代类型论的发展与应用》），
横跨 **Coq / Coq-HoTT（自包含 mini-HoTT）/ Agda / Lean 4 / SWI-Prolog**
五种实现讲解。

**章号 = 示例编号**——除 60（坑位清单）与 55/58 的陈述级部分外，
每章对应 `examples/NN_name/` 里经多通道（coqc 8.20.1 /
WSL Agda 2.8.0+stdlib 2.3——第六部分另启用其 `--cubical` 模式 /
Lean 4.25.0 / swipl 10.0）机器验证的完整文件。

> 核心理念：**类型论 = 语法分层 × 依赖类型 × Curry–Howard**。
> λ 演算（02）→ 简单类型双轮：Hindley 证明论线（03–11）+
> Farmer 模型论线（12–17）→ λ 立方体（18–21）→ Martin-Löf
> （27–33）→ 证明助手实战（34–35）→ **程序设计语言类型论
> （36–46）** → 同伦（47–58）→ 元理论与收束（59–60）。

## 目录结构

```text
typetheory/
├── README.md          本文件
├── build.ps1          多通道验证（-All/-Chapter/-Lang/-File/-List/-Clean）
│                      + 运行通道（Lean main 自动 --run；
│                      Agda *_run.agda 触发 --compile+执行+清理）
├── CHEATSheet.md      记号/规则/四家语法速查 + 精选坑位
├── docs/              60 章教程（01 → 60 顺序阅读，七个部分）
└── examples/          章目录（章号 = 示例编号）
```

## 章节索引

### 第一部分 · 简单类型论（01–17）

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识类型论](docs/01-intro.md) | 悖论→三主线→四助手；同一定理四家对照 | 三家各一 |
| [02 无类型 λ](docs/02-lambda.md) | de Bruijn/β/CR；Church 算术、SKK=I、Ω | 三镜像 |
| [03 η、βη 与 λI](docs/03-eta.md) | η-归约/后置/βη-合流；λI 与 K 不可定义 | 三镜像 |
| [04 λ→](docs/04-stlc.md) | 三种工程路线：检查器/推导即数据/内在式 + progress | 三路线 |
| [05 Curry 指派](docs/05-curry.md) | 合一+主类型算法（HM 之根），occurs check | Lean |
| [06 等式规则与语义](docs/06-eqsem.md) | Eq-规则/后置/WN-非-SN；λ-模型、类型解释、完备性 | Lean+Prolog |
| [07 正规化与可指派刻画](docs/07-norm.md) | 图灵 1942 度数策略机器化；Y/SN-反例/BCKλ 三票 | Lean 旗舰 |
| [08 Curry–Howard](docs/08-curryhoward.md) | 同构精确表述（三层/非单射/最疏散代表元）；居留搜索 | 三家 |
| [09 弱逻辑与子结构 λ](docs/09-sub.md) | R_/BCK/BCI ↔ λI/BCKλ/BCIλ；四公理集矩阵 | Lean+Prolog |
| [10 逆主类型与凝结分离](docs/10-converse.md) | 逆 PT/Meyer 构造/双胞胎定理；D-规则=PT 应用情形 | Prolog 主场+Lean |
| [11 居留项计数](docs/11-counting.md) | Ben-Yelles 长式搜索；D(τ)=｜τ｜×‖τ‖ 三案例判定 | Prolog 主场+Lean |
| [12 Alonzo](docs/12-alonzo.md) | Church 式七构造子；V1–V7 部分赋值；Henkin 落域可执行化 | Lean+Prolog |
| [13 未定义性](docs/13-undef.md) | TATU 三原则；= vs ≃；非法 β 双反例；K3 对照 | Lean+Prolog |
| [14 证明系统 A](docs/14-proofsystem.md) | 公理即合一的检查器；A.3 三步原证；节俭模型与完备性 | Prolog 主场+Lean |
| [15 理论与模型论](docs/15-theories.md) | 四级扩张；PA⁺ 紧致性引擎；范畴性/完备性；结构枚举机 | Prolog 主场+Lean |
| [16 理论态射与小理论](docs/16-morphisms.md) | 态射定理；义务清偿；运输双实例；GRP 负例见证 | Lean 旗舰+Prolog |
| [17 描述算子、选择与引用](docs/17-desc.md) | I/ε/AC 三级；Coq iota 古典互证；引用往返定理 | Coq 主场+Lean |

### 第二部分 · λ 立方体与 λD（18–26）

| 章 | 主题 | 示例 |
|---|---|---|
| [18 System F](docs/18-systemf.md) | 双 β 引擎；Church 数带类型复活；I I 翻案 | 三家 |
| [19 依赖类型](docs/19-dependent.md) | Vec/Even/even_double；加法方向学三连 | 三家 |
| [20 立方体 λC](docs/20-cube.md) | mini-PTS 内核：八系统=八张规则表可执行 | 三家 |
| [21 λC 逻辑编码](docs/21-logic.md) | ⊥¬∧∨∃ 二阶编码即程序；ET↔DN 零公理；λP2 检查器 | Lean+Prolog |
| [22 定义 λD](docs/22-definitions.md) | Section/opaque/模块三管理术 | 三家 |
| [23 λD 形式系统](docs/23-lambdad.md) | def/inst 两规则；δ-归约可执行；原始定义=公理 | Lean+Prolog |
| [24 旗式自然演绎](docs/24-flags.md) | 附录 A 规则库=定义；旗式解释器；图 11.16 全 7 行 | Prolog 主场+Lean |
| [25 λD 数学：等式/序/ι](docs/25-ldmath.md) | Leibniz 等式=定义；∃¹ 与 ι 握手 17 章；子集即谓词 | Lean 主场+Prolog |
| [26 从 Peano 到 Bézout](docs/26-bezout.md) | 公理化 Peano 记账；整数=对之商；九个洞；eea 见证 | Coq 主场+Lean |

### 第三部分 · Martin-Löf 类型论（27–33）

| 章 | 主题 | 示例 |
|---|---|---|
| [27 判断与规则](docs/27-judgments.md) | 四种判断；等式四公理动作 | 三家 |
| [28 Π 与枚举](docs/28-enums.md) | ⊥/⊤/Bool；荒谬三拼写；Π-填表 | 三家 |
| [29 相等与 J](docs/29-identity.md) | MyEq 手造；四件套 J 手推；funext 边界 | 三家 |
| [30 归纳族](docs/30-indfam.md) | 自造 ℕ/List/Σ/Sum；add_comm Peano 三步走 | 三家 |
| [31 全域](docs/31-universes.md) | 宇宙塔；Cumulativity 三家立场 | 三家 |
| [32 W 类型](docs/32-wtypes.md) | 良序归纳；ℕ=W Bool；W-加法 2+3=5 | 三家 |
| [33 子集与强制](docs/33-subtype.md) | sig/Subtype/Σ；Coercion/Coe/函数 | 三家 |

### 第四部分 · 证明助手实战（34–35）

| 章 | 主题 | 示例 |
|---|---|---|
| [34 四家对照](docs/34-fourways.md) | rev·rev 一题三文化 | 三家 |
| [35 提取与运行](docs/35-extraction.md) | Extraction/lean --run/MAlonzo 编译 | 三家 |

### 第五部分 · 程序设计语言的类型论（36–46）

| 章 | 主题 | 示例 |
|---|---|---|
| [36 操作语义](docs/36-opsem.md) | NB 语言；小步/大步；推导归纳；stuck；安全性 | Coq+Prolog |
| [37 简单扩展](docs/37-extensions.md) | unit/序列/归属/let/序对/记录/变式/一般递归/列表 | Prolog+Coq |
| [38 引用与异常](docs/38-refs.md) | store typing；带状态的安全性；异常 | Coq+Prolog |
| [39 子类型](docs/39-subtyping.md) | 记录宽度深度置换；包含规则；算法化；合类型 | Coq+Prolog |
| [40 命令式对象与 FJ](docs/40-objects.md) | 命令式对象；轻量级 Java 演算 | Prolog+Coq |
| [41 递归类型](docs/41-rectypes.md) | μ；等式/同构递归；归纳与余归纳；成员算法 | Coq+Prolog |
| [42 类型重构](docs/42-reconstruction.md) | 约束类型化；合一；主类型；let 多态 | Prolog 主场+Coq |
| [43 存在类型](docs/43-existentials.md) | pack/unpack；ADT；存在量词编码 | Coq+Prolog |
| [44 囿量词 F<:](docs/44-bounded.md) | 界限量词；算法化；全系统不可判定性 | Prolog+Coq |
| [45 类型算子与 Fω](docs/45-higherorder.md) | kind；高阶多态；高阶子类型 | Agda+Prolog |
| [46 纯函数对象](docs/46-pureobjects.md) | 存在包×记录×self 三合一；更新=函数组合 | Prolog |

### 第六部分 · 同伦类型论（47–58）

| 章 | 主题 | 示例 |
|---|---|---|
| [47 路径与同伦](docs/47-paths.md) | 零公理 paths 库；群律；纤维化与 transport 族；UIP 天花板 | 三家 |
| [48 等价论](docs/48-equivalence.md) | quasi-inverse/半伴随/双可逆/合同纤维四定义互含；embed/surj | cubical Agda+Coq |
| [49 泛等](docs/49-univalence.md) | 等价即相等；Bool 取反新路；UA⇒函数外延 | 三家+cubical |
| [50 集合与逻辑](docs/50-setlogic.md) | h-level；mere prop；AC 是定理；唯一选择 | cubical Agda+Lean |
| [51 截断与 n-类型](docs/51-truncation.md) | Contr/Prop/Set；Hedberg；连通性 | Coq+cubical |
| [52 归纳进阶](docs/52-induction.md) | 初始代数；同伦归纳型；恒等系统 | cubical Agda |
| [53 高阶归纳类型](docs/53-hit.md) | 区间/圆/商； Suspension/Pushout/Flattening | Coq+cubical |
| [54 压轴：π₁(S¹)](docs/54-capstone.md) | encode-decode 完整证明 + 一般形式 | Coq+cubical |
| [55 同伦论进阶](docs/55-homotopy.md) | Freudenthal；van Kampen；Whitehead；Hopf | cubical 陈述级 |
| [56 范畴论](docs/56-category.md) | precategory；iso≠eq 与饱和；Yoneda；SIP；Rezk 完成 | cubical |
| [57 集合论](docs/57-settheory.md) | Cantor 构造版机器证明；基数/序数；累积层级 V | Lean |
| [58 实数](docs/58-reals.md) | Dedekind vs Cauchy；区间紧性 | cubical 陈述级 |

### 第七部分 · 收束（59–60）

| 章 | 主题 | 示例 |
|---|---|---|
| [59 元理论](docs/59-metatheory.md) | de Bruijn 元定理组；CR/SN 策略地图 | Lean |
| [60 坑位与书目](docs/60-pitfalls.md) | 五类坑位总清单；七书导读；四家速查 | — |

> 第一部分 03/06/07/09/10/11 六章为 Hindley《Basic Simple Type
> Theory》专轮扩充（η/βη/λI、等式与语义、正规化与刻画、弱逻辑、
> 逆主类型与凝结分离、居留计数）——至此该书 1–8 章核心内容全部
> 自包含覆盖，第 9 章技术细节与 52 章元理论相接。
>
> 第二部分 21–26 六章为 TTAFP（Nederpelt–Geuvers）专轮扩充
> （λC 逻辑编码 / λD 形式系统 / 旗式自然演绎与附录 A 规则库 /
> λD 数学：等式·序·ι / 公理化算术与 Bézout）——至此该书
> ch.7–15 + 附录 A/B/C 核心内容全部自包含覆盖，与 Farmer 线
> 在描述子 ι（17 章）与公理化方法（15/16 章）两处互读。
>
> 第五部分为 **TAPL（皮尔斯《类型和程序设计语言》）专轮**（36
> 操作语义 / 37 简单扩展 / 38 引用与异常 / 39 子类型 / 40 命令式
> 对象与轻量级 Java / 41 递归类型 / 42 类型重构 / 43 存在类型 /
> 44 囿量词 / 45 类型算子与 Fω / 46 纯函数对象 十一新章）——至此
> 该书 32 章中本指南未覆盖的部分（ch.3/4/8 操作语义、ch.11 扩展
> 目录、ch.13/14 引用与异常、ch.15–19 子类型与对象、ch.20/21
> 递归类型、ch.22 类型重构、ch.24 存在类型、ch.26–28 囿量词、
> ch.29–32 高阶系统）全部自包含覆盖；已覆盖部分（ch.5/6 无类型
> λ 与 de Bruijn→02、ch.9/10 简单类型→04、ch.23 全称类型→18、
> ch.12 规范化→07 深化）以对读标注衔接。机器面以 **Coq（inductive
> 操作语义与元定理：安全性/算法可靠性/不可判定性陈述）+ Prolog
> （可执行件：NB 求值机/子类型算法/合一与 W/存储机/F 检查器）**
> 双主力，Lean/Agda 延续。

> 第六部分为 **HoTT 书专轮**（48 等价论 / 50 集合与逻辑 /
> 52 归纳进阶 / 55 同伦论进阶 / 56 范畴论 / 57 集合论 / 58 实数
> 七新章 + 47/49/51/53/54 五章深化）——至此该书 ch.1–11 核心
> 内容全部自包含覆盖；机器面以 **cubical Agda**（`--cubical`
> 从 Glue/区间原语手造 ua/hcomp，泛等与 HIT 原生计算：∥·∥
> 真 HIT、ua β 律可证、funext 一行）为主力，Coq mini-HoTT
> 公理化对照组（Hedberg/π₁ 完整版）与 Lean set 层对照
>（Cantor/实数骨架）延续；同伦论大定理（Freudenthal/Hopf/
> van Kampen）以陈述级+证明思想呈现（完整机器版 coq-hott
> 教程续读——已知边界条目）。

## 工具链（本机实测）

| 通道 | 工具 | 判定 |
|---|---|---|
| Coq | coqc 8.20.1（Windows） | exit 0 + stderr 无 Error（拷贝 ex_ 前缀） |
| Agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | exit 0 + 无 error/warning |
| Lean | lean 4.25.0 standalone | exit 0 + 无 error:/warning: |
| Prolog | swipl 10.0.2（Windows 本机） | exit 0 + 无 ERROR/Warning |
| 运行 | Lean 含 `def main` 自动 `--run`；Agda `*_run.agda` 触发 MAlonzo→GHC 编译执行 | 输出含程序结果 |

```powershell
cd typetheory
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 08' # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang agda'  # 单语言
```

## 与本仓库其他教程的关系

- [coq](../coq)（33 章）：tactic 与工程详讲——本指南 34 章后
  的 Coq 深修线；
- [agda](../agda)（55 章）：Agda 全景——第三部分后的 Agda 线；
- [lean4](../lean4)：Lean 4 与 Mathlib——同上；
- [coq-hott](../coq-hott)（25 章）：官方 HoTT 库完整版——
  第五部分（mini-HoTT）的工业级续篇（含 loop ≠ 1、螺旋覆叠）；
- [prolog](../prolog)（27 章）：合一与归结的工程全景——09/10/11
  章 Prolog 通道的语言深修线。

## 已知边界（诚实清单）

- Coq mini-HoTT（49/51/53/54 的公理对照组）为公理记账制：
  UA/β/HIT 构造子公理化，每章 `Print Assumptions` 公示；cubical
  通道补齐计算面；loop ≠ idpath 的完整覆叠论证（55 章）以
  陈述+骨架呈现，完整机器版见 coq-hott 教程续读。
- 05 章主类型算法为 Curry 式单态（无 let-多态）；19 章 Vec
  为示教版（非 stdlib 全功能）。
- 全部示例在本机通道通过；其他版本（Coq 9.x / Agda 3 /
  Lean 4.3x）未测。
- Farmer 专轮的完备性/紧致性/LST 等元定理证明为散文重构
  （附录 B/C 的完整归纳未机器化——机器面取其可执行内核：
  Henkin 落域检查、A.3 标本、PA⁺ 切片引理）；ch.10–12 的
  序列记法/实数开发/知识模块语法以对读形式并入 15/16 章。
- TTAFP 专轮的 λD 性质（10.4–10.5 的 SN/CR 完整归纳）为散文
  重构（机器面取 δ 展开可执行内核）；26 章 Lean 侧 eea 的
  一般规格定理以具体实例验证代替（一般收官在 Coq 侧由
  stdlib 承担——「Lean 看构造、Coq 看收官」分工在案）。
