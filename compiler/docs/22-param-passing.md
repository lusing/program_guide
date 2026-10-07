# 第 22 章　参数传递的四种机制：同一调用，四种语义

函数怎么拿到数据，看似语法细节，实为语言设计的分水岭。`p(a, a)` 这一个调用——同一个变量传两次——在四种传递机制下给出四个不同的答案，其中两个还相同。本章取材 Louden《编译原理及实践》§7.5（参数传递机制）与 §7.2（完全静态运行时环境），把四种机制做成**同一台解释器里的四个开关**，让每个语义差异都可运行、可对账。

这不是考据章。值传递是你每天在 C 里用的；引用传递是 C++ 的 `&` 与 Pascal 的 `var`；值结果是 Ada 的 in out；名字传递是 Algol 60 的幽灵——被淘汰了，但它的思想（延迟求值）活在惰性语言里。四种机制各有其运行时代价与别名行为，**编译器作者必须为每一种设计调用序列与帧布局**——这是第 21 章（活动记录）的直接续篇。

**本章示例：`examples/22_param_passing`（无 ANTLR；手写前端 + 四机制解释器）**

阅读地图：

- 只想知道 p(a,a) 为什么四个答案 → §22.4 的别名分辨器 + §22.7 的 S6 段。
- 想看 Jensen 装置怎么工作 → §22.5.2 的逐圈账。
- 想理解"没有栈的世界" → §22.1（完全静态环境，递归禁令的由来）。
- 想动手换机制 → §22.9 练习 1–4（加 const 引用、结果传递、thunk 计数器扩展）。

## 22.0　本章要解决的问题与位置

四个问题，四节正菜：

1. **没有栈的世界长什么样**（§22.1）——FORTRAN 77 的完全静态环境：每函数一帧、跨调用保留、递归被禁。它回答"栈到底买来了什么"。
2. **每种机制的调用序列差在哪**（§22.2–22.5）——实参怎么算（调用时/使用时）、地址要不要（引用/值结果）、写回什么时候发生（值结果出口）。
3. **别名怎么分辨机制**（§22.4）——`p(a,a)` 的四答案表：别名是唯一能区分引用与值结果的实验。
4. **淘汰者留下了什么**（§22.5）——名字传递的 thunk 与 Jensen 装置；延迟求值的现代转世。

位置：第三篇"中间表示与运行时"的中段。第 21 章讲了帧的形状（栈环境），本章讲**帧里参数的四种住法**；第 23 章（GC）接着讲帧外的东西（堆）。三合成"运行时环境"的完整地图——L 书第 7 章的全部野心，教程用三章机器化。

与教程其他执行器的分工：第 15 章树遍历解释器只有值语义（闭包除外）；本章解释器**一机四制**——同一个 call 函数里的一个 switch 是全部机制差别的落点。教学语言的形参注记（`val/ref/valres/name`）对应 Pascal/Ada 的声明语法（`var`/`in out`），而不是 C 的"只有值"。

教学语言的完整文法（front.cpp 的对照面，每行一条产生式）：

- `program = fun { fun }` —— 若干顶层函数，`main` 为入口；
- `fun = "fun" NAME "(" [ param { "," param } ] ")" block`；
- `param = ("val"|"ref"|"valres"|"name") NAME` —— 机制注记住在形参上；
- `block = "{" { stmt } "}"` —— 循环与分支体必须是块（坑四的文法约定）；
- `stmt` 的十一种形态：`var`/`array` 声明、`print`、`if-else`、`while`、`for-do`、`return`、标量赋值、数组元素赋值、弃值调用；
- `expr` 四层优先级（比较 → 加减 → 乘除 → 一元 → 原子），全部左结合；
- `atom`：数字、变量、数组元素、调用、括号。

十二行文法撑起九组语料——教学语言的性价比算法：**每个产生式至少要有一组语料依赖它，否则删掉**（`while` 是唯一的双保险语句：语料没直接用、但 if/for 覆盖不了它的场景，留作练习扩展的接口）。

## 22.1　完全静态运行时环境：没有栈的世界

### 22.1.1　FORTRAN 77 的世界

L 书 §7.2 的开场：**最早的运行时环境没有栈**。FORTRAN 77 的每个过程只有一份静态帧——地址在编译期定死、放进数据段，像全局变量一样：

- 调用 `count` 时不需要"建帧"——帧早就在那里；
- 局部变量的值**跨调用保留**（本章 S1 段的证人：三次 `count(1)` 得 3 不是 1）；
- 代价：**递归被语言禁止**——`fact(fact(n))` 需要两份 `fact` 的帧，而世界上只有一份。

递归禁令的表述在 FORTRAN 标准里是"过程不得直接或间接调用自己"——不是"不建议"，是**非法**。本章解释器的静态模式用调用环检测实现这条禁令：`active_` 链上再见同名函数即拒绝（S1 段：`rec-static` 报 `recursion rejected`，同一程序在栈模式跑出 6）。

### 22.1.1a　静态帧的布局账（与第 21 章的对照）

把两种环境的帧布局并排画（以 counter 语料为例）：

- 静态环境：
  - `count` 的帧：一格（c），地址编译期定死——概念上是 `dMem[17]` 这样的常量；
  - `main` 的帧：一格（x），另一段静态区；
  - 调用序列：**零条**帧指令——没有 push fp/mov fp,sp，直接跳转；
  - 参数 `step` 也有自己的静态格（每次调用覆写）。
- 栈环境（第 21 章 21.3 节的形状）：
  - 每次调用 `count` 现场造一帧（返回地址、动态链、参数、局部）；
  - 调用序列五步、返回序列四步（21 章正文有完整账）；
  - 帧地址每次不同——参数访问走 fp 相对寻址。

对照的读法：**第 21 章讲的调用序列，在静态环境里几乎整段消失**——这是 FORTRAN 编译器在 1960 年代跑得快的结构性原因之一（另一个是没有动态分配）。买回递归的代价不只是"建帧的几条指令"，还有**地址不再是常量**——编译器的每一处变量访问都多一层间接（fp 相对寻址）。

本章解释器把这两种布局做成同一张 `map` 的两种生命周期（staticFrames_ 永生 vs keepAlive 随调用生死）——**布局差异在实现里收缩为生命周期差异**，因为解释器的"地址"本来就是运行期的 map 查找。真机上（第 65 章 TM）两者的指令差会显形：静态变量一条 LDC 地址、栈变量要经 fp 算偏移。

### 22.1.2　栈买来了什么

对照表（本章两种模式的全部差异，机器为证）：

| 维度 | 完全静态（§7.2） | 栈环境（§7.3，第 21 章） |
|---|---|---|
| 帧的数量 | 每函数一份 | 每次调用一份 |
| 帧的位置 | 编译期定死 | 运行期随调用栈伸缩 |
| 局部变量 | 跨调用保留（SAVE 语义） | 每次调用重新初始化 |
| 递归 | 禁止（无第二份帧） | 天然支持 |
| 帧的分配成本 | 零 | 建帧/销毁各一次 |
| 谁在用 | FORTRAN 77、嵌入式底层 | 几乎所有现代语言 |

栈的发明买来的就是最后一行左列没有的东西：**递归与重入**。代价是一次建帧销帧（现代机器上几个纳秒）。第 21 章讲帧布局时把栈当空气，本章补上"空气也是有价格的"这一课。

实现注记：静态模式的"声明只在首次落格"是 SAVE 语义的关键——`var c;` 在第二次调用 `count` 时**不**清零 c。栈模式则每次重落。两行代码的差异（`if (!static_ || fr.find(...) == fr.end())`），语义上隔着一个时代。

### 22.1.2a　静态环境的现代回声（展开）

"没有栈"不是化石展品，四处回声：

- **中断与信号处理**：handler 与被中断代码若共享静态缓冲——重入即数据竞争；POSIX 的 async-signal-safe 函数清单本质是"这些函数在静态环境语义下可安全重入"的白名单；
- **老式 RTOS 与固件**：任务各自静态栈/静态帧，递归禁令写在编码规范里（MISRA C 的"不递归"条款）——内存总量编译期可知是硬实时系统的刚需；
- **errno 的历史**：这个著名的"全局错误格"就是静态环境遗产——多线程时代不得不改成线程局部存储（TLS）——**静态格遇上并发要重新发明环境**，线程局部存储是"每线程一份静态帧"的现代版；
- **per-CPU 变量**（Linux 内核）：`per_cpu(x, cpu)` ——静态地址 + CPU 编号偏移，静态环境思想的并发定制款。

回声的公共主题：**静态环境 = 环境维度退化为一**。一旦并发/重入/递归需要第二个维度（线程/调用层），要么把维度补回来（TLS、栈）、要么用契约禁掉需求（不可重入、禁递归）。这张"维度账"是运行时环境设计的总纲——第 21 章的栈是"调用层维度"、第 23 章的堆是"生命周期维度"、本章静态环境是"零维度基线"。

### 22.1.3　静态帧的地址固定红利

静态环境有一样栈永远给不了的东西：**变量的地址是编译期常量**。FORTRAN 编译器可以把 `count` 的 `c` 直接编成 `dMem[17]` 这样的一次性地址——没有帧指针、没有间接寻址。教学解释器用 `map` 存帧（地址运行期才定），但**概念上**每个槽的地址在编译期已可知。这份红利在目标机上值多少，第 65 章的 TM 机器会明码标价（gp 基址 + 编译期偏移 = 变量地址的全部计算）。

## 22.2　值传递：被初始化了的局部变量

### 22.2.1　语义

实参在调用时**求值一次**，值拷贝进被调者的局部槽。此后形参就是普通局部变量——**对它的任何改变都与外界无关**。L 书的原话："值参数在本质上被看作是被初始化了的局部变量"。

本章 S2 段的 inc2 反例（L 书原文程序）：

```text
fun inc2(val x) { x = x + 1; x = x + 1; }
main: y = 5; inc2(y); print y;    → 5
```

`x` 加了两次，`y` 纹丝不动。要让函数影响外界，值传递语言只有一条路：**通过返回值**（函数式风格）或**传地址**（把指针当值传——C 的 `&` 是"半个引用"，见 §22.3.3）。

### 22.2.2　编译器的账

值传递对编译器最友好：

- 调用序列：求值实参 → 拷入帧槽。无地址、无写回、无延迟；
- 帧布局：参数就是一个普通局部变量的槽；
- 访问代码：直接读写槽。

C 只提供值传递（数组例外——退化为指针，见下节），不是历史偶然：**值传递的实现是四种里最便宜的**，而 1972 年的机器付不起别的。

### 22.2.2a　纯值世界：ML 与 Haskell 的选择

函数式语言把值传递推到语义洁癖的极端：**一切皆值、值不可变**——ML 的引用类型是显式的盒子（`ref`）、Haskell 连盒子都要经 monad。这个选择换来的推理性质：

- 等式推理：`f(x)` 可以随手替换成它的值（引用透明）——重构与优化的数学地基；
- 无别名：不可变值谈何别名——§22.3.2a 的优化杀手根本不存在，Haskell 编译器（GHC）敢于做激进变换的底气；
- 并行自由：无共享写 = 无数据竞争——纯函数部分自动并行安全。

代价是"想让函数影响外界"必须把效果**显式化**（返回新值、State monad、IO monad）——inc2 的治愈不是把 x 变成 var，而是 `let y2 = y + 2`。**机制的选择即编程范式的选择**——这是 §1.5（L 书"参数传递对语言设计的影响"）最远的回声。

值传递谱系的三个档位小结：C 的值（可变世界的隔离）、Pascal/Ada 的值+引用（双轨）、ML/Haskell 的纯值（不可变世界）——三档都是"值"，语义重量完全不同。本章机器实现的是第一档，第三档的影子在 call-by-need 的讨论里（§22.5.2a）已经出现。

## 22.3　引用传递：别名与临时格

### 22.3.1　语义与 inc2 的治愈

实参的**地址**传给被调者，形参成为实参的**别名**（alias）——写形参就是写实参。S3 段：

```text
fun inc2(ref x) { x = x + 1; x = x + 1; }
main: y = 5; inc2(y); print y;    → 7
```

同一函数体、同一实参，答案从 5 变 7——机制换了，语义换了。Pascal 用 `var`、C++ 用 `&` 声明这一档；FORTRAN 77 干脆**只有**这一档。

引用版的逐步账（p(a,a) 的 ref 档，对照 §22.9.1 剧本）：

- 绑定：x.ref = &a、y.ref = &a——两个形参是**同一格的两个名字**；
- x = x + 1：读 *(&a) = 1，加一，写 *(&a) → a = 2；
- y = y + 1：读 *(&a) = **2**（不是 1！），加一，写 → a = 3；
- 关键行是第二条的"读 2"——**别名让两个"独立"的语句实际串联**。顺序程序员的直觉（每条语句只看自己的变量）在别名面前失效——这就是 §22.3.2a 优化杀手的手感版。

## 22.3.1a　引用传递的两个语义陷阱

- **别名串联**（上面 p(a,a) 的账）：两个形参各改各的，结果却互相影响——诊断这类 bug 的口诀："参数表里有同一个变量两次吗？"
- **输出参数当输入用**：`fun div(ref q, ref r, val a, val b)`（整数除法同时回商与余数）——调用者若把未初始化的变量当 q/r 传，被调函数若碰巧先读 q 就读到垃圾。现代风格指南的对策：**输出参数只写不读**（或干脆用多返回值/元组——C++17 结构化绑定后，输出参数正在退出新代码）。

### 22.3.2　表达式实参的临时格

引用传递要求实参**有地址**。但 `g(2 + 3)` 呢——表达式没有地址？FORTRAN 77 的官方答案（L 书 §7.5.2）：**编译器造一个临时格**，把 5 算进去，把临时格的地址传过去。被调者的写落在临时格上、随调用消亡——外界无恙。

本章 S3 段的证人（`expr-arg` 语料）：`g(2+3)` 与 `g(4+1)` 各落一个临时格（#0、#1），main 的 `m` 稳在 42。临时格住在调用者的存储里——本章实现用解释器的 `temps_` 仓（真实编译器放在调用者的帧或静态区，FORTRAN 放静态区）。

临时格的三个工程细节（L 书提到、值得展开的）：

- **谁造格**：调用者（实参求值在调用方语境）；造在调用者帧里则随调用方生死——本章全局仓是简化，练习 6 的改进点；
- **复用与否**：同一调用点的两次执行可以复用同一格（本章 #0/#1 各司其职因为两次调用走同一个格位——若实现按调用点分配，两次 `g(...)` 会共用一格；按递增编号则是审计友好。教学选了后者，把"格的一生"打印出来）；
- **只读契约**：FORTRAN 允许把表达式传给引用参数、**不保证**被调者的写不影响后续——写出这种依赖的程序是错的（又一例"契约换自由"）。C++ 对 const& 无此问题（写都不许）、对非 const & 直接编译错——现代语言用类型系统把临时格陷阱焊死。

## 22.3.2b　引用传递的声明面：三种语言的语法对照

- Pascal：`procedure p(var x: integer)`——`var` 是**类型的一部分**；调用点无记号（实参必须是变量）；
- C++：`void p(int &x)`——`&` 在声明处；调用点同样无记号（这是 C++ 引用被批评"看不出改没改"的原因——call site 无信息）；
- FORTRAN：无记号——一切皆引用（编译器自行决定标量是否优化成值语义，反正不可分辨）。

对照的读法：**机制住进类型系统（Pascal/C++）还是住进默认（FORTRAN）**，决定了调用点的可读性与声明处的复杂度之争。Rust 的 `&mut` 把这架吵到了新高度——可变性进类型、别名进生命周期（borrow checker），那是对本章问题的类型论级总攻。

### 22.3.2a　别名如何毁掉优化（与第 51 章的互参）

引用传递不只是"多一种调用方式"——它给编译器引进了**别名**这个优化杀手。一段对比：

- 值传递的 `p(x, y)`：编译器**知道** x、y 是不同存储——`t = x; y = 1; u = x;` 里第二个 x 可复用 t（公共子表达式）、两句话可乱序、x 可驻留寄存器全程；
- 引用传递的 `p(a, b)`：编译器**不知道** a、b 是否同一格——任何对 y 的写都可能改掉 x，CSE、乱序、寄存器驻留全部泡汤，除非先证无别名。

这就是第 51 章指针分析存在的理由：**别名分析是引用型语言的优化地基**。Andersen 式分析（51 章）算"may-point-to"、再据此排除别名、优化才能进场。本章教学解释器没有优化 pass 用不着这些；但把"引用 = 别名源"记在心里，51 章读到"为什么要算 points-to"时的答案就在这里。

反过来，值传递语言（C 的标量部分）天然无参数别名——这是 C 能编出紧凑代码的隐性红利之一（ANSI C 的 restrict 关键字后来把这个红利显式化：程序员**承诺**无别名，换回优化自由——承诺错了就是 UB，又一个"契约换性能"的语言设计样本）。

### 22.3.3　C 的数组退化为指针：半个引用

C 的值传递有一个著名的特例：**数组形参其实是指针**——`void f(int a[])` 里的 `a` 是 `int *`，传的是数组首地址。于是"改 a[i] 穿透到外界"——看起来像引用传递，机制上仍是**值传递（传的是地址值）**。L 书专门点了这一条：它让 C 程序员以为自己在用引用，实际上每次都手动传址。C++ 的 `&` 与 `const&` 才是真正的引用档——后者兼得"免拷贝"与"只读检查"（大结构传参的标准姿势：`void f(const MuchData &x)`，编译器静态保证 x 不出现在赋值左边）。

## 22.4　值结果传递：别名是唯一的分辨器

### 22.4.1　语义

值结果（value-result，Ada 的 in out）：**入口拷入、出口写回**——执行期像值传递（对局部槽操作），返回时把终值抄回实参。别名分辨器（L 书 §7.5.3 原文例）：

```text
fun p(valres x, valres y) { x = x + 1; y = y + 1; }
main: a = 1; p(a, a); print a;
```

- 引用传递：x、y 都别名 a —— a 被加两次 → **3**
- 值结果：入口 x=y=1（各拷一份）；执行 x→2、y→2；出口写回——**无论谁先谁后，写的都是 2** → **2**

S4 段实测：valres 2、ref 3。**同一个程序、两种机制、两个答案**——这是区分两者的唯一实验（无别名时两者行为全同）。

### 22.4.2　未指定的两件事

L 书指出值结果有两处**语言间未指定**，实现者自选：

- **写回顺序**：多参数按声明序还是逆序？本章选声明序（实现口径写进代码注释）。S4 的 `writeback-order` 语料把这一点变成可观察的：`q(valres x, valres y) { x = x + 1; y = y + 10; }` 传 `(a, a)`——出口 x 写 2、y 写 11，**声明序**则终值 11，逆序则 2。实测 11，口径自证。
- **地址重算时机**：实参地址在入口取一次，还是出口重取？`q(a, a[i])` 且函数内改了 i——两种选择给不同的写回位置。本章选**入口取一次**（slot.out 在绑定时定死）。

Ada 的立场更有趣：标准说 in out **可以**用引用实现，也可以用值结果实现——**任何依赖两者差异的程序都是错误的**。把未指定上升为"程序员不得依赖"，是语言设计处理实现自由的经典手法。

### 22.4.2b　未指定、未定义、实现定义：规范语言的三分类

标准文档（C/C++/Ada）对"行为没定死"的情形有三档措辞，机制章正好一次见全：

- **未指定（unspecified）**：几种行为都合法，实现任选、不必一致——本章的写回序与求值序（C 的实参求值顺序）都是。程序**不应依赖**，但依赖了也不炸——只是换编译器结果漂移；
- **实现定义（implementation-defined）**：实现必须**选定并写进文档**——如 C 的 `int` 位宽。比未指定严一档：可查手册、可移植地依赖（代价是绑定平台）；
- **未定义（undefined）**：任何行为都不受保护——越界写（本章解释器抛异常是**教学加护**，真机上是 UB）、FORTRAN 往临时格写后续依赖。优化器可以假设 UB 不发生——依赖 UB 的程序在优化下会静默错得离谱。

三分类的教学价值：**"语言是什么"不只由能写出什么决定，还由哪些行为没被定死决定**。写回序这类未指定条款不是标准的懒惰，是把"实现自由"与"程序可移植"分好的边界——Ada 的"不得依赖"就是这个边界的合同文本。本章实现自选了声明序并在代码注释里立此存照——**教学机器也按标准文档的纪律写**。

### 22.4.3　对调用序列的修改

值结果比引用多两笔账（L 书 §7.5.3）：

- 被调者**不能销毁帧**直到写回完成（出口代码要读局部槽）；
- 调用者要**保存实参地址**直到写回（或被调者重算）。

本章实现：写回循环在 `call()` 的返回前显式执行（声明序遍历参数表）——真实编译器把它编成函数体的 epilogue 一部分，或调用者的 prologue 一部分，两种分工各有传统。

## 22.5　名字传递：淘汰者的思想遗产

### 22.5.0　thunk 的编译器视角

Algol 编译器怎么实现名字传递？把实参**编译成一个无参过程**（thunk 的词源就是"一小块要算的东西"）：

- 实参 `a[i] * 2` 在调用点被改写成函数 `procedure τ1; τ1 := a[i] * 2;`——捕获调用点的环境（i 的访问路径照抄）；
- 形参 x 的每次读编译成"调用 τ1"、每次写编译成"调用 τ1 的左值版"（取址 thunk）；
- 参数槽里放 τ1 的代码地址 + 环境指针——**与传函数参数（§22.6）完全同构**，只是这个函数是编译器替你造的。

本章解释器的 Thunk{expr, env} 是这套编译方案的解释器直译——没有真的生成过程，但机制一一对应。**"编译器替你造函数"**是理解名字传递的最短路径：它不是魔法，是高阶函数的隐式版。Algol 60 报告没有这样说（报告只给了换名规则语义），实现界用了五年才收敛到 thunk 方案——语义标准走在实现前面，这又是语言史的一贯节奏。

### 22.5.1　语义：使用处重求值

名字传递（call by name，Algol 60）：实参**不在调用时求值**——它被封装成一个** thunk**（无参过程），**每次使用形参时在调用方的环境里重新求值**。四个机制里最贵也最强的一档：

| 时机 | 值 | 引用 | 值结果 | 名字 |
|---|---|---|---|---|
| 实参求值 | 调用时一次 | 调用时取址 | 调用时取址+拷值 | **不求值** |
| 形参读 | 读局部槽 | 间接读 | 读局部槽 | **thunk 重求值** |
| 形参写 | 写局部槽 | 间接写 | 写局部槽 | **thunk 定址后写** |
| 返回时 | 无 | 无 | **写回** | 无（写已穿透） |

thunk 的实现（本章）：`Thunk{expr, env}`——实参表达式指针 + 调用方帧指针。读走 `eval`（重求值）、写走 `evalLValue`（重定址）——**两条通道都要穿透**，这是实现名字传递最容易漏的一半（漏了写通道，`x = y` 就写不回调用方）。

### 22.5.2　Jensen 装置：被调方改写调用方的循环变量

名字传递的王牌应用（Jensen's device）：**把循环变量与循环体都作为名字实参传给求和函数**——

```text
fun sum(name i, val n, name term) { var s; s = 0;
    for i = 0 to n - 1 do { s = s + term; } return s; }
main: array a[3] = {1,2,3};  s = sum(i, 3, a[i] * 2);  → 12
```

逐圈账（S5 段的实测 12 与 thunk evals=3 的展开）：

| 圈 | i（被调方写，穿透到 main） | term 重求值 | s |
|---|---|---|---|
| 1 | i = 0 | a[0]*2 = 2 | 2 |
| 2 | i = 1 | a[1]*2 = 4 | 6 |
| 3 | i = 2 | a[2]*2 = 6 | 12 |

- `for i = ...` 的赋值经 thunk 写通道穿透到 **main 的 i**（S5 打印 i 终值 2）；
- 每圈 `s + term` 触发 term 的**重求值**——thunk evals 恰好 3（每圈一次读）；
- `a[i] * 2` 里的 i 用的是**当圈**的 i——求和的语义完全由"重求值"撑起。

同一个 `sum`，传不同的 term 就算不同的和——Jensen 装置的应用家族：

- `sum(i, 3, a[i] * a[i])` → 平方和（14）；
- `sum(i, 3, 1)` → 计数（3，term 与 i 无关——重求值退化成常量）；
- `sum(j, 100, 1.0 / j)` → 调和级数近似（j 是另一个名字形参，被调方的 for 改写它）；
- `sum(i, n, b[i] - a[i])` → 向量差的和（两个数组的同步遍历，一个循环变量就够）。

**一个函数、一族行为**——这是名字传递的诱惑，也是它危险的开端（swap 反例在下一节等着）。现代语言达到同样表达力的路径是高阶函数：`sum(i => a[i]*a[i])`——thunk 显式化为 lambda、循环变量变成参数，控制权同样交出，但语法上到处可见、可推理。

### 22.5.2a　call-by-need：补上缓存的名字传递

名字传递的工程病根是**每次使用都付全价**。call-by-need（Haskell 的求值策略）只改一件事——thunk 第一次求值后把结果**缓存**进格子：

- 实现 sketch：Slot 加 `bool forced` 与 `double cached`；eval 读 thunk 槽时先看 forced——未强迫则求值并缓存、已强迫直接读缓存；
- 语义差：**纯表达式的 call-by-name ≡ call-by-need**（重求值同一表达式在同一环境必然同值）；有副作用的表达式两者不同（副作用只发生一次 vs 每次）；
- Jensen 语料在 call-by-need 下**算错**：term 的 a[i] 随 i 变——缓存第一次的 2 之后不再更新，和变成 2*3=6 而不是 12。**缓存破坏了"重看世界"的语义**——Jensen 需要 call-by-name，惰性需要 call-by-need，两者在 term 依赖可变量时分道扬镳。

这个对照是"延迟求值家族"的内部地形图：**延迟（什么时候算）与重算（算几次）是两个正交旋钮**——名字传递是"延迟+每次"、need 是"延迟+一次"、严格值是"立即+一次"。四机制外的第五维，现代函数语言的默认档。

### 22.5.3　swap(i, a[i])：写错槽位的经典

名字传递最著名的反例（Knuth 反复引用）——交换 `i` 与 `a[i]`：

```text
fun swapn(name x, name y) { var t; t = x; x = y; y = t; }
main: i = 2; a[2] = 5; swapn(i, a[i]);
```

逐步推演（S5 段实测 5 5 2）：

| 语句 | thunk 解开为 | 效果 |
|---|---|---|
| t = x | t = i | t = 2 |
| x = y | **i = a[i]** | i = a[2] = 5（i 变了！） |
| y = t | **a[i] = t** | a[**5**] = 2（错槽！） |

终态：i=5、a[2]=5（没动）、a[5]=2（写错地方）。引用传递版同一程序得 i=5、a[2]=2（正确交换，S5 的 swap-ref 行）。**两个机制在同一语料上给出可预言的不同错误**——这是分辨名字与引用的关键反例（p(a,a) 上它们同答案，swap 上分道扬镳）。

这个反例的出处与变体：

- Knuth 在《The Art of Computer Programming》第 1 卷论及换名语义时引用了它（后来又被多本教材转引，L 书是其一）——**教科书史上被复用最多的名字传递反例**；
- 变体一（下标变加号）：`swapn(i, a[i+1])`——错位差一格，终态 a[a[i+1]] 被写；
- 变体二（交换双方都依赖循环变量）：在 for 循环里 swapn(j, a[j])——每圈错位位置都变，错误随迭代扩散成**错误带**；
- 变体三（纯标量）：`swapn(x, x)`——退化为 p(x,x) 型，与引用同答案（都是"交换自己"，无害）——**反例的力量来自 lvalue 的"下标会变"**，纯变量让名字传递退化成别名（§22.9.1 的观察）。

教学上这个反例的经典用法：先让学生**预言**输出（多数人猜 5 2 0——按引用直觉），再跑 swap-name（得 5 5 2），最后逐步推演找分歧点（第二条赋值）——**直觉、机器、推演三堂会审**，比任何定义式讲解都记得牢。

### 22.5.4　被淘汰的原因与思想的转世

thunk 与闭包的对照表（同一机制的两件衣服）：

| 维度 | 本章 Thunk | 第 15 章闭包 |
|---|---|---|
| 封装物 | 实参表达式（Expr*） | 函数体（AST 子树） |
| 捕获 | 调用方帧指针 | 定义时环境链 |
| 触发 | 每次读/写形参 | 每次调用函数值 |
| 写通道 | 有（evalLValue 穿透） | 无（函数值不可赋值） |
| 缓存 | 无（每次重求值） | 无 |
| 加 memoization 后 | call-by-need（Haskell） | 带记忆化的闭包（原型链缓存） |

最后一行是历史的关键一步：**call-by-need = call-by-name + 记忆化**——thunk 第一次求值后把结果存进格子、后续直接读。Algol 的错误不在思想而在**没有缓存**——每次使用都付全价。Haskell 的惰性求值补上这一笔，惰性从此可以量产。教程的机器谱系里，第 15 章的环境链（闭包）与本章的 Thunk 在"代码 + 环境"这个二元组上会师——**运行时篇的全部深奥（闭包、上值、thunk）都是这个二元组的变奏**。

Algol 60 的名字传递被淘汰，工程理由三条（L 书 §7.5.4 的总结）：

- **难优化**：每次访问都是一次过程调用，编译器无法把形参固化到寄存器；
- **难推理**：swap(i, a[i]) 一类的语义陷阱，程序员防不胜防；
- **难实现**：thunk 的生成、环境捕获、写通道穿透，每个编译器都要重写一遍。

思想却活了下来：**thunk 就是闭包的最小形态**（表达式 + 定义环境），**使用处重求值就是惰性求值**（Haskell 的 call-by-need 在 thunk 上加了 memoization——求过一次就缓存，兼得名字传递的表达力与值传递的效率）。第 15 章的闭包（函数体 + 定义环境指针）与本章的 Thunk 结构同构——一个用于函数值、一个用于实参延迟，**同一机制的两件衣服**。

### 22.4a　四机制的调用序列伪码对照

把 call() 的绑定 switch 翻译成调用双方的伪码（L 书 §7.5 各小节的调用序列综合）：

```text
值传递：
  调用者：t = 求值(实参)；  push t 的拷贝；  call f
  被调者：参数槽 = 栈上的拷贝；  （执行）  ret
  出口：  无动作

引用传递：
  调用者：t = 取址(实参)（或临时格）；  push t；  call f
  被调者：参数槽 = 间接指针；  （执行：读写都间接）  ret
  出口：  无动作（写已实时穿透）

值结果：
  调用者：t = 取址(实参)；  push t 与 *t 的拷贝；  call f
  被调者：参数槽 = 本地值 + 出口地址；  （执行：读写本地值）  ret 前：*t = 本地值
  出口：  写回（声明序、地址入口取——两个自选口径）

名字传递：
  调用者：push {实参表达式, 当前帧}；  call f
  被调者：参数槽 = thunk；  （执行：每次访问 = 调用 thunk）  ret
  出口：  无动作（写已穿透）
```

四段伪码的行数差就是实现成本的差——值传递三行、名字传递五行外加 thunk 的生成与分派。L 书 §7.5 每小节的"对编译程序的要求"段落说的就是这些行；本章 interp.cpp 把它们收进一个 switch，对照读即可。

## 22.6　过程参数：传函数要带环境

L 书 §7.3.3 的收尾话题：**函数本身当实参传**。`apply(f, x)` 里 f 是什么？栈环境里传函数必须带两样：**代码地址 + 定义环境**（不然 f 里的自由变量找不到家）——这正是第 15 章闭包的定义。本章语言暂不实现函数值（教学语料不需要），但机制已在门口：thunk 的 `{expr, env}` 对就是 `{代码, 环境}` 对的最小版。真实实现见第 15 章环境链与第 21 章访问链——后者是"环境跟着函数走"的帧上版本。

过程参数的三种实现路线（L 书 §7.3.3 的讨论骨架）：

- **代码地址单传**：只传入口点。当且仅当语言无嵌套函数（C 的函数指针）时安全——自由变量只有全局，地址就是全部身份；
- **代码 + 定义环境对**：Pascal/Ada 的嵌套过程参数——对里环境指针让被传过程回家；访问链（第 21 章）就是这个环境指针的帧上实现；
- **闭包对象**：函数值是一等公民的语言（ML/JS/教程第 15 章）——{代码, 环境} 打包成堆对象，参数传递只是传这个对象。

三条路线是同一需求的三个时代答案。教学价值在于它们解释了 C 函数指针"为什么简单"——**简单不是天性，是语言面（无嵌套函数）换来的**；也预告了第 60 章（上值）要解决的深水区：环境跟着函数走了，环境本身的生命周期怎么办。

## 22.6b　S1–S5 逐组推演小账

期望输出的六段之外，每组断言配一张"最小推演账"——读者合上书也能重建数字：

- **S1 counter（static=3）**：三连调共用 count 的静态帧——c 首次落格为 0，此后 `c = c + step` 三次：0+1=1、1+1=2、2+1=3。若声明每次重落（坑一的病），每次都从 0 加起——三连 1。
- **S1 fact（static 拒）**：main → fact(3) → fact(2)——active_ 链 [main, fact, fact]，环闭合，拒绝。栈模式：fact(2) 的帧是新的，active_ 不存在——6 = 3*2*1 正常回家。
- **S2 inc2（5）**：x 是拷贝；y 的格从头到尾没被碰。
- **S3 inc2（7）**：x.ref = &y；两次 +1 都落在 y 的格上：5→6→7。
- **S3 临时格（42）**：`g(2+3)` 的 5 进 temps_[0]、x.ref 指它；x+1 写 temps_[0]=6，函数返回，格遗弃；m 的格从头到尾无关。
- **S4 valres（2）**：22.9.1 剧本已推。
- **S4 写回序（11）**：q 里 x=1+1=2、y=1+10=11（互不干扰——值语义）；出口 x 先：a←2，y 后：a←11——**后写者胜是声明序的直接推论**。
- **S5 swap（两版）**：§22.5.3 的表已推。
- **S5 jensen（12/2/3）**：§22.5.2 的逐圈表已推。

九张小账合订本——**每个数字都有一步之内的推导**，这是"机器证人"方法论对读者的承诺：跑得出、也推得回。

## 22.6a　lang.hpp 字段速览与 front.cpp 逐函数走读

**lang.hpp 的四个结构**（全部字段及其服务对象）：

- `Expr`：六种节点（Num/Var/Index/Bin/Unary/Call）——表达式层刚好覆盖四机制的实验需要：Var 是最简单 lvalue、Index 是"下标会变"的 lvalue（swap 反例的原料）、Call 让实参里嵌调用（嵌套机制的语料）、Bin/Unary 是"无地址表达式"（临时格的原料）。
- `Stmt`：九种语句——赋值（标量/数组元素两形态）、print、if/while/for、return、声明（var/array）、CallStmt（弃值调用——inc2 与 swap 语料的形态）。**for 语句**是 Jensen 的必需品：循环变量归属被调方的名字形参时，装置才成立。
- `Param`：`(name, mode)` 二元组——机制注记住在形参上（Pascal/Ada 口径），不是调用点（C 口径）。
- `Fun/Program`：函数表——本语言无嵌套定义（thunk 捕获的"环境"因此只有一层帧，练习 5 扩展）。

**front.cpp 三段**：

- 扫描器 `scan`（~40 行）：跳空白与 `//` 注释、两字符运算符先行、标识符/数字成词。**行号在 token 里**——错误消息"第 N 行：期待 X，遇到 Y"的数据源（第 10 章黄金句式的前端半）。
- 递归下降 `Parser`（~180 行）：`parseFun/parseBlock/parseStmt` 三层 + 表达式四层（cmp→add→mul→unary→atom）——**第 6 章 6.3 节的分层法原样落地**（每层一个函数、优先级住层级）。Louden 路线的手写前端在 TINY（§2.5/§4.4）里也是这个形状——本章是这条路线在教程里的第二次完整实践（第一次是第 65 章的 TINY 前端……按章号是将来时，按写作时序是平行件）。
- 语句分派的**前瞻一眼**：赋值与调用语句都以名字开头，看第二个 token（`=`/`[` vs `(`）分道——递归下降处理"前缀相同产生式"的最小技巧（第 6 章提左因子的手工替代）。
- 错误协议：`want()` 统一抛"第 N 行：期待 X，遇到 Y"——本语言没有错误恢复（第 10 章的机制可以嫁接，练习 9 预告）。

## 22.7　驱动与对账

### 22.7.1　驱动全文

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 22 章驱动（无参运行，走"简单程序"对账协议）：
//   S1 完全静态环境（保留性 + 递归拒绝）→ S2 值传递 → S3 引用传递（含临时格）→
//   S4 值结果（p(a,a) 别名 + 写回序）→ S5 名字传递（p(a,a) + swap 槽位错乱 + Jensen）→
//   S6 四机制总账（同一 p(a,a) 四个答案并排）。
#include "front.hpp"
#include "interp.hpp"

#include <iostream>

namespace {

using plang::PassMode;

// 四机制共用骨架：p 双参自增，实参都是同一个变量 a
std::string pProgram(PassMode m) {
    std::string mode = plang::modeName(m);
    return "fun p(" + mode + " x, " + mode + " y) { x = x + 1; y = y + 1; }\n"
           "fun main() { var a; a = 1; p(a, a); print a; }\n";
}

plang::RunResult runProgram(const std::string &src, bool staticEnv = false) {
    plang::Program p = plang::parse(src);
    plang::Interp it(p, staticEnv);
    return it.run("main");
}

void show(const char *tag, const plang::RunResult &r) {
    std::cout << "[" << tag << "] ok=" << r.ok;
    if (!r.error.empty()) std::cout << " err=" << r.error;
    std::cout << " out=";
    for (const auto &s : r.printed) std::cout << " " << s;
    std::cout << "\n";
}

}  // namespace

int main() {
    // ---------- S1 完全静态运行时环境（§7.2） ----------
    std::cout << "== S1 fully static env ==\n";
    {
        // 局部变量跨调用保留：count 的 c 在两次调用间不清零——"活动记录即全局变量"
        const char *counter =
            "fun count(val step) { var c; c = c + step; return c; }\n"
            "fun main() { var x; x = count(1); x = count(1); x = count(1); print x; }\n";
        show("static  ", runProgram(counter, true));    // 期待 3
        show("stacked ", runProgram(counter, false));   // 期待 1（每次调用新帧）
        // 递归禁令：第二份帧无处安放
        const char *fact =
            "fun fact(val n) { if n <= 1 { return 1; } return n * fact(n - 1); }\n"
            "fun main() { print fact(3); }\n";
        show("rec-static", runProgram(fact, true));     // 期待拒绝
        show("rec-stack ", runProgram(fact, false));    // 期待 6
    }

    // ---------- S2 值传递（§7.5.1） ----------
    std::cout << "== S2 call by value ==\n";
    {
        // inc2 反例（L 书原文程序）：改形参不影响外界——"被初始化了的局部变量"
        const char *inc2 =
            "fun inc2(val x) { x = x + 1; x = x + 1; }\n"
            "fun main() { var y; y = 5; inc2(y); print y; }\n";
        show("inc2-val", runProgram(inc2));   // 期待 5
    }

    // ---------- S3 引用传递（§7.5.2） ----------
    std::cout << "== S3 call by reference ==\n";
    {
        const char *inc2r =
            "fun inc2(ref x) { x = x + 1; x = x + 1; }\n"
            "fun main() { var y; y = 5; inc2(y); print y; }\n";
        show("inc2-ref", runProgram(inc2r));  // 期待 7
        // 表达式实参的临时格：副作用落在临时格、外界无恙
        const char *tmp =
            "fun g(ref z) { z = z + 1; }\n"
            "fun main() { var m; m = 42; g(2 + 3); g(4 + 1); print m; }\n";
        auto r = runProgram(tmp);
        show("expr-arg", r);                  // 期待 42
        for (const auto &t : r.tempCells) std::cout << "    " << t << "\n";
    }

    // ---------- S4 值结果传递（§7.5.3） ----------
    std::cout << "== S4 call by value-result ==\n";
    {
        // 别名分辨器：p(a,a) 下值结果得 2、引用得 3（L 书原文例）
        show("p(a,a) valres", runProgram(pProgram(PassMode::ValRes)));   // 期待 2
        // 写回序（实现口径：声明序 x 先 y 后）：x+1 与 y+10 写同格，后写者胜
        const char *order =
            "fun q(valres x, valres y) { x = x + 1; y = y + 10; }\n"
            "fun main() { var a; a = 1; q(a, a); print a; }\n";
        show("writeback-order", runProgram(order));   // 期待 11（若反序则 2）
    }

    // ---------- S5 名字传递（§7.5.4） ----------
    std::cout << "== S5 call by name ==\n";
    {
        show("p(a,a) name", runProgram(pProgram(PassMode::Name)));   // 期待 3（与引用同形）
        // 经典 swap 反例：名字传递写错槽位（Knuth 的 swap(i, a[i])）
        const char *swapRef =
            "fun swap(ref x, ref y) { var t; t = x; x = y; y = t; }\n"
            "fun main() { var i; array a[6]; i = 2; a[2] = 5; swap(i, a[i]);"
            " print i; print a[2]; print a[5]; }\n";
        show("swap-ref", runProgram(swapRef));     // 期待 5 2 0（正确交换）
        const char *swapName =
            "fun swapn(name x, name y) { var t; t = x; x = y; y = t; }\n"
            "fun main() { var i; array a[6]; i = 2; a[2] = 5; swapn(i, a[i]);"
            " print i; print a[2]; print a[5]; }\n";
        show("swap-name", runProgram(swapName));   // 期待 5 5 2（a[a[i]] 写错槽）
        // Jensen 装置：i 与 term 都是名字传递——被调方改写 i、每次取 term 都重求值
        const char *jensen =
            "fun sum(name i, val n, name term) { var s; s = 0;"
            " for i = 0 to n - 1 do { s = s + term; } return s; }\n"
            "fun main() { var i; var s; array a[3]; a[0] = 1; a[1] = 2; a[2] = 3;"
            " s = sum(i, 3, a[i] * 2); print s; print i; }\n";
        auto r = runProgram(jensen);
        show("jensen", r);                          // 期待 12 与 2（i 终值 = 末次赋值）
        std::cout << "    thunk evals = " << r.thunkEvals << " (i 与 term 的重求值次数)\n";
    }

    // ---------- S6 四机制总账 ----------
    std::cout << "== S6 four modes on p(a,a) ==\n";
    {
        // 同一程序骨架、四个答案并排——别名是唯一分辨器
        for (PassMode m : {PassMode::Val, PassMode::ValRes, PassMode::Ref, PassMode::Name}) {
            auto r = runProgram(pProgram(m));
            std::cout << "  " << plang::modeName(m) << ": a =";
            for (const auto &s : r.printed) std::cout << " " << s;
            std::cout << "\n";
        }
    }
    return 0;
}
```

六节对应六组断言，逐节走读：

- **S1 静态环境**：counter 语料双模式对照（static 3 / stacked 1——保留性证人）；fact 语料双模式（static 拒绝 / stack 6——递归禁令人）。四台 Interp 独立构造（环境模式是构造参数）。
- **S2 值**：inc2 反例（5）——L 书原文程序逐字移植。
- **S3 引用**：inc2 治愈（7）——同一函数体换机制注记；表达式实参的临时格（m=42 + tempCells 两行记录）。注意语料故意让两次调用的表达式值相同（5、5）——排除"值不同导致格不同"的干扰变量，**实验只留机制这一个自变量**。
- **S4 值结果**：别名分辨器（2）；写回序（11）——x+1 与 y+10 制造两个不同终值，让顺序可观察。
- **S5 名字**：p(a,a)=3；swap 双机制（5 2 0 vs 5 5 2）——同一 swap 体、机制换名；Jensen（12、i=2、thunk 3 次）——main 里 a[3] 初始化成 1/2/3、term 是 `a[i]*2`。
- **S6 总账**：`pProgram(mode)` 工厂按机制生成四份同骨架程序——**四答案并排是本章的封面照**。

main 的三个工程细节：

- `pProgram` 用字符串拼接生成语料——四机制只差形参注记，**语料的公共骨架单点维护**（改一处四份全改）；
- `show` 统一打印 ok/error/out 三件套——错误与正常共用一行格式（对账文件因此规整）；
- 每组语料**独立解析、独立构造 Interp**——前一组的状态（temps_、staticFrames_）绝不泄给后一组；这是语料间的隔离纪律（第 9 章四台 MiniYacc 独立构造的同款要求）。

### 22.7.2　期望输出逐段解读

```text
; expected: expected/output.txt
== S1 fully static env ==
[static  ] ok=1 out= 3
[stacked ] ok=1 out= 1
[rec-static] ok=0 err=recursion rejected (static env): fact depth=2 out=
[rec-stack ] ok=1 out= 6
== S2 call by value ==
[inc2-val] ok=1 out= 5
== S3 call by reference ==
[inc2-ref] ok=1 out= 7
[expr-arg] ok=1 out= 42
    g 第1参 表达式实参 -> 临时格 #0 (值 5)
    g 第1参 表达式实参 -> 临时格 #1 (值 5)
== S4 call by value-result ==
[p(a,a) valres] ok=1 out= 2
[writeback-order] ok=1 out= 11
== S5 call by name ==
[p(a,a) name] ok=1 out= 3
[swap-ref] ok=1 out= 5 2 0
[swap-name] ok=1 out= 5 5 2
[jensen] ok=1 out= 12 2
    thunk evals = 3 (i 与 term 的重求值次数)
== S6 four modes on p(a,a) ==
  val: a = 1
  valres: a = 2
  ref: a = 3
  name: a = 3
```

26 行输出的关键行：

- `[static] out= 3` vs `[stacked] out= 1`：同一程序、两种环境——**SAVE 语义的机器证人**（若静态模式的声明每次重落，3 会退化成 1——开发时真踩过，见坑账）。
- `[rec-static] err=recursion rejected (static env): fact depth=2`：递归在进入第二层时被调用环检测抓住——错误消息带函数名与深度。
- `[rec-stack] out= 6`：同一程序换栈模式——递归解禁，正反对照完整。
- `[inc2-val] 5` / `[inc2-ref] 7`：同一函数体、两种机制——L 书 inc2 反例与治愈的成对证人。
- `[expr-arg] out= 42` + 两行临时格：副作用落在 #0/#1 两个临时格，main 无恙。
- `[p(a,a) valres] out= 2` / `[writeback-order] out= 11`：前者是 L 书原文的数字，后者是本章实现口径的自证。
- `[swap-ref] out= 5 2 0` / `[swap-name] out= 5 5 2`：正确交换 vs 槽位错乱——第三列（a[5]）从 0 变 2 是错写的直接证据。
- `[jensen] out= 12 2` + `thunk evals = 3`：和、i 终值、重求值次数三件套——Jensen 的完整账。
- S6 四行：本章全部论点的最终压缩——**一个调用、四个答案**。

### 22.7.2a　与前后章的接口冻结

- `Slot` 的五字段布局（v/ref/out/thunk/arr）——第 60 章上值机制若需复用"名字的运行期形态"一节，以本结构为起点（那是帧世界的续篇，这里是参数世界的版本）。
- `Thunk{expr, env}` 二元组——**与第 15 章闭包的结构等价约定**：后续章节引用 thunk 概念时，指向本定义。
- `PassMode` 枚举与 `modeName`——练习扩展（const ref/out）按尾部追加纪律。
- 手写前端（front.*）——第 65 章 TINY 前端的姊妹件（同为 Louden 手写路线）；两章互不复用（语言不同），但**风格约定一致**：扫描器带行号、want() 的错误句式、前瞻一眼的语句分派。

### 22.7.2b　阅读自检

1. 画 Slot 的五字段表，标出每种机制各用哪几个。
2. p(a,a) 四机制的答案分别怎么算出来的？手推各一遍。
3. swap-name 的三步推演里，第二步 `x = y` 为什么解成 `i = a[i]` 而不是 `i = a[2]`？
4. Jensen 的 thunk evals 为什么恰好 3 而不是 4 或 6？数一数 term 的出现点。
5. 静态模式拒绝递归的实现为什么用"调用环检测"而不是"禁止出现调用自身的函数定义"？（提示：间接递归。）

### 22.7.3　源码导览

| 文件 | 行数 | 角色 |
|---|---|---|
| src/lang.hpp | 55 | AST：四机制注记的形参表 |
| src/front.hpp/cpp | 12+250 | 手写扫描器 + 递归下降（Louden 路线） |
| src/interp.hpp/cpp | 68+290 | 四机制解释器 + 静态环境模式 |
| src/main.cpp | 120 | 六组断言驱动 |
| expected/output.txt | 26 | 全部证人的期望真身 |

全部为本章新码（无副本）——机制章从零造机器，是 Louden 轮四新章里唯一的一台"全自研"。

```cpp
// file: src/lang.hpp
// file: src/lang.hpp
// 第 22 章配套：参数传递教学语言的 AST（L 书 §7.5 的实验台）。
// 语言面：函数 + 四种形参机制注记（val/ref/valres/name）+ 标量与一维数组 +
// 赋值/print/if/while/for/return——刚好够演出四种机制的全部语义差异。
#ifndef TIP_PLANG_HPP
#define TIP_PLANG_HPP

#include <memory>
#include <string>
#include <vector>

namespace plang {

// ---------- 表达式 ----------
struct Expr {
    enum class Kind { Num, Var, Index, Bin, Unary, Call };
    Kind kind;
    double num = 0;                      // Num
    std::string name;                    // Var / Call 的函数名
    std::unique_ptr<Expr> lhs, rhs;      // Bin；Unary 用 lhs；Index 的下标用 lhs
    std::string op;                      // "+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "u-"
    std::vector<std::unique_ptr<Expr>> args;   // Call 的实参表达式
};

// ---------- 语句 ----------
struct Stmt {
    enum class Kind { VarDecl, ArrayDecl, Assign, Print, If, While, For, Return, CallStmt };
    Kind kind;
    std::string name;                    // 声明/赋值目标；CallStmt 的函数名
    std::unique_ptr<Expr> index;         // 数组元素赋值的下标
    std::unique_ptr<Expr> value, cond, from, to;   // 赋值值 / 条件 / for 边界
    std::vector<std::unique_ptr<Stmt>> then, other, body;   // 分支与循环体
    std::vector<std::unique_ptr<Expr>> args;   // CallStmt 的实参表达式
};

// ---------- 函数与形参 ----------
enum class PassMode { Val, Ref, ValRes, Name };

struct Param {
    std::string name;
    PassMode mode;
};

struct Fun {
    std::string name;
    std::vector<Param> params;
    std::vector<std::unique_ptr<Stmt>> body;
};

struct Program {
    std::vector<std::unique_ptr<Fun>> funs;
};

const char *modeName(PassMode m);

}  // namespace plang

#endif  // TIP_PLANG_HPP
```

```cpp
// file: src/front.hpp
// file: src/front.hpp
// 手写扫描器 + 递归下降前端的接口。
#ifndef TIP_PFRONT_HPP
#define TIP_PFRONT_HPP

#include "lang.hpp"

namespace plang {

// 解析整程序；语法错误抛 std::runtime_error（消息带行号——§10.5 的黄金句式雏形）。
Program parse(const std::string &src);

}  // namespace plang

#endif  // TIP_PFRONT_HPP
```

```cpp
// file: src/front.cpp
// file: src/front.cpp
// 手写扫描器 + 递归下降前端（Louden 路线：§2.5 的扫描器风格 + §4.4 的分析程序风格）。
// 不用生成器——本章的主题是运行期语义，前端越朴素越好读。
#include "front.hpp"

#include <cctype>
#include <stdexcept>

namespace plang {

namespace {

// ---------- 扫描器 ----------
struct Tok {
    std::string text;   // 关键字/名字/数字原文，或单符号
    int line;
};

bool isIdentStart(char c) { return std::isalpha(static_cast<unsigned char>(c)) || c == '_'; }
bool isIdentChar(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; }

std::vector<Tok> scan(const std::string &src) {
    std::vector<Tok> out;
    int line = 1;
    size_t i = 0;
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (c == '/' && i + 1 < src.size() && src[i + 1] == '/') {   // 行注释
            while (i < src.size() && src[i] != '\n') ++i;
            continue;
        }
        if (isIdentStart(c)) {
            size_t j = i;
            while (j < src.size() && isIdentChar(src[j])) ++j;
            out.push_back({src.substr(i, j - i), line});
            i = j;
            continue;
        }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            size_t j = i;
            while (j < src.size() && (std::isdigit(static_cast<unsigned char>(src[j])) || src[j] == '.'))
                ++j;
            out.push_back({src.substr(i, j - i), line});
            i = j;
            continue;
        }
        // 两字符运算符
        if (i + 1 < src.size()) {
            std::string two = src.substr(i, 2);
            if (two == "<=" || two == ">=" || two == "==" || two == "!=") {
                out.push_back({two, line});
                i += 2;
                continue;
            }
        }
        out.push_back({std::string(1, c), line});
        ++i;
    }
    return out;
}

// ---------- 递归下降分析器 ----------
// Stmt 的字段多且带 unique_ptr，部分聚合初始化会触发 -Wextra——工厂逐字段赋值。
std::unique_ptr<Stmt> newStmt(Stmt::Kind k) {
    auto st = std::make_unique<Stmt>();
    st->kind = k;
    return st;
}
class Parser {
public:
    explicit Parser(std::vector<Tok> toks) : t_(std::move(toks)) {}

    Program parseProgram() {
        Program p;
        while (!atEnd()) p.funs.push_back(parseFun());
        return p;
    }

private:
    std::vector<Tok> t_;
    size_t i_ = 0;

    bool atEnd() const { return i_ >= t_.size(); }
    const Tok &cur() const {
        static Tok eof{"?", 0};
        if (atEnd()) return eof;
        return t_[i_];
    }
    std::string peek() const { return cur().text; }
    std::string take() { return t_[i_++].text; }
    bool eat(const std::string &s) {
        if (peek() == s) { ++i_; return true; }
        return false;
    }
    void want(const std::string &s) {
        if (!eat(s))
            throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：期待 '" + s +
                                     "'，遇到 '" + cur().text + "'");
    }

    std::unique_ptr<Fun> parseFun() {
        auto f = std::make_unique<Fun>();
        want("fun");
        f->name = take();
        want("(");
        while (peek() != ")") {
            Param pm;
            std::string m = take();
            if (m == "val") pm.mode = PassMode::Val;
            else if (m == "ref") pm.mode = PassMode::Ref;
            else if (m == "valres") pm.mode = PassMode::ValRes;
            else if (m == "name") pm.mode = PassMode::Name;
            else throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：未知机制 '" + m + "'");
            pm.name = take();
            f->params.push_back(pm);
            if (!eat(",")) break;
        }
        want(")");
        f->body = parseBlock();
        return f;
    }

    std::vector<std::unique_ptr<Stmt>> parseBlock() {
        std::vector<std::unique_ptr<Stmt>> out;
        want("{");
        while (peek() != "}") out.push_back(parseStmt());
        want("}");
        return out;
    }

    std::unique_ptr<Stmt> parseStmt() {
        std::string s = peek();
        if (s == "var") {
            ++i_;
            auto st = newStmt(Stmt::Kind::VarDecl);
            st->name = take();
            want(";");
            return st;
        }
        if (s == "array") {
            ++i_;
            auto st = newStmt(Stmt::Kind::ArrayDecl);
            st->name = take();
            want("[");
            st->value = parseExpr();   // 长度（通常是 NUM）
            want("]");
            want(";");
            return st;
        }
        if (s == "print") {
            ++i_;
            auto st = newStmt(Stmt::Kind::Print);
            st->value = parseExpr();
            want(";");
            return st;
        }
        if (s == "if") {
            ++i_;
            auto st = newStmt(Stmt::Kind::If);
            st->cond = parseExpr();
            st->then = parseBlock();
            if (eat("else")) st->other = parseBlock();
            return st;
        }
        if (s == "while") {
            ++i_;
            auto st = newStmt(Stmt::Kind::While);
            st->cond = parseExpr();
            st->body = parseBlock();
            return st;
        }
        if (s == "for") {
            ++i_;
            auto st = newStmt(Stmt::Kind::For);
            st->name = take();
            want("=");
            st->from = parseExpr();
            want("to");
            st->to = parseExpr();
            want("do");
            st->body = parseBlock();
            return st;
        }
        if (s == "return") {
            ++i_;
            auto st = newStmt(Stmt::Kind::Return);
            st->value = parseExpr();
            want(";");
            return st;
        }
        // 赋值或过程调用：看第二个 token
        if (i_ + 1 < t_.size()) {
            const std::string &nxt = t_[i_ + 1].text;
            if (nxt == "=" || nxt == "[") {
                auto st = newStmt(Stmt::Kind::Assign);
                st->name = take();
                if (eat("[")) {
                    st->index = parseExpr();
                    want("]");
                }
                want("=");
                st->value = parseExpr();
                want(";");
                return st;
            }
            if (nxt == "(") {
                auto st = newStmt(Stmt::Kind::CallStmt);
                st->name = take();
                eat("(");
                while (peek() != ")") {
                    st->args.push_back(parseExpr());
                    if (!eat(",")) break;
                }
                want(")");
                want(";");
                return st;
            }
        }
        throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：无法解释的语句起点 '" + s + "'");
    }

    // 表达式：cmp → add → mul → unary → atom（每层一个函数，第 6 章的分层法）
    std::unique_ptr<Expr> parseExpr() { return parseCmp(); }

    std::unique_ptr<Expr> mkBin(std::string op, std::unique_ptr<Expr> a, std::unique_ptr<Expr> b) {
        auto e = std::make_unique<Expr>();
        e->kind = Expr::Kind::Bin;
        e->op = std::move(op);
        e->lhs = std::move(a);
        e->rhs = std::move(b);
        return e;
    }

    std::unique_ptr<Expr> parseCmp() {
        auto a = parseAdd();
        while (peek() == "<" || peek() == "<=" || peek() == ">" || peek() == ">=" ||
               peek() == "==" || peek() == "!=") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseAdd());
        }
        return a;
    }
    std::unique_ptr<Expr> parseAdd() {
        auto a = parseMul();
        while (peek() == "+" || peek() == "-") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseMul());
        }
        return a;
    }
    std::unique_ptr<Expr> parseMul() {
        auto a = parseUnary();
        while (peek() == "*" || peek() == "/") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseUnary());
        }
        return a;
    }
    std::unique_ptr<Expr> parseUnary() {
        if (peek() == "-") {
            ++i_;
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Unary;
            e->op = "u-";
            e->lhs = parseUnary();
            return e;
        }
        return parseAtom();
    }
    std::unique_ptr<Expr> parseAtom() {
        if (eat("(")) {
            auto e = parseExpr();
            want(")");
            return e;
        }
        if (std::isdigit(static_cast<unsigned char>(peek()[0]))) {
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Num;
            e->num = std::stod(take());
            return e;
        }
        if (isIdentStart(peek()[0])) {
            std::string n = take();
            if (eat("(")) {   // 调用
                auto e = std::make_unique<Expr>();
                e->kind = Expr::Kind::Call;
                e->name = n;
                while (peek() != ")") {
                    e->args.push_back(parseExpr());
                    if (!eat(",")) break;
                }
                want(")");
                return e;
            }
            if (eat("[")) {   // 数组元素
                auto e = std::make_unique<Expr>();
                e->kind = Expr::Kind::Index;
                e->name = n;
                e->lhs = parseExpr();
                want("]");
                return e;
            }
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Var;
            e->name = n;
            return e;
        }
        throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：表达式起点非法 '" + peek() + "'");
    }
};

}  // namespace

Program parse(const std::string &src) {
    Parser p(scan(src));
    return p.parseProgram();
}

}  // namespace plang
```

```cpp
// file: src/interp.hpp
// file: src/interp.hpp
// 第 22 章正题：四机制解释器 + 完全静态环境模式（L 书 §7.2/§7.5 的机器化身）。
#ifndef TIP_PINTERP_HPP
#define TIP_PINTERP_HPP

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "lang.hpp"

namespace plang {

// 求值中的非局部退出（return）——第 15 章 ReturnSignal 的同款手法。
struct ReturnSignal {
    double value;
};

// 递归禁令（完全静态模式的诊断）。
struct RecursionRejected {
    std::string fun;
    int depth;
};

struct RunResult {
    bool ok = false;
    std::string error;                    // 语义错误（含行号尽量给）
    std::vector<std::string> printed;     // print 的输出流
    // 机器证人的侧通道：
    long thunkEvals = 0;                  // name 实参的重求值次数
    std::vector<std::string> tempCells;   // ref/valres 表达式实参的临时格记录
};

class Interp {
public:
    // fullyStatic = true：完全静态运行时环境（§7.2）——每函数一帧、跨调用保留、
    // 递归被调用环检测拒绝。false：标准栈环境（每调用一帧）。
    explicit Interp(const Program &p, bool fullyStatic);

    RunResult run(const std::string &entryFun);

private:
    struct Thunk;
    // 槽 = 名字的全部运行期形态。四种机制各占一角：
    //   val/valres 的值都住 v；ref 的别名指 ref；valres 的写回落点指 out（执行期
    //   不读它——值结果的"值"语义靠这个字段与 ref 分开）；name 的延迟体住 thunk。
    struct Slot {
        double v = 0;
        double *ref = nullptr;            // 仅 Ref：执行期别名
        double *out = nullptr;            // 仅 ValRes：出口写回落点
        std::shared_ptr<Thunk> thunk;     // 仅 Name
        std::vector<double> arr;          // 数组
        bool isArray = false;
    };
    struct Thunk {
        const Expr *expr = nullptr;       // 实参表达式（调用方环境里解释）
        std::map<std::string, Slot> *env = nullptr;   // 捕获的调用方帧
    };
    using Frame = std::map<std::string, Slot>;

    const Fun &findFun(const std::string &name) const;
    double eval(const Expr &e, Frame &fr);
    double *evalLValue(const Expr &e, Frame &fr);   // Var/Index 的格子地址
    void exec(const Stmt &s, Frame &fr);
    void execBlock(const std::vector<std::unique_ptr<Stmt>> &body, Frame &fr);
    double call(const Fun &f, const std::vector<std::unique_ptr<Expr>> &args, Frame &caller);

    const Program &prog_;
    bool static_ = false;
    std::map<std::string, Frame> staticFrames_;   // 完全静态模式的函数帧库
    std::vector<std::string> active_;             // 递归检测：调用链上的函数名
    RunResult *res_ = nullptr;
    std::vector<double> temps_;                   // 表达式实参的临时格仓
};

}  // namespace plang

#endif  // TIP_PINTERP_HPP
```

```cpp
// file: src/interp.cpp
// file: src/interp.cpp
// 四机制解释器实现。机制分派全部集中在 call() 的实参绑定段——正文走读的锚点。
#include "interp.hpp"

#include <sstream>
#include <stdexcept>

namespace plang {

namespace {

std::string fmt(double v) {
    std::ostringstream os;
    os << v;
    return os.str();
}

}  // namespace

const char *modeName(PassMode m) {
    switch (m) {
    case PassMode::Val: return "val";
    case PassMode::Ref: return "ref";
    case PassMode::ValRes: return "valres";
    case PassMode::Name: return "name";
    }
    return "?";
}

Interp::Interp(const Program &p, bool fullyStatic) : prog_(p), static_(fullyStatic) {}

const Fun &Interp::findFun(const std::string &name) const {
    for (const auto &f : prog_.funs)
        if (f->name == name) return *f;
    throw std::runtime_error("undefined function: " + name);
}

RunResult Interp::run(const std::string &entryFun) {
    RunResult r;
    res_ = &r;
    try {
        const Fun &main = findFun(entryFun);
        Frame dummy;   // 顶层调用的 caller 帧（空）
        call(main, {}, dummy);
        r.ok = true;
    } catch (const ReturnSignal &) {
        r.ok = true;   // 顶层 return 视为正常结束
    } catch (const RecursionRejected &e) {
        std::ostringstream os;
        os << "recursion rejected (static env): " << e.fun << " depth=" << e.depth;
        r.error = os.str();
    } catch (const std::exception &e) {
        r.error = e.what();
    }
    res_ = nullptr;
    return r;
}

// ---------- 表达式 ----------

double Interp::eval(const Expr &e, Frame &fr) {
    switch (e.kind) {
    case Expr::Kind::Num:
        return e.num;
    case Expr::Kind::Var: {
        auto it = fr.find(e.name);
        if (it == fr.end()) throw std::runtime_error("undefined variable: " + e.name);
        if (it->second.thunk) {   // name 传递：使用处重求值——Jensen 的心脏
            ++res_->thunkEvals;
            return eval(*it->second.thunk->expr, *it->second.thunk->env);
        }
        if (it->second.ref) return *it->second.ref;   // ref/valres 间接读
        return it->second.v;
    }
    case Expr::Kind::Index: {
        double i = eval(*e.lhs, fr);
        auto it = fr.find(e.name);
        if (it == fr.end() || !it->second.isArray)
            throw std::runtime_error("undefined array: " + e.name);
        long k = static_cast<long>(i);
        if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
            throw std::runtime_error("index out of range: " + e.name +
                                     "[" + std::to_string(k) + "]");
        return it->second.arr[static_cast<size_t>(k)];
    }
    case Expr::Kind::Unary:
        return -eval(*e.lhs, fr);
    case Expr::Kind::Bin: {
        double a = eval(*e.lhs, fr), b = eval(*e.rhs, fr);
        if (e.op == "+") return a + b;
        if (e.op == "-") return a - b;
        if (e.op == "*") return a * b;
        if (e.op == "/") return a / b;
        if (e.op == "<") return a < b ? 1 : 0;
        if (e.op == "<=") return a <= b ? 1 : 0;
        if (e.op == ">") return a > b ? 1 : 0;
        if (e.op == ">=") return a >= b ? 1 : 0;
        if (e.op == "==") return a == b ? 1 : 0;
        if (e.op == "!=") return a != b ? 1 : 0;
        throw std::runtime_error("bad op: " + e.op);
    }
    case Expr::Kind::Call: {
        const Fun &f = findFun(e.name);
        return call(f, e.args, fr);
    }
    }
    throw std::runtime_error("bad expr");
}

double *Interp::evalLValue(const Expr &e, Frame &fr) {
    if (e.kind == Expr::Kind::Var) {
        auto it = fr.find(e.name);
        if (it == fr.end()) throw std::runtime_error("undefined variable: " + e.name);
        if (it->second.thunk)   // name 传递的赋值：穿透 thunk 写到调用方的格子
            return evalLValue(*it->second.thunk->expr, *it->second.thunk->env);
        if (it->second.ref) return it->second.ref;
        return &it->second.v;
    }
    if (e.kind == Expr::Kind::Index) {
        double i = eval(*e.lhs, fr);
        auto it = fr.find(e.name);
        if (it == fr.end() || !it->second.isArray)
            throw std::runtime_error("undefined array: " + e.name);
        long k = static_cast<long>(i);
        if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
            throw std::runtime_error("index out of range: " + e.name +
                                     "[" + std::to_string(k) + "]");
        return &it->second.arr[static_cast<size_t>(k)];
    }
    throw std::runtime_error("not an lvalue");
}

// ---------- 语句 ----------

void Interp::execBlock(const std::vector<std::unique_ptr<Stmt>> &body, Frame &fr) {
    for (const auto &s : body) exec(*s, fr);
}

void Interp::exec(const Stmt &s, Frame &fr) {
    switch (s.kind) {
    case Stmt::Kind::VarDecl: {
        // 静态模式：声明只在首次落格（局部变量跨调用保留——§7.2 的 SAVE 语义）；
        // 栈模式：每次调用的新帧里全新落格。
        if (!static_ || fr.find(s.name) == fr.end()) fr[s.name] = Slot{};
        break;
    }
    case Stmt::Kind::ArrayDecl: {
        if (!static_ || fr.find(s.name) == fr.end()) {
            Slot sl;
            sl.isArray = true;
            sl.arr.assign(static_cast<size_t>(eval(*s.value, fr)), 0.0);
            fr[s.name] = std::move(sl);
        }
        break;
    }
    case Stmt::Kind::Assign: {
        double *cell;
        if (s.index) {
            // 数组元素目标：s.name 是数组名、s.index 存的是下标表达式（非 Index 节点）
            auto it = fr.find(s.name);
            if (it == fr.end() || !it->second.isArray)
                throw std::runtime_error("undefined array: " + s.name);
            double i = eval(*s.index, fr);
            long k = static_cast<long>(i);
            if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
                throw std::runtime_error("index out of range: " + s.name +
                                         "[" + std::to_string(k) + "]");
            cell = &it->second.arr[static_cast<size_t>(k)];
        } else {
            cell = evalLValue(Expr{Expr::Kind::Var, 0, s.name, {}, {}, {}, {}}, fr);
        }
        // 先求值右部再写左部（a[i] = i + 1 两边都有 i 时次序可讲）
        double v = eval(*s.value, fr);
        *cell = v;
        break;
    }
    case Stmt::Kind::Print:
        res_->printed.push_back(fmt(eval(*s.value, fr)));
        break;
    case Stmt::Kind::If:
        if (eval(*s.cond, fr) != 0) execBlock(s.then, fr);
        else execBlock(s.other, fr);
        break;
    case Stmt::Kind::While:
        while (eval(*s.cond, fr) != 0) execBlock(s.body, fr);
        break;
    case Stmt::Kind::For: {
        double lo = eval(*s.from, fr), hi = eval(*s.to, fr);
        // i 是当前帧的格子；name 传递时它可能别名到调用方（Jensen 的通道）
        Expr var{Expr::Kind::Var, 0, s.name, {}, {}, {}, {}};
        for (double k = lo; k <= hi; k += 1) {
            *evalLValue(var, fr) = k;
            execBlock(s.body, fr);
        }
        break;
    }
    case Stmt::Kind::Return:
        throw ReturnSignal{eval(*s.value, fr)};
    case Stmt::Kind::CallStmt: {
        const Fun &f = findFun(s.name);
        call(f, s.args, fr);
        break;
    }
    }
}

// ---------- 调用：四机制的分派中心 ----------

double Interp::call(const Fun &f, const std::vector<std::unique_ptr<Expr>> &args, Frame &caller) {
    if (args.size() != f.params.size())
        throw std::runtime_error("arity mismatch: " + f.name + " 期望 " +
                                 std::to_string(f.params.size()) + " 实给 " +
                                 std::to_string(args.size()));
    // 完全静态模式：递归 = 第二份帧无处安放——调用环检测直接拒绝
    if (static_) {
        for (const auto &a : active_)
            if (a == f.name) throw RecursionRejected{f.name, static_cast<int>(active_.size())};
        active_.push_back(f.name);
    }

    // 帧的两种住法（§7.2 vs §7.3 的全部区别就在这四行）：
    //   静态模式：每函数一帧、住在 staticFrames_ 里、跨调用保留；
    //   栈模式：  每次调用一帧、随返回消亡（shared_ptr 撑到 return，thunk 捕获安全）。
    auto keepAlive = std::make_shared<Frame>();
    Frame &frame = static_ ? staticFrames_[f.name] : *keepAlive;

    // —— 形参绑定（正文走读锚点）：四机制的全部差别在这一个 switch ——
    for (size_t k = 0; k < args.size(); ++k) {
        const Param &pm = f.params[k];
        const Expr &a = *args[k];
        Slot &slot = frame[pm.name];
        slot.isArray = false;
        switch (pm.mode) {
        case PassMode::Val:
            slot.ref = nullptr;
            slot.out = nullptr;
            slot.thunk = nullptr;
            slot.v = eval(a, caller);
            break;
        case PassMode::Ref:
            // 实参必须是左值；表达式实参造临时格（FORTRAN 77 的官方姿势，§7.5.2）
            slot.thunk = nullptr;
            slot.out = nullptr;
            if (a.kind == Expr::Kind::Var || a.kind == Expr::Kind::Index) {
                slot.ref = evalLValue(a, caller);
            } else {
                temps_.push_back(eval(a, caller));
                slot.ref = &temps_.back();
                std::ostringstream os;
                os << f.name << " 第" << (k + 1) << "参 表达式实参 -> 临时格 #" << (temps_.size() - 1)
                   << " (值 " << temps_.back() << ")";
                res_->tempCells.push_back(os.str());
            }
            break;
        case PassMode::ValRes: {
            // 入口取地址、拷入 v；执行期读写全走 v（值语义）；出口按声明序把 v
            // 写回 out（实现口径注明：L 书 §7.5.3 指出写回顺序与地址重算时机未指定）
            slot.thunk = nullptr;
            slot.ref = nullptr;
            double *src = evalLValue(a, caller);
            slot.out = src;
            slot.v = *src;
            break;
        }
        case PassMode::Name: {
            // 延迟求值：实参表达式 + 调用方帧原样封存，使用处才解释（§7.5.4 thunk）
            auto th = std::make_shared<Thunk>();
            th->expr = &a;
            th->env = &caller;
            slot.ref = nullptr;
            slot.out = nullptr;
            slot.thunk = std::move(th);
            break;
        }
        }
    }

    double ret = 0;
    try {
        execBlock(f.body, frame);
    } catch (ReturnSignal &sig) {
        ret = sig.value;
    }
    // 值结果的出口写回（声明序）
    for (size_t k = 0; k < args.size(); ++k) {
        const Param &pm = f.params[k];
        if (pm.mode != PassMode::ValRes) continue;
        Slot &slot = frame[pm.name];
        *slot.out = slot.v;
    }

    if (static_) active_.pop_back();
    return ret;
}

}  // namespace plang
```

## 22.7a　interp.cpp 逐函数走读

**Slot 的五字段**（值宇宙的最小分格）：

- `v`：值的家——val/valres 的执行期存储；
- `ref`：引用别名——**仅 Ref 模式**在执行期被读（坑二的教训：valres 不得共用）；
- `out`：写回落点——**仅 ValRes**，绑定时装、出口用，执行期不碰；
- `thunk`：名字延迟体——**仅 Name**；
- `arr/isArray`：数组载荷（本语言数组只按值整体存在槽里；元素级引用经 evalLValue 现算地址）。

四机制占四角、互不串门——**字段与机制一一对应**是本章实现能自证的关键（坑二正是串门的代价）。

**eval / evalLValue 双通道**：

- `eval(e, fr)`：右值——thunk 槽触发**重求值**（计数器在这里跳）；ref 槽间接读；否则读 v。
- `evalLValue(e, fr)`：左值——thunk 槽**递归穿透**到捕获环境里再定址（写通道）；ref 槽返回别名地址；否则返回 &v。
- 两条通道对 Var/Index 的分派完全平行——**名字传递的读写都穿透**，漏掉任何一半，swap 或 Jensen 就塌（§22.5.1 的实现注记）。
- 数组越界在两条通道里都查——诊断带数组名与下标值。

**exec 的语句分派**：

- 声明两分支：静态模式"首次才落格"（坑一的修复）、栈模式每帧重落——两行代码隔着一个时代（§22.1.2）。
- 赋值分支：数组目标是"查槽 + 求下标 + 取元素址"三步（坑三的修复形态）；标量目标走 evalLValue（thunk/ref 都能穿透）。**先求右部再写左部**——`a[i] = i + 1` 的求值次序因此可讲（右部的 i 用旧值）。
- For 分支：内部循环变量 k 逐圈写入**目标格子**（evalLValue 定址）——目标可能是本帧变量，也可能是名字形参穿透到调用方——Jensen 的通道就是这两行。
- Return：抛 `ReturnSignal`——非局部退出的异常实现（与第 15 章同款；备选的"结果参数层层透传"方案在 15 章正文有对比）。

**call 的机制分派中心**（正文的锚点）：

1. 元数检查；静态模式做调用环检测（`active_` 链）。
2. 帧的取得：静态模式 `staticFrames_[name]`（每函数一帧）、栈模式新 `shared_ptr<Frame>`（thunk 捕获安全性——帧要活过调用方返回，教学实现统一用堆帧）。
3. **绑定 switch**（四机制的全部差别）：
   - Val：`v = eval(实参, caller)`——一次求值、拷贝；
   - Ref：Var/Index 实参 `ref = evalLValue(...)`；表达式实参进 `temps_` 仓（临时格记录进 RunResult 的侧通道）；
   - ValRes：`out = evalLValue(...)`、`v = *out`——地址与值分开装；
   - Name：`thunk = {&实参, &caller}`——不求值、只封装。
4. 执行体、捕 ReturnSignal。
5. **写回循环**（仅 ValRes）：声明序遍历、`*out = v`——实现口径注释里写明 L 书的未指定条款。
6. 静态模式弹出 active_。

六步里第 3 步是机制章的心脏、第 5 步是未指定条款的落点——正文各有一节对账。

**RunResult 的侧通道**：`printed`（输出对账）、`thunkEvals`（Jensen 计数）、`tempCells`（临时格记录）——**机器证人的三条输出线**，expected 文件逐字节锁定。

## 22.7b　历史深潜：四种机制的设计史

机制不是同时发明的，它们的次序反映了"运行时环境"概念的成熟史：

- **1958 FORTRAN II**：只有引用传递（实现上常做值结果优化——语义上两者在无别名的 FORTRAN 程序里不可区分，标准干脆宣布不定义）。完全静态环境是那个时代唯一可想的方案——栈还没进语言设计者的工具箱。
- **1960 Algol 60**：名字传递作为**默认**——设计者（Backus、Naur 一代）追求语义的数学纯度：调用即换名（copy rule，β-归约的直译）。thunk 是实现层补上的工程妥协。Algol 同时引入栈环境（递归第一次合法）——**名字传递与栈环境同年出生**，这不是巧合：换名的环境捕获逼出了对运行时环境的想象。
- **1968 Algol 68**：提供 value 与 value-and-result（名字降为可选）——工程派的第一轮反攻。
- **1970 Pascal**：Wirth 把选择权交给声明（`var` vs 缺省值）——**机制成为类型系统的一部分**（实参必须匹配形参的机制要求：var 要左值）。这是本章教学语法的直系祖先。
- **1972 C**：只有值——Ritchie 的极简主义。数组的退化传递是"值的语义、引用的效果"的历史偶合（BCPL 的指针血统）。
- **1983 Ada**：in / out / in out 三档 + "不得依赖实现"条款——**把未指定变成程序员契约**，语言设计处理实现自由的范式转移。
- **1985 C++**：`&` 引用入 C 家族；九十年代补 `const&`（大对象免拷贝 + 静态只读检查）——工程实用的最终形态。
- **1990s–**：Java/C#/Python 清一色"引用的值传递"；Haskell 把 thunk + 记忆化升格为求值策略本体（call-by-need）。**四种古典机制收缩成两种活着的日常（值、引用的值）+ 一种活着的技术（thunk）**。

这条史的读法：**每一次机制增减都是"表达力 vs 实现成本 vs 可推理性"的再平衡**。名字传递输在后两项；值结果败于第一项（别名坑）；引用与值活到今天因为它们各占一个清晰的生态位（可变共享 vs 隔离）。

## 22.7c　机制 × 数据形状：矩阵讨论

L 书 §7.5 各小节都有一段"什么时候用这档"的讨论，合成一张机制 × 数据形状的矩阵：

| 数据形状 | 值 | 引用 | 值结果 | 名字 |
|---|---|---|---|---|
| 小标量（int/double） | ✓ 默认 | 想让函数改它 | 想拿回多个结果 | 玩具 |
| 大结构/数组 | ✗ 拷贝贵 | ✓（C++ 加 const） | ✗ 双份拷贝 | ✗ |
| 只读大对象 | ✗ 贵 | ✓ const& | — | — |
| 要改的原地数据 | ✗ | ✓ | △（别名坑） | ✗ |
| "逻辑上每次重看"的量 | — | — | — | ✓（Jensen 一族） |

矩阵的三条断崖：

- 大对象 + 值 = 拷贝灾难（一毫秒的函数调一秒的拷贝）——C 程序员手动传指针、C++ 用 const& 的经济动因；
- 值结果 + 别名 = 语义悬崖——Ada 的"不得依赖"就是给这个格子贴的封条；
- 名字传递在现代语言里只剩格子外的遗产（lambda）。

**矩阵是选型表，不是评分表**——每种机制在其格子里都是正确的；错误的是把机制用错格子（给大数组用值传递）或用机制弥补语言缺陷（用输出参数模拟多返回值——现代语言有元组/解构后，这一用法正在退场）。

### 22.7d　一次调用的六步走读（拿 inc2-ref 当标本）

`inc2(y)`（ref 版）在 call() 里的完整旅程，逐行对代码：

1. **元数检查**：args.size()==1 == params.size()==1 ✓。
2. **环检测**：栈模式跳过（static_ 为假）。
3. **帧取得**：`keepAlive = make_shared<Frame>()`——inc2 的新帧上堆；这是"栈模式"的解释器版（真机是栈帧，这里是堆帧，生命周期等价：随调用生死）。
4. **绑定 switch（k=0）**：pm.mode==Ref、实参 `y` 是 Var——
   - `slot.ref = evalLValue(Var y, caller)`；
   - evalLValue 在 main 帧找到 y 的槽：无 thunk、无 ref → 返回 `&slot.v`；
   - x 的槽现在：v=0（没用）、ref=&main.y、out=nullptr、thunk=nullptr。
5. **执行体**：`x = x + 1` 两遍——
   - Assign：evalLValue(Var x) → slot.ref = &main.y（别名地址）；
   - eval(Bin(x+1)) → eval(Var x) → *ref = 5（第一次）→ +1 = 6；
   - 写：*(&main.y) = 6；第二遍同理 6→7；
   - **x 的槽.v 从头到尾没人碰**——引用模式下 v 字段是死重（这正是坑二的病灶处：valres 误用此通道）。
6. **返回与写回**：无 ReturnSignal（自然结束）→ ret=0；无 valres → 无写回；keepAlive 析构（帧消亡），main.y = 7 留在 main 的帧里。

六步里第 4 步 3 行、第 5 步每语句 3 行——**总共十几行代码承载了本节三页的语义讨论**。读者把这段走读与 §22.3.1 的逐步账对照，机制的全部零件就都摸过一遍了。

### 22.7e　输出格式的稳定性约定

expected 的 26 行要经得起 check_example 的逐字节比对，格式约定因此是"协议"：

- `[标签] ok=1 out= v1 v2`——ok 与输出值一行；错误时 `err=...` 接在中间；
- 侧通道行缩进四格（`    g 第1参 ...`、`    thunk evals = ...`）——与主行视觉分层；
- 多值输出空格分隔（swap 的三列）——不加逗号，省转义；
- 章内不改格式——README 的解读段（§22.7.2）按行号引用输出，格式一改全章的页码锚点全动。

这套约定从第 4 章沿用至今——**教程的 expected 文件不只是测试，是正文引用的稳定锚文本**。

## 22.8　本章开发的真坑复盘（四个，全部真实发生）

**坑一：静态模式局部声明重落（症状：static 也是 1）**。

- 症状：counter 语料双模式都输出 1——静态帧的保留性没生效。
- 定位：S1 的 3/1 对照直接暴露；读 exec 的 VarDecl 分支。
- 根因：`fr[s.name] = Slot{}` 每次调用都执行——**声明把静态帧里的旧值清掉了**。静态语义要求声明只在首次落格（SAVE）。
- 修复：`if (!static_ || fr.find(s.name) == fr.end())` 才落格。
- 迁移："声明 = 分配 + 初始化"在栈世界天然成立，在静态世界必须拆开——**初始化时机是环境模型的一部分**。

**坑二：valres 被做成引用（症状：p(a,a) valres 得 1）**。

- 症状：S4 输出 1（值传递的答案），不是 2。
- 定位：slot 同时有 ref 与 v，执行期的读写走了 ref（别名通道）。
- 根因：Slot 的 ref 字段被 ref 与 valres 共用——**值结果在执行期必须是值语义**，地址只能留到出口。
- 修复：Slot 加独立的 `out` 字段（写回落点），执行期读写只看 v。
- 迁移：**一个字段两种用途是状态机的隐形炸弹**——两种机制哪怕只差"什么时候用地址"，也要分成两个字段。

**坑三：数组赋值把下标当 lvalue（症状：swap/jensen 全崩，"not an lvalue"）**。

- 症状：所有含数组元素赋值的语料报 not an lvalue。
- 定位：探针打印 evalLValue 收到的 kind=0（Num）——`a[2] = 5` 的 AST 里 s.index 存的是**下标表达式**（Num 2），不是 Index 节点。
- 根因：Assign 的设计里数组目标拆成 name + 下标两字段，执行时我却把 s.index 整个喂给 evalLValue——**结构拆开存，执行却按整节点用**。
- 修复：Assign 的数组分支改为"查数组槽 + 求值下标 + 取元素地址"三步。
- 迁移：AST 的形状约定（拆开存 vs 整节点）必须在**每个消费点**一致——设计文档里写下来的形状，执行代码里每一处都要对着数。

**坑四：循环体语法与语料不匹配（症状：Jensen 报"期待 '{'，遇到 's'"）**。

- 症状：S5 之前整章崩在解析。
- 定位：错误消息直指 do 之后——语料写的是 `do s = s + term;`（单语句），文法要求块。
- 根因：**语言设计（do 后必须块）与语料习惯（C 风格单语句）不一致**——写语料时手比文法快。
- 修复：语料补花括号（`do { s = s + term; }`）。
- 迁移：教学语言定语法时的自检法——**先写十个语料再定文法**，语料里的自然写法就是文法该接受的样子；反过来定文法再写语料，必然踩这条。

四坑的分布：坑一在环境模型、坑二在机制分派、坑三/四在 AST 形状——**语义章的坑全部在"模型与表示的接缝"**，与第 9/10 章的接缝律一脉相承。

**坑账的方法论注脚**：本章四坑全部由**对账断言**当场抓住（S1 的 3/1 抓坑一、S4 的 2 抓坑二、swap 的崩溃抓坑三、解析报错抓坑四）——没有一个靠 code review 先行发现。这是"断言先于修复"的又一实证：**为每个语义论点写一条机器证人，证人顺带当守卫**。四坑修复后全部写进正文（你刚读完的四段），开发成本转化为教学材料——教程开发与写作的循环增益。

### 22.2a　求值时机的暗坑：实参求值顺序

值传递的"调用时求值一次"里藏着一个语言设计的暗坑：**多个实参之间谁先求值？** C 与 C++ 都**未指定**（comma 运算符除外），`p(f(), g())` 若 f、g 有共享副作用，结果不可预言。C++17 起给部分运算定了序（函数实参仍不定序但每个实参的求值完整 indivisible）；Java 规定左到右；Scheme 语言的报告干脆明说"未指定"。

本章解释器按 args 的下标序求值（与写下的顺序一致）——教学口径的确定性换来可对账；真实编译器为寄存器分配的方便会打乱顺序。**"未指定"与"实现自选"贯穿本章**：写回序（§22.4.2）、地址重算、求值序——同一族语言设计决策，教科书里它们散在各章，机制章把它们串成一条线。

### 22.4.2a　Ada 的三档与实现自由

Ada 把机制做成参数方向（in/out/in out），并**明文允许** in out 用引用或值结果实现（L 书 §7.5.3 的总结）：

- 程序员声明的是**意图**（读/写/读写），不是机制；
- 编译器选**实现**（标量常用值结果、大对象常用引用）；
- 依赖两者差异的程序 = 错误程序——别名行为被划出规范之外。

GNAT（GCC 的 Ada 前端）的实际策略：标量 in out 走值结果、记录与数组走引用——**按数据形状自动选机制**，§22.7c 矩阵的自动化版本。语言设计的层次感在这份安排里非常清楚：意图层（方向）、实现层（机制）、契约层（不得依赖）——三层各司其职，比 Pascal 的"var 一刀切"和 C 的"只有值"都更有表达力。

### 22.6c　编译器视角总表：六行账

L 书 §7.5 每小节都有"对编译程序的要求"段落——合并成一张六行账（本章各节的落点对照）：

| 机制 | 实参求值时机 | 调用序列增量 | 帧布局增量 | 访问代码 | 返回时 | 别名风险 |
|---|---|---|---|---|---|---|
| 值 | 调用时一次 | 求值+拷贝 | 参数槽=普通局部 | 直读直写 | 无 | 无 |
| 引用 | 调用时取址 | 取址（或造临时格） | 参数槽=地址 | **间接** | 无 | 有（别名） |
| 值结果 | 入口取址+拷值 | 取址+拷贝 | 地址槽+值槽 | 直读直写 | **写回**（序自选） | 入口快照下无 |
| 名字 | **不求值** | 封装 thunk | 参数槽=thunk 指针 | **thunk 调用** | 无 | 有（穿透） |

四行 × 六列 = 二十四格——每格在本章正文与代码里都有对应物：求值时机在 call() 的绑定 switch、帧布局在 Slot 五字段、访问代码在 eval/evalLValue 双通道、返回时在写回循环。**表格的每格都能翻到代码行**，这是机制章"讲清楚"的验收标准。

### 22.6d　教学语言与教程各章语言的机制对照

| 章 | 语言 | 机制 |
|---|---|---|
| 03（TIP 导览） | TIP | 值（含指针值的拷贝——引用效果） |
| 15 | 闭包树遍历 | 值 + 环境捕获（函数值） |
| 55→58 | 单遍编译 | 值（栈槽位拷贝） |
| 57→60 | 上值 VM | 值 + 捕获上值 |
| 本章 | 教学语言 | **四机制全谱** |
| 65 | TINY→TM | 值（TM 的 dMem 格拷贝） |

教程的主线语言一直只用值传递（与 TIP/Lox 的谱系一致）；本章是唯一的机制动物园。**主线教值、专章教谱**——这个安排与 L 书相同（TINY 用值传递，§7.5 专门展开机制论），教学上的道理一致：先在一种机制下把编译/解释的全流程走顺，再换机制看语义怎样流动。

## 22.9　小结与练习

本章把 L 书 §7.2 与 §7.5 的全部机制做进一台解释器：完全静态环境（保留性 + 递归禁令）、值（初始化的局部变量）、引用（别名 + 临时格）、值结果（入口拷出口写 + 未指定的两件事）、名字（thunk + Jensen + swap 陷阱）。核心数字一组：**p(a,a) 四机制四答案 1/2/3/3，swap 双机制 5 2 0 vs 5 5 2，Jensen 12 与 3 次重求值**——每个论点都有机器证人。

### 22.9.1　课堂推演剧本：S6 四答案的逐步账

拿封面照（四机制同骨架）做一次完整的课堂推演——每格的"变量追踪表"（p 的函数体是 `x = x + 1; y = y + 1;`，实参都是 a，a 初值 1）：

- **val：a=1**
  - 绑定：x←1、y←1（两份拷贝，与 a 脱钩）；
  - x=x+1 → x=2；y=y+1 → y=2；
  - 返回：无写回；a 读自己的格 → **1**。
- **valres：a=2**
  - 绑定：x←1（记 out=&a）、y←1（记 out=&a）；
  - 执行同 val：x=2、y=2；
  - 出口（声明序）：*(&a)←2；*(&a)←2——两次写同一格，终值 **2**。
- **ref：a=3**
  - 绑定：x.ref=&a、y.ref=&a——双别名；
  - x=x+1：读 *ref（1）+1 写回 → a=2；
  - y=y+1：读 *ref（**2**）+1 → a=3；
  - 终值 **3**——两次加法在同一格上串联。
- **name：a=3**
  - 绑定：x、y 各封 thunk（表达式都是"a"，环境都是 main）；
  - x=x+1：读穿透 → a=1，+1 写穿透 → a=2；
  - y=y+1：读穿透 → a=**2**，+1 → a=3；
  - 终值 **3**——与 ref 同形（本语料 thunk 恰是纯变量，行为退化为别名）。

四张追踪表并排，机制的全部语义差异一屏尽收：**val 的隔离、valres 的快照、ref 的串联、name 的穿透**。教学时这页可以当板书——先遮住结果列让学生填，再跑 S6 对答案。

### 22.9.2　机制谱系图与三组数字

谱系（箭头 = 语义包含或退化关系）：

- 严格一档：**值**（隔离世界）；
- 严格 + 地址：**引用**（别名世界；退化：实参恰为纯变量时与 name 同形）；
- 值 + 出口快照：**值结果**（无别名时与引用全同；有别名时独自一格）；
- 延迟族：**名字**（延迟+每次）→ call-by-need（延迟+一次）→ 严格（不延迟+一次）——缓存与时机两个旋钮的正交家族。

本章的三组封面数字，各自的证明对象：

- **1/2/3/3**（p(a,a)）——机制在别名下的可分辨性；
- **5 2 0 vs 5 5 2**（swap）——名字与引用在"下标会变"时的行为分裂；
- **12 / 2 / 3**（Jensen）——延迟求值的表达力账（和、穿透的循环变量、重求值次数）。

三组数字合起来，L 书 §7.5 的全部要点各有一证——**教材的论述变成机器的报告**，这是 Louden 轮每一章的同一句结尾。

### 22.9.3　课堂使用建议

本章的六段输出天然是六道课堂实验，建议的用法：

- **第一课（机制直觉）**：只放 S2/S3（inc2 两版）——学生先猜再跑；引出"同一函数体、两种语义"的钩子；
- **第二课（别名分辨器）**：S4 的 p(a,a)——让学生设计"如何区分引用与值结果"的实验（答案是制造别名），再放 S6 四答案对账；
- **第三课（延迟求值）**：S5 三连——swap 预言游戏（上面三堂会审）→ Jensen 逐圈表（§22.5.2）→ thunk evals 计数与"使用次数"的对应；
- **收尾（环境维度）**：S1 的 3/1 与拒绝——抛出"栈买来了什么"（§22.1.2 的对照表），预告第 23 章堆的第三维度。

每课的共性动作：**先预言、再运行、后推演**——机器证人的教学价值不在"它跑对了"，而在它跑出的数字能当场裁决学生的预言。这也是全部九章新章共享的课堂语法。

**术语速查**：

- **完全静态环境**：每函数一帧、地址编译期定、递归禁止——FORTRAN 77 的世界。
- **SAVE 语义**：静态帧的局部变量跨调用保留——声明只在首次落格。
- **值传递**：形参 = 被初始化的局部变量；改动不外泄。
- **引用传递**：形参 = 实参的别名；间接读写。
- **临时格**：表达式实参的匿名存储——FORTRAN 给 `p(2+3)` 造的家。
- **值结果**：入口拷入、出口写回；别名下与引用分歧。
- **名字传递**：实参封 thunk、使用处重求值；thunk = 闭包的最小形态。
- **Jensen 装置**：循环变量与循环体都传名字——一个函数、一族行为。
- **别名**：同一存储的多个名字——分辨机制的唯一实验器。
- **写回序**：值结果多参出口的顺序——语言间未指定，实现自选。
- **call-by-need**：名字传递加记忆化——延迟+只算一次，Haskell 的求值策略。
- **restrict**：C 的无别名承诺关键字——契约换优化的样本。
- **换名规则（copy rule）**：Algol 60 报告的名字传递语义——调用即 β-归约。
- **不可重入**：静态环境的契约面——帧只有一份，递归即违约。

**再补五条阅读自检**：

1. 临时格是谁造的、住哪、什么时候死？三种语言（FORTRAN/C++/本章）各怎么防它的陷阱？
2. thunk 的读写双通道各在哪段代码？漏掉写通道，哪组语料第一个崩？
3. call-by-name 与 call-by-need 在什么语料上分歧？为什么 Jensen 必须用前者？
4. Ada 为什么敢说"in out 不得依赖实现"？这条契约把哪类程序划为非法？
5. 传函数为什么要带环境？C 函数指针为什么可以不带？

**与 L 书的取材对照**：§7.2 → 本章 §22.1；§7.5.1–7.5.4 → §22.2–22.5；§7.3.3 → §22.6；§1.5（参数传递对语言设计的影响）融进各节的"谁在用"。原书的 Pascal/Ada/C++ 语法对照（var/in out/&, const&）在 §22.3.3 与 §22.4 各就各位。

**语料全集表**（八组语料与各自的证明对象）：

| 语料 | 断言 | 期望 |
|---|---|---|
| counter（三连调） | SAVE 语义 | static 3 / stack 1 |
| fact(3) | 递归禁令 | static 拒 / stack 6 |
| inc2(val x) | 值不外泄 | 5 |
| inc2(ref x) | 别名写入 | 7 |
| g(2+3); g(4+1) | 临时格 | m=42、格 #0/#1 |
| p(a,a) × 4 机制 | 别名分辨器 | 1/2/3/3 |
| q(a,a) 双 valres | 写回序 | 11（声明序） |
| swap(i,a[i]) × 2 | 槽位错乱 | 5 2 0 vs 5 5 2 |
| sum(i,3,a[i]*2) | Jensen 装置 | 12、i=2、thunk 3 |

九组语料、每组分到一个论点——**语料与断言一一对应**是机制章对账纪律的骨架（一鱼一吃，不许多钓）。

**FAQ**：

- **问：C++ 的引用与本章 ref 完全一样吗？** 答：语义核心一样（别名）；C++ 还有引用折叠、右值引用（`&&`）等类型系统层的设计，那是另一门课的深度。本章管的是运行时机制。
- **问：Java/C#/Python 的对象传参是哪一档？** 答：**值传递（传引用的值）**——变量槽里装对象引用，拷贝的是引用。行为上像"引用传递可改内容、不可改绑定"——`swap` 对象字段的写穿透、对象变量本身的交换失败，正是这条的日常证据。
- **问：为什么现代语言不再提供名字传递？** 答：表达力被闭包与高阶函数取代（要延迟就传 lambda）、实现与推理成本又高——Jensen 的求和，今天写 `sum(range(3), lambda i: a[i]*2)`。**thunk 从语言特性降级为实现技术**（惰性求值内部仍在用）。
- **问：值结果的写回序真的重要吗？** 答：只在别名时可见（q 语料的 11 vs 2）——无别名的程序两序无差。Ada 把它划入"不得依赖"正是承认这一点：**为病态语料定规范不值得，禁掉更便宜**。
- **问：完全静态环境今天还有吗？** 答：有——中断处理程序、内核的 per-CPU 区、协程的静态上下文，以及一切"不可重入"的老代码。递归禁令从限制变成了**契约**：不可重入 = 帧只有一份。
- **问：解释器的 temps_ 仓为什么是全局的？** 答：偷懒的教学取舍——真实编译器把临时格放调用者帧（随调用生死）。全局仓的后果是临时格永不回收（本章语料几十个、无碍）；练习 6 可以把它挪进帧。
- **问：为什么用异常实现 return？** 答：非局部退出的教学最省实现（第 15 章同款）；编译器实现是"写返回值槽 + epilogue 跳转"——第 65 章 TM 的代码生成会把那个版本写出来。两种实现的对照是"解释器便利 vs 编译器直白"的常课。
- **问：本语言有 else-if 吗？** 答：else 后必须块——`else { if ... }` 是 else-if 的正规写法（ALGOL/Pascal 传统）。文法不特设 elseif 分支（C 系的 else if 是"else 后单语句"的连击），块的强制让悬挂 else 类歧义在本语言根本不存在——第 6/10 章的老朋友在这里被文法设计提前解决了。
- **问：thunk 里的环境指针为什么是裸指针 Frame*？** 答：教学语料里调用方帧一定活得比被调方久（没有逃逸的闭包）——裸指针够用且暴露机制。一旦允许函数值逃逸（练习 5），就必须换 shared_ptr 链——第 60 章上值的完整剧情。
- **问：为什么实参个数不匹配是运行期错误而不是解析期？** 答：教学前端不解引用（名字解析留给解释器查 funs 表）；工业前端有符号表，元数检查在编译期。想前移的话：解析后扫一遍 funs 表即可——练习留给读者，机制在 §22.6 的"代码地址单传"讨论里已有影子。
- **问：本章的 for 是语句不是表达式，Jensen 还能再玄学一点吗？** 答：能——Algol 68 的传值子句（call-by-value 的循环）能写出"sum 里嵌 sum"的二维装置；再玄学就要上 continuation 了。教学语言的 for-do 已够展示机制，深水区留给函数式语言的教程分支。
- **问：valres 的入口拷贝什么时候被读？** 答：函数体第一次读形参时（此前只是躺在槽里）；若函数体从不读形参、只写——valres 退化成"结果传递"（练习 2 的 out 档）——机制的组合里藏着子机制。

**常见误解辨析**（每条先给误解、再给正解）：

- 误解一："值传递的参数改动绝对不会影响外界。" 正解：**值本身**不影响；但值里装着地址时（指针/引用的值），通过它写**指向的内容**会穿透——C 数组与 Java 对象都走这条缝。"影响外界"要区分"改绑定"与"改指向物"。
- 误解二："引用传递就是传地址。" 正解：语义上引用是**别名**（语言概念），地址是实现（编译器概念）；FORTRAN 的引用传的是"静态格的地址"、Pascal 的 var 在栈帧上走间接——同一语义、不同实现。反过来，C 传指针是值语义装着地址——机制上是值传递。
- 误解三："值结果 = 值 + 引用之和。" 正解：值结果在**执行期**是纯值语义（无别名——坑二的病根就是把这句实现错了）；引用的"实时性"它没有、值的"隔离性"它只在执行期有。出口的写回是一次性快照——函数中途的中间值外界永远看不见。
- 误解四："Jensen 装置证明名字传递更强。" 正解：它证明名字传递**更可编程**（被调方获得了调用方求值的控制权）；"强"要看维度——可推理性维度它是负分（swap 反例）。现代语言用高阶函数拿到同样的控制权而不付 trap 的代价。
- 误解五："静态环境是历史化石。" 正解：不可重入代码（中断处理、信号处理、老式协程）至今活在静态环境里；**"帧只有一份"从限制变成契约**——理解它才能安全地与这些代码共存。

**练习**（前四题有解答要点）：

1. 给机制表加第五档 `const ref`（C++ 的 const 引用）：绑定时同 ref，但**静态检查**形参不出现在赋值左边。语料：大数组求和 `total(const ref a)`——违规语料（赋值 a[i]）须被拒绝。（要点：前端在函数体里扫形参名的赋值目标；数组的 const 引用还要禁 `a[i] = ...`。）
2. 加"结果传递"（call by result，Ada 的 out）：只有出口写回、入口不拷。`p(out x) { x = 1; }` 传 a 得 1；`p(a,a)` 双 out 得几？（要点：写回声明序——后写者胜，2 个 out 各写 1，答案 1；与 valres 的区别在入口值。）
3. 把 thunk evals 计数器扩展成**分参数计数**（每个 name 形参各计各的），Jensen 语料里 i 与 term 的次数各多少？（要点：i 的写走 lvalue 通道不计、读走 eval 计——for 的边界比较若用 i 会计进；term 恰 3。）
4. 实现地址重算的另一种口径（出口重取实参地址）：`q(valres x, valres y)` 传 `(a, a[i])` 且函数内先改 i——两种口径下 a 的哪个元素被写回？（要点：入口取址写 a[i₀]、出口重取写 a[i_new]；构造 i 从 0 改到 1 的语料，两口径分别落 a[0] 与 a[1]。）
5. （进阶）给语言加嵌套函数定义，让 thunk 捕获的环境链变长——这与第 15 章的 Environment 链如何对接？
6. （进阶）测量四种机制的调用开销：给 call() 加计时（或指令计数），同一循环语料跑四档，报告相对成本。
7. （进阶）把 swap(i, a[i]) 推广成 swap(i, a[i], b[j])——构造一个三名字机制下错误更隐蔽的语料，手工预言再验证。
8. （大题）在静态模式里实现"递归可用但每函数仍一帧"的作弊版（把递归调用的帧临时压栈、返回后弹）——它与真栈环境的差异在哪些语料上暴露？（提示：地址稳定性——递归期间外层帧的地址没变，别名行为不同。）

**练习 5–8 解答要点**：

5. 嵌套函数：Fun 结构加 enclosing 指针、Frame 加 parent 链——thunk 的 env 捕获从"一层帧"变"帧链"，eval/evalLValue 沿链查找（第 15 章 Environment 的 recolor 版）。真正的深水区在嵌套函数**逃逸**后被调用时——环境链要堆分配，接上第 60 章上值的剧情。
6. 计时口径先想清楚：计 call() 的进入/绑定/执行/写回四段还是整体？四档的差主要在绑定段（val 拷一次、ref 取一次址、valres 两者、name 零成本但转嫁到每次访问）——访问次数大的循环语料会让 name 的"零绑定"变成"高访问"，账要按段记。
7. 三名字 swap：`swap3(i, a[i], b[j])` 里第二个赋值改 j——错位链更长；预言方法同 §22.5.3 的逐步推演表，每步问一句"现在 i/j 是几"。
8. 作弊版静态递归的暴露语料：`f(ref x)` 递归时外层把 x 的地址传下去——真栈环境里两次调用的 x 是不同格（互不影响），作弊版是**同一格**（内层写穿透外层）——别名语料一测即破。这道题证明：**递归的语义本质是"每个活动有独立存储"，帧压栈只是实现**。

---

上一章：[21 栈与活动记录](21-activation-records.md) · 下一章：[23 垃圾回收](23-garbage-collection.md)
