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

## 6.4 Drawer 的正确内胆

Drawer 里**用 ListView 开头**（示例 6.2）：它处理了顶部安全区与滚动；直接塞 Column 遇到长内容会溢出。结构惯例：DrawerHeader（或 UserAccountsDrawerHeader）+ 一列 ListTile，点击后记得 `Navigator.pop(context)` 关抽屉再跳页面。

## 坑位清单

- **NavigationBar 与 BottomNavigationBar**：后者是 M2 旧组件，新代码用前者；参数名不同（destinations vs items）。
- **Card 默认 margin**：4 逻辑像素，紧贴边缘的设计要么接受要么 `margin: EdgeInsets.zero`。
- **ListTile 长文案溢出**：subtitle 多行默认截断到两行（`isThreeLine` 开三行）；真长文本换自己的布局。
- **Drawer 项点击无反应**：忘写 `Navigator.pop`——抽屉盖在页面上，不关掉看不见跳转效果。
