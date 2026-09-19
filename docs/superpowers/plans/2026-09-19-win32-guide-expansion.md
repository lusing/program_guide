# Win32 教程扩充实施计划（12 章 → 30 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `win32/` 从 12 章/15 示例扩充为 30 章/32 示例的初学者标准教程：12 章全面重写 + 18 个新章（错误处理/控件 3 章/编码/安全/系统信息/DLL 拆分/注册表/COM 3 章/D2D/WinRT/服务/Shell/剪贴板），全部示例经本机 MSVC 编译验证。

**Architecture:** 沿用现有"docs/NN-中文标题.md 章节 + examples/NN_name 一目录一工程 + build.ps1 编译验证"骨架；先重排编号（git mv + 占位章），再按 14 批次逐篇重写/新增；每批次内先写示例（编译+运行验证）后写章节（引用示例代码），收口 = 全量编译绿 + 提交。

**Tech Stack:** MSVC `cl /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00`（VS 18 / 工具集 14.51）、comctl32/ole32/advapi32/d2d1/dwrite、C++/WinRT（SDK 26100 自带 cppwinrt 头）、PowerShell。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-19-win32-guide-expansion-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\win32`（bash 路径 `/g/code/guide/win32`）；仓库根 `G:\code\guide`。
- vcvars：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`。
- **编译参数铁律**（所有示例、文档中出现的编译命令一律用这套）：

  ```
  cl /nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00
  link /nologo /MACHINE:X64 /SUBSYSTEM:{WINDOWS|CONSOLE}
  ```

- **默认链接库全集**（Task 1 起写入 build.ps1，未用到的库链接器自动忽略）：

  ```
  user32.lib gdi32.lib kernel32.lib shell32.lib comctl32.lib psapi.lib comdlg32.lib
  dwmapi.lib ole32.lib oleaut32.lib uuid.lib advapi32.lib d2d1.lib dwrite.lib
  ```

- **子系统判定**：源码含 `int wmain(` → CONSOLE，否则 WINDOWS（build.ps1 现有逻辑，保持）。
- **BOM 铁律**：根 `build.ps1` 头部 `EF BB BF` 必须保留（PS5.1 解析中文脚本的命门，改动后必查）；**子 build.ps1（多目标工程自带脚本）一律纯 ASCII 注释**，无 BOM 依赖，PS5.1/pwsh 通吃。
- **输出命名**：一律 `build/<示例目录名>[_部件名].exe/.dll/.obj`（多目标用后缀区分，绝不互相覆盖）。
- **控制台示例约定**（沿用 `examples/14_srwlock_demo`）：`wmain()` + `_wsetlocale(LC_ALL, L"")` + `wprintf`；输出确定性文本；正常 `return 0`。
- **GUI 示例约定**：`wWinMain`；验证 = 编译通过（关键新示例加 3 秒冒烟存活测试：启动→sleep 3→进程存活即过）。
- **新示例源文件头注释**：`// NN_name — 一句话主题` + 对应章节号（docs 按此引用）。
- **章节模板**（每章必须，spec §3）：①开篇三件（本章回答的问题/前置章节/你将做出什么）②概念先铺垫后定义 ③核心示例为完整可编译代码+分段解剖 ④关键机制配 ASCII 图 ⑤易错清单（症状→原因→解法表）⑥小结 3~5 条 + 动手练习 1~3 题（带提示）。重写章 300~450 行，新章 350~500 行。
- **章节文件名**：`NN-中文标题.md`（沿用现有风格，无空格）。
- **风格范本**：现版 `docs/02-环境搭建与第一个窗口.md`（逐行解剖 + 错误对照表写法）——重写时保住这些优点，只加厚不掺水。
- **固定 GUID**（Task 12 的 27_com_server 使用，不得改动）：
  - `IID_ICalc` = `{1DBE71E1-2CA9-417E-AF41-2A2101510601}`
  - `CLSID_Calc` = `{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}`
- **已验证技术事实**（2026-09-19 本机 spike，不得凭记忆推翻）：

  | 事实 | 结论 |
  |---|---|
  | C++/WinRT 头 | `C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\cppwinrt\winrt\*.h` |
  | WinRT 链接库 | `Lib\10.0.26100.0\um\x64\WindowsApp.lib`；编译需 `/I <SDK>\Include\<ver>\cppwinrt` |
  | WinRT 最小程序 | DateTimeFormatter 编译运行通过，输出 `today = 2026-09-19`；无需显式 /permissive- |
  | Direct2D/DWrite | 现有编译参数 + `d2d1.lib dwrite.lib` 编译零错误；GUI 冒烟 3 秒存活 |
  | git-bash 直接 spawn cmd 跑 vcvars | 需先 `set PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\Installer`（vswhere 所在）；**build.ps1 经 PowerShell 调用不受影响** |

- **验证命令**（bash 下执行）：

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  单示例：`... -File 23_dll_math/main.cpp`；清理：`... -Clean`。
- **单示例手工调试**（写代码阶段快速迭代，正式验证一律走 build.ps1）：

  ```bash
  cd /g/code/guide/win32/examples/16_error_handling
  cat > /tmp/cc.bat << 'EOF'
  @echo off
  set "PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\Installer"
  call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
  cl /nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00 /Fe:demo.exe main.cpp /link user32.lib kernel32.lib /SUBSYSTEM:CONSOLE
  EOF
  cmd //c "$(cygpath -w /tmp/cc.bat)" && ./demo.exe && rm -f demo.exe demo.obj
  ```

- 提交规范：`docs(win32):` / `feat(win32):` / `chore(win32):` 前缀 + 中文说明，结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`。每个 Task 收口时 `git status` 干净。

---

### Task 1: build.ps1 改造（新库 + 多目标委托）

**Files:**
- Modify: `win32/build.ps1`

**Interfaces:**
- Produces: `-All` 改为**按示例目录遍历**（原为递归找 `*.cpp`）：目录含自己的 `build.ps1` → 委托执行（子脚本自含 vcvars 调用与运行验证）；否则按现有单 main.cpp 路径编译。`-File <dir>/main.cpp` 同样委托。后续 Task 10/12/13 的 23/24/27/29 示例依赖此机制。

- [ ] **Step 1: 用 Edit 修改 build.ps1 的两处**

  改动 1——`Invoke-CompileExample` 内 link 命令的库列表（约 70 行处）：

  ```powershell
  # 旧
  ... user32.lib gdi32.lib kernel32.lib shell32.lib comctl32.lib psapi.lib comdlg32.lib dwmapi.lib'
  # 新
  ... user32.lib gdi32.lib kernel32.lib shell32.lib comctl32.lib psapi.lib comdlg32.lib dwmapi.lib ole32.lib oleaut32.lib uuid.lib advapi32.lib d2d1.lib dwrite.lib'
  ```

  改动 2——`-All` 分支整体替换为目录遍历 + 委托：

  ```powershell
  if ($All) {
      $dirs = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
      foreach ($d in $dirs) {
          $child = Join-Path $d.FullName "build.ps1"
          $main  = Join-Path $d.FullName "main.cpp"
          if (Test-Path -LiteralPath $child) {
              Write-Host "[Delegate] $($d.Name)" -ForegroundColor Magenta
              & $child
              if ($LASTEXITCODE -ne 0) { throw "委托构建失败: $($d.Name)" }
          } elseif (Test-Path -LiteralPath $main) {
              Invoke-CompileExample -SourcePath $main
          } else {
              throw "示例目录既无 build.ps1 也无 main.cpp: $($d.Name)"
          }
      }
      Write-Host "[Done] examples 目录全部构建通过。" -ForegroundColor Green
      exit 0
  }
  ```

  `-File` 分支同样处理：取 `$sourcePath` 所在目录，若含 `build.ps1` 则委托，否则走 `Invoke-CompileExample`。

- [ ] **Step 2: 验证 BOM 未丢失**

  ```bash
  cd /g/code/guide/win32 && xxd build.ps1 | head -1
  ```

  预期首字段 `efbb bf`。若丢失：`printf '\xef\xbb\xbf' | cat - build.ps1 > /tmp/b.ps1 && mv /tmp/b.ps1 build.ps1`。

- [ ] **Step 3: 全量验证旧 15 示例**

  ```bash
  powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：`[Done] examples 目录全部构建通过。`，`build/` 下 15 个 exe。

- [ ] **Step 4: Commit**

  ```bash
  git add build.ps1 && git commit -m "chore(win32): build.ps1 扩容——默认库新增 COM/注册表/D2D 全家，支持多目标工程委托

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 2: 骨架重排（章节 git mv + 占位章 + 目录页 + 交叉引用清扫）

**Files:**
- Modify: `win32/docs/`（10 个 git mv 重命名 + 2 个原地保留）
- Create: `win32/docs/` 18 个占位章（见 Step 2 清单）
- Modify: `win32/Win32 API开发指南.md`（目录页整体重写）
- Modify: `win32/README.md`（章节对照表更新为新章号）

**Interfaces:**
- Produces: 30 个章节文件全部存在（占位章含指向对应批次的说明）；目录页 30 章结构定稿；全书交叉引用指向新章号。后续所有 Task 在此结构上填内容。

- [ ] **Step 1: git mv 重命名（严格按此顺序，防碰撞）**

  ```bash
  cd /g/code/guide/win32/docs
  git mv 12-现代Win32与学习路线.md 30-现代Win32与学习路线.md
  git mv 11-DLL与模块加载.md      19-DLL基础.md
  git mv 10-文件系统.md           16-文件系统.md
  git mv 09-内存管理.md           15-内存管理.md
  git mv 08-进程与线程.md         13-进程与作业对象.md
  git mv 07-综合应用三例.md       11-综合应用三例.md
  git mv 06-菜单工具栏与对话框.md 10-菜单对话框与资源.md
  git mv 05-GDI绘图与现代显示.md  09-GDI绘图与现代显示.md
  git mv 04-控件与事件.md         05-控件基础.md
  git mv 03-窗口与消息机制.md     04-窗口与消息机制.md
  ```

  （01、02 两章文件名不变。）注意：13 章此刻内容仍是原 08 章全文（含线程部分），Task 7 拆分；19 章仍是原 11 章全文，Task 10 拆分。

- [ ] **Step 2: 创建 18 个占位章**

  每个占位章内容统一为（标题按实际替换）：

  ```markdown
  # 第 N 章 <标题>

  > 本章为扩充新增章节，将在对应批次中完成（见仓库 spec：docs/superpowers/specs/2026-09-19-win32-guide-expansion-design.md）。
  ```

  清单（18 个）：
  `03-错误处理与调试.md`、`06-ListView与TreeView.md`、`07-更多通用控件.md`、`08-自绘与子类化.md`、`12-字符编码与字符串.md`、`14-线程与同步.md`、`17-内核对象与安全.md`、`18-系统信息与定时器.md`、`20-DLL进阶与插件系统.md`、`21-注册表.md`、`22-COM入门.md`、`23-COM实战.md`、`24-COM实现.md`、`25-Direct2D与DirectWrite.md`、`26-WinRT与CppWinRT.md`、`27-Windows服务与事件日志.md`、`28-Shell集成.md`、`29-剪贴板与拖放.md`

- [ ] **Step 3: 重写目录页 `Win32 API开发指南.md`**

  全文替换为：

  ````markdown
  # Win32 API 开发指南

  > Win32 API 是 Windows 操作系统暴露给应用程序的官方 C 语言服务接口——不只是"窗口库"。它覆盖两大板块：窗口、消息、控件、GDI 等界面能力（被各代 UI 框架不断封装），以及进程、线程、同步、内存、文件、DLL、COM、安全等系统服务能力（**至今没有任何替代品**）。

  本教程面向初学者，按依赖链组织为 30 章（五篇 + 收束），全部示例可编译验证。

  ## 目录

  ### 第一篇 入门

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [01 全景与发展史](docs/01-全景与发展史.md) | 操作系统服务接口定位、分层视图、1985–Win11 演化 | Win32 到底是什么、为什么现在还要学 |
  | [02 环境搭建与第一个窗口](docs/02-环境搭建与第一个窗口.md) | 工具链、编译链接、`wWinMain`、宽字符、报错对照表 | 怎么把源码变成能跑的 exe |
  | [03 错误处理与调试](docs/03-错误处理与调试.md) | `GetLastError`、`FormatMessageW`、`HRESULT`、`OutputDebugString`、SEH、调试器 | 出错了怎么查、怎么不被错误码淹没 |

  ### 第二篇 界面层

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [04 窗口与消息机制](docs/04-窗口与消息机制.md) | 句柄、窗口类、消息的完整旅程、`SendMessage` vs `PostMessage` | 事件驱动的程序到底怎么运转 |
  | [05 控件基础](docs/05-控件基础.md) | 控件即窗口、`WM_COMMAND`、六种基础控件、布局 | 按钮输入框怎么用、事件怎么回来 |
  | [06 ListView 与 TreeView](docs/06-ListView与TreeView.md) | 报表视图、项与子项、ImageList、树形层级、`WM_NOTIFY` | 数据列表和树怎么展示 |
  | [07 更多通用控件](docs/07-更多通用控件.md) | 工具栏、状态栏、进度条、Tab、RichEdit | 现代应用的外围控件怎么组装 |
  | [08 自绘与子类化](docs/08-自绘与子类化.md) | Owner Draw、Custom Draw、`SetWindowSubclass` | 控件长得丑怎么办、行为想改怎么办 |
  | [09 GDI 绘图与现代显示](docs/09-GDI绘图与现代显示.md) | 重绘模型、GDI 对象、双缓冲；DWM、Per-Monitor V2、Win11 视觉 | 屏幕内容怎么画、怎么不闪、怎么适配高分屏 |
  | [10 菜单、对话框与资源](docs/10-菜单对话框与资源.md) | 命令 ID 分发、加速键、模态对话框、通用对话框、资源脚本 | 命令入口怎么做、临时交互怎么弹 |
  | [11 综合应用三例](docs/11-综合应用三例.md) | 计算器、RichEdit 编辑器、绘图板 | 零件怎么组装成完整程序 |

  ### 第三篇 系统服务层

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [12 字符编码与字符串](docs/12-字符编码与字符串.md) | 代码页、`wchar_t`、`MultiByteToWideChar`、UTF-8 互转、StrSafe | 中文为什么乱码、编码怎么转换 |
  | [13 进程与作业对象](docs/13-进程与作业对象.md) | `CreateProcessW`、快照枚举、Job 对象 | 怎么启动和管理别的程序 |
  | [14 线程与同步](docs/14-线程与同步.md) | `CreateThread`、竞态、`CRITICAL_SECTION` 到 SRWLock/条件变量/线程池 | 怎么"同时做多件事"且不崩溃 |
  | [15 内存管理](docs/15-内存管理.md) | 虚拟地址空间、页、堆、文件映射 | `new` 底下发生了什么 |
  | [16 文件系统](docs/16-文件系统.md) | `CreateFileW` 详解、读写循环、目录枚举、NTFS 特性、长路径 | 可靠的文件代码怎么写 |
  | [17 内核对象与安全](docs/17-内核对象与安全.md) | 句柄表、句柄复制、SD/ACL、令牌、UAC、完整性级别 | 权限是怎么回事、UAC 拦了什么 |
  | [18 系统信息与定时器](docs/18-系统信息与定时器.md) | 版本、环境变量、系统时间、高精度定时器、电源 | 程序怎么感知它所处的机器 |

  ### 第四篇 模块与 COM

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [19 DLL 基础](docs/19-DLL基础.md) | 导出表、隐式/显式链接、`DllMain` 纪律、搜索顺序 | 模块化机制怎么工作 |
  | [20 DLL 进阶与插件系统](docs/20-DLL进阶与插件系统.md) | 插件架构实战、资源段、PE 速览、API Set | 怎么做一个能加载插件的宿主 |
  | [21 注册表](docs/21-注册表.md) | 键值类型、增删改查、枚举、HKCU 策略 | Windows 的配置中心怎么用 |
  | [22 COM 入门](docs/22-COM入门.md) | 二进制接口、`IUnknown`、引用计数、`HRESULT`、`ComPtr` | COM 是什么、为什么到处是它 |
  | [23 COM 实战](docs/23-COM实战.md) | `CoInitialize`、`CoCreateInstance`、`IFileOpenDialog` | 怎么调用系统里的 COM 组件 |
  | [24 COM 实现](docs/24-COM实现.md) | 类厂、`DllGetClassObject`、`DllRegisterServer`、HKCU 注册 | 怎么手写一个 COM 组件 |
  | [25 Direct2D 与 DirectWrite](docs/25-Direct2D与DirectWrite.md) | 工厂、渲染目标、画刷、DWrite 文本、与 GDI 对照 | 现代渲染怎么写 |
  | [26 WinRT 与 C++/WinRT](docs/26-WinRT与CppWinRT.md) | `IInspectable`、激活工厂、投影、C++20 协程异步 | 怎么从 Win32 调用现代 API |

  ### 第五篇 平台专题

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [27 Windows 服务与事件日志](docs/27-Windows服务与事件日志.md) | SCM、最小服务、安装启动停止、`ReportEventW` | 后台服务怎么写 |
  | [28 Shell 集成](docs/28-Shell集成.md) | 托盘图标、右键菜单、气泡通知 | 程序怎么融进桌面环境 |
  | [29 剪贴板与拖放](docs/29-剪贴板与拖放.md) | `CF_UNICODETEXT` 全链路、`WM_DROPFILES`、`IDropTarget` | 复制粘贴和拖放怎么实现 |

  ### 收束

  | 章 | 内容 | 回答的问题 |
  |---|------|-----------|
  | [30 现代 Win32 与学习路线](docs/30-现代Win32与学习路线.md) | Win10/11 新增 API、技术栈关系图谱、避坑总表、学习地图 | 接下来去哪 |

  ## 示例代码

  `examples/` 下每个目录对应一个可编译工程，全部经本机 MSVC 编译验证（见 [README](README.md)）。示例对照表以 README 为准。
  ````

- [ ] **Step 4: 更新 README.md 的"章节与示例对照"表**

  15 个现有示例行保留，"对应章节"列改为新章号：01→02、02→04、03→05、04→09、05→11、06→10/11、07→09/11、08→13、09→15、10→16、11→14、12→15、13→16、14→14、15→09。表后加一行说明："16~32 号示例与新增章节随扩充批次落地（共 32 个示例，终表见收束批次）。"

- [ ] **Step 5: 交叉引用清扫**

  ```bash
  cd /g/code/guide/win32 && grep -rn "第 *[0-9]* *章" docs/ "Win32 API开发指南.md" README.md | grep -v "0[123]0"
  ```

  人工逐条映射到新章号：3→4、4→5、5→9、6→10、7→11、8→13 或 14（谈进程/Job→13，谈线程/同步→14）、9→15、10→16、11→19 或 20（谈链接/DllMain→19，谈 PE/API Set→20）、12→30。章内小节号 `N.M` 同步改（如"第 8.8 节"→"第 14 章现代同步原语节"）。示例 main.cpp 头部的"对应教程 docs/NN-*.md"注释**本批不改**（各内容批次重写示例时一并处理）。

- [ ] **Step 6: 验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && ls *.md | wc -l    # 预期 31（30 章 + 无：目录页在上级）
  ```

  更正：`ls *.md | wc -l` 预期 **30**。再跑全量编译确认无意外（仍 15 示例全绿），然后：

  ```bash
  git add -A && git commit -m "docs(win32): 骨架重排——12 章重编号为 30 章结构，18 个新增章占位，目录页五篇定稿

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 3: 批 2 入门篇——16_error_handling 示例 + 01/02/03 章重写

**Files:**
- Create: `win32/examples/16_error_handling/main.cpp`
- Modify: `win32/docs/01-全景与发展史.md`（重写）
- Modify: `win32/docs/02-环境搭建与第一个窗口.md`（重写）
- Modify: `win32/docs/03-错误处理与调试.md`（填充占位）

**Interfaces:**
- Produces: 03 章是全书错误处理/HRESULT/SEH 的定义点（17~32 号示例的报错检查风格向它看齐）；`HRESULT_FROM_WIN32`/`FAILED` 在 22~24 章 COM 全面复用。

- [ ] **Step 1: 写 `examples/16_error_handling/main.cpp` 全文**

```cpp
// 16_error_handling — GetLastError / FormatMessageW / HRESULT / SEH 错误处理四件套
//
// 对应教程：docs/03-错误处理与调试.md
// 控制台程序（wmain），build.ps1 自动按 CONSOLE 子系统编译

#include <windows.h>
#include <stdio.h>
#include <locale.h>

// ── 演示 1：失败的 API + GetLastError + FormatMessageW ──────────────
static void DemoWin32Error() {
    wprintf(L"[1] Win32 错误码与消息\n");

    // 打开一个肯定不存在的文件
    HANDLE h = CreateFileW(L"C:\\__no_such_file__.tmp", GENERIC_READ, 0,
                           nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {          // 文件句柄的失败判据是它，不是 nullptr！
        DWORD err = GetLastError();           // ★ 必须紧贴失败调用读取
        wprintf(L"    CreateFileW 失败，GetLastError() = %lu\n", err);

        LPWSTR msg = nullptr;                 // 把错误码翻译成人话
        DWORD n = FormatMessageW(
            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            nullptr, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPWSTR)&msg, 0, nullptr);
        if (n > 0 && msg) {
            wprintf(L"    FormatMessageW: %s", msg);   // 系统消息自带换行
            LocalFree(msg);                           // ALLOCATE_BUFFER 的配对释放
        }
    } else {
        CloseHandle(h);
    }
}

// ── 演示 2：HRESULT——COM 世界的错误形态（第 22 章正式展开）──────────
static void DemoHresult() {
    wprintf(L"[2] HRESULT\n");
    DWORD err = ERROR_FILE_NOT_FOUND;         // = 2
    HRESULT hr = HRESULT_FROM_WIN32(err);     // 打包：0x80070002
    wprintf(L"    Win32 错误 %lu → HRESULT 0x%08lX\n", err, (unsigned long)hr);
    wprintf(L"    FAILED(hr) = %s\n", FAILED(hr) ? L"true" : L"false");
    wprintf(L"    SUCCEEDED(S_OK) = %s\n", SUCCEEDED(S_OK) ? L"true" : L"false");
}

// ── 演示 3：SEH——硬件级异常的兜底 ──────────────────────────────────
// ★ 含 __try 的函数里不能有需要析构的 C++ 对象（编译器 C2712），
//   所以 SEH 代码独立成函数、只放原始类型——这是工程上的真实约束。
static int DemoSehInner() {
    __try {
        volatile int* bad = nullptr;
        *bad = 42;                            // 写空指针 → ACCESS_VIOLATION
        return 0;                             // 执行不到
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        wprintf(L"    捕获异常 0x%08lX（EXCEPTION_ACCESS_VIOLATION）\n",
                (unsigned long)GetExceptionCode());
        return 1;
    }
}

static void DemoSeh() {
    wprintf(L"[3] SEH 结构化异常\n");
    wprintf(L"    __except 已兜底，程序继续运行（返回 %d）\n", DemoSehInner());
}

// ── 演示 4：OutputDebugStringW——写给调试器的留言 ────────────────────
static void DemoDebugOutput() {
    wprintf(L"[4] OutputDebugStringW（用 DebugView/调试器观察）\n");
    OutputDebugStringW(L"[16_error_handling] 这条消息只出现在调试器里\n");
}

int wmain() {
    _wsetlocale(LC_ALL, L"");
    wprintf(L"══ 16_error_handling：错误处理四件套 ══\n\n");
    DemoWin32Error();
    wprintf(L"\n");
    DemoHresult();
    wprintf(L"\n");
    DemoSeh();
    wprintf(L"\n");
    DemoDebugOutput();
    wprintf(L"\n演示结束，全部正常返回\n");
    return 0;
}
```

- [ ] **Step 2: 编译并运行验证**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 16_error_handling/main.cpp
  ./build/16_error_handling.exe
  ```

  预期输出含：`GetLastError() = 2`、`HRESULT 0x80070002`、`捕获异常 0xC0000005`、退出码 0。

- [ ] **Step 3: 重写 01 章（约 320 行）**

  保留现有 1.1~1.6 骨架与史实，升级为：
  1. 开篇三件（前置：无；成果：心里有一张 30 章地图）
  2. 1.1 定位（现内容保留：服务接口 + 界面/系统两大板块）
  3. 1.2 分层视图：`app → kernel32/user32/… → ntdll → 内核` ASCII 图 + "一个 API 调用经过什么"（现内容补图）；API Set 埋伏笔（20 章）
  4. 1.3 发展史 7 段（现内容保留）+ 一张 1985→2026 时间线 ASCII 图
  5. 1.4 替换与保留表（更新：UI 层 GDI→D2D（25 章）→WinUI；系统层只加不减；加入本教程新篇预告：编码/安全/COM/服务/WinRT）
  6. 1.5 四个误解（现内容保留）
  7. 1.6 本教程地图：五篇 30 章路线 + "每章你将做出什么"的成果列表节选
  8. 章末小结 + 练习（如：用任务管理器找一个进程，列出它加载的 DLL 数量）

- [ ] **Step 4: 重写 02 章（约 400 行）**

  现版质量已高（逐行解剖+错误表是全书范本），做加法：
  1. 开篇三件
  2. 2.1 工具链表（保留）+ Developer Command Prompt 进入步骤文字化 + `cl` 可用性自检命令
  3. 2.2 编译链接（保留）+ 新增：`dumpbin /imports build\01_hello_window.exe` 演示——亲眼看到 user32.dll 出现在导入表 = "链接了导入库"的证据；编译流程 ASCII 图（main.cpp→obj→exe）
  4. 2.3 版本宏（保留）
  5. 2.4 `wWinMain`（保留逐参数解剖）
  6. 2.5 第一个窗口（保留完整程序；**新增前置**：先给 20 行"消息框程序"（`MessageBoxW` 一行主体）作为第 0 个程序，再上完整窗口——两级台阶）
  7. 2.6 宽字符（保留 + 指路 12 章深讲）
  8. 2.7 错误对照表（保留 + 补两行：`LNK1561 未定义入口点`、`error C2001 常量中有换行符（编码问题）`）
  9. 小结 + 练习（改标题/尺寸/背景三连；故意去掉 DefWindowProcW 观察症状）

- [ ] **Step 5: 填充 03 章占位（新章，约 400 行）**

  1. 开篇三件（前置 02；成果：错误处理工具箱）
  2. 3.1 失败是常态：三族返回值判据表——`BOOL`（FALSE+查码）、句柄族（`INVALID_HANDLE_VALUE` vs `nullptr` 两类判据对照）、指针族；"每个 API 查文档确认失败判据"
  3. 3.2 `GetLastError` 纪律：紧贴失败调用（中间任何调用都可能覆盖）；`SetLastError(0)` 预清理；错误码是**线程局部**的
  4. 3.3 `FormatMessageW` 参数逐个解剖 + `LocalFree` 配对；引用 16 示例演示 1
  5. 3.4 `HRESULT`：ASCII 位布局图（严重位 1 | 设备 4 | 代码 16）；`HRESULT_FROM_WIN32`；`FAILED/SUCCEEDED`；常见值表（S_OK/S_FALSE/E_FAIL/E_NOTIMPL/0x80070002）；"22 章 COM 全面使用"伏笔
  6. 3.5 `OutputDebugStringW` + DebugView 工具用法
  7. 3.6 调试器入门：VS 断点/单步三种/调用栈/监视窗口；`__debugbreak()`；WinDbg 一句话定位
  8. 3.7 SEH：`__try/__except`、过滤表达式三态、`GetExceptionCode`、`__finally`；**C2712 约束**（析构对象不能进 `__try` 函数——所以 SEH 独立成函数）；MSVC 下 C++ 异常建立在 SEH 之上的一段说明
  9. 3.8 错误处理策略：重试（网络类）/报告退出/降级/断言（开发期）选型表；`ERROR_IO_PENDING` 不是错误（16 章异步伏笔一句话）
  10. 易错清单：文件句柄判成 `nullptr`；`GetLastError` 隔十行才调；`FormatMessageW` 忘 `LocalFree`；`__try` 里放 `std::string`
  11. 小结 + 练习（把 16 示例改成查 5 个错误码的翻译器；故意访问野指针用调试器抓现场）

- [ ] **Step 6: 结构自检 + 全量编译 + Commit**

  ```bash
  cd /g/code/guide/win32/docs
  for f in 01-*.md 02-*.md 03-*.md; do echo "== $f"; grep -c "本章回答的问题\|小结" "$f"; wc -l "$f"; done
  ```

  预期：每章两个关键词都 ≥1；行数 300~450。再 `build.ps1 -All` 全绿（16 示例）。

  ```bash
  git add -A && git commit -m "docs(win32): 入门篇——01/02 章重写加厚，03 错误处理新章 + 16 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 4: 批 3 界面层 I——04/05 章重写（无新示例）

**Files:**
- Modify: `win32/docs/04-窗口与消息机制.md`（重写，原 03 章内容）
- Modify: `win32/docs/05-控件基础.md`（重写，原 04 章内容）

**Interfaces:**
- Consumes: 现有示例 `02_message_loop`（04 章引用）、`03_controls`（05 章引用）。
- Produces: 04 章的定时器/消息图是 06~08、28 章引用点；05 章 `WM_COMMAND` 位布局图是 06/07 章引用点。

- [ ] **Step 1: 重写 04 章（约 380 行）**

  原 03 章骨架保留（3.1 句柄 → 3.9 消息观测器），升级：
  1. 开篇三件（前置 02；成果：能解释"点一下鼠标到底发生了什么"）
  2. 4.1 句柄（保留 + 补 ASCII 句柄表意图：进程句柄表 → 内核对象）
  3. 4.2 窗口类与窗口（保留：模板/实例类比）
  4. 4.3 一条消息的旅程（保留 + 扩成完整 ASCII 泳道图：输入→系统队列→线程队列→GetMessage→Dispatch→WndProc→DefWindowProc）
  5. 4.4 消息循环三行逐讲（保留 + 补：`GetMessageW` 返回值是三态 `int`——0/-1/正数，循环条件写 `> 0` 的原因）
  6. 4.5 `wParam/lParam` 位布局（保留 + `GET_X_LPARAM` 负坐标安全性）
  7. 4.6 WndProc 解剖与常用消息表（保留）
  8. 4.7 三种发消息方式（保留 + 跨线程 SendMessage 死锁风险一段）
  9. 4.8 定时器（保留：`WM_TIMER` 低精度真相 + 引 18 章 QPC 对照）
  10. 4.9 实战消息观测器（引 `02_message_loop` 分段解剖）
  11. 易错清单（保留 + 新增：在 WndProc 里 Sleep 观察"未响应"实验步骤）
  12. 小结 + 练习

- [ ] **Step 2: 重写 05 章（约 360 行）**

  原 04 章骨架保留，升级：
  1. 开篇三件（前置 04；成果：配置面板）
  2. 5.1 控件就是窗口（保留 + 演示代码：对按钮 `GetClassNameW` 返回 `Button`）
  3. 5.2 控件 ID 与 `WM_COMMAND`（保留 + wParam 位布局 ASCII 图：HIWORD 通知码/LOWORD ID/lParam 句柄）
  4. 5.3 六种基础控件（保留每种：创建代码 + 常用消息表）
  5. 5.4 实战配置面板（引 `03_controls`）
  6. 5.5 `WM_SIZE` 布局（保留 + 布局函数化写法）
  7. 5.6 四条工程纪律（保留）
  8. 5.7 去处：更复杂的列表/树 → 06 章；外观 → 08 章
  9. 易错清单（保留 + `CreateWindowW` 忘 `WS_VISIBLE` 又没 `ShowWindow`）
  10. 小结 + 练习

- [ ] **Step 3: 自检 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 04-*.md 05-*.md && grep -c "小结" 04-*.md 05-*.md
  ```

  预期行数 300~450、各含小结。`build.ps1 -All` 全绿（老示例未动）。

  ```bash
  git add -A && git commit -m "docs(win32): 04 窗口消息 / 05 控件基础 两章重写加厚

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 5: 批 4 界面层 II——17/18/19 示例 + 06/07/08 章

**Files:**
- Create: `win32/examples/17_listview_treeview/main.cpp`
- Create: `win32/examples/18_common_controls/main.cpp`
- Create: `win32/examples/19_custom_draw/main.cpp`
- Modify: `win32/docs/06-ListView与TreeView.md`（填充占位）
- Modify: `win32/docs/07-更多通用控件.md`（填充占位）
- Modify: `win32/docs/08-自绘与子类化.md`（填充占位）

**Interfaces:**
- Produces: 06 章的 `WM_NOTIFY`/`InitCommonControlsEx` 讲法被 07/08/29 章复用；19 示例的 `SetWindowSubclass` 被 31 章托盘示例复用。

- [ ] **Step 1: 写 `examples/17_listview_treeview/main.cpp` 全文**

```cpp
// 17_listview_treeview — ListView 报表视图 + TreeView 层级 + ImageList 共享
//
// 对应教程：docs/06-ListView与TreeView.md
#include <windows.h>
#include <commctrl.h>
#include <stdio.h>

#define IDC_LIST 1001
#define IDC_TREE 1002

struct Item { const wchar_t* name; const wchar_t* size; const wchar_t* type; };
static const Item kFiles[] = {
    { L"readme.md",  L"2 KB",   L"Markdown" },
    { L"build.ps1",  L"4 KB",   L"脚本"     },
    { L"win32.exe",  L"64 KB",  L"应用程序" },
    { L"笔记.txt",   L"1 KB",   L"文本文档" },
};

static HIMAGELIST g_icons;

static void CreateList(HWND parent, HINSTANCE inst) {
    HWND lv = CreateWindowExW(0, WC_LISTVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS,
        10, 10, 380, 300, parent, (HMENU)(INT_PTR)IDC_LIST, inst, nullptr);

    // 报表视图第一步：插列
    LVCOLUMNW col = { .mask = LVCF_TEXT | LVCF_WIDTH };
    const wchar_t* titles[] = { L"名称", L"大小", L"类型" };
    const int widths[] = { 180, 80, 100 };
    for (int i = 0; i < 3; ++i) {
        col.pszText = (LPWSTR)titles[i];
        col.cx = widths[i];
        SendMessageW(lv, LVM_INSERTCOLUMNW, i, (LPARAM)&col);
    }
    // 整行选中（报表视图的现代惯例）
    SendMessageW(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);

    // 图像列表：挂到 LVSIL_SMALL 后，LVIF_IMAGE 的 iImage 才生效
    g_icons = ImageList_Create(16, 16, ILC_COLOR32 | ILC_MASK, 0, 4);
    ImageList_AddIcon(g_icons, LoadIconW(nullptr, IDI_APPLICATION));
    ImageList_AddIcon(g_icons, LoadIconW(nullptr, IDI_INFORMATION));
    SendMessageW(lv, LVM_SETIMAGELIST, LVSIL_SMALL, (LPARAM)g_icons);

    // 行 = LVIF_IMAGE 的主项；列 = iSubItem 的子项
    for (int i = 0; i < 4; ++i) {
        LVITEMW it = { .mask = LVIF_TEXT | LVIF_IMAGE, .iItem = i, .iImage = i % 2 };
        it.pszText = (LPWSTR)kFiles[i].name;
        int idx = (int)SendMessageW(lv, LVM_INSERTITEMW, 0, (LPARAM)&it);

        for (int sub = 1; sub <= 2; ++sub) {
            LVITEMW si = { .mask = LVIF_TEXT, .iItem = idx, .iSubItem = sub };
            si.pszText = (LPWSTR)(sub == 1 ? kFiles[i].size : kFiles[i].type);
            SendMessageW(lv, LVM_SETITEMW, 0, (LPARAM)&si);
        }
    }
}

static HTREEITEM InsertTreeItem(HWND tv, const wchar_t* text, int img, HTREEITEM parent) {
    TVINSERTSTRUCTW ins = {};
    ins.hParent = parent;
    ins.item.mask = TVIF_TEXT | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    ins.item.pszText = (LPWSTR)text;
    ins.item.iImage = img;
    ins.item.iSelectedImage = img;
    return (HTREEITEM)SendMessageW(tv, TVM_INSERTITEMW, 0, (LPARAM)&ins);
}

static void CreateTree(HWND parent, HINSTANCE inst) {
    HWND tv = CreateWindowExW(0, WC_TREEVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | TVS_HASLINES | TVS_HASBUTTONS |
        TVS_LINESATROOT | TVS_SHOWSELALWAYS,
        400, 10, 230, 300, parent, (HMENU)(INT_PTR)IDC_TREE, inst, nullptr);
    SendMessageW(tv, TVM_SETIMAGELIST, TVSIL_NORMAL, (LPARAM)g_icons);  // 与列表共享

    HTREEITEM fruit = InsertTreeItem(tv, L"水果", 0, nullptr);  // 根节点
    InsertTreeItem(tv, L"苹果", 1, fruit);
    InsertTreeItem(tv, L"梨",   1, fruit);
    HTREEITEM veg = InsertTreeItem(tv, L"蔬菜", 0, nullptr);
    InsertTreeItem(tv, L"白菜", 1, veg);
    SendMessageW(tv, TVM_EXPAND, TVE_EXPAND, (LPARAM)fruit);
}

static void ShowSelection(HWND hwnd) {
    wchar_t text[128];
    HWND lv = GetDlgItem(hwnd, IDC_LIST);
    int sel = (int)SendMessageW(lv, LVM_GETNEXTITEM, (WPARAM)-1, LVNI_SELECTED);
    if (sel >= 0) {
        LVITEMW it = { .mask = LVIF_TEXT, .iItem = sel, .pszText = text, .cchTextMax = 128 };
        SendMessageW(lv, LVM_GETITEMW, 0, (LPARAM)&it);
    }
    HWND tv = GetDlgItem(hwnd, IDC_TREE);
    HTREEITEM hItem = (HTREEITEM)SendMessageW(tv, TVM_GETNEXTITEM, TVGN_CARET, 0);
    wchar_t treeText[128] = L"（无）";
    if (hItem) {
        TVITEMW ti = { .mask = TVIF_TEXT, .hItem = hItem, .pszText = treeText, .cchTextMax = 128 };
        SendMessageW(tv, TVM_GETITEMW, 0, (LPARAM)&ti);
    }
    wchar_t title[256];
    swprintf_s(title, L"列表选中：%s ｜ 树选中：%s",
               sel >= 0 ? text : L"（无）", treeText);
    SetWindowTextW(hwnd, title);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        // LVN_ITEMCHANGED 会成对触发（取消旧选中 + 选中新选中各一次），
        // 只在"新状态含选中"时刷新标题，避免重复
        if (nm->idFrom == IDC_LIST && nm->code == LVN_ITEMCHANGED) {
            LPNMLISTVIEW nlv = (LPNMLISTVIEW)lParam;
            if (nlv->uNewState & LVIS_SELECTED) ShowSelection(hwnd);
        }
        if (nm->idFrom == IDC_TREE && nm->code == TVN_SELCHANGEDW) {
            ShowSelection(hwnd);
        }
        return 0;
    }
    case WM_SIZE:
        MoveWindow(GetDlgItem(hwnd, IDC_LIST), 10, 10, 380, HIWORD(lParam) - 20, TRUE);
        MoveWindow(GetDlgItem(hwnd, IDC_TREE), 400, 10, LOWORD(lParam) - 410, HIWORD(lParam) - 20, TRUE);
        return 0;
    case WM_DESTROY:
        if (g_icons) ImageList_Destroy(g_icons);   // 图像列表要销毁
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_LISTVIEW_CLASSES | ICC_TREEVIEW_CLASSES };
    InitCommonControlsEx(&icc);   // 通用控件（comctl32）必须先注册

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ListTreeClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ListTreeClass", L"ListView 与 TreeView",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 680, 400,
        nullptr, nullptr, hInst, nullptr);
    CreateList(hwnd, hInst);
    CreateTree(hwnd, hInst);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
```

- [ ] **Step 2: 写 `examples/18_common_controls/main.cpp` 全文**

```cpp
// 18_common_controls — 工具栏 / 状态栏 / 进度条 / Tab / RichEdit 五件套
//
// 对应教程：docs/07-更多通用控件.md
#include <windows.h>
#include <commctrl.h>
#include <richedit.h>
#include <stdio.h>

#define IDC_TOOL    1101
#define IDC_STATUS  1102
#define IDC_PROG    1103
#define IDC_TAB     1104
#define IDC_RICH    1105
#define IDC_PAGE1   1106
#define IDC_PAGE2   1107
#define IDM_OPEN    2001
#define IDM_SAVE    2002
#define IDM_PRINT   2003
#define TIMER_PROGRESS 1

static HWND g_tool, g_status, g_prog, g_tab, g_rich, g_page1, g_page2;
static HMODULE g_richedDll;

static void StatusText(int part, const wchar_t* text) {
    SendMessageW(g_status, SB_SETTEXTW, part, (LPARAM)text);
}

static void Layout(HWND hwnd) {
    RECT rc; GetClientRect(hwnd, &rc);
    RECT tb;  GetWindowRect(g_tool, &tb);   int toolH = tb.bottom - tb.top;
    RECT sb;  GetWindowRect(g_status, &sb); int statH = sb.bottom - sb.top;
    MoveWindow(g_prog, 10, toolH + 8, 200, 18, TRUE);
    MoveWindow(g_tab, 10, toolH + 34, 300, rc.bottom - statH - toolH - 44, TRUE);
    MoveWindow(g_rich, 320, toolH + 34, rc.right - 330,
               rc.bottom - statH - toolH - 44, TRUE);
    RECT tabRc; GetClientRect(g_tab, &tabRc);
    SendMessageW(g_tab, TCM_ADJUSTRECT, FALSE, (LPARAM)&tabRc);  // 客户区扣掉标签头
    MapWindowPoints(g_tab, hwnd, (LPPOINT)&tabRc, 2);
    int w = tabRc.right - tabRc.left, h = tabRc.bottom - tabRc.top;
    MoveWindow(g_page1, tabRc.left, tabRc.top, w, h, TRUE);
    MoveWindow(g_page2, tabRc.left, tabRc.top, w, h, TRUE);
    SendMessageW(g_status, WM_SIZE, 0, 0);   // 状态栏收到 WM_SIZE 自动重排
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;

        // ── 工具栏：加载系统标准图库，零资源起步 ──
        g_tool = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | TBSTYLE_TOOLTIPS,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_TOOL, cs->hInstance, nullptr);
        SendMessageW(g_tool, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
        // HINST_COMMCTRL + IDB_STD_SMALL_COLOR = comctl32 内置的标准图标集
        SendMessageW(g_tool, TB_LOADIMAGES, IDB_STD_SMALL_COLOR, (LPARAM)HINST_COMMCTRL);
        TBBUTTON btns[] = {
            { STD_FILEOPEN, IDM_OPEN,  TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"打开" },
            { STD_FILESAVE, IDM_SAVE,  TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"保存" },
            { 0, 0, TBSTATE_ENABLED, BTNS_SEP, {}, 0, 0 },            // 分隔线
            { STD_PRINT,    IDM_PRINT, TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"打印" },
        };
        SendMessageW(g_tool, TB_ADDBUTTONSW, 4, (LPARAM)btns);
        SendMessageW(g_tool, TB_AUTOSIZE, 0, 0);

        // ── 状态栏：三栏 ──
        g_status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_STATUS, cs->hInstance, nullptr);
        int parts[] = { 220, 420, -1 };
        SendMessageW(g_status, SB_SETPARTS, 3, (LPARAM)parts);
        StatusText(0, L"就绪");
        StatusText(2, L"共 5 个控件");

        // ── 进度条：定时器驱动 ──
        g_prog = CreateWindowExW(0, PROGRESS_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
            10, 40, 200, 18, hwnd, (HMENU)(INT_PTR)IDC_PROG, cs->hInstance, nullptr);
        SendMessageW(g_prog, PBM_SETRANGE32, 0, 100);
        SetTimer(hwnd, TIMER_PROGRESS, 100, nullptr);

        // ── Tab：两个子页（切换 = 显隐切换）──
        g_tab = CreateWindowExW(0, WC_TABCONTROL, nullptr,
            WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
            10, 66, 300, 200, hwnd, (HMENU)(INT_PTR)IDC_TAB, cs->hInstance, nullptr);
        TCITEMW ti = { .mask = TCIF_TEXT };
        ti.pszText = (LPWSTR)L"第一页"; SendMessageW(g_tab, TCM_INSERTITEMW, 0, (LPARAM)&ti);
        ti.pszText = (LPWSTR)L"第二页"; SendMessageW(g_tab, TCM_INSERTITEMW, 1, (LPARAM)&ti);
        g_page1 = CreateWindowExW(0, L"STATIC", L"这是第一页的内容",
            WS_CHILD | WS_VISIBLE | SS_CENTER, 20, 46, 260, 150,
            g_tab, (HMENU)(INT_PTR)IDC_PAGE1, cs->hInstance, nullptr);
        g_page2 = CreateWindowExW(0, L"EDIT", L"这是第二页的输入框",
            WS_CHILD | WS_BORDER | ES_AUTOHSCROLL, 20, 46, 260, 24,
            g_tab, (HMENU)(INT_PTR)IDC_PAGE2, cs->hInstance, nullptr);

        // ── RichEdit：必须先 LoadLibrary 才能用 ──
        g_richedDll = LoadLibraryW(L"msftedit.dll");   // RichEdit 4.1
        if (g_richedDll) {
            g_rich = CreateWindowExW(WS_EX_CLIENTEDGE, MSFTEDIT_CLASSW,
                L"RichEdit 编辑区：\r\n支持复杂文本格式、无限撤销、查找替换。\r\n（普通 EDIT 的能力天花板见第 05 章）",
                WS_CHILD | WS_VISIBLE | ES_MULTILINE | WS_VSCROLL | ES_AUTOVSCROLL,
                320, 66, 340, 250, hwnd, (HMENU)(INT_PTR)IDC_RICH, cs->hInstance, nullptr);
            CHARFORMAT2W cf = { sizeof(cf) };
            cf.dwMask = CFM_FACE | CFM_SIZE;
            cf.yHeight = 320;                    // 字号单位是 twips：320 = 16pt
            lstrcpynW(cf.szFaceName, L"微软雅黑", LF_FACESIZE);
            SendMessageW(g_rich, EM_SETCHARFORMAT, SCF_ALL, (LPARAM)&cf);
        }
        return 0;
    }
    case WM_TIMER:
        if (wParam == TIMER_PROGRESS) {
            int pos = (int)SendMessageW(g_prog, PBM_GETPOS, 0, 0) + 1;
            if (pos > 100) pos = 0;
            SendMessageW(g_prog, PBM_SETPOS, pos, 0);
            wchar_t buf[64]; swprintf_s(buf, L"进度 %d%%", pos);
            StatusText(1, buf);
        }
        return 0;
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_TAB && nm->code == TCN_SELCHANGE) {
            int cur = (int)SendMessageW(g_tab, TCM_GETCURSEL, 0, 0);
            ShowWindow(g_page1, cur == 0 ? SW_SHOW : SW_HIDE);
            ShowWindow(g_page2, cur == 1 ? SW_SHOW : SW_HIDE);
        }
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_OPEN:  StatusText(0, L"打开（通用对话框见第 10 章）"); return 0;
        case IDM_SAVE:  StatusText(0, L"保存"); return 0;
        case IDM_PRINT: StatusText(0, L"打印"); return 0;
        }
        break;
    case WM_SIZE:
        Layout(hwnd);
        return 0;
    case WM_DESTROY:
        KillTimer(hwnd, TIMER_PROGRESS);
        if (g_richedDll) FreeLibrary(g_richedDll);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc),
        ICC_BAR_CLASSES | ICC_TAB_CLASSES | ICC_WIN95_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"CommonCtrlsClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"CommonCtrlsClass", L"通用控件五件套",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 720, 420,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
```

- [ ] **Step 3: 写 `examples/19_custom_draw/main.cpp` 全文**

```cpp
// 19_custom_draw — Owner Draw 按钮 + Custom Draw 隔行变色 + 子类化大写输入
//
// 对应教程：docs/08-自绘与子类化.md
#include <windows.h>
#include <commctrl.h>
#include <stdio.h>

#define IDC_ODBTN 1201
#define IDC_LIST  1202
#define IDC_EDIT  1203

// ── 子类化：拦截编辑框的 WM_CHAR，小写自动转大写 ────────────────────
LRESULT CALLBACK SubEditProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam,
                             UINT_PTR uIdSubclass, DWORD_PTR) {
    if (msg == WM_CHAR && wParam >= L'a' && wParam <= L'z') {
        wParam -= L'a' - L'A';      // 改写参数再交给原过程——子类化的本质
    }
    return DefSubclassProc(hwnd, msg, wParam, lParam, uIdSubclass, 0);
}

static void CreateList(HWND parent, HINSTANCE inst) {
    HWND lv = CreateWindowExW(0, WC_LISTVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS,
        10, 60, 400, 240, parent, (HMENU)(INT_PTR)IDC_LIST, inst, nullptr);
    LVCOLUMNW col = { .mask = LVCF_TEXT | LVCF_WIDTH, .cx = 380 };
    col.pszText = (LPWSTR)L"条目（隔行变色由 Custom Draw 绘制）";
    SendMessageW(lv, LVM_INSERTCOLUMNW, 0, (LPARAM)&col);
    SendMessageW(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);
    for (int i = 0; i < 6; ++i) {
        wchar_t buf[64]; swprintf_s(buf, L"第 %d 行：底色不是系统的，是我们画的", i + 1);
        LVITEMW it = { .mask = LVIF_TEXT, .iItem = i, .pszText = buf };
        SendMessageW(lv, LVM_INSERTITEMW, 0, (LPARAM)&it);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        // 自绘按钮：样式声明"我要自己画"，绘制发生在父窗口的 WM_DRAWITEM
        CreateWindowExW(0, L"BUTTON", L"",
            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            10, 10, 160, 40, hwnd, (HMENU)(INT_PTR)IDC_ODBTN, cs->hInstance, nullptr);
        CreateList(hwnd, cs->hInstance);
        HWND edit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"在这里输入小写字母试试",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
            10, 320, 400, 26, hwnd, (HMENU)(INT_PTR)IDC_EDIT, cs->hInstance, nullptr);
        SetWindowSubclass(edit, SubEditProc, 1, 0);   // 现代子类化（comctl32）
        return 0;
    }
    case WM_DRAWITEM: {
        // Owner Draw 事件：系统已备好 DC 和区域，我们只管画
        DRAWITEMSTRUCT* dis = (DRAWITEMSTRUCT*)lParam;
        if (dis->CtlID != IDC_ODBTN) break;
        COLORREF bg = (dis->itemState & ODS_SELECTED) ? RGB(0x7A, 0x1F, 0xC8)
                                                      : RGB(0x2B, 0x7B, 0xD5);
        HBRUSH brush = CreateSolidBrush(bg);
        FillRect(dis->hDC, &dis->rcItem, brush);
        DeleteObject(brush);
        SetBkMode(dis->hDC, TRANSPARENT);
        SetTextColor(dis->hDC, RGB(255, 255, 255));
        DrawTextW(dis->hDC, L"自绘按钮（按下变色）", -1, &dis->rcItem,
                  DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        return TRUE;   // 已处理
    }
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_LIST && nm->code == NM_CUSTOMDRAW) {
            LPNMLVCUSTOMDRAW cd = (LPNMLVCUSTOMDRAW)lParam;
            switch (cd->nmcd.dwDrawStage) {
            case CDDS_PREPAINT:
                return CDRF_NOTIFYITEMDRAW;   // 第一阶段：申请逐项通知
            case CDDS_ITEMPREPAINT: {          // 第二阶段：逐项绘制前改颜色
                int row = (int)cd->nmcd.dwItemSpec;
                cd->clrTextBk = (row % 2) ? RGB(0xE4, 0xEF, 0xFB) : RGB(255, 255, 255);
                return CDRF_NEWFONT;           // 声明"颜色我改了"
            }
            }
        }
        break;
    }
    case WM_DESTROY: {
        HWND edit = GetDlgItem(hwnd, IDC_EDIT);
        if (edit) RemoveWindowSubclass(edit, SubEditProc, 1);
        PostQuitMessage(0);
        return 0;
    }
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_LISTVIEW_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"CustomDrawClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"CustomDrawClass", L"自绘与子类化",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 440, 400,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
```

- [ ] **Step 4: 编译验证三个示例（GUI：编译即过；可选 3 秒冒烟）**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 17_listview_treeview/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 18_common_controls/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 19_custom_draw/main.cpp
  ```

  预期：三个 exe 出现在 `build/`。冒烟（可选）：

  ```bash
  ./build/17_listview_treeview.exe & sleep 3; kill %1 2>/dev/null; echo OK
  ```

- [ ] **Step 5: 填充 06 章占位（约 400 行）**

  1. 开篇三件（前置 05；成果：双视图资源管理器面板）
  2. 6.1 为什么需要它们：ListBox 的三个不够（无列/无图/无层级）
  3. 6.2 通用控件与 comctl32：`InitCommonControlsEx` + `ICC_*` 标志表；清单（manifest）启用 6.0 视觉样式一句话（本教程默认系统样式）
  4. 6.3 ListView 报表视图：插列 `LVCOLUMNW`；**`mask` 语义专节**——"mask 里不写的字段会被静默忽略，新手 90% 的'为什么不生效'在这里"；`iItem/iSubItem` 模型 ASCII 图
  5. 6.4 选中与通知：`LVM_GETNEXTITEM + LVNI_SELECTED`；`LVN_ITEMCHANGED` 成对触发原理（旧→新状态迁移）与防重复写法
  6. 6.5 ImageList：创建/`ImageList_AddIcon`/挂载点 `LVSIL_SMALL`；一个图像列表可被多个控件共享；销毁责任
  7. 6.6 TreeView：`TVINSERTSTRUCTW`、`hParent=nullptr` 即根、`TVM_EXPAND`、`TVGN_CARET` 取选中
  8. 6.7 `WM_NOTIFY` 与 `WM_COMMAND` 分工表（简单事件 vs 结构体通知；`NMHDR` 头部布局图）
  9. 6.8 完整示例解剖（17 示例分四段：建列/填行/建树/联动标题）
  10. 易错清单：mask 漏写 / `LVN_ITEMCHANGED` 无条件刷新导致闪烁 / `ImageList_Destroy` 忘调 / ID 强转漏 `INT_PTR` 在 64 位截断
  11. 小结 + 练习（加"修改日期"列；树改三级；选中行内容显示到状态栏）

- [ ] **Step 6: 填充 07 章占位（约 380 行）**

  1. 开篇三件（前置 06；成果：带工具栏状态栏的现代窗口骨架）
  2. 7.1 五控件全家福定位表
  3. 7.2 工具栏：`TB_LOADIMAGES` + `HINST_COMMCTRL` 标准图库（零资源起步）；`TBBUTTON` 七字段解剖表；分隔线写法；`TB_AUTOSIZE`；`TBSTYLE_TOOLTIPS` + `iString` 直给文本
  4. 7.3 状态栏：`SB_SETPARTS`/`SB_SETTEXTW`；**收到 `WM_SIZE` 自动重排**——父窗口必须转发的原因
  5. 7.4 进度条：`PBM_SETRANGE32/SETPOS/GETPOS`；定时器驱动模式（呼应 04 章定时器）
  6. 7.5 Tab：`TCM_INSERTITEMW`；**子页显隐切换**这一通用模式；`TCM_ADJUSTRECT` 求内容区
  7. 7.6 RichEdit：**为什么要 `LoadLibraryW(L"msftedit.dll")`**（微软有意不静态注册，版本可选）；RichEdit 版本矩阵表（1.0 `Riched32`/2.0 `Riched20`/4.1 `Msftedit` 类名与能力）；`CHARFORMAT2W` 字体；与 EDIT 对比表
  8. 7.7 完整示例解剖（18 示例分五段对应五控件）
  9. 易错清单：RichEdit 忘 LoadLibrary（`CreateWindowExW` 直接失败）/ 忘 `TB_BUTTONSTRUCTSIZE` / 状态栏布局乱（忘转发 WM_SIZE）/ Tab 切了选中态没切页面
  10. 小结 + 练习（把第 05 章配置面板升级成工具栏+状态栏版）

- [ ] **Step 7: 填充 08 章占位（约 360 行）**

  1. 开篇三件（前置 06；成果：与众不同的三控件）
  2. 8.1 外观定制四条路成本表：样式参数（免费）→ Custom Draw（改颜色）→ Owner Draw（全权绘制）→ 完全自绘窗口（最贵，指路 25 章 D2D）
  3. 8.2 Owner Draw：`BS_OWNERDRAW` 声明 → 父窗口 `WM_DRAWITEM`；`DRAWITEMSTRUCT` 字段解剖表（hDC/rcItem/itemState/CtlID）；按 `ODS_SELECTED` 画按下态；`return TRUE`
  4. 8.3 Custom Draw：**两阶段握手图**（`CDDS_PREPAINT`→返回 `CDRF_NOTIFYITEMDRAW` 申请逐项→`CDDS_ITEMPREPAINT`→改 `clrTextBk`→返回 `CDRF_NEWFONT`）；`NMLVCUSTOMDRAW`；与 Owner Draw 对比表（系统还帮你画多少）
  5. 8.4 子类化：旧 `SetWindowLongPtr(GWLP_WNDPROC)` 的两个坑（64 位类型/被反装）→ 现代 `SetWindowSubclass`（comctl32，带 id 可叠层）；`DefSubclassProc`；`RemoveWindowSubclass` 配对
  6. 8.5 完整示例解剖（19 示例三段）
  7. 易错清单：`WM_DRAWITEM` 不 `return TRUE` 被默认处理覆盖 / Custom Draw 第一阶段直接改色无效（没申请逐项）/ 子类化不 Remove / 子类过程忘走 `DefSubclassProc` 消息链断裂
  8. 小结 + 练习（自绘按钮加悬停色提示 `ODS_HOTLIGHT`；列表奇偶行改成三色循环）

- [ ] **Step 8: 自检 + 全量编译 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 06-*.md 07-*.md 08-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：三章 350~500 行；全量 19 个工程绿。

  ```bash
  git add -A && git commit -m "docs(win32): 界面层新三章——ListView/TreeView、通用控件、自绘子类化 + 17/18/19 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 6: 批 5 界面层 III——09/10/11 章重写 + 06_text_editor 升级 RichEdit

**Files:**
- Modify: `win32/docs/09-GDI绘图与现代显示.md`（重写，原 05 章内容）
- Modify: `win32/docs/10-菜单对话框与资源.md`（重写，原 06 章内容）
- Modify: `win32/docs/11-综合应用三例.md`（大幅扩写，原 07 章内容）
- Modify: `win32/examples/06_text_editor/main.cpp`（EDIT → RichEdit 4.1）

**Interfaces:**
- Consumes: 现有示例 `04_gdi_drawing`、`07_paint_app`、`15_dpi_modern_window`（09 章）、`05_mini_calculator`、`06_text_editor`（11 章）。
- Produces: 06_text_editor 的 RichEdit 形态是 11 章案例二的解剖对象；09 章末尾"现代继任"引子指向 25 章。

- [ ] **Step 1: 重写 09 章（约 380 行）**

  原 05 章骨架保留（重绘模型→HDC→GDI 对象→双缓冲→实战→DWM/DPI），升级：
  1. 开篇三件（前置 04；成果：会重绘的绘图板）
  2. 5.1 重绘模型（保留 + "绘制是被动响应"的 invalidate 请求图）
  3. 5.2 HDC（保留）
  4. 5.3 GDI 对象（保留四步配平纪律）
  5. 5.4 双缓冲（保留 + ASCII 图：离屏 DC→BitBlt 一次呈现）
  6. 5.5 实战绘图板（引 `07_paint_app`）
  7. 5.6 DWM 与 Win11 视觉（保留 + 圆角代码）
  8. 5.7 Per-Monitor V2（保留 + 引 `15_dpi_modern_window`）
  9. 5.8 GDI 的边界与去处（改写：**明确指向 25 章 Direct2D**——抗锯齿/DIP/硬件加速三痛点各一段预告）
  10. 易错清单 + 小结 + 练习（保留并补：忘换回旧 brush 就 DeleteObject → 删除了正在使用的对象）

- [ ] **Step 2: 重写 10 章（约 340 行）**

  原 06 章内容迁移重组：
  1. 开篇三件（前置 07 章【工具栏】/05 章；成果：带完整命令系统的窗口）
  2. 10.1 命令路由统一模型（保留：菜单/加速键/工具栏汇入同一 `WM_COMMAND` 的图）
  3. 10.2 代码创建菜单（保留）+ 资源脚本 .rc 简介（菜单/对话框模板/字符串表；`rc /c65001` 编码注意一句话）
  4. 10.3 快捷键（保留）
  5. 10.4 模态对话框（保留：DialogBox/EndDialog/对话框过程与 WndProc 差异表）
  6. 10.5 通用对话框（保留 `GetOpenFileNameW`；**新增**：一句话预告 23 章 `IFileOpenDialog` 是它的 COM 继任）
  7. 10.6 非模态与资源加载常识（保留）
  8. 工具栏细节**不再展开**，指向 07 章
  9. 易错清单 + 小结 + 练习

- [ ] **Step 3: 升级 `examples/06_text_editor/main.cpp` 为 RichEdit**

  先读现文件，然后按此清单修改（其余逻辑不动）：
  1. 头部加 `#include <richedit.h>`；头注释"对应教程"改为 `docs/11-综合应用三例.md`
  2. `wWinMain` 开头（注册窗口类之前）加：`HMODULE riched = LoadLibraryW(L"msftedit.dll"); if (!riched) return 1;`
  3. 编辑区创建：类名 `L"EDIT"` → `MSFTEDIT_CLASSW`；样式加 `ES_MULTILINE`（若无）；加 `WS_VSCROLL | ES_AUTOVSCROLL | ES_WANTRETURN`
  4. 创建后设置默认字体：

     ```cpp
     CHARFORMAT2W cf = { sizeof(cf) };
     cf.dwMask = CFM_FACE | CFM_SIZE;
     cf.yHeight = 240;   // 12pt
     lstrcpynW(cf.szFaceName, L"Consolas", LF_FACESIZE);
     SendMessageW(hEdit, EM_SETCHARFORMAT, SCF_ALL, (LPARAM)&cf);
     ```

  5. `WM_DESTROY` 前加 `FreeLibrary(riched);`（用全局或窗口额外数据存句柄）
  6. 验证：编译过 + 手动冒烟 3 秒；`EN_UPDATE`/文件读写逻辑（`GetWindowTextW/SetWindowTextW`）对 RichEdit 同样有效——在头注释里注明这一点

- [ ] **Step 4: 扩写 11 章（约 420 行，原仅 118 行）**

  1. 开篇三件（前置 05~10 全部；成果：三个完整程序）
  2. 11.1 案例一 计算器（引 `05_mini_calculator`）：状态机转移图 ASCII（ idle→operand1→op→operand2→result ）；"为什么不用逆波兰/为什么状态机让代码变直"讨论；关键代码三段
  3. 11.2 案例二 RichEdit 编辑器（引升级后 `06_text_editor`）：多子系统协作图（命令系统+文件 IO+编码转换+控件）；UTF-8 读写链路（ReadFile→MultiByteToWideChar→SetWindowTextW）；**RichEdit 升级 diff 讲解**（EDIT 的天花板在哪、RichEdit 多了什么）；脏标记与关闭确认
  4. 11.3 案例三 绘图板（引 `07_paint_app`）：状态-绘制分离模式图（输入改状态→Invalidate→WM_PAINT 全量重画）；为什么不能在鼠标消息里直接画（遮挡/缩放丢失实验）
  5. 11.4 三案例共同骨架：命令路由 + 状态模型 + 视图刷新，一张对照表
  6. 易错清单 + 小结 + 大练习（给编辑器加"查找替换"提示用 EM_FINDTEXT）

- [ ] **Step 5: 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期 19 工程全绿（06_text_editor 以新形态编译）。

  ```bash
  git add -A && git commit -m "docs(win32): 09 GDI / 10 菜单对话框 / 11 综合应用 重写扩写，编辑器升级 RichEdit

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 7: 批 6 系统层 I——20_encoding 示例 + 12/13/14 章

**Files:**
- Create: `win32/examples/20_encoding_convert/main.cpp`
- Modify: `win32/docs/12-字符编码与字符串.md`（填充占位）
- Modify: `win32/docs/13-进程与作业对象.md`（重写：现为原 08 章全文）
- Create 内容填充: `win32/docs/14-线程与同步.md`（填充占位；内容取自原 08 章后半）

**Interfaces:**
- Consumes: 原 08 章素材（现全在 13 章文件里——先重写 13 留下 8.1~8.5 素材，线程素材迁入 14）。
- Produces: 12 章的"两段式转换 API"模式被 11 章编辑器（已写）、24 章插件、30 章服务引用；14 章是 28 章托盘、30 章服务线程模型的引用点。

- [ ] **Step 1: 写 `examples/20_encoding_convert/main.cpp` 全文**

```cpp
// 20_encoding_convert — 代码页 / UTF-8 互转 / 非法序列检测 / StrSafe
//
// 对应教程：docs/12-字符编码与字符串.md
#include <windows.h>
#include <strsafe.h>
#include <stdio.h>
#include <locale.h>

static void DumpHex(const wchar_t* label, const char* bytes, int len) {
    wprintf(L"    %s（%d 字节）:", label, len);
    for (int i = 0; i < len; ++i) wprintf(L" %02X", (unsigned char)bytes[i]);
    wprintf(L"\n");
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    const wchar_t* text = L"Win32 编码";

    // 1) 宽字符 → UTF-8：两段式（先问长度再转换——几乎所有转换 API 的套路）
    int need = WideCharToMultiByte(CP_UTF8, 0, text, -1, nullptr, 0, nullptr, nullptr);
    char utf8[64];
    WideCharToMultiByte(CP_UTF8, 0, text, -1, utf8, need, nullptr, nullptr);
    DumpHex(L"UTF-8     ", utf8, need - 1);

    // 2) UTF-8 → 宽字符（回来），往返校验
    int need2 = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
    wchar_t back[64];
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, back, need2);
    wprintf(L"    往返一致：%s\n", wcscmp(back, text) == 0 ? L"是" : L"否");

    // 3) 同一段文字在 GBK(936) 下的形态：字节完全不同
    int need3 = WideCharToMultiByte(936, 0, text, -1, nullptr, 0, nullptr, nullptr);
    char gbk[64];
    WideCharToMultiByte(936, 0, text, -1, gbk, need3, nullptr, nullptr);
    DumpHex(L"GBK (936) ", gbk, need3 - 1);
    wprintf(L"    →「乱码」的本质：按 A 编码写、按 B 编码读\n");

    // 4) 非法序列：MB_ERR_INVALID_CHARS 让坏输入报错而不是静默替换
    char bad[] = { (char)0xFF, (char)0xFE, 'A', 0 };
    int r = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bad, -1, nullptr, 0);
    if (r == 0) {
        wprintf(L"    非法 UTF-8 被拒绝，GetLastError()=%lu\n", GetLastError());
    }

    // 5) StrSafe：长度感知的字符串函数，杜绝缓冲区溢出
    wchar_t dst[8];
    HRESULT hr = StringCchCopyW(dst, 8, L"1234567890");   // 10 字符塞 8 容量
    if (FAILED(hr)) {
        wprintf(L"    StringCchCopyW 拒绝溢出：0x%08lX\n", (unsigned long)hr);
        wprintf(L"    dst 安全截断为：%s\n", dst);
    }
    size_t len = 0;
    StringCchLengthW(dst, 8, &len);
    wprintf(L"    StringCchLengthW：dst 有效长度 %zu\n", len);
    return 0;
}
```

- [ ] **Step 2: 编译并运行验证**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 20_encoding_convert/main.cpp && ./build/20_encoding_convert.exe
  ```

  预期输出：UTF-8 字节序列（`57 69 6E 33 32 20 E7 BC 96 E7 A0 81`）、往返一致"是"、GBK 不同字节、拒绝非法序列、StrSafe 截断"1234567"、退出码 0。

- [ ] **Step 3: 填充 12 章占位（约 420 行）**

  1. 开篇三件（前置 02（`L""` 基础）；成果：编码转换与安全字符串工具箱）
  2. 12.1 三代编码史 ASCII 图：ASCII（1 字节）→ 代码页 DBCS（1~2 字节，936 表）→ Unicode/UTF-16（`wchar_t` 定长 2 字节）+ UTF-8（变长）
  3. 12.2 `wchar_t` 与 UTF-16：`sizeof(L"中") == 4` 的拆解；**代理对**一段（U+10000 以上两 `wchar_t`，`wcslen` 会多算——罕见但要听过）
  4. 12.3 代码页：`GetACP()`；常用页表（936/65001/437/1252）；`CharNextW` 免代理对遍历一句话
  5. 12.4 两段式转换模式（图 + 引 20 示例）：`WideCharToMultiByte`/`MultiByteToWideChar` 全参数解剖；`-1` 与显式长度两种语义；`MB_ERR_INVALID_CHARS`/`WC_ERR_INVALID_CHARS`
  6. 12.5 A 系列 API 内部行为：`MessageBoxA` 把 ANSI 转 UTF-16 再调 W——"W 是原生形态"的证据链
  7. 12.6 控制台与文件：`chcp 65001`；BOM（`FF FE`/`EF BB BF`）识别文件编码；`/utf-8` 编译开关到底管什么
  8. 12.7 StrSafe 家族表（Copy/Cat/Printf/Length/Gets）+ 为什么 `strcpy` 一族被禁
  9. 易错清单：`sizeof(buf)` 当字符容量传给 W 函数（差一倍）/ 转换目标缓冲按"字符数"还是"字节数"弄混 / 忘两段式直接估长度 / 在 UTF-16 下用 `str*` 函数
  10. 小结 + 练习（写一个"探测文件编码"函数：看 BOM + 试转）

- [ ] **Step 4: 重写 13 章（约 360 行，进程部分）**

  取原 08 章 8.1~8.5 素材重写：
  1. 开篇三件（前置 03/12；成果：进程管理器）
  2. 13.1 进程=容器、线程=执行流（ASCII 图：地址空间里住着代码/数据/堆/DLL，线程是其中的执行箭头；**线程细节指路 14 章**）
  3. 13.2 `CreateProcessW` 十参数解剖（保留现版精华表格 + 命令行**可写缓冲区**坑 + 两个句柄都要关）
  4. 13.3 快照枚举（保留：`CreateToolhelp32Snapshot`；引 `08_process_manager`）
  5. 13.4 打开与终止（保留：`OpenProcess` 权限、`TerminateProcess` 是"崩掉"不是"关闭"）
  6. 13.5 Job 对象（保留 + 浏览器沙箱真实案例一段；`IsProcessInJob`/`Breakaway`）
  7. 13.6 `STARTUPINFOEXW` 与属性扩展一句话（继承句柄列表——指路 17 章安全）
  8. 易错清单（保留 + 补：`PROCESS_INFORMATION` 两句柄漏关 → 子进程成僵尸）
  9. 小结 + 练习

- [ ] **Step 5: 填充 14 章占位（约 400 行，线程部分）**

  取原 08 章 8.6~8.8 素材重写：
  1. 开篇三件（前置 13；成果：生产者消费者与线程安全 UI 回传）
  2. 14.1 `CreateThread` 与 `_beginthreadex`：CRT 初始化差异——教程用 `CreateThread` 但把取舍讲透
  3. 14.2 竞态：`i++` 拆三步的时序图（load/add/store 交错演示）
  4. 14.3 `CRITICAL_SECTION`（保留：用户态快路径）
  5. 14.4 SRWLock 与条件变量（保留：读多写少、`SleepConditionVariableSRW` while 复查；引 `14_srwlock_demo`）
  6. 14.5 内核对象同步三件：Mutex/Event/Semaphore 对比表（跨进程？/可命名？/用途例）——与 14.3/14.4 用户态锁的分界线
  7. 14.6 `WaitOnAddress`（无锁对象的等待）
  8. 14.7 线程池 `SubmitThreadpoolWork`（为什么别手搓线程池）
  9. 14.8 GUI 线程模型（保留：工作线程 + `PostMessage` 回传模式；引 `11_thread_sync_demo`）；死锁四条件一段（互斥/持有等待/不可剥夺/循环等待）
  10. 易错清单（保留 + 补：`WaitForMultipleObjects` 上限 64）
  11. 小结 + 练习（给生产者消费者加退出协议：关门前哨兵值）

- [ ] **Step 6: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 12-*.md 13-*.md 14-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：三章 360~450 行；20 工程全绿。

  ```bash
  git add -A && git commit -m "docs(win32): 系统层 I——12 编码新章 + 13/14 进程线程拆分 + 20 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 8: 批 7 系统层 II——15/16 章重写（内存/文件）

**Files:**
- Modify: `win32/docs/15-内存管理.md`（重写，原 09 章内容）
- Modify: `win32/docs/16-文件系统.md`（重写，原 10 章内容）

**Interfaces:**
- Consumes: 现有示例 `09_memory_monitor`、`12_memory_deep_dive`、`10_file_manager`、`13_file_system_deep_dive`。
- Produces: 15 章文件映射是 24 章插件加载、26 章 WinRT 的引用点；16 章异步 IO 一句话指向 30 章服务。

- [ ] **Step 1: 重写 15 章（约 380 行）**

  原 09 章骨架保留，升级：
  1. 开篇三件（前置 13/14；成果：内存观测器 + 虚拟内存实验台）
  2. 15.1 三层地图（保留：虚拟内存层→堆层→CRT/new 层，谁包谁）
  3. 15.2 虚拟地址空间（保留 + 64 位布局 ASCII 图：NULL 区/用户区/内核区）
  4. 15.3 `VirtualAlloc`/`VirtualFree`（保留：保留 vs 提交两阶段 + `MEM_RELEASE` 传 0）
  5. 15.4 堆（保留：`HeapAlloc` 与 `new` 的关系； LFH 一句）
  6. 15.5 页保护（保留：`VirtualProtect` + guard page 演示；栈溢出如何被捕获一句话）
  7. 15.6 查询内存状态（保留：`GlobalMemoryStatusEx`/`VirtualQuery`；引 09/12 示例）
  8. 15.7 文件映射（保留：`CreateFileMappingW`/`MapViewOfFile` 四件套 + 共享内存；为 24 章插件、16 章文件预览埋引用）
  9. 15.8 内存错误与诊断（保留 + VMMap 工具一段）
  10. 易错清单 + 小结 + 练习（保留 + 补：跨层释放配对表）

- [ ] **Step 2: 重写 16 章（约 380 行）**

  原 10 章骨架保留，升级：
  1. 开篇三件（前置 12（编码）/13；成果：文件管理器）
  2. 16.1 路径世界观（保留 + `\\?\` 长路径；盘符大小写不敏感）
  3. 16.2 `CreateFileW` 八参数全解剖（保留：六种身份表——文件/目录/设备/管道/控制台/物理磁盘）
  4. 16.3 读写与文件指针（保留：读写循环、`ERROR_IO_PENDING` 不是错误的一句话——异步 IO 指路）
  5. 16.4 目录枚举（保留：`FindFirstFileW` 家族 + `.`/`..` 过滤）
  6. 16.5 属性与元数据（保留：大小拼 High/Low；`GetFileInformationByHandle`）
  7. 16.6 NTFS 特性（保留：ADS/Reparse/压缩；好奇自测命令）
  8. 16.7 文件监视（保留 `ReadDirectoryChangesW`）
  9. 16.8 `CreateFile2` 与现代 IO（结构体化参数；overlapped 一句话）
  10. 易错清单（保留）+ 小结 + 练习（写"目录大小统计器"递归版）

- [ ] **Step 3: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 15-*.md 16-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  ```bash
  git add -A && git commit -m "docs(win32): 系统层 II——15 内存 / 16 文件 两章重写加厚

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 9: 批 8 系统层 III——21/22 示例 + 17/18 章

**Files:**
- Create: `win32/examples/21_security_descriptors/main.cpp`
- Create: `win32/examples/22_sysinfo_timers/main.cpp`
- Modify: `win32/docs/17-内核对象与安全.md`（填充占位）
- Modify: `win32/docs/18-系统信息与定时器.md`（填充占位）

**Interfaces:**
- Consumes: 03 章错误处理风格（`GetLastError` 链）、14 章内核对象知识（`WaitForSingleObject`）。
- Produces: 17 章的 UAC/完整性讲法被 27 章服务（安装需管理员）、24 章（HKCU 免管理员注册）引用；18 章 `RtlGetVersion`+`GetProcAddress` 组合呼应 19 章 DLL 显式链接。

- [ ] **Step 1: 写 `examples/21_security_descriptors/main.cpp` 全文**

```cpp
// 21_security_descriptors — 令牌 / 完整性级别 / 给文件写 DACL 并读回
//
// 对应教程：docs/17-内核对象与安全.md
// 控制台程序；标准用户即可运行（只碰自己创建的临时文件）
#include <windows.h>
#include <aclapi.h>
#include <accctrl.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* IntegrityName(DWORD rid) {
    if (rid < 0x1000) return L"Low";
    if (rid < 0x3000) return L"Medium";      // 普通用户进程默认档
    if (rid < 0x4000) return L"High";        // 管理员提升后档位
    return L"System";
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 令牌：进程的"身份证" ──────────────────────────────────
    HANDLE token;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) {
        wprintf(L"OpenProcessToken 失败 %lu\n", GetLastError());
        return 1;
    }
    DWORD len = 0;

    GetTokenInformation(token, TokenElevation, nullptr, 0, &len);
    TOKEN_ELEVATION elev = {};
    GetTokenInformation(token, TokenElevation, &elev, len, &len);
    wprintf(L"[1] UAC 提升：%s\n",
            elev.TokenIsElevated ? L"是（管理员）" : L"否（标准用户）");

    GetTokenInformation(token, TokenIntegrityLevel, nullptr, 0, &len);
    PTOKEN_MANDATORY_LABEL ml = (PTOKEN_MANDATORY_LABEL)LocalAlloc(LMEM_FIXED, len);
    GetTokenInformation(token, TokenIntegrityLevel, ml, len, &len);
    DWORD count = *GetSidSubAuthorityCount(ml->Label.Sid);
    DWORD rid = *GetSidSubAuthority(ml->Label.Sid, count - 1);
    wprintf(L"[2] 完整性级别：RID 0x%04lX（%s）\n",
            (unsigned long)rid, IntegrityName(rid));
    LocalFree(ml);
    CloseHandle(token);

    // ── 2. 给临时文件写 DACL：自己全权 / Everyone 只读 ─────────────
    wchar_t path[MAX_PATH];
    GetTempPathW(MAX_PATH, path);
    wcscat_s(path, L"win32_sec_demo.txt");
    HANDLE h = CreateFileW(path, GENERIC_WRITE, 0, nullptr,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h != INVALID_HANDLE_VALUE) CloseHandle(h);

    // Everyone 的 SID（S-1-1-0）：用权威常量拼，别背字节序列
    PSID everyone = nullptr;
    SID_IDENTIFIER_AUTHORITY worldAuth = SECURITY_WORLD_SID_AUTHORITY;
    AllocateAndInitializeSid(&worldAuth, 1, SECURITY_WORLD_RID,
                             0, 0, 0, 0, 0, 0, 0, &everyone);

    wchar_t userName[64];
    DWORD nameLen = 64;
    GetUserNameW(userName, &nameLen);

    EXPLICIT_ACCESSW ea[2] = {};
    ea[0].grfAccessPermissions = GENERIC_ALL;             // 自己：全权
    ea[0].grfAccessMode = GRANT_ACCESS;
    ea[0].grfInheritance = NO_INHERITANCE;
    ea[0].Trustee.TrusteeForm = TRUSTEE_IS_NAME;
    ea[0].Trustee.ptstrName = userName;
    ea[1].grfAccessPermissions = GENERIC_READ;            // Everyone：只读
    ea[1].grfAccessMode = GRANT_ACCESS;
    ea[1].grfInheritance = NO_INHERITANCE;
    ea[1].Trustee.TrusteeForm = TRUSTEE_IS_SID;           // SID 免受本地化名影响
    ea[1].Trustee.ptstrName = (LPWSTR)everyone;

    PSECURITY_DESCRIPTOR sd = nullptr;
    ULONG sdLen = 0;
    BuildSecurityDescriptorW(nullptr, nullptr, 2, ea, 0, nullptr,
                             nullptr, &sdLen, &sd);
    BOOL present = FALSE, defaulted = FALSE;
    PACL dacl = nullptr;
    GetSecurityDescriptorDacl(sd, &present, &dacl, &defaulted);
    SetNamedSecurityInfoW(path, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION,
                          nullptr, nullptr, dacl, nullptr);
    wprintf(L"[3] 已写入 DACL：%s\n", path);

    // ── 3. 读回验证：数 ACE、把 SID 翻译回账户名 ───────────────────
    PSID owner = nullptr; PACL readAcl = nullptr;
    PSECURITY_DESCRIPTOR rsd = nullptr;
    GetNamedSecurityInfoW(path, SE_FILE_OBJECT,
                          OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION,
                          &owner, nullptr, &readAcl, nullptr, &rsd);
    ACL_SIZE_INFORMATION ai = {};
    GetAclInformation(readAcl, &ai, sizeof(ai), AclSizeInformation);
    wprintf(L"[4] 读回 DACL：%lu 条 ACE\n", (unsigned long)ai.AceCount);
    for (DWORD i = 0; i < ai.AceCount; ++i) {
        ACCESS_ALLOWED_ACE* ace = nullptr;
        if (GetAce(readAcl, i, (void**)&ace)) {
            wchar_t name[64], domain[64];
            DWORD nLen = 64, dLen = 64;
            SID_NAME_USE use;
            LookupAccountSidW(nullptr, &ace->SidStart, name, &nLen,
                              domain, &dLen, &use);
            wprintf(L"    ACE%lu：%s\\%s 权限掩码 0x%08lX\n",
                    (unsigned long)i, domain, name, (unsigned long)ace->Mask);
        }
    }

    LocalFree(rsd);
    LocalFree(sd);
    FreeSid(everyone);
    DeleteFileW(path);
    wprintf(L"演示结束（临时文件已删除）\n");
    return 0;
}
```

- [ ] **Step 2: 写 `examples/22_sysinfo_timers/main.cpp` 全文**

```cpp
// 22_sysinfo_timers — 版本 / 处理器内存 / 环境 / 时间 / QPC / 可等待定时器 / 电源
//
// 对应教程：docs/18-系统信息与定时器.md
#include <windows.h>
#include <stdio.h>
#include <locale.h>

typedef LONG(WINAPI* RtlGetVersionFn)(void*);   // ntdll!RtlGetVersion

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 版本：绕过 manifest 谎言的诚实问法 ─────────────────────
    HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
    RtlGetVersionFn rtlGetVersion =
        (RtlGetVersionFn)GetProcAddress(ntdll, "RtlGetVersion");
    OSVERSIONINFOW vi = { sizeof(vi) };
    rtlGetVersion(&vi);
    wprintf(L"[1] 真实版本：Windows %lu.%lu build %lu\n",
            (unsigned long)vi.dwMajorVersion,
            (unsigned long)vi.dwMinorVersion,
            (unsigned long)vi.dwBuildNumber);

    // ── 2. 处理器与内存 ──────────────────────────────────────────
    SYSTEM_INFO si = {};
    GetSystemInfo(&si);
    wprintf(L"[2] 逻辑处理器 %lu 个，页面 %lu KB\n",
            (unsigned long)si.dwNumberOfProcessors,
            (unsigned long)si.dwPageSize / 1024);
    MEMORYSTATUSEX ms = { sizeof(ms) };
    GlobalMemoryStatusEx(&ms);
    wprintf(L"    物理内存占用 %lu%%（共 %llu MB）\n",
            (unsigned long)ms.dwMemoryLoad,
            (unsigned long long)ms.ullTotalPhys / (1024 * 1024));

    // ── 3. 环境变量 ──────────────────────────────────────────────
    wchar_t temp[MAX_PATH];
    ExpandEnvironmentStringsW(L"%TEMP%", temp, MAX_PATH);
    wprintf(L"[3] TEMP 展开为：%s\n", temp);
    LPWCH env = GetEnvironmentStringsW();       // 块内 NUL 分隔，空串收尾
    int shown = 0;
    for (LPWCH p = env; *p && shown < 3; p += lstrlenW(p) + 1, ++shown) {
        wprintf(L"    %s\n", p);
    }
    FreeEnvironmentStringsW(env);

    // ── 4. 时间：本地 / UTC / FILETIME 三种形态 ───────────────────
    SYSTEMTIME local = {}, utc = {};
    GetLocalTime(&local);
    GetSystemTime(&utc);
    wprintf(L"[4] 本地 %04d-%02d-%02d %02d:%02d:%02d ｜ UTC %02d:%02d\n",
            local.wYear, local.wMonth, local.wDay,
            local.wHour, local.wMinute, local.wSecond,
            utc.wHour, utc.wMinute);
    FILETIME ft = {};
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER big = { .LowPart = ft.dwLowDateTime,
                           .HighPart = ft.dwHighDateTime };
    wprintf(L"    FILETIME（1601 纪元，100ns 单位）= %llu\n",
            (unsigned long long)big.QuadPart);

    // ── 5. 高精度计时：QPC 秒表 ──────────────────────────────────
    LARGE_INTEGER freq = {}, t0 = {}, t1 = {};
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&t0);
    Sleep(100);
    QueryPerformanceCounter(&t1);
    wprintf(L"[5] QPC 测得 Sleep(100) 实际 %.1f ms\n",
            (t1.QuadPart - t0.QuadPart) * 1000.0 / freq.QuadPart);

    // ── 6. 可等待定时器：1 秒后变有信号 ──────────────────────────
    HANDLE timer = CreateWaitableTimerW(nullptr, FALSE, nullptr);
    LARGE_INTEGER due = {};
    due.QuadPart = -10'000'000;                 // 负 = 相对；100ns 单位 → 1 秒
    SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE);
    WaitForSingleObject(timer, INFINITE);
    wprintf(L"[6] 可等待定时器：1 秒已到\n");
    CloseHandle(timer);

    // ── 7. 电源 ──────────────────────────────────────────────────
    SYSTEM_POWER_STATUS ps = {};
    GetSystemPowerStatus(&ps);
    wprintf(L"[7] 电源：%s，电量 %lu%%\n",
            ps.ACLineStatus == 1 ? L"交流电" : L"电池/未知",
            (unsigned long)ps.BatteryLifePercent);
    return 0;
}
```

- [ ] **Step 3: 编译并运行两个示例**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 21_security_descriptors/main.cpp && ./build/21_security_descriptors.exe && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 22_sysinfo_timers/main.cpp && ./build/22_sysinfo_timers.exe
  ```

  21 预期：`UAC 提升：否`、`完整性级别 RID 0x2000+（Medium/High）`、`2 条 ACE`、临时文件已删除、退出码 0。22 预期：真实 build 号（如 26100）、QPC ≈100ms、定时器 1 秒到达、退出码 0。

- [ ] **Step 4: 填充 17 章占位（约 430 行）**

  1. 开篇三件（前置 14/15；成果：能解释"为什么双击没权限"并亲手写 ACL）
  2. 17.1 内核对象 vs 用户/GDI 对象三族对照表（句柄族谱：CloseHandle/DeleteObject/DestroyWindow 各归各家）；内核对象共性：引用计数、可命名、跨进程共享（呼应 14 章 Mutex）
  3. 17.2 句柄表与 `DuplicateHandle`（继承示意；句柄泄漏排查：Process Explorer 句柄数）
  4. 17.3 安全描述符 SD 四室一厅 ASCII 图（Owner/Group/DACL/SACL）+ ACE 结构；"DACL 是白名单问题的答案：遍历 ACE 找第一个 allow/deny"
  5. 17.4 令牌：登录会话、组 SID、特权（`SeDebugPrivilege` 一例）；访问检查流程图（令牌 ∩ DACL）
  6. 17.5 UAC：**虚拟化实验**——标准用户写 `C:\Program Files` 实际落到 `%LOCALAPPDATA%\VirtualStore`（亲手验证步骤）；requireAdministrator 清单；`runas` 动词
  7. 17.6 完整性级别：IL 五档表（Low→Protected）；UIPI（低完整性进程给高完整性窗口发消息被拦——解释"为什么有的窗口 PostMessage 失败"）；**呼应 03 章错误处理**
  8. 17.7 `SetProcessMitigationPolicy` 一段（DEP/CFG 一句话级别）
  9. 17.8 完整示例解剖（21 示例四段）
  10. 易错清单：DACL 给 Everyone 完全控制 / `SetNamedSecurityInfoW` 后忘 `LocalFree(rsd)` / 假设总是管理员 / 空 DACL（=全允许）与无 DACL（=拒绝）的区别——**必讲**
  11. 小结 + 练习（把 DACL 改成 deny 自己读，观察 `ERROR_ACCESS_DENIED` 再改回）

- [ ] **Step 5: 填充 18 章占位（约 380 行）**

  1. 开篇三件（前置 14；成果：系统感知工具箱）
  2. 18.1 版本检测三个时代：`GetVersionExW` 撒谎史（动机：应用兼容性清单）→ `VerifyVersionInfoW`+manifest 声明 → `RtlGetVersion` 永远说真话（`GetProcAddress` 动态取——**呼应 19 章显式链接预告**）
  3. 18.2 处理器/内存：`GetSystemInfo`/`GetNativeSystemInfo` 差异（WOW64）；`SYSTEM_INFO` 字段表
  4. 18.3 环境变量：进程环境块模型；`GetEnvironmentVariableW`/`SetEnvironmentVariableW`/`ExpandEnvironmentStringsW`；系统变量 vs 用户变量合并顺序
  5. 18.4 时间三态：本地/UTC/FILETIME 互转图；1601 纪元与 100ns；`SystemTimeToFileTime`/`FileTimeToSystemTime`；ULONGLONG 比较要用 `ULARGE_INTEGER` 拼装（直接比 FILETIME 结构是 UB）
  6. 18.5 高精度计时：QPC 特性（单调递增、不受改时钟影响）；测耗时标准三行代码；`Sleep` 精度真相（≈15.6ms 粒度，`timeBeginPeriod` 一句）
  7. 18.6 三种定时器对比表：`WM_TIMER`（消息、低精度、GUI）/ `SetWaitableTimer`（内核对象、可等待、多线程）/ `CreateTimerQueueTimer`（线程池回调）——选型建议
  8. 18.7 电源与设备：`GetSystemPowerStatus`；`WM_DEVICECHANGE` + `RegisterDeviceNotification`（U 盘到达，代码片段）
  9. 18.8 完整示例解剖（22 示例七段）
  10. 易错清单：`GetVersionExW` 信了谎言 / FILETIME 直接比较 / `Sleep(1)` 当精确延迟 / 环境变量改了只影响本进程
  11. 小结 + 练习（写"系统体检报告"：版本+内存+电池+处理器拼一段文字）

- [ ] **Step 6: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 17-*.md 18-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：两章 380~450 行；22 工程全绿。

  ```bash
  git add -A && git commit -m "docs(win32): 系统层 III——17 内核对象与安全 / 18 系统信息与定时器 新章 + 21/22 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 10: 批 9 DLL——19/20 章 + 23/24 示例（首批多目标工程）

**Files:**
- Modify: `win32/docs/19-DLL基础.md`（重写：现为原 11 章全文，拆出进阶素材留 20 章）
- Create 内容填充: `win32/docs/20-DLL进阶与插件系统.md`（填充占位）
- Create: `win32/examples/23_dll_math/{mathlib.h,mathlib.cpp,main.cpp,build.ps1}`
- Create: `win32/examples/24_dll_plugin/{plugin_api.h,plugin_circle.cpp,plugin_square.cpp,main.cpp,build.ps1}`

**Interfaces:**
- Consumes: Task 1 的委托机制（目录含 build.ps1 时根脚本委托）。
- Produces: 19 章隐式/显式链接讲法是 24 章注册函数、26 章 WinRT 加载的引用点；20 章插件契约被 27 章（COM 插件形态）与 31 章（托盘）呼应；`build/` 里此后常驻 `mathlib.dll` 等插件 DLL——24 示例的"跳过非插件"逻辑依赖这一点（教学点）。

- [ ] **Step 1: 写 `examples/23_dll_math` 四个文件**

`mathlib.h`：

```cpp
// mathlib.h — 同一个头同时服务导出方与导入方
#pragma once

#ifdef MATHLIB_EXPORTS            // DLL 工程定义它 → 我是导出方
#  define MATHLIB_API __declspec(dllexport)
#else                             // 使用方不定义 → 我是导入方
#  define MATHLIB_API __declspec(dllimport)
#endif

extern "C" MATHLIB_API int Math_Add(int a, int b);
extern "C" MATHLIB_API int Math_Mul(int a, int b);
extern "C" MATHLIB_API const wchar_t* Math_Version(void);
```

`mathlib.cpp`：

```cpp
// mathlib.cpp — DLL 侧实现（编译时定义 MATHLIB_EXPORTS）
#include "mathlib.h"
#include <windows.h>

static wchar_t g_version[] = L"mathlib 1.0 (MSVC x64)";

extern "C" MATHLIB_API int Math_Add(int a, int b) { return a + b; }
extern "C" MATHLIB_API int Math_Mul(int a, int b) { return a * b; }
extern "C" MATHLIB_API const wchar_t* Math_Version(void) { return g_version; }

BOOL APIENTRY DllMain(HMODULE hinst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinst);   // 不关心线程事件就关掉
    }
    return TRUE;
}
```

`main.cpp`：

```cpp
// 23_dll_math — 隐式链接消费者：像调普通函数一样调 DLL 导出
//
// 对应教程：docs/19-DLL基础.md
// 本示例由 23_dll_math/build.ps1 构建（DLL + 导入库 + 本 exe 四步）
#include "mathlib.h"
#include <stdio.h>
#include <locale.h>

int wmain() {
    _wsetlocale(LC_ALL, L"");
    wprintf(L"Math_Add(20, 22) = %d\n", Math_Add(20, 22));
    wprintf(L"Math_Mul(6, 7)   = %d\n", Math_Mul(6, 7));
    wprintf(L"Math_Version()   = %s\n", Math_Version());
    wprintf(L"（没有 LoadLibrary——加载发生在进程启动，这就是隐式链接）\n");
    return 0;
}
```

`build.ps1`（**纯 ASCII，无 BOM**）：

```powershell
# 23_dll_math build: DLL (+ import lib) then consumer exe (implicit link), then run
# Invoked by root build.ps1 (delegation) or run directly from this directory.
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "23_dll_math"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# 1) DLL object (MATHLIB_EXPORTS selects dllexport)
Invoke-Cl ('cl {0} /DMATHLIB_EXPORTS /c mathlib.cpp /Fo:"{1}\{2}_mathlib.obj"' -f $common, $buildDir, $name)
# 2) DLL + import library
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\mathlib.dll" /IMPLIB:"{0}\mathlib.lib" "{0}\{1}_mathlib.obj" kernel32.lib user32.lib' -f $buildDir, $name)
# 3) consumer object
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
# 4) consumer exe: mathlib.lib on the link line IS implicit linking
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" "{0}\mathlib.lib" kernel32.lib' -f $buildDir, $name)
# 5) run: exe finds mathlib.dll in its own directory (DLL search order)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "consumer run failed" }
```

- [ ] **Step 2: 写 `examples/24_dll_plugin` 五个文件**

`plugin_api.h`：

```cpp
// plugin_api.h — 宿主与插件之间的唯一契约：纯 C、无 CRT 依赖
#pragma once

#define PLUGIN_API_VERSION 1

typedef struct PluginInfo {
    int apiVersion;              // 宿主先核对版本再使用
    const wchar_t* name;
    double (*area)(double r);    // 纯函数：不跨边界分配/释放内存
} PluginInfo;

// 每个插件导出这一个函数，返回只读信息结构：
// extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void);
typedef const PluginInfo* (*PFN_query_plugin)(void);
```

`plugin_circle.cpp`：

```cpp
// plugin_circle.cpp — 插件：圆面积（编译成 plugin_circle.dll）
#include "plugin_api.h"

static double CircleArea(double r) { return 3.14159265358979 * r * r; }

static const PluginInfo g_info = { PLUGIN_API_VERSION, L"圆形（πr²）", CircleArea };

extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void) {
    return &g_info;
}
```

`plugin_square.cpp`：

```cpp
// plugin_square.cpp — 插件：正方形面积（编译成 plugin_square.dll）
#include "plugin_api.h"

static double SquareArea(double a) { return a * a; }

static const PluginInfo g_info = { PLUGIN_API_VERSION, L"正方形（a²）", SquareArea };

extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void) {
    return &g_info;
}
```

`main.cpp`（宿主）：

```cpp
// 24_dll_plugin — 插件宿主：扫描 exe 旁的 DLL，显式加载并调用
//
// 对应教程：docs/20-DLL进阶与插件系统.md
#include "plugin_api.h"
#include <windows.h>
#include <stdio.h>
#include <locale.h>

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // exe 所在目录 = build\（插件 DLL 也输出到那里，靠"应用程序目录优先"找到）
    wchar_t dir[MAX_PATH];
    GetModuleFileNameW(nullptr, dir, MAX_PATH);
    wchar_t* slash = wcsrchr(dir, L'\\');
    if (slash) *slash = 0;

    wchar_t pattern[MAX_PATH];
    swprintf_s(pattern, MAX_PATH, L"%s\\*.dll", dir);

    WIN32_FIND_DATAW fd;
    HANDLE find = FindFirstFileW(pattern, &fd);
    if (find == INVALID_HANDLE_VALUE) {
        wprintf(L"没有找到任何 DLL\n");
        return 1;
    }
    int loaded = 0;
    do {
        HMODULE hMod = LoadLibraryW(fd.cFileName);   // 裸名：搜索顺序生效
        if (!hMod) {
            wprintf(L"[跳过] %s 加载失败 %lu\n", fd.cFileName, GetLastError());
            continue;
        }
        PFN_query_plugin query =
            (PFN_query_plugin)GetProcAddress(hMod, "query_plugin");
        if (!query) {
            // 不是本宿主的插件（如 build\ 里别的示例 DLL）——正常，静默跳过
            FreeLibrary(hMod);
            continue;
        }
        const PluginInfo* info = query();
        if (info->apiVersion != PLUGIN_API_VERSION) {
            wprintf(L"[拒绝] %s 版本不匹配（插件 %d，宿主 %d）\n",
                    info->name, info->apiVersion, PLUGIN_API_VERSION);
            FreeLibrary(hMod);
            continue;
        }
        wprintf(L"[插件] %-14s area(2.5) = %.4f\n", info->name, info->area(2.5));
        ++loaded;
        FreeLibrary(hMod);
    } while (FindNextFileW(find, &fd));
    FindClose(find);

    wprintf(L"共加载 %d 个插件\n", loaded);
    return 0;
}
```

`build.ps1`（**纯 ASCII**）：

```powershell
# 24_dll_plugin build: two plugin DLLs + host exe, then run host
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "24_dll_plugin"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# plugin DLLs (bare-minimum C interface)
Invoke-Cl ('cl {0} /c plugin_circle.cpp /Fo:"{1}\{2}_circle.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\plugin_circle.dll" "{0}\{1}_circle.obj" kernel32.lib' -f $buildDir, $name)
Invoke-Cl ('cl {0} /c plugin_square.cpp /Fo:"{1}\{2}_square.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\plugin_square.dll" "{0}\{1}_square.obj" kernel32.lib' -f $buildDir, $name)
# host
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" kernel32.lib user32.lib' -f $buildDir, $name)
# run: host finds plugin DLLs next to itself in build\
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "host run failed" }
```

- [ ] **Step 3: 验证委托构建与运行**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 23_dll_math/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 24_dll_plugin/main.cpp
  ```

  预期：`[Delegate]` 前缀出现；23 输出 `Math_Add(20, 22) = 42`；24 输出两个 `[插件]` 行（圆形/正方形）+ `共加载 2 个插件`（**若 build\ 里有 mathlib.dll 等非插件 DLL，被静默跳过——正常**）。

- [ ] **Step 4: 重写 19 章（约 380 行）**

  原 11 章前半素材重写（PE/API Set/资源素材留给 20 章）：
  1. 开篇三件（前置 15/16；成果：自己的 mathlib.dll 与插件宿主）
  2. 19.1 DLL 是什么（保留原 11.1：PE 模块/导出表/导入表；"你调 Win32 API 的每一步都在跨 DLL"）
  3. 19.2 隐式链接（保留原 11.2 上半 + **手把手**：跟着 23 示例的三步构建看 `mathlib.lib` 怎么挂上、`dumpbin /imports` 亲验、缺 DLL 启动报错实验）
  4. 19.3 显式链接：`LoadLibraryW`/`GetProcAddress`/`FreeLibrary` 逐参数；**函数指针签名逐字核对**（呼应 18 章 `RtlGetVersion` 已经用过一次！）；适用场景表
  5. 19.4 `extern "C"` 与导出宏模式（`MATHLIB_API` 一个宏服务双方；名字修饰对照 `?Add@@YAXHH@Z`；`.def` 一段）
  6. 19.5 `DllMain` 纪律（保留原 11.3 全部：loader lock 禁令清单）
  7. 19.6 搜索顺序（保留原 11.4 六步表 + 安全要点 + 24 示例"裸名找 exe 旁 DLL"的实验）
  8. 易错清单（保留原 11.8 表 + 补：签名不匹配的崩溃形态描述）
  9. 小结 + 练习（给 mathlib 加 `Math_Div` 并处理除零返回码）

- [ ] **Step 5: 填充 20 章占位（约 400 行）**

  1. 开篇三件（前置 19；成果：双插件宿主）
  2. 20.1 插件系统设计：契约三原则（纯 C 接口/版本号握手/内存不跨界）——每条配"违反了会怎样"
  3. 20.2 宿主扫描-加载-校验-调用-卸载五步（24 示例解剖；"跳过非插件"的容错设计；`FreeLibrary` 时机）
  4. 20.3 版本协商：`apiVersion` 硬匹配 vs 能力位；拒绝加载的礼貌路径
  5. 20.4 COM 是更好的插件机制吗——一段伏笔（契约即接口、生命周期即引用计数；24 章`27_com_server` 就是它的标准形态）
  6. 20.5 资源段（保留原 11.7：`.rsrc`、`FindResourceW` 三步、`LoadResource` 不配对释放的冷知识）
  7. 20.6 PE 速览（保留原 11.6：DOS 头/NT 头/节表图）
  8. 20.7 API Set（保留原 11.5：`api-ms-win-*` 的真相）
  9. 20.8 DLL 版本地狱简史与现代对策（SxS/清单/`SetDefaultDllDirectories`）
  10. 易错清单 + 小结 + 练习（写第三个插件"三角形"；把契约函数改成两个函数的表）

- [ ] **Step 6: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 19-*.md 20-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：两章 380~450 行；24 工程全绿（含 2 个委托）。

  ```bash
  git add -A && git commit -m "docs(win32): DLL 双章——19 基础 / 20 进阶与插件系统 + 23/24 多目标示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 11: 批 10 注册表——25 示例 + 21 章

**Files:**
- Create: `win32/examples/25_registry_tool/main.cpp`
- Modify: `win32/docs/21-注册表.md`（填充占位）

**Interfaces:**
- Consumes: 03 章 `FormatMessageW` 错误风格；HKCU 免管理员结论（17 章提过 UAC）。
- Produces: 21 章注册表键路径讲法是 24 章 COM 注册（`HKCU\Software\Classes\CLSID\...`）的直接前置。

- [ ] **Step 1: 写 `examples/25_registry_tool/main.cpp` 全文**

```cpp
// 25_registry_tool — HKCU 下的注册表增删改查与枚举全流程
//
// 对应教程：docs/21-注册表.md
// 控制台程序；全部操作在 HKEY_CURRENT_USER，标准用户即可
#include <windows.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* kRoot = L"Software\\GuideWin32";
static const wchar_t* kSubKey = L"Software\\GuideWin32\\Demo";

static const wchar_t* TypeName(DWORD type) {
    switch (type) {
    case REG_SZ:         return L"REG_SZ";
    case REG_EXPAND_SZ:  return L"REG_EXPAND_SZ";
    case REG_DWORD:      return L"REG_DWORD";
    case REG_QWORD:      return L"REG_QWORD";
    case REG_BINARY:     return L"REG_BINARY";
    default:             return L"其他";
    }
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 创建键（已存在则打开）────────────────────────────────
    HKEY key;
    LSTATUS st = RegCreateKeyExW(HKEY_CURRENT_USER, kSubKey, 0, nullptr,
                                 REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS,
                                 nullptr, &key, nullptr);
    if (st != ERROR_SUCCESS) {
        wprintf(L"RegCreateKeyExW 失败 %ld\n", (long)st);
        return 1;
    }
    wprintf(L"[1] 已创建/打开 HKCU\\%s\n", kSubKey);

    // ── 2. 写三种类型的值 ──────────────────────────────────────
    DWORD count = 42;
    BYTE blob[] = { 0xDE, 0xAD, 0xBE, 0xEF };
    const wchar_t* hello = L"你好，注册表";
    RegSetValueExW(key, L"计数", 0, REG_DWORD,
                   (const BYTE*)&count, sizeof(count));
    RegSetValueExW(key, L"问候", 0, REG_SZ,
                   (const BYTE*)hello,
                   (DWORD)((wcslen(hello) + 1) * sizeof(wchar_t)));   // 含结尾 NUL
    RegSetValueExW(key, L"指纹", 0, REG_BINARY, blob, sizeof(blob));
    wprintf(L"[2] 写入 REG_DWORD / REG_SZ / REG_BINARY\n");

    // ── 3. 读回：按类型分支 ────────────────────────────────────
    wchar_t text[64]; DWORD type = 0, size = sizeof(text);
    st = RegQueryValueExW(key, L"问候", nullptr, &type, (BYTE*)text, &size);
    if (st == ERROR_SUCCESS && type == REG_SZ) {
        wprintf(L"[3] 问候 = %s\n", text);
    }
    DWORD num = 0; size = sizeof(num);
    RegQueryValueExW(key, L"计数", nullptr, &type, (BYTE*)&num, &size);
    wprintf(L"    计数 = %lu\n", (unsigned long)num);

    // ── 4. 建子键，然后枚举值与子键 ─────────────────────────────
    HKEY sub;
    RegCreateKeyExW(key, L"子键甲", 0, nullptr, REG_OPTION_NON_VOLATILE,
                    KEY_ALL_ACCESS, nullptr, &sub, nullptr);
    RegCloseKey(sub);
    RegCreateKeyExW(key, L"子键乙", 0, nullptr, REG_OPTION_NON_VOLATILE,
                    KEY_ALL_ACCESS, nullptr, &sub, nullptr);
    RegCloseKey(sub);

    wprintf(L"[4] 枚举值：\n");
    for (DWORD i = 0; ; ++i) {
        wchar_t name[64]; DWORD nameLen = 64;
        st = RegEnumValueW(key, i, name, &nameLen, nullptr,
                           &type, nullptr, nullptr);
        if (st == ERROR_NO_MORE_ITEMS) break;
        if (st != ERROR_SUCCESS) break;
        wprintf(L"    值 %s（%s）\n", name, TypeName(type));
    }
    wprintf(L"    枚举子键：\n");
    for (DWORD i = 0; ; ++i) {
        wchar_t name[64]; DWORD nameLen = 64;
        st = RegEnumKeyExW(key, i, name, &nameLen,
                           nullptr, nullptr, nullptr, nullptr);
        if (st == ERROR_NO_MORE_ITEMS) break;
        if (st != ERROR_SUCCESS) break;
        wprintf(L"    键 %s\n", name);
    }

    // ── 5. 清场：整棵删除（环境还原）────────────────────────────
    RegCloseKey(key);
    st = RegDeleteTreeW(HKEY_CURRENT_USER, kRoot);
    wprintf(L"[5] RegDeleteTreeW 清场：%s\n",
            st == ERROR_SUCCESS ? L"已删除" : L"失败");
    return 0;
}
```

- [ ] **Step 2: 编译并运行验证**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 25_registry_tool/main.cpp && ./build/25_registry_tool.exe
  ```

  预期：`问候 = 你好，注册表`、枚举出 3 值 2 子键、`已删除`、退出码 0。复查：`reg query HKCU\Software\GuideWin32` 报"找不到"。

- [ ] **Step 3: 填充 21 章占位（约 380 行）**

  1. 开篇三件（前置 17；成果：注册表读写工具）
  2. 21.1 注册表是什么：配置数据库（vs ini 文件的三个不够）；注册表编辑器 `regedit` 参观路线（只看不动！）
  3. 21.2 五大根键表（HKCR/HKCU/HKLM/HKU/HKCC）+ "HKCR 是 HKLM\Software\Classes 与 HKCU\Software\Classes 的合成视图"——**这句话 24 章直接用**
  4. 21.3 数据模型：键/值/树形 ASCII 图；类型表（SZ/EXPAND_SZ/DWORD/QWORD/BINARY/MULTI_SZ 各自装什么）
  5. 21.4 增：`RegCreateKeyExW`（创建或打开的合一语义）与 `RegOpenKeyExW`
  6. 21.5 写：`RegSetValueExW` 全参数；**REG_SZ 字节数含结尾 NUL** 的坑（图解）
  7. 21.6 读：两段式（先探大小）与定长缓冲；`RegGetValueW` 一步式 + 自动展开 EXPAND_SZ
  8. 21.7 枚举：`RegEnumValueW`/`RegEnumKeyExW` 的 `ERROR_NO_MORE_ITEMS` 循环模式（25 示例解剖）
  9. 21.8 删除：`RegDeleteKeyW` vs `RegDeleteTreeW`
  10. 21.9 64 位重定向与权限：WOW64 的 `Wow6432Node`（32 位进程看到的世界）；HKLM 写需管理员 vs HKCU；应用配置放 `HKCU\Software\<公司>\<产品>` 的惯例
  11. 21.10 reg.exe 命令对照表（query/add/delete/export）
  12. 易错清单：字节数漏 NUL / 忘 `RegCloseKey` / 32 位进程查 64 位键扑空 / 在 HKLM 硬写拿不到权限（呼应 17 章 UAC）
  13. 小结 + 练习（把 25 示例改成带 `--dump <路径>` 参数的查看器）

- [ ] **Step 4: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 21-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：25 工程全绿。

  ```bash
  git add -A && git commit -m "docs(win32): 21 注册表新章 + 25 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 12: 批 11 COM——22/23/24 章 + 26/27 示例

**Files:**
- Modify: `win32/docs/22-COM入门.md`（填充占位）
- Modify: `win32/docs/23-COM实战.md`（填充占位）
- Modify: `win32/docs/24-COM实现.md`（填充占位）
- Create: `win32/examples/26_com_file_dialog/main.cpp`
- Create: `win32/examples/27_com_server/{calc.h,server.cpp,main.cpp,build.ps1}`

**Interfaces:**
- Consumes: 03 章 HRESULT、20 章显式链接、21 章注册表。
- Produces: `IID_ICalc`/`CLSID_Calc`（Global Constraints 固定值）；27 的 `calcdll.dll` 常驻 `build\`（24 宿主会跳过它——24 章文档要提到这个联动）；22~24 章是 25/26/29 章（D2D/WinRT/拖放）的引用基座。

- [ ] **Step 1: 写 `examples/26_com_file_dialog/main.cpp` 全文**

```cpp
// 26_com_file_dialog — CoInitializeEx + ComPtr + IFileOpenDialog 实战
//
// 对应教程：docs/23-COM实战.md
#include <windows.h>
#include <shobjidl_core.h>     // IFileOpenDialog、CLSID_FileOpenDialog
#include <wrl/client.h>        // Microsoft::WRL::ComPtr
#include <stdio.h>

#define IDC_OPEN 1301
#define IDC_PATH 1302

using Microsoft::WRL::ComPtr;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        CreateWindowExW(0, L"BUTTON", L"打开文件（COM 对话框）",
            WS_CHILD | WS_VISIBLE, 10, 10, 220, 36, hwnd,
            (HMENU)(INT_PTR)IDC_OPEN, cs->hInstance, nullptr);
        CreateWindowExW(0, L"STATIC", L"（点击按钮选择文件）",
            WS_CHILD | WS_VISIBLE, 10, 64, 560, 24, hwnd,
            (HMENU)(INT_PTR)IDC_PATH, cs->hInstance, nullptr);
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_OPEN) {
            ComPtr<IFileOpenDialog> dlg;
            HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                          CLSCTX_INPROC_SERVER,
                                          IID_PPV_ARGS(&dlg));
            if (FAILED(hr)) return 0;

            FILEOPENDIALOGOPTIONS opts = 0;
            dlg->GetOptions(&opts);
            dlg->SetOptions(opts | FOS_FORCEFILESYSTEM | FOS_ALLOWMULTISELECT);

            hr = dlg->Show(hwnd);              // 模态：内部自转消息循环
            if (FAILED(hr)) {
                if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
                    SetWindowTextW(GetDlgItem(hwnd, IDC_PATH), L"（用户取消）");
                }
                return 0;
            }
            ComPtr<IShellItem> item;
            if (SUCCEEDED(dlg->GetResult(&item))) {
                PWSTR path = nullptr;
                item->GetDisplayName(SIGDN_FILESYNCHESIS, &path);
                SetWindowTextW(GetDlgItem(hwnd, IDC_PATH), path ? path : L"?");
                CoTaskMemFree(path);           // COM 内存统一走 IMalloc/CoTaskMem
            }
            return 0;
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    // COM 使用前初始化（每线程一次），配对 CoUninitialize——一切 COM 程序的开场白
    if (FAILED(CoInitializeEx(nullptr, COINIT_APARTMENTED))) return 1;

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ComDialogClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ComDialogClass", L"IFileOpenDialog 演示",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 620, 150,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    CoUninitialize();
    return (int)msg.wParam;
}
```

- [ ] **Step 2: 写 `examples/27_com_server` 四个文件**

`calc.h`：

```cpp
// calc.h — 宿主与 COM 服务器共享的接口定义（教学版：无 IDL 直接写）
#pragma once
#include <windows.h>
#include <unknwn.h>

// IID_ICalc = {1DBE71E1-2CA9-417E-AF41-2A2101510601}
static const IID IID_ICalc =
    { 0x1DBE71E1, 0x2CA9, 0x417E,
      { 0xAF, 0x41, 0x2A, 0x21, 0x01, 0x51, 0x06, 0x01 } };
// CLSID_Calc = {6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}
static const CLSID CLSID_Calc =
    { 0x6B92FBEE, 0x1E6D, 0x4010,
      { 0x9A, 0xC0, 0x57, 0x83, 0xE2, 0x88, 0xF9, 0xC1 } };

// COM 接口 = 纯虚类 + IUnknown 头三个方法。vtable 布局即二进制契约。
interface ICalc : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Add(int a, int b, int* result) = 0;
    virtual HRESULT STDMETHODCALLTYPE Sub(int a, int b, int* result) = 0;
};
```

`server.cpp`：

```cpp
// server.cpp — 进程内 COM 服务器（编译成 calcdll.dll）
//
// 对应教程：docs/24-COM实现.md
#include "calc.h"
#include <new>

static HMODULE g_module = nullptr;

// ── 组件实现：引用计数 + QueryInterface ───────────────────────
class Calc : public ICalc {
    LONG m_ref = 1;                       // 诞生即被引用一次
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_ICalc) {
            *ppv = static_cast<ICalc*>(this);
            AddRef();                     // 给出指针就要 AddRef——COM 铁律
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override {
        return InterlockedIncrement(&m_ref);
    }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;          // 归零自毁——COM 的生命周期规则
        return n;
    }
    STDMETHODIMP Add(int a, int b, int* result) override {
        if (!result) return E_POINTER;
        *result = a + b;
        return S_OK;
    }
    STDMETHODIMP Sub(int a, int b, int* result) override {
        if (!result) return E_POINTER;
        *result = a - b;
        return S_OK;
    }
};

// ── 类厂：CoCreateInstance 与对象之间的中介 ────────────────────
class CalcFactory : public IClassFactory {
    LONG m_ref = 1;
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_IClassFactory) {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_ref); }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;
        return n;
    }
    STDMETHODIMP CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
        if (outer) return CLASS_E_NOAGGREGATION;   // 教学版不支持聚合
        Calc* obj = new (std::nothrow) Calc();
        if (!obj) return E_OUTOFMEMORY;
        HRESULT hr = obj->QueryInterface(riid, ppv);   // QI 已 AddRef
        obj->Release();                                // 抵消构造时的 1
        return hr;
    }
    STDMETHODIMP LockServer(BOOL) override {
        return S_OK;    // 教学版不做服务器级锁计数
    }
};

// ── 四个标准导出（COM DLL 的门面）────────────────────────────
extern "C" __declspec(dllexport)
HRESULT STDAPICALLTYPE DllGetClassObject(REFCLSID rclsid, REFIID riid, void** ppv) {
    if (rclsid != CLSID_Calc) return CLASS_E_CLASSNOTAVAILABLE;
    CalcFactory* f = new (std::nothrow) CalcFactory();
    if (!f) return E_OUTOFMEMORY;
    HRESULT hr = f->QueryInterface(riid, ppv);
    f->Release();
    return hr;
}

extern "C" __declspec(dllexport)
HRESULT STDAPICALLTYPE DllCanUnloadNow() {
    return S_FALSE;    // 教学版常驻内存
}

static const wchar_t* kClsidPath =
    L"Software\\Classes\\CLSID\\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}";
static const wchar_t* kInproc = L"Software\\Classes\\CLSID\\"
                                L"{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}"
                                L"\\InprocServer32";

extern "C" __declspec(dllexport)
HRESULT STDAPICALLTYPE DllRegisterServer() {
    // 写 HKCU\Software\Classes\...：免管理员的 per-user 注册
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(g_module, path, MAX_PATH);

    HKEY key;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, kInproc, 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
        return E_FAIL;
    }
    RegSetValueExW(key, nullptr, 0, REG_SZ, (const BYTE*)path,
                   (DWORD)((wcslen(path) + 1) * sizeof(wchar_t)));
    const wchar_t* apartment = L"Apartment";
    RegSetValueExW(key, L"ThreadingModel", 0, REG_SZ,
                   (const BYTE*)apartment,
                   (DWORD)((wcslen(apartment) + 1) * sizeof(wchar_t)));
    RegCloseKey(key);
    return S_OK;
}

extern "C" __declspec(dllexport)
HRESULT STDAPICALLTYPE DllUnregisterServer() {
    RegDeleteTreeW(HKEY_CURRENT_USER, kClsidPath);
    return S_OK;
}

BOOL APIENTRY DllMain(HMODULE hinst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_module = hinst;                  // 记下自己，注册时要写全路径
        DisableThreadLibraryCalls(hinst);
    }
    return TRUE;
}
```

`main.cpp`（消费者，全链路）：

```cpp
// 27_com_server 消费者 — 注册 → CoCreateInstance → 使用 → 注销 全链路
//
// 对应教程：docs/24-COM实现.md
// 本示例由 27_com_server/build.ps1 构建（server dll + 本 exe 三步）
#include "calc.h"
#include <windows.h>
#include <stdio.h>
#include <locale.h>

typedef HRESULT (STDAPICALLTYPE* PfnDllServer)(void);

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // 1. 手动注册：LoadLibrary + GetProcAddress 调 DllRegisterServer
    //    （regsvr32 干的就是这件事——第 20 章显式链接的又一课）
    HMODULE dll = LoadLibraryW(L"calcdll.dll");      // 裸名：exe 目录搜索
    if (!dll) {
        wprintf(L"加载 calcdll.dll 失败 %lu\n", GetLastError());
        return 1;
    }
    PfnDllServer reg =
        (PfnDllServer)GetProcAddress(dll, "DllRegisterServer");
    if (reg && SUCCEEDED(reg())) {
        wprintf(L"[1] DllRegisterServer → 已注册到 HKCU\\Software\\Classes\n");
    }

    // 2. COM 大门：初始化 + 创建
    if (FAILED(CoInitializeEx(nullptr, COINIT_APARTMENTED))) return 1;

    ICalc* calc = nullptr;
    HRESULT hr = CoCreateInstance(CLSID_Calc, nullptr, CLSCTX_INPROC_SERVER,
                                  IID_ICalc, (void**)&calc);
    if (FAILED(hr)) {
        wprintf(L"[2] CoCreateInstance 失败 0x%08lX\n", (unsigned long)hr);
        CoUninitialize();
        return 1;
    }
    wprintf(L"[2] CoCreateInstance 成功（COM 替你 LoadLibrary 了我们刚注册的 DLL）\n");

    // 3. 调接口方法
    int sum = 0, diff = 0;
    calc->Add(20, 22, &sum);
    calc->Sub(50, 8, &diff);
    wprintf(L"[3] Add(20,22) = %d，Sub(50,8) = %d\n", sum, diff);

    // 4. 引用计数现场观察
    ULONG n = calc->AddRef();
    wprintf(L"[4] AddRef 后引用计数 = %lu（Release 归位）\n", (unsigned long)n);
    calc->Release();

    // 5. 释放与注销——环境还原
    calc->Release();          // 归零 → 组件自毁
    CoUninitialize();
    PfnDllServer unreg =
        (PfnDllServer)GetProcAddress(dll, "DllUnregisterServer");
    if (unreg && SUCCEEDED(unreg())) {
        wprintf(L"[5] DllUnregisterServer → 注册表已清理\n");
    }
    FreeLibrary(dll);
    wprintf(L"全链路完成\n");
    return 0;
}
```

`build.ps1`（**纯 ASCII**）：

```powershell
# 27_com_server build: COM DLL (calcdll.dll) + consumer exe, run full chain
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "27_com_server"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# 1) COM server DLL (exports DllGetClassObject / DllRegisterServer / ...)
Invoke-Cl ('cl {0} /c server.cpp /Fo:"{1}\{2}_server.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\calcdll.dll" "{0}\{1}_server.obj" kernel32.lib user32.lib ole32.lib advapi32.lib' -f $buildDir, $name)
# 2) consumer exe
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" ole32.lib advapi32.lib' -f $buildDir, $name)
# 3) run full chain: register -> create -> use -> unregister (HKCU only, no admin)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "com chain failed" }
```

- [ ] **Step 3: 验证 26/27**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 26_com_file_dialog/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 27_com_server/main.cpp
  ```

  预期：26 编译过（GUI）；27 输出 `[1]~[5]` 全链路 + `全链路完成`。复查环境还原：

  ```bash
  reg query "HKCU\Software\Classes\CLSID\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}" 2>&1 | head -2
  ```

  预期：系统找不到指定的注册表项（已注销干净）。

- [ ] **Step 4: 填充 22 章占位（约 430 行）**

  1. 开篇三件（前置 19/20；成果：读懂任何 COM 报错与代码骨架）
  2. 22.1 为什么会有 COM：二进制级复用难题——C++ 类跨编译器/跨模块边界不可靠（名字修饰/内存布局/CRT 各一套）；"接口与实现彻底分离"的答案
  3. 22.2 对象模型：组件/接口/方法三层 ASCII 图；**接口 = vtable 契约**（对象内存布局图：vptr → vtable[QueryInterface,AddRef,Release,方法…]）；与 C++ 虚类对照表（相同：纯虚+虚析构语义；不同：调用约定固定/无名字修饰/ lifetime 明确规则）
  4. 22.3 `IUnknown` 精讲：`QueryInterface`（接口导航器 + "同一对象所有 QI(IUnknown) 必须相等"的身份规则）；`AddRef/Release`（所有权规则表：**拿到接口要 Release、给出接口要 AddRef**）；引用计数环问题一段（弱引用一句话）
  5. 22.4 `HRESULT` 回顾（链到 03 章）+ `FACILITY_ITF`；`IErrorInfo`/富错误信息一句话
  6. 22.5 GUID/IID/CLSID：128 位唯一性；字符串形式；注册表里的家（链 21 章）
  7. 22.6 `ComPtr`（`wrl/client.h`）：手工计数样板代码 → RAII 封装；`Get/GetAddressOf/ReleaseAndGetAddressOf/&` 用法表；与 `std::unique_ptr` 的差异（Release 语义是方法调用不是 delete）
  8. 22.7 套间概念级：为什么有线程亲缘问题（STA 的消息泵本质）；`COINIT_APARTMENTED` vs `COINIT_MULTITHREADED`；一张图；27 章 ThreadingModel 呼应
  9. 易错清单：忘 Release 泄漏 / 双重 Release 崩溃 / 出参给了指针忘 AddRef / 判接口用 `SUCCEEDED(hr)` 而不是判指针空
  10. 小结 + 练习（手写一个最小 IUnknown 实现并数引用计数——预习 24 章）

- [ ] **Step 5: 填充 23 章占位（约 380 行）**

  1. 开篇三件（前置 22；成果：COM 版文件对话框）
  2. 23.1 使用 COM 的五步骨架图与配对表：`CoInitializeEx` ↔ `CoUninitialize`、`CoCreateInstance` ↔ `Release`
  3. 23.2 逐步精讲：`CoCreateInstance` 五参数（CLSID 哪来的：SDK 头/注册表/`CLSIDFromProgID`）；`CLSCTX_INPROC_SERVER` 等上下文表；`IID_PPV_ARGS` 双保险
  4. 23.3 `IFileOpenDialog` 实战（26 示例全文解剖，分六段）：options 位或、`Show` 模态、取消的处理（`ERROR_CANCELLED`→HRESULT）、`GetResult`→`IShellItem`→`GetDisplayName`、`CoTaskMemFree`（**COM 内存约定：组件分配的内存用 `CoTaskMemFree` 释放**——第 20 章"内存不跨界"的官方解法）
  5. 23.4 与 `GetOpenFileNameW`（10 章）对比表：能力/体积/扩展性
  6. 23.5 系统里的 COM 组件地图：Shell/对话框/DirectX（25 章）/WinRT（26 章）/拖放（29 章）
  7. 23.6 常见坑：工作线程忘初始化 COM、STA 里阻塞消息循环、老系统 IID 缺失
  8. 易错清单 + 小结 + 练习（改成 `IFileSaveDialog` + 文件类型过滤）

- [ ] **Step 6: 填充 24 章占位（约 430 行）**

  1. 开篇三件（前置 21/22/23；成果：自己的 COM 组件 + 全链路消费者）
  2. 24.1 反向理解 `CoCreateInstance`：SCM 查注册表 → `LoadLibrary` → `DllGetClassObject` → 类厂 `CreateInstance` → `QueryInterface`——**全链路 ASCII 泳道图**（本章骨架图）
  3. 24.2 接口定义（calc.h）：教学版无 IDL 路线 vs 工业 IDL/midl 路线对照一段；GUID 必须固定（编译期生成一次写死）
  4. 24.3 组件实现（server.cpp 的 Calc 解剖）：QI 身份规则落地；引用计数自毁；方法参数校验（`E_POINTER`）
  5. 24.4 类厂：`IClassFactory` 两方法；`CreateInstance` 里 QI+Release 配平的算术（为什么是加一减一）
  6. 24.5 四个标准导出逐个讲；注册表写哪些键（键树 ASCII：`CLSID\{...}\InprocServer32` 默认值=DLL 路径、`ThreadingModel`）
  7. 24.6 注册三路线对比表：`regsvr32`（HKLM，要管理员）/**HKCU per-user**（本教程路线，免管理员）/**免注册清单**（Reg-Free COM，manifest 一句话）
  8. 24.7 消费者全链路（main.cpp 解剖）：手动注册也是显式链接一课（链 20 章）；引用计数观察段
  9. 24.8 `ThreadingModel=Apartment` 到底承诺了什么（回看 22.7）
  10. 易错清单：QI 出指针忘 AddRef / GUID 每次重编译变了（用 `#include` 共享而不是各自 `static`——27 示例 calc.h 的做法）/ 注销忘 `RegDeleteTreeW` 留残键 / `CLSCTX` 写错加载不到
  11. 小结 + 练习（加 `Mul` 方法；写第二个组件换 CLSID 并存）

- [ ] **Step 7: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 22-*.md 23-*.md 24-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：三章 380~450 行；27 工程全绿（4 个委托）。

  ```bash
  git add -A && git commit -m "docs(win32): COM 三章——入门/实战/手写进程内服务器 + 26/27 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 13: 批 12 现代渲染与 WinRT——28/29 示例 + 25/26 章

**Files:**
- Create: `win32/examples/28_direct2d_hello/main.cpp`
- Create: `win32/examples/29_winrt_modern/{main.cpp,build.ps1}`
- Modify: `win32/docs/25-Direct2D与DirectWrite.md`（填充占位）
- Modify: `win32/docs/26-WinRT与CppWinRT.md`（填充占位）

**Interfaces:**
- Consumes: 09 章 GDI 对照、22 章 COM 知识（D2D 全是 COM 接口）。
- Produces: 28 走默认构建路径（d2d1/dwrite 已在 Task 1 进默认库）；29 是唯一需要 cppwinrt 头 + WindowsApp.lib 的工程（自带子 build.ps1）。

- [ ] **Step 1: 写 `examples/28_direct2d_hello/main.cpp` 全文**

```cpp
// 28_direct2d_hello — Direct2D 渐变/抗锯齿图形 + DirectWrite 文本 + resize/重建
//
// 对应教程：docs/25-Direct2D与DirectWrite.md
#include <windows.h>
#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>

template <class T> void SafeRelease(T** p) {
    if (*p) { (*p)->Release(); *p = nullptr; }
}

static ID2D1Factory*             g_factory = nullptr;
static IDWriteFactory*           g_dw      = nullptr;
static ID2D1HwndRenderTarget*    g_target  = nullptr;
static ID2D1SolidColorBrush*     g_solid   = nullptr;
static ID2D1LinearGradientBrush* g_grad    = nullptr;
static IDWriteTextFormat*        g_format  = nullptr;

static const wchar_t kText[] =
    L"Direct2D + DirectWrite\n硬件加速 · 抗锯齿 · 设备无关像素";

static void CreateDeviceResources(HWND hwnd) {
    if (g_target) return;
    RECT rc; GetClientRect(hwnd, &rc);
    g_factory->CreateHwndRenderTarget(
        D2D1::RenderTargetProperties(),
        D2D1::HwndRenderTargetProperties(
            hwnd, D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top)),
        &g_target);

    g_target->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::White), &g_solid);

    ID2D1GradientStopCollection* stops = nullptr;
    D2D1_GRADIENT_STOP gs[] = {
        { 0.0f, D2D1::ColorF(D2D1::ColorF::CornflowerBlue)   },
        { 1.0f, D2D1::ColorF(D2D1::ColorF::MediumVioletRed)  },
    };
    g_target->CreateGradientStopCollection(gs, 2, &stops);
    g_target->CreateLinearGradientBrush(
        D2D1::LinearGradientBrushProperties(
            D2D1::Point2F(0, 0), D2D1::Point2F(700, 0)),
        stops, &g_grad);
    stops->Release();
}

static void DiscardDeviceResources() {
    // 画刷是"设备相关资源"，绑定在 target 上：先画刷后 target
    SafeRelease(&g_solid);
    SafeRelease(&g_grad);
    SafeRelease(&g_target);
}

static void Draw() {
    g_target->BeginDraw();
    g_target->Clear(D2D1::ColorF(0.09f, 0.10f, 0.14f));       // 深色底

    D2D1_SIZE_F size = g_target->GetSize();
    g_target->FillRoundedRectangle(                            // 抗锯齿圆角矩形
        D2D1::RoundedRect(
            D2D1::RectF(60, 60, size.width - 60, size.height - 60), 18, 18),
        g_grad);
    g_target->DrawEllipse(                                     // 抗锯齿圆
        D2D1::Ellipse(D2D1::Point2F(170, 190), 70, 70), g_solid, 2.0f);
    g_target->DrawTextW(                                       // DirectWrite 文本
        kText, (UINT32)lstrlenW(kText), g_format,
        D2D1::RectF(280, 140, size.width - 80, 260), g_solid);

    if (g_target->EndDraw() == (HRESULT)D2DERR_RECREATE_TARGET) {
        DiscardDeviceResources();   // 设备丢失（锁屏/驱动重置）：释放待重建
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_PAINT:
        ValidateRect(hwnd, nullptr);   // D2D 自己管理脏区；这行只是安抚 GDI 体系
        CreateDeviceResources(hwnd);
        Draw();
        return 0;
    case WM_SIZE:
        if (g_target) {
            D2D1_SIZE_U s = D2D1::SizeU(LOWORD(lParam), HIWORD(lParam));
            g_target->Resize(s);       // 渲染目标跟窗口走
            InvalidateRect(hwnd, nullptr, FALSE);
        }
        return 0;
    case WM_ERASEBKGND:
        return 1;                      // 不让 GDI 擦背景——防闪
    case WM_DESTROY:
        DiscardDeviceResources();
        SafeRelease(&g_format);
        SafeRelease(&g_dw);
        SafeRelease(&g_factory);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    // 两个工厂：D2D 管"怎么画"，DWrite 管"文字"
    D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &g_factory);
    DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                        (IUnknown**)&g_dw);
    g_dw->CreateTextFormat(L"微软雅黑", nullptr, DWRITE_FONT_WEIGHT_NORMAL,
                           DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
                           26.0f, L"zh-CN", &g_format);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.lpszClassName = L"D2DHelloClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"D2DHelloClass", L"Direct2D + DirectWrite",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 760, 420,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
```

- [ ] **Step 2: 写 `examples/29_winrt_modern` 两个文件**

`main.cpp`：

```cpp
// 29_winrt_modern — 从 Win32 控制台调用 WinRT（C++/WinRT 投影 + C++20 协程）
//
// 对应教程：docs/26-WinRT与CppWinRT.md
// 本示例由 29_winrt_modern/build.ps1 构建（额外带 cppwinrt 头与 WindowsApp.lib）
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.DateTimeFormatting.h>
#include <winrt/Windows.System.Threading.h>
#include <stdio.h>
#include <locale.h>

namespace wf = winrt::Windows::Foundation;

// C++20 协程消费 WinRT 异步：co_await 一个 IAsyncAction
static wf::IAsyncAction WorkAsync() {
    co_await winrt::Windows::System::Threading::ThreadPool::RunAsync(
        [](auto&&) { /* 工作项在线程池上执行（此处空转演示） */ });
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // WinRT 版的 CoInitializeEx
    winrt::init_apartment(winrt::apartment_type::single_threaded);

    // 1) 投影类型：像普通 C++ 类一样用系统组件
    using namespace winrt::Windows::Globalization::DateTimeFormatting;
    DateTimeFormatter date{ L"{year.full} 年 {month.integer(2)} 月 {day.integer(2)} 日" };
    DateTimeFormatter time{ L"{hour.integer(2)}:{minute.integer(2)}:{second.integer(2)}" };
    auto now = winrt::clock::now();
    wprintf(L"[1] 今天：%s\n", date.Format(now).c_str());
    wprintf(L"    现在：%s（格式化由系统组件完成，不是我们写的）\n",
            time.Format(now).c_str());

    // 2) 协程异步：提交线程池工作并等待
    wprintf(L"[2] 提交线程池工作并 co_await ...\n");
    auto action = WorkAsync();
    action.get();               // 阻塞等完成（真实程序里会继续 co_await）
    wprintf(L"    工作完成\n");

    wprintf(L"演示结束（没有手工引用计数——投影全托管了）\n");
    return 0;
}
```

  **降级预案**（若协程在当前 SDK 的 cppwinrt 头下编译失败）：把 `WorkAsync` 与 `action.get()` 段替换为直调版并保留注释说明——

```cpp
    auto action = winrt::Windows::System::Threading::ThreadPool::RunAsync(
        [](auto&&) { });
    action.get();               // IAsyncAction::get() 同样阻塞等待
```

`build.ps1`（**纯 ASCII**）：

```powershell
# 29_winrt_modern build: only extras = cppwinrt headers + WindowsApp.lib
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$sdkRoot = "C:\Program Files (x86)\Windows Kits\10\Include"
$name = "29_winrt_modern"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

# find newest SDK that actually has cppwinrt headers
$cppwinrt = $null
Get-ChildItem -Path $sdkRoot -Directory | Sort-Object Name -Descending | ForEach-Object {
    if (-not $cppwinrt) {
        $candidate = Join-Path $_.FullName "cppwinrt"
        if (Test-Path (Join-Path $candidate "winrt")) { $cppwinrt = $candidate }
    }
}
if (-not $cppwinrt) { throw "cppwinrt headers not found under $sdkRoot" }
Write-Host "[Info] cppwinrt: $cppwinrt"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

Invoke-Cl ('cl {0} /I "{1}" /c main.cpp /Fo:"{2}\{3}_main.obj"' -f $common, $cppwinrt, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" WindowsApp.lib' -f $buildDir, $name)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "run failed" }
```

- [ ] **Step 3: 验证 28/29**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 28_direct2d_hello/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 29_winrt_modern/main.cpp
  ```

  预期：28 编译过 + 冒烟 3 秒存活（设计期 spike 已验过同款代码）；29 输出今天日期 + `[2] 工作完成` + 退出码 0。

- [ ] **Step 4: 填充 25 章占位（约 420 行）**

  1. 开篇三件（前置 09 GDI、22 COM；成果：D2D 渲染的现代窗口）
  2. 25.1 为什么有 D2D：GDI 三痛点（无抗锯齿/无硬件加速/无设备无关像素）对照表；D2D 的回答
  3. 25.2 一眼认出 D2D 是 COM：`factory->CreateXxx`/`Release` 的熟面孔（22 章知识直接变现；示例用原生 Release，ComPtr 写法给一小段对照）
  4. 25.3 对象层级图：`Factory → RenderTarget → 资源`；**设备无关资源**（factory 建）vs **设备相关资源**（target 建）表——理解谁跟谁走，生命周期就懂了
  5. 25.4 `HwndRenderTarget`：创建参数；`BeginDraw/EndDraw` 取代 `BeginPaint/EndPaint` 的映射表；`WM_ERASEBKGND` 返回 1 防闪
  6. 25.5 绘制调用：`Clear/FillRoundedRectangle/DrawEllipse`；同一颗圆 GDI vs D2D 边缘放大对比描述
  7. 25.6 画刷：solid / linear gradient（stops 数组概念图）/ bitmap 一句话
  8. 25.7 DirectWrite：独立工厂；`TextFormat`（字体/字号/locale）；`DrawTextW` 与 GDI `DrawTextW` 的差异（DIP 单位）；`TextLayout` 高级排版一句话
  9. 25.8 窗口变化与设备丢失：`Resize`；`D2DERR_RECREATE_TARGET` 丢弃重建模式（28 示例解剖）
  10. 25.9 与 GDI 互操作（DC Target）一段 + "何时仍用 GDI"（改一个按钮颜色不值得上 D2D）
  11. 易错清单：忘 `EndDraw` / 画刷比 target 活得久（悬空）/ 用像素思维算 DIP / 不处理 RECREATE 白屏
  12. 小结 + 练习（`WM_TIMER` 驱动圆移动动画）

- [ ] **Step 5: 填充 26 章占位（约 400 行）**

  1. 开篇三件（前置 22~24；成果：从 Win32 调用 WinRT 的最短路径）
  2. 26.1 WinRT 是什么：COM 直系后代（`IInspectable : IUnknown` 继承图）；API 全类库化（命名空间/类/事件/异步）；`.winmd` 元数据（类型自描述——比 typelib 进化在哪）
  3. 26.2 激活机制：`RoGetActivationFactory`（`CoCreateInstance` 的现代对应物）泳道图；投影内部就在做这件事——**用 C++/WinRT 不等于没用 COM，是 COM 被封装了**
  4. 26.3 C++/WinRT 投影：头文件即投影（`winrt/Windows.*.h`）；投影类型 vs ABI 接口；`winrt::hstring`（值语义）；工具链三件套表（cppwinrt 头 + `WindowsApp.lib` + `/std:c++20`）
  5. 26.4 `init_apartment`：套间知识复用（22.7）；与 `CoInitializeEx` 的关系
  6. 26.5 实战格式化（29 示例段 1 解剖）：`DateTimeFormatter` 模板语法表；`winrt::clock`
  7. 26.6 异步模型：`IAsyncAction`/`IAsyncOperation<T>`；**C++20 协程 `co_await`**（语言级支持 vs 回调地狱）；`.get()` 阻塞的适用与禁忌（UI 线程禁 `.get()`）
  8. 26.7 无打包 Win32 的能力边界：身份（AUMID）与能力（capability）概念；为什么 Toast 需要快捷方式配合（原理 + 文档指引，不在示例实跑）
  9. 26.8 WinRT 地图表：哪些现代能力**只**在 WinRT（通知/后台任务/现代传感器/应用生命周期）
  10. 易错清单：忘 `init_apartment` / 忘 include 对应 `winrt/*.h`（每命名空间一个头）/ 忘链 `WindowsApp.lib` / STA 里 `.get()` 死锁
  11. 小结 + 练习（`StorageFolder::GetFolderAsync` 枚举文档目录并打印）

- [ ] **Step 6: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 25-*.md 26-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：两章 400~450 行；29 工程全绿（5 个委托）。

  ```bash
  git add -A && git commit -m "docs(win32): 25 Direct2D/DirectWrite / 26 WinRT 与 C++/WinRT 新章 + 28/29 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 14: 批 13 平台专题——30/31/32 示例 + 27/28/29 章

**Files:**
- Create: `win32/examples/30_windows_service/main.cpp`
- Create: `win32/examples/31_shell_tray/main.cpp`
- Create: `win32/examples/32_clipboard_dnd/main.cpp`
- Modify: `win32/docs/27-Windows服务与事件日志.md`、`win32/docs/28-Shell集成.md`、`win32/docs/29-剪贴板与拖放.md`（填充占位）

**Interfaces:**
- Consumes: 14 章线程/事件、17 章权限、24 章 COM 实现（32 的 IDropTarget 是第二次手写 COM）、26 章（Toast 指路）。
- Produces: 三个示例分别走默认构建路径（控制台/GUI）；27 章"双模式服务开发法"是教程服务知识的落点。

- [ ] **Step 1: 写 `examples/30_windows_service/main.cpp` 全文**

```cpp
// 30_windows_service — 最小服务 + 事件日志 + 控制台/list 双模式
//
// 对应教程：docs/27-Windows服务与事件日志.md
// 控制台程序；console/list 模式标准用户可跑；install/remove/start/stop 需管理员
#include <windows.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* kSvcName = L"GuideDemoSvc";
static const wchar_t* kSvcDisplay = L"Guide Win32 教程演示服务";

static SERVICE_STATUS        g_status = {};
static SERVICE_STATUS_HANDLE g_statusHandle = nullptr;
static HANDLE g_stopEvent = nullptr;

static void ReportState(DWORD state, DWORD waitHint = 0) {
    g_status.dwCurrentState = state;
    g_status.dwWaitHint = waitHint;
    g_status.dwCheckPoint = (state == SERVICE_START_PENDING) ? 1 : 0;
    SetServiceStatus(g_statusHandle, &g_status);
}

static void LogEvent(WORD type, const wchar_t* msg) {
    HANDLE hLog = RegisterEventSourceW(nullptr, kSvcName);
    if (hLog) {
        const wchar_t* strings[] = { msg };
        ReportEventW(hLog, type, 0, 1, nullptr, 1, 0, strings, nullptr);
        DeregisterEventSource(hLog);
    }
}

// 服务主体：真正"干活"的循环（服务/控制台共用，便于先本地验证）
static void RunServiceCore(bool asService) {
    int tick = 0;
    while (WaitForSingleObject(g_stopEvent, 1000) == WAIT_TIMEOUT) {
        wchar_t buf[128];
        swprintf_s(buf, L"第 %d 次心跳（%s模式）", ++tick,
                   asService ? L"服务" : L"控制台");
        if (asService) LogEvent(EVENTLOG_INFORMATION_TYPE, buf);
        else           wprintf(L"    %s\n", buf);
        if (!asService && tick >= 3) break;   // 控制台模式 3 拍即收
    }
}

static DWORD WINAPI HandlerEx(DWORD control, DWORD, LPVOID, LPVOID) {
    if (control == SERVICE_CONTROL_STOP) {
        ReportState(SERVICE_STOP_PENDING, 2000);
        SetEvent(g_stopEvent);                // 通知主循环退出
    }
    return NO_ERROR;
}

static void WINAPI ServiceMain(DWORD, LPWSTR*) {
    g_statusHandle = RegisterServiceCtrlHandlerExW(kSvcName, HandlerEx, nullptr);
    if (!g_statusHandle) return;

    g_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    g_status.dwControlsAccepted = SERVICE_ACCEPT_STOP;
    ReportState(SERVICE_START_PENDING, 2000);

    g_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    ReportState(SERVICE_RUNNING);
    LogEvent(EVENTLOG_INFORMATION_TYPE, L"服务已启动");

    RunServiceCore(true);                     // 阻塞到收到停止

    ReportState(SERVICE_STOPPED);
    LogEvent(EVENTLOG_INFORMATION_TYPE, L"服务已停止");
    CloseHandle(g_stopEvent);
}

static int Install() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CREATE_SERVICE);
    if (!scm) {
        wprintf(L"OpenSCManager 失败 %lu（需要管理员）\n", GetLastError());
        return 1;
    }
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(nullptr, path, MAX_PATH);
    SC_HANDLE svc = CreateServiceW(scm, kSvcName, kSvcDisplay,
        SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, SERVICE_DEMAND_START,
        SERVICE_ERROR_NORMAL, path, nullptr, nullptr, nullptr, nullptr, nullptr);
    if (!svc) {
        wprintf(L"CreateService 失败 %lu\n", GetLastError());
        CloseServiceHandle(scm);
        return 1;
    }
    wprintf(L"已安装 %s（手动启动）。管理员执行：30_windows_service.exe start\n", kSvcName);
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int RemoveSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, DELETE) : nullptr;
    if (!svc) { wprintf(L"打开服务失败（不存在或需要管理员）\n"); if (scm) CloseServiceHandle(scm); return 1; }
    DeleteService(svc);
    wprintf(L"已标记删除 %s\n", kSvcName);
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int StartSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, SERVICE_START) : nullptr;
    if (!svc) { wprintf(L"打开服务失败（未安装或需要管理员）\n"); if (scm) CloseServiceHandle(scm); return 1; }
    BOOL ok = StartServiceW(svc, 0, nullptr);
    wprintf(L"%s\n", ok ? L"已发出启动请求" : L"启动失败（可能已在运行）");
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return ok ? 0 : 1;
}

static int StopSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, SERVICE_STOP) : nullptr;
    if (!svc) { wprintf(L"打开服务失败（未安装或需要管理员）\n"); if (scm) CloseServiceHandle(scm); return 1; }
    SERVICE_STATUS st = {};
    ControlService(svc, SERVICE_CONTROL_STOP, &st);
    wprintf(L"已发出停止请求\n");
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int ListServices() {   // 只需要枚举权限，标准用户可跑
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ENUMERATE_SERVICE);
    if (!scm) { wprintf(L"OpenSCManager 失败 %lu\n", GetLastError()); return 1; }
    DWORD need = 0, count = 0, resume = 0;
    EnumServicesStatusW(scm, SERVICE_WIN32_OWN_PROCESS, SERVICE_STATE_ALL,
                        nullptr, 0, &need, &count, &resume);
    need += 4096;
    LPENUM_SERVICE_STATUSW buf = (LPENUM_SERVICE_STATUSW)LocalAlloc(LMEM_FIXED, need);
    if (!EnumServicesStatusW(scm, SERVICE_WIN32_OWN_PROCESS, SERVICE_STATE_ALL,
                             buf, need, &need, &count, &resume)) {
        wprintf(L"EnumServicesStatus 失败 %lu\n", GetLastError());
        LocalFree(buf);
        CloseServiceHandle(scm);
        return 1;
    }
    wprintf(L"系统内自有进程服务共 %lu 个，前 8 个：\n", (unsigned long)count);
    for (DWORD i = 0; i < count && i < 8; ++i) {
        wprintf(L"    %-24s [%s]\n", buf[i].lpServiceName,
                buf[i].ServiceStatus.dwCurrentState == SERVICE_RUNNING
                    ? L"运行中" : L"未运行");
    }
    LocalFree(buf);
    CloseServiceHandle(scm);
    return 0;
}

int wmain(int argc, wchar_t** argv) {
    _wsetlocale(LC_ALL, L"");
    if (argc >= 2) {
        if (wcscmp(argv[1], L"install") == 0) return Install();
        if (wcscmp(argv[1], L"remove")  == 0) return RemoveSvc();
        if (wcscmp(argv[1], L"start")   == 0) return StartSvc();
        if (wcscmp(argv[1], L"stop")    == 0) return StopSvc();
        if (wcscmp(argv[1], L"list")    == 0) return ListServices();
        if (wcscmp(argv[1], L"console") == 0) {
            g_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
            wprintf(L"控制台模式：服务逻辑就地跑 3 拍（无需安装验证）\n");
            RunServiceCore(false);
            CloseHandle(g_stopEvent);
            return 0;
        }
    }
    // 无参数：由 SCM 调度（用户直接双击会得到提示）
    SERVICE_TABLE_ENTRYW table[] = {
        { (LPWSTR)kSvcName, ServiceMain }, { nullptr, nullptr }
    };
    if (!StartServiceCtrlDispatcherW(table)) {
        wprintf(L"可用动词：console / list / install / remove / start / stop\n");
        return 1;
    }
    return 0;
}
```

- [ ] **Step 2: 写 `examples/31_shell_tray/main.cpp` 全文**

```cpp
// 31_shell_tray — 托盘图标 + 右键菜单 + 气泡通知 + Explorer 重启恢复
//
// 对应教程：docs/28-Shell集成.md
#include <windows.h>
#include <shellapi.h>

#define WM_TRAYICON (WM_APP + 1)
#define IDM_SHOW    1
#define IDM_NOTIFY  2
#define IDM_EXIT    3

static UINT g_taskbarCreatedMsg;         // Explorer 重启广播的消息号
static NOTIFYICONDATAW g_nid;

static void AddTrayIcon(HWND hwnd) {
    g_nid = {};
    g_nid.cbSize = sizeof(g_nid);
    g_nid.hWnd = hwnd;
    g_nid.uID = 1;
    g_nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;                    // 事件路由到它
    g_nid.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    lstrcpynW(g_nid.szTip, L"托盘演示（右键菜单/双击显示）", 128);
    Shell_NotifyIconW(NIM_ADD, &g_nid);
}

static void ShowBalloon(const wchar_t* text) {
    g_nid.uFlags = NIF_INFO;                                 // 只动气泡字段
    lstrcpynW(g_nid.szInfo, text, 256);
    lstrcpynW(g_nid.szInfoTitle, L"来自托盘图标", 64);
    g_nid.dwInfoFlags = NIIF_INFO;
    Shell_NotifyIconW(NIM_MODIFY, &g_nid);
}

static void ShowMenu(HWND hwnd) {
    POINT pt; GetCursorPos(&pt);
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_SHOW,   L"显示窗口");
    AppendMenuW(menu, MF_STRING, IDM_NOTIFY, L"发个通知");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_EXIT,   L"退出");
    // 托盘菜单标准姿势：不先 SetForegroundWindow，点菜单外不会收起
    SetForegroundWindow(hwnd);
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        AddTrayIcon(hwnd);
        return 0;
    case WM_TRAYICON:
        if (lParam == WM_RBUTTONUP)          ShowMenu(hwnd);
        else if (lParam == WM_LBUTTONDBLCLK) ShowWindow(hwnd, SW_SHOW);
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_SHOW:
            ShowWindow(hwnd, SW_SHOW);
            SetForegroundWindow(hwnd);
            return 0;
        case IDM_NOTIFY:
            ShowBalloon(L"这是气泡通知。现代替代是 WinRT Toast（第 26 章）——"
                        L"它需要应用身份，见该章 26.7。");
            return 0;
        case IDM_EXIT:
            DestroyWindow(hwnd);
            return 0;
        }
        break;
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED) {
            ShowWindow(hwnd, SW_HIDE);       // 最小化进托盘：藏窗口留图标
            return 0;
        }
        break;
    case WM_DESTROY:
        Shell_NotifyIconW(NIM_DELETE, &g_nid);   // 图标必须收走，否则留"幽灵"
        PostQuitMessage(0);
        return 0;
    default:
        if (msg == g_taskbarCreatedMsg) {
            AddTrayIcon(hwnd);               // Explorer 重启：重挂图标
            return 0;
        }
        break;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    g_taskbarCreatedMsg = RegisterWindowMessageW(L"TaskbarCreated");

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"TrayDemoClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"TrayDemoClass", L"托盘演示（最小化藏进托盘）",
        WS_OVERLAPPEDWINDOW | WS_MINIMIZEBOX, CW_USEDEFAULT, CW_USEDEFAULT, 480, 200,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
```

- [ ] **Step 3: 写 `examples/32_clipboard_dnd/main.cpp` 全文**

```cpp
// 32_clipboard_dnd — 剪贴板 CF_UNICODETEXT 全链路 + WM_DROPFILES + 手写 IDropTarget
//
// 对应教程：docs/29-剪贴板与拖放.md
// OLE 拖放要求用 OleInitialize（不能用 CoInitialize）
#include <windows.h>
#include <oleidl.h>

#define IDC_SRC      1401
#define IDC_DST      1402
#define IDC_COPY     1403
#define IDC_PASTE    1404
#define IDC_DROPLIST 1405

static HWND g_src, g_dst, g_dropList;

// ── 剪贴板：写（四步协议：开→清→设→关）────────────────────────
static bool CopyToClipboard(HWND hwnd, const wchar_t* text) {
    if (!OpenClipboard(hwnd)) return false;      // 独占打开
    EmptyClipboard();                            // 清空并取得所有权
    size_t bytes = (lstrlenW(text) + 1) * sizeof(wchar_t);
    HGLOBAL mem = GlobalAlloc(GMEM_MOVEABLE, bytes);   // 必须可移动内存
    if (!mem) { CloseClipboard(); return false; }
    CopyMemory(GlobalLock(mem), text, bytes);
    GlobalUnlock(mem);
    SetClipboardData(CF_UNICODETEXT, mem);       // 所有权交给剪贴板：不再 GlobalFree！
    CloseClipboard();
    return true;
}

// ── 剪贴板：读 ──────────────────────────────────────────────
static bool PasteFromClipboard(HWND hwnd, wchar_t* buf, size_t cap) {
    if (!OpenClipboard(hwnd)) return false;
    bool ok = false;
    HANDLE h = GetClipboardData(CF_UNICODETEXT);
    if (h) {
        const wchar_t* p = (const wchar_t*)GlobalLock(h);
        if (p) {
            lstrcpynW(buf, p, (int)cap);
            GlobalUnlock(h);
            ok = true;
        }
    }
    CloseClipboard();
    return ok;
}

// ── 手写 COM 接口：IDropTarget（第 24 章知识的第二次实战）──────
class DropTarget : public IDropTarget {
    LONG m_ref = 1;
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (riid == IID_IUnknown || riid == IID_IDropTarget) {
            *ppv = static_cast<IDropTarget*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_ref); }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;
        return n;
    }
    STDMETHODIMP DragEnter(IDataObject* obj, DWORD, POINTL, DWORD* effect) override {
        FORMATETC fmt = { CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
        *effect = (obj->QueryGetData(&fmt) == S_OK) ? DROPEFFECT_COPY
                                                    : DROPEFFECT_NONE;
        return S_OK;
    }
    STDMETHODIMP DragOver(DWORD, POINTL, DWORD* effect) override {
        *effect = DROPEFFECT_COPY;
        return S_OK;
    }
    STDMETHODIMP DragLeave() override { return S_OK; }
    STDMETHODIMP Drop(IDataObject* obj, DWORD, POINTL, DWORD* effect) override {
        *effect = DROPEFFECT_COPY;
        FORMATETC fmt = { CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
        STGMEDIUM medium = {};
        if (SUCCEEDED(obj->GetData(&fmt, &medium))) {
            HDROP hDrop = (HDROP)GlobalLock(medium.hGlobal);
            if (hDrop) {
                UINT n = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
                for (UINT i = 0; i < n && i < 8; ++i) {
                    wchar_t path[MAX_PATH];
                    DragQueryFileW(hDrop, i, path, MAX_PATH);
                    SendMessageW(g_dropList, LB_ADDSTRING, 0, (LPARAM)path);
                }
                GlobalUnlock(medium.hGlobal);
            }
            ReleaseStgMedium(&medium);       // StgMedium 必须释放
        }
        return S_OK;
    }
};

static DropTarget* g_drop = nullptr;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        g_src = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"这段文字可以复制到剪贴板",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 10, 10, 360, 26, hwnd,
            (HMENU)(INT_PTR)IDC_SRC, cs->hInstance, nullptr);
        CreateWindowExW(0, L"BUTTON", L"复制",
            WS_CHILD | WS_VISIBLE, 380, 10, 70, 26, hwnd,
            (HMENU)(INT_PTR)IDC_COPY, cs->hInstance, nullptr);
        g_dst = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"粘贴到这里",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 10, 46, 360, 26, hwnd,
            (HMENU)(INT_PTR)IDC_DST, cs->hInstance, nullptr);
        CreateWindowExW(0, L"BUTTON", L"粘贴",
            WS_CHILD | WS_VISIBLE, 380, 46, 70, 26, hwnd,
            (HMENU)(INT_PTR)IDC_PASTE, cs->hInstance, nullptr);
        g_dropList = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", nullptr,
            WS_CHILD | WS_VISIBLE | LBS_NOTIFY, 10, 90, 440, 180, hwnd,
            (HMENU)(INT_PTR)IDC_DROPLIST, cs->hInstance, nullptr);

        DragAcceptFiles(hwnd, TRUE);          // 姿势一：WM_DROPFILES（窗口级）
        g_drop = new DropTarget();            // 姿势二：OLE 拖放（列表框级）
        RegisterDragDrop(g_dropList, g_drop);
        return 0;
    }
    case WM_DROPFILES: {
        HDROP hDrop = (HDROP)wParam;
        UINT n = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
        for (UINT i = 0; i < n && i < 8; ++i) {
            wchar_t path[MAX_PATH];
            DragQueryFileW(hDrop, i, path, MAX_PATH);
            SendMessageW(g_dropList, LB_ADDSTRING, 0, (LPARAM)path);
        }
        DragFinish(hDrop);
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_COPY: {
            wchar_t text[256];
            GetWindowTextW(g_src, text, 256);
            CopyToClipboard(hwnd, text);
            return 0;
        }
        case IDC_PASTE: {
            wchar_t text[256] = L"";
            if (PasteFromClipboard(hwnd, text, 256)) {
                SetWindowTextW(g_dst, text);
            }
            return 0;
        }
        }
        break;
    case WM_DESTROY:
        RevokeDragDrop(g_dropList);
        if (g_drop) g_drop->Release();
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    if (FAILED(OleInitialize(nullptr))) return 1;   // OLE 拖放专用初始化

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ClipDndClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ClipDndClass", L"剪贴板与拖放（往列表框拖文件试试）",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 480, 320,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    OleUninitialize();
    return (int)msg.wParam;
}
```

- [ ] **Step 4: 验证三示例**

  ```bash
  cd /g/code/guide/win32 && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 30_windows_service/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 31_shell_tray/main.cpp && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 32_clipboard_dnd/main.cpp && ./build/30_windows_service.exe console && ./build/30_windows_service.exe list | head -4
  ```

  预期：31/32 编译过；30 的 console 模式输出 3 拍心跳后退出码 0；list 模式列出服务表（标准用户可跑）。

- [ ] **Step 5: 填充 27 章占位（约 420 行）**

  1. 开篇三件（前置 14/17/21；成果：可安装的最小服务）
  2. 27.1 服务是什么：无 UI 长驻进程；**会话 0 隔离**（为什么服务弹窗看不见——安全设计）
  3. 27.2 SCM 与生命周期图：安装→启动→运行→停止→卸载；`SERVICE_TABLE_ENTRY` + `StartServiceCtrlDispatcherW`（SCM 借它找到 `ServiceMain`——与 WndProc 的"系统回调你"同构！）
  4. 27.3 最小服务五要素（30 示例 ServiceMain 逐段解剖）：`RegisterServiceCtrlHandlerExW` / 状态上报时机 / 停止事件 / 工作循环 / `SERVICE_STOPPED` 收尾
  5. 27.4 安装与治理：`CreateServiceW` 关键参数表（启动类型/运行账户）；`sc.exe` 命令对照表；为什么安装需要管理员（17 章）
  6. 27.5 双模式开发法：`console` 动词就地跑服务逻辑——先验证业务再上 SCM（工程惯例）
  7. 27.6 事件日志：三大日志（Application/System/Security）；`RegisterEventSourceW`/`ReportEventW`；事件查看器参观路线；未注册源的显示问题与 message DLL 一句话；`wevtutil` 一条
  8. 27.7 调试与观测：附加到进程；日志代替 UI 的思路
  9. 易错清单：`ServiceMain` 里干重活超时被 SCM 判死（`START_PENDING`+`waitHint` 分段报）/ 忘报 `SERVICE_STOPPED` 残留"正在停止" / 直接双击服务 exe（会走到提示分支）/ 事件源未注册的"找不到描述"
  10. 小结 + 练习（心跳间隔改成读服务参数 `lpServiceArgs`）

- [ ] **Step 6: 填充 28 章占位（约 380 行）**

  1. 开篇三件（前置 04/07；成果：完整托盘程序）
  2. 28.1 托盘：`NOTIFYICONDATAW` 关键字段表；`NIM_ADD/MODIFY/DELETE` 三动作；回调消息设计（`uCallbackMessage`；**事件类型在 lParam 不在 wParam**——易错高亮）
  3. 28.2 右键菜单：`TrackPopupMenu` + 前置 `SetForegroundWindow`（菜单不消失的老坑与官方解法）
  4. 28.3 气泡通知：`NIF_INFO`；与 WinRT Toast 的边界（指 26.7）
  5. 28.4 Explorer 重启恢复：`TaskbarCreated` 广播 + `RegisterWindowMessageW`（31 示例解剖）
  6. 28.5 最小化进托盘完整交互流（31 示例：隐藏/显示/退出三路径）
  7. 28.6 Shell 接驳总表：文件关联/右键菜单扩展/跳转列表/任务栏进度（`ITaskbarList3` 一段——COM 又来了）
  8. 易错清单：退出忘 `NIM_DELETE` 留幽灵图标 / 判事件用了 wParam / 托盘菜单卡死（忘 SetForegroundWindow）
  9. 小结 + 练习（双击图标循环切换显示/隐藏）

- [ ] **Step 7: 填充 29 章占位（约 400 行）**

  1. 开篇三件（前置 22~24；成果：剪贴板 + 双姿势拖放）
  2. 29.1 剪贴板模型：系统全局共享 + 格式协商（多格式共存思想）；四步协议 ASCII 图（开→清→设→关）；延迟渲染一句话
  3. 29.2 写 `CF_UNICODETEXT` 全链路（32 示例 Copy 段解剖）：`GlobalAlloc(GMEM_MOVEABLE)` 为什么；**所有权转移——`SetClipboardData` 之后绝不能 `GlobalFree`**（头号易错）
  4. 29.3 读：`GetClipboardData` + `GlobalLock` 只读不解锁不释放；先 `IsClipboardFormatAvailable` 探格式
  5. 29.4 拖放三档：`DragAcceptFiles`/`WM_DROPFILES`（最简，文件专用）→ OLE `IDropTarget`（标准，任意数据）→ 现成控件一句话；选型表
  6. 29.5 `WM_DROPFILES` 实战（32 示例段：`0xFFFFFFFF` 问数量、逐个 `DragQueryFileW`、`DragFinish`）
  7. 29.6 手写 `IDropTarget`（32 示例 DropTarget 解剖——**第 24 章实现知识的第二次实战**）：四方法职责表（Enter 查格式/Over 报效果/Leave/Drop 取数据）；`FORMATETC`/`STGMEDIUM`/`ReleaseStgMedium`；`RegisterDragDrop`/`RevokeDragDrop`；**`OleInitialize` 与 `CoInitialize` 的区别**（OLE 拖放强制的）
  8. 29.7 拖动方一段：`DoDragDrop` + `IDataObject`（剪贴板与拖放共用数据对象模型——同一个抽象的两条管道）
  9. 易错清单：`SetClipboardData` 后 `GlobalFree`（双重释放崩溃）/ 忘 `EmptyClipboard` 抢不到所有权 / `RegisterDragDrop` 返回错误因为没 `OleInitialize` / `ReleaseStgMedium` 忘调泄漏
  10. 小结 + 练习（把拖放列表改成去重添加；剪贴板多格式同时给 text + 自定义格式概念题）

- [ ] **Step 8: 自检 + 全量验证 + Commit**

  ```bash
  cd /g/code/guide/win32/docs && wc -l 27-*.md 28-*.md 29-*.md
  cd .. && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  预期：三章 380~450 行；32 工程全绿。

  ```bash
  git add -A && git commit -m "docs(win32): 平台专题三章——服务与事件日志/Shell 集成/剪贴板与拖放 + 30/31/32 示例

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

### Task 15: 批 14 收束——30 章 + README/目录页终稿 + 全量终验

**Files:**
- Modify: `win32/docs/30-现代Win32与学习路线.md`（重写，原 12 章内容）
- Modify: `win32/README.md`（终稿：32 示例表 + 工具链说明更新）
- Modify: `win32/Win32 API开发指南.md`（示例表补全为 32 行终表）
- Modify: 记忆文件 `G:\xulun\.claude\projects\G--code-guide\memory\win32-tutorial-build.md`（重写）

**Interfaces:**
- Consumes: 全部前序任务的成果。
- Produces: 教程终态；记忆更新供后续会话使用。

- [ ] **Step 1: 重写 30 章（约 400 行）**

  原 12 章结构升级：
  1. 开篇三件
  2. 30.1 Win10/11 新增能力清单（保留原表并补行：C++/WinRT 消费、`CreatePseudoConsole`、`SetProcessMitigationPolicy`；每行标"第 N 章已讲"）
  3. 30.2 技术栈关系图谱（保留 ASCII 图更新：把 D2D/WinRT 层画进去；三个误解澄清保留）
  4. 30.3 全书避坑总表（按五篇分组合并各章易错清单——**只收最要命的**，每篇 4~6 条）
  5. 30.4 学习地图更新：Direct3D 12（为什么本教程不含：600+ 行三角形 + HLSL；给出官方学习路径）、Windows App SDK/WinUI 3、深入内核（Windows Internals）、安全方向、MSIX
  6. 30.5 结语（更新为 30 章视角：界面层会被封装，系统层三十年只有加法；三个"学成的标志"保留并补第四条：看到 IUnknown 不再害怕、能跟着 24 章手写出自己的组件）

- [ ] **Step 2: README.md 终稿**

  1. 目录结构段更新（新增章节文件数、build.ps1 委托机制一句话）
  2. "章节与示例对照"表替换为 **32 行终表**（01~32 每行：示例名/对应章/演示内容/形态 CONSOLE|GUI|DLL+EXE|DLL×2+EXE|服务）
  3. 工具链段补：默认链接库全集说明（Task 1 的 15 个库）；cppwinrt 头与 `WindowsApp.lib`（仅 29）
  4. "编译与验证"段补：多目标工程说明（23/24/27/29 自带 build.ps1 被根脚本委托，运行验证内含其中）
  5. "说明"段更新：控制台示例可直接运行观察；服务示例双模式；COM 全链路 HKCU 免管理员

- [ ] **Step 3: 目录页示例表补全**

  `Win32 API开发指南.md` 的"示例代码"段替换为与 README 一致的 32 行表（或直接保留指向 README 的链接——采用前者，读者在目录页即可浏览）。

- [ ] **Step 4: 全量终验**

  ```bash
  cd /g/code/guide/win32
  powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All       # 预期：32 工程全绿
  grep -rn "即将在对应批次中完成" docs/ && echo "存在未填充占位章！" || echo "占位已清零"
  ls docs/*.md | wc -l                                                      # 预期 30
  # 抽查控制台五件套
  ./build/16_error_handling.exe > /dev/null && ./build/20_encoding_convert.exe > /dev/null && ./build/25_registry_tool.exe > /dev/null && ./build/30_windows_service.exe console > /dev/null && ./build/29_winrt_modern.exe > /dev/null && echo RUN_OK
  # COM 环境复查
  reg query "HKCU\Software\Classes\CLSID\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}" 2>&1 | head -1   # 预期找不到（已注销）
  # 交叉引用抽查
  grep -rn "第 8 章\|第 11 章\|第 12 章" docs/ | grep -v "第 18\|第 19\|第 20\|第 21\|第 24\|第 25\|第 26\|第 27\|第 28\|第 29\|第 30" | head   # 预期无残留旧引用（人工核对输出）
  ```

- [ ] **Step 5: 记忆更新**

  重写 `G:\xulun\.claude\projects\G--code-guide\memory\win32-tutorial-build.md`：30 章/32 示例结构、build.ps1 委托机制（目录含 build.ps1 即委托，子脚本纯 ASCII）、默认库全集、BOM 铁律（根脚本必须带、子脚本不需要）、cppwinrt 构建要点（29 示例）、COM 全链路验证模式（HKCU 注册→创建→注销）、服务双模式验证法、本轮实测新增坑（记录执行中实际踩到的）。同时更新 MEMORY.md 索引行描述。

- [ ] **Step 6: 终 Commit**

  ```bash
  cd /g/code/guide && git add win32 && git status --short && git commit -m "docs(win32): 收束——30 章现代 Win32 与学习路线重写，README/目录页终稿，32 示例全绿

  Co-Authored-By: Claude Code <noreply@anthropic.com>"
  ```

---

## 计划自检记录（writing-plans Self-Review）

1. **Spec 覆盖**：spec §2 的 30 章 ↔ Task 2 建骨架 + Task 3~15 逐章填充（01/02→T3、03→T3、04/05→T4、06/07/08→T5、09/10/11→T6、12/13/14→T7、15/16→T8、17/18→T9、19/20→T10、21→T11、22/23/24→T12、25/26→T13、27/28/29→T14、30→T15）✓；spec §4 的 17 个新示例 ↔ 16→T3、17/18/19→T5、20→T7、21/22→T9、23/24→T10、25→T11、26/27→T12、28/29→T13、30/31/32→T14 ✓；spec §5 构建改造 ↔ T1 ✓；spec §6 验证标准分散在各 Task 的验证步骤 + T15 终验 ✓；spec §7 的 14 批 ↔ T1(批1)~T15(批14) 一一对应 ✓。
2. **占位扫描**：无 TBD/TODO；29 的协程段给了明确降级预案代码而非"待定"✓。
3. **类型/名称一致性**：`IID_ICalc`/`CLSID_Calc` 在 Global Constraints 与 T12 calc.h 逐字一致 ✓；委托机制描述在 T1（根脚本）与 T10/T12/T13（子脚本）互为对端 ✓；示例编号在 T2 目录页、T15 终表、各 Task 文件路径三处一致 ✓；章号引用（如"26.7""22.7"）在各章 outline 间交叉对应 ✓。




