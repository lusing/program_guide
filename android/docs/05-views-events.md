# 05 · 传统 View 体系：布局、控件与事件

> 对应示例：`examples/02_layout_views.kt`、`examples/03_button_toast.kt`、`examples/19_property_animation.kt`

## 1. 两种建界面的方式

Android 建界面有两条路：**代码直接 new View 对象**（本教程示例的做法），或 **XML 布局 + `setContentView(R.layout.x)`**。`examples/02_layout_views.kt` 建出的界面树长这样：

```text
Activity
└─ LinearLayout（竖直方向）
   ├─ TextView    "Profile"
   └─ EditText    hint="Input your name"
```

XML 版的等价写法（真实工程里的主流形态）：

```xml
<!-- res/layout/activity_profile.xml -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Profile" />

    <EditText
        android:id="@+id/name_input"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Input your name" />
</LinearLayout>
```

```kotlin
setContentView(R.layout.activity_profile)              // 解析 XML，inflate 成对象树
val input = findViewById<EditText>(R.id.name_input)    // 再按 id 找回控件引用
```

| | 代码建界面 | XML 布局 |
|---|---|---|
| 本质 | 直接 `new` View 对象 | aapt 把 XML 编进资源，运行时 inflate 成同一批对象 |
| 类型安全 | 编译期 | id 拼错是运行时才炸（返回 null 或异常） |
| 预览 | 无 | Layout Editor 实时预览 |
| 动态性 | 强，可用条件/循环生成 | 弱，适合静态结构 |
| 工具链 | 只要 `android.jar` | 需要 aapt2 资源管线（[第 02 章](02-project-toolchain.md)） |

本教程示例为什么用代码：示例集只用 `kotlinc + android.jar` 编译（[第 02 章](02-project-toolchain.md)），没有 aapt 参与，`R` 类无从产生；更重要的教学理由是——代码建界面把"**View 就是普通对象**"暴露无遗，XML 只是把 `new` + `addView` 换了一种书写。真实项目的传统界面九成是 XML；而 Compose 又回到了纯代码建界面（[第 12 章](12-compose-basics.md)），这条路你并不白走。

顺带一提，`setContentView` 有两个常用重载：传 View 对象（本章示例）或传布局资源 id（`R.layout.x`）——两条路最终都汇到同一棵 View 树上。

## 2. 布局容器：LinearLayout 为主角

`examples/02_layout_views.kt` 全文：

```kotlin
class Example02LayoutViews : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        val title = TextView(this).apply { text = "Profile" }
        val input = EditText(this).apply { hint = "Input your name" }
        layout.addView(title)
        layout.addView(input)
        setContentView(layout)
    }
}
```

（省略了 package 与 import，下同。）四个要点：

- `LinearLayout(this)` 也是 View（ViewGroup 是 View 的子类），容器可以无限嵌套
- `orientation` 决定子 View 排成一行（`HORIZONTAL`）还是一列（`VERTICAL`）
- `addView(child)` 把控件挂进容器；不给 LayoutParams 时由父容器补默认值——竖直 LinearLayout 默认给子 View"宽 match_parent、高 wrap_content"
- `setContentView(layout)` 挂根容器，与挂单个 TextView 是同一个方法

按比例分配空间用 `layout_weight`，这是 LinearLayout 的杀手锏：

```kotlin
layout.addView(top, LinearLayout.LayoutParams(
    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))   // 高度为 0，权重 1
layout.addView(bottom, LinearLayout.LayoutParams(
    LinearLayout.LayoutParams.MATCH_PARENT, 0, 2f))   // 同理权重 2 → 1:2 分完剩余高度
```

`FrameLayout` 的用法一眼版（叠加 + 居中，需要 `import android.view.Gravity`）：

```kotlin
val overlay = FrameLayout(this)
overlay.addView(ImageView(this).apply {
    setImageResource(android.R.drawable.ic_menu_info_details)
}, FrameLayout.LayoutParams(
    FrameLayout.LayoutParams.WRAP_CONTENT,
    FrameLayout.LayoutParams.WRAP_CONTENT,
    Gravity.CENTER))       // LayoutParams 第三个构造参数是 gravity
```

四个容器的定位与取舍：

| 容器 | 定位方式 | 适用 |
|---|---|---|
| `LinearLayout` | 一个方向依次排；`weight` 分剩余空间 | 行/列结构，简单界面首选（本示例用它） |
| `FrameLayout` | 子 View 叠放，默认都挤在左上角，靠 `layout_gravity` 挪 | 叠加层、单子 View 占位容器 |
| `RelativeLayout` | 子 View 互相参照（`layout_below` 等） | 老代码常见；新代码不建议再选 |
| `ConstraintLayout` | 约束系统（平铺解决复杂关系），配套可视化编辑器 | 复杂界面的现代默认选择，需 AndroidX 依赖 |

观点：容器选型宁浅勿深——能用一层 LinearLayout 解决的别套三层；真的复杂了直接上 ConstraintLayout，别用嵌套 LinearLayout 硬拼。布局层级越深，测量与绘制的代价越大（WPF 的 Measure/Arrange 两阶段协商在这里同构，只是步长单位不同）。

## 3. 常用控件速览

| 控件 | 职责 | 代码里最常设的成员 |
|---|---|---|
| `TextView` | 显示文本 | `text`、`textSize`、`textColor` |
| `EditText` | 可输入文本（TextView 的子类） | `hint`、`inputType`、`setText()` |
| `Button` | 按钮（**也是 TextView 的子类**，所以 `button.text` 同样成立） | `text`、`setOnClickListener` |
| `ImageView` | 显示图片 | `setImageResource(...)` |
| `CheckBox` / `Switch` | 勾选状态 | `isChecked`、`setOnCheckedChangeListener` |

值得知道的一点结构常识：Android 传统控件的继承树很浅，文本系控件全是 `TextView` 的后代（EditText、Button 都是），所以 `text` 这套属性一通百通。界面上的大多数需求 = 文本控件家族 + ImageView + 容器，剩下的都是变体。

状态类控件的监听也是同一套 SAM 转换：

```kotlin
val check = CheckBox(this).apply {
    text = "仅看未完成"
    setOnCheckedChangeListener { _, isChecked ->
        toast(if (isChecked) "过滤已开" else "过滤已关")
    }
}
```

## 4. 事件处理与 Toast

`examples/03_button_toast.kt` 全文：

```kotlin
class Example03ButtonToast : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val button = Button(this).apply {
            text = "Click me"
            setOnClickListener {
                Toast.makeText(this@Example03ButtonToast, "clicked", Toast.LENGTH_SHORT).show()
            }
        }
        setContentView(button)
    }
}
```

三处看点：

1. **`setOnClickListener { ... }`**：参数本该是 `View.OnClickListener` 接口对象，Kotlin Lambda 直接 SAM 转换（第 03 章第 6 节）——传统 View 体系的事件入口几乎都是它
2. **`this@Example03ButtonToast`**：`apply` 块内 `this` 指 Button，把 Activity 遮住了；Kotlin 用标签语法显式点名外层的 Activity。这是 Kotlin 标签在 Android 里最常见的出场
3. **`Toast.makeText(context, msg, duration).show()`**：三个参数分别是上下文、文案、时长（只有 `LENGTH_SHORT`/`LENGTH_LONG` 两档）。`context` 的含义是"这段 UI 挂在哪个上下文上"——Toast 需要它来取主题与资源

`makeText(...)` 只是构造 Toast 对象，**`.show()` 才真正显示**——这一行漏了没有任何报错，界面只是安静地什么都不做（常见坑之一）。时长只有两档：`LENGTH_SHORT` 约 2 秒、`LENGTH_LONG` 约 3.5 秒，没有自定义时长的 API，别找。

同一族还有 `setOnLongClickListener { true }`（返回 `true` 表示"事件已消费"，否则长按完还会触发一次 click）——监听器一族全是 SAM 转换的用武之地。

观点：一次性轻提示用 Toast；要常驻或可交互的提示，用 Material 的 Snackbar 或系统通知（[第 10 章](10-system-components.md)）。

## 5. 属性动画

`examples/19_property_animation.kt` 全文：

```kotlin
class Example19PropertyAnimation : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "animate me" }
        setContentView(tv)
        ObjectAnimator.ofFloat(tv, "alpha", 0.2f, 1.0f).apply {
            duration = 600L
            start()
        }
    }
}
```

`ObjectAnimator.ofFloat(target, "alpha", 0.2f, 1.0f)` 逐参数读：

- `tv`：动画作用的对象
- `"alpha"`：属性名——运行时按名字找到 `setAlpha(float)` 方法，**每帧调用一次**，把插值塞进去；`translationX`、`scaleX`、`rotation` 同理
- `0.2f, 1.0f`：起止值；`duration = 600L` 是 600 毫秒；`start()` 启动

与老一代**视图动画（补间动画，view animation）**的一句话差别：补间动画只是把变化"画"在屏幕上，控件的真实位置与点击区域纹丝不动；属性动画改的是对象真实的属性值，控件是真的动了。

体系关系：`ValueAnimator` 是底层引擎（每帧给你插值，你自己决定拿来干嘛），`ObjectAnimator` 是它在"对象的某个属性"上的便捷封装，日常用后者就够。

循环播放与底层引擎的样子：

```kotlin
ObjectAnimator.ofFloat(tv, "rotation", 0f, 360f).apply {
    repeatCount = ValueAnimator.INFINITE    // 无限循环
    repeatMode = ValueAnimator.RESTART      // RESTART 重放；REVERSE 往复
    start()
}

ValueAnimator.ofInt(0, 100).apply {
    addUpdateListener { anim ->             // 每帧回调，插值自己用
        Log.d("Anim", "value=${anim.animatedValue}")
    }
    start()
}
```

## 6. 尺寸单位：px、dp、sp

| 单位 | 全称 | 含义 | 用在哪 |
|---|---|---|---|
| `px` | pixel | 物理像素 | 几乎不要直接用 |
| `dp` | density-independent pixel | 以 160dpi 为基准的抽象单位，同样 dp 数在不同密度屏幕上物理大小近似一致 | 所有布局尺寸 |
| `sp` | scale-independent pixel | dp 之上再跟随系统字体缩放设置 | 文字大小 |

不写单位直接用 px 的问题：同样 `16px`，在低密度屏上是正常字，在高密度屏上就小得看不见。

XML 里写 `16dp` 由系统换算；**代码里没有单位这回事**——`layoutParams.width`、`setPadding(...)` 收的都是 px。dp 转 px 的标准姿势（扩展函数，第 03 章）：

```kotlin
fun Int.toPx(): Int = (this * resources.displayMetrics.density).toInt()

val padding = 16.toPx()      // 16dp → 当前屏幕上的像素数
```

`textSize` 例外：`setTextSize(16f)` 默认按 sp 解释，别再自己乘缩放系数。

## 7. 这套体系的边界

两条边界决定了它的历史位置：

1. **只有主线程能碰 UI**。后台线程改 `textView.text` 直接抛 `CalledFromWrongThreadException`（异常名一眼可辨）。所以网络取回数据必须先回到主线程——`Handler(Looper.getMainLooper())` 的做法与协程方案都在[第 08 章](08-threads-network.md)（`examples/06_handler_looper.kt` 就是前者的实例）
2. **命令式同步是它的原罪**。本章每个示例都是"找到控件 → 设属性"的命令式代码：状态一多，每处变化都要手动同步到每个控件，漏一处就是 bug。Compose 用"声明式 + 自动重组"取代的正是这一层（[第 12 章](12-compose-basics.md)）——把本章当对照组读，Compose 的价值才看得清

## 8. 常见坑

**忘了 `.show()`**。`Toast.makeText(...)` 不调用 `show()` 就什么都不发生，不报错不提示，纯静默。看到"点了没反应"先查这一行。

**context 传谁分不清**。经验法则：跟界面生命周期相关的（Dialog、LayoutInflater）必须用 Activity；活得比界面久的对象（单例、[第 10 章](10-system-components.md)的 Service）用 ApplicationContext，否则 Activity 泄漏。传反的后果也不对称：Dialog 用 ApplicationContext 直接崩（BadTokenException），长命对象抓着 Activity 则是慢性的内存泄漏。Toast 是少数两者皆可的——它不依赖 Activity 窗口，`examples/03` 里传 Activity 只是顺手。

**属性动画与 invalidate 的误解**。从老文档过来的人以为要手动 `invalidate()` 动画才刷新——对 `alpha`、`translationX` 这些 View 内建属性不需要：`ObjectAnimator` 调用的 `setAlpha` 等 setter 内部已触发重绘。真正要 invalidate 的是**自定义属性**：给你的自定义 View 做"progress"这类属性动画时，setter 里不调 `invalidate()`，动画就一格不动。

**代码里把 dp 当 px 用**。`layoutParams.width = 16` 是 16 像素不是 16dp，高密度屏上肉眼几乎看不见。记住第 6 节的换算函数。

**LayoutParams 张冠李戴**。子 View 的 LayoutParams 类型必须匹配父容器——给 LinearLayout 的孩子塞 `FrameLayout.LayoutParams` 会在 addView 时抛 `ClassCastException`。

## 9. 实战建议

- 先选容器再填控件：单行/单列 LinearLayout，叠加 FrameLayout，复杂关系 ConstraintLayout——层级宁浅勿深
- 建控件统一 `Xxx(this).apply { ... }` 的姿势（本教程示例的形状），配置集中一眼读全
- dp 常量与 `toPx()` 换算收进一个文件统一管理，别把魔法数字撒满工程
- 学传统 View 不是怀旧：存量代码全是它，[第 07 章](07-lists-adapters.md)的列表、面试常问的事件分发也都建在这套体系上
- 动画从属性动画学起，补间动画只在做旧代码维护时再补课
- 事件"没反应"先 `Log.d` 打一行确认回调到没到，再怀疑业务逻辑

---
上一章：[04 Activity 与应用生命周期](04-activity-lifecycle.md) ｜ 下一章：[06 Intent 与页面导航](06-intents-navigation.md) ｜ 返回：[README](../README.md)
