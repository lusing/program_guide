# 06 · 对话框：模态、非模态与 DDX

> 对应示例：`examples/06_dialog`

> **本章你将学会**：模态与非模态两套生死规则的区别、`DoDataExchange` 里 DDX/DDV 到底做了什么、`UpdateData` 的方向语义、DDV 校验失败时的完整行为，以及非模态对话框为什么要 `new` + `PostNcDestroy` 自毁。
> **前置知识**：第 05 章的窗口创建与销毁链路、第 04 章的对话框资源（`DIALOGEX`）。

## 1. 两种形态，两套生死规则

| | 模态（DoModal） | 非模态（Create） |
|---|---|---|
| 行为 | 阻塞调用方，必须先回答 | 与主窗口共存 |
| 创建 | `dlg.DoModal()` | `dlg.Create(IDD, parent)` + `ShowWindow` |
| 关闭 | `EndDialog(IDOK/IDCANCEL)` | `DestroyWindow()` |
| 典型对象 | 栈上局部变量 | 堆上 `new` + 自毁 |
| 用途 | 登录、设置、确认 | 面板、查找、监视窗 |

最常见的崩溃就是把两套规则混用：对非模态调 `EndDialog`（窗口没销毁）、对栈上的非模态调 `DestroyWindow`（对象已析构窗口还在）。

## 2. 对话框模板与类

对话框的界面在 .rc 里用 `DIALOGEX` 模板描述（坐标单位是**对话框单位 DLU**，随字体缩放，这是它比像素坐标好的地方）：

```rc
IDD_LOGIN DIALOGEX 0, 0, 210, 96
STYLE DS_SETFONT | DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU
CAPTION "登录"
FONT 9, "微软雅黑"
BEGIN
    LTEXT           "用户名：", IDC_STATIC, 8, 11, 40, 10
    EDITTEXT        IDC_USER, 52, 8, 150, 14, ES_AUTOHSCROLL
    DEFPUSHBUTTON   "确定", IDOK, 90, 76, 50, 14
    PUSHBUTTON      "取消", IDCANCEL, 152, 76, 50, 14
END
```

`IDOK`/`IDCANCEL` 是 MFC 预定义 ID：点击会触发 `OnOK`/`OnCancel`。派生类用 `enum { IDD = IDD_LOGIN };` 关联模板：

```cpp
class CLoginDialog : public CDialog {
public:
    enum { IDD = IDD_LOGIN };
    CLoginDialog(CWnd* parent = nullptr) : CDialog(IDD_LOGIN, parent) {}
};
```

## 3. DDX 与 DDV 的完整机制

手写 `GetDlgItemText` / `SetDlgItemText` 又长又容易漏。DDX（Dialog Data Exchange）把控件值绑定到成员变量，双向同步只由一个函数决定方向：

```text
         UpdateData(FALSE)   成员变量 → 控件     （初始化界面）
   成员变量 ─────────────────────────────► 控件
   m_user                                 IDC_USER      编辑框
   m_pass                                 IDC_PASS      编辑框
   m_remember                             IDC_REMEMBER  复选框
   成员变量 ◄───────────────────────────── 控件
         UpdateData(TRUE)    控件 → 成员变量   （读取输入 + 校验）
```

绑定写在 `DoDataExchange` 里：

```cpp
void DoDataExchange(CDataExchange* pDX) override {
    CDialog::DoDataExchange(pDX);           // 必须调基类
    DDX_Text(pDX, IDC_USER, m_user);
    DDX_Text(pDX, IDC_PASS, m_pass);
    DDX_Check(pDX, IDC_REMEMBER, m_remember);
    DDX_Control(pDX, IDC_LIST, m_list);     // 绑定控件对象本身，不是值
    DDV_MaxChars(pDX, m_user, 32);          // DDV：校验，紧跟对应的 DDX
    DDV_MaxChars(pDX, m_pass, 32);
}
```

**每个 `DDX_*` 函数内部只有两件事**：看 `pDX->m_bSaveAndValidate` 决定方向，然后调 `pDX->PrepareCtrl(nIDC)` 拿到控件句柄、读或写。所以它本质就是"帮你写 `GetDlgItemText` / `SetDlgItemText`"——只是写得整齐、不漏、且天然带方向语义。

常用 DDX 函数：

| 函数 | 绑定的成员类型 |
|---|---|
| `DDX_Text` | `CString` / `int` / `UINT` / `long` / `DWORD` / `float` / `double` / `COleDateTime` … |
| `DDX_Check` | `int`（`BOOL` 也行，因为 `BOOL` 就是 `int`） |
| `DDX_Radio` | `int`（第几个单选钮） |
| `DDX_LBIndex` / `DDX_CBIndex` | `int`（列表/组合框选中项下标） |
| `DDX_CBString` | `CString`（组合框文本） |
| `DDX_Control` | `CWnd` 派生类（绑定**控件对象**，用来调它的方法） |

### DDV 校验失败时会发生什么

DDV 函数是**纯校验**——注意它们的签名是 `DDV_MinMaxInt(pDX, int value, int minVal, int maxVal)`，`value` 是**按值**传的，改不了数据，只能判合不合法。

校验失败时 `DDV_*` 调 `pDX->Fail()`，后者做三件事：

1. 弹出错误提示框（内容来自 MFC 的错误字符串资源）
2. 把焦点设回**最后处理的那个控件**（`CDataExchange::m_idLastControl` 记着它）
3. `AfxThrowUserException()` 抛异常

这个异常被 `CWnd::UpdateData` 捕获，于是 **`UpdateData(TRUE)` 返回 `FALSE`**。连锁反应是：`CDialog::OnOK` 的默认实现是 `if (!UpdateData(TRUE)) return; EndDialog(IDOK);`——所以**校验失败时对话框自动保持打开**，用户的光标已经回到出问题的那个控件上。整套交互你不用写一行代码。

**实测**（探针程序，`DDX_Text(IDC_NUM, m_num)` + `DDV_MinMaxInt(pDX, m_num, 0, 100)`）：

```text
① 越界 999 -> UpdateData(TRUE)=FALSE, m_num=999    提示："请输入一个 0 到 100 之间的整数。"
② 合法 50  -> UpdateData(TRUE)=TRUE,  m_num=50
③ 文本 abc -> UpdateData(TRUE)=FALSE, m_num=-1     提示："请输入一个整数。"
④ UpdateData(FALSE) 后控件文本 = "77"
```

① 和 ③ 都是"失败"，但结果**不一样**，差别来自执行顺序：

- **`DDX_*` 先执行，`DDV_*` 后执行**（这也是为什么 DDV 必须紧跟对应的 DDX 写）。①里 999 是个合法整数，`DDX_Text` 顺利把它**写进了 `m_num`**，随后 `DDV_MinMaxInt` 才发现越界 —— 所以**校验失败时成员变量已经被污染成那个非法值**（`m_num == 999`）
- ③里 `abc` 连整数都解析不出来，`DDX_Text` 内部解析失败就直接 `Fail()`，**赋值那一步根本没发生**，`m_num` 保持原值（哨兵 `-1`）

这个差别有实际后果：**校验失败后不要读成员变量**，它要么是非法值、要么是旧值，取决于失败发生在 DDX 还是 DDV 阶段。要拿"用户到底输了什么"，得读控件文本（`GetDlgItemText`）。

## 4. 对话框的返回值与生命周期

`DoModal` 的返回值来自 `EndDialog` 的参数：

```cpp
INT_PTR nRet = dlg.DoModal();
// IDOK      —— 用户点了确定（或按了 Enter）
// IDCANCEL  —— 用户点了取消、按了 Esc、或点了标题栏的 X
// 其他值    —— 你在 OnOK/OnCancel 里 EndDialog(IDC_XXX) 传的值
```

三个重写点的分工：

| 重写 | 何时被调 | 默认行为 |
|---|---|---|
| `OnOK` | 点"确定"按钮、按 Enter | `UpdateData(TRUE)` 失败则返回；否则 `EndDialog(IDOK)` |
| `OnCancel` | 点"取消"、按 Esc、点 X | `EndDialog(IDCANCEL)` |
| `OnInitDialog` | 窗口已建、显示之前 | 调基类；返回 `TRUE` 表示"把焦点给第一个 `WS_TABSTOP` 控件" |

**关键**：`DoModal` 返回之后，对话框窗口已经销毁，**控件全没了**——用户输入只存在于成员变量里（框架在 `OnOK` 默认路径里已经 `UpdateData(TRUE)` 过）。所以调用方这样用：

```cpp
CLoginDialog dlg(this);
dlg.m_user = m_lastUser;            // 预填：构造完、DoModal 之前设成员
if (dlg.DoModal() == IDOK) {
    Use(dlg.m_user, dlg.m_pass);    // 直接读成员，不要再碰控件
}
```

非模态对话框没有 `DoModal` 那层保护，销毁完全由你控制：

```cpp
void OnCancel() override { DestroyWindow(); }   // ① 点 X / Esc：销毁窗口
void PostNcDestroy() override {
    GetOwner()->PostMessage(WM_APP_INFO_CLOSED); // ② 通知持有者清指针
    delete this;                                 // ③ 自毁 C++ 对象
}
```

`PostNcDestroy` 是 `WM_NCDESTROY` 的最后一步，此时窗口已经彻底没了，是**唯一安全的自毁时机**。为什么必须自毁：`CDialog::PostNcDestroy` 默认**不** delete 自己（因为模态对话框在栈上，框架不能替你删）。堆上分配的非模态必须自己 `delete this`，而且要先让持有者把指针清空——否则主窗口持着悬空指针。

## 5. 非模态对话框的完整套路

持有方（主窗口）需要处理三件事：已开则置顶、创建后显示、关闭时清指针。

```cpp
afx_msg void OnDlgInfo() {
    if (m_info) { m_info->SetForegroundWindow(); return; }   // 已开则置顶
    m_info = new CInfoDialog(this);
    m_info->Create(this);
    m_info->ShowWindow(SW_SHOW);
}

afx_msg LRESULT OnInfoClosed(WPARAM, LPARAM) {   // ON_MESSAGE(WM_APP_INFO_CLOSED)
    m_info = nullptr;
    return 0;
}
```

程序退出时，主窗口对还开着的面板只需 `DestroyWindow()`（销毁链路会触发 `PostNcDestroy → delete this`），**别再手工 delete**。

非模态对话框里的周期任务（刷新显示）用 `SetTimer`/`OnTimer`，与普通窗口无异。

## 常见坑

1. **非模态对话框做成栈对象**
   `CInfoDialog dlg(this); dlg.Create(...);` —— 函数一返回，C++ 对象析构，窗口还在但已经没有对象管它了，之后任何消息都会崩。非模态**必须 `new`**。

2. **在 `OnInitDialog` 里调 `UpdateData(TRUE)`**
   方向搞反了。`OnInitDialog` 是"把初值放进控件"，要用 `UpdateData(FALSE)`；`TRUE` 会把控件的空值抓回成员变量，刚设好的初值全被清掉。

3. **`DDX_Control` 的成员在使用前没绑定**
   `DDX_Control` 是在 `DoDataExchange` 里才把控件对象和 ID 关联起来的，而 `DoDataExchange` 首次被调是在 `DoModal`/`Create` 过程中。所以在构造函数里就调 `m_list.InsertColumn(...)` 会操作一个还没有 `HWND` 的空对象——这类代码要放到 `OnInitDialog`。

4. **`OnInitDialog` 忘记返回 `TRUE`**
   默认返回值决定焦点归属：返回 `TRUE` 框架把焦点给第一个 `WS_TABSTOP` 控件；你自己调了 `SetFocus` 才返回 `FALSE`。随便返回 `FALSE` 会让焦点落在不该落的地方。

5. **`DoModal` 之后还读对话框控件**
   模态关闭后窗口没了。正确姿势就是读 DDX 成员变量。

6. **`UpdateData(TRUE)` 返回 `FALSE` 后还读成员变量**
   见第 3 节实测：DDX 先执行、DDV 后校验，所以**校验失败时成员变量已经被写成了那个非法值**（越界的 `999` 会原样躺在 `m_num` 里）。`OnOK` 里 `if (!UpdateData(TRUE)) return;` 挡住了"非法值被当成结果用掉"，但如果你自己在别处调 `UpdateData(TRUE)` 又不检查返回值，就会拿到脏数据。判断依据永远是**返回值**，不是成员变量的内容。

7. **在 `OnInitDialog` 里 `ShowWindow(SW_HIDE)` 无效**
   对话框显示前框架会按模板可见性处理。要"隐藏启动"需在 `OnWindowPosChanging` 里拦。

8. **Esc 键直接关掉了非模态面板**
   Esc 触发 `IDCANCEL` → `OnCancel`。不想要这个行为就覆写 `OnCancel` 判定来源，或改模板样式。

9. **日期控件写成 `DDX_DateCtrl`**
   没有这个函数。日期用 `CDateTimeCtrl` + `DDX_DateTimeCtrl`（`<afxdtctl.h>`）。

## 实战建议

- 对话框类设计成"数据进出站"：所有控件交互封在类内部，外部只见成员变量和方法。第 25 章实战项目的设置对话框就是这个模式
- 模态对话框构造参数做"输入"，成员变量做"输出"，注释写清哪些成员是 out 参数
- **能用 DDV 表达的业务规则就用 DDV**——它自带提示框和焦点回退；只有 DDV 覆盖不到的跨字段校验才去覆写 `OnOK`
- 非模态面板记得处理"面板开着但内容过时"：让持有者在数据变化时调用 `UpdateText`（第 25 章统计面板的实现）

## 自测

1. **`UpdateData(TRUE)` 和 `UpdateData(FALSE)` 的方向分别是什么？** —— `TRUE` 是控件 → 成员变量（读取输入并校验，对应 `m_bSaveAndValidate == TRUE`）；`FALSE` 是成员变量 → 控件（初始化界面）。
2. **DDV 校验失败后，为什么对话框会自动保持打开？** —— `DDV_*` 调 `pDX->Fail()`：弹提示框、把焦点设回出问题的控件、抛 `CUserException`；`UpdateData` 捕获后返回 `FALSE`，而 `CDialog::OnOK` 默认实现是 `if (!UpdateData(TRUE)) return;`，于是不会走到 `EndDialog`。
3. **`UpdateData(TRUE)` 返回 `FALSE` 时，成员变量是原值还是用户输入的值？** —— 看失败发生在哪一步：DDX 先执行、DDV 后校验，所以 **DDV 判失败时成员变量已被写成非法值**（实测越界 `999` 会留在 `m_num` 里）；而 DDX 自身解析失败（输入 `abc`）时赋值尚未发生，成员变量保持原值。所以判断成败只能看返回值。
4. **非模态对话框为什么必须在 `PostNcDestroy` 里 `delete this`？** —— 因为 `CDialog::PostNcDestroy` 默认不删自己（模态对话框在栈上，框架不能替你删）；堆上分配的非模态若不自己删就内存泄漏，而 `PostNcDestroy` 是窗口彻底销毁后唯一安全的自毁时机。
5. **为什么 `DDX_Control` 绑定的控件对象不能在构造函数里使用？** —— `DoDataExchange` 首次被调是在 `DoModal`/`Create` 过程中，构造函数执行时控件对象还没有 `HWND`，相关操作要放到 `OnInitDialog`。

---
上一章：[05 窗口与框架类](05-frames.md) ｜ 下一章：[07 常用控件深入](07-controls.md)
