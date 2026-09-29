# 16 · Compose 自定义布局与绘制

> 对应示例：`compose_examples/app/src/main/java/guide/android/compose/samples/LayoutDrawSamples.kt`

第 12、20 章的界面全部由现成组件搭成。当设计稿超出组件库的表达力（文字基线对齐、等高分割线、圆环进度、网格背景），就要下到 Compose 渲染管线的后两个阶段——**布局**与**绘制**——自己动手。本章先讲清"组合 / 布局 / 绘制"三阶段模型，再沿"Modifier.layout → Layout 组件 → Intrinsic → Canvas → DrawModifier"的阶梯逐层放权：每一层都只在上一层不满足时才动用。

## 1. 三阶段：组合、布局、绘制

每次界面更新经过三个阶段：

| 阶段 | 做什么 | 输入 → 输出 | 对应传统 View |
|---|---|---|---|
| 组合（Composition） | 执行 Composable，构建/更新节点树 | 状态 → LayoutNode 树 | `setContentView` + 手动增删 View |
| 布局（Layout） | 测量每个节点宽高并摆放 | 约束 → 尺寸与位置 | `onMeasure` + `onLayout` |
| 绘制（Draw） | 把节点画上屏幕 | 尺寸 → 像素 | `onDraw` |

组合阶段就是"重组"（第 22 章）；本章定制后两个。布局阶段的核心规则只有一条：

**每个节点只允许被测量一次，再次测量直接抛异常。**

这不是偷懒，是防指数爆炸：若允许测两次，子测两次、孙就测四次，测量次数随树的深度 2ⁿ 增长。Compose 在框架层掐死了这条路；确实需要"先知道子级尺寸再决定怎么测它"的场景，用 Intrinsic（第 4 节）或 SubcomposeLayout 这两个受控出口。

**约束（Constraints）**是布局的语言：父节点给子节点一组 `minWidth/maxWidth/minHeight/maxHeight`。maxWidth == minWidth 意味着"宽度必须是这个值"；`verticalScroll` 的容器给子级的高度约束是无限大（`maxHeight = ∞`）——第 19 章第 8 节"LazyColumn 不给定高就崩"的根源就在这：LazyColumn 需要有限 maxHeight 才能算出"可见区"。

在 Modifier 或 Layout 里**读了可变状态**，状态变化会跳过组合、直接触发重排（relayout）；尺寸位置没变则连绘制都不用重跑。这是性能优化的一个正规出口：动画位移写在 `offset { }` lambda 里就只重排不重组（第 25 章手势大量用到）。

## 2. Modifier.layout：改一个节点的测量与摆放

`Modifier.layout` 是最轻量的布局定制：包住**单个节点**，重新决定"修饰后的宽高"和"原内容在新边界里的落点"。经典案例——"文字**基线**距顶部 24dp"，`padding(top = 24.dp)` 只能定"顶边"到顶部的距离，基线语义做不到：`LayoutBaselineSample`（渲染1）：

```kotlin
private fun Modifier.firstBaselineToTop(firstBaselineToTop: Dp) = layout { measurable, constraints ->
    // 每个节点只允许测量一次：measurable.measure() 只能调一次
    val placeable = measurable.measure(constraints)
    val baseline = placeable[FirstBaseline]           // 查询被修饰内容的基线位置
    val topPaddingPx = firstBaselineToTop.roundToPx() - baseline
    layout(placeable.width, placeable.height + topPaddingPx.coerceAtLeast(0)) {
        placeable.placeRelative(0, topPaddingPx)       // placeRelative 自动适配 RTL
    }
}

Text("基线距顶部 24dp", modifier = Modifier.firstBaselineToTop(24.dp)...)
```

回调里的两位参数：`measurable` 是被修饰内容的**测量句柄**（measure 一次得 Placeable），`constraints` 是父级给的约束。`layout(w, h) { }` 上报修饰后节点的尺寸，块内 `placeRelative(x, y)` 摆放原内容。官方的 `padding`、`size` 本质都是这么实现的——所谓"自定义 Modifier"多数就是 `composed`/`layout` 包一段这样的逻辑。

## 3. Layout 组件：自定义"ViewGroup"

`Modifier.layout` 只管一个节点；要管理**一批子节点**（自定义容器），用 `Layout` composable——它是 Row/Column/Box 共同的底座。`LayoutCustomColumnSample`（渲染2）实现一个固定间距的纵向堆叠 `MySpacedColumn`：

```kotlin
@Composable
fun MySpacedColumn(modifier: Modifier = Modifier, spacing: Dp = 12.dp,
                   content: @Composable () -> Unit) {
    Layout(content = content, modifier = modifier) { measurables, constraints ->
        val spacingPx = spacing.roundToPx()
        val placeables = measurables.map { it.measure(constraints) }   // 每个子节点测一次
        val height = (placeables.sumOf { it.height } + spacingPx * (placeables.size - 1))
            .coerceIn(constraints.minHeight, constraints.maxHeight)
        val width = placeables.maxOf { it.width }.coerceIn(constraints.minWidth, constraints.maxWidth)
        layout(width, height) {
            var y = 0
            placeables.forEach {
                it.placeRelative(0, y)
                y += it.height + spacingPx
            }
        }
    }
}
```

与第 2 节的差别只在规模：`measurables` 是子节点们的测量句柄 List；测量策略（measurePolicy）遍历、汇总、摆放。把中间两行换成"取最大 x 之和、按权重分"就手写出了 Row；官方布局组件与它同构。第 19 章的布局三件套从此不再是黑盒。

## 4. Intrinsic：先问尺寸，再定约束

"测量只许一次"挡住了一类需求：分割线要与两侧**文字中最高的那行**等高——Row 得先知道子级多高，才能把高度约束成确定值传给分割线。固有特性测量（Intrinsic measurement）就是这条受控通道：允许父级**预先询问**子级的固有尺寸，再用问到的值参与正式测量。

内置组件大多已适配，普通场景一行 Modifier 就能用——`LayoutIntrinsicSample`（渲染3）：

```kotlin
Row(modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
    Text("左边一段\n两行的文案")
    HorizontalDivider(modifier = Modifier.width(4.dp).fillMaxHeight())  // 撑满行高
    Text("右边一段比较长的文案…")
}
```

`height(IntrinsicSize.Min)` 的含义：高度取"按子级固有尺寸算出的最小值"——两段文字的固有高度的最大者。之后 `fillMaxHeight()` 的分割线才有高度可撑。去掉这行，分割线塌成 0 高。

自己写 Layout 组件要适配 Intrinsic 时，在 MeasurePolicy 里额外重写 `minIntrinsicHeight` 等四个方法（未重写却在父级被问及时会崩溃）；SubcomposeLayout 则能"先组合测量一部分、再组合其余"，能力更强但每个子组合都要建子 Composition，性能不如常规 Layout——需要时再查官方文档，心智模型本章已备齐。

## 5. Canvas：单元绘制组件

绘制阶段的标准入口是 `Canvas` composable：一个**不能有子级**的纯绘制画布（传统 View 里自绘 View 的对应物），两个参数——modifier 与 DrawScope lambda。DrawScope 提供基础绘制 API：

| API | 画什么 |
|---|---|
| `drawLine / drawRect / drawCircle / drawArc / drawOval` | 几何图形 |
| `drawPath` | 任意路径（曲线、自定义形状） |
| `drawImage` | 位图 |
| `rotate / translate / scale / withTransform` | 画布变换（嵌套生效） |

`DrawCanvasSample`（渲染4）画一支可调的圆环进度：

```kotlin
Canvas(modifier = Modifier.fillMaxWidth().height(72.dp)) {
    val stroke = 10.dp.toPx()
    val diameter = minOf(size.width, size.height) - stroke
    // 底环：Stroke 空心描边；startAngle 270° 从 12 点方向起
    drawArc(Color(0xFFE0E0E0), 270f, 360f, useCenter = false,
        topLeft = topLeft, size = Size(diameter, diameter),
        style = Stroke(width = stroke, cap = StrokeCap.Butt))
    // 进度弧：cap = Round 端点圆润
    drawArc(Color(0xFF43A047), 270f, 360f * progress, useCenter = false, ...)
}
```

三个细节：角度以 3 点钟方向为 0°、顺时针为正（顶部是 270°）；`useCenter = false` 画弧不连圆心（连了就是扇形）；`Stroke` 是描边画笔、默认 `Fill` 是实心。`size`（画布尺寸）与 `dp.toPx()`（密度换算）都在 DrawScope 里现成可用。

DrawScope 是对平台 Canvas 的封装；真要用它没暴露的能力（如直接 `drawText`），`drawContext.canvas.nativeCanvas` 拿到 Android 原生 `android.graphics.Canvas` 继续画——代价是丢失跨平台性。

## 6. DrawModifier 三兄弟：drawBehind / drawWithContent / drawWithCache

给**已有组件**加工绘制，不必上 Canvas——三个 DrawModifier 直接挂在 Modifier 链上。核心概念是**绘制层级**：后画的盖在先画的上面，`drawContent()` 表示"组件自身内容"这个图层。

**`drawWithContent`**：自定义内容与组件内容的相对层级。`DrawLayerSample`（渲染5）演示两种顺序：

```kotlin
Text("先描边再 drawContent：边框在下层", modifier = Modifier.drawWithContent {
    drawRect(Color(0xFFA5D6A7), style = Stroke(3.dp.toPx()))
    drawContent()                       // 内容后画 → 盖住描边
})
Text("先 drawContent 再描边：边框在上层", modifier = Modifier.drawWithContent {
    drawContent()                       // 内容先画 → 被描边盖住
    drawRect(Color(0xFFEF9A9A), style = Stroke(3.dp.toPx()))
})
```

这与传统 View 重写 `onDraw` 时调 `super.onDraw()` 的时机语义完全相通。

**`drawBehind`**：`drawWithContent { 画东西(); drawContent() }` 的语法糖——画的东西永远垫底，即"自定义背景"。示例里的荧光底文字就是它。

**`drawWithCache`**：把 Path、Paint、ImageBitmap 这类**重对象**缓存进绘制阶段。DrawScope 每次重绘都会重新执行，里面 new 的对象也跟着重建——动画场景（每帧重绘）会制造内存抖动。`DrawCacheSample`（渲染6）：

```kotlin
Modifier.drawWithCache {
    // 只在尺寸等输入变化时重建
    val grid = Path()
    var x = 0f
    while (x <= size.width) { grid.moveTo(x, 0f); grid.lineTo(x, size.height); x += 18.dp.toPx() }
    var y = 0f
    while (y <= size.height) { grid.moveTo(0f, y); grid.lineTo(size.width, y); y += 18.dp.toPx() }
    onDrawBehind { drawPath(grid, Color(0xFF90CAF9), style = Stroke(1.dp.toPx())) }
}
```

缓存块返回 `onDrawBehind` / `onDrawWithContent` 之一作为每帧的绘制回调。对象跟着绘制而非组合生命周期走（对比 `remember` 缓存），不污染全局、不越界。

顺带揭一层底：`Canvas` 组件本身就是个 `Spacer + drawBehind`——第 5 节与第 6 节是同一套绘制体系的两个门。

## 7. 常见坑

**测量了两次**：在 layout/MeasurePolicy 里对同一个 `measurable` 调了两次 `measure()`——运行期直接抛 `IllegalStateException`。要"先问再测"用 Intrinsic 或 SubcomposeLayout，不要硬来。

**修改 constraints 却忘了 clamp**：自定义容器把子级测量结果直接 `layout(w, h)` 上报，w/h 超出父给的约束范围（比如大于 maxWidth）——子级被裁或父级崩溃。汇总尺寸务必 `coerceIn(constraints.minX, constraints.maxX)`（渲染2 的写法）。

**Intrinsic 用在未适配的组件上**：给自写 Layout 没重写 Intrinsic 方法，外层却用了 `height(IntrinsicSize.Min)`——问询时崩溃。自写容器要么四个 Intrinsic 方法全给，要么文档里声明不支持。

**drawBehind 里忘了内容会被盖**：往文字上画装饰用 `drawBehind`，结果装饰全被文字盖住——drawBehind 永远垫底，画"内容之上"的东西（角标、对勾）用 `drawWithContent { drawContent(); 画东西() }`。

**drawWithCache 里读高频状态**：缓存块里读了动画状态，尺寸没变时缓存不重建、动画却要新值——行为错乱。缓存块只放"只依赖尺寸/密度"的对象，动画值在 `onDrawBehind` 里读。

## 8. 实战建议

- 需求超出组件库时按阶梯下放：**Modifier 拼装 → Modifier.layout → Layout 组件 → Canvas/DrawModifier**，能用上一层就不下探
- 间距、对齐类需求先查 `Arrangement`/`Alignment` 参数与 `paddingFromBaseline` 等现成 Modifier——多数"自定义"其实是"没找对参数"
- 圆环/图表/波形类"自绘图形"用 Canvas；给现成组件加装饰（边框、角标、网格背景）用 DrawModifier；两者不要混用 Canvas 包组件（Canvas 没有子级）
- 动画驱动的绘制（进度、shimmer）把动画值在 onDraw 回调里读——只触发重绘，不惊动组合与布局（连接第 24 章）
- 改完跑 `.\build.ps1 -Compose` 验证编译；本章 API 来自 ui/foundation，零新增依赖

---

上一章：[22 Compose 状态与重组深入](22-compose-state.md) ｜ 下一章：[24 Compose 动画进阶](24-compose-animation.md) ｜ 返回：[README](../README.md)
