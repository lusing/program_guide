# 27 · 菜单深入：动态、系统菜单、上下文菜单与 owner-draw

> 对应示例：`examples/27_menus_advanced`

> **本章你将学会**：运行时增删改菜单项、复选/单选/禁用的更新机制、系统菜单与上下文菜单、owner-draw（自绘）菜单的完整回调链。
> **前置知识**：第 03 章的消息映射与命令路由、第 04 章的资源文件。

第 04 章把静态菜单（.rc 里写死的那套）讲完了。《Visual C++ MFC 编程实例》第 6 章的例 14–21 全部发生在**运行时**：根据状态动态改变菜单、启用禁用、复选单选、动态修改、改系统菜单、触发菜单命令、弹出式菜单；扩展编程实例实例 11 又加了“带位图的菜单”。本章示例 27 把这些一次性装进一个程序。

## 1. 状态三件套：复选、单选、禁用

菜单项的勾/点/灰不是“设置一次”的属性，而是**每次菜单下拉时框架来问**。`ON_UPDATE_COMMAND_UI` 的处理器就是回答（第 03 章讲过机制，这里补齐 API 面）：

```cpp
// 复选：开关量
void OnUpdateViewStatus(CCmdUI* p) { p->SetCheck(m_showStatus); }

// 单选：一组命令里只有一个亮
void OnUpdateColor(CCmdUI* p) {
    p->SetRadio(ColorOfCommand(p->m_nID) == m_color);   // 命令ID -> 基准色 -> 比对
    p->Enable(TRUE);
}

// 禁用：Enable(FALSE) 即灰
```

单选有个实用套路：**命令 ID 与状态值做成可映射的**（示例 27 的 `ColorOfCommand`），否则一串 if/else 会在更新函数和命令函数里各写一遍。

另外还有直接 API：菜单还没显示时就打勾/灰掉——

```cpp
popup.CheckMenuItem(IDM_DYN_FIRST, MF_BYCOMMAND | MF_CHECKED);
popup.EnableMenuItem(IDM_DYN_FIRST + 1, MF_BYCOMMAND | MF_GRAYED);
::SetMenuDefaultItem(popup.GetSafeHmenu(), IDM_DYN_FIRST + 2, TRUE);  // 加粗默认项
```

`CheckMenuItem` 适合**临时构造的弹出菜单**（TrackPopupMenu 马上要显示，没有 UPDATE_COMMAND_UI 的机会）；常驻菜单一律走 ON_UPDATE_COMMAND_UI，别两种混用——状态会打架。

## 2. 动态构造整张菜单

`CMenu` 是个轻对象，临时弹出菜单的正确姿势是**栈上构造、CreatePopupMenu、用完即弃**：

```cpp
CMenu popup;
popup.CreatePopupMenu();
for (int i = 0; i < 8; i++) {
    CString text;
    text.Format(_T("动态项 %d"), i + 1);
    popup.AppendMenu(MF_STRING, IDM_DYN_FIRST + i, text);
}
popup.AppendMenu(MF_SEPARATOR);
popup.AppendMenu(MF_OWNERDRAW, ODM_COLOR_FIRST + i, (LPCTSTR)od);  // owner-draw 段
```

命令处理用 `ON_COMMAND_RANGE(IDM_DYN_FIRST, IDM_DYN_LAST, OnDynRange)` 一个宏接住整段——比逐个 ON_COMMAND 干净得多。配套还有 `ON_UPDATE_COMMAND_UI_RANGE`、`ON_NOTIFY_RANGE`（第 03 章列过变体宏清单）。

`InsertMenu`（插到某位置）、`RemoveMenu`、`ModifyMenu` 同族；改**主菜单**用 `SetMenu(nullptr)` 卸下、`SetMenu(&menuNew)` 换上、`DrawMenuBar()` 重画。

## 3. 上下文菜单（右键菜单）

两个入口，按场景选：

1. **`OnContextMenu(CWnd* pWnd, CPoint pt)`**：标准入口。pt 是**屏幕坐标**，正好直接喂给 TrackPopupMenu。
2. 老书的 `WM_RBUTTONDOWN` + `ClientToScreen` 手工路线——今天没必要，除非要在按下（而非抬起）时弹。

```cpp
afx_msg void OnContextMenu(CWnd*, CPoint pt) {
    CMenu popup;
    popup.CreatePopupMenu();
    // ...按当前选中状态填项...
    int cmd = popup.TrackPopupMenu(TPM_RIGHTBUTTON | TPM_RETURNCMD, pt.x, pt.y, this);
    if (cmd)
        PostMessage(WM_COMMAND, cmd);    // 借主菜单的路由：一处逻辑两处入口
}
```

`TPM_RETURNCMD` 是关键：菜单命令**以返回值给你**而不是走消息循环分发。这样右键菜单和主菜单可以共用同一套命令处理（PostMessage 转发回去），也能对“用户取消”（返回 0）做特殊处理。

上下文菜单的“正确姿势”是跟随**当前选中对象**（老书例 14“根据当前可视文档动态改变菜单”的思想）：右键在列表项上弹“删除/重命名”，在空白处弹“新建/刷新”。判断依据用 `ScreenToClient` 转回客户区坐标后 `HitTest`。

## 4. 系统菜单：标题栏图标那一份

```cpp
void OnTestSysCmd() {
    CMenu* pSys = GetSystemMenu(FALSE);        // FALSE=取现有的（TRUE 会重置成默认）
    if (pSys->GetMenuState(IDM_SYS_ABOUT, MF_BYCOMMAND) == (UINT)-1) {  // 还没加过
        pSys->AppendMenu(MF_SEPARATOR);
        pSys->AppendMenu(MF_STRING, IDM_SYS_ABOUT, _T("关于菜单实验(&A)..."));
    }
}
```

系统菜单的命令**不走 WM_COMMAND 路由**，走 `WM_SYSCOMMAND`：

```cpp
afx_msg void OnSysCommand(UINT id, LPARAM) {
    if ((id & 0xFFF0) == IDM_SYS_ABOUT) {   // 低 4 位系统自用，必须先掩掉
        MessageBox(_T("..."), _T("关于"), MB_OK);
        return;
    }
    CFrameWnd::OnSysCommand(id, 0);
}
```

`& 0xFFF0` 不是可选项——SDK 文档明说系统用低 4 位做内部标记，老书例 19 特别强调过。忘了掩码，你的“关于”项会时灵时不灵（取决于 Windows 版本把哪几位置 1）。

自定义 ID 还要避开 `SC_*` 标准值段：用 0xF000 以下（比如 0x0010 段之后）的安全区。

## 5. owner-draw 菜单：位图与色块

老书扩展篇实例 11（“给下拉菜单加位图”）的路线今天依然成立，分三步：

1. **声明**：`AppendMenu(MF_OWNERDRAW, id, (LPCTSTR)pData)`——第三个参数在本模式下是 `dwItemData`，塞你的自备结构指针。
2. **量尺寸**：`WM_MEASUREITEM` 回调（`CtlType == ODT_MENU`），给每项宽高。色块菜单 = 色块宽 + 文本宽 + 余量。
3. **绘制**：`WM_DRAWITEM` 回调，`DRAWITEMSTRUCT` 给了 hdc、rcItem、itemState（含 `ODS_SELECTED` 高亮态）、itemData（还你指针）。

```cpp
afx_msg void OnDrawItem(int nIDCtl, LPDRAWITEMSTRUCT pd) {
    if (nIDCtl != 0 || !pd || pd->CtlType != ODT_MENU)
        return;                              // 只管菜单的 owner-draw（控件的是另一路）
    CDC dc;
    dc.Attach(pd->hDC);
    // ... 画背景（选中态用 COLOR_HIGHLIGHT）/ 色块 / 文本 ...
    dc.Detach();                             // Attach 了就要 Detach，CDC 析构不能带走它
}
```

两条纪律：

- `dwItemData` 指针的生命周期**自己管**：菜单销毁前得能访问。示例 27 把结构收在 `CPtrArray` 成员里、`DestroyWindow` 统一 delete。
- `nIDCtl == 0` 表示“菜单”发来的（菜单没有控件 ID）；非 0 是控件 owner-draw（第 09 章的 WM_DRAWITEM），一个处理函数里先分流。

顺带一提：现代 Windows 的菜单已自带图标通道——`SetMenuItemBitmaps`、菜单项 `MIIM_BITMAP` + 32 位色 ALPHA 位图，多数“美化”需求不用走到全 owner-draw 那么重。owner-draw 真正的不可替代场景是**完全自定义内容**（色板、迷你预览、滑杆）。

## 6. 与键盘的配合

菜单文本里的 `\tCtrl+D` 只是**显示**加速键文字；真正让它生效的是 ACCELERATORS 表（第 04 章/第 11 章）。动态构造的弹出菜单没法配加速键——需要键盘捷径的命令应该住在常驻菜单里。另一个方向：`LoadAccelerators` 换表可以在运行时切换快捷键方案（老书例 20“触发一个菜单命令”的现代变体是 `PostMessage(WM_COMMAND, ID_xxx)` 直接触发命令，跳过菜单本体）。

## 实战建议

- “最近文件”列表（MRU）是动态菜单的经典应用：MFC 有现成的 `CRecentFileList`（第 13 章注册表一节会碰到），没有就用 `InsertMenu` 手搓。
- 上下文菜单考虑用 `TrackPopupMenu` 的 `TPM_NONOTIFY`（配合 `TPM_RETURNCMD`）：菜单自身不发消息，只把结果交给你，逻辑集中。
- 菜单项超过一屏时考虑分层或改用对话框；`GetSystemMetrics(SM_CYSCREEN)` 粗判即可。

## 常见坑（实测）

1. **`ID_VIEW_LIST` 这类名字撞 AFX 内置宏**：`afxres.h` 已定义（列表视图模式命令），resource.h 里再定义会 C4005 宏重定义警告，且 afxres 的值覆盖你的——命令路由到不了你的处理器。避开 `ID_VIEW_*`、`ID_WINDOW_*`、`ID_APP_*` 这些 AFX 保留段（示例 26 实测中招，改名 `ID_VIEW_LISTVIEW` 解决）。
2. **系统菜单比较不掩 `0xFFF0`**：见上文，时灵时不灵的“灵异”菜单项十有八九是这个。
3. **TrackPopupMenu 返回后用 `CMenu` 局部对象**：对象已析构——但 `TPM_RETURNCMD` 模式下菜单在返回时销毁，`dwItemData` 不再被回调，正好安全；若你保留了菜单句柄继续用，结构生命周期要跟着菜单走。
4. **owner-draw 菜单忘了 `WM_MEASUREITEM`**：菜单项尺寸为 0，表现为“菜单弹出但什么都看不到”。
