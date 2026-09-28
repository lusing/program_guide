# 08 · 菜单、工具栏与状态栏

> 对应示例：`examples/08_menus`（完整菜单栏 + 右键菜单 + 工具栏 + 状态栏 + 快捷键，串成迷你编辑器骨架）

> **本章你将学会**：MenuStrip 与菜单项层级、ShortcutKeys、ContextMenuStrip、ToolStrip、StatusStrip 的 Spring。
> **前置章节**：[05 文本控件](05-controls-text.md)。

## 1. MenuStrip：菜单栏

```csharp
var menu = new MenuStrip();

var miNew = new ToolStripMenuItem("新建(&N)") { ShortcutKeys = Keys.Control | Keys.N };
miNew.Click += (s, e) => { _editor.Clear(); Say("新建文档"); };

var fileMenu = new ToolStripMenuItem("文件(&F)");          // 顶级菜单
fileMenu.DropDownItems.AddRange(new ToolStripItem[]       // 下拉项：项/分隔线混装
    { miNew, miSave, new ToolStripSeparator(), miQuit });
menu.Items.Add(fileMenu);
…
MainMenuStrip = menu;        // 告诉窗体谁是主菜单（Alt 激活、菜单快捷键行为）
```

三个要点：

- **`(&N)` 是访问键**：Alt+F 打开文件菜单、再按 N 触发新建——零代码的键盘可达性。
- **`ShortcutKeys`**：真正的高捷（Ctrl+N），自动显示在菜单项右侧；`ShowShortcutKeys = false` 可隐藏显示。
- **`MainMenuStrip` 要赋值**，否则 Alt 激活等行为不挂靠。

## 2. 勾选菜单项：CheckOnClick

```csharp
var miTool = new ToolStripMenuItem("工具栏(&T)") { Checked = true, CheckOnClick = true };
miTool.Click += (s, e) => _tool.Visible = miTool.Checked;   // Checked 自动翻，只管用
```

视图菜单（工具栏/状态栏开关）的标准件。**别手写 `mi.Checked = !mi.Checked`**——`CheckOnClick = true` 已经翻了，再翻等于双否。

## 3. ContextMenuStrip：右键菜单

```csharp
var ctx = new ContextMenuStrip();
ctx.Items.Add(new ToolStripMenuItem("剪切") { ShortcutKeys = Keys.Control | Keys.X });
…
_editor.ContextMenuStrip = ctx;      // ★ 关联到控件：在它上面右键弹出
```

右键菜单**复用菜单项工厂**（同一个 `Item(...)` 函数），但要**新开一份实例**——`ToolStripItem` 不能同时挂两棵树。给 RichTextBox 挂上后，系统默认右键被替换。

## 4. ToolStrip：工具栏

```csharp
var _tool = new ToolStrip { GripStyle = ToolStripGripStyle.Hidden };   // 去掉左侧拖动把手
_tool.Items.Add(ToolBtn("新建", "新建文档 (Ctrl+N)", miNew.PerformClick));   // ★ 直接复用菜单项逻辑
_tool.Items.Add(new ToolStripSeparator());
```

`PerformClick()` 是"按钮/菜单互相镜像"的正统做法：工具栏按钮触发对应菜单项的 `PerformClick`，逻辑只有一份。`ToolTipText` 给悬浮提示。

## 5. StatusStrip：状态栏

```csharp
_hint.Spring = true;                        // ★ 弹性占满剩余宽度
_hint.TextAlign = ContentAlignment.MiddleLeft;
_count.Text = "0 字";
_status.Items.AddRange(new ToolStripItem[] { _hint, _count });
```

`Spring = true` 的标签吃掉整行剩余空间——"左提示右计数"的经典布局就靠它。鼠标扫过菜单时给提示（08 示例）：

```csharp
foreach (var strip in new ToolStrip[] { menu, _tool, ctx })
    foreach (ToolStripItem it in strip.Items)
        if (it.Tag is string tip && tip.Length > 0)
            it.MouseEnter += (s, e) => Say(tip);      // 造菜单时把说明文字塞进 Tag
```

## 6. 三语言差异

**F#**——菜单项小工厂 + 数组上转：

```fsharp
let item text shortcut onClick =
    let mi = new ToolStripMenuItem(Text = text)
    if shortcut <> Keys.None then
        mi.ShortcutKeys <- shortcut      // 枚举位或先算好再赋值（命名实参里写 ||| 要括号）
        mi.ShowShortcutKeys <- true
    mi.Click.Add(fun _ -> onClick ())
    mi
```

遍历 Items 是非泛型集合：`for it in strip.Items |> Seq.cast<ToolStripItem> do`。

**C++/CLI**——两个实测坑：

1. **`gcnew ContextMenuStrip()` 报"语法错误"**：`ContextMenuStrip` 被 Form 的属性名遮蔽（[01 章 §5-⑤](01-overview.md)），要 `gcnew System::Windows::Forms::ContextMenuStrip()`。
2. **`PerformClick` 挂不上 EventHandler**：签名是 `void()`，不匹配 `(Object^, EventArgs^)`——经 `Tag` 存镜像菜单项 + 中转方法调用：

```cpp
b->Tag = mirror;                                  // 工具栏按钮存镜像菜单项
b->Click += gcnew EventHandler(this, &MainForm::OnToolClick);
void OnToolClick(Object^ sender, EventArgs^ e)
{
    auto b = safe_cast<ToolStripButton^>(sender);
    safe_cast<ToolStripMenuItem^>(b->Tag)->PerformClick();
}
```

C++/CLI 没有 lambda——多个菜单项共用处理器时按 `Tag` 分发（08 的 C++ 版 `OnMenuClick` 按 `Text` 分发是同款思路）。

## 坑位清单

1. `CheckOnClick = true` 又手写翻 `Checked` → 双否回跳。
2. 同一 `ToolStripItem` 实例挂两棵菜单树 → 异常。各开各的实例。
3. 忘设 `MainMenuStrip`：Alt 菜单不灵。
4. C++/CLI：`ContextMenuStrip` 名字遮蔽 + `PerformClick` 委托签名不匹配（解法见上）。
5. F#：`ShortcutKeys = Keys.Control ||| Keys.N` 写在命名实参里报 FS0691——先 let 成一个值。

## 自测

1. `(&N)` 与 `ShortcutKeys` 的区别（提示：什么时候能用）？
2. 工具栏按钮与菜单项共用一份点击逻辑，正统做法是什么？
3. 状态栏"左边撑满 + 右边固定"靠哪个属性？
4. ContextMenuStrip 如何与控件关联？关联后系统的默认右键还在吗？
5. C++/CLI 里给 10 个菜单项写 10 个处理器太啰嗦，两种省法？（Tag 分发 / 菜单工厂）
