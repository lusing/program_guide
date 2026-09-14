# Win32 API 开发指南

> Win32 API 是 Windows 平台下最底层、最接近系统内核的编程接口之一。它提供了窗口创建、消息循环、控件、GDI、文件和系统资源等能力，是理解 Windows 桌面开发的基础。

## 1. 什么是 Win32 API

Win32 API 是微软发布的一组 C 语言风格的函数、结构体和宏，用于和 Windows 操作系统交互。它不依赖 MFC、.NET 或 WPF，而是更接近系统层的原始编程接口。

Win32 的核心能力包括：

- 创建和管理窗口
- 处理消息（Message Loop / WndProc）
- 创建控件（按钮、编辑框、列表框等）
- 使用 GDI 进行绘图和文本渲染
- 调用系统资源和线程、文件等接口

## 2. Win32 程序的最小骨架

任何 Win32 程序都至少包含下面的结构：

1. `WinMain` 作为程序入口
2. `WNDCLASS` 注册窗口类
3. `CreateWindowEx` 创建窗口
4. `GetMessage` / `DispatchMessage` 消息循环
5. `WndProc` 处理窗口消息

示例：

```cpp
#include <windows.h>

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    case WM_PAINT:
        PAINTSTRUCT ps;
        BeginPaint(hwnd, &ps);
        EndPaint(hwnd, &ps);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"SampleWindowClass";

    WNDCLASS wc = {};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);

    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(
        0, CLASS_NAME, L"Hello Win32", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 640, 480,
        nullptr, nullptr, hInstance, nullptr);

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}
```

这个程序的关键点在于：

- `WinMain` 代替 `main`
- `WndProc` 处理所有窗口消息
- `GetMessage` / `DispatchMessage` 驱动程序运行

## 3. 窗口类与消息系统

### 3.1 `WNDCLASS`

窗口类定义了窗口的外观和默认行为，例如：

- 窗口过程函数：`lpfnWndProc`
- 实例句柄：`hInstance`
- 类名：`lpszClassName`
- 光标：`hCursor`
- 背景刷：`hbrBackground`

### 3.2 消息循环

消息循环是 Win32 程序的核心：

```cpp
MSG msg;
while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
}
```

这段循环不断获取应用程序收到的消息，并把它转交给窗口过程。

### 3.3 处理消息的方式

`WndProc` 中常见消息包括：

- `WM_CREATE`：窗口创建时
- `WM_PAINT`：重绘窗口
- `WM_DESTROY`：窗口销毁时
- `WM_SIZE`：窗口大小变化
- `WM_COMMAND`：控件或菜单消息
- `WM_MOUSEMOVE`：鼠标移动
- `WM_LBUTTONDOWN`：左键按下

## 4. 常见 Win32 消息示例

```cpp
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        return 0;

    case WM_LBUTTONDOWN:
        MessageBox(hwnd, L"左键按下", L"消息", MB_OK);
        return 0;

    case WM_MOUSEMOVE:
        if (wParam == MK_LBUTTON) {
            // 拖拽逻辑
        }
        return 0;

    case WM_PAINT:
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        TextOut(hdc, 20, 20, L"Hello Win32", 12);
        EndPaint(hwnd, &ps);
        return 0;

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}
```

理解消息系统，是学习 Win32 最关键的部分。

## 5. 控件开发基础

Win32 允许直接创建原生控件，比如：

- `BUTTON`
- `EDIT`
- `STATIC`
- `LISTBOX`
- `COMBOBOX`
- `SCROLLBAR`

### 5.1 创建按钮和编辑框

```cpp
HWND hEdit = CreateWindowEx(
    0, L"EDIT", L"",
    WS_CHILD | WS_VISIBLE | WS_BORDER | ES_LEFT,
    20, 20, 200, 24, hwnd, nullptr, hInst, nullptr);

HWND hBtn = CreateWindowEx(
    0, L"BUTTON", L"确认",
    WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
    240, 20, 80, 30, hwnd, (HMENU)1001, hInst, nullptr);
```

控件本质上也是窗口，因此也能接收消息、触发事件，并由父窗口处理 `WM_COMMAND`。

### 5.2 处理控件通知

```cpp
case WM_COMMAND:
    if (LOWORD(wParam) == 1001 && HIWORD(wParam) == BN_CLICKED) {
        MessageBox(hwnd, L"按下了按钮", L"通知", MB_OK);
    }
    return 0;
```

## 6. GDI 绘图基础

GDI（Graphics Device Interface）是 Win32 中最关键的图形技术之一，用于在窗口上绘制：

- 文字
- 线条
- 矩形
- 圆形
- 位图
- 自定义图像

### 6.1 `WM_PAINT` 与 `HDC`

`HDC` 是设备上下文句柄，表示当前绘图上下文：

```cpp
case WM_PAINT: {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);

    Rectangle(hdc, 20, 20, 220, 180);
    Ellipse(hdc, 260, 20, 460, 180);

    TextOut(hdc, 80, 210, L"Win32 GDI", 9);

    EndPaint(hwnd, &ps);
    return 0;
}
```

### 6.2 画笔与刷子

在 GDI 中常见对象包括：

- `HPEN`：线条样式
- `HBRUSH`：填充样式
- `HFONT`：字体

示例：

```cpp
HDC hdc = GetDC(hwnd);
HPEN pen = CreatePen(PS_SOLID, 3, RGB(255, 0, 0));
HBRUSH brush = CreateSolidBrush(RGB(0, 128, 255));

HPEN oldPen = (HPEN)SelectObject(hdc, pen);
HBRUSH oldBrush = (HBRUSH)SelectObject(hdc, brush);

Rectangle(hdc, 50, 50, 200, 150);

SelectObject(hdc, oldPen);
SelectObject(hdc, oldBrush);
DeleteObject(pen);
DeleteObject(brush);
ReleaseDC(hwnd, hdc);
```

GDI 通常用于：

- 绘图软件
- 图表和仪表盘
- 自定义控件
- 2D 图形编辑器

## 7. Win32 编程的典型框架

一个比较完整的原生 Win32 应用通常由以下部分组成：

1. `WinMain` 初始化和入口
2. 窗口注册：`WNDCLASS`
3. `CreateWindowEx` 创建窗口
4. 消息循环：`GetMessage` / `DispatchMessage`
5. `WndProc` 处理所有系统消息
6. 控件事件与菜单命令处理
7. 使用 GDI 进行绘图与界面渲染
8. 资源管理和对象释放

这是一种“底层而稳定”的桌面编程模型。

## 8. 菜单与工具栏（Win32 方式）

Win32 中菜单和工具栏不是 MFC 的封装，而是更接近原生 Windows 资源层：

- 菜单使用 `CreateMenu` / `AppendMenu`
- 工具栏通常是 `CreateWindowEx` 创建 `TOOLBARCLASSNAME`
- 命令来自 `WM_COMMAND`

菜单的典型设计：

```cpp
HMENU hMenu = CreateMenu();
HMENU hFile = CreatePopupMenu();
AppendMenu(hFile, MF_STRING, 1001, L"新建");
AppendMenu(hFile, MF_STRING, 1002, L"打开");
AppendMenu(hMenu, MF_STRING | MF_POPUP, (UINT_PTR)hFile, L"文件");
SetMenu(hwnd, hMenu);
```

在菜单、快捷键、工具栏等功能之间，最关键的是统一命令 ID，通过 `WM_COMMAND` 接收命令并执行相关逻辑。

这是 Win32 程序中非常常见的设计方式。

## 9. 对话框与资源

Win32 API 提供对话框支持，通常使用：

- 模板资源：`IDD_*`
- `DialogBoxParam` / `CreateDialogParam`
- `WM_INITDIALOG` 消息
- `WM_COMMAND` 处理按钮点击

典型流程：

```cpp
INT_PTR CALLBACK DialogProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG:
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            EndDialog(hwnd, IDOK);
        }
        return TRUE;
    }
    return FALSE;
}
```

这是原生 Windows 对话框编程的基础步骤。

## 10. Win32 和 MFC 的区别

Win32 与 MFC 的关系可以概括为：

- Win32：底层原生 API，控制粒度最细，学习成本较高
- MFC：基于 Win32 做一层 C++ 封装，开发效率更高

如果你想理解 Windows 桌面应用的本质，先学习 Win32 API 是最有效的路线。

## 11. 本目录中的示例

本目录中的示例将逐步展示：

- `01_hello_window`：最小窗口程序
- `02_message_loop`：消息处理基础
- `03_controls`：按钮和编辑框等原生控件
- `04_gdi_drawing`：GDI 绘图基础

这些示例都按本机 Visual Studio 工具链进行编译验证，并尽量保持与当前安装版本兼容。
