# mathlogic 第八轮扩充实施计划：张寅生六新章（80→86）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按张寅生《证明方法与理论》完成第八轮扩充：六新章块内生长（80→86）+五深化件+收官五文件对账。

**Architecture:** 沿用七轮既定节奏：批次〇全书重排（renumber_k.py 第六次改造：新 MAP/GAPS/NEW_TITLES/expect 86）→四批次新章（C/L 双通道为主，15/63 加 P）→深化件+收官。机器件纪律=有限影子/表格对账/可判定小宇宙/枚举判定器，零公理或显式记账。

**Tech Stack:** Coq (Rocq 9.1 `g:/rocq/Rocq-Platform~9.1~2026.01/bin/coqc.exe -q`，产物在 build/coq)、Lean 4.25 裸 core（native_decide 允许）、Prolog SWI 10（15/63 各一件+35 深化）、build.ps1 (-All/-Chapter)。

**Spec:** docs/superpowers/specs/2026-10-09-mathlogic-zhangyinsheng-expansion-design.md（章位映射/每章五节结构与机器件清单/深化件表全部以 spec 为准；书 OCR 原文在 `.scratch/zyz/zyz_book.txt`，PDF 页≈书页+10~14 各区略异——引用时以 agent 提取件为准）

## Global Constraints

- 教程三铁律：正文引用全部讲解代码；对书内容自包含讲清；无篇幅限制。
- 每章 docs ≥240 行、文字多于代码；页脚由重排脚本生成后新章手工补。
- Coq 零公理纪律（旗舰件 Print Assumptions = Closed）；Lean 无 mathlib。
- Prolog：首行 `:- encoding(utf8).`、stdout 纯 ASCII、末行 `END ====`。
- 验收：每章 `-Chapter NN` 各通道全 OK；收官 `-All` 全绿 0 SKIP。
- commit：每批次一个，消息含批次号与章目。
- 书内容归属纪律：15 章第 4 节明确标注「量化扩展三段论」为张寅生自研体系（2009 专著）；OCR 损失公式按惯例复原处标注。

---

### Task 1: 批次〇——全书重排 80→86

**Files:**
- Modify: `tools/renumber_k.py`（新 MAP/GAPS/NEW_TITLES/expect 86）
- Rename: 66 个 `examples/NN_*` 目录、66 个 `docs/NN-*.md`、其内 exNN_* 文件
- Rewrite: 全部交叉引用文本（docs/*.md、README/PLAN/CHEATSheet、examples/ROOT、examples/**/*）

**Interfaces:**
- Produces: 空位 15/20/54/63/78/84（新章用）；旧 80 收官→86（Task 9 改写）

- [ ] **Step 1:** 更新 `tools/renumber_k.py` 头注释与映射：
  ```python
  MAP = {  # 旧→新（01-14 恒等不列；全部单调增）
      15:16, 16:17, 17:18, 18:19,                   # FOL 块头：+1（让位 15 三段论）
      19:21, 20:22, 21:23, 22:24, 23:25, 24:26, 25:27,
      26:28, 27:29, 28:30, 29:31, 30:32, 31:33, 32:34, 33:35,
      34:36, 35:37, 36:38, 37:39, 38:40, 39:41, 40:42, 41:43,
      42:44, 43:45, 44:46, 45:47, 46:48, 47:49, 48:50, 49:51,
      50:52, 51:53,                                   # →53（让位 54 截消）
      52:55, 53:56, 54:57, 55:58, 56:59, 57:60, 58:61, 59:62,
      60:64, 61:65, 62:66, 63:67, 64:68, 65:69, 66:70, 67:71,
      68:72, 69:73, 70:74, 71:75, 72:76, 73:77,       # →77（让位 78 悖论）
      74:79, 75:80, 76:81, 77:82, 78:83,              # →83（让位 84 算术几何）
      79:85, 80:86,
  }
  GAPS = {15, 20, 54, 63, 78, 84}
  NEW_TITLES = {
      15: ('syllogism',  '三段论与传统逻辑'),
      20: ('historical', '历史形式系统考古：Frege、PM 与 Hilbert'),
      54: ('cutelim',    '截消定理与序数分析'),
      63: ('automata',   '自动机与形式语言：Chomsky 层级'),
      78: ('paradox',    '悖论的结构与解悖理论'),
      84: ('axioms',     '算术与几何的公理系统'),
  }
  # verify: expect = set(range(1, 87)) - GAPS
  ```
- [ ] **Step 2:** dry-run 检查输出（目录/docs/文件改名清单与映射一致；替换统计合理）
- [ ] **Step 3:** `python -I tools/renumber_k.py --apply`；git status 核对（66 目录+66 docs）；verify 残留过滤 n∈MAP 后=0
- [ ] **Step 4:** `pwsh -NoProfile -Command '& ./build.ps1 -All'` —— 208 单元全绿（纯重排）
- [ ] **Step 5:** 提交批次〇

### Task 2: 批次一——新 15 章 三段论与传统逻辑（C/L/P）

**Files:**
- Create: `examples/15_syllogism/ex15_syllogism.v` / `.lean` / `.pl`、`docs/15-syllogism.md`

**Interfaces（C/L 同名镜像）:**
- `ext : bool -> bool -> bool`——外延对 (S,P) 在 3 元论域的枚举算子（形如 sub/has 闭包，输出 27 种 (S,P) 组合的真值表载体）
- `aeio : (list nat -> bool) -> (list nat -> bool) -> form`——四直言命题构造（A: ∀x(S→P)、E: ∀x(S→¬P)、I: ∃x(S∧P)、O: ∃x(S∧¬P)），S/P=list nat 载集
- `square_check`——对当方阵账：矛盾(A↔¬O ∧ E↔¬I)/反对(A∧E 不同真)/下反对(I∨O 至少一真——空载集反例账)/差等(A→I ∧ E→O)的 27 载集对全枚举（含空载集暴露「存在导入」偏差）
- `sylValid : mood(三元组 A/E/I/O) -> figure(1..4) -> bool`——有限论域枚举判定器
- `valid24`——256 格式枚举 → 恰 24 有效式清单对账（按格分组打印账本）
- `barbara/celarent/baroco`——FOL 侧机器证明（Coq 一阶内建/Lean 手写）；`darapti_counter`——空论域反例件（AAI-3 在空载集失败=现代语义下无效）
- `pt_implies_ex`——量化扩展：PT(真子集)→∃ 蕴涵账+¬∀=∃/PT∨∀=∃ 两式验证（张氏定理 4.1 选样）
- `ext_valid`——格岗空间五关系（全异 disj/全同 eq/交叉 cross/包含 sub/被包含 sup）样本组合枚举：前提 (S,m)×(m,P) 关系→结论 (S,P) 可达关系读出量词——504 有效式的机制缩影（抽样对账表）
- Prolog：`:- encoding(utf8).` 载集幂枚举+判定 `syl(Mood,Fig)`+ND(SOA) 产生式风格生成器（P1 演绎 15 条产生式骨架）+`END ====`

- [ ] Step 1: 写 `.v`（外延语义+对当方阵 27 枚举+256→24 账+四格证明+Darapti 反例）→ coqc 过
- [ ] Step 2: 写 `.lean` 镜像（native_decide 允许）→ lean 过
- [ ] Step 3: 写 `.pl`（判定+生成双引擎）→ swipl 过
- [ ] Step 4: `-Chapter 15` 三通道 OK
- [ ] Step 5: 写 `docs/15-syllogism.md`（≥240 行五节：直言命题与对当方阵/直接推理/格式与 256→24/量化扩展[张氏体系标注]/三段论自动机 ND(SOA)+QESS——代码全引用、自包含）
- [ ] Step 6: 提交批次一

### Task 3: 批次二 a——新 20 章 历史形式系统考古（C/L）

**Files:**
- Create: `examples/20_historical/ex20_historical.v` / `.lean`、`docs/20-historical.md`

**Interfaces:**
- `fax : form -> bool`——Frege 九公理谓词（form:=pvar|fimp|fneg|feq atom 侧命题片段为主；F52/F54/F58 谓词侧记文档线）+`f_axioms_taut` 六条命题公理布尔永真抽查
- `f_subst`——代入组合子（变元替换）；`fmp`——分离规则步
- `f_thm4_chain`——例 9.4 重演：F 定理 4 的推导链账（公理 2 三次代入+MP 的步进表）
- `f_thm_ex95`——例 9.5 重演（⊢((¬a→b)→b)→((¬a→b)→¬¬a)）
- `pm1_2 .. pm1_6`——PM R-1 五公理（¬/∨ 初始，→ ∧ ≡ 缩写定义展开）+`pm_207/208/21_chain`——2.07→2.08→2.1 命题链重演账（例 9.10/9.11/9.12 步进表）
- `h17 : form -> bool`——Hilbert 17 公理谓词+`h17_of_mendelson`——17 条全为 Mendelson 三公理（K/S 命题骨架）定理的机器证明（每条 tauto/derive）；反向 `mendelson_of_h17` 三条
- `blood_table`——三系统血缘账数据件（H 的 * 源 Russell/^ 源 Frege 标注对照）

- [ ] Step 1: 写 `.v`（公理谓词+推导链账+互导）→ coqc 过
- [ ] Step 2: 写 `.lean` 镜像 → lean 过
- [ ] Step 3: `-Chapter 20` 两通道 OK
- [ ] Step 4: 写 `docs/20-historical.md`（四节：公理 vs 规则系统/Frege 1879/PM R-1R-2/Hilbert 17 与互导——每节推导链步进表全引用）
- [ ] Step 5: （与 Task 4 同 commit 提交批次二）

### Task 4: 批次二 b——新 54 章 截消定理与序数分析（C/L）

**Files:**
- Create: `examples/54_cutelim/ex54_cutelim.v` / `.lean`、`docs/54-cutelim.md`

**Interfaces:**
- `seq := list form * list form`——矢列；（Γ,Δ）
- `g2rules`——G 第二系统 12 规则编码（弱化 wkl/wkr、凝缩 ctl/ctr、交换、∧R/∧L、∨R/∨L、¬R/¬L 命题侧）；`deriv : nat -> seq -> bool`——深度界可推导性判定器
- `g_ex915`——例 9.15 矢列证明重演账（⊢¬(P∧Q)→¬P∨¬Q 七步推导表，含「∧左引入」勘误注记）
- `inv_check`——反演定理命题件：11 条规则「底矢列有效⟹顶矢列有效」有限指派枚举验证表
- `cut_admissible`——cut 在命题 G 中可吸附的样本账（含 cut 推导→无 cut 推导的步进对照 `cut_step`：情形 1a 弱化吸附+情形 3 主公式 A→B 分裂，每步级 g 下降对账）
- `grade : form -> nat`——级（原子=1、每联结词+1）；`rank_mix`——mix 左右秩计算
- `cnf_ord`（复用 51 章序数树风格的最小实现）+`ord_assign`——序数指派 o(P)（初始=1/弱化不变/+1/自然和 #/cut 处 ω^(h−r)）+`descent_check`——单实例消去后 o(P′)<o(P) 对账
- `ti_finite`——超穷归纳有限影子：有限序数段上的 TI 验证（良序最小元反证法账）+`ti_peano`——TI 模式在 nat 上的陈述（=nat_ind 的对账）
- `consistency_ladder`——83 层相容性链数据件（EFA<PRA<RCA₀<PA<ACA₀<ID₁<Z₂<ZFC 表）

- [ ] Step 1: 写 `.v` → coqc 过
- [ ] Step 2: 写 `.lean` 镜像 → lean 过
- [ ] Step 3: `-Chapter 54` 两通道 OK
- [ ] Step 4: 写 `docs/54-cutelim.md`（五节：G 第二系统/反演定理/cut-mix 与截消方法/Hauptsatz 与 PA 相容性[序数指派+TI+四版证明史+定理 13.4 文档线]/相容性层级——步进表与对账全引用）
- [ ] Step 5: 提交批次二（20+54）

### Task 5: 批次三 a——新 63 章 自动机与形式语言（C/L/P）

**Files:**
- Create: `examples/63_automata/ex63_automata.v` / `.lean` / `.pl`、`docs/63-automata.md`

**Interfaces:**
- `dfa := list (nat * bool * nat)`——DFA 转移表（状态=nat、输入=bool 二元字母表教学件；汉字例用三符号 abc 载体）；`dfa_run : dfa -> nat -> list bool -> nat`、`dfa_accept`
- `panda_dfa`——例 11.6 熊猫识别器镜像（「xiong mao」两词序+¬A 补类拒绝账）；`prop_dfa`——例 11.7「1+1=2」接受账
- `nfa := list (nat * bool * list nat)`；`nfa_run`（状态集语义）；`subset_dfa : nfa -> dfa`——子集构造；`subset_ok`——定理 11.1 构造化证明账：∀w, nfa_accept n w ↔ dfa_accept (subset_dfa n) w（全词枚举对账）+`gogole_nfa`——例 11.9 go*gle 账
- `pda := ...`（栈符号 bool）；`pda_run`——例 11.5 aⁿbⁿ接受+aⁿbᵐ(m≠n) 拒绝对账（栈轨迹表 `pda_trace`）
- `lba_shadow`——例 11.4② 等额检查：边界 ⟨,⟩ 内 aᵐbcᵐ 识别的带头受限单带机（简化 3 状态教学版）
- `chomsky_table`——四型文法约束数据件（0 无限制/1 型 |α|≤|β|/2 型 α∈V_N/3 型右线性）+包含链对账；`rg_of_dfa/dfa_of_rg`——3 型文法↔DFA 互译件+定理 11.2(4) 验证（生成语言=接受语言样本对账）
- `reg_sep`——语言类分离数据表（aⁿbⁿ∈CFL∖REG 等账；泵引理陈述文档线）
- Prolog：文法推导引擎（产生式链 enumerate）+DFA 运行双引擎+`END ====`

- [ ] Step 1: 写 `.v`（DFA/NFA/子集构造/PDA/LBA/互译）→ coqc 过
- [ ] Step 2: 写 `.lean` 镜像 → lean 过
- [ ] Step 3: 写 `.pl` → swipl 过
- [ ] Step 4: `-Chapter 63` 三通道 OK
- [ ] Step 5: 写 `docs/63-automata.md`（四节：五原型谱系+Chomsky 总表/DFA 与 NFA+子集构造/PDA 与 LBA/文法-机器互译+分离——全引用）
- [ ] Step 6: （与 Task 6 同 commit 提交批次三）

### Task 6: 批次三 b——新 78 章 悖论的结构与解悖理论（C/L）

**Files:**
- Create: `examples/78_paradox/ex78_paradox.v` / `.lean`、`docs/78-paradox.md`

**Interfaces:**
- `smullyan`——抽象系统件：g:nat->nat 命名函数（有限宇宙）+`t_repr : (nat->bool)->bool` T-可表示性+`diag_not_repr`——命题 13.1：{n|¬T(g(n)[n])} 不可表示的枚举验证账（对每个候选 φ 找反例 n）
- `quine_fix`——quin 不动点骨架：subst 自替换+¬ 前缀——说谎者「本句不真」/Russell「x∉x」/Gödel「本句不可证」三实例一键生成对账（有限字符串自复制骨架）
- `order_check`——类型阶检查器：`oform`（带阶语法：prop n | app (n+1 阶谓词作用于 ≤n 阶项)…），罗素谓词输入时**类型检查失败现场**（Error 项）；说谎者 q 的阶分析账（例 13.8：变元阶 ≤n 通过 vs n+1 失败）
- `sep_scene`——ZFC 分离现场：V₄ 有限秩内 {x∈M|φ(x)}⊆M 枚举账 vs 朴素概括越界对比+正规公理挡 Ω={Ω}（∈ 链无穷下降被禁的有限账）
- `nf_strat`——NF 层化检查器：差约束求解（x∈y ⟹ α(y)=α(x)+1；x=y ⟹ α 相等），x∈x 判「不分层」（无解账）/x=x 通过/罗素概括式被禁——例 13.16 对账
- `sit_seq`——情境序列生成器：s1→s2→s3 展开+True m/False m 交替账（表 13.1 机器化）
- 文档线：Lawvere 范畴不动点+λ 表示 Y(t)+朴素集表示 (A=B)∧(A∈B)+五系统对照表（→79 章 NBG 衔接）

- [ ] Step 1: 写 `.v` → coqc 过
- [ ] Step 2: 写 `.lean` 镜像 → lean 过
- [ ] Step 3: `-Chapter 78` 两通道 OK
- [ ] Step 4: 写 `docs/78-paradox.md`（五节：悖论谱系/统一结构/类型论/ZFC 与 NF/情境语义学——全引用）
- [ ] Step 5: 提交批次三（63+78）

### Task 7: 批次四 a——新 84 章 算术与几何的公理系统（C/L）

**Files:**
- Create: `examples/84_axioms/ex84_axioms.v` / `.lean`、`docs/84-axioms.md`

**Interfaces:**
- `z7_iso`——log 同构影子：Z₇*≅Z₆ 加法循环群同构账（x↦log₃x 保持运算的逐对验证表）
- `interp_nat_z`——解释函子影子：ℕ 嵌入 ℤ 商构造（79 章 paireq 复用）+保真小账
- `pa1889`——Peano 九公理原文形式（N 谓词+四则+二阶归纳 ∀Y(…)）vs nat_ind 翻译账（九条逐条在 Coq nat 上的兑现表）
- `aca_comp`——ACA₀ 算术概括件：X:Nat->Bool+φ 算术侧条件（归纳定义 arith 公式类）+PA 归纳为 ACA₀ 定理的样本推导
- `tarski19`——实数 20 公理：19 条在有序域载体（29 章 ordered field 风格最小实现：carrier=nat 上有理比例教学域或 Q 风格对）逐条验证账+4'' Dedekind 二阶例外标注
- `euclid_deps`——命题 1.29 依赖链件：1.29←{公设 1.5,1.13,1.15,公理 I.1}、1.13←{…}、1.15←{…} 依赖图数据+重演（书例 9.16 三步证明的形式化对账）
- `hilbert_I`——关联公理 F₃² 解析模型：点=F₃²、线=ax+by+c=0 解集（9 直线全集枚举）+I.1-I.8 逐条验证表+「两直线至多一交点」小定理机器推导
- `rel_consistency`——相对相容性骨架：小理论对（欧氏线序→非欧线序带解释函子+保真验证）；E→L→R 包容链公理 13.13 文档线

- [ ] Step 1: 写 `.v` → coqc 过
- [ ] Step 2: 写 `.lean` 镜像 → lean 过
- [ ] Step 3: `-Chapter 84` 两通道 OK
- [ ] Step 4: 写 `docs/84-axioms.md`（五节：同态与解释性证明/PA 1889 与 ACA₀/Tarski 实数 20 公理/欧几里得与希尔伯特几何/相对相容性——全引用）
- [ ] Step 5: （并入批次四 commit）

### Task 8: 批次四 b——五深化件

**Files:**
- Modify: `examples/34_herbrand/ex34_herbrand.{v,lean}`（原 32）：H 域逐层生成器 `herbrand_layers`（H₀={a}、H_{i+1}=H_i∪F(H_i) fuel+单调性 H_i⊆H_{i+1}）+**语义树件** `sem_tree`（基原子二叉分叉+失败节点判定+封闭性——图 10.1/10.2 可执行版小例）
- Modify: `examples/35_rescomp/ex35_rescomp.{v,lean}`（原 33）：`res_closure` Rⁿ 归结闭包算子（R⁰=S 迭代至不动点）+Robinson 两定理两阶段执行链账（基例化→基础归结→□）
- Modify: `examples/37_sldprolog/ex37_sldprolog.pl`（原 35）：**WAM 双栈轨迹件**（例 11.14：p(X,X). q(a,b). p(X,Z):-q(X,Y),p(Y,Z). ?-p(X,b). 目标栈/绑定栈/回溯轨迹表，得 p(b,b)/p(a,b)）
- Modify: `examples/40_turing/ex40_turing.{v,lean}`（原 38）：表格式五元组 TM 对照件 `tm_tab`（例 11.1 2ˣ 机+例 11.2 一进制加法器的六元组表格式编码+与四元组解释器互译账）
- Modify: `examples/79_funequiv/ex79_funequiv.{v,lean}`（原 74）：关系运算深化 `trans_close`（Warshall/不动点双实现对照）+`rel_props` 五性质判定器+运算-联结词同步表账
- Docs: 各章 md 加「张寅生轮深化」节（每件 30-50 行讲解）
- 49 章加 EFA 下界一段文档注记（定理 14.4）+41 章 Dershowitz-Gurevich 注记一段

- [ ] Step 1: 34/35 件+C/L 编译过+`-Chapter 34/35` OK
- [ ] Step 2: 37 .pl 过+`-Chapter 37` OK
- [ ] Step 3: 40 件+`-Chapter 40` OK；79 件+`-Chapter 79` OK
- [ ] Step 4: 五章 docs 补深化节+49/41 注记段
- [ ] Step 5: （并入批次四 commit）

### Task 9: 批次四 c——86 收官改写+五文件对账+记忆

**Files:**
- Rewrite: `docs/86-wrapup.md`（原 80）：标题「八轮合拢」、86 章 231 单元口径、频谱图补 63 自动机位（Chomsky 层级与 SAT→ITP 谱交汇）、八轮总坑位节（+第八轮新坑）、张寅生书 15 章逐章对账表、十二书导读（+张书行）、相容性层级叙事线收口（54 章衔接）
- Modify: `README.md`（第八轮状态行+6 新表行=86 行全表）、`PLAN.md`（十二书+张书行+6 新行）、`CHEATSheet.md`（「张寅生轮新章坑位」节）
- Create: 记忆 `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-zhangyinsheng-expansion.md`+MEMORY.md 索引行

- [ ] Step 1: 86 收官改写（对账表 stale 编号清零自查）
- [ ] Step 2: README/PLAN/CHEATSheet 三文件
- [ ] Step 3: 全量回归 `pwsh -NoProfile -Command '& ./build.ps1 -All'` —— 231 单元全绿 0 SKIP
- [ ] Step 4: 记忆落盘+索引
- [ ] Step 5: 提交批次四（84+深化+收官）

## Self-Review 结论

- 覆盖：spec 三节六章→Task 2-7 一一对应；spec 四节五深化+两注记→Task 8；spec 五节收官→Task 9。✓
- 占位符：无 TBD/TODO；每件签名已定。✓
- 类型一致：重排 MAP 与 spec 二节映射一致（15-18→16-19 等）；深化件章号用重排后新号（34/35/37/40/79）。✓
