# 18 · GDI 绘图与双缓冲

> 对应示例：`examples/18_gdi`

> **本章你将学会**：DC 与 GDI 对象的所有权规则（含 `FromHandle` 的陷阱）、双缓冲的三种写法各适合哪里、`OnEraseBkgnd` 与 `Invalidate(FALSE)` 的配合，以及什么时候该放弃 GDI 换 GDI+/Direct2D。
> **前置知识**：第 09 章的自绘子窗口。

## 1. 绘图模型：DC 是什么

GDI（Graphics Device Interface）通过**设备上下文**（DC，Device Context）绘图。DC 是一块"画布 + 画具"的抽象：你把画笔/画刷/字体**选入** DC，然后调用画图函数，画到 DC 对应的表面（屏幕窗口、内存位图、打印机）。

MFC 封装了三类 DC：

| 类 | 时机 | 用途 |
|---|---|---|
| `CPaintDC` | `OnPaint` 里构造 | 响应 WM_PAINT 的标准绘制 |
| `CClientDC` | 任意时刻 | 在客户区即时绘制（如拖拽预览） |
| `CWindowDC` | 任意时刻 | 含非客户区（标题栏都算） |
| `CDC::CreateCompatibleDC` | 任意时刻 | 内存 DC（双缓冲的主角） |

WM_PAINT 的特殊性：它是**低优先级队列消息**——只在队列空闲时投递，且系统自己合并连续多次 `Invalidate`。所以重绘节奏是系统控制的，你只负责"把整个客户区画对"。

## 2. GDI 对象：选入与归还

画笔（线）、画刷（填充）、字体、位图都是 GDI 对象，绘图前选入 DC：

```cpp
CPen pen(PS_SOLID, 3, RGB(255, 100, 0));      // 线型、粗细、颜色
CPen* oldPen = dc.SelectObject(&pen);
dc.Rectangle(300, 80, 520, 220);
dc.SelectObject(oldPen);                       // 用完选回旧对象
```

MFC 的 CPen/CBrush/CFont 是 RAII 的（析构自动 DeleteObject），需要记住的只有两条：**SelectObject 必须归还**（否则对象卡在 DC 里删不掉），**GDI 对象数量有上限**（默认每个进程 10000 个，泄漏真会炸）。

常用绘制 API：

| 函数 | 作用 |
|---|---|
| `FillSolidRect` | 纯色填充（最常用的背景手段） |
| `Rectangle / Ellipse` | 矩形 / 圆（用当前画笔画边、画刷填充） |
| `MoveTo / LineTo` | 画线 |
| `Polyline / Polygon` | 折线 / 多边形 |
| `TextOut / DrawText` | 文本（DrawText 支持排版、对齐、省略号） |
| `BitBlt / StretchBlt` | 位块搬运（双缓冲的拷贝、图片缩放） |
| `SetBkMode(TRANSPARENT)` | 文字背景透明 |
| `GetTextExtent` | 量文本宽度（对齐、截断用） |

## 3. DC 与 GDI 对象的所有权

GDI 对象的生死有两个角色参与：**创建者**（你，或 MFC RAII 类的析构）和**当前选入的 DC**。规则就一句话：*对象销毁时不能还选在 DC 里*。所以标准节奏是"选入 → 画 → 选回旧对象"——选回之后，RAII 析构才能安全 `DeleteObject`。

```cpp
// 典型错误：局部字体没归还就析构 —— DeleteObject 失败，句柄泄漏
void BadPaint(CDC& dc) {
    CFont font;
    font.CreatePointFont(120, _T("微软雅黑"));
    dc.SelectObject(&font);
    dc.DrawText(...);
}   // font 析构时还选在 dc 里 → 泄漏
```

另一类所有权问题出在 **`FromHandle` 家族**：`CDC::FromHandle(hdc)`、`CPen::FromHandle(hPen)` 把裸句柄包成 MFC 对象指针，但它返回的是**临时对象**——挂在线程的临时表里，**下一次空闲处理（或消息循环间隙）就被回收**，句柄本身并不归它管：

| 获取方式 | 所有权 | 能存成成员吗 |
|---|---|---|
| `CPaintDC dc(this)`（构造函数拿句柄） | 对象拥有句柄，析构释放 | 局部变量用完即弃 |
| `GetDC()` / `ReleaseDC()` | 调用者负责 Release | 配对释放 |
| `CDC::FromHandle(hdc)` | **无**——包装别人句柄的临时对象 | **不能**，只能当次消息里用 |

典型事故：消息处理里 `CDC* pDC = CDC::FromHandle(wParam)`，存进成员，下一条消息再解引用——临时对象已被回收，行为未定义。`FromHandle` 的正确用途只有一个：**框架回调塞给你裸句柄（如 `OnCtlColor`、打印钩子），当次消息里包一下就用**。

## 4. 双缓冲：消除闪烁的标准解法（写法①）

直接往屏幕画复杂场景时，"先擦背景再逐个画"的过程被人眼看到 → 闪烁。双缓冲的思路：**先在内存位图上把整幅画画完，再一次性拷到屏幕**：

```cpp
afx_msg void OnPaint() {
    CPaintDC screenDc(this);
    CRect rect;
    GetClientRect(&rect);

    // ① 内存 DC + 兼容位图
    CDC memDc;
    memDc.CreateCompatibleDC(&screenDc);
    CBitmap buffer;
    buffer.CreateCompatibleBitmap(&screenDc, rect.Width(), rect.Height());
    CBitmap* oldBmp = memDc.SelectObject(&buffer);

    DrawScene(&memDc, rect);                    // ② 场景画进内存

    screenDc.BitBlt(0, 0, rect.Width(), rect.Height(),
                    &memDc, 0, 0, SRCCOPY);     // ③ 一次性上屏
    memDc.SelectObject(oldBmp);
}

afx_msg BOOL OnEraseBkgnd(CDC*) {
    return TRUE;    // 背景擦除也并入 DrawScene，别让框架再刷一次白底
}
```

两个配套细节缺一不可：

1. **`OnEraseBkgnd` 返回 TRUE**——不拦住它，系统会在你绘制前先刷一遍背景色，闪的还是那一下
2. **`Invalidate(FALSE)`**——请求重绘时声明"不用擦背景"

**内存位图尺寸必须与客户区一致，窗口变了要重建**。`OnSize` 里记下新尺寸并置"缓冲失效"，下次 `OnPaint` 重建位图；用旧尺寸位图 BitBlt 到新尺寸客户区，就是拉伸变形。示例 18 的做法是每次 `OnPaint` 都按当前客户区重建——小窗口没问题；大窗口高频重绘时改成缓存位图 + 失效重建（见实战建议）。

## 5. 双缓冲的三种写法

**写法①：`CreateCompatibleDC` + `CreateCompatibleBitmap`**（上一节）——最通用，不依赖任何附加头文件，自己掌控每一步；缺点是样板代码 6 行，容易漏掉"选回旧位图"。

**写法②：Feature Pack 的 `CMemDC`**——MFC 现成的 RAII 封装（`afxcontrolbarutil.h`，被 `afxcontrolbars.h` 带入）：

```cpp
afx_msg void OnPaint() {
    CPaintDC dc(this);
    CMemDC mem(dc, this);       // 构造时建内存 DC，析构时自动拷回屏幕
    DrawScene(&mem.GetDC(), ...);   // 全部画到 mem.GetDC()
}                               // 离开作用域：BitBlt 上屏 + 释放
```

它还会读 `CMemDC::m_bUseMemoryDC` 全局开关（某些远程桌面/性能场景 MFC 自动关掉缓冲）。适合"代码里双缓冲很多处"的工程；缺点是行为黑盒，客户区边界情况（空 rect 等）靠它内部兜底。

**写法③：UxTheme 的缓冲绘制 API**（`BeginBufferedPaint`/`EndBufferedPaint`，uxtheme.lib）——Vista 起系统提供的缓冲，能和 DWM 组合、处理半透明边框；写法②内部在 Vista+ 上走的其实就是它（`IsVistaDC()` 可探测）。除非要做带主题的非客户区效果，一般用不到直接调。

选择建议：**教程/单控件用①，大型工程用②，主题特效用③**。三者解决的是同一个问题，不要在同一个 `OnPaint` 里混用。

## 6. 鼠标交互画线：状态机 + SetCapture

画板类交互是三消息状态机：

```cpp
OnLButtonDown → 记起点，SetCapture()，进入 drawing 状态
OnMouseMove   → drawing 时记路径点，Invalidate(FALSE) 重绘
OnLButtonUp   → 记终点，ReleaseCapture()，退出状态
```

`SetCapture` 让鼠标拖出窗口也继续收 `MouseMove`（否则拖出就断线）。**必须配对 ReleaseCapture**。

笔画数据的组织：每笔画一个 `std::vector<CPoint>` + 颜色，整体 `std::vector<Stroke>` 就是文档数据——这个结构和第 15 章 Doc/View 天然契合（数据搬进 CDocument，OnDraw 画它）。

## 7. 文本绘制要点

```cpp
CFont font;
font.CreatePointFont(120, _T("微软雅黑"));   // 参数是 1/10 磅：120 = 12pt
CFont* old = dc.SelectObject(&font);

dc.SetBkMode(TRANSPARENT);                    // 文字背景透明
dc.SetTextColor(RGB(40, 40, 40));
dc.DrawText(_T("标题"), -1, rect, DT_LEFT | DT_WORDBREAK | DT_END_ELLIPSIS);

dc.SelectObject(old);
```

`CreatePointFont` 的好处是**按磅指定字号，自动算像素**，DPI 变了字号跟着对。`DrawText` 支持 `DT_WORDBREAK`（自动换行）、`DT_END_ELLIPSIS`（截断加省略号）、`DT_CALCRECT`（只测量不画——布局计算神器）。

## 8. 什么时候不该用 GDI

GDI 是 80 年代 API，三条硬伤：

| 硬伤 | 后果 |
|---|---|
| 无抗锯齿 | 斜线、圆弧全是锯齿 |
| 无 Alpha 混合 | 半透明只能靠 `AlphaBlend` 位图级（且无逐像素着色器） |
| 无渐变笔刷/几何变换矩阵 | 复杂效果全靠手工模拟 |

需要这些效果时的升级路径：**GDI+**（`Graphics` + `Pen`/`SolidBrush`，抗锯齿和半透明开箱即用，启动快依赖少——第 22 章）或 **Direct2D**（硬件加速，大量图元 + 动画才需要——第 22 章）。

GDI 依然值得用的场景：**打印**（打印机 DC 上 GDI 是标准通道，第 19 章）、简单图表/波形、启动速度敏感的小工具、不引额外依赖的场合。一句话：**界面简单选 GDI，要好看选 GDI+，要快且好看选 Direct2D**。

## 常见坑

1. **`SelectObject` 后不归还旧对象**
   新对象一直选在 DC 里，销毁时 `DeleteObject` 失败——GDI 句柄泄漏，进程句柄数上涨，涨到上限后所有绘图静默失效。RAII 类救不了"没归还"这个错。

2. **内存位图没随窗口尺寸重建**
   客户区变大后还用旧尺寸缓冲位图，`BitBlt` 出来拉伸变形。`OnSize` 置失效标记，`OnPaint` 里按新尺寸重建。

3. **`CreateCompatibleBitmap` 传错 DC**
   传了内存 DC 会得到 1×1 单色位图——典型"双缓冲后全黑"的原因。参数要传**屏幕（目标）DC**。

4. **在 `OnPaint` 里用 `GetDC`/`new CDC` 而不是 `CPaintDC`**
   `CPaintDC` 构造调 `BeginPaint`、析构调 `EndPaint`，这套配对还负责把 WM_PAINT 从队列里清掉；用 `GetDC` 画 WM_PAINT，队列永远不清空，窗口无限重绘。

5. **`OnEraseBkgnd` 与双缓冲没配合**
   双缓冲画完一次上屏是"不闪"的前提，但 `OnEraseBkgnd` 不返回 TRUE 的话，系统先刷一遍白底——刚好闪那一下。反过来，非双缓冲的简单绘制也别乱返回 TRUE，否则背景没人擦。

6. **把 `FromHandle` 返回的指针存成成员**
   那是线程临时表里的临时对象，消息间隙就被回收。只在当次消息处理里用。

## 实战建议

- 所有自绘控件都走"双缓冲 + 缓存字体成员"的模板，一次写对处处受益
- 字体、画笔这类创建成本高的 GDI 对象**缓存成成员**（`OnCreate` 里建），别在 `OnPaint` 循环里反复 `CreateFont`——高频重绘时这是最大的隐藏开销
- 大窗口高频重绘：静态部分渲染成缓存位图（尺寸变化才重建），动态部分每帧叠加，`Invalidate(rect)` 只标脏区
- 需要 PNG/抗锯齿/半透明时升级 GDI+：`GdiplusStartup` 初始化后 `Graphics g(dc.GetSafeHdc())`，API 思路同 GDI（第 22 章）
- 打印和屏幕共用一套绘制代码（第 19 章），设计绘制函数时就把它写成"给我一个 DC 和一块矩形我就画"

## 自测

1. **GDI 对象"选入 DC 后必须归还"的根源是什么？不归还的后果？**
   —— 对象销毁时不能还选在 DC 里，否则 `DeleteObject` 失败。后果是 GDI 句柄泄漏（进程上限默认 10000），涨满后所有绘图静默失效。

2. **`CDC::FromHandle` 返回的对象和 `CPaintDC` 有什么本质区别？**
   —— `FromHandle` 只是把裸句柄包装成临时 MFC 对象，不拥有句柄、随线程临时表回收，只能当次消息里用；`CPaintDC` 拥有句柄并负责 `BeginPaint/EndPaint` 配对。`FromHandle` 的指针不能存成员。

3. **双缓冲为什么不闪？`OnEraseBkgnd` 和 `Invalidate(FALSE)` 各起什么作用？**
   —— 整幅画先在内存位图上完成，再一次性 `BitBlt` 上屏，人眼看不到中间过程。`OnEraseBkgnd` 返回 TRUE 拦掉系统擦背景；`Invalidate(FALSE)` 声明重绘不用擦背景——两者都是防止"上屏前多刷一遍白底"。

4. **窗口尺寸变化后双缓冲要做什么？不做会怎样？**
   —— 内存位图按新客户区尺寸重建（`OnSize` 置失效、`OnPaint` 重建）。不做的话旧尺寸位图被 `BitBlt` 到新尺寸客户区，画面拉伸变形。

5. **什么样的需求该放弃 GDI？两条升级路径怎么选？**
   —— 需要抗锯齿、Alpha 混合、渐变/变换矩阵时。偶尔好看用 GDI+（快上手、依赖少）；图元量大、要硬件加速和动画用 Direct2D。打印和简单图表留在 GDI 即可。

---
上一章：[17 序列化深入与文档版本化](17-serialize.md) ｜ 下一章：[19 打印与打印预览](19-printing.md)
