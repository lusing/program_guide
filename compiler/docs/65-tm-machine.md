# 第 65 章　TM 目标机器与 TINY 代码生成：一台完整的机器，一次完整的编译

教程的代码生成线（第 61–63 章）讲的是算法——寄存器怎么分、指令怎么选；上一章（64）看的是真机——真机有多"脏"。本章造**一台自己的机器**：TM（Tiny Machine），Louden《编译原理及实践》§8.7 的教学目标机——只读指令存储 + 数据存储 + 八个寄存器，**没有 sp、没有 fp、没有硬件栈**，一切运行时组织由编译器手工显式产生。然后在它上面跑一个**完整的编译器**：TINY 语言（§1.7 的 28 行文法）→ 手写扫描器 → 递归下降分析器 → 代码生成器 → .tm 文本 → 两遍汇编器 → 模拟器 → 真实输出。最后把 §8.10 的三档优化逐档叠加，指令数与内存访问双账单调下降，而四档的运行输出**逐字节全等**。

为什么值得做？因为这是**唯一一次看到全貌**：第 17 章 LLVM 替我们做了后端、第 57 章栈机替我们藏了地址、第 63 章伪汇编没有汇编器——TM 线全部自己来。文本汇编要两遍（标号前向引用）、临时值没有硬件栈要软件压弹（tmpOffset）、变量地址要基址约定（gp）、比较要先布尔化（五指令模板）、跳转目标未知要先占位后回填（emitSkip/backup/restore）——**每一件在真编译器里"理所当然"的事，在这一章都要亲手写出来**。

**本章示例：`examples/65_tm_machine`（无 ANTLR；Louden 手写路线全程）**

阅读地图：

- 想看 TM 长什么样 → §65.1（架构与六条使用说明）；
- 想懂"文本汇编为什么要两遍" → §65.2；
- 想懂临时变量的软件栈 → §65.5.3 的压弹账；
- 想懂回填 → §65.5.5（与第 58 章两公式对照）；
- 想看优化怎么逐档省钱 → §65.6 的双账 + §65.7 的 S2 段。

## 65.0　本章要解决的问题与位置

五个子问题，五节正菜：

1. **最小机器能小到什么程度**（§65.1）——16 条指令、8 个寄存器、无专用栈帧设施；"最小指令集如何撑起高级语言"的六条说明。
2. **文本汇编怎么变成指令序列**（§65.2）——标号的前向引用逼出两遍结构；40 行递归下降吃掉一门汇编语言。
3. **机器怎么执行与观察**（§65.3）——取指-执行循环、三错误码、trace 现场表。
4. **TINY 前端**（§65.4）——Louden 原路线的手写扫描器与递归下降（与第 4 章 ANTLR 路线对照）。
5. **代码生成与四档优化**（§65.5–65.6）——cGen 树遍历发码、寄存器约定、软件临时栈、布尔化模板、回填；然后 8.10 三档优化逐档叠加、双账下降。

位置：第十一篇的收官。第 61–63 章的算法在本章的档 1/档 2 里各有一个"预科班形态"（临时变量入寄存器 = 寄存器分配的雏形；变量驻留 = 地址描述器的第一课）；第 66 章起进入并行与放置，机器层的"单线程顺序执行"假设就此结束。

TM 章在 Louden 轮的位置：**压舱石**。前四个新章（09/10/22/64）各取 L 书一角——本端正餐把这四角拼回一台完整机器：TINY 前端是 09/10 手写路线的收官、运行时"没有的东西"是 22 章机制的反衬、真机对照（64 章）给 TM 的每个约定提供出处。L 书自己也是这个结构——第 8 章用前七章的部件装出 TINY 编译器。**读 Louden 轮的正确顺序因此有两种**：按章号线性（教程式）或以本章为锚反向回溯（拼图式）——后者是复习路径。

本章与教程既有机器的分工一句话：**LLVM（17 章）是"会跑的真后端"、栈机（57 章）是"会跑的假后端"、TM 是"自己造的真后端"**——三个"后端"各教一件事：委托、栈语义、全景。

## 65.1　TM：一台最小而完整的机器

### 65.1.1　架构全貌（§8.7.1）

TM 的全部家当：

- **只读指令存储** iMem（1024 条）与**数据存储** dMem（512 单元）——分离的、线性寻址、非负整数地址；
- **8 个通用寄存器** r0–r7，其中 **r7 = PC 是唯一专用寄存器**——没有 sp、没有 fp；
- 启动约定：寄存器清零、**dMem[0] = 数据区最高地址**（程序可查询可用内存量）、PC=0；
- 停机：HALT；错误三码：IMEM_ERR（取指越界）、DMEM_ERR（数据地址越界）、ZERO_DIV。

16 条指令，两种格式：

- **RO 格式** `op r,s,t`（7 条）：HALT/IN/OUT/ADD/SUB/MUL/DIV——算术全部三地址、全部在寄存器上；
- **RM 格式** `op r,d(s)`（9 条）：LD/LDA/LDC/ST + 六条条件转移 JLT/JLE/JGE/JGT/JEQ/JNE——有效地址 **a = d + reg[s]**，一条公式覆盖立即数（LDC：d 即值）、直接（LDA：a 即地址）、间接（LD/ST：a 是数据地址）、相对转移（Jxx：基址 7）四种寻址。

### 65.1.2　最小指令集如何撑起高级语言（六条使用说明，§8.7.1 末）

L 书给 TM 的六条使用说明，是"最小机器的自足性论证"，逐条配本章实现里的对应物：

1. **目标寄存器在前**（ADD r,s,t 的 r 是目的）——类似 80×86 而不同于 SPARC（第 64 章 64.3 的伏笔）；
2. **算术只在寄存器上**——内存值必须先 LD 进寄存器（装入-存储纪律，TM 天生 RISC 风格）；
3. **立即数只有 LDC 一条**——`LDC r, d(0)`：d 直接当值、s=0（reg0 恒为工作区，但"0 号寄存器"不是零寄存器！见坑账）；
4. **`LDA 7, x(7)` 即无条件转移**——a = x + reg[7]，而 reg[7] 在取指后已是 pc+1——**跳转公式就住在寻址公式里**；
5. **无硬件栈**——没有 push/pop 指令、没有 sp；编译器用 dMem 的顶部当软件栈（mp 指向）、tmpOffset 记深度（§65.5.3）；
6. **无帧设施**——没有 fp、没有调用约定；TINY 甚至没有函数（单程序），变量全部"全局"（gp 基址 + 编译期槽位）。

第五、六条是 TM 的教学精髓：**把运行时环境从硬件手里拿走，交还给编译器**——第 21/22 章讲的一切（帧布局、参数传递），在 TM 上都要生成显式指令。TINY 没有函数所以逃过了参数传递；练习 8 会让你给 TM 加 call/return，补上这一课。

### 65.1.3　与教程各目标机的对照（§8.7 收束）

| 维度 | TM（本章） | 字节码 VM（第 57 章） | 伪汇编（第 63 章） | LLVM（第 17 章） |
|---|---|---|---|---|
| 指令形态 | 文本汇编（两遍汇编器） | 字节流（直发） | 文本（无汇编器） | bitcode |
| 操作数家 | 寄存器（8 个） | 隐式值栈 | 伪寄存器 | SSA 值 |
| 内存模型 | 分离 I/D、显式地址 | 帧槽（u8 槽位） | 无内存层 | 托管 |
| 跳转 | 相对 (7) 基址 | u16 偏移回填 | 标号 | 基本块 |
| 执行者 | 自造模拟器 | 自造 VM | 无（教学停在选择） | ORC JIT |
| 可观察性 | trace 每步七寄存器 | DEBUG 栈迹 | — | — |

表的第二行是分水岭：**寄存器机 vs 栈机**。栈机的指令密（无操作数编码）但值没有"名字"；寄存器机的值有家（可驻留、可描述——档 2 优化的全部前提）。第 57 章末尾说"栈机无寄存器名"——本章正是那个对照的正主。

### 65.1.2a　16 条指令全表（opcode / 格式 / 效果 / 本章用点）

| 指令 | 格式 | 效果 | 本章谁在发它 |
|---|---|---|---|
| HALT | RO | 停机 | gen 尾声（每程序恰一条） |
| IN r | RO | reg[r] ← 输入队列 | read 语句 |
| OUT r | RO | 输出 reg[r] | write 语句 |
| ADD r,s,t | RO | reg[r]=reg[s]+reg[t] | 加法；（不是拷贝——坑二） |
| SUB r,s,t | RO | reg[r]=reg[s]−reg[t] | 减法；条件差值 |
| MUL r,s,t | RO | reg[r]=reg[s]×reg[t] | 乘法 |
| DIV r,s,t | RO | reg[r]=reg[s]÷reg[t]（除 0 → ZeroDiv） | 除法 |
| LD r,d(s) | RM | reg[r] ← dMem[d+reg[s]] | 变量读（gp 基）；临时弹栈（mp 基） |
| LDA r,d(s) | reg[r] = d+reg[s] | **拷贝惯用法**（d=0）；无条件跳转（s=7） |
| LDC r,d(s) | reg[r] = d（s 恒 0） | 常量装载；序幕设 mp |
| ST r,d(s) | dMem[d+reg[s]] ← reg[r] | 变量写；临时压栈；序幕清 dMem[0] |
| JLT/JLE r,d(s) | reg[r]</≤0 → reg[7]=a | 布尔化真臂（JLT）；直转真跳 |
| JGE/JGT r,d(s) | ≥/>0 → 跳 | **补条件假跳**（JGE）；练习 4 |
| JEQ r,d(s) | ==0 → 跳 | 布尔化假臂（`=` 比较）；低档假跳 |
| JNE r,d(s) | ≠0 → 跳 | 直转假跳（`=` 的补条件） |

一个"用点"列的观察：**LDA 一身三职**（拷贝/跳转/装地址）——寻址公式的通用性让指令复用成为 TM 的日常；对照 80×86 的 lea 双职（§64.2.2）——**RISC 哲学（少指令、正交）在 16 条里已经成型**。

### 65.1.2b　教学机谱系（TM 的亲威们）

- **Pascal-P 机**（1970s）：P-code 的虚拟机——第 57 章 P-码谱系的起点（57 章补章会再遇）；
- **SCIP 的寄存器机**（SICP 5.2）：scheme 显式控制求值器——"寄存器机器模拟器"的教学经典；
- **DCG/Ocode**（Pascal 编译器族）：教学编译器的目标机群；
- **TM**（Louden 1995）：本表里最晚、也最小的一个——**没有它，L 书的"编译器全景"就停在伪码**；
- **LLVM/JS 引擎**：工业VM——TM 的曾孙辈，寄存器约定/错误码/trace 的直系后代。

谱系的公共设计：**小指令集 + 显式约定 + 可模拟**——教学机的三件套五十年未变；变的只是"约定"的规模（TM 8 寄存器 → V8 的数百虚拟寄存器）。

## 65.2　两遍汇编器：文本怎么变成指令

### 65.2.1　.tm 文本格式

本章的 .tm 格式（cgen 的产物、汇编器的输入）：

- 每行一条指令，**行首的 `N:` 是地址前缀**（汇编器当标号处理——见坑账一）；
- 注释从 `;` 到行尾（cgen 的每个发码点都带注释——**注释即文档**，正文走读直接引用）；
- 标号（本章手编 .tm 语料用）：`label: OP ...`；跳转目标可写标号（汇编器换算成 (7) 相对偏移）。

### 65.2.2　为什么要两遍

前向跳转的目标还不存在——**一遍读不完**。两遍分工：

- **第一遍**：剥注释、剥标号，**记标号 → 行号**；指令先不编码；
- **第二遍**：逐行编码；遇到 `Jxx r,label(7)` 时查表换算：`d = label地址 - (本行行号 + 1)`——与 cgen 的 emitRMAbs **同一个公式**（§65.5.5 的三行注释推演）。

两遍结构与第 14 章 CFG 构造的"先收集后回填"、第 58 章跳转回填是同一形态：**前向引用的通用解法就是占位加回填**——一遍收集、一遍结算。

### 65.2.3　汇编器的 40 行递归下降

.tm 的操作数文法只有两条产生式：

- `operand-RO → NUM , NUM , NUM`
- `operand-RM → NUM , NUM ( NUM )`（d 可为负、可为标号）

40 行递归下降（含诊断）吃掉一门汇编语言——第 6 章的手法在这里的"最小应用"。**汇编器是编译器的镜像**：前端吃高级语言、这里吃指令语言；文法越小，越看清"分析器不过是文法的机械展开"。

**一遍汇编什么时候可行？** 若跳转只许后向（目标已定义），标号表边走边查——一遍够；前向跳转逼出第二遍。有趣的是 cgen **同时住在两边**：repeat 的后向跳直发（一遍心态）、if 的前向跳占位回填（两遍心态）——**发码器的"局部两遍"与汇编器的"全局两遍"是同一件事的两个尺度**。真实工具链里，链接器再做一次更大尺度的"第三遍"（跨文件地址结算）——遍数与引用距离成正比，从语句到文件到库——**前向引用是分遍的普适理由**。

## 65.3　模拟器：执行与观察

### 65.3.1　取指-执行循环

```cpp
int pc = reg[7];
TmIns cur = ins[pc];
reg[7] = pc + 1;      // 取指即自增——跳转指令随后覆盖它
...执行 cur...
```

三行是 TM 执行语义的全部骨架：**PC 先行自增、跳转后覆**——这个次序决定了相对跳转公式里的 `+1`（§65.5.5）。执行分支按 RO/RM 分派：RO 直算；RM 先算有效地址 a = d + reg[s]（越界即 DMemErr），六条 Jxx 检查 reg[r] 的符号/零、命中则 reg[7] = a。

### 65.3.2　三错误码与现场

- IMEM_ERR：取指越界（含步数保险丝——教学实现把"疑似死循环"并入同一通道）；
- DMemErr：LD/ST 的 a 越界——错误现场带 pc（S4 段的证人）；
- ZeroDiv：DIV 的除数为零——除法前显式检查。

错误码是**机器合同的一部分**：编译器（与手编 .tm 的程序员）依赖它们诊断。第 10 章的"检测是规范属性"在机器层的回声——错误码就是机器的"检测点"。

### 65.3.3　trace：每步七寄存器现场

`step pc OP r0 r1 r2 r3 r4 r5 r6`（执行后快照）——正文的手推账与机器的执行账**逐行对上**（§65.7 的 S3 段）。trace 是本章最重要的可观察性设施：教学机器的全部价值在于**每一步都看得见**——真机要靠性能计数器与调试器才能凑齐的信息，这里一行 printf。

### 65.3a　tmasm.cpp 逐函数走读

- `split(raw, lineno)`——一行的三级剥壳：
  - 剥注释：`;` 之后全弃；
  - 剥标号：**冒号出现在第一个空白之前**才算标号（`loop:` 是标号、`3(7)` 里的括号不受影响）；
  - 切词：istringstream 按空白切——`OP` 与操作数各成一词。
- `splitCommas(operand, ln)`——操作数串（如 `5,511(0)`）按逗号切段；**两段是 RM、三段是 RO**——段数就是格式判据（坑账一的现场：段与字段的错位曾让 RO 全崩）。
- `assemble()` 两遍主体：
  - 第一遍：逐行 split、空行跳过、**标号记入 labels 表**（值 = 当前行数——"下一条指令的地址"）；非空行进 lines；
  - 第二遍：查 opTable 得操作码；RO 走三段直装（**字段序注释钉死**：TmIns 是 op,r,d,s,t——RO 无 d 置 0）；RM 拆 `d(s)`：
    - dpart 数字或负号 → 直接数；
    - dpart 是标号 → 查表换算 `d = 标号地址 - (本行 + 1)`——**与 emitRMAbs 同一公式**（两处代码、一条代数，§65.5.5 的三行注释两边通用）；
    - 基址不是 7 而用标号 → 报错（标号目标只许 pc 相对——**约定收紧防手滑**）。
- `disasm(i)`——一行反汇编（trace 的字段就是它打的）。

**汇编器与 cgen 的接口哲学**：cgen 发的每行都带 `N:` 地址前缀与 `; 注释`——汇编器把前者当标号（无害）、后者剥掉；**文本即接口**让中间产物可读、可 diff、可手编（S4 的错误语料直接手写 .tm 上汇编器）——教学机器的全部可调试性来自这个决定。

### 65.3b　tmvm.cpp 逐函数走读

- boot 段：寄存器清零、`dmem[0] = DADDR-1`（书 §8.7.1 的"可用内存量写在头单元"）、PC=0；
- `dmemAt(a)` 闭包：**越界检查的唯一关口**——LD/ST 都经它；命中 DMemErr 时把 pc 写进现场再抛；
- 主循环（§65.3.1 的三行骨架展开）：
  - 步数保险丝：超限并入 IMemErr 通道（教学口径：死循环是"取指失控"的特例）；
  - 取指：`pc = reg[7]`、**先自增再执行**——跳转公式 `+1` 的来源；
  - RM 先算 `a = d + reg[s]`（在 switch 外统一算——RO 用不上、RM 全用）；
  - 执行 switch：16 个 case 一一对应；HALT 带打印 return；Jxx 命中覆写 reg[7]；
  - trace 尾拍：执行后打印七寄存器快照（r7 是 pc 下一跳，不打自留）。
- IN 的教学口径：输入从队列取、**空则给 0**（真实模拟器读 stdin——对账环境无 stdin，口径写进注释）。

**模拟器的"三个一律"**：越界一律查（dmemAt）、错误一律带现场（pc）、执行一律可 trace——**机器的合同用代码写死**，而不是靠使用者小心。

## 65.4　TINY 前端：Louden 的手写路线

### 65.4.1　TINY 语言（§1.7）

八关键字（if/then/else/end/repeat/until/read/write）、两种语句族（条件/循环）+ 三种简单语句（赋值/读/写）、表达式两级（加减/乘除）+ 括号、比较只出现在条件位、注释 `{ ... }`。28 行文法撑起四个语料：阶乘（repeat 乘法循环）、gcd（欧几里得取模）、分支（if-else 双臂）、嵌套（min + 计数循环）。

### 65.4.2　扫描器（§2.5 的路线）

保留字表 + 标识符/数字 + `:=` 双字符前瞻——**与第 5 章 DFA 路线对照**：手写扫描器靠 if-else 链、生成器靠自动机，语义空间相同（最长匹配在手写版里靠字符类别检查自然实现）。Louden 的 TINY 编译器全部手写——1995 年的教学自包含（没有 ANTLR、没有 flex）——本章沿这条路线**不是怀旧**，而是让前端的每一行都可读。

### 65.4.3　递归下降分析器（§4.4 的路线）

每语句一个过程（ifStmt/repeatStmt/assign/read/write）、表达式三层（exp/term/factor）——第 6 章的分层法、第 22 章教学语言的同款结构。错误消息带行号（"第 N 行：期待 X，遇到 Y"）——第 10 章黄金句式的第三次落地。

与第 4 章 ANTLR 路线的分工：TIP 主线语言用生成器（工业感），TINY 用手写（可控感）——**一个教程两条路线，读者各取所需**。

### 65.4.2a　tinyscan.cpp 逐函数走读

- `scan(src)` 主循环四大分支：
  - 空白/换行：跳过并计行号（`line` 进 token——诊断的数据源）；
  - `{ ... }` 注释：吃到配对 `}`，未闭合报"注释未闭合"（带行号）；
  - 标识符/保留字：`identStart/identChar` 分类成词，**查 keywords 表定种类**——查到是关键字、查不到是 ID。**最长匹配在手写版里天然成立**：标识符分支一次吃尽所有 identChar（`x9y` 不会被切开）；
  - 数字：连吃 digit（无小数——TINY 只有整数，与书一致）。
- 双字符前瞻只有一个：`:=`。单字符 else-if 链覆盖其余 11 个符号——每个 case 一行。
- `fail` 闭包：词法错误统一带行号——第 10 章黄金句式的词法半。

**与第 5 章 Scanner 的并排读**（同一语义、两种实现）：

| 机制 | 第 5 章（DFA） | 本章（手写） |
|---|---|---|
| 最长匹配 | lastAcc 回退 | 分支一次吃尽 |
| 保留字优先 | 规则声明序着色 | keywords 表查一次 |
| 行号 | 未实现（留练习） | 内建 |
| 规模 | 441 行自动机 | 90 行 if-else |
| 适用 | 规则多变/需证明 | 规则少/需可读 |

表最后一行是选型判据：TINY 只有 15 类 token，手写完胜；TIP 的 token 族更大且要配 ANTLR，DFA 路线合理。

### 65.4.3a　tinyparse.cpp 逐函数走读

- `stmtSeq()`：`stmt { ';' stmt }`——分号是**分隔符**（最后一条不带）；`eat(Semi)` 循环。
- `stmt()`：switch 当前 token 分派到五个过程——**一个 switch 就是文法的语句族**。
- `ifStmt()`：`else` 可选（eat 试探）；**end 收尾**让悬挂 else 在 TINY 根本不存在（对照第 6/10 章的老朋友——文法设计预防了恢复难题）。
- `repeatStmt()`：条件在**后面**（直到型）——对发码的回跳形状有直接影响（§65.5.5）。
- `cond()`：比较只允许出现在条件位（L 书口径）——布尔化只此一处（§65.5.4）。
- `exp/term/factor` 三层：优先级住调用层级；左递归已被文法写成迭代（`while eat(Add)`）——**文法作者替分析器消了左递归**。
- `want()/fail()`：诊断双件套——期待什么、遇到什么，都带行号。

**左结合的三层同构**：`a - b - c` 在文法里是迭代循环 → AST 是左折叠 `((a-b)-c)` → 发码是两轮压弹（§65.5.3）——**文法、树、码三层形状一致**，"文法即语义"最具体的一次展示。

TINY 文法全表（每行一条，front 的对照面）：

- `program → stmtSeq EOF`；
- `stmtSeq → stmt { ';' stmt }`；
- `stmt → ifStmt | repeatStmt | assign | read | write`；
- `ifStmt → 'if' cond 'then' stmtSeq [ 'else' stmtSeq ] 'end'`；
- `repeatStmt → 'repeat' stmtSeq 'until' cond`；
- `assign → ID ':=' exp`；`read → 'read' ID`；`write → 'write' exp`；
- `cond → exp relop exp`（relop ∈ {<, =}）；
- `exp → term { ('+'|'-') term }`；`term → factor { ('*'|'/') factor }`；
- `factor → '(' exp ')' | NUM | ID`。

十行文法、四个语料、16 条指令——**TINY/TM 是编译器全景的最小标本**：麻雀的五脏按真鸟的比例。

### 65.4.4　与第 4 章 ANTLR 路线的对照

**语料与文法的对照检查表**（每语料用到哪些产生式——覆盖率的自证）：

| 语料 | 用到的语句/表达式形状 |
|---|---|
| fact | read、assign（×2）、repeat、二元乘/减、比较 =、write |
| gcd | read×2、assign×3、repeat、三元嵌套（u − u/v*v）、比较 = |
| branch | read、if-else 双臂、assign、比较 <、乘、加减混合、write×2 |
| nest | read×2、if-else、repeat、比较 < 与 =、自增（d+1）、乘 |

四语料合计覆盖文法全部产生式（else 双臂、两种 relop、乘除加减、嵌套括号经 gcd 的 u/v*v）——**语料集即文法的测试覆盖**；新语料进 corpus 前先过这张表：它贡献了哪条产生式的第一次覆盖？

## 65.5　代码生成器：把树变成指令

### 65.5.1　寄存器约定（§8.8 的第一笔账）

八个寄存器的分工表（cgen 的第一处设计决策）：

| 寄存器 | 角色 | 约定的由来 |
|---|---|---|
| r0 = ac | 累加器：表达式的结果家 | 一切 genExp 的产物落这里 |
| r1 = ac1 | 副累加器：左操作数家 | 二元运算的 lhs 中转 |
| r2–r4 | 临时/驻留（按档位分派） | 档 1 的临时仓、档 2 的变量家 |
| r5 = mp | 内存顶指针：软件临时栈基 | 指向 dMem 最高地址，临时向下长 |
| r6 = gp | 变量基址：全局区起点 | 变量槽 = gp + 编译期偏移 |
| r7 = PC | 程序计数器（硬件专用） | 取指自增、跳转覆盖 |

**约定即接口**：cgen 的每个发码点、模拟器的每个 trace、正文每笔手推账，都对着这张表——寄存器约定是目标机文档的第一页（第 64 章 Borland 的 ax/bx/bp 是它的真机版）。

标准序幕两条（§8.8.2）：`LDC 5,511(0)`（mp 指向数据区顶）+ `ST 0,0(0)`（清 dMem[0] 的启动标记）。**两条指令就是"运行时环境的全部初始化"**——对照第 21 章调用序列五步、第 64 章 Borland 序幕三件套：TINY 没有函数，环境初始化退化到两条——**运行时复杂度与语言特性严格成正比**。

### 65.5.2　cGen 树遍历发码

结构照书（§8.8.2）：`gen(program) → genSeq → genStmt → genExp`——深度优先、语句序发码、表达式后序（先子后算）。这是第 15 章 Visitor 求值的**发码版**：同样的树遍历，一个算值、一个发指令——**解释器与编译器在树遍历这一层是同一台机器**（第 15 章的论断在此第三次验证）。

### 65.5.3　tmpOffset 软件临时栈（§8.8.2 的核心机制）

二元运算 `a op b` 的通用序列（档 0）：

```text
genExp(a)            ; ac = a
ST 0,0(5)            ; 压栈：dMem[mp+0] = a，tmpOffset 0→-1
genExp(b)            ; ac = b
LD 1,0(5)            ; 弹栈：ac1 = dMem[mp+0]，tmpOffset -1→0
ADD 0,1,0            ; ac = ac1 + ac
```

四行里的两行（ST/LD）就是**没有硬件栈的代价**——每个非叶二元运算一压一弹。tmpOffset 压负弹正（`ST tmp--` / `LD ++tmp`），嵌套表达式自然成栈——`a*b+c*d` 压两弹两（S3 trace 的 10–12 步现场）。这是第 49 章 IDE 之前、第 18 章 TAC 临时变量之外，**内存临时栈的第三个形态**——软件栈的全部智慧就在"偏移跟着递归深度走"。

#`a*b + c*d` 的完整压弹账（档 0，四嵌套深度 2 的标准例）：

- `LD ac,a` → `ST 0,0(5)`（压 a，tmp 0→−1）；
- `LD ac,b` → `LD 1,0(5)`（弹 a 进 ac1）→ `MUL ac,ac1,ac`（ac = a×b）；
- `ST 0,0(5)`（**压左积**，tmp 0→−1——第一项结果也要让路）；
- `LD ac,c` → `ST 0,-1(5)`（压 c，tmp −1→−2——**两层栈深**）；
- `LD ac,d` → `LD 1,-1(5)`（弹 c）→ `MUL`（ac = c×d）；
- `LD 1,0(5)`（弹左积）→ `ADD ac,ac1,ac`（ac = a×b + c×d）。

十二行里 ST/LD 各四——**每个二元节点一压一弹的规律**在嵌套下依然成立（压的时机跟着递归深度走）；S3 trace 的第 10–12 步（gcd 的 `u − u/v*v`）正是这份账的活体。**软件栈的深度 = 表达式树的高度**——这就是"没有硬件栈的代价按树高付费"的精确表述。

### 65.5.3a　与第 57 章栈机的深对比

TM（寄存器机）与字节码 VM（栈机）在"临时值放哪"上的两套哲学：

| 维度 | TM（本章） | 栈机（第 57 章） |
|---|---|---|
| 临时值的家 | 寄存器（r2–r4）或软件栈（dMem） | 隐式值栈（指令的操作数即栈） |
| 二元运算的形状 | 显式三地址（ADD r,s,t） | 无操作数（OP_ADD 弹二压一） |
| 压弹指令 | 显式 ST/LD（档 1 可消除） | 不存在（栈即语义） |
| 值有名字吗 | 有（寄存器号/槽位）——**驻留优化的前提** | 无——优化要先"装回"寄存器 |
| 指令密度 | 低（地址要编码） | 高（每条 1 字节级） |
| 谁的谱系 | RISC/LLVM IR | JVM/P-码/wasm |

表中间一行是分水岭：**值有没有"名字"决定优化能不能指名道姓**——档 2 的 `d→r3` 必须有名字；栈机的 JIT（如 HotSpot）第一件事就是把栈"装"进虚拟寄存器（第 59 章值表示的伏笔）。**栈机省了编码、费了优化；寄存器机反过来**——两章并读，这个 trade-off 从口号变成机制。

### 65.5.3b　与第 21 章活动记录的对照

TM 没有函数，但第 21 章的帧概念在本章有全部的"前件"：

- 帧的**局部变量区** → gp+槽位（TINY 的"全局帧"就是活动记录退化的样子：一个函数、一帧永驻）；
- 帧的**临时区** → mp 向下的软件栈（活动记录里"编译器生成的临时变量区"的显式版）；
- **帧指针** → gp（单帧世界里 fp=gp）；**栈指针** → mp 管临时、不管帧（帧不增长）；
- 缺的：控制链/返回地址/参数区——全部随"无函数"缺席。

**练习 8 补函数时，这张对照表就是施工图**：CAL 压返回地址（控制链）、帧切换改 gp、参数按第 22 章四机制选一——第 21/22 章的运行时篇在 TM 上的总装，教程把这个"总装"留作大题是对读者的信任。

## 65.5.4　比较的布尔化：五指令模板（§8.8.2）

条件位计算 `lhs < rhs`（档 0–2）：

```text
SUB 0,1,0      ; ac = lhs - rhs
JLT 0,2(7)     ; 差 < 0（即 lhs < rhs）→ 跳过两条到 LDC 1
LDC 0,0(0)     ; 假：ac = 0
LDA 7,1(7)     ; 跳过真臂
LDC 0,1(0)     ; 真：ac = 1
```

五条指令把比较物化为 0/1——TINY 其实不需要布尔值（比较只在条件位），Louden 仍选择通用形（**为将来有布尔值的语言预留**，§8.8.2 明说）。这个选择在档 3 被撤销（直转，省五条中的四条）。与第 58 章短路布尔化的对照：**那章的布尔化服务于短路语义（跳转即短路），这章服务于通用性（值可传递）**——同一家族的两个分支。

### 65.5.5　回填：emitSkip / backpatch 与两条公式

if 语句（无 else）的发码骨架：

```text
<条件计算>           ; ac = 0/1（档 0–2）
<skip>              ; 占位：假 → end
<then 序列>
end:                ; 回填占位为 JEQ 0, end-(skip+1) (7)
```

**回填公式**（本章与第 58 章的连心桥）：

- 模拟器三行注释：执行位于 pc 的 RM 跳转时 `reg[7] = pc+1`（取指自增）、目标 `a = d + reg[7]`、命中则 `reg[7] = a`；
- 要跳到绝对地址 addr：`d = addr - (pc + 1)`——**emitRMAbs 的全部代数**；
- 对照第 58 章字节码回填：patchJump 偏移 = 目标 − 字段地址 − 2——公式形状相同、常数不同（字节流的"取指自增"藏在 ip 推进里）。

**写公式先写三行注释再代数、不许心算**——第 55 章的老规矩在本章的每处回填（if 双臂、repeat 回跳、布尔化 LDA）重新生效。

repeat 的回跳是**后向**的——目标已知、无需占位：`emitRMAbs("Jxx", AC, top)` 直接发。**前向要占位、后向直发**——回填的全部分类学。

### 65.5.6　发码器全文走读

```cpp
// file: src/cgen.cpp
// file: src/cgen.cpp
// 代码生成器实现。寄存器约定与回填公式全部照 L 书 §8.8：
//   ac=r0（结果家）、ac1=r1（左操作数家）、mp=r5（内存顶=临时栈基）、gp=r6（变量基址）。
// 回填公式（写公式先写模拟器三行注释再代数，不许心算）：
//   模拟器执行位于 pc 的 RM 跳转时 reg[7] 已是 pc+1，目标 a = d + reg[7]；
//   要跳到绝对地址 addr ⇒ d = addr - (pc + 1)。
#include "cgen.hpp"

#include <algorithm>
#include <functional>
#include <sstream>

namespace tiny {

// ---------- 发码与回填 ----------

void Cgen::emitRO(const char *op, int r, int s, int t, const std::string &cmt) {
    std::ostringstream os;
    os << op << " " << r << "," << s << "," << t;
    if (!cmt.empty()) os << " ; " << cmt;
    code_.push_back(os.str());
}

void Cgen::emitRM(const char *op, int r, int d, int s, const std::string &cmt) {
    std::ostringstream os;
    os << op << " " << r << "," << d << "(" << s << ")";
    if (!cmt.empty()) os << " ; " << cmt;
    code_.push_back(os.str());
}

void Cgen::emitRMAbs(const char *op, int r, int addr, const std::string &cmt) {
    int here = static_cast<int>(code_.size());
    emitRM(op, r, addr - (here + 1), PC, cmt);
}

int Cgen::emitSkip() {
    code_.push_back("; <skip>");
    return static_cast<int>(code_.size()) - 1;
}

void Cgen::backpatch(int at, const std::string &line) { code_[at] = line; }

// ---------- 变量表 ----------

Cgen::VarInfo &Cgen::var(const std::string &name) {
    auto it = vars_.find(name);
    if (it == vars_.end()) {
        VarInfo v;
        v.memLoc = static_cast<int>(vars_.size());
        it = vars_.emplace(name, v).first;
    }
    return it->second;
}

void Cgen::countWeights(const Program &p) {
    // 引用计数 ×10^循环深度（L 书 8.10.2 的加权法：循环内引用重复执行）
    std::function<void(const std::vector<std::unique_ptr<Stmt>> &, int)> walk =
        [&](const std::vector<std::unique_ptr<Stmt>> &ss, int depth) {
            for (const auto &s : ss) {
                long long w = 1;
                for (int k = 0; k < depth; ++k) w *= 10;
                std::function<void(const Exp &)> countExp = [&](const Exp &e) {
                    if (e.kind == Exp::Kind::Id) var(e.name).weight += w;
                    if (e.lhs) countExp(*e.lhs);
                    if (e.rhs) countExp(*e.rhs);
                };
                switch (s->kind) {
                case Stmt::Kind::Assign: var(s->name).weight += w; countExp(*s->exp); break;
                case Stmt::Kind::Read: var(s->name).weight += w; break;
                case Stmt::Kind::Write: countExp(*s->exp); break;
                case Stmt::Kind::If:
                    countExp(*s->cond);
                    walk(s->thenSeq, depth);
                    walk(s->elseSeq, depth);
                    break;
                case Stmt::Kind::Repeat:
                    walk(s->body, depth + 1);
                    countExp(*s->cond);
                    break;
                }
            }
        };
    walk(p.stmts, 0);
}

void Cgen::assignResidentRegs() {
    // 8.10.2：权重最高的两个变量驻留 r3/r4（r0-r2 留给临时与工作寄存器）
    std::vector<std::pair<long long, std::string>> order;
    for (const auto &kv : vars_) order.push_back({kv.second.weight, kv.first});
    std::sort(order.begin(), order.end(),
              [](const std::pair<long long, std::string> &a,
                 const std::pair<long long, std::string> &b) { return a.first > b.first; });
    int reg = 3;
    for (const auto &w : order) {
        if (reg > 4 || w.first == 0) break;
        vars_[w.second].reg = reg;
        resident_.push_back({w.second, reg});
        ++reg;
    }
}

// ---------- 临时变量：档位分派 ----------

int Cgen::tempRegFor(int depth) const {
    if (!optTemps_) return -1;
    if (optVars_) return depth == 0 ? 2 : -1;   // 8.10.2：r3/r4 让给变量，临时只剩 r2
    return depth <= 2 ? 2 + depth : -1;          // 8.10.1：r2/r3/r4 三档
}

void Cgen::saveTemp(const char *why) {
    int r = tempRegFor(tmpDepth_);
    ++tmpDepth_;
    if (r >= 0) emitRM("LDA", r, 0, AC, why);
    else emitRM("ST", AC, tmpOffset_--, MP, why);
}

void Cgen::loadTemp(const char *why) {
    --tmpDepth_;
    int r = tempRegFor(tmpDepth_);
    if (r >= 0) emitRM("LDA", AC1, 0, r, why);
    else emitRM("LD", AC1, ++tmpOffset_, MP, why);
}

// ---------- 表达式 ----------

// 叶子（常量/变量）直发目标寄存器——压弹消除的主角。
void Cgen::genLeafInto(const Exp &e, int r, const char *why) {
    if (e.kind == Exp::Kind::Const) emitRM("LDC", r, static_cast<int>(e.val), 0, why);
    else {
        VarInfo &v = var(e.name);
        if (v.reg >= 0) emitRM("LDA", r, 0, v.reg, why);
        else emitRM("LD", r, v.memLoc, GP, why);
    }
}

void Cgen::genExp(const Exp &e) {
    switch (e.kind) {
    case Exp::Kind::Const:
        emitRM("LDC", AC, static_cast<int>(e.val), 0, "load const");
        break;
    case Exp::Kind::Id: {
        VarInfo &v = var(e.name);
        if (v.reg >= 0) emitRM("LDA", AC, 0, v.reg, "var in reg");
        else emitRM("LD", AC, v.memLoc, GP, "load var");
        break;
    }
    case Exp::Kind::Op: {
        const char *op;
        switch (e.op) {
        case Tok::Add: op = "ADD"; break;
        case Tok::Sub: op = "SUB"; break;
        case Tok::Mul: op = "MUL"; break;
        case Tok::Div: op = "DIV"; break;
        default: op = "SUB"; break;   // 比较的差值在 ac，布尔化/直转在条件位处理
        }
        // 档 1 起的叶子直发：右部是常量/变量时直接发进 ac1，省掉一压一弹。
        // 操作数位两路不同：压弹路径 ac=右、ac1=左（RO dst,s,t = ac1 op ac）；
        // 叶路径 ac=左、ac1=右（dst,s,t = ac op ac1）——都要保证 dst = 左 op 右。
        if (optTemps_ && e.rhs->kind != Exp::Kind::Op) {
            genExp(*e.lhs);
            genLeafInto(*e.rhs, AC1, "leaf rhs -> ac1");
            emitRO(op, AC, AC, AC1, "apply op (leaf)");
        } else {
            genExp(*e.lhs);
            saveTemp("op: push left");
            genExp(*e.rhs);
            loadTemp("op: pop left");
            emitRO(op, AC, AC1, AC, "apply op");
        }
        break;
    }
    }
}

// ---------- 条件：布尔化（低档）与直转（8.10.3） ----------

void Cgen::emitCond(const Exp &cond) {
    genExp(*cond.lhs);
    saveTemp("cond: push left");
    genExp(*cond.rhs);
    loadTemp("cond: pop left");
    emitRO("SUB", AC, AC1, AC, "left - right");
    lastRelop_ = cond.op;
    if (!optTest_) {
        // C 风格布尔化五指令模板（§8.8.2）。执行时的 reg[7] 已是 pc+1：
        //   JLT/JEQ +2(7) 落到 LDC 1（真臂）；否则 LDC 0 后 LDA 跳过真臂。
        const char *j = cond.op == Tok::Lt ? "JLT" : "JEQ";
        emitRM(j, AC, 2, PC, "bool: jump true arm");
        emitRM("LDC", AC, 0, 0, "bool: false = 0");
        emitRMAbs("LDA", PC, static_cast<int>(code_.size()) + 2, "bool: skip true arm");
        emitRM("LDC", AC, 1, 0, "bool: true = 1");
    }
    // tier3：差值留 ac，跳转由 emitJumpIfFalse/True 补条件直发
}

void Cgen::emitJumpIfFalse(int addr, const std::string &why) {
    if (!optTest_) emitRMAbs("JEQ", AC, addr, why);
    else emitRMAbs(lastRelop_ == Tok::Lt ? "JGE" : "JNE", AC, addr, why);
}

void Cgen::emitJumpIfTrue(int addr, const std::string &why) {
    if (!optTest_) emitRMAbs("JNE", AC, addr, why);
    else emitRMAbs(lastRelop_ == Tok::Lt ? "JLT" : "JEQ", AC, addr, why);
}

// ---------- 语句 ----------

void Cgen::genSeq(const std::vector<std::unique_ptr<Stmt>> &ss) {
    for (const auto &s : ss) genStmt(*s);
}

void Cgen::genStmt(const Stmt &s) {
    switch (s.kind) {
    case Stmt::Kind::Assign: {
        genExp(*s.exp);
        VarInfo &v = var(s.name);
        if (v.reg >= 0) emitRM("LDA", v.reg, 0, AC, "assign into reg var");
        else emitRM("ST", AC, v.memLoc, GP, "assign: store var");
        break;
    }
    case Stmt::Kind::Read: {
        emitRO("IN", AC, 0, 0, "read");
        VarInfo &v = var(s.name);
        if (v.reg >= 0) emitRM("LDA", v.reg, 0, AC, "read into reg var");
        else emitRM("ST", AC, v.memLoc, GP, "read: store");
        break;
    }
    case Stmt::Kind::Write: {
        genExp(*s.exp);
        emitRO("OUT", AC, 0, 0, "write");
        break;
    }
    case Stmt::Kind::If: {
        emitCond(*s.cond);
        int toElse = emitSkip();          // 假 → else/end 的跳转占位
        genSeq(s.thenSeq);
        if (!s.elseSeq.empty()) {
            int overElse = emitSkip();    // then 完 → 跳过 else 占位
            int elseAddr = static_cast<int>(code_.size());
            // 回填占位：绝对地址换相对偏移的公式同 emitRMAbs
            std::ostringstream os;
            if (optTest_) os << (lastRelop_ == Tok::Lt ? "JGE" : "JNE");
            else os << "JEQ";
            os << " " << AC << "," << (elseAddr - (toElse + 1)) << "(" << PC << ")"
                << " ; if: jmp to else";
            backpatch(toElse, os.str());
            genSeq(s.elseSeq);
            int endAddr = static_cast<int>(code_.size());
            std::ostringstream os2;
            os2 << "LDA " << PC << "," << (endAddr - (overElse + 1)) << "(" << PC << ")"
                << " ; if: jmp over else";
            backpatch(overElse, os2.str());
        } else {
            int endAddr = static_cast<int>(code_.size());
            std::ostringstream os;
            if (optTest_) os << (lastRelop_ == Tok::Lt ? "JGE" : "JNE");
            else os << "JEQ";
            os << " " << AC << "," << (endAddr - (toElse + 1)) << "(" << PC << ")"
                << " ; if: jmp to end";
            backpatch(toElse, os.str());
        }
        break;
    }
    case Stmt::Kind::Repeat: {
        int top = static_cast<int>(code_.size());
        genSeq(s.body);
        emitCond(*s.cond);
        // until 语义：条件真则落下（退出循环）、假则回跳——回跳就是"假跳"
        emitJumpIfFalse(top, "repeat: while false, loop");
        break;
    }
    }
}

// ---------- 顶层 ----------

std::string Cgen::gen(const Program &p, Tier tier) {
    code_.clear();
    vars_.clear();
    resident_.clear();
    tmpOffset_ = 0;
    tmpDepth_ = 0;
    optTemps_ = tier != Tier::None;
    optVars_ = tier == Tier::Vars || tier == Tier::Test;
    optTest_ = tier == Tier::Test;
    if (optVars_) {
        countWeights(p);
        assignResidentRegs();
    }
    // 标准序幕（§8.8.2）：mp 指向数据区顶（临时栈基）；清 dMem[0]（启动标记）
    emitRM("LDC", MP, 511, 0, "prelude: mp = top of dMem");
    emitRM("ST", AC, 0, 0, "prelude: clear dMem[0]");
    genSeq(p.stmts);
    emitRO("HALT", 0, 0, 0, "end of program");
    std::ostringstream os;
    for (size_t i = 0; i < code_.size(); ++i) os << i << ": " << code_[i] << "\n";
    return os.str();
}

}  // namespace tiny
```

走读锚点（对照 §65.5.1–65.5.5）：

- `emitRO/emitRM/emitRMAbs/emitSkip/backpatch`——发码五件套；RMAbs 的代数在 §65.5.5 的三行注释里；
- `var(name)`——变量表：首次见名分配槽位（gp 偏移）；档 2 的权重与驻留也住这里；
- `saveTemp/loadTemp`——软件临时栈的两端；档位分派在 `tempRegFor`；
- `genExp`——表达式后序发码；**叶直发**（档 1 起的压弹消除）与压弹路径的操作数位差异见注释（坑账四的教训现场）；
- `emitCond/emitJumpIfFalse/emitJumpIfTrue`——条件的两种形态（布尔化/直转）与假跳/真跳的补条件表；
- `genStmt` 五分支——赋值/读/写/if/repeat；if 的双占位回填、repeat 的后向直发；
- `gen` 顶层——档位设定 → 序幕 → 语句序列 → HALT → 带行号输出。

### 65.5.7　cgen 逐函数详读

- 发码五件套：
  - `emitRO(op,r,s,t,cmt)` / `emitRM(op,r,d,s,cmt)`——格式化一行进 code_；**注释随行**（正文走读直接引用产线注释）；
  - `emitRMAbs(op,r,addr,cmt)`——绝对→相对的唯一换算点（公式见 §65.5.5）；if 的回跳、布尔化的 LDA 全走它；
  - `emitSkip()`——占位一行、返回行号；`backpatch(at,line)`——整行重写。**文本实现的回填就是字符串替换**——第 58 章字节流的 patchJump 是它的二进制版。
- `var(name)`——首次见名分槽（memLoc = 当前变量数）；**变量表就是符号表的最小形态**（名字→位置，无类型无作用域——TINY 单层全局）。
- `countWeights(p)` / `assignResidentRegs()`——档 2 的两步（§65.6.3）：
  - 遍历时 `w = 10^depth`——Repeat 体 depth+1（嵌套 ×100）；
  - 排序取 top-2 进 r3/r4；**权重为 0 的不驻**（nest 的 b 只被读一次、权重低——S6 的驻留表印证）。
- `tempRegFor(depth)`——档位分派表（档 1：r2/r3/r4 三层；档 2：只剩 r2）——**临时与变量抢寄存器的仲裁就这一行条件**。
- `saveTemp/loadTemp`——软件栈两端：寄存器可用则 LDA 拷贝（坑二之后的惯用法）、否则 ST/LD 走 mp 基址。
- `genLeafInto(e,r,why)`——叶直发（档 1+）：Const→LDC、Id→LD/LDA，目标寄存器由参数给（ac1 或变量寄存器）——**压弹消除的主角**。
- `genExp`——表达式后序；Op 分支的双路径（压弹 vs 叶直发）与**操作数位的两路约定**（坑三的现场，注释成对出现）。
- `emitCond`——条件的两形态分档（布尔化五条 / SUB 留差值）；`lastRelop_` 记住比较方向供补条件表用。
- `emitJumpIfFalse/True`——假跳/真跳×两档的四格表：
  - 低档：JEQ（假）/JNE（真）——对 0/1 布尔值；
  - 档 3：JGE/JNE（假跳）与 JLT/JEQ（真跳）——对差值的补条件。
- `genStmt` 五分支：
  - 赋值/读：genExp 后按描述器发 ST 或 LDA（变量进寄存器）；
  - 写：genExp + OUT；
  - if：**双占位回填**（有 else 时 toElse+overElse 两个 skip；无 else 时一个）——占位的回填文本手工拼（绝对地址已知后）——与 emitRMAbs 同公式、不同时机（发码时未知 vs 回填时已知）；
  - repeat：`top = 当前行号` 记下、体发码、条件发码、`emitJumpIfFalse(top)` 后向直发——**后向不需要占位**。
- `gen` 顶层：清表 → 档位 → 序幕两条 → 语句 → HALT → 带行号输出。

**一行一职责的检查表**：发码（五件套）、决策（档位分派）、遍历（genExp/genStmt）、布局（变量表/临时分派）、结算（回填）——五层各管各的，**改一档只动决策层**——这是本章代码能同时承载四档而不纠缠的结构保证。

### 65.5.6a　fact 语料档 0 的 31 行清单逐段讲解

整份 .tm（cgen 的原样输出，注释即发码点自述）分七段读：

**序幕（0–1 行）**：

- `0: LDC 5,511(0)`——mp 指向数据区顶；s=0 是 LDC 的"忽略位"；
- `1: ST 0,0(0)`——清 dMem[0]（启动标记）。**两条就是全部环境初始化**（§65.5.1 的对照论断）。

**读入与初始化（2–5 行）**：

- `2: IN 0,0,0` / `3: ST 0,0(6)`——read n：IN 到 ac、ST 到 gp+0（n 是第一个变量）；
- `4: LDC 0,1(0)` / `5: ST 0,1(6)`——fact := 1：常量进 ac、存 gp+1。
- 注意**每个赋值的形状**都是"值进 ac → ac 进变量槽"——ac 是唯一的数据中转站（累加器风格，§64.2.1 的 TM 版）。

**循环体·乘法（6–11 行）**：`fact := fact * n`——

- `6: LD 0,1(6)`（fact）→ `7: ST 0,0(5)`（压 mp+0）→ `8: LD 0,0(6)`（n）→ `9: LD 1,0(5)`（弹进 ac1）→ `10: MUL 0,1,0` → `11: ST 0,1(6)`；
- 压弹对的偏移对称（0 压 0 弹）——tmpOffset 的收支平衡在清单上可见。

**循环体·减法（12–17 行）**：`n := n - 1`——同构的六连（12 LD n；13 压；14 LDC 1；15 弹；16 SUB；17 ST n）。

**条件（18–26 行）**：`until n = 0`——

- `18: LD 0,0(6)`（n）→ `19: ST 0,0(5)`（压）→ `20: LDC 0,0(0)` → `21: LD 1,0(5)`（弹）→ `22: SUB 0,1,0`（差值）；
- `23: JEQ 0,2(7)`——差为 0（n=0）→ 跳 +2 到 26（LDC 1，真）；否则落下 24（LDC 0 假）→ `25: LDA 7,1(7)` 跳过真臂 → 26 不会执行；
- **五指令布尔化模板的活体**（§65.5.4 的逐行注）。

**回跳（27 行）**：`27: JEQ 0,-22(7)`——布尔值 0（假）时跳 top=6：执行时 reg[7]=28，目标 = −22+28 = 6 ✓——**后向直发、公式现场验算**。

**收尾（28–30 行）**：`LD fact` → `OUT` → `HALT`。

七段读完，31 行无一多余、无一含糊——**这份清单就是本章正文所有机制（约定/压弹/布尔化/回填）的一次性全景展示**。建议读者把它与 §65.6.2a 的四档对照表并排读：优化的每一档都改动这张清单的具体几行。

### 65.5.6b　编译流水线全景账

本章跑通了一条六站流水线——每一站对应教程的一章（或几章）：

| 站 | 本章的件 | 对应章 | 那一章多给了什么 |
|---|---|---|---|
| 扫描 | tinyscan | 5 | 自动机理论与多模式 |
| 分析 | tinyparse | 6/9/10 | LL/LR 理论、生成器、错误恢复 |
| 树 | tiny.hpp | 12 | 访问者模式与作用域 |
| 发码 | cgen | 61–63 | 分配/选择的完整算法 |
| 汇编 | tmasm | —（本章新） | 两遍结构与标号代数 |
| 执行 | tmvm | 15/57 | 解释器与栈机的对照 |

表的读法：**本章是"全而不深"的横切面，前面各章是"深而专"的纵切面**——横切面把六站连成一个可运行的整体（这是理解编译器的第一步），纵切面把每站做到工业深度（那是本教程主体的路）。Louden 书的结构（一章一部件、末章全装配）与教程的互参由此闭环。

## 65.6　四档优化：双账逐档下降（§8.10）

### 65.6.1　四档的定义与叠加

| 档 | 取材 | 机制 | 预期收益 |
|---|---|---|---|
| None | §8.8 | 朴素：全内存临时、全内存变量、布尔化 | 基线 |
| Temps | §8.10.1 | 临时入寄存器（r2–r4 三层）+ **叶右部直发 ac1**（压弹消除） | 指令数降 |
| Vars | §8.10.2 | 变量驻留寄存器（权重 top-2 进 r3/r4，临时只留 r2） | **内存指令大降**（指令数持平） |
| Test | §8.10.3 | 比较直转（布尔化五条 → SUB + 补条件跳转一条） | 指令数再降 |

叠加是累进的（档 3 含档 1+2）——与书的清单 8-14→8-15→8-16→8-17 的推进一致。

### 65.6.2　双账实测（S2 段）

四个语料的账（指令数 / 其中内存指令 LD/ST）：

| 语料 | None | Temps | Vars | Test |
|---|---|---|---|---|
| fact | 31/16 | 27/10 | **27/1** | 23/1 |
| gcd | 37/22 | 33/14 | **33/3** | 29/3 |
| branch | 40/20 | 32/10 | **32/1** | 28/1 |
| nest | 44/22 | 40/14 | **40/7** | 32/7 |

两列账讲两个故事：

- **指令数列**（31>27=27>23）：档 1 的压弹消除立竿见影（每个叶右部省 2 条）；档 2 **持平**——变量驻留是 1:1 替换（LD→LDA：都是一条）；
- **内存指令列**（16>10>**1**>1）：档 2 的真正战场——变量驻留后，循环体内的变量访问全部变成寄存器操作，**fact 从 16 条内存指令降到 1 条**（只剩序幕那条 ST 清 dMem[0]）。L 书 8.10.2 说"又比前面代码缩短许多"——书里量的是综合效果，本章把两个维度拆开量——**指令数省的是取指带宽、内存指令省的是访存延迟**，真机上后者贵一个量级（第 64 章 CISC/RISC 的代价不对称在这里兑现）。

### 65.6.3　权重与驻留（§8.10.2 的机制）

`countWeights`：遍历统计每个变量的引用次数，**循环内引用 ×10、嵌套 ×100**（循环体重复执行的加权）；`assignResidentRegs`：权重 top-2 驻 r3/r4（r0–r2 留给工作与临时）。S6 段的实测：fact 的 n/fact、gcd 的 v/u、branch 的 x/y、nest 的 d/a——**全是循环变量**，加权法自动找到了它们。

变量地址描述器的第一课（通往第 61 章）：驻留后变量的"位置"有两个可能（reg 或 mem），每次访问查描述器发对应指令——本章用 `VarInfo.reg >= 0` 一个字段实现；第 61 章把它扩成完整的分配器（干涉图、着色、溢出）。**档 2 是寄存器分配的最小完整样本**：有权重（启发式）、有描述器（数据结构）、有回退（内存）——缺的只是干涉分析（两个变量不同时活跃才能共享——练习 6 的入口）。

### 65.6.4　比较直转（§8.10.3）

档 3 撤销布尔化：条件位的 `lhs < rhs` 不再造 0/1——**SUB 之后直接发补条件跳转**：

- if 的假跳：`not (<) = >=` → `JGE ac → else`；`not (=) = !=` → `JNE`；
- repeat 的假跳（回跳）：同补条件（`<` → JGE、`=` → JNE → top）。

每处条件省四条（五条布尔化 → 一条直转）。**补条件表**（Lt→JGE/Eq→JNE）是第 55 章"跳转双公式"之后的第二张双列对照表——写错补条件，循环方向就反（坑账的常客）。

### 65.6.5　语义不变证人（S5 段）

四档的运行输出与档 0 **逐字节全等**（7/7：四语料七次运行）——优化的正确性不是"看起来对"，是**每一档都跑出同一串数**。这是本章最重要的断言：优化只许改变"怎么算"，不许改变"算出什么"——第 33 章数据流框架的"变换保持语义"在代码生成层的最小版本。

### 65.6.2a　同一语句四档的指令对照（拿 `fact := fact * n` 说话）

| 档 | 指令序列 | 条数 | 内存指令 |
|---|---|---|---|
| None | LD fact；ST 压(mp0)；LD n；LD 弹(mp0)；MUL；ST fact | 6 | 4 |
| Temps | LD fact；LDA r2,0(ac) 压；LD n；LDA ac1,0(r2) 弹；MUL；ST fact | 6 | 2 |
| Temps（叶直发版） | LD fact；LD n→ac1；MUL；ST fact | 4 | 2 |
| Vars | LDA ac,0(r4)；LD n→ac1（n 驻 r3：LDA ac1,0(r3)）；MUL；LDA r4,0(ac) | 4 | 0 |
| Test | 同 Vars（乘法语句无条件） | 4 | 0 |

五行讲清四件事：

- 档 1 的"临时入寄存器"把压弹的两条内存指令换成两条 LDA——**访存消失、条数未减**；
- **叶直发**才是条数下降的主力（6→4）：n 是叶子，根本不用压——直接发进 ac1；
- 档 2 把变量的 LD/ST 也换成 LDA——**内存指令归零**；
- 档 3 只作用于条件位——乘法语句看不见它。

双账的两个数字（§65.6.2 的表）就这样从"一句一行"的对照里长出来——**优化档位的叙事以语句为单位最清楚**。

### 65.6.2b　条件位四档对照（拿 `until n = 0` 说话）

| 档 | 指令序列 | 条数 |
|---|---|---|
| None | LD n；ST 压；LDC 0；LD 弹；SUB；JEQ+2；LDC 0；LDA 跳；LDC 1；JEQ→top | 10 |
| Temps | LD n→压弹省（LDC 直发 ac1）；SUB；JEQ+2；LDC 0；LDA；LDC 1；JEQ→top | 7 |
| Vars | LDA ac,0(r3)；LDC ac1,0；SUB；JEQ+2；LDC 0；LDA；LDC 1；JEQ→top | 8→6 |
| Test | LDA ac,0(r3)；LDC ac1,0；SUB；JNE→top（补条件直转） | 4 |

- 档 0 的十连是"通用布尔值"的全价——**五条布尔化占了半壁**；
- 档 3 的 JNE 一条替代了"布尔化五条 + 假跳一条"——**条件位是档 3 的专属战场**；
- `=` 的补条件是 JNE（差值 ≠ 0 即不相等 → 继续循环）——until 的"假则回跳"语义与补条件表在 §65.6.4 已对齐。

### 65.6.6　与第 64 章的回环（真机模式在 TM 上的重现）

把 §64 的真机观察在 TM 上对号入座——教学机是真机的蒸馏，蒸馏物在 TM 全找得到：

- **累加器风格**（Borland 的 ax）→ TM 的 ac：表达式滚过单一寄存器；
- **帧相对寻址**（`[bp-2]`）→ TM 的 `d(gp)`：基址+偏移，偏移编译期定；
- **乘尺寸的移位**（`shl bx,1`）→ TM 无移位指令！乘法只能 MUL——**TINY 无数组、乘尺寸的场景不存在**；练习 4 加数组时这条真机智慧才进场；
- **条件转移吃标志**（cmp+jle）→ TM 无标志位：布尔化把比较落成 0/1 再 JEQ——**CISC 的标志 vs TM 的显式值**，同一语义的两种机器分工；
- **调用者清栈**（cdecl）→ TM 无调用——练习 8 的 CAL/RET 将重演这课。

回环的结论：**64 章读真机是"看实例"，本章造机器是"做原理"**——实例的每个模式在原理机上有对应物或明确的缺席理由（无数组所以无移位、无函数所以无清栈）——**缺席也是设计**，教学机的白描由此完整。

### 65.6.0a　四档的设计权衡（每档一问一答）

- **档 1（临时入寄存器）**：为什么只给三层（r2/r3/r4）？——更深嵌套的表达式罕见（L 书的观察：程序里的表达式很少复杂到同时需要两三个临时）；三层的成本是零（寄存器闲着也是闲着），第四层开始回退内存——**收益递减处即截断处**。叶直发的补刀：多数二元运算的右部是叶子（变量或常量）——根本不需要临时——**最好的临时是没发生的临时**。
- **档 2（变量驻留）**：为什么按权重而不是按"先到先得"？——循环变量在运行期被引用成千次、其权重 ×10/×100 后碾压一次性变量；**静态计数近似动态热度**是编译器启发式的永恒主题（第 62 章分支预测的同门手法）。为什么只驻两个？——r3/r4 之外无房（§65.7.2a 的 FAQ）；**寄存器不够是 8 寄存器机器的宿命，也正是第 61 章干涉图存在的理由**。
- **档 3（比较直转）**：为什么撤销布尔化是安全的？——TINY 的比较只在条件位、布尔值从不流动（无布尔变量、无布尔表达式赋值）——**通用化在语言里没有消费者时，专属化零成本**。一旦语言有布尔值（练习 4 的 `<=` 或布尔变量），直转必须保守回退——优化的合法性永远以语言语义为界。
- **四档为什么累进而不是任选？**——L 书的呈现顺序就是收益顺序：档 1 立竿见影、档 2 需要档 1 的临时让位、档 3 依赖前两档后的代码形状。**优化 pass 的次序本身是设计**（第 45 章 PRE 的调度约束是同一课的深水版）。

### 65.6.7　优化后的可读性账

四档优化的隐藏成本：**代码越来越不像"手写的汇编"**——

- 档 0：每行都对应一个语法概念（人能逐行读懂）；
- 档 2：`LDA ac,0(r3)` 的语义要查驻留表才知道读的是哪个变量（S6 的表成为解码钥匙）；
- 档 3：JNE 的方向要回想补条件表才知道循环往哪边转。

L 书 8.10 末尾的清单 8-17 注释说"相对接近手写代码"——但每档都让"接近"打折。**优化与可调试性是永恒的对手**：-O0/-O2 的档位选择（第 64 章的双曝光）在 TM 上同样存在——这就是为什么 cgen 的注释从不省略、trace 永远在线——**教学机器用注释和可观察性补偿优化吃掉的可读性**。

## 65.7　驱动与对账

### 65.7.1　驱动全文

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 65 章驱动（无参运行，走"简单程序"对账协议）：
//   S1 四语料 × 档 0 跑通（值对账）→ S2 四档指令数单调账 → S3 gcd 前 12 步 trace →
//   S4 手编 .tm 的三错误码 → S5 档 3 与档 0 输出全等（语义不变证人）。
#include "cgen.hpp"
#include "tmasm.hpp"
#include "tinyparse.hpp"
#include "tinyscan.hpp"
#include "tmvm.hpp"

#include <iostream>
#include <sstream>

namespace {

struct Corpus {
    const char *name;
    const char *src;
    std::vector<std::vector<long long>> inputs;   // 每组输入一次运行
};

const std::vector<Corpus> &corpora() {
    static const std::vector<Corpus> v = {
        {"fact",
         "read n; fact := 1;\n"
         "repeat fact := fact * n; n := n - 1 until n = 0;\n"
         "write fact",
         {{5}}},
        {"gcd",
         "read u; read v;\n"
         "repeat temp := v; v := u - u / v * v; u := temp until v = 0;\n"
         "write u",
         {{36, 24}, {1071, 462}}},
        {"branch",
         "read x;\n"
         "if x < 10 then y := x * 2 else y := x - 10 + 100 end;\n"
         "write y; write x + y",
         {{7}, {25}}},
        {"nest",
         "read a; read b;\n"
         "if a < b then m := a else m := b end;\n"
         "repeat d := d + 1 until d = m;\n"
         "write d * 2",
         {{3, 9}, {9, 4}}},
    };
    return v;
}

// 编译→汇编→运行 一条龙；返回 (指令数, TmResult)。
struct RunOut {
    size_t insns = 0;
    tmach::TmResult res;
};
RunOut runTier(const Corpus &c, tiny::Cgen::Tier tier, const std::vector<long long> &input) {
    tiny::Program p = tiny::parse(tiny::scan(c.src));
    tiny::Cgen g;
    std::string tm = g.gen(p, tier);
    tmach::Assembler as;
    std::vector<tmach::TmIns> ins = as.assemble(tm);
    RunOut r;
    r.insns = ins.size();
    r.res = tmach::tmRun(ins, input);
    return r;
}

std::string outs(const std::vector<std::string> &v) {
    std::string s;
    for (const auto &x : v) s += x + " ";
    return s.empty() ? s : s.substr(0, s.size() - 1);
}

}  // namespace

int main() {
    auto tierName = [](tiny::Cgen::Tier t) {
        switch (t) {
        case tiny::Cgen::Tier::None: return "None ";
        case tiny::Cgen::Tier::Temps: return "Temps";
        case tiny::Cgen::Tier::Vars: return "Vars ";
        case tiny::Cgen::Tier::Test: return "Test ";
        }
        return "?";
    };
    std::vector<tiny::Cgen::Tier> tiers = {
        tiny::Cgen::Tier::None, tiny::Cgen::Tier::Temps, tiny::Cgen::Tier::Vars,
        tiny::Cgen::Tier::Test};

    // ---------- S1 档 0 跑通 ----------
    std::cout << "== S1 tier-None runs ==\n";
    for (const auto &c : corpora()) {
        for (const auto &in : c.inputs) {
            RunOut r = runTier(c, tiny::Cgen::Tier::None, in);
            std::cout << "[" << c.name << " in=";
            for (long long x : in) std::cout << x << ",";
            std::cout << "\b] steps=" << r.res.steps << " out=" << outs(r.res.out) << "\n";
        }
    }

    // ---------- S2 四档指令数 ----------
    std::cout << "== S2 tier instruction counts ==\n";
    bool mono = true;
    for (const auto &c : corpora()) {
        std::cout << "[" << c.name << "]";
        size_t prev = SIZE_MAX;
        for (auto t : tiers) {
            tiny::Program p = tiny::parse(tiny::scan(c.src));
            tiny::Cgen g;
            std::string tm = g.gen(p, t);
            size_t n = static_cast<size_t>(g.emitted());
            size_t mem = 0;   // 内存指令 LD/ST（不含 LDA/LDC）——档 2 的收益指标
            for (size_t pos = 0; pos + 1 < tm.size(); ++pos) {
                if ((tm.compare(pos, 4, " LD ") == 0) || (tm.compare(pos, 4, " ST ") == 0)) ++mem;
            }
            std::cout << " " << tierName(t) << "=" << n << "/mem" << mem;
            if (n > prev) mono = false;
            prev = n;
        }
        std::cout << "\n";
    }
    std::cout << "[monotone] " << (mono ? 1 : 0) << "\n";

    // ---------- S3 trace：gcd 档 0 前 12 步 ----------
    std::cout << "== S3 trace gcd(None) first 12 steps ==\n";
    {
        tiny::Program p = tiny::parse(tiny::scan(corpora()[1].src));
        tiny::Cgen g;
        std::string tm = g.gen(p, tiny::Cgen::Tier::None);
        tmach::Assembler as;
        auto ins = as.assemble(tm);
        std::ostringstream tr;
        tmach::tmRun(ins, {36, 24}, &tr);
        std::istringstream lines(tr.str());
        std::string l;
        for (int k = 0; k < 12 && std::getline(lines, l); ++k) std::cout << "    " << l << "\n";
    }

    // ---------- S4 手编 .tm 的三错误码 ----------
    std::cout << "== S4 hand .tm error codes ==\n";
    {
        tmach::Assembler as;
        struct H {
            const char *name, *src;
        };
        for (const H &h : std::vector<H>{
                 {"dmemerr", "LDC 0,5(0)\nST 0,600(0)\nHALT 0,0,0\n"},
                 {"zerodiv", "LDC 0,1(0)\nLDC 1,0(0)\nDIV 0,0,1\nHALT 0,0,0\n"},
                 {"imemerr", "LDA 7,50(7)\nHALT 0,0,0\n"},
             }) {
            auto ins = as.assemble(h.src);
            auto r = tmach::tmRun(ins, {});
            const char *err = r.err == tmach::TmResult::Err::DMemErr ? "DMEM_ERR"
                            : r.err == tmach::TmResult::Err::ZeroDiv ? "ZERO_DIV"
                            : r.err == tmach::TmResult::Err::IMemErr ? "IMEM_ERR"
                                                                      : "None";
            std::cout << "[" << h.name << "] err=" << err << " steps=" << r.steps
                      << " pc=" << r.pc << "\n";
        }
    }

    // ---------- S5 档 3 与档 0 输出全等 ----------
    std::cout << "== S5 tier-Test == tier-None outputs ==\n";
    int runs = 0, equal = 0;
    for (const auto &c : corpora()) {
        for (const auto &in : c.inputs) {
            RunOut r0 = runTier(c, tiny::Cgen::Tier::None, in);
            RunOut r3 = runTier(c, tiny::Cgen::Tier::Test, in);
            ++runs;
            bool ok = (r0.res.out == r3.res.out && !r0.res.out.empty());
            equal += ok ? 1 : 0;
            if (!ok)
                std::cout << "  MISMATCH " << c.name << " none=" << outs(r0.res.out)
                          << " test=" << outs(r3.res.out) << "\n";
        }
    }
    std::cout << "[equal] " << equal << "/" << runs << "\n";

    // ---------- S6 驻留变量报告（档 2 的侧通道） ----------
    std::cout << "== S6 resident vars (tier Vars) ==\n";
    for (const auto &c : corpora()) {
        tiny::Program p = tiny::parse(tiny::scan(c.src));
        tiny::Cgen g;
        g.gen(p, tiny::Cgen::Tier::Vars);
        std::cout << "[" << c.name << "]";
        for (const auto &vr : g.residentVars())
            std::cout << " " << vr.first << "->r" << vr.second;
        std::cout << (g.residentVars().empty() ? " (none)" : "") << "\n";
    }
    return 0;
}
```

六段对应六组断言，逐段走读：

- **S1 档 0 跑通**：四语料七次运行，值对账——fact(5)=120、gcd(36,24)=12、gcd(1071,462)=21、branch(7)=14 21、branch(25)=115 140、nest(3,9)=6、nest(9,4)=8——**每个值都手算可验**（第 22 章"九张小账"的纪律）；
- **S2 双账**：四档 × 指令数/内存指令——§65.6.2 的表就是这里的输出；
- **S3 trace**：gcd 档 0 前 12 步——序幕 2 步、两次 IN+ST（读 u/v）、循环体开始（temp := v、u 装载、压栈）——**每步七寄存器现场与手推逐行对**；
- **S4 错误码**：三条手编 .tm 各触发一码——DMEM_ERR（ST 越界，pc=2 现场正确）、ZERO_DIV（DIV 零除）、IMEM_ERR（LDA 跳飞，目标 pc=51 越界）；
- **S5 全等**：档 3 vs 档 0，7/7；
- **S6 驻留报告**：档 2 的权重胜者表——全部是循环变量。

**驱动层的数据设计**：

- `Corpus{name, src, inputs}`——inputs 是**向量 of 向量**：一个语料多组输入（branch 的两臂、nest 的两方向）；expected 的行数 = 语料 × 输入档位之和（S1 的 7 行 = 1+2+2+2）；
- `RunOut{insns, res}`——一条龙（gen→assemble→run）的打包返回；`runTier` 让 S1/S5 共用同一管线——**对账与展示共享执行路径**（两套路径 = 两套真相）；
- `outs(v)` 的空格拼接约定——第 22 章输出格式协议的沿用（expected 锚文本的稳定性）。

### 65.7.2　期望输出逐段解读

```text
; expected: expected/output.txt
== S1 tier-None runs ==
[fact in=5,] steps=113 out=120
[gcd in=36,24,] steps=62 out=12
[gcd in=1071,462,] steps=89 out=21
[branch in=7,] steps=28 out=14 21
[branch in=25,] steps=32 out=115 140
[nest in=3,9,] steps=68 out=6
[nest in=9,4,] steps=83 out=8
== S2 tier instruction counts ==
[fact] None =31/mem16 Temps=27/mem10 Vars =27/mem1 Test =23/mem1
[gcd] None =37/mem22 Temps=33/mem14 Vars =33/mem3 Test =29/mem3
[branch] None =40/mem20 Temps=32/mem10 Vars =32/mem1 Test =28/mem1
[nest] None =44/mem22 Temps=40/mem14 Vars =40/mem7 Test =32/mem7
[monotone] 1
== S3 trace gcd(None) first 12 steps ==
    1 0 LDC 5,511(0) 0 0 0 0 0 511 0
    2 1 ST 0,0(0) 0 0 0 0 0 511 0
    3 2 IN 0,0,0 36 0 0 0 0 511 0
    4 3 ST 0,0(6) 36 0 0 0 0 511 0
    5 4 IN 0,0,0 24 0 0 0 0 511 0
    6 5 ST 0,1(6) 24 0 0 0 0 511 0
    7 6 LD 0,1(6) 24 0 0 0 0 511 0
    8 7 ST 0,2(6) 24 0 0 0 0 511 0
    9 8 LD 0,0(6) 36 0 0 0 0 511 0
    10 9 ST 0,0(5) 36 0 0 0 0 511 0
    11 10 LD 0,0(6) 36 0 0 0 0 511 0
    12 11 ST 0,-1(5) 36 0 0 0 0 511 0
== S4 hand .tm error codes ==
[dmemerr] err=DMEM_ERR steps=2 pc=2
[zerodiv] err=ZERO_DIV steps=3 pc=2
[imemerr] err=IMEM_ERR steps=2 pc=51
== S5 tier-Test == tier-None outputs ==
[equal] 7/7
== S6 resident vars (tier Vars) ==
[fact] n->r3 fact->r4
[gcd] v->r3 u->r4
[branch] x->r3 y->r4
[nest] d->r3 a->r4
```

关键行（上面内嵌的是字节级真身）：

- `[fact in=5,] steps=113 out=120`：113 步 = 6（序幕+读）+ 5 圈 × ~21 步 + 收尾——**步数也是账**（每圈 21 步对得上指令清单）；
- `[gcd in=36,24,] steps=62 out=12`：gcd(36,24) 两圈出结果——欧几里得的最快情形之一；
- S2 行 `[fact] None =31/mem16 Temps=27/mem10 Vars =27/mem1 Test =23/mem1`——§65.6.2 表的数据源；
- S3 的 12 行 trace——§65.3.3 的现场表；第 12 步 `ST 0,-1(5)` 是嵌套压栈（tmpOffset 第二层）的直接证据；
- `[monotone] 1`、`[equal] 7/7`——两条总判词。

### 65.7.3　源码导览

| 文件 | 行数 | 角色 | 相对 L 书 |
|---|---|---|---|
| src/tiny.hpp | 50 | AST（StmtK/ExpK 双族构型照书） | §8.8.2 的 TreeNode |
| src/tinyscan.hpp/cpp | 40+90 | 手写扫描器 | §2.5 |
| src/tinyparse.hpp/cpp | 14+150 | 递归下降 | §4.4 |
| src/tmasm.hpp/cpp | 40+150 | 两遍汇编器 | 附录 C 的教学化重写 |
| src/tmvm.hpp/cpp | 35+95 | 模拟器 | §8.7 + 附录 C |
| src/cgen.hpp/cpp | 70+250 | 四档代码生成器 | §8.8 + §8.10 |
| src/main.cpp | 190 | 六段断言驱动 | 本章自创 |
| expected/output.txt | 38 | 全部证人 | — |

全部本章新码（无副本）——Louden 轮四新章里**代码量最大、也唯一"从扫描器到模拟器"全链自研**的一台。附录 B/C 的 C 语言列表没有照抄（PDF 也未含）——按 §8.7/§8.8 的文字规格重写，**规格与实现的对照在正文逐处标注**。

**S3 段 trace 的 12 步逐行账**（gcd 档 0、输入 36/24）：

- 第 1–2 步：序幕——mp=511（LDC）、清 dMem[0]（ST）。此后 r5 列恒 511；
- 第 3–4 步：`IN`（r0=36）+ `ST 0,0(6)`——u 落在 gp+0=dMem[0]；
- 第 5–6 步：v=24 落 dMem[1]；
- 第 7–8 步：循环体第一句 `temp := v`——LD v（r0=24）、ST 到 gp+2（temp 是第三个变量）；
- 第 9 步：`LD 0,0(6)`——u=36 装载（表达式 `u - u/v*v` 的最左 u）；
- 第 10 步：`ST 0,0(5)`——**压栈**：36 存进 dMem[511]（mp+0）；tmpOffset 0→−1；
- 第 11–12 步：`LD 0,0(6)`（第二个 u）+ `ST 0,-1(5)`——**第二层压栈**：dMem[510]（mp−1）——嵌套表达式（u/v 的 u）的栈深可视化。

12 步里 r5 列的恒定与两次 ST 的偏移（0、−1）就是**软件临时栈的全部动态**——trace 让 tmpOffset 从"代码里的静态变量"变成"看得见的栈深"。

**语料全集值账**（S1 的七个数，各配一行手算）：

- fact(5)：fact = 1×5×4×3×2×1 = 120（五圈乘法）；
- gcd(36,24)：24 → 36 mod 24 = 12 → 24 mod 12 = 0 → u=12；
- gcd(1071,462)：462 → 1071 mod 462 = 147 → 462 mod 147 = 21 → 147 mod 21 = 0 → u=21；
- branch(7)：7<10 → y=7×2=14；x+y=21；
- branch(25)：else 臂 → y=(25−10)+100=115；x+y=140；
- nest(3,9)：m=3；d 从 0 数到 3；输出 3×2=6；
- nest(9,4)：m=4；d 数到 4；输出 8。

**main 六段的设计账**：

- S1 的输入设计：fact 单输入、gcd 双输入（一大一小一对经典欧几里得对）、branch 双输入（**两臂各跑一次**——if 的两条路径都要有证人）、nest 双输入（min 的两个方向）；
- S2 的双账在 main 里现场统计（mem 计数扫 .tm 文本的 " LD "/" ST "）——**指标即协议**：读者拿 expected 就能对上；
- S4 的手编 .tm：三条错误语料**绕过 cgen 直接上汇编器**——错误码是机器的合同，验证合同不需要编译器在场；
- S5 的 7/7：四语料 × 全部输入档位逐一比对——全等是总判词。

### 65.7.2a　FAQ

- **问：为什么 TINY 没有函数？** 答：L 书的刻意裁剪——函数会把运行时环境（调用序列、帧、参数）全部带进来，那是第 7 章的正题、会淹没代码生成的讲解。TINY 是"单函数语言"，第 21/22 章的机制在本章以"约定缺失"的方式被引用（无 sp/fp → 软件 mp；无参数 → 无传递机制）。练习 8 补全。
- **问：trace 为什么不打 r7？** 答：r7 在快照时刻是"下一跳的 pc"——打印它和第二列重复；教学版省一列宽。真实模拟器（附录 C）有全套选项。
- **问：变量槽从 dMem[0] 开始，会不会和临时栈（mp=511 向下）撞上？** 答：变量最多几十个（向上长）、临时栈从 511 向下——**相向生长、中间隔着大片空地**；dmemAt 的越界检查兜底（真的撞上=程序太大，DMemErr）。
- **问：档 2 为什么只驻两个变量？** 答：r3/r4 之外只有 r2 能让（r0/r1 是工作寄存器、r5/r6/r7 有约）——8 寄存器的机器就这么多家当。练习 3 探讨"让出 r2 值不值"。
- **问：`LDC r,d(0)` 的 s=0 是"零寄存器"吗？** 答：不是！r0 是普通累加器（随时有值）。LDC 的语义是"d 直接当值、忽略 s"——**指令格式统一（都有三域）与寻址语义（d 即值）是两回事**——坑二的病根就是把"r0 当零"想当然了。

### 65.7.2b　与前后章的接口冻结

- **寄存器约定表**（§65.5.1）——本章一切代码与账目的基准；练习加指令/加档不得挪用已约定寄存器；
- **回填公式** `d = addr − (pc+1)`——与第 58 章 patchJump（偏移=目标−字段地址−2）并列为教程的"跳转双公式"，后续章引用以此为准；
- **.tm 文本格式**（行号前缀 + ; 注释 + 标号可选）——手编语料与 cgen 输出共用的接口，格式变更须两处同步；
- **TmIns 的 (op,r,d,s,t) 字段序**——坑一的纪念碑：任何消费 TmIns 的新代码先读那条注释。

### 65.7.2c　阅读自检

1. 画出 TM 的 16 条指令两格式表，标出每条的 a/值语义。
2. 默写寄存器约定表（ac/ac1/r2–r4/mp/gp/PC 各自的角色）。
3. `a*b+c*d` 在档 0 发多少条指令？压弹各几次？（数一遍 §65.5.3 的模板。）
4. if-else 的双占位各在什么时刻回填？repeat 为什么不需要占位？
5. 档 2 的双账为什么指令数持平、内存指令大降？两列指标各对应真机的什么成本？
**S1 段（8 行）逐行**：七次运行的三个看点——

- 步数列：fact 113 步（五圈循环 ≈ 每圈 21 步 + 序幕收尾 8 步）、gcd 62/89（圈数 = 欧几里得步数）、branch 28/32（**两臂步数差 4**——else 臂多一条 LDC 一条跳板：无错时这 4 条就是两臂的形状差）；
- 输出列：每个值在 §65.7.2 的值账里有一行手算——**机器的数与手算的数对齐**是本段的验收；
- `in=` 行的输入档位：双输入语料各跑一对（覆盖两臂/两方向）——语料设计学（§65.7.1 的设计账）落成 expected 的行数。

**S4 段（3 行）逐行**：三条手编 .tm 各验一码——

- `dmemerr steps=2 pc=2`：第 2 步执行 ST 越界——pc=2 是**出错指令的地址**（现场回报）；
- `zerodiv steps=3 pc=2`：DIV 在第 3 步触发——除数 r1=0、被除数 r0=1；
- `imemerr steps=2 pc=51`：LDA 把 pc 送到 51（无指令处）——**IMemErr 的现场是"想去哪没去成"**。
- 三行合起来验证错误合同的三个面：触发、现场、码别。

**S6 段（4 行）逐行**：驻留表 × 语料的三个观察——

- 每语料恰好两个变量驻留（r3/r4 满员的物理上限）；
- 驻的全是**循环变量**（n/fact、v/u、x/y、d/a）——权重加权的直接产物；
- nest 的 b/m 未驻：m 的权重（循环内引用 1 次 ×10）不敌 d（循环内 2 次 ×10 + 输出 1 次）；b 只在条件里出现一次（权重 10）——**排序结果可从语料人工复算**。

### 65.7.2c　cgen.hpp 接口逐项表

| 声明 | 角色 | 冻结要点 |
|---|---|---|
| `enum class Tier { None, Temps, Vars, Test }` | 四档 | **尾部追加**纪律（新档续在 Test 后） |
| `gen(p, tier) → string` | 主入口 | .tm 文本（含行号前缀与注释） |
| `emitted() → long long` | 指令数账 | S2 的数据源 |
| `residentVars() → vector<pair<name,reg>>` | 驻留表 | S6 的数据源（档 2 以下为空） |
| `emitRO/emitRM/emitRMAbs/emitSkip/backpatch` | 发码五件套 | RMAbs 的公式冻结（§65.5.5） |
| `VarInfo { memLoc, weight, reg }` | 变量描述器 | **reg=-1 表示 inMem**——地址描述器的最小形态（第 61 章的起点） |
| `tempRegFor(depth)` | 档位分派 | 档 2 下只回 r2——临时与变量的让位协议 |
| `lastRelop_` | 补条件记忆 | emitCond 写、emitJumpIf* 读——**两函数间的隐形约定**（练习 7 的检查点） |

**"隐形约定"的教训位**：lastRelop_ 是唯一跨函数的可变状态——它假设"Cond 之后立刻 Jump"的调用次序；若有人在两者之间插入别的发码，补条件就错——**接口表把它显式化**，练习 7 让读者给它加断言。

### 65.7.2d　FAQ（续）

- **问：为什么 .tm 要带行号前缀？汇编器不是自己会数吗？** 答：行号是给**人**的——正文引用"第 23 行 JEQ+2"时不需要手数；汇编器把它当标号消化（不占指令域）——**文本接口的一个字段服务两个读者**。
- **问：变量槽为什么不从 1 开始（避开 dMem[0] 的启动标记）？** 答：序幕第 2 条已经把 dMem[0] 清掉——标记只活在头两条指令之间；清完它就是普通单元。**启动约定的生命周期只有一个指令间隙**——设计得刚好不浪费。
- **问：repeat 和 if 谁的发码更难？** 答：if（双占位回填、可选 else、两处地址未知）；repeat 的 top 在发码时已知——**"条件在后"的文法让回填只属于 if**——文法形状决定发码复杂度的又一例。
- **问：能在这台机器上跑多快的程序？** 答：模拟器每步是 C++ 的 switch——百万步/秒量级；真 TM（若造硬件）每步一周期。**模拟器的"慢"是教学的快**——trace 想停哪停哪。
- **问：四档之后还有什么可优化？** 答：常量折叠（LDC 0,1 + SUB → 直接发差）、死代码删除（无 else 时 LDA 跳板若落点即下一行可删）、窥孔（相邻 LDA 链合并）——第 63 章的三件套在 TM 上的落点；练习 5–7 是入口。


- **问：为什么汇编器不接受 `Jxx label` 而必须写 `label(7)`？** 答：显式基址让"标号只能 pc 相对"成为可检查的约定（基址不是 7 直接报错）——**格式收紧换取语义收紧**；真实汇编器大多允许省略（默认绝对/相对由指令定）——教学版宁啰嗦勿歧义。
- **问：模拟器为什么不用异常做正常控制流（比如 HALT）？** 答：HALT 是正常停机（带 trace 打印后 return）；异常只给错误——**错误通道与正常通道分离**是模拟器可测试性的前提（check_example 按退出码区分）。
- **问：tmpOffset 为什么是 int 而不是随深度算？** 答：静态变量 + 压负弹正——递归的进出自动配对；若"随深度算"要在 genExp 里传参——**静态变量换来了发码函数的干净签名**（代价：并发/重入不可用——教学单线程无碍）。
- **问：档 3 为什么不把 if 的"无 else 跳板"也删掉？** 答：本章的 if 发码在无 else 时本来就只发一条占位跳转（落点即下一行时它是"空跳"——L 书 8.10.3 末尾提到的"删除尾部空转移"）。实测四语料的无 else 分支……branch 语料有 else、fact/gcd/nest 的 repeat 无此物——**空跳删除在本语料集里没有触发点**，实现留给练习（这也是"语料决定优化可见性"的一课）。

### 65.7.2e　坑账的防复发清单（四坑各一行）

- 坑一（字段错位）：**聚合初始化禁用于多格式结构体**——工厂函数 + 字段序注释；
- 坑二（ADD 当拷贝）：**新 ISA 上手先背惯用法表**——TM 三大惯用法（LDA 拷贝/LDA 跳/LDC 常量）写进 §65.1.2a 的表；
- 坑三（操作数位漂移）：**双路径发码的操作数位注释成对出现**——"dst=左 op 右"在两条路径旁各写一遍；
- 坑四（未爆）：**回填公式必先写三行注释**——规矩已在，惯性要保持。

### 65.7.2f　时代注记：从 TM 到 WebAssembly

TM 的设计谱系向后延伸三十年：

- ** JVM/CLR（1995/2002）**：栈机 + 类型验证——第 57 章的 P-码谱系工业化；
- **LLVM IR（2003）**：无限虚拟寄存器 + SSA——TM 的"8 寄存器约定"被"寄存器无穷多、分配后置"取代——**约定从机器层上移到 IR 层**；
- **WebAssembly（2017）**：**栈机 + 显式结构控制**（if/loop 块）——回摆到 P-码形态，但控制流块化（无任意跳转）换来流式验证——**TM 的"跳转自由"在 wasm 里被设计掉了**；
- **RISC-V（2010s）**：真机层的正交极简——TM 的"少指令、正交、显式"哲学的硬件正名。

四代演变的常数：**指令集是编译器与硬件的合同**——合同越简单、编译器越好写（TM 的教训位）；合同越丰富、性能上限越高（x86 的复杂寻址）——**教学机站在"好写"一端，工业机在两端摇摆**。



**与 L 书 TINY 编译器的工程结构对照**（书的文件划分 vs 本章）：

- 书：`globals.h/main.c/util.c/scan.c/parse.c/symtab.c/semant.c/cgen.c/tm.c` 九件套——每 pass 一文件、全局状态集中在 globals（TraceFlags 等）；
- 本章：语言件（tiny/tinyscan/tinyparse）+ 机器件（tmasm/tmvm）+ 发码件（cgen）——**机器与编译器分家**（书里 tm.c 是独立模拟器程序、其余是编译器——同样的分家）；
- 两个差异：其一，本章 AST 与扫描 token 分两个头文件（书里共用 globals）；其二，本章无 symtab/semant（TINY 语义检查只有"变量未声明"一条——L 书语义章的简化沿用）；
- **结构即教学大纲**：书的九件对应书的九章——本章的七件对应本章七节——**文件划分是章节划分的物理投影**，两代教材在此惊人一致。

**六段断言的覆盖矩阵**（哪行输出证哪条断言）：

| 断言 | 证人行 | 判据 |
|---|---|---|
| 值对账 | S1 七行 | 每值手算可复算（§65.7.2 值账） |
| 双账单调 | S2 四行 + [monotone] | 条数不增、mem 列档 2 骤降 |
| trace 手推 | S3 十二行 | 每步七寄存器与清单逐步对 |
| 错误合同 | S4 三行 | 三码各触发、pc 现场正确 |
| 语义不变 | S5 [equal] | 7/7 |
| 驻留合理 | S6 四行 | 全是循环变量（权重可复算） |

矩阵是本章的"考试答题卡"——也是收官批 survey 的数据来源（§71 章）。


## 65.8　本章开发的真坑复盘（四个，全部真实发生）

**坑一：RO 聚合初始化的字段错位（症状：fact 输出 25）**。

- 症状：`.tm` 清单逐行正确（手推可验），机器却算出 25=5×5。
- 定位：trace 第 11 步 `MUL 0,0,0`——**汇编后的 s 字段错了**；查 parseRO。
- 根因：`TmIns{op, r, s, t}` 聚合初始化——但 TmIns 的字段序是 **(op, r, d, s, t)**，d 插在中间！RO 的第二个操作数装进了 d，s 拿到第三个、t 归零——**聚合初始化按位置匹配，中间插一个字段就整体错位一位**。
- 修复：显式 `TmIns{op, f0, 0, f1, f2}`（d 置 0）+ 注释钉死字段序。
- 迁移：**结构体有"格式变体"（RO/RM 共用四字段但含义不同）时，禁止裸聚合初始化**——工厂函数或显式构造是唯一安全姿势。

**坑二：ADD 当拷贝用（症状：档 1+ 全错、fact 死循环）**。

- 症状：档 0 全对；开档 1 后 fact 步数爆炸（n 单调变负、死循环到保险丝）。
- 定位：档 1 的临时拷贝用 `ADD r,0,0`——**reg[r] = ac + ac = 2×ac**！
- 根因：想当然用了 ADD 做"复制"——但 TM **没有零寄存器**（r0 是普通工作寄存器），ADD 复制必然翻倍。
- 修复：TM 的拷贝惯用法是 **`LDA r,0(源)`**（a = 0 + reg[源]，寻址公式当拷贝用）——五处拷贝全部换掉。
- 迁移：**每个 ISA 的"惯用法"（idiom）是文档的隐形页**——x86 的 mov、RISC-V 的 mv/addi rd,rs,0、TM 的 LDA——写生成器前先背熟惯用法表，否则错的不是编译器是你的机器观。

**坑三：操作数位在两条路径间漂移（症状：branch(25) 得 85 而非 115）**。

- 症状：叶直发优化后 `y := x - 10 + 100` 算出 85——`x-10` 变成了 `10-x`。
- 定位：压弹路径 ac=右/ac1=左、叶路径 ac=左/ac1=右——**同一个 emitRO 的 (s,t) 位在两路含义相反**，共用一行发码就把减法交换了。
- 修复：两路分开发码，注释里写明两路的操作数位约定。
- 迁移：**"代码复用"在操作数有方向性时是陷阱**——表面同构（都是 dst,s,t）语义反转（左 op 右 vs 右 op 左），复用前先核对每个位置的含义。

**坑四：回填公式的 +1（本章没有踩、因为规矩在）**。

- 本章所有回填（if 双臂、repeat、布尔化 LDA）一次写对——不是运气：**每处都先写"模拟器三行注释"再代数**（取指自增 → reg[7]=pc+1 → d=addr-(pc+1)）。
- 对照第 55 章的教训（两差一坑）：那次心算错了偏移、这次规矩挡住了——**方法论的价值要用"没踩的坑"来计量**。

四坑三真一虚：真坑全在**机器层**（字段序、惯用法、操作数位）——语义章的坑在模型接缝、机器章的坑在表示约定——**每章的坑型跟着章节的主题走**，这本身是教程结构正确性的一个旁证。

## 65.9　小结与练习

本章造了 Louden 轮的最大一台机器：TM（16 指令、无栈无帧）+ 两遍汇编器 + 模拟器 + TINY 手写前端 + 四档代码生成器。全部断言有证人：七次运行值对账、双账单调（31/16 → 23/1）、trace 手推逐行、三错误码、四档输出 7/7 全等。核心心法：**约定即接口、回填先写三行注释、优化不许改变输出、每台机器都有自己的惯用法**。

**术语速查**：

- **TM**：Louden 的教学目标机——分离 I/D、8 寄存器、r7=PC、无 sp/fp。
- **RO/RM**：TM 的两种指令格式（寄存器三地址 / 寄存器-存储器 a=d+reg[s]）。
- **ac/ac1/mp/gp**：累加器、副累加器、内存顶指针、变量基址的寄存器约定。
- **tmpOffset**：软件临时栈的偏移（压负弹正）——无硬件栈的全部代价与智慧。
- **布尔化**：比较物化为 0/1 的五指令模板。
- **回填**：前向跳转占位后结算——d = addr − (pc+1)。
- **补条件**：直转优化里 `<`→JGE、`=`→JNE 的反向条件表。
- **权重驻留**：引用计数 ×10^循环深度、top-k 变量进寄存器——地址描述器第一课。
- **惯用法**：ISA 的地道表达（TM 的 LDA 拷贝、x86 的 mov）。
- **双账**：指令数（取指带宽）与内存指令数（访存延迟）分开计量。

**与 L 书的取材对照**：§1.7 → §65.4；§2.5/§4.4 → 前端两件；§8.7 → §65.1–65.3；§8.8 → §65.5；§8.10.1/2/3 → §65.6 的三档；附录 B/C 按规格重写（§65.7.3 的说明）。§8.9 的优化总论已在教程第五–七篇展开，本章只取 8.10 的三个具体优化。

**练习 1–4 解答要点**：

1. PSH/POP 省的是压弹对的"地址算术"（ST/LD 的 d+reg[s] 编码进指令的专用操作数）——条数从 2 到 1；但 TM 的"最小完备"评价要扣分：16→18 条指令、模拟器多两 case、汇编器多两助记符——**教学机的美德是最小，工业机的美德是快——两套评分表**。
2. 手编参考（7 条）：`IN 0,0,0` / `ST 0,0(6)` / `LD 0,0(6)` / `LDC 1,2(0)` / `MUL 0,1,0` / `OUT 0,0,0` / `HALT`——对照 cgen：它发 LDC 2 到 ac 再 ADD？不——乘 2 无叶直发时是 `LDC 0,2(0)`+压弹+MUL；手编直接用 r1 装常量——**人知道全局、编译器只知道模板**。
3. nest 四变量（a/b/d/m）驻三个：权重排序 d/m/a（b 只读一次）——指令数持平、内存指令 7→更少；但 r2 让出后嵌套表达式（`d * 2` 的右部是叶、不受影响；`x - 10 + 100` 形态的三层表达式会回退内存）——**账要按语料的表达式形状算**。
4. `<=` 的布尔化：SUB 后 JLE+2（真臂）；补条件假跳 = JGT——六条 Jxx 指令在 TM 里的"全配置"由此凑齐（Lt/Eq/Le 三比较 × 真/假两跳）。

### 65.9.1　小结的三句话

- **一台机器**：TM 用 16 条指令、8 个寄存器、两条启动约定撑起了 TINY 的全部运行时——没有栈的栈（软件临时栈）、没有帧的帧（gp+槽位）、没有布尔的布尔（五指令模板）——**"没有"本身就是教材**。
- **一条流水线**：扫描→分析→树→发码→汇编→执行六站全自研，每站对应教程前面的纵切章——横切面把编译器连成"一台可运行的机器"，纵切面把它拆成"一门门可深挖的课"。
- **一组账**：四语料七运行值全等（120/12/21/14 21/115 140/6/8）、双账单调（31/16→23/1）、trace 逐行、三错误码、7/7 语义不变——**每个论点有数字、每个数字有手推**——Louden 轮"教材论述变机器报告"的收官样本。

### 65.9.2　教学建议

- **第一课（跑通）**：只放 S1——学生先手算七个值、再对机器输出——"值对账"的信任由此建立；
- **第二课（看穿）**：S3 的 12 行 trace + §65.5.6a 的 31 行清单并排——逐行指认"这行是哪条机制的产物"；
- **第三课（省钱）**：S2 双账 + §65.6.2a 的语句级对照——让学生预言"档 2 的内存指令为什么归零"再放表；
- **第四课（犯错）**：把坑一的 TmIns 字段序故意改坏、让学生用 trace 定位——**坑账当教具**，比讲十遍字段序有效。

四课的共同动作：预言→运行→推演——第 22 章课堂语法的 TM 版。

### 65.9.3　L 书取材的未取清单（诚实账）

本章未取材的 §8.7–8.10 内容及原因：

- **§8.7 的 C 代码片段**（iMem/dMem 的 C 声明示意）——本章用 C++ 重写，语义同、风格异；
- **附录 B/C 的完整 C 列表**——PDF 未含（卷九仅附录 A）；按文字规格重写，导览表已注明；
- **§8.9 优化总论**（分类与数据结构）——教程第五–七篇的纵深早已覆盖，本章只取 8.10 的三个具体优化；
- **§8.10 的清单 8-14…8-17 原文对照**——本章用自有语料重做同型实验（双账表），数字不同、方法相同——**取材取机制，数据用自产**——这是全书"自包含"原则在本章的执行。

### 65.9.4　术语补遗

- **指令格式**：RO/RM 的三域布局——TM 只有两种，真机可达十几种（x86）。
- **地址前缀**：.tm 行首的 `N:`——人读的行号、汇编器的标号。
- **启动约定**：boot 时机器状态的契约（清零、dMem[0]、PC=0）。
- **收益递减**：优化档位的截断判据（三层临时、两个驻留）。
- **补条件表**：`<`↔JGE、`=`↔JNE 的反向映射。
- **双账**：条数账（带宽）与内存账（延迟）——§65.6.2。
- **横切面/纵切面**：全流水线的一遍 vs 单阶段的深挖。
- **惯用法**：ISA 的地道表达（§65.1.2a 的表）。

### 65.9.5　自检补遗

1. fact 的 113 步怎么拆？（序幕 2 + 读 2 + 初始化 2 + 五圈 × 21 + 条件末次 9 + 收尾 3——对不上就查。）
2. 档 2 的驻留表如果驻错了变量（比如驻了 b 不驻 d），哪个语料的哪个数字会变？
3. .tm 的标号与 cgen 的行号前缀在汇编器里走同一条路——为什么这是设计而不是偷懒？
4. 四档里哪一档改变了 trace 的**形状**（而不只是条数）？（档 3——布尔化五连消失。）
5. 如果 DADDR 从 512 改 1024，本章哪些数字会变、哪些不变？（变：mp 初值、dmemerr 语料的临界；不变：全部指令数与输出——**机器容量与程序逻辑正交**。）



**练习 5–8 解答要点**：

5. 内存窗口：trace 里加"本步触及的 dMem 单元"列（LD/ST 的 a 与旧新值）——压弹的可视化就是这一列在 mp 区间的跳动；与 reg 列并排即"寄存器-存储器双城记"。
6. 活跃区间：首次到末次引用的语句序号区间；不交的变量可共房——nest 的 a（读两次、区间长）与 m（区间短）或可共享 r4；对照第 61 章干涉图的"区间图着色"预演。
7. 占位行固定性：本章 code_ 只在尾部追加（emitSkip 占的行不会被后续移动——没有插入式发码）；backpatch 只改那一行的文本。若未来加"指令重排"pass，回填时机必须整体后移——**回填与重排是不相容的两种发码风格**，工业编译器用"最后统一结算"解此题。
8. CAL/RET 设计：`CAL` = `LDA r7, 返回地址(7)` 的宏（链接器/汇编器展开）+ 帧切换（新 gp = mp、mp 下移帧大小）；RET 恢复。参数区放新帧顶部——第 22 章的 val 直接拷贝最简。全部走 mp 的"帧即栈段"实现——第 21 章的图逐格兑现。

### 65.1.0a　设计者的三个取舍（TM 为什么长这样）

- **为什么只有 8 个寄存器？** 够用即止：ac/ac1（工作）+ 3（临时/驻留）+ mp/gp/PC（约定）= 8——**寄存器数 = 约定数 + 余量**；多出来的寄存器会诱使教学代码做超出主线的事（比如激进分配）——Louden 把"寄存器稀缺"当特性保留（档 2 只驻两个变量的约束感就是教学点）。
- **为什么指令/数据存储分离？** 其一，iMem 只读——**程序不可自改**（von Neumann 与 Harvard 的分野在教学机的投影）；其二，地址空间各自从 0 起——变量槽的编号（gp+0/1/2…）不被代码体积挤占——**编号的稳定换来正文账目的干净**。
- **为什么没有标志位/没有栈指令/没有调用指令？** 每删一样，编译器就多写一段显式代码——**删减清单 = 教学大纲**：布尔化教"标志的显式化"、软件栈教"栈的本质是约定"、无调用教"帧是编译器的构造物"。TM 的最小性不是省事，是**把运行时的每一课从硬件还给编译器**。

### 65.3.5　错误语料为什么手编（而不是从 TINY 编出来）

S4 的三条 .tm 不经 cgen——三个理由：

- **合同隔离**：错误码是机器的合同——验证合同要排除编译器这个中间人（万一 cgen 永远发不出越界地址，合同就测不到）；
- **精确触达**：手编可以一步到位（`ST 0,600(0)` 直奔越界），TINY 语义程序很难造出恰好的越界（TINY 无指针、无数组——发码器发的地址永远合法）；
- **语料极小化**：三条各 3–4 行——**用最小的输入测最深的边界**，这是错误路径测试的通用姿势（第 10 章错误恢复语料的同门法）。

### 65.9.6　本章知识点清单（收官批 survey 的素材）

- 机器层：16 指令两格式、寻址公式 a=d+reg[s]、三错误码、boot 约定、三大惯用法；
- 汇编层：两遍结构、标号代数、文本接口；
- 发码层：寄存器约定、软件临时栈、布尔化模板、回填双公式、叶直发、权重驻留、补条件直转；
- 验证层：值对账、双账、trace 对账、错误合同、语义不变断言、语料覆盖表。

四层 20 个知识点——71 章收官 survey 的"TM 行"将逐条点名（本章为收官批备料）。

### 65.9.7　教学后记

这一章是整个 Louden 轮写作时间最长的一章——不是因为内容最难（机制都是前面各章的老朋友），而是因为**全链路的每一环都要真的转起来**：一处字段序错位、一处拷贝翻倍、一处操作数交换，都会让"7/7 全等"变"3/7"——**完整性的代价是每处约定都不能靠**。四坑三爆一防（坑四靠规矩未爆）的账目说明：方法论（先注释后代数）不是仪式，是省时间的——它把两处必错的地方变成了零处。

**读者做完本章练习后的自画像**：能在纸上为一门小语言设计目标机（指令集、约定、错误码），能为它写汇编器与模拟器，能写四档代码生成器并用双账证明每档的收益与安全——这就是"写过编译器"的最小完整含义。

### 65.9.8　FAQ 终章三问

- **问：TM 与教学的关系——学生该记 TM 的什么？** 答：不记指令表（查表即可）——记**三个"没有"怎么补**（无栈→软件栈、无帧→gp 约定、无布尔→模板化）与**两条公式**（寻址 a=d+reg[s]、回填 d=addr−(pc+1)）——机制会过时、公式与取舍长存。
- **问：如果只保留一章的代码给读者改着玩，选哪章？** 答：就是本章——六站流水线每站都能独立动（改文法、加指令、换约定），且每动一下都有 expected 兜底（改坏立知）——**可改性是教学代码的最高评分**。
- **问：下一台机器在哪？** 答：教程的机器线到此收官（栈机/寄存器机/真机三角闭合）；剩下的机器（ILP 调度器、放置器）不再"执行"程序——它们变换程序——从本章起，机器让位于**变换**（第 66 章起）。


**练习**：

1. 给 TM 加两条指令 `PSH r` / `POP r`（用 mp 做栈指针）——tmpOffset 的软件栈能省多少条指令？（要点：压弹从 2 条 ST/LD 变 1 条；但**机器变复杂了**——教学机的最小性是特性，加指令要算总账。）
2. 手编 .tm：不用 cgen，直接写 `read n; write n*2` 的 TM 汇编（7 条左右）——体会"人肉代码生成器"后，再对照 cgen 的输出。
3. 档 2 目前只驻留 2 个变量（r3/r4）——把 r2 也让出来（临时全进内存），可以驻 3 个。对 nest 语料（4 变量）值得吗？用双账回答。
4. 比较运算 `<=`：TINY 文法没有，加上它——布尔化模板与补条件表各加一行；`JLE`/`JGT` 指令已在 TM 里等着。
5. （进阶）把 trace 扩展成"内存窗口"（打印 dMem 的活跃区间）——软件临时栈的压弹在窗口里怎么可视化？
6. （进阶）干涉分析的预习：给 countWeights 加"活跃区间"估算（首次引用到末次引用），两个区间不交的变量共享一个寄存器——对 nest 语料能省出什么？
7. （进阶）emitRMAbs 的公式在**回填**场景要小心：占位行的 pc 在发码时未知（后续代码会移动它吗？）——本章的实现里占位行固定、回填只改文本，为什么安全？
8. （大题）给 TM 加 `CAL/RET`（call 压返回地址、ret 弹跳）与 sp 约定，TINY 加函数——第 21 章的调用序列在 TM 上的完整重演；帧布局图（§21.2）逐格变成指令。

## 65.10　本章配套文件

```cpp
// file: src/tiny.hpp
// file: src/tiny.hpp
// TINY 语言的 AST（L 书 §1.7.2 的文法、§8.8.2 的树构型——StmtK/ExpK 双族）。
#ifndef TIP_TINY_HPP
#define TIP_TINY_HPP

#include <memory>
#include <string>
#include <vector>

namespace tiny {

enum class Tok {
    If, Then, Else, End, Repeat, Until, Read, Write,   // 关键字 8 个
    Assign,        // :=
    Eq,            // =
    Lt,            // <
    Add, Sub, Mul, Div,
    LParen, RParen, Semi,
    Num, Id,
    EndOfFile,
};

// ---------- 表达式（ExpK） ----------
struct Exp {
    enum class Kind { Op, Const, Id } kind;
    Tok op = Tok::Add;        // Kind::Op 时有效（Add/Sub/Mul/Div/Lt/Eq）
    long long val = 0;        // Kind::Const
    std::string name;         // Kind::Id
    std::unique_ptr<Exp> lhs, rhs;   // Kind::Op 的两个孩子
};

// ---------- 语句（StmtK） ----------
struct Stmt {
    enum class Kind { If, Repeat, Assign, Read, Write } kind;
    // If: cond + thenSeq + elseSeq；Repeat: body + cond（直到型）；
    // Assign: name + exp；Read: name；Write: exp。
    std::unique_ptr<Exp> cond, exp;
    std::string name;
    std::vector<std::unique_ptr<Stmt>> thenSeq, elseSeq, body;
    int line = 0;
};

struct Program {
    std::vector<std::unique_ptr<Stmt>> stmts;
};

// 语法错误（带行号——第 10 章黄金句式）。
struct ParseError {
    std::string msg;
    int line;
};

}  // namespace tiny

#endif  // TIP_TINY_HPP
```

```cpp
// file: src/tinyscan.hpp
// file: src/tinyscan.hpp
// TINY 扫描器（L 书 §2.5 的手写路线：保留字表 + 标识符/数字 + 最长 ':='）。
#ifndef TIP_TINYSCAN_HPP
#define TIP_TINYSCAN_HPP

#include <string>
#include <vector>

#include "tiny.hpp"

namespace tiny {

struct ScanTok {
    Tok kind;
    std::string text;   // Num 的原文 / Id 的名字
    long long num = 0;  // Num
    int line = 1;
};

// 注释 { ... } 嵌套不计（书里单层）；无法成词抛 ParseError。
std::vector<ScanTok> scan(const std::string &src);

const char *tokName(Tok t);

}  // namespace tiny

#endif  // TIP_TINYSCAN_HPP
```

```cpp
// file: src/tinyscan.cpp
// file: src/tinyscan.cpp
#include "tinyscan.hpp"

#include <cctype>
#include <map>
#include <stdexcept>

namespace tiny {

namespace {

const std::map<std::string, Tok> &keywords() {
    static const std::map<std::string, Tok> kw = {
        {"if", Tok::If},       {"then", Tok::Then}, {"else", Tok::Else},
        {"end", Tok::End},     {"repeat", Tok::Repeat}, {"until", Tok::Until},
        {"read", Tok::Read},   {"write", Tok::Write},
    };
    return kw;
}

bool identStart(char c) { return std::isalpha(static_cast<unsigned char>(c)); }
bool identChar(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

}  // namespace

const char *tokName(Tok t) {
    switch (t) {
    case Tok::If: return "if";       case Tok::Then: return "then";
    case Tok::Else: return "else";   case Tok::End: return "end";
    case Tok::Repeat: return "repeat"; case Tok::Until: return "until";
    case Tok::Read: return "read";   case Tok::Write: return "write";
    case Tok::Assign: return ":=";   case Tok::Eq: return "=";
    case Tok::Lt: return "<";        case Tok::Add: return "+";
    case Tok::Sub: return "-";       case Tok::Mul: return "*";
    case Tok::Div: return "/";       case Tok::LParen: return "(";
    case Tok::RParen: return ")";    case Tok::Semi: return ";";
    case Tok::Num: return "NUM";     case Tok::Id: return "ID";
    case Tok::EndOfFile: return "EOF";
    }
    return "?";
}

std::vector<ScanTok> scan(const std::string &src) {
    std::vector<ScanTok> out;
    size_t i = 0;
    int line = 1;
    auto fail = [&](const std::string &why) {
        throw ParseError{"词法: " + why, line};
    };
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (c == '{') {   // 注释到配对 }
            ++i;
            while (i < src.size() && src[i] != '}') {
                if (src[i] == '\n') ++line;
                ++i;
            }
            if (i >= src.size()) fail("注释未闭合");
            ++i;
            continue;
        }
        if (identStart(c)) {
            size_t j = i;
            while (j < src.size() && identChar(src[j])) ++j;
            std::string w = src.substr(i, j - i);
            auto it = keywords().find(w);
            ScanTok t;
            t.line = line;
            t.text = w;
            t.kind = it != keywords().end() ? it->second : Tok::Id;
            out.push_back(t);
            i = j;
            continue;
        }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            size_t j = i;
            while (j < src.size() && std::isdigit(static_cast<unsigned char>(src[j]))) ++j;
            ScanTok t;
            t.kind = Tok::Num;
            t.text = src.substr(i, j - i);
            t.num = std::stoll(t.text);
            t.line = line;
            out.push_back(t);
            i = j;
            continue;
        }
        if (c == ':' && i + 1 < src.size() && src[i + 1] == '=') {
            out.push_back({Tok::Assign, ":=", 0, line});
            i += 2;
            continue;
        }
        Tok one;
        switch (c) {
        case '=': one = Tok::Eq; break;
        case '<': one = Tok::Lt; break;
        case '+': one = Tok::Add; break;
        case '-': one = Tok::Sub; break;
        case '*': one = Tok::Mul; break;
        case '/': one = Tok::Div; break;
        case '(': one = Tok::LParen; break;
        case ')': one = Tok::RParen; break;
        case ';': one = Tok::Semi; break;
        default: fail(std::string("无法成词的字符 '") + c + "'");
        }
        out.push_back({one, std::string(1, c), 0, line});
        ++i;
    }
    out.push_back({Tok::EndOfFile, "", 0, line});
    return out;
}

}  // namespace tiny
```

```cpp
// file: src/tinyparse.hpp
// file: src/tinyparse.hpp
// TINY 递归下降分析器（L 书 §4.4 的原路线——每语句一个过程）。
#ifndef TIP_TINYPARSE_HPP
#define TIP_TINYPARSE_HPP

#include "tinyscan.hpp"   // ScanTok
#include "tiny.hpp"

namespace tiny {

// 解析整程序；失败抛 ParseError（带行号）。
Program parse(const std::vector<ScanTok> &toks);

}  // namespace tiny

#endif  // TIP_TINYPARSE_HPP
```

```cpp
// file: src/tinyparse.cpp
// file: src/tinyparse.cpp
#include "tinyparse.hpp"

#include "tinyscan.hpp"

#include <stdexcept>

namespace tiny {

namespace {

class Parser {
public:
    explicit Parser(const std::vector<ScanTok> &toks) : t_(toks) {}

    Program parseProgram() {
        Program p;
        p.stmts = stmtSeq();
        want(Tok::EndOfFile);
        return p;
    }

private:
    const std::vector<ScanTok> &t_;
    size_t i_ = 0;

    const ScanTok &cur() const { return t_[i_]; }
    bool eat(Tok k) {
        if (cur().kind == k) { ++i_; return true; }
        return false;
    }
    void want(Tok k) {
        if (!eat(k))
            throw ParseError{"语法: 期待 '" + std::string(tokName(k)) + "'，遇到 '" +
                                 tokName(cur().kind) + "'",
                             cur().line};
    }
    [[noreturn]] void fail(const std::string &why) {
        throw ParseError{"语法: " + why + "（遇到 '" + tokName(cur().kind) + "'）", cur().line};
    }

    // stmt-seq → stmt { ';' stmt }——语句以分号分隔（最后一条不带）。
    std::vector<std::unique_ptr<Stmt>> stmtSeq() {
        std::vector<std::unique_ptr<Stmt>> out;
        out.push_back(stmt());
        while (eat(Tok::Semi)) out.push_back(stmt());
        return out;
    }

    std::unique_ptr<Stmt> stmt() {
        int line = cur().line;
        switch (cur().kind) {
        case Tok::If: return ifStmt(line);
        case Tok::Repeat: return repeatStmt(line);
        case Tok::Read: return readStmt(line);
        case Tok::Write: return writeStmt(line);
        case Tok::Id: return assignStmt(line);
        default: fail("语句起点非法");
        }
    }

    std::unique_ptr<Stmt> ifStmt(int line) {
        want(Tok::If);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::If;
        s->line = line;
        s->cond = cond();
        want(Tok::Then);
        s->thenSeq = stmtSeq();
        if (eat(Tok::Else)) s->elseSeq = stmtSeq();
        want(Tok::End);
        return s;
    }

    std::unique_ptr<Stmt> repeatStmt(int line) {
        want(Tok::Repeat);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Repeat;
        s->line = line;
        s->body = stmtSeq();
        want(Tok::Until);
        s->cond = cond();
        return s;
    }

    std::unique_ptr<Stmt> assignStmt(int line) {
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Assign;
        s->line = line;
        s->name = cur().text;
        want(Tok::Id);
        want(Tok::Assign);
        s->exp = exp();
        return s;
    }

    std::unique_ptr<Stmt> readStmt(int line) {
        want(Tok::Read);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Read;
        s->line = line;
        s->name = cur().text;
        want(Tok::Id);
        return s;
    }

    std::unique_ptr<Stmt> writeStmt(int line) {
        want(Tok::Write);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Write;
        s->line = line;
        s->exp = exp();
        return s;
    }

    // 条件专用：exp relop exp（L 书口径：比较只出现在 if/repeat 的条件位）
    std::unique_ptr<Exp> cond() {
        auto lhs = exp();
        if (cur().kind != Tok::Lt && cur().kind != Tok::Eq)
            fail("条件期待比较运算符");
        auto e = std::make_unique<Exp>();
        e->kind = Exp::Kind::Op;
        e->op = cur().kind;
        ++i_;
        e->lhs = std::move(lhs);
        e->rhs = exp();
        return e;
    }

    std::unique_ptr<Exp> exp() {
        auto a = term();
        while (cur().kind == Tok::Add || cur().kind == Tok::Sub) {
            Tok op = cur().kind;
            ++i_;
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Op;
            e->op = op;
            e->lhs = std::move(a);
            e->rhs = term();
            a = std::move(e);
        }
        return a;
    }

    std::unique_ptr<Exp> term() {
        auto a = factor();
        while (cur().kind == Tok::Mul || cur().kind == Tok::Div) {
            Tok op = cur().kind;
            ++i_;
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Op;
            e->op = op;
            e->lhs = std::move(a);
            e->rhs = factor();
            a = std::move(e);
        }
        return a;
    }

    std::unique_ptr<Exp> factor() {
        if (eat(Tok::LParen)) {
            auto e = exp();
            want(Tok::RParen);
            return e;
        }
        if (cur().kind == Tok::Num) {
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Const;
            e->val = cur().num;
            ++i_;
            return e;
        }
        if (cur().kind == Tok::Id) {
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Id;
            e->name = cur().text;
            ++i_;
            return e;
        }
        fail("表达式起点非法");
    }
};

}  // namespace

Program parse(const std::vector<ScanTok> &toks) {
    Parser p(toks);
    return p.parseProgram();
}

}  // namespace tiny
```

```cpp
// file: src/tmasm.hpp
// file: src/tmasm.hpp
// TM 两遍汇编器（L 书 §8.7/附录 C 的 .tm 文本格式）。
#ifndef TIP_TMASM_HPP
#define TIP_TMASM_HPP

#include <string>
#include <vector>

namespace tmach {

// 一条 TM 指令：RO 用 (r,s,t)；RM 用 (r,d,s)。
struct TmIns {
    enum class Op {
        HALT, IN, OUT, ADD, SUB, MUL, DIV,           // RO：op r,s,t
        LD, LDA, LDC, ST, JLT, JLE, JGE, JGT, JEQ, JNE,   // RM：op r,d(s)
    };
    Op op = Op::HALT;
    int r = 0, d = 0, s = 0, t = 0;   // RO 用 (r,s,t)；RM 用 (r,d(s))

    static const char *name(Op o);
    static bool isRO(Op o) { return o <= Op::DIV; }
};

// .tm 文本格式（一章内自定义的干净版）：
//   ; 整行注释
//   label: OP r,d(s)        ; 行尾注释
//   OP r,s,t
// 第一遍收集标号地址；第二遍编码（标号只能出现在跳转的 d 位——`Jxx r,label(7)`）。
// 语法错抛 std::runtime_error（消息带行号）。
class Assembler {
public:
    std::vector<TmIns> assemble(const std::string &tmText);
};

// 反汇编一行（trace/正文展示用）。
std::string disasm(const TmIns &i);

}  // namespace tmach

#endif  // TIP_TMASM_HPP
```

```cpp
// file: src/tmasm.cpp
// file: src/tmasm.cpp
#include "tmasm.hpp"

#include <cctype>
#include <map>
#include <sstream>
#include <stdexcept>

namespace tmach {

const char *TmIns::name(Op o) {
    switch (o) {
    case Op::HALT: return "HALT";
    case Op::IN: return "IN";
    case Op::OUT: return "OUT";
    case Op::ADD: return "ADD";
    case Op::SUB: return "SUB";
    case Op::MUL: return "MUL";
    case Op::DIV: return "DIV";
    case Op::LD: return "LD";
    case Op::LDA: return "LDA";
    case Op::LDC: return "LDC";
    case Op::ST: return "ST";
    case Op::JLT: return "JLT";
    case Op::JLE: return "JLE";
    case Op::JGE: return "JGE";
    case Op::JGT: return "JGT";
    case Op::JEQ: return "JEQ";
    case Op::JNE: return "JNE";
    }
    return "?";
}

namespace {

const std::map<std::string, TmIns::Op> &opTable() {
    static const std::map<std::string, TmIns::Op> t = {
        {"HALT", TmIns::Op::HALT}, {"IN", TmIns::Op::IN}, {"OUT", TmIns::Op::OUT},
        {"ADD", TmIns::Op::ADD},   {"SUB", TmIns::Op::SUB}, {"MUL", TmIns::Op::MUL},
        {"DIV", TmIns::Op::DIV},   {"LD", TmIns::Op::LD},   {"LDA", TmIns::Op::LDA},
        {"LDC", TmIns::Op::LDC},   {"ST", TmIns::Op::ST},   {"JLT", TmIns::Op::JLT},
        {"JLE", TmIns::Op::JLE},   {"JGE", TmIns::Op::JGE}, {"JGT", TmIns::Op::JGT},
        {"JEQ", TmIns::Op::JEQ},   {"JNE", TmIns::Op::JNE},
    };
    return t;
}

// 把一行拆成（标号?、操作数们）——剥注释、去标号、按空白切。
struct Line {
    int lineno;
    std::string label;              // 可空
    std::vector<std::string> words; // [OP, 操作数...]
};

Line split(const std::string &raw, int lineno) {
    std::string s = raw;
    auto sc = s.find(';');
    if (sc != std::string::npos) s = s.substr(0, sc);
    Line out;
    out.lineno = lineno;
    // 标号：冒号在第一个空白之前
    auto colon = s.find(':');
    if (colon != std::string::npos) {
        bool ok = true;
        for (size_t k = 0; k < colon; ++k)
            if (std::isspace(static_cast<unsigned char>(s[k]))) { ok = false; break; }
        if (ok) {
            out.label = s.substr(0, colon);
            s = s.substr(colon + 1);
        }
    }
    std::istringstream is(s);
    std::string w;
    while (is >> w) out.words.push_back(w);
    return out;
}

int toInt(const std::string &w, int lineno) {
    try {
        return std::stoi(w);
    } catch (const std::exception &) {
        throw std::runtime_error("汇编第 " + std::to_string(lineno) + " 行：非法数字 '" + w + "'");
    }
}

// 把 "r,s,t" / "r,d(s)" 按逗号切成字段（最后一个字段可能是 d(s) 形态）。
std::vector<std::string> splitCommas(const std::string &operand, int ln) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : operand) {
        if (c == ',') { out.push_back(cur); cur.clear(); }
        else cur += c;
    }
    out.push_back(cur);
    if (out.size() != 2 && out.size() != 3)
        throw std::runtime_error("汇编第 " + std::to_string(ln) +
                                 " 行：操作数要 'r,s,t' 或 'r,d(s)'，得 '" + operand + "'");
    return out;
}

}  // namespace

std::string disasm(const TmIns &i) {
    std::ostringstream os;
    os << TmIns::name(i.op);
    if (i.isRO(i.op)) os << " " << i.r << "," << i.s << "," << i.t;
    else os << " " << i.r << "," << i.d << "(" << i.s << ")";
    return os.str();
}

std::vector<TmIns> Assembler::assemble(const std::string &tmText) {
    // ---------- 第一遍：剥注释/标号，记标号地址 ----------
    std::vector<Line> lines;
    std::map<std::string, int> labels;
    {
        std::istringstream is(tmText);
        std::string raw;
        int ln = 0;
        while (std::getline(is, raw)) {
            ++ln;
            Line l = split(raw, ln);
            if (l.words.empty()) {
                if (!l.label.empty())
                    labels[l.label] = static_cast<int>(lines.size());   // 空行标号指向下一条
                continue;
            }
            if (!l.label.empty()) labels[l.label] = static_cast<int>(lines.size());
            lines.push_back(std::move(l));
        }
    }
    // ---------- 第二遍：编码（d 位的标号 → 相对 7 的偏移） ----------
    std::vector<TmIns> out;
    out.reserve(lines.size());
    for (const auto &l : lines) {
        auto it = opTable().find(l.words[0]);
        if (it == opTable().end())
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：未知指令 '" + l.words[0] + "'");
        TmIns::Op op = it->second;
        if (l.words.size() != 2)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：指令要 'OP r,s,t' 或 'OP r,d(s)' 形式");
        auto f = splitCommas(l.words[1], l.lineno);
        if (TmIns::isRO(op)) {
            if (f.size() != 3)
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：RO 指令要 r,s,t");
            // TmIns 字段序是 (op, r, d, s, t)——RO 无 d，置 0 别错位
            out.push_back(TmIns{op, toInt(f[0], l.lineno), 0, toInt(f[1], l.lineno),
                                toInt(f[2], l.lineno)});
            continue;
        }
        // RM：r,d(s)——d 可以是标号（跳转目标，按 (7) 基址换算）
        if (f.size() != 2)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：RM 指令要 r,d(s)");
        TmIns ins;
        ins.op = op;
        ins.r = toInt(f[0], l.lineno);
        std::string ds = f[1];   // 形如 -4(6) 或 label(7) 或 3(0)
        auto lp = ds.find('(');
        if (lp == std::string::npos || ds.back() != ')')
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：RM 第二操作数要 d(s) 形式，得 '" + ds + "'");
        std::string dpart = ds.substr(0, lp), spart = ds.substr(lp + 1, ds.size() - lp - 2);
        if (std::isdigit(static_cast<unsigned char>(dpart[0])) || dpart[0] == '-') {
            ins.d = toInt(dpart, l.lineno);
        } else {
            // 标号目标：绝对地址 addr → d = addr - (当前位置 + 1)（基址 7）
            if (spart != "7")
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：标号目标只能以 (7) 为基址");
            auto li = labels.find(dpart);
            if (li == labels.end())
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：未定义标号 '" + dpart + "'");
            ins.d = li->second - (static_cast<int>(out.size()) + 1);
        }
        ins.s = toInt(spart, l.lineno);
        if (ins.r < 0 || ins.r > 7 || ins.s < 0 || ins.s > 7)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：寄存器号须在 0..7");
        out.push_back(ins);
    }
    return out;
}

}  // namespace tmach
```

```cpp
// file: src/tmvm.hpp
// file: src/tmvm.hpp
// TM 模拟器（L 书 §8.7 的取指-执行循环 + 三错误码 + trace）。
#ifndef TIP_TMVM_HPP
#define TIP_TMVM_HPP

#include <iosfwd>
#include <string>
#include <vector>

#include "tmasm.hpp"

namespace tmach {

constexpr int IADDR_SPACE = 1024;   // 指令存储大小
constexpr int DADDR_SPACE = 512;    // 数据存储大小

struct TmResult {
    enum class Err { None, IMemErr, DMemErr, ZeroDiv } err = Err::None;
    long long steps = 0;                 // 取指次数
    std::vector<std::string> out;        // OUT 的输出（一行一值）
    // 错误现场（正文讲解账用）
    int pc = -1;
};

// 取指-执行循环。boot 语义（书 §8.7.1）：寄存器清零、dMem[0]=DADDR_SPACE-1、PC=0。
// IN 从 input 队列取值（空则取 0——教学口径：真实模拟器读标准输入）。
// trace 非空时每步打一行：`step pc OP r0 r1 r2 r3 r4 r5 r6`（执行后现场）。
TmResult tmRun(const std::vector<TmIns> &ins, const std::vector<long long> &input,
               std::ostream *trace = nullptr, long long maxSteps = 200000);

}  // namespace tmach

#endif  // TIP_TMVM_HPP
```

```cpp
// file: src/tmvm.cpp
// file: src/tmvm.cpp
#include "tmvm.hpp"

#include <array>
#include <sstream>
#include <stdexcept>

namespace tmach {

TmResult tmRun(const std::vector<TmIns> &ins, const std::vector<long long> &input,
               std::ostream *trace, long long maxSteps) {
    if (ins.size() > IADDR_SPACE) throw std::runtime_error("程序超出指令存储");
    std::array<long long, 8> reg{};
    std::array<long long, DADDR_SPACE> dmem{};
    dmem[0] = DADDR_SPACE - 1;   // 书 §8.7.1 的启动约定：可用内存量写在 dMem[0]
    reg[7] = 0;
    size_t inPos = 0;
    TmResult res;

    auto dmemAt = [&](int a) -> long long & {
        if (a < 0 || a >= DADDR_SPACE) {
            res.err = TmResult::Err::DMemErr;
            res.pc = static_cast<int>(reg[7]);
            throw std::runtime_error("DMEM_ERR");
        }
        return dmem[a];
    };
    auto rd = [&](int r) -> long long { return reg[r]; };

    try {
        for (;;) {
            if (++res.steps > maxSteps) {
                res.err = TmResult::Err::IMemErr;   // 步数保险丝计入同一错误通道
                res.pc = static_cast<int>(reg[7]);
                throw std::runtime_error("步数超限（疑似死循环）");
            }
            int pc = static_cast<int>(reg[7]);
            if (pc < 0 || pc >= static_cast<int>(ins.size())) {
                res.err = TmResult::Err::IMemErr;
                res.pc = pc;
                throw std::runtime_error("IMEM_ERR");
            }
            TmIns cur = ins[pc];
            reg[7] = pc + 1;   // 取指即自增——跳转指令随后覆盖它
            int a = 0;
            if (!TmIns::isRO(cur.op)) a = cur.d + static_cast<int>(rd(cur.s));
            switch (cur.op) {
            case TmIns::Op::HALT:
                if (trace) *trace << res.steps << " " << pc << " HALT\n";
                return res;
            case TmIns::Op::IN:
                reg[cur.r] = inPos < input.size() ? input[inPos++] : 0;
                break;
            case TmIns::Op::OUT:
                res.out.push_back(std::to_string(reg[cur.r]));
                break;
            case TmIns::Op::ADD: reg[cur.r] = rd(cur.s) + rd(cur.t); break;
            case TmIns::Op::SUB: reg[cur.r] = rd(cur.s) - rd(cur.t); break;
            case TmIns::Op::MUL: reg[cur.r] = rd(cur.s) * rd(cur.t); break;
            case TmIns::Op::DIV:
                if (rd(cur.t) == 0) {
                    res.err = TmResult::Err::ZeroDiv;
                    res.pc = pc;
                    throw std::runtime_error("ZERO_DIV");
                }
                reg[cur.r] = rd(cur.s) / rd(cur.t);
                break;
            case TmIns::Op::LD: reg[cur.r] = dmemAt(a); break;
            case TmIns::Op::LDA: reg[cur.r] = a; break;
            case TmIns::Op::LDC: reg[cur.r] = cur.d; break;
            case TmIns::Op::ST: dmemAt(a) = rd(cur.r); break;
            case TmIns::Op::JLT: if (rd(cur.r) < 0) reg[7] = a; break;
            case TmIns::Op::JLE: if (rd(cur.r) <= 0) reg[7] = a; break;
            case TmIns::Op::JGE: if (rd(cur.r) >= 0) reg[7] = a; break;
            case TmIns::Op::JGT: if (rd(cur.r) > 0) reg[7] = a; break;
            case TmIns::Op::JEQ: if (rd(cur.r) == 0) reg[7] = a; break;
            case TmIns::Op::JNE: if (rd(cur.r) != 0) reg[7] = a; break;
            }
            if (trace) {
                std::ostringstream os;
                os << res.steps << " " << pc << " " << disasm(cur);
                for (int r = 0; r < 7; ++r) os << " " << reg[r];
                *trace << os.str() << "\n";
            }
        }
    } catch (const std::runtime_error &) {
        return res;   // 错误码已写进 res
    }
}

}  // namespace tmach
```

```cpp
// file: src/cgen.hpp
// file: src/cgen.hpp
// TINY → TM 代码生成器（L 书 §8.8 的 cGen/genStmt/genExp + §8.10 四档优化）。
#ifndef TIP_CGEN_HPP
#define TIP_CGEN_HPP

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "tiny.hpp"

namespace tiny {

class Cgen {
public:
    // 档位累进：None ⊂ Temps ⊂ Vars ⊂ Test（8.10.1 → 8.10.2 → 8.10.3 逐档叠加）。
    enum class Tier { None, Temps, Vars, Test };

    // 产 .tm 文本（经 tmasm 汇编后上 tmvm 跑——文本即接口）。
    std::string gen(const Program &p, Tier tier);

    // 侧通道（指令数账、变量驻留表——正文对账用）
    long long emitted() const { return static_cast<long long>(code_.size()); }
    const std::vector<std::pair<std::string, int>> &residentVars() const { return resident_; }

private:
    std::vector<std::string> code_;
    struct VarInfo {
        int memLoc = -1;
        long long weight = 0;
        int reg = -1;   // -1 = inMem
    };
    std::map<std::string, VarInfo> vars_;
    std::vector<std::pair<std::string, int>> resident_;
    int tmpOffset_ = 0;    // 压负弹正（内存临时栈）
    int tmpDepth_ = 0;     // 当前表达式临时深度（寄存器临时分配）
    bool optTemps_ = false, optVars_ = false, optTest_ = false;
    Tok lastRelop_ = Tok::Lt;   // tier3 直转的条件记忆

    // 发码与回填
    void emitRO(const char *op, int r, int s, int t, const std::string &cmt);
    void emitRM(const char *op, int r, int d, int s, const std::string &cmt);
    void emitRMAbs(const char *op, int r, int addr, const std::string &cmt);
    int emitSkip();
    void backpatch(int at, const std::string &line);

    // 寄存器约定：AC=0 AC1=1 临时=2..4 MP=5 GP=6 PC=7
    static constexpr int AC = 0, AC1 = 1, MP = 5, GP = 6, PC = 7;

    VarInfo &var(const std::string &name);
    void countWeights(const Program &p);
    void assignResidentRegs();

    void genStmt(const Stmt &s);
    void genSeq(const std::vector<std::unique_ptr<Stmt>> &ss);
    void genExp(const Exp &e);
    void genLeafInto(const Exp &e, int r, const char *why);
    void saveTemp(const char *why);
    void loadTemp(const char *why);
    int tempRegFor(int depth) const;
    void emitCond(const Exp &cond);          // 条件计算（含布尔化/直转分档）
    void emitJumpIfFalse(int addr, const std::string &why);
    void emitJumpIfTrue(int addr, const std::string &why);
};

}  // namespace tiny

#endif  // TIP_CGEN_HPP
```

---

上一章：[64 真机实地](64-real-codegen.md) · 下一章：[66 指令级并行](66-ilp.md)
