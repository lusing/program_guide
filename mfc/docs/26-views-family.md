# 26 · 视图家族：ScrollView / FormView / ListView / RichEditView

> 对应示例：`examples/26_views_family`

> **本章你将学会**：CView 四个常用派生类各自的定位与用法、SDI 运行时切换视图的标准三步、为什么“文档不动、视图随便换”。
> **前置知识**：第 15 章的 Doc/View 架构、第 07 章的 CListCtrl、第 06 章的 DDX。

《Visual C++ MFC 编程实例》第 8 章用六个例子把“视图”这个概念拆开了：滚动视图（例 32）、改变鼠标光标（例 33）、沙漏光标（例 34）、窗体视图（例 35）、列表视图（例 36）、动态分割（例 37）。扩展编程实例第 12 章又从应用程序角度补了文本编辑器和 RTF 编辑器两个完整实例。本章把这些归拢成一张“视图选型表”，并用一个可以**运行时切换四种视图**的示例贯穿。

## 1. 为什么要分视图类

第 15 章说过：文档管数据，视图管显示。但“显示”二字底下藏着完全不同的活：

- 大画布上自由作画 → `CScrollView`：给你滚动条和虚拟坐标系
- 像填表单一样编辑数据 → `CFormView`：对话框模板直接当视图
- 行列结构的数据 → `CListView`：内嵌一个报表样式 `CListCtrl`
- 带格式文本 → `CRichEditView`：内嵌 `CRichEditCtrl`

它们的继承关系值得看一眼：

```text
CView
├── CScrollView            ← 滚动逻辑（映射模式 + 视口原点）
│   └── CFormView          ← 窗体视图本质是"会滚动的对话框"
└── CCtrlView              ← "视图 = 一个控件铺满"的通用思路
    ├── CEditView          ├── CListView
    ├── CRichEditView      └── CTreeView
```

`CCtrlView` 这一支的思路很优雅：**控件即视图**。MFC 把子控件创建、大小跟随、通知转发全包了，你只面对一个视图类的接口。

## 2. CScrollView：虚拟画布

不滚动的 CView 里，你只能在客户区分辨率那么大的地方画。CScrollView 的做法是在 `OnInitialUpdate` 里声明一块**逻辑画布**：

```cpp
void OnInitialUpdate() override {
    CScrollView::OnInitialUpdate();
    SetScrollSizes(MM_TEXT, CSize(1200, 900));   // 逻辑尺寸，与窗口多大无关
}
```

之后 `OnDraw` 拿到的 CDC 已经被框架设置了视口原点——画 (30, 700) 的内容，用户滚到底就能看见，你**完全不用管滚动条**。示例 26 的滚动视图画了一张 1200×900 的条目表，窗口只有 800×560，拖滚动条就能看到画布外。

两个实用细节：

- **滚到指定位置**用 `ScrollToPosition(CPoint(x, y))`；`GetScrollPosition()` 反查。
- 老书例 33/34（鼠标光标变沙漏）在今天有更省事的替代：耗时前 `CWaitCursor wait;`，作用域结束自动还原。

## 3. CFormView：对话框即视图

数据录入界面用 CFormView 最快：**写一个对话框模板（无 OK/Cancel，`WS_CHILD`），派生 CFormView，DDX 照用**：

```cpp
class CItemFormView : public CFormView {
    DECLARE_DYNCREATE(CItemFormView)
public:
    CItemFormView() : CFormView(IDD_FORM_VIEW) {}
    void DoDataExchange(CDataExchange* pDX) override {
        DDX_Text(pDX, IDC_FORM_NAME, m_name);
        DDV_MinMaxInt(pDX, m_points, 0, 100);   // 校验宏照常工作
    }
    ...
};
```

三个容易踩的点（示例 26 都演示了）：

1. `OnInitialUpdate` 里先 `GetParentFrame()->RecalcLayout()` 再 `ResizeParentToFit(FALSE)`——让框架窗口适配模板尺寸，否则打开时视图区可能比模板大/小一截。
2. 按钮点击是普通 `ON_BN_CLICKED`，**没有 OnOK/OnCancel**——窗体视图不是对话框，没有“确定关闭”这个概念。
3. 要改数据时记得 `UpdateData(TRUE)` 拉取控件值（校验失败 MFC 会自动弹提示并返回 FALSE）。

## 4. CListView：内嵌报表

`CListView` 自带一个 `CListCtrl`，`GetListCtrl()` 取用。第 07 章学的列、行、`LVS_EX_FULLROWSELECT`、`LVN_*` 通知全部适用。视图化后的差别在于**同步时机**：实现 `OnUpdate`，文档一变就重填——

```cpp
void OnUpdate(CView* /*pSender*/, LPARAM /*lHint*/, CObject* /*pHint*/) override {
    FillList();          // 文档变了：任何视图改的，这里都会被通知
}
```

`OnUpdate` 是 Doc/View 的广播终点站：任何视图调 `UpdateAllViews`，所有**其他**视图的 OnUpdate 都会被触发。示例 26 里窗体视图“添加”一条，列表视图和滚动视图同时刷新，靠的就是这条链。

## 5. CRichEditView：带格式的文本

富文本视图内嵌 `CRichEditCtrl`，是老书“RTF 编辑器”实例（扩展书实例 42）的地基。三件事必须知道：

1. **`AfxSocketInit` 同款前置**：`InitInstance` 里必须先 `AfxInitRichEdit2()`，忘了它视图一片空白且不报错。
2. 格式靠 `CHARFORMAT2`：先 `SetSel` 再 `SetSelectionCharFormat`，对“当前选区”上色/改字号（示例 26 的报告是分段设色画出来的）。
3. `GetRichEditCtrl().SetReadOnly(TRUE)` 把它当报表用——读侧场景比写侧常见得多。

## 6. 运行时切换视图（SDI）

老书例 37 讲的是动态分割；今天更常见的需求是“视图菜单里换一种看数据的方式”。SDI 的标准做法三步（示例 26 的 `CMainFrame::SwitchToView`）：

```cpp
void CMainFrame::SwitchToView(int idx) {
    CView* pOld = GetActiveView();

    CCreateContext cx;
    cx.m_pNewViewClass = kViewClasses[idx];      // 目标视图的 CRuntimeClass
    cx.m_pCurrentDoc = pOld->GetDocument();      // 新视图接到同一份文档

    CView* pNew = static_cast<CView*>(kViewClasses[idx]->CreateObject());
    pNew->Create(nullptr, nullptr, AFX_WS_DEFAULT_VIEW, CRect(0, 0, 0, 0),
                 this, AFX_IDW_PANE_FIRST, &cx); // create context 会触发 AddView
    pNew->OnInitialUpdate();
    SetActiveView(pNew);
    pOld->DestroyWindow();     // OnDestroy -> RemoveView，文档引用计数不泄漏
    RecalcLayout();
}
```

四个要点：

- `AFX_IDW_PANE_FIRST` 是视图在框架里的标准 ID（切分窗口的第 0 窗格也用它），**换视图必须还用这个 ID**，否则框架的激活/布局链就断了。
- 新视图 `Create` 时传 `CCreateContext`，`CView::OnCreate` 内部会调 `pDoc->AddView`——这是文档侧登记。
- 旧视图 `DestroyWindow`，其 `OnDestroy` 里自动 `RemoveView`——一加一减，`CDocument` 的视图计数才平衡。漏了销毁是内存泄漏，漏了登记是“文档变了视图不刷”。
- 菜单上用一组 `ON_UPDATE_COMMAND_UI` + `SetRadio` 打单选点（第 27 章细说）。

MDI 下不需要这套体操：多个 `CMultiDocTemplate` 或 `OpenDocumentFile` 各开各的子窗口就行（第 16 章的做法）。

## 7. 选型速查

| 需求 | 视图 | 关键调用 | 老书出处 |
|---|---|---|---|
| 大画布/自由绘制 | CScrollView | SetScrollSizes | 编程实例 例 32 |
| 表单录入 | CFormView | DDX + ResizeParentToFit | 例 35 |
| 行列数据 | CListView | GetListCtrl + OnUpdate | 例 36 |
| 格式文本/报表 | CRichEditView | CHARFORMAT2 + AfxInitRichEdit2 | 扩展书 实例 42 |
| 纯文本编辑 | CEditView | 免费得到复制粘贴查找 | 记事本的原料 |
| 树形数据 | CTreeView | GetTreeCtrl | 资源管理器的样子 |

## 实战建议

- 视图切换做“查看方式”功能时，把当前视图索引存进 `CWinApp` 的 profile（第 13 章），下次启动恢复用户的选择。
- `CFormView` 的模板在高 DPI 下会跟着系统缩放，但**手工 Create 的控件不会**——两章后（第 28 章的对话条）会再遇到这个问题的变体。
- 视图类都要 `DECLARE_DYNCREATE`/`IMPLEMENT_DYNCREATE`——Doc/View 框架靠运行时类信息反射创建视图，少了它模板挂不上。

## 常见坑（实测）

1. **忘了 `AfxInitRichEdit2()`**：CRichEditView 空白，无任何报错——排查方向压根想不到入口。
2. **CFormView 模板带了 OK 按钮**：运行时按回车触发 OnOK → `EndDialog`……实际上 CFormView 没有 EndDialog 可走，行为是按钮按下没反应或直接断言；模板里干脆别放。
3. **切换视图后不 RecalcLayout**：新视图尺寸保持旧视图的残留布局，表现为客户区错位、滚动条悬浮。
4. **`OnUpdate` 里用 `Invalidate()` 而非 `Invalidate(FALSE)`**：闪烁明显——擦背景 + 重绘两次代价，绘制密集的视图（滚动视图画大表）尤其扎眼。
