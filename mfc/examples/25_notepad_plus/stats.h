// stats.h：统计面板（非模态对话框）+ 后台统计线程的接口。
#pragma once

#include <afxwin.h>
#include <afxcmn.h>
#include <memory>
#include <string>

#define WM_APP_STATS_DONE  (WM_APP + 10)  // 统计线程完成通知（lParam 指向结果堆对象）
#define WM_APP_STATS_CLOSED (WM_APP + 11) // 面板销毁通知（主窗口清空指针用）

// 统计面板：非模态，用 shared_ptr 把文本快照交给 worker 线程，
// 结果用 WM_APP_STATS_DONE 回到 UI 线程更新列表。
class CStatsDialog : public CDialog {
public:
    enum { IDD = IDD_STATS };

    explicit CStatsDialog(CWnd* parent);
    ~CStatsDialog() override;

    // 主窗口调用：传当前文本的快照，启动（或排队）一次统计
    void UpdateText(std::shared_ptr<std::wstring> text);

    BOOL Create(CWnd* parent) { return CDialog::Create(IDD, parent); }

protected:
    BOOL OnInitDialog() override;
    void DoDataExchange(CDataExchange* pDX) override;

    void OnCancel() override { DestroyWindow(); }
    void PostNcDestroy() override {
        if (GetOwner())   // 让主窗口把 m_stats 指针清空，避免悬挂
            GetOwner()->PostMessage(WM_APP_STATS_CLOSED);
        delete this;
    }

    afx_msg void OnClickedRefresh();
    afx_msg LRESULT OnStatsDone(WPARAM wParam, LPARAM lParam);

    DECLARE_MESSAGE_MAP()

private:
    void RunThread();
    void SetRow(int row, const CString& name, const CString& value);

    CListCtrl m_list;
    std::shared_ptr<std::wstring> m_pending;  // 线程运行期间到达的新文本
    bool m_running = false;
    bool m_dirty = false;   // m_pending 是否有待统计的新内容
};
