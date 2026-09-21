# 09 · 自绘控件与自定义控件

> 对应示例：`examples/09_custom_controls`

> **本章你将学会**：Owner-draw 与 Custom draw 的分工差别、`DRAWITEMSTRUCT` 每个字段的含义、`NM_CUSTOMDRAW` 的两阶段握手、从零写一个 `CWnd` 派生控件要做什么，以及 `SetWindowSubclass` 给现成控件加行为。
> **前置知识**：第 05 章的窗口创建与 `AfxRegisterWndClass`、第 07 章的 `WM_NOTIFY` 与 `NMHDR`、第 06 章的 `DDX_Control`。

## 1. 三条自绘路线

要改控件外观，有三条路，代价从低到高：

| 路线 | 机制 | 谁负责画 | 适合 |
|---|---|---|---|
| **Custom draw** | 控件发 `NM_CUSTOMDRAW`，你只改属性 | **控件自己画**，你改颜色/字体 | 列表、树、工具栏等公共控件改配色 |
| **Owner-draw** | 样式加 `BS_OWNERDRAW` 等，控件发 `WM_DRAWITEM` | **你全画**，控件只给一块矩形 | 按钮、菜单项等需要完全自定义外观的小控件 |
| **完全自绘控件** | `CWnd` 派生 + 自己注册窗口类 | **你全画**，且窗口类也是你的 | 现有控件都满足不了的、全新的控件 |

选择判据很简单：**能用 custom draw 就别用 owner-draw**。custom draw 下控件仍然负责画文字、画图标、处理高 DPI，你只覆盖想改的那几个属性；owner-draw 下连文字排版、焦点框、按下态都得自己来，等于把控件重写一遍。

只有当"目标控件根本不支持 custom draw"（按钮就是），或者"我要的控件压根不存在"（仪表盘、颜色选择器）时，才往下面两条路走。

## 2. Owner-draw 按钮

资源模板里给按钮加 `BS_OWNERDRAW`：

```rc
CONTROL "自绘按钮", IDC_OWNERDRAW_BTN, "Button",
        BS_OWNERDRAW | WS_TABSTOP, 12, 10, 120, 26
```

按钮就不再画自己了，改成给父窗口发 `WM_DRAWITEM`。**你必须给这个 ID 绑定一个 `CButton` 派生类**，否则 MFC 找不到处理函数，按钮就是一片空白（不报错、不崩溃，最难查）：

```cpp
void DoDataExchange(CDataExchange* pDX) override {
    CDialog::DoDataExchange(pDX);
    DDX_Control(pDX, IDC_OWNERDRAW_BTN, m_btn);   // 关键：绑上才会走 DrawItem
}
```

然后重写 `DrawItem`，参数 `dis` 是一个 `DRAWITEMSTRUCT*`：

| 字段 | 含义 |
|---|---|
| `CtlID` | 控件的 ID |
| `CtlType` | 控件类型（`ODT_BUTTON` / `ODT_LISTBOX` / `ODT_MENU`…） |
| `itemID` | 列表类控件里是行号；按钮无意义 |
| `itemAction` | 要执行的动作（`ODA_DRAWENTIRE` / `ODA_SELECT` / `ODA_FOCUS`） |
| `itemState` | **当前状态位**：`ODS_SELECTED`（按下）、`ODS_FOCUS`（有焦点）、`ODS_DISABLED` |
| `hwndItem` | 控件句柄 |
| `hDC` | **要往哪画**——用 `CDC::FromHandle` 包成 `CDC` 再用 |
| `rcItem` | **画在哪**——绘制矩形，单位是客户区坐标 |

```cpp
void DrawItem(LPDRAWITEMSTRUCT dis) override {
    CDC* pDC = CDC::FromHandle(dis->hDC);
    CRect rc(dis->rcItem);

    const bool pressed  = (dis->itemState & ODS_SELECTED) != 0;
    const bool focused  = (dis->itemState & ODS_FOCUS) != 0;
    const bool disabled = (dis->itemState & ODS_DISABLED) != 0;

    COLORREF face = disabled ? RGB(230, 230, 230)
                             : (pressed ? RGB(60, 120, 200) : RGB(90, 155, 235));
    pDC->FillSolidRect(rc, face);
    pDC->Draw3dRect(rc, RGB(255, 255, 255), RGB(40, 80, 140));

    CString caption;
    GetWindowText(caption);
    pDC->SetBkMode(TRANSPARENT);
    pDC->SetTextColor(disabled ? RGB(150, 150, 150) : RGB(255, 255, 255));
    if (pressed)
        rc.OffsetRect(1, 1);          // 按下时文字下沉一格
    pDC->DrawText(caption, rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    if (focused) {                    // ← 这一条不能省
        CRect f = rc;
        f.DeflateRect(3, 3);
        pDC->DrawFocusRect(f);
    }
}
```

**为什么必须处理 `ODS_FOCUS`**：系统的按钮会自己画焦点虚线框，而 owner-draw 按钮的焦点框**也得你自己画**。漏掉它，鼠标用户看不出问题（鼠标点哪哪高亮），但键盘用户用 Tab 切到这个按钮时**界面上完全没有提示**——焦点在哪全靠猜。这类无障碍缺陷在开发时几乎发现不了。

三个状态位都要用上：`ODS_SELECTED`（按下）让底色变深 + 文字下沉，`ODS_DISABLED` 让整体变灰，`ODS_FOCUS` 补焦点框。只画一种状态的按钮，点下去没有任何反馈。

## 3. Custom draw 列表

列表控件自己会画，custom draw 让你在它画的中间插一脚。通知是 `NM_CUSTOMDRAW`，结构体是 `NMLVCUSTOMDRAW`。

**关键是两阶段握手**——控件在画之前先问你一次，你必须明确回答"逐行画的时候还要不要叫我"：

```cpp
afx_msg void OnCustomDraw(NMHDR* pNMHDR, LRESULT* pResult) {
    auto* pLVCD = reinterpret_cast<NMLVCUSTOMDRAW*>(pNMHDR);
    *pResult = CDRF_DODEFAULT;                  // 默认：你随便画，我不插手

    switch (pLVCD->nmcd.dwDrawStage) {
    case CDDS_PREPAINT:
        // 整个控件要开始画了。返回这个 = "每一行画之前再叫我一次"
        *pResult = CDRF_NOTIFYITEMDRAW;
        break;
    case CDDS_ITEMPREPAINT:
        // 某一行要画了。nmcd.dwItemSpec 在报表视图里就是行号。
        if (pLVCD->nmcd.dwItemSpec % 2 == 1)
            pLVCD->clrTextBk = RGB(238, 245, 255);   // 斑马纹
        *pResult = CDRF_NEWFONT;                // "颜色我改了，按我的来"
        break;
    default:
        break;
    }
}
```

三个返回值要分清：`CDRF_DODEFAULT`（你照常画）、**`CDRF_NOTIFYITEMDRAW`（每行画之前叫我，斑马纹必须返回这个）**、`CDRF_SKIPDEFAULT`（这行我全包，你别画）。`CDRF_NEWFONT` 是 `CDDS_ITEMPREPAINT` 阶段专用的，含义是"字体/颜色变了，按我的来"。

可改的属性都在 `NMLVCUSTOMDRAW` 上：`clrText`（文字色）、`clrTextBk`（背景色）、`clrFace`（分组视图的底色）。

**为什么这比 owner-draw 省事**：`LVS_OWNERDRAWFIXED` 也存在于列表控件，但用它意味着每一行的每一个子项、每一次选中高亮、每一个图标，全要你自己画。custom draw 下这些照旧由控件负责，你只改了背景色一个属性。

## 4. 从零写一个自绘控件

现有控件都满足不了时（示例里的仪表盘），就得自己造。三步：

**① 注册窗口类。** 用 `AfxRegisterWndClass` 拿一个类名，参数决定系统怎么对待这套窗口。背景刷给 `NULL_BRUSH` 是自绘控件的标准做法——反正 `OnPaint` 会把整个客户区覆盖掉，让系统再擦一遍纯属浪费（也是闪烁的来源之一）。

**② 创建窗口。** `CWnd::Create` 就是 `::CreateWindowEx` 的包装：

```cpp
BOOL Create(CWnd* parent, UINT id, const CRect& rc) {
    LPCTSTR cls = AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW,   // 尺寸变了就重画
                                      ::LoadCursor(NULL, IDC_ARROW),
                                      (HBRUSH)::GetStockObject(NULL_BRUSH));
    return CWnd::Create(cls, NULL, WS_CHILD | WS_VISIBLE, rc, parent, id);
}
```

**③ 画。** 重写 `OnPaint`：

```cpp
afx_msg void OnPaint() {
    CPaintDC dc(this);            // 构造时 BeginPaint，析构时 EndPaint —— 必须用这个
    CRect rc;
    GetClientRect(&rc);
    Draw(dc, rc);
}
```

**`OnEraseBkgnd` 返回 `TRUE` 消除闪烁**：

```cpp
afx_msg BOOL OnEraseBkgnd(CDC*) { return TRUE; }
```

默认实现会用窗口类的背景刷把整个客户区擦一遍，然后 `OnPaint` 再画一遍——同一个像素每帧被写两次，快速刷新时就是肉眼可见的闪烁。返回 `TRUE` 表示"背景我已经在 `OnPaint` 里处理了，系统别再擦"。

**改值后调 `Invalidate`，不要在 `SetValue` 里直接画**：

```cpp
void SetValue(int percent) {
    percent = max(0, min(100, percent));
    if (percent == m_percent) return;   // 值没变就别重画
    m_percent = percent;
    Invalidate();                        // 标脏，等系统合并后发 WM_PAINT
}
```

`Invalidate` 只是标脏，真正的 `WM_PAINT` 由系统在消息队列空闲时合并发出。这样连续改十次值只会重画一次。要立刻画就再调 `UpdateWindow()`（强制马上发 `WM_PAINT`）——**只在确实需要同步刷新时才用**，比如动画循环里。

**把绘制逻辑抽成 `Draw(CDC&, CRect)`** 而不是全塞进 `OnPaint`：这样同一份代码可以画到内存 DC（双缓冲）、画到打印机 DC，也好单独测。

## 5. 子类化：给现成控件加行为

不想重写整个控件，只想改它的一点行为（比如"编辑框只收数字"），用**子类化**：把现成控件的窗口过程换成你的，处理完再转回去。

MFC 有两条路：

| | `SetWindowSubclass`（推荐） | `CWnd::SubclassWindow`（传统） |
|---|---|---|
| 所属 | Win32 公共控件 API | MFC 自己的机制 |
| 可叠加 | **可以**，多层按后进先出 | 不行，只能一层 |
| 生命周期 | 窗口销毁时自动摘钩 | 要自己保证对象比窗口活得久 |
| 参考数据 | 有 `dwRefData` 参数可传 `this` | 靠 `CWnd` 对象自身 |

```cpp
static LRESULT CALLBACK NumEditProc(HWND hWnd, UINT msg, WPARAM wParam,
                                    LPARAM lParam, UINT_PTR /*uIdSubclass*/,
                                    DWORD_PTR /*dwRefData*/) {
    if (msg == WM_CHAR) {
        // 只放行数字和退格；其余一律吃掉（返回 0 = 已处理，别再往下传）
        if (!_istdigit(static_cast<TCHAR>(wParam)) && wParam != VK_BACK)
            return 0;
    }
    // 其余消息必须交给 DefSubclassProc 往下传，否则控件等于废了
    return DefSubclassProc(hWnd, msg, wParam, lParam);
}

// 装上：子类号随便给个唯一值，同一个控件可以用不同号叠多层
SetWindowSubclass(m_edit.GetSafeHwnd(), NumEditProc, 1, 0);
```

**`DefSubclassProc` 不能漏**。子类过程必须是个"过滤器"而不是"替代品"——只处理你关心的消息，其余原样转给链上的下一个过程。忘了转，控件连画自己都不会了。

> 顺带纠正一个常见说法：**MFC 工程里不需要手动链接 `comctl32.lib`**。`afx.h` 里已经有 `#pragma comment(lib, "comctl32.lib")`（示例构建时验证过，直接链上了）。只有纯 Win32 工程才要自己加。

## 常见坑

1. **Owner-draw 控件忘写 `DrawItem`，或者忘了 `DDX_Control` 绑定**
   两种情况的症状一样：控件一片空白，**不报错、不崩溃**。样式加了 `BS_OWNERDRAW` 就必须有一个 `CButton` 派生类被 `DDX_Control` 绑到那个 ID 上，`DrawItem` 才会被调。

2. **Custom draw 在 `CDDS_PREPAINT` 阶段直接改颜色**
   收不到效果。`CDDS_PREPAINT` 是"整个控件要开始画了"，此时没有"当前行"的概念；必须返回 `CDRF_NOTIFYITEMDRAW`，控件才会在每行画之前再叫你一次（`CDDS_ITEMPREPAINT`），那才是改 `clrTextBk` 的地方。

3. **自绘控件不处理 `OnEraseBkgnd`**
   默认实现会先用背景刷擦一遍再 `OnPaint`，同一个像素每帧写两次，快速刷新时严重闪烁。返回 `TRUE` 并自己在 `OnPaint` 里铺满背景。

4. **`SubclassWindow` 的 C++ 对象先析构而窗口还活着**
   `CWnd::SubclassWindow` 之后，窗口的生死和对象的生死就绑在一起了。对象是栈上的局部变量、函数一返回就析构，而窗口还在——之后任何消息都会走到一个已析构的对象上。用 `SetWindowSubclass` 就没这个问题：它不持有对象，窗口销毁时自动摘钩。

5. **子类过程忘了调 `DefSubclassProc`**
   只处理 `WM_CHAR` 却把其他消息也一并"吃掉"，控件就不再响应绘制、鼠标、键盘——等于一个死的矩形。子类过程是过滤器，不是替代品。

6. **在 `SetValue` 里直接画而不是 `Invalidate`**
   连续改值时每一帧都同步画一次，既慢又闪。`Invalidate` 标脏、由系统合并成一次 `WM_PAINT`；确实需要立刻刷新时再补一个 `UpdateWindow()`。

## 实战建议

- **能用 custom draw 就别用 owner-draw**：前者控件仍负责画文字、图标、高 DPI 缩放，你只覆盖几个属性；后者等于把控件重写一遍
- **自绘控件的绘制逻辑抽成 `Draw(CDC&, CRect)`**，`OnPaint` 只负责拿 DC 和调它——这样能画到内存 DC 做双缓冲，也能直接画到打印机，还好单独验证
- **高频刷新用 `InvalidateRect` 只失效脏区域**，别整个控件 `Invalidate`；仪表盘这种只改指针的，算准指针扫过的那一小块矩形就够了
- **owner-draw 的控件一定要用键盘走一遍**：Tab 切进去有没有焦点框、空格键能不能按下、禁用态是否变灰——这三件事鼠标测不出来

## 自测

1. **Custom draw 和 owner-draw 的分工差别是什么？什么时候必须用 owner-draw？**
   —— Custom draw 下控件自己画，你只改属性（颜色、字体）；owner-draw 下控件只给你一块矩形和 DC，全部由你画。目标控件不支持 custom draw（按钮就是），或者要的控件压根不存在时，才必须用 owner-draw 或从零自绘。

2. **`DRAWITEMSTRUCT` 里 `itemState` 的 `ODS_FOCUS` 为什么不能忽略？**
   —— Owner-draw 控件的焦点虚线框也要自己画。忽略它，鼠标操作时看不出问题，但键盘用户用 Tab 切到该控件时界面上没有任何焦点提示，是无障碍缺陷。

3. **Custom draw 想给列表加斑马纹，为什么必须返回 `CDRF_NOTIFYITEMDRAW`？**
   —— `CDDS_PREPAINT` 阶段是"整个控件要开始画"，此时没有当前行的概念，改不了单行颜色。返回 `CDRF_NOTIFYITEMDRAW` 后控件才会在每行画之前再回调一次 `CDDS_ITEMPREPAINT`，那才是改 `clrTextBk` 的时机。

4. **自绘控件为什么要让 `OnEraseBkgnd` 返回 `TRUE`？**
   —— 默认实现会先用窗口类背景刷把客户区擦一遍，`OnPaint` 再画一遍，同一像素每帧写两次，快速刷新时闪烁。返回 `TRUE` 表示"背景已在 `OnPaint` 里处理"，跳过系统擦除。

5. **`SetWindowSubclass` 和 `CWnd::SubclassWindow` 该怎么选？子类过程里为什么必须调 `DefSubclassProc`？**
   —— 优先 `SetWindowSubclass`：可叠加多层、窗口销毁时自动摘钩、不需要对象与窗口同生命周期；`SubclassWindow` 只能一层，且对象必须先于窗口析构，容易悬空。子类过程是过滤器不是替代品，只处理关心的消息，其余必须转给 `DefSubclassProc`。

---
上一章：[08 控件进阶：树、属性页与任务对话框](08-controls-advanced.md) ｜ 下一章：[10 通用对话框与文件 IO](10-common-dialogs.md)
