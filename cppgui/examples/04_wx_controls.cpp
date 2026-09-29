// ============================================================
// 04_wx_controls.cpp —— 常用控件大全与事件绑定
//
// 覆盖：Button / CheckBox / RadioBox / StaticText / Choice /
//       ComboBox / Slider / SpinCtrl / Gauge / 多行 TextCtrl /
//       ListCtrl（report 报表模式）
// 事件：Bind(wxEVT_XXX) 全家 + 两种取值方式对照
// （wx 约定：SetValue/GetValue 是控件值的统一接口——保留模式
//   的"状态"都住在控件里，与 imgui 的"状态在外部变量"对照）
// 官方参考：samples/widgets/、samples/listctrl/listtest.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"
#include "wx/listctrl.h"   // wxListCtrl
#include "wx/spinctrl.h"   // wxSpinCtrl

#include <cstdarg>
#include <cstdio>
#include <cstring>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-04_wx_controls.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

class MyFrame : public wxFrame
{
public:
    MyFrame();
    void OnSelftestTimer(wxTimerEvent&);

    // 被验证的控件指针
    wxButton*     m_btn = nullptr;
    wxCheckBox*   m_check = nullptr;
    wxRadioBox*   m_radio = nullptr;
    wxChoice*     m_choice = nullptr;
    wxComboBox*   m_combo = nullptr;
    wxSlider*     m_slider = nullptr;
    wxSpinCtrl*   m_spin = nullptr;
    wxTextCtrl*   m_multi = nullptr;
    wxListCtrl*   m_list = nullptr;
    wxGauge*      m_gauge = nullptr;

private:
    wxTimer m_timer;
    int m_clickCount = 0;
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
    if (g_selftest) Log("==== 04 wx 控件大全 开始 ====\n");
    (new MyFrame())->Show(true);
    return true;
}

int MyApp::OnExit()
{
    if (g_selftest) Log("==== 04 wx 控件大全 结束 ====\n");
    return 0;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("04 - 常用控件"),
              wxDefaultPosition, wxSize(760, 560))
    , m_timer(this)
{
    wxBoxSizer* root = new wxBoxSizer(wxVERTICAL);
    wxBoxSizer* row1 = new wxBoxSizer(wxHORIZONTAL);

    // ---------- 按钮与计数：事件里的"改状态" ----------
    m_btn = new wxButton(this, wxID_ANY, wxString::FromUTF8("点我 +1"));
    m_btn->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) {
        ++m_clickCount;
        SetStatusText(wxString::Format("clicked=%d", m_clickCount), 0);
    });
    row1->Add(m_btn, 0, wxALL, 4);

    // ---------- 复选框：bool 值 ----------
    m_check = new wxCheckBox(this, wxID_ANY, wxString::FromUTF8("启用夜间模式"));
    m_check->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent& e) {
        Log("checkbox -> %d\n", (int)e.IsChecked());   // 事件里即时取值
    });
    row1->Add(m_check, 0, wxALL | wxALIGN_CENTER_VERTICAL, 4);

    // ---------- 单选组：枚举值 ----------
    const wxString modes[] = { wxString::FromUTF8("低"), wxString::FromUTF8("中"), wxString::FromUTF8("高") };
    m_radio = new wxRadioBox(this, wxID_ANY, wxString::FromUTF8("画质"),
                             wxDefaultPosition, wxDefaultSize, 3, modes, 1, wxRA_SPECIFY_COLS);
    m_radio->Bind(wxEVT_RADIOBOX, [this](wxCommandEvent& e) {
        Log("radiobox -> sel=%d label=%s\n", e.GetInt(),
            (const char*)m_radio->GetStringSelection().utf8_str());
    });
    row1->Add(m_radio, 0, wxALL, 4);

    root->Add(row1, 0, wxEXPAND);

    // ---------- Choice（只读下拉）vs ComboBox（可编辑）----------
    wxBoxSizer* row2 = new wxBoxSizer(wxHORIZONTAL);
    m_choice = new wxChoice(this, wxID_ANY);
    m_choice->Append(wxArrayString{ "alpha", "beta", "gamma" });
    m_choice->SetSelection(0);
    m_choice->Bind(wxEVT_CHOICE, [this](wxCommandEvent& e) {
        Log("choice -> %s\n", (const char*)e.GetString().utf8_str());
    });
    row2->Add(m_choice, 1, wxALL | wxEXPAND, 4);

    m_combo = new wxComboBox(this, wxID_ANY, "");   // 可输入，也能 SetValue
    m_combo->Append(wxArrayString{ wxString::FromUTF8("北京"), wxString::FromUTF8("上海"), wxString::FromUTF8("深圳") });
    m_combo->Bind(wxEVT_COMBOBOX, [this](wxCommandEvent& e) {
        Log("combobox -> %s\n", (const char*)e.GetString().utf8_str());
    });
    row2->Add(m_combo, 1, wxALL | wxEXPAND, 4);
    root->Add(row2, 0, wxEXPAND);

    // ---------- 数值三件套：Slider / SpinCtrl / Gauge ----------
    wxBoxSizer* row3 = new wxBoxSizer(wxHORIZONTAL);
    m_slider = new wxSlider(this, wxID_ANY, 30, 0, 100,
                            wxDefaultPosition, wxDefaultSize, wxSL_HORIZONTAL | wxSL_LABELS);
    m_slider->Bind(wxEVT_SLIDER, [this](wxCommandEvent&) {
        Log("slider -> %d\n", m_slider->GetValue());
    });
    row3->Add(m_slider, 1, wxALL | wxEXPAND, 4);

    m_spin = new wxSpinCtrl(this, wxID_ANY, "1", wxDefaultPosition, wxDefaultSize,
                            wxSP_ARROW_KEYS, 1, 100, 1);
    m_spin->Bind(wxEVT_SPINCTRL, [this](wxSpinEvent& e) {
        Log("spin -> %d\n", e.GetValue());
    });
    row3->Add(m_spin, 0, wxALL, 4);

    m_gauge = new wxGauge(this, wxID_ANY, 100);
    m_gauge->SetValue(30);
    row3->Add(m_gauge, 1, wxALL | wxEXPAND, 4);
    root->Add(row3, 0, wxEXPAND);

    // ---------- 多行文本 ----------
    m_multi = new wxTextCtrl(this, wxID_ANY, "",
                             wxDefaultPosition, wxSize(-1, 120),
                             wxTE_MULTILINE | wxTE_RICH2);
    *m_multi << wxString::FromUTF8("第一行：多行编辑\n第二行：rich2\n");
    root->Add(m_multi, 1, wxALL | wxEXPAND, 4);

    // ---------- ListCtrl：report 模式（列 + 行）----------
    m_list = new wxListCtrl(this, wxID_ANY, wxDefaultPosition, wxSize(-1, 160),
                            wxLC_REPORT | wxBORDER_SUNKEN);
    m_list->InsertColumn(0, "ID", wxLIST_FORMAT_LEFT, 60);
    m_list->InsertColumn(1, wxString::FromUTF8("名称"), wxLIST_FORMAT_LEFT, 160);
    m_list->InsertColumn(2, wxString::FromUTF8("数量"), wxLIST_FORMAT_RIGHT, 80);
    const char* names[] = { "apple", "banana", "cherry" };
    for (int i = 0; i < 3; ++i)
    {
        long idx = m_list->InsertItem(i, wxString::Format("%d", 100 + i));
        m_list->SetItem(idx, 1, names[i]);
        m_list->SetItem(idx, 2, wxString::Format("%d", (i + 1) * 7));
    }
    m_list->Bind(wxEVT_LIST_ITEM_SELECTED, [this](wxListEvent& e) {
        Log("list selected -> %ld\n", (long)e.GetIndex());
    });
    root->Add(m_list, 0, wxALL | wxEXPAND, 4);

    CreateStatusBar(2);
    SetSizerAndFit(root);
    Bind(wxEVT_TIMER, &MyFrame::OnSelftestTimer, this);
    if (g_selftest) m_timer.StartOnce(700);
}

void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    // 程序化驱动各控件并读回——事件逻辑之外，值接口本身也要测
    m_check->SetValue(true);
    Log("check GetValue=%d\n", (int)m_check->GetValue());

    m_radio->SetSelection(2);
    Log("radio GetSelection=%d label=%s\n", m_radio->GetSelection(),
        (const char*)m_radio->GetStringSelection().utf8_str());

    m_choice->SetStringSelection("gamma");
    Log("choice GetSelection=%d\n", m_choice->GetSelection());

    m_combo->SetValue(wxString::FromUTF8("广州"));   // 【坑】窄字面量按本地编码(GBK)解释，中文必须 FromUTF8
    Log("combo GetValue=%s\n", (const char*)m_combo->GetValue().utf8_str());

    m_slider->SetValue(77);
    Log("slider GetValue=%d\n", m_slider->GetValue());

    m_spin->SetValue(42);
    Log("spin GetValue=%d\n", m_spin->GetValue());

    m_gauge->SetValue(66);
    Log("gauge GetValue=%d\n", m_gauge->GetValue());

    // 模拟一次按钮点击（不经过鼠标）：构造命令事件直接投给控件
    wxCommandEvent e(wxEVT_BUTTON, m_btn->GetId());
    m_btn->ProcessWindowEvent(e);
    Log("clicks after synthetic click=%d\n", m_clickCount);

    Log("list GetItemCount=%d, row1 text=%s\n",
        (int)m_list->GetItemCount(),
        (const char*)m_list->GetItemText(1).utf8_str());

    long lines = m_multi->GetNumberOfLines();
    Log("multi lines=%ld\n", lines);
    Close(true);
}
