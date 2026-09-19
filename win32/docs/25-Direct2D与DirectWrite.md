# 第 25 章 Direct2D 与 DirectWrite

> **本章回答的问题**：GDI 不够在哪、D2D 好在哪？为什么说 D2D 是"COM 接口风格的天下"？工厂/渲染目标/资源三层怎么分工？文字为什么要单独一个 DirectWrite？设备丢了怎么办？
>
> **前置章节**：第 9 章（GDI——对照起点）、第 22 章（COM——D2D 的每个对象都是 COM 接口）。
>
> **你将做出什么**：一个现代渲染窗口（`examples/28_direct2d_hello`）：渐变圆角矩形 + 抗锯齿圆 + DWrite 文本，窗口缩放即时跟随。

本章示例：`examples/28_direct2d_hello/main.cpp`。

## 25.1 为什么有 D2D：GDI 的三笔账

第 9 章末尾说"GDI 至今被维护"，但三笔账它还得认：

| 痛点 | GDI | Direct2D |
|------|-----|----------|
| 抗锯齿 | `Ellipse` 边缘全是锯齿 | 默认每条边抗锯齿（每图元 AA） |
| 硬件加速 | CPU 画进内存位图（DWM 合成才上 GPU） | 直接渲染到 GPU 表面 |
| 单位 | 物理像素，DPI 一变全歪 | **DIP（设备无关像素，1/96 英寸）**，DPI 由运行时换算 |

（透明/alpha 混合是第四笔：GDI 基本没有，D2D 天生全程 alpha。）由此决定选型：改个按钮颜色、画个简单图表——GDI 够；要动画、富文本、专业 UI——D2D。本教程两者都教：GDI 教的是"失效-重绘"的模型，那个模型到 D2D 一样成立。

## 25.2 一眼认出：D2D 全家都是 COM

打开 28 示例，扑面而来的熟面孔——第 22~24 章的 COM 知识直接变现：

```cpp
ID2D1Factory*          g_factory;   // 接口指针（IUnknown 血统）
D2D1CreateFactory(..., &g_factory); // 人家不叫 CoCreateInstance，但干的是激活
g_factory->Release();               // 引用计数纪律原样适用
```

每个 `ID2D1Xxx`/`IDWriteXxx` 都是 COM 接口：`Release` 归还、`QueryInterface` 可用、ComPtr 可包（示例用原生 `SafeRelease` 模板，让纪律显形；工程代码建议 ComPtr）。**学完 COM 再学 D2D，学习曲线从"陡"变"缓"**——这正是本教程把 D2D 放在 COM 之后的理由。

## 25.3 三层对象模型：工厂 → 渲染目标 → 资源

D2D 的对象分三层，**谁创建、跟谁走**是所有生命周期问题的答案：

```text
ID2D1Factory（工厂，进程里一个就够）
   │  创建
   ▼
ID2D1HwndRenderTarget（渲染目标 = "绑在某 HWND 上的画布"）
   │  创建
   ▼
设备相关资源：ID2D1SolidColorBrush / LinearGradientBrush / Bitmap...
   （绑定在这个 target 上，target 丢了它们全失效）
```

| 资源 | 创建者 | 设备无关？ | 生命期 |
|------|--------|-----------|--------|
| `ID2D1Factory` | `D2D1CreateFactory` | 是 | 全程序 |
| `ID2D1HwndRenderTarget` | factory | 否（持 GPU 资源） | 到设备丢失/窗口销毁 |
| 画刷/位图（factory 建） | factory | 是（几何/笔触） | 全程序 |
| 画刷/位图（target 建） | target | **否** | **≤ target 的生命期** |

28 示例的纪律：`SafeRelease` 顺序严格"画刷 → target →（退出时）format → dwrite 工厂 → d2d 工厂"——倒过来释放就是访问已亡对象。

## 25.4 HwndRenderTarget：与窗口模型接轨

创建一个"画在本窗口上"的渲染目标：

```cpp
RECT rc; GetClientRect(hwnd, &rc);
g_factory->CreateHwndRenderTarget(
    D2D1::RenderTargetProperties(),                 // 像素格式/DPi 默认
    D2D1::HwndRenderTargetProperties(hwnd, D2D1::SizeU(rc.right, rc.bottom)),
    &g_target);
```

与 GDI `WM_PAINT` 体系的对照表（心智迁移地图）：

| GDI（第 9 章） | D2D |
|----------------|-----|
| `BeginPaint`/`EndPaint` | `BeginDraw()`/`EndDraw()` |
| `HDC` | `ID2D1RenderTarget*` |
| 失效区自动剪裁 | 自己全画（简单）或用 `PushAxisAlignedClip`（少用） |
| `WM_ERASEBKGND` 默认擦白 | 自己 `Clear()` 铺底；`WM_ERASEBKGND` 返回 1 防闪 |
| 选入画笔/画刷再画 | 每次调用**直接传画刷参数**（无"当前对象"状态） |

注意"直接传画刷"这一条：D2D 没有第 9 章的"选中→换回"四步舞——状态机变成了参数传递，少了整类配平错误。`WM_PAINT` 里 `ValidateRect(hwnd, nullptr)` 后自绘（D2D 自己管脏区，这行是安抚 GDI 体系）；`WM_SIZE` 里 `g_target->Resize(...)` 让画布跟窗口。

## 25.5 绘制原语与画刷

```cpp
g_target->Clear(D2D1::ColorF(0.09f, 0.10f, 0.14f));            // 铺底色
g_target->FillRoundedRectangle(D2D1::RoundedRect(rc, 18, 18), g_grad);   // 圆角矩形
g_target->DrawEllipse(D2D1::Ellipse(center, 70, 70), g_solid, 2.0f);     // 抗锯齿圆
```

画刷三种：**纯色**（`CreateSolidColorBrush`，参数是 RGBA）、**线性渐变**（先造 stops 数组再 Create——28 示例从 CornflowerBlue 渐变到 MediumVioletRed）、**位图画刷**（贴图，一句话）。渐变的 stops 概念图：

```text
0.0 ──────────────────────── 1.0
CornflowerBlue ──插值──▶ MediumVioletRed
（stops 数组给多个位置点，中间自动过渡）
```

## 25.6 DirectWrite：文字是独立学科

D2D 自己不管文字排版——**DirectWrite**（`dwrite.dll`）专职：字体枚举/回退、复杂文种（阿拉伯/印度系）、排版。D2D 与它以 `DrawTextW` 衔接：

```cpp
// ① 文本格式（字体/字号/语言）——设备无关资源，可全程序复用
g_dw->CreateTextFormat(L"微软雅黑", nullptr,
                       DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
                       DWRITE_FONT_STRETCH_NORMAL, 26.0f, L"zh-CN", &g_format);
// ② 画（矩形内排版，选项与 GDI DrawText 的 DT_* 精神相通）
g_target->DrawTextW(kText, len, g_format, &layoutRect, g_solid);
```

两个与 GDI 的差异要知道：**单位是 DIP**（`26.0f` 是 26/96 英寸的字号，不是像素——DPI 换算系统代办）；排版能力上限是 `IDWriteTextLayout`（逐段样式、内嵌对象、测量命中——做富文本 UI 的基座）。选字体放心用中文名（"微软雅黑"），DWrite 有完整的字体回退链，不会像 GDI 时代那样挑不到字就豆腐块。

## 25.7 窗口变化与设备丢失

**缩放**：`WM_SIZE` 里 `Resize`，随后 `InvalidateRect` 重画（28 示例）。

**设备丢失（device lost）**是 D2D 的特色场景：锁屏、驱动重置、睡眠恢复都可能让 GPU 资源蒸发。协议是 `EndDraw()` 返回 `D2DERR_RECREATE_TARGET`——**丢弃全部设备相关资源，下次 WM_PAINT 重建**：

```cpp
if (g_target->EndDraw() == (HRESULT)D2DERR_RECREATE_TARGET) {
    DiscardDeviceResources();     // 画刷 + target 全放，下次重造
}
```

这正是 25.3 表里"设备相关资源 ≤ target 生命期"的原因：它们随时可能集体蒸发，代码结构必须支持"从工厂无中生有"。设备无关资源（format、factory）不受影响。

## 25.8 与 GDI 互操作 & 何时仍用 GDI

`ID2D1DCRenderTarget` 能把 D2D 输出画进 GDI 的 HDC（老界面里嵌现代图块的桥）；反过来 `CreateDCRenderTarget`/`ID2D1GdiInteropRenderTarget` 支持双向。何时仍用 GDI：给现有控件画个图标、打印路径（GDI 打印体系成熟）——**工具按活挑，不是信仰站队**。第 8 章说过"完全自定义外观"的终点是自绘窗口；现在补全：自绘窗口的画笔就是本章。

## 25.9 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| `EndDraw` 忘调 | 后续 BeginDraw 报错 | 成对（25.4） |
| 锁屏回来白屏 | 没处理 `D2DERR_RECREATE_TARGET` | 丢弃重建（25.7） |
| 访问已释放画刷崩溃 | target 丢了但画刷还被缓存使用 | 设备相关资源与 target 同生共死（25.3） |
| 文字大小随 DPI 变 | 以为 `26.0f` 是像素 | DIP 单位（25.6） |
| 渐变看不出效果 | stops 数组位置没排开/颜色太近 | 25.5 图 |
| 每帧创建画刷 | 画刷是资源不是参数，反复建浪费 | 缓存（28 示例的做法） |
| 窗口闪一下才正常 | `WM_ERASEBKGND` 让 GDI 擦了背景 | 返回 1（25.4） |
| `DrawTextW` 链接错误 | 只链 d2d1 忘 dwrite | 两库都要（本仓库 build.ps1 已带） |

## 25.10 小结

1. D2D 三笔账：抗锯齿、硬件加速、DIP——GDI 的模型（失效-重绘）不变，画笔换代。
2. 全家 COM：接口指针 + Release + ComPtr 可用——22 章知识变现。
3. 三层模型：工厂（全程序）→ target（到设备丢失）→ 设备相关资源（≤ target）；释放顺序严格倒序。
4. 绘制无"当前对象"状态机，画刷作参数直传；渐变先 stops 后 brush。
5. 文字归 DirectWrite：format 设备无关可复用，单位 DIP；设备丢失走"丢弃重建"协议。

## 25.11 动手练习

1. 给 28 示例加动画：`WM_TIMER`（第 4 章）每 30ms 让圆心的 x 前进一点，越界折返——D2D 全量重绘小场景毫无压力。
2. 换成径向渐变（`CreateRadialGradientBrush`）做圆的填充，圆心高亮边缘变暗。
3. 用 `IDWriteTextLayout` 给标题里的 "Direct2D" 单词单独加大加粗（`SetTextFormat` 指定区间）——富文本排版的第一次接触。

---

**下一章**：[第 26 章 WinRT 与 C++/WinRT](26-WinRT与CppWinRT.md)——COM 家族的现代收束。
