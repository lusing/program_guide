# Erlang/OTP 教程

按本仓库统一的 `guide` 结构组织的 Erlang/OTP 教程：**一份内容充实的指南正文 + 28 个
独立可运行的示例 + 两个等价的验证入口**。

验证环境：Erlang/OTP 29（erts 17.0.3），macOS（MacPorts `/opt/local/bin/erl`）。

## 目录结构

```text
erlang/
├── README.md                  本文件
├── Erlang-OTP编程指南.md       教程正文（约 4300 行，30 章）
├── build.ps1                  PowerShell 入口（Windows / macOS / Linux）
├── run-all.sh                 shell 入口（macOS / Linux / WSL）
├── examples/
│   ├── 01-hello.erl           NN-topic.erl：两位编号 + 主题
│   ├── ...
│   ├── 28-debugging-ops.erl
│   └── kvapp/                 第 23、28 章用的最小 OTP application
│       ├── kvapp.app
│       ├── kvapp_app.erl
│       ├── kvapp_sup.erl
│       └── kvapp_store.erl
└── build/                     编译与运行产物（不入库）
    ├── ebin/                  所有 .beam
    └── <示例名>/
        ├── stdout.txt  stderr.txt       通道 A（默认调度器）
        └── stdout.s1.txt stderr.s1.txt  通道 B（+S 1:1）
```

## 工具链

| 工具 | 说明 |
| --- | --- |
| `erl` | 虚拟机 + REPL。非交互跑示例：`erl -noshell -pa build/ebin -run '01-hello' main -s init stop` |
| `erlc` | 编译器。本仓库用 `erlc -Werror -Wall`（**警告即错误**） |

两个入口都会自动探测工具链；也可以显式指定：

```bash
ERL=/opt/local/bin/erl ERLC=/opt/local/bin/erlc ./run-all.sh
```

## 怎么跑

```bash
./run-all.sh                 # shell 版（macOS / Linux / WSL）
pwsh ./build.ps1 -All        # PowerShell 版（Windows / macOS / Linux）
```

| 需求 | shell 版 | PowerShell 版 |
| --- | --- | --- |
| 跑全部 | `./run-all.sh` | `pwsh ./build.ps1 -All` |
| 附带打印每个示例的输出 | `./run-all.sh -v` | `pwsh ./build.ps1 -All -ShowOutput` |
| 只跑指定编号 | `./run-all.sh 01 13` | `pwsh ./build.ps1 01 13` |
| 只跑指定文件 | （用编号） | `pwsh ./build.ps1 -Example 24-ets.erl` |
| 清理 build | `./run-all.sh --clean` | `pwsh ./build.ps1 -Clean` |
| 改超时上限 | `TIMEOUT_SECS=8 ./run-all.sh` | `pwsh ./build.ps1 -All -TimeoutSec 8` |

> **两个入口不要并行跑**：它们共用 `build/<示例名>/` 下的输出文件，
> 并行会互相覆盖 → 输出只写一半、结束标记丢失 → 误报成"示例 bug"。

单个文件自己编译运行：

```bash
erlc -Wall -Werror -o build/ebin examples/01-hello.erl
erl -noshell -pa build/ebin -run '01-hello' main -s init stop
```

## 判定标准（四条，缺一不可）

1. **退出码为 0**
2. **stderr 为空**
3. **stdout 里除 TAB/LF/CR 外没有 0..31 的控制字符**
4. **stdout 里有结束标记 `==== NN 结束 ====`**

第 4 条最关键：Erlang 里 `main/0` 崩了、而没人 link 它时，`erl` 的退出码**仍可能是 0**。
只有结束标记能证明"这个示例真的从头跑到尾"。

### 为什么是"两个通道"而不是"多实现比对"

仓库里 fortran / sml 那几个目录的惯例是每份示例在**两套实现**上跑。Erlang 这里做不到 ——
本机只有一套实现（OTP 29 / erts 17.0.3）。所以改成**同一份 BEAM、两种运行时配置**：

| 通道 | 参数 | 含义 |
| --- | --- | --- |
| A | （默认） | 多调度器 |
| B | `+S 1:1` | 单调度器 |

两通道输出必须**逐字节一致**。这条约束抓的是"输出依赖调度/环境"的东西：
map 迭代顺序（原子哈希随机种子）、ETS set 顺序、打了 pid / ref / 时间戳、
以及内存字节数和 `port_limit` 这类随环境变的数字。

最后这一类无法"修好"，只能**改断言形式**：把"打具体数字"改成打布尔断言
（"每个都 > 0"、"递减"、"三者之和 ≤ 总内存"）。第 26.6、28.4 节就是这么处理的。

### 反向验证

判定标准本身也可能有 bug —— 一个永远返回 OK 的判定函数比没有判定更危险。
所以改完判定逻辑要造几个"故意违规"的示例，确认它真报 FAIL。做过的场景：
缺结束标记 / stderr 非空 / stdout 含控制字符 / `halt(3)` / 永不结束（超时）/
编译失败 / 两通道不一致 —— 两个入口都真的报了 FAIL。

## 各章索引

| 编号 | 主题 | 编号 | 主题 |
| --- | --- | --- | --- |
| 01 | 模块、函数与 Hello World | 15 | 错误处理哲学 |
| 02 | 数值与算术 | 16 | proplists 与配置 |
| 03 | 原子、字符串与 Unicode | 17 | 集合容器 |
| 04 | 模式匹配 | 18 | 进程 |
| 05 | 卫语句（guard） | 19 | 消息传递 |
| 06 | 递归与尾调用 | 20 | 链接与监控 |
| 07 | 列表 | 21 | gen_server |
| 08 | 推导式 | 22 | supervisor |
| 09 | 二进制与位语法 | 23 | application |
| 10 | 映射（map） | 24 | ETS |
| 11 | 记录（record） | 25 | 文件 I/O 与二进制序列化 |
| 12 | 函数与 fun | 26 | 定时器、时间与系统限制 |
| 13 | 控制流与异常 | 27 | 日志（logger）与可观测性 |
| 14 | 高阶函数 | 28 | 调试、热加载与运维 |

指南正文另有：**第 0 章**（环境与工具链）、**第 29 章**（构建与验证）、
**第 30 章**（坑总表，80+ 条实测踩过的坑）、以及**常用命令速查**附录。

## 目录里的三条约定

1. **文档里每条输出都能溯源**。指南里的「实测输出」块全部来自
   `build/<章>/stdout.txt`。复核办法：`./run-all.sh 25` 然后
   `cat build/25-binary-files/stdout.txt`。已做过一次全量抽查，
   文档中所有输出行都能在对应产物里找到出处。
2. **不能凭记忆写语言结论**。凡是"应该如此"的地方都实测过 —— 第 30 章坑总表里
   一大半是被实测推翻的直觉（浮点溢出是 badarith 不是 inf、
   `timer` 模块 OTP 27+ 不一定走 `timer_server`、`write_concurrency` 在单调度器下会被静默降级……）。
3. **新增示例要满足四条判定 + 两通道一致**，并且文件头要写准确的编译/运行命令、
   最后一行要打 `==== NN 结束 ====`。

## 当前状态

- 28 个示例全部编译通过（`-Werror -Wall`，零警告）并实跑通过；
- 两个入口各 56 项（28 示例 × 2 通道）全部通过：**通过 56　失败 0　不可重复 0**；
- 两个入口产生的 112 个产物文件（28 示例 × 2 通道 × stdout/stderr）**逐字节一致**：
  一致 112　不一致 0。
