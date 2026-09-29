# 15 · Compose 状态与重组深入

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/StateSamples.kt`

第 19 章教会了"状态驱动界面"，第 21 章把业务状态搬进了 ViewModel。本章回到 Compose 自己的两台底层机器——**状态**与**重组**——把它们拆开看：重组的范围是怎么划定的、什么时候组件会被"跳过"、`remember` 的三条等高线（重组 / 配置变更 / 进程回收）、以及 `derivedStateOf`、`snapshotFlow` 这类为性能而生的 API。学完本章，"列表为什么卡""状态为什么丢""界面为什么不刷新"三类问题都有了系统性的排查路径。

## 1. 重组的范围：读到状态的那个代码块

第 19 章说过重组是"智能的"，现在把"智能"说精确。Compose 编译器会给每个 Composable 函数与 lambda 插桩：**函数体在执行中读了哪个可变状态，就与它建立订阅**。状态变化时，读到它的**最小代码块**被标记失效，下一帧重新执行——这就是重组的最小范围。

但"最小代码块"有资格限制：必须是**非 inline 且无返回值的 Composable 函数或 lambda**。这解释了两个日常现象：

- `Column` / `Row` 是 inline 声明的高阶函数，内容 lambda 会被展开到调用处——所以写在 `Column { }` 里的状态读取，重组范围是**外层函数**而不是这个 lambda。"点了一下计数器，整个函数体都重新执行了"正是这个原因。把内容包进一个非 inline 组件（比如 `Card`），重组范围就收缩到卡片内部
- 有返回值的函数（比如把一段 UI 逻辑提成 `fun buildLabel(): String`）不能独立成为重组范围——返回值变了会影响调用方，必须连调用方一起重组

配合编译器的另一条规则——**参数没变的子组件跳过执行**——重组的形态是：失效的最小 scope 执行，scope 里调用的子组件逐一比较参数，相同的直接跳过。整个机制发生在快照（snapshot）系统里：读状态即订阅、写状态即失效通知，天生线程安全。

## 2. 稳定性与跳过：@Stable 决定"参数没变"是否可信

"参数没变就跳过"有个前提：参数类型的比较结果是**可信**的。Compose 编译器把类型分为两类：

| 类型 | 判定 | equals 结果 |
|---|---|---|
| 基本类型、String、函数类型 | 稳定（不可变） | 可信 |
| 全部属性都是 `val` 且类型稳定的类 | 稳定 | 可信 |
| 含 `var` 属性、`List`/`Map` 等集合接口的类 | **不稳定** | 不可信 |
| `MutableState<T>` | 稳定（变化可被追踪） | —— |

不稳定类型的参数**永远参与重组**——即使两次传入 `equals` 相等，编译器也不信任这个结果（集合的内容可能在_equals 判断之后被改掉）。`StateStabilitySample`（状态2）把这个差异做成了肉眼可见的实验：

```kotlin
// tags 是 List：默认被编译器判为"不稳定"
data class UnstableTagList(val tags: List<String>)

// 加 @Stable 后向编译器承诺运行时不变
@Stable
data class StableTagList(val tags: List<String>)
```

父组件每 600ms tick 一次（`LaunchedEffect` 里无限 `delay`），每次重组都向两个子组件**新建**内容相等的实例。子组件用"渲染计数器"暴露自己是否被执行：

```kotlin
@Composable
private fun StableTagRow(item: StableTagList) {
    // 普通数组而非 mutableStateOf：计数本身不能触发重组，否则会自激震荡
    val renders = remember { intArrayOf(0) }.also { it[0]++ }
    Text("…渲染 ${renders[0]} 次…")
}
```

跑起来的结果：不稳定参数那一行的计数每 600ms 涨一次（每次都被执行）；`@Stable` 参数那一行停在初次值（equals 相等被跳过）。

**`@Stable` 的适用对象**：你确定运行时不可变、但类型签名让编译器无法自动判稳的类型——集合字段、接口类型最典型。被标注的密封类/接口，其全部子类一并视为稳定。还有一个更强的兄弟 `@Immutable`（完全不可变），两者功能重叠，官方建议优先 `@Stable`。

实战清单：

- `data class` 尽量全 `val` + 稳定类型属性，让编译器自动判稳
- 实在要用 `List` 字段，要么换 `ImmutableList`（kotlinx.collections.immutable），要么给类加 `@Stable` 并自律不改内容
- `UiState` 密封类（第 21 章第 3 节）加 `@Stable`，列表屏幕的跳过效率会好一截

## 3. key()：给循环里的组件发身份证

编译器靠**调用位置**给组件建索引。但 `forEach` 里的组件位置是同一个，框架只能按"第 N 个"对齐新旧列表——在头部插入一条数据，所有"第 N 个"的内容都变了，整列重组。`StateKeySample`（状态3）用同样的渲染计数器对比了两种写法：

```kotlin
rows.forEach { row -> KeyRowText(row) }        // 无 key：头部插入后全部重渲染

rows.forEach { row ->
    key(row.id) { KeyRowText(row) }             // 有 key：按身份对齐，旧行被跳过
}
```

`key(row.id)` 给循环里的组件发放了**运行时身份**：插入头部后，旧行的 id 没变、参数没变，逐个被跳过——计数器纹丝不动，只有新行从 1 开始计。这正是第 20 章 `LazyColumn` 的 `items(list, key = { it.id })` 的底层原理：Lazy 列表把 key 机制做成了参数；普通 `Column + forEach` 场景就手包一层 `key()`。**只要列表会增删/排序，且条目内有状态或重组成本高，key 必给。**

## 4. remember 的三条等高线：rememberSaveable

第 21 章第 1 节给过 `remember` / `rememberSaveable` / `ViewModel` 的对照表，本章补上 `rememberSaveable` 的机制细节。`StateSaveableSample`（状态1）是两条可点的计数器，旋转屏幕后一条归零、一条保留：

```kotlin
var plain by remember { mutableIntStateOf(0) }          // 活过重组，死于配置变更
var saved by rememberSaveable { mutableIntStateOf(0) }  // 活过重组 + 配置变更 + 进程回收
```

机制：`rememberSaveable` 的数据随 `onSaveInstanceState` 写进 Bundle，进程重建时按编译期确定的组件标识恢复。三条边界要记住：

- **能存什么**：Bundle 支持的基本类型直接存。自定义对象加 `@Parcelize`（Kotlin 编译器插件 `kotlin-parcelize` 生成 Parcelable 实现）后可存
- **存不了什么**：`MutableState<T>` 本身可存，但装着大对象、协程、Bitmap 的状态不行——Bundle 有 1MB 量级的 TransactionTooLarge 限制
- **自定义 Saver**：三库类没法加 Parcelable 时，用 `listSaver` / `mapSaver` 把对象拆成可 Bundle 的字段：

```kotlin
data class City(val name: String, val population: Int)

val CitySaver = listSaver<City, Any>(save = { listOf(it.name, it.population) },
                                     restore = { City(it[0] as String, it[1] as Int) })
val city = rememberSaveable(stateSaver = CitySaver) { mutableStateOf(City("北京", 2189)) }
```

一句话选型（承接第 21 章的表格）：界面小状态过旋转用 `rememberSaveable`；带业务逻辑的屏幕状态交给 ViewModel；`ViewModel` + `SavedStateHandle` 组合能同时活过进程回收——那是第 21 章的领地。

## 5. derivedStateOf：一份数据，两种变化频率

重组的性能问题常来自"高频状态被低频消费者订阅"。典型：`LazyListState.firstVisibleItemIndex` 在滚动中每行都变，而"是否显示回到顶部按钮"只关心 `> 0` 这个布尔。直接在组件里读 index，每次滚动全屏重组；用 `derivedStateOf` 包一层，只有**派生值本身变了**才通知：

```kotlin
val listState = rememberLazyListState()
val awayFromTop by remember { derivedStateOf { listState.firstVisibleItemIndex > 0 } }
```

`StateDerivedSample`（状态4）就是这段代码加上列表与徽标。判断口诀：

- **状态变化频率 ≈ UI 变化频率**（`input` 变 → 提示语变）→ 直接读，别包
- **状态高频变、UI 只关心粗糙的结果**（index 每行变 → 布尔翻转才要）→ `derivedStateOf`
- 计算依赖的是**普通变量**而非 State → 派生不动，用 `remember(key)` 的 key 机制

## 6. snapshotFlow：副作用协程里的状态观察窗

`LaunchedEffect` 的协程里想"盯着某个状态变"怎么办？把状态设成 LaunchedEffect 的 key 会在变化时**重启整个协程**——代价太高。`snapshotFlow { }` 把状态读取转成冷流：状态变了才发射，相同值不发射（自带 `distinctUntilChanged` 语义）：

```kotlin
LaunchedEffect(listState) {
    snapshotFlow { listState.firstVisibleItemIndex }
        .collect { index -> currentIndex = index }
}
```

`StateSnapshotFlowSample`（状态5）用计数器展示"发射了几次"：滚动一屏只发射数次（每次 index 变化），而不是每帧都发射。key 的正确姿势也随之明确：**State 对象本身**当 key（实例替换时重启副作用），状态**的值**交给 `snapshotFlow` 监听。

## 7. rememberUpdatedState：长命副作用读新值

`LaunchedEffect(Unit)` 里直接调用外部传进来的 lambda 参数，固化的是**首组合时传入的那个实例**——之后父级重组传入新 lambda，协程里还在调旧的。`rememberUpdatedState` 把 lambda 装进一个每次重组都刷新的 State：

```kotlin
@Composable
private fun CountdownStrip(totalSeconds: Int, onTick: () -> Unit, onDone: () -> Unit) {
    val currentOnTick by rememberUpdatedState(onTick)
    val currentOnDone by rememberUpdatedState(onDone)
    LaunchedEffect(totalSeconds) {
        repeat(totalSeconds) { delay(1000); currentOnTick() }   // 始终是最新实例
        currentOnDone()
    }
}
```

`StateRememberUpdatedSample`（状态6）就是这条倒计时条。配套的选 key 原则一句话：**状态的改变需要"终止并重启"副作用时才做 key；只需要回调时拿到最新值，用 rememberUpdatedState 包装**。官方的计时器、动画内部大量使用这个模式。

## 8. StateHolder：状态与逻辑一起搬出 Composable

第 19 章的"状态提升"把状态搬到调用方；当**多个状态 + 配套逻辑**长在一起（步进计数器的 count/step/increment/reset），逐个提升会让调用方参数爆炸。第三个选项：写一个普通类打包，`remember` 进组合——状态容器（StateHolder）：

```kotlin
private class CounterStateHolder(initial: Int = 0) {
    var count by mutableIntStateOf(initial)
        private set                       // 对外只读，写走方法——与第 21 章 VM 同一纪律
    var step by mutableIntStateOf(1)
    fun increment() { count += step }
    fun reset() { count = 0 }
}

@Composable
private fun rememberCounterState() = remember { CounterStateHolder() }
```

`StateHolderSample`（状态7）用一个 `rememberCounterState()` 把 UI 函数体清空到只剩布局。三条选型纪律（书里叫"状态的分层管理"）：

| 容器 | 存活范围 | 适合放 |
|---|---|---|
| Stateful Composable | 与组件共存亡 | 一两个界面小状态（开关、输入） |
| StateHolder | 与组件共存亡（可配 rememberSaveable） | 一组 UI 状态 + UI 逻辑（滚动状态、表单校验） |
| ViewModel | 跨配置变更 | 业务状态 + 业务逻辑（数据请求、写库） |

三者在真实工程**并存**：Composable 持有小状态、StateHolder 收纳成组的 UI 逻辑、ViewModel 管业务——StateHolder 与 ViewModel 的边界就是"UI 相关与否"。需要多实例（同一屏幕出现两次的同款组件）时必须用 StateHolder：ViewModel 在 Store 范围内只有一份。

## 9. 常见坑

**渲染计数器用 mutableStateOf**：想观察"组件被执行了几次"，顺手写了 `var n by remember { mutableIntStateOf(0) }; n++`——写状态让自己失效，无限重组。计数必须用**不可观察**的容器（`intArrayOf`、`Ref`）。

**给高频状态当 key**：`LaunchedEffect(listState.firstVisibleItemIndex) { ... }`——每滚一行副作用重启一次，前功尽弃。key 用 State 对象本身，值交给 `snapshotFlow`（第 6 节）。

**`derivedStateOf` 忘了 remember**：`val d = derivedStateOf { ... }` 直接写在函数体里——每次重组新建派生实例，缓存与去重全部失效。标准写法 `remember { derivedStateOf { ... } }`。

**`rememberSaveable` 装大对象**：Bitmap、长列表塞进去，运行期 `TransactionTooLargeLarge` 崩溃。大对象走 ViewModel/磁盘，Bundle 只放轻量值。

**给不稳定类型加 @Stable 却偷偷改内容**：`@Stable` 是"承诺"不是"验证"——注解了又运行时改集合内容，跳过机制会展示旧值且无任何警告。承诺了就要自律（或用不可变集合库）。

## 10. 实战建议

- 列表卡顿先查三件套：`key` 给了没、参数类型稳定没（`@Stable`）、高频状态包 `derivedStateOf` 没——多数"Compose 慢"是这三个没做
- 观察重组用 Layout Inspector 的"重组计数"或本工程的渲染计数器法，先量化再优化，别凭感觉加 `remember`
- 状态选型按第 8 节的表走：小状态就地、成组逻辑进 StateHolder、业务进 ViewModel；别把一切塞进 ViewModel（预览与测试都会变难）
- 需要活过旋转的纯 UI 状态（滚动位置、展开态）优先 `rememberSaveable`，比把所有东西搬进 ViewModel 便宜得多
- 改完跑 `.\build.ps1 -Compose` 验证编译；本章 API 全部来自 runtime，零新增依赖

---

上一章：[21 Compose 工程化架构](21-compose-architecture.md) ｜ 下一章：[23 Compose 自定义布局与绘制](23-compose-layout-draw.md) ｜ 返回：[README](../README.md)
