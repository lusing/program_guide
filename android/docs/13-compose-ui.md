# 13 · Compose 组件与交互

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/UiSamples.kt`

第 12 章解决了"怎么想"（状态驱动界面），本章解决"怎么搭"：把常用组件、应用骨架、对话框、进阶列表、副作用与动画一次备齐。学完本章，你就能不查文档搭出一张真实应用的界面。

## 1. 组件速查：按钮族与选择控件

`UiButtonsSample`（UI 示例1）：

```kotlin
@Composable
fun UiButtonsSample() {
    var clicks by remember { mutableIntStateOf(0) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例1：按钮族（累计点击 $clicks 次）", fontWeight = FontWeight.Bold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 4.dp)) {
            Button(onClick = { clicks += 1 }) { Text("实心") }
            OutlinedButton(onClick = { clicks += 1 }) { Text("描边") }
            TextButton(onClick = { clicks += 1 }) { Text("文本") }
        }
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 4.dp)) {
            IconButton(onClick = { clicks += 1 }) {
                Icon(Icons.Filled.Add, contentDescription = "新增")
            }
            IconButton(onClick = { }) {
                Icon(Icons.Filled.Delete, contentDescription = "删除")
            }
            Text("IconButton + Icon")
        }
    }
}
```

按钮族按"视觉权重"分级，选型看动作的重要程度：

| 组件 | 视觉权重 | 典型用途 |
|---|---|---|
| `Button` | 最高（实心填充） | 每屏至多一个的主操作：提交、保存 |
| `OutlinedButton` | 中（描边） | 次要操作：筛选、取消 |
| `TextButton` | 最低（纯文字） | 辅助动作：了解更多、跳过 |
| `IconButton` | 图标 | 工具栏动作：新增、删除、分享 |
| `FloatingActionButton` | 浮在内容上 | 代表整屏的动作（第 2 节） |

三个要点：

- **按钮内容是 `@Composable` lambda**：`Button(onClick = ...) { Text("实心") }` 的花括号就是槽位（slot），放文字、图标、行布局都行——这是 Compose 组件组合的基本手法，`Card` 的内容（第 12 章）同理
- **`Icon(Icons.Filled.Add, contentDescription = "新增")`**：图标来自 Material 图标库。本工程为此新增了唯一一个依赖 `androidx.compose.material:material-icons-core:1.7.8`（核心集 49 枚常用图标，`Add`/`Delete`/`Home` 等都在内；更大的 `icons-extended` 有数千枚但会拖慢构建，按需再加）
- **`contentDescription` 不是注释**：它是读屏软件（TalkBack）朗读的文案，漏写等于把按钮对视障用户藏起来；纯装饰性图标才显式传 `null`

选择控件（UI 示例2）一屏看完：

```kotlin
Row(verticalAlignment = Alignment.CenterVertically) {
    Checkbox(checked = checked, onCheckedChange = { checked = it })
    Text(if (checked) "已勾选" else "未勾选")
}
listOf("A", "B").forEach { opt ->
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
        RadioButton(selected = option == opt, onClick = { option = opt })
        Text("选项 $opt")
    }
}
Slider(value = slider, onValueChange = { slider = it })
Text("滑块进度：${(slider * 100).toInt()}%")
```

注意 `RadioButton` 的用法：`selected = option == opt` 是**派生值**（第 12 章第 5 节）——不存"哪个选中"的重复状态，单选互斥由"一个状态 + 现算比较"天然保证。`Switch`（第 12 章主题示例）同一模式。这批控件在传统体系里的对应物见[第 05 章](05-views-events.md)控件表，行为语义没变，变的只是"状态上报"替代了"属性读写"。

## 2. Scaffold：一屏应用的标准骨架

真实应用的每一屏几乎都是同一个骨架：顶栏 + 内容区 + 浮动按钮 + 提示条。Material3 把它做成了一个组件——`UiScaffoldSample`（UI 示例3）：

```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UiScaffoldSample() {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    Scaffold(
        // 固定高度：外层是可滚动 Column，无限高度约束下 Scaffold 撑不开
        modifier = Modifier.fillMaxWidth().height(220.dp),
        topBar = { TopAppBar(title = { Text("UI 示例3：Scaffold 骨架") }) },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        floatingActionButton = {
            FloatingActionButton(onClick = {
                scope.launch { snackbarHostState.showSnackbar("FAB 被点击") }
            }) {
                Icon(Icons.Filled.Add, contentDescription = "新增")
            }
        }
    ) { innerPadding ->
        Column(modifier = Modifier.padding(innerPadding).padding(8.dp)) {
            Text("Scaffold 内容区")
            Text("innerPadding 已避开顶栏与 FAB，内容不会被遮挡", color = Color.Gray)
        }
    }
}
```

四个槽位各司其职：

| 槽位 | 参数 | 说明 |
|---|---|---|
| 顶栏 | `topBar` | `TopAppBar(title = { ... })`，还可挂 `navigationIcon`（返回箭头）与 `actions`（右上角 IconButton 行） |
| 提示条 | `snackbarHost` | 轻量结果反馈"已保存/已删除"，几秒自动消失；对比[第 10 章](10-system-components.md)的通知——Snackbar 屏内自愈，通知进系统托盘 |
| 浮动按钮 | `floatingActionButton` | 代表整屏的动作，`contentDescription` 同样必写 |
| 内容区 | 尾 lambda 的 `innerPadding` | **必须应用**：它避开了顶栏/底栏/FAB 占的空间，不加这层 padding，内容会被顶栏盖住 |

两个新面孔值得展开：

- **`snackbarHostState`**：Snackbar 的显示是排队管理的状态，`showSnackbar(...)` 是挂起函数（显示到消失要等时间）。于是需要第二位新面孔——
- **`rememberCoroutineScope()`**：能在 `onClick` 这类**非组合上下文**里启动协程的作用域，随组合存在、离开自动取消。`onClick` 里不能直接写 `LaunchedEffect`（那是组合期 API），协程就是它的替代。第 5 节会把这对搭档讲全

`@OptIn(ExperimentalMaterial3Api::class)`：`TopAppBar` 在 material3 1.3.1 里仍标注实验性，需要显式声明"我知情"。这是 Material3 的常态，等官方转正后移除即可。

对照传统体系：Scaffold 一个组件吃掉了 XML 时代的 `CoordinatorLayout` + `AppBarLayout` + `FloatingActionButton` + `Snackbar` 四件套的协调逻辑——不再需要 behavior 配置，槽位即协议。

## 3. AlertDialog：状态驱动的对话框

对话框是"声明式"体感最强烈的组件。`UiDialogSample`（UI 示例4）：

```kotlin
@Composable
fun UiDialogSample() {
    var showDelete by remember { mutableStateOf(false) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例4：AlertDialog 删除确认", fontWeight = FontWeight.Bold)
        Button(onClick = { showDelete = true }, modifier = Modifier.padding(top = 4.dp)) {
            Text("删除便签")
        }
    }
    if (showDelete) {
        AlertDialog(
            onDismissRequest = { showDelete = false },
            title = { Text("删除确认") },
            text = { Text("便签删除后不可恢复，确定删除吗？") },
            confirmButton = {
                TextButton(onClick = { showDelete = false }) { Text("删除") }
            },
            dismissButton = {
                TextButton(onClick = { showDelete = false }) { Text("取消") }
            }
        )
    }
}
```

关键就是那个 `if`：**对话框"出现"不是被 `show()` 出来的，而是状态为真时它就在**。传统 `AlertDialog.Builder.show()` / `dismiss()` 是命令式时序，你得管理"显示标志 + dialog 实例"两份东西；Compose 里标志本身就是唯一的真相，`onDismissRequest`（点对话框外部或按返回键触发）也只是把状态写回 `false`。

三个按钮位语义固定：`confirmButton` 主操作（危险动作用强调色）、`dismissButton` 逃生门（取消）、`onDismissRequest` 兜底关闭。删除这类不可逆动作**必须**走确认对话框，别用 Snackbar 的撤销模式代替两者之一——它们是互补关系。

## 4. 列表进阶：key、增删动画与横向列表

第 12 章的 `LazyColumn` 只展示了"列表能滚动"。真实列表会增删，`UiListKeySample`（UI 示例5）补上这一课：

```kotlin
@Composable
fun UiListKeySample() {
    var nextId by remember { mutableIntStateOf(4) }
    val tasks = remember { mutableStateListOf("买牛奶" to 1, "写周报" to 2, "回邮件" to 3) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例5：列表 key 与增删动画", fontWeight = FontWeight.Bold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 4.dp)) {
            Button(onClick = {
                tasks.add("新任务 $nextId" to nextId)
                nextId += 1
            }) { Text("新增") }
            OutlinedButton(onClick = {
                if (tasks.isNotEmpty()) tasks.removeAt(tasks.lastIndex)
            }) { Text("删除末尾") }
        }
        LazyColumn(modifier = Modifier.height(110.dp).padding(top = 4.dp)) {
            items(tasks, key = { it.second }) { task ->
                Text(
                    text = "#${task.second} ${task.first}",
                    modifier = Modifier
                        .fillMaxWidth()
                        .animateItem()
                        .padding(vertical = 4.dp)
                )
            }
        }
        Text("横向 LazyRow：", modifier = Modifier.padding(top = 4.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items((1..8).toList()) { n ->
                Text(text = "标签$n", modifier = Modifier.background(Color(0xFFE3F2FD)).padding(6.dp))
            }
        }
    }
}
```

三个进阶点：

- **`mutableStateListOf`**：可观察列表——增删即触发重组，替代 `notifyItemInserted` 那一族回调。数据类换成 `data class Task(val id: Int, ...)` 是同一个道理，`Pair` 只是教学最简形态
- **`key = { it.second }`**：给每条数据一个稳定身份。没有 key，框架按"位置"对齐新旧列表；有了 key，按"身份"对齐——删除第 2 条时，框架知道是"第 2 条没了"，而不是"第 2、3 条内容变了"。**条目内部有状态（勾选框、输入框）时，没有 key 会导致状态跟着位置走、串到别的条目上**。这就是[第 07 章](07-lists-adapters.md) DiffUtil `areItemsTheSame` 在 Compose 里的对应物
- **`Modifier.animateItem()`**：声明一句，条目的出现/消失/位移自动带动画（示例里点"新增/删除"即可观察）。RecyclerView 时代要写 `DefaultItemAnimator` 定制，现在是布局声明的一部分

`LazyRow` 与 `LazyColumn` 同构，只是主轴转了 90°——横滑标签栏、卡片流都是它。再往后的 `LazyVerticalGrid`（网格）、`stickyHeader`（吸顶分组）都是同一族 API，需要时查文档即可，心智模型不变。

## 5. 副作用 API：代码什么时候真的会跑

第 12 章埋下的线：Composable 函数体会被反复执行，副作用不能直接写在函数体里。那"加载一次数据""启动一个定时器"写在哪？`UiSideEffectSample`（UI 示例6）给出标准答案：

```kotlin
@Composable
fun UiSideEffectSample() {
    var reloadKey by remember { mutableIntStateOf(0) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(reloadKey) {
        loaded = false
        delay(1200)                       // 模拟一次网络/磁盘加载
        loaded = true
    }
    // UI 按 loaded 分支渲染：加载中转圈，完成显示文字与"重新加载"按钮
}
```

`LaunchedEffect(key1) { ... }` 的契约：

- 组件**进入组合**时，用给定的 key 启动一个协程执行 lambda
- **key 变化**时，取消旧协程、用新 key 重启（示例里点"重新加载"→ `reloadKey += 1` → 重新走一遍加载）
- 组件**离开组合**时，协程自动取消——不会泄漏

于是"副作用跑几次"从猜测变成了工程契约：**key 相同就不重跑，key 变了才重跑**。选 key 的原则是"什么变了才需要重做这件事"：按用户 ID 加载资料就传 ID，只做一次就传常量。

这一族还有三个成员，各有定位：

| API | 时机 | 典型用途 |
|---|---|---|
| `LaunchedEffect(key)` | 进入组合 / key 变化 | 一次性加载、定时刷新 |
| `rememberCoroutineScope()` | 手动 `scope.launch { }` | 在 `onClick` 等回调里做挂起操作（第 2 节的 `showSnackbar`） |
| `DisposableEffect(key)` | 进入组合 + **离开时回调 `onDispose`** | 订阅/退订广播、注册/注销监听器——成对操作必须用它 |
| `produceState(initial, key)` | 把上述结果直接变成 State | `val notes by produceState(emptyList(), userId) { ... }` 的速写形态 |

（`rememberCoroutineScope` 严格说是"作用域"而非"副作用"，但它们解决同一件事：组合之外何时能有协程。）

分工原则一条：**界面级副作用**（滚到顶、弹个 Snackbar）留在 Composable 用这族 API；**业务副作用**（请求、写库）上移到 ViewModel 的 `viewModelScope`（[第 14 章](14-compose-architecture.md)）——那里不随重组反复执行，还能活过旋转。

## 6. 动画（上）：值动画与内容切换

动画是 Compose 相对传统体系体验差距最大的一块：**默认就有、声明即得**。入门只需要两句话：改一个状态，让动画 API 负责过渡。`UiAnimationValueSample`（UI 示例7）用两条进度条对比两种"过渡的性格"：

```kotlin
@Composable
fun UiAnimationValueSample() {
    var target by remember { mutableStateOf(0.2f) }
    val springValue by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(dampingRatio = 0.35f),   // 弹簧：物理驱动
        label = "spring"
    )
    val tweenValue by animateFloatAsState(
        targetValue = target,
        animationSpec = tween(durationMillis = 1200, easing = LinearEasing),  // 时长驱动
        label = "tween"
    )
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例7：值动画 spring vs tween", fontWeight = FontWeight.Bold)
        Button(onClick = { target = if (target < 0.9f) 1f else 0.2f }, modifier = Modifier.padding(top = 4.dp)) {
            Text("切换目标值")
        }
        LinearProgressIndicator(progress = { springValue }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
        LinearProgressIndicator(progress = { tweenValue }, modifier = Modifier.fillMaxWidth().padding(top = 4.dp))
        Text("上：spring（弹簧回弹）  下：tween（1.2s 线性）", modifier = Modifier.padding(top = 4.dp))
    }
}
```

`animateFloatAsState(targetValue, animationSpec)` 读起来就是一句承诺："给我一个目标值，我还你一个持续在变的当前值"。`target` 一变，`springValue`/`tweenValue` 在后续每帧自动逼近目标，UI 只管读——**动画状态本身就是派生状态**，不需要你管理"动画进行到哪了"。

过渡的性格由 `animationSpec` 决定：

| Spec | 驱动方式 | 手感 | 适用 |
|---|---|---|---|
| `spring()` | 物理弹簧（默认） | 自然、可中途打断不跳变 | 大多数交互动画（默认不写 spec 就是它） |
| `tween(300, easing)` | 固定时长 + 缓动曲线 | 可精确预测 | 进度条、与设计稿对时长 |
| `keyframes { }` | 关键帧 | 分段控制 | 复杂路径/多段节奏 |
| `snap()` | 无过渡，立即到位 | —— | 需要程序化跳变的场合 |

spring 的参数只有物理意义：`dampingRatio` 越小回弹越明显（示例 0.35f 能看到明显过冲），`stiffness` 越大越"硬"。这是 Compose 动画哲学的体现：**描述物理，而不是描述时间轴**——被打断时弹簧从当前位置继续算，不会像时间轴动画那样跳变。

同族还有 `animateColorAsState`（第 12 章主题开关的颜色切换加上它就是动画）、`animateDpAsState`（尺寸）等，参数结构完全一致。

内容随状态**整体切换**时，用 `AnimatedContent` / `Crossfade`（UI 示例8）：

```kotlin
Row(verticalAlignment = Alignment.CenterVertically) {
    Button(onClick = { count += 1 }) { Text("+1") }
    AnimatedContent(
        targetState = count,
        transitionSpec = { fadeIn(tween(200)) togetherWith fadeOut(tween(200)) },
        label = "count"
    ) { value ->
        Text("  $value", fontWeight = FontWeight.Bold)
    }
}
// 同文件里：
Crossfade(targetState = dark, label = "cross") { d ->
    Text(if (d) "深色内容" else "浅色内容", ...)
}
```

- **`AnimatedContent`**：`targetState` 变化时，旧内容按"出场"动画离开、新内容按"入场"动画进来，`togetherWith` 把两者配成一对；`transitionSpec` 里可换 `slideIn/slideOut`、`expandIn/shrinkOut` 等组合——数字翻动、方向滑动都是它
- **`Crossfade`**：`AnimatedContent` 的极简版，只做淡入淡出，一行搞定"两套界面切来切去"

再往上一层是 `updateTransition`（一次状态变化驱动多个值联动动画）与 `Animatable`（最底层出口：自己在协程里 `animateTo`，前面全不满足时才用它）。层级关系记住一句话：**从 `animate*AsState` 起步，不满足再加层**。

对照[第 05 章](05-views-events.md)的属性动画：`ObjectAnimator` 时代动画是"额外写的奢侈品"（目标值、时长、插值器、启动停止全套手动管理），Compose 里它是状态变化的默认副产品——这是声明式"UI = f(state)"在时间维度的延伸：**UI 不止是状态的函数，还是状态历史的连续函数**。

## 7. 动画（下）：可见性、尺寸与无限循环

另一半动画需求是"东西出现/消失/变形"。`UiAnimationVisibilitySample`（UI 示例9）一次演示两个：

```kotlin
@Composable
fun UiAnimationVisibilitySample() {
    var expanded by remember { mutableStateOf(false) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Button(onClick = { expanded = !expanded }, modifier = Modifier.padding(top = 4.dp)) {
            Text(if (expanded) "收起" else "展开")
        }
        AnimatedVisibility(
            visible = expanded,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Text("被展开的内容：出现与消失由 AnimatedVisibility 负责过渡。", modifier = Modifier.padding(top = 4.dp))
        }
        Text(
            text = if (expanded) "长版本：这段文字会随状态变长，容器尺寸由 animateContentSize 自动过渡。" else "短版本：点击试试",
            modifier = Modifier
                .fillMaxWidth()
                .animateContentSize()
                .background(Color(0xFFF5F5F5))
                .padding(8.dp)
                .clickable { expanded = !expanded }
        )
    }
}
```

- **`AnimatedVisibility(visible, enter, exit)`**：条件渲染加动画。`if (x) Widget()` 是瞬间出现/消失；换成 `AnimatedVisibility`，出入就有了淡入淡出 + 展开/收拢的过渡。`enter`/`exit` 用 `+` 组合多个效果（`fadeIn() + expandVertically()`），出场后还能配 `slideIn` 等——展开面板、下拉提示都是这套
- **`Modifier.animateContentSize()`**：一句话修饰符，容器尺寸变化（内容变多/变少）不再瞬间跳变，而是平滑过渡。注意它挂在**容器**上，动画的是"尺寸"这个属性本身

循环动画（加载指示、呼吸灯）用 `rememberInfiniteTransition`（UI 示例10）：

```kotlin
@Composable
fun UiInfinitePulseSample() {
    val transition = rememberInfiniteTransition(label = "pulse")
    val alpha by transition.animateFloat(
        initialValue = 0.2f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(800), repeatMode = RepeatMode.Reverse),
        label = "alpha"
    )
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 6.dp)) {
        Box(
            modifier = Modifier
                .size(18.dp)
                .alpha(alpha)
                .background(MaterialTheme.colorScheme.primary, CircleShape)
        )
        Text("UI 示例10：无限循环动画（加载脉冲）", modifier = Modifier.padding(start = 8.dp))
    }
}
```

`infiniteRepeatable(tween(800), RepeatMode.Reverse)` = 每遍 800ms、到头折返——一颗按 Material 主题色呼吸的圆点就完成了。`RepeatMode.Restart` 则是"到头跳回起点"（经典 loading 三连点）。

加上第 4 节的 `animateItem()`（列表条目动画），动画 API 的选型速查表：

| 我想要 | 用什么 |
|---|---|
| 一个值（颜色/尺寸/透明度/进度）平滑变过去 | `animateFloatAsState` / `animateColorAsState` / `animateDpAsState` |
| 两块内容切换时有过渡 | `Crossfade`（简单）/ `AnimatedContent`（要定制出入场） |
| 组件出现/消失有过渡 | `AnimatedVisibility` |
| 容器尺寸变化平滑过渡 | `Modifier.animateContentSize()` |
| 列表条目增删/排序有过渡 | `Modifier.animateItem()`（Lazy 列表内） |
| 无限循环（加载/呼吸） | `rememberInfiniteTransition` |
| 一次状态变化驱动多个值 | `updateTransition` |
| 完全自定义时间轴 | `Animatable`（协程手动驱动） |

前瞻一句：Compose 1.7 引入了实验性的 `SharedTransitionLayout`（列表图片点开铺满全屏那类"共享元素"动画），API 尚未稳定，本工程不示范；等它转正，上面的选型表加一行即可。

## 8. @Preview：不装机的看图开发

写界面最大的时间黑洞是"改一行 → 编译 → 装机 → 看一眼"。`@Preview` 把这个循环压缩到侧栏秒级刷新。`UiSamples.kt` 末尾：

```kotlin
@Preview(showBackground = true)
@Composable
private fun UiButtonsSamplePreview() {
    UiButtonsSample()
}
```

规则只有三条：

- 被预览的函数**无参**（或参数全有默认值）——所以组件要写成无状态 + 参数传入的形态（第 12 章状态提升），预览能力是白送的回报
- `showBackground = true` 加白色底，否则组件浮在检查器背景上难看清；还有 `widthDp`/`heightDp`（模拟尺寸）、`fontScale`（大字号无障碍）等参数
- 一个文件可以放**多个** Preview 函数，侧栏逐个渲染——把同一组件的多个数据形态（空列表/满列表/错误态）各写一个 Preview，等于给组件拍了组照

进阶一步是 `@PreviewParameter`（自动注入多组样例参数）与交互式预览（Studio 里直接点）。依赖上，编译期只需 `ui-tooling-preview`（已在工程），渲染器本体是 `debugImplementation("androidx.compose.ui:ui-tooling")`——只进 debug 包，release 包不背这个重量。

## 9. 常见坑

**Scaffold / LazyColumn 塞进可滚动容器不限高**：外层 `Column` 加了 `verticalScroll` 后给子级的最大高度约束是**无限**，里面的 `LazyColumn`（"给我无限高度我才能滚"）会直接抛异常，Scaffold 则会塌成一条。解法见本工程两个示例的处理：定高（`Modifier.height(220.dp)`）或把滚动交给 LazyColumn 自己（外层别套 verticalScroll）。MainActivity 整页用 `verticalScroll` 是因为示例全是小段静态内容；真实应用的"列表页"应该让 LazyColumn 占满、只有它滚。

**`LaunchedEffect(Unit)` / 常量 key 恒真**：传 `Unit` 或字面量意味着"只在进入组合时跑一次"——这本身合法（首屏加载常这么写），但当它包裹的数据**会变**（按用户 ID 加载）时就成了 bug：ID 变了加载不重跑。key 漏给的 symptom 是"切了数据源，界面还是旧数据"。

**Dialog/Snackbar 状态忘了 remember**：`var showDelete = false` 每次重组重置——对话框一闪而过或根本出不来；`showSnackbar` 是挂起函数，忘了 `scope.launch` 直接在 `onClick` 里调用，编译期就会报"suspend function can only be called within coroutine body"（这反而是好事，错误前移了）。

**IconButton 不写 `contentDescription`**：读屏用户听到的是"未加标签的按钮"。写清动作语义（"新增"），纯装饰图标才传 `null`。

## 10. 实战建议

- 组件优先选 Material3 标准件（本章速查表 + 官方组件目录），自定义控件是最后手段——先组合现有组件 + Modifier，组合不出来再谈自定义
- 每屏一个 `Scaffold`，顶栏/FAB/Snackbar 的交互契约它已经替你谈好；`innerPadding` 记得应用
- 动画从 `animate*AsState` 与 `animateContentSize` 起步，90% 的"质感提升"就来自这两者；`AnimatedContent` 用在真正的内容切换上，别给静态界面加戏
- 列表只要有增删/条目内状态，`key` 必给；`animateItem()` 顺手加上，成本一句话收益肉眼可见
- 副作用清单化检查：函数体里每出现一个非 UI 调用，问一句"它该在 `LaunchedEffect`/`DisposableEffect` 里，还是该搬去 ViewModel"（[第 14 章](14-compose-architecture.md)）
- 写组件时顺手写 `@Preview`——无状态设计 + 预览，是 Compose 开发体验的复利
- 改完跑 `.\build.ps1 -Compose` 做编译验证；[第 16 章](16-memopad.md)会把本章组件、动画与第 14 章架构全部串成完整应用

---
上一章：[12 Jetpack Compose 基础](12-compose-basics.md) ｜ 下一章：[14 Compose 工程化架构](14-compose-architecture.md)
