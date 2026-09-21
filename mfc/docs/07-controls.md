# 07 · 常用控件深入

> 对应示例：`examples/07_controls`

> **本章你将学会**：控件通知为什么分 `WM_COMMAND` 与 `WM_NOTIFY` 两条路、`CListCtrl` 四种视图风格与列宽自适应、`SortItems` 回调为什么拿不到行号、虚拟列表在什么规模下才值得上，以及右键菜单的 `TPM_RETURNCMD` 写法。
> **前置知识**：第 05 章的控件创建与 `ON_BN_CLICKED`、第 06 章的 DDX（本章会对照它讲 `GetDlgItem`）。

## 1. 控件速查

| 控件 | 类 | 典型用途 | 关键 API |
|---|---|---|---|
| 静态文本 | `CStatic` | 标签、说明 | `SetWindowText` |
| 编辑框 | `CEdit` | 输入、日志显示 | `GetWindowText`、`SetSel`、`LineScroll` |
| 按钮 | `CButton` | 命令、复选、单选 | `GetCheck/SetCheck` |
| 组合框 | `CComboBox` | 下拉选择 | `AddString`、`GetCurSel`、`SetCurSel` |
| 列表框 | `CListBox` | 简单列表 | `AddString`、`GetSelItems` |
| 滑块 | `CSliderCtrl` | 音量/透明度 | `SetRange`、`GetPos` |
| 进度条 | `CProgressCtrl` | 任务进度 | `SetRange`、`SetPos`、`StepIt` |
| 列表控件 | `CListCtrl` | 报表/图标视图 | 见第 3 节（本章重点） |
| 树控件 | `CTreeCtrl` | 层级数据 | `InsertItem`（带 hParent） |

编辑框常用样式：`ES_MULTILINE`（多行）、`ES_AUTOHSCROLL`（横向续写）、`ES_PASSWORD`（密文）、`ES_READONLY`、`ES_NUMBER`（只收数字）。多行编辑框显示内容注意换行符是 **`\r\n`**。

## 2. 控件通用机制：通知的两条路

控件向父窗口汇报，走的是两条不同的消息通道。分清楚它们，才知道该写哪个映射宏：

| | `WM_COMMAND` | `WM_NOTIFY` |
|---|---|---|
| 谁在用 | 按钮、编辑框、组合框、菜单 | 列表、树、日期、进度、工具栏等公共控件 |
| 通知码在哪 | `HIWORD(wParam)` | `((NMHDR*)lParam)->code` |
| 控件 ID 在哪 | `LOWORD(wParam)` | `((NMHDR*)lParam)->idFrom` |
| 附加数据 | 没有，只有 wParam/lParam 两个整数 | `NMHDR` 后面跟着控件专属的结构体 |
| MFC 宏 | `ON_BN_CLICKED` / `ON_EN_CHANGE` / `ON_CBN_*` | `ON_NOTIFY(code, id, fn)` |

`WM_COMMAND` 是老通道，两个整数塞不下多少信息，只能表达"哪个控件的什么事件"。`WM_NOTIFY` 把 `lParam` 变成一个结构体指针，**`NMHDR` 只是这个结构体的头三个字段**——`hwndFrom`（发通知的控件）、`idFrom`（控件 ID）、`code`（通知码）。

后面可以挂任意多字段：`NMLISTVIEW` 挂 `iItem`/`iSubItem`、`NMTREEVIEW` 挂新旧选中项、`LVN_GETDISPINFO` 挂一个可写的 `LVITEM`。这就是列表、树这类"信息量大"的控件必须走这条路的原因。处理函数签名也跟着变，`ON_NOTIFY` 的**必须带这两个参数**，且通常要把 `pNMHDR` 转成具体结构体才读得到有用字段（见第 3.3 节）：

```cpp
afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult);   // ON_NOTIFY
afx_msg void OnClickedAdd();                                    // ON_BN_CLICKED
```

`*pResult` 记得赋值——它对应 `WM_NOTIFY` 的返回值。

### `GetDlgItem` 和 DDX 是什么关系

DDX 是**批量双向同步**：一次 `UpdateData` 把一批控件和一批成员变量对齐。`GetDlgItem(id)` / `SetDlgItemText(id, s)` 则是**运行时按 ID 现取**——一次一个控件、一次一个值，没有方向语义，也不需要 `DoDataExchange`。DDX 内部走的也是这条路（`CDataExchange::PrepareCtrl` 最终就是 `GetDlgItem`）。

选择标准：**同一批控件要反复和成员变量对齐就用 DDX；只偶尔碰一下、或要调控件方法本身就用 `GetDlgItem` 或 `DDX_Control` 绑定的成员对象。**

## 3. CListCtrl 深入

### 3.1 四种视图风格

风格在 `Create` 时定死，`LVS_REPORT` 才支持列：

| 风格 | 样子 | 典型用途 |
|---|---|---|
| `LVS_ICON` | 大图标，文字在下方 | 文件浏览器"大图标" |
| `LVS_SMALLICON` | 小图标，文字在右侧 | 紧凑排列 |
| `LVS_LIST` | 小图标，单列多行 | 简单清单 |
| `LVS_REPORT` | 表头 + 列 + 行 | **表格（最常用）** |

下面全部按报表视图讲。四步搭起来：

```cpp
m_list.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT,
              CRect(0, 0, 0, 0), this, IDC_LIST);
m_list.SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);

m_list.InsertColumn(0, _T("任务名"), LVCFMT_LEFT, 220);   // 列
m_list.InsertColumn(1, _T("优先级"), LVCFMT_CENTER, 90);

int row = m_list.InsertItem(index, _T("编写需求文档"));   // 行（第 0 列）
m_list.SetItemText(row, 1, _T("高"));                     // 子项（第 n 列）
```

**扩展样式**（普通样式在 `Create` 给，扩展样式单独设）——`LVS_EX_FULLROWSELECT`（整行选中，不做的话只有第一列能点）、`LVS_EX_GRIDLINES`（网格线）、`LVS_EX_CHECKBOXES`（行复选框）、`LVS_EX_DOUBLEBUFFER`（双缓冲，行多时明显减少闪烁）。

**列宽自适应**：列宽填 `0` 会让列直接不可见，这是最常见的"我插了列怎么没显示"。要么给具体像素，要么让它自己量——`SetColumnWidth(col, LVSCW_AUTOSIZE)`（`-1`）按该列所有行的内容中最宽的算，`LVSCW_AUTOSIZE_USEHEADER`（`-2`）按"内容与表头文字"中较宽的算。两个常量都定义在 `CommCtrl.h`。注意**要在数据填完之后再调**，否则量的是空表，列宽会塌成一条缝。

### 3.2 行数据挂在 lParam 上

列表显示的字符串只是投影，**结构化数据挂在每行的 `lParam`**：

```cpp
struct ItemData { CString name; int priority; };

auto* data = new ItemData{ name, priority };
int row = m_list.InsertItem(LVIF_TEXT | LVIF_PARAM, index,
                            name, 0, 0, 0, (LPARAM)data);   // LVIF_PARAM 不能少
```

`LVIF_PARAM` 这个 flag 不能少——不带它，`lParam` 那一格不会被写进去，`GetItemData(row)` 取回的就是垃圾值。**删除行时记得释放**，否则内存泄漏：

```cpp
delete reinterpret_cast<ItemData*>(m_list.GetItemData(row));
m_list.DeleteItem(row);
```

### 3.3 排序：SortItems 的正确用法

点击列头触发 `LVN_COLUMNCLICK`（走 `WM_NOTIFY`），通知结构体是 `NMLISTVIEW`，`iSubItem` 就是被点的列号：

```cpp
// 消息映射
ON_NOTIFY(LVN_COLUMNCLICK, IDC_LIST, OnColumnClick)

afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult) {
    auto* pNM = reinterpret_cast<NMLISTVIEW*>(pNMHDR);
    m_sortCol = pNM->iSubItem;
    m_sortAsc = !m_sortAsc;
    // 第二参原样传给比较函数的第三参，用来把 this 送进去
    m_list.SortItems(CompareProc, reinterpret_cast<LPARAM>(this));
    *pResult = 0;
}
```

比较函数的签名是**固定的**，三个参数全是 `LPARAM`：

```cpp
static int CALLBACK CompareProc(LPARAM lhs, LPARAM rhs, LPARAM self) {
    auto* wnd = reinterpret_cast<CControlsWnd*>(self);   // 就是 SortItems 的第二参
    auto* a = reinterpret_cast<ItemData*>(lhs);
    auto* b = reinterpret_cast<ItemData*>(rhs);
    int cmp = (wnd->m_sortCol == 0) ? a->name.Compare(b->name)
                                    : a->priority - b->priority;
    return wnd->m_sortAsc ? cmp : -cmp;   // 负数在前、0 相等、正数在后
}
```

**三个必须记住的点**：

1. **`lhs`/`rhs` 是两行的 `lParam`，不是行号。** 系统只把当初存的 `lParam` 递给你——它不知道也不关心你存的是什么。所以**任何要用来排序的字段都必须冗余进 `ItemData`**，想排文本就得把文本也存一份。这是 `CListCtrl` 最经典的坑：在回调里写 `m_list.GetItemText(lhs, ...)`，把 `lParam` 当行号用，编译能过，排序结果完全错乱。
2. **比较函数必须是 `static` + `CALLBACK`**（`CALLBACK` 即 `__stdcall`）。系统回调没有 `this`，所以 `this` 只能靠 `SortItems` 的第二参显式送进去——这跟 `qsort` 的 `context` 参数是一个套路。
3. **`CListCtrl` 不提供稳定的排序**，相同键值的行相对顺序不保证。要稳定排序就自己在 `cmp == 0` 时用行号兜底。

### 3.4 右键上下文菜单

```cpp
ON_WM_CONTEXTMENU()

afx_msg void OnContextMenu(CWnd*, CPoint point) {
    int sel = m_list.GetNextItem(-1, LVNI_SELECTED);
    if (sel < 0) return;                    // 没选中不弹

    if (point.x == -1 && point.y == -1) {   // Shift+F10 键盘触发：坐标无效
        CRect rc;
        m_list.GetItemRect(sel, &rc, LVIR_BOUNDS);
        point = CPoint(rc.left + 40, rc.CenterPoint().y);
        m_list.ClientToScreen(&point);
    }

    CMenu menu;
    menu.CreatePopupMenu();
    menu.AppendMenu(MF_STRING, IDM_DELETE, _T("删除(&D)"));
    // TPM_RETURNCMD：直接返回命令 ID，省掉"等 WM_COMMAND"那一套
    int cmd = menu.TrackPopupMenu(TPM_LEFTALIGN | TPM_RIGHTBUTTON |
                                  TPM_RETURNCMD, point.x, point.y, this);
    if (cmd == IDM_DELETE) DeleteSelected();
}
```

### 3.5 选中项与虚拟列表

```cpp
int row = m_list.GetNextItem(-1, LVNI_SELECTED);   // 首个选中行，-1 表示无
CString text = m_list.GetItemText(row, 1);         // 读子项文本
m_list.DeleteAllItems();                            // 清空（先释放 lParam！）
```

`GetNextItem(-1, LVNI_SELECTED)` 是取选中行的标准写法（`-1` 表示"从头开始找"），多选时反复调它可以遍历全部选中行。

**行数上万时该上虚拟列表**。普通列表每行都要真建一个内部结构并复制一份字符串——插十万行就是十万次分配，插入慢、内存高。虚拟列表加 `LVS_OWNERDATA` 风格，用 `SetItemCountEx` 只告诉控件"我有多少行"，控件显示到哪一行就来问你那一行的文本：

```cpp
m_list.Create(WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_OWNERDATA, ...);
m_list.SetItemCountEx(n, LVSICF_NOINVALIDATEALL | LVSICF_NOSCROLL);

// ON_NOTIFY(LVN_GETDISPINFO, IDC_LIST, OnGetDispInfo)
auto* p = reinterpret_cast<NMLVDISPINFO*>(pNMHDR);
if (p->item.mask & LVIF_TEXT)   // 只填它这次问的字段
    _tcscpy_s(p->item.pszText, p->item.cchTextMax,
              RowText(p->item.iItem, p->item.iSubItem));
```

数据始终留在你自己的容器里，控件一个字节都不存。代价：**`InsertItem` / `DeleteItem` / `SortItems` 全部不适用**——行是你要多少给多少，增删排序都得动你自己的数据源，然后 `SetItemCountEx` + `RedrawItems` 让视图重画。

## 4. CTreeCtrl 要点

树控件用句柄 `HTREEITEM` 逐层插入：

```cpp
HTREEITEM root = m_tree.InsertItem(_T("工程"), TVI_ROOT);
HTREEITEM dir  = m_tree.InsertItem(_T("src"), root);      // 挂在 root 下
m_tree.InsertItem(_T("main.cpp"), dir);
m_tree.Expand(root, TVE_EXPAND);
```

`HTREEITEM` 是**不透明句柄，不是索引**——不能拿它做算术，也不能当数组下标。第 08 章会展开树控件（图标、`TVN_SELCHANGED`、节点数据）。

## 5. 其他常用操作

**CEdit 追加日志**：多行编辑框没有"追加"API，标准做法是读全文 → 接一行 → 写回，最后 `LineScroll(GetLineCount())` 滚到底（示例 `05_frame_layout` 与 `07_controls` 都用了这个套路）。注意换行符必须是 `\r\n`，只写 `\n` 在编辑框里不会换行。

**CComboBox**：`CBS_DROPDOWNLIST`（只选不可输）、`CBS_DROPDOWN`（可输可选）、`CBS_SORT`（自动排序）。选中的关联数据用 `SetItemData(index, dwData)`。

**滑块联动**：`ON_WM_HSCROLL()` 处理函数里区分 `pScrollBar == &m_slider`，再 `GetPos()` 更新显示。

## 常见坑

1. **`SortItems` 回调里把 `lParam` 当行号用**
   回调收到的是两行的 `lParam`，不是行号。写成 `m_list.GetItemText(lhs, ...)` 编译能过，排序结果全乱。要排序的字段必须冗余存进 `ItemData`（第 3.3 节）。

2. **`InsertItem` 时漏了 `LVIF_PARAM`，或 `InsertColumn` 的宽度传 0**
   前者让 `lParam` 那一格压根没被写入，`GetItemData` 取回垃圾值，解引用就崩（用 `LVIF_TEXT | LVIF_PARAM` 一次带齐）；后者让列**存在但看不见**，于是"我明明插了列"。宽度要么给像素值，要么填完数据后用 `LVSCW_AUTOSIZE_USEHEADER` 让它自己量。

3. **忘记 `SetExtendedStyle(LVS_EX_FULLROWSELECT)`**
   不加这一条，用户点在第 2 列上时整行不会高亮，选择行为看起来很怪。这是报表视图几乎必加的扩展样式。

4. **`DeleteAllItems` 后 `lParam` 指针悬空**
   `DeleteAllItems` 只清控件内部的行，**不会**替你 `delete` 那些 `ItemData`。清空前必须遍历 `GetItemCount()` 逐行 `FreeRowData`，否则整表数据泄漏。

5. **对话框里的控件字体是老的**
   对话框模板声明了 `FONT 9, "微软雅黑"` 就自动对；代码创建的控件要手动 `WM_SETFONT`（第 05 章）。

6. **后台线程直接调 `m_list` 的方法**
   跨线程访问 UI 控件是未定义行为，一律 `PostMessage` 给 UI 线程代做（第 20 章）。

## 实战建议

- 报表类界面优先想 **`CListCtrl` + `lParam` 挂数据 + 列头排序** 这三件套；够用再考虑引入虚拟列表
- **`ItemData` 的分配和释放收在一处**：写一对 `AllocRowData` / `FreeAllRows`，删除、清空、析构都走它。散在各处的 `delete` 早晚漏一处
- 控件封装成自己的小类（继承 `CListCtrl`，内嵌排序/数据管理），主窗口只管拼装——第 25 章统计面板示范了简化版
- 调试控件状态时用 **`SPY++`** 看通知流（它能把 `WM_NOTIFY` 的 `code` 解出来），比断点猜测快得多

## 自测

1. **`WM_COMMAND` 和 `WM_NOTIFY` 分别怎么带控件 ID 和通知码？** —— `WM_COMMAND` 用 `LOWORD(wParam)` 带 ID、`HIWORD(wParam)` 带通知码，没有附加数据；`WM_NOTIFY` 的 `lParam` 指向一个 `NMHDR` 开头的结构体，`idFrom` 是 ID、`code` 是通知码，`NMHDR` 后面还跟着控件专属字段。
2. **`SortItems` 的比较函数为什么必须把文本也存进 `ItemData`？** —— 因为回调拿到的两个参数是两行的 `lParam`，**不是行号**；系统不提供行号，所以任何排序键都必须在插入时冗余存进 `lParam`。
3. **`InsertColumn` 宽度传 0 会怎样？怎么让列宽自适应？** —— 列会存在但宽度为 0、完全看不见；填完数据后调 `SetColumnWidth(col, LVSCW_AUTOSIZE_USEHEADER)` 让它按内容与表头中较宽者自动量宽。
4. **虚拟列表（`LVS_OWNERDATA`）适合什么场景？代价是什么？** —— 适合上万行以上、且数据本来就存在自己容器里的场景，控件不复制任何数据；代价是 `InsertItem`/`DeleteItem`/`SortItems` 都不适用，增删排序要改自己的数据源再 `RedrawItems`。另外比较函数必须 `static`（系统回调不带 `this`），`this` 通过 `SortItems` 的第二参传进回调的第三个 `LPARAM`。

---
上一章：[06 对话框](06-dialogs.md) ｜ 下一章：[10 通用对话框与文件 IO](10-common-dialogs.md)
