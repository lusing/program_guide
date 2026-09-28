# WinUI 3 教程第五轮扩充：按《Learn WinUI 3》(Alivin Ashcraft, 2nd ed., zh) 扩到 43 章

日期：2026-09-28。教材：`G:\book\计算机\Windows\Learn WinUI 3 - zh (...).pdf`（241 页 14 章，C#/.NET 向）。
本轮把书里 C++/WinRT 可承接的内容全部翻译成 C++ 落地，指南 35 → 43 章。

## 书 ↔ 章映射与裁决

| 书章 | 主题 | 裁决 |
|---|---|---|
| 1 WinUI 简介与框架对比 | 已覆盖（01 章），就地补对比表 | 就地 |
| 2 环境与首个项目 | 已覆盖（04/05） | 不动 |
| 3-4 MVVM/ICommand/DI/导航服务 | **新 36 章**（C++ 化：XamlUICommand、手写 DI、导航服务） | 新章+扩 32 例 |
| 5 控件巡视 | 已覆盖（07-16） | 不动 |
| 6 生命周期+SQLite+服务 | **新 37 章**（sqlite3 C API 合并文件直编） | 新章+新例 |
| 7 Fluent 设计/亚克力/云母 | **新 38 章**（原则/排版 ramp/in-app acrylic 画刷/Theme Editor） | 新章 docs |
| 8 通知（推送+应用通知） | **新 39 章**（AppNotificationBuilder C++、unpackaged Register(displayName,icon)） | 新章+扩 34 例 |
| 9 WCT / 10 Template Studio | **新 43 章**生态综述（C++ 视角：不可用/替代） | 新章 docs |
| 11 调试（绑定失败/LVT/LPR/热重载） | **新 41 章**（+我们的 stowed exception 战争史） | 新章 docs |
| 12 Blazor+WebView2 | **新 40 章**（WebView2 C++ 全解；Blazor 部分归 43 概述） | 新章+新例 |
| 13 Uno Platform | 归 43 章生态 | docs |
| 14 打包/winget/Store/旁加载 | **新 42 章**（命令行 makeappx+signtool+自签名+Add-AppxPackage 实测） | 新章+实测 |

## 示例工程

- **新 `37-media-library`**：书的 My Media Collection 的 C++ 复刻核心。列表+类型过滤 ComboBox+增删按钮+SQLite 持久化（vendored sqlite3.c 3530400）。数据目录 `%LOCALAPPDATA%\MediaLibrary\media.db`（unpackaged 无 ApplicationData，34 章结论复用）。
- **新 `40-webview-host`**：WebView2 控件 + URL 导航 + NavigateToString 本地页 + ExecuteScriptAsync + WebMessage 双向。
- **扩 `32-binding-mvvm`**：MainWindow 加 XamlUICommand/StandardUICommand 命令区（ExecuteRequested/CanExecuteRequested）。
- **扩 `34-os-integration`**：加"发送应用通知"区（AppNotificationManager.Register(displayName,iconUri) unpackaged 路线 + NotificationInvoked 回显）。
- 38/41/42/43 docs 为主；42 的打包实测以 37 的构建产物为对象。

## 验证

- 编译级：build.ps1 全量（12 工程）。
- 运行时级：37 启动→种子数据→增删→重启持久（状态行铁证）；40 导航+消息回显；34 通知出现在 Action Center（人工/截图）。
- 打包级：42 章 makeappx+signtool+证书信任+Add-AppxPackage 安装运行+Remove-AppxPackage 卸载，全程命令行留档。
- 诚实边界照旧：没驱动的流程只到编译级。

## 就地修改

- README：目录表加 36-43、学习路线、验证状态、速查表新增条目、"后续扩展方向"划掉已交付项、新增与本书对照表。
- 33.6 → 指向 42；31.3 → 指向 38；01 → 补 WinUI vs UWP/WPF/WinForms 对比表。
