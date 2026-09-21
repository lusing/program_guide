# 25 · 实战项目：WPF 记事本+

> 对应示例：`examples/25_notepad_plus`——把全书知识串成的一个完整应用。
> **本章你将学会**：一个 MVVM 应用的完整分层、全部机制在真实需求里的落位、继续扩展的方向。

## 1. 功能清单与知识点映射

| 功能 | 用到的章节 |
|---|---|
| 应用骨架、StartupUri、程序级编码注册 | 02 |
| 菜单 + KeyBinding 快捷键 + 命令绑定 | 03、12 |
| 三行 Grid 骨架（菜单/编辑区/状态栏） | 05 |
| 菜单项 ItemsSource 绑定集合 | 07、10 |
| MVVM：ViewModelBase + RelayCommand + 命令表 | 11、12 |
| DataTrigger 驱动自动换行 | 14 |
| 异步文件读写 + 状态栏反馈 | 21 |
| 打开/保存对话框（委托注入 ViewModel） | 22 |
| 脏标记与退出确认（OnClosing） | 02、11 |
| 最近文件列表（JSON 持久化） | 10、11 |
| 非模态查找替换窗口 | 22 |
| 编码识别（BOM/UTF-8/GB18030） | 22（IO）+ 本章 |

## 2. 工程结构

```text
25_notepad_plus/
├── App.xaml(.cs)              # 注册 GB18030 编码提供程序
├── Services/
│   ├── EncodingDetector.cs    # BOM → 严格 UTF-8 → GB18030 的编码识别
│   ├── TextFileService.cs     # 异步读写 + BOM 剥离
│   └── RecentFilesService.cs  # 最近文件 JSON 持久化（%APPDATA%）
├── ViewModels/
│   ├── ViewModelBase.cs       # 第 11 章的标准壳
│   ├── RelayCommand.cs        # 第 12 章的命令实现
│   └── MainViewModel.cs       # 全部界面状态 + 命令 + 查找逻辑（纯字符串）
└── Views/
    ├── MainWindow.xaml(.cs)   # 壳：菜单/编辑区/状态栏 + OnClosing 确认
    └── FindReplaceWindow.xaml(.cs)  # 非模态查找替换
```

这个划分本身就是实践建议：**ViewModel 里一行 `using System.Windows.Controls` 都没有**——它知道"有一个字符串叫 Content"，不知道有 TextBox。查找替换的字符串算法（FindNext/ReplaceAll）是纯函数式的，可以脱离界面单元测试；窗口只负责选区和提示。Services 层无 UI 依赖，编码识别与持久化都能单独测。

## 3. 命令表：一个动词一个命令

MainViewModel 暴露 7 个命令，与菜单/快捷键一一对应：

```csharp
NewDocumentCommand = new RelayCommand(_ => NewDocument());
OpenFileCommand    = new RelayCommand(_ => _ = OpenAsync(null));
OpenRecentCommand  = new RelayCommand(p => _ = OpenAsync(p as string));  // 参数 = 路径
SaveCommand        = new RelayCommand(_ => _ = SaveAsync(), _ => IsDirty);
SaveAsCommand      = new RelayCommand(_ => _ = SaveAsAsync());
FindCommand        = new RelayCommand(_ => FindRequested?.Invoke());     // 事件外抛
```

第 12 章的三个要点全部落地：

1. **CanExecute 依赖状态**：`SaveCommand` 的 CanExecute 是 `_ => IsDirty`，未修改时"保存"自动置灰；`IsDirty` 的 setter 里 `RaiseCanExecuteChanged()`
2. **同一命令多入口**：Ctrl+S（Window.InputBindings 的 KeyBinding）与"文件→保存"菜单绑的是同一个命令
3. **参数化命令**：最近文件菜单 8 个条目共用 `OpenRecentCommand`，路径作为 `CommandParameter` 传进来

## 4. 视图职责的边界：委托注入 + 事件外抛

ViewModel 不碰 UI，但确实需要"弹文件对话框"和"开查找窗口"。两种手法都在实战里（第 11 章的方案落地）：

```csharp
// ① 委托注入（对话框）：View 赋值，VM 调用
public Func<string?>? PickOpenFile { get; set; }
public Func<bool>? ConfirmDiscard { get; set; }

// MainWindow 里
_vm.PickOpenFile = () => openDlg.ShowDialog(this) == true ? openDlg.FileName : null;

// ② 事件外抛（窗口）：VM 只声明意图
public event Action? FindRequested;
// MainWindow 订阅后 new FindReplaceWindow(...).Show()
```

边界线划清后，VM 在单元测试里给委托塞个假路径就能跑完整流程——这是第 11 章"可测试"承诺的兑现现场。

## 5. 编码识别：三层判断

`EncodingDetector` 是第 22 章"实战必须补的两件事"之一的完整实现，逻辑三层递进：

```csharp
// ① BOM 最可靠：三种文本 BOM 逐一比对
if (bytes[0]==0xEF && bytes[1]==0xBB && bytes[2]==0xBF) → UTF-8 带 BOM
if (bytes[0]==0xFF && bytes[1]==0xFE)                    → UTF-16 LE
if (bytes[0]==0xFE && bytes[1]==0xFF)                    → UTF-16 BE

// ② 无 BOM：严格 UTF-8 试解码（非法序列直接抛）
_ = new UTF8Encoding(false, throwOnInvalidBytes: true).GetCharCount(bytes);

// ③ 失败 → 回退 GB18030（中文 Windows 老文件的默认编码）
Encoding.GetEncoding("GB18030")
```

两个容易忽略的细节：

- **GB18030 不是免费的**：.NET 默认只带 Unicode 系编码，代码页编码要在 `App` 里注册提供程序（第 02 章 OnStartup 的应用场景）：`Encoding.RegisterProvider(CodePagesEncodingProvider.Instance)`
- **BOM 要手工剥离**：`Encoding.GetString` 不剥 BOM（StreamReader 才会），直接解码会得到开头一个看不见的 `﻿`。`TextFileService.StripBom` 按 `GetPreamble().Length` 切掉

保存时**保留读入时识别到的编码**（`_encoding` 字段随 Open 更新），UTF-8 带回 BOM；`File.WriteAllTextAsync` 自动写 preamble。

## 6. 异步读写与状态联动

`OpenAsync` 是第 21 章模式 + 第 10 章绑定的合流：

```csharp
public async Task OpenAsync(string? path)
{
    path ??= PickOpenFile?.Invoke();
    if (path is null) return;
    try
    {
        StatusMessage = "正在打开…";                        // ① 状态反馈
        var (content, encoding) = await TextFileService.ReadAsync(path);
        Content = content;                                  // ② 绑定自动刷新编辑区
        FilePath = path;
        _encoding = encoding;
        EncodingName = encoding.WebName.ToUpperInvariant();
        IsDirty = false;                                    // ③ 载入不算编辑
        StatusMessage = $"已打开 {path}";
        PushRecent(path);
    }
    catch (Exception ex) { StatusMessage = $"打开失败: {ex.Message}"; }
}
```

注意 `Content = content` 会触发 setter 把 IsDirty 置 true（任何编辑都置脏），所以**随后显式清掉**——顺序不能反。整条链上没有一个控件被引用，全是属性。

## 7. 最近文件：ObservableCollection 的教科书场景

```csharp
public ObservableCollection<string> RecentFiles { get; } = new(RecentFilesService.Load());

private void PushRecent(string path)
{
    RecentFiles.Remove(path);                     // 去重：挪到最上
    RecentFiles.Insert(0, path);
    while (RecentFiles.Count > 8)
        RecentFiles.RemoveAt(RecentFiles.Count - 1);
    RecentFilesService.Save(RecentFiles);         // JSON 持久化，坏了静默忽略
}
```

XAML 侧的菜单条目动态生成（第 07 章 ItemsControl 机制的变体 + 第 13 章样式）：

```xml
<MenuItem Header="最近打开(_R)" ItemsSource="{Binding RecentFiles}">
    <MenuItem.ItemContainerStyle>
        <Style TargetType="MenuItem">
            <Setter Property="Header" Value="{Binding}"/>
            <Setter Property="Command"
                    Value="{Binding DataContext.OpenRecentCommand,
                            RelativeSource={RelativeSource AncestorType=Window}}"/>
            <Setter Property="CommandParameter" Value="{Binding}"/>
        </Style>
    </MenuItem.ItemContainerStyle>
</MenuItem>
```

`RelativeSource AncestorType=Window` 是第 15 章预告的"模板里够到 ViewModel"的标准桥——条目的 DataContext 是字符串本身（路径），命令在窗口的 DataContext（MainViewModel）上。

## 8. 查找替换：纯逻辑在 VM，选区在 View

```csharp
// VM：纯字符串，可单测
public int FindNext(string query, bool matchCase, int startIndex)
{
    var comparison = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
    var idx = Content.IndexOf(query, startIndex, comparison);
    if (idx < 0 && startIndex > 0)
        idx = Content.IndexOf(query, 0, comparison);   // 回绕到开头
    return idx;
}
```

```csharp
// View：把 VM 的下标翻译成编辑器选区
var idx = _vm.FindNext(FindBox.Text, MatchCaseBox.IsChecked == true, _getSearchStart());
if (idx >= 0)
    _select(idx, FindBox.Text.Length);   // Editor.Select(start, len); Editor.Focus();
```

查找窗口用 `Show()`（非模态）：用户边看文档边替换；重复打开只 `Activate()` 置前（第 22 章的防重复套路）。

## 9. 脏标记与退出确认

```csharp
protected override void OnClosing(CancelEventArgs e)
{
    if (!_vm.IsDirty) return;
    var result = MessageBox.Show(this, "文档已修改，保存吗？", "记事本+",
        MessageBoxButton.YesNoCancel, MessageBoxImage.Warning);
    switch (result)
    {
        case MessageBoxResult.Cancel: e.Cancel = true; return;
        case MessageBoxResult.Yes:
            e.Cancel = true;              // 先拦住，存完再关
            _ = SaveThenCloseAsync();     // 保存成功 → Close()
            break;
    }
}
```

标题栏的 `*` 脏标记由 `Title` 计算属性 + `OnPropertyChanged(nameof(Title))` 联动（第 11 章 SetField 返回值的联动用法），用户不用猜有没有未保存的修改。Yes 分支"先拦再异步保存后关"是第 22 章常见坑的标准解法。

## 10. 可以继续做的事

把这个项目当练习基地，按难度递增：

1. 撤销/重做接入 TextBox 内建的 Undo（`Editor.Undo()`/`CanUndo`）并接到命令系统（第 12 章）
2. 状态栏加"选区字符数"，用 IProgress 处理大文本的统计防抖（第 21 章）
3. 多标签编辑（TabControl + 每标签一个 ViewModel，第 07/11 章）
4. 拖放打开文件（`AllowDrop` + `Drop` 事件，第 08 章）
5. 全局主题切换（App.Resources 的 DynamicResource，第 13/14 章）
6. 查找对话框加"不能为空"验证（第 16 章 FormViewModel 模板直接可抄）
7. 把查找替换升级为"正则模式"（`Regex.Matches` 进 FindNext）
8. 打包发布：`dotnet publish -r win-x64 --self-contained` 产出免安装 exe（第 24 章，已实测）

## 自测（全书总复习）

1. **从点击"打开"菜单到文本显示，中间经过了哪些层/机制？** —— 命令（OpenFileCommand）→ 委托 PickOpenFile 弹对话框 → 异步读文件（Services）→ Content 属性 setter 触发 INPC → 绑定刷新 TextBox → IsDirty 联动命令状态。
2. **"最近文件"菜单动态生成用了哪四个机制？** —— ObservableCollection 绑定 ItemsSource、ItemContainerStyle、RelativeSource 找窗口 VM、CommandParameter 传路径。
3. **为什么把 BOM 剥离放在 Service 而不是 ViewModel？** —— 它是 IO/编码细节（Model 层职责），VM 只关心"读到的文本与编码"——分层让 TextFileService 可独立测试复用。
4. **全书的"UI 不碰业务、业务不碰 UI"分别由什么机制保证？** —— 绑定/命令/事件外抛（数据与动作的通道）+ VM 零 UI 引用（可测试的证明）。

---
上一章：[24 部署与发布](24-publishing.md) ｜ 返回：[README](../README.md)
