# 数理逻辑教程 CHEATSheet（六通道速查）

> 78 个验证单元沉淀的工具坑与语言坑速查。详证见各章 docs/ 的
> 坑位速记；本表按「你需要做什么」组织。

## 我要跑验证

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'            # 全量 78 单元
pwsh -NoProfile -Command '& ./build.ps1 -File ex46_hoare.v'   # 单文件
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 46_hoare'    # 单章
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
  ——46 章的 cmd/exec/hoare 全是这个形状
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


## H&R 扩充新坑（时态·模态·符号 MC——新号 35-48）

### Coq（Rocq 9.1）

- 否定进归纳谓词（36 章 lsat）→ 非严格正性——语义改**公式结构
  Fixpoint**（递归在子公式，位置不动）
- Notation 定义的总公式**不能 unfold**——`Cannot coerce to an
  evaluable reference`（38 章 EFP）；全走 simpl
- F 见证的 destruct 是对 `(∃j, ≤ ∧ …)`——`[j [_ Hj]]` 两层
  拆（38 章）
- `discriminate` 裸调不收「假等式目标」（0 = 2）——要
  `discriminate H` 或 lia（38 章）
- `apply Htr with (y := v)` 的隐式 unify 岔开——全参显式
  `apply (Htr w v u)`（44 章）
- 探针赋值的双 eqb match：`Nat.eqb_neq` 的 proj2 提供
  `(v =? w) = false`，外层 match 对 false 直接 iota（44 章）
- 迭代同构引理不能 reflexivity——两个 Fixpoint 对**轮次归纳**
  （42 章）
- `F [] = B` 的种子步：app_nil_r 前先 unfold unionL（42 章）

### Lean（bare core）

- `cases h : starve k` 目标含 starve (k+1) 报 free variables
  ——**generalize hs : starve k = s** 先抽象（37 章）
- `decide` 只收闭目标；含自由变量的成员判定换 simp 方程引理
  （37 章）
- `Nat × Nat × Nat` 是**右嵌套**（Coq 左嵌套相反）——投影
  s.1 / s.2.1 / s.2.2（37 章）
- `simp [模型] at hs` 常把成员命题收成**单个反向等式**——
  `first | exact hs | exact hs.symm` 直收（38 章）
- 列表字面量是**逗号**不是分号（38 章）
- 守卫三连坑：`(s x == 0) = false` 是 Prop；`!(s x == 0)`
  elaborate 成 `!decide …`；正解 `decide (s x ≠ 0)` +
  `of_decide_eq_true`（47 章）
- `Nat.eqb_neq` 不存在——`cases hb : Nat.beq …` + `Nat.beq_eq`
  手工组装（44 章）
- match 表达式内**不用 end**（44 章 T_converse 的探针赋值）
- `by_contra` 非 core——`by_cases h : P` 替代（44 章）

### Isabelle

- exec 的 inductive 规则默认入 intro 集——blast/auto/force 在
  含 exec 的目标沿 eWhileT **无限展开**（600s+ 假死）——纪律：
  exec 目标一律 **metis**（只吃给定事实）或定向 rule（47 章）
- `of` 属性按命题**首次出现序**（15 章坑在 total correctness
  的 V 前缀上复现——47 章）
- 四层闭合括号少一层 = cwhile 第三参数（错误 `at ""` 的真义）
- 会话级 sqlite 冲突：中断后必须删 ML47.db 再 build（47 章）

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

## Ben-Ari 扩充新坑（新号 19/26-31/33/34/39-41/48）+ Prolog 通道

### Prolog 通道（SWI 10，本机 scoop）
- `:- encoding(utf8).` 必须是**物理首行**（前面连注释都不行，否则 UTF-8 注释按 GBK 报 Illegal multibyte）；
- 运行期输出纯 ASCII（`START/END` 标记）；`format/1` 是 SWI 简写、gprolog 无——统一 `format/2`；
- 原子名不能带撇号（`succK'` 撞引号语法）；`call(P, X, Y)` 元调用切模型；
- clpfd 要 `:- use_module(library(clpfd)).`；零子句谓词要 `:- dynamic p/2.` 否则 findall 报 Unknown procedure；
- `\+` 带自由变元 = 存在式否定——NAF 演示用定人查询（30 章）。

### 35-42 各章最重坑（详见各章速记）
- **35**：记录域参数化（`interp (D:Type)`+`Arguments iasg {D}`）；隐式 {D} 三处坑（陈述悬空/intros 吞名/IH 显式）；as 模式必须含前提槽位（`a Hp IH` 三槽）；proj1/proj2 方向反是最高频翻车；`apply` 不展开 satE 要先 unfold；Compute 探针校准期望值；
- **36**：α 优先于 β 否则指数爆炸；◇ 推迟支 `saturate k Γ' (lDia a :: next)`（Γ' 别丢）；重现检测必须集合语义（setEqL）；
- **37**：as 模式坑第三次；lsat 的 lNext 展开用 simpl/change/exact 各显神通；Exp 的 X□A 支要 `change (forall j, S k <= j -> …)` 逐 j 喂；
- **38**：Nat.mul_succ_l 匹配 `S n * m` 形（写错只报 no subterm）；◇ 相位枚举（bI 放全部可达起点）；Lean 的 Nat.add 在第二参递归（`0+b` 非定义归约）；`Nat.mul_succ_l/r` 在 core 叫 `Nat.succ_mul/mul_succ`；
- **39**：守卫先自审（turn 协议正确守卫=「轮到我」+退出交牌）；Prop 不变式优于 bool（lia 吃字段算术）；`injection Hstep; subst s'` 是每案例起手式；辅助不变式是蕴含要手 specialize；可达集的 flat_map 不能 simpl（in_flat_map 认不出）；reach_inv 泛化起点再归纳；
- **40**：Horn 子句「体变元 ⊆ 头变元」用眼睛盯（头写错=野变元+答案集错位）；答案沿链累积（`s ++ acc`）+换名链追踪（chaseX）；unifyL 双表递归改累积式；Lean 的 `Sub` 撞核心类名、`open Tm` 后裸构造子名当绑定子会撞；
- **41**：resolvent 的 C2 段消 ¬l（`removeLit (oppl l)`）；PHP(2,2) 可满足（最小不可满足鸽笼从 PHP(3,1) 起）；match-only 函数写 Fixpoint 则 existsb 引理全 apply 不上（non-recursive 警告是线索）；existsb_exists 合取序 In 在前；iff 嵌在 `||` 下触发 setoid——先 `apply (proj2 (orb_true_iff _ _))`；Lean 的 Bool cases 顺序 false 在前；
- **42**：赋值变换器两层混淆（`CAssn (fun s => upd 0 (s 0-1) s)` 才对）；守卫里的绑定子挡 rewrite（unfold+simpl 先行）；fuel 算术要用真算术（lia 报 Cannot find witness 先查自己）；状态序不可颠倒（B 在 A 之上）；exists 形态优于 match 形态（exact 吃定义等价）；Lean 的 `while/skip/seq` 全是关键字（构造子加 c 前缀）；`Nat.eqb_refl` 不在裸 core；`replace X = Y by omega` 不存在（用 have+rw）。

### 中译本/2e 取材注记
- 2e OCR 公式区不可靠——公式一律以 3e 文本层为准；2e 仅取 §8.3（cut/NAF/CWA 叙述）与 §8.5（CLP 概念）；Z 记号章跳过（裁决）；
- 3e 页偏移（PDF=书页+Δ，Δ 按章 6-13 跳变——数字版删了章间空白页）：提取时按章实测。

## Jongsma 扩充新坑（离散底座——新号 49-57）

**数学先于战术**（三连：43/49/51）——目标为假时 lia 的
"Cannot find witness" 是**正确判断**：55 章 `2*2 ≤ (k₁'+1)(k₂'+1)`
不真（应证乘积=1）；57 章 filter 口径的度数引理在自环 (v,v)
上是假命题（改多重图递归口径后成定义方程）。写证明前先验算。

**PDF 文本层丢上杠**（50）——§7.3 命题的补运算排印在提取文本
中全部裸奔：共识律照抄是假命题（中间项必须 x̄）、冗余律
x(x̅+y)=xy 同病。处方：涉及补的公式按数学实体校读，机器是
唯一裁判。

**Coq**：`Nat.mul_cancel_l/r` 是 iff 且非零因子在第三参（45/48/49
三连坑）；`rw` 对含自由字母的项全局改写会自我指涉爆炸（45 的
gcdn——remember/反向 rw/congrArg 三解）；min/max 这类条件定义
暴力 destruct 后化简失灵——**特征引理装配范式**（49 四条
big/sml + assert + rewrite）；`le_lt_dec` 右支是 `<` 要 `≤` 时
用 `ltac:(lia)` 作实参；`destruct … eqn:E` 已替换 scrutinee、
勿再 `rewrite E`；iff 引理用 `proj1/proj2` 解包；`filter_In`
只用于成员关系，等式造成员用 `rewrite F; left; reflexivity`；
自定义折叠（lsum）保持**折叠形纪律**——`lsum_cons` 引理 +
`cbn [map]` 白名单，绝不全 simpl（51 的 IH 失配连坑）。

**Lean 4.25 裸 core 件名录**：`Nat.leb`/`Nat.leb_le`/`Nat.decide`
不存在——布尔比较改 Prop 级 `if x ≤ y` + `if_pos`/`if_neg`
（负分支侧条件从三叉来）；`Bool.or_false/false_or/not_true/
not_false/true_and/false_and/and_true/and_false` 全家可用；
`Bool.xor` 全名是根名 `xor`；`List.mem_cons_self` 全隐参裸名
即完整应用；`.lsum` 式点语法不存在（找 List.lsum）。

**Lean omega 三律**：无非线性字面量因子的假设**被静默丢弃**
→先纯等式链蒸馏成线性（49 的 hLin：Nat.succ_mul 展开须 have
显式类型钉 `+1` 拼法）；直证**合取目标**拉 Classical.choice
→拆单目标；面对**非算术目标**也拉 choice→`(by omega : False).elim`。

**Lean term/match**：term 级 match 的臂是项不是 tactic（50 djn
规格件）；变量等式 `x = 0` 不能 rfl——用见证 `p.1`；系数写在
minterm 右侧（&&/|| 从左匹配，字面量在左死项才先归零），
dnf2 的 or 链卡在不透明应用处→全 `simp [lit]` 一发收；`show`
对 ≠-合取目标失灵（单边 rfl 可证也不行）→先证 rfl 步进引理
再 `rw`（51 的 greedy_step）。

**Lean stdlib 公理传递**：`List.erase` 引理族自带
`Classical.choice`（51 鸽笼的 pick_notin 及下游账本显式记账；
自证区间鸽笼撞加法性墙——拆两段各自 ≤ |L| 推不出和 ≤ |L|，
需区间表强化归纳）。

**Prolog**：QMC 合并参与者须**双向采集**（`U @< V` 单向让最大
模式 111 漏网成假素蕴涵项）；着色约束须**累积器**——边建表边
`\+ member(·, As)` 时尾部未绑定、否定全灭；K3,3 **有** Ham 圈
（平衡 3=3），反例是 K3,4（3≠4）——书 Ex 8.2.17 判据两侧各
有机型，勿张冠李戴。
