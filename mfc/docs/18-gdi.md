# 18 · GDI 绘图与双缓冲

> 对应示例：`examples/18_gdi`

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

## 3. 双缓冲：消除闪烁的标准解法

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

## 4. 鼠标交互画线：状态机 + SetCapture

画板类交互是三消息状态机：

```cpp
OnLButtonDown → 记起点，SetCapture()，进入 drawing 状态
OnMouseMove   → drawing 时记路径点，Invalidate(FALSE) 重绘
OnLButtonUp   → 记终点，ReleaseCapture()，退出状态
```

`SetCapture` 让鼠标拖出窗口也继续收 `MouseMove`（否则拖出就断线）。**必须配对 ReleaseCapture**。

笔画数据的组织：每笔画一个 `std::vector<CPoint>` + 颜色，整体 `std::vector<Stroke>` 就是文档数据——这个结构和第 15 章 Doc/View 天然契合（数据搬进 CDocument，OnDraw 画它）。

## 5. 文本绘制要点

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

## 6. 常见坑

**GDI 句柄泄漏**：SelectObject 后不归还 + 对象没析构，累积到上限后所有绘图静默失效。MFC RAII 类基本免疫，但"新建对象放进循环里"要注意规模（每次重绘都 new 一个 CFont 是常见浪费——缓存成成员）。

**双缓冲后仍闪**：九成是忘了 `OnEraseBkgnd` 返回 TRUE，或 `Invalidate` 用了默认的 TRUE。

**CreateCompatibleBitmap 的坑**：参数要传**屏幕 DC**（或目标 DC），传内存 DC 会得到 1x1 单色位图——典型黑屏原因。

**高频重绘卡顿**：绘制内容复杂时把静态部分渲染成缓存位图（画一次，之后 BitBlt 贴），动态部分再叠加。

## 7. 实战建议

- 所有自绘控件都走"双缓冲 + 缓存字体成员"的模板，一次写对处处受益
- 需要 PNG/抗锯齿/半透明时，GDI 撑不住，引入 GDI+：`GdiplusStartup` 初始化后用 `Graphics g(dc.GetSafeHdc())` 画，API 思路相同（Pen/Brush 变成 GDI+ 对象）
- 图表、波形这类高频刷新场景，考虑每帧只重绘变化区域（`Invalidate(rect)` 指定脏矩形）

---
上一章：[15 Doc/View 架构](15-docview.md) ｜ 下一章：[20 多线程与后台任务](20-threads.md)
