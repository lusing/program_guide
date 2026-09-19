# 第 27 章 Windows 服务与事件日志

> **本章回答的问题**：服务是什么、和普通程序差在哪？SCM 怎么调度服务？`ServiceMain` 的五要素是什么？怎么安装/启动/停止？事件日志怎么写、去哪看？
>
> **前置章节**：第 14 章（停止事件/等待——服务的骨架就是它）、第 17 章（为什么安装服务要管理员）、第 21 章（服务的家在注册表，事件源的注册同理）。
>
> **你将做出什么**：一个可安装的最小服务（`examples/30_windows_service`）+ 它的"双模式"开发法：不装也能先验证业务逻辑。

本章示例：`examples/30_windows_service/main.cpp`。

## 27.1 服务是什么：Session 0 里的长住客

服务（service）= **无 UI、随系统启动、长驻后台**的程序。数据库引擎、打印队列、杀毒监控、驱动辅助——服务器世界的常驻人口全是服务。它与你已写的控制台程序有两个本质差异：

1. **由 SCM（Service Control Manager，服务控制管理器）管理生命周期**：启动、停止、状态查询都经它，不归用户双击；
2. **住在 Session 0**： Vista 起服务与用户桌面隔离在 不同会话——**服务弹的 MessageBox 用户根本看不见**（还会卡死服务！），这条隔离叫 Session 0 Isolation，是安全设计（老木虫靠服务窗口攻击桌面的路被堵死）。

所以服务的铁律：**不碰 UI，输出走事件日志**（27.6）。

## 27.2 生命周期与调度：SCM 怎么找到你的代码

```text
安装（一次）：CreateServiceW → 注册表 HKLM\SYSTEM\CurrentControlSet\Services\名字
启动（每次）：SCM 读注册表 → CreateProcess 启动你的 exe（带特殊标志）
   │
   ▼ 你的 main 必须尽快调：
StartServiceCtrlDispatcherW(服务表)      ★ 服务 exe 的"报到"动作
   │  SCM 据此确认"这真是服务"，并为它连上管道
   ▼ SCM 在新线程上调你登记的：
ServiceMain(...)                          ★ 服务入口（相当于服务的 wWinMain）
   │  在这里注册控制处理器、报状态、进入工作循环
   ▼
停止：SCM → 你注册的 HandlerEx → 你 SetEvent → 循环退出 → 报 STOPPED → SCM 结案
```

`SERVICE_TABLE_ENTRYW` 表里登记"服务名 → ServiceMain"，与第 4 章"注册窗口类 → 系统回调 WndProc"完全同构——**又是"你注册、系统调用你"**。双击服务 exe 会怎样？`StartServiceCtrlDispatcherW` 发现自己不在 SCM 手里，直接失败——30 示例利用这一点打印"可用动词"提示，一个 exe 同时是服务与命令行工具。

## 27.3 ServiceMain 五要素

30 示例的 `ServiceMain` 就是标准模板，五个要素一个不能少：

```cpp
static void WINAPI ServiceMain(DWORD, LPWSTR*) {
    // ① 注册控制处理器：SCM 的停止/暂停请求送到 HandlerEx
    g_statusHandle = RegisterServiceCtrlHandlerExW(kSvcName, HandlerEx, nullptr);
    if (!g_statusHandle) return;

    g_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    g_status.dwControlsAccepted = SERVICE_ACCEPT_STOP;        // 声明会响应什么
    ReportState(SERVICE_START_PENDING, 2000);                 // ② 报"正在启动"

    g_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);// ③ 停止信号（14 章）
    ReportState(SERVICE_RUNNING);                             // ④ 报"已就绪"

    RunServiceCore(true);          // ★ 工作循环：等停止事件，其间干活+写日志

    ReportState(SERVICE_STOPPED);                              // ⑤ 报"已停止"收尾
}
```

为什么要反复报状态？SCM 有超时预算：`START_PENDING` 超过约 30 秒没下文就判服务"失败"；`waitHint` 告诉它"给我 N 毫秒"，长初始化还应周期性报 checkpoint。**忘报 `SERVICE_STOPPED`** 是经典事故：服务明明退了，`services.msc` 里永远显示"正在停止"。

`HandlerEx` 收到 `SERVICE_CONTROL_STOP` 时只做两件事：报 `STOP_PENDING` + `SetEvent`——真正的收尾留给主循环自然走完（优雅退出，不杀线程）。

## 27.4 安装与治理：服务控制 API 与 sc.exe

安装一次性的活（`CreateServiceW`），治理是日常（start/stop/query）：

| 动作 | API | sc.exe 等价 |
|------|-----|------------|
| 安装 | `CreateServiceW(scm, 名, 显示名, 权限, SERVICE_WIN32_OWN_PROCESS, SERVICE_DEMAND_START, ...)` | `sc create GuideDemoSvc binPath= "..."` |
| 启动 | `StartServiceW` | `sc start GuideDemoSvc` |
| 停止 | `ControlService(SERVICE_CONTROL_STOP)` | `sc stop GuideDemoSvc` |
| 删除 | `DeleteService`（标记，真删要等句柄全关） | `sc delete GuideDemoSvc` |
| 枚举 | `EnumServicesStatusW` | `sc query` |

三个要点：**安装/启动/停止都要管理员**（SCM 的写操作走 HKLM 与特权，17 章），唯独**枚举标准用户可跑**（30 示例的 `list` 模式）；`SERVICE_DEMAND_START`（手动）vs `SERVICE_AUTO_START`（开机自启）在安装时定；服务运行账户默认 `LocalSystem`（权限极大），最小权限实践是建专用账户或 `NetworkService`。

## 27.5 双模式开发法：先 console 验证业务

服务的调试体验差（要装、要管理员、看不到输出）。30 示例的工程解法值得抄走：**核心循环与"服务性"分离**——

```cpp
static void RunServiceCore(bool asService) {     // 业务逻辑：只认停止事件
    while (WaitForSingleObject(g_stopEvent, 1000) == WAIT_TIMEOUT) {
        if (asService) LogEvent(...);            // 服务模式：写事件日志
        else           wprintf(...);             // 控制台模式：直接打印
    }
}
```

开发时 `console` 动词就地跑（3 秒内心跳可见、无需安装），验收时再 `install`/`start` 走 SCM 全流程。业务代码一份，两种宿主。

## 27.6 事件日志：服务的 stdout

无 UI 程序的输出通道。三层结构：**日志**（Application/System/Security 三个大本营）→ **来源**（source，你的服务名）→ **事件**（一条条记录）。写就三步：

```cpp
HANDLE hLog = RegisterEventSourceW(nullptr, L"GuideDemoSvc");   // ① 登记来源
const wchar_t* strings[] = { L"第 3 次心跳" };
ReportEventW(hLog,                 // ② 写一条
             EVENTLOG_INFORMATION_TYPE,   // 级别：信息/警告/错误
             0, 1,                        // 类别、事件 ID
             nullptr,                     // 用户 SID
             1, 0,                        // 字符串数、原始数据字节数
             strings, nullptr);
DeregisterEventSource(hLog);                                    // ③ 注销
```

**去哪看**：事件查看器（`eventvwr.msc`）→ Windows 日志 → 应用程序，按来源名过滤。命令行 `wevtutil q Application /q:"*[System[Provider[@Name='GuideDemoSvc']]]"` 直接捞。

两个进阶认知：未注册"消息 DLL"的来源，查看器会抱怨"找不到描述"但**插入字符串照样显示**（30 示例就是这个状态——教学够用，产品级要配 message resource 编译）；`Security` 日志只有系统自己能写（审计策略管着）。

## 27.7 调试与观测

- **附加进程**：VS"调试 → 附加到进程"勾选"显示所有用户的进程"，找到服务进程 attach——断点照打（前提：服务已在跑；`SERVICE_AUTO_START` 的服务可在注册表加 `Image File Execution Options` 的 Debugger 键用调试器拉起，进阶）；
- **日志代替 printf**：所有观测输出走事件日志/DebugView 双通道；
- 状态机自检：`sc query` 的 `STATE` 应与 `ReportState` 序列一致，不一致 = 你漏报状态。

## 27.8 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| 服务装上后启动即"失败" | `ServiceMain` 忘报 `RUNNING` 超时 | 27.3 五要素 |
| services.msc 永远"正在停止" | 没报 `SERVICE_STOPPED` | 收尾必报 |
| `CreateService` 拒绝访问 | 不是管理员 | 提权（17 章） |
| 服务里弹 MessageBox 程序卡死 | Session 0 隔离，无人点确定 | 服务禁 UI（27.1） |
| `StartServiceCtrlDispatcherW` 直接失败 | 非 SCM 启动（双击） | 正常，转命令行模式（27.2） |
| 停止请求没反应 | HandlerEx 没接 / 没声明 `SERVICE_ACCEPT_STOP` | 27.3 ① |
| HandlerEx 里干重活 | 控制处理器要快回 | 只 SetEvent，活留给主循环 |
| 事件查看器"找不到描述" | 无消息 DLL | 教学可忍；产品配 message resource |

## 27.9 小结

1. 服务 = SCM 管理的无 UI 长驻程序，住 Session 0（隔离即安全，禁 UI）。
2. 调度链：注册表 → SCM 拉起 exe → `StartServiceCtrlDispatcherW` 报到 → `ServiceMain` 五要素（注册处理器/报状态/停止事件/工作循环/报停止）。
3. 治理 API 与 sc.exe 一一对应；装/启/停要管理员，枚举不要。
4. 双模式开发法：业务循环认"停止事件"，服务/控制台两种宿主。
5. 事件日志三步写（Register/Report/Deregister），查看器按来源过滤。

## 27.10 动手练习

1. 给心跳加"参数化间隔"：`ServiceMain` 的第二参是启动参数数组（`sc start GuideDemoSvc 500` 传入），把它解析成毫秒数。
2. 实现"暂停/继续"：声明 `SERVICE_ACCEPT_PAUSE_CONTINUE`，`HandlerEx` 里接 `SERVICE_CONTROL_PAUSE`，用第二个事件（或 `PauseableWork` 标志位）让循环可暂停可恢复——状态机再上两层。
3. 让 console 模式把心跳同时写进事件日志：控制台验证 + 查看器复核双通道。

---

**下一章**：[第 28 章 Shell 集成](28-Shell集成.md)——托盘、通知与桌面对话。
