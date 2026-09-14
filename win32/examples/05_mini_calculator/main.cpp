#include <windows.h>
#include <stdio.h>

namespace {
    const int ID_BUTTON_0 = 1000;
    const int ID_BUTTON_1 = 1001;
    const int ID_BUTTON_2 = 1002;
    const int ID_BUTTON_3 = 1003;
    const int ID_BUTTON_4 = 1004;
    const int ID_BUTTON_5 = 1005;
    const int ID_BUTTON_6 = 1006;
    const int ID_BUTTON_7 = 1007;
    const int ID_BUTTON_8 = 1008;
    const int ID_BUTTON_9 = 1009;
    const int ID_BUTTON_CLEAR = 1010;
    const int ID_BUTTON_PLUS = 1011;
    const int ID_BUTTON_MINUS = 1012;
    const int ID_BUTTON_MUL = 1013;
    const int ID_BUTTON_DIV = 1014;
    const int ID_BUTTON_EQUAL = 1015;

    const int ID_DISPLAY = 2000;

    double currentValue = 0.0;
    double storedValue = 0.0;
    bool hasStoredValue = false;
    bool waitingForOperand = false;
    wchar_t currentOp = 0;
}

void UpdateDisplay(HWND hwnd, const wchar_t* value) {
    SetWindowTextW(GetDlgItem(hwnd, ID_DISPLAY), value);
}

void AppendDigit(HWND hwnd, int digit) {
    wchar_t buffer[64] = {};
    GetWindowTextW(GetDlgItem(hwnd, ID_DISPLAY), buffer, 64);

    if (waitingForOperand) {
        buffer[0] = L'\0';
        waitingForOperand = false;
    }

    if (wcscmp(buffer, L"0") == 0 && digit == 0) {
        return;
    }

    if (wcscmp(buffer, L"0") == 0) {
        swprintf_s(buffer, L"%d", digit);
    } else {
        wchar_t temp[64];
        swprintf_s(temp, L"%ls%d", buffer, digit);
        wcscpy_s(buffer, temp);
    }

    UpdateDisplay(hwnd, buffer);
}

void PerformPendingOperation(HWND hwnd) {
    wchar_t buffer[64] = {};
    GetWindowTextW(GetDlgItem(hwnd, ID_DISPLAY), buffer, 64);
    double displayValue = wcstod(buffer, nullptr);

    if (!hasStoredValue) {
        storedValue = displayValue;
        hasStoredValue = true;
        return;
    }

    switch (currentOp) {
    case L'+':
        storedValue += displayValue;
        break;
    case L'-':
        storedValue -= displayValue;
        break;
    case L'*':
        storedValue *= displayValue;
        break;
    case L'/':
        if (displayValue != 0.0) {
            storedValue /= displayValue;
        }
        break;
    }

    wchar_t result[64];
    swprintf_s(result, L"%.10g", storedValue);
    UpdateDisplay(hwnd, result);

    currentValue = storedValue;
    waitingForOperand = true;
    hasStoredValue = false;
}

void ClearCalculator(HWND hwnd) {
    currentValue = 0.0;
    storedValue = 0.0;
    hasStoredValue = false;
    waitingForOperand = false;
    currentOp = 0;
    UpdateDisplay(hwnd, L"0");
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CreateWindowExW(0, L"EDIT", L"0",
            WS_CHILD | WS_VISIBLE | WS_BORDER | ES_RIGHT | ES_READONLY,
            20, 20, 260, 32, hwnd, reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_DISPLAY)), ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        int x = 20; int y = 70;
        int buttons[] = {
            ID_BUTTON_7, ID_BUTTON_8, ID_BUTTON_9, ID_BUTTON_DIV,
            ID_BUTTON_4, ID_BUTTON_5, ID_BUTTON_6, ID_BUTTON_MUL,
            ID_BUTTON_1, ID_BUTTON_2, ID_BUTTON_3, ID_BUTTON_MINUS,
            ID_BUTTON_CLEAR, ID_BUTTON_0, ID_BUTTON_EQUAL, ID_BUTTON_PLUS
        };

        for (int i = 0; i < 16; ++i) {
            int id = buttons[i];
            const wchar_t* label = L"";

            switch (id) {
            case ID_BUTTON_0: label = L"0"; break;
            case ID_BUTTON_1: label = L"1"; break;
            case ID_BUTTON_2: label = L"2"; break;
            case ID_BUTTON_3: label = L"3"; break;
            case ID_BUTTON_4: label = L"4"; break;
            case ID_BUTTON_5: label = L"5"; break;
            case ID_BUTTON_6: label = L"6"; break;
            case ID_BUTTON_7: label = L"7"; break;
            case ID_BUTTON_8: label = L"8"; break;
            case ID_BUTTON_9: label = L"9"; break;
            case ID_BUTTON_CLEAR: label = L"C"; break;
            case ID_BUTTON_PLUS: label = L"+"; break;
            case ID_BUTTON_MINUS: label = L"-"; break;
            case ID_BUTTON_MUL: label = L"*"; break;
            case ID_BUTTON_DIV: label = L"/"; break;
            case ID_BUTTON_EQUAL: label = L"="; break;
            }

            CreateWindowExW(0, L"BUTTON", label,
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                x, y, 54, 40, hwnd, reinterpret_cast<HMENU>(static_cast<UINT_PTR>(id)), ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

            x += 62;
            if ((i + 1) % 4 == 0) {
                x = 20;
                y += 52;
            }
        }

        UpdateDisplay(hwnd, L"0");
        return 0;
    }
    case WM_COMMAND: {
        int id = LOWORD(wParam);
        if (HIWORD(wParam) == BN_CLICKED) {
            switch (id) {
            case ID_BUTTON_CLEAR:
                ClearCalculator(hwnd);
                return 0;
            case ID_BUTTON_0:
            case ID_BUTTON_1:
            case ID_BUTTON_2:
            case ID_BUTTON_3:
            case ID_BUTTON_4:
            case ID_BUTTON_5:
            case ID_BUTTON_6:
            case ID_BUTTON_7:
            case ID_BUTTON_8:
            case ID_BUTTON_9:
                AppendDigit(hwnd, id - ID_BUTTON_0);
                return 0;
            case ID_BUTTON_PLUS:
            case ID_BUTTON_MINUS:
            case ID_BUTTON_MUL:
            case ID_BUTTON_DIV:
                {
                    wchar_t buffer[64] = {};
                    GetWindowTextW(GetDlgItem(hwnd, ID_DISPLAY), buffer, 64);
                    double displayValue = wcstod(buffer, nullptr);

                    if (waitingForOperand) {
                        if (id == ID_BUTTON_PLUS) currentOp = L'+';
                        else if (id == ID_BUTTON_MINUS) currentOp = L'-';
                        else if (id == ID_BUTTON_MUL) currentOp = L'*';
                        else if (id == ID_BUTTON_DIV) currentOp = L'/';
                    } else {
                        if (hasStoredValue && currentOp != 0) {
                            switch (currentOp) {
                            case L'+': storedValue += displayValue; break;
                            case L'-': storedValue -= displayValue; break;
                            case L'*': storedValue *= displayValue; break;
                            case L'/': if (displayValue != 0.0) storedValue /= displayValue; break;
                            }
                            wchar_t result[64];
                            swprintf_s(result, L"%.10g", storedValue);
                            UpdateDisplay(hwnd, result);
                        } else {
                            storedValue = displayValue;
                            hasStoredValue = true;
                        }

                        if (id == ID_BUTTON_PLUS) currentOp = L'+';
                        else if (id == ID_BUTTON_MINUS) currentOp = L'-';
                        else if (id == ID_BUTTON_MUL) currentOp = L'*';
                        else if (id == ID_BUTTON_DIV) currentOp = L'/';

                        waitingForOperand = true;
                    }
                }
                return 0;
            case ID_BUTTON_EQUAL:
                PerformPendingOperation(hwnd);
                return 0;
            }
        }
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"CalculatorWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Mini Calculator",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 330, 360,
        nullptr, nullptr, hInstance, nullptr);

    if (hwnd == nullptr) {
        return 1;
    }

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return 0;
}
