# 28 · 控制条家族：CDialogBar、CReBar 与停靠体系

> 对应示例：`examples/28_control_bars`

> **本章你将学会**：CDialogBar（对话条）的创建与命令路由、CReBar 的 band 编组、经典停靠三件套（EnableDocking/DockControlBar/FloatControlBar）、控制条布局的内部机制。
> **前置知识**：第 11 章的工具栏与状态栏、第 06 章的对话框。

《Visual C++ MFC 扩展编程实例》第 2 章是全书的总纲——**控制条**。它先讲通用控制条与 API/MFC 两条创建路线，再用停靠、对话条、ReBar、更新命令、自定义控制条把 `CControlBar` 家族拆了个透。第 11 章我们讲了家族里最常见的两位（CToolBar/CStatusBar）；本章补齐剩下的主力。

## 1. 家族地图与继承关系

```text
CWnd
└── CControlBar                 ← 控制条基类：布局协商 + 命令路由参与
    ├── CStatusBar              ← 状态栏（第 11 章）
    ├── CToolBar                ← 工具栏（第 11 章）
    ├── CDialogBar              ← 对话条：对话框模板做的控制条
    ├── CReBar                  ← ReBar：装控制条的"带子架"
    └── CDockBar                ← 停靠站点（框架内部用）
```

`CControlBar` 的两个关键虚函数（老书 2.7 节用整整一节讲）：

- `CalcFixedLayout()`：算自己的固定尺寸；
- `CalcDynamicLayout()`：算动态尺寸（浮动/伸缩时）。

框架布局的协商链：`CFrameWnd::RecalcLayout()` → `CWnd::RepositionBars()` → 每根控制条的 `OnSizeParent()`（响应 `WM_SIZEPARENT`）→ `CalcDynamicLayout()`/`CalcFixedLayout()`。理解这条链，"控制条为什么出现在那里、占多大"就不再是玄学——这也是自定义控制条（派生 CControlBar 改写 CalcDynamicLayout）的理论基础。

## 2. CDialogBar：对话框模板即控制条

工具栏只能放按钮；要放**组合框、编辑框、复选框**这些输入控件，就用对话条。创建三要素（示例 28）：

```cpp
// 1. 模板：长得像对话框，但必须 WS_CHILD | WS_VISIBLE，且没有 OK/Cancel
// IDD_DIALOGBAR DIALOGEX ... STYLE ... WS_CHILD | WS_VISIBLE ...

// 2. 创建：参数是 父窗口 / 模板ID / 允许停靠的边 / 控制条ID
if (!m_dialogBar.Create(this, IDD_DIALOGBAR,
                        CBRS_ALIGN_TOP | CBRS_ALIGN_BOTTOM, IDD_DIALOGBAR))
    return -1;

// 3. 内容自理：对话条不做自动 DDX，控件内容自己初始化
CComboBox* pCombo = (CComboBox*)m_dialogBar.GetDlgItem(IDC_DB_COMBO);
pCombo->AddString(_T("红色"));
```

**命令路由是白送的**：对话条是 `CCmdTarget` 路由链的一环——里面的组合框 `CBN_SELCHANGE`、复选框 `BN_CLICKED`、编辑框 `EN_CHANGE`，都会以标准 `WM_COMMAND` 走到框架窗口的消息映射里，和菜单命令一模一样：

```cpp
BEGIN_MESSAGE_MAP(CBarLabWnd, CFrameWnd)
    ON_CBN_SELCHANGE(IDC_DB_COMBO, OnDbComboChange)   // 对话条上的组合框
    ON_BN_CLICKED(IDC_DB_CHECK, OnDbCheck)
    ON_EN_CHANGE(IDC_DB_EDIT, OnDbEditChange)
END_MESSAGE_MAP()
```

这是对话条相对"手工往工具栏上贴控件"（老书例 28 的艰苦路线）的本质优势：**路由免费**。

注意 `EN_CHANGE` 这类内容型通知每敲一键都来——状态栏刷新之类的轻活可以，重活（查询、搜索）要防抖或改在按钮/回车时做。

## 3. CReBar：把控制条编成"带子"

ReBar 是 IE 时代引入的容器（老书 2.9 节）：工具栏、对话条作为 **band** 挂进去，得到分组标题、可拖动 rearrange 的分隔条：

```cpp
if (!m_rebar.Create(this, RBS_BANDBORDERS,
                    WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS |
                    WS_CLIPCHILDREN | CBRS_TOP | CBRS_ALIGN_ANY))
    return -1;
m_rebar.AddBar(&m_toolbar, _T("命令"));      // band 1：工具栏
m_rebar.AddBar(&m_dialogBar, _T("属性"));    // band 2：对话条
DockControlBar(&m_rebar);                    // ReBar 整体停靠
```

两个细节（示例 28 都吃了）：

- `CReBar::Create` **没有标题参数**：`Create(parent, 控件样式, 窗口样式, ID)`——和 CToolBar 的 CreateEx 长得像但签名不同，凭记忆写会 C2664。
- 进了 ReBar 的控制条不再单独 `DockControlBar`——**ReBar 是它们的停靠代理**，框架只认识 ReBar 这一根条。

`CReBarCtrl`（裸控件版）一般不直接用——MFC 的 CReBar 包装已够。现代 MFC（Feature Pack）另有 `CMFCReBar`/`CMFCToolBar` 全家，第 11 章的对比表说过：经典类够用、教学清晰，老书讲的就是这套。

## 4. 停靠三件套

```cpp
EnableDocking(CBRS_ALIGN_ANY);              // ① 框架声明：四边能停
m_dialogBar.EnableDocking(CBRS_ALIGN_ANY);  // ② 控制条声明：我能停靠
DockControlBar(&m_dialogBar);               // ③ 停到（默认）边上
FloatControlBar(&m_dialogBar, pt, CBRS_ALIGN_TOP);  // 浮动到屏幕坐标
ShowControlBar(&m_dialogBar, bShow, FALSE);          // 显/隐（带布局重算）
```

体验全在组合里：

- 用户拖动条子的把手（`CBRS_GRIPPER`）可以自由拖停——这是 1996 年 VC 给 Windows 桌面带来的招牌交互。
- `FloatControlBar` 编程式浮动（示例 28 的"浮动对话条"按钮，浮到鼠标处）。
- `DockControlBar(&bar, CBRS_ALIGN_LEFT, &rc)` 指定边与初始矩形。
- **显隐用 `ShowControlBar`** 而不是直接 `ShowWindow`：前者会走 RecalcLayout 把客户区重排；后者只藏窗口，留下布局空洞。

配套的 `ON_UPDATE_COMMAND_UI` 打复选（第 27 章同款）：

```cpp
void OnUpdateToggleDlg(CCmdUI* p) {
    p->SetCheck((m_dialogBar.GetStyle() & WS_VISIBLE) != 0);
}
```

## 5. 布局机制速览（读懂老书 2.7 节）

框架窗口 `OnSize` → `RecalcLayout` → `RepositionBars(AFX_IDW_CONTROLBAR_FIRST, AFX_IDW_CONTROLBAR_LAST, AFX_IDW_PANE_FIRST)`——控制条们按 ID 段参与，剩余空间给 pane（视图）。每根条收到 `WM_SIZEPARENT` 时返回自己要占的矩形（`CalcFixedLayout`/`CalcDynamicLayout` 的返回值）。所以：

- 自定义"自适应内容高度"的控制条：派生改 `CalcFixedLayout`；
- "高度随内容变"的对话条：模板高度决定一切（MFC 按模板算），要动态变高就得走派生路线；
- `RecalcLayout(TRUE)` 的 TRUE = "控制条位置可能变了，别管缓存"。

这一节不需要天天用，但**调试布局问题时它是地图**：控制条没出现 → 查是否加进了停靠协商（EnableDocking/ID 段）；位置不对 → 查 DockControlBar 的边参数与 RecalcLayout 调用时机。

## 6. 状态栏再进一步

第 11 章覆盖了窗格基础。控制条语境下补两点：

- `SetPaneInfo(index, id, style, width)` 运行期改窗格宽度/样式（`SBPS_NORMAL`/`SBPS_STRETCH` 弹性窗格——状态栏自己也是控制条，宽度协商走同一套）。
- 往状态栏**塞控件**（进度条、动画）是老书例 31 的经典题：`SetPaneInfo` 留出窗格，`OnSize` 里把子控件 `MoveWindow` 到 `GetItemRect` 返回的窗格矩形——本质是手工版"对话条"。

## 实战建议

- 一屏控制条别超过三根：ReBar(工具+对话条) + 状态栏是理智上限；再多数值输入就该考虑挪到对话框或侧栏面板。
- 对话条模板改了尺寸，运行时旧停靠位置缓存可能失配——`m_dialogBar.DestroyWindow(); Create(...)` 一轮干净重来，好过追布局怪象。
- 浮动控制条的持久化（下次启动恢复用户摆放）存 `GetBarStyle`/浮动矩形进注册表（第 13 章套路）。
- 检查命令路由问题的第一现场：控制条上的控件命令走 `WM_COMMAND`，`ON_CBN_SELCHANGE` 的 ID 是**控件 ID**——resource.h 里控件 ID 与命令 ID 混段时最容易接错。

## 常见坑（实测）

1. **对话条模板不是 WS_CHILD**：Create 返回 FALSE，`OnCreate` 返回 -1，窗口整个不出现——检查模板 STYLE 行。
2. **CReBar::Create 多传了标题参数**：签名是 `(parent, dwCtrlStyle, dwStyle, nID)`，没有 LPCTSTR——C2664 编译错还算好的，怕的是拿 CToolBar::CreateEx 的记忆硬套。
3. **进了 ReBar 的条再单独 DockControlBar**：布局打架（条被拽出 ReBar 或重复停靠）——ReBar 全权代理。
4. **显隐控制条用 ShowWindow**：客户区不回收，出现空洞；用 `ShowControlBar`。
5. **对话条控件的通知接不到**：多半是消息映射写在对话条类里而非框架里——对话条自身不是窗口控件的宿主路由（默认路由给 frame），写到框架（或父链上任一 CCmdTarget）即可。
