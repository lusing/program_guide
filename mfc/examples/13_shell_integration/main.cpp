// 13_shell_integration：文件系统遍历 / 最近文件 / 配置持久化 / 单实例。
//
//   1. CFileFind 递归扫描 —— while (working) { working = FindNextFile(); } 的
//      惯用法，漏掉最后一个文件是 CFileFind 最常见的错误
//   2. CRecentFileList —— 最近文件列表，落在注册表里持久化
//   3. WriteProfileString / GetProfileString —— 配置持久化（注册表 or INI）
//   4. CreateMutex 单实例 —— ERROR_ALREADY_EXISTS 判断
//
// 编译运行：.\build.ps1 -File 13_shell_integration

#include "resource.h"
#include <afxwin.h>
#include <afxdlgs.h>   // CFolderPickerDialog
#include <afxadv.h>    // CRecentFileList

// ------------------------------------------------- 1) CFileFind 递归扫描

static void ScanDir(LPCTSTR root, int& files, ULONGLONG& bytes,
                    CString& biggest, ULONGLONG& biggestLen,
                    CStringArray& out, int depth) {
    // 防御：junction / 符号链接 / 网络重定向可能构成环
    if (depth > 20)
        return;

    CFileFind finder;
    BOOL working = finder.FindFile(CString(root) + _T("\\*"));
    // 惯用法：FindNextFile 返回 FALSE 时，最后一个匹配项仍在 finder 上有效。
    // 先取数据再判断，不能写成 while (finder.FindNextFile())。
    while (working) {
        working = finder.FindNextFile();

        if (finder.IsDots())                       // "." 和 ".."
            continue;

        if (finder.IsDirectory()) {
            ScanDir(finder.GetFilePath(), files, bytes, biggest,
                    biggestLen, out, depth + 1);
            continue;
        }

        ++files;
        const ULONGLONG len = finder.GetLength();  // ULONGLONG，防 4GB 溢出
        bytes += len;
        if (len > biggestLen) {
            biggestLen = len;
            biggest = finder.GetFilePath();
        }
        if (out.GetSize() < 60)                    // 摘要只记前 60 个
            out.Add(finder.GetFilePath());
    }
    // 循环结束，finder 析构会关闭搜索句柄
}

// ------------------------------------------------- 2) 主对话框

class CShellDlg : public CDialog {
public:
    CShellDlg() : CDialog(IDD_MAIN), m_mru(5001, _T("Recent Files"),
                                         _T("File%d"), 8) {}

    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Control(pDX, IDC_RESULT, m_result);
        DDX_Control(pDX, IDC_RECENT, m_recent);
    }

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();

        // 启动时从注册表读回 MRU（ReadList 内部走 AfxGetApp()->GetProfileString）
        m_mru.ReadList();
        FillRecentBox();
        return TRUE;
    }

    afx_msg void OnBrowse() {
        CFolderPickerDialog dlg(m_folder);   // 初始目录
        if (dlg.DoModal() != IDOK)
            return;
        m_folder = dlg.GetPathName();
        SetDlgItemText(IDC_FOLDER, m_folder);
    }

    afx_msg void OnScan() {
        GetDlgItemText(IDC_FOLDER, m_folder);
        if (m_folder.IsEmpty()) {
            SetResult(_T("先填一个目录"));
            return;
        }

        int files = 0;
        ULONGLONG bytes = 0, biggestLen = 0;
        CString biggest;
        CStringArray summary;

        ScanDir(m_folder, files, bytes, biggest, biggestLen, summary, 0);

        CString s;
        s.Format(_T("共 %d 个文件，%.2f MB，最大："),
                 files, static_cast<double>(bytes) / (1024.0 * 1024.0));
        s += biggest;
        if (biggestLen > 0)
            s.AppendFormat(_T("（%.2f MB）"), static_cast<double>(biggestLen) / (1024.0 * 1024.0));
        s += _T("\r\n\r\n前若干个：");
        for (int i = 0; i < summary.GetSize(); ++i) {
            s += _T("\r\n  ");
            s += summary[i];
        }
        SetResult(s);

        // 记住这次扫描的目录，顺手进 MRU（Add 会去重并移到队首）
        if (!m_folder.IsEmpty()) {
            m_mru.Add(m_folder);      // 注意：Add 不会自动持久化
            m_mru.WriteList();        // 必须自己 WriteList 才落注册表
            FillRecentBox();
        }
    }

    afx_msg void OnSaveCfg() {
        CWinApp* app = AfxGetApp();
        app->WriteProfileString(_T("ShellDemo"), _T("LastFolder"), m_folder);
        app->WriteProfileInt(_T("ShellDemo"), _T("ScanCount"), m_scanCount);
        SetResult(_T("已写入配置（HKCU\\Software\\GuideTutorials\\ShellIntegration）"));
    }

    afx_msg void OnLoadCfg() {
        CWinApp* app = AfxGetApp();
        m_folder = app->GetProfileString(_T("ShellDemo"), _T("LastFolder"), _T(""));
        m_scanCount = app->GetProfileInt(_T("ShellDemo"), _T("ScanCount"), 0);
        SetDlgItemText(IDC_FOLDER, m_folder);

        CString s;
        s.Format(_T("载入配置：LastFolder=%s，ScanCount=%d"),
                 m_folder.IsEmpty() ? _T("（空）") : m_folder.GetString(),
                 m_scanCount);
        SetResult(s);
    }

    afx_msg void OnRecentDblClick() {
        const int sel = m_recent.GetCurSel();
        if (sel == LB_ERR)
            return;
        // 简单演示：弹一下路径。真实项目里这里走打开文件的流程
        CString name;
        m_recent.GetText(sel, name);
        AfxMessageBox(name, MB_ICONINFORMATION);
    }

    DECLARE_MESSAGE_MAP()

private:
    void FillRecentBox() {
        m_recent.ResetContent();
        for (int i = 0; i < m_mru.GetSize(); ++i) {
            CString name;
            // GetDisplayName 第 3/4 参传 NULL 会直接返回 FALSE，
            // 不做同目录缩写就传空串和 0
            if (m_mru.GetDisplayName(name, i, _T(""), 0) && !name.IsEmpty())
                m_recent.AddString(name);
        }
    }
    void SetResult(const CString& s) { SetDlgItemText(IDC_RESULT, s); }

    CString      m_folder;
    CEdit        m_result;
    CListBox     m_recent;
    int          m_scanCount = 0;
    CRecentFileList m_mru;   // nStart=5001, 节="Recent Files", 条目格式="File%d", 条数=8
};

BEGIN_MESSAGE_MAP(CShellDlg, CDialog)
    ON_BN_CLICKED(IDC_BROWSE, &CShellDlg::OnBrowse)
    ON_BN_CLICKED(IDC_SCAN, &CShellDlg::OnScan)
    ON_BN_CLICKED(IDC_SAVE_CFG, &CShellDlg::OnSaveCfg)
    ON_BN_CLICKED(IDC_LOAD_CFG, &CShellDlg::OnLoadCfg)
    ON_LBN_DBLCLK(IDC_RECENT, &CShellDlg::OnRecentDblClick)
END_MESSAGE_MAP()

// ------------------------------------------------- 应用

class CShellApp : public CWinApp {
public:
    // 显式给应用名，注册表路径就确定下来了：
    // HKCU\Software\GuideTutorials\ShellIntegration\<Section>
    CShellApp() : CWinApp(_T("ShellIntegration")) {}

    BOOL InitInstance() override {
        // ① 单实例：命名互斥体。CreateMutex 失败/已存在时 GetLastError 会区分
        HANDLE hMutex = ::CreateMutex(nullptr, FALSE, _T("Guide.Mfc.ShellIntegration"));
        if (hMutex == nullptr)
            return FALSE;   // 罕见：权限问题等

        if (::GetLastError() == ERROR_ALREADY_EXISTS) {
            // 互斥体已存在 —— 已经有一个实例在跑。hMutex 用完即关即可。
            ::CloseHandle(hMutex);
            AfxMessageBox(_T("程序已经在运行了。"), MB_ICONINFORMATION);
            return FALSE;
        }
        // 注意：不要 CloseHandle(hMutex) —— 它要撑到进程结束才能挡住第二个实例。
        // 进程退出时操作系统会自动回收，这里刻意"泄漏"是标准做法。

        // ② 配置走注册表：必须在第一次 WriteProfile*/GetProfile* 之前调用。
        //    不调用的话，Profile 系列函数会退回 exe 同目录的 .ini 文件。
        SetRegistryKey(_T("GuideTutorials"));

        CShellDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CShellApp theApp;
