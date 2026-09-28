# 09 · 通用对话框与迷你编辑器

> 对应示例：`examples/09_dialogs`（打开/保存/颜色/字体/文件夹五个系统对话框 + 三按钮关闭确认，串成完整迷你编辑器）

> **本章你将学会**：五类通用对话框、Filter 语法、ShowDialog 的返回值处理、脏标记与退出确认。
> **前置章节**：[03 窗体](03-forms.md)、[08 菜单](08-menus.md)。

## 1. 对话框全家福

| 对话框 | 干什么 | 关键属性 |
|---|---|---|
| `MessageBox` | 提示/确认 | 按钮/图标组合 |
| `OpenFileDialog` | 选已有文件 | Filter、Multiselect、CheckFileExists |
| `SaveFileDialog` | 选保存位置 | DefaultExt、AddExtension、OverwritePrompt |
| `ColorDialog` | 选颜色 | FullOpen、Color |
| `FontDialog` | 选字体 | MinSize/MaxSize、ShowColor |
| `FolderBrowserDialog` | 选文件夹 | Description、SelectedPath |

它们都是 `CommonDialog`，用法统一：**设属性 → `ShowDialog(this)` → 判 `DialogResult.OK` → 读结果**。

## 2. OpenFileDialog：Filter 的语法

```csharp
using var dlg = new OpenFileDialog
{
    Filter = "文本文件|*.txt;*.md|日志|*.log|所有文件|*.*",   // "显示名|通配符"成对出现
    InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
    CheckFileExists = true,
};
if (dlg.ShowDialog(this) != DialogResult.OK) return;   // 取消就什么都不做
_editor.Text = File.ReadAllText(dlg.FileName);         // 默认 UTF-8 读
```

Filter 三条规则：多对用竖线串；一个显示名配多个扩展名用**分号**（`*.txt;*.md`）；竖线数量必须是偶数——少半根整个过滤器失灵。

## 3. SaveFileDialog：自动补扩展名

```csharp
using var dlg = new SaveFileDialog
{
    Filter = "文本文件|*.txt|所有文件|*.*",
    DefaultExt = "txt",
    AddExtension = true,           // 用户没写扩展名自动补
    OverwritePrompt = true,        // 覆盖前确认（默认就开，写出来图明白）
    FileName = _file is null ? "新文档.txt" : Path.GetFileName(_file),
};
```

保存逻辑的"已有文件直写、否则弹框"分叉（09 示例的 `Save` 方法）：

```csharp
private void Save(bool saveAs)
{
    if (_file is null || saveAs) { …弹框拿路径… }
    File.WriteAllText(_file, _editor.Text);    // 默认 UTF-8 无 BOM
    _dirty = false;
    UpdateTitle();
}
```

## 4. 颜色与字体

```csharp
using var dlg = new ColorDialog { Color = _editor.ForeColor, FullOpen = true };
if (dlg.ShowDialog(this) == DialogResult.OK)
    _editor.SelectionColor = dlg.Color;         // 只改选区（无选区=改后续输入）

using var fd = new FontDialog { MinSize = 9, MaxSize = 36, FontMustExist = true };
if (fd.ShowDialog(this) == DialogResult.OK)
    _editor.SelectionFont = fd.Font;
```

`FullOpen = true` 直接展开自定义颜色区；`FontDialog` 的 Min/MaxSize 防止用户选出 1 号小字。

## 5. FolderBrowserDialog

```csharp
using var dlg = new FolderBrowserDialog { Description = "选一个文件夹，统计里面文本文件的数量" };
if (dlg.ShowDialog(this) != DialogResult.OK) return;
int n = Directory.GetFiles(dlg.SelectedPath, "*.txt", SearchOption.TopDirectoryOnly).Length;
```

`SelectedPath` 是结果。新式文件夹选择（Vista 风格树）在现代 .NET 是默认外观。

## 6. 三按钮退出确认（MessageBox 完全体）

```csharp
FormClosing += (s, e) =>
{
    if (!_dirty) return;
    var r = MessageBox.Show(this,
        "内容有未保存的修改。\n「是」保存后退出，「否」直接退出，「取消」留在编辑器。",
        "迷你编辑器", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Warning);
    if (r == DialogResult.Cancel)
        e.Cancel = true;
    else if (r == DialogResult.Yes)
    {
        Save(false);
        if (_dirty) e.Cancel = true;    // 保存被取消（另存为点取消）就别退出了
}
```

脏标记的维护：`TextChanged` → `_dirty = true`，保存 → false，标题栏跟 `*`（03 章生命周期的综合应用）。

## 7. 三语言差异

**F#**——`use` 对应 `using`；路径可空用 `string option` 建模：

```fsharp
let mutable file: string option = None
let pickPath () =
    use dlg = new SaveFileDialog(Filter = …, DefaultExt = "txt", …)
    if dlg.ShowDialog(form) <> DialogResult.OK then None else Some dlg.FileName
```

**C++/CLI**——对话框对象没有 `using`，手动 `delete`（确定性回收）：

```cpp
auto dlg = gcnew OpenFileDialog();
dlg->Filter = L"文本文件|*.txt;*.md|所有文件|*.*";
if (dlg->ShowDialog(this) != System::Windows::Forms::DialogResult::OK) { delete dlg; return; }
…
delete dlg;
```

注意 `DialogResult` 的遮蔽全限定（[01 章 §5-⑤](01-overview.md)）。

## 坑位清单

1. Filter 竖线奇数个 → 过滤器整个失效（不报错）。
2. 只判了 OK 分支的 `ShowDialog`，忘了取消路径什么也不做 → 点取消照旧打开文件。
3. 保存对话框点取消也写文件——`ShowDialog != OK` 必须 return。
4. C# `using var dlg` 在 `if` 条件外声明、内里 return——作用域没问题但 F# 的 `use` 在 `if` 里才有同款确定性释放。
5. C++/CLI `OpenFileDialog` 用完不 `delete` → 句柄滞留（非托管资源不及时释放）。

## 自测

1. Filter 写 `"文本|*.txt;*.md"` 时下拉显示几个条目？分号的含义？
2. `OverwritePrompt` 与 `AddExtension` 分别管什么？
3. 三按钮退出确认里"保存被取消"这个分支为什么必须 `e.Cancel = true`？
4. 颜色对话框的 `FullOpen` 与 `Color` 初始值分别有什么用？
5. C++/CLI 里 `using var` 的等价物是什么？
