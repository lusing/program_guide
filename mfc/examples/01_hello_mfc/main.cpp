#include <afxwin.h>
#include <iostream>

int main() {
    CString title = _T("MFC Hello");
    CPoint origin(10, 20);

    std::wcout << L"Title: " << static_cast<const wchar_t*>(title) << L"\n";
    std::cout << "Origin: (" << origin.x << ", " << origin.y << ")\n";

    CWinApp app;
    app.m_pszHelpFilePath = _T("mfc_help.chm");

    std::cout << "MFC headers and libraries are available.\n";
    return 0;
}
