#include <afxwin.h>
#include <iostream>

class CMyDialog : public CDialog {
public:
    enum { IDD = 1000 };

    explicit CMyDialog(UINT templateId = IDD) : CDialog(templateId) {}
};

int main() {
    CString title = _T("MFC Dialog Demo");
    CPoint origin(100, 200);
    CMyDialog dialog;

    std::wcout << L"Title: " << static_cast<const wchar_t*>(title) << L"\n";
    std::cout << "Origin: (" << origin.x << ", " << origin.y << ")\n";
    dialog.SetWindowText(_T("Dialog initialized."));

    std::cout << "MFC dialog types are available.\n";
    return 0;
}
