// 24 实战 · 领域模型：纯函数操作不可变任务列表（19-22 章手法汇总）

data class Task(val id: Int, val title: String, val done: Boolean = false)

/** 新增：返回新列表（不可变更新），id = 现有最大 id + 1 */
fun addTask(list: List<Task>, title: String): Pair<List<Task>, Int> {
    require(title.isNotBlank()) { "标题不能为空" }
    val id = (list.maxOfOrNull { it.id } ?: 0) + 1
    return list + Task(id, title.trim()) to id
}

/** 完成/勾选：存在则返回新列表，不存在返回 null（调用方决定报错） */
fun completeTask(list: List<Task>, id: Int): List<Task>? =
    if (list.any { it.id == id }) list.map { if (it.id == id) it.copy(done = true) else it } else null

fun removeTask(list: List<Task>, id: Int): List<Task>? =
    if (list.any { it.id == id }) list.filterNot { it.id == id } else null

/** 渲染：勾选状态 + 计数摘要（输出唯一事实源，测试与演示共用） */
fun renderTasks(list: List<Task>, showAll: Boolean = true): List<String> {
    val shown = if (showAll) list else list.filter { !it.done }
    val lines = shown.map { t -> "${if (t.done) "[x]" else "[ ]"} #${t.id} ${t.title}" }
    val summary = "共 ${list.size} 项，未完成 ${list.count { !it.done }} 项"
    return lines + summary
}
