# mathlogic Ben-Ari 全谱扩充实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 mathlogic 教程（34 章/101 单元全绿）按 Ben-Ari《Mathematical Logic for Computer Science》3e 全谱扩充：新增 35–42 八章（FOL 表列/LTL 表列/时态演绎/自动机 MC/并发演绎/SLD 与 Prolog/归结完备与 SAT 难例/合成与形式语义）+ 现有九章定点补强 + 26 收官 Ben-Ari 账本 + Prolog 第七通道。

**Architecture:** 3e 原生文本层为主源（pdftotext 按节提取到 `.scratch/benari/`，页偏移按章实测校准），2e OCR 扫描仅取 §8.3（cut/NAF/CWA）与 §8.5（CLP）精选补充。每章交付=教程文档（docs/NN-*.md，≥200 行、文字多于代码、代码摘录自真实 examples 文件）+ 裁剪通道机器单元（examples/NN_topic/exNN_topic.*，build.ps1 自动发现）。11 个批次（批次零+一…十），每批一个 commit。

**Tech Stack:** Rocq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`）/ Lean 4.25（bare core）/ **SWI-Prolog 10.0.2**（`G:\scoop\apps\swipl\current\bin\swipl.exe`，本机第七通道，已冒烟实测）/ WSL gprolog 1.5.0（跨引擎抽查，不进 CI）/ pdftotext / RapidOCR（cudnn `G:\cudnn\9.24`，仅 2e 公式存疑处）。Agda/Isabelle/HOL4/HoTT 本轮不新增件。

**Spec:** `docs/superpowers/specs/2026-10-07-mathlogic-benari-expansion-design.md`

## Global Constraints

- **教程标准**（spec 原文，逐条可检验）：自包含（只读 docs 学会，不踢读者去原书）；每章 ≥200 行且文字行数多于代码行数；每段代码前后必有文字；正文代码摘录自 examples/ 真实文件并注明文件名；章首保留「> 对书：」行；章末坑位速记。
- **教程验收协议**（每章交付前跑，Git Bash）：

```bash
cd /g/code/guide/mathlogic
wc -l docs/NN-x.md                      # ≥200
awk '/^```/{f=!f;next} !f{n++} END{print "prose:",n}' docs/NN-x.md   # prose 行数
awk '/^```/{f=!f;next} f{n++} END{print "code:",n}' docs/NN-x.md     # 须 < prose
grep -n '自行\|见原书\|参见原书\|读者自己看' docs/NN-x.md              # 须无输出
```

另抽查 2 段正文代码：`grep -F "<片段首行>" examples/NN_topic/<对应文件>` 确认逐字存在。
- **页偏移表**（已实测；PDF 页 = 书页 + 章内恒定偏移，章间因数字版删空白页而跳变）：

| 3e 章 | 偏移 | | 3e 章 | 偏移 |
|---|---|---|---|---|
| ch2 | +13 | | ch10 | +8 |
| ch3 | +12 | | ch11 | +7 |
| ch4 | +11 | | ch12 | +7 |
| ch5 | +10 | | ch13 | +7 |
| ch6 | +10 | | ch14 | +7 |
| ch7 | +9 | | ch15 | +7 |
| ch8 | +9 | | ch16 | +6 |
| ch9 | +9 | | | |

2e ch8 偏移 **+10**（PDF 183=书 173 实测）。
- **提取命令模板**：`pdftotext -f <起> -l <止> -layout "G:/book/计算机/Mathematical Logic for Computer Science v3.pdf" .scratch/benari/<名>.txt`（2e 用原名不带 v3）。
- **命名**：章目录 `examples/NN_topic/`，文件 `exNN_topic.{v,lean,pl}`；.pl 的 `main/0` 必须打印「`==== exNN ... 开始 ====`」与「`==== exNN ... 结束 ====`」两行标记。
- **Prolog 通道判定**（Task 0 接入）：`swipl.exe -q -f <文件> -g main -t halt`，退出码 0 且 stdout 含「结束 ====」标记；stderr 警告不阻塞（单引擎简化协议）。
- **验证**：单章 `pwsh -NoProfile -Command '& ./build.ps1 -Chapter NN'`；全量 `-All`；既有 101 单元每批零回归（SKIP 通道除外）。
- **CRLF 纪律**：Write 工具在 Windows 产出 CRLF——**所有** .v/.lean/.pl 落盘后必须 `python -c "open(p,'w',newline='\n').write(open(p).read())"` 规范化（或 heredoc 内联规范；重要补丁写独立 .py 执行，防 shell 吃转义）。
- **通道坑先查**：动笔前读 `mathlogic/CHEATSheet.md` 27-34 节与 docs/ 相邻章坑位速记（Lean 守卫三连/generalize/`==` 不定义性归约、Coq Notation 不可 unfold/discriminate 裸调/in_or_app 单向、迭代同构对轮次归纳等均会复现）。
- **诚实止步**：某通道卡住按惯例「止步+坑位速记」，不许假装全绿；单元数收官如实记账。
- **提交**：每批 `feat(mathlogic): 批次N——…`，结尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；同步 PLAN.md 蓝图表。
- **新章通道裁剪**：35/36/37/39/41/42 用 C/L；38/40 用 C/L/P。

---

## 批次零：基础设施与取材（Task 0，一个 commit）

### Task 0a: Prolog 第七通道接入 build.ps1 + 冒烟单元

**Files:**
- Modify: `mathlogic/build.ps1`（units 收集 + 'prolog' 分支 + 头部注释）
- Create: `mathlogic/examples/01_intro/ex01_prolog.pl`（ch1 第七家 hello-logic，永久单元）
- Modify: `mathlogic/docs/01-intro.md`（六家账本处加第七家一段）
- Modify: `mathlogic/PLAN.md`、`mathlogic/README.md`（通道表加 prolog 行）

- [ ] **Step 1: build.ps1 三处修改**

1) units 收集的扩展名列表 `'.v', '.agda', '.lean', '.thy', '.sml'` 追加 `'.pl'`；
2) tool 判别追加：`elseif ($f.Extension -eq '.pl') { 'prolog' }`；
3) switch 内新增分支（放在 'hol4' 之后）：

```powershell
'prolog' {
    $out = & 'G:\scoop\apps\swipl\current\bin\swipl.exe' -q -f $u.Path -g main -t halt 2>&1 | Out-String
    $ok = ($LASTEXITCODE -eq 0) -and ($out -match '结束 ====')
    if (-not $ok) { $detail = $out }
}
```

头部注释「六通道」改「七通道」并补 prolog 判定行。

- [ ] **Step 2: 冒烟单元 ex01_prolog.pl**

```prolog
% ex01_prolog.pl —— 第七家：Prolog（SWI-Prolog 10）。
% 逻辑即程序的最初形态：Horn 子句 + SLD 消解（40 章主角，这里 hello-logic）。

peano(zero).
peano(s(X)) :- peano(X).

and(T, T).  or(T, _).  or(_, T).
imp(T, F) :- or(not(F), T).  not(F) :- \+ F.   % NAF：经典否定的计算替代

main :-
    format('==== ex01 prolog hello-logic 开始 ====~n'),
    ( and(true,true), imp(true,true) -> format('tt: ok~n') ; format('tt: FAIL~n') ),
    findall(N, (between(0,4,N), peano_ok(N)), Ns), format('peano: ~w~n', [Ns]),
    format('==== ex01 prolog hello-logic 结束 ====~n').

peano_ok(N) :- numlist(0,N,L), foldl(succ_mul, L, zero, _).
```

注意：SWI 10 源码默认 UTF-8，中注释直读；若实测警告/乱码，文件首行加 `:- encoding(utf8).`
（Step 3 定案后写进 CHEATSheet）。落盘后按 CRLF 纪律规范化。
若上述 `peano_ok` 起不为纯 hello 逻辑（含多余算术），简化为：

```prolog
main :-
    format('==== ex01 prolog hello-logic 开始 ====~n'),
    ( and(true,true) -> format('and: ok~n') ; format('and: FAIL~n') ),
    ( imp(false,false) -> format('imp: ok~n') ; format('imp: FAIL~n') ),
    findall(X, peano(X), Ps),
    length(Ps, Lp), format('peano depth: ~w~n', [Lp]),
    format('==== ex01 prolog hello-logic 结束 ====~n').
```

（`findall` 需限制深度——用 `call_with_depth_limit(peano(X), 5, R)` 或改列
`peano_list(zero,[zero]). peano_list(s(X),[s|T]):-peano_list(X,T).` 数五个；
实现时取最简、输出确定的一条路即可，别让 hello 单元复杂化。）

- [ ] **Step 3: 验证**

```bash
cd /g/code/guide/mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -File ex01_prolog.pl'   # OK
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01'            # 01 章全部 OK
```

跨引擎抽查（手动，不进 CI）：
`wsl.exe -d Ubuntu-26.04 -e gprolog --consult-file <wsl路径> --entry-goal main`（路径转 /mnt/g/…；gprolog 对 `\+`/format 兼容——若不兼容，冒烟件里只用两者公共谓词，把不兼容部分隔离在注释里说明）。

- [ ] **Step 4: docs/01 补第七家一段**（「六家账本」处扩成七家：Prolog=逻辑方程求解器，ND/Hilbert 的可执行亲戚；指向 20/40 章）。保持 01 章现有行数标准不降。

- [ ] **Step 5: PLAN.md/README.md 通道表加 prolog 行**（SWI 10.0.2 路径+判定）。

- [ ] **Step 6: Commit**

```bash
git add mathlogic/build.ps1 mathlogic/examples/01_intro/ex01_prolog.pl mathlogic/docs/01-intro.md mathlogic/PLAN.md mathlogic/README.md
git commit -m "feat(mathlogic): 批次零——Prolog 第七通道接入 + 冒烟单元 ex01_prolog"
```

### Task 0b: 3e/2e 节段提取

**Files:**
- Create: `.scratch/benari/` 下 14 个节段文本（不入库）

- [ ] **Step 1: 3e 十二段提取**（书页+章偏移，见 Global Constraints 表）

```bash
cd /g/code/guide && mkdir -p .scratch/benari
B="G:/book/计算机/Mathematical Logic for Computer Science v3.pdf"
pdftotext -f 39  -l 42  -layout "$B" .scratch/benari/s2_4.txt         # 功能完备集(书26-29)
pdftotext -f 76  -l 83  -layout "$B" .scratch/benari/s3_8-3_9.txt     # 强完备+紧致+变体(书64-71)
pdftotext -f 93  -l 103 -layout "$B" .scratch/benari/s4_4-4_5.txt     # 归结SC+鸽笼(书82-92)
pdftotext -f 121 -l 139 -layout "$B" .scratch/benari/s6_all.txt       # SAT全章(书111-129)
pdftotext -f 152 -l 162 -layout "$B" .scratch/benari/s7_5-7_6.txt     # FOL表列(书143-153)
pdftotext -f 172 -l 174 -layout "$B" .scratch/benari/s8_5.txt         # C规则(书163-165)
pdftotext -f 212 -l 229 -layout "$B" .scratch/benari/s11_all.txt      # 逻辑编程全章(书205-222)
pdftotext -f 230 -l 237 -layout "$B" .scratch/benari/s12_all.txt      # 不可判定+模型论(书223-230)
pdftotext -f 247 -l 269 -layout "$B" .scratch/benari/s13_4-13_9.txt   # LTL语义尾+表列+过去(书240-262)
pdftotext -f 270 -l 279 -layout "$B" .scratch/benari/s14_all.txt      # 时态演绎L(书263-272)
pdftotext -f 286 -l 300 -layout "$B" .scratch/benari/s15_4-15_6.txt   # 合成+语义+相对完备(书279-293)
pdftotext -f 303 -l 331 -layout "$B" .scratch/benari/s16_all.txt      # 并发验证全章(书297-325)
ls -la .scratch/benari/   # 12 个文件全非空
```

- [ ] **Step 2: 2e 两段提取**（偏移 +10；提取后抽查 OCR 质量，公式区存疑页码记入尾部备注）

```bash
B2="G:/book/计算机/Mathematical Logic for Computer Science.pdf"
pdftotext -f 191 -l 196 -layout "$B2" .scratch/benari/2e_s8_3.txt     # cut/NAF/CWA(书181-186)
pdftotext -f 204 -l 209 -layout "$B2" .scratch/benari/2e_s8_5.txt     # CLP(书194-199)
```

- [ ] **Step 3: 质量抽查**——`head -60 .scratch/benari/s7_5-7_6.txt`（FOL 表列是核心新章，
  确认 γ/δ 规则描述可读）；`head -40 2e_s8_3.txt`（OCR 公式区若成乱码，用 RapidOCR
  对应页图核对，只对公式行做，散文不 OCR）。存疑清单追加到 `.scratch/benari/NOTES.md`。

无独立 commit（.scratch 不入库；Task 0a 的 commit 即批次零）。

---

## 批次一：35 FOL 语义表列（Task 1）

**Files:**
- Create: `mathlogic/examples/35_foltableau/ex35_foltableau.v`
- Create: `mathlogic/examples/35_foltableau/ex35_foltableau.lean`
- Create: `mathlogic/docs/35-foltableau.md`

**Interfaces（Coq 版签名，Lean 同构镜像）：**
- 复用 14 章语法形状：`ftm := fvar nat | ffun nat (list ftm)`、
  `folform := fatom nat (list ftm) | fnot … | fand … | fimp … | fforall nat … | fexists nat …`（若 14 章命名不同以现库为准，本章文件内自带定义、不跨文件依赖——各章自包含惯例）。
- 带符号公式 `sf := TT folform | FF folform`（或 `bool × folform`）；分支 `branch := list sf`。
- 规则步（声明式闭规则 + fuel 搜索，沿 07 章 tableau 模式）：

```coq
Fixpoint closedB (b : branch) : bool          (* 分支含互补对 *)
Fixpoint tabSat (fuel : nat) (b : branch) : bool   (* 饱和搜索: 全闭=true *)
Theorem tab_sound : forall fuel A,
  tabSat fuel (map (fun f => FF f) A) = true -> noModel A.
Theorem open_model : forall A b,
  saturatedOpen b -> branchModel b 满足 b   (* Herbrand 项模型读出 *)
```

- δ 规则的「新闭项」用 Ben-Ari 的 a_{f,i} 编号常量方案（`deltaName : folform -> nat -> ftm`）；
  γ 规则用「分支内已有闭项+新项」实例化（教学版：对已出现闭项枚举+新鲜变元兜底，fuel 兜底终止）。
- 现场例两组：① `{∀x.p(x)→q(c), p(c)}` 表列闭（反驳 `¬q(c)`）；② `p(a)∨p(b)` 开分支读出 Herbrand 模型。

**Steps:**
- [ ] Step 1: 读 `.scratch/benari/s7_5-7_6.txt` + 07/16 章 docs 与 CHEATSheet（07 章 fuel 模式照搬）。
- [ ] Step 2: 写 Coq 版（定义→两定理→两组 Example 全绿）。CRLF 规范化。
- [ ] Step 3: `pwsh -NoProfile -Command '& ./build.ps1 -Chapter 35_foltableau'` coq 分支 OK。
- [ ] Step 4: 写 Lean 版镜像（裸 core；守卫/`==` 坑位按 CHEATSheet 预防）。
- [ ] Step 5: build.ps1 35 章 C/L 双绿。
- [ ] Step 6: 写 docs/35-foltableau.md（≥200 行；结构：为何表列比 ND 贴近算法→α/β 回顾→γ/δ 与侧条件（新项命名纪律 vs 16 章新鲜变元）→可靠性与单向完备→Henkin 常量同源（23 章）→与 07/16/22 章接线→坑位速记）。
- [ ] Step 7: 教程验收协议（awk/wc/grep）+ 代码抽查。
- [ ] Step 8: PLAN.md 蓝图加 35 行标 ✅；Commit `feat(mathlogic): 批次一——35 FOL 语义表列新章（C/L）`。

---

## 批次二：36 LTL 语义表列（Task 2）

**Files:**
- Create: `mathlogic/examples/36_ltltab/ex36_ltltab.v` / `.lean`
- Create: `mathlogic/docs/36-ltltab.md`

**Interfaces:**
- 27 章 lform 形状自带（`latom/lneg/land/lor/limp/lnext/luntil`）。
- `closure : lform -> list lform`（对偶闭包；关键引理 `closure_finite`/`closure_closed`：
  闭包内公式的子公式/对偶仍在）。
- 节点 `lnode := (list lform * list lform)`（当前集，下一集）；X-步：`stepNodes : lnode -> list lnode`。
- U 展开：`luntil A B ≡ B ∨ (A ∧ X(A U B))` 作为步规则（β 展开+X 收集）。
- fulfillment：`fulfills : list lnode -> bool`（环上每个未兑现 U 有见证）——教学版对成环节点表检查。
- 现场例：① `F G p`（◇□p）：开表列→预备状态图→环 `{G p, p}` fulfill→读出无穷路径模型；② `G(p→X q) ∧ F p ∧ G ¬q` 类不可满足闭表列（选一个确定性小的）。

**Steps:**
- [ ] Step 1: 读 s13_4-13_9.txt（§13.5 全程：构造、Lemma 13.x 系列、fulfilling 定义）+ 27 章 docs。
- [ ] Step 2-5: Coq 版 → 编译 → Lean 版 → 双绿（同批次一步伐；迭代修坑记速记）。
- [ ] Step 6: docs/36-ltltab.md（结构：判定问题重提（LTL 可满足=反模型存在）→闭包有限性=可判定性的根源→(Γ,Δ) 节点与 X 收集→开分支的预备状态图→环+fulfillment=无穷路径的**有限证书**（第五暗线首发）→与 27（语义）/38（Büchi 前身）/22（有限性主题）接线→坑位速记）。
- [ ] Step 7: 验收协议+抽查。
- [ ] Step 8: PLAN.md ✅；Commit `feat(mathlogic): 批次二——36 LTL 语义表列新章（C/L）`。

---

## 批次三：37 时态演绎系统 L（Task 3）

**Files:**
- Create: `mathlogic/examples/37_ltlded/ex37_ltlded.v` / `.lean`
- Create: `mathlogic/docs/37-ltlded.md`

**Interfaces:**
- 深嵌入（05/17 章 Hilbert 模式搬到时态）：

```coq
Inductive lder : list lform -> lform -> Prop :=
| lAxTaut : 重言实例（教学版: 指定有限公理集, 非 schema）
| lAxDistr : G(p→q)→(Gp→Gq) 系（X 代替 G 的 Ben-Ari 原版: X(p→q)→(Xp→Xq)）
| lAxDual  : ◇p ↔ ¬G¬p 系
| lAxInd   : 归纳公理 G(A→X A)→(A→G A) 实例
| lMP : … | lGen : lder G f -> lder G (G f)   (* 必然化, 无侧条件版 *)
```

- 定理件：`dual_der`、`distr_der`、`ind_countdown`（归纳公理对倒数程序形态实例——直通 25/30 章）。
- 零公理账本：全构造器内建，`Print Assumptions` 空。
- 过去算子 U/S 与分离定理：文档级小节（§13.6 素材），不做机器件。

**Steps:**
- [ ] Step 1: 读 s14_all.txt + s13_4-13_9.txt 尾部（13.6）+ 05/17/31 章 docs。
- [ ] Step 2-5: Coq/Lean 双绿。
- [ ] Step 6: docs/37-ltlded.md（结构：为何要演绎（38 章之前的可满足判定不能证有效式）→系统 L 公理逐条读法→归纳公理=时态归纳法=不变式规则的理论形态→若干定理推导现场→与 31（模态 Gen 无侧条件 vs 33 □i 严格性的对照：时态框架自反？——X 版 Gen 的合理性讨论）→过去算子与分离定理→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次三——37 时态演绎系统 L 新章（C/L）`。

---

## 批次四：38 自动机与 LTL 模型检查（Task 4，本轮最大件，C/L/P）

**Files:**
- Create: `mathlogic/examples/38_buechi/ex38_buechi.v` / `.lean` / `.pl`
- Create: `mathlogic/docs/38-buechi.md`

**Interfaces（教学版路线，spec 风险节已定案）：**
- Büchi 自动机：

```coq
Record baut := { bS : list nat; bT : nat -> nat -> bool;
                 bI : list nat; bF : list nat }.
Definition prod (A B : baut) : baut.            (* 交自动机: 状态对+接受条件交替 *)
Fixpoint reach (A : baut) (fuel : nat) : list nat.        (* 可达集 *)
Definition findLoop (A : baut) : option (list nat)        (* 可达接受态 s 且 s→*s 的环 *)
Theorem loop_to_run : forall A pth, findLoop A = Some pth ->
  exists r, 无穷运行且无穷多次过 bF.                    (* 环→无穷反例路径读出 *)
Theorem no_loop_empty : findLoop A = None -> 不存在接受运行.  (* 单向即可 *)
```

- 现场例（doc 主线+机器件同一案例）：三状态模型 K（0→1→2→1 循环，p 只在 0），
  验证 `AG F p`（"总回到 0"）——取 ¬(AG F p) 的监视自动机由 36 章表列状态图手推（doc 走查），
  机器件直接给该自动机数据：`negA : baut` + `prod K negA` + `findLoop = None` 判真；
  反例现场：改 K'（0→1 自环死掉回不去）→ `findLoop (prod K' negA) = Some 环` 读出反例路径。
- Prolog 件 `ex38_buechi.pl`：同一 K/K'/negA 数据 + 同一 findLoop 算法（可达闭包+环检测），
  main 打印两个现场的结果与反例环；标记行按全局约定。

**Steps:**
- [ ] Step 1: 读 s16_all.txt §16.4-16.8（程序=自动机→不变式/活性→LTL→自动机→同步积）+ 28/34 章 docs。
- [ ] Step 2: Coq 版（baut/prod/reach/findLoop/两定理/两组 Example）。
- [ ] Step 3: Lean 版镜像。
- [ ] Step 4: ex38_buechi.pl（SWI 10；CRLF 规范化；纯数据+表驱动，不用 tabling/高级库）。
- [ ] Step 5: `build.ps1 -Chapter 38_buechi` C/L/P 三绿；gprolog 跨引擎抽查一次。
- [ ] Step 6: docs/38-buechi.md（结构：反例=无穷路径，怎么**搜**（28 章逐状态标记不找路径）→程序=自动机→¬φ 监视自动机（36 表列状态图是它的前身——两次走查同源）→乘积与空性→环=有限证书（第五暗线第二发）→嵌套 DFS/Tarjan 注记（教学版走可达+环检测，复杂度不优、正确性完备）→与 24/28/34 三条 MC 路线总收束→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次四——38 自动机与 LTL 模型检查新章（C/L/P）`。

---

## 批次五：39 并发程序演绎验证（Task 5）

**Files:**
- Create: `mathlogic/examples/39_conc/ex39_conc.v` / `.lean`
- Create: `mathlogic/docs/39-conc.md`

**Interfaces:**
- 并发程序 = 原子步表：`Record astep := { guard : state -> bool; act : state -> state }`；
  状态 `state := (nat * nat * nat)`（两进程位置 pc1/pc2 + 转折变量 turn）。
- 不变式保持逐条机器化：

```coq
Definition inv : state -> bool.            (* 互斥: pc1=crit -> turn=2 等 *)
Theorem inv_preserved : forall st st' a,
  In a asteps -> guard a st = true -> act a st = st' ->
  inv st = true -> inv st' = true.         (* 对原子步表逐条 case *)
Theorem inv_init : inv init_state = true.
```

- await/原子区霍尔规则的文档级陈述 + 与 25 章单进程规则的对照；交错语义定义。
- 现场例：两进程简化互斥（turn 变量/Peterson 简化版，与 28 章同一案例的演绎面）。

**Steps:**
- [ ] Step 1: 读 s16_all.txt §16.1-16.3 + 25/28 章 docs。
- [ ] Step 2-5: Coq/Lean 双绿（逐条 case 的体力件——Lean 侧注意函数展开展示）。
- [ ] Step 6: docs/39-conc.md（结构：交错=组合爆炸之源（28 章状态数的来由）→演绎 vs 算法：一个不变式顶一个可达集→原子步模型与 await 规则→互斥例逐条保持现场→活性为何演绎难（公平性进逻辑=38 章 LTL 的活）→Owicki-Gries 注记→与 25/28/37/38 接线→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次五——39 并发程序演绎验证新章（C/L）`。

---

## 批次六：40 SLD 与逻辑编程语义（Task 6，C/L/P）

**Files:**
- Create: `mathlogic/examples/40_sldprolog/ex40_sldprolog.v` / `.lean` / `.pl`（文件名 `ex40_sldprolog.pl`）
- Create: `mathlogic/docs/40-sldprolog.md`

**Interfaces:**
- C/L 件（复用 19 章合一形状、自带定义）：

```coq
Definition clause := atom * list atom.          (* 头 :- 体 *)
Definition goal := list atom.
Fixpoint resolve (c : clause) (g : goal) (fuel) : option (goal * sub)  (* 选定原子归结 *)
(* 两条计算规则 *)
Definition ruleL : nat -> nat := fun _ => 0     (* 恒选最左 *)
Definition ruleR : nat -> nat := fun n => n-1   (* 恒选最右 *)
Theorem indep_example : 同一程序同一目标, ruleL 可解出的 answer 集 = ruleR 可解出的 answer 集
                          (实例级: 一个具体程序+目标, 两边集合相等, refl/穷举收)
```

  一般性陈述（任意 fair 规则）文档级走查（spec 风险节定案：实例级机器化+一般性文档化，边界如实登记）。
- Prolog 件 `ex40_sldprolog.pl` 三现场：① cut 对照（green cut 保语义/red cut 剪解集——同一程序两版打印解集）；② NAF 非 CWA（`\+` 与经典否定的差异例）；③ CLP 小节（SWI clpfd：`X in 1..9, X*X #= 25` 类约束传播——2e §8.5 素材；若 clpfd 加载慢/警告，改纯逻辑版 `label` 模拟并注明）。标记行按全局约定。

**Steps:**
- [ ] Step 1: 读 s11_all.txt + 2e_s8_3.txt/2e_s8_5.txt + 20 章 docs（T_P 桥）。
- [ ] Step 2-5: Coq → Lean → .pl → `build.ps1 -Chapter 40_sldprolog` 三绿 + gprolog 抽查。
- [ ] Step 6: docs/40-sldprolog.md（结构：从 T_P 语义到 SLD 搜索树→计算规则 vs 搜索规则（独立性定理的准确陈述与实例现场）→Prolog 三偏差（cut/NAF/CWA）逐个账本化（语义=纯逻辑的哪些片段被工程偏离）→CLP：解空间先约束后标签→与 09（DPLL 同是搜索+传播）对照→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次六——40 SLD 与逻辑编程语义新章（C/L/P）`。

---

## 批次七：41 归结完备性与 SAT 难例（Task 7）

**Files:**
- Create: `mathlogic/examples/41_rescomp/ex41_rescomp.v` / `.lean`
- Create: `mathlogic/docs/41-rescomp.md`

**Interfaces:**
- 命题归结反驳证明对象：`Inductive resproof := RClause of clause | RRes of clause * clause * clause * nat`（消解变元位）+ `rpSound : resproof -> clause -> 良构检查`。
- 完备性桥（教学版）：`tab_to_res`：07 章闭表列 → 归结反驳的翻译（对表列深度归纳；若整桥太重，做**单向引理**：闭表列存在⟹反驳存在，证明走「表列闭规则=归结步」的逐规则翻译引理，fuel 版）。
- 鸽笼件：`php32 : list clause`（PHP(3,2)：3 鸽 2 洞，9+… 子句）+ `php32_refute : resproof`（显式反驳树）+ `Example php32_closed : rpSound php32_refute ⊥ = true`。若 PHP(3,2) 反驳树超长（>40 步），降 PHP(2,2) 并在 doc 如实说明（长度爆炸本身就是本节主题——Ben-Ari 的点）。
- DP 消元器：`dpStep : list clause -> option (list clause)`（纯文字消除/单子句传播/变量消元三规则）+ `dp_sound : dp 保持可满足性`（方向：dpStep S = Some S' → sat S ↔ sat S'）+ 现场例跑 php32。

**Steps:**
- [ ] Step 1: 读 s4_4-4_5.txt + s6_all.txt（§6.2 DP 与 §6.4 扩展例）+ 07/09/19 章 docs。
- [ ] Step 2-5: Coq/Lean 双绿（PHP 反驳树是体力件——Coq 手写 + Lean 同构；DP 消元器较轻）。
- [ ] Step 6: docs/41-rescomp.md（结构：可靠性便宜完备贵（19 章留下的口）→反驳=证明对象（演算作为数据第三次会师）→完备性桥：表列↔归结→鸽笼：为何难（每个洞的「至多一鸽」要两两展开，反驳长度指数）→DP 三规则 vs DPLL 分裂（09 章回望：消元先行 vs 赋值先行）→随机算法与复杂度注记（NP 完全性一句话账）→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次七——41 归结完备性与 SAT 难例新章（C/L）`。

---

## 批次八：42 程序合成与形式语义（Task 8）

**Files:**
- Create: `mathlogic/examples/42_synthsem/ex42_synthsem.v` / `.lean`
- Create: `mathlogic/docs/42-synthsem.md`

**Interfaces:**
- cmd（25 章形状自带：`cskip | cass nat (state->state) | cseq | cwhile bexp cmd`——若 25 章是别的形状以现库为准）。
- 小步语义：

```coq
Fixpoint step (c : cmd) (s : state) : option (cmd * state).   (* skip 终止/赋值一步/while 展开 *)
Fixpoint steps (fuel) (c) (s) : option state.                 (* 大步包装 *)
Theorem hoare_step_sound : hoare P c Q -> forall s s',
  steps fuel c s = Some s' -> P s = true -> Q s' = true.      (* 联接件: 演算↔语义 *)
```

- 合成现场：除法程序由规约 `{x≥0∧y>0} div {x = y*q+r ∧ r<y}` 反推（doc 主线走查 Ben-Ari
  §15.4 的逆向构造：不变式从规约「长出来」）；机器件=合成结果的霍尔三元组验证（复用 25/30 章规则形状）+ `steps` 执行两例。
- 指称语义与不动点：文档级（Knaster–Tarski 第四次会师——20/24/34 章收束线）；相对完备性（Cook）注记：证明蕴含算术，演绎系统不可能完全——与 22 章不完备的又一呼应。

**Steps:**
- [ ] Step 1: 读 s15_4-15_6.txt + 25/30 章 docs。
- [ ] Step 2-5: Coq/Lean 双绿。
- [ ] Step 6: docs/42-synthsem.md（结构：霍尔规则正向用（验证）反向用（合成）→除法合成六步走查→小步语义：程序=状态机（39 章原子步的单进程版）→hoare_step_sound：演算对语义可靠→指称=不动点→相对完备性：不完备性在程序逻辑的化身→与 12（证明=程序）/22/25/30/34 接线→坑位速记）。
- [ ] Step 7-8: 验收协议；Commit `feat(mathlogic): 批次八——42 程序合成与形式语义新章（C/L）`。

---

## 批次九：现有章定点补强（Task 9，纯文档，无新单元）

**Files:**
- Modify: `mathlogic/docs/02-propsem.md`（§2.4 功能完备集小节：{∧,¬}/{→,¬}/NAND/NOR 单独成基，与 09/10 实现语言呼应）
- Modify: `mathlogic/docs/06-sequent.md`（§3.9 变体形式：G↔ND↔H 互译对照小节）
- Modify: `mathlogic/docs/09-dpll.md`（DP 变量消元对照段+指向 41）
- Modify: `mathlogic/docs/17-folhilbert.md`（§8.5 C-规则小节：存在常量引入）
- Modify: `mathlogic/docs/19-resolution.md`（完备性方向+lifting 思路段，指向 41）
- Modify: `mathlogic/docs/20-herbrand.md`（SLD 计算规则指针段，指向 40）
- Modify: `mathlogic/docs/21-decidability.md`（§12.2 可判定情形小节：单项 FOL、两变元片段）
- Modify: `mathlogic/docs/23-completeness.md`（§3.8 命题强完备与紧致性小节）

**Steps:**
- [ ] Step 1: 对应节段文本复读（s2_4/s3_8-3_9/s8_5/s6_all/s11_all/s12_all）。
- [ ] Step 2: 逐章加节——每节 25-60 行自包含讲解（不是摘要：把定理陈述+证明思想在本教程语境重述），保持各章 prose>code 不降。
- [ ] Step 3: 验收：八章 wc/awk 复跑全过、无「见原书」字样。
- [ ] Step 4: Commit `feat(mathlogic): 批次九——八章定点补强（Ben-Ari 视角小节）`。

---

## 批次十：收官对账（Task 10）

**Files:**
- Modify: `mathlogic/docs/26-wrapup.md`（收官重写：Ben-Ari 16 章逐节账本表（节|主题|本教程落点）与 H&R 账本并列；H&R/Ben-Ari/EFT/Mendelson 四书分工对照表；七通道表；总坑位清点加 35-42 节）
- Modify: `mathlogic/README.md`（35-42 章行、通道表、单元数实测口径）
- Modify: `mathlogic/PLAN.md`（蓝图 35-42 行标 ✅、八书定位 Ben-Ari 行更新为「已逐节对账」）
- Modify: `mathlogic/CHEATSheet.md`（新坑：Prolog 通道判定/编码、35-42 各章实测坑、2e OCR 公式核对注记、3e 页偏移表）

**Steps:**
- [ ] Step 1: 全量回归 `pwsh -NoProfile -Command '& ./build.ps1 -All'`——实测单元数 N/ N 全绿（含 2 个 .pl；SKIP 通道除外），把**实测数字**写进 README/26 章（不预算不虚报）。
- [ ] Step 2: 26 章重写（账本表逐节填：3e 全部 16 章×节→「已覆盖章号/本轮新增/文档级/边界」四类落点；四书分工：H&R=CS 应用主线、Ben-Ari=演算与判定算法主线、EFT/Mendelson=元理论纵深）。
- [ ] Step 3: README/PLAN/CHEATSheet 同步；最后跑一次教程验收协议全库抽查（34+8 章 wc/awk）。
- [ ] Step 4: Commit `feat(mathlogic): 批次十——收官对账：Ben-Ari 账本+全库回归`。
- [ ] Step 5: 更新记忆文件 `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-benari-expansion.md` + MEMORY.md 索引。

---

## Self-Review 记录

- **Spec 覆盖**：8 新章=批次一~八；补强 8 章+01=批次零/九；26 账本+四书对照=批次十；Prolog 协议=批次零；取材协议（页偏移实测表/2e 精选/OCR 纪律）=Global Constraints+批次零。✓
- **占位符**：无 TBD；每任务给出文件名、接口签名、现场例、验收命令、commit 信息。机器件签名是「设计锚点」（Coq 记法），实现时按通道习惯微调但定理名/语义保持——这是本项目既定工作方式（H&R 轮同款）。✓
- **类型一致**：35-42 章示例目录名/文件名前后一致（38_buechi/40_sldprolog 三通道同名不同扩展）；.pl 标记约定全文统一「==== exNN … 开始/结束 ====」与 build.ps1 判定 `'结束 ===='` 互锁。✓
