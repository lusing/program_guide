# 03 · Sizer 布局：盒子、网格与弹性

> 对应示例：[examples/03_wx_sizers.cpp](../examples/03_wx_sizers.cpp)

绝对坐标摆控件在真实应用里活不过第一次 resize。wx 的答案是 Sizer 布局系统：不给控件坐标，而是描述"谁拉伸、谁固定、间距多少"——窗口尺寸变化后按权重重新分配空间，是保留模式下的响应式布局。本章走读四种 sizer（Box/Grid/FlexGrid/Wrap）加链式风格的 `wxSizerFlags`，最后看布局计算如何被 selftest 断言。

## 3.1 布局思维：描述而非摆放

Sizer 不直接管理控件，而是管理 `wxSizerItem`——每个 Add 进去的窗口（或子 sizer、或 spacer）包成一个条目，记下它的 proportion、flags、border。窗口 resize 时，sizer 按条目的权重重算每个孩子的位置和大小。由此推论两件事：**嵌套是常态**——一个横向盒子放进一个纵向 root，就是"工具条一行 + 下面若干区块"的结构；**最小尺寸自下而上聚合**——每个控件报告自己的最佳尺寸（按钮按文字宽度），父 sizer 聚合出整窗最小需求，`CalcMin()` 就从这个链条算出来。

示例里所有按钮都走一个小工厂函数，把"中文必须 FromUTF8"集中管起来：

```cpp
// ═══ 3.1 中文标签小工厂：统一 FromUTF8 ═══
static wxButton* MkBtn(wxWindow* parent, const char* label)
{
    return new wxButton(parent, wxID_ANY, wxString::FromUTF8(label));
}
```

一处封装，全文件 20 来个按钮不再各自面对编码问题——02 章坑位清单里那条 GBK 陷阱的工程化解法。后文 `MkBtn(this, "拉伸(p=1)")` 都是这个函数。

## 3.2 wxBoxSizer：proportion 与 border

```cpp
// ═══ 3.2 proportion：0 保最佳尺寸，>0 按权重分剩余空间 ═══
wxBoxSizer* box = new wxBoxSizer(wxHORIZONTAL);
box->Add(MkBtn(this, "固定(p=0)"), 0, wxALL, 4);
box->Add(MkBtn(this, "拉伸(p=1)"), 1, wxALL | wxEXPAND, 4);
box->Add(MkBtn(this, "拉伸(p=2)"), 2, wxALL | wxEXPAND, 4);
box->AddSpacer(16);                       // spacer：纯占位
box->Add(MkBtn(this, "右贴"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 4);
```

`Add` 的完整签名是 `Add(window, proportion, flags, border, userData)`，这一行浓缩了 sizer 布局的大部分语义：

- **proportion 管主轴**：横向盒子的主轴是宽度。p=0 的按钮保持最佳尺寸不参与分配；p=1 与 p=2 的按钮把剩余宽度按 1:2 分掉。
- **wxEXPAND 管交叉轴**：管高度。不加它，控件在交叉轴按最佳尺寸+对齐旗标摆放；加了它，填满交叉轴。
- **对齐旗标管"不拉伸时怎么放"**：`wxALIGN_CENTER_VERTICAL` 让"右贴"按钮在行内垂直居中，与"拉伸"按钮的 `wxEXPAND` 是两种姿态。
- **border 与 wxALL**：`wxALL` 四边各留 4 像素；配 `wxLEFT`/`wxTOP` 等则只留指定边。

注意 `wxEXPAND` 与对齐旗标互斥：填满了就无所谓对齐，两者同传时对齐旗标无效。

## 3.3 GridSizer 与 FlexGridSizer

```cpp
// ═══ 3.3 GridSizer：等宽等高格 ═══
wxGridSizer* grid = new wxGridSizer(3, 2, 4, 4);   // 3 列 2 行，间隙 4x4
for (int i = 1; i <= 6; ++i)
    grid->Add(MkBtn(this, std::to_string(i).c_str()), 0, wxEXPAND);

// ═══ 3.4 FlexGridSizer：行列按内容，可指定拉伸列 ═══
m_flex = new wxFlexGridSizer(2, 8, 8);    // 2 列，间隙 8x8
m_flex->AddGrowableCol(1);                // 第 2 列吃掉剩余宽度
m_flex->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("用户名：")), 0, wxALIGN_CENTER_VERTICAL);
m_flex->Add(new wxTextCtrl(this, wxID_ANY), 0, wxEXPAND);
m_flex->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("密码：")), 0, wxALIGN_CENTER_VERTICAL);
// 【实测坑位】wxTextCtrl 第 3 参是"初值"而非样式——直接传
// wxTE_PASSWORD 会撞上故意私有化的 wxString(int)，报 C2248。
m_flex->Add(new wxTextCtrl(this, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD), 0, wxEXPAND);
```

`wxGridSizer` 是均格：每格等宽等高，参数依次为列数、行数、横向间隙、纵向间隙。`wxFlexGridSizer` 灵活一档：行高、列宽按该行/列最胖的内容决定，`AddGrowableCol(1)` 再把第 1 列（0 起）标记为可拉伸——标签列按文字宽度收紧、输入列吃掉剩余宽度，正是桌面表单的标准形态（标签垂直居中对齐输入框）。坑在最后两行：`wxTextCtrl` 第 3 参是**初值**不是样式，想偷懒把 `wxTE_PASSWORD` 顶上去，会撞上故意私有化的 `wxString(int)` 构造函数，编译器报 C2248——正确写法用 `""` 占住初值位，样式老老实实放第 6 参。

## 3.4 WrapSizer：流式换行

```cpp
// ═══ 3.5 WrapSizer：放不下自动换行 ═══
m_wrap = new wxWrapSizer(wxHORIZONTAL, wxWRAPSIZER_DEFAULT_FLAGS);
for (int i = 0; i < 8; ++i)
    m_wrap->Add(MkBtn(this, ("标签" + std::to_string(i + 1)).c_str()), 0, wxALL, 2);
```

`wxWrapSizer` 是水平流式布局：宽度不够时把后面的项折到下一行，行为类似网页的行内元素——标签云、工具条分组用它最顺手。

## 3.5 wxSizerFlags：链式现代写法

```cpp
// ═══ 3.6 wxSizerFlags 链式 + 弹性 spacer ═══
wxBoxSizer* flagsBox = new wxBoxSizer(wxHORIZONTAL);
flagsBox->Add(MkBtn(this, "Flags 左"), wxSizerFlags().Border(wxALL, 8).CenterVertical());
flagsBox->AddStretchSpacer(1);
flagsBox->Add(MkBtn(this, "Flags 右"), wxSizerFlags().Right().Border(wxALL, 8));
```

`Add` 有一个接收 `wxSizerFlags` 的重载——没有裸 proportion 参数，比例搬进 `wxSizerFlags().Proportion(n)`，边距、对齐、展开全部链式表达，读起来像一句话："左边这个按钮，四边 8 像素边距，垂直居中"。同一个布局两种写法完全等价，新代码建议 flags 风格，参数含义自文档化。

同节还对照了两种占位：`AddSpacer(16)` 是**固定** 16 像素的空隙；`AddStretchSpacer(1)` 是**弹性**空隙，按权重吃剩余空间——"标签靠左、按钮靠右"的经典排版用后者，不需要手算中间宽度。

## 3.6 嵌套组装与 SetSizerAndFit

```cpp
// ═══ 3.7 纵向 root 装五个区块，区块间用 border 隔开 ═══
m_root->Add(box, 0, wxEXPAND | wxALL, 6);
m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— GridSizer 3x2 ——")), 0, wxALL, 2);
m_root->Add(grid, 0, wxEXPAND | wxALL, 6);
m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— FlexGrid（第 2 列可拉伸）——")), 0, wxALL, 2);
m_root->Add(m_flex, 0, wxEXPAND | wxALL, 6);
m_root->Add(new wxStaticText(this, wxID_ANY, wxString::FromUTF8("—— WrapSizer（缩窗换行）——")), 0, wxALL, 2);
m_root->Add(m_wrap, 0, wxEXPAND | wxALL, 6);
m_root->Add(flagsBox, 0, wxEXPAND);

SetSizerAndFit(m_root);      // 挂 sizer 并按内容适配最小尺寸
```

复杂布局 = 小 sizer 的组合，不是一张大网格硬调：box、grid、flex、wrap 各自是独立的布局单元，纵向 root 只决定区块顺序与区块间距；每个区块 proportion=0（不随窗口变高），配 `wxEXPAND` 横向填满。夹在中间的 `wxStaticText` 是区块小标题，border 压到 2 让它贴近自己的区块——它标注"下面这块用的是什么 sizer"，运行时把窗口拖窄，WrapSizer 那一块应声折行，其余区块纹丝不动。最后一行 `SetSizerAndFit` 把 sizer 挂上窗口，并把 `CalcMin()` 算出的最小尺寸设为窗口尺寸约束——它就是"窗口不会缩到比内容还小"的保证。

## 3.7 运行与输出

布局是纯计算，selftest 不需要任何交互：直接问 sizer 要结构计数与最小尺寸。

```cpp
// ═══ 3.8 布局计算的确定性断言 ═══
Log("root children=%d (5 个区块 + 3 个小标题)\n", (int)m_root->GetChildren().GetCount());
wxSize minRoot = m_root->CalcMin();
Log("root CalcMin = %dx%d\n", minRoot.x, minRoot.y);

wxSize minFlex = m_flex->CalcMin();
Log("flex CalcMin = %dx%d（两行文本框的最小需求）\n", minFlex.x, minFlex.y);
...
wxSizerItem* first = m_root->GetChildren()[0];
Log("box 区块 proportion=%d, border=%d\n",
    first->GetProportion(), (int)first->GetBorder());
```

selftest 实测输出（sidecar 文件 `build/docs-ref/03_wx_sizers.sidecar` 摘录一次运行，三次连跑逐字节一致）：

```text
==== 03 wx Sizer 布局 开始 ====
root children=8 (5 个区块 + 3 个小标题)
root CalcMin = 733x561
flex CalcMin = 286x80（两行文本框的最小需求）
wrap children=8
box 区块 proportion=0, border=6
==== 03 wx Sizer 布局 结束 ====
```

值得盯两个数字：`root CalcMin = 733x561` **大于**构造 frame 时给的 `wxSize(560, 520)`——`SetSizerAndFit` 已经按内容最小需求把窗口撑大，这正是它的职责（也是"内容装不下"类 bug 的诊断入口：先打 CalcMin 再对比窗口尺寸）。`box 区块 proportion=0, border=6` 与 `m_root->Add(box, 0, wxEXPAND | wxALL, 6)` 逐参数吻合——`wxSizerItem` 把 Add 时的承诺原样记住了。两处 `children=8` 数的也都是条目不是控件：root 的 8 = 5 个区块 + 3 个小标题，wrap 的 8 = 8 个标签按钮——`GetChildren()` 返回的是 `wxSizerItem` 列表，每次 Add（包括加 spacer）都会多一个条目。

## 坑位清单

- **wxTextCtrl 第 3 参是初值不是样式**：把 `wxTE_PASSWORD` 当第 3 参传，撞上故意私有化的 `wxString(int)` 构造，MSVC 报 C2248——初值位给 `""`，样式给第 6 参（源码【实测坑位】注释）。
- **proportion 管主轴、wxEXPAND 管交叉轴**：横向盒子里 p=2 的按钮分到两倍剩余宽度，但高度不变；要填满高度必须另加 `wxEXPAND`。两个维度两套开关，新手最常只给一半然后疑惑"为什么没铺满"。
- **对齐旗标与 wxEXPAND 互斥**：`wxALIGN_CENTER_VERTICAL` 描述的是不展开时的摆法；一旦 `wxEXPAND` 填满交叉轴，对齐旗标无从谈起，同传时后者被忽略。
- **AddSpacer 固定、AddStretchSpacer 弹性**：前者是硬像素占位，后者按比例吃剩余空间。"左标签右按钮"的排版用 StretchSpacer，不是手算中间空多少像素。
- **SetSizerAndFit 会改窗口尺寸**：内容最小需求大于初始尺寸时直接撑大（本例 733x561 > 560x520）；只想挂布局不动窗口，用 `SetSizer`——07 章就是后者（窗口尺寸由构造参数定）。

---

上一章：[02 · 菜单、工具栏与命令](02-wx-menus.md) ｜ 下一章：[04 · 常用控件与事件绑定](04-wx-controls.md) ｜ 返回：[README](../README.md)
