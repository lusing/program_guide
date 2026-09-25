# 43 · jEdit 与系统工具：PIDE 视角

对应示例：`../examples/T43_system_jedit.thy`

## 43.1 一句话概括

jEdit 手册与 system 手册讲同一件事的两面：**PIDE 协议**
（异步、增量、持续检查）与围绕它的命令行工具链。理论侧轻
（重头在文档），但每条 ML 都过构建。

## 43.2 环境自检

```isabelle
ML ‹
  val _ = writeln ("ISABELLE_IDENTIFIER = " ^ getenv "ISABELLE_IDENTIFIER")
›
```

`getenv`（顶层 ML 函数）读环境变量，构建期看到的是构建进程的
视角（与命令行 `isabelle getenv` 一致）。实测会话里
`Isabelle_System.getenv` 未声明——用顶层 `getenv`。

## 43.3 会话选项

`declare [[goals_limit = 5]]` 影响本理论之后；`Options.default_int`
等读当前值。命令行全集 `isabelle options -l`；构建时覆盖
`isabelle build -o name=value`——本教程验证脚本关并行打印
（`parallel_print=false`）用的正是这个通道。

## 43.4 jEdit 五面板（文档节）

- **Output**：当前命令的消息（writeln、警告、反例）；
- **State**：证明态仪表盘（apply 脚本离不开）；
- **Theories**：装载状态与错误总览；
- **Symbols**：符号转义官方写法表；
- **Query**：find_theorems/find_consts/print_context 的 GUI 面。

## 43.5 命令行工具四类（文档节）

构建（`build`、`process_theories`）、查询（`getenv`、`options`、
`export`、`build_log`）、交互（`jedit -l`、`console`）、维护
（`build_history`、`update`）。堆与数据库在
`ISABELLE_HOME_USER/heaps`；换版本先清它。

## 43.6 Windows 三连坑（实测，全修进 run-all.sh）

1. Git Bash 直接跑 `bin/isabelle` 报
   `Failed to determine hardware and operating system type`
   ——唯一正解是经 `contrib/cygwin/bin/bash --login`。
2. Cygwin 登录 shell 里 isabelle 不在 PATH：用完整 cygwin 路径。
3. JDK 18+ 管道输出按 ANSI 代码页转码（本机 GBK）：中文 writeln
   变 GBK 字节，需用户级 settings 注入
   `-Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8`。

## 43.7 坑位清单（实测）

1. 上述 Windows 三连。
2. `declare [[...]]` 只影响当前理论之后；全局生效写进 ROOT 的
   `options [...]`。
3. `Options.default_int` 在构建与 jEdit 里可能不同（编辑器选项
   面板是另一份）。

## 43.8 与其他章的接口

- 第 21 章会话/ROOT 的系统面；第 22 章诊断选项的底层。
- 第 37 章 export_code 产物用 `isabelle export` 取。
- 第 44 章文档生成是另一个"消费理论内容"的下游。
