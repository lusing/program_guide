// ============================================================
// 07_wx_docview_thread.cpp —— 文档/视图框架 + 后台线程安全更新 UI
//
// 上半：wxDocument/wxView/wxDocManager/wxDocTemplate
//   * 文档（数据+序列化）与视图（呈现）分离，一个文档可挂多视图
//   * 序列化钩子是流式的：SaveObject(wxOutputStream&) /
//     LoadObject(wxInputStream&)（wx 3.3 实测签名）
// 下半：wxThread + wxQueueEvent + wxEVT_THREAD
//   * 铁律：UI 线程之外【禁止】碰控件；wxQueueEvent 是唯一安全通路
// 官方参考：samples/docview/docview.cpp、samples/thread/thread.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"
#include "wx/docview.h"
#include "wx/thread.h"
#include "wx/txtstrm.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-07_wx_docview_thread.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

class MyFrame;   // 前置（视图要回指）

// ---------------- 文档：数据 + 流式序列化 ----------------
// 【实测坑位】SaveObject/LoadObject 有两套签名，取决于 wxUSE_STD_IOSTREAM：
// 本构建（默认）走 std::ostream/std::istream 版本。
class MyDocument : public wxDocument
{
public:
    wxString m_text = "hello docview";

    std::ostream& SaveObject(std::ostream& stream) override
    {
        wxDocument::SaveObject(stream);          // 基类存文档头
        stream << m_text.utf8_str();             // 自定义内容随后
        return stream;
    }
    std::istream& LoadObject(std::istream& stream) override
    {
        wxDocument::LoadObject(stream);
        std::string s;
        stream >> s;                             // 与 Save 对称：读一个词
        m_text = wxString::FromUTF8(s.c_str());
        return stream;
    }

private:
    wxDECLARE_DYNAMIC_CLASS(MyDocument);         // CLASSINFO 反射创建所需
};
wxIMPLEMENT_DYNAMIC_CLASS(MyDocument, wxDocument);

// ---------------- 视图：把文档画到主窗口画布上 ----------------
class MyView : public wxView
{
public:
    bool OnCreate(wxDocument* doc, long flags) override;
    bool OnClose(bool deleteWindow = true) override;
    void OnDraw(wxDC* dc) override;              // 框架/画布回调

    MyFrame* m_frame = nullptr;
    int m_drawCalls = 0;

private:
    wxDECLARE_DYNAMIC_CLASS(MyView);
};
wxIMPLEMENT_DYNAMIC_CLASS(MyView, wxView);

// ---------------- 后台线程：进度经事件投递 ----------------
class WorkerThread : public wxThread
{
public:
    WorkerThread(wxEvtHandler* sink, int id, int steps)
        : wxThread(wxTHREAD_DETACHED), m_sink(sink), m_id(id), m_steps(steps) {}

protected:
    ExitCode Entry() override
    {
        for (int i = 1; i <= m_steps; ++i)
        {
            wxMilliSleep(6);                     // 模拟耗时
            auto* e = new wxThreadEvent(wxEVT_THREAD, m_id);
            e->SetInt(i);                        // 载荷：进度
            wxQueueEvent(m_sink, e);             // 线程→主线程唯一通路
            if (TestDestroy()) return nullptr;
        }
        auto* done = new wxThreadEvent(wxEVT_THREAD, m_id + 1000);
        wxQueueEvent(m_sink, done);
        return nullptr;
    }
private:
    wxEvtHandler* m_sink;
    int m_id, m_steps;
};

// ---------------- 主窗口 ----------------
class MyFrame : public wxFrame
{
public:
    explicit MyFrame(wxDocManager* mgr);

    void OnViewPaint(wxPaintEvent&);
    void OnThread(wxThreadEvent& e);
    void OnSelftestTimer(wxTimerEvent&);
    void StartWorkers();

    MyView* m_view = nullptr;                    // 视图挂靠点
    wxPanel* m_canvas = nullptr;                 // 视图画布（public：视图要访问）

private:
    void OnNew(wxCommandEvent&);
    void OnCloseWindow(wxCloseEvent& e);

    wxDocManager* m_docMgr = nullptr;
    wxGauge*   m_gauge[2] = {};
    wxStaticText* m_label[2] = {};
    WorkerThread* m_worker[2] = {};
    int m_doneCount = 0;
    const int m_steps = 40;
    wxTimer m_timer;
};

class MyApp : public wxApp
{
public:
    bool OnInit() override;
    int  OnExit() override;
    void OnInitCmdLine(wxCmdLineParser& p) override;
    bool OnCmdLineParsed(wxCmdLineParser& p) override { g_selftest = p.Found("selftest"); return wxApp::OnCmdLineParsed(p); }
private:
    wxDocManager* m_docMgr = nullptr;
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
    if (g_selftest) Log("==== 07 wx docview+线程 开始 ====\n");

    // 文档管理器 + 模板（登记 文档类/视图类/文件通配符——CLASSINFO 反射）
    m_docMgr = new wxDocManager;
    auto* tpl = new wxDocTemplate(m_docMgr, "Text", "*.t7txt", "", "t7txt",
                                  "Text Doc", "Text Doc/View",
                                  CLASSINFO(MyDocument), CLASSINFO(MyView));

    auto* frame = new MyFrame(m_docMgr);
    SetTopWindow(frame);
    frame->Show(true);

    if (g_selftest)
    {
        // 【坑】CreateDocument 非 SILENT 时会弹"选模板"对话框——selftest
        // 直接走模板创建（等价 File→New 确认后的路径）。
        MyDocument* doc = static_cast<MyDocument*>(tpl->CreateDocument("", wxDOC_NEW));
        Log("CreateDocument: doc=%p, view attached=%d\n",
            (void*)doc, (int)(frame->m_view != nullptr));
        if (!doc) { Log("模板创建失败\n"); return true; }
        doc->Modify(true);
        Log("doc modified=%d（脏标记由框架跟踪）\n", (int)doc->IsModified());
    }
    return true;
}

int MyApp::OnExit()
{
    // 不在此 delete 管理器：退出期顶层窗口可能已销毁，文档关闭链会
    // 触碰悬垂 frame 指针（教学示例以进程退出兜底收尾）
    if (g_selftest) Log("==== 07 wx docview+线程 结束 ====\n");
    return 0;
}

MyFrame::MyFrame(wxDocManager* mgr)
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("07 - 文档视图 + 后台线程"),
              wxDefaultPosition, wxSize(660, 460))
    , m_timer(this)
    , m_docMgr(mgr)
{
    wxMenu* fileMenu = new wxMenu;
    fileMenu->Append(wxID_NEW);
    fileMenu->Append(wxID_EXIT);
    SetMenuBar(new wxMenuBar);
    GetMenuBar()->Append(fileMenu, "&File");
    CreateStatusBar();
    Bind(wxEVT_MENU, &MyFrame::OnNew, this, wxID_NEW);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { Close(true); }, wxID_EXIT);

    wxBoxSizer* root = new wxBoxSizer(wxVERTICAL);

    // 上半：视图画布（paint 时调用 view->OnDraw）
    m_canvas = new wxPanel(this, wxID_ANY, wxDefaultPosition, wxSize(-1, 200),
                           wxBORDER_SUNKEN);
    m_canvas->SetBackgroundStyle(wxBG_STYLE_PAINT);
    m_canvas->Bind(wxEVT_PAINT, &MyFrame::OnViewPaint, this);
    root->Add(m_canvas, 1, wxEXPAND | wxALL, 6);

    // 下半：两条进度条（对应两个 worker）
    for (int i = 0; i < 2; ++i)
    {
        m_label[i] = new wxStaticText(this, wxID_ANY, wxString::Format("worker %d: -", i));
        m_gauge[i] = new wxGauge(this, wxID_ANY, m_steps);
        root->Add(m_label[i], 0, wxALL, 4);
        root->Add(m_gauge[i], 0, wxEXPAND | wxLEFT | wxRIGHT, 8);
    }
    auto* btn = new wxButton(this, wxID_ANY, wxString::FromUTF8("启动两个后台线程"));
    btn->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { StartWorkers(); });
    root->Add(btn, 0, wxALL | wxALIGN_CENTER, 8);
    SetSizer(root);

    Bind(wxEVT_THREAD, &MyFrame::OnThread, this);
    Bind(wxEVT_TIMER, &MyFrame::OnSelftestTimer, this);
    Bind(wxEVT_CLOSE_WINDOW, &MyFrame::OnCloseWindow, this);
    if (g_selftest) m_timer.StartOnce(900);
}

void MyFrame::OnNew(wxCommandEvent&)
{
    // File→New 交给文档管理器（走模板创建 doc+view 全流程）
    m_docMgr->CreateDocument("", wxDOC_NEW);
}

void MyFrame::OnViewPaint(wxPaintEvent&)
{
    wxPaintDC dc(m_canvas);                      // 【坑】必须无条件创建
    dc.Clear();
    if (m_view)
        m_view->OnDraw(&dc);                     // 委托给视图：文档的呈现
}

void MyFrame::StartWorkers()
{
    if (m_worker[0] || m_worker[1]) return;
    for (int i = 0; i < 2; ++i)
    {
        m_worker[i] = new WorkerThread(this, 100 + i, m_steps);
        m_worker[i]->Run();
    }
}

void MyFrame::OnThread(wxThreadEvent& e)
{
    int which = e.GetId() - 100;
    if (which >= 0 && which < 2)
    {
        int v = e.GetInt();
        m_gauge[which]->SetValue(v);             // 主线程里才能碰控件
        m_label[which]->SetLabel(wxString::Format("worker %d: %d/%d", which, v, m_steps));
    }
    else if (e.GetId() >= 1100)
    {
        int w = e.GetId() - 1100;
        m_label[w]->SetLabel(wxString::Format("worker %d: done", w));
        Log("worker %d done（wxEVT_THREAD 完成信号）\n", w);
        m_worker[w] = nullptr;                   // DETACHED 线程自毁
        if (++m_doneCount == 2 && g_selftest)
        {
            Log("gauges: %d/%d, %d/%d\n",
                m_gauge[0]->GetValue(), m_steps, m_gauge[1]->GetValue(), m_steps);
            Close(true);
        }
    }
}

void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    Log("view OnDraw calls=%d（画布 paint 已驱动视图绘制）\n",
        m_view ? m_view->m_drawCalls : -1);
    StartWorkers();
}

void MyFrame::OnCloseWindow(wxCloseEvent& e)
{
    // 线程在跑就先拒绝（教学示例：线程 ~300ms 自然结束，稍后再关即可）
    for (int i = 0; i < 2; ++i)
        if (m_worker[i]) { e.Veto(); return; }
    e.Skip(true);
}

// ---------------- 视图实现 ----------------
bool MyView::OnCreate(wxDocument* doc, long WXUNUSED(flags))
{
    m_frame = static_cast<MyFrame*>(wxTheApp->GetTopWindow());
    m_frame->m_view = this;                      // 挂靠：画布 paint 会来找我
    SetFrame(m_frame);
    Activate(true);
    m_frame->m_canvas->Refresh();
    return true;
}

bool MyView::OnClose(bool WXUNUSED(deleteWindow))
{
    if (!GetDocument()->Close()) return false;
    Activate(false);
    if (m_frame) m_frame->m_view = nullptr;
    SetFrame(nullptr);
    return true;
}

void MyView::OnDraw(wxDC* dc)
{
    ++m_drawCalls;
    auto* doc = static_cast<MyDocument*>(GetDocument());
    dc->SetFont(wxFontInfo(14).Bold());
    dc->DrawText("doc: " + doc->m_text, 16, 16);
    dc->SetFont(wxFontInfo(10));
    dc->DrawText(wxString::FromUTF8("视图负责呈现文档（文档/视图分离）"), 16, 44);
}
