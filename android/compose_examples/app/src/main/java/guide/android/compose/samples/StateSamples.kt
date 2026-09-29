package guide.android.compose.samples

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

// 状态1：remember vs rememberSaveable——重组、配置变更两道坎
@Composable
fun StateSaveableSample() {
    var plain by remember { mutableIntStateOf(0) }
    var saved by rememberSaveable { mutableIntStateOf(0) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态1：remember vs rememberSaveable", fontWeight = FontWeight.Bold)
        Text(
            text = "plain = $plain（点击 +1，旋转屏幕后归零）",
            modifier = Modifier
                .fillMaxWidth()
                .clickable { plain += 1 }
                .padding(top = 4.dp)
        )
        Text(
            text = "saved = $saved（点击 +1，旋转屏幕后保留）",
            modifier = Modifier
                .fillMaxWidth()
                .clickable { saved += 1 }
                .padding(top = 2.dp)
        )
        Text(
            text = "两者都活过重组；只有 rememberSaveable 写进 Bundle，活过配置变更与进程回收",
            color = Color.Gray,
            modifier = Modifier.padding(top = 2.dp)
        )
    }
}

// 状态2：稳定性与跳过——@Stable 注解决定“参数没变”是否可信
// tags 是 List：默认被编译器判为“不稳定”，equals 结果不可信，无法跳过重组
data class UnstableTagList(val tags: List<String>)

// 加 @Stable 后向编译器承诺运行时不变，equals 恢复可信，相等即可跳过
@Stable
data class StableTagList(val tags: List<String>)

// 渲染计数器：普通数组而非 mutableStateOf——计数本身不能触发重组，否则会自激震荡
// （参数类型决定命运：不稳定 → 每次父级重组都执行；稳定且 equals 相等 → 被跳过）
@Composable
private fun UnstableTagRow(item: UnstableTagList) {
    val renders = remember { intArrayOf(0) }.also { it[0]++ }
    Text(
        text = "不稳定参数（List 字段）：渲染 ${renders[0]} 次（equals 不可信，每次都执行）",
        modifier = Modifier.padding(top = 2.dp)
    )
}

@Composable
private fun StableTagRow(item: StableTagList) {
    val renders = remember { intArrayOf(0) }.also { it[0]++ }
    Text(
        text = "@Stable 参数：渲染 ${renders[0]} 次（equals 相等即被跳过）",
        modifier = Modifier.padding(top = 2.dp)
    )
}

@Composable
fun StateStabilitySample() {
    // tick 状态每 600ms 变一次，驱动本函数反复重组，向两个子组件反复传参
    var tick by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(600)
            tick += 1
        }
    }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态2：稳定性与跳过（tick = $tick）", fontWeight = FontWeight.Bold)
        // 每次重组都新建实例，但 data class 内容相等（equals 为真）
        UnstableTagRow(UnstableTagList(listOf("a", "b")))
        StableTagRow(StableTagList(listOf("a", "b")))
        Text(
            text = "同样新建实例、同样 equals 相等：编译器只信任稳定类型的比较结果",
            color = Color.Gray,
            modifier = Modifier.padding(top = 2.dp)
        )
    }
}

// 状态3：key() 手动索引——列表头部插入数据，观察两种写法的重渲染范围
private data class KeyRow(val id: Int, val text: String)

@Composable
private fun KeyRowText(row: KeyRow) {
    val renders = remember { intArrayOf(0) }.also { it[0]++ }
    Text(text = "${row.text}（渲染 ${renders[0]} 次）", modifier = Modifier.padding(vertical = 2.dp))
}

@Composable
fun StateKeySample() {
    var nextId by remember { mutableIntStateOf(100) }
    var rows by remember { mutableStateOf(listOf(KeyRow(1, "初始行 A"), KeyRow(2, "初始行 B"), KeyRow(3, "初始行 C"))) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态3：key() 手动索引", fontWeight = FontWeight.Bold)
        Button(
            onClick = {
                nextId += 1
                rows = listOf(KeyRow(nextId, "新插入行 #$nextId")) + rows
            },
            modifier = Modifier.padding(top = 4.dp)
        ) { Text("在头部插入一行") }
        Text("无 key（按位置对齐，全部重渲染）：", modifier = Modifier.padding(top = 6.dp))
        rows.forEach { row -> KeyRowText(row) }
        Text("有 key（按身份对齐，旧行被跳过）：", modifier = Modifier.padding(top = 6.dp))
        rows.forEach { row ->
            key(row.id) { KeyRowText(row) }
        }
    }
}

// 状态4：derivedStateOf——频繁变化的底层状态，只派生出“变了才通知”的顶层状态
@Composable
fun StateDerivedSample() {
    val listState = rememberLazyListState()
    // firstVisibleItemIndex 在滚动中高频变化；派生成 Boolean 后，只在越過 0 时通知一次
    val awayFromTop by remember { derivedStateOf { listState.firstVisibleItemIndex > 0 } }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态4：derivedStateOf 派生状态", fontWeight = FontWeight.Bold)
        Box(modifier = Modifier.fillMaxWidth().height(120.dp)) {
            LazyColumn(state = listState, modifier = Modifier.fillMaxWidth().height(120.dp)) {
                items((1..30).toList()) { n ->
                    Text(text = "第 $n 行", modifier = Modifier.padding(3.dp))
                }
            }
            // 条件渲染徽标（Box 嵌在 Column 里时 AnimatedVisibility 会被
            // ColumnScope 扩展遮蔽——改用 if，淡入淡出交给第 20 章的动画 API）
            if (awayFromTop) {
                Text(
                    text = "↑ 顶部之上还有内容",
                    color = Color.White,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .background(Color(0xFF5C6BC0), RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
        }
    }
}

// 状态5：snapshotFlow——在副作用协程里轻量观察状态变化
@Composable
fun StateSnapshotFlowSample() {
    val listState = rememberLazyListState()
    var currentIndex by remember { mutableIntStateOf(0) }
    var events by remember { mutableIntStateOf(0) }
    LaunchedEffect(listState) {
        snapshotFlow { listState.firstVisibleItemIndex }
            .collect { index ->
                currentIndex = index
                events += 1
            }
    }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态5：snapshotFlow 观察状态", fontWeight = FontWeight.Bold)
        Text(
            text = "首个可见项 = $currentIndex（本次进入组合以来发射了 $events 次，相同值不发射）",
            modifier = Modifier.padding(top = 2.dp)
        )
        LazyColumn(state = listState, modifier = Modifier.fillMaxWidth().height(100.dp).padding(top = 4.dp)) {
            items((1..30).toList()) { n ->
                Text(text = "第 $n 行", modifier = Modifier.padding(3.dp))
            }
        }
    }
}

// 状态6：rememberUpdatedState——长生命周期副作用里始终读到最新的回调
@Composable
private fun CountdownStrip(totalSeconds: Int, onTick: () -> Unit, onDone: () -> Unit) {
    // 直接使用 onTick 参数会把“首组合时传入的那个 lambda”固化进协程；
    // rememberUpdatedState 提供一个每次重组都被刷新的 State 包装
    val currentOnTick by rememberUpdatedState(onTick)
    val currentOnDone by rememberUpdatedState(onDone)
    LaunchedEffect(totalSeconds) {
        repeat(totalSeconds) {
            delay(1000)
            currentOnTick()
        }
        currentOnDone()
    }
}

@Composable
fun StateRememberUpdatedSample() {
    var remain by remember { mutableIntStateOf(5) }
    var finished by remember { mutableStateOf(false) }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 6.dp)
    ) {
        Text("状态6：rememberUpdatedState 倒计时", fontWeight = FontWeight.Bold)
        OutlinedButton(onClick = {
            remain = 5
            finished = false
        }) { Text(if (finished) "重新开始" else "重置") }
    }
    Text(
        text = if (finished) "倒计时结束（回调读到的始终是最新状态）" else "剩余 $remain 秒",
        modifier = Modifier.padding(bottom = 4.dp)
    )
    CountdownStrip(
        totalSeconds = 5,
        onTick = { remain -= 1 },
        onDone = { finished = true }
    )
}

// 状态7：StateHolder 状态容器——多个状态连同逻辑一起搬出 Composable
private class CounterStateHolder(initial: Int = 0) {
    var count by mutableIntStateOf(initial)
        private set
    var step by mutableIntStateOf(1)

    fun increment() {
        count += step
    }

    fun reset() {
        count = 0
    }
}

@Composable
private fun rememberCounterState(): CounterStateHolder = remember { CounterStateHolder() }

@Composable
fun StateHolderSample() {
    val state = rememberCounterState()
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("状态7：StateHolder 状态容器", fontWeight = FontWeight.Bold)
        Text(
            text = "count = ${state.count}（步长 ${state.step}）",
            modifier = Modifier.padding(top = 4.dp),
            fontWeight = FontWeight.Bold
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 4.dp)) {
            Button(onClick = state::increment) { Text("加一步") }
            OutlinedButton(onClick = { state.step = if (state.step == 1) 2 else 1 }) { Text("切换步长") }
            OutlinedButton(onClick = state::reset) { Text("清零") }
        }
        Text(
            text = "rememberCounterState() 是官方推荐的配套写法：容器仍存于组合，UI 函数只剩布局",
            color = Color.Gray,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}
