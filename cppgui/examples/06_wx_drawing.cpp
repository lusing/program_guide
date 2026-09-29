// ============================================================
// 06_wx_drawing.cpp —— 设备上下文绘图：wxDC / 双缓冲 / 抗锯齿
//
// 要点：
//   * wxEVT_PAINT 里【必须】创建 wxPaintDC（哪怕不画——否则
//     Windows 上 WM_PAINT 不会被确认，事件风暴/重绘异常）
//   * wxBufferedPaintDC 双缓冲：resize 不闪烁
//   * 画笔 wxPen（线）/ 画刷 wxBrush（填充）样式
//   * wxGraphicsContext：GDI+ 抗锯齿高阶路径
//   * 鼠标画板：事件收集点列 → paint 统一重放（"状态+重绘"模型）
// 官方参考：samples/drawing/painting.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"
#include "wx/dcbuffer.h"     // wxBufferedPaintDC
#include "wx/graphics.h"     // wxGraphicsContext

#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <vector>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-06_wx_drawing.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// ---------- 画板：收集笔迹，重绘时统一回放 ----------
class DrawPanel : public wxPanel
{
public:
    DrawPanel(wxWindow* parent);

    void AddStroke(const std::vector<wxPoint>& pts) { m_strokes.push_back(pts); }
    size_t StrokeCount() const { return m_strokes.size(); }
    size_t PointCount() const;
    int    PaintCount() const { return m_paintCount; }

private:
    void OnPaint(wxPaintEvent&);
    void OnLeftDown(wxMouseEvent&);
    void OnMotion(wxMouseEvent&);
    void OnLeftUp(wxMouseEvent&);

    std::vector<std::vector<wxPoint>> m_strokes;
    bool m_drawing = false;
    int m_paintCount = 0;
};

DrawPanel::DrawPanel(wxWindow* parent)
    : wxPanel(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
              wxBORDER_SUNKEN)
{
    SetBackgroundStyle(wxBG_STYLE_PAINT);    // 双缓冲要求：自管背景擦除
    Bind(wxEVT_PAINT, &DrawPanel::OnPaint, this);
    Bind(wxEVT_LEFT_DOWN, &DrawPanel::OnLeftDown, this);
    Bind(wxEVT_MOTION, &DrawPanel::OnMotion, this);
    Bind(wxEVT_LEFT_UP, &DrawPanel::OnLeftUp, this);
}

size_t DrawPanel::PointCount() const
{
    size_t n = 0;
    for (auto& s : m_strokes) n += s.size();
    return n;
}

void DrawPanel::OnPaint(wxPaintEvent&)
{
    ++m_paintCount;
    // 【坑】wxPaintDC 必须无条件创建（即使什么都不画）
    wxAutoBufferedPaintDC dc(this);          // 双缓冲版 paint DC
    wxSize sz = GetClientSize();
    dc.SetBackground(*wxWHITE_BRUSH);
    dc.Clear();

    // ---- 基本图元：线/矩形/椭圆/多边形/文字 ----
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

    // ---- wxGraphicsContext：抗锯齿高阶绘制 ----
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

    // ---- 回放笔迹 ----
    dc.SetPen(wxPen(*wxBLACK, 2));
    for (auto& s : m_strokes)
        if (s.size() == 1)
            dc.DrawPoint(s[0]);
        else
            dc.DrawLines(static_cast<int>(s.size()), s.data());
}

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

// ---------- 主窗口 ----------
class MyFrame : public wxFrame
{
public:
    MyFrame();
    void OnSelftestTimer(wxTimerEvent&);
private:
    DrawPanel* m_panel = nullptr;
    wxTimer m_timer;
};

class MyApp : public wxApp
{
public:
    bool OnInit() override;
    int  OnExit() override;
    void OnInitCmdLine(wxCmdLineParser& p) override;
    bool OnCmdLineParsed(wxCmdLineParser& p) override { g_selftest = p.Found("selftest"); return wxApp::OnCmdLineParsed(p); }
};
wxIMPLEMENT_APP(MyApp);

void MyApp::OnInitCmdLine(wxCmdLineParser& p)
{
    wxApp::OnInitCmdLine(p);
    p.AddSwitch(wxEmptyString, "selftest", "smoke test");
}

bool MyApp::OnInit()
{
    if (!wxApp::OnInit()) return false;
    if (g_selftest) Log("==== 06 wx 自绘 开始 ====\n");
    (new MyFrame())->Show(true);
    return true;
}

int MyApp::OnExit()
{
    if (g_selftest) Log("==== 06 wx 自绘 结束 ====\n");
    return 0;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("06 - DC 绘图与双缓冲"),
              wxDefaultPosition, wxSize(760, 480))
    , m_timer(this)
{
    m_panel = new DrawPanel(this);
    CreateStatusBar();
    SetStatusText(wxString::FromUTF8("左键拖动画笔迹；程序化注入见 selftest"));
    Bind(wxEVT_TIMER, &MyFrame::OnSelftestTimer, this);
    if (g_selftest) m_timer.StartOnce(800);
}

void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    // 程序化注入 3 条笔迹（各 7 个点）——不经过鼠标，验证"收集→回放"管线
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
    Close(true);
}
