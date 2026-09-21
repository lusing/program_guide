// 08_controls_advanced：控件进阶。
//
// 演示四组控件：
//   1. CTreeCtrl      —— 层级数据、TVN_SELCHANGED
//   2. CPropertySheet —— 三页属性表，一键切成向导（SetWizardMode）
//   3. CTaskDialog    —— 带命令链接的现代任务对话框
//   4. CDateTimeCtrl / CProgressCtrl / CSliderCtrl —— 三者联动
//
// 编译运行：.\build.ps1 -File 08_controls_advanced

#include "resource.h"
#include <afxwin.h>
#include <afxdlgs.h>         // CPropertySheet / CPropertyPage 在这里
#include <afxcmn.h>          // CTreeCtrl / CProgressCtrl / CSliderCtrl
#include <afxdtctl.h>        // CDateTimeCtrl
#include <afxtaskdialog.h>   // CTaskDialog 在这里，不在 afxwin.h

// ---------------------------------------------------------------- 属性页
//
// CPropertyPage 继承自 CDialog，但模板必须是 WS_CHILD（见 advanced.rc）。
// OnSetActive / OnWizardFinish 都是虚函数，不需要消息映射。

class CPage1 : public CPropertyPage {
public:
    CPage1() : CPropertyPage(IDD_PAGE1) {}

    // 每次进入本页都会调，可以在这里根据已有数据决定按钮的可用性
    BOOL OnSetActive() override {
        auto* sheet = DYNAMIC_DOWNCAST(CPropertySheet, GetParent());
        if (sheet && sheet->IsWizard())
            sheet->SetWizardButtons(PSWIZB_NEXT);   // 首页没有"上一步"
        return CPropertyPage::OnSetActive();
    }
};

class CPage2 : public CPropertyPage {
public:
    CPage2() : CPropertyPage(IDD_PAGE2) {}

    BOOL OnSetActive() override {
        auto* sheet = DYNAMIC_DOWNCAST(CPropertySheet, GetParent());
        if (sheet && sheet->IsWizard())
            sheet->SetWizardButtons(PSWIZB_BACK | PSWIZB_NEXT);
        return CPropertyPage::OnSetActive();
    }
};

class CPage3 : public CPropertyPage {
public:
    CPage3() : CPropertyPage(IDD_PAGE3) {}

    BOOL OnSetActive() override {
        auto* sheet = DYNAMIC_DOWNCAST(CPropertySheet, GetParent());
        if (sheet && sheet->IsWizard())
            sheet->SetWizardButtons(PSWIZB_BACK | PSWIZB_FINISH);
        return CPropertyPage::OnSetActive();
    }

    // 点"完成"时被调：返回 TRUE 才真的关闭
    BOOL OnWizardFinish() override {
        AfxMessageBox(_T("向导完成，这里可以收集三页的数据。"),
                      MB_ICONINFORMATION);
        return CPropertyPage::OnWizardFinish();
    }
};

// ---------------------------------------------------------------- 主对话框

class CAdvancedDlg : public CDialog {
public:
    CAdvancedDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();

        // ---- 树：三层的目录结构 ----
        HTREEITEM root = m_tree.InsertItem(_T("工程"), TVI_ROOT);
        HTREEITEM src  = m_tree.InsertItem(_T("src"), root);
        m_tree.InsertItem(_T("main.cpp"), src);
        m_tree.InsertItem(_T("dialog.cpp"), src);
        HTREEITEM res  = m_tree.InsertItem(_T("res"), root);
        m_tree.InsertItem(_T("app.rc"), res);
        m_tree.Expand(root, TVE_EXPAND);
        m_tree.Expand(src, TVE_EXPAND);

        // ---- 滑块与进度条：同一量程，滑块动进度条跟着动 ----
        // 注意：CSliderCtrl 只有 SetRange(min, max, bRedraw)，
        // 没有 SetRange32 —— 那个是 CProgressCtrl 的成员。
        m_slider.SetRange(0, 100);
        m_slider.SetTicFreq(10);          // 每 10 一格刻度（需 TBS_AUTOTICKS）
        m_slider.SetPos(30);
        m_progress.SetRange32(0, 100);
        m_progress.SetPos(30);

        // ---- 日期：默认今天。GetCurrentTime 返回临时对象，先落成具名变量 ----
        CTime now = CTime::GetCurrentTime();
        m_date.SetTime(&now);

        return TRUE;
    }

    afx_msg void OnTreeSelChanged(NMHDR* pNMHDR, LRESULT* pResult) {
        auto* pNMTV = reinterpret_cast<NMTREEVIEW*>(pNMHDR);
        CString text = m_tree.GetItemText(pNMTV->itemNew.hItem);
        SetWindowText(_T("控件进阶演示 — 选中：") + text);
        *pResult = 0;
    }

    // 滑块移动 → 进度条跟随。滑块走 WM_HSCROLL，不是 WM_NOTIFY。
    afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) {
        if (pScrollBar && pScrollBar->GetSafeHwnd() == m_slider.GetSafeHwnd())
            m_progress.SetPos(m_slider.GetPos());
        CDialog::OnHScroll(nSBCode, nPos, pScrollBar);
    }

    afx_msg void OnTaskDialog() {
        // CTaskDialog 没有默认构造函数，必须给"内容 / 主指令 / 标题"三参。
        // 写成 CTaskDialog dlg; 会报 C2512（没有合适的默认构造函数）。
        CTaskDialog dlg(_T("选择一种处理方式，下面的按钮是命令链接。"),
                        _T("要对选中的文件做什么？"),
                        _T("任务对话框演示"));
        dlg.SetMainIcon(TD_INFORMATION_ICON);
        dlg.SetFooterText(_T("任务对话框从 Vista 起可用，比 MessageBox 能装更多东西。"));
        dlg.AddCommandControl(101, _T("直接删除"));
        dlg.AddCommandControl(102, _T("移到回收站"));
        dlg.AddCommandControl(103, _T("跳过"));

        // DoModal 返回的是被点中的命令 ID（这里就是 101/102/103），
        // 点右上角 X 或按 Esc 则返回 IDCANCEL。
        INT_PTR cmd = dlg.DoModal();
        CString msg;
        msg.Format(_T("你选了命令 %d（返回的是命令 ID，不是 IDOK）。"), (int)cmd);
        AfxMessageBox(msg, MB_ICONINFORMATION);
    }

    afx_msg void OnWizard() {
        // 三个页对象必须活到 DoModal 返回之后，所以放在栈上、在 DoModal
        // 之前 AddPage —— 属性表只存指针，不接管所有权。
        CPage1 p1;
        CPage2 p2;
        CPage3 p3;

        CPropertySheet sheet(_T("三页向导"));
        sheet.AddPage(&p1);
        sheet.AddPage(&p2);
        sheet.AddPage(&p3);
        sheet.SetWizardMode();     // 一键从"属性表"变"向导"

        // 向导点"完成"返回 IDOK（MFC 把 Finish 按钮就当作 IDOK 处理），
        // 点"取消"/关窗口返回 IDCANCEL。
        if (sheet.DoModal() == IDOK)
            AfxMessageBox(_T("向导正常走完了。"), MB_ICONINFORMATION);
    }

    DECLARE_MESSAGE_MAP()

private:
    CTreeCtrl     m_tree;
    CProgressCtrl m_progress;
    CSliderCtrl   m_slider;
    CDateTimeCtrl m_date;
};

BEGIN_MESSAGE_MAP(CAdvancedDlg, CDialog)
    ON_NOTIFY(TVN_SELCHANGED, IDC_TREE, OnTreeSelChanged)
    ON_WM_HSCROLL()
    ON_BN_CLICKED(IDC_TASKDLG, OnTaskDialog)
    ON_BN_CLICKED(IDC_WIZARD, OnWizard)
END_MESSAGE_MAP()

// ---------------------------------------------------------------- 应用

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CAdvancedDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;   // 对话框关了就该退出，不必再进消息循环
    }
};

CMyApp theApp;
