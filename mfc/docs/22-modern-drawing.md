# 22 · 现代绘图：GDI+ 与 Direct2D

> 对应示例：`examples/22_modern_drawing`

> **本章你将学会**：GDI+ 怎么和 MFC 共存（`GdiplusStartup` 配对）、抗锯齿/渐变/半透明三件套、Direct2D 渲染进 HWND 的四步管线与设备丢失重建，以及 DirectWrite 文字。
> **前置知识**：第 18 章的 GDI 与双缓冲。

## 1. GDI 的天花板

GDI 是 1980 年代的 API，三条硬伤决定了"要好看就得升级"：

| 硬伤 | GDI 表现 |
|---|---|
| 无抗锯齿 | 斜线、圆、曲线全是锯齿 |
| 无 Alpha 混合 | 半透明只能靠 `AlphaBlend` 位图级补丁 |
| 无硬件加速 | 大量图元全靠 CPU 软件画 |

| 路线 | 定位 | 适合 |
|---|---|---|
| **GDI+** | 托管风格的 C++ 封装，软件渲染为主 | 抗锯齿/渐变够用、代码量小、依赖少 |
| **Direct2D** | GPU 加速、DWrite 排版 | 工业级 2D、大量图元、动画 |
| Direct3D | 3D | 超出本书范围 |

选型判据：**偶尔好看选 GDI+，量大且要快选 D2D**。纯线条、表格、打印布局留在 GDI（第 18 章）——升级是有成本的。

## 2. GDI+ 与 MFC 共存

GDI+ 是独立于 MFC 的库，用前要初始化——**生命周期绑在应用上**：

```cpp
class CDrawApp : public CWinApp {
    BOOL InitInstance() override {
        Gdiplus::GdiplusStartupInput gsi;
        Gdiplus::GdiplusStartup(&m_gdiplusToken, &gsi, NULL);   // ① 最早初始化
        ...
    }
    int ExitInstance() override {
        Gdiplus::GdiplusShutdown(m_gdiplusToken);               // ② 与 ① 配对
        return CWinApp::ExitInstance();
    }
    ULONG_PTR m_gdiplusToken = 0;
};
```

`GdiplusStartup` 必须在**任何 GDI+ 对象出生之前**调用——没调就直接 `new Graphics`，不报错，只是**什么都画不出来**（静默失败，非常迷惑）。`ExitInstance` 里配对关闭，位置在窗口销毁之后。

和 MFC 对象的接口只有一条缝——`CDC` 的裸句柄：

```cpp
void DrawWithGdiplus(CDC& dc, const CRect& rc) {
    Gdiplus::Graphics g(dc.GetSafeHdc());   // 从 HDC 构造
    g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);   // 抗锯齿开关
    ...
}
```

注意两套颜色类型**不同源**：GDI 用 `COLORREF`（`RGB(r,g,b)`，0x00BBGGRR），GDI+ 用自己的 `Color(a,r,g,b)`（ARGB，第 4 位是透明度）。互相传值要手工换算。

## 3. 抗锯齿、渐变与 Alpha

这三个能力正是 GDI 缺的，GDI+ 里都是一行开关/一个对象：

```cpp
// ① 线性渐变填充：起点色 → 终点色，按 90 度方向过渡
Gdiplus::LinearGradientBrush bg(
    Gdiplus::Rect(0, 0, rc.Width(), rc.Height()),
    Gdiplus::Color(255, 30, 60, 120),      // 深蓝（255 = 不透明）
    Gdiplus::Color(255, 120, 200, 255),    // 亮蓝
    90.0f);
g.FillRectangle(&bg, 0, 0, rc.Width(), rc.Height());

// ② 半透明高光：alpha 80/255 的白椭圆，GDI 完全画不出来
Gdiplus::SolidBrush glow(Gdiplus::Color(80, 255, 255, 255));
g.FillEllipse(&glow, x, y, w, h);

// ③ 抗锯齿文字
g.SetTextRenderingHint(Gdiplus::TextRenderingHintAntiAlias);
```

"圆角卡片 + 渐变背景 + 半透明高光"这三件积木就是现代 UI 视觉的最小组合——在 GDI 里模拟它们要写几十行逐像素代码，GDI+ 里每样一个调用。`PathGradientBrush` 还能做径向渐变（中心向外过渡），按钮高光常用。

代价要知道：GDI+ 主要是**软件渲染**（GDI+ 1.1 无 GPU 加速），图元量大时比 GDI 还慢。所以它是"小面积好看"的工具，不是"大场景快"的工具。

## 4. Direct2D 渲染进 HWND

D2D 的编程模型是**工厂 → 渲染目标 → 每帧 Begin/End**：

```cpp
// 一次性：工厂 + 绑定 HWND 的渲染目标（OnCreate / 懒创建）
D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_d2dFactory);
m_d2dFactory->CreateHwndRenderTarget(
    D2D1::RenderTargetProperties(),
    D2D1::HwndRenderTargetProperties(m_hWnd, size),   // HWND + 像素尺寸
    &m_rt);

// 每帧：
m_rt->BeginDraw();
m_rt->Clear(D2D1::ColorF(0x1A1A2E));
m_rt->FillEllipse(ellipse, brush);        // 几何图元
m_rt->DrawText(...);                      // 文字（下一节）
HRESULT hr = m_rt->EndDraw();             // 真正提交给 GPU

// 窗口尺寸变化（OnSize）：
m_rt->Resize(D2D1::SizeU(cx, cy));        // 渲染目标绑定像素尺寸，必须跟
```

三件必须处理的事：

- **`EndDraw` 返回 `D2DERR_RECREATE_TARGET`**：设备丢失（切显示器、休眠恢复、驱动重置）。处理方式是释放渲染目标，下一帧重新 `CreateHwndRenderTarget`——不处理的表现是"休眠唤醒后画面永远黑掉"。示例把它抽成 `ReleaseD2D()` + 懒创建的 `EnsureRenderTarget()`。
- **`OnSize` 里 `Resize`**：渲染目标记着创建时的像素尺寸，窗口变了不 `Resize`，画面拉伸或裁剪。
- **资源释放顺序与创建顺序相反**：brush/textFormat/rendertarget → factory。COM 引用计数靠 `Release()`，别漏也别重复。

D2D 的 brush 是**渲染目标的附属资源**——`CreateSolidColorBrush` 是 `m_rt` 的方法，渲染目标重建后 brush 也要重建（这也是 `EndDraw` 失败后全部重建的原因）。

## 5. DirectWrite 文字

D2D 自己不排版，文字走 **DirectWrite**：

```cpp
// 工厂 + 文字格式（一次性）
DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                    reinterpret_cast<IUnknown**>(&m_dwFactory));
m_dwFactory->CreateTextFormat(
    L"微软雅黑", nullptr,
    DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
    DWRITE_FONT_STRETCH_NORMAL,
    24.0f,          // DIP 字号（设备无关像素，96 DIP = 1 英寸）
    L"zh-CN",       // 语言
    &m_textFormat);

// 每帧：m_rt->DrawText(文本, 长度, 格式, 布局矩形, 画笔)
```

DWrite 的渲染质量全面好于 GDI `DrawText`：亚像素抗锯齿、ClearType 调优、按 DIP 缩放（换显示器不糊——第 14 章 DPI 问题的文字侧正解）。精细排版（逐字符定位、混排、自动换行测量）走 `IDWriteTextLayout`，超出本书范围——知道入口在哪即可。

## 常见坑

1. **`GdiplusStartup` 没调就创建 `Graphics`**
   不报错、不崩，就是**什么都不画**——GDI+ 静默失败的代表。Startup 放 `InitInstance` 最前面。

2. **忘 `GdiplusShutdown`**
   退出时 GDI+ 内部资源不释放。和 Startup 在 `InitInstance`/`ExitInstance` 严格配对。

3. **`EndDraw` 返回 `D2DERR_RECREATE_TARGET` 不处理**
   切显示器/休眠恢复后画面黑掉，直到重启程序。收到就释放渲染目标，下帧懒重建。

4. **渲染目标没随 `OnSize` 重建/Resize**
   窗口一拉大画面拉伸变形或被裁掉。`OnSize` 里 `m_rt->Resize(newSize)`。

5. **混用 GDI 与 D2D 画同一个区域**
   两者提交机制不同（GDI 即时、D2D 每帧整体提交），互相覆盖、闪烁顺序错乱。一个窗口的绘制**选定一条路线**，别缝缝补补两套都上。

6. **库没链接（`gdiplus.lib`/`d2d1.lib`/`dwrite.lib`）**
   MFC 的 `afx.h` 不自动链它们，链接时报未解析外部符号。示例走 build.ps1 的 `extraLibsByExample` 白名单；VC 工程在"附加依赖项"里加。

7. **GDI+ 颜色当 COLORREF 用**
   `RGB()` 的内存序和 `Gdiplus::Color(a,r,g,b)` 不同源，直接传数值会换色。写代码时用各自的构造函数，不做数值混算。

## 实战建议

- 纯线条/表格/打印用 GDI（快、零依赖）；要抗锯齿/半透明才上 GDI+；图元量大、要硬件加速才上 D2D——按需升级，不要为三个椭圆引入 D2D
- D2D 的设备丢失重建抽成 `EnsureRenderTarget()`（懒创建）+ `ReleaseD2D()`，`EndDraw` 失败和 `OnCreate` 走同一个入口
- GDI+ 的 `Graphics` 对象**不要跨帧持有**——它包着 HDC，一次 `OnPaint` 一次构造析构最安全
- 双缓冲纪律（第 18 章）对两条路线都适用：`OnEraseBkgnd` 返回 TRUE、`Invalidate(FALSE)`；D2D 的 Clear 本身就是整帧重画，天然无闪
- 字号一律用 DIP（DWrite）或磅（GDI+ `Font`），不要写像素——和第 14 章的 DPI 思想一致

## 自测

1. **`GdiplusStartup` 忘调会怎样？为什么这个错特别难发现？**
   —— 不报错不崩溃，GDI+ 调用静默失败，画面就是空的。没有异常、没有断言、没有日志，只有"什么都不画"这一个症状，和逻辑 bug 极难区分。

2. **GDI+ 和 D2D 各自的核心适用场景？判据是什么？**
   —— GDI+：小面积好看（抗锯齿/渐变/半透明），软件渲染，图元少；D2D：GPU 加速，图元量大、要动画/高帧率。判据是图元数量和性能要求，不是"哪个新用哪个"。

3. **D2D 的四步管线是什么？`EndDraw` 返回 `D2DERR_RECREATE_TARGET` 时该怎么办？**
   —— `D2D1CreateFactory` → `CreateHwndRenderTarget`（绑 HWND + 尺寸）→ 每帧 `BeginDraw`/画/`EndDraw` → `OnSize` 里 `Resize`。收到 RECREATE_TARGET 就释放渲染目标（brush 等附属资源一并），下一帧重新创建。

4. **D2D 为什么要配 `OnSize` 里的 `Resize`？**
   —— `HwndRenderTarget` 创建时绑定了像素尺寸，窗口变化后尺寸不匹配，画面被拉伸或裁剪。`Resize` 按新客户区更新渲染目标。

5. **DWrite 的字号和 GDI 字体有什么本质区别？**
   —— DWrite 用 DIP（设备无关像素，96 DIP = 1 英寸），渲染时按目标 DPI 自动缩放，跨 DPI 屏幕不糊；GDI 字体按目标 DC 的像素定，跨设备要自己换算（`CreatePointFont` 的磅只是缓解）。

---
上一章：[21 异常处理、调试与内存诊断](21-debugging.md) ｜ 下一章：[23 部署与发布](23-deployment.md)
