# 第 10 章　语法错误的恢复与校正：让分析器跌倒后爬起来

到此为止，本教程所有的分析器都遵守同一条默契：输入要么合法、要么程序作废。真实世界的编译器不能这样——用户提交的第一次编译几乎总有错，**错误恢复的质量直接决定 IDE 体验的下限**：一条缺掉的分号，不该让后面三十行全部报废。

本章取材 Louden《编译原理及实践》§4.5（自顶向下的错误校正）与 §5.7（自底向上的错误校正），把"跌倒后爬起来"做成一门工程学：检测点在哪、怎么同步、怎么避免级联假错误、怎么让恢复后的分析继续产出结果。与前两章的机器衔接紧密：LL 侧复用第 6 章的表驱动预测分析器，LR 侧复用第 9 章的值栈驱动器（MiniYacc）——错误恢复是**驱动器的扩展**，不是新机器。

**本章示例：`examples/10_error_recovery`（无 ANTLR，LL/LR 双侧四模式）**

阅读地图：

- 只想知道"为什么会报一串错" → §10.2 的级联账（TokenDel 3 条 vs Panic 1 条）。
- 想理解 yacc 的 error 记号 → §10.4 的三步协议。
- 想比较 LL 与 LR 谁先发现错误 → §10.1 与 §10.7 的 S2 段（结论先说：本语料 10/10 同时）。
- 想动手改进恢复策略 → §10.9 的练习 5–8。

## 10.0　本章要解决的问题与位置

四个子问题，每个都有独立的一节：

1. **错误在哪一刻被看见**（检测点）——不是"哪一行错了"（那是用户视角），而是"分析器的哪一步走不下去了"（机器视角）。两者的换算 = 诊断的行号与光标定位。
2. **走不下去之后怎么办**（恢复策略）——朴素删除、恐慌模式、短语级修复、错误产生式，四档火力。
3. **恢复会不会引狼入室**（级联假错误）——一次真错误触发一串假诊断，是恢复设计里最阴的坑。
4. **恢复之后还剩什么**（续行能力）——归约日志能不能接上、无错部分的求值能不能保住。

位置：本章是第二篇"前端的原理"的收官前一章。第 9 章补齐了生成器谱系，本章补齐这条谱系最弱的环节——**生成器的错误恢复是被框架圈定的**（yacc 只有 error 记号一种官方姿势，ANTLR 只有监听器回调），而手写分析器（第 6/11 章）想怎么恢复都行。理解了这个约束，就理解了第 9.8 节"工业前端为什么手写"的最后一块拼图。

与前后章的接口冻结：

- `MiniYacc::Recover` 枚举与 `parseRecover` 签名——第 9 章 parse 的姊妹入口，后续章复用时新增模式**尾部追加**（枚举尾部追加纪律，同第 9 章 ConflictStats 的先例）。
- `Diag`/`LLResult` 的 (pos, msg) 形状——第 12 章起的诊断体系以此为雏形（加行号列号是练习 5 的活）。
- `error` 伪终结符的注册约定——文法侧声明、表侧普通列、驱动侧注入；三份职责的边界就此固定。
- 06/09 副本的改名（LLGrammar/LLParseResult）——**本章的新命名属于本章**；后续章若再需要 06 原版，仍回 06 章取（副本裁剪的"原章为准"约定，见第 9 章 9.7.8）。

## 10.1　错误检测点：LL 与 LR 谁先看见

### 10.1.1　检测的形式定义

- **LL(1) 表驱动**：检测发生在"栈顶非终结符 A、当前 token a、表项 M[A][a] 为空"的那一刻——**没有任何 A 的推导能以 a 开头**。
- **LR(LALR)**：检测发生在"栈顶状态 s、当前 token a、action[s][a] 为空"的那一刻——**没有任何合法句子的前缀能延续"栈上内容 + a"**（活前缀性质）。

两个定义的共性：都是"第一个不可能的 token"——**规范检测**。理论上，任何确定的分析器都不可能在更早的位置断言错误（前面的输入始终可以延长成合法句子……严格说要看文法类，教学口径取此直觉）。

### 10.1.2　Louden 论断的精确化

L 书 §5.7.1 说"LR 检测到错误的时刻永不迟于、且通常早于 LL"。这句话需要一个精确化的注脚——**"通常早于"的来源不是 LR 算法本身，而是 LL 文法的工程变形**：

- LL(1) 要求文法无左递归、无公共前缀冲突 → 真实语言文法要**改写**（左递归消除、提左因子）；
- 改写偶尔会**推迟判定**（公共前缀被合并后，区分两个分支的信息要等更多 token）；
- LR 不改写文法，活前缀性质原样保留 → 检测点天然贴着"第一个不可能的 token"。

本章的实测（§10.7 S2 段）恰好是干净的对照：demo 的 LL 文法是忠实改写（没有信息损失的合并），十个坏语料上 LL 与 LR 的检测位置**逐条相同**（equal=10）。这个"全部相等"本身就是有价值的实证——它说明：**当 LL 文法改写不丢信息时，两家的检测能力打平**；Louden 的"通常早于"应读作"当 LL 文法被迫模糊化时，LR 占优"。

"LL 被迫模糊化"的三种典型机制（何时 LR 会真的更早）：

- **左因子的合并**：`stmt → if (e) s | while (e) s` 若被迫写成 `stmt → kw ( e ) s`、`kw → if | while`——kw 的判定被推迟到展开后，某些非法 token 要等 s 归属确定后才暴露。
- **ε 的大量引入**：消除左递归会引入 ε 产生式，FOLLOW 集变大、表项变"宽容"——错误 token 撞上宽容表项时，LL 要多走几步才见空格。
- **右递归化的信息倒置**：`prog → stmt prog'` 把"序列结构"倒过来，尾部错误的检测依赖 prog' 的 ε 判定——与左递归版"边读边并"的即时性有微妙差异。

三条机制的共同点：**改写动了文法的判定顺序**。LR 从不改写，所以它的检测点是"第一不可能 token"的忠实实现——这就是"永不迟于"的形式内容。练习 4 会让你亲手制造一次"迟于"。

### 10.1.3　从检测点到用户诊断

检测点给出 (token 下标, 栈顶状态/符号)。翻译成人话要两步：

- 下标 → 行号列号（词法阶段记下的 line 字段——本章 LexTok 预留了它，MiniLex 已填）；
- 栈顶 → "期望集"：LL 侧是 FIRST(栈顶非终结符)（"期待表达式，却看到了 ;"）；LR 侧是该状态所有非空 action 的 key 集（同样的句式）。

诊断的黄金句式：**"第 N 行：期待 {……}，遇到 {实际 token}"**——两边的信息都在栈上，恢复器顺手就能生成。本章 demo 的 diag 消息是它的雏形（`[top=stmt la=;]`）。

## 10.2　恐慌模式：同步集与级联抑制

### 10.2.1　朴素删除为什么是级联制造机

最直觉的恢复：删掉出错的 token、重试。对"缺分号"语料 `y = 2 z = 3;`（LR 侧）：

| 步 | 栈期待 | 当前 token | 动作 |
|---|---|---|---|
| 错误 | `;` | `z`(ID) | 删 z，报错 1 |
| 重试 | `;` | `=` | 删 =，报错 2 |
| 重试 | `;` | `3`(NUM) | 删 3，报错 3 |
| 重试 | `;` | `;` | ✓ 语句完成 |

**一次真错误（缺分号），三条诊断**——用户看到三条报错会以为程序有三个问题。实测（§10.7 S3 段）：TokenDel 三条、Panic 一条，LR/LL 两侧完全一致。级联的机制：删 token 治标不治本——**病根是缺了 `;`，删多少输入都补不上**，要等"运气好删到对齐"为止。

### 10.2.2　恐慌模式的两个变体

- **LL 版（FOLLOW 同步）**：栈顶非终结符 A 无表项时，**丢输入直到 token ∈ FOLLOW(A)，然后弹出 A**——"这一段里没有 A"的官方解释。栈顶是终结符不匹配时，直接弹栈（假定输入缺了它）。
- **LR 版（本章实现：input-first）**：action[s][a] 为空时，**先丢输入直到当前状态能接受**（栈不动——栈的期望就是同步集），丢到 `$` 仍不行才弹栈。对缺分号语料：期待 `;` 的状态丢掉 `z = 3` 三个 token 后迎来 `;` ✓——一条诊断，`y = 2` 完整保住。

两个变体的共同哲学：**承认"这一段解析不了"，跳到一个双方都认可的同步点**。同步点的选择是设计决策：语句边界（`;`）、块边界（`}`）、声明开始符——越靠近语言的结构边界，恢复越干净，丢弃越多。

变体对照表（本章实现为据）：

| 维度 | LL 版（FOLLOW 同步） | LR 版（input-first 状态期望） |
|---|---|---|
| 同步集来源 | 文法分析产物 follow 表 | 栈顶状态的 action keys（活的） |
| 修输入时机 | 丢到 FOLLOW(A) 再弹 A | 丢到当前状态能接受，栈不动 |
| 修栈时机 | A 弹出即恢复 | 兜底才弹（丢到 $ 仍不行） |
| 缺分号语料 | 1 条诊断 | 1 条诊断 |
| y=2 保住？ | 是（弹 `;` 假定缺失） | 是（丢 z=3 迎回 `;`） |
| 结构损伤 | 丢一个非终结符的期望 | 丢三个输入 token |

最后一行是两者的真实差异：**LL 修复栈（丢期望）、LR 修复输入（丢内容）**——同一语料两种哲学，殊途同归到"1 条诊断 + 语义保全"。选择往往不由优劣定，而由**哪边的结构更便宜**定：LL 的栈是非终结符（弹一个）、LR 的栈是状态（弹一串才到一个可接受点），所以 LR 天然偏向修输入。

### 10.2.3　恢复的质量指标

从 S3/S5 的数据提炼三条指标：

- **诊断数**：Panic 1 vs TokenDel 3——级联抑制的直接量度；
- **抢救率**：S5 里 `y = 2` 的赋值保住了（变量表有 y=2）、后续 `w = 4` 与两条 print 全部照常——恢复丢弃的输入越少，语义损失越小；
- **接受性**：恢复后仍 accept——分析器"跌倒后爬起来走完全程"，这是 IDE 能继续给后续代码做高亮/补全的基础。

## 10.3　短语级恢复：局部的插入与删除

恐慌模式动辄丢几个 token，短语级（phrase-level）恢复试图**最小修复**：

- **插入**（假定输入缺了 X）：栈顶终结符 X 与输入不匹配时，弹掉 X、不消耗输入——"输入里少了 X"；
- **删除**（假定输入多了 a）：直接吃掉 a——TokenDel 的单步版；
- **替换**（X 应为 a）：弹 X 吃 a——两步合一。

最小修复的代价是**抖动风险**：纯插入不消耗输入也不弹栈的情形（若修复逻辑写歪）会原地打转。本章 LL 侧的 Phrase 模式带**双创口守卫**：连续两次"不消耗输入的修复"后强制吃一个 token。实测（S6 段）：`print ((();` 三次插入 + 守卫介入，28 步有界收场；深括号语料 67 步。**单调性论证**：每次修复要么消耗输入要么收缩栈，两者都有限 → 总步数必然有界——守卫是对"修复逻辑不单调"的保险，不是必要条件。这个论证写进正文，因为它是"恢复器不会死循环"的证明骨架。

短语级与恐慌的关系是火力梯度：**先试最小修复，连续失败升级恐慌**。bison 的 `error` 之前的 yacc、以及很多教学编译器就是这么叠的。

单调性论证的完整版（为什么 Phrase 必然终止）：

- 设输入长 n、文法的可展开栈深有上界 S（每次展开压的符号数有限、且不展开到无穷——LL(1) 表的展开是有限的）。
- 每轮循环做且仅做三类事之一：**消耗一个输入 token**（≤ n 次）、**弹一个栈符号**（栈深有限）、**展开一个非终结符**（表驱动、每步有限）。
- 插入修复 = 弹栈不消耗输入：栈在缩；删除修复 = 消耗输入不动栈：输入在缩。
- 两个计数器（剩余输入、当前栈深）构成**字典序递减的二元组**——不可能无限循环。
- 守卫（连续两次无消耗修复强制吃一个）是在这个论证之上再加一道闸：即便未来有人加入"既不消耗也不收缩"的修复（如重写规则），闸门保证它连不成环。

这个论证的形状与第 30 章不动点的"高度有限所以迭代终止"同构——**终止性靠的是度量函数的递减**，恢复器的度量是 (剩余输入, 栈深) 的字典序。

## 10.4　错误产生式与 yacc 的 error 记号

### 10.4.1　思想：把常见错误写进文法

与其让"缺表达式"崩掉，不如给文法加一条**专门吃错误的产生式**：

```text
stmt → ID '=' expr ';'
     | 'print' expr ';'
     | error ';'          ← 新增：错误占位 + 同步到分号
```

`error` 是一个**不出现在任何词法规则里的伪终结符**。表构造器把它当普通终结符——LALR 表里照常出现 error 的 shift 列（第 9 章的仲裁器都不用改）。恢复协议三步（yacc 的官方算法，L 书 §5.7.3）：

1. 出错时，**弹栈**直到某状态可移进 error；
2. **移进 error**（注入一个假 token）；
3. **丢输入**直到表给出动作——通常是 error 规则的后续符号（这里是 `;`）。

### 10.4.2　本章实测走读（S4 段）

语料 `x = 1; y = print 2; z = 3; print z;`（`y =` 后面跟了关键字，表达式位置非法）：

| 步 | 事件 | 栈/输入状态 |
|---|---|---|
| 1–5 | `x = 1;` 正常归约 | prog 已滚一句 |
| 6 | 移进 `y`、`=`，检测：expr 期待因子，遇 `print` 无动作 | **诊断 @6** |
| 7 | 弹栈至"error 可移进"的状态 | 丢掉 `y =` 的上下文 |
| 8 | 移进 error（伪 token，值 Empty） | 进入 `stmt → error · ;` |
| 9 | 丢输入 `print 2`，至表给出动作 | 迎来 `;` |
| 10 | 移进 `;` → 归约 `14: stmt → error ;` | y 语句以伪形态闭合 |
| 11+ | `z = 3; print z;` 照常归约 | 续行完成 |

- **续行**：归约日志从 `14: stmt → error ;` 起接上正轨——`z = 3;`、`print z;` 两条语句的归约序列与无错版**逐条一致**（`[tail match] 1`）；
- 语义：`print z` 输出 3——z 的赋值在恢复后照常完成；
- 第 7 步值得多看一眼：弹栈丢掉的是 `y =` 的**已解析上下文**（y 这个名字连同它的赋值目标都消失了）——error 记号的代价是"错误语句整体作废"，比 Panic（保住 y=2）**语义损失更大**、但**恢复位置更精确**（正停在语句边界）。两档火力的取舍又一次摆上桌。

error 记号与恐慌的分工：**恐慌是驱动器的机制（不改文法），error 是文法的机制（声明式地写恢复点）**。bison 用户偏爱 error——它在 .y 文件里可见、可版本管理、可以精确到"哪类语句的哪 个位置能吞错误"。

### 10.4.3　TINY 的实例（L 书 §5.7.4）

Louden 的 TINY 分析程序用 yacc 生成，错误策略正是 error 记号：`stmt → error ;` 一类的规则 + 词法层的关键字同步。书里给出的观察值得抄录：**简单文法配简单恢复就够**——TINY 的错误恢复不到二十行文法改动，就能做到"报错一次、后续语句照析"。工业前端的恢复器复杂度爆炸，不是因为算法深，而是因为**语言 constructs 的同步点多**（模板、lambda 体、属性列表……每个都要人工指定恢复边界）。

## 10.5　诊断质量：报什么、不报什么

四条经验律（从本章语料与真实编译器的对照里提炼）：

- **位置要具体到 token**：`@6` 比"第 2 行"好；行号+列号+原文摘录（`y = print 2;` 的 `print` 处）是黄金标准。
- **期望集要人话**："期待表达式"比"表项 M[expr][print] 为空"好；期望集来自栈顶状态的 action keys——§10.1.3 的换算。
- **一条真错误一条诊断**：S3 的级联账就是反例教材；恢复器作者的第一 KPI 是**抑制假诊断**。
- **不猜用户的意图**：短语级修复只做"语法上最小"的动作（插入分号），不做"语义上可能"的动作（把 print 改名）——猜错比不猜更伤信任。

第 9.7.5 坑复盘的"接缝是 Bug 集散地"在本章再次应验：恢复器是**驱动器与文法的接缝**，本章开发的五个坑（§10.8）全部长在缝上。

诊断质量的实例演算（拿期望输出的 diag 行练手）：

- 原始行：`@7 no action [la=ID]`——机器视角，用户看不懂。
- 第一层换算（位置）：@7 → 语料 `x = 1; y = 2 z = 3; w = 4;` 的第 8 个 token `z`，行 1 列 15（词法层可算）。
- 第二层换算（期望）：栈顶状态的动作 keys = {`;`} → "期待分号"。
- 黄金句式：**`第 1 行第 15 列：期待 ';'，遇到标识符 'z'（是否漏了分号？）`**——括号里那句是修复建议（可选），其置信度讨论见 FAQ 第一条。
- 反例（不要这样报）：`syntax error`——没有位置、没有期望、没有建议，等于让用户自己重写编译器。

四条经验律与实例演算合起来就是"诊断质量"的全部教学：**位置、期望、实际、（可选）建议**四件套，缺一件都让用户的下一分钟更难。

## 10.6　前端工程收束：恢复策略的选型表

| 场景 | 推荐策略 | 理由 |
|---|---|---|
| 教学编译器 | 恐慌模式 + 语句同步 | 二十行代码，覆盖 90% 场景 |
| yacc/bison 项目 | error 记号（声明式） | 框架唯一官方姿势；同步点写在文法里可维护 |
| ANTLR 项目 | 错误监听器 + 手写同步回调 | 框架给回调不給算法；策略自己写 |
| 手写递归下降 | 过程级同步集（FIRST ∪ FOLLOW） | 每个过程自带恢复边界——第 6 章结构的红利 |
| IDE 增量分析 | 短语级 + 容错文法 | 丢 token 会破坏增量缓存；最小修复保位置 |

表的最后一行是第 9.8 节"工业前端手写"的续篇：**增量解析要保 token 位置稳定，生成器的恢复策略（丢弃式）天然冲突**——这是 lsp-era 手写派的又一票。

表格逐行注解：

- 教学行：本章的 Panic 就是它——二十行代码的出处是 recover.cpp 的一个 case 分支。
- bison 行：error 记号是声明式的，同步点改动 = 文法改动 = 可 diff、可 review——工程属性好。
- ANTLR 行：框架给了 `reportError`/`recoverInline` 钩子但不管算法——策略空缺由用户填，填得差就级联。
- 手写行：第 6 章的每个过程自带 FIRST ∪ FOLLOW 同步集——**结构即恢复边界**，这是递归下降最被低估的红利。
- IDE 行：增量缓存按 token 区间索引，丢弃 token = 缓存失效——短语级的"最小修复"是唯一不破坏区间的档位。

五行合成一句：**恢复策略的选型由"谁拥有 token 位置的决定权"决定**——批处理编译器可以丢、IDE 不能丢。

## 10.7　驱动与对账

### 10.7.1　驱动全文

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 10 章驱动（无参运行，走"简单程序"对账协议）：
//   S2 检测点对照（LL vs LR，None 模式）→ S3 级联账（TokenDel vs Panic）→
//   S4 error 记号恢复（归约续行）→ S5 恐慌抢救求值 → S6 短语级步数有界。
#include "demo.hpp"
#include "recover.hpp"

#include <iostream>

namespace {

using tip::LexTok;
using tip::MiniLex;
using tip::MiniYacc;

std::vector<std::pair<std::string, std::string>> toPairs(const std::vector<LexTok> &ts) {
    std::vector<std::pair<std::string, std::string>> out;
    for (const auto &t : ts) out.push_back({t.kind, t.text});
    return out;
}
std::vector<std::string> toKinds(const std::vector<LexTok> &ts) {
    std::vector<std::string> out;
    for (const auto &t : ts) out.push_back(t.kind);
    return out;
}

MiniYacc makeCalc(tip::CalcEnv &env) {
    MiniYacc y(tip::calcRules(env, 2), "prog",
               {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN"});
    y.setPrec("+", 1, tip::YaccAssoc::Left);
    y.setPrec("-", 1, tip::YaccAssoc::Left);
    y.setPrec("*", 2, tip::YaccAssoc::Left);
    y.setPrec("/", 2, tip::YaccAssoc::Left);
    y.setPrec("^", 3, tip::YaccAssoc::Right);
    return y;
}

}  // namespace

int main() {
    MiniLex lx(tip::calcLexRules(), tip::calcAlphabet());
    std::cout << "[lex] " << lx.stats() << "\n";

    // ---------- S2 检测点对照：LL 与 LR 谁先看见错误 ----------
    std::cout << "== S2 detection points ==\n";
    tip::LLGrammar llg = tip::calcLL();   // LL1 持文法引用——临时量会被悬垂
    tip::LL1 ll(llg);
    ll.computeFirst();
    ll.computeFollow();
    ll.buildTable(true);
    tip::CalcEnv env0;
    MiniYacc lr = makeCalc(env0);
    const char *bad[] = {
        "x = ;", "print 2+;", "x = 2", "(x = 4);", "x = (2+;",
        "x = )2(; ", "x = 2+*3;", "print;", "x = 2 3;", "print 4 5;",
    };
    int le = 0, tie = 0, total = 0;
    for (const char *p : bad) {
        auto llr = llParse(ll, toKinds(lx.scan(p)), tip::LLRecover::None);
        auto lrr = lr.parseRecover(toPairs(lx.scan(p)), MiniYacc::Recover::None);
        ++total;
        bool lrFirst = lrr.detectPos < llr.detectPos;
        bool same = lrr.detectPos == llr.detectPos;
        le += lrFirst;
        tie += same;
        std::cout << "  ll@" << (llr.detectPos < 0 ? -1 : llr.detectPos)
                  << " lr@" << lrr.detectPos << (same ? "  ==" : (lrFirst ? "  LR<" : "  LL<"))
                  << "  [" << p << "]\n";
    }
    std::cout << "[stats] total=" << total << " equal=" << tie << " lr-earlier=" << le
              << " ll-earlier=" << (total - tie - le) << "\n";

    // ---------- S3 级联账：朴素删除制造假错误，恐慌模式只报真错误 ----------
    std::cout << "== S3 cascade ==\n";
    const std::string cascade = "x = 1; y = 2 z = 3; w = 4;";
    {
        tip::CalcEnv e1;
        MiniYacc y1 = makeCalc(e1);
        auto del = y1.parseRecover(toPairs(lx.scan(cascade)), MiniYacc::Recover::TokenDel);
        std::cout << "[LR TokenDel] diags=" << del.diags.size()
                  << " accept=" << del.accept << "\n";
        for (const auto &d : del.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        tip::CalcEnv e2;
        MiniYacc y2 = makeCalc(e2);
        auto pan = y2.parseRecover(toPairs(lx.scan(cascade)), MiniYacc::Recover::Panic);
        std::cout << "[LR Panic   ] diags=" << pan.diags.size()
                  << " accept=" << pan.accept << "\n";
        for (const auto &d : pan.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        auto lldel = llParse(ll, toKinds(lx.scan(cascade)), tip::LLRecover::TokenDel);
        auto llpan = llParse(ll, toKinds(lx.scan(cascade)), tip::LLRecover::Panic);
        std::cout << "[LL TokenDel] diags=" << lldel.diags.size()
                  << " accept=" << lldel.accept << "\n";
        std::cout << "[LL Panic   ] diags=" << llpan.diags.size()
                  << " accept=" << llpan.accept << "\n";
    }

    // ---------- S4 error 记号：恢复后续行，归约日志保留后半 ----------
    std::cout << "== S4 error production ==\n";
    {
        tip::CalcEnv e;
        MiniYacc ye(tip::calcRulesErr(e), "prog",
                    {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN", "error"});
        ye.setPrec("+", 1, tip::YaccAssoc::Left);
        ye.setPrec("-", 1, tip::YaccAssoc::Left);
        ye.setPrec("*", 2, tip::YaccAssoc::Left);
        ye.setPrec("/", 2, tip::YaccAssoc::Left);
        ye.setPrec("^", 3, tip::YaccAssoc::Right);
        const std::string corpus = "x = 1; y = print 2; z = 3; print z;";
        auto run = ye.parseRecover(toPairs(lx.scan(corpus)), MiniYacc::Recover::ErrorProd);
        std::cout << "[accept] " << run.accept << " diags=" << run.diags.size() << "\n";
        for (const auto &d : run.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        std::cout << "[reductions after recovery]\n";
        bool seenErr = false;
        for (const auto &s : run.reduceLog) {
            if (s.find("error") != std::string::npos) seenErr = true;
            if (seenErr) std::cout << "    " << s << "\n";
        }
        std::cout << "[printed]";
        for (const auto &p : e.printed) std::cout << " " << p;
        std::cout << "\n";
        // 对照：前缀语料（q = 0; 打头，让尾部同样以 prog → prog stmt 滚雪球）
        tip::CalcEnv e2;
        MiniYacc y2(tip::calcRulesErr(e2), "prog",
                    {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN", "error"});
        auto tail = y2.parseRecover(toPairs(lx.scan("q = 0; z = 3; print z;")), MiniYacc::Recover::None);
        std::vector<std::string> tailLog(tail.reduceLog.end() - 6, tail.reduceLog.end());
        // 取 run.reduceLog 的最后 6 条比对（error 语句之后的 z/print 两条语句）
        bool tailEq = run.reduceLog.size() >= 6;
        if (tailEq) {
            std::vector<std::string> runTail(run.reduceLog.end() - 6, run.reduceLog.end());
            tailEq = runTail == tailLog;
        }
        std::cout << "[tail match] " << (tailEq ? 1 : 0) << "\n";
    }

    // ---------- S5 恐慌抢救：恢复后无错部分照常求值 ----------
    std::cout << "== S5 panic salvage ==\n";
    {
        tip::CalcEnv e;
        MiniYacc y = makeCalc(e);
        const std::string corpus = "x = 1; y = 2 z = 3; w = 4; print x; print w;";
        auto run = y.parseRecover(toPairs(lx.scan(corpus)), MiniYacc::Recover::Panic);
        std::cout << "[accept] " << run.accept << " diags=" << run.diags.size() << "\n";
        std::cout << "[printed]";
        for (const auto &p : e.printed) std::cout << " " << p;
        std::cout << "\n";
        // 对照：手工期望——x=1 与 w=4 应当照常打印（y 语句被恢复吞掉）
        tip::CalcEnv e2;
        MiniYacc y2 = makeCalc(e2);
        auto clean = y2.parseRecover(toPairs(lx.scan("x = 1; print x; w = 4; print w;")),
                                     MiniYacc::Recover::None);
        (void)clean;
        std::cout << "[expect match] " << (e.printed == e2.printed ? 1 : 0) << "\n";
    }

    // ---------- S6 短语级：局部修复的步数有界 ----------
    std::cout << "== S6 phrase bounded ==\n";
    {
        auto jitter = llParse(ll, toKinds(lx.scan("print ((();")), tip::LLRecover::Phrase);
        std::cout << "[phrase on 'print ((();'] diags=" << jitter.diags.size()
                  << " steps=" << jitter.steps << " accept=" << jitter.accept << "\n";
        auto deep = llParse(ll, toKinds(lx.scan("x = (((((((1; print x;")), tip::LLRecover::Phrase);
        std::cout << "[phrase on deep parens] diags=" << deep.diags.size()
                  << " steps=" << deep.steps << " accept=" << deep.accept << "\n";
        std::cout << "[bounded] " << (jitter.steps < 200 && deep.steps < 200 ? 1 : 0) << "\n";
    }
    return 0;
}
```

main 五节对应五组断言：

1. **S2 检测点对照**：十条坏语料，LL（None）与 LR（None）的 detectPos 逐条打印，统计 equal/lr-earlier/ll-earlier。
2. **S3 级联账**：缺分号语料在 TokenDel/Panic × LR/LL 四格的 diags 数——3/1/3/1。
3. **S4 error 记号**：恢复后续行的归约日志 + 与无错版尾部的逐条比对（`[tail match]`）+ 求值结果。
4. **S5 恐慌抢救**：恢复后 `print x; print w;` 输出 1、4——与等价无错程序 `x = 1; print x; w = 4; print w;` 的输出**逐字节对账**（`[expect match]`）。
5. **S6 有界性**：两条深错语料的 Phrase 步数（28、67）+ 上限断言。

#### 10.7.1a　main 逐节走读

- 工具层（匿名命名空间）：`toPairs/toKinds`——同一 token 流的两种视图（LR 要 text 填 yylval、LL 只要种类）；`makeCalc`——第 9 章的标准口径原样搬来（五条 setPrec）。
- 开场：MiniLex 构造 + stats 一行——词法体检（与第 9 章同源同数：15 规则 47 字符 20 态）。
- S2 节：`bad[]` 十条坏语料的选取讲究——覆盖五种死法：
  - 表达式缺位（`x = ;`、`print 2+;`、`print;`）；
  - 语句不完整（`x = 2` 缺 `;`）；
  - 语句起点非法（`(x = 4);`——括号开不了语句）；
  - 括号不配（`x = (2+;`、`x = )2(;`）；
  - 双表达式粘连（`x = 2 3;`、`print 4 5;`）。
  每条跑 LL(None) 与 LR(None)，打印 `ll@i lr@j` 与关系标记（==/LR</LL<），末行汇总。
- S3 节：级联语料 `x = 1; y = 2 z = 3; w = 4;` 四格（TokenDel/Panic × LR/LL）——TokenDel 的诊断逐条打印（级联现场的三连 @7/@8/@9）；**四台分析器各自独立构造**（env 各一份），避免动作副作用串味。
- S4 节：error 文法的构造（terminals 多注册一个 `"error"`）+ 语料 `x = 1; y = print 2; z = 3; print z;`；归约日志从含 error 的那条起打印（`seenErr` 标记）；尾部对照——无错版加前缀 `q = 0;` 让两边同为"滚雪球"形态（坑五的修复），取最后 6 条逐条比对。
- S5 节：抢救语料 `... print x; print w;` 与等价无错程序**输出对账**——恢复的语义损失直接可量（丢了 y 语句、保住其余）。
- S6 节：两条深错语料的 Phrase 步数 + `< 200` 断言——有界性的实证口径。

### 10.7.2　两台恢复器的实现要点

#### 10.7.2a　recover.cpp 逐函数走读

- `llParse(ll, input, mode)` 的骨架与第 6 章 predict 同构：栈存符号（底 `$` 顶开始符号）、输入尾部补 `$`、循环查表展开或匹配消费。
- `diag` 闭包：统一的消息格式 `[top=X la=Y]` + 首错位置 `detectPos` 的记录——S2 对照表的数据源。
- 终结符分支（匹配/不匹配）：
  - 匹配：弹栈、前进、`noConsume` 清零——守卫的复位点；
  - 不匹配按模式分派：None 停；TokenDel 删输入；Panic **弹栈**（假定输入缺了它）；Phrase 弹栈但计守卫。
- 非终结符分支（查表）：
  - 有表项：弹 A、逆序压 rhs——正常展开；
  - 无表项按模式分派：None 停；TokenDel 删输入；Panic **丢输入到 FOLLOW(A) 再弹 A**；Phrase 看 la 是否已在 FOLLOW(A)——在则弹 A（ε 删除修复），不在则删输入。
- Phrase 守卫的精确定义：`++noConsume > 2` 时**强制吃一个输入 token** 并清零——两种修复（弹终结符/弹非终结符）都不消耗输入，连续两次后必须前进，否则"假定缺 X"的修复可以无限叠加（每次都"再缺一个"）。
- 保险丝 `steps > 4000`：对单调修复是死代码，对未来的非单调扩展是安全网——留一行买心安。

#### 10.7.2b　yacc.cpp 的 parseRecover 逐分支走读（第 9 章副本的扩展）

- 与 parse 的共享骨架抽成了三个 lambda：
  - `act(s, k)`——查 action 表的私有封装（恢复逻辑要反复试探"这个状态能不能吃这个 token"）；
  - `shiftCur()`——移进当前 token 并填 yylval（与 parse 逐字相同）；
  - `reduceBy(p)`——归约五步 + 日志（与 parse 逐字相同，**动作照跑**——恢复中的归约照常计算）。
- 四个错误分支：
  - `None`：记诊断、return——对照组；
  - `TokenDel`：记诊断、`++i` 跳过当前 token——一条 `if (kind == "$") return` 防止删掉结尾哨兵后死循环；
  - `Panic`（input-first）：
    - 第一优先：**丢输入直到当前状态能接受**——栈不动，栈的期望就是同步集；
    - 兜底：丢到 `$` 仍不行才**弹栈**重试一轮（某些错误连"丢输入"都救不了，如开头就非法的 `(x = 4);`）；
    - 弹到底仍不行：return——放弃；
  - `ErrorProd`（yacc 官方三步）：
    - 弹栈直到某状态对 `error` 有 Shift 动作（找不到 = 文法没写 error 规则 → 放弃）；
    - 移进 error（值栈压 Empty——伪 token 无值）；
    - 丢输入直到表给出动作（通常是 error 规则的后续符号）。
- **error 是普通终结符**的全部含义：MiniYacc 构造时把它列进 terminals，LALR 构造器为它照常造 shift 列与 goto——第 9 章机器一行未改。伪终结符设计让"恢复点"成为**文法数据**而非驱动器特例，这是 yacc 四十年不换这套协议的原因。
- 值栈在恢复中的命运：弹栈分支同步弹值（`stateStack.pop_back(); valueStack.pop_back();` 成对出现）——双栈平行不变式在恢复里也必须维持，破一对就是内存对不齐的深渊。

#### 10.7.2c　demo 新件走读（calcLL 与 calcRulesErr）

- `calcLL()`：18 条产生式的消左递归版——`expr → term expr'`、`expr' → ± term expr' | ε` 的第 6 章手法直接落地。它和 09 章的左递归版**语言等价**（S2 的 10/10 打平在文法层的前提）。
- `calcRulesErr(env)`：抄 calcRules(env, 2) 后**尾部追加**一条 `stmt → error ';'`——副本演进纪律（只尾部追加）的又一次实践。注意 terminals 注册表里要加 `"error"`——伪终结符也要登记在案，否则悬空符号检查会拦它。
- MiniLex 与词法规则表：09 章副本零改动（错误语料用的都是合法 token——词法层的错误处理是另一章的事，见练习 5 的伏笔）。

### 10.7.3　期望输出逐段解读

```text
; expected: expected/output.txt
[lex] rules=15 alphabet=47 dfa_states=20
== S2 detection points ==
  ll@2 lr@2  ==  [x = ;]
  ll@3 lr@3  ==  [print 2+;]
  ll@3 lr@3  ==  [x = 2]
  ll@0 lr@0  ==  [(x = 4);]
  ll@5 lr@5  ==  [x = (2+;]
  ll@2 lr@2  ==  [x = )2(; ]
  ll@4 lr@4  ==  [x = 2+*3;]
  ll@1 lr@1  ==  [print;]
  ll@3 lr@3  ==  [x = 2 3;]
  ll@2 lr@2  ==  [print 4 5;]
[stats] total=10 equal=10 lr-earlier=0 ll-earlier=0
== S3 cascade ==
[LR TokenDel] diags=3 accept=1
    @7 no action [la=ID]
    @8 no action [la==]
    @9 no action [la=NUM]
[LR Panic   ] diags=1 accept=1
    @7 no action [la=ID]
[LL TokenDel] diags=3 accept=1
[LL Panic   ] diags=1 accept=1
== S4 error production ==
[accept] 1 diags=1
    @6 no action [la=print]
[reductions after recovery]
    14: stmt → error ;
    1: prog → prog stmt
    12: expr → NUM
    3: stmt → ID = expr ;
    1: prog → prog stmt
    13: expr → ID
    4: stmt → print expr ;
    1: prog → prog stmt
[printed] 3
[tail match] 1
== S5 panic salvage ==
[accept] 1 diags=1
[printed] 1 4
[expect match] 1
== S6 phrase bounded ==
[phrase on 'print ((();'] diags=3 steps=28 accept=1
[phrase on deep parens] diags=17 steps=67 accept=1
[bounded] 1
```

**S2 段（13 行）**：十行对照全部 `==`——LL 与 LR 在忠实文法上检测能力打平（§10.1.2 的讨论）；`[stats] total=10 equal=10 lr-earlier=0 ll-earlier=0`。逐语料读检测位置（token 下标从 0 数）：

- `x = ;` → @2：分号出现在 expr 的 FIRST 之外——**第三个 token 就报**，最经典的"缺表达式"。
- `print 2+;` → @3：加号后期待 term，分号进不了 FIRST(factor)。
- `x = 2` → @3：这里 @3 是**结尾哨兵 $ 的下标**——语句没结束就到了输入尾，"缺分号"的机器形态。
- `(x = 4);` → @0：括号开不了语句（FIRST(stmt) = {ID, print}）——最左检测，任何恢复器都只能丢到下一个同步点。
- `x = (2+;` → @5：`(`、2、`+` 都合法，分号进不了 FIRST(factor)——**括号不配的检测要等括号内表达式走完**才见分晓。
- `x = )2(;` → @2：右括号开不了 factor。
- `x = 2+*3;` → @4：`+` 后期待 term，`*` 进不了 FIRST(factor)——运算符粘连。
- `print;` → @1：print 后期待 expr。
- `x = 2 3;` → @3：expr 归约后期待 `;`，数字来了——**双表达式粘连**（缺运算符）。
- `print 4 5;` → @2：同上，print 版。

十个位置的共同模式：**检测点 = "FIRST/FOLLOW 说了算"的第一个位置**——要么 token 不在谁的 FIRST 里（缺东西），要么不在谁的 FOLLOW 里（多了东西）。这张逐条解读表也是"手写检测位置预测"的答案页：先自己数，再对输出。

**S3 段（10 行）**：TokenDel 的三条诊断 @7/@8/@9 是"删 z、删 =、删 3"的级联现场；Panic 一条 @7——丢了 `z = 3` 三个 token 迎回 `;`。LL 侧同样 3/1。**四格数据完全对称**——两种驱动器的级联病理与药方同构。

**S4 段（12 行）**：诊断 @6；恢复后的归约日志 8 条——`14: stmt → error ;` 是 error 规则的归约（伪产生式进了日志，与普通归约无异）；随后 `z = 3`、`print z` 的归约序列与无错版逐条一致；`[printed] 3` 是 z 的值；`[tail match] 1`。

**S5 段（4 行）**：诊断 1 条；`[printed] 1 4`——x 与 w 的输出保住（y 语句被恢复吞掉，变量 y 仍在表中）；`[expect match] 1`——与无错等价程序逐字节对账。

**S6 段（4 行）**：`print ((();` 三括号语料 28 步 3 诊断；深括号 67 步 17 诊断——**每次修复单调前进**（吃输入或弹栈），步数必然有界；`[bounded] 1`。

**全部语料速查表**（正文出现过的每条语料与其归宿）：

| 语料 | 出现于 | 用途 | 关键数字 |
|---|---|---|---|
| `x = ;` 等 10 条坏语料 | S2 | 检测点对照 | 全部 `==` |
| `x = 1; y = 2 z = 3; w = 4;` | S3 | 级联账 | TokenDel 3 / Panic 1 |
| 同上 | S5 | 抢救求值 | printed = 1 4 |
| `x = 1; y = print 2; z = 3; print z;` | S4 | error 记号 | tail match = 1、printed = 3 |
| `q = 0; z = 3; print z;` | S4 | 尾部对照（无错版） | 尾 6 条归约 |
| `x = 1; print x; w = 4; print w;` | S5 | 输出对账（无错版） | expect match = 1 |
| `print ((();` | S6 | 短语级抖动 | 28 步 3 诊断 |
| `x = (((((((1; print x;` | S6 | 深括号有界 | 67 步 17 诊断 |

八条语料撑起五组断言——每条都复用（S3 语料在 S5 再用、S4 的对照版兼作形状对齐教具），这是语料设计的经济法：**一鱼多吃，但每吃的哪一口要能独立验证**。

**五组断言的覆盖矩阵**（哪条输出行证哪条断言）：

| 断言 | 证人行 | 通过判据 |
|---|---|---|
| 检测点对照 | S2 十行 + stats | lr-earlier ≥ 0 且 ll-earlier = lr-earlier（本语料全等） |
| 级联抑制 | S3 四行 | TokenDel=3、Panic=1（LR/LL 双侧） |
| error 续行 | S4 accept/reductions/tail | accept=1、diags=1、tail match=1 |
| 恐慌抢救 | S5 printed/expect | printed = `1 4`、expect match=1 |
| 短语有界 | S6 bounded | steps < 200（实测 28/67） |

矩阵的最后一列是"通过判据"而非"手抄期望"——它们同时是 check_example 的对账口径（期望文件逐字节锁定）与读者的自查清单。

### 10.7.5　FAQ：恢复器的常见疑问

- **问：为什么不直接报告"缺了分号"？** 答：那是**修复建议**，比诊断高一级。从检测点（期待 `;` 遇到 ID）推"缺分号"需要启发式（插入成本最低的修复）——短语级恢复已经朝这个方向走（插入 `;` 的修复），但把它升格为用户建议需要置信度控制（误报"缺分号"而实际缺的是别的，比不报更糟）。
- **问：恢复会不会把后面的错误掩盖掉？** 答：会——同步丢弃越激进，掩盖越多（Panic 丢了 `z = 3`，若里面还有第二个错误就一起没了）。这是恢复的三角权衡：**级联抑制 vs 错误覆盖 vs 语义抢救**，没有全赢的策略。
- **问：ErrorProd 的 error 规则会与优先级冲突吗？** 答：不会——error 规则 `stmt → error ';'` 的最右终结符是 `;`（无声明级），它只在"没有任何正常动作"时被启用（恢复分支），不参与正常分析的仲裁。
- **问：LL 与 LR 的恢复谁更强？** 答：本章数据：级联抑制打平（3→1 双侧）、LL 的 FOLLOW 同步与 LR 的状态期望同步在本语料等价。理论差异在**恢复粒度**：LL 弹的是非终结符（结构单元明确），LR 弹的是状态（结构信息隐含在项集里）——error 记号是把 LR 的隐含结构显式化的官方工具。
- **问：真实的编译器还有什么本章没有的？** 答：三样——**多错误会话**（IDE 一次编辑后重跑全部诊断而非增量修补）、**容错 AST**（错误节点进树，让补全/高亮在残缺树上继续）、**错误分类学**（语法错/词法错/语义错的统一编号体系）。它们都是恢复策略的上层建筑，地基仍是本章的四档火力。

### 10.7.6　恢复器与 IDE 时代的对接

本章的四档火力诞生于批处理编译的年代（一次编译、一份报告），而今天的分析器活在 IDE 里（每次按键、即时反馈）。对接引出三个现代议题，本教程在相应章节会回来展开：

- **容错 AST（走向第 12 章）**：恢复后的分析应当产出一棵**带洞的树**——`y = <error>` 作为节点进 AST，作用域检查与补全在洞周围继续工作。本章的值栈恢复已经保住了 `z = 3; print z;` 的求值（S4/S5），那正是容错 AST 的语义面；把"求值照跑"升级为"树照建"只差动作里建节点而非算值。
- **增量重析（走向选型）**：编辑一个 token 后，理想分析器只重析受影响的区间——这要求恢复**永不移动未编辑 token 的位置**。丢弃式恢复（Panic 丢三个 token）会连累后续所有 token 的位置映射——IDE 派偏爱短语级的"最小修复"正是为了位置稳定（第 10.6 节选型表最后一行的深因）。
- **诊断即服务（走向 LSP 时代）**：诊断从编译器的打印变成结构化消息（位置/严重度/修复建议三件套，LSP 的 Diagnostic 协议）——本章 diag 结构的 (pos, msg) 是它的直系雏形，练习 5 的黄金句式就是补上第三件。

三个议题的公共底座不变：**检测（栈顶状态）—恢复（四档火力）—续行（归约接上）**。195 页的 L 书写这些时（1997 年），IDE 议题只占了半页脚注；今天它占前端工程的一半——机制没变，座次变了。

### 10.7.7　三层验证在本章的实战记录

本章示例经过的三道验证闸门与各自抓过什么（教程方法论的实例注脚）：

- **第一层 `example_build.sh`**（编译，-Wall -Wextra -Werror）：抓过坑二/坑三（双副本撞名的重定义错）——编译期是最好的守门员，撞名连链接都到不了。
- **第二层 `check_example.py`**（运行对账 expected）：抓过坑四的前身——Panic 恢复次序错时诊断数是 2 不是 1，期望文件一对就现形；S4 的 tail match=0（坑五）也是这一层报的。
- **第三层 `check_docs.py`**（内嵌字节校验）：保证正文里的代码与示例目录零漂移——本章 16 个围栏、2800 余行内嵌全部对上。
- 三层之外的第四道（人肉）：悬垂引用（坑一）表现为 bad_alloc 崩溃——第一层不报（编译合法）、第二层直接崩（连输出都没有）——**运行期 UB 是三层验证的盲区**，gdb 栈一指就破（崩溃在 follow.at）。
- 实战结论：**编译错 < 对账错 < 崩溃 < 静默错**，排查成本依次翻倍；本章五坑恰好覆盖了前三种，静默错（如恢复逻辑悄悄丢语句）靠 S5 的输出对账兜住——这就是"每章至少一条语义对账断言"的由来。

### 10.7.4　源码导览与副本清单

| 文件 | 行数 | 角色 | 相对原章的改动 |
|---|---|---|---|
| src/llgrammar.hpp/cpp | 41+65 | 06 副本：LL 文法表示 | Grammar→LLGrammar（撞名规避） |
| src/ll1.hpp/cpp | 54+151 | 06 副本：FIRST/FOLLOW/LL(1) 表 | ParseResult→LLParseResult（同上） |
| src/re.hpp/cpp | 103+441 | 09 副本：词法自动机 | 无 |
| src/lr1.hpp/cpp | 84+263 | 09 副本：LALR 造表 | 无 |
| src/yacc.hpp/cpp | 144+321 | 09 副本：值栈驱动器 | **扩展 parseRecover 四模式（本章正题）** |
| src/recover.hpp/cpp | 34+104 | 新：LL 侧三模式驱动 | — |
| src/demo.hpp/cpp | 48+173 | 09 裁剪 + calcLL/calcRulesErr | 新增 LL 文法与 error 文法 |
| src/main.cpp | 174 | 驱动 | — |

改名两处、扩展一处，其余零漂移——**撞名是双副本同处的必然税**（06 与 08 的 Grammar/ParseResult 同名），改名是最低侵入的解。

全部源文件与期望输出按导览次序内嵌如下（10.7.2 的实现要点对照读）：

```cpp
// file: src/llgrammar.hpp
// file: src/llgrammar.hpp
// 第 6 章配套：LL(1) 分析的“文法即数据”。
// 两个内置文法都是绿龙第 5 章的原装货：
//   expr  —— 文法 (5.9)，消除了左递归的经典表达式文法；
//   stmt  —— 文法 (5.11) 的 TIP 风格化身，自带悬挂 else 冲突。
#ifndef TIP_LL_GRAMMAR_HPP
#define TIP_LL_GRAMMAR_HPP

#include <string>
#include <vector>

namespace tip {

struct Production {
    std::string lhs;
    std::vector<std::string> rhs;   // 空向量 = ε 产生式
};

struct LLGrammar {
    std::string start;
    std::vector<std::string> nonterms;
    std::vector<std::string> terms;   // 不含 "$"；"$" 是输入与栈的公共同界符
    std::vector<Production> prods;

    bool isTerm(const std::string &s) const;
    bool isNonterm(const std::string &s) const;
    std::string show(const Production &p) const;
};

// E → T E' ; E' → + T E' | ε ; T → F T' ; T' → * F T' | ε ; F → INT|IDENT|INPUT|( E )
// 与绿龙 (5.9) 同构，只是 id 换成了 TIP 的 INT/IDENT/INPUT 三种“原子”。
LLGrammar exprLLGrammar();

// stmt  → if ( IDENT ) stmt stmt'
// stmt' → else stmt | ε
// 对应绿龙 (5.11)：M[stmt', else] 双定义——悬挂 else 的教科书现场。
LLGrammar stmtLLGrammar();

}  // namespace tip

#endif  // TIP_LL_GRAMMAR_HPP
```

```cpp
// file: src/llgrammar.cpp
// file: src/grammar.cpp
#include "llgrammar.hpp"

#include <sstream>

namespace tip {

bool LLGrammar::isTerm(const std::string &s) const {
    for (const auto &t : terms)
        if (t == s) return true;
    return false;
}

bool LLGrammar::isNonterm(const std::string &s) const {
    for (const auto &t : nonterms)
        if (t == s) return true;
    return false;
}

std::string LLGrammar::show(const Production &p) const {
    std::ostringstream os;
    os << p.lhs << " ->";
    if (p.rhs.empty()) {
        os << " ε";
    } else {
        for (const auto &x : p.rhs) os << ' ' << x;
    }
    return os.str();
}

LLGrammar exprLLGrammar() {
    LLGrammar g;
    g.start = "expr";
    g.nonterms = {"expr", "expr'", "term", "term'", "factor"};
    g.terms = {"INT", "IDENT", "INPUT", "LPAREN", "RPAREN", "PLUS", "STAR"};
    g.prods = {
        {"expr", {"term", "expr'"}},                    // 1
        {"expr'", {"PLUS", "term", "expr'"}},           // 2
        {"expr'", {}},                                  // 3
        {"term", {"factor", "term'"}},                  // 4
        {"term'", {"STAR", "factor", "term'"}},         // 5
        {"term'", {}},                                  // 6
        {"factor", {"INT"}},                            // 7
        {"factor", {"IDENT"}},                          // 8
        {"factor", {"INPUT"}},                          // 9
        {"factor", {"LPAREN", "expr", "RPAREN"}},       // 10
    };
    return g;
}

LLGrammar stmtLLGrammar() {
    LLGrammar g;
    g.start = "stmt";
    g.nonterms = {"stmt", "stmt'"};
    g.terms = {"IF", "LPAREN", "IDENT", "RPAREN", "ELSE"};
    g.prods = {
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt", "stmt'"}},  // 1
        {"stmt", {"IDENT"}},                                             // 2
        {"stmt'", {"ELSE", "stmt"}},                                     // 3
        {"stmt'", {}},                                                   // 4
    };
    return g;
}

}  // namespace tip
```

```cpp
// file: src/ll1.hpp
// file: src/ll1.hpp
// 第 6 章配套：FIRST/FOLLOW 的不动点计算、LL(1) 表构造与冲突检测。
#ifndef TIP_LL1_HPP
#define TIP_LL1_HPP

#include "llgrammar.hpp"

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

inline const std::string EPS = "ε";   // FIRST 集里的空串标记
inline const std::string DOLLAR = "$";

struct LL1 {
    const LLGrammar &g;
    std::map<std::string, std::set<std::string>> first;    // 非终结符 → FIRST
    std::map<std::string, std::set<std::string>> follow;   // 非终结符 → FOLLOW
    // (非终结符, 终结符或$) → 产生式下标（0 起）。多定义时保留胜者并记入 conflicts。
    std::map<std::pair<std::string, std::string>, int> table;
    // 冲突清单：(格子, 候选产生式下标们, 胜者)
    struct Conflict {
        std::string A, a;
        std::vector<int> candidates;
        int winner;
    };
    std::vector<Conflict> conflicts;

    explicit LL1(const LLGrammar &g);

    // FIRST(序列)：逐项吸收，遇 ε 项继续，全 ε 则含 ε。
    std::set<std::string> firstOf(const std::vector<std::string> &beta) const;

    void computeFirst();    // 规则迭代到不动点（工作表思想的又一现身）
    void computeFollow();
    void buildTable(bool resolveClosestElse);
};

// 表驱动预测分析器（绿龙 Fig 5.23 的程序化）。
// 副本改动：ParseResult → LLParseResult（避开 08 章副本的同名结构）。
struct LLParseResult {
    bool ok = false;
    std::vector<int> usedProds;      // 最左推导所用的产生式序列
    std::string error;               // 失败时的诊断（供 expected/errors 对账）
    size_t consumed = 0;             // 失败时已消耗的 token 数
};

LLParseResult predict(const LL1 &ll, const std::vector<std::string> &input);

}  // namespace tip

#endif  // TIP_LL1_HPP
```

```cpp
// file: src/ll1.cpp
// file: src/ll1.cpp
// 第 6 章配套：LL(1) 引擎实现——FIRST/FOLLOW/表/冲突/预测分析。
#include "ll1.hpp"

#include <cassert>

namespace tip {

LL1::LL1(const LLGrammar &g) : g(g) {}

// ---------- FIRST ----------
// 绿龙的口径：对每个非终结符反复套用三条规则，直到没有任何集合再变大。
// 这是“从下界出发、单调上升、有限高度”的迭代——第 30 章的不动点骨架。
std::set<std::string> LL1::firstOf(const std::vector<std::string> &beta) const {
    std::set<std::string> out;
    bool allEps = true;
    for (const auto &x : beta) {
        std::set<std::string> fx;
        if (g.isTerm(x) || x == DOLLAR) {
            fx = {x};
        } else {
            auto it = first.find(x);
            if (it != first.end()) fx = it->second;
        }
        for (const auto &t : fx)
            if (t != EPS) out.insert(t);
        if (!fx.count(EPS)) {
            allEps = false;
            break;
        }
    }
    if (allEps) out.insert(EPS);
    return out;
}

void LL1::computeFirst() {
    for (const auto &A : g.nonterms) first[A] = {};
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            auto &F = first[p.lhs];
            size_t before = F.size();
            for (const auto &t : firstOf(p.rhs)) F.insert(t);
            if (F.size() != before) changed = true;
        }
    }
}

// ---------- FOLLOW ----------
void LL1::computeFollow() {
    for (const auto &A : g.nonterms) follow[A] = {};
    follow[g.start].insert(DOLLAR);
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            for (size_t i = 0; i < p.rhs.size(); ++i) {
                const auto &B = p.rhs[i];
                if (!g.isNonterm(B)) continue;
                auto &FB = follow[B];
                size_t before = FB.size();
                // 规则 2：后面紧跟的串的 FIRST（去掉 ε）进 FOLLOW
                std::vector<std::string> rest(p.rhs.begin() + i + 1, p.rhs.end());
                auto fr = firstOf(rest);
                for (const auto &t : fr)
                    if (t != EPS) FB.insert(t);
                // 规则 3：尾部可推空，则左部的 FOLLOW 传递下来
                if (fr.count(EPS) || rest.empty()) {
                    for (const auto &t : follow[p.lhs]) FB.insert(t);
                }
                if (FB.size() != before) changed = true;
            }
        }
    }
}

// ---------- 表构造（绿龙 Algorithm 5.4） ----------
namespace {
// “最近 else”消解：候选里若有右端以 a 开头者（即会吃掉当前 token 的产生式，
// 相当于移进 else），选它——绿龙对文法 (5.11) 的经典裁决：
// 选 S'→eS 让 else 与最内层 then 配对；选 ε 会让 else 永远无法被消费。
int pickWinner(const tip::LLGrammar &g, const std::string &a,
               int oldIdx, int newIdx, bool resolveClosestElse) {
    if (!resolveClosestElse) return oldIdx;
    if (!g.prods[oldIdx].rhs.empty() && g.prods[oldIdx].rhs[0] == a) return oldIdx;
    if (!g.prods[newIdx].rhs.empty() && g.prods[newIdx].rhs[0] == a) return newIdx;
    return oldIdx;
}
}  // namespace

void LL1::buildTable(bool resolveClosestElse) {
    auto put = [&](const std::string &A, const std::string &a, int idx) {
        auto cell = std::make_pair(A, a);
        auto it = table.find(cell);
        if (it == table.end()) {
            table[cell] = idx;
        } else if (it->second != idx) {
            int winner = pickWinner(g, a, it->second, idx, resolveClosestElse);
            conflicts.push_back({A, a, {it->second, idx}, winner});
            it->second = winner;
        }
    };
    for (size_t idx = 0; idx < g.prods.size(); ++idx) {
        const auto &p = g.prods[idx];
        auto fs = firstOf(p.rhs);
        for (const auto &a : fs)
            if (a != EPS) put(p.lhs, a, static_cast<int>(idx));
        if (fs.count(EPS))
            for (const auto &b : follow[p.lhs])
                put(p.lhs, b, static_cast<int>(idx));
    }
}

// ---------- 预测分析器（绿龙 Fig 5.23） ----------
LLParseResult predict(const LL1 &ll, const std::vector<std::string> &input) {
    LLParseResult r;
    std::vector<std::string> stack = {DOLLAR, ll.g.start};
    size_t ip = 0;
    while (true) {
        std::string X = stack.back();
        std::string a = ip < input.size() ? input[ip] : DOLLAR;
        if (X == DOLLAR && a == DOLLAR) {
            r.ok = true;
            return r;
        }
        if (ll.g.isTerm(X) || X == DOLLAR) {
            if (X == a) {
                stack.pop_back();
                ++ip;
            } else {
                r.error = "栈顶 " + X + " 期待 " + a;
                r.consumed = ip;
                return r;
            }
        } else {
            auto it = ll.table.find({X, a});
            if (it == ll.table.end()) {
                r.error = "无 " + X + " 的产生式可匹配 " + a;
                r.consumed = ip;
                return r;
            }
            stack.pop_back();
            const auto &rhs = ll.g.prods[it->second].rhs;
            for (auto rit = rhs.rbegin(); rit != rhs.rend(); ++rit) stack.push_back(*rit);
            r.usedProds.push_back(it->second);
        }
    }
}

}  // namespace tip
```

```cpp
// file: src/re.hpp
// file: src/re.hpp
// 第 5 章配套：正则表达式 → NFA → DFA → 最小 DFA 的完整流水线。
// 数据结构刻意贴着绿龙 Algorithm 3.1–3.3 的伪码走：
//   NFA 状态 = (符号, 下一状态1, 下一状态2) 三元组（ε 用 '\0' 表示）；
//   DFA 状态 = NFA 状态子集（子集构造的产物）；
//   最小化   = 按可区分性反复分割（Algorithm 3.3）。
#ifndef TIP_RE_HPP
#define TIP_RE_HPP

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 正则表达式的语法树 ----------
// 与绿龙 3.3 节的归纳定义一一对应：基础是 ε 与单符号 a，
// 归纳步是 R|S、RS、R* 三条。没有并集、差集之类的扩展运算——
// 教科书子集足够描述 TIP 的全部 token。
enum class REKind { Eps, Sym, Alt, Concat, Star };

struct RE {
    REKind kind;
    char ch = 0;                     // Kind::Sym 时有效
    std::unique_ptr<RE> lhs, rhs;    // Alt/Concat 用两个，Star 用 lhs

    static std::unique_ptr<RE> eps();
    static std::unique_ptr<RE> sym(char c);
    static std::unique_ptr<RE> alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> star(std::unique_ptr<RE> a);
};

// 把中缀正则串解析成语法树。文法（优先级：* 高于并置，并置高于 |）：
//   expr  → term ('|' term)*
//   term  → factor factor*
//   factor→ atom '*'?
//   atom  → '(' expr ')' | 字符
// 这本身就是一个 LL(1) 文法——第 6 章会正式认识它。
std::unique_ptr<RE> parseRE(const std::string &pat);

// ---------- NFA：绿龙式三元组表示 ----------
// Algorithm 3.2 保证每个状态至多两条出边，因此三元组就够。
// sym == '\0' 表示 ε 边；to2 == -1 表示没有第二条边。
struct NFA {
    struct State {
        char sym1 = 0; int to1 = -1;
        char sym2 = 0; int to2 = -1;
        bool accept = false;
    };
    std::vector<State> st;
    int start = 0, finish = 0;   // Thompson 构造保证单一入口/单一出口
};

// Thompson 构造（Algorithm 3.2）：按语法树归纳地拼装。
NFA thompson(const RE &re);

// ---------- DFA ----------
struct DFA {
    // 状态编号 0..n-1；trans[s][c] 缺席（-1）表示该输入下无转移。
    std::vector<std::map<char, int>> trans;
    int start = 0;
    std::vector<int> color;   // 0 = 非接受；k>0 = 第 k 优先级的接受类
    int states() const { return static_cast<int>(trans.size()); }
};

// 子集构造（Algorithm 3.1）。alphabet 显式给出，避免“隐式全集”歧义。
// stateClass 为空时按 accept 态统一给类 1；scanner 场景传入
// “NFA 态 → 规则号+1”的着色，子集的类取集合中最小者（最高优先级）。
DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass = {});

// 状态最小化（Algorithm 3.3）。初试分割按 color 分组——
// 不同优先级的接受态即使行为相同也不可合并（scanner 语义依赖优先级）。
DFA minimize(const DFA &d, const std::set<char> &alphabet);


// ---------- 多模式 scanner ----------
struct TokenRule { std::string name, pat; };

// 词法分析：把每条规则编译成一个 NFA，共用一个新起点并联；
// 子集构造时每个 DFA 态携带“所含 NFA 接受态的最高优先级规则号”；
// 主循环做最长匹配（maximal munch），平局按优先级。
class Scanner {
public:
    explicit Scanner(std::vector<TokenRule> rules, std::set<char> alphabet);
    // 对输入做一遍切词；无法成词的字符输出 ERR('c')。
    std::vector<std::string> lex(const std::string &src) const;
    // 诊断信息：供 --check 打印各阶段状态数。
    std::string stats() const;

private:
    std::vector<TokenRule> rules_;
    std::set<char> alpha_;
    DFA dfa_;
    std::vector<int> nfaStateRule_;   // NFA 态 → 规则号（-1 非接受）
};

}  // namespace tip

#endif  // TIP_RE_HPP
```

```cpp
// file: src/re.cpp
// file: src/re.cpp
// 第 5 章配套：re.hpp 全部算法的实现。
#include "re.hpp"

#include <algorithm>
#include <array>
#include <cassert>
#include <sstream>

namespace tip {

// ---------- 语法树构造 ----------
std::unique_ptr<RE> RE::eps() {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Eps;
    return r;
}
std::unique_ptr<RE> RE::sym(char c) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Sym;
    r->ch = c;
    return r;
}
std::unique_ptr<RE> RE::alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Alt;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Concat;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::star(std::unique_ptr<RE> a) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Star;
    r->lhs = std::move(a);
    return r;
}

// ---------- 正则串的递归下降解析 ----------
namespace {
struct REParser {
    const std::string &s;
    size_t i = 0;
    explicit REParser(const std::string &src) : s(src) {}

    [[noreturn]] void fail(const char *why) const {
        std::ostringstream os;
        os << "regex 位置 " << i << ": " << why;
        throw std::runtime_error(os.str());
    }

    std::unique_ptr<RE> expr() {
        auto t = term();
        while (i < s.size() && s[i] == '|') {
            ++i;
            t = RE::alt(std::move(t), term());
        }
        return t;
    }
    std::unique_ptr<RE> term() {
        if (i >= s.size() || s[i] == '|' || s[i] == ')')
            return RE::eps();           // 空并置 = ε（允许 "(a|)" 这类宽松写法）
        auto f = factor();
        while (i < s.size() && s[i] != '|' && s[i] != ')')
            f = RE::concat(std::move(f), factor());
        return f;
    }
    std::unique_ptr<RE> factor() {
        auto a = atom();
        while (i < s.size() && s[i] == '*') {
            ++i;
            a = RE::star(std::move(a)); // 连续星 a** 同样合法：等价于 a*
        }
        return a;
    }
    std::unique_ptr<RE> atom() {
        if (i >= s.size()) fail("意外结束");
        if (s[i] == '\\') {          // 转义：下一个字符一律按字面量处理
            ++i;
            if (i >= s.size()) fail("转义后意外结束");
            return RE::sym(s[i++]);
        }
        if (s[i] == '(') {
            ++i;
            auto e = expr();
            if (i >= s.size() || s[i] != ')') fail("缺右括号");
            ++i;
            return e;
        }
        if (s[i] == ')' || s[i] == '|') fail("缺操作数");
        return RE::sym(s[i++]);
    }
};
}  // namespace

std::unique_ptr<RE> parseRE(const std::string &pat) {
    REParser p(pat);
    auto re = p.expr();
    if (p.i != pat.size()) p.fail("尾部有多余字符");
    return re;
}

// ---------- Thompson 构造（Algorithm 3.2） ----------
namespace {
struct Builder {
    NFA n;

    int fresh() {
        n.st.emplace_back();
        return static_cast<int>(n.st.size()) - 1;
    }
    // 基础：单符号 a → 两个状态一条实边；ε → 两个状态一条 ε 边。
    // 归纳：R|S 与 R* 各加两个新状态、四条 ε 边；RS 把出口 ε 直连入口。
    // 每个部件“单一入口、单一出口、入口无入边、出口无出边”的
    // 不变式由构造本身维持——这正是归纳证明能成立的原因。
    void build(const RE &re, int &entry, int &exit_) {
        switch (re.kind) {
        case REKind::Eps: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Sym: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {re.ch, exit_, 0, -1, false};
            break;
        }
        case REKind::Alt: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, e2, false};
            n.st[x1] = {0, exit_, 0, -1, false};
            n.st[x2] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Concat: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            // 绿龙原文：“把 N2 的入口识别为 N1 的出口，后者消失”——
            // 状态合并而不是 ε 直连，这正是书上例子状态数更少的原因。
            // 入口不变式保证没有边指向 e2 的“内部”，只需全局改指。
            n.st[x1] = n.st[e2];   // x1 继承 e2 的（至多两条）出边
            for (auto &q : n.st) {
                if (q.to1 == e2) q.to1 = x1;
                if (q.to2 == e2) q.to2 = x1;
            }
            entry = e1;
            exit_ = x2;
            break;
        }
        case REKind::Star: {
            int e1, x1;
            build(*re.lhs, e1, x1);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, exit_, false};
            n.st[x1] = {0, e1, 0, exit_, false};
            break;
        }
        }
    }
};
}  // namespace

NFA thompson(const RE &re) {
    Builder b;
    int entry, exit_;
    b.build(re, entry, exit_);
    b.n.st[exit_].accept = true;
    b.n.start = entry;
    b.n.finish = exit_;
    // 压实：concat 的状态合并会留下不可达的孤儿入口，
    // 从 start 做一次可达性重编号，状态数才与绿龙例子的口径一致。
    NFA &n = b.n;
    std::vector<int> num(n.st.size(), -1);
    std::vector<int> stack = {n.start};
    num[n.start] = 0;
    int cnt = 1;
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        for (int t : {n.st[s].to1, n.st[s].to2}) {
            if (t != -1 && num[t] == -1) {
                num[t] = cnt++;
                stack.push_back(t);
            }
        }
    }
    NFA packed;
    packed.st.resize(cnt);
    for (int s = 0; s < static_cast<int>(n.st.size()); ++s)
        if (num[s] != -1) {
            packed.st[num[s]] = n.st[s];
            auto &st = packed.st[num[s]];
            if (st.to1 != -1) st.to1 = num[st.to1];
            if (st.to2 != -1) st.to2 = num[st.to2];
        }
    packed.start = 0;                       // 重编号从 start 出发，start 必为 0
    packed.finish = num[n.finish];
    return packed;
}

// ---------- ε 闭包与子集构造（Algorithm 3.1） ----------
namespace {
// ε-CLOSURE(T)：从 T 出发只沿 ε 边可达的状态集（含 T 自身）。
// 绿龙 Fig 3.9 的栈式搜索——它就是第 31 章工作表算法的袖珍版。
std::set<int> epsClosure(const NFA &n, const std::set<int> &t) {
    std::set<int> got = t;
    std::vector<int> stack(t.begin(), t.end());
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        const auto &st = n.st[s];
        if (st.sym1 == 0 && st.to1 != -1 && !got.count(st.to1)) {
            got.insert(st.to1);
            stack.push_back(st.to1);
        }
        if (st.sym2 == 0 && st.to2 != -1 && !got.count(st.to2)) {
            got.insert(st.to2);
            stack.push_back(st.to2);
        }
    }
    return got;
}
}  // namespace

DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass) {
    auto cls = [&](int q) -> int {
        if (!stateClass.empty()) return stateClass[q];
        return n.st[q].accept ? 1 : 0;
    };
    DFA d;
    std::map<std::set<int>, int> id;
    std::vector<std::set<int>> work;
    auto nameOf = [&](const std::set<int> &s) {
        auto [it, fresh] = id.emplace(s, static_cast<int>(id.size()));
        if (fresh) {
            d.trans.emplace_back();
            d.color.push_back(0);
            work.push_back(s);
        }
        return it->second;
    };
    d.start = nameOf(epsClosure(n, {n.start}));
    // 只沿实符号转移扩张；ε 已被闭包吸收。
    for (size_t wi = 0; wi < work.size(); ++wi) {
        int cs = id.at(work[wi]);
        for (char c : alphabet) {
            std::set<int> next;
            for (int q : work[wi]) {
                const auto &st = n.st[q];
                if (st.sym1 == c && st.to1 != -1) next.insert(st.to1);
                if (st.sym2 == c && st.to2 != -1) next.insert(st.to2);
            }
            if (next.empty()) continue;
            nameOf(epsClosure(n, next));
            int t = id.at(epsClosure(n, next));
            d.trans[cs][c] = t;
        }
    }
    // 接受类：子集中出现的最小正类（最高优先级）。
    for (const auto &[sub, s] : id) {
        int best = 0;
        for (int q : sub)
            if (cls(q) > 0 && (best == 0 || cls(q) < best)) best = cls(q);
        d.color[s] = best;
    }
    return d;
}

// ---------- 最小化（Algorithm 3.3） ----------
DFA minimize(const DFA &d, const std::set<char> &alphabet) {
    // 初试分割按 color 分组：空串 ε 本身就能区分接受与非接受，
    // 不同优先级的接受态也必须从第一轮起就分居两组。
    auto countGroups = [](const std::vector<int> &g) {
        return static_cast<size_t>(*std::max_element(g.begin(), g.end()) + 1);
    };
    std::vector<int> group(d.states());
    {
        std::map<int, int> colorToGroup;
        for (int s = 0; s < d.states(); ++s) {
            auto [it, fresh] = colorToGroup.emplace(d.color[s],
                                                    static_cast<int>(colorToGroup.size()));
            group[s] = it->second;
        }
    }
    // 反复按“全部输入符号都落进同一组”细化，直到组数不再增长。
    // 签名以旧组号开头，因此每轮只会分裂、不会合并——
    // 单调有界，循环必然停止（与第 30 章不动点的终止论证同型）。
    while (true) {
        std::map<std::pair<int, std::vector<std::pair<char, int>>>, int> sigToGroup;
        std::vector<int> next(d.states());
        for (int s = 0; s < d.states(); ++s) {
            std::vector<std::pair<char, int>> sig;
            sig.reserve(alphabet.size());
            for (char c : alphabet) {
                auto it = d.trans[s].find(c);
                int t = (it == d.trans[s].end()) ? -1 : it->second;
                sig.emplace_back(c, t < 0 ? -1 : group[t]);
            }
            auto [it, fresh] = sigToGroup.emplace(std::make_pair(group[s], sig),
                                                  static_cast<int>(sigToGroup.size()));
            next[s] = it->second;
        }
        if (sigToGroup.size() == countGroups(group)) break;   // 稳定
        group = next;
    }
    // 重建：每组取一个代表态（编号最小者），重定向所有转移。
    int nGroups = static_cast<int>(countGroups(group));
    std::vector<int> rep(nGroups, -1);
    for (int s = 0; s < d.states(); ++s)
        if (rep[group[s]] == -1) rep[group[s]] = s;
    DFA m;
    m.trans.assign(nGroups, {});
    m.color.assign(nGroups, 0);
    m.start = group[d.start];
    for (int g = 0; g < nGroups; ++g) {
        int s = rep[g];
        m.color[g] = d.color[s];
        for (char c : alphabet) {
            auto it = d.trans[s].find(c);
            if (it != d.trans[s].end()) m.trans[g][c] = group[it->second];
        }
    }
    return m;
}

// ---------- scanner ----------
Scanner::Scanner(std::vector<TokenRule> rules, std::set<char> alphabet)
    : rules_(std::move(rules)), alpha_(std::move(alphabet)) {
    // 多模式并联：公共起点只留两条 ε 出边位（Thompson 的形状约定），
    // 因此像表达式 a|b|c|d 一样做“两两合并”的平衡树：
    // 规则 k 的入口挂到树的第 k 个叶子上，树根是整个大 NFA 的入口。
    std::vector<NFA> parts;
    std::vector<int> partStart;
    for (const auto &r : rules_) {
        NFA one = thompson(*parseRE(r.pat));
        partStart.push_back(one.start);     // 部件入口要存“部件内的编号”
        parts.push_back(std::move(one));
    }
    NFA big;
    auto fresh = [&]() {
        big.st.emplace_back();
        nfaStateRule_.push_back(-1);
        return static_cast<int>(big.st.size()) - 1;
    };
    auto offset = [&](NFA &host, int idx, int base) {
        for (auto &st : host.st) {
            if (st.to1 != -1) st.to1 += base;
            if (st.to2 != -1) st.to2 += base;
        }
        (void)idx;
    };
    // 逐个搬入并改相对编号；接受态记录所属规则（0 起的最高优先级）。
    std::vector<int> shiftedRoots;
    for (size_t k = 0; k < parts.size(); ++k) {
        int base = static_cast<int>(big.st.size());
        offset(parts[k], static_cast<int>(k), base);
        for (size_t q = 0; q < parts[k].st.size(); ++q) {
            big.st.push_back(parts[k].st[q]);
            nfaStateRule_.push_back(parts[k].st[q].accept ? static_cast<int>(k) : -1);
        }
        shiftedRoots.push_back(base + partStart[k]);
    }
    // 平衡树式并联：每合并两棵子树加一个 ε 分叉状态。
    while (shiftedRoots.size() > 1) {
        std::vector<int> next;
        for (size_t i = 0; i < shiftedRoots.size(); i += 2) {
            if (i + 1 < shiftedRoots.size()) {
                int join = fresh();
                big.st[join] = {0, shiftedRoots[i], 0, shiftedRoots[i + 1], false};
                next.push_back(join);
            } else {
                next.push_back(shiftedRoots[i]);
            }
        }
        shiftedRoots = next;
    }
    big.start = shiftedRoots[0];
    // NFA 态着色：规则号+1（0 仍表示非接受）。
    std::vector<int> stateClass;
    for (int k : nfaStateRule_) stateClass.push_back(k < 0 ? 0 : k + 1);
    dfa_ = minimize(subset(big, alpha_, stateClass), alpha_);
}

std::vector<std::string> Scanner::lex(const std::string &src) const {
    std::vector<std::string> out;
    size_t i = 0;
    while (i < src.size()) {
        if (src[i] == ' ' || src[i] == '\n' || src[i] == '\t' || src[i] == '\r') {
            ++i;
            continue;
        }
        int s = dfa_.start;
        size_t j = i;
        size_t lastAcc = std::string::npos;
        int lastColor = 0;
        if (dfa_.color[s] > 0) { lastAcc = i; lastColor = dfa_.color[s]; }
        while (j < src.size()) {
            auto it = dfa_.trans[s].find(src[j]);
            if (it == dfa_.trans[s].end()) break;
            s = it->second;
            ++j;
            if (dfa_.color[s] > 0) { lastAcc = j; lastColor = dfa_.color[s]; }
        }
        if (lastAcc == std::string::npos) {
            std::ostringstream os;
            os << "ERR('" << src[i] << "')";
            out.push_back(os.str());
            ++i;
        } else {
            std::ostringstream os;
            os << rules_[lastColor - 1].name << "('" << src.substr(i, lastAcc - i) << "')";
            out.push_back(os.str());
            i = lastAcc;
        }
    }
    return out;
}

std::string Scanner::stats() const {
    std::ostringstream os;
    os << "rules=" << rules_.size() << " alphabet=" << alpha_.size()
       << " dfa_states=" << dfa_.states();
    return os.str();
}

}  // namespace tip
```

```cpp
// file: src/lr1.hpp
// file: src/lr1.hpp
// 第 8 章配套：规范 LR(1) 造表与 LALR 同心合并（鲸书 §3.4.2 + §3.6.2）。
#ifndef TIP_LR1_HPP
#define TIP_LR1_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 文法 ----------
// 产生式 0 恒为增广开始产生式 S'→S；rhs 空串表示 ε。
struct Grammar {
    std::vector<std::pair<std::string, std::vector<std::string>>> prods;
    std::set<std::string> terms;     // 终结符（含 "$"）
    std::set<std::string> nonterms;  // 非终结符
    std::string start = "S'";
};

// FIRST(符号串)。终结符出现即止；非终结符含 ε 则继续看下一个。
std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail = "");


// ---------- LR 项 ----------
struct Item {
    int prod = 0;         // 产生式编号
    int dot = 0;          // 圆点位置 0..|rhs|
    std::string la;       // lookahead；空串 = LR(0)/SLR 口径
    friend bool operator<(const Item &a, const Item &b) {
        if (a.prod != b.prod) return a.prod < b.prod;
        if (a.dot != b.dot) return a.dot < b.dot;
        return a.la < b.la;
    }
    friend bool operator==(const Item &a, const Item &b) {
        return a.prod == b.prod && a.dot == b.dot && a.la == b.la;
    }
};

// 项的核心（去掉 lookahead）——同心合并的"心"
using Core = std::set<std::pair<int, int>>;

// ---------- 表 ----------
struct Action {
    enum Kind { Err, Shift, Reduce, Acc } kind = Err;
    int target = -1;   // Shift: 目标状态；Reduce: 产生式号
    friend bool operator==(const Action &x, const Action &y) {
        return x.kind == y.kind && x.target == y.target;
    }
};

struct Table {
    std::string kind;                                   // "SLR(1)" / "LR(1)" / "LALR(1)"
    std::vector<std::set<Item>> states;                 // 规范族（SLR/LALR 为合并后状态）
    std::map<int, std::map<std::string, Action>> action; // 状态 -> 终结符 -> 动作
    std::map<int, std::map<std::string, int>> gotos;     // 状态 -> 非终结符 -> 状态
    std::vector<std::pair<int, std::string>> conflicts;  // (状态, 终结符)
    // LR(1) 独有：每个 LR(0) 核心分裂出的 LR(1) 状态（讲"精确 lookahead 分裂状态"用）
    std::map<Core, std::vector<int>> splits;
};


// 规范 LR(1) 造表：项带 lookahead [A→α·β, a]，CLOSURE 用 FIRST(βa) 传播
Table buildLR1(const Grammar &g);

// LALR(1)：规范族按核心合并、lookahead 求并（同心合并）
Table buildLALR(const Grammar &g, const Table &lr1);

// 项集转移（GOTO）。08 章原副本未导出；本章仲裁器要重算移进候选，导出之。
std::set<Item> goTo(const Grammar &g, const std::set<Item> &is, const std::string &x);

// ---------- 表驱动分析器 ----------
struct ParseResult {
    bool accept = false;
    int steps = 0;
};

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words);

}  // namespace tip

#endif  // TIP_LR1_HPP
```

```cpp
// file: src/lr1.cpp
// file: src/lr1.cpp
// 第 8 章配套：FIRST/FOLLOW、CLOSURE/GOTO（带 lookahead）、规范 LR(1) 造表、
// SLR 对照表、LALR 同心合并、表驱动分析器（鲸书 §3.4.2 + §3.6.2 + §3.7）。
#include "lr1.hpp"

namespace tip {

namespace {

bool isTerm(const Grammar &g, const std::string &s) { return g.terms.count(s) > 0; }

// 单符号的 FIRST（含 ε 传播标记：返回集合里带 "" 表示可空）
std::set<std::string> firstOne(const Grammar &g, const std::string &sym,
                               std::map<std::string, std::set<std::string>> &memo) {
    if (auto it = memo.find(sym); it != memo.end()) return it->second;
    std::set<std::string> out;
    if (isTerm(g, sym) || sym.empty()) {
        out.insert(sym);   // 空串符号 "" 表示 ε
        return out;
    }
    bool nullable = false;
    for (const auto &[lhs, rhs] : g.prods) {
        if (lhs != sym) continue;
        if (rhs.empty()) { nullable = true; continue; }
        bool allNullable = true;
        for (const auto &x : rhs) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; break; }
        }
        if (allNullable) nullable = true;
    }
    if (nullable) out.insert("");
    memo[sym] = out;
    return out;
}

}  // namespace

std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail) {
    static std::map<std::string, std::set<std::string>> memo;
    memo.clear();
    std::set<std::string> out;
    bool allNullable = true;
    auto feed = [&](const std::vector<std::string> &part) {
        for (const auto &x : part) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; return; }
        }
    };
    feed(seq);
    if (allNullable && !tail.empty()) feed({tail});
    if (out.empty()) out.insert("");   // 全可空 ⇒ ε
    return out;
}

// ---------- CLOSURE / GOTO ----------

namespace {

// CLOSURE：LR(1) 口径传播 lookahead——[A→α·Bβ, a] 为每个 B→γ 与 b∈FIRST(βa) 加项；
// la 为空串（LR(0)/SLR 口径）时不传播 lookahead。
std::set<Item> closure(const Grammar &g, std::set<Item> is) {
    for (bool ch = true; ch;) {
        ch = false;
        std::set<Item> add;
        for (const auto &it : is) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &b = rhs[it.dot];
            if (isTerm(g, b)) continue;
            std::vector<std::string> beta(rhs.begin() + it.dot + 1, rhs.end());
            std::set<std::string> las;
            if (it.la.empty()) las.insert("");   // LR(0)：无 lookahead
            else las = firstOfSeq(g, beta, it.la);
            for (size_t p = 0; p < g.prods.size(); ++p) {
                if (g.prods[p].first != b) continue;
                for (const auto &a : las) {
                    Item ni{static_cast<int>(p), 0, it.la.empty() ? "" : a};
                    if (!is.count(ni)) { add.insert(ni); ch = true; }
                }
            }
        }
        is.insert(add.begin(), add.end());
    }
    return is;
}

Core coreOf(const std::set<Item> &is) {
    Core c;
    for (const auto &it : is) c.insert({it.prod, it.dot});
    return c;
}

}  // namespace —— goTo 移出匿名区：本章仲裁器要重算移进候选（08 章原副本未导出）

// GOTO(I, X)：圆点移过 X 再闭包
std::set<Item> goTo(const Grammar &g, const std::set<Item> &is, const std::string &x) {
    std::set<Item> moved;
    for (const auto &it : is) {
        const auto &rhs = g.prods[it.prod].second;
        if (it.dot < static_cast<int>(rhs.size()) && rhs[it.dot] == x)
            moved.insert(Item{it.prod, it.dot + 1, it.la});
    }
    return moved.empty() ? moved : closure(g, std::move(moved));
}

namespace {  // 匿名区续

// 规范族：BFS；lr1=false 时为 LR(0) 族（SLR 用）
std::vector<std::set<Item>> collection(const Grammar &g, bool lr1) {
    std::vector<std::set<Item>> states;
    std::map<std::set<Item>, int> index;
    std::vector<std::set<Item>> work;
    auto push = [&](std::set<Item> s) -> int {
        auto it = index.find(s);
        if (it != index.end()) return it->second;
        index[s] = static_cast<int>(states.size());
        states.push_back(s);
        work.push_back(s);
        return static_cast<int>(states.size()) - 1;
    };
    push(closure(g, {{0, 0, lr1 ? "$" : ""}}));
    std::set<std::string> symbols = g.terms;
    symbols.insert(g.nonterms.begin(), g.nonterms.end());
    while (!work.empty()) {
        std::set<Item> cur = work.back();
        work.pop_back();
        for (const auto &x : symbols) {
            std::set<Item> nx = goTo(g, cur, x);
            if (!nx.empty()) push(std::move(nx));
        }
    }
    return states;
}

// 填表的公共骨架：遍历项集，移进项发 shift、归约项按 permit 发 reduce 许可证
// （SLR 的 permit=FOLLOW(A)，LR(1) 的 permit=项自身 lookahead）。
// coreLookup 非空时（LALR）：转移目标按"项集的核心"解析——合并态出发的 GOTO
// 只落在核心的某半边项集上，必须按核心回到合并态（同心态的 GOTO 同心）。
void fill(Table &t, const Grammar &g, const std::vector<std::set<Item>> &states,
          const std::map<std::string, std::set<std::string>> *permit,
          const std::map<Core, int> *coreLookup = nullptr) {
    t.states = states;
    std::map<std::set<Item>, int> index;
    for (size_t i = 0; i < states.size(); ++i) index[states[i]] = static_cast<int>(i);
    auto setAct = [&](int s, const std::string &a, Action act) {
        Action &cell = t.action[s][a];
        if (cell == Action{} || cell == act) { cell = act; return; }
        t.conflicts.push_back({s, a});   // 同格两异动作：记冲突，保留先到者
    };
    auto targetOf = [&](const std::set<Item> &nx) -> int {
        if (nx.empty()) return -1;   // 无此转移（如对 S' 的 GOTO）
        if (coreLookup) {
            auto cit = coreLookup->find(coreOf(nx));
            return cit == coreLookup->end() ? -1 : cit->second;
        }
        return index.at(nx);
    };
    for (size_t si = 0; si < states.size(); ++si) {
        for (const auto &it : states[si]) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot < static_cast<int>(rhs.size())) {
                const std::string &x = rhs[it.dot];
                if (!isTerm(g, x)) continue;
                int tgt = targetOf(goTo(g, states[si], x));
                if (tgt >= 0)
                    setAct(static_cast<int>(si), x, Action{Action::Shift, tgt});
            } else if (it.prod == 0) {
                setAct(static_cast<int>(si), "$", Action{Action::Acc, -1});
            } else if (it.prod != 0) {
                // 归约许可证来源：SLR 用 FOLLOW(A)，LR(1) 用 lookahead
                if (permit) {
                    const auto &f = permit->at(lhs);
                    for (const auto &a : f) setAct(static_cast<int>(si), a, Action{Action::Reduce, it.prod});
                } else {
                    setAct(static_cast<int>(si), it.la, Action{Action::Reduce, it.prod});
                }
            }
        }
        for (const auto &b : g.nonterms) {
            int tgt = targetOf(goTo(g, states[si], b));
            if (tgt >= 0)
                t.gotos[static_cast<int>(si)][b] = tgt;
        }
    }
}

}  // namespace


Table buildLR1(const Grammar &g) {
    Table t;
    t.kind = "LR(1)";
    fill(t, g, collection(g, true), nullptr);
    // 记录核心分裂：同一核心对应多少个 LR(1) 状态
    for (size_t i = 0; i < t.states.size(); ++i) t.splits[coreOf(t.states[i])].push_back(static_cast<int>(i));
    return t;
}

Table buildLALR(const Grammar &g, const Table &lr1) {
    Table t;
    t.kind = "LALR(1)";
    // 1) 按核心分组合并，lookahead 求并
    std::map<Core, int> coreId;
    std::vector<std::set<Item>> merged;
    for (const auto &st : lr1.states) {
        Core c = coreOf(st);
        auto it = coreId.find(c);
        if (it == coreId.end()) {
            coreId[c] = static_cast<int>(merged.size());
            merged.push_back(st);
        } else {
            merged[it->second].insert(st.begin(), st.end());
        }
    }
    // 2) 用"核心 → 合并态"索引重建 GOTO/ACTION：转移按核心解析（见 fill 注释）
    fill(t, g, merged, nullptr, &coreId);
    return t;
}

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words) {
    ParseResult r;
    std::vector<int> stack{0};
    std::vector<std::string> input = words;
    input.push_back("$");
    size_t ip = 0;
    for (;;++r.steps) {
        if (r.steps > 1000) return r;   // 保险丝
        int s = stack.back();
        auto it = t.action.find(s);
        if (it == t.action.end() || !it->second.count(input[ip])) return r;   // 错误
        const Action &a = it->second.at(input[ip]);
        if (a.kind == Action::Shift) {
            stack.push_back(a.target);
            ++ip;
        } else if (a.kind == Action::Reduce) {
            const auto &rhs = g.prods[a.target].second;
            for (size_t k = 0; k < rhs.size(); ++k) stack.pop_back();
            int top = stack.back();
            auto git = t.gotos.find(top);
            if (git == t.gotos.end() || !git->second.count(g.prods[a.target].first)) return r;
            stack.push_back(git->second.at(g.prods[a.target].first));
        } else if (a.kind == Action::Acc) {
            r.accept = true;
            return r;
        } else {
            return r;
        }
    }
}

}  // namespace tip
```

```cpp
// file: src/yacc.hpp
// yacc 心脏：LALR(1) 表（08 章副本）之上的值栈驱动器 + 优先级仲裁 + 嵌入动作改写。
// 对应 L 书 §5.4–5.5 的三个机制：%union（任意值类型）、$$/$n 伪变量、
// 优先级/结合性声明消冲突；§5.5.6 的嵌入动作 = 空产生式改写也在本文件实现。
#ifndef TIP_YACC_HPP
#define TIP_YACC_HPP

#include <functional>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "lr1.hpp"

namespace tip {

// ---------- %union：值栈元素的带标签联合 ----------
// yacc 的 %union 声明编译成一个 union/struct，词法动作填 yylval，
// 语法动作经 $$/$n 读写。教学版用 Tag + 双字段表达同一契约：
// 动作里取错标签 = 生成器报错的运行期对应物（断言炸）。
struct YaccValue {
    enum class Tag { Empty, Num, Str } tag = Tag::Empty;
    double num = 0;
    std::string str;

    static YaccValue empty() { return {}; }
    static YaccValue ofNum(double v) { YaccValue y; y.tag = Tag::Num; y.num = v; return y; }
    static YaccValue ofStr(std::string s) { YaccValue y; y.tag = Tag::Str; y.str = std::move(s); return y; }

    double asNum(const char *who) const {
        // %type 声明的运行期影子：声明了 <num> 的位置来了 Str，就是类型错误
        if (tag != Tag::Num) {
            std::ostringstream os;
            os << "type error: " << who << " expects Num, got "
               << (tag == Tag::Str ? "Str" : "Empty");
            throw std::runtime_error(os.str());
        }
        return num;
    }
    const std::string &asStr(const char *who) const {
        if (tag != Tag::Str) {
            std::ostringstream os;
            os << "type error: " << who << " expects Str, got "
               << (tag == Tag::Num ? "Num" : "Empty");
            throw std::runtime_error(os.str());
        }
        return str;
    }
};

// ---------- 规则与动作 ----------
// vals[k-1] 即 $k（$1..$n 按出现序）；返回值即 $$。
// 动作为空的规则按 yacc 缺省：$$ = $1（ε 规则给 Empty）。
using YaccAction = std::function<YaccValue(std::vector<YaccValue> &)>;

struct YaccRule {
    std::string lhs;
    std::vector<std::string> rhs;
    YaccAction action;        // 可空
    std::string actionName;   // 日志用（嵌入动作改写对账的关键）
    int rulePrec = 0;         // %prec 覆盖：0 = 未声明（取最右终结符）
};

// ---------- 结合性 ----------
enum class YaccAssoc { None, Left, Right };

// ---------- 驱动器 ----------
class MiniYacc {
public:
    // startSym 指定文法开始非终结符；内部自动增广 S'→startSym。
    MiniYacc(std::vector<YaccRule> rules, const std::string &startSym,
             std::vector<std::string> terminals);

    // 优先级/结合性声明（%left/%right/%prec 的教学对应物）。
    void setPrec(const std::string &term, int level, YaccAssoc assoc);

    struct RunResult {
        bool accept = false;
        int steps = 0;
        std::vector<std::string> reduceLog;   // "p: lhs → rhs" 逐次归约
        std::vector<std::string> actionLog;   // 动作名按执行序（嵌入改写对账用）
        YaccValue result;
    };

    // 值栈分析：stateStack 与 valueStack 平行推进；Err 即拒绝。
    // 非 const：首次调用会触发冲突仲裁（声明先于规则、表收尾生成的 yacc 次序）。
    RunResult parse(const std::vector<std::pair<std::string, std::string>> &toks,
                    bool runActions);

    // ---- 第 10 章扩展（本章正题）：错误处置四模式 ----
    //   None     报错即停（对照组）
    //   TokenDel 朴素删除：删当前 token 重试——级联假错误的制造机
    //   Panic    恐慌模式：丢输入至"栈上某状态能接受"为止（L 书 §5.7.2 应急方式）
    //   ErrorProd 文法里写好 error 记号：弹栈至可移进 error、移进、
    //             再丢输入至表恢复动作（yacc 的 error 记号协议，§5.7.3）
    enum class Recover { None, TokenDel, Panic, ErrorProd };
    struct RecoverOut {
        bool accept = false;
        int steps = 0;
        std::vector<std::pair<int, std::string>> diags;   // (token 下标, 人话)
        int detectPos = -1;                               // 首错位置（LL/LR 对照的 LR 侧）
        std::vector<std::string> reduceLog;
    };
    RecoverOut parseRecover(const std::vector<std::pair<std::string, std::string>> &toks,
                            Recover mode);

    // 冲突账本：resolve 前后可各打印一次。
    struct ConflictStats {
        int raw = 0;            // 表构造期记录的冲突格数
        int byPrec = 0;         // 优先级高者胜
        int byAssoc = 0;        // 同级看结合性
        int defaultShift = 0;   // 一方无优先级：缺省移进
        int ruleOrder = 0;      // reduce/reduce：先声明者胜
        int unresolved = 0;
    };
    const ConflictStats &conflictStats() const {
        const_cast<MiniYacc *>(this)->ensureResolved();
        return cstats_;
    }

    const Grammar &grammar() const { return g_; }
    const Table &table() const {
        const_cast<MiniYacc *>(this)->ensureResolved();
        return tab_;
    }

private:
    void buildTable();
    void resolveConflicts();
    // yacc 的 .y 文件里声明在规则前、表在收尾生成——对应到代码就是
    // 「setPrec 尽管晚到，首次用时（parse/取表）才仲裁」。
    void ensureResolved() {
        if (!resolved_) {
            resolveConflicts();
            resolved_ = true;
        }
    }
    int prodPrecOf(int rulesIdx) const;   // 产生式优先级：%prec 覆盖或最右终结符

    Grammar g_;
    std::vector<YaccRule> rules_;   // 含增广产生式在内的展开结果（与 g_.prods 对齐）
    Table tab_;
    std::map<std::string, std::pair<int, YaccAssoc>> prec_;  // 终结符 → (级, 结合性)
    ConflictStats cstats_;
    bool resolved_ = false;
};

// ---------- 嵌入动作 = 空产生式改写（§5.5.6）----------
// rhs 中以 '#' 起头的符号是嵌入动作占位（"#log"），其执行体经 embeds 旁表给出。
// rewriteEmbedded 把占位符变成新的 ε 非终结符并搬运动作——等价性的机制核心。
// 返回 (改写后的规则集, 新增的 ε 规则数)。
std::pair<std::vector<YaccRule>, int> rewriteEmbedded(
    std::vector<YaccRule> rules,
    std::map<std::string, std::pair<YaccAction, std::string>> embeds);

// 产生式打印："lhs → a b c"（ε 显示为 ε）。
std::string showProd(const Grammar &g, int p);

}  // namespace tip

#endif  // TIP_YACC_HPP
```

```cpp
// file: src/yacc.cpp
// yacc 心脏实现。表构造完全复用 08 章副本（buildLR1/buildLALR），
// 本文件只做三件 08 章没有的事：值栈平行推进、优先级仲裁、嵌入动作改写。
#include "yacc.hpp"

#include <stdexcept>

namespace tip {

namespace {

bool isTerminal(const Grammar &g, const std::string &s) { return g.terms.count(s) > 0; }

}  // namespace

MiniYacc::MiniYacc(std::vector<YaccRule> rules, const std::string &startSym,
                   std::vector<std::string> terminals)
    : rules_(std::move(rules)) {
    for (size_t i = 0; i < rules_.size(); ++i)
        g_.nonterms.insert(rules_[i].lhs);   // 先收集 lhs：#chk 这类 ε 非终结符靠它放行
    for (size_t i = 0; i < rules_.size(); ++i)
        for (const auto &s : rules_[i].rhs)
            if (s.rfind("#", 0) == 0 && !g_.nonterms.count(s))
                throw std::runtime_error("MiniYacc: 嵌入动作须先经 rewriteEmbedded 展开: " + s);
    terminals.push_back("$");
    g_.terms.insert(terminals.begin(), terminals.end());
    g_.start = "S'";
    g_.prods.push_back({"S'", {startSym}});
    g_.nonterms.insert("S'");
    g_.nonterms.insert(startSym);
    for (const auto &r : rules_) {
        g_.prods.push_back({r.lhs, r.rhs});
        g_.nonterms.insert(r.lhs);
    }
    for (const auto &r : rules_)
        for (const auto &s : r.rhs)
            if (!isTerminal(g_, s) && !g_.nonterms.count(s))
                throw std::runtime_error("MiniYacc: 悬空符号 " + s);
    buildTable();
}

void MiniYacc::setPrec(const std::string &term, int level, YaccAssoc assoc) {
    prec_[term] = {level, assoc};
}

void MiniYacc::buildTable() {
    Table lr1 = buildLR1(g_);
    tab_ = buildLALR(g_, lr1);
    cstats_.raw = static_cast<int>(tab_.conflicts.size());
    // 仲裁不在此处：setPrec 的声明可能在构造后才到达（ensureResolved 惰性触发）。
    // 早期版本这里漏了一次 resolveConflicts()——账本被"无声明一遍 + 有声明一遍"
    // 双重计入，表动作正确而计数翻倍（§9.7.5 坑五的教训：删调用要删干净）。
}

// 产生式优先级 = %prec 覆盖，否则最右终结符的声明级（无则 0）——§5.5.3 规则。
int MiniYacc::prodPrecOf(int p) const {
    if (rules_[p].rulePrec > 0) return rules_[p].rulePrec;
    const auto &rhs = g_.prods[p + 1].second;   // +1 跳过增广产生式
    for (auto it = rhs.rbegin(); it != rhs.rend(); ++it) {
        if (!isTerminal(g_, *it)) continue;
        auto pi = prec_.find(*it);
        return pi == prec_.end() ? 0 : pi->second.first;
    }
    return 0;
}

void MiniYacc::resolveConflicts() {
    if (tab_.conflicts.empty()) return;
    // 状态定位表：goTo 的落点按项集相等找回编号（LALR 合并族仍封闭）。
    std::map<std::set<Item>, int> index;
    for (size_t i = 0; i < tab_.states.size(); ++i) index[tab_.states[i]] = static_cast<int>(i);

    std::set<std::pair<int, std::string>> seen;   // 同格多次入账只裁一次
    for (const auto &[s, a] : tab_.conflicts) {
        if (!seen.insert({s, a}).second) continue;
        // 候选 1：移进——重算 goTo(states[s], a)。
        int shiftTgt = -1;
        auto nx = goTo(g_, tab_.states[s], a);
        if (!nx.empty()) {
            auto it = index.find(nx);
            if (it != index.end()) shiftTgt = it->second;
        }
        // 候选 2：归约——态内 dot 到底、lookahead 覆盖 a 的项。
        std::vector<int> reduces;
        for (const auto &it : tab_.states[s]) {
            const auto &rhs = g_.prods[it.prod].second;
            if (it.prod == 0 || it.dot != static_cast<int>(rhs.size())) continue;
            if (it.la != a) continue;
            reduces.push_back(it.prod);
        }
        if (reduces.empty() && shiftTgt < 0) { ++cstats_.unresolved; continue; }
        if (reduces.size() >= 2) ++cstats_.ruleOrder;   // reduce/reduce：先声明者胜
        if (reduces.empty()) {                           // 纯 shift 之争：保留现状
            tab_.action[s][a] = Action{Action::Shift, shiftTgt};
            continue;
        }
        int best = reduces[0];                           // prods 升序即声明序
        if (shiftTgt < 0) {                              // 纯归约之争
            tab_.action[s][a] = Action{Action::Reduce, best};
            continue;
        }
        // shift/reduce 投票
        int tp = 0, pp = 0;
        YaccAssoc ta = YaccAssoc::None;
        auto pi = prec_.find(a);
        if (pi != prec_.end()) { tp = pi->second.first; ta = pi->second.second; }
        pp = prodPrecOf(best - 1);                       // rules_ 下标 = prod-1
        if (tp > 0 && pp > 0) {
            if (tp > pp) { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.byPrec; }
            else if (tp < pp) { tab_.action[s][a] = Action{Action::Reduce, best}; ++cstats_.byPrec; }
            else if (ta == YaccAssoc::Left) { tab_.action[s][a] = Action{Action::Reduce, best}; ++cstats_.byAssoc; }
            else if (ta == YaccAssoc::Right) { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.byAssoc; }
            else { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.defaultShift; }
        } else {
            tab_.action[s][a] = Action{Action::Shift, shiftTgt};   // 一方无级：缺省移进
            ++cstats_.defaultShift;
        }
    }
}

MiniYacc::RunResult MiniYacc::parse(
    const std::vector<std::pair<std::string, std::string>> &toks, bool runActions) {
    ensureResolved();
    RunResult r;
    std::vector<int> stateStack{0};
    std::vector<YaccValue> valueStack{YaccValue::empty()};
    size_t i = 0;
    std::string kind = i < toks.size() ? toks[i].first : "$";
    std::string text = i < toks.size() ? toks[i].second : "";
    // 步数口径与 08 章 tableGenerate 对齐：本轮完成才计数（for 头自增）。
    for (;; ++r.steps) {
        int s = stateStack.back();
        Action act;
        auto row = tab_.action.find(s);
        if (row != tab_.action.end()) {
            auto cell = row->second.find(kind);
            if (cell != row->second.end()) act = cell->second;
        }
        if (act.kind == Action::Err) return r;                    // 拒绝
        if (act.kind == Action::Acc) { r.accept = true; r.result = valueStack.back(); return r; }
        if (act.kind == Action::Shift) {
            stateStack.push_back(act.target);
            YaccValue v = YaccValue::empty();
            if (kind == "NUM") v = YaccValue::ofNum(std::stod(text));
            else if (kind == "ID") v = YaccValue::ofStr(text);
            valueStack.push_back(v);
            ++i;
            kind = i < toks.size() ? toks[i].first : "$";
            text = i < toks.size() ? toks[i].second : "";
        } else {                                                   // Reduce
            int p = act.target;
            const auto &rhs = g_.prods[p].second;
            std::vector<YaccValue> vals(valueStack.end() - static_cast<long>(rhs.size()),
                                       valueStack.end());
            stateStack.resize(stateStack.size() - rhs.size());
            valueStack.resize(valueStack.size() - rhs.size());
            const YaccRule &rule = rules_[p - 1];
            r.reduceLog.push_back(showProd(g_, p));
            YaccValue got;
            if (rule.action && runActions) {
                r.actionLog.push_back(rule.actionName);
                got = rule.action(vals);
            } else if (!rhs.empty()) {
                got = vals[0];                                     // 缺省 $$ = $1
            }
            int tgt = tab_.gotos.at(stateStack.back()).at(g_.prods[p].first);
            stateStack.push_back(tgt);
            valueStack.push_back(got);
        }
    }
}

MiniYacc::RecoverOut MiniYacc::parseRecover(
    const std::vector<std::pair<std::string, std::string>> &toks, Recover mode) {
    ensureResolved();
    RecoverOut r;
    std::vector<int> stateStack{0};
    std::vector<YaccValue> valueStack{YaccValue::empty()};
    size_t i = 0;
    std::string kind = i < toks.size() ? toks[i].first : "$";
    std::string text = i < toks.size() ? toks[i].second : "";
    auto act = [&](int s, const std::string &k) {
        Action a;
        auto row = tab_.action.find(s);
        if (row != tab_.action.end()) {
            auto cell = row->second.find(k);
            if (cell != row->second.end()) a = cell->second;
        }
        return a;
    };
    auto shiftCur = [&]() {
        YaccValue v = YaccValue::empty();
        if (kind == "NUM") v = YaccValue::ofNum(std::stod(text));
        else if (kind == "ID") v = YaccValue::ofStr(text);
        valueStack.push_back(v);
        ++i;
        kind = i < toks.size() ? toks[i].first : "$";
        text = i < toks.size() ? toks[i].second : "";
    };
    auto reduceBy = [&](int p) {
        const auto &rhs = g_.prods[p].second;
        std::vector<YaccValue> vals(valueStack.end() - static_cast<long>(rhs.size()),
                                   valueStack.end());
        stateStack.resize(stateStack.size() - rhs.size());
        valueStack.resize(valueStack.size() - rhs.size());
        r.reduceLog.push_back(showProd(g_, p));
        YaccValue got;
        const YaccRule &rule = rules_[p - 1];
        if (rule.action) got = rule.action(vals);
        else if (!rhs.empty()) got = vals[0];
        int tgt = tab_.gotos.at(stateStack.back()).at(g_.prods[p].first);
        stateStack.push_back(tgt);
        valueStack.push_back(got);
    };
    auto diag = [&](const char *why) {
        r.diags.push_back({static_cast<int>(i), std::string(why) + " [la=" + kind + "]"});
        if (r.detectPos < 0) r.detectPos = static_cast<int>(i);
    };
    for (;; ++r.steps) {
        if (r.steps > 4000) return r;   // 保险丝
        int s = stateStack.back();
        Action a = act(s, kind);
        if (a.kind == Action::Err) {
            switch (mode) {
            case Recover::None:
                diag("no action");
                return r;
            case Recover::TokenDel:      // 朴素删除：级联之源
                diag("no action");
                if (kind == "$") return r;
                ++i;
                kind = i < toks.size() ? toks[i].first : "$";
                text = i < toks.size() ? toks[i].second : "";
                break;
            case Recover::Panic: {
                // 应急方式（L 书 §5.7.2）：先丢输入到"当前状态能接受"，栈不动——
                // 栈的期望就是同步集；丢到 $ 仍不行才弹栈重试一轮。
                diag("no action");
                bool resumed = false;
                while (kind != "$" && act(stateStack.back(), kind).kind == Action::Err) {
                    ++i;
                    kind = i < toks.size() ? toks[i].first : "$";
                    text = i < toks.size() ? toks[i].second : "";
                    if (act(stateStack.back(), kind).kind != Action::Err) { resumed = true; break; }
                }
                if (!resumed && act(stateStack.back(), kind).kind != Action::Err) resumed = true;
                if (!resumed) {
                    while (stateStack.size() > 1) {
                        stateStack.pop_back();
                        valueStack.pop_back();
                        if (act(stateStack.back(), kind).kind != Action::Err) { resumed = true; break; }
                    }
                }
                if (!resumed) return r;
                break;
            }
            case Recover::ErrorProd: {
                // yacc error 记号协议：弹栈至可移进 error 的状态，移进 error，
                // 再丢输入直到表给出动作（同步点通常是 error 规则的后续符号）
                diag("no action");
                bool found = false;
                while (stateStack.size() > 1) {
                    stateStack.pop_back();
                    valueStack.pop_back();
                    if (act(stateStack.back(), "error").kind == Action::Shift) { found = true; break; }
                }
                if (!found) return r;
                Action e = act(stateStack.back(), "error");
                stateStack.push_back(e.target);
                valueStack.push_back(YaccValue::empty());
                // 丢输入至恢复（error 之后表上第一个可用动作）
                while (kind != "$" && act(stateStack.back(), kind).kind == Action::Err) {
                    ++i;
                    kind = i < toks.size() ? toks[i].first : "$";
                    text = i < toks.size() ? toks[i].second : "";
                }
                break;
            }
            }
            continue;
        }
        if (a.kind == Action::Acc) { r.accept = true; return r; }
        if (a.kind == Action::Shift) {
            stateStack.push_back(a.target);
            shiftCur();
        } else {
            reduceBy(a.target);
        }
    }
}

std::pair<std::vector<YaccRule>, int> rewriteEmbedded(
    std::vector<YaccRule> rules,
    std::map<std::string, std::pair<YaccAction, std::string>> embeds) {
    int added = 0;
    std::set<std::string> emitted;
    for (auto &r : rules)
        for (auto &s : r.rhs) {
            if (s.rfind("#", 0) != 0) continue;
            if (!emitted.insert(s).second) continue;
            auto it = embeds.find(s);
            if (it == embeds.end())
                throw std::runtime_error("rewriteEmbedded: 占位符缺动作 " + s);
            YaccRule eps;
            eps.lhs = s;                       // 占位符名即 ε 非终结符名
            eps.rhs = {};
            eps.action = it->second.first;
            eps.actionName = it->second.second;
            rules.push_back(eps);
            ++added;
        }
    return {std::move(rules), added};
}

std::string showProd(const Grammar &g, int p) {
    const auto &[lhs, rhs] = g.prods[p];
    std::string s = std::to_string(p) + ": " + lhs + " → ";
    if (rhs.empty()) return s + "ε";
    for (size_t i = 0; i < rhs.size(); ++i) s += rhs[i] + (i + 1 < rhs.size() ? " " : "");
    return s;
}

}  // namespace tip
```

```cpp
// file: src/recover.hpp
// 第 10 章正题之一：LL(1) 表驱动分析器的三种错误处置（L 书 §4.5.2 口径）。
//   None    —— 报错即停（对照组）；
//   TokenDel—— 朴素删除：删掉当前 token 重试（级联假错误的制造机）；
//   Panic   —— 恐慌模式：栈顶终结符不匹配则弹栈（假定缺失），
//              非终结符无表项则丢输入至 FOLLOW(A) 再弹 A（同步集恢复）。
#ifndef TIP_RECOVER_HPP
#define TIP_RECOVER_HPP

#include <string>
#include <vector>

#include "ll1.hpp"

namespace tip {

enum class LLRecover { None, TokenDel, Panic, Phrase };

struct Diag {
    int pos;             // 错误检测点的 token 下标（0 起）
    std::string msg;     // 人话诊断
};

struct LLResult {
    bool accept = false;
    int steps = 0;
    std::vector<Diag> diags;
    int detectPos = -1;  // 首个错误的 token 下标（LL/LR 对照表的 LL 侧数据）
};

// input 为终结符种类序列（不含尾部 $；函数内部补）。
LLResult llParse(const LL1 &ll, const std::vector<std::string> &input, LLRecover mode);

}  // namespace tip

#endif  // TIP_RECOVER_HPP
```

```cpp
// file: src/recover.cpp
// LL(1) 三模式驱动实现。表与 FIRST/FOLLOW 全部来自第 6 章副本（零改动）。
#include "recover.hpp"

namespace tip {

namespace {

std::string topShow(const std::vector<std::string> &st) {
    return st.empty() ? "<empty>" : st.back();
}

}  // namespace

LLResult llParse(const LL1 &ll, const std::vector<std::string> &input, LLRecover mode) {
    LLResult r;
    // 栈底 $，其上是开始符号；输入尾部补 $。
    std::vector<std::string> st{"$", ll.g.start};
    std::vector<std::string> in = input;
    in.push_back("$");
    size_t i = 0;
    int noConsume = 0;   // Phrase 守卫：连续"不消耗输入的修复"计数
    auto diag = [&](const std::string &msg) {
        Diag d{static_cast<int>(i), msg + " [top=" + topShow(st) + " la=" + in[i] + "]"};
        r.diags.push_back(d);
        if (r.detectPos < 0) r.detectPos = static_cast<int>(i);
    };
    while (!st.empty()) {
        if (++r.steps > 4000) return r;   // 保险丝：模式错误时防止失控
        std::string top = st.back();
        if (top == "$" && in[i] == "$") {
            st.pop_back();
            r.accept = st.empty();
            return r;
        }
        if (ll.g.isTerm(top) || top == "$") {
            if (top == in[i]) {           // 匹配：弹栈前进
                st.pop_back();
                ++i;
                noConsume = 0;
                continue;
            }
            // 终结符不匹配——错误检测点
            switch (mode) {
            case LLRecover::None:
                diag("terminal mismatch");
                return r;
            case LLRecover::TokenDel:      // 朴素：删输入 token 重试（级联之源）
                diag("terminal mismatch");
                if (in[i] == "$") return r;
                ++i;
                break;
            case LLRecover::Panic:         // 恐慌：假定该终结符在输入中缺失——弹栈
                diag("terminal mismatch");
                st.pop_back();
                break;
            case LLRecover::Phrase:        // 短语级"插入"：假定输入缺了 top——弹掉它
                diag("terminal mismatch");
                if (++noConsume > 2) {     // 守卫：连续两次不消耗输入，强制吃一个
                    noConsume = 0;
                    if (in[i] != "$") ++i;
                } else {
                    st.pop_back();
                }
                break;
            }
            continue;
        }
        // 非终结符：查表
        auto key = std::make_pair(top, in[i]);
        auto cell = ll.table.find(key);
        if (cell != ll.table.end()) {
            const Production &p = ll.g.prods[cell->second];
            st.pop_back();
            for (auto it = p.rhs.rbegin(); it != p.rhs.rend(); ++it) st.push_back(*it);
            continue;
        }
        switch (mode) {
        case LLRecover::None:
            diag("empty table cell");
            return r;
        case LLRecover::TokenDel:
            diag("empty table cell");
            if (in[i] == "$") return r;
            ++i;
            break;
        case LLRecover::Panic: {
            // 丢输入至同步集 FOLLOW(A)，再弹掉 A——"这一段没有 A"的官方解释
            diag("empty table cell");
            const auto &fol = ll.follow.at(top);
            while (i + 1 < in.size() && !fol.count(in[i]) && in[i] != "$") ++i;
            st.pop_back();
            break;
        }
        case LLRecover::Phrase:
            // 短语级"删除"：la 已在 FOLLOW(A) 里，假定 A 推导了 ε——弹掉 A
            diag("empty table cell");
            if (ll.follow.at(top).count(in[i])) {
                if (++noConsume > 2) {
                    noConsume = 0;
                    if (in[i] != "$") ++i;
                } else {
                    st.pop_back();
                }
            } else if (in[i] != "$") {
                noConsume = 0;
                ++i;                      // A 的 FIRST 里谁都不是：删输入 token
            } else {
                st.pop_back();
            }
            break;
        }
    }
    return r;
}

}  // namespace tip
```

```cpp
// file: src/demo.hpp
// 第 10 章配套：错误语料的舞台——同一门计算器语言的两种文法 + 词法（09 副本）。
#ifndef TIP_DEMO10_HPP
#define TIP_DEMO10_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "llgrammar.hpp"
#include "re.hpp"
#include "yacc.hpp"

namespace tip {

// ---------- 词法（09 章副本，规则表与拆包原样） ----------
struct LexTok {
    std::string kind, text;
};
class MiniLex {
public:
    MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet);
    std::vector<LexTok> scan(const std::string &src) const;
    std::string stats() const { return sc_.stats(); }

private:
    Scanner sc_;
};
std::vector<TokenRule> calcLexRules();
std::set<char> calcAlphabet();

// ---------- 计算环境（09 章副本） ----------
struct CalcEnv {
    std::map<std::string, double> vars;
    std::vector<std::string> printed;
};
std::string fmt(double v);

// ---------- LR 版文法：左递归（09 章副本） ----------
std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel);
// ---------- LR 版 + error 记号（本章新件） ----------
// 多一条 stmt → error ';'：错误发生时弹栈至 error 可移进处、丢输入至 ';'。
std::vector<YaccRule> calcRulesErr(CalcEnv &env);

// ---------- LL(1) 版文法：消左递归（第 6 章手法） ----------
// prog  → stmt prog'      prog' → stmt prog' | ε
// stmt  → ID = expr ; | print expr ;
// expr  → term expr'      expr' → (+|-) term expr' | ε
// term  → factor term'    term' → (*|/) factor term' | ε
// factor → NUM | ID | ( expr ) | - factor
LLGrammar calcLL();

}  // namespace tip

#endif  // TIP_DEMO10_HPP
```

```cpp
// file: src/demo.cpp
// demo 层实现。词法与 LR 文法取自 09 章副本（零改动），新增 error 记号文法与 LL 版。
#include "demo.hpp"

#include <cmath>
#include <sstream>
#include <stdexcept>

namespace tip {

// ---------- mini-lex ----------

MiniLex::MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet)
    : sc_(std::move(rules), std::move(alphabet)) {}

std::vector<LexTok> MiniLex::scan(const std::string &src) const {
    std::vector<LexTok> out;
    for (const std::string &s : sc_.lex(src)) {
        // 产物形如 NAME('text')：第一个 '(' 之前是名字，')' 之前是 yytext。
        size_t lp = s.find('(');
        size_t rp = s.rfind(')');
        LexTok t;
        t.kind = s.substr(0, lp);
        t.text = s.substr(lp + 2, rp - lp - 3);   // 跳过 '(' 与开引号，止于闭引号
        out.push_back(std::move(t));
    }
    return out;
}

// ---------- 词法规则 ----------

namespace {

// 把字符集拼成 (a|b|c) 的择一式——05 章迷你正则没有字符类语法，
// Lex 的 [0-9] 在这里展开成它的原形（教学价值：糖与核心的差）。
std::string altChars(const std::string &chars) {
    std::string s = "(";
    for (size_t i = 0; i < chars.size(); ++i)
        s += std::string(1, chars[i]) + (i + 1 < chars.size() ? "|" : "");
    return s + ")";
}

const std::string kLetters = "abcdefghijklmnopqrstuvwxyz_";
const std::string kDigits = "0123456789";

}  // namespace

std::vector<TokenRule> calcLexRules() {
    std::string L = altChars(kLetters);
    std::string D = altChars(kDigits);
    std::string LD = "(" + L + "|" + D + ")";
    return {
        // 先声明者优先：关键字在 ID 前——同长匹配 "print" 时 KW 胜出。
        {"print", "print"},
        {"NUM", D + D + "*"},
        {"ID", L + LD + "*"},
        // 最长匹配由扫描器保证：'<= '|'==' 无需声明在 '<'、'=' 前，长度定胜负。
        {"<=", "(<)(=)"},
        {"==", "(=)(=)"},
        {"<", "<"},
        {"=", "="},
        {"+", "+"}, {"-", "-"}, {"*", "\\*"}, {"/", "/"}, {"^", "^"},
        {"LPAREN", "\\("}, {"RPAREN", "\\)"}, {";", ";"},
    };
}

std::set<char> calcAlphabet() {
    std::set<char> a(kLetters.begin(), kLetters.end());
    a.insert(kDigits.begin(), kDigits.end());
    for (char c : std::string("<=+-*/^();"))
        a.insert(c);
    return a;
}

std::string fmt(double v) {
    std::ostringstream os;
    os << v;                       // %g 风格：14 而非 14.000000
    return os.str();
}

std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel) {
    std::vector<YaccRule> r;
    r.push_back({"prog", {"prog", "stmt"}, {}, "prog-cons", 0});
    r.push_back({"prog", {"stmt"}, {}, "prog-base", 0});
    r.push_back({"stmt", {"ID", "=", "expr", ";"},
                 [&env](std::vector<YaccValue> &v) {
                     env.vars[v[0].asStr("stmt: $1")] = v[2].asNum("stmt: $3");
                     return YaccValue::empty();
                 },
                 "stmt-assign", 0});
    r.push_back({"stmt", {"print", "expr", ";"},
                 [&env](std::vector<YaccValue> &v) {
                     env.printed.push_back(fmt(v[1].asNum("stmt: $2")));
                     return YaccValue::empty();
                 },
                 "stmt-print", 0});
    struct Op { const char *sym; char tag; };
    for (Op op : {Op{"+", '+'}, Op{"-", '-'}, Op{"*", '*'}, Op{"/", '/'}, Op{"^", '^'}}) {
        std::string name = std::string("expr-") + op.tag;
        r.push_back({"expr", {"expr", op.sym, "expr"},
                     [tag = op.tag](std::vector<YaccValue> &v) {
                         double a = v[0].asNum("expr: $1"), b = v[2].asNum("expr: $3");
                         switch (tag) {
                         case '+': return YaccValue::ofNum(a + b);
                         case '-': return YaccValue::ofNum(a - b);
                         case '*': return YaccValue::ofNum(a * b);
                         case '/': return YaccValue::ofNum(a / b);
                         case '^': return YaccValue::ofNum(std::pow(a, b));
                         default: throw std::runtime_error("bad op");
                         }
                     },
                     name, 0});
    }
    r.push_back({"expr", {"-", "expr"},
                 [](std::vector<YaccValue> &v) {
                     return YaccValue::ofNum(-v[1].asNum("expr: $2"));
                 },
                 "expr-neg", uminusLevel});
    r.push_back({"expr", {"LPAREN", "expr", "RPAREN"},
                 [](std::vector<YaccValue> &v) { return v[1]; },
                 "expr-paren", 0});
    r.push_back({"expr", {"NUM"}, {}, "expr-num", 0});      // 缺省 $$ = $1
    r.push_back({"expr", {"ID"},
                 [&env](std::vector<YaccValue> &v) {
                     auto it = env.vars.find(v[0].asStr("expr: $1"));
                     if (it == env.vars.end())
                         throw std::runtime_error("undefined variable: " + v[0].str);
                     return YaccValue::ofNum(it->second);
                 },
                 "expr-id", 0});
    return r;
}

// ---------- error 记号文法（本章新件，L 书 §5.7.3） ----------
std::vector<YaccRule> calcRulesErr(CalcEnv &env) {
    std::vector<YaccRule> r = calcRules(env, 2);
    // stmt → error ';'  ：yacc 的 error 记号——一个不出现在任何词法规则里的
    // 伪终结符。表构造器把它当普通终结符对待（照常造出 shift 列），
    // 恢复驱动在出错时"注入"一个 error token 走这条路。
    r.push_back({"stmt", {"error", ";"},
                 [](std::vector<YaccValue> &) { return YaccValue::empty(); },
                 "stmt-err", 0});
    return r;
}

// ---------- LL(1) 版（第 6 章消左递归手法的应用） ----------
LLGrammar calcLL() {
    LLGrammar g;
    g.start = "prog";
    g.nonterms = {"prog", "progt", "stmt", "expr", "exprt", "term", "termt", "factor"};
    g.terms = {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "LPAREN", "RPAREN"};
    g.prods = {
        {"prog",  {"stmt", "progt"}},
        {"progt", {"stmt", "progt"}},
        {"progt", {}},
        {"stmt",  {"ID", "=", "expr", ";"}},
        {"stmt",  {"print", "expr", ";"}},
        {"expr",  {"term", "exprt"}},
        {"exprt", {"+", "term", "exprt"}},
        {"exprt", {"-", "term", "exprt"}},
        {"exprt", {}},
        {"term",  {"factor", "termt"}},
        {"termt", {"*", "factor", "termt"}},
        {"termt", {"/", "factor", "termt"}},
        {"termt", {}},
        {"factor", {"NUM"}},
        {"factor", {"ID"}},
        {"factor", {"LPAREN", "expr", "RPAREN"}},
        {"factor", {"-", "factor"}},
    };
    return g;
}

}  // namespace tip
```

## 10.8　本章开发的真坑复盘（五个，全部真实发生）

**坑一：悬垂引用（症状：bad_alloc 爆内存）**。

- 症状：进程直接 bad_alloc，无任何输出。
- 定位：崩溃栈在 llParse → follow.at → map 炸。
- 根因：`tip::LL1 ll(tip::calcLL());`——LL1 的成员是 `const Grammar &`，绑到了**返回的临时对象**上；临时量在语句末析构，follow 计算读的是已释放内存。
- 修复：先 `LLGrammar llg = calcLL();` 存变量，再构造 LL1。
- 防复发：**引用成员的构造函数接裸临时量**是 C++ 的经典陷阱；教学代码可以在 LL1 构造器加 `const LLGrammar &` + 文档注明生命周期要求（06 章原版就这么用——它的 main 也存了变量，坑被原章的用法掩盖了）。
- 迁移：任何"持有引用的聚合"传临时都是悬垂——值语义（存副本）是默认安全取向。

**坑二/坑三：双副本撞名（症状：redefinition 编译错 ×2）**。

- 症状：`tip::Grammar` 与 `tip::ParseResult` 重定义。
- 根因：06 副本（LLGrammar 体系）与 08/09 副本（Grammar 体系）在同一个命名空间里各自定义了同名结构——两章当年各自独立，从没同屋檐过。
- 修复：06 副本改名 LLGrammar/LLParseResult（机械替换 + 注释注明）。
- 迁移：**复制式教学仓库的命名空间是共享的**——跨章组队时符号撞名是结构税，改名前缀（LL/LR）比命名空间嵌套侵入小。

**坑四：Panic 先弹栈后丢输入（症状：恢复多报一条假诊断）**。

- 症状：LR Panic 对缺分号语料报 2 条（@7、@8），LL Panic 报 1 条。
- 定位：第一条诊断后弹栈落进了"表达式上下文"（z 被当成 expr→ID 归约），'=' 处二次报错。
- 根因：恢复次序错了——**先动栈再对输入**，把 z 送进了错误的上下文。
- 修复：input-first——先丢输入到当前状态能接受（栈不动），栈的期望就是同步集；对缺分号语料一步到位 1 条诊断，且 y=2 完整保住。
- 迁移：恢复器的次序设计（动栈 vs 动输入）直接决定级联行为——**优先修输入、栈是最后手段**，因为栈承载的是已解析的结构。

**坑五：对照语料的形状差（症状：[tail match] 0）**。

- 症状：S4 的尾部归约比对失败，肉眼看日志明明一致。
- 定位：无错对照语料 `z = 3; print z;` 的第一条语句用 `prog → stmt`（基产生式）起头，恢复版同一位置是 `prog → prog stmt`（滚雪球产生式）——**同一句话在序列头部与中部的归约形状不同**。
- 修复：对照语料加前缀 `q = 0;`，让两边都处于"滚雪球"形态。
- 迁移：**对账语料与被对账语料必须结构对齐**——比较归约序列时，头部效应（首语句 vs 后续语句）是最常见的伪差异。

五坑的共性：坑一是**生命周期接缝**（临时量与引用成员）、坑二/三是**命名空间接缝**（双副本同屋）、坑四/五是**语义接缝**（恢复次序、对照形态）。加上第 9 章的五坑（字符集/协议/编号/防御/惰性），两章十坑全部长在接缝上——**接缝清单就是测试清单**，这张经验表值回两章的开发时间。

## 10.9　小结与练习

本章把错误恢复做成了四档火力（None/TokenDel/Panic/ErrorProd × LL/LR 双侧），全部实证：检测点 10/10 打平、级联 3→1、error 记号续行、恐慌抢救求值、短语级有界。核心心法三条：**检测是规范属性、恢复是设计决策、级联是恢复器的第一敌人**。

### 10.9.1　与第 9 章的连续性复盘

两章合起来是一部"驱动器工程学"的连续剧，回放一遍主线：

- 第 9 章造机器：值栈让归约顺便完成计算；优先级让冲突变成语义；嵌入动作让 ε 产生式长出新用途。
- 本章给机器装安全气囊：同一个驱动循环，错误分支按四档火力分派——**机器没换，策略换了**。
- 两章的坑账连读：十个坑全部在接缝（字符集/协议/编号/防御/惰性/生命周期/命名/次序/形态）——接缝清单就是两章的测试清单。
- 向后看：第 12 章的作用域检查是"语义层的错误检测"（检测点从栈顶状态换成符号表查询）、第 21 章的调用序列是"归约五步的运行时版"——错误处理的谱系从语法层一路延伸到语义层与运行时层，每一层的"检测-恢复-续行"三段式都同构。

### 10.9.2　三条心法的出处

- **检测是规范属性**：§10.1 的两种检测定义（空表项/空动作格）都指向"第一个不可能的 token"——这不是实现选择，是文法类给的保证；实证是 S2 的 10/10 打平。
- **恢复是设计决策**：§10.2 的两个变体（LL 修栈/LR 修输入）殊途同归——同步点选哪、先动谁，都是人在选；实证是 S3/S5 的对照。
- **级联是第一敌人**：§10.2.1 的三连假错误——一次真缺分号报三条；实证是 TokenDel 的 @7/@8/@9 三行诊断，与 Panic 的单行对照。

三条心法对应的三个数：**10/10、1/3、3→1**——本章的全部论点压缩在三个数字里，这也是教程"机器证人"方法论的最小样本。

**本章术语速查**：

- **检测点**：分析器第一次走不下去的 (状态, token) 对。
- **规范检测**：在第一个不可能的 token 处报错——不早不晚。
- **恐慌模式**：丢输入到同步点（FOLLOW/状态期望），承认"这一段解析不了"。
- **同步集**：恢复的目标 token 集——语句边界、块边界。
- **级联假错误**：一次真错误引发的连锁误报——恢复器的头号 KPI。
- **短语级恢复**：插入/删除/替换的最小修复，带抖动守卫。
- **error 记号**：文法里的伪终结符，声明式的恢复点（yacc 官方姿势）。
- **input-first**：先丢输入后动栈的恢复次序——保住已解析结构。
- **抖动**：不消耗任何资源的修复反复执行——原地打转的死循环风险。
- **守卫**：连续 N 次无进展修复后强制前进的闸门。
- **抢救率**：恢复后保住的语义量（变量赋值、语句求值）与无错版之比。
- **容错 AST**：带错误节点的树——IDE 在残缺结构上继续工作的地基。
- **FOLLOW 同步**：LL 恢复的经典同步集来源——丢输入到 FOLLOW(A) 弹 A。
- **活前缀**：LR 栈内容的数学性质——任何时刻都是某句型规范前缀。
- **双创口守卫**：本章 Phrase 的 N=2 版本——两次无消耗修复后强制吃一个。

**阅读自检（合上书回答）**：

1. 四档火力各自动的是栈还是输入？哪一档语义损失最小、哪一档位置最精确？
2. TokenDel 的三条诊断为什么恰好三条（不是两条或四条）？数一遍 §10.2.1 的表。
3. error 记号的三步里，为什么"弹栈至 error 可移进"必须发生在"移进 error"之前？
4. S5 的抢救为什么保住 y=2 却丢了 z=3？换成 LL 版 Panic 结果一样吗？
5. 单调性论证中度量函数是什么？为什么字典序递减保证终止？

**与 L 书的取材对照**：

| 本章 | L 书 | 主题 |
|---|---|---|
| §10.1 | §3.3.2（错误性质）、§5.7.1 | 检测点与 LR/LL 论断 |
| §10.2 | §4.5.1–4.5.2、§5.7.2 | 恐慌模式与应急方式 |
| §10.3 | §4.5.2 后半 | 短语级修复 |
| §10.4 | §5.7.3–5.7.4 | error 记号与 TINY 实例 |
| §10.5–10.6 | 教程综合 | 诊断质量与选型 |
| §10.7–10.8 | 本章自创 | 机器证人与坑账 |

原书另有两块本章有意未展开：**4.5.3 的 TINY 分析程序错误校正**（它的递归下降版同步集策略已由 §10.2 的 LL 变体覆盖）与 **5.7.4 的 Yacc 错误校正细节**（yyerrok 的复位语义——它对应"恢复后清错误状态"，本章 ErrorProd 分支的隐含行为，练习 7 的扩展点）。教程的分工原则不变：机制入正文、边角留练习。

**练习**（前四题有解答要点）：

1. 给 LR 的 TokenDel 加"连续删除上限"（删 3 个就升级 Panic），跑 S3 语料——诊断数变成多少？（要点：3 条诊断里第 3 条时已对齐，上限 2 会让第 3 步升级为丢输入到 `;`——仍是 1 条假错误被抑制为……自己跑。）
2. 把 Panic 的同步集从"状态期望"改成"固定 {; ID print}"（语言级同步集），对 S5 语料的抢救率有变化吗？（要点：无变化——状态期望恰好就是这三个；但换一个"错误在表达式内部"的语料，两者分歧。）
3. 为 LL 版也实现 error 记号（LL 的错误产生式：`stmt → error ;` 在 LL 表里怎么造？）。（要点：LL 表的 error 当普通终结符造表；恢复时注入——与 LR 完全同构，try it。）
4. 构造一个"LL 检测晚于 LR"的语料：把 calcLL 的 factor 公共前缀故意合并（`factor → pre tail`，pre 吃 `( expr` 与 `( stmt` 的公共部分），观察 S2 表变化。（要点：合并丢失分支信息后，某些错误要等更多 token 才能排除——equal 从 10 降下来。）
5. （进阶）把诊断消息升级为黄金句式：`第 N 行：期待 {…}，遇到 <tok>`——需要词法层把 line 填进 LexTok（MiniLex 的 scan 已有位置信息可顺带计算）。（要点：MiniLex 的 scan 循环里数 `\n` 即得行号；期望集在两个驱动器里都唾手可得——LL 的 FIRST(栈顶)、LR 的 action keys。）
6. （进阶）测量恢复的"丢弃率"：每条语料记录丢弃的 token 数/总 token 数，画四档火力的对比表。（要点：给 RecoverOut/LLResult 加 dropped 字段，恢复分支里每次 ++i/丢输入计数；预期排序：Phrase < ErrorProd ≈ Panic < TokenDel 的语义损失，但 TokenDel 不"丢弃"只是逐个吃——度量口径先想清楚。）
7. （进阶）给 ErrorProd 加嵌套 error（`block → { stmts }`、`stmts → stmts stmt | error ;`），验证"块边界同步优于语句边界"在什么语料下成立。（要点：构造"错误密集"语料——两条错语句相邻时，块级同步一次吞两条、语句级各吞一次；诊断数与覆盖率的取舍再次出现。）
8. （大题）实现 replace 修复（弹 X 吃 a）并设计它的守卫——它与 insert/delete 的组合会不会破坏单调性论证？（提示：replace 同时消耗输入与栈，单调；真正危险的是"推导后回到同一格局"的环——构造一个能成环的修复组合并证明守卫拦得住它。）

**产出型自查**：

1. 默写 error 记号三步协议，指出每步动的是栈还是输入。
2. 缺分号语料在四格（TokenDel/Panic × LL/LR）的诊断数各是多少？为什么 TokenDel 恰好三条？
3. input-first 的"栈不动"为什么能保住 y=2 的赋值？
4. 单调性论证为什么能证明 Phrase 步数有界？守卫在这论证里是什么角色？
5. LL 与 LR 的检测点在本章语料上为何 10/10 相等？Louden"通常早于"的准确条件是什么？
