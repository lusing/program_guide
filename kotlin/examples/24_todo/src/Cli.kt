// 24 实战 · CLI 层：命令解析（sealed）+ 执行（唯一出口：CliResult(code, lines)）
// 退出码约定：0 成功 / 1 目标不存在 / 2 用法错误（与 git 等成熟 CLI 一致）

sealed interface Command {
    data class Add(val title: String) : Command
    data object List : Command
    data class Done(val id: Int) : Command
    data class Rm(val id: Int) : Command
    data object Clear : Command
    data object Help : Command
}

data class CliResult(val exitCode: Int, val lines: List<String>)

const val EXIT_OK = 0
const val EXIT_NOT_FOUND = 1
const val EXIT_USAGE = 2

val USAGE = listOf(
    "用法: ktodo <命令> [参数]",
    "  add <标题>     新增任务",
    "  list           列出全部",
    "  done <id>      勾选完成",
    "  rm <id>        删除任务",
    "  clear          清空全部",
    "  help           本帮助",
)

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

/** main 的实际入口：args → 退出码 + 输出（供测试直接调用，不走 System.exit） */
fun runCli(repo: TaskRepository, args: List<String>): CliResult =
    try {
        execute(repo, parse(args))
    } catch (e: IllegalArgumentException) {
        CliResult(EXIT_USAGE, listOf(e.message ?: "参数错误"))
    }
