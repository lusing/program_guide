// ============================================================
// 05_wx_dialogs.cpp —— 标准对话框 / 自定义对话框 / 数据校验
//
// 要点：
//   * 标准对话框五件套：wxMessageDialog / wxFileDialog /
//     wxColourDialog / wxFontDialog / wxProgressDialog（菜单触发）
//   * 自定义 wxDialog：sizer 布局 + OK/Cancel 标准按钮 +
//     TransferDataToWindow/FromWindow 数据搬运钩子
//   * wxTextValidator：wxFILTER_ALPHANUMERIC 等过滤器 + 校验失败拦截
//   * ShowModal 返回值分派（wxID_OK / wxID_CANCEL）
// 官方参考：samples/dialogs/dialogs.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"
#include "wx/colordlg.h"
#include "wx/fontdlg.h"
#include "wx/spinctrl.h"
#include "wx/valgen.h"     // wxGenericValidator
#include "wx/valtext.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-05_wx_dialogs.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

enum
{
    Dlg_MsgBox = 200,
    Dlg_FileOpen,
    Dlg_FileSave,
    Dlg_Colour,
    Dlg_Font,
    Dlg_Custom,
};

// ---------- 自定义对话框：带数据搬运与校验 ----------
class MyNameDialog : public wxDialog
{
public:
    MyNameDialog(wxWindow* parent);

    // 数据搬运钩子：模态前后自动搬运（也可手动调）
    bool TransferDataToWindow() override;
    bool TransferDataFromWindow() override;

    wxString m_name;          // 对外数据（成员即"模型"）
    int      m_age = 18;

    // 教学示例从简设为 public（selftest 需直接检查控件）
    wxTextCtrl* m_nameCtrl = nullptr;
    wxSpinCtrl* m_ageCtrl = nullptr;
};

MyNameDialog::MyNameDialog(wxWindow* parent)
    : wxDialog(parent, wxID_ANY, wxString::FromUTF8("录入人员信息"),
               wxDefaultPosition, wxDefaultSize)
{
    wxBoxSizer* top = new wxBoxSizer(wxVERTICAL);
    wxFlexGridSizer* form = new wxFlexGridSizer(2, 8, 8);
    form->AddGrowableCol(1);

    form->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("姓名（仅字母数字）")),
              0, wxALIGN_CENTER_VERTICAL);
    m_nameCtrl = new wxTextCtrl(this, wxID_ANY);
    // 校验器：绑到控件 + 指向"模型"成员，Validate/Transfer 时自动搬运。
    // wx 3.3 的 wxTextValidator 没有 SetMinLength——长度校验自己做。
    m_nameCtrl->SetValidator(wxTextValidator(wxFILTER_ALPHANUMERIC, &m_name));
    form->Add(m_nameCtrl, 0, wxEXPAND);

    form->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("年龄")),
              0, wxALIGN_CENTER_VERTICAL);
    m_ageCtrl = new wxSpinCtrl(this, wxID_ANY, "18", wxDefaultPosition, wxDefaultSize,
                               wxSP_ARROW_KEYS, 1, 120, 18);
    m_ageCtrl->SetValidator(wxGenericValidator(&m_age));   // 通用校验器：整型直通
    form->Add(m_ageCtrl, 0, wxEXPAND);

    top->Add(form, 0, wxEXPAND | wxALL, 12);
    top->Add(CreateSeparatedButtonSizer(wxOK | wxCANCEL), 0, wxEXPAND | wxALL, 8);  // 标准按钮排

    SetSizerAndFit(top);
}

bool MyNameDialog::TransferDataToWindow()
{
    if (!wxDialog::TransferDataToWindow()) return false;
    m_nameCtrl->SetValue(m_name);        // 模型 → 控件
    m_ageCtrl->SetValue(m_age);
    return true;
}

bool MyNameDialog::TransferDataFromWindow()
{
    if (!wxDialog::TransferDataFromWindow()) return false;
    m_name = m_nameCtrl->GetValue();     // 控件 → 模型
    m_age = m_ageCtrl->GetValue();
    return true;
}

// ---------- 主窗口：菜单触发各对话框 ----------
class MyFrame : public wxFrame
{
public:
    MyFrame();
    void OnSelftestTimer(wxTimerEvent&);
private:
    void OnMsgBox(wxCommandEvent&);
    void OnFileOpen(wxCommandEvent&);
    void OnColour(wxCommandEvent&);
    void OnCustom(wxCommandEvent&);
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
    if (g_selftest) Log("==== 05 wx 对话框 开始 ====\n");
    (new MyFrame())->Show(true);
    return true;
}

int MyApp::OnExit()
{
    if (g_selftest) Log("==== 05 wx 对话框 结束 ====\n");
    return 0;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("05 - 对话框与校验"),
              wxDefaultPosition, wxSize(600, 380))
    , m_timer(this)
{
    wxMenu* menu = new wxMenu;
    menu->Append(Dlg_MsgBox, wxString::FromUTF8("消息框(&M)"));
    menu->Append(Dlg_FileOpen, wxString::FromUTF8("打开文件(&O)...\tCtrl-O"));
    menu->AppendSeparator();
    menu->Append(Dlg_Colour, wxString::FromUTF8("颜色(&C)..."));
    menu->Append(Dlg_Font, wxString::FromUTF8("字体(&F)..."));
    menu->AppendSeparator();
    menu->Append(Dlg_Custom, wxString::FromUTF8("自定义对话框(&D)..."));
    wxMenuBar* bar = new wxMenuBar;
    bar->Append(menu, wxString::FromUTF8("对话框(&D)"));
    SetMenuBar(bar);
    CreateStatusBar();

    Bind(wxEVT_MENU, &MyFrame::OnMsgBox, this, Dlg_MsgBox);
    Bind(wxEVT_MENU, &MyFrame::OnFileOpen, this, Dlg_FileOpen);
    Bind(wxEVT_MENU, &MyFrame::OnColour, this, Dlg_Colour);
    // 字体对话框用 lambda 接线演示
    Bind(wxEVT_MENU, [this](wxCommandEvent&) {
        wxFontData data;
        data.SetInitialFont(GetFont());
        wxFontDialog dlg(this, data);
        if (dlg.ShowModal() == wxID_OK)
            SetFont(dlg.GetFontData().GetChosenFont());
    }, Dlg_Font);
    Bind(wxEVT_MENU, &MyFrame::OnCustom, this, Dlg_Custom);
    Bind(wxEVT_TIMER, &MyFrame::OnSelftestTimer, this);

    SetStatusText(wxString::FromUTF8("用菜单打开各对话框"));
    if (g_selftest) m_timer.StartOnce(700);
}

void MyFrame::OnMsgBox(wxCommandEvent&)
{
    // 三按钮 + 图标 + 默认按钮组合；YesNo 带帮助按钮变体
    wxMessageDialog dlg(this,
        wxString::FromUTF8("要继续操作吗？\n这是 wxMessageDialog。"),
        wxString::FromUTF8("确认"),
        wxYES_NO | wxCANCEL | wxICON_QUESTION | wxYES_DEFAULT | wxHELP);
    int rc = dlg.ShowModal();
    Log("msgbox ShowModal=%s\n",
        rc == wxID_YES ? "wxID_YES" : rc == wxID_NO ? "wxID_NO" : "CANCEL");
}

void MyFrame::OnFileOpen(wxCommandEvent&)
{
    wxFileDialog dlg(this, wxString::FromUTF8("打开文件"), "",
                     "",
                     wxString::FromUTF8("文本文件 (*.txt;*.md)|*.txt;*.md|所有文件 (*.*)|*.*"),
                     wxFD_OPEN | wxFD_FILE_MUST_EXIST);
    if (dlg.ShowModal() == wxID_OK)
        SetStatusText(dlg.GetPath());
}

void MyFrame::OnColour(wxCommandEvent&)
{
    wxColourData data;
    data.SetColour(*wxBLUE);
    wxColourDialog dlg(this, &data);
    if (dlg.ShowModal() == wxID_OK)
        SetBackgroundColour(dlg.GetColourData().GetColour());
}

void MyFrame::OnCustom(wxCommandEvent&)
{
    MyNameDialog dlg(this);
    dlg.m_name = "Tom";
    if (dlg.ShowModal() == wxID_OK)
        wxLogStatus("name=%s age=%d", dlg.m_name, dlg.m_age);
}

// ---------- selftest：不走 ShowModal，直接构造+搬运+校验 ----------
void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    MyNameDialog dlg(this);
    dlg.m_name = "Tom123";
    dlg.m_age = 20;
    dlg.TransferDataToWindow();               // 模型 → 控件
    Log("after ToWindow: ctrl=%s（TransferData 搬运可见）\n",
        (const char*)dlg.m_nameCtrl->GetValue().utf8_str());

    dlg.m_nameCtrl->SetValue("legal9");
    Log("Validate(legal input)=%d\n", (int)dlg.Validate());
    // 注意：非法输入走 Validate 会弹「Validation conflict」模态框
    // （src/common/valtext.cpp:144 wxMessageBox），selftest 不能碰——
    // 负路径由交互模式（菜单 → 自定义对话框）演示。
    dlg.m_nameCtrl->SetValue("abc");
    dlg.TransferDataFromWindow();             // 控件 → 模型
    Log("after FromWindow: m_name=%s len=%zu\n",
        (const char*)dlg.m_name.utf8_str(), dlg.m_name.length());

    // 校验器另一面：非法输入在按键层就被过滤器吃掉（wxFILTER_ALPHA 不收数字）
    wxTextCtrl probe(this, wxID_ANY);
    probe.SetValidator(wxTextValidator(wxFILTER_ALPHA));
    Log("probe validator filter ok（构造成功）\n");
    Close(true);
}
