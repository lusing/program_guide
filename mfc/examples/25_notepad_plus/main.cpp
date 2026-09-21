// main.cpp：记事本+ 的应用层——App、主框架、设置对话框。
//
// 这个项目把前面各章的知识串起来：
//   ch03 消息映射/命令路由   ch04 资源与加速键      ch05 窗口布局
//   ch06 对话框与 DDX        ch07 CListCtrl(stats.cpp)  ch08 文件读写与编码
//   ch09 工具栏/状态栏       ch11 双缓冲与 GDI       ch12 后台线程(stats.cpp)
//
// 编译运行：.\build.ps1 -File 12_notepad_plus
#include "resource.h"
#include "stats.h"
#include <afxwin.h>
#include <afxext.h>
#include <afxcmn.h>
#include <afxdlgs.h>

// ---- 高 DPI：在第一个窗口创建前声明 Per-Monitor V2 感知 ----
// 否则 Windows 会按 96DPI 渲染再整体拉伸，文字发虚。
static void EnableHighDpi() {
    if (HMODULE user32 = ::GetModuleHandleW(L"user32.dll")) {
        using Fn = BOOL(WINAPI*)(HANDLE);
        if (auto fn = reinterpret_cast<Fn>(::GetProcAddress(
                user32, "SetProcessDpiAwarenessContext"))) {
            // DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
            fn(reinterpret_cast<HANDLE>(-4));
        }
    }
}

// ---------- 设置对话框：DDX + DDV ----------
class CSettingsDialog : public CDialog {
public:
    int m_tabSize = 4;     // Tab 宽度
    BOOL m_wrap = TRUE;    // 自动换行

    enum { IDD = IDD_SETTINGS };
    CSettingsDialog(CWnd* parent = nullptr) : CDialog(IDD_SETTINGS, parent) {}

protected:
    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Text(pDX, IDC_TAB_SIZE, m_tabSize);
        DDV_MinMaxInt(pDX, m_tabSize, 1, 32);   // 自动范围校验
        DDX_Check(pDX, IDC_WRAP, m_wrap);
    }
};

// ---------- 主框架 ----------
class CMainFrame : public CFrameWnd {
public:
    CMainFrame() {
        // LoadFrame：一次性加载菜单 + 加速键 + 标题（IDR_MAINFRAME）
        LoadFrame(IDR_MAINFRAME, WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE);
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;

        CreateToolbar();
        CreateStatusBar();

        CreateEditor();

        UpdateTitle();
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (m_edit.GetSafeHwnd()) {
            CRect rect;
            RepositionBars(AFX_IDW_CONTROLBAR_FIRST, AFX_IDW_CONTROLBAR_LAST,
                           0, reposQuery, &rect);
            m_edit.MoveWindow(rect);
        }
    }

    // ---- 文件命令 ----
    afx_msg void OnFileNew() {
        if (!ConfirmDiscard())
            return;
        m_edit.SetWindowText(_T(""));
        m_filePath.Empty();
        m_dirty = false;
        UpdateTitle();
        PushStats();
    }

    afx_msg void OnFileOpen() {
        if (!ConfirmDiscard())
            return;
        CFileDialog dlg(TRUE, _T("txt"), nullptr, OFN_FILEMUSTEXIST,
                        _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"), this);
        if (dlg.DoModal() != IDOK)
            return;
        LoadFile(dlg.GetPathName());
    }

    afx_msg void OnFileSave() {
        if (m_filePath.IsEmpty()) {
            CFileDialog dlg(FALSE, _T("txt"), _T("untitled.txt"),
                            OFN_OVERWRITEPROMPT,
                            _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"),
                            this);
            if (dlg.DoModal() != IDOK)
                return;
            m_filePath = dlg.GetPathName();
        }
        SaveFile(m_filePath);
    }

    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }

    // ---- 最近文件 ----
    afx_msg void OnOpenRecent(UINT id) {
        int index = id - IDM_MRU_1;
        if (index >= 0 && index < m_recentCount &&
            !ConfirmDiscard())
            return;
        if (index >= 0 && index < m_recentCount)
            LoadFile(m_recent[index]);
    }

    afx_msg void OnUpdateRecent(CCmdUI* pCmdUI) {
        int index = pCmdUI->m_nID - IDM_MRU_1;
        if (index < m_recentCount) {
            // 只显示文件名，完整路径放 tooltip
            CString name = m_recent[index].Mid(
                m_recent[index].ReverseFind(_T('\\')) + 1);
            pCmdUI->SetText(name);
            pCmdUI->Enable(TRUE);
        } else {
            pCmdUI->Enable(FALSE);
        }
    }

    // ---- 编辑命令：转发给编辑框 ----
    afx_msg void OnEditUndo()   { m_edit.Undo(); }
    afx_msg void OnEditCut()    { m_edit.Cut(); }
    afx_msg void OnEditCopy()   { m_edit.Copy(); }
    afx_msg void OnEditPaste()  { m_edit.Paste(); }

    afx_msg void OnUpdateEditUndo(CCmdUI* pCmdUI) {
        pCmdUI->Enable(m_edit.CanUndo());
    }

    // ---- 工具 ----
    afx_msg void OnToolsStats() {
        if (m_stats) {
            m_stats->SetForegroundWindow();
        } else {
            m_stats = new CStatsDialog(this);
            if (m_stats->Create(this))
                m_stats->ShowWindow(SW_SHOW);
            else {
                delete m_stats;
                m_stats = nullptr;
            }
        }
        PushStats();
    }

    afx_msg void OnToolsSettings() {
        CSettingsDialog dlg(this);
        dlg.m_tabSize = m_tabSize;
        dlg.m_wrap = m_wrap;
        if (dlg.DoModal() != IDOK)
            return;
        m_tabSize = dlg.m_tabSize;
        m_wrap = dlg.m_wrap;
        ApplySettings();   // 换行样式需要重建编辑框才能生效
    }

    afx_msg void OnHelpAbout() {
        CDialog(IDD_ABOUT, this).DoModal();
    }

    // ---- 内容变化：标脏 + 刷新状态栏 + 推给统计面板 ----
    afx_msg void OnEditChange() {
        m_dirty = true;
        UpdateTitle();
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_STATE),
                                _T("已修改"));
        PushStats();
    }

    afx_msg void OnClose() {
        if (!ConfirmDiscard())
            return;
        CFrameWnd::OnClose();
    }

    // 统计面板销毁时清指针（stats.cpp 的 PostNcDestroy 会发消息过来）
    afx_msg LRESULT OnStatsClosed(WPARAM, LPARAM) {
        m_stats = nullptr;
        return 0;
    }

    DECLARE_MESSAGE_MAP()

private:
    void CreateToolbar() {
        if (!m_toolbar.CreateEx(this, TBSTYLE_FLAT,
                                WS_CHILD | WS_VISIBLE | CBRS_TOP |
                                    CBRS_TOOLTIPS | CBRS_FLYBY))
            return;
        static const UINT ids[] = { IDM_FILE_NEW, IDM_FILE_OPEN,
                                    IDM_FILE_SAVE, ID_SEPARATOR,
                                    IDM_TOOLS_STATS, IDM_TOOLS_SETTINGS };
        if (!m_toolbar.SetButtons(ids, _countof(ids)))
            return;
        if (!m_toolbar.LoadBitmap(IDR_TOOLBAR_BMP))
            return;
        m_toolbar.SetSizes(CSize(54, 42), CSize(16, 15));
    }

    void CreateStatusBar() {
        static UINT indicators[] = { ID_SEPARATOR, ID_INDICATOR_STATE };
        m_statusBar.Create(this);
        m_statusBar.SetIndicators(indicators, _countof(indicators));
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_STATE),
                                _T("就绪"));
    }

    void CreateEditor() {
        m_edit.Create(MakeEditStyle(), CRect(0, 0, 0, 0), this, IDC_EDIT);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        m_edit.SetTabStops(m_tabSize * 4);   // 单位：对话框单位
    }

    DWORD MakeEditStyle() const {
        DWORD style = WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE |
                      ES_AUTOVSCROLL | ES_WANTRETURN;
        if (!m_wrap)
            style |= WS_HSCROLL | ES_AUTOHSCROLL;   // 不换行时给横向滚动
        return style;
    }

    // 自动换行开关要重建控件（窗口样式创建后不可改），这里保存内容重建
    void ApplySettings() {
        if (!m_edit.GetSafeHwnd())
            return;
        CString text;
        m_edit.GetWindowText(text);
        m_edit.DestroyWindow();
        m_edit.Create(MakeEditStyle(), CRect(0, 0, 0, 0), this, IDC_EDIT);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        m_edit.SetTabStops(m_tabSize * 4);
        m_edit.SetWindowText(text);
        CRect rect;
        RepositionBars(AFX_IDW_CONTROLBAR_FIRST, AFX_IDW_CONTROLBAR_LAST,
                       0, reposQuery, &rect);
        m_edit.MoveWindow(rect);
    }

    void UpdateTitle() {
        CString name = _T("未命名");
        if (!m_filePath.IsEmpty())
            name = m_filePath.Mid(m_filePath.ReverseFind(_T('\\')) + 1);
        SetWindowText((m_dirty ? CString(_T("*")) : CString()) + name +
                      _T(" - 记事本+"));
    }

    // 关闭/新建前确认未保存的修改
    bool ConfirmDiscard() {
        if (!m_dirty)
            return true;
        CString msg = _T("当前内容尚未保存，确定丢弃吗？");
        return MessageBox(msg, _T("记事本+"), MB_YESNO | MB_ICONWARNING) == IDYES;
    }

    // ---- 文件 IO：带 BOM 的 UTF-8 读写（同 07 章） ----
    void LoadFile(const CString& path) {
        CFile file;
        if (!file.Open(path, CFile::modeRead | CFile::shareDenyWrite)) {
            MessageBox(_T("无法打开文件：") + path, _T("错误"), MB_ICONERROR);
            return;
        }
        UINT len = (UINT)file.GetLength();
        CByteArray bytes;
        bytes.SetSize(len);
        file.Read(bytes.GetData(), len);
        file.Close();

        UINT codePage = CP_ACP;
        const BYTE* data = bytes.GetData();
        int offset = 0;
        CString content;
        if (len >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
            codePage = CP_UTF8;
            offset = 3;
        } else if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
            content = CString(reinterpret_cast<const wchar_t*>(data + 2),
                              (len - 2) / 2);
        } else if (len > 0) {
            int wlen = MultiByteToWideChar(codePage, 0,
                reinterpret_cast<const char*>(data), len, nullptr, 0);
            MultiByteToWideChar(codePage, 0, reinterpret_cast<const char*>(data),
                                len, content.GetBuffer(wlen), wlen);
            content.ReleaseBuffer(wlen);
        }

        m_edit.SetWindowText(content);
        m_filePath = path;
        m_dirty = false;
        AddRecent(path);
        UpdateTitle();
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_STATE),
                                _T("就绪"));
        PushStats();
    }

    void SaveFile(const CString& path) {
        CString content;
        m_edit.GetWindowText(content);
        CT2A utf8(content, CP_UTF8);
        const BYTE bom[] = { 0xEF, 0xBB, 0xBF };

        CFile file;
        if (!file.Open(path, CFile::modeCreate | CFile::modeWrite |
                                CFile::shareExclusive)) {
            MessageBox(_T("无法保存文件：") + path, _T("错误"), MB_ICONERROR);
            return;
        }
        file.Write(bom, sizeof(bom));
        file.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
        file.Close();

        m_filePath = path;
        m_dirty = false;
        AddRecent(path);
        UpdateTitle();
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_STATE),
                                _T("已保存"));
    }

    // ---- 最近文件列表（内存实现，最多 4 条） ----
    void AddRecent(const CString& path) {
        // 已存在就先移除，再插到最前
        for (int i = 0; i < m_recentCount; ++i) {
            if (m_recent[i].CompareNoCase(path) == 0) {
                for (int j = i; j > 0; --j)
                    m_recent[j] = m_recent[j - 1];
                m_recent[0] = path;
                return;
            }
        }
        for (int i = m_recentCount < 4 ? m_recentCount : 3; i > 0; --i)
            m_recent[i] = m_recent[i - 1];
        m_recent[0] = path;
        if (m_recentCount < 4)
            ++m_recentCount;
    }

    // 给统计面板推一份文本快照
    void PushStats() {
        if (!m_stats)
            return;
        CString text;
        m_edit.GetWindowText(text);
        m_stats->UpdateText(std::make_shared<std::wstring>(text.GetString(),
                                                           text.GetLength()));
    }

    enum { ID_INDICATOR_STATE = 4100 };

    CEdit m_edit;
    CToolBar m_toolbar;
    CStatusBar m_statusBar;
    CStatsDialog* m_stats = nullptr;

    CString m_filePath;
    CString m_recent[4];
    int m_recentCount = 0;
    int m_tabSize = 4;
    bool m_wrap = true;
    bool m_dirty = false;
};

BEGIN_MESSAGE_MAP(CMainFrame, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_WM_CLOSE()
    ON_COMMAND(IDM_FILE_NEW, OnFileNew)
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
    ON_COMMAND_RANGE(IDM_MRU_1, IDM_MRU_4, OnOpenRecent)
    ON_UPDATE_COMMAND_UI_RANGE(IDM_MRU_1, IDM_MRU_4, OnUpdateRecent)
    ON_COMMAND(IDM_EDIT_UNDO, OnEditUndo)
    ON_COMMAND(IDM_EDIT_CUT, OnEditCut)
    ON_COMMAND(IDM_EDIT_COPY, OnEditCopy)
    ON_COMMAND(IDM_EDIT_PASTE, OnEditPaste)
    ON_UPDATE_COMMAND_UI(IDM_EDIT_UNDO, OnUpdateEditUndo)
    ON_COMMAND(IDM_TOOLS_STATS, OnToolsStats)
    ON_COMMAND(IDM_TOOLS_SETTINGS, OnToolsSettings)
    ON_COMMAND(IDM_HELP_ABOUT, OnHelpAbout)
    ON_EN_CHANGE(IDC_EDIT, OnEditChange)
    ON_MESSAGE(WM_APP_STATS_CLOSED, OnStatsClosed)
END_MESSAGE_MAP()

// ---------- 应用 ----------
class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        EnableHighDpi();

        m_pMainWnd = new CMainFrame();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
