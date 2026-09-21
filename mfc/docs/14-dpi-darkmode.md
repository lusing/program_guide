# 14 · DPI 感知与深色模式

> 对应示例：`examples/14_dpi_darkmode`

> **本章你将学会**：三种 DPI 感知级别的差别、为什么布局必须经过 `MulDiv(px, dpi, 96)`、`WM_DPICHANGED` 该怎么处理、`DwmSetWindowAttribute` 深色标题栏只管哪一半，以及怎么跟随系统主题切换。
> **前置知识**：第 05 章的窗口创建、第 09 章的自绘子窗口。

## 1. 为什么会有 DPI 问题

老程序都假设屏幕是 96 DPI（100% 缩放）。高 DPI 屏把这个假设打破了：同样一张 32 像素高的按钮图标，在 150% 缩放的屏幕上物理尺寸只剩 2/3。

系统有两种应对方式：

| 方式 | 谁来缩放 | 效果 |
|---|---|---|
| **系统缩放** | 系统把你的窗口位图拉伸放大 | 位置尺寸对了，但**模糊** |
| **应用自己缩放** | 程序感知 DPI，按实际值画 | 清晰，但布局代码要自己写 |

所有 DPI 相关工作的目标就一句话：**让程序进入"应用自己缩放"的阵营，并且换显示器时跟得上**。

关键 API：

```cpp
UINT dpi = ::GetDpiForWindow(m_hWnd);    // 窗口**所在显示器**的 DPI
UINT sys = ::GetDpiForSystem();          // 主显示器 DPI（多屏下可能不同）
```

`GetDpiForWindow` 返回的是**这个窗口当前所在那块屏**的值——笔记本 150% + 外接 100% 的组合下，把窗口从一块屏拖到另一块，这个值会变。缩放百分比就是 `MulDiv(dpi, 100, 96)`。

## 2. 三种 DPI 感知级别

| 级别 | 声明方式 | 行为 | 问题 |
|---|---|---|---|
| Unaware | 默认（老程序） | 系统拉伸整个窗口 | 全部模糊 |
| System Aware | 进程启动时按主屏 DPI 初始化 | 启动时清晰 | 拖到不同 DPI 的屏上**再次变模糊** |
| **Per-Monitor Aware v2** | `SetProcessDpiAwarenessContext` | 跟随窗口所在屏，拖动时收到 `WM_DPICHANGED` | 要自己处理缩放（本章内容） |

```cpp
BOOL CMyApp::InitInstance() {
    // 必须在任何窗口创建之前调用
    if (!::SetProcessDpiAwarenessContext(
            DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
        // 常见失败原因：清单里已声明过，或之前已调过。
        // 失败是静默的 —— 表现只是"高 DPI 下模糊"，必须检查返回值
        TRACE(_T("SetProcessDpiAwarenessContext 失败：%u\n"), ::GetLastError());
    }
    ...
}
```

**"任何窗口创建之前"不是建议而是要求**：第一个窗口创建时进程的 DPI 行为就定了，之后调用不生效（返回 `FALSE`）。`InitInstance` 的第一行是最安全的位置。

等价的另一种做法是在**清单文件**（manifest）里声明 `dpiAwareness`——两者选一，**清单优先**（清单在进程加载时就生效，比任何 API 调用都早）。命令行构建没有清单，所以示例用 API；VC 工程建议直接在清单里配。

## 3. 按 DPI 缩放布局

一个全程序共用的辅助函数：

```cpp
int Scale(int px) const {
    return MulDiv(px, static_cast<int>(m_dpi), 96);   // 96 DPI = 100%
}
```

`MulDiv(a, b, c)` = a*b/c，中间用 64 位防止 `a*b` 溢出。**所有尺寸、边距、字号都过这个函数**，不要在代码里散落裸 `MulDiv`——散落后改缩放策略就要满工程找。

这带来的直接结论：**`.rc` 模板里不要写死像素布局**。示例的对话框模板是空壳，子控件全部在运行时创建、`Layout()` 统一摆放：

```cpp
void CMainDlg::Layout() {
    CRect rc;
    GetClientRect(&rc);
    const int m = Scale(12);                        // 12 是 96 DPI 下的设计值

    m_info.MoveWindow(m, m, rc.Width() - 2 * m, Scale(72));
    m_btnDark.MoveWindow(m, m + Scale(82), Scale(170), Scale(26));
    ...
}
```

所有坐标都是"96 DPI 设计值 × 缩放因子"，改 DPI 只需要重跑一遍 `Layout()`。

### WM_DPICHANGED

拖动窗口跨屏或用户改缩放比例时，系统发来 `WM_DPICHANGED`（0x02E0）：

- `wParam`：新 DPI。**高 16 位 = X DPI，低 16 位 = Y DPI**（几乎总是相等）
- `lParam`：`RECT*`——系统**建议**的新窗口矩形

MFC 的消息映射**没有** `ON_WM_DPICHANGED` 宏，要用 `ON_MESSAGE` 手接：

```cpp
LRESULT OnDpiChanged(WPARAM wParam, LPARAM lParam) {
    m_dpi = HIWORD(wParam);
    // 系统建议的新窗口矩形，必须照做 —— 不调的话窗口尺寸不跟随，
    // 系统会把旧尺寸拉伸到新屏上，前面做的所有努力全部白费
    const RECT* prc = reinterpret_cast<const RECT*>(lParam);
    SetWindowPos(nullptr, prc->left, prc->top,
                 prc->right - prc->left, prc->bottom - prc->top,
                 SWP_NOZORDER | SWP_NOACTIVATE);
    Layout();          // 整体重排子控件
    return 0;
}

BEGIN_MESSAGE_MAP(CMainDlg, CDialog)
    ON_MESSAGE(WM_DPICHANGED, &CMainDlg::OnDpiChanged)
END_MESSAGE_MAP()
```

> **`ON_MESSAGE` 的处理函数签名必须严格是 `LRESULT (WPARAM, LPARAM)`**。写成 `UINT wParam` 会让宏里那个 `static_cast<LRESULT (CWnd::*)(WPARAM, LPARAM)>` 不再是合法转换，在消息表（const 数组）里直接报 **C2737**——本示例实际踩过。MFC 消息映射里所有手写消息（`ON_MESSAGE`/`ON_REGISTERED_MESSAGE`）都受此约束。

## 4. 深色标题栏

Windows 10 起标题栏颜色可以由应用选择，走 DWM（桌面窗口管理器）：

```cpp
#include <dwmapi.h>

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20    // 旧 SDK 头文件里没有，兜底
#endif

BOOL dark = TRUE;
::DwmSetWindowAttribute(m_hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE,
                        &dark, sizeof(dark));
```

链接需要 `dwmapi.lib`（示例通过 build.ps1 的库白名单加上；MFC 的 `afx.h` 不自动链它）。

三个必须知道的事实：

- **它只改非客户区**——标题栏、边框。**客户区完全不动**，编辑框还是白的、自绘控件还是亮的。想让客户区变黑只能自己画：示例里的面板用 `OnEraseBkgnd` 填 `RGB(32,32,32)`、文字用浅色。
- 常量在旧版 SDK 的 `dwmapi.h` 里不存在（Win10 1903 才加进去）。`#ifndef` 兜底是成本最低的兼容手段——本章示例用的 SDK（10.0.26100）里已经有了，兜底只是防御。
- 改完**立即生效**，不需要重绘消息配合。

读系统当前主题偏好：

```cpp
static bool IsSystemDark() {
    DWORD v = 1, size = sizeof(v);
    ::RegGetValue(HKEY_CURRENT_USER,
        _T("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"),
        _T("AppsUseLightTheme"),      // 1 = 浅色，0 = 深色
        RRF_RT_REG_DWORD, nullptr, &v, &size);
    return v == 0;
}
```

这个键是 Windows 设置里"选择默认 Windows 模式 / 选择默认应用模式"的落点。`RegGetValue` 在 `advapi32.lib` 里，MFC 的 `afx.h` 已自动链接。

## 5. 响应系统主题变化

用户在设置里切换深浅色时，所有顶层窗口收到 `WM_SETTINGCHANGE`。`lParam` 是**变更类别的字符串**，主题切换时是 `"ImmersiveColorSet"`：

```cpp
afx_msg void OnSettingChange(UINT uFlags, LPCTSTR lpszSection) {
    if (lpszSection && lstrcmpi(lpszSection, _T("ImmersiveColorSet")) == 0) {
        m_dark = IsSystemDark();    // 重读偏好
        ApplyDark();                // 标题栏 + 自绘客户区一起切
    }
    CDialog::OnSettingChange(uFlags, lpszSection);
}
```

`lpszSection` 可能为 `NULL`，**判空再比较**。别把它和 `WM_THEMECHANGED` 混淆：`WM_THEMECHANGED` 是视觉样式（主题包、系统颜色度量）变化时发的，年代更早、粒度不同；跟"深浅色模式"打交道用 `WM_SETTINGCHANGE` + `"ImmersiveColorSet"`。

## 常见坑

1. **`SetProcessDpiAwarenessContext` 在窗口创建之后调**
   第一个窗口创建时 DPI 行为已经定型，之后调用返回 `FALSE` 且**什么都不改**——程序继续模糊。不检查返回值的话，你永远不会知道感知级别根本没生效。

2. **`.rc` 模板里写死像素**
   96 DPI 设计的对话框在高 DPI 屏上要么控件挤成一团要么窗口巨大。模板只留壳，布局放 `Layout()` 统一过 `Scale()`。

3. **`WM_DPICHANGED` 里不按 `lParam` 的矩形调整窗口**
   尺寸不跟随，系统把旧尺寸的窗口拉伸到新屏——**位图模糊，恰好退化回 System Aware 的最差效果**。`lParam` 的矩形是系统算好的，照做。

4. **`ON_MESSAGE` 处理函数参数写成 `UINT`**
   宏里的 `static_cast` 要求签名严格等于 `LRESULT (WPARAM, LPARAM)`，任何参数类型偏差都会让消息表的常量初始化失败，报 **C2737**（"const 对象必须初始化"）——报错位置在消息映射数组而不是你的函数，非常迷惑。

5. **以为深色模式 API 会把客户区也变黑**
   `DWMWA_USE_IMMERSIVE_DARK_MODE` 只管标题栏和边框。客户区要配套：`OnEraseBkgnd` 填深色、自绘文字换浅色、系统控件的背景靠 `OnCtlColor`（第 10 章）。

6. **`OnSettingChange` 里不判空就比较字符串**
   `lpszSection` 可能为 `NULL`，直接 `lstrcmpi` 会崩。

7. **多屏程序用 `GetDpiForSystem` 排版**
   那是主显示器的值。窗口拖到副屏后一切尺寸都错。**永远用 `GetDpiForWindow`**。

## 实战建议

- **全程序只允许一个 `Scale()` 函数**，集中在一个头文件里；散落的 `MulDiv(px, dpi, 96)` 是将来统一改缩放策略时最大的敌人
- **深色模式至少做三层**：标题栏（DWM API）+ 自绘客户区（`OnEraseBkgnd`）+ 系统控件（`OnCtlColor` 返回深色刷子）。只做第一层，标题黑内容白，比不改还难看
- **命令行/无清单工程用 API 声明 DPI 感知，VC 工程用清单**：清单在进程加载时生效，比 API 的调用时机可靠得多
- **启动时就读 `IsSystemDark()`**，别等用户的第一次切换——首屏就要符合当前主题

## 自测

1. **System Aware 和 Per-Monitor v2 的关键差别是什么？**
   —— System Aware 在进程启动时按**主显示器** DPI 缩放一次，窗口拖到不同 DPI 的屏幕上时系统拉伸位图、重新变模糊；Per-Monitor v2 跟随窗口**当前所在屏**，拖动时收到 `WM_DPICHANGED` 让你自己重排，全程清晰。

2. **`WM_DPICHANGED` 的 `wParam` 和 `lParam` 各是什么？为什么 `lParam` 必须照做？**
   —— `wParam` 高 16 位是 X DPI、低 16 位是 Y DPI；`lParam` 是系统建议的新窗口矩形 `RECT*`。不按它调整窗口尺寸，系统会把旧尺寸的窗口拉伸到新屏，位图模糊——等于白做了 DPI 感知。

3. **`DWMWA_USE_IMMERSIVE_DARK_MODE` 改的是什么？客户区怎么跟着变黑？**
   —— 只改非客户区（标题栏、边框）。客户区要自己来：自绘控件在 `OnEraseBkgnd` 里填深色背景、文字用浅色；系统控件靠父窗口的 `OnCtlColor` 换背景刷和文字色。

4. **怎么知道用户切了系统深浅色主题？**
   —— 顶层窗口会收到 `WM_SETTINGCHANGE`，`lParam` 是类别字符串，主题切换时为 `"ImmersiveColorSet"`（判空再比较）。收到后重读注册表 `HKCU\...\Themes\Personalize\AppsUseLightTheme`（0 = 深色），刷新标题栏和自绘部分。

5. **`SetProcessDpiAwarenessContext` 为什么必须在 `InitInstance` 最开头调用？调晚了会怎样？**
   —— 进程的 DPI 感知级别在第一个窗口创建时定型，之后调用返回 `FALSE` 且不改变任何行为。调晚了的症状是程序照常运行但高 DPI 下模糊，没有报错——所以必须检查返回值并尽早调用。

---
上一章：[13 系统集成：文件系统、最近文件与配置](13-shell-integration.md) ｜ 下一章：[15 Doc/View 架构](15-docview.md)
