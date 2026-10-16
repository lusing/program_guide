# 类型论指南（typetheory）：从 λ 演算到同伦类型论

面向**会编程（任意语言背景）、想系统学类型论**的读者。以七本
读本为骨架（Hindley《Basic Simple Type Theory》、Nederpelt–
Geuvers《Type Theory and Formal Proof》、《类型和程序设计语言》
(TAPL)、Nordström 等《Martin-Löf 类型论程序设计导论》、HoTT 书、
Farmer《Simple Type Theory》、《现代类型论的发展与应用》），
横跨 **Coq / Coq-HoTT（自包含 mini-HoTT）/ Agda / Lean 4 / SWI-Prolog**
五种实现讲解。

**章号 = 示例编号**——除 36（仅 Lean）与 37（坑位清单）外，
每章对应 `examples/NN_name/` 里经多通道（coqc 8.20.1 /
WSL Agda 2.8.0+stdlib 2.3 / Lean 4.25.0 / swipl 10.0）机器验证的
完整文件。

> 核心理念：**类型论 = 语法分层 × 依赖类型 × Curry–Howard**。
> λ 演算（02）→ 简单类型双轮：Hindley 证明论线（03–11）+
> Farmer 模型论线（12–17）→ λ 立方体（18–21）→ Martin-Löf
> （27–33）→ 证明助手实战（34–35）→ 同伦（36–40）→
> 元理论与收束（41–42）。

## 目录结构

```text
typetheory/
├── README.md          本文件
├── build.ps1          多通道验证（-All/-Chapter/-Lang/-File/-List/-Clean）
│                      + 运行通道（Lean main 自动 --run；
│                      Agda *_run.agda 触发 --compile+执行+清理）
├── CHEATSheet.md      记号/规则/四家语法速查 + 精选坑位
├── docs/              42 章教程（01 → 42 顺序阅读，六个部分）
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
| [22 定义 λD](docs/22-definitions.md) | Section/opaque/模块三管理术 | 三家 |

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

### 第五部分 · 同伦类型论（36–40）

| 章 | 主题 | 示例 |
|---|---|---|
| [36 路径与同伦](docs/36-paths.md) | 零公理 paths 库；群律；UIP 天花板 | 三家 |
| [37 泛等](docs/37-univalence.md) | 等价即相等；Bool 取反新路 | 三家 |
| [38 截断层级](docs/38-truncation.md) | Contr/Prop/Set；noconf；funext | Coq |
| [39 HIT](docs/39-hit.md) | 区间/圆/商公理化；计算规则补账 | Coq |
| [40 压轴](docs/40-capstone.md) | S¹ 环路代数 iterate_add 完整证明 | Coq |

### 第六部分 · 收束（41–42）

| 章 | 主题 | 示例 |
|---|---|---|
| [41 元理论](docs/41-metatheory.md) | de Bruijn 元定理组；CR/SN 策略地图 | Lean |
| [42 坑位与书目](docs/42-pitfalls.md) | 五类坑位总清单；七书导读；四家速查 | — |

> 第一部分 03/06/07/09/10/11 六章为 Hindley《Basic Simple Type
> Theory》专轮扩充（η/βη/λI、等式与语义、正规化与刻画、弱逻辑、
> 逆主类型与凝结分离、居留计数）——至此该书 1–8 章核心内容全部
> 自包含覆盖，第 9 章技术细节与 41 章元理论相接。

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
- [agda](../agda)（44 章）：Agda 全景——第三部分后的 Agda 线；
- [lean4](../lean4)：Lean 4 与 Mathlib——同上；
- [coq-hott](../coq-hott)（25 章）：官方 HoTT 库完整版——
  第五部分（mini-HoTT）的工业级续篇（含 loop ≠ 1、螺旋覆叠）；
- [prolog](../prolog)（27 章）：合一与归结的工程全景——09/10/11
  章 Prolog 通道的语言深修线。

## 已知边界（诚实清单）

- mini-HoTT（36–40）为公理记账制：UA/β/HIT 构造子公理化，
  每章 `Print Assumptions` 公示；loop ≠ idpath 与
  funext-from-interval 未机器化（42 章清单 + coq-hott 教程续读）。
- 05 章主类型算法为 Curry 式单态（无 let-多态）；19 章 Vec
  为示教版（非 stdlib 全功能）。
- 全部示例在本机通道通过；其他版本（Coq 9.x / Agda 3 /
  Lean 4.3x）未测。
- Farmer 专轮的完备性/紧致性/LST 等元定理证明为散文重构
  （附录 B/C 的完整归纳未机器化——机器面取其可执行内核：
  Henkin 落域检查、A.3 标本、PA⁺ 切片引理）；ch.10–12 的
  序列记法/实数开发/知识模块语法以对读形式并入 15/16 章。
