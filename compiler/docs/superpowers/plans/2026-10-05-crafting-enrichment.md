# 匠书轮扩充实施计划（Crafting Interpreters → 66 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以 Robert Nystrom《Crafting Interpreters》（匠书）为第五轮取材，在现有 60 章基础上新增 6 章、补充 2 章，重编号为 66 章；每章自包含蒸馏原书内容（不让读者翻原书），全部示例三层对账全绿。

**Architecture:** 沿用四轮验证过的模式：批式推进（重编号→逐新章→补充→收官）、每章 `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）、机器证人（断言 + outputs 语义对账）、`check_docs.py` 字节级内嵌校验。匠书 PDF 文本层完好（pymupdf 直接抽取），无需 OCR。新篇「第十篇 字节码解释器（54–57）」形成 TIP 第三条执行路：同一程序 LLVM JIT / TAC 解释器 / 字节码 VM 输出全等。

**Tech Stack:** C++23（MSYS2 UCRT64 g++）、ANTLR4（仅新 13 章复用 12 章文法副本）、Python 校验脚本。

**Spec:** `docs/superpowers/specs/2026-10-05-crafting-enrichment-design.md`（本计划 argues from spec，执行者两份都读）。用户五轮恒定要求——教程而非代码罗列；讲解的代码正文引用；书籍内容提炼核心自包含；没有篇幅限制讲清楚为止。

## Global Constraints

- 每章正文 ≥200 行且**文字行多于代码行**（fence 翻转计数）。
- 示例的 `src/*.cpp|hpp`、`TIP.g4`（如有）、`expected/output.txt` 全部以 `// file:` / `; expected:` 围栏**字节级内嵌**进正文；改码后跑 `python .scratch/renumber4.py embed` 重生成（幂等，全量重嵌）。
- 三层对账：`bash tools/example_build.sh examples/NN_slug .` → `python tools/check_example.py examples/NN_slug`（绝对路径）→ `python tools/check_docs.py` 全绿后才提交。
- 提交只 stage `compiler/` 路径；消息 `feat(compiler): 批次N——…`，尾注 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；`.scratch/`、`tools/__pycache__/` 永不入库。
- 工具链：`export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH`；**ANTLR 示例必须经 UCRT64 壳构建**：`UCRT_INVOKED=1 /g/scoop/apps/msys2/current/usr/bin/bash -lc "cd /g/code/guide/compiler && UCRT_INVOKED=1 bash tools/example_build.sh examples/NN_slug ."`（Git Bash 直跑会链到 scoop MinGW gcc，ANTLR 静态库 ABI 不匹配）。
- **C++/含反斜杠内容一律 Write/Edit 工具写文件，禁止 Bash heredoc**（反斜杠坑四轮五次复发）；事后 `grep -n "^[^']*'$"` 类坏行排查。
- 查询 map 已删节点一律 `find` 不 `operator[]`。
- 每章注明取材节号（如「匠书 §25.2」）；Lox 语义按需改写为 TIP 子集/C++23，改写处如实说明。
- 匠书 PDF 取材：`python -X utf8 -c "import fitz; doc=fitz.open(r'G:\book\计算机\编译原理\Crafting Interpreters (Robert Nystrom) (z-library.sk, 1lib.sk, z-lib.sk).pdf')"`——注意控制台 GBK，一律 `python -X utf8` 且落盘到 `.scratch/` 再读；书页码（1 基）= pymupdf 页索引 +1。各章页码：§6 77–94、§7 95–107、§8 108–133、§9 134–146、§10 147–168、§11 169–190、§14 234–256、§15 257–277、§16 278–297、§17 298–318、§18 319–332、§19 333–349、§20 350–373、§21 374–391、§22 392–404、§23 405–424、§24 425–457、§25 458–492、§26 493–519、§28 533–558、§29 559–573、§30 574–598。

## 重编号映射（旧→新）

| 旧 | 新 | | 旧 | 新 | | 旧 | 新 |
|---|---|---|---|---|---|---|---|
| 1–8 | 1–8 | | 12 | 14 | | 19–51 | 21–53（+2） |
| **新** | **09** | | 13 | 15 | | **新** | **54** |
| 9 | 10 | | 14 | 16 | | **新** | **55** |
| 10 | 11 | | 15 | 17 | | **新** | **56** |
| 11 | 12 | | 16 | 18 | | **新** | **57** |
| **新** | **13** | | 17 | 19 | | 52–60 | 58–66（+6） |
| | | | 18 | 20 | | | |

插入点：新 09（旧 08 后）、新 13（旧 11 后）、新 54–57（旧 51 后）。篇结构：第二篇 3–12、第三篇 13–20、第四~九篇 +2、**新第十篇 54–57 字节码解释器**、第十一篇 58–64（代码生成与并行）、第十二篇 65–66（收束）。

---

### Task 1: 重编号 60→66（批四十）

**Files:**
- Modify: `docs/NN-*.md` ×59（重写引用+改名）、`examples/NN_*/` ×59、`README.md`、`docs/60-finale.md`→`66-finale.md`
- Create: `.scratch/renumber4.py`（复制 `renumber3.py` 骨架换 MAP）

- [x] 换 MAP 为上表（旧→新 60 项；9/13/54–57 不在 MAP——留给新章）；核对 `rw_paren_range` 的 survey 行守卫与 `"54_finale"` 路径守卫按当前 `60_finale` 实况改为 `66_finale`（renumber3 里有鲸轮遗留的过时守卫，先读 `examples/60_finale/expected/output.txt` 的真实行式再改）
- [x] 跑 `rewrite`（计数多重集一致）→ `rename`（两阶段 git mv）→ 全量三层回归基线 60 章仍绿（此时新章未建、README 暂列 66 目标口径）
- [x] 重建 66_finale 二进制并**重生成 expected**（从新二进制跑出落盘，不手改）；`python .scratch/renumber4.py embed` 全量重嵌；`check_docs` 绿
- [x] Commit: `feat(compiler): 批次四十——60→66 重编号腾位（匠书轮开工）`

### Task 2: 新 09 章 Pratt 分析（批四十一）

**Files:**
- Create: `docs/09-pratt-parsing.md`、`examples/09_pratt_parsing/src/{pratt.hpp,pratt.cpp,llref.hpp,llref.cpp,main.cpp}`、`examples/09_pratt_parsing/expected/output.txt`

**Interfaces:**
- 产出 `struct Expr`（IntLit/Binop/Unary/Call/VarRef/Field/Deref——与 12 章旧 11 的 ast.hpp 同名同形，便于读者对照）、`std::unique_ptr<Expr> parseExpression(Precedence)`、`enum class Precedence { None, Assignment, Equality, Comparison, Term, Factor, Unary, Call, Primary }`（对齐匠书 §6.3.3 的 Prec_ 枚举，幂 `^` 插在 Assignment 与 Equality 之间且右结合）。
- `llref.cpp`：把 06 章 LL(1) 表驱动分析器收窄成可求值的最小副本（同文法），供对账。

**内容**（取材 §6.1–6.3 全 + §17.5 对照，TIP 表达式子集：`+ - * / > == < <= >= !=`、一元 `-`、`*p`、`&x`、调用、字段、`( )`、幂 `^` 教学扩展）：
1. §09.1 递归下降的重复之痛：06 章每层优先级一个函数（`expr/term/factor`），层与结合性都焊死在调用图里；新运算符=新函数+改三处。
2. §09.2 Pratt 循环：token 流上前缀位/中缀位两类回调；`parseExpression(prec)` = 前缀起步 + while(peek 中缀且其 prec ≥ prec) 中缀回调；**结合性由递归层级控制**——左结合中缀回调里递归 `parseExpression(同级)`，右结合 `parseExpression(prec+1)`；匠书 §6.3.4「错把 == 写成右结合」的求值差异演示。
3. §09.3 规则表：`( TokenType → {prefix?, infix?, precedence} )` 一张表；分组/字面量/标识符是前缀；`(` 既是前缀（分组）又给调用当中缀；后缀（调用、字段）= 左结合特例（prec 最高、无右递归再入）。
4. §09.4 三方对比：LL(1) 分层手写（06 章）、LR/LALR 造表（07/08 章，表由构造器从文法算出）、Pratt（表由人写、递归即文法）——工业界为何手写编译器几乎全用 Pratt/递归下降变体；§17.5 clox 版（函数指针表 + `canAssign` 参数）一眼带过为 55 章铺垫。
5. §09.5 陷阱：`-a.b` 前缀回调必须递归进中缀循环；`2^3^2` 右结合；比较链非结合的处理（TIP 按左结合简化，如实说明与 Lox 差异）；`a * -b` 前缀嵌中缀。

**断言**（main.cpp 内嵌语料，简单对账协议，无 ANTLR）：
1. 语料 ≥15 条：算术/比较/一元/括号/调用（内置 `abs`/`input` 桩函数求值器）/幂——Pratt AST 求值与手算期望逐条相等并打印。
2. 与 `llref` LL(1) 对同一交集语料（无 `^`/无字段/无解引用的条目）求值一致，打印对照行。
3. `(2^3)^2 = 64` vs `2^(3^2) = 512`——Pratt 按 `^` 右结合取 512。
4. 故意把 `*` 写成右结合的「坏表」版本跑 `2-3-4` 得 -9（正确左结合为 -5），坏表被检测并打印对照（同一构造两版求值不同）。

- [x] 写 src（Pratt + LL 参考 + 语料）→ 跑通断言 → expected 落盘
- [x] 写正文（五节、全部代码内嵌、期望输出逐行解读、练习）
- [x] 三层对账绿 → Commit: `feat(compiler): 批次四十一——09 Pratt 分析`

### Task 3: 新 13 章 树遍历解释器与环境链（批四十二）

**Files:**
- Create: `docs/13-tree-walk-interp.md`、`examples/13_tree_walk_interp/`（`TIP.g4` 复制自 `examples/12_scopes/`、`src/` 里复制 12 章的 `ast.hpp/ast_build.hpp/ast_build.cpp/symtab.hpp/symtab.cpp` 本地副本 + 新 `interp.hpp/interp.cpp/main.cpp`）、`expected/output.txt`

**Interfaces:**
- `class Environment`（`std::shared_ptr<Environment> enclosing_` + `std::map<std::string,int64_t> values_`；`define/get/assign` 三协议，get/assign 沿链、miss 即抛 `InterpError`）。
- `class Interpreter`（消费 12 章 `Bindings`：先 `resolveNames` 后求值——静态检查先行，求值只走已绑定符号）。
- `struct InterpError { std::string msg; int line; }`；return 非局部退出用 `struct ReturnSignal { int64_t value; }` 异常（正文对比「结果参数层层透传」方案后择异常，理由讲清）。

**内容**（取材 §7 求值协议、§8.1–8.3 环境与赋值、§9 真值与块、§10 函数与闭包与原生函数、§11 语义陷阱四则）：
1. §13.1 第三条执行路：10 章_visitor 与 12 章_绑定已备齐，求值 = 对已解析 AST 的深度优先行走；与 15 章 LLVM（先编译后执行）、16 章 TAC 解释器（先降 IR 再解释）对照——树遍历零变换直接执行。
2. §13.2 环境链：作用域=节点，`define` 先声明后赋值的窗口；取值沿链查找 vs 赋值沿链**写回**（匠书 §8.4 assignment 与 variable 二分：读找定义处、写也找定义处）；块 `{}` 进出即 push/pop；TIP 语义适配（TIP 无 let 初始化器，用 `var x; x = e;` 讲「先声明后初始化窗口」）。
3. §13.3 闭包=定义时环境指针：捕获即共享同一节点（可变状态经链回流——计数器程序逐行推演）；与 53 章（原 51）编译期装箱单对照：那是静态搬家，这是动态共享。
4. §13.4 return 与调用：异常实现非局部退出；调用序列（新环境=globals+参数绑定→执行体→ReturnSignal 捕获）；原生函数（`input`/`abs`）C++ 直调注册在全局环境，与用户函数同形。
5. §13.5 求值前的静态检查（§11 精要四陷阱蒸馏）：(a) `var x; x = x + 1;` 之外匠书原例 `var a = a;` 在 TIP 的对应形态——**声明前使用自己的槽位**（TIP varDecls 先声明后用，把匠书「定义但未初始化」窗口映射成 TIP 的「同一声明组内前向自引用」并在正文讲清两语言差异）；(b) 块级遮蔽合法、同层重复非法（12 章 resolver 已抓，此处补块级一档）；(c) 函数名与变量名绑定次序——名字在不同时刻指向不同实体（TIP 全局函数扁平层 vs Lox 声明即绑定，两口径对比）；(d) return 只在函数体内合法（顶层 return 拒绝）。定位：这是教程主题「静态分析」在真实解释器里的第一个消费者——诊断先于运行。

**断言**（语料内嵌 main.cpp 字符串字面量，经 ANTLR 内存解析；简单对账协议）：
1. 闭包计数器（两层 make-counter 两次 new 各自计数）、递归阶乘 `fact(5)=120`、块遮蔽 `{var x; x=1; {var x; x=2; output x;} output x;}` 输出 2,1、前向引用函数调用——输出与手算期望全等。
2. 与 15 章 LLVM JIT 同语料子集（纯函数无 output 差异部分）对账或手算对账（正文交代）。
3. 四陷阱各一条违规程序：静态检查拒绝、打印诊断行号、**不进入求值**。
4. 赋值沿链写回：内层闭包改外层变量后外层 `output` 读到新值。

- [x] 复制 12 章文件 + 写 interp → UCRT64 壳构建 → 断言 → expected
- [x] 正文（五节、内嵌、期望解读、练习）→ 三层绿 → Commit: `feat(compiler): 批次四十二——13 树遍历解释器与环境链`

### Task 4: 新 54 章 字节码与栈式虚拟机（批四十三）

**Files:**
- Create: `docs/54-bytecode-vm.md`、`examples/54_bytecode_vm/src/{chunk.hpp,chunk.cpp,vm.hpp,vm.cpp,main.cpp}`、`expected/output.txt`

**Interfaces**（55/57 章按此扩展，签名冻结）:
```cpp
enum class Op : uint8_t {
  Constant, Add, Sub, Mul, Div, Gt, Eq, Negate,
  Print, Pop,                       // 栈顶输出/丢弃
  GetLocal, SetLocal,               // u8 槽位操作数
  JumpIfFalse, Jump, Loop,          // u16 偏移操作数
  Call,                             // u8 argc；被调者在栈上函数常量
  CloseUpvalue, Return,
};
struct Value { enum class Tag { Int, Obj } tag; int64_t i; Obj* o; };  // §18 带标签联合起步
struct Chunk { std::vector<uint8_t> code; std::vector<Value> consts; std::vector<int> lines;
               int addConstant(const Value&); };
void disassemble(const Chunk&, std::ostream&);   // 每指令 human-readable + 行号
struct VM { Value run(const Chunk&); };           // 55/57 复制的核心；栈深上限断言
```

**内容**（取材 §14.1–14.4、§15.1–15.5、§18.1–18.2、§24.1–24.4）:
1. §54.1 树遍历的天花板：每节点一次 switch/虚分派、AST 局部性差；把树**编码成线性字节流**——chunk = 操作码流 + 常量池 + 行号表；常量去重查找。
2. §54.2 反汇编即文档：打印每条指令（操作数、常量值、行号）；匠书金句「调试器是你会写的第二个程序」；disasm 输出逐字段讲。
3. §54.3 大循环：`for(;;) switch(op)` FETCH–DECODE–EXECUTE；栈式求值 `Add` 弹二压一（后缀序=求值序，与 54 章前缀/中缀对照）；`Negate` 一元；`Gt/Eq` 比较；`Print/Pop`；DEBUG_TRACE_EXECUTION 打印每步栈（正文用一小段 trace 逐行解读）。
4. §54.4 值：带标签联合 `Value{tag,i,o}`（§18 起步版；预告 56 章 NaN 装箱）。
5. §54.5 调用帧：CallFrame = {函数 chunk 指针、ip、帧基（slots 起点）}；调用序列手推（实参已在栈→记帧基→ip 跳入→Return 弹帧留返回值）；栈溢出保护；原生函数走 C++ 直调旁路（`input` 桩）；帧数=递归深度的账。
6. §54.6 与 16 章 TAC 寄存器机对照：栈机无寄存器名（隐式操作数栈）vs TAC 显式临时变量；指令密度 vs 解码简单性；JVM/CPython/JS 引擎皆栈机的现实。

**断言**（手编字节码程序 ≥4 个内嵌 main.cpp，简单协议，无 ANTLR）:
1. 表达式 `-(3+4)*2` 手编字节码求值 = -14，打印。
2. 反汇编文本与手工推演逐行一致（打印全部指令含操作数与行号）。
3. 阶乘：手编函数 chunk + Call，`fact(5)` 帧数=6（含顶层）断言（VM 内计数器）。
4. 每指令边界栈深 = 手推值（DEBUG 栈深校验数组断言）。

- [x] src（chunk/vm/disasm + 手编程序）→ 断言 → expected → 正文（六节）→ 三层绿
- [x] Commit: `feat(compiler): 批次四十三——54 字节码与栈式虚拟机`

### Task 5: 新 55 章 单遍编译与跳转回填（批四十四）

**Files:**
- Create: `docs/55-single-pass.md`、`examples/55_single_pass/src/{scanner.hpp,scanner.cpp,compiler.hpp,compiler.cpp,vm.hpp,vm.cpp,chunk.hpp,chunk.cpp,main.cpp}`（vm/chunk 为 54 章本地副本 + 新 Op 扩展）、`expected/output.txt`

**Interfaces:**
- scanner：匠书 §16 协议 `advance/peek/match`（即取即用，无 token 缓冲）。
- compiler：Pratt 发码表 `void (Compiler::*)(bool canAssign)`（§17.5 形态）；`emitConstant/addLocal/resolveLocal/emitJump/patchJump/emitLoop`。
- Op 扩展（54 章副本内追加）：`GetGlobal, SetGlobal`（u8 常量池名索引，运行期查 `std::unordered_map<std::string,int64_t>`——56 章升级为手写散列表）；块用 `{}`。
- 语言面：TIP 子集 = 顶层函数 + `var x`/赋值/if/else/while/return/output/算术比较/调用/块。

**内容**（取材 §16、§17.1–17.5、§21、§22.1–22.4、§23.1–23.6）:
1. §55.1 无 AST：扫描+语法+发码一遍完成——与 09–12 章多遍流水线对照表（内存/错误恢复/优化空间三轴）；匠书两解释器架构对照图（jlox 树 vs clox 字节码）在本教程的对应（13 章 vs 54–57 章）。
2. §55.2 即取即用扫描器：`advance/peek/match` 三函数；注释跳过；错误即编译终止（单遍的代价如实讲）。
3. §55.3 Pratt 直接发码：前缀回调发 `Constant/Negate`，中缀回调发 `Add/Gt/...`（弹二压一）；常量去重 `addConstant` 查重；发码序=后缀序=54 章栈求值序（闭环论证）。
4. §55.4 局部变量：进块 `beginScope` 深度+1、出块 `endScope` 弹槽（`Pop` 数）；名字查**编译期局部表**——查到即 `GetLocal/SetLocal` 槽位，查不到落全局；**这就是 12 章 Resolver 的编译版**：静态绑定信息直接变成帧布局（读者已在 12 章见过语义，这里看它如何变成代码）；匠书 §22.4「声明与初始化之间」的窗口：Lox 里 `var a = a;` 要靠额外标记抓，TIP 子集 varDecls 先声明组后语句——两口径差异如实对比。
5. §55.5 全局变量迟绑定：名字进常量池、运行期查表；早绑定（槽位）vs 迟绑定（查表）代价光谱；前向引用函数调用为何只能迟绑定。
6. §55.6 跳转与回填：`emitJump` 发占位 `Jump/JumpIfFalse + u16=0xFFFF`→语句编译完 `patchJump` 回填真实偏移（前向跳转的目标此时才存在）；if/else 双跳转模板、`&&/||` 短路电路（跳转即短路：左值留栈、右值补栈——TIP 无布尔类型的短路用 `&&`→`JumpIfFalse` 直跳 + 保留左值实现，教学扩展如实标注）、while 的 `emitLoop` 向后跳（目标已知直接回填）。

**断言**（内嵌 ≥5 个源程序字符串 → 编译 → 反汇编打印 + VM 执行，简单协议）:
1. 程序输出与手算期望全等（含 if/else、while 累加、函数调用）。
2. 一个代表程序的完整反汇编与正文手工推演逐行一致。
3. 共同语料：与 13 章树遍历同子集程序（print/算术/if/while/函数）双方输出全等（正文引用 13 章语料号）。
4. 短路求值：右操作数含副作用函数调用，短路路径下调用计数=0（VM 内计数器断言）。
5. 嵌套块 `{var x; {var x; ...}}` 编译期槽位峰值=2、出块后复用=1（编译器内计数断言）。

- [x] src（scanner/compiler/vm 副本+扩展）→ 断言 → expected → 正文（六节）→ 三层绿
- [x] Commit: `feat(compiler): 批次四十四——55 单遍编译与跳转回填`

### Task 6: 新 56 章 值表示：NaN 装箱、驻留与散列表（批四十五）

**Files:**
- Create: `docs/56-value-repr.md`、`examples/56_value_repr/src/{value.hpp,value.cpp,table.hpp,table.cpp,main.cpp}`、`expected/output.txt`

**Interfaces:**
```cpp
using Value = uint64_t;
// NaN 装箱：QNaN|sign|全 1 尾数高位 + tag 位（§30 口径，指针 47 位藏低位）
constexpr uint64_t QNAN = 0x7ffc000000000000;
constexpr uint64_t TAG_NIL=7, TAG_FALSE=2, TAG_TRUE=3;   // §30.3.3 实际位值
Value number(double); Value boolean(bool); Value nil(); Value obj(Obj*);
bool isNumber(Value); double asNumber(Value); // ... 往返函数族
struct ObjString { ObjType type; std::string text; };     // §19 起步
struct Table {  // §20 开放定址
  std::vector<Entry> entries;  // Entry{Key key; Value value;} key=nil 表空、key=false 表墓碑
  void set(ObjString*, Value); ObjString* find(const std::string&);
  void deleteKey(ObjString*); bool get(ObjString*, Value*);
  void addAll(Table&); void adjustCapacity(int);
};
uint32_t fnv1a(const std::string&);  // FNV-1a 32 位
```

**内容**（取材 §18.1、§19.1–19.3、§20.1–20.6、§30.1–30.5）:
1. §56.1 值宇宙决定一切：带标签联合 16 字节（tag+double+padding）的内存账；为什么 `Value` 拷贝是解释器最热的路径之一（54 章 VM 的每次 push/pop 都是 Value 拷贝——承上）。
2. §56.2 NaN 装箱：IEEE 754 double 位布局图（符号 1+指数 11+尾数 52）；QNaN 静默位模式：指数全 1+尾数最高位 1 → 尾数还剩 51 位空闲；tag 3 位分 nil/true/false/obj；指针藏尾数低位（47 位指针空间为什么够 x86-64/ARM64——页表上限 48/52 位）；`isNumber = (v & QNAN) != QNAN`；`|1` 合并两布尔位型判 `isBool`（宏二次求值陷阱，C++ 用内联函数天然免疫——两语言对照）；TIP 的 int64 宇宙对照：整数不需装箱（tag 都不用，直存位）——宇宙不同账不同，如实讲。
3. §56.3 ObjString 与驻留：驻留=「值相等 ⇔ 指针相等」；`==` 从逐字符比较退化为一次指针比较（07 章常量去重思想在运行期重现——互参）；驻留池的生命周期问题引出弱引用（预告 20 章 GC 补）。
4. §56.4 开放定址散列表：FNV-1a（位 avalanche、为什么字符串散列不用 `std::hash` 的实现细节差异）；线性探测；**删除必须留墓碑**——真删截断探测链的反例逐格推演；墓碑=nil/false 双空位编码；装填因子 0.75 上限触发扩容；扩容=新表+逐活项重插（墓碑顺带清扫）+ 容量翻倍序列（§20.4 状态机）；`addAll` 给字符串驻留池搬家；与 `std::unordered_map`（链地址法）缓存局部性对照。
5. §56.5 把 55 章的全局表换掉：`std::unordered_map` → 手写 Table 的接入点与实测收益叙事（正文交代，不强制改 55 章示例）。

**断言**（简单协议，无 ANTLR）:
1. 随机 ≥1000 个 double（含特殊值 ±0/±inf/NaN 本身/最接近 QNAN 边界的值）装箱往返 `asNumber(number(d))` 逐位无损（memcmp）；随机指针（假造 47 位内地址）往返无损。
2. 布尔/nil 判定全对；「二次求值」对照：C 宏 `IS_BOOL(v)` 若展开两次的假想例（正文讲），C++ 内联函数单次求值——用带副作用计数器函数证明只调一次。
3. 驻留：两个内容相同、地址不同的字符串经 intern 后指针相同；不同内容不共享。
4. 散列表语义：插入 N=200 项后逐一 get 全中；删除一半后剩余仍全中（墓碑生效）；重插被删键成功（墓碑可复用探测链）；扩容触发后墓碑清零（表内 key=false 计数=0）。
5. FNV-1a 已知向量：`""→0x811c9dc5`、`"a"→0xe40c292c` 等标准测试值对账。

- [x] src（value/table + 断言）→ expected → 正文（五节）→ 三层绿
- [x] Commit: `feat(compiler): 批次四十五——56 值表示：NaN 装箱与驻留`

### Task 7: 新 57 章 上值：虚拟机里的闭包（批四十六）

**Files:**
- Create: `docs/57-upvalues.md`、`examples/57_upvalues/src/{scanner.hpp,scanner.cpp,compiler.hpp,compiler.cpp,vm.hpp,vm.cpp,chunk.hpp,chunk.cpp,main.cpp}`（55 章全套本地副本 + 扩展）、`expected/output.txt`

**Interfaces:**
- Op 扩展：`Closure`（u8 常量池函数 + 捕获表 upvalueCount×(isLocal:1,index:7) 编码——§25.4 字节格式）、`GetUpvalue/SetUpvalue`（u8 上值索引）、`CloseUpvalue`。
- `struct ObjUpvalue { uint8_t* location; Value closed; }`——开放时 location 指栈槽地址，关闭后 location 指自身 `closed` 字段（匠书原技巧，正文讲透「指针改指自己家」）。
- VM 持 `std::vector<ObjUpvalue*> openUpvalues`（按栈地址降序插入维护，捕获先查链：同槽位已开放则复用——两个闭包共享同一 upvalue）。
- `captureUpvalue(uint8_t* slot)` / `closeUpvalues(uint8_t* last)`（栈收缩到 last 之上全部关闭）。

**内容**（取材 §25.1–25.8）:
1. §57.1 帧没了，变量还在：13 章闭包=环境指针（整链保留）、53 章闭包转换=编译期装箱单——都「整变量/整环境」保留；54/55 章的局部变量住**栈帧**里，函数返回帧即回收——逃逸闭包读谁？方案光谱三档表。
2. §57.2 上值=单变量粒度的运行期捕获：`ObjUpvalue` 开放（指栈槽）/关闭（自持盒子）两态；捕获时 VM 查开放链（同槽复用→共享语义）；**close 时机**：`endScope`/函数返回把栈收缩到界，界上所有开放上值关闭——值搬进盒子、指针改指盒子（这一步的指针改写逐行讲）。
3. §57.3 编译器配合：函数对象里嵌套函数时，局部变量解析失败的查找次序 = 本函数局部 → 外层**上值表**（编译期递归 markInitializers 链）→ 全局；`Closure` 指令捕获表编码；两个函数捕同一外层变量共享同一 upvalue 索引空间各自独立。
4. §57.4 关键反例：循环体建 N 个闭包——Lox 里循环体是新作用域每次迭代新槽位（各捕各的）vs 把捕获提到循环外（共享一个）；TIP 子集 while 无块级迭代作用域（如实讲两语言差异，用「循环内显式块」构造出「各捕各的」形态）。
5. §57.5 四方对照收束：环境链（13，整链共享）/访问链 display（19 章，帧上链，帧没了就没了——为什么不适用）/闭包转换装箱单（53 章，编译期静态）/上值（本章，运行期按需）——四行对照表 + 各自代价。

**断言**（内嵌闭包语料 ≥6 程序，简单协议）:
1. 逃逸闭包计数器：`make-counter` 返回的函数跨 ≥3 次调用累加 0→1→2→3（帧已回收仍正确）。
2. 共同语料与 13 章树遍历全等（计数器、加法器工厂、嵌套捕获 x+y+z 三层）。
3. 循环内块作用域建 3 个闭包各捕各的：输出 0,1,2（不是 3,3,3）——反例裁决。
4. 同一变量被两个闭包捕获：一写一读共享（输出证明共享同一 upvalue）。
5. 结构断言：close 后 openUpvalues 链表为空（VM 内校验打印）；开放期间两闭包的 upvalue 指针相同（共享）。

- [ ] src（55 副本+扩展）→ 断言 → expected → 正文（五节）→ 三层绿
- [ ] Commit: `feat(compiler): 批次四十六——57 上值与闭包`

### Task 8: 20 章 GC 补三色抽象与弱引用（批四十七）

**Files:**
- Modify: `examples/20_garbage_collection/src/{heap.hpp,heap.cpp,main.cpp}` + `docs/20-garbage-collection.md`（新增三节：三色抽象、弱引用与字符串池、LISP2 压紧 + 分代假设注记；embed 重生成）

**内容**（取材 §26.1–26.4 + 书末练习/设计注记）:
1. 三色抽象：白/灰/黑、三色不变式「黑不指白」；把现有标记清除改写成灰集工作列表的**模拟器**（逐步打印颜色账）；不变式在每步保持、终态无灰断言；为什么增量 GC 靠它（文字，为将来分批标记留门）。
2. 弱引用与字符串池：驻留池是缓存不是语义——GC 根集**不含**驻留池；标记后清扫前清弱表：死串从池中摘除（断言：池里只剩活串）；强根误当弱表=字符串永不回收的泄漏账。
3. LISP2 三指针压紧（练习引申、自包含讲清）：标记→first/last/free 三指针滑动重排活对象→改写全部引用→地址单调递增；碎片账：压紧前空闲块数 vs 压紧后恰 1 块。
4. 分代假设设计注记（文字）：幼年死亡率、nursery/晋升/双收集器；与教程 Cheney 复制（18 章=新 20）的亲缘。

**断言**（追加进现有 main，expected 重生成）: (1) 三色模拟每步不变式保持（程序内校验+打印摘要行）；(2) 驻留池弱清理后死串不在池中、内存回收数正确；(3) LISP2 压紧后所有引用改写正确（间接读全对）+ 活对象地址单调 + 空闲块从 k→1。
- [ ] 改 src → 重建 → 新 expected → `renumber4.py embed` 重嵌该章 → check_docs 绿 → Commit: `feat(compiler): 批次四十七——20 补三色抽象与弱引用`

### Task 9: 52 章对象补方法即闭包（批四十八）

**Files:**
- Modify: `examples/52_objects/src/{objmodel.hpp,objmodel.cpp,main.cpp}` + `docs/52-objects.md`（新增两节：方法即闭包与 this 捕获、super 链式查找；embed 重生成）

**内容**（取材 §28.1–28.4、§29.1–29.6）:
1. bound method：字段访问返回「闭包」（方法函数 + 捕获 this 槽）；存进变量延迟调用 this 不丢；与「每次调用动态查字典」的对照（绑定一次 vs 每次查找）。
2. this 捕获与逃逸检测：this 即方法体的隐式第 0 上值（互参 57 章——匠书正是用上值实现 this）；顶层出现 this 的静态拒绝（一条诊断）。
3. super 链式查找：先沿超类链找方法定义、再用**当前接收者**绑定 this（super 不是「换个 this」——匠书经典澄清）；类字典派发（方法表在类对象上，实例只存字段）vs 教程 52 章前缀法 vtable 的取舍表（扁平快 vs 灵活可增）；init() 构造表达式必返实例（返回值拦截）。

**断言**: (1) bound method 延迟调用 this 正确；(2) 嵌套继承三层 super 调用解析到正确祖先方法且 this 是最内接收者；(3) 顶层 this 被静态拒绝带行号；(4) init 内 return 值被拦截、构造表达式恒返实例。
- [ ] 改 src → 重建 → 新 expected → embed 重嵌 → check_docs 绿 → Commit: `feat(compiler): 批次四十八——52 补方法即闭包与 super 链`

### Task 10: 收官（66/66，批四十九）

**Files:**
- Modify: `examples/66_finale/src/survey.cpp` + expected（survey 扩 6 行：Pratt/树遍历/字节码 VM/单遍编译/值表示/上值——若 6 新家族可归并为 4 行家族口径，按 survey 现有行式定，读 `66-finale` 现状后定稿）、`docs/66-finale.md`（内嵌重生成、每章一句话 66 句、口径 60→66、延伸阅读补匠书）、`README.md`（五书口径：SPA 骨架 + 绿龙/紫龙/虎/鲸/匠、十二篇导航、验证状态 66/66）
- Modify: 记忆 `G:\xulun\.claude\projects\G--code-guide\memory\compiler-tutorial-build.md` + `MEMORY.md`（匠书轮结构、批次、新坑）

- [ ] survey 扩行 + expected 从新二进制重生成 + embed 全量重嵌
- [ ] 每章一句话 66 句、README 五书十二篇定稿
- [ ] 全量三层回归 66/66 exit 0（`bash run-all.sh`）
- [ ] Commit: `feat(compiler): 批次四十九——66 章收官更新与 README 定稿（匠书扩充完成）`
- [ ] 更新记忆文件与 MEMORY.md 索引

## Self-Review

- **覆盖**：spec 六新章（09/13/54/55/56/57）各有任务；两补充（20 GC、52 objects）各有任务；收官（survey/finale/README/记忆）在 Task 10。spec 的机器证人总设计落在 Task 3(断言2)、Task 5(断言3)、Task 7(断言2) 三处跨解释器对账。
- **占位符**：无 TBD；每任务给出内容节纲、接口签名与断言设计。
- **类型一致**：Op 枚举/Chunk/VM/disassemble 签名在 Task 4 冻结，Task 5/7 声明「本地副本+扩展」并列出追加 Op；Value 语义在 Task 6 独立成章（54 章带标签联合起步版 ≠ 56 章装箱版，两版差异正文交代）。
- **依赖次序**：Task 1 重编号先行；Task 2/3/6 独立可并行；Task 4→5→7 依赖链（55/57 复制 54）；Task 8/9 依赖 Task 1 的重编号（20/52 新号）。
