# 05 · 窗口与框架类：创建、布局与生命周期

> 对应示例：`examples/05_frame_layout`

## 1. CWnd 体系

MFC 所有窗口类的基类是 `CWnd`，它就是一个 `HWND` 的 C++ 包装——`CWnd` 对象和 Windows 窗口**不是同一个东西**：对象是 C++ 层的壳，窗口是系统内核对象，两者在 `Create` 时通过句柄关联、在销毁时解除。

```
CWnd                       // 一切窗口的基础：句柄管理、消息映射、子窗口
├── CFrameWnd              // 框架窗口：菜单、工具栏停靠、SDI 主窗口
│   ├── CMDIFrameWnd       // MDI 主框架
│   └── COleFrameWnd
├── CDialog                // 对话框（第 06 章）
│   └── CPropertySheet     // 属性表
├── 控件类                 // CButton/CEdit/CListBox/CListCtrl...（第 07 章）
└── CView                  // Doc/View 的视图（第 15 章）
```

最常用的 `CWnd` 成员：

| 成员 | 用途 |
|---|---|
| `Create()` | 创建窗口（控件用 `Create`，框架窗口也用 `Create`） |
| `GetSafeHwnd()` | 拿 HWND；对象可能还没建窗口，先判空防崩溃 |
| `GetDlgItem(id) / SetDlgItemText` | 按控件 ID 访问子控件 |
| `MoveWindow / SetWindowPos` | 移动缩放（布局的核心） |
| `Invalidate(bErase)` | 请求重绘 → 触发 `WM_PAINT` |
| `SendMessage / PostMessage` | 发消息（同步/异步） |
| `SetCapture()` | 让鼠标消息持续发给自己（拖拽必需） |
| `ClientToScreen / ScreenToClient` | 坐标系转换 |

## 2. 创建时机：OnCreate

子控件的标准创建位置是框架的 `OnCreate`——此时窗口本体已建立、尚未显示，在这里建子控件可以避免闪烁：

```cpp
afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
    if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
        return -1;              // 基类失败则终止窗口创建

    m_edit.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                  CRect(0, 0, 0, 0), this, IDC_INPUT);   // 尺寸先给 0
    ...
    return 0;                   // 0 继续；-1 会销毁窗口
}
```

三个关键点：

1. **`WS_CHILD | WS_VISIBLE`**：控件是子窗口，必须带 `WS_CHILD`；`WS_VISIBLE` 让它随父窗口一起显示
2. **`this` 是父窗口**：控件的所有权、坐标基准、消息通知目标都归它
3. **初始尺寸给 0 没关系**——真正的尺寸在 `OnSize` 里布

## 3. 自适应布局：OnSize 模式

MFC 没有 layout 引擎，可变尺寸窗口的布局就是**在 OnSize 里手工算**：

```cpp
afx_msg void OnSize(UINT nType, int cx, int cy) {
    CFrameWnd::OnSize(nType, cx, cy);
    if (m_edit.GetSafeHwnd() == nullptr)
        return;                     // OnCreate 之前也可能来 WM_SIZE！

    const int margin = 12, editH = 28, gap = 8;
    m_edit.MoveWindow(margin, margin, cx - 2 * margin, editH);
    ...
}
```

防守两件事：

- **`GetSafeHwnd() == nullptr` 检查**：窗口创建过程中 `WM_SIZE` 可能先于 `OnCreate` 到达，此时控件还不存在，直接 `MoveWindow` 是空指针崩溃
- **`OnSize` 里别做重活**：拖拽窗口时它每秒触发几十次

复杂布局（可拖拽分隔条、停靠面板）用 `CFormView` 或引入 CSplitterWnd，但原理仍然是这套"收到尺寸、重算矩形、MoveWindow"。

## 4. 控件字体：默认字体很丑

手工创建的控件默认是粗老的 System 字体。统一设置 GUI 字体：

```cpp
wnd.SendMessage(WM_SETFONT, (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
```

真实工程一般建一个 `CFont` 成员（`CreatePointFont(90, _T("微软雅黑"))`），在 `OnCreate` 里发给每个控件，`ExitInstance` 前保持存活——注意 `GetStockObject` 拿到的不用删除，自建的 `CFont` 要在所有控件销毁后才能释放。

## 5. 控件通知怎么回到父窗口

控件与父窗口通信靠**通知消息**，MFC 映射宏按通知类型分：

| 事件 | 宏 | 处理函数 |
|---|---|---|
| 按钮点击 | `ON_BN_CLICKED(IDC_ADD, OnAdd)` | `afx_msg void OnAdd()` |
| 编辑框文本变化 | `ON_EN_CHANGE(IDC_EDIT, OnChange)` | `afx_msg void OnChange()` |
| 组合框选择变化 | `ON_CBN_SELCHANGE(IDC_COMBO, OnSel)` | `afx_msg void OnSel()` |
| 列表控件复杂通知 | `ON_NOTIFY(LVN_XXX, IDC_LIST, OnXxx)` | `afx_msg void OnXxx(NMHDR*, LRESULT*)` |

`ON_BN_CLICKED` / `ON_EN_*` 这类是 `WM_COMMAND` 的语法糖；`ON_NOTIFY` 处理 `WM_NOTIFY`（能携带更丰富的信息）。都是**子 → 父**的单向通知，父窗口想控制子控件就用成员变量的方法（`m_edit.SetWindowText`）。

## 6. 窗口生命周期与对象生命周期

```text
Create 时序：  C++ 对象构造 → Create/OnCreate → 显示 → 使用
销毁时序：    WM_CLOSE → DestroyWindow → WM_DESTROY → WM_NCDESTROY → PostNcDestroy
```

关键规则：

- **CFrameWnd 派生窗口**：框架在 `PostNcDestroy` 里 `delete this`——所以 `new CMainWindow()` 之后不用管释放（第 01 章示例没写任何 delete 是对的）
- **控件（CButton 等）**：作为 `WS_CHILD` 子窗口随父窗口销毁，但 **C++ 对象不自动 delete**——控件通常做成成员变量（如 `CEdit m_edit;`），跟随宿主类析构，最省心
- **对话框**：模态在栈上；非模态需要 `PostNcDestroy` 套路（第 06 章详解）

**绝不手工调用 `delete` 去销毁一个还有窗口的 CWnd**，先 `DestroyWindow()` 让窗口走完销毁链路。

## 7. 常见坑

**WM_SIZE 先于 OnCreate**：见第 3 节，判 `GetSafeHwnd()`。

**控件 ID 重复**：两个控件用同一 ID，通知路由错乱。ID 段位分配好（第 04 章）。

**在 OnCreate 里 MoveWindow 全量布局后仍闪烁**：控件多时逐个移动会闪。先 `SetRedraw(FALSE)`，布局完 `SetRedraw(TRUE)` + `Invalidate`。

**SetCapture 配对遗忘**：`SetCapture()` 后必须在 `WM_LBUTTONUP`（或中途判断按键抬起）`ReleaseCapture()`，否则鼠标被独占，别的程序收不到。

## 8. 实战建议

- 把布局逻辑抽成 `void LayoutChildren(int cx, int cy)`，`OnSize` 和初始化都调它，避免两处算尺寸不一致
- 控件一律做成员变量（值语义、自动析构），只有动态创建的一组控件才用容器管理
- `GetSafeHwnd()` 养成习惯——它比 `GetSafeHwnd` 之外的裸 `GetHWND` 判断多一层对象判空

---
上一章：[04 资源文件入门](04-resources.md) ｜ 下一章：[06 对话框](06-dialogs.md)
