// stats.cpp：统计面板实现。
//
// 线程模型：
//   UI 线程                          worker 线程
//   --------                         -----------
//   UpdateText(快照) --StartThread--> StatsThreadProc
//                                      纯计算，不碰任何控件
//   OnStatsDone <--PostMessage------- 堆上 StatsResult
//   delete result; 更新 CListCtrl
//
// 关键点：线程里只读 shared_ptr 指向的快照，绝不直接访问控件；
// 线程运行时又来了新文本就先存 m_pending，结束后再统计一轮。
#include "resource.h"
#include "stats.h"

// ---- 跨线程数据包 ----
struct StatsRequest {
    HWND hwnd;                                  // 结果回传目标
    std::shared_ptr<std::wstring> text;         // 只读快照
};

struct StatsResult {
    DWORD chars;
    DWORD charsNoSpace;
    DWORD words;
    DWORD lines;
    DWORD paragraphs;
};

// worker 线程入口：只做计算和 PostMessage
UINT StatsThreadProc(LPVOID pParam) {
    std::unique_ptr<StatsRequest> req(static_cast<StatsRequest*>(pParam));

    const std::wstring& s = *req->text;
    auto* result = new StatsResult{ 0, 0, 0, 0, 0 };

    result->chars = (DWORD)s.size();
    bool inWord = false;
    bool lastWasNL = false;
    for (wchar_t c : s) {
        if (c != L' ' && c != L'\t' && c != L'\r' && c != L'\n')
            ++result->charsNoSpace;
        if (c == L' ' || c == L'\t' || c == L'\r' || c == L'\n') {
            inWord = false;                     // 空白结束一个“词”
        } else {
            if (!inWord)
                ++result->words;
            inWord = true;
        }
        if (c == L'\n') {
            ++result->lines;
            lastWasNL = true;
            continue;
        }
        if (lastWasNL && c != L'\n')
            ++result->paragraphs;               // 非空行开头 = 新段落
        lastWasNL = false;
    }
    if (!s.empty() && s.back() != L'\n')
        ++result->lines;                        // 最后一行没有换行符

    // PostMessage 只投递 32 位值，堆对象用指针传；UI 线程负责 delete
    ::PostMessage(req->hwnd, WM_APP_STATS_DONE, 0, (LPARAM)result);
    return 0;
}

// ---- 对话框 ----
CStatsDialog::CStatsDialog(CWnd* parent) : CDialog(IDD_STATS, parent) {}

CStatsDialog::~CStatsDialog() = default;

BOOL CStatsDialog::OnInitDialog() {
    CDialog::OnInitDialog();
    m_list.SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);
    m_list.InsertColumn(0, _T("指标"), LVCFMT_LEFT, 76);
    m_list.InsertColumn(1, _T("数值"), LVCFMT_RIGHT, 56);
    for (int i = 0; i < 5; ++i)
        m_list.InsertItem(i, _T(""));
    SetRow(0, _T("字符数"),   _T("-"));
    SetRow(1, _T("去空白"),   _T("-"));
    SetRow(2, _T("单词数"),   _T("-"));
    SetRow(3, _T("行数"),     _T("-"));
    SetRow(4, _T("段落数"),   _T("-"));
    return TRUE;
}

void CStatsDialog::DoDataExchange(CDataExchange* pDX) {
    CDialog::DoDataExchange(pDX);
    DDX_Control(pDX, IDC_STATS_LIST, m_list);   // 控件 <-> 成员绑定
}

void CStatsDialog::SetRow(int row, const CString& name, const CString& value) {
    m_list.SetItemText(row, 0, name);
    m_list.SetItemText(row, 1, value);
}

// 主窗口推来一份新文本快照
void CStatsDialog::UpdateText(std::shared_ptr<std::wstring> text) {
    if (m_running) {
        m_pending = std::move(text);   // 正在算：先存着，结束后补算
        m_dirty = true;
        return;
    }
    m_pending = std::move(text);
    RunThread();
}

void CStatsDialog::RunThread() {
    auto* req = new StatsRequest{ GetSafeHwnd(), m_pending };
    m_running = true;
    m_dirty = false;
    if (!AfxBeginThread(StatsThreadProc, req)) {
        delete req;                    // 线程创建失败要回收资源包
        m_running = false;
    }
}

afx_msg void CStatsDialog::OnClickedRefresh() {
    // 让主窗口给一份最新文本：简单起见直接自己找主窗口要
    CFrameWnd* frame = static_cast<CFrameWnd*>(AfxGetMainWnd());
    if (!frame)
        return;
    CString text;
    CWnd* edit = frame->GetDlgItem(IDC_EDIT);
    if (edit) {
        edit->GetWindowText(text);
        UpdateText(std::make_shared<std::wstring>(text.GetString(),
                                                  text.GetLength()));
    }
}

afx_msg LRESULT CStatsDialog::OnStatsDone(WPARAM /*wParam*/, LPARAM lParam) {
    m_running = false;

    // 结果是线程 new 的堆对象，这里接管并负责释放
    std::unique_ptr<StatsResult> r(reinterpret_cast<StatsResult*>(lParam));
    if (!r)
        return 0;

    CString v;
    v.Format(_T("%u"), r->chars);    SetRow(0, _T("字符数"), v);
    v.Format(_T("%u"), r->charsNoSpace); SetRow(1, _T("去空白"), v);
    v.Format(_T("%u"), r->words);    SetRow(2, _T("单词数"), v);
    v.Format(_T("%u"), r->lines);    SetRow(3, _T("行数"), v);
    v.Format(_T("%u"), r->paragraphs); SetRow(4, _T("段落数"), v);

    if (m_dirty)      // 统计期间文本又变了？再来一轮
        RunThread();
    return 0;
}

BEGIN_MESSAGE_MAP(CStatsDialog, CDialog)
    ON_BN_CLICKED(IDC_STATS_REFRESH, OnClickedRefresh)
    ON_MESSAGE(WM_APP_STATS_DONE, OnStatsDone)
END_MESSAGE_MAP()
