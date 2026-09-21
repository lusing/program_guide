# 06 · Intent 与页面导航

> 对应示例：`examples/04_intent_navigation.kt`、`examples/20_activity_result_style.kt`

## 1. Intent 是什么：组件之间的消息信封

第 04 章讲了 Activity 的生死轮回，但没讲它怎么被"找上"。Android 的组件（Activity、Service、BroadcastReceiver）不对外暴露构造函数——你**不能 `new` 一个 Activity 再把它显示出来**。组件之间靠什么联系？靠 Intent。

把 Intent 想成一封信：信封上写着收件人和用途，信封里装着正文。

| 信封要素 | Intent 对应字段 | 例子 |
|---|---|---|
| 收件人 | 组件名（ComponentName，即目标类） | `Example04TargetActivity::class.java` |
| 干什么 | action（动作常量） | `Intent.ACTION_VIEW` |
| 附带地址 | data（Uri） | `https://developer.android.com` |
| 暗语分类 | category | `Intent.CATEGORY_DEFAULT` |
| 正文 | extras（键值对） | `putExtra("message", "hello target")` |

而且不止页面跳转在用它——三类组件都靠 Intent 触发：

| 组件 | 递信 API | 详见 |
|---|---|---|
| Activity | `startActivity()` | 本章 |
| Service | `startService()` / `bindService()` | [第 10 章](10-system-components.md) |
| BroadcastReceiver | `sendBroadcast()` | [第 10 章](10-system-components.md) |

所以把 Intent 理解成"跳页工具"是低估了它：它是 Android 组件通信的通货。本章只展开它最常用的切面——用 Intent 完成 Activity 之间的导航与数据往来。

## 2. 显式 Intent：指名道姓

`examples/04_intent_navigation.kt` 全貌，发送方与接收方各一半：

```kotlin
class Example04IntentNavigation : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val intent = Intent(this, Example04TargetActivity::class.java)
        intent.putExtra("message", "hello target")
        startActivity(intent)
    }
}

class Example04TargetActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val message = intent.getStringExtra("message") ?: "empty"
        val tv = TextView(this).apply { text = message }
        setContentView(tv)
    }
}
```

发送方三步：

1. `Intent(this, Example04TargetActivity::class.java)`——Context + 目标类，收件人写死，这就是**显式（explicit）**。Activity 本身就是 Context（第 04 章），所以 `this` 直接可用
2. `intent.putExtra("message", "hello target")`——往信封里塞一张键值对便签
3. `startActivity(intent)`——交给系统投递；当前 Activity 退居幕后（走 [第 04 章](04-activity-lifecycle.md) 的 `onPause → onStop`），目标 Activity 压栈上前台

接收方一步：`onCreate` 里用 `intent` 属性（即 `getIntent()`）取回这封信，`getStringExtra("message") ?: "empty"` 读便签——键不存在或类型对不上时返回 null，`?:` 降级为默认值。

还有一个不出现在代码里、但缺了必崩的前提：**目标 Activity 必须在 `AndroidManifest.xml` 注册**：

```xml
<activity android:name=".Example04TargetActivity" />
```

Manifest 是组件的户口本。漏掉这行，`startActivity` 当场抛 `ActivityNotFoundException` 崩溃退出，错误信息会明确提示你补注册。工程与 Manifest 的结构详见[第 02 章](02-project-toolchain.md)。

## 3. 隐式 Intent：只说想干什么

**隐式（implicit）Intent** 不写收件人，只写 action（有时配 data/category），由系统在所有 App 声明的 intent-filter 里挑选谁能接。最典型的是打开网页——你不关心哪个浏览器接单：

```kotlin
val openWeb = Intent(Intent.ACTION_VIEW, Uri.parse("https://developer.android.com"))
startActivity(openWeb)
```

`ACTION_VIEW` 表示"请显示这个 Uri"，匹配 `<intent-filter>` 里声明了该 action + `https` scheme 的浏览器。常用的还有：

| action | 意图 | 典型构造 |
|---|---|---|
| `Intent.ACTION_VIEW` | 显示一个 Uri（网页/地图） | `Intent(Intent.ACTION_VIEW, Uri.parse("https://..."))` |
| `Intent.ACTION_SEND` | 分享内容 | `Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, "...") }` |
| `Intent.ACTION_DIAL` | 拨号盘预填号码（不拨出） | `Intent(Intent.ACTION_DIAL, Uri.parse("tel:10086"))` |

两种 Intent 的分野：

| | 显式 | 隐式 |
|---|---|---|
| 怎么写 | Context + 目标类 | action（+ category + data） |
| 谁来接收 | 唯一确定的目标 | 系统按 intent-filter 挑选，多个候选时弹选择框 |
| 典型用途 | App 内部导航 | 跨 App：开网页、分享、发邮件 |
| 失败模式 | 目标没在 Manifest 注册，崩 | 没有任何 App 能处理，抛 `ActivityNotFoundException` |

观点：**App 内导航一律显式**——类名写死换来编译期可追溯，重构时 IDE 能跟着改；隐式 Intent 的正确定位是"跨 App 能力调用"，不要用它做内部跳转（耦合系统选择行为，难测试）。

## 4. 数据传递：extras 的边界

extras 是 Intent 内部的一个 `Bundle`（键值对容器），常用 API 就四个：

| API | 说明 |
|---|---|
| `putExtra(name, value)` | 塞入；String / Int / Boolean / Parcelable 等重载 |
| `getStringExtra(name)` | 读出；缺失或类型不符返回 null |
| `putExtras(bundle)` / `intent.extras` | 整包塞入 / 整包取出 |

多塞几个值也还是同一封信：

```kotlin
intent.putExtra("title", "会议纪要")
intent.putExtra("page", 3)
intent.putExtra("urgent", true)
```

```kotlin
val page = intent.getIntExtra("page", 0)          // Int 重载要求显式给默认值
val urgent = intent.getBooleanExtra("urgent", false)
```

注意读侧的不对称：`getStringExtra` 返回 null 可用 `?:` 兜底，`getIntExtra` / `getBooleanExtra` 直接要求传默认值——类型对不上时同样静默取默认，不报错。

为什么不能传大对象（Bitmap、长列表、大字符串）？

- Intent 跨进程投递时 extras 要**序列化（parcel）**走 Binder，事务缓冲区整进程共享约 1MB，塞大对象随时 `TransactionTooLargeException`
- 即使同 App 同进程跳转不真正走 Binder，进程被杀重建后系统仍要靠保存的 Intent 状态恢复，可打包是硬要求
- 序列化本身有成本：跳个页面传 2MB 数据，两端都要付出编解码时间

正确姿势是**传 id 不传数据**：Intent 里只放数据库主键或标识符，数据本体走第 09 章的持久层或进程内仓库（单例）。导航与数据分家，这是中大型 App 的基本功。

## 5. 回传数据：从 startActivityForResult 到 Activity Result API

单向传值之外，常见"打开选择页 → 用户挑一个 → 带回来"的闭环。`examples/20_activity_result_style.kt` 演示的是这个闭环的经典写法：

```kotlin
class Example20ActivityResultStyle : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivityForResult(Intent(this, Example20PickerActivity::class.java), 501)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 501 && resultCode == RESULT_OK && data != null) {
            val value = data.getStringExtra("picked") ?: "none"
            setContentView(TextView(this).apply { text = value })
        }
    }
}

class Example20PickerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val result = Intent()
        result.putExtra("picked", "android-item")
        setResult(RESULT_OK, result)
        finish()
    }
}
```

流程拆解：

1. `startActivityForResult(intent, 501)`——带上**请求码（requestCode）**发起跳转，501 是自己定的身份号
2. 选择页拿到结果后 `setResult(RESULT_OK, result)` 塞回数据，随即 `finish()` 自我出栈
3. 发起方在 `onActivityResult` 里先核对 `requestCode == 501`（可能同时有多个请求在飞），再核对 `resultCode == RESULT_OK`（用户可能按了返回键放弃，此时是 `RESULT_CANCELED`），最后才敢拆 `data`

**如实说：这是历史写法**。一个冷知识：框架层 `android.app.Activity` 的这组方法至今没有标注 `@Deprecated`（用 `javap` 查本地 `android.jar` 即可验证），真正被标记废弃的是 androidx 侧 `ComponentActivity` 的同名覆盖——但官方文档与模板早就不教它了，新代码不应再写。它的毛病在代码里已经看得见：所有请求的结果挤进同一个回调，靠手写 requestCode 分发；`data: Intent?` 手动判空拆包；样板代码每个 Activity 重复一遍。

现代替代是 **Activity Result API**（来自 AndroidX 的 `androidx.activity` 库，需要 `ComponentActivity` 基类；本工程示例用框架 `android.app.Activity` 零依赖编译验证，所以演示的是旧写法）。等效改写：

```kotlin
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts

class Example20Modern : ComponentActivity() {
    private val pickLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            val value = result.data?.getStringExtra("picked") ?: "none"
            setContentView(TextView(this).apply { text = value })
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pickLauncher.launch(Intent(this, Example20PickerActivity::class.java))
    }
}
```

选择页一侧的 `setResult + finish` 不变——回传机制本身没换，换的是发起侧的接收方式。两代对比：

| | startActivityForResult（旧） | Activity Result API（新） |
|---|---|---|
| 注册方式 | 调用点直接发起 | 先 `registerForActivityResult` 拿 launcher |
| 结果回调 | 全部挤在 `onActivityResult`，靠 requestCode 分发 | 每个 launcher 独立回调，无 requestCode |
| 类型安全 | 手动判空拆 `Intent?` | 契约（Contract）定义输入输出类型 |
| 生命周期 | 手动对齐 | 结果只在组件可见时投递，自动对齐 |
| 内置场景 | 无 | `StartActivityForResult` / `RequestPermission` / `TakePicture` 等 |

launcher 的归属也值得看清：它是**注册它的组件的私有财产**，结果直达自己的回调，不经全局分发——旧 API"所有结果挤一个门"造成的 requestCode 管理成本，在结构上被消灭。一个页面要同时发起多种请求（选联系人、拍照、选文件）就是多个 launcher 各管各的，互不干扰。

`registerForActivityResult` 有个硬约束：**必须在 Activity 进入 STARTED 状态之前调用**——写成属性初始化（如上）或放在 `onCreate` 里都行，放到按钮点击回调里再注册会直接 `IllegalStateException`。另外 `ActivityResultContracts.RequestPermission` 契约把运行时权限申请也统一到了这套 API，第 11 章会用到。

## 6. 任务与回退栈：导航的骨架

系统用一个**任务（Task）**承载用户的一段操作连续性，任务内部以**回退栈（back stack）**组织 Activity：

```text
压栈：startActivity(B)             出栈：返回键 / B.finish()
 ┌──┐                               ┌──┐
 │ B │ ← 新页面到前台                │ A │ ← 回到前台：onRestart → onStart → onResume
 │ A │                               └──┘   B 走 onPause → onStop → onDestroy
 └──┘
```

- `startActivity` = 压栈（新页面到前台，旧页面走 [第 04 章](04-activity-lifecycle.md) 的退居流程）
- `finish()` 或用户按返回键 = 出栈（下面的页面回到前台）

隐式 Intent 打开的页面（比如你 App 里点开浏览器）也压进同一个回退栈——用户按返回会回到你的页面，体验上像同一个 App。这在跨 App 导航里非常有用。

需要改变栈行为时再碰 flag，先认识两枚：

- `FLAG_ACTIVITY_CLEAR_TOP`：栈里已有目标页面，把它上面的全部清掉再复用它（"回首页"场景）
- `FLAG_ACTIVITY_SINGLE_TOP`：目标已在栈顶就不新建，改走 `onNewIntent`（防止连点叠多个同一页面）

还有一枚迟早遇到：从**非 Activity 的 Context**（Service、Application、BroadcastReceiver 的 `onReceive`）里 `startActivity`，必须加 `FLAG_ACTIVITY_NEW_TASK`——系统拒绝把页面压进一个没有"当前界面"语义的任务，不加会直接 `IllegalStateException`。后台组件拉起页面是必修课（第 10 章的通知点击就是场景）。

观点：简单导航链用 `startActivity / finish` 就够，别一上来背 flag 全家桶——栈行为一旦复杂化，排查"为什么返回不回到预期页面"的成本远高于收益。

## 7. 常见坑

**目标 Activity 没在 Manifest 注册**：`ActivityNotFoundException: Unable to find explicit activity class ... have you declared this activity in your AndroidManifest.xml?`——报错把修法都写明了，补 `<activity>` 声明即可。新建 Activity 时用 IDE 模板会自动注册，手写类就要自己想着这行。

**隐式 Intent 无接收者**：没有任何 App 声明能处理该 action 时同样抛 `ActivityNotFoundException`。凡是面向用户的隐式调用（开链接、分享）都要兜底：

```kotlin
try {
    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")))
} catch (e: ActivityNotFoundException) {
    Toast.makeText(this, "没有应用能打开这个链接", Toast.LENGTH_SHORT).show()
}
```

（`resolveActivity(packageManager)` 可以预检，但 API 30 起的包可见性过滤会让它对未在 `<queries>` 声明的包返回 null，预检反而更绕——try/catch 兜底更省心。）

**extras 键名或类型对不上**：`getStringExtra("Message")` 大小写一错就是 null，`?: "empty"` 只能按计划降级，不报错；`putExtra("level", 1)` 之后用 `getStringExtra("level")` 读同样拿 null。键名收进常量，收发两边共用。

**launcher 注册太晚**：`registerForActivityResult` 放进点击回调等运行时路径会直接 `IllegalStateException`（必须在 STARTED 之前注册）。属性初始化或 `onCreate` 是标准位置。

**把大对象塞进 extras**：跨进程路径上等着你的是 `TransactionTooLargeException`；侥幸不炸时也是双端序列化开销。传 id，不传数据。

## 8. 实战建议

- App 内导航一律显式 Intent；隐式只用于"跨 App 能力"（开网页、分享、拍照），并且必带 `ActivityNotFoundException` 兜底
- extras 键名收进伴生对象常量，再配一个 `newIntent(context, ...)` 工厂函数，收发两侧用同一份真源，杜绝拼写错位
- 传 id 不传对象：数据本体放第 09 章的持久层或进程内仓库，导航只负责"指路"
- 新代码禁用 `onActivityResult`，统一 Activity Result API；权限申请也走 `RequestPermission` 契约（详见[第 11 章](11-permissions-content.md)）
- 回退栈 flag 按需学习：先记住压栈/出栈两条基本操作，出现"清栈回首页"类需求再查 `FLAG_ACTIVITY_CLEAR_TOP`

---
上一章：[05 传统 View 体系：布局、控件与事件](05-views-events.md) ｜ 下一章：[07 列表与 Adapter 模式](07-lists-adapters.md) ｜ 返回：[README](../README.md)
