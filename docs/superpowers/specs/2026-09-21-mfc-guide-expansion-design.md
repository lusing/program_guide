# MFC 开发指南扩充设计（13 章 → 25 章）

> 日期：2026-09-21　状态：已获用户批准的设计，待写实施计划
> 范围：G:\code\guide\mfc（docs/ 章节正文、examples/ 可编译示例、build.ps1、新增 smoke.ps1、README、根 README 条目）

## 1. 背景与目标

现有教程为 2026-09-16 重构版：**13 章 / 1894 行正文 + 12 个示例**，写得紧凑但容量明显低于同仓库的 WPF 教程（25 章 / 4100 行 / 21 示例）。两类缺口：

- **容量缺口**：正文只有 WPF 的 46%，章节数只有一半；多数专题（打印、剪贴板拖放、MDI、部署、调试）完全缺失。
- **教学骨架缺口**：WPF 每章有「本章你将学会 / 前置知识」开篇与「常见坑 / 实战建议 / 自测」收尾，MFC 只有「对应示例」一行和上下章链接，初学者友好度低。

用户决策（2026-09-21 对话确认）：

1. **重排式**：整体重编号，**章号 = 示例号**（对齐 WPF 惯例）；
2. **每个新章都配可编译运行的新示例**；
3. 四个专题方向全选：控件与界面进阶、Doc/View 进阶 + 打印、系统集成、现代 MFC 与工程化；
4. **第 14 章保留「DPI 感知与深色模式」**（不换成键盘加速键/菜单自绘）；
5. **第 23、24 章复用已有示例源码**（部署章用 `25_notepad_plus` 做静态/动态两套构建；现代 C++ 章把同一程序重构一遍），不硬造全新程序。

## 2. 新章节结构（25 章，★ = 新增）

### 第一篇 起步

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 01 | MFC 概述与开发环境 | `01_hello_mfc` | 扩写（原 01） |
| 02 | 应用骨架与消息循环 | `02_app_lifecycle` | ★ 新增示例（原 02 复用 01，现独立） |
| 03 | 消息映射机制 | `03_message_map` | 扩写（原 03） |
| 04 | 资源文件入门 | `04_resources` | 扩写（原 04） |

### 第二篇 界面构建

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 05 | 窗口与框架类 | `05_frame_layout` | 扩写（原 05） |
| 06 | 对话框：模态、非模态与 DDX | `06_dialog` | 扩写（原 06） |
| 07 | 常用控件深入 | `07_controls` | 扩写（原 07） |
| 08 | ★ 控件进阶：树、属性页与任务对话框 | `08_controls_advanced` | 新增：CTreeCtrl / CPropertySheet 向导 / CTaskDialog / 日期时间与进度控件 |
| 09 | ★ 自绘与自定义控件 | `09_custom_controls` | 新增：owner-draw / custom draw / CWnd 派生自绘控件 / 子类化 |

### 第三篇 系统集成

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 10 | 通用对话框与文件 IO | `10_common_dialogs` | 扩写（原 08） |
| 11 | 菜单、工具栏与状态栏 | `11_toolbar_statusbar` | 扩写（原 09） |
| 12 | ★ 剪贴板与拖放 | `12_clipboard_dnd` | 新增：CF_HDROP/CF_UNICODETEXT 读写、COleDropTarget、拖出 |
| 13 | ★ 文件系统、Shell 与最近文件 | `13_shell_integration` | 新增：CFileFind 递归、CRecentFileList(MRU)、注册表/INI 持久化、单实例互斥体 |
| 14 | ★ DPI 感知与深色模式 | `14_dpi_darkmode` | 新增：DPI 感知级别、按监视器 DPI 缩放、DwmSetWindowAttribute 深色标题栏、WM_SETTINGCHANGE 响应 |

### 第四篇 Doc/View 与绘图

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 15 | Doc/View 架构 | `15_docview` | 扩写（原 10） |
| 16 | ★ MDI 多文档与分割窗口 | `16_mdi_splitter` | 新增：CMultiDocTemplate / CChildFrame / CSplitterWnd 多视图同步 |
| 17 | ★ 序列化深入与文档版本化 | `17_serialize` | 新增：CArchive 自定义类型、IMPLEMENT_SERIAL、版本号与向后兼容读取 |
| 18 | GDI 绘图与双缓冲 | `18_gdi` | 扩写（原 11） |
| 19 | ★ 打印与打印预览 | `19_printing` | 新增：CPrintDialog / OnPrint / 分页 / CPreviewView 打印预览 |

### 第五篇 并发与工程化

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 20 | 多线程与后台任务 | `20_threads` | 扩写（原 12） |
| 21 | ★ 异常处理、调试与内存诊断 | `21_debugging` | 新增：MFC 异常体系、TRACE/ASSERT_VALID、AfxSetResourceHandle、_CrtMemCheckpoint 内存诊断 |
| 22 | ★ GDI+ 与 Direct2D | `22_modern_drawing` | 新增：GdiplusStartup 与 MFC 共存、抗锯齿与 Alpha 混合、D2D/DWrite 渲染进 HWND；与第 18 章对照 |
| 23 | ★ 部署：静态/动态链接与打包 | `23_deployment` | 新增；**复用 `25_notepad_plus` 源码**做静态/动态两套构建实测 |

### 第六篇 现代 MFC 与实战

| 章 | 标题 | 示例 | 来源 |
|---|------|------|------|
| 24 | ★ MFC 与现代 C++（RAII、智能指针、C++20） | `24_modern_cpp` | 新增；**复用已有示例代码重构**（如把 `13_shell_integration` 的裸句柄改成 RAII 包装） |
| 25 | 实战项目：记事本+ | `25_notepad_plus` | 扩写（原 13，示例原 `12_notepad_plus` 重命名） |

## 3. 章内模板（全章统一，对齐 WPF）

**开篇三行**（紧跟一级标题）：

```markdown
> 对应示例：`examples/NN_xxx`（一句话说明示例演示什么）
> **本章你将学会**：3~5 个具体能力点，逗号分隔。
> **前置知识**：指向具体前序章节。
```

**正文**：概念先给"为什么需要它"再给定义；核心代码给完整可编译片段 + 分段解剖；关键机制配 ASCII 图（消息流转、对象关系、调用链）；对比表格优先于长段落。

**收尾三节**（固定顺序）：

```markdown
## 常见坑          # 症状 → 原因 → 解法，表格或短条列，每章至少 3 条
## 实战建议        # 3~5 条工程经验
## 自测            # 3~5 题，题目加粗、答案紧跟破折号（与 WPF 一致，便于自测）
---
上一章：[NN 标题](NN-xxx.md) ｜ 下一章：[MM 标题](MM-xxx.md)
```

**篇幅目标**：每章 160~240 行；核心章（07 / 15 / 25）取上限。全书 25 章合计 **约 4000~4200 行**（对齐 WPF 的 4100 行）。分配：扩写章 160~195 行（原 127~182 行），新章 160~175 行。

## 4. 示例清单（23 个目录 = 12 重命名 + 11 新增；第 23、24 章复用已有示例，不建新目录）

### 4.1 重命名映射（批 1 用 `git mv`）

| 现目录 | 新目录 | 现章节 | 新章节 |
|--------|--------|--------|--------|
| `01_hello_mfc` | `01_hello_mfc`（不变） | 01/02 | 01 |
| `02_message_map` | `03_message_map` | 03 | 03 |
| `03_resources` | `04_resources` | 04 | 04 |
| `04_frame_layout` | `05_frame_layout` | 05 | 05 |
| `05_dialog` | `06_dialog` | 06 | 06 |
| `06_controls` | `07_controls` | 07 | 07 |
| `07_common_dialogs` | `10_common_dialogs` | 08 | 10 |
| `08_toolbar_statusbar` | `11_toolbar_statusbar` | 09 | 11 |
| `09_docview` | `15_docview` | 10 | 15 |
| `10_gdi` | `18_gdi` | 11 | 18 |
| `11_threads` | `20_threads` | 12 | 20 |
| `12_notepad_plus` | `25_notepad_plus` | 13 | 25 |

docs 章节文件同批重命名（`08-common-dialogs.md` → `10-common-dialogs.md` 等 6 个），并同步更新每章一级标题里的章号。

### 4.2 新增示例（11 个目录 + 2 章复用）

| 示例 | 章 | 内容 | 形态 |
|------|----|------|------|
| `02_app_lifecycle` | 02 | CWinApp 回调时序（InitInstance/Run/ExitInstance）+ 消息循环 + 关闭流程，用日志窗口可视化 | GUI + 控制台输出 |
| `08_controls_advanced` | 08 | CTreeCtrl 树 + CPropertySheet 三页向导 + CTaskDialog + 日期时间/进度控件 | GUI + .rc |
| `09_custom_controls` | 09 | Owner-draw 按钮 + ListCtrl custom draw + CWnd 派生自绘控件 + SetWindowSubclass 子类化 | GUI + .rc |
| `12_clipboard_dnd` | 12 | 剪贴板读写（文本 + 文件列表）+ COleDropTarget 接文件 + 拖出 | GUI + .rc |
| `13_shell_integration` | 13 | CFileFind 递归统计 + CRecentFileList MRU + 注册表/INI 读写 + 单实例互斥体 | GUI + .rc |
| `14_dpi_darkmode` | 14 | 按监视器 DPI 缩放布局 + 深色标题栏切换 + WM_SETTINGCHANGE 响应 | GUI + .rc |
| `16_mdi_splitter` | 16 | CMultiDocTemplate 多文档 + CChildFrame + CSplitterWnd 左右双视图同步 | GUI + .rc |
| `17_serialize` | 17 | IMPLEMENT_SERIAL 自定义类 + 版本号 + 旧版本文件兼容读取 | GUI + .rc |
| `19_printing` | 19 | OnPrint 分页绘制 + CPrintDialog + 打印预览 | GUI + .rc |
| `21_debugging` | 21 | 自定义 CException 派生 + TRACE/ASSERT 演示 + _CrtMemCheckpoint 内存诊断报告 | GUI + .rc |
| `22_modern_drawing` | 22 | GDI+ 抗锯齿与 Alpha 混合 + D2D/DWrite 渲染进 HWND，与 18 章 GDI 版对照 | GUI |
| （无新目录） | 23 | **复用 `25_notepad_plus` 源码**，同源两套构建（动态 26 KB / 静态 2.5 MB）实测对比，由 `build.ps1 -Static` 产出第二套 | 复用源码 |
| （无新目录） | 24 | **复用 `13_shell_integration` 源码重构**：裸句柄 → RAII 包装、CString → std::wstring 边界、C++20 特性混用 | 复用源码 |

## 5. 脚本改造

### 5.1 build.ps1

- 保持现有 `cl → rc → link` 三步流水线与 `/ENTRY:wWinMainCRTStartup`；
- 新增**逐示例额外链接库**机制：默认不链接，`22_modern_drawing` 需 `gdiplus.lib d2d1.lib dwrite.lib`，`12_clipboard_dnd` 需 `ole32.lib oleaut32.lib`，`14_dpi_darkmode` 需 `dwmapi.lib`（未用到的库链接器自动忽略，故可统一追加，但为教学清晰起见按示例白名单加）；
- 新增**静态链接模式**（`-Static` 开关，仅用于第 23 章）：去掉 `/D_AFXDLL`、运行时改 `/MT`，其余不变；
- 保持 UTF-8 BOM（PowerShell 5.1 中文脚本必需，改动后必须确认文件头仍是 `EF BB BF`）。

### 5.2 smoke.ps1（新增）

对齐 WPF 的 `smoke.ps1`：枚举 `build\*.exe`，逐个启动 → 存活 3 秒不崩 → `taskkill` 回收 → 报告 `存活/崩溃` 计数。MFC 的运行期错误（消息映射断言、缺失资源、`AfxOleInit` 失败、DDX 控件 ID 不存在）只在启动时暴露，编译通过不等于能跑。

用法：

```powershell
.\smoke.ps1              # 冒烟全部已构建的 exe
.\smoke.ps1 -Name 12_clipboard_dnd   # 只冒烟一个
```

## 6. 验证标准（每批次收口，全部满足才提交）

1. `.\build.ps1 -All` 全绿（最终 23 个示例目录，含 11 个新建）
2. `.\smoke.ps1` 全部 exe 3 秒存活（第 23 章的静态/动态两套产物都冒烟）
3. 正文交叉检查：每章「对应示例」路径真实存在、章号 ↔ 示例号一致、上下章链接双向可达
4. 行数达标：全书 4000~4200 行，每章 ≥160 行，新章含完整「开篇三行 + 收尾三节」
5. 全文 grep 无残留旧章号引用（如 `examples/09_docview`、`第 13 章`）
6. 每批 git 提交，提交信息说明批次内容

## 7. 实施批次（8 批）

| # | 内容 | 新示例 |
|---|------|--------|
| 1 | 骨架重排：`git mv` 12 个示例目录 + 6 个 docs 文件、更新一级标题章号与内部引用、新增 smoke.ps1、build.ps1 加库白名单与 `-Static`、旧示例全绿 + 冒烟 | — |
| 2 | 第一篇 01–04（含 02 独立示例） | 02_app_lifecycle |
| 3 | 第二篇 05–09（控件进阶 + 自绘两新章） | 08_controls_advanced / 09_custom_controls |
| 4 | 第三篇 10–14（剪贴板拖放 / Shell / DPI 三新章） | 12_clipboard_dnd / 13_shell_integration / 14_dpi_darkmode |
| 5 | 第四篇 15–19（MDI / 序列化 / 打印三新章） | 16_mdi_splitter / 17_serialize / 19_printing |
| 6 | 第五篇 20–23（调试 / 现代绘图 / 部署三新章；23 用 `-Static` 产出第二套构建） | 21_debugging / 22_modern_drawing |
| 7 | 第六篇 24–25（现代 C++ 新章 + 实战项目扩写） | 无新目录（24 重构 `13_shell_integration`） |
| 8 | 终稿：mfc/README.md 全量重写、根 README 条目扩写、全文交叉引用终检、记忆更新 | — |

## 8. 已验证的技术事实（设计期 spike，2026-09-21）

本机实测，`cl /std:c++20 /EHsc /DUNICODE /D_UNICODE /utf-8 /D_WIN32_WINNT=0x0A00` + MFC 14.51.36231：

1. **静态链接 MFC 可行且无需额外开关**：去掉 `/D_AFXDLL`、运行时改 `/MT`，链接器自动取 `atlmfc\lib\x64\mfc140u.lib`，编译链接一次通过。实测体积对比（同一份含 CTaskDialog/CTreeCtrl/CPropertySheet/CPrintDialog/GDI+/D2D 的源码）：**动态 26,112 B vs 静态 2,500,096 B**（约 96 倍）——第 23 章的核心教学数据，已实测得出。
2. **`CTaskDialog` 在 `<afxtaskdialog.h>`，不在 `afxwin.h`**；且**没有默认构造函数**，必须用 `CTaskDialog(内容, 主指令, 标题)` 三参构造，只写 `CTaskDialog dlg;` 报 C2512。
3. **`COleDropTarget::OnDrop` 返回 `BOOL` 不是 `DROPEFFECT`**（只有 `OnDragEnter`/`OnDragOver` 返回 `DROPEFFECT`）。照直觉写 `DROPEFFECT OnDrop(...) override` 报 C2555「重写虚函数返回类型有差异」。
4. **GDI+ / Direct2D / DirectWrite / DwmSetWindowAttribute 均可与 MFC 混编**，只需额外链接 `gdiplus.lib d2d1.lib dwrite.lib dwmapi.lib`；`GdiplusStartup` 在 `InitInstance` 里调用即可，与 MFC 无冲突。
5. **拖放需 `AfxOleInit()`**（`InitInstance` 里），否则 `COleDropTarget::Register` 失败。`AfxOleInit` + `Register` + `CF_HDROP` 判定全链路实测可跑。
6. `CPrintDialog`、`CPropertySheet`/`CPropertyPage`、`CTreeCtrl`、`CRecentFileList`（`<afxadv.h>`）、`CFileFind`、`WriteProfileString`/`GetProfileString`、`CreateMutex` 单实例全部可用。
7. **深色标题栏**：`DwmSetWindowAttribute(hwnd, 20 /*DWMWA_USE_IMMERSIVE_DARK_MODE*/, &bDark, sizeof(BOOL))` 编译链接运行通过。
8. **3 秒冒烟对 MFC 有效**：全部 spike 产物存活，未触发消息映射/资源断言——证明冒烟能作为独立于编译的第二道防线。

## 9. 风险与对策

| 风险 | 对策 |
|------|------|
| 重命名 12 个示例目录 + 6 个 docs 文件导致交叉引用大面积失效 | 批 1 完成后全文 grep 旧目录名与旧章号；每批收口再 grep 一次；只用 `git mv` 保留历史 |
| build.ps1 丢失 BOM 引发 PowerShell 5.1 语法错误 | 每次改动后确认文件头 `EF BB BF`（记忆已载此坑） |
| 11 个新示例体量大，MFC 代码量远高于 WPF 的 XAML 示例 | 分批推进，每批 1~3 个新示例，先写示例跑通再写对应章节正文 |
| 打印/预览、MDI、拖放等章节运行期断言多 | 每个新示例写完立刻 `smoke.ps1` 冒烟；断言弹窗会表现为进程退出，能抓出来 |
| `22_modern_drawing` 需额外库，`23_deployment` 需双模式构建 | build.ps1 在批 1 就加好库白名单与 `-Static` 开关，后续批次直接用 |
| 一次性 25 章上下文超限 | 8 批分批推进，每批独立收口提交；单批内先写示例后写正文再验证 |
| 第 23、24 章复用源码，可能与源示例产生"两份真相" | 正文明确写"本章不新增示例工程，直接引用 `25_notepad_plus` / `13_shell_integration` 源码"，构建脚本里以构建变体（`-Static`）与代码重构对照呈现 |

## 10. 不做清单（明确出界）

- ATL / WRL 全面教程（第 22 章只用 GDI+ 与 D2D 的 C++ 接口，不展开 COM 底层）
- ActiveX 控件容器与 OLE 服务器实现（第 12 章只讲剪贴板与拖放的数据传输层）
- MFC Feature Pack（`afxcontrolbars.h`）的 Ribbon / 可停靠窗格专题（只在第 08、11 章顺带提及）
- 安装包制作（第 23 章讲清静态/动态链接与运行库分发原理，不实操 Inno Setup / MSIX）
- Windows 服务、驱动、内核、钩子（属于 win32 教程范围）
- 多显示器完整专题（第 14 章覆盖按监视器 DPI 缩放的实用部分）
