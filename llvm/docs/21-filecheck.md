# 21 · 测试：FileCheck 与回归

> 对应示例：`examples/21_filecheck/`（fib.mini + checks/ 两套断言）

编译器的代码没有"显然正确"，只有"被测过正确"。LLVM 生态的答案叫 **FileCheck**——一个"带通配的模式匹配断言器"，上游几万个测试全靠它。本章给 MiniLang 的 IR 输出建回归：改了前端，一条命令知道有没有伤到代码生成。

## 21.1 FileCheck 的心智模型

```text
CHECK: 模式          ← 从"上次匹配点"向后找，找到则推进游标
CHECK-NOT: 模式      ← 到下一个 CHECK 之前，此模式【不许】出现
CHECK-NEXT: 模式     ← 必须紧跟上一条匹配的下一行
CHECK-SAME: 模式     ← 必须和上一条同一行
CHECK-COUNT-N: 模式  ← 必须连续匹配 N 次
模式里的 [[VAR:re]]  ← 捕获命名变量；后面用 [[VAR]] 反向引用
```

它不是逐行 diff——是**有序的、允许跳行的**断言序列，恰好匹配"IR 里有些细节无关紧要"的现实。

## 21.2 两套断言的实战

原始 IR（`checks/fib-raw.checks`）：

```text
CHECK: define double @fib(double %n)
CHECK: alloca double          ← 前端的参数槽在（第 15 章策略的回归锚点）
CHECK: fsub double            ← 我们生成的减法
CHECK: phi double             ← if 合流的 phi 在
CHECK: define i32 @main()
```

-O2 后（`checks/fib-opt.checks`）：

```text
CHECK: define double @fib
CHECK-NOT: alloca             ← mem2reg 必须把它洗掉
CHECK: phi double
; instcombine 的经典改写：fsub %n, 1.0 → fadd %n, -1.0
CHECK: fadd double %n, -1.000000e+00
CHECK: tail call double @fib
```

运行（build 脚本自动做）：

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
& "$uc\FileCheck.exe" checks\fib-raw.checks --input-file fib.ll
& "$uc\opt.exe" -O2 fib.ll -S -o fib.O2.ll
& "$uc\FileCheck.exe" checks\fib-opt.checks --input-file fib.O2.ll
```

`fsub→fadd -1` 那条断言很有讲究：它锁住的是**上游优化器的已知行为**——上游改主意（比如某天不再做这个改写），测试立刻报错提醒你去看 changelog。这类"钉住依赖行为"的测试要节制使用。

> **实测坑（CHECK 有序性）**：断言必须按**文件中的出现顺序**排。第一版把 `CHECK: fsub` 放在 `CHECK: phi` 之后——fsub 在文件里位于 phi 之前，FileCheck 从 phi 处向后扫永远找不到，报 `expected string not found`。排查利器：`--dump-input=always` 会把输入与匹配过程并排打印。

## 21.3 CHECK-NOT 的区间语义

`CHECK-NOT: alloca` 约束的是**上一个 CHECK 到下一个 CHECK 之间的文本**——不是整个文件。想在全局断言"绝无 alloca"，要在文件尾再放一条普通 CHECK 收口，或干脆用两段式。误用区间语义是 FileCheck 新手第一大坑。

## 21.4 lit：上游的测试驱动器

上游测试每个目录一个 `lit.cfg.py`，文件头写 `; RUN: opt -S %s | FileCheck %s`，跑 `llvm-lit .` 全量驱动（并行、按依赖过滤）。**MSYS2 的 llvm-tools 包不带 llvm-lit**——本教程用 build.ps1 当手动驱动器（等价物），lit 的理念照搬：

| lit 概念 | 我们的等价物（build.ps1 / run-all.sh） |
|---|---|
| `RUN:` 行 | Invoke-Tool / run_step 序列 |
| `%s`/`%S` | 示例目录变量 |
| XFAIL | （未实现——教程规模用不上）|
| 并行调度 | ForEach 串行（24 个够快）|

## 21.5 回归金字塔（本书的实践）

```text
        少而精：行为级（21 章 FileCheck 断 IR 形态）
      ─────────────────────────────
        中量：出口级（各章 build.ps1 的输出断言/标记）
      ─────────────────────────────────────────
        海量：单元级（C++ assert / verifyModule——全程在线）
```

第 24 章的 regr.ps1 / regr.sh 把四条执行路径的**输出一致性**纳入顶层回归——金字塔封顶。

## 21.6 本章小结

- FileCheck = 有序跳行断言器；CHECK/CHECK-NOT/CHECK-NEXT/捕获变量五件套。
- 断言按文件序排列；CHECK-NOT 是区间语义不是全局。
- 上游 lit 的 RUN 行理念 = 脚本化的工具链编排，本书用 build.ps1 等价实现。

| 坑 | 解法 |
|---|---|
| CHECK 顺序报 not found | 按文件出现顺序排断言；--dump-input=always 排查 |
| CHECK-NOT 没管住全局 | 区间语义，末尾加收口 CHECK |
| 断言过脆频繁红 | 删掉钉依赖行为的断言，留结构性断言 |
| macOS 上没有 FileCheck 可执行文件 | MacPorts 的 llvm-2x 只给 libLLVMFileCheck.a；用官方库自链驱动（tools/filecheck_main.cpp） |

下一章终于给 scoop 那套"精简版 clang 23"派正经用场。
