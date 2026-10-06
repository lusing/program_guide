# 01 全景：数理逻辑 × 证明助手

> 对书：Huth&Ryan §1.1-1.2 与第 2 版前言 / Ben-Ari 3e Ch1-2 / Mints §2.2 / EFT I / Mendelson §1.1
> 通道：C/A/L/I（hello-logic 四连），H4/T 后续章进场

## 为什么计算机科学需要逻辑

Huth&Ryan 开篇给了一个日常论证（§1.1 例 1.1）：

> 如果火车晚点，而且车站没有出租车，那么 John 开会就会迟到。
> John 没有迟到。火车确实晚点了。**因此**，车站有出租车。

直觉上这个论证是对的：把第一句和第三句放在一起，得知「如果没
有出租车，John 就会迟到」；第二句说他没迟到，所以只能是有出租
车。再看第二个例子（§1.1 例 1.2）：

> 如果下雨，Jane 没带伞，就会被淋湿。Jane 没有被淋湿，确实
> 下雨了。**因此**，Jane 带伞了。

把两个例子并排看，会发现一件微妙的事：**它们的论证结构完全
相同**。火车晚点还是下雨、出租车还是雨伞，统统不重要——重要的
只有「如果 p 且非 q，那么 r；非 r；p；因此 q」这个骨架。这就是
逻辑对计算机科学的第一个承诺：**把论证从内容中抽出来，变成可以
机械检查的符号结构**。一旦论证是符号结构，它就能交给计算机处理——
而计算机系统的规范（specification）恰恰就是这样的判断句序列。

只关心结构意味着我们需要一类特殊的语句：**判断句**
（declarative sentence，中译本译「判断语句」）——原则上可以判定
真假的语句。「3 与 5 的和等于 8」是；「请把盐递给我」不是；
「每个大于 2 的偶数是两个素数之和」（哥德巴赫猜想）是——尽管
没人知道它真假，它**原则上**有确定真值。本教程只处理判断句。

## 全书暗线：M ⊨ φ

Huth&Ryan 第 2 版前言交代了全书的 leitmotif（主旋律）：

> 绝大多数用于计算机系统设计、规范与验证的逻辑，本质上都在
> 处理一个**可满足关系** M ⊨ φ——M 是所讨论系统的某种模型，
> φ 是规范（一个公式），表达「在 M 中应该成立的事情」。这个
> 构架的核心在于：我们常常能**指明并实现计算 ⊨ 的算法**。

这句话值得逐字拆。它说逻辑在 CS 里的用法有一个统一形态：

- **M 一侧是「世界」**：02 章里它是一次布尔赋值；15 章里是一个
  带论域和解释的 FOL 模型；24/27 章里是一个迁移系统加上某个
  状态；31 章里是一个 Kripke 框架加上某个可能世界。
- **φ 一侧是「规范」**：一个公式，断言世界应该长什么样。
- **⊨ 是连接两者的关系**，而「计算 ⊨」就是验证：02 章的蛮力
  判定器在算它（命题逻辑，枚举赋值）；28 章的模型检查算法在算它
  （时态逻辑，标记状态集）；25/30 章的霍尔演算换了个姿势——
  不直接算 ⊨，而是用证明演算去**建立**它。

记住这条暗线。本教程 34 章，每一章都可以问一句：「这一章的
M 是什么，φ 是什么，⊨ 怎么算（或怎么证）？」

## 逻辑三件套

一套逻辑由三样东西构成，缺一样都不叫逻辑：

1. **语法**：哪些符号串是合法公式。02 章会看到，「公式是一棵
   归纳类型的树」这个观察直接决定了证明助手里的表示方式。
2. **证明演算**：怎么从前提**推出**结论。推是纯符号操作——不
   管意义，只管形状。03 章自然演绎、05 章 Hilbert 系统、06 章
   矢列演算是三种风格迥异的演算。
3. **语义**：公式什么时候**为真**。真不在符号里，在模型里。
   02 章真值表、13 章 Kripke 模型、15 章 Tarski 式 FOL 语义。

三件套之间有两道缝：**可靠性**（soundness：推得出的都是真的，
演算不说谎——中译本译作「合理性」）和**完备性**（completeness：
真的都推得出，演算不缺货）。缝这两道缝是全书最重的元定理，
23 章专门收账。

证明助手在这个图景里的位置：**它把三件套全部变成可执行的
程序**。语法是数据结构，演算是带类型的构造子，语义是可计算的
函数（在有限片段上）或归纳定义的谓词（在一般情形）。而内核
（kernel）扮演裁判：任何证明必须通过类型检查才算数。

## 六家谱系

本教程横跨六家证明助手。它们不是六个并列选项，而是两个家族、
两种哲学：

| 家 | 内核 | 命题层 | 默认逻辑 | 经典性来源 |
|---|---|---|---|---|
| Coq / Rocq 9.1 | 依赖类型论（CIC） | `Prop` | 构造 | 公理 `classic`（要手动 `From Stdlib Require`） |
| Agda 2.8 | 依赖类型论（MLTT 系） | `Set` 层类型 | 构造 | 只能 postulate |
| Lean 4.25 | 依赖类型论（CIC 系） | `Prop` | 构造 | `Classical.em` 是定理（靠 `Classical.choice` 公理） |
| HoTT (Rocq 9.1) | 同伦类型论 | h-level 1 截断 | 构造 | 泛等公理（不补经典） |
| Isabelle/HOL | 简单类型 + LCF 内核 | `bool` | **经典** | 内核自带（EFS 推理规则） |
| HOL4 | 简单类型 + LCF 内核 | `bool` | **经典** | 内核自带（SELECT 原则） |

两条分水岭：

1. **类型论系 vs LCF 系**：前三家+HoTT 是「命题即类型」——证明
   是程序，`Print Assumptions` / `#print axioms` 能查账（哪个定理
   依赖了哪条公理，一目了然）；后两家是「定理即 ML 值」——`thm`
   是抽象类型，定理只能由内核规则产生，经典性长在内核里，账单
   在更深处。
2. **构造默认 vs 经典默认**：同一个 ¬¬P→P，构造系证不出（要
   公理入账），经典系 `blast` 一步（零额外公理）。这不是工程
   差异，是**立场**差异：构造逻辑只承认能给出见证的真，经典
   逻辑承认排中。这条暗线从 04 章（经典原理矩阵）贯穿到
   11 章（Glivenko）和 13 章（Kripke 反例）。

## hello-logic 四连

用同一组定理摸一遍各家的脾气。选这四条不是随机的——它们
恰好排成构造性光谱：

| 定理 | 构造可证？ | 备注 |
|---|---|---|
| `(P→Q) → P → Q`（mp） | ✓ | 高阶函数应用 |
| `(P→Q) → (Q→R) → P → R` | ✓ | 复合 |
| `P → ¬¬P` | ✓ | 「不能证伪两次」白送 |
| `¬¬P → P`（哨兵） | ✗ | 经典等价物：DNE / LEM / Peirce（04 章矩阵） |

Coq 的记账现场（摘自 `examples/01_intro/ex01_intro.v`）：

```coq
Lemma mp : forall (P Q : Prop), (P -> Q) -> P -> Q.
Proof. intros P Q H HP. exact (H HP). Qed.

Lemma nn_intro : forall P : Prop, P -> ~ ~ P.
Proof. intros P HP HNP. exact (HNP HP). Qed.

Print Assumptions nn_intro.  (* Closed under the global context *)
```

`nn_intro` 的证明值得看第二眼：`~ P` 在 Coq 里**展开就是**
`P -> False`，所以 `~~P` 是 `(P -> False) -> False`——一个
「吃不掉 P 的函数」。给它一个 `HP : P`，它就能交出 `False`：
`HNP HP` 不过是函数应用。这就是构造逻辑里 ¬¬ 引入「白送」的
原因：它根本不含经典成分，只是个高阶函数。

而反方向就完全是另一回事了：

```coq
From Stdlib Require Import Classical_Prop.

Lemma nn_elim : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. apply NNPP. exact H. Qed.

Print Assumptions nn_elim.   (* 依赖 classic 公理——账本记上了 *)
```

从 `~~P` 到 `P` 需要「无中生有」：手里只有「P 不可证伪」，
却要交出 P 的**证据**。构造内核在这里卡死——没有任何组合子能
把否定翻成肯定。只有请来 `classic` 公理（排中律：任意命题或真
或假）才放行。`Print Assumptions` 把这笔账记得清清楚楚。

Lean 的账单换了个入口（`#print axioms` 报 `Classical.choice`），
Isabelle/HOL4 则根本没有账单——不是没有公理，而是公理在更深的
层（内核规则与对象逻辑的焊接处），对象逻辑层面看不见。

## 本机六通道（Windows + WSL 双机架）

| 通道 | 工具 | 判定 |
|---|---|---|
| coq | Rocq Platform 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`） | exit 0 + 无 Error |
| hott | Rocq 9.1 同二进制 + 本地 Coq-HoTT 库（597 .vo 全量构建） | 同上 |
| agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | exit 0 + 无 error/warning |
| lean | lean 4.25.0 | exit 0 + 无 error:/warning: |
| isabelle | G:\xulun3\Isabelle2025-2（自带 Cygwin，HOL heap 预构建） | isabelle build exit 0 |
| hol4 | WSL Ubuntu-26.04 ~/hol4-src（Poly/ML 5.9.2 + HOL develop 全量构建） | hol run + [OK] 标记 |

统一入口：

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量 78+ 单元
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01' # 只验本章
```

HoTT/HOL4 两个重资产的构建脚本在 `tools/build-hott.ps1` 与
`tools/build-hol4.sh`（均支持断点续编；未构建时对应通道 SKIP，
SKIP 不是失败）。

## 本章小结

- 逻辑对 CS 的第一个承诺：论证可以符号化，符号化就能机械化。
- 判断句是唯一的研究对象；论证的**结构**独立于内容。
- 暗线 M ⊨ φ：每一章都回答「M 是什么、φ 是什么、⊨ 怎么算」。
- 三件套=语法+演算+语义；两道缝=可靠+完备；证明助手把三者
  全部变成程序，内核当裁判。
- 六家分两族：类型论系（构造默认，公理可记账）与 LCF 系
  （经典长在核里）。

## 坑位速记

- Isabelle 在 Windows 走自带 Cygwin：命令行入口
  `G:\xulun3\Isabelle2025-2\contrib\cygwin\bin\bash.exe -lc '<isabelle> ...'`，
  路径用 `/cygdrive/g/...` 全形式，别指望 `G:/` 混写。
- HOL4 必须用 `hol run f.sml` 验证，**不能用 REPL 管道**
  （`hol < f.sml`）——管道模式遇未捕获异常打印后继续、退出码
  仍是 0，假绿（hol4 教程实测）。
- HoTT 库编译用自制拓扑排序脚本（`tools/build-hott.ps1`）：上游
  Makefile 是 CRLF，bash 5 直接语法错（coq-hott 教程同款坑）。
- Rocq 9.1 不收数字开头的模块名——拷贝 `ex_` 前缀再编译；
  `Require Import X` 裸写法在 9.1 起 deprecated，一律
  `From Stdlib Require Import X`（本教程 20 个 .v 单元已全量迁移，
  编译零警告之外无其他迁移成本）。
- Lean 的 `#print axioms` 对构造性定理报 "does not depend on any
  axioms"——零公理判据认准这句话。
- pwsh 调用 build.ps1 必须 `-NoProfile` 防 profile 污染；
  WSL 通道（agda/hol4）走 `wsl -d Ubuntu-26.04 bash -lc`，
  Windows 路径要换算成 `/mnt/g/...`。
