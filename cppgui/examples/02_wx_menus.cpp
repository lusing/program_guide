// ============================================================
// 02_wx_menus.cpp —— 菜单栏 / 工具栏 / 状态栏 / 加速键 / 动态启停
//
// 要点：
//   * wxMenu/wxMenuBar 组装：Append / AppendCheckItem / AppendRadioItem
//     / AppendSeparator / 子菜单嵌套；~X~ 热键 + "\tCtrl-N" 加速键
//   * 事件接线的两种写法对照：静态事件表 EVT_MENU vs 动态 Bind
//   * 工具栏 wxToolBar::AddTool（复用菜单命令号，事件同为 wxEVT_MENU）
//   * 状态栏多格 SetStatusText
//   * wxEVT_UPDATE_UI：不点击也能每空闲拍更新 UI 状态（禁用/勾选）
//   * 右键弹出菜单 PopupMenu
// 官方参考：samples/menu/menu.cpp、samples/toolbar/toolbar.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/artprov.h"    // wxArtProvider 标准图标
#include "wx/cmdline.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-02_wx_menus.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// ---- 命令号：自定义从 100 起，避免与标准 ID 冲突 ----
enum
{
    Menu_File_New = 100,
    Menu_File_Open,
    Menu_File_Save,
    Menu_File_AutoSave,     // checkable
    Menu_View_Mode1,        // radio 组
    Menu_View_Mode2,
    Menu_View_Mode3,
    Menu_Help_About = wxID_ABOUT,
};

class MyFrame : public wxFrame
{
public:
    MyFrame();

    // 事件表风格的处理器（编译期接线）
    void OnQuit(wxCommandEvent&);
    void OnAbout(wxCommandEvent&);
    void OnNew(wxCommandEvent&);

    // Bind 风格的处理器（运行期接线，同一函数形态）
    void OnOpen(wxCommandEvent&);
    void OnSave(wxCommandEvent&);
    void OnToggleAutoSave(wxCommandEvent&);
    void OnViewMode(wxCommandEvent&);
    void OnUpdateSave(wxUpdateUIEvent&);      // 动态启停"保存"
    void OnRightUp(wxMouseEvent&);            // 右键弹出菜单
    void OnSelftestTimer(wxTimerEvent&);

private:
    wxDECLARE_EVENT_TABLE();
    wxTimer m_timer;
    bool m_modified = false;                  // 模拟"文档已修改"
};

wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    EVT_MENU(wxID_EXIT,  MyFrame::OnQuit)     // 静态事件表（对照 01 章）
    EVT_MENU(Menu_Help_About, MyFrame::OnAbout)
    EVT_MENU(Menu_File_New,   MyFrame::OnNew)
    EVT_TIMER(wxID_ANY, MyFrame::OnSelftestTimer)
wxEND_EVENT_TABLE()

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
    p.AddSwitch(wxEmptyString, "selftest", "smoke test");  // 注意：第二参才是长名
}

bool MyApp::OnInit()
{
    if (!wxApp::OnInit()) return false;
    if (g_selftest)
        Log("==== 02 wx 菜单与工具栏 开始 ====\n");
    (new MyFrame())->Show(true);
    return true;
}

int MyApp::OnExit()
{
    if (g_selftest) Log("==== 02 wx 菜单与工具栏 结束 ====\n");
    return 0;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("02 - 菜单/工具栏/状态栏"),
              wxDefaultPosition, wxSize(720, 480))
    , m_timer(this)
{
    // ---------- 菜单栏 ----------
    wxMenu* fileMenu = new wxMenu;
    fileMenu->Append(Menu_File_New,  "&New\tCtrl-N",   "Create new document");
    fileMenu->Append(Menu_File_Open, "&Open...\tCtrl-O", "Open existing");
    fileMenu->Append(Menu_File_Save, "&Save\tCtrl-S",  "Save (disabled until modified)");
    fileMenu->AppendSeparator();
    fileMenu->AppendCheckItem(Menu_File_AutoSave, "A&uto-save", "Checkable item");
    fileMenu->AppendSeparator();
    fileMenu->Append(wxID_EXIT, "E&xit\tAlt-X");

    // 视图菜单：单选组（radio items 自动互斥）
    wxMenu* viewMenu = new wxMenu;
    viewMenu->AppendRadioItem(Menu_View_Mode1, wxString::FromUTF8("模式：紧凑"));
    viewMenu->AppendRadioItem(Menu_View_Mode2, wxString::FromUTF8("模式：舒适"));
    viewMenu->AppendRadioItem(Menu_View_Mode3, wxString::FromUTF8("模式：宽大"));
    viewMenu->Check(Menu_View_Mode2, true);          // 程序化勾选

    // 嵌套子菜单
    wxMenu* sub = new wxMenu;
    sub->Append(Menu_File_New, "子菜单项 A");
    sub->Append(Menu_File_Open, "子菜单项 B");
    fileMenu->AppendSeparator();
    fileMenu->AppendSubMenu(sub, "&More...");

    wxMenu* helpMenu = new wxMenu;
    helpMenu->Append(Menu_Help_About, "&About\tF1");

    wxMenuBar* bar = new wxMenuBar;
    bar->Append(fileMenu, "&File");
    bar->Append(viewMenu, "&View");
    bar->Append(helpMenu, "&Help");
    SetMenuBar(bar);

    // ---------- 工具栏（命令号复用菜单 → 事件同源）----------
    wxToolBar* tb = CreateToolBar();
    tb->AddTool(Menu_File_New,  "New",  wxArtProvider::GetBitmap(wxART_NEW));
    tb->AddTool(Menu_File_Open, "Open", wxArtProvider::GetBitmap(wxART_FILE_OPEN));
    tb->AddTool(Menu_File_Save, "Save", wxArtProvider::GetBitmap(wxART_FILE_SAVE));
    tb->AddSeparator();
    tb->AddTool(Menu_Help_About, "About", wxArtProvider::GetBitmap(wxART_HELP));
    tb->Realize();               // 添加完必须 Realize

    // ---------- 状态栏（3 格）----------
    CreateStatusBar(3);
    SetStatusText(wxString::FromUTF8("就绪"), 0);
    SetStatusText(wxString::FromUTF8("第 2 格"), 1);
    SetStatusText("column 3", 2);

    // ---------- Bind 动态接线（对照事件表静态接线）----------
    Bind(wxEVT_MENU, &MyFrame::OnOpen,  this, Menu_File_Open);
    Bind(wxEVT_MENU, &MyFrame::OnSave,  this, Menu_File_Save);
    Bind(wxEVT_MENU, &MyFrame::OnToggleAutoSave, this, Menu_File_AutoSave);
    Bind(wxEVT_MENU, &MyFrame::OnViewMode, this, Menu_View_Mode1, Menu_View_Mode3);
    Bind(wxEVT_UPDATE_UI, &MyFrame::OnUpdateSave, this, Menu_File_Save);
    Bind(wxEVT_RIGHT_UP, &MyFrame::OnRightUp, this);

    if (g_selftest) m_timer.StartOnce(700);
}

// ---------- 事件处理器 ----------
void MyFrame::OnNew(wxCommandEvent&)   { m_modified = true; }
void MyFrame::OnQuit(wxCommandEvent&)  { Close(true); }
void MyFrame::OnAbout(wxCommandEvent&)
{
    wxMessageBox("Menus / Toolbar / StatusBar demo", "About", wxOK, this);
}

void MyFrame::OnOpen(wxCommandEvent&)
{
    m_modified = false;
    SetStatusText(wxString::FromUTF8("打开（演示）"), 0);
}
void MyFrame::OnSave(wxCommandEvent&)  { m_modified = false; }
void MyFrame::OnToggleAutoSave(wxCommandEvent& e)
{
    GetMenuBar()->Check(Menu_File_AutoSave, e.IsChecked());  // 与菜单项同步
}
void MyFrame::OnViewMode(wxCommandEvent& e)
{
    SetStatusText(wxString::Format("View mode: %d", e.GetId() - Menu_View_Mode1), 0);
}

// UPDATE_UI：每次空闲拍都会走这里——UI 状态集中维护点
void MyFrame::OnUpdateSave(wxUpdateUIEvent& e)
{
    e.Enable(m_modified);        // 未修改时"保存"灰掉
    e.SetText(m_modified ? "&Save\tCtrl-S" : "&Save (nothing)");
}

// 右键弹出菜单
void MyFrame::OnRightUp(wxMouseEvent& event)
{
    wxMenu menu;
    menu.Append(Menu_File_New, "Popup: New");
    menu.Append(Menu_File_Open, "Popup: Open");
    menu.AppendSeparator();
    menu.Append(wxID_EXIT, "Popup: Exit");
    PopupMenu(&menu, event.GetPosition());
}

// ---------- selftest ----------
void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    // 程序化验证：结构计数 + UPDATE_UI 行为 + radio 状态
    wxMenuBar* bar = GetMenuBar();
    int menus = bar->GetMenuCount();
    int fileItems = bar->GetMenu(0)->GetMenuItemCount();
    Log("menubar menus=%d, file items=%d\n", menus, fileItems);

    m_modified = true;
    wxUpdateUIEvent e(Menu_File_Save);   // 直接喂一个 UPDATE_UI 事件
    OnUpdateSave(e);
    Log("UPDATE_UI with modified=true: enabled=%d\n", (int)e.GetEnabled());
    m_modified = false;
    wxUpdateUIEvent e2(Menu_File_Save);
    OnUpdateSave(e2);
    Log("UPDATE_UI with modified=false: enabled=%d\n", (int)e2.GetEnabled());

    Log("radio mode2 checked=%d, mode1 checked=%d\n",
        (int)bar->IsChecked(Menu_View_Mode2), (int)bar->IsChecked(Menu_View_Mode1));

    Log("toolbar tools=%d, status fields=%d\n",
        (int)GetToolBar()->GetToolsCount(), (int)GetStatusBar()->GetFieldsCount());
    Close(true);
}
