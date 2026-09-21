# 16 · MDI 多文档与分割窗口

> 对应示例：`examples/16_mdi_splitter`

> **本章你将学会**：MDI 的窗口层次与两套资源怎么配合、`CMultiDocTemplate` 和 SDI 模板的差别、`CSplitterWnd` 静态分栏的正确接法，以及"左列表右详情"的经典多视图同步。
> **前置知识**：第 15 章的 Doc/View 架构。

## 1. SDI、MDI 与对话框式

| 形态 | 模板类 | 窗口结构 | 典型场景 |
|---|---|---|---|
| SDI | `CSingleDocTemplate` | 一个主框架 = 一个文档 | 记事本 |
| **MDI** | `CMultiDocTemplate` | 一个外壳框架 + 任意个子框架 | Photoshop、VS |
| 对话框式 | 无模板 | 一个对话框 | 小工具（前几章） |

MDI 的窗口层次——外壳只有一个，子窗口随文档增减：

```text
CMDIFrameWnd（外壳：菜单/工具栏/状态栏，管住整个客户区）
   │  LoadFrame(IDR_MAINFRAME)  ← 外壳的菜单和标题从这来
   │
   ├── CMDIChildWnd（子框架 1：文档 A）
   │      │  菜单/加速键来自 IDR_MDITYPE，子窗口激活时框架自动切换
   │      └── CSplitterWnd（可选：把客户区分成几格）
   │             ├── CView 0（左：列表）
   │             └── CView 1（右：详情）
   │
   └── CMDIChildWnd（子框架 2：文档 B）……
```

三个类各司其职：**外壳**管"程序级"的东西（窗口菜单、层叠平铺）；**子框架**是"一个文档的壳"，标题跟文档名走；**视图**住在子框架里。命令路由也顺着这个层次走：菜单命令先给激活的子框架 → 视图 → 文档 → 外壳 → 应用，沿途谁处理了就停。

## 2. CMultiDocTemplate 与两套资源

```cpp
auto* pTemplate = new CMultiDocTemplate(
    IDR_MDITYPE,                 // 文档类型的资源：菜单/加速键/9 字段串
    RUNTIME_CLASS(CMdiDoc),      // 文档
    RUNTIME_CLASS(CChildFrame),  // 子框架（每开一个文档 new 一个）
    RUNTIME_CLASS(CLeftView));   // 默认视图类
AddDocTemplate(pTemplate);
```

和 SDI 的第一个差别在资源 ID：MDI **必须两套**——

| 资源 | 内容 | 谁在用 |
|---|---|---|
| `IDR_MAINFRAME` | 外壳菜单、外壳加速键、主框架标题 | `LoadFrame(IDR_MAINFRAME)` 创建外壳时 |
| `IDR_MDITYPE` | 文档菜单、文档加速键、9 字段串 | 每个子窗口激活时，框架把外壳菜单换成这套 |

没有子窗口时显示外壳菜单（只有文件-新建/退出），一旦有激活的子窗口，菜单自动换成文档类型的（多了关闭、窗口菜单）。这个切换是 `CMDIChildWnd` 内置的，不用你写一行。

第二个差别在初始化顺序：外壳和文档**分开创建**——

```cpp
auto* pFrame = new CMainFrame;
m_pMainWnd = pFrame;
pFrame->LoadFrame(IDR_MAINFRAME);   // ① 先造外壳
pFrame->ShowWindow(m_nCmdShow);
pFrame->UpdateWindow();

OnFileNew();                        // ② 再造第一个文档（框架 new 出
                                    //    文档 + 子框架 + 视图并缝合）
```

SDI 里 `ProcessShellCommand` 一步到位，MDI 里通常自己调 `OnFileNew()`（它是 `CWinApp` 的 public 虚函数）。有多个模板时，`ID_FILE_NEW` 会弹对话框让用户选类型；只有一个模板就直接用它——`CDocManager` 维护着模板链表，这就是它做选择的全部逻辑。

`IDR_MDITYPE` 的字符串表仍是第 15 章讲的 9 字段格式，字段含义不变。子窗口标题（新建默认名）取自第 3 字段；过滤器字段只在打开/保存时用——本例菜单没有打开/保存（第 17 章补 `Serialize` 后启用），留空即可。

## 3. 分割窗口 CSplitterWnd

`CSplitterWnd`（在 `<afxext.h>` 里）把一个子框架的客户区分成几格，每格住一个视图。两种创建方式：

| | `CreateStatic` | `CreateDynamic` |
|---|---|---|
| 分栏数 | 固定（创建时定死 rows×cols） | 可动态增删（拆分条拖出来的） |
| 每格视图 | **可以是不同类** | 同一个视图类 |
| 典型用途 | 左列表右详情 | 资源管理器式多窗格 |

静态分栏是绝大多数场景——示例就是这么写的，位置在子框架的 `OnCreateClient`：

```cpp
BOOL CChildFrame::OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) {
    if (!m_split.CreateStatic(this, 1, 2))          // 1 行 2 列
        return FALSE;
    m_split.CreateView(0, 0, RUNTIME_CLASS(CLeftView),
                       CSize(200, 0), pContext);    // 左格
    m_split.CreateView(0, 1, RUNTIME_CLASS(CRightView),
                       CSize(0, 0), pContext);      // 右格
    m_split.SetColumnInfo(0, 220, 100);             // 理想 220px，最小 100px
    m_split.RecalcLayout();
    return TRUE;
}
```

四件事，一件都不能错：

- **`pContext` 必须原样传给 `CreateView`**。它是框架传进来的"文档↔视图"绑定上下文，`CreateView` 内部靠它让每个视图 `GetDocument()` 拿到文档。自己造一个或传 `NULL`，视图创建得出来但文档是空的，一访问就崩。
- **每格调一次 `CreateView`，索引必须在 `CreateStatic` 声明的行列范围内**，超了直接断言。
- **初始宽度有两层**：`CreateView` 的 `CSize` 只是初值；要"理想宽度 + 最小宽度 + 用户拖动边界"这套语义，用 `SetColumnInfo(col, ideal, min)`（行方向是 `SetRowInfo`），改完调 `RecalcLayout()` 生效。
- **父子关系**：splitter 是子框架的子窗口，视图是 splitter 的子窗口。所以视图里 `GetParent()` 拿到的是 splitter，不是 `CChildFrame`——要找子框架得 `GetParentFrame()`。

`OnCreateClient` 返回 `FALSE` 时框架不报错——子窗口照常出现，客户区空白。所以每步返回值都要检查，别让静默失败留到运行时。

## 4. 多视图数据同步

左列表右详情是 splitter 最经典的应用。职责划分：

```text
文档（唯一数据源）：m_items[] 条目数组 + m_sel 当前选中下标
   ▲                          │
   │ 读数据                    │ 广播 UpdateAllViews
   │                          ▼
左视图：负责"选谁"            右视图：负责"显示/编辑谁"
   用户点列表 → doc.m_sel = i     收到 HINT_SEL → 从文档读详情进编辑框
   → UpdateAllViews(this,        用户改编辑框 → 写回 doc + SetModifiedFlag
     HINT_SEL)                     → UpdateAllViews(this, HINT_DETAIL)
                                   （左视图不关心详情，收到也忽略）
```

关键代码就两段。左视图的选中处理：

```cpp
afx_msg void CLeftView::OnSelChange() {
    int i = m_list.GetCurSel();
    if (i < 0) return;
    GetDoc()->m_sel = i;
    GetDoc()->UpdateAllViews(this, HINT_SEL);   // 排除自己，右视图跟上
}
```

右视图的 `OnUpdate` 按 `lHint` 决定刷新范围——但它的场景里 HINT_SEL 和全量刷新要做的事**恰好相同**（把文档里选中项的详情搬进编辑框），所以合并成一段，用第 15 章的 `m_updating` 守卫挡 `EN_CHANGE` 回环：

```cpp
void CRightView::OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) {
    if (!GetDoc()) return;
    m_updating = true;
    int sel = GetDoc()->m_sel;
    if (sel >= 0 && sel < GetDoc()->m_items.GetSize())
        m_edit.SetWindowText(GetDoc()->m_items[sel].detail);
    else
        m_edit.SetWindowText(_T(""));
    m_updating = false;
}
```

两个纪律，违反了同步立刻失效：

- **视图不存业务数据**。左视图里没有条目数组的副本，右视图里没有详情的副本——只有编辑框这个"控件状态"和文档这一个数据源。
- **hint 枚举要敢于"收到也忽略"**。`HINT_DETAIL` 到达左视图时直接 `return`——广播是全网的，接不接由各视图自己定，这比"每种消息只发给关心的视图"（需要定向投递机制）简单得多，MFC 也不提供定向投递。

顺带一提：`ID_FILE_NEW`、`ID_FILE_CLOSE`、`ID_APP_EXIT` 和 `ID_WINDOW_CASCADE`/`ID_WINDOW_TILE_HORZ`/`ID_WINDOW_ARRANGE` 全部不用写处理代码——分别由 `CWinApp`、`CDocument`、`CMDIFrameWnd` 的标准实现处理，命令路由会自动找到它们。你写的代码只有：文档数据、两个视图、splitter 布局。

## 常见坑

1. **`CreateView` 传 `NULL` 或自造 `CCreateContext`**
   视图能创建，但 `GetDocument()` 返回 `NULL`，`OnInitialUpdate`/`OnUpdate` 里一解引用就崩。`pContext` 是框架传给 `OnCreateClient` 的，**原样转发**，不要自己 new。

2. **`CreateStatic` 的行列数和 `CreateView` 索引不匹配**
   `CreateStatic(this, 1, 2)` 之后去 `CreateView(1, 0, ...)` 直接断言。数好行列再写循环。

3. **`IDR_MAINFRAME` 的字符串表漏写**
   SDI 只有一套资源、错不了；MDI 新增了第二套，容易漏掉 `IDR_MAINFRAME` 那条——症状是外壳标题为空、外壳菜单加载失败。两套 STRINGTABLE 都要写。

4. **两个视图各存一份数据**
   一边改了另一边不知道，同步逻辑写再多也救不回来。数据只在文档里，视图只留控件状态（选中项回显、滚动位置）。

5. **`OnCreateClient` 返回 `FALSE` 不报错**
   `CreateStatic`/`CreateView` 失败后如果照样 `return TRUE` 或吞掉错误，子窗口客户区一片空白、没有任何提示。每步检查返回值，失败就 `return FALSE` 并在调试器里追。

6. **初始宽度全靠 `CreateView` 的 `CSize` 硬凑**
   `CSize` 只是初值，想要"最小宽度 + 用户可拖"的语义用 `SetColumnInfo(0, ideal, min)` + `RecalcLayout()`。

## 实战建议

- 分栏布局参数（列宽、最小值）集中在 `OnCreateClient` 一处，别散到视图的 `OnSize` 里去补丁
- 视图找文档用 `GetDocument()`，找子框架用 `GetParentFrame()`——`GetParent()` 返回的是 splitter，不是框架
- 子窗口数量多的 MDI，激活切换时可处理 `WM_MDIACTIVATE` 刷新标题栏/工具栏状态（比如"当前编辑第 N 条"）
- 多个文档类型（多个模板）时，`IDR_MDITYPE` 的第 8 字段（注册表类型名）记得各写各的，注册文件关联（第 13 章）才不会互相覆盖
- 先在 SDI（第 15 章）里把数据模型和 `UpdateAllViews` 走通，再搬进 MDI——MDI 只是"多了壳"，同步逻辑不变

## 自测

1. **MDI 为什么需要 `IDR_MAINFRAME` 和 `IDR_MDITYPE` 两套资源？各在什么时机生效？**
   —— 外壳框架 `LoadFrame(IDR_MAINFRAME)` 时用第一套（外壳菜单/加速键/标题）；子窗口激活时框架自动把菜单换成 `IDR_MDITYPE` 的文档菜单，文档的 9 字段串也从同 ID 的 STRINGTABLE 解析。没有子窗口时显示外壳菜单。

2. **`OnCreateClient` 的 `CCreateContext*` 参数是干什么的？丢了会怎样？**
   —— 它携带模板装配时的"文档↔视图"绑定，`CreateView` 靠它让视图 `GetDocument()` 拿到文档。传 `NULL` 视图照样创建，但文档指针为空，一访问就崩——必须原样转发。

3. **左视图改变选中项后，右视图是怎么知道的？**
   —— 左视图把选中下标写进文档（`m_sel`），调 `UpdateAllViews(this, HINT_SEL)` 广播（排除自己）；右视图在 `OnUpdate` 里按提示从文档读选中项详情刷新编辑框。

4. **`CreateStatic` 和 `CreateDynamic` 怎么选？**
   —— 分栏固定、每格是不同视图类（左列表右详情）用 `CreateStatic`；需要用户拖出/关掉窗格、每格同类视图用 `CreateDynamic`。绝大多数布局需求是前者。

5. **MDI 的初始化为什么不能照抄 SDI 的 `ProcessShellCommand`？**
   —— MDI 的外壳和文档是分开的：先 `new CMainFrame` + `LoadFrame(IDR_MAINFRAME)` + `ShowWindow` 造外壳，再 `OnFileNew()` 造第一个文档（框架按模板反射创建文档+子框架+视图）。`ProcessShellCommand` 是 SDI 单框架流程的封装。

---
上一章：[15 Doc/View 架构](15-docview.md) ｜ 下一章：[17 序列化与文件格式](17-serialize.md)
