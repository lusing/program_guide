// 07_controls：控件深入 —— CListCtrl 报表视图是重点。
//
// 演示：
//   1. CListCtrl 报表模式：插入列、插入行、子项文本
//   2. 点击列头排序（LVN_COLUMNCLICK + SortItems）
//   3. 右键弹出菜单（TrackPopupMenu）
//   4. CComboBox / CEdit / CButton 组成“添加一行”表单
//   5. 选中项操作：获取、删除
//
// 编译运行：.\build.ps1 -File 07_controls

#include <afxwin.h>
#include <afxcmn.h>   // CListCtrl 等公共控件

// 每行的排序比较数据：挂在 item 的 lParam 上
struct ItemData {
    CString name;   // 排序时 SortItems 只给 lParam，所以文本也要存一份
    int priority;   // 数字越小越靠前
};

class CControlsWnd : public CFrameWnd {
public:
    CControlsWnd() {
        Create(NULL, _T("任务列表演示"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 760, 520));
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;

        SetGuiFont(m_list);
        SetGuiFont(m_edit);
        SetGuiFont(m_combo);
        SetGuiFont(m_btnAdd);

        // ---- 列表：报表视图 ----
        m_list.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_TABSTOP |
                          LVS_REPORT | LVS_SHOWSELALWAYS | LVS_SINGLESEL,
                      CRect(0, 0, 0, 0), this, IDC_LIST);
        m_list.SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);

        m_list.InsertColumn(0, _T("任务名"), LVCFMT_LEFT, 220);
        m_list.InsertColumn(1, _T("优先级"), LVCFMT_CENTER, 90);
        m_list.InsertColumn(2, _T("状态"),   LVCFMT_CENTER, 100);

        // ---- 表单区 ----
        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_TABSTOP |
                          ES_AUTOHSCROLL,
                      CRect(0, 0, 0, 0), this, IDC_NAME);
        m_combo.Create(WS_CHILD | WS_VISIBLE | WS_TABSTOP | CBS_DROPDOWNLIST,
                       CRect(0, 0, 0, 0), this, IDC_PRIORITY);
        for (int i = 0; i < 3; ++i)
            m_combo.AddString(PriorityName(i));
        m_combo.SetCurSel(1);

        m_btnAdd.Create(_T("添加任务"), WS_CHILD | WS_VISIBLE | WS_TABSTOP |
                            BS_PUSHBUTTON,
                        CRect(0, 0, 0, 0), this, IDC_ADD);

        // 预置几行数据
        AddRow(_T("编写需求文档"), 0);
        AddRow(_T("实现消息循环"), 1);
        AddRow(_T("修复内存泄漏"), 2);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (!m_list.GetSafeHwnd())
            return;

        const int margin = 12, formH = 30, gap = 8;
        m_list.MoveWindow(margin, margin, cx - 2 * margin,
                          cy - margin * 2 - formH - gap);
        int y = cy - margin - formH;
        m_btnAdd.MoveWindow(cx - margin - 110, y, 110, formH);
        m_combo.MoveWindow(cx - margin - 110 - gap - 130, y, 130, formH);
        m_edit.MoveWindow(margin, y, cx - margin * 2 - 110 - gap - 130 - gap,
                          formH);
    }

    afx_msg void OnClickedAdd() {
        CString name;
        m_edit.GetWindowText(name);
        if (name.Trim().IsEmpty()) {
            MessageBox(_T("请输入任务名"), _T("提示"), MB_ICONWARNING);
            return;
        }
        AddRow(name, m_combo.GetCurSel());
        m_edit.SetWindowText(_T(""));
        m_edit.SetFocus();
    }

    // 点击列头：按该列排序（只有优先级列有真实数据，其他列按文本排）
    afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult) {
        auto* pNM = reinterpret_cast<NMLISTVIEW*>(pNMHDR);
        m_sortCol = pNM->iSubItem;
        m_sortAsc = !m_sortAsc;
        // SortItems 把比较函数和“当前 this”传给系统，逐对回调比较
        m_list.SortItems(CompareProc, reinterpret_cast<LPARAM>(this));
        *pResult = 0;
    }

    // 右键：弹出上下文菜单
    afx_msg void OnContextMenu(CWnd* /*pWnd*/, CPoint point) {
        if (m_list.GetNextItem(-1, LVNI_SELECTED) < 0)
            return;  // 没选中行就不弹菜单

        // 键盘弹出菜单（Shift+F10）时 point 是 (-1,-1)，要换算到选中行
        if (point.x == -1 && point.y == -1) {
            CRect rc;
            m_list.GetItemRect(m_list.GetNextItem(-1, LVNI_SELECTED),
                               &rc, LVIR_BOUNDS);
            point = CPoint(rc.left + 40, rc.CenterPoint().y);
            m_list.ClientToScreen(&point);
        }

        CMenu menu;
        menu.CreatePopupMenu();
        menu.AppendMenu(MF_STRING, IDM_MARK_DONE, _T("标记为完成"));
        menu.AppendMenu(MF_STRING, IDM_DELETE, _T("删除(&D)"));

        // TrackPopupMenu 阻塞直到用户选择；TPM_RETURNCMD 直接返回命令 ID
        int cmd = menu.TrackPopupMenu(TPM_LEFTALIGN | TPM_RIGHTBUTTON |
                                          TPM_RETURNCMD,
                                      point.x, point.y, this);
        if (cmd == IDM_DELETE)
            DeleteSelected();
        else if (cmd == IDM_MARK_DONE)
            MarkSelectedDone();
    }

    DECLARE_MESSAGE_MAP()

private:
    static LPCTSTR PriorityName(int i) {
        static LPCTSTR names[] = { _T("高"), _T("中"), _T("低") };
        return names[i];
    }

    void AddRow(const CString& name, int priority) {
        int index = m_list.GetItemCount();
        auto* data = new ItemData{ name, priority };
        int row = m_list.InsertItem(LVIF_TEXT | LVIF_PARAM, index,
                                    name, 0, 0, 0, (LPARAM)data);
        m_list.SetItemText(row, 1, PriorityName(priority));
        m_list.SetItemText(row, 2, _T("进行中"));
    }

    void DeleteSelected() {
        int row = m_list.GetNextItem(-1, LVNI_SELECTED);
        if (row < 0)
            return;
        FreeRowData(row);
        m_list.DeleteItem(row);
    }

    void MarkSelectedDone() {
        int row = m_list.GetNextItem(-1, LVNI_SELECTED);
        if (row < 0)
            return;
        m_list.SetItemText(row, 2, _T("已完成"));
    }

    // 行数据挂在 lParam 上，删行时记得释放，否则内存泄漏
    void FreeRowData(int row) {
        delete reinterpret_cast<ItemData*>(m_list.GetItemData(row));
    }

    // SortItems 的静态比较函数：lhs/rhs 就是 AddRow 时的 lParam
    static int CALLBACK CompareProc(LPARAM lhs, LPARAM rhs, LPARAM self) {
        auto* wnd = reinterpret_cast<CControlsWnd*>(self);
        auto* a = reinterpret_cast<ItemData*>(lhs);
        auto* b = reinterpret_cast<ItemData*>(rhs);
        int cmp = (wnd->m_sortCol == 0) ? a->name.Compare(b->name)
                                        : a->priority - b->priority;
        return wnd->m_sortAsc ? cmp : -cmp;
    }

    static void SetGuiFont(CWnd& wnd) {
        wnd.SendMessage(WM_SETFONT,
                        (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
    }

    enum { IDC_LIST = 201, IDC_NAME = 202, IDC_PRIORITY = 203, IDC_ADD = 204 };
    enum { IDM_MARK_DONE = 3001, IDM_DELETE = 3002 };

    CListCtrl m_list;
    CEdit m_edit;
    CComboBox m_combo;
    CButton m_btnAdd;
    int m_sortCol = 0;
    bool m_sortAsc = true;
};

BEGIN_MESSAGE_MAP(CControlsWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_BN_CLICKED(IDC_ADD, OnClickedAdd)
    ON_NOTIFY(LVN_COLUMNCLICK, IDC_LIST, OnColumnClick)
    ON_WM_CONTEXTMENU()
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CControlsWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
