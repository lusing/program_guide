# 30 · 事件系统与消息循环（⭐）

16 章用过事件、29 章摸过 Application.Run——本章拆开引擎盖：**事件在 LCL 里
到底是什么、消息怎么流动、有哪几条通道、什么时候必须手动泵消息**。这层
知识是从"会用控件"到"能写自定义控件（34 章）与多线程 GUI（28 章）"的
分水岭。

## 1. 事件 = published 方法指针

```pascal
property OnClick: TNotifyEvent read FOnClick write FOnClick;
// TNotifyEvent = procedure(Sender: TObject) of object
Btn.OnClick := @BtnClick;      // 挂接 = 给方法指针赋值（of object 带 Self）
```

所以：事件可以挂、可以换、可以摘（赋 nil）、可以用 `Assigned(OnClick)` 探测
——它就是个字段。控件内部触发就是一次"指针非空就调用"：

```pascal
if Assigned(OnClick) then OnClick(Self);
```

**这解释了 17 章的横评表**：触发不触发 OnChange 是每个控件 setter 里**手写**
的判定——`TTrackBar.SetPosition` 里调了，`TCalendar.SetDateTime` 里没调，
不存在统一机制，只能实测。

## 2. 消息：事件的底层货币

LCL 把一切（鼠标、键盘、绘制、定时器、系统通知）统一成 `TLMessage` 记录流。
每个 TControl 都有一条必经之路 `WndProc`——覆写它就拿到了"比事件更底层"
的拦截权：

```pascal
procedure TMsgForm.WndProc(var TheMessage: TLMessage); override;
begin
  case TheMessage.Msg of
    LM_APP_PING, LM_APP_DATA:          // 自定义消息（见 §4）
    begin
      Inc(WndHits);
      LastWParam := TheMessage.WParam; // WParam/LParam 是消息的两个随件
    end;
  end;
  inherited WndProc(TheMessage);       // ★ 不转发 = 吞掉（绘制鼠标全停摆）
end;
```

**铁律**：拦截后必须 `inherited WndProc` 转发（除非你就是想吞）——LCL 默认
处理把消息翻译成事件（LM_LBUTTONDOWN → OnMouseDown 之类）。

比 WndProc-case 更"事件化"的绑定——`message` 指令（静态、编译期接线）：

```pascal
procedure HandlePing(var Msg: TLMessage); message LM_APP_PING;
// 这条消息直接路由到这个方法，不用写 case（WndProc 也会先经过）
```

## 3. 消息三通道（selftest 实测）

| 通道 | 语义 | 实测证据 |
|---|---|---|
| `Perform(Msg, W, L)` | **同步直呼**：不等队列，发完即已处理 | 发完 WndHits 立刻=1 |
| `PostMessage(Handle, Msg, W, L)` | **异步入队**：泵了才到 | 3 条入队后计数不动；ProcessMessages 后全到且保序 |
| `SendMessage(Handle, ...)` | 跨窗体直呼对方 WndProc（同步，Perform 的"指定收件人"版） | 同 Perform 语义 |

```pascal
f.Perform(LM_APP_PING, 42, 0);               // 同步：下一行就能读到副作用
PostMessage(f.Handle, LM_APP_DATA, I, 0);    // 异步：只是排队（Handle 首次访问会创建句柄）
for I := 1 to 20 do Application.ProcessMessages;   // 手动泵——消息这才送达
```

选型：**要"问一句拿结果"用 Perform/SendMessage；要"通知别阻塞我"用
PostMessage**。后台线程只能 PostMessage/Queue（SendMessage 跨线程会等待
目标线程——死锁温床）。

## 4. 自定义消息：LM_USER 起

LCL 消息号从 `LM_USER = $400` 起留给应用（lmessages 单元，与 Windows
WM_USER 同值）：

```pascal
const
  LM_APP_PING = LM_USER + 100;
  LM_APP_DATA = LM_USER + 101;
```

自定义消息是"绕过事件系统"的正规军通道：往 WParam/LParam 里塞 PtrInt
（指针要小心生命周期——收发双方约好所有权，28 章线程回传的保守做法是
只传值或传队列索引）。

## 5. QueueAsyncCall：LCL 的"回主线程"标准通道

```pascal
Application.QueueAsyncCall(@f.DoAsync, 77);   // 排队（带一个 PtrInt）
Application.ProcessMessages;                  // 泵——回调在主线程执行
```

实测：入队后、泵之前不执行；泵时带参执行。它和 28 章 `TThread.Queue`
是近亲（Queue 内部就走向量化的异步调用），共同纪律：**回调执行在主线程
消息循环里**——GUI 状态随便碰，但意味着泵不转它就不来。

用法场景：把"稍后再做"合法化——拖动中累积一次重算（30 章防抖的正解，
23 章埋的指针在这兑现）、跨线程结果回传、以及避免在消息处理器里同步
触发另一轮同消息（重入）。

## 6. ProcessMessages：手动泵与它的坑

`Application.Run` 是"泵到退出"；`ProcessMessages` 是"泵一把就回来"。
两个坑：

1. **重入**：泵会把队列里**所有**挂起消息处理掉——包括用户刚又点了一次
   "删除"。处理器里先 `Btn.Enabled := False` 再泵，是防重入的最小姿势；
   更干净的是 QueueAsyncCall（本轮处理完才轮到它）。
2. **饥饿**：长循环里每圈泵一次能让界面活着，但也让"取消"按钮可点——
   28 章的答案是干脆把长活挪进 TThread。

## 7. 一张流向图

```text
OS 原生消息（win32 等）
   ↓  widgetset 层翻译
TLMessage（LM_*）
   ↓  TControl.WndProc（覆写=拦截层）
   ↓  LCL 默认处理：消息→事件判定
事件方法指针（OnXxx）
   ↓  你的 @Handler
业务代码
```

自定义控件（34 章）常在这条链的每一层安家：WndProc 拦原生行为、message
方法收通知、事件再发布给使用者——届时回看本章。

## 8. 示例与验证

```powershell
pwsh -File build.ps1 -Example 30_events_messages
```

selftest 覆盖：Perform 同步到 WndProc（含 WParam 传递、message 方法命中）、
PostMessage 异步（泵前计数不动、泵后 3 条全到且保序）、QueueAsyncCall
（泵前不执行、泵后带参执行、与 28 章语义闭环）、未挂接事件=nil。

## 9. 坑位清单（实测）

1. WndProc 覆写后**必须 inherited 转发**——不转发=吞消息（绘制/鼠标停摆）。
2. PostMessage 的收件人是 `Handle`——首次访问触发句柄创建（lazy）；
   句柄没建就发=发给空气。
3. 后台线程禁用 SendMessage/Perform（同步等待 → 死锁）；用 PostMessage
   或 28 章的 Queue/Synchronize。
4. ProcessMessages 处理**全部**挂起消息——重入风险自负（先禁用入口控件
   或改 QueueAsyncCall）。
5. 自定义消息号从 `LM_USER($400)` 起步（LM_USER 前面是 LCL 自留地）。
6. 事件触发面逐控件实测（17 章横评表）——"程序赋值触发吗"没有统一答案。

---
上一章：[29 应用与窗体生命周期](29-form-lifecycle.md) ｜ 下一章：[31 焦点、键盘与输入验证](31-focus-validation.md) ｜ 返回：[README](../README.md)
