# 第 10 章 Rebar 与属性页

> **本章回答的问题**：IE 那种"可以拖来拖去、能折叠出小箭头"的工具条是怎么搭的？设置对话框那种"多页标签框"（属性表）和向导界面是同一个控件吗？
>
> **前置章节**：第 7 章（工具栏/状态栏）、第 13 章（对话框过程——属性页就是对话框）。
>
> **你将做出什么**：一个 IE 风格的"可定制工具区" + 一个两页属性表 + 一个三步向导（`examples/35_rebar_propsheet`）。

本章示例：`examples/35_rebar_propsheet/main.cpp`。

> 本章素材参考《Win32 开发人员参考库·第 4 卷》第 6 章（IE 样式工具条/Rebar）、第 19 章（Pager）、第 21 章（属性页）与第 11 章（创建向导）。

## 10.1 容器型控件：工具条需要一个"壳"

第 7 章的工具栏是"贴死在窗口顶部"的。真实应用（IE、早期 VS/Office）的工具区要求更多：**多条带独立拖动、拖窄了出"»"折叠菜单、可显示/隐藏某条**。Win32 的答案是 **Rebar**——一个专门容纳工具条的**容器控件**：

```text
┌─ Rebar ─────────────────────────────────┐
│ ┰ [标准工具栏 band]      ┰ [地址栏 band] │   ┰ = 夹具（gripper）
└─────────────────────────────────────────┘
  每个 band = 夹具 + 子窗口（通常是工具栏）
```

参考库第 6 章讲得很直白：IE 工具条"实质上包含有由四个区段所组成的 Rebar 控件：三个工具条与一个菜单条"。本章顺带介绍它的两个亲戚：**Pager**（滚动容纳装不下的子窗口）和**属性页**（标签式多页对话框——逻辑上也是"一块区域多个内容页"的容器思想）。

## 10.2 Rebar 基础：band 的插入

Rebar 自己几乎不画东西，它的全部工作是管理 **band**。三步：建 Rebar → 建子控件 → 用 `REBARBANDINFOW` 登记 band：

```cpp
// ① 容器（RBS_BANDBORDERS 画 band 间分隔线，RBS_VARHEIGHT 允许各 band 高度不同）
HWND rebar = CreateWindowExW(WS_EX_TOOLWINDOW, REBARCLASSNAMEW, nullptr,
    WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
    | CCS_NODIVIDER | CCS_NOPARENTALIGN | RBS_BANDBORDERS | RBS_VARHEIGHT,
    0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_REBAR, hInst, nullptr);

// ② 一条普通工具栏（第 7 章的建法，尺寸给 0——由 band 决定）
HWND tb = CreateToolbarEx...   // 或 CreateWindowExW + TB_ADDBUTTONSW，见 7.2

// ③ 登记 band
REBARBANDINFOW rbi = { .cbSize = sizeof(rbi) };
rbi.fMask       = RBBIM_STYLE | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_SIZE;
rbi.fStyle      = RBBS_GRIPPERALWAYS;             // 总是显示夹具（默认仅在多 band 同行时显示）
rbi.hwndChild   = tb;
rbi.cxMinChild  = 0;   rbi.cyMinChild = 32;       // 子窗口的最小尺寸
rbi.cx          = 260;                            // band 初始宽度
SendMessageW(rebar, RB_INSERTBANDW, (WPARAM)-1, (LPARAM)&rbi);   // -1 = 追加
```

三个行为要点：

- **拖动是白送的**：用户按住夹具左右拖、整行拖动换行，Rebar 自动处理——你一行代码都不用写；
- **父窗口 `WM_SIZE` 要转发给 Rebar**（和第 7 章状态栏同一条纪律），它才跟着窗口变宽；
- 子窗口的高度变化、band 被用户拖没了，Rebar 发 `RBN_HEIGHTCHANGE`/`RBN_AUTOSIZE` 通知（`WM_NOTIFY`），需要联动重排客户区时处理。

## 10.3 IE 风格：人字形按钮与下拉按钮

**人字形按钮（chevron，"»"）**：band 被挤窄、工具栏有按钮显示不下时，Rebar 在 band 右端画一个 "»"。前提是 band 的 `fStyle` 带 `RBBS_USECHEVRON`；用户点它时发 `RBN_CHEVRONPUSHED`，你弹出菜单列出被挡住的按钮（参考库第 6.3.1 节给了完整的九步算法：`RB_GETRECT` 取 band 矩形 → `TB_GETITEMRECT` 逐个取按钮 → `IntersectRect`/`EqualRect` 找出被挡者 → `TrackPopupMenuW` 在 chevron 正下方弹出）。

配套的两个工具栏进阶样式（它们不属于 Rebar，但 IE 风格离不开）：

```cpp
// 下拉按钮：fStyle 用 BTNS_DROPDOWN——点击不执行命令，改发 TBN_DROPDOWN 让你弹菜单
TBBUTTON btn = { STD_UNDO, IDM_UNDO, TBSTATE_ENABLED, BTNS_DROPDOWN, {}, 0, (INT_PTR)L"撤销" };

// 平面样式 + 热跟踪：按钮平时无边框，悬停才"浮起"（IE/VS 的观感）
CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
    WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_LIST, ...);   // LIST：文字在图标右侧
```

- `BTNS_DROPDOWN`（点击弹菜单）/ `BTNS_WHOLEDROPDOWN`（整个按钮是箭头）：点击时工具栏发 `TBN_DROPDOWN`，你在 `NMTOOLBAR.rc` 拿到按钮矩形，`TrackPopupMenuW` 对齐其左下角；
- `TBSTYLE_FLAT`（平面+热跟踪）/ `TBSTYLE_LIST`（文字在右，按钮更矮）——两者组合即 IE 观感。热状态切换会发 `TBN_HOTITEMCHANGE`。

参考库第 6.4 章甚至演示了用"纯文本按钮的工具栏 + Rebar"自制**菜单条**（menubar）——鼠标热跟踪、点按钮弹菜单、F10/方向键键盘导航全要自己实现。这是理解"菜单也是 UI 约定而非魔法"的好练习，但工程上第 13 章的标准菜单仍是首选。

## 10.4 Pager：装不下就滚动

Pager 是个薄壳容器：子窗口比它大时，显示左右（或上下）滚动箭头，点箭头滚动**子窗口的可见区**。当年 IE 的"链接栏"就是它。用法极简：

```cpp
HWND pager = CreateWindowExW(0, WC_PAGESCROLLERW, nullptr,
    WS_CHILD | WS_VISIBLE | PGS_HORZ,          // PGS_HORZ 横向（默认纵向）
    0, 0, 200, 34, hwnd, (HMENU)(INT_PTR)IDC_PAGER, hInst, nullptr);

SendMessageW(pager, PGM_SETCHILD, 0, (LPARAM)toolbar);   // 唯一的"内容"
```

滚动的联动通知：`PGN_SCROLL`（用户点箭头，`NMPGSCROLL` 告诉你方向与建议步长，可改）与 `PGN_CALCSIZE`（问你要内容的理想尺寸，按需重算返回滚动范围）。有了 Rebar 的 `RBBS_USECHEVRON` 之后，新界面很少再用 Pager——知道它是"滚动版 Rebar"即可。

## 10.5 属性页：标签式设置对话框

"选项"对话框那种**标签框**不是 Tab 控件套对话框——它是**属性表（property sheet）**，一个独立的弹出窗口框架，由**多个属性页（property page）**组成，每页就是一个对话框模板。数据结构两级：

```cpp
#include <prpsht.h>    // 或 #include <commctrl.h> 已含

// 一页 = 一个对话框模板 + 一个对话框过程
PROPSHEETPAGEW psp[2] = {};
psp[0] = { .dwSize = sizeof(psp[0]), .dwFlags = PSP_DEFAULT | PSP_USETITLE,
           .hInstance = hInst,
           .pszTemplate = MAKEINTRESOURCEW(IDD_PAGE_GENERAL),   // 对话框模板资源
           .pszTitle = L"常规",
           .pfnDlgProc = GeneralPageProc };
psp[1] = { /* IDD_PAGE_ADVANCED, AdvancedPageProc ... */ };

// 框架
PROPSHEETHEADERW psh = { .dwSize = sizeof(psh) };
psh.dwFlags     = PSH_PROPSHEETPAGE | PSH_NOCONTEXTHELP;
psh.hwndParent  = hwnd;
psh.hInstance   = hInst;
psh.pszCaption  = L"设置";
psh.nPages      = 2;
psh.ppsp        = psp;

INT_PTR rc = PropertySheetW(&psh);    // 模态运行，直到用户关掉
```

页面的对话框过程**不是** `DialogBox` 的过程——它的通知走 `WM_NOTIFY`，四个最要紧的页通知：

| 通知 | 时机 | 你该干什么 |
|------|------|-----------|
| `PSN_INITDIALOG` | 页初始化 | 填控件初值（等价 `WM_INITDIALOG`） |
| `PSN_KILLACTIVE` | 将离开本页 | 校验本页输入；不合法则拒绝切换 |
| `PSN_APPLY` | 用户点了"应用/确定" | **把页面的值写回配置**（真正的提交点） |
| `PSN_RESET` | 用户点了"取消" | 丢弃未提交的修改 |

"确定/应用/取消"的语义由框架管理：**只有 `PSN_APPLY` 是提交点**——在 `PSN_KILLACTIVE` 里只做校验不落盘。拒绝离开某页（输入非法时）的写法是设置消息结果：

```cpp
case WM_NOTIFY:
    if (((NMHDR*)lParam)->code == PSN_KILLACTIVE) {
        if (!ValidPage(hwndDlg)) {
            MessageBoxW(hwndDlg, L"端口必须是数字", L"设置", MB_ICONWARNING);
            SetWindowLongPtrW(hwndDlg, DWLP_MSGRESULT, TRUE);   // TRUE = 不许切走
            return TRUE;
        }
    }
    return FALSE;
```

对话框过程里设置"消息结果"用 `SetWindowLongPtrW(hwndDlg, DWLP_MSGRESULT, ...)`——属性页通知的返回值都走这个通道（参考库第 21 章的"通告消息返回值"说明）。框架还提供 `PSM_SETTITLE`、动态增删页（`PSM_ADDPAGE`/`PSM_REMOVEPAGE`）、每页右上角帮助按钮（`PSH_HASHELP`）等，用到再查。

## 10.6 向导：属性页的另一张皮

向导（wizard）——"下一步 → 下一步 → 完成"——**是属性页换张皮**（参考库第 11 章的标题就叫"创建向导"）。差异只在框架标志与按钮语义：

```cpp
psh.dwFlags = PSH_PROPSHEETPAGE | PSH_WIZARD97     // 或 PSH_WIZARD（朴素外观）
            | PSH_HEADER | PSH_WATERMARK;          // WIZARD97 的页眉/水印（要给位图句柄）
```

向导模式下每页：

- 不显示标签，"上一步/下一步"代替了页间切换。**由你在每页 `PSN_SETACTIVE` 时声明可用按钮**：

```cpp
if (((NMHDR*)lParam)->code == PSN_SETACTIVE) {
    PropSheet_SetWizButtons(hwndDlg, PSWIZB_BACK | PSWIZB_NEXT);   // 第一页别给 BACK
    return TRUE;
}
```

- `PSN_WIZNEXT`（点了下一步）/ `PSN_WIZBACK`：校验并控制去向——把 `DWLP_MSGRESULT` 设成目标页对话框句柄可跳页（如"跳过可选步骤"）；
- 最后一页用 `PSWIZB_FINISH`；`PSN_WIZFINISH` 里做提交（等价普通表的 `PSN_APPLY`）。

参考库第 11 章的完整示例（向导应用程序实例）演示了标题字体、完成页等细节。工程提示：向导的每一页仍是普通对话框模板——第 13 章的资源脚本功夫全部适用。

## 10.7 完整示例解剖

`examples/35_rebar_propsheet/main.cpp` 的三段：

1. **Rebar 工具区**：两条 band——标准图像工具栏（`TBSTYLE_FLAT`，一条按钮带 `BTNS_DROPDOWN` 弹菜单）+ 一条编辑框"地址栏"（`RBBS_USECHEVRON`，拖窄后点 » 弹菜单）；父窗口 `WM_SIZE` 转发给 Rebar；`RBN_CHEVRONPUSHED` 用"矩形相交"法找出被挡按钮弹菜单；
2. **属性表**："设置"菜单打开两页属性表（页模板用代码在内存中拼装——`PSP_DLGINDIRECT`，免资源文件）；`PSN_APPLY` 把值写进状态栏展示；
3. **向导**："新建"菜单打开三页向导（`PSH_WIZARD`，第一页无 BACK、末页 FINISH，中间页 `PSN_WIZNEXT` 校验非空）。

## 10.8 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| Rebar 里的工具栏点不动/漏画 | 容器少了 `WS_CLIPCHILDREN`/`WS_CLIPSIBLINGS` | 10.2（容器样式的固定搭配） |
| band 显示但拖不动 | 没有夹具（`RBBS_GRIPPERALWAYS` 或空间不足） | 10.2 |
| Rebar 不随窗口变宽 | 父窗口 `WM_SIZE` 没转发 | 10.2（同状态栏纪律） |
| chevron 从不出现 | band 没设 `RBBS_USECHEVRON`，或没被挤窄 | 10.3 |
| 下拉按钮点了没菜单 | 按钮是 `BTNS_DROPUP`... 是 `BTNS_DROPDOWN` 但没处理 `TBN_DROPDOWN` | 10.3 |
| 属性页通知的返回值不生效 | `return TRUE` 之外忘了 `SetWindowLongPtrW(DWLP_MSGRESULT, ...)` | 10.5（双保险都要） |
| "应用"点了没保存 | 把写回逻辑放在 `PSN_KILLACTIVE` | 提交点只有 `PSN_APPLY`（10.5） |
| 向导每页按钮全亮 | 没在 `PSN_SETACTIVE` 里设按钮集 | 10.6 |
| 向导页校验形同虚设 | 只处理了 `PSN_WIZNEXT` 没拦 | 拒绝时 `DWLP_MSGRESULT = -1`（10.6） |

## 10.9 小结

1. Rebar = band 容器：`REBARBANDINFOW`（mask 纪律又来了）+ `RB_INSERTBANDW`；拖动/换行/收缩白送，`WM_SIZE` 要转发。
2. IE 风格三件套：`RBBS_USECHEVRON` + `RBN_CHEVRONPUSHED`（» 菜单）、`BTNS_DROPDOWN` + `TBN_DROPDOWN`（下拉按钮）、`TBSTYLE_FLAT | TBSTYLE_LIST`（平面+热跟踪）。
3. Pager 是"滚动壳"（`PGM_SETCHILD` 一条消息完成收养），现代界面多被 chevron 取代。
4. 属性表两级结构：`PROPSHEETHEADERW`（框架）+ `PROPSHEETPAGEW[]`（页=对话框模板+过程）；通知走 `WM_NOTIFY`，**提交点只有 `PSN_APPLY`**，返回值走 `DWLP_MSGRESULT`。
5. 向导 = 属性表 + `PSH_WIZARD*`：每页 `PSN_SETACTIVE` 声明按钮，`PSN_WIZNEXT/WIZFINISH` 做校验与提交。

## 10.10 动手练习

1. 给示例 Rebar 增加第三个 band（放第 9 章的 DTP），`RBBIM_TEXT` 给 band 加标题文字，验证 `RBBS_NOGRIPPER` 的效果。
2. 给属性表加第三个"关于"页（`PSP_USETITLE` 命名），并实现 `PSH_HASHELP` + `PSN_HELP` 弹出帮助。
3. 挑战：把向导中间页做成"校验失败不许下一步"（`DWLP_MSGRESULT = -1`），并在末页 `PSN_WIZFINISH` 里把三页收集的值拼成摘要弹窗——一个真正可用的安装向导骨架。

---

上一章：[09 · 日期时间与反馈控件](09-日期时间与反馈控件.md) ｜ 下一章：[11 · 自绘与子类化](11-自绘与子类化.md) ｜ 返回：[目录](../Win32%20API开发指南.md)
