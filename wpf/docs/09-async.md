# 09 · 异步与后台任务：Dispatcher 边界

> 对应示例：`examples/07_async_progress`

## 1. 为什么界面会卡

WPF 的全部界面工作——输入、布局、渲染回调、绑定更新——排在**同一个 Dispatcher 队列**里逐个执行。你在按钮事件里写一个 10 秒循环，队列就堵死 10 秒：界面冻结、白窗、Windows 打"未响应"。MFC 时代的解法是开 worker 线程 + PostMessage 回传（MFC 教程第 12 章）；WPF 的解法更轻：**async/await**。

## 2. UI 线程与 Dispatcher

规则重申（第 01 章）：UI 对象只能被创建它的线程访问。后台线程要碰 UI，必须把工作排回 Dispatcher 队列：

```csharp
// 在任意线程上，把回调排回 UI 线程执行
Dispatcher.Invoke(() => StatusText = "done");          // 同步等它跑完
Dispatcher.BeginInvoke(() => StatusText = "done");     // 排队就走
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

机制：WPF 的 SynchronizationContext 记住了"这段代码从 Dispatcher 上来"，`await` 完成后的续体被排回同一个 Dispatcher。**所以 await 前后都在 UI 线程，可以直接更新绑定属性**——不需要任何 Dispatcher.Invoke。

`await` 的本质贡献：挂起期间**不占队列**，界面照常响应。同步等待（`Task.Wait()`/`.Result`）恰恰相反——占着 UI 线程等自己完成，经典死锁，永远别在 UI 上同步等。

## 3. 示例拆解：进度条闭环

`07_async_progress` 是最小可用的异步进度方案，三块拼图：

**① 绑定目标**（XAML）：

```xml
<ProgressBar Height="20" Minimum="0" Maximum="100" Value="{Binding Progress}"/>
<TextBlock Text="{Binding StatusText}"/>
<Button Content="启动任务" Command="{Binding StartCommand}"/>
```

**② 命令启动异步任务**（ViewModel）：

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

**③ 进度就是普通 INPC 属性**：`Progress`/`StatusText` 的 setter 触发 PropertyChanged，绑定自动刷 ProgressBar——异步场景没有任何新知识，还是第 06 章的管道。

要点藏在 `_ = RunAsync()` 的弃元里：命令是同步签名，把 async Task 方法"发射"出去。直接 `async void` 也可以，但**异常处理**见第 6 节。

## 4. IProgress<T>：进度回传的正规姿势

示例直接更新 UI 线程属性，任务简单时没问题。任务逻辑复杂（在真正的后台线程上算）时，用 `IProgress<T>` 把"进度"抽象出来：

```csharp
private async Task RunAsync()
{
    var progress = new Progress<int>(percent => Progress = percent);  // ① UI 线程创建
    await Task.Run(() => HeavyWork(progress));                        // ② 整个任务丢线程池
}

private void HeavyWork(IProgress<int> progress)
{
    for (var i = 0; i <= 100; i += 10)
    {
        Thread.Sleep(200);              // 真的占着 CPU 的活
        progress.Report(i);             // ③ 任意线程调用，回调自动排回 UI 线程
    }
}
```

分工判断：

| 任务性质 | 做法 |
|---|---|
| IO（文件、网络） | `await File.ReadAllTextAsync(...)` 等异步 API，**不需要 Task.Run** |
| CPU 密集计算 | `await Task.Run(() => ...)` 丢线程池 |
| 混合 | Task.Run 里调异步 API（`await` 嵌套） |

与 MFC 对照：`Progress<T>.Report` ≈ `PostMessage(WM_APP_PROGRESS)`，`new Progress<T>` 的回调 ≈ 消息处理函数——同一个"计算在别处、更新回主线程"的模式，语言级封装了样板。

## 5. 取消：CancellationToken

长任务应该可取消，标准三件套：

```csharp
private CancellationTokenSource? _cts;

StartCommand  = new RelayCommand(_ => { _cts = new(); _ = RunAsync(_cts.Token); });
CancelCommand = new RelayCommand(_ => _cts?.Cancel());

private async Task RunAsync(CancellationToken token)
{
    for (var i = 0; i <= 100; i += 10)
    {
        token.ThrowIfCancellationRequested();     // 协作式检查点
        await Task.Delay(200, token);             // 可取消的等待
    }
}
```

取消是**协作式**的：`Cancel()` 只是立旗，任务代码在检查点自觉退出。捕获 `OperationCanceledException` 区分"取消"与"失败"，别把它当错误报给用户。

## 6. 常见坑

**UI 上同步等异步**：`RunAsync().Result` 或 `.Wait()`——死锁（续体等 UI 线程，UI 线程在等续体）。等就是 `await`，没有例外。

**async void 吞异常**：`async void` 方法抛出的异常没人接，直接崩进程。规则：**事件处理器可以用 async void（框架契约），其他一律 async Task**；命令里用 `_ = RunAsync()` 并在 RunAsync 内 try/catch。

**忘记 await**：`Task.Delay(200);` 少写 await，编译器警告 CS4014，任务在后台无人看管地跑。警告别忽略。

**await 后碰了不该碰的上下文**：await 续体回到 UI 线程没错，但如果你 `ConfigureAwait(false)` 了，续体就在线程池——之后更新绑定属性会崩。UI 层代码不要用 ConfigureAwait(false)，它属于库层。

**进度回调洪水**：百万次循环每次 Report 一次，队列被排爆。合并节流（每 N 次或每 100ms 报一次）。

## 7. 实战建议

- 默认写法：命令 → `_ = RunAsync()` → 方法内 try/catch + await 异步 API；进度用绑定属性或 IProgress<T>
- 禁用"再启动"：任务进行中把 StartCommand 的 CanExecute 置 false（第 07 章），防重入
- 保存/打开文件这类有后果的异步操作要处理竞态：连点两次"保存"至少要防并发写同一文件（原子写：先写临时文件再替换）
- 第 12 章实战项目的文件读写全走 async API（`File.ReadAllBytesAsync`/`WriteAllTextAsync`），状态栏实时显示"正在打开…/已保存"，是本章模式的最小应用

---
上一章：[08 样式、触发器与模板](08-styles.md) ｜ 下一章：[10 对话框与文件 IO](10-dialogs-files.md)
