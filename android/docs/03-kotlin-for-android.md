# 03 · Kotlin for Android 必需子集

> 对应示例：`examples/01_hello_activity.kt`

## 1. 为什么 Android 世界倒向了 Kotlin

Kotlin 是 JetBrains 2011 年发布的 JVM 语言。2017 年 Google I/O 宣布它成为 Android 官方支持语言，2019 年进一步宣布 **Kotlin-first**：官方文档、示例与 Jetpack 新 API 一律 Kotlin 优先，Jetpack Compose（详见[第 12 章](12-compose-basics.md)）的 API 干脆只能用 Kotlin 写。今天新建 Android 工程的默认语言就是 Kotlin，Java 反而成了存量。

倒向的理由不是赶时髦，是三笔实账：

1. **null 安全**：`NullPointerException` 是 Java 世界头号崩溃源，Kotlin 把"可空"搬进类型系统，编译期就拦下
2. **零成本互操作**：Kotlin 编译成标准 JVM 字节码，与 Java 自由互调、可逐文件混编，迁移没有断崖
3. **样板大幅减少**：同样的界面，Kotlin 版通常只有 Java 版一半行数

同一个界面的两种写法（Java 版是照着 `examples/01_hello_activity.kt` 翻译的等价代码）：

```java
// Java 版：仪式感十足
public class HelloActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView textView = new TextView(this);
        textView.setText("Hello Android Java");
        setContentView(textView);
    }
}
```

```kotlin
// Kotlin 版：examples/01_hello_activity.kt 的类主体（省略 package 与 import）
class Example01HelloActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val textView = TextView(this)
        textView.text = "Hello Android Kotlin"
        setContentView(textView)
    }
}
```

| 维度 | Java | Kotlin |
|---|---|---|
| null 安全 | 无，运行时炸 NPE | 可空/非空进类型系统，编译期拦截 |
| 类型推断 | `TextView tv = new TextView(...)` 类型写两遍 | `val tv = TextView(this)` 写一遍 |
| 属性访问 | `textView.setText("hi")` | `textView.text = "hi"` |
| 回调注册 | 匿名内部类 4 行 | Lambda 1 行 |

观点先行：**不需要先学完 Kotlin 再学 Android**。日常开发反复用到的语法只有十几个特性，本章一次讲清；语言全景交给同仓库的兄弟教程《Kotlin 指南》承接（见本章最后一节）。本章所有片段都可以直接改进 `examples/01_hello_activity.kt`，用第 02 章的 `.\build.ps1 -File 01_hello_activity.kt` 编译验证。

## 2. val、var 与类型推断

`val` 只读、`var` 可变，类型都由编译器推断。Android 代码里九成的局部变量该是 `val`——**默认用 val，确需重新赋值才用 var**，这条习惯能消灭一整类"值被半路改掉"的 bug。

```kotlin
val label = "Profile"        // 推断为 String，重新赋值直接编译错误
var count = 0                // 推断为 Int
val input = EditText(this)   // 推断为 EditText
count += 1                   // OK：var
// label = "About"           // 编译错误：Val cannot be reassigned
```

需要显式写类型的场合基本只有两种：可空类型（下一节），以及"用抽象类型持有具体对象"：

```kotlin
val views: List<View> = listOf(textView, button)   // 面向接口，不关心具体类型
```

函数参数支持**默认值与命名参数**——Android 里大量"可选配置"靠它消灭一排重载：

```kotlin
fun toast(msg: String, long: Boolean = false) =
    Toast.makeText(this, msg, if (long) Toast.LENGTH_LONG else Toast.LENGTH_SHORT).show()

toast("已保存")                  // 缺省参数
toast("删除失败", long = true)    // 命名参数：跳着传也不歧义
```

## 3. 可空类型：?. 、?: 与 !!

类型名后带 `?` 才允许装 null；不带 `?` 就是"编译器担保非空"。三件套各管一件事：

```kotlin
var nickname: String? = null            // ? = 可空，初始值 null 合法
val len: Int? = nickname?.length        // ?. 安全调用：左边为 null 整体为 null
val safe: Int = nickname?.length ?: 0   // ?: Elvis：左边为 null 就取右边
val forced = nickname!!.length          // !! 断言非空：为 null 当场抛异常
```

| 操作符 | 语义 | 等价的传统写法 |
|---|---|---|
| `?.` | 为 null 则短路成 null | `if (a != null) a.f() else null` |
| `?:` | 为 null 取右值（右值还能是 `return`/`throw`） | 三元表达式判 null |
| `!!` | 断言非空，赌错抛 NPE | 无，纯危险操作 |

Android 里最常见的一行是从 Intent 取参数（详见[第 06 章](06-intents-navigation.md)）——返回值天然可空：

```kotlin
val name = intent.getStringExtra("name") ?: "匿名用户"   // 没传就给默认值
```

## 4. data class 与 copy

界面状态、网络返回的 JSON 对象，都适合建模成 data class。一行类头自动生成 `equals`、`hashCode`、`toString` 与解构，还有最好用的 `copy`：

```kotlin
data class Note(val id: Int, val title: String, val done: Boolean = false)

val a = Note(1, "买牛奶")
val b = a.copy(done = true)     // 只改指定字段，其余照抄，原对象不动
println(b)                      // Note(id=1, title=买牛奶, done=true)
val (id, title, done) = b       // 解构声明：按声明顺序取字段
```

**不可变 + copy** 是 Kotlin 变更状态的默认姿势：不原地改，而是派生新对象。这与第 12 章 Compose 的"状态不可变、变化即重组"是同一种哲学，现在养成习惯，后面白捡。

## 5. when 表达式

`when` 是 switch 的超集，而且是**表达式**（有返回值），分支支持多值、区间、任意条件：

```kotlin
fun describe(code: Int): String = when (code) {
    200 -> "成功"
    404, 410 -> "资源不存在"
    in 500..599 -> "服务器错误"
    else -> "未知"
}
```

不带参数的 `when` 还能当紧凑的 if-else 链，配合表达式函数体很顺手：

```kotlin
fun label(done: Boolean, priority: Int): String = when {
    priority > 5 -> "紧急"
    done -> "已完成"
    else -> "进行中"
}
```

Android 里的典型用途：按 view id 分发点击（[第 07 章](07-lists-adapters.md)）、按网络状态码切换 UI。

## 6. Lambda 与 SAM 转换

Kotlin 的 Lambda 是花括号表达式，`it` 是单参数时的隐式参数名。Android 里大量 Java 接口只有一个方法（SAM，Single Abstract Method），Lambda 可以直接当它传入——`setOnClickListener` 就是教科书案例：

```kotlin
// setOnClickListener 需要 View.OnClickListener（Java 单方法接口）
button.setOnClickListener { toast("clicked") }   // Lambda 自动做 SAM 转换

// 集合操作是 Lambda 的主场
val doneTitles = notes.filter { it.done }.map { it.title }

// 遍历的最短写法
notes.forEach { toast(it.title) }     // 等价于 for (n in notes) toast(n.title)
```

没有 SAM 转换的等价写法是四行匿名内部类（第 1 节 Java 版的痛点），Kotlin 里你几乎不会再见到。`toast(...)` 这个扩展函数下一节安家。

## 7. 扩展函数

给别人的类（包括框架类）"外挂"方法：不碰源码、不继承。Android 里最实用的落点是给 `Context` 加工具函数：

```kotlin
fun Context.toast(msg: String) =
    Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()

// 之后任何 Activity / Service 里：
toast("已保存")
```

扩展函数体内的 `this` 指向接收者（这里是 Context）。它的本质是**静态方法的语法糖**——不改类本身，因此访问不到私有成员，也别指望它参与多态。

## 8. apply、let 与字符串模板

`apply` 在对象上执行一段配置并返回对象本身，是建控件的标准姿势——本教程 `examples/02`、`03`、`06`、`19` 全是这个形状：

```kotlin
val tv = TextView(this).apply {
    text = "Hello"
    textSize = 16f       // 块内 this 就是 tv，不必反复写 tv.
}
```

`let` 常与 `?.` 连用，表达"非空才执行"：

```kotlin
intent.getStringExtra("name")?.let { greet(it) }   // 为 null 时整句跳过
```

字符串模板用 `$` 插值：

```kotlin
Log.d("Guide", "response=$code")    // examples/16_network_thread.kt 的真实用法
println("共 ${notes.size} 条")       // 表达式要套花括号
```

同族的 `run`、`also` 见到要认识：`run` 像 let 但块内是 `this`，`also` 像 apply 但用 `it`、返回对象本身。日常开发记住两条分工就够：**apply 配对象的配置，let 配判空后的使用**。

## 9. 协程最小集

网络、磁盘这些耗时操作不能在主线程做（为什么、怎么做详见[第 08 章](08-threads-network.md)）。现代方案是协程，入门只需要三个词：

```kotlin
suspend fun loadTitle(url: String): String =
    withContext(Dispatchers.IO) {     // 把块内代码切到 IO 线程池执行
        URL(url).readText()           // 阻塞式网络请求，放在 IO 线程没关系
    }                                 // 结束后自动切回调用线程
```

- `suspend`：标记"可挂起"的函数——能暂停再恢复而不占着线程；只能从协程或其他 suspend 函数调用
- `withContext(Dispatchers.IO)`：把活儿切到 IO 线程干，干完带着返回值回来
- `launch`：发射一个协程——`scope.launch { textView.text = loadTitle(url) }`，写法是同步的，执行是异步的

`launch` 的完整样子（真实工程还需加 `kotlinx-coroutines-android` 依赖）：

```kotlin
val scope = CoroutineScope(Dispatchers.Main)
scope.launch {                          // 在主线程上启动协程
    val title = loadTitle(url)          // 挂起点：线程让路，界面不卡
    textView.text = title               // 恢复后继续，仍在主线程，改 UI 合法
}
```

协程的调度细节、取消与超时、与 Handler 的对照都在[第 08 章](08-threads-network.md)展开。本章只需记住一句话：**看到 suspend 不慌，它只是"会自动让路的长操作"**。

## 10. Android 里的 Kotlin 惯用法

读 Android 官方文档（示例多为 Java）需要一副"翻译眼镜"：**成对的 getter/setter 自动变属性**。示例 01 的 `textView.text = "..."` 调用的其实是 `setText()`，这就是 Kotlin 直接用属性语法访问 getter/setter 的效果：

| Java 文档里写的 | Kotlin 里你写的 |
|---|---|
| `tv.setText("hi")` / `tv.getText()` | `tv.text = "hi"` |
| `btn.setOnClickListener(new OnClickListener() {...})` | `btn.setOnClickListener { ... }` |
| `getResources().getString(R.string.x)` | `getString(R.string.x)` |
| `new Intent(this, Target.class)` | `Intent(this, Target::class.java)` |
| 匿名内部类里的 `MainActivity.this` | 标签 `this@MainActivity`（第 05 章出场） |

认属性语法的边界同样重要：**只有成对的 getter/setter 才折叠成属性**。`setContentView`、`addView` 这类单一方法照旧是普通函数调用——不存在 `view.view = ...` 的写法。

三个高频组合拳，认熟了读示例零障碍：

```kotlin
// 组合 1：建控件 = 构造 + apply 配置（examples/02 的形状）
val input = EditText(this).apply { hint = "Input your name" }

// 组合 2：可空参数 = ?. 与 ?: 连招
val title = intent.getStringExtra("title") ?: "默认标题"

// 组合 3：点击 = SAM 转换 + 字符串模板
button.setOnClickListener { toast("第 ${++count} 次点击") }
```

## 11. 常见坑

**`!!` 滥用**。从 Java 迁来的人把 `!!` 当"我确定不为 null"的万能钥匙——它等于手动关掉 null 检查，把崩溃从编译期挪回运行期，还更难查。规则：生产代码里 `!!` 应当屈指可数，每一处都要能说清"这里为什么不可能为 null"。

**Platform Type（平台类型）**。调用 Java API 时返回值的可空性未知（Kotlin 里标记为 `String!` 这类类型），赋给非空变量**不报错**，运行时却可能是 null——`intent.getStringExtra()` 就是惯犯。对策：把平台类型一律当可空处理，用 `?.`/`?:` 收口。

**companion object 与 static**。Kotlin 没有 `static` 关键字。类级常量与伴生工厂放 `companion object`，而与类无关的工具函数直接写顶层函数/顶层 `val`（比 companion 更轻、更常用）：

```kotlin
class NoteListActivity : Activity() {
    companion object { const val EXTRA_ID = "extra_id" }   // Java 眼中的 static final
}
```

**字符串比较的习惯反着带**。Kotlin 的 `==` 就是内容相等（自动调 `equals`），`===` 才是引用相等。从 Java 带来的"字符串别用 =="戒律在这里纯属负担。

## 12. 实战建议

- 按本章子集写代码足以完成本教程全部章节；遇到看不懂的语法再回来查，比预习整本语言书效率高
- 三个默认值比一百条规则有用：默认 `val`、默认不可变 + `copy`、默认把平台类型当可空
- IDE 的灰色提示（"可转为表达式""可用 apply"）是免费教材，顺手改一遍肌肉记忆就有了
- 与 Java 混编完全合法：同一工程里逐文件迁移，不必推倒重来
- 语言全景深入入口：同仓库兄弟教程《Kotlin 指南》（`G:\code\guide\kotlin\KOTLIN_GUIDE.md`，本目录的相对路径是 `../kotlin/KOTLIN_GUIDE.md`），含 169 个可编译片段；其协程章节与本教程[第 08 章](08-threads-network.md)互补

---
上一章：[02 工程结构与构建工具链](02-project-toolchain.md) ｜ 下一章：[04 Activity 与应用生命周期](04-activity-lifecycle.md)
