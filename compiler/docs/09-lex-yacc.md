# 第 9 章　Lex 与 Yacc 的心脏：值栈与生成器时代

前端走到这里，我们手里已经有三种解析器：递归下降手写函数（第 6 章 LL(1)、第 11 章 Pratt）、ANTLR 从文法生成的递归下降（第 4 章）、以及 LR 家族的表驱动（第 7、8 章）。但工业史上还有一条同样重要的谱系我们没有碰过：**Unix 的生成器两件套 lex 与 yacc**——1975 年贝尔实验室 Mike Lesk 的 lex 与 Stephen Johnson 的 yacc。它们是第一批"写文法、得前端"的工具，此后四十多年的 flex/bison/byacc 是它们的直系后代，ANSI C 的第一个参考实现、Perl、Ruby、PostgreSQL 的解析器都出自这条线。

本章以 Louden《编译原理及实践》§2.6（Lex）与 §5.4–5.5（Yacc）为取材，做一件与第 4 章互补的事：**把两个生成器的"心脏"亲手写出来**——不是调用它们（本机工具链里也没有 bison/flex），而是把它们的机制实现到能跑、能对账的程度。yacc 的心脏是一句话：**在 LR 分析的状态栈旁边再放一条值栈，让"归约"这个机械动作顺带完成"计算"**。这句话展开成三件事——%union（值栈元素的类型）、`$$`/`$n` 伪变量（归约时读写值栈）、优先级声明（给冲突投票）。理解了这三件事，再看 bison 语法文件，你会发现它没有任何魔法。

与前几章的关系：词法引擎直接复用第 5 章的多模式 Scanner（它本来就是 Lex 心脏的 DFA 版），LALR 造表直接复用第 8 章的构造器（它本来就是 yacc 造表算法的教学版）。本章的新代码只有三个文件：值栈驱动器（yacc.*）、把它用起来的计算器（demo.*）、驱动与对账（main.cpp）。复用遵循第 15 章开先例的"按需裁剪"副本制：删掉本章用不到的整块（Brzozowski 最小化、SLR 支路）、导出 goTo 供仲裁器用——留下的行与原章逐字相同，裁剪清单在 §9.7.6。

**本章示例：`examples/09_lex_yacc`（无 ANTLR，纯手写机器）**

阅读地图（按需取用）：

- 只想知道 bison 语法文件怎么读 → §9.2.1、§9.3.1、§9.4、§9.6（约半小时）。
- 想吃透值栈机制 → §9.3 全节 + §9.7.2 的对账设计。
- 想理解优先级声明为什么是语义 → §9.6 全节 + §9.7.3 的 S6 段逐行解读。
- 想看"改写"这种工程手法的原型 → §9.5（嵌入动作）连读 §9.5.4 的机制论证。
- 想吸取前人踩坑经验 → §9.7.5 的五坑复盘（全部真实发生）。

## 9.0　本章要解决的问题与位置

先回答"为什么现在学这个"。三个理由。

第一，**谱系完整性**。本教程的前端线到此覆盖了手写与生成器两大阵营，但生成器阵营内部又分两代：

- 自底向上的一代（yacc/bison，LALR 表 + 值栈），1975 年起；
- 自顶向下的一代（ANTLR 2 时代的 LL(k) 到 ANTLR 4 的 ALL(*)，递归下降 + 树重建），1989 年起。

两代的机制差异不在"谁造表"（都造表），而在**语义动作挂在哪个事件上**：

- yacc 的动作只在归约时执行——右部完整才动手，天然后缀序；
- ANTLR 的监听器/访问者在进入/退出规则时执行——可以前缀动手。

这个差异向下辐射到三个层面：

- 文法写法：yacc 偏爱左递归（栈深线性）、ANTLR 必须右递归（LL 限制）；
- 动作位置：yacc 的动作天然在"句柄归齐"处、ANTLR 两头都能挂；
- 错误恢复：yacc 有 error 记号（第 10 章主场）、ANTLR 走错误监听器。

不懂值栈，就无法真正理解这个分野——"归约时执行"四个字，一半的重量在值栈上。

第二，**值栈本身是重要数据结构课**。"一条栈管控制流（状态）、一条栈管数据流（值）"的平行结构，会在后面的运行时篇以另一种形态重现——活动记录里的控制链与数据链。归约时"弹 n 个压 1 个"的模式，就是函数调用"弹实参压返回值"的静态预演。第 9.3 节与第 9.3.6 节把这个对应讲透。

第三，**冲突仲裁是文法工程的实战课**。第 7 章见过 shift/reduce 冲突与 prefer-shift 缺省，第 8 章见过 lookahead 精确化如何消掉 SLR 的假冲突。但真实文法（表达式、悬空 else、一元负号）的冲突往往不是靠改文法解决的，而是靠**优先级与结合性声明**——告诉生成器"这个冲突投票给谁"。这是 yacc 家族四十年沉淀出的工程约定，本章把它完整实现并做翻转实验：同一份文法，改一行声明，`-3^2` 从 -9 变成 9。**优先级声明是语言语义的一部分**，这句话只有亲手翻过才信。

位置上，本章是第二篇"前端的原理"的中坚：第 9 章（本章）补齐生成器谱系，第 10 章讲这条谱系最弱的环节（错误恢复），第 11/12 章回到 AST 与遍历。学完本章你应当能：

1. 读懂任意一份 bison 语法文件（%union、%type、$$/$n、%left/%right/%prec、error 记号的预告）；
2. 说清值栈与状态栈的平行不变式，以及归约五步里每一步动的是哪条栈；
3. 对一个 shift/reduce 冲突，按 yacc 规则裁决出胜负并说出理由；
4. 解释嵌入动作为什么必须改写成空产生式，改写后 $n 编号怎么变；
5. 列出 lex 的两条仲裁法（最长匹配、先声明优先）并各给一个可观察的实验。

## 9.1　1975 年的两件套：族谱与世代对照

### 9.1.0　族谱时间线（一分钟版）

- 1970 年前后：Alloy→…，贝尔实验室内部一堆 compiler-compiler 试验互相竞争。
- 1973 年：Stephen Johnson 写出 yacc（Yet Another Compiler-Compiler——这个名字就是那次内卷的自嘲）。
- 1975 年：Mike Lesk 写出 lex；两者以 `yylval`/`yylex` 接口配对，前端两件套成形。
- 1975–1978：yacc 被 Johnson 本人用来做可移植 C 编译器，逼出 LALR 优化与优先级声明——工具与用户互相塑造的第一案例。
- 1985 年：GNU bison 立项（R. Corbett），yacc 语法兼容、内部算法重写（后改用更现代的项集压缩）；Berkeley byacc 是另一支后裔。
- 1987 年：flex（V. Paxson）取代 lex，等价类压缩 + 直接 DFA 合成，快一个数量级。
- 1989–1992：Terence Parr 的 ANTLR（PCCTS）开启自顶向下生成器世代，动作挂进入/退出事件、树是第一公民。
- 2013 年：ANTLR 4 的 ALL(*) 把 LL 分析的适应力推到实践上限；同世代 re2c 把"词法生成"做成代码内嵌风格。
- 今天：bison 仍服役于 Ruby、PostgreSQL、PHP、GNU grep 之外的多数 GNU 工具链；gcc/clang 的前端则是大规模手写递归下降（第 9.8 节谈为什么）。

这条时间线的主旋律：**yacc 定下的接口契约（文法 + 动作 + 值栈 + 冲突声明）四十年没换过骨架**——后来者换的是分析算法与工程包装，不是这份契约。

### 9.1.1　它们解决的是"造表贵"的时代问题

1970 年代早期，写一个前端意味着手写几百页的转换表。Stephen Johnson 的 yacc（Yet Another Compiler-Compiler，这个名字本身就是贝尔实验室内部一堆 compiler-compiler 试验的自嘲）把这件事倒过来：**程序员写文法和语义动作，机器造表**。Lesk 的 lex 把词法也如法炮制：**写正则，得扫描器**。两件套的分工恰好对应编译器前端的两个阶段：

```text
源程序 ──lex──> token 流 ──yacc──> 归约序（动作在此执行）──> 结果/AST
         正则规则          文法规则 + 动作
```

这个分工有一个隐含的**接口契约**：lex 每识别一个 token，就把它的"词义"写进一个全局变量 `yylval`，然后返回 token 种类号；yacc 拿到种类号查表驱动，归约时通过 `$n` 读 `yylval` 留下的值。一个写、一个读，中间没有任何其他通信——这是 Unix 工具哲学（窄接口、管道化）在前端的体现。本章的 MiniLex/MiniYacc 严格遵守这个契约：`MiniLex::scan` 产出 `LexTok{kind, text}`，`MiniYacc::parse` 移进时把 NUM 的文本转成数值压入值栈——这就是 yylval 的填充点。

### 9.1.2　两代生成器的分野

| 维度 | yacc/bison 一代（1975–） | ANTLR 一代（1989–） |
|---|---|---|
| 分析算法 | LALR(1)，自底向上 | LL(k) → ALL(*)，自顶向下 |
| 表的形态 | 二维 action/goto 大表 | 递归函数 + 预测决策 |
| 动作时机 | **只在归约时**执行 | 进入/退出规则时执行（监听器） |
| 文法口味 | 偏爱左递归（栈深线性） | 偏爱右递归（LL 限制） |
| 值的传递 | 值栈 + `$$`/`$n` | 规则参数/返回值、树的遍历 |
| 冲突处理 | 优先级声明 + error 记号 | 改文法或语义判定 |
| 代表用户 | C、Perl、Ruby、PostgreSQL、PHP | Hive、Spark SQL、SQLite(手写LL)邻域 |

表中每一行都值得展开，但先抓住最核心的一行：**动作时机**。自底向上分析里，唯一"知道一条产生式已经完整匹配"的时刻就是归约——圆点走到底、右部全在栈上。所以 yacc 把动作挂在这里：`expr : expr '+' expr { $$ = $1 + $3; }`，弹三个值、算一个值、压回去。而自顶向下分析在"进入规则"时就知道要用哪条产生式，动作可以放在规则开头（继承属性可用），也能在结尾收尾（综合属性）。这就是为什么 yacc 家族天然适合 **S-属性文法**（第 13 章的术语：只用综合属性），而继承属性在 yacc 里要靠中绵规则或栈内窥视的技巧——一个我们用"嵌入动作"（§9.5）部分绕开的限制。

其余各行的注解（每行背后都有一段工业史）：

- **表形态**：yacc 的二维大表在 16 位机时代是内存怪兽（bison 后来用行压缩与默认项省掉大半）；ANTLR 的"表"其实是生成出来的 switch 树——形态差异决定部署差异（表可序列化、switch 可编译期优化）。
- **文法口味**：左递归禁令是 LL 的数学限制（第 6 章 6.4 节的推导），不是风格偏好——ANTLR 4 的 ALL(*) 解除了大部分直接左递归禁令，但间接左递归仍非法。
- **值的传递**：值栈是"隐式的、由机器管"的通道；ANTLR 4 干脆不传值、直接给树（parse tree 是一等公民，监听器按需访问）——**两代工具对"中间产物"的哲学不同**：yacc 认为值是过客、树是要另造的；ANTLR 认为树就是主产物。
- **错误恢复**：yacc 的 error 记号是文法层的（错误也是语法的一部分）；ANTLR 的恢复是策略层的（监听器回调）——第 10 章整章就在这个差异上展开。
- **代表用户**一行的潜台词：两代都有巨头背书，**没有失败者**——选型看需求（控制力 vs 生产力），不看新旧。

还有一行值得先记下：**文法口味**。yacc 偏爱左递归，因为 `expr → expr + term` 让长表达式在栈上滚雪球归约，状态栈深度保持线性；而 LL 分析见左递归即死锁（第 6 章 6.4 节），必须消除成右递归。本章 demo 文法全部用左递归写成，就是这个口味——你会在 §9.7 的归约日志里看到它"边读边算"的节奏：`2+3*4` 读到 `4` 就地归约 `expr→NUM`，读到 `*` 先吞进来，随后 `3*4` 归约、再 `2+(3*4)` 归约，全程状态栈不超过几个格子。

### 9.1.3　本章的实现策略

不安装 bison/flex（教学自包含，也不污染工具链），而是**手写两个生成器的心脏**：

1. **Lex 心脏**：第 5 章的多模式 Scanner——规则表并联进一个 NFA、子集构造带规则号着色、最长匹配、同长先声明优先——本来就是 lex 的机制内核。本章零改动复用（文件级副本），只在外面套一层把 `"NUM('42')"` 风格的产物拆成结构化 token 的薄壳。
2. **Yacc 心脏**：第 8 章的 LALR(1) 造表器也是 yacc 造表算法的教学版。本章在它上面新写一个**值栈驱动器**：状态栈旁边平行推进一条值栈，归约时执行动作。加上优先级仲裁器（重算冲突格的两个候选、按 yacc 规则投票）与嵌入动作改写器（把 `A → a {动作} b` 展开成空产生式）。

复用文件与原章的差异是"裁剪 + 一处导出"：删 Brzozowski 最小化块与 SLR 支路（本章不走这两条路线，原章仍完整讲述）；lr1.hpp/lr1.cpp 把 `goTo` 移出匿名命名空间并声明（仲裁器要重算移进候选，08 章原版把它藏起来）。改动的注释写明缘由，读者拿原章全文与本章副本 diff，只见删除块与边界注释——留下的代码逐字相同（清单见 §9.7.6）。

## 9.2　Lex 的心脏：规则表、最长匹配、先声明优先

### 9.2.1　规格文件的三段式

lex 的输入文件分成三段，段间用 `%%` 分隔：

```text
[定义段]   名字与正则的缩写、C 代码注入（%{ ... %}）
%%
[规则段]   模式1  动作1
           模式2  动作2
%%
[用户段]   main() 等——扫描器的宿主程序
```

三段各自的职责与本章对应物：

- 定义段：宏替换（`digit [0-9]`）与 C 代码注入——对应 demo.cpp 里 `altChars` 生成的两条"类"字符串与 `kLetters/kDigits` 常量；
- 规则段：模式-动作对——对应 `calcLexRules()` 的 15 条 `TokenRule`（名字段即动作里的 `return` 值）；
- 用户段：宿主程序——对应 main.cpp 的驱动（flex 生成 `yylex()`，用户写调用它的循环）。

规则段是心脏。每条规则是"正则 → C 语句"，动作里能用的最重要的变量族：

- `yytext`：刚匹配到的原文（本章 LexTok.text）；
- `yyleng`：其长度（本章 text.size()）；
- `yylineno`：行号（本章 LexTok 预留的 line 字段，第 10 章启用）；
- `yylval`：传给 yacc 的值槽（本章在 MiniYacc 移进时填充，§9.3.4）。

一条典型规则长这样：

```c
[0-9]+   { yylval.num = atoi(yytext); return NUM; }
```

读法：方括号是字符类糖、花括号是动作、return 的 NUM 是 token 种类号。对照本章机器：字符类糖 → `altChars` 展开；动作 → 移进时的 ofNum(stod(text))；种类号 → LexTok.kind。**一行 lex 规则在本章机器里散落成三处**——这不是本章机器的劣势，而是把"糖压进机器"的解压过程本身当成了教学。

定义段的缩写只是文本替换糖——第 5 章迷你正则连字符类都没有，一切展开成 `(0|1|...|9)` 的原形。demo 的 `altChars` 专门干这个展开，读者可以对照体会"糖与核心"的差距：lex 的 `[0-9]+` 是糖，`(0|1|…|9)(0|1|…|9)*` 是它去掉糖以后喂给 Thompson 构造的东西。

两个 lex 的进阶特性本章刻意不碰、但要点名（它们是真实词法的主力）：

- **起始状态**（`%s COMMENT` + `BEGIN COMMENT`）：同一台 DFA 换起点——C 注释、字符串字面量、内插表达式各配一个起点，动作里切换。本章单一起点够用；第 12 章 TIP 前端的 ANTLR 版用词法模式（lexer modes）实现同一思想。
- **最长匹配的例外**：`.`（任意字符）规则与 C 注释规则并存时，`/*` 必须赢过 `/`——长度法自然处理；但 `a/*b` 里 ID `a` 与注释的边界要靠**规则不可重叠**保证。词法设计的隐形约束：**规则集对任何输入前缀的"最长可匹配"必须唯一可判定**。

### 9.2.2　两条仲裁法：最长匹配与先声明优先

扫描器面对输入 `a<=b` 时，`<` 规则和 `<=` 规则都能匹配起点：怎么办？lex 的仲裁法只有两条，恰好是第 5 章 Scanner 的实现口径：

1. **最长匹配（maximal munch）**：能吃多长吃多长，`<=` 长 2，赢。
2. **同长先声明优先**：`print` 既匹配关键字规则 `print` 又匹配标识符规则 `[a-z]+`——长度同为 5，谁写在规则表前面谁赢。所以关键字必须声明在 ID 之前。

这两条法则是**词法定义的一部分**：C 语言里 `x+++y` 必须切成 `x ++ + y`（最长匹配），Pascal 里 `until` 不是标识符（先声明）。它们不是实现选择，是语言规格——第 5 章用 DFA 的优先级着色实现了它们，本章直接验证：把规则表里 `print` 与 `ID` 的声明顺序对调，同一个词 `print` 的种类号就变（§9.7 期望输出的两组对照行）。

### 9.1.4　本章 demo 的 bison 真身对照

本章机器与真实 bison 的距离，最直观的量法是把 demo 翻译成一份**真的能喂给 bison 的 .y 文件**，逐行对照。翻译件（演示用，未纳入示例构建——读者可在任何装有 bison 的机器上验证）：

```bison
%union   { double num; char *str; }        /* 对应 YaccValue 的两个字段 */
%token <str> ID
%token <num> NUM
%token PRINT LPAREN RPAREN '=' ';' '+' '-' '*' '/' '^'
%type  <num> expr
%left  '+' '-'                              /* 级 1，左结合 */
%left  '*' '/'                              /* 级 2，左结合 */
%right '^'                                  /* 级 3，右结合 */
%precedence UMINUS                          /* 伪终结符，只给 %prec 用 */
%%
prog  : prog stmt
      | stmt
      ;
stmt  : ID '=' expr ';'      { vars[$1] = $3; }              /* $1 取 str 槽 */
      | PRINT expr ';'       { printf("%g\n", $2); }
      ;
expr  : expr '+' expr        { $$ = $1 + $3; }
      | expr '-' expr        { $$ = $1 - $3; }
      | expr '*' expr        { $$ = $1 * $3; }
      | expr '/' expr        { $$ = $1 / $3; }
      | expr '^' expr        { $$ = pow($1, $3); }
      | '-' expr  %prec UMINUS { $$ = -$2; }                 /* 规则 10 的对应物 */
      | LPAREN expr RPAREN   { $$ = $2; }                    /* 不是 $$=$1！ */
      | NUM                  { $$ = $1; }                    /* 可省略：缺省即 $1 */
      | ID                   { $$ = vars[$1]; }
      ;
%%
```

逐行对照本章机器的对应物：

- `%union` ↔ `YaccValue` 的 Tag + 双字段（§9.4.1）；
- `%token <str> ID` ↔ 移进时 `ofStr(text)` 压值栈（§9.3.4 第 2 点）——`<str>` 就是标签登记；
- `%left/%right/%precedence` ↔ `setPrec(term, level, assoc)` 与 `rulePrec`（§9.6.2）——注意 bison 里**声明顺序即级差**（先写的级低），本章用显式整数级，语义相同、可读性各有千秋；
- `%prec UMINUS` ↔ `YaccRule.rulePrec`——给"最右符号是非终结符"的产生式补优先级的同一机制；
- 动作里的 `$1/$3/$$` ↔ `vals[0]/vals[2]` 与返回值——**bison 的 $n 是 1 基、C++ 向量是 0 基**，差一要牢记；
- `prog : prog stmt` 的左递归原样保留——bison 与本章机器同口味；
- `NUM` 规则的动作 `{ $$ = $1; }` 可以整行删掉——缺省行为就是它，写出来是为了与"括号规则必须写 `$2`"并排展示（§9.4.2）。

翻译件的语义与本章机器**逐语料等价**：§9.7 的 18 条求值、四组翻转，在有 bison 的机器上跑这份 .y 应当得到同一串输出（`%g` 与本章 `fmt` 的六位有效数字口径一致）。"教学机器与工业工具行为等价"——这是本章机器可信度的最终背书。

### 9.2.2a　仲裁法细则与边界情形

两条法则陈述起来一句话，边界情形却有四条值得点名：

- **前缀词的切分**：`<e1` 里 `<` 与 `<e1`（不存在）之争不存在——ID 规则不收 `<`，所以贪心走到 `e` 就断。但 `x<=y` 与 `x< =y` 不同：后者 `<` 与 `=` 之间有空格，切成两个 token。**空白是词法的硬边界**，规则里的并置连接从不跨空白。
- **关键字与标识符的边界即声明序**：`printx` 不是关键字（最长匹配给了 ID）；`print_x` 呢——ID 规则收下划线，同样最长匹配判 ID。**"以关键字开头的更长词"永远赢**，除非另有关键字规则。
- **错误字符的策略分歧**：迷你版输出 ERR 并前进一格；flex 缺省 ECHO 回显。两种策略都"不崩"，差别在**静默与否**——编译器前端的词法层通常要立即报错（第 10 章把词法错误并入恢复框架）。
- **回退的代价**：最长匹配的"回退到最后接受点"在 C 风格注释 `/* ... *` 尾部会回退很深吗？不会——回退只发生在**当前 token 内部**（每步都记录最后接受），跨 token 从不回退。yyless(n) 是 flex 给动作回吐的口子，迷你版用不到。

### 9.2.3　复用第 5 章的机器

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

第 5 章的这份接口本章用到的成员逐一对应 lex 概念：`TokenRule{name, pat}` 是规则行的"模式"半边（name 就是动作里 `return NUM` 的种类号）；`parseRE/thompson/subset` 是 lex 内部把正则编译成 DFA 的流水线；`Scanner` 是编译产物加主扫描循环。注意 `subset` 的 `stateClass` 参数——它给每个 NFA 接受态染上"所属规则号"，子集构造取集合内最小规则号（最高优先级）作为 DFA 态颜色。**这个"取最小"就是"先声明优先"在自动机层的实现**；而最长匹配住在 `Scanner::lex` 的主循环里——每步都记录"最后一个接受态"，转移失败时回退到它：

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

走读要点（对照第 5 章 5.6 节的完整讲解，这里只提本章视角的新观察）：

1. `Scanner::lex` 的主循环里 `lastAcc/lastColor` 就是"最长匹配"的全部实现——先贪心走到走不动，再退回最后一个接受点。如果没有任何接受点（`lastAcc == npos`），输出 `ERR('c')` 并前进一格：lex 对应的缺省动作是"ECHO"（原样吐出），教学版选择显式报错，语义更严格。
2. `Scanner` 构造器把 N 条规则的 NFA 用**平衡树式 ε 分叉**并联成一个新起点——因为 Thompson 构造保证每状态至多两条出边（第 5 章的形状约定），N 路分叉要搭 log 层。lex 真实实现（flex）用等价类的 DFA 直接合成，形状不同但语义相同。
3. `minimize(subset(...))` 的最小化以 `color` 分割——不同优先级的接受态即使行为相同也不合并。这是**词法优先级住进自动机**的又一处体现：最小化必须保守地保留规则身份。

#### 9.2.3a　re.cpp 逐段走读：从模式串到 DFA 的四段旅程

裁剪后的 441 行副本在第 5 章有过完整的逐行讲解，这里按"Lex 视角"重走一遍——每个部件在 lex 这台机器里扮演什么角色。四段旅程：RE 解析器、Thompson 构造、子集构造与最小化、多模式 Scanner。

**第一段：`REParser` 与 `parseRE`——模式串的语法分析器**（文件头至 ~105 行）。

- lex 规则段里每个"模式"是一段正则文本；任何实现的第一件事都是把它解析成结构。
- 迷你正则五种节点：Eps/Sym/Alt/Concat/Star——教科书子集，足够描述 demo 的全部 token。
- 解析文法三层：`expr → term ('|' term)*`、`term → factor factor*`、`factor → atom '*'?`——**优先级住在文法层级里**（星高于并置、并置高于择一）。
- 自举时刻：解析"正则表达式"本身就是一次表达式分析——用第 6 章的知识理解第 9 章的工具输入，这在教程结构上不是巧合而是必然。
- 诊断 `fail` 带位置号：`regex 位置 1: 缺右括号`——本章开发真实撞过的报错（坑一的现场，§9.7.5）。
- 转义分支是规则表的刚需：运算符 token 的模式就是元字符本身，`\(`、`\*` 靠它回到字面量世界。

**第二段：`thompson`——语法树到 NFA 的归纳构造**（~106–210 行）。

- 四个 case 严格按归纳定义走：Sym 两态一边；Alt 加 ε 分叉；Star 造环；Concat 出口 ε 直连入口。
- 每个部件维持"单一入口、单一出口、入口无入边、出口无出边"四不变式——归纳证明能成立的形状基础（第 5 章 5.4 节的完整论证）。
- 本章视角的新话：**lex 并联 N 条规则用的还是同一个 Alt 操作**（见第四段）——规则表在自动机层就是一个巨大的择一表达式 `rule1 | rule2 | ... | ruleN`。
- lex 语法上分了 N 行规则，自动机上是一家人——这是"语法糖与语义核心"在词法层的具体形状。

**第三段：`subset` 与 `minimize`——确定化与化简**（~211–380 行）。

- 子集构造的三件套：ε-闭包、按字符转移、注册新状态——教科书内容（第 5 章 5.4 节）。
- 本章真正要盯的是 `stateClass` 参数的流动：
  - 调用方（Scanner 构造器）给每个 NFA 接受态染"规则号 + 1"；
  - 子集构造生成每个 DFA 态时取集合内**最小非零类号**作为该态颜色；
  - "取最小" = **先声明优先**在自动机层的全部实现。
- 最小化的初试分割按颜色分组：颜色不同的接受态**永不合并**——优先级住进了等价类结构，连化简都绕不开它。
- 副本裁掉了 Brzozowski 最小化（逆转两次的那条路线）：它是第 5 章 5.5 节的主角，本章只用分割式，裁剪清单见 §9.7.6。

**第四段：`Scanner`——并联、着色、扫描循环**（~381 行至末尾）。

- 构造器三步：N 条规则各自 thompson → 逐个搬进大自动机改相对编号 → 平衡树式 ε 分叉并成单入口。
- 平衡树的由来：Thompson 形状限制每状态两条出边，N 路分叉要搭 ⌈log N⌉ 层 ε 结构——形状约束催生算法形状的又一样本。
- 着色链：`stateClass` 喂给 subset → DFA 态带规则色 → minimize 保持色分割。
- 扫描循环（§9.2.2 的可执行形式）：
  - 外层 while 逐 token 推进；空白在循环外跳过（真实 lex 里空白通常是"动作为空"的一条规则 `[ \t]+ ;`，效果等价）；
  - 内层 while 贪心前进，每步记 `lastAcc/lastColor`——**最长匹配的全部实现就是这两个变量**；
  - 转移失败回退到 lastAcc、按 lastColor 报规则名；
  - lastAcc 为 npos 时 ERR 前进一格（flex 缺省 ECHO 回显——策略分歧见 §9.2.2a）。

走读完这四段，"Lex 心脏"应当已经具体化：**四段旅程 + 两条仲裁法**。flex 快一个数量级（等价类、直接合成、表压缩——§9.2.5 的差距清单），但语义空间没有一寸超出这里的范围。

### 9.2.4　套上 yylval 的外套：MiniLex

第 5 章 Scanner 的产物是 `"NUM('42')"` 风格的字符串——用于第 5 章的对账很方便，但 yacc 需要结构化的 (kind, text)。本章的 MiniLex 就是这层薄壳：

```cpp
// file: src/demo.hpp
// demo 层：mini-lex（Lex 心脏的规则表包装）与计算器文法（yacc 心脏的消费者）。
#ifndef TIP_DEMO_HPP
#define TIP_DEMO_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "re.hpp"    // TokenRule / Scanner：Lex 心脏住在第 5 章的机器里
#include "yacc.hpp"

namespace tip {

// ---------- mini-lex：Lex 规格的最小对应物 ----------
// Lex 心脏 = 规则表（正则→动作）+ 最长匹配 + 同长先声明优先。
// 这三样恰好是第 5 章多模式 Scanner 的全部——所以这里一行不改地复用它，
// 只把 "NAME('text')" 的字符串产物拆回结构化 token（yylval 的填充点）。
struct LexTok {
    std::string kind, text;   // kind 即文法终结符名；text 即 yytext
};

class MiniLex {
public:
    MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet);
    // 空白跳过；无法成词的字符输出 kind="ERR"。
    std::vector<LexTok> scan(const std::string &src) const;
    std::string stats() const { return sc_.stats(); }

private:
    Scanner sc_;
};

// ---------- 计算器语言 ----------
// stmt → ID '=' expr ';' | 'print' expr ';'
// expr → expr op expr | '-' expr | '(' expr ')' | NUM | ID     （op ∈ + - * / ^）
// 表达式文法刻意二义（yacc 用优先级声明消解，而非改文法）——见 demo.cpp。

struct CalcEnv {
    std::map<std::string, double> vars;     // ID 的家
    std::vector<std::string> printed;       // print 语句的输出
};

std::string fmt(double v);

// 规则集三份口径：uminusLevel = '-' expr 的 %prec 级别（0 = 不声明）。
std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel);

// 计算器语言的词法规则（先声明者优先：print 在 ID 前）。
std::vector<TokenRule> calcLexRules();
std::set<char> calcAlphabet();

// ---------- 嵌入动作改写的对照文法 ----------
// A 形（用户写法）  ：stmt2 → ID #chk1 '=' expr #chk2 ';'
// B 形（改写产物）  ：#chk / #chk2 变 ε 非终结符——rewriteEmbedded 的输出
// C 形（手写等价）  ：N1/N2 手写 ε 规则——独立复核
struct EmbedEnv {
    std::map<std::string, double> vars;
    std::vector<std::string> log;
};
std::vector<YaccRule> embedRulesA(EmbedEnv &env);   // 含 '#' 占位符（不可直接构造表）
std::vector<YaccRule> embedRulesC(EmbedEnv &env);   // 手写 N1/N2 版
std::map<std::string, std::pair<YaccAction, std::string>> embedActions(EmbedEnv &env);

}  // namespace tip

#endif  // TIP_DEMO_HPP
```

```cpp
// file: src/demo.cpp
// demo 层实现。
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

// ---------- 计算器文法 ----------

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

// ---------- 嵌入动作对照 ----------

std::vector<YaccRule> embedRulesA(EmbedEnv &env) {
    // 用户写法：两个嵌入动作夹在产生式中间（'#' 占位）。
    return {
        {"prog2", {"prog2", "stmt2"}, {}, "prog2-cons", 0},
        {"prog2", {"stmt2"}, {}, "prog2-base", 0},
        {"stmt2", {"ID", "#chk1", "=", "expr2", "#chk2", ";"},
         [&env](std::vector<YaccValue> &v) {
             env.vars[v[0].asStr("stmt2: $1")] = v[3].asNum("stmt2: $4");
             env.log.push_back("stmt2-done");
             return YaccValue::empty();
         },
         "stmt2", 0},
        {"expr2", {"expr2", "+", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") + v[2].asNum("$3")); },
         "expr2-add", 0},
        {"expr2", {"expr2", "*", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") * v[2].asNum("$3")); },
         "expr2-mul", 0},
        {"expr2", {"NUM"}, {}, "expr2-num", 0},
        {"expr2", {"ID"},
         [&env](std::vector<YaccValue> &v) {
             auto it = env.vars.find(v[0].asStr("expr2: $1"));
             if (it == env.vars.end())
                 throw std::runtime_error("undefined variable: " + v[0].str);
             return YaccValue::ofNum(it->second);
         },
         "expr2-id", 0},
    };
}

std::vector<YaccRule> embedRulesC(EmbedEnv &env) {
    // 手写改写：N1/N2 是 ε 非终结符——与 rewriteEmbedded 的自动产物对账。
    return {
        {"prog2", {"prog2", "stmt2"}, {}, "prog2-cons", 0},
        {"prog2", {"stmt2"}, {}, "prog2-base", 0},
        {"stmt2", {"ID", "N1", "=", "expr2", "N2", ";"},
         [&env](std::vector<YaccValue> &v) {
             env.vars[v[0].asStr("stmt2: $1")] = v[3].asNum("stmt2: $4");
             env.log.push_back("stmt2-done");
             return YaccValue::empty();
         },
         "stmt2", 0},
        {"expr2", {"expr2", "+", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") + v[2].asNum("$3")); },
         "expr2-add", 0},
        {"expr2", {"expr2", "*", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") * v[2].asNum("$3")); },
         "expr2-mul", 0},
        {"expr2", {"NUM"}, {}, "expr2-num", 0},
        {"expr2", {"ID"},
         [&env](std::vector<YaccValue> &v) {
             auto it = env.vars.find(v[0].asStr("expr2: $1"));
             if (it == env.vars.end())
                 throw std::runtime_error("undefined variable: " + v[0].str);
             return YaccValue::ofNum(it->second);
         },
         "expr2-id", 0},
        {"N1", {}, [&env](std::vector<YaccValue> &) { env.log.push_back("#chk1-after-ID"); return YaccValue::empty(); }, "N1", 0},
        {"N2", {}, [&env](std::vector<YaccValue> &) { env.log.push_back("#chk2-after-expr"); return YaccValue::empty(); }, "N2", 0},
    };
}

std::map<std::string, std::pair<YaccAction, std::string>> embedActions(EmbedEnv &env) {
    return {
        {"#chk1", {[&env](std::vector<YaccValue> &) {
                       env.log.push_back("#chk1-after-ID");
                       return YaccValue::empty();
                   }, "#chk1"}},
        {"#chk2", {[&env](std::vector<YaccValue> &) {
                       env.log.push_back("#chk2-after-expr");
                       return YaccValue::empty();
                   }, "#chk2"}},
    };
}

}  // namespace tip
```

`MiniLex::scan` 把 `NAME('text')` 拆回两半：`(` 之前是种类号，引号里是 yytext。真正填充 `yylval` 的时机不在这里而在 MiniYacc 的移进动作里（NUM 转数值、ID 留字符串——§9.3.4），这正是 lex 契约的分工：**lex 只交原文，值的解释归语法动作**。

#### 9.2.4a　demo.cpp 逐块走读

demo.cpp 分三块：MiniLex 的拆包、词法规则表、计算器文法。逐块过。

**块一：`MiniLex::scan` 的三行拆包**。

- `lp = s.find('(')` 定位第一个左括号——名字与正文的分界。
- `rp = s.rfind(')`')` 定位最后一个右括号——防御 text 里本身含括号的情形（ID 模式不收括号，这里是纵深防御）。
- `substr(lp + 2, rp - lp - 3)` 取引号内的原文：`+2` 跳过 `(` 与开引号，长度减 3 掉两引号与右括号。这三个常数是本章开发时真实调过一次的 off-by-one（初版 `rp - lp - 2` 把闭引号带进了 yytext，§9.7.5 的坑账有记）。

**块二：规则表 `calcLexRules`——15 条规则逐条讲**。

- 辅助函数 `altChars` 把字符集展开成 `(a|b|c)` 择一式：lex 的 `[a-z]` 是糖，这里是糖下的原形。26 个小写字母加下划线、10 个数字，两条"类"各展开一次、复用两次（`LD = (L|D)`）。
- 第 1 条 `{"print", "print"}`：关键字规则。**它必须排在 ID 前**——同长匹配时先声明者胜（§9.2.2 法则二）。
- 第 2 条 `{"NUM", D + D + "*"}`：数字串。`DD*` 即"一位以上"——lex 写 `[0-9]+`，迷你正则没有 `+`，用 `XX*` 展开。
- 第 3 条 `{"ID", L + LD + "*"}`：字母开头的标识符。与关键字规则的先后序就是两者的边界。
- 第 4–5 条 `{"<=", "(<)(=)"}`、`{"==", "(=)(=)"}`：双字符运算符。**这两条放在 `<`、`=` 前后都无所谓**——长度仲裁自动让 `<=` 赢 `<`。与第 1 条形成对照：同长靠声明序、异长靠长度，两条法则各管一边。
- 第 6–7 条 `{"<", "<"}`、`{"=", "="}`：单字符比较运算符。demo 文法其实不用它们（计算器无布尔值），规则表留着是为了 §9.7 的最长匹配语料——词法层可以独立于语法层测试。
- 第 8–12 条 `+ - * / ^`：五个运算符。注意 `"*"` 的模式写成 `"\\*"`——C++ 字面量里的两个字符 `\*`，迷你正则的转义符（§9.2.3a 第一段）把星号按字面量处理。没有这层转义，模式 `"*"` 是"空串的星号"，解析器报"缺操作数"。
- 第 13–14 条 `LPAREN/RPAREN`：括号。名字不用 `"("`/`")"`，原因见下。
- 第 15 条 `{";", ";"}`：分号，无转义需求（分号不是迷你正则的元字符）。

**一个接口细节**：括号 token 为什么叫 `LPAREN/RPAREN`？第 5 章的字符串协议是 `NAME('text')`，拆包以**第一个 `(`** 为界——名字里若含 `(`，`kind` 会截成空前缀。这不是假想威胁，是本章开发的真实事故（§9.7.5 坑二）：初版就叫 `"("`，全部含括号语料静默拒绝，因为 kind 变成了空串、查表落空。"接口对名字字符集的隐含约束"在真实工具同样常见——bison 的符号名只允许字母数字下划线，flex 的 `%option` 名单同理。**字符串协议的定界符不能出现在载荷里**，这是所有自定义文本协议的第一课。

**块三：`calcRules`——十条产生式逐条讲**（动作语义；文法形状的讨论在 §9.3.5）。

- 第 1–2 条 `prog → prog stmt | stmt`：左递归的语句序列。无动作（prog 的值没人消费），缺省 `$$ = $1` 拿到 Empty，无害。
- 第 3 条 `stmt → ID '=' expr ';'`：赋值。动作五行：`env.vars[v[0].asStr(...)] = v[2].asNum(...)`——`$1` 取名字（Str 标签）、`$3` 取值（Num 标签），写进 CalcEnv 的变量表。`asStr/asStr` 的调用点名字（`"stmt: $1"`）会在标签不符时进诊断信息（§9.4）。
- 第 4 条 `stmt → 'print' expr ';'`：打印。`$2` 求值后 `fmt()` 成字符串压入 `env.printed`——`fmt` 用 `ostringstream` 的缺省六位有效数字：`14` 打出来是 `14` 不是 `14.000000`，`100/8/5` 是 `2.5`。
- 第 5–9 条 `expr → expr op expr`：五个二元运算符共用一个循环生成（`for (Op op : {...})`），每个动作是三行：取 `$1`、取 `$3`、按 op 字符 switch 算 `$$`。switch 带 default 抛异常——Lt 潜伏坑的教训（第 55 章）：跨枚举/字符对照的表必须显式拒绝静默穿透。pow 用 `std::pow`，整型幂会走 double——demo 语料全在精确表示范围内，输出无尾差。
- 第 10 条 `expr → '-' expr`：一元负号。`rulePrec` 字段填 `uminusLevel`（构造参数）——它就是 %prec UMINUS 的教学对应物（§9.6.2），0 表示"不声明"。
- 第 11 条 `expr → '(' expr ')'`：括号。动作只有 `return v[1];`——**必须显式**，缺省 `$$=$1` 会拿 `(` 的 Empty（§9.4.2 的最小反例）。
- 第 12 条 `expr → NUM`：无动作，缺省拿 NUM 的值——移进时已经 `stod` 成数值压栈（§9.3.4 第 2 点）。
- 第 13 条 `expr → ID`：变量引用。查 `env.vars`，查不到抛 `undefined variable: x`——这不是语法错误而是语义错误，抛异常由 main 捕获……实际上 demo 语料全部先赋值后引用，这条路径走不到；留着它是"值栈动作可以做任意计算"的示范（包括失败）。

**EmbedEnv 三兄弟**：`embedRulesA`（用户写法，`#chk1`/`#chk2` 占位）、`embedRulesC`（手写 N1/N2 的改写版）、`embedActions`（占位符的动作旁表）。三者的对账实验在 §9.5——这里先注意 A 与 C 的 stmt2 动作**逐字相同**（都引用 `$4` 即 expr2 的值）：改写只动文法形状，不动动作体，这是等价性论证的前提。

### 9.2.5　迷你实现与 flex 的差距清单

教学实现与工业 flex 的差距值得点名，免得读者把迷你版当成 flex 的等价物：

| 维度 | 本章 MiniLex | flex 实际做法 | 差距的性质 |
|---|---|---|---|
| 字符类 | `(0|1|...|9)` 全展开 | 等价类压缩（256 字符并成几十类） | 性能：转移表按类索引，缓存友好 |
| NFA→DFA | 子集构造 + 最小化 | 直接从正则合成 DFA | 性能：少一次中间表示 |
| 起始状态 | 单一起点 | `%start` 多起始态（注释/字符串/代码分区） | 表达力：上下文相关词法 |
| 规则动作 | kind 号 + yytext | 任意 C 代码，含 BEGIN 切换起始态 | 表达力：词法状态机 |
| 输入缓冲 | std::string 整串 | 双缓冲区 + yyless/unput 回退 | 内存：流式处理任意大输入 |
| 优先级实现 | 接受态着色 + 取最小 | 规则序内建 | 语义：相同 |

表里最后一行是本教程敢于"以小代大"的根据：**语义空间我们全覆盖**（两条仲裁法、优先级、yytext），差距集中在性能与工程包装——它们不改变"什么是合法的 token 流"。

### 9.2.6　字母表与自动机规模的账

`stats` 行里的三个数字（rules=15、alphabet=47、dfa_states=20）值得算一遍账：

- 47 个字符 = 26 个小写字母 + 下划线 + 10 数字 + 10 个符号（`< = + - * / ^ ( ) ;`）——alphabet 显式给出是第 5 章子集构造的口径（避免"隐式全集"歧义），它恰好等于规则表用到的字符全集。（开发时这里曾混进一个没有任何规则使用的幽灵字符 `>`：字母表虚胖一格、自动机毫无感觉——**字母表是"允许出现"的清单，不是"真的出现"的清单**，多写无害但账不干净，删。）
- 15 条规则并联后，未最小化的 DFA 态数在几十到百级（数字状态 × 运算符状态 × 前缀共享）；最小化压到 20。**最小化为什么能压这么多**：`<=` 与 `<` 共享 `<` 前缀态、`==` 与 `=` 共享 `=` 前缀态、NUM 与 ID 共享"起始未定"的那几个态——可区分性分割把这些合并掉了。
- 一个反直觉的观察：**加一条 `<=` 规则几乎不增加状态**（它复用 `<` 的前缀路径），但**加一个新字符类**（比如大写字母）会让字母表与状态数都涨。规则的正则形状决定增量成本——这是"为什么关键字列表通常做成一条 `((if)|(then)|(else)|...)` 择一规则而不是 N 条独立规则"的自动机层解释。

## 9.3　Yacc 的心脏：状态栈旁边的值栈

### 9.3.1　值栈是什么

yacc 生成的分析器是一个表驱动循环（第 7/8 章已经手写过两遍），yacc 在它上面加的唯一东西是**第二条栈**：

```text
状态栈：  [s0, s1, s2, ..., sk]        ← 控制流：查表用
值栈：    [∅,  v1, v2, ..., vk]        ← 数据流：动作读写用
              └── 与状态一一对应，移进同步压，归约同步弹
```

两条栈的**平行不变式**：第 i 个状态槽旁边住着"导致进入该状态的符号的值"。移进 token `t` 时，状态栈压入目标态、值栈压入 `yylval`；归约产生式 `A → X1 X2 ... Xn` 时，状态栈弹 n 格、值栈也弹 n 格——弹出的 n 个值按出现序就是 `$1, $2, ..., $n`，动作算出的 `$$` 随 goto 目标态一起压回。**值栈不需要独立的生命周期管理，它完全寄生在状态栈的节奏上。**这是本设计的全部优雅之处。

对照后面第 21 章的运行时栈：活动记录里"控制链"（谁调用我）与"数据链"（我的非局部环境在哪）也是这样一对平行信息。归约五步（§9.3.3）与调用序列五步（第 21 章 21.3 节）的类比，学到运行时篇可以回来印证。

### 9.3.2　表从哪来：复用第 8 章

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

LALR(1) 造表的完整讲解在第 8 章（项集族、同心合并、lookahead 传播）。本章视角的两个新观察：

1. **`fill` 的冲突记账**：同一格出现两个不同动作时，`setAct` 保留先到者并把这个格子记进 `conflicts`。yacc 真实做法一样——先造完表、再统一裁决冲突（§9.6），而不是在填表途中偏袒任何一方。教学版把"保留先到者"作为可覆盖的初值，仲裁器随后重写。
2. **`goTo` 的导出**：08 章把它藏进匿名命名空间（只有 `fill` 用它）；本章的仲裁器要**重算**冲突格的移进候选（从项集出发走一遍 GOTO 找回目标态编号），所以副本把它移出匿名区并在头文件声明。这是两章副本仅有的实质差异，diff 一眼可验。

#### 9.3.2a　lr1.cpp 逐段走读：造表器的六个部件

裁剪后的 263 行副本（裁了 SLR 支路，见 §9.7.6 清单），第 8 章的主角。按"yacc 造表要过六关"的顺序重走，每关只讲本章用到的新视角；完整推导（含例子与手工造表账）见第 8 章原文。

**第 1 关：文法表示（`Grammar`）**。

- 产生式是 `(lhs, rhs向量)`，**产生式 0 恒为增广开始产生式 `S' → S`**——这是 LR 分析的标准预处理：让"接受"也有一个专属产生式（`S' → S ·, $` 项到达即 Acc），否则接受与归约无法区分。
- `terms` 里含哨兵 `"$"`（输入结束）。MiniYacc 构造器里 `terminals.push_back("$")` 就是补这一格。
- 终结符与非终结符是**字符串集合**，判别靠 `isTerm`（terms 里有没有）。字符串符号让教学代码可读（`"expr"`、`"+"`），真实 bison 用整数编号省一次哈希——副本保持第 8 章原样。

**第 2 关：FIRST 集（`firstOfSeq`）**。

- 服务于 lookahead 传播：闭包里 `[A → α·Bβ, a]` 要给 `B` 的各项发 `FIRST(βa)` 的许可证。
- 实现细节值得一眼：终结符出现即止；非终结符**可空则继续看下一个**——链式可空（B 可空、C 可空、……）靠递归自然处理。
- 本章 demo 文法没有 ε 产生式（除了 §9.5 改写注入的两条），FIRST 退化为"非空即停"——但改写文法 B/C 形会真实用上这条路径，这就是为什么副本不能裁掉可空处理。

**第 3 关：项与闭包（`Item`/`closure`/`goTo`）**。

- `Item{prod, dot, la}` 三元组：产生式号、圆点位置、lookahead。SLR 口径下 `la` 为空串（用 FOLLOW 代替）。
- `closure` 的传播循环是造表的成本大头：新项可能再派生新项，循环到不动点。第 8 章 8.3 节有手工传播账。
- `goTo` 是圆点移过符号再闭包——**填表时它决定 shift 目标，本章仲裁器用它重算冲突格的移进候选**（§9.6.3）。它从匿名命名空间移出的那两行改动（.hpp 声明 + .cpp 边界），加上裁掉的 SLR 支路，构成副本相对第 8 章原版的全部差异——行为零变化，diff 一眼可验（§9.7.6 的裁剪清单）。

**第 4 关：规范 LR(1) 族（`buildLR1`）**。

- 从 `[S' → ·S, $]` 出发，闭包 + goTo 穷举所有状态。
- demo 文法（含五个二元运算符与一元负号）的 LR(1) 状态数在百级——第 8 章讲过的"lookahead 分裂"让每个核心按上下文裂成多份。这个数字是 LALR 要合并的理由，下一关说。

**第 5 关：同心合并（`buildLALR`）**。

- 核心（`Core`）= 去掉 lookahead 的 (prod, dot) 集合。**同心的状态合并、lookahead 求并**。
- 合并后状态数回落到几十，表小到能塞进 1975 年的内存——这是 yacc 选 LALR 而非规范 LR(1) 的历史原因（第 8 章 8.5 节）。
- 合并的安全性：同心合并**不会引入 shift/reduce 冲突**（只会引入新 reduce/reduce）——这是 LALR 的定理，也是 yacc 家族敢用的数学底气。demo 文法合并后 30 个唯一冲突格全部是 shift/reduce（`ruleOrder=0` 佐证了这一定理在本语料上的表现）。

**第 6 关：填表与冲突记账（`fill`）与裸驱动（`tableParse`）**。

- `fill` 遍历项集：移进项发 Shift、归约项按 permit 发 Reduce（SLR 用 FOLLOW、LR(1)/LALR 用项自身 lookahead）、增广项发 Acc。
- 同格两异动作：**记入 `conflicts`、保留先到者**。注意"先到者"取决于 `std::set<Item>` 的遍历序（按 prod/dot/la 字典序），不是"prefer-shift"——真正的裁决在仲裁器（§9.6.3），`fill` 只负责把冲突**曝光**。这个设计让冲突处理成为独立于填表的阶段，与 yacc 报告冲突再裁决的真实流程同构。
- `tableParse` 是不含值栈的裸驱动——本章把它当 **oracle**（§9.7.2）：同一张表、两种驱动、步数对账。它的 1000 步保险丝在教学语料上永远点不着，留着无妨。

### 9.3.3　归约五步

把 `MiniYacc::parse` 的归约分支展开成五步（对照代码读）：

```text
1. 定位：act.target = 产生式号 p
2. 弹值：vals = 值栈末尾 n 个（即 $1..$n，按序）
3. 弹栈：状态栈、值栈各弹 n 格
4. 算值：$$ = action(vals)     ← 动作在此执行，也仅在此执行
5. 压回：goto[栈顶][A] 压状态，$$ 压值栈
```

第 4 步的注释是本节的标题句：**动作只在归约时执行**。移进永不执行用户代码——这保证了动作的执行序恰好等于归约序，而归约序由表唯一决定。于是"文法 + 动作"的语义完全可预测：§9.7 的 reduce log 打印出来的每一行，就是动作执行的时刻表。

一个常被忽视的细节在第 2 步与第 5 步之间：**弹出的 vals 是拷贝**。动作拿到的是 n 个值的副本，想改它们不影响栈上已弹掉的内容——当然也不需要影响，因为弹掉的就是要丢弃的。真正的"输出"只有 `$$` 一个槽。这与函数调用的值传递完全同构（第 22 章会看到值传递的运行时版本）。

### 9.3.4　驱动器全文

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

走读要点：

1. **构造即造表**（`buildTable`）：先 `buildLR1` 再 `buildLALR`——第 8 章的标准两步。注意冲突**不**在构造期裁决：`setPrec` 声明可能在构造之后才到达（对应 .y 文件里声明在前、生成在后的次序其实无关紧要），所以仲裁是惰性的——`parse/table/conflictStats` 首次使用前经 `ensureResolved` 触发。这个"声明可以晚到"的实现口径，恰好和 bison 的使用体验一致（生成器读完全文件才开始干活）。
2. **移进即填 yylval**：`NUM` 的文本在这里 `stod` 成数值、`ID` 留字符串、其余种类给 Empty。这就是 §9.2.1 说的 lex/yacc 接口契约的另一半。
3. **缺省动作 `$$ = $1`**：动作留空的规则按 yacc 缺省继承首符号的值。`expr → NUM` 靠它白拿 NUM 的值；但 `expr → ( expr )` **必须**显式写动作返回 `$2`——缺省会给 `(` 的 Empty 值。demo 文法里这条规则的动作只有 `return v[1];` 一行，它是"缺省不是万能"的最小反例。
4. **步数口径**：`for (;; ++r.steps)` 在循环头自增——本轮动作完成才计数。这与第 8 章 `tableParse` 的口径逐字对齐，§9.7 的 oracle 对账（同一张表两种驱动，步数必须相等）依赖这个细节。差一就 DIFFER，写错了对账会立刻抓到——这正是对账的价值。

#### 9.3.4a　yacc.cpp 逐函数走读

201 行新代码，六个函数，逐个过。

**`MiniYacc::MiniYacc`（构造器）——校验、增广、造表三段**。

- 第一段校验占位符：右部里 `#` 起头、又**没有对应 lhs 定义**的符号，抛"须先经 rewriteEmbedded 展开"。
- 注意校验的精确定义：不是"见到 `#` 就炸"。改写产物里 `#chk1` 是**合法的 ε 非终结符**（它出现在某条规则的 lhs），必须放行——初版校验见 `#` 就炸，把改写产物也炸了（§9.7.5 坑四）。
- 第二段组装 Grammar：先收集全部 lhs 进 nonterms（给 `#` 放行提供依据），再逐条 prods.push_back、补 `"$"` 哨兵、悬空符号检查（右部符号既不是终结符又没有产生式定义 → 报错）。
- 悬空符号检查是本章开发的第二位功臣：`expr` 与 `expr2` 的一次手滑（§9.7.5 坑三的姊妹）就是它抓的。
- 第三段 `buildTable()`：`buildLR1` → `buildLALR`，记 `cstats_.raw`，**不**做仲裁（§9.3.4 走读第 1 点）。

**`setPrec`——声明只入账**。

- 一行：`prec_[term] = {level, assoc}`。声明与造表解耦，仲裁推迟到首次使用——这就是 .y 文件里"声明段在规则段前"的次序在实现里的对应物（倒过来写也一样能用，bison 同理）。

**`prodPrecOf`——产生式优先级的一处查询**。

- 优先级取 `%prec` 覆盖（`rulePrec > 0`）；
- 否则**从右往左**扫 rhs，第一个终结符的声明级；
- 全无非终结符前缀到头或都没声明 → 0（无级）。
- "从右往左"不是随便定的：`expr → expr * expr` 的句柄身份由最右运算符决定（左边的 `expr` 是已归约的整体）。L 书 §5.5.3 的原话就是"产生式优先级 = 最右终结符的优先级"。
- 参数是 rulesIdx（含 0），函数内部换算 `g_.prods[p + 1]`（跳过增广产生式）——两套编号（Grammar 的 prods 从 0 起含增广、rules_ 从 0 起不含）差一，是本文件最容易看走眼的地方，函数注释里钉死了。

**`resolveConflicts`——仲裁器逐步**。

1. 建 `index`：项集 → 状态号（goTo 的落点要按集合相等找回编号；LALR 合并族对 GOTO 封闭，这个查找必有结果）。
2. `seen` 集合去重：`conflicts` 是入账流水（一格撞三动作记两次），逐格只裁一次。
3. 对每个冲突格 `(s, a)`：
4. 重算移进候选：`index[goTo(states[s], a)]`——若落点空（该状态在 a 上根本无移进），shiftTgt = -1；
5. 重算归约候选：遍历 `states[s]`，圆点到底、非增广、且 `la == a` 的项——它们的 prod 号集合；
6. 纯移进（无归约候选）：写回 Shift（保留现状的规范化）；
7. 纯归约：`reduces.size() >= 2` 时计 `ruleOrder++`（reduce/reduce，先声明者胜——prods 升序遍历天然取最小），写回 Reduce；
8. 移进/归约之争：查 `prec_[a]` 得 (tp, ta)，查 `prodPrecOf(best-1)` 得 pp；
9. tp、pp 都 > 0：tp > pp 移进、tp < pp 归约（计 byPrec）；
10. 同级：ta 为 Left 归约、Right 移进（计 byAssoc）、None 移进（计 defaultShift——"非结合"运算符如比较链的 yacc 语义其实是报错，教学版从简）；
11. 任一方为 0（未声明）：缺省移进，计 defaultShift。
- 这个流程与 bison 手册"Conflict Resolution"一节的叙述逐条对应，只是 bison 在文法分析期做、我们在表后做。

**`parse`——值栈主循环逐行**。

- 入口先 `ensureResolved()`（惰性仲裁的收口点之一）。
- 双栈初始化：`stateStack = {0}`、`valueStack = {Empty}`——**两栈长度从此永不相差**。
- `kind/text` 是"当前 lookahead"的滑窗：i 越界时 kind 变 `"$"`，与 tableParse 的哨兵拼接同构。
- 查表 `tab_.action[s][kind]`：双层 map 两次 find，缺席即 Err（拒绝）。
- Shift 分支：压状态、压值（NUM→ofNum(stod)、ID→ofStr、其余 Empty——**yylval 的填充点**，§9.2.1 契约的另一半）、推进滑窗。
- Reduce 分支五步（§9.3.3）：取 p、取 rhs 长度、`vals` 拷贝弹出、双栈同步收缩、执行动作（`actionLog` 先记名后执行——名字先于执行，日志反映"何时触发"而非"何时返回"）、goto 压回。
- 动作为空的缺省：`!rhs.empty()` 时 `got = vals[0]`（`$$ = $1`）；ε 规则给 Empty。
- Acc 分支：`r.result = valueStack.back()`——栈顶值就是开始符号的 `$$`，demo 里 prog 无动作所以是 Empty；真正的计算结果都从 CalcEnv 的 printed/vars 走（动作写侧通道，值栈只当管道）。
- `for (;; ++r.steps)` 在循环头自增：本轮完成才计数——与 tableParse 逐字同构，oracle 对账的命门（§9.3.4 第 4 点）。

**`rewriteEmbedded`——改写器逐步**。

1. 遍历所有规则的 rhs，收集 `#` 起头的符号；
2. 每个**首次出现**的占位符：从旁表 `embeds` 取 (action, name)，造 `YaccRule{lhs=占位符名, rhs={}, action, name}`——**占位符名直接升格为 ε 非终结符名**，原规则的 rhs 一个字符都不用改；
3. 新规则 push 进规则表尾部，计数返回。
- 简洁性来自一个决定：占位符命名空间（`#` 前缀）与非终结符命名空间（无 `#`）**共享字符串世界**，lhs 里允许 `#` 只是"名字怪一点"。真实 yacc 内部用编号做同样的事，人看到的 `$@1` 之类的匿名名就是它的 `#chk1`。

**`showProd`——一行日志的格式**。

- `"12: expr → NUM"`：产生式号 + 文法原文。归约日志的可读性全靠它——§9.7 期望输出的时刻表每行都经它格式化。

#### 9.3.4b　yacc.hpp 接口逐项解说

144 行头文件是本章机器的合同面，逐项过（实现走读在 9.3.4a）：

| 声明 | 角色 | 设计备注 |
|---|---|---|
| `YaccValue` | %union 的教学版 | Tag + num/str 双字段；Empty 表示"无值符号"（运算符、分号） |
| `YaccValue::asNum/asStr` | %type 的运行期影子 | 带调用点名字进诊断——报错能落到 $n |
| `YaccAction` | 动作的类型 | `function<YaccValue(vector<YaccValue>&)>`——vals[k-1] 即 $k |
| `YaccRule` | 规则与动作的绑定 | lhs/rhs/action/actionName/rulePrec 五字段；actionName 服务日志对账 |
| `YaccRule::rulePrec` | %prec 的落点 | 0 = 未声明（取最右终结符） |
| `YaccAssoc` | 结合性枚举 | None/Left/Right 三态，喂给仲裁第三条 |
| `MiniYacc::MiniYacc` | 构造即造表 | 校验占位符 → 组装 Grammar → LR(1) → LALR；仲裁不在此 |
| `MiniYacc::setPrec` | 声明入口 | 只入账不触发——惰性化的前半 |
| `MiniYacc::parse` | 值栈主循环 | 非 const：首次调用触发仲裁（签名即文档） |
| `MiniYacc::RunResult` | 一次分析的全部证词 | accept/steps/reduceLog/actionLog/result 五字段 |
| `MiniYacc::ConflictStats` | 冲突账本 | raw/byPrec/byAssoc/defaultShift/ruleOrder/unresolved 六格 |
| `ensureResolved` | 惰性化的后半 | 三个出口（parse/table/conflictStats）统一收口 |
| `rewriteEmbedded` | 嵌入动作改写器 | 占位符升格为 ε 非终结符；embeds 旁表供动作 |
| `showProd` | 日志格式化 | "12: expr → NUM" 的唯一产地 |

两个接口决定值得点名：**RunResult 带日志**而不是"打印在动作里"——对账需要把证据带出来逐字节比（§9.7 的 expected 就是它的产物）；**parse 的 runActions 开关**——同一驱动可以纯走表（不跑动作）或全功能跑，给"决策与计算分离"留了实验口（练习 9 会用到）。

#### 9.3.4c　demo.hpp 与 lr1.hpp 的接口速览

demo.hpp 的四个实体：

- `LexTok{kind, text}`——token 的最小结构（line 字段留给第 10 章的错误定位，本章未用）；
- `MiniLex`——05 章 Scanner 的拆包壳，构造参数就是规则表与字母表；
- `CalcEnv{vars, printed}`——求值侧通道：变量表 + 打印收集（对账协议的输出面）；
- `EmbedEnv{vars, log}`——嵌入实验的侧通道：变量表 + 动作日志（对账的时序面）。

lr1.hpp 留下的四个公开函数（裁剪后）：

- `firstOfSeq(g, seq, tail)`——FIRST(符号串)，闭包传播的底座；
- `buildLR1(g)`——规范 LR(1) 族造表；
- `buildLALR(g, lr1)`——同心合并；
- `goTo(g, is, x)`——项集转移（本章导出；08 章藏于匿名区）。

加上 `Grammar/Item/Core/Action/Table` 五个数据结构，这就是 yacc 造表的全部合同——**四个函数五个结构，撑起一个世代的工具**。

### 9.3.5　demo 文法：故意二义的计算器

```cpp
（demo.cpp 的 calcRules 全文已在 §9.2.4 内嵌）
```

demo 的文法值得在纸上抄一遍：

```text
prog  → prog stmt | stmt
stmt  → ID '=' expr ';' | 'print' expr ';'
expr  → expr '+' expr | expr '-' expr | expr '*' expr
      | expr '/' expr | expr '^' expr
      | '-' expr            ← %prec UMINUS（§9.6）
      | '(' expr ')' | NUM | ID
```

除了去掉括号的歧义（括号天然无歧义），这张文法**故意保留全部二义性**：五个二元运算符两两冲突、一元负号与二元减号冲突。这不是偷懒——是 yacc 家族的标准姿势：**表达式文法写成人话（数学直觉），优先级与结合性交给声明去表达**。对照第 6 章的 LL 写法（`expr/term/factor` 三层函数把优先级焊进调用图）与第 11 章 Pratt（一张优先级表），这是第三种"优先级住哪儿"的答案：住在生成器的声明段里。三种答案的对照表在 §9.8。

左递归的口味也在这张文法里：`prog → prog stmt` 让语句序列边读边并（栈深常数），`expr → expr + expr` 让加法左结合（§9.6 会看到左结合=冲突时归约）。第 6 章的 LL(1) 版本两者都必须右递归化——世代口味差异在文法形状上一眼可见。

### 9.3.6　归约五步与函数调用的预演对照

值栈的节奏在运行时篇会原样重现。把归约五步与第 21 章的调用序列并排：

| 归约（本章，编译期） | 函数调用（第 21 章，运行期） | 共同的骨架 |
|---|---|---|
| 弹出 n 个右部符号的值 | 实参从调用者栈传入被调者帧 | 数据从"上游"流向"加工点" |
| 动作执行，产出 $$ | 函数体执行，产出返回值 | 计算发生 |
| 压回一个值 | 返回值写回调用者预留的槽 | 数据回到"下游" |
| 状态栈弹 n 压 1 | 帧的建立与销毁 | 控制流框定数据的生命周期 |
| goto 到新状态 | 返回地址跳回调用点 | "下一步去哪"由控制栈决定 |

五行对照里最值得咀嚼的是第四行：**控制流框定数据的生命周期**。值栈槽与状态槽共生共死，正如局部变量与活动记录共生共死。第 21 章讲完活动记录、第 60 章讲完上值（帧没了变量还得活的那些方案）之后，回头看这张表，会看到"生命周期与控制流解耦"正是闭包、堆、GC 的共同起点——而值栈是那个还没解耦的纯真年代。

另一个预告：第 65 章 TM 机器上，表达式求值的临时值住在**数据存储器的软件栈**里（tmpOffset 压弹），那里没有值栈与状态栈的平行结构、只有一条数据栈和 PC——硬件不同，"弹 n 压 1"的节奏相同。**节奏比结构更本质**。

## 9.4　%union 与伪变量：值栈的元素类型

### 9.4.1　值栈装什么

值栈的元素必须能装下**任何符号可能携带的值**：NUM 带数值、ID 带名字、'+' 什么都不带、将来接上 AST 的文法还要带树指针。yacc 的答案是一个带标签联合：

```c
%union {
    double num;        /* NUM 用 */
    char  *str;        /* ID 用 */
    Node  *node;       /* 语法树节点用 */
}
%token <num> NUM
%token <str> ID
%type  <node> expr stmt
```

`%token <num> NUM` 声明"NUM 这个终结符的值住 union 的 num 槽"——这就是 %type 声明。生成器据此做静态检查：动作里 `$1` 的标签与上下文期望不符，编译期报错。本章教学版的 `YaccValue` 用 `Tag + 双字段` 表达同一契约，把 %type 的静态检查降级为运行期断言（`asNum/asStr` 带调用点名字，取错标签即抛异常）：

```cpp
//（yacc.hpp 的 YaccValue，全文见 §9.3.4 内嵌）
struct YaccValue {
    enum class Tag { Empty, Num, Str } tag = Tag::Empty;
    double num = 0;
    std::string str;
    // asNum("stmt: $1")：标签不符 → "type error: stmt: $1 expects Num, got Str"
};
```

标签联合的进阶版——把标签压进位模式本身（NaN 装箱）——是第 59 章的正题，那里值槽只有 64 位、连 tag 字段都要省。本章的 YaccValue 是它奢侈的祖先。

### 9.4.2　缺省 $$ = $1 的陷阱

yacc 的缺省规则"动作留空则 `$$ = $1`"对 `expr → NUM` 恰好正确（NUM 的值就是表达式的值），对 `expr → ( expr )` 则**错**——`$1` 是 `(` 的值（Empty），真正要传递的是 `$2`。demo 文法的解法是显式动作：

```cpp
r.push_back({"expr", {"LPAREN", "expr", "RPAREN"},
             [](std::vector<YaccValue> &v) { return v[1]; },   // $2，不是缺省的 $1
             "expr-paren", 0});
```

这条一行规则是教学语料里"缺省不是万能"的最小反例。真实 yacc 文法里同类陷阱更多——比如 `stmt → if stmt else stmt` 想把 `$2` 传给 `$$`，忘写动作就静默拿到 `$1` 的垃圾值。**标签联合把这类错误从"静默错值"升级成"类型错误"**，这是 %union 设计的真正回报。

缺省 $$=$1 的完整适用条件清单（满足才可省动作）：

- 右部第一个符号的值**恰好就是**左部的语义值（expr→NUM 成立、expr→(expr) 不成立）；
- 值的类型匹配（%type 登记一致——NUM 的 num 槽 vs expr 的 num 槽，恰好一致）；
- 不需要对 $1 做任何加工（取负、包装、登记符号表都不行）。

三个条件在 demo 十条产生式里的分布：满足的只有 `expr → NUM` 与两条 prog 规则（值无人消费，Empty 也无害）；`expr → ID` 要查表（条件三不满足）；五个二元运算要算术（同）；`expr → -expr` 要取负（同）；`expr → (expr)` 要跳过 `$1`（条件一不满足）。**十条里七条要写动作**——缺省是例外而非常态，这是 $n 体系的第一课。

另一个值得并列的反例来自嵌入动作改写（§9.5.3 的姊妹）：改写后 `stmt2 → ID N1 = expr2 N2 ;` 的 `$4` 仍是 expr2 的值——占位符占号、编号不乱；但如果有人把动作写在"以为占位符不占号"的假设上（写成 `$3`），拿到的是 `=` 的 Empty。**编号体系只有一个真相来源：右部符号的物理位置**——任何"我以为"都会被标签联合抓住（asNum 报 type error），这正是 §9.4.1 说的"运行期 %type 检查"的价值时刻。

### 9.4.3　yylval 的生命周期

值在 union 槽里活多久？从移进压栈到归约弹出，**最多活一个句柄的长度**。这条生命周期的短，恰好匹配表达式求值的即时性——算完就丢，不留垃圾。对照第 15 章树遍历解释器的环境链（值在堆上活整个作用域）与第 57 章字节码 VM 的值栈（活到帧退出）：值栈是三者里最短命的。**存储责任与生命周期长度，是运行时设计的核心权衡**——这个主题在第三篇正式展开，此处先埋一个最短命的极端样本。

### 9.4.4　%union 的进化史：从 C union 到装箱

带标签联合这一数据形态的谱系，教程里会出现四次，这里先立个路标：

| 阶段 | 表示 | 标签在哪 | 代表 |
|---|---|---|---|
| yacc %union（1975） | C union + 约定 | 使用者自觉 + %type 声明检查 | 本章 YaccValue |
| C++17 std::variant | 类型安全的判别联合 | 库内建（visit/index） | 现代替代 |
| 字节码值槽（clox） | 带显式 tag 字段的结构 | 结构字段 | 第 57 章 Value |
| NaN 装箱 | 64 位位模式里的静默位 | 位段 | 第 59 章 |

四步的方向一致：**把"标签与载荷的一致性"从人肉约定逐步压进类型系统、再压进位模式**。每一步省的字节数都以安全性检查为代价换来——第 59 章会把这笔账算到底（16 字节的 tag 联合怎么压进 8 字节 double）。C 的裸 union 连标签都没有（靠上下文人肉记住"现在装的是哪个"），%union 的 %type 声明相当于给裸 union 补了一张登记表——生成器据此在编译期对动作代码做检查。本章的 asNum/asStr 把检查挪到运行期、报错带 `$n` 名字，是教学取舍：实现小、诊断可读，代价是错误发现晚一拍。

顺带一个 C++ 程序员会问的问题：为什么不用 std::variant<monostate,double,string>？完全可以——variant 的 std::visit 就是带标签的分派，std::get_if 就是 asNum。教学版手写三字段是为了让"标签"物理可见（一行 struct 看清全部状态空间），也顺便让本章与第 57/59 章的表示演进序列无缝衔接。

## 9.5　嵌入动作：文法里的代码块 = 空产生式改写

### 9.5.1　问题：动作想在"半路"执行

值栈机制只允许动作挂在产生式末尾（归约时刻）。但有时想在**中间**插一段代码——典型场景：在 `stmt → ID '=' expr ';'` 里，想在识别完 ID 后立刻记一行日志（词法位置、变量名），不等整条语句归约。yacc 允许把动作写进右部：

```text
stmt2 → ID  { 动作α }  '=' expr  { 动作β }  ';'
```

问题来了：表驱动世界只有"移进/归约"两种时刻，`{ 动作α }` 挂哪个事件？它不在任何产生式的末尾——**它自己就是一个位置**。

### 9.5.2　答案：改写成空产生式

yacc 的内部改写（L 书 §5.5.6）：

```text
stmt2 → ID  Nα  '=' expr  Nβ  ';'      （Nα、Nβ 是新造的非终结符）
Nα    → ε        { 动作α }
Nβ    → ε        { 动作β }
```

动作α 现在挂在 `Nα → ε` 的**末尾**——归约时刻存在了！ε 产生式的归约发生在"分析器需要在这里出现 Nα、而输入串没有对应符号"的时刻，也就是圆点走到 `{ 动作α }` 位置的时刻。**语义分毫不差，机制成本为零**：不需要新事件类型，不需要改驱动器，只需要文法重写。

本章把这次改写实现成 `rewriteEmbedded`：右部里 `#` 起头的符号是嵌入占位（如 `#chk1`），改写器为每个占位造一条 ε 规则、搬运动作、占位符名直接升格为非终结符名。demo 里同时**手写**一份等价文法（N1/N2 命名的 ε 规则）作为独立复核——§9.7 的对账实验证明两者归约序、动作执行序、求值结果逐项相同。

### 9.5.3　$n 编号的偏移陷阱

改写引入了一个经典陷阱：**$n 按符号位置编号，占位符也占号**。

```text
原写法   stmt2 → ID {α} '=' expr {β} ';'
              $1    $2   $3   $4   $5     ← 占位符占 $2、$5
改写后   stmt2 → ID  Nα  '=' expr  Nβ  ';'
              $1   $2  $3   $4   $5  $6
```

在原写法的动作里写 `$2` 指的是 `{α}` 之后的 `'='`——yacc 会把它编号为 $3。**动手写嵌入动作时最常见的错误**就是把 $n 当成"第几个真符号"。yacc 的实际做法是给嵌入动作分配自己的编号（它有 $$ 可写、可被后文 `$-k` 引用），教材级建议很简单：嵌入动作里只写 `$$`，不数 `$n`。demo 的对照实验里，stmt2 的动作引用 `$4`（expr2 的值）——在 A 形（占位符版）与 C 形（手写版）里这个位置都是 $4，行为一致；若有人把 A 形的动作写成 `$3`（误以为占位符不占号），他会拿到 '=' 的 Empty 值——标签联合会当场报错，而不是静默算错。

### 9.5.4　为什么必须改写（机制论证）

能否让驱动器原生支持"移进后执行"？能，但代价是每个动作位置都变成一个**隐式状态转移点**：驱动器要区分"移进 token"与"执行中缀代码再移进"，动作日志、归约日志、错误恢复的同步点全部要跟着分叉。改写方案把这些复杂性全部推回**文法层**——一个早已被 LR 理论覆盖的层。这是"用已有机制组合出新语义"的教科书案例：ε 产生式在文法理论里早就有（第 6 章 FIRST 集计算就处理过它），嵌入动作只是它的一次营销包装。同样的思路后面还会遇到：第 58 章短路求值用"跳转即短路"实现、第 65 章缓冲区回填用"占位+回写"实现——**不发明新机制，让老机制长出新形状**。

### 9.5.5　执行序的逐行账：`x = 3*4;` 在 B 形下的完整时刻表

把 §9.7 期望输出里 B 形的动作日志（`#chk1-after-ID #chk2-after-expr stmt2-done`）展开成带栈状态的时刻表，每行一步：

| 步 | 动作 | 状态栈（示意） | 值栈（示意） | 说明 |
|---|---|---|---|---|
| 1 | 移进 ID | … ID态 | … Str("x") | yylval 填名字 |
| 2 | **归约 `#chk1 → ε`** | … #chk1态 | … Empty | 嵌入动作 α 在此执行——ID 刚进栈、`=` 还没来 |
| 3 | 移进 `=` | … =态 | … Empty | |
| 4 | 移进 NUM(3) | … | … Num(3) | |
| 5 | 归约 `expr2 → NUM` | … | … Num(3) | 缺省 $$=$1 |
| 6 | 移进 `*` | … | | |
| 7 | 移进 NUM(4)、归约 `expr2 → NUM` | … | … Num(4) | |
| 8 | 归约 `expr2 → expr2 * expr2` | … | … Num(12) | |
| 9 | **归约 `#chk2 → ε`** | … | … Empty | 嵌入动作 β 在此执行——expr 刚归约完、`;` 还没来 |
| 10 | 移进 `;` | | | |
| 11 | 归约 `stmt2 → ID #chk1 = expr2 #chk2 ;` | … | … Empty | stmt2 动作执行（记 log、写 vars） |
| 12 | 归约 `prog2 → stmt2` | … | | 第一句完 |

十二步里三处加粗就是三个动作的触发点。注意两个精确细节：

- 第 2 步的 ε 归约发生在移进 `=` **之前**——LR 分析器在"下一个输入是 `=`、而 #chk1 可空"的时刻选择归约 ε（lookahead `=` ∈ FIRST(=…) 恰好允许）。**ε 归约的时机由 lookahead 许可证控制**，这是它"落在半路"的机制根据。
- 第 9 步同理发生在 `;` 之前。如果 lookahead 是 `+`（比如 `x = 3*4 + 1;`），#chk2 的 ε 归约会等到 `expr2 → expr2 + expr2` 整体归约完之后——**嵌入动作贴着"最近的完整句柄"走**，不是贴着输入位置走。这一点与 ANTLR 监听器的 exitExpr 时机有微妙差别，是两代生成器行为差异的一个具体样本。

C 形的十二步与上表**逐行相同**（N1/N2 只是名字不同）——这就是 §9.7 断言"日志序相等"的展开形态。改写保序的证明就在这张表里：ε 归约的触发条件只依赖 (状态, lookahead)，与 ε 非终结符叫什么名字无关。

### 9.5.6　嵌入动作的真实用途清单

教学 demo 里嵌入动作只是打日志，真实文法里它是四个场景的主力：

- **中途查表**：`decl : TYPE ID { declare($2, $1); } ',' decl_list ...`——声明要在列表继续之前入符号表，等整条 decl 归约就晚了（后续元素可能引用前面的兄弟）。第 12 章作用域规则里"同一声明组内前向引用非法"的检查点，在 yacc 文法里就长在这个位置。
- **L 属性的传递**：继承属性不能等归约——`type : INT { $$ = "int"; }` 之后 `var_list` 的每个动作都要用它。中绵动作把"父传子"的值在文法中途显式接力，是 S-属性框架里硬凑 L-属性的标准姿势（第 13 章 13.3 节的理论在工程上的补丁）。
- **循环不变量的提前计算**：`for ID { push_loopvar($1); } IN range do ...`——循环变量进栈的时机必须在解析体之前，嵌入动作是唯一挂在"半路"的钩子。
- **错误上下文的收集**：`stmt : error { recover_stats(); } ';'`——与 error 记号（第 10 章）配合，恢复点上的清理动作天然是"嵌入"的。

四个场景的共性：**动作依赖的状态在产生式中途才齐、而消费它的代码等不到归约**。这是嵌入动作的存在理由，也是它危险的地方——§9.5.3 的 $n 偏移陷阱全部来自"中途"这个位置属性。经验法则：**能用尾部动作就不用嵌入动作，必须用时动作体只写 $$ 和显式索引，不数"第几个真符号"**。

## 9.6　冲突的仲裁：优先级与结合性声明

### 9.6.1　冲突是特性，不是缺陷

§9.3.5 的文法造出的 LALR 表记了 90 条冲突入账、去重后 30 个唯一冲突格（§9.7 输出 `[standard] raw=90`；分布见 §9.6.3）。一个自然的疑问：为什么不改文法消掉它们？可以——第 6 章的 expr/term/factor 分层就是消歧文的文法——但代价是文法不再像数学直觉，而且每加一个运算符要动三层。yacc 家族的选择相反：**文法保持直觉性的二义，冲突交给声明裁决**。裁决规则四条（L 书 §5.5.3）：

1. **产生式优先级 = 其最右终结符的声明级**（`expr → expr * expr` 的优先级 = `*` 的级）。
2. 冲突格上，比较**当前 token 的级**与**待归约产生式的级**：token 高 → 移进；产生式高 → 归约。
3. **同高看结合性**：左结合 → 归约；右结合 → 移进。
4. **一方无级 → 缺省移进**（这就是第 7 章 prefer-shift 的 yacc 版）。

这四条规则的输出是**确定的语言语义**。`10-3-2` 在 `-` 左结合下归约得 `5`（(10-3)-2），在没有声明（缺省移进）下得 `9`（10-(3-2)）——两个都是"合法的分析"，声明决定哪个是"这门语言的语义"。**优先级声明是语言定义的一部分**，bison 手册把 %left/%right 段落直接放在"语义规则"章节里，就是这个道理。

四条规则各自在 demo 语料里的例证账：

| 规则 | 冲突格 | 语料 | 裁决 | 结果 |
|---|---|---|---|---|
| 1+2 优先级高下 | `expr→expr·*·expr` vs `expr→expr+expr·` 遇 `*` | `2+3*4` | `*`(2) > `+`(1) → 移进 | 14 |
| 1+2 优先级高下（反向） | `expr→expr*expr·` 遇 `+` | `2*3+4` | `+`(1) < `*`(2) → 归约 | 10 |
| 3 结合性 | `expr→expr-expr·` 遇 `-` | `10-3-2` | 同级 1，Left → 归约 | 5 |
| 3 结合性（右） | `expr→expr^expr·` 遇 `^` | `2^3^2` | 同级 3，Right → 移进 | 512 |
| 4 缺省移进 | `expr→expr-expr·` 遇 `-`（无声明口径） | `10-3-2` | 一方无级 → 移进 | 9 |
| 4 缺省移进 | `expr→(expr·)` 里的各归约项遇 `)` | `(1+2)` | `)` 无声明 → 移进 | 3 |

最后一行值得多看一眼：demo 的 30 个冲突格**全部落在五个运算符上**（一次性转储程序的按 token 统计：`+` 6、`-` 6、`*` 6、`/` 6、`^` 6），`)`、`;`、`$` 一个都没撞——LALR 的 lookahead 精确性让"括号后该归约还是移进"这类格子天然无冲突（第 8 章 8.5 节讲过的精确许可证）。**缺省规则的品质**在于它对常见情形的命中率：yacc 选移进，因为"把右部读完整再归约"在绝大多数文法里是对的——这是四十年经验固化成的缺省。

### 9.6.1a　悬空 else：为什么缺省移进恰好正确

第 6 章 6.6 节 LL 版的悬空 else，在 yacc 下是同一个冲突的另一种解法。假想把 demo 文法扩一条：

```text
stmt → 'if' expr 'then' stmt
     | 'if' expr 'then' stmt 'else' stmt
```

移进 `else` 与归约 `stmt → if expr then stmt` 在 else 格子上相撞——else 该配内层 if 还是外层 if？规则 4 缺省移进：**else 永远配最近的未闭合 if**。手工验证两分钟：`if a then if b then s else t`——移进 else 意味着它进内层 if 的右部，t 配 b。这与第 6 章 LL 版"扩展文法让 else 只能进内层"的解法殊途同归——**LL 靠改文法把语义焊进产生式，yacc 靠缺省裁决把语义焊进表**。两种焊法都写进了各自语言实现的历史：Pascal 报告说"else 配最近 if"，C 标准说"else 配最近未匹配的 if"，措辞不同、机制同源。

### 9.6.2　%prec：一元负号的优先级从哪来

`expr → '-' expr` 的最右符号是**非终结符** expr——按规则 1 它没有优先级。而它偏偏最需要优先级（`-3^2` 是 -(3^2) 还是 (-3)^2？）。yacc 的 %prec 指令给产生式**显式覆盖**：

```c
%left '+' '-'
%left '*' '/'
%right '^'
%precedence UMINUS      /* 一个只用于 %prec 的伪终结符 */
%%
expr : '-' expr  %prec UMINUS  { $$ = -$2; }
```

教学版对应 `YaccRule.rulePrec` 字段（`calcRules(env, uminusLevel)` 的第二个参数就是它）。UMINUS 的级声明在哪一档，直接决定语言语义：级低于 `^`（Pascal 传统）则 `-3^2 = -(3^2) = -9`；级高于 `^`（BASIC 传统）则 `(-3)^2 = 9`。§9.7 的翻转实验用两套声明把两个值都跑出来——同一份文法、同一张表、两个答案，差别只在三行声明。

%prec 的三个易混点：

- **它是产生式属性，不是 token 属性**——`%prec UMINUS` 标在规则上，UMINUS 本身只是级数的"名字载体"（一个不出现在任何规则右部的伪终结符，bison 里由 `%precedence UMINUS` 登记级数）。本章的对应：rulePrec 挂在 YaccRule 上，而 UMINUS 的级数直接用整数（2 或 4）传入——省掉伪终结符的注册，机制等价。
- **它只在冲突裁决时被读**——不参与移进/归约的常规判定。一条带 %prec 的规则若无冲突，声明写了也白写（但写了不亏：文档价值）。
- **它的语义是"整条规则当作这个级"**——`expr → - expr` 声明 %prec UMINUS 后，与任何 token 比较都用 UMINUS 的级，包括 `*`、`+`。-3*2 里 `expr→-expr` 遇 `*`：UMINUS(2) 与 `*`(2) 同级、`*` 是 Left → 归约 → (-3)*2 ✓ 正确。**一元负号与乘同档**是多数语言的选择（BASIC 例外）——想清楚这一条，就明白了为什么 demo 取 uminus=2 与乘除同档。

UMINUS 档位的三种语言传统（真实语言的分层样本）：

- C/Pascal 系：一元负号低于幂（-3^2 = -9）；
- BASIC 系：一元负号最高（-3^2 = 9）；
- 数学排版传统：负号当减号看（-3² = -(3²) = -9）——与 C 一致纯属约定巧合。

同一张二义文法 + 三行声明的不同组合 = 三种语言语义。**文法是骨架、声明是语义**——这是 yacc 家族把"语言定义"拆成两半的方式，也解释了为什么读一份 .y 文件必须连声明段一起读。

### 9.6.3　仲裁器的实现

```cpp
//（yacc.cpp 的 resolveConflicts，全文见 §9.3.4 内嵌）
```

实现的关键一步是**重算候选**：冲突格 (s, a) 上，移进候选 = `index[goTo(states[s], a)]`（从项集走一遍 GOTO 找回目标态），归约候选 = 态内所有"圆点到底且 lookahead 覆盖 a"的项。两个候选都拿到了，四条规则就是查表比较，胜者写回 action 表。三个计件器（byPrec/byAssoc/defaultShift）把裁决依据记进账本。demo 文法的真实账目（§9.7 输出）：`raw=90` 是 fill 期的入账流水，`seen` 去重后 **30 个唯一冲突格**——恰好五个运算符各 6 格（`+` 6、`-` 6、`*` 6、`/` 6、`^` 6，用一次性转储程序实测的分布）；standard 口径下 byPrec=19、byAssoc=11、defaultShift=0——**全部 30 格都被声明显式裁决**，没有一格落入缺省。这个"零缺省"是检验声明完备性的意外收获：若漏声明某个运算符，defaultShift 会立刻从 0 跳起来。

还有两个 yacc 缺省值得一记：

- **reduce/reduce**：两个归约候选打架，先声明的产生式胜。武断，但确定——真实文法里 reduce/reduce 几乎总是文法错误（同一串有两种归约），yacc 报 warning 并选前者，bison 会直接标 error。教学版 `ruleOrder` 计数器记录这类裁决。
- **悬空 else**：`stmt → if stmt | if stmt else stmt | ...` 的经典冲突（第 6 章 6.6 节 LL 版）在 yacc 下按规则 4 缺省移进——恰好就是"else 归属最近的 if"。**缺省即语言语义**的又一例。

### 9.6.4　翻转实验：四组数据

实验设计：同一份 demo 文法，四套声明口径，跑同一批语料：

| 口径 | 声明 | 语料与期望 |
|---|---|---|
| no-decl | 完全不声明 | `10-3-2 → 9`（缺省移进=右结合效果） |
| standard | `+ -`↔`* /`↔`^`(右)，UMINUS 低于 `^` | `2+3*4 → 14`、`10-3-2 → 5`、`2^3^2 → 512`、`-3^2 → -9` |
| caret-left | `^` 改左结合 | `2^3^2 → 64` |
| uminus-high | UMINUS 高于 `^` | `-3^2 → 9` |

### 9.6.5　仲裁决策树（把四条规则画成一棵树）

裁决一个 shift/reduce 冲突的完整决策路径，从上往下走：

```text
冲突格 (状态 s, lookahead a)，候选：移进 a / 归约产生式 p
│
├─ tp = prec(a)（token 的声明级）；pp = prec(p)（%prec 或最右终结符）
│
├─ tp = 0 或 pp = 0（有一方没声明）
│    └─ 移进（defaultShift）────────────── yacc 的缺省
│
├─ tp > pp
│    └─ 移进（byPrec）──────────────────── 如 ^ 压 +、UMINUS 压 *
│
├─ tp < pp
│    └─ 归约（byPrec）──────────────────── 如 + 遇 *、- 遇 UMINUS(高档)
│
└─ tp = pp（同级）
     ├─ a 声明为 %left  → 归约（byAssoc）── 左结合：尽早成句
     ├─ a 声明为 %right → 移进（byAssoc）── 右结合：尽量吞
     └─ 未声明结合性    → 移进（defaultShift）
```

树上六个叶子，demo 的 standard 口径踩中三个（byPrec 19 格、byAssoc 11 格、defaultShift 0 格）；no-decl 口径全部落入两个缺省叶（30 格 defaultShift）。**看树识病**：如果一份真实文法的仲裁账本里 defaultShift 很高，说明声明覆盖不足——bison 的 "-Wprecedence" 系列警告就是在树上装了同样的探针。

四组数据全部来自 §9.7 的实际运行输出（不是手抄的理论值）——每一条都能在期望输出里找到对应行。特别注意 `2+3*4` 在 no-decl 与 standard 下**同为 14**：缺省移进让 `*` 在冲突格上赢，与优先级声明同效——但这是巧合的等价（对 `+ *` 组合成立，对 `- -`、`^ ^` 组合不成立），不能因为"结果一样"就以为声明可有可无。`10-3-2` 的 9 vs 5 才是撕开两者差别的语料。

## 9.7　驱动与对账实验

### 9.7.1　驱动全文

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 9 章驱动（无参运行，走"简单程序"对账协议）：
//   §2 mini-lex 最长匹配与先声明优先 → §3 值栈驱动求值 + 08 章表驱动对账 →
//   §5 嵌入动作改写等价 → §6 优先级声明消冲突（翻转实验）。
#include "demo.hpp"

#include <iostream>
#include <stdexcept>

namespace {

using tip::LexTok;
using tip::MiniLex;
using tip::MiniYacc;
using tip::YaccAssoc;

std::vector<std::pair<std::string, std::string>> toPairs(const std::vector<LexTok> &ts) {
    std::vector<std::pair<std::string, std::string>> out;
    for (const auto &t : ts) out.push_back({t.kind, t.text});
    return out;
}

void printTokStream(const MiniLex &lx, const std::string &src) {
    std::cout << "  ";
    for (const auto &t : lx.scan(src))
        std::cout << t.kind << "('" << t.text << "') ";
    std::cout << "\n";
}

// 一套优先级口径：null = 完全不声明；否则给 +,-,*,/ 声明级与结合性，
// '^' 与一元负号的级别由参数单独给——翻转实验的旋钮。
struct PrecCfg {
    bool none = false;
    int caretLevel = 3;
    YaccAssoc caretAssoc = YaccAssoc::Right;
    int uminus = 2;
};
MiniYacc makeCalc(tip::CalcEnv &env, const PrecCfg &cfg) {
    MiniYacc y(tip::calcRules(env, cfg.uminus), "prog",
               {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN"});
    if (cfg.none) return y;
    y.setPrec("+", 1, YaccAssoc::Left);
    y.setPrec("-", 1, YaccAssoc::Left);
    y.setPrec("*", 2, YaccAssoc::Left);
    y.setPrec("/", 2, YaccAssoc::Left);
    y.setPrec("^", cfg.caretLevel, cfg.caretAssoc);
    return y;
}

double evalOne(const MiniLex &lx, MiniYacc &y, tip::CalcEnv &env,
               const std::string &prog) {
    auto r = y.parse(toPairs(lx.scan(prog)), true);
    if (!r.accept) throw std::runtime_error("reject: " + prog);
    if (env.printed.empty()) throw std::runtime_error("no output: " + prog);
    double v = std::stod(env.printed.back());
    env.printed.clear();
    return v;
}

}  // namespace

int main() {
    // ---------- §2 mini-lex ----------
    std::cout << "== S2 mini-lex ==\n";
    MiniLex lx(tip::calcLexRules(), tip::calcAlphabet());
    std::cout << "[stats] " << lx.stats() << "\n";
    std::cout << "[longest match]\n";
    printTokStream(lx, "a<=b == c = d <e1 x9y 42");
    std::cout << "[tie: keyword first -> print is KW]\n";
    printTokStream(lx, "print printx");
    {
        // 翻转声明序：ID 在前，同长 "print" 判给 ID——先声明优先的直接证据。
        auto rules = tip::calcLexRules();
        std::vector<tip::TokenRule> flipped(rules.begin() + 1, rules.begin() + 3);
        flipped.push_back(rules[0]);
        for (size_t i = 3; i < rules.size(); ++i) flipped.push_back(rules[i]);
        MiniLex lx2(flipped, tip::calcAlphabet());
        std::cout << "[tie: ID first -> print is ID]\n";
        printTokStream(lx2, "print printx");
    }

    // ---------- §3 值栈驱动 ----------
    std::cout << "== S3 value-stack parse ==\n";
    tip::CalcEnv env;
    MiniYacc calc = makeCalc(env, PrecCfg{});   // 标准口径：+ - * / 左，^ 右，uminus<* ^
    const std::string corpus =
        "x = 2+3*4; print x; y = (2+3)*4; print y; z = 2^3^2; print z; "
        "w = -3^2; print w; v = 10-3-2; print v; u = 100/8/5; print u; "
        "t = 2*3+4*5; print t; s = -2--3; print s; "
        "a1 = 7; print a1; b = a1*2; print b; c = 2^2^3; print c; "
        "d = (1+2)^2; print d; e = -(-5); print e; f = 8/2*3; print f; "
        "g = 1+2*3^2; print g; h = 10-2*3; print h; i = 2^(1+2); print i; "
        "j = 6/2/3; print j;";
    auto run = calc.parse(toPairs(lx.scan(corpus)), true);
    if (!run.accept) {
        std::cout << "!! corpus rejected\n";
        return 1;
    }
    for (size_t k = 0; k < env.printed.size(); ++k)
        std::cout << "[eval " << k + 1 << "] " << env.printed[k] << "\n";

    // 归约日志：第一条语句 x = 2+3*4; 的完整归约序（手工推演的对照面）
    {
        auto first = calc.parse(toPairs(lx.scan("x = 2+3*4;")), true);
        std::cout << "[reduce log: x = 2+3*4;]\n";
        for (const auto &s : first.reduceLog) std::cout << "  " << s << "\n";
    }

    // 08 章表驱动对账：同一张 LALR 表，值栈驱动与裸驱动逐语料同 accept/同步数。
    {
        std::cout << "[oracle parity]\n";
        const char *progs[] = {
            "x = 2+3*4; print x;", "print (1+2)*3;", "x = -3^2; print x;",
            "x = ;", "print 2+;", "x = 2", "(x = 4);",
        };
        int agree = 0, total = 0;
        for (const char *p : progs) {
            auto toks = lx.scan(p);
            std::vector<std::string> words;
            for (const auto &t : toks) words.push_back(t.kind);
            auto mine = calc.parse(toPairs(toks), true);
            auto oracle = tip::tableParse(calc.grammar(), calc.table(), words);
            ++total;
            bool ok = mine.accept == oracle.accept && (!mine.accept || mine.steps == oracle.steps);
            agree += ok;
            std::cout << "  " << (ok ? "match  " : "DIFFER ") << "accept=" << mine.accept
                      << "/" << oracle.accept << " steps=" << mine.steps << "/" << oracle.steps
                      << "  [" << p << "]\n";
        }
        std::cout << "[oracle] " << agree << "/" << total << " matched\n";
        if (agree != total) return 1;
    }

    // ---------- §5 嵌入动作 = 空产生式改写 ----------
    std::cout << "== S5 embedded action rewrite ==\n";
    const std::string ecorpus = "x = 3*4; y = x+1;";
    tip::EmbedEnv envB, envC;
    auto [rulesB, added] = tip::rewriteEmbedded(tip::embedRulesA(envB), tip::embedActions(envB));
    std::cout << "[rewrite] embedded markers -> " << added << " epsilon rules\n";
    MiniYacc yB(rulesB, "prog2", {"ID", "NUM", "=", ";", "+", "*"});
    auto rB = yB.parse(toPairs(lx.scan(ecorpus)), true);
    MiniYacc yC(tip::embedRulesC(envC), "prog2", {"ID", "NUM", "=", ";", "+", "*"});
    auto rC = yC.parse(toPairs(lx.scan(ecorpus)), true);
    if (!rB.accept || !rC.accept) {
        std::cout << "!! embedded corpus rejected (B=" << rB.accept << " C=" << rC.accept << ")\n";
        for (const char *q : {"x = 3*4;", "y = x+1;", "x = 3;"}) {
            auto b1 = yB.parse(toPairs(lx.scan(q)), true);
            auto c1 = yC.parse(toPairs(lx.scan(q)), true);
            std::cout << "  [" << q << "] B accept=" << b1.accept << " steps=" << b1.steps
                      << " | C accept=" << c1.accept << " steps=" << c1.steps << "\n";
        }
        auto cb = yB.conflictStats();
        auto cc = yC.conflictStats();
        std::cout << "  B conf raw=" << cb.raw << " dshift=" << cb.defaultShift
                  << " | C conf raw=" << cc.raw << " dshift=" << cc.defaultShift << "\n";
        auto db = yB.parse(toPairs(lx.scan("x = 3;")), true);
        for (const auto &s : db.reduceLog) std::cout << "  B-reduce: " << s << "\n";
        return 1;
    }
    std::cout << "[auto  B] log:";
    for (const auto &s : envB.log) std::cout << " " << s;
    std::cout << "  x=" << envB.vars.at("x") << " y=" << envB.vars.at("y") << "\n";
    std::cout << "[hand  C] log:";
    for (const auto &s : envC.log) std::cout << " " << s;
    std::cout << "  x=" << envC.vars.at("x") << " y=" << envC.vars.at("y") << "\n";
    bool eq = envB.log == envC.log && envB.vars == envC.vars;
    std::cout << "[equiv] B == C : " << (eq ? 1 : 0) << "\n";
    if (!eq) return 1;

    // ---------- §6 优先级仲裁 ----------
    std::cout << "== S6 precedence arbitration ==\n";
    auto showConf = [](const char *tag, const MiniYacc &y) {
        const auto &c = y.conflictStats();
        std::cout << "[" << tag << "] raw=" << c.raw << " byPrec=" << c.byPrec
                  << " byAssoc=" << c.byAssoc << " defaultShift=" << c.defaultShift
                  << " ruleOrder=" << c.ruleOrder << " unresolved=" << c.unresolved << "\n";
    };
    tip::CalcEnv e1, e2, e3, e4;
    MiniYacc yNone = makeCalc(e1, PrecCfg{true, 3, YaccAssoc::Right, 0});
    MiniYacc yStd = makeCalc(e2, PrecCfg{});                        // ^3 右，uminus 2
    MiniYacc yUhigh = makeCalc(e3, PrecCfg{false, 3, YaccAssoc::Right, 4});   // uminus 4
    MiniYacc yCleft = makeCalc(e4, PrecCfg{false, 3, YaccAssoc::Left, 2});    // ^ 左
    showConf("no-decl ", yNone);
    showConf("standard", yStd);

    auto ev = [](MiniYacc &y, tip::CalcEnv &e, const char *prog) {
        MiniLex l(tip::calcLexRules(), tip::calcAlphabet());
        return evalOne(l, y, e, prog);
    };
    std::cout << "[10-3-2] no-decl=" << ev(yNone, e1, "print 10-3-2;")
              << "  standard=" << ev(yStd, e2, "print 10-3-2;") << "\n";
    std::cout << "[2^3^2 ] standard=" << ev(yStd, e2, "print 2^3^2;")
              << "  caret-left=" << ev(yCleft, e4, "print 2^3^2;") << "\n";
    std::cout << "[-3^2  ] standard=" << ev(yStd, e2, "print -3^2;")
              << "  uminus-high=" << ev(yUhigh, e3, "print -3^2;") << "\n";
    std::cout << "[2+3*4 ] no-decl=" << ev(yNone, e1, "print 2+3*4;")
              << "  standard=" << ev(yStd, e2, "print 2+3*4;") << "\n";
    return 0;
}
```

main 分四节，与四个断言组一一对应：

1. **§2 mini-lex**：规则表统计（15 条规则、48 字符字母表、最小 DFA 20 态）、最长匹配语料（`<=`/`<`/`==`/`=` 混排）、关键字/ID 先后翻转。
2. **§3 值栈求值**：18 条语句的计算器语料（含幂右结合、一元负号、括号、变量引用、左结合除法），每条 `print` 出值；随后打印 `x = 2+3*4;` 的完整归约日志；最后是 **oracle 对账**——7 条语料（4 好 3 坏）逐条跑值栈驱动与第 8 章 `tableParse`（同一张 LALR 表的裸驱动），accept 必须一致、接受时 steps 必须相等。
3. **§5 嵌入动作**：A 形经 `rewriteEmbedded` 自动改写成 B 形，与手写 C 形并行跑同一语料，动作日志与变量终值必须全等。
4. **§6 优先级翻转**：四套声明口径的冲突账本 + 四组翻转数据。

#### 9.7.1a　main.cpp 逐节走读

199 行驱动分六块，逐块过。

**块零：工具函数（匿名命名空间）**。

- `toPairs`：`vector<LexTok>` → `vector<pair<kind, text>>`——MiniYacc 的输入形状。两套 token 形状（LexTok 有 line 字段预留、pair 是最小面）之间的适配层。
- `printTokStream`：一行打完一条语料的 token 流——§9.2 两条仲裁法的输出面。
- `PrecCfg`：优先级口径的四元组（是否声明、`^` 的级与结合性、uminus 级）。**四个旋钮对应 §9.6.4 的四套口径**——翻转实验的全部变量集中在一个 struct 里，实验的可复现性由它保证。
- `makeCalc(env, cfg)`：按口径造 MiniYacc——规则集来自 `calcRules(env, cfg.uminus)`，声明来自四个 `setPrec` 调用（`cfg.none` 时全部跳过）。注意 uminus 的级**走的是规则字段**（rulePrec）而非 setPrec——%prec 是产生式属性、%left 是终结符属性，两条通路在代码里就是两个参数口。
- `evalOne`：跑一条语料、取 printed 的末值、清空 printed、返回数值。四组翻转实验的每格数据都经它——**每次调用独立求值，副作用（env.vars 累积）只用于变量引用**。

**块一：§2 mini-lex（输出 8 行）**。

- 构造 + `stats()`：规则数、字母表大小、最小 DFA 态数——自动机规模的体检表。
- 最长匹配语料 `"a<=b == c = d <e1 x9y 42"`：九个 token，覆盖双字符/单字符/前缀关系/字母数字混排。
- 翻转实验：拷贝规则表、把 `print` 规则移到 NUM/ID 之后、重建 Scanner——**同一个 DFA 构造器、两种声明序**，`print` 的种类号从 `print` 变 `ID`。`printx` 两次都是 ID：长度 6 赢长度 5，最长匹配压过先声明。

**块二：§3 值栈求值（输出 18 行 eval + 7 行 reduce log + 9 行 oracle）**。

- 语料是 18 条语句拼成的一条长串——**一个程序、一次 parse**，语句间靠 `prog → prog stmt` 滚雪球。变量（x/y/z/w/v/u/t/s/a1/b/c/d/e/f/g/h/i/j）先赋值后引用，覆盖：优先级（`2+3*4`）、括号（`(2+3)*4`）、右结合幂（`2^3^2`）、幂与一元负号（`-3^2`）、左结合减（`10-3-2`）、左结合除（`100/8/5`）、双重负号（`-2--3`）、标识符带数字（`a1`）、变量算术（`b = a1*2`）、嵌套幂（`2^2^3`）、括号幂（`(1+2)^2`）、括号负号（`-(-5)`）、除乘混合（`8/2*3`）、三级混合（`1+2*3^2`）、幂括号（`2^(1+2)`）、连除（`6/2/3`）。
- 归约日志单独再 parse 一遍 `"x = 2+3*4;"`——**演示语料与求值语料分离**，日志行数（7 行）恰好等于该句的归约次数，手工可对。
- oracle 对账：七条语料（四好三坏），`mine` 与 `tableParse` 逐条比 accept/steps。坏语料覆盖三种死法：缺右部（`x = ;`）、中途截断（`print 2+;`、`x = 2`）、括号不配（`(x = 4);`）。
- `agree != total` 即 return 1——**对账失败是编译失败**，不是 warning。

**块三：§5 嵌入动作（输出 5 行）**。

- `rewriteEmbedded(embedRulesA(envB), embedActions(envB))` 得 (rulesB, added)——`added` 打印出来（2 条 ε 规则）作为改写发生的证词。
- B/C 两台 MiniYacc **分别构造**（各自的 Grammar、各自的表），同语料各跑一遍——不是共享表的两次调用，改写的等价性要连表一起等价。
- `eq = envB.log == envC.log && envB.vars == envC.vars`：日志序与变量终值双断言。log 相等证明**动作执行序**一致；vars 相等证明**计算结果**一致。两个证人合起来才是完整等价。

**块四：§6 优先级翻转（输出 8 行）**。

- 四台 MiniYacc（no-decl/standard/uminus-high/caret-left）各自构造、各自 `evalOne`。
- `showConf` 打印六格账本（raw/byPrec/byAssoc/defaultShift/ruleOrder/unresolved）——§9.6.3 的账目讨论以此表为据。
- 四行数据两两对照，每行一个旋钮：`10-3-2`（声明与否）、`2^3^2`（结合性）、`-3^2`（%prec 档位）、`2+3*4`（巧合等价的对照组）。

**块五：退出协议**。

- 全部断言通过 return 0；任何一处失败 return 1——check_example 的 exit.txt 对账要求。

### 9.7.2　oracle 对账：同一张表、两种驱动、零漂移

这个实验值得专门讲设计意图。值栈驱动器是本章新写的核心代码，它对表的服从性是全部正确性的地基——**值栈的引入不允许改变任何一个分析决策**。怎么证？让第 8 章的 `tableParse`（不含值栈、不含动作、纯粹走表）当裁判：

```text
对每条语料：
  mine   = MiniYacc::parse(tokens)      ← 新驱动（值栈 + 动作）
  oracle = tableParse(grammar, table, kinds)   ← 旧驱动（裸表）
  断言：mine.accept == oracle.accept
        且接受时 mine.steps == oracle.steps
```

接受且步数相等意味着两台驱动走了**完全相同的动作序列**（每步一个动作，序列等长且每步查同一张表 → 序列相同）。拒绝语料上 accept 同为假。这就是"副本零漂移"的机器证人——不是靠人眼 diff 代码，而是靠行为等价。它还顺手保护了 §9.3.4 提到的步数口径：谁改了 `for (;; ++r.steps)` 的位置，7 条对账里立刻出现 DIFFER。

### 9.7.3　期望输出解读

```text
; expected: expected/output.txt
== S2 mini-lex ==
[stats] rules=15 alphabet=47 dfa_states=20
[longest match]
  ID('a') <=('<=') ID('b') ==('==') ID('c') =('=') ID('d') <('<') ID('e1') ID('x9y') NUM('42') 
[tie: keyword first -> print is KW]
  print('print') ID('printx') 
[tie: ID first -> print is ID]
  ID('print') ID('printx') 
== S3 value-stack parse ==
[eval 1] 14
[eval 2] 20
[eval 3] 512
[eval 4] -9
[eval 5] 5
[eval 6] 2.5
[eval 7] 26
[eval 8] 1
[eval 9] 7
[eval 10] 14
[eval 11] 256
[eval 12] 9
[eval 13] 5
[eval 14] 12
[eval 15] 19
[eval 16] 4
[eval 17] 8
[eval 18] 1
[reduce log: x = 2+3*4;]
  12: expr → NUM
  12: expr → NUM
  12: expr → NUM
  7: expr → expr * expr
  5: expr → expr + expr
  3: stmt → ID = expr ;
  2: prog → stmt
[oracle parity]
  match  accept=1/1 steps=21/21  [x = 2+3*4; print x;]
  match  accept=1/1 steps=17/17  [print (1+2)*3;]
  match  accept=1/1 steps=19/19  [x = -3^2; print x;]
  match  accept=0/0 steps=2/2  [x = ;]
  match  accept=0/0 steps=4/4  [print 2+;]
  match  accept=0/0 steps=3/3  [x = 2]
  match  accept=0/0 steps=0/0  [(x = 4);]
[oracle] 7/7 matched
== S5 embedded action rewrite ==
[rewrite] embedded markers -> 2 epsilon rules
[auto  B] log: #chk1-after-ID #chk2-after-expr stmt2-done #chk1-after-ID #chk2-after-expr stmt2-done  x=12 y=13
[hand  C] log: #chk1-after-ID #chk2-after-expr stmt2-done #chk1-after-ID #chk2-after-expr stmt2-done  x=12 y=13
[equiv] B == C : 1
== S6 precedence arbitration ==
[no-decl ] raw=90 byPrec=0 byAssoc=0 defaultShift=30 ruleOrder=0 unresolved=0
[standard] raw=90 byPrec=19 byAssoc=11 defaultShift=0 ruleOrder=0 unresolved=0
[10-3-2] no-decl=9  standard=5
[2^3^2 ] standard=512  caret-left=64
[-3^2  ] standard=-9  uminus-high=9
[2+3*4 ] no-decl=14  standard=14
```

56 行输出逐行对账（上面内嵌的是字节级真身，check_docs 保证它与示例目录里的文件一字不差）。

**S2 段（7 行）**：

- 第 1 行 `[stats] rules=15 alphabet=47 dfa_states=20`：15 条规则、47 个字符的字母表、最小 DFA 只有 20 态。**为什么 15 条规则只有 20 个状态**——数字与字母的骨架被 `<=`/`<`、`==`/`=` 共享前缀，自动机没有为每条规则各盖一栋楼；对比第 5 章单规则自动机的状态数，这里能看到"并联 + 最小化"的合并威力。
- 第 2–3 行最长匹配语料：`ID('a') <=('<=')` 确认 `<=` 整体成词（长度仲裁）；`<e1` 处 `<('<')` 单独成词、`ID('e1')` 随后独立——贪心循环在 `e` 处转移失败、**回退到最后接受点** `<`，这正是 §9.2.2 法则一的可观察行为；`x9y` 整体一个 ID（字母开头的字母数字串）；`42` 是 NUM。
- 第 4–5 行 vs 第 6–7 行翻转：`print('print')` 与 `ID('print')`——**同一个词、两种命运，唯一的变量是声明顺序**。`printx` 两次都是 `ID('printx')`：长度 6 的 ID 匹配胜过长度 5 的关键字，**最长匹配压过先声明优先**——两条法则的次序（先比长度、同长才比声明序）在这两行里直接可读。

**S3 段（39 行）**：

- 18 个 `[eval N] V`：`14/20/512/-9/5/2.5/26/1/7/14/256/9/5/12/19/4/8/1`。逐条手算验证：
  - eval 1 `x = 2+3*4` → 14：`*` 先归约。
  - eval 2 `y = (2+3)*4` → 20：括号强制 `+` 先成句柄。
  - eval 3 `z = 2^3^2` → 512：`^` 右结合，2^(3^2)。
  - eval 4 `w = -3^2` → -9：`^`(3) 压过一元负号(2)，-(3^2)。
  - eval 5 `v = 10-3-2` → 5：左结合 (10-3)-2。
  - eval 6 `u = 100/8/5` → 2.5：左结合 (100/8)/5——也是 `fmt` 六位有效数字的浮点输出口径。
  - eval 7 `t = 2*3+4*5` → 26：两个乘法各自先归约。
  - eval 8 `s = -2--3` → 1：词法切成 `- 2 - - 3`、语法是 `(-2) - (-3)`——一元负号在二元减号后照常起跳；规则表里没有 `--` token，两个 `-` 依次成词。
  - eval 9–10 `a1 = 7; b = a1*2` → 7/14：标识符带数字 + 变量引用。
  - eval 11 `c = 2^2^3` → 256：右结合 2^(2^3)——与 eval 3 一起夹击"幂是右结合"。
  - eval 12 `d = (1+2)^2` → 9；eval 13 `e = -(-5)` → 5：括号包负号。
  - eval 14 `f = 8/2*3` → 12：同级左结合，先除后乘——**不是**先乘后除。
  - eval 15 `g = 1+2*3^2` → 19：三级优先一锅炖，1+(2*(3^2))。
  - eval 16 `h = 10-2*3` → 4；eval 17 `i = 2^(1+2)` → 8；eval 18 `j = 6/2/3` → 1：连除左结合。
- 归约日志 7 行（`x = 2+3*4;` 的完整时刻表）：三个 `expr → NUM` 体现"读到就归约"的左递归节奏；`expr → expr * expr` 排在 `expr → expr + expr` **之前**——优先级在归约序里现形（`*` 先成句柄）；`stmt → ID = expr ;` 与 `prog → stmt` 收尾。这张 7 行的时刻表值得对着 §9.3.3 的归约五步在纸上逐步推演一遍。
- oracle 段 9 行：4 条接受语料 `accept=1/1 steps=21/21`、`17/17`、`19/19` 型两两相等——**值栈的加入没有改变任何一步**；3 条拒绝语料 `accept=0/0` 且步数一致（2/2、4/4、3/3）。`(x = 4);` 的 0/0 步死法值得想清楚：第一个 token 是 `(`、表里明明有它的 shift——为什么 0 步？因为 0 步的计数口径是"完成的动作数"，而它死于**第一个**查表失败（细节留给练习 3）。
- `[oracle] 7/7 matched` 是本组断言的总判词。

**S5 段（5 行）**：

- `[rewrite] embedded markers -> 2 epsilon rules`：两个占位符各自升格为 ε 非终结符。
- `[auto B]` 与 `[hand C]` 两行除标签外逐字符相同：log 序 `#chk1-after-ID #chk2-after-expr stmt2-done` 两遍（两条语句），变量终值 `x=12 y=13`（3*4=12、12+1=13）。
- 动作序的语义正确性：`#chk1`（ID 刚进栈）→ `#chk2`（expr 刚归约）→ `stmt2-done`（整句归约）——嵌入动作确实在"半路"执行，靠的是 ε 归约恰好落在那个位置（§9.5.5 的十二步时刻表是它的展开形态）。
- `[equiv] B == C : 1`：自动改写与手写改写在日志序与变量终值上双对账通过。

**S6 段（6 行）**：

- `[no-decl ] raw=90 byPrec=0 byAssoc=0 defaultShift=30`：不声明时 30 个唯一冲突格全部缺省移进——效果是运算符右结合化（`10-3-2` 因此得 9）。
- `[standard] raw=90 byPrec=19 byAssoc=11 defaultShift=0`：19 格优先级高下立断、11 格同级看结合性、**零缺省**——声明恰好覆盖全部冲突（§9.6.3 的"零缺省"讨论）。
- 四行翻转数据各对一个旋钮：`10-3-2` 9→5（声明的有无）、`2^3^2` 512→64（结合性）、`-3^2` -9→9（%prec 档位）、`2+3*4` 14→14（巧合等价的对照组——§9.6.4 的告诫：别拿这行当"声明没用"的证据）。

### 9.7.4　工程注意点

1. **步数口径**是 oracle 对账的命门——计数语句放在循环的哪个位置，最好写成与被对账方逐字相同的形状（`for (;; ++steps)`）。
2. **冲突账本要区分入账数与唯一格数**：`raw` 是朴素计数，同一格可能多次入账；去重后再分类计数，账才平（60 = 19+11+30）。
3. **惰性仲裁**让"构造后声明"成为合法使用顺序，代价是 `parse/table/conflictStats` 都要保证先 `ensureResolved`——漏一处就用到了未裁决的表，这类错误在并发/缓存场景下会变成 Heisenbug。教学代码选择在三个出口统一收口。
4. **标签联合的错误要带调用点名字**（`asNum("stmt: $3")`）：报错信息里没有 `$3` 这个名字，用户就得反推是哪次取值炸了。代价是每处调用多打一个字符串字面量——值得。

### 9.7.5　本章开发的真坑复盘（五个，全部真实发生）

这个教程的传统是把开发过程中的真实事故写成案例——它们比虚构的"最佳实践"更有教学价值。本章五个坑，按六段式记账：症状、定位、根因、修复、防复发、迁移。

**坑一：模式串里的元字符（症状：`regex 位置 1: 缺右括号`）**。

- 症状：程序启动即抛异常，第一个 lex 规则就建不起来。
- 定位：异常来自 `parseRE`；逐条规则二分试跑，锁定 `{"(", "("}`——模式就是单个左括号。
- 根因：`(` 在迷你正则里是**分组元字符**，模式 `"("` 是一个未闭合的组。同理 `"*"` 是"空串的星号"（缺操作数）。规则表要给运算符 token 建模式，而运算符恰好是正则的元字符——**lex 手册里运算符模式全部带引号或转义，不是排版习惯，是刚需**。
- 修复：`"\\*"`、`"\\("`、`"\\)"`——第 5 章副本的转义符（`\` 后一律字面量）恰好覆盖。
- 防复发：规则表生成器可以加一条 lint（模式里未转义的元字符直接出现在单字符规则中时警告）；教学版靠注释与本章复盘。
- 迁移：写任何"数据即语法"的系统（SQL 拼接、shell 命令、本例的正则模式）时，**载荷字符集与协议元字符集的交集**是第一顺位检查项。

**坑二：token 名字撞了字符串协议（症状：含括号语料全部拒绝）**。

- 症状：`x = 2;` 通过，`y = (2+3)*4;` 拒绝——四条含括号语料全军覆没。
- 定位：打印 token 流发现括号 token 的 kind 是**空串**——查表落空，Err。
- 根因：第 5 章 Scanner 的产物是 `NAME('text')` 文本，MiniLex 拆包以第一个 `(` 为界；名字 `(` 让 `substr(0, lp)` 取到空前缀。
- 修复：token 更名 `LPAREN/RPAREN`——名字回到安全字符集。
- 防复发：接口文档写明"NAME 不得含 `(`"；或者更根本地，产物改成结构化类型而不是字符串协议（教学上保留字符串协议是为了与第 5 章对账零漂移——两难时的取舍要写进注释）。
- 迁移：**自定义文本协议的定界符不能出现在载荷任何一侧**。CSV 的逗号、URL 的 & 与 =、本例的括号，同一家族的事故。

**坑三：两套编号差一（症状：`悬空符号 expr`）**。

- 症状：§5 的 embed 语料构造 MiniYacc 时抛"悬空符号 expr"。
- 定位：报错来自构造器的 rhs 检查；打印规则表发现 stmt2 的 rhs 写了 `expr`，而规则定义的 lhs 是 `expr2`——一个手滑。
- 根因：人文笔误，但能活到运行期是因为规则表在 C++ 里是裸字符串、没有编译期拼写检查。**字符串符号表把类型检查从编译期推迟到运行期**，这是第 8 章副本选择可读性时一起选进来的代价。
- 修复：`expr` → `expr2`。
- 防复发：构造器的悬空符号检查就是防复发网（它抓的正是这类手滑）；更根本的方案是符号 intern 成整数（bison 的内部表示），教学版不做。
- 迁移：所有"字符串当标识符"的系统（SQL 表名、配置键、本例的文法符号）都要在入口设一张**声明的符号表**并拒绝未声明者——晚拒绝好过静默穿透。

**坑四：占位符校验误杀改写产物（症状：§5 一进构造就抛异常）**。

- 症状：§5 构造 yB 时抛"嵌入动作须先经 rewriteEmbedded 展开: #chk1"——但 rulesB 明明**就是**改写产物。
- 定位：异常消息直指校验分支；读代码即见——校验条件是"rhs 里出现 `#` 起头符号"，而改写产物里 `#chk1` 是合法非终结符（有 lhs 定义）。
- 根因：校验的本意是拦"**未改写**的占位符"，写成了拦"一切 `#` 符号"。防御性检查的谓词写宽了，把自己人当敌人。
- 修复：先收集全部 lhs，`#` 符号**有 lhs 定义则放行**。
- 防复发：防御检查要对着"坏样本的精确特征"写谓词，而不是对着"表面特征"写；写完自问一句"合法路径上有没有东西长得像坏样本"。
- 迁移：输入校验的假阳性比假阴性更隐蔽——假阴性至少会炸在后面，假阳性直接拒绝合法用户。**校验谓词的最小化**（只拦确定坏的）是默认取向。

**坑五：惰性化没删干净旧调用（症状：账本数字对不上任何解释）**。

- 症状：§6 冲突账本显示 `byPrec=19 byAssoc=11 defaultShift=30`——但用一次性转储程序数出唯一冲突格只有 30 个，三个计数器的和却是 60。所有语料的**求值结果全对**，只有账是错的。
- 定位：给仲裁循环加"每处理一格打印一行"的探针，重跑发现 30 个格子**每个都打印了两遍**——仲裁跑了两整趟。
- 根因：把仲裁改成惰性（`ensureResolved`）时，`buildTable()` 末尾的旧 `resolveConflicts()` 调用**忘了删**。于是构造期先跑一遍（此时 setPrec 还没来，全部落入 defaultShift），首次使用时又跑一遍（这次带着声明，byPrec/byAssoc 正确）——计数器是成员变量，两遍**累加**；action 表被第二遍正确覆写，所以行为对、账错。这是"惰性化改造"的经典残留：把入口改成按需触发，却没删掉原来的急切调用。
- 修复：删掉 `buildTable` 里的调用，函数注释里记下这次事故（yacc.cpp 里那段"删调用要删干净"的注释就是它）。
- 防复发：计数器账本要能**对上独立测量**——本章的正是一次外部对账（转储程序数格数 vs 计数器求和）抓住了它。内部统计若无外部交叉验证，翻倍/减半错误可以存活很久（行为无恙时尤其如此）。
- 迁移：任何"从急切改为惰性"的重构（缓存、单例、连接池）都要**全文搜旧调用点**；惰性化的正确性证明里必须包含"旧路径已死"这一条。

五个坑的共性：全部出在**两个世界的接缝上**（正则世界与字符世界、文本协议与结构化数据、两套编号、防御与放行、急切与惰性）。接缝是 Bug 的集散地——这句经验值回票价。

### 9.7.6　源码导览地图

九个源文件、56 行期望输出在本章正文里的落点，一张索引表（按阅读次序）：

| 文件/产物 | 行数 | 正文落点 | 一句话角色 |
|---|---|---|---|
| src/re.hpp | 103 | §9.2.3 | 第 5 章自动机接口（本章裁掉 Brzozowski 声明） |
| src/re.cpp | 441 | §9.2.3 + 走读 9.2.3a | RE→NFA→DFA→Scanner 四段旅程（Lex 心脏正身） |
| src/lr1.hpp | 84 | §9.3.2 | 第 8 章造表接口（裁 SLR 支路、导出 goTo） |
| src/lr1.cpp | 279 | §9.3.2 + 走读 9.3.2a | FIRST/闭包/LR(1)/LALR/填表六关 |
| src/yacc.hpp | 144 | §9.3.4 | 值栈驱动器接口：YaccValue/Rule/MiniYacc |
| src/yacc.cpp | 201 | §9.3.4 + 走读 9.3.4a | 构造/仲裁/parse/改写四件实现 |
| src/demo.hpp | 67 | §9.2.4 | MiniLex 与计算器语言的接口 |
| src/demo.cpp | 212 | §9.2.4 + 走读 9.2.4a | 拆包/规则表/十条产生式/嵌入对照文法 |
| src/main.cpp | 199 | §9.7.1 + 走读 9.7.1a | 四组断言的驱动 |
| expected/output.txt | 56 | §9.7.3 | 全部断言的期望真身（逐行解读） |

三处副本改动（相对第 5/8 章原版）全部是**裁剪或导出**、无行为修改，逐一可验：

- re.hpp/re.cpp：删 Brzozowski 最小化块（本章只用分割式最小化；删除的 ~95 行是第 5 章 5.5 节的主角，那章仍完整讲述）；
- lr1.hpp/lr1.cpp：删 SLR 支路（followSets/buildSLR，第 7/8 章的对照件；本章只走 LR(1)→LALR 路线）+ 把 goTo 移出匿名命名空间并导出（仲裁器重算移进候选）；
- 裁剪遵循"删整块、不动留下的行"——diff 上只见删除块与两处边界注释，留下的代码与原章逐字相同。

这份"裁剪清单"本身就是教学法：读者拿着第 5/8 章的全文与本章副本 diff，看到的正是"Lex/yacc 心脏需要自动机理论的哪些部件"——**需求驱动的裁剪是理解的试金石**。

### 9.7.7　一条语句的一生：从源文本到 56 行输出的末行

把全部机制串成一条时间线，以 `print -3^2;`（§6 的翻转语料）在 uminus-high 口径下为例：

1. 规则表先行：`calcLexRules()` 造 15 条规则，`MiniLex` 构造器把它们并联成 NFA、子集构造着色、最小化出 20 态 DFA。
2. 文法与声明：`calcRules(env, 4)` 造十条产生式（一元负号带 rulePrec=4），`makeCalc` 里五个 setPrec 登记 + - * / ^。
3. 造表：构造器内 buildLR1 产出规范族、buildLALR 同心合并；90 条冲突入账，账本 raw=90，此时尚未裁决。
4. 首次 parse 触发 ensureResolved：30 个唯一冲突格逐一重算候选、投票——`expr → - expr`(级 4) 在 `^`(级 3) 面前归约获胜，这正是 uminus-high 语义进入表的时刻。
5. 词法：`scan("print -3^2;")` 吐七个 token：print/-/NUM(3)/^/NUM(2)/;（贪心循环每步记最后接受点）。
6. 语法与求值：值栈驱动走 19 步——`-` 移进、3 归约成 expr、**在 `^` 面前归约 `expr → - expr`**（第 4 步埋的裁决在这里兑现）、(-3) 平方得 9、print 收尾。
7. 侧通道：动作把 "9" 推进 env.printed；evalOne 取末值返回。
8. 输出：main 把 9 与对照值（standard 口径的 -9）拼进翻转行——期望 output.txt 的倒数第二行。

八个阶段里"语义在哪里变成行为"只发生在一处：第 4 步的投票。**声明是语言设计、裁决是语言实现、求值是语言行为**——三段式在本章机器里是三次可断点的打印。

### 9.7.8　与前后章的接口冻结

本章对外承诺的稳定接口（后续章复用时不得漂移）：

- `MiniYacc::parse` 的 RunResult 形状——第 10 章错误恢复要扩展 diags 字段（追加，不改现有五字段）；
- `LexTok` 预留的 line 字段——第 10 章检测位置对照表的地基；
- `rewriteEmbedded` 的 (rules, embeds) 双输入——嵌入动作的构造约定不变；
- 05/08 副本的裁剪版——后续章若再复用 re/lr1，以**本章裁剪版**还是原章全文为准？**以原章全文为准**：裁剪是本章的教学叙事，不是接口演进。这条约定与匠书轮"Op 枚举冻结"同性质——冻结的是语义，不是字节。

## 9.8　三路对照：手写递归下降 / Pratt / yacc 心脏

前端三部曲至此凑齐三种"优先级住哪儿"的答案，合一张总账：

| 维度 | 分层函数（第 6 章） | Pratt 表（第 11 章） | yacc 声明（本章） |
|---|---|---|---|
| 优先级住在 | 调用图的层级 | 一张 (prec, 回调) 表 | %left/%right 声明段 |
| 表谁算 | 人脑 | 人写表、机器执行 | **机器从文法算出 LALR 表** |
| 结合性表达 | 递归层级（左=同级、右=+1） | 同上 | 声明的结合性标志 |
| 新增运算符 | 加一层函数、改三处 | 表里加一行 | 文法加一行 + 声明加一段 |
| 左递归 | 不允许（须消除） | 天然左结合循环 | 天然支持（还偏爱） |
| 值的传递 | 函数返回值 | 回调返回值 | 值栈 + $$/$n |
| 错误恢复 | 过程级同步集 | 前缀回调里自查 | error 记号（第 10 章主场） |
| 工业代表 | gcc、clang、V8 | clox、部分脚本引擎 | bison：Ruby、PostgreSQL、PHP |

三行答案各有其不可替代性：分层函数是理解的地基（第 6 章用它讲清 FIRST/FOLLOW）；Pratt 是手写表达式的性价比之王（一张表管所有中缀）；yacc 是"文法即规格"的极端——表完全由机器推导，人的输入只有文法与声明。**生成器把文法抬高到"唯一事实源"**：改语言 = 改文法，表重造，动作不动。这是 1975 年那次革命的遗产，也是今天 bison 仍在服役的原因。

值栈机制本身也有后续：第 13 章的 S-属性文法是它的理论名分（综合属性 = 归约时从子节点算父节点）；第 65 章 TM 机器的 tmpOffset 软件临时栈是它在目标机上的远亲（压左操作数、算右操作数、弹回做运算——同样的"两值进一值出"节奏，只是家从值栈搬到了数据存储器）。

### 9.8.1　选型实战：什么时候不用生成器

三路对照之后是工程界的真问题：新手该用什么？团队该用什么？答案没有悬念但有层次：

- **原型与课程**：bison/ANTLR 仍是最快路径——文法即规格，半天出前端。本章证明的"机制可手写"不等于"应该手写"。
- **成熟语言的工业实现**：gcc、clang、V8、Go 全是手写递归下降。原因不在性能（生成器的表驱动也不慢），而在**控制力**：错误恢复要贴诊断系统（第 10 章会看到生成器的恢复策略有多受限）、增量解析要贴 IDE、语义动作要贴类型检查的时机——生成器的"动作只在归约时"框架在这些需求面前太紧。
- **中间地带**：Ruby 用 bison 但配大量语义中绵；PostgreSQL 的 gram.y 两万行、靠 %prec 与有限状态词法撑住——**生成器 + 工程纪律**能走很远。
- **教学**：本教程的路线——先手写（第 6/11 章）、再用生成器（第 4 章）、再手写生成器心脏（本章）——三轮之后，无论将来站在哪一阵营，都知道对方阵营的地基长什么样。

## 9.9　小结与练习

本章把 lex 与 yacc 的心脏亲手实现了：Lex 心脏 = 第 5 章多模式 Scanner 的正身（规则表 + 最长匹配 + 先声明优先，零改动复用）；Yacc 心脏 = 第 8 章 LALR 表之上的值栈驱动器（双栈平行、归约五步、动作只在归约时执行）；再加上三件 yacc 家族的传家宝——%union 带标签联合、嵌入动作的空产生式改写、优先级/结合性的四条仲裁规则。全部机制有机器证人：18 条求值语料、oracle 步数对账 7/7、嵌入改写等价 B≡C、四组优先级翻转。

**产出型自查**（能不看书回答再往下走）：

1. 不看 §9.3.3，默写归约五步，标出每步动哪条栈。
2. 不看 §9.6.1，复述仲裁四规则，并说出 `%prec` 解决的是四条里哪一条的什么缺口。
3. `y = (2+3)*4;` 的归约日志共几行、每行是什么？（答案在 §9.7.3 的方法里，不在输出里——它是 §9.7 输出没有的语料，正好当考题。）
4. 把 MiniLex 的规则表里 `NUM` 挪到 `ID` 之后，哪些语料的 token 流会变、为什么？
5. 为什么 `expr → ( expr )` 必须显式动作，而 `expr → NUM` 可以省？

**练习**（建议全部动手；前六题有解答要点附后）：

1. 给 demo 文法加一个 `%prec UMINUS` 风格的一元加号 `expr → '+' expr`，优先级与 UMINUS 同档。跑 `+2^2`，预期输出是什么？再把它声明成与 `^` 同级，输出变成什么？
2. 把 `print` 规则从 calcLexRules 里删掉，改用"ID 规则 + 语法动作里查关键字表"实现关键字。这更接近某些真实前端的"软关键字"路线。代价与收益各是什么？（提示：yylval 里得装下"可能是关键字"的信息。）
3. 在 oracle 对账里加入语料 `x = (2+;` 与 `x = )2(;`，手工预测 accept 与 steps，再跑验证。
4. 修改 `MiniYacc::parse` 的步数计数（把 `++r.steps` 挪到循环体首行），重跑 oracle 对账——观察哪几条语料 DIFFER，解释为什么接受语料全都差一、拒绝语料差一不固定。
5. 给 MiniYacc 加 `%prec` 缺失检查：一条产生式最右终结符无声明、又没有 rulePrec、还参与了 shift/reduce 冲突时，打印警告而不是静默缺省移进。在 demo 的 standard 口径下它会报几条？
6. 把 demo 文法的 `prog → prog stmt` 改成右递归 `prog → stmt prog`，重跑全部语料。接受性应不变——但归约日志的顺序变了。画出两种文法下 `x = 1; y = 2;` 的归约时刻表，说明"边读边并"与"读完再并"对内存峰值的含义。
7. 给规则表加大写字母（A-Z），观察 stats 里 alphabet 与 dfa_states 各涨多少，解释增量来自哪些共享路径的破坏。
8. 在 rewriteEmbedded 里支持"同一占位符在多条规则里出现"（共享一条 ε 规则）与"同一规则里出现两次同一占位符"两种情形，各写一个语料验证动作执行次数。
9. 把 oracle 对账扩展到 §5 的嵌入文法：yB 与一个"表驱动无值栈"的裸跑（对 yB 的表调 tableParse）也做 accept/steps 对账。需要修改哪些代码？
10. 用 MiniYacc 实现一个 BOOL 文法（`and/or/not`，声明 `not` 最高右、`and` 左、`or` 左），复现 §9.6 的翻转实验风格：`a or b and c`、`not a or b` 两组数据。
11. （大题）给 MiniYacc 加 `error` 记号：识别含 error 的产生式、错误时丢弃输入到同步集、归约恢复态、yyerrok 复位。这是第 10 章的预演——做完这题，第 10 章的 LR 侧你已经提前写完了。
12. （大题）把 MiniYacc 的输出从"求值"改成"构 AST"：YaccValue 加 Node 槽、动作改为建树。得到的树与第 12 章 ANTLR 路线的树逐节点 diff。两代生成器的树形状差异（如有）来自哪里？

**本章术语速查（一句话词典）**：

- **yylval**：lex 与 yacc 之间唯一的值信道——全局变量、类型由 %union 决定；本章对应移进时压值栈的那个值。
- **yytext**：刚匹配到的 token 原文；本章对应 LexTok.text。
- **值栈**：与状态栈平行的第二条栈，每格住着"导致进入该状态的符号的值"。
- **$$ / $n**：归约动作里的两个伪变量——结果槽与第 n 个右部符号的值（1 基）。
- **%union**：值栈元素类型的带标签联合声明。
- **%type / %token<>**：符号与 union 槽位的登记（静态类型检查的依据）。
- **%left / %right / %precedence**：终结符的优先级与结合性声明；声明次序即级差。
- **%prec**：产生式优先级的显式覆盖——给"最右符号是非终结符"的规则补级。
- **嵌入动作**：写在产生式右部中间的代码块；机制上是空产生式改写。
- **最长匹配（maximal munch）**：词法仲裁法一——能吃多长吃多长。
- **先声明优先**：词法仲裁法二——同长时规则表里靠前的赢。
- **归约五步**：定位产生式、弹值、弹栈、算 $$、压回。
- **活前缀**：LR 栈内容永远是某句型的规范前缀——LR 检测能力的来源（第 10 章主场）。
- **LALR(1)**：同心合并后的 LR(1)——yacc 的表规格。
- **冲突账本**：byPrec/byAssoc/defaultShift/ruleOrder 四个计数器——裁决依据的流水。
- **oracle 对账**：同一张表、两种驱动，accept 与 steps 必须一致——零漂移的机器证人。
- **ε 归约**：空产生式的归约；嵌入动作的执行时机由它的 lookahead 许可证决定。

**常见问题（FAQ）**：

- **问：为什么不直接装 bison/flex 学？** 答：装了也该手写一遍——生成器把机制藏进表里，学习者看到的是声明与结果，中间的"值栈怎么动、冲突怎么裁"是黑盒。本章机器让每一步可打印、可对账；学完再回头看 §9.1.4 的 .y 真身，黑盒变白盒。工具链自包含也是本教程的硬约束（不污染读者的机器）。
- **问：MiniYacc 的 parse 为什么不是 const 成员？** 答：首次调用触发惰性仲裁（写表与计数器），语义上是"预热"而非"只读"。const_cast 的两个取值接口（table/conflictStats）是同一事实的妥协包装——教学代码选择显式非 const 的 parse，把"会变"写在签名上。
- **问：demo 文法的 90 条冲突入账里，为什么一个格会入账多次？** 答：fill 的 setAct 在"同格两异动作"时入账——一格撞进三个动作（五个运算符的冲突态常有）记两次。去重后 30 格才是真实规模；账本四个计数器按去重后计。
- **问：为什么 %prec 只在 unary 场景出现？** 答：二元运算符的最右符号就是自己（优先级自然有）；只有"最右符号是非终结符"的规则（一元负号、if-else、dangling 结构）才需要显式补级。看到 %prec 就要想"这条规则的最右是啥"。
- **问：嵌入动作和 ANTLR 的 enterRule 监听器等价吗？** 答：不完全。嵌入动作的触发时机由 ε 归约的 lookahead 许可证决定——"最近的完整句柄之后"；enterRule 在规则一开始就触发。差异在 `x = a + {嵌入} b` 这类中途场景里可观察（§9.5.5 的最后一段）。
- **问：值栈和 AST 树构建可以同时用吗？** 答：可以且常见——动作建树（$$ = new Node($1, $3)），值栈里跑的是指针。本章求值是"树都不建直接算"的极简路线；练习 12 是它的建树版。
- **问：冲突全消掉不好吗？为什么留 30 个？** 答：这 30 个是**表达式文法的本性**——优先级与结合性本来就是"语义决策"而非"结构决策"，声明就是它们的正确居所。硬要消掉等于把语义焊进文法形状（第 6 章路线），两代人的经验都证明那更难维护。
- **问：本章机器能解析多大的文法？** 答：LALR 构造是 O(状态数 × 闭包)，字符串符号的哈希开销让万行级文法会很慢；bison 用整数符号与压缩表撑住两万行的 PostgreSQL gram.y。教学机器的适用域是千行以下——够讲清全部机制。
- **问：`y = x+1;` 里 expr2 → ID 的动作查不到变量会怎样？** 答：抛 undefined variable 异常——语法接受、语义失败，两层的边界正在这里。真实编译器会在语义分析阶段（第 12 章起）用符号表拦截，而不是等求值炸。
- **问：为什么 demo 的 print 语句值要绕道 env.printed 而不直接 cout？** 答：对账协议需要**全部输出可捕获、可逐字节比对**（expected/output.txt），侧通道收集再统一打印是教程四层验证的常规姿势（第 4 章起一直如此）。

**与 L 书的取材对照**（本章各节的原书出处，便于读者回溯语境）：

| 本章 | L 书 | 主题 |
|---|---|---|
| §9.1 | §1.2 编译器的伙伴、§5.0 | 工具族谱与动机 |
| §9.2.1–9.2.2 | §2.6.1 Lex 约定、§2.6.2 输入文件格式 | 三段式与仲裁法 |
| §9.2.3 | §2.3–2.4（经由第 5 章） | 正则→自动机 |
| §9.3 | §5.4（值栈与语法分析）、§5.5.1–5.5.2 | Yacc 心脏 |
| §9.4 | §5.5.5 任意值类型 | %union |
| §9.5 | §5.5.6 嵌入的动作 | 改写与陷阱 |
| §9.6 | §5.5.3 冲突消除、§5.5.4 执行描述 | 仲裁规则 |
| §9.7 | 本章自创（教程的机器证人口径） | 对账实验 |
| §9.8 | 教程综合（三本书的前端线收束） | 谱系定位 |

原书各节还有本章未展开的边角（Lex 的起始状态切换、yacc 的继承属性中绵、错误记号全貌），凡与第 10/12/13 章重叠的一律留到那些章的正场——教程的分工优先于书的目录。

**前六题解答要点**：

1. UMINUS 同档（低于 `^`）：`+2^2` 得 +(2^2)=4；与 `^` 同级且右结合看结合性声明——若 `+` 一元声明为右结合，得 (+2)^2=4；关键是想清楚"同级时结合性才说话"。
2. 收益：关键字表可动态增（上下文关键字）；代价：ID 的动作要区分"关键字/标识符"两种身份，yylval 得带双信息或动作里回查表——这正是 §9.4 标签联合的扩展场景。
3. `x = (2+;`：`( 2 +` 后遇 `;`，无动作（`+` 后要 expr），死在第 5 步左右——具体步数自己数，方法见 §9.7.3 拒绝语料的口径讨论；`x = )2(;`：第一个 `)` 即死（0 步完成动作）。
4. 接受语料：Acc 迭代的计数差一（口径变化在每条语料上等量）；拒绝语料：死得越早差越不可预测（0 步死的语料从 0 变 1，晚死的差一）——**口径差对不同结局的影响不对称**。
5. standard 口径下 0 条：defaultShift=0 说明没有产生式落在"参与冲突但无优先级"的分支（demo 的 30 个冲突格全被声明覆盖）。这个检查的真正价值在 no-decl 口径：会报 30 条。
6. 左递归：归约序 `stmt, prog→prog stmt, stmt, prog→prog stmt`（边读边并，值栈峰值低）；右递归：`stmt, stmt, prog→stmt prog, prog→stmt prog`（读完再并，栈深随语句数线性涨）。**左递归是 yacc 的"流式"口味，右递归是它的"批处理"口味**——内存账完全不同。

**练习 7–12 解答要点**：

7. 大写字母把字母表从 47 涨到 73（+26）；dfa_states 的涨幅远小于 26——大写与小写共享"字母态"的转移结构（同是"ID 字符类"的成员），最小化按行为分割、不看字符身份。真正会涨态的是**破坏共享前缀**的新规则（比如三字符运算符）。
8. 同一占位符出现在两条规则：rewriteEmbedded 的 `emitted` 集合保证只造一条 ε 规则——两处引用共享同一非终结符，动作各执行一次（共两次）；同一规则里出现两次 `#chk`：第二次出现被 `emitted` 跳过（已是非终结符，rhs 无需改），两个位置各自触发 ε 归约——动作仍执行两次，但**先后由 lookahead 决定**，构造语料（两个位置夹不同符号）可观察次序。
9. yB 的表驱动裸跑：`tableParse(yB.grammar(), yB.table(), words)`——但 tableParse 是 08 副本的函数、yB 的表已仲裁过，直接调即可；要改的只有 main（加对账块）与 oracle 断言（B 的 accept/steps 与 mine 一致）。陷阱：yB 的 parse 已跑过（ensureResolved 已触发），table 拿到的就是裁决后的表——顺序不能反。
10. BOOL 文法的关键声明：`%right NOT`（或 %precedence）高于 `%left AND` 高于 `%left OR`；`a or b and c` 的翻转对照是 `or`/`and` 声明对调；`not a or b` 验证 NOT 的高档——`(not a) or b` 还是 `not (a or b)` 由级差决定。
11. error 记号的三个改动点：MiniYacc 接受含 `error` 伪终结符的规则（校验放行 + terms 注册）；parse 的 Err 分支改为"弹栈到能移进 error 的状态、丢弃输入到该状态可接受的同步集"；yyerrok 对应一个动作名约定（复位后清恢复态）。做完后第 10 章的 LR 侧就是复习。
12. 两棵树的形状差异来源：本章左递归文法天然产出**左倾斜的迭代形树**（prog 是链表状的 stmt 序列），ANTLR 的右递归版产出右倾斜——语义等价、打印不同；diff 脚本要先归一化（链表方向）再比。这个差异正是两代生成器"文法口味"在数据上的投影。
