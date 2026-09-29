# 12 · 传统 View 深水区：布局、菜单与样式

> 对应示例：`examples/22_layouts_menus_styles.kt`。取材：李刚《疯狂Android讲义（第3版）》第 2 章（界面编程）、第 6 章（资源）——05 章讲了 LinearLayout/FrameLayout 与核心控件，本章补全布局全家、对话框、三种菜单、样式主题与 Drawable 七类，是读存量代码的"组件字典"。

## 1. 布局全家：从线性到网格

05 章只展开了 LinearLayout 与 FrameLayout。真实的存量工程里还有四位常客，一张表先立全貌：

| 布局 | 排列逻辑 | 关键属性/方法 | 现状 |
|---|---|---|---|
| `LinearLayout` | 一个方向依次排 | `orientation`、`weight` | 活着，简单行/列首选 |
| `FrameLayout` | 子 View 叠放 | `layout_gravity` | 活着，叠加层/占位容器 |
| `TableLayout` | 行×列表格（LinearLayout 子类） | `stretchColumns` 等 | 活着，纯表单场景仍好用 |
| `RelativeLayout` | 子 View 互相参照 | `layout_below` 等 | 存量大量存在，新代码别选 |
| `GridLayout` | 行×列网格 + 跨度 | `columnCount`、`spec(row, span)` | 活着，键盘/相册类界面 |
| `AbsoluteLayout` | 绝对坐标 | `layout_x`/`layout_y` | **已删除**——只在博物馆里 |

### TableLayout：列是"报名制"

TableLayout 不需要声明几行几列：**加一个 `TableRow` 就多一行，TableRow 里加一个子 View 就多一列**；直接向 TableLayout 加 View 则该 View 独占一行。列宽由该列最宽的单元格决定。列的三种行为（书 2.2.2 的术语值得记住，报错和文档里都会出现）：

- **Stretchable（可拉伸）**：`setColumnStretchable(col, true)`——剩余宽度灌给这一列
- **Shrinkable（可收缩）**：`setColumnShrinkable(col, true)`——空间不够时压窄这一列保住整表
- **Collapsed（可折叠）**：`setColumnCollapsed(col, true)`——整列隐藏

```kotlin
val table = TableLayout(this).apply {
    setColumnStretchable(1, true)          // 第 2 列吃掉剩余宽度
    setColumnCollapsed(2, false)
}
table.addView(Button(this).apply { text = "独占一行的按钮" })   // 不裹 TableRow = 整行
table.addView(TableRow(this).apply {
    addView(TextView(this).apply { text = "姓名" })
    addView(EditText(this))                                   // 拉伸列
})
```

### GridLayout：计算器界面的标准解

GridLayout（API 14 加入）把容器划成 `rows × columns` 的格子，子 View 用 `GridLayout.spec(行, 列)` 声明落点，还能**横跨多列**——书的"计算器界面"实例就是这个套路：显示屏跨 4 列，下面 16 个按键各占一格（`examples/22_layouts_menus_styles.kt` 里的 `Example22GridLayout` 完整复刻）：

```kotlin
val grid = GridLayout(this).apply { columnCount = 4 }
grid.addView(TextView(this).apply { text = "0" }, GridLayout.LayoutParams(
    GridLayout.spec(0, 4, GridLayout.FILL),    // 第 0 行起、跨 4 列、填满
    GridLayout.spec(0, GridLayout.FILL)).apply {
    width = GridLayout.LayoutParams.MATCH_PARENT
})
// 循环放 16 个按键：spec(i / 4 + 2), spec(i % 4)
```

两个易混点：`spec(a, b)` 的第二个参数是**跨度不是终点**；`GridLayout.FILL` 是对齐方式（撑满格子），与 `MATCH_PARENT` 是两套话语体系。

### 布局嵌套的纪律

书里反复演示"LinearLayout 套 LinearLayout"是 2010 年代的历史局限，现代纪律不变：**层级宁浅勿深**（测量代价随深度指数涨），复杂关系上 ConstraintLayout（05 章表），表格结构用 GridLayout 而不是三层 LinearLayout 模拟。

## 2. 控件动物园速查

传统控件按继承家族归类才记得住（书 2.3–2.8 的分组思路）。每行末列是 2026 年视角的现状校准——**书里能跑、今天仍能编译，但工程价值要分层**：

| 家族 | 成员 | 一句话 | 现状 |
|---|---|---|---|
| 文本系（TextView 后代） | `EditText`、`Button`、`CheckedTextView`、`AutoCompleteTextView` | `text`/`hint`/`inputType` 一通百通 | 全部活着 |
| 图片系 | `ImageView`、`ImageButton`、`QuickContactBadge` | `setImageResource` | 前两者常用；Badge 罕见 |
| 开关系 | `CheckBox`、`RadioButton`、`ToggleButton`、`Switch`、`RadioButton`+`RadioGroup` | `isChecked` + 监听器 | 活着；新 UI 常换 Material 版本 |
| 进度系（ProgressBar 后代） | `SeekBar`、`RatingBar` | `max`/`progress`；前者可拖、后者打星（`numStars`、`stepSize`） | 活着 |
| 切换器系（ViewAnimator 后代） | `ViewSwitcher`、`ImageSwitcher`、`TextSwitcher`、`ViewFlipper` | FrameLayout + 切换动画，`setFactory`/`showNext` | 能用但式微——ViewPager2/Compose 替代 |
| 时间系 | `AnalogClock`、`TextClock`、`Chronometer`（计时器）、`DatePicker`、`TimePicker`、`CalendarView`、`NumberPicker` | TextClock 走系统时区；Chronometer `base`/`start` | 活着 |
| 杂项 | `SearchView`、`ScrollView`、`ZoomControls` | SearchView 配 ActionBar/Toolbar 当搜索框 | 前两者常用 |

三处值得展开：

**SeekBar 与 RatingBar 是 ProgressBar 的亲儿子**。所以 `max`、`progress`、`secondaryProgress` 直接可用；SeekBar 加 `setOnSeekBarChangeListener`（`onProgressChanged`/`onStartTrackingTouch`/`onStopTrackingTouch` 三回调——**取值要 `fromUser` 为 true 才响应用户**，否则程序设进度也会触发），RatingBar 加 `setOnRatingBarChangeListener`。SeekBar 的 `thumb`（滑块）与 `progressDrawable`（轨道）都可以换 Drawable——6 节的 LayerDrawable 正是定制轨道的官方姿势。

**Chronometer 是最省事的计时器**：`base = SystemClock.elapsedRealtime()` 归零，`start()` 开始，`format` 里可用 `%s` 占位。它内部就是 Handler + 定时 invalidate，等于官方帮你写了一个。

**9-Patch 图片**（书 2.3.4）：`.9.png` 在图片四周画黑线标记"可拉伸区"与"内容区"，让按钮背景在任意大小下边角不糊。工具从 `draw9patch` 演进为 Android Studio 内置的 9-Patch 编辑器；Material 时代的 `inset`/`shape` Drawable 已覆盖大部分需求，但聊到老项目的 `.9.png` 你得知道是什么。

## 3. 对话框全家：AlertDialog 的六种内容

书 2.9 的精华是一张结构图：**AlertDialog = 图标区 + 标题区 + 内容区 + 按钮区**，按钮区最多三个（Positive/Negative/Neutral）。创建走 `AlertDialog.Builder` 链，**内容区有六种填法**，这是它的全部灵活性：

| 填法 | 内容形态 |
|---|---|
| `setMessage(...)` | 纯文本 |
| `setItems(数组, 监听)` | 单击列表 |
| `setSingleChoiceItems(数组, 默认项, 监听)` | 单选列表 |
| `setMultiChoiceItems(数组, boolean[], 监听)` | 多选列表 |
| `setAdapter(适配器, 监听)` | 自定义列表项 |
| `setView(view)` | 任意自定义 View |

`Example22Dialogs`（示例文件里）演示了三种最常用形态：

```kotlin
AlertDialog.Builder(this).apply {
    setTitle("删除确认")
    setMessage("这份便签将永久删除")
    setPositiveButton("删除") { _, _ -> toast("已删除") }
    setNegativeButton("取消", null)          // null = 关掉就算
    setNeutralButton("详情") { _, _ -> /* ... */ }
}.show()                                     // Builder 上直接 show() 等价于 create().show()
```

三个校正（书成书于 2015，之后世界变了）：

1. **`ProgressDialog` 已废弃**（API 26 起官方劝退）：进度对话框的现代替代是"界面内嵌 ProgressBar/进度条 + 状态文本"或 ViewModel 暴露进度状态——书里那套 `ProgressDialog.show(...)` 在新工程里别再写
2. **主题即外观**：framework 的 `AlertDialog` 长什么样由主题决定；Material Components 的 `MaterialAlertDialogBuilder` 是现代工程的主流（依赖 material 库），Builder 六法完全同构——**学的是六法，不是那个类**
3. **`DatePickerDialog`/`TimePickerDialog` 仍在**：`DatePickerDialog(context, 监听, 年, 月, 日)` 一行弹出，监听回传用户选择；它们不改系统时间，只是选择器

`PopupWindow` 与对话框的差异：Dialog 是模态的（抢占焦点），**PopupWindow 是浮层**——`showAsDropDown(anchor)` 挂在某控件下方，`showAtLocation(parent, gravity, x, y)` 指定绝对位置，`dismiss()` 收起。适合"点击头像弹出资料卡"这类轻交互。示例文件里 `Example22PopupWindow` 给了最小骨架（要点：`isFocusable = true` 才能吃返回键关闭，宽高必须显式给 `WRAP_CONTENT` 起）。

## 4. 三种菜单

传统菜单三件套，全部经手 `Menu`/`MenuItem` 接口（书 2.10）：

| 菜单 | 入口 | 触发方式 |
|---|---|---|
| 选项菜单 options | `onCreateOptionsMenu(menu)` 填充 | 菜单键/Toolbar 溢出按钮 |
| 上下文菜单 context | `registerForContextMenu(view)` + `onCreateContextMenu(...)` | **长按**该控件 |
| 弹出菜单 popup | `PopupMenu(context, anchor)` | 代码 `show()` |

```kotlin
class Example22Menus : Activity() {
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menu.add(0, 1, 0, "新建")                       // groupId, itemId, order, title
        menu.add(0, 2, 1, "排序").subMenu?.apply {       // 子菜单：不支持图标、不可再嵌套
            add("按时间"); add("按名称")
        }
        return true                                     // false = 不显示菜单
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean = when (item.itemId) {
        1 -> { toast("新建"); true }                     // 返回 true = 已消费
        else -> super.onOptionsItemSelected(item)
    }
}
```

四条规矩（书里都有，值得背下来）：选项菜单**不支持勾选**、子菜单**不支持图标与嵌套**、上下文菜单**不支持快捷键与图标**、菜单项 `itemId` 是 `onOptionsItemSelected` 里分发的唯一依据——所以添加时必须给 ID。勾选态系统**不替你维护**：`item.isChecked = !item.isChecked` 要自己写（书原文吐槽过的"奇怪之处"，至今如此）。

**XML 菜单资源**（`res/menu/*.xml`，根元素 `<menu>`，子元素 `<item>`/`<group>`）是真实工程的主流写法，`menuInflater.inflate(R.menu.main, menu)` 一行加载；`<group>` 的 `checkableBehavior="single|all|none"` 直接声明单选/多选组。本教程示例无 aapt 参与，故演示代码建菜单——两种形态在文档里对得上号即可。

**历史坐标**：书 2.11 整节讲 ActionBar——它已被 **Toolbar**（support 库，可放进布局的任意位置）取代，菜单转而显示在 Toolbar 上；`onCreateOptionsMenu` 这套填充机制则原样保留。TabHost/ActionBar Tab 导航同理已被 TabLayout + ViewPager2 取代。读老代码认识它们，写新代码用 Toolbar。

## 5. 样式与主题

样式（Style）= **一组格式属性的命名集合**；主题（Theme）= **作用于整个窗口/应用的样式**。二者在 XML 里是同一种东西（`<style>`），差别只在作用域与挂法（书 6.9）：

```xml
<!-- res/values/styles.xml -->
<style name="NoteTitle">                       <!-- name：引用键 -->
    <item name="android:textSize">20sp</item>
    <item name="android:textColor">#111111</item>
</style>
<style name="NoteTitle.Warning">               <!-- 点号 = 继承 NoteTitle -->
    <item name="android:textColor">#CC0000</item>   <!-- 覆盖一项，其余沿用 -->
</style>
```

```xml
<!-- 布局里用样式（单个 View） -->
<TextView style="@style/NoteTitle" ... />
<!-- 清单里挂主题（application 全部窗口或单个 activity） -->
<application android:theme="@style/Theme.MyApp" ... />
```

继承两种写法要分清：`name="A.B"` 是**隐式继承**（B 继承 A）；`parent="A"` 是**显式继承**——覆盖系统主题时必须用显式（`parent="android:Theme.Material.Light"` 之类），隐式写法对系统主题无效。

代码侧与样式/主题的接触点只有一个，但很重要：`obtainStyledAttributes` 把主题/样式解析成 `TypedArray` 读值，自定义 View 的 XML 属性就是经它取出（13 章自定义 View 会真正用上）。用完必须 `recycle()`——对象是池化复用的。

**主题沿革坐标**（读老工程时对号入座）：书时代的 `Theme.Material`（Android 5.0）→ AppCompat 的 `Theme.AppCompat.*` → Material Components 的 `Theme.MaterialComponents.*` → `Theme.Material3.*`；Compose 则完全绕开 XML 主题，用 `MaterialTheme` 组合函数（20 章）。层级里的对应物变了，"主题=窗口级格式集合"这个概念没变。

## 6. Drawable 七类

Drawable 是"可绘制物"的抽象——图片只是最朴素的一种。书 6.4 按类过了一遍，这张表是存量代码的解码器：

| Drawable | XML 根元素 | 干什么 | 代码等价物 |
|---|---|---|---|
| `BitmapDrawable` | `<bitmap>` | 包一张位图（可设平铺/重力） | `BitmapDrawable(resources, bmp)` |
| `StateListDrawable` | `<selector>` | **按状态换图**（pressed/focused/checked…） | `addState(intArrayOf(...), d)` |
| `LayerDrawable` | `<layer-list>` | 多层叠画（后面的盖前面） | `LayerDrawable(arrayOf(d1, d2))` |
| `ShapeDrawable` | `<shape>` | 几何图形：圆角/渐变/描边 | **`GradientDrawable`**（代码侧主类） |
| `ClipDrawable` | `<clip>` | 按 level(0–10000) 裁剪显示 | `ClipDrawable(d, gravity, HORIZONTAL)` |
| `AnimationDrawable` | `<animation-list>` | 逐帧动画（14 章主角） | `addFrame(d, 时长ms)` |
| `LevelListDrawable` | `<level-list>` | 按 level 换整图 | `addLevel(下限, 上限, d)` |

**每种 XML Drawable 都有代码等价物**——这正好契合本教程"无 aapt、纯代码验证"的模式，`Example22Drawables` 全部用代码构建：

```kotlin
// shape：圆角渐变底（XML <shape> 的代码真身是 GradientDrawable）
val shape = GradientDrawable().apply {
    shape = GradientDrawable.RECTANGLE
    cornerRadius = 12f
    colors = intArrayOf(0xFF6699FF.toInt(), 0xFF3366CC.toInt())   // 渐变两端
    orientation = GradientDrawable.Orientation.TL_BR
    setStroke(2, 0xFF113366.toInt())                              // 描边
}

// selector：按下变深（按钮/输入框高亮就靠它）
val selector = StateListDrawable().apply {
    addState(intArrayOf(android.R.attr.state_pressed), ColorDrawable(0xFF3366CC.toInt()))
    addState(intArrayOf(android.R.attr.state_enabled), ColorDrawable(0xFF6699FF.toInt()))
}

// clip：像"展开画卷"一样按进度显示（书里"徐徐展开的风景"）
val clip = ClipDrawable(ColorDrawable(0xFF4C4C1D.toInt()), Gravity.LEFT, ClipDrawable.HORIZONTAL)
```

三个实战要点：

- **`setLevel()` 是Drawable 的通用旋钮**：ClipDrawable 按 level 裁剪、LevelListDrawable 按 level 换图、ProgressBar 的进度视觉本质也是 level——取值恒为 **0–10000**（10000 = 满），不是百分比
- **StateListDrawable 的状态顺序敏感**：从上往下第一个全匹配的 item 生效，所以**具体状态写在前面、兜底状态（空状态数组）写在最后**
- **LayerDrawable 定制 SeekBar 轨道**是书里的经典配方：底层背景轨 + 上层进度轨（id 设为 `android:id/progress`），系统自动把进度映射到上层——14 章动画和实战项目还会遇到

## 7. 常见坑

**`addView` 的 LayoutParams 张冠李戴**（05 章坑的续集）：TableLayout 的孩子是 TableRow.LayoutParams，GridLayout 的孩子是 GridLayout.LayoutParams——塞错类型在测量期抛 `ClassCastException`。 GridLayout 尤其隐蔽：不用 `GridLayout.LayoutParams` 包裹时 `spec` 不生效，控件全部挤在 (0,0)。

**菜单勾选态"点了没反应"**：`setGroupCheckable` 只让菜单项可勾，视觉翻转要自己 `item.isChecked = !item.isChecked`——系统不代劳。

**StateListDrawable 只换"背景类"属性**：它换的是它被挂在的那个槽位（background/thumb/textColor 的 selector 版是 ColorStateList，另一个类）——想让**文字颜色**随状态变，得用 `ColorStateList`，不是 StateListDrawable。

**`PopupWindow` 不设 `isFocusable` 收不掉**：`showAsDropDown` 之后按返回键没反应、点外面也不关——`isFocusable = true`（吃返回键）与 `isOutsideTouchable = true`（点外关闭）至少设一个，且宽高必须显式构造参数，默认 0 会导致不可见。

**主题继承用点号写法覆盖系统主题无效**：`name="Base.Mine"` 只能继承自家样式；改系统主题必须 `parent=`。这是 XML 静默失败的典型——不报错，只是样式没生效。

**`TypedArray` 忘了 `recycle()`**：不崩但泄漏池化对象，Lint 会黄牌。老代码里高频。

## 8. 实战建议

- 新界面第一反应仍是：行/列 LinearLayout、叠加 FrameLayout、复杂 ConstraintLayout；**表格结构才想起 TableLayout/GridLayout**，别用三层嵌套线性模拟表格
- 对话框六法记"setMessage/setItems/setSingleChoiceItems/setMultiChoiceItems/setAdapter/setView"——新工程把 `AlertDialog.Builder` 换成 `MaterialAlertDialogBuilder`，六法原样平移
- 菜单优先 XML 资源（`res/menu/`），代码建菜单只出现在无资源管线的教学/工具场景
- Drawable 分层记忆：**形状用 GradientDrawable、状态用 StateListDrawable、层级用 LayerDrawable、进度用 ClipDrawable**——四件套覆盖 90% 的存量样式文件
- 本仓示例刻意全走"代码建 X"路线：XML 与代码两条路一一对应（`<shape>`↔`GradientDrawable`、`<selector>`↔`StateListDrawable`），读 XML 工程时按这张对照表反向翻译
- 学完这章配合 05 章重读一遍：控件字典 + 布局纪律齐了，13 章开始自己造控件

---
上一章：[11 权限、ContentResolver 与硬件](11-permissions-content.md) ｜ 下一章：[13 自定义 View 与绘图](13-custom-view-drawing.md) ｜ 返回：[README](../README.md)
