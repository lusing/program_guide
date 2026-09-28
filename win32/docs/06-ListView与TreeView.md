# 第 6 章 ListView 与 TreeView

> **本章回答的问题**：任务管理器的进程列表、资源管理器的文件树是怎么做的？ListView 的"列"和"子项"什么关系？`mask` 是什么、为什么漏写它 API 就"不生效"？`WM_NOTIFY` 和 `WM_COMMAND` 分什么工？
>
> **前置章节**：第 5 章（控件 = 窗口、控件 ID、事件路由）。
>
> **你将做出什么**：一个双栏浏览器面板（`examples/17_listview_treeview`）：左边报表视图文件列表，右边分类树，两边选择联动标题栏。

本章示例：`examples/17_listview_treeview/main.cpp`。

## 6.1 为什么需要它们：LISTBOX 的三个不够

第 5 章的 LISTBOX 只有一列纯文本。真实界面常需要：

1. **多列**（名称/大小/类型/修改时间……）——LISTBOX 做不到；
2. **图标**（每行前面的小图标、状态图标）——LISTBOX 要自己画；
3. **层级**（目录树、组织架构树）——LISTBOX 完全无能为力。

Win32 的回答是 **comctl32.dll 通用控件家族**：ListView（列表视图）负责 1 和 2，TreeView（树视图）负责 3。它们也是你第一次接触"以结构体 + 通知消息为 API 风格"的控件——比第 5 章的"发一个简单消息"复杂一档，但这个风格是所有现代控件的通用语言，值得花一章学透。

## 6.2 通用控件与 comctl32：先注册，再用

通用控件不在 user32 里，而在单独的 `comctl32.dll`。用之前要**注册**（通知 DLL 按需初始化）：

```cpp
#include <commctrl.h>

INITCOMMONCONTROLSEX icc = { sizeof(icc),
                             ICC_LISTVIEW_CLASSES | ICC_TREEVIEW_CLASSES };
InitCommonControlsEx(&icc);
```

`ICC_*` 标志按家族分组（`ICC_LISTVIEW_CLASSES` 覆盖 ListView 与 Header，`ICC_BAR_CLASSES` 覆盖工具栏/状态栏……）。漏了注册，控件类不存在，`CreateWindowExW` 直接失败——这是"控件创建不出来"的第一嫌疑人。

创建控件本体，与第 5 章同一个 `CreateWindowExW`，只是类名换成常量：

```cpp
HWND lv = CreateWindowExW(0, WC_LISTVIEWW, nullptr,
    WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS,
    10, 10, 380, 300, hwnd, (HMENU)(INT_PTR)IDC_LIST, hInst, nullptr);
```

ListView 的四种视图由样式决定：`LVS_REPORT`（报表，本章主角）、`LVS_LIST`（纵列）、`LVS_ICON`/`LVS_SMALLICON`（大小图标）。资源管理器右键菜单里"查看"切的就是这四种。

> 版本提示：要让控件长成现代样子（圆角选中、主题边框），程序需要嵌入 comctl32 6.0 的清单（manifest）。本教程示例走系统默认外观——机制正确为先，视觉锦上添花。

## 6.3 报表视图：列、项与子项

报表视图的数据模型是一张二维表：

```text
            列 0（主项）      列 1（子项）     列 2（子项）
行 0   ┌ readme.md      │ 2 KB          │ Markdown    ┐
行 1   │ build.ps1      │ 4 KB          │ 脚本         │
行 2   │ win32.exe      │ 64 KB         │ 应用程序     │
       └ 每行 = 一个 item（LVITEMW），主项文本 + 若干子项（iSubItem）┘
```

**第一步：插列**。`LVCOLUMNW` 描述一列，`LVM_INSERTCOLUMNW` 落位：

```cpp
LVCOLUMNW col = { .mask = LVCF_TEXT | LVCF_WIDTH };
const wchar_t* titles[] = { L"名称", L"大小", L"类型" };
const int widths[] = { 180, 80, 100 };
for (int i = 0; i < 3; ++i) {
    col.pszText = (LPWSTR)titles[i];
    col.cx = widths[i];
    SendMessageW(lv, LVM_INSERTCOLUMNW, i, (LPARAM)&col);
}
```

**第二步：插行（主项）**，**第三步：填子项**。都用 `LVITEMW`，区别在 `iSubItem`：

```cpp
LVITEMW it = { .mask = LVIF_TEXT | LVIF_IMAGE, .iItem = i, .iImage = i % 2 };
it.pszText = (LPWSTR)kFiles[i].name;
int idx = (int)SendMessageW(lv, LVM_INSERTITEMW, 0, (LPARAM)&it);   // 主项

LVITEMW si = { .mask = LVIF_TEXT, .iItem = idx, .iSubItem = 1 };
si.pszText = (LPWSTR)kFiles[i].size;
SendMessageW(lv, LVM_SETITEMW, 0, (LPARAM)&si);                     // 子项
```

### `mask`：字段开关（新手 90% 的"为什么不生效"在这）

`LVITEMW` 有十几个字段，`mask` 声明"这次调用哪些字段有效"：`mask` 里没写的字段**被静默忽略**——不报错、不生效。例如插行时忘了 `LVIF_IMAGE`，`iImage` 填得再对也没有图标。这个设计贯穿所有 comctl32 结构体（`TVITEMW`/`TCITEMW`/`LVCOLUMNW` 同理），是"赋值了却没反应"类 bug 的头号来源。**纪律：每次填结构体，先写 mask，再填 mask 点名的字段。**

顺手的现代惯例——整行选中（否则点"大小"列选不中行）：

```cpp
SendMessageW(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);
```

## 6.4 头标控件：报表视图的列头

报表视图顶部那条可拖宽、可点击排序的"列头"，本身就是一个通用控件——**头标控件（header，`WC_HEADERW`）**。平时你不需要自己创建它：ListView 报表视图内建了一个，一列对应一个头标项。需要跟它打交道的时候：

```cpp
HWND hdr = ListView_GetHeader(lv);        // 取 ListView 内建的头标（宏 = LVM_GETHEADER）

// 点列头排序：头标把点击发回给 ListView 的父窗口（WM_NOTIFY, LVN_COLUMNCLICK）
if (nm->code == LVN_COLUMNCLICK) {
    int col = ((NMLISTVIEW*)lParam)->iSubItem;
    SortByColumn(col);                    // 按该列排序 + 重插数据
}
```

两个值得知道的事实：

1. **列宽拖动是头标在干**：用户拖列头分隔线时头标发 `HDN_ITEMCHANGING`/`HDN_ITEMCHANGED`（挂在**头标自己的**父窗口——对内建头标来说即 ListView——的通知链上）。想让某列锁宽，拦 `HDN_ITEMCHANGING` 返回 TRUE；
2. **头标可以独立使用**：不配合 ListView、单独放在任意数据控件顶上（`HDM_INSERTITEMW` + `HDITEMW`，又是 mask 纪律），"排序指示箭头"给 `HDITEM.fmt` 设 `HDF_SORTUP`/`HDF_SORTDOWN` 即可（comctl32 5.80+）。参考库第 15 章对头标有整章参考，需要定制列头行为时查阅。

## 6.5 选中与通知：`LVN_ITEMCHANGED` 的成对触发

查选中行是"发消息问"：

```cpp
int sel = (int)SendMessageW(lv, LVM_GETNEXTITEM, (WPARAM)-1, LVNI_SELECTED);
// -1 = 无选中
LVITEMW it = { .mask = LVIF_TEXT, .iItem = sel, .pszText = buf, .cchTextMax = 128 };
SendMessageW(lv, LVM_GETITEMW, 0, (LPARAM)&it);      // 读出该行文本
```

选中**变化**的通知走 `WM_NOTIFY`（下一节详讲），通知码 `LVN_ITEMCHANGED`。一个必须知道的细节：**选从 A 换到 B 会触发两次**——一次报告"A 不再选中"（`uOldState` 有选中、`uNewState` 没有），一次报告"B 变为选中"。不区分就把刷新逻辑跑两遍，轻则浪费，重则闪烁。防御写法：

```cpp
case WM_NOTIFY: {
    LPNMHDR nm = (LPNMHDR)lParam;
    if (nm->idFrom == IDC_LIST && nm->code == LVN_ITEMCHANGED) {
        LPNMLISTVIEW nlv = (LPNMLISTVIEW)lParam;
        if (nlv->uNewState & LVIS_SELECTED) {     // 只认"新状态含选中"
            ShowSelection(hwnd);
        }
    }
    return 0;
}
```

## 6.6 ImageList：图标的公共仓库

行前小图标不是直接给控件塞 HICON，而是装进**图像列表（ImageList）**再整表挂给控件：

```cpp
HIMAGELIST icons = ImageList_Create(16, 16, ILC_COLOR32 | ILC_MASK, 0, 4);
ImageList_AddIcon(icons, LoadIconW(nullptr, IDI_APPLICATION));   // 索引 0
ImageList_AddIcon(icons, LoadIconW(nullptr, IDI_INFORMATION));   // 索引 1
SendMessageW(lv, LVM_SETIMAGELIST, LVSIL_SMALL, (LPARAM)icons);
```

挂上之后，`LVITEMW` 的 `iImage` 填**索引**即可。三个要点：

- **一个 ImageList 可以被多个控件共享**（示例里 TreeView 挂的就是同一个列表）；
- **销毁责任在创建者**：控件销毁不会替你销毁 ImageList，`WM_DESTROY` 里 `ImageList_Destroy(icons)`；
- 挂载点有三种：`LVSIL_SMALL`（小图标列）、`LVSIL_NORMAL`（大图标）、`LVSIL_STATE`（状态复选框位）。ListView 自带复选框开关：`LVS_EX_CHECKBOXES` 扩展样式。

## 6.7 TreeView：层级的世界

TreeView 的数据模型是树：每个节点（item）由 `HTREEITEM` 句柄标识，插入时指定父节点——**`hParent == nullptr` 就是根，指定某个节点就是它的孩子**：

```cpp
HTREEITEM InsertTreeItem(HWND tv, const wchar_t* text, int img, HTREEITEM parent) {
    TVINSERTSTRUCTW ins = {};
    ins.hParent = parent;                              // ★ 层级由它决定
    ins.item.mask = TVIF_TEXT | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    ins.item.pszText = (LPWSTR)text;
    ins.item.iImage = img;
    ins.item.iSelectedImage = img;                     // 选中时换图标（不用就同值）
    return (HTREEITEM)SendMessageW(tv, TVM_INSERTITEMW, 0, (LPARAM)&ins);
}

HTREEITEM fruit = InsertTreeItem(tv, L"水果", 0, nullptr);   // 根
InsertTreeItem(tv, L"苹果", 1, fruit);                        // 孩子
SendMessageW(tv, TVM_EXPAND, TVE_EXPAND, (LPARAM)fruit);      // 展开节点
```

常配样式：`TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT`（画层次线与 +/- 折叠钮）、`TVS_SHOWSELALWAYS`（失焦也保持高亮）。取选中节点用"先问句柄、再取文本"两步（`TVM_GETNEXTITEM` + `TVGN_CARET`，然后 `TVM_GETITEMW`），选择变化通知是 `TVN_SELCHANGEDW`。

节点可以携带自定义数据（`TVIF_PARAM` + `lParam` 存指针）——真实程序里树上挂的往往不是文本，而是"这个节点对应哪条业务数据"。

## 6.8 `WM_NOTIFY`：复杂通知的专用通道

第 5 章的 `WM_COMMAND` 把通知打包进两个整数——对"单击"够用，对"用户拖动了列宽/展开了某节点/开始编辑标签"这类**带上下文**的通知就装不下了。comctl32 控件改走 `WM_NOTIFY`：

```text
WM_COMMAND（简单通知）            WM_NOTIFY（结构体通知）
─────────────────────────        ─────────────────────────
wParam = ID | 通知码（挤一起）     lParam → NMHDR*（结构体指针）
lParam = 控件 HWND                 ├── hwndFrom：谁发的
返回值：基本不用                   ├── idFrom：它的 ID
                                  └── code：通知码（LVN_*/TVN_*/TCN_*）
                                  返回值：常用于表态（如 CDRF_*，第 11 章）
```

`NMHDR` 只是头部，实际结构体更长（`NMLISTVIEW`、`NMTREEVIEW`……都以 `NMHDR` 开头），所以处理代码的固定套路是"先按 `NMHDR*` 看 code，再强转成具体类型"——第 11 章 Custom Draw 的两阶段握手也走这条通道。

## 6.9 comctl32 的版本与通用协议

通用控件不是"Windows 的一部分"那么简单——它是一路随 IE/系统版本升级的独立 DLL，由此带来一整套**版本工程学**（参考库第 6/7 章的专题）。

**版本从哪来**。comctl32.dll 的版本史：4.00（Win95/NT4）→ 4.70（IE3）→ 4.71/4.72（IE4）→ 5.80/5.81（IE5/Win2000）。很多 API（如 `RBBS_USECHEVRON`、`TTM_ADJUSTRECT`）只在 4.71+ 存在。现代 Windows 上事情反而简单了：系统 comctl32.dll 停在 5.82，**带主题的 6.0 通过并行程序集（WinSxS）提供**——也就是 6.2 节"版本提示"里说的 manifest。老教材里的版本探测代码今天仍有价值（判断老系统降级），标准姿势是 DLL 导出的 `DllGetVersion` 而非文件版本号：

```cpp
// LoadLibrary + GetProcAddress("DllGetVersion")，填 DLLVERSIONINFO 后调
// 返回的 dwMajorVersion/dwMinorVersion 与 PACKVERSION(4,71) 这类宏比较
```

配套两个编译期开关：`_WIN32_IE` 宏决定头文件里"新 API"的可见范围（书里的老代码常见 `#define _WIN32_IE 0x0500` 再 `#include <commctrl.h>`，现代工程由 SDK 默认值覆盖）；结构大小常量（`HDITEM_V1_SIZE`、`PROPSHEETPAGEW_V1_SIZE` 等）用于与 4.00 老布局的**磁盘格式**互操作——新代码只需认识它们，不必使用。

**窗口类总表**。参考库第 7 章给出了全家族类名清单，本教程的分布：

| 类名常量 | 控件 | 讲解处 |
|---------|------|--------|
| `WC_LISTVIEWW` / `WC_HEADERW` | 列表视图 / 头标 | 本章 |
| `WC_TREEVIEWW` | 树视图 | 本章 |
| `TOOLBARCLASSNAMEW` / `STATUSCLASSNAMEW` / `TRACKBAR_CLASSW` / `TOOLTIPS_CLASSW` | 工具栏/状态栏/轨迹条/工具提示 | 第 7/9 章 |
| `PROGRESS_CLASSW` / `WC_TABCONTROL` | 进度条 / 选项卡 | 第 7 章 |
| `ANIMATE_CLASSW` | 动画 | 第 9 章 |
| `DATETIMEPICK_CLASSW` / `MONTHCAL_CLASSW` | 日期检出器 / 月历 | 第 9 章 |
| `UPDOWN_CLASSW` / `HOTKEY_CLASSW` / `WC_IPADDRESSW` / `WC_COMBOBOXEXW` | 增减数/热键/IP 地址/扩展组合框 | 第 8 章 |
| `REBARCLASSNAMEW` / `WC_PAGESCROLLERW` | Rebar / Pager | 第 10 章 |

（RichEdit 不在此列——第 7 章讲过它住在独立的 msftedit.dll。）

**三条跨控件的通用协议**：

1. **`WM_NOTIFY` 的字符集协商**：通用控件创建时会向父窗口发 `WM_NOTIFYFORMAT` 问"通知结构体用 ANSI 还是 Unicode"；父窗口不处理则 `DefWindowProc` 按窗口自身类型作答（`NFR_UNICODE`/`NFR_ANSI`）。还有一条对应的运行时消息 `CCM_SETUNICODEFORMAT` 可以中途切换——现代代码全 Unicode，一般不必碰；
2. **`WM_SYSCOLORCHANGE` 要转发**：用户改系统配色时系统只通知**顶层窗口**，通用控件收不到——顶层窗口要把它转发给各控件，否则工具栏按钮会保留旧配色（参考库第 6 章的明确警告）。这与第 7 章状态栏的 `WM_SIZE` 转发是同一条纪律；
3. **`NM_*` 通用通知族**：一组"任何控件都可能发"的通知——`NM_CLICK`/`NM_DBLCLK`/`NM_RCLICK`/`NM_RDBLCLK`（鼠标）、`NM_HOVER`、`NM_KEYDOWN`、`NM_RETURN`、`NM_SETFOCUS`/`NM_KILLFOCUS`、`NM_SETCURSOR`、`NM_RELEASEDCAPTURE`、`NM_OUTOFMEMORY`，以及 5.80+ 的 `NM_TOOLTIPSCREATED`（控件建好自己的 tooltip 时告知，参数里有它的句柄）。写 `WM_NOTIFY` 分发器时，控件专属码（`LVN_*`/`TVN_*`）之前先看一眼这些通用码，常能少写重复代码。

另有几个冷门但救急的通用函数（都在 comctl32）：`GetEffectiveClientRect`（扣除工具栏/状态栏后"真正可用的客户区"）、`ShowHideMenuCtl`（菜单勾选 ↔ 控件显隐一键联动）、`InitMUILanguage`/`GetMUILanguage`（指定控件 UI 语言，参考库第 6.5 节"通用控件的本地化支持"）。

## 6.10 完整示例解剖

`examples/17_listview_treeview/main.cpp` 四段结构：

1. **建列表**（`CreateList`）：插列 → 扩展样式 → 建 ImageList 挂 `LVSIL_SMALL` → 循环插行填子项；
2. **建树**（`CreateTree`）：共享同一个 ImageList → 插两级节点 → 展开第一棵子树；
3. **联动**（`ShowSelection`）：分别向两个控件查询选中，拼进窗口标题；
4. **通知分发**（`WM_NOTIFY`）：列表的 `LVN_ITEMCHANGED`（防成对触发）与树的 `TVN_SELCHANGEDW` 都调 `ShowSelection`；`WM_SIZE` 里两边各占半栏。

运行后：点击列表行或树节点，标题栏实时显示两侧的选择——一条 `WM_NOTIFY` 打通两类控件。

## 6.11 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| 控件创建不出来（返回 nullptr） | 忘了 `InitCommonControlsEx` | 6.2 |
| 填了 `iImage` 没图标 | `mask` 漏 `LVIF_IMAGE`，或忘挂 ImageList | 6.3/6.6 |
| 填了 `pszText` 文本没变 | `mask` 漏 `LVIF_TEXT` | 6.3（mask 纪律） |
| 选中一次代码跑两遍 | `LVN_ITEMCHANGED` 成对触发没过滤 | 6.5 |
| ImageList 泄漏 | 控件销毁不带走它 | `WM_DESTROY` 里 `ImageList_Destroy` |
| 子项写进了主项 | `iSubItem` 忘了设（0 = 主项） | 6.3 |
| 64 位下 ID 强转警告/错乱 | `(HMENU)1001` 直转 | `(HMENU)(INT_PTR)id` |
| 判断通知只看 code 不看来源 | 多个控件都发 `NM_CUSTOMDRAW` 等 | 先比 `idFrom` 再看 `code` |

## 6.12 小结

1. 通用控件住 comctl32：先 `InitCommonControlsEx` 注册家族，再 `CreateWindowExW` 建控件。
2. 报表模型 = 列（`LVCOLUMNW`）+ 行/子项（`LVITEMW` + `iSubItem`）；**mask 是字段开关，漏写即静默失效**。列头是头标控件（`ListView_GetHeader`），点列头排序走 `LVN_COLUMNCLICK`。
3. 图标走 ImageList（创建 → 挂载 → 按索引引用 → 自己销毁），可多控件共享。
4. TreeView 靠 `hParent` 组织层级，`HTREEITEM` 是节点句柄，`lParam` 可挂业务数据。
5. 简单通知走 `WM_COMMAND`，结构体通知走 `WM_NOTIFY`：先看 `NMHDR.code`，再强转具体类型；`NM_*` 是跨控件通用通知族。
6. comctl32 是独立演化的 DLL：老代码有 `_WIN32_IE`/`DllGetVersion`/结构大小常量的版本工程；`WM_SYSCOLORCHANGE` 与状态栏的 `WM_SIZE` 一样要父窗口转发。

## 6.13 动手练习

1. 给示例加第四列"修改日期"，用 `SYSTEMTIME` 拼出"2026-09-19"格式文本（提示：`GetLocalTime` + `swprintf_s`，字段含义第 21 章讲）。
2. 把树改成三级：水果 → 苹果 → "红富士/国光"，并把展开状态用 `TVM_GETNEXTITEM` + `TVGN_CHILD` 遍历打印出来。
3. 给列表开 `LVS_EX_CHECKBOXES`，在状态栏显示"已勾选 N 项"（提示：`LVM_GETSELECTEDCOUNT` 不行，它数的是选中不是勾选——逐行 `LVM_GETITEMSTATE` 查 `LVIS_CHECKEDMASK`，顺便体会查文档）。

---

上一章：[05 · 控件基础](05-控件基础.md) ｜ 下一章：[07 · 更多通用控件](07-更多通用控件.md) ｜ 返回：[目录](../Win32%20API开发指南.md)
