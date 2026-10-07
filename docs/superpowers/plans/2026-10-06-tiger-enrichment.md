# 虎书扩充：静态分析教程 48→54 章实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以 Appel《Modern Compiler Implementation in C》（虎书）为取材，把 48 章教程扩为 54 章：6 个新章逻辑插入、48 章重编号，新 48 章补 coalescing。全部自包含蒸馏，虎书 C 代码改写为 C++23 + ANTLR + LLVM 栈。

**Architecture:** 新章沿用 docs/NN-slug.md ↔ examples/NN_slug 双轨契约；重编号复用上轮 renumber.py 模式（单遍回调 + 哨兵 + 多重集校验）。

**Tech Stack:** 同既有教程。

**Spec:** 本文件（含映射表与章节定义）。

## Global Constraints

- 教程叙事体；书的内容自包含蒸馏，不指派读者翻原书；虎书 C 代码全部改写为 C++23 风格。
- 每章 ≥200 行、文字多于代码；src/TIP.g4/expected 字节级内嵌；三层对账全绿。
- 提交只 stage compiler/，消息尾注 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 绝对路径调工具；UCRT64 PATH 每条命令自带。

## 旧→新映射（48 槽 → 54 槽）

恒等：1–13 不动。其余：
14→15, 15→16, 16→17, 17→18, 18→19, 19→20, 20→21, 21→22, 22→23, 23→24,
24→25, 25→26, 26→27, 27→28, 28→29, 29→30, 30→31, 31→32, 32→33, 33→34,
34→36, 35→37, 36→39, 37→40, 38→41, 39→42, 40→43, 41→44, 42→45, 43→48,
44→49, 45→50, 46→52, 47→53, 48→54。
新槽：14 规范化与跟踪、35 控制依赖与 SSA 往返、38 边界检查与循环展开、
46 对象与类、47 闭包与函数式、51 分支预测与预取。

篇结构（十一篇）：一 地基(1–2)；二 前端(3–10)；三 中间表示与运行时(11–16)；
四 类型(17–20)；五 格与数据流(21–29)；六 精度(30–32)；七 控制流结构(33–39)；
八 跨函数(40–45)；九 语言范式(46–47)；十 代码生成与并行(48–52)；十一 收束(53–54)。

---

## 批次二十（Task 1）：48 章重编号到 54 槽

- [x] 1.1 更新 .scratch/renumber.py 的 MAP 与新槽注释，跑 rewrite → 终检计数一致
- [x] 1.2 跑 rename（两阶段 git mv + 清旧 build 子目录）
- [x] 1.3 跑 embed 重生成；48/48 示例 run-all 全绿
- [x] 1.4 README 篇结构重排（新槽标"扩充中"）；提交

## 批次二十一（Task 2）：14 规范化与跟踪（虎 §8）

**Files:** examples/14_traces/{src/trace.hpp,src/trace.cpp,src/main.cpp, 基座=TAC 家族}
**要点:** canonical TAC（每指令单运算、比较不落地——13 章已满足，正文点明）；
贪心跟踪：从入口块出发"跟着跳转走"，串成跟踪（trace）；跟踪内顺直链消跳转
（块尾无条件跳到下一块的开头 ⇒ 消除）；条件跳转两臂的翻转（fall-through 选热臂）。
**--check:** TAC → 块 → 贪心跟踪表 → 线性化新 TAC（跳转数前后对比）→ 解释器 outputs 对账。
**验收:** jumps 下降 + outputs 相等 + exit 0。

## 批次二十二（Task 3）：35 控制依赖与 SSA 往返（虎 §19.5–19.7）

**Files:** examples/35_cdg/{src/cdg.hpp,src/cdg.cpp,src/ssaback.cpp,src/main.cpp, 基座=TAC+dom}
**要点:** 后支配者（逆图上跑 33 章迭代）；CDG = {n 依赖 c | c 不是 n 的后支配者且
c 到 n 的每条路都过后支配 n 的停止点}（实现：边 (a,b)，b 不是 a 的后支配者、
且 a 的……用标准算法：对每条边 A→B，若 B 不后支配 A，从 A 沿 CFG 向上回溯到
首个被 B 后支配的节点，途经节点都控制依赖于 B）。SSA 退出：φ 拆成前驱块尾的
复制（并行→串行，swap 用临时）；函数式 IR（CPS）一小节正文讲思想不实现。
**--check:** 块图 → 后支配树 → CDG 边表 → SSA(33 章构造) → 拆回 TAC →
解释器往返对账（原==SSA==拆回）。
**验收:** CDG 边与手工验证一致 + 往返 outputs 相等。

## 批次二十三（Task 4）：38 边界检查与循环展开（虎 §18.4–18.5）

**Files:** examples/38_bounds/{src/bounds.cpp,src/unroll.cpp,src/main.cpp, 基座=TAC+licm 家族}
**要点:** 边界检查 = `if i >= N goto fail` 模式；虎书的三级优化：
(1) 循环不变界（N 不变、i ∈ [0,N) 由归纳变量约束推出）⇒ 检查整体外提或删除；
(2) 归纳变量约束传播（i = i0 + k·t，0 ≤ i0 且 k·trip ≤ N ⇒ 全程安全）；
(3) 循环展开 ×2（减少分支与循环开销；正文讲收益/代码膨胀权衡）。
**--check:** TAC → 循环识别 → 检查消除计数 → 展开后 TAC → steps/outputs 对账。
**验收:** 检查指令下降 + 展开后 outputs 相等。

## 批次二十四（Task 5）：46 对象与类（虎 §14）

**Files:** examples/46_objects/{src/objmodel.hpp,src/objmodel.cpp,src/main.cpp}（无 ANTLR，模拟模型）
**要点:** 对象 = 记录 + 类描述符指针；**vtable**（方法表）：静态方法直呼、
虚方法经 vtable 间接调用（连回 44 章 0-CFA 的"调用图是分析出来的"）；
单继承 = 属性前缀扩展（子类布局兼容父类前缀）；多继承的三种成员测试方案
（字典/彩色/display 向量，正文自包含讲清取舍）；self/this 的静态与动态绑定。
**--check:** 迷你类层级（A→B→C 单继承 + D 多继承）→ 布局表 → vtable 表 →
派发轨迹（静态/虚方法各一串）→ 模拟执行 outputs；虚调用点报告"可能的目标集合"
（与 0-CFA 口径一致）。
**验收:** 布局偏移正确 + 派发轨迹与手算一致。

## 批次二十五（Task 6）：47 闭包与函数式（虎 §15+§16）

**Files:** examples/47_functional/{src/closure.cpp,src/tailcall.cpp,src/thunk.cpp,src/main.cpp}（内置迷你函数式程序，无 ANTLR）
**要点:** 闭包 = 代码指针 + 环境指针（连回 15 章活动记录的访问链装箱）；
**闭包转换**：自由变量装箱进环境、调用约定改造；**内联展开**（小函数体直嵌，
正文讲启发式）；**尾递归 → 循环**（栈不增长的语义条件：尾调用是 return 位置
且参数不求值顺序无副作用）；**惰性求值**：thunk = 值或计算，强制求值一次后
记忆（call-by-need 的计数对账 vs call-by-value）；**多态值表示**（虎 §16.3）：
统一表示（一切皆机器字/装箱指针）vs 双表示（int 直存/引用装箱）的取舍。
**--check:** 迷你 λ 程序 → 闭包转换打印（环境内容）→ 尾递归改写为循环
（用 15 章 VM 跑对账）→ thunk 求值计数（need ≤ value）。
**验收:** 尾递归改写保 outputs + need/value 求值计数对账。

## 批次二十六（Tasks 7–8）：48 补 coalescing + 51 分支预测与预取 ✅

### Task 7: 48 寄存器分配补 coalescing（虎 §11.2）
- [x] 在 48 章（原 43）示例里实现 Briggs 安全合并（合并后度 < k 的邻居数不减才合并），
      moves 清单已登记；新增 stats: coalesced=N；期望输出重生成；正文 48.4 节扩写。

### Task 8: 51 分支预测与预取（虎 §20.3+§21.2–21.3）
**Files:** examples/51_predict/{src/bpredict.cpp,src/prefetch.cpp,src/main.cpp}（模拟）
**要点:** 静态预测（后向跳转预测 taken 的循环启发式）；二位饱和计数器（00–11，
强/弱 taken/not-taken，错两次才翻转）；预测命中率 = 命中/分支总数；
**预取**：循环流水的提前取数（距离 = 延迟/迭代时长，正文推演）；
**缓存块对齐**：数组基址按缓存行对齐消冲突 miss（52 章模拟器口径复用）。
**--check:** 两段循环+分支的 trace → 二位预测器逐事件表 → 命中率；对齐前后的
miss 对比（复用 52 章口径的迷你模拟）；预取距离推演表。
**验收:** 循环预测命中率 > 分支乱序命中率（启发式的机器证据）。

## 批次二十七（Task 9）：54 收官更新与 README 定稿 ✅

- [x] 9.1 survey 表补 6 行新家族（跟踪线性化/控制依赖/边界检查/对象派发/闭包转换/预测预取）；
      每章一句话扩至 54；正文"三十/四十八"口径更新为五十四。
- [x] 9.2 README 十一篇 54 章导航定稿；虎书取材说明入前言。
- [x] 9.3 全量回归 54/54 + check_docs；更新记忆文件。
- [x] 9.4 提交。

## Self-Review

- 覆盖：虎书独有内容（§8/§14/§15/§16.3/§18.4–5/§19.5–7/§20.3/§21.2–3）全映射到任务；
  §11.2 合并按用户拍板补进 Task 7。
- 一致性：新章示例对账契约与既有各章同型（steps/outputs/轨迹/计数四类证人）。
- 风险：重编号脚本二次使用——MAP 改错会连锁；终检计数一致 + run-all 全绿双闸。
