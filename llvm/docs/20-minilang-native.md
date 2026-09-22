# 20 · 原生编译：从 .mini 到 .exe

> 对应示例：`examples/20_minilang_native/`（minilang.cpp v0.9 + test.mini）

冲线章。前 19 章的所有能力汇合成一条完整的编译器通道：**MiniLang 源码 → AST → IR →（可选优化）→ 目标文件 → 链接 → 独立 .exe**。`--obj` 模式用 `TargetMachine` 在进程内直出 COFF 目标文件——和 rustc 编 `.o`、clang 编 `.o` 是同一套库调用。

## 20.1 TargetMachine：后端的程序化入口

第 10 章用 `llc` 命令行做后端；这里是库形态，六步：

```cpp
// ① 整程序装配（--ir 的同一套：extern/def/anon + 合成 main）
auto M = buildWholeProgram(InPath, Ok);

// ② 本机目标
InitializeNativeTarget(); InitializeNativeTargetAsmPrinter(); InitializeNativeTargetAsmParser();
auto TargetTriple = sys::getDefaultTargetTriple();   // 22 起要 #include llvm/TargetParser/Host.h
Triple TheTriple(TargetTriple);                      // 22：API 全面改收 Triple 对象
M->setTargetTriple(TheTriple);

// ③ 查目标表 → 造机器
const Target *TheTarget = TargetRegistry::lookupTarget(TheTriple, Error);
TargetOptions Opt;
auto *TM = TheTarget->createTargetMachine(TheTriple, "generic", "", Opt, Reloc::PIC_);

// ④ DataLayout 由机器给（第 10 章的"以后端为准"）
M->setDataLayout(TM->createDataLayout());

// ⑤ 老式 PassManager 装代码生成管线（新 PM 尚未接管 emit）
legacy::PassManager CodeGenPM;
TM->addPassesToEmitFile(CodeGenPM, Dest, nullptr, CodeGenFileType::ObjectFile);

// ⑥ 跑
CodeGenPM.run(*M);
```

`Reloc::PIC_` 对齐 MinGW 默认约定；`"generic"` CPU 换 `"native"` 可出本机特化代码（`getHostCPUName()`，见 Host.h）。Mach-O 与 ELF 上 `PIC_` 同样是默认选择（macOS 可执行文件本来就默认 PIE），所以这一行**不需要按平台分叉**。

> **实测坑（22 的 API 迁移三连）**：`sys::getDefaultTargetTriple` 要 include `llvm/TargetParser/Host.h`；`Module::setTargetTriple`/`TargetRegistry::lookupTarget`/`createTargetMachine` 全部改收 `const Triple&`（构造一个 `Triple TheTriple(str)` 传下去）；代码生成仍走 `legacy::PassManager`（新 PM 的 emit 接口尚在迁移中）。

## 20.2 链接：clang 驱动包圆

```powershell
& minilang --obj test.mini test.o
& clang test.o -o test.exe      # crt/libc/链接器全由驱动补齐
.\test.exe
```

（实测输出）：

```text
wrote test.o (triple x86_64-w64-windows-gnu)     # Windows
wrote test.o (triple x86_64-apple-darwin23.6.0)  # macOS（同一份代码，三元组来自宿主机）
==== 20 ok ====
610.000000        # fib(15)
125250.000000     # sum_to(500)
-55.000000        # -fib(10)（用户自定义一元负号）
```

> **跨平台**：三元组取自 `sys::getDefaultTargetTriple()`，产物格式随宿主机走（Windows→COFF、macOS→Mach-O、Linux→ELF），示例代码一行都不用改。链接那步在 macOS 上要给 clang 补 `-isysroot $(xcrun --show-sdk-path)`，否则报 `ld: library 'System' not found`。可执行文件的扩展名也只是约定（`test.exe` vs `test`），验证脚本按无扩展名处理。

**为什么不需要运行时库**：print 在第 13 章就降级成 `printf`，而 printf 由 libc 提供、链接器自动带上。玩具语言"零 runtime"的秘诀就是全靠 C 库——Go/Rust 都没这么潇洒（它们带 runtime）。

`llvm-nm test.o`（第 10 章工具）可以验尸采购单：

```text
                 U printf          ← 唯一的外部依赖
0000000000000000 T fib
0000000000000040 T sum_to
0000000000000080 T main
```

## 20.3 交叉编译只差一行

```cpp
Triple TheTriple("aarch64-linux-gnu");   // 换个三元组即可（TargetRegistry 认识它）
```

第 10 章 `llc --mtriple` 的库形态。Windows 主机上编 Linux ARM64 的 `.o`——但**链接**需要目标平台的工具链（lld 交叉链接是第 21 章之后的话题），所以本教程实操停在本机目标，交叉仅作原理展示。

## 20.4 全通道架构图（此刻的 MiniLang）

```text
 test.mini ──► 词法 ──► 解析/AST ──► codegen(IRBuilder) ──► LLVM IR
                                 │                            │
                                 │              ┌─────────────┼──────────────┐
                                 │              ▼             ▼              ▼
                                 │         --ir 出 .ll    --jit 入 ORC    --obj 出 .o
                                 │         (opt/llc 验证)  (TransformLayer  (TargetMachine
                                 │                          -O2 可选)       + clang 链接)
                                 ▼              ▼             ▼              ▼
                              --ast 观察     --stats 观察   REPL 回显      独立 .exe
```

四个出口共享同一前端与 codegen——**分层清晰是演进安全的前提**（第 24 章把它们收进统一 CLI）。

## 20.5 本章小结

- TargetMachine 六步：装配 → triple → lookupTarget → createTargetMachine → addPassesToEmitFile → run。
- 22 的 Triple 对象化 + Host.h 迁移 + legacy PM 三个版本注意点。
- print→printf 降级 = 零运行时链接；`llvm-nm` 验采购单。

| 坑 | 解法 |
|---|---|
| getDefaultTargetTriple 未声明 | include llvm/TargetParser/Host.h |
| lookupTarget 不收 string | 22 全线改 Triple 对象 |
| emit 用新 PM 没接口 | legacy::PassManager + addPassesToEmitFile |
| 交叉 .o 链不过 | 目标平台链接工具链缺席；先本机 |
| macOS 链接报 `library 'System' not found` | clang 补 `-isysroot $(xcrun --show-sdk-path)` |
| 进程内 emit 的产物格式 | COFF/Mach-O/ELF 随 `getDefaultTargetTriple()`，代码不用改 |

下一章补工程化短板：FileCheck 回归测试。
