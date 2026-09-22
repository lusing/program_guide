# 24 · 收官：MiniLang v1.0 与全书总账

> 对应示例：`examples/24_minilang_full/`（minilang.cpp v1.0 + mandel.mini + regression.mini + regr.ps1 / regr.sh）

九章连载的终点。MiniLang v1.0 的完整能力表：函数/原型/extern、if/for/while、var 与赋值、用户自定义一元/二元运算符、`&&`/`||` 短路、print/putch 内置、六种执行模式。压轴演出是**曼德博集合 ASCII 图**，回归武器是**四路径一致性套件**。

## 24.1 v1.0 的统一 CLI

```text
minilang run  <f>       JIT 执行（-O2 优化层）      ← 日常
minilang run0 <f>       JIT 执行（无优化）          ← 对照/教学
minilang ir   <f> <out> 导出 .ll                    ← 接 opt/llc 工具链
minilang obj  <f> <out> 直出 .o（→ clang 链接 exe） ← 交付
minilang ast  <f>       AST dump                    ← 调前端
minilang stats <f>      进程内统计 pass             ← 观察哨
```

旧旗标（`--jit` 等）作为别名保留——**CLI 迁移别断老用户**，这条工程经验同样来自真实世界。

新增的 `putch(x)` 内置（降级为 `putchar((int)x`）补上了最后一块拼图：字符输出。曼德博因此可画：

```text
# mandel.mini（节选）——三重 while 嵌套 + 短路逃逸判定
(while n < 60 && (xi * xi + yi * yi) < 4.0 do ...)
(if n < 4 then putch(35)          # '#'
 else if n < 10 then putch(43)    # '+'
 else if n < 30 then putch(46)    # '.'
 else putch(32))                  # ' '
```

（实测输出节选，`minilang run mandel.mini`）：

```text
#############################################################
###############################++++++.++++++#################
############################++++++++++.+. +++++##############
#########################+++++++++++++ ..++++++++############
#######################+++++++++++++.    .++++++++###########
####################+++++++++++++++..    ..+++++.+++#########
##################+++++++++++.  ..          ......++#########
###############+++++++++++++..                  .++++########
```

二十来行玩具语言源码，画出了分形——**这就是"前端管语义、LLVM 管一切"的含金量**。

## 24.2 四路径一致性回归

`regr.ps1`（Windows）/`regr.sh`（macOS）用同一份 `regression.mini`（覆盖全部语言特性，期望十个数值输出）跑四条执行路径：

| 路径 | 链路 | 验证的是 |
|---|---|---|
| run | JIT + IRTransformLayer(-O2) | 优化不改变语义 |
| run0 | JIT 无优化 | 前端直出的正确性 |
| ir → lli | 文本 IR 落盘再外部执行 | IR 序列化无损 |
| obj → clang → exe | TargetMachine + 链接 | 代码生成与链接 |

（实测输出）：

```text
== MiniLang v1.0 回归 ==
  [ok] run (JIT -O2)
  [ok] run0 (JIT 无优化)
  [ok] ir -> lli
  [ok] obj -> exe
  [ok] mandelbrot (run)
  [ok] ast
  [ok] stats
==== 24 ok ====
```

四条路径 + mandel + ast/stats 冒烟——`==== 24 ok ====` 一个标记锁定整条工具链。**以后任何一章的知识你动手改坏了什么，跑这一条就知道**。

## 24.3 MiniLang 全量代码规模

| 单元 | 行数（约） | 对应章 |
|---|---|---|
| 词法 + 解析 + AST | 380 | 12 |
| codegen（表达式/if/for） | 200 | 13 |
| JIT 驱动 + tracker + 跨模块签名 | 130 | 14 |
| var/赋值/alloca 化 | 120 | 15 |
| 用户运算符 | 90 | 16 |
| 优化层 | 40 | 17 |
| while/短路 | 110 | 18 |
| stats pass | 90 | 19 |
| TargetMachine obj | 70 | 20 |
| putch/统一 CLI | 30 | 24 |

**~1260 行 C++ 得到一门能编出原生 exe 的语言**——LLVM 承担了传统编译器课程里 80% 的篇幅。这就是本书选择"应用开发为主"的实证。

## 24.4 全书坑位总账（按"再遇概率"排序）

1. **工具链选型**：scoop llvm = 精简 clang 工具集，无 opt/lli/llvm-config/开发库（1）；PATH 里第一个 clang 可能来自 Swift（1）。
2. **版本迁移三巨头**：`i32*`→`ptr`（2-3）；旧 PassManager→新 PM（6）；`llvm/Passes/PassPlugin.h`→`llvm/Plugins/`（6，主干已验证）。
3. **22 的 API 细节**：EP 回调三参数（7）；`GetInsertPoint` 返回迭代器（13）；`getBasicBlockList()` 私有、块要 Create 时挂进函数（13）；`parseIR` 收 MemoryBufferRef、外部函数必须 declare（11）；`lookupTarget`/`setTargetTriple` 收 Triple 对象、Host.h 迁到 TargetParser（20）；`--link-shared` 必须连 `--libs`（6）。
4. **ConstantExpr 家族已删除**（21 起）：全局直接当 ptr，别再写 getGetElementPtr 常量（8）。
5. **内存/所有权类**（最难查）：悬垂 StringRef 键（9）；CloneFunction 自动入模块、双重插入死循环（9）；ResourceTrackerSP 寿命 ≤ Session（14）；跨 Context 复用 FunctionType* 错乱（14）。
6. **Windows 专属**：JIT 宿主函数要 dllexport（11）；scoop clang 无 VS 环境时借 MSYS2 头（22）；PowerShell 吞 `--`（22）；原生 cmake 探测 MinGW g++ 失败→llvm-config 直连最稳（S6）。
6b. **macOS 专属**：MacPorts 只有 19/21/23，选 23（Plugins/PassPlugin.h 与 22 同位置），但 `OptimizationLevel` 变裸 enum（7）；llvm-2x 不装 FileCheck 可执行文件，用官方库自链驱动（21）；clang 必须 `-isysroot`（1/10/20/22）；JIT 宿主函数改 `visibility("default")` 且查进程符号要带 `'_'` 前缀（11）；本机汇编乘法助记符随 CPU 变（10）；源码导览要 `LLVM_SRC`（23）。
7. **C++ 自伤类**：无括号 if 吞 return（13 的调试惨案）；`(char)` 强转 200 → -56（18）；map 键存临时 .str()（9 的孪生坑）。
8. **语言设计类**：double 写整数算法（18）；测试覆盖不足让原型逗号 bug 潜伏九章（18）。

每条的完整上下文都在对应章的"坑"小节 + CHEATSheet.md 的索引里。

## 24.5 下一步的路标

- **给 MiniLang 加类型**（int/double 二分法）——Type 系统进 NamedValues，codegen 分叉；
- **对标 Kaleidoscope 后几章**：LLVM ORC 的 lazy 编译（LLazyJIT）、EBC；
- **读一个真后端**：`llvm/lib/Target/X86/X86ISelLowering.cpp`（从 `include/llvm/Target/TargetLowering.h` 进）；
- **上手 MLIR**：`mlir/examples/` 的 toy 教程——本书全部 IR 直觉直接迁移；
- **给上游提 PR**：从 `llvm/test/` 里挑个 fail 的测试修起（23 章的 lit 知识就位了）。

## 24.6 结语

24 章，从 `clang -emit-llvm` 打印第一段 IR，到自己的语言画出曼德博、编出原生 exe。你手里现在有：读 IR 的眼睛、写 pass 的手、跑 JIT 的心脏、看源码的地图、防坑的清单。LLVM 很大，但它已经不再陌生。

| 坑 | 解法 |
|---|---|
| 压轴程序死循环 | 检查外层循环变量是否真的在递增（mandel 第一版教训） |
| 回归红在不认识的断言 | regr 的期望值表与 regression.mini 的 print 顺序一一对应 |
| 想加新内置函数 | 照 print/putch 的降级模式：codegen 里特判 + 返回 double |
