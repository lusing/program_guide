# MFC 开发指南扩充实施计划（13 章 → 25 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `G:\code\guide\mfc` 从 13 章 / 1894 行 / 12 示例扩充到 25 章 / 约 4100 行 / 23 示例目录，对齐同仓库 WPF 教程的容量与教学骨架，全部示例实际编译、链接、冒烟通过。

**Architecture:** 先做一次骨架重排（`git mv` 重命名 12 个示例目录与 6 个 docs 文件，使「章号 = 示例号」），再按六篇顺序逐批补写章节正文与配套示例。每批以「示例先跑通 → 正文后写 → 构建 + 冒烟 + 交叉检查」收口并提交。第 23、24 章不建新示例目录，分别复用 `25_notepad_plus` 源码（`-Static` 双构建对比）与重构 `13_shell_integration`。

**Tech Stack:** MSVC 14.51.36231（VS 18 Community）、Windows SDK 10.0.26100.0、MFC 14.51（动态 `_AFXDLL` / 静态 `mfc140u.lib`）、C++20、PowerShell 5.1 脚本、Git Bash。

**Spec:** `docs/superpowers/specs/2026-09-21-mfc-guide-expansion-design.md`

## Global Constraints

以下约束对每个任务都生效，不再逐条重复。

- **章号 = 示例号**：第 NN 章的「对应示例」必须是 `examples/NN_*`（第 23、24 章例外，复用 `25_notepad_plus` 与 `13_shell_integration`）。
- **每章固定骨架**：一级标题 `# NN · 标题`；紧跟三行开篇（`> 对应示例：` / `> **本章你将学会**：` / `> **前置知识**：`）；正文小节；末尾固定三节 `## 常见坑`（≥3 条）、`## 实战建议`（3~5 条）、`## 自测`（3~5 题，题目加粗、答案紧跟 `——`）；最后一行 `---` + `上一章：[NN 标题](NN-xxx.md) ｜ 下一章：[MM 标题](MM-xxx.md)`（首章上一章写「无」，末章下一章写「无」）。
- **篇幅**：每章 ≥160 行；全书 25 章合计 4000~4200 行。
- **示例构建方式**：所有示例只用 `build.ps1` 构建，不生成 vcxproj。编译参数 `cl /std:c++20 /EHsc /W3 /DUNICODE /D_UNICODE /D_AFXDLL /MD /utf-8 /D_WIN32_WINNT=0x0A00`，资源 `rc /c65001`，链接 `/link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup`。
- **文件编码**：源码与 `.rc` 一律 UTF-8；含中文的 `.rc` 必须 `#pragma code_page(65001)`；`build.ps1` 与 `smoke.ps1` 必须带 UTF-8 BOM（`EF BB BF`），否则 PowerShell 5.1 按 GBK 解析中文会语法错误。
- **MFC API 陷阱（已在 spike 中实测，写正文时按此写）**：
  - `CTaskDialog` 在 `<afxtaskdialog.h>`，**无默认构造函数**，必须三参构造 `CTaskDialog(内容, 主指令, 标题)`。
  - `COleDropTarget::OnDrop` 返回 **`BOOL`**；`OnDragEnter`/`OnDragOver` 返回 `DROPEFFECT`。写错报 C2555。
  - 拖放前必须 `AfxOleInit()`，否则 `COleDropTarget::Register` 失败。
  - `CWinApp` 没有 `m_hAccelTable` 成员（自己存 `HACCEL`）；`afx_msg` 处理函数**不是虚函数**（写 `override` 报 C3668）；`CView::OnDraw` 是纯虚必须实现。
  - `CFileDialog`/`CColorDialog` 在 `<afxdlgs.h>`；`CToolBarCtrl`/`CTreeCtrl`/`CDateTimeCtrl` 在 `<afxcmn.h>`；`CRecentFileList` 在 `<afxadv.h>`；`CPrintDialog` 在 `<afxdlgs.h>`；`CPreviewView` 在 `<afxext.h>`。
  - `CListCtrl::SortItems` 的比较回调收到的是行 `lParam`（`ItemData` 指针）不是行号。
- **静态/动态体积基线（spike 实测，第 23 章直接引用）**：同一份源码动态链接 26,112 B，静态链接 2,500,096 B。
- **收口三步（每个任务末尾必须全跑）**：
  ```bash
  cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -30
  pwsh -NoProfile -File smoke.ps1 2>&1 | tail -10
  wc -l docs/*.md | tail -1
  ```
- **提交信息格式**：`docs(mfc): <批次内容>`，正文说明本批新增/扩写的章节与示例，结尾加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

---

## Task 1: 骨架重排（重命名 + smoke.ps1 + build.ps1 改造）

**Files:**
- Rename: `mfc/examples/02_message_map/` → `03_message_map/`、`03_resources/` → `04_resources/`、`04_frame_layout/` → `05_frame_layout/`、`05_dialog/` → `06_dialog/`、`06_controls/` → `07_controls/`、`07_common_dialogs/` → `10_common_dialogs/`、`08_toolbar_statusbar/` → `11_toolbar_statusbar/`、`09_docview/` → `15_docview/`、`10_gdi/` → `18_gdi/`、`11_threads/` → `20_threads/`、`12_notepad_plus/` → `25_notepad_plus/`（`01_hello_mfc` 不变）
- Rename: `mfc/docs/08-common-dialogs.md` → `10-common-dialogs.md`、`09-toolbars.md` → `11-toolbars.md`、`10-docview.md` → `15-docview.md`、`11-gdi.md` → `18-gdi.md`、`12-threads.md` → `20-threads.md`、`13-notepad-plus.md` → `25-notepad-plus.md`
- Modify: `mfc/build.ps1`（库白名单 + `-Static` 开关）
- Modify: `mfc/docs/01-*.md` … `07-*.md`（正文内引用旧示例目录名的行）
- Create: `mfc/smoke.ps1`

**Interfaces:**
- Produces: `build.ps1 -Static` 开关与 `$extraLibsByExample` 白名单表（后续所有任务依赖）；`smoke.ps1`（`-Name` / `-Seconds` 参数）；示例目录命名约定 `NN_<slug>`。

- [ ] **Step 1: 用 git mv 重命名 11 个示例目录**

```bash
cd /g/code/guide/mfc/examples
git mv 02_message_map 03_message_map
git mv 03_resources 04_resources
git mv 04_frame_layout 05_frame_layout
git mv 05_dialog 06_dialog
git mv 06_controls 07_controls
git mv 07_common_dialogs 10_common_dialogs
git mv 08_toolbar_statusbar 11_toolbar_statusbar
git mv 09_docview 15_docview
git mv 10_gdi 18_gdi
git mv 11_threads 20_threads
git mv 12_notepad_plus 25_notepad_plus
ls
```

Expected: 目录列表为 `01_hello_mfc 03_message_map 04_resources 05_frame_layout 06_dialog 07_controls 10_common_dialogs 11_toolbar_statusbar 15_docview 18_gdi 20_threads 25_notepad_plus`

- [ ] **Step 2: 用 git mv 重命名 6 个 docs 文件**

```bash
cd /g/code/guide/mfc/docs
git mv 08-common-dialogs.md 10-common-dialogs.md
git mv 09-toolbars.md 11-toolbars.md
git mv 10-docview.md 15-docview.md
git mv 11-gdi.md 18-gdi.md
git mv 12-threads.md 20-threads.md
git mv 13-notepad-plus.md 25-notepad-plus.md
ls
```

Expected: `01-overview.md 02-app-lifecycle.md 03-message-map.md 04-resources.md 05-frames.md 06-dialogs.md 07-controls.md 10-common-dialogs.md 11-toolbars.md 15-docview.md 18-gdi.md 20-threads.md 25-notepad-plus.md`

- [ ] **Step 3: 修正重命名章节的一级标题章号**

对 `10-common-dialogs.md`、`11-toolbars.md`、`15-docview.md`、`18-gdi.md`、`20-threads.md`、`25-notepad-plus.md` 六个文件，把一级标题里的旧章号改成新章号。例如 `15-docview.md` 首行 `# 10 · Doc/View 架构` 改为 `# 15 · Doc/View 架构`；`25-notepad-plus.md` 首行 `# 13 · 实战项目：记事本+` 改为 `# 25 · 实战项目：记事本+`。

```bash
cd /g/code/guide/mfc/docs && head -1 10-common-dialogs.md 11-toolbars.md 15-docview.md 18-gdi.md 20-threads.md 25-notepad-plus.md
```

Expected: 六行依次为 `# 10 · …`、`# 11 · …`、`# 15 · …`、`# 18 · …`、`# 20 · …`、`# 25 · …`

- [ ] **Step 4: 修正全部 docs 里的示例目录引用与上下章链接**

先找出所有引用点：

```bash
cd /g/code/guide/mfc && grep -rn "examples/0[2-9]_\|examples/1[0-2]_\|docs/0[89]-\|docs/1[0-3]-\|(0[89]-\|(1[0-3]-" docs/ README.md
```

逐条替换为新名（`examples/02_message_map` → `examples/03_message_map`，`docs/09-toolbars.md` → `docs/11-toolbars.md`，链接文字 `[09 工具栏与状态栏](09-toolbars.md)` → `[11 菜单、工具栏与状态栏](11-toolbars.md)` 等）。同时把每章末行的「上一章/下一章」链接改成新文件名与新标题。

重跑同一 grep，Expected: 无输出。

- [ ] **Step 5: 给 build.ps1 加库白名单与 -Static 开关**

修改 `mfc/build.ps1`。`param()` 块改为：

```powershell
param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$Static
)
```

在 `$buildDir = Join-Path $projectRoot "build"` 之后插入：

```powershell
# 逐示例额外链接库白名单（未列出的示例只链接 MFC 默认库）
$extraLibsByExample = @{
    '12_clipboard_dnd'  = @('ole32.lib', 'oleaut32.lib')
    '14_dpi_darkmode'   = @('dwmapi.lib')
    '22_modern_drawing' = @('gdiplus.lib', 'd2d1.lib', 'dwrite.lib')
}
```

把 `Build-Example` 函数体替换为：

```powershell
function Build-Example {
    param(
        [Parameter(Mandatory = $true)][string]$ExamplePath
    )

    $name = Split-Path -Leaf $ExamplePath
    $objDir = Join-Path $buildDir "obj\$name"
    New-Item -ItemType Directory -Force -Path $objDir | Out-Null
    $suffix = if ($Static) { '_static' } else { '' }
    $exePath = Join-Path $buildDir ($name + $suffix + '.exe')

    $cpps = @(Get-ChildItem -LiteralPath $ExamplePath -Filter "*.cpp" | Sort-Object Name)
    $rcs = @(Get-ChildItem -LiteralPath $ExamplePath -Filter "*.rc")

    if ($cpps.Count -eq 0) {
        Write-Host "[Skip] $name (没有 .cpp 文件)" -ForegroundColor Yellow
        return
    }

    # 静态模式：去掉 /D_AFXDLL，运行时改 /MT，链接器自动取 mfc140u.lib
    $compileFlags = if ($Static) {
        '/std:c++20 /EHsc /W3 /DUNICODE /D_UNICODE /MT /utf-8 /D_WIN32_WINNT=0x0A00'
    } else {
        '/std:c++20 /EHsc /W3 /DUNICODE /D_UNICODE /D_AFXDLL /MD /utf-8 /D_WIN32_WINNT=0x0A00'
    }

    $extraLibs = $extraLibsByExample[$name]
    if (-not $extraLibs) { $extraLibs = @() }

    Write-Host ("[Build] {0}{1}" -f $name, $(if ($Static) { ' (静态)' } else { '' })) -ForegroundColor Cyan

    $steps = @('call "{0}" >nul' -f $vcvars)

    foreach ($cpp in $cpps) {
        $objPath = Join-Path $objDir ($cpp.BaseName + $suffix + ".obj")
        $steps += ('cl /nologo {0} /c "{1}" /Fo"{2}"' -f $compileFlags, $cpp.FullName, $objPath)
    }

    foreach ($rc in $rcs) {
        $resPath = Join-Path $objDir ($rc.BaseName + $suffix + ".res")
        $steps += ('rc /nologo /c65001 {0} /Fo"{1}" "{2}"' -f ($rcIncludeFlags -join " "), $resPath, $rc.FullName)
    }

    $objList = ($cpps | ForEach-Object { Join-Path $objDir ($_.BaseName + $suffix + ".obj") }) -join " "
    $resList = ""
    if ($rcs.Count -gt 0) {
        $resList = " " + (($rcs | ForEach-Object { Join-Path $objDir ($_.BaseName + $suffix + ".res") }) -join " ")
    }
    $libList = if ($extraLibs.Count -gt 0) { " " + ($extraLibs -join " ") } else { "" }
    # Unicode MFC 的入口是 wWinMain（动态由 mfc140u.dll 提供，静态由 mfc140u.lib 提供），必须显式指定
    $steps += ('cl /nologo {0}{1} /Fe"{2}" /link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup{3}' -f $objList, $resList, $exePath, $libList)

    $cmd = $steps -join " && "
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "构建失败: $name"
    }
    Write-Host "[OK] $name -> $exePath" -ForegroundColor Green
}
```

把 `-All` 分支的循环体改为 `Build-Example -ExamplePath $d.FullName`（不变，`$Static` 是脚本级变量，函数内可直接读）。在 `-File` 分支末尾的 `Build-Example -ExamplePath $target` 之后保持 `exit 0`。

在最后的用法输出里补一行：

```powershell
Write-Host "  .\build.ps1 -File <示例目录> -Static   静态链接 MFC 构建（第 23 章用）"
```

- [ ] **Step 6: 确认 build.ps1 的 UTF-8 BOM 仍在**

```bash
cd /g/code/guide/mfc && head -c 3 build.ps1 | xxd
```

Expected: `00000000: efbb bf` 。若丢失（显示为 `param` 的开头字节），补回：

```bash
cd /g/code/guide/mfc && printf '\xef\xbb\xbf' | cat - build.ps1 > build.tmp && mv build.tmp build.ps1 && head -c 3 build.ps1 | xxd
```

- [ ] **Step 7: 新建 smoke.ps1**

创建 `mfc/smoke.ps1`，内容为：

```powershell
param(
    [string]$Name,
    [int]$Seconds = 3
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $buildDir)) {
    throw "找不到 build 目录，请先运行 .\build.ps1 -All"
}

if ($Name) {
    $exes = @(Get-ChildItem -LiteralPath $buildDir -Filter ($Name + "*.exe") | Sort-Object Name)
} else {
    $exes = @(Get-ChildItem -LiteralPath $buildDir -Filter "*.exe" | Sort-Object Name)
}

if ($exes.Count -eq 0) {
    throw "没有找到可冒烟的 exe。"
}

$alive = 0
$failed = 0
foreach ($exe in $exes) {
    try {
        $p = Start-Process -FilePath $exe.FullName -PassThru -ErrorAction Stop
    } catch {
        Write-Host ("[FAIL] {0} 启动失败: {1}" -f $exe.Name, $_.Exception.Message) -ForegroundColor Red
        $failed++
        continue
    }
    Start-Sleep -Seconds $Seconds
    if ($p.HasExited) {
        Write-Host ("[CRASH] {0} 提前退出（退出码 {1}）" -f $exe.Name, $p.ExitCode) -ForegroundColor Red
        $failed++
    } else {
        Write-Host ("[ALIVE] {0}" -f $exe.Name) -ForegroundColor Green
        $alive++
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ("[Done] 存活 {0} / 失败 {1}" -f $alive, $failed) -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
```

- [ ] **Step 8: 给 smoke.ps1 补 UTF-8 BOM**

```bash
cd /g/code/guide/mfc && printf '\xef\xbb\xbf' | cat - smoke.ps1 > smoke.tmp && mv smoke.tmp smoke.ps1 && head -c 3 smoke.ps1 | xxd
```

Expected: `00000000: efbb bf`

- [ ] **Step 9: 全量构建 12 个旧示例**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -30
```

Expected: 12 行 `[OK] <name> -> …`，末行 `[Done] examples 目录全部构建完成。`，无 `构建失败`。

- [ ] **Step 10: 冒烟全部 exe**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File smoke.ps1 2>&1 | tail -15
```

Expected: 12 行 `[ALIVE]`，末行 `[Done] 存活 12 / 失败 0`。

- [ ] **Step 11: 验证 -Static 开关可用**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 01_hello_mfc -Static 2>&1 | tail -5 && ls -la build/01_hello_mfc.exe build/01_hello_mfc_static.exe
```

Expected: `[OK] 01_hello_mfc -> …01_hello_mfc_static.exe`；动态产物约 26 KB，静态产物约 2.5 MB（量级即可，不必逐字节一致）。

- [ ] **Step 12: 清理静态产物并提交**

```bash
cd /g/code/guide/mfc && rm -f build/*_static.exe && rm -rf build/obj/*_static* 
cd /g/code/guide && git add -A mfc && git status --short | head -30
```

确认 `git status` 里全是 `R`（重命名）与少量 `M`，没有意外的新增/删除。然后提交：

```bash
cd /g/code/guide && git commit -q -F - <<'EOF'
docs(mfc): 骨架重排，章号对齐示例号 + 新增 smoke.ps1

12 个示例目录与 6 个 docs 文件按「章号 = 示例号」重命名（git mv 保留
历史），同步修正正文内引用与上下章链接。build.ps1 增加逐示例额外链接
库白名单与 -Static 静态链接开关（第 23 章用）。新增 smoke.ps1 做启动
冒烟，作为编译之外的第二道防线。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git log --oneline -1
```

---

## Task 2: 第 01–02 章 + 新示例 `02_app_lifecycle`

**Files:**
- Modify: `mfc/docs/01-overview.md`（扩写 127 → ~170 行）
- Modify: `mfc/docs/02-app-lifecycle.md`（重写 107 → ~165 行，改为指向 `examples/02_app_lifecycle`）
- Create: `mfc/examples/02_app_lifecycle/main.cpp`、`resource.h`

**Interfaces:**
- Produces: 示例 `02_app_lifecycle` 的构建产物 `build/02_app_lifecycle.exe`；后续章节引用「应用骨架四阶段」术语。

- [ ] **Step 1: 写示例 `02_app_lifecycle`**

`mfc/examples/02_app_lifecycle/resource.h`：

```cpp
#pragma once
#define IDR_MAINFRAME 128
#define IDC_LOG       1001
```

`mfc/examples/02_app_lifecycle/main.cpp`：一个框架窗口，客户区放一个只读多行 `CEdit`（`IDC_LOG`），把 `CWinApp` 各回调与消息循环事件按时间顺序追加进去。关键结构：

```cpp
#include "resource.h"
#include <afxwin.h>

class CLifecycleApp;

class CMainFrame : public CFrameWnd {
public:
    CMainFrame();
    void Log(LPCTSTR text);           // 追加一行到 IDC_LOG 并滚到底
    afx_msg void OnClose();           // 记 WM_CLOSE，再走默认处理
    afx_msg void OnDestroy();         // 记 WM_DESTROY
    DECLARE_MESSAGE_MAP()
private:
    CEdit m_log;
};

class CLifecycleApp : public CWinApp {
public:
    CLifecycleApp();
    BOOL InitApplication() override;  // 记时序 1
    BOOL InitInstance() override;     // 记时序 2，创建主窗口
    int  ExitInstance() override;     // 记时序 4
    BOOL OnIdle(LONG lCount) override;// 记空闲处理（lCount == 0 时记一次即可）
    ~CLifecycleApp();
};
```

要点：`InitInstance` 里创建 `CMainFrame`、`ShowWindow`、`UpdateWindow`；`Log` 用 `m_log.SetSel(-1, -1)` + `ReplaceSel` 追加；`OnIdle` 只在 `lCount == 0` 时记一行，避免刷屏；`ExitInstance` 用 `AfxMessageBox` 弹一次时序总结（退出后编辑框已不可见，所以退出阶段的事件要弹框呈现）。

- [ ] **Step 2: 构建并冒烟示例**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 02_app_lifecycle 2>&1 | tail -5
pwsh -NoProfile -File smoke.ps1 -Name 02_app_lifecycle 2>&1 | tail -5
```

Expected: `[OK] 02_app_lifecycle -> …` 且 `[ALIVE] 02_app_lifecycle.exe`，末行 `[Done] 存活 1 / 失败 0`。

- [ ] **Step 3: 扩写 `docs/01-overview.md`**

在现有内容基础上补：
- 开篇三行（`> 对应示例：examples/01_hello_mfc` / `本章你将学会` / `前置知识：C++ 基础与 Win32 窗口概念，可对照本仓库《Win32 API 桌面编程指南》第 04 章`）。
- 新增小节「**1.5 MFC 在 Windows UI 谱系中的位置**」：加一张对照表，列为 Win32 / MFC / WinForms / WPF / WinUI 3，行含语言、渲染、界面描述、数据绑定、自定义外观、运行时依赖、诞生年。数据取自 `wpf/docs/01-overview.md` 的同名表，保持两书口径一致。
- 新增小节「**7. 常见坑**」3 条：① 忘记 `/ENTRY:wWinMainCRTStartup` 报「无法解析的外部符号 WinMain」；② rc.exe 不在 MSVC 目录而在 SDK `bin\<ver>\x64`；③ `/D_AFXDLL` 与 `/MD` 必须配套，混用 `/MT` 报运行时库冲突。
- 把现有「7. 常见坑」编号顺延，末尾补「8. 实战建议」4 条与「9. 自测」4 题（题目加粗、答案 `——` 开头）。

- [ ] **Step 4: 重写 `docs/02-app-lifecycle.md`**

固定小节：

1. `## 1. 一个 MFC 程序的四个阶段` —— ASCII 图：`构造 theApp → InitApplication → InitInstance → Run（消息循环）→ ExitInstance → 析构`。说明 `theApp` 是全局对象，在 `main` 之前构造。
2. `## 2. InitInstance：唯一必须重写的函数` —— 逐行解剖 `02_app_lifecycle` 的 `InitInstance`；说明返回 `FALSE` 的后果（`AfxWinMain` 直接跳到 `ExitInstance`，不进入消息循环）。
3. `## 3. 消息循环到底在做什么` —— `CWinThread::Run` 的骨架：`PeekMessage` 取队列 → `PumpMessage` 分发 → 无消息时调 `OnIdle`。给出等价伪代码。指出这就是 Win32 教程里 `GetMessage/TranslateMessage/DispatchMessage` 循环的 MFC 版本，MFC 额外做了加速键翻译与空闲处理。
4. `## 4. OnIdle：空闲时机的正确用法` —— 参数 `lCount` 的含义（连续空转次数）；返回值 `TRUE` 表示"还有事要做，别睡"；典型用途（延迟清理临时对象、更新状态栏）；反例（在 `OnIdle` 里做耗时计算会让界面卡住）。
5. `## 5. 关闭流程：从 WM_CLOSE 到进程退出` —— 顺序图：`WM_CLOSE` → `CFrameWnd::OnClose` → `DestroyWindow` → `WM_DESTROY` → `PostQuitMessage` → `Run` 退出 → `ExitInstance` → 全局对象析构。指出 `PostQuitMessage` 是消息循环的终止信号。
6. `## 6. 常见坑` —— ① `InitInstance` 里 `new` 了窗口却没赋给 `m_pMainWnd`，主窗口关闭后进程不退出；② 在 `ExitInstance` 里访问已销毁的窗口对象导致崩溃；③ `OnIdle` 里不判断 `lCount` 导致每轮都做重活；④ 重写 `InitInstance` 忘记调 `CWinApp::InitInstance()`。
7. `## 7. 实战建议` —— 把初始化拆成 `InitInstance` 调用的私有函数；耗时的启动工作放 `OnIdle` 首次触发；用 `m_nCmdShow` 而不是硬编码 `SW_SHOW`。
8. `## 8. 自测` —— 4 题，覆盖四阶段顺序、`InitInstance` 返回 FALSE 的后果、`OnIdle` 的 `lCount`、`PostQuitMessage` 的作用。

- [ ] **Step 5: 验证章节骨架与行数**

```bash
cd /g/code/guide/mfc/docs && for f in 01-overview.md 02-app-lifecycle.md; do echo "--- $f"; head -1 $f; grep -c "^## " $f; grep -q "本章你将学会" $f && echo "OK 开篇" || echo "MISS 开篇"; grep -q "^## 自测" $f && echo "OK 自测" || echo "MISS 自测"; wc -l $f; done
```

Expected: 两章都有「开篇」「自测」，各 ≥160 行。

- [ ] **Step 6: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 01-02 章扩写 + 新示例 02_app_lifecycle

01 章补 MFC 在 Windows UI 谱系中的位置对照表、常见坑与自测；02 章从
复用 01 示例改为独立示例，用日志窗口可视化 CWinApp 四阶段回调与消息
循环时序，并补关闭流程顺序图。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 3: 第 03–04 章扩写

**Files:**
- Modify: `mfc/docs/03-message-map.md`（163 → ~185 行）
- Modify: `mfc/docs/04-resources.md`（140 → ~165 行）

- [ ] **Step 1: 扩写 `docs/03-message-map.md`**

补开篇三行（对应示例 `examples/03_message_map`）与收尾三节。正文补两个小节：

- `## N. 消息映射的底层实现` —— 展开 `BEGIN_MESSAGE_MAP`/`END_MESSAGE_MAP` 宏展开后的 `AFX_MSGMAP_ENTRY` 数组结构（`nMessage`/`nCode`/`nID`/`nLastID`/`nSig`/`pfn`），说明 `AfxSig_*` 签名枚举与 MFC 如何在 `CWnd::OnWndMsg` 里线性查表后按签名转型调用。给一张 ASCII 图表示「HWND → CWnd 映射表（`CWnd::FromHandlePermanent`）→ 查 `messageMap` → 转型调用」。
- `## N. 命令消息与更新 UI` —— `ON_COMMAND` 与 `ON_UPDATE_COMMAND_UI` 的配对关系，`CCmdUI::SetCheck`/`Enable`/`SetText`，以及 `ON_UPDATE_COMMAND_UI` 只在空闲时被调用的机制（回到第 02 章 `OnIdle`）。

常见坑补：① `ON_COMMAND` 的 ID 与资源里不一致（静默无响应，不报错）；② `afx_msg` 写 `override` 报 C3668；③ `DECLARE_MESSAGE_MAP()` 放在类声明的 `private` 段仍然有效但习惯放末尾；④ 消息处理函数返回 `void` 却写了 `return` 值。

- [ ] **Step 2: 扩写 `docs/04-resources.md`**

补开篇三行（对应示例 `examples/04_resources`）与收尾三节。正文补：

- `## N. 资源 ID 的组织惯例` —— `resource.h` 全大写 `IDR_`/`IDD_`/`IDC_`/`IDI_`/`IDS_` 前缀含义；ID 区间划分建议（命令 32771 起、控件 1000 起、对话框 100 起）。
- `## N. 字符串表与国际化` —— `STRINGTABLE` 的用法；`CString::LoadString`；同一资源的多语言 `.rc`（`LANGUAGE` 指令 + 附属 DLL）思路；说明本书只用简体中文（`LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED`）。
- `## N. 图标的正确做法` —— `ICON` 资源、`SetIcon`/`SetClassLongPtr`、大小图标（`IDI_MAINFRAME` 提供 16×16 与 32×32 两档）。

常见坑补：① 含中文的 `.rc` 忘记 `#pragma code_page(65001)` 与 `rc /c65001` 导致乱码；② `resource.h` 与 `.rc` 里同一个 ID 定义了两次（后者静默覆盖）；③ 图标文件不是 `.ico` 而是改了扩展名的 `.bmp`（rc 报 RC2175）。

- [ ] **Step 3: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/03-message-map.md docs/04-resources.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 13 / 失败 0`；两章各 ≥160 行。

- [ ] **Step 4: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 03-04 章扩写（消息映射底层实现、资源 ID 惯例与国际化）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 4: 第 05–06 章扩写

**Files:**
- Modify: `mfc/docs/05-frames.md`（133 → ~160 行）
- Modify: `mfc/docs/06-dialogs.md`（158 → ~180 行）

- [ ] **Step 1: 扩写 `docs/05-frames.md`**

补开篇三行（对应示例 `examples/05_frame_layout`）与收尾三节。正文补：

- `## N. 窗口类的注册与 MFC 的封装` —— `AfxRegisterWndClass` vs `RegisterClassEx`；MFC 如何为每个 `CWnd` 派生类惰性注册窗口类；`CWnd::CreateEx` 的参数序列。
- `## N. 客户区布局的三种做法` —— 对照表：① `OnSize` 里手算 `MoveWindow`（示例用法，最直观）；② `CControlBar` 停靠栏（框架自动布局）；③ `CSplitterWnd` 分割（第 16 章）。给出 `OnSize` 手算的完整片段，含「窗口最小化时 `cx`/`cy` 为 0，必须提前返回」的守卫。

常见坑补：① `OnSize` 在窗口创建过程中会被调用，此时成员控件可能还没创建（`if (!IsWindow(m_edit)) return;`）；② 最小化时按 0 尺寸计算导致除零或控件消失；③ 用 `GetClientRect` 后又用 `ScreenToClient` 重复换算。

- [ ] **Step 2: 扩写 `docs/06-dialogs.md`**

补开篇三行（对应示例 `examples/06_dialog`）与收尾三节。正文补：

- `## N. DDX 与 DDV 的完整机制` —— `DoDataExchange` 里 `DDX_Text`/`DDX_Control`/`DDX_Check` 的展开；`UpdateData(TRUE/FALSE)` 的方向语义；`DDV_MinMaxInt` 等校验函数在 `UpdateData(TRUE)` 时的执行顺序与失败行为（弹框 + 焦点回到控件）。给一张「成员变量 ↔ 控件」的双向箭头图。
- `## N. 对话框的返回值与生命周期` —— `DoModal` 返回 `IDOK`/`IDCANCEL`；`OnOK`/`OnCancel` 的重写点；非模态对话框必须 `new` 且自己管理释放（示例里的做法），以及 `PostNcDestroy` 里 `delete this` 的惯用法。

常见坑补：① 非模态对话框用栈对象导致返回后窗口失效；② `UpdateData(TRUE)` 在 `OnInitDialog` 里调用会清空刚设好的初值（方向搞反）；③ `DDX_Control` 的成员必须在使用前绑定（`DoDataExchange` 首次调用时机）；④ 忘记 `OnInitDialog` 返回 `TRUE`（返回 `FALSE` 会导致焦点被框架改到第一个控件但 DDX 未完成）。

- [ ] **Step 3: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/05-frames.md docs/06-dialogs.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 13 / 失败 0`；两章各 ≥160 行。

- [ ] **Step 4: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 05-06 章扩写（窗口类注册、三种布局做法、DDX/DDV 完整机制）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 5: 第 07 章扩写（常用控件深入）

**Files:**
- Modify: `mfc/docs/07-controls.md`（167 → ~195 行）

- [ ] **Step 1: 扩写正文**

补开篇三行（对应示例 `examples/07_controls`）与收尾三节。正文补：

- `## N. 控件通用机制` —— 控件通知消息的两条路径：`ON_BN_CLICKED` 等按 ID 的宏 vs `ON_NOTIFY`（带 `NMHDR*`）；`GetDlgItem`/`SetDlgItemText` 与 DDX 的关系（前者是运行时、后者是批量同步）。
- `## N. CListCtrl 深入` —— 四种视图风格（图标/小图标/列表/报表）；报表视图的列宽自适应（`LVSCW_AUTOSIZE_USEHEADER`）；`LVS_EX_FULLROWSELECT`/`LVS_EX_GRIDLINES` 扩展样式；虚拟列表 `LVS_OWNERDATA` + `LVN_GETDISPINFO` 的适用场景（十万行以上）。
- `## N. 排序：SortItems 的正确用法` —— 强调回调收到的是**行 `ItemData` 指针而不是行号**，所以排序键必须冗余存进 `ItemData`；给出 `static int CALLBACK CompareFunc(LPARAM, LPARAM, LPARAM)` 的完整实现与 `SetItemData` 配套写入。

常见坑补：① `SortItems` 回调里用行号索引文本（spike 与旧版记忆都踩过，排序结果错乱）；② `InsertColumn` 的宽度传 0 导致列不可见；③ 忘记 `SetExtendedStyle` 导致整行选中失效；④ `DeleteAllItems` 后旧的 `ItemData` 指针悬空。

- [ ] **Step 2: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/07-controls.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 13 / 失败 0`；`07-controls.md` ≥185 行。

- [ ] **Step 3: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 07 章扩写（控件通用机制、CListCtrl 深入、SortItems 回调陷阱）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 6: 第 08 章 + 新示例 `08_controls_advanced`

**Files:**
- Create: `mfc/examples/08_controls_advanced/main.cpp`、`resource.h`、`advanced.rc`
- Create: `mfc/docs/08-controls-advanced.md`（新章，~175 行）

**Interfaces:**
- Consumes: `build.ps1` 的 `rc /c65001` 资源编译路径（Task 1）。
- Produces: 示例 `08_controls_advanced`；第 11 章将引用本章的「向导式属性页」概念。

- [ ] **Step 1: 写示例 `08_controls_advanced`**

`resource.h` 定义：`IDD_MAIN 101`、`IDD_PAGE1 102`、`IDD_PAGE2 103`、`IDD_PAGE3 104`、`IDC_TREE 1001`、`IDC_PROGRESS 1002`、`IDC_SLIDER 1003`、`IDC_DATE 1004`、`IDC_TASKDLG 1005`、`IDR_MAINFRAME 128`。

`advanced.rc` 必须以 `#pragma code_page(65001)` 开头，含主对话框与三个属性页对话框模板（属性页模板需 `WS_CHILD` 风格且**不带**标题栏/边框，`DIALOGEX` 的 `style` 用 `WS_CHILD | WS_VISIBLE | WS_CAPTION`），以及 `STRINGTABLE` 提供各页标题。

`main.cpp` 结构：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxcmn.h>
#include <afxtaskdialog.h>   // CTaskDialog 在这里，不在 afxwin.h

class CPage1 : public CPropertyPage {
public:
    CPage1() : CPropertyPage(IDD_PAGE1) {}
    BOOL OnSetActive() override;   // PSN_SETACTIVE：向导里可在此禁用"上一步"
    DECLARE_MESSAGE_MAP()
};
// CPage2 / CPage3 同构

class CAdvancedDlg : public CDialog {
public:
    CAdvancedDlg() : CDialog(IDD_MAIN) {}
    BOOL OnInitDialog() override;  // 填树、设进度/滑块范围、设日期
    afx_msg void OnTreeSelChanged(NMHDR*, LRESULT*);   // TVN_SELCHANGED
    afx_msg void OnSliderChanged();                    // 滑块 → 进度条联动
    afx_msg void OnTaskDialog();                       // 弹 CTaskDialog
    afx_msg void OnWizard();                           // 弹三页向导
    DECLARE_MESSAGE_MAP()
private:
    CTreeCtrl     m_tree;
    CProgressCtrl m_progress;
    CSliderCtrl   m_slider;
    CDateTimeCtrl m_date;
};
```

要点：
- `CTaskDialog` 用**三参构造** `CTaskDialog dlg(_T("内容"), _T("主指令"), _T("标题"));` 再 `dlg.AddCommandControl(100, _T("…")); dlg.SetMainIcon(TD_INFORMATION_ICON); dlg.DoModal();` —— 写 `CTaskDialog dlg;` 会报 C2512。
- 向导用 `CPropertySheet sheet(_T("向导")); sheet.AddPage(&p1); …; sheet.SetWizardMode(); sheet.DoModal();`
- 树用 `TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT`，`InsertItem` 返回 `HTREEITEM` 作为父句柄。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 08_controls_advanced 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 08_controls_advanced 2>&1 | tail -5
```

Expected: `[OK] 08_controls_advanced -> …`；`[ALIVE]`，末行 `[Done] 存活 1 / 失败 0`。若启动即退出，检查 `.rc` 里属性页模板是否带了 `WS_CHILD`。

- [ ] **Step 3: 写新章 `docs/08-controls-advanced.md`**

固定小节：

1. `## 1. 树控件 CTreeCtrl` —— `InsertItem` 的四种重载（文本/图标/父句柄）；`HTREEITEM` 是不透明句柄不是索引；`TVN_SELCHANGED` 里用 `GetSelectedItem` + `GetItemText` 取选中项；`SetImageList` 配 `CImageList`；`DeleteAllItems` 后句柄全部失效。给一张树形结构 ASCII 图。
2. `## 2. 属性页与向导 CPropertySheet` —— `CPropertyPage` 与 `CDialog` 的关系（前者继承后者）；属性页模板必须是 `WS_CHILD`；`AddPage`/`DoModal`；`SetWizardMode` 一键变向导；`OnSetActive` 控制按钮可用性；`OnWizardFinish` 收集结果。
3. `## 3. 任务对话框 CTaskDialog` —— 与 `MessageBox` 的对比表（图标、命令链接、页脚、进度条、验证回调）；**明确写出头文件与构造函数的坑**；`AddCommandControl` + `DoModal` 返回值判断。
4. `## 4. 日期时间、进度与滑块` —— `CDateTimeCtrl` 的 `DTN_DATETIMECHANGE` 与 `SetFormat`；`CProgressCtrl::SetRange32/SetPos`；`CSliderCtrl` 的 `TBS_HORZ`/`TBS_AUTOTICKS` 与 `NM_CUSTOMDRAW` 无关的 `SetTicFreq`；三者联动的示例代码。
5. `## 5. 常见坑` —— ① `CTaskDialog` 无默认构造 + 头文件在 `afxtaskdialog.h`（C2512）；② 属性页模板忘加 `WS_CHILD` 导致创建失败断言；③ `HTREEITEM` 当索引用（`DeleteAllItems` 后悬空）；④ 滑块 `SetRange` 与 `SetRange32` 在旧 SDK 的差异（统一用 `SetRange32`）。
6. `## 6. 实战建议` —— 树节点数据用 `SetItemData` 存指针并在 `DeleteAllItems` 前统一释放；属性页之间共享数据用 `CPropertySheet` 派生类的成员；任务对话框比 `MessageBox` 更适合"带操作选项的提示"。
7. `## 7. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/08-controls-advanced.md && echo "OK 开篇" || echo "MISS 开篇"
grep -q "^## 自测" docs/08-controls-advanced.md && echo "OK 自测" || echo "MISS 自测"
grep -q "examples/08_controls_advanced" docs/08-controls-advanced.md && echo "OK 示例引用" || echo "MISS 示例引用"
wc -l docs/08-controls-advanced.md
```

Expected: 三个 OK，行数 ≥170。

- [ ] **Step 5: 更新第 07 章的下一章链接**

把 `docs/07-controls.md` 末行的「下一章」从指向 `10-common-dialogs.md` 改为指向 `08-controls-advanced.md`；同时把 `docs/08-controls-advanced.md` 的「上一章」指向 `07-controls.md`、「下一章」指向 `09-custom-controls.md`。

- [ ] **Step 6: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 08 章控件进阶与示例 08_controls_advanced

树控件 / 属性页与向导 / 任务对话框 / 日期时间与进度滑块；实测记录
CTaskDialog 无默认构造且头文件在 afxtaskdialog.h 的坑。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 7: 第 09 章 + 新示例 `09_custom_controls`

**Files:**
- Create: `mfc/examples/09_custom_controls/main.cpp`、`resource.h`、`custom.rc`
- Create: `mfc/docs/09-custom-controls.md`（新章，~175 行）

- [ ] **Step 1: 写示例 `09_custom_controls`**

`resource.h`：`IDD_MAIN 101`、`IDC_OWNERDRAW_BTN 1001`、`IDC_LIST 1002`、`IDC_GAUGE 1003`、`IDR_MAINFRAME 128`。

`custom.rc`：对话框模板里按钮加 `BS_OWNERDRAW` 风格，列表加 `LVS_REPORT | LVS_OWNERDRAWFIXED`（或用 custom draw），再加一个空的静态框占位给自绘控件（`IDC_GAUGE`）。

`main.cpp` 结构：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxcmn.h>

// 1) Owner-draw 按钮：BS_OWNERDRAW + DrawItem
class COwnerDrawButton : public CButton {
public:
    void DrawItem(LPDRAWITEMSTRUCT dis) override;   // 按 ODS_SELECTED/ODS_FOCUS 画三种状态
    DECLARE_MESSAGE_MAP()
};

// 2) Custom draw 列表：NM_CUSTOMDRAW + NMLVCUSTOMDRAW
//    在 CDDS_ITEMPREPAINT 阶段按行号设 clrTextBk（斑马纹）

// 3) CWnd 派生自绘控件：注册窗口类 + 自己 OnPaint 画仪表盘
class CGaugeCtrl : public CWnd {
public:
    BOOL Create(CWnd* parent, UINT id, const CRect& rc);
    void SetValue(int percent);      // 改值后 Invalidate
    afx_msg void OnPaint();
    afx_msg BOOL OnEraseBkgnd(CDC*) { return TRUE; }  // 防闪烁
    DECLARE_MESSAGE_MAP()
private:
    int m_percent = 0;
};

// 4) 子类化：SetWindowSubclass 给标准编辑框加"只允许数字"过滤
```

要点：
- `DrawItem` 里用 `dis->itemState & ODS_SELECTED` 区分按下态，`dis->rcItem` 是绘制矩形，`dis->hDC` 是 DC（用 `CDC::FromHandle` 包装）。
- Custom draw 返回 `CDRF_NEWFONT`/`CDRF_DODEFAULT`；只在 `dwDrawStage == CDDS_ITEMPREPAINT` 时改 `clrTextBk`。
- 自绘控件用 `AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW, ::LoadCursor(NULL, IDC_ARROW), (HBRUSH)::GetStockObject(NULL_BRUSH))` 注册，再 `CWnd::Create`。
- 子类化用 `SetWindowSubclass(GetSafeHwnd(), SubclassProc, 1, (DWORD_PTR)this)` + `DefSubclassProc`（需要 `#include <commctrl.h>` 并链接 `comctl32.lib`）。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 09_custom_controls 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 09_custom_controls 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 3: 写新章 `docs/09-custom-controls.md`**

固定小节：

1. `## 1. 三条自绘路线` —— 对照表：① Owner-draw（`BS_OWNERDRAW`/`LBS_OWNERDRAWFIXED`，控件只给矩形，你全画）；② Custom draw（`NM_CUSTOMDRAW`，控件自己画、你只改属性）；③ 完全自绘控件（`CWnd` 派生，自己注册窗口类）。给出选择判据。
2. `## 2. Owner-draw 按钮` —— `DrawItem` 的 `DRAWITEMSTRUCT` 字段逐个解释（`CtlID`/`itemState`/`rcItem`/`hDC`/`itemData`）；画三种状态的完整代码；为什么必须处理 `ODS_FOCUS`（否则键盘用户看不到焦点）。
3. `## 3. Custom draw 列表` —— `NM_CUSTOMDRAW` 的两阶段（`CDDS_PREPAINT` 返回 `CDRF_NOTIFYITEMDRAW` → `CDDS_ITEMPREPAINT` 改颜色）；`NMLVCUSTOMDRAW` 的 `clrText`/`clrTextBk`；给出斑马纹实现；说明为什么这比 owner-draw 省事。
4. `## 4. 从零写一个自绘控件` —— `AfxRegisterWndClass` → `CWnd::Create` → `OnPaint` 的完整链条；`OnEraseBkgnd` 返回 `TRUE` 消除闪烁的原理；`Invalidate`/`UpdateWindow` 的调用时机；控件如何把"值变了"通知父窗口（自定义 `WM_*` + `SendMessage`）。
5. `## 5. 子类化：给现成控件加行为` —— `SetWindowSubclass`/`DefSubclassProc`（推荐，可叠加多层）vs `CWnd::SubclassWindow`（MFC 传统做法，单层且要小心生命周期）对照表；给出"编辑框只允许输入数字"的完整子类化过程。
6. `## 6. 常见坑` —— ① Owner-draw 控件忘写 `DrawItem`（按钮一片空白且不报错）；② Custom draw 在 `CDDS_PREPAINT` 直接改颜色（必须返回 `CDRF_NOTIFYITEMDRAW` 才收得到 item 阶段）；③ 自绘控件没处理 `OnEraseBkgnd` 导致严重闪烁；④ `SubclassWindow` 的对象先析构而窗口还活着（悬空）；⑤ 忘记链接 `comctl32.lib` 时 `SetWindowSubclass` 报未解析外部符号。
7. `## 7. 实战建议` —— 能用 custom draw 就别用 owner-draw；自绘控件把绘制逻辑抽成独立的 `Draw(CDC&, CRect)` 便于测试；高频刷新走 `InvalidateRect` 只失效脏区域。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/09-custom-controls.md && grep -q "^## 自测" docs/09-custom-controls.md && grep -q "examples/09_custom_controls" docs/09-custom-controls.md && echo "OK 骨架" || echo "MISS"
wc -l docs/09-custom-controls.md
```

Expected: `OK 骨架`，行数 ≥170。

- [ ] **Step 5: 接好上下章链接并提交**

`09-custom-controls.md` 的「上一章」指向 `08-controls-advanced.md`、「下一章」指向 `10-common-dialogs.md`；`10-common-dialogs.md` 的「上一章」改为 `09-custom-controls.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 09 章自绘与自定义控件 + 示例 09_custom_controls

Owner-draw / custom draw / CWnd 派生自绘控件 / SetWindowSubclass 子类化
四条路线对照与完整实现。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 8: 第 10–11 章扩写

**Files:**
- Modify: `mfc/docs/10-common-dialogs.md`（149 → ~170 行）
- Modify: `mfc/docs/11-toolbars.md`（128 → ~160 行）

- [ ] **Step 1: 扩写 `docs/10-common-dialogs.md`**

补开篇三行（对应示例 `examples/10_common_dialogs`）与收尾三节。正文补：

- `## N. 文件对话框的现代用法` —— `CFileDialog` 的 `bOpenFileDialog`/`lpszDefExt`/`lpszFileName`/`dwFlags`/`lpszFilter` 参数逐个解释；`OFN_ALLOWMULTISELECT` 多选后 `GetStartPosition`/`GetNextPathName` 的遍历；`OFN_EXPLORER` 与旧式对话框的差异；`CFileDialog` 与 Win32 的 `IFileOpenDialog`（第 22 章会提到的现代替代）的关系。
- `## N. 文件读写与编码` —— `CFile` 的 `Open`/`Read`/`Write`/`Close` 与 `CStdioFile` 的 `ReadString`/`WriteString` 对照；UTF-8 BOM 的写入与探测；`CFile::GetLength` 与 `SeekToEnd`；异常路径（`CFileException` 的 `GetErrorMessage`）。
- `## N. 颜色与字体对话框` —— `CColorDialog` 的 `COLORREF` 与 `RGB` 宏；`CFontDialog` 的 `LOGFONT`；把选中的字体应用到控件（`WM_SETFONT`）。

常见坑补：① `lpszFilter` 的字符串必须以 `||` 结尾；② 多选返回的字符串首段是目录、后续是文件名（不是完整路径）；③ `CFile` 打开失败不抛异常而返回 `FALSE`（只有 `CFileException*` 出参版本才抛）；④ 忘记 `Close` 导致文件句柄泄漏。

- [ ] **Step 2: 扩写 `docs/11-toolbars.md`**

补开篇三行（对应示例 `examples/11_toolbar_statusbar`）与收尾三节。正文补：

- `## N. 加速键表` —— `ACCELERATORS` 资源；`HACCEL` 的加载（`LoadAccelerators`）与在 `PreTranslateMessage` 里 `TranslateAccelerator` 的接线；**强调 `CWinApp` 没有 `m_hAccelTable` 成员，必须自己存一个 `HACCEL`**（旧记忆里的真实踩坑）。
- `## N. 状态栏的三个窗格` —— `CStatusBar::SetIndicators` 与 `ID_SEPARATOR` 的约定（第一个窗格默认是"就绪"提示区）；`ON_UPDATE_COMMAND_UI` 更新窗格文本；`SetPaneText` 的即时更新 vs 空闲更新的区别。
- `## N. 工具栏的两种形态` —— `CToolBar`（`afxext.h`，传统 MFC，配 `.bmp` 工具位图 + `TOOLBAR` 资源）与 `CMFCToolBar`（`afxcontrolbars.h`，Feature Pack）对照；`SetSizes`/`LoadBitmap`/`SetButtons` 的调用顺序。

常见坑补：① 加速键表忘接线导致菜单快捷键无效（点击菜单却正常）；② 状态栏第一个窗格被当成"就绪区"，想显示内容要放到索引 1 起；③ 工具栏位图不是 16 色/尺寸不对导致按钮花屏；④ `ON_UPDATE_COMMAND_UI` 里改了非 UI 状态导致空闲循环里反复触发。

- [ ] **Step 3: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/10-common-dialogs.md docs/11-toolbars.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 15 / 失败 0`；两章各 ≥160 行。

- [ ] **Step 4: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 10-11 章扩写（文件对话框现代用法、加速键表与状态栏窗格）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 9: 第 12 章 + 新示例 `12_clipboard_dnd`

**Files:**
- Create: `mfc/examples/12_clipboard_dnd/main.cpp`、`resource.h`、`clipboard.rc`
- Create: `mfc/docs/12-clipboard-dnd.md`（新章，~165 行）

**Interfaces:**
- Consumes: `build.ps1` 的 `$extraLibsByExample['12_clipboard_dnd'] = @('ole32.lib','oleaut32.lib')` 白名单（Task 1）。
- Produces: 示例 `12_clipboard_dnd`。

- [ ] **Step 1: 写示例 `12_clipboard_dnd`**

`resource.h`：`IDD_MAIN 101`、`IDC_EDIT 1001`、`IDC_COPY 1002`、`IDC_PASTE 1003`、`IDC_DROPZONE 1004`、`IDC_STATUS 1005`、`IDR_MAINFRAME 128`。

`main.cpp` 结构：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxole.h>     // COleDataSource / COleDropTarget / COleDataObject

class CDropTarget : public COleDropTarget {
public:
    DROPEFFECT OnDragEnter(CWnd*, COleDataObject* pData, DWORD, CPoint) override;
    DROPEFFECT OnDragOver (CWnd*, COleDataObject* pData, DWORD, CPoint) override;
    void       OnDragLeave(CWnd*) override;
    // 注意：OnDrop 返回 BOOL 不是 DROPEFFECT！写 DROPEFFECT 报 C2555
    BOOL       OnDrop(CWnd*, COleDataObject* pData, DROPEFFECT, CPoint) override;
};

class CMainDlg : public CDialog {
public:
    BOOL OnInitDialog() override;      // m_drop.Register(this)
    afx_msg void OnCopy();             // 文本 → 剪贴板（CF_UNICODETEXT）
    afx_msg void OnPaste();            // 剪贴板 → 编辑框
    afx_msg void OnDragOut();          // 拖出：COleDataSource + DoDragDrop
    DECLARE_MESSAGE_MAP()
    CDropTarget m_drop;
};

class CClipApp : public CWinApp {
public:
    BOOL InitInstance() override {
        if (!AfxOleInit()) return FALSE;   // 拖放必需，否则 Register 失败
        ...
    }
};
```

要点：
- 写剪贴板：`OpenClipboard()` → `EmptyClipboard()` → `GlobalAlloc(GMEM_MOVEABLE, (len+1)*sizeof(wchar_t))` → `memcpy` → `SetClipboardData(CF_UNICODETEXT, h)` → `CloseClipboard()`。**`SetClipboardData` 成功后所有权移交系统，不能再 `GlobalFree`**。
- 读剪贴板：`IsClipboardFormatAvailable(CF_UNICODETEXT)` → `GetClipboardData` → `GlobalLock`/`GlobalUnlock`。
- 接文件：`OnDragEnter` 里 `pData->IsDataAvailable(CF_HDROP)` 决定返回 `DROPEFFECT_COPY` 还是 `DROPEFFECT_NONE`；`OnDrop` 里 `GetGlobalData(CF_HDROP)` 拿到 `HDROP`，`DragQueryFile` 逐个取路径，然后 `GlobalFree`。
- 拖出：`COleDataSource src; src.CacheGlobalData(CF_UNICODETEXT, hGlobal); DROPEFFECT de = src.DoDragDrop(DROPEFFECT_COPY);`

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 12_clipboard_dnd 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 12_clipboard_dnd 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。若链接报 `IID_*` 未解析，确认 `$extraLibsByExample` 里的 `ole32.lib oleaut32.lib` 已生效。

- [ ] **Step 3: 写新章 `docs/12-clipboard-dnd.md`**

固定小节：

1. `## 1. 剪贴板的数据模型` —— 剪贴板是"格式 → 全局内存句柄"的表；`CF_UNICODETEXT`/`CF_TEXT`/`CF_HDROP`/`CF_BITMAP` 等标准格式；为什么必须用 `GMEM_MOVEABLE` 分配（系统接管所有权后要能移动内存块）；ASCII 图表示「你的进程 → 系统剪贴板 → 另一个进程」的所有权流转。
2. `## 2. 文本剪贴板的完整实现` —— 写与读的完整代码；`OpenClipboard` 失败要重试（别的进程可能正占着）；`EmptyClipboard` 会把所有格式清空；`CloseClipboard` 必须在所有分支执行（含异常路径）。
3. `## 3. 拖放：OLE 而不是 WM_DROPFILES` —— 对照表：`DragAcceptFiles` + `WM_DROPFILES`（简单，只能接文件，不能拖出）vs `COleDropTarget`（完整 OLE 拖放，可接任意格式，可拖出）；`AfxOleInit()` 的必要性。
4. `## 4. COleDropTarget 的四个回调` —— `OnDragEnter`/`OnDragOver`/`OnDrop`/`OnDragLeave` 各自的返回值与语义；**重点标出 `OnDrop` 返回 `BOOL` 而其余返回 `DROPEFFECT`**（写错报 C2555），并解释为什么 MFC 这样设计（`BOOL` 表示"我处理了"，`DROPEFFECT` 表示"允许什么操作"）。
5. `## 5. 把数据拖出去` —— `COleDataSource` + `CacheGlobalData` + `DoDragDrop`；`DoDragDrop` 是阻塞的，返回时拖放已结束；`DROPEFFECT_NONE` 表示对方拒收。
6. `## 6. 常见坑` —— ① `OnDrop` 写成返回 `DROPEFFECT`（C2555）；② 忘 `AfxOleInit()` 导致 `Register` 失败；③ `SetClipboardData` 后又 `GlobalFree`（双重释放，剪贴板内容损坏）；④ `OpenClipboard` 不检查返回值；⑤ 拖放目标窗口没调用 `Register`；⑥ `CF_HDROP` 的文件列表必须以双 `\0` 结尾。
7. `## 7. 实战建议` —— 剪贴板操作包成 RAII 小类保证 `CloseClipboard`；拖放时用 `OnDragOver` 实时给用户视觉反馈（改状态栏文字）；跨进程拖放要延迟渲染（`SetClipboardData(fmt, NULL)` + `OnRenderGlobalData`），本教程只讲即时渲染。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/12-clipboard-dnd.md && grep -q "^## 自测" docs/12-clipboard-dnd.md && grep -q "examples/12_clipboard_dnd" docs/12-clipboard-dnd.md && echo "OK 骨架" || echo "MISS"
wc -l docs/12-clipboard-dnd.md
```

Expected: `OK 骨架`，行数 ≥160。

- [ ] **Step 5: 接好上下章链接并提交**

`12-clipboard-dnd.md` 的「上一章」指向 `11-toolbars.md`、「下一章」指向 `13-shell-integration.md`；`11-toolbars.md` 的「下一章」改为 `12-clipboard-dnd.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 12 章剪贴板与拖放 + 示例 12_clipboard_dnd

文本/文件剪贴板读写、COleDropTarget 四回调、COleDataSource 拖出；
实测记录 OnDrop 返回 BOOL 而非 DROPEFFECT 的 C2555 陷阱。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 10: 第 13 章 + 新示例 `13_shell_integration`

**Files:**
- Create: `mfc/examples/13_shell_integration/main.cpp`、`resource.h`、`shell.rc`
- Create: `mfc/docs/13-shell-integration.md`（新章，~175 行）

**Interfaces:**
- Produces: 示例 `13_shell_integration` —— **第 24 章（Task 20）会重构它的源码**，因此本章的 `main.cpp` 里裸句柄的写法要刻意保留（作为重构对照的"改造前"）。

- [ ] **Step 1: 写示例 `13_shell_integration`**

`resource.h`：`IDD_MAIN 101`、`IDC_FOLDER 1001`、`IDC_BROWSE 1002`、`IDC_SCAN 1003`、`IDC_RESULT 1004`、`IDC_RECENT 1005`、`IDC_SAVE_CFG 1006`、`IDC_LOAD_CFG 1007`、`IDR_MAINFRAME 128`。

`main.cpp` 四块功能：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxadv.h>   // CRecentFileList

// 1) CFileFind 递归统计：目录 → 文件数/总字节/最大文件
static void ScanDir(LPCTSTR root, int& files, ULONGLONG& bytes, CString& biggest, CStringArray& out);

// 2) 最近文件列表：CRecentFileList（构造参数 nStart, lpszSection, lpszEntryFormat, nSize）
//    mru.Add(path) / mru.GetDisplayName(i, buf, n) / mru.Remove(i)
//    显示在 IDC_RECENT 列表框里，双击可"打开"

// 3) 配置持久化：
//    InitInstance 里 SetRegistryKey(_T("GuideTutorials")) 之后
//    AfxGetApp()->WriteProfileString/GetProfileString 走
//    HKCU\Software\GuideTutorials\<应用名>\<section>

// 4) 单实例：
//    HANDLE h = CreateMutex(NULL, FALSE, _T("Guide.Mfc.ShellIntegration"));
//    if (GetLastError() == ERROR_ALREADY_EXISTS) { 提示并退出 }
```

要点：递归扫描要跳过 `"."`/`".."`（`CFileFind` 默认不返回，但 `GetFileName()` 要判 `IsDirectory()` 后再递归）；`ULONGLONG` 累加避免 4GB 溢出；`SetRegistryKey` 必须在任何 `WriteProfile*` 之前调用。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 13_shell_integration 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 13_shell_integration 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 3: 写新章 `docs/13-shell-integration.md`**

固定小节：

1. `## 1. 遍历文件系统：CFileFind` —— `FindFile`/`FindNextFile` 的循环骨架（必须用 `while (finder.FindNextFile())` 的惯用法，最后一次调用返回 `FALSE` 时仍有一个有效结果）；`IsDirectory`/`IsDots`/`GetLength`/`GetFilePath`/`GetFileName` 的语义；递归遍历的完整实现与"符号链接死循环"的现实风险。
2. `## 2. 最近文件列表 MRU` —— `CRecentFileList` 的四个构造参数含义；`Add` 自动去重与裁剪；`GetDisplayName` 的 `&` 前缀表示加速键；把 MRU 接进菜单的两种做法（动态菜单项 vs 独立对话框，示例用后者）。
3. `## 3. 配置持久化：注册表还是 INI` —— `SetRegistryKey` 之后 `WriteProfileString`/`GetProfileString`/`WriteProfileInt` 自动落到 `HKCU\Software\<公司>\<应用>\<节>`；不调 `SetRegistryKey` 时落到 exe 同目录的 `.ini`；两者对照表；为什么写 `HKCU` 而不写 `HKLM`（免管理员、免 UAC 虚拟化）。
4. `## 4. 单实例程序` —— `CreateMutex` + `GetLastError() == ERROR_ALREADY_EXISTS` 的标准写法；为什么不用 `FindWindow`（不可靠，窗口类名可被伪造）；命名互斥体的 `Global\` 前缀与权限；把已运行实例拉到前台的正确做法（`AllowSetForegroundWindow` + 自定义广播消息）。
5. `## 5. 常见坑` —— ① `CFileFind` 循环写成 `while (finder.FindNextFile())` 之外的形态导致漏掉最后一个文件；② 递归时不判断 `IsDirectory` 导致对文件调 `FindFile`；③ `SetRegistryKey` 在 `WriteProfileString` 之后调用（写到了错误位置）；④ 互斥体句柄没保存（被 GC/析构提前释放，单实例失效）；⑤ 用 `FindWindow` 做单实例导致误判。
6. `## 6. 实战建议` —— `SetRegistryKey(_T("公司名"))` 一次就够，应用名自动取自 exe 名；配置读写包成 `LoadConfig`/`SaveConfig` 两个函数；MRU 的 `nSize` 取 4~16。
7. `## 7. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/13-shell-integration.md && grep -q "^## 自测" docs/13-shell-integration.md && grep -q "examples/13_shell_integration" docs/13-shell-integration.md && echo "OK 骨架" || echo "MISS"
wc -l docs/13-shell-integration.md
```

Expected: `OK 骨架`，行数 ≥170。

- [ ] **Step 5: 接好上下章链接并提交**

`13-shell-integration.md` 的「上一章」指向 `12-clipboard-dnd.md`、「下一章」指向 `14-dpi-darkmode.md`；`12-clipboard-dnd.md` 的「下一章」改为 `13-shell-integration.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 13 章文件系统、Shell 与最近文件 + 示例 13_shell_integration

CFileFind 递归、CRecentFileList、注册表/INI 配置持久化、单实例互斥体。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 11: 第 14 章 + 新示例 `14_dpi_darkmode`

**Files:**
- Create: `mfc/examples/14_dpi_darkmode/main.cpp`、`resource.h`、`dpi.rc`
- Create: `mfc/docs/14-dpi-darkmode.md`（新章，~160 行）

**Interfaces:**
- Consumes: `build.ps1` 的 `$extraLibsByExample['14_dpi_darkmode'] = @('dwmapi.lib')` 白名单（Task 1）。

- [ ] **Step 1: 写示例 `14_dpi_darkmode`**

`resource.h`：`IDD_MAIN 101`、`IDC_DPIINFO 1001`、`IDC_TOGGLEDARK 1002`、`IDC_SAMPLE 1003`、`IDR_MAINFRAME 128`。

`main.cpp` 要点：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <dwmapi.h>          // DwmSetWindowAttribute
#pragma comment(lib, "dwmapi.lib")

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

class CDpiApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 必须在任何窗口创建之前调用
        ::SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
        ...
    }
};

// 主对话框：
//   OnInitDialog  读 GetDpiForWindow(m_hWnd) 显示 DPI 与缩放百分比
//   OnToggleDark  DwmSetWindowAttribute(m_hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &b, sizeof(BOOL))
//   OnDpiChanged  WM_DPICHANGED：用 lParam 里的 RECT* 重设窗口位置尺寸，按新 DPI 重排控件
//   OnSettingChange WM_SETTINGCHANGE 且 lParam 为 "ImmersiveColorSet" 时重读系统主题
```

`dpi.rc` 用 `#pragma code_page(65001)`；对话框模板里的控件**不写绝对像素**，在 `OnInitDialog` 里按 DPI 缩放因子统一 `MoveWindow`（给出 `Scale(int px) { return MulDiv(px, m_dpi, 96); }` 辅助函数）。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 14_dpi_darkmode 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 14_dpi_darkmode 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。若链接报 `DwmSetWindowAttribute` 未解析，确认 `dwmapi.lib` 白名单生效。

- [ ] **Step 3: 写新章 `docs/14-dpi-darkmode.md`**

固定小节：

1. `## 1. 为什么会有 DPI 问题` —— 高 DPI 屏上 96 DPI 假设的失效；系统缩放（拉伸位图，模糊）vs 应用自己缩放（清晰）的区别；`GetDpiForWindow` 返回的是**窗口所在显示器**的 DPI，多显示器下会不同。
2. `## 2. 三种 DPI 感知级别` —— 对照表：Unaware（系统拉伸）/ System Aware（按主显示器 DPI 缩放，跨屏模糊）/ Per-Monitor Aware v2（推荐，跟随窗口所在屏）；`SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)` 必须在**任何窗口创建前**调用；也可用清单文件声明（两者选一，清单优先）。
3. `## 3. 按 DPI 缩放布局` —— `MulDiv(px, dpi, 96)` 的缩放辅助函数；为什么不要在 `.rc` 里写死像素；`WM_DPICHANGED` 的 `wParam`（新 DPI，高 16 位 X 低 16 位 Y）与 `lParam`（`RECT*` 建议的新窗口矩形）；完整处理函数。
4. `## 4. 深色标题栏` —— `DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE /* 20 */, &bDark, sizeof(BOOL))`；常量在旧 SDK 头文件里没有，要自己 `#define`；这个 API 只改**非客户区**（标题栏/边框），客户区要自己画；读系统主题偏好的注册表路径 `HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme`。
5. `## 5. 响应系统主题变化` —— `WM_SETTINGCHANGE` 的 `lParam` 是变更类别字符串，主题变化时是 `"ImmersiveColorSet"`；对比 `WM_THEMECHANGED`（视觉样式变化）；重读偏好并刷新界面。
6. `## 6. 常见坑` —— ① `SetProcessDpiAwarenessContext` 在窗口创建后调用（静默失败，返回值没检查）；② `.rc` 里写死像素导致高 DPI 下控件挤成一团；③ `WM_DPICHANGED` 里不按 `lParam` 的 `RECT` 调整窗口（窗口尺寸不跟随，被系统拉伸变模糊）；④ `DWMWA_USE_IMMERSIVE_DARK_MODE` 在旧 SDK 头文件里缺失导致编译错误（自己 `#define`）；⑤ 以为深色模式 API 会把客户区也变黑。
7. `## 7. 实战建议` —— 全程序统一用 `Scale()` 函数，不要散落 `MulDiv`；深色模式至少处理标题栏 + 自绘控件的背景色；用 `dpiAwareness` 清单比调 API 更可靠（API 调用时机太容易错）。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/14-dpi-darkmode.md && grep -q "^## 自测" docs/14-dpi-darkmode.md && grep -q "examples/14_dpi_darkmode" docs/14-dpi-darkmode.md && echo "OK 骨架" || echo "MISS"
wc -l docs/14-dpi-darkmode.md
```

Expected: `OK 骨架`，行数 ≥160。

- [ ] **Step 5: 接好上下章链接并提交**

`14-dpi-darkmode.md` 的「上一章」指向 `13-shell-integration.md`、「下一章」指向 `15-docview.md`；`15-docview.md` 的「上一章」改为 `14-dpi-darkmode.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 14 章 DPI 感知与深色模式 + 示例 14_dpi_darkmode

三种 DPI 感知级别、MulDiv 缩放布局、WM_DPICHANGED 处理、DwmSetWindowAttribute
深色标题栏、WM_SETTINGCHANGE 主题响应。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 12: 第 15 章扩写（Doc/View 架构）

**Files:**
- Modify: `mfc/docs/15-docview.md`（169 → ~195 行）

- [ ] **Step 1: 扩写正文**

补开篇三行（对应示例 `examples/15_docview`）与收尾三节。正文补：

- `## N. 文档模板与运行时类信息` —— `CRuntimeClass` 与 `DECLARE_DYNCREATE`/`IMPLEMENT_DYNCREATE` 宏的展开；框架为什么需要反射（模板要在不知道具体类的情况下 `new` 出文档/框架/视图）；`RUNTIME_CLASS(CNoteDoc)` 返回的指针如何被 `CDocTemplate::CreateNewFrame` 使用。给一张「CDocTemplate → 三个 CRuntimeClass → 三个对象实例」的 ASCII 图。
- `## N. 多视图与数据同步` —— `UpdateAllViews(pSender, lHint, pHint)` 的三种调用形态（全刷/排除发送者/带提示）；`OnUpdate` 里根据 `lHint` 做局部刷新的完整写法；`CView::OnInitialUpdate` 与 `OnUpdate` 的调用时机差异（前者只在视图创建后调一次）。
- `## N. 脏标记与关闭确认` —— `SetModifiedFlag`/`IsModified` 与标题 `*` 的联动；`CDocument::SaveModified` 的返回语义；`OnNewDocument` 里清空数据并 `SetModifiedFlag(FALSE)`。

常见坑补：① `IMPLEMENT_DYNCREATE` 只写在头文件（链接报未解析）；② 构造函数写成 `private`（框架反射创建失败）；③ `OnUpdate` 里忘了防回环（第 10 章已提，这里给 Doc/View 版的具体守卫）；④ `UpdateAllViews` 在 `Serialize` 里调用（加载过程中刷新导致读到半成品数据）。

- [ ] **Step 2: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/15-docview.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 18 / 失败 0`；`15-docview.md` ≥185 行。

- [ ] **Step 3: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 15 章扩写（运行时类信息、多视图同步、脏标记与关闭确认）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 13: 第 16 章 + 新示例 `16_mdi_splitter`

**Files:**
- Create: `mfc/examples/16_mdi_splitter/main.cpp`、`resource.h`、`mdi.rc`
- Create: `mfc/docs/16-mdi-splitter.md`（新章，~175 行）

- [ ] **Step 1: 写示例 `16_mdi_splitter`**

`resource.h`：`IDR_MAINFRAME 128`、`IDR_MDITYPE 129`、`IDD_ABOUTBOX 100`，以及菜单命令 `ID_FILE_NEW 0xE100`、`ID_APP_EXIT 0xE141`。

`mdi.rc`：**两套菜单/加速键/字符串表** —— `IDR_MAINFRAME`（MDI 外壳：文件-新建/退出、窗口-层叠/平铺）与 `IDR_MDITYPE`（文档类型：文件-新建/打开/保存/另存）；`IDR_MDITYPE` 的字符串表是 Doc/View 的 9 字段格式。两个 `DIALOGEX` 模板作为分割窗格的左右视图内容。

`main.cpp` 结构：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxext.h>   // CSplitterWnd

class CLeftView  : public CView { /* 列表视图：文档里的条目列表 */ };
class CRightView : public CView { /* 详情视图：显示选中条目 */ };

class CChildFrame : public CMDIChildWnd {
    DECLARE_DYNCREATE(CChildFrame)
public:
    BOOL OnCreateClient(LPCREATESTRUCT, CCreateContext* ctx) override {
        if (!m_split.CreateStatic(this, 1, 2)) return FALSE;
        m_split.CreateView(0, 0, RUNTIME_CLASS(CLeftView),  CSize(180, 0), ctx);
        m_split.CreateView(0, 1, RUNTIME_CLASS(CRightView), CSize(0, 0),   ctx);
        return TRUE;
    }
    CSplitterWnd m_split;
};

class CShellApp : public CWinApp {
public:
    BOOL InitInstance() override {
        auto* pDocTemplate = new CMultiDocTemplate(
            IDR_MDITYPE, RUNTIME_CLASS(CMdiDoc), RUNTIME_CLASS(CChildFrame), RUNTIME_CLASS(CLeftView));
        AddDocTemplate(pDocTemplate);
        auto* pMainFrame = new CMainFrame;   // CMDIFrameWnd
        ...
    }
};
```

要点：左视图 `OnUpdate` 里刷新列表并广播 `HINT_SELECTION`；右视图 `OnUpdate` 里根据 `lHint` 决定是否只刷新详情；两侧用同一份 `CDocument` 数据，**不允许各存一份**。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 16_mdi_splitter 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 16_mdi_splitter 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。若启动即退出，检查 `IDR_MAINFRAME` 与 `IDR_MDITYPE` 的字符串表是否都在，以及 `CMultiDocTemplate` 的 9 字段串字段数。

- [ ] **Step 3: 写新章 `docs/16-mdi-splitter.md`**

固定小节：

1. `## 1. SDI、MDI 与对话框式` —— 三种应用形态对照表（窗口数、模板类、典型场景）；MDI 的窗口层次 ASCII 图：`CMDIFrameWnd`（外壳，含菜单/工具栏）→ `CMDIChildWnd`（子窗口，被限制在外壳客户区内）→ `CView`。
2. `## 2. CMultiDocTemplate 与两套资源` —— 为什么 MDI 需要 `IDR_MAINFRAME`（外壳）与 `IDR_MDITYPE`（文档类型）两套菜单/加速键/图标；`CDocManager` 维护模板列表，`File-New` 时选哪个模板的规则（只有一个模板时直接选它）；9 字段字符串表在 MDI 下的作用。
3. `## 3. 分割窗口 CSplitterWnd` —— `CreateStatic`（固定分栏，每栏一个视图类）vs `CreateDynamic`（同类型多栏，可增删）对照；`CreateView` 的 `CCreateContext*` 必须来自 `OnCreateClient` 的参数（自己造会导致 `GetDocument()` 拿不到文档）；`SetColumnInfo`/`SetRowInfo` 设初始宽度；`CSplitterWnd` 的父子关系（它是子框架的子窗口，不是视图）。
4. `## 4. 多视图数据同步` —— 左列表右详情的经典布局；`UpdateAllViews(this, HINT_SELECTION, &sel)` 带提示广播；`OnUpdate` 里按 `lHint` 分支；左视图负责"选谁"、右视图负责"显示谁"、文档负责"数据是什么"的职责划分图。
5. `## 5. 常见坑` —— ① `CreateView` 的 `CCreateContext*` 传 `NULL` 导致 `GetDocument()` 返回 `NULL`（视图里一访问就崩）；② `CreateStatic` 的行列数与后续 `CreateView` 的索引不匹配（断言）；③ MDI 的 `IDR_MAINFRAME` 字符串表漏写（外壳菜单出不来）；④ 两个视图各存一份数据（同步立刻失效）；⑤ `OnCreateClient` 返回 `FALSE` 时框架不报错但子窗口空白。
6. `## 6. 实战建议` —— 分割窗格的初始宽度用 `SetColumnInfo` 而不是硬编码；左视图的选中项变化用 `GetDocument()->UpdateAllViews(this, ...)` 广播；MDI 子窗口数量多时记得处理 `WM_MDIACTIVATE` 更新标题。
7. `## 7. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/16-mdi-splitter.md && grep -q "^## 自测" docs/16-mdi-splitter.md && grep -q "examples/16_mdi_splitter" docs/16-mdi-splitter.md && echo "OK 骨架" || echo "MISS"
wc -l docs/16-mdi-splitter.md
```

Expected: `OK 骨架`，行数 ≥170。

- [ ] **Step 5: 接好上下章链接并提交**

`16-mdi-splitter.md` 的「上一章」指向 `15-docview.md`、「下一章」指向 `17-serialize.md`；`15-docview.md` 的「下一章」改为 `16-mdi-splitter.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 16 章 MDI 多文档与分割窗口 + 示例 16_mdi_splitter

CMultiDocTemplate 两套资源、CSplitterWnd 静态分栏、左列表右详情多视图同步。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 14: 第 17 章 + 新示例 `17_serialize`

**Files:**
- Create: `mfc/examples/17_serialize/main.cpp`、`resource.h`、`serialize.rc`
- Create: `mfc/docs/17-serialize.md`（新章，~165 行）

- [ ] **Step 1: 写示例 `17_serialize`**

`resource.h`：`IDR_MAINFRAME 128`、`IDD_ABOUTBOX 100`。

`main.cpp` 结构：SDI Doc/View 应用，文档里存一个 `CArray<CItem*, CItem*>`，`CItem` 是可序列化的自定义类：

```cpp
#include "resource.h"
#include <afxwin.h>

class CItem : public CObject {
    DECLARE_SERIAL(CItem)
public:
    CItem() = default;
    CItem(LPCTSTR name, int qty, double price) : m_name(name), m_qty(qty), m_price(price) {}
    void Serialize(CArchive& ar) override;   // 注意：这里手写版本号，不用 ar.GetObjectSchema()
    CString m_name;
    int     m_qty   = 0;
    double  m_price = 0.0;
    // v2 新增字段（读旧文件时为默认值）
    CString m_note;
};
IMPLEMENT_SERIAL(CItem, CObject, 1)   // 末参是 schema 版本号

// CDocument::Serialize：
//   const WORD kVersion = 2;   // 当前文件格式版本
//   if (ar.IsStoring()) {
//       ar << kVersion;
//       ar << (int)m_items.GetSize();
//       for (auto* p : m_items) ar << p;
//   } else {
//       WORD ver = 0; ar >> ver;
//       int n = 0;    ar >> n;
//       for (int i = 0; i < n; ++i) { CItem* p = nullptr; ar >> p; m_items.Add(p); }
//       if (ver < 2) { /* 旧版本没有 m_note，用默认值 */ }
//   }
```

要点：手写 `kVersion` 头是**推荐做法**（比 `GetObjectSchema` 更可控）；`ar << p`（`CObject*`）会写类名 + schema 号，读取时按类名反查 `CRuntimeClass` 并 `new`；`IMPLEMENT_SERIAL` 必须与 `DECLARE_SERIAL` 配对。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 17_serialize 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 17_serialize 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 3: 写新章 `docs/17-serialize.md`**

固定小节：

1. `## 1. CArchive 是什么` —— `CArchive` 是"字节流 + 类型分派"的包装；`<<`/`>>` 运算符重载表（基本类型、`CString`、`CObject*`、`CByteArray` 等）；`IsStoring()` 决定方向；ASCII 图表示「对象 ↔ CArchive ↔ CFile ↔ 磁盘」。
2. `## 2. 让自定义类可序列化` —— `DECLARE_SERIAL`/`IMPLEMENT_SERIAL` 宏对；`Serialize` 成员函数的重写；`CObject*` 写入时 MFC 会额外写类名与 schema 号（用 `WriteObject`/`ReadObject` 而非 `Write`/`Read`）；为什么类必须有默认构造函数。
3. `## 3. 版本化：让旧文件还能打开` —— 两种做法对照：`ar.GetObjectSchema()`/`SetObjectSchema`（MFC 内置，但只覆盖单个对象）vs **手写文件头版本号**（推荐，可控、可整体升降级）；给出"v1 文件被 v2 程序打开"的完整兼容读取代码；升级策略（只加字段不删字段、字段语义不复用）。
4. `## 4. 容器与指针图` —— `CArray`/`CObList` 的序列化（`Serialize` 里循环 `ar << p`）；`CObList` 自带序列化支持；**指针共享与循环引用**问题（MFC 的 `CArchive` 对同一指针只写一次，但要求对象由 `new` 创建且归文档所有）；所有权约定（文档拥有对象，析构时释放）。
5. `## 5. 常见坑` —— ① 忘记 `IMPLEMENT_SERIAL`（链接报 `CRuntimeClass` 未解析）；② 自定义类没有默认构造函数（读取时反射创建失败断言）；③ 版本号只在写侧改、读侧没判断（读旧文件崩溃或读到垃圾）；④ 用 `ar.Write` 直接写对象内存（含指针，换机器就废）；⑤ 读取时 `new` 出来的对象在失败路径上泄漏。
6. `## 6. 实战建议` —— 文件格式第一版就把版本号写进去（后面加字段不用改格式）；`Serialize` 保持纯数据、不碰 UI（第 15 章已提）；单测时用 `CMemFile` 代替磁盘文件，序列化逻辑可以脱离界面测试。
7. `## 7. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/17-serialize.md && grep -q "^## 自测" docs/17-serialize.md && grep -q "examples/17_serialize" docs/17-serialize.md && echo "OK 骨架" || echo "MISS"
wc -l docs/17-serialize.md
```

Expected: `OK 骨架`，行数 ≥160。

- [ ] **Step 5: 接好上下章链接并提交**

`17-serialize.md` 的「上一章」指向 `16-mdi-splitter.md`、「下一章」指向 `18-gdi.md`；`16-mdi-splitter.md` 的「下一章」改为 `17-serialize.md`；`18-gdi.md` 的「上一章」改为 `17-serialize.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 17 章序列化深入与文档版本化 + 示例 17_serialize

DECLARE_SERIAL/IMPLEMENT_SERIAL、手写文件头版本号、v1 文件向后兼容读取、
容器序列化与所有权约定。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 15: 第 18 章扩写 + 第 19 章 + 新示例 `19_printing`

**Files:**
- Modify: `mfc/docs/18-gdi.md`（127 → ~160 行）
- Create: `mfc/examples/19_printing/main.cpp`、`resource.h`、`print.rc`
- Create: `mfc/docs/19-printing.md`（新章，~165 行）

- [ ] **Step 1: 扩写 `docs/18-gdi.md`**

补开篇三行（对应示例 `examples/18_gdi`）与收尾三节。正文补：

- `## N. CDC 与 GDI 对象的所有权` —— `CPen`/`CBrush`/`CFont` 创建后必须 `SelectObject` 进 DC 并把旧对象存下来，**用完必须选回旧对象再销毁新对象**（否则 GDI 对象泄漏）；`CDC::FromHandle` 的临时对象与永久对象的区别。
- `## N. 双缓冲的三种写法` —— ① `CreateCompatibleDC` + `CreateCompatibleBitmap`（示例用法，最通用）；② `CMemDC`（Feature Pack 的现成封装，`afxcontrolbars.h`）；③ `SetDoubleBuffer` 相关的高阶做法；给出第 ① 种的完整 `OnPaint` 骨架，含"内存位图尺寸必须与客户区一致，`OnSize` 时重建"的要点。
- `## N. 什么时候不该用 GDI` —— GDI 不支持抗锯齿与 Alpha 混合，需要这些效果时走 GDI+（第 22 章）或 Direct2D（第 22 章）；GDI 的优势是启动快、依赖少、适合简单图形与打印。

常见坑补：① 内存位图没随窗口尺寸重建（拉伸变形）；② `SelectObject` 后忘了 `DeleteObject` 旧对象（GDI 对象泄漏，进程句柄数上涨）；③ 在 `OnPaint` 里 `new` 出 `CDC` 而不用 `CPaintDC`（`BeginPaint`/`EndPaint` 不配对）；④ `OnEraseBkgnd` 与双缓冲同时使用导致闪一下。

- [ ] **Step 2: 写示例 `19_printing`**

`resource.h`：`IDR_MAINFRAME 128`、`IDD_ABOUTBOX 100`、`ID_FILE_PRINT 0xE107`、`ID_FILE_PRINT_PREVIEW 0xE109`、`ID_FILE_PRINT_SETUP 0xE106`。

`main.cpp`：SDI Doc/View 应用，视图重写打印相关函数：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <afxext.h>   // CPreviewView / 打印预览

class CReportView : public CView {
    DECLARE_DYNCREATE(CReportView)
public:
    void OnDraw(CDC* pDC) override;                       // 屏幕绘制
    BOOL OnPreparePrinting(CPrintInfo* pInfo) override;    // 调 DoPreparePrinting
    void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo) override;  // 创建打印专用字体
    void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo) override;    // 释放字体
    void OnPrint(CDC* pDC, CPrintInfo* pInfo) override;    // 按页绘制
    afx_msg void OnFilePrintPreview();                     // 进入预览
    DECLARE_MESSAGE_MAP()
};
```

要点：`OnPreparePrinting` 里 `pInfo->SetMaxPage(总页数)`；`OnPrint` 用 `pInfo->m_nCurPage` 决定画第几页；**打印与屏幕共用一份绘制函数**（把绘制逻辑抽成 `DrawPage(CDC&, const CRect&, int page)`），这是本章的核心教学点；预览需要 `CView::OnFilePrintPreview` 与消息映射里的 `ON_COMMAND(ID_FILE_PRINT_PREVIEW, &CView::OnFilePrintPreview)`。

- [ ] **Step 3: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 19_printing 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 19_printing 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 4: 写新章 `docs/19-printing.md`**

固定小节：

1. `## 1. 打印为什么看起来复杂` —— 打印 = 在打印机 DC 上重放一遍绘制逻辑；难点在于**分页**（屏幕没有"页"的概念）与**坐标/字体差异**（打印机 DPI 远高于屏幕）；ASCII 图：`CPrintInfo` 串起 `OnPreparePrinting → OnBeginPrinting → OnPrint × N → OnEndPrinting`。
2. `## 2. 五个重写点` —— `OnPreparePrinting`（`DoPreparePrinting` 弹打印对话框、设页数）、`OnBeginPrinting`（建打印专用 `CFont`，别用屏幕字体）、`OnPrint`（画第 `m_nCurPage` 页）、`OnEndPrinting`（释放）、`OnDraw`（屏幕）。逐个给出签名与职责。
3. `## 3. 屏幕与打印共用绘制逻辑` —— 把绘制抽成 `DrawPage(CDC& dc, const CRect& rc, int page)`；`OnDraw` 调 `DrawPage(*pDC, client, 1)`，`OnPrint` 调 `DrawPage(*pDC, printableArea, pInfo->m_nCurPage)`；用 `dc.IsPrinting()` 判断当前是屏幕还是打印机以切换配色（屏幕用彩色、打印用黑白）。
4. `## 4. 分页计算` —— `pInfo->m_rectDraw` 是打印机可打印区域；`GetDeviceCaps(LOGPIXELSY)` 取打印机 DPI 算行高；每页能放几行 → 总页数 → `SetMaxPage`；`OnPrepareDC` 里设 `SetViewportOrg` 做分页偏移。
5. `## 5. 打印预览` —— `CView::OnFilePrintPreview` 一行进入预览（MFC 自带的 `CPreviewView` 会把打印机 DC 重定向到一个模拟 DC）；预览模式下 `OnPrint` 会被反复调用（每页一次 + 缩放重绘），所以 `OnPrint` 必须无副作用；`SetPreviewMode` 的 `AFX_ID_PREVIEW_*` 命令。
6. `## 6. 常见坑` —— ① 在 `OnPrint` 里做有副作用的操作（预览时被反复调用，数据被改多次）；② 用屏幕字体打印（打印机上字号完全不对）；③ `OnPreparePrinting` 忘记 `return DoPreparePrinting(pInfo)`（打印对话框不弹）；④ 不调 `SetMaxPage` 导致只打印一页；⑤ 预览没接 `ON_COMMAND(ID_FILE_PRINT_PREVIEW, ...)`（菜单点了没反应）。
7. `## 7. 实战建议` —— 先把 `DrawPage` 写纯（只读数据、只画），打印和预览就都免费了；页数在 `OnPreparePrinting` 里算，不要留到 `OnPrint` 里再算；`CFont` 在 `OnBeginPrinting` 建、`OnEndPrinting` 删，别在 `OnPrint` 里反复建。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 5: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/19-printing.md && grep -q "^## 自测" docs/19-printing.md && grep -q "examples/19_printing" docs/19-printing.md && echo "OK 骨架" || echo "MISS"
wc -l docs/18-gdi.md docs/19-printing.md
```

Expected: `OK 骨架`；`18-gdi.md` ≥160 行，`19-printing.md` ≥160 行。

- [ ] **Step 6: 接好上下章链接并提交**

`19-printing.md` 的「上一章」指向 `18-gdi.md`、「下一章」指向 `20-threads.md`；`18-gdi.md` 的「下一章」改为 `19-printing.md`；`20-threads.md` 的「上一章」改为 `19-printing.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 18 章扩写 + 新增第 19 章打印与打印预览 + 示例 19_printing

18 章补 GDI 对象所有权、双缓冲三种写法与 GDI 的适用边界；19 章讲透
五个打印重写点、屏幕与打印共用绘制逻辑、分页计算与 CPreviewView 预览。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 16: 第 20 章扩写（多线程与后台任务）

**Files:**
- Modify: `mfc/docs/20-threads.md`（144 → ~175 行）

- [ ] **Step 1: 扩写正文**

补开篇三行（对应示例 `examples/20_threads`）与收尾三节。正文补：

- `## N. CWinThread 与 AfxBeginThread` —— `AfxBeginThread` 的两个重载（工作者线程 `AFX_THREADPROC` vs 界面线程 `CRuntimeClass*`）；`CWinThread::m_bAutoDelete` 的含义与陷阱；工作者线程函数的签名 `UINT Func(LPVOID)` 与参数传递（用结构体 + 所有权约定）。
- `## N. 线程与 MFC 对象的边界` —— MFC 的"线程局部"对象（`CWnd` 句柄映射表、`CWinApp` 指针）只在创建它的线程有效；**跨线程访问 `CWnd` 是不安全的**（不是"慢"，是可能崩）；必须走 `PostMessage`/`SendMessage` 回到 UI 线程；`AfxGetApp()` 在工作线程里返回什么。
- `## N. 取消与进度回传的完整模式` —— `volatile BOOL m_cancel` + `PostMessage(WM_PROGRESS, n)` 的标准闭环；为什么用 `PostMessage` 而不是 `SendMessage`（前者不阻塞工作线程）；`PostMessage` 的参数不能传栈上指针（消息还在队列里对象已析构）。

常见坑补：① 工作线程里直接 `SetWindowText`（偶发崩溃或界面不刷新）；② `PostMessage` 传了栈上结构体指针（悬空读取）；③ `m_bAutoDelete = TRUE` 时又手动 `delete` 线程对象（双重释放）；④ 退出时不等工作线程结束（进程退出时线程还在跑，资源泄漏或崩溃）。

- [ ] **Step 2: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -3
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -3
wc -l docs/20-threads.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 21 / 失败 0`；`20-threads.md` ≥170 行。

- [ ] **Step 3: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 20 章扩写（CWinThread 与 AfxBeginThread、跨线程对象边界、取消与进度闭环）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 17: 第 21 章 + 新示例 `21_debugging`

**Files:**
- Create: `mfc/examples/21_debugging/main.cpp`、`resource.h`、`debug.rc`
- Create: `mfc/docs/21-debugging.md`（新章，~165 行）

- [ ] **Step 1: 写示例 `21_debugging`**

`resource.h`：`IDD_MAIN 101`、`IDC_TRACE 1001`、`IDC_THROW 1002`、`IDC_MEMCHECK 1003`、`IDC_RESULT 1004`、`IDR_MAINFRAME 128`。

`main.cpp` 四块：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <crtdbg.h>      // _CrtMemCheckpoint / _CrtMemDifference / _CrtDumpMemoryLeaks

// 1) 自定义异常：继承 CException
class CConfigException : public CException {
    DECLARE_DYNAMIC(CConfigException)
public:
    CConfigException(LPCTSTR what) : m_what(what) {}
    BOOL GetErrorMessage(LPTSTR buf, UINT max, PUINT pHelp = NULL) const override;
    CString m_what;
};
IMPLEMENT_DYNAMIC(CConfigException, CException)

// 2) MFC 异常宏 TRY/CATCH/AND_CATCH/END_CATCH 与 C++ try/catch 的对照
//    （MFC 异常类继承 CObject，可用 catch (CException* e) 捕获，但要自己 Delete()）
//    AfxThrowFileException / AfxThrowMemoryException 的现成抛出点

// 3) TRACE / ASSERT / VERIFY / ASSERT_VALID 的用法与差异
//    TRACE 只在 _DEBUG 下输出到调试器；VERIFY 在 release 下仍求值

// 4) 内存诊断：
//    _CrtMemState s1, s2, s3;
//    _CrtMemCheckpoint(&s1);
//    { /* 可疑代码：故意泄漏一块内存 */ }
//    _CrtMemCheckpoint(&s2);
//    if (_CrtMemDifference(&s3, &s1, &s2)) _CrtMemDumpStatistics(&s3);
```

要点：`GetErrorMessage` 必须实现（`CException` 的纯虚）；用 `TRY/CATCH` 宏捕获后**必须 `e->Delete()`**（MFC 异常是 `new` 出来的）；`_CrtMemDifference` 返回值非零表示有差异。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 21_debugging 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 21_debugging 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 3: 写新章 `docs/21-debugging.md`**

固定小节：

1. `## 1. MFC 的异常体系` —— `CException : CObject` 的继承树（`CMemoryException`/`CFileException`/`CArchiveException`/`CResourceException`/`CUserException`/`CNotSupportedException`）；为什么它继承 `CObject`（要能被 MFC 的宏体系管理）；`GetErrorMessage` 的职责；ASCII 图表示继承关系。
2. `## 2. TRY/CATCH 宏 vs C++ try/catch` —— 对照表：MFC 宏（`TRY`/`CATCH`/`AND_CATCH`/`END_CATCH`）与标准 `try`/`catch` 的语法与语义差异；**MFC 异常是堆对象，捕获后必须 `e->Delete()`**；C++ 异常可以直接 `catch`，但 `CException*` 仍需 `Delete`；混用时的 `AfxThrow*` 与 `throw` 的区别。
3. `## 3. 断言家族：ASSERT / VERIFY / ASSERT_VALID` —— 三者的语义与 release 行为对照表（`ASSERT` 在 release 下整个消失、`VERIFY` 保留表达式求值、`ASSERT_VALID` 调用 `AssertValid()`）；什么时候用哪个；`ASSERT` 在 release 版里被编译掉，所以**绝不能把有副作用的表达式放进 ASSERT**。
4. `## 4. 跟踪输出：TRACE 与 afxDump` —— `TRACE`/`TRACE0`~`TRACE3` 宏；输出只在 `_DEBUG` 下可见（用 DebugView 或 VS 输出窗口看）；`afxDump << obj` 的用法（`CObject::Dump`）；本书示例是 release 构建，所以 `TRACE` 看不到输出，正文要说明"想看 TRACE 得用 `/D_DEBUG /MDd` 重新构建"。
5. `## 5. 内存泄漏诊断` —— `_CrtMemCheckpoint` / `_CrtMemDifference` / `_CrtMemDumpStatistics` 三段式；`_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF)` 在程序退出时自动 dump 泄漏；`_CrtDumpMemoryLeaks`；**注意这些只在 `_DEBUG` 构建下有效**，release 下是空宏；示例里用 `#ifdef _DEBUG` 包起来并说明。
6. `## 6. 常见坑` —— ① 捕获 MFC 异常后忘记 `e->Delete()`（每次异常泄漏一个对象）；② 把有副作用的调用写进 `ASSERT`（release 下整个表达式消失，逻辑变了）；③ 在 release 构建里期待 `TRACE` 输出；④ `_CrtMemCheckpoint` 把静态/全局对象的初始化也算进去导致误报（要在 `main` 之后才 checkpoint）；⑤ 只捕获 `CException*` 而漏掉标准异常（`std::bad_alloc` 不是 `CException`）。
7. `## 7. 实战建议` —— 调试版（`/D_DEBUG /MDd`）与发布版（`/MD`）分开构建，前者开满断言与内存诊断；异常只在真正异常的情况下抛，不要拿异常做流程控制；`GetErrorMessage` 返回给用户看的文字，技术细节走日志。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/21-debugging.md && grep -q "^## 自测" docs/21-debugging.md && grep -q "examples/21_debugging" docs/21-debugging.md && echo "OK 骨架" || echo "MISS"
wc -l docs/21-debugging.md
```

Expected: `OK 骨架`，行数 ≥160。

- [ ] **Step 5: 接好上下章链接并提交**

`21-debugging.md` 的「上一章」指向 `20-threads.md`、「下一章」指向 `22-modern-drawing.md`；`20-threads.md` 的「下一章」改为 `21-debugging.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 21 章异常处理、调试与内存诊断 + 示例 21_debugging

CException 继承体系、TRY/CATCH 宏与标准异常对照、断言家族语义差异、
TRACE/afxDump、_CrtMemCheckpoint 三段式内存诊断。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 18: 第 22 章 + 新示例 `22_modern_drawing`

**Files:**
- Create: `mfc/examples/22_modern_drawing/main.cpp`、`resource.h`
- Create: `mfc/docs/22-modern-drawing.md`（新章，~165 行）

**Interfaces:**
- Consumes: `build.ps1` 的 `$extraLibsByExample['22_modern_drawing'] = @('gdiplus.lib','d2d1.lib','dwrite.lib')` 白名单（Task 1）。

- [ ] **Step 1: 写示例 `22_modern_drawing`**

`resource.h`：`IDR_MAINFRAME 128`、`IDC_TOGGLE 1001`。

`main.cpp` 要点：

```cpp
#include "resource.h"
#include <afxwin.h>
#include <gdiplus.h>
#include <d2d1.h>
#include <dwrite.h>
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "d2d1.lib")
#pragma comment(lib, "dwrite.lib")

class CDrawFrame : public CFrameWnd {
public:
    void DrawWithGdiplus(CDC& dc, const CRect& rc);   // 抗锯齿 + 渐变 + Alpha
    void DrawWithD2D(const CRect& rc);                // D2D + DWrite
    afx_msg void OnPaint();
    afx_msg BOOL OnEraseBkgnd(CDC*) { return TRUE; }
    afx_msg void OnSize(UINT, int, int);              // 重建 D2D 渲染目标
    afx_msg void OnToggle();                          // GDI+ / D2D 切换
    DECLARE_MESSAGE_MAP()
private:
    ID2D1HwndRenderTarget* m_rt = nullptr;
    ID2D1Factory*          m_d2dFactory = nullptr;
    IDWriteFactory*        m_dwFactory = nullptr;
    IDWriteTextFormat*     m_textFormat = nullptr;
    bool m_useD2D = true;
};

class CDrawApp : public CWinApp {
public:
    BOOL InitInstance() override {
        Gdiplus::GdiplusStartupInput gsi;
        Gdiplus::GdiplusStartup(&m_gdiplusToken, &gsi, NULL);   // GDI+ 启动
        ...
    }
    int ExitInstance() override { Gdiplus::GdiplusShutdown(m_gdiplusToken); ... }
private:
    ULONG_PTR m_gdiplusToken = 0;
};
```

要点：GDI+ 侧用 `Graphics g(dc.GetSafeHdc())` + `SetSmoothingMode(SmoothingModeAntiAlias)` + `LinearGradientBrush`；D2D 侧 `D2D1CreateFactory` → `CreateHwndRenderTarget` → `BeginDraw`/`Clear`/`DrawEllipse`/`FillEllipse`/`EndDraw`，文字用 `DWriteCreateFactory` + `CreateTextFormat` + `DrawText`；`OnSize` 里 `m_rt->Resize(D2D1::SizeU(cx, cy))`。

- [ ] **Step 2: 构建并冒烟**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -File 22_modern_drawing 2>&1 | tail -8
pwsh -NoProfile -File smoke.ps1 -Name 22_modern_drawing 2>&1 | tail -5
```

Expected: `[OK]` 且 `[ALIVE]`。

- [ ] **Step 3: 写新章 `docs/22-modern-drawing.md`**

固定小节：

1. `## 1. GDI 的天花板` —— GDI 不支持抗锯齿、Alpha 混合、硬件加速；三条现代路线对照表：GDI+（托管式 C++ 封装，软件渲染为主，抗锯齿够用）/ Direct2D（GPU 加速，工业级）/ Direct3D（3D，超出本书范围）；选型判据。
2. `## 2. GDI+ 与 MFC 共存` —— `GdiplusStartup`/`GdiplusShutdown` 必须在 `InitInstance`/`ExitInstance` 配对；`Graphics` 从 `CDC` 的 HDC 构造；**GDI+ 的 `Color` 与 GDI 的 `COLORREF` 不同源**（`Color(255, r, g, b)` vs `RGB(r,g,b)`）；`SmoothingModeAntiAlias` 的效果对比。
3. `## 3. 抗锯齿、渐变与 Alpha` —— `LinearGradientBrush`/`PathGradientBrush` 的构造与 `FillRectangle`；`Color` 的 alpha 通道与半透明叠加；给出"圆角卡片 + 渐变背景 + 半透明高光"的完整绘制函数（这是现代 UI 视觉的基础积木）。
4. `## 4. Direct2D 渲染进 HWND` —— 四步管线：`D2D1CreateFactory` → `CreateHwndRenderTarget`（绑定 HWND + 像素尺寸）→ `BeginDraw`/绘制/`EndDraw` → `Resize`；`EndDraw` 返回 `D2DERR_RECREATE_TARGET` 时必须重建渲染目标（设备丢失）；资源创建顺序与释放顺序相反。
5. `## 5. DirectWrite 文字` —— `DWriteCreateFactory` → `CreateTextFormat(字体名, 字号, 粗细, 风格, 拉伸, 区域)` → `DrawText`；`IDWriteTextLayout` 做精细排版（超出本书范围，只提一句）；DWrite 的文字质量与 GDI `DrawText` 的对比。
6. `## 6. 常见坑` —— ① `GdiplusStartup` 没调用就 `new Graphics`（静默失败，什么都不画）；② 忘 `GdiplusShutdown`（退出时资源未释放）；③ D2D 的 `EndDraw` 返回 `D2DERR_RECREATE_TARGET` 不处理（切显示器/休眠恢复后画面黑掉）；④ 渲染目标没随 `OnSize` 重建（画面拉伸变形）；⑤ 混用 GDI 与 D2D 画同一个区域（互相覆盖）；⑥ 忘记在 `build.ps1` 白名单里加 `d2d1.lib` 等（未解析外部符号）。
7. `## 7. 实战建议` —— 只在需要抗锯齿/透明时才上 GDI+，纯线条表格用 GDI 更快；D2D 渲染目标的重建逻辑抽成一个 `EnsureRenderTarget()` 函数；GDI+ 的 `Graphics` 对象不要跨帧持有。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/22-modern-drawing.md && grep -q "^## 自测" docs/22-modern-drawing.md && grep -q "examples/22_modern_drawing" docs/22-modern-drawing.md && echo "OK 骨架" || echo "MISS"
wc -l docs/22-modern-drawing.md
```

Expected: `OK 骨架`，行数 ≥160。

- [ ] **Step 5: 接好上下章链接并提交**

`22-modern-drawing.md` 的「上一章」指向 `21-debugging.md`、「下一章」指向 `23-deployment.md`；`21-debugging.md` 的「下一章」改为 `22-modern-drawing.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 22 章 GDI+ 与 Direct2D + 示例 22_modern_drawing

GdiplusStartup 与 MFC 共存、抗锯齿与 Alpha 渐变、D2D 四步管线与设备丢失
重建、DirectWrite 文字；与第 18 章 GDI 版对照。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 19: 第 23 章（部署：静态/动态链接与打包）

**Files:**
- Create: `mfc/docs/23-deployment.md`（新章，~160 行）
- 不新增示例目录；复用 `mfc/examples/25_notepad_plus/`

**Interfaces:**
- Consumes: `build.ps1 -Static`（Task 1）、`examples/25_notepad_plus/`（Task 1 重命名）。
- Produces: 实测体积数据，写进正文。

- [ ] **Step 1: 实测两套构建的体积与依赖**

```bash
cd /g/code/guide/mfc
pwsh -NoProfile -File build.ps1 -File 25_notepad_plus 2>&1 | tail -3
pwsh -NoProfile -File build.ps1 -File 25_notepad_plus -Static 2>&1 | tail -3
ls -la build/25_notepad_plus.exe build/25_notepad_plus_static.exe
```

记录两个字节数，写进正文（正文里要出现这两个真实数字，不要写"约 26KB / 约 2.5MB"这类模糊说法）。

- [ ] **Step 2: 用 dumpbin 列出动态版的外部依赖**

```bash
cd /g/code/guide/mfc && cmd //c "\"G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat\" >nul && dumpbin /dependents build\25_notepad_plus.exe"
```

Expected: 输出里能看到 `mfc140u.dll`、`MSVCP140.dll`、`VCRUNTIME140.dll`、`KERNEL32.dll`、`USER32.dll` 等。把这份依赖列表整理成正文里的表格。再对静态版跑一次，Expected: 只剩系统 DLL（`KERNEL32.dll`/`USER32.dll`/`GDI32.dll` 等），没有 `mfc140u.dll`。

- [ ] **Step 3: 冒烟两套产物**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File smoke.ps1 -Name 25_notepad_plus 2>&1 | tail -5
```

Expected: `[Done] 存活 2 / 失败 0`（`-Name` 前缀匹配会同时命中动态与静态两个 exe）。

- [ ] **Step 4: 写新章 `docs/23-deployment.md`**

开篇三行里「对应示例」写：`> 对应示例：本章不新增示例工程，直接复用 `examples/25_notepad_plus`，用 `build.ps1 -Static` 产出第二套构建做对比。`

固定小节：

1. `## 1. 两种链接方式` —— 动态（`/D_AFXDLL /MD`，exe 小、依赖 `mfc140u.dll` + VC 运行库）vs 静态（`/MT`，exe 大、零依赖）对照表；MFC 的四种组合（动态/静态 × Debug/Release）与对应的库名（`mfc140u.dll` / `mfc140u.lib` / `mfc140ud.dll` / `mfc140ud.lib`）；ASCII 图表示"你的 exe 依赖了谁"。
2. `## 2. 实测：同一份代码的两种体积` —— 直接引用 Step 1 测出的真实字节数与 Step 2 的 `dumpbin /dependents` 结果表；解释体积差从哪来（静态链接把用到的 MFC 模块与 CRT 全部塞进 exe）；给出选型建议（内部工具/便携绿色版选静态，正常分发选动态）。
3. `## 3. 动态链接的部署清单` —— 需要随程序分发的 DLL：`mfc140u.dll`、`msvcp140.dll`、`vcruntime140.dll`、`vcruntime140_1.dll`；VC 运行库的三种分发方式（`vc_redist.x64.exe`、应用本地部署 `app-local`、静态链接）；"开发机跑得好好的，拷到别人机器就报缺少 DLL"的成因与排查。
4. `## 4. 清单文件：DPI 与视觉样式` —— 外部清单 `<exe名>.exe.manifest` 或编译进资源；两个关键声明：`dpiAware`/`dpiAwareness`（第 14 章讲过 API 方式，清单更可靠）与 `Microsoft.Windows.Common-Controls` 6.0（启用视觉样式，否则控件是 Windows 95 外观）；`/MANIFESTUAC` 的 `level` 设置与"以管理员身份运行"。
5. `## 5. 打包与分发` —— 一个最小发布目录应该有什么（exe + 依赖 DLL + 资源文件 + 清单）；用 `dumpbin /dependents` 自查依赖；为什么不要依赖"目标机器上装了 VS"；ZIP 绿色分发 vs 安装包（本书不实操安装包制作，只讲原理与清单）。
6. `## 6. 常见坑` —— ① 静态链接时忘了改 `/MT`（`/D_AFXDLL` 与 `/MT` 混用报运行时库冲突）；② 动态版只拷了 exe 没拷 `mfc140u.dll`；③ 清单里的 `Common-Controls` 版本写成 5.x（视觉样式不生效）；④ 静态版体积暴涨误以为是 bug；⑤ Debug 版（`/MDd`）拷到没装 VS 的机器上（依赖 `mfc140ud.dll` 与调试 CRT，根本不该分发）。
7. `## 7. 实战建议` —— 内部工具用静态链接省事，对外分发用动态链接省空间；用 `dumpbin /dependents` 在交付前自查依赖；清单文件从项目一开始就加上（后期补容易漏）。
8. `## 8. 自测` —— 4 题。

- [ ] **Step 5: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/23-deployment.md && grep -q "^## 自测" docs/23-deployment.md && grep -q "25_notepad_plus" docs/23-deployment.md && echo "OK 骨架" || echo "MISS"
grep -c "dumpbin" docs/23-deployment.md
wc -l docs/23-deployment.md
```

Expected: `OK 骨架`；`dumpbin` 出现 ≥2 次；行数 ≥160。

- [ ] **Step 6: 接好上下章链接、清理静态产物、提交**

`23-deployment.md` 的「上一章」指向 `22-modern-drawing.md`、「下一章」指向 `24-modern-cpp.md`；`22-modern-drawing.md` 的「下一章」改为 `23-deployment.md`。

```bash
cd /g/code/guide/mfc && rm -f build/*_static.exe && rm -rf build/obj/*_static*
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 23 章部署：静态/动态链接与打包

用 25_notepad_plus 同源两套构建实测体积与依赖差异（dumpbin /dependents），
讲清 VC 运行库分发、清单文件（DPI 与 Common-Controls 6.0）与打包清单。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 20: 第 24 章（MFC 与现代 C++）

**Files:**
- Create: `mfc/docs/24-modern-cpp.md`（新章，~160 行）
- 不新增示例目录；复用并对照 `mfc/examples/13_shell_integration/`

**Interfaces:**
- Consumes: `examples/13_shell_integration/main.cpp`（Task 10 刻意保留的"裸句柄"写法，作为改造前对照）。

- [ ] **Step 1: 写新章 `docs/24-modern-cpp.md`**

开篇三行里「对应示例」写：`> 对应示例：本章不新增示例工程，直接对照 `examples/13_shell_integration` 的源码，逐处给出"现代 C++ 改写版"。`

固定小节（每节都是「改造前 → 改造后」的成对代码）：

1. `## 1. 为什么 MFC 代码容易"不现代"` —— MFC 诞生于 C++98 之前，它的惯用法（裸 `new`/`delete`、`LPCTSTR`、`CString`、异常宏）在那个年代是合理的；今天的目标不是抛弃 MFC，而是**在 MFC 边界上使用现代 C++**。
2. `## 2. RAII 包装裸句柄` —— 对照 `13_shell_integration` 里的 `HANDLE h = CreateMutex(...); ... CloseHandle(h);`（任何提前 return 都泄漏）→ 用 `std::unique_ptr<void, decltype(&::CloseHandle)>` 或自定义 deleter 包装；给出完整对照代码与"异常路径也安全"的说明；`CFile`/`CDC` 这类 MFC 类本身已是 RAII，不需要再包。
3. `## 3. 智能指针与 MFC 对象所有权` —— `CWnd*` 的所有权归属（`CFrameWnd` 由框架管、对话框由谁 `new` 谁管）；`std::unique_ptr<CDialog>` 管理非模态对话框（配合 `PostNcDestroy` 的 `delete this` 惯用法要二选一，不能都做）；`std::shared_ptr` 在 MFC 里几乎不需要（文档对象归文档所有）。
4. `## 4. CString 与 std::wstring 的边界` —— 对照表（`CString` 的 `Format`/`Mid`/`Left`/`Trim` vs `std::wstring` + `std::format`/`substr`）；转换方式（`CString` 可直接取 `GetString()` 给 `std::wstring_view`）；建议：**MFC 边界内用 `CString`，纯逻辑层用 `std::wstring`**，转换只发生在边界；`_T()`/`TCHAR` 在 Unicode-only 时代的简化（直接用 `L""` 与 `wchar_t`）。
5. `## 5. C++20 能带进来什么` —— `std::format` 与 `CString::Format` 的对照（类型安全、不用记 `%d`/`%s`）；`std::span` 传缓冲区；`constexpr` 与 `std::array` 替代手写常量表；`std::string_view`/`std::wstring_view` 做只读参数；`/std:c++20` 已是本书构建默认（`build.ps1` 里就有）。
6. `## 6. 异常：两套体系怎么共存` —— MFC 的 `CException*`（堆对象、要 `Delete`）与标准异常（栈对象、`catch` 引用）；`AfxThrowFileException` 抛出的是 `CException*`；建议：**新代码抛标准异常，MFC 边界处捕获 `CException*` 并转成标准异常**；给出转换函数。
7. `## 7. 迁移策略` —— 不要"重写"；按「新增代码用现代 C++ → 边界处加 RAII 包装 → 逐文件把裸资源换成 RAII → 最后才考虑 `CString` 降级」的顺序渐进；每次改动都要能编译能跑（本书的 `build.ps1` + `smoke.ps1` 就是安全网）。
8. `## 8. 常见坑` —— ① 给 MFC 对象套 `unique_ptr` 而 MFC 自己也会 `delete`（双重释放）；② 用 `std::shared_ptr<CWnd>` 管理窗口（生命周期与窗口句柄脱节）；③ 在 MFC 边界外继续用 `CString`（逻辑层被 MFC 绑死，没法单测）；④ `std::format` 的格式串与 `CString::Format` 语法不同（`{}` vs `%d`）混用；⑤ `_T("")` 与 `L""` 混用导致字符类型不一致。
9. `## 9. 实战建议` —— 逻辑层（纯计算、解析、序列化）写成不依赖 MFC 的普通 C++，可以脱离界面单测；MFC 边界处用 RAII 包装把裸资源管起来；`build.ps1` 的 `/std:c++20` 已经在位，不需要额外配置。
10. `## 10. 自测` —— 4 题。

- [ ] **Step 2: 验证**

```bash
cd /g/code/guide/mfc && grep -q "本章你将学会" docs/24-modern-cpp.md && grep -q "^## 自测" docs/24-modern-cpp.md && grep -q "13_shell_integration" docs/24-modern-cpp.md && echo "OK 骨架" || echo "MISS"
grep -c "unique_ptr" docs/24-modern-cpp.md
wc -l docs/24-modern-cpp.md
```

Expected: `OK 骨架`；`unique_ptr` 出现 ≥3 次；行数 ≥160。

- [ ] **Step 3: 接好上下章链接并提交**

`24-modern-cpp.md` 的「上一章」指向 `23-deployment.md`、「下一章」指向 `25-notepad-plus.md`；`23-deployment.md` 的「下一章」改为 `24-modern-cpp.md`；`25-notepad-plus.md` 的「上一章」改为 `24-modern-cpp.md`。

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 新增第 24 章 MFC 与现代 C++

对照 13_shell_integration 源码给出 RAII 包装裸句柄、智能指针与 MFC 对象
所有权、CString/std::wstring 边界、C++20 特性引入、两套异常体系共存与
渐进迁移策略。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 21: 第 25 章扩写（实战项目：记事本+）

**Files:**
- Modify: `mfc/docs/25-notepad-plus.md`（182 → ~240 行）
- Modify: `mfc/examples/25_notepad_plus/main.cpp` —— **仅当正文新增的小节需要引用示例中尚不存在的代码时才改**；本章以讲清现有 652 行源码为主，优先不改代码。若确实改了，必须重跑 `build.ps1 -File 25_notepad_plus` 与 `-Static` 两套构建，并在 Task 19 的正文里同步更新体积数字。

- [ ] **Step 1: 扩写正文**

补开篇三行（对应示例 `examples/25_notepad_plus`）与收尾三节。正文补：

- `## N. 项目结构与模块划分` —— 现有 `main.cpp` / `stats.cpp` / `stats.h` / `notepad.rc` / `resource.h` / `toolbar.bmp` 的职责表；为什么把统计逻辑拆到 `stats.cpp`（对应第 24 章"逻辑层不依赖 MFC"的主张，`stats.cpp` 里是纯 C++）。
- `## N. 全书知识点索引` —— 一张大表，列出「功能 → 用到的章节」：菜单/工具栏/状态栏（11）、文件对话框与编码（10）、控件（07）、通用对话框（10）、Doc/View（15）、序列化（17）、GDI 绘图（18）、线程与后台统计（20）、配置持久化（13）、DPI（14）、部署（23）。这张表是全书收束的核心。
- `## N. 还能怎么继续做` —— 5 个可选的下一步扩展方向（多标签页、语法高亮、正则查找替换、编码自动探测、打印），每个指向对应章节。

常见坑补：① 工具栏位图与按钮 ID 不匹配（按钮图标错位）；② 统计线程直接更新状态栏（第 20 章的坑在这里的具体表现）；③ `.rc` 里 Doc/View 的 9 字段串字段数错（打开/保存对话框过滤器和扩展名错位）。

- [ ] **Step 2: 收口三步**

```bash
cd /g/code/guide/mfc && pwsh -NoProfile -File build.ps1 -All 2>&1 | tail -5
pwsh -NoProfile -File smoke.ps1 2>&1 | tail -5
wc -l docs/25-notepad-plus.md
```

Expected: 构建全 `[OK]`；冒烟 `存活 23 / 失败 0`；`25-notepad-plus.md` ≥230 行。

- [ ] **Step 3: 提交**

```bash
cd /g/code/guide && git add -A mfc && git commit -q -F - <<'EOF'
docs(mfc): 第 25 章实战项目扩写（模块划分、全书知识点索引、扩展方向）

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
```

---

## Task 22: 终稿（README、根 README、交叉引用终检、记忆更新）

**Files:**
- Modify: `mfc/README.md`（全量重写）
- Modify: `README.md`（根仓库的 mfc 条目）
- Modify: `G:\xulun\.claude\projects\G--code-guide\memory\mfc-tutorial-build.md`（更新记忆）

- [ ] **Step 1: 全量重写 `mfc/README.md`**

按新结构改写：25 章 / 23 示例目录 / 章号=示例号。必含：

- 开篇一句话说明（25 章正文 + 23 个可编译示例 + 1 个实战项目）
- 快速开始（`build.ps1 -All` / `-File` / `-Clean` / `-Static`，以及 `smoke.ps1`）
- 目录结构树（docs 25 个文件 + examples 23 个目录，每个一行注释）
- 学习路线（六篇分组）
- 工具链表格（VS 18 Community / MSVC 14.51.36231 / SDK 10.0.26100.0 / MFC 动态 `_AFXDLL`）
- 验证状态节：说明 23 个示例全部 `cl` 编译 + `rc` 编资源 + 链接通过，全部通过 3 秒启动冒烟；第 23 章的静态/动态体积实测数据

- [ ] **Step 2: 更新根 `README.md` 的 mfc 条目**

把现有的一行：

```
- [mfc](./mfc) — MFC 桌面应用开发指南，使用 MSVC + MFC 库编译验证
```

改写为与 wpf/win32 条目同等详略的一段（说明章数、示例数、覆盖专题、验证方式、实测亮点），并在末尾指回 `mfc/README.md` 的验证状态节。

- [ ] **Step 3: 全文交叉引用终检**

```bash
cd /g/code/guide/mfc
# 1) 每章的「对应示例」路径必须真实存在
for f in docs/*.md; do n=$(basename "$f" | cut -c1-2); if [ "$n" = "23" ] || [ "$n" = "24" ]; then continue; fi; grep -o "examples/[0-9][0-9]_[a-z_]*" "$f" | head -1 | while read d; do [ -d "$d" ] || echo "MISSING $f -> $d"; done; done
# 2) 上下章链接目标文件必须存在
grep -oh "](\([0-9][0-9]-[a-z-]*\.md\))" docs/*.md | tr -d '](' | sort -u | while read t; do [ -f "docs/$t" ] || echo "BROKEN LINK $t"; done
# 3) 不应再有旧章号/旧目录名残留
grep -rn "examples/0[2-9]_\|examples/1[0-2]_\|docs/0[89]-\|docs/1[0-3]-" docs/ README.md
```

Expected: 三段都无输出（第 3 段允许 `docs/1[0-3]-` 的合法新名如 `10-common-dialogs.md` 被排除，如误报则按实际文件名调整正则）。

- [ ] **Step 4: 统计最终规模**

```bash
cd /g/code/guide/mfc && echo "章数: $(ls docs/*.md | wc -l)" && echo "示例目录数: $(ls -d examples/*/ | wc -l)" && echo "正文总行数: $(cat docs/*.md | wc -l)" && wc -l docs/*.md
```

Expected: 章数 25，示例目录数 23，正文总行数 4000~4200。若有章节 <160 行，回到对应任务补写。

- [ ] **Step 5: 更新记忆**

改写 `G:\xulun\.claude\projects\G--code-guide\memory\mfc-tutorial-build.md`，记录：25 章 / 23 示例结构；章号=示例号；`build.ps1 -Static` 与 `smoke.ps1`；实测的静态/动态体积（26 KB vs 2.5 MB）；本批新踩的 MFC 坑（`CTaskDialog` 无默认构造且在 `afxtaskdialog.h`；`COleDropTarget::OnDrop` 返回 `BOOL` 导致 C2555；拖放需 `AfxOleInit`；`DWMWA_USE_IMMERSIVE_DARK_MODE` 旧 SDK 需自己 `#define`）。同步更新 `MEMORY.md` 里对应那一行的摘要。

- [ ] **Step 6: 提交**

```bash
cd /g/code/guide && git add -A mfc README.md && git commit -q -F - <<'EOF'
docs(mfc): 终稿——README 全量重写、根 README 条目扩写、交叉引用终检

25 章 / 23 示例目录，正文约 4000+ 行；补齐验证状态与静态/动态构建实测。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git log --oneline -10
```

---

## 附：明确不做（出界清单）

来自 spec 第 10 节，实施时不要顺手加进来：ATL/WRL 全面教程、ActiveX 控件容器与 OLE 服务器实现、MFC Feature Pack 的 Ribbon/可停靠窗格专题（08、11 章顺带提及即可）、安装包制作实操（23 章只讲原理）、Windows 服务/驱动/内核/钩子（属 win32 教程范围）、多显示器完整专题（14 章只覆盖按监视器 DPI 缩放的实用部分）。

## 附：任务依赖与执行顺序

- Task 1 是所有后续任务的前置（重命名 + 脚本改造），必须第一个完成。
- Task 10（`13_shell_integration`）必须先于 Task 20（第 24 章重构它）。
- Task 1（重命名 `25_notepad_plus`）必须先于 Task 19（第 23 章用它的源码实测）。
- Task 21（第 25 章扩写）与 Task 19（第 23 章）无强依赖，但若 Task 19 先做完而 Task 21 之后又改了 `25_notepad_plus/main.cpp`，需在 Task 21 的收口步骤里重跑一次 `build.ps1 -File 25_notepad_plus -Static` 确认第 23 章引用的体积数据仍成立。
- 其余任务相互独立，可按顺序执行，也可在 Task 1 完成后并行分发。
