# 04 · 资源文件入门

> 对应示例：`examples/04_resources`

> **本章你将学会**：资源如何从 `.rc` 编译进 exe、ID 该怎么编号才不打架、字符串表为什么是本地化的地基、图标的多档尺寸怎么处理，以及菜单 / 工具栏 / 加速键共用同一个命令 ID 的红利。
> **前置知识**：第 03 章的命令消息与 `ON_COMMAND`。

## 1. 资源是什么

资源是**编译进 exe 的数据块**：菜单、对话框模板、图标、位图、字符串表、加速键表、版本信息……真实 MFC 工程（VS 向导生成的）几乎都把界面元素放在 `.rc` 资源里，而不是代码里手工拼。好处：

- exe 双击即完整，不依赖外部文件
- 界面文案集中在一处，本地化时只翻译 .rc
- VS 的资源编辑器可以可视化拖拽（本教程用文本编辑 .rc，原理相同）

## 2. 资源的编译链路

```text
resource.h ──┬── main.cpp（C++ 代码用 ID 访问资源）
             └── demo.rc ──rc.exe──> demo.res ──link──> 嵌进 exe
```

- `resource.h` 是**两边共用的 ID 定义**，用 `#define` 数值（rc.exe 不认 C++ 的 enum）
- `rc.exe` 把 .rc 编译成 .res，链接器把它并进 exe
- 运行时用 `LoadMenu` / `LoadString` / `FindResource` 等 API 按 ID 取出

## 3. 资源 ID 的组织惯例

ID 前缀不是装饰，它标明了资源的**类型**，也决定了你能用哪个 API 去取它：

| 前缀 | 含义 | 取它的 API | 示例 |
|---|---|---|---|
| `IDR_` | 独立资源块（菜单/加速键/图标/工具栏） | `LoadMenu` / `LoadAccelerators` / `LoadIcon` | `IDR_MAINFRAME` |
| `IDD_` | 对话框模板 | `CDialog::Create` / `DoModal` | `IDD_LOGIN` |
| `IDC_` | 控件 ID（也用于光标） | `GetDlgItem` / `DDX_Control` | `IDC_USER` |
| `IDM_` | 菜单命令 ID | `ON_COMMAND` | `IDM_FILE_NEW` |
| `IDI_` | 图标（单独使用时） | `LoadIcon` | `IDI_APP` |
| `IDS_` | 字符串表条目 | `CString::LoadString` | `IDS_APP_TITLE` |

比前缀更重要的是**数值区间的划分**。ID 全是 32 位整数，如果菜单命令和控件 ID 混在同一个区段里，早晚会撞——而撞了的症状往往是"点了没反应"或"改错了控件"，很难查。按类别留出间隔：

| 区段 | 用途 | 说明 |
|---|---|---|
| 100 ~ 199 | 资源块（菜单、加速键、图标） | 每个程序十来个，够用 |
| 1000 ~ 1999 | 控件 ID | 对话框里的控件都在这儿 |
| 2000 ~ 2999 | 菜单 / 工具栏命令 | 本教程示例用这一段 |
| 3000 ~ 3999 | 字符串表 | |
| 32771 起 | 用户命令（VS 向导默认） | AppWizard 的 `_APS_NEXT_COMMAND_VALUE` 起点 |
| `WM_APP + n` | 自定义消息 | 见第 03 章 |

示例 `04_resources/resource.h` 就是按这个思路编号的：

```cpp
#define IDR_MAINFRAME       100   // 主图标（一个 .ico 里含 32×32 与 16×16 两档）
#define IDR_MAIN_MENU       101   // 主菜单
#define IDR_MAIN_ACCEL      102   // 加速键表

#define IDM_FILE_NEW        2001  // 菜单命令 ID
#define IDM_FILE_OPEN       2002
...
#define IDS_APP_TITLE       3001  // 字符串表
#define IDS_GREETING        3002
```

**VS 向导自己的编号习惯**：命令从 32771 起（`ID_FILE_NEW` 这类标准命令则用 `0xE100` 以上的 MFC 保留区）。你用哪套都行，**关键是选定之后不要越界**。

## 4. 资源脚本 .rc 的语法

`.rc` 文件结构类似 C，支持 `//` 注释和 `#include`。本教程所有 .rc 用 UTF-8 保存，文件头声明代码页与语言：

```rc
#pragma code_page(65001)    // 告诉 rc.exe 按 UTF-8 解析
#include "resource.h"
#include "afxres.h"         // MFC 标准资源 ID（ID_FILE_OPEN 等）和类型宏
LANGUAGE LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED
```

`LANGUAGE` 声明**其后所有资源**的语言归属，为将来加多语言版留路（第 6 节）。

### 4.1 菜单

```rc
IDR_MAIN_MENU MENU
BEGIN
    POPUP "文件(&F)"                       // &F = Alt+F 加速字母
    BEGIN
        MENUITEM "新建(&N)\tCtrl+N",    IDM_FILE_NEW
        MENUITEM SEPARATOR              // 分隔条
        MENUITEM "退出(&X)",            IDM_FILE_EXIT
    END
END
```

- `\tCtrl+N` 是显示的快捷键提示，真正生效要配加速键表
- 菜单项的 ID 就是命令 ID，点击产生 `WM_COMMAND`
- `&` 后面那个字母是 **Alt 助记键**（`Alt+F` 打开"文件"菜单），与 `\t` 后面的加速键是两回事

### 4.2 加速键表

```rc
IDR_MAIN_ACCEL ACCELERATORS
BEGIN
    "N", IDM_FILE_NEW,  VIRTKEY, CONTROL
    "O", IDM_FILE_OPEN, VIRTKEY, CONTROL
END
```

把组合键翻译成命令 ID。`InitInstance` 里 `::LoadAccelerators` 加载，然后在 `CWinApp::PreTranslateMessage` 里交给 `::TranslateAccelerator` 分发——翻译成命令就返回 `TRUE`，别再往下传（完整代码见示例 `main.cpp`）。

注意：**Doc/View 框架（第 15 章）不用这么写**，`CFrameWnd::LoadFrame` 会按同一个 `nIDResource` 自动加载菜单、加速键表、图标和标题字符串——这正是那个 ID 叫 `IDR_MAINFRAME` 的原因。

### 4.3 字符串表

```rc
STRINGTABLE
BEGIN
    IDS_APP_TITLE "MFC 资源示例"
    IDS_GREETING  "这段文字来自字符串表资源。"
END
```

取用就一句 `CString s; s.LoadString(IDS_GREETING);`。每条字符串不超过 4095 字符，且**一条就是一行**——不能跨行。

### 4.4 把菜单挂到框架窗口

`Create` 的第 6 个参数就是菜单资源名，传 `MAKEINTRESOURCE(IDR_MAIN_MENU)` 即可。之后点菜单 → `WM_COMMAND(IDM_XXX)` → `ON_COMMAND` 分发，一条链路。

## 5. 命令 ID 的复用：菜单 = 工具栏 = 加速键

一个命令 ID（比如 `IDM_FILE_SAVE`）可以同时出现在菜单、工具栏、加速键表里，三处触发都会路由到同一个 `ON_COMMAND` 处理函数。`ON_UPDATE_COMMAND_UI` 也对三者统一生效——菜单变灰时工具栏按钮同步变灰。这是 MFC 命令系统的核心红利，第 11 章展开。

## 6. 字符串表与国际化

把界面文案从代码里搬到 `STRINGTABLE`，是本地化的第一步，也是最省事的一步。之后要支持多语言，有两条路：

**路线一：一个 .rc，多个 `LANGUAGE` 块。** 在字符串表前各写一行 `LANGUAGE LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED` / `LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US`，加载时 Windows 按当前线程语言挑对应块。问题是**菜单这类资源没法这么办**——菜单在窗口创建时就挂上去了，只有 `FindResourceEx` 这种带语言参数的 API 才能按语言取。所以这条路只适合字符串表。

**路线二：每种语言一个卫星 DLL（推荐）。** 把每种语言的 `.rc` 单独编译成 DLL（约定名 `<exe名><语言码>.dll`，如 `MyAppCHS.dll`），启动时按用户语言加载并切换资源句柄：

```cpp
// InitInstance 里，创建窗口之前
HINSTANCE hRes = ::LoadLibrary(_T("MyAppCHS.dll"));
if (hRes) AfxSetResourceHandle(hRes);   // 之后所有资源查找都走这个 DLL
```

`AfxSetResourceHandle` 一换，`LoadString`、`LoadMenu`、`CreateDialog` 全部改从这个 DLL 取资源，代码里一行判断都不用加。这是 MFC 官方推荐的本地化方案。

**本书的做法**：只用简体中文，但每个 `.rc` 开头都写一行 `LANGUAGE` 声明清楚语言归属。以后要加英文版，把同一个 .rc 复制一份改 `LANGUAGE` 和文案即可，不用回头补。

## 7. 图标的正确做法

图标是资源里唯一带"尺寸"概念的。`.ico` 格式本身支持在**一个文件里打包多档尺寸**（16×16、32×32、48×48、256×256）。示例的 `app.ico` 就装了 32×32 与 16×16 两档：

```rc
IDR_MAINFRAME ICON "app.ico"
```

```cpp
HICON hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
SetIcon(hIcon, TRUE);    // 大图标：任务栏、Alt+Tab 切换器
SetIcon(hIcon, FALSE);   // 小图标：标题栏左上角
```

`CWnd::SetIcon(HICON, BOOL bBigIcon)` 内部就是发 `WM_SETICON`，`bBigIcon` 决定填 `ICON_BIG` 还是 `ICON_SMALL` 槽位。**你不需要自己挑尺寸**——`LoadIcon` 拿到的是整个图标组，Windows 按槽位从 .ico 里选合适的那一档。

三个容易忽略的点：

1. **两行 `SetIcon` 都要写**。只设大图标，标题栏左上角会是 Windows 的默认图标；只设小图标，任务栏和 Alt+Tab 是默认图标——两处用的不是同一档
2. **想要一个确定的尺寸**，用 `LoadImage(实例, 资源名, IMAGE_ICON, cx, cy, LR_DEFAULTCOLOR)` 显式指定。做工具栏图标、列表视图图像时用得上（第 08 章）
3. **`SetClassLongPtr(hwnd, GCLP_HICON, …)` / `GCLP_HICONSM`** 设的是"窗口类"的图标，影响该类所有窗口，也决定任务栏分组图标。日常用 `SetIcon` 就够了，需要让同类窗口（比如所有非模态对话框）共享图标时才用它

**Doc/View 框架下不用写这些**——`CFrameWnd::LoadFrame` 会按 `nIDResource` 自动 `LoadIcon` 并调用 `SetIcon`。这也是为什么向导生成的 `IDR_MAINFRAME` 既是菜单名、加速键名，又是图标名。

## 常见坑

1. **rc 编译报 RC2135**
   九成是语法问题——字符串没放进 `STRINGTABLE`/`BEGIN...END`、少引号、ID 没定义。rc 的报错行号经常滞后，检查报错行的**上一行**。

2. **中文乱码 / 编译失败**
   `.rc` 存成 UTF-8 时必须**两处都写**：文件里 `#pragma code_page(65001)`，命令行 `rc /c65001`。少任何一处，rc.exe 都会按系统 ANSI 代码页（简中机器上是 GBK）去解 UTF-8 字节，中文变乱码或直接语法错误。本仓库的 `build.ps1` 已经带了 `/c65001`，所以示例只要在 .rc 开头写 `#pragma` 就行。

3. **同一个 ID 定义了两次**
   `resource.h` 里改了一处、忘了另一处，或者 .rc 里又写了一遍 `#define`。rc.exe **不报错，静默取后一个值**——于是代码用一个 ID 去 `LoadString`，资源却挂在另一个 ID 下，运行时拿不到东西。改 ID 时用编辑器的"查找全部引用"。

4. **图标文件不是真的 `.ico`**
   把 `.bmp` 改名成 `.ico` 是最常见的自欺欺人，rc.exe 会报 **RC2175（invalid icon file）**。`.ico` 有自己的容器格式（`ICONDIR` 头 + 各尺寸条目），必须用图标编辑器或转换工具生成。

5. **改了资源但 exe 没变**
   资源是编译进 exe 的，改 .rc 后必须重新构建。`build.ps1` 每次都会重跑 rc.exe，直接重新构建即可。

6. **`MAKEINTRESOURCE` 忘了用**
   资源 API 的字符串参数既可以是名字也可以是 ID，传数字 ID 必须包 `MAKEINTRESOURCE(id)` 转成伪指针，直接传数字会当字符串地址解引用崩溃。

## 实战建议

- **从第一天起就按区间管理 ID**：资源块 100+、控件 1000+、命令 2000+（或 32771+）、字符串 3000+、自定义消息 `WM_APP+1`，给每类留出间隔，并把这张表写在 `resource.h` 顶部注释里
- **界面上的每一个字符串都放字符串表**。写死在代码里的中文，将来做多语言时要一行行抠出来；放进 `STRINGTABLE` 则是零成本的
- **菜单文案里的加速键提示（`\tCtrl+S`）和加速键表要同步维护**，最好在 resource.h 旁边写注释互相提醒——这两处不同步时，菜单上写着 `Ctrl+S` 但按下去没反应，是很尴尬的 bug
- **对话框模板不用手写**：用 VS 资源编辑器拖拽生成 .rc 片段，再手写补注释。但理解 `DIALOGEX` 的字段（`STYLE`/`FONT`/`BEGIN` 块）便于阅读和排查问题（第 06 章展开）

## 自测

1. **`.rc` 里的 ID 为什么必须用 `#define` 而不是 C++ 的 `enum`？** —— 因为 rc.exe 是独立的资源编译器，不是 C++ 编译器，不认 enum。
2. **`IDR_` / `IDC_` / `IDM_` / `IDS_` 分别是什么资源？** —— 独立资源块（菜单/加速键/图标）、控件、菜单命令、字符串表条目。
3. **一个 `.ico` 里为什么可以只放一个图标资源，却同时当大图标和小图标用？** —— `.ico` 容器本身打包了多档尺寸；`SetIcon(h, TRUE/FALSE)` 填不同的 `WM_SETICON` 槽位，Windows 按槽位自动从图标组里挑合适的那一档。
4. **多语言支持里，为什么字符串表能靠 `LANGUAGE` 块解决，菜单却不行？** —— 字符串是运行时按语言现取的；菜单在窗口创建时就挂上去了，只有带语言参数的 `FindResourceEx` 类 API 才能按语言取，所以菜单需要卫星 DLL + `AfxSetResourceHandle` 方案。

---
上一章：[03 消息映射机制](03-message-map.md) ｜ 下一章：[05 窗口与框架类](05-frames.md)
