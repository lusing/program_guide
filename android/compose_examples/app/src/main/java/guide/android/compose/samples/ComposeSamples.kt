package guide.android.compose.samples

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import guide.android.compose.jni.GuideNativeBridge

@Composable
fun ComposeCounterSample() {
    var count by remember { mutableIntStateOf(0) }
    Text(
        text = "Compose 示例1：计数器 = $count",
        modifier = Modifier
            .fillMaxWidth()
            .clickable { count += 1 }
            .padding(vertical = 6.dp),
        fontWeight = FontWeight.Bold
    )
}

@Composable
fun ComposeLazyListSample() {
    val itemsData = remember { (1..5).map { "Compose 列表项 $it" } }
    // 固定高度：MainActivity 外层 Column 带 verticalScroll，高度约束无限，
    // 不给 LazyColumn 定高会在运行期崩溃（详见第 12 章第 8 节）
    LazyColumn(modifier = Modifier.height(120.dp).padding(vertical = 6.dp)) {
        items(itemsData) { item ->
            Text(text = "Compose 示例2：$item", modifier = Modifier.padding(2.dp))
        }
    }
}

@Composable
fun ComposeThemeToggleSample() {
    var dark by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "Compose 示例3：主题切换（${if (dark) "Dark" else "Light"}）",
            color = if (dark) Color.Gray else MaterialTheme.colorScheme.onBackground
        )
        Switch(checked = dark, onCheckedChange = { dark = it })
    }
}

@Composable
fun ComposeFormValidationSample() {
    var input by remember { mutableStateOf("") }
    val isValid = input.length >= 4
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        OutlinedTextField(
            value = input,
            onValueChange = { input = it },
            label = { Text("Compose 示例4：输入至少 4 个字符") }
        )
        Text(
            text = if (isValid) "输入有效" else "输入过短",
            color = if (isValid) Color(0xFF2E7D32) else Color(0xFFC62828)
        )
    }
}

@Composable
fun ComposeCardListSample() {
    val cards = remember { listOf("Kotlin", "Jetpack Compose", "JNI") }
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("Compose 示例5：卡片列表")
        cards.forEach { title ->
            Card(modifier = Modifier.fillMaxWidth().padding(top = 6.dp)) {
                Text(text = title, modifier = Modifier.padding(10.dp))
            }
        }
    }
}

@Composable
fun ComposeLayoutRowSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("Compose 示例6：Row/Column/Box 布局三件套")
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("SpaceBetween")
            Text("两端贴边")
            Text("中间均分")
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("spacedBy(8.dp)")
            Text("间距")
            Text("排开")
        }
        Box(modifier = Modifier.fillMaxWidth().padding(top = 4.dp).height(44.dp)) {
            Text("Box 左上", modifier = Modifier.align(Alignment.TopStart))
            Text("Box 中间", modifier = Modifier.align(Alignment.Center))
            Text("Box 右下", modifier = Modifier.align(Alignment.BottomEnd))
        }
    }
}

@Composable
fun ComposeWeightSample() {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Text("Compose 示例7：weight 按比例分宽")
        Row(modifier = Modifier.fillMaxWidth().padding(top = 4.dp)) {
            Box(
                modifier = Modifier.weight(1f).height(28.dp).background(Color(0xFFBBDEFB)),
                contentAlignment = Alignment.Center
            ) { Text("1f") }
            Spacer(modifier = Modifier.width(4.dp))
            Box(
                modifier = Modifier.weight(2f).height(28.dp).background(Color(0xFFC8E6C9)),
                contentAlignment = Alignment.Center
            ) { Text("2f") }
            Spacer(modifier = Modifier.width(4.dp))
            Box(
                modifier = Modifier.weight(3f).height(28.dp).background(Color(0xFFFFE0B2)),
                contentAlignment = Alignment.Center
            ) { Text("3f") }
        }
    }
}

@Composable
fun JniStatusSample() {
    val nativeMessage = remember { GuideNativeBridge.stringFromJNI() }
    Text(
        text = "JNI 示例：$nativeMessage",
        modifier = Modifier.padding(vertical = 8.dp)
    )
}

