# 06 · Material 组件库：搭积木的说明书

> 对应示例：examples/06_material/

## 6.1 解决什么问题

Material 是 Google 的设计系统，Flutter 把它做成了一套**开箱组件库**（`material.dart`；iOS 风格另有一套/cupertino，一句话带过）。第 02 章用过 Scaffold 的三个插槽，本章补全它的六个，并认识信息展示的主力（Card/ListTile/Chip）与按钮家族——掌握这些，"像样的桌面应用"就搭得出来了。

```dart
    // ═══ 6.1 Scaffold：页面骨架的六个插槽 ═══
    return Scaffold(
      appBar: AppBar(title: const Text('Material 组件')),
      // ═══ 6.2 Drawer：侧滑抽屉 ═══
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('菜单')),
            ListTile(leading: Icon(Icons.inbox), title: Text('收件箱')),
            ListTile(leading: Icon(Icons.settings), title: Text('设置')),
          ],
        ),
      ),
      // ═══ 6.3 NavigationBar：M3 底部导航 ═══
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.search), label: '发现'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: _tab == 0 ? const HomeBody() : const Center(child: Text('发现页')),
    );
```

六个插槽速查：

| 插槽 | 内容 | 备注 |
|---|---|---|
| `appBar` | 顶栏 | 配 Drawer 后自动出现菜单图标 |
| `body` | 主内容 | 唯一必想的"正区" |
| `floatingActionButton` | 悬浮按钮 | `FloatingActionButtonLocation` 定位 |
| `drawer` / `endDrawer` | 左/右抽屉 | 内容用 ListView（防溢出安全区） |
| `bottomNavigationBar` | 底部导航 | M3 用 NavigationBar |

**NavigationBar 四件套**（示例 6.3）：`selectedIndex`（当前项，受控状态）+ `onDestinationSelected`（切换回调里 setState）+ `destinations`（图标与标签）+ body 按索引换内容。这是"状态驱动 UI"的标准三步：状态 `_tab` → 回调改状态 → build 按状态出界面（第 08 章把这套讲透）。

### AppBar 的完整参数面

示例只用了 `title`，AppBar 的实际参数面值得知道：

| 参数 | 用途 |
|---|---|
| `title` | 主标题（通常 Text） |
| `leading` | 标题左侧（null 时自动推断：有 Drawer 出菜单图标、可 pop 出返回键） |
| `automaticallyImplyLeading` | false 关掉上面的自动推断（自己完全控制左侧） |
| `actions` | 标题右侧的 Widget 列表（IconButton 一排） |
| `bottom` | AppBar 下方的附加条（TabBar、搜索框常驻区） |
| `elevation` | 阴影高度（M3 默认 0，滚动时自动出现） |
| `centerTitle` | 标题居中（桌面端默认左对齐，移动端默认居中） |

`actions` 的典型形状：

```dart
AppBar(
  title: const Text('收件箱'),
  actions: [
    IconButton(icon: const Icon(Icons.search), onPressed: _search, tooltip: '搜索'),
    IconButton(icon: const Icon(Icons.more_vert), onPressed: _menu, tooltip: '更多'),
  ],
)
```

桌面应用常给 AppBar 配 `bottom: const TabBar(...)` 做标签页（第 32 章 IM 实战的骨架就是）。

## 6.2 信息组件：Card + ListTile + Chip

```dart
        // ═══ 6.4 信息组件：Card + ListTile + Chip ═══
        Card(
          child: ListTile(
            leading: Icon(Icons.article),
            title: Text('卡片标题'),
            subtitle: Text('ListTile 承载一行信息的标准姿势'),
            trailing: Chip(label: Text('新')),
          ),
        ),
```

- **Card**：圆角+阴影的容器，一般直接包一个 ListTile；
- **ListTile**：一行的标准姿势——leading/title/subtitle/trailing 四座位（第 03 章表），自带点击态与合适的内边距，列表里 90% 的行都该是它；
- **Chip**：小标签（状态/计数），`Wrap` 一包就是标签云。

### ListTile 的密度与行数

`dense: true` 让 ListTile 更紧凑（桌面端常用——屏幕大、信息密）；`isThreeLine: true` 开三行副标题（默认两行截断）。`onTap`/`onLongPress` 自带 InkWell 水波纹反馈。

### Chip 的变体

| Chip | 用途 |
|---|---|
| `Chip(label: ...)` | 静态标签 |
| `InputChip` | 输入框里的标签（可删除的已选项） |
| `FilterChip(selected: ...)` | 可切换的筛选条件（选中态自带对勾） |
| `ChoiceChip(selected: ...)` | 单选集合里的一项 |
| `ActionChip` | 带操作的标签（点击触发动作） |

### Badge：图标上的小红点

M3 的 `Badge` 挂在任何 child 上，常见于 IconButton 的未读数：

```dart
Badge.count(
  count: 9,
  child: IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () {},
    tooltip: '通知',
  ),
)
```

`Badge(label: Text('新'), child: ...)` 是任意文案版；`isLabelVisible: false` 隐藏（清空未读时）。`Badge.count` 的 count 超过 99 自动显示 "99+"。

## 6.3 按钮家族：层级递减的选择

| 按钮 | 视觉重量 | 用 |
|---|---|---|
| `FilledButton` | 高（实心） | 页面主操作（每屏最多一个） |
| `FilledButton.tonal` | 中（浅实心） | 次主操作 |
| `OutlinedButton` | 低（描边） | 并列的可选操作 |
| `TextButton` | 最低（纯文字） | 弱操作（取消、了解更多） |
| `IconButton` | 图标 | 工具栏动作（必给 `tooltip`） |
| `FloatingActionButton` | 悬浮 | 全屏级新建/继续 |

选型口诀：**一个主操作配 Filled，其余按重要度降级**。所有按钮的公共点：`onPressed` 必填（`null` = 禁用灰态，`() {}` = 可点无动作——两者不同，第 07 章）。

### 按钮的常用变体

- **`FilledButton.tonal`**：浅实心（背景是 primary 色的低透明度版本）——比 Filled 弱、比 Outlined 强，"次主操作"的专用位。
- **`FilledButton.icon` / `OutlinedButton.icon` / `TextButton.icon`**：带前置图标的版本（`icon: Icon(...), label: Text(...)` 两个参数）。
- **`IconButton.filled` / `IconButton.outlined`**：M3 新增的图标按钮变体——filled 是圆形实心（选中态常用），outlined 是圆形描边。
- **`SegmentedButton<T>`**：分段选择器（单选/多选），替代旧版 ToggleButtons——示例 26 章的平台选择器就是它。

### FloatingActionButton 的定位与变体

`FloatingActionButtonLocation` 控制 FAB 在 Scaffold 里的位置（`endFloat` 默认右下、`centerFloat` 底部居中、`endDocked` 嵌入 NavigationBar）。变体：

- `FloatingActionButton.small`：小一号（列表内嵌操作）
- `FloatingActionButton.large`：大一号（核心 CTA）
- `FloatingActionButton.extended`：带文字的宽版（`icon:` + `label:`）

## 6.4 Drawer 的正确内胆

Drawer 里**用 ListView 开头**（示例 6.2）：它处理了顶部安全区与滚动；直接塞 Column 遇到长内容会溢出。结构惯例：DrawerHeader（或 UserAccountsDrawerHeader）+ 一列 ListTile，点击后记得 `Navigator.pop(context)` 关抽屉再跳页面。

`UserAccountsDrawerHeader` 是带用户信息的现成头部（头像 + 用户名 + 邮箱）：

```dart
DrawerHeader(
  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
  child: const Text('菜单'),
)
```

## 6.5 进度与状态：ProgressIndicator / SnackBar / Tooltip

### ProgressIndicator

| 组件 | 形状 | 场景 |
|---|---|---|
| `CircularProgressIndicator` | 转圈 | 加载中（不明确进度） |
| `LinearProgressIndicator` | 横条 | 顶部进度条、下载进度 |

两种模式：**indeterminate**（不传 value，无限循环动画——"在加载但不知道多久"）和 **determinate**（传 `value: 0.0~1.0`，按百分比填充——"下载 60%"）。`LinearProgressIndicator` 的 `minHeight` 控制线宽，`color` 改填充色、`backgroundColor` 改轨道色。

```dart
// 明确进度：下载 60%
LinearProgressIndicator(value: 0.6)
// 不明确进度：转圈等待
const CircularProgressIndicator()
```

### SnackBar：底部轻提示

`ScaffoldMessenger.of(context).showSnackBar(...)` 弹出底部提示条（2 秒自动消失，可带操作按钮）：

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('已保存'),
    action: SnackBarAction(label: '撤销', onPressed: _undo),
  ),
);
```

细节：`showSnackBar` 会顶掉当前未消失的 SnackBar（同屏最多一条）；`ScaffoldMessenger` 是 MaterialApp 内置的（不需要自己创建）——第 07 章交互章会展开。

### Tooltip：悬停提示

桌面端必备——鼠标悬停显示功能说明：

```dart
IconButton(
  icon: const Icon(Icons.delete),
  onPressed: _delete,
  tooltip: '删除',  // 桌面悬停显示；也服务无障碍（屏幕阅读器朗读）
)
```

`Tooltip(message: '...', child: ...)` 也可以包任意 widget。无障碍角度 tooltip 不是装饰——屏幕阅读器用户靠它知道按钮干什么。

## 坑位清单

- **NavigationBar 与 BottomNavigationBar**：后者是 M2 旧组件，新代码用前者；参数名不同（destinations vs items）。
- **Card 默认 margin**：4 逻辑像素，紧贴边缘的设计要么接受要么 `margin: EdgeInsets.zero`。
- **ListTile 长文案溢出**：subtitle 多行默认截断到两行（`isThreeLine` 开三行）；真长文本换自己的布局。
- **Drawer 项点击无反应**：忘写 `Navigator.pop`——抽屉盖在页面上，不关掉看不见跳转效果。
- **SnackBar 不显示**：在 AppBar 的 action 回调里用错了 context（AppBar 的 context 不在 Scaffold 下）——用 Builder 或外层 context 拿 ScaffoldMessenger。
- **IconButton 忘 tooltip**：桌面用户不知道图标按钮干什么——所有 IconButton 必给 tooltip（无障碍刚需）。
- **进度条模式混用**：明确进度传 value、不明确不传——"下载中"不传 value 用户以为卡死。
---

上一章：[05 · 布局 II：线性、弹性与层叠](05-layout-multi.md) ｜ 下一章：[07 · 交互与对话框：点击、轻提示、确认](07-interaction.md) ｜ 返回：[README](../README.md)
