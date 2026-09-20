# 05 · 优化管线：opt 与 -O 系列

> 对应示例：`examples/05_opt_pipeline/`（naive.ll）

`opt` 是 IR 层的加工机床：吃进 `.ll`/`.bc`，按你指定的管线（pipeline）跑一串 pass，吐出加工后的 IR。`clang -O2` 的"中端"就是它。这一章：`-O` 系列各自装了什么、显式 `-passes=` 语法怎么写、优化器在我们的"笨 IR"上如何层层剥笋。

## 5.1 opt 的两副面孔

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'

# 面孔一：标准优化级别（和 clang -O2 的中端等价）
& "$uc\opt.exe" -O2 naive.ll -S -o naive.O2.ll

# 面孔二：显式管线（精确控制跑哪些 pass、什么顺序）
& "$uc\opt.exe" -passes='mem2reg,instcombine,simplifycfg' naive.ll -S -o out.ll
```

`-S` 输出文本 IR（不加则输出位码）。调试优化必配的还有：

```powershell
# 逐 pass 观察：每个 pass 前后各 dump 一次
& "$uc\opt.exe" -O2 naive.ll -S -print-changed 2>&1 | Select-String 'IR Dump'
```

## 5.2 我们的笨 IR 笨在哪

`examples/05_opt_pipeline/naive.ll` 在第 4 章循环的基础上，故意埋了四个"优化器粮草"：

```llvm
%dead = alloca i32                   ; ① 写了 999 从没人读——死代码
store i32 999, ptr %dead
%zero = mul i32 %n, 0                ; ② n*0，常量折叠的教科书案例
...
loop.cond:
  %limit = add i32 %n, %zero         ; ③ 每圈重算的循环不变量
  %cond = icmp sle i32 %i, %limit
...
loop.end:
  %unused = load i32, ptr %dead      ; ④ 读死代码（还是逃逸防护，让 %dead 暂时"活着"）
  ret i32 %r
```

四级加工后（build 脚本会全部跑一遍并验证行为不变）：

```text
O0: 27 条指令行   （alloca/store/load 相关 12 行——原样）
O1: 14 条指令行   （mem2reg+instcombine+循环化：四个笨点全清）
O2: 14 条指令行   （与 O1 同规模，属性标注更细）
O3: 14 条指令行   （本例无向量化机会，规模不变）
```

### O2 输出精读（实测产物 `build/05_opt_pipeline/naive.O2.ll`）

```llvm
define i32 @sum_to(i32 %n) local_unnamed_addr #1 {
entry:
  %cond.not2 = icmp slt i32 %n, 1                 ; ③循环旋转：守卫提到循环外
  br i1 %cond.not2, label %loop.end, label %loop.body

loop.body:                                        ; preds = %entry, %loop.body
  %i.addr.04 = phi i32 [ %i.next, %loop.body ], [ 1, %entry ]
  %acc.addr.03 = phi i32 [ %acc.next, %loop.body ], [ 0, %entry ]
  %acc.next = add i32 %i.addr.04, %acc.addr.03
  %i.next = add i32 %i.addr.04, 1
  %cond.not = icmp sgt i32 %i.next, %n            ; 条件翻转进循环尾
  br i1 %cond.not, label %loop.end, label %loop.body

loop.end:                                         ; preds = %loop.body, %entry
  %acc.addr.0.lcssa = phi i32 [ 0, %entry ], [ %acc.next, %loop.body ]
  ret i32 %acc.addr.0.lcssa
}

define noundef i32 @main() local_unnamed_addr #0 {
entry:
  %pf1 = tail call i32 (ptr, ...) @printf(ptr ..., i32 5050)   ; ⑤彩蛋：见下
  %pf2 = tail call i32 (ptr, ...) @printf(ptr ..., i32 1)
  %pm = call i32 @puts(ptr ...)
  ret i32 0
}
```

对照着数优化器干了什么：

- **①④ 死代码**：`%dead`/`%unused` 无影无踪（`dce`/死 store 消除）；
- **② 常量折叠**：`%zero` 折成 0 后，`add n, 0` 又被 `instcombine` 消掉（`0` 是加法单位元）；
- **③ 循环旋转 + 不变量外提**：循环被重排成"守卫在前的 do-while 形态"（`loop-rotate`/`licm` 的合成效果），`loop.end` 里出现 `lcssa` phi——循环退出值的规范形态；
- **⑤ 彩蛋**：`main` 里的 `sum_to(100)` 整个被**内联+常量传播**，最后直接 `printf("…", 5050)`——编译期就算完了答案。这就是为什么指令数反而集中在属性标注上。

属性标注也值得看一眼：`norecurse`（不递归）、`memory(none)`（不碰内存）、`nounwind`（不抛异常）——优化器推理出的**行为契约**，后续 pass 据此放行。

## 5.3 -O 系列里都装了什么

粗粒度地图（越往上越"激进"）：

| 级别 | 定位 | 代表内容 |
|---|---|---|
| `-O0` | 不优化 | 什么都不跑（保留前端原貌） |
| `-O1` | 基础 | mem2reg、instcombine、simplifycfg、sroa、基本内联 |
| `-O2` | 发布标配 | O1 + 循环旋转/licm、GVN、更激进内联、删除公共子表达式 |
| `-O3` | 激进 | O2 + 循环向量化（SLP/loop-vectorize）、更激进展开 |
| `-Os`/`-Oz` | 体积优先 | O2 语义但砍掉增体积的变换 |
| `-O4` | （LLVM 21 起）真 LTO | 全程序链接期优化 |

> **注意**：`-O0` 也不是"零处理"——它仍会跑最低限度清理。想看"纯前端输出"，用 `clang -S -emit-llvm` 不加 `-O`（默认 -O0，alloca 满屏，正是第 4 章讲的前端形态）。

## 5.4 显式 -passes= 语法

新 PassManager（第 6 章你会从写 pass 的角度再见到它）的管线是一门小语言：

```text
mem2reg,instcombine                     逗号串联，从左到右跑
function(mem2reg,instcombine)           显式适配器：函数级 pass 要包在 function() 里
default<O2>                             引用整条标准管线
cgscc(inline)                           调用图 SCC 适配器
loop(licm)                              循环适配器
print<instcount>                        分析型"打印 pass"
```

实用片段：

```powershell
# 只想提升 SSA
opt -passes=mem2reg x.ll -S

# 标准管线后追加一个自定义 pass（第 6 章会写自己的！）
opt -passes='default<O2>,my-pass' x.ll -S

# 统计指令数
opt -passes='print<instcount>' x.ll -disable-output 2>&1 | Select-String 'function'
```

> **实测坑（语法迁移）**：老教程的 `-sroa -instcombine`（每个 pass 一个横线旗标）是**旧 PassManager** 语法，新版本里主流 pass 已不认横线形态，统一走 `-passes=`。两者混用还可能出现"`-passes` 与旧旗标互斥"的报错。新代码一律 `-passes=`。

> **实测坑（shell 转义）**：`<`、`>` 在 PowerShell/cmd 里是重定向符。`default<O2>` 和 `print<instcount>` **必须加引号**：`opt -passes='default<O2>'`。bash 同理。

## 5.5 函数属性与优化契约

优化不是"尽力而为"，是**在契约允许的范围内改写**。IR 侧的契约长这样：

```llvm
define i32 @sum_to(i32 %n) willreturn mustprogress nosync memory(none) { ... }
```

| 属性 | 含义 | 允许的放肆 |
|---|---|---|
| `readonly` / `memory(none)` | 不写内存/完全不碰内存 | 调用可重排、可删除 |
| `nounwind` | 不会异常退出 | 异常路径的清理代码全删 |
| `willreturn` | 一定返回 | 死循环也能按"会结束"优化 |
| `norecurse` | 不（直接/间接）递归 | 栈分析简化 |
| `noundef`（参数/返回值） | 不会是 undef/poison | 消除防御性检查 |
| `tail call` | 尾调用 | 可转成跳转（第 1 章 fib 变循环有它的功劳） |

谁负责生成这些属性？**推理 InferAttributes + 各 pass 的传播**。前端也可以直接标注（C 的 `__attribute__((const))` → `memory(read)`）。第 17 章 MiniLang 接入优化层时会看到：属性标得好，优化白嫖得多。

## 5.6 怎么"看着"优化器干活

三件套：

```powershell
# 1) 哪些 pass 改了 IR（改一个打一行）
opt -O2 naive.ll -S -print-changed -o nul          # stderr 打印变更摘要

# 2) 单 pass 前后 diff
opt -passes=instcombine naive.ll -S -o a.ll
fc.exe naive.ll a.ll                                # Windows 自带 diff

# 3) pass 失败/放行的原因（调试神器 remarks）
opt -O2 -pass-remarks-missed=inline naive.ll -S -o nul 2>&1 | Select-String 'missed'
```

开发自己的 pass（第 6-7 章）时，`-print-changed` 是确认"我的 pass 到底动了没有"的第一手段。

## 5.7 本章小结

- `opt` = IR 加工机床；`-O0..O3` 是预组装管线，`-passes=` 是自定义管线小语言。
- 四个经典粮草：死代码、常量折叠、循环不变量、逃逸防护——我们的笨 IR 全被清掉，`sum_to(100)` 甚至编译期求值成 5050。
- 优化 = 契约内的改写；属性（`memory(none)` 等）是优化器的放行证。
- `-print-changed`、remarks、前后 diff 是观察优化器的三件套。

| 坑 | 解法 |
|---|---|
| 老教程横线 pass 旗标不识别 | 统一 `-passes=` |
| `default<O2>` 被 shell 吃掉 | 引号包住整个 `-passes='...'` |
| 优化后行为变了 | 先查未定义行为（有符号溢出没 `nsw`、越界……优化器会放大 UB） |
| 向量化为啥没出现 | 数据要足量、无别名阻碍；`-pass-remarks-missed` 问原因 |

下一章从"用 pass"进化到"写 pass"：亲手造一个能被 `-passes=` 点名的优化器扩展。
