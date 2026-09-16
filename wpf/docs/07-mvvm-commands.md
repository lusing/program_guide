# 07 · MVVM 与命令：RelayCommand 前后

> 对应示例：`examples/03_mvvm`、`examples/06_commands`

## 1. 为什么要 MVVM

第 02 章的事件写法，`Button_Click` 里直接读 `NameTextBox.Text`——界面和逻辑焊死，代价三连：逻辑没法脱离界面单测；同一个操作从菜单/快捷键/按钮进来就要写三份；界面重做逻辑重写。

MVVM 把焊点拆开成三层：

| 层 | 是什么 | 知道谁 |
|---|---|---|
| Model | 数据与业务（文件、计算、服务） | 不知道任何人 |
| ViewModel | **界面状态 + 界面动作**，纯 C# | 只知道 Model |
| View（XAML） | 界面声明 + 绑定 | 只知道 ViewModel |

关键约束只有一条：**ViewModel 不引用任何 UI 类型**。它不知道有 TextBox 存在，只知道"有一个字符串属性叫 TaskName"。这一条成立，逻辑就可以在单元测试里跑，界面可以整个重画而不动逻辑。

## 2. ViewModelBase：INPC 的标准壳

第 06 章手写的通知模式抽成基类（`03_mvvm` 示例的写法内联在 VM 里，思想相同）：

```csharp
public abstract class ViewModelBase : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));

    protected bool SetField<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;   // true = 真的变了（调用方可以接着做联动）
    }
}
```

`SetField` 返回值是常用的联动开关："值变了才刷新派生属性"。

## 3. ViewModel 实战：状态与动作

`03_mvvm` 的完整 ViewModel（去掉了重复的通知代码）：

```csharp
public sealed class MainViewModel : ViewModelBase
{
    private string _taskName = "学习 WPF";
    private string _statusMessage = "待处理";

    public string TaskName { get => _taskName; set => SetField(ref _taskName, value); }
    public string StatusMessage { get => _statusMessage; set => SetField(ref _statusMessage, value); }

    public ICommand AddTaskCommand { get; }

    public MainViewModel()
    {
        AddTaskCommand = new RelayCommand(_ =>
        {
            if (string.IsNullOrWhiteSpace(TaskName))
            {
                StatusMessage = "任务名称不能为空。";   // 反馈也走状态属性，不弹窗
                return;
            }
            StatusMessage = $"已添加任务: {TaskName}";
        });
    }
}
```

View 这边只剩声明：

```xml
<TextBox Text="{Binding TaskName, UpdateSourceTrigger=PropertyChanged}" />
<TextBlock Text="{Binding StatusMessage}" />
<Button Content="添加任务" Command="{Binding AddTaskCommand}" />
```

代码文件里唯一一行"接驳"：

```csharp
public MainWindow()
{
    InitializeComponent();
    DataContext = new MainViewModel();   // 第 06 章说的 DataContext 继承从这里开始
}
```

**对比第 02 章**：Click 处理函数没了，"读输入框 → 判断 → 更新提示"变成"TaskName 属性本来就是最新的 → 判断 → StatusMessage 属性"。输入与输出都成了属性，这就是 MVVM 的全部魔法。

## 4. RelayCommand：命令的最小实现

`ICommand` 三个成员：`Execute`（做什么）、`CanExecute`（现在能不能做）、`CanExecuteChanged`（能力变了通知界面置灰）。RelayCommand 把它变成"两个委托的事"：

```csharp
public sealed class RelayCommand : ICommand
{
    private readonly Action<object?> _execute;
    private readonly Predicate<object?>? _canExecute;

    public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter) => _canExecute is null || _canExecute(parameter);
    public void Execute(object? parameter) => _execute(parameter);
    public event EventHandler? CanExecuteChanged;
    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}
```

与第 05 章的分工对照：**命令是"动词"的一等公民**——一个命令对象可以同时绑到按钮、菜单、快捷键（第 12 章实战项目的 Ctrl+S 与"保存"菜单就是同一个命令），而事件只能一处一挂。

## 5. CanExecute：自动置灰的按钮

`06_commands` 示例展示了 CanExecute 的完整闭环——任务名为空时按钮自动变灰：

```csharp
AddTaskCommand = new RelayCommand(
    _ => StatusText = $"命令已执行: {TaskName}",
    _ => !string.IsNullOrWhiteSpace(TaskName));      // ← CanExecute

public string TaskName
{
    get => _taskName;
    set
    {
        if (_taskName == value) return;
        _taskName = value;
        OnPropertyChanged();
        AddTaskCommand.RaiseCanExecuteChanged();     // ← 影响能力时主动通知
    }
}
```

注意第二处：**WPF 不会自动重算 CanExecute**（WPF 内置命令才会）。你改了影响能力的状态，必须 `RaiseCanExecuteChanged()`，否则按钮灰不灰永远停在旧状态。这是命令系统第二大坑。

## 6. ViewModel 里不能碰 UI：边界案例

命令处理器要"打开文件对话框""弹确认框"怎么办？这些是 UI 职责，ViewModel 不该 `new OpenFileDialog()`。两个可测试的做法：

```csharp
// ① 委托注入：View 把能力"借"给 ViewModel（第 12 章实战采用）
public Func<string?>? PickOpenFile { get; set; }   // View 赋值：() => dlg.ShowDialog()...

// ② 事件外抛：ViewModel 只声明"我需要查找窗口"，View 决定怎么开
public event Action? FindRequested;
```

两者共同点：**ViewModel 表达意图，View 实现手段**。测试时给委托塞个假返回值即可，不需要真的弹窗。

另一个边界是消息框：确认类交互用 `ConfirmDiscard` 委托；纯提示类（"保存成功"）用状态属性展示在界面（StatusBar），比打断式弹窗体验更好。

## 7. 常见坑

**CanExecute 不刷新**：上一节。凡是"按钮状态莫名不变"，找 `RaiseCanExecuteChanged`。

**ViewModel 引用了 UI 类型**：出现 `using System.Windows.Controls` 就是破界的信号。文本处理可以，控件操作不行。

**async void 命令**：`RelayCommand(_ => _ = RunAsync())` 用弃元启动异步任务可以，但异常会静默；命令里 async 的异常处理见第 09 章。

**一个 ViewModel 塞整个应用**：窗口/页面级 ViewModel，跨窗口共享的数据放单独的服务类，VM 之间通过服务通信，别互相引用。

**XAML 绑定写错命令名**：与绑定错误一样静默，输出窗口查。

## 8. 实战建议

- 基类 + RelayCommand 这两个文件直接进你每个项目的工具库；若愿意引入 NuGet 包，`CommunityToolkit.Mvvm` 的 `[ObservableProperty]` 源生成器是当前社区标准做法，原理与本章完全一致
- 命令粒度跟"动词"走：Open、Save、Find…… 一个动词一个命令，多入口共享
- 命令处理器里保持业务薄：编排服务调用 + 更新状态属性，复杂逻辑下沉 Model
- 第 12 章实战项目是本章模式的完整落地：7 个命令、委托注入、事件外抛全用上了

---
上一章：[06 数据绑定](06-binding.md) ｜ 下一章：[08 样式、触发器与模板](08-styles.md)
