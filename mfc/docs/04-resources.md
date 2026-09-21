# 04 · 资源文件入门

> 对应示例：`examples/04_resources`

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

ID 命名惯例（VS 向导风格，照做可以避免混乱）：

| 前缀 | 含义 | 示例 |
|---|---|---|
| `IDR_` | 独立资源块（菜单/加速键/图标/工具栏） | `IDR_MAIN_MENU` |
| `IDD_` | 对话框模板 | `IDD_LOGIN` |
| `IDC_` | 控件 ID（也用于光标） | `IDC_USER` |
| `IDM_` | 菜单命令 ID | `IDM_FILE_NEW` |
| `IDS_` | 字符串表条目 | `IDS_APP_TITLE` |

## 3. 资源脚本 .rc 的语法

`.rc` 文件结构类似 C，支持 `//` 注释和 `#include`。本教程所有 .rc 用 UTF-8 保存并在文件头声明代码页：

```rc
#pragma code_page(65001)    // 告诉 rc.exe 按 UTF-8 解析
#include "resource.h"
#include "afxres.h"         // MFC 标准资源 ID（ID_FILE_OPEN 等）和类型宏
```

### 3.1 菜单

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

### 3.2 加速键表

```rc
IDR_MAIN_ACCEL ACCELERATORS
BEGIN
    "N", IDM_FILE_NEW,  VIRTKEY, CONTROL
    "O", IDM_FILE_OPEN, VIRTKEY, CONTROL
END
```

把组合键翻译成命令 ID。加载与分发：

```cpp
// InitInstance 里加载
m_accel = ::LoadAccelerators(AfxGetInstanceHandle(),
                             MAKEINTRESOURCE(IDR_MAIN_ACCEL));

// CWinApp::PreTranslateMessage 里分发
BOOL PreTranslateMessage(MSG* pMsg) override {
    if (m_accel && m_pMainWnd &&
        ::TranslateAccelerator(m_pMainWnd->GetSafeHwnd(), m_accel, pMsg))
        return TRUE;    // 翻译成了命令，别再往下传
    return CWinApp::PreTranslateMessage(pMsg);
}
```

注意：**Doc/View 框架（第 15 章）不用这么写**，`CFrameWnd::LoadFrame` 会自动加载同 ID 的加速键表。

### 3.3 字符串表

```rc
STRINGTABLE
BEGIN
    IDS_APP_TITLE "MFC 资源示例"
    IDS_GREETING  "这段文字来自字符串表资源。"
END
```

```cpp
CString s;
s.LoadString(IDS_GREETING);
```

界面文案放字符串表是本地化的基础。注意：每条字符串不超过 4095 字符，且 **不能包含 `\n` 之类转义以外的原始换行**——一条就是一行。

### 3.4 把菜单挂到框架窗口

```cpp
CMainWindow::CMainWindow() {
    // Create 的第 6 个参数是菜单资源名
    Create(NULL, LoadText(IDS_APP_TITLE), WS_OVERLAPPEDWINDOW,
           CRect(100, 100, 680, 440), nullptr,
           MAKEINTRESOURCE(IDR_MAIN_MENU));
}
```

之后点菜单 → `WM_COMMAND(IDM_XXX)` → `ON_COMMAND` 分发，一条链路。

## 4. 命令 ID 的复用：菜单 = 工具栏 = 加速键

一个命令 ID（比如 `IDM_FILE_SAVE`）可以同时出现在菜单、工具栏、加速键表里，三处触发都会路由到同一个 `ON_COMMAND` 处理函数。`ON_UPDATE_COMMAND_UI` 也对三者统一生效——菜单变灰时工具栏按钮同步变灰。这是 MFC 命令系统的核心红利，第 11 章展开。

## 5. 常见坑

**rc 编译报 RC2135**：九成是语法问题——字符串没放进 `STRINGTABLE`/`BEGIN...END`、少引号、ID 没定义。rc 的报错行号经常滞后，检查报错行的**上一行**。

**中文乱码/编译失败**：.rc 存成无 BOM 的 UTF-8 时必须 `#pragma code_page(65001)`，编译加 `/c65001`；或者干脆存成 UTF-16 LE（rc 原生支持）。

**改了资源但 exe 没变**：资源是编译进 exe 的，改 .rc 后必须重新构建。资源 ID 冲突（两个资源用同一个数字）会导致加载到错误对象——按前缀分号段分配 ID（101 资源块 / 1000 控件 / 2000 命令）。

**`MAKEINTRESOURCE` 忘了用**：资源 API 的字符串参数既可以是名字也可以是 ID，传数字 ID 必须包 `MAKEINTRESOURCE(id)` 转成伪指针，直接传数字会当字符串地址解引用崩溃。

## 6. 实战建议

- 从第一天起就按向导惯例管理 ID：资源块 101+、控件 1001+、命令 2001+、自定义消息 `WM_APP+1`，给每类留出间隔
- 菜单文案里的加速键提示（`\tCtrl+S`）和加速键表要同步维护，最好在 resource.h 旁边写注释互相提醒
- 对话框模板不用手写——用 VS 资源编辑器拖拽生成 .rc 片段，再手写补注释即可；理解 DIALOGEX 的字段（STYLE/FONT/BEGIN 块）便于阅读

---
上一章：[03 消息映射机制](03-message-map.md) ｜ 下一章：[05 窗口与框架类](05-frames.md)
