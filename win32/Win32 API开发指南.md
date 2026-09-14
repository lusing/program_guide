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

## 12. Win32 API 的完整地图：大类、能力和版本差异

如果把 Win32 API 看成一套完整的 Windows 系统编程工具箱，它并不是只有“窗口”一个单位，而是由很多功能模块组合而成。理解这些大类，能帮助你真正把 Win32 学习从“函数拼接”提升到“系统模型理解”。

### 12.1 Win32 API 的主要大类

Win32 可以大致分为下面几个层次：

#### 1）基础系统 API

这是最底层的核心模块，负责与操作系统本身交互：

- 进程与线程：`CreateProcessW`、`CreateThread`、`OpenProcess`
- 句柄管理：`CreateFileW`、`CreateEventW`、`CreateMutexW`
- 内存管理：`VirtualAlloc`、`VirtualFree`、`GlobalAlloc`
- 资源与错误处理：`GetLastError`、`CloseHandle`
- 事件和同步：`WaitForSingleObject`、`CreateMutex`、`CreateEvent`

这部分是 Win32 的“系统编程”基础，像进程管理、线程同步、文件管理都属于这里。

#### 2）窗口与消息 API

这是 Win32 最为人熟知的部分，负责创建和管理窗口：

- 窗口注册：`RegisterClassW` / `WNDCLASS`
- 创建窗口：`CreateWindowExW`
- 消息循环：`GetMessageW` / `DispatchMessageW`
- 窗口过程：`WndProc`
- 子窗口和控件：按钮、编辑框、列表框、静态文本等

这一类 API 是 Windows GUI 程序的核心；无论是 Win32 原生程序、MFC 还是很多 GUI 框架，最后都依赖这里的底层机制。

#### 3）图形设备接口（GDI）

GDI 是 Win32 中负责绘图的模块：

- `BeginPaint` / `EndPaint`
- `TextOutW` / `DrawTextW`
- `Rectangle` / `Ellipse` / `LineTo`
- `CreatePen` / `CreateBrush`
- `SelectObject` / `DeleteObject`

GDI 用于：

- 绘制窗口内容
- 自定义控件
- 图表和绘图工具
- 二维图形渲染

#### 4）控件和对话框 API

Win32 允许直接创建原生控件，也支持对话框：

- `CreateWindowExW` 创建按钮、编辑框、列表框等
- `WM_COMMAND` 处理控件消息
- `DialogBoxParam` / `CreateDialogParam` 创建对话框
- `SendMessageW` / `PostMessageW` 发送消息

这是桌面 UI 开发的最基础结构之一。

#### 5）文件系统与 I/O API

用于文件和目录操作：

- `CreateFileW` / `ReadFile` / `WriteFile`
- `FindFirstFileW` / `FindNextFileW`
- `GetFileAttributesW` / `SetFileAttributesW`
- `MoveFileW` / `CopyFileW` / `DeleteFileW`

这部分常见于：

- 文本编辑器
- 配置保存器
- 日志和资源管理工具
- 文件浏览器类程序

#### 6）注册表和系统配置 API

Windows 提供了注册表与系统配置访问：

- `RegOpenKeyExW`
- `RegQueryValueExW`
- `RegSetValueExW`
- `RegCreateKeyExW`

常用于：

- 程序配置存储
- 启动项
- 运行时参数
- 系统策略与安装配置

#### 7）资源与菜单 API

- `LoadMenuW` / `CreateMenu` / `AppendMenuW`
- `LoadIconW` / `LoadBitmapW`
- `LoadStringW`
- `DialogBoxParam` 资源对话框

用于：

- 菜单系统
- 图片资源
- 图标和字符串资源
- 资源型桌面应用

#### 8）Shell 与高级桌面 API

这是更高层面的 Windows 集成能力：

- `ShellExecuteW`
- `SHBrowseForFolder`
- `SHFileOperation`
- 任务栏、快捷方式、文件关联等

这些 API 往往让程序与桌面环境更自然地集成。

### 12.2 Win32 实际上并不是一个单独“版本”，而是一套跨版本的 Windows API 体系

Win32 API 的设计非常长寿，它经历过多次 Windows 版本迭代，但底层理念基本保持一致。

#### 1）Win32 早期阶段（Win95 / Win98 / NT 3.x）

- 32 位编程模型基本成型
- ANSI 字符集与 Unicode 早期并存
- 依赖 `WNDCLASS`、消息循环和窗口过程
- 资源和对话框经常通过资源脚本配置

这一阶段的程序风格更偏底层，是后续 Win32 程序的源头。

#### 2）Windows NT / 2000 / XP 时代

- 统一了 NT 家族与桌面应用编程模型
- 对 Unicode 支持增强
- 事件、线程、同步和高级系统 API 得到广泛使用
- 资源管理、文件和注册表更加成熟

这是很多经典 Win32 桌面程序的主要时代。

#### 3）Vista / 7 / 8 / 10 / 11 时代

- DPI 感知（DPI awareness）开始成为重要课题
- UAC 和安全模型更严格
- 新增大量 Shell、媒体和高级桌面能力
- 更重视用户体验和无障碍性

这时期的程序需要考虑：

- DPI 缩放
- 用户权限
- 高分辨率屏幕适配
- 新版控件和 UI 规范

#### 4）64 位 Windows

Win32 在 64 位系统上并没有消失，而是演化成 64 位可执行程序：

- `DWORD_PTR`、`SIZE_T`、`UINT_PTR` 等类型更常见
- 指针宽度从 32 位升级到 64 位
- 许多 API 需要使用 `LONG_PTR` / `UINT_PTR` 来避免截断
- 64 位程序更关注内存布局与指针正确性

例如：

```cpp
UINT_PTR id = 1001;
HMENU hMenu = reinterpret_cast<HMENU>(static_cast<UINT_PTR>(id));
```

这是 Win32 中非常典型的 32/64 位兼容问题。

### 12.3 ANSI 与 Unicode：Win32 最重要的版本兼容问题之一

在 Win32 早期很多 API 有两套版本：

- ANSI 版本：以 `A` 结尾，如 `CreateWindowA`
- Unicode 版本：以 `W` 结尾，如 `CreateWindowW`

现代 Windows 中，通常用宏统一：

```cpp
#ifdef UNICODE
#define CreateWindow CreateWindowW
#else
#define CreateWindow CreateWindowA
#endif
```

因此，现代 Win32 程序通常写：

- `CreateWindowW`
- `TextOutW`
- `MessageBoxW`
- `CreateFileW`

原因是 Unicode 更适合国际化、中文路径、非 ASCII 字符处理。

### 12.4 Win32 与 MFC、.NET、WPF 的关系

这是很多初学者容易混淆的概念：

- Win32：最底层的系统 API
- MFC：C++ 封装层，建立在 Win32 之上
- .NET / WPF：托管环境，最终仍然可能依赖 Windows 窗口系统
- WinUI：现代 Windows UI 体系，但也涉及 Win32 兼容层

可以把它们理解为：

- Win32 是“底层土壤”
- MFC 是“C++ 封装”
- WPF 是“托管 UI 框架”
- WinUI 是“现代 Windows UI 语言层”

因此，学习 Win32 从本质上是理解 Windows 应用的真实架构，而不是看表面框架。

### 12.5 需要特别注意的兼容性点

#### 1）句柄类型是 64 位兼容的

Windows 中的句柄往往是指针大小的类型，例如 `HANDLE`、`HWND`、`HMENU`。在 64 位系统中，不能直接按 32 位整数强转。

#### 2）字符串必须注意宽字符

尤其是中文路径、文件名和窗口标题，最好使用 `wchar_t` + `W` 系列 API。

#### 3）资源释放必须成对出现

例如：

- `CreateFileW` 后要 `CloseHandle`
- `VirtualAlloc` 后要 `VirtualFree`
- `CreatePen` / `CreateBrush` 后要 `DeleteObject`
- `CreateProcessW` 后要 `CloseHandle(pi.hThread)` / `CloseHandle(pi.hProcess)`

#### 4）错误处理要看 `GetLastError()`

很多底层 Win32 API 失败时，不一定抛异常，而是返回 `FALSE`/`NULL`，此时必须看 `GetLastError()`。

### 12.6 典型学习路线：从“底层到应用”理解 Win32

推荐的学习顺序是：

1. WinMain + WNDCLASS + CreateWindow + 消息循环
2. `WM_*` 消息与 `WndProc` 结构
3. 控件与 `WM_COMMAND`
4. GDI 与绘图
5. 文件 I/O 与目录枚举
6. 内存与句柄管理
7. 进程与线程管理
8. 资源、注册表和 Shell 集成

这样你会从“完成一个窗口”逐步走到“能写一个真正的 Windows 桌面工具”。

### 12.7 总结

Win32 API 不是一个单一函数库，它是整个 Windows 桌面开发的底层基座。关键的大类包括：

- 基础系统 API
- 窗口与消息系统
- GDI 图形系统
- 控件和对话框
- 文件系统
- 进程/线程/同步
- 资源和 Shell 集成
- 注册表与系统配置

而它的不同版本差异，最关键的是：

- ANSI vs Unicode
- 32 位 vs 64 位
- 安全模型与权限变化
- DPI 和高分辨率适配
- 组件和 API 逐步扩充

掌握这些，你就不只是会调用几个 API，而是已经理解了 Windows 程序的整体机制。

## 13. Win32 线程 API 与同步机制

线程是 Win32 程序中非常关键的概念。它决定了一个进程内能否同时执行多段任务，并在多任务环境中协调资源访问。对于桌面应用、后台处理、网络服务和工具软件来说，线程与同步是永远绕不开的核心主题。

### 13.1 线程与进程的区别

前面已经学习了进程，它表示“一个正在运行的程序实例”，而线程则表示：

- 进程内部执行代码的最小单元
- 共享同一块进程地址空间
- 可能并发运行多个逻辑流
- 共享文件、内存和对象句柄

一个进程至少有一个线程，通常叫做主线程。Win32 程序很多时候都是：

- 主线程处理窗口消息
- 子线程处理后台工作
- 互斥量、事件和临界区负责协调协调

### 13.2 `CreateThread`：创建线程

创建线程最常用的 API 是 `CreateThread`：

```cpp
#include <windows.h>
#include <stdio.h>

DWORD WINAPI WorkerThread(LPVOID param) {
    int* value = (int*)param;
    for (int i = 0; i < 5; ++i) {
        printf("Thread running: %d\n", (*value)++);
        Sleep(100);
    }
    return 0;
}

int main() {
    int counter = 0;
    HANDLE hThread = CreateThread(
        nullptr,
        0,
        WorkerThread,
        &counter,
        0,
        nullptr);

    if (hThread) {
        WaitForSingleObject(hThread, INFINITE);
        CloseHandle(hThread);
    }
    return 0;
}
```

这里的关键参数：

- `LPTHREAD_START_ROUTINE` 线程入口函数
- `LPVOID` 参数，传入任意上下文数据
- `DWORD` 返回值，线程退出时可被读取
- `WaitForSingleObject` 用于等待线程结束

### 13.3 线程的结束与等待

线程有三种常见方式结束：

1. 线程函数返回
2. 调用 `ExitThread`
3. 由其他线程调用 `TerminateThread`（不推荐）

通常推荐使用：

```cpp
DWORD exitCode = 0;
GetExitCodeThread(hThread, &exitCode);
WaitForSingleObject(hThread, INFINITE);
```

这是因为线程正常结束往往比强制结束更清晰，也更符合 Win32 的资源管理习惯。

### 13.4 线程同步的核心问题

线程同步的本质是：避免多个线程同时访问共享资源导致竞态条件、脏读、错误状态等问题。

典型问题包括：

- 两个线程同时写同一个变量
- 一个线程读数据时另一个线程正在改
- GUI 线程和后台线程同时修改控件状态
- 资源释放发生在另一个线程使用对象时

### 13.5 `CRITICAL_SECTION`：轻量级同步工具

`CRITICAL_SECTION` 是最常见的线程同步原语之一，适合同一进程内的线程共享资源：

```cpp
#include <windows.h>
#include <stdio.h>

CRITICAL_SECTION g_cs;
int g_counter = 0;

DWORD WINAPI Worker(LPVOID) {
    EnterCriticalSection(&g_cs);
    ++g_counter;
    printf("counter = %d\n", g_counter);
    LeaveCriticalSection(&g_cs);
    return 0;
}

int main() {
    InitializeCriticalSection(&g_cs);

    HANDLE h1 = CreateThread(nullptr, 0, Worker, nullptr, 0, nullptr);
    HANDLE h2 = CreateThread(nullptr, 0, Worker, nullptr, 0, nullptr);

    WaitForSingleObject(h1, INFINITE);
    WaitForSingleObject(h2, INFINITE);

    DeleteCriticalSection(&g_cs);
    CloseHandle(h1);
    CloseHandle(h2);
    return 0;
}
```

`CRITICAL_SECTION` 的优点：

- 适合同一进程内的线程同步
- 比互斥量更轻量
- 执行效率高

注意：

- 只能用于同一进程中的线程
- 不能跨进程使用
- 若进入后忘记离开，可能造成死锁

### 13.6 `Mutex`：跨线程/跨进程互斥对象

如果两个线程来自不同进程，或者你需要整个系统级同步，可以使用 `CreateMutexW`：

```cpp
HANDLE hMutex = CreateMutexW(nullptr, FALSE, L"GlobalDemoMutex");
if (hMutex == nullptr) {
    return 1;
}

WaitForSingleObject(hMutex, INFINITE);
// 访问共享资源
ReleaseMutex(hMutex);
CloseHandle(hMutex);
```

Mutex 和 CriticalSection 的区别：

- `CRITICAL_SECTION`：仅限同一进程内
- `Mutex`：可跨进程同步
- `Mutex`：具备命名特性，适合系统范围资源共享

### 13.7 `Event`：用于通知和等待

`Event` 适合“一个线程通知另一个线程某事已发生”的场景：

```cpp
HANDLE hEvent = CreateEventW(nullptr, FALSE, FALSE, L"DemoEvent");

DWORD WINAPI Worker(LPVOID) {
    WaitForSingleObject(hEvent, INFINITE);
    printf("Event signaled!\n");
    return 0;
}

SetEvent(hEvent);
```

`Event` 常用于：

- 线程启动通知
- 任务完成通知
- 生产者/消费者模型
- 后台线程与前台线程协调

特点：

- 自动复位（`FALSE`）或手动复位（`TRUE`）
- 可以作为信号量一样通知同步状态

### 13.8 `Semaphore`：控制并发数量

Win32 里还有 `CreateSemaphoreW`，常用于：

- 限制同时访问资源的线程数量
- 任务队列中限制并发处理数
- 生产者/消费者缓冲池控制

```cpp
HANDLE hSem = CreateSemaphoreW(nullptr, 3, 3, L"DemoSem");
WaitForSingleObject(hSem, INFINITE);
// access limited resource
ReleaseSemaphore(hSem, 1, nullptr);
```

它与互斥量的主要区别：

- 互斥量：只允许一个线程进入
- 信号量：允许多个线程在某个计数范围内进入

### 13.9 `WaitForSingleObject` 与 `WaitForMultipleObjects`

这是 Win32 中最常用的等待 API：

```cpp
DWORD result = WaitForSingleObject(hThread, 1000);
if (result == WAIT_TIMEOUT) {
    // timed out
}
```

如果需要等待多个对象：

```cpp
HANDLE handles[] = { hThread1, hThread2, hEvent };
DWORD result = WaitForMultipleObjects(3, handles, FALSE, INFINITE);
```

用途：

- 等待多个线程结束
- 等待事件或信号
- 实现任务协调和超时控制

### 13.10 线程同步的典型模式

#### 1）生产者/消费者

- 生产线程将数据写入队列
- 消费线程从队列读取数据
- 通过事件或信号量协调速度差异

#### 2）后台任务与 UI 线程

- 后台线程做大量计算
- UI 线程负责界面更新
- 通过消息或事件进行通讯

#### 3）共享资源保护

- 多个线程访问同一块缓存
- 用 `CRITICAL_SECTION` 或 `Mutex` 包住临界区

### 13.11 死锁与竞态条件

线程同步最难的一点是避免两个典型错误：

#### 1）死锁

例如：

- 线程 A 等待 Mutex1
- 线程 B 等待 Mutex2
- 两个线程分别持有对方需要的锁

这就造成了互相等待。

#### 2）竞态条件

例如：

```cpp
int count = 0;
// 线程 1: count++
// 线程 2: count++
```

这在很多平台上可能导致丢失更新问题。线程安全的关键是：

- 对共享变量使用同步原语
- 尽量减少共享状态
- 让修改逻辑保持原子性

### 13.12 Win32 线程 API 的工程意义

Win32 线程 API 不只是“让程序有多线程”，而是让程序能够：

- 并行处理计算任务
- 避免界面卡死
- 处理后台 I/O
- 管理多个并发资源
- 实现服务型、调度型、监控型工具

如果没有线程和同步，很多真实程序都很难做到高效和稳定。

### 13.13 线程与回调消息的结合

在 GUI 程序中，后台线程通常不直接修改 UI 控件，因为这会带来跨线程访问问题。正确做法是：

- 后台线程计算数据
- 总结结果
- 通过 `PostMessageW` 或事件通知主线程
- 主线程更新界面控件

这是 Win32 GUI 程序中非常成熟的设计模式。

### 13.14 总结

Win32 线程 API 与同步机制的核心要点可以概括为：

- `CreateThread` 创建线程
- `WaitForSingleObject` / `WaitForMultipleObjects` 等待对象
- `CRITICAL_SECTION` 适用于同进程共享资源
- `Mutex` 适用于跨进程同步
- `Event` 适用于通知与信号
- `Semaphore` 适用于并发数量限制
- 线程安全的根本要求是正确使用同步对象并避免死锁/竞态

线程是 Win32 程序的高级能力，它是从“会画窗口”走向“能写真实工具程序”的关键一步。

### 13.15 实战演示：线程同步与 UI 消息回传

一个现实中的 Win32 程序，通常不会让后台线程直接改写控件文本；这是因为窗口和控件属于 UI 线程，跨线程访问常常导致不可预期的行为。更稳妥的方式是：

- 后台线程做计算或 I/O
- 使用 `CRITICAL_SECTION` 保护共享计数器
- 用 `PostMessageW` 向主窗口发送状态更新
- 主窗口根据消息更新静态文本和按钮状态

对应的示例目录是：

```text
win32/examples/11_thread_sync_demo/
└── main.cpp
```

它演示了以下关键点：

```cpp
CRITICAL_SECTION g_cs;
LONG g_counter = 0;
HANDLE g_doneEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);

DWORD WINAPI WorkerThread(LPVOID param) {
    for (int i = 0; i < 5; ++i) {
        EnterCriticalSection(&g_cs);
        ++g_counter;
        LeaveCriticalSection(&g_cs);

        PostMessageW(hwnd, WM_APP_THREAD_UPDATE, 0, (LPARAM)L"tick");
        Sleep(250);
    }

    SetEvent(g_doneEvent);
    return 0;
}
```

这里的设计思想很重要：

1. 共享变量要受临界区保护，避免多个线程同时写入同一内存。
2. 跨线程更新窗口时，优先使用 `PostMessageW` 或 `SendMessageW`，不要直接在工作线程里操作控件。
3. `Event` 很适合表示“后台任务已完成”这种状态。调用 `WaitForSingleObject` 可以让其他线程安全地等待任务完成。

这类线程模型是 Win32 GUI 工程中最常见的模式之一，几乎所有后台计算、文件扫描、网络请求回调和命令执行器都会采用类似思路。

## 14. Win32 DLL 与模块加载

DLL（Dynamic Link Library，动态链接库）是 Windows 平台上最重要的模块化机制之一。它允许程序把功能拆成多个独立模块，并在运行时按需加载。理解 DLL，不只是理解“库文件”，而是理解 Windows 应用的模块组织方式。

### 14.1 DLL 是什么

DLL 本质上是一种共享代码和资源的可执行模块。它与 EXE 程序的主要区别是：

- EXE 是可执行程序入口，通常有 `WinMain` 或 `main`
- DLL 不是独立程序，不直接运行
- DLL 被其他程序加载之后提供函数、资源和共享能力
- 多个进程可以共享同一个 DLL 的内存映像（前提是系统支持共享页）

典型用途：

- 提供通用函数库
- 封装系统功能模块
- 分离业务逻辑和界面逻辑
- 给插件式架构提供扩展能力

### 14.2 DLL 的典型生命周期

一个 DLL 在 Windows 中常见的加载与卸载流程是：

1. 进程调用 `LoadLibraryW` / `LoadLibraryExW`
2. 系统在内存中定位并映射 DLL
3. DLL 初始化代码执行（`DllMain`）
4. 进程调用导出函数
5. 程序调用 `FreeLibrary` 卸载 DLL

这就是 Windows 程序的模块加载模型的基础。

### 14.3 `LoadLibraryW` / `LoadLibraryExW`

最常见的 DLL 加载函数：

```cpp
#include <windows.h>

int main() {
    HMODULE hMod = LoadLibraryW(L"user32.dll");
    if (hMod != nullptr) {
        // DLL 已成功加载
        FreeLibrary(hMod);
    }
    return 0;
}
```

`LoadLibraryExW` 可以提供更多参数，例如：

- `LOAD_LIBRARY_SEARCH_*` 这样的搜索策略
- 远程加载控制（如果支持）
- 显式指定加载行为

常见用途：

- 延迟加载依赖模块
- 插件系统
- 运行时可扩展能力
- 动态调用系统功能

### 14.4 `GetProcAddress`：获取导出函数地址

加载 DLL 后，程序常常需要获取某个函数指针：

```cpp
#include <windows.h>
#include <stdio.h>

typedef void (WINAPI *MessageBoxFunc)(HWND, LPCWSTR, LPCWSTR, UINT);

int main() {
    HMODULE hUser32 = LoadLibraryW(L"user32.dll");
    if (hUser32 == nullptr) {
        return 1;
    }

    FARPROC proc = GetProcAddress(hUser32, "MessageBoxW");
    if (proc != nullptr) {
        MessageBoxFunc pfn = (MessageBoxFunc)proc;
        pfn(nullptr, L"Hello", L"DLL", MB_OK);
    }

    FreeLibrary(hUser32);
    return 0;
}
```

这里的关键：

- `GetProcAddress` 返回导出函数地址
- 必须知道函数名和调用约定
- 这属于显式链接（explicit linking）

显式链接常用于：

- 插件架构
- 运行时功能选择
- 特定系统 API 的动态调用
- 降低启动依赖

### 14.5 `DLLMain`：模块初始化与清理

DLL 中最关键的入口函数是 `DllMain`：

```cpp
#include <windows.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {
    switch (fdwReason) {
    case DLL_PROCESS_ATTACH:
        // 进程加载 DLL 时执行
        break;
    case DLL_PROCESS_DETACH:
        // 进程卸载 DLL 时执行
        break;
    case DLL_THREAD_ATTACH:
        // 线程创建时执行
        break;
    case DLL_THREAD_DETACH:
        // 线程退出时执行
        break;
    }
    return TRUE;
}
```

`DllMain` 里要非常小心：

- 不要做复杂的初始化工作
- 不要调用可能触发加载其他 DLL 的代码
- 不要在这里执行耗时操作
- 不要在初始化期间做大量日志或 UI 操作

这是因为 DLL 在加载过程中处于非常脆弱的状态。Windows 的模块加载机制要求它尽量轻量。

### 14.6 导出和导入：DLL 的接口设计

一个 DLL 通常对外提供导出函数，常用方法是：

- `__declspec(dllexport)`
- .def 文件中声明导出符号

例如：

```cpp
extern "C" __declspec(dllexport) int Add(int a, int b) {
    return a + b;
}
```

调用方通过：

```cpp
HMODULE hMod = LoadLibraryW(L"demo.dll");
using AddFunc = int(*)(int, int);
AddFunc add = (AddFunc)GetProcAddress(hMod, "Add");
```

设计 DLL 接口时要注意：

- 明确导出函数名和签名
- 尽量避免依赖复杂 C++ 名称修饰
- 如果 C++ 编译器参与，最好用 `extern "C"`
- 对二进制兼容性做长期规划

### 14.7 DLL 搜索路径与模块解析

Windows 在加载 DLL 时会按一定顺序搜索文件：

- 应用程序目录
- 当前工作目录
- 系统目录
- Windows 目录
- PATH 环境变量

这意味着：

- 如果你把 DLL 放在错误位置，`LoadLibraryW` 可能失败
- 依赖管理和路径处理非常重要
- 依赖缺失通常表现为 `ERROR_MOD_NOT_FOUND`

处理方式：

- 把 DLL 放在适当目录
- 使用 `SetDllDirectoryW` 进行自定义搜索路径
- 使用显式路径 `LoadLibraryW(L"C:\\path\\to\\lib.dll")`

### 14.8 运行时模块加载的实际价值

DLL 的意义远远不止“共享库”。它使 Windows 程序具备：

- 模块化开发
- 插件机制
- 按需加载功能
- 缩小 EXE 体积
- 运行时扩展能力

大量真实程序都依赖 DLL：

- 系统组件
- 图形驱动
- 语言运行时
- 插件式编辑器
- 扩展工具和脚本环境

### 14.9 DLL 与 PE 文件格式关系

DLL 本质上是 PE（Portable Executable）文件格式的一种。PE 文件包括：

- DOS 头
- NT 头
- 节区表
- 导入表
- 导出表
- 重定位表

只要理解了 PE 结构，你就能理解：

- 为什么 DLL 能被加载
- 为什么符号表会影响导出
- 为什么依赖库需要被解析
- 为什么库版本和路径很关键

这也是从 Win32 入门走向更底层 Windows 机制的重要一步。

### 14.10 DLL 与进程/线程的结合

DLL 往往和进程、线程密切关系：

- 一个 DLL 可以被多个进程同时加载
- 每个线程都可能进入 `DllMain`
- 线程和进程加载时的初始化逻辑不一样
- 资源初始化、锁和同步需要特别小心

例如：

- 一个插件 DLL 在多个进程中安装时需要考虑线程安全
- 全局变量可能在进程内共享
- 线程本地存储（TLS）可用于线程特有状态

### 14.11 常见的 DLL 设计注意事项

- 不要使用 DLL 作为“文件更随便放进去就行”的方案
- 不要假设所有加载都成功
- 对 `GetProcAddress` 返回值必须检查
- 如果 DLL 依赖别的 DLL，要保证依赖链完整
- 在卸载时避免出现引用计数错误

### 14.12 总结

Win32 DLL 与模块加载机制是 Windows 编程中非常核心的一部分。它让程序从一个单体 EXE 变成可以被模块化、扩展和复用的架构。掌握 DLL 后，你就已经开始理解：

- 模块如何被 Windows 加载
- 程序如何调用别的组件
- 导出函数与导入表如何连接
- 为什么 `LoadLibraryW`、`GetProcAddress`、`FreeLibrary` 是底层程序设计的基础

如果你已经熟悉窗口编程、线程和同步，再继续学习 DLL，会让你对 Windows 应用的真实结构理解更完整。

## 15. 进程管理：理解 Windows 任务模型

Win32 API 不只是窗口编程，它也提供了强大的系统级管理能力，其中最重要的是进程管理。所谓“进程”，就是程序的执行实例；它拥有自己的地址空间、线程、句柄和资源。学习 Win32 API 时，理解进程模型非常关键，因为它决定了程序是如何被操作系统调度与管理的。

### 15.1 进程的基本概念

在 Windows 中，进程和线程是分开的：

- 进程：一个程序运行时占用的资源集合。
- 线程：进程内执行代码的最小单元。
- 句柄：系统对象的标识符。
- 进程 ID（PID）：系统内唯一标识一个进程。

一个进程至少包含：

- 代码和数据的内存空间
- 一个主线程
- 资源句柄（文件句柄、窗口句柄、事件对象等）
- 一个独立的安全上下文

常见的核心进程 API 包括：

- `CreateProcessW`：启动新进程
- `CreateToolhelp32Snapshot`：抓取系统进程快照
- `Process32FirstW` / `Process32NextW`：枚举进程
- `OpenProcess`：打开已有进程句柄
- `GetCurrentProcessId`：获得当前进程 PID
- `GetExitCodeProcess`：查询进程退出状态
- `TerminateProcess`：强制结束进程
- `WaitForSingleObject`：等待进程结束

### 15.2 使用 `CreateToolhelp32Snapshot` 进行进程枚举

这是最常见、最稳定的 Win32 进程枚举方式。它本质上是抓取一个“快照”，然后遍历系统中的进程记录。

```cpp
#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>

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

这里的关键点：

- `TH32CS_SNAPPROCESS` 表示枚举进程快照
- `PROCESSENTRY32W` 中有 `th32ProcessID` 和 `szExeFile`
- `Process32FirstW` / `Process32NextW` 遍历所有记录

应用场景：

- 任务管理器式程序
- 进程监控器
- 杀毒/安全扫描器
- 系统诊断工具

### 15.3 使用 `CreateProcessW` 启动新进程

如果你的程序想“启动另一个应用”，最常用的是 `CreateProcessW`。它不仅能启动程序，还能设置工作目录、环境变量、进程优先级和窗口显示方式。

```cpp
#include <windows.h>

void StartNotepad() {
    wchar_t cmd[] = L"notepad.exe";
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = {};

    BOOL ok = CreateProcessW(
        nullptr,
        cmd,
        nullptr,
        nullptr,
        FALSE,
        0,
        nullptr,
        nullptr,
        &si,
        &pi);

    if (!ok) {
        return;
    }

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
}
```

要点：

- 第一个参数是可执行文件路径；如果传 `nullptr`，系统会使用命令行字符串中指定的程序
- 第二个参数是一份可修改的命令行缓冲区，通常需要可写
- `STARTUPINFO` 控制子进程的窗口属性
- `PROCESS_INFORMATION` 返回子进程的句柄和 Pid

这是很多“启动器”“脚本执行器”“桌面工具管理器”都依赖的基本 API。

### 15.4 `OpenProcess` 与进程句柄

如果程序已经知道某个 PID，但需要对该进程进行进一步管理，就需要打开句柄：

```cpp
HANDLE hProcess = OpenProcess(
    PROCESS_QUERY_INFORMATION | PROCESS_TERMINATE,
    FALSE,
    pid);
```

常用权限选项：

- `PROCESS_QUERY_LIMITED_INFORMATION`：查询基本状态
- `PROCESS_TERMINATE`：允许结束进程
- `PROCESS_VM_READ`：读取另一个进程内存
- `PROCESS_VM_OPERATION`：操作另一个进程内存
- `SYNCHRONIZE`：等待进程结束

注意：

- 这些权限由安全描述符控制，不能无条件访问所有进程
- 终止系统关键进程非常危险，必须谨慎使用
- 正常程序通常只需要读取当前进程或自己启动的子进程

### 15.5 等待和退出状态：`WaitForSingleObject` / `GetExitCodeProcess`

有时你启动了子进程后，需要等待它结束，或者检查退出码：

```cpp
DWORD waitResult = WaitForSingleObject(pi.hProcess, INFINITE);
if (waitResult == WAIT_OBJECT_0) {
    DWORD exitCode = 0;
    if (GetExitCodeProcess(pi.hProcess, &exitCode)) {
        wprintf(L"Process exited with code: %lu\n", exitCode);
    }
}
```

这些 API 很适合：

- 执行外部命令并等待其结束
- 构建包装器程序
- 编译器/构建脚本托管工具
- 自动化工具链控制器

### 15.6 `TerminateProcess`：强制结束进程

有时需要在程序中“杀掉”一个进程，例如：

```cpp
HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
if (hProcess) {
    TerminateProcess(hProcess, 1);
    CloseHandle(hProcess);
}
```

它是强制退出，类似“硬关闭”，不会给进程机会清理自己。常用于：

- 任务管理器式工具
- 自动化测试清理
- 批量脚本管理
- 临时资源清理

但它本质上是不优雅的停止方式，通常不建议用于正常业务逻辑；更好的做法是：

- 发送窗口关闭消息
- 让程序自行退出
- 仅在必要时才调用 `TerminateProcess`

### 15.7 进程 API 的典型使用路线

一个典型的进程管理流程可以概括为：

1. `CreateToolhelp32Snapshot` 取快照
2. `Process32FirstW` / `Process32NextW` 遍历所有进程
3. 用 `OpenProcess` 打开需要访问的目标进程
4. 使用 `GetExitCodeProcess` / `WaitForSingleObject` 检查状态
5. 在必要时用 `TerminateProcess` 结束它
6. `CloseHandle` 及时释放句柄

这套模式非常适合做：

- 系统状态查看器
- 资源管理器型工具
- 进程清理工具
- 自动化运行器

### 15.8 实战案例：进程管理窗口

本目录中的 `08_process_manager` 示例演示了更完整的进程管理流程：

- 列出当前所有进程
- 启动 `notepad.exe`
- 选择某个 PID 并终止它

核心代码流：

```cpp
HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
PROCESSENTRY32W pe = { sizeof(pe) };
if (Process32FirstW(snapshot, &pe)) {
    do {
        wprintf(L"%lu - %ls\n", pe.th32ProcessID, pe.szExeFile);
    } while (Process32NextW(snapshot, &pe));
}
CloseHandle(snapshot);
```

然后启动新进程：

```cpp
STARTUPINFOW si = { sizeof(si) };
PROCESS_INFORMATION pi = {};
CreateProcessW(nullptr, L"notepad.exe", nullptr, nullptr, FALSE, 0, nullptr, nullptr, &si, &pi);
CloseHandle(pi.hThread);
CloseHandle(pi.hProcess);
```

最后通过选择 PID 终止：

```cpp
DWORD pid = 0;
HANDLE process = OpenProcess(PROCESS_TERMINATE | SYNCHRONIZE, FALSE, pid);
if (process) {
    TerminateProcess(process, 1);
    CloseHandle(process);
}
```

这个示例的意义在于：它不是“单纯看一眼进程列表”，而是把 Win32 进程 API 真正组合成一个可操作的工具。

### 15.9 进程管理中的注意事项

做 Win32 进程编程时，尤其要注意：

- 不要对系统进程执行任意终止
- 句柄必须 `CloseHandle`
- `CreateProcessW` 传入命令行时，要保证缓冲区可写
- 处理错误时优先检查 `GetLastError()`
- 进程访问权限取决于当前用户和安全策略

### 15.10 总结

Win32 API 的进程管理能力，是 Windows 系统编程的重要基础。它让程序从“只会画窗口”升级到“能管理系统任务”。

如果你掌握了：

- 列举进程
- 启动进程
- 监控退出状态
- 终止进程
- 处理句柄与权限

你就已经真正触碰到 Windows 进程模型的核心。

## 16. 内存管理：理解堆、虚拟内存和对象生命周期

Win32 API 中，内存管理并不是简单的 `malloc` / `free`。在 Windows 上，程序的内存主要以“虚拟内存”和“堆”两种形式存在。理解这两者，才能认真理解 Windows 程序的资源模型。

### 16.1 进程内存模型

现代 Windows 程序的内存模型有三个层次：

- 代码段：程序指令和静态代码
- 数据段：全局变量、静态变量、常量
- 堆 / 栈：动态内存与函数调用栈

其中：

- 栈：函数调用产生的局部变量和返回地址
- 堆：动态分配的内存，如 `malloc`、`new`
- 虚拟内存：系统给进程映射的地址空间

### 16.2 `VirtualAlloc` / `VirtualFree`

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

### 16.3 `GlobalMemoryStatusEx`

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

### 16.4 操作系统基础知识：页、地址空间、提交与保留

理解 Win32 内存 API，必须站在操作系统的视角来看。Windows 中，进程并不是直接在物理内存上“随机分配”；它看到的是一个大规模的虚拟地址空间。

#### 1）虚拟地址空间

每个进程都有自己的虚拟地址空间。这个地址空间看起来像一整块连续地址区域，但它并不一定与物理内存一一对应。Windows 通过分页机制把虚拟地址映射到物理页帧上。

因此：

- 进程 A 的 0x00007FF... 并不等于进程 B 的同一个地址
- 程序编写时看到的是“连续地址”，但物理上可能分散在不同页框
- 该机制是现代操作系统安全与隔离的基础

#### 2）页（Page）

Windows 以页为单位管理内存。常见页大小是：

- 4 KB（x86 / x64 的标准页大小）
- 2 MB（大页，需特殊调用）

虚拟内存分配常说“保留”和“提交”：

- `MEM_RESERVE`：保留一段虚拟地址空间，但不实际分配页帧
- `MEM_COMMIT`：真正分配物理页并承诺可使用

这意味着程序可以先保留大空间，再按需提交，适合大数组、缓存、对象池等场景。

#### 3）页保护（Page Protection）

每一页还有权限：

- `PAGE_READONLY`
- `PAGE_READWRITE`
- `PAGE_EXECUTE_READ`
- `PAGE_NOACCESS`

这些权限控制一个页面能否读、写、执行。安全机制和防止越界访问都依赖这种分页保护。

#### 4）堆 vs 虚拟内存

- `VirtualAlloc` 适合底层对象池、缓存、共享内存、系统组件
- `new / malloc` 通常来自 C/C++ 运行时堆，底层往往又依赖进程堆
- 程序堆是系统为进程提供的更高层抽象；它管理对象分配和释放

因此，Win32 编程允许你在不同层次控制内存：从高层堆，到中层虚拟内存，再到底层页保护和映射。

### 16.5 详细 API：`VirtualProtect`、`HeapAlloc`、`GlobalAlloc`、映射文件

#### 1）`VirtualProtect`：改变页属性

有时一个页面刚分配时是可读写的，但你可能想把它临时设为只读，或在执行缓存时设置可执行权限：

```cpp
void* p = VirtualAlloc(nullptr, 4096, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
DWORD oldProtect = 0;
VirtualProtect(p, 4096, PAGE_READONLY, &oldProtect);
```

这个 API 在：

- 运行时安全检测
- 动态代码生成 / JIT
- 内存写保护
- 实现页面级保护策略

时非常重要。

#### 2）`HeapAlloc` / `HeapFree`：进程堆

C/C++ 运行时的堆通常是进程堆的一层封装。Win32 也允许直接使用：

```cpp
HANDLE heap = GetProcessHeap();
void* p = HeapAlloc(heap, HEAP_ZERO_MEMORY, 4096);
if (p) {
    strcpy_s((char*)p, 4096, "hello");
    HeapFree(heap, 0, p);
}
```

进程堆适合：

- 需要大量对象分配的应用
- 运行库实现
- 数据结构容器
- 长生命周期对象池

#### 3）`GlobalAlloc` / `LocalAlloc`：旧式全局内存

这些 API 是历史比较早的 Win32 内存接口：

```cpp
HGLOBAL hMem = GlobalAlloc(GMEM_FIXED, 1024);
char* p = (char*)GlobalLock(hMem);
strcpy_s(p, 1024, "global memory");
GlobalUnlock(hMem);
GlobalFree(hMem);
```

它们的含义：

- `GlobalAlloc`：全局堆分配
- `LocalAlloc`：局部堆分配
- 这些接口如今通常只是兼容性支持；现代代码更倾向于 `new`、`malloc` 或堆 API

#### 4）文件映射：`CreateFileMapping` / `MapViewOfFile`

Win32 中非常强大的内存技巧是“内存映射文件”。它让文件内容像内存一样访问，而不是传统的 `ReadFile` / `WriteFile` 轮询：

```cpp
HANDLE hFile = CreateFileW(L"C:\\tmp\\memdemo.txt", GENERIC_READ | GENERIC_WRITE,
    0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

HANDLE hMapping = CreateFileMappingW(hFile, nullptr, PAGE_READWRITE, 0, 4096, L"DemoMem");
void* p = MapViewOfFile(hMapping, FILE_MAP_ALL_ACCESS, 0, 0, 4096);

strcpy_s((char*)p, 4096, "Mapped file memory");
UnmapViewOfFile(p);
CloseHandle(hMapping);
CloseHandle(hFile);
```

这类技术用于：

- 大文件访问
- 共享内存
- IPC（进程间通信）
- 高效缓存和数据共享

它的本质是：让“文件”和“内存”之间建立映射关系，减少复制成本。

#### 5）`GetProcessMemoryInfo`：查看进程真实内存占用

如果要看某个进程的工作集（working set）、峰值内存等，可以用：

```cpp
PROCESS_MEMORY_COUNTERS pmc = {};
pmc.cb = sizeof(pmc);
if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
    printf("WorkingSetSize: %llu KB\n", pmc.WorkingSetSize / 1024ULL);
    printf("PeakWorkingSetSize: %llu KB\n", pmc.PeakWorkingSetSize / 1024ULL);
}
```

这是系统诊断工具、监控程序、性能观察器的常见用法。它不是“系统总内存”，而是“当前进程的内存占用情况”。

### 16.6 OS 视角：为什么要掌握这些 API

从操作系统角度理解，Win32 内存 API 其实对应着三种不同层次：

1. 用户态对象：堆、句柄、C/C++ 分配器
2. 进程虚拟地址空间：VirtualAlloc、VirtualProtect
3. 系统级物理资源：页面框架、分页、交换文件、共享映射

这样看，Win32 内存管理就不再只是“申请一块内存”，而是：

- 申请虚拟地址
- 维护分页保护
- 绑定到页表
- 可能映射到物理内存或文件
- 通过系统对象和进程空间安全隔离

这恰恰是操作系统最核心的思想之一：把真实资源抽象成安全、受控、可管理的对象。Windows 程序员如果只用 `new` / `malloc`，只能看到最表层；但如果学会 `VirtualAlloc`、`VirtualProtect`、`CreateFileMapping`，就会真正理解操作系统是如何管理程序内存的。

### 16.7 实战案例：内存管理深度示例

本目录中的 `12_memory_deep_dive` 示例演示了更完整的内存管理组合：

- `GlobalMemoryStatusEx`：查看系统总可用内存
- `GetSystemInfo`：查看页面大小和 CPU 架构信息
- `VirtualAlloc`：保留并提交一段虚拟内存
- `VirtualProtect`：将一段内存设置为只读
- `HeapAlloc`：使用进程堆进行对象分配
- `GetProcessMemoryInfo`：查看当前进程工作集
- `CreateFileMappingW` / `MapViewOfFile`：映射共享内存

这不是一个“只会输出数字”的程序，它把 Windows 内存的几个核心层次串起来了：

- 物理内存状态
- 虚拟地址空间
- 页保护
- 进程堆
- 文件映射

这正是一个真正理解操作系统内存模型的关键步骤。

### 16.8 内存管理中的注意事项

在 Win32 程序里，内存管理不是“随便开个 buffer 就行”的事情，需要注意：

- `VirtualAlloc` 申请的内存必须配套 `VirtualFree`
- `HeapAlloc` 必须对应 `HeapFree`
- `CreateFileMapping` / `MapViewOfFile` 需要成对使用，并在合适时 `UnmapViewOfFile`
- 使用 `VirtualProtect` 时，要保留旧保护属性，避免破坏原有设置
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

### 15.5 从操作系统视角看文件系统：抽象、缓存、对象和命名空间

Win32 文件 API 让程序员看起来像是在直接操作“文件”，但从操作系统的角度看，它其实是和非常底层的文件子系统打交道。

#### 1）文件对象与句柄

在 Windows 中，打开一个文件并不只是“拿到一个字符串路径并读取内容”，而是：

- 解析路径
- 访问对象管理器 / 文件系统驱动
- 分配一个 `FILE_OBJECT`
- 返回一个 `HANDLE`

因此，`HANDLE` 本质上是对系统资源的引用。打开文件后，后续的 `ReadFile`、`WriteFile`、`SetFilePointerEx` 都是围绕这个对象进行的。

#### 2）命名空间与卷管理

Windows 的文件系统由多个“卷”组成，例如：

- `C:`
- `D:`
- `E:`
- 网络共享 / UNC 路径（如 `\\server\share`）

每个卷可能使用不同的文件系统：

- NTFS
- ReFS
- FAT32
- exFAT
- 网络文件系统（SMB/CIFS）

这说明 Windows 文件系统不是一个单一的实现，而是一组统一的命名空间抽象。应用层只看到路径和句柄，真正的底层实现由卷管理器和文件系统驱动完成。

#### 3）缓存与 I/O 管理器

Windows 不会每次读 1 字节都直接打到磁盘。它通常通过：

- 页缓存
- 文件缓存
- I/O 管理器
- 读写队列和异步 I/O

来提高效率。写入并不一定瞬间落盘，系统会在合适时机刷新缓存和日志，尤其在 NTFS 下，这种设计是保证一致性和崩溃恢复的重要基础。

#### 4）权限与 ACL

文件不仅是数据容器，还带有：

- ACL（访问控制列表）
- 所有者
- 安全描述符
- 共享模式

因此，`CreateFileW` 的 `dwDesiredAccess` 和 `dwShareMode` 远不只是“读写权限”，还涉及安全策略、共享冲突和权限检查。

### 15.6 NTFS 文件系统：Windows 最核心的文件实现

NTFS（New Technology File System）是 Windows 上最重要的本地文件系统之一。它不仅支持文件和目录，还提供了很多系统级特性，很多 Win32 API 本质上就是暴露 NTFS 语义的接口。

#### 1）MFT（Master File Table）

NTFS 的核心结构之一是 MFT。它维护每个文件和目录的元数据，例如：

- 文件 ID
- 创建时间、修改时间、访问时间
- 文件大小
- 记录属性
- 目录关系
- 硬链接与索引

你可以把 MFT 想象成“文件系统目录中的总目录表”。

#### 2）簇与分配单元

NTFS 不是以“字节”直接在裸磁盘上来管理文件；它以“簇（cluster）”作为最小分配单位。

例如：

- 一个文件 1 KB
- 但分配单元可能 4 KB

那么文件会占据至少一个簇，或者多个簇。这样的设计提高了管理效率，也让 NTFS 能更好的处理稀疏文件和碎片整理。

#### 3）文件属性与元数据

NTFS 中的文件会有大量属性：

- 标准信息
- 文件名
- 安全描述符
- 数据流
- 压缩/加密属性
- Reparse Point
- 硬链接

这也是为什么 Win32 里有 `GetFileAttributesW`、`GetFileInformationByHandle` 等 API：它们并不是在读“一个文本文件”，而是在读取文件系统的元数据。

#### 4）日志与事务性

NTFS 采用日志（journal）机制来保证文件系统崩溃后仍可恢复。它的一些核心思想：

- 先记录变更日志
- 再执行实际数据更新
- 若系统崩溃，可回放日志恢复一致性

这也是 NTFS 相较于早期 FAT 系统更稳健的重要原因。

#### 5）压缩、加密、重解析点和 ADS

NTFS 还支持：

- 文件压缩：减少占用空间
- EFS（Encrypting File System）：加密文件内容
- Reparse Point：挂载点、符号链接、目录联接
- Alternate Data Streams（ADS）：一个文件有多个数据流

其中 ADS 是非常典型的 Windows 特性：

```text
C:\demo\file.txt
C:\demo\file.txt:stream1
```

这看起来像一个文件，但实际上可能是同一个文件的多个数据流，常用于兼容性与扩展。对于安全审计和恶意软件检测来说，这非常关键。

### 15.7 更完整的文件 API：`GetFileInformationByHandle`、`GetFinalPathNameByHandleW`、`SetFilePointerEx`

除了简单的 `CreateFileW` / `ReadFile` / `WriteFile` 之外，Win32 还提供了大量更底层的文件控制 API：

#### 1）`GetFileInformationByHandle`

这个 API 能拿到文件句柄对应的详细信息：

```cpp
BY_HANDLE_FILE_INFORMATION info = {};
if (GetFileInformationByHandle(hFile, &info)) {
    printf("File attributes: 0x%X\n", info.dwFileAttributes);
    printf("Volume serial number: %u\n", info.dwVolumeSerialNumber);
    printf("File index high: %u\n", info.nFileIndexHigh);
}
```

这使程序可以访问：

- 目标卷序列号
- 文件属性
- 创建/修改时间
- 文件索引（更接近 NTFS 级别的文件标识）

#### 2）`GetFinalPathNameByHandleW`

如果你拿到了文件句柄，但不知道最终的完整路径，可以这样获取：

```cpp
wchar_t path[MAX_PATH];
DWORD len = GetFinalPathNameByHandleW(hFile, path, MAX_PATH, FILE_NAME_NORMALIZED);
```

这对：

- 系统监控程序
- 日志工具
- 文件管理器
- 诊断工具

都非常有用。

#### 3）`SetFilePointerEx` / `SetEndOfFile`

这属于更底层的文件定位与伸缩：

```cpp
LARGE_INTEGER pos;
pos.QuadPart = 1024;
SetFilePointerEx(hFile, pos, nullptr, FILE_BEGIN);
SetEndOfFile(hFile);
```

它能够：

- 移动文件指针
- 直接写入固定偏移
- 压缩或扩展文件大小
- 为二进制格式和数据库文件设计更底层的 I/O

### 15.8 目录与文件系统对象：`CreateDirectoryW`、`MoveFileW`、`DeleteFileW` 以及真实工程语义

Win32 文件 API 还包含大量目录和对象维护接口：

- `CreateDirectoryW`
- `RemoveDirectoryW`
- `MoveFileW`
- `CopyFileW`
- `DeleteFileW`
- `GetFileAttributesExW`
- `SetFileAttributesW`

这些 API 在工程中具有非常现实的价值：

- 保存配置目录
- 创建日志目录
- 监控文件更新
- 实现批量处理工具
- 自动整理文件

#### 例子：读取目录项并显示文件属性

```cpp
WIN32_FIND_DATAW fd;
HANDLE hFind = FindFirstFileW(L"C:\\temp\\*", &fd);
if (hFind != INVALID_HANDLE_VALUE) {
    do {
        DWORD attr = fd.dwFileAttributes;
        wprintf(L"%ls | attributes=0x%08X | size=%llu\n",
            fd.cFileName, attr, fd.nFileSizeLow);
    } while (FindNextFileW(hFind, &fd));
    FindClose(hFind);
}
```

这种操作能够让程序意识到：目录列表并不只是“文件名数组”，而是文件系统对象的真实元数据集合。

### 15.9 文件系统与 NTFS 的工程意义

如果你只是知道 `fopen` / `open` / `read`, 你看到的是一个抽象层；而如果你学习 Win32 文件 API，你会真正接触到：

- 文件对象模型
- 路径解析
- 安全描述符
- 属性和时间戳
- 目录遍历
- NTFS 的扩展能力

这也是 Windows 编程和 Unix-like 编程最大的区别之一：Windows 的文件系统 API 更强调“对象语义”和“系统级接口”，而不是只给出一个简单的 C 标准 I/O 抽象。

### 15.10 目录中的 NTFS 深入示例

本目录中的 `13_file_system_deep_dive` 示例演示了：

- 当前目录扫描
- `GetFileAttributesExW` 读取文件属性
- `GetFileInformationByHandle` 获取更深入的元数据
- `CreateFileW` 打开和写入文件
- 显示时间、大小、属性和句柄信息

它能够帮助你从“会写文件”提升到“理解文件系统对象和 NTFS 元数据”。

### 15.11 文件管理中的注意事项

文件系统编程最容易犯的错误包括：

- 路径错误或 UNC 路径不正确
- 使用错误的访问权限和共享模式
- 忘记 `CloseHandle`
- 未检查 `GetLastError()`
- 直接假设 `ReadFile` / `WriteFile` 一次就完成全部数据
- 忽略文件属性与 ACL 语义

这些问题在不同文件系统、网络共享和 NTFS 特性下都会比简单文本 I/O 更明显。

### 15.12 总结

Win32 文件系统 API 是 Windows 程序真正与系统打交道的入口之一。它不只是“读写文件”，而是：

- 管理路径和命名空间
- 处理文件对象与句柄
- 访问 NTFS 元数据和属性
- 应用权限和共享规则
- 处理目录、卷和缓存语义

如果你已经熟悉窗口、线程和内存，再学习文件系统，你就会看到 Windows 编程从“用户界面”和“业务逻辑”进一步延伸到“系统级资源管理”。

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
