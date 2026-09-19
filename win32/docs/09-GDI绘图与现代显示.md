# 第 9 章 GDI 绘图与现代显示

> 本章回答的问题：屏幕上的内容是怎么画出来的？为什么一切绘制都要发生在 `WM_PAINT` 里？`BeginPaint` 和 `GetDC` 有什么区别？GDI 对象为什么要"选中—用完—换回—删除"？窗口如何适配高 DPI？Win11 的圆角和 Mica 材质怎么加？
>
> **前置章节**：第 4 章（`WM_PAINT` 消息、`wParam/lParam`）。
>
> **你将做出什么**：一个会重绘的绘图板（`examples/07_paint_app`），以及给任何窗口加上 Win11 圆角与高分屏适配的能力。

本章示例：`examples/04_gdi_drawing`、`examples/07_paint_app`、`examples/15_dpi_modern_window`。

## 9.1 重绘模型：绘制是"被动"的

先建立整个 GDI 体系的最高层规则，它决定了一切代码的形状：

> **你的窗口内容随时可能被破坏**（被别的窗口盖住、最小化、拉伸），但 Windows 不保存你的内容。它只在你需要补画时发一条 `WM_PAINT`，其余时间不管。所以：**界面内容必须随时能由代码重画出来**。

由此推出 GDI 编程的核心分工：

- **"状态"与"绘制"分离**：程序维护一份状态数据（文本、图形列表、画过的线段），`WM_PAINT` 负责把状态完整地重画一遍；
- **状态变化时，不直接画，而是调 `InvalidateRect` 声明"这块脏了"**，系统随后合并发 `WM_PAINT`：

```cpp
// 状态变了（例如文字内容更新）
InvalidateRect(hwnd, nullptr, TRUE);   // nullptr = 整个客户区失效；TRUE = 顺带擦背景
```

`InvalidateRect` 只是把区域标脏并请求重绘，**它立即返回，不产生绘制**。系统把多次失效合并成一次 `WM_PAINT`（在队列空闲时才送），这就是为什么不闪、不浪费。反过来，在 `WM_PAINT` 之外直接拿 HDC 画东西，画的 内容会在下次重绘时凭空消失——这是初学者最常见的"我画的东西不见了"。

## 9.2 `HDC`：绘图的入口

`HDC`（设备上下文句柄）是 GDI 的"画布 + 画板状态"对象：它代表一个绘图目标（窗口、打印机、内存位图），同时携带当前的画笔、画刷、字体、颜色等状态。所有 GDI 函数第一个参数几乎都是它。

获取 `HDC` 有两条路，**时机和规矩不同，必须分清**：

| | `BeginPaint` / `EndPaint` | `GetDC` / `ReleaseDC` |
|---|---|---|
| 使用时机 | **只在 `WM_PAINT` 里** | 其他任何地方（如响应鼠标拖动画线） |
| 失效区域 | 自动验证（清掉脏区标记） | 不影响失效标记 |
| 剪裁 | 只允许画失效区域 | 整个客户区 |
| 归还 | `EndPaint` | `ReleaseDC`（**不成对会泄漏 HDC**） |

```cpp
// WM_PAINT 里的标准形态
case WM_PAINT: {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);   // 拿 HDC，ps 里带回失效区域等信息
    // ... 全部绘制 ...
    EndPaint(hwnd, &ps);               // 归还 + 验证失效区（缺了它 WM_PAINT 会无限重发！）
    return 0;
}
```

`EndPaint` 忘了调是双重 bug：HDC 泄漏 + 失效区永不验证，系统以为你还脏着，`WM_PAINT` 连发，CPU 100%。

## 9.3 GDI 对象：画笔、画刷、字体、位图

GDI 用四类对象定义"怎么画"，全是句柄，纪律统一为四步：**创建 → 选中 → 用完换回 → 删除**：

```cpp
HPEN   pen   = CreatePen(PS_SOLID, 3, RGB(255, 0, 0));   // 1) 创建：红色实线、3 像素粗
HPEN   old   = (HPEN)SelectObject(hdc, pen);             // 2) 选中：替换 DC 当前画笔，拿到旧的
MoveToEx(hdc, 20, 20, nullptr);
LineTo(hdc, 220, 220);                                   //    画线用"当前画笔"
SelectObject(hdc, old);                                  // 3) 换回旧对象
DeleteObject(pen);                                       // 4) 删除自己创建的
```

第 3 步"换回"不是洁癖：`SelectObject` 的语义是"借还制"，对象在被 DC 占用时不能删除（返回错误）。这四步在任何 GDI 代码里都成对出现，看 GDI 代码先看有没有配平。

四类对象速览：

| 对象 | 创建函数 | 控制 |
|------|---------|------|
| 画笔 `HPEN` | `CreatePen(style, width, color)` | 轮廓线条：`PS_SOLID` 实线、`PS_DASH` 虚线、`PS_NULL` 无 |
| 画刷 `HBRUSH` | `CreateSolidBrush(color)` / `CreateHatchBrush` | 填充：矩形/椭圆内部 |
| 字体 `HFONT` | `CreateFontW(...14 个参数...)` | 文字 |
| 位图 `HBITMAP` | `CreateCompatibleBitmap` / `LoadImageW` | 图像数据 |

### 文字输出

```cpp
HFONT font = CreateFontW(
    32, 0, 0, 0, FW_BOLD,            // 高度 32px、加粗（FW_NORMAL/FW_BOLD…）
    FALSE, FALSE, FALSE,             // 斜体 / 下划线 / 删除线
    DEFAULT_CHARSET,                 // 字符集
    OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
    DEFAULT_PITCH | FF_SWISS,        // 字体族（SWISS = 无衬线）
    L"Microsoft YaHei UI");          // 字体名（中文字体，UI 场景推荐）
HFONT oldFont = (HFONT)SelectObject(hdc, font);

SetTextColor(hdc, RGB(20, 20, 20));      // 文字前景色
SetBkMode(hdc, TRANSPARENT);             // ★ 文字背景透明，否则字后有白色小方块
TextOutW(hdc, 40, 40, L"Hello Win32", 11);          // 简单定位输出
// DrawTextW：支持矩形内排版（居中/换行），更常用：
RECT rc;
GetClientRect(hwnd, &rc);
DrawTextW(hdc, L"居中显示", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

SelectObject(hdc, oldFont);
DeleteObject(font);
```

`TextOutW` 的最后一个参数是**字符个数不是字节数**（宽字符下一个中文字算 1 个），写错就截断或越界。

### 图形原语

```cpp
Rectangle(hdc, x1, y1, x2, y2);   // 矩形：轮廓用当前画笔画，内部用当前画刷填
Ellipse(hdc, x1, y1, x2, y2);     // 椭圆（内切于矩形）
MoveToEx(hdc, x, y, nullptr); LineTo(hdc, x2, y2);   // 线段
Polygon(hdc, pts, count);         // 多边形
FillRect(hdc, &rc, hBrush);       // 填充矩形（不用画笔描边）
```

几何函数的坐标约定是**右边界、下边界不包含**（画 `(0,0)-(10,10)` 的矩形实际覆盖 0..9），与数学直觉略有出入，做像素级对齐时要知道。

## 9.4 双缓冲：消除闪烁

窗口复杂、刷新频繁时，直接往屏幕画会出现闪烁：擦背景和重画之间、多个图形逐个绘制之间，屏幕短暂呈现"半成品"。解法是**先在内存里画完整幅，再一次拷贝到屏幕**：

```text
闪烁路径（直接画）:                  双缓冲路径：
  擦背景(白) → 用户看见了!             memDC: 擦背景 → 画图1 → … → 画图N
  画图1     → 用户又看见了!                     │（用户全程看不见中间态）
  画图2 …                                  BitBlt 一次性上屏 → 用户只看到成品
```

```cpp
case WM_PAINT: {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);
    RECT rc;
    GetClientRect(hwnd, &rc);

    // 1) 建一块与屏幕兼容的内存画布
    HDC     memDC  = CreateCompatibleDC(hdc);
    HBITMAP memBmp = CreateCompatibleBitmap(hdc, rc.right, rc.bottom);
    HBITMAP oldBmp = (HBITMAP)SelectObject(memDC, memBmp);

    // 2) 在 memDC 上随便画多少笔——用户看不见
    HBRUSH bg = CreateSolidBrush(RGB(245, 245, 245));
    FillRect(memDC, &rc, bg);
    DeleteObject(bg);
    Ellipse(memDC, 50, 50, 250, 200);      // 全部画到 memDC

    // 3) 一次性拷贝到屏幕
    BitBlt(hdc, 0, 0, rc.right, rc.bottom, memDC, 0, 0, SRCCOPY);

    // 4) 清理（三类对象、两个 DC，一个不能少）
    SelectObject(memDC, oldBmp);
    DeleteObject(memBmp);
    DeleteDC(memDC);

    EndPaint(hwnd, &ps);
    return 0;
}
```

两个易错点：`CreateCompatibleBitmap` 的第一个参数必须是**屏幕 HDC**（不是 memDC，否则建出单色位图）；清理时位图要从 DC 里换出后才能 `DeleteObject`，DC 自己用 `DeleteDC` 归还。

另外还有一个"半官方"的减闪手段：把窗口类背景刷设为 `nullptr`，自己在 `WM_PAINT` 里铺满背景——彻底消除"系统擦背景（白闪）→ 你重画"之间的空隙。注意这样处理后别忘了 `return 1` 给 `WM_ERASEBKGND`（查文档），或干脆在 `WM_ERASEBKGND` 里 `return 1` 拦掉系统擦除。

## 9.5 实战：会重绘的绘图板

`examples/07_paint_app` 演示 9.1 节"状态与绘制分离"的完整落地。老式教程的画板用鼠标消息直接画线，结果一遮挡就丢内容——正确做法是把线段存进列表，`WM_PAINT` 重画全部：

```cpp
#include <vector>
struct Segment { POINT from; POINT to; };
std::vector<Segment> g_strokes;      // ★ 状态：全部已画线段
bool g_drawing = false;
POINT g_last{};

case WM_LBUTTONDOWN:
    g_drawing = true;
    g_last = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
    SetCapture(hwnd);                // 拖出窗口也继续收鼠标消息
    return 0;

case WM_MOUSEMOVE:
    if (g_drawing) {
        g_strokes.push_back({ g_last,
                              { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) } });
        g_last = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        InvalidateRect(hwnd, nullptr, FALSE);   // 标脏即可，绘制交给 WM_PAINT
    }
    return 0;

case WM_LBUTTONUP:
    g_drawing = false;
    ReleaseCapture();                // 与 SetCapture 成对
    return 0;

case WM_PAINT:
    // BeginPaint 后遍历 g_strokes，逐条 MoveToEx/LineTo 重画 → EndPaint
    return 0;
```

对高性能绘图，把 `WM_PAINT` 里的重画放进 9.4 的双缓冲，再进一步可把"增量线段"画进内存位图避免全量重画——思路都是同一句话：**状态在前，绘制在后**。

## 9.6 现代视角一：DWM 与 Win11 视觉

> 💡 **现代视角（Vista+ / Windows 11）**：从 Vista 起，所有窗口由 DWM（Desktop Window Manager）统一合成到屏幕——你画的其实是窗口自己的离屏表面，DWM 再把它贴到桌面。这带来硬件加速、缩略图、亚像素动画，也意味着 GDI 绘制的最终质量不受影响（合成时无缝转换）。

Win11 把一些视觉开关通过 `DwmSetWindowAttribute` 暴露给普通 Win32 程序（链接 `dwmapi.lib`）：

```cpp
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib")

// 圆角窗口（Windows 11+；老系统上调用只是返回错误码，无害）
DWM_WINDOW_CORNER_PREFERENCE pref = DWMWCP_ROUND;
DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                      &pref, sizeof(pref));

// Mica 材质：窗口背景融入桌面壁纸（Win11 22H2+，需要背景刷为 nullptr 等配合）
DWM_SYSTEMBACKDROP_TYPE backdrop = DWMSBT_MAINWINDOW;
DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE,
                      &backdrop, sizeof(backdrop));
```

旧 API `DwmExtendFrameIntoClientArea`（Vista+，玻璃边框扩展）至今仍在维护。这些调用都是"能力探测式"的：在不支持的系统上返回失败码，程序照常运行——写 Win32 程序处理新 API 的标准姿势就是**不依赖、可降级**。

## 9.7 现代视角二：Per-Monitor V2 DPI 感知

> 💡 **现代视角（Windows 10 1703+）**：今天的笔记本外接一个 125%/150% 缩放的显示器是常态。程序不声明 DPI 感知，系统会替你拉伸位图——结果就是模糊。

一行声明，让程序按每个显示器的真实 DPI 渲染：

```cpp
#include <windows.h>

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int nCmdShow) {
    // Per-Monitor V2：窗口移到不同 DPI 的屏幕时，系统发 WM_DPICHANGED 让你缩放
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    ...
}
```

配合处理缩放消息：

```cpp
case WM_DPICHANGED: {          // 仅在 Per-Monitor V2 感知下才会收到
    int newDpi = HIWORD(wParam);                  // 新 DPI（96 = 100%）
    float scale = newDpi / 96.0f;
    // 按比例缩放所有控件/布局……
    // 系统已算好建议的新窗口矩形，直接用：
    const RECT* suggested = (const RECT*)lParam;
    SetWindowPos(hwnd, nullptr, suggested->left, suggested->top,
                 suggested->right - suggested->left,
                 suggested->bottom - suggested->top,
                 SWP_NOZORDER | SWP_NOACTIVATE);
    return 0;
}
```

查询当前 DPI：`GetDpiForWindow(hwnd)`（Win10+）。布局计算的纪律：**所有尺寸用"基准像素 × scale"计算，不要写死 640×480**。老 API `SetProcessDPIAware()`（Vista）和 `SetProcessDPIAwareness`（8.1）是旧档位，新代码直接用 V2。`examples/15_dpi_modern_window` 演示了完整组合。

## 9.8 GDI 的边界与去处

GDI 至今被维护（资源管理器、记事本仍然在用），但要清楚它的定位：

- GDI 是 **2D、CPU 绘制、无抗锯齿的接口**（DWM 合成那一步除外）；
- 需要 alpha 透明、抗锯齿文字、动画性能时，现代选择是 **Direct2D + DirectWrite**——第 25 章会正式上手：你会发现"工厂 → 渲染目标 → 画刷"和本章"创建 → 选中 → 绘制"的思维完全同构，而 COM 接口的样子你在第 22~24 章早已学会；
- 3D 是 Direct3D 的领域（第 30 章学习地图指路）；
- 对本教程的目标——理解窗口模型与系统服务——GDI 是最合适的入门画笔，它的"失效-重绘"纪律甚至与 Direct2D 挂接 DComp 的模型一脉相承。

学完本章，你应当能把任何"界面怪现象"归因到四类问题之一：忘了 `EndPaint`/`ReleaseDC`（泄漏与连发）、在 `WM_PAINT` 外直接画（内容消失）、没双缓冲（闪烁）、没 DPI 感知（模糊）。

## 9.9 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| `WM_PAINT` 连发、CPU 飙满 | 忘 `EndPaint`（失效区没验证） | 9.2 |
| 画的东西过一会消失 | 在 `WM_PAINT` 外拿 DC 直接画 | 状态 + `InvalidateRect`（9.1） |
| 窗口闪烁 | 逐笔直画屏幕 | 双缓冲（9.4） |
| 删除画笔失败/行为怪 | 没换回旧对象就 `DeleteObject`（对象还被 DC 占用） | 四步配平（9.3） |
| 双缓冲出来是黑白的 | `CreateCompatibleBitmap` 传了 memDC | 传**屏幕** HDC（9.4） |
| 文字后面有白色小方块 | `SetBkMode` 没设 TRANSPARENT | 9.3 |
| 高分屏上模糊 | 没声明 DPI 感知，被位图拉伸 | Per-Monitor V2（9.7） |
| 控件位置随 DPI 错乱 | 布局写死像素 | 基准像素 × scale（9.7） |
| 窗口拖到副屏尺寸跳变 | 没处理 `WM_DPICHANGED` | 9.7 |

## 9.10 小结

1. 最高规则：内容随时可由代码重画——状态与绘制分离，`InvalidateRect` 是唯一的"重画请求"。
2. `HDC` 分两条获取路径：`WM_PAINT` 里 `BeginPaint/EndPaint`，其余场合 `GetDC/ReleaseDC`——各自成对。
3. GDI 对象四步纪律：创建 → 选中 → 换回 → 删除，任何 GDI 代码先查配平。
4. 闪烁的解法是双缓冲：内存画完整幅再一次 `BitBlt`。
5. Win11 视觉与 DPI V2 都是"能力探测式"新增：不依赖、可降级是处理新 API 的标准姿势。

## 9.11 动手练习

1. 给绘图板加颜色选择：右键循环换画笔颜色（提示：颜色存进 `Segment` 结构，重画时逐条 `CreatePen`）。
2. 把 9.4 的双缓冲套进绘图板的 `WM_PAINT`，对比加与不加时快速拖动鼠标的观感。
3. 给你的窗口加圆角 + 深色标题栏（`DWMWA_USE_IMMERSIVE_DARK_MODE`，查 SDK 文档确定值），观察在 Win11 与老系统上的表现差异。

---

**下一章**：[第 10 章 菜单、对话框与资源](10-菜单对话框与资源.md)——命令 ID 的统一分发与模态交互。
