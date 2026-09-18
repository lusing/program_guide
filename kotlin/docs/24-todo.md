# 24 · 实战：迷你待办 CLI（ktodo）⭐

> 对应示例：`examples/24_todo/`——零依赖的完整项目：模型 / 手写 JSON / 文件存储 / CLI。
> 前面 23 章的手法在这里各就各位。

## 24.1 需求与退出码

一个命令行待办管理器：

```
ktodo add <标题>       新增任务
ktodo list             列出全部
ktodo done <id>        勾选完成
ktodo rm <id>          删除
ktodo clear            清空
ktodo help             帮助
```

退出码约定（与 git 等成熟 CLI 一致）：**0 成功 / 1 目标不存在 / 2 用法错误**。脚本化时 `$LASTEXITCODE` 就是判据——示例 golden 里能看到 `done 99` 和未知命令分别拿 1 和 2。

## 24.2 分层结构

```
examples/24_todo/
├── src/
│   ├── Model.kt    领域：Task + 纯函数（addTask/completeTask/removeTask/renderTasks）
│   ├── Json.kt     手写 JSON：ADT + 递归下降解析器 + 编码器 + Task 映射
│   ├── Store.kt    TaskRepository 接口 + JsonFileStore 实现
│   ├── Cli.kt      Command(sealed) + parse + execute + runCli
│   └── Main.kt     演示场景（对 build/demo/tasks.json 全流程演练）
└── test/Tests.kt   25+ 断言：解析器/模型/存储/CLI 四组
```

依赖方向：`Main → Cli → (Model, Store) → Json`——**领域模型（Model）不依赖任何 IO**，这是全部可测性的来源。

## 24.3 领域层：纯函数 + 不可变列表

```kotlin
data class Task(val id: Int, val title: String, val done: Boolean = false)

fun addTask(list: List<Task>, title: String): Pair<List<Task>, Int> {
    require(title.isNotBlank()) { "标题不能为空" }
    val id = (list.maxOfOrNull { it.id } ?: 0) + 1
    return list + Task(id, title.trim()) to id          // 造新列表（22 章不可变更新）
}

fun completeTask(list: List<Task>, id: Int): List<Task>? =
    if (list.any { it.id == id }) list.map { if (it.id == id) it.copy(done = true) else it } else null
```

三个决策：

1. **输入输出都是 `List<Task>`**（不是 MutableList）——函数无状态，测试一行一个断言。
2. **"不存在"用 null 表达**（`List<Task>?`）——调用方（Cli）用 Elvis 分支转成退出码，04 章手法。
3. **id 生成 = max+1**：简单场景够用；并发/合并场景换 UUID。

## 24.4 JSON：ADT + 递归下降

解析器的数据模型是 08 章的密封层级（一图流）：

```kotlin
sealed interface Json {
    data object Null : Json
    data class Bool(val v: Boolean) : Json
    data class Num(val v: Number) : Json
    data class Str(val v: String) : Json
    data class Arr(val items: List<Json>) : Json
    data class Obj(val entries: List<Pair<String, Json>>) : Json {
        operator fun get(key: String): Json? = ...      // 06 章 operator 约定
    }
}
```

解析器是教科书式**递归下降**：一个游标 `i` + 每个 JSON 产生式一个函数（`value/obj/arr/string/number`），互递归下降。错误全用 `require/throw IllegalArgumentException`（16 章三件套），消息带**位置**（`位置 $i 附近: ...`）——调试坏 JSON 的救命稻草。

细节三则：

- 字符串转义：`\" \\ \/ \b \f \n \r \t \uXXXX`（\u 按十六进制码点解码）。
- 数字：带 `.`/`e` 判为 Double，否则 Long——`01x`、`[1,]`、未闭合字符串全被拒（测试逐个断言）。
- 编码器是 19 章那个 30 行版本的完整版（`JsonWriter.write` 递归 + `quote` 转义）。

**Task ↔ Json 的边界转换**各自 ~10 行：解析出的 Obj 取字段时用 `as?` 逐个兜底（`done` 缺失默认 false——旧数据兼容，测试覆盖）。

## 24.5 存储层：接口隔离 IO

```kotlin
interface TaskRepository {
    fun load(): List<Task>
    fun save(tasks: List<Task>)
}

class JsonFileStore(private val file: File) : TaskRepository {
    override fun load(): List<Task> = if (file.exists()) tasksFromJson(file.readText()) else emptyList()
    override fun save(tasks: List<Task>) { file.parentFile?.mkdirs(); file.writeText(tasksToJson(tasks)) }
}
```

20 章的 fake（InMemoryStore）在测试里直接换掉文件实现——**CLI 全链路测试不碰磁盘**。真实现就是"读全文 → 解析 / 序列化 → 写全文"：千级任务足够；再大量级这个接口后面换 SQLite 实现，CLI 与领域层一行不改。

## 24.6 CLI 层：sealed Command + 单一出口

```kotlin
sealed interface Command {
    data class Add(val title: String) : Command
    data object List : Command
    data class Done(val id: Int) : Command
    ...
}

fun parse(args: List<String>): Command = when { ... }        // 字符串 → 意图（可全测）

data class CliResult(val exitCode: Int, val lines: List<String>)

fun execute(repo: TaskRepository, cmd: Command): CliResult = when (cmd) { ... }

fun runCli(repo: TaskRepository, args: List<String>): CliResult =
    try { execute(repo, parse(args)) }
    catch (e: IllegalArgumentException) { CliResult(EXIT_USAGE, listOf(e.message ?: "参数错误")) }
```

关键设计：**输出不直接 println**——`CliResult(code, lines)` 是唯一出口：

- 测试直接断言 lines 与 exitCode（golden 同源）；
- 未来加 `--json` 输出模式只是多一个渲染函数；
- Main 拿到结果统一打印。

08 章 sealed + 穷尽 when 在 `execute` 里再次兑现：**新增命令时漏改 execute 编译不过**。

## 24.7 Main：幂等演示

```kotlin
val file = File("build/demo/tasks.json")
file.delete()                                  // 每次从空库开始 → 输出可复现（快照层的前提）
val repo = JsonFileStore(file)

fun run(vararg args: String) {
    val r = runCli(repo, args.toList())
    println("$ ktodo ${args.joinToString(" ")}")
    r.lines.forEach { println("  $it") }
}
```

场景脚本：增 ×3 → list → done → list → rm → 三个误用（done 99 / 未知命令 / add 空参）→ 展示落盘的 JSON 文件原文 → help → clear。golden（expected.txt）47 行，把这个脚本的全部输出钉死。

## 24.8 测试矩阵

| 组 | 覆盖 | 关键断言 |
|---|---|---|
| 解析器 | 6 种标量、嵌套、转义、5 种畸形输入 | `01x`、`[1,]`、未闭合全抛 |
| 编码器 | 各类型、转义往返 | `"tab\there"` |
| 模型 | 增/勾/删/渲染 + 边界（空标题、不存在 id、trim） | null 语义 |
| 存储 | 文件不存在 → 空表；save→load 相等；中文引号转义落盘 | 19 章往返模式 |
| 兼容 | 旧数据缺 done 字段 | 默认 false |
| CLI | happy path 全流程 + 4 种错误 + help | 退出码逐个断言 |

**"CLI 全链路测试"用内存 repo**：`runCli(memRepo(), listOf("add", "任务A"))` 断言 `exitCode == 0`——命令行行为不需要起进程就能钉死。

## 24.9 可以继续做什么（练习方向）

1. `list --pending` 过滤（Model 已有 showAll 参数，接 CLI 即可）。
2. `due <id> <日期>` 截止日（19 章 java.time 进 Task）。
3. JSON 改用 kotlinx-serialization（17 章 Gradle 依赖）对比手写版。
4. `ktodo export` 输出 HTML 报告（23 章 builder 直接复用）。
5. 存储换 SQLite（JDBC + Dispatchers.IO，21 章选型表）。
6. 补 JUnit5 参数化测试（17 章工程形态）替换手写表驱动。

## 24.10 坑位清单

1. **演示/测试必须幂等**：开工先 `file.delete()`（或临时目录）——快照测试被上次残留污染是最常见的"假红"。
2. `System.exit(code)` 放在**最外层 main**，不要进 runCli——否则测试进程直接被杀死（这就是 CliResult 存在的原因）。
3. 手写解析器**别吞错误位置**——异常消息里带 `位置 $i`，否则坏数据没法查。
4. `when` 穷尽 + sealed Command 的红利依赖"不写 else"——忍不住写 else 就把安全网拆了（08 章坑 1 重申）。
5. 旧版本数据的**字段兼容**要显式设计（done 缺失默认值）——测试里专门留一个"旧数据"用例。
6. 文件读写的**父目录**要 mkdirs——`writeText` 不会替你建目录（19 章坑 4）。
