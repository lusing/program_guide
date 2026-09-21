# 07 · 列表与 Adapter 模式

> 对应示例：`examples/05_listview_adapter.kt`

## 1. 列表问题的本质：数据无限，视图有限

列表是移动端第一界面形态。直觉写法是第 05 章思路的推广：`for` 循环 `new` 一百个 `TextView` 塞进 `LinearLayout`。为什么这条路走不通？

- **内存**：每个控件都是一个对象树（外加大量测量/布局缓存），一千条数据就是一千份完整控件，中低端机直接吃满
- **创建成本**：inflate + 测量 + 布局都是实打实的 CPU 时间，滚动列表每秒要进出几十行，现场造视图根本来不及
- **滚动**：线性布局装进 ScrollView 后，滚到第 500 条时前面 499 条依然活着——你的列表越长越卡

| | for 循环造满 | 列表控件 + 复用 |
|---|---|---|
| 视图数量 | = 数据条数（1000 条 1000 份） | ≈ 一屏 + 缓冲（十来份） |
| 内存 | 随数据线性增长，长列表直接爆 | 常数级 |
| 滚动性能 | 现造视图，越滚越卡 | 换内容不换"壳"，稳定流畅 |
| 数据更新 | 手动找到对应控件逐个改 | 通知 Adapter，统一重绑 |

破局点是一个观察：**任何时刻用户只看得到一屏**。屏幕显示 10 行，就只需要 10 份行视图（再加几行滚动缓冲）；滚出屏幕的行视图回收，改头换面给滚进来的行用。这就是**视图复用（view recycling）**，列表控件的一切复杂度都在为它服务。

而"数据集合 ↔ 有限视图"之间需要一个翻译官——它知道数据有多少条、第 N 条是什么、第 N 条长什么样。这个角色的设计模式就叫 **Adapter（适配器）**。

## 2. Adapter：数据与视图之间的合同

`examples/05_listview_adapter.kt` 用最短的路径跑通了这条合同：

```kotlin
class Example05ListViewAdapter : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val listView = ListView(this)
        val data = listOf("Kotlin", "Compose", "JNI", "Gradle")
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, data)
        listView.adapter = adapter
        setContentView(listView)
    }
}
```

三行核心：

1. `ArrayAdapter(this, android.R.layout.simple_list_item_1, data)`——三个参数分别是 Context、**行模板布局**、数据集。`simple_list_item_1` 是系统自带的"单个 TextView"行布局，不用自己写 XML
2. `listView.adapter = adapter`——即 `setAdapter`，把翻译官交给列表，触发首轮绑定与测量
3. `ArrayAdapter` 的内部逻辑朴素到一句话：把 `data[position]` 调 `toString()` 塞进模板里的 TextView

点击也不在 Adapter 里，在 ListView 上：

```kotlin
listView.setOnItemClickListener { _, _, position, _ ->
    Toast.makeText(this, "点了 ${data[position]}", Toast.LENGTH_SHORT).show()
}
```

四个参数是 parent / view / position / id，日常只用到 position——拿它回数据集取那条数据。这个设计透露了职责切分：**Adapter 管"长什么样"，ListView 管"点了谁"**。

ArrayAdapter 覆盖"纯字符串列表"足够了。但一旦每行不止一段文本（标题 + 日期 + 图标），就要落到它的父类合同上——`BaseAdapter` 四个方法：

| 方法 | 职责 |
|---|---|
| `getCount()` | 数据有多少条（列表靠它决定高度与滚动范围） |
| `getItem(position)` | 第 position 条数据是什么 |
| `getItemId(position)` | 第 position 条的稳定 id（快速滚动/选中态用） |
| `getView(position, convertView, parent)` | **把第 position 条翻译成一个 View**——每行的诞生地 |

ListView 自己不懂数据，它只在滚动时按需追问 Adapter："position 12 长什么样？"——这就是合同的全部。

## 3. getView 与 convertView：复用发生在哪里

自定义一个 Adapter，标准写法（行模板继续借用系统资源，保证每个符号都真实可用；换成你自己的 `R.layout.item_xxx` 就是生产写法）：

```kotlin
class StringAdapter(context: Context, private val data: List<String>) : BaseAdapter() {
    override fun getCount() = data.size
    override fun getItem(position: Int): Any = data[position]
    override fun getItemId(position: Int) = position.toLong()

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val view = convertView ?: LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        view.findViewById<TextView>(android.R.id.text1).text = data[position]
        return view
    }
}
```

关键在第二个参数 `convertView`。ListView 只创建"一屏多几行"数量的 View；某行滚出屏幕，它的 View 被回收入池；新行滚进来时，ListView 把池里那位作为 `convertView` 递给你——**非 null 就直接用，千万别再 inflate**。上面的 `?:` 正是这个判断：为 null（首屏，池子还空着）才造新视图。

`inflate(..., parent, false)` 三个参数也有讲究：传 parent 让行布局拿到正确的 LayoutParams，`false` 则只借用不挂载（挂进 ListView 是列表自己的事）。

一次滚动的完整循环：

```text
行滚入 ──▶ ListView 从回收池取 View ──▶ getView(position, 复用View, parent)
                                          │
                                          ▼
                                  Adapter 用 data[position] 改写复用 View 的内容
                                          │
行滚出 ◀── 该 View 退场，进回收池 ◀────────┘
```

## 4. ViewHolder：findViewById 也是开销

判空复用解决了"重复造视图"，但每行还剩一次 `findViewById`——它沿行视图树**遍历查找**。单行两三个控件时无感，行布局一复杂（头像、标题、副标题、角标、按钮）乘上滚动的调用频率，就是肉眼可见的掉帧。

**ViewHolder 模式**：把查到的控件引用缓存进一个小对象，挂在 View 的 `tag` 上随视图一起复用：

```kotlin
private class ViewHolder(val text: TextView)

override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
    val view: View
    val holder: ViewHolder
    if (convertView == null) {
        view = LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        holder = ViewHolder(view.findViewById(android.R.id.text1))
        view.tag = holder
    } else {
        view = convertView
        holder = view.tag as ViewHolder
    }
    holder.text.text = data[position]
    return view
}
```

代价是每个 getView 多一次判空和一次 `as` 转型，收益是 findViewById 从"每行每次"降为"每个复用体一次"。观点：ListView 时代 ViewHolder 是民间最佳实践——不写不报错，只是慢；RecyclerView 干脆把它升格为强制，写法上想偷懒都不行。

## 5. 数据更新：notify 家族

还差一块拼图：**Adapter 不观察数据**。它是被动翻译官——`data` 集合改了，界面纹丝不动；必须由你通知它"数据变了"：

| 方法 | 效果 | 属于 |
|---|---|---|
| `notifyDataSetChanged()` | 全量刷新：所有可见行重新走一遍 getView / onBindViewHolder | ListView 与 RecyclerView 都有 |
| `notifyItemInserted(position)` | 声明 position 处插入了一项，只处理该位置 | RecyclerView |
| `notifyItemRemoved(position)` | 声明 position 处移除了一项 | RecyclerView |
| `notifyItemChanged(position)` | 声明 position 项内容变了，只重绑它 | RecyclerView |

全量刷新是万能但最贵的选项：丢动画、丢滚动上下文、长列表白白重绑。精确通知省资源，但要求你准确说出"哪里怎么变了"——说错位置就是界面错乱。两难的自动化解法是 DiffUtil，见下节。

## 6. ListView → RecyclerView：继任者强在哪

RecyclerView（2014 年随 Android 5.0 推出）是 ListView 的官方继任者，把"复用"内核保留、把外围职责重新切分：

| | ListView | RecyclerView |
|---|---|---|
| ViewHolder | 可选，自己写自己存 `tag` | **强制**——`onCreateViewHolder` 的返回类型就是 ViewHolder |
| 布局方式 | 只会纵向排 | `LayoutManager`：Linear / Grid / StaggeredGrid 可换 |
| 更新通知 | `notifyDataSetChanged()` 全量 | 精确通知 + `DiffUtil` 自动差分 |
| 增删动画 | 无内置 | `ItemAnimator` 内置增删移动动画 |
| 点击事件 | `setOnItemClickListener` 一行 | 自己在绑定回调里挂（灵活但要自己写） |

标准写法（依赖 `androidx.recyclerview:recyclerview`）：

```kotlin
class StringRecyclerAdapter(private val data: List<String>) :
    RecyclerView.Adapter<StringRecyclerAdapter.ItemViewHolder>() {

    class ItemViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val text: TextView = view.findViewById(android.R.id.text1)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        return ItemViewHolder(view)
    }

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        holder.text.text = data[position]
    }

    override fun getItemCount() = data.size
}
```

使用处两行：

```kotlin
recyclerView.layoutManager = LinearLayoutManager(context)
recyclerView.adapter = StringRecyclerAdapter(data)
```

点击则回到对比表里"要自己写"的形态——构造参数多传一个 lambda，绑定时挂到行视图上：

```kotlin
class StringRecyclerAdapter(
    private val data: List<String>,
    private val onItemClick: (String) -> Unit          // 新增：点击回调
) : RecyclerView.Adapter<StringRecyclerAdapter.ItemViewHolder>() {

    // ItemViewHolder / onCreateViewHolder / getItemCount 与上面相同

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        holder.text.text = data[position]
        holder.itemView.setOnClickListener { onItemClick(data[position]) }   // 新增
    }
}
```

```kotlin
recyclerView.adapter = StringRecyclerAdapter(data) { item ->
    Toast.makeText(this, "点了 $item", Toast.LENGTH_SHORT).show()
}
```

三行代码换来完全的掌控权——点击、长按、某几项禁用都在你手里，这正是"自己写"的代价与回报。

对照第 3~4 节立刻能看懂：`onCreateViewHolder` = "convertView 为 null 时"的那半边（造视图 + 建 ViewHolder，框架保证只在该造时调用）；`onBindViewHolder` = "拿到复用体后改写内容"的那半边。你已经手动做过的事情，RecyclerView 把它拆成两个明确的回调，复用逻辑框架包办。

频繁增删的列表再配 `DiffUtil`：新旧列表喂给它，它算出差异并自动产出精确通知序列。更省事的是直接继承 `ListAdapter`（RecyclerView.Adapter 的差分子类），连通知都不用手调：

```kotlin
class StringListAdapter : ListAdapter<String, StringListAdapter.ItemViewHolder>(DIFF) {
    // onCreateViewHolder / onBindViewHolder / ItemViewHolder 与上面完全相同

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<String>() {
            override fun areItemsTheSame(oldItem: String, newItem: String) = oldItem == newItem
            override fun areContentsTheSame(oldItem: String, newItem: String) = oldItem == newItem
        }
    }
}
```

使用时只调 `adapter.submitList(newData)`——差分、精确通知、动画全由它代办。观点：**新代码没有理由再写 ListView**；学 ListView 的意义一是海量存量代码，二是 Adapter 思想本身——它是理解一切列表方案的地基。

## 7. Compose：LazyColumn 一行的事

第 12 章的 Jetpack Compose 里，同样的列表只剩一个概念：

```kotlin
LazyColumn {
    items(data) { item ->
        Text(item)
    }
}
```

没有 Adapter、没有 ViewHolder、没有 notify——Compose 的组合与重组机制天然按需构建可见项，"复用"下沉为框架内部的实现细节。想给条目稳定身份（避免增删时状态错位），加个 key 即可：`items(data, key = { it })`。但请留意思想上的血缘：`LazyColumn` 的"lazy（惰性组合）"与 RecyclerView 的"recycle（回收复用）"解决的是同一个问题——**数据无限，视图有限**。传统体系里你手写的每一处复用技巧，都在帮你理解声明式方案为什么这样设计（详见[第 12 章](12-compose-basics.md)；key 的语义、增删动画与横向列表在[第 13 章](13-compose-ui.md)展开）。

## 8. 常见坑

**getView 不判 convertView 直接收**：每行都 inflate，滚动时对象疯狂创建，GC 频繁、帧率跳水。判空复用是写自定义 Adapter 的底线，不是优化项。

**notifyDataSetChanged 当万能药**：它让所有可见行全部重绑——丢动画、丢精细更新机会，还掩盖了"数据到底怎么变"这个信息（第 5 节）。增删改用精确通知；差分麻烦就上 DiffUtil / ListAdapter。反过来，改了集合**不调任何 notify**，界面纹丝不动——Adapter 不观察数据，这是另一半经典 bug。

**getView / onBindViewHolder 里做重活**：同步读文件、解码大图、复杂计算都发生在滑动的渲染路径上——每秒几十次调用，任何"看起来没事"的重活乘以 60 都是灾难。重活丢后台（第 08 章的线程模型），绑定回调只做"填数据"。

**复用导致状态串位**：item 里的 CheckBox / 开关状态跟着 View 复用"记忆"了上一个 position 的值——用户勾了第 3 行，滚一圈回来第 15 行也是勾选态。绑定时必须**显式重置每个可变控件**，不要依赖复用体上次的残留。

**在 Adapter 里做业务**：点击某行后直接在 Adapter 里 startActivity、请网络——翻译官兼职干业务，很快变成谁都不敢动的上帝类。点击用构造参数传入的 lambda 回调出去，业务留在页面/ViewModel 层。

## 9. 实战建议

- 新列表一律 RecyclerView（传统工程）或 `LazyColumn`（Compose 工程，第 12 章）；ListView 只在维护旧代码时才会遇到
- Adapter 保持"翻译器"身份：只做 position → 视图的映射；点击回调用 lambda 注入，别让 Adapter 持有 Activity 干业务
- 图片加载交给 Coil / Glide 这类库（异步、缓存、生命周期安全一揽子解决），不要在 getView 里自己解码 Bitmap
- 频繁增删的列表用 `ListAdapter` + `DiffUtil`（把差分与通知自动化），别手搓 notify 序列
- item 布局层级越扁越好：行内嵌套越深，每帧测量布局成本越高，滚动越肉

---
上一章：[06 Intent 与页面导航](06-intents-navigation.md) ｜ 下一章：[08 线程、Handler 与网络请求](08-threads-network.md) ｜ 返回：[README](../README.md)
