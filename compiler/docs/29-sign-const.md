# 第 29 章　扁平常量格：常量传播与可靠性的经验检验

## 29.1 本章目标

第 25 章到第 28 章搭好了数据流分析的完整流水线：符号格给出
抽象域与抽象算术，格构造子给出把简单域组装成程序状态的方法，
单调方程组把分析写成规格，worklist 求解器把规格解成最小不动
点。四章合起来，我们已经对 sign1.tip 给出了"每个程序点每个
变量的符号"这样一份静态预测。但整套机器目前只回答一类问题
——"值的符号是什么"。本章换一个域，验证流水线的通用性；
再换一种验证结论的方式，回答一个此前从未正面回答的问题：
**静态分析的结论，凭什么可信？**

前半章做常量传播（constant propagation）。它问的不是"值的
符号"，而是更精细的问题："这个变量的值是否**确定地**是某个
具体的整数？"如果 `a = 3 + 4 * 2`，那么此后每个读 a 的地方
读到的都是 11——这不是概率性的猜测，而是一个可以形式化并
可以证明的事实。承载这个事实的抽象域叫**扁平常量格**：
每个变量取值 ∈ {⊥, c, ⊤}，其中 c 是任意一个具体的整数。
域换了、传递函数换了，但第 28 章的 worklist 骨架一字不动地
复用——同一个求解器，喂进不同的格与传递函数，就得到一个
全新的分析。这是"格抽象化"设计红利最直白的兑现时刻。

后半章是本章真正的重头戏：**可靠性的经验检验**。spa 第 1.3
节给出可靠性的经典定义——静态预测必须覆盖具体执行的一切
可能行为，即具体值经抽象化（concretization）后必须落在静态
预测之内。定义是理论性的，检验却可以是经验性的：本章让
程序**真的跑起来**。同一个程序，两条独立的执行通道——一个
直接在 AST 上解释执行的具体解释器，一个经 LLVM IR 生成加
ORC JIT 编译到机器码的真实执行——在多组输入下产出输出序列；
再由解释器记录"第 k 次输出出自哪条 output 语句"，把每个
具体值映射回它所在的程序点，逐点与静态预测对账：具体值的
符号必须 ⊑ 静态预测的符号（成员检验），静态预测为确定常量
处 JIT 值必须逐点相等（相等检验）。任何一处违反，程序打出
UNSOUND 并退出非零。理论上的可靠性定义，在这里变成了一条
可反复执行的回归防线。

最后把我们的常量分析与 LLVM 的 SCCP 做一次对照。同一个
前端（第 15 章的 IRGen）产出的 IR，交给 `opt -passes=sccp`
和交给我们的常量分析，各自能折叠掉什么、不能折叠掉什么，
两栏并排——这一对照会把"稀疏"与"稠密"、"SSA 边"与
"程序点环境"两组概念的区别钉在具体输出上。

### 29.1.1 与 spa 原书章节的对应

扁平常量格是 spa 第 4 章在讲完符号格之后给出的第二个标准
例子（4.1 节的 Flat 域）：同一个不动点框架，换一个抽象函数
γ，就得到另一个分析。spa 把可靠性定义放在第 1 章但全书的
例子都止步于"应该如此"；本书把 1.3 节的定义落实为一个
可执行的对账程序——这层工程化是 spa 没有展开的。SCCP
（sparse conditional constant propagation）不在 spa 的
叙述里，它是 LLVM 生态里常量传播的工业形态，第 29.7 节
用真实输出把它与教科书形态接上。

### 29.1.2 阅读路线

17.2 建立扁平格与 cJoin 三规则，回答"为什么扁平"和"除零
为什么入 ⊥"。17.3 逐段拆解常量传递函数：表达式折叠、
⊥ 传染与 ⊤ 吸收的对称直觉。17.4 说明同一个 worklist 引擎
如何因换格而换分析。17.5 搭建经验检验的三方对账：解释器、
JIT、静态预测，并给出正确性论证里最关键的一环——"第 k 次
输出对应哪条 output 语句"的映射必须建立在同一次语法分析
之上。17.6 逐行解读两个实验程序的真实输出。17.7 与 SCCP
对照。17.8 简短交代本章复用的前几章机器。17.9 工程注意点，
17.10 练习，17.11 小结。

读者需要的前置只有两样：第 28 章的 worklist 求解（特别是
28.3 节"弹出—重算—写回—入队"的骨架）与第 25 章的符号
格（作为"换域"前的参照系）。其余各章的被复用件在 17.8
统一点名。

### 29.1.3 一张全景表：本章的五个角色与三份契约

经验检验一章有五个参与者，开写之前先把每个角色的职责与
它们之间的数据契约列清楚，后文的所有讲解都在这张图上
定位。

**角色一：静态符号分析**（第 28 章 solveFixpoint + 第 25 章传递函数）。输入是 AST 与 CFG，输出是 PointEnv——
每个程序点一份"变量 → 符号"的映射。它对 output 语句的
承诺是弱的：表达式值的符号必须落在预测里。

**角色二：静态常量分析**（本章 solveConstFixpoint）。
同样的输入，输出 ConstPointEnv——每个程序点一份
"变量 → {⊥,c,⊤}"的映射。它对 output 语句的承诺是强的：
若预测为确定常量，动态值必须逐位相等。

**角色三：具体解释器**（本章 interpret）。输入是 AST 与
一组输入整数，输出是 ConcreteRun——输出值序列，外加
每个值的"户口"（产生它的 OutputS 语句指针）。它不生产
承诺，它生产**事实**。

**角色四：JIT 执行台**（第 15 章 IRGen + jitrun）。同样的
输入，经 LLVM IR 编译成机器码后真实执行，输出值序列。
它也不生产承诺，它生产的是**另一份独立采集的事实**。

**角色五：对账器**（main.cpp 的 --verify-soundness 循环）。
它消费四者的产出，执行三份契约。契约一（动态内部一致）：
解释器与 JIT 的值序列必须完全相同——两台独立的语义机器
不允许分叉。契约二（弱承诺）：每个输出值的符号 ⊑ 该
output 语句所在程序点的静态符号预测。契约三（强承诺）：
静态预测为确定常量处，动态值必须等于该常量。三份契约
依次收紧，任何一份破裂都以 UNSOUND 判罚并立即终止。

这张表还解释了本章结构为什么是这样的：17.2 与 17.3 造
角色二，17.4 接引擎，17.5 造角色三、装配角色五，17.6
宣读裁决，17.7 请来一位外部专家（LLVM SCCP）做交叉
质证。五个角色在全文中缺一不可，读到任何一节都可以
回来对照它们的位置。

## 29.2 扁平常量格 {⊥, c, ⊤}

### 29.2.1 为什么是"扁平"的

符号格把整数分成五类，类与类之间有精细的序：− < ⊤、0 <
⊤，但 − 与 + 互不可比。常量分析面对的抽象问题更极端：它
想知道变量是否**恰好**等于某个具体整数。这个"恰好"重塑了
整个序结构。

考虑两个抽象值"必须为 5"与"必须为 11"。在符号格里，
任何两个非 ⊥ 值至少共享"上界 ⊤"；但"必须为 5"与"必须
为 11"之间**没有任何一个变量能同时满足**——一个变量不可
能既是 5 又是 11。所以这两个值在信息偏序上互不可比：谁也不
比谁更精确或更不精确，它们是关于变量的两个互斥的承诺。把
每个整数各自立成一个与全体其他整数不可比的点，只在下面垫
一个 ⊥（"还没有任何信息"）、在上面盖一个 ⊤（"任何整数
都有可能"），得到的就是扁平格：

```text
              ⊤  (任意整数)
  ┌─────┬─────┼─────┬─────┐
  … 2   1   0  -1  -2 …     (每个整数一个点，互不可比)
              │
              ⊥  (无信息/不可达)
```

"扁平"指的正是中间那一层：无数个具体常量平铺在一起，
彼此之间没有序。这与符号格形成了漂亮的两极——符号格用
粗粒度换取小高度（高度 2，分析便宜），常量格用细粒度换来
一个高度无穷的域（所有整数平铺，高度随整数值无界）。无穷
高度听上去危险（第 16.5.3 节的警告还悬着），但常量分析的
迭代有天然的安全绳：每次 join 要么保持一个常量、要么一步
跳到 ⊤，而 ⊤ 之后永不再变。到达 ⊤ 的次数有限、不经过 ⊤
的上升链只在"同一常量"上原地踏步——迭代仍然必然终止，
第 29.4 节会把这条安全绳说得更精确。

用第 26 章的构造子语言重述一遍会更清楚：在整数集上取
**离散序**（只有 a ≤ a，任何两个不同整数不可比），得到一个
退化的格；再对它施加 **lift** 构造——垫一个新底"还没有
值"——就得到 {⊥} ∪ Z，配上"两个不同常量的公共上界"的
要求补上顶 ⊤。扁平格 = lift(离散序)。第 26 章的四个构造
子里，lift 在这里第一次单独登场挑大梁。

抽象函数 γ 也随之定型：γ(⊥) = ∅（空集，没有任何具体执行
状态）、γ(c) = {c}、γ(⊤) = Z。可靠性定义（具体行为 ⊆
γ(静态预测)）在这三个等式上落地：如果静态在某点说"b 是
⊤"，那么该点任何一次真实执行读到任何整数都算覆盖；如果
静态说"b 是 11"，那么每一次真实执行必须读到 11——少一次
都不行，第 29.5 节的相等检验就是在逐次盘查这句话。

### 29.2.2 cJoin 的三规则

控制流汇合处的合并算子 cJoin 只有三条规则，完整地枚举如下：

| a      | b      | a ⊔ b | 直觉 |
|---|---|---|---|
| ⊥      | x      | x     | 一侧还没有任何信息，另一侧说了算 |
| c      | c（相等） | c     | 两条路径都承诺同一个值 |
| c₁     | c₂（c₁≠c₂） | ⊤  | 两条路径给出不同常量，只能共同承诺"是某个整数" |
| ⊤      | 任意    | ⊤     | 顶吸收一切 |

三行合起来就是一个可机械执行的判定：先看 ⊥（⊥ ⊔ x = x），
再看相等（c ⊔ c = c），其余一律 ⊤。注意第一条与第三条的
对照：⊥ 参与合并不损失精度（"不知道"被"知道 c"覆盖后
仍然精确地是"知道 c"），这与第 16.6.5 节循环头 join 的
细读完全同构——entry 侧的全 ⊥ 不会稀释回边带来的常量。
而两个**不同的**常量相遇时没有任何商量余地：不存在一个
比 ⊤ 更精确的值能同时覆盖 {5} 和 {11}，γ 的定义排除了
这种可能。常量分析的精度损失几乎全部发生在这一行——
路径合并处常量变 ⊤，此后再也无法恢复。这也是为什么工业
级常量分析（17.7 的 SCCP 是其一）把大量工程花在"让不该
相遇的路径别相遇"上：稀疏化、路径敏感性、条件剪枝，殊途
同归地服务于推迟 c₁ ⊔ c₂ = ⊤ 这一行的到来。

### 29.2.3 除零为什么入 ⊥

evalConstExpr 里有一行看似突兀的规则：常量除以常量零，
结果取 ⊥ 而不是 ⊤ 或抛出。理由藏在具体语义里：`11 / 0`
在任何一次真实执行中都不会产生一个整数——TIP 语义下这是
一个动态错误，解释器抛出异常、编译到机器码后是硬件陷阱。
也就是说，**走到这条除法的具体执行在此处中止**，其后的
程序点根本不会被任何执行流触达。

抽象层面的正确对应物正是空集：γ(⊥) = ∅。给"除零之后的
世界"贴 ⊥，说的是"没有具体状态生活在这里"——后续点在
方程里与这个 ⊥ 做 join 时，⊥ 单位元性质保证它们不受污染；
如果这条路径是某个条件分支的一翼，另一翼的信息会原封不动
地占据汇合点。工程上的回报是双重的：其一，分析不会沿着
一条不可行的路径把伪造的值继续传播下去（若取 ⊤，除零点
之后的所有点都被顶成"未知"，一条永远不会发生的路径把整
片区域的分析拖成废纸）；其二，静态结论"此处之后不可达"
本身就是有价值的判定——第 32 章的死代码分析正是这个思路
的反向使用。

要诚实指出边界：⊥ 在本框架里承担了双重语义——"尚未计算
/ 不可达"与"此路径动态错误"。两者在"其后没有可观察行为"
这一点上后果一致，所以工程上可以共用一个符号；但在更精细
的框架里（例如需要区分"会抛异常"与"不会到达"的验证场景），
它们必须分家。本教程的分析不区分，第 36 章的除零专项检查
会把"除数可能是 0"单独拎出来报告，而不是悄悄吞进 ⊥。

### 29.2.4 语言层不变

本章没有动文法一个字。程序仍然是 TIP：函数、赋值、output、
if/while、算术与比较、input。这本身就是一个值得记录的事实
——从第 2 章定义这门小语言起，第 25 章到第 29 章五次换
分析视角（符号、格构造、方程、不动点、常量），语言层零改动。
分析是架在语言之上的视图，视图可以无限更换，被观看的对象
只有一个。嵌入文法存档如下，与第 2 章逐字节相同。

```antlr
// file: TIP.g4
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
AND        : '&' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

### 29.2.5 与符号格并排：两种域设计的一次对读

符号格与常量格是 spa 第 4 章先后给出的两个标准例子，
把它们并排量一遍，能看清"抽象域设计"这件事的全部自由度
落在哪里。

| 维度 | 符号格 | 扁平常量格 |
|---|---|---|
| 元素 | ⊥、−、0、+、⊤（5 个） | ⊥、每个整数、⊤（无穷个） |
| 中间层序 | −、0、+ 两两不可比 | 常量两两不可比 |
| 高度 | 2 | 无穷，但单调链至多 2 步 |
| join 实现 | 查表（4×4） | 三行判定 |
| 传递函数 | 查符号算术表 | 直接执行具体算术 |
| 每变量状态大小 | O(1)（一个 int） | O(1)（两个 int） |
| 回答的问题 | 值的正负 | 值是否为确定常量 |

几个对照值得展开。**元素个数与高度的关系**：符号格五
元素、高度 2；常量格无穷元素，高度形式上无穷（⊥ 下面
没有、常量层无限宽），但第 29.4 节会论证它的单调链被
"星形结构"截断——任何值要么原地不动、要么一步到 ⊤。
**传递函数的形态**：符号格的加法必须查表，因为"正加负
是什么符号"是一个需要预先算好的分类问题；常量格的加法
就是加法本身——抽象运算与具体运算在常量×常量的格子
里合二为一。这不是巧合而是抽象的层次差：符号域把整数
压扁成三桶，运算必须重新定义；常量域保留了全部整数，
运算原样可用，只有"桶间的三态规则"是新东西。**精度与
代价的换算**：两个域的每变量状态都是 O(1)，但精度的
适用面不同——符号格对"来自 input 的值"仍能说点什么
（它至少是个整数，符号未知但"与零的关系"在运算中可
追踪），常量格对同样的值只能说 ⊤。反方向，常量格在
纯常量表达式上精确到个位，符号格只能给"+"。谁更好
取决于下游要什么：第 36 章的除零检查离不开符号格
（除数是否可能为 0），死代码消除离不开常量格（条件
是否恒真）。第 30 章的乘积格会把两者并成一个域，让
一份状态同时携带两种粒度。

最后核对一遍 cJoin 确实是 γ 下的最小上界——这是格
定义与抽象函数自洽的最后一块拼图。要验证的命题：
对任意 a、b，γ(a ⊔ b) 必须是 γ(a) ∪ γ(b) 的上确界。
逐规则看：⊥ ⊔ x = x，即 γ(x) = ∅ ∪ γ(x)，精确相等；
c ⊔ c = c，即 {c} = {c} ∪ {c}，精确相等；c₁ ⊔ c₂ = ⊤
（c₁≠c₂），即 Z ⊇ {c₁} ∪ {c₂}——上界成立；最小性
也不难：任何同时覆盖 {c₁} 与 {c₂} 的 γ 像，要么含
c₁ 且含 c₂（只能是 Z，因为 γ 的像只有 ∅、单点集、Z
三种），要么不含——不含就不是上界。所以 ⊤ 是唯一
选择。三行 join 每一行都在 γ 下严格最优：**扁平格是
对"追踪确定常量"这个问题的最精确回答**，任何精度损失
都不是域设计的锅，而是问题本身（不同路径的常量承诺
互斥）的锅。记住这个核对动作——拿到任何新格，第一件
事就是拿 γ 验 join，第 30 章的幂集格还要再做一遍。

### 29.2.6 一次菱形汇合的 cJoin 演算

规则表背下来不如在一个最小控制流上跑一遍。考虑这样的
菱形：入口给 a 赋一个值，然后 if-else 两翼各改一次 a，
两翼在汇合点重逢。四种赋值方案，逐一演算汇合处的
cJoin 输入与结果。

**方案一：两翼写同一个常量。** if 翼 `a = 5`，else 翼
`a = 5`。汇合处两输入都是 cVal(5)，命中"相等保留"，
a = 5。菱形没有损失任何常量性——这正是"相等保留"
规则存在的意义：两条路径的承诺一致时，承诺可以穿过
汇合继续活下去。

**方案二：两翼写不同常量。** `a = 5` 与 `a = 7`。汇合
cJoin(5, 7) = ⊤。汇合之后 a 永远是 ⊤，哪怕后续代码
只做 `b = a - a`（动态恒为 0）也无法恢复——扁平格
没有减法的"自消"意识，这是它比符号格更"健忘"的地方。
恢复这类信息需要关系域（第 47 章），此处只留印象。

**方案三：一翼写常量，一翼不写。** if 翼 `a = 5`，else
翼什么都不做（a 保持入口值）。若入口处 a = 5（比如
前置 `a = 5`），两翼分别是 5 与 5，汇合 5；若入口处
a 来自 input（⊤），两翼是 5 与 ⊤，汇合 ⊤。注意第二条
的形状：**一翼的 ⊤ 污染整个汇合**，与符号格的
"任何值 ⊔ ⊤ = ⊤"完全同型。"没写"不等于"保持常量"——
保持的是入口的抽象值，入口是 ⊤ 则汇合必 ⊤。

**方案四：一翼不可达。** if 条件是 `2 > 1`，else 翼
永远不走。本章的分析不读条件（17.6 已注明），else 翼
的状态照样参与汇合——若 else 翼写着 `a = 7`，汇合
照样是 cJoin(5, 7) = ⊤。**常量性被一条不可能走的路径
杀死**，这是本章最大的精度遗憾，也是 17.7 SCCP
"conditional"要解决的头号问题：让条件常量反馈回控制流，
不可行翼的状态退出汇合，方案四回到方案一。理解了这
四个方案，就理解了常量分析的全部精度来源与全部精度
损失点——剩下的只是工程上如何少触发方案二与方案四。

### 29.2.7 形式化补全：γ、α 与格律的逐条核验

到这里常量格的构造全靠直觉讲完：三种值、三条 join 规则、
一张菱形演算表。直觉足以写代码，但不足以支撑后面 17.5
的可靠性论证——那里要把静态结论与具体执行一一对账，必须
先在形式世界里把常量格的每一条性质钉死。本节补做这件事：
给出偏序的完整定义、具体化函数 γ 与抽象化函数 α，然后
逐条核验 cJoin 确实是这个偏序上的最小上界、格的四条基本
律确实成立。读者若只关心工程实现，可略过本节直接读
17.3；但 17.5 之后的论证都会默认本节的记号。

**偏序。** 设整数集合为 Z，常量格的承载集为
L = {⊥, ⊤} ∪ {c | c ∈ Z}。L 上的偏序 ⊑ 定义为：
⊥ ⊑ x 对一切 x 成立；x ⊑ ⊤ 对一切 x 成立；
对任意两个不同的整数 c、d，c ⊑ d 与 d ⊑ c 都不成立；
c ⊑ c 成立（自反）。也就是说，所有整数平铺在同一层，
⊥ 悬在它们脚下，⊤ 压在它们头顶——"扁平"之名的全部
含义就是这张图。核验它是偏序只需例行公事：自反显然；
反对称要求 c ⊑ d 且 d ⊑ c 时 c = d，而两个整数之间
根本不存在序边，唯一可能的边是经 ⊥ 或 ⊤ 的，经 ⊥
要求另一边为 ⊥，经 ⊤ 同理；传递按"最多两条边"的
所有走法逐一核验，⊥→c→⊤ 是唯一的两链，它与
⊥ ⊑ ⊤ 一致。

**具体化函数 γ（concretization）。** γ 把每个抽象元素
映射回它所代表的具体值集合：

- γ(⊥) = ∅：⊥ 不代表任何值；
- γ(c) = {c}：常量 c 只代表它自己；
- γ(⊤) = Z：⊤ 代表任意整数。

γ 关于两边的序都是单调的：a ⊑ b 蕴含 γ(a) ⊆ γ(b)。
九对元素里唯一需要动笔的是 c ⊑ ⊤：{c} ⊆ Z 显然；
⊥ ⊑ c：∅ ⊆ {c} 显然；两个整数之间无序边、无需核验。
这张 γ 表是本章所有可靠性命题的基石：静态承诺
"此处是 c"翻译为具体语言就是"此处的具体值 ∈ {c}"，
即必须恰好等于 c；承诺 ⊤ 翻译为"∈ Z"，即什么也
没承诺——17.5 的两道断言就是这两个集合关系的程序化。

**抽象化函数 α（abstraction）。** 反方向把一个整数集合
压成 L 中的一个元素：

- α(∅) = ⊥；
- α({c}) = c；
- α(S) = ⊤，当 S 至少含两个元素。

α 与 γ 的关系要认清：α(γ(⊥)) = ⊥、α(γ(c)) = c、
α(γ(⊤)) = α(Z) = ⊤，三者各自回到自己——α 是 γ 的
左逆。但 γ(α(S)) 一般只保证 S ⊆ γ(α(S))：对
S = {5, 7}，α(S) = ⊤，γ(⊤) = Z ⊇ {5, 7}，集合
被放大了。这不是缺陷而是抽象的本质：一次压缩丢失了
"到底是哪两个值"的信息，再展开只能得到一个包络。
本章所有精度损失都可以归结为这一步集合被放大；所有
可靠性都依赖放大方向始终朝"更大"走。

**cJoin 是最小上界。** 要核验的命题是：cJoin(a,b)
同时满足 a ⊑ cJoin(a,b)、b ⊑ cJoin(a,b)（上界），
且对任何满足两者的 c 都有 cJoin(a,b) ⊑ c（最小）。
按 cJoin 的三规则分情形：任一边为 ⊥ 时结果为另
一边，⊥ ⊑ 另一边成立，最小性要求"任何同时大于
⊥ 与 x 的元素都大于 x"，这是偏序自身的事实；
两边相等时结果为该值，两边都 ⊑ 自身，最小性要求
任何大于 c 的元素都大于 c——注意候选可以是 c 或
⊤（整数层没有别的元素能大于 c），cJoin 给的是
c，两种候选都 ≥ c，成立；两边是不同整数 c、d 时
结果为 ⊤，c ⊑ ⊤、d ⊑ ⊤ 成立，最小性要求任何
同时大于 c 与 d 的元素只能是 ⊤——整数层没有任何
元素能同时大于两个互不可比的常量，故 ⊤ 是唯一
候选，最小性成立。九种情形（⊥、⊤、c 的两两
组合）核完，cJoin 即 L 上的 join。

**一个容易误判的等式。** 对集合格有 γ(a ⊔ b) =
γ(a) ∪ γ(b)，对常量格这条等式**不成立**：
cJoin(5, 7) = ⊤，γ(⊤) = Z，而
{5} ∪ {7} = {5, 7} ≠ Z。正确的陈述只有
γ(a) ∪ γ(b) ⊆ γ(a ⊔ b)。这个不等号正是 17.2.6
方案二"汇合之后常量性不可逆"的形式化根源：具体
语义在汇合点只是两个值的并（仍然只有两个可能），
抽象 join 却一步跨到了 ⊤。想在抽象侧保住 {5,7}
这个信息，需要元素更丰富的格（二元有界集、幂集、
或第 34 章的区间若两值相邻），扁平格的形状决定
它表达不出来。读后续章节时凡是看到"换一块更精
细的格"，都可以回来看这个不等号：换域就是把
γ(a ⊔ b) 与 γ(a) ∪ γ(b) 之间的缝隙一点点挤窄。

**格律快检。** 有了 join，L 是格的其余几条性质
可以顺手核验：交换性（cJoin 对两边对称，规则
分支不区分左右）、结合性（三元素的 join 只取决于
其中有没有 ⊤、有没有 ⊥、或是否全等，排列次序不
影响这个判定）、幂等（cJoin(c,c) = c）、单位元
（cJoin(⊥,x) = x）、吸收元（cJoin(⊤,x) = ⊤）。
对应的 meet（最大下界）可对偶定义：mMeet(a,b) 在
任一边为 ⊤ 时给另一边，相等时给该值，两个不同
常量相遇给 ⊥；本章求解器不用 meet，但 widening/
narrowing 那一章（第 35 章）会回到这种"两个算子
一上一下"的结构。把这一小节的每个断言都亲手核验
一遍，是读 17.5 之前值得花的二十分钟：可靠性论证
不会再补这些基础事实，只在它们之上推进。

## 29.3 常量传递函数：把表达式折叠成值

### 29.3.1 值与环境的形态

constant.hpp 定义了本章的全部数据形态。一个抽象常量值
`Const` 用两个 int 编码三维：`kind` 取 0/1/2 分别是 ⊥、
具体常量、⊤，`v` 在 kind==1 时是那个常量本身。

```cpp
// file: src/constant.hpp
// 常量格（spa 4.1/4.3 的 Flat 常量域）：每个变量取值 ∈ {⊥, c, ⊤}。
//   ⊥（不可达） < 具体常量 c < ⊤（非常量/未知）
// join 规则：两边相等取该值；一边 ⊥ 取另一边；否则 ⊤。
#pragma once

#include <string>

#include "ast.hpp"
#include "cfg.hpp"
#include "sign_transfer.hpp"  // PointEnv 形态与 printPointEnv 复用

namespace tip {

struct Const {
    int kind = 0;  // 0=⊥, 1=常量, 2=⊤
    int v = 0;     // kind==1 时有效

    bool operator==(const Const &o) const { return kind == o.kind && v == o.v; }
};

std::string constShow(const Const &c);

Const cBot();         // ⊥
Const cTop();         // ⊤
Const cVal(int v);    // 具体常量
Const cJoin(const Const &a, const Const &b);

// 常量传递函数：复用 CFG，环境改为 变量→Const。
using ConstEnv = std::map<std::string, Const>;
using ConstPointEnv = std::map<int, ConstEnv>;

ConstEnv constEntryEnv(const FunDecl &f);
ConstEnv constJoinEnv(const ConstEnv &a, const ConstEnv &b);
Const evalConstExpr(const Expr *e, const ConstEnv &env);
ConstEnv constTransferNode(const CfgNode &node, const ConstEnv &in);

ConstPointEnv solveConstFixpoint(const Cfg &cfg, const ProgramA &program);
std::string printConstEnv(const Cfg &cfg, const ProgramA &program,
                          const ConstPointEnv &states);

}  // namespace tip
```

环境类型 `ConstEnv` 是"变量名 → Const"的映射，
`ConstPointEnv` 是"程序点 → ConstEnv"。形状与第 25 章
的 SignEnv/PointEnv 完全同构——这正是第 26 章映射格构造
所描述的抽象环境的一个直接实例：**抽象环境 = 变量集合 →
值格 的映射格**。当时用 `maps(sign, {"x","y"})` 组装的是
符号域上的映射格，本章的 `ConstEnv` 是常量域上的同一个
构造，只是用 `std::map` 手写而非模板生成。缺键即 ⊥ 的
约定原样沿用：读取一个尚未写入的变量按 cBot() 解释，
这在语义上是"该点尚未有任何信息"——与第 16.2.1 节对 ⊥
的校准一字不差地迁移到了新域。

值得停在接口设计上一说的是：constant.hpp 把 `cBot/cTop/
cVal/cJoin` 四个自由函数与 `Const` 这个贫血结构并列，而不
是把它们做成成员函数。这与 sign.hpp 的 SignLattice（成员
式 eq/leq/join）刻意不同。原因很实际：常量格的序与 join
规则太少（三行表），包装成类反而是仪式；符号格有四张算术
表与五种比较语义，值得一个类来聚合。抽象域的接口形态应该
跟随域的复杂度，而不是服从统一的模板——这也是为什么本章
没有把 Const 塞进第 26 章 `Lattice<A>` 的五件套里去"统一
接口"：Lattice 构造子服务于"用通用构造子组装复合域"的
场景（lattice.hpp 的 lift/product/maps/powerset 都是围绕
它写的），而常量分析直接手写域与传递函数，更短也更透明。

顺带把 `operator==` 单独点出来：Const 重载相等比较而
SignLattice 用成员 eq，差别源自两处使用场景。常量侧的
worklist 写回判定（`old->second == nv`）直接用 ==，这是
热路径上每点每次弹出都要跑的比较，运算符重载让它写得
像内建类型；符号侧的比较出现在打印与对账这类冷路径，
成员函数的仪式感无伤大雅。两个域对"相等"的实现恰好
一致（逐字段比），所以热路径优化不会引入语义分歧——
若哪天 Const 加字段（比如 17.9 注意点三的来源标记），
operator== 必须同步决定"标记算不算相等的一部分"：
算，则来源不同的 ⊥ 在 worklist 眼里是两个值，会多跑
几轮迭代；不算，则标记只影响打印。这个看似琐碎的
决定会实质改变引擎行为，域设计里没有真正"只是加个
字段"的事。

### 29.3.2 evalConstExpr：两种吸收的对称

传递函数的核心是表达式求值器 evalConstExpr，constant.cpp
给出全文。它对 AST 做一次后序遍历：字面量折叠成 cVal，
变量查环境，input 与函数调用保守给 ⊤，二元运算按两个
操作数的抽象值分派。

```cpp
// file: src/constant.cpp
#include "constant.hpp"

#include <deque>
#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"

namespace tip {

std::string constShow(const Const &c) {
    if (c.kind == 0) return "BOT";
    if (c.kind == 2) return "TOP";
    return std::to_string(c.v);
}

Const cBot() { return Const{0, 0}; }
Const cTop() { return Const{2, 0}; }
Const cVal(int v) { return Const{1, v}; }

Const cJoin(const Const &a, const Const &b) {
    if (a.kind == 0) return b;
    if (b.kind == 0) return a;
    if (a == b) return a;
    return cTop();  // 两个不同常量：只能共同承诺"是某个整数"
}

ConstEnv constEntryEnv(const FunDecl &f) {
    ConstEnv env;
    for (const std::string &p : f.params) env[p] = cTop();
    return env;
}

ConstEnv constJoinEnv(const ConstEnv &a, const ConstEnv &b) {
    ConstEnv r = a;
    for (const auto &[k, v] : b) {
        auto it = r.find(k);
        r[k] = it == r.end() ? v : cJoin(it->second, v);
    }
    return r;
}

Const evalConstExpr(const Expr *e, const ConstEnv &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return cVal(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        return it == env.end() ? cBot() : it->second;
    }
    if (dynamic_cast<const InputE *>(e)) return cTop();  // 输入未知 → 非"确定常量"
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const Const l = evalConstExpr(x->l.get(), env);
        const Const r = evalConstExpr(x->r.get(), env);
        // 任一操作数 ⊥：此路径不可达，结果 ⊥（⊥ 吸收一切）。
        if (l.kind == 0 || r.kind == 0) return cBot();
        // 任一操作数 ⊤：即使另一个是常量，结果也随输入变化（除零在
        // 抽象层面无法排除，保守取 ⊤；具体除零属动态错误）。
        if (l.kind == 2 || r.kind == 2) return cTop();
        switch (x->op) {  // 两侧都是常量：具体折叠
            case BOp::Add: return cVal(l.v + r.v);
            case BOp::Sub: return cVal(l.v - r.v);
            case BOp::Mul: return cVal(l.v * r.v);
            case BOp::Div:
                if (r.v == 0) return cBot();  // 常量除零：该路径具体会抛错
                return cVal(l.v / r.v);
            case BOp::Gt: return cVal(l.v > r.v ? 1 : 0);
            case BOp::Eq: return cVal(l.v == r.v ? 1 : 0);
        }
    }
    return cTop();  // 调用/指针/记录：保守视为非常量
}

ConstEnv constTransferNode(const CfgNode &node, const ConstEnv &in) {
    if (node.kind != CfgNode::Kind::Assign || !node.stmt) return in;
    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
    const auto *target = dynamic_cast<const VarRef *>(a->target.get());
    if (!target) return in;  // *p / r.f 目标：指针分析之前不处理
    ConstEnv out = in;
    out[target->name] = evalConstExpr(a->value.get(), in);
    return out;
}

ConstPointEnv solveConstFixpoint(const Cfg &cfg, const ProgramA &program) {
    ConstPointEnv cur;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        std::map<int, std::vector<int>> preds, succs;
        for (const auto &[from, to] : fc.edges) {
            succs[from].push_back(to);
            preds[to].push_back(from);
        }

        std::deque<int> wl{fc.entry};
        std::set<int> in{fc.entry};
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            in.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            ConstEnv nv;
            if (node.kind == CfgNode::Kind::Entry) {
                nv = constEntryEnv(*decl);
            } else {
                ConstEnv before;
                auto pit = preds.find(p);
                if (pit != preds.end())
                    for (int q : pit->second)
                        if (auto it = cur.find(q); it != cur.end())
                            before = constJoinEnv(before, it->second);
                nv = constTransferNode(node, before);
            }

            auto old = cur.find(p);
            if (old == cur.end() || !(old->second == nv)) {
                cur[p] = nv;
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int s : sit->second)
                        if (!in.count(s)) {
                            wl.push_back(s);
                            in.insert(s);
                        }
            }
        }
    }
    return cur;
}

std::string printConstEnv(const Cfg &cfg, const ProgramA &program,
                          const ConstPointEnv &states) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();
        std::vector<std::string> names = decl->params;
        for (const std::string &v : decl->vars) names.push_back(v);

        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) {
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << " branch  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << " branch  if " << printExpr(i->cond.get());
                else
                    out << " " << printStmtLine(*node.stmt);
            }
            out << ':';
            const ConstEnv &env = states.at(id);
            for (const std::string &k : names)
                out << ' ' << k << '=' << constShow(env.count(k) ? env.at(k) : cBot());
            out << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
```

二元运算的三个前置分支值得逐个细读，因为它们各自体现
格元素的一种"吸收"行为，而且方向相反。

**⊥ 吸收：任何操作数是 ⊥，结果是 ⊥。** ⊥ 在环境里
意味着"这个操作数所在的路径还没有任何信息"，或者更
准确地——"控制流根本到不了这里"。用一个不存在的值做
加法，结果仍然只属于不存在的世界。所以 ⊥ 沿表达式树
向上传染，整棵表达式的抽象值坍缩为 ⊥，赋值把 ⊥ 写进
目标变量，后续点继续坍缩。这不是精度损失而是忠实记录：
γ(⊥) = ∅，空集与任何集合做任何运算还是空集。

**⊤ 吸收：任何操作数是 ⊤，结果是 ⊤。** 方向恰好相反。
⊤ 意味着"这个操作数可能是任何整数"——比如它来自
input。一个确定常量加一个未知数，结果随输入而变，只能
承诺"是某个整数"，即 ⊤。注意这里有一个容易写错的诱惑：
看到 `2 + ⊤`，直觉会想"至少结果是正的吧"——那是符号格
的事！在扁平格里没有"+"这个元素，2 + ⊤ 的所有可能结果
是全体整数，抽象值只能是 ⊤。扁平格付出的代价正是这种
一刀切：它只回答"是不是确定常量"，不回答任何更粗的问题。
第 30 章的乘积格（符号 × 常量）会把两个世界的精度合起来。

**双常量折叠：两侧都是具体常量，直接执行具体算术。**
`3 + 4 * 2` 在抽象层面被精确地折叠成 11。这是常量分析
的全部收益所在——它本质上是把"编译期就能算的算术"从
运行时挪到分析时。折叠出的比较结果也按值处理：Gt/Eq
产生 cVal(0/1)，于是常量分析顺带获得了"常量条件"的
判定能力（if (3 > 2) 的条件在抽象层面就是 1）——这为
死分支剪枝提供了入口，本章不做剪枝，17.7 的 SCCP 会
展示"条件常量反馈到控制流"的完整形态。

除零分支再次出现：r.v == 0 时返回 cBot()。17.2.3 节
已经论证过工程理由，这里补一个实现层面的观察：这个
分支使得 evalConstExpr 对 `x / (2 - 2)` 这样的表达式
给出 ⊥ 而不是程序崩溃或任意值——传递函数因此**总
终止且总给出格元素**，这是第 27 章"传递函数必须是
从格到格的全函数"要求的一个具体兑现。具体解释器遇到
同一个表达式会抛异常（17.5 的 soundness.cpp 里
`division by zero`），两条通道各按自己的语义处理，
且结论相容：抽象说"此路不通"，具体说"走不通时抛错"。

### 29.3.3 入口、合并与传递节点

接口的其余三个函数与符号侧的对应物逐行同构。
constEntryEnv 把形参置 ⊤——调用方传什么实参，静态分析
在过程内一无所知（过程间分析在第 46 章），与第 25 章
entryEnv 的"参数 = ⊤"决策完全一致。constJoinEnv 逐
变量做 cJoin，缺键一侧贡献 cBot——⊥ 单位元性质再次
让"合并一个还没算过的前驱"变成无操作。

constTransferNode 与 transferNode 的形状一字不差：
非赋值节点透传（output/分支/返回/出口不改变环境），
赋值节点只更新目标为 VarRef 的赋值——`*p` 与 `r.f`
这样的间接目标在指针分析（第 51 章）之前无法确定写到
哪个变量，保持环境不变是唯一安全的选择，误更新任何
候选都会破坏可靠性。这一对"同构传递函数"是 29.4 节
"换格即换分析"论断的物质基础。

constJoinEnv 的逐变量合并还藏着映射格代数的一个缩影，
值得用代数语言复述一遍。cJoin 满足四条性质：交换律
（规则表对称）、结合律（三类结果 ⊥/c/⊤ 的归属与合并
次序无关）、幂等律（c ⊔ c = c，⊤ ⊔ ⊤ = ⊤）、单位元
（⊥ ⊔ x = x）。四条合起来，cJoin 是一个合格的
半格合并算子——这也正是 worklist 引擎敢"任意顺序合并
任意多个前驱"的代数前提：顺序无关性由交换律与结合律
保证，重复合并不改变结果由幂等律保证，"还没算的前驱
可以参与合并"由单位元保证。第 16.4 的不动点论证用的
是这些性质的推论，第 26 章验证构造子时检查的也是这
四条——同一份检查清单，在通用构造、符号域、常量域
上各跑一遍，全部通过。写新域时把四条性质当 checklist
逐条验（多半靠 γ 论证，见 17.2.5），验证过即可放心
交给引擎。

printConstEnv 负责把解打印成人读的表：每个函数一段，
每行"点号 + 语句文本 + 冒号 + 逐变量状态"。变量顺序
固定为形参在前、var 声明在后（与 printPointEnv 相同），
缺键打印 BOT。打印格式与第 28 章的符号表刻意保持平行，
让 29.6 节的双栏对照在视觉上可直接逐行比对。

### 29.3.4 折叠的逐行追踪：fold.tip 的点 3

形式化的分支讲完了，把 17.6 将要出现的最复杂一行输出
提前手推一遍——fold.tip 的点 3，`b = a * 2 + input`，
入口环境 a = cVal(11)。传给 evalConstExpr 的表达式树是
(+ (* a 2) input)（pretty 打印的前缀式即此形状），后序
遍历的求值次序如下。

1. 节点 `a`（VarRef）：查环境，命中 cVal(11)。返回。
2. 节点 `2`（IntLit）：cVal(2)。
3. 节点 `(* a 2)`（Binop/Mul）：两操作数 cVal(11) 与
   cVal(2)。⊥ 分支不命中（两边 kind==1），⊤ 分支不命中，
   进入 switch 的 Mul 情形：cVal(11 * 2) = cVal(22)。
4. 节点 `input`（InputE）：无条件 cTop()。输入流的下一
   个整数在静态世界没有任何约束，γ(cTop) = Z 恰好覆盖。
5. 节点 `(+ (* a 2) input)`（Binop/Add）：左 cVal(22)、
   右 cTop()。⊥ 分支不命中；⊤ 分支命中——哪怕左边是
   精确的 22，加法的另一边是全体整数，22 + Z = Z，
   结果 cTop()。
6. constTransferNode 把 cTop() 写进 b，环境变为
   {a=11, b=⊤}。

六步里值得记住的是第 5 步的形状：**精度在表达式的某一
个内节点上一次性坍塌，且不可逆**。它坍塌的原因不是
实现保守，而是信息论意义上的必然——静态世界确实不知道
input 的值。假如想让 b 也拿到精确值，唯一的途径是把
input 从等式里请出去（常量参数、过程间分析、或者把
input 改成确定值）——分析器的职责是如实报告这一点，
而不是假装知道。第 5 步同时也是 17.6.3 节"相等检验
自动跳过"的直接来源：b 的抽象值是 cTop()，kind != 1，
对账循环对它无事可做。

再补一个对照追踪：同样的树，若环境里 a = cBot()（例如
这条赋值位于一个前驱全不可达的点），第 1 步就返回
cBot()，第 3 步命中 ⊥ 吸收，整棵树坍缩为 ⊥，b 得 BOT。
同一个表达式，环境的底色决定整棵树的命运——这正是
"⊥ 传染"比任何单个分支都更有威力的场合。

### 29.3.5 传递函数单调性的逐情形证明

第 27 章把"传递函数必须单调"列为单调框架的准入条件，
当时只在符号格上口头核验过。常量格是一个更微妙的
考场：它的域上存在互不可比的元素（两个不同整数），
"x 变大"这个概念在整数层根本不存在，单调到底是对
什么而言？本节把常量传递函数的单调性严格证明一遍。
这个证明在 17.4 的终止性论证与 17.5 的可靠性论证中
都要被引用，是绕不过去的一步。

**环境格。** 单个变量的值域是 L，一个程序点上的
环境 ConstEnv 是有限变量集 V 上的映射 V → L，它自身
构成一个格，序为逐点序：S ⊑ S' 当且仅当对每个变量
z 都有 S(z) ⊑ S'(z)，其中缺键按 ⊥ 读（与第 26 章
maps 构造的定义一致）。join 也是逐点的：
(S ⊔ S')(z) = cJoin(S(z), S'(z))。注意缺键处理的
方向：S 中没有 z 读作 ⊥ 而不是 ⊤——"没有信息"与
"什么都可能"在常量分析里是两个方向，缺键是前者。

**待证命题。** 对任意表达式 e，函数
g_e(S) = evalConstExpr(e, S) 关于环境格单调：
S ⊑ S' 蕴含 g_e(S) ⊑ g_e(S')。

**对表达式结构归纳。** 归纳基：IntLit 返回常量，
与环境无关，两边相等；InputE 恒返回 ⊤，两边相等；
VarRef 查键：S ⊑ S' 时 S(z) ⊑ S'(z)，缺键情形
⊥ ⊑ S'(z) 成立，直接得证。

归纳步 Binop(op, l, r)：由归纳假设
g_l(S) ⊑ g_l(S')、g_r(S) ⊑ g_r(S')，记为
a ⊑ a'、b ⊑ b'。要证 h(a,b) ⊑ h(a',b')，其中 h
是 constant.cpp 中 Binop 分支实现的函数：先判 ⊥
吸收（任一边 kind==0 返回 ⊥），再判 ⊤ 吸收（任一
边 kind==2 返回 ⊤），最后按 op 折叠两个具体值。

逐情形核验 h 的单调性。若 a 或 b 为 ⊥，h(a,b) = ⊥，
⊥ ⊑ 任何结果，成立——这是最省事的情形，也是为什么
⊥ 吸收规则要放在最前：它让"不可达输入"的一切组合
自动合法。若 a' 或 b' 为 ⊤，h(a',b') = ⊤，任何
结果 ⊑ ⊤，成立。剩下的情形要求 a、b、a'、b' 全部
既非 ⊥ 也非 ⊤，即四个都是具体常量。此时 a ⊑ a' 且
两者都是具体常量，偏序定义迫使 a = a'（两个不同整数
互不可比！）；同理 b = b'。于是两边折叠的输入完全
相同，h(a,b) = h(a',b')，相等是单调的特例。证毕。

最后这一步是常量格单调性证明的真正核心，值得停下来
体会：**扁平格上的单调函数在"具体常量层"只能做恒等
搬运，不能把一个常量变成另一个**——因为层内没有序
边允许这种变化。常量折叠算术中的 cVal(l.v+r.v) 看似
"产生了新值"，但它产生的是表达式的值而非环境变化
的响应：输入环境不变，输出永远不变。任何想让分析
"随环境从 c 平滑过渡到 c'"的设计，在扁平格上都不
可能单调，必须换域。

**赋值传递的单调性。** 语句 x = e 的传递函数
T_{x=e}(S) 是把 S 中 x 一格替换为 g_e(S)（环境的其余
部分原样保留）。S ⊑ S' 时，对 z ≠ x 两环境在 z 上
满足 S(z) ⊑ S'(z)（替换不动这一格）；对 z = x，由
g_e 的单调性得 g_e(S) ⊑ g_e(S')。两点合起来
T(S) ⊑ T(S')。非赋值语句（Branch、Output、Return、
Entry）的传递是恒等函数，单调性显然。至此常量分析的
全部传递函数都通过了单调框架的准入审查。

### 29.3.6 局部可靠性：静态一步与具体一步的交换图

单调性保证迭代收敛到一个不动点，但不保证这个不动点
"说的是实话"。实话的标准在 spa 1.3 给出：对所有可能
的具体执行，每个程序点上的具体值都必须落在静态预测的
具体化集合内（soundness）。本节先证明这个性质的"一步
版本"——局部可靠性（local soundness）；它如何沿路径
与循环推广为全局可靠性，留到 17.5 对账之后与抽象解释
章节（第 65 章）从两侧夹击。

**具体一步。** TIP 的具体语义里，语句 x = e 在具体
环境 σ（变量 → 具体整数）上的效果是
C[[x=e]](σ) = σ[x ↦ eval(e, σ)]，即先按具体语义求出
表达式的值 v，再覆盖 x 一格。对一组具体环境的集合 P
（静态分析处理的是"可能处于的所有状态"），逐点执行
得到 C(P) = {σ[x ↦ eval(e,σ)] | σ ∈ P}。

**交换条件。** 要证的是 α(C(P)) ⊑ T(α(P))：先具体
执行再抽象，得到的抽象状态不超过（信息不少于）先
抽象再过抽象传递函数。用 17.2.7 的交换图画，具体的
横向一步与抽象的横向一步必须能交换，且先走具体侧
永远不会冒出抽象侧兜不住的值。

证明按 α(P) 的三种可能分情形。若 α(P) = ⊥，则
P = ∅（α 取 ⊥ 仅当输入空集），C(P) = ∅，
α(C(P)) = ⊥ ⊑ 任何 T(⊥)，成立。若 α(P) = c，则
P 恰含一个具体环境 σ（α 取具体常量仅当集合单点），
C(P) 也是单点 {σ[x↦v]}，α 后是具体常量 v；右边
T(c) 在 x 格写 g_e(α({σ})) = evalConstExpr(e, σ*)，
这里 σ* 是 σ 的抽象。需要 v ⊑ evalConstExpr(e, σ*)：
单点情形具体化集合都是单元素，这要求两者恰好相等
（{c} 与 {d} 的包含只有 c = d）。这就是**表达式
折叠的局部可靠性**：常量分析对表达式的抽象求值与
具体求值在输入完全确定时必须给出同一个数。它的
证明是对 e 的再一次结构归纳：整数与变量平凡；
Binop 两侧子表达式由归纳假设折出与具体相同的数，
四则运算与比较的 C++ 实现（+、-、*、/ 截断、>、
==）与 TIP 具体语义逐一对齐——唯一的边界是除零：
具体语义在此抛错而非产生值，抽象侧返回 ⊥ 使这条边
退出交换图（"会抛错的路径不产生需要承诺的值"），
与 17.2.3 的设计闭合。

若 α(P) = ⊤，右边 T(⊤) 在 x 格写 g_e(⊤环境)。g_e
对任何输入的返回值 ∈ L，其具体化集合 ⊆ Z；左边
α(C(P)) 无论是什么，其具体化也 ⊆ Z（任何具体整数
集合都在 Z 内），故 γ(α(C(P))) ⊆ Z = γ(T(⊤))，
即 α(C(P)) ⊑ T(⊤)。注意这里靠的是 ⊤ 的具体化恰为
整个整数宇宙：**⊤ 之所以是"安全的放弃"，正因为它
承诺的集合大到无所不包**。这也解释了为什么保守回退
在任何工程语境下都是 ⊤ 而不是某个"猜测的常量"——
猜错一个具体值会破坏交换图，放弃承诺永远不会。

**从一步到全程。** 局部可靠性是一个对每条语句都成立
的交换方块。沿一条无环路径把方块首尾相接，具体侧
复合出路径执行、抽象侧复合出路径的传递函数，方块
交换性逐格传递（每次包含关系的复合仍是包含），得到
路径版本：路径终点的具体值 ∈ γ(路径抽象结果)。对
含汇合的 CFG，分叉处具体环境集合分叉、抽象侧分别
处理，汇合处具体集合取并、抽象侧取 join，由
γ(a) ∪ γ(b) ⊆ γ(cJoin(a,b))（17.2.7 核验过的包含）
闭合。循环是唯一不能简单拼接的形状——执行可以绕圈
任意多次，需要对绕圈次数归纳并借助不动点的"最小"
性质：k 次绕圈内的具体值都被同一个不动点摘要盖住
（因为不动点是这些摘要的 join 的极限）。这条完整的
全局证明将在第 65 章用 Galois 连接的语言一次讲透；
本章的做法不同：**不全局证明，而是用 17.5 的经验
检验对每一次具体执行直接验证交换图的终点实例**——
证明负责"原则上不可能错"，检验负责"这批代码这次没
错"，两者回答的是不同的问题。

## 29.4 同一台 worklist，换一个格

把 solveConstFixpoint（constant.cpp 的中段）与第 28 章
solveFixpoint（solve.cpp）并排放，会看到一组几乎逐行对应的
结构：一个 `std::deque` 队列加一个 `std::set` 防重集合、
entry 特判、弹出时合并全部前驱、transfer、新旧比较、变化
才入队后继。整个骨架一共有五步——弹出、重算、比较、写回、
入队——两份代码在五步上的形状完全一致，不同的只有三样：

1. **状态类型**：SignEnv（变量 → 符号整数编码）换成
   ConstEnv（变量 → Const）；
2. **合并算子**：SignLattice::join 的查表逻辑换成 cJoin
   的三行判定；
3. **传递函数**：evalExprSign 的符号算术表换成
   evalConstExpr 的折叠求值。

第 27 章与第 28 章花了整整两章建立"单调框架"这个概念——
方程组是规格、worklist 是求解算法、格与传递函数是框架的
可替换组件——本章就是这套理论的第一次实际兑现：**不动点
求解不是某个分析的实现细节，而是所有分析的公共引擎**。
写第二个分析的工作量只剩"给出格 + 给出传递函数"，框架
的认知成本是一次性的。第四篇后面的每一个分析（活跃变量、
可用表达式、区间、指针）都将走这条路：新分析 = 新域 + 新
传递函数，求解器零改动。

诚实地说一句实现取舍：本教程的两份求解器是复制粘贴的孪生
而非模板化的一体。C++ 完全可以把状态类型、transfer 与 join
做成模板参数写一份通用求解器（第 30 章把四大 DFA 接到统一
求解器上时会更接近这个形态），但复制版本让两个分析各自
可读、可独立讲解，expected 快照里两栏输出互不干扰。教学
代码优先透明，生产代码优先去重——这个取舍在第 23 章
（朴素合一换近线性）与第 28 章（FIFO 换逆后序）反复出现，
本章再次确认它。

终止性也顺带说清。第 16.5.3 节警告过"无穷高度格上的单调
迭代不保证停"，常量格恰恰高度无穷（整数平铺），表面上看
危险还在。但细看迭代的行为：写回发生在"新值 ≠ 旧值"时，
而常量域上 nv 变化的路径只有两种——从 ⊥ 首次算出一个
常量（每变量至多一次），或任何值跳到 ⊤（每变量至多一次，
⊤ 之后再算仍是 ⊤，比较相等、不再写回）。两个不同常量
之间的"上升"不存在——它们互不可比，且传递函数的设计
保证重算只会在前驱变化后把值推向 ⊤ 或保持常量。于是
每变量的写回至多两次，P 个点 × V 个变量 × 2 次封顶，
队列必然清空。**扁平格是"无穷域但迭代有界"的标准案例**：
高度无穷，但单调链的长度被域的星形结构（一切都直接连向
⊤）截断了。第 34 章的区间格就没有这份幸运——它的链
⊥ < [1,1] < [1,2] < [1,3] < … 真的无界，加宽算子必须登场。

### 29.4.1 扁平格终止性的完整论证

上一段的"安全绳"值得写成完整的命题，因为它与第 16.5
的高度论证形态不同，是终止性论证的第二种范式。

命题：对任意 TIP 程序，solveConstFixpoint 在有限步内
终止。

证明分三步。第一步，刻画单变量的值轨道。一个变量在
某程序点的抽象值随重算变化的序列，每个新值要么与旧值
相等（比较失败、不写回），要么不等。不等的新值有几种
可能：从缺键（⊥）到某常量 c；从常量 c 到另一个常量
c'？——这一步要小心，c 到 c' 看似可能，实则需要
重算输入发生"从 c 到 c' 的变化"，而重算输入只来自
前驱状态的变化；对前驱状态序列做同样的归纳，最终
归纳到入口边界（不变）与 input（恒 ⊤，不变）。于是
每个变量的可能序列被限定为：⊥ → c（一次）→ ⊤（零或
一次）→ ⊤（不变），长度至多 2。星形结构的含义正是
这个：扁平格里唯一的严格上升路径是 ⊥ → c → ⊤，两个
不同常量之间不存在边。

第二步，全局计数。P 个程序点、V 个变量，每点环境写回
对应至少一个变量的值变化（写回条件是整个环境不等，
而环境不等必由某变量不等引起），故写回总数 ≤ 2PV。

第三步，队列排空。每次弹出至多引发一次写回；写回总数
有界，故弹出总数有界，队列必然排空。证毕。

与第 16.5.2 的 O(P·H) 论证对照：那里用"格高度"统一
度量一切有限格；这里高度无穷、度量失灵，改用"轨道
形状"直接计数。两个范式覆盖了本教程遇到的所有域：
有限高度格用前者（第 30 章幂集格、第 32 章布尔域），
无穷高度但轨道有界的用后者（本章扁平格），高度与轨道
都无界的必须外加机制（第 29、30 章的加宽/收窄）。
拿到新域时先判断它属于哪一类，终止性的答案就在分类里。

### 29.4.2 引擎复用的边界：什么时候必须改引擎

"换格即换分析"是本章的主旋律，但主旋律也有低音部：
哪些变化是换格消化不了的？把边界画清楚，复用才不会被
神化。

**传递函数必须是全函数。** 框架假设 transfer 对任何格
元素都终止并返回格元素。若某天传递函数内部要查一张
"可能查不到"的表（比如未来的域带上下文），查不到时的
兜底行为就属于引擎契约——返回 ⊤（保守）或断言失败
（尽早暴露）都行，静默返回垃圾不行。这一条不是格论
要求而是工程要求，但它决定引擎敢不敢信任组件。

**新信息源要改引擎。** 本章的分析只沿 CFG 边流动。
若要加"调用图上的信息流动"（过程间分析）或"指向关系
的流动"（指针分析），状态不再是单纯的变量映射，方程
的依赖也不再是 CFG 前驱——引擎的"合并前驱"这一步
必须升级。第 46 章起会看到引擎的第二次进化；在那
之前，"每点状态 = 前驱 join 后过传递函数"的方程形状
一直够用。

**needs-sparse 时改引擎。** 本章的稠密环境在编译器
规模上会露怯（17.9 注意点二）。稀疏化不是换格能解决
的——它是"值往哪里放"的结构变化，属于引擎。SCCP
的稀疏引擎与本教程的稠密引擎解的是同一组格论问题，
只是"格值住在哪"不同；把两台引擎共用同一副格与传递
函数，是理解引擎与组件边界的最佳实验（留给练习五）。

**精度反哺控制流时改引擎。** 17.7 的两相 SCCP 让格值
反过来剪 CFG 边，方程组的依赖图本身变成动态的。这
超出了"依赖取自 CFG"的第 27 章框架，是引擎层最大的
一次升级。升级之后方程组的单调性论证要重做一遍——
依赖图变化时"最小不动点"的定义都要重述。这也是为什么
教科书本章之前都不做条件反馈：先把静态图上的不动点
讲透，动态图是它的推广而不是替代。

总结成一句：**格与传递函数负责"抽象什么"，引擎负责
"信息怎么流"；换前者是配置，换后者是重构。** 本章
享受的是配置级复用的全部红利，同时把四个重构触发点
记在账上，后面章节逐一兑付。

### 29.4.3 MOP 与 MFP：不动点相对"所有路径"站在哪

worklist 求出的不动点有一个自然的竞争对手：不合并、
不迭代，直接沿每条路径分别把传递函数复合下去，最后
把所有路径终点的结果 join 成一个摘要。这就是
meet-over-paths（MOP，本教程方向应称 join-over-paths，
spa 沿用 MOP 统称）；worklist 不动点则称
maximal-fixed-point 解（MFP）。两者谁更精确？这是
数据流理论里少数有干脆答案的问题之一，本节把定理与
证明给出，并用 fold.tip 对号入座。

**MOP 的定义。** 设从入口到程序点 p 的路径集合为
Paths(p)（沿 CFG 边的有限序列）。一条路径
π = n₀→n₁→…→nₖ 的传递效果是沿途传递函数的复合
F_π = F_{nₖ} ∘ … ∘ F_{n₁}（顺序按信息流动方向）。
MOP(p) = ⊔_{π ∈ Paths(p)} F_π(边界值)。直觉上 MOP
是"上帝视角的分析"：它保留每条路径的完整历史直到
终点，只在最后一刻合并。路径敏感能给出的最好结果
莫过于此。

**MFP 的定义。** worklist 在每个点只维护一份摘要，
点 p 的入值 = ⊔_{q → p} 点q出值，绕圈信息通过迭代
回流。MFP 不记录"值是沿哪条路来的"，在每个汇合点
当场合并。

**定理（MOP ⊑ MFP）。** 当所有传递函数单调时，对
每个点 p，MOP(p) ⊑ MFP(p)：不动点不比 MOP 更精确
（记住序的方向：更小 = 信息更多；MFP 在序上更大 =
更"糊涂"）。

证明对路径长度归纳。核心不变量：对点 p 任意长度的
路径，F_π(边界值) ⊑ MFP(p)。长度零（入口自身）：
边界值 = MFP 入口（求解器对入口特判为边界条件）。
归纳步：路径经最后一条边 q→p 到达，
F_π = F_p ∘ F_{π'}。由归纳假设
F_{π'}(边界值) ⊑ MFP(q)；F_p 单调，作用后
F_p(F_{π'}(边界值)) ⊑ F_p(MFP(q))。而
F_p(MFP(q)) ⊑ F_p(⊔_{r→p} MFP(r))（MFP(q) 是 p 的
入值 join 中的一项，join 后更大），后者正是
MFP(p) 的定义（p 点出值）。包含传递，归纳完成。
最后对 Paths(p) 中所有路径的包含同时成立，join 保持
序，即 MOP(p) ⊑ MFP(p)。证毕。

**等号何时成立：分配性。** 若每个传递函数保持 join
——F(a ⊔ b) = F(a) ⊔ F(b)，称 F 分配（distributive）
——则 MFP = MOP：在汇合点先合并再过 F，与过 F 后
再合并完全等价，MFP 的"当场合并"不损失任何东西，
MOP 的路径历史也就没有额外价值。第 30 章的 gen/kill
传递函数全部分配（集合上 F(S)=(S∖K)∪G，并集在
S 的替换下直接展开即证）；常量分析的传递函数**不
分配**：取 a = cVal(5)、b = cVal(7)，
F(a ⊔ b) = F(⊤)（以 `x = y` 为例则为 ⊤），而
F(a) ⊔ F(b) = cJoin(5,7) = ⊤——此例恰好相等；换
表达式 `x = y + 1`：F(a)=6、F(b)=8、join 为 ⊤，
F(a⊔b)=F(⊤)=⊤，仍相等。再换 `x = y - y`：
F(a)=0、F(b)=0、join 为 0，而 F(⊤)=⊤——缝隙出现：
MOP 知道"无论 5 还是 7，自减皆 0"，MFP 不知道。
这就是 17.2.6 方案二预言的关系信息，MOP/MFP 的差距
在此可见。IFDS（第 48 章）的全部价值就是为分配问题
提供线性复杂度的 MOP 级求解；常量这类非分配问题只
能停在 MFP。

**fold.tip 对号。** fold.tip 是直线程序：每个点只有
一条路径，MOP 与 MFP 的定义重合（join 单项 = 自身），
a=11、b=⊤ 的两栏输出同时是两个解。sign1.tip 出现循环
后两解才真正分岔：MOP 区分"循环执行 0、1、2…次"的
路径，在输出点保留"从未执行时 x 未定义"这一支；MFP
在循环头把"首次到达"与"绕圈返回"合并（BOT ⊔ 2 = 2），
输出点只承诺 x=2。17.5 的检验之所以对每个输入组都
裁决 membership OK，是因为 sign1.inputs 的首个输入
全部大于 0——被检验的执行都进入循环、都落在 MFP 承诺
的路径支上。把某行首值改成 -1，JIT 会输出 0（IRGen
给局部变量预置 0），而 MFP 仍预测 2，相等检验将以
UNSOUND 翻案。这不是 MFP 理论上不可靠——按 TIP 的
严格语义，读未初始化变量没有定义值、不在可靠性承诺
的范围内——而是经验检验"只证明被测试执行"这一属性的
当场暴露。MOP 那一支（未定义）与 MFP 的承诺（2）在
语义灰区擦肩而过；设计输入时绕开灰区，是 17.9 第五
条的用意，也是阅读所有经验性 soundness 报告时应有的
谨慎：SOUND 一行的量化范围永远只等于输入文件的覆盖
范围。

## 29.5 可靠性的经验检验

### 29.5.1 为什么需要一台陪审团

第 28 章用 Knaster–Tarski 与四步归纳证明了 worklist 收敛
到最小不动点，第 29.3 节的传递函数每一行都"看起来"保守。
但证明链上有环环相扣的前提：join 表抄对了吗？⊥ 与 ⊤ 的
分支写反了吗？传递函数真的作用在"该程序点执行后"的环境上
吗？CFG 的程序点编号与解释器走的语句是同一批对象吗？任何
一环失守，静态预测就整体作废——而这些都是实现错误，恰好
是证明管不到、测试管得了的。

经验检验的设计因此非常明确：**不做证明的复制品，做证明的
对抗者**。让程序真的执行——而且是沿两条互相独立的通道执行
——把每次执行产生的每个输出值送回静态预测处对账。一个值
只要违反预测（符号越界或常量不等），UNSOUND 立刻宣判。这个
设计的哲学与第 26 章"用固定 join 例子对账构造子"一脉相承：
理论给出全称命题（"对所有输入成立"），实验给出存在命题
（"在这组输入上成立"）；实验永远不能证明全称命题，但任何
一次反例都能推翻实现。跑得越多、输入越刁钻，实现的可信度
越高——而理论证明保证：只要实现与理论一致，反例永不存在。
两者各司其职。

把"谁审谁"的关系再摆正一次。表面上看是动态审静态：
JIT 跑出真实值，静态预测被拿来对质。但契约一先审了
动态自己——解释器与 JIT 互为独立实现，先要求两者一致
才能拿到"可信的事实"。于是整个检验的信任链是：**静态
分析的可信度 ≤ 对账的严格性 ≤ 动态事实的可信度 ≤
两条独立实现的一致性**。链条上任何一环松动，SOUND
就贬值。这也解释了为什么本章愿意花一个解释器的篇幅
（soundness.cpp 的一百行）去"重复实现"TIP 语义——
如果没有第二台独立的语义机器，对账就退化成"用被测
系统的另一部分测它自己"，对抗性荡然无存。测试理论里
这叫 oracle problem：你需要一个独立于被测实现的正确性
源泉。本章的 oracle 是"两台独立实现 + 静态格论承诺"
的三方共识，比任何单一来源都难被同一个 bug 骗过。

### 29.5.2 具体解释器：给每个输出值上户口

对账需要知道"第 k 次输出对应哪个程序点"。JIT 通道给不出
这个信息——tip_output 回调只上报一个 int32 值序列，值的
来源语句在编译后已经消失。解决办法是让第三条通道承担
"户口登记"：一个直接在 AST 上解释执行的具体解释器，它
与 JIT 语义等价（都是 TIP 的具体语义），但在执行每条
output 语句时把**语句指针本身**与输出值成对记录下来。
soundness.hpp 定义这个记录的形态。

```cpp
// file: src/soundness.hpp
// 可靠性经验验证（spa 1.3 的 soundness 概念落地）：
//   1. 静态：符号分析（第 28 章 worklist）给出每个程序点上每个变量的符号；
//      常量分析（本章）给出部分点的确定常量。
//   2. 动态：对 INPUTS 里的每组输入，用 ORC JIT 真实执行程序，收集输出序列。
//   3. 对账：需要一个"第 k 次输出对应哪个 output 语句"的映射——
//      由一个具体解释器（与 JIT 同语义）在解释时记录每次执行的 output 语句，
//      JIT 只负责产生值序列。把具体值转成符号后断言 ⊑ 静态预测；
//      静态预测为常量处再断言逐点相等。任一断言失败即 UNSOUND。
#pragma once

#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

// 一次具体执行：输出值序列 + 每个值来自哪个 OutputS 语句（下标一一对应）。
struct ConcreteRun {
    std::vector<int> values;
    std::vector<const OutputS *> sites;
};

// 具体解释执行：inputs 按序供 input 表达式消费。
// 仅覆盖标量算术/控制流/函数调用；指针与记录构造在此抛错（验证程序不使用）。
ConcreteRun interpret(const ProgramA &program, const std::vector<int> &inputs);

}  // namespace tip
```

ConcreteRun 的两个字段一一对应：values[k] 是第 k 个输出的
值，sites[k] 是产生它的那条 OutputS 语句。值与语句的配对
在解释时天然成立——解释器执行到 output 语句的那一刻，值
和语句同时在手上。这个"当场配对"的技巧让后续所有对账都
不用再做任何匹配猜测。

soundness.cpp 是解释器本体。它是一个最小但完整的 TIP
具体语义实现：表达式求值、语句执行、函数调用（用 "\x01ret"
这个不可能与源码标识符冲突的键在环境里传返回值）、循环与
分支。它有三处设计值得放大。

```cpp
// file: src/soundness.cpp
#include "soundness.hpp"

#include <map>
#include <stdexcept>

namespace tip {
namespace {

struct Machine {
    const ProgramA &program;
    std::vector<int> inputs;
    size_t inputPos = 0;
    ConcreteRun run;

    int readInput() {
        if (inputPos >= inputs.size())
            throw std::runtime_error("inputs exhausted");
        return inputs[inputPos++];
    }

    int eval(const Expr *e, std::map<std::string, int> &env) {
        if (const auto *x = dynamic_cast<const IntLit *>(e)) return x->v;
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            auto it = env.find(x->name);
            if (it == env.end()) throw std::runtime_error("unbound " + x->name);
            return it->second;
        }
        if (dynamic_cast<const InputE *>(e)) return readInput();
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            const int l = eval(x->l.get(), env);
            const int r = eval(x->r.get(), env);
            switch (x->op) {
                case BOp::Add: return l + r;
                case BOp::Sub: return l - r;
                case BOp::Mul: return l * r;
                case BOp::Div:
                    if (r == 0) throw std::runtime_error("division by zero");
                    return l / r;
                case BOp::Gt: return l > r ? 1 : 0;
                case BOp::Eq: return l == r ? 1 : 0;
            }
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            const auto *fn = dynamic_cast<const VarRef *>(x->callee.get());
            const FunDecl *decl = nullptr;
            for (const auto &f : program.funs)
                if (f->name == fn->name) decl = f.get();
            std::map<std::string, int> local;
            for (size_t i = 0; i < decl->params.size(); ++i)
                local[decl->params[i]] = eval(x->args[i].get(), env);
            execBody(*decl, local);
            return local["\x01ret"];
        }
        throw std::runtime_error("interpret: unsupported expression");
    }

    void execBody(const FunDecl &f, std::map<std::string, int> &env) {
        const auto *body = dynamic_cast<const BlockS *>(f.body.get());
        for (const auto &s : body->ss) execStmt(s.get(), env);
        if (f.ret) env["\x01ret"] = eval(f.ret->e.get(), env);
    }

    void execStmt(const Stmt *s, std::map<std::string, int> &env) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            const auto *t = dynamic_cast<const VarRef *>(x->target.get());
            env[t->name] = eval(x->value.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            run.values.push_back(eval(x->e.get(), env));
            run.sites.push_back(x);
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            if (eval(x->cond.get(), env) != 0) execStmt(x->then.get(), env);
            else if (x->els) execStmt(x->els.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            while (eval(x->cond.get(), env) != 0) execStmt(x->body.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &y : x->ss) execStmt(y.get(), env);
            return;
        }
        if (dynamic_cast<const ReturnS *>(s))
            return;  // 返回值统一在函数体末尾求值；TIP 的 return 位于函数尾部
        throw std::runtime_error("interpret: unsupported statement");
    }
};

}  // namespace

ConcreteRun interpret(const ProgramA &program, const std::vector<int> &inputs) {
    Machine m{program, inputs, 0, {}};
    const FunDecl *mainFn = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFn = f.get();
    std::map<std::string, int> env;  // main 无参：空环境
    m.execBody(*mainFn, env);
    return std::move(m.run);
}

}  // namespace tip
```

第一处，**OutputS 分支的当场配对**：`run.values.push_back`
与 `run.sites.push_back(x)` 紧挨着执行，x 是 AST 里那条
OutputS 语句的地址。地址的稳定性由 AST 的所有权结构保证
——ProgramA 用 unique_ptr 持有全部函数，语句存活到
ProgramA 析构，指针在整个对账期间有效。

第二处，**除零抛异常**。解释器不给除零任何宽容：抛出
"division by zero"。这与 17.2.3 节的抽象语义（⊥ = 此后
无行为）形成一对可对账的语义：如果静态分析在某点预测
⊥（不可达/错误路径），而某次具体执行真的带着输出走到了
那里，17.5.4 的成员检验会判 UNSOUND——具体行为出现在
γ(⊥) = ∅ 之外，可靠性被当场证伪。反之，若具体执行真的
在常量除零处抛了异常，那一次运行没有输出值可对账（异常
向上传播，本次运行作废）——本教程的实验输入刻意避开
触发除零，把"异常路径的对账"留给第 36 章的专项检查。

第三处，**return 的位置约定**。TIP 文法规定 return 只能
出现在函数体末尾（RETURN expr SEMI 是 function 产生式的
收尾），所以解释器在 execBody 里顺序执行完块内语句后统一
求值 f.ret，体内的 ReturnS 空转。这不是偷懒而是对文法的
忠实：语言里不存在"提前 return"，语义自然不需要提前
出栈机制。JIT 通道（第 15 章 irgen）用 CreateRet 做的是
同一件事的编译形态。

为了让解释器不再是"读过的代码"而是"看得见的机器"，
把 sign1.tip 在输入 `1 0` 下完整走一遍。execBody 进
main 的块：第一条语句是 WhileS，进入 while 分支求值
条件 `input > 0`——eval 遇到 InputE 调 readInput，取走
第一个输入 1，1 > 0 为真，执行循环体：y := 1（环境
{y:1}）；x := y + 1，递归求值出 2，环境 {y:1, x:2}。
回到条件，再取一个输入 0，0 > 0 为假，跳出。最后一条
是 output x：eval 查环境得 2，**此刻** push_back(2) 与
push_back(x 这条 OutputS 的地址) 成对落进 ConcreteRun。
注意几个与静态侧严丝合缝的咬合点：循环条件每轮重新
求值、每轮消费一个输入——这与 JIT 里 wh.cond 块每轮
回到、每轮 call tip_input 是同一语义的两份实现；户口
登记发生在值算出的同一时刻，中间没有任何缓冲区可以
错位；环境是 map 的朴素值语义，函数调用时的 local 新建
对应 irgen 里的新 alloca 组。解释器没有任何一个部件是
聪明的——它聪明在足够笨，笨到与文法一一对应，任何
一处与文法的不一致都会在对账里现形。

### 29.5.3 总装：--verify-soundness 的五段流水

main.cpp 新增 --verify-soundness 模式把三方接在一起：
静态符号分析、静态常量分析、具体解释器、JIT、对账循环。
先看全文再分段讲解。（文件顶部沿用早期章节总装程序的用途
注释，以 usage 行与下文讲解为准。）

```cpp
// file: src/main.cpp
// 第 24 章配套程序：类型分析总装（含 null），按表达式报告最终类型。
//   --check FILE    : collect -> unify -> 逐表达式打印类型，末尾打印函数类型
//   --emit-ir FILE  : 打印未优化的 LLVM 模块
//   --run FILE INPUTS: 每行输入真实执行一次
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "constant.hpp"
#include "equations.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "sign.hpp"
#include "solve.hpp"
#include "soundness.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
    }
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);

    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);

    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

std::vector<int> parseRun(const std::string &line) {
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);
        std::vector<tip::MonoEq> eqs = tip::signEquations(cfg);
        tip::PointEnv signStates = tip::solveFixpoint(cfg, *p.ast, eqs);
        tip::ConstPointEnv constStates = tip::solveConstFixpoint(cfg, *p.ast);

        std::cout << "SIGN (worklist least fixpoint):\n";
        std::cout << tip::printPointEnv(cfg, *p.ast, signStates);
        std::cout << "CONST (flat constant lattice, least fixpoint):\n";
        std::cout << tip::printConstEnv(cfg, *p.ast, constStates);
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--verify-soundness") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);
        std::vector<tip::MonoEq> eqs = tip::signEquations(cfg);
        tip::PointEnv signStates = tip::solveFixpoint(cfg, *p.ast, eqs);
        tip::ConstPointEnv constStates = tip::solveConstFixpoint(cfg, *p.ast);

        // output 语句 → 所在 CFG 节点（静态状态查询用）。
        std::map<const tip::Stmt *, int> nodeOf;
        for (const tip::FunCfg &fc : cfg.funs)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt) nodeOf[node.stmt] = id;

        int run = 0, obs = 0;
        bool allOk = true;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            tip::ConcreteRun concrete = tip::interpret(*p.ast, inputs);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);
            ++run;

            bool ok = outputs == concrete.values;
            for (size_t k = 0; k < outputs.size() && ok; ++k) {
                const tip::OutputS *site = concrete.sites[k];
                int nid = nodeOf.at(site);
                const tip::SignEnv &senv = signStates.at(nid);
                const tip::ConstEnv &cenv = constStates.at(nid);

                // 符号成员检验：具体值的符号必须 ⊑ 静态预测。
                int predicted = tip::evalExprSign(site->e.get(), senv);
                tip::SignLattice lat;
                if (predicted == tip::SBOT ||
                    !lat.leq(tip::signOfLiteral(outputs[k]), predicted)) {
                    std::cout << "run " << run << ": outputs " << outputs[k]
                              << " ; UNSOUND: sign at output\n";
                    ok = false;
                    break;
                }
                ++obs;
                // 常量相等检验：静态预测为确定常量处，JIT 值必须逐点相等。
                tip::Const cp = tip::evalConstExpr(site->e.get(), cenv);
                if (cp.kind == 1) {
                    if (cp.v != outputs[k]) {
                        std::cout << "run " << run << ": outputs " << outputs[k]
                                  << " ; UNSOUND: const predicted " << cp.v << '\n';
                        ok = false;
                        break;
                    }
                    ++obs;
                }
            }
            if (ok) {
                std::cout << "run " << run << ": outputs";
                for (size_t i = 0; i < outputs.size(); ++i)
                    std::cout << (i ? ", " : " ") << outputs[i];
                std::cout << " ; membership OK\n";
            } else {
                allOk = false;
            }
        }
        std::cout << (allOk ? "SOUND " : "FAILED ") << run << " runs, " << obs
                  << " observations\n";
        return allOk ? 0 : 1;
    }

    if (argc >= 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--run") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        int run = 0;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            Parsed p = parseFile(argv[2]);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);

            std::cout << "run " << ++run << ":";
            for (size_t i = 0; i < outputs.size(); ++i)
                std::cout << (i ? ", " : " ") << outputs[i];
            std::cout << '\n';
        }
        return 0;
    }

    std::cerr << "usage: tipa --check FILE | tipa --emit-ir FILE | tipa --run FILE INPUTS\n";
    return 1;
}
```

**第一段：一次语法分析，四方共用。** --verify-soundness
模式下 parseFile 只调用一次，随后 AST 同时供给四个消费者：
buildCfg（静态分析的图）、signEquations + solveFixpoint
（符号预测）、solveConstFixpoint（常量预测）、interpret
（具体执行）、IRGen（JIT 编译）。这不是省一次解析的优化
问题，而是**正确性问题**。对账的枢纽是 main 中段那张
nodeOf 映射：它把"CFG 节点持有的 Stmt 指针"映射到节点号；
interpret 记录的 sites[k] 也是 Stmt 指针——两种指针指向
同一个对象的前提是它们来自**同一次** buildAst。假如为
JIT 通道重新 parse 一次源文件，会得到一棵全新的 AST、
全新的 OutputS 对象：旧 nodeOf 查不到新指针，nodeOf.at
抛异常（还算幸运）；若把方向反过来、用新 AST 建 nodeOf
而 interpret 用旧 AST，就会拿到**指向已析构对象的悬空
指针**——map 按地址查找碰巧可能命中（旧地址被新对象复用）
也可能查不到，错误以最难排查的形态出现。"第 k 次输出对应
哪条 output 语句"这条对应关系，整个建立在"指针同一性"
之上，而指针同一性建立在"一次解析、处处引用"之上。这是
本章正确性论证不可省略的一环：对应关系不是算出来的，是
用共享所有权**保**出来的。

**第二段：静态预测就位。** solveFixpoint 与
solveConstFixpoint 在循环外各跑一次，产出两份程序点状态。
对账循环体内只做查询、不再求解——静态结论在所有运行间
共享，这正是静态分析的定义：一次分析，覆盖所有输入。

**第三段：双通道执行。** 每读入一行非注释输入，先
interpret 得到 ConcreteRun（值 + 语句户口），再 IRGen +
runJit 得到 JIT 的值序列。两个通道用同一组 inputs、同一棵
AST，但中间形态完全不同——一个走 dynamic_cast 加 map 的
解释路径，一个走 LLVM IR 加 x86 机器码的编译路径。紧接着
的 `outputs == concrete.values` 是第一道断言：两条独立
实现的通道必须产出**完全相同**的输出序列。这道断言同时
看守两边：解释器写错了、IRGen 写错了、JIT 运行时注入的
tip_input/tip_output 有 off-by-one，任何一个都会在这里
炸开。它是后面一切"静态 vs 动态"对账的地基——先确认
"动态"内部自洽，再拿"动态"去考"静态"。

**第四段：逐点对账。** 对第 k 个输出，先由 sites[k] 查
nodeOf 得到程序点 nid，取出该点的两份静态状态 senv 与
cenv，然后做两次断言。

**成员检验（符号）**：把 JIT 输出的具体值经 signOfLiteral
抽象成符号，用 SignLattice::leq 断言它 ⊑ 静态在该点对该
输出表达式求出的符号 predicted。注意 predicted 是对
`site->e`（output 的表达式整体）在 senv 上求值——静态
与动态对账的对象是同一个表达式。predicted == SBOT 单独
判 UNSOUND：静态说这个输出点不可达（或其值无信息），而
现实里输出真的发生了，任何值都不可能 ⊑ ⊥，这是最严重
的一类违反——静态模型与真实控制流脱节了。

**相等检验（常量）**：用 evalConstExpr 在 cenv 上对该
表达式求抽象值，若得到确定常量 cp（kind==1），则 JIT 值
必须与 cp.v 逐位相等。这是常量分析独有的强断言：符号检验
只要求"9 属于 {正数}"，相等检验要求"9 == 11"逐位成立。
静态敢说"必须是 11"，动态就得每次都是 11——少一次相等
都是 UNSOUND。若 cp 是 ⊤（比如输出依赖 input），检验自动
跳过：⊤ 的承诺是"任何整数都可能"，动态出现的任何值都
在 γ(⊤) 之内，无需盘查。若 cp 是 ⊥（静态认为此输出不可
达），理论上也该判违反——本章的实验程序没有这种情形，
实现里 ⊥ 落入"不检查"分支，第 32 章引入可达性分析后
会把这一格补严。

**第五段：计数与裁决。** obs 计数每通过一次断言加一：
每个输出值贡献一次符号成员检验；其表达式被预测为确定
常量时再贡献一次相等检验。循环结束后打印裁决行：
全绿是 `SOUND N runs, M observations`，任何一次违反是
`FAILED ...` 并以非零码退出——CI 里这条命令可以直接当
回归门禁。要准确解读这行字的含义：**SOUND 不是数学意义
的"已被证明"，而是"经受住了这 N 组输入、M 次断言的对抗
未被推翻"**。数学保证来自 16.4 的不动点证明与 17.3 传递
函数的保守性；经验检验的价值在于看守"实现与理论一致"
这条更容易失守的环节。runs 数与 observations 数一起给
出检验的覆盖强度——第 29.6 节将逐字解读两个程序的裁决行。

### 29.5.4 两次断言的语义：同一份 γ 的两种问法

第四段的两次断言值得单独一节，因为它们不是两个随手的
if，而是同一条可靠性定义在不同格上的两次精确投影。把
这个对应写透，读者将来为自己的分析写对账时就知道断言
该怎么长。

**符号成员检验是"v ∈ γ(预测)"的格上翻译。** 可靠性定义
说：每次具体执行的每个可观察值，都必须落在静态预测的
具体化集合里。符号格的 γ 把预测映射成一个整数集合：
γ(+) 是全体正整数、γ(0) 是 {0}、γ(⊤) 是全体整数。
"v 落在集合里"翻译到格上，恰好是 α(v) ⊑ predicted：
α 把具体值压回格元素（signOfLiteral），⊑ 是格序。
这不是巧合而是 Galois 连接的标准性质——抽象函数与
具体化函数互为伴随，"v ∈ γ(p)" 与 "α(v) ⊑ p" 恒等价，
第 25 章埋下的抽象解释理论在这一行 if 上兑现。
predicted == SBOT 的特判也在这里获得准确含义：γ(⊥) = ∅，
"v ∈ ∅"恒假，任何动态值都构成违反——所以代码里根本
不必去计算 leq（也没有值 ⊑ ⊥），直接判 UNSOUND。

**常量相等检验是同一句话在扁平格上的退化形态。** 扁平格
的 γ 像只有三种：∅（⊥）、单点集 {c}、全整数（⊤）。
预测为 ⊤ 时"v ∈ Z"恒真，检验自动免掉——这就是代码里
`if (cp.kind == 1)` 只在确定常量处动作的原因；预测为 c
时"v ∈ {c}"退化成 v == c，一个整型比较；预测为 ⊥ 时
"v ∈ ∅"恒假，严格说应判违反（17.5.3 已注明本章实现
落入了静默分支）。两种格、两份静态预测、两种检验形态，
骨架是同一句"v ∈ γ(预测)"。日后接入任何新域（区间、
幂集、乘积），对账器要做的只是为该域实现一次
"v ∈ γ(预测)"的判定——γ 的像是什么形状，判定就是
什么形状。这份"检验逻辑随域自动换装"的可扩展性，
正是把可靠性定义放在最前面讲的回报。

**两条断言的互补性。** 只做符号检验行不行？不行：符号
说 a=+ 时，动态 11 与 12 都是"合法"的，一个把 a 折成
a+1 的传递函数 bug 不会被符号对账发现。只做常量检验
行不行？也不行：预测为 ⊤ 的输出（依赖 input 的 b）
完全不受盘查，一条把所有变量都顶成 ⊤ 的"退化传递函数"
（恒返回 ⊤，永远保守、永远正确）会轻松通过全部常量
检验——保守到极致的分析没有信息也没有错误。两条断言
合起来正好卡住两端：符号检验惩罚"承诺了却不覆盖"，
常量检验奖励"敢承诺且承诺兑现"。obs 计数把"敢承诺"
显式量化——一个只敢给 ⊤ 的分析 obs 长不上去，检验
覆盖度一目了然。用一句话收拢：**符号检验守下界
（不许错），常量检验量上限（敢多准）**。

### 29.5.5 对账正确性的论证

一个容易被忽略的问题是：通过了这些断言，到底说明了什么？
没通过又说明了什么？把对账器自身的正确性论证写清楚，
SOUND 这个词才站得住。

**断言的语义。** 契约二的形式是：signOfLiteral(v) ⊑
predicted，其中 v 是动态值、predicted 是静态对该表达式
在该点的预测。按可靠性的定义（γ(静态) 覆盖具体行为），
具体值 v 属于 predicted 的具体化集合当且仅当其符号 ⊑
predicted——signOfLiteral 正是"具体值 → 符号域"的抽象
函数 α，断言检查的正是 α(v) ⊑ 静态值，这是"具体 ⊑ 静态"
在格上的标准翻译。契约三的形式是等式 v == c：当静态值
是确定常量 c 时，γ(c) = {c}，"v ∈ γ(静态)"退化为
"v == c"。两个断言都不是随意设计的检查，而是同一条
可靠性定义在两种静态值形态下的精确展开。

**逆否命题才是锋利的那一侧。** 断言失败意味着什么？
意味着存在一个具体执行行为落在了 γ(静态预测) 之外——
按定义，这就是不可靠。而不可靠必有根源：要么传递函数
某行不够保守（比如 join 表抄错、吸收分支写反），要么
预测所查的程序点与真实执行点错位（nodeOf 映射断裂），
要么动态通道自身有 bug（这与静态无关，但同样会让对账
失去意义——所以契约一必须先行）。对账器不定位根源，
它只负责把"理论与实践不一致"这个事实钉在具体的一次
运行、一个输出值上；定位靠的是 17.5.3 分段讲解里那些
结构性的保证。

**为什么只在 output 语句处对账？** 严格说，可靠性是对
所有程序点上所有变量而言的；本章只在 output 处抽查，
是因为 output 是语言里唯一的可观察副作用——一个值的
"错误"只有最终变成可观察行为才能被外部证实。在中间
点对账，需要给每个变量插装观测（打印或断言），那会
改变被测程序本身（海森堡式干预）。output 处的对账是
**无损的**：JIT 与解释器都在完全不被打扰的情况下运行。
代价是覆盖面——变量在中间点的中间值未被盘查。工程上
的补偿手段是把它们人为 output 出来（练习一就这么做），
这也正是测试驱动分析精度演化的朴素起点。

**expected 快照的角色。** 对账的输出本身也被钉进了
expected/soundness/*.txt——连"检验结论"也在回归覆盖
之下。这意味着三类错误各有各的暴露面：静态分析 bug
表现为 UNSOUND 或 obs 数变化；对账器 bug（漏检、重复
计数）表现为 obs 数与手工预测不符；动态通道 bug 表现
为契约一的失败或输出序列变化。快照把三方同时看住，
这是它比"跑通就行"更强的原因。

### 29.5.6 三次假想的失败：对账网眼够细吗

检验的价值取决于它对真实 bug 的网眼密度。与其空谈
"能抓错"，不如故意放三个假想的 bug 进来，逐个推演
对账网能不能接住、在哪一环接住。

**假想 bug 一：cJoin 的相等分支写反**——`a == b` 时
返回 ⊤ 而非 a。后果：fold 点 2 的 a 折出 11 后，任何
汇合都会把它顶成 ⊤；sign1 的循环头 join(entry ⊥, 回边
2) 在第二轮变成 ⊤，output x 的常量预测从 2 塌成 ⊤。
对账表现：常量相等检验静默消失（kind != 1），obs 从
6 掉到 3，SOUND 仍是 SOUND——**弱化但没有错报**。
接住它的是 expected/output.txt 的逐字节比对：CONST 栏
的 11 变 TOP，快照 diff 一目了然。教训：对账抓"不可靠"，
快照抓"变笨"，两道网各管一类退化，缺一不可。

**假想 bug 二：cJoin 的 ⊥ 分支删掉**——两个不同常量
合并时返回了"第一个参数"而不是 ⊤。后果：汇合点
cJoin(5, 7) 得 5，静态承诺变强。对账表现：若动态真跑
出 7，相等检验当场 UNSOUND——这是对账网最得意的
捕获场景，17.5.5 的逆否命题完整生效。但注意它有漏网
条件：动态输入若从未让 else 翼的 7 流到输出（比如
输入永远走 if 翼），对账全程绿灯——**经验检验的
盲区恰好是输入没走过的路径**。解药在输入设计
（17.9 注意点五的反向构造）与理论证明的双重保险。

**假想 bug 三：nodeOf 映射错位一格**——比如构建时
错把 OutputS 映到下一个节点号。后果：预测查询用的
是错误程序点的状态。对账表现：视错位方向而定——
若错位点的预测恰好 ⊒ 正确预测（比如两点都是 ⊤），
检验安静通过；若错位点的符号预测是 ⊥（不可达点），
正常输出也触发 UNSOUND。sign1 只有一个 output，
错位后多半查到 return 或 exit 点——符号格在那里
是 x=+，碰巧与 output 点相同，对账全绿；常量侧同样
x=2，也全绿。**这个 bug 在 sign1 上是网眼外的鱼**。
要接住它，需要更密的程序：多个 output 点、点间状态
有差异——fold 两个输出点夹着一个赋值，就是为此设计
的。这解释了实验程序的第三层用心：不仅要让断言能过，
还要让"错了就过不去"。

三次推演合起来给出对账体系的真实画像：UNSOUND 抓
"过强的承诺"，快照 diff 抓"无端的弱化"，程序设计的
多样性抓"映射与对账的结构性错误"。检验不是一台
机器而是一张网，网眼在不同方向上密度不同——知道
网眼朝哪，才知道往哪条水里放鱼。

### 29.5.7 用 γ 语言逐行重读对账循环

17.5.3 从工程流程角度讲过 --verify-soundness 的五段
流水；本节换一副眼镜，把 main.cpp 对账循环的每一处
判定都翻译成 17.2.7 的 γ 集合关系。同一段代码读两遍
是值得的：第一遍看"程序做什么"，这一遍看"每一步在
可靠性证明里对应哪条事实"。读完这一节，检验代码的
任何一处改动都能立刻判断是否动摇了对账的有效性。

**nodeOf：定位 γ 的自变量。** 静态预测是按程序点存储
的，而 JIT 只给出"第 k 个输出值"。nodeOf 在解析后
遍历所有 FunCfg 的节点、把每条语句指针映射到节点号。
这一步在证明里的角色是确定"本次承诺的 γ 在哪个点
取值"：output 语句 s 对应的承诺是
γ(g_e(状态(nodeOf(s))))。指针同一性保证映射查到的
状态恰为产生该输出的执行点状态——同一次解析构建
AST 与 CFG，语句地址全程序唯一。

**符号断言：一次 γ 成员检验。** 代码行
lat.leq(signOfLiteral(outputs[k]), predicted) 翻译成
集合语言是：signOfLiteral 先把具体值 v 按符号抽象化
（α 的符号格版本：v>0 得 +、v=0 得 0、v<0 得 -），
leq 检验该抽象符号 ⊑ 预测符号。等价的具体化写法是
v ∈ γ_sign(predicted)：预测 + 要求 v>0、预测 ⊤ 放任、
预测 0 要求 v 恰为 0。这里多绕了一层 α 是因为代码
直接复用符号格的 leq，避免展开集合；两步的等价性由
α、γ 的单调对应保证（17.2.7 同型事实在符号格上的
复刻）。

**常量断言：γ(c) 是单元素集。** 只有 cp.kind==1 时才
做相等检验，原因用 γ 一读就清楚：γ(c) = {c}，成员
关系 v ∈ {c} 等价于 v = c，即代码中的 cp.v !=
outputs[k] 翻案。对 cp.kind==2（⊤），γ = Z，成员
关系恒真，写断言也是恒真，省掉。对 cp.kind==0（⊥），
γ = ∅，成员关系恒假——若真在此处输出了值，意味着
"不可达点被执行"，本身就是一桩异常；代码选择不检验
这一格，等价于把"不可达点不会产生输出"留给 CFG 构造
与具体语义保证，而不是让对账循环每轮处理这个先验。

**先符号后常量的次序。** 循环对同一输出先查符号、再
查常量，任一失败立即 break。次序不是任意的：符号承诺
几乎处处存在（符号格对每个点每个变量都给值），是更
密的底层网；常量承诺只在少数点存在，是局部加强。
底层先破则上层无检验意义。obs 同时为两种检验计数，
因此 sign1 的 6 observations = 3 次执行 ×（1 个输出
点上的 2 道承诺：符号 + 常量），fold 的 9 = 3 × 3
（两个输出点：点 4 上符号与常量两道、点 5 上仅符号
一道，合计每执行 3）。练习七要求写脚本静态预测 obs，
算法正是按这个口径数承诺。

**解释器交叉核对的证明含义。** 代码先算
ConcreteRun concrete = interpret(...)，再以
outputs == concrete.values 为前提进入循环。这行比较
在证明里是"户口可信"的引理：sites[k] 声称第 k 个值
来自某条 output 语句，该声明的正确性依赖解释器与 JIT
同语义；值序列逐元素相等是同语义的必要证据（对所选
输入成立）。若将来 TIP 加新语义（如短路求值）而只改
了一处，两边的值序列首先分叉、循环根本不进入——比起
拿着错位的 sites 查错状态，这种 fail-closed 行为把
"设施失配"与"分析不可靠"两类故障明确分开。

**裁决行的逻辑强度。** 全循环无翻案才打印 SOUND 并以
0 退出。按证明结构读，一次 SOUND 的完整含义是：对
.inputs 中每个输入组，解释器与 JIT 同值、每个输出
点上符号与常量两道 γ 成员关系成立。它是一长串有限
合取——可靠性全称命题（对所有输入、所有路径）的
一个有限样本。CI 把退出码接成门禁，守住的是"已知的
承诺不被新改动推翻"这一回归性质；把它读作"分析已被
证明可靠"则超出了合取的量化范围。17.6.6 的灰区讨论
是此区别的具体实例。

### 29.6.1 两个实验程序

本章准备了两个各司其职的 TIP 程序。fold.tip 考察**表达式
折叠**：纯常量表达式、常量与输入的混合、以及"常量进入
output"三个场景，没有循环——它验证的是传递函数本身的
折叠能力。sign1.tip 考察**循环携带的常量**：循环体里
y = 1、x = y + 1，两个变量每轮被重写成同一个值——它验证
的是不动点迭代能否在环上稳住一个常量，而不是退化成 ⊤。

```text
// file: programs/fold.tip
main() {
  var a, b;
  a = 3 + 4 * 2;
  b = a * 2 + input;
  output a;
  output b;
  return 0;
}
```

```text
// file: programs/sign1.tip
main() {
  var x, y;
  while (input > 0) {
    y = 1;
    x = y + 1;
  }
  output x;
  return 0;
}
```

fold.tip 里 `3 + 4 * 2` 依赖 TIP 文法的优先级：mulExpr 产生
式排在 addExpr 之前，乘法先结合，抽象语法树是 (+ 3 (* 4 2))
——expected 输出里前缀式打印的正是这棵树，结果是 11 而不
是 14。b = a * 2 + input 则是刻意构造的"半常量"：a 确定，
input 不确定，b 只能是 ⊤。sign1.tip 的循环条件 input > 0
保证循环次数由输入决定，但循环体写的值与输入无关——正是
"控制流依赖输入、数据流不依赖输入"的典型形状，常量分析
最喜欢的猎物。

### 29.6.2 --check：符号与常量两栏并排

对两个程序跑 tipa --check，expected/output.txt 逐字节如下。
程序点编号沿用第 25 章的 CFG 编号（1=entry，随后按源码
顺序，最后 exit），每个点先列 SIGN 栏再列 CONST 栏。

```text
; expected: expected/output.txt
== fold.tip ==
SIGN (worklist least fixpoint):
-- main --
  1 entry: a=⊥ b=⊥
  2 assign  a = (+ 3 (* 4 2)) ;: a=+ b=⊥
  3 assign  b = (+ (* a 2) input) ;: a=+ b=⊤
  4 output  output a ;: a=+ b=⊤
  5 output  output b ;: a=+ b=⊤
  6 return  return 0 ;: a=+ b=⊤
  7 exit: a=+ b=⊤
CONST (flat constant lattice, least fixpoint):
-- main --
  1: a=BOT b=BOT
  2 a = (+ 3 (* 4 2)) ;: a=11 b=BOT
  3 b = (+ (* a 2) input) ;: a=11 b=TOP
  4 output a ;: a=11 b=TOP
  5 output b ;: a=11 b=TOP
  6 return 0 ;: a=11 b=TOP
  7: a=11 b=TOP
== sign1.tip ==
SIGN (worklist least fixpoint):
-- main --
  1 entry: x=⊥ y=⊥
  2 branch  while (> input 0): x=+ y=+
  3 assign  y = 1 ;: x=+ y=+
  4 assign  x = (+ y 1) ;: x=+ y=+
  5 output  output x ;: x=+ y=+
  6 return  return 0 ;: x=+ y=+
  7 exit: x=+ y=+
CONST (flat constant lattice, least fixpoint):
-- main --
  1: x=BOT y=BOT
  2 branch  while (> input 0): x=2 y=1
  3 y = 1 ;: x=2 y=1
  4 x = (+ y 1) ;: x=2 y=1
  5 output x ;: x=2 y=1
  6 return 0 ;: x=2 y=1
  7: x=2 y=1
```

先看 fold.tip 的 CONST 栏，逐点走一遍不动点的形成过程。

**点 1（entry）**：`a=BOT b=BOT`。main 无形参，入口边界
是空环境；a、b 尚未赋值，打印器对缺键补 BOT。⊥ 的语义是
"还没有任何信息"——进入函数时两个局部变量都没有事实。

**点 2（a = 3 + 4 * 2）**：`a=11`。传递函数对表达式
(+ 3 (* 4 2)) 做后序折叠：4 与 2 折成 8，3 与 8 折成 11，
cVal(11) 写入 a。sign1 同一位置的 SIGN 栏是 `a=+`——
符号分析只知道"正"，常量分析知道"是 11"。**同一台
worklist、同一张 CFG，换格的直接收益就是精度从"+变细到
11"**。b 在此点仍是 BOT：b 还没有被写，缺键即 ⊥。

**点 3（b = a * 2 + input）**：`b=TOP`。表达式
(+ (* a 2) input) 的折叠过程值得手推一遍：a 查环境得
cVal(11)，2 是字面量 cVal(2)，相乘得 cVal(22)；另一子树
input 直接给 cTop()。到加法分派时两操作数是 cVal(22) 与
cTop()——命中"⊤ 吸收"分支，结果 cTop()，b 被写成 ⊤。
这就是 17.3.2 说的"一刀切"：22 + 任何整数的结果空间是
全体整数，扁平格没有更细的元素可用。

**点 4–7**：a=11、b=TOP 原样透传到出口。output 与
return 不改环境，常量 11 一路存活到函数出口。

再对照 SIGN 栏读同一程序，两处差异最醒目。其一，点 2 的
a：SIGN 栏说 a=+，CONST 栏说 a=11——符号格与常量格对
同一个事实给出两种粒度的预测，17.5 的对账里两种预测都要
分别过关（符号上 11 的符号是 +，成员检验过；常量上 11==11，
相等检验过）。其二，点 3 之后 b：SIGN 栏 b=⊤，CONST 栏
b=TOP——两个格在这里殊途同归于顶，但语义不同：符号格的
⊤ 是"正负皆可能"，扁平格的 ⊤ 是"任何整数皆可能"。

sign1.tip 的 CONST 栏是本章技术含量最高的输出。循环头
点 2 显示 `x=2 y=1`——**两个循环携带的常量在不动点里
活了下来**。手推一遍迭代看这是怎么发生的：第一轮从 entry
进循环，y := 1 写入 cVal(1)，x := y + 1 折叠成 cVal(2)；
回边把 {x=2, y=1} 送回循环头，与 entry 侧的全 ⊥ 逐变量
join——⊥ ⊔ 2 = 2、⊥ ⊔ 1 = 1，循环头保持常量；第二轮
循环体重算，y 仍是 1、x 仍是 2，**与旧值相等，迭代收敛**。
环上稳定的常量不会触发 c₁ ⊔ c₂ = ⊤，因为每次合并的
两个值要么一方是 ⊥、要么相等。这就是 29.4 节说的安全绳
在真实数据上的形态。

反例一念即明：若把循环体改成 `x = x + 1`，第一轮 x=2，
回边带 2 回头，第二轮体里 x := 2+1 = 3，回边再带回 3，
循环头 join(2,3) = ⊤——自累加变量在扁平格上一步破顶，
此后永远 ⊤。sign1 之所以能守常量，是因为体里的赋值是
**幂等的**（每轮写同一个值）；累加变量不幂等，常量性
即失。工业编译器对循环归纳变量的专门处理（强度削减、
归纳变量分析）正是为了从 ⊤ 的废墟里抢回这类信息——
那超出扁平格的能力，属于第 34 章之后的区间/仿射世界。

SIGN 栏的 sign1 部分（x=+ y=+）与第 28 章逐字一致——
同一段输出在两章出现两次，含义不同：第 28 章它是主角
（不动点如何收敛），本章它是**对照组**（换格前后精度
对比的基准）。

sign1 的 CONST 栏值得再逐行走一遍，因为七行输出里的
每一行都在回答一个不同的问题。

**行 1 `1: x=BOT y=BOT`**——回答"入口处知道什么"：
什么也不知道。⊥ 是出发姿态，与第 28 章符号侧的全 ⊥
起点一致。

**行 2 `2 branch while (> input 0): x=2 y=1`**——循环
头，全章最重的一行。它同时是汇合点（前驱：entry 与
回边 4）与分支点（条件 input > 0）。常量分析不读条件，
两条出边都当作可行；但两条入边的合并给出了 x=2、y=1——
**循环没有毁掉常量，因为循环携带的值恰好幂等**。
对比 SIGN 栏同一行的 x=+ y=+：两个格在同一个点上给出
不同粒度的同一事实。

**行 3 `3 y = 1 ;: x=2 y=1`**——y 被重写为 1（它本来
在入边就是 1），x 透传。注意这行的环境在赋值**之后**：
打印的是"该点执行完"的状态，因此 x 已经在列——x 的
值来自前驱合并，不是这行算出来的。读输出时"行内变量
是流入的，被赋值变量是刚算的"这一区分，是读懂一切
数据流表的关键。

**行 4 `4 x = (+ y 1) ;: x=2 y=1`**——折叠发生点。
y 查表得 cVal(1)，与字面量 1 相加得 cVal(2)，写回 x
（覆盖合并来的 2，结果相同）。假如 y 是 ⊤，此行会把
x 顶回 ⊤——行 2 的常量能否存活，完全押在体内每一次
重算的结果上。

**行 5 `5 output x ;: x=2 y=1`**——对账的主战场。
17.5 的两次断言都在这一行的状态上进行：符号侧取 x=+
做成员检验，常量侧取 x=2 做相等检验。静态表上这一行
与行 4 看起来一样，语义却不同——它是"状态被消费"的
地方，而前面各行只是"状态被搬运与更新"。

**行 6 `6 return 0 ;: x=2 y=1`** 与 **行 7 `7: x=2 y=1`**
——透传与出口。0 是返回值不是变量状态；出口处两个
局部变量仍然活着（TIP 没有作用域块级出栈的抽象必要，
本章的分析也不做活性剔除——第 30 章的活跃变量分析
会回答"哪些变量此刻的信息还值得携带"）。

七行合起来的叙事是：⊥ 起步 → 循环头合并守常量 →
体内重算自洽 → 出口满载常量离开。与第 28 章 SIGN 栏
的十三步迭代对读还能看到一层结构差：常量侧的迭代
轮数与符号侧完全相同（同样的图、同样的回边、同样的
收敛节奏），差异只发生在每一步"值变成什么"——引擎
与组件的分工，在时间轴上也成立。

### 29.6.3 经验检验的运行与裁决

--verify-soundness 的输入文件每行一组输入，# 开头是注释。
sign1.tip 的输入集（第 28.7 节预告过的设计）首输入全为正、
末位为 0——保证循环体至少执行一轮（读到的 x 一定已被
赋值，尊重第 32 章未初始化分析与本分析的分工），同时用
不同的首轮值与循环轮数覆盖多条执行路径。

```text
; expected: expected/soundness/sign1.inputs
1 0
2 1 0
5 -3 0
```

三组输入下的输出都是 2：y=1、x=y+1 与输入无关——这正是
静态预测 x=2 所断言的。运行 --verify-soundness，真实输出：

```text
; expected: expected/soundness/sign1.txt
run 1: outputs 2 ; membership OK
run 2: outputs 2 ; membership OK
run 3: outputs 2 ; membership OK
SOUND 3 runs, 6 observations
```

裁决行 `SOUND 3 runs, 6 observations` 的计数可精确复算：
每次运行有 1 条 output 语句（output x），三次运行共 3 次
符号成员检验（JIT 值 2 抽象成 +，⊑ 静态预测 +，通过）；
output x 的表达式在 CONST 栏预测为确定常量 2，每次运行
再贡献 1 次相等检验（2 == 2，通过）。3 + 3 = 6 次断言，
与 observations 精确吻合。**这个数可以也应该被读者手工
预测出来**——它是"对账在对什么"的最直接自检：如果哪天
obs 数对不上手工计数，说明检验流程本身漏了断言或重复
计数。

fold.tip 的输入集换个策略：三条输入各不相同（7、−5、0），
b = 22 + input 因此取三个不同的值 29、17、22——相等检验
在 output b 处必须**自动跳过**（b 的静态预测是 ⊤，没有
可违反的常量承诺），而 output a 处的 11 必须三次全中。

```text
; expected: expected/soundness/fold.inputs
7
-5
0
```

```text
; expected: expected/soundness/fold.txt
run 1: outputs 11, 29 ; membership OK
run 2: outputs 11, 17 ; membership OK
run 3: outputs 11, 22 ; membership OK
SOUND 3 runs, 9 observations
```

计数同样可复算：三次运行 × 2 条 output = 6 次符号成员
检验；output a 在三次运行中都被预测为常量 11 且三次
动态值恰为 11，贡献 3 次相等检验；output b 的预测是
TOP，零次。6 + 3 = 9 次断言。注意 run 1 的输出序列
"11, 29"里藏着双重验证：第一个值过的是"常量 11"的
相等检验，第二个值 29 只过"符号为 +"的成员检验——
静态分析对两个输出给出了不同强度的承诺，对账程序对
两种承诺分别执行了不同强度的检查，**承诺与检查的强度
一一对应**，这正是 γ 定义在经验层的投影。

还有一个隐蔽的对账点值得指出：每行输出序列本身已经
先过了 `outputs == concrete.values` 这道内部一致性
检查——JIT 通道与解释器通道独立产出相同的值序列。
也就是说 fold.txt 每一行的 "11, 29" 同时为三套机器
（解释器、JIT、静态分析）背书：前两套一致地认为输出
是这些值，第三套认为这些值必须 ⊑ 它的预测。三方对账
的每一方都有独立的出错方式，而 expected 快照把三方
一致的结果钉死成回归基线。

### 29.6.4 逐点精度对照：静态承诺的强度谱

把两个程序的静态结论按"承诺强度"排成一张表，会看到
常量分析在同一个程序里同时给出三个等级的承诺——这比
笼统地说"常量分析比符号分析准"更能说明格设计如何
决定预测能力。

| 程序点 | 符号预测 | 常量预测 | 动态观察 | 对账动作 |
|---|---|---|---|---|
| fold 点 4（output a） | a=+ | a=11 | 恒为 11 | 符号成员检验 + 常量相等检验 |
| fold 点 5（output b） | b=⊤ | b=⊤ | 29/17/22 | 仅符号成员检验 |
| sign1 点 5（output x） | x=+ | x=2 | 恒为 2 | 符号成员检验 + 常量相等检验 |

第一行是承诺的满配：静态既知道符号（+）又知道常量
（11），动态值两头都过。第二行是承诺的底线：两个格
都到顶，静态不承诺任何东西，动态出现什么都在覆盖范围
内——注意即使在这里符号检验也没有跳过：⊤ 的成员检验
是平凡成立的（任何符号都 ⊑ ⊤），代码里照样执行了一次
leq 并计入 obs。第三行最有意思：同一个变量 x，符号格
说"+"而常量格说"2"——动态值 2 与两个预测都相容，但
相等检验只有常量格能触发。**预测的强度由格的粒度决定，
检验的强度自动跟随**——对账器不关心格长什么样，它只
按 γ 的定义行事。

这张表也解释了为什么 fold 的 obs（9）比 sign1 的 obs
（6）多：fold 有两个输出点，其中一个是满配承诺；sign1
只有一个输出点，同样是满配。observations 数 = Σ 每次
运行每个输出的（1 + [该输出预测为确定常量]）。读者
可以拿任意自己的程序预测 obs，再与机器对——预测失误
的地方往往就是对账设计理解有偏差的地方。

### 29.6.5 输出格式的几条约定

解读输出时用到四条打印约定，统一记在这里。其一，程序
点编号从 1 开始、按源码先序分配，entry 恒为 1，exit
在最后（第 14 章两遍构造的确定性保证）。其二，每个点
先打印语句文本再打印冒号与状态，分支点只打印条件
（`while (> input 0)`）不打印循环体——体在后续点各自
成行。其三，变量按"形参在前、var 声明在后"的固定顺序
打印，全部打印、不省略 ⊥——fold 点 1 的 `a=BOT b=BOT`
因此占满一行。其四，符号域打印 Unicode 字符（⊥、+、⊤），
常量域打印大写单词（BOT、TOP、数字）——两栏在视觉上
一眼可分，17.6.2 的输出里不会有任何一行混淆归属。

还有一条隐含约定值得点破：CONST 栏的语句文本行在点 1
（entry）与点 7（exit）为空——这两个点不持有语句，
打印器直接写编号与冒号（`  1: a=BOT b=BOT`）。这与
SIGN 栏的 `1 entry:` 格式略有差别（printConstEnv 对
entry/exit 不打印类型名），是打印器各自的取舍，不影响
语义；逐字节对账时以 expected 为准。

### 29.6.6 慢放：两份快照的逐次重放

17.6.2 的快照是不动点到达后的静态画面；本节把求解过程
本身慢放，按节点编号逐个重放 worklist 的弹出与写回。
亲眼看一遍信息如何在直线代码上顺流、在循环上回流，是
理解"为什么快照恰好长这样"的最直接路径，也为第 28 章
的算法描述提供一个完整的第二实例。

**fold.tip：一次顺流，零回流。** 初始队列只有节点 1，
所有点状态缺键。第一次弹出 1（entry）：边界条件是
空环境，写回 {}，后继 2 入队。弹出 2（a = 3 + 4*2）：
合并前驱（1 的 {}）仍为空，evalConstExpr 折叠
3+4*2：先折 4*2=8，再折 3+8=11，写回 {a=11}，3 入队。
弹出 3（b = a*2 + input）：入值 {a=11}，a*2 折成
22，input 得 ⊤，⊤ 吸收加法，写回 {a=11, b=⊤}，
4 入队。弹出 4（output a）：传递函数对 Output 节点
是恒等（输出不改变环境），状态保持 {a=11, b=⊤}，
5 入队。弹出 5（output b）同理，6 入队。弹出 6
（return 0）：Return 节点不改动环境，状态保持，
7 入队。弹出 7（exit）：恒等，无后继。队列空。

全程七次弹出、两次真正的写回（点 2 与点 3），信息
严格沿编号增大方向流动一次，没有任何节点被第二次
处理。直线程序是 worklist 最省力的形状：队列长度在
任意时刻不超过 1，总工作量等于节点数。快照里每个点
的状态都能在上面的重放里指认来源：a=11 诞生于点 2
并一路恒等搬运到点 7，b=⊤ 诞生于点 3 同理；点 1 的
a=BOT b=BOT 不是写回的内容而是打印器把缺键显式化为
⊥——"空环境"与"两个变量都不可达"在打印层是同一行。

**sign1.tip：先顺流一遍，再沿环回流一遍。** 节点
布局：1 entry，2 为 while 条件分支点，3（y=1）、
4（x=y+1）是循环体，5（output x）、6（return 0）、
7 exit。边：1→2；2 在条件为真时→3、为假时→5；
3→4；4→2（回流边）；5→6→7。

第一阶段顺流，与 fold 同形。弹出 1，写回 {}，2 入队。
弹出 2（分支点，传递恒等），入值 {}，写回 {}，它的
两个后继 3、5 同时入队——队列此刻长度 2。按 FIFO
先弹出 3：入值 {}，折 y=1，写回 {y=1}，4 入队。弹出
5（队列里早先排入的 output）：入值 {}（此时 4 尚未
处理，从 2 经假边带来的也是空环境），恒等，写回 {}，
6 入队。弹出 4：入值 {y=1}，折 x=y+1：y=1 命中，
x=2，写回 {x=2, y=1}——回流边 4→2 让 2 重新入队。
弹出 6：入值 {}，恒等，7 入队。弹出 7：恒等。至此若
无环，求解已结束；但队列里还有回流的 2。

第二阶段回流。再次弹出 2：合并其全部前驱——1 带来
{}、4 带来 {x=2, y=1}——逐格 join：
x: cJoin(⊥,2)=2，y: cJoin(⊥,1)=1，入值
{x=2,y=1}，与点 2 的旧状态 {} 不等，写回；两个后继
3、5 再次入队。弹出 3：入值 {x=2,y=1}（前驱 2 现在
带着循环的信息），折 y=1，出口 {x=2,y=1}，与旧状态
{y=1} 不等（x 从缺键变 2），写回，4 入队。弹出 5：
入值 {x=2,y=1}（经假边从 2 来），恒等，与旧状态 {}
不等，写回，6 入队。弹出 4：入值 {x=2,y=1}，折
x=y+1=2，出口 {x=2,y=1}，与旧状态相同——**回流在此
第一次被吸收**，2 不再入队。弹出 6：入值 {x=2,y=1}，
与旧 {} 不等，写回，7 入队。弹出 7：同上写回。队列
空，第二阶段结束。

快照与重放逐行对账：CONST 栏里点 2 的 x=2 y=1 诞生
于第二阶段首次重处理 2（回流首次到达分支点）；点 3、
4 的状态在第二阶段被"从后方带来的信息"各补写一次；
点 5、6、7 沿假边把回流信息继续送出。值得注意的是
点 4 的折叠结果在两个阶段完全一致（都是 2）——求解器
仍然重算了它（因为点 3 变了），只是写回比较拦住了
后续传播。**单调框架的省工作量全部发生在"比较相等"
这一步**：重算廉价、传播昂贵，宁可多重算几格也要把
回流的传播范围压到最小。

**重放中的语义灰区。** 点 5 的最终状态 x=2 是经假边
（循环条件为假、退出循环）到达的，但 x=2 这个值诞生
于循环体内。对"循环至少执行一次"的执行，这是实话；
对"循环一次不执行"的执行，沿假边到达点 5 的应是
"x 未初始化"，而第一阶段点 5 的空环境恰恰如此——
第二阶段的回流把它覆盖成了 2。MFP 在汇合处无法保留
"这个值只在绕环后才存在"的出身信息（17.4.3 的
MOP/MFP 差距）。快照因此只对"首值 > 0"的执行可靠；
检验输入恰好全部满足。把这条重放多看两遍，就能体会
经验性 soundness 报告的量化范围为什么必须连同输入文件
一起阅读：求解过程没有任何一步算错，承诺的覆盖面是
框架形状预先决定的，输入设计只决定这次去触碰覆盖面的
哪一部分。

## 29.7 与 LLVM SCCP 对照

把同一个前端产出的 IR 交给 LLVM 的常量传播 pass，是本章
的第三条对照线。命令只有一行（expected/opt/sccp.cmd 存档）：
第 15 章的 --emit-ir 打印未优化模块，管道送给 opt 的新
pass 管理器，`-passes=sccp` 指定稀疏条件常量传播，`-S`
要求输出可读汇编格式的 IR。

```text
; expected: expected/opt/sccp.cmd
export PATH=/ucrt64/bin:$PATH && build/29_sign_const/tipa --emit-ir examples/29_sign_const/programs/fold.tip | opt -passes=sccp -S
```

对 fold.tip 的真实输出如下。读它之前先回忆未优化 IR 的
形状（第 15 章）：每个 TIP 变量对应一个 alloca 槽位，每次
赋值是 store、每次读取是 load，irgen 还给局部变量垫了
store i32 0 的零初始化。

```text
; expected: expected/opt/sccp.out
; ModuleID = '<stdin>'
source_filename = "tip"

declare i32 @tip_input()

declare void @tip_output(i32)

define i32 @tip_main() {
entry:
  %a = alloca i32, align 4
  store i32 0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 0, ptr %b, align 4
  store i32 11, ptr %a, align 4
  %a1 = load i32, ptr %a, align 4
  %0 = mul i32 %a1, 2
  %1 = call i32 @tip_input()
  %2 = add i32 %0, %1
  store i32 %2, ptr %b, align 4
  %a2 = load i32, ptr %a, align 4
  call void @tip_output(i32 %a2)
  %b3 = load i32, ptr %b, align 4
  call void @tip_output(i32 %b3)
  ret i32 0
}

define i32 @tip_entry() {
entry:
  %0 = call i32 @tip_main()
  ret i32 %0
}
```

逐行与我们的常量分析对读，第一处对照是最漂亮的一处
**一致**：`store i32 11, ptr %a`。未优化 IR 里这个
store 的操作数是一串 add/mul 指令（3、4、2 三个常量的
计算链）；SCCP 把整条链折叠成常量 11 直接塞进 store——
这与我们 CONST 栏的 `a=11` 是同一个事实的两种表述：
**源层的 a=11 与 IR 层的 store i32 11 是同一个抽象解释
结果在两个表示层上的投影**。两台独立实现的分析器
（我们的 AST 级 worklist、LLVM 的 SCCP）在同一个程序上
给出互相印证的折叠。

第二处对照是一处醒目的**差异**：SCCP 止步于 store i32 11，
此后的 `%a1 = load i32, ptr %a` 与 `%0 = mul i32 %a1, 2`
原样保留——22 没有被算出来，output a 读到的值也没有被
替换成 11。而我们的 CONST 栏在点 3 之后仍然坚持 a=11。
原因不在 SCCP 能力不济，而在**作用层**：SCCP 的格值附着
在 SSA **寄存器**上，沿 def-use 边稀疏传播；alloca/store/
load 是内存操作，对 SCCP 是不透明的——load 读到什么
取决于运行时内存，SSA 值层面无话可说。把 store-to-load
的转发交给 mem2reg（或先跑 SROA 把 alloca 提升成寄存器）
之后，a 就变成 SSA 名字，SCCP 立刻能把 22 与 output 的
11 全部折出来——工业流水线里 sccp 从不单独作战，它的
前后总是站着 mem2reg 这样的"让 SSA 真的稀疏起来"的
预处理。我们不必经历这道弯：源层分析直接以变量为状态，
天然"稀疏地"知道 a 的值，代价是要自己处理控制流汇合
（稠密的环境合并）。

第三处对照落在名字上：SCCP 的三个词各有出处。**sparse**
——格值不挂在程序点上、挂在 SSA 值上，一个值的结论直接
喂给所有使用者，无需整片环境的搬运与合并（对比我们每点
一份 ConstEnv、汇合处逐变量 join 的稠密形态）；**conditional**
——常量条件会反馈回控制流：若某分支条件被折叠成常量，
不可行的分支边被标记为不可达，其中的代码按 ⊥ 处理，
这正是我们 17.2.3 的 ⊥ 语义在 LLVM 层的实现（LLVM 术语
里不可达/无信息的状态叫 undef，冲突顶叫 overdefined——
undef/constant/overdefined 三层与我们的 ⊥/c/⊤ 一一
对应，顶底角色完全一致）；**constant propagation**——
不动点迭代本身，与第 28 章同一套 Knaster–Tarski 机器。
把三件套翻译回本教程的语言：**SCCP = 扁平常量格 + 稀疏
def-use 传播 + 以格值反过来修剪 CFG 的不动点求解**。
第 27 章把方程组当作"CFG 的另一种读法"，SCCP 把这句话
推到极致——方程组的解反过来改写方程组所在的图。

最后核对一遍 sccp.out 里的"没动"清单，它们同样是对照
的一部分：两个 `store i32 0` 是 irgen 的零初始化，运行
时语义必需，SCCP 正确地不动它（0 是运行时写入的值，
不是可消除的死代码）；`call i32 @tip_input()` 原样保留
——外部调用对常量分析是天然的 ⊤ 源，与我们 transfer
里 InputE → cTop() 的决策一致；tip_entry 包装函数与
第 15 章的输出逐字相同。一张输出快照里，该折的折了、
该留的留了、该顶的顶了——SCCP 与我们的分析在"保守性"
上完全同调，差异只在精度落点——作用层的差别，上面第二处
对照已经说明。

### 29.7.1 SCCP 的两相结构与概念对照表

把对照里散落的点收拢成一张表，再补一个尚未讲到的结构
特征——SCCP 的"条件"来自它的两相求解。

| 概念 | 本教程的形态 | SCCP 的形态 |
|---|---|---|
| 抽象域 | {⊥, c, ⊤}，c 为 int | {undef, constant, overdefined}，c 为 LLVM 常量 |
| 格值附着点 | 程序点（稠密环境） | SSA 值（def-use 边，稀疏） |
| 不可达信息 | ⊥ 传染进方程 | undef 标记不可达块，值沿边剪除 |
| 冲突顶 | c₁ ⊔ c₂ = ⊤ | 标记 overdefined，停止精化 |
| 求解器 | worklist，从 ⊥ 上升 | worklist，两相交替到不动点 |
| 条件反馈 | 无（CFG 固定） | 常量条件剪掉不可行边 |
| 内存 | 源层变量直接可见 | 不透明，需 mem2reg 预处理 |

两相求解是 SCCP 名字里 "conditional" 的机制来源，值得
单独一段。经典稠密求解器（本章）把 CFG 视为固定骨架：
所有边都当作可行，格值只沿边流动。SCCP 把问题拆成两
个互相喂养的子问题：**流分析相**回答"哪些 CFG 边是可行
的"——一个分支条件若已折叠成常量 1，则 else 边不可行，
其上的块标为 undef（⊥）；**值分析相**回答"每个 SSA 值
是什么常量"——undef 操作数按 ⊥ 吸收，冲突标记
overdefined。两相交替迭代直到都不再变化。这相当于把
"格值"与"控制流可达性"放进同一个方程组联立求解——
第 27 章说"方程组是 CFG 的另一种读法"，SCCP 则让读出
的方程组反过来改写 CFG 本身。效果上，不可行分支里的
常量计算被整体免掉，汇合处也就少了几次 c₁ ⊔ c₂ 的
提前破顶——这正是我们 29.9 节要谈的"路径敏感化"的
第一步。

表里"从 ⊥ 上升"与 LLVM 术语的对应还需一个注脚：SCCP
的实现里格值从"unknown"（尚无结论）出发，向 constant
或 overdefined 两个方向落定；就偏序而言 unknown 位于
最底（与 undef 同层使用），overdefined 是吸收一切冲突
的顶。方向看似与我们的"从 ⊥ 上升"不同，实质相同：
都是从一个"零信息"的起点出发，只在证据允许的范围内
收敛到更具体的结论，冲突即封顶。格论不关心实现术语，
只关心序结构与单调性——这也是为什么本章能把两台
相隔一个生态的分析器放在同一张表里逐行对照。

### 29.7.2 一次带条件折叠的推演：SCCP 多看见了什么

sccp.out 里没有分支，"conditional"三个字母的存在感
不强。补一个纸上推演：给 fold.tip 添一个恒真分支——

```text
if (2 > 1) { a = 5; } else { a = 7; }
output a;
```

我们的分析（本章）：不读条件，两翼都可行。汇合处
cJoin(5, 7) = ⊤，output a 的常量预测是 ⊤——相等检验
自动豁免，只做符号成员检验。**恒真分支在我们手里
照样杀死常量**（17.2.6 的方案四）。

SCCP（同一份 IR 经 mem2reg 后）：值分析相把条件
2 > 1 折成常量 1；流分析相看到常量真条件，把 else 边
标为不可行，else 块整体 undef（⊥）；汇合处参与合并的
只有 if 翼的 5，output a 的实参被替换成常量 5；更进一步，
else 块里那条 store i32 7 作为不可达代码可以被
后续清理 pass 删除。同一份程序，SCCP 多看见了三样东西：
条件的常量性、不可行的翼、以及随之保全的 a=5。

推演的重点不是"SCCP 更强"——它强在特定的维度上——
而是**信息在分析之间的可回收性**：条件折叠的原料
（常量算术）与数据流折叠的原料是同一个格、同一套
运算，SCCP 只是让两处消费者共享一次计算。我们的
引擎同样握着这份原料（17.3.2 末尾说过 Gt/Eq 折叠出
cVal(0/1)），只是没有接上消费者。第 30 章实现死代码
消除时会把这条线接上：常量条件 → 可达性剪枝 → 死分支
报告，三步全部发生在本教程现有机器之内，不需要任何
新域。到那时回头看，SCCP 的"conditional"不过是把
两件我们已经会做的事接了一根线。

### 29.7.3 对照的适用边界

最后给这场对照立两块界碑，防止把结论用过头。

第一块：**作用层不同的两台分析器不可互相替代**。我们
的源层分析看到的是变量与语句，SCCP 看到的是 SSA 值
与内存操作；前者适合喂给源层工具（告警、验证、教学
追踪），后者适合喂给代码生成。17.7 开头"a=11 与
store i32 11 是同一事实的两种投影"说的是**结论可
对照**，不是说**能力可互换**——把 SCCP 的输出翻译回
"每个 output 处每个变量的常量"需要额外的映射层，
把我们的环境翻译成 IR 变换需要完整的 lowering。两层
各留一台分析器，恰是编译器生态的现状。

第二块：**expected/opt/sccp.out 是环境敏感的快照**。
opt 的输出带 ModuleID 与版本相关的细节，LLVM 升级后
格式可能微调；sccp 本身的折叠行为相对稳定（扁平格
的语义是格论承诺，不随版本变），但打印格式、pass
管线默认值都可能动。这份快照的复验命令就在
sccp.cmd 里，环境变化时重跑一次、diff 审查、有意
接受变化即可——与 17.9 注意点七的快照合同同一条
纪律。对照的价值在"两个引擎当前对同一程序说了什么"，
而不在任何一方的永久承诺。

### 29.7.4 对照补遗：逐值追踪 SCCP 在 fold 模块上的动作

17.7.1 给了概念对照表、17.7.2 给了条件折叠推演；本小节
做最后一步收尾工作：拿 sccp.out 的实际 IR 逐值核对
SCCP 的内部状态迁移，把"过/不过每条指令时格值如何变化"
完整走一遍。这是把 17.7 全部抽象对照钉在一份真实输出上
的练习。

SCCP 处理 fold 模块时面对的初始状态：所有 SSA 值
undefined（⊥），唯一已知的可执行块是 entry。按指令
顺序推进：%a、%b 的 alloca 不产生格值（内存地址不是
标量值）；两条 store i32 0 是 IRGen 对 TIP 变量预置的
零值，SCCP 只记账"该地址当前存过常量 0"；store
i32 11 是 SCCP 真正等待的事件——它对应源码
a = 3 + 4*2，IRGen 在生成时已经由自己的前端完成了折叠
（sccp.out 里根本没有出现 3、4、8 的指令，只有
store i32 11）。这一点值得注意：**对照实验里 11 由本教程
的 AST 常量折叠产生，SCCP 只是照单接收**；若想看 SCCP
亲手折 11，需要让 IRGen 不做前端折叠（把算术保留为 IR
指令）。两个引擎都能折 11，但 sccp.out 只展示了后者接
收前者结论的情形——阅读对照快照时不要把功劳错记。

接下来：%a1 = load 沿 store 11 解析为常量 11；
%0 = mul i32 %a1, 2：两个操作数 11 与常量 2 都是
constant，折出 22（注意 sccp.out 里这条 mul 仍被保留
为指令！）。为什么没折？因为 SCCP 对 mul 的折叠在结果
还要被使用、且——更关键的——下一条指令是
%1 = call i32 @tip_input()：外部调用结果 overdefined，
%2 = add i32 %0, %1 随之为 overdefined。SCCP 完全可以
把 mul 22 折掉，但它选择保留指令：折叠一个其消费者
马上 overdefined 的值不产生优化收益，且保留指令不阻碍
后续（事实上现代 LLVM 的实现选择是只折叠"能消除指令或
喂给其他折叠"的常量边）。**"能推出"与"选择改写"在
优化器里是两件事**：格状态记录全部可知信息，IR 改写只
应用有收益的部分。对照时区分这两层，才不会把"mul 还在"
误读为"SCCP 不知道 22"。

后半程：store %2 到 b 只记账（值 overdefined）；
%a2 = load 解析为 11；call @tip_output(i32 %a2)：实参
常量 11，无折叠可做但参数格值确定；%b3 = load 为
overdefined；第二个 output 以此调用；ret i32 0 是常量
返回。最终 IR 与输入 IR 的差异只有：a 的值被确定为 11
（贯穿 store/load），其余形状不变。对照本章 --check 快照：
a=11 与 SCCP 的 11 是同一个格论结论在稠密环境与稀疏 SSA
两个世界的各自投影；b=TOP 对应 overdefined 的 %2。两边
的精度在 fold 上逐值相同。

**一张小对账表。** 把本节事实压成五行：

- 常量 11：MFP 点 2 折出；SCCP 经 store 11 接收（前端
  已折）；结论相同、折叠者不同。
- 常量 22：MFP 在点 3 的子表达式折出后被 ⊤ 吸收；SCCP
  在 SSA 格中知其为 22 但保留 mul 指令；"知道"相同、
  改写策略不同。
- input：两边同为 ⊤/overdefined。
- b：两边同为 ⊤/overdefined，输出点不盘查。
- 可执行 CFG：fold 无不可行边，SCCP 的条件剪枝无机会
  展示——这是本章实现与 SCCP 的能力差距在本程序上不可见
  的原因；要见差距需用 17.7.2 那种常量条件程序。

理解了"格值信息"与"IR 改写"之间的缝隙，就拿到了阅读
一切 sparse constant propagation 输出的通用钥匙：先问
每个 SSA 值在终点是什么格值，再问每条保留的指令为何没
有被改写（无消费者、有副作用、或改写无收益）——两个问题
分开作答，输出里每一处保留与消失都有交代。

## 29.8 本章复用前几章的机器

本章真正新写的只有 constant.{hpp,cpp} 与 soundness.{hpp,cpp}
两对文件，加上 main.cpp 里新增的两个模式；其余十三份源码
全部原样复用。按依赖顺序依次点名，每份交代"它是什么、
本章从它那里取什么"。先从地基开始。

关于"复用"本身的策略先说三句。其一，复用的单位是**字节
级原样**：check_docs 脚本会校验文档嵌入的每个文件与
examples 目录逐字节一致，因此任何"顺手改一下注释"的
冲动都不被允许——要改就升版本、全链路重跑，教程的
快照纪律与真实工程一致。其二，复用的文件仍然全部嵌入
文档，哪怕本章一个字都没有新说：这一方面是脚本强制的
完整性（查漏即失败），另一方面是叙事的诚实——读者
看到的每一章都是当章完整的、可独立构建的快照，不必
跨章拼接。其三，嵌入顺序服从讲解逻辑而非目录序：
新写的两对文件在 17.3/17.5 详细讲过，本节按依赖序
（地基 → 对照组 → 引擎 → 执行台）补齐其余，每份的
讲解侧重"本章视角"，逐章重复的内容不再展开。

### 29.8.1 AST 与它的构建器（第 3 章）

ast.hpp 冻结的 AST 是五个章节的共同语言。本章从它那里取
三类东西：表达式类层次（IntLit/VarRef/InputE/Binop/CallE）
是 evalConstExpr 与 interpret 两台求值器的遍历对象；
AssignS 的 target 字段被 constTransferNode 与解释器各自
dynamic_cast 成 VarRef 来判定"直接赋值还是间接赋值"；
OutputS 语句类型是 ConcreteRun::sites 的元素类型——17.5
节整个对账枢纽就压在这个类上。

再往深处看一层，ast.hpp 的所有权设计是 17.5.3 论证的
隐形支柱。整棵树用 unique_ptr 从 ProgramA 一路独占到
每个表达式节点，意味着对象地址在 ProgramA 存活期内
**永不变更也永不复用**：Stmt* 既可以当 nodeOf 的键，
也可以当 interpret 户口登记的值，两处比较的就是纯地址。
假如当年选了 shared_ptr 或把节点存在 vector 里按下标
引用，"指针同一性"就得换成"编号同一性"，nodeOf 与
sites 的契约要重新推导。本章没有为此写一行新代码，
却完全依赖那个第三章定下的设计——好的基础设施的
标志就是下游免费获得正确性。另一个被本章消费而不被
察觉的细节是 BOp 枚举：evalConstExpr 与 interpret 的
两个 switch 用同一份枚举做分派，两侧算术语义的对齐
（同一个 BOp::Add 在抽象与具体两侧各是什么）由编译器
的穷尽检查兜底——新增一种运算时，两台求值器会同时
（并且只在同时）补上情形，漏一侧即是编译错误。

```cpp
// file: src/ast.hpp
// AST 定义：AST 是去掉了括号、分号等语法噪音的程序结构。
// 接口自本章起冻结，后续所有分析（名字、CFG、类型、格……）都在此之上工作。
#pragma once

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace tip {

enum class BOp { Add, Sub, Mul, Div, Gt, Eq };

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr {
    int v;
    explicit IntLit(int value) : v(value) {}
};
struct VarRef : Expr {
    std::string name;
    explicit VarRef(std::string n) : name(std::move(n)) {}
};
struct InputE : Expr {};
struct Binop : Expr {
    BOp op;
    std::unique_ptr<Expr> l, r;
    Binop(BOp o, std::unique_ptr<Expr> lhs, std::unique_ptr<Expr> rhs)
        : op(o), l(std::move(lhs)), r(std::move(rhs)) {}
};
struct CallE : Expr {
    std::unique_ptr<Expr> callee;
    std::vector<std::unique_ptr<Expr>> args;
    CallE(std::unique_ptr<Expr> fn, std::vector<std::unique_ptr<Expr>> as)
        : callee(std::move(fn)), args(std::move(as)) {}
};
struct Deref : Expr {
    std::unique_ptr<Expr> e;
    explicit Deref(std::unique_ptr<Expr> p) : e(std::move(p)) {}
};
struct AddrOf : Expr {                       // spa: & Id
    std::string name;
    explicit AddrOf(std::string n) : name(std::move(n)) {}
};
struct AllocE : Expr {
    std::unique_ptr<Expr> e;
    explicit AllocE(std::unique_ptr<Expr> init) : e(std::move(init)) {}
};
struct NullE : Expr {};
struct RecLit : Expr {
    std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
    explicit RecLit(std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fs)
        : fields(std::move(fs)) {}
};
struct FieldA : Expr {
    std::unique_ptr<Expr> e;
    std::string field;
    FieldA(std::unique_ptr<Expr> record, std::string f)
        : e(std::move(record)), field(std::move(f)) {}
};

struct Stmt {
    virtual ~Stmt() = default;
};
// target 只会是 VarRef / FieldA / Deref，文法 lvalue 已限定。
struct AssignS : Stmt {
    std::unique_ptr<Expr> target, value;
    AssignS(std::unique_ptr<Expr> t, std::unique_ptr<Expr> v)
        : target(std::move(t)), value(std::move(v)) {}
};
struct OutputS : Stmt {
    std::unique_ptr<Expr> e;
    explicit OutputS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};
struct IfS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> then, els;
    IfS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> t, std::unique_ptr<Stmt> e)
        : cond(std::move(c)), then(std::move(t)), els(std::move(e)) {}
};
struct WhileS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> body;
    WhileS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> b)
        : cond(std::move(c)), body(std::move(b)) {}
};
struct BlockS : Stmt {
    std::vector<std::unique_ptr<Stmt>> ss;
    explicit BlockS(std::vector<std::unique_ptr<Stmt>> v) : ss(std::move(v)) {}
};
struct ReturnS : Stmt {
    std::unique_ptr<Expr> e;
    explicit ReturnS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};

struct FunDecl {
    std::string name;
    std::vector<std::string> params;
    std::vector<std::string> vars;
    std::unique_ptr<Stmt> body;
    std::unique_ptr<ReturnS> ret;
};

struct ProgramA {
    std::vector<std::unique_ptr<FunDecl>> funs;
};

}  // namespace tip
```

ast_build 是 ANTLR parse tree 到这棵 AST 的翻译器——
17.5.3 强调的"一次解析、四方共用"的源头就在这里：
buildAst 产出的 unique_ptr<ProgramA> 由 Parsed 结构持有，
存活到 main 的整个对账循环结束，所有下游指针因此稳定。
本章对它没有一行改动。

值得点名的是 buildLvalue 的产物形状与常量分析的分工
边界。它把赋值目标统一翻译成表达式：直接目标是
VarRef，经指针或字段的目标是 Deref（可能再包 FieldA）。
constTransferNode 对目标做一次 dynamic_cast<const
VarRef*>——命中则更新环境，不命中则原样透传。这个
"翻译器把语义难点编码成类型形态、传递函数用类型判定
分工"的模式，让常量分析不需要任何对 lvalue 文法的
了解：它只认 VarRef，其余一律保守。解释器
（soundness.cpp 的 execStmt）用的是同一个 cast、同一个
判定，两侧的保守边界天然一致——假如某天指针写入的
语义被补上，两个消费者会在同一个类型判断处同时需要
修改，漏改任何一侧都会被 --verify-soundness 的契约一
抓出来。另一个小细节：NegExpr 被翻译成 0 - E 而不是
专门的一元节点，于是 evalConstExpr 里根本没有"负号"
分支——`0 - x` 与 `x` 取负在抽象语义上共用同一条
Binop 路径，文法层的糖在 AST 层就被消化干净了。

```cpp
// file: src/ast_build.hpp
// AST 构建器：在 ANTLR 生成的 parse-tree 上下文节点上手工递归下降。
// （本工具链 C++ runtime 的 visitor 以 std::any 传值，而 std::any 不能持有
// unique_ptr，因此不使用 visitor 机制：parse-tree 的上下文类本身信息完整，
// 用 dynamic_cast 区分 #标签备选，自己做一次结构化遍历同样直接。）
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "TIPParser.h"
#include "antlr4-runtime.h"
#include "ast.hpp"

namespace tip {

struct AstBuilder {
    std::unique_ptr<ProgramA> build(TIPParser::ProgramContext *tree);

private:
    std::unique_ptr<FunDecl> buildFun(TIPParser::FunctionContext *ctx);
    std::unique_ptr<Expr> buildExpr(TIPParser::ExprContext *ctx);
    std::unique_ptr<Stmt> buildStmt(TIPParser::StmtContext *ctx);
    // lvalue 翻译成赋值目标表达式：VarRef / Deref，可再包一层 FieldA。
    std::unique_ptr<Expr> buildLvalue(TIPParser::LvalueContext *lv);
};

// 便捷入口：parse tree 的 program 节点 -> 完整 AST。
std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree);

}  // namespace tip
```

```cpp
// file: src/ast_build.cpp
#include "ast_build.hpp"

#include <utility>
#include <vector>

namespace tip {

std::unique_ptr<ProgramA> AstBuilder::build(TIPParser::ProgramContext *tree) {
    auto program = std::make_unique<ProgramA>();
    for (auto *fc : tree->function()) program->funs.push_back(buildFun(fc));
    return program;
}

std::unique_ptr<FunDecl> AstBuilder::buildFun(TIPParser::FunctionContext *ctx) {
    auto f = std::make_unique<FunDecl>();
    f->name = ctx->IDENT()->getText();
    if (ctx->params()) {
        for (auto *p : ctx->params()->IDENT()) f->params.push_back(p->getText());
    }
    if (ctx->varDecls()) {
        for (auto *v : ctx->varDecls()->IDENT()) f->vars.push_back(v->getText());
    }

    std::vector<std::unique_ptr<Stmt>> body;
    for (auto *sc : ctx->stmt()) body.push_back(buildStmt(sc));
    f->body = std::make_unique<BlockS>(std::move(body));

    f->ret = std::make_unique<ReturnS>(buildExpr(ctx->expr()));
    return f;
}

std::unique_ptr<Expr> AstBuilder::buildLvalue(TIPParser::LvalueContext *lv) {
    std::unique_ptr<Expr> base;
    std::string field;
    if (auto *d = dynamic_cast<TIPParser::DirectLvalueContext *>(lv)) {
        base = std::make_unique<VarRef>(d->IDENT(0)->getText());
        if (d->IDENT().size() == 2) field = d->IDENT(1)->getText();
    } else {
        auto *p = dynamic_cast<TIPParser::PointerLvalueContext *>(lv);
        base = std::make_unique<Deref>(buildExpr(p->expr()));
        if (p->IDENT()) field = p->IDENT()->getText();
    }
    if (!field.empty())
        return std::make_unique<FieldA>(std::move(base), std::move(field));
    return base;
}

std::unique_ptr<Expr> AstBuilder::buildExpr(TIPParser::ExprContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::IntExprContext *>(ctx))
        return std::make_unique<IntLit>(std::stoi(c->INT()->getText()));
    if (auto *c = dynamic_cast<TIPParser::VarExprContext *>(ctx))
        return std::make_unique<VarRef>(c->IDENT()->getText());
    if (dynamic_cast<TIPParser::InputExprContext *>(ctx))
        return std::make_unique<InputE>();
    if (dynamic_cast<TIPParser::NullExprContext *>(ctx))
        return std::make_unique<NullE>();
    if (auto *c = dynamic_cast<TIPParser::ParenExprContext *>(ctx))
        return buildExpr(c->expr());

    if (auto *c = dynamic_cast<TIPParser::AddExprContext *>(ctx)) {
        const BOp op = c->PLUS() ? BOp::Add : BOp::Sub;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::MulExprContext *>(ctx)) {
        const BOp op = c->STAR() ? BOp::Mul : BOp::Div;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::CmpExprContext *>(ctx)) {
        const BOp op = c->GT() ? BOp::Gt : BOp::Eq;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::NegExprContext *>(ctx)) {
        // TIP 没有负数字面量 token，-E 即 0-E。
        return std::make_unique<Binop>(BOp::Sub, std::make_unique<IntLit>(0),
                                       buildExpr(c->expr()));
    }
    if (auto *c = dynamic_cast<TIPParser::CallExprContext *>(ctx)) {
        std::vector<std::unique_ptr<Expr>> args;
        if (c->args())
            for (auto *a : c->args()->expr()) args.push_back(buildExpr(a));
        return std::make_unique<CallE>(buildExpr(c->expr()), std::move(args));
    }
    if (auto *c = dynamic_cast<TIPParser::FieldExprContext *>(ctx))
        return std::make_unique<FieldA>(buildExpr(c->expr()), c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::DerefExprContext *>(ctx))
        return std::make_unique<Deref>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::AddrExprContext *>(ctx))
        return std::make_unique<AddrOf>(c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::AllocExprContext *>(ctx))
        return std::make_unique<AllocE>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::RecExprContext *>(ctx)) {
        std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
        for (auto *fc : c->field())
            fields.emplace_back(fc->IDENT()->getText(), buildExpr(fc->expr()));
        return std::make_unique<RecLit>(std::move(fields));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<Stmt> AstBuilder::buildStmt(TIPParser::StmtContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::AssignStmtContext *>(ctx))
        return std::make_unique<AssignS>(buildLvalue(c->lvalue()), buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::OutputStmtContext *>(ctx))
        return std::make_unique<OutputS>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::IfStmtContext *>(ctx)) {
        std::unique_ptr<Stmt> els;
        if (c->stmt().size() == 2) els = buildStmt(c->stmt(1));
        return std::make_unique<IfS>(buildExpr(c->expr()), buildStmt(c->stmt(0)),
                                     std::move(els));
    }
    if (auto *c = dynamic_cast<TIPParser::WhileStmtContext *>(ctx))
        return std::make_unique<WhileS>(buildExpr(c->expr()), buildStmt(c->stmt()));
    if (auto *c = dynamic_cast<TIPParser::BlockStmtContext *>(ctx)) {
        std::vector<std::unique_ptr<Stmt>> ss;
        for (auto *sc : c->stmt()) ss.push_back(buildStmt(sc));
        return std::make_unique<BlockS>(std::move(ss));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree) {
    return AstBuilder{}.build(tree);
}

}  // namespace tip
```

### 29.8.2 CFG（第 14 章）

buildCfg 把 AST 展开成"程序点 + 边"的图，是两个分析
（符号、常量）与对账映射 nodeOf 三者的共同底座。它的
两遍构造（先按源码顺序编号、再连边）保证程序点编号确定
——expected/output.txt 里 `1 entry`、`2 assign` 的每一行
都依赖这份确定性。CfgNode 里存的 `const Stmt *stmt` 正是
nodeOf 的键来源：图上的点与 AST 里的语句由这个指针焊接。

从常量分析的视角再看一遍 CFG 的三个结构决定。第一，
**分支是点不是边**：if/while 在图上是一个 Branch 节点，
条件真假对应两条出边——本章的分析不读条件表达式
（不剪枝），所有出边一律可行，因此 Branch 节点在
constTransferNode 里落入"非赋值透传"分支，与 output、
return 同等待遇。这个"图比分析更富余"的余量正是
17.7 SCCP 条件反馈的用武之地：当分析器开始消费分支
条件时，Branch 节点上已经折叠出常量的条件表达式就能
反过来删边——结构早已备好，本章只是没有启用。第二，
**回边是普通的边**：循环在 wireStmt 里表现为"体尾回到
条件点"的一条边，没有任何特殊标记；worklist 引擎因此
不需要"循环检测"，迭代自然地多跑几轮直到不动点——
第 28 章 13 步追踪里的两轮结构不是引擎识别了循环，
而是循环在数据上自我显现。第三，**节点持语句指针而非
拷贝**：nodeOf、打印、对账全都免费获得"点 ↔ 语句"的
双向通道，这是 CfgNode 里那一个 `const Stmt *` 字段
的全部分量所在。

```cpp
// file: src/cfg.hpp
// 控制流图（CFG, spa 第 2 章）：把函数体从树形语法展开为"程序点 + 边"的图。
// 数据流分析的载体是图而不是树：循环在图上是环，条件在图上是分叉。
#pragma once

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"

namespace tip {

struct CfgNode {
    int id = 0;
    enum class Kind { Entry, Exit, Assign, Output, Branch, Return } kind;
    const Stmt *stmt = nullptr;  // Assign/Output/Branch 指向对应语句
};

struct FunCfg {
    std::string name;
    int entry = -1;
    int exitNode = -1;
    std::map<int, CfgNode> nodes;
    std::vector<std::pair<int, int>> edges;
};

struct Cfg {
    std::vector<FunCfg> funs;
};

Cfg buildCfg(const ProgramA &program);
std::string printCfg(const Cfg &cfg);

}  // namespace tip
```

```cpp
// file: src/cfg.cpp
#include "cfg.hpp"

#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"

namespace tip {
namespace {

// 两遍构造：第一遍按 AST 先序给所有程序点分配固定编号；第二遍连边。
// 先编号再连边，是为了让编号严格按源码顺序（连边时若先构造后继节点，
// 后继会抢在前面编号），从而输出与程序点编号都是确定的。
class CfgBuilder {
public:
    explicit CfgBuilder(const ProgramA &program) : program_(program) {}

    Cfg run() {
        Cfg cfg;
        for (const auto &fun : program_.funs) {
            FunCfg fc;
            cur_ = &fc;
            cur_->name = fun->name;
            nextId_ = 1;
            stmtId_.clear();

            const int entry = addNode(CfgNode::Kind::Entry);
            cur_->entry = entry;
            numberStmt(fun->body.get());
            const int retId = addNode(CfgNode::Kind::Return, fun->ret.get());
            const int exitId = addNode(CfgNode::Kind::Exit);
            cur_->exitNode = exitId;

            // 连边：语句构造返回它自己的入口点集合；空块没有节点，直接透传后继。
            std::vector<int> bodyEntries = wireStmt(fun->body.get(), {retId});
            if (bodyEntries.empty()) bodyEntries = {retId};
            link(entry, bodyEntries);
            link(retId, {exitId});

            // set 去重并排序：CFG 边不允许重复，输出顺序固定。
            std::set<std::pair<int, int>> uniq(cur_->edges.begin(), cur_->edges.end());
            cur_->edges.assign(uniq.begin(), uniq.end());
            cfg.funs.push_back(std::move(*cur_));
        }
        return cfg;
    }

private:
    const ProgramA &program_;
    FunCfg *cur_ = nullptr;
    int nextId_ = 1;
    std::map<const Stmt *, int> stmtId_;

    int addNode(CfgNode::Kind kind, const Stmt *stmt = nullptr) {
        const int id = nextId_++;
        cur_->nodes.emplace(id, CfgNode{id, kind, stmt});
        return id;
    }

    // ---- 第一遍：编号 ----
    void numberStmt(const Stmt *s) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            for (const auto &x : b->ss) numberStmt(x.get());
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->then.get());
            numberStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->body.get());
            return;
        }
        if (dynamic_cast<const AssignS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Assign, s);
            return;
        }
        if (dynamic_cast<const OutputS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Output, s);
        }
    }

    // ---- 第二遍：连边。返回进入该语句时首先到达的程序点集合 ----
    std::vector<int> wireStmt(const Stmt *s, const std::vector<int> &succ) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            std::vector<int> cur = succ;
            for (auto it = b->ss.rbegin(); it != b->ss.rend(); ++it)
                cur = wireStmt(it->get(), cur);
            return cur;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            const int n = stmtId_[x];
            std::vector<int> targets = wireStmt(x->then.get(), succ);
            if (targets.empty()) targets = succ;
            if (x->els) {
                std::vector<int> e = wireStmt(x->els.get(), succ);
                if (e.empty()) e = succ;
                targets.insert(targets.end(), e.begin(), e.end());
            } else {
                targets.insert(targets.end(), succ.begin(), succ.end());
            }
            link(n, targets);
            return {n};
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            const int n = stmtId_[x];
            // 循环体执行完回到条件点；空体时条件点连一条自边（等于死循环）。
            std::vector<int> bodyEntries = wireStmt(x->body.get(), {n});
            if (bodyEntries.empty()) bodyEntries = {n};
            link(n, bodyEntries);
            link(n, succ);
            return {n};
        }
        const int n = stmtId_[s];
        link(n, succ);
        return {n};
    }

    void link(int from, const std::vector<int> &to) {
        for (int t : to) cur_->edges.emplace_back(from, t);
    }
};

const char *kindName(CfgNode::Kind kind) {
    switch (kind) {
        case CfgNode::Kind::Entry: return "entry";
        case CfgNode::Kind::Exit: return "exit";
        case CfgNode::Kind::Assign: return "assign";
        case CfgNode::Kind::Output: return "output";
        case CfgNode::Kind::Branch: return "branch";
        case CfgNode::Kind::Return: return "return";
    }
    return "?";
}

}  // namespace

Cfg buildCfg(const ProgramA &program) { return CfgBuilder(program).run(); }

std::string printCfg(const Cfg &cfg) {
    std::ostringstream out;
    for (const FunCfg &f : cfg.funs) {
        out << "== " << f.name << " ==\n";
        out << "nodes:\n";
        for (const auto &[id, node] : f.nodes) {
            out << "  " << id << ": " << kindName(node.kind);
            if (node.stmt) out << "  " << printStmtLine(*node.stmt);
            out << "\n";
        }
        out << "edges:\n";
        for (const auto &[a, b] : f.edges) out << "  " << a << " -> " << b << "\n";
    }
    return out.str();
}

}  // namespace tip
```

### 29.8.3 前缀式打印器（第 3 章）

pretty 把表达式打印成前缀式（`(+ 3 (* 4 2))`）、把语句压成
单行。本章有两处消费：printConstEnv 里的节点标签直接调用
printStmtLine/printExpr（expected 的 `a = (+ 3 (* 4 2)) ;`
就是它的产出），使常量表与第 20、23 章的符号表在视觉上
同构；除此之外它不再参与任何分析逻辑——打印器与语义的
分离让它可以放心地被所有章节共用。

前缀式打印在本章还额外扮演了一个不显眼的对账角色：
expected/output.txt 里的表达式文本是**抽象语法树的一维
投影**，括号位置即树的形状。`(+ 3 (* 4 2))` 与
`(+ (* 3 4) 2)` 在源代码里可能写起来一样（都是 3 + 4 * 2
的变体），打印出来却分毫不差地暴露求值次序——17.6.2
据此确认"乘法先结合"的文法优先级被正确传到了分析层。
若打印器丢失了结合性信息（比如打印成中缀不加括号），
这一类验证就静默失效。pretty 的一系列单行输出还服务
于另一个消费者：soundness.cpp 不用它，但 17.5.4 讲解
"对账对象是同一个表达式"时，读者能亲手用 printExpr
把 site->e 打出来对照——同一台打印器同时服务人读
与机器对账，是"工具的复用先于工具的花哨"的又一例。

```cpp
// file: src/pretty.hpp
// Pretty-printer：把 AST 以固定的前缀式语法重新打印出来。
// 它是 AST 的第一个消费者，也为后续各章提供"程序结构可视化"的通用工具。
#pragma once

#include <string>

#include "ast.hpp"

namespace tip {

std::string printExpr(const Expr *e);
std::string printProgram(const ProgramA &program);

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printStmtLine(const Stmt &stmt);

}  // namespace tip
```

```cpp
// file: src/pretty.cpp
#include "pretty.hpp"

#include <string>

namespace tip {

namespace {

// 表达式打印为前缀式：运算符与符号的对照表。
std::string exprText(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return std::to_string(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) return x->name;
    if (dynamic_cast<const InputE *>(e)) return "input";
    if (dynamic_cast<const NullE *>(e)) return "null";

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const char *sym = "+";
        switch (x->op) {
            case BOp::Add: sym = "+"; break;
            case BOp::Sub: sym = "-"; break;
            case BOp::Mul: sym = "*"; break;
            case BOp::Div: sym = "/"; break;
            case BOp::Gt: sym = ">"; break;
            case BOp::Eq: sym = "=="; break;
        }
        return "(" + std::string(sym) + " " + exprText(x->l.get()) + " " +
               exprText(x->r.get()) + ")";
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        std::string s = "(call " + exprText(x->callee.get());
        for (const auto &a : x->args) s += " " + exprText(a.get());
        return s + ")";
    }
    if (const auto *x = dynamic_cast<const Deref *>(e))
        return "(* " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const AddrOf *>(e)) return "(& " + x->name + ")";
    if (const auto *x = dynamic_cast<const AllocE *>(e))
        return "(alloc " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const FieldA *>(e))
        return "(. " + exprText(x->e.get()) + " " + x->field + ")";
    if (const auto *x = dynamic_cast<const RecLit *>(e)) {
        std::string s = "{";
        for (size_t i = 0; i < x->fields.size(); ++i) {
            if (i) s += ", ";
            s += x->fields[i].first + ": " + exprText(x->fields[i].second.get());
        }
        return s + "}";
    }
    return "<unknown expr>";
}

std::string indent(int level) { return std::string(static_cast<size_t>(level) * 2, ' '); }

// 语句打印带缩进，一条语句一行（块内多行）。
void stmtText(const Stmt *s, int level, std::string &out) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        out += indent(level) + exprText(x->target.get()) + " = " +
               exprText(x->value.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        out += indent(level) + "output " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
        out += indent(level) + "return " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        out += indent(level) + "if (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->then.get(), level + 1, out);
        if (x->els) {
            out += indent(level) + "else\n";
            stmtText(x->els.get(), level + 1, out);
        }
        return;
    }
    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        out += indent(level) + "while (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->body.get(), level + 1, out);
        return;
    }
    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        out += indent(level) + "{\n";
        for (const auto &st : x->ss) stmtText(st.get(), level + 1, out);
        out += indent(level) + "}\n";
        return;
    }
    out += indent(level) + "<unknown stmt>\n";
}

}  // namespace

std::string printExpr(const Expr *e) { return exprText(e); }

std::string printProgram(const ProgramA &program) {
    std::string out;
    for (const auto &f : program.funs) {
        std::string paramList;
        for (size_t i = 0; i < f->params.size(); ++i) {
            if (i) paramList += ",";
            paramList += f->params[i];
        }
        out += f->name + "(" + paramList + ") {\n";
        if (!f->vars.empty()) {
            out += indent(1) + "var ";
            for (size_t i = 0; i < f->vars.size(); ++i) {
                if (i) out += ",";
                out += f->vars[i];
            }
            out += " ;\n";
        }
        // 函数体是 BlockS；打印其内部语句而不是再嵌一层花括号。
        const auto *body = dynamic_cast<const BlockS *>(f->body.get());
        for (const auto &st : body->ss) stmtText(st.get(), 1, out);
        stmtText(f->ret.get(), 1, out);
        out += "}\n";
    }
    return out;
}

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printStmtLine(const Stmt &stmt) {
    std::string out;
    stmtText(&stmt, 0, out);
    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
}

}  // namespace tip
```

### 29.8.4 名字解析（第 4 章）

resolveNames 把每个 VarRef 绑定到它的声明，产出的 Bindings
本章被 IRGen 消费：局部变量的 alloca 槽位表以 Symbol 指针
为键，IRGen 经 bindings->uses 查到每个变量引用对应的符号
再落到槽位。静态分析侧（constant/sign）反而不消费它——
它们按变量名直接建环境，因为本章实验程序是单函数直名的，
名字冲突在解析阶段已被拦截。两个消费者对同一份绑定的
不同用法，恰好说明"解析产物"是一层独立的中间事实。

这一节顺带澄清一个读者可能憋了很久的问题：常量环境
为什么用变量**名**做键，而 IRGen 的槽位表用 Symbol
**指针**做键？名字键的代价是作用域信息被抹平——两个
同名局部变量在不同函数里会被视为同一个键。对本章的
分析这不成问题：逐函数求解（每个 FunCfg 独立跑队列），
环境不跨函数流动，同名不同函数的变量永远不会相遇；
跨函数的信息流动要等第 46 章过程间分析，那时键必须
升级为"（函数，变量）"对或 Symbol 指针。指针键的
好处是天然携带作用域身份，irgen 用它直接落槽位；坏处
是键的生命周期与 AST 绑定。两条路线在本教程里共存，
分工标准就一条：**信息的流动范围等于键的作用域时用名，
跨作用域时用指针**。第 46 章升级键时，本章的
solveConstFixpoint 只需换键类型，格与传递函数原样不动——
又一次验证"框架与组件"的分界。

```cpp
// file: src/symtab.hpp
// 符号表与名字解析：把 AST 上的每个 VarRef 绑定到它的声明
// （函数 / 参数 / 局部变量），同时产出未声明、重复声明诊断。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Symbol {
    enum Kind { Fun, Param, Local } kind;
    std::string name;
    const FunDecl *fun;          // Fun: 指向自身声明; Param/Local: 指向所属函数
};

struct Scope {
    Scope *parent;
    std::map<std::string, Symbol> table;

    explicit Scope(Scope *p = nullptr) : parent(p) {}
    const Symbol *lookup(const std::string &name) const;
};

struct Diag {
    std::string text;
};

struct Bindings {
    Scope global;                                  // 函数名所在的全局作用域
    // 各函数作用域由 Bindings 持有所有权：uses 中的 Symbol* 才不会悬垂。
    std::vector<std::unique_ptr<Scope>> scopes;
    std::vector<Diag> errors;
    std::map<const VarRef *, const Symbol *> uses;  // 解析成功的使用点
};

// 两遍解析：先注册全部函数名（支持前向调用），再逐函数解析函数体。
Bindings resolveNames(ProgramA &program);

}  // namespace tip
```

```cpp
// file: src/symtab.cpp
#include "symtab.hpp"

#include <utility>

namespace tip {

namespace {

// 解析器在遍历 AST 的同时完成绑定与诊断收集。
struct Resolver {
    Bindings bindings;
    Scope *current = nullptr;
    const FunDecl *owner = nullptr;

    void declare(const std::string &name, Symbol::Kind kind) {
        if (current->table.count(name)) {
            bindings.errors.push_back({"error: redeclared '" + name + "'"});
            return;  // 保留先声明者，后声明被忽略
        }
        current->table.emplace(name, Symbol{kind, name, owner});
    }

    void resolveExpr(const Expr *e) {
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            const Symbol *s = current->lookup(x->name);
            if (!s) {
                bindings.errors.push_back({"error: undeclared '" + x->name + "'"});
            } else {
                bindings.uses[x] = s;
            }
            return;
        }
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            resolveExpr(x->l.get());
            resolveExpr(x->r.get());
            return;
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            resolveExpr(x->callee.get());
            for (const auto &a : x->args) resolveExpr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const AllocE *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            resolveExpr(x->e.get());  // 字段名不是变量，无需解析
            return;
        }
        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &f : x->fields) resolveExpr(f.second.get());
            return;
        }
        // IntLit / InputE / AddrOf / NullE：无变量使用。
    }

    void resolveStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            resolveExpr(x->target.get());
            resolveExpr(x->value.get());
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->then.get());
            if (x->els) resolveStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) resolveStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) return resolveExpr(x->e.get());
    }
};

}  // namespace

const Symbol *Scope::lookup(const std::string &name) const {
    auto it = table.find(name);
    if (it != table.end()) return &it->second;
    return parent ? parent->lookup(name) : nullptr;
}

Bindings resolveNames(ProgramA &program) {
    Resolver resolver;
    resolver.bindings.global = Scope(nullptr);
    Scope *global = &resolver.bindings.global;

    // 第一遍：所有函数名进入全局作用域。
    for (const auto &f : program.funs) {
        if (global->table.count(f->name)) {
            resolver.bindings.errors.push_back({"error: redeclared '" + f->name + "'"});
            continue;
        }
        global->table.emplace(f->name, Symbol{Symbol::Fun, f->name, f.get()});
    }

    // 第二遍：每个函数开自己的作用域，父作用域是全局表；
    // 作用域所有权交给 Bindings，遍历结束后符号依然存活。
    for (const auto &f : program.funs) {
        auto functionScope = std::make_unique<Scope>(global);
        resolver.current = functionScope.get();
        resolver.owner = f.get();

        for (const std::string &p : f->params) resolver.declare(p, Symbol::Param);
        for (const std::string &v : f->vars) resolver.declare(v, Symbol::Local);

        resolver.resolveStmt(f->body.get());
        resolver.resolveStmt(f->ret.get());

        resolver.current = nullptr;
        resolver.bindings.scopes.push_back(std::move(functionScope));
    }
    return std::move(resolver.bindings);
}

}  // namespace tip
```

### 29.8.5 符号格与符号传递函数（第 25 章）

sign.{hpp,cpp} 是本章的**对照组**。扁平常量格的每一条
设计决策都值得与它对读一遍：符号格五个元素、高度 2、
join 靠四张表；常量格无数元素、高度无穷但链长有界、join
三行。SignLattice::leq 在 17.5 的对账里直接上场——成员
检验那句 `lat.leq(signOfLiteral(...), predicted)` 用的
就是这份第 25 章的序关系。sAdd/sMul 的表驱动风格与
evalConstExpr 的分支风格又是一组对照：域越粗越适合查表
（组合有限），域越细越适合直接计算（常量运算就是具体
运算本身）。

本章消费 sign.hpp 还有一个不易察觉的层次：**它示范了
"域可以被替换"之后代码里哪些东西不需要跟着换**。
SignLattice 的 top/bot 字段、leq/join 签名，与 Const 的
cBot/cTop/cJoin 在结构上同构，但后者没有强求同一个
接口——17.3.1 说过这是刻意的。对读两份域定义时建议
带一个问题：如果明天要写第三个域（区间格、奇偶格），
哪些决定沿用、哪些重估？沿用的是"域 + 序 + join + 传递
函数"的四件套骨架与"缺键即 ⊥"的约定；重估的是接口
形态（查表还是分支、成员函数还是自由函数）与终止性
论证的范式。问题清单本身是这一章的方法论遗产，比任何
一个具体域都耐用。sign.cpp 的四张算术表（ADD/MUL 及
sSub 的取负、sDiv 的分解）在本章不参与求解——它们
只在 17.5 的成员检验里通过 evalExprSign 间接上场，但
作为"对照组的完整语义"仍被逐字节嵌入与讲解，这是
快照完整性原则的小小体现。

```cpp
// file: src/sign.hpp
// 符号格（Sign lattice, spa 第 4 章）：把整数的具体值按"正负号"分五类。
//   ⊥（不可达/无信息） < −、0、+（三者互不可比） < ⊤（三者皆可能）
// 本章只给"域 + 序 + join"和抽象算术；多趟不动点在第 28 章补上。
#pragma once

#include <string>

#include "lattice.hpp"

namespace tip {

// 同一符号域的 Lattice<int> 形态：供通用构造（lift/product/maps/…）组装使用。
Lattice<int> signLatticeDomain();

// 编码：⊥=-2, −=-1, 0=0, +=1, ⊤=2。
// 用整数编码只是存储便利；序关系不是整数大小，join 必须查 join 表。
constexpr int SBOT = -2;
constexpr int SMINUS = -1;
constexpr int SZERO = 0;
constexpr int SPLUS = 1;
constexpr int STOP = 2;

std::string signShow(int s);

// 符号格的三要素：判定相等、偏序、最小上界。
// 后面所有单调框架的算法只依赖这三个操作（及 top/bot 边界）。
struct SignLattice {
    int top = STOP;
    int bot = SBOT;

    bool eq(int a, int b) const { return a == b; }
    bool leq(int a, int b) const;
    int join(int a, int b) const;
};

// 抽象算术：每个操作都对应整数运算"按符号分类"后的最小上界。
// 例如 +:(+,−)→⊤，因为正整数加负整数可能是 −、0 或 +。
int sAdd(int a, int b);
int sSub(int a, int b);
int sMul(int a, int b);
int sDiv(int a, int b);  // 除数符号含 0 时按 ⊥ 处理（具体程序在此抛错/中止）

// 比较运算在 TIP 中产生 0/1：抽象结果恒为 {0,+}=⊤（⊥ 仍吸收）。
int sCompare(int a, int b);

}  // namespace tip
```

```cpp
// file: src/sign.cpp
#include "sign.hpp"

#include <array>

namespace tip {

Lattice<int> signLatticeDomain() {
    SignLattice s;
    return Lattice<int>{
        STOP, SBOT,
        [](int a, int b) { return a == b; },
        [=](int a, int b) { return s.leq(a, b); },
        [=](int a, int b) { return s.join(a, b); }};
}

std::string signShow(int s) {
    switch (s) {
        case SBOT: return "⊥";
        case SMINUS: return "−";
        case SZERO: return "0";
        case SPLUS: return "+";
        case STOP: return "⊤";
    }
    return "?";
}

bool SignLattice::leq(int a, int b) const {
    if (a == SBOT || b == STOP) return true;   // 底最小、顶最大
    if (b == SBOT || a == STOP) return a == b; // 越过底/顶的唯一可能是相等
    return a == b;                             // −、0、+ 三者互不可比
}

int SignLattice::join(int a, int b) const {
    if (a == b) return a;
    if (a == SBOT) return b;                   // ⊥ ⊔ x = x
    if (b == SBOT) return a;
    return STOP;                               // 其余组合（含 −/0/+ 两两）= ⊤
}

namespace {

// 加法符号表（行=左操作数 [−,0,+,⊤]，列=右操作数）。
constexpr std::array<std::array<int, 4>, 4> ADD_TABLE = {{
    //  −      0      +      ⊤
    {{SMINUS, SMINUS, STOP,  STOP }},  // −
    {{SMINUS, SZERO,  SPLUS, STOP }},  // 0
    {{STOP,   SPLUS,  SPLUS, STOP }},  // +
    {{STOP,   STOP,   STOP,  STOP }},  // ⊤
}};

// 乘法符号表：同号得 +，异号得 −，任何一边是 0 得 0。
constexpr std::array<std::array<int, 4>, 4> MUL_TABLE = {{
    //  −      0      +      ⊤
    {{SPLUS,  SZERO,  SMINUS, STOP }},  // −
    {{SZERO,  SZERO,  SZERO,  SZERO}},  // 0
    {{SMINUS, SZERO,  SPLUS,  STOP }},  // +
    {{STOP,   SZERO,  STOP,   STOP }},  // ⊤
}};

int idx(int s) { return s + 1; }  // −(-1)→0, 0→1, +(1)→2, ⊤(2)→3

}  // namespace

int sAdd(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return ADD_TABLE[idx(a)][idx(b)];
}

int sSub(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    // a − b = a + (−b)：−、+ 互换，0/⊤ 不变。
    const int negB = b == SMINUS ? SPLUS : b == SPLUS ? SMINUS : b;
    return ADD_TABLE[idx(a)][idx(negB)];
}

int sMul(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return MUL_TABLE[idx(a)][idx(b)];
}

int sDiv(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    if (b == SZERO) return SBOT;  // 除以确定的 0：该路径具体不可行（抛错中止）
    // 排除"除数可能为 0"的情形后，商的符号规律与乘法相同。
    if (b == STOP) {
        // 除数 ∈ {−,0,+}：0 排除，剩下 {−,+}；结果符号对 −/+ 分别讨论后取 join。
        return sAdd(sMul(a, SMINUS), sMul(a, SPLUS));
    }
    return MUL_TABLE[idx(a)][idx(b)];
}

int sCompare(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return STOP;  // 比较结果只可能是 0 或 1：{0,+} 在本格中即 ⊤
}

}  // namespace tip
```

sign_transfer.{hpp,cpp} 承担本章三个角色：其一是定义
SignEnv/PointEnv 的形态别名，constant.hpp 的 ConstEnv/
ConstPointEnv 按同一形状镜像（constant.hpp 甚至直接
include 它复用打印器依赖的形态约定）；其二是提供
evalExprSign 与 signOfLiteral——前者是 17.5 成员检验的
静态一侧，后者把 JIT 的具体值抽象回符号；其三是
printPointEnv，--check 输出的 SIGN 栏由它打印。它与
constant.cpp 的对应函数逐行同构，29.4 节的"换格即换
分析"论断在两份代码的 diff 里肉眼可见。

它在本章的第三个身份是**抽象函数 α 的实现库**。17.5.5
论证过：成员检验检查的是 α(v) ⊑ 静态值，其中 α 就是
signOfLiteral——把任意 int 压回 {−, 0, +} 三桶的函数。
注意它对 v == 0 给 SZERO 而不是 ⊥：0 是一个完全确定的
具体值，抽象化必须如实反映"确定是零"；⊥ 在具体侧没有
对应物（它是纯静态概念）。这个细节经常被误解——
"零信息"（⊥）与"值为零"（0）在符号格上是两个不同的
元素，混淆它们会把成员检验变成恒真。evalExprSign 对
output 表达式的求值同样原样沿用：InputE 给 STOP、
调用给 STOP 的保守决策与常量侧的 cTop() 一一对应，
保证两个静态通道对同一表达式给出**互相兼容**的预测
强度（符号预测从不比常量预测更细——符号格更粗但
覆盖面不同，两者的保守方向一致）。

```cpp
// file: src/sign_transfer.hpp
// 符号传递函数与单趟执行：抽象环境沿 CFG 逐点传播。
// 本章按程序点编号顺序只走一遍——回边在被走到时目标尚未计算，按 ⊥ 处理，
// 因此循环携带的信息会丢失。第 28 章用 worklist 反复走到不动点解决。
#pragma once

#include <map>
#include <string>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

using SignEnv = std::map<std::string, int>;  // 变量名 → 符号；缺键视为 ⊥
using PointEnv = std::map<int, SignEnv>;     // 程序点 → 该点执行后的抽象环境

int signOfLiteral(int v);
int evalExprSign(const Expr *e, const SignEnv &env);

SignEnv entryEnv(const FunDecl &f);                 // 参数 = ⊤，局部变量缺省 ⊥
SignEnv joinEnv(const SignEnv &a, const SignEnv &b);
SignEnv transferNode(const CfgNode &node, const SignEnv &in);

// 单趟：按节点编号顺序，每点 = transfer(join(前驱已有状态))。
PointEnv singlePass(const Cfg &cfg, const ProgramA &program);

std::string printPointEnv(const Cfg &cfg, const ProgramA &program,
                          const PointEnv &states);

}  // namespace tip
```

```cpp
// file: src/sign_transfer.cpp
#include "sign_transfer.hpp"

#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"
#include "sign.hpp"

namespace tip {

int signOfLiteral(int v) {
    if (v < 0) return SMINUS;
    if (v == 0) return SZERO;
    return SPLUS;
}

int evalExprSign(const Expr *e, const SignEnv &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return signOfLiteral(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        return it == env.end() ? SBOT : it->second;
    }
    if (dynamic_cast<const InputE *>(e)) return STOP;  // 输入流的下一个整数符号未知
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const int l = evalExprSign(x->l.get(), env);
        const int r = evalExprSign(x->r.get(), env);
        switch (x->op) {
            case BOp::Add: return sAdd(l, r);
            case BOp::Sub: return sSub(l, r);
            case BOp::Mul: return sMul(l, r);
            case BOp::Div: return sDiv(l, r);
            case BOp::Gt:
            case BOp::Eq: return sCompare(l, r);
        }
    }
    // 函数调用的返回值、指针/记录相关表达式：本章按"任意整数"保守处理，
    // 精确分析在过程间（第 46 章起）与指针篇（第 51 章）给出。
    (void)e;
    return STOP;
}

SignEnv entryEnv(const FunDecl &f) {
    SignEnv env;
    for (const std::string &p : f.params) env[p] = STOP;  // 调用方实参符号未知
    return env;
}

SignEnv joinEnv(const SignEnv &a, const SignEnv &b) {
    SignEnv r = a;
    SignLattice lat;
    for (const auto &[k, v] : b) {
        auto it = r.find(k);
        r[k] = it == r.end() ? v : lat.join(it->second, v);
    }
    return r;
}

SignEnv transferNode(const CfgNode &node, const SignEnv &in) {
    if (node.kind != CfgNode::Kind::Assign || !node.stmt) return in;
    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
    const auto *target = dynamic_cast<const VarRef *>(a->target.get());
    if (!target) return in;  // *p / r.f 目标：第 51 章指针分析之前保持环境不变
    SignEnv out = in;
    out[target->name] = evalExprSign(a->value.get(), in);
    return out;
}

namespace {

std::map<int, std::vector<int>> predecessorMap(const FunCfg &f) {
    std::map<int, std::vector<int>> preds;
    for (const auto &[from, to] : f.edges) preds[to].push_back(from);
    return preds;
}

const char *nodeLabel(CfgNode::Kind kind) {
    switch (kind) {
        case CfgNode::Kind::Entry: return "entry";
        case CfgNode::Kind::Exit: return "exit";
        case CfgNode::Kind::Assign: return "assign";
        case CfgNode::Kind::Output: return "output";
        case CfgNode::Kind::Branch: return "branch";
        case CfgNode::Kind::Return: return "return";
    }
    return "?";
}

}  // namespace

PointEnv singlePass(const Cfg &cfg, const ProgramA &program) {
    PointEnv states;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        const auto preds = predecessorMap(fc);
        for (const auto &[id, node] : fc.nodes) {
            if (node.kind == CfgNode::Kind::Entry) {
                states[id] = entryEnv(*decl);  // 边界条件：参数 ⊤
                continue;
            }
            // 前驱尚未计算（典型是循环回边）时其状态按全 ⊥（空环境）处理。
            SignEnv in;
            auto pit = preds.find(id);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    auto qit = states.find(q);
                    if (qit != states.end()) in = joinEnv(in, qit->second);
                }
            }
            states[id] = transferNode(node, in);
        }
    }
    return states;
}

std::string printPointEnv(const Cfg &cfg, const ProgramA &program,
                          const PointEnv &states) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";

        const FunDecl *decl = nullptr;  // 变量打印顺序：参数在前，局部变量在后
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();
        std::vector<std::string> names = decl->params;
        for (const std::string &v : decl->vars) names.push_back(v);

        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id << ' ' << nodeLabel(node.kind);
            if (node.kind == CfgNode::Kind::Branch && node.stmt) {
                // 分支点只标注条件，避免把整个 if/while 体压成一行又折行。
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << "  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << "  if " << printExpr(i->cond.get());
            } else if (node.stmt) {
                out << "  " << printStmtLine(*node.stmt);
            }
            out << ':';

            const SignEnv &env = states.at(id);
            for (const std::string &k : names) {
                auto it = env.find(k);
                out << ' ' << k << '='
                    << signShow(it == env.end() ? SBOT : it->second);
            }
            out << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
```

### 29.8.6 方程组与 worklist 求解器（第 22、23 章）

equations 把 CFG 读成显式的单调方程组，是分析的"规格
层"。本章的 --check 仍然先生成一次符号方程组——不是为了
求解（solveFixpoint 也不消费它），而是为了在接口上保持
"规格 ↔ 实现"的显式对应：signEquations 声明了符号分析
解的是哪组方程，solveConstFixpoint 的存在则声明了常量
分析有自己的方程组（同一张 CFG 直接生成，不再单独打印）。
equations.cpp 里 joinText 把多前驱写成 join(v2,v4) 的
文本形式，与 constant.cpp 里 constJoinEnv 的循环一一对应
——规格里的 join 与实现里的 join 是同一件事的两种语言。

对读两份代码还有一个收获：**规格层与实现层的演化速度
不同**。equations.cpp 自第 27 章以来零改动，而实现层在
第 28 章（单趟 → worklist）与本章（符号 → 常量）动了
两次——规格是系统中变化最慢的部分，这使它值得被单独
建模、单独打印、单独嵌入文档。本章没有为常量分析生成
打印版方程组，因为那张方程组与符号侧逐条同构（只差
传递函数的文本），重复打印的边际信息量太低；但
solveConstFixpoint 在结构上仍被写成"方程组的求解器"
而非"针对性算法"，一旦某天需要打印或静态验证常量方程，
MonoEq 的生成逻辑可以原样复制。规格先行的另一个隐性
收益在评审：reviewer 先读七条方程再读代码，代码的每一
个分支都能在方程上找到对应物，漏写一个 join 项这类
错误在规格对照下无处藏身——这比任何单元测试都更接近
"正确性构造"而非"正确性检验"。

```cpp
// file: src/equations.hpp
// 单调方程组（spa 4.4）：把"每点状态 = 传递函数作用于前驱合并"写成显式方程。
// 方程是分析的规格：第 28 章的 worklist 只是这组方程的一种求解算法。
#pragma once

#include <string>
#include <utility>
#include <vector>

#include "cfg.hpp"

namespace tip {

struct MonoEq {
    int point = 0;                 // 等号左边的程序点
    std::vector<int> deps;         // 右边依赖的前驱点（CFG 上的流依赖）
    std::string expr;              // 可读的右端表达
};

std::vector<MonoEq> signEquations(const Cfg &cfg);
std::string printEquations(const Cfg &cfg, const std::vector<MonoEq> &eqs);

}  // namespace tip
```

```cpp
// file: src/equations.cpp
#include "equations.hpp"

#include <map>
#include <sstream>
#include <vector>

#include "ast.hpp"
#include "pretty.hpp"

namespace tip {
namespace {

std::map<int, std::vector<int>> predecessorMap(const FunCfg &f) {
    std::map<int, std::vector<int>> preds;
    for (const auto &[from, to] : f.edges) preds[to].push_back(from);
    return preds;
}

// join 项的文本：单前驱直接用该点，多前驱写 join(...)。
std::string joinText(const std::vector<int> &deps) {
    if (deps.size() == 1) return "v" + std::to_string(deps[0]);
    std::string r = "join(";
    for (size_t i = 0; i < deps.size(); ++i) {
        if (i) r += ",";
        r += "v" + std::to_string(deps[i]);
    }
    return r + ")";
}

}  // namespace

std::vector<MonoEq> signEquations(const Cfg &cfg) {
    std::vector<MonoEq> all;
    for (const FunCfg &fc : cfg.funs) {
        const auto preds = predecessorMap(fc);
        for (const auto &[id, node] : fc.nodes) {
            MonoEq e;
            e.point = id;
            auto pit = preds.find(id);
            if (pit != preds.end()) e.deps = pit->second;

            std::ostringstream out;
            if (node.kind == CfgNode::Kind::Entry) {
                out << "entry boundary (params = ⊤)";
            } else {
                out << joinText(e.deps);
                if (node.kind == CfgNode::Kind::Assign && node.stmt) {
                    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
                    if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                        out << "[" << t->name << " := " << printExpr(a->value.get()) << "]";
                }
            }
            e.expr = out.str();
            all.push_back(std::move(e));
        }
    }
    return all;
}

std::string printEquations(const Cfg &cfg, const std::vector<MonoEq> &eqs) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const MonoEq &e : eqs) {
            bool inFun = false;
            if (const auto it = fc.nodes.find(e.point); it != fc.nodes.end()) inFun = true;
            if (!inFun) continue;
            out << "v" << e.point << " = " << e.expr << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
```

solve.{hpp,cpp} 是第 28 章的主角、本章的发动机——
solveFixpoint 一字未动地继续为 SIGN 栏供数。29.4 节已经
把 solveConstFixpoint 与它的五步骨架做了逐行对照，此处
不再重复；只补一句阅读建议：把这两份代码并排打开看
diff，"框架与组件"的分界线就在 diff 的红色行里——
凡是涉及 SignEnv/SignLattice/evalExprSign 的行都是
组件，其余全部是框架。

solve.hpp 的接口注释在本章多了一层含义。它写着"eqs 仅
用于确认求解的是第 27 章那组方程"——本章 main.cpp 确实
先生成 eqs 再传入，运行时被 (void) 弃用，这个"看似冗余"
的参数在 17.5 的总装里却承担了真实的叙事职责：它把
"符号预测来自第 15/16 章的方程组"写进了调用点，读者
不翻实现即可确认静态预测的谱系。常量侧没有对应的
constEquations 参数，是本章一个自觉的不对称：常量分析
的规格（三行 join、折叠语义）已经全部写在
constant.hpp 的头注释里，再绕道 MonoEq 只会多一层
间接。接口上"什么时候把规格显式化"没有标准答案，
判据是规格与实现的距离：距离远（跨章、跨文件）就
显式化，距离近（同文件头注释可见）就就地自明。

```cpp
// file: src/solve.hpp
// Worklist 不动点求解（spa 4.4）：从全 ⊥ 出发反复重算受影响的程序点，
// 直到没有点再变化——结果是方程组的最小不动点。
#pragma once

#include <vector>

#include "cfg.hpp"
#include "equations.hpp"
#include "sign_transfer.hpp"

namespace tip {

// eqs 仅用于确认"求解的是第 27 章那组方程"；依赖关系取自 CFG。
PointEnv solveFixpoint(const Cfg &cfg, const ProgramA &program,
                       const std::vector<MonoEq> &eqs);

}  // namespace tip
```

```cpp
// file: src/solve.cpp
#include "solve.hpp"

#include <deque>
#include <map>
#include <set>
#include <vector>

namespace tip {

namespace {

std::map<int, std::vector<int>> neighborMap(const FunCfg &f, bool successors) {
    std::map<int, std::vector<int>> r;
    for (const auto &[from, to] : f.edges) {
        if (successors) r[from].push_back(to);
        else r[to].push_back(from);
    }
    return r;
}

}  // namespace

PointEnv solveFixpoint(const Cfg &cfg, const ProgramA &program,
                       const std::vector<MonoEq> &eqs) {
    (void)eqs;
    PointEnv cur;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        const auto succs = neighborMap(fc, true);
        const auto preds = neighborMap(fc, false);

        // 初始值：除入口边界外全部 ⊥（空环境）。
        std::deque<int> wl{fc.entry};
        std::set<int> in{fc.entry};
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            in.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            SignEnv nv;
            if (node.kind == CfgNode::Kind::Entry) {
                nv = entryEnv(*decl);  // 边界条件不随前驱变化
            } else {
                SignEnv before;
                auto pit2 = preds.find(p);
                if (pit2 != preds.end())
                    for (int q : pit2->second)
                        if (auto it = cur.find(q); it != cur.end())
                            before = joinEnv(before, it->second);
                nv = transferNode(node, before);
            }

            auto old = cur.find(p);
            if (old == cur.end() || old->second != nv) {
                cur[p] = nv;  // 单调框架保证 nv ⊒ 旧值
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int s : sit->second)
                        if (!in.count(s)) {
                            wl.push_back(s);
                            in.insert(s);
                        }
            }
        }
    }
    return cur;
}

}  // namespace tip
```

### 29.8.7 格构造子与其演示单元（第 26 章）

lattice.hpp 的四个通用构造是"域可以组装"的证明。本章
17.2.1 用 lift 解释了扁平格的来历——理论上，常量格就是
对整数离散序做 lift 再补顶；实现没有走这条组装路线而是
手写三行 join，两相对照恰好说明通用构造与手写域的分工：
构造子适合"结构有层次的复合格"（环境 = 映射格），扁平格
这种"一页纸就写得下"的域手写更直白。

lift 的实现细节现在可以回头看清楚了：它给被提升的域
加一个 nullopt 底，join 里 nullopt 让位、否则委托内层
join。常量格与它的差别只在顶：lift 的结果里"两个不可
比元素"没有公共上界（离散序上 c₁ ⊔ c₂ 无定义），而
常量格需要顶——因为控制流汇合确实会发生、方程必须
有解。于是手写版在"两者不同"时返回 ⊤ 而不是求救。
这个两行的差距正是 17.2.1"配顶"一步的代码形态，也
解释了为什么 lift 不能直接充当常量格：**lift 造的是
"部分格"，方程组需要的是完全格**。第 30 章的乘积格
会把本域与常量域拼起来（每变量同时带符号与常量），
届时 maps(product(sign, const), vars) 的组装能力才会
真正发挥——现在埋个种子。

```cpp
// file: src/lattice.hpp
// 格的统一接口与四类通用构造（spa 第 4 章）。
// 一个"格"只需提供：顶/底两个边界、相等判定、偏序、最小上界。
// 提升(lift)、积(product)、映射(maps)、幂集(powerset)能把简单格组装成
// 程序状态所需的复合格——抽象环境就是"变量集合 → 值格"的映射格。
#pragma once

#include <functional>
#include <map>
#include <optional>
#include <set>
#include <tuple>
#include <utility>

namespace tip {

template <class A>
struct Lattice {
    A topV;
    A botV;
    std::function<bool(const A &, const A &)> eqF;
    std::function<bool(const A &, const A &)> leqF;
    std::function<A(const A &, const A &)> joinF;

    const A &top() const { return topV; }
    const A &bot() const { return botV; }
    bool eq(const A &a, const A &b) const { return eqF(a, b); }
    bool leq(const A &a, const A &b) const { return leqF(a, b); }
    A join(const A &a, const A &b) const { return joinF(a, b); }
};

// ---- 提升：给 A 加一个新底 ⊥=nullopt（"还没有值"） ----
template <class A>
Lattice<std::optional<A>> lift(const Lattice<A> &l) {
    using O = std::optional<A>;
    return Lattice<O>{
        O{l.top()}, O{std::nullopt},
        [](const O &a, const O &b) { return a == b; },
        [l](const O &a, const O &b) {
            if (!b.has_value()) return a == b;        // ⊥ 最小
            if (!a.has_value()) return true;
            return l.leq(*a, *b);
        },
        [l](const O &a, const O &b) {
            if (!a.has_value()) return b;
            if (!b.has_value()) return a;
            return O{l.join(*a, *b)};
        }};
}

// ---- 积：分量各自取 join，序为逐分量序 ----
template <class T, std::size_t... Is, class LTuple>
T tupleJoin(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return T{std::get<Is>(lats).join(std::get<Is>(a), std::get<Is>(b))...};
}
template <class T, std::size_t... Is, class LTuple>
bool tupleLeq(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return (... && std::get<Is>(lats).leq(std::get<Is>(a), std::get<Is>(b)));
}

template <class... As>
Lattice<std::tuple<As...>> product(const Lattice<As> &... ls) {
    using T = std::tuple<As...>;
    auto lats = std::make_tuple(ls...);
    T topT{ls.top()...};
    T botT{ls.bot()...};
    return Lattice<T>{
        std::move(topT), std::move(botT),
        [](const T &a, const T &b) { return a == b; },
        [lats](const T &a, const T &b) {
            return tupleLeq<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        },
        [lats](const T &a, const T &b) {
            return tupleJoin<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        }};
}

// ---- 映射：固定键集上逐点 join；键缺失按底处理 ----
template <class K, class V>
Lattice<std::map<K, V>> maps(const Lattice<V> &l, const std::set<K> &keys) {
    using M = std::map<K, V>;
    M topM, botM;
    for (const K &k : keys) {
        topM.emplace(k, l.top());
        botM.emplace(k, l.bot());
    }
    auto getOrBot = [&botM](const M &m, const K &k) {
        auto it = m.find(k);
        if (it != m.end()) return it->second;
        return botM.at(k);
    };
    return Lattice<M>{
        topM, botM,
        [](const M &a, const M &b) { return a == b; },
        [=](const M &a, const M &b) {
            for (const K &k : keys)
                if (!l.leq(getOrBot(a, k), getOrBot(b, k))) return false;
            return true;
        },
        [=](const M &a, const M &b) {
            M r;
            for (const K &k : keys) r.emplace(k, l.join(getOrBot(a, k), getOrBot(b, k)));
            return r;
        }};
}

// ---- 幂集：join=并，meet=交，序=包含；顶=给定全集（默认为空集） ----
template <class K>
Lattice<std::set<K>> powerset(const std::set<K> &universe = {}) {
    using S = std::set<K>;
    return Lattice<S>{
        universe, S{},
        [](const S &a, const S &b) { return a == b; },
        [](const S &a, const S &b) {
            for (const K &k : a)
                if (!b.count(k)) return false;
            return true;
        },
        [](const S &a, const S &b) {
            S r = a;
            r.insert(b.begin(), b.end());
            return r;
        }};
}

}  // namespace tip
```

lattice_demo 是第 26 章的固定 join 例子演示单元，本章
不调用、不改动，随快照一并嵌入以保证 examples 目录
自洽（构建脚本对 src 全量编译，它的存在不干扰本章
的任何模式）。

把它留在快照里还有一个教学上的理由：17.2.1 用"lift
离散序"解释了扁平格的理论出身，而 lattice_demo 里
`lift(sign)` 的两行输出（join(⊥,+) = +、join(0,−) = ⊤）
是 lift 语义在符号域上的实演。两个演示对着看——同一个
构造子，作用在"已有顶的格"上只是加底，作用在"离散序"
上就需要手工补顶——构造子的语义边界（它保证什么、
不保证什么）就从两份真实输出里浮出来了。教程嵌入
它但不重跑它，是把第 26 章的实证留在了原地；读者若
想验证，单跑第 26 章的示例即可，输出仍然逐字有效。

```cpp
// file: src/lattice_demo.hpp
// 第 26 章配套：在符号域上演示 lift/product/maps/powerset 四类构造的固定 join 例子。
#pragma once

#include <string>

namespace tip {

std::string latticeDemo();

}  // namespace tip
```

```cpp
// file: src/lattice_demo.cpp
#include "lattice_demo.hpp"

#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <tuple>

#include "lattice.hpp"
#include "sign.hpp"

namespace tip {
namespace {

std::string optShow(const std::optional<int> &o) {
    return o.has_value() ? signShow(*o) : "⊥";
}

std::string pairShow(const std::tuple<int, int> &t) {
    return "(" + signShow(std::get<0>(t)) + "," + signShow(std::get<1>(t)) + ")";
}

std::string mapShow(const std::map<std::string, int> &m) {
    std::string r = "{";
    bool first = true;
    for (const auto &[k, v] : m) {
        if (!first) r += ",";
        r += k + "=" + signShow(v);
        first = false;
    }
    return r + "}";
}

std::string setShow(const std::set<std::string> &s) {
    std::string r = "{";
    bool first = true;
    for (const std::string &k : s) {
        if (!first) r += ",";
        r += k;
        first = false;
    }
    return r + "}";
}

}  // namespace

std::string latticeDemo() {
    std::ostringstream out;
    out << "lattice constructors over the sign domain (fixed join examples):\n";

    Lattice<int> sign = signLatticeDomain();

    // lift：新底 ⊥ 与符号元素的 join。
    Lattice<std::optional<int>> lifted = lift(sign);
    std::optional<int> none, plus = SPLUS, zero = SZERO, minus = SMINUS;
    out << "lift(sign): join(⊥,+) = " << optShow(lifted.join(none, plus)) << '\n';
    out << "lift(sign): join(0,−) = " << optShow(lifted.join(zero, minus)) << '\n';

    // 积：两个符号分量分别 join，0⊔+=⊤，+⊔−=⊤。
    Lattice<std::tuple<int, int>> prod = product(sign, sign);
    auto a = std::make_tuple(SZERO, SPLUS);
    auto b = std::make_tuple(SPLUS, SMINUS);
    out << "product(sign,sign): join((0,+),(+,−)) = " << pairShow(prod.join(a, b)) << '\n';

    // 映射：两变量状态逐变量 join。
    Lattice<std::map<std::string, int>> stateLat =
        maps<std::string, int>(sign, {"x", "y"});
    std::map<std::string, int> s1{{"x", SZERO}, {"y", SBOT}};
    std::map<std::string, int> s2{{"x", SPLUS}, {"y", SPLUS}};
    out << "maps{x,y}->sign: join({x=0,y=⊥},{x=+,y=+}) = "
        << mapShow(stateLat.join(s1, s2)) << '\n';

    // 幂集：并集（第 30 章四大 DFA 的格）。
    Lattice<std::set<std::string>> powLat = powerset<std::string>();
    std::set<std::string> one{"a"}, two{"b"};
    out << "powerset: join({a},{b}) = " << setShow(powLat.join(one, two)) << '\n';

    return out.str();
}

}  // namespace tip
```

### 29.8.8 IR 生成与 ORC 执行台（第 15 章）

irgen 把 AST 编译成 LLVM Module：变量是 alloca 槽位、赋值
是 store、读取是 load、算术是 SSA 指令、main 改名 tip_main
再垫一个 tip_entry 包装。17.7 的 SCCP 对照全部建立在这份
IR 上——SCCP 对 store i32 11 的折叠、对 load/mul 的无能为
力，都是对这份 IR 形状的直接反应。它同时是 JIT 通道的
前端：--verify-soundness 的每次运行现场生成一份模块。

从常量传播的视角补看 irgen 的三个决定。第一，**alloca
而非 SSA 名字直接承载变量**：这让未优化 IR 与源代码
逐语句对应（一个赋值一条 store），教学上极友好，
代价是把常量信息藏进了内存——17.7 已详述，mem2reg
是恢复稀疏性的桥。第二，**零初始化 store i32 0**：
TIP 语义没有规定"读未赋值变量"的值，irgen 选择 0
作垫底，使生成的模块永远是良定义的——这层善意在
17.6.3 的输入设计里被绕开了（我们的输入保证循环体
执行），在 17.9 的注意点里被点名为"静态与动态对
未定义行为的双重沉默"。第三，**tip_entry 包装**：
input 的消费点被固定在函数入口——main 形参先于函数体
被读入。本章两个程序 main 均无参，input 全部出现在
表达式里，包装函数与解释器的 readInput 因此消费同一
条输入流、顺序一致，契约一的值序列相等才有可能成立。
假如把 input 的消费点放进 tip_entry 与函数体两个位置，
两条通道的读取顺序就会出现分叉——这类"语义对应点"
的对齐在单看任何一份代码时都不可见，只有对账失败时
才会现形。

```cpp
// file: src/irgen.hpp
// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 50 章以后扩展，遇到时直接报错。
#pragma once

#include <map>
#include <memory>
#include <string>

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

struct IRGen {
    // 三者均以 unique_ptr 持有：JIT 需要接管 Module 与 Context 的所有权。
    std::unique_ptr<llvm::LLVMContext> ctx;
    std::unique_ptr<llvm::Module> mod;
    std::unique_ptr<llvm::IRBuilder<>> b;

    const Bindings *bindings = nullptr;
    const FunDecl *cur = nullptr;
    std::map<const Symbol *, llvm::AllocaInst *> locals;

    IRGen();

    // 生成全部 TIP 函数 + C main（main 改名 tip_main）。
    // 结束后模块必须通过 verify。
    void gen(const ProgramA &program, const Bindings &resolved);

    llvm::Value *expr(const Expr *e);
    void stmt(const Stmt *s);

    bool verify() const;
    std::string dump() const;

  private:
    llvm::FunctionCallee rtInput_, rtOutput_;

    void genFun(const FunDecl *f, Scope *scope);
    void genWrapper(const FunDecl *mainFun);
};

}  // namespace tip
```

```cpp
// file: src/irgen.cpp
#include "irgen.hpp"

#include <stdexcept>
#include <utility>
#include <vector>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace tip {

IRGen::IRGen()
    : ctx(std::make_unique<LLVMContext>()),
      mod(std::make_unique<Module>("tip", *ctx)),
      b(std::make_unique<IRBuilder<>>(*ctx)) {
    // 运行时入口先声明：input 无参返回 i32，output 吃一个 i32。
    auto *i32 = Type::getInt32Ty(*ctx);
    rtInput_ = mod->getOrInsertFunction(
        "tip_input", FunctionType::get(i32, false));
    rtOutput_ = mod->getOrInsertFunction(
        "tip_output", FunctionType::get(Type::getVoidTy(*ctx), {i32}, false));
}

namespace {

// TIP 的 main 改名 tip_main：真正的 @main 是我们生成的 C 入口。
std::string emitName(const std::string &name) {
    return name == "main" ? "tip_main" : name;
}

}  // namespace

void IRGen::gen(const ProgramA &program, const Bindings &resolved) {
    bindings = &resolved;

    // 先创建全部函数（含类型），函数体互相前向调用时也能查到声明。
    auto *i32 = Type::getInt32Ty(*ctx);
    for (const auto &f : program.funs) {
        std::vector<Type *> args(f->params.size(), i32);
        auto *ft = FunctionType::get(i32, args, false);
        Function::Create(ft, Function::ExternalLinkage,
                         emitName(f->name), *mod);
    }

    for (size_t i = 0; i < program.funs.size(); ++i) {
        const auto &f = program.funs[i];
        cur = f.get();
        genFun(f.get(), resolved.scopes[i].get());
    }

    const FunDecl *mainFun = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFun = f.get();
    if (!mainFun) throw std::runtime_error("program has no main");
    genWrapper(mainFun);
}

void IRGen::genFun(const FunDecl *f, Scope *scope) {
    auto *fn = llvm::cast<Function>(mod->getFunction(emitName(f->name)));
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    // 形参：alloca 槽位 + 存入实参；var 局部：alloca + 零初始化。
    for (size_t j = 0; j < f->params.size(); ++j) {
        const Symbol *s = &scope->table.at(f->params[j]);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, f->params[j]);
        b->CreateStore(fn->getArg(j), slot);
        locals[s] = slot;
    }
    for (const std::string &v : f->vars) {
        const Symbol *s = &scope->table.at(v);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, v);
        b->CreateStore(b->getInt32(0), slot);
        locals[s] = slot;
    }

    stmt(f->body.get());
    b->CreateRet(expr(f->ret->e.get()));
}

Value *IRGen::expr(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e))
        return ConstantInt::get(b->getInt32Ty(), x->v, true);

    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        const Symbol *s = bindings->uses.at(x);
        return b->CreateLoad(b->getInt32Ty(), locals.at(s), x->name);
    }

    if (dynamic_cast<const InputE *>(e))
        return b->CreateCall(rtInput_);

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        Value *l = expr(x->l.get());
        Value *r = expr(x->r.get());
        switch (x->op) {
            case BOp::Add: return b->CreateAdd(l, r);
            case BOp::Sub: return b->CreateSub(l, r);
            case BOp::Mul: return b->CreateMul(l, r);
            case BOp::Div: return b->CreateSDiv(l, r);
            case BOp::Gt: {
                Value *p = b->CreateICmpSGT(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
            case BOp::Eq: {
                Value *p = b->CreateICmpEQ(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
        }
    }

    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        const auto *nameUse = dynamic_cast<const VarRef *>(x->callee.get());
        if (!nameUse)
            throw std::runtime_error("ch15: 间接调用留待第 50 章");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("ch15: 间接调用留待第 50 章");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("ch15: 指针与记录构造留待第 50 章");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        const auto *target = dynamic_cast<const VarRef *>(x->target.get());
        if (!target)
            throw std::runtime_error("ch15: 经指针/字段写入留待第 50 章");
        const Symbol *sym = bindings->uses.at(target);
        b->CreateStore(expr(x->value.get()), locals.at(sym));
        return;
    }

    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        b->CreateCall(rtOutput_, {expr(x->e.get())});
        return;
    }

    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *thenBB = BasicBlock::Create(*ctx, "then", fn);
        auto *elseBB = BasicBlock::Create(*ctx, "else", fn);
        auto *mergeBB = BasicBlock::Create(*ctx, "merge", fn);

        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, thenBB, elseBB);

        b->SetInsertPoint(thenBB);
        stmt(x->then.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);

        b->SetInsertPoint(elseBB);
        if (x->els) {
            stmt(x->els.get());
            if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);
        } else {
            b->CreateBr(mergeBB);
        }
        b->SetInsertPoint(mergeBB);
        return;
    }

    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *header = BasicBlock::Create(*ctx, "wh.cond", fn);
        auto *bodyBB = BasicBlock::Create(*ctx, "wh.body", fn);
        auto *exitBB = BasicBlock::Create(*ctx, "wh.exit", fn);

        b->CreateBr(header);
        b->SetInsertPoint(header);
        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, bodyBB, exitBB);

        b->SetInsertPoint(bodyBB);
        stmt(x->body.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(header);

        b->SetInsertPoint(exitBB);
        return;
    }

    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        for (const auto &st : x->ss) stmt(st.get());
        return;
    }

    if (const auto *x = dynamic_cast<const ReturnS *>(s))
        b->CreateRet(expr(x->e.get()));
}

void IRGen::genWrapper(const FunDecl *mainFun) {
    // C 入口：按 TIP main 形参数目读 input，再调用 tip_main。
    // 不命名为 main——MinGW 目标会向 main 注入对 CRT 符号 __main 的调用。
    auto *fn = Function::Create(FunctionType::get(b->getInt32Ty(), false),
                                Function::ExternalLinkage, "tip_entry", *mod);
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    std::vector<Value *> args;
    for (size_t j = 0; j < mainFun->params.size(); ++j)
        args.push_back(b->CreateCall(rtInput_));
    Value *r = b->CreateCall(mod->getFunction("tip_main"), args);
    b->CreateRet(r);
}

bool IRGen::verify() const {
    std::string err;
    llvm::raw_string_ostream os(err);
    bool bad = llvm::verifyModule(*mod, &os);
    os.str();
    return !bad;
}

std::string IRGen::dump() const {
    std::string out;
    llvm::raw_string_ostream os(out);
    mod->print(os, nullptr);
    return os.str();
}

}  // namespace tip
```

jitrun 把模块交给 LLJIT、注入 tip_input/tip_output 两个
宿主回调，真实执行 tip_entry。17.5 的对账里它是"动态"
一侧的执行引擎，解释器是另一台——两台机器共享的只有
输入与 TIP 语义，实现上零耦合，这正是 `outputs ==
concrete.values` 断言有对抗价值的前提。

零耦合的实现里有一个刻意的不对称值得指出：解释器的
readInput 在输入耗尽时抛异常，JIT 的 tip_input 却返回
0——JIT 回调无法抛 C++ 异常穿越 JIT 边界（异常展开
要跨越 JIT 生成的栈帧，ORC 的默认配置不保证支持），
返回 0 是工程上的安全垫。这个不对称在正常实验里不
触发（输入行恰好喂饱每次执行），但它的存在提醒我们：
**契约一的"两条通道语义等价"只在语言的良定义区域内
成立**；未定义区域（输入耗尽、除零、溢出）里两条通道
各自选了不同的应急行为，对账在这些区域必须绕行。
第 36 章把"未定义区域"本身作为分析对象时，会先给
TIP 语义补全这些角落，再谈对账。

```cpp
// file: src/jitrun.hpp
// ORC JIT 执行：把 IRGen 的模块交给 LLJIT，注入 tip_input/tip_output
// 两个宿主 C 函数，真实执行 main，收集输出序列。
#pragma once

#include <vector>

#include "irgen.hpp"

namespace tip {

// 一次执行：inputs 按出现顺序被 tip_input 消费，返回 output 值序列。
// 模块所有权随 IRGen 一起移入 JIT。
std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs);

}  // namespace tip
```

```cpp
// file: src/jitrun.cpp
#include "jitrun.hpp"

#include <cstdint>
#include <stdexcept>

#include "llvm/ExecutionEngine/JITSymbol.h"
#include "llvm/ExecutionEngine/Orc/Core.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/ExecutionEngine/Orc/ThreadSafeModule.h"
#include "llvm/Support/TargetSelect.h"

using llvm::StringRef;
using llvm::JITSymbolFlags;
using llvm::orc::ExecutorSymbolDef;
using llvm::JITTargetAddress;
using llvm::jitTargetAddressToFunction;
using llvm::pointerToJITTargetAddress;
using llvm::orc::LLJITBuilder;
using llvm::orc::SymbolMap;
using llvm::orc::ThreadSafeModule;
using llvm::orc::absoluteSymbols;

namespace tip {
namespace {

// JIT 模块通过这两个宿主函数与外界交换数据。
const std::vector<int> *inQueue = nullptr;
std::vector<int> *outQueue = nullptr;
size_t inPos = 0;

extern "C" int32_t tip_input() {
    if (inPos >= inQueue->size()) return 0;
    return (*inQueue)[inPos++];
}

extern "C" void tip_output(int32_t value) {
    outQueue->push_back(value);
}

void initNative() {
    // 进程内只初始化一次。
    static const bool ready = [] {
        llvm::InitializeNativeTarget();
        llvm::InitializeNativeTargetAsmPrinter();
        return true;
    }();
    (void)ready;
}

[[noreturn]] void fail(llvm::Error e) {
    std::string text = llvm::toString(std::move(e));
    throw std::runtime_error(text);
}

}  // namespace

std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs) {
    initNative();
    std::vector<int> outputs;
    inQueue = &inputs;
    outQueue = &outputs;
    inPos = 0;

    auto jitOrErr = LLJITBuilder().create();
    if (!jitOrErr) fail(jitOrErr.takeError());
    auto jit = std::move(*jitOrErr);

    auto defineHost = [&](StringRef name, void *addr) {
        SymbolMap symbols;
        symbols[jit->mangleAndIntern(name)] = ExecutorSymbolDef(
            llvm::orc::ExecutorAddr::fromPtr(addr), JITSymbolFlags());
        if (llvm::Error e =
                jit->getMainJITDylib().define(absoluteSymbols(symbols)))
            fail(std::move(e));
    };
    defineHost("tip_input", reinterpret_cast<void *>(&tip_input));
    defineHost("tip_output", reinterpret_cast<void *>(&tip_output));

    ThreadSafeModule tsm(std::move(gen.mod), std::move(gen.ctx));
    if (llvm::Error e = jit->addIRModule(std::move(tsm)))
        fail(std::move(e));

    auto mainAddr = jit->lookup("tip_entry");
    if (!mainAddr) fail(mainAddr.takeError());
    auto *entry = jitTargetAddressToFunction<int (*)()>(mainAddr->getValue());
    entry();

    return outputs;
}

}  // namespace tip
```

## 29.9 工程注意点

把本章放进真实的工程语境，有六件事值得预先想清楚。

**第一，状态爆炸的邻居：路径数。** 常量格本身极其便宜
（每变量一个值、三态切换），但它的精度死穴在汇合处：
两条路径带来不同常量，⊤ 一锤定音。路径敏感的分析
（每个分支条件单独建模状态）能推迟这个时刻，代价是状态
数随路径数指数增长。SCCP 的"conditional"是一步温和的
路径敏感化——常量条件剪掉不可行边；更激进的路径敏感
变体（第 48 章后的上下文敏感话题）则把状态直接挂在
路径历史上。拿到一个"精度不够"的报告时，先问：是
汇合的锅还是传递函数的锅——两者的解法完全不同。

**第二，稠密环境的成本。** 我们在每个程序点存一整份
变量 → 值的映射，合并时逐变量 join。P 个点、V 个变量时
状态总量是 O(PV)，对编译器规模的函数（数千变量）这是
真实负担。稀疏化（SCCP 的路线）把值挂在定义处、按
def-use 边流动，状态总量正比于"定义数"而非"点数 ×
变量数"。第 30 章做完四大 DFA 后会再回到这个话题：
稠密是教学形态，稀疏是生产形态，方程组是两者共同的
规格。

**第三，⊥ 的双重语义要在报告里拆开。** 17.2.3 节说过
⊥ 同时承担"不可达"与"动态错误"。若把常量分析的结果
喂给下游工具（比如死代码消除或告警器），BOT 必须区分
两种来源：来自"前驱全无信息"的 ⊥ 可以安全地当不可达
处理；来自"常量除零"的 ⊥ 意味着"这条路径会炸"，把它
当死代码删掉会把一个必然崩溃的程序变成静默错误的程序。
实现层面最小的一步是把 cBot() 的两处产生点（缺键 vs
除零）打上不同的来源标记——本章为了格的极简没有做，
但任何下游消费前都该补上。

**第四，有符号溢出在抽象层被静默放行。** evalConstExpr
的折叠用 C++ 的 int 直接算：`cVal(l.v + r.v)`。两个
接近 INT_MAX 的常量相加在宿主 C++ 里是未定义行为——
折叠出的"常量"可能是一个毫无道理的数。TIP 本身没有
规定溢出语义，JIT 编译出的 LLVM add 同样对此未定义，
所以"静态折叠结果 = 动态结果"在抽象意义上仍然自洽
（两边都是未定义），但宿主侧的 UB 是另一个层面的问题
——编译器有权对 signed overflow 做任何事。工业实现的
折叠一律用带环绕或带饱和检测的运算。本教程的示例常量
远离边界，这个缝隙留给读者在练习里补。

**第五，经验检验的输入设计是一门手艺。** sign1.inputs
与 fold.inputs 是刻意设计的：前者保证循环体至少执行
（否则 output 读未赋值变量，语义未定，对账失去意义——
第 28.7 节的分工说明），后者让同一预测（a=11）反复
过关、另一个预测（b=⊤）反复豁免。随机输入能覆盖更多
路径，但缺少"每个静态承诺至少被盘查一次"的定向性。
规范的做法是从静态结果反向构造输入：找一个能让某条
output 的预测为确定常量的输入组合，专门盘查那个承诺。
第 36 章的检查器会把这个思路程序化。

**第六，--verify-soundness 是门禁不是仪式。** 裁决行
以非零退出码区分 SOUND/FAILED，任何 CI 都能直接消费。
更重要的使用姿势是"改格必跑"：每次调整 cJoin、
evalConstExpr 或 CFG 构造，先跑一遍两个程序的检验再
谈别的——它是传递函数与对账枢纽之间那条脆弱对应
（程序点、语句指针、预测表达式）的常驻哨兵。第 28 章练习三建议的"单调性断言化"与本章的检验合在一起，
构成数据流分析的两条回归防线：一条守求解器，一条守
语义。

**第七，expected 快照是有生命的合同。** 本章的
expected 目录里有四类文件：--check 的总输出、两个
程序的 soundness 裁决、SCCP 的对照输出，以及两份输入
清单。它们构成一个四方合同——分析器、对账器、输入
设计、外部工具（opt）各自的当前行为被逐字节封存。
任何一方升级（换 LLVM 版本、改打印格式、调输入集），
合同就要重新公证：重跑、肉眼审查差异、确认每一处
变化都是**有意的**再提交。这个流程听起来繁琐，但它
把"升级是否破坏了什么"从记忆问题变成 diff 问题。
经验做法是升级说明写进提交信息（哪个文件、哪一行、
为什么变了），让半年后的考古有据可查。

**第八，输入消费的配平要当作断言来守。** 17.8.8 提到
两条通道对"输入耗尽"处理不同（解释器抛异常、JIT 返
0），17.6.3 的输入行都是"恰好喂饱"的。这种配平目前
靠设计者心算：sign1 的输入以 0 结尾是因为循环要消费
一个"退出值"，fold 的单值输入恰好够一个 input 表达式。
程序稍复杂（多条路径消费不同数量的 input），心算就会
出错——而配平失败的表现是两条通道在"边界上"分叉
（一个抛异常、一个静默 0），对账以最迷惑的方式失败。
工程上的补救很轻：在对账循环里记录每行输入被消费的
个数（解释器有 inputPos 现成可读），与输入行长度比对，
不等即报"input imbalance"而非继续对账。这个检查本章
没有实现——它连同 ⊥ 的来源标记一起，都是"实验代码
走向生产代码"清单上的前两名。

## 29.10 拓展练习

**练习一（折叠表的手推验证）。** 在纸上对 fold.tip 的
点 3 手推 evalConstExpr 的完整递归：写出每个子表达式
返回的 Const（kind 与 v），标出命中了哪个吸收分支。
然后给 fold.tip 增加一行 `c = b * 2; output c;`，先预测
c 的静态值与每次对账的 obs 增量，再跑 --check 与
--verify-soundness 验证。

**练习二（幂等性的边界）。** 构造一个循环体"半幂等"的
程序：`x = 2; while (input > 0) { y = x; x = 2; }`，
预测 y 与 x 在循环头与循环尾的常量值。再把 x = 2 改成
x = x + 0——结果应当完全相同（加零是恒等变换）。最后
改成 x = x * 1，先想一想为什么这次也相同，再跑工具
确认。这个练习的手感目标是：看到循环体就能预判常量
能否存活。

**练习三（除零路径的 ⊥ 传播）。** 写一个程序：
`x = 1 / 0; output x;`，跑 --check。观察 output 点的
x 是否为 BOT，再解释为什么这次对账不能跑（提示：
--verify-soundness 需要 input 集合，而这份程序在解释器
里第一步就抛异常）。把 17.9 注意点三的"来源标记"实现
到 constant.hpp 里：给 Const 加一个 bool fromDivZero，
打印时 BOT 写作 BOT(DIV)，观察输出变化。

**练习四（相等检验的对抗测试）。** 故意在 sign_transfer
的 sAdd 表里改坏一格（比如 (+,+) 改成 ⊤），重跑
--verify-soundness。观察哪类断言先失败、失败信息长什么样。
恢复后，再故意把 constant.cpp 的 cJoin 相等分支改成
返回 cBot——这次失败的是哪道断言？两个实验分别展示了
"对账守语义"与"对账守合并"的两条防线。

**练习五（与 mem2reg 的完整对照）。** 把 17.7 的管道改成
`tipa --emit-ir ... | opt -passes=mem2reg,sccp -S`，对比
sccp.out 与新输出：%a/%b 的 alloca/load 应当消失，b 的
计算链（mul 22、add input）应当暴露在 SSA 值上。解释
为什么现在 `mul i32 22` 仍不会被折掉（input 是外部调用），
而 output a 的实参应被替换成常量 11。这道练习把"稀疏"
从概念变成肉眼可见的 IR 差异。

**练习六（配平守卫）。** 按注意点八的设计，在对账循环
里加入输入配平检查：解释器跑完后比较 inputPos 与输入行
的整数个数，不等则打印 `run N: input imbalance (expected
M, consumed K)` 并跳过对账。构造一个两条路径消费不同
数量 input 的程序（if 的一翼多一个 input），喂一行
"临界"输入让两条通道对"耗尽"做出不同反应，观察没有
守卫时对账输出多么费解、有守卫时多么直白。

**练习七（obs 的静态预测器）。** 写一个小脚本（或在
main.cpp 加 --predict-obs 模式）：只跑 --check 的静态
部分，数一数"预测为确定常量的 output 表达式个数"，
据此预测 --verify-soundness 的 obs 数。对 fold 与 sign1
预测应精确命中 9 与 6。这个练习把"obs 可手工复算"
从口头承诺变成工具——也给将来更大的实验程序一个
"对账覆盖度"的先行指标。

### 29.10.8 思考题详解与 FAQ

下面把本章阅读中最常被追问的十六个问题集中作答。
问题按"格与序 → 传递函数 → 引擎 → 检验 → 定位"的
顺序排列；每题先给最短答案，再给出理由与正文的
对应小节。

**问一：⊥ 和 BOT 是同一个东西吗？** 是。文档正文
用数学符号 ⊥ 叙述、代码与输出用字符串 BOT 打印，
指的都是常量格的最小元素。类似地 ⊤ 与 TOP 同义。
阅读时把两套记号一一对应即可。

**问二：为什么两个不同常量 join 的结果不是"二选一"
之类更精确的元素？** 因为扁平格里根本不存在这样的
元素。承载集只有 {⊥, 具体整数, ⊤}，能同时大于 c
与 d 的上界唯一是 ⊤（17.2.7 的最小上界核验）。想要
"{5 或 7}"这样的元素，必须换一块承载集更丰富的格
（比如整数集合的幂集格），那已经是另一个分析。

**问三：join 里为什么让 ⊥ 让位而不是保留？** 因为
⊥ 的具体化是空集。汇合处两条路径的可能值取并集，
空集与任何集合并都等于另一边。反过来若让 ⊥ 吸收
（遇 ⊥ 得 ⊥），则一条"尚未分析"的前驱会永久压制
其他前驱的信息，迭代无法启动。⊥ 在表达式折叠中
吸收（⊥ 沿表达式向上传染）与在环境 join 中让位，
方向相反、各司其职（17.3.2）。

**问四：常量除零为什么映射到 ⊥ 而不是给一个特殊
错误值？** 因为该路径在具体语义里不产生任何值
（抛错终止）。"不产生值"恰是 ⊥ 的具体化 ∅ 的含义
（17.2.3）。若引入专门的错误元素，格要重新设计、
join 规则要重写，而收益只是区分两种"无值"来源；
17.9 第三条建议在工程上用来源标记区分，不必动格。

**问五：evalConstExpr 为什么对未绑定变量返回 ⊥？
未绑定不就是"什么都可能"吗？** 在常量分析的约定里
不是。未绑定意味着"此路径上该变量尚未被赋值"，
缺键按 ⊥ 读（17.3.5 的环境格定义）。"什么都可能"
是 ⊤，它只用于 input 这类真随机源。把缺键读作 ⊤
会让未初始化变量静默逃避所有告警——第 32 章的可能
未初始化分析正是建立在"缺键 = 有信息（嫌疑）"这
个方向上。

**问六：input 为什么不能记成"上一次输入的值"？**
静态分析面对的是所有可能执行，input 在不同执行中
取遍 Z。它在抽象侧的唯一 sound 表示是 ⊤（γ=Z）。
JIT 执行时 input 被某次具体输入替换，这是"一次
执行"的视图；静态视图必须覆盖所有输入。17.5 的
检验则把两者对齐：具体执行的输入由 .inputs 文件
指定，分析的 ⊤ 对任何具体值都豁免。

**问七：常量分析能不能识别 `x - x` 恒为 0？**
本章的实现不能：当 x = ⊤ 时两边各取 ⊤、⊤ 吸收
减法得 ⊤。MOP 视角下该式确为 0（17.4.3 的分配性
反例），恢复它需要让传递函数意识到"两个 x 是同一
个变量"（关系域）或逐路径求值。这是 MFP 相对 MOP
精度损失的标准例子，也是第 32 章之后换更聪明域的
动机之一。

**问八：说传递函数单调，到底什么在"变"？** 变的
是环境摘要：信息从 ⊥（空）经具体常量向 ⊤（全体）
流动。单调要求输入环境在这个序上变大时输出不会
变小。17.3.5 证明的关键细节是：两个具体常量之间
没有序边，所以单调函数在常量层只能恒等——任何
"随输入把 c 改成 c'"的设计都不单调。

**问九：为什么求解器对每个函数都从 ⊥ 起步，而不是
从 ⊤ 起步？** 因为要求最小不动点。从 ⊥ 起步迭代
得到方程组的最小解，它是 MOP 的最佳逼近（17.4.3）。
从 ⊤ 起步会单调下降，求的是最大不动点，包含大量
"从未被证明可达"的信息，对 may/must 两类分析都会
给出错误承诺。方向与边界的配对是单调框架五元组的
一部分（第 32 章总表）。

**问十：fold.tip 与 sign1.tip 的求解成本各是多少？**
fold 七次弹出、零节点重处理（直线）；sign1 共十四次
弹出：七个节点各处理两遍（顺流一遍、回流后再一遍），
其中点 4 第二遍的重算被写回比较拦住、不再传播
（17.6.6 慢放）。一般地，成本 ≈ 节点数 ×（绕圈引发
的波次 + 1）；扁平格把波次上限定为每变量两次写回
（17.4.1）。

**问十一：worklist 的 FIFO 顺序影响结果吗？影响
效率吗？** 不影响结果：单调方程组的最小不动点唯一，
与重算次序无关。影响效率：坏次序会让信息在环上多
绕几圈才到齐。逆后序等启发式（第 28 章）对前向
分析能显著减少重处理次数；本章教学实现坚持 FIFO
以保持快照可复现。

**问十二：17.5 同时用解释器和 JIT，是不是多此
一举？** 两者各有不可替代的职责。JIT 只产生输出值
序列，不记录"第 k 个值来自哪条 output 语句"；解释
器在执行时登记这个语句户口（ConcreteRun.sites），
静态预测才能按站点查询对账。解释器的值序列再与 JIT
的值序列交叉核对（outputs == concrete.values），
保证解释器与 JIT 语义一致、户口登记没有错位
（17.5.2、17.5.3）。

**问十三：为什么 output 预测为 ⊤ 时断言自动通过？
这不是放任吗？** 因为 ⊤ 的具体化是整个 Z，任何具体
整数都 ∈ Z。成员检验断言"具体值 ∈ γ(预测)"，对 ⊤
恒真。检验只盘查分析真正做出的承诺：常量承诺逐值
相等、符号承诺符号相符；不承诺处不盘查。放任的不是
检验而是 ⊤ 本身——要盘查得先让分析给出更精细的
元素。

**问十四：`SOUND 3 runs` 算不算证明了分析可靠？**
不算。它只说明这三个输入组对应的执行没有推翻成员
关系（17.5.4、17.6.6）。可靠性作为全称命题（对所有
执行成立）只能靠形式化证明（17.3.6 的交换图与第 65 章的全局版本）。经验检验的价值是抓住实现错误
（练习四的对抗实验），不是替代证明。报告的量化范围
永远等于 .inputs 的覆盖范围。

**问十五：如果想让本章分析覆盖函数调用，最小改动是
什么？** 常量折叠遇 CallE 一律返回 ⊤ 是当前的保守
处理。最小改进是第 46 章的做法：在传递函数层对直线
纯函数内联展开（实参绑形参、顺序执行赋值、取返回
表达式），有环或非直线处仍回退 ⊤。再进一步就是第 47 章按调用串分箱的 k-CFA。引擎骨架不变，变的只是
CallE 一个分支。

**问十六：本章的常量格和 LLVM SCCP 的 undef/
overdefined 完全等价吗？** 概念对应但不等价。SCCP
在 SSA 值上运行，undefined 对应 ⊥、constant 对应 c、
overdefined 对应 ⊤（17.7.1）；但 SCCP 同时维护可执行
CFG、让常量条件剪边（本章不做），且现代 LLVM 的
undef 已被 poison 语义细分。对照用于理解"同一格论
结构跨实现出现"，不应把两边逐值行为等同。

**问十七：第 25 章的符号格和本章常量格，哪一个"更强"？**
两者不可直接比强弱：它们抽象的是不同性质。符号格回答
正负零，对任何算术都给结论（⊤ 处也只是放弃符号）；
常量格回答是否确定值，给得出常量时承诺更强（"是 11"
推出"为正"），给不出时只剩 ⊤。形式化地说，存在映射把
常量结果改写成符号（⊥→⊥、⊤→⊤、c 按符号映射），
反向不存在——常量格的承诺可推出符号格的承诺，反之
不然，但这只说明"常量承诺更强"，不说明常量分析处处
更精确。工程上两者常同时运行、互补使用。

**问十八：既然能定义 meet，为什么求解器只沿 join 方向
迭代？** 因为程序状态的信息在执行中"分叉并汇合"，汇合
的具体语义是可能值取并——对应的抽象运算是 join。迭代
从信息最少的 ⊥ 出发收集事实，沿 join 上升到最小不动点。
meet 对应的是"同时满足两边约束"，出现在精炼（如条件
约束收窄区间，第 30、31 章）而非合并中。用错算子方向
会求出"最大解"，把未经证实的信息也包含进来。

**问十九：本章代码里 printConstEnv 为什么打印全部变量
而不只打印有值的？** 因为 ⊥ 也是承诺的一部分："此处
该变量不可达/未定义"与"此处为常量"同样是分析结论，
省略会让逐点对账无法发现某变量的状态从 ⊥ 被错误改写。
全量打印使快照对每个变量的每次变化都敏感（17.6.5 约定
三）。代价只是输出更长——对教学快照，可读性与对账密度
比紧凑重要。

**问二十：如果 TIP 增加布尔类型，常量格要怎么改？**
承载集从"整数平铺 + ⊥/⊤"扩为"按类型分层平铺"：
布尔常量（0/1 或 true/false）与整数常量分属不可比的
层，join 仅在同类型同值时保留、跨类型合并给 ⊤ 或专门
的类型冲突元素。本质上是把扁平格按类型做积（第 26 章
product 构造）。若再让类型分析为每点标注类型，常量格
可只在标注类型上取层，精度与成本都更优——这正是工业
编译器"类型先行、常量后行"流水线的一个小缩影。

### 29.10.9 闭卷自测八问

读完本章后，可用下面八问做闭卷检验；问题不附答案，答案
全部可由正文相应小节直接推出。每题都应能在不看源码的情况
下用三五句话讲清；讲不清的一节即应回读处。

第一问：不看代码写出常量格的三个元素层级与 cJoin 的三条
规则，并各举一个程序片段说明该规则何时被触发（回读
17.2.2、17.2.6）。

第二问：解释"缺键按 ⊥ 读"与"缺键按 ⊤ 读"两个约定分别会
导致什么后果；为什么常量分析与可能未初始化分析都选择前者
（17.3.5、FAQ 问五）。

第三问：写出 evalConstExpr 中 Binop 分支三条判定的先后
次序，并说明为什么 ⊥ 吸收必须排在最前、⊤ 吸收必须排在
折叠之前（17.3.2、17.3.5）。

第四问：用环境逐点序的语言证明"赋值 x=e 的传递函数单调"，
指出证明中唯一依赖 e 的一步是什么（17.3.5）。

第五问：陈述 MOP 与 MFP 的定义、写出 MOP ⊑ MFP 的定理与
证明的归纳不变量，并给出一个两解严格不等的表达式例子
（17.4.3）。

第六问：说明 --verify-soundness 中解释器与 JIT 各自不可
替代的职责，以及 outputs == concrete.values 这行比较在
证明结构中守的是什么引理（17.5.2、17.5.7）。

第七问：对 sign1.tip 按 17.6.6 的口径口述十四次弹出的完整
序列，并指出第二阶段唯一一次"重算但不传播"发生在哪个点、
被什么机制拦住。

第八问：用 γ 成员关系分别解释常量断言、符号断言、⊤ 豁免、
⊥ 不检验四种处理；据此说明 SOUND 裁决的量化范围为什么只
等于 .inputs 的覆盖范围（17.5.7、17.6.6）。

### 29.10.10 延伸阅读地图

若想就本章任一主题继续深入，按下面四条线索取材最省力。

其一，扁平格与提升构造的标准叙述见 spa 第 4 章；配套的
形式化习题（证明 lift、maps 构造保持格律）可对照本教程
第 26 章动手核验。

其二，MOP/MFP 定理与分配性在数据流教材中通常以
Kildall 的名字出现；读完 17.4.3 后可直接进入第 48 章的
IFDS——它把"分配问题线性时间求 MOP"做成通用框架。

其三，稀疏条件常量传播的原始论文描述了 SCCP 的两相
（可执行边、格值）互推结构；对照 17.7 与 LLVM 中
SCCP 的实现源码阅读，概念表能逐行对上。

其四，可靠性与抽象解释的完整理论（Galois 连接、局部到
全局的严格推导）见第 65 章；在那之前第 34–36 章先展示
无穷高格上的工程机制（加宽、收窄、路径精炼），与本章
的有限经验检验形成对照。

其五，若关心工程上的常量承诺如何被下游消费，可读 LLVM
中 assume/constantrange 元数据与告警管线的协作；对照
17.9 第三、四条，理解"承诺带来源、溢出有策略"在生产
编译器里的具体落点。

其六，想亲手实验的读者最推荐练习四与练习七：前者用
对抗性改动体会经验检验抓哪类故障，后者把 obs 计数从
口头约定变成可运行的静态预测器，两个练习合起来覆盖了
本章方法论的攻守两面。

最后提示：本章所有结论的记号都可在 17.2.7 一处查得；
回读任何证明之前先确认 γ、α 与偏序定义，效率最高。

## 29.11 小结

本章在不动求解器一行代码的前提下，把第四篇的机器开进了
第二块田地。

**域**：扁平常量格 {⊥, c, ⊤}——整数之间无序、全体悬于
⊥ 与 ⊤ 之间；它是 lift(离散序) 的直接实例，γ(⊥)=∅、
γ(c)={c}、γ(⊤)=Z 三个等式撑起全部语义。cJoin 三规则
（⊥ 让位、相等保留、异常量归 ⊤）一页写尽，除零入 ⊥
让"错误路径"与"不可达路径"共用一个符号。

**传递函数**：evalConstExpr 把常量表达式折叠成值，
input 与调用保守给 ⊤；⊥ 沿表达式向上传染（空集的世界
里没有算术），⊤ 同样向上吸收（一个未知数毁掉全部
确定性）。两种吸收方向相反、各司其职。

**引擎**：同一台 worklist——弹出、合并前驱、传递、
比较、写回、入队——喂进新的格与传递函数就是新的分析。
终止性在无穷高的扁平格上依然成立，因为星形结构把
单调链截断在"每变量至多两次写回"。这是格抽象化红利的
兑现时刻。

**检验**：可靠性从定义变成程序。具体解释器给每个输出值
登记语句户口，JIT 独立地跑出同样的值序列；成员检验
盘查符号承诺，相等检验盘查常量承诺；nodeOf 映射的
正确性由"一次解析、四方共用"的指针同一性保证；
`SOUND 3 runs, 9 observations` 不是证明而是"未被推翻"
的战绩，与 16.4 的不动点证明一攻一守构成完整的可信度
结构。

**对照**：LLVM 的 SCCP 在同一份 IR 上折出同样的 11——
抽象解释的结论跨实现稳定；它止步于内存操作的边界，
mem2reg 打通 SSA 后稀疏的力量才完全释放。undef/
overdefined 与 ⊥/⊤ 的对应把教科书与工业实现接在同一条
格论根上。

第 30 章将用幂集格与同样的引擎实现四大经典数据流分析
（到达定值、活跃变量、可用表达式、非常忙表达式）——
域再换一次，骨架纹丝不动。到时候回头看，本章真正的
遗产不是常量传播，而是那条已被验证两次的流水线：
**换域、换传递函数，然后让对账程序证明你没有换错。**
