# 05 · 对话框与数据校验

> 对应示例：[examples/05_wx_dialogs.cpp](../examples/05_wx_dialogs.cpp)

对话框分两类：**标准对话框**由系统/框架提供，你只负责参数化调用（消息框、文件、颜色、字体）；**自定义对话框**从 `wxDialog` 派生，用 03 章的 sizer 排表单，再交给**校验器**（validator）做数据搬运与合法性检查。两类都以模态 `ShowModal()` 为中心——它返回标准码，是结果分派的唯一依据。

## 5.1 wxMessageDialog：样式位组合与返回值分派

```cpp
// ═══ 5.1 三类样式位：按钮组合 + 图标 + 默认按钮 ═══
wxMessageDialog dlg(this,
    wxString::FromUTF8("要继续操作吗？\n这是 wxMessageDialog。"),
    wxString::FromUTF8("确认"),
    wxYES_NO | wxCANCEL | wxICON_QUESTION | wxYES_DEFAULT | wxHELP);
int rc = dlg.ShowModal();
Log("msgbox ShowModal=%s\n",
    rc == wxID_YES ? "wxID_YES" : rc == wxID_NO ? "wxID_NO" : "CANCEL");
```

样式位分三类：按钮组合（`wxYES_NO | wxCANCEL | wxHELP`）、图标（`wxICON_QUESTION`，另有 INFORMATION/WARNING/ERROR）、默认按钮（`wxYES_DEFAULT`——回车键落在哪个按钮上）。`ShowModal()` 阻塞到用户关掉对话框，返回标准码（`wxID_YES`/`wxID_NO`/`wxID_CANCEL`...），后续逻辑围绕返回码分派。顺手一提 `wxMessageBox()` 是它的函数版快捷方式（02 章的 About 用过）。

## 5.2 wxFileDialog：通配符语法

```cpp
// ═══ 5.2 通配符："说明 (模式)|模式" 的竖线串 ═══
wxFileDialog dlg(this, wxString::FromUTF8("打开文件"), "",
                 "",
                 wxString::FromUTF8("文本文件 (*.txt;*.md)|*.txt;*.md|所有文件 (*.*)|*.*"),
                 wxFD_OPEN | wxFD_FILE_MUST_EXIST);
if (dlg.ShowModal() == wxID_OK)
    SetStatusText(dlg.GetPath());
```

通配符参数的语法是 `"说明 (模式)|模式|说明|模式"`：竖线分隔**段**，每段"文件类型说明 + 模式"；段内分号列出**多模式**（`*.txt;*.md` 同时收两种扩展名）。本例两段，文件类型下拉里出现两项。`wxFD_FILE_MUST_EXIST` 强制只能选现存文件（打开语义）；保存对话框换 `wxFD_SAVE` 并由框架询问覆盖。返回 `wxID_OK` 后 `GetPath()` 拿全路径。

## 5.3 颜色与字体对话框：Data 对象进出

```cpp
// ═══ 5.3 wxColourData 带初值进去、带选择出来 ═══
wxColourData data;
data.SetColour(*wxBLUE);
wxColourDialog dlg(this, &data);
if (dlg.ShowModal() == wxID_OK)
    SetBackgroundColour(dlg.GetColourData().GetColour());
```

这两个对话框遵循同一个模式：先填 `wxXxxData` 设初值（颜色预选蓝、字体预选当前字体），对话框吃掉它，用户选择后从 `dlg.GetXxxData()` 取结果。字体对话框顺便演示了 lambda 接线：

```cpp
// ═══ 5.4 wxFontDialog（lambda 接线）═══
Bind(wxEVT_MENU, [this](wxCommandEvent&) {
    wxFontData data;
    data.SetInitialFont(GetFont());
    wxFontDialog dlg(this, data);
    if (dlg.ShowModal() == wxID_OK)
        SetFont(dlg.GetFontData().GetChosenFont());
}, Dlg_Font);
```

三个标准对话框都栈上构造：`ShowModal` 返回后对象还活着，读结果照常进行——不需要 new/delete。

## 5.4 自定义对话框：表单 + 标准按钮排

```cpp
// ═══ 5.5 flex 表单 + 分隔按钮排 ═══
MyNameDialog::MyNameDialog(wxWindow* parent)
    : wxDialog(parent, wxID_ANY, wxString::FromUTF8("录入人员信息"),
               wxDefaultPosition, wxDefaultSize)
{
    wxBoxSizer* top = new wxBoxSizer(wxVERTICAL);
    wxFlexGridSizer* form = new wxFlexGridSizer(2, 8, 8);
    form->AddGrowableCol(1);
    ...   // 两行：姓名 + 年龄，标签列固定、输入列拉伸（03 章套路）
    top->Add(form, 0, wxEXPAND | wxALL, 12);
    top->Add(CreateSeparatedButtonSizer(wxOK | wxCANCEL), 0, wxEXPAND | wxALL, 8);  // 标准按钮排

    SetSizerAndFit(top);
}
```

自定义对话框就是一个小 frame：sizer 排布局、`SetSizerAndFit` 收尾。关键一行是 `CreateSeparatedButtonSizer(wxOK | wxCANCEL)`——生成带上方分隔线的平台惯例按钮排（Windows 上 OK 在左，别的平台可能对调），按钮 ID 是标准 `wxID_OK`/`wxID_CANCEL`，wxDialog 已内建它们的处理：点 OK 先 `Validate()` 后 `TransferDataFromWindow()`，全过才关窗。所以**保存逻辑写在 Transfer 钩子里，不要自己 Bind OK 按钮**。

## 5.5 校验器与 Transfer 钩子：数据搬运自动化

```cpp
// ═══ 5.6 两种校验器：文本过滤 + 通用直通 ═══
m_nameCtrl = new wxTextCtrl(this, wxID_ANY);
// 校验器：绑到控件 + 指向"模型"成员，Validate/Transfer 时自动搬运。
// wx 3.3 的 wxTextValidator 没有 SetMinLength——长度校验自己做。
m_nameCtrl->SetValidator(wxTextValidator(wxFILTER_ALPHANUMERIC, &m_name));
...
m_ageCtrl->SetValidator(wxGenericValidator(&m_age));   // 通用校验器：整型直通
```

校验器是控件与"模型"之间的自动搬运工：`wxTextValidator(过滤器, &m_name)` 把姓名输入框绑到成员 `m_name`，`wxFILTER_ALPHANUMERIC` 声明只收字母数字；`wxGenericValidator` 不做内容过滤，按类型（int/bool/wxString...）直通搬运。本例的"模型"就是对话框自己的 public 成员，调用方 `dlg.m_name = "Tom"` 放初值、模态返回后读结果。

搬运钩子可以重写来显式化这条通路：

```cpp
// ═══ 5.7 TransferDataToWindow / FromWindow：双向搬运 ═══
bool MyNameDialog::TransferDataToWindow()
{
    if (!wxDialog::TransferDataToWindow()) return false;
    m_nameCtrl->SetValue(m_name);        // 模型 → 控件
    m_ageCtrl->SetValue(m_age);
    return true;
}
bool MyNameDialog::TransferDataFromWindow()
{
    if (!wxDialog::TransferDataFromWindow()) return false;
    m_name = m_nameCtrl->GetValue();     // 控件 → 模型
    m_age = m_ageCtrl->GetValue();
    return true;
}
```

基类版本会驱动各控件的校验器完成它们那份搬运；派生版本先调基类（失败即短路），再补自定义部分——本例成员与控件一一对应，校验器其实已覆盖，钩子写出来是把"模型 → 控件"这条通路明明白白摊开。过滤器是**第一道闸**：非法字符在按键层就被吃掉（`wxFILTER_ALPHA` 直接不收数字），根本到不了提交；`Validate()` 是第二道闸，拦"过滤管不着"的情况。要长度下限就自己在 `TransferDataFromWindow` 里查 `length()`，返回 false 即可拦住关窗——wx 3.3 的 `wxTextValidator` 没有 `SetMinLength`。

## 5.6 运行与输出：绕开 ShowModal 的自动化验证

模态对话框会卡死无人值守的 selftest，所以验证路径完全绕开 `ShowModal`：手工调 Transfer 钩子 + 只走 Validate 正路径。

```cpp
// ═══ 5.8 selftest：构造 → 搬运 → 校验，全程不弹窗 ═══
MyNameDialog dlg(this);
dlg.m_name = "Tom123";
dlg.m_age = 20;
dlg.TransferDataToWindow();               // 模型 → 控件
Log("after ToWindow: ctrl=%s（TransferData 搬运可见）\n",
    (const char*)dlg.m_nameCtrl->GetValue().utf8_str());

dlg.m_nameCtrl->SetValue("legal9");
Log("Validate(legal input)=%d\n", (int)dlg.Validate());
// 注意：非法输入走 Validate 会弹「Validation conflict」模态框
// （src/common/valtext.cpp:144 wxMessageBox），selftest 不能碰——
// 负路径由交互模式（菜单 → 自定义对话框）演示。
dlg.m_nameCtrl->SetValue("abc");
dlg.TransferDataFromWindow();             // 控件 → 模型
Log("after FromWindow: m_name=%s len=%zu\n",
    (const char*)dlg.m_name.utf8_str(), dlg.m_name.length());
```

selftest 实测输出（sidecar 文件 `build/docs-ref/05_wx_dialogs.sidecar` 摘录一次运行，三次连跑逐字节一致）：

```text
==== 05 wx 对话框 开始 ====
after ToWindow: ctrl=Tom123（TransferData 搬运可见）
Validate(legal input)=1
after FromWindow: m_name=abc len=3
probe validator filter ok（构造成功）
==== 05 wx 对话框 结束 ====
```

三行证据：`ctrl=Tom123` 说明模型 → 控件搬运生效；`Validate(legal input)=1` 是合法输入通过校验；`m_name=abc len=3` 是控件 → 模型回搬。最后一行 `probe` 是单独构造的一个 `wxFILTER_ALPHA` 校验器探针（只验构造可用）。负路径（非法输入触发拦截）刻意不进 selftest——原因见坑位清单第一条。

## 坑位清单

- **Validate 的负路径会弹模态框**：非法输入时 `wxTextValidator` 内部直接 `wxMessageBox` 弹「Validation conflict」（wx 3.3 源码 src/common/valtext.cpp:144），自动化测试一碰就挂起——负路径只能留给交互演示，selftest 只走正路径（源码注释原话）。
- **wxTextValidator 无 SetMinLength**：wx 3.3 的文本校验器只有字符过滤器，长度下限要在 `TransferDataFromWindow` 里自己查——钩子返回 false 同样拦住关窗（源码注释 + ae14a03 坑位）。
- **过滤器与 Validate 是两道闸**：`wxFILTER_*` 在按键层吃掉非法字符（空值、过短这类"合法字符组成的不合法输入"它管不着），`Validate()` 管内容规则——只设过滤器就以为校验完备，是常见漏算。
- **OK 按钮别自己 Bind**：`CreateSeparatedButtonSizer` 的标准 ID 由 wxDialog 内建处理（先 Validate 后 Transfer 再关窗）；自己 Bind `wxID_OK` 又不 `Skip()`，会抢先吞掉内建链，校验搬运全被跳过。
- **标准对话框栈上构造即可**：`ShowModal` 返回后对象仍在作用域内，`GetPath()`/`GetColourData()` 照常读——new 到堆上反而要操心删除时机。

---

上一章：[04 · 常用控件与事件绑定](04-wx-controls.md) ｜ 下一章：[06 · DC 绘图：双缓冲与抗锯齿](06-wx-drawing.md) ｜ 返回：[README](../README.md)
