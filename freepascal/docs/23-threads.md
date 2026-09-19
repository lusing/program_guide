# 23 · 多线程与后台任务（⭐）

## 1. 为什么 GUI 需要多线程

单线程 GUI 里做慢活（读大文件、算总账、下网络）= 界面冻结（消息循环停转，
白屏、"未响应"）。解法永远是同一个形状：**慢活扔后台线程，结果/进度回主线程**。
FPC 的 `TThread` + LCL 的 `Synchronize/Queue` 就是这套机制的成品。

## 2. TThread：Execute 是线程的身体

```pascal
type
  TWorker = class(TThread)
  protected
    procedure Execute; override;          // 线程从这里开始跑，返回即结束
  public
    constructor Create;
  end;

constructor TWorker.Create;
begin
  FCrit := TCriticalSection.Create;
  inherited Create(False);                // False = Create 返回时线程已在跑（默认挂起=传 True）
end;

procedure TWorker.Execute;
var i: Integer;
begin
  for i := 1 to 1000 do
  begin
    if Terminated then Break;             // 取消协作点：Terminate 只设标志，这里自查
    FTotal += i;
    if i mod 10 = 0 then
      Synchronize(@DoReportProgress);     // 回主线程汇报（下节）
  end;
end;
```

生命周期要点：

- `CreateSuspended`（构造参数）：False 立即开跑；True 挂起等你 `Start`。
- **`FreeOnTerminate` 默认 False**——主线程负责 Free（selftest 要读结果，用默认；
  "发后不管"的线程才设 True）。
- `Terminate` **只是设标志**，不是杀线程——线程在协作点（循环里查 `Terminated`）
  自行退出。杀线程的想法本身就该被消灭。
- `WaitFor` 阻塞等线程结束（主线程慎用——会冻界面；后台等后台没问题）。
- 线程对象析构前必须先结束（WaitFor 或确认 Finished）——对活线程 Free 是崩溃。

## 3. LCL 铁律与 Synchronize vs Queue

**铁律：非主线程不得直接碰 LCL 控件**（控件背后是 Win32 窗口 + 消息，跨线程操作
= 玄学崩溃）。回主线程只有两个正道：

```pascal
Synchronize(@DoReportProgress);   // 阻塞式：投递后睡到主线程执行完才返回
Queue(@DoReportProgress);         // 异步式：投递即返回，主线程稍后执行
```

| | Synchronize | Queue |
|---|---|---|
| 调用线程 | 阻塞等结果 | 立即返回 |
| 主线程执行时机 | 尽快（下一次消息循环/CheckSynchronize） | 同左 |
| 风险 | 线程互等死锁（主线程恰在 WaitFor 它） | 线程先死、回调后到（访问已释放对象） |

经验法则：**要"完成后的结果"用 Synchronize；高频进度推送用 Queue**
（配合"回调只碰还活着的对象"的设计）。

**主线程怎么"收到"回调**：消息循环每轮自动泵 Synchronize/Queue 队列
（`Application.ProcessMessages`/`Application.Run` 都会）。**没有消息循环的环境**
（selftest、控制台）手动泵：`CheckSynchronize`——本章 selftest 就是靠它在无头
环境里验证了 100 次进度回调。

## 4. 共享数据：TCriticalSection

```pascal
FCrit := TCriticalSection.Create;
...
FCrit.Enter;
try
  FProgressPct := i div 10;      // 锁内改共享状态
finally
  FCrit.Leave;
end;
```

- Enter/Leave 必须严格配对（try-finally 护住）——忘 Leave = 全体死等。
- 锁的粒度最小化：锁内只做赋值/读写，绝不做耗时活、绝不再进另一把锁（死锁配方）。
- SyncObjs 单元还送 `TEvent`（信号）/`TMutex`/`TSemaphore`（POSIX/Win 通吃）。
- 只读共享（快照）不需要锁——22 章画板"数据在主线程、线程只读"就是免锁设计。

## 5. 进度回传的完整闭环（示例结构）

```text
后台线程 Execute               主线程
─────────────                 ──────
计算 i 循环
  改 FProgressPct（锁内）
  Synchronize(@DoReport) ───→ DoReportProgress：
                                  Progress.Position := FProgressPct
                                  （这里碰控件，合法——在主线程）
循环完 → Execute 返回
                              等到 Finished → WaitFor → 读 Total → Free
```

示例 `StartBtnClick` 的等待循环是 GUI 版标准姿势：

```pascal
while not Worker.Finished do begin
  Application.ProcessMessages;    // 泵消息：既响应界面又执行 Synchronize 队列
  Sleep(1);
end;
Worker.WaitFor;
```

（更优雅的"完成通知"是 Queue 一个回调而不是轮询——示例保持简单，思路同源。）

## 6. 取消：协作式的艺术

```pascal
// 取消方
Worker.Terminate;                  // 设标志，仅此而已
// 线程方（Execute 循环里）
if Terminated then Break;
```

实测（selftest 第二段）：`Create` 后立刻 `Terminate`，线程在第一个协作点退出，
Total=0 而非 500500——**取消是被"请求"的，线程自己决定何时何地响应**。
长任务要多埋协作点（每个 chunk 查一次），否则"取消"按钮按了没反应。

## 7. 示例与验证

本章示例 `examples/23_threads`：TWorker（求和 + 锁 + Synchronize 汇报 + 取消点）、
GUI 版进度条闭环、selftest 用 CheckSynchronize 无头验证（全量 500500/100 次回调；
Terminate 早期退出）。

```powershell
pwsh -File build.ps1 -Example 23_threads
```

## 8. 坑位清单（实测）

1. **非主线程碰控件 = 玄学崩溃**——Synchronize/Queue 是唯一通道。
2. `FreeOnTerminate=True` + 主线程还持有引用 = 悬垂访问——要读结果就用默认 False。
3. `Terminate` 不是杀线程——循环里没有 `if Terminated` 检查的线程永远取消不了。
4. 无消息循环（selftest/控制台）Synchronize 永远不执行——手动 `CheckSynchronize` 泵。
5. 非主线程 WaitFor 自己人：主线程 WaitFor 一个正 Synchronize 等自己的线程 = 死锁。
6. 窗体字段放非 TPersistent 后代类（如 TThread 子类）报 "Only classes compiled in $M+
   mode can be published"——挪到 public 段（TForm 默认段是 published）。
7. Enter/Leave 必须 try-finally——异常路径忘解锁就全队死等。

---
上一章：[22 绘图与自绘](22-canvas.md) ｜ 下一章：[24 实战：记事本+](24-notepad.md) ｜ 返回：[README](../README.md)
