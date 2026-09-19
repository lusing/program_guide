# 第 28 章 Shell 集成：托盘、通知与桌面对话

> **本章回答的问题**：托盘图标怎么挂、事件怎么回来？右键菜单为什么要点外面收不起来？气泡通知怎么发？Explorer 崩了图标没了怎么办？"最小化进托盘"的完整交互怎么拼？
>
> **前置章节**：第 4 章（自定义消息/`RegisterWindowMessage`）、第 7 章（弹出菜单与工具栏世界）、第 26 章（现代 Toast 的边界）。
>
> **你将做出什么**：一个完整的托盘程序（`examples/31_shell_tray`）：图标常驻、右键菜单、气泡通知、最小化进托盘、Explorer 重启自愈。

本章示例：`examples/31_shell_tray/main.cpp`。

## 28.1 托盘图标：`Shell_NotifyIconW` 三动作

托盘（通知区域）图标不是窗口，是一份**登记信息**（`NOTIFYICONDATAW`）+ 一个三动作 API：

```cpp
NOTIFYICONDATAW nid = {};
nid.cbSize           = sizeof(nid);
nid.hWnd             = hwnd;                 // 事件的收件人（你的窗口）
nid.uID              = 1;                    // 同窗口多图标时的编号
nid.uFlags           = NIF_MESSAGE | NIF_ICON | NIF_TIP;
nid.uCallbackMessage = WM_TRAYICON;          // ★ 事件路由到这个自定义消息
nid.hIcon            = LoadIconW(nullptr, IDI_APPLICATION);
lstrcpynW(nid.szTip, L"托盘演示", 128);       // 悬停提示

Shell_NotifyIconW(NIM_ADD,    &nid);   // 挂上
Shell_NotifyIconW(NIM_MODIFY, &nid);   // 改图标/提示/发气泡
Shell_NotifyIconW(NIM_DELETE, &nid);   // ★ 收走——退出不删就留"幽灵图标"
```

**事件怎么回来**是新手最懵的部分：鼠标点图标时，Shell 给 `nid.hWnd` 发一条 `uCallbackMessage` 指定的消息，**事件类型放在 `lParam`**（真实消息值：`WM_RBUTTONUP`、`WM_LBUTTONDBLCLK`...），`wParam` 是图标 uID：

```cpp
case WM_TRAYICON:                    // WM_APP+1 起的自定义消息区（第 4 章）
    if (lParam == WM_RBUTTONUP)          ShowMenu(hwnd);
    else if (lParam == WM_LBUTTONDBLCLK) ShowWindow(hwnd, SW_SHOW);
    return 0;
```

（记反 wParam/lParam 是高发笔误——对照第 4 章位布局的习惯：通知里 lParam 常载"发生了什么"。）

## 28.2 托盘右键菜单：`SetForegroundWindow` 的老偏方

弹出菜单用第 7/10 章的 `CreatePopupMenu` + `TrackPopupMenu`，但托盘场景有个 20 年历史的老 bug：**点菜单外面，菜单不收起**——因为托盘菜单属于"失焦窗口"，系统等不到失焦事件。官方 workaround 一行：

```cpp
SetForegroundWindow(hwnd);     // ★ 弹菜单前先把宿主窗口提到前台
TrackPopupMenu(menu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, nullptr);
```

（微软文档明文建议；有的代码还会在菜单后补一条无关消息帮窗口"落焦"，现代系统上前面那一行基本够用。）

## 28.3 气泡通知：`NIF_INFO`

```cpp
nid.uFlags = NIF_INFO;                       // 这次 MODIFY 只动气泡字段
lstrcpynW(nid.szInfo,       L"内容……", 256);
lstrcpynW(nid.szInfoTitle,  L"标题",     64);
nid.dwInfoFlags = NIIF_INFO;                 // 图标：信息/警告/错误/无
Shell_NotifyIconW(NIM_MODIFY, &nid);
```

气泡几秒后自动消失；用户点击会以 `NIN_BALLOONUSERCLICK` 到达回调消息。**现代替代是 WinRT Toast**（第 26 章）——视觉更好、交互更强，但需要应用身份（26.7 的 AUMID 要求）。选型：内部工具/无打包程序用气泡最省事；正经产品上 Toast。

## 28.4 Explorer 重启自愈：`TaskbarCreated`

Explorer 崩溃重启（或你手动结束 explorer.exe 进程）后，**所有托盘图标清空**——Shell 不会替你恢复。协议：Explorer 重启完成时向所有顶层窗口广播注册消息 `TaskbarCreated`，你收到就重挂图标：

```cpp
// wWinMain 里登记一次（值每系统不同，所以必须"注册"而不是写死）
g_taskbarCreatedMsg = RegisterWindowMessageW(L"TaskbarCreated");

// WndProc 的 default 分支里比对（它是动态值，进不了 switch）
default:
    if (msg == g_taskbarCreatedMsg) {
        AddTrayIcon(hwnd);                   // 重挂：内部就是 NIM_ADD
        return 0;
    }
```

`RegisterWindowMessageW` 的机制值得一句：系统保证"同名字符串 → 全系统唯一消息号"，是跨程序约定自定义消息的标准手法（同一个思路还能用于两个自己的程序间通信）。

## 28.5 完整交互流：最小化进托盘

31 示例拼出产品级托盘程序的完整回路：

```text
WM_CREATE          → NIM_ADD 挂图标
最小化按钮          → WM_SIZE(SIZE_MINIMIZED) → ShowWindow(SW_HIDE)
                     （窗口藏、图标留 = "最小化进托盘"）
图标右键            → ShowMenu：显示窗口 / 发通知 / 退出
图标双击            → ShowWindow(SW_SHOW) 复活窗口
"退出"              → DestroyWindow → WM_DESTROY → NIM_DELETE 收图标 → PostQuitMessage
Explorer 重启       → TaskbarCreated → 重挂
```

## 28.6 更多 Shell 接驳：全景表

托盘只是 Shell 集成的入口，其余各支按需取用：

| 能力 | 关键 API | 备注 |
|------|---------|------|
| 打开 URL/文件/邮件 | `ShellExecuteW(nullptr, L"open", path, ...)` | `runas` 动词=提权运行（17 章） |
| 文件关联 | 注册表 `HKCU\Software\Classes\.ext`（21 章） | 让"打开方式"里有你 |
| 右键菜单扩展 | `IContextMenu`（COM，进程内 shell 扩展） | 22~24 章知识的又一战场 |
| 任务栏进度条 | `ITaskbarList3::SetProgressValue` | 下载/安装进度直接进任务栏图标（COM） |
| 跳转列表 | `ICustomDestinationList` | 任务栏右键你的图标出现的"最近文件" |
| Toast 通知 | WinRT `Windows.UI.Notifications` | 26.7 的身份要求 |

（注意 Shell 扩展类接口全是 COM——本教程的 COM 投入到这里反复分红。）

## 28.7 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| 退出后图标残留在托盘 | 没发 `NIM_DELETE` | `WM_DESTROY` 收走（28.1） |
| 点图标没反应 | 把事件类型读进了 `wParam` | 在 `lParam`（28.1） |
| 托盘菜单点外面不消失 | 缺 `SetForegroundWindow` | 28.2 老偏方 |
| Explorer 重启图标消失 | 没处理 `TaskbarCreated` | 28.4 |
| 多个图标互相覆盖事件 | `uID`/`hWnd` 组合不唯一 | 每图标独立 uID |
| 气泡发不出 | 图标没挂成功就 MODIFY | 先 ADD 后 MODIFY |
| `ShellExecute` 打不开 | 关联缺失/参数错 | 检查动词与路径 |

## 28.8 小结

1. 托盘 = `NOTIFYICONDATAW` 登记 + `NIM_ADD/MODIFY/DELETE` 三动作；退出必删。
2. 事件走自定义消息，类型在 `lParam`；菜单前 `SetForegroundWindow` 治失焦。
3. 气泡 = `NIF_INFO` 一次 MODIFY；产品级上 WinRT Toast（要身份）。
4. `TaskbarCreated` 注册消息是 Explorer 重启的自愈信号。
5. Shell 集成全家桶（关联/扩展/进度/跳转列表）几乎全是 COM 地盘。

## 28.9 动手练习

1. 给 31 示例换自定义图标：`LoadImageW` 从 .ico 文件加载（48×48），退出前 `DestroyIcon`。
2. 双击行为升级为"循环切换显示/隐藏"（提示：维护一个 bool，`ShowWindow(hwnd, visible ? SW_HIDE : SW_SHOW)`）。
3. 上 `ITaskbarList3`：装一个长任务（`WM_TIMER` 模拟），任务期间任务栏图标显示进度条——COM 三步走（`CoCreateInstance` → `SetProgressValue(hwnd, cur, total)` → Release）。

---

**下一章**：[第 29 章 剪贴板与拖放](29-剪贴板与拖放.md)——复制粘贴与拖拽的完整实现。
