package guide.android.compose.samples

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.FirstBaseline
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// 渲染1：Modifier.layout——定制“测量后的宽高”与“内容在新宽高里的落点”
// 经典案例：文字基线距顶部 24dp（padding 只能定“顶边”到顶部的距离，做不到基线语义）
private fun Modifier.firstBaselineToTop(firstBaselineToTop: Dp) = layout { measurable, constraints ->
    // 每个节点只允许测量一次：measurable.measure() 只能调一次
    val placeable = measurable.measure(constraints)
    val baseline = placeable[FirstBaseline]
    val topPaddingPx = firstBaselineToTop.roundToPx() - baseline
    // 修饰后节点的高度 = 原高度 + 顶部补出的距离（负值则不补）
    layout(placeable.width, placeable.height + topPaddingPx.coerceAtLeast(0)) {
        // placeRelative 自动适配 RTL 布局方向
        placeable.placeRelative(0, topPaddingPx)
    }
}

@Composable
fun LayoutBaselineSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染1：Modifier.layout 基线语义", fontWeight = FontWeight.Bold)
        Text(
            text = "基线距顶部 24dp（firstBaselineToTop）",
            modifier = Modifier
                .firstBaselineToTop(24.dp)
                .background(Color(0xFFE8F5E9))
                .padding(horizontal = 4.dp)
        )
        Text(
            text = "对照：padding(top = 24.dp) 是顶边距 24dp",
            modifier = Modifier
                .padding(top = 24.dp)
                .background(Color(0xFFFCE4EC))
                .padding(horizontal = 4.dp)
        )
    }
}

// 渲染2：Layout Composable——自定义“ViewGroup”：一个 12dp 间距的纵向堆叠容器
@Composable
fun MySpacedColumn(
    modifier: Modifier = Modifier,
    spacing: Dp = 12.dp,
    content: @Composable () -> Unit
) {
    Layout(content = content, modifier = modifier) { measurables, constraints ->
        val spacingPx = spacing.roundToPx()
        // 每个子节点测量一次（无额外限制，直接透传父约束）
        val placeables = measurables.map { it.measure(constraints) }
        val contentHeight = placeables.sumOf { it.height } + spacingPx * (placeables.size - 1).coerceAtLeast(0)
        val height = contentHeight.coerceIn(constraints.minHeight, constraints.maxHeight)
        val width = placeables.maxOfOrNull { it.width }?.coerceIn(constraints.minWidth, constraints.maxWidth)
            ?: constraints.minWidth
        layout(width, height) {
            var y = 0
            placeables.forEach { placeable ->
                placeable.placeRelative(0, y)
                y += placeable.height + spacingPx
            }
        }
    }
}

@Composable
fun LayoutCustomColumnSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染2：Layout 自定义容器（间距 12dp 的 Column）", fontWeight = FontWeight.Bold)
        MySpacedColumn(modifier = Modifier.padding(top = 4.dp)) {
            Text("第一个子节点")
            Text("第二个子节点")
            Text("第三个子节点")
        }
    }
}

// 渲染3：IntrinsicSize——先“预知”子节点尺寸再决定自身尺寸（分割线与文案等高）
@Composable
fun LayoutIntrinsicSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染3：IntrinsicSize.Min 分割线等高", fontWeight = FontWeight.Bold)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
                .padding(top = 4.dp)
        ) {
            Text(
                text = "左边一段\n两行的文案",
                modifier = Modifier.padding(end = 8.dp)
            )
            HorizontalDivider(
                modifier = Modifier
                    .width(4.dp)
                    .fillMaxHeight()
            )
            Text(
                text = "右边一段比较长的文案：分割线高度由两侧文案的固有高度决定",
                modifier = Modifier.padding(start = 8.dp)
            )
        }
        Text(
            text = "去掉 height(IntrinsicSize.Min)，分割线就塌成 0 高",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 渲染4：Canvas Composable——单元绘制组件：圆环进度条
@Composable
fun DrawCanvasSample() {
    var progress by remember { mutableFloatStateOf(0.7f) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染4：Canvas 圆环进度（${(progress * 100).toInt()}%）", fontWeight = FontWeight.Bold)
        Canvas(modifier = Modifier.fillMaxWidth().height(72.dp).padding(top = 4.dp)) {
            val stroke = 10.dp.toPx()
            val diameter = minOf(size.width, size.height) - stroke
            val topLeft = Offset((size.width - diameter) / 2f, (size.height - diameter) / 2f)
            // 底环
            drawArc(
                color = Color(0xFFE0E0E0),
                startAngle = 270f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = Size(diameter, diameter),
                style = Stroke(width = stroke, cap = StrokeCap.Butt)
            )
            // 进度弧：startAngle 270° 从顶部起，顺时针扫过 progress 比例
            drawArc(
                color = Color(0xFF43A047),
                startAngle = 270f,
                sweepAngle = 360f * progress,
                useCenter = false,
                topLeft = topLeft,
                size = Size(diameter, diameter),
                style = Stroke(width = stroke, cap = StrokeCap.Round)
            )
        }
        Slider(
            value = progress,
            onValueChange = { progress = it },
            modifier = Modifier.fillMaxWidth()
        )
    }
}

// 渲染5：DrawModifier 三兄弟——drawWithContent / drawBehind 的图层顺序
@Composable
fun DrawLayerSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染5：drawWithContent 与 drawBehind", fontWeight = FontWeight.Bold)
        Text(
            text = "先描边再 drawContent()：边框在内容下层",
            color = Color(0xFF43A047),
            modifier = Modifier
                .padding(top = 6.dp)
                .drawWithContent {
                    drawRect(Color(0xFFA5D6A7), style = Stroke(width = 3.dp.toPx()))
                    drawContent()
                }
                .padding(horizontal = 8.dp, vertical = 4.dp)
        )
        Text(
            text = "先 drawContent() 再描边：边框盖在内容上层",
            color = Color(0xFFE53935),
            modifier = Modifier
                .padding(top = 8.dp)
                .drawWithContent {
                    drawContent()
                    drawRect(Color(0xFFEF9A9A), style = Stroke(width = 3.dp.toPx()))
                }
                .padding(horizontal = 8.dp, vertical = 4.dp)
        )
        Text(
            text = "drawBehind 黄色荧光底",
            modifier = Modifier
                .padding(top = 8.dp)
                .drawBehind {
                    drawRect(Color(0xFFFFF59D))
                }
                .padding(horizontal = 8.dp, vertical = 4.dp)
        )
        Text(
            text = "drawBehind ≡ drawWithContent { 画东西(); drawContent() }：两种写法效果相同",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 渲染6：drawWithCache——把 Path/画笔等重对象缓存进绘制阶段，尺寸不变就不重建
@Composable
fun DrawCacheSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("渲染6：drawWithCache 缓存网格", fontWeight = FontWeight.Bold)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(80.dp)
                .padding(top = 4.dp)
                .drawWithCache {
                    // CacheDrawScope：这里只在尺寸等输入变化时重新执行
                    val step = 18.dp.toPx()
                    val grid = Path()
                    var x = 0f
                    while (x <= size.width) {
                        grid.moveTo(x, 0f)
                        grid.lineTo(x, size.height)
                        x += step
                    }
                    var y = 0f
                    while (y <= size.height) {
                        grid.moveTo(0f, y)
                        grid.lineTo(size.width, y)
                        y += step
                    }
                    // 返回 onDrawBehind / onDrawWithContent 之一：每帧绘制时复用上面的 grid
                    onDrawBehind {
                        drawPath(grid, color = Color(0xFF90CAF9), style = Stroke(width = 1.dp.toPx()))
                    }
                }
        )
        Text(
            text = "网格 Path 只构建一次；反复重绘（如同叠加动画）不再重建对象",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}
