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

## 11. 完整应用例程：从“单窗口示例”走向“真实程序”

如果只停留在 Hello World 和单一消息处理，容易以为 Win32 编程只是几个 `WM_*` 的组合。但真正的桌面程序往往具备：

- 用户界面布局
- 事件响应机制
- 数据输入与输出
- 文件读写或状态保存
- 图形渲染与界面刷新

下面介绍几个更完整的 Win32 应用范式，它们比单一示例更接近真实工程开发。

### 11.1 计算器程序：窗口布局 + 事件处理 + 业务逻辑

一个窗口程序最重要的能力不是“能弹一个窗”，而是“能把输入、按钮和计算逻辑组合起来”。

一个简单计算器的结构通常包括：

- 一个显示区（编辑框或静态文本）
- 数字键和运算符键
- 处理按钮点击事件
- 维护当前值和运算符状态
- 在点击 `=` 时输出结果

典型流程：

1. 用户输入数字
2. 主窗口收到 `WM_COMMAND`（按钮点击）
3. 程序根据按钮 ID 更新状态
4. 点击运算符时切换当前运算
5. 点击 `=` 时执行最终计算并更新显示

这类程序能让你真正体会窗口资源、控件和消息处理的协作方式。

### 11.2 文本编辑器：菜单 + 文件 I/O + 编辑控件

文本编辑器是 Win32 很经典的案例，因为它整合了：

- 菜单：`File -> Open / Save / Exit`
- 控件：编辑框（多行文本）
- 文件操作：`CreateFileW` / `ReadFile` / `WriteFile`
- 命令处理：`WM_COMMAND`

这有两个好处：

- 让你理解菜单命令与控件联动
- 让你看到 Win32 程序从 “窗体” 走向 “实际应用工具” 的过程

### 11.3 画图程序：鼠标跟踪 + 矩形/线条绘制 + GDI 重绘

绘图程序是 GDI 的典型应用：

- 鼠标按下开始绘制
- 鼠标移动时连续更新线段
- `WM_PAINT` 中重绘界面
- 用 `MoveToEx` / `LineTo` 绘制路径

这类程序能帮助你理解：

- 事件驱动模型
- 实时反馈
- 图形状态持久化
- 窗口重绘机制

## 12. 本目录中的完整应用示例

本目录中的示例将逐步展示：

- `01_hello_window`：最小窗口程序
- `02_message_loop`：消息处理基础
- `03_controls`：按钮和编辑框等原生控件
- `04_gdi_drawing`：GDI 绘图基础
- `05_mini_calculator`：完整的计算器程序
- `06_text_editor`：完整的文本编辑器程序
- `07_paint_app`：完整的绘图程序

这些示例都按本机 Visual Studio 工具链进行编译验证，并尽量保持与当前安装版本兼容。

## 13. 进程管理：理解 Windows 任务模型

Win32 API 不只是窗口编程，它也提供了强大的系统级管理能力，其中最重要的是进程管理。所谓“进程”，就是程序的执行实例；它拥有自己的地址空间、线程、句柄和资源。学习 Win32 API 时，理解进程模型非常关键，因为它决定了程序是如何被操作系统调度与管理的。

### 13.1 进程的基本概念

在 Windows 中，进程和线程是分开的：

- 进程：一个程序运行时占用的资源集合。
- 线程：进程内执行代码的最小单元。
- 句柄：系统对象的标识符。
- 进程 ID（PID）：系统内唯一标识一个进程。

常见的进程 API 包括：

- `CreateToolhelp32Snapshot`
- `Process32FirstW`
- `Process32NextW`
- `OpenProcess`
- `TerminateProcess`
- `GetCurrentProcessId`
- `GetCurrentProcess`

### 13.2 进程枚举示例

```cpp
#include <windows.h>
#include <tlhelp32.h>

void ListProcesses() {
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        return;
    }

    PROCESSENTRY32W pe = { sizeof(pe) };
    if (Process32FirstW(hSnapshot, &pe)) {
        do {
            wprintf(L"PID: %u, EXE: %ls\n", pe.th32ProcessID, pe.szExeFile);
        } while (Process32NextW(hSnapshot, &pe));
    }

    CloseHandle(hSnapshot);
}
```

这类函数允许你枚举系统中所有当前进程，并在程序中获取进程 ID 和名称。它常用于：

- 任务管理器风格工具
- 监控器与诊断程序
- 进程筛查和自动化脚本
- 反作弊或安全审计工具

### 13.3 `OpenProcess` 与进程控制

如果需要对另一个进程进行访问或控制，可以使用：

```cpp
HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
```

常用权限包括：

- `PROCESS_QUERY_INFORMATION`
- `PROCESS_VM_READ`
- `PROCESS_TERMINATE`
- `PROCESS_CREATE_THREAD`

注意：权限受安全描述符和用户权限影响，因此在真实系统中，进程访问必须遵守 Windows 安全模型。不要随意终止系统关键进程。

### 13.4 进程管理的实战意义

Windows 桌面程序往往不只是“画一个窗口”，而是在系统中管理资源和任务。进程管理能力用于：

- 监控系统活动
- 做启动器和监管器
- 实现进程间通信协作
- 构建高级系统工具

这种能力是 Win32 API 中“系统编程”层面的关键基础。

## 14. 内存管理：理解堆、虚拟内存和对象生命周期

Win32 API 中，内存管理并不是简单的 `malloc` / `free`。在 Windows 上，程序的内存主要以“虚拟内存”和“堆”两种形式存在。理解这两者，才能认真理解 Windows 程序的资源模型。

### 14.1 进程内存模型

现代 Windows 程序的内存模型有三个层次：

- 代码段：程序指令和静态代码
- 数据段：全局变量、静态变量、常量
- 堆 / 栈：动态内存与函数调用栈

其中：

- 栈：函数调用产生的局部变量和返回地址
- 堆：动态分配的内存，如 `malloc`、`new`
- 虚拟内存：系统给进程映射的地址空间

### 14.2 `VirtualAlloc` / `VirtualFree`

如果需要更底层地控制内存，Win32 提供了 `VirtualAlloc` 和 `VirtualFree`：

```cpp
void* p = VirtualAlloc(
    nullptr,
    1024 * 1024,
    MEM_COMMIT | MEM_RESERVE,
    PAGE_READWRITE);

if (p) {
    memset(p, 0xAA, 1024 * 1024);
    VirtualFree(p, 0, MEM_RELEASE);
}
```

这类 API 的优点是：

- 可以申请大块连续虚拟地址空间
- 能在更低层控制内存属性
- 常用于系统组件、运行时引擎和内存扫描工具

### 14.3 `GlobalMemoryStatusEx`

想知道当前系统的可用物理和虚拟内存，可以使用：

```cpp
MEMORYSTATUSEX mem = { sizeof(mem) };
GlobalMemoryStatusEx(&mem);

printf("Total physical memory: %llu MB\n", mem.ullTotalPhys / (1024ULL * 1024ULL));
printf("Available physical memory: %llu MB\n", mem.ullAvailPhys / (1024ULL * 1024ULL));
```

这在做：

- 内存监控工具
- 资源管理器
- 诊断脚本
- 自动化性能检测

时极为常用。

### 14.4 内存管理中的注意事项

在 Win32 程序里，内存管理不是“随便开个 buffer 就行”的事情，需要注意：

- `VirtualAlloc` 申请的内存必须配套 `VirtualFree`
- 释放后，要避免悬空指针
- 读写越界会导致访问违例
- 处理大量内存时需注意 32 位/64 位地址差异

这也是为什么底层 Win32 程序开发往往比托管语言更容易出现资源问题：它把资源所有权和生命周期交给开发者自己管理。

## 15. 文件管理：文件、目录、读写和查找

Win32 API 对文件系统提供了近乎底层的访问能力。与 C 标准库相比，它更贴近 Windows 文件系统语义，并支持：

- 创建/打开文件
- 读写二进制和文本文件
- 遍历目录
- 获取文件属性
- 查找文件和子目录

### 15.1 `CreateFileW` / `ReadFile` / `WriteFile`

最基础的文件 API 三件套：

```cpp
HANDLE hFile = CreateFileW(
    L"C:\\tmp\\demo.txt",
    GENERIC_WRITE,
    0,
    nullptr,
    CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    nullptr);

const char text[] = "Hello from Win32!\n";
DWORD written = 0;
WriteFile(hFile, text, (DWORD)strlen(text), &written, nullptr);
CloseHandle(hFile);
```

这类 API 用于：

- 日志文件写入
- 配置文件保存
- 资源导出
- 二进制数据缓存

### 15.2 目录枚举：`FindFirstFileW` / `FindNextFileW`

Windows 中常见的目录扫描方式：

```cpp
WIN32_FIND_DATAW fd;
HANDLE hFind = FindFirstFileW(L"C:\\*", &fd);
if (hFind != INVALID_HANDLE_VALUE) {
    do {
        wprintf(L"%ls\n", fd.cFileName);
    } while (FindNextFileW(hFind, &fd));
    FindClose(hFind);
}
```

这可以帮助你：

- 扫描目录中的文件
- 过滤目录和文件
- 构建文件浏览器
- 实现简单的资源管理器风格工具

### 15.3 获取和设置文件属性

Win32 还支持：

- `GetFileAttributesW`
- `SetFileAttributesW`
- `GetFileSizeEx`
- `SetFilePointerEx`
- `MoveFileW`
- `CopyFileW`
- `DeleteFileW`

这些 API 使得 Win32 文件管理既能完成“低层读写”，也能完成“目录与资源操作”。

### 15.4 文件管理场景中的工程价值

文件管理功能是桌面程序最常见、最关键的能力之一，它支撑：

- 文本编辑器
- 配置保存器
- 资源打包工具
- 日志记录器
- 数据导入/导出程序

一个真正的 Windows 图形应用，很少只是窗口和控件；通常一定要处理数据的持久化和文件管理。

## 16. 进程、内存和文件管理协同：真实工程中的 Win32 程序

真正实用的 Win32 程序通常不是“静态窗口”，而是同时处理以下几类能力：

1. 进程管理：枚举、观察、控制任务
2. 内存管理：监控、分配、释放、避免越界
3. 文件管理：打开、读写、搜索、保存和重建数据
4. 窗口与控件：形成用户界面
5. GDI：显示状态和绘制信息

这就说明：Win32 API 不只是“界面 API”，更是一整套系统编程工具箱。只要你掌握了这几个关键主题，就能从最基础的 Hello Window 逐渐走向真正的 Windows 工具程序。

### 16.1 进一步推荐的学习顺序

建议以后按下面顺序继续学习：

- 进程枚举和 PID 管理
- 句柄和资源生命周期管理
- 线程编程（CreateThread / WaitForSingleObject）
- 文件映射（CreateFileMapping / MapViewOfFile）
- DLL 与模块加载
- 事件、互斥量和同步对象
- 控制台/GUI/系统服务程序的区别

### 16.2 本目录新增的进阶示例

本目录新增了三个更接近系统编程的例子：

- `08_process_manager`：进程枚举和 PID 查询
- `09_memory_monitor`：虚拟内存与物理内存状态查看
- `10_file_manager`：文件创建、目录枚举和文件读写

这三个示例是连接“基础窗口编程”和“更真实系统工具开发”的重要桥梁。

## 17. 总结

Win32 API 不是一个单独的“窗口库”，而是一整套 Windows 原生编程接口。它覆盖了：

- 窗口与消息
- 控件与事件
- GDI 图形绘制
- 菜单、对话框与资源
- 进程管理
- 内存管理
- 文件管理

如果你能把这些主题串起来，你就已经开始真正理解 Windows 程序的运行机制，而不仅仅是逐个函数调用。后续继续深入时，建议以“窗口 + 事件 + 资源 + 系统服务”的视角来阅读 Win32 API 文档，这样理解会更加稳定和实用。
