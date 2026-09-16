# 06 · 对话框：模态、非模态与 DDX

> 对应示例：`examples/05_dialog`

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

## 3. DDX：控件值与成员变量的自动同步

手写 `GetDlgItemText` / `SetDlgItemText` 又长又容易漏。DDX（Dialog Data Exchange）把控件值绑定到成员变量：

```cpp
CString m_user;
CString m_pass;
BOOL    m_remember;

void DoDataExchange(CDataExchange* pDX) override {
    CDialog::DoDataExchange(pDX);
    DDX_Text(pDX, IDC_USER, m_user);
    DDX_Text(pDX, IDC_PASS, m_pass);
    DDX_Check(pDX, IDC_REMEMBER, m_remember);
    DDV_MaxChars(pDX, m_user, 32);      // DDV：范围/长度校验
    DDV_MaxChars(pDX, m_pass, 32);
}
```

DDX 的同步方向由 `UpdateData` 的参数决定：

```text
UpdateData(FALSE)   成员变量 → 控件    （初始化界面）
UpdateData(TRUE)    控件 → 成员变量    （读取输入，做校验）
```

**DoModal 返回 IDOK 之后，成员变量里就是用户输入的最新值**——框架在 `OnOK` 默认路径里调过 `UpdateData(TRUE)`。调用方这样用：

```cpp
CLoginDialog dlg(this);
dlg.m_user = m_lastUser;            // 预填
if (dlg.DoModal() == IDOK) {
    Use(dlg.m_user, dlg.m_pass);    // 直接读成员
}
```

常用 DDX 函数：`DDX_Text`（CString/int/…）、`DDX_Check`、`DDX_Radio`、`DDX_LBIndex`、`DDX_CBString`、`DDX_Control`（把控件绑定到 CWnd 成员）。常用 DDV：`DDV_MaxChars`、`DDV_MinMaxInt`。

## 4. 自定义校验：覆写 OnOK

DDV 只能管范围。业务校验（比如"用户名不能为空"）覆写 `OnOK`，校验不过就**不关对话框**：

```cpp
void OnOK() override {
    UpdateData(TRUE);               // 先把控件值抓回来
    if (m_user.IsEmpty()) {
        MessageBox(_T("用户名不能为空"), _T("校验失败"), MB_ICONWARNING);
        GetDlgItem(IDC_USER)->SetFocus();
        return;                     // 不调 EndDialog → 对话框保持打开
    }
    EndDialog(IDOK);
}
```

这是模态对话框最重要的扩展点。注意 `OnInitDialog` 返回 `TRUE` 表示把焦点给第一个 WS_TABSTOP 控件；若自己 `SetFocus` 了就返回 `FALSE`。

## 5. 非模态对话框的完整套路

非模态对话框有三个生死规则要自己处理：

```cpp
class CInfoDialog : public CDialog {
public:
    explicit CInfoDialog(CWnd* parent) : CDialog(IDD_INFO, parent) {}

    BOOL Create(CWnd* parent) { return CDialog::Create(IDD_INFO, parent); }

    void OnCancel() override { DestroyWindow(); }   // ① 点 X / Esc：销毁窗口
    void PostNcDestroy() override {
        GetOwner()->PostMessage(WM_APP_INFO_CLOSED); // ② 通知持有者清指针
        delete this;                                 // ③ 自毁 C++ 对象
    }
};
```

持有方（主窗口）：

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

为什么这么绕：`CDialog::PostNcDestroy` 默认**不** delete 自己（因为模态对话框在栈上）。堆上分配的非模态必须自己 `delete this`，而且要先让持有者把指针清空——否则主窗口持着悬空指针。程序退出时主窗口对还开着的面板只需 `DestroyWindow()`（销毁链路会触发 `PostNcDestroy → delete this`），**别再手工 delete**。

非模态对话框里的周期任务（刷新显示）用 `SetTimer`/`OnTimer`，与普通窗口无异。

## 6. 常见坑

**DoModal 之后还读对话框控件**：模态关闭后窗口没了，控件值只在成员变量里。正确姿势就是 DDX 成员。

**在 OnInitDialog 里 ShowWindow(SW_HIDE) 无效**：对话框显示前框架会按模板可见性处理。要"隐藏启动"需在 `OnWindowPosChanging` 里拦。

**DDX_DateCtrl 没有这东西**：日期用 `CDateTimeCtrl` + `DDX_DateTimeCtrl`（afxdtctl.h）。

**Esc 键直接关掉了非模态面板**：Esc 触发 `IDCANCEL` → `OnCancel`。不想要这个行为就覆写 `OnCancel` 判定来源，或改模板去掉 `DS_MODALFRAME`/改样式。

**模态对话框里再开模态**：允许，但层数多了用户会迷路。配置类界面用属性表 `CPropertySheet` 替代多层弹窗。

## 7. 实战建议

- 对话框类设计成"数据进出站"：所有控件交互封在类内部，外部只见成员变量和方法。第 13 章实战项目的设置对话框就是这个模式
- 模态对话框构造参数做"输入"，成员变量做"输出"，注释写清哪些成员是 out 参数
- 非模态面板记得处理"面板开着但内容过时"：让持有者在数据变化时调用 `UpdateText`（第 13 章统计面板的实现）

---
上一章：[05 窗口与框架类](05-frames.md) ｜ 下一章：[07 常用控件深入](07-controls.md)
