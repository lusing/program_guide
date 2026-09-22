# 06 · 写第一个 Pass（新 PassManager 插件）

> 对应示例：`examples/06_hello_pass/`（HelloPass.cpp + test.ll）

前五章你是 opt 的用户，从这章起你是它的**扩展者**。目标很小但完整：一个能被 `-passes=` 点名、能挂进 `-O2` 管线的 pass 插件（dll）。别看只有 40 行代码，它就是 rustc、Swift 编译器里自定义优化管线的同款机制——新 PassManager（NPM）的插件协议。

## 6.1 Pass 的形态学

新 PM 里一个 pass 就是普通 C++ 结构体，全部契约只有两点：

```cpp
struct HelloPass : PassInfoMixin<HelloPass> {      // ① 继承 Mixin（拿到调度所需的样板）
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    // ② 一个 run()：处理一个"IR 单元"，返回"保住了哪些分析"
    ...
    return PreservedAnalyses::all();               //    只读不改 → 全保住
  }
};
```

**作用域由类型决定**，不靠继承基类：

| run() 的参数 | 作用域 | 适配器写法 |
|---|---|---|
| `Function &` | 函数 | `function(...)` 或直接进 FPM |
| `Loop &` | 循环 | `loop(...)` |
| `SCC &` | 调用图强连通分量 | `cgscc(...)` |
| `Module &` | 整个模块 | `module(...)` 或直接进 MPM |

**PreservedAnalyses 是性能承诺**，不是装饰：

- `PreservedAnalyses::all()`——我没改 IR，分析缓存全部有效；
- 空的 `PreservedAnalyses()`——我可能改了任何东西，相关分析全部重算；
- `PreservedAnalyses PA; PA.preserve<DominanceTreeAnalysis>(); ...`——精细声明。

谎报的后果是"分析结果过期 → 后续 pass 用错数据"，属于最难查的 bug 之一。诚实第一。

> **为什么还要 `isRequired()`**：新 PM 有"死 pass 淘汰"——不产出结果、不改变 IR 的 pass 可能被管线直接跳过。纯打印的 pass 必须声明 `static bool isRequired() { return true; }`，否则你的 print 可能一行都不出现。（本例实测即使不写也打印了，但这是版本相关的宽容，别赌。）

## 6.2 插件协议：一个入口函数

`.dll`/`.so` 想被 `opt -load-pass-plugin` 认领，只需导出一个函数：

```cpp
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,   // 插件 API 版本，opt 会核对
          "hello-pass",              // 插件名
          LLVM_VERSION_STRING,       // 构建时的 LLVM 版本
          [](PassBuilder &PB) { ... }};  // 拿到 PassBuilder，往里挂钩子
}
```

`PassBuilder` 是管线的"注册中心"，最常用的钩子：

| 钩子 | 用途 |
|---|---|
| `registerPipelineParsingCallback` | 让 `-passes=我的名字` 可解析 |
| `registerAnalysisRegistrationCallback` | 注册自定义分析（第 7 章） |
| `registerOptimizerLastEPCallback` 等 EP | 自动挂进 `-O2` 等标准管线（第 7 章） |
| `registerParsePassPipelineCallback`（更细） | 支持带参数的 pass 名 |

名字注册的回调长这样——**认领你认识的名字，不认识的必须返回 false**（让后续注册者有机会认领）：

```cpp
PB.registerPipelineParsingCallback(
    [](StringRef Name, FunctionPassManager &FPM,
       ArrayRef<PassBuilder::PipelineElement>) {
      if (Name == "hello-pass") { FPM.addPass(HelloPass()); return true; }
      return false;
    });
```

> **实测坑（头文件路径）**：LLVM 22 里插件协议头文件在 **`llvm/Plugins/PassPlugin.h`**；`PassBuilder.h` 仍在 `llvm/Passes/`。v10 源码与旧教程里两者都在 `llvm/Passes/`——照抄会 `fatal error: llvm/Passes/PassPlugin.h: No such file or directory`。

## 6.3 构建与运行

一条 g++ 命令出插件（MSYS2 UCRT64 环境，pwsh 直调可行）：

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
$ex = 'G:\code\guide\llvm\examples\06_hello_pass'

& "$uc\g++.exe" -shared `
    ((& "$uc\llvm-config.exe" --cxxflags) -join ' ').Split(' ') `
    "$ex\HelloPass.cpp" -o HelloPass.dll `
    ((& "$uc\llvm-config.exe" --ldflags --link-shared --libs core) -join ' ').Split(' ')
```

三个技术点：

1. **`llvm-config --cxxflags`** 给出 `-I`、`-std=c++17`、`-fno-exceptions` 等必备旗标（你的代码要能无异常编译——别在 LLVM 程序里写 `throw`）；
2. **`--link-shared --libs core`** 链接导入库 `libLLVM-22.dll.a`——插件和 opt.exe 共享同一个已加载的 `libLLVM-22.dll`，符号天然一致；
3. MinGW 构建 dll **自动导出符号**，`llvmGetPassPluginInfo` 不用再写 `__declspec(dllexport)`。

> **实测坑**：`--link-shared` 必须与 `--libs <组件>` 连用才会真正输出 `-lLLVM-22`；只写 `--ldflags --link-shared` 一个 `-l` 都没有，链接报一屏 undefined reference。

macOS 侧同一条命令（产物扩展名 `.so`，`run-all.sh` 里就是这么写的）：

```bash
clang++ -shared $(llvm-config --cxxflags) HelloPass.cpp -o HelloPass.so \
        $(llvm-config --ldflags --link-shared --libs core)
opt -load-pass-plugin=HelloPass.so -passes=hello-pass test.ll -disable-output
```

两点平台差异：Mach-O 动态库默认**不**导出全部符号，但 `extern "C" LLVM_ATTRIBUTE_WEAK` 那个入口仍然能被 `dlsym` 到（示例不改即可）；插件**只走 shared 通道**——静态链会把 libLLVM 复制进插件，opt 与插件各持一份 LLVM，符号必然打架。

运行：

```powershell
& "$uc\opt.exe" -load-pass-plugin=HelloPass.dll -passes=hello-pass `
     "$ex\test.ll" -S -o after.ll
```

（实测输出，stderr）：

```text
hello-pass: square (1 bb)
hello-pass: quad (1 bb)
hello-pass: cube (1 bb)
hello-pass: main (1 bb)
```

而且 `after.ll` 依然能被 `lli` 跑出 `==== 06 ok ====`——`PreservedAnalyses::all()` 的承诺兑现（build 脚本两条都验）。

`-load-pass-plugin` 只负责**加载**；不指定 `-passes` 时插件不会自己跑（注册≠执行）。

## 6.4 老教程对照（旧 PassManager 避雷）

2019 年前的 pass 教程（包括 LLVM 官方旧版 WritingAnLLVMPass）长这样：

```cpp
struct Hello : public FunctionPass {                 // 旧：继承基类
  static char ID;                                    // 旧：静态 ID
  Hello() : FunctionPass(ID) {}
  bool runOnFunction(Function &F) override { ... }   // 旧：返回 bool（改没改）
};
char Hello::ID = 0;
static RegisterPass<Hello> X("hello", "Hello World Pass", false, false);
```

配套运行方式是 `opt -load Hello.so -hello`（横线旗标）。**这套东西在 LLVM 15+ 已删除**，新 PM 没有继承、没有 static ID、返回值从 bool 变成 PreservedAnalyses、注册从 `RegisterPass` 变成回调。看到 `FunctionPass`、`runOnFunction`、`RegisterPass` 字样，直接换教程。

## 6.5 调试三招

```powershell
# 插件没加载成功？看加载细节
& "$uc\opt.exe" -load-pass-plugin=HelloPass.dll --debug-pass-manager -passes=hello-pass ...

# 名字打错了？管线解析会报 unknown pass
& "$uc\opt.exe" -passes=hello-passx ...   # → 'hello-passx' is not a valid pass name

# 版本不匹配（链了别的 LLVM）：加载即报 API 版本/符号错误
```

另外 `-print-changed`（第 5 章）可以确认"我的 pass 到底改没改"。

## 6.6 本章小结

- 新 PM pass = `PassInfoMixin` 结构体 + `run()` + `PreservedAnalyses`；作用域由参数类型决定。
- 插件 = 导出 `llvmGetPassPluginInfo`，经 `registerPipelineParsingCallback` 把名字挂进 `-passes=` 语言。
- 构建 = g++ -shared + llvm-config 旗标 + link-shared；MinGW 自动导出入口。
- 旧 PM（FunctionPass/RegisterPass）已死，认得出就行。

| 坑 | 解法 |
|---|---|
| `llvm/Passes/PassPlugin.h` 不存在 | 22 在 `llvm/Plugins/PassPlugin.h` |
| 一屏 undefined reference | `--link-shared` 要配 `--libs <组件>` |
| pass 被静默跳过 | 打印型 pass 加 `isRequired(){return true;}` |
| `-load` 了但没跑 | 还要 `-passes=名字` 指定执行 |
| 代码里写 throw | llvm-config 带 `-fno-exceptions`，改返回码/llvm::Error |
| macOS 插件链静态库后符号打架 | 插件只走 `--link-shared`（一份 libLLVM 由 opt 提供） |

下一章给 pass 装上"眼睛"（自定义 Analysis）和"自动驾驶"（自动接入 -O2）。
