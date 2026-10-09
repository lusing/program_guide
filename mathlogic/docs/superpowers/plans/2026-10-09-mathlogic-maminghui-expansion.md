# mathlogic 第九轮扩充实施计划：马明辉《结构证明论》86→92

> **For agentic workers:** 本计划沿用本会话前八轮的执行模式（批次提交+
> 全量回归）。Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按马明辉《结构证明论》扩充 mathlogic 教程：6 新章+5 深化+
2 注记+92 收官，全书 86→92 章、222→235 单元全绿。

**Architecture:** 块内生长（第七次重排）；每新章=examples/NN_slug/
exNN_slug.{v,lean}（费奇加 .pl）+ docs/NN-slug.md（五节结构、代码全引
用）；深化件扩展现有 examples 单元+docs 加节；收官五文件对账。

**Spec:** docs/superpowers/specs/2026-10-09-mathlogic-maminghui-expansion-design.md

**Global constraints:**
- 通道判定：coq=`/g/rocq/Rocq-Platform~9.1~2026.01/bin/coqc.exe -q`（拷
  build/coq/ 命名 ex_*.v）；lean=lean 4.25 裸 core（native_decide 允许）；
  prolog=SWI-Prolog 10（入口 main、首行 `:- use_module(library(settings))` 类
  utf8、stdout ASCII、末行 `END ====`）。
- Coq 记号坑全录：&&/||→andb/orb；三元组左结合（显式嵌套）；`at`/`seq`/
  `tape` 关键字或撞名；`*` 被 nat_scope 劫持（%type）；map2/Nat.pow2 缺席
  （手写）。Lean 坑：列表字面量首元素全限定；zipWith 全应用；Nat.eqb→==。
- 教程纪律：docs 正文引用全部机器代码；每章≥200 行；文字多于代码；
  章末 Zig 式导航（上一章/下一章）；文档线标注（不给机器的书内容）。
- 回归：tools 现有 verify 全量（-All），0 SKIP；每批次提交前跑相关章。

## Tasks

### Task 0: 第七次重排 86→92

**Files:** tools/renumber_k.py（改 MAP/GAPS/NEW_TITLES/expect）
- [ ] MAP={3:4..13:14, 14:16..54:56, 55:59..68:72, 69:74..81:86, 82:88..86:92}
- [ ] GAPS={3,15,57,58,73,87}；NEW_TITLES 六项
      （3 fitch 费奇式自然演绎 / 15 normalization 正规化定理 /
      57 structural 结构规则谱系 / 58 interpolation Craig 插值定理 /
      73 modalpt 模态证明论 / 87 alglogic 代数逻辑）
- [ ] dry-run 校验目录数=92、映射后 expect=set(range(1,93))-GAPS
- [ ] --apply + 全量回归 222/222

### Task 1: 新 3 章 费奇式自然演绎（ex3_fitch）

**Files:** examples/03_fitch/ex3_fitch.{v,lean,pl} + docs/03-fitch.md
**Interfaces:** fform（p/bot/and/or/imp）；fline=(级别,公式,依据)；依据=
Pre | Hyp | Reit:n | AI:m,n | AEL:m | AER:m | OI1:m | OI2:m | OE:m,a-b,c-d
| II:a-b | IE:m,n | BotE:m | NE:a-b（经典）。
- [ ] C：fitchOK 检查器（作用域：Reit 仅同级之前+上一级；Hyp 开新级）
      +例 2.1 三例+LEM 在 FK/¬¬α→α+FJ 无 ¬E 的 LEM 不可推（搜索无据）
- [ ] L：镜像+native_decide 账
- [ ] P：行号引用检查器 main（书例通过账）
- [ ] docs 五节+导航；`-Chapter 3` 三通道绿

### Task 2: 新 15 章 正规化定理（ex15_normalization）

**Files:** examples/15_normalization/ex15_normalization.{v,lean} + docs/15-normalization.md
**Interfaces:** der=叶(公式,假设标记)|节点(规则名,前提列表,结论)；cutFml
（引入结论=消去大前提）；red1（∧-变/→-变/∨-置换）；chD=(k,n) 字典序。
- [ ] C：der+cutFml+red1+chD 严格降账+normalize 跑到底+子公式检查
      （推论 2.3）+NK° 注记（⊥E^a）
- [ ] L：镜像
- [ ] docs 五节；`-Chapter 15` 绿

### Task 3: 新 57 章 结构规则谱系（ex57_structural）

**Files:** examples/57_structural/ex57_structural.{v,lean} + docs/57-structural.md
**Interfaces:** mset=list fform+count；g1chk/g2chk/g3chk（规则表数据）；
g4ip 四分支+μ 权重（μ(p)=μ(⊥)=2，μ(a∧b)=μ(a)(1+μ(b))，μ(a∨b)=μ(a)+
μ(b)+1，μ(a→b)=μ(a)·μ(b)+1）；g4search（深度限+无重复）。
- [ ] C：G1/G2/G3 规则账（引理 4.3/4.6/4.8 选样）+四不等式账+g4search
      （书例 ⇒(α→α)→β 类死循环在 G3、G4 终止）+Ea/Em 账+Glivenko 双
      重否定单例
- [ ] L：镜像
- [ ] docs 五节；`-Chapter 57` 绿

### Task 4: 新 58 章 Craig 插值（ex58_interpolation）

**Files:** examples/58_interpolation/ex58_interpolation.{v,lean} + docs/58-interpolation.md
**Interfaces:** split=(Γ₁,Δ₁,Γ₂,Δ₂)；interp:推导×划分→公式（组合子
Id/pass/And/Or/Imp/Const）；varsCheck。
- [ ] C：interp 递归构造+端到端例（α=(p∧q)∨r 类→插值子→α→γ→γ→β
      真值表全枚举）+直觉主义版（γ₁→γ₂ 跨侧）+变元条件+无公共变元
      极端账（γ=⊥/⊤）
- [ ] L：镜像
- [ ] docs 五节；`-Chapter 58` 绿

### Task 5: 新 73 章 模态证明论（ex73_modalpt）

**Files:** examples/73_modalpt/ex73_modalpt.{v,lean} + docs/73-modalpt.md
**Interfaces:** mseq=(前件 list mform,后件 option)；GI 规则 (K)/(T)/(S4)；
hseq=list mseq（超矢列）；MG 合成。
- [ ] C：GI 六系统规则账+例 6.4+GS5 分析性 cutᵃ 现场+HC 内/外部结构
      规则+MG+HS5 □ 消除 (5.3) 收尾+S5 等价公理账
- [ ] L：镜像
- [ ] docs 五节；`-Chapter 73` 绿

### Task 6: 新 87 章 代数逻辑（ex87_alglogic）

**Files:** examples/87_alglogic/ex87_alglogic.{v,lean} + docs/87-alglogic.md
**Interfaces:** term=p|a∧b|a∨b|~a；L/GDL/GDM 后承=（项表,项）；w 权重。
- [ ] C：L 检查器+命题 7.6 选样+p∧(q∨r)⊬(p∧q)∨(p∧r) 搜索反证+DL 需
      cut vs GDL 消除对照+DM 公理账+GDM+~~a⊢a+CP 变换+w 可判定账
- [ ] L：镜像
- [ ] docs 五节；`-Chapter 87` 绿

### Task 7: 五深化+两注记

- [ ] 04（原 03）：ND→Hilbert 五平移模板账
- [ ] 07（原 05）：HK A1-A10 全真+HJ=HK−A10 账
- [ ] 16（原 14）：素理论/典范模型/真值引理/过滤 FMP/可判定链+三反例
- [ ] 25（原 23）：G3c/G3i 特征变元+EP+命题 5.4/5.5
- [ ] 69（原 66）：15 系统+对应定理+模态词计数+存在引理
- [ ] 注记：14 章证明论路线指针；53 章 Gödel 翻译量词失效
- [ ] 各章 `-Chapter N` 回归

### Task 8: 92 收官+五文件对账+全量回归

- [ ] docs/92-wrapup.md 九轮合拢改写（235 口径+七章对账+十三书+新坑）
- [ ] README（92 行全表）/PLAN/CHEATSheet（马明辉轮坑位节）
- [ ] 记忆落盘+MEMORY.md 索引
- [ ] `-All` 全量回归 235/235 绿 0 SKIP → 提交

## Execution

本会话直接内联执行（executing-plans 模式），每 Task 一个 commit 语义
（按批次合并提交：spec→计划→〇重排→一费奇→二正规化+结构→三插值+模态
→四代数+深化+收官）。
