# 16 · 实战项目：MemoPad 便签应用

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/MemoPadSample.kt`

## 1. 项目目标

前 14 章学的东西散落在 21 个 Kotlin 示例和 10 个 Compose 示例里，本章把它们组装成一个能装进手机的真实应用：**MemoPad 便签**。功能清单：

| 功能 | 用到的知识 | 来自哪章 |
|---|---|---|
| 便签列表（按修改时间倒序） | `LazyColumn` + `items(key=)` | 第 12 章 |
| 新建 / 编辑便签 | `Navigation Compose` 路由与参数 | 第 14 章 |
| 删除便签 | `StateFlow` 状态更新 | 第 14 章 |
| 退出重开数据还在 | JSON 文件持久化到 `filesDir` | 第 09 章 |
| 后台备份 | `WorkManager` + `CoroutineWorker` | 第 14 章 |
| 状态在屏幕旋转后不丢 | `ViewModel` + `AndroidViewModel` | 第 14 章、第 04 章 |

整个项目是**一个约 330 行的 Kotlin 文件**，零新增依赖——用的全是 `compose_examples` 工程里已经有的库（Compose、Navigation、Lifecycle、WorkManager）加 SDK 自带的 `org.json`。这是刻意的：实战项目的意义在于架构组装，而不是堆依赖。

## 2. 架构：单向数据流的三层

```text
┌─────────────────────────────────────────────┐
│  UI 层（Compose）                            │
│  MemoListScreen / MemoEditScreen            │
│  只读状态、只发事件                           │
└──────────────┬──────────────▲───────────────┘
        事件（save/delete/导航） │ 状态（StateFlow<List<Memo>>）
┌──────────────▼──────────────┴───────────────┐
│  状态层（ViewModel）                          │
│  MemoPadViewModel : AndroidViewModel         │
└──────────────┬──────────────▲───────────────┘
               │ 读写           │ 内存态
┌──────────────▼──────────────┴───────────────┐
│  数据层（Repository 内嵌）                     │
│  memos.json ← org.json ← filesDir           │
└─────────────────────────────────────────────┘
```

三条纪律，对应第 14 章讲过的单向数据流（UDF）：

1. **Composable 不持有业务状态**：列表数据从 `vm.memos` 订阅，编辑框的临时输入才用 `remember`
2. **Composable 不做 IO**：所有文件读写都发生在 ViewModel 的 `Dispatchers.IO` 里
3. **数据层只认 Kotlin 对象**：`Memo` data class 是唯一事实，JSON 只是它的序列化格式

## 3. 数据层：Memo 与 JSON 持久化

数据模型一行定义：

```kotlin
data class Memo(
    val id: Long,
    val title: String,
    val body: String,
    val updatedAt: Long
)
```

`id` 直接用 `System.currentTimeMillis()` 生成——新建那一刻的时间戳天然唯一（除非同一毫秒建两条，教学场景可以接受）。`updatedAt` 同时充当排序键。

读写走 `filesDir/memos.json`，格式就是第 09 章内部存储 + 第 08 章 JSON 解析的组合：

```kotlin
private suspend fun readMemos(): List<Memo> = withContext(Dispatchers.IO) {
    if (!memoFile.exists()) return@withContext emptyList()
    runCatching {
        val array = JSONArray(memoFile.readText())
        buildList {
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                add(Memo(obj.getLong("id"), obj.getString("title"),
                    obj.getString("body"), obj.getLong("updatedAt")))
            }
        }
    }.getOrDefault(emptyList())
}
```

三个细节值得停一下：

- **`runCatching { }.getOrDefault(emptyList())`**：JSON 是外部格式，文件损坏（用户手改、磁盘半写）不该让应用崩溃，降级成空列表是正确姿势
- **`withContext(Dispatchers.IO)`**：文件读写离开主线程，第 08 章的铁律
- **首次启动文件不存在**：返回空列表而不是抛异常，空状态由 UI 层展示

写回是全量覆盖（整个列表重新序列化）。便签场景几十条数据，全量写完全够用；换成上万条就该换 SQLite/Room 的增量更新了——选型逻辑见第 09 章的存储对比表。

**为什么不用 Room？** 第 14 章说过：本工程没有配置 KSP 和 `room-compiler`，Room 只能定义三件套不能实例化。教学工程保持"零注解处理器"有很多好处（构建快、依赖少、代码全可读），JSON 文件方案让持久层只有 40 行可审查的代码。升级路径在最后一节。

## 4. 状态层：MemoPadViewModel

```kotlin
class MemoPadViewModel(app: Application) : AndroidViewModel(app) {

    private val memoFile = File(app.filesDir, "memos.json")

    private val _memos = MutableStateFlow<List<Memo>>(emptyList())
    val memos: StateFlow<List<Memo>> = _memos

    init {
        viewModelScope.launch { _memos.value = readMemos() }
    }
    ...
}
```

要点逐条对应前面章节：

- **`AndroidViewModel` 而不是 `ViewModel`**：需要 `Application` 才能拿到 `filesDir`（Application 是全应用单例，不会泄漏）
- **`_memos` 私有可变 / `memos` 公开只读**：UI 层只能订阅不能改，状态的唯一入口是 `save()`/`delete()` 这两个意图函数——单向数据流的字面实现
- **`viewModelScope`**：协程作用域跟随 ViewModel 生命周期，ViewModel 清理时自动取消，不会泄漏（第 08 章、第 14 章）
- **`init` 里异步加载**：构造函数不能挂起，磁盘读取放 `launch`，加载完成前 UI 显示空列表

保存逻辑是"更新内存态 → 落盘"两步：

```kotlin
fun save(title: String, body: String, editing: Memo?) {
    viewModelScope.launch {
        val next = if (editing != null) {
            editing.copy(title = title, body = body, updatedAt = System.currentTimeMillis())
        } else {
            Memo(System.currentTimeMillis(), title, body, System.currentTimeMillis())
        }
        _memos.update { list ->
            (list.filterNot { it.id == next.id } + next).sortedByDescending { it.updatedAt }
        }
        writeMemos(_memos.value)
    }
}
```

`editing != null` 区分新建与编辑：编辑用 `copy()` 保住原 `id`（否则会变成两条），新建用时间戳当新 `id`。`filterNot + sortedByDescending` 一行完成"去旧插新并重排"。

## 5. 导航层：两个路由一个哨兵

```kotlin
NavHost(navController = nav, startDestination = "list") {
    composable("list") { MemoListScreen(vm = vm, onNew = ..., onOpen = ..., onBackup = ...) }
    composable(
        route = "edit/{id}",
        arguments = listOf(navArgument("id") { type = NavType.StringType })
    ) { entry ->
        val id = entry.arguments?.getString("id").orEmpty()
        MemoEditScreen(vm = vm,
            editing = vm.memos.value.firstOrNull { it.id.toString() == id },
            onDone = { nav.popBackStack() })
    }
}
```

两个设计决定：

**`vm` 创建在 `NavHost` 外面**。`viewModel()` 的默认作用域是当前的 `ViewModelStoreOwner`——放在 `composable("edit/{id}")` 里，每个路由会得到**各自独立的** ViewModel 实例，列表屏和编辑屏就看不到同一份数据了。提升到 `MemoPadSample()` 顶层（owner 是 Activity），两个屏共享一个实例。这是 Navigation Compose 最容易踩的结构坑。

**`edit/new` 哨兵值**。编辑路由需要知道"编辑谁"，新建时还没有 id，就用字符串 `new` 占位；`firstOrNull { it.id.toString() == id }` 匹配不到任何便签时 `editing` 为 null，编辑屏据此显示"新建便签"标题并隐藏删除按钮。比定义两个路由省一半样板。

返回用 `popBackStack()`：保存/删除完成后退回列表，列表订阅着 StateFlow，自动刷新——**不需要手动"刷新列表"这个动作**，这就是响应式的收益。

## 6. 界面层：列表屏与编辑屏

列表屏的骨架是 `Scaffold` + `LazyColumn`：

```kotlin
val memos by vm.memos.collectAsStateWithLifecycle()
Scaffold(floatingActionButton = {
    FloatingActionButton(onClick = onNew) { Text("＋") }
}) { innerPadding ->
    if (memos.isEmpty()) {
        /* 空状态：居中提示 + 备份按钮 */
    } else {
        LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = innerPadding) {
            items(memos, key = { it.id }) { memo -> MemoCard(memo, onOpen) }
            item { /* 底部：WorkManager 备份按钮 */ }
        }
    }
}
```

- `collectAsStateWithLifecycle()`：让订阅跟随生命周期，退到后台就停止收集（第 14 章）
- `items(memos, key = { it.id })`：给 item 一个稳定 key，删除中间一条时 Compose 能复用其余节点而不是全部重建——和第 07 章 ViewHolder 复用是同一个问题意识，只是这里一行参数搞定
- `contentPadding = innerPadding`：吃掉 Scaffold 留白，列表滚到底也不会被 FAB 挡住

每张卡片是 `Card + clickable`，展示标题、两行预览（`maxLines = 2`）、相对时间。

编辑屏两个 `OutlinedTextField` 绑定本地状态：

```kotlin
var title by remember(editing) { mutableStateOf(editing?.title.orEmpty()) }
```

`remember` 的参数键是 `editing` 本身：同一屏内旋转重组不丢输入（`remember` 保住），而换了一篇便签进来（`editing` 对象变了）则重新初始化——这是 `remember(key)` 的标准用法，第 12 章"状态记忆"的实战版。

## 7. WorkManager 后台备份

```kotlin
class MemoBackupWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val source = File(applicationContext.filesDir, "memos.json")
        if (source.exists()) {
            source.copyTo(File(applicationContext.filesDir, "memos.backup.json"), overwrite = true)
        }
        Result.success()
    }
}
```

把 `memos.json` 复制成 `memos.backup.json`——真实但极小。它的教学价值在调用侧：

```kotlin
WorkManager.getInstance(context)
    .enqueue(OneTimeWorkRequestBuilder<MemoBackupWorker>().build())
```

点击"备份"按钮，工作被交给系统调度：即使进程被杀，约束满足后任务仍会补执行——这是第 10 章 Service 做不到的**保证执行**语义（第 14 章选型表）。把 `OneTimeWorkRequestBuilder` 换成 `PeriodicWorkRequestBuilder<MemoBackupWorker>(6, TimeUnit.HOURS)` 就是每六小时自动备份，其余代码一行不改。

## 8. 把它跑起来

`MemoPadSample()` 是一个自包含的 Composable，挂载只要在 `MainActivity.kt` 的 `setContent` 里加一行：

```kotlin
setContent {
    Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
        MemoPadSample()   // 替换或并列于现有示例
    }
}
```

本工程默认**没有**把它挂进 `MainActivity`——展示工程以"全部示例可编译"为目标，`MainActivity` 是十个示例的陈列架。运行完整应用需要 Android 设备或模拟器（`adb install` APK），这超出了本仓库"静态编译验证"的边界；但代码本身参与了 `gradle :app:compileDebugKotlin`，语法与 API 用法和其余示例一样经过验证：

```powershell
cd G:\code\guide\android
pwsh -File .\build.ps1 -Compose
```

## 9. 常见坑

**`vm.memos.value` 直读 vs `collectAsStateWithLifecycle`**。编辑路由里取 `editing` 用了 `.value` 直读（拿参数那一刻的快照），列表屏则正确订阅了状态流。直读的代价：值变化不触发重组——如果磁盘加载还没完成就点进编辑，可能拿到 null。生产代码应把 `memos` 状态一路传下去或让编辑屏自己也订阅。

**`remember` 忘了带 key**。编辑屏若写 `remember { mutableStateOf(...) }`（无参），从便签 A 返回再进便签 B 时，B 的输入框里还留着 A 的内容——复用了过期的记忆。

**`SimpleDateFormat` 非线程安全**。本例里它只在主线程做格式化，安全；一旦挪进 IO 线程批量格式化就要换 `java.time.format.DateTimeFormatter`（API 26+，或 desugaring）。

**内存态与磁盘态不同步**。`save()` 先改 `_memos` 再 `writeMemos`，两步之间进程被杀会丢这次修改但界面已经显示成功。教学上可接受；严格做法是先写盘、成功后再更新内存态，或引入事务化 Repository。

**id 用时间戳**。同一毫秒创建两条便签会撞 id（`items(key=)` 直接崩溃）。改用自增计数器存进 SharedPreferences，或换 `UUID.randomUUID()`（String id）。

## 10. 实战建议

- **先跑通再升级**：这个项目的每一层都能单独替换——把 `readMemos/writeMemos` 换成 Room DAO（第 14 章三件套 + KSP 接入步骤），UI 与 ViewModel 一行不改，这就是分层的回报
- **Repository 抽接口**：`MemoPadViewModel` 直接持有文件读写，下一步是把数据层抽成 `MemoRepository` 接口 + JSON 实现，测试时注入内存实现（第 14 章依赖注入的思想）
- **值得做的练习**：标题搜索框（`derivedStateOf` 过滤列表）、滑动删除（`SwipeToDismissBox`）、便签置顶（`sortByDescending` 加权重）、深色主题跟随系统（`isSystemInDarkTheme()`）
- **发布前清单**：`minSdk 24` 覆盖 98%+ 设备可保持；图标与 `label` 在 manifest 里替换；备份规则 `android:allowBackup`；若上架 Play，WorkManager 的周期任务最小间隔 15 分钟
- 把第 09 章的 SharedPreferences（记住"上次打开的便签"）、第 10 章的通知（定时提醒）逐个加进来，每加一个功能回读对应章节——这本教程的闭环就完成了

---
上一章：[15 JNI 与 NDK](15-jni-ndk.md) ｜ 本教程完，回到[目录](../README.md)
