package guide.android.compose.samples

import android.app.Application
import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.work.CoroutineWorker
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class Memo(
    val id: Long,
    val title: String,
    val body: String,
    val updatedAt: Long
)

class MemoPadViewModel(app: Application) : AndroidViewModel(app) {

    private val memoFile = File(app.filesDir, "memos.json")
    private val timeFormat = SimpleDateFormat("MM-dd HH:mm", Locale.getDefault())

    private val _memos = MutableStateFlow<List<Memo>>(emptyList())
    val memos: StateFlow<List<Memo>> = _memos

    init {
        viewModelScope.launch { _memos.value = readMemos() }
    }

    fun formatTime(memo: Memo): String = timeFormat.format(Date(memo.updatedAt))

    fun save(title: String, body: String, editing: Memo?) {
        viewModelScope.launch {
            val next = if (editing != null) {
                editing.copy(title = title, body = body, updatedAt = System.currentTimeMillis())
            } else {
                Memo(
                    id = System.currentTimeMillis(),
                    title = title,
                    body = body,
                    updatedAt = System.currentTimeMillis()
                )
            }
            _memos.update { list ->
                (list.filterNot { it.id == next.id } + next).sortedByDescending { it.updatedAt }
            }
            writeMemos(_memos.value)
        }
    }

    fun delete(id: Long) {
        viewModelScope.launch {
            _memos.update { list -> list.filterNot { it.id == id } }
            writeMemos(_memos.value)
        }
    }

    private suspend fun readMemos(): List<Memo> = withContext(Dispatchers.IO) {
        if (!memoFile.exists()) return@withContext emptyList()
        runCatching {
            val array = JSONArray(memoFile.readText())
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        Memo(
                            id = obj.getLong("id"),
                            title = obj.getString("title"),
                            body = obj.getString("body"),
                            updatedAt = obj.getLong("updatedAt")
                        )
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private suspend fun writeMemos(list: List<Memo>) {
        withContext(Dispatchers.IO) {
            val array = JSONArray()
            list.forEach { memo ->
                array.put(
                    JSONObject()
                        .put("id", memo.id)
                        .put("title", memo.title)
                        .put("body", memo.body)
                        .put("updatedAt", memo.updatedAt)
                )
            }
            memoFile.writeText(array.toString())
        }
    }
}

class MemoBackupWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val source = File(applicationContext.filesDir, "memos.json")
        if (source.exists()) {
            source.copyTo(File(applicationContext.filesDir, "memos.backup.json"), overwrite = true)
        }
        Result.success()
    }
}

@Composable
fun MemoPadSample() {
    val context = LocalContext.current
    val app = context.applicationContext as Application
    val vm: MemoPadViewModel = viewModel(initializer = { MemoPadViewModel(app) })
    val nav = rememberNavController()

    NavHost(navController = nav, startDestination = "list") {
        composable("list") {
            MemoListScreen(
                vm = vm,
                onNew = { nav.navigate("edit/new") },
                onOpen = { id -> nav.navigate("edit/$id") },
                onBackup = {
                    WorkManager.getInstance(context)
                        .enqueue(OneTimeWorkRequestBuilder<MemoBackupWorker>().build())
                }
            )
        }
        composable(
            route = "edit/{id}",
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            MemoEditScreen(
                vm = vm,
                editing = vm.memos.value.firstOrNull { it.id.toString() == id },
                onDone = { nav.popBackStack() }
            )
        }
    }
}

@Composable
private fun MemoListScreen(
    vm: MemoPadViewModel,
    onNew: () -> Unit,
    onOpen: (Long) -> Unit,
    onBackup: () -> Unit
) {
    val memos by vm.memos.collectAsStateWithLifecycle()
    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onNew) { Text("＋") }
        }
    ) { innerPadding ->
        if (memos.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text("暂无便签，点右下角＋新建")
                Spacer(Modifier.height(8.dp))
                Button(onClick = onBackup) { Text("WorkManager 备份") }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = innerPadding
            ) {
                items(memos, key = { it.id }) { memo ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpen(memo.id) }
                            .padding(horizontal = 16.dp, vertical = 6.dp)
                    ) {
                        Column(Modifier.padding(12.dp)) {
                            Text(
                                text = memo.title.ifBlank { "(无标题)" },
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = memo.body,
                                style = MaterialTheme.typography.bodySmall,
                                maxLines = 2
                            )
                            Text(
                                text = vm.formatTime(memo),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Button(onClick = onBackup) { Text("WorkManager 备份") }
                    }
                }
            }
        }
    }
}

@Composable
private fun MemoEditScreen(
    vm: MemoPadViewModel,
    editing: Memo?,
    onDone: () -> Unit
) {
    var title by remember(editing) { mutableStateOf(editing?.title.orEmpty()) }
    var body by remember(editing) { mutableStateOf(editing?.body.orEmpty()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = if (editing != null) "编辑便签" else "新建便签",
            style = MaterialTheme.typography.titleLarge
        )
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("标题") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = body,
            onValueChange = { body = it },
            label = { Text("内容") },
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
        )
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Button(onClick = {
                vm.save(title, body, editing)
                onDone()
            }) { Text("保存") }
            if (editing != null) {
                Button(onClick = {
                    vm.delete(editing.id)
                    onDone()
                }) { Text("删除") }
            }
        }
    }
}
