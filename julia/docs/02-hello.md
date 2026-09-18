# 02 · 第一个程序

> 对应示例：`examples/02_hello/`

## 2.1 REPL：探索的主战场

裸敲 `julia` 进 REPL，四种模式靠前缀切换：

| 前缀 | 模式 | 用途 |
|---|---|---|
| 无 | julia> | 求值表达式；`ans` 是上一个结果 |
| `;` | shell> | 直接跑系统命令（如 `;dir`） |
| `]` | pkg> | 包管理（17 章专讲） |
| `?` | help?> | 查文档：`?println` |

REPL 对中文/Unicode 友好；数学符号用 LaTeX 缩写 + Tab 输入：`\pi`→`π`、`\sqrt`→`√`、`\in`→`∈`、`\circ`→`∘`（本教程大量使用）。

## 2.2 脚本与命令行旗标

```powershell
julia --startup-file=no main.jl Julia 1.13    # 跑脚本，参数进 ARGS
julia --startup-file=no -e 'println("hi")'    # 一行代码
julia --startup-file=no -t 4 main.jl          # 4 线程（20 章）
julia --project=myenv main.jl                 # 激活环境（17 章）
```

本教程统一 `--startup-file=no --history-file=no` 起脚本（干净、可复现）；两个入口验证时另加 `--check-bounds=yes`（强制边界检查，23 章细讲）。

## 2.3 三种输出：println / print / show

```julia
println("Hello, Julia ", VERSION)   # 追加换行（演示输出：Hello, Julia 1.13.0）
print("print 不换行")               # 原样输出
show(stdout, "带引号")              # show：可解析的代码表示 → "带引号"
```

分工记法：**print/println 给人看，show 给机器看**（`repr`/字符串插值底层调 show）。字符串拼接用 `*`（不是 `+`），重复用 `^`：

```julia
"a" * "b"        # "ab"
"ab" ^ 3         # "ababab"
```

为什么是 `*`？Julia 把拼接视为乘法性质的群运算（`ab * ba` 交换后不同），而 `+` 留给可交换运算——一致性的代价是 C/Python 用户前三天会打错（12 章再细看字符串）。

## 2.4 插值：`$var` 与 `$(expr)`

```julia
x = 42
println("x = $(x)，和 $((x + 8))，π = $(π)")   # x = 42，和 50，π = π
```

**头号实测坑**：`$var` 后紧跟**中文全角标点**（`，`！`）或**半角 `!`/`?`** 会把它们吞进变量名——`"你好，$name！"` 直接 ParseError，`"$ver!"` 找不存在的 `ver!`。规则：**插值统一写 `$(var)`**，一了百了（1.13 新前端实测）。

## 2.5 ARGS 与 `@main` 入口（1.11+）

脚本取参的老办法是全局 `ARGS`（`Vector{String}`，julia 命令行上脚本名之后的参数）。1.11 起有了正式入口宏：

```julia
function @main(args)          # ✅ 正确形式：脚本主体先执行，结束后 julia 自动调用 main(ARGS)
    isempty(args) && println("（无参数运行）")
    println("入口收到 ARGS = $args")
end
```

三条实测规则（1.13）：

1. **正确形式**是 `function @main(args) ... end`，或先定义再独立写一行 `@main`。
2. **错误形式** `Base.@main function main(args) end` 会被展开成"注册 + 立即以函数对象调用 main"——实测打印 `args = main`，不报错但行为错（宏返回 `Expr(:call, :main, ...)`）。
3. **入口必须容忍空参数**：`-e 'include(...)'` 等加载方式也会触发入口调用（args 是 `String[]`）。本教程所有示例遵守这条约定。

## 2.6 函数的最小形式

```julia
greet(name::AbstractString) = "你好，$(name)！"
```

一行赋值式定义 + 参数类型标注——标注不是必需的，但它是多重派发的钥匙（06 章）。完整讲法见 05 章。

## 2.7 示例怎么跑

```bash
cd julia
./run-all.sh 02                                                  # 三层验证（shell 入口）
julia --startup-file=no examples/02_hello/main.jl Julia 1.13     # 手跑（注意会触发 @main）
julia --startup-file=no examples/02_hello/runtests.jl            # 测试层
```

```powershell
cd julia
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello   # 等价入口（Windows 上更顺手）
```

改动示例后重跑：`./run-all.sh 02`（或 `build.ps1 -Example 02_hello`）是标准学法——运行层看输出与结束标记（`==== 02 结束 ====`），测试层看 @testset 全绿。

## 2.8 坑位清单

1. **`$var` + 全角标点 / `!`/`?`**：解析错误或变量名吞并——统一 `$(var)`（2.4）。
2. **`@main` 的错误形式**：`Base.@main function main(args)` 静默变成"立即调用"——用 `function @main(args)`（2.5）。
3. **字符串拼接是 `*` 不是 `+`**：`"a" + "b"` 抛 MethodError（12 章有提示信息原文）。
4. **脚本里 `@code_typed` 等" REPL 自动物"不存在**：InteractiveUtils 只在 REPL 自动加载，脚本要 `using InteractiveUtils`（16 章实测坑）。
5. **结束标记约定**：本教程示例末行打印 `==== NN 结束 ====`，两个入口靠它确认输出完整——改示例别删这行。
