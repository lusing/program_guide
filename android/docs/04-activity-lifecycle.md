# 04 · Activity 与应用生命周期

> 对应示例：`examples/01_hello_activity.kt`

## 1. Activity 是什么

Activity 是 Android 四大组件（Activity、Service、BroadcastReceiver、ContentProvider，后两者详见[第 10 章](10-system-components.md)）里唯一负责界面的那个：**一个 Activity 大致对应一屏 UI**，可以理解为应用组件概念上的"屏幕"。

三件事必须刻进脑子：

1. **它只是系统进程里的一个对象**。你从不 `new Activity()`，而是通过 Intent 请求系统启动（[第 06 章](06-intents-navigation.md)）；它的创建与销毁都不归你管
2. **生命周期由系统驱动**。用户按 Home、来电、旋转屏幕、内存告急——每一种外界事件都被系统翻译成一串回调敲在你头上。你的角色不是管理者，是**填空者**：系统在正确的时机调你的方法，你在方法里放正确的代码
3. **系统随时可以杀掉重建**。Activity 可能被销毁后原样重建，进程本身也可能整个被杀。一切状态管理设计都从这个前提出发

从 WPF 来的读者对照一张表，差别一目了然：

| | WPF Window | Android Activity |
|---|---|---|
| 谁创建 | 你 `new` + `Show()` | 系统，响应 Intent |
| 谁驱动生命周期 | 你的代码（Show/Activate/Close） | 系统回调 |
| 销毁时机 | 你调 `Close()` | 返回键、`finish()`、系统回收 |
| 意外重建 | 无此概念 | 旋转屏幕、切深色模式、内存不足 |
| 进程被杀 | 进程退出，窗口随之消失 | 用户无感知，回来时静默重建 |

还有一层关系要早点知道：**Activity 是 `Context` 的子类**。Context 是 Android 世界的"通行证"——取资源、启动界面、访问系统服务都要出示它，所以你会看到 `TextView(this)`、`Toast.makeText(this, ...)` 里到处把 Activity 自己传出去（[第 05 章](05-views-events.md)展开）。

经验法则：**一屏一事**——一个 Activity 聚焦一件用户任务，列表屏、详情屏、编辑屏分开，靠 Intent 串联（[第 06 章](06-intents-navigation.md)）。别做一个千行大局面的"上帝 Activity"。

写惯桌面程序的人在这里要换一次心智模型：不是"我管理窗口"，而是"**系统管理我，我只在回调里填空**"。

## 2. 逐行讲解 `examples/01_hello_activity.kt`

全文件不到 20 行，却是后面所有示例的骨架：

```kotlin
package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class Example01HelloActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val textView = TextView(this)
        textView.text = "Hello Android Kotlin"
        setContentView(textView)
    }
}
```

逐行拆开：

| 代码 | 在干什么 |
|---|---|
| `class Example01HelloActivity : Activity()` | 继承框架 `Activity`；Kotlin 用冒号继承，括号表示调用父类构造 |
| `override fun onCreate(...)` | 重写生命周期回调；`override` 是关键字（Java 里只是注解） |
| `savedInstanceState: Bundle?` | 可空：正常启动为 null，**重建时带着上次存的状态**（第 5 节） |
| `super.onCreate(savedInstanceState)` | 必须第一行调用，框架在内部完成窗口等基础初始化 |
| `TextView(this)` | `this` 就是 Context——Activity 是 Context 的子类，控件构造靠它拿主题与资源 |
| `textView.text = "..."` | 属性语法实际调用 `setText()`（第 03 章惯用法表） |
| `setContentView(textView)` | 把 View 挂到这个 Activity 的窗口上；不调用就是白屏 |

两个"为什么"：

- **为什么继承 `Activity` 而不是 `AppCompatActivity`**：`AppCompatActivity` 属于 AndroidX 库，而本教程基础篇示例只用 `android.jar` 编译（[第 02 章](02-project-toolchain.md)的 `build.ps1`），没有 AndroidX 依赖。真实项目几乎总用 AppCompat 系（第 6 节谱系）
- **这个类怎么被启动**：真实工程里每个 Activity 都要在 `AndroidManifest.xml` 注册，入口 Activity 带 `MAIN`/`LAUNCHER` intent-filter（详见[第 02 章](02-project-toolchain.md)）。示例集只做编译验证、不打包 APK，所以你在这里看不到 manifest

回头再看，这十几行浓缩了第 03 章的全部惯用法：冒号继承、`override` 关键字、可空类型 `Bundle?`、属性语法 `textView.text`——一个最小的"Kotlin for Android"标本。

## 3. 生命周期回调一览

七个回调，两两成对更好记：

| 对 | 台阶 | 进入时适合 | 离开时适合 |
|---|---|---|---|
| `onCreate` ↔ `onDestroy` | 存在与否 | 一次性初始化 | 一次性释放 |
| `onStart` ↔ `onStop` | 可见与否 | 注册监听 | 注销监听 |
| `onResume` ↔ `onPause` | 前台与否 | 开始动画/预览 | 暂停动画/预览 |

| 回调 | 何时被调 | 该做什么 |
|---|---|---|
| `onCreate(Bundle?)` | 创建，全程只一次 | `setContentView`、建控件、初始化数据、恢复 savedInstanceState |
| `onStart()` | 即将可见 | 注册界面需要的监听 |
| `onResume()` | 到前台、获得焦点 | 启动动画、摄像头预览、传感器监听（[第 11 章](11-permissions-content.md)） |
| `onPause()` | 失去焦点（被部分遮挡、即将跳转） | 只做轻活——它阻塞下一个界面上屏，写重了切换就卡 |
| `onStop()` | 完全不可见 | 停止耗电工作、注销监听、把草稿落盘 |
| `onRestart()` | 从 stopped 状态再次可见前 | 少用；逻辑通常对称地放 onStart |
| `onDestroy()` | 被销毁（返回键、`finish()`、系统回收） | 释放全部资源 |

"可见"与"可交互"是两个台阶：弹一个半透明对话框，底下的 Activity 只走到 onPause（还看得见，摸不着）；跳到别的 App，才走完 onPause → onStop。四种典型场景的回调序列：

```text
冷启动:      onCreate → onStart → onResume        （运行中）
按 Home:     onPause → onStop                     （后台，随时可能被杀）
回来:        onRestart → onStart → onResume
按返回键:    onPause → onStop → onDestroy         （走完一生）
```

亲手验证：给每个回调打一行日志（`import android.util.Log`，用法同 `examples/16_network_thread.kt`），

```kotlin
class LifecycleLogActivity : Activity() {
    override fun onCreate(b: Bundle?) { super.onCreate(b); Log.d("LC", "onCreate") }
    override fun onStart()  { super.onStart();   Log.d("LC", "onStart") }
    override fun onResume() { super.onResume();  Log.d("LC", "onResume") }
    override fun onPause()  { super.onPause();   Log.d("LC", "onPause") }
    override fun onStop()   { super.onStop();    Log.d("LC", "onStop") }
    override fun onRestart(){ super.onRestart(); Log.d("LC", "onRestart") }
    override fun onDestroy(){ super.onDestroy(); Log.d("LC", "onDestroy") }
}
```

Logcat 里按 `LC` 过滤，回调顺序一目了然。`onRestart` 只在"从后台回来"出现、`onCreate` 只在"创建"出现——这两个是区分场景的指纹。粒度上也要留心："暂停音乐"放 `onPause`、"停止传感器刷新"放 `onStop`，两者的触发条件并不相同。

一张图收束全部顺序：

```text
生:    onCreate → onStart → onResume → （运行中）
退:    ← onPause ← onStop ← ──────────┘
折返:  onStop 状态 → onRestart → onStart → onResume
死:    运行中 → onPause → onStop → onDestroy
```

记忆锚点是"生三个、退两个、死一个"：走向前台要三步（create/start/resume），退到后台两步（pause/stop），销毁再多一步（destroy）。

## 4. 回退栈与返回键

每启动一个 Activity，系统就把它压进**回退栈（back stack）**；按返回键（或全面屏返回手势）等于弹出栈顶：当前 Activity 走 `onPause → onStop → onDestroy`，露出的下一个收到 `onRestart → onStart → onResume`。代码里手动弹栈的等价物是 `finish()`。

```text
用户路径: A → B → C         回退栈: [A, B, C]
按返回:   C 销毁，露出 B     回退栈: [A, B]
再按返回: B 销毁，露出 A     回退栈: [A]
再按返回: A 销毁，任务结束
```

```kotlin
startActivity(Intent(this, DetailActivity::class.java))   // 压栈（第 06 章）
finish()                                                  // 弹栈，等价于用户按返回
```

对照 WPF：窗口谁开谁关、模态与否，全由代码说了算；Android 把"返回"做成了**系统级语义**——用户在任何界面按返回都得到可预期行为，应用只负责按逻辑顺序把页面压栈。"最近任务"（recent tasks）里看到的是任务维度的一个栈；多任务细节与启动模式（如 `clearTop`）见[第 06 章](06-intents-navigation.md)。

## 5. 进程回收与 savedInstanceState

两种"不知不觉被重来"：

1. **进程回收**：应用退到后台，内存吃紧时系统直接杀掉整个进程——**没有 onDestroy 告别仪式**。用户再点图标时是全新进程 + 全新 Activity，一切内存状态归零
2. **配置变更（configuration change）**：旋转屏幕、切换深色模式、改系统语言，默认行为都是**销毁重建**当前 Activity

为什么旋转要重建？因为屏幕尺寸变了，界面可能需要另一套资源（横屏布局、不同字号）——系统选了最粗暴也最通用的方案：推倒重来。代价是内存状态丢失，所以才需要下面这条逃生通道。

两种情况的救命稻草是同一个：`Bundle`。系统在销毁前调 `onSaveInstanceState(outState)` 给你机会存一小包数据，重建的 `onCreate` 里原样还给你：

```kotlin
override fun onSaveInstanceState(outState: Bundle) {
    super.onSaveInstanceState(outState)
    outState.putString("draft", input.text.toString())   // 存草稿
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // ...建界面...
    val draft = savedInstanceState?.getString("draft")   // 重建时有值，正常启动是 null
    input.setText(draft ?: "")
}
```

串成完整的最小示例（用第 03 章的惯用法写）：

```kotlin
class DraftActivity : Activity() {
    private lateinit var input: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        input = EditText(this).apply { hint = "写点什么" }
        setContentView(input)
        savedInstanceState?.getString("draft")?.let { input.setText(it) }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("draft", input.text.toString())
    }
}
```

恢复的另一个入口是 `onRestoreInstanceState`：它在 `onStart` 之后调用、**只在重建时**被调，因此不用判空：

```kotlin
override fun onRestoreInstanceState(savedInstanceState: Bundle) {
    super.onRestoreInstanceState(savedInstanceState)
    input.setText(savedInstanceState.getString("draft") ?: "")
}
```

| 场景 | `onSaveInstanceState` 会不会被调 |
|---|---|
| 按 Home、切后台 | 可能（系统评估有回收风险时才调） |
| 旋转屏幕 | 会 |
| 按返回键离开 | 不会 |

三条边界要认清：

- 按**返回键离开不触发保存**——用户明确结束了这一屏，没义务替他留现场
- Bundle 经 Binder 跨进程传输，别塞大对象（事务缓冲区约 1MB 且全局共享），大文件直接写磁盘（[第 09 章](09-data-storage.md)）
- manifest 里 `android:configChanges="orientation"` 可以声明"旋转我自己处理"从而跳过重建——不推荐，等于把一堆状态同步的脏活从系统接回自己手上

现代补充：架构组件 ViewModel 在旋转重建时跨过生死保留数据，比手动搬 Bundle 省心，Compose 工程里配合 StateFlow 使用——见[第 14 章](14-compose-architecture.md)。

## 6. Activity 谱系：ComponentActivity 与 AppCompatActivity

一句话谱系（中间还有个 FragmentActivity——Fragment 的宿主，传统多页工程常见；AppCompatActivity 已包含它的能力）：

```text
android.app.Activity                         ← 本教程基础篇示例用这层
└─ androidx.activity.ComponentActivity       ← Compose 入口（setContent 在这层）
   └─ androidx.appcompat.app.AppCompatActivity ← 传统 View 项目默认
```

`android.app.Activity` 是根；Jetpack 在其上叠了 `androidx.activity.ComponentActivity`，挂载 Lifecycle 等架构组件能力，**Compose 的 `setContent { }` 就定义在这一层**（[第 12 章](12-compose-basics.md)）；`AppCompatActivity` 再继承它，补上主题与 ActionBar 兼容，是传统 View 项目的默认选择。选择规则：纯 Compose 项目用 ComponentActivity，其余用 AppCompatActivity，本教程示例（无 AndroidX 依赖）用框架 Activity。

## 7. 常见坑

**漏掉 `super.onCreate(...)`**。立刻崩溃（`SuperNotCalledException`）。所有生命周期回调都要求先调 super——IDE 生成的 override 模板自带这一行，删除"看起来没用"的代码前想两遍。

**在 `onCreate` 之前用 View**。字段初始化器比 `onCreate` 先执行：把 `findViewById<TextView>(R.id.x)` 写成字段初始化，跑的时候 `setContentView` 还没发生，拿到 null 一用就炸。控件引用要么在 `onCreate` 里赋值，要么声明 `lateinit var`。

**把 Activity 当普通对象 new 出来**。`val a = MyActivity()` 得到的对象没经过系统初始化——没有窗口、Context 能力残缺、生命周期回调一个都不会来。进入 Activity 的唯一正门是 `startActivity(Intent)`（[第 06 章](06-intents-navigation.md)）。

**以为旋转丢状态是 bug**。那是默认行为。没写 `onSaveInstanceState` 的瞬态（输入草稿、滚动位置）重建后必然消失——报 bug 前先问自己"这一屏的状态放在哪了"。

**在 `onPause` 里做重活**。onPause 不返回，下一个 Activity 就上不了屏。持久化、释放资源这类 IO 请移到 `onStop`。

**Bundle 里塞了不可序列化的对象**。Bundle 只收基本类型与 `Parcelable`/`Serializable`——把没实现这两个接口的自定义对象或 Bitmap 直接塞进去，运行时崩。大图存文件、传路径（[第 09 章](09-data-storage.md)）。

**把全部初始化塞进 `onCreate`**。冷启动时长直接体现在白屏上：能延迟的（首屏用不到的数据）往后挪，能缓存的别每次重算。

## 8. 实战建议

- 重初始化放 `onCreate`（只走一次），轻恢复放 `onStart`/`onResume`（每次可见）——别把所有事都塞进 onCreate
- 成对回调成对写：`onStart` 注册、`onStop` 注销。[第 10 章](10-system-components.md)的 BroadcastReceiver、[第 11 章](11-permissions-content.md)的传感器监听都靠这条纪律避免泄漏
- 给每个回调打一行 `Log.d("Lifecycle", ...)`，把第 3 节四个场景亲手跑一遍，眼见为实
- 开发者选项里打开"不保留活动"（Don't keep activities），把"后台被杀"从偶发变成每次可复现
- 状态分三层放：瞬态进 Bundle、会话级进内存对象、持久化进磁盘（[第 09 章](09-data-storage.md)）——三层别混
- 读别人的 Activity 先看它重写了哪几个回调，生命周期足迹一望便知
- Compose 的 `rememberSaveable` 本质上就是 Bundle 机制的声明式包装（[第 12 章](12-compose-basics.md)）——本章的模型到那一章仍然成立

---
上一章：[03 Kotlin for Android 必需子集](03-kotlin-for-android.md) ｜ 下一章：[05 传统 View 体系：布局、控件与事件](05-views-events.md)
