package guide.android.compose.samples

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.exponentialDecay
import androidx.compose.animation.core.tween
import androidx.compose.animation.rememberSplineBasedDecay
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.AnchoredDraggableState
import androidx.compose.foundation.gestures.DraggableAnchors
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.anchoredDraggable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.Velocity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

// 手势1：detectTapGestures——单击/双击/长按的细粒度监听（无涟漪蒙层）
@Composable
fun GestureTapSample() {
    var status by remember { mutableStateOf("单击 / 双击 / 长按 试试") }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("手势1：detectTapGestures 细粒度点击", fontWeight = FontWeight.Bold)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp)
                .height(52.dp)
                .background(Color(0xFFE3F2FD), RoundedCornerShape(8.dp))
                .pointerInput(Unit) {
                    detectTapGestures(
                        onDoubleTap = { status = "双击 ✓" },
                        onLongPress = { status = "长按 ✓（约 400ms 判定）" },
                        onTap = { status = "单击 ✓" }
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            Text(status)
        }
        Text(
            text = "pointerInput 的 block 是协程体：所有手势监听都以挂起方式实现，替代了回调监听",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

// 手势2：detectDragGestures——任意方向拖动（draggable 修饰符只能单轴）
@Composable
fun GestureDragSample() {
    var offset by remember { mutableStateOf(Offset.Zero) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("手势2：detectDragGestures 拖动小球", fontWeight = FontWeight.Bold)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp)
                .height(120.dp)
                .clipToBounds()
                .background(Color(0xFFF5F5F5), RoundedCornerShape(8.dp))
                .pointerInput(Unit) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        offset = Offset(
                            (offset.x + dragAmount.x).coerceIn(0f, size.width - 40.dp.toPx()),
                            (offset.y + dragAmount.y).coerceIn(0f, size.height - 40.dp.toPx())
                        )
                    }
                }
        ) {
            Box(
                modifier = Modifier
                    .offset { IntOffset(offset.x.roundToInt(), offset.y.roundToInt()) }
                    .size(40.dp)
                    .background(Color(0xFF42A5F5), CircleShape)
            )
        }
    }
}

// 手势3：transformable——双指缩放 / 旋转 / 平移（触屏演示；模拟器可模拟双指）
@Composable
fun GestureTransformSample() {
    var scale by remember { mutableFloatStateOf(1f) }
    var rotation by remember { mutableFloatStateOf(0f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    val state = rememberTransformableState { zoomChange, panChange, rotationChange ->
        scale = (scale * zoomChange).coerceIn(0.5f, 3f)
        rotation += rotationChange
        offset += panChange
    }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text(
            text = "手势3：transformable 缩放 ${(scale * 100).toInt()}% / 旋转 ${rotation.toInt()}°",
            fontWeight = FontWeight.Bold
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp)
                .height(140.dp)
                .transformable(state),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .graphicsLayer(
                        scaleX = scale,
                        scaleY = scale,
                        rotationZ = rotation,
                        translationX = offset.x,
                        translationY = offset.y
                    )
                    .size(64.dp)
                    .background(Color(0xFF7E57C2), RoundedCornerShape(8.dp))
            )
        }
    }
}

// 手势4：anchoredDraggable——锚点吸附（已废弃 swipeable 的现代替代）
private enum class AnchorPos { Closed, Open }

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun GestureAnchoredDragSample() {
    val density = LocalDensity.current
    val trackWidth = 168.dp
    val knobSize = 40.dp
    val trackWidthPx = with(density) { trackWidth.toPx() }
    val knobPx = with(density) { knobSize.toPx() }

    // 1.7 版用 remember + 构造函数（rememberAnchoredDraggableState 是 1.8 新增）
    val state: AnchoredDraggableState<AnchorPos> = remember {
        AnchoredDraggableState(
            initialValue = AnchorPos.Closed,
            // 拖过两锚点间距离的 50% 就吸附到对面
            positionalThreshold = { totalDistance -> totalDistance * 0.5f },
            velocityThreshold = { with(density) { 125.dp.toPx() } },
            snapAnimationSpec = tween(),
            decayAnimationSpec = exponentialDecay()
        )
    }
    // 锚点表要在拿到像素尺寸后注册：Closed 在 0f，Open 在滑块可移动的终点
    SideEffect {
        state.updateAnchors(
            DraggableAnchors {
                AnchorPos.Closed at 0f
                AnchorPos.Open at trackWidthPx - knobPx
            }
        )
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .width(trackWidth)
                .height(knobSize)
                .background(Color(0xFFE0E0E0), RoundedCornerShape(knobSize / 2))
                .anchoredDraggable(state, Orientation.Horizontal)
        ) {
            Box(
                modifier = Modifier
                    .offset { IntOffset(state.offset.roundToInt(), 0) }
                    .size(knobSize)
                    .background(
                        if (state.targetValue == AnchorPos.Open) Color(0xFF43A047) else Color(0xFF9E9E9E),
                        CircleShape
                    )
            )
        }
        Text(
            text = if (state.targetValue == AnchorPos.Open) "手势4：Open（拖过一半自动吸附）" else "手势4：Closed（拖动试试）",
            modifier = Modifier.padding(start = 12.dp),
            fontWeight = FontWeight.Bold
        )
    }
}

// 手势5：nestedScroll——父组件预消费子列表滚不完的手势（下拉刷新的最小实现）
@Composable
fun GestureNestedScrollSample() {
    val maxIndicatorPx = 96f
    var indicatorHeightPx by remember { mutableFloatStateOf(0f) }
    var refreshing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    val connection = remember {
        object : NestedScrollConnection {
            override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
                val delta = available.y
                // 上滑且指示器仍展开：父级先消费，把指示器收回去，列表不动
                return if (delta < 0 && indicatorHeightPx > 0f) {
                    val prev = indicatorHeightPx
                    indicatorHeightPx = (indicatorHeightPx + delta).coerceIn(0f, maxIndicatorPx)
                    Offset(0f, indicatorHeightPx - prev)
                } else {
                    Offset.Zero
                }
            }

            override fun onPostScroll(
                consumed: Offset,
                available: Offset,
                source: NestedScrollSource
            ): Offset {
                val delta = available.y
                // 下滑且列表已在顶部（剩余手势没人要）：拉出指示器
                return if (delta > 0 && !refreshing) {
                    val prev = indicatorHeightPx
                    indicatorHeightPx = (indicatorHeightPx + delta).coerceIn(0f, maxIndicatorPx)
                    Offset(0f, indicatorHeightPx - prev)
                } else {
                    Offset.Zero
                }
            }

            override suspend fun onPreFling(available: Velocity): Velocity {
                // 松手：拉出过半进入刷新态，否则收回
                if (indicatorHeightPx > maxIndicatorPx / 2 && !refreshing) {
                    refreshing = true
                    indicatorHeightPx = maxIndicatorPx / 2
                    scope.launch {
                        delay(1500)
                        refreshing = false
                        indicatorHeightPx = 0f
                    }
                } else if (!refreshing) {
                    indicatorHeightPx = 0f
                }
                return Velocity.Zero
            }
        }
    }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("手势5：nestedScroll 下拉刷新", fontWeight = FontWeight.Bold)
        Column(
            modifier = Modifier
                .padding(top = 4.dp)
                .fillMaxWidth()
                .nestedScroll(connection)
        ) {
            val indicatorDp = with(LocalDensity.current) { indicatorHeightPx.toDp() }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(indicatorDp),
                contentAlignment = Alignment.Center
            ) {
                if (refreshing) {
                    CircularProgressIndicator(modifier = Modifier.size(22.dp))
                }
            }
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(110.dp)
                    .background(Color(0xFFFAFAFA), RoundedCornerShape(4.dp))
            ) {
                items((1..20).toList()) { n ->
                    Text(text = "列表项 $n（先滚到顶，再往下拉）", modifier = Modifier.padding(4.dp))
                }
            }
        }
    }
}

// 手势6：手势 + 动画——VelocityTracker 追踪速度，松手后按速度衰减滑行（Fling）
@Composable
fun GestureFlingSample() {
    val decaySpec = rememberSplineBasedDecay<Float>()
    var offset by remember { mutableFloatStateOf(0f) }
    val flingAnim = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("手势6：Fling 惯性滑行（快速拖动后松手）", fontWeight = FontWeight.Bold)
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp)
                .height(64.dp)
                .clipToBounds()
                .background(Color(0xFFEDE7F6), RoundedCornerShape(8.dp))
                .pointerInput(Unit) {
                    val tracker = VelocityTracker()
                    detectDragGestures(
                        onDrag = { change, amount ->
                            change.consume()
                            // 松手前的每次移动都喂给速度追踪器
                            tracker.addPosition(change.uptimeMillis, change.position)
                            offset += amount.x
                        },
                        onDragEnd = {
                            val velocity = tracker.calculateVelocity().x
                            tracker.resetTracking()
                            scope.launch {
                                flingAnim.snapTo(offset)
                                // 衰减动画的每一帧把值写回偏移状态，UI 持续重组
                                flingAnim.animateDecay(velocity, decaySpec) {
                                    offset = value
                                }
                            }
                        }
                    )
                }
        ) {
            val maxOffset = with(LocalDensity.current) { (maxWidth - 40.dp).toPx() }
            Box(
                modifier = Modifier
                    .offset { IntOffset(offset.coerceIn(0f, maxOffset).roundToInt(), 12) }
                    .size(40.dp)
                    .background(Color(0xFF7E57C2), CircleShape)
            )
        }
    }
}
