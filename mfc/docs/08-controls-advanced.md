# 08 · 控件进阶：树、属性页与任务对话框

> 对应示例：`examples/08_controls_advanced`

> **本章你将学会**：`CTreeCtrl` 的句柄式操作、属性页模板为什么必须是 `WS_CHILD`、`SetWizardMode` 如何一键把属性表变向导、`CTaskDialog` 相比 `MessageBox` 多出什么，以及日期 / 进度 / 滑块三个控件的联动。
> **前置知识**：第 07 章的控件通知两条路（`WM_COMMAND` / `WM_NOTIFY`）、第 06 章的对话框与资源模板。

## 1. 树控件 CTreeCtrl

树和列表最大的差别是**层级**：每个节点挂在父节点下，`InsertItem` 返回一个 `HTREEITEM` 句柄，下次插入时拿它当父句柄。

```cpp
HTREEITEM root = m_tree.InsertItem(_T("工程"), TVI_ROOT);
HTREEITEM src  = m_tree.InsertItem(_T("src"), root);   // 挂在 root 下
m_tree.InsertItem(_T("main.cpp"), src);                 // 再挂一层
m_tree.Expand(root, TVE_EXPAND);
```

`InsertItem` 有几组重载，常用的三种：

| 形式 | 用途 |
|---|---|
| `InsertItem(文本, hParent)` | 最常用：文本 + 父句柄 |
| `InsertItem(文本, nImage, nSelectedImage, hParent)` | 带图标，需先 `SetImageList` |
| `InsertItem(TVIF_*, ...)` | 结构体式，一次给齐文本/图标/`lParam` |

**`HTREEITEM` 是不透明句柄，不是索引。** 不能对它做算术（`hItem + 1` 没有意义），也不能当数组下标，更不能用它跨 `DeleteAllItems` 存活——清空后所有旧句柄全部失效，跟 `CListCtrl` 的 `lParam` 指针一个道理。

节点的附加数据挂 `SetItemData(hItem, dwData)` / `GetItemData(hItem)`，存指针的话记得在 `DeleteAllItems` 前统一释放（第 07 章第 4 条坑）。

常用通知：

| 通知 | 触发时机 | 通知结构体 |
|---|---|---|
| `TVN_SELCHANGED` | 选中项变化 | `NMTREEVIEW`（`itemNew.hItem` 是新选中项） |
| `TVN_ITEMEXPANDED` | 展开 / 折叠 | `NMTREEVIEW` |
| `NM_RCLICK` | 右键点击 | `NMHDR` |

取选中项文本：

```cpp
afx_msg void OnTreeSelChanged(NMHDR* pNMHDR, LRESULT* pResult) {
    auto* pNMTV = reinterpret_cast<NMTREEVIEW*>(pNMHDR);
    CString text = m_tree.GetItemText(pNMTV->itemNew.hItem);   // 用句柄，不用索引
    SetWindowText(_T("选中：") + text);
    *pResult = 0;
}
```

树的样式在 `Create` 时给：`TVS_HASLINES`（节点间连线）、`TVS_HASBUTTONS`（带 +/- 展开按钮）、`TVS_LINESATROOT`（根节点也画线）。三个都加才像资源管理器。

## 2. 属性页与向导 CPropertySheet

`CPropertyPage` **继承自 `CDialog`**——所以第 06 章的对话框知识全部适用（`OnInitDialog`、DDX、`DoModal`）。`CPropertySheet` 则是一个容器，把若干个页装进带页签的窗口。

```cpp
CPage1 p1;  CPage2 p2;  CPage3 p3;      // 栈上，必须活到 DoModal 之后
CPropertySheet sheet(_T("三页向导"));
sheet.AddPage(&p1);
sheet.AddPage(&p2);
sheet.AddPage(&p3);
sheet.DoModal();
```

**属性表只存页对象的指针，不接管所有权。** 所以页对象必须比 `sheet.DoModal()` 活得久——放栈上、在 `DoModal` 之前 `AddPage`，是最省心的写法（示例就是这么做的）。写成 `new CPage1` 再 `AddPage` 而忘了 `delete`，就是一处泄漏。

### 2.1 属性页模板必须是 `WS_CHILD`

这是属性页最容易踩的坑。属性页模板**不是**一个独立窗口，它要被"嵌"进属性表，所以：

```rc
IDD_PAGE1 DIALOGEX 0, 0, 240, 120
STYLE DS_SETFONT | WS_CHILD | WS_VISIBLE | WS_CAPTION
FONT 9, "微软雅黑"
BEGIN
    LTEXT "这里放第一页的控件。", IDC_STATIC, 12, 12, 200, 10
END
```

- **必须有 `WS_CHILD`**，不能有 `WS_POPUP`——少了它，属性表创建时会直接断言失败（debug 版）或行为诡异（release 版）
- **不能有 `WS_SYSMENU` / `DS_MODALFRAME`**——页签和边框由属性表自己画
- 页签上的文字取自模板的 `CAPTION`，也可以 `m_psp.dwFlags |= PSP_USETITLE` 配 `SetTitle` 动态给

### 2.2 一键变向导

```cpp
sheet.SetWizardMode();     // 加这一行，属性表变向导
```

变完之后按钮从"确定 / 取消 / 应用"变成"上一步 / 下一步 / 完成"，页签消失。三个页的按钮可用性由每页的 `OnSetActive` 决定：

```cpp
BOOL CPage1::OnSetActive() {
    auto* sheet = DYNAMIC_DOWNCAST(CPropertySheet, GetParent());
    if (sheet && sheet->IsWizard())
        sheet->SetWizardButtons(PSWIZB_NEXT);          // 首页没有"上一步"
    return CPropertyPage::OnSetActive();
}
```

`PSWIZB_BACK` / `PSWIZB_NEXT` / `PSWIZB_FINISH` / `PSWIZB_DISABLEDFINISH` 是位标志，或起来用。**每次进页都会调 `OnSetActive`**，所以这是做"根据已填数据决定下一步能不能点"的正确位置——数据不合法就不给 `PSWIZB_NEXT`，比弹框拦截友好得多。

收结果有两个位置：`OnWizardFinish`（点"完成"时，返回 `TRUE` 才真的关闭）或 `OnWizardNext`（点"下一步"时，返回 `0` 继续、返回 `-1` 阻止翻页）。

`DoModal` 的返回值：**向导点"完成"返回 `IDOK`**——MFC 内部把按钮点击的控件 ID 直接当作返回值（`m_nModalResult = nID`），而属性表的标准按钮组就是 `{ IDOK, IDCANCEL, ID_APPLY_NOW, IDHELP }`，"完成"占的正是 `IDOK`。点"取消"或关窗口返回 `IDCANCEL`。

> 网上不少 MFC 老代码写 `if (sheet.DoModal() == ID_WIZARD_FINISHED)`。这个常量在当前 MFC 头文件里**并不存在**，编译不过；直接判 `IDOK` 即可。

## 3. 任务对话框 CTaskDialog

`MessageBox` 只能给"是 / 否 / 取消"三个按钮和一行文字。`CTaskDialog`（Vista 起可用）能装：主指令、内容、页脚、命令链接按钮、进度条、展开的详细信息、验证回调。

| 能力 | `MessageBox` | `CTaskDialog` |
|---|---|---|
| 按钮 | 固定几种组合 | 任意多个**命令链接**，各自带说明文字 |
| 图标 | 4 种 | 同左 + 盾牌（管理员）、警告底纹 |
| 页脚 | 无 | `SetFooterText` |
| 进度条 | 无 | `SetProgressBarRange/Pos` |
| 展开详情 | 无 | `SetExpandedInformation` |
| 关闭前校验 | 无 | `SetVerificationCallback` |

**两个必须记住的坑**：

1. **头文件是 `<afxtaskdialog.h>`**，不在 `<afxwin.h>` 里
2. **没有默认构造函数**——`CTaskDialog dlg;` 会报 `C2512`。必须用三参构造：

```cpp
CTaskDialog dlg(_T("内容"), _T("主指令"), _T("标题"));
dlg.SetMainIcon(TD_INFORMATION_ICON);
dlg.SetFooterText(_T("页脚说明"));
dlg.AddCommandControl(101, _T("直接删除"));
dlg.AddCommandControl(102, _T("移到回收站"));
INT_PTR cmd = dlg.DoModal();     // 返回被点中的命令 ID；取消返回 IDCANCEL
```

三个参数依次是**内容、主指令、标题**（顺序和直觉相反，标题在最后）。`DoModal` 的返回值就是你在 `AddCommandControl` 里给的 ID——这正是它比 `MessageBox` 好用的地方：每个选项有自己的语义 ID，不用把 `IDYES` 硬映射成业务含义。

## 4. 日期、进度与滑块

三个"数值型"控件，用法都简单，但各有各的通知方式。

**`CDateTimeCtrl`**（`<afxdtctl.h>`）：`SetTime` / `GetTime` 收发 `CTime`，`SetFormat` 改显示格式。通知是 `DTN_DATETIMECHANGE`。

```cpp
CTime now = CTime::GetCurrentTime();   // 注意：不能写 &CTime::GetCurrentTime()
m_date.SetTime(&now);                  // 返回的是临时对象，取地址是错的
```

**`CProgressCtrl`**：`SetRange32(0, 100)` + `SetPos(n)`，或 `StepIt()` 按步长前进。**只有它有 `SetRange32`。**

**`CSliderCtrl`**：`SetRange(0, 100)`（三参版第三参是 `bRedraw`，有默认值）、`SetPos` / `GetPos`、`SetTicFreq(n)`（每 n 个单位一格刻度，需 `TBS_AUTOTICKS` 样式）。**它没有 `SetRange32`**——两个控件的 API 名字很容易记混。

**联动**：滑块移动走的是 `WM_HSCROLL`，**不是** `WM_NOTIFY`：

```cpp
afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) {
    if (pScrollBar && pScrollBar->GetSafeHwnd() == m_slider.GetSafeHwnd())
        m_progress.SetPos(m_slider.GetPos());
    CDialog::OnHScroll(nSBCode, nPos, pScrollBar);   // 别忘基类
}
```

一个对话框里可能有好几个滚动条类控件（滑块、滚动条、微调按钮），它们**共用同一个 `OnHScroll`**，所以必须用第三参 `pScrollBar` 区分是谁在动。比较用 `GetSafeHwnd()` 而不是 `pScrollBar == &m_slider`——前者对"控件对象还没绑定"的情况也安全。

## 常见坑

1. **`CTaskDialog dlg;` 编译不过（C2512）**
   它没有默认构造函数，必须三参构造 `CTaskDialog dlg(内容, 主指令, 标题)`。头文件也要单独 `#include <afxtaskdialog.h>`。

2. **属性页模板忘了 `WS_CHILD`**
   属性表创建时断言失败或页签空白。属性页是子窗口，模板必须是 `WS_CHILD | WS_VISIBLE`，不能带 `WS_POPUP`（第 2.1 节）。

3. **`HTREEITEM` 当索引用**
   它是不透明句柄，不能做算术、不能当下标；`DeleteAllItems` 之后所有旧句柄失效，再用就是访问已释放的内存。跨"清空"保存句柄是典型的悬空 bug。

4. **页对象在 `DoModal` 之前就析构了**
   属性表只存指针不接管所有权。把 `CPage1` 声明在 `DoModal` 之后的作用域里，或者 `new` 了不 `delete`，前者崩溃后者泄漏。

5. **`CSliderCtrl` 上写 `SetRange32`**
   这个函数只存在于 `CProgressCtrl`。滑块用三参的 `SetRange(min, max, bRedraw)`。

6. **`OnHScroll` 里不判 `pScrollBar`**
   对话框里所有滚动条类控件共用这一个处理函数。不区分就会"动滑块把别的控件也改了"。

7. **`&CTime::GetCurrentTime()` 取临时对象地址**
   `GetCurrentTime` 按值返回，取地址是错的（编译报 C2102）。先落成具名 `CTime` 变量再取地址。

## 实战建议

- **树节点的数据用 `SetItemData` 存指针**，并在 `DeleteAllItems` 之前统一遍历释放；把这套收进一对 `AllocNode` / `FreeAllNodes`，别散在各处
- **向导的多页数据共享，靠 `CPropertySheet` 派生类的成员**——在 `AddPage` 之前把 `this` 传给各页，或者让各页 `GetParent()` 后 `DYNAMIC_DOWNCAST` 成自己的 sheet 类
- **"带操作选项的提示"一律用 `CTaskDialog`**：命令链接的文案可以写得很清楚（"移到回收站"比"是"信息量大得多），返回值还是你自己的业务 ID
- **属性页模板用 VS 资源编辑器画**：`WS_CHILD` 这种关键样式让编辑器保证，比手写 `.rc` 不容易漏

## 自测

1. **属性页模板为什么必须是 `WS_CHILD`？**
   —— 属性页不是独立窗口，它要被嵌进属性表当子窗口。带 `WS_POPUP` 或缺 `WS_CHILD` 会让属性表创建失败（debug 版直接断言），页签和边框由属性表自己画，所以模板里也不该有 `WS_SYSMENU` / `DS_MODALFRAME`。

2. **`CTaskDialog` 相比 `MessageBox` 强在哪？用的时候有哪两个必踩的坑？**
   —— 强在能装命令链接按钮（每个选项有自己的业务 ID 和说明文字）、页脚、进度条、展开详情、关闭前校验。两个坑：头文件在 `<afxtaskdialog.h>` 而不是 `<afxwin.h>`；没有默认构造函数，必须三参构造，否则报 C2512。

3. **滑块移动为什么要用 `OnHScroll` 而不是 `ON_NOTIFY`？处理函数里为什么必须判 `pScrollBar`？**
   —— 滑块是滚动条类控件，发的是 `WM_HSCROLL` 而不是 `WM_NOTIFY`。同一个对话框里所有滚动条类控件（滑块、滚动条、微调按钮）共用同一个 `OnHScroll`，所以必须用第三参 `pScrollBar` 判断是谁在动，否则会误改别的控件。

4. **`SetRange32` 是哪个控件的成员？另一个控件该用什么？**
   —— `SetRange32` 是 `CProgressCtrl` 的；`CSliderCtrl` 没有这个函数，用三参的 `SetRange(nMin, nMax, bRedraw = FALSE)`。

---
上一章：[07 常用控件深入](07-controls.md) ｜ 下一章：[09 自绘控件与自定义控件](09-custom-controls.md)
