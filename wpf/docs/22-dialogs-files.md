# 22 · 对话框与文件 IO

> 对应示例：`examples/22_file_dialogs`（打开/保存对话框 + 文件读写）

> **本章你将学会**：三类对话框的使用、ShowDialog 的三态返回、模态与非模态窗口的管理、文件读写的注意点。
> **前置章节**：[02 窗口生命周期](02-app-lifecycle.md)、[21 异步](21-async.md)。

## 1. 三类对话框

WPF 应用里的对话框分三类，来源不同：

| 类别 | 来源 | 例子 |
|---|---|---|
| 系统通用对话框 | `Microsoft.Win32`（WPF 自带） | OpenFileDialog、SaveFileDialog |
| 消息框 | `System.Windows.MessageBox` | 提示、确认 |
| 自定义对话框 | 自己写的 `Window` | 登录、设置、查找 |

通用对话框和消息框不用设计界面，先解决这两类；自定义对话框的生死规则在第 5 节。

## 2. 打开/保存文件对话框

`22_file_dialogs` 的打开文件完整流程：

```csharp
using Microsoft.Win32;

private void OpenFile_Click(object sender, RoutedEventArgs e)
{
    var dialog = new OpenFileDialog
    {
        Filter = "文本文件|*.txt|所有文件|*.*",
        InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
    };

    if (dialog.ShowDialog() == true)          // 注意 bool? 的判断（第 3 节）
    {
        PathBox.Text = dialog.FileName;
        MessageBox.Show($"已选择: {dialog.FileName}", "Open File");
    }
}
```

保存文件对称，多一个默认文件名：

```csharp
var dialog = new SaveFileDialog
{
    Filter = "文本文件|*.txt|所有文件|*.*",
    FileName = "newfile.txt",
};
```

`Filter` 的语法是"显示名|通配符"成对出现，多对用竖线串；一个显示名可配多个扩展名（分号分隔）：

```text
"文本文件|*.txt;*.md;*.log|图片|*.png;*.jpg|所有文件|*.*"
          ↑ 分号 = 同一显示名的多个扩展名
```

常用配置：`Multiselect = true`（多选，结果在 `FileNames` 数组）、`CheckFileExists`（打开时校验存在）、`OverwritePrompt`（保存覆盖前确认，默认开）、`AddExtension`（自动补扩展名）。

## 3. ShowDialog() == true：可空布尔的坑

`ShowDialog()` 返回 `bool?`：`true` 确认、`false` 取消、`null` 非正常关闭（如点标题栏 X、Alt+F4）。所以判断必须：

```csharp
if (dialog.ShowDialog() == true)     // ✔ 三态正确
if (dialog.ShowDialog())             // ✘ 编译错误：bool? 不能隐式转 bool
if (dialog.ShowDialog() != false)    // ✘ 危险：null 也当确认了
```

写 `is true` 也行。**记法：模态对话的结果只用 `== true` 放行**。第 07 章 CheckBox 的三态 bool? 是同一个类型习惯。

## 4. 文件读写

拿到路径后的读写是纯 .NET IO，与 WPF 无关：

```csharp
File.WriteAllText(path, "Hello from WPF!\r\n");       // 同步一行写
var text = File.ReadAllText(path);                    // 同步一行读（默认 UTF-8）

// 第 21 章的异步版（UI 上应当用这个）
await File.WriteAllTextAsync(path, content, encoding);
var bytes = await File.ReadAllBytesAsync(path);
```

实战必须补两件事（第 25 章实战项目有完整实现）：

**① 异常处理**：文件是 IO——磁盘满、权限不够、文件被别的程序锁住，都会抛。try/catch 把 `ex.Message` 显示到状态栏，别让异常崩穿 Dispatcher。

**② 编码**：`File.ReadAllText(path)` 默认按 UTF-8 解码，拿 GBK 老文件读出来是乱码。识别方案（BOM 优先 → 严格 UTF-8 试解码 → 回退 GB18030）在第 25 章作为服务类完整展开；那里还有 `.NET 默认不带 GB18030`（要注册 CodePagesEncodingProvider）的坑。

## 5. 自定义对话框：模态 vs 非模态

自己写的 Window 有两种打开方式：

| | 模态 `ShowDialog()` | 非模态 `Show()` |
|---|---|---|
| 行为 | 阻塞调用方，必须先应答 | 与主窗口共存 |
| 关闭 | 设 `DialogResult` 自动关 | `Close()` |
| 生命周期 | 局部变量即可 | 字段持有，防 GC + 防重复开 |
| 典型用途 | 登录、设置、确认 | 查找替换、监视面板 |

模态对话框返回结果给调用方：

```csharp
// 主窗口里
var dlg = new SettingsDialog { Owner = this };
if (dlg.ShowDialog() == true)
    Apply(dlg.Result);
```

```csharp
// 对话框内部（SettingsDialog）
private void Ok_Click(object sender, RoutedEventArgs e)
{
    DialogResult = true;    // 设置 DialogResult 会自动关闭窗口并返回
}
```

`Owner = this` 值得写上：对话框始终浮在主窗口之上、主窗口最小化时跟随、任务栏不出现多余图标。对话框里的确定/取消按钮记得配 `IsDefault="True"` / `IsCancel="True"`（Enter=确定、Esc=取消）。

非模态窗口的防重复开（第 25 章查找窗口就是这个套路）：

```csharp
private FindReplaceWindow? _findWindow;

private void OpenFind()
{
    if (_findWindow is { IsLoaded: true }) { _findWindow.Activate(); return; }  // 已开则置前
    _findWindow = new FindReplaceWindow { Owner = this };
    _findWindow.Show();
}
```

字段持有有双重理由：局部变量的窗口可能被 GC 中途回收（表现为闪退消失）；下次打开前要判断"它还开着吗"。

## 6. MessageBox

最轻的交互，静态方法直接用：

```csharp
MessageBox.Show(this, "文档已修改，保存吗？", "记事本+",
    MessageBoxButton.YesNoCancel, MessageBoxImage.Warning);
// 返回 MessageBoxResult.Yes / No / Cancel
```

第一个参数传 Owner；按钮组合 `OK / OKCancel / YesNo / YesNoCancel`；图标 `Information / Warning / Error / Question`。三选一的保存确认在第 25 章实战的 `OnClosing` 里就是这一行。**用之前问自己：这是必须打断用户的决策吗**——提示类信息放状态栏更好（第 11 章的原则）。

## 7. 常见坑

**Filter 格式写错**：竖线数量不对（必须成对）运行时才炸；多扩展名用分号不是逗号。

**模态关闭后读控件状态时机**：窗口对象关闭后仍在内存（这比 MFC 友好），但正确姿势是把结果整理成属性/字段再取——对话框的"输出协议"应该清晰。

**非模态窗口成孤儿**：Owner 关闭时非模态子窗口不自动关。主窗口退出前遍历 `OwnedWindows` 逐个 Close。

**保存没写编码**：`WriteAllText` 默认 UTF-8 无 BOM，老程序（记事本旧版/GBK 时代软件）打开会猜错。明确传 Encoding（第 25 章方案）。

**大文件同步读**：UI 线程 `File.ReadAllText` 读 100MB——白窗。一律异步 API（第 21 章）+ 状态栏反馈。

**ShowDialog 在 OnClosing 里同步等**：保存确认的 Yes 分支要先 `e.Cancel = true` 拦住关闭，异步保存完再 `Close()`——直接在 OnClosing 里同步弹窗流程容易把自己绕晕，第 25 章实战给出完整正确版。

## 8. 实战建议

- 文件对话框的"视图职责"用委托注入 ViewModel（第 11 章手法 ①），第 25 章的 `PickOpenFile`/`PickSaveFile` 是现成模板
- 打开与保存的 Filter 保持一致（用户保存了 .txt，打开对话框里就该看得到它）
- 对话框链（设置 → 高级设置 → …）别超过两层，第三层改成导航页（第 23 章）
- 键盘体验一次配齐：IsDefault/IsCancel + Tab 顺序（TabIndex）——手写 KeyDown 监听 Enter/Esc 是弯路

## 自测

1. **模态与非模态的生命周期差异？** —— 模态局部变量即可；非模态要字段持有（防 GC、防重复开）。
2. **ShowDialog 的三态各是什么？怎么判断？** —— true/false/null（非正常关闭）；只用 `== true` 放行。
3. **对话框里怎样"确定并关闭"？** —— 设 `DialogResult = true`（自动关闭并返回）。
4. **文件读写的两件"必补事项"？** —— 异常处理（IO 会失败）与编码（默认 UTF-8，GBK 文件乱码）。

---
上一章：[21 异步与线程模型](21-async.md) ｜ 下一章：[23 窗口与页面导航](23-navigation.md)
