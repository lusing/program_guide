# 23 · 工具链与测试

> 对应示例：`examples/23_tooling/`（同一源码在两个验证层打印不同"形态"行）

## 23.1 fbc 选项速查（1.10.1 实测）

| 选项 | 作用 |
|---|---|
| `-x 路径` | 输出文件名 |
| `-w all` | 全警告（本教程纪律：**零诊断**才算过） |
| **`-g`** | 调试信息 + **激活 Assert**（15 章实测结论）+ 定义 `__FB_DEBUG__` |
| `-exx` | 数组边界/空指针运行时检查（配合 -g 是验证第一层） |
| `-e` / `-ex` | 基础/增强运行时错误检查（-ex 加 Resume 支持） |
| `-c` / `-C` | 只编译不链接 / 保留中间 .o |
| `-lib` / `-dll` | 产静态库 / 动态库（11 章） |
| `-m 模块名` | 显式指定主模块（多文件顺序保险） |
| `-pp` | 输出预处理结果到 `.bas.pp`——看宏展开的调试神器 |
| `-O 0..3` | 优化级别（默认 0；经 gcc 后端） |
| `-lang xx` | 方言选择（22 章）；`-forcelang` 覆盖源内 `#lang` |
| `-target xxx` | 交叉编译（如 `-target win32` 产 32 位） |
| `-arch xxx` | 目标架构 |
| `-i 路径` | 头文件搜索路径 |
| `-v` | 冗长输出（看 gcc 命令行） |

## 23.2 看宏展开

```bash
fbc -pp 10_preprocessor.bas      # 产出 10_preprocessor.bas.pp
```

宏出鬼的时候，看展开后的真实代码——比盯源码猜快十倍。

## 23.3 调试

- `-g` 产出带符号的 exe，**gdb 直接可用**（MinGW gdb：`gdb 24_snake.exe` → `break 24_snake.bas:120` → `run`）。
- FB 没有专属调试器生态，gdb 是主力；图形前端用 VS Code + gdb（装 basic 插件获得语法高亮）。
- 断言（`-g`）+ `-exx` 边界检查 + 返回码——三件套覆盖 90% 的诊断需求，比上手 gdb 快。

## 23.4 自制测试框架

FB 没有内建单测框架。30 行自助（示例有完整版）：

```freebasic
Dim Shared testCount As Integer = 0, failCount As Integer = 0

Sub check(actual As Integer, expected As Integer, label_ As String)
    testCount += 1
    If actual = expected Then
        Print "  PASS "; label_
    Else
        failCount += 1
        Print "  FAIL "; label_; "（期望 "; expected; " 实际 "; actual; "）"
    End If
End Sub

' 用例
check(fib(10), 55, "fib(10)")

If failCount > 0 Then End 1          ' 退出码协议：失败 = 1
```

## 23.5 本教程的验证协议（可直接抄去别的项目）

1. **双层编译运行**：`-w all -g -exx`（断言+边界层）与 `-w all`（发布层）各跑一遍；
2. **四条判定**：退出码 0 / stderr 空 / stdout 非空 / 末尾 `[OK] 标记`；
3. **确定性手段**：`Randomize 固定种子`、参数用 `fakeArgv()` 数组注入、时间断言只设下界；
4. **gfx 程序**：`Sleep 固定毫秒` 自退 + `Open Cons` 输出 + `Point` 像素断言（18 章）。

## 23.6 坑位清单（1.10.1 实测）

1. `fbc -h` 不存在（"Invalid command-line option"）——用 `fbc -help`（或裸 `fbc`）。
2. `Assert` 的激活开关是 `-g` 不是 `-e/-exx`（15 章，再喊一次）。
3. `-pp` 输出的是**整个预处理源**——include 的系统头也会展开，文件很大，配合文本搜索用。
4. `-O` 优化经 gcc；`-O 3` 下 `-exx` 检查可能被优化移动——**检查层别开优化**。
5. 退出码即协议：脚本判定看它；`End n` 是你唯一的"测试报告"。
