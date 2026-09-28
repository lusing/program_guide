# 07 · 容器与列表：TreeView、ListView、TabControl、SplitContainer

> 对应示例：`examples/07_lists`（左侧类别树 + 右侧三页签：明细表/图标视图/滚动面板）

> **本章你将学会**：TreeView 的节点模型、ListView 的视图模式与 Details 表格、ImageList 挂图标、TabControl、SplitContainer、AutoScroll。
> **前置章节**：[04 布局](04-layout.md)、[06 选择控件](06-controls-selection.md)。

## 1. SplitContainer：可拖动的分栏

```csharp
var split = new SplitContainer { Dock = DockStyle.Fill };
split.SplitterDistance = 220;          // 初始左侧宽度
split.Panel1.Controls.Add(_tree);      // 左右两个 Panel 各装各的
split.Panel2.Controls.Add(tabs);
```

中间那条分隔条用户可以拖动——`SplitterMoved` 事件、`FixedPanel` 属性控制拖动时谁让位。

## 2. TreeView：节点树

```csharp
foreach (var (cat, items) in Catalog)
{
    var node = _tree.Nodes.Add(cat);       // 一级节点 = 类别
    node.Tag = cat;                        // Tag：随节点携带任意数据的口袋
    foreach (var (name, _, _) in items)
    {
        var child = node.Nodes.Add(name);
        child.Tag = (cat, name);           // 元组也能塞
    }
}
_tree.ExpandAll();
_tree.AfterSelect += (s, e) =>
{
    // e.Node.Text / e.Node.Level（0=一级）/ e.Node.FullPath（用反斜杠串起来）
};
```

`Tag` 是 WinForms 的"随身口袋"模式——控件/节点不认识你的业务类型，就用 `object` 口袋装，用的时候再取。`Nodes` 的增删查（`Add/Remove/Clear/Find`）、`Level`、`FullPath` 是常驻 API。

## 3. ListView：视图模式

ListView 有五种 `View`，最常用的两种：

```csharp
// Details：表格（不是 DataGridView，轻量、不编辑）
_list.View = View.Details;
_list.FullRowSelect = true;                  // 点整行任意处都选中
_list.GridLines = true;
_list.Columns.Add("品名", 140);
_list.Columns.Add("单价(元)", 90, HorizontalAlignment.Right);
_list.Items.Add(new ListViewItem(new[] { name, price.ToString("F1"), from }));  // 行 = 子项数组
```

```csharp
// LargeIcon：图标墙（配 ImageList）
_iconList.View = View.LargeIcon;
_iconList.LargeImageList = _icons;
_iconList.Items.Add("盾牌", "shield");       // (文本, 图标键)
```

**免资源文件的图标技巧**（教程零素材约束）：`SystemIcons.Shield/Warning/Information` 是系统自带的：

```csharp
_icons.ImageSize = new Size(32, 32);
_icons.Images.Add("shield", SystemIcons.Shield);
```

## 4. TabControl：页签

```csharp
var tabs = new TabControl { Dock = DockStyle.Fill };
tabs.TabPages.AddRange(new TabPage[] { page1, page2, page3 });   // 每页就是个容器
```

`SelectedIndexChanged` 感知页切换；`TabPage` 本质是容器，里面随便装。

## 5. Panel + AutoScroll

```csharp
var panel = new Panel { Dock = DockStyle.Fill, AutoScroll = true };
for (int i = 1; i <= 12; i++)
{
    var b = new Button { Text = $"按钮 {i:00}", Location = … };
    int captured = i;              // ★ for 的循环变量被所有 lambda 共享——拷一份
    b.Click += (s, e) => _status.Text = $"  滚动面板：点了按钮 {captured:00}";
    panel.Controls.Add(b);
}
```

内容超出面板边界自动出滚动条。**闭包捕获循环变量**是 C# `for` 循环的经典雷（`foreach` 自 C# 5 起每轮新绑定，`for` 不是）——F# 的 `for` 每次迭代都是新绑定，天然免疫（07 的 F# 版特意对比了这点）。

## 6. 三语言差异

**F#**——数据建模直接用不可变结构：

```fsharp
let catalog =
    [ "水果", [ "苹果", 8.5m, "山东"; … ]; "蔬菜", […] ] |> Map.ofList

for KeyValue(cat, items) in catalog do      // Map 迭代给 KeyValuePair，KeyValue 模式解
    let node = tree.Nodes.Add cat
    node.Tag <- cat
```

`ListViewItem` 的构造参数是字符串数组——F# 传 `[| name; p; from |]`。

**C++/CLI**——没有元组，用小 `value struct` 建模；循环变量捕获同样有坑：

```cpp
public value struct Item { String^ Name; Decimal Price; String^ From; };

b->Tag = i;                       // C++ 的 for 变量也被所有处理器共享：塞 Tag
void OnPanelButton(Object^ s, EventArgs^ e)
{
    _status->Text = String::Format(L"  滚动面板：点了按钮 {0:00}", safe_cast<int>(safe_cast<Button^>(s)->Tag));
}
```

## 坑位清单

1. C# `for` 循环里直接捕获 `i` → 所有按钮都显示最后一个数（拷贝或换 `foreach`）。
2. ListView 想当可编辑表格用 → 那是 [15 章](15-datagridview.md) DataGridView 的活。
3. `node.Tag` 装箱取出时类型对不上 → `(string)node.Tag` 抛 InvalidCastException（C# 模式匹配 `is` 更稳）。
4. F# `for cat, items in catalog`（Map）→ FS0001 元组不匹配，要用 `for KeyValue(k, v) in …`。
5. C++/CLI 给 `array<Item>`（漏 `^`）→ C3149；用 `gcnew List<Item>` + `Add`（或带构造函数的值结构体逐个加）。

## 自测

1. `Tag` 模式解决什么问题？取出时的注意点？
2. ListView 五种视图里最适合"只读表格"的是哪种？真正的编辑表格用什么控件？
3. `SystemIcons` 技巧为什么能让教程免带资源文件？
4. C# 与 F# 的循环变量捕获行为差异？
5. SplitContainer 的两个面板分别叫什么？
