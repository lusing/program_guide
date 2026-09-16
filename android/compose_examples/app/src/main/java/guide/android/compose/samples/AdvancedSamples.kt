package guide.android.compose.samples

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import androidx.work.CoroutineWorker
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.random.Random

class CounterViewModel : ViewModel() {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count

    fun increment() {
        _count.update { it + 1 }
    }
}

@Composable
fun AdvancedViewModelStateFlowSample() {
    val vm: CounterViewModel = viewModel()
    val count by vm.count.collectAsStateWithLifecycle()
    Text(
        text = "进阶1：ViewModel + StateFlow = $count（点击+1）",
        modifier = Modifier
            .fillMaxWidth()
            .clickable { vm.increment() }
            .padding(vertical = 6.dp)
    )
}

@Composable
fun AdvancedNavigationSample() {
    val navController = rememberNavController()
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("进阶2：Navigation Compose")
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.fillMaxWidth()
        ) {
            composable("home") {
                Text(
                    text = "首页（点击进入详情页 id=42）",
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { navController.navigate("detail/42") }
                        .padding(top = 4.dp)
                )
            }
            composable(
                route = "detail/{id}",
                arguments = listOf(navArgument("id") { type = NavType.StringType })
            ) { entry ->
                val id = entry.arguments?.getString("id") ?: "unknown"
                Text(text = "详情页 id=$id", modifier = Modifier.padding(top = 4.dp))
            }
        }
    }
}

@Entity(tableName = "notes")
data class NoteEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val createdAt: Long
)

@Dao
interface NoteDao {
    @Query("SELECT * FROM notes ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<NoteEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(note: NoteEntity)
}

@Database(entities = [NoteEntity::class], version = 1, exportSchema = false)
abstract class GuideRoomDatabase : RoomDatabase() {
    abstract fun noteDao(): NoteDao
}

@Composable
fun AdvancedRoomArchitectureSample() {
    Text(
        text = "进阶3：Room 实体/DAO/Database 已定义（可直接接入 Room.databaseBuilder）",
        modifier = Modifier.padding(vertical = 6.dp)
    )
}

class SyncWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        return Result.success()
    }
}

private fun enqueueSync(context: Context) {
    val request = OneTimeWorkRequestBuilder<SyncWorker>().build()
    WorkManager.getInstance(context).enqueue(request)
}

@Composable
fun AdvancedWorkManagerSample() {
    val context = LocalContext.current
    Text(
        text = "进阶4：WorkManager（点击创建一次后台任务）",
        modifier = Modifier
            .fillMaxWidth()
            .clickable { enqueueSync(context) }
            .padding(vertical = 6.dp)
    )
}

/** 屏幕状态建模为一个密封类：任一时刻只可能是三态之一，编译器保证分支穷尽 */
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}

/** 假数据源：delay 模拟网络延迟，随机失败演示 Error 态（教学工程不引入真实网络） */
class FakeNoteRepository {
    suspend fun loadNotes(): List<String> {
        delay(1500)
        if (Random.nextInt(10) < 3) error("模拟网络失败")
        return listOf("便签 A", "便签 B", "便签 C")
    }
}

class NoteListViewModel(
    private val repository: FakeNoteRepository = FakeNoteRepository()
) : ViewModel() {
    private val _state = MutableStateFlow<UiState<List<String>>>(UiState.Loading)
    val state: StateFlow<UiState<List<String>>> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = UiState.Loading
            runCatching { repository.loadNotes() }
                .onSuccess { notes -> _state.value = UiState.Success(notes) }
                .onFailure { e -> _state.value = UiState.Error(e.message ?: "未知错误") }
        }
    }
}

@Composable
fun AdvancedUiStateSample(vm: NoteListViewModel = viewModel()) {
    val state by vm.state.collectAsStateWithLifecycle()
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Text("进阶5：UiState 三态渲染", fontWeight = FontWeight.Bold)
        when (val s = state) {
            is UiState.Loading -> Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(top = 4.dp)
            ) {
                CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                Text("  加载中…", modifier = Modifier.padding(start = 8.dp))
            }
            is UiState.Success -> Column(modifier = Modifier.padding(top = 4.dp)) {
                s.data.forEach { note -> Text("· $note") }
            }
            is UiState.Error -> Column(modifier = Modifier.padding(top = 4.dp)) {
                Text("加载失败：${s.message}", color = Color(0xFFC62828))
                OutlinedButton(onClick = { vm.load() }, modifier = Modifier.padding(top = 4.dp)) {
                    Text("重试")
                }
            }
        }
    }
}

