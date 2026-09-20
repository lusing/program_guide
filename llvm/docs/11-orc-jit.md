# 11 · ORC JIT：把编译器嵌进你的程序

> 对应示例：`examples/11_orc_jit/`（jit_demo.cpp）

`lli` 的心脏是 ORC——LLVM 的**运行时编译**框架（On-Request Compilation）。把 ORC 嵌进你的程序，就得到"边生成 IR 边执行"的能力：这是 Julia、Cling（C++ 解释器）、LLDB 表达式求值、数据库查询 JIT 的共同底座；也是我们第 14 章起 MiniLang REPL 的动力系统。本章用 ~120 行代码实现 JIT'd 代码与宿主 C++ 的**双向互调**。

## 11.1 ORC 的心智模型

```text
┌── 你的程序（宿主）───────────────────────────────┐
│  LLJIT                                           │
│  ├─ ExecutionSession   符号表与调度的中枢         │
│  ├─ Main JITDylib      "你的"代码放这             │
│  ├─ ProcessSymbols JD  宿主进程符号（回看窗口）    │
│  ├─ IRCompileLayer     IR → 目标文件（on demand） │
│  └─ ObjectLinkingLayer 目标文件 → 可执行内存      │
└──────────────────────────────────────────────────┘
   J->addIRModule(TSM)  扔 IR 进去（还不编译！）
   J->lookup("fib")     这一刻才触发编译（lazy/按需）
   Addr.toPtr<fn*>()    拿到地址当 C 函数指针调
```

要点三个：

1. **JITDylib（dynamic library）是符号命名空间**。`LLJIT` 帮你建好 Main 和 ProcessSymbols 两个，前者放你的 IR，后者映射宿主进程已导出的符号（JIT'd 代码由此回调你的 C++）。
2. **按需编译**：addIRModule 只登记；lookup 一个符号才把"包含它的模块"编译链接成可执行内存。同一个模块里没被 lookup 触达的函数可能永远不编译。
3. **模块的三种来源**在这里汇合：文本（parseIR）、API（IRBuilder）、位码（parseIRFile）——第 8 章造 IR 的技能直接复用。

## 11.2 最小 LLJIT 程序的骨架

`jit_demo.cpp` 主干：

```cpp
InitializeNativeTarget();               // ① 本机目标三件套（JIT 编本机码）
InitializeNativeTargetAsmPrinter();
InitializeNativeTargetAsmParser();

auto J = ExitOnErr(LLJITBuilder().create());   // ② 造 LLJIT

// ③ IR 进 Main JITDylib——DataLayout 必须与 JIT 一致（第 10 章的规则）
ExitOnErr(J->addIRModule(makeTextModule(J->getDataLayout())));
ExitOnErr(J->addIRModule(makeFibModule(J->getDataLayout())));

// ④ lookup → 函数指针 → 调用
int (*fib)(int) = ExitOnErr(J->lookup("fib")).toPtr<int (*)(int)>();
outs() << "fib(10) = " << fib(10) << "\n";
```

`ExitOnError` 是 LLVM 的错误处理糖：`Expected<T>` 带错误就打印并退出。LLVM 用 `Expected<T>`/`Error` 代替异常（`llvm-config --cxxflags` 带着 `-fno-exceptions`），**你的 LLVM 程序也不该 throw**。

## 11.3 双向互调与 Windows 大坑

JIT'd 代码回调宿主函数（`host_mul`、`print_i32`），IR 里只写 `declare`，链接时 ORC 从 ProcessSymbols JD 解析。Windows 上这里有个**必踩坑**：

```cpp
// 必须 __declspec(dllexport)！否则 JIT 报 Symbols not found: [ host_mul ]
extern "C" __declspec(dllexport) int host_mul(int a, int b) { return a * b; }
```

原因：Windows PE 的符号解析走**导出表**，MinGW 默认不给 exe 导出普通函数；Linux/macOS 的 dlsym(NULL) 天下大同。同理，宿主侧如果直接 `J->lookup("host_mul")` 查不到（详见 11.5）。

（实测输出）：

```text
poly(7)  = 70        ← 文本 IR 模块：host_mul(7,7)+host_mul(7,3)
jit says: 108        ← JIT 内部调用宿主 print_i32 打的（回调方向）
fib(10)  = 55        ← IRBuilder 模块：递归 fib
host_mul visible: yes
==== 11 ok ====
```

## 11.4 IR 字符串直接进 JIT

```cpp
auto M = parseIR(MemoryBufferRef(R"IR(
declare i32 @host_mul(i32, i32)     // ← 22 要求：调用的外部函数必须显式声明
define i32 @poly(i32 %x) { ... }
)IR", "poly.ll"), Err, *Ctx);
M->setDataLayout(DL);               // ← 与 JIT 对齐
return ThreadSafeModule(std::move(M), std::move(Ctx));
```

三个版本敏感点（都实测过）：

- **`parseIR` 收 `MemoryBufferRef`**（轻量视图），不再收 `unique_ptr<MemoryBuffer>`；
- **外部函数必须先 declare**——22 的解析器报 `use of undefined value '@host_mul'`，老版本会隐式插声明；
- `ThreadSafeModule` 是"模块+上下文"的线程安全包装——ORC 的编译可能发生在别的线程，模块的锁必须跟着走。

## 11.5 lookup 的搜索范围（22 实测行为）

| 想查 | 写法 | 说明 |
|---|---|---|
| 你 addIRModule 的函数 | `J->lookup("fib")` | 只搜 Main JITDylib，够用 |
| 宿主进程符号 | `ES.lookup({J->getProcessSymbolsJITDylib().get()}, "host_mul")` | **`J->lookup` 不搜进程符号**（22 实测），要显式指向 ProcessSymbols JD |

这个行为差异在老教程里说法混乱（早期 LLJIT 把进程生成器挂在 Main 上）。心智模型：**lookup 按你给的 JD 列表顺序搜索**；Main 的"链接顺序"里含 ProcessSymbols（所以 JIT 内部调用能解析），但便捷版 `J->lookup` 只查 Main。

另外注意 `ES.lookup` 的参数是 `ArrayRef<JITDylib*>`（**裸指针**），不是 `JITDylibSP`——拿 `.get()` 转一下。

## 11.6 性能与生命周期

- JIT'd 代码是**本机原生码**——`fib(30)` 就是原生速度。但默认不带优化（`-O0` 形态的 IR 直接编），第 17 章给 MiniLang 接上编译期 -O2 管线后提速一个数量级（实测对比在那一章）。
- `LLJIT` 析构时释放所有 JIT 内存（ExecutableAllocator 保证指令缓存安全失效）；宿主拿到的函数指针在 J 死后悬垂——**函数指针的生命周期 ≤ LLJIT**。
- 增量定义：同一个 Main JD 可以反复 addIRModule——REPL "每敲一行加一个函数" 的机制基础（第 14 章）。

## 11.7 本章小结

- LLJIT = Session + JITDylib + 两层（编译/链接）；lookup 触发按需编译。
- 模块来源三选一（文本/Builder/位码）；DataLayout 对齐 JIT 是硬规则。
- Windows：宿主函数给 JIT 用必须 dllexport；`J->lookup` 不搜进程符号。
- `Expected/Error` + `ExitOnError` 替代异常；函数指针寿命 ≤ LLJIT。

| 坑 | 解法 |
|---|---|
| `Symbols not found: [xxx ]` | 宿主函数加 `__declspec(dllexport)`；或 IR 里缺 declare |
| `use of undefined value` | 22 解析器要求先声明外部函数 |
| parseIR 编不过 | 用 MemoryBufferRef（22 API） |
| `J->lookup` 查不到宿主函数 | 走 ProcessSymbols JD + `ES.lookup({JD*}, ...)` |
| 模块 DataLayout 不符 | `J->getDataLayout()` 回填后再 addIRModule |
| 代码里写 throw | `-fno-exceptions` 下编译不过；改用 Error/Expected |

至此"使用者"技能树点满。下一章开始造语言：MiniLang 前端（词法 + 语法 + AST）。
