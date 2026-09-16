package guide.android.compose.samples

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun UiButtonsSample() {
    var clicks by remember { mutableIntStateOf(0) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例1：按钮族（累计点击 $clicks 次）", fontWeight = FontWeight.Bold)
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(top = 4.dp)
        ) {
            Button(onClick = { clicks += 1 }) { Text("实心") }
            OutlinedButton(onClick = { clicks += 1 }) { Text("描边") }
            TextButton(onClick = { clicks += 1 }) { Text("文本") }
        }
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(top = 4.dp)
        ) {
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

@Composable
fun UiSelectionSample() {
    var checked by remember { mutableStateOf(true) }
    var option by remember { mutableStateOf("A") }
    var slider by remember { mutableStateOf(0.5f) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例2：选择控件", fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = checked, onCheckedChange = { checked = it })
            Text(if (checked) "已勾选" else "未勾选")
        }
        listOf("A", "B").forEach { opt ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                RadioButton(selected = option == opt, onClick = { option = opt })
                Text("选项 $opt")
            }
        }
        Slider(value = slider, onValueChange = { slider = it })
        Text("滑块进度：${(slider * 100).toInt()}%")
    }
}

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

@Composable
fun UiListKeySample() {
    var nextId by remember { mutableIntStateOf(4) }
    val tasks = remember { mutableStateListOf("买牛奶" to 1, "写周报" to 2, "回邮件" to 3) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例5：列表 key 与增删动画", fontWeight = FontWeight.Bold)
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(top = 4.dp)
        ) {
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
                Text(
                    text = "标签$n",
                    modifier = Modifier.background(Color(0xFFE3F2FD)).padding(6.dp)
                )
            }
        }
    }
}

@Composable
fun UiSideEffectSample() {
    var reloadKey by remember { mutableIntStateOf(0) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(reloadKey) {
        loaded = false
        delay(1200)                       // 模拟一次网络/磁盘加载
        loaded = true
    }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例6：LaunchedEffect 模拟加载", fontWeight = FontWeight.Bold)
        if (!loaded) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(top = 4.dp)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp
                )
                Text("  加载中…", modifier = Modifier.padding(start = 8.dp))
            }
        } else {
            Text("加载完成（第 $reloadKey 次触发）", modifier = Modifier.padding(top = 4.dp))
            OutlinedButton(
                onClick = { reloadKey += 1 },
                modifier = Modifier.padding(top = 4.dp)
            ) { Text("重新加载") }
        }
    }
}

@Composable
fun UiAnimationValueSample() {
    var target by remember { mutableStateOf(0.2f) }
    val springValue by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(dampingRatio = 0.35f),
        label = "spring"
    )
    val tweenValue by animateFloatAsState(
        targetValue = target,
        animationSpec = tween(durationMillis = 1200, easing = LinearEasing),
        label = "tween"
    )
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例7：值动画 spring vs tween", fontWeight = FontWeight.Bold)
        Button(
            onClick = { target = if (target < 0.9f) 1f else 0.2f },
            modifier = Modifier.padding(top = 4.dp)
        ) { Text("切换目标值") }
        LinearProgressIndicator(
            progress = { springValue },
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
        )
        LinearProgressIndicator(
            progress = { tweenValue },
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
        )
        Text("上：spring（弹簧回弹）  下：tween（1.2s 线性）", modifier = Modifier.padding(top = 4.dp))
    }
}

@Composable
fun UiAnimationTransitionSample() {
    var count by remember { mutableIntStateOf(0) }
    var dark by remember { mutableStateOf(false) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例8：AnimatedContent 与 Crossfade", fontWeight = FontWeight.Bold)
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
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 4.dp)) {
            Switch(checked = dark, onCheckedChange = { dark = it })
            Crossfade(targetState = dark, label = "cross") { d ->
                Text(
                    if (d) "深色内容" else "浅色内容",
                    color = if (d) Color(0xFF616161) else Color(0xFF2E7D32),
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }
    }
}

@Composable
fun UiAnimationVisibilitySample() {
    var expanded by remember { mutableStateOf(false) }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("UI 示例9：AnimatedVisibility 与 animateContentSize", fontWeight = FontWeight.Bold)
        Button(
            onClick = { expanded = !expanded },
            modifier = Modifier.padding(top = 4.dp)
        ) { Text(if (expanded) "收起" else "展开") }
        AnimatedVisibility(
            visible = expanded,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Text(
                "被展开的内容：出现与消失由 AnimatedVisibility 负责过渡。",
                modifier = Modifier.padding(top = 4.dp)
            )
        }
        Text(
            text = if (expanded) "长版本：这段文字会随状态变长，容器尺寸由 animateContentSize 自动过渡，不需要手写任何插值。" else "短版本：点击试试",
            modifier = Modifier
                .fillMaxWidth()
                .animateContentSize()
                .background(Color(0xFFF5F5F5))
                .padding(8.dp)
                .clickable { expanded = !expanded }
        )
    }
}

@Composable
fun UiInfinitePulseSample() {
    val transition = rememberInfiniteTransition(label = "pulse")
    val alpha by transition.animateFloat(
        initialValue = 0.2f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(800), repeatMode = RepeatMode.Reverse),
        label = "alpha"
    )
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(18.dp)
                .alpha(alpha)
                .background(MaterialTheme.colorScheme.primary, CircleShape)
        )
        Text("UI 示例10：无限循环动画（加载脉冲）", modifier = Modifier.padding(start = 8.dp))
    }
}

// @Preview：不装进设备，Android Studio 侧栏直接渲染（第 13 章第 8 节）
@Preview(showBackground = true)
@Composable
private fun UiButtonsSamplePreview() {
    UiButtonsSample()
}

@Preview(showBackground = true)
@Composable
private fun UiSelectionSamplePreview() {
    UiSelectionSample()
}
