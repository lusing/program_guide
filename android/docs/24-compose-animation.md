# 17 · Compose 动画进阶

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/AnimationSamples.kt`

第 20 章的动画两节覆盖了 90% 的日常需求：`animate*AsState`、`AnimatedVisibility`、`AnimatedContent`、`animateContentSize`、无限循环。本章补齐剩下 10% 的深水区——按《Jetpack Compose 从入门到实战》第 6 章的体系：先认识动画 API 的分层地图，再用 `AnimationSpec` 家族精确控制"过渡的性格"，然后是 `updateTransition`（多属性联动）与 `Animatable`（完全手动驱动），最后以两个实战收尾：骨架屏 shimmer 与收藏按钮。

## 1. 动画地图：高级别与低级别

Compose 动画 API 按易用性分两层：

| 层 | API | 特点 |
|---|---|---|
| 高级别 | `AnimatedVisibility` / `AnimatedContent` / `Crossfade` / `animateContentSize` / `animate*AsState` | Composable 或 Modifier，开箱即用，覆盖常见业务 |
| 低级别 | `updateTransition` / `Animatable` / `AnimationSpec` / `TwoWayConverter` | 状态驱动任意动画，接口复杂、控制力强 |

高层全部由低层实现：`animate*AsState` 的底层是 `Animatable`，`AnimatedContent` 的底层是 `updateTransition`。选型路径一句话（第 20 章已给速查表，本章给原理）：**从 `animate*AsState` 起步，一个状态要驱动多个值就用 `updateTransition`，连"目标值"都想自己算就用 `Animatable`。**

传统 View 时代 `ObjectAnimator`（固定时长）与 `SpringAnimation`（物理驱动）是两套 API；Compose 用统一的 `AnimationSpec` 把两者收编进了同一条参数。

## 2. AnimationSpec 家族：过渡的性格

`AnimSpecCompareSample`（动效1）把四种 spec 并排放：同一个目标值，四条进度条各自过渡——

```kotlin
val springValue by animateFloatAsState(target, spring(dampingRatio = Spring.DampingRatioMediumBouncy))
val tweenValue  by animateFloatAsState(target, tween(1200, easing = LinearEasing))
val keyframesValue by animateFloatAsState(target, keyframes {
    durationMillis = 1200
    (target / 2) at 700 using FastOutSlowInEasing     // 700ms 时只走到一半：先慢后快
})
val snapValue   by animateFloatAsState(target, snap())
```

| Spec | 驱动 | 关键参数 | 适用 |
|---|---|---|---|
| `spring` | 物理弹簧（不写 spec 的默认值） | `dampingRatio` 阻尼比、`stiffness` 刚度 | 交互动画；打断后从当前位置继续，不跳变 |
| `tween` | 固定时长 + 缓动 | `durationMillis`、`easing` | 与设计稿对时长、进度条 |
| `keyframes` | 关键帧（时长类） | `值 at 时刻 using 曲线` | 分段节奏、复杂路径 |
| `snap` | 无过渡立即到位 | `delayMillis` | 程序化跳变、关闭过场 |
| `repeatable` / `infiniteRepeatable` | 循环播放时长类 spec | `iterations` / 无限、`RepeatMode` | 加载动画（第 20 章已用） |

三个要点：

- **spring 是默认**且值得信赖：物理驱动意味着打断时从当前位置、当前速度续算，不会像时间轴动画那样闪跳。`DampingRatioMediumBouncy` 有肉眼可见的回弹，`NoBouncy`（默认）干净利落
- **keyframes 的中缀语法**就是给"时间-值-曲线"三元组写的 DSL：`0.5f at 700 using FastOutSlowInEasing` 读作"700 毫秒时到 0.5，这一段用这条曲线"
- **repeatable 只包时长类 spec**——`spring` 不能循环，永动的弹簧违背物理定律；要循环动画，里面包 `tween` 或 `keyframes`（第 20 章的 `infiniteRepeatable(tween(800))` 即是）

`easing` 曲线（`LinearEasing` 线性、`FastOutSlowInEasing` 快进慢出等）是 tween/keyframes 的时间函数：输入时间进度 0~1、输出值进度 0~1；内置曲线不够用时有 `CubicBezierEasing` 自定义。

## 3. updateTransition：一个状态，多个属性，同步起止

一个开关翻转要同时动背景色、圆角、尺寸——用三个独立的 `animate*AsState` 可以，但三个动画各自为政，起止时间可能有微妙错位；且"状态 → 各属性目标值"的映射逻辑散落三处。`updateTransition` 把它们收进同一个事务。`AnimTransitionSample`（动效2）：

```kotlin
private enum class ExpandState { Collapsed, Expanded }

val transition = updateTransition(targetState = expanded, label = "expand")
val color  by transition.animateColor(label = "color")  { if (it == Expanded) Color(0xFF2E7D32) else Color(0xFF90CAF9) }
val corner by transition.animateDp(label = "corner")    { if (it == Expanded) 32.dp else 8.dp }
val size   by transition.animateDp(label = "size")      { if (it == Expanded) 96.dp else 48.dp }
```

读法：`updateTransition(状态)` 建一个 Transition，`transition.animateXxx { 状态 -> 目标值 }` 注册子动画——**状态一变，所有子动画同起同止**，各自用默认 spring（可传 `transitionSpec` 定制）。它相当于传统 View 的 `AnimationSet`。

注意与第 20 章 `EnterTransition`/`ExitTransition` 的名字撞车——那是 `AnimatedVisibility` 的出入场描述，此 Transition 是"多属性动画事务"，两码事。

配套技巧两个：`createChildTransition` 把父状态 map 成子状态（拨号按钮只关心自己的显隐布尔，不感知整机状态）；`Transition.AnimatedVisibility` / `Transition.AnimatedContent` 扩展把出入场动画也纳入同一事务。动画属性多了以后，用"持有全部动画值的类 + 更新函数"封装复用（动效 6 的做法）。

## 4. Animatable：完全手动驱动

`animate*AsState` 的目标值只能来自重组，动画过程对你是不透明的。`Animatable` 是它的底层：一个**动画值包装器**，`animateTo` / `snapTo` / `animateDecay` 都是**挂起函数**，跑在你自己的协程里。`AnimManualSample`（动效3）：

```kotlin
val value = remember { Animatable(0.2f) }        // Float 工厂重载
val scope = rememberCoroutineScope()

scope.launch {
    value.snapTo(0f)                              // 立即跳变
    value.animateTo(1f, animationSpec = tween(1500))   // 挂起直至动画完成
}
```

相比 `animate*AsState`，手动驱动的额外能力：初值可以任意指定；`snapTo` 跳变、`animateDecay` 衰减（第 25 章 Fling 的引擎）；动画中途再次 `animateTo` 会**从当前位置、当前速度平滑改道**；还能加边界（`Animatable(0f, 0f..1f)`）自动在边界反弹。代价是你要自己管协程与生命周期——`remember` + `rememberCoroutineScope` / `LaunchedEffect` 是标准搭配。

## 5. TwoWayConverter：给任意类型插值

动画引擎只会对 `AnimationVector`（1D~4D 浮点矢量）插值。常用类型（Float、Color、Dp、Offset、Size…）的内建转换器已备好——`animate*AsState` 家族就是"类型 + 转换器"的组合。**自定义类型**想参与动画，手写一个双向转换器即可。`AnimCustomTypeSample`（动效4）给"左右边距"这对 Dp 做动画：

```kotlin
private data class SidePadding(val start: Dp, val end: Dp)

private val SidePaddingConverter = TwoWayConverter(
    convertToVector   = { p: SidePadding -> AnimationVector2D(p.start.value, p.end.value) },
    convertFromVector = { v: AnimationVector2D -> SidePadding(v.v1.dp, v.v2.dp) }
)

val padding by animateValueAsState(
    targetValue = if (expanded) SidePadding(24.dp, 48.dp) else SidePadding(4.dp, 4.dp),
    typeConverter = SidePaddingConverter, ...)
```

维度对上就行：一个数用 `AnimationVector1D`（注意取值是 `.value`），两个数 2D（`.v1/.v2`），Color 是 4D（RGBA）。书里给的记忆法：转换器是"值 ⇄ 矢量"的往返翻译，动画引擎只在矢量空间工作。

## 6. 实战一：骨架屏 shimmer

加载中的列表页常见"灰色占位块 + 微光扫过"。拆解：占位块是普通布局，微光是一个**位置随无限动画移动的线性渐变笔刷**。`AnimShimmerSample`（动效5）：

```kotlin
val transition = rememberInfiniteTransition(label = "shimmer")
val translate by transition.animateFloat(
    initialValue = -200f, targetValue = 600f,
    animationSpec = infiniteRepeatable(tween(1300, easing = LinearEasing), RepeatMode.Restart),
    label = "translate")

val brush = Brush.linearGradient(
    colors = listOf(Color(0xFFEEEEEE), Color(0xFFFAFAFA), Color(0xFFEEEEEE)),
    start = Offset(translate, 0f), end = Offset(translate + 200f, 0f))   // 端点跟着动画走

repeat(2) { ShimmerItem(brush) }        // 每个占位块都刷同一支笔刷
```

第 20 章的 `rememberInfiniteTransition` 在这里驱动的是**笔刷几何**而非组件属性——"动画什么"完全由你决定，这是声明式动画的深层灵活性：把 `translate` 换成 DrawScope 里的画布偏移（第 23 章），就是书的"波浪加载"实战。

## 7. 实战二：收藏按钮（多属性状态切换）

需求：收藏按钮在"未收藏（宽矩形、浅底）/ 已收藏（圆形、深底）"两态切换，宽度、配色、圆角**逐属性**平滑过渡。`AnimFavButtonSample`（动效6）——先用 enum 把两态的 UI 参数建成表：

```kotlin
private enum class FavState(val bg: Color, val fg: Color, val corner: Dp, val width: Dp) {
    Idle(Color(0xFFFFE0B2), Color(0xFF5D4037), 28.dp, 140.dp),
    Done(Color(0xFFE53935), Color.White,   28.dp, 56.dp)
}

val transition = updateTransition(targetState = state, label = "fav")
val bg     by transition.animateColor(label = "bg")     { it.bg }
val corner by transition.animateDp(label = "corner")    { it.corner }
val width  by transition.animateDp(transitionSpec = { tween(300) }, label = "width") { it.width }
```

为什么不用 `AnimatedContent` 一把梭？内容切换动画把整块 UI 当一个整体淡入淡出，各属性**无法分别过渡**；`updateTransition` 逐属性建动画，"宽度收拢、配色渐变"同时发生——书里对同一需求给了两种实现，结论一致：高级别 API 胜在简单，低级别 API 胜在精细。这也回答了第 1 节的选型问题：**要"整块换"，用高级别；要"属性各动各的"，下到 Transition。**

## 8. 常见坑

**keyframes 循环用了 spring**：`infiniteRepeatable(spring(...))` 编译报类型错——repeatable 族只接受 `DurationBasedAnimationSpec`（tween/keyframes/snap）。物理动画无法定义"一个周期"。

**`Animatable` 忘了 remember**：`val a = Animatable(0f)` 直接写在函数体里，每次重组新建实例——动画永远从头开始。所有动画状态（Animatable/Transition 引用）都必须 remember。

**`animateValueAsState` 的转换器每次重建**：`typeConverter = TwoWayConverter(...)` 写在函数体里，每次重组新对象，动画缓存失效。转换器声明成顶层 `val`（示例的 `SidePaddingConverter`）。

**手写 1D 转换器取 `.v1`**：`AnimationVector1D` 的取值属性叫 `value` 不叫 `v1`（v1/v2 是 2D 的）——编译器会直接告诉你 `Unresolved reference 'v1'`。

**在重组路径里驱动 Animatable**：`value.animateTo(...)` 写在 Composable 函数体里（不在协程/回调中）——挂起函数没地方跑，动画随重组反复重启。挂起动画只属于 `LaunchedEffect`、`rememberCoroutineScope.launch` 或 `pointerInput`（第 25 章）。

## 9. 实战建议

- 日常动画仍在 `animate*AsState` / `AnimatedVisibility` 停留（第 20 章）；本章的 API 只在"多属性联动、精确控制、自定义插值"三类需求出现时上
- 交互类动画优先 spring（打断不打闪），展示类/进度类用 tween 对齐设计时长——这条默认约定能省掉大多数 spec 讨论
- 动画 label（`label = "xxx"`）不是装饰：Android Studio 的动画预览工具靠它识别曲线，都写上
- 复杂状态切换先建"状态 → UI 参数"的 enum/data class 表（动效 6），再对表逐属性建动画——表驱动比 if/else 散落各处好维护
- 改完跑 `.\build.ps1 -Compose` 验证编译；本章只用了已在依赖树里的 animation 库，零新增依赖

---

上一章：[23 Compose 自定义布局与绘制](23-compose-layout-draw.md) ｜ 下一章：[25 Compose 手势处理](25-compose-gestures.md) ｜ 返回：[README](../README.md)
