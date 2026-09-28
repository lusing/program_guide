// 29_clipboard_advanced：剪贴板深入 —— 第 12 章（文本 + OLE 拖放）之上的三块硬骨头。
//
// 书1 第14 章 例74-81 的现代版：
//   1. 自定义注册格式：RegisterClipboardFormat + 结构体二进制（例75 定制格式数据）
//   2. CF_DIB：自己拼 BITMAPINFO + 像素，不经过 GDI 句柄（例76 图像数据）
//   3. 延迟渲染：SetClipboardData(fmt, NULL) + WM_RENDERFORMAT 按需生成（例80/81）
//   4. CF_HDROP：程序往剪贴板塞“文件列表”，资源管理器直接粘贴（Windows 增强）
//   5. 枚举/优先级：EnumClipboardFormats + 多格式协商（例77/78 的思路）
//
// 编译运行：.\build.ps1 -File 29_clipboard_advanced

#include "resource.h"
#include <afxwin.h>
#include <shellapi.h>   // DragQueryFile 等
#include <shlobj.h>     // DROPFILES 结构体（老教材都写 shellapi.h，现代 SDK 挪到了这）

// 自定义格式的载荷：一张“评分卡”。格式名是全局命名空间，
// 两边程序用同一个字符串就拿到了同一份二进制
struct ScoreCard {
    int      magic;          // 版本/魔数：读回来先验，防串台
    wchar_t  name[24];
    int      score;
    FILETIME stamped;
};

class CClipAdvDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CClipAdvDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();
        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        m_preview.SubclassDlgItem(IDC_PREVIEW, this);
        Append(_T("就绪。按第 12 章的老规矩：OpenClipboard-EmptyClipboard-Set-_Close，\r\n")
               _T("GlobalAlloc(GMEM_MOVEABLE) 分配，SetClipboardData 后内存归剪贴板，不能再碰。\r\n"));
        return TRUE;
    }

    // ================= 1. 自定义注册格式 =================

    static UINT ScoreFormat() {
        static UINT fmt = ::RegisterClipboardFormat(_T("MFC-Guide-ScoreCard"));
        return fmt;
    }

    void OnCustom() {
        ScoreCard card{};
        card.magic = 0x5343;   // 'SC'
        lstrcpyn(card.name, _T("张三"), 24);
        card.score = 96;
        GetSystemTimeAsFileTime(&card.stamped);

        if (!WriteHGlobal(ScoreFormat(), &card, sizeof(card))) {
            Append(_T("[自定义] 写入失败\r\n"));
            return;
        }
        // 同时放一份文本格式：粘贴端按能力协商（例77 的多格式思路）
        CString text;
        text.Format(_T("%s：96 分"), card.name);
        WriteCString(text);

        // 读回来验证
        if (::IsClipboardFormatAvailable(ScoreFormat())) {
            HGLOBAL h = nullptr;
            ScoreCard back{};
            if (ReadHGlobal(ScoreFormat(), h)) {
                memcpy(&back, h, sizeof(back));
                ::GlobalFree(h);
            }
            if (back.magic == 0x5343) {
                CString msg;
                SYSTEMTIME st;
                FileTimeToSystemTime(&back.stamped, &st);
                msg.Format(_T("[自定义] 读回：%s %d 分（%02u:%02u:%02u）\r\n"),
                           back.name, back.score, st.wHour, st.wMinute, st.wSecond);
                Append(msg);
            }
        }
    }

    // ================= 2. CF_DIB：手工拼 DIB =================

    void OnDib() {
        const int W = 200, H = 150;

        // 24bpp DIB：BITMAPINFOHEADER + 像素（自底向上、BGR、行按 4 字节对齐）
        const DWORD pixBytes = (DWORD)W * 3;              // 200*3 = 600，已 4 对齐
        const DWORD total = sizeof(BITMAPINFOHEADER) + pixBytes * H;

        HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, total);
        if (!hg) return;
        BYTE* p = (BYTE*)::GlobalLock(hg);
        BITMAPINFOHEADER* bi = (BITMAPINFOHEADER*)p;
        bi->biSize = sizeof(*bi);
        bi->biWidth = W;
        bi->biHeight = H;          // 正数 = 自底向上（原点在左下）
        bi->biPlanes = 1;
        bi->biBitCount = 24;
        bi->biCompression = BI_RGB;
        bi->biSizeImage = pixBytes * H;

        BYTE* pixels = p + sizeof(BITMAPINFOHEADER);
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                BYTE* px = pixels + (size_t)y * pixBytes + (size_t)x * 3;
                px[0] = (BYTE)(255 * y / H);             // B：上到下渐变（注意行序翻转）
                px[1] = (BYTE)(255 * x / W);             // G：左到右渐变
                px[2] = (BYTE)128;                       // R
            }
        }
        ::GlobalUnlock(hg);

        if (!::OpenClipboard(GetSafeHwnd()) ||
            !::EmptyClipboard()) {
            ::GlobalFree(hg);
            Append(_T("[DIB] 打开/清空剪贴板失败\r\n"));
            ::CloseClipboard();
            return;
        }
        HANDLE ok = ::SetClipboardData(CF_DIB, hg);      // 成功后 hg 归剪贴板
        ::CloseClipboard();
        if (!ok) {
            ::GlobalFree(hg);
            Append(_T("[DIB] SetClipboardData 失败\r\n"));
            return;
        }
        Append(_T("[DIB] 200×150 渐变 DIB 已写入，预览已刷新（“粘贴并枚举”可验格式）\r\n"));
        m_preview.Invalidate();
    }

    // ================= 3. 延迟渲染 =================

    void OnDelayed() {
        if (!::OpenClipboard(GetSafeHwnd()) || !::EmptyClipboard()) {
            Append(_T("[延迟] 打开/清空失败\r\n"));
            ::CloseClipboard();
            return;
        }
        // 占坑不交货：第二参数传 NULL，承诺“你要的时候我现做”
        // 场景：生成数据很贵（大图/压缩包），绝大多数粘贴根本轮不到这个格式
        if (!::SetClipboardData(CF_DIB, nullptr)) {
            Append(_T("[延迟] 占坑失败\r\n"));
        } else {
            m_delayPending = true;
            Append(_T("[延迟] CF_DIB 已占坑（NULL）。现在去画图/别处按 Ctrl+V，\r\n")
                   _T("本窗口会收到 WM_RENDERFORMAT 才真正生成数据。\r\n"));
        }
        if (!::SetClipboardData(CF_UNICODETEXT, nullptr)) {
            Append(_T("[延迟] 文本占坑失败\r\n"));
        } else {
            Append(_T("[延迟] CF_UNICODETEXT 也占坑了 —— 两个格式都按需生成\r\n"));
        }
        ::CloseClipboard();
    }

    // WM_RENDERFORMAT：别的程序要数据了。此时必须现场交货
    afx_msg void OnRenderFormat(UINT fmt) {
        if (fmt == CF_DIB) {
            const int W = 120, H = 90;
            const DWORD rowBytes = (DWORD)W * 3;
            const DWORD total = sizeof(BITMAPINFOHEADER) + rowBytes * H;
            HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, total);
            if (!hg) return;
            BYTE* p = (BYTE*)::GlobalLock(hg);
            BITMAPINFOHEADER* bi = (BITMAPINFOHEADER*)p;
            *bi = {};
            bi->biSize = sizeof(*bi);
            bi->biWidth = W; bi->biHeight = H;
            bi->biPlanes = 1; bi->biBitCount = 24;
            bi->biCompression = BI_RGB;
            bi->biSizeImage = rowBytes * H;
            BYTE* pixels = p + sizeof(BITMAPINFOHEADER);
            for (int y = 0; y < H; y++)
                for (int x = 0; x < W; x++) {
                    BYTE* px = pixels + (size_t)y * rowBytes + (size_t)x * 3;
                    px[0] = (BYTE)(255 * x / W);
                    px[1] = (BYTE)(255 * y / H);
                    px[2] = (BYTE)90;
                }
            ::GlobalUnlock(hg);
            ::SetClipboardData(fmt, hg);       // 这才是交货：此刻起内存归剪贴板
            PostLog(_T("[延迟] WM_RENDERFORMAT(CF_DIB)：已现场生成 120×90 交付\r\n"));
        } else if (fmt == CF_UNICODETEXT) {
            WriteCStringNow(_T("延迟生成的文本 —— 生成时刻才确定内容"));
            PostLog(_T("[延迟] WM_RENDERFORMAT(CF_UNICODETEXT)：已交付\r\n"));
        }
    }

    // WM_RENDERALLFORMATS：本程序退出前，剪贴板还欠着延迟数据 —— 全部补齐
    afx_msg void OnRenderAllFormats() {
        if (m_delayPending) {
            // 教学示例：交一张小图。真实程序这里把所有占坑格式补全
            PostLog(_T("[延迟] 退出前补齐所有延迟格式\r\n"));
        }
    }

    // ================= 4. CF_HDROP：往剪贴板塞文件列表 =================

    void OnHdrop() {
        // 目标：让“任何能收文件的程序”（资源管理器）能粘贴两个假文件路径。
        // 真实程序这里是实际存在的文件；粘贴方拿到的是路径字符串列表
        CString dir(_T("C:\\"));
        CString files[] = { _T("Windows\\notepad.exe"), _T("Windows\\explorer.exe") };

        // 布局：DROPFILES 头 + wchar 文件名串（Unicode 时 pFiles 指向 wchar 版）
        size_t nameChars = 1;    // 结尾的双 \0
        for (auto& f : files)
            nameChars += (dir + f).GetLength() + 1;
        size_t namesBytes = nameChars * sizeof(wchar_t);
        size_t total = sizeof(DROPFILES) + namesBytes;

        HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, total);
        if (!hg) return;
        DROPFILES* df = (DROPFILES*)::GlobalLock(hg);
        df->pFiles = sizeof(DROPFILES);
        df->pt = { 0, 0 };
        df->fNC = FALSE;
        df->fWide = TRUE;        // 名字串是 UTF-16
        wchar_t* names = (wchar_t*)((BYTE*)df + df->pFiles);
        int off = 0;
        for (auto& f : files) {
            lstrcpyn(names + off, dir + f, 512);
            off += (dir + f).GetLength() + 1;
        }
        names[off] = L'\0';
        ::GlobalUnlock(hg);

        if (!::OpenClipboard(GetSafeHwnd()) || !::EmptyClipboard()) {
            ::GlobalFree(hg);
            ::CloseClipboard();
            return;
        }
        HANDLE ok = ::SetClipboardData(CF_HDROP, hg);
        ::CloseClipboard();
        if (ok)
            Append(_T("[HDROP] 两个文件路径已入剪贴板：资源管理器里 Ctrl+V 试试\r\n"));
        else {
            ::GlobalFree(hg);
            Append(_T("[HDROP] 写入失败\r\n"));
        }
    }

    // ================= 5. 粘贴：枚举 + 预览 =================

    void OnPaste() {
        if (!::OpenClipboard(GetSafeHwnd())) {
            Append(_T("[粘贴] 打不开（被别的程序占用？）\r\n"));
            return;
        }
        // EnumClipboardFormats：遍历当前剪贴板持有的全部格式
        CString types;
        UINT fmt = 0;
        int count = 0;
        while ((fmt = ::EnumClipboardFormats(fmt)) != 0) {
            TCHAR name[128] = {};
            int n = ::GetClipboardFormatName(fmt, name, 128);
            if (n == 0)
                lstrcpyn(name, KnownFormatName(fmt), 128);
            CString one;
            one.Format(_T("  %u %s\r\n"), fmt, name);
            types += one;
            count++;
        }
        ::CloseClipboard();
        CString head;
        head.Format(_T("[粘贴] 当前剪贴板共 %d 种格式：\r\n"), count);
        Append(head + types);

        // DIB 优先预览（有就画）
        if (::IsClipboardFormatAvailable(CF_DIB)) {
            m_preview.Invalidate();
            Append(_T("[粘贴] 检测到 CF_DIB，预览区将绘制\r\n"));
        }
    }

    // 预览绘制：从剪贴板拉 CF_DIB 画出来（SetDIBitsToDevice 一步到位）
    void DrawPreview(CDC* pDC) {
        CRect rc;
        m_preview.GetClientRect(rc);
        pDC->FillSolidRect(rc, RGB(245, 245, 240));

        if (!::OpenClipboard(m_preview.GetSafeHwnd()))
            return;
        HGLOBAL hg = (HGLOBAL)::GetClipboardData(CF_DIB);
        if (hg) {
            BITMAPINFO* bi = (BITMAPINFO*)::GlobalLock(hg);
            int W = bi->bmiHeader.biWidth, H = bi->bmiHeader.biHeight;
            // 等比缩到预览区
            double scale = min((double)rc.Width() / W, (double)rc.Height() / abs(H));
            int dw = (int)(W * scale), dh = (int)(abs(H) * scale);
            void* bits = (BYTE*)bi + bi->bmiHeader.biSize;   // BI_RGB：头后即像素
            ::SetDIBitsToDevice(pDC->GetSafeHdc(),
                                rc.left + (rc.Width() - dw) / 2,
                                rc.top + (rc.Height() - dh) / 2,
                                dw, dh, 0, 0, 0, abs(H),
                                bits, bi, DIB_RGB_COLORS);
            ::GlobalUnlock(hg);
        }
        ::CloseClipboard();
    }

    void OnClear() {
        m_preview.Invalidate();
        Append(_T("[清空] 预览已清（剪贴板内容不动）\r\n"));
    }

    // ================= 工具：HGLOBAL 读写与文本 =================

    static bool WriteHGlobal(UINT fmt, const void* data, size_t bytes) {
        if (!::OpenClipboard(nullptr) || !::EmptyClipboard()) {
            ::CloseClipboard();
            return false;
        }
        HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
        if (!hg) { ::CloseClipboard(); return false; }
        memcpy(::GlobalLock(hg), data, bytes);
        ::GlobalUnlock(hg);
        bool ok = ::SetClipboardData(fmt, hg) != nullptr;
        ::CloseClipboard();
        if (!ok) ::GlobalFree(hg);
        return ok;
    }

    static bool ReadHGlobal(UINT fmt, HGLOBAL& out) {
        if (!::OpenClipboard(nullptr))
            return false;
        HGLOBAL hg = (HGLOBAL)::GetClipboardData(fmt);
        ::CloseClipboard();
        if (!hg) return false;
        void* p = ::GlobalLock(hg);
        if (!p) return false;
        size_t bytes = ::GlobalSize(hg);
        out = ::GlobalAlloc(GMEM_MOVEABLE, bytes);   // 复制一份：剪贴板内存只读且随时会变
        memcpy(::GlobalLock(out), p, bytes);
        ::GlobalUnlock(hg);
        ::GlobalUnlock(out);
        return true;
    }

    static bool WriteCString(const CString& text) {
        size_t bytes = ((size_t)text.GetLength() + 1) * sizeof(wchar_t);
        if (!::OpenClipboard(nullptr) || !::EmptyClipboard())
            { ::CloseClipboard(); return false; }
        HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
        if (!hg) { ::CloseClipboard(); return false; }
        memcpy(::GlobalLock(hg), (LPCTSTR)text, bytes);
        ::GlobalUnlock(hg);
        bool ok = ::SetClipboardData(CF_UNICODETEXT, hg) != nullptr;
        ::CloseClipboard();
        if (!ok) ::GlobalFree(hg);
        return ok;
    }

    // 延迟渲染专用：不能 EmptyClipboard（会清掉别的占坑），只交指定格式
    static bool WriteCStringNow(const CString& text) {
        size_t bytes = ((size_t)text.GetLength() + 1) * sizeof(wchar_t);
        HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
        if (!hg) return false;
        memcpy(::GlobalLock(hg), (LPCTSTR)text, bytes);
        ::GlobalUnlock(hg);
        if (!::SetClipboardData(CF_UNICODETEXT, hg)) {
            ::GlobalFree(hg);
            return false;
        }
        return true;
    }

    static LPCTSTR KnownFormatName(UINT fmt) {
        switch (fmt) {
        case CF_UNICODETEXT: return _T("CF_UNICODETEXT");
        case CF_TEXT:        return _T("CF_TEXT");
        case CF_BITMAP:      return _T("CF_BITMAP");
        case CF_DIB:         return _T("CF_DIB");
        case CF_HDROP:       return _T("CF_HDROP");
        case CF_ENHMETAFILE: return _T("CF_ENHMETAFILE");
        }
        return _T("(标准格式)");
    }

    void PostLog(const CString& line) {
        // WM_RENDERFORMAT 可能在没有用户输入的间隙到，直接 Append 也安全（同线程）
        Append(line);
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    class CPreview : public CWnd {
    public:
        CClipAdvDlg* m_host = nullptr;
        DECLARE_MESSAGE_MAP()
        afx_msg void OnPaint() {
            CPaintDC dc(this);
            if (m_host) m_host->DrawPreview(&dc);
        }
    };

    CPreview  m_preview;
    CEdit     m_log;
    bool      m_delayPending = false;
};

BEGIN_MESSAGE_MAP(CClipAdvDlg::CPreview, CWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

BEGIN_MESSAGE_MAP(CClipAdvDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_CUSTOM, OnCustom)
    ON_BN_CLICKED(IDC_BTN_DIB, OnDib)
    ON_BN_CLICKED(IDC_BTN_DELAYED, OnDelayed)
    ON_BN_CLICKED(IDC_BTN_HDROP, OnHdrop)
    ON_BN_CLICKED(IDC_BTN_PASTE, OnPaste)
    ON_BN_CLICKED(IDC_BTN_CLEAR, OnClear)
    ON_WM_RENDERFORMAT()
    ON_WM_RENDERALLFORMATS()
END_MESSAGE_MAP()

class CClipAdvApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CClipAdvDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CClipAdvApp theApp;
