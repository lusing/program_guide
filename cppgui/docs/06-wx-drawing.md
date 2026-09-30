# 06 · DC 绘图：双缓冲与抗锯齿

> 对应示例：[examples/06_wx_drawing.cpp](../examples/06_wx_drawing.cpp)

控件不够用时就要自己画。保留模式的绘图 = 响应重绘事件（`wxEVT_PAINT`）+ 在设备上下文（DC）上**重放状态**：示例是一个鼠标画板，笔迹存进 `vector`，OnPaint 每次从头画完——窗口被遮挡再露出、resize、被别的窗口拖过，系统发 paint 事件，你的数据是唯一真源。本章覆盖 paint DC 铁律、双缓冲、GDI 原语、`wxGraphicsContext` 抗锯齿，以及"收集 → 重放"的完整管线。

## 6.1 绘图模型：状态与重放

```cpp
// ═══ 6.1 画板：笔迹是状态，OnPaint 是重放 ═══
class DrawPanel : public wxPanel
{
public:
    DrawPanel(wxWindow* parent);
    void AddStroke(const std::vector<wxPoint>& pts) { m_strokes.push_back(pts); }
    ...
private:
    void OnPaint(wxPaintEvent&);
    void OnLeftDown(wxMouseEvent&);
    void OnMotion(wxMouseEvent&);
    void OnLeftUp(wxMouseEvent&);

    std::vector<std::vector<wxPoint>> m_strokes;
    bool m_drawing = false;
    int m_paintCount = 0;
};
```

与"画一步留一步"（只在鼠标移动时补画增量）相反，这里鼠标事件**只收集数据**，一切像素都由 OnPaint 从 `m_strokes` 完整重画。`m_strokes` 的每个元素是一笔（stroke）——一串 `wxPoint`。好处是无条件可重现：遮挡、缩放、多次重绘都不花屏；代价是每次全量重画——对画板这种规模毫无压力。`AddStroke` 暴露给外部（selftest 用它程序化注入笔迹），`m_paintCount` 统计 OnPaint 执行次数（selftest 的断言依据）。

## 6.2 wxPaintDC 铁律与双缓冲

```cpp
// ═══ 6.2 OnPaint：paint DC 必须无条件创建 ═══
DrawPanel::DrawPanel(wxWindow* parent)
    : wxPanel(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
              wxBORDER_SUNKEN)
{
    SetBackgroundStyle(wxBG_STYLE_PAINT);    // 双缓冲要求：自管背景擦除
    Bind(wxEVT_PAINT, &DrawPanel::OnPaint, this);
    ...
}

void DrawPanel::OnPaint(wxPaintEvent&)
{
    ++m_paintCount;
    // 【坑】wxPaintDC 必须无条件创建（即使什么都不画）
    wxAutoBufferedPaintDC dc(this);          // 双缓冲版 paint DC
    wxSize sz = GetClientSize();
    dc.SetBackground(*wxWHITE_BRUSH);
    dc.Clear();
    ...
}
```

两个关键点：

- **paint DC 必须无条件创建**。Windows 的 WM_PAINT 必须被 BeginPaint/EndPaint 确认，wx 把这个确认动作藏在 wxPaintDC 的构造/析构里——OnPaint 里不创建 paint DC，系统认为"还没画完"，paint 事件反复投递，形成事件风暴。哪怕这个分支什么都不画，DC 也要先造出来。
- **双缓冲的前提是 `SetBackgroundStyle(wxBG_STYLE_PAINT)`**（构造函数里）。它声明"背景擦除我自己管"，阻止系统在 paint 前先擦一遍；`wxAutoBufferedPaintDC` 则把绘制先落到离屏位图、再一次性贴屏——"先擦白再逐笔画"的闪烁就此消失。

## 6.3 绘图原语：pen 与 brush 的状态机

```cpp
// ═══ 6.3 GDI 原语：矩形/椭圆/多边形/文字 ═══
dc.SetPen(wxPen(*wxRED_PEN));
dc.SetBrush(wxBrush(*wxCYAN_BRUSH));
dc.DrawRectangle(10, 10, 80, 50);
dc.SetBrush(*wxTRANSPARENT_BRUSH);
dc.DrawEllipse(110, 10, 80, 50);
dc.SetPen(wxPen(*wxGREEN, 3, wxPENSTYLE_DOT));
wxPoint poly[] = { {220, 60}, {260, 10}, {300, 60} };
dc.DrawPolygon(3, poly);
dc.SetPen(*wxBLACK_PEN);
dc.DrawText(wxString::FromUTF8("基本图元（GDI，无抗锯齿）"), 10, 70);
```

DC 是状态机：`SetPen` 管线条、`SetBrush` 管填充，设一次持续生效直到更换。示例里四个套路：红笔青刷画实心矩形；换 `wxTRANSPARENT_BRUSH` 后椭圆只描边；`wxPen(颜色, 宽 3, wxPENSTYLE_DOT)` 点线画多边形；最后黑色画文字。这条经典 GDI 路线**没有抗锯齿**——斜线锯齿肉眼可见，正好与下一节对照。

## 6.4 wxGraphicsContext：抗锯齿高阶绘制

```cpp
// ═══ 6.4 从 DC 创建 GC：路径 + 贝塞尔曲线 ═══
if (wxGraphicsContext* gc = wxGraphicsContext::Create(dc))
{
    gc->SetPen(wxPen(*wxBLUE, 2));
    wxGraphicsPath path = gc->CreatePath();
    path.MoveToPoint(360.0, 60.0);
    path.AddCurveToPoint(380.0, 10.0, 420.0, 70.0, 440.0, 30.0);
    gc->StrokePath(path);
    gc->SetFont(GetFont(), *wxBLUE);
    gc->DrawText(wxString::FromUTF8("GraphicsContext 抗锯齿贝塞尔"), 350, 70);
    delete gc;
}
```

`wxGraphicsContext` 是各平台高阶 2D API 的统一门面（Windows 上是 GDI+）：浮点坐标、路径对象、默认反走样。`Create(dc)` 在现有 DC 之上叠加创建——同一个 OnPaint 里 GDI 原语与 GC 抗锯齿混排（截图中上半段文字无抗锯齿、下半段贝塞尔与文字平滑，对比立现）。注意两点：Create 返回**裸指针**，用完手动 `delete`；`if (gc)` 初始化语句恰好圈定作用域，后端不可用时整段自然跳过。

## 6.5 鼠标画板：收集端

```cpp
// ═══ 6.5 三个鼠标事件维护笔迹状态 ═══
void DrawPanel::OnLeftDown(wxMouseEvent& e)
{
    m_drawing = true;
    CaptureMouse();                          // 拖出窗口也要收到 UP
    m_strokes.push_back({ e.GetPosition() });
}
void DrawPanel::OnMotion(wxMouseEvent& e)
{
    if (m_drawing && !m_strokes.empty())
    {
        m_strokes.back().push_back(e.GetPosition());
        Refresh(false);                      // 只重绘，不擦背景（减闪烁）
    }
}
void DrawPanel::OnLeftUp(wxMouseEvent&)
{
    m_drawing = false;
    if (HasCapture()) ReleaseMouse();
}
```

- **CaptureMouse** 把后续鼠标事件锁给本窗口：拖画时鼠标滑出客户区也能收到 UP——否则 `m_drawing` 永远卡在 true。释放前先查 `HasCapture()`，配对释放。
- **Refresh(false)** 只标记"需要重绘"不擦背景：擦除的活由 `wxAutoBufferedPaintDC` 在离屏完成，系统再擦一遍就是闪烁的来源。

回放端在 OnPaint 尾部，单点笔迹画点、多点连线：

```cpp
// ═══ 6.6 回放端：单点画点、多点连线 ═══
dc.SetPen(wxPen(*wxBLACK, 2));
for (auto& s : m_strokes)
    if (s.size() == 1)
        dc.DrawPoint(s[0]);
    else
        dc.DrawLines(static_cast<int>(s.size()), s.data());
```

## 6.6 运行与输出：程序化注入笔迹

selftest 不动鼠标：直接 `AddStroke` 注入 3 条各 7 点的笔迹，Refresh 触发真实重绘，`wxYield()` 让 paint 事件在计时前处理完。

```cpp
// ═══ 6.7 注入笔迹 + wxYield 等待重绘落地 ═══
for (int s = 0; s < 3; ++s)
{
    std::vector<wxPoint> stroke;
    for (int i = 0; i < 7; ++i)
        stroke.push_back(wxPoint(40 + s * 60 + i * 8, 380 + (i % 2) * 6));
    m_panel->AddStroke(stroke);
}
m_panel->Refresh();                      // 触发一次真实重绘
wxYield();                               // 让 paint 事件在计时前处理掉
Log("strokes=%zu points=%zu\n",
    m_panel->StrokeCount(), m_panel->PointCount());
Log("paint count after show+inject=%d（>0 即 OnPaint 已走）\n",
    m_panel->PaintCount());
```

selftest 实测输出（sidecar 文件 `build/docs-ref/06_wx_drawing.sidecar` 摘录一次运行，三次连跑逐字节一致）：

```text
==== 06 wx 自绘 开始 ====
strokes=3 points=21
paint count after show+inject=2（>0 即 OnPaint 已走）
==== 06 wx 自绘 结束 ====
```

`strokes=3 points=21` 是注入的 3 笔 × 7 点；`paint count=2` 两次 OnPaint：窗口 Show 时一次、注入后 Refresh 一次——`wxYield` 保证第二次在 Log 之前执行完（paint 是低优先级事件，不等它就打日志，读到的会是旧计数）。

## 坑位清单

- **OnPaint 必须无条件创建 paint DC**：Windows 的 WM_PAINT 靠 wxPaintDC 构造/析构确认；提前 return 不造 DC，系统认为没画完，paint 事件风暴。用 `wxAutoBufferedPaintDC` 同样满足铁律（源码【坑】注释）。
- **双缓冲前提是 wxBG_STYLE_PAINT**：构造函数里不清背景样式，系统在 paint 前先擦一遍，离屏缓冲白做、闪烁照旧——这是双缓冲最常见的"配了没生效"原因。
- **Refresh(false) 不是 Refresh()**：false 表示只重绘不擦背景，擦除交给离屏 Clear；两处擦除叠加正是闪烁来源（源码注释"只重绘，不擦背景（减闪烁）"）。
- **CaptureMouse/ReleaseMouse 必须配对**：Capture 后鼠标事件全归本窗口，忘了 Release，别的窗口从此收不到鼠标；释放前查 `HasCapture()`（源码写法）。
- **wxGraphicsContext::Create 返回裸指针**：用完 `delete gc`；Create 可能失败（平台无后端），if 初始化语句既圈作用域又当空值守卫。
- **读 paint 计数前先 wxYield**：Refresh 只是"标记脏"，paint 事件低优先级；不 yield 就读计数拿到旧值，断言必错——本例 selftest 专门等它（源码注释"让 paint 事件在计时前处理掉"）。

---

上一章：[05 · 对话框与数据校验](05-wx-dialogs.md) ｜ 下一章：[07 · 文档/视图与线程](07-wx-docview-thread.md) ｜ 返回：[README](../README.md)
