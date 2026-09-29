package guide.android.compose.samples

import androidx.compose.animation.animateColor
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationVector2D
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.TwoWayConverter
import androidx.compose.animation.core.animateDp
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateValueAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.keyframes
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.updateTransition
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

// 动效1：AnimationSpec 四种规格——同一目标值，四种“过渡的性格”
@Composable
fun AnimSpecCompareSample() {
    var big by remember { mutableStateOf(false) }
    val target = if (big) 1f else 0.15f
    val springValue by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
        label = "spring"
    )
    val tweenValue by animateFloatAsState(
        targetValue = target,
        animationSpec = tween(durationMillis = 1200, easing = LinearEasing),
        label = "tween"
    )
    val keyframesValue by animateFloatAsState(
        targetValue = target,
        animationSpec = keyframes {
            durationMillis = 1200
            // 前 700ms 只走到一半，后 500ms 走完——先慢后快的两段节奏
            (target / 2) at 700 using FastOutSlowInEasing
        },
        label = "keyframes"
    )
    val snapValue by animateFloatAsState(targetValue = target, animationSpec = snap(), label = "snap")
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("动效1：AnimationSpec 四种规格", fontWeight = FontWeight.Bold)
        Button(onClick = { big = !big }, modifier = Modifier.padding(top = 4.dp)) {
            Text(if (big) "回到 15%" else "切到 100%")
        }
        LinearProgressIndicator(progress = { springValue }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
        LinearProgressIndicator(progress = { tweenValue }, modifier = Modifier.fillMaxWidth().padding(top = 4.dp))
        LinearProgressIndicator(progress = { keyframesValue }, modifier = Modifier.fillMaxWidth().padding(top = 4.dp))
        LinearProgressIndicator(progress = { snapValue }, modifier = Modifier.fillMaxWidth().padding(top = 4.dp))
        Text(
            text = "自上而下：spring（物理回弹）｜tween（1.2s 线性）｜keyframes（700ms 走半程的两段式）｜snap（瞬间到位）",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 动效2：updateTransition——一个状态变化驱动多个属性同步动画
private enum class ExpandState { Collapsed, Expanded }

@Composable
fun AnimTransitionSample() {
    var expanded by remember { mutableStateOf(ExpandState.Collapsed) }
    val transition = updateTransition(targetState = expanded, label = "expand")
    // 三个子动画共享同一个状态源，同起同止
    val color by transition.animateColor(label = "color") {
        if (it == ExpandState.Expanded) Color(0xFF2E7D32) else Color(0xFF90CAF9)
    }
    val corner by transition.animateDp(label = "corner") {
        if (it == ExpandState.Expanded) 32.dp else 8.dp
    }
    val size by transition.animateDp(label = "size") {
        if (it == ExpandState.Expanded) 96.dp else 48.dp
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.padding(vertical = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(size)
                .background(color, RoundedCornerShape(corner))
                .clickable {
                    expanded = if (expanded == ExpandState.Expanded) ExpandState.Collapsed else ExpandState.Expanded
                }
        )
        Text("动效2：updateTransition 多属性联动（点方块）", fontWeight = FontWeight.Bold)
    }
}

// 动效3：Animatable——手动驱动的动画值：snapTo / animateTo / 中途打断
@Composable
fun AnimManualSample() {
    val value = remember { Animatable(0.2f) }
    val scope = rememberCoroutineScope()
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("动效3：Animatable 手动驱动", fontWeight = FontWeight.Bold)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp)
                .height(12.dp)
                .background(Color(0xFFE0E0E0), RoundedCornerShape(6.dp))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(value.value)
                    .height(12.dp)
                    .background(Color(0xFF43A047), RoundedCornerShape(6.dp))
            )
        }
        Button(
            onClick = {
                scope.launch {
                    // snapTo 立即跳变、animateTo 平滑过渡：手动拼出“闪回起点再缓铺满”的路径
                    value.snapTo(0f)
                    value.animateTo(1f, animationSpec = tween(durationMillis = 1500))
                }
            },
            modifier = Modifier.padding(top = 4.dp)
        ) { Text("闪回 0% → 1.5s 铺满") }
        Text(
            text = "animateTo/snapTo 都是挂起函数，跑在协程里；动画中途再次点击会被新动画打断",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 动效4：TwoWayConverter——为自定义类型插值（两个 Dp 组成的“横纵边距”）
private data class SidePadding(val start: Dp, val end: Dp)

private val SidePaddingConverter = TwoWayConverter(
    convertToVector = { padding: SidePadding -> AnimationVector2D(padding.start.value, padding.end.value) },
    convertFromVector = { vector: AnimationVector2D -> SidePadding(vector.v1.dp, vector.v2.dp) }
)

@Composable
fun AnimCustomTypeSample() {
    var expanded by remember { mutableStateOf(false) }
    val padding by animateValueAsState(
        targetValue = if (expanded) SidePadding(24.dp, 48.dp) else SidePadding(4.dp, 4.dp),
        typeConverter = SidePaddingConverter,
        animationSpec = spring(dampingRatio = Spring.DampingRatioLowBouncy),
        label = "sidePadding"
    )
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("动效4：自定义类型动画（TwoWayConverter）", fontWeight = FontWeight.Bold)
        Text(
            text = "start=${padding.start} / end=${padding.end} 的文字块",
            modifier = Modifier
                .padding(top = 4.dp)
                .background(Color(0xFFE3F2FD))
                .padding(start = padding.start, end = padding.end, top = 4.dp, bottom = 4.dp)
                .clickable { expanded = !expanded }
        )
        Text(
            text = "常用类型（Color/Dp/Float…）的转换器内建了；自定义类型把值拆进 AnimationVector 即可参与动画",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 动效5：骨架屏 shimmer——无限动画驱动渐变笔刷位移
@Composable
private fun ShimmerItem(brush: Brush) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(brush, CircleShape)
        )
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.7f)
                    .height(14.dp)
                    .background(brush, RoundedCornerShape(4.dp))
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.4f)
                    .height(12.dp)
                    .background(brush, RoundedCornerShape(4.dp))
            )
        }
    }
}

@Composable
fun AnimShimmerSample() {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translate by transition.animateFloat(
        initialValue = -200f,
        targetValue = 600f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1300, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "translate"
    )
    // 渐变端点随 translate 移动：微光从左扫到右，循环往复
    val brush = Brush.linearGradient(
        colors = listOf(Color(0xFFEEEEEE), Color(0xFFFAFAFA), Color(0xFFEEEEEE)),
        start = Offset(translate, 0f),
        end = Offset(translate + 200f, 0f)
    )
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("动效5：骨架屏 shimmer", fontWeight = FontWeight.Bold)
        repeat(2) { ShimmerItem(brush) }
    }
}

// 动效6：收藏按钮——enum 建模状态 + updateTransition 逐属性动画（书 6.8 的精简版）
private enum class FavState(val bg: Color, val fg: Color, val corner: Dp, val width: Dp) {
    Idle(Color(0xFFFFE0B2), Color(0xFF5D4037), 28.dp, 140.dp),
    Done(Color(0xFFE53935), Color.White, 28.dp, 56.dp)
}

@Composable
fun AnimFavButtonSample() {
    var state by remember { mutableStateOf(FavState.Idle) }
    val transition = updateTransition(targetState = state, label = "fav")
    val bg by transition.animateColor(label = "bg") { it.bg }
    val fg by transition.animateColor(label = "fg") { it.fg }
    val corner by transition.animateDp(label = "corner") { it.corner }
    val width by transition.animateDp(
        transitionSpec = { tween(300) },
        label = "width"
    ) { it.width }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.padding(vertical = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .width(width)
                .height(48.dp)
                .background(bg, RoundedCornerShape(corner))
                .clickable { state = if (state == FavState.Idle) FavState.Done else FavState.Idle },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = if (state == FavState.Done) "❤" else "收藏",
                color = fg,
                fontWeight = FontWeight.Bold
            )
        }
        Text("动效6：收藏按钮（宽度/配色逐属性过渡）", fontWeight = FontWeight.Bold)
    }
}
