# 10 · 对话框与文件 IO

> 对应示例：`examples/08_file_dialogs`

## 1. 三类对话框

WPF 应用里的对话框分三类，来源不同：

| 类别 | 来源 | 例子 |
|---|---|---|
| 系统通用对话框 | `Microsoft.Win32`（WPF 自带） | OpenFileDialog、SaveFileDialog |
| 消息框 | `System.Windows.MessageBox` | 提示、确认 |
| 自定义对话框 | 自己写的 `Window` | 登录、设置、查找 |

通用对话框和消息框不需要设计界面，先解决这两类；自定义对话框的生死规则在本章第 5 节。

## 2. 打开/保存文件对话框

`08_file_dialogs` 的打开文件完整流程：

```csharp
using Microsoft.Win32;

private void OpenFile_Click(object sender, RoutedEventArgs e)
{
    var dialog = new OpenFileDialog
    {
        Filter = "文本文件|*.txt|所有文件|*.*",
        InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
    };

    if (dialog.ShowDialog() == true)          // 注意 bool? 的判断
    {
        PathBox.Text = dialog.FileName;
        MessageBox.Show($"已选择: {dialog.FileName}", "Open File");
    }
}
```

保存文件对称，多一个默认名：

```csharp
var dialog = new SaveFileDialog
{
    Filter = "文本文件|*.txt|所有文件|*.*",
    FileName = "newfile.txt",
    InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
};
```

Filter 的语法是"显示名|通配符"对，多对用竖线串：

```text
"文本文件|*.txt;*.md;*.log|图片|*.png;*.jpg|所有文件|*.*"
              ↑ 一个显示名可以配多个扩展名，分号分隔
```

常用配置：`Multiselect = true`（多选，结果在 `FileNames` 数组）、`CheckFileExists`（打开时校验存在）、`OverwritePrompt`（保存时覆盖前确认，默认开）。

## 3. ShowDialog() == true：可空布尔的坑

`ShowDialog()` 返回 `bool?`：`true` = 确认，`false` = 取消，`null` = 窗口非正常关闭。所以判断必须 `== true`：

```csharp
if (dialog.ShowDialog() == true)     // ✔ 三态正确
if (dialog.ShowDialog())             // ✘ 编译错误，bool? 不能隐式转 bool
```

如果忘了问什么能写 `is true`——两种都行，关键是别用 `!= false`（会把 null 也当确认）。

## 4. 文件读写

拿到路径后的读写是纯 .NET IO，与 WPF 无关：

```csharp
File.WriteAllText(dialog.FileName, "Hello from WPF!\r\n");        // 同步一行写
var text = File.ReadAllText(path);                                 // 同步一行读

// 第 09 章的异步版（UI 上应当用这个）
await File.WriteAllTextAsync(path, content, encoding);
var (content, encoding) = await ReadTextAsync(path);
```

实战必须补两件事，第 12 章实战项目都有完整实现：

**① 异常处理**：文件操作是 IO，磁盘满、权限不够、文件被锁都会抛。try/catch 把 `ex.Message` 显示到状态栏，别让它崩穿 Dispatcher。

**② 编码**：`File.ReadAllText(path)` 默认按 UTF-8 解码，拿 GBK 老文件读出来是乱码。识别方案（BOM 优先，严格 UTF-8 试解码，失败回退 GB18030）在第 12 章作为服务类完整展开。

## 5. 自定义对话框：模态 vs 非模态

自己写的 Window 有两种打开方式，规则与 MFC 第 06 章完全同构：

| | 模态 `ShowDialog()` | 非模态 `Show()` |
|---|---|---|
| 行为 | 阻塞调用方，必须先回答 | 与主窗口共存 |
| 关闭 | `Close()`，结果在 `DialogResult` | `Close()` |
| 生命周期 | 通常栈上局部变量 | 字段持有，防 GC + 防重复开 |
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
    DialogResult = true;    // 关闭并返回 true
}
```

`Owner = this` 值得写上：保证对话框始终浮在主窗口之上、主窗口最小化时跟随、任务栏不出现多余图标。

非模态的典型重复开窗问题：

```csharp
private FindReplaceWindow? _findWindow;

private void OpenFind()
{
    if (_findWindow is { IsLoaded: true }) { _findWindow.Activate(); return; }  // 已开则置前
    _findWindow = new FindReplaceWindow();
    _findWindow.Owner = this;
    _findWindow.Show();
}
```

## 6. MessageBox

最轻的交互，静态方法直接用：

```csharp
MessageBox.Show(this, "文档已修改，保存吗？", "记事本+",
    MessageBoxButton.YesNoCancel, MessageBoxImage.Warning);
// 返回 MessageBoxResult.Yes / No / Cancel
```

第一个参数传 Owner（有主窗口时），带图标（Warning/Error/Information/Question），带默认按钮（`MessageBoxButton.YesNoCancel, MessageBoxResult.No` 可指定默认焦点）。三选一的保存确认在第 12 章实战的 `OnClosing` 里就是这一行。

## 7. 常见坑

**Filter 格式写错**：竖线数量不对（必须奇数个：显示名|模式 成对再结尾）运行时才炸。多扩展名用分号 `*.txt;*.md`，别用逗号。

**对话框里读 UI 控件状态"过了时机"**：模态关闭后读对话框控件的值——控件还在（Window 对象没销毁），这比 MFC 友好；但正确姿势仍是把结果整理成属性/字段再取。

**非模态窗口被主人关掉后还开着**：Owner 关闭时非模态子窗口不会自动关，会在 OnClosed 里孤立存活。主窗口退出前遍历 `OwnedWindows` 逐个 Close。

**保存时没写编码**：`WriteAllText` 默认 UTF-8 无 BOM，老程序打开会猜错。明确传 Encoding（第 12 章）。

**对话框按钮没有 IsDefault/IsCancel**：`IsDefault="True"` 让 Enter 触发"确定"，`IsCancel="True"` 让 Esc 触发"取消"——键盘习惯靠这两个属性，手写 KeyDown 是弯路。

## 8. 实战建议

- 文件对话框的"视图职责"用委托注入 ViewModel（第 07 章的模式 ①），第 12 章实战的 `PickOpenFile`/`PickSaveFile` 是现成模板
- 打开与保存的 Filter 保持一致（用户保存了 .txt 就该在打开对话框里看得到它）
- 大文件读写必须走异步版（第 09 章），并在状态栏给"正在打开…"反馈——第 12 章实战全按此办理
- 自定义对话框内容多时考虑改用导航 Page（第 11 章），别堆第 4 层嵌套模态

---
上一章：[09 异步与后台任务](09-async.md) ｜ 下一章：[11 窗口与页面导航](11-navigation.md)
