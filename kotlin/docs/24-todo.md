# 24 · 实战：迷你待办 CLI（ktodo）⭐

> 对应示例：`examples/24_todo/`——零第三方依赖的完整命令行项目：
> 领域模型、手写 JSON 解析器/编码器、文件存储、CLI 解析与执行，五个源文件各管一层。
> 本章所有代码逐字引自 `src/` 五个文件，所有输出引自 `expected.txt`（47 行快照）。
>
> 一个能增删查改的待办 CLI，配上手写 JSON 持久化——这个题材在 2018–2020 年的
> Kotlin 入门书里是标配练手项目。本章用 Kotlin 2.4.21（K2 编译器）+ JDK 21 的现代写法
> 把它从头讲透：不引用任何外部书页，递归下降解析器的完整思路都在正文里。

前面 23 章学过的每一块——data class、sealed、when 穷尽、不可变更新、扩展函数、
运算符约定、空安全分支——都会在这个项目里各就各位。这一章的重点不是"又学新语法"，
而是看**一个真实的小项目怎样把语言特性组装成分层结构**，
以及每一层为什么长成那个样子。

## 24.1 需求与退出码

需求一句话：命令行待办管理器，六个命令：

```text
ktodo add <标题>       新增任务
ktodo list             列出全部
ktodo done <id>        勾选完成
ktodo rm <id>          删除
ktodo clear            清空
ktodo help             帮助
```

功能本身平平无奇，值得先讲的是**退出码约定**（引自 `src/Cli.kt` 头部注释与常量）：

```kotlin
const val EXIT_OK = 0
const val EXIT_NOT_FOUND = 1
const val EXIT_USAGE = 2
```

三个码的语义：**0 成功 / 1 目标不存在 / 2 用法错误**。这是成熟 CLI 的通行约定
（git、grep 都是这个家族）。为什么一个教学项目要先定退出码？因为命令行工具的
**用户不只是人，还有脚本**——脚本判断成败靠的不是 stdout 的文字，而是退出码
（shell 里的 `$?`、PowerShell 里的 `$LASTEXITCODE`）。"成功"和"没找到"和"命令打错了"
是三件不同的事：没找到任务值得脚本重试或跳过，用法错误则应该直接报警。
从本章的快照里能看到三者各就各位：`done 99` 拿到 1，`frobnicate` 和裸 `add` 拿到 2。

## 24.2 分层结构

项目只有五个源文件，但每一行代码都有明确的"层"：

```text
examples/24_todo/
├── src/
│   ├── Model.kt    领域：Task + 纯函数（addTask/completeTask/removeTask/renderTasks）
│   ├── Json.kt     手写 JSON：ADT + 递归下降解析器 + 编码器 + Task 映射
│   ├── Store.kt    TaskRepository 接口 + JsonFileStore 实现
│   ├── Cli.kt      Command(sealed) + parse + execute + runCli
│   └── Main.kt     演示场景（对 build/demo/tasks.json 全流程演练）
└── test/Tests.kt   解析器/模型/存储/CLI 四组断言
```

依赖方向是单行道：`Main → Cli → (Model, Store) → Json`。
这个结构里最重要的性质一句话：**领域模型（Model）不依赖任何 IO**——
不读文件、不打印、不退出进程。它就是"任务列表"这个概念的纯数据加纯函数。
全部可测性都从这个性质长出来：测领域逻辑不需要文件系统，
测 CLI 行为不需要起进程（24.8 会看到）。反过来，一旦 Model 里出现一句 `println`，
这两个好处同时作废。分层不是洁癖，是**把"难测的东西"（IO、进程）压缩到最薄的两层**。

## 24.3 领域层：纯函数 + 不可变列表

`src/Model.kt` 全文不到 30 行，值得逐段看。先是数据本身：

```kotlin
data class Task(val id: Int, val title: String, val done: Boolean = false)
```

一个任务：id、标题、完成标记（默认未完成）。`data class` 白送 `equals/hashCode/copy`，
`copy` 马上就会用到。接着是三个操作函数，第一个是新增：

```kotlin
/** 新增：返回新列表（不可变更新），id = 现有最大 id + 1 */
fun addTask(list: List<Task>, title: String): Pair<List<Task>, Int> {
    require(title.isNotBlank()) { "标题不能为空" }
    val id = (list.maxOfOrNull { it.id } ?: 0) + 1
    return list + Task(id, title.trim()) to id
}
```

三个决策逐一拆开：

1. **入参出参都是 `List<Task>`（只读列表），返回新列表而不是改旧列表。**
   `list + Task(...)` 造出一个新列表（22 章的不可变更新手法）。函数因此**无状态**：
   同样的输入永远同样的输出，测试一行一个断言，不用担心调用顺序污染。
2. **id 生成策略是"现有最大 id + 1"**。
   [`maxOfOrNull`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/max-of-or-null.html)
   在空列表上返回 null，Elvis 兜底成 0，于是第一条任务拿到 id 1。
   单文件单机场景这个策略够用；多客户端并发或数据合并场景它会产生 id 冲突，
   那种场景该换 UUID——但那是另一个项目的需求，不为它过度设计。
3. **入参校验用
   [`require`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/require.html)**：
   空标题直接抛 `IllegalArgumentException`，消息"标题不能为空"。
   领域层把非法输入挡在门口，上层（Cli）把这个异常翻译成退出码 2——分工明确。

返回值类型是
[`Pair<List<Task>, Int>`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-pair/index.html)：
既给新列表，又给新分配的 id（调用方要打印"已添加 #N"）。最后一个表达式里的 `to`
是中缀函数造 Pair 的惯用法。

勾选与删除是一对，共用同一个"不存在怎么办"的答案：

```kotlin
/** 完成/勾选：存在则返回新列表，不存在返回 null（调用方决定报错） */
fun completeTask(list: List<Task>, id: Int): List<Task>? =
    if (list.any { it.id == id }) list.map { if (it.id == id) it.copy(done = true) else it } else null

fun removeTask(list: List<Task>, id: Int): List<Task>? =
    if (list.any { it.id == id }) list.filterNot { it.id == id } else null
```

**"目标不存在"用返回 null 表达**（`List<Task>?`），而不是抛异常——04 章的空安全分支手法。
为什么？因为"id 不存在"在这个领域里是**正常业务情况**（用户记错了编号），
不是程序错误；用可空返回把判断权交给调用方：Cli 层收到 null 就转成退出码 1 和一句
"没有 #N 这个任务"。`completeTask` 里的 `it.copy(done = true)` 是 data class 的标准更新姿势：
原对象不动，造一个只有 `done` 不同的副本。

最后是渲染——输出格式的**唯一事实源**：

```kotlin
/** 渲染：勾选状态 + 计数摘要（输出唯一事实源，测试与演示共用） */
fun renderTasks(list: List<Task>, showAll: Boolean = true): List<String> {
    val shown = if (showAll) list else list.filter { !it.done }
    val lines = shown.map { t -> "${if (t.done) "[x]" else "[ ]"} #${t.id} ${t.title}" }
    val summary = "共 ${list.size} 项，未完成 ${list.count { !it.done }} 项"
    return lines + summary
}
```

每个任务一行 `[ ] #1 标题`（完成则 `[x]`），末尾追加一行摘要"共 N 项，未完成 M 项"。
对照 `expected.txt` 里 `list` 命令的输出，逐字就是这个函数的产物：

```text
$ ktodo list
  [ ] #1 读完 Kotlin 指南第 24 章
  [x] #2 给示例写测试
  [ ] #3 提交 git
  共 3 项，未完成 2 项
```

`showAll = false` 时只列未完成项——这是给练习方向里的 `list --pending` 预留的参数。
把渲染收进领域层、返回 `List<String>` 而不是直接打印，是这个项目"随处可测"的第二块基石。

## 24.4 JSON：ADT + 递归下降

持久化格式选 JSON，但**不用任何 JSON 库**——手写一个。这既是教学（解析器是理解
"文本 → 结构"的最佳案例），也展示了零依赖能做到什么程度。整个 `src/Json.kt`
约 170 行，分四块：数据模型、解析器、编码器、Task 映射。

### 数据模型：JSON 的六种值是一个密封层级

JSON 规范里的值只有六种：null、布尔、数字、字符串、数组、对象。
"一个值是这六种之一，别无其他"——这正是密封层级的定义（08 章）：

```kotlin
sealed interface Json {
    data object Null : Json
    data class Bool(val v: Boolean) : Json
    data class Num(val v: Number) : Json
    data class Str(val v: String) : Json
    data class Arr(val items: List<Json>) : Json
    data class Obj(val entries: List<Pair<String, Json>>) : Json {
        operator fun get(key: String): Json? = entries.firstOrNull { it.first == key }?.second
    }
}
```

这就是 JSON 的**代数数据类型**（ADT）表示。几个设计点：

- `Arr` 和 `Obj` 的孩子还是 `Json`——**类型本身就是递归的**，和 JSON 文法同构。
  `value: Json` 里的 `value` 可以又是一个 `Obj`，任意深的嵌套天然可表达。
- `Obj` 用 `List<Pair<String, Json>>` 而不是 `Map`：保留键的插入顺序，
  也允许重复键（JSON 规范不禁止，后写覆盖是常见策略，这里保留原样）。
- `Obj` 上定义了 `operator fun get(key: String)`（06 章的运算符约定），
  于是能写 `obj["id"]` 取值，返回 `Json?`——键不存在是正常情况，用 null 表达。
  后面的 Task 映射全靠这个下标语法保持短小。

### 解析器：递归下降的完整思路

**递归下降**（recursive descent）是最直观的解析技术，一句话说清：
**给文法的每个产生式写一个函数，函数之间按文法互相调用**。
JSON 的文法是：

```text
value  := object | array | string | number | "true" | "false" | "null"
object := "{" [ string ":" value ("," string ":" value)* ] "}"
array  := "[" [ value ("," value)* ] "]"
```

于是解析器就有 `value()`、`obj()`、`arr()`、`string()`、`number()` 几个函数：
`value()` 看首字符分派，`obj()` 里调 `value()`（对象里有值），`arr()` 里也调
`value()`（数组里有值），而 `value()` 又可能回调 `obj()`/`arr()`——
**互递归**，嵌套多深就递归多深。所有函数共享一个游标（当前读到哪了）。

看实现。入口 `JsonParser.parse`：

```kotlin
object JsonParser {
    fun parse(src: String): Json {
        val p = P(src)
        p.ws()
        val v = p.value()
        p.ws()
        require(p.i >= src.length) { "JSON 末尾有多余内容（位置 ${p.i}）" }
        return v
    }
```

三步：跳过前导空白 → 解析一个值 → 跳过后续空白并**确认全文耗尽**。
最后那个 `require` 是很多人会漏的检查：没有它，`[1, 2] garbage` 这种输入
会被解析成 `[1, 2]` 然后静默丢掉尾巴——坏数据就这样混进了数据库。

游标类和基础动作：

```kotlin
    private class P(val s: String) {
        var i = 0
        fun ws() { while (i < s.length && s[i].isWhitespace()) i++ }
        fun expect(c: Char) {
            require(i < s.length && s[i] == c) { "期望 '$c'，位置 $i 附近: ${s.substring(i, minOf(i + 8, s.length))}" }
            i++
        }
```

整个解析器的状态就是**一个整数 `i`**（当前位置），所有函数读写它。
`ws()` 吞掉空白；`expect(c)` 断言当前字符必须是 `c` 并前进——
注意它的错误消息：`"期望 'c'，位置 i 附近: ..."` 带上位置和后文片段。
**解析器报错带位置是救命的设计**：坏 JSON 调试时，"位置 137 附近: `"dne": tru`"
比"解析失败"有用一万倍。这个习惯请原样带走。

`value()` 是分派中心，看当前字符决定走哪条产生式：

```kotlin
        fun value(): Json {
            require(i < s.length) { "JSON 意外结束" }
            return when (s[i]) {
                '{' -> obj()
                '[' -> arr()
                '"' -> Json.Str(string())
                't' -> lit("true", Json.Bool(true))
                'f' -> lit("false", Json.Bool(false))
                'n' -> lit("null", Json.Null)
                else -> number()
            }
        }
        fun lit(word: String, v: Json): Json {
            require(s.startsWith(word, i)) { "非法字面量，位置 $i" }
            i += word.length
            return v
        }
        fun peek(c: Char): Boolean = i < s.length && s[i] == c
```

首字符是 `{`/`[`/`"` 走对应产生式；`t`/`f`/`n` 是三个字面量的开头，
`lit` 验证后续字符真的拼成 `true`/`false`/`null`（于是 `truX` 会被拒）；
其余情况一律按数字处理——数字格式不合法？由 `number()` 自己报错，
分派处不用操心。`peek(c)` 只看不吃，是循环结构里的侦察兵。

对象和数组是**同一个循环模式的两个实例**：

```kotlin
        fun obj(): Json.Obj {
            expect('{'); ws()
            val entries = mutableListOf<Pair<String, Json>>()
            if (peek('}')) { i++; return Json.Obj(entries) }
            while (true) {
                val k = string(); ws(); expect(':'); ws()
                entries += k to value(); ws()
                when {
                    peek(',') -> { i++; ws() }
                    peek('}') -> { i++; return Json.Obj(entries) }
                    else -> throw IllegalArgumentException("对象里期望 ',' 或 '}'，位置 $i")
                }
            }
        }
        fun arr(): Json.Arr {
            expect('['); ws()
            val items = mutableListOf<Json>()
            if (peek(']')) { i++; return Json.Arr(items) }
            while (true) {
                items += value(); ws()
                when {
                    peek(',') -> { i++; ws() }
                    peek(']') -> { i++; return Json.Arr(items) }
                    else -> throw IllegalArgumentException("数组里期望 ',' 或 ']'，位置 $i")
                }
            }
        }
```

循环结构值得记住，它是"逗号分隔列表"的标准解析法：
开括号 → 特判空容器（直接闭括号就返回空）→ 循环【解析一项 →
看下一字符：逗号则吃掉继续，闭括号则吃掉收工，**否则报错**】。
那个 `else` 分支就是 `[1,]`（尾逗号）和 `[1 2]`（漏逗号）被拒之门外的地方——
JSON 不允许尾逗号，这项检查替你做主。

字符串产生式最长，因为要处理转义：

```kotlin
        fun string(): String {
            expect('"')
            val out = StringBuilder()
            while (true) {
                require(i < s.length) { "字符串未闭合" }
                when (val c = s[i]) {
                    '"' -> { i++; return out.toString() }
                    '\\' -> {
                        i++
                        require(i < s.length) { "转义未闭合" }
                        when (val e = s[i]) {
                            '"' -> out.append('"'); '\\' -> out.append('\\'); '/' -> out.append('/')
                            'b' -> out.append('\b'); 'f' -> out.append('[C'); 'n' -> out.append('\n')
                            'r' -> out.append('\r'); 't' -> out.append('\t')
                            'u' -> {
                                require(i + 4 < s.length) { "\\u 转义不完整" }
                                out.append(s.substring(i + 1, i + 5).toInt(16).toChar())
                                i += 4
                            }
                            else -> throw IllegalArgumentException("非法转义 \\$e")
                        }
                        i++
                    }
                    else -> { out.append(c); i++ }
                }
            }
        }
```

逻辑：吃到闭引号返回；遇到反斜杠进入转义分支，八个单字符转义
（`\" \\ \/ \b \f \n \r \t`）各归各位，`\u` 读 4 位十六进制按码点解码
（`substring(i + 1, i + 5).toInt(16).toChar()`）；其余字符原样追加。
两个 `require` 分别挡"字符串未闭合"和"转义写到一半"——输入在这些地方断掉时
报错消息直接告诉你断在哪。

数字产生式按文法分段消费：符号、整数段、可选小数段、可选指数段：

```kotlin
        fun number(): Json.Num {
            val start = i
            if (i < s.length && s[i] == '-') i++
            require(i < s.length && s[i].isDigit()) { "非法数字，位置 $i" }
            while (i < s.length && s[i].isDigit()) i++
            var isDouble = false
            if (i < s.length && s[i] == '.') {
                isDouble = true; i++
                require(i < s.length && s[i].isDigit()) { "小数点后缺数字" }
                while (i < s.length && s[i].isDigit()) i++
            }
            if (i < s.length && (s[i] == 'e' || s[i] == 'E')) {
                isDouble = true; i++
                if (i < s.length && (s[i] == '+' || s[i] == '-')) i++
                require(i < s.length && s[i].isDigit()) { "指数缺数字" }
                while (i < s.length && s[i].isDigit()) i++
            }
            val text = s.substring(start, i)
            return Json.Num(if (isDouble) text.toDouble() else text.toLong())
        }
```

策略是"**先按文法扫过整个词，再按出现的段决定类型**"：出现过 `.` 或 `e/E`
就是 Double，否则按 Long 解析——JSON 本身不区分整数浮点，但 Kotlin 分，
`Num` 里装 `Number` 就是为了同时容纳两种。`01x` 为什么被拒？`number()` 扫完
`01` 就停（`x` 不是数字段字符），回到 `parse` 的末尾检查时发现没耗尽全文——
每个畸形的拒绝路径都能指回某一行代码。

### 编码器：解析器的镜像

写回字符串比解析简单得多——递归遍历 ADT 拼字符串：

```kotlin
object JsonWriter {
    fun write(v: Json): String = when (v) {
        Json.Null -> "null"
        is Json.Bool -> v.v.toString()
        is Json.Num -> v.v.toString()
        is Json.Str -> quote(v.v)
        is Json.Arr -> v.items.joinToString(",", "[", "]") { write(it) }
        is Json.Obj -> v.entries.joinToString(",", "{", "}") { "${quote(it.first)}:${write(it.second)}" }
    }

    fun quote(s: String): String = buildString {
        append('"')
        for (c in s) when (c) {
            '"' -> append("\\\""); '\\' -> append("\\\\")
            '\n' -> append("\\n"); '\r' -> append("\\r"); '\t' -> append("\\t")
            '[C' -> append("\\f")
            else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
        }
        append('"')
    }
}
```

`write` 的 `when` **没有 else**——sealed 层级的红利：六种情况穷尽，编译器担保。
`quote` 是 `string()` 的逆运算：特殊字符转义回去，控制字符（`c < ' '`）
统一输出 `\u00XX` 形式。编码器与解析器**互逆**意味着一个经典测试：
`write(parse(x))` 与原文语义相等——24.8 的测试矩阵里就有这种往返用例。

### Task ↔ Json：边界上的翻译

最后一块是领域对象和 JSON 之间的翻译，编解码各约 10 行：

```kotlin
/** 领域对象 ↔ JSON 的转换（编解码各 ~10 行，正是 data class + when 的甜区） */
fun Task.toJson(): Json = Json.Obj(
    listOf("id" to Json.Num(id), "title" to Json.Str(title), "done" to Json.Bool(done)),
)

fun Json.toTask(): Task {
    val obj = this as? Json.Obj ?: error("任务必须是 JSON 对象")
    val id = (obj["id"] as? Json.Num ?: error("id 缺失")).v.toInt()
    val title = (obj["title"] as? Json.Str ?: error("title 缺失")).v
    val done = (obj["done"] as? Json.Bool)?.v ?: false   // 旧数据缺 done 字段 → 默认未完成
    return Task(id, title, done)
}

fun tasksToJson(tasks: List<Task>): String = JsonWriter.write(Json.Arr(tasks.map { it.toJson() }))

fun tasksFromJson(src: String): List<Task> {
    val root = JsonParser.parse(src)
    require(root is Json.Arr) { "根节点必须是数组" }
    return root.items.map { it.toTask() }
}
```

解码侧的手法值得细品：**逐级 `as?` 安全转换 + Elvis 兜底**。
`obj["id"] as? Json.Num` 只要键不存在或类型不对就得到 null，`?:` 立刻抛带消息的异常——
坏数据在哪一层坏掉，消息就指到哪一层。而 `done` 字段故意写成
`(obj["done"] as? Json.Bool)?.v ?: false`：**字段缺失时默认未完成**。
这不是偷懒，是**数据兼容设计**——旧版本存的数据没有 `done` 字段，
升级后照样能读。存储格式的演进靠这种"读取时宽容"的默认值完成，测试矩阵里
有专门一条覆盖它。[`error`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/error.html)
抛的是 `IllegalStateException`，语义是"数据违反本程序的不变量"。

## 24.5 存储层：接口隔离 IO

有了"任务列表 ↔ JSON 字符串"的双向翻译，存储层只剩两个动作：读全文、写全文。
但它仍然被设计成一个接口（`src/Store.kt` 全文）：

```kotlin
import java.io.File

interface TaskRepository {
    fun load(): List<Task>
    fun save(tasks: List<Task>)
}

/** JSON 文件存储：一行数组，整读整写（千级任务足够；更大的量级换 SQLite/数据库） */
class JsonFileStore(private val file: File) : TaskRepository {
    override fun load(): List<Task> =
        if (file.exists()) tasksFromJson(file.readText()) else emptyList()

    override fun save(tasks: List<Task>) {
        file.parentFile?.mkdirs()
        file.writeText(tasksToJson(tasks))
    }
}
```

`load`：文件不存在返回空列表（首次运行不是错误）；存在则
[`readText()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/read-text.html)
读全文交给解析器。`save`：先 `parentFile?.mkdirs()` 确保父目录存在——
[`writeText()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/write-text.html)
**不会替你建目录**，漏掉这行会在第一次保存时撞上 `FileNotFoundException`（19 章坑 4）。
整读整写在千级任务量下毫无压力；量级再大，把实现换成 SQLite，
`TaskRepository` 后面的世界（Cli、领域层）一行不用改。

接口存在的真正理由是**测试**：20 章的 fake 手法在这里兑现——
测试里用一个内存版 `TaskRepository`（两个方法操作一个 `var List<Task>`）替换文件实现，
CLI 的全链路测试就完全不碰磁盘。接口只有 `load/save` 两个方法，
fake 写起来三行——**接口越小，替身越便宜**。

## 24.6 CLI 层：sealed Command + 单一出口

CLI 层做两件事：把 `List<String>` 参数翻译成**意图**，把意图翻译成**执行结果**。
意图是一个密封层级（`src/Cli.kt`）：

```kotlin
sealed interface Command {
    data class Add(val title: String) : Command
    data object List : Command
    data class Done(val id: Int) : Command
    data class Rm(val id: Int) : Command
    data object Clear : Command
    data object Help : Command
}

data class CliResult(val exitCode: Int, val lines: List<String>)
```

六个命令六个分支：带参数的用 `data class`，无参数的用 `data object`。
`CliResult` 是执行结果：**退出码 + 输出行**，注意它**不含任何打印动作**——
这是全章最重要的一个设计，稍后再展开。

解析函数 `parse` 把字符串数组变成 `Command`：

```kotlin
fun parse(args: List<String>): Command = when {
    args.isEmpty() -> Command.Help
    args[0] == "add" && args.size >= 2 -> Command.Add(args.drop(1).joinToString(" "))
    args[0] == "add" -> throw IllegalArgumentException("add 需要标题: ktodo add <标题>")
    args[0] == "list" -> Command.List
    args[0] == "done" && args.size == 2 -> args[1].toIntOrNull()?.let { Command.Done(it) }
        ?: throw IllegalArgumentException("done 需要 id，得到 '${args[1]}'")
    args[0] == "done" -> throw IllegalArgumentException("done 需要一个 id: ktodo done <id>")
    args[0] == "rm" && args.size == 2 -> args[1].toIntOrNull()?.let { Command.Rm(it) }
        ?: throw IllegalArgumentException("rm 需要 id，得到 '${args[1]}'")
    args[0] == "rm" -> throw IllegalArgumentException("rm 需要一个 id: ktodo rm <id>")
    args[0] == "clear" -> Command.Clear
    args[0] == "help" -> Command.Help
    else -> throw IllegalArgumentException("未知命令 '${args[0]}'")
}
```

这个 `when` 是**条件分支形式**（不带目标值），从上到下逐条匹配，
模式值得学：**先匹配"形状正确"的分支（命令名 + 参数个数），形状不对再落入对应的报错分支**。
`add` 出现两次：第一次要求 `args.size >= 2`（标题里的空格由
`args.drop(1).joinToString(" ")` 重新拼回，所以 `ktodo add 写完 报告` 的标题是"写完 报告"）；
第二次接住裸 `add`，抛带用法提示的异常。id 参数用
[`toIntOrNull`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int-or-null.html)：
非数字得到 null，`?:` 抛异常——"done 需要 id，得到 'abc'"，
错误消息把用户输入原样回显。所有用法错误统一抛 `IllegalArgumentException`，
由上层统一翻译成退出码 2。

执行函数 `execute` 是 sealed + 穷尽 when 的又一次兑现：

```kotlin
/** 执行命令：读 → 领域函数 → 写 → 产出（命令行输出 + 退出码） */
fun execute(repo: TaskRepository, cmd: Command): CliResult = when (cmd) {
    is Command.Add -> {
        try {
            val (next, id) = addTask(repo.load(), cmd.title)
            repo.save(next)
            CliResult(EXIT_OK, listOf("已添加 #${id} ${cmd.title.trim()}"))
        } catch (e: IllegalArgumentException) {
            CliResult(EXIT_USAGE, listOf("添加失败: ${e.message}"))
        }
    }
    Command.List -> CliResult(EXIT_OK, renderTasks(repo.load()))
    is Command.Done -> {
        val next = completeTask(repo.load(), cmd.id)
        if (next == null) CliResult(EXIT_NOT_FOUND, listOf("没有 #${cmd.id} 这个任务"))
        else { repo.save(next); CliResult(EXIT_OK, listOf("完成 #${cmd.id}")) }
    }
    is Command.Rm -> {
        val next = removeTask(repo.load(), cmd.id)
        if (next == null) CliResult(EXIT_NOT_FOUND, listOf("没有 #${cmd.id} 这个任务"))
        else { repo.save(next); CliResult(EXIT_OK, listOf("已删除 #${cmd.id}")) }
    }
    Command.Clear -> { repo.save(emptyList()); CliResult(EXIT_OK, listOf("已清空")) }
    Command.Help -> CliResult(EXIT_OK, USAGE)
}
```

每个分支是同一个四拍：**load → 调领域函数 → save → 拼 CliResult**。
看三个翻译点如何各就各位：`Add` 分支里 `addTask` 的 `require` 抛出的
`IllegalArgumentException`（空标题）被就地 catch 成退出码 2；
`Done`/`Rm` 分支里领域函数返回的 null 被翻译成退出码 1 和"没有 #N 这个任务"；
`when` 没有 else——**新增第七个命令时，漏改 execute 直接编译不过**，
sealed 的安全网就是靠"忍住不写 else"保住的（08 章坑 1 的重申）。

最外层是 `runCli`，整个 CLI 的唯一入口：

```kotlin
/** main 的实际入口：args → 退出码 + 输出（供测试直接调用，不走 System.exit） */
fun runCli(repo: TaskRepository, args: List<String>): CliResult =
    try {
        execute(repo, parse(args))
    } catch (e: IllegalArgumentException) {
        CliResult(EXIT_USAGE, listOf(e.message ?: "参数错误"))
    }
```

`parse` 抛的用法异常在这里统一收口为退出码 2。现在回头看 `CliResult` 的设计，
它解决了两个问题：

1. **`System.exit` 不进库代码**。如果 `runCli` 内部调 `System.exit(2)`，
   测试进程会在第一个错误用例上直接死亡。让退出码以数据形式返回，
   由最外层的 `main` 决定何时退出进程——这就是"main 的实际入口"注释的深意。
2. **输出可断言**。`lines: List<String>` 是数据，测试直接断言内容；
   未来想加 `--json` 机器可读输出，只是多一个渲染函数，执行逻辑不动。

## 24.7 Main：幂等演示

`src/Main.kt` 把整条链路跑一遍。开头三行是快照测试的前提：

```kotlin
val file = File("build/demo/tasks.json")
file.delete()                      // 幂等：演示从空库开始

val repo = JsonFileStore(file)

fun run(vararg args: String) {
    val r = runCli(repo, args.toList())
    println("\$ ktodo ${args.joinToString(" ")}")
    r.lines.forEach { println("  $it") }
    if (r.exitCode != 0) println("  (exit ${r.exitCode})")
}
```

**先删文件再演示**——每次运行从空库开始，输出才可复现；
`expected.txt` 快照能被钉死，前提就是这一步幂等（快照被上次残留污染
是最常见的"假红"）。局部函数 `run` 是演示的脚手架：打印一条仿 shell 的
`$ ktodo ...` 命令行，缩进打印输出，退出码非零时补一行 `(exit N)`。

场景脚本覆盖 happy path 和三类误用：

```kotlin
run("add", "读完 Kotlin 指南第 24 章")
run("add", "给示例写测试")
run("add", "提交 git")
run("list")
run("done", "2")
run("list")
run("rm", "3")
run("done", "99")          // exit 1
run("frobnicate")          // exit 2
run("add")                 // exit 2
```

三种退出码在 `expected.txt` 里各就各位，逐字引用误用段：

```text
$ ktodo done 99
  没有 #99 这个任务
  (exit 1)
$ ktodo frobnicate
  未知命令 'frobnicate'
  (exit 2)
$ ktodo add
  add 需要标题: ktodo add <标题>
  (exit 2)
```

随后展示落盘文件原文——存储格式透明可见：

```text
== 24.3 持久化文件内容 ==
  build/demo/tasks.json →
  [{"id":1,"title":"读完 Kotlin 指南第 24 章","done":false},{"id":2,"title":"给示例写测试","done":true}]
```

打印路径那一行有个跨平台细节（引自 `Main.kt` 注释）：
`File("build/demo/tasks.json")` 构造时两种平台都接受 `/`，但 `.path` 在 Windows 上
会被规范成反斜杠形式，而快照只有一份——所以打印前归一分隔符：

```kotlin
println("  ${file.path.replace(File.separatorChar, '/')} →")
```

结尾是 `help` 与 `clear` 清场，最后一次 `list` 回到空态：

```text
$ ktodo clear
  已清空
$ ktodo list
  共 0 项，未完成 0 项
```

## 24.8 测试矩阵

`test/Tests.kt` 分四组，25+ 断言。整章在 Kotlin 2.4.21（K2）+ JDK 21 上的验证链是四层：
`kotlinc -Werror` 零告警 → kotlin.test 断言全绿 → 演示运行 exit 0 → 输出与
`expected.txt` 快照逐字节一致。

| 组 | 覆盖 | 关键断言 |
|---|---|---|
| 解析器 | 6 种标量、嵌套、转义、5 种畸形输入 | `01x`、`[1,]`、未闭合字符串全抛 |
| 编码器 | 各类型、转义往返 | `"tab\there"` 写读相等 |
| 模型 | 增/勾/删/渲染 + 边界（空标题、不存在 id、trim） | null 语义 |
| 存储 | 文件不存在 → 空表；save→load 相等；中文引号转义落盘 | 往返一致 |
| 兼容 | 旧数据缺 done 字段 | 默认 false |
| CLI | happy path 全流程 + 4 种错误 + help | 退出码逐个断言 |

最有价值的一行是最后一行：**CLI 全链路测试用内存 repo**——
`runCli(memRepo, listOf("add", "任务A"))` 直接断言 `exitCode == 0` 和输出行。
命令行行为不需要起进程就能钉死，这就是 24.2 那句"领域模型不依赖 IO"的红利兑现。

## 24.9 可以继续做什么（练习方向）

1. `list --pending` 过滤——`renderTasks` 的 `showAll` 参数已经预留，接通 CLI 即可。
2. `due <id> <日期>` 截止日——java.time 进 `Task`，JSON 映射里按字符串存。
3. JSON 改用 kotlinx-serialization，与手写版对比代码量和行为差异。
4. `ktodo export` 输出 HTML 报告——23 章的 builder 直接复用。
5. 存储换 SQLite（JDBC），验证 `TaskRepository` 接口后面的世界真的一行不改。
6. 把手写断言换成 JUnit5 参数化测试，体验工业级测试形态。

## 24.10 坑位清单

1. **演示/测试必须幂等**：开工先 `file.delete()`（或用临时目录）——快照被上次运行
   残留污染，是最常见的"假红"。
2. **`System.exit` 只出现在最外层 main**。它一进 `runCli`，测试进程就被杀死——
   `CliResult` 存在的全部意义就是把退出码变成数据。
3. **解析器报错必须带位置**。异常消息里的 `位置 $i 附近: ...` 不是装饰，
   是坏数据的唯一线索；吞掉位置的解析器等于没有错误处理。
4. **sealed + 穷尽 when 的红利依赖"不写 else"**。忍不住写 else 就是把
   "新增命令漏改 execute 编译不过"这张安全网亲手拆掉。
5. **旧数据的字段兼容要显式设计**（`done` 缺失默认 false），并在测试里
   留一个"旧格式"用例——兼容逻辑没有测试守护，下次重构就没了。
6. **写文件先建父目录**：`parentFile?.mkdirs()`——`writeText` 不替你建目录，
   首次运行必炸（19 章坑 4 的重申）。

---

上一章：[23 ⭐类型安全 DSL](23-dsl.md) · 下一章：[25 ⭐多平台：JS/Native/Wasm](25-multiplatform.md)
