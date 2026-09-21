# 07 · 常用控件深入

> 对应示例：`examples/07_controls`

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
| 列表控件 | `CListCtrl` | 报表/图标视图 | 见下文（本章重点） |
| 树控件 | `CTreeCtrl` | 层级数据 | `InsertItem`（带 hParent） |

编辑框常用样式：`ES_MULTILINE`（多行）、`ES_AUTOHSCROLL`（横向续写）、`ES_PASSWORD`（密文）、`ES_READONLY`、`ES_NUMBER`（只收数字）。多行编辑框显示内容注意换行符是 **`\r\n`**。

## 2. CListCtrl 报表视图：最有用也最常用

"表格"就是它。四步搭起来：

```cpp
m_list.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT,
              CRect(0, 0, 0, 0), this, IDC_LIST);
m_list.SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);

m_list.InsertColumn(0, _T("任务名"), LVCFMT_LEFT, 220);   // 列
m_list.InsertColumn(1, _T("优先级"), LVCFMT_CENTER, 90);

int row = m_list.InsertItem(index, _T("编写需求文档"));   // 行（第 0 列）
m_list.SetItemText(row, 1, _T("高"));                     // 子项（第 n 列）
```

常用扩展样式：`LVS_EX_FULLROWSELECT`（整行选中）、`LVS_EX_GRIDLINES`（网格线）、`LVS_EX_CHECKBOXES`（行复选框）。

### 2.1 行数据挂在 lParam 上

列表显示的字符串只是投影，**结构化数据挂在每行的 `lParam`**：

```cpp
struct ItemData { CString name; int priority; };

auto* data = new ItemData{ name, priority };
int row = m_list.InsertItem(LVIF_TEXT | LVIF_PARAM, index,
                            name, 0, 0, 0, (LPARAM)data);
```

读取：`GetItemData(row)` 取回指针。**删除行时记得释放**，否则内存泄漏：

```cpp
delete reinterpret_cast<ItemData*>(m_list.GetItemData(row));
m_list.DeleteItem(row);
```

### 2.2 点击列头排序

```cpp
// 消息映射
ON_NOTIFY(LVN_COLUMNCLICK, IDC_LIST, OnColumnClick)

afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult) {
    auto* pNM = reinterpret_cast<NMLISTVIEW*>(pNMHDR);
    m_sortCol = pNM->iSubItem;
    m_sortAsc = !m_sortAsc;
    m_list.SortItems(CompareProc, reinterpret_cast<LPARAM>(this));
    *pResult = 0;
}

// 比较函数必须是静态的（系统回调不能带 this），this 从第三参进来
static int CALLBACK CompareProc(LPARAM lhs, LPARAM rhs, LPARAM self) {
    auto* wnd = reinterpret_cast<CControlsWnd*>(self);
    auto* a = reinterpret_cast<ItemData*>(lhs);
    auto* b = reinterpret_cast<ItemData*>(rhs);
    int cmp = ...;
    return wnd->m_sortAsc ? cmp : -cmp;
}
```

**`SortItems` 回调里拿到的是两行的 lParam（不是行号）**——这就是为什么文本也要存进 ItemData。这是 CListCtrl 最经典的坑。

### 2.3 右键上下文菜单

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

    int cmd = menu.TrackPopupMenu(TPM_LEFTALIGN | TPM_RIGHTBUTTON |
                                  TPM_RETURNCMD, point.x, point.y, this);
    if (cmd == IDM_DELETE) DeleteSelected();  // TPM_RETURNCMD：直接返回命令 ID
}
```

`TPM_RETURNCMD` 比"设置菜单再等 WM_COMMAND"的写法简单得多，优先用它。

### 2.4 选中项操作

```cpp
int row = m_list.GetNextItem(-1, LVNI_SELECTED);   // 首个选中行，-1 表示无
CString text = m_list.GetItemText(row, 1);         // 读子项文本
m_list.DeleteAllItems();                            // 清空（先释放 lParam！）
```

## 3. CTreeCtrl 要点

树控件用句柄 `HTREEITEM` 逐层插入：

```cpp
HTREEITEM root = m_tree.InsertItem(_T("工程"), TVI_ROOT);
HTREEITEM dir  = m_tree.InsertItem(_T("src"), root);      // 挂在 root 下
m_tree.InsertItem(_T("main.cpp"), dir);
m_tree.Expand(root, TVE_EXPAND);
```

数据同样挂 `SetItemData(hItem, dwData)`。常用通知：`TVN_SELCHANGED`（选择变化）、`NM_RCLICK`（右键）、`TVN_ITEMEXPANDED`（展开/折叠）。

## 4. 其他常用操作

**CEdit 追加日志**（多行、自动滚到底）：

```cpp
CString text;
m_log.GetWindowText(text);
if (!text.IsEmpty()) text += _T("\r\n");
text += line;
m_log.SetWindowText(text);
m_log.LineScroll(m_log.GetLineCount());
```

**CComboBox 下拉列表**：`CBS_DROPDOWNLIST`（只选不可输）、`CBS_DROPDOWN`（可输可选）、`CBS_SORT`（自动排序）。选中的关联数据用 `SetItemData(index, dwData)`。

**滑块联动**：`ON_WM_HSCROLL()` 处理函数里区分 `pScrollBar == &m_slider`，再 `GetPos()` 更新显示。

## 5. 常见坑

**CListCtrl 行数大时卡**：超过几千行改用 `LVS_OWNERDATA`（虚拟列表），数据留在自己手里，按需提供——SetItemCountEx + LVN_GETDISPINFO。真实项目的表格多半要走这条路。

**SetItemText 后 lParam 丢了**：`InsertItem` 时用 `LVIF_TEXT|LVIF_PARAM` 一次带齐；分步设置时注意别被重置。

**对话框里的控件字体是老的**：对话框模板声明了 `FONT 9, "微软雅黑"` 就自动对；代码创建的控件要手动 `WM_SETFONT`（第 05 章）。

**后台线程直接调 m_list 的方法**：跨线程访问 UI 控件是未定义行为，一律 PostMessage 给 UI 线程代做（第 20 章）。

## 6. 实战建议

- 报表类界面优先想 `CListCtrl + lParam 数据 + 列头排序` 这三件套；够用再考虑引入虚拟列表
- 控件封装成自己的小类（继承 CListCtrl，内嵌排序/数据管理），主窗口只管拼装——第 25 章统计面板示范了简化版
- 调试控件状态时用 `SPY++` 看通知流，比断点猜测快

---
上一章：[06 对话框](06-dialogs.md) ｜ 下一章：[10 通用对话框与文件 IO](10-common-dialogs.md)
