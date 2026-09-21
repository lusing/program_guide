// 10_common_dialogs：通用对话框 + 文件读写。
//
// 演示：
//   1. CFileDialog 打开/保存：过滤器写法、OFN_OVERWRITEPROMPT
//   2. CColorDialog 选颜色
//   3. CFile 二进制读写 + BOM 编码识别 —— 比 CStdioFile 更可控的文本 IO
//      （CStdioFile 在 Unicode 工程里按 ANSI 读中文，遇到 UTF-8 文件会乱码，
//       这里演示自己转码的规范做法）
//   4. OnCtlColor 改编辑框文字颜色
//
// 编译运行：.\build.ps1 -File 10_common_dialogs

#include "resource.h"
#include <afxwin.h>
#include <afxdlgs.h>   // CFileDialog / CColorDialog 等通用对话框

class CEditorWnd : public CFrameWnd {
public:
    CEditorWnd() {
        Create(NULL, _T("迷你文本编辑器"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 720, 500), nullptr,
               MAKEINTRESOURCE(IDR_MAIN_MENU));

        // 菜单项文本里写了 "Ctrl+O" 就得真有这张表，否则用户按下去没反应
        // （菜单里的 &O 只是助记符，展开菜单时才有用）。第 11 章详述。
        LoadAccelTable(_T("IDR_MAIN_MENU"));
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;
        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL |
                          ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL,
                      CRect(0, 0, 0, 0), this, IDC_EDIT);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (m_edit.GetSafeHwnd())
            m_edit.MoveWindow(0, 0, cx, cy);
    }

    afx_msg void OnFileOpen() {
        CFileDialog dlg(TRUE,             // TRUE = 打开对话框
                        _T("txt"),        // 默认扩展名
                        nullptr,
                        OFN_FILEMUSTEXIST | OFN_HIDEREADONLY,
                        // 过滤器：两段一组，“显示文本\0模式\0”，用 | 结尾
                        _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"),
                        this);
        if (dlg.DoModal() != IDOK)
            return;

        CString content;
        if (ReadTextFile(dlg.GetPathName(), content)) {
            m_edit.SetWindowText(content);
            m_filePath = dlg.GetPathName();
            SetTitleFromPath();
        }
    }

    afx_msg void OnFileSave() {
        // 没打开过文件就先要一个路径
        if (m_filePath.IsEmpty()) {
            CFileDialog dlg(FALSE, _T("txt"), _T("untitled.txt"),
                            OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST,
                            _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"),
                            this);
            if (dlg.DoModal() != IDOK)
                return;
            m_filePath = dlg.GetPathName();
        }

        CString content;
        m_edit.GetWindowText(content);
        if (WriteTextFile(m_filePath, content)) {
            SetTitleFromPath();
            MessageBox(_T("已保存（UTF-8 带 BOM）"), _T("完成"),
                       MB_OK | MB_ICONINFORMATION);
        }
    }

    afx_msg void OnFmtColor() {
        CColorDialog dlg(m_textColor);   // 传入当前颜色作为初始值
        if (dlg.DoModal() != IDOK)
            return;
        m_textColor = dlg.GetColor();
        m_edit.Invalidate();             // 触发 OnCtlColor 重刷颜色
    }

    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }

    // 编辑框要改文字颜色，必须在这里拦：控件自绘颜色的统一挂点
    afx_msg HBRUSH OnCtlColor(CDC* pDC, CWnd* pWnd, UINT nCtlColor) {
        HBRUSH hbr = CFrameWnd::OnCtlColor(pDC, pWnd, nCtlColor);
        if (pWnd->GetSafeHwnd() == m_edit.GetSafeHwnd()) {
            pDC->SetTextColor(m_textColor);
        }
        return hbr;
    }

    DECLARE_MESSAGE_MAP()

private:
    void SetTitleFromPath() {
        // CFileDialog::GetPathName 给的是全路径，标题只显示文件名
        SetWindowText(_T("迷你文本编辑器 - ") +
                      m_filePath.Mid(m_filePath.ReverseFind(_T('\\')) + 1));
    }

    // 读文本：二进制读入 -> 看 BOM 决定编码 -> 转成 UTF-16 的 CString
    static BOOL ReadTextFile(const CString& path, CString& content) {
        CFile file;
        if (!file.Open(path, CFile::modeRead | CFile::shareDenyWrite))
            return FALSE;

        const UINT len = (UINT)file.GetLength();
        CByteArray bytes;
        bytes.SetSize(len);
        file.Read(bytes.GetData(), len);
        file.Close();

        // BOM 判断：EF BB BF = UTF-8，FF FE = UTF-16LE，否则按 ANSI（GBK）
        UINT codePage = CP_ACP;
        const BYTE* data = bytes.GetData();
        int offset = 0;
        if (len >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
            codePage = CP_UTF8;
            offset = 3;
        } else if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
            content = CString(reinterpret_cast<const wchar_t*>(data + 2),
                              (len - 2) / 2);
            return TRUE;
        }

        int wlen = MultiByteToWideChar(codePage, 0,
                                       reinterpret_cast<const char*>(data + offset),
                                       len - offset, nullptr, 0);
        if (wlen <= 0)
            return FALSE;
        MultiByteToWideChar(codePage, 0,
                            reinterpret_cast<const char*>(data + offset),
                            len - offset, content.GetBuffer(wlen), wlen);
        content.ReleaseBuffer(wlen);
        return TRUE;
    }

    // 写文本：统一 UTF-8 + BOM，记事本等工具都能正确识别
    static BOOL WriteTextFile(const CString& path, const CString& content) {
        CT2A utf8(content, CP_UTF8);   // ATL 转换宏：CString -> UTF-8 窄串
        const BYTE bom[] = { 0xEF, 0xBB, 0xBF };

        CFile file;
        if (!file.Open(path, CFile::modeCreate | CFile::modeWrite |
                                CFile::shareExclusive))
            return FALSE;
        file.Write(bom, sizeof(bom));
        file.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
        file.Close();
        return TRUE;
    }

    enum { IDC_EDIT = 101 };

    CEdit m_edit;
    CString m_filePath;
    COLORREF m_textColor = RGB(30, 30, 30);
};

BEGIN_MESSAGE_MAP(CEditorWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_WM_CTLCOLOR()
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_FMT_COLOR, OnFmtColor)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CEditorWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
