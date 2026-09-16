# MFC 开发指南

一套从零开始的 MFC（Microsoft Foundation Classes）实用教程：13 章正文 + 12 个可编译运行的示例 + 1 个实战项目。所有示例在本机 Visual Studio / MSVC 工具链上编译、链接并运行验证。

## 快速开始

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All                # 构建全部示例（含资源编译与链接）
.\build.ps1 -File 03_resources  # 构建单个示例
.\build.ps1 -Clean              # 清理 build 目录
```

产物在 `build\<示例名>.exe`，可直接双击运行。

## 目录结构

```text
mfc/
├── README.md            # 本文件
├── build.ps1            # 一键构建脚本（cl + rc + link）
├── docs/                # 教程正文（按章组织）
│   ├── 01-overview.md          # MFC 概述与开发环境
│   ├── 02-app-lifecycle.md     # 应用骨架与消息循环
│   ├── 03-message-map.md       # 消息映射机制
│   ├── 04-resources.md         # 资源文件入门
│   ├── 05-frames.md            # 窗口与框架类
│   ├── 06-dialogs.md           # 对话框：模态、非模态与 DDX
│   ├── 07-controls.md          # 常用控件深入
│   ├── 08-common-dialogs.md    # 通用对话框与文件 IO
│   ├── 09-toolbars.md          # 工具栏与状态栏
│   ├── 10-docview.md           # Doc/View 架构
│   ├── 11-gdi.md               # GDI 绘图与双缓冲
│   ├── 12-threads.md           # 多线程与后台任务
│   └── 13-notepad-plus.md      # 实战项目：记事本+
└── examples/            # 每章示例（可独立编译运行）
    ├── 01_hello_mfc/           # 最小 MFC 程序骨架
    ├── 02_message_map/         # 三类消息与消息映射
    ├── 03_resources/           # .rc 资源：菜单/加速键/字符串表
    ├── 04_frame_layout/        # 窗口创建与 OnSize 自适应布局
    ├── 05_dialog/              # 模态 + 非模态对话框与 DDX
    ├── 06_controls/            # CListCtrl 报表/排序/右键菜单
    ├── 07_common_dialogs/      # CFileDialog/CColorDialog + 文件编码
    ├── 08_toolbar_statusbar/   # 工具栏/状态栏/命令 UI 更新
    ├── 09_docview/             # SDI Doc/View 全流程
    ├── 10_gdi/                 # GDI 画板 + 双缓冲
    ├── 11_threads/             # worker 线程 + 进度回传 + 取消
    └── 12_notepad_plus/        # 实战项目：记事本+（多模块）
```

## 学习路线

- **入门（01–05）**：跑起来 → 消息怎么流转 → 界面元素从哪来 → 窗口怎么布局
- **进阶（06–09）**：对话框与 DDX → 控件（重点 CListCtrl）→ 文件与编码 → 菜单/工具栏/状态栏
- **专题（10–12）**：Doc/View 架构 → GDI 绘图与双缓冲 → 多线程
- **实战（13）**：记事本+，把全部知识串成一个完整应用

建议方式：每章先跑对应的示例 exe 玩一遍，再读正文，最后读示例源码。

## 工具链

| 组件 | 版本 / 路径 |
|---|---|
| Visual Studio | 18 Community |
| MSVC | 14.51.36231 |
| Windows SDK | 10.0.26100.0 |
| MFC | 动态链接（`_AFXDLL`，随 VS 安装的 mfc140u.dll） |

`build.ps1` 的构建流程：`cl` 编译各 `.cpp` → `rc` 编译 `.rc`（UTF-8，`/c65001`）→ `cl` 链接（`/ENTRY:wWinMainCRTStartup`，Unicode MFC 的入口要求）。

## 说明

- 所有示例均已实际编译、链接通过；01、03、09、13 还做过启动运行验证
- 示例刻意不用 VS 向导生成的工程文件，保持"每个文件都看得懂"——但资源组织、ID 惯例与真实 VS 工程一致
- 中文环境无特殊要求；.rc 与源码均为 UTF-8（源码 `/utf-8`，资源 `/c65001`）
