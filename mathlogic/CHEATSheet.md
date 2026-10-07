# 数理逻辑教程 CHEATSheet（六通道速查）

> 78 个验证单元沉淀的工具坑与语言坑速查。详证见各章 docs/ 的
> 坑位速记；本表按「你需要做什么」组织。

## 我要跑验证

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'            # 全量 78 单元
pwsh -NoProfile -Command '& ./build.ps1 -File ex25_hoare.v'   # 单文件
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 25_hoare'    # 单章
```

| 通道 | 入口 | 判定 |
|---|---|---|
| Rocq 9.1 | `G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`（拷 ex_ 前缀防重名；deprecated 警告容忍） | exit 0 |
| HoTT | Rocq 9.1 + `tools/build-hott.ps1`（597 .vo 断点续编） | exit 0 |
| Agda 2.8 | WSL Ubuntu-26.04，`-i /usr/share/agda-stdlib/src` | 无 error/warning |
| Lean 4.25 | bare core（无 Mathlib！） | 无 error:/warning: |
| Isabelle2025-2 | `examples/ROOT` 每章 session MLNN → isabelle build | exit 0 |
| HOL4 | WSL `~/hol4-src/bin/hol run f.sml`（**run 模式唯一可信**） | [OK] 标记 |

## 构造子头索引的归纳（while 规则五解）

| 系统 | 做法 |
|---|---|
| Coq | `remember (cwhile b c) as w eqn:Hw` + `revert` → 方程进动机；`inversion Hw` 灭不可能支 |
| Lean | 泛化命令为 w，方程进 key 引理动机；`Cmd.noConfusion hw` 灭支 |
| Isabelle | `induct "cwhile b c" s1 s2 arbitrary: HP rule: exec.induct` |
| Agda | 直接模式匹配（构造子头索引是常态） |
| HOL4 | 命令泛化 + 方程携带 + **exec_strongind**（fetch 取回） |

## 六通道高频坑（章号索引）

### Coq
- `apply (proj1 (iff…)) in H` shelve 前提 → destruct+pose proof（01）
- `destruct eqn:` 分支序=模式序（05）；会替换目标 scrutinee（15）
- lia 视 `2^S n`/`2^n` 为两原子（08）；`hd` 撞 stdlib（24）
- iff 分量显式 `.mp/.mpr`（15）；需要 `In x` 条件的 fv 条款（14）

### Lean
- **`lemma` 非关键字**、**`while` 保留字**（25）
- induction 拒构造子头索引；`with` 模式构造子字段在前 IH 在后（17/25）
- doc comment 紧邻声明（13/21）；`‹_›` 复合类型会挂死（13）
- Bool 守卫写 `decide (p)` 统一 elaboration（25）

### Agda
- with 定义函数 → 引理处 with-under-with 卡死：换 Bool-if+cong（25）
- `⌊_≟_⌋` 不做定义性归约（because 构造）：用 `_≡ᵇ_`（25）
- with 抽象函数应用留悬空约束：抽象判定本身（25）
- where 块隐式元变量组装悬空：构件提顶层（25）

### Isabelle
- 裸 `induct rule:` 对构造子头索引失败：显式实例化+arbitrary（25）
- auto 深度不够换 blast（25）；`∃x∈set` 害 eval（24）
- 引理实参按变量出现序（01）；Unicode 词法（04）

### HOL4
- hol run 下 metis 爆炸=静默中止（exit 0 无输出）（25）
- 战术位引文静态 elaboration：全类型注解救命；`!s1 s2.` 注解
  反而解析失败；绑定名撞上下文变量（25）
- REPEAT STRIP_TAC 双向（前件 ∨ 分情况、目标 ∧ 拆）（03）
- Hol_reln 3 元组；strongind/cmd_11/cmd_distinct 要 fetch（25）
- exec 反演 IMP_RES_THEN 只能一层（级联污染）（25）

### HoTT
- 无 Prelude：`Require Import HoTT.HoTT`；False_ind/Empty_rect
  双失败 → set+destruct Empty（04）；截断=丢标签读法（12）

## 语义嵌入模式（横评结论）

- **深嵌入**（本章主流）：语法自建归纳类型，语义/推导全是引理
  ——25 章的 cmd/exec/hoare 全是这个形状
- **浅嵌入**（05 章 Hilbert 示范）：宿主 Prop 当对象逻辑的
  Prop，推导规则变成定理持续器——代码量小但受限
- 布尔截面：`nat -> bool` 表示谓词（09 DPLL）vs Prop 值语义
  （02 真值表）——计算的用 bool、推理的用 Prop、桥用
  eqb/decide/Reflects（各通道桥定理速查：Coq Nat.eqb_eq /
  Lean decide_eq_true / Agda ≡ᵇ⇒≡ / Isabelle auto / HOL4 DECIDE）

## 工具层三防

1. **autocrlf**：.agda/.sh 被 CRLF 化即坏——.gitattributes 兜底
2. **PS 后台目录**：不持久，显式 cd 进 mathlogic
3. **build.ps1**：switch($true) 里 $_ 是被匹配值；/cygdrive
   路径拼接 Substring(2)


## 27-34 章新坑（H&R 全谱扩充）

### Coq（Rocq 9.1）

- 否定进归纳谓词（27 章 lsat）→ 非严格正性——语义改**公式结构
  Fixpoint**（递归在子公式，位置不动）
- Notation 定义的总公式**不能 unfold**——`Cannot coerce to an
  evaluable reference`（29 章 EFP）；全走 simpl
- F 见证的 destruct 是对 `(∃j, ≤ ∧ …)`——`[j [_ Hj]]` 两层
  拆（29 章）
- `discriminate` 裸调不收「假等式目标」（0 = 2）——要
  `discriminate H` 或 lia（29 章）
- `apply Htr with (y := v)` 的隐式 unify 岔开——全参显式
  `apply (Htr w v u)`（32 章）
- 探针赋值的双 eqb match：`Nat.eqb_neq` 的 proj2 提供
  `(v =? w) = false`，外层 match 对 false 直接 iota（32 章）
- 迭代同构引理不能 reflexivity——两个 Fixpoint 对**轮次归纳**
  （34 章）
- `F [] = B` 的种子步：app_nil_r 前先 unfold unionL（34 章）

### Lean（bare core）

- `cases h : starve k` 目标含 starve (k+1) 报 free variables
  ——**generalize hs : starve k = s** 先抽象（28 章）
- `decide` 只收闭目标；含自由变量的成员判定换 simp 方程引理
  （28 章）
- `Nat × Nat × Nat` 是**右嵌套**（Coq 左嵌套相反）——投影
  s.1 / s.2.1 / s.2.2（28 章）
- `simp [模型] at hs` 常把成员命题收成**单个反向等式**——
  `first | exact hs | exact hs.symm` 直收（29 章）
- 列表字面量是**逗号**不是分号（29 章）
- 守卫三连坑：`(s x == 0) = false` 是 Prop；`!(s x == 0)`
  elaborate 成 `!decide …`；正解 `decide (s x ≠ 0)` +
  `of_decide_eq_true`（30 章）
- `Nat.eqb_neq` 不存在——`cases hb : Nat.beq …` + `Nat.beq_eq`
  手工组装（32 章）
- match 表达式内**不用 end**（32 章 T_converse 的探针赋值）
- `by_contra` 非 core——`by_cases h : P` 替代（32 章）

### Isabelle

- exec 的 inductive 规则默认入 intro 集——blast/auto/force 在
  含 exec 的目标沿 eWhileT **无限展开**（600s+ 假死）——纪律：
  exec 目标一律 **metis**（只吃给定事实）或定向 rule（30 章）
- `of` 属性按命题**首次出现序**（15 章坑在 total correctness
  的 V 前缀上复现——30 章）
- 四层闭合括号少一层 = cwhile 第三参数（错误 `at ""` 的真义）
- 会话级 sqlite 冲突：中断后必须删 ML30.db 再 build（30 章）

## 中译本术语对照（哈斯/瑞安版）

| 英文（2e） | 中译本 | 教程现行 |
|---|---|---|
| soundness | 合理性 | 可靠性 |
| semantic entailment | 语义推导 | 语义蕴含 |
| model checking | 模型检测 | 模型检查 |
| proof tableaux | 证明布景 | 竖式证明表 |
| minimal-sum section | 最小和截段 | 最小和段 |
| programming by contract | 合同编程 | 契约式设计 |
| modal logics and agents | 模态逻辑与代理 | 模态逻辑与主体 |
| binary decision diagrams | 二叉判定图 | 二叉决策图 |
| reduced OBDD | 简约 OBDD | 约简 OBDD |
| declarative sentences | 判断语句 | 判断/宣言句 |
| substitution | 代换 | 代入 |
