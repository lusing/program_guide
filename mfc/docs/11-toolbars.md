# 11 · 工具栏与状态栏

> 对应示例：`examples/11_toolbar_statusbar`

> **本章你将学会**：`CToolBar` 的组装顺序、加速键表为什么必须单独建、`CStatusBar` 的三个窗格各自归谁用、`ON_UPDATE_COMMAND_UI` 如何一处代码同时管住菜单和工具栏，以及带控制条的窗口该怎么写 `OnSize`。
> **前置知识**：第 03 章的命令 ID 与消息映射、第 05 章框架窗口的创建。

## 1. 总览

工具栏（`CToolBar`）和状态栏（`CStatusBar`）是 `CControlBar` 的派生类——MFC 对它们有**特殊待遇**：只要作为框架窗口的成员创建，框架就会：

- 自动管理它们的布局（`RepositionBars` 给普通子控件让位）
- 自动把 `ON_UPDATE_COMMAND_UI` 应用到按钮/窗格（变灰、打勾、改文字）

创建标准套路（都在 `OnCreate` 里）：

```cpp
m_toolbar.CreateEx(this, ...);
m_toolbar.SetButtons(ids, count);
m_toolbar.LoadBitmap(IDB_TOOLBAR);       // 图标位图
m_toolbar.SetSizes(CSize(54, 42), CSize(16, 15));

static UINT indicators[] = { ID_SEPARATOR, ID_INDICATOR_STATE };
m_statusBar.Create(this);
m_statusBar.SetIndicators(indicators, _countof(indicators));
```

## 2. CToolBar 组装细节

```cpp
// 1. 创建控件本体：CBRS_TOP 停靠在顶部，TOOLTIPS/FLYBY 给提示
m_toolbar.CreateEx(this, TBSTYLE_FLAT,
                   WS_CHILD | WS_VISIBLE | CBRS_TOP |
                   CBRS_TOOLTIPS | CBRS_FLYBY);

// 2. 建按钮：数组里 ID_SEPARATOR 生成竖直分隔条
static const UINT ids[] = { IDM_FILE_OPEN, IDM_FILE_SAVE,
                            ID_SEPARATOR, IDM_FMT_COLOR };
m_toolbar.SetButtons(ids, _countof(ids));

// 3. 图标位图：每格 16x15，按按钮顺序排列（分隔条不占格）
m_toolbar.LoadBitmap(IDR_TOOLBAR_BMP);   // 或 CToolBarCtrl::AddBitmap

// 4. 按钮 + 文字标签尺寸：SetSizes(按钮总尺寸, 图标尺寸)
m_toolbar.SetButtonText(0, _T("打开"));   // 文字显示在图标下方
m_toolbar.SetButtonText(1, _T("保存"));
m_toolbar.SetButtonText(3, _T("颜色"));   // 下标 2 是分隔条
m_toolbar.SetSizes(CSize(54, 42), CSize(16, 15));
```

按钮点击产生的就是 `WM_COMMAND(IDM_XXX)`——**和菜单同一个命令 ID，同一段处理代码**，无需为工具栏单独写事件。

没有图标资源时的替代品：用内存位图（`CreateCompatibleBitmap` + GDI 画色块 + `GetToolBarCtrl().AddBitmap`），本章示例演示了这个技巧；正式项目用 .bmp 或 PNG（需要自绘）资源。

## 3. 加速键表：让 Ctrl+O 真的能用

菜单项文本里的 `&O`（"打开(&O)"）是**助记符**，只在菜单已经展开时有效——按 Alt+F 打开"文件"菜单，再按 O 才触发。用户不打开菜单时直接按 Ctrl+O，**没有任何反应**。

要让它生效，需要一张**加速键表**（accelerator table）：

```rc
IDR_MAIN_MENU ACCELERATORS
BEGIN
    "O",    IDM_FILE_OPEN,  VIRTKEY, CONTROL
    "S",    IDM_FILE_SAVE,  VIRTKEY, CONTROL
    "C",    IDM_FMT_COLOR,  VIRTKEY, CONTROL, SHIFT
END
```

加速键表可以用和菜单相同的 ID（资源类型不同，互不冲突）——MFC 向导生成的 `IDR_MAINFRAME` 就是菜单、图标、工具栏、加速键表共用一个 ID。

光有资源还不够，**要在框架窗口上把它装进去**：

```cpp
CEditorWnd::CEditorWnd() {
    Create(NULL, _T("..."), WS_OVERLAPPEDWINDOW, rect, nullptr,
           MAKEINTRESOURCE(IDR_MAIN_MENU));
    LoadAccelTable(_T("IDR_MAIN_MENU"));   // ← 关键
}
```

**装完之后不用自己写 `PreTranslateMessage`。** `CFrameWnd::PreTranslateMessage` 的末尾已经做好了这件事（`winfrm.cpp` 源码）：

```cpp
if (pMsg->message >= WM_KEYFIRST && pMsg->message <= WM_KEYLAST)
{
    HACCEL hAccel = GetDefaultAccelerator();
    return hAccel != NULL && ::TranslateAccelerator(m_hWnd, hAccel, pMsg);
}
```

按下的键在进消息队列前先过一遍 `TranslateAccelerator`：命中加速键就转成 `WM_COMMAND` 走正常的命令处理，没命中才当普通按键消息发下去。

> 两个容易搞错的点。**第一，`CWinApp` 没有 `m_hAccelTable` 成员**——它在 `CFrameWnd` 上（`afxwin.h` 里 `CFrameWnd` 的 public 实现区），另外 `CMultiDocTemplate` 也有一个，供 MDI 子窗口用。网上有些示例写 `AfxGetApp()->m_hAccelTable = ...`，编译不过。
>
> **第二，`LoadAccelTable` 只能调一次**——源码里第一行就是 `ASSERT(m_hAccelTable == NULL)`。Debug 版重复调用会直接断言失败。

`GetDefaultAccelerator()` 有个 Doc/View 相关的细节：如果当前文档提供了自己的加速键表（`CDocument::GetDefaultAccelerator`），它会**优先于**框架的那张。这是第 15 章 Doc/View 里"不同文档类型不同快捷键"的实现位置。

## 4. CStatusBar：三个窗格，三种归属

状态栏由一排**窗格**（pane）组成，窗格由 indicator ID 数组定义：

```cpp
static UINT indicators[] = {
    ID_SEPARATOR,           // 第 0 格：弹性主窗格
    ID_INDICATOR_FILE,      // 自定义窗格：当前文件
    ID_INDICATOR_POS,       // 自定义窗格：光标位置
};
m_statusBar.Create(this);
m_statusBar.SetIndicators(indicators, _countof(indicators));
```

| 窗格 | 归属 | 内容 |
|---|---|---|
| `ID_SEPARATOR`（第 0 格） | **框架自用** | 菜单项提示、`CBRS_FLYBY` 的按钮提示 |
| 自定义 ID | **你的** | 文件路径、行列号、状态文字 |
| `ID_INDICATOR_CAPS` / `NUM` / `SCRL` | 系统内置 | 大写锁定、数字键盘、滚动锁定，加进数组即自动工作 |

**第 0 格是框架的提示区，不要拿它显示自己的状态**——鼠标滑过菜单或工具栏按钮时，框架会往这一格写提示文字，把你写的内容覆盖掉。自定义状态一律放后面带自己 ID 的窗格。

自定义窗格的 ID 在 resource.h 里 `#define ID_INDICATOR_FILE 4001`（用 4 开头段避开其他 ID）。

更新文字：

```cpp
m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_FILE),
                        _T("已保存"));
```

`CommandToIndex` 把 ID 换成下标——**不要写死下标**，indicator 数组一改全乱。

改窗格宽度用 `SetPaneInfo(index, id, style, width)`，`style` 里带 `SBPS_STRETCH` 的窗格会自动占满剩余宽度（第 0 格就是这个样式）。

## 5. ON_UPDATE_COMMAND_UI：一处代码管三处

工具栏按钮的置灰与菜单完全同源（第 03 章）：

```cpp
ON_UPDATE_COMMAND_UI(IDM_FILE_SAVE, OnUpdateFileSave)

afx_msg void OnUpdateFileSave(CCmdUI* pCmdUI) {
    pCmdUI->Enable(!m_filePath.IsEmpty());
}
```

这段代码在**消息队列空闲时**被框架调用（不是每次消息都调），菜单项、工具栏按钮、状态栏窗格同时生效——写一次，三处一致。`CCmdUI` 还能 `SetText`（动态菜单文案）、`SetCheck`（勾选状态）。

**`ON_UPDATE_COMMAND_UI` 里只读状态，不要改状态。** 它会被反复调用，在里面改数据（比如递增计数器、写日志、改 `m_filePath`）会让"状态变了→界面要更新→又调一次"变成循环，CPU 空转。判断和显示是它唯一的职责。

## 6. 布局：让普通子控件给控制条让位

工具栏/状态栏占据客户区上下之后，`GetClientRect` 给出的矩形仍然包含它们。标准做法：

```cpp
afx_msg void OnSize(UINT nType, int cx, int cy) {
    CFrameWnd::OnSize(nType, cx, cy);
    if (!m_edit.GetSafeHwnd())
        return;
    CRect rect;
    // reposQuery：只查询，控制条先占好位置，rect 返回剩余空间
    RepositionBars(AFX_IDW_CONTROLBAR_FIRST, AFX_IDW_CONTROLBAR_LAST,
                   0, reposQuery, &rect);
    m_edit.MoveWindow(rect);
}
```

`AFX_IDW_CONTROLBAR_FIRST..LAST` 是所有控制条的 ID 范围。这个"先查询再布局"是带控制条的窗口的标准 `OnSize` 写法，第 25 章实战项目沿用。

`if (!m_edit.GetSafeHwnd()) return;` 这一句不能省：`OnSize` 在 `OnCreate` 之前就可能被调用一次（创建窗口时框架会先发一个尺寸消息），那时子控件还不存在，`MoveWindow` 会作用在空对象上。

## 7. 工具栏的两种形态

| | `CToolBar` | `CMFCToolBar` |
|---|---|---|
| 头文件 | `<afxext.h>` | `<afxcontrolbars.h>` |
| 外观 | 传统扁平工具栏 | Office 2007+ 风格，热态/按下态渐变 |
| 图标 | 16 色 `.bmp`，固定尺寸 | PNG/32 位色，支持高 DPI 多尺寸 |
| 额外能力 | 无 | 自定义对话框、下拉按钮、停靠重排 |
| 依赖 | 无 | 需要 `CWinAppEx`、`CFrameWndEx` |

`CMFCToolBar` 的组装 API 与 `CToolBar` 基本同构（`CreateEx` → `SetButtons` → `LoadBitmap`），迁移成本不高。代价是要把 `CWinApp` 换成 `CWinAppEx`、`CFrameWnd` 换成 `CFrameWndEx`，且功能包会接管一部分状态持久化（窗口位置、工具栏布局会写注册表）。

**新项目直接用功能包（`CMFCToolBar`）**；维护老项目时保持 `CToolBar` 即可，两者不必混用。

## 常见坑

1. **菜单有 `&O` 就以为 Ctrl+O 能用**
   助记符只在菜单展开时生效。要全局快捷键，必须有 `ACCELERATORS` 资源**并且**在框架窗口上调用 `LoadAccelTable`——少任何一半，快捷键都是静默失效（不报错、不提示）。

2. **`AfxGetApp()->m_hAccelTable = ...` 编译不过**
   `CWinApp` 没有这个成员。它在 `CFrameWnd` 上（`CMultiDocTemplate` 也有一个，供 MDI 子窗口用）。用 `CFrameWnd::LoadAccelTable`。

3. **`LoadAccelTable` 调了两次**
   源码第一行是 `ASSERT(m_hAccelTable == NULL)`，Debug 版直接断言失败。想换表得先把旧的清掉。

4. **把状态文字写进第 0 格**
   `ID_SEPARATOR` 那格是框架的提示区，鼠标滑过菜单/按钮时框架会往里面写提示，把你的内容覆盖掉。自定义状态放带自己 ID 的窗格。

5. **图标和按钮对不上**
   位图格数必须等于命令按钮数（分隔条不占格）。`SetButtons` 与 `AddBitmap`/`LoadBitmap` 顺序错了会串图。

6. **`toolbar.bmp` 载入失败是静默的**
   `LoadBitmap` 返回 `FALSE` 时按钮仍在但一片空白。判断返回值并在失败时降级为纯文字按钮，比事后排查省事。

7. **工具栏不响应 `UPDATE_COMMAND_UI`**
   控制条必须是**框架窗口的成员变量**且正确 `CreateEx`。用局部变量建的工具栏没有 UI 更新，函数返回后对象析构、控件还在——比不更新更糟。

8. **在 `ON_UPDATE_COMMAND_UI` 里改数据**
   它在空闲时被反复调用。在里面递增计数器、写日志之类会形成"改状态→更新界面→再改状态"的循环，CPU 空转。只读、只决定显示。

## 实战建议

- **状态栏预留一个"消息窗格"**，把用户需要知道的反馈（保存成功、加载了什么、几行几列）都写进去，比弹 `MessageBox` 克制得多——第 25 章实战项目就有一个
- **工具栏只放高频操作（≤8 个）**，其余进菜单；带文字标签的工具栏对新手更友好，纯图标的只适合极高频且图标表意明确的动作
- **快捷键和菜单项一起加**：加菜单项时顺手在 `ACCELERATORS` 表里补一条，否则用惯键盘的用户会觉得这个功能"没有"
- **`OnSize` 里先判子控件句柄再布局**，否则创建阶段的第一次尺寸消息会让程序在空窗口对象上崩掉

## 自测

1. **菜单项写了 `&O`，为什么按 Ctrl+O 没反应？要补什么？**
   —— `&O` 是助记符，只在菜单已展开时生效。要全局快捷键得两件事都做：资源里加 `ACCELERATORS` 表（`"O", IDM_FILE_OPEN, VIRTKEY, CONTROL`），并在框架窗口上调用 `LoadAccelTable(_T("IDR_MAIN_MENU"))`。

2. **`LoadAccelTable` 之后还需要自己写 `PreTranslateMessage` 调 `TranslateAccelerator` 吗？**
   —— 不需要。`CFrameWnd::PreTranslateMessage` 在末尾已经对 `WM_KEYFIRST..WM_KEYLAST` 范围的消息调用了 `::TranslateAccelerator(m_hWnd, GetDefaultAccelerator(), pMsg)`。

3. **状态栏第 0 格为什么不能用来显示自己的状态文字？**
   —— `ID_SEPARATOR` 那格是框架的提示区，鼠标滑过菜单项或带 `CBRS_FLYBY` 的按钮时框架会往里面写提示文字，把你的内容覆盖掉。自定义状态要用带自己 ID 的窗格。

4. **`ON_UPDATE_COMMAND_UI` 什么时候被调用？为什么不能在里面对状态做修改？**
   —— 消息队列空闲时被框架调用（不是每条消息都调）。因为在空闲时反复执行，在里面改状态会形成"状态变→界面更新→又改状态"的循环，白白占用 CPU；它只该读状态、决定可用性/勾选/文案。

5. **带控制条的窗口为什么必须在 `OnSize` 里调 `RepositionBars(..., reposQuery, &rect)`？**
   —— 控制条占掉客户区上下之后 `GetClientRect` 仍然包含那块区域。`reposQuery` 让控制条先完成定位，再返回真正剩余的矩形给普通子控件，否则子控件会被工具栏和状态栏盖住。

---
上一章：[10 通用对话框与文件 IO](10-common-dialogs.md) ｜ 下一章：[15 Doc/View 架构](15-docview.md)
