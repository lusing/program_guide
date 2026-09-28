// 33_dll：动态链接库的三种形态 —— 普通 Win32 DLL、MFC 扩展 DLL、资源专用 DLL。
//
// 演示：
//   1. 隐式链接：exe 链接 mathlib.lib，像调本地函数一样调 Add/Multiply
//   2. 显式链接：LoadLibrary + GetProcAddress，运行时才决定加载谁（插件式）
//   3. MFC 扩展 DLL：AFX_EXT_CLASS 导出 CShape 族，exe 里直接 new/绘制/delete
//   4. 按名动态创建：CRuntimeClass::CreateObject 跨 DLL 找到 CEllipseShape ——
//      AfxInitExtensionModule + CDynLinkLibrary 把 DLL 的类表并进了应用
//   5. 资源专用 DLL：LoadLibrary 后用模块句柄 LoadString，双语文案外置
//
// 书1 第15 章 例82-85 的现代版（x64 + 动态链接 MFC）
// 编译运行：.\build.ps1 -File 33_dll

#include "resource.h"
#include "shape.h"       // 扩展 DLL 的共享声明（本侧 AFX_EXT_CLASS = dllimport）
#include <afxwin.h>
#include <memory>

// mathlib.dll 的 C 接口（隐式链接：build.ps1 自动附加了 mathlib.lib）
extern "C" __declspec(dllimport) int   Add(int a, int b);
extern "C" __declspec(dllimport) int   Multiply(int a, int b);
extern "C" __declspec(dllimport) void  GetGreeting(wchar_t* buf, int cch);
extern "C" __declspec(dllimport) wchar_t* AllocReport(int value);
extern "C" __declspec(dllimport) void  ExportFree(void* p);

// 画布：让扩展 DLL 导出的类有地方画（第 09 章的自绘套路）
class CShapeCanvas : public CWnd {
    DECLARE_MESSAGE_MAP()
public:
    BOOL Create(CWnd* parent, UINT id) {
        return CWnd::Create(nullptr, nullptr, WS_CHILD | WS_VISIBLE | WS_BORDER,
                            CRect(0, 0, 0, 0), parent, id);
    }
    void SetShape(std::unique_ptr<CShape>&& s) {
        m_shape = std::move(s);
        Invalidate();
    }
private:
    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(rc);
        if (m_shape) {
            CRect shapeRc = rc;
            shapeRc.DeflateRect(24, 24);
            m_shape->Draw(&dc, shapeRc);      // 扩展 DLL 里的代码在本进程画图
        } else {
            dc.FillSolidRect(rc, GetSysColor(COLOR_APPWORKSPACE));
        }
    }
    std::unique_ptr<CShape> m_shape;
};

BEGIN_MESSAGE_MAP(CShapeCanvas, CWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

class CDllDemoDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CDllDemoDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();
        m_canvas.SubclassDlgItem(IDC_CANVAS, this);
        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        Append(_T("就绪。DLL 与本程序同目录（build\\33_dll 依赖同目录的 *.dll）。\r\n"));
        return TRUE;
    }

    // —— 1. 隐式链接：进程启动时加载器自动映射 mathlib.dll，符号在链接期已解析
    void OnImplicit() {
        CString msg;
        msg.Format(_T("Add(123,456)=%d  Multiply(37,73)=%d\r\n"), Add(123, 456), Multiply(37, 73));
        wchar_t buf[128] = {};
        GetGreeting(buf, 128);
        msg += CString(buf) + _T("\r\n");
        wchar_t* rep = AllocReport(0x2A);     // DLL 的堆分配
        if (rep) {
            msg += CString(rep) + _T("\r\n");
            ExportFree(rep);                  // 配套的释放：谁分配谁释放
        }
        Append(_T("[隐式链接]\r\n") + msg);
    }

    // —— 2. 显式链接：LoadLibrary/GetProcAddress。插件、热更新、可选功能的标准做法
    typedef int (*MultiplyFn)(int, int);
    void OnExplicit() {
        // 不写死路径：先试 exe 同目录，失败再给提示
        HMODULE h = ::LoadLibraryW(L"plain.dll");   // 故意用错名演示失败路径
        if (!h) {
            DWORD err = ::GetLastError();
            CString msg;
            msg.Format(_T("LoadLibrary(\"plain.dll\") 失败（GetLastError=%lu）\r\n"
                          "—— 找不到模块是显式加载最常见的错，检查文件名与工作目录\r\n"), err);
            Append(_T("[显式链接]\r\n") + msg);
            h = ::LoadLibraryW(L"mathlib.dll");
            if (!h) { Append(_T("mathlib.dll 也加载失败，中止\r\n")); return; }
        }
        MultiplyFn fn = (MultiplyFn)::GetProcAddress(h, "Multiply");
        if (fn) {
            CString msg;
            msg.Format(_T("GetProcAddress(\"Multiply\")(7,6)=%d\r\n"), fn(7, 6));
            Append(msg);
        }
        // 用完就放：引用计数归零才真正卸载（隐式链接持有的一份还在，不会卸载）
        ::FreeLibrary(h);
        Append(_T("[显式链接] FreeLibrary 完成\r\n"));
    }

    // —— 3. 扩展 DLL 导出的 MFC 类：直接构造、调用、归还 —— 与本地类无差别
    void OnExtClass() {
        auto rect = std::make_unique<CRectShape>(RGB(64, 145, 108));
        Append(_T("[扩展 DLL 类] ") + rect->Describe() + _T("\r\n"));
        m_canvas.SetShape(std::move(rect));
    }

    // —— 4. 按名动态创建：不 include 任何头也能造对象（纯字符串耦合）
    //    CRuntimeClass::CreateObject(LPCSTR) 静态重载会顺着应用类表找名字，
    //    扩展 DLL 的类已在 DllMain 里用 CDynLinkLibrary 并进了这张表
    void OnRuntimeClass() {
        CObject* obj = CRuntimeClass::CreateObject(_T("CEllipseShape"));
        if (obj) {
            CEllipseShape* ell = static_cast<CEllipseShape*>(obj);
            Append(_T("[按名创建] ") + ell->Describe() + _T("\r\n"));
            m_canvas.SetShape(std::unique_ptr<CShape>(ell));
        } else {
            Append(_T("[按名创建] 失败：类表没并上？检查 CDynLinkLibrary 那步\r\n"));
        }
    }

    // —— 5/6. 资源专用 DLL：代码在 exe，文案在 DLL —— 换语言不发新 exe
    void OnResource() {
        if (!m_hResDll) {
            m_hResDll = ::LoadLibraryW(L"strings.dll");
            if (!m_hResDll) {
                Append(_T("[资源 DLL] LoadLibrary 失败（应与 exe 同目录）\r\n"));
                return;
            }
            Append(_T("[资源 DLL] 已加载 strings.dll\r\n"));
        }
        ShowResourceString();
    }

    void OnLangToggle() {
        m_english = !m_english;
        if (m_hResDll) ShowResourceString();
        else Append(_T("先点“加载资源 DLL”\r\n"));
    }

    void ShowResourceString() {
        // 注意第一个参数是模块句柄而不是 nullptr（nullptr = exe 自己的资源）
        wchar_t buf[256] = {};
        UINT id = m_english ? 200 : 100;
        int n = ::LoadStringW(m_hResDll, id, buf, 128);
        CString msg(buf, n < 0 ? 0 : n);
        Append(CString(_T("[资源 DLL] ID ")) + (m_english ? _T("200") : _T("100")) +
               _T(": ") + msg + _T("\r\n"));
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    BOOL DestroyWindow() override {
        if (m_hResDll) { ::FreeLibrary(m_hResDll); m_hResDll = nullptr; }
        return CDialog::DestroyWindow();
    }

    CShapeCanvas m_canvas;
    CEdit        m_log;
    HMODULE      m_hResDll = nullptr;
    bool         m_english = false;
};

BEGIN_MESSAGE_MAP(CDllDemoDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_IMPLICIT, OnImplicit)
    ON_BN_CLICKED(IDC_BTN_EXPLICIT, OnExplicit)
    ON_BN_CLICKED(IDC_BTN_EXTCLASS, OnExtClass)
    ON_BN_CLICKED(IDC_BTN_RUNTIMECLASS, OnRuntimeClass)
    ON_BN_CLICKED(IDC_BTN_RESOURCE, OnResource)
    ON_BN_CLICKED(IDC_BTN_LANG_TOGGLE, OnLangToggle)
END_MESSAGE_MAP()

class CDllApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CDllDemoDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CDllApp theApp;
