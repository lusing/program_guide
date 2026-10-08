# 数理逻辑教程 CHEATSheet（六通道速查）

> 78 个验证单元沉淀的工具坑与语言坑速查。详证见各章 docs/ 的
> 坑位速记；本表按「你需要做什么」组织。

## 我要跑验证

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'            # 全量 78 单元
pwsh -NoProfile -Command '& ./build.ps1 -File ex50_hoare.v'   # 单文件
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 50_hoare'    # 单章
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
  ——50 章的 cmd/exec/hoare 全是这个形状
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


## H&R 扩充新坑（时态·模态·符号 MC——新号 39-49）

### Coq（Rocq 9.1）

- 否定进归纳谓词（40 章 lsat）→ 非严格正性——语义改**公式结构
  Fixpoint**（递归在子公式，位置不动）
- Notation 定义的总公式**不能 unfold**——`Cannot coerce to an
  evaluable reference`（42 章 EFP）；全走 simpl
- F 见证的 destruct 是对 `(∃j, ≤ ∧ …)`——`[j [_ Hj]]` 两层
  拆（42 章）
- `discriminate` 裸调不收「假等式目标」（0 = 2）——要
  `discriminate H` 或 lia（42 章）
- `apply Htr with (y := v)` 的隐式 unify 岔开——全参显式
  `apply (Htr w v u)`（48 章）
- 探针赋值的双 eqb match：`Nat.eqb_neq` 的 proj2 提供
  `(v =? w) = false`，外层 match 对 false 直接 iota（48 章）
- 迭代同构引理不能 reflexivity——两个 Fixpoint 对**轮次归纳**
  （46 章）
- `F [] = B` 的种子步：app_nil_r 前先 unfold unionL（46 章）

### Lean（bare core）

- `cases h : starve k` 目标含 starve (k+1) 报 free variables
  ——**generalize hs : starve k = s** 先抽象（41 章）
- `decide` 只收闭目标；含自由变量的成员判定换 simp 方程引理
  （41 章）
- `Nat × Nat × Nat` 是**右嵌套**（Coq 左嵌套相反）——投影
  s.1 / s.2.1 / s.2.2（41 章）
- `simp [模型] at hs` 常把成员命题收成**单个反向等式**——
  `first | exact hs | exact hs.symm` 直收（42 章）
- 列表字面量是**逗号**不是分号（42 章）
- 守卫三连坑：`(s x == 0) = false` 是 Prop；`!(s x == 0)`
  elaborate 成 `!decide …`；正解 `decide (s x ≠ 0)` +
  `of_decide_eq_true`（51 章）
- `Nat.eqb_neq` 不存在——`cases hb : Nat.beq …` + `Nat.beq_eq`
  手工组装（48 章）
- match 表达式内**不用 end**（48 章 T_converse 的探针赋值）
- `by_contra` 非 core——`by_cases h : P` 替代（48 章）

### Isabelle

- exec 的 inductive 规则默认入 intro 集——blast/auto/force 在
  含 exec 的目标沿 eWhileT **无限展开**（600s+ 假死）——纪律：
  exec 目标一律 **metis**（只吃给定事实）或定向 rule（51 章）
- `of` 属性按命题**首次出现序**（16 章坑在 total correctness
  的 V 前缀上复现——51 章）
- 四层闭合括号少一层 = cwhile 第三参数（错误 `at ""` 的真义）
- 会话级 sqlite 冲突：中断后必须删 ML51.db 再 build（51 章）

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

## Ben-Ari 扩充新坑（新号 20/27-32/37-38/43-45/52）+ Prolog 通道

### Prolog 通道（SWI 10，本机 scoop）
- `:- encoding(utf8).` 必须是**物理首行**（前面连注释都不行，否则 UTF-8 注释按 GBK 报 Illegal multibyte）；
- 运行期输出纯 ASCII（`START/END` 标记）；`format/1` 是 SWI 简写、gprolog 无——统一 `format/2`；
- 原子名不能带撇号（`succK'` 撞引号语法）；`call(P, X, Y)` 元调用切模型；
- clpfd 要 `:- use_module(library(clpfd)).`；零子句谓词要 `:- dynamic p/2.` 否则 findall 报 Unknown procedure；
- `\+` 带自由变元 = 存在式否定——NAF 演示用定人查询（31 章）。

### Ben-Ari 八章最重坑（新号 20/29/31/32/43-45/52，详见各章速记）
- **20**：记录域参数化（`interp (D:Type)`+`Arguments iasg {D}`）；隐式 {D} 三处坑（陈述悬空/intros 吞名/IH 显式）；as 模式必须含前提槽位（`a Hp IH` 三槽）；proj1/proj2 方向反是最高频翻车；`apply` 不展开 satE 要先 unfold；Compute 探针校准期望值；
- **43**：α 优先于 β 否则指数爆炸；◇ 推迟支 `saturate k Γ' (lDia a :: next)`（Γ' 别丢）；重现检测必须集合语义（setEqL）；
- **44**：as 模式坑第三次；lsat 的 lNext 展开用 simpl/change/exact 各显神通；Exp 的 X□A 支要 `change (forall j, S k <= j -> …)` 逐 j 喂；
- **45**：Nat.mul_succ_l 匹配 `S n * m` 形（写错只报 no subterm）；◇ 相位枚举（bI 放全部可达起点）；Lean 的 Nat.add 在第二参递归（`0+b` 非定义归约）；`Nat.mul_succ_l/r` 在 core 叫 `Nat.succ_mul/mul_succ`；
- **52**：守卫先自审（turn 协议正确守卫=「轮到我」+退出交牌）；Prop 不变式优于 bool（lia 吃字段算术）；`injection Hstep; subst s'` 是每案例起手式；辅助不变式是蕴含要手 specialize；可达集的 flat_map 不能 simpl（in_flat_map 认不出）；reach_inv 泛化起点再归纳；
- **31**：Horn 子句「体变元 ⊆ 头变元」用眼睛盯（头写错=野变元+答案集错位）；答案沿链累积（`s ++ acc`）+换名链追踪（chaseX）；unifyL 双表递归改累积式；Lean 的 `Sub` 撞核心类名、`open Tm` 后裸构造子名当绑定子会撞；
- **29**：resolvent 的 C2 段消 ¬l（`removeLit (oppl l)`）；PHP(2,2) 可满足（最小不可满足鸽笼从 PHP(3,1) 起）；match-only 函数写 Fixpoint 则 existsb 引理全 apply 不上（non-recursive 警告是线索）；existsb_exists 合取序 In 在前；iff 嵌在 `||` 下触发 setoid——先 `apply (proj2 (orb_true_iff _ _))`；Lean 的 Bool cases 顺序 false 在前；
- **32**：赋值变换器两层混淆（`CAssn (fun s => upd 0 (s 0-1) s)` 才对）；守卫里的绑定子挡 rewrite（unfold+simpl 先行）；fuel 算术要用真算术（lia 报 Cannot find witness 先查自己）；状态序不可颠倒（B 在 A 之上）；exists 形态优于 match 形态（exact 吃定义等价）；Lean 的 `while/skip/seq` 全是关键字（构造子加 c 前缀）；`Nat.eqb_refl` 不在裸 core；`replace X = Y by omega` 不存在（用 have+rw）。

### 中译本/2e 取材注记
- 2e OCR 公式区不可靠——公式一律以 3e 文本层为准；2e 仅取 §8.3（cut/NAF/CWA 叙述）与 §8.5（CLP 概念）；Z 记号章跳过（裁决）；
- 3e 页偏移（PDF=书页+Δ，Δ 按章 6-13 跳变——数字版删了章间空白页）：提取时按章实测。

## Jongsma 扩充新坑（离散底座——新号 53-61）

**数学先于战术**（三连：53/55/61）——目标为假时 lia 的
"Cannot find witness" 是**正确判断**：55 章 `2*2 ≤ (k₁'+1)(k₂'+1)`
不真（应证乘积=1）；61 章 filter 口径的度数引理在自环 (v,v)
上是假命题（改多重图递归口径后成定义方程）。写证明前先验算。

**PDF 文本层丢上杠**（50）——§7.3 命题的补运算排印在提取文本
中全部裸奔：共识律照抄是假命题（中间项必须 x̄）、冗余律
x(x̅+y)=xy 同病。处方：涉及补的公式按数学实体校读，机器是
唯一裁判。

**Coq**：`Nat.mul_cancel_l/r` 是 iff 且非零因子在第三参（55/58/59
三连坑）；`rw` 对含自由字母的项全局改写会自我指涉爆炸（55 的
gcdn——remember/反向 rw/congrArg 三解）；min/max 这类条件定义
暴力 destruct 后化简失灵——**特征引理装配范式**（59 四条
big/sml + assert + rewrite）；`le_lt_dec` 右支是 `<` 要 `≤` 时
用 `ltac:(lia)` 作实参；`destruct … eqn:E` 已替换 scrutinee、
勿再 `rewrite E`；iff 引理用 `proj1/proj2` 解包；`filter_In`
只用于成员关系，等式造成员用 `rewrite F; left; reflexivity`；
自定义折叠（lsum）保持**折叠形纪律**——`lsum_cons` 引理 +
`cbn [map]` 白名单，绝不全 simpl（61 的 IH 失配连坑）。

**Lean 4.25 裸 core 件名录**：`Nat.leb`/`Nat.leb_le`/`Nat.decide`
不存在——布尔比较改 Prop 级 `if x ≤ y` + `if_pos`/`if_neg`
（负分支侧条件从三叉来）；`Bool.or_false/false_or/not_true/
not_false/true_and/false_and/and_true/and_false` 全家可用；
`Bool.xor` 全名是根名 `xor`；`List.mem_cons_self` 全隐参裸名
即完整应用；`.lsum` 式点语法不存在（找 List.lsum）。

**Lean omega 三律**：无非线性字面量因子的假设**被静默丢弃**
→先纯等式链蒸馏成线性（59 的 hLin：Nat.succ_mul 展开须 have
显式类型钉 `+1` 拼法）；直证**合取目标**拉 Classical.choice
→拆单目标；面对**非算术目标**也拉 choice→`(by omega : False).elim`。

**Lean term/match**：term 级 match 的臂是项不是 tactic（60 djn
规格件）；变量等式 `x = 0` 不能 rfl——用见证 `p.1`；系数写在
minterm 右侧（&&/|| 从左匹配，字面量在左死项才先归零），
dnf2 的 or 链卡在不透明应用处→全 `simp [lit]` 一发收；`show`
对 ≠-合取目标失灵（单边 rfl 可证也不行）→先证 rfl 步进引理
再 `rw`（61 的 greedy_step）。

**Lean stdlib 公理传递**：`List.erase` 引理族自带
`Classical.choice`（61 鸽笼的 pick_notin 及下游账本显式记账；
自证区间鸽笼撞加法性墙——拆两段各自 ≤ |L| 推不出和 ≤ |L|，
需区间表强化归纳）。

**Prolog**：QMC 合并参与者须**双向采集**（`U @< V` 单向让最大
模式 111 漏网成假素蕴涵项）；着色约束须**累积器**——边建表边
`\+ member(·, As)` 时尾部未绑定、否定全灭；K3,3 **有** Ham 圈
（平衡 3=3），反例是 K3,4（3≠4）——书 Ex 8.2.17 判据两侧各
有机型，勿张冠李戴。

## 21-26/30/33 章新坑（EFT 扩充全谱）

- **Lean native_decide 救 reflexivity/decide**：解释表用深 `match s, args`
  写的有限结构求值，`by rfl`/`by decide` 卡在 Decidable 实例归约
  （依赖 elim 阻塞）——`by native_decide`（编译 IR）一次全过。
- **嵌套递归第三/四次撞墙**：通用词项化简翻译器、tm_eqb 结构相等
  ——同 substt 病（fsym 挂 list tm）；示例手工内联 / 原子用 rat i []
  化身避开相等判定。
- **Bool 等值**：Coq 用 `Bool.eqb`（=? 是 nat 专用）；Lean 用 `==`。
- **对账要双向**：翻译保真验一真一假两例——假方向恰好证明没丢/没引
  入信息。
- （21 章其余坑见上节：嵌套归纳无 IH、Lean 符号项 defeq 卡死、conj
  遮蔽、∃A 新鲜性 compute、账本 choice 对照。）
- **25 章新坑**（前文已录，此处归并索引）：forall 条件合取=∀。
- **33 章新坑**：燃料预算不足（P₀ 需 3n+20——首版 n+10 被拒）；
  HALT 检测=pc 不动（注意自跳 rife r 0 0 也不停）；Prolog 变量名带
  撇号与全角注释组合解析炸（统一 Cfg2）；Example 的 kernel 归约比
  Compute 慢一个量级（对账数值小则无碍）。
- **30 章新坑**：泛性质首版少生成元约定（无条件唯一是假命题——
  机器拒证即抓包）；Lean `a = b && c` 解析成 `(a = b) && c`（= 级
  50 高于 && 35——布尔等式 RHS 必加括号）；foldr 累加器交换自证
  （核心库不带）；Coq andb 族在 Stdlib.Bool。
- **26 章新坑**：连通式平凡满足（正向 ∃ 全关系——必须否定式）；
  chain 边写漏（结构自检先于断言）；函词混关系（fid 无解释——改
  S(x,y) 关系式）；Lean 公式上 ! 不可用（iff 用 conj/imp 组合）；
  嵌套 conj 括号连错四次（单行参数+程序平衡检查收场）。
- **25 章新坑**：手推让位于穷举（Z₂/Z₃ 分离轮数手推 3 实为 2——
  以机器真值修断言）；Prolog forall 条件合取=∀、动作合取才是 ∃
  （回溯供存在量词——胜负全反的源头）；负结果 if-else 标签易反；
  规模×轮数组合防爆（8 元×5 轮≈百万叶）。
- **24 章新坑**：数学先于战术×2（有限线序永不稠密——机器拒证是
  对的；「不可有限公理化」的对象是有限性而非 DLO）；空真陷阱（稠密
  在单点域空真，穷举从 n≥2 起）；σₙ 嵌套括号程序生成；Lean 草稿
  sorry/where 残留要清。
- **23 章新坑**：嵌套结构相等 mutual/fuel/list-外层三连拒（fuel 单
  Fixpoint 收）；合同闭包两炸（无界 f-提升→T4 截断；重复项→每轮
  dedup）；canon 须统一次序+自反闭包；Lean 严格正定性拒高阶辅助谓词
  （cong 内联 cong0/congS）；求值器 neg 穿透明量词会算错。

- **Coq 嵌套归纳无元素 IH**：`fsym f (list tm)` 的 list 参数不给逐元素假设——
  tsize 测度归纳；fold_right 是 lia 黑盒原子，配 fr_pos 正性引理。
- **Lean 嵌套归纳类型禁 induction**：含 List 字段的归纳类型无递归子；
  测度归纳；内层 induction ts 自动泛化依赖假设（ht 进 IH）——
  map_self_gen（元素级假设做参数）绕开。
- **Lean 符号项上 defeq 卡死**：substf 计算形 vs 手写形在符号 t 上不合——
  `have h := d_all_inst …; simpa [substf, substt, mul, eg, List.map_cons,
  List.map_nil] using h`（tactic 归一化再 rfl）；decide 卡 Decidable 实例。
- **Coq 名字遮蔽**：自定义 `conj`（fm 缩写）遮蔽 stdlib 合取构造子——
  tactic 级 split 造见证（mkcomp 模式）。
- **∃A 侧条件新鲜性**：具体公式 vm_compute（Coq）/全定义 simp（Lean）。
- **账本对照**：同一群例 Coq 零公理 vs Lean [propext, Classical.choice,
  Quot.sound]（by_cases 经典分叉）。

## 09/34/35/36/37/62 章新坑（Mendelson 扩充）

### 09 章 完备集与公理独立性（C/L）
- **↓ 是 NOR 不是 NAND**：joint denial 的 `upeval` 首版写成 `negb (andb …)`
  被 conj 案反例当场抓包——先读原句（neither…nor）再写求值器；
- **nat destruct 两案陷阱**：值 2 落在任意后继分支、表匹配卡死——
  Coq 三层 `as [|[|?]]`、Lean 27 行 `match | 0,0,0 => rfl | b+2,… => rfl`
  查表；**unfold 递归常量变裸 fix** 导致 destruct 匹配落空——让 simpl
  做 iota、只 unfold 定义型常量（ev1）；
- **destruct 不穿透未展开目标**（`beval (imp B C) s` 里看不见
  `beval B s`）：先 simpl 暴露；rw ← h 全量替换 true 的风险改 have+rw；
- **一致性陈述**：`∀f,(∀b,=b)∨(∀b,=¬b)` 才推得常真不可定义——逐点
  弱陈述归纳也闭但推论断链；
- Lean：`split with h` 不收（用 split+next）；`cases h : s n` 已替换目标
  则后续 rw 删 hsn；simp 可能提前闭合（first | rfl | cases 兜底）；
- 账本：Coq 全章零公理 vs Lean shannon_ok [propext, Quot.sound]——
  差异全在 tactic 层。

### 34 章 图灵机（C/L/P）
- **Tadd 首版只擦一笔**：隔板改笔净加一格，5x5 网格全体 +1 被抓——写机器前
  先算格子账（输入 (m+1)+1+(n+1) 格 vs 目标 m+n+1 笔）；
- **Lean 转换剥不动符号乘法**：`2*m+4` 燃料在 exact/rfl 转换检查里无法归约
  succ——构造子递归 `tfuel |0=>4|m+1=>succ succ` + tfuel_eq/omega 桥接；
- **run_mono 的 IH 广义化 c**（revert c 后归纳才能吃 step 的新配置）；
  Coq `unfold step at 1 2` 在 simpl 之后报 Invalid occurrence——改
  simpl+exact 靠转换检查；
- **Lean 结构字段类型**：cur 是 Nat 不是 List（cnt1 直接喂类型错）；
  Option Cfg 相等改 `.isNone = true`（Decidable 实例合成失败绕行）。

### 35 章 递归函数（C/L）
- **Lean list-comp 求值挤到良基递归**：`gs.map (fun gi => peval gi args)`
  元素递归让 peval 的 rfl/defeq 全废——改 **comp1/comp2 双构造子**回归
  结构归纳；Coq guard 反而收 list-comp（两通道分歧现场）；
- **itup 只 match 计数**：成对 match (k,r) 让 stuck 的 peval g xs 阻塞
  iota——r 作普通参数；
- **Lean succ/pred 形态**：`x+1` 非构造子（步进引理写 Nat.succ）；
  `(x+1).pred` 卡 HAdd——Nat.pred_succ / Nat.pred_eq_sub_one；
  `y - 0` 转换卡（减法递归首参）——基例 simp [peval,…,itup]；
- **(* *) 是 Coq 注释**——Lean 镜像文件用 `--`；
- **ack 的 WF 方程不能 rfl**：have h := by simp [ack] 提取后 rw。

### 36/37 章 算术化+不完备升级（C/L）
- **指数配对炸内存**：2^a·(2b+1) 两层树 Compute OOM（nat 单仁 2^145）——
  平方配对 (a+b)²+b 多项式增长、单射证只要 s²+s<(s+1)²；嵌套 cp 每层
  再平方——码值预算：Coq 样本止步 n=0（1e6 单仁 kernel 栈溢出）、
  Lean native_decide（GMP）跑 n=200；
- **omega 不碰非线性积**：平方项作原子传给全称辅助引理（纯线性）再
  omega——直接 omega 在未归一的乘积变体上失败；
- **Lean if 计算不自动**（`if (0==2)=true` 卡）——`change … at h` 走
  转换 iota；**iff 裸 apply 方向歧义**——proj1/proj2 显式；Lean
  induction 名字顺序=参数全前、IH 全后（`| imp a b iha ihb`）；
- **Bool↔Prop 桥**：not_eq_true'+absurd+Bool.noConfusion 手工搭；
  Coq destruct eqn:E 会联动重写假设（exact E 失配改按新形写）。

### 62 章 NBG 集合论（C/L）
- **`at` 撞 Coq 关键字**（rewrite … at）——构造子改名 atom；
- **map vn 未应用递归被 guard 拒**（第三次撞：09/35/62）——改**追加式**
  vn (S k) = els (vn k) ++ [vn k]+els 引桥族；vn 定义体是 match——
  一切定理走 els_vn_S 展开，别直接 simpl；
- **injection 方程数不定**：嵌套 list 一次产 1-3 条——`injection H.
  intros E1 E2 E3.` 稳妥；Lean injection 每层一构造子（[x]=[y] 再剥
  一层）——kur_char 六层链；
- **Lean ∃ 字段记法**：`∃ c, c.length` 类型未知——显式 `∃ c : List
  Fset`；omega 不算 List.length——先 simp only [List.length_nil]。

### 批次六 深化五处（18/23/24/26 为 C 通道件；Lean 镜像记边界）
- 18：fA4/fE4 可导规则（各=一条公理模式+MP）；isAx 五分支的
  `right. right. right. right.` 数清再下（第 5 分支要 4 个 right）；
- 23：lin_ext 走 consistentb（16 赋值穷举 v0/v1）；lin_cons 的
  归纳步先 `simpl` 暴露 if 分支；lin_max 的 witness 用 `fun _ => true`
  处理「整体赋值下 sat 计算真假」；
- 24：iso_eeq 用 `lt`（rat 0）而非 rlt——章内已定义 lt；lt_r 的
  符号位是 0（<）不是 2；trueZnR 需自带 rel 参数包装；
- 26：soInd = neg(∃X[X(0)∧封闭∧不满])；尾巴现场用 succ_rel2
  （顶部自环）+孤立点 5——soev 的 relenv 初始 `fun _ => []`。
