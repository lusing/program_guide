# MFC 开发指南示例集

本目录按 `guide` 统一标准整理了 MFC（Microsoft Foundation Classes）教程中的可编译示例，并使用本机 Visual Studio VC 工具链进行验证。

## 目录结构

```text
mfc/
├── README.md
├── MFC开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello_mfc/
│   │   └── main.cpp
│   └── 02_dialog_demo/
│       └── main.cpp
├── build/
└── ...
```

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MFC 库：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\atlmfc\lib\x64`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

## 编译与验证

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -File 01_hello_mfc\main.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- MFC 是微软提供的 C++ 窗体开发框架，适合 Windows 桌面应用开发。
- 本目录采用本机 MSVC / MFC 工具链进行编译验证，确保示例能在当前 Windows 环境中真实构建。
- 示例覆盖了最小窗口应用、应用对象初始化和框架基础。
