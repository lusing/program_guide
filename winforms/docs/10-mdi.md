# 10 · SDI 与 MDI：多文档界面

> 对应示例：`examples/10_mdi`（MDI 容器主窗体 + 可增子文档 + 窗口菜单四件套 + 状态栏汇报）

> **本章你将学会**：MDI 容器与子窗体的父子关系、LayoutMdi 四种排布、窗口菜单自动清单、活动子窗体。
> **前置章节**：[03 窗体](03-forms.md)、[08 菜单](08-menus.md)。

## 1. 一句话变身 MDI 容器

```csharp
IsMdiContainer = true;      // 主窗体：背景变深，准备装子窗体
```

子窗体认父：

```csharp
var child = new ChildForm(++_created)
{
    MdiParent = this,                            // ★ 从此受容器管理
    StartPosition = FormStartPosition.Manual,
    Location = new Point(30 * (_created % 8), 30 * (_created % 8)),   // 级联错位
};
child.Show();
```

`MdiParent` 必须在 `Show()` 之前设。设了它的子窗体：不占任务栏、被关在容器范围内、随容器最小化。

**SDI vs MDI**：SDI（单文档）就是此前所有章节的普通窗体；09 章迷你编辑器开多份就是"多 SDI"。MDI 把子窗体圈在一个框里管理——老牌 IDE/办公软件的形态，如今新应用多用页签（07 章 TabControl）替代，但存量系统和教材（本书 4.4 节）仍是它。

## 2. 窗口菜单：布局四件套 + 自动清单

```csharp
miCascade.Click += (s, e) => LayoutMdi(MdiLayout.Cascade);        // 层叠
miTileV.Click   += (s, e) => LayoutMdi(MdiLayout.TileVertical);   // 垂直平铺
miTileH.Click   += (s, e) => LayoutMdi(MdiLayout.TileHorizontal); // 水平平铺
miArrange.Click += (s, e) => LayoutMdi(MdiLayout.ArrangeIcons);   // 排列最小化的图标
```

**子窗体清单是白送的**——但要设对地方：

```csharp
menu.MdiWindowListItem = miCascade;    // ★ 在 MenuStrip 上，不是菜单项上！
```

指定的那一项后面会自动出现所有子窗体的名字（点击激活），还可以勾选显示当前活动子窗体。**实测坑**：写成 `winMenu.MdiWindowListItem`（菜单项）→ 编译错（属性在 `MenuStrip` 上）。

## 3. 活动子窗体与子窗体枚举

```csharp
MdiChildActivate += (s, e) => RefreshStatus();     // 活动子窗体切换时

private void RefreshStatus()
{
    var active = ActiveMdiChild as ChildForm;      // 当前活动的那一个（可能为 null）
    string activeInfo = active is null
        ? "（无）"
        : $"「{active.Text}」{active.Editor.Text.Length} 字";
    _status.Text = $"  子窗体 {MdiChildren.Length} 个；活动文档：{activeInfo}";
}
```

`ActiveMdiChild`（一个）与 `MdiChildren`（`Form[]` 全体）是 MDI 编程的两个把手。主窗体关闭会带走全部子窗体，无需逐个处理。

## 4. 窗体间协作的三条正路（对照 03 章）

1. **构造注入**：`new ChildForm(data)`——开窗时给数据
2. **公共属性/事件**：子窗体暴露 `Editor` 属性 + 事件向外汇报（03 章浮动窗口）
3. **从容器反查**：`MdiParent`/`MdiChildren`/`ActiveMdiChild` 拿到对方引用再操作

反着来（子窗体构造函数里硬编码主窗体类型）能跑但耦合——教材里的"登录窗体传主窗体引用"写法，生产上不如事件干净。

## 5. 三语言差异

**F#**：

```fsharp
let child = new ChildForm(created, MdiParent = form,
                          StartPosition = FormStartPosition.Manual,
                          Location = Point(30 * (created % 8), 30 * (created % 8)))
```

活动子窗体的模式匹配：

```fsharp
let active =
    match form.ActiveMdiChild with
    | :? ChildForm as c -> $"「{c.Text}」{c.Editor.Text.Length} 字"
    | _ -> "（无）"
```

**C++/CLI**——布局枚举塞 Tag，一个处理器服务四件套：

```cpp
ToolStripMenuItem^ LayoutItem(String^ text, MdiLayout layout)
{
    auto mi = gcnew ToolStripMenuItem(text);
    mi->Tag = layout;                            // 枚举装箱进 Tag
    mi->Click += gcnew EventHandler(this, &MainForm::OnLayoutClick);
    return mi;
}
void OnLayoutClick(Object^ s, EventArgs^ e)
{
    LayoutMdi(safe_cast<MdiLayout>(safe_cast<ToolStripMenuItem^>(s)->Tag));
}
```

## 坑位清单

1. `MdiWindowListItem` 设在菜单项上 → 编译错；它在 **MenuStrip** 上。
2. `MdiParent` 在 `Show()` 之后才设 → 子窗体已经按普通窗体显示了。
3. `ActiveMdiChild` 可能为 null（子窗体全关时）——不判空就 NRE。
4. 子窗体设了 `TopMost = true` 想浮在最上——MDI 里没意义（被圈在容器里）。
5. 在子窗体上 `ShowDialog()`：MDI 子窗体不支持模态显示，只能 `Show()`。

## 自测

1. `IsMdiContainer = true` 除了背景色还改变了什么？
2. 四种 `MdiLayout` 各自的排布效果？
3. 子窗体清单为什么"白送"？它挂在哪个属性上？
4. `MdiChildren` 与 `ActiveMdiChild` 的类型与可空性？
5. 为什么说页签（07 章）在现代应用里常替代 MDI？
