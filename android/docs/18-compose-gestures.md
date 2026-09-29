# 18 · Compose 手势处理

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/GestureSamples.kt`

点击（`clickable`）之外的手势——拖动、双击长按、双指缩放、锚点吸附、嵌套滚动、惯性滑行——是交互体验的分水岭，也是 Compose 与传统 View 差异最大的领域之一。本章沿"现成 Modifier → 检测器 → 事件流"三层展开：第一层开箱即用，第二层按需组装，第三层（`pointerInput` 协程）是所有上层的地基。

## 1. 手势体系鸟瞰

传统 View 里手势靠回调（`onTouchEvent`）与拦截（`onInterceptTouchEvent`）解决；Compose 把手势监听做进了**协程**——`pointerInput` 的 block 是一个 suspend 作用域，事件以挂起函数的方式被"等待"，取代了回调监听。三层结构：

| 层 | API | 一句话 |
|---|---|---|
| 高层 Modifier | `clickable`、`combinedClickable`、`draggable`、`scrollable`、`transformable`、`anchoredDraggable`、`nestedScroll` | 单一手势，声明即得 |
| 检测器 | `detectTapGestures`、`detectDragGestures`、`detectTransformGestures`（都在 `pointerInput { }` 里调用） | 细粒度回调，自由组合 |
| 事件流 | `awaitPointerEvent` / `awaitFirstDown` / `drag` … | 完全自定义：事件分发、消费、速度追踪 |

事件到达路径与传统体系同构：输入系统 → 窗口 → LayoutNode 树自上而下分发。事件分三个阶段投递（Initial 自上而下 / Main 自下而上 / Final 自上而下），分别对应 View 体系的 `onInterceptTouchEvent`、`onTouchEvent` 与"事后知情"——大多数需求停在前两层，不需要碰分发细节。

Modifier 链序惯例：**手势 Modifier 放链尾**（第 12 章第 6 节的洋葱模型——放外层会扩大响应区或吃到不该吃的位移）。

## 2. detectTapGestures：单击/双击/长按

`clickable` 只给 `onClick`，还自带涟漪蒙层。要区分三种点击且控制视觉，用 `pointerInput + detectTapGestures`。`GestureTapSample`（手势1）：

```kotlin
Box(modifier = Modifier
    .background(Color(0xFFE3F2FD), RoundedCornerShape(8.dp))
    .pointerInput(Unit) {
        detectTapGestures(
            onTap = { status = "单击 ✓" },
            onDoubleTap = { status = "双击 ✓" },
            onLongPress = { status = "长按 ✓" }   // 约 400ms 判定
        )
    })
```

回调时序值得记：`onPress` 最先（手指按下即触发）；双击必先经历两次 press；`onTap` 与 `onDoubleTap` 互斥——设了双击监听后，单击要等双击窗口超时才确认，这是手感变"钝半拍"的原因。参数 `Unit` 是 `pointerInput` 的 key：重组时 key 不变，监听协程不重启（把会变的对象当 key，手势会被无谓打断）。

补一个同层替代：`combinedClickable`（Modifier 层）也能要双击/长按，且保留涟漪——要"原生手感"用它，要"完全自定义"用检测器。

## 3. detectDragGestures：任意方向拖动

`draggable` 修饰符只监听**单轴**偏移；任意方向拖动用 `detectDragGestures`。`GestureDragSample`（手势2）：

```kotlin
Box(modifier = Modifier
    .clipToBounds()
    .background(Color(0xFFF5F5F5), RoundedCornerShape(8.dp))
    .pointerInput(Unit) {
        detectDragGestures { change, dragAmount ->
            change.consume()
            offset = Offset(
                (offset.x + dragAmount.x).coerceIn(0f, size.width - 40.dp.toPx()),
                (offset.y + dragAmount.y).coerceIn(0f, size.height - 40.dp.toPx()))
        }
    })
```

三个细节：`dragAmount` 是**本次增量**不是累计值（自己累加）；`change.consume()` 标记消费，防止父容器二次处理（本例父级是滚动容器，不消费就"既拖球又滚页"）；`size` 与 `dp.toPx()` 在 `PointerInputScope` 里可用（它实现了 Density），边界钳制就地完成。同族还有 `detectDragGesturesAfterLongPress`（长按后拖动，如列表重排序）、`detectHorizontal/VerticalDragGestures`（单轴版）。

## 4. transformable：双指缩放/旋转/平移

看图、看地图类界面要同时处理三组双指手势。`transformable` 一个 Modifier 打包三者。`GestureTransformSample`（手势3）：

```kotlin
val state = rememberTransformableState { zoomChange, panChange, rotationChange ->
    scale = (scale * zoomChange).coerceIn(0.5f, 3f)   // zoomChange 是倍率（1.05 = 放大 5%）
    rotation += rotationChange                        // 角度增量
    offset += panChange                               // 平移增量
}
Box(modifier = Modifier.transformable(state)) { ... }
```

状态更新后用 `graphicsLayer`（scaleX/rotationZ/translationX）施加——**图形层变换不触发布局**，比 `size()/rotate()` 修饰符省一整次测量摆放（第 16 章重排优化的直接应用）。`lockRotationOnZoomPan` 参数可在缩放/平移时锁定旋转，避免手抖误转。

## 5. anchoredDraggable：锚点吸附

开关、抽屉、滑块分档——松手后自动吸附到最近的"档位"。老教材里的 `swipeable` 已废弃，现代 API 是 `anchoredDraggable`。`GestureAnchoredDragSample`（手势4）：

```kotlin
val state = remember {
    AnchoredDraggableState(
        initialValue = AnchorPos.Closed,
        positionalThreshold = { totalDistance -> totalDistance * 0.5f },  // 拖过一半吸附
        velocityThreshold = { with(density) { 125.dp.toPx() } },          // 快甩也吸附
        snapAnimationSpec = tween(), decayAnimationSpec = exponentialDecay())
}
SideEffect {
    state.updateAnchors(DraggableAnchors {         // 锚点表：状态 → 像素位置
        AnchorPos.Closed at 0f
        AnchorPos.Open at trackWidthPx - knobPx
    })
}
Box(modifier = Modifier.anchoredDraggable(state, Orientation.Horizontal)) {
    Box(modifier = Modifier.offset { IntOffset(state.offset.roundToInt(), 0) } ...)
}
```

要点四条：锚点是"状态 → 位置"的映射（`状态 at 像素`），要拿到像素尺寸后经 `updateAnchors` 注册（示例用 `SideEffect` 在首帧注册）；滑块位置直接读 `state.offset`；`positionalThreshold` 决定"拖多远算过档"（返回两锚点距离的比例）；该 API 目前标注 `@ExperimentalFoundationApi`，需 `@OptIn` 声明。本工程用的 1.7.8 以构造函数 + `remember` 创建（1.8 才有 `rememberAnchoredDraggableState` 工厂）。

## 6. nestedScroll：父子分账

嵌套滚动的本质是**滚动量的分账**：子列表滚不动了（到顶），剩下的手势给谁？第 12 章的崩溃警告（verticalScroll 嵌 LazyColumn）是约束问题；这里处理的是**协商**问题。`NestedScrollConnection` 四个回调按顺序参与：

| 回调 | 时机 | 典型用途 |
|---|---|---|
| `onPreScroll` | 子级滚动**前** | 父级先扣一块（吸顶、收回指示器） |
| 子级消费 | —— | 列表自己滚 |
| `onPostScroll` | 子级滚完**后**（剩余量） | 子级到顶后父级接手（拉出指示器） |
| `onPreFling` / `onPostFling` | 松手惯性滑动前/后 | 吸附判定、速度接力 |

`GestureNestedScrollSample`（手势5）用这套协议手写了下拉刷新的最小实现：

```kotlin
override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
    val delta = available.y
    if (delta < 0 && indicatorHeightPx > 0f) {          // 上滑且指示器展开：先收回
        val prev = indicatorHeightPx
        indicatorHeightPx = (indicatorHeightPx + delta).coerceIn(0f, maxIndicatorPx)
        return Offset(0f, indicatorHeightPx - prev)     // 返回消费掉的部分
    }
    return Offset.Zero                                  // 不消费：手势交给列表
}
override fun onPostScroll(consumed: Offset, available: Offset, ...): Offset {
    val delta = available.y
    if (delta > 0 && !refreshing) {                     // 列表已到顶、剩余下滑量：拉出指示器
        ...
    }
    return Offset.Zero
}
```

返回值就是"分账单"：返回 `Offset.Zero` 表示分文不取，返回多少表示消费多少。Material3 的 `PullToRefresh`、顶部渐隐图（collapse toolbar）都是这套协议的封装——理解了最小实现，那些组件的行为就不再是魔法。

## 7. 手势 + 动画：Fling 惯性滑行

松手后按出指速度继续滑行并衰减——这是手势与动画（第 17 章）的合流点，也是 `Animatable.animateDecay` 的主场。`GestureFlingSample`（手势6）三步：

```kotlin
// ① 拖动期：位移即时跟随，同时把每帧位置喂给速度追踪器
onDrag = { change, amount ->
    change.consume()
    tracker.addPosition(change.uptimeMillis, change.position)   // VelocityTracker
    offset += amount.x
},
// ② 松手：算出瞬时速度
onDragEnd = {
    val velocity = tracker.calculateVelocity().x
    tracker.resetTracking()
    // ③ 衰减动画：从当前速度指数衰减到 0，每帧写回偏移
    scope.launch {
        flingAnim.snapTo(offset)
        flingAnim.animateDecay(velocity, decaySpec) { offset = value }
    }
}
```

`rememberSplineBasedDecay()` 返回平台调优的衰减曲线（内部与系统滚动一致的贝塞尔拟合）。"拖动跟手 + 松手惯性"这一整套，正是 `scrollable`/LazyColumn 滚动手感的全部秘密——第 3 层 API 的能力可见一斑。

## 8. 常见坑

**pointerInput 的 key 用了会变的状态**：`pointerInput(offset) { detectDragGestures { offset += ... } }`——offset 每变一次监听协程重启，拖动会莫名"断触"。检测器内部不需要外部状态时 key 固定传 `Unit`；确实要按参数重启（如换监听目标）才传它。

**忘 consume 与父级抢手势**：拖动小球不 `change.consume()`，外层 `verticalScroll` 同时响应——球动页也动。消费标记是嵌套手势的沟通语言，Main 阶段先拿到事件的组件消费后，父级在 Final 阶段看到的位置增量已是 0。

**在 onDrag 回调里调挂起函数**：`detectDragGestures` 的回调是普通函数，`animateTo`/`delay` 直接写进去编译报错。协程环境要么 `rememberCoroutineScope`（示例的 onDragEnd）、要么把逻辑搬进 `pointerInput` 协程体本身。

**anchoredDraggable 忘了 updateAnchors**：构造了 state 不注册锚点，`state.offset` 无从谈起，滑块不动。锚点依赖像素尺寸时记得在 `SideEffect`/布局回调里注册（手势 4 的写法）。

**graphicsLayer 与 offset 修饰符混用导致位置错乱**：旋转 + 平移建议全部走 `graphicsLayer` 的 translation/rotation；先 `offset` 再 `rotate` 修饰符会先平移再绕新位置旋转，落点不可预期。

## 9. 实战建议

- 手势选型先高层后底层：单击用 `clickable`/`combinedClickable`，单轴拖/滚用 `draggable`/`scrollable`，双指用 `transformable`，档位吸附用 `anchoredDraggable`；都不满足才写检测器，事件分发层几乎永远不用手写
- 触摸目标 ≥ 48dp、手势区域与视觉边界对齐（配合 `clipToBounds` 防溢出）——可用性基础先于炫技
- 拖动跟手的状态更新走 `offset { }` lambda / `graphicsLayer`（只重排/重绘不重组，第 15/16 章的性能结论在此兑现）
- 本机验证手势示例需要触摸屏或模拟器双指手势；`.\build.ps1 -Compose` 保证的是 API 正确性
- 手势 + 动画合流时记住分工：手势负责"改目标与速度"，动画 API 负责"怎么过去"

---

上一章：[17 Compose 动画进阶](17-compose-animation.md) ｜ 下一章：[19 Compose 依赖注入与生态](19-compose-di-ecosystem.md) ｜ 返回：[README](../README.md)
