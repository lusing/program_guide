# MFC 开发指南

一套从零开始的 MFC（Microsoft Foundation Classes）实用教程：25 章正文 + 23 个可编译运行的示例（含 1 个实战项目）。所有示例在本机 Visual Studio / MSVC 工具链上编译、链接并运行验证。

## 快速开始

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All                # 构建全部示例（含资源编译与链接）
.\build.ps1 -File 04_resources  # 构建单个示例
.\build.ps1 -File 25_notepad_plus -Static   # 静态链接版（第 23 章部署对比）
.\build.ps1 -Clean              # 清理 build 目录
```

产物在 `build\<示例名>.exe`，可直接双击运行。`smoke.ps1` 对全部 23 个示例做启动冒烟验证。

## 目录结构

```text
mfc/
├── README.md            # 本文件
├── build.ps1            # 一键构建脚本（cl + rc + link，支持 -Static）
├── smoke.ps1            # 启动冒烟测试（构建产物全部拉起一遍）
├── docs/                # 教程正文（25 章，章号 = 示例号）
│   ├── 01-overview.md            # MFC 概述与开发环境
│   ├── 02-app-lifecycle.md       # 应用骨架与消息循环
│   ├── 03-message-map.md         # 消息映射机制
│   ├── 04-resources.md           # 资源文件入门
│   ├── 05-frames.md              # 窗口与框架类
│   ├── 06-dialogs.md             # 对话框：模态、非模态与 DDX
│   ├── 07-controls.md            # 常用控件深入
│   ├── 08-controls-advanced.md   # 控件进阶
│   ├── 09-custom-controls.md     # 自定义控件与自绘
│   ├── 10-common-dialogs.md      # 通用对话框与文件 IO/编码
│   ├── 11-toolbars.md            # 工具栏与状态栏
│   ├── 12-clipboard-dnd.md       # 剪贴板与拖放
│   ├── 13-shell-integration.md   # 系统集成（注册表/文件关联/单实例）
│   ├── 14-dpi-darkmode.md        # 高 DPI 与深色模式
│   ├── 15-docview.md             # Doc/View 架构
│   ├── 16-mdi-splitter.md        # MDI 多文档与切分窗口
│   ├── 17-serialize.md           # 序列化与 CArchive（含版本兼容）
│   ├── 18-gdi.md                 # GDI 绘图与双缓冲
│   ├── 19-printing.md            # 打印与打印预览
│   ├── 20-threads.md             # 多线程与后台任务
│   ├── 21-debugging.md           # 异常处理、调试与内存诊断
│   ├── 22-modern-drawing.md      # GDI+ 与 Direct2D
│   ├── 23-deployment.md          # 部署：静态/动态链接与打包
│   ├── 24-modern-cpp.md          # MFC 与现代 C++
│   └── 25-notepad-plus.md        # 实战项目：记事本+（全书收束）
└── examples/            # 每章示例（可独立编译运行）
    ├── 01_hello_mfc/           # 最小 MFC 程序骨架
    ├── 02_app_lifecycle/       # InitInstance/消息循环/ExitInstance
    ├── 03_message_map/         # 三类消息与消息映射
    ├── 04_resources/           # .rc 资源：菜单/加速键/字符串表
    ├── 05_frame_layout/        # 窗口创建与 OnSize 自适应布局
    ├── 06_dialog/              # 模态 + 非模态对话框与 DDX
    ├── 07_controls/            # CListCtrl 报表/排序/右键菜单
    ├── 08_controls_advanced/   # 树/组合框/Spin 等进阶控件
    ├── 09_custom_controls/     # Owner-draw 与自绘控件
    ├── 10_common_dialogs/      # CFileDialog/CColorDialog + 文件编码
    ├── 11_toolbar_statusbar/   # 工具栏/状态栏/命令 UI 更新
    ├── 12_clipboard_dnd/       # 剪贴板读写与拖放
    ├── 13_shell_integration/   # 注册表/文件关联/单实例
    ├── 14_dpi_darkmode/        # Per-Monitor V2 DPI 与深色模式
    ├── 15_docview/             # SDI Doc/View 全流程
    ├── 16_mdi_splitter/        # MDI + CSplitterWnd 切分
    ├── 17_serialize/           # CArchive 序列化 + IMPLEMENT_SERIAL 版本
    ├── 18_gdi/                 # GDI 画板 + 双缓冲
    ├── 19_printing/            # 打印五步与预览
    ├── 20_threads/             # worker 线程 + 进度回传 + 取消
    ├── 21_debugging/           # 异常/TRACE/内存泄漏诊断
    ├── 22_modern_drawing/      # GDI+ 与 D2D 双路线切换
    └── 25_notepad_plus/        # 实战项目：记事本+（多模块）
```

（第 23、24 章为专题章：23 复用示例 25 做 -Static 部署实测，24 复用示例 13 的源码做现代 C++ 对照改写，不各配新工程。）

## 学习路线

- **入门（01–05）**：跑起来 → 消息怎么流转 → 界面元素从哪来 → 窗口怎么布局
- **界面（06–09）**：对话框与 DDX → 常用控件 → 控件进阶 → 自定义控件与自绘
- **桌面整合（10–14）**：通用对话框与文件编码 → 工具栏/状态栏 → 剪贴板拖放 → 系统集成 → 高 DPI 与深色模式
- **框架深入（15–17）**：Doc/View → MDI 与切分窗口 → 序列化与版本兼容
- **绘图与系统（18–22）**：GDI 与双缓冲 → 打印 → 多线程 → 调试与内存诊断 → GDI+/Direct2D
- **交付（23–24）**：静态/动态链接与部署 → 现代 C++ 迁移
- **实战（25）**：记事本+，把全部知识串成一个完整应用，附全书知识点索引

建议方式：每章先跑对应的示例 exe 玩一遍，再读正文，最后读示例源码。

## 工具链

| 组件 | 版本 / 路径 |
|---|---|
| Visual Studio | 18 Community |
| MSVC | 14.51.36231 |
| Windows SDK | 10.0.26100.0 |
| MFC | 动态链接为主（`_AFXDLL`，随 VS 安装的 mfc140u.dll）；静态版见第 23 章 |

`build.ps1` 的构建流程：`cl` 编译各 `.cpp` → `rc` 编译 `.rc`（UTF-8，`/c65001`）→ `cl` 链接（`/ENTRY:wWinMainCRTStartup`，Unicode MFC 的入口要求）。`-Static` 开关切到 `/MT`（去 `_AFXDLL`）产出静态链接版；`extraLibsByExample` 白名单处理个别示例的额外库（如 22 的 gdiplus/d2d1/dwrite）。

## 说明

- 所有示例均已实际编译、链接通过，且全部通过 `smoke.ps1` 启动冒烟（存活 23 / 失败 0）
- 示例刻意不用 VS 向导生成的工程文件，保持"每个文件都看得懂"——但资源组织、ID 惯例与真实 VS 工程一致
- 中文环境无特殊要求；.rc 与源码均为 UTF-8（源码 `/utf-8`，资源 `/c65001`）
- 部署相关的体积/依赖数据均为本机实测（第 23 章）：动态版 63 KB，静态版 2.4 MB
