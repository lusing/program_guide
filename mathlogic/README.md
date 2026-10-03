# 数理逻辑指南（mathlogic）：从命题到不完备性

面向**会编程、想系统学数理逻辑**的读者。以八本读本为骨架
（Huth&Ryan、Ben-Ari 3e、Mints、EFT、Mendelson 等详见
[PLAN.md](./PLAN.md)），横跨 **Coq / Agda / Lean 4 / Isabelle/HOL /
HOL4 / Coq-HoTT** 六种实现机器验证。

**施工中**：01–13 章已交付（全部通道绿）；总蓝图 26 章见
[PLAN.md](./PLAN.md) 的章节表。

> 核心理念：**逻辑 = 语法 + 证明演算 + 语义**，而证明助手把三者
> 全部变成可执行的程序。全书四条暗线：构造/经典的账本对照、
> 「演算作为数据」的元定理证法、语义与证毕之缝（可靠/完备）、
> 深浅两种嵌入。

## 目录结构

```text
mathlogic/
├── README.md / PLAN.md / build.ps1 / CHEATSheet.md(终章交付)
├── docs/               分章文档（每章末坑位速记）
├── examples/           章号=示例号；examples/ROOT 为 Isabelle 会话表
└── tools/              HoTT/HOL4 全量构建脚本（断点续编）
```

## 已交付章节

| 章 | 主题 | 通道 |
|---|---|---|
| [01 全景](docs/01-intro.md) | 六家谱系 + hello-logic + 账本 | C/A/L/I |
| [02 命题语义](docs/02-propsem.md) | 蛮力判定器双向可靠 + 一致性引理 | C/A/L/I |
| [03 自然演绎 NJp](docs/03-njp.md) | 规则即程序；HOL4 首秀五连坑 | C/A/L/I/H4 |
| [04 经典加成](docs/04-classical.md) | 五原理等价矩阵零公理；HoTT 首秀 | C/A/L/I/H4/T |
| [05 Hilbert 系统](docs/05-hilbert.md) | 推导归纳证演绎定理；深浅嵌入 | C/A/L/I/H4 |
| [06 矢列演算 G](docs/06-sequent.md) | 九规则 + 可靠性旗舰（零公理） | C/A/L/I |
| [07 语义表列](docs/07-tableau.md) | fuel 化搜索 + **三定理链**（sound/complete/decides，零公理） | C/L |
| [08 范式](docs/08-cnf.md) | NNF/CNF 保语义；Agda case-tree 互卡边界实录 | C/A/L |
| [09 DPLL](docs/09-dpll.md) | upd 复合装配模型；三定理零公理 | C/L/I |
| [10 BDD](docs/10-bdd.md) | apply/mk 编译保语义；树形 vs DAG 现场实录 | C/L |
| [11 Glivenko 现象](docs/11-glivenko.md) | 经典原理 ¬¬ 化全部直觉可证（零公理四通道） | C/A/L/T |
| [12 Curry–Howard](docs/12-ch.md) | 闭值 canonical forms + 析取性质（零公理四通道） | C/A/L/T |
| [13 Kripke 语义](docs/13-kripke.md) | 两世界 LEM 反例（零公理三通道） | C/A/L |

## 工具链（本机实测）

| 通道 | 工具 | 判定 |
|---|---|---|
| Coq | coqc 8.20.1 | exit 0 + 无 Error |
| HoTT | Rocq 9.1 + 本地 Coq-HoTT（597 .vo 全量构建） | 同上 |
| Agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | 无 error/warning |
| Lean | lean 4.25.0 | 无 error:/warning: |
| Isabelle | Isabelle2025-2（Windows 自带 Cygwin，HOL heap 预构建） | build exit 0 |
| HOL4 | WSL ~/hol4-src（Poly/ML 5.9.2 源码全量构建 9m52s） | hol run + [OK] |

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

## 已知边界（诚实清单）

- 可靠性/演绎定理类元定理：Coq 通道最完整（06 章九规则归纳）；
  Lean/Agda/Isabelle 相应章节立演算与示例，完整归纳证明按章注记。
- HOL4 采用浅嵌入（05 章对照点）；深嵌入的元定理工程不在本书范围。
- 中译本 Huth&Ryan 是扫描件（引用时以英文 2e 为准）；
  Mints 书公式层缺失（引用需按页核对版面）。
- 其他版本（Coq 9/Agda 3/Lean 4.3x）未测。
