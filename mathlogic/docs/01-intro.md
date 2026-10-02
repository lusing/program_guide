# 01 全景：数理逻辑 × 证明助手

> 对书：Huth&Ryan §1.1-1.2 / Ben-Ari 3e Ch1-2 / Mints §2.2 / EFT I / Mendelson §1.1

逻辑的三件套——**语法**（公式怎么写）、**证明演算**（公式怎么推）、
**语义**（公式什么时候为真）——本章先把六家证明助手放到这张地图上，
再用同一组定理（mp、蕴涵传递、¬¬引入、经典哨兵 ¬¬P→P）摸一遍各家的脾气。

## 六家谱系

| 家 | 内核 | 命题层 | 默认逻辑 | 经典性来源 |
|---|---|---|---|---|
| Coq 8.20 | 依赖类型论（CIC） | `Prop` | 构造 | 公理 `classic`（要手动 `Require`） |
| Agda 2.8 | 依赖类型论（MLTT 系） | `Set` 层类型 | 构造 | 只能 postulate |
| Lean 4.25 | 依赖类型论（CIC 系） | `Prop` | 构造 | `Classical.em` 是定理（靠 `Classical.choice` 公理） |
| HoTT (Rocq 9.1) | 同伦类型论 | h-level 1 截断 | 构造 | 泛等公理（不补经典） |
| Isabelle/HOL | 简单类型 + LCF 内核 | `bool` | **经典** | 内核自带（EFS 推理规则） |
| HOL4 | 简单类型 + LCF 内核 | `bool` | **经典** | 内核自带（SELECT 原则） |

两条分水岭：

1. **类型论系 vs LCF 系**：前三家+HoTT 是「命题即类型」——证明是程序，
   `Print Assumptions` / `#print axioms` 能查账；后两家是「定理即 ML 值」——
   定理只能由内核规则产生，经典性长在内核里。
2. **构造默认 vs 经典默认**：同一个 ¬¬P→P，构造系证不出（要公理入账），
   经典系 `blast` 一步（零额外公理）。这是贯穿全书的暗线。

## hello-logic 四连

| 定理 | 构造可证？ | 备注 |
|---|---|---|
| `(P→Q) → P → Q`（mp） | ✓ | 高阶函数应用 |
| `(P→Q) → (Q→R) → P → R` | ✓ | 复合 |
| `P → ¬¬P` | ✓ | 「不能证伪两次」白送 |
| `¬¬P → P`（哨兵） | ✗ | 经典等价物：DNE / LEM / Peirce（04 章矩阵） |

Coq 的记账现场（`Print Assumptions`）：

```coq
Lemma nn_intro : forall P : Prop, P -> ~ ~ P.
Proof. intros P HP HNP. exact (HNP HP). Qed.
Print Assumptions nn_intro.   (* Closed under the global context *)

Require Import Classical_Prop.
Lemma nn_elim : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. apply NNPP. exact H. Qed.
Print Assumptions nn_elim.   (* 依赖 classic 公理 *)
```

Lean 的账单换了个入口（`#print axioms`），Isabelle/HOL4 则根本没有账单——
不是没有公理，而是公理在更深的层（内核规则与对象逻辑的焊接处）。

## 本机六通道（Windows + WSL 双机架）

| 通道 | 工具 | 判定 |
|---|---|---|
| coq | coqc 8.20.1 | exit 0 + 无 Error |
| hott | Rocq Platform 9.1 + 本地 Coq-HoTT 库（597 .vo 全量构建） | 同上 |
| agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | exit 0 + 无 error/warning |
| lean | lean 4.25.0 | exit 0 + 无 error:/warning: |
| isabelle | G:\xulun3\Isabelle2025-2（自带 Cygwin，HOL heap 预构建） | isabelle build exit 0 |
| hol4 | WSL Ubuntu-26.04 ~/hol4-src（Poly/ML 5.9.2 + HOL develop 全量构建） | hol run + [OK] 标记 |

构建脚本在 `tools/build-hott.ps1` 与 `tools/build-hol4.sh`（断点续编）。

## 坑位速记

- Isabelle 在 Windows 走自带 Cygwin：命令行入口
  `G:\xulun3\Isabelle2025-2\contrib\cygwin\bin\bash.exe -lc '<isabelle> ...'`，
  路径用 `/cygdrive/g/...` 全形式，别指望 `G:/` 混写。
- HOL4 必须用 `hol run f.sml` 验证，**不能用 REPL 管道**（`hol < f.sml`）——
  管道模式遇未捕获异常打印后继续、退出码仍是 0，假绿（hol4 教程实测）。
- HoTT 库编译用自制拓扑排序脚本（`tools/build-hott.ps1`）：上游 Makefile
  是 CRLF，bash 5 直接语法错（coq-hott 教程同款坑）。
- Coq 8.20 不收数字开头的模块名——拷贝 `ex_` 前缀再编译（沿用 category 配方）。
- Lean 的 `#print axioms` 对构造性定理报 "does not depend on any axioms"——
  零公理判据认准这句话。
