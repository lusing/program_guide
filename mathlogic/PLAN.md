# mathlogic 教程总计划（八书为纲 × 六证明助手）

> 状态：01–06 章已交付（四个 commit）。本文件是全项目的施工蓝图，
> 供后续会话续接——每完成一章更新一次「已交付」标记。

## 八书定位

| 书 | 角色 |
|---|---|
| Huth & Ryan《Logic in Computer Science》2e（英文文本层好；中译本=同书 OCR 扫描） | CS 主线：ND→SAT→FOL→模型检测→霍尔逻辑→模态→BDD |
| Ben-Ari 3e（2012，文本层好；2e 为 OCR 扫描仅补充） | 演算主线：G 矢列、Hilbert H、tableau、归结/合一、SLD、验证 |
| Mints《A Short Introduction to Intuitionistic Logic》（公式层缺，需按页读版面） | 直觉主义线：NJp/NKp、Glivenko、正规化、Kripke |
| Ebbinghaus-Flum-Thomas (EFT) 3e | 元理论线：矢列、完备性、L-S、不可判定、Lindström |
| Mendelson 6e | Hilbert 系统与元定理线：L 系统、完备性 2.7、形式算术 S、递归函数 |
| 《Advances in Natural Deduction》（Prawitz 纪念文集） | 证明论进阶（文档引用） |
| 贺伟《范畴论》/《高级范畴论》 | （本轮范畴论教程已用） |

## 六通道（已全部打通并实测）

| 通道 | 工具链 | 入口 | 判定 |
|---|---|---|---|
| coq | Rocq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`，原 8.20 弃用） | build.ps1 | 拷 ex_ 前缀 + exit 0 |
| agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | build.ps1 | -i stdlib，无 error/warning |
| lean | lean 4.25.0 | build.ps1 | 无 error:/warning: |
| isabelle | G:\xulun3\Isabelle2025-2（Cygwin，HOL heap 预构建） | build.ps1 → examples/ROOT 每章 session MLNN | build exit 0 |
| hol4 | WSL ~/hol4-src（Poly/ML 5.9.2 源码构建，tools/build-hol4.sh） | build.ps1（hol run + [OK] 标记） | exit 0 + [OK] + 无 uncaught |
| hott | Rocq 9.1（G:\rocq）+ 本地 Coq-HoTT 库（597 .vo，tools/build-hott.ps1） | build.ps1（`*_hott.v` 后缀路由） | exit 0 无 Error |

## 章节蓝图（26 章）

| 章 | 主题 | 通道 | 状态 |
|---|---|---|---|
| 01 | 全景与 hello-logic（六家账本） | C/A/L/I | ✅ 扩写✅ |
| 02 | 命题语义与蛮力判定器（一致性引理+双向可靠） | C/A/L/I | ✅ 扩写✅ |
| 03 | 自然演绎 NJp（规则即程序；HOL4 首秀） | C/A/L/I/H4 | ✅ 扩写✅ |
| 04 | 经典加成矩阵（六家账本对照；HoTT 首秀） | C/A/L/I/H4/T | ✅ 扩写✅ |
| 05 | Hilbert 系统与演绎定理（推导归纳的元定理范本） | C/A/L/I/H4 | ✅ 扩写✅ |
| 06 | 矢列演算 G（九规则+可靠性旗舰；G 天生经典） | C/A/L/I | ✅ 扩写✅ |
| 07 | 语义表列 tableau（fuel 化搜索+双向正确+判定程序） | C/L | ✅ 扩写✅ |
| 08 | 范式 NNF/CNF（Agda 止步 NNF——case tree 互卡实录） | C/A/L | ✅ 扩写✅ |
| 09 | DPLL 与 SAT（upd 复合装配模型；三定理零公理；Isabelle 边界实录） | C/L/I | ✅ 扩写✅ |
| 10 | BDD（深度编码+apply 三旗舰；坍缩与深度编码相克实录；树形 vs DAG） | C/L | ✅ 扩写✅ |
| 11 | Glivenko 现象（经典原理 ¬¬ 化全部直觉可证；四通道零公理） | C/A/L/T | ✅ 扩写✅ |
| 12 | Curry–Howard 与析取性质（双 canonical 零公理；截断丢标签的 HoTT 观点） | C/A/L/T | ✅ 扩写✅ |
| 13 | Kripke 语义（两世界 LEM 反例零公理；DNE 空真认知修正） | C/A/L | ✅ 扩写✅ |
| 14 | FOL 语法与代入（fv 条款含 In x 条件教训；同型不挡混淆实录） | C/A/L | ✅ 扩写✅ |
| 15 | FOL 语义（一致性+完整代入交换+locale/结构理论） | C/A/L/I | ✅ 扩写✅ |
| 16 | FOL 自然演绎（Drinker 悖论三旗舰；Agda 构造边界实录） | C/A/L/I/H4 | ✅ 扩写✅ |
| 17 | FOL Hilbert 与 Gen 侧条件演绎定理（GenMove 公理；Lean 三连坑实录） | C/L | ✅ 扩写✅ |
| 18 | 前束范式构件（量词穿越四条零公理；侧条件不对称实录） | C/L | ✅ 扩写✅ |
| 19 | 合一与归结（occurs check 结构锚+归结可靠性侧条件版） | C/L/I | ✅ 扩写✅ |
| 20 | Herbrand 与 SLD（T_P 单调+头原子；Knaster-Tarski 边界） | C/L | ✅ 扩写✅ |
| 21 | 可判定性与 SMT（presburger 现场+Decidable 机器面；Church 文档） | I/L | ✅ 扩写✅ |
| 22 | 哥德尔不完备（三步证明+机器化先例索引） | 文档 | ✅ 扩写✅ |
| 23 | 完备性 Henkin（构造七步+紧致性/LS 推论+先例索引） | 文档 | ✅ 扩写✅ |
| 24 | CTL 语义+AG/EG 展开等价+不动点构件 | C/L | ✅ 扩写✅ |
| 25 | 霍尔逻辑程序验证（while 规则五通道对照+别名前提+截断减法绕行） | C/A/L/I/H4 | ✅ |
| 26 | 收官：SAT→SMT→MC→ITP 图景 + 总坑位清单 + 八书导读（+CHEATSheet） | 文档 | ✅ |

章号=示例号；`docs/NN-*.md` 每章坑位速记；ROOTS 随章追加 Isabelle session。

## 全书暗线（写作时保持呼应）

1. **构造/经典账本**：每章末 `Print Assumptions`/`#print axioms` 记账，
   LCF 两家「无账单」本身要交代；
2. **演算作为数据**：05/06 章的归纳推导 → 19 章归结 → 23 章完备性
   全是同一招「对推导/证明结构归纳」；
3. **语义与证毕的缝**：02（判定器双向）→06（G 可靠）→23（完备）；
4. **深浅嵌入**：05 章深（derives 归纳）vs HOL4 浅（DISCH 白送）。

## 已沉淀的跨章配方

- Isabelle 每章：examples/ROOT 加 `session MLNN in "NN_dir" = HOL +`；
- HOL4 脚本头：`Feedback.set_trace` 两条 + `open HolKernel boolLib bossLib Parse` +
  `new_theory "ExNN…"` + 尾部 `[OK]` 标记 + `export_theory()`；
- HoTT 文件名 `exNN_*_hott.v`；`Require Import HoTT.HoTT`（顶层无 Prelude）；
- Coq 公理记账三入口：Print Assumptions / #print axioms / Print Assumptions on klassical。
