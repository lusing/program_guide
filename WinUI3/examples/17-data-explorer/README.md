# 17-data-explorer（数据浏览器）

控件篇第三功能工程：SplitView 侧栏分类树 + 自制四列表格 + 卡片双视图 + FlipView 详情条，一个过滤管线喂三个视图。

## 承载章节

| 章 | 控件 | 在本工程的真实职责 |
|---|---|---|
| 17 | ListView | 四列表格（表头+行模板同栅格） |
| 18 | GridView/FlipView | 卡片视图切换 + 详情轮播（双向选中同步） |
| 19 | TreeView | 分类过滤（ItemInvoked） |
| 20 | 自制表格路线 | 无 DataGrid 的完整替代（20 章论点的实体） |

## 架构

```text
MainWindow
├── SplitView.Pane     TreeView（All/Documents/Images/Audio/Archives）
├── 过滤行             TextBox 子串过滤 + Cards 开关 + 计数行
├── Table(ListView)    四列模板（x:Bind FileItem）
├── Cards(GridView)    卡片模板（与 Table 共用 m_view，可见性互换）
├── Details(FlipView)  详情条（选中双向同步，m_syncing 防重入）
└── ApplyFilters()     类别 × 子串 → 单一 m_view → 三视图同刷
FileItem               runtimeclass（Name/Kind/Size/Date/Category，格式化前置）
FilesStore             静态数据集（4 类 10 行）
```

## 关键实现位

- **单一数据源**：m_view 一个向量喂三视图——过滤/排序改一处，列表卡片详情永远一致
- **空 AddedItems 守卫**：过滤 Clear 触发空集 SelectionChanged，`GetAt(0)` 前必须查 `Size()`（否则启动 stowed 崩溃，实测）
- **ToggleButton 无 Toggled 事件**（WMC0011）：用 Click
- **自制表格**：两份相同 ColumnDefinitions 即表格；列宽是契约

## 冒烟

```powershell
pwsh tools\ui-smoke\smoke-dataexplorer.ps1
```

四流程：tree（"3 items · Images"）/ filter（"1 items · 'jpg'"）/ cards（视图互换）/ flip（详情翻页）。tree/cards/flip 已验证，filter 流待输入抽奖补证。
