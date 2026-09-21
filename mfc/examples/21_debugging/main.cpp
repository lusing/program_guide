// 21_debugging：异常体系、断言家族、TRACE 与内存诊断。
//
// 三个按钮各演示一块：
//   断言与 TRACE —— VERIFY 在 release 下仍求值、ASSERT 整个消失；
//                    TRACE 只在 _DEBUG 下输出到调试器
//   异常演示     —— 自定义 CException 派生类 + AfxThrowFileException；
//                    MFC TRY/CATCH 宏（自动清理）vs C++ catch（要自己 Delete）
//   内存诊断     —— _CrtMemCheckpoint 三段式找泄漏（仅 _DEBUG 构建有效）
//
// 本书示例是 release 构建（/MD）：TRACE/ASSERT/内存诊断都会"静默"，
// 想看全效果用调试参数重新构建：
//   cl /D_DEBUG /MDd ...（其余参数同 build.ps1）
//
// 编译运行：.\build.ps1 -File 21_debugging

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>
#include <crtdbg.h>
#include <stdexcept>

// ---------- 1) 自定义异常：继承 CException ----------
class CConfigException : public CException {
    DECLARE_DYNAMIC(CConfigException)
public:
    explicit CConfigException(LPCTSTR what) : m_what(what) {}

    // CException::GetErrorMessage 是虚函数（基类版本只返回 FALSE），
    // 派生类重写它，ReportError 和消息框才有可读文字
    BOOL GetErrorMessage(LPTSTR buf, UINT max, PUINT pHelp = NULL) const override {
        if (!buf || max == 0)
            return FALSE;
        _tcsncpy_s(buf, max, m_what, _TRUNCATE);
        return TRUE;
    }

    CString m_what;
};

IMPLEMENT_DYNAMIC(CConfigException, CException)

// ---------- 主对话框 ----------
class CDebugDlg : public CDialog {
public:
    CDebugDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        m_result.SubclassDlgItem(IDC_RESULT, this);
        m_result.SendMessage(WM_SETFONT,
                             (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return TRUE;
    }

    void AppendLog(LPCTSTR line) {
        m_log += line;
        m_log += _T("\r\n");
        m_result.SetWindowText(m_log);
    }

    // ---------- 2) 断言家族：VERIFY vs ASSERT ----------
    bool CountOne() {
        ++m_calls;
        return true;
    }

    afx_msg void OnTrace() {
        AppendLog(_T("―― 断言家族 ――"));

        // VERIFY：debug 下断言，release 下**仍然求值** ——
        // 调用照常发生，m_calls 照常增加
        VERIFY(CountOne());

        // 如果换成 ASSERT(CountOne())：release 下整个表达式被编译掉，
        // CountOne 根本不会执行 —— 这就是"ASSERT 里不能放有副作用的调用"
        AppendLog(m_calls == 1
            ? _T("VERIFY(CountOne()) 执行了 1 次（release 下仍求值）")
            : _T("VERIFY(CountOne()) 被重复执行"));

#ifdef _DEBUG
        TRACE(_T("TRACE 输出：只在调试器/DebugView 里能看到\n"));
        TRACE1(_T("带参数版本 TRACE%d：m_calls = %d\n"), 1, m_calls);
        AppendLog(_T("TRACE 已输出到调试器（_DEBUG 构建）"));
        ASSERT_VALID(this);   // 调 AssertValid()，检查对象自身一致性
#else
        AppendLog(_T("release 构建：TRACE/ASSERT 都被编译掉了（想看输出用 /D_DEBUG /MDd 重编）"));
#endif
    }

    // ---------- 3) 异常体系 ----------
    afx_msg void OnThrow() {
        AppendLog(_T("―― 异常 ――"));

        // 形式一：MFC TRY/CATCH 宏。CATCH 里记录的异常由
        // AFX_EXCEPTION_LINK 在作用域结束自动 Delete（m_bAutoDelete=TRUE）
        TRY {
            AfxThrowFileException(CFileException::fileNotFound, -1, _T("config.ini"));
        }
        CATCH(CFileException, e) {
            TCHAR buf[256] = _T("");
            e->GetErrorMessage(buf, 256);
            CString s;
            s.Format(_T("MFC 宏捕获 CFileException：%s"), buf);
            AppendLog(s);
        }
        END_CATCH

        // 形式二：C++ try/catch。MFC 异常是 new 出来的堆对象，
        // 没有 AFX_EXCEPTION_LINK 托底 —— 必须自己调 e->Delete()
        try {
            throw new CConfigException(_T("配置文件缺少 [database] 节"));
        } catch (CException* e) {
            TCHAR buf[256] = _T("");
            e->GetErrorMessage(buf, 256);
            CString s;
            s.Format(_T("C++ catch 捕获 CConfigException：%s"), buf);
            AppendLog(s);
            e->Delete();    // 忘了这行 = 每次异常泄漏一个对象
        }

        // 形式三：标准异常不是 CException，catch (CException*) 接不住
        try {
            throw std::runtime_error("std exception, not CException");
        } catch (const std::exception& ex) {
            CString s;
            s.Format(_T("C++ catch 捕获标准异常：%hs"), ex.what());
            AppendLog(s);
        }
    }

    // ---------- 4) 内存诊断：三段式 ----------
    afx_msg void OnMemCheck() {
        AppendLog(_T("―― 内存诊断 ――"));

#ifdef _DEBUG
        _CrtMemState s1, s2, s3;
        _CrtMemCheckpoint(&s1);            // 起点
        int* leak = new int[100];          // 故意泄漏 400 字节（教学演示）
        (void)leak;                        // 不释放 —— 差异里应该看到它
        _CrtMemCheckpoint(&s2);            // 终点

        // 返回非零 = 两点之间有差异
        if (_CrtMemDifference(&s3, &s1, &s2)) {
            _CrtMemDumpStatistics(&s3);    // 输出到调试器
            AppendLog(_T("_DEBUG 构建：检测到内存差异，统计已 dump 到调试器"));
        }
#else
        // release 下 _Crt* 全是空宏（crtdbg.h 里 #define 成 (void)0），
        // 整段三段式什么都不会发生 —— 想看效果用 /D_DEBUG /MDd 重新构建
        AppendLog(_T("release 构建下 _Crt* 是空宏，检测不到任何差异。")
                  _T("用 /D_DEBUG /MDd 重新构建再点这个按钮。"));
#endif
    }

    DECLARE_MESSAGE_MAP()

private:
    CEdit m_result;
    CString m_log;
    int m_calls = 0;
};

BEGIN_MESSAGE_MAP(CDebugDlg, CDialog)
    ON_BN_CLICKED(IDC_TRACE, &CDebugDlg::OnTrace)
    ON_BN_CLICKED(IDC_THROW, &CDebugDlg::OnThrow)
    ON_BN_CLICKED(IDC_MEMCHECK, &CDebugDlg::OnMemCheck)
END_MESSAGE_MAP()

// ---------- 应用 ----------
class CDebugApp : public CWinApp {
public:
    BOOL InitInstance() override {
#ifdef _DEBUG
        // _DEBUG 构建下：进程退出时自动 dump 尚未释放的内存块
        _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

        CDebugDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CDebugApp theApp;
