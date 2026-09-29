package guide.android.compose.samples

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

// —— 依赖注入的最小可行集：接口 + 两个实现 + 手写容器（零注解处理器）——

/** 数据层接口：UI 只依赖它，测试/换源时可替换任意实现 */
interface NoteRepository {
    fun loadNotes(): List<String>
}

/** 教学用假实现 A：真实项目里换成 Room/网络数据源 */
class InMemoryNoteRepository : NoteRepository {
    override fun loadNotes() = listOf("默认源 · 便签 A", "默认源 · 便签 B")
}

/** 教学用假实现 B：演示“换实现不动 UI” */
class BackupNoteRepository : NoteRepository {
    override fun loadNotes() = listOf("备份源 · 便签 X", "备份源 · 便签 Y", "备份源 · 便签 Z")
}

/**
 * 手动 DI 容器：真实工程在 Application 里创建全局一份、集中装配所有依赖；
 * 这里为演示切换，按需构造
 */
class AppContainer(val noteRepository: NoteRepository = InMemoryNoteRepository())

/**
 * 用 CompositionLocal 把容器送进组合树——避免逐层透传（prop drilling）。
 * 正式项目更常用 Hilt：@HiltViewModel + hiltViewModel() 由编译期生成的工厂完成装配
 */
val LocalAppContainer = compositionLocalOf { AppContainer() }

@Composable
fun EcoManualDiSample() {
    var useBackup by remember { mutableStateOf(false) }
    val container = remember(useBackup) {
        if (useBackup) AppContainer(BackupNoteRepository()) else AppContainer()
    }
    CompositionLocalProvider(LocalAppContainer provides container) {
        val repo = LocalAppContainer.current.noteRepository
        Column(modifier = Modifier.padding(vertical = 6.dp)) {
            Text("生态1：手动依赖注入 AppContainer", fontWeight = FontWeight.Bold)
            // UI 只面向 NoteRepository 接口编程：换数据源，这几行不用改
            repo.loadNotes().forEach { note ->
                Text(text = "· $note", modifier = Modifier.padding(top = 2.dp))
            }
            Button(
                onClick = { useBackup = !useBackup },
                modifier = Modifier.padding(top = 4.dp)
            ) { Text(if (useBackup) "切回默认数据源" else "切换到备份数据源") }
            Text(
                text = "手写装配在依赖图变大后难以为继；Hilt 用 KSP 生成装配代码，本工程不接 KSP（见第 19 章）",
                color = Color.Gray,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
    }
}
