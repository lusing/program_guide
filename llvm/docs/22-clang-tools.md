# 22 · clang 前端工具链：ast-dump / clang-format / clang-tidy

> 对应示例：`examples/22_clang_tools/`（sample.c + ugly.c + .clang-format + run.ps1 / run.sh）

scoop 的 LLVM 23 干不了 IR 实操（第 1 章勘察：无 opt/lli/开发库），但它是**一流的 clang 前端工具集**——clang-format、clang-tidy、clangd 的宿主。本章四连：emit-llvm 跨版本互通、AST 观测、格式化、静态体检。

## 22.1 跨版本 IR 互通（复盘第 1 章的伏笔）

```powershell
$clang23 = 'G:\scoop\apps\llvm\current\bin\clang.exe'
& $clang23 -S -emit-llvm -O1 -target x86_64-pc-windows-gnu `
           -isystem G:\scoop\apps\msys2\current\ucrt64\include `
           sample.c -o sample.ll
& G:\scoop\apps\msys2\current\ucrt64\bin\lli.exe sample.ll   # 22 执行 23 的 IR
```

（实测输出）：

```text
sum = 55
==== 22 ir ok ====
```

**clang 23 产的 IR，LLVM 22 的 lli 直接执行**——文本 IR 的版本兼容性是生态的粘合剂（bitcode 可没这个待遇，见 2.5）。

> **实测坑（MSVC 头文件失踪）**：scoop clang 默认目标 `x86_64-pc-windows-msvc`，无 VS 环境变量时直接 `fatal error: 'stdio.h' file not found`。两条出路：① 开 VS 开发者环境让它找到 MSVC 头；② 切 GNU 目标 `-target x86_64-pc-windows-gnu` 并 `-isystem` 借 MSYS2 UCRT64 的头文件。本教程选②——与主线工具链同一套头。

### macOS 上的同一个实验

本机没有 MSYS2，但 MacPorts 同时装着 llvm-21 和 llvm-23，跨版本照样能做——**clang 23 产 IR，llvm-21 的 lli 执行**：

```bash
/opt/local/libexec/llvm-23/bin/clang -isysroot $(xcrun --show-sdk-path) \
    -S -emit-llvm -O1 sample.c -o sample.ll
/opt/local/libexec/llvm-21/bin/lli sample.ll     # 21 执行 23 的 IR：同样通过
```

`run.sh` 里取的是 `LLVM2_BIN`（`run-all.sh` 自动探测到的第二套 LLVM）；若本机只装了一套，它会打印"同版本，未构成跨版本验证"而**不假装跨了**。

macOS 侧要补的两处平台差异：代替 `-isystem 借 MSYS2 头` 的是 `-isysroot $(xcrun --show-sdk-path)`；clang-tidy 的 SDK 根要经 `--` 传给底层 clang。bash 不吃 `--`（那是 PowerShell 的坑），所以 run.sh 里直接写 `"$TIDY" --checks=... sample.c -- "${SDK_ARGS[@]}"` 就行。

## 22.2 AST 观测：-Xclang -ast-dump

```powershell
& $clang23 -target x86_64-pc-windows-gnu -isystem <ucrt64 include> `
           -Xclang -ast-dump -fsyntax-only sample.c
```

（实测输出节选）：

```text
FunctionDecl <sample.c:4:12, line:4, col:41> used add 'int (int, int)'
`-CompoundStmt
  `-ReturnStmt
    `-BinaryOperator 'int' '+'
      `-ImplicitCastExpr 'int'
        `-DeclRefExpr 'int' lvalue ParmVar 'a' 'int'
...
ForStmt
|-DeclStmt  `int i = 1'
|-BinaryOperator '<' ...
```

这是**翻译前的树**——对照第 12 章 MiniLang 的 AST dump，节点型号都差不多（Decl/Stmt/Expr 三大家族）。clang AST 是做重构工具、静态分析、代码生成的金矿：`clang-check`、`clang-query`（交互式 AST 查询）、ASTMatcher 库全在这棵树上作业。

## 22.3 clang-format：.clang-format 配置文件

```yaml
# 放在项目根目录，clang-format --style=file 自动发现
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 100
AllowShortFunctionsOnASingleLine: None
PointerAlignment: Right
```

```powershell
& clang-format --style=file ugly.c -i      # 原地格式化（我们的脚本在副本上做）
```

实测把单行压缩的 `if(x<0){return -x;}` 展开成四行块。工作流建议：编辑器集成（保存即格式化）+ CI 里 `--dry-run -Werror` 把不合格式拒之门外。所有选项见 `clang-format --style=llvm --dump-config`。

## 22.4 clang-tidy：静态体检

```powershell
clang-tidy --checks="clang-diagnostic-*,readability-*" sample.c `
           -- --target=x86_64-w64-windows-gnu -isystem <ucrt64 include>
```

（实测输出节选）：

```text
warning: parameter name 'a' is too short, expected at least 3 characters [readability-identifier-length]
warning: 10 is a magic number; consider replacing it with a named constant [readability-magic-numbers]
warning: statement should be inside braces [readability-braces-around-statements]
```

检查族谱：`clang-diagnostic-*`（编译器警告）、`readability-*`、`modernize-*`（现代化改写）、`bugprone-*`、`performance-*`、`cert-*`（安全）。项目里放 `.clang-tidy` 文件固化选择；`--fix` 可自动改代码。

> **实测坑（PowerShell × 原生命令的 "--"）**：clang-tidy 用 `--` 分隔自身选项与编译旗标，**PowerShell 会把 `--` 吃掉**（它是 PS 的"参数结束"标记）， tidy 收到残缺参数只打印 usage。须经 `cmd /c` 转交，或把编译旗标写进 `compile_commands.json`（大型项目的正道——clangd 也吃它）。
>
> **实测坑（scoop tidy 默认零检查）**：不带 `--checks` 时报 `Error: no checks enabled.`——发行版不带默认检查集，必须显式点名。

## 22.5 clangd：一句话带过

编辑器侧的语言服务器（补全/跳转/诊断），吃 `compile_commands.json`（`cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` 生成）。本教程的 llvm-config 直连构建没有 compile db，clangd 派不上场——这也解释了你可能在 IDE 里看到的"头文件找不到"红色波浪线：**它不知道 MSYS2 的 include 路径**，编译其实没问题（build.ps1 是唯一真相）。

## 22.6 本章小结

- IR 文本跨版本互通（23 产 22 执行）；GNU 目标 + 借头解决 scoop clang 的 MSVC 依赖。
- `-Xclang -ast-dump` 看翻译前的树；format/tidy 用配置文件固化团队约定。
- PowerShell 吞 `--`、tidy 零默认检查、clangd 缺 compile db 三个环境坑各有解。

| 坑 | 解法 |
|---|---|
| stdio.h not found | GNU 目标 + -isystem 借 MSYS2 头 |
| tidy 只打 usage | `--` 经 cmd /c 传；或 compile_commands.json |
| tidy 无输出 | scoop 版零默认检查，--checks 点名 |
| IDE 红波浪线 | clangd 没有 include 路径信息，以构建脚本为准 |
| macOS：stdio.h not found | clang 要 `-isysroot $(xcrun --show-sdk-path)`（等价于 Windows 的借头） |
| macOS 无第二套 LLVM | run.sh 会打印"同版本，未构成跨版本验证"，不假装跨了 |

下一章把 G:\github\lang\llvm-project 的现代源码树变成你的地图。
