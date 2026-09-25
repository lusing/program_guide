theory T43_system_jedit
  imports Main
begin

section \<open>43.1 集成开发环境与工具链：PIDE 视角\<close>

text \<open>jEdit 手册（jedit.pdf）与 system 手册（system.pdf）讲同一件事的
两面：**PIDE 协议**（异步、增量、持续检查）与围绕它的命令行工具链。
本章把日常会用到的操作面压成四块：环境自检、会话/堆管理、jEdit 面板
导航、常用 isabelle 子命令。理论侧轻（本章的重头在文档里），但每条
ML 都过构建。\<close>

ML \<open>writeln "==== 43 开始 ===="\<close>

subsection \<open>43.2 环境自检：从理论内看到的系统\<close>

text \<open>@{verbatim "Isabelle_System"} 是 ML 侧系统调用的门面。构建期
读到的环境变量是**构建进程**的视角——与命令行 @{verbatim "isabelle getenv"}
一致：\<close>

ML \<open>
  val _ = writeln ("ISABELLE_IDENTIFIER = " ^ getenv "ISABELLE_IDENTIFIER")
  val _ = writeln ("ML_SYSTEM = " ^ getenv "ML_SYSTEM")
  val _ = writeln ("ISABELLE_HOME_USER = " ^ getenv "ISABELLE_HOME_USER")
\<close>

subsection \<open>43.3 会话选项的声明与查询\<close>

text \<open>第 22 章的打印开关属于**会话选项**系统。理论内可以
@{verbatim "declare [[...]]"}（影响本理论及之后），也可以读当前值：\<close>

declare [[goals_limit = 5]]

ML \<open>
  val n = Options.default_int "goals_limit"
  val _ = writeln ("goals_limit = " ^ string_of_int n)
\<close>

text \<open>命令行全集用 @{verbatim "isabelle options -l"} 列出；
构建时覆盖用 @{verbatim "isabelle build -o name=value"}（验证脚本
关并行打印用的正是这个通道）。\<close>

subsection \<open>43.4 jEdit 面板速查（文档节）\<close>

text \<open>PIDE 的"持续检查"意味着：光标停在哪里，状态就是哪里的。
日常五个面板：

  - **Output**：当前命令的消息（警告、 @{verbatim "writeln"}、反例）；
  - **State**：证明态（目标列表、假设、类型）——apply 脚本的仪表盘；
  - **Theories**：理论装载状态与错误下划线总览；
  - **Symbols**：符号补全表（@{verbatim "\<forall>"} 这类转义的官方写法）；
  - **Query**：@{verbatim "find_theorems"} / @{verbatim "find_consts"} /
    @{verbatim "print_context"} 的交互界面（第 17/22 章工具的 GUI 面）。

键盘三件套：@{verbatim "C+e C+e"}（回到错误处）、补全 @{verbatim "Escape"}
或直接敲前缀、@{verbatim "C+RETURN"} 发送文本（多行编辑时）。\<close>

subsection \<open>43.5 命令行工具速查（文档节）\<close>

text \<open>@{verbatim "isabelle"} 的子命令按用途分四类（全部离线）：

  - 构建：@{verbatim "build"}（-D 目录 / -b 只建堆 / -o 选项）、
    @{verbatim "process_theories"}（临时 Draft 跑理论，本教程验证
    脚本的核心）；
  - 查询：@{verbatim "getenv"}、@{verbatim "options"}、
    @{verbatim "export"}（取会话导出，第 37 章 codegen 文件）、
    @{verbatim "build_log"}；
  - 交互：@{verbatim "jedit"}（-l 选逻辑 / -D 会话目录）、
    @{verbatim "console"}（ML/Scala REPL）；
  - 维护：@{verbatim "build_history"}、@{verbatim "update"}。

堆（heap）与数据库在 @{verbatim "ISABELLE_HOME_USER/heaps"}；
换版本先清它（验证脚本把 @{verbatim "USER_HOME"} 指到临时目录
就是同一招）。\<close>

subsection \<open>43.6 坑位清单（实测）\<close>

text \<open>1. **Windows 版必须经自带 Cygwin**：Git Bash 里直接跑
   @{verbatim "bin/isabelle"} 报
   @{verbatim "Failed to determine hardware and operating system type"}；
   正确入口 @{verbatim "contrib/cygwin/bin/bash --login"}。
2. **Cygwin 登录 shell 里 isabelle 不在 PATH**：用完整路径
   @{verbatim "/cygdrive/盘/.../bin/isabelle"}。
3. **JDK 18+ 管道输出编码**：中文 writeln 会按 ANSI 代码页转码
   （本机 GBK），需在用户级 settings 加
   @{verbatim "-Dstdout.encoding=UTF-8"}（验证脚本自动写入）。
4. @{verbatim "declare [[...]]"} 影响的是**当前理论之后**的部分，
   想全局生效要写进会话选项（ROOT 的 @{verbatim "options [..]"}）。
5. @{verbatim "Options.default_int"} 等取值函数在理论处理期返回
   构建进程的当前值——构建与 jEdit 里跑同一理论可能不同
   （编辑器的选项面板是另一份）。\<close>

subsection \<open>43.7 与其他章的接口\<close>

text \<open>第 21 章会话与 ROOT：本章是其系统面。第 22 章诊断选项的
底层就是会话选项系统。第 37 章 @{verbatim "export_code"} 的产物
用 @{verbatim "isabelle export"} 取。第 44 章文档生成是 jEdit 之外
另一个"消费理论内容"的下游。\<close>

ML \<open>writeln "==== 43 结束 ===="\<close>

end
