# 14 · Compose 工程化架构

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/AdvancedSamples.kt`

## 1. 为什么需要架构：重组救不了旋转

第 12 章的 `ComposeCounterSample` 有个没展开的事实：旋转屏幕后，计数归零。这不是 bug，是 `remember` 的设计边界。[第 04 章](04-activity-lifecycle.md)讲过，配置变更（旋转、深色模式、语言、分屏尺寸）会销毁重建 Activity；Activity 没了，挂在它身上的组合（composition）也没了，`remember` 存的值随之蒸发。

旋转一下，裸 `remember` 的工程会同时暴露三个问题：

- 计数、表单进度等界面状态丢失
- 刚请求回来的数据丢失（或更糟：重建后又发一次请求）
- 异步任务与界面失去关联，结果无处投递

**ViewModel 的存在意义就一条：生命周期长于配置变更。** Activity 重建时，框架把 ViewModel 留在 ViewModelStore 里，新 Activity 拿到的是同一个实例，状态与任务原地不动。

| | `remember` | `rememberSaveable` | `ViewModel` |
|---|---|---|---|
| 活过重组 | 是 | 是 | 是 |
| 活过配置变更 | 否 | 是（序列化进 Bundle） | 是（实例保留） |
| 活过进程被杀 | 否 | 是 | 否（要 SavedStateHandle 补） |
| 适合放什么 | 单组件的界面小状态 | 小量可打包值 | 屏幕状态 + 业务逻辑 |
| 能否放协程、大对象 | 能但会丢 | 不能（Bundle 限制） | 能 |

一句话分工：`remember` 管"这一帧到下一帧"，`ViewModel` 管"这次进入屏幕到离开屏幕"。

## 2. ViewModel + StateFlow：单向数据流

`AdvancedSamples.kt` 的第一个示例（配套依赖 `androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7`）：

```kotlin
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
```

逐个拆解：

- **`CounterViewModel : ViewModel()`**：无参构造，`viewModel()` 首次调用时创建并登记到最近的 ViewModelStoreOwner（这里是 Activity）；之后任何时刻再调——包括旋转重建后——返回的都是同一个实例
- **私有 `MutableStateFlow` + 公开 `StateFlow`**：写权限收口在 ViewModel 内部，UI 只能读。这是单向数据流的物理基础
- **`_count.update { it + 1 }`**：基于 CAS 的原子自增，并发安全，比 `_count.value++` 可靠
- **`collectAsStateWithLifecycle()`**：把 `StateFlow` 转成 Compose 状态，且生命周期感知——界面 STOPPED 时停止收集、回来续上（普通 `collectAsState()` 不感知生命周期，后台也在收）
- **UI 端只做两件事**：显示 `count`，点击时调 `vm.increment()`，一行业务都没有

收集方式二选一（`collectAsStateWithLifecycle` 由 lifecycle 2.8.7 系列提供，随 `lifecycle-viewmodel-compose` 进入依赖）：

| | `collectAsState()` | `collectAsStateWithLifecycle()` |
|---|---|---|
| 生命周期感知 | 否 | 是（STOPPED 暂停，STARTED 恢复） |
| 后台耗流 | 界面不可见也在收 | 不可见时不收 |
| 定位 | 早期 API | 新代码默认选它 |

这就是单向数据流（unidirectional data flow，UDF）：

```text
          事件向上（vm.increment()）
Composable ─────────────────────────────▶ ViewModel
Composable ◀───────────────────────────── ViewModel
          状态向下（count 经 collectAsStateWithLifecycle）
```

三条纪律：状态向下、事件向上、ViewModel 不知道 UI 存在。最后一条是白送的：`CounterViewModel` 不依赖任何 Compose 类型，可以直接写 JVM 单元测试。

ViewModel 同时是挂起工作的自然宿主：`viewModel.viewModelScope` 里的协程（[第 08 章](08-threads-network.md)）活到 ViewModel 被清除为止，旋转打断不了它——这正是第 1 节"异步结果无处投递"的解法。本示例的 `increment()` 是纯同步看不到 scope；真实项目里 `viewModelScope.launch { ... }` 包住请求、结果写回状态流——结果具体怎么建模，正是下一节的主题。

## 3. UiState：把屏幕状态建模成一个密封类

第 2 节的状态是单个 `Int`，这掩盖了真实屏幕的复杂性：数据可能还在加载、可能加载成功、可能加载失败。直觉写法是三个布尔（`isLoading` / `isError` / ...），但布尔们可以**同时为真**——"加载中且已失败"这种不可能状态在类型上没有被排除，只能靠码品自律，迟早失守。Kotlin 的密封类型（[第 03 章](03-kotlin-for-android.md)）给出根治方案：屏幕任一时刻只处于**一种**状态，那就把它建成一个类型。

`AdvancedSamples.kt` 的三段式（进阶5）。先建模状态：

```kotlin
/** 屏幕状态建模为一个密封类：任一时刻只可能是三态之一，编译器保证分支穷尽 */
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

- **互斥由类型保证**：`state` 是 `UiState` 就不可能"既 Loading 又 Success"——不可能状态不是被禁止了，是被**表达不出来**了
- **`<out T>` 泛型**：`UiState<List<Note>>`、`UiState<User>` 随便复用；`Loading`/`Error` 没有 T 也装得进任何 `UiState<T>`（协变，细节[第 03 章](03-kotlin-for-android.md)）
- **`data object` / `data class`**：无参状态用 `object` 全局一份，带数据的状态是值对象，`==` 比较内容

数据源与 ViewModel：

```kotlin
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
```

三件事：

- **Repository 经构造函数注入**（带默认值便于直接用）：ViewModel 不自己造数据源——测试时塞一个"立即成功/立即失败"的假实现，三态渲染逻辑不碰网络就能验证。这是分层的第一块砖，[第 16 章](16-memopad.md)的 MemoPad 会再遇到它
- **`runCatching { }`**：把异常收进 `Result`，`onSuccess`/`onFailure` 各写各的，比 try/catch 少一层缩进；失败映射成 `Error(message)` 而不是让协程崩掉
- **每次 `load()` 先回 `Loading`**：重试时 UI 自动回到转圈分支，不需要单独的 `isRefreshing` 布尔

UI 侧的渲染就是穷尽分支（示例里三个分支分别是转圈、列表、错误 + 重试按钮）：

```kotlin
when (val s = state) {
    is UiState.Loading -> { /* CircularProgressIndicator + "加载中…" */ }
    is UiState.Success -> { /* s.data.forEach { Text("· $it") } */ }
    is UiState.Error -> { /* Text(s.message, color = 红) + OutlinedButton("重试") { vm.load() } */ }
}
```

`when` 摆在 `state` 的收口处，密封类的威力在编译期兑现：**漏写任何一个分支，编译直接报错**；将来加第四态（比如"空数据 `Empty`"），所有渲染点被编译器逐个揪出来补分支。对比布尔组合方案——漏判一个 `if (isError)` 只会在测试甚至线上暴露。这是"派生值现算"（第 12 章第 5 节）在屏幕维度的对应物：状态不是散落的标志位，是一台状态机。

诚实标注边界：不是每块界面都值得上密封类——数据**必然**可得的本地状态（如 MemoPad 的便签列表）用 `StateFlow<List<Memo>>` 就够（[第 16 章](16-memopad.md)即如此）；UiState 的用武之地是"异步加载、可能失败"的屏幕，也就是绝大多数联网页面。

## 4. Navigation Compose：应用内路由

`AdvancedNavigationSample`（依赖 `androidx.navigation:navigation-compose:2.8.5`）：

```kotlin
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
```

- **`rememberNavController()`**：路由栈的控制器，唯一有状态的东西
- **`NavHost` + `composable(route)`**：声明路由表。`startDestination = "home"` 指定起点；每个 `composable("...")` 的 lambda 就是该页面
- **导航参数**：路由模板 `"detail/{id}"`，`navArgument("id") { type = NavType.StringType }` 声明类型，页面里 `entry.arguments?.getString("id")` 取值
- **跳转即压栈**：`navController.navigate("detail/42")` 把 `"detail/42"` 压入内部栈；`navController.popBackStack()` 弹栈返回，系统返回键默认走同一条路。快速连点会压入两个相同页面——底部导航这类"切标签"场景给 `navigate` 加 `navOptions { launchSingleTop = true }` 复用栈顶，避免重复页

与[第 06 章](06-intents-navigation.md) Intent 的对照——两者是互补，不是替代：

| | Intent | Navigation Compose |
|---|---|---|
| 定位 | 组件间/应用间消息 | 应用内页面路由 |
| 目标 | Activity（显式/隐式） | 路由字符串 |
| 返回栈 | 系统 Task 栈 | NavHost 内部栈 |
| 传参 | extras Bundle | 路由参数 + `navArgument` 类型 |
| 典型场景 | 跳别的应用、系统页面 | 单 Activity 内多页面 |

新工程的主流形态是单 Activity + NavHost 承载全部页面；一旦要跨出应用边界（打开浏览器、分享、拨号），仍然回到 Intent。

## 5. Room：三件套与本工程的真实状态

`AdvancedSamples.kt` 定义了 Room 的标准三件套（依赖 `androidx.room:room-runtime` / `room-ktx` 2.6.1）：

```kotlin
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
```

| 注解 | 角色 | 说明 |
|---|---|---|
| `@Entity` | 表 | data class 映射成 SQLite 表，`@PrimaryKey` 主键 |
| `@Dao` | 访问层 | SQL 写在注解里；挂起函数自动切到 IO 线程 |
| `@Database` | 数据库入口 | 声明版本与全部 Entity，暴露 DAO |

注意 `observeAll()` 的返回值是 `Flow<List<NoteEntity>>` 而不是 `List`：**响应式查询**——notes 表任何变更都会重新发射最新列表，UI 层接上第 2 节的 `collectAsStateWithLifecycle` 就自动刷新，"查一次、手动刷"的老路不需要走了。

必须如实说明：**本工程没有接入 KSP/kapt，也没有 `room-compiler`**。三件套目前只是普通注解 + 接口，编译通过，但 Room 的实现类（`GuideRoomDatabase_Impl` 等）不会被生成——一旦在运行期调用 `Room.databaseBuilder(...)` 会直接崩溃。要让 Room 真正跑起来：

```kotlin
// 根 build.gradle.kts 的 plugins 声明版本：
plugins {
    id("com.google.devtools.ksp") version "2.0.21-1.0.28" apply false
}

// app/build.gradle.kts：
plugins {
    id("com.google.devtools.ksp")          // 与 Kotlin 插件并列
}
dependencies {
    ksp("androidx.room:room-compiler:2.6.1")
}
```

版本对齐是硬约束：KSP 版本前缀必须等于工程 Kotlin 版本（`2.0.21-1.0.28` ↔ Kotlin `2.0.21`），错位直接编译失败。接好之后的使用形态（示意，单例 Database + DAO 流入 ViewModel）：

```kotlin
val db = Room.databaseBuilder(context, GuideRoomDatabase::class.java, "guide.db").build()
db.noteDao().observeAll()      // Flow<List<NoteEntity>>，接第 2 节的收集链
```

[第 16 章](16-memopad.md)实战项目选择用 JSON 文件做持久层，就是为了绕开这个额外依赖——架构思想（DAO 接口 + 响应式流）不变，落地物换成文件读写。

## 6. WorkManager：可保证执行的后台任务

`AdvancedSamples.kt` 的最后一块（依赖 `androidx.work:work-runtime-ktx:2.10.0`）：

```kotlin
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
```

- **`CoroutineWorker`**：任务体就是一个 `suspend fun doWork()`——协程（[第 08 章](08-threads-network.md)）直接在后台任务里用；返回 `Result.success()` / `failure()` / `retry()`
- **`OneTimeWorkRequestBuilder<SyncWorker>().build()`**：构造一次性任务请求（周期任务是 `PeriodicWorkRequestBuilder`），可以附加约束（充电、联网）、退避策略
- **`WorkManager.getInstance(context).enqueue(request)`**：交给系统调度，方法立即返回
- **`LocalContext.current`**：Compose 提供的当前 Android Context，拿它去调框架 API 是标准姿势

WorkManager 的卖点是**保证执行**：任务入库后，进程被杀、甚至设备重启，系统都会找机会续跑。选型表（连接[第 10 章](10-system-components.md)）：

| | WorkManager | 前台 Service | 协程作用域 |
|---|---|---|---|
| 保证执行 | 是（可延迟，重启续跑） | 运行期间是 | 否 |
| 系统调度 | 是（约束/退避/去重） | 手动管理 | 手动 |
| 用户可感知 | 否 | 是（常驻通知） | 否 |
| 适用 | 可推迟的后台工作：同步、上传、清理 | 播放、导航等前台长任务 | 页面内异步加载 |

## 7. 常见坑

**在 Composable 里 new ViewModel**：`val vm = CounterViewModel()`——编译通过，但每次重组都可能造出新实例，状态随机归零，"活过旋转"更无从谈起。必须用 `viewModel()` 获取（工程大了再换 hiltViewModel 等注入方案）。

**StateFlow 不 collectAsState 直接读 `.value`**：`Text("${vm.count.value}")` 能编译、能显示初值，然后永远不动——`.value` 是一次性读取，不构成订阅。要 UI 跟着变，必须 `collectAsStateWithLifecycle()`（至少 `collectAsState()`）拿到 Compose 状态再读。

**把一次性事件塞进 UiState**：想弹个"已保存"提示，给密封类加个 `ShowToast(message)` 分支——事件是会"过期"的（弹过就该消失），状态是"持续成立"的；混在一起会出现"旋转后旧提示又弹一遍"。一次性事件走 `Channel`（VM 端 `send`，UI 端 `receiveAsFlow().collect` 消费后即失）或 Snackbar 的排队语义（[第 13 章](13-compose-ui.md)第 2 节），别让它进状态机。

**WorkManager 当 Service 用**：拿 WorkManager 跑音乐播放、实时定位——它是"可延迟的保证执行"，任务可能被系统推迟十几分钟，进程也会被回收重启。用户可感知的常驻任务走[第 10 章](10-system-components.md)的前台 Service；页面内异步用协程；WorkManager 只管"迟早要做、中断会续"的那类。

## 8. 实战建议

- 每屏一个 ViewModel；状态用 `StateFlow` 暴露（私有 `MutableStateFlow` 写），事件方法语义化——`increment()` 而不是 `setCount(n)`
- 异步屏幕状态用 `UiState` 密封类建模（第 3 节），本地必然可得的数据用裸 `StateFlow<List<T>>` 就够——按需上强度
- Room 数据库全局一份（单例），DAO 经构造函数进 ViewModel，不要在 Composable 里建库
- 路由字符串提常量或扩展属性，`"detail/{id}"` 这类模板散落各处必然拼写漂移
- Room 三件套随时可写，但要跑起来先接 KSP（第 5 节步骤）；不想接就学第 16 章用文件持久层
- 架构不是层数越多越好：单屏小工具一个 ViewModel 足够，别提前引入 Repository/UseCase 层
- 改完跑 `.\build.ps1 -Compose` 验证编译；[第 16 章](16-memopad.md)会把本章的 ViewModel + StateFlow + Navigation 全部串成完整应用

---
上一章：[13 Compose 组件与交互](13-compose-ui.md) ｜ 下一章：[15 JNI 与 NDK](15-jni-ndk.md) ｜ 返回：[README](../README.md)
