# 11 · MVVM 模式：界面与逻辑分家

> 对应示例：`examples/11_mvvm`（MVVM 版任务清单）

> **本章你将学会**：MVVM 三层的职责与依赖方向、ViewModelBase 的抽取、DataContext 的装配位置、"ViewModel 不碰 UI"边界。
> **前置章节**：[10 绑定进阶](10-binding-advanced.md)。

## 1. 为什么要 MVVM

第 02 章的事件写法，`Button_Click` 里直接读 `NameTextBox.Text`——界面和逻辑焊死，代价三连：

1. 逻辑没法脱离界面做单元测试（要测"添加任务"得先造一个窗口）
2. 同一个操作从按钮/菜单/快捷键进来要写三份
3. 界面重做（WinForms 迁 WPF、换皮肤），逻辑跟着重写

MVVM（Model-View-ViewModel）把焊点拆开成三层：

| 层 | 是什么 | 知道谁 | 例子 |
|---|---|---|---|
| **Model** | 数据与业务逻辑：文件、计算、服务 | 不知道任何人 | TextFileService、EncodingDetector |
| **ViewModel** | **界面状态 + 界面动作**，纯 C# | 只知道 Model | MainViewModel：TaskName、StatusMessage、AddTask |
| **View** | 界面声明（XAML）+ 绑定 | 只知道 ViewModel | MainWindow.xaml |

依赖方向单向：**View → ViewModel → Model**，回头不知。关键约束只有一条：

> **ViewModel 不引用任何 UI 类型。** 它不知道有 TextBox 存在，只知道"有一个字符串属性叫 TaskName"。

这一条成立，逻辑就能在单元测试里裸跑；界面可以整个重画而不动逻辑。这条线也是第 25 章实战项目验收 ViewModel 的标准（一行 `using System.Windows.Controls` 都不许出现）。

## 2. ViewModelBase：把样板抽成基类

第 10 章每个属性都手写三步曲——重复。抽成基类（`11_mvvm` 与第 25 章实战共用这套壳）：

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
        return true;   // true = 真的变了，调用方可以接着做联动
    }
}
```

属性瘦身成一行：

```csharp
private string _taskName = "学习 WPF";
public string TaskName { get => _taskName; set => SetField(ref _taskName, value); }
```

`SetField` 返回值的用途（联动开关）：

```csharp
public bool IsDirty
{
    get => _isDirty;
    set { if (SetField(ref _isDirty, value)) OnPropertyChanged(nameof(Title)); }   // 脏了标题也要变
}
```

## 3. 一个完整的 ViewModel

`11_mvvm` 的 MainViewModel（去掉重复通知后的全貌）——**注意没有一个 UI 类型**：

```csharp
public sealed class MainViewModel : ViewModelBase
{
    private string _taskName = "学习 WPF";
    private string _statusMessage = "待处理";

    public string TaskName
    {
        get => _taskName;
        set => SetField(ref _taskName, value);
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set => SetField(ref _statusMessage, value);
    }

    public ICommand AddTaskCommand { get; }     // 第 12 章的主角，本章当黑盒

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

## 4. View 这边只剩声明与一根接驳线

XAML 全部是绑定，没有任何事件名：

```xml
<TextBox Text="{Binding TaskName, UpdateSourceTrigger=PropertyChanged}" />
<TextBlock Text="{Binding StatusMessage}" />
<Button Content="添加任务" Command="{Binding AddTaskCommand}" />
```

代码后置只剩一行"接驳"：

```csharp
public MainWindow()
{
    InitializeComponent();
    DataContext = new MainViewModel();   // 第 09 章的 DataContext 继承从这里开始
}
```

**对比第 02 章的事件版**：`Click` 处理函数没了，"读输入框 → 判断 → 更新提示"变成"TaskName 天然最新 → 判断 → StatusMessage 属性"。**输入与输出都成了属性，这就是 MVVM 的全部秘密**。测试时 `new MainViewModel()` 就能跑全部逻辑，窗口不存在也无所谓。

## 5. ViewModel 与 View 的通信边界

ViewModel 不碰 UI，但确实需要"弹对话框""开窗口"这类纯 UI 能力。两个可测试的标准手法（第 25 章实战都用了）：

```csharp
// ① 委托注入：View 把能力"借"给 ViewModel
public Func<string?>? PickOpenFile { get; set; }   // View 赋值：() => 弹对话框返回路径
public Func<bool>? ConfirmDiscard { get; set; }

// ② 事件外抛：ViewModel 只声明"我需要查找窗口"，View 决定怎么开
public event Action? FindRequested;
```

```csharp
// MainWindow 里装配
_vm.PickOpenFile = () => dlg.ShowDialog(this) == true ? dlg.FileName : null;
_vm.FindRequested += () => new FindReplaceWindow().Show();
```

共同点：**ViewModel 表达意图，View 实现手段**。单元测试给委托塞假返回值即可，不需要真弹窗。另一类边界是消息框：确认类用 `ConfirmDiscard` 委托；提示类（"已保存"）更好做成状态属性显示在状态栏——不打断用户，还免了边界问题。

## 6. MVVM 的收益与成本（诚实版）

收益：

- 逻辑可测：第 25 章的查找替换算法就是这么测的
- 多入口共享：一个命令绑按钮/菜单/快捷键
- 并行开发：界面和逻辑两个人写

成本（别假装没有）：

- 小工具（一屏配置器）上 MVVM 是过度设计，事件直连更快
- 文件变多：每窗口一个 VM + 基类 + 命令类
- 某些交互（拖拽、焦点控制）用纯 MVVM 别扭，需要附加行为或控件库帮忙

判断标准：**程序会长大、逻辑会变复杂、要写测试 → MVVM；一次性小工具 → 事件直连**。本教程主线用 MVVM，因为第 25 章的实战需要它撑起来。

## 7. 常见坑

**ViewModel 里出现 UI 类型**：`using System.Windows.Controls`、参数里出现 `Window`——破界信号。文本处理（string）可以，控件操作不行。

**一个 ViewModel 塞整个应用**：每窗口/每页一个 VM；跨窗口共享的数据放服务类，VM 之间通过服务通信，不互相引用。

**状态属性忘了通知**：改了 VM 字段界面不动——又是第 10 章坑。VM 全部属性走 SetField。

**View 与 VM 互相知道**：VM 引用 View（哪怕只是接口）都违背依赖方向。通信只走：绑定（数据）、命令（动作）、委托/事件（能力外借）。

**DataContext 装配太晚**：构造函数里 `InitializeComponent()` 之后再赋 DataContext 没问题；但异步加载后赋值时，之前绑定的求值已经失败过一轮——首次值要能通知（INPC）才能补上。

## 8. 实战建议

- `ViewModelBase.cs` 与下一章的 `RelayCommand.cs` 直接进你的工具库，每个项目复用；愿意引 NuGet 包的话，`CommunityToolkit.Mvvm` 的 `[ObservableProperty]` 源生成器是社区标准，原理与手写完全一致（本仓库 csharp 教程第 24 章讲源生成器）
- VM 命名按"界面状态"走：`TaskName` 而非 `TextBox1Text`——VM 不知道也不该知道控件名
- 反馈一律用状态属性（状态栏/内联提示），弹窗只留给必须打断的决策
- 每写一个 VM 自问：不启动界面能把主要流程跑一遍吗？能，说明分层干净

## 自测

1. **MVVM 三层各自知道谁？关键约束是哪条？** —— View→VM→Model 单向依赖；VM 不引用任何 UI 类型。
2. **SetField 返回 bool 有什么用？** —— 联动开关：值真的变了才触发派生属性通知。
3. **ViewModel 要弹文件对话框，标准做法是什么？** —— 委托注入（View 赋值）或事件外抛（View 订阅），VM 只表达意图。
4. **什么场景不值得用 MVVM？** —— 一次性小工具：逻辑简单、不测试、不长大。

---
上一章：[10 绑定进阶](10-binding-advanced.md) ｜ 下一章：[12 命令系统](12-commands.md)
