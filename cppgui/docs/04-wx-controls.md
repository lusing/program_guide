# 04 · 常用控件与事件绑定

> 对应示例：[examples/04_wx_controls.cpp](../examples/04_wx_controls.cpp)

控件是保留模式的"状态容器"：wx 约定每个控件实现 `SetValue`/`GetValue` 统一值接口，值就住在控件里，读写都找它——与 08 章 Dear ImGui"状态在外部变量、每帧重新提交"形成范式对照。本章把常用控件一次走完：按钮/复选/单选、Choice/ComboBox、Slider/SpinCtrl/Gauge、多行文本、ListCtrl 报表，每个都配 `Bind` 接线；selftest 再反过来程序化设值、读回验证。

## 4.1 按钮与复选框：事件里改状态

```cpp
// ═══ 4.1 按钮计数：lambda 处理器 + 状态栏回显 ═══
m_btn = new wxButton(this, wxID_ANY, wxString::FromUTF8("点我 +1"));
m_btn->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) {
    ++m_clickCount;
    SetStatusText(wxString::Format("clicked=%d", m_clickCount), 0);
});

// ═══ 4.2 复选框：事件里即时取值 ═══
m_check = new wxCheckBox(this, wxID_ANY, wxString::FromUTF8("启用夜间模式"));
m_check->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent& e) {
    Log("checkbox -> %d\n", (int)e.IsChecked());   // 事件里即时取值
});
```

按钮是"无值"控件，事件只承担通知，状态（计数）存在 frame 成员里；复选框有 bool 值，事件对象直接带结果 `e.IsChecked()`。这里也展示了 Bind 接 lambda 的形态——捕获 `this`，处理器体就是普通函数体。

## 4.2 RadioBox：枚举值控件

```cpp
// ═══ 4.3 RadioBox：选项数组 + 个数 + majorDimension ═══
const wxString modes[] = { wxString::FromUTF8("低"), wxString::FromUTF8("中"), wxString::FromUTF8("高") };
m_radio = new wxRadioBox(this, wxID_ANY, wxString::FromUTF8("画质"),
                         wxDefaultPosition, wxDefaultSize, 3, modes, 1, wxRA_SPECIFY_COLS);
m_radio->Bind(wxEVT_RADIOBOX, [this](wxCommandEvent& e) {
    Log("radiobox -> sel=%d label=%s\n", e.GetInt(),
        (const char*)m_radio->GetStringSelection().utf8_str());
});
```

注意第 8 参 `1` 是 **majorDimension**：配 `wxRA_SPECIFY_COLS` 它表示列数（3 项竖排 1 列），配 `wxRA_SPECIFY_ROWS` 它表示行数——同一个数字两种语义，读代码先看 style。取值有两条路：`e.GetInt()` 事件里给序号，`GetStringSelection()` 随时给文本；`wxString` 转 UTF-8 字节给 printf 的惯用法是 `(const char*)str.utf8_str()`。

## 4.3 Choice 与 ComboBox：只读下拉 vs 可编辑下拉

```cpp
// ═══ 4.4 Choice（只读下拉）与 ComboBox（可输入）═══
m_choice = new wxChoice(this, wxID_ANY);
m_choice->Append(wxArrayString{ "alpha", "beta", "gamma" });
m_choice->SetSelection(0);
m_choice->Bind(wxEVT_CHOICE, [this](wxCommandEvent& e) {
    Log("choice -> %s\n", (const char*)e.GetString().utf8_str());
});

m_combo = new wxComboBox(this, wxID_ANY, "");   // 可输入，也能 SetValue
m_combo->Append(wxArrayString{ wxString::FromUTF8("北京"), wxString::FromUTF8("上海"), wxString::FromUTF8("深圳") });
m_combo->Bind(wxEVT_COMBOBOX, [this](wxCommandEvent& e) {
    Log("combobox -> %s\n", (const char*)e.GetString().utf8_str());
});
```

`wxChoice` 只能选列表项；`wxComboBox` 是下拉+编辑框合体，值可以是列表外的任意文本，`SetValue` 直填。事件名不同（`wxEVT_CHOICE` vs `wxEVT_COMBOBOX`），但都给 `wxCommandEvent`、都能 `e.GetString()` 拿选中项。

## 4.4 数值三件套：Slider / SpinCtrl / Gauge

```cpp
// ═══ 4.5 数值控件：注意事件参数类型开始分化 ═══
m_slider = new wxSlider(this, wxID_ANY, 30, 0, 100,
                        wxDefaultPosition, wxDefaultSize, wxSL_HORIZONTAL | wxSL_LABELS);
m_slider->Bind(wxEVT_SLIDER, [this](wxCommandEvent&) {
    Log("slider -> %d\n", m_slider->GetValue());
});

m_spin = new wxSpinCtrl(this, wxID_ANY, "1", wxDefaultPosition, wxDefaultSize,
                        wxSP_ARROW_KEYS, 1, 100, 1);
m_spin->Bind(wxEVT_SPINCTRL, [this](wxSpinEvent& e) {
    Log("spin -> %d\n", e.GetValue());
});

m_gauge = new wxGauge(this, wxID_ANY, 100);
m_gauge->SetValue(30);
```

- **Slider** 构造参数是 (id, 初始值 30, 最小 0, 最大 100)，`wxSL_LABELS` 让两端显示当前值；事件给 `wxCommandEvent`，值从 `GetValue()` 读。
- **SpinCtrl** 同样是 min/max/初值（1/100/1），`wxSP_ARROW_KEYS` 带上下箭头键支持；但事件给的是 **`wxSpinEvent`** 不是 `wxCommandEvent`——Bind 处理器签名必须对上。
- **Gauge 是纯输出控件**：没有事件可绑，`SetValue(30)` 直填进度。本例静态填 30/66；07 章由后台线程经事件驱动它逐格走。

## 4.5 多行文本 wxTextCtrl

```cpp
// ═══ 4.6 多行 rich2 编辑 + 流式写入 ═══
m_multi = new wxTextCtrl(this, wxID_ANY, "",
                         wxDefaultPosition, wxSize(-1, 120),
                         wxTE_MULTILINE | wxTE_RICH2);
*m_multi << wxString::FromUTF8("第一行：多行编辑\n第二行：rich2\n");
```

`wxTE_MULTILINE` 变多行编辑，`wxTE_RICH2` 在 Windows 上选用新版 richedit 内核（长文本与撤销行为更好）。`operator<<` 让文本框能接流式写入——像 cout 一样往里追加。行数用 `GetNumberOfLines()` 查（selftest 输出里它会数出 3，含收尾换行产生的空行）。

## 4.6 wxListCtrl：report 报表模式

```cpp
// ═══ 4.7 三步填表：建列 → 建行 → 填格 ═══
m_list = new wxListCtrl(this, wxID_ANY, wxDefaultPosition, wxSize(-1, 160),
                        wxLC_REPORT | wxBORDER_SUNKEN);
m_list->InsertColumn(0, "ID", wxLIST_FORMAT_LEFT, 60);
m_list->InsertColumn(1, wxString::FromUTF8("名称"), wxLIST_FORMAT_LEFT, 160);
m_list->InsertColumn(2, wxString::FromUTF8("数量"), wxLIST_FORMAT_RIGHT, 80);
const char* names[] = { "apple", "banana", "cherry" };
for (int i = 0; i < 3; ++i)
{
    long idx = m_list->InsertItem(i, wxString::Format("%d", 100 + i));
    m_list->SetItem(idx, 1, names[i]);
    m_list->SetItem(idx, 2, wxString::Format("%d", (i + 1) * 7));
}
m_list->Bind(wxEVT_LIST_ITEM_SELECTED, [this](wxListEvent& e) {
    Log("list selected -> %ld\n", (long)e.GetIndex());
});
```

`wxLC_REPORT` 是带表头的表格模式。填表是**三步**：`InsertColumn` 先建列（列号、标题、对齐、宽度）；`InsertItem` 建行并顺带填第 0 列，返回行号；`SetItem(idx, col, text)` 填其余列——顺序颠倒，`SetItem` 无行可填。第三列 `wxLIST_FORMAT_RIGHT` 数字右对齐，是报表惯例。选中事件给 `wxListEvent`，`GetIndex()` 是行号。

## 4.7 运行与输出：值接口回读 + 合成事件注入

selftest 到点后逐控件 `SetValue` 再 `GetValue` 回读，验证值接口本身；最后合成一次按钮点击：

```cpp
// ═══ 4.8 selftest：程序化设值 → 读回 ═══
m_radio->SetSelection(2);
Log("radio GetSelection=%d label=%s\n", m_radio->GetSelection(),
    (const char*)m_radio->GetStringSelection().utf8_str());
...
m_combo->SetValue(wxString::FromUTF8("广州"));   // 【坑】窄字面量按本地编码(GBK)解释，中文必须 FromUTF8
Log("combo GetValue=%s\n", (const char*)m_combo->GetValue().utf8_str());
...
// 模拟一次按钮点击（不经过鼠标）：构造命令事件直接投给控件
wxCommandEvent e(wxEVT_BUTTON, m_btn->GetId());
m_btn->ProcessWindowEvent(e);
Log("clicks after synthetic click=%d\n", m_clickCount);
```

合成事件是本例的关键一招：`wxCommandEvent(wxEVT_BUTTON, id)` 手工构造，`ProcessWindowEvent` 投回控件——事件走完整派发链（包括 Bind 的 lambda），所以验证的是"接线 + 处理器"整体，而不是绕过接线直调函数。

selftest 实测输出（sidecar 文件 `build/docs-ref/04_wx_controls.sidecar` 摘录一次运行，三次连跑逐字节一致）：

```text
==== 04 wx 控件大全 开始 ====
check GetValue=1
radio GetSelection=2 label=高
choice GetSelection=2
combo GetValue=广州
slider GetValue=77
spin GetValue=42
gauge GetValue=66
clicks after synthetic click=1
list GetItemCount=3, row1 text=101
multi lines=3
==== 04 wx 控件大全 结束 ====
```

逐行对应：`check=1`/`radio=2 高`/`choice=2`（gamma 是第 3 项）/`slider=77`/`spin=42`/`gauge=66` 全是"设了什么读回什么"；`combo GetValue=广州` 证明 FromUTF8 链路通畅——若窄字面量直传，这一行当场乱码；`clicks after synthetic click=1` 说明合成事件真的把 lambda 跑了一遍；`row1 text=101` 是 `GetItemText(1)` 取第二行（0 起）第 0 列；`multi lines=3` 即两行文本加收尾换行的一个空行。

## 坑位清单

- **窄字面量中文按 GBK 解释**：`m_combo->SetValue("广州")` 直接乱码，必须 `wxString::FromUTF8("广州")`——源码【坑】标注行，也是本批提交（ae14a03）实测坑位（rc 资源与 app 名同病）。中文进 `wxString` 只有 FromUTF8 一条正路。
- **事件参数类型因控件而异**：Button/CheckBox/RadioBox/Choice/ComboBox/Slider 都给 `wxCommandEvent`，SpinCtrl 给 `wxSpinEvent`、ListCtrl 给 `wxListEvent`——Bind 的处理器签名与事件类型错位是编译错，但报错点在 Bind 那行，别只盯着处理器看。
- **RadioBox 的 majorDimension 双语义**：同一个构造参数，配 `wxRA_SPECIFY_COLS` 是列数、配 `wxRA_SPECIFY_ROWS` 是行数——抄示例时把 style 和数字一起抄，单抄数字必错。
- **ListCtrl 填格三步不能乱序**：`InsertColumn` → `InsertItem`（返回行号、填第 0 列）→ `SetItem`（其余列）；列没建先插行、行没插先填格，都是白填。
- **Gauge 无事件**：它是输出指示器，别指望"进度走完"有通知；驱动逻辑（定时器/线程）自己掌握节奏，本例直填、07 章线程驱动。

---

上一章：[03 · Sizer 布局：盒子、网格与弹性](03-wx-sizers.md) ｜ 下一章：[05 · 对话框与数据校验](05-wx-dialogs.md) ｜ 返回：[README](../README.md)
