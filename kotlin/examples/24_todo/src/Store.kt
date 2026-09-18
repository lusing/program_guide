// 24 实战 · 存储层：接口 + 文件实现（20 章的"假实现测试"在这里兑现为可替换设计）
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
