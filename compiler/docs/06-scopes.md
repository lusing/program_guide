# 第 06 章　名字与作用域：把变量使用绑定到声明

## 6.1 AST 上的名字还"没有着落"

第 05 章得到的 AST 已经是干净的程序结构，但其中代表变量使用的 `VarRef`
节点只持有一个字符串字段 `name`。字符串本身不是程序实体：同一个名字
`x` 完全可能在不同函数里各声明一次，它们是两个互不相干的变量；
一个名字可能指函数、参数或局部变量；写在文本前面的函数甚至可以调用
文本后面才出现的函数。仅凭字符串，谁也回答不了"这个使用点到底在读谁、写谁"。

本章在 AST 之上做第一件**语义**工作——**名字解析（name resolution）**：
为 AST 上每一个变量使用点找到它所引用的那个声明，并把"未声明""重复声明"
两类违规诊断出来。第 03–05 章的工作属于语法层：把文本变成结构；
从本章起进入语义层：解释结构中名字的意义。

值得先指出的是，名字解析与第 02 章讨论的不可判定问题性质完全不同。
作用域规则有限、程序有限，每个使用点的答案唯一存在且可被机械算出——
它是在**整理程序里已经确定的事实**，不需要近似，也不存在可靠性与精度的
取舍。真正需要近似的是后面章节对"程序运行时会发生什么"的预测；
本章的产出（使用点 → 声明的绑定表）正是那些预测赖以工作的底座。

以本章的示例程序 `good.tip` 为例，可以提前看到要处理的全部情形：

```
main() {
  var x;
  x = helper(3);
  return x;
}
helper(n) {
  return n+1;
}
```

`main` 中三个使用点：两个 `x` 必须绑定到局部变量，`helper` 必须绑定到
**后面才定义**的函数名；`helper` 中的 `n` 绑定到参数。前向引用、
函数名、参数、局部变量四件事，一个程序里全有了。

这里也划清"语法正确"与"语义正确"的界限。第 04 章文法只检查形状：
`x + z` 形状合法，即使 `z` 从未声明，解析器也不会有任何异议——文法
无法、也不应该知道哪些名字存在。名字是否存在、引用是否合法，是形状
之上关于**意义**的事实，属于语义层。两层违规的表现也不同：语法错误
让程序连 AST 都构建不出；语义错误的程序有完整结构，只是其中某些使用
点找不到合法归属。本章处理后者时，AST 已经在手，这也是先过语法、
再谈语义的工程顺序的根源。

还要澄清一个常见误解：名字解析有时被说成"把变量替换成地址"。在本章
的设计中它**不做**这件事——绑定表只把使用点映射到声明实体（一个
`Symbol`），不给地址，也不决定存储布局。声明实体在栈上还是堆上、
活多久，是代码生成（第 08 章）与运行时的职责。把"名字指谁"与
"数据在哪里"分开，同一作用域规则才能同时服务于类型检查、代码生成
等不同消费者；它们对"之后怎么办"回答各异，对"指谁"的回答一致。

## 6.2 词法作用域：定义时就确定的归属

回答"名字指谁"有两种根本不同的规则，先建立直觉。

**词法作用域（lexical scoping）**，又称静态作用域：一个名字的归属在
**读程序文本时**就能确定，依据是声明与使用在文本嵌套结构上的位置，
与程序怎样被调用、被谁调用无关。**动态作用域（dynamic scoping）**则把
答案推迟到运行时：名字沿当前的**调用栈**向下查找，同一段代码在不同
调用历史下可能指向不同的声明。用一个最小例子说明差别：

```
f() { return x; }
g() { var x; x = 1; return f(); }
h() { var x; x = 2; return f(); }
```

动态作用域下，`g()` 里的 `f` 看到 `g` 的 `x`（得 1），`h()` 里的 `f`
看到 `h` 的 `x`（得 2）；词法作用域下，`f` 文本上没有 `x` 的声明，
引用全局 `x`——无论被谁调用，答案只有一个。注意这个例子不是合法的
TIP 程序（`f` 中使用了未声明的 `x`），仅用于对照两种规则。

主流语言几乎一致选择词法作用域，理由是原则性的，不只是习惯：

- **可局部推理**：读懂一个函数不需要知道它可能被谁、以什么顺序调用，
  名字的意义封闭在文本结构内；动态作用域下，任何函数的行为都依赖
  全局调用历史，模块化推理无从谈起。
- **可静态确定**：归属在编译期是确定事实，工具可以据此做重命名、
  跳转、类型检查而无须运行程序。
- **一等函数与闭包的基础**：当函数可以作为值传递（第 03 章的
  `twice(inc, x)`），函数离开它被定义的文本位置后仍须记住自己的
  名字环境——这只有词法规则能自洽地给出。

TIP 采用词法作用域，其规则可以完整陈述为三条：

1. 所有**函数名**在唯一的全局作用域中声明，彼此可见，且支持前向引用；
2. 每个函数的**参数**与用 `var` 声明的**局部变量**在该函数自己的作用域中声明；
3. 函数作用域中找不到名字时，到全局作用域继续找；再找不到即为未声明。

TIP 有一个简化：函数声明**不能嵌套**，所有函数平级。因此 TIP 程序的
作用域嵌套实际上只有两层。但下面会看到，实现并不硬编码层数，而是用
通用的"父作用域指针"表达——规则的陈述与数据结构都按一般的词法作用域
书写，两层只是该语言的一个具体形状。

这段历史值得一提：最早的 LISP 实现采用动态作用域——很大程度上是当时
实现技术的偶然（名字沿运行栈查找最容易实现），而非深思熟虑的设计。
Scheme 及其后的语言明确转向词法作用域，并因此需要真正支持闭包
（函数离开定义处仍携带着自己的环境）。理解这段历史有助于避免把
"动态作用域灵活"误读为优点：灵活性的代价是名字意义随调用历史漂移，
而大型程序恰恰最依赖"名字的意义不变"。

当内层作用域声明了与外层相同的名字时，内层的绑定**遮蔽（shadowing）**
外层：查找停在最近的声明处。遮蔽不是额外规定，而是"由内向外、取第一处
命中"这条查找规则的直接推论，6.3 节将把它形式化。

### 6.2.1 约束出现与自由出现

用更形式化的语言重述词法作用域，需要区分名字的两种**出现**：

- **约束出现（binding occurrence）**：声明名字的位置——函数定义处的
  函数名、参数表中的参数、`var` 声明中的变量。一个约束出现为它的
  **作用域**（该声明有效的文本范围）引入一个绑定实体。
- **使用出现（applied/use occurrence）**：表达式中读取或语句中写入
  名字的位置，即 AST 上的 `VarRef`。使用出现本身不引入绑定，它必须
  被某个约束出现**约束**。

若一个使用出现在所有嵌套作用域中都找不到约束它的声明，就称它是
**自由的（free）**——TIP 中这是错误（`undeclared`）。一个程序
**闭（closed）**，当其中没有自由出现：本章每个合法 TIP 程序都是闭的，
因为函数名全局可见、参数与局部变量在函数内可见，没有程序外的依赖。

这套词汇不是多余的术语，它让"绑定正确"有了精确的陈述对象：名字
解析就是为每个使用出现找到唯一约束它的约束出现。它还与一个重要概念
相连——**α 等价**：把一个声明及其作用域内的所有使用点一致改名
（如把 `var x` 及其使用全部改成 `var t`），程序的意义完全不变。
α 等价说明：名字字符串只是**表面语法**，真正的实体是"声明 + 被它
约束的那些使用"这一绑定结构。本章绑定表把这个结构显式建立出来；
字符串相同而声明不同，是两个实体——α 等价的观点与此完全一致。

### 6.2.2 为什么"自由/约束"在后续分析中重要

自由出现与约束出现这套区分，在 TIP 中似乎只用来报未声明，但它是
后续若干分析的基础设施，值得提前看到它的去向。

其一，计算一个函数体的**自由变量集合**，是许多分析的第一步。
规则完全机械：约束出现把名字加入局部环境，使用出现查询环境、
未命中即为自由。TIP 函数没有嵌套，函数体能"自由引用"到的主要
是全局函数名；但在第 27 章引入一等函数值后，一个函数值可能逃逸
出定义它的文本范围，此时它引用了哪些外部名字，直接决定它需要
捕获什么——闭包转换要为每个自由出现安排存储与传递。本章的
绑定关系是"捕获分析"的依据。

其二，过程间分析需要知道调用边界上**流动**的是什么。函数的参数
和返回值是显式边界，自由变量（对外层名字的依赖）则是隐式边界。
在没有嵌套函数的 TIP 里隐式边界为空，分析因此简洁；理解这一点，
才能理解 spa.pdf 在处理高阶特性时为何要引入 0-CFA：当函数可以
作为值传递，"一个调用点到底约束到哪个函数声明"不再是本章式的
简单查找，而要靠控制流分析近似——那时"使用出现约束到哪个约束
出现"从可精确求解的问题变成需要抽象解释的问题。

其三，α 等价所表达的"绑定结构才是实体、名字只是表面"这一观点，
贯穿本书所有以声明为节点的分析：类型变量、数据流事实的归属、
指针分析中的位置（location），最终都挂在声明实体而非字符串上。
本章是这条主线的起点。

## 6.3 形式化：作用域是一棵带父指针的树

把直觉变成可以论证的规则。先明确**绑定实体**：每次声明（函数定义、
参数、`var` 变量）都引入一个独立实体，即使两个实体名字相同也是两个。
名字解析的任务，就是把每个使用点映射到唯一一个这样的实体（或判定为
不存在）。

一个**作用域**包含两部分：一张名字表与一个父作用域指针：

- `table`：名字到符号的有限映射，同一个作用域内名字至多出现一次；
- `parent`：外层作用域；根作用域的 `parent` 为空。

名字查找是作用域上的递归函数。记作用域 `S`、名字 `z`：

```
lookup(S, z) =
    若 z ∈ S.table :  S.table[z]
    否则若 S.parent 存在 :  lookup(S.parent, z)
    否则 :  ⊥（未声明）
```

三条 TIP 规则在此精确对应到作用域树的构造方式：

- 全局作用域 `G` 是根，`parent` 为空，函数名全部进入 `G.table`；
- 每个函数 `f` 有自己的作用域 `S_f`，`S_f.parent = G`；
  参数与 `var` 声明进入 `S_f.table`。

于是"静态最近声明原则"可以一句话概括：**使用点绑定到从它所在作用域
出发、沿父链向上找到的第一个同名声明**；遮蔽是该原则在"内外层同名"
情形下的名字——最近的声明遮蔽更远的同名声明。

作用域之间的父指针构成一棵**树**：每个非根作用域有唯一父节点，没有环。
这与第 05 章 AST 是树、第 07 章 CFG 可以是环形成有趣对照——词法嵌套
天然无环（一个作用域不可能外层于自己），控制流则可以回到原点（循环）。
名字解析简单，根源就在这棵树的无环性：沿父链的查找必然终止。

对 `good.tip`，作用域树的具体形状是：

```
G = { main, helper }
├── S_main = { x }
└── S_helper = { n }
```

`S_main` 中使用的 `helper` 在本表未命中、沿父链在 `G` 命中；
`S_helper` 中的 `n` 在本表直接命中。每个使用点的答案都能在这棵树上
沿一条确定路径找到。

### 6.3.1 作用域（scope）不是生存期（extent）

形式化作用域后，必须立刻区分两个极易混淆的概念：

- **作用域**回答**文本**问题：一个声明的名字在程序哪一段文本范围内
  可见、一个使用点由哪个声明约束。它完全由程序文本决定，是本章
  静态可算的事实。
- **生存期（extent/lifetime）**回答**时间**问题：一个声明对应的
  **存储**在运行期的哪段时间内有效、何时分配与回收。

两者的答案可以不同，递归调用是最直观的例子：阶乘 `ite(n)` 中参数
`n` 的作用域是整个函数体——唯一的声明、文本上唯一的绑定；但运行时
`ite(5)` 递归调用 `ite(4)`，两次激活各自需要一份独立的 `n` 的存储，
内层返回后外层的 `n` 必须完好。**一个声明，多份同时存在的存储**：
作用域是文本上的一个，生存期则随每次激活开始、结束。本章只建立
作用域与绑定，完全不涉及"几份存储、何时回收"——那是运行时语义与
代码生成的职责，第 08 章在函数入口为每个声明生成 alloca、由栈帧
管理生存期，正是对这一区分的落地。

把这两件事分清还能避免一类常见的错误论断："名字解析算出了变量
地址"。它没有——绑定是使用点到**声明**的静态关系，地址是某次
激活中某份存储的动态位置。同一个静态声明在递归下对应多个地址，
任何"绑定 = 地址"的说法都会在此崩溃。

### 6.3.2 遮蔽的一次完整走查

TIP 的声明点只有三层（全局函数、参数、函数级 `var`），参数和 `var`
同居一个函数作用域，所以最有教学价值的遮蔽发生在局部名与函数名
之间。考虑：

```
foo(x) { return x + 1; }
main() {
  var foo;
  foo = 3;
  return foo;
}
```

这是**合法 TIP**：名字解析不禁止局部变量与函数同名。逐步看查找：

1. 第一遍后全局表为 `G = { foo(函数), main }`；
2. 处理 `main` 时建立 `S_main`，`var foo` 在本表插入一个**局部**
   符号，也叫 foo。注意这不是"重声明"——重声明只禁止在**同一张
   表**里同名两次；`S_main.foo` 与 `G.foo` 是不同表中的不同实体；
3. 解析 `foo = 3` 的使用点时，lookup 从 `S_main` 出发：本表立即
   命中局部 foo，查找停止，**根本不会走到 G**。外层的函数 foo 在
   这个函数体内变得不可达——不是不存在，而是被同名的内层实体
   遮住了；
4. `return foo` 同理命中局部。两个使用点都绑定到同一个局部符号，
   与全局的函数实体没有任何关系。

这个例子澄清三件事。第一，遮蔽是查找规则的**推论**而非额外特性：
"本表优先、找不到才看父表"一旦确定，遮蔽自动发生，无需专门代码
判断"是否与外层同名"。第二，遮蔽不删除任何东西：函数 foo 在
`main` 之外照常可见、可调用；受影响的只是文本上位于 `S_main`
内部的使用点。第三，被遮蔽的名字**无法在该作用域内被点名访问**——
TIP 没有提供"绕过内层、直达外层同名实体"的限定语法（许多语言用
模块限定或 `extern` 提供这种逃生口）。

遮蔽会给后续分析留下一个耐人寻味的局面：在 `main` 内无法再调用
函数 foo，因为任何形如 `foo(...)` 的使用，其函数位置的 foo 都
绑定到那个整数局部变量。名字解析本身不会报错——绑定完全合法；
是第 09 章的类型分析在统一约束时发现"被调用者必须是函数"与
"该符号是整型变量"冲突，才把问题判为类型错误。这精确展示了
各阶段的分工：名字解析回答"指谁"，类型分析回答"这样用对不对"。

## 6.4 为什么一遍不够：前向引用与两遍算法

形式化清楚后，算法问题随之而来：按什么顺序构造这棵树？

一个朴素的想法是按文本顺序处理一遍：读到函数就注册名字，随后立即解析
函数体。这在 `good.tip` 上立刻失败——`main` 写在前面，它的函数体里
使用了文本上尚不存在的 `helper`；此时全局表为空，一个合法程序会被
误报为未声明。调换两个函数的书写顺序虽能绕过本例，却要求程序员按
依赖关系排列函数，与"前向引用合法"的语言设计相矛盾；相互递归
（`f` 调 `g`、`g` 调 `f`）更是任何顺序都无法在一遍内解决。

正解是把"注册名字"与"解析使用"拆成**两遍**：

1. **第一遍**遍历全部函数声明，只把函数名注册进全局作用域，不碰函数体；
2. **第二遍**逐函数建立函数作用域（此时全局表已完整），声明参数与
   局部变量，再遍历函数体做绑定。

两遍是处理前向引用的通用模式，并非名字解析独有：链接器对目标文件
先收集符号表再解析重定位、许多语言的类型检查先收集定义再检查函数体，
结构完全同构——凡是"实体之间允许任意顺序互相引用"，就先让所有实体
存在，再解释引用。

相互递归比简单的前向引用更能说明两遍（而非排序）的必要性。考虑
（合法 TIP）：

```
even(n) { if (n == 0) return 1; else return odd(n - 1); }
odd(n)  { if (n == 0) return 0; else return even(n - 1); }
main()  { return even(input); }
```

`even` 引用 `odd`、`odd` 又引用 `even`：无论函数按什么顺序排列，
一遍式"见到再注册"的算法在处理第一个函数体时都必然找不到另一个。
两遍算法对此毫无困难——第一遍结束后 `{even, odd, main}` 全部在
全局表中，第二遍解析任何函数体时所有引用都能命中。这个例子也说明
依赖关系本身可以成**环**（even ↔ odd），但名字解析仍然终止：因为
成环的是"函数体引用函数名"，两遍把它切断在第一遍；查找沿父链
（作用域树，无环）进行，环不会进入查找过程。

为什么两遍恰好足够、不需要三遍？因为依赖只存在一个方向：函数体可以
引用任意函数名，而函数名的注册不依赖函数体的任何信息；TIP 又没有
嵌套函数，函数作用域之间互不依赖。第一遍结束后，第二遍所需的全部
外部信息（全局函数表）已一次到位，没有遗留的前向依赖。

### 6.4.1 横向对照：真实语言如何安排"先声明还是先用"

把 TIP 的做法放到真实语言的谱系中，"两遍"背后的原理会更清楚。

C/C++ 把两遍的负担部分交给程序员：函数需要先**声明**（原型）才能
调用，编译器在单个翻译单元内仍是"先收集声明、再检查使用"，只是
声明可能由人用头文件提前给出。这恰好说明"注册"与"解析"分离是
本质需要——手写原型无非是人替编译器完成了第一遍。

Java 与 C# 不要求前向声明：同一类型内的方法可任意顺序互相调用，
因为语言规范直接规定实现分若干遍（或等价地，先建立符号再解析
方法体）。这正是 TIP 的做法——"前向引用合法"由编译器的多遍
结构兑现，而不是靠书写顺序。

JavaScript 的 `var` 与 `let` 展示了同一区分的微妙后果：`var`
声明会被"提升"（hoisting）到作用域顶部，名字在声明语句之前
即可见（值为 undefined）；`let` 则在声明之前处于"暂时性死区"，
可见但不可用。两者都体现"声明的可见性"与"初始化的时间"是
两件可以分开规定的事——这与 6.3.1 节作用域/生存期的区分同构：
名字在文本上归属谁，与它在何时拥有可用的值，是两个层面。

Pascal 曾严格要求先声明后使用，于是用专门的 `forward` 声明解决
相互递归——又是一个由人补做的"第一遍"。把这些例子并排看，结论
只有一个：只要允许实体间任意顺序互相引用，"先让实体存在、再
解释引用"就是绕不开的结构；区别仅在于这第一遍由编译器自动完成，
还是通过前向声明机制部分外化给程序员。

## 6.5 数据结构：Symbol、Scope 与 Bindings

本节逐一说明数据结构，它们是上述规则的直接落地，全部声明在
`symtab.hpp` 中。

**符号 `Symbol`** 描述一个绑定实体，有三个字段：

- `kind`：实体种类，取值为 `Fun`（函数）、`Param`（参数）、
  `Local`（`var` 局部变量）三种之一；
- `name`：实体的名字；
- `fun`：一个 `FunDecl*`，含义随种类而定——对 `Fun` 符号指向该函数
  自己的声明；对 `Param`/`Local` 符号指向它所属的函数声明。

`fun` 字段让一个绑定同时携带"它生活在哪个函数里"这一信息，打印
`in helper` 这样的归属、以及后续章节按函数索引局部变量时都要用。

**作用域 `Scope`** 与形式化一一对应：`parent` 是父作用域指针，
`table` 是 `std::map<std::string, Symbol>`，并提供成员函数 `lookup`
实现 6.3 节的递归查找。用 `map` 而非 `unordered_map`，是因为本章一切
输出都要求确定顺序；名字表的遍历顺序在后续章节若被用到，同样稳定。

**解析结果 `Bindings`** 汇总一次解析的全部产出，四个字段各有职责：

- `global`：全局作用域本身（直接作为成员持有，函数名住在里面）；
- `scopes`：各函数作用域的 **`unique_ptr` 向量**——作用域的所有权由
  `Bindings` 持有，这一点是关键设计，下面专门解释；
- `errors`：收集到的全部诊断；
- `uses`：`const VarRef*` 到 `const Symbol*` 的映射，即绑定表本身。

`uses` 的键选作 `VarRef*`，直接兑现了第 05 章"AST 节点构建后地址
稳定"的论证：任何分析都可以把 AST 节点指针当作索引键长期保存，
无须再引入编号层。第 08 章生成 IR 时，将沿这张表从变量使用点找到
它的符号、再找到对应的栈槽。

为什么函数作用域必须由 `Bindings` 用 `unique_ptr` 持有、而不能是
解析过程中的局部变量？解析在第二遍逐函数进行：若作用域是循环体内的
局部对象，离开该次迭代后存储即被回收，而 `uses` 表中保存的
`Symbol*` 指向作用域内部的 `table`——指针立刻悬垂。把每个作用域
`make_unique` 出来、在结束时移入 `Bindings.scopes`，则所有符号与
解析结果同寿：只要 `Bindings` 存活，`uses` 中的指针就有效。

`errors` 与 `uses` 可以同时非空：解析不因一个错误而中止，结果中
既有成功绑定也有诊断。调用方据此既能报告全部问题，又能对正确的
部分继续工作（本章的命令行在有任何错误时退出，但数据结构本身支持
"部分成功"，这为工业工具在错误状态下仍提供分析留有余地）。

### 6.5.1 另一条路：无名表示与 De Bruijn 索引

本章用"名字字符串 + 父链查找"的**有名表示**，因为它与程序员的
文本直觉一致、输出可读、且 AST 已保留名字。形式化领域还存在一条
著名的替代路线——**无名表示（nameless representation）**：变量
不携带名字，而用一个整数指出"绑定我的声明在当前作用域栈向上数第几
层"，即 **De Bruijn 索引**。例如 λ. λ. 1（内层变量引用外层绑定）。
无名表示的最大优点是 α 等价变成**句法相等**：一致改名后的程序表示
完全相同，省去一切名字生成与碰撞处理；证明助手内核（处理带绑定的
项时）广泛采用它。

本书不选它，理由同样是原则性的：其一，TIP 是供人阅读和书写的语言，
源程序带名字；解析后立刻抹去名字会让所有面向用户的输出（诊断、
打印、类型报告）需要重新恢复名字，复杂度从前端转移到每个消费者。
其二，本章绑定只需"使用点 → 声明"一张表，De Bruijn 解决的
α 等价与绑定碰撞问题在扁平的 TIP 中几乎不出现（没有嵌套函数、
没有高阶绑定结构），用它属于过度装备。其三，第 09 章起的分析要
向程序员解释"这个变量的类型是什么"，名字是解释的天然载体。

认识这条路的价值在于理解本章设计的**边界**：当被处理语言出现
复杂的嵌套绑定（λ 抽象、模式中的绑定、量词公式），名字管理与
α 等价会成为真正的成本，那时无名表示（或局部作用域分析与显式
替换）就值得认真考虑。TIP 没有跨过这条边界，有名表示因此是
最简单的充分方案。

### 6.5.2 为什么函数名单独占一层

TIP 把所有函数名放在唯一一个全局作用域，而不是让每个函数各管
各的、或把被调函数也登记进调用者的作用域。这个选择值得追问，
因为它决定了名字解析的整个形状，且在 spa.pdf 的 TIP 设计中是
刻意的。

理由首先来自语言设计本身。TIP 函数在**顶层**声明、互不嵌套，
文本顺序任意；一个函数可以调用程序中的任何其他函数（包括写在
它后面的、以及与它互相递归的）。"任何函数可引用任何函数"正是
一个全局命名空间的语义：可见性与"谁在谁里面"无关。若按函数
切分命名空间，就必须额外规定"哪些函数对调用者可见"并处理
前向可见性——用更复杂的机制去重新实现全局空间本来免费给出的
行为。

其次，两层结构（全局函数层 + 每函数局部层）与 TIP 的**绑定种类**
恰好对应：一个使用点绑定到的实体，要么是函数、要么是参数或局部
变量，没有别的可能。作用域树因此恒为"深度 2 的树"（根 + 函数
作用域），lookup 至多跨一次父指针。第 09 章的类型规则直接依赖
这种简单性：函数名承载函数类型，其余承载整型/指针等，种类在
注册时已确定。

把函数名集中也使**两遍算法**成为可能：第一遍只扫顶层一遍就能
收齐全部函数名，因为它们恰好在同一层。若函数可以嵌套，内层
函数名的注册就依赖外层作用域的建立，需要与函数体解析交错进行，
遍的结构会复杂得多。扁平的全局层是"先收集、再解析"得以干净
实施的前提。

当然，这一设计也明确让出了某些能力：TIP 没有信息隐藏（任何
函数都能点名任何函数）、没有同名的两个函数（全局表内重声明即
非法）、也没有函数局部的函数。这些是 TIP 作为教学语言有意
接受的简化；第 27 章处理一等函数值时我们会看到，函数可以作为
*值*在局部流转——那是另一套机制（绑定到值与闭包），并不需要
改动这里的全局命名空间。

## 6.6 算法实现：resolveNames

`resolveNames` 的实现位于 `symtab.cpp`。具体工作交给一个内部结构
`Resolver`：它持有正在积累的 `Bindings`、记录当前作用域 `current`
与当前所属函数 `owner`，并提供声明与遍历操作。

**声明操作 `declare`** 在当前作用域登记一个名字。它先检查名字是否
已存在于本表：已存在则产生一条 `redeclared` 诊断并**直接返回**——
后声明者被忽略，先声明者保留；不存在则用 `emplace` 写入，符号的
`fun` 字段统一取当前的 `owner`。诊断策略的理由在 6.7 节展开。

**表达式遍历 `resolveExpr`** 按表达式节点的具体种类分派。处理一个
节点前必须想清楚：这个节点是否自身构成变量使用？它有哪些需要继续
深入的子表达式？各分支如下：

- `VarRef`：这是唯一真正的"变量使用"节点。在当前作用域 `lookup`
  它的名字；命中则把 `(节点指针, 符号指针)` 写入 `uses`，未命中则
  产生 `undeclared` 诊断。两种情况下都不需要再深入（它没有子节点）。
- `Binop`：自身不产生绑定，对左右子表达式分别递归。
- `CallE`：被调表达式自身就是一个使用（`helper(3)` 中的 `helper`
  通过对 callee 递归而绑定），再逐个递归实参。这正体现了 TIP 的
  一等函数设计：被调位置是任意表达式，名字解析与它"是不是函数"
  无关，一律按普通使用处理；它究竟绑定到函数还是变量，由查找结果
  客观给出。
- `Deref`、`AllocE`：自身不含名字，对内部子表达式递归。
- `FieldA`：字段名是记录的标签、不是变量，不参与解析；只对记录
  子表达式递归。
- `RecLit`：逐个字段对其值表达式递归，字段名同样忽略。
- `IntLit`、`InputE`、`NullE`：既无名字也无子表达式，没有动作。

这里有一个必须如实说明的简化：`AddrOf`（`&x`）节点中的 `x`
**语义上当然引用一个声明**，但本章实现没有为它生成绑定——它落入
末尾的"无变量使用"注释。原因是本章的命令行与后续第 08 章 IR 生成
只覆盖整数核心，不处理指针；`&x` 的绑定在第 27 章指针分析扩展
前端时补全。数据结构对此毫无障碍，只是当前遍历少一个分支。读者若
自行扩展，这是第一个该补上的位置。

**语句遍历 `resolveStmt`** 同理，按五种语句分派：

- `AssignS`：赋值目标与右值都是表达式，分别递归。目标位置的使用
  同样绑定——`x = ...` 中的 `x` 是对声明的**写引用**，与读引用
  共用同一张绑定表，词法归属规则不因读/写而不同。
- `OutputS`：对内部表达式递归。
- `IfS`：递归条件、then 分支；else 分支存在时一并递归。
- `WhileS`：递归条件与循环体。
- `BlockS`：块本身不引入作用域（TIP 没有块级声明，声明只能位于
  函数层），它只负责逐个递归内部语句。注意这与有块级 `let` 的语言
  不同：那里每个 `BlockS` 都应新建作用域。
- `ReturnS`：对返回表达式递归。

**主流程 `resolveNames`** 严格按 6.4 节的两遍组织。第一遍遍历函数
列表，向全局表注册函数名；函数名本身重名也按重声明处理（产生诊断、
保留先注册者、`continue` 跳过）。第二遍为每个函数：新建父指针为
全局表的作用域，依次 `declare` 全部参数与 `var` 名字，再遍历函数体
与返回语句，最后把作用域所有权移入 `bindings.scopes`。函数返回时
`std::move` 整个 `Bindings`，所有权连同作用域一起交给调用方。

## 6.7 诊断策略：重声明、未声明与退出码分层

本章只诊断两类语义错误，加上第 04 章传来的语法错误，三层失败用三个
退出码区分，自动化脚本据此判断问题出在哪一层。

**重声明 `redeclared`**：同一作用域中同名声明出现两次。本章的错误
程序 `redecl.tip` 让参数 `x` 与局部变量 `x` 同名：

```
main(x) {
  var x;
  return x;
}
```

实现选择**保留先声明者、忽略后声明者**。这一选择有其道理而非任意：
其一，后续遍历必须对每个名字找到唯一实体才能继续，"二者都保留"
无法做到；取先声明者让解析结果完全确定。其二，它符合 C 系语言的
传统（内层/先到的声明生效），程序员的直觉一致。被忽略的声明不产生
连锁的"未声明"——引用该名字的使用点照常绑定到先声明者，一个错误
不会自我繁殖成一片。

**未声明 `undeclared`**：使用点沿父链查找落空。`undecl.tip`
中的 `z` 从未声明：

```
main(x) {
  return x + z;
}
```

该使用点**不进入 `uses`**——绑定表只收录成功的绑定，"绑定到空"
不作为条目。这样任何消费 `uses` 的后续算法都可以假设：表中每个符号
指针非空且有效，错误处理只在解析阶段发生一次，不污染下游。

**诊断不中止遍历**：无论第一遍还是函数体遍历，遇到错误都只记录、
继续执行。因此一次运行能报告程序中的**全部**问题，而不是修一个再
跑一遍才能看到下一个。这对教学和工具体验都重要，代价仅是遍历代码
不能假设"目前为止无错误"——本章通过让成功路径与错误路径各自独立
维护状态来保证这一点。

退出码的约定是：语法错误（第 04 章 parse tree 阶段）退出码 **2**；
本章的语义错误（重声明、未声明）退出码 **3**；成功为 0。本章
main.cpp 中两层的顺序也清晰可见：先收集语法错误，无语法错误后才
构建 AST、执行名字解析——语法不过的程序没有语义可言。

### 6.7.1 "遇错即停"与"收集全部"：两种策略的取舍

诊断策略背后有一个更一般的设计选择：工具发现第一个错误时应当**立即
中止（fail-fast）**，还是**恢复并继续（error recovery）**以报告更多
问题？本章的选择（收集全部）值得论证，因为它并非在所有环节都正确。

解析器（第 04 章）其实两者都做：ANTLR 内部会做错误恢复、试图继续
解析以发现后续错误；本章的语法错误收集器如实接收恢复过程中产生的
诊断。但恢复有代价——一个真实错误之后的 parse tree 可能不可靠，
连锁诊断常常是"幻觉错误"（同一处根因的多次反映）。因此本章只
**信任并报告**收集到的诊断文本，却不在有语法错误时进入语义阶段：
恢复用于"多看几处"，不用于"带病继续分析"。

名字解析阶段更适合收集全部，因为该阶段的错误彼此**局部独立**：
一个未声明名字不影响另一处绑定，一个重声明只在自己的作用域内
改变结果。不存在"一个错误之后全盘状态不可信"的问题——这与语法
错误的连锁性正好相反。可以观察本章策略：undecl 只让该使用点不入
表，redecl 只忽略后声明者，其余遍历照常，因此多个诊断各自真实、
不是同一根因的回声。这一性质让"收集全部"在此可靠：错误之间不
互相污染，报告数量 ≈ 真实问题数量。

反过来，fail-fast 的适用场景是错误会破坏后续工作的前提。例如第 08
章 JIT 执行中模块查找失败，继续执行已无意义——main.cpp 在模块
verify 失败时直接返回。一般判据是：**错误之后的状态是否仍足以让
后续结论可信**；足以则恢复收集，不足则立即停止。本章的分层恰好
演示了两种判断——语法层停止，语义层收集。

## 6.8 正确性论证思路：声明完全、绑定正确

与第 05 章一样，本章把正确性论证、实现与输出对账分开。需要论证的
规范命题有两个：

1. **声明完全性**：程序中每个声明（函数名、参数、局部变量）在其
   作用域中注册恰好一次；
2. **绑定正确性**：每个成功使用点绑定到的符号，正是 6.3 节
   "静态最近声明原则"规定的那个声明。

论证以**结构归纳**进行，骨架与第 05 章的翻译论证同构。

**遍历覆盖**是归纳的前提：`resolveExpr` 与 `resolveStmt` 的分支必须
穷尽 AST 的全部节点种类。这可以机械核对——表达式分支覆盖了
`VarRef`、`Binop`、`CallE`、`Deref`、`AllocE`、`FieldA`、`RecLit`
及三种无动作叶子，语句分支覆盖全部六种语句；任何新增节点种类都要求
同步补分支。与第 05 章漏 cast 的情形同理，漏分支在此是静默的，
因而"分支集合 = 节点种类集合"是显式检查项而非默认保证。

**声明完全性**：参数与局部变量的注册由第二遍中两个按列表长度的循环
完成，每个声明点恰好对应一次 `declare` 调用；函数名由第一遍同样
按列表逐个注册。`declare` 在名字已存在时不写入，因此每个名字在表中
至多一个条目——"恰好一次"对合法程序成立，重名程序按明确的诊断
规则退化。

**绑定正确性**分两步。对 `VarRef` 节点，写入 `uses` 的符号来自
`Scope::lookup`；而 `lookup` 的实现就是 6.3 节形式化规则的逐条翻译
——本表命中则返回本表，否则递归父链，父链为空则失败。因此算法找到
的符号 = 形式化规定的符号。对复合节点，归纳假设是"所有子结构中的
使用点已正确绑定"，当前节点只负责把遍历延伸到正确的子节点
（`Binop` 两侧、`CallE` 的被调与全部实参……），子节点的位置由
AST 的结构唯一确定，不会遗漏或错序；故全部使用点的绑定都正确。

**两遍顺序**保证了一个全局前提：第二遍开始时第一遍已经结束，全局表
包含全部函数名。于是函数体中任何前向引用在查找时必能命中——这一
前提不依赖函数的书写顺序，论证一次覆盖所有排列。

在两个主命题之外，有一个更基础的引理值得单独陈述——**终止性**：
`lookup` 沿父链的查找必然终止。证明简单但结构完整：每次递归都从
当前作用域移动到它的父节点；作用域之间的父指针构成树，沿"向根"
方向的路径长度以树高为上界，而树高有限（任何具体程序只含有限个
声明）。因此查找在有限步内要么命中、要么到达父指针为空的根并以
"未声明"结束。这个引理把"未声明"从"算法找不到"提升为"规则
判定不存在"——查找不是因为放弃而失败，而是沿完整路径核实后
确认无声明。6.3 节强调作用域树无环，意义在此兑现：若父指针允许
成环，查找可能永不终止，"未声明"也无法与"查找未结束"区分。

由此，对任意合法 TIP 程序，作用域树按规则构造、每个使用点绑定到
静态最近声明。需要再次说明论证与输出的分工：论证覆盖无穷的程序集合，
输出对账（6.9 节）只触及本章两个具体程序，但能抓住实现与规范之间
的现实偏差。本章对 `AddrOf` 的简化也应在此记住：上述"全部使用点"
指当前遍历覆盖范围内的使用点，这是论证边界的诚实陈述，不是隐藏的例外。

### 6.8.1 为什么结构归纳在此适用

结构归纳并非万能模板，它在此适用有明确条件，值得点出，以免读者
把它当作走过场：

- **复合方式有限且显式**：AST 由有限种节点复合而成（`Binop` 恰好
  两个子表达式、`BlockS` 是有限序列……），归纳假设可以精确施加
  到"所有直接子结构"，不存在看不见的隐式依赖。
- **性质对子结构可继承**：需要证明的性质（"使用点绑定正确"）在
  复合节点上完全由子结构的同一性质决定——当前节点只传递遍历、
  不改变已有绑定。若性质包含"全局执行顺序"等跨越子结构的内容，
  单纯的结构归纳就不够，需要更强的归纳假设。
- **基础情形可直接验证**：叶子节点（IntLit、VarRef……）的行为无
  递归成分，正确性可逐行核对，归纳由此有可靠的起点。

对照后面章节会更清楚：数据流分析的正确性也用归纳，但基础是
"执行步数归纳"而非纯结构归纳——因为循环让同一段结构被反复
进入，结构不变、状态在变。本章没有执行状态，结构归纳恰好充分；
工具的选择始终由"被论证对象的复合方式"决定。

### 6.8.2 本章的答案是精确的：还没有近似，也没有精度损失

本章是本书少有的"答案非对即错、无需谈精度"的阶段，理解它与
后续分析的本质差别，能为进入格与不动点（第 13 章起）做好
概念准备。

名字解析可以**精确**求解，因为它问的是一个有唯一答案的有限
文本问题：给定一棵具体的 AST 与明确的作用域规则，每个使用点
要么恰好绑定到一个声明、要么确实自由。答案集合有限、查找
必然终止、规则没有歧义——不存在"拿不准，给个保守估计"的
空间。Resolver 算出的绑定与规则规定的绑定逐项相同，正确性
命题因此是"相等"，而不是"包含"。

从第 09 章类型分析开始，局面会变化：类型系统本身就是一种
抽象，它只刻画程序性质而放弃具体取值；再往后，数据流与指针
分析面对的性质在一般情况下不可精确判定（第 02 章的不可判定性
结论），只能在有限格上求不动点，得到一个**近似**答案。那时
正确性命题的形式从"分析结果 == 真实答案"变为"真实行为 ⊆
分析结果"（健全性：不遗漏，但可能不精确），并开始区分
"健全/不健全""精确/粗糙""可能/一定"。

因此本章在方法论上是一个标尺：先看清一个**可精确**问题如何
被完整地形式化、实现并论证相等；之后当我们不得不引入近似时，
才能清楚地知道多出来的东西（格、单调、加宽、上下文）分别
是为解决什么而存在——它们不是一开始就需要的负担，而是不可
判定性逼出来的工具。绑定表本身则将作为精确底座，被所有近似
分析反复复用。

## 6.9 真实输出解读

### 正常程序的绑定结果

对 `good.tip` 与 `ite.tip` 执行 `--check`，输出分函数组织。先建立
阅读约定：每个函数先打印自己的 `== 函数名 ==` 标题（`== good.tip ==`
是对账脚本加的文件名标题）；函数体内按遍历顺序给使用点编号，
每条形如 `use k: 名字 -> 种类`，参数与局部变量再追加所属函数名。

`good.tip` 的输出只有四行绑定，逐一可读：

- `use 1: x -> local in main`：右值前的赋值目标 `x`，第一个遍历到，
  绑定到 `main` 的局部变量；
- `use 2: helper -> fun`：被调名字在全局作用域命中，种类是函数，
  因此没有 `in ...` 后缀；
- `use 3: x -> local in main`：返回语句中的 `x`，与 use 1 是同一
  声明的两个使用点——两个不同的 `VarRef` 节点、同一个 `Symbol`；
- `use 1: n -> param in helper`：计数器在每个函数重新从 1 开始，
  `n` 绑定到参数。

`ite.tip`（阶乘）有八个使用点，它们展示同一规则在循环下的形态。
把源程序的每个使用位置按遍历顺序编号，可以与输出逐行对回：

```
ite(n) {
  var f;
  f = 1;          # use 1: f（赋值目标）
  while (n>0) {   # use 2: n（循环条件，Binop 左子）
    f = f*n;      # use 3: f（赋值目标）
                  # use 4: f（乘法左子）
                  # use 5: n（乘法右子）
    n = n-1;      # use 6: n（赋值目标）
                  # use 7: n（减法左子）
  }
  return f;       # use 8: f（返回值）
}
```

编号顺序正是结构遍历的顺序：进入 while 先读条件（n 在 f 的赋值
之后），进入循环体先处理第一条赋值（目标 f、右值乘法的 f 与 n），
再处理第二条（目标与右值中的 n），最后循环外的返回 f。对照输出：
`f` 的四次出现（use 1、3、4、8）全部绑定到局部变量；`n` 的四次
（use 2、5、6、7）全部绑定到参数。注意 use 4 的 `f`（乘法中读取）
与 use 3 的 `f`（赋值中写入）是同一条语句里的两个 `VarRef`，
词法归属不因读/写位置而有任何区别。

循环在文本上只是嵌套语句，词法归属不因为"这段代码会执行多次"
而有任何不同——这正是词法作用域"与运行历史无关"的具体体现。
换个角度看：use 2 的条件 `n` 在一次运行中会被求值多次（5、4、
3……），但绑定表只有一条——绑定是静态关系，记录"指谁"，不记录
"执行几次"。把执行次数与绑定分开，也是 6.3.1 节作用域/生存期
区分的又一次体现。

### 三个错误输出

`errors/` 下三个程序的诊断文本各自只有一行：

- 语法错误仍由第 04 章前端检出，文本形状与第 04 章完全一致
  （`syntax error line 2:13 ...`），退出码 2；
- `redecl.tip`：`error: redeclared 'x'`，退出码 3；
- `undecl.tip`：`error: undeclared 'z'`，退出码 3。

三个输出都不含文件路径、机器名等环境信息，因此在任何机器上逐字节
一致——这是"expected 对账"能跨环境成立的前提。

## 6.10 绑定表将被谁消费

名字解析的产出在本书后续被反复使用，在此一次性交代接口的去向：

- **第 08 章 LLVM IR 生成**是最近的消费者：它维护
  `Symbol* → AllocaInst*` 的映射，表达式中遇到 `VarRef` 时沿本章的
  `uses` 找到符号、再找到该符号的栈槽并 load。没有本章的绑定，
  代码生成无法区分同名变量。
- **第 09–12 章类型分析**中，变量的类型由其**声明**给出：参数和
  局部变量各获得一个类型变量，同一声明的所有使用点共享它。使用点
  到声明的绑定正是共享的依据。
- **第 27 章指针分析**扩展前端时，会补上 `AddrOf` 的绑定并新增
  经指针读写的处理；作用域结构本身无须改动。

`Bindings` 的设计因此与第 05 章 AST 的"冻结接口"遵循同一原则：
一次构建、多方只读共享。作用域树与绑定表自本章冻结。

### 6.10.1 类型信息为什么挂在声明上，而不是使用点上

第 09 章将为程序生成类型约束，这里先说明一个由本章绑定决定的
关键设计：**类型变量附着于声明（Symbol），不附着于使用点
（VarRef）**。

直觉上，"一个变量是什么类型"是关于变量**本身**的判断；而变量
本身就是声明引入的那个实体。同一声明的两个使用点（赋值中的写、
表达式中的读）不可能有不同类型——否则 `f = f*n` 里写入的 f 与
读取的 f 将毫无关系，程序也就无法理解。因此正确的归属粒度是
"每个**声明**一个类型变量"，该声明的全部使用点经 `uses` 表
回溯到同一个 Symbol、从而共享同一个类型变量。如果误把类型变量
挂在每个 VarRef 上，就需要额外的约束强行令它们相等，既冗余又
容易遗漏——本章的绑定表已经一次性给出了这种相等关系。

函数名同理：函数类型（参数类型序列 → 返回类型）挂在函数 Symbol
上；每个调用点经绑定找到同一个函数 Symbol，于是"同一函数所有
调用点的参数数目一致、返回类型一致"成为免费的结论。这也解释了
6.3.2 节遮蔽示例中的错误为何能在类型阶段被抓住：调用位置绑定到
了整型局部变量的 Symbol，而那个 Symbol 的类型变量不可能同时
满足"可被调用"。

### 6.10.2 为什么两次遍历 AST 是可接受的

本章实际上对 AST 做了两类行走：Resolver 的绑定遍历，以及打印
结果时 UsePrinter 对使用点的再遍历（为了按可读顺序输出"哪个
使用点绑定了谁"）。"为什么不复用第一次遍历顺手打印"值得正面
回答，因为它关系到一个普遍的工程判断。

根本原因是两次行走回答的问题不同、且各自需要对方的结果。
绑定遍历必须先**全部完成**，绑定表才可信——任何使用点的归属
都可能依赖遍历中尚未处理的声明（两遍结构正是为此）。打印则是
在一张**已完成**的表上做只读汇报，它在逻辑上只能发生在绑定
之后。把打印塞进绑定遍历，会在表尚未闭合时输出中间状态，顺序
与正确性都无法保证。

而多一次遍历的代价极低：AST 是有限树，遍历是线性时间、只读、
无副作用，不改变算法的量级；真正的成本在生成约束与求解（第 09
章起），不在走树。这里体现一条通用原则：**遍历次数本身不是
成本要害，每次遍历所做工作的量级才是**。为换取阶段清晰而增加
一次线性只读遍历，是划算的；应当避免的是在遍历中嵌套可能
平方、甚至更高代价的操作。

后续各章还会多次行走同一棵 AST（建 CFG、生成约束、生成 IR），
理由完全相同：每个阶段消费前一阶段冻结的产出，彼此以清晰接口
相接，而不是把所有事情压成一次无所不知的遍历。

顺带澄清一个容易猜错的归属：第 07 章的 CFG 构建其实**不消费**
绑定表，它只关心语句与表达式的形状（哪里分叉、哪里跳回），
不关心变量指谁。CFG 与绑定表是同一份 AST 上两种正交的提炼：
一个描述控制、一个描述名字；直到数据流分析把"沿控制边传播
关于名字的事实"时，二者才第一次被组合起来使用。

还值得一提的是 `Symbol::fun` 字段（符号所属函数）这一看似细小的
设计为何重要：它让"这个局部声明归哪个函数所有"成为 O(1) 可查的
事实，而不必每次沿作用域树反推归属。过程间分析在第 20 章以后要
反复按函数切分和汇总事实，归属信息随符号携带，正是为这类消费者
预备的；它也再次体现"归属挂在声明实体上"这一贯穿全书的做法。

## 6.11 工程注意点

- **先保证语法成立再做语义**：main.cpp 中 parse tree、AST、名字解析
  严格分层，任何一层失败就不进入下一层；跨层诊断混在一起会让错误
  信息失去确定性。
- **让数据结构支持部分成功**：即使当前命令行在有错误时退出，
  `Bindings` 仍把错误与成功绑定分开存放；这让"带错误继续分析"在
  未来无须重构数据结构。
- **所有权随结果一起移动**：作用域由 `Bindings` 持有是 `uses`
  指针有效的唯一保障；新增任何被长期指针引用的对象，都应照此把
  所有权放进结果结构，而不是留在遍历过程的局部存储里。
- **输出只依赖源码内容**：诊断与绑定打印均不含环境信息，顺序由
  AST 遍历与 `map` 保证确定，expected 文件才能逐字节对账。

## 6.12 本章代码

### 文法（与第 04、05 章同一份，前端持续复用）

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

### main.cpp：解析、构建 AST、执行名字解析并打印结果

```cpp
// file: src/main.cpp
// 第 06 章配套程序：解析 -> AST -> 名字解析，
// 无诊断时按函数打印每个变量使用点的绑定结果；有诊断时打印诊断并以 3 退出。
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

// 为打印绑定结果再走一遍 AST；使用点的输出顺序由此固定。
struct UsePrinter {
    const tip::Bindings &bindings;
    int counter = 0;

    void line(const tip::VarRef *ref) {
        const tip::Symbol *s = bindings.uses.at(ref);
        std::string kind;
        if (s->kind == tip::Symbol::Fun) kind = "fun";
        else kind = (s->kind == tip::Symbol::Param ? "param" : "local");
        std::cout << "use " << ++counter << ": " << ref->name << " -> " << kind;
        if (s->kind != tip::Symbol::Fun) std::cout << " in " << s->fun->name;
        std::cout << '\n';
    }

    void expr(const tip::Expr *e) {
        if (const auto *x = dynamic_cast<const tip::VarRef *>(e)) return line(x);
        if (const auto *x = dynamic_cast<const tip::Binop *>(e)) {
            expr(x->l.get()); expr(x->r.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::CallE *>(e)) {
            expr(x->callee.get());
            for (const auto &a : x->args) expr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::Deref *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::AllocE *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::FieldA *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::RecLit *>(e)) {
            for (const auto &f : x->fields) expr(f.second.get());
        }
    }
    void stmt(const tip::Stmt *s) {
        if (const auto *x = dynamic_cast<const tip::AssignS *>(s)) {
            expr(x->target.get()); expr(x->value.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::OutputS *>(s)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::IfS *>(s)) {
            expr(x->cond.get()); stmt(x->then.get());
            if (x->els) stmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::WhileS *>(s)) {
            expr(x->cond.get()); stmt(x->body.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::BlockS *>(s)) {
            for (const auto &st : x->ss) stmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::ReturnS *>(s)) return expr(x->e.get());
    }
};

}  // namespace

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
    tip::Bindings bindings = tip::resolveNames(*ast);
    if (!bindings.errors.empty()) {
        for (const tip::Diag &d : bindings.errors) std::cout << d.text << '\n';
        return 3;
    }

    UsePrinter printer{bindings};
    for (const auto &f : ast->funs) {
        std::cout << "== " << f->name << " ==\n";
        printer.counter = 0;
        printer.stmt(f->body.get());
        printer.stmt(f->ret.get());
    }
    return 0;
}
```

### ast.hpp：冻结的 AST 节点定义（同第 05 章）

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

### ast_build.hpp / .cpp：第 05 章的 AST 构建器

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

### pretty.hpp / .cpp：第 05 章带来的打印工具（本章 main 未使用）

需要特别说明：`pretty.hpp` 与 `pretty.cpp` 是从第 05 章快照一并复制
过来的，**本章的 main.cpp 没有包含或调用它们**——本章绑定结果的打印
由 main.cpp 内部的 `UsePrinter` 直接完成。它们保留在工程中，是因为
第 07 章构造 CFG 时，图节点的语句简记将复用其中的打印能力。一个文件
被随快照携带而当前未使用，与"死代码"不同：它的消费者就在下一章，
此处明确交代以免读者困惑。

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

### symtab.hpp：符号、作用域与解析结果的接口

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

### symtab.cpp：两遍解析的实现

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

### 6.6.1 一次执行的完整轨迹

把上述代码在 `good.tip` 上逐步跑一遍，可以看到数据结构如何一步步到达
最终的绑定表。下面的轨迹按时间顺序列出关键状态变化（符号用
`名字(种类)` 简写）。

1. 进入 `resolveNames`，`bindings.global` 初始化为空表，`current` 为空。
2. **第一遍**处理第一个函数：`main` 不在全局表，写入
   `main(Fun, fun=main)`。
3. 处理第二个函数：`helper` 不在全局表，写入
   `helper(Fun, fun=helper)`。第一遍结束，全局表 = `{helper, main}`
   （map 按名字排序，因此后续遍历顺序是 helper、main，但不影响绑定）。
4. **第二遍**处理 `main`：新建 `S_main`，父指针指向全局表；`owner=main`。
5. 参数列表为空；处理 `var x`：`x` 不在 `S_main`，写入
   `x(Local, fun=main)`。
6. 遍历函数体唯一语句（赋值）：先递归目标 `x`——`S_main` 命中，
   登记 `use: VarRef#1 → x(Local)`；再递归右值 `helper(3)`：对 callee
   `helper` 在 `S_main` 未命中、父链全局表命中，登记
   `use: VarRef#2 → helper(Fun)`；对实参 `3`（IntLit）无动作。
7. 遍历返回语句 `return x`：登记 `use: VarRef#3 → x(Local)`。
   `S_main` 的所有权移入 `bindings.scopes`。
8. 处理 `helper`：新建 `S_helper`（父为全局表）；参数 `n` 写入
   `n(Param, fun=helper)`；无 var。
9. 函数体为空（函数只有 return）；遍历返回语句 `return n+1`：
   `Binop` 触发左侧 `n` 在本表命中，登记 `use: VarRef#4 → n(Param)`，
   右侧 `1` 无动作。移入 `S_helper`。
10. `errors` 为空，返回完整 `Bindings`。

轨迹中值得注意三点：其一，第 6 步对 `helper` 的查找**必然发生在
第一遍之后**——前向引用由两遍顺序解决，与函数书写顺序无关。其二，
登记的四个使用点对应四个不同的 `VarRef` 节点：`x` 在 `good.tip`
中出现两次（赋值目标的写引用、返回语句的读引用），两个节点、
同一个 `Symbol x`；`helper` 与 `n` 各一个节点、各对应自己的
符号。"多个使用点、一个声明实体"在此一目了然。其三，`fun`
字段在写入时统一取 `owner`，因此打印归属时无须再沿 AST 回溯——
数据结构在注册一刻就把归属信息固化了。

回到代码中验证"遍历顺序"的来源：UsePrinter 与 Resolver 都是同一套
结构遍历（先目标后右值、先 callee 后 args），因此绑定**登记顺序**
与最终**打印顺序**一致。这一一致性不是巧合，而是两处复用同一种
AST 遍历次序的直接结果——确定性由此贯穿"解析"与"展示"两个阶段。

## 6.13 真实输出

### 正常程序

```text
; expected: expected/output.txt
== good.tip ==
== main ==
use 1: x -> local in main
use 2: helper -> fun
use 3: x -> local in main
== helper ==
use 1: n -> param in helper
== ite.tip ==
== ite ==
use 1: f -> local in ite
use 2: n -> param in ite
use 3: f -> local in ite
use 4: f -> local in ite
use 5: n -> param in ite
use 6: n -> param in ite
use 7: n -> param in ite
use 8: f -> local in ite
```

### 错误输出

```text
; expected: expected/errors/badsyntax.txt
syntax error line 2:13 mismatched input ';' expecting {'input', 'alloc', 'null', IDENT, INT, '-', '*', '&', '(', '{'}
```

```text
; expected: expected/errors/redecl.txt
error: redeclared 'x'
```

```text
; expected: expected/errors/undecl.txt
error: undeclared 'z'
```

## 6.14 小结

本章在冻结的 AST 之上完成了第一件语义工作：按词法作用域规则，先一遍注册
全部函数名、再一遍逐函数建立作用域并遍历绑定，把每个变量使用点映射到
函数、参数或局部变量三类声明实体；重声明与未声明以确定文本诊断，
语法错误与语义错误用退出码 2、3 分层。作用域的所有权集中在解析结果中，
保证绑定表的指针与结果同寿。

需要记住的不只是算法，更是它与后续工作的关系：名字解析整理的是程序中
**已确定的事实**，可判定、无近似；它产出的绑定表是第 08 章代码生成
与第 09 章类型分析共同的输入。本章也诚实地标出了当前边界——`&x` 的
绑定随指针部分在第 27 章补全。下一章把视角从"名字"转向"控制"：
把树形的函数体展开为带程序点与边的**控制流图**，让循环成为环、
条件成为分叉——数据流分析届时的工作平面。

最后把本章的原理性收获单列于此，它们比任何代码细节都更值得带走：

- 绑定是使用点到**声明实体**的静态关系，不是到地址、也不是到
  执行某次取值；名字字符串只是表面，绑定结构才是实体（α 等价）。
- 词法作用域可以归结为一棵无环的作用域树加一条"本表优先、沿
  父链向上"的查找规则；遮蔽、前向引用、相互递归都是该结构的
  推论或对遍历顺序的要求，而非各自独立的特性。
- "先让实体存在、再解释引用"是允许任意互相引用时绕不开的结构；
  两遍之所以恰好足够，是因为依赖只有一个方向。
- 本章答案精确、论证形式为"相等"；从下一篇起，面对不可精确
  判定的性质，答案将变为近似、论证将变为"真实行为 ⊆ 分析结果"。
  记住这个标尺，才能理解后面每一件新工具为何被引入。
