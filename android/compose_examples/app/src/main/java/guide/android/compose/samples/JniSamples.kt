package guide.android.compose.samples

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import guide.android.compose.jni.BionicBridge
import guide.android.compose.jni.GuideNativeBridge
import guide.android.compose.jni.JniDeepBridge
import guide.android.compose.jni.MediaBridge
import guide.android.compose.jni.NativeThreadBridge
import guide.android.compose.jni.SocketBridge
import java.io.File
import java.nio.ByteBuffer

// 第 20–25 章原生线示例：每条对应 cpp/ 下一个 JNI 函数。
// 纯计算在 remember { } 里调一次即收；会碰文件/线程的写法保证真机可跑。

// ---------- 第 20 章：日志 ----------

@Composable
fun JniLogSample() {
    // 真机上看 logcat | grep GuideNative：native 侧唯一的"打印"出口
    val logInfo = remember { GuideNativeBridge.logFromNative("GuideNative") }
    Text(
        text = "原生示例0（日志）：$logInfo",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

// ---------- 第 21 章：JNI 深入 ----------

@Composable
fun JniDeepStringSample() {
    val greet = remember { JniDeepBridge.nativeGreet("Compose 读者") }
    Text(
        text = "JNI 深入示例1（字符串）：$greet",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun JniDeepArraySample() {
    val ints = remember { intArrayOf(3, 1, 4, 1, 5, 9, 2, 6) }
    val doubles = remember { doubleArrayOf(1.5, 2.5, 3.5, 4.5) }
    val sum = remember(ints) { JniDeepBridge.nativeSumIntArray(ints) }
    val doubled = remember(doubles) {
        doubles.copyOf().also { JniDeepBridge.nativeScaleArrayInPlace(it, 2.0) }.joinToString()
    }
    Text(
        text = "JNI 深入示例2（数组两路）：Region 求和=$sum；Elements 原地翻倍=$doubled",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun JniDeepBufferSample() {
    // 直接 ByteBuffer 背后是 malloc 的 native 内存：用完必须手动 free
    val info = remember {
        val buf: ByteBuffer? = JniDeepBridge.nativeMakeDirectBuffer(1024)
        if (buf == null) {
            "创建失败"
        } else {
            buf.put(0, 7.toByte())                       // Kotlin 侧写
            buf.put(1023, 3.toByte())
            val sum = JniDeepBridge.nativeDirectBufferSum(buf)  // native 侧直读
            val freed = JniDeepBridge.nativeFreeDirectBuffer(buf)
            "容量 1024，两侧同读共 ${sum}，手动 free=${freed}"
        }
    }
    Text(
        text = "JNI 深入示例3（NIO 直接缓冲区）：$info",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun JniDeepFieldMethodSample() {
    val counter = remember { JniDeepBridge.JniCounter() }
    var count by remember { mutableStateOf(0) }
    val ping = remember { JniDeepBridge.nativePingSelf("field/method 演示") }
    val staticInfo = remember { JniDeepBridge.nativeStaticInfo() }
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Text("JNI 深入示例4（域与方法）", style = MaterialTheme.typography.bodyMedium)
        Row {
            Button(onClick = { count = JniDeepBridge.nativeBumpCounter(counter) }) {
                Text("nativeBumpCounter（当前 ${counter.count}）")
            }
        }
        Text(
            text = "实例回调：$ping\n静态调用：$staticInfo",
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
fun JniDeepExceptionSample() {
    val report = remember {
        // native 抛出的 IllegalArgumentException 跨界后与 Kotlin 异常无异
        val sqrtResult = runCatching { JniDeepBridge.nativeCheckedSqrt(-1.0) }
            .onSuccess { "意外成功：$it" }
            .exceptionOrNull()?.message
        val caught = JniDeepBridge.nativeCatchAndReport()
        "sqrt(-1) → $sqrtResult\n$caught"
    }
    Text(
        text = "JNI 深入示例5（异常双向）：$report",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun JniDeepReferenceSample() {
    var recall by remember { mutableStateOf("（还没记住）") }
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Text("JNI 深入示例6（全局引用跨调用存活）", style = MaterialTheme.typography.bodyMedium)
        Row {
            Button(onClick = { JniDeepBridge.nativeRememberTag("tag-${(0..999).random()}") }) {
                Text("Remember")
            }
            Button(onClick = { recall = JniDeepBridge.nativeRecallTag() }) {
                Text("Recall")
            }
            Button(onClick = { JniDeepBridge.nativeForgetTag() }) {
                Text("Forget")
            }
        }
        Text(text = "Recall 结果：$recall", style = MaterialTheme.typography.bodySmall)
    }
}

// ---------- 第 22 章：Bionic ----------

@Composable
fun BionicSystemSample() {
    val info = remember {
        "页大小=${BionicBridge.bionicPageSize()} B，CPU=${BionicBridge.bionicCpuCount()} 核，" +
                "ro.build.version.sdk=${BionicBridge.bionicSdkProp()}"
    }
    Text(
        text = "Bionic 示例1（sysconf/系统属性）：$info",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun BionicUidSample() {
    val uidInfo = remember { BionicBridge.bionicUidInfo() }
    Text(
        text = "Bionic 示例2（沙箱身份）：$uidInfo",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun BionicFileSample() {
    val context = LocalContext.current
    val report = remember(context) {
        // 内部存储路径（第 09 章）：native 只应碰应用沙箱之内
        val path = File(context.filesDir, "bionic_demo.txt").absolutePath
        BionicBridge.bionicFileRoundTrip(path, "hello from C stdio")
    }
    Text(
        text = "Bionic 示例3（FILE* I/O）：$report",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun BionicStlSample() {
    val sorted = remember {
        BionicBridge.bionicSortDoubles(doubleArrayOf(3.5, 1.2, 9.8, 0.4, 7.7))?.joinToString()
    }
    val features = remember { BionicBridge.bionicCppFeatures() }
    Text(
        text = "Bionic 示例4（STL/异常/RTTI）：std::sort → $sorted\n$features",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

// ---------- 第 23 章：原生线程 ----------

@Composable
fun NativeThreadSample() {
    val sum = remember { NativeThreadBridge.threadSpawnSum(1000) }
    val notify = remember {
        val back = NativeThreadBridge.threadNotifyBack(12)
        "join 后读取：${NativeThreadBridge.lastNativeMessage ?: back}"
    }
    val pings = remember { NativeThreadBridge.threadSemPingpong(50) }
    val sched = remember { NativeThreadBridge.threadSchedInfo() }
    Text(
        text = "线程示例1：pthread 求和 1..1000=$sum；AttachCurrentThread 回调成功；" +
                "信号量乒乓 $pings 回合\n$sched",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

// ---------- 第 24 章：POSIX Socket ----------

@Composable
fun SocketEchoSample() {
    val tcp = remember { SocketBridge.socketTcpEcho(48777, "tcp-hello") }
    val udp = remember { SocketBridge.socketUdpEcho(48778, "udp-hello") }
    Text(
        text = "Socket 示例1：$tcp\n$udp",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun SocketLocalEchoSample() {
    val context = LocalContext.current
    val local = remember(context) {
        val path = File(context.filesDir, "guide.sock").absolutePath
        SocketBridge.socketLocalEcho(path, "unix-hello")
    }
    Text(
        text = "Socket 示例2（UNIX domain）：$local",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

// ---------- 第 25 章：图形、音频与 NEON ----------

@Composable
fun MediaBitmapSample() {
    val info = remember {
        val bitmap = Bitmap.createBitmap(8, 6, Bitmap.Config.ARGB_8888)
        MediaBridge.mediaBitmapInfo(bitmap)
    }
    Text(
        text = "媒体示例1（JNI Graphics）：$info",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun MediaNeonSample() {
    val sum = remember {
        val a = shortArrayOf(1, 2, 3, 4, 5, 6, 7, 8, 9)
        val b = shortArrayOf(10, 20, 30, 40, 50, 60, 70, 80, 90)
        MediaBridge.mediaNeonAddShorts(a, b)?.joinToString()
    }
    Text(
        text = "媒体示例2（NEON）：8 路 vaddq_s16 + 标量尾巴 → $sum",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
fun MediaProbeSample() {
    val openSl = remember { MediaBridge.mediaOpenSlProbe() }
    val egl = remember { MediaBridge.mediaEglProbe() }
    Text(
        text = "媒体示例3（探测）：$openSl；$egl",
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        style = MaterialTheme.typography.bodySmall
    )
}
