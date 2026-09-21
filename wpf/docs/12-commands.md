# 12 · 命令系统：ICommand 与 RelayCommand

> 对应示例：`examples/12_commands`（CanExecute 自动置灰闭环）

> **本章你将学会**：ICommand 三个成员的分工、RelayCommand 实现、CanExecute 通知机制、内置命令与多入口共享。
> **前置章节**：[11 MVVM 模式](11-mvvm.md)。

## 1. 命令是什么

第 08 章留了分工口诀：**"动词"用命令，"状态变化"用事件**。事件处理器是"界面上的一个函数"，命令（`ICommand`）则是**一个对象**，把"做什么"打包成一等公民：

```csharp
public interface ICommand
{
    bool CanExecute(object? parameter);            // 现在能不能做（按钮置灰依据）
    void Execute(object? parameter);               // 做什么
    event EventHandler? CanExecuteChanged;         // 能力变了，通知界面重查
}
```

事件 vs 命令的本质差异，一个对照看全：

| | 事件 | 命令 |
|---|---|---|
| 形态 | 界面上的函数 | 独立对象（可存进 VM） |
| 多入口 | 一处一挂 | 一个命令绑按钮 + 菜单 + 快捷键 |
| 可用性 | 无（得手写 IsEnabled） | CanExecute 自动置灰 |
| 可测试 | 要起界面 | new 出来直接调 Execute |
| 绑定语法 | `Click="Handler"` | `Command="{Binding SaveCommand}"` |

## 2. RelayCommand：命令的最小实现

自己实现 ICommand 不到 20 行，就是"两个委托的事"（`12_commands` 与实战项目共用）：

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

ViewModel 里组装：

```csharp
AddTaskCommand = new RelayCommand(
    _ => StatusText = $"已添加任务: {TaskName}",
    _ => !string.IsNullOrWhiteSpace(TaskName));   // ← CanExecute：任务名空则不可用
```

```xml
<Button Content="添加" Command="{Binding AddTaskCommand}"/>
```

## 3. CanExecute：自动置灰的按钮

`12_commands` 演示完整闭环——输入框为空时按钮自动变灰，敲一个字就亮。机制分两半：

**WPF 负责的**：命令绑到 Button 时，按钮自动调 `CanExecute()` 决定 IsEnabled；监听 `CanExecuteChanged` 事件，事件来了自动重查。

**你要负责的**：**WPF 不会自动重算自定义命令的 CanExecute**——`CanExecuteChanged` 事件必须由你触发。影响能力的状态变了，主动通知：

```csharp
public string TaskName
{
    get => _taskName;
    set
    {
        if (_taskName == value) return;
        _taskName = value;
        OnPropertyChanged();
        AddTaskCommand.RaiseCanExecuteChanged();   // ← 不写这行，按钮灰亮永远停在旧状态
    }
}
```

这是命令系统**第一大坑**：按钮状态"莫名不变"，找 `RaiseCanExecuteChanged`。（对比：WPF 内置命令由 CommandManager 自动重查，下一节。）

用 SetField（第 11 章）的写法更紧凑：

```csharp
public string TaskName
{
    get => _taskName;
    set { if (SetField(ref _taskName, value)) AddTaskCommand.RaiseCanExecuteChanged(); }
}
```

## 4. CommandParameter 与多入口共享

**参数化**：一个命令服务 N 个条目——最近文件菜单 8 项共用一个命令，路径作参数：

```xml
<Button Content="打开最近文件" Command="{Binding OpenRecentCommand}"
        CommandParameter="C:\docs\a.txt"/>
```

**多入口**：同一个命令绑三处（第 25 章实战的"保存"）：

```xml
<MenuItem Header="保存(_S)" Command="{Binding SaveCommand}"/>
<Button Content="保存" Command="{Binding SaveCommand}"/>
<Window.InputBindings>
    <KeyBinding Key="S" Modifiers="Control" Command="{Binding SaveCommand}"/>
</Window.InputBindings>
```

三处行为、置灰状态天然一致——这就是"动词一等公民"的红利。反过来，**逻辑永远只在命令的实现里写一份**。

## 5. WPF 内置命令：RoutedCommand 家族

WPF 自带一套标准命令（`ApplicationCommands.Save/Open/Copy`、`EditingCommands`、`MediaCommands`…），它们是 `RoutedCommand`——**沿可视化树路由**找谁实现了它（第 08 章的路由机制在命令层的翻版）：

```xml
<MenuItem Command="ApplicationCommands.Open"/>
```

TextBox 自动响应 Copy/Paste/Undo 这类内置命令，不用你写。两个注意点：

1. 内置命令的 CanExecute 由 CommandManager 自动重查（不必手动通知）——但**性能上**它靠全局失效，高频界面偶发卡顿，重逻辑项目一般还是用自定义 RelayCommand
2. 自定义命令可以做成静态类共享（`public static class AppCommands { public static readonly RoutedCommand Export = new(); }`），配合 `CommandBindings` 在 View 层接实现

入门阶段记住结论：**数据驱动的动作用 RelayCommand（绑 VM），控件内建行为（复制粘贴撤销）白拿内置命令**。

## 6. 异步命令（预告）

`Execute` 的签名是同步的 void，长任务怎么办？第 21 章的答案：

```csharp
SaveCommand = new RelayCommand(_ => _ = SaveAsync());   // 弃元发射异步任务
private async Task SaveAsync() { try { ... } catch (Exception ex) { StatusText = ex.Message; } }
```

两条纪律先立好：**命令处理器里启动的异步任务必须自带异常处理**（弃元吞异常）；任务进行中把命令 CanExecute 置 false 防重入（第 21 章完整版 AsyncRelayCommand）。

## 7. 常见坑

**CanExecute 不刷新**：第一大坑，第 3 节。判据：按钮灰亮"停在旧状态"。

**Execute 里忘了判重**：连点两次"保存"并发写同一文件。命令要么 CanExecute 防重入，要么逻辑端幂等。

**命令名绑定拼错**：`Command="{Binding SaveCmd}"`（VM 里叫 SaveCommand）——静默失败，输出窗口查（第 10 章清单）。

**async void 直塞命令**：`new RelayCommand(async _ => await SaveAsync())` 把 Action 换成 async lambda——编译成 async void，异常直接崩进程。用弃元发射 + 方法内 try/catch（第 6 节）。

**在 CanExecute 里做重活**：CanExecute 会被频繁调用（每次 CanExecuteChanged 后所有绑定处各一次），里面放 IO/遍历会卡界面。判断保持轻量。

## 8. 实战建议

- RelayCommand + ViewModelBase 这两个文件是工具库常驻居民；命令多了再上 `AsyncRelayCommand<T>` 泛型版
- 命令命名按动词：`OpenFileCommand`、`SaveCommand`、`FindCommand`——一个动词一个命令，多入口共享
- 命令处理器保持薄：编排服务调用 + 更新状态属性；复杂逻辑下沉 Model（第 25 章的分层示范）
- InputBindings（快捷键）+ CommandBindings 只写在 View——快捷键是界面层的事，VM 不感知
- 菜单条目的参数化命令配合 ItemContainerStyle 是动态菜单的标准解（第 25 章实战第 7 节有完整代码）

## 自测

1. **ICommand 三个成员各管什么？** —— CanExecute 能不能做（置灰）、Execute 做什么、CanExecuteChanged 通知界面重查。
2. **自定义命令的 CanExecute 为什么会"不刷新"？怎么修？** —— WPF 只监听 CanExecuteChanged 不主动重查；影响能力的状态变化处手动 RaiseCanExecuteChanged()。
3. **一个命令如何同时服务按钮、菜单、Ctrl+S？** —— 三处绑定同一 Command，快捷键走 KeyBinding + Command。
4. **内置 RoutedCommand 与 RelayCommand 的定位差异？** —— 内置命令沿树路由、CommandManager 自动重查，适合控件内建行为；RelayCommand 数据驱动、绑 VM，业务动作首选。

---
上一章：[11 MVVM 模式](11-mvvm.md) ｜ 下一章：[13 资源与样式](13-styles-resources.md)
