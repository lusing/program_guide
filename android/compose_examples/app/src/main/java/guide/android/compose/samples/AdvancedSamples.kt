package guide.android.compose.samples

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update

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

