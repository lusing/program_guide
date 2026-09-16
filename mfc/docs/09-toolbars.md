# 09 · 工具栏与状态栏

> 对应示例：`examples/08_toolbar_statusbar`

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

没有图标资源时的替代品：用内存位图（`CreateCompatibleBitmap` + GDI 画色块 + `GetToolBarCtrl().AddBitmap`），示例 08 演示了这个技巧；正式项目用 .bmp 或 PNG（需要自绘）资源。

## 3. CStatusBar：窗格即界面

状态栏由一排**窗格**（pane）组成，窗格由 indicator ID 数组定义：

```cpp
static UINT indicators[] = {
    ID_SEPARATOR,           // 第 0 格：弹性主窗格（自动占满剩余宽度）
    ID_INDICATOR_STATE,     // 自定义窗格：文件状态
};
m_statusBar.Create(this);
m_statusBar.SetIndicators(indicators, _countof(indicators));
```

自定义窗格的 ID 在 resource.h 里 `#define ID_INDICATOR_STATE 4100`（用 4 开头段避开其他 ID）。

更新文字：

```cpp
m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_STATE),
                        _T("已保存"));
```

`CommandToIndex` 把 ID 换成下标——**不要写死下标**，indicator 数组一改全乱。

`CAPS`、`NUM` 这些系统内置窗格 ID 加进数组即自动工作。

## 4. ON_UPDATE_COMMAND_UI：一处代码管三处

工具栏按钮的置灰与菜单完全同源（第 03 章）：

```cpp
ON_UPDATE_COMMAND_UI(IDM_FILE_SAVE, OnUpdateFileSave)

afx_msg void OnUpdateFileSave(CCmdUI* pCmdUI) {
    pCmdUI->Enable(!m_filePath.IsEmpty());
}
```

这段代码在**消息队列空闲时**被框架调用（不是每次消息都调），菜单、工具栏按钮同时生效。`CCmdUI` 还能 `SetText`（动态菜单文案）、`SetCheck`（勾选状态）。

## 5. 布局：让普通子控件给控制条让位

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

`AFX_IDW_CONTROLBAR_FIRST..LAST` 是所有控制条的 ID 范围。这个"先查询再布局"是带控制条的窗口的标准 OnSize 写法，第 13 章实战项目沿用。

## 6. 常见坑

**图标和按钮对不上**：位图格数必须等于命令按钮数（分隔条除外）。SetButtons 之后 AddBitmap/LoadBitmap 顺序错了会串图。

**状态栏窗格文字被覆盖**：第 0 格是框架自用的提示区（菜单提示、FLYBY 提示），自己的状态文字放自定义 ID 窗格。

**工具栏不响应 UPDATE_COMMAND_UI**：控件必须是框架窗口的成员且正确创建。用局部变量建的工具栏没有 UI 更新。

**toolbar.bmp 载入失败静默**：`LoadBitmap` 返回 FALSE 时按钮仍在但空白，记得判断返回值——示例 08/13 都做了。

## 7. 实战建议

- 状态栏预留一个"消息窗格"，把用户需要知道的反馈（保存成功、加载了什么）都写进去，比弹 MessageBox 克制
- 工具栏只放高频操作（≤8 个），其余进菜单；带文字标签的工具栏对新手用户更友好
- 需要现代外观时研究 `CMFCToolBar`（MFC 的功能包版本，支持 PNG、热态图标、自定义），API 同构

---
上一章：[08 通用对话框与文件 IO](08-common-dialogs.md) ｜ 下一章：[10 Doc/View 架构](10-docview.md)
