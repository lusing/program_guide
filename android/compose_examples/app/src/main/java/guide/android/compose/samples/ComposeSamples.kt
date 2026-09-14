package guide.android.compose.samples

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
    LazyColumn(modifier = Modifier.padding(vertical = 6.dp)) {
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
fun JniStatusSample() {
    val nativeMessage = remember { GuideNativeBridge.stringFromJNI() }
    Text(
        text = "JNI 示例：$nativeMessage",
        modifier = Modifier.padding(vertical = 8.dp)
    )
}

