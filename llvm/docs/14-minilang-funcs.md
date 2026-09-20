# 14 · 函数与原型：JIT 增量执行

> 对应示例：`examples/14_minilang_funcs/`（minilang.cpp v0.3 + test.mini + redefine.mini）

`--ir` 模式是"编译器视角"：先全部编完再交给 lli。本章换**解释器视角**：内嵌 ORC LLJIT（第 11 章），逐条处理顶层单元——定义即注册、表达式即编即调。这让 MiniLang 有了 REPL 的心脏，也引出两个真实编译器的核心机制：**按函数增量编译**与**重定义撤销**。

## 14.1 逐项执行的主循环

```cpp
static int runJit(const char *InPath) {
  InitializeNativeTarget(); ...            // JIT 三件套初始化
  auto J = ExitOnErr(LLJITBuilder().create());

  while (true) {
    switch (CurTok) {
    case Eof:   ... return 0;
    case Extern: resetCodegen(); codegenProto; J->addIRModule(...); break;
    case Def:   /* 见 14.3 */ break;
    default:    /* 顶层表达式，见 14.4 */
    }
  }
}
```

`resetCodegen()` 每次造全新的 Context+Module——**每个顶层单元是独立模块**，这是增量编译的最小粒度：后定义的函数不影响已编译的，内存可逐个回收。

## 14.2 跨模块调用：签名即契约

独立模块立刻带来一个问题：`print(fib(10))` 的匿名模块里没有 `@fib`。解法是**签名记账**：

```cpp
static std::map<std::string, size_t> KnownFnArity;   // 名字 → 参数个数

// CallExprAST::codegen 里，本模块查不到时：
FunctionType *FT = FunctionType::get(DoubleTy,
    std::vector<Type *>(KnownFnArity[Callee], DoubleTy), false);
CalleeF = Function::Create(FT, ExternalLinkage, Callee, TheModule.get());  // 补 declare
```

模块内 `declare`，链接期由 JITDylib 解析到定义模块——第 10 章讲过的"`U` 符号采购单"在 JIT 里的版本。

> **实测坑（跨 Context 类型身份）**：第一版记账存的是 `FunctionType*`——**类型属于特定 LLVMContext**，在另一个 Context 的模块里复用旧指针会产生"看似 double 调 double 却报 Call parameter type does not match"的灵异 verify 错误。MiniLang 万物皆 double，所以记**元数**（参数个数）、用时在当前 Context 重建 FunctionType 即可。通用语言要记结构化的类型描述（符号表序列化同理）。

## 14.3 重定义：ResourceTracker 撤销法

JITDylib 里的符号默认只增不减，重复定义直接报 duplicate。ORC 的答案：**ResourceTrackerSP**——给每个 def 的模块发一个"tracker"，重定义时 `remove()` 旧 tracker，符号即刻消失：

```cpp
if (auto It = TrackedDefs.find(F->Proto->Name); It != TrackedDefs.end()) {
  ExitOnErr(It->second->remove());      // 撤销旧定义
  TrackedDefs.erase(It);
}
auto RT = J->getMainJITDylib().createResourceTracker();
ExitOnErr(J->addIRModule(RT, ThreadSafeModule(...)));
TrackedDefs[F->Proto->Name] = RT;
```

`redefine.mini` 实测：

```text
def twice(x) x + x
print(twice(10))     → 20.000000
def twice(x) x * 4   ← 同名重定义
print(twice(10))     → 40.000000     ← 新定义即时生效
==== 14 ok ====
```

这正是 REPL 语言（Julia/Cling）"重跑一段定义就更新"的机制内核。

> **实测坑（SP 生命周期）**：`TrackedDefs` 若是全局 map 且不清空，里面的 ResourceTrackerSP 会在**静态析构阶段**比 ExecutionSession 活得久——退出时 use-after-free 崩溃（0xC0000005，且因 outs() 缓冲连结束标记都打不出来）。退出前 `TrackedDefs.clear()` 一行解决。**ORC 的句柄不能跨过 Session 的寿命**。

## 14.4 顶层表达式：即编即调即撤

```cpp
default: {
  auto F = parseTopLevel();
  resetCodegen();
  Function *Fn = F->codegen();
  auto RT = J->getMainJITDylib().createResourceTracker();
  ExitOnErr(J->addIRModule(RT, ThreadSafeModule(...)));
  auto Addr = ExitOnErr(J->lookup(Fn->getName()));   // 触发编译
  double (*FP)() = Addr.toPtr<double (*)()>();
  outs() << "=> " << FP() << "\n";                   // REPL 风格回显
  ExitOnErr(RT->remove());                           // 用完即撤
}
```

`lookup` 是**按需编译的扳机**（第 11 章）：不 lookup，模块静静躺着。用完 remove——表达式是一次性的，不留垃圾符号。

实测 `test.mini`：

```text
=> 5.500000e+01     # print(fib(10))（print 打印后回显值）
=> 6.765000e+03     # fib(20)
=> 5.050000e+03     # sum_to(100)
=> 0.000000e+00     # sin(0)——extern 走 ProcessSymbols 解析（第 11 章）
==== 14 ok ====
```

## 14.5 --ir 与 --jit 的分工

| | `--ir`（第 13 章） | `--jit`（本章） |
|---|---|---|
| 模块组织 | 整文件一个 Module | 每单元一个 Module |
| 执行者 | lli（外部进程） | 内嵌 LLJIT |
| 重定义 | 编译错误（单模块内冲突） | tracker 撤销，运行时生效 |
| 适合 | 看 IR、走 opt/llc 工具链 | 交互、快速迭代 |

同一套 codegen，两种驱动——**前端与执行策略解耦**，这是编译器架构的常用分层。

## 14.6 本章小结

- 逐项 JIT：定义注册、表达式即编即调；`lookup` 触发按需编译。
- 跨模块调用 = 签名记账 + 本模块补 declare；类型不能跨 Context 复用。
- 重定义 = ResourceTracker remove；ORC 句柄寿命 ≤ Session（退出前清空）。

| 坑 | 解法 |
|---|---|
| 跨 Context 类型错乱 | 记元数/类型描述，用时重建 |
| duplicate symbol | 每模块独立 tracker，重定义先 remove |
| 退出时崩溃丢输出 | 全局 tracker map 在 Session 死前 clear |

下一章解决 v0.2 遗留的痛点：没有变量，累加只能递归。
