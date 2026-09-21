# 21 · 异步与线程模型：Dispatcher 边界

> 对应示例：`examples/21_async_progress`（进度条闭环：绑定属性 + IProgress + 取消）

> **本章你将学会**：界面为什么卡、async/await 如何回到 UI 线程、IProgress 进度回传、协作式取消、异步命令的纪律。
> **前置章节**：[10 INPC](10-binding-advanced.md)、[12 命令](12-commands.md)。

## 1. 为什么界面会卡

第 02 章埋的线索在此展开：WPF 的全部界面工作——输入、布局、渲染回调、绑定更新——排在**同一个 Dispatcher 队列**里逐个执行。你在按钮事件里写一个 10 秒循环，队列就堵死 10 秒：界面冻结、白窗、Windows 弹"未响应"。

```text
Dispatcher 队列：[渲染帧] [鼠标移动] [点击] [绑定更新] [你的 10 秒循环 ← 后面全部堵死]
```

MFC 时代的解法是开 worker 线程 + `PostMessage` 回传；WPF 的解法更轻：**async/await**。但先讲清楚线程规则，await 的"魔法"才不神秘。

## 2. UI 线程铁律与 Dispatcher

第 01 章的铁律：**UI 对象只能被创建它的线程访问**。后台线程要碰 UI，必须把工作排回 Dispatcher 队列：

```csharp
// 在任意线程上，把回调排回 UI 线程执行
Dispatcher.Invoke(() => StatusText = "done");          // 同步等它跑完
Dispatcher.BeginInvoke(() => StatusText = "done");     // 排队就走（≈ PostMessage）
```

好消息是 **async/await 默认替你做了这件事**：

```csharp
private async Task RunAsync()
{
    Progress = 20;                 // UI 线程上
    await Task.Delay(200);         // ★ 挂起，让出 Dispatcher 队列
    Progress = 40;                 // await 之后自动回到 UI 线程！
}
```

机制：WPF 装了 `SynchronizationContext`，`await` 前记住"这段代码从 Dispatcher 上来"，完成后的**续体被排回同一个 Dispatcher**。所以 await 前后都在 UI 线程，直接更新绑定属性，**不需要任何 Dispatcher.Invoke**。

`await` 的本质贡献：挂起期间**不占队列**，界面照常响应。同步等待（`Task.Wait()`/`.Result`）恰恰相反——占着 UI 线程等自己，经典死锁，**永远别在 UI 上同步等**。

```text
同步等：  UI线程 ──[.Result 阻塞]──► 等 Task ──► Task 的续体要排回 UI 线程 ──► 死锁
await：   UI线程 ──[挂起让出]──► 队列继续跑别的 ──► Task 完成，续体排回 ──► 无事发生
```

## 3. 示例拆解：进度条闭环

`21_async_progress` 是最小可用的异步进度方案，三块拼图：

**① 绑定目标**（XAML）：

```xml
<ProgressBar Height="20" Minimum="0" Maximum="100" Value="{Binding Progress}"/>
<TextBlock Text="{Binding StatusText}"/>
<Button Content="启动任务" Command="{Binding StartCommand}"/>
```

**② 命令启动异步任务**（ViewModel，第 12 章的弃元发射模式）：

```csharp
StartCommand = new RelayCommand(_ => _ = RunAsync());

private async Task RunAsync()
{
    for (var i = 0; i <= 100; i += 10)
    {
        Progress = i;
        StatusText = $"处理中 {i}%";
        await Task.Delay(200);          // 模拟工作片段
    }
    StatusText = "完成";
}
```

**③ 进度就是普通 INPC 属性**：`Progress`/`StatusText` 的 setter 触发通知，绑定自动刷 ProgressBar——**异步场景没有任何新知识，还是第 10 章的管道**。await 之后在 UI 线程，属性随便改。

## 4. IProgress<T>：真后台线程的进度回传

示例的活儿都在 UI 线程上"装忙"（Task.Delay）。真的占 CPU 的计算要 `Task.Run` 丢线程池，此时**不能直接改绑定属性**（工作线程改 UI 绑定源虽不抛异常，但集合与 UI 状态会炸——ObservableCollection 跨线程就崩）。正规姿势 `IProgress<T>`：

```csharp
private async Task RunAsync()
{
    var progress = new Progress<int>(percent => Progress = percent);  // ① UI 线程创建，回调自动回 UI 线程
    await Task.Run(() => HeavyWork(progress));                        // ② 计算整体丢线程池
}

private void HeavyWork(IProgress<int> progress)
{
    for (var i = 0; i <= 100; i += 10)
    {
        Thread.Sleep(200);              // 真的占着 CPU 的活
        progress.Report(i);             // ③ 任意线程调用，回调安全回到 UI 线程
    }
}
```

分工判断表：

| 任务性质 | 做法 |
|---|---|
| IO（文件、网络、数据库） | `await File.ReadAllTextAsync(...)` 等异步 API，**不需要 Task.Run** |
| CPU 密集计算 | `await Task.Run(() => ...)` 丢线程池 |
| 混合 | Task.Run 里再 await 异步 API |

与 MFC 对照：`Progress<T>.Report` ≈ `PostMessage(WM_APP_PROGRESS)`，`new Progress<T>` 的回调 ≈ 消息处理函数——同一个"计算在别处、更新回主线程"的模式，语言级封装了样板。

## 5. 取消：CancellationToken

长任务应该可取消，标准三件套：

```csharp
private CancellationTokenSource? _cts;

StartCommand  = new RelayCommand(_ => { _cts = new(); _ = RunAsync(_cts.Token); });
CancelCommand = new RelayCommand(_ => _cts?.Cancel());

private async Task RunAsync(CancellationToken token)
{
    try
    {
        for (var i = 0; i <= 100; i += 10)
        {
            token.ThrowIfCancellationRequested();     // 协作式检查点
            await Task.Delay(200, token);             // 可取消的等待
        }
    }
    catch (OperationCanceledException)
    {
        StatusText = "已取消";                        // 取消不是错误，单独接住
    }
    catch (Exception ex)
    {
        StatusText = $"失败: {ex.Message}";           // 真错误走这里
    }
}
```

取消是**协作式**的：`Cancel()` 只是立旗，任务代码在检查点自觉退出。`OperationCanceledException` 单独 catch——把它当错误报给用户是新手常见失误（用户自己点的取消）。

## 6. 异步命令的完整纪律

第 12 章预告的 async 命令，完整版规则：

1. **`_ = RunAsync()` 弃元发射** + RunAsync 内部 try/catch 全包（弃元吞异常，方法内必须自理）
2. **防重入**：任务进行中 StartCommand 的 CanExecute 置 false（`IsBusy` 属性 + RaiseCanExecuteChanged）
3. **async void 只给事件处理器**：框架契约（如 `Loaded`）没法改签名；其他场合一律 async Task
4. **ConfigureAwait(false) 属于库代码**：UI 层不用——用了续体就不回 UI 线程，后续更新绑定直接炸

```csharp
private bool _isBusy;
public bool IsBusy
{
    get => _isBusy;
    set { if (SetField(ref _isBusy, value)) StartCommand.RaiseCanExecuteChanged(); }
}
```

## 7. 常见坑

**UI 上同步等异步**：`RunAsync().Result` / `.Wait()`——死锁（第 2 节的图）。等就是 await，没有例外。

**async void 吞异常**：`async void` 方法抛出的异常没人接，直接崩进程。规则见第 6 节。

**忘记 await**：`Task.Delay(200);` 少写 await，编译器警告 CS4014，任务在后台无人看管地跑。警告别忽略。

**ConfigureAwait(false) 用在 UI 层**：续体掉到线程池，之后更新绑定属性崩（The calling thread…）。UI 层永远不写它。

**进度回调洪水**：百万次循环每次 Report 一次，Dispatcher 队列被排爆。合并节流：每 N 次迭代或每 100ms 报一次。

**后台线程碰 ObservableCollection**：直接异常。数据变更回 UI 线程做（IProgress 的回调里改，或 Dispatcher.BeginInvoke）。

**连点两次"保存"**：异步没防重入，两个任务并发写同一文件。IsBusy + CanExecute（第 6 节）或逻辑端原子写（临时文件 + 替换）。

## 8. 实战建议

- 默认写法一句话：**命令 → `_ = RunAsync()` → 方法内 try/catch + await 异步 API；进度走绑定属性或 IProgress**
- 有后果的操作（保存/删除/发送）一律防重入；纯查看类（刷新列表）可以容忍
- 超时也是取消家族：`CancellationTokenSource(TimeSpan.FromSeconds(10))` 构造即定时
- 第 25 章实战的文件读写全走异步 API（`File.ReadAllBytesAsync`/`WriteAllTextAsync`），状态栏实时显示"正在打开…/已保存"——本章模式的最小完整落地

## 自测

1. **await 前后为什么都能直接改绑定属性？** —— SynchronizationContext 记住了 UI 线程，续体自动排回 Dispatcher。
2. **`.Result` 在 UI 线程上为什么会死锁？** —— UI 线程阻塞等 Task，而 Task 的续体要排回这个被阻塞的线程。
3. **IO 和 CPU 密集分别怎么异步？** —— IO 用内置异步 API（不需要 Task.Run）；CPU 计算用 Task.Run。
4. **取消为什么是"协作式"的？Cancel 后任务立刻停吗？** —— Cancel 只立旗，任务在 ThrowIfCancellationRequested/可取消 await 检查点退出，不会立刻停。
5. **IProgress<T> 解决什么问题？** —— 后台线程安全地回 UI 线程报进度（回调自动封送）。

---
上一章：[20 动画](20-animation.md) ｜ 下一章：[22 对话框与文件 IO](22-dialogs-files.md)
