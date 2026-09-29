# 19 · Compose 依赖注入与生态

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/EcosystemSamples.kt`

第 14 章的 `viewModel()` 有个没展开的问题：带构造参数的 ViewModel（Repository 进构造函数）怎么创建？答案是依赖注入（Dependency Injection，DI）。本章先用手写方式把 DI 的本质讲透（`EcoManualDiSample`），再看工业标准 Hilt 为什么长那样、接入它要付出什么；最后盘一遍 Compose 周边生态——书里的 Accompanist 一章已成"历史课"，官方库已收编其大半，这一章按 2026 年的现状重新校准。

## 1. 依赖注入：问题与最小解

回看第 14 章的 `NoteListViewModel(repository = FakeNoteRepository())`——带默认值的构造参数其实就是最朴素的注入：**依赖从外面递进来，组件不自己造**。它解决三件事：

- **可替换**：换数据源（内存 → Room → 网络）不改 UI 代码
- **可测试**：塞一个"立即成功/立即失败"的假实现，逻辑测试不碰真 IO
- **单一装配点**：谁依赖谁，一眼看尽，不散落在各处 `new`

规模一大，问题随之而来：几十个 ViewModel 各自 new 各自的 Repository，同一个数据源被建了 N 份。于是需要**容器**：全局一处装配、处处拿同一份。`EcoManualDiSample`（生态1）是手写容器的完整最小解：

```kotlin
interface NoteRepository { fun loadNotes(): List<String> }        // ① 依赖倒置：UI 面向接口
class InMemoryNoteRepository : NoteRepository { ... }             //    实现 A
class BackupNoteRepository : NoteRepository { ... }               //    实现 B（演示换源）

class AppContainer(val noteRepository: NoteRepository = InMemoryNoteRepository())  // ② 容器集中装配

val LocalAppContainer = compositionLocalOf { AppContainer() }     // ③ CompositionLocal 递进组合树

CompositionLocalProvider(LocalAppContainer provides container) {
    val repo = LocalAppContainer.current.noteRepository           // ④ 消费方只取接口
    repo.loadNotes().forEach { Text("· $it") }                    //    换实现，这几行不改
}
```

四个角色各司其职：**接口**隔离变化、**容器**集中装配（真实工程在 `Application` 子类里建全局一份）、**CompositionLocal** 免逐层透传（第 13 章主题一节讲过的"隐式环境参数"，DI 是它最重的用例）、**消费方**只面向接口。点击示例里的"切换到备份数据源"，UI 代码一行没动、数据全换——这就是注入的全部价值。

手写的极限也一目了然：依赖图大了以后，"谁初始化谁、单例还是每次新建、ViewModel 的工厂怎么接容器"全靠手排，容器自己长成一个大工厂类。这正是 DI 框架的入口。

## 2. Hilt：把装配交给编译期

Android 官方的 DI 标准是 Dagger Hilt（Dagger 的 Android 定制版）。它的思路：**用注解声明依赖关系，编译期由 KSP/kapt 生成装配代码**——你写 `@Inject constructor`，它生成工厂；你写 `@Module`，它生成容器；手写容器那个"大工厂类"不存在了。

典型形态（示意，本工程未接入）：

```kotlin
@HiltViewModel
class NoteListViewModel @Inject constructor(          // 构造参数自动注入，无需手写 Factory
    private val repository: NoteRepository
) : ViewModel() { ... }

@Module @InstallIn(SingletonComponent::class)
object DataModule {
    @Provides @Singleton                              // 接口 → 实现 的绑定也声明式
    fun provideNoteRepository(): NoteRepository = RoomNoteRepository()
}

@Composable fun NoteListScreen() {
    val vm: NoteListViewModel = hiltViewModel()       // 与第 14 章 viewModel() 同型，依赖已注入
}
```

为什么 Compose 项目格外需要它：`viewModel()` 只能创建**无参**构造的 ViewModel（第 14 章的 `CounterViewModel` 因此不敢带参数）；带参构造要手写 `ViewModelProvider.Factory`，而 Hilt 为每个 `@HiltViewModel` 自动生成工厂，`hiltViewModel()` 直接可用。配合 Navigation，每个 Destination 的 ViewModelStore 各自持有实例（页面级状态隔离），依赖照样注入。

**本工程的取舍（与第 14 章 Room/KSP 同一条纪律）**：Hilt 依赖 KSP 注解处理器，接入要动 plugins/依赖且版本与 Kotlin 严格对齐；教学主线保持零处理器，示例用手写容器如实演示同一套思想。真实工程接法：根工程加 `id("com.google.devtools.ksp") version "<kotlin版本>-<ksp版本>"`，app 模块加 `ksp("com.google.dagger:hilt-android-compiler:...")` 与 `hilt-navigation-compose` 依赖——步骤与第 14 章第 5 节的 Room/KSP 完全同构。轻量替代品 Koin（运行时 DSL 注入、无代码生成）在中小项目也常见，取舍：Hilt 编译期查错但构建重，Koin 轻但错误延迟到运行期。

## 3. 生态现状课：Accompanist 的兴衰与官方收编

《Jetpack Compose 从入门到实战》第 9 章整章讲 Accompanist（谷歌官方的"实验性补丁库"）与三方库。四年过去，**Accompanist 的大部分能力已被官方库收编或废弃**——书上的用法不能再照抄。对照表（左列书里的章节，右列 2026 年的正解）：

| 书中方案（Accompanist，2022） | 现状与官方替代 |
|---|---|
| `accompanist-pager`（HorizontalPager） | ✅ 官方化：`androidx.compose.foundation.pager.HorizontalPager/VerticalPager`（1.4+） |
| `accompanist-flowlayout`（FlowRow） | ✅ 官方化：`foundation.layout.FlowRow`（1.4+） |
| `accompanist-swiperefresh` | ✅ 替代：material3 `PullToRefresh` / `pullToRefresh` 修饰符（第 18 章手写过它的内核） |
| `accompanist-insets` + `SystemUiController` | ✅ 官方化：`WindowInsets` API + `enableEdgeToEdge()`（androidx.activity） |
| `accompanist-navigation-*` | 部分并入 `navigation-compose`；动画版转 community 维护 |

教训值得记住：**为补官方空缺而生的库，官方补上之日就是它退役之时**。选三方库时先查它是否在给官方库"打补丁"——这类库的寿命等于官方的排期。

依然坚挺的三方件：

- **Coil**（`coil-compose`）：Kotlin 协程优先的图片加载。`AsyncImage(model = url, contentDescription = ...)` 一个组件解决网络图 + 占位 + 渐入；`SubcomposeAsyncImage` 支持按加载状态自定义内容。Compose 时代的事实标准（Glide 亦有 compose 支持但更重）
- **Lottie**（`lottie-compose`）：AE 导出的 JSON 动画直读，`animateLottieCompositionAsState` 把播放进度接进 Compose 状态体系。设计师产物的标准通道
- 本工程不引入它们：示例零网络、零素材依赖（README"平台差异"一条的同一纪律）；用法示意：

```kotlin
// build.gradle.kts: implementation("io.coil-kt:coil-compose:2.7.0")
AsyncImage(
    model = "https://example.com/avatar.png",
    contentDescription = "用户头像",          // 占位/错误图经 SubcomposeAsyncImage 定制
    modifier = Modifier.size(48.dp).clip(CircleShape))
```

## 4. 版本观：这本书为什么"对但旧"

本书（2022-08 出版，Compose 1.1/1.2 时代）质量很高，但 API 演进三年，读书与读任何教程一样要带版本意识。本教程已按现状校准的几处：

| 书中写法 | 本教程（Compose 1.7.8） |
|---|---|
| `swipeable` 修饰符做吸附开关 | `anchoredDraggable`（第 18 章第 5 节） |
| `BottomNavigation`（Material2） | `NavigationBar`（Material3，第 13 章谱系） |
| `ScaffoldState`/`rememberScaffoldState` | `SnackbarHostState` 直挂 `snackbarHost`（第 13 章第 2 节） |
| Accompanist Pager/Insets | 官方 `HorizontalPager` / `WindowInsets` |
| `Modifier.animationType` 时代的过渡 API | `togetherWith` / `AnimatedContent`（第 13 章） |

方法论：任何 Compose API 先看**所属包**——`androidx.compose.*` 官方稳定、`accompanist.*` 查退役公告、三方包查维护状态；再在 Android Studio 里看**是否有删除线**（deprecated）与 **@ExperimentalXxx 标注**（要 @OptIn 的都是未稳定区）。

## 5. 常见坑

**CompositionLocal 传"会变的数据"**：把列表内容、表单状态塞进 CompositionLocal——它设计给"环境级"不变量（主题、容器、窗口尺寸），当业务总线用会让数据流不可追踪、重组失效（`compositionLocalOf` 每处读取点各自订阅，一处 provide 全树抖动）。业务数据老老实实走参数与 ViewModel。

**手写容器里存可变状态**：`AppContainer` 的字段设计成 `var` 且随处改——容器应当只是"装配结果"，运行期可变状态属于 ViewModel/数据层；否则单例容器成了全局变量集散地。

**给 @Provides 方法里 new 有状态对象**：Hilt 模块按声明提供依赖，`@Provides fun x() = StatefulThing()` 每次注入新实例、状态飘忽；有状态依赖标 `@Singleton` 并明确生命周期归属。

**按书的依赖坐标抄 Accompanist**：`com.google.accompanist:accompanist-pager:x` 抄进工程——Pager 系已停止维护，新代码直接用 foundation 的官方 Pager，别再引。

## 6. 实战建议

- 中小工程先手写 AppContainer（本章示例的完整套路），依赖图长到"容器初始化函数超过一屏"再上 Hilt——框架是规模化的产物，不是起点
- `hiltViewModel()` 与 `viewModel()` 的关系记住一句话：前者是后者加了注入的版本；第 14 章的 UDF 纪律一条不变
- 引三方库前过一遍"官方补丁测试"（第 3 节），并用 Context7/官方文档核对当前版本的推荐 API——教材与博客的时滞是常态
- 图片用 Coil、设计师动画用 Lottie、其余需求先在 `androidx.compose.*` 里找——生态收敛后"选择困难"反而是最少的问题
- 改完跑 `.\build.ps1 -Compose` 验证编译（本章示例零新增依赖，Hilt/Coil 代码为文档示意）

---

上一章：[18 Compose 手势处理](18-compose-gestures.md) ｜ 下一章：[20 JNI 与 NDK](20-jni-ndk.md) ｜ 返回：[README](../README.md)
