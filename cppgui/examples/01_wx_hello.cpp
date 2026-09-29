// ============================================================
// 01_wx_hello.cpp —— wxWidgets 最小应用：wxApp/wxFrame/事件表/消息循环
//
// 保留模式范式导读：
//   与 imgui（08 章）相反，wx 是经典"保留模式"——先构建一棵
//   【控件对象树】（Frame→MenuBar/StatusBar/控件），它们常驻内存、
//   自带状态；应用只注册【事件处理器】，事件到来时被回调改状态，
//   需要时由库负责重绘。控件是对话者，不是每帧重跑的代码。
// 三件套：
//   wxIMPLEMENT_APP(MyApp)   —— 宏生成真正的 main，创建应用对象
//   MyApp::OnInit()          —— 初始化：建主窗口、Show
//   隐式的 OnRun()           —— 进入消息循环（不用自己写 while）
// 事件接线的两种写法（本例事件表 + 02 章起混用 Bind）：
//   wxBEGIN_EVENT_TABLE / EVT_MENU / wxEND_EVENT_TABLE（静态、编译期）
// 官方参考：samples/minimal/minimal.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"     // wxCmdLineParser（命令行钩子用）

#include <cstdio>
#include <cstring>

// ---- 应用类：每个 wx 程序一个，宏负责实例化 ----
class MyApp : public wxApp
{
public:
    virtual bool OnInit() override;
    virtual int  OnExit() override;   // 消息循环结束后、对象清理前调用

    // 【实测坑位】基类 OnInit 会用 wxCmdLineParser 解析命令行，任何
    // 未注册的参数（选项或位置参数）都让解析报错 → OnInit 返回 false
    // → 程序以 255 秒退。想让程序接受自己的参数，正道是重写这两个钩子：
    virtual void OnInitCmdLine(wxCmdLineParser& parser) override;
    virtual bool OnCmdLineParsed(wxCmdLineParser& parser) override;

    bool m_selftest = false;
};

// ---- 主窗口类：事件处理器不写成 virtual ----
class MyFrame : public wxFrame
{
public:
    MyFrame(const wxString& title, bool selftest);

    void OnQuit(wxCommandEvent& event);    // File→Exit
    void OnAbout(wxCommandEvent& event);   // Help→About
    void OnSelftestTimer(wxTimerEvent& event);  // selftest 自动退出

private:
    wxDECLARE_EVENT_TABLE();
    wxTimer m_selftestTimer;   // selftest 用：600ms 一次性定时器
};

enum
{
    Minimal_Quit  = wxID_EXIT,    // 标准退出 ID（macOS 上有特殊待遇）
    Minimal_About = wxID_ABOUT
};

// 静态事件表：把事件"路由"到成员函数（编译期接线）
wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    EVT_MENU(Minimal_Quit,  MyFrame::OnQuit)
    EVT_MENU(Minimal_About, MyFrame::OnAbout)
    EVT_TIMER(wxID_ANY,     MyFrame::OnSelftestTimer)
wxEND_EVENT_TABLE()

// 宏 = 真正的 main：创建 MyApp、初始化 wx、跑消息循环
wxIMPLEMENT_APP(MyApp);

bool MyApp::OnInit()
{
    if (!wxApp::OnInit())     // 基类解析命令行（含下面注册的 --selftest）
        return false;

    if (m_selftest)           // GUI 子系统：标记写 sidecar 文件
    {                         // （build.ps1 走 sidecar 判定分支）
        if (FILE* f = std::fopen("selftest-01_wx_hello.txt", "w"))
            std::fprintf(f, "==== 01 wx 最小应用 开始 ====\n"), std::fclose(f);
    }

    MyFrame* frame = new MyFrame(
        wxString::FromUTF8("01 - 最小 wxWidgets 应用"), m_selftest);
    frame->Show(true);        // frame 默认不显示，必须显式 Show

    return true;              // true → 进入 OnRun() 的消息循环
}

// 注册自定义开关 --selftest。
// 【实测坑位】AddSwitch/AddOption 第一个参数是【短名】（须单字符），
// 第二个参数才是长名——写成 AddSwitch("selftest", ...) 时它被当成短名
// 注册，--selftest 依旧解析报错 → OnCmdLineError → 退出码 255。
void MyApp::OnInitCmdLine(wxCmdLineParser& parser)
{
    wxApp::OnInitCmdLine(parser);   // 先保留标准选项（--help 等）
    parser.AddSwitch(wxEmptyString, "selftest",
                     "run briefly then exit (for automated smoke test)");
}

// 解析成功后取值
bool MyApp::OnCmdLineParsed(wxCmdLineParser& parser)
{
    m_selftest = parser.Found("selftest");
    return wxApp::OnCmdLineParsed(parser);
}

int MyApp::OnExit()
{
    if (m_selftest)
    {
        if (FILE* f = std::fopen("selftest-01_wx_hello.txt", "a"))
            std::fprintf(f, "主窗口已关闭，事件循环正常退出\n"
                            "==== 01 wx 最小应用 结束 ====\n"), std::fclose(f);
    }
    return 0;
}

MyFrame::MyFrame(const wxString& title, bool selftest)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, wxSize(640, 400))
    , m_selftestTimer(this)   // 定时器属主=本 frame → 事件回投给 frame
{
    // 菜单栏：File(Exit) + Help(About)
    wxMenu* fileMenu = new wxMenu;
    fileMenu->Append(Minimal_Quit, "E&xit\tAlt-X", "Quit this program");
    wxMenu* helpMenu = new wxMenu;
    helpMenu->Append(Minimal_About, "&About\tF1", "Show about dialog");

    wxMenuBar* menuBar = new wxMenuBar();
    menuBar->Append(fileMenu, "&File");
    menuBar->Append(helpMenu, "&Help");
    SetMenuBar(menuBar);

    // 状态栏（2 格）
    CreateStatusBar(2);
    SetStatusText(wxString::FromUTF8("欢迎使用 wxWidgets（保留模式）"), 0);

    // selftest：不等人手，600ms 后自动关窗走正常退出路径
    if (selftest)
        m_selftestTimer.StartOnce(600);
}

void MyFrame::OnQuit(wxCommandEvent& WXUNUSED(event))
{
    Close(true);              // true = 强制关闭（绕过 OnQueryClose 询问）
}

void MyFrame::OnAbout(wxCommandEvent& WXUNUSED(event))
{
    wxMessageBox(wxString::Format(
                     "Welcome to %s!\n\n这是最小 wxWidgets 示例，\n运行于 %s。",
                     wxVERSION_STRING, wxGetOsDescription()),
                 wxString::FromUTF8("关于"),
                 wxOK | wxICON_INFORMATION, this);
}

void MyFrame::OnSelftestTimer(wxTimerEvent& WXUNUSED(event))
{
    if (FILE* f = std::fopen("selftest-01_wx_hello.txt", "a"))
        std::fprintf(f, "selftest：菜单/状态栏/主循环均已运行，定时器触发自动退出\n"),
        std::fclose(f);
    Close(true);
}
