# LLVM 22 速查表（Windows MSYS2 UCRT64 实测）

命令速查 + 坑位索引。详细讲解见对应章（表中 `N.M` = 第 N 章 M 节）。主线工具链：`G:\scoop\apps\msys2\current\ucrt64`（LLVM 22.1.8 完整版）。

## 1. 工具链就位（换机先跑）

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
foreach ($t in 'opt','lli','llc','llvm-as','llvm-dis','llvm-config','FileCheck','g++','clang') {
    Test-Path "$uc\$t.exe" }        # 9 个 True 才齐活（01.3）
& "$uc\llvm-config.exe" --version   # 22.1.8
```

## 2. IR 工具五连

```powershell
clang -S -emit-llvm -O1 f.c -o f.ll     # C → 文本 IR（01.5）
llvm-as f.ll -o f.bc                     # 文本 → 位码（2.5）
llvm-dis f.bc -o f.dis.ll                # 位码 → 文本
lli f.ll                                 # 执行 IR（@main 的返回值 = 退出码）
opt -passes=mem2reg f.ll -S -o out.ll    # 优化管线（5.1）
opt -O2 f.ll -S -o out.ll                # 标准级别
opt -passes='default<O2>,my-pass' f.ll -S # 引号！< > 是重定向符（5.4）
llc f.ll -o f.s                          # IR → 汇编
llc -filetype=obj f.ll -o f.o            # IR → 目标文件
llc --mtriple=aarch64-linux-gnu f.ll -o cross.s   # 一键交叉（10.2）
clang f.o -o f.exe                       # 驱动补 crt/libc 并链接（10.1）
llvm-nm f.o                              # 符号表：U = 采购单（10.4）
```

## 3. C++ 对接 llvm-config

```powershell
$rm = [System.StringSplitOptions]::RemoveEmptyEntries
$cxx = ((& $uc\llvm-config.exe --cxxflags) -join ' ').Split(' ', $rm)
$lnk = ((& $uc\llvm-config.exe --ldflags --link-shared --libs core support) -join ' ').Split(' ', $rm)
& "$uc\g++.exe" $cxx prog.cpp -o prog.exe $lnk      # 程序（8.7）
& "$uc\g++.exe" -shared $cxx pass.cpp -o pass.dll $lnk  # pass 插件（6.3）
# 组件：core/support 永远要；irreader+asmparser 解析 .ll；orcjit+executionengine
# 做 JIT；passes+analysis 优化层；codegen+target+native+mc 出 .o
$env:PATH = "$uc;" + $env:PATH                        # 运行期要找 libLLVM-22.dll
```

## 4. Pass 插件骨架（新 PM）

```cpp
#include "llvm/Plugins/PassPlugin.h"   // 22 的新家（不是 llvm/Passes/）！
struct MyPass : PassInfoMixin<MyPass> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    errs() << F.getName() << "\n";
    return PreservedAnalyses::all();   // 只读不改 → 全保住
  }
  static bool isRequired() { return true; }  // 打印型防淘汰
};
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "my", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "my-pass") { FPM.addPass(MyPass()); return true; }
                  return false; });
          }};
}
```

运行：`opt -load-pass-plugin=MyPass.dll -passes=my-pass f.ll -disable-output`

## 5. ORC JIT 骨架（LLJIT）

```cpp
InitializeNativeTarget(); InitializeNativeTargetAsmPrinter(); InitializeNativeTargetAsmParser();
auto J = ExitOnErr(LLJITBuilder().create());
TSM.withModuleDo([](Module&M){ M.setDataLayout(J->getDataLayout()); }); // DL 必须对齐
ExitOnErr(J->addIRModule(std::move(TSM)));
auto Addr = ExitOnErr(J->lookup("fn"));
double (*fp)() = Addr.toPtr<double(*)()>();
// 宿主函数给 JIT 调用：extern "C" __declspec(dllexport)（Windows 必需）
// 重定义：JD.createResourceTracker() + addIRModule(RT,...) + RT->remove()
```

## 6. 坑位索引（按遇错频率排）

| 坑 | 解法 | 章 |
|---|---|---|
| scoop llvm 无 opt/lli/llvm-config | 精简版只当前端工具集；主线用 MSYS2 | 1.3 |
| `llvm/Passes/PassPlugin.h` 不存在 | 22 起在 `llvm/Plugins/` | 6.2 |
| 旧教材 `i32*`/`bitcast` | 一律换 `ptr`；bitcast 基本消失 | 2.7 |
| `ConstantExpr::getGetElementPtr` 编不过 | 21 起删除；全局直接当 ptr | 8.4 |
| `--link-shared` 不出 `-lLLVM` | 必须连 `--libs <组件>` | 6.3 |
| EP 回调参数不够 | 22 加了 ThinOrFullLTOPhase 第三参 | 7.3 |
| map<StringRef> 配 .str() 临时 | 键悬垂 UB；用 std::string | 9.3 |
| CloneFunction 后 push_back 死循环 | 22 自动入模块，别重复插 | 9.4 |
| JIT 找不到宿主函数 | `__declspec(dllexport)`；`J->lookup` 只搜 Main JD | 11.3/11.5 |
| parseIR 编不过 | 22 收 MemoryBufferRef；外部函数先 declare | 11.4 |
| 块没挂进函数（parentless） | Create 时传 F；getBasicBlockList 已私有 | 13.3 |
| GetInsertPoint() 编不过 | 22 返回迭代器；块指针用 GetInsertBlock | 13.3 |
| lookupTarget 不收 string | 22 收 Triple 对象；Host.h 在 TargetParser | 20.1 |
| `nativeasmparser` 组件不存在 | 组件名精简：target/native/mc/codegen | 20 |
| ResourceTracker 退出崩溃 | SP 寿命 ≤ Session；退出前 clear | 14.3 |
| 跨 Context 用 FunctionType* | 类型错乱；记元数重建 | 14.2 |
| `(char)200` 变 -56 | token 全 int；表 map<int,int> | 18.1 |
| scoop clang 报 stdio.h 找不到 | GNU 目标 + -isystem 借 MSYS2 头 | 22.1 |
| PowerShell 吞原生命令的 `--` | 经 cmd /c 转交 | 22.4 |
| clang-tidy "no checks enabled" | scoop 版零默认，--checks 点名 | 22.4 |
| `.bc` 跨版本打不开 | 持久化只用 .ll 文本 | 2.5 |
| 无括号 if 吞 return | 单语句也写花括号（13 调试惨案） | 13 |
| 双精度写整数算法出 nan | exp/2=0.5；先取整 | 18.4 |
| 标识符不带 `_` | 词法字符集加下划线 | 12.2 |

## 7. 新旧 PassManager 对照（认旧代码用）

```text
旧（≤14，已删除）                    新（15+）
FunctionPass 基类                →   PassInfoMixin<T> 结构体
static char ID                   →   不需要
bool runOnFunction(F&)           →   PreservedAnalyses run(F&, FAM&)
RegisterPass<X> X("name",...)    →   PB.registerPipelineParsingCallback
opt -load P.so -name             →   opt -load-pass-plugin=P.dll -passes=name
getAnalysis<T>()                 →   AM.getResult<T>(F)（Analysis 要 AnalysisInfoMixin + static Key）
```

## 8. 本书示例地图（章号 = 目录号）

```text
01-05  IR 层（clang 产 IR/手写/类型/SSA/优化）
06-07  Pass（插件/分析/EP）
08-09  C++ API（IRBuilder/Value 对象模型）
10-11  后端与 JIT（llc 交叉/LLJIT）
12-20  MiniLang 连载（前端→…→原生 exe）
21-24  工程化（FileCheck/clang 工具/源码导览/v1.0 回归）
```

全量验证：`pwsh build.ps1 -All`（24/24 全绿）
