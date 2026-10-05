# 第 8 章　抽象语法树：分析算法的工作平面

## 8.1 parse tree 缺什么、又多了什么

第 4 章得到的 parse tree 忠实记录了解析过程：每调用一条语法规则就有一个内部节点，
每个记号都有一片叶子。它的优点是**无遗漏**，但把它交给分析算法会立刻遇到两类麻烦。

- **它太多**。一个简单的 `n > 0` 在 parse tree 里是
  `(expr (expr n) > (expr 0))`——三层节点只为表达一个比较，
  因为左递归的每个展开层都留下一个 `expr` 包装。括号、分号、花括号也全是叶子，
  而它们对程序"做什么"没有任何贡献，只服务于解析。
- **它太少**。判断"这是哪一种表达式"要靠检查节点里有哪些记号
  （有没有 `PLUS`、有没有 `STAR`），节点本身不直接声明自己的语义种类；
  分析代码若每处都这样检查，既冗长又容易漏。

一个自然的想法是"就地清洗 parse tree"，跳过包装层、按需查记号即可。
本书没有这样做，因为那会让每个分析各自重复同一份清洗逻辑，且分析代码
从此与 ANTLR 的生成结构死死绑在一起——文法生成方式一变，全部分析受影响。
单独建立一层 AST，相当于在"解析器的输出形状"与"分析算法的输入需求"之间
插入一个稳定的中间接口：前端与分析各自演化，互不牵连。这层接口的价值
在第 10 章以后会持续兑现。

本章在 parse tree 之上构造**抽象语法树（Abstract Syntax Tree，AST）**：
一个"每个语义构造恰好对应一个节点"的精简表示。AST 去掉括号、分号、优先级分层等
**语法噪音**，把运算的优先级直接体现为树的形状，
并让"节点的种类"成为一眼可知的类型。从本章起，
AST 接口冻结，名字解析、控制流图、类型系统、全部数据流分析都在它之上工作。

## 8.2 什么叫"抽象"：三个消失与一个保留

从 parse tree 到 AST，被抽象掉的东西可以具体列出。

1. **括号消失**。`(a + b) * c` 与 `a + b * c` 的区别不靠括号节点保留，
   而由树的**形状**保留：前者是 `Mul(Add(a,b), c)`，后者是 `Add(a, Mul(b,c))`。
   括号完成了它在解析期的使命后不再出现。
2. **记号与分号消失**。`;`、`{`、`}` 等只起分隔作用的记号没有对应节点；
   块就是一个含有语句序列的节点，序列的顺序本身就是结构。
3. **冗余的表达式包装消失**。一次比较就是一个节点，不再有三层 `expr`。
4. **lvalue 与 expr 的区分消失**。文法为了解析把赋值目标单列成 `lvalue`，
   但在 AST 里赋值目标就是一个普通表达式（只可能是变量、字段访问、解引用），
   赋值节点持有两个表达式指针。后续分析因此可以用同一套遍历处理"读取"和"写入"位置。

唯一被**保留**的是真正影响语义的东西：字面量的值、变量的名字、运算的种类、
子构造的顺序与嵌套。抽象的原则是——**凡解析后可由结构推出的记号，都不进 AST；
凡影响运行行为的，一个不丢。**

这里用的"抽象"一词，与第 21 章以后"抽象解释（abstract interpretation）"里的
抽象是同一个思想的两次运用，值得提前点破：两者都是**丢弃与当前目的无关的细节、
保留必须区分的信息**。本章的目的是语法处理，所以丢掉分号与括号、保留嵌套结构；
后面符号分析的目的是判断正负，所以丢掉具体数值、保留符号。差别只在"目的是什么"，
因而"哪些细节无关"也随之不同；判断抽象好坏的标准则始终一样——
被保留的信息必须足以回答目的提出的问题。本章是这个思想在语法层的第一次实践。

## 8.3 节点体系总览

本章 AST 的全部节点类型如下，与第 3 章 TIP 构造一一对应：12 种表达式、
7 种语句、函数与程序各一种。

| 类别 | 节点 | 持有的内容 |
|---|---|---|
| 表达式 | `IntLit` | 整数值 `v` |
| | `VarRef` | 变量名 `name` |
| | `InputE` | 无（表示 input） |
| | `Binop` | 运算符 `op`、左子树、右子树 |
| | `CallE` | 被调表达式、实参表达式序列 |
| | `Deref` | 被解引用表达式 |
| | `AddrOf` | 变量名（`&x`） |
| | `AllocE` | 初值表达式 |
| | `NullE` | 无 |
| | `RecLit` | （字段名，值表达式）序列 |
| | `FieldA` | 记录表达式、字段名 |
| 语句 | `AssignS` | 目标表达式、值表达式 |
| | `OutputS` | 表达式 |
| | `IfS` | 条件、then 语句、else 语句（可为空） |
| | `WhileS` | 条件、循环体 |
| | `BlockS` | 语句序列 |
| | `ReturnS` | 表达式 |
| 外层 | `FunDecl` | 名字、参数名表、局部变量名表、函数体、返回语句 |
| | `ProgramA` | 函数声明序列 |

`Binop` 的运算符只有六种可能，用枚举 `BOp { Add, Sub, Mul, Div, Gt, Eq }` 表示。
把运算种类收成枚举而不是分成六个子类，是因为六种运算的**形状完全相同**
（都有左右子树），区别只在语义；子类会让遍历代码重复六遍，枚举加一个字段则共用一份。
这是 AST 设计的一般取舍：**形状不同的构造分成不同节点，形状相同、语义不同的收成枚举字段。**

### 8.3.1 一条可操作的判据：新构造该建新节点吗

上面的取舍可以细化成一条日后能反复套用的判据。面对一种新构造，问两个问题：
它的子结构数量或类型是否与已有节点不同？消费者处理它时是否必须走不同路径？
两个问题中只要有一个答案为"是"，就应建立独立节点；都为"否"，则收成枚举字段。

用 TIP 自己的构造检验这条判据：

- `if` 与 `while` 看似都是"条件加语句"，但 `if` 有两个分支（其一可空）、
  `while` 只有一个循环体，且控制流边的连接方式完全不同——子结构与消费者路径
  都不同，故各自独立成节点。
- 六种二元运算子结构完全相同，消费者（类型约束、代码生成、打印）只在
  "运算符是什么"一处分叉，故收成 `BOp`。
- 取地址 `&x` 与解引用 `*E` 只有一个子项，看似形状相近，但 `&` 后只能跟
  名字、`*` 后是任意表达式，且指针分析对二者生成方向相反的约束，故各自独立。

判据的反面同样值得记住：**不要因为"语义不同"就急于拆节点**。
六种运算语义当然不同，但让节点携带一个枚举、把语义差异推迟到真正需要
分叉的消费者那里，树本身可以保持精简。AST 描述的是"程序由什么组成"，
语义解释是消费者的职责——这条边界守得越清楚，后续每个分析的规则数量越少。

## 8.4 表达式节点逐一说明

下面逐个说明 12 种表达式节点存在的理由与字段含义。

- `IntLit` 只持有一个 `int v`。它代表"程序文本里这个位置写死的数"，
  与变量、输入相对——后面常量分析要传播的"常量"最终就落到这类节点上。
- `VarRef` 持有名字字符串。它只是**引用**，不包含变量的声明信息；
  "这个名字指向谁"由第 10 章另行建立。AST 刻意不把名字解析提前做进来，
  保持"结构构造"与"语义分析"两层分离。
- `InputE` 没有任何字段。它代表第 3 章说的"任意整数来源"，
  是全书可靠性讨论的起点：抽象时它必须对应整个整数集合。
- `Binop` 持有 `op` 与两个子树。比较 `Gt/Eq` 也走这一个节点，
  因为比较在 TIP 里同样产出整数，运行形状与算术无异。
- `CallE` 的第一个字段是**被调表达式**而非函数名字符串——
  这是 TIP 一等函数特性在 AST 上的直接后果：`f(...)` 里的 `f` 本身是任意表达式。
  实参是表达式序列，顺序固定。
- `Deref` 持有被解引用的表达式，对应 `*E`。
- `AddrOf` 持有变量**名字**而不是任意表达式：TIP 文法规定 `&` 后只能跟标识符。
- `AllocE` 持有初值表达式：`alloc E` 造一个新单元并以 `E` 初始化。
- `NullE` 是空指针常量，无字段。
- `RecLit` 持有一组（字段名，值表达式）。字段按**文本顺序**保存为有序序列，
  打印时也按此顺序，保证输出确定；分析记录类型时再处理"字段集合"。
- `FieldA` 持有记录表达式与字段名，对应 `E.f`。

### 8.4.1 几个容易被追问的设计决定

**为什么节点里不保存行号？** 工业编译器普遍在 AST 上保留源位置以便报错，
本书刻意不保存：所有诊断在第 4 章的解析期可以拿到行列，
而后续分析引用程序点时使用第 11 章固定编号，行列号对分析计算本身没有贡献。
少一个字段，节点的构造与打印都更简单；这也再次体现"只放语义必需内容"的取舍。

**为什么字段、实参用有序序列而不是集合？** 实参位置决定含义（第一个参数不同于第二个），
必须有序；记录的字段虽然按名字区分、次序在语义上无关紧要，
但打印输出要求确定，按文本顺序保留序列最直接，"字段是否重复"交给第 17 章类型分析。
若这里提前做成集合，反而要引入排序规则并丢失源顺序信息。

**这里的"抽象"和第 20 章是同一回事吗？** 不是，注意区分两个层面：
本章是**语法层面的抽象**——丢弃不影响语义的具体文本形态，得到程序的规范结构，
不涉及近似，信息无损（凡影响运行的都保留了）；
第 20 章的抽象解释是**语义层面的抽象**——把无穷的运行状态映射到有限的近似域，
必然损失信息，需要专门论证可靠性。可以说本章准备的是"被抽象解释的对象"：
先有一棵干净的树，后面才谈得上对树所表示的运行做近似。

**AST 为什么仍然是树而不是图？** 语法嵌套天然是树：一个子构造只出现在一个位置，
没有"同一个节点被两处引用"的语法现象。变量的多次引用指向的是**名字**而非节点，
名字与声明的关联由第 10 章建立为附带的索引，不改变树的形状。
真正的图结构从第 11 章控制流图开始出现——控制流允许汇合与回流，树无法表达。
保持"语法是树、控制流是图"的分层，每一层分析处理的数据形状都与其问题匹配。

## 8.5 语句节点与外层节点

- `AssignS` 持有目标与值两个表达式。文法里的 lvalue 在构造时已被翻译成
  `VarRef`、`FieldA`、`Deref`（或外裹 `FieldA`），因此语句层不再需要 lvalue 类型。
- `OutputS` 持有要写出的表达式。
- `IfS` 持有条件、then、else；没有 else 时第三个指针为空。
  用"可空指针"而不是布尔标志，是因为 else 子句本身就是一棵子树，空指针直接表示缺席。
- `WhileS` 持有条件与循环体。循环是后续不动点理论存在的理由——
  信息沿循环回流，无法一遍算定。
- `BlockS` 持有语句序列，把花括号的范围表达为顺序。
- `ReturnS` 单独成节点，虽然文法保证它总在末尾；保留节点是为了让"返回"在
  遍历、CFG、数据流里都有统一的程序点位置。
- `FunDecl` 把名字、参数名表、局部变量名表、函数体、返回语句收在一起。
  参数与局部变量只存**名字**，再次体现类型无须声明。
- `ProgramA` 是根，持有全部函数。

## 8.6 树的所有权：unique_ptr 与稳定地址

AST 是一棵严格的树：每个节点有且只有一个拥有者，拥有关系用 `std::unique_ptr` 表达——
`ProgramA` 拥有函数，函数拥有语句，复合语句与表达式拥有各自的子节点。
这样整棵树随根对象构造、随根对象销毁，没有共享、没有手动释放。

构造过程因此是一路 `move`：parse tree 的上下文节点是 ANTLR 拥有的临时对象，
AST 节点一旦建好就通过 `unique_ptr` 移交给父节点。子树先构造、再移入父节点，
任何节点都不会有两个拥有者。

`unique_ptr` 还有一个对后续章节重要的性质：树构造完成后，**所有节点的地址保持稳定**——
此后只遍历、不增删节点。因此第 10 章的符号表可以直接存放 `const VarRef*` 作为使用点索引，
第 11 章可以让 CFG 节点持有 `const Stmt*`，这些裸指针不是拥有关系、
只是"指向那棵稳定 AST 中某个节点"的非空标识，安全且零成本。

### 8.6.1 "稳定地址"为什么值得专门论证

后续章节大量存放指向 AST 的裸指针，安全前提有两个，值得逐一确认，
而不是默认"反正对象还在"。

第一，**生命周期覆盖使用期**。所有分析对象（符号表、CFG、类型约束、格上的状态）
都在 AST 构建完成之后才创建，并在 AST 根对象仍然存活时使用；
它们不拥有 AST、也不试图延长其生命，只是在同一作用域内的只读引用。
根对象销毁时分析对象先销毁，顺序天然正确。

第二，**地址在使用期内不变**。对 `unique_ptr` 拥有的节点做移动操作只会改变
**指针本身**（哪个父节点拥有它），不会移动堆上的节点对象；
而树构建完成后不再有任何移动或增删。C++ 标准保证对象在其生命周期内地址不变，
因此存入的 `const Stmt*` 等始终指向同一节点，不存在"重定位使索引失效"的可能。

这两点合起来使裸指针成为零成本的节点标识。另一种常见做法是给节点编号
（整数 ID）再维护 ID 到节点的表——本书在第 11 章的程序点上确实用了编号，
因为那些点是新构造的、不属于 AST；但对 AST 自身的节点，
地址已是天然唯一标识，再加一层编号表纯属冗余。

## 8.7 为什么不使用 ANTLR 的 visitor 机制

ANTLR 为 C++ 目标生成了 visitor 基类与每个规则的 `accept` 方法，
按标签重写 visit 方法本是构造 AST 的常见路线。本书没有采用，原因在本工具链的运行时 API 上。

查看生成代码会看到 visitor 方法与 `accept` 都以 `std::any` 传值。
`std::any` 只能持有**可拷贝**类型——存入时要拷贝，取出时也可能拷贝；
而 `unique_ptr` 不可拷贝，无法作为 `std::any` 的内容向上返回。
（`std::any` 可以接受可拷贝的包装，但 unique_ptr 没有合法的拷贝路径。）
若硬走 visitor，只能改用 `shared_ptr`（引入引用计数开销与共享所有权）、
裸指针（退化为手工内存管理），或替换运行时的 Any 实现——都是为迁就机制而扭曲设计。

本书的选择是**直接在上下文节点上递归下降**：ANTLR 生成的上下文类
（`AddExprContext`、`IfStmtContext`……）已经提供了全部类型化的子节点访问器
（`expr(i)`、`stmt()`、`PLUS()`），信息并不需要 visitor 来转交。
自己写三个构造入口，用 `dynamic_cast` 识别上下文的真实子类，
得到的代码与"标签 → visit 方法"一一对应，且全程使用 `unique_ptr`，
语义最直接。这一取舍也写在 ast_build.hpp 的开头注释里。

### 8.7.1 放弃的另外几条路

决策时认真比较过四种替代，逐一说明放弃理由，比单纯说"我们不用 visitor"更有参考价值。

- **升级到带 move-only Any 的更新运行时**：上游较新版本的 C++ 目标重新引入了
  自定义 Any，可以承载只移类型。但本机工具链已经完整构建、验证，
  为一个语法糖更换运行时会牵动全部章节的构建，收益与成本不成比例。
- **以 `shared_ptr` 构造 AST**：能通过 std::any，但整棵树从此引用计数、
  节点可能被共享持有，"严格的树、唯一拥有者"这条简单不变量就丢失了；
  引用计数的运行时成本也无必要——树只需要一种所有权模型。
- **visitor 返回裸指针、手工管理**：把释放责任推给根节点列表可以工作，
  但等于绕开 C++ 的资源管理机制重新发明一套，任何漏注册都是泄漏。
- **在 visitor 外再包一层非 any 的分发**：形式上仍是 visitor、实际上只用到上下文节点，
  那不如直接递归下降，省掉 accept/any 的全部空转。

直接递归下降的代价只有一个：上下文子类的识别由我们手写的 `dynamic_cast` 链承担，
文法新增备选时要同步补分支。第 8.13 节的正确性讨论恰好把"分支是否穷尽"
变成显式检查项——这个代价可见、可控，而它换来的是最直接的所有权语义。

## 8.8 构建器的三个入口

`AstBuilder` 对外只暴露一个 `build`，内部沿程序结构分三层。

- `build(ProgramContext*)` 遍历 `tree->function()`，对每个函数上下文调用 `buildFun`，
  把得到的函数节点收集成 `ProgramA`。
- `buildFun(FunctionContext*)` 负责一个函数：从上下文取函数名记号，
  从 `params()`、`varDecls()` 取参数与局部变量名，对 `ctx->stmt()` 的每条语句
  调用 `buildStmt`，把语句序列包成一个 `BlockS` 作为函数体，
  最后把 `ctx->expr()` 经 `buildExpr` 包成 `ReturnS`。
- `buildExpr` 与 `buildStmt` 是真正的翻译核心，下两节详述。

自由函数 `buildAst(tree)` 只是一次性便捷入口：构造一个临时 `AstBuilder` 并调用 `build`。
main.cpp 就通过它把 parse tree 变成 AST。

## 8.9 buildExpr：14 路上下文分派

`buildExpr` 的输入是一个 `ExprContext*`。文法里 expr 有 14 个标签备选，
ANTLR 为每个备选生成独立子类；函数体因此是一连串 `dynamic_cast`，
每个分支返回对应 AST 节点。各分支的翻译规则如下。

- `IntExprContext`：读 `INT()` 记号文本，`std::stoi` 成整数，返回 `IntLit`。
- `VarExprContext`：读 `IDENT()` 文本，返回 `VarRef`。
- `InputExprContext`：直接返回 `InputE`。
- `NullExprContext`：返回 `NullE`。
- `ParenExprContext`：**不产生节点**，对内层 `expr()` 递归调用 `buildExpr` 并直接返回其结果。
  这是"括号消失"在代码里的落点——括号对子树形状的影响在解析期已经解决。
- `AddExprContext`：检查上下文中 `PLUS()` 是否存在，决定运算符是 `Add` 还是 `Sub`
  （备选文本是 `expr (PLUS|MINUS) expr`，两个记号恰好出现一个），
  对 `expr(0)`、`expr(1)` 分别递归，构造 `Binop`。
- `MulExprContext`：同理，看 `STAR()` 是否存在决定 `Mul` 或 `Div`。
- `CmpExprContext`：看 `GT()` 决定 `Gt` 或 `Eq`。
- `NegExprContext`：见 5.10，被翻译成减法节点。
- `CallExprContext`：对被调位置 `expr()` 递归；若有 `args()`，
  对其中每个 `expr()` 递归成实参序列，构造 `CallE`。
- `FieldExprContext`：对内层表达式递归，配上 `IDENT()` 字段名，构造 `FieldA`。
- `DerefExprContext`：对内层递归，构造 `Deref`。
- `AddrExprContext`：直接取 `IDENT()` 文本构造 `AddrOf`。
- `AllocExprContext`：对内层递归，构造 `AllocE`。
- `RecExprContext`：遍历每个 `field()`，字段名取 `IDENT()`、值递归构造，
  按文本顺序收集，构造 `RecLit`。

注意子表达式的递归顺序：各分支按"从左到右、先被调后实参"的固定顺序构造。
这不影响正确性，但当我们需要稳定的调试输出时，构造顺序即节点生成顺序，
确定性由此而来。函数末尾对解析成功的程序不可到达，保留返回 `nullptr` 只是为了通过编译器检查。

### 8.9.1 为什么靠 dynamic_cast 分派，而不是手写种类标签

读到这里自然会问：一连串 `dynamic_cast` 与"在节点里放一个 enum 再 switch"
看起来同样是分派，为什么这里选前者？关键在于分派发生的位置——
输入类型是 ANTLR 的**上下文**，不是我们自己的节点。上下文子类已经由生成器
按标签固定下来，`dynamic_cast` 只是在读取生成器已经给出的类型信息，
无需我们再维护一张"标签 → 种类"的对应表。若改成手写标签字符串比较，
等于在生成器的类型系统之外平行维护一份必然会漂移的副本。

这条链还有两个不显眼但重要的性质。其一，分支顺序与语义无关：
14 个上下文子类互斥（一个上下文对象的动态类型唯一），先 cast 谁都不影响结果，
所以顺序只按"先简单后复杂"的可读性排列。其二，漏分支是**静默**的：
新增文法备选而忘记补 cast 时，函数会落到末尾的 `nullptr`。
本书的应对不是记住别漏，而是让 pretty-printer 对所有示例程序产出
可逐行核对的完整输出——漏掉的分支立刻表现为打印缺失，
第 8.13 节的结构归纳清单则要求"备选集合 = 分支集合"作为显式检查项。

## 8.10 两个明确的语义选择

教材在两处留下了"由实现自行选择"的空间，本书在本章显式选定，后续章节都按此理解。

**负号**：TIP 没有负数字面量词法记号。`-E` 按文法是一元前缀备选，
本书把它翻译成 `Binop(Sub, IntLit(0), E)`，即 `-E ≡ 0 - E`。
这样做的好处是 AST 不再需要"一元减法"节点——语义节点种类更少，
而整数世界里 `0-E` 与取负完全等价。翻译只此一处，
后续所有分析天然覆盖负号，无须为它单独写规则。

**整数宽度**：本书用机器 `int` 承载 TIP 的任意精度整数，
因为全部教学程序都在小整数范围内；这一选择在第 3 章已声明，
正文讨论"任意整数"时实际指"程序中出现的整数"。

## 8.11 lvalue 的翻译与 FieldA 的包裹

赋值目标在文法里单独成规则，构造时由 `buildLvalue` 处理，它与 `buildExpr` 平行但更短。

- `DirectLvalueContext`：基础是 `VarRef(IDENT(0))`；
  若上下文有两个 `IDENT`（文法 `IDENT (DOT IDENT)?`），
  第二个就是字段名，记下来。
- `PointerLvalueContext`：对内层表达式递归，外裹 `Deref`；
  若该备选还带 `(DOT IDENT)?` 且 `IDENT()` 存在，同样记下字段名。

最后，若记下了字段名，就在基础表达式外再包一层 `FieldA`：
于是 `x.f = E` 的目标是 `FieldA(VarRef(x), f)`，
`(*p).f = E` 的目标是 `FieldA(Deref(...), f)`；没有字段则直接返回基础。
这个统一处理保证赋值语句看到的目标永远是 `Expr`，
"变量赋值 / 经指针写入 / 写字段"在节点层面没有特例。

## 8.12 buildStmt：五种语句与块

`buildStmt` 对 `StmtContext` 的五个带标签子类分派。

- `AssignStmtContext`：对 `lvalue()` 调 `buildLvalue`、对 `expr()` 调 `buildExpr`，
  构造 `AssignS`。
- `OutputStmtContext`：构造 `OutputS`。
- `IfStmtContext`：递归构造条件与第一个 `stmt`；上下文中若有两条 `stmt`，
  第二条递归为 else，否则 else 保持空指针，构造 `IfS`。
- `WhileStmtContext`：递归构造条件与唯一的 `stmt`，构造 `WhileS`。
- `BlockStmtContext`：对每个 `stmt()` 递归，收集成 `BlockS`。

注意嵌套块会得到嵌套的 `BlockS`——不做"压平"，因为块在后续作用域分析里
代表一个独立范围，压平会丢掉这层结构。语句的嵌套层次与源码完全对应。

## 8.13 正确性论证思路：翻译保结构

AST 构建是一条从 parse tree 到 AST 的纯函数（不修改输入、不依赖外部状态），
它的正确性可以按**结构归纳（structural induction）**论证，思路如下。

- 对每个上下文子类，规定其翻译结果：节点的种类由标签唯一确定，
  节点字段要么直接来自上下文记号（字面量文本、字段名），
  要么来自对子节点的递归翻译。
- 归纳假设：对所有更小的子上下文，递归翻译都正确反映对应子构造。
  那么当前分支把这些正确的子翻译按文法位置组装（左子树放左、实参按序、
  条件与分支各归其位），所得节点即正确反映当前构造。
- 括号分支不产生节点是安全的：括号对子树形状的全部作用已由解析器在
  "哪个表达式是哪个的子节点"中确定，递归返回内层翻译恰好保留了这一形状。
- 基础情形（字面量、变量、input、null）只做文本到字段的直接映射，显然成立。

由此每个语义构造都在 AST 中恰好出现一次、字段与子树位置正确——翻译保结构。
经验侧的旁证是 pretty-printer：它把 AST 重新打印，三个程序的输出中可以逐一数回
全部构造（见 8.16 节的解读）。需要说明的是，打印结果与原文文本并不逐字相同
（优先级已变成括号、写法变成前缀式），保的是**结构**而非字面排版。

### 8.13.1 论证、实现与输出三者如何分工

本章同时给出了三样东西：结构归纳式的论证思路、构建器实现、可对账的打印输出。
它们不是同一件事的三种说法，而是各管一段、互为犄角，值得说清分工。

- **论证**回答"对所有合法程序，翻译应当满足什么"。它覆盖的是无穷集合——
  TIP 程序有无穷多个，任何测试都只能触及其中有限个；归纳论证的价值正在于
  以"规则 + 子结构"的方式一次性覆盖全部备选组合。
- **实现**回答"论证里的规定在 C++ 中如何落地"。论证假设了"每个备选都有分支"，
  实现则可能因笔误漏掉一个 cast——论证约束实现，但不证明代码无笔误。
- **输出对账**回答"这份具体实现对这批具体程序是否兑现了规定"。
  它不能覆盖全部程序，但能抓住实现与规定之间的现实偏差，
  这正是纯论证够不到的地方。

静态分析本身的正确性也将反复沿用这三层分工：第 17 章起每个分析都有
形式化的规范（格与约束）、实现、以及经验检验（具体执行值落入预测集合）。
本章是这套方法论第一次小规模预演——先在"翻译"这种简单性质上练熟，
后面论证"可靠（soundness）"时结构完全同构，只是规范更复杂。

## 8.14 pretty-printer：AST 的第一个消费者

仅有 AST 的内存结构无法直接观察。pretty-printer 用一套**固定的前缀式语法**
把整棵树重新打印，它既是验证"AST 建对了没有"的手段，
也为之后各章提供"程序结构可视化"的通用工具。

### 8.14.1 表达式的打印约定

| 构造 | 打印形式 |
|---|---|
| 整数字面量、变量、input、null | 原样：`17`、`x`、`input`、`null` |
| 二元运算 | `(op 左 右)`，如 `(+ a b)`、`(> n 0)`、`(== x y)` |
| 函数调用 | `(call 被调 实参...)`，如 `(call f (call f x))` |
| 解引用 / 取地址 | `(* E)`、`(& x)` |
| 分配 / 字段访问 | `(alloc E)`、`(. E f)` |
| 记录 | `{f: E, g: E}` |

选择前缀式并给每个复合表达式加括号，是为了让打印文本**无须任何优先级知识**即可读出树：
最外层运算符总在括号内第一位，其余依次是子树。中缀式更接近源码，
但阅读者要自己结合优先级判断分组，前缀式则让结构一目了然——
这正符合"打印是为看见树"的目的。运算符符号通过 `BOp` 到字符的对照取得，六种一一对应。

### 8.14.2 语句的打印约定

- 每条语句独占一行，按嵌套层次每层缩进两个空格；
- 赋值：`目标 = 值 ;`，目标与值都按表达式约定打印；
- output：`output E ;`；return：`return E ;`；
- if：先打印 `if (条件)`，then 缩进一级；有 else 时在同层次打印 `else` 再打印子句；
- while：`while (条件)` 后缩进打印循环体；
- 块：`{` 起、内部语句缩进、`}` 收。

条件本身是复合表达式时会看到双括号，如 `while ((> n 0))`：
外层括号是语句格式里固定的 `while (...)`，内层是表达式自身的前缀括号，两层各有来源。

### 8.14.3 函数的打印约定

每个函数先打印 `名字(参数表) {`，参数表逗号分隔、无空格；
若有局部变量，打印一行 `var x,y ;`。函数体在文法里是一个 `BlockS`，
打印时刻意**解开这一层**——直接把体内语句按一级缩进列出，不再套一对花括号
（花括号已由函数自己的 `{ }` 承担）；然后是一级缩进的 return 与收尾 `}`。
这一约定让函数文本与 TIP 源码尽量接近，阅读成本最低。

### 8.14.4 这棵树将被谁消费：后续章节的接口预告

pretty-printer 只是 AST 的第一个消费者。本书其余 25 章中，几乎每一类分析
都以同一棵不可变 AST 为输入，但各自只取自己需要的部分；在此一次性预告，
读者可以看到"节点体系为什么恰好是这些"并非偶然。

- **作用域与符号表（第 10 章）**遍历 `BlockS` 的嵌套与函数边界，
  回答"一个 `VarRef` 引用的是哪个声明"；块节点不压平正是为此。
- **控制流图（第 11 章）**消费语句节点的后继关系，把 `IfS`/`WhileS`
  翻译成显式的分支边；树上的语句指针直接成为图节点的负载。
- **类型约束（第 17–20 章）**对每个表达式节点生成一条约束：
  `Binop` 两侧同型且结果为 int，`CallE` 的被调位置必须是函数类型，
  `Deref` 的内层必须是指针。节点种类决定约束形状。
- **数据流分析（第 25 章起）**在控制流图上传递格元素，
  赋值节点的左右子树决定"杀/生"集合与传递函数。
- **指针分析（第 44–45 章）**只看 `AllocE`、`AddrOf`、`AssignS`
  这几类节点——抽象位置的集合直接由 `alloc` 节点枚举。

每个分析都只读、不改，且互不干扰地共享这棵树。这正是第 8.6 节坚持
唯一所有权与稳定地址的回报：任何分析都可以长期保存指向某个 AST 节点的
指针作为索引键（"这个抽象位置来自第 3 个 alloc 节点"），
无须担心节点在分析期间移动或失效。接口至此冻结，后续工作全部是在它之上
添加新的消费者。

## 8.15 工程注意点

- **AST 一旦构建即视为不可变数据**：之后所有分析只在上面读取与索引，不修改节点；
  这条约束让"指针指向 AST 节点"可以放心使用，也让多个分析能共享同一棵树。
- **打印格式是输出契约的一部分**：空格、缩进、分号前的空格都被逐字节对账，
  改动打印代码必须同步更新 expected，二者由脚本强制一致。
- **不为"将来可能用到"增设节点**：没有一元减法节点、没有 else-if 节点、
  不存表达式类型——只放当前语义必需的字段，这是本章贯穿的 YAGNI 取舍。
- **翻译与打印分成独立文件**：ast_build.cpp 只负责构造，pretty.cpp 只负责观察，
  职责清晰后，第 10 章只需新增解析器而不碰这两处。

## 8.16 本章代码

### 文法（与第 4 章同一份，前端自此复用）

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

### main.cpp：解析并打印 AST

```cpp
// file: src/main.cpp
// 第 8 章配套程序：解析 TIP 源文件 -> AST -> pretty-printer 重新打印。
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "pretty.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    std::ifstream src(argv[2]);
    if (!src) {
        std::cerr << "cannot open " << argv[2] << '\n';
        return 1;
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
        return 2;
    }

    std::unique_ptr<tip::ProgramA> ast = tip::buildAst(tree);
    std::cout << tip::printProgram(*ast);
    return 0;
}
```

### ast.hpp：冻结的节点定义

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

### ast_build.hpp：构建器接口

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

### ast_build.cpp：递归下降翻译

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

### pretty.hpp：打印接口

```cpp
// file: src/pretty.hpp
// Pretty-printer：把 AST 以固定的前缀式语法重新打印出来。
// 它是 AST 的第一个消费者，也为后续各章提供"程序结构可视化"的通用工具。
#pragma once

#include <string>

#include "ast.hpp"

namespace tip {

std::string printProgram(const ProgramA &program);

}  // namespace tip
```

### pretty.cpp：前缀式打印实现

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

}  // namespace tip
```

## 8.17 真实输出

### 三个程序的 AST 打印

```text
; expected: expected/output.txt
== ite.tip ==
ite(n) {
  var f ;
  f = 1 ;
  while ((> n 0))
    {
      f = (* f n) ;
      n = (- n 1) ;
    }
  return f ;
}
== rec.tip ==
main() {
  var x,y ;
  x = {f: 1, g: 2} ;
  y = (. x f) ;
  return y ;
}
== twice.tip ==
twice(f,x) {
  return (call f (call f x)) ;
}
inc(y) {
  return (+ y 1) ;
}
main(z) {
  return (call twice inc z) ;
}
```

### 语法错误（由第 4 章前端检测，退出码 2）

```text
; expected: expected/errors/badsyntax.txt
syntax error line 2:13 mismatched input ';' expecting {'input', 'alloc', 'null', IDENT, INT, '-', '*', '&', '(', '{'}
```

## 8.18 输出解读：把树读回去

对照 8.14 节的约定，可以从输出里把三个程序的树完整读回。

`ite` 的输出中，`while ((> n 0))` 说明条件节点是 `Binop(Gt, VarRef(n), IntLit(0))`；
循环体块内 `f = (* f n)` 是 `AssignS(VarRef(f), Binop(Mul, f, n))`，
`n = (- n 1)` 对应递减——循环的"回流"在文本上表现为这两条语句位于 while 之下。
`rec` 中 `{f: 1, g: 2}` 与 `(. x f)` 让记录构造和字段访问各出现一次，
字段顺序与源码一致。`twice` 的 `(call f (call f x))` 精确显示嵌套调用：
内层先以 `x` 调 `f`，外层再以其结果调 `f`；
`main` 里 `(call twice inc z)` 的被调与第一个实参分别是 `VarRef(twice)`、`VarRef(inc)`——
函数在这里作为名字引用出现，但"inc 是函数值"要到第 44 章才由分析推出。
三个程序中没有出现括号节点或分号叶子，抽象的取舍在输出里可以直接核对。

## 8.19 小结

本章把臃肿的 parse tree 提炼成抽象语法树：括号、分号、冗余包装全部消失，
优先级变成树的形状，lvalue 回归为普通表达式；节点按"形状不同则分类、
语义不同则加枚举字段"的原则设计，整棵树由 `unique_ptr` 严格拥有、
构建后地址稳定。构建器以直接递归下降代替 std::any 传值的 visitor，
其保结构正确性可用结构归纳论证；pretty-printer 以无歧义的前缀式语法
让整棵树成为可见、可逐字节对账的文本。

回顾本篇前三章，读者已经走完静态分析全部前置工作的完整链条：第 3 章确定了
被分析的语言，第 4 章把程序文本变成忠实但臃肿的 parse tree，本章则把它
提炼成分析算法真正的工作平面。三个阶段层层收窄——字符、记号、结构——
每一层只解决自己那一级的问题，且一经冻结便不再回头修改。这种分层不是
形式洁癖：类型分析、数据流分析、指针分析将面对完全相同的前端，
前置工作只做一次，后面 25 章都在复用。

本章还预演了贯穿全书的方法论。节点设计遵循"形状决定分类"的判据，
本质上是在为后续每一类分析减少需要分别处理的情形；构建器的正确性以
结构归纳论证、以确定性输出对账，论证与经验检验各管一段。第 17 章起，
当性质从"翻译保结构"换成"分析结果可靠"时，读者会看到同样的骨架：
形式化规范、实现、以及具体执行值落入预测集合的经验检验。工具会变，
论证的结构不变。

下一章在这棵稳定的树上做第一件语义工作：**名字解析**——
回答每个 `VarRef` 指向函数、参数还是局部变量，并把未声明、重复声明诊断出来。
