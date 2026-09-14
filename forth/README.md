# Forth / GForth 教程示例集

本目录按照本仓库统一标准整理为「教程文档 + 独立可运行示例 + 构建脚本」的结构，使用本机 gforth 0.7.3 对每个示例做实际运行验证。

## 目录结构

```text
forth/
├── README.md                 ← 本文件（目录说明 + 构建方式）
├── Forth编程指南.md            ← 教程正文（19 章 + 速查表 + 坑清单）
├── build.ps1                 ← 统一构建入口（PowerShell）
├── run-all.sh                ← macOS / Linux 下的一键运行与回归验证
├── examples/
│   ├── 01-hello-stack.fs
│   ├── 02-arithmetic.fs
│   ├── ...
│   └── 19-testing.fs
└── build/
```

## 工具链

- GForth：`/opt/local/bin/gforth`（0.7.3，macOS darwin）
- 库目录：`/opt/local/share/gforth/0.7.3/`
- PowerShell：`/opt/local/bin/pwsh`（7.6.5，构建脚本入口）

验证命令：

```bash
gforth --version
```

## 构建与验证

PowerShell（与本仓库其它目录一致）：

```powershell
cd /Users/xulun/code/programming/forth
pwsh ./build.ps1 -All                        # 全量验证
pwsh ./build.ps1 -File 04-control-flow.fs    # 单个示例
pwsh ./build.ps1 -Clean                      # 清理 build 目录
```

`build.ps1` 失败时返回退出码 1，可直接用于 CI / 回归检查。

等价的 shell 脚本（支持显示完整输出、按编号筛选）：

```bash
cd /Users/xulun/code/programming/forth
./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 07 15      # 只跑指定编号
```

单个示例：

```bash
gforth examples/04-control-flow.fs
```

### 判定标准

`build.ps1` / `run-all.sh` 对每个示例检查三件事，全绿才算通过：

1. 退出码为 0
2. stderr 没有任何输出
3. 结束最后一行显示 `<0>`（数据栈为空）

第 3 条是 Forth 特有的：某个词悄悄在栈上多留一个值，程序照样跑完不报错，但后续代码全被污染。
所以每个示例末尾都写了 `.s` 兜底 —— **写 Forth 时养成习惯，每个词跑完都看一眼栈**。

当前状态：19 个示例全部通过（gforth 0.7.3 / macOS，`build.ps1 -All` 与 `./run-all.sh` 双通道实测）。

## 已验证示例章节

| 编号 | 示例文件 | 主题 |
|---|---|---|
| 01 | `01-hello-stack.fs` | 数据栈、返回栈、浮点栈、摄氏↔华氏 |
| 02 | `02-arithmetic.fs` | 整数/定标/双精度/进制/`<# #>` 格式化 |
| 03 | `03-words-variables.fs` | 冒号定义、CONSTANT、VARIABLE、VALUE/TO、DEFER/IS |
| 04 | `04-control-flow.fs` | IF/CASE/DO LOOP/BEGIN UNTIL，九九表、FizzBuzz、素数筛 |
| 05 | `05-strings.fs` | `S"`、`C"`、`S\"`、比较、切分、拼接、`>number` |
| 06 | `06-arrays-memory.fs` | 一维/二维数组、越界检查、FILL/ERASE/MOVE/CMOVE |
| 07 | `07-recursion.fs` | RECURSIVE、备忘化、相互递归、阿克曼、汉诺塔、UTIME 计时 |
| 08 | `08-create-does.fs` | `CREATE ... DOES>` 定义「定义词的词」 |
| 09 | `09-locals.fs` | `{ }` 与 `locals| |` 局部变量、点积、解一元二次方程 |
| 10 | `10-heap-alloc.fs` | ALLOCATE/RESIZE/FREE、可增长动态数组、堆上链表 |
| 11 | `11-exceptions.fs` | CATCH/THROW、自定义异常码、资源清理 |
| 12 | `12-structures.fs` | `struct/field/end-struct`、嵌套、结构体数组 |
| 13 | `13-floats.fs` | 浮点字面量、运算、精度、牛顿法、数值积分 |
| 14 | `14-file-io.fs` | 文本/二进制读写、追加、slurp、一个能用的 wc |
| 15 | `15-oop.fs` | 手工 vtable OO、多态、mini-oof.fs 继承 |
| 16 | `16-vocabulary.fs` | 词表、搜索顺序、命名空间、MARKER |
| 17 | `17-metaprogramming.fs` | 编译期计算、immediate、postpone、DSL |
| 18 | `18-generators.fs` | 生成器协议、惰性序列、map/filter/take、管道 |
| 19 | `19-testing.fs` | 自制断言库、栈平衡检查、异常断言、基准 |

## 说明

- Forth 是栈式、可交互、可自扩展的语言；GForth 是 ANS Forth 的主流开源实现。
- 本目录的示例均以「独立可执行」为目标：每个 `.fs` 文件自带 shebang，可单独运行，末尾统一 `bye` 退出。
- 教程正文见 [Forth编程指南.md](./Forth编程指南.md)，其中「gforth 0.7.3 坑清单」一章的每一条都是在本机真跑出来的结果。
- 本目录内容由 `/Users/xulun/code/forth` 的例程集整合而来，示例源码与验证脚本保持原有验证标准。
