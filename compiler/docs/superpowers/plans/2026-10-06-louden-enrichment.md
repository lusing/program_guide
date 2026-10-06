# Louden 轮扩充实施计划（编译原理及实践 → 71 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以 Kenneth C. Louden《编译原理及实践》（L 书）为第六轮取材，在现有 66 章基础上新增 5 章、补充 2 章，重编号为 71 章；每章自包含蒸馏原书内容（不让读者翻原书），全部示例三层对账全绿。

**Architecture:** 沿用五轮验证过的模式：批式推进（重编号→逐新章→补充→收官）、每章 `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）、机器证人（断言语料 + expected 对账）、`check_docs.py` 字节级内嵌校验。L 书 PDF 文本层完好（pymupdf 已抽至 `.scratch/louden_01..09.txt`），无需 OCR。五个新章零 ANTLR 零 LLVM——Louden 路线本身就是手写机器路线（迷你 lex/yacc、错误恢复、四机制解释器、gcc -S 对账、TM 模拟器）。

**Tech Stack:** C++17（`tools/example_build.sh` 现行口径，MSYS2 UCRT64 g++，-Wall -Wextra -Werror）、gcc -S（64 章运行期调用）、Python 校验脚本。

**Spec:** `docs/superpowers/specs/2026-10-06-louden-enrichment-design.md`（本计划 argues from spec，执行者两份都读）。用户六轮恒定要求——教程而非代码罗列；讲解的代码正文引用；书籍内容提炼核心自包含；没有篇幅限制讲清楚为止。

## Global Constraints

- 每章正文 ≥200 行且**文字行多于本章新写代码行**（**新代码口径**：旧章冻结副本不计入代码侧——用户 2026-10-06 裁定，09 章起生效）。
- 示例的 `src/*.cpp|hpp`、`expected/output.txt` 全部以 `// file:` / `; expected:` 围栏**字节级内嵌**进正文；改码后跑 `python .scratch/renumber5.py embed` 重生成（幂等，全量重嵌）。
- 三层对账：`export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH`，然后 `bash tools/example_build.sh examples/NN_slug .` → `python tools/check_example.py G:/code/guide/compiler/examples/NN_slug`（绝对路径）→ `python tools/check_docs.py` 全绿后才提交。
- 提交只 stage `compiler/` 路径；消息 `feat(compiler): 批次N——…`，尾注 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；`.scratch/`、`tools/__pycache__/` 永不入库。
- **C++/含反斜杠内容一律 Write/Edit 工具写文件，禁止 Bash heredoc**（反斜杠坑多轮复发）。
- 查询 map 已删节点一律 `find` 不 `operator[]`；**switch 遍枚举一律带 default 断言**（Lt 潜伏坑：跨枚举对照的两张表必须同步，default 静默是坑温床）。
- 每章注明取材节号（如「L 书 §8.7」）；L 书语料按需改写，改写处如实说明。
- L 书取材：grep `.scratch/louden_01..09.txt`（`=== volN pM ===` 分页头）。**卷首书页映射**：vol1→书1（第1章）、vol2→书21（第2章）、vol3→书69（第3章）、vol4→书105（第4章）、vol5→书151（第5章）、vol6→书198（第6章）、vol7→书266（第7章）、vol8→书305（第8章）、vol9→书373（附录A，附录B/C 不在 PDF 内——TM 按 §8.7 文字规格自实现，不抄附录 C）。关键节书页：§1.7 TINY 语言 14；§2.5 TINY 扫描器 52、§2.6 Lex 57；§4.4 TINY 递归下降 136、§4.5 自顶向下错误校正 137；§5.4–5.6 Yacc 163–192、§5.7 自底向上错误校正 188；§6.4.3 类型等价 248；§7.2 完全静态环境 269、§7.3.3 过程参数 284、§7.5 参数传递 292；§8.1.3 P-代码 310、§8.6 商用案例 339、§8.7 TM 346、§8.8 TINY 代码生成器 351、§8.10 三优化 366。
- 64 章 gcc -S 对账用「模式 → 计数」表，不用逐字节汇编（版本敏感）；expected 由本机 gcc 钉版生成。

## 重编号映射（旧→新，66→71）

| 旧 | 新 | | 旧 | 新 | | 旧 | 新 |
|---|---|---|---|---|---|---|---|
| 1–8 | 1–8 | | 24 | 27 | | 46 | 49 |
| **新** | **09** | | 25 | 28 | | 47 | 50 |
| **新** | **10** | | 26 | 29 | | 48 | 51 |
| 09 | 11 | | 27 | 30 | | 49 | 52 |
| 10 | 12 | | 28 | 31 | | 50 | 53 |
| 11 | 13 | | 29 | 32 | | 51 | 54 |
| 12 | 14 | | 30 | 33 | | 52 | 55 |
| 13 | 15 | | 31 | 34 | | 53 | 56 |
| 14 | 16 | | 32 | 35 | | 54 | 57 |
| 15 | 17 | | 33 | 36 | | 55 | 58 |
| 16 | 18 | | 34 | 37 | | 56 | 59 |
| 17 | 19 | | 35 | 38 | | 57 | 60 |
| 18 | 20 | | 36 | 39 | | 58 | 61 |
| 19 | 21 | | 37 | 40 | | 59 | 62 |
| **新** | **22** | | 38 | 41 | | 60 | 63 |
| 20 | 23 | | 39 | 42 | | **新** | **64** |
| 21 | 24 | | 40 | 43 | | **新** | **65** |
| 22 | 25 | | 41 | 44 | | 61 | 66 |
| 23 | 26 | | 42 | 45 | | 62 | 67 |
| | | | 43 | 46 | | 63 | 68 |
| | | | 44 | 47 | | 64 | 69 |
| | | | 45 | 48 | | 65 | 70 |
| | | | | | | 66 | 71 |

插入点：新 09/10（旧 08 后）、新 22（旧 19 后、旧 20 前）、新 64/65（旧 60 后）。篇结构：第二篇 前端 3–14（12 章）、第三篇 中间表示与运行时 15–23（9 章）、第四~十篇 +3、第十一篇 代码生成与并行 61–69（9 章）、第十二篇 收束 70–71。

---

### Task 1: 重编号 66→71（批五十）

**Files:**
- Modify: `docs/NN-*.md` ×59（重写引用）、`examples/NN_*/` ×59（git mv）、`README.md`、`docs/66-finale.md`→`71-finale.md`
- Create: `.scratch/renumber5.py`（复制 `renumber4.py` 骨架换 MAP）

- [x] 换 MAP 为上表（09–19:+2、20–63:+3、64–66:+5；五个新号 09/10/22/64/65 不在 MAP——留给新章）；核对 renumber4 遗留守卫：output.txt 守卫 `"60_finale"` 按当前实况改 `"66_finale"`（rewrite 阶段还是旧名 66）；survey 行守卫已是通用 `^\[\d+/\d+\]` 勿动；`rw_quoted_range` 对 survey.cpp 字符串 `"NN-MM"`/`"NN"` 的重写核对五处新插入不误伤（9、10、22、64、65 是新号，旧文档里 9/10/22/64/65 会被 +2/+3/+5 平移——映射表已覆盖）
- [x] 跑 `python .scratch/renumber5.py rewrite`（计数多重集前后一致）→ `rename`（两阶段 git mv）→ 重建 71_finale 二进制并**重生成 expected**（从新二进制跑出落盘，不手改；survey 输出行 `[n/32]` 的章号引用已被 rw_paren_range 平移）→ `python .scratch/renumber5.py embed` 全量重嵌 → 三层全量回归 66 项仍绿（此时新章未建、README 暂列 71 目标口径）
- [x] Commit: `feat(compiler): 批次五十——66→71 重编号腾位（Louden 轮开工）`

### Task 2: 新 09 章 Lex 与 Yacc 的心脏（批五十一）

**Files:**
- Create: `docs/09-lex-yacc.md`、`examples/09_lex_yacc/src/{re.hpp,re.cpp,lr1.hpp,lr1.cpp,yacc.hpp,yacc.cpp,demo.hpp,demo.cpp,main.cpp}`、`examples/09_lex_yacc/expected/output.txt`

**Interfaces:**
- `re.{hpp,cpp}`：05 章正则→NFA→DFA 引擎**本地副本**（文件名保留原章名，便于读者对照）。
- `lr1.{hpp,cpp}`：08 章 LALR(1) 项集/造表**本地副本**（按需小幅改接口：文法符号 int 编号统一）。
- 新增（签名冻结，Task 3 复制扩展）：
```cpp
// yacc.hpp —— 值栈驱动器
struct YaccValue { enum class Tag { Empty, Num, Str } tag;
                   double num; std::string str; };        // %union 教学版
using Action = std::function<YaccValue(std::vector<YaccValue>&)>;  // vals[k-1] 即 $k，返回 $$
struct Rule { int lhs; std::vector<int> rhs; Action action; };     // action 可空
enum class Assoc { None, Left, Right };
class MiniYacc {
 public:
  MiniYacc(std::vector<Rule>, int startSym, std::vector<int> termIdx);
  void setPrec(int term, int level, Assoc);              // 优先级/结合性声明
  // parse：归约序 trace（含嵌入动作展开标记）+ 最终 $$；冲突仲裁结果计数
  YaccValue parse(const std::vector<Tok>&, std::ostream* trace, int* conflicts) const;
};
// demo.hpp —— 迷你 Lex：规则表 → 组合 DFA → 最长匹配（同长先声明优先）
struct Tok { int kind; std::string text; int line; };
std::vector<Tok> miniLex(const std::vector<LexRule>&, const std::string& src);
```

**内容**（取材 §2.6、§5.4–5.6）:
1. §09.1 族谱：1975 Lesk lex / Johnson yacc → flex/bison/byacc → 与 ANTLR（04 章）世代对照——自底向上+值栈 vs 自顶向下+树；「生成器为什么出现在 1975」（造表贵、人力贵、文法即规格）。
2. §09.2 Lex 心脏：规格文件三段式（定义%%规则%%用户码）；**最长匹配、同长先声明优先**（`<=` vs `<` 的仲裁法）；yytext/yyleng/yylineno/yylval 契约；迷你 lex 走读（规则表并联进一个 NFA→DFA，05 章机器的第三种用法）。
3. §09.3 Yacc 心脏：LALR(1) 表（08 章复用）+ **双栈平行**——状态栈与值栈同步移进/弹出；归约时弹 n 个 `$k`、动作算 `$$` 压回；**动作只在归约时执行**（移进不跑代码）——这是自底向上翻译与 13 章 SDD S-属性在栈上求值的机械对应。
4. §09.4 任意值类型：%union = 带标签联合（YaccValue）；%type 给每个符号声明标签；类型不匹配=生成器报错（教学版：运行期 tag 断言）。
5. §09.5 嵌入动作：`A → a {动作} b` ≡ `A → a N b; N → ε {动作}` 的空产生式改写——教学版**两版文法都真实构造**并跑同语料；位置陷阱（嵌入动作后 `$n` 序号偏移）。
6. §09.6 冲突仲裁：shift/reduce 优先级投票（产生式优先级=最右终结符；与当前 token 比，高者胜、同高看结合性——§5.5.3 规则）；悬空 else 缺省 shift 的来由；reduce/reduce 缺省取先声明（武断但确定的口径）。翻转实验：同文法声明前后 `2+3*4`、`-2-3`、`2^3^2`（幂教学扩展）三语料结果对照。
7. §09.7 三路对照收束：手写递归下降（06 章）/Pratt（11 章）/yacc 心脏（本章）——表谁算、优先级谁定、错误恢复谁强；error 记号预告（10 章）。

**断言**（main.cpp 内嵌语料，简单协议，无 ANTLR）:
1. 迷你 lex+yacc 解析教学子集（算术+比较+幂+赋值序列）求值输出与期望全等。
2. 同语料与 08 章 LALR 副本**归约产生式序列逐条一致**（对账核心：两张表同源必须零漂移）。
3. 嵌入动作展开改写前后：动作执行序与求值结果一致（计数器证人）。
4. 优先级翻转：无声明版（冲突计数>0，缺省 shift）与声明版结果对照入 expected。
5. 最长匹配语料（`<=`/`<`/`==`/`=` 混排）token 流正确。

- [x] 写 src（05/08 副本 + yacc/demo + 语料）→ 三层对账 → expected 落盘
- [x] 写正文（七节、全部代码内嵌、期望输出逐行解读、练习；文字行多于代码行）
- [x] 三层绿 → Commit: `feat(compiler): 批次五十一——09 Lex 与 Yacc 的心脏`

### Task 3: 新 10 章 语法错误的恢复与校正（批五十二）

**Files:**
- Create: `docs/10-error-recovery.md`、`examples/10_error_recovery/src/{re.hpp,re.cpp,lr1.hpp,lr1.cpp,yacc.hpp,yacc.cpp,llrec.hpp,llrec.cpp,main.cpp}`、`expected/output.txt`
- `re/lr1/yacc` 为 09 章**本地副本**；`llrec.{hpp,cpp}` 改自 06 章 `ll1.{hpp,cpp}` 副本（表驱动 LL(1) + 恢复钩子）

**Interfaces:**
```cpp
enum class Recover { None, Panic, Phrase, ErrorProd };
struct Diag { int line; std::string msg; };
struct ParseResult { bool accept; std::vector<Diag> diags; size_t steps; };
// llrec.hpp
ParseResult llParse(const Grammar&, const std::vector<Tok>&, Recover mode);
// yacc.hpp 扩展：Rule.lhs 可含 ERROR_T 伪终结符（error 记号）；yyerrok=同步动作
ParseResult lrParse(const MiniYacc&, const std::vector<Tok>&, Recover mode,
                    std::ostream* reduceLog);
```

**内容**（取材 §4.5、§5.7、§3.3.2）:
1. §10.1 错误的性质与检测点：首现点 vs 检测点；LL 空表项即报（恰在错 token 处）；LR 活前缀性质——任何时刻栈内容+剩余输入构成活前缀才合法，**LR 检测永不晚于、通常早于 LL**（§5.7.1 构造性论证：LR 栈已含全部前文信息）；两侧检测位置实测对照表。
2. §10.2 恐慌模式：丢 token 至 FOLLOW(出错非终结符) 同步集；递归下降版=每过程 catch 后跳自身同步集（§4.5.1）；表驱动版=弹栈至可恢复状态+丢输入（§4.5.2）；**级联抑制账**：缺分号 → 无恢复 3 个假错误 vs 恐慌 1 个真错误。
3. §10.3 短语级恢复：以剩余首 token 查表做插入/删除/替换（§4.5.2 局部修复）；**抖动死循环**——纯插入反复触发的构造性反例 + 「连续两次纯插入禁令」守卫。
4. §10.4 错误产生式与 yacc error 记号：常见错误写进文法（§5.7.3）；error 进栈后进恢复态、丢弃至同步点（`;`/`)`）、yyerrok 复位重启正常分析；TINY 错误校正走读（§4.5.3/§5.7.4）。
5. §10.5 诊断质量：报位置+期望集 vs 实际 token；最小编辑修复思想（文字）；恢复的两难——多报假错 vs 漏报真错。
6. §10.6 前端工程收束：恢复策略选择表（教学编译器/生产编译器各有取舍）；与 04 章 ANTLR 错误监听器对照。

**断言**（错误语料内嵌，简单协议）:
1. 级联对照：同语料 None 版诊断数 vs Panic 版诊断数（构造缺分号+两后续语句语料，3 vs 1 计数入 expected）。
2. LL/LR 检测位置表：≥8 条错误语料，两侧 `(行, token)` 对照行 + 「LR ≤ LL」比例统计行。
3. error 产生式恢复后剩余合法语句完整归约（reduceLog 后半与前缀无错版逐条一致）。
4. 抖动语料在 Phrase 模式下步数有上界（守卫生效，上限常数打印）。
5. Panic 恢复后无错前缀可求值（输出前缀表达式结果）。

- [x] 副本 + llrec/yacc 恢复扩展 → 断言 → expected → 正文（六节）→ 三层绿
- [x] Commit: `feat(compiler): 批次五十二——10 语法错误的恢复与校正`

### Task 4: 新 22 章 参数传递的四种机制（批五十三）

**Files:**
- Create: `docs/22-param-passing.md`、`examples/22_param_passing/src/{lang.hpp,front.hpp,front.cpp,interp.hpp,interp.cpp,main.cpp}`、`expected/output.txt`

**Interfaces:**
```cpp
// lang.hpp —— 教学子集 AST：函数/形参带机制注记/一维数组/赋值/if/while/for/output
enum class PassMode { Val, Ref, ValRes, Name };          // 形参语法：fun p(val x, ref y, valres z, name w)
struct Param { std::string name; PassMode mode; bool isArray; };
// interp.hpp
struct Thunk { const Expr* body; Env* defEnv; };          // 名字传递：实参表达式+定义环境
struct Actual { PassMode mode; const Expr* expr; int64_t* refAddr; Thunk thunk; };
class Interp {
 public:
  explicit Interp(bool fullyStatic);                      // 完全静态环境开关
  int64_t call(const Function&, std::vector<Actual>&, Env& caller);
  // 静态模式：每函数一帧（static std::map），调用图环 → 抛 RecursionRejected
};
```

**内容**（取材 §7.2、§7.3.3、§7.5、§1.5）:
1. §22.1 没有栈的世界：**完全静态运行时环境**（FORTRAN 77）——每过程一份静态帧、地址编译期定死、递归禁令的由来（第二份帧无处安放）；静态帧=活动记录即全局变量（变量跨调用**保留**值的实测）；要递归就要栈——连回 21 章栈环境的动机面。
2. §22.2 值传递：参数=被初始化的局部变量；`inc2(int x)` 反例走读；C 数组退化为指针——「半个引用」的错觉剖析；大结构拷贝的代价账。
3. §22.3 引用传递：别名；FORTRAN 77 唯一机制的表达式实参 `p(2+3)`——编译器**造临时格**（地址稳定性实测：副作用函数两次调用间临时格地址不变）；Pascal `var`/C++ `&`/`const&`（免拷贝+静态只读检查）三语言口径。
4. §22.4 值结果传递：copy-in copy-out；**`p(a,a)`：引用 → a=3，值结果 → a=2——别名是唯一分辨器**（逐行推演两版数据流）；书上证实的两个未指定问题（写回顺序、地址重算时机）——实现取「声明序写回、入口算地址」并如实标注是实现口径；对调用序列的修改（被调者不能释放帧、调用者要存实参地址）。
5. §22.5 名字传递：换名=实参表达式在被调者体内**每次使用处重求值**；thunk=编译成无参过程（教学版=表达式+定义环境对，即 15 章闭包的最小形态）；**Jensen 装置**：`sum(i,1,n,a[i])` 名字传递下循环变量改写穿透实参的经典；**`swap(i, a[i])` 槽位错乱**——引用正确交换、名字因 `i` 先被改写到 `a[a[i]]`（分辨名字 vs 引用的关键反例）；Algol 60 历史、被淘汰的原因、思想活在惰性求值（互参预告）。
6. §22.6 过程参数（§7.3.3）：传过程=代码地址+定义环境对（栈环境要访问链的原因）；与 15 章闭包、21 章访问链三方互参。
7. §22.7 编译器视角总表：四机制 ×（实参求值时机/调用序列增量/帧布局/访问代码/别名风险/重求值）六行账；语言设计注记（§1.5：机制选择如何反过来塑造语言）。

**断言**（语料内嵌，简单协议）:
1. `p(a,a)`（`++x;++y;`，a 初值 1）四机制 a 终值：val 1 / valres 2 / ref 3 / name 3 各自打印；`swap(i,a[i])`：ref 正确交换、name 写错槽位（按构造语料数值打印）。
2. Jensen 语料：name 求和正确 + thunk 求值次数 = 形参使用次数（计数器证人，期望次数手推入正文）。
3. 完全静态模式：非递归计数器程序跨调用保留值（静态语义证人）；递归语料被调用图环检测拒绝（诊断行）。
4. ref 的表达式实参临时格地址稳定（打印格地址两次相同）。
5. valres 双写回按声明序：`p(valres x, valres y)` 传入同一变量两别名时终值与手推一致（写回序 x 先 y 后）。

- [ ] 写 src（前端+解释器四机制+静态模式）→ 断言 → expected → 正文（七节）→ 三层绿
- [ ] Commit: `feat(compiler): 批次五十三——22 参数传递的四种机制`

### Task 5: 新 64 章 真机实地：两个商用编译器的代码生成（批五十四）

**Files:**
- Create: `docs/64-real-codegen.md`、`examples/64_real_codegen/src/{snippets.hpp,asmcheck.hpp,asmcheck.cpp,main.cpp}`、`expected/output.txt`

**Interfaces:**
```cpp
// snippets.hpp —— 与书上同款的 C 片段（内嵌字符串）
// asmcheck.hpp
struct Pattern { std::string name; std::regex re; };
struct FuncReport { std::string func, opt;    // opt ∈ {"-O0","-O1"}
                    size_t insnCount; std::map<std::string,int> hits; };
// 落盘 tmpdir → 调 gcc -S -o out.s（popen/system，PATH 上 gcc）→ 逐行匹配计数
std::vector<FuncReport> checkAll(const std::vector<std::string>& funcs,
                                 const std::vector<Pattern>&, bool o1);
```

**内容**（取材 §8.6 全节；书内两案例全部汇编清单**完整入正文**逐行讲解）:
1. §64.1 为什么看真机：教学 IR 与真机的鸿沟（寻址模式多样、寄存器饥饿、指令代价不对称）；Louden 选 1992 年两个编译器的理由（文档全、CISC 与 RISC 两端）。
2. §64.2 Borland C 3.0 / 80×86 走读：`(x=x+3)+4` → ax 累加器风格、`[bp-2]` 帧寻址（bp=帧指针、int 占 2 字节）、`word ptr` 尺寸标注；数组 `(a[i+1]=2)+a[j]` → `shl bx,1` 比例伸缩（80×86 无 scale 寻址时乘 2 靠移位）、`lea` 取地址、基+变址组合；if/while 控制流（条件转移与标志寄存器）；函数调用：栈传参、清栈责任（cdecl 调用者清 / pascal 被调者清 `ret n`）。
3. §64.3 Sun cc 2.0 / SPARC 走读：**寄存器窗口**（%o/%i/%l 分组、SAVE/RESTORE 换窗口、窗口溢出/下溢陷阱——「寄存器更多但要靠调用层次回滚」）；**延迟转移槽**（转移指令后一拍必执行——编译器要填空：填独立指令或 nop；与 66 章 ILP 的填空思想同源）；装入-存储架构（只有 ld/st 碰内存）；定长指令的代价（一条 `shl` 变三指令的展开账）。
4. §64.4 两机对照表：累加器 vs 寄存器窗口；内存-内存操作 vs 装入-存储；变长 vs 定长指令；清栈责任；CISC/RISC 谱系一句话史。
5. §64.5 三十年对账（主证人）：本机 gcc `-O0 -S` 编译同款函数——`push rbp / mov rbp,rsp`（帧建立三十年未变）、`[rbp-x]` 局部寻址照旧、比例寻址自带 scale（`shl` 伸缩消失——寻址模式进化）、`lea` 照旧、`call/ret` 对；Windows x64 寄存器传参（rcx/rdx/r8/r9）vs 1992 全栈传参；`-O1` 删了什么（逐条讲：栈槽消除、强度削减、跳转链压缩）。
6. §64.6 时代注记：RISC-V 取消延迟槽（编译器不该替硬件填空的思想反转）；调用约定是 ABI 的一部分（互参 21 章）；Louden 的两案例在今天的对应物（gcc/clang -fverbose-asm、godbolt）。

**断言**（C++ 驱动运行期调 gcc -S，打印「函数 × 档位 → 模式计数 + 指令数」表；gcc 失败走明确报错路径）:
1. -O0 模式表：帧建立（push rbp 或 mov rbp,rsp 计数 ≥1）、`[rbp-` 计数、下标伸缩（lea/imul/shl 任一）计数、call+ret 对——各函数行入 expected。
2. 同函数 -O0 vs -O1 指令条数两档入 expected（下降）。
3. 书内 Borland/SPARC 清单的行数与关键指令计数与正文讲解账一致（讲解性核对，正文表格）。

- [ ] 写 src（snippets + asmcheck + 驱动）→ 本机 gcc 生成 expected → 正文（六节、书内清单全量入正文）→ 三层绿
- [ ] Commit: `feat(compiler): 批次五十四——64 真机实地：两个商用编译器`

### Task 6: 新 65 章 TM 目标机器与 TINY 代码生成（批五十五）

**Files:**
- Create: `docs/65-tm-machine.md`、`examples/65_tm_machine/src/{tiny.hpp,tinyscan.hpp,tinyscan.cpp,tinyparse.hpp,tinyparse.cpp,tmasm.hpp,tmasm.cpp,tmvm.hpp,tmvm.cpp,cgen.hpp,cgen.cpp,main.cpp}`、`expected/output.txt`

**Interfaces:**
```cpp
// tiny.hpp：TINY AST（StmtK: If/Repeat/Assign/Read/Write；ExpK: Op/Const/Id——L 书 §8.8.2 原构型）
// tmasm.hpp —— 两遍汇编器
struct TmIns { enum class Op { HALT,IN,OUT,ADD,SUB,MUL,DIV,LD,LDA,LDC,ST,
                               JLT,JLE,JGE,JGT,JEQ,JNE } op; int r,d,s; };
std::vector<TmIns> assemble(const std::string& tmText);   // 一遍标号地址、二遍编码
// tmvm.hpp —— 模拟器
struct TmResult { enum class Err { None, IMemErr, DMemErr, ZeroDiv } err; int steps; };
TmResult tmRun(const std::vector<TmIns>&, std::istream& in, std::ostream& out,
               std::ostream* trace);                       // r7=PC 先自增；dMem[0]=DADDR-1 启动
// cgen.hpp —— TINY→TM，四档
enum class Opt { None, TempsInRegs, VarsInRegs, TestOpt }; // 8.10.1 / 8.10.2 / 8.10.3
std::string genTm(const Program&, Opt);                    // 产 .tm 文本（经 tmasm 自举对账）
```
寄存器约定（L 书 §8.8）：ac=r0、ac1=r1、mp=r5（内存顶=临时栈基）、gp=r6（变量基址）、tmpOffset 初 0 压负弹正。

**内容**（取材 §8.7、§8.8、§8.10、§1.7、§2.5、§4.4）:
1. §65.1 目标机 TM：只读 iMem + dMem + 8 寄存器、**r7=PC 唯一专用、无 sp/fp 无硬件栈**（编译器全手工维护运行时——一切显式的教学价值）；启动约定 dMem[0]=最高地址；RO 格式 `op r,s,t` 与 RM 格式 `op r,d(s)`、`a=d+reg[s]`；六条件转移 + `LDA 7,x(7)` 即无条件转移；三错误码；「最小指令集如何撑起高级语言」六条使用说明（§8.7 末：先目标后源、算术只在寄存器、立即数只有 LDC、间接寻址靠 LD/LDA 组合……）。
2. §65.2 两遍汇编器：.tm 文本（标号:`/注释`;`/指令三域）；一遍标号→行号表、二遍编码 `r,d(s)` 文法（递归下降 40 行吃完一门汇编语言）；代码生成器产 .tm 文本再自举汇编——文本即接口的可调试性。
3. §65.3 模拟器：取指-执行循环（`ins = iMem[reg[7]++]` 先自增）；trace 每步 `(pc, op, r0..r6)` 现场；错误三码的触发条件与现场打印。
4. §65.4 TINY 前端：手写扫描器（§2.5：保留字表+标识符/数字）+ 递归下降（§4.4）——Louden 原路线；与 04 章 ANTLR 路线对照（为什么 1995 年教学实现手写：自包含、可单步）。
5. §65.5 代码生成器：cGen/genStmt/genExp 树遍历发码（15 章 Visitor 的发码版）；寄存器约定账；**tmpOffset 软件临时栈**——`a*b+c*d` 的压弹逐指令推演（`ST ac,tmp--,mp`/`LD ac1,++tmp,mp`）；比较运算 C 风格布尔化五指令模板（SUB/JLT+2(7)/LDC 0/LDA 7,1(7)/LDC 1——与 58 章短路布尔化同律对照）；if/repeat 的 **emitSkip/emitBackup/emitRestore 缓冲区级回填**——跳转目标先占位、子树编译完回填（与 58 章字节流内偏移回填两公式对照：**地址域不同、公式不同、思想同——写公式先写模拟器三行注释再代数，不许心算**）。
6. §65.6 四档优化逐档（§8.10）：档 0 朴素；档 1 临时入寄存器（saveTmp/loadTmp：tmpOffset 0–4 映射 r0–r4、负值落内存 +5 偏移）；档 2 变量驻留寄存器（引用计数 ×10^循环深度加权、inReg/inMem 位置描述符——**变量地址描述器第一课**，通往 61 章寄存器分配）；档 3 测试表达式直转（比较根节点直接条件转移 + 补条件 JGE、删尾部空转移）。逐档指令数账复现清单 8-14→8-15→8-16→8-17 的单调缩短。
7. §65.7 四方目标机对照收束：TM（寄存器机+文本汇编+两遍汇编器）vs 57 章栈机（字节流+直发+运行期值栈）vs 60 章 isel（模式重写）vs LLVM（17 章）——指令密度/解码成本/可读性/回填层次四轴。

**断言**（TINY 语料内嵌 + .tm 文本打印，简单协议）:
1. 语料 ≥4（阶乘 sample.tny 同款、gcd、if/repeat/read/write 综合、嵌套比较）四档全跑输出全等且与手推期望全等。
2. **四档指令数单调下降**且数值与正文手推账一致（每语料打印四档计数行）。
3. trace 抽样：gcd 语料前 12 步寄存器现场表入 expected。
4. DMEM_ERR（ST 越界语料）/ZERO_DIV（除零语料）触发错误码与步数正确。
5. 全语料档 3 与档 0 输出全等（语义不变证人）。

- [ ] 写 src（前端/汇编器/模拟器/cgen 四档）→ 断言 → expected → 正文（七节）→ 三层绿
- [ ] Commit: `feat(compiler): 批次五十五——65 TM 目标机器与 TINY 代码生成`

### Task 7: 补 57 章（原 54）P-代码谱系（批五十六）

**Files:**
- Modify: `examples/57_bytecode_vm/src/{pcode.hpp,pcode.cpp,main.cpp}` + `docs/57-bytecode-vm.md`（新增一节三块；embed 重生成）+ `expected/output.txt` 重生成

**内容**（取材 §8.1.3）:
1. P-机器与 P-代码史：70 年代 Pascal 编译器的标准目标码——编译器写一次、每平台只重写解释器（可移植性策略；JVM/CLR/WebAssembly 的曾祖父——谱系图）。
2. 简化 P-码指令集：ldc/lod/lda/mpi/sbi/adi/sro/…；`2*a+(b-3)` 与 `x:=y+1` 的 P-码序列逐行入正文；与本章 chunk 字节码**逐条对照表**（栈效应同构：两边都是隐式操作数栈、弹二压一）。
3. P-码作为合成属性：pcode 属性文法（§8.1 表 8-1）——字符串拼接式代码生成，与 13 章 SDD 互参（「把代码当属性算」的谱系）。

**断言**（追加进 main，expected 重生成）: (1) 书内示例表达式集生成 P-码文本与正文手推逐行一致；(2) ~60 行 P-机器解释循环执行这些 P-码，结果与 chunk-VM 等价字节码程序全等。
- [ ] 加 pcode.{hpp,cpp} + main 扩 → 重建 → 新 expected → `renumber5.py embed` 重嵌该章 → check_docs 绿
- [ ] Commit: `feat(compiler): 批次五十六——57 补 P-代码谱系`

### Task 8: 补 27 章（原 24）类型等价（批五十七）

**Files:**
- Modify: `examples/27_records_limits/src/{typeequiv.hpp,typeequiv.cpp,main.cpp}`（新文件对，沿现有 ast/constraints/unify 命名风格）+ `docs/27-records-limits.md`（新增一节三块；embed 重生成）+ `expected/output.txt` 重生成

**内容**（取材 §6.4.3）:
1. 结构等价 vs 名字等价 doctrine：Pascal `var` 参数与记录声明的严格、C 结构的结构等价怪癖（匿名/逐处声明的结构处处等价）、Ada 名字等价 + 子类型（`subtype` 同表示不同名）；「同一语言两种口径并存」的实况。
2. 判定算法：结构等价 = 类型树同构递归（**递归类型的环处理**：假设集/coinduction 一句话门）；名字等价 = 符号表身份比较；陷阱实测（字段序敏感、参数名不算、别名传递性）。
3. 与 25 章合一的关系：结构等价是无方向的结构合一——推断式语言把「检查等价」泛化成「求解等式」；27 章记录行的边界讨论在此补上「等价判定的语言设计维度」。

**断言**（追加进 main，expected 重生成）: (1) 两模式判定器对语料集（递归别名 `t = record{t next}`、字段序反例、匿名 vs 命名、var 参数匹配）输出各异且与手推全等；(2) 环处理对自引用类型不发散（步数上限打印）。
- [ ] 加 typeequiv.{hpp,cpp} + main 扩 → 重建 → 新 expected → embed 重嵌 → check_docs 绿
- [ ] Commit: `feat(compiler): 批次五十七——27 补类型等价`

### Task 9: 收官（71/71，批五十八）

**Files:**
- Modify: `examples/71_finale/src/survey.cpp` + expected（survey 扩 5 行：Lex/Yacc 值栈 09、错误恢复 10、参数传递 22、真机对照 64、TM 代码生成 65——行式照 survey 现有六列结构）+ embed 全量重嵌
- Modify: `docs/71-finale.md`（每章一句话 71 句、口径 66→71、延伸阅读补 Louden）、`README.md`（六书口径：SPA 骨架 + 绿龙/紫龙/虎/鲸/匠/L；十二篇导航：第二篇 3–14、第三篇 15–23、第十一篇 61–69；验证状态 71/71）
- Modify: 记忆 `G:\xulun\.claude\projects\G--code-guide\memory\compiler-tutorial-build.md` + `MEMORY.md`

- [ ] survey 扩行 + expected 从新二进制重生成 + embed 全量重嵌
- [ ] 每章一句话 71 句、README 六书十二篇定稿
- [ ] 全量三层回归 71/71 exit 0（`bash run-all.sh`）
- [ ] Commit: `feat(compiler): 批次五十八——71 章收官更新与 README 定稿（Louden 扩充完成）`
- [ ] 更新记忆文件与 MEMORY.md 索引

## Self-Review

- **覆盖**：spec 五新章（09/10/22/64/65）各有任务；两补章（57 P-代码、27 类型等价）各有任务；收官（survey/finale/README/记忆）在 Task 9；spec 的全部断言按章落进各任务断言块（含 p(a,a) 四机制四结果、swap 槽位错乱、Jensen 计数、四档指令数单调、模式表等）。
- **占位符**：无 TBD；每任务给出文件清单、接口签名、内容节纲与断言语料设计。
- **类型一致**：MiniYacc/Rule/YaccValue 签名在 Task 2 冻结，Task 3 声明「本地副本+恢复扩展」；TmIns/TmResult/Opt 在 Task 6 自洽；副本文件名保留原章名（re/lr1/ll1→llrec）便于读者对照。
- **依赖次序**：Task 1 重编号先行；Task 2→3 依赖链（10 章复制 09 章 yacc 心脏）；Task 5→6 建议次序（真机案例作 TM 动机，但无硬依赖）；Task 4/7/8 独立；Task 9 收官最后。
