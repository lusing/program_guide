# 12 · Jetpack Compose 基础

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/ComposeSamples.kt`

## 1. 声明式 vs 命令式：全书分水岭

第 05 章的 View 体系是命令式（imperative）的：先在 XML 里摆好控件，再在代码里拿到引用、逐条改属性。一个计数器写出来是这样的（第 05 章风格回顾，简化版）：

```kotlin
// 命令式：状态在变量里，界面靠手动刷新
private var count = 0
val tv = findViewById<TextView>(R.id.counterText)
val button = findViewById<Button>(R.id.button)
button.setOnClickListener {
    count += 1
    tv.text = "计数 = $count"     // 漏掉这行，界面就停留在旧值
}
```

Compose 把这件事整个倒过来：**界面是状态的函数**——UI = f(state)。你不再"改界面"，只改状态；框架发现状态变了，自动重新执行描述界面的函数，把差异刷上屏幕。同一个计数器，`ComposeSamples.kt` 里的 `ComposeCounterSample`：

```kotlin
@Composable
fun ComposeCounterSample() {
    var count by remember { mutableIntStateOf(0) }
    Text(
        text = "Compose 示例1：计数器 = $count",
        modifier = Modifier
            .fillMaxWidth()
            .clickable { count += 1 }
            .padding(vertical = 6.dp),
        fontWeight = FontWeight.Bold
    )
}
```

没有 `findViewById`，没有 `setText`，点击处只有一行 `count += 1`。

| | 命令式（View 体系） | 声明式（Compose） |
|---|---|---|
| 界面描述 | XML + 代码操控 | Kotlin 函数 |
| 更新方式 | 手动改属性 | 改状态，框架重组 |
| 状态归属 | 分散在各控件字段 | 集中在 `remember` / ViewModel |
| 一致性风险 | 漏改一处就不同步 | UI = f(state)，不存在漏改 |

命令式要回答"怎么把界面**改成**那样"，声明式只需回答"状态**是**什么样"。这是本教程前 11 章与后 4 章的分水岭：第 05、07 章的控件与 Adapter 思维在此退役；但第 04 章的生命周期、第 08 章的线程模型依然全程有效——Compose 替换的是窗口里的 View 树，不是 Android 的组件模型。

## 2. 入口：setContent

传统 Activity 用 `setContentView(R.layout.xxx)` 把 XML 塞进窗口；Compose 工程的 `MainActivity`（`compose_examples/app/src/main/java/guide/android/compose/MainActivity.kt`，import 略）用 `setContent { }` 直接在 Kotlin 里描述整棵界面树：

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    ComposeCounterSample()
                    ComposeLazyListSample()
                    ComposeThemeToggleSample()
                    ComposeFormValidationSample()
                    ComposeCardListSample()
                    JniStatusSample()
                    AdvancedViewModelStateFlowSample()
                    AdvancedNavigationSample()
                    AdvancedRoomArchitectureSample()
                    AdvancedWorkManagerSample()
                }
            }
        }
    }
}
```

四个要点：

- `ComponentActivity` 与第 04 章讲解的是同一谱系（`androidx.activity` 提供），生命周期回调一个不少——Compose 没有"另起炉灶"
- `setContent { }` 是 `activity-compose` 提供的扩展函数，代替 `setContentView`；花括号内就是界面本身
- `Surface` + `MaterialTheme.colorScheme.background`：Material3 主题的背景容器（第 8 节展开）
- 后四个 `Advanced*` 是第 13 章的进阶示例，本章只看前六个

开关在 `app/build.gradle.kts`：

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")   // Kotlin 2.0 起 Compose 编译器随 Kotlin 一起发布
}

android {
    buildFeatures {
        compose = true
    }
}
```

本工程版本与依赖（与[第 02 章](02-project-toolchain.md)的构建链对应）：AGP 8.7.3、Kotlin 2.0.21、compileSdk 35、minSdk 24。

| 依赖 | 版本 | 作用 |
|---|---|---|
| `androidx.activity:activity-compose` | 1.10.1 | `setContent` 入口 |
| `androidx.compose.ui:ui` | 1.7.8 | runtime、布局、输入、Modifier |
| `androidx.compose.material3:material3` | 1.3.1 | Material 3 组件与主题 |
| `androidx.compose.ui:ui-tooling-preview` | 1.7.8 | `@Preview` 预览支持 |

## 3. @Composable：函数即组件

`@Composable` 不是普通注解：`org.jetbrains.kotlin.plugin.compose` 编译器插件会把标注的函数改写成"可组合的"——能在组合（composition，正在构建的界面树）里建立节点、订阅状态。于是：

- **函数就是组件**：调用 `ComposeCounterSample()` 这一行，等价于命令式里"创建一个控件并加进布局"。没有类、没有继承 `View`，任何函数标上 `@Composable` 就是组件
- **参数就是输入**：组件的一切外部信息经由参数传入（后面会看到 `Modifier` 也是参数）
- **命名惯例**：名词、大驼峰（`ComposeCounterSample`，不是 `composeCounterSample`）。它在代码里的角色与 `TextView` 同级，命名也向控件看齐，读起来才像"在摆界面"
- **预览一句话**：给无参 `@Composable` 再标一个 `@Preview`，Android Studio 侧栏即可单独渲染它，不必装到设备（本工程已引入 `ui-tooling-preview`）

## 4. 状态与重组：点击 +1 时发生了什么

`ComposeCounterSample` 的第一行信息量最大：

```kotlin
var count by remember { mutableIntStateOf(0) }
```

拆开看：

- `mutableIntStateOf(0)`：可观察的状态盒子，装着初值 0。Int 专用重载避免装箱；String/Boolean 等用 `mutableStateOf(...)`（示例 3 的 `dark`、示例 4 的 `input` 就是）
- `remember { }`：把 lambda 的结果"存"进组合，重组发生时**不重新执行**这个 lambda，取回上次存的值
- `by`：属性委托，让 `count` 用起来像普通 `Int`（需要 `import androidx.compose.runtime.getValue` / `setValue`）

点击 +1 的完整链路：

1. `clickable` 的回调执行 `count += 1`，写入状态盒子
2. Compose 的快照（snapshot）系统记着"谁读过 `count`"，此刻把这些读取者标记失效
3. 下一帧，`ComposeCounterSample` 函数体从头到尾重新执行一遍——这就是**重组（recomposition）**
4. 新的 `Text(text = "...计数器 = 1", ...)` 与旧界面求差异，只有变化的部分被应用到屏幕

关键推论：**函数体会被反复执行**。所以函数体必须"纯"——同样的状态进来，产出同样的界面；网络请求、写库、弹 Toast 这类副作用不能直接放函数体里（第 9 节）。

还有一个边界要划清：`remember` 活过重组，但**不活过 Activity 重建**（旋转屏幕、切换深色模式，见[第 04 章](04-activity-lifecycle.md)）——旋转后 `count` 归零不是 bug，是设计边界。跨过这条边界就需要 ViewModel，那是[第 13 章](13-compose-architecture.md)的动机。

## 5. 状态提升：状态放哪，事件往哪流

`ComposeFormValidationSample` 展示了状态驱动的典型形态：

```kotlin
@Composable
fun ComposeFormValidationSample() {
    var input by remember { mutableStateOf("") }
    val isValid = input.length >= 4
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        OutlinedTextField(
            value = input,
            onValueChange = { input = it },
            label = { Text("Compose 示例4：输入至少 4 个字符") }
        )
        Text(
            text = if (isValid) "输入有效" else "输入过短",
            color = if (isValid) Color(0xFF2E7D32) else Color(0xFFC62828)
        )
    }
}
```

两件事值得放大：

- `OutlinedTextField(value = ..., onValueChange = ...)`：连"用户输入"都不是控件自己管的——它渲染传入的 `value`，把每次按键作为事件上报，由状态写回后再重组出新内容。命令式习惯里"从控件里取 text"的动作消失了
- `val isValid = input.length >= 4` 是**派生值**：每次重组现算，不占第二份状态。命令式习惯会写"输入变化时同步更新一个 isValid 标志位"——声明式里这是反模式，两份状态就有不同步的机会

**状态提升（state hoisting）** 就是把这两条原则推到组件边界：状态搬到共同调用方，子组件只接收值与回调，变成无状态（stateless）组件。改造示意（非示例工程代码）：

```kotlin
@Composable
fun ValidatedField(input: String, onInputChange: (String) -> Unit) {
    Column {
        OutlinedTextField(value = input, onValueChange = onInputChange)
        Text(if (input.length >= 4) "输入有效" else "输入过短")
    }
}

// 状态住在调用方
var input by remember { mutableStateOf("") }
ValidatedField(input, { input = it })
```

提升到哪层为止？提到"需要这份状态的最小共同祖先"为止；再往上（跨屏、业务级）就该交给 ViewModel 了（[第 13 章](13-compose-architecture.md)）。

## 6. Modifier：普通对象，不是魔法字符串

每个 Compose 组件都收一个 `Modifier`，用链式调用描述尺寸、间距、行为。回看计数器：

```kotlin
modifier = Modifier
    .fillMaxWidth()                  // 占满父容器宽度
    .clickable { count += 1 }        // 包一层点击处理
    .padding(vertical = 6.dp)        // 内容再留 6dp 内边距
```

与 XML 属性的本质差别：XML 属性是字符串键值，inflate 时才解析，拼错运行时才知道；`Modifier` 是**普通 Kotlin 对象**——链上每个函数返回"包住前一层"的新对象（洋葱模型），编译期类型检查、IDE 补全，还能存进变量、当参数传、按条件拼接：

```kotlin
val rowModifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)
// 可以继续包，也可以原样传给多个子组件复用
```

顺序即包裹顺序，所以**顺序敏感**：

```kotlin
Modifier.clickable { }.padding(16.dp)   // clickable 在外层：点击区包含 padding
Modifier.padding(16.dp).clickable { }   // padding 在外层：只有内容区可点
```

示例 1 用的是前一种，所以上下 6dp 的留白也能点。调换链序不报错，只是行为"反了"。惯例（也是官方库的一贯做法）：自定义组件第一个参数收 `modifier: Modifier = Modifier`，让调用方控制外层布局。

## 7. 列表：LazyColumn

`ComposeLazyListSample` 全文：

```kotlin
@Composable
fun ComposeLazyListSample() {
    val itemsData = remember { (1..5).map { "Compose 列表项 $it" } }
    LazyColumn(modifier = Modifier.padding(vertical = 6.dp)) {
        items(itemsData) { item ->
            Text(text = "Compose 示例2：$item", modifier = Modifier.padding(2.dp))
        }
    }
}
```

对照[第 07 章](07-lists-adapters.md)的 RecyclerView：

| | RecyclerView | LazyColumn |
|---|---|---|
| 必须写的类 | Adapter + ViewHolder（+ DiffUtil） | 无 |
| item 布局 | 单独的 XML 文件 | 内联 `@Composable` |
| 数据更新 | `notifyItemXxx` / DiffUtil | 状态变了自动重组 |
| 复用机制 | 手写ViewHolder 复用 | 框架只组合可见项 |
| 代码量 | 几十到上百行 | 六行 |

Lazy 的含义是**虚拟化**：不是把所有项都组合出来，而是只组合视口内（及附近）的项，滚动时按需创建销毁——RecyclerView 用 ViewHolder 复用达成的目标，Compose 用"函数随叫随到"达成。数据是静态的所以 `remember` 了一次；真实应用里列表数据通常来自 ViewModel（[第 13 章](13-compose-architecture.md)）。

选型：几个固定项用 `Column` + `forEach`（第 8 节的卡片列表就是这么写的）；可能超屏、动态增删的列表用 `LazyColumn`，并建议 `items(list, key = { it.id })` 给稳定 key，帮框架识别增删。

## 8. Material 3：主题与卡片

`ComposeThemeToggleSample`：

```kotlin
@Composable
fun ComposeThemeToggleSample() {
    var dark by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "Compose 示例3：主题切换（${if (dark) "Dark" else "Light"}）",
            color = if (dark) Color.Gray else MaterialTheme.colorScheme.onBackground
        )
        Switch(checked = dark, onCheckedChange = { dark = it })
    }
}
```

状态怎么流动：`Switch` 的 `onCheckedChange` 写 `dark` → 本函数重组 → `Text` 的 `color` 表达式按新值重新求值。点击控件、读状态的方向与第 5 节完全一致。

要诚实指出：这个示例**没有真正切换主题**——`dark` 只控制了一处硬编码颜色（三元表达式）。正规做法是把 `dark` 提升到 `setContent` 顶层，用主题组件包裹整棵树：

```kotlin
MaterialTheme(colorScheme = if (dark) darkColorScheme() else lightColorScheme()) {
    App()
}
```

这样所有组件统一从 `MaterialTheme.colorScheme` 读颜色。`MaterialTheme` 本质是框架用 CompositionLocal 提供的"隐式环境参数"，`MainActivity` 里的 `Surface(color = MaterialTheme.colorScheme.background)` 就是它的消费方。

`ComposeCardListSample` 则是 Material 容器组件的样子：

```kotlin
@Composable
fun ComposeCardListSample() {
    val cards = remember { listOf("Kotlin", "Jetpack Compose", "JNI") }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("Compose 示例5：卡片列表")
        cards.forEach { title ->
            Card(modifier = Modifier.fillMaxWidth().padding(top = 6.dp)) {
                Text(text = title, modifier = Modifier.padding(10.dp))
            }
        }
    }
}
```

`Card` 的内容就是一个 `@Composable` lambda——三个固定项用 `Column` + `forEach`，换成 `LazyColumn` + `items` 即可承载长列表。

## 9. 常见坑

**状态忘了 remember**：写成 `var count = 0`，或 `var input by mutableStateOf("")` 不套 `remember`——每次重组都重新初始化。症状是"界面不理你"：点击计数没反应、输入框打不出字（每敲一个字符，重组把状态抹回初值）。不报错，极具迷惑性。

**在重组里做副作用**：函数体里直接发请求、写文件、弹 Toast——重组次数与时机不受你控制（父级刷新、主题变化、旋转都会触发），副作用会无端多跑。用 `LaunchedEffect(key) { }`（key 变化才重新执行）承载副作用，业务型副作用干脆上移到 ViewModel（[第 13 章](13-compose-architecture.md)）。

**Modifier 顺序敏感**：`clickable` 与 `padding` 谁在外层，点击区就差一块（第 6 节）。Compose 不给任何警告，布局"反了"先查链序。

**`by` 委托缺 import**：忘 `import androidx.compose.runtime.getValue` / `setValue` 时，报错是一句费解的 "no method 'getValue()"，与真实原因相去甚远。用 `by remember` 就成对带上这两个 import。

## 10. 实战建议

- 界面小状态（输入内容、开关）用 `remember`；屏幕级、业务级状态进 ViewModel（[第 13 章](13-compose-architecture.md)），不要什么都塞 `remember`
- 派生值永远现算，不存第二份状态——"两处状态不同步"这一整类 bug 从根上消灭
- 自定义组件写成无状态 + `modifier` 参数，状态放调用方：复用、预览、测试三赢
- 超过一屏或动态增删的列表用 `LazyColumn` 并给 `key`；几个固定项才用 `Column` + `forEach`
- 改完跑 `.\build.ps1 -Compose` 做编译验证，这是本仓库的标准流程（[第 02 章](02-project-toolchain.md)）
- 第 15 章实战项目会把本章与第 13 章的全部内容串成一个完整应用

---
上一章：[11 运行时权限、ContentResolver 与硬件服务](11-permissions-content.md) ｜ 下一章：[13 Compose 工程化架构](13-compose-architecture.md)
