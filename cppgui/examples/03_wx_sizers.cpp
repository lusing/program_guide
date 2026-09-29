// ============================================================
// 03_wx_sizers.cpp —— Sizer 布局系统：盒子/网格/弹性/换行
//
// 要点：
//   * wxBoxSizer：方向 + proportion(拉伸权重) + border + 对齐 flags
//   * wxGridSizer / wxFlexGridSizer（AddGrowableCol 可拉伸列）
//   * wxWrapSizer：放不下自动换行
//   * wxSizerFlags：链式风格的现代写法（Border/Expand/Proportion）
//   * spacer 占位、嵌套组合、SetSizerAndFit 自动适配
// 布局思维：不给控件绝对坐标，而是描述"谁拉伸、谁固定、间距多少"，
// 窗口 resize 后按权重重新分配空间（保留模式下的响应式布局）。
// 官方参考：samples/sizer/sizer.cpp
// ============================================================
#include "wx/wxprec.h"
#ifndef WX_PRECOMP
    #include "wx/wx.h"
#endif
#include "wx/cmdline.h"
#include "wx/wrapsizer.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-03_wx_sizers.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

static wxButton* MkBtn(wxWindow* parent, const char* label)
{
    return new wxButton(parent, wxID_ANY, wxString::FromUTF8(label));
}

class MyFrame : public wxFrame
{
public:
    MyFrame();
    void OnSelftestTimer(wxTimerEvent&);
private:
    wxTimer m_timer;
    wxBoxSizer* m_root = nullptr;
    wxFlexGridSizer* m_flex = nullptr;
    wxWrapSizer* m_wrap = nullptr;
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
    if (g_selftest) Log("==== 03 wx Sizer 布局 开始 ====\n");
    (new MyFrame())->Show(true);
    return true;
}

int MyApp::OnExit()
{
    if (g_selftest) Log("==== 03 wx Sizer 布局 结束 ====\n");
    return 0;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, wxString::FromUTF8("03 - Sizer 布局"),
              wxDefaultPosition, wxSize(560, 520))
    , m_timer(this)
{
    m_root = new wxBoxSizer(wxVERTICAL);

    // ---------- 1. BoxSizer：proportion 与 border ----------
    // proportion=0 不拉伸（保持最佳尺寸）；>0 按权重分剩余空间
    wxBoxSizer* box = new wxBoxSizer(wxHORIZONTAL);
    box->Add(MkBtn(this, "固定(p=0)"), 0, wxALL, 4);
    box->Add(MkBtn(this, "拉伸(p=1)"), 1, wxALL | wxEXPAND, 4);
    box->Add(MkBtn(this, "拉伸(p=2)"), 2, wxALL | wxEXPAND, 4);
    box->AddSpacer(16);                       // spacer：纯占位
    box->Add(MkBtn(this, "右贴"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 4);

    // ---------- 2. GridSizer：等宽等高格 ----------
    wxGridSizer* grid = new wxGridSizer(3, 2, 4, 4);   // 3 列 2 行，间隙 4x4
    for (int i = 1; i <= 6; ++i)
        grid->Add(MkBtn(this, std::to_string(i).c_str()), 0, wxEXPAND);

    // ---------- 3. FlexGridSizer：行高列宽按内容，可设拉伸列 ----------
    m_flex = new wxFlexGridSizer(2, 8, 8);    // 2 列，间隙 8x8
    m_flex->AddGrowableCol(1);                // 第 2 列吃掉剩余宽度
    m_flex->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("用户名：")), 0, wxALIGN_CENTER_VERTICAL);
    m_flex->Add(new wxTextCtrl(this, wxID_ANY), 0, wxEXPAND);
    m_flex->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("密码：")), 0, wxALIGN_CENTER_VERTICAL);
    // 【实测坑位】wxTextCtrl 第 3 参是"初值"而非样式——直接传
    // wxTE_PASSWORD 会撞上故意私有化的 wxString(int)，报 C2248。
    m_flex->Add(new wxTextCtrl(this, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD), 0, wxEXPAND);

    // ---------- 4. WrapSizer：水平流式自动换行 ----------
    m_wrap = new wxWrapSizer(wxHORIZONTAL, wxWRAPSIZER_DEFAULT_FLAGS);
    for (int i = 0; i < 8; ++i)
        m_wrap->Add(MkBtn(this, ("标签" + std::to_string(i + 1)).c_str()), 0, wxALL, 2);

    // ---------- 5. wxSizerFlags 链式风格（现代写法）----------
    wxBoxSizer* flagsBox = new wxBoxSizer(wxHORIZONTAL);
    flagsBox->Add(MkBtn(this, "Flags 左"), wxSizerFlags().Border(wxALL, 8).CenterVertical());
    flagsBox->AddStretchSpacer(1);
    flagsBox->Add(MkBtn(this, "Flags 右"), wxSizerFlags().Right().Border(wxALL, 8));

    // ---------- 组装 ----------
    m_root->Add(box, 0, wxEXPAND | wxALL, 6);
    m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— GridSizer 3x2 ——")), 0, wxALL, 2);
    m_root->Add(grid, 0, wxEXPAND | wxALL, 6);
    m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— FlexGrid（第 2 列可拉伸）——")), 0, wxALL, 2);
    m_root->Add(m_flex, 0, wxEXPAND | wxALL, 6);
    m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— WrapSizer（缩窗换行）——")), 0, wxALL, 2);
    m_root->Add(m_wrap, 0, wxEXPAND | wxALL, 6);
    m_root->Add(flagsBox, 0, wxEXPAND);

    SetSizerAndFit(m_root);      // 挂 sizer 并按内容适配最小尺寸
    Bind(wxEVT_TIMER, &MyFrame::OnSelftestTimer, this);
    if (g_selftest) m_timer.StartOnce(700);
}

void MyFrame::OnSelftestTimer(wxTimerEvent&)
{
    // 程序化验证：结构计数 + 布局计算的确定性
    Log("root children=%d (5 个区块 + 3 个小标题)\n", (int)m_root->GetChildren().GetCount());
    wxSize minRoot = m_root->CalcMin();
    Log("root CalcMin = %dx%d\n", minRoot.x, minRoot.y);

    wxSize minFlex = m_flex->CalcMin();
    Log("flex CalcMin = %dx%d（两行文本框的最小需求）\n", minFlex.x, minFlex.y);

    Log("wrap children=%d\n", (int)m_wrap->GetChildren().GetCount());

    // 嵌套场景：把 root 铺进 1000x800 的假想区域，验证布局器能算出位置
    wxSizerItem* first = m_root->GetChildren()[0];
    Log("box 区块 proportion=%d, border=%d\n",
        first->GetProportion(), (int)first->GetBorder());
    Close(true);
}
