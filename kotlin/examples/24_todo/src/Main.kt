// 24 实战 · 演示：对 build/demo/tasks.json 跑完整场景（每次运行前清空 → 输出可复现）
import java.io.File

fun main() {
    val file = File("build/demo/tasks.json")
    file.delete()                      // 幂等：演示从空库开始

    val repo = JsonFileStore(file)

    fun run(vararg args: String) {
        val r = runCli(repo, args.toList())
        println("\$ ktodo ${args.joinToString(" ")}")
        r.lines.forEach { println("  $it") }
        if (r.exitCode != 0) println("  (exit ${r.exitCode})")
    }

    println("== 24.2 场景：增 → 列 → 勾 → 删 → 误用 ==")
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

    println("== 24.3 持久化文件内容 ==")
    println("  ${file.path} →")
    file.readLines().forEach { println("  $it") }

    println("== 24.4 help ==")
    run("help")

    println("== 24.5 收尾：清空 ==")
    run("clear")
    run("list")
}
