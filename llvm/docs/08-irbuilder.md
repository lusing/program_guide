# 08 · IRBuilder：用 C++ 生成 IR

> 对应示例：`examples/08_irbuilder/`（gen_fib.cpp）

手写 `.ll` 教会了你语法；现在换**生产者视角**：程序自己在内存里搭 Module。这是所有真实前端的核心技能——第 13 章起 MiniLang 的代码生成器就是本章内容的放大版。核心道具只有一个类：`IRBuilder`。

## 8.1 内存对象模型（文本 IR 的另一面）

你在 `.ll` 里看到的每样东西，在 C++ 里都有对应对象，**所有权自上而下**：

```text
LLVMContext        （上下文：类型/常量的全局唯一表，线程本地）
└── Module         （对应一个 .ll 文件）
    ├── GlobalVariable      （@globals）
    └── Function            （@函数）
        ├── BasicBlock      （标签块）
        │   └── Instruction （一条条指令，串成链表）
        └── Argument        （%参数）
```

- `LLVMContext` 是**类型和常量的驻留池**：`i32` 在整个 Context 里只有一个 `Type*`，指针比较即可判等（这也是 `isa` 体系快的原因，下一章细讲）；
- 一个进程可以有很多 Module 并存，但值不能跨 Module 使用；
- Module 拥有一切——析构 Module 时函数、块、指令全部回收。

## 8.2 造一个函数的四步曲

`gen_fib.cpp` 的 `buildFib` 是标准流程：

```cpp
// ① 拿类型（FunctionType：返回类型 + 参数类型数组 + 是否变参）
FunctionType *FT = FunctionType::get(B.getInt32Ty(), {B.getInt32Ty()}, false);

// ② 造函数壳（链接类型 + 名字 + 归属模块）
Function *F = Function::Create(FT, Function::ExternalLinkage, "fib", M);
F->getArg(0)->setName("n");           // 参数命名，否则打印成 %0

// ③ 造基本块（第一个块即入口）
BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);

// ④ IRBuilder 定位到块尾，开始发射指令
B.SetInsertPoint(Entry);
```

`IRBuilder` 的心智模型：**一个游标 + 一堆 Create 方法**。游标指向"下一条指令插在哪"，每发一条自动前移。跳块工作就是"换个 SetInsertPoint"——所以 IR 是**可以乱序生成的**（先把远处的块写完再回来补入口，完全合法）。

## 8.3 IRBuilder 常用发射器速查

`gen_fib.cpp` 用到的 + 马上要用的：

| 方法 | 生成 |
|---|---|
| `CreateAdd/Sub/Mul` (`nsw` 可选) | `add/sub/mul` |
| `CreateICmpSLT` 等 | `icmp slt`（I=整数，S=有符号；FLT 用 `CreateFCmpOLT`） |
| `CreateCondBr(Cond, A, B)` | `br i1, label %A, label %B` |
| `CreateBr(BB)` / `CreateRet(V)` | `br` / `ret` |
| `CreateCall(FT, Callee, Args, "名")` | `call`（22 起**必须**传 FT 或用 FunctionCallee） |
| `CreateAlloca/CreateLoad/CreateStore` | 栈槽三件套（第 15 章主角） |
| `CreateNot/CreateTimePHI...` `CreatePHI(Ty, N)` | `phi`（手造 phi 的入口） |

两个易踩点：

- **名字只是提示**：`"n.minus.1"` 如果撞名，打印机自动加后缀（`n.minus.1.1`）；无名则统一编号。
- **CreateCall 的类型参数**：变参/间接调用必须显式给 `FunctionType*`（22 的 API），直接 `CreateCall(Callee, Args)` 只适用于 callee 携带完整类型信息的场景。我们全程带 FT，最稳。

## 8.4 全局常量与 getOrInsertFunction

```cpp
// 字符串常量 = ConstantDataArray + GlobalVariable 壳
auto *Fmt = ConstantDataArray::getString(Ctx, "fib(10) = %d\n");
new GlobalVariable(M, Fmt->getType(), /*isConstant=*/true,
                   GlobalValue::PrivateLinkage, Fmt, ".intfmt");

// 函数声明/定义二合一：有就取，没有就插声明
FunctionCallee Printf = M.getOrInsertFunction("printf", PrintfT);
```

> **实测坑（ConstantExpr 已死）**：老代码常见的 `ConstantExpr::getGetElementPtr(...)`（给字符串常量取首地址）在 LLVM 21 起**编译不过**——ConstantExpr 家族被整体删除。不透明指针时代的正确姿势：**全局变量的值本来就是 `ptr`，直接传**（clang -O1 生成的就是 `call ... @printf(ptr @.str, ...)`）。同理 `bitcast` 常量、`select` 常量都没了，常量折叠统一走 `ConstantFold*` 工具函数。

> **实测坑（FunctionCallee vs Function*）**：`getOrInsertFunction` 返回 `FunctionCallee`（可能是现成 Function，也可能是"仅声明"占位）。传给 `CreateCall` 时要 `.getCallee()` 拿 `Value*`，或者对确定存在的用 `M.getFunction("fib")` 先判空。

## 8.5 验证与落盘

```cpp
if (verifyModule(M, &errs())) return 1;   // 结构合法性：终结指令、phi 前驱数、类型…

std::error_code EC;
raw_fd_ostream Out(argv[1], EC);          // EC 非零 = 打不开文件
M.print(Out, nullptr);                    // nullptr = 不加汇编注释（assembly annotation writer）
```

`verifyModule`/`verifyFunction` 是前端作者的单元测试——**先验证再导出**，坏 IR 一秒定位。`M.print` 的第二个参数可以挂一个注解器往输出里塞自定义注释（调试 pass 时很有用，比如把每个值的 use 数标在旁边）。

## 8.6 实测运行

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
$ex = 'G:\code\guide\llvm\examples\08_irbuilder'
$out = 'G:\code\guide\llvm\build\08_irbuilder'

# 构建（这次是普通可执行文件，不再是 -shared 插件）
& "$uc\g++.exe" ((& "$uc\llvm-config.exe" --cxxflags) -join ' ').Split(' ') `
    "$ex\gen_fib.cpp" -o "$out\gen_fib.exe" `
    ((& "$uc\llvm-config.exe" --ldflags --link-shared --libs core support) -join ' ').Split(' ')

& "$out\gen_fib.exe" "$out\fib.ll"    # 生成 IR
& "$uc\lli.exe" "$out\fib.ll"         # 立刻执行
```

（实测输出）：

```text
wrote G:\code\guide\llvm\build\08_irbuilder\fib.ll
fib(10) = 55
==== 08 ok ====
```

生成的 `fib.ll`（节选，`build/08_irbuilder/fib.ll`）——和你手写的 IR 一模一样：

```llvm
define i32 @fib(i32 %n) {
entry:
  %is.small = icmp slt i32 %n, 2
  br i1 %is.small, label %base, label %recur

base:
  ret i32 %n

recur:
  %n.minus.1 = sub nsw i32 %n, 1
  %n.minus.2 = sub nsw i32 %n, 2
  %fib.n.1 = call i32 @fib(i32 %n.minus.1)
  %fib.n.2 = call i32 @fib(i32 %n.minus.2)
  %add.r = add nsw i32 %fib.n.1, %fib.n.2
  ret i32 %add.r
}
```

注意 `sub`/`add` 自带 `nsw`——IRBuilder 对**有符号**算术默认加"无符号溢出即 UB"标记（`CreateNSW` 默认开），给优化器递刀。想要绕过 UB 语义用 `CreateAdd` 的 `HasNUW/HasNSW` 参数关掉。

## 8.7 链接库：llvm-config 的组件语言

`--libs` 后面跟的是**组件名**，llvm-config 负责展开成具体的库并排好依赖序：

```text
core          IR 核心类（Module/Function/IRBuilder…）——几乎总要
support       工具基础设施（StringRef/Twine/流/错误处理）——几乎总要
irreader      parseIRFile 文本解析（下一章用）
asmparser     文本解析后端
transformutils  CloneFunctionInto 等（下一章用）
analysis      通用分析
passes        标准优化 pass 集合
executionengine + orcjit    JIT（第 11 章）
native / nativeasmprinter    本机目标（第 11 章 JIT 出码用）
```

`--link-shared` 让以上全部映射到 `-lLLVM-22`（一个 dll 全包含）；不加则链几十个静态库（编译慢但产物独立）。本教程统一 shared——开发迭代快，运行时 PATH 里有 `libLLVM-22.dll` 就行（build.ps1 已前置）。

## 8.8 本章小结

- 对象模型：Context→Module→Function→BasicBlock→Instruction，所有权自上而下，类型常量全局驻留。
- IRBuilder = 游标 + Create 系；乱序生成合法；名字是提示。
- 22 的新现实：ConstantExpr 没了（全局直接当 ptr）；CreateCall 要带 FunctionType。
- `verifyModule` 先行，`M.print` 落盘；组件名经 `--libs` 展开成 `-lLLVM-22`。

| 坑 | 解法 |
|---|---|
| `ConstantExpr::getGetElementPtr` 编译不过 | 21+ 已删除；全局直接当 ptr 用 |
| FunctionCallee 塞不进 CreateCall | `.getCallee()` 取 Value* |
| 参数打印成 %0 | `F->getArg(i)->setName(...)` |
| 想关掉 nsw 的 UB 语义 | CreateAdd 的布尔参数 |
| 打不开输出文件 | 检查 error_code，raw_fd_ostream 构造不抛异常 |

下一章深入这棵对象树的根：`Value/User/Use` 与 RTTI。
