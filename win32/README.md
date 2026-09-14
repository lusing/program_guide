# Win32 API 开发指南示例集

本目录按 `guide` 统一标准整理了 Win32 API 教程中的可编译示例，并使用本机 Visual Studio VC 工具链进行验证。

## 目录结构

```text
win32/
├── README.md
├── Win32 API开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello_window/
│   │   └── main.cpp
│   ├── 02_message_loop/
│   │   └── main.cpp
│   ├── 03_controls/
│   │   └── main.cpp
│   └── 04_gdi_drawing/
│       └── main.cpp
├── build/
└── ...
```

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MSVC SDK：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\include`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

## 编译与验证

```powershell
cd G:\code\guide\win32
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -File 02_message_loop\main.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

## 示例说明

- `01_hello_window`：WinMain + RegisterClass + CreateWindow + 消息循环的最小窗口应用。
- `02_message_loop`：处理 `WM_LBUTTONDOWN`、`WM_MOUSEMOVE`、`WM_CHAR` 等消息示例。
- `03_controls`：使用 `CreateWindowW` 创建按钮、编辑框和静态文本控件。
- `04_gdi_drawing`：使用 GDI 在 `WM_PAINT` 中绘制矩形、圆形和文本。

## 说明

- Win32 API 是 Windows 平台上的底层编程接口，适合理解窗口消息、控件和 GDI 的核心机制。
- 本目录采用本机 MSVC 工具链进行编译验证，保证示例在当前环境中能通过实际编译。
- 由于窗口程序依赖桌面环境，本文档以编译验证为主；在无桌面会话环境下不直接运行窗口，但确保代码可通过本机编译器成功构建。
