# 15 · 终端界面：SCREEN SECTION

> 示例：[`examples/15_screen/`](../examples/15_screen/)
> 运行：`./run-all.sh 15`（自检模式）｜ `COB_SCREEN_DEMO=1 ./build/check/15_screen`（交互模式，需在真终端里）

COBOL 诞生于终端时代，`SCREEN SECTION` 就是它内建的**字符终端 UI（TUI）**设施：
用声明式的布局定义字段在屏幕上的位置、颜色、输入方式，然后 `DISPLAY` 整屏画出、
`ACCEPT` 整屏收集输入。GnuCOBOL 底层用 **curses/ncurses** 实现，能做出带高亮、下划线、
颜色、光标跳转的表单界面——不用手写一行 ANSI 转义。

## 1. SCREEN SECTION 在哪、长什么样

`SCREEN SECTION` 是 `DATA DIVISION` 的一个节，紧跟在 `WORKING-STORAGE SECTION` 之后。
它定义的是**屏幕布局**，不是数据存储：

```cobol
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE    PIC X(24) VALUE "=== 用户登记表 ===".
       01 WS-NAME     PIC X(10) VALUE SPACES.
       01 WS-AGE      PIC 9(3)  VALUE 0.
       SCREEN SECTION.
       01 SCR-FORM.                                   * 一个"屏组"（screen）
           05 S-TITLE PIC X(24) FROM WS-TITLE         * 只读显示字段
               LINE 2 COLUMN 5 REVERSE-VIDEO HIGHLIGHT.
           05 S-NAME  PIC X(10) TO WS-NAME            * 只写输入字段
               LINE 4 COLUMN 18 UNDERLINE AUTO.
           05 S-AGE   PIC X(3)  TO WS-AGE
               LINE 6 COLUMN 18 BELL.
```

结构要点：

- **`01` 是屏组（screen），`05` 是屏内字段（field）**。层级与记录布局一样，但语义是"一屏"。
- **`LINE n COLUMN m`**：字段在终端上的绝对位置（行、列都从 1 起）。
- **`PIC` 决定字段宽度与类型**：`X(n)` 收字符串，`9(n)` 只收数字（输入非数字会被拒）。

## 2. FROM / TO / 双向：字段与数据项怎么绑

屏字段本身**不存数据**，它通过 `FROM`/`TO` 绑定到 `WORKING-STORAGE` 的数据项：

| 写法 | 方向 | 用途 |
|---|---|---|
| `FROM WS-X` | 数据 → 屏（只读） | 显示标签、标题、只读值 |
| `TO WS-X` | 屏 → 数据（只写） | 接收用户输入的字段 |
| `PIC X(n) VALUE "..."`（无 FROM/TO） | 常量 | 写死在屏上的静态文字 |
| 字段名本身即数据项（不推荐） | 双向 | 省一个变量，但可读性差 |

- `DISPLAY SCR-FORM` 时，`FROM` 字段把数据项的值画上屏。
- `ACCEPT SCR-FORM` 时，`TO` 字段把用户键入的值写回数据项。

> **坑（实测）：屏字段（SCREEN SECTION 里的项）不能和普通字面量/数据项混在同一个
> `DISPLAY` 里。** 我最初写 `DISPLAY "field1=[" SL-TITLE "]"`（`SL-TITLE` 是屏字段），
> 编译器报 `cannot mix screens and fields in the same DISPLAY statement`。
> 想打印屏字段的值，要打印它 `FROM`/`TO` 绑定的**工作数据项**，而不是屏字段本身。

## 3. 字段属性速查

`LINE`/`COLUMN` 之外，字段可带一串属性（可叠加）：

| 属性 | 效果 |
|---|---|
| `REVERSE-VIDEO` / `RV` | 反显（前景背景对调） |
| `HIGHLIGHT` / `LOWLIGHT` | 高亮 / 暗显 |
| `UNDERLINE` | 下划线 |
| `BLINK` | 闪烁（很多终端已不支持） |
| `BELL` / `BEEP` | 光标移到该字段时响铃 |
| `AUTO` | 输入满宽度后自动跳下一个字段 |
| `SECURE` | 输入不回显（密码框，显示 `*`） |
| `FOREGROUND-COLOR n` / `BACKGROUND-COLOR n` | 前/背景色（0-7 标准色） |
| `PICTURE` 带 `USAGE DISPLAY` | 普通字符字段 |

本示例用了 `REVERSE-VIDEO HIGHLIGHT`（标题）、`UNDERLINE AUTO`（姓名输入）、
`BELL`（年龄输入）、`LOWLIGHT`（确认行）。

## 4. DISPLAY / ACCEPT 整屏

```cobol
       PROCEDURE DIVISION.
       MAIN.
           DISPLAY SCR-FORM.       * 一次画出整屏所有 FROM 字段与静态文字
           ACCEPT SCR-FORM.        * 一次收集整屏所有 TO 字段（光标按 LINE 顺序跳）
           DISPLAY "收到: 姓名=[" WS-NAME "] 年龄=" WS-AGE.
```

- `DISPLAY 屏组名`：把整屏布局刷到终端（清屏 + 定位 + 画字段）。
- `ACCEPT 屏组名`：进入交互，光标依次停在各 `TO` 字段等输入，回车/`AUTO` 跳下一格，
  全部填完返回。也可 `ACCEPT 单个字段` 只收一格。
- `ACCEPT` 还能收**功能键/特殊键**（配合 `COB_SCREEN_EXCEPTIONS`），返回 `CRT STATUS`
  里的键码——做菜单导航时用得上。

## 5. 验证的难题：curses 与重定向不兼容

这是本章最"实测"的一节，也是本仓库验证方法论的一次典型应变。

> **真·上屏（`DISPLAY SCR-FORM`）走 curses，会吐出大量 ANSI 转义序列**（清屏、定位、
> 设色、显/隐光标……）。当 stdout 被重定向到文件（验证脚本正是如此），这些转义序列
> 原样落盘，输出变成一堆 `\033[2J\033[2;5H...` 的乱码——既过不了"无控制字符"判定，
> 也让 check/release 两通道无法逐字节比对。

我实测抓到的转义序列开头长这样（`od -c`）：

```text
033 [ ? 1 0 4 9 h 033 [ 2 2 ; 0 ; 0 t 033 [ 1 ; 2 4 r 033 ( B 033 [ m ...
033 [ 2 J 033 [ 2 ; 5 H = = =   H E L L O ...
```

**解法（借鉴本仓库 FreePascal GUI 章的 `--selftest` 思路）：用环境变量把"交互上屏"和
"确定性自检"分流。** 程序开头读一个环境变量，据此走两条路：

```cobol
           ACCEPT WS-MODE FROM ENVIRONMENT "COB_SCREEN_DEMO".
           IF WS-MODE NOT = SPACES
               PERFORM INTERACTIVE-MODE      * 设了变量：真上屏 + ACCEPT 键盘
           ELSE
               PERFORM SELFTEST-MODE         * 未设（脚本默认）：确定性打印，供判定
           END-IF.
```

- **自检模式**（脚本跑的默认路径）：**不触发任何 curses 调用**，直接给输入字段
  `MOVE` 上测试值，再按布局顺序把"位置 + 字段值"确定性 `DISPLAY` 出来。输出无控制字符、
  两通道逐字节一致，能进验证。
- **交互模式**（`COB_SCREEN_DEMO=1 ./15_screen`，人在真终端里跑）：`DISPLAY SCR-FORM` +
  `ACCEPT SCR-FORM`，体验真实的光标跳转、反显、响铃。

自检模式实测输出（`./run-all.sh 15 -v`，check/release 一致）：

```text
[L2 C5 ] title =[=== 用户登记表 === ]
[L4 C5 ] label =[姓名:     ]
[L4 C18] name  =[ALICE     ]
[L6 C5 ] label =[年龄:     ]
[L6 C18] age   =030
[L8 C5 ] ok    =[YES ]
==== 15 结束 ====
```

每行前缀 `[L行 C列]` 就是布局元数据，后面是绑定数据项的值——**用文本形式复现了"屏幕长什么样"
且可判定**。这套"声明式布局 + 自检分流"的做法，让 TUI 程序也能进 CI。

## 6. 交互模式的真实行为（含一个坑）

我在终端里用管道喂输入实测交互分支：

```text
$ printf 'BOB\n25\nY\n' | COB_SCREEN_DEMO=1 COB_EXIT_WAIT=off ./15_screen
... 收到: 姓名=[BOB ] 年龄=000 确认=[     ] ...
```

- **姓名 `BOB` 正确收到**——`ACCEPT` 的 `TO WS-NAME` 绑定生效。
- **年龄显示 `000`、确认为空**：这是 **curses 对"管道输入"的处理特性**，不是代码 bug。
  curses 的字段输入依赖真实终端的行编辑/键事件，管道喂进来的字节不被逐字段解析。
  **交互模式必须在真 TTY 里手动跑**（直接敲键盘），管道/重定向下行为不完整。
- **`COB_EXIT_WAIT=off`**：GnuCOBOL 默认在"有 screen DISPLAY 但没跟 ACCEPT"时，
  程序结束前打印 `end of program, please press a key to exit` 并等按键。设这个环境变量
  关掉等待，脚本化运行时才不会被卡住（`COB_EXIT_MSG ''` 可只去掉提示文字）。

## 7. 坑位清单（实测）

1. **屏字段不能和普通字面量/数据项混在同一个 `DISPLAY`**（`cannot mix screens and fields`）；
   要打印屏字段的值，打印它绑定的工作数据项。
2. **curses 输出与重定向不兼容**：真上屏吐 ANSI 转义序列，重定向即乱码。验证/CI 场景必须
   分流到"不上屏的自检模式"（本例用 `COB_SCREEN_DEMO` 环境变量）。
3. **`ACCEPT` 交互依赖真 TTY**：管道/重定向喂输入时，多字段收集不完整（本例年龄收不到）。
   交互测试要在真终端里敲键盘。
4. **`COB_EXIT_WAIT` 默认 true**：有 screen DISPLAY 无 ACCEPT 时结束前会等按键，
   脚本化运行要设 `COB_EXIT_WAIT=off`（或 `COB_EXIT_MSG ''`）避免卡住。
5. **`LINE`/`COLUMN` 从 1 起**，是终端绝对坐标；屏组里字段顺序决定 `ACCEPT` 时光标跳转顺序。
6. **`BLINK` 等属性很多现代终端不支持**：别把关键信息只靠闪烁传达，颜色/反显更可靠。

---
上一章：[14 结构化编程与文本复用](14-structured.md) ｜ 下一章：[16 与 C 互操作](16-c-interop.md) ｜ 返回：[README](../README.md)
