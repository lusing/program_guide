# 02 · 菜单、工具栏与命令

> 对应示例：[examples/02_wx_menus.cpp](../examples/02_wx_menus.cpp)

01 章的窗口只有骨架；本章把它变成"会响应命令的应用"。主角是**命令**（command）：菜单项、工具栏按钮、加速键、右键菜单项，在 wx 里全部汇成同一类事件 `wxEVT_MENU`，靠整数命令号区分彼此。围绕命令，本章覆盖菜单组装的 Append 全家、事件表与 Bind 两种接线写法的对照、分区状态栏，以及新手最容易漏掉的 UPDATE_UI 机制——UI 状态（禁用/勾选）不靠点击驱动，而是每空闲拍集中刷新。

## 2.1 命令号：命令的身份标识

```cpp
// ═══ 2.1 命令号：自定义从 100 起，避开标准 ID ═══
enum
{
    Menu_File_New = 100,
    Menu_File_Open,
    Menu_File_Save,
    Menu_File_AutoSave,     // checkable
    Menu_View_Mode1,        // radio 组
    Menu_View_Mode2,
    Menu_View_Mode3,
    Menu_Help_About = wxID_ABOUT,
};
```

wx 用整数 ID 标识命令：菜单项点击、工具栏按钮、`\tCtrl-N` 加速键、右键菜单项，ID 相同即同一命令——后面工具栏直接复用菜单命令号，处理器只写一份。自定义 ID 从 100 起，避开 `wxID_EXIT`/`wxID_ABOUT` 等标准 ID；枚举里 `Menu_Help_About = wxID_ABOUT` 则是故意挂靠标准 About，让 macOS 把它安置进系统菜单。不初始化的枚举成员自动续号，由此得到一段**连续命令号区间**，2.3 节的范围 Bind 正好用上。

## 2.2 菜单组装：Append 全家

```cpp
// ═══ 2.2 五种 Append：普通/勾选/单选/分隔线/子菜单 ═══
wxMenu* fileMenu = new wxMenu;
fileMenu->Append(Menu_File_New,  "&New\tCtrl-N",   "Create new document");
fileMenu->Append(Menu_File_Open, "&Open...\tCtrl-O", "Open existing");
fileMenu->Append(Menu_File_Save, "&Save\tCtrl-S",  "Save (disabled until modified)");
fileMenu->AppendSeparator();
fileMenu->AppendCheckItem(Menu_File_AutoSave, "A&uto-save", "Checkable item");
fileMenu->AppendSeparator();
fileMenu->Append(wxID_EXIT, "E&xit\tAlt-X");

// 视图菜单：单选组（radio items 自动互斥）
wxMenu* viewMenu = new wxMenu;
viewMenu->AppendRadioItem(Menu_View_Mode1, wxString::FromUTF8("模式：紧凑"));
viewMenu->AppendRadioItem(Menu_View_Mode2, wxString::FromUTF8("模式：舒适"));
viewMenu->AppendRadioItem(Menu_View_Mode3, wxString::FromUTF8("模式：宽大"));
viewMenu->Check(Menu_View_Mode2, true);          // 程序化勾选

// 嵌套子菜单
wxMenu* sub = new wxMenu;
sub->Append(Menu_File_New, "子菜单项 A");
sub->Append(Menu_File_Open, "子菜单项 B");
fileMenu->AppendSeparator();
fileMenu->AppendSubMenu(sub, "&More...");
```

四个要点：

- **助记符与加速键写在标签里**：`"E&xit"` 的 x 带下划线（Alt 串联定位），`"\tCtrl-N"` 跟在标签尾部注册加速键；第三参是状态栏提示文本。
- **AppendCheckItem** 产生可勾选项，勾选态用 `IsChecked()` 读。
- **AppendRadioItem** 连续追加的项自动互斥成组，`Check(id, true)` 在构造期就能程序化选中某一档。
- **AppendSubMenu** 挂子菜单，子菜单项照常复用已有命令号——"子菜单项 A"与主菜单 New 同 ID，一处接线两处触发。

组装完挂上菜单栏，三行收尾：

```cpp
// ═══ 2.3 菜单 → 菜单栏 → frame ═══
wxMenuBar* bar = new wxMenuBar;
bar->Append(fileMenu, "&File");
bar->Append(viewMenu, "&View");
bar->Append(helpMenu, "&Help");
SetMenuBar(bar);
```

## 2.3 事件表 vs Bind：同一 frame 的双轨对照

02 例故意把命令分给两种接线方式，在同一个 frame 里并存对照：

```cpp
// ═══ 2.4 静态事件表：编译期接线（01 章写法）═══
wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    EVT_MENU(wxID_EXIT,  MyFrame::OnQuit)     // 静态事件表（对照 01 章）
    EVT_MENU(Menu_Help_About, MyFrame::OnAbout)
    EVT_MENU(Menu_File_New,   MyFrame::OnNew)
    EVT_TIMER(wxID_ANY, MyFrame::OnSelftestTimer)
wxEND_EVENT_TABLE()

// ═══ 2.5 动态 Bind：运行期接线 ═══
Bind(wxEVT_MENU, &MyFrame::OnOpen,  this, Menu_File_Open);
Bind(wxEVT_MENU, &MyFrame::OnSave,  this, Menu_File_Save);
Bind(wxEVT_MENU, &MyFrame::OnToggleAutoSave, this, Menu_File_AutoSave);
Bind(wxEVT_MENU, &MyFrame::OnViewMode, this, Menu_View_Mode1, Menu_View_Mode3);
Bind(wxEVT_UPDATE_UI, &MyFrame::OnUpdateSave, this, Menu_File_Save);
Bind(wxEVT_RIGHT_UP, &MyFrame::OnRightUp, this);
```

处理器函数形态完全一样（普通成员函数收 `wxCommandEvent&`），区别在接线时机与能力：事件表是编译期展开的静态查找表，声明式、零运行期开销；Bind 是运行期接线，能接 lambda（05 章有实例）、能跨对象，还支持 **ID 范围**——`Bind(wxEVT_MENU, &MyFrame::OnViewMode, this, Menu_View_Mode1, Menu_View_Mode3)` 末两个参数是"首 ID、末 ID"，一行接住三个 radio 项，处理器里 `e.GetId() - Menu_View_Mode1` 算出选中第几档。同一事件两条路都通，混用合法（本例 Quit/New 走表、Open/Save 走 Bind）；新代码推荐 Bind，事件表写法在读官方示例时必须认识。

## 2.4 工具栏：复用命令号，事件同源

```cpp
// ═══ 2.6 AddTool 第 1 参就是命令号，图标用 wxArtProvider ═══
wxToolBar* tb = CreateToolBar();
tb->AddTool(Menu_File_New,  "New",  wxArtProvider::GetBitmap(wxART_NEW));
tb->AddTool(Menu_File_Open, "Open", wxArtProvider::GetBitmap(wxART_FILE_OPEN));
tb->AddTool(Menu_File_Save, "Save", wxArtProvider::GetBitmap(wxART_FILE_SAVE));
tb->AddSeparator();
tb->AddTool(Menu_Help_About, "About", wxArtProvider::GetBitmap(wxART_HELP));
tb->Realize();               // 添加完必须 Realize
```

工具栏不发明新命令体系：`AddTool` 第一个参数就是菜单命令号，点击发出的同样是 `wxEVT_MENU`——2.3 节那几行 Bind 同时管住菜单项、工具栏按钮和加速键，处理器零新增。图标来自 `wxArtProvider` 标准图标集（跨平台取各平台主题内建图标），示例不用自己切图。最后 `Realize()` 把攒下的工具布局落地——忘掉它工具栏一片空白。

状态栏三格：

```cpp
// ═══ 2.7 分区状态栏 ═══
CreateStatusBar(3);
SetStatusText(wxString::FromUTF8("就绪"), 0);
SetStatusText(wxString::FromUTF8("第 2 格"), 1);
SetStatusText("column 3", 2);
```

`CreateStatusBar(3)` 一次建三格，`SetStatusText(文本, 格号)` 各自更新。第 0 格按惯例放"就绪/提示"，后两格放上下文信息——很多编辑器在 1/2 格常驻显示行列号与编码。

## 2.5 UPDATE_UI：不点击也在跑的 UI 状态

"保存"什么时候该灰掉？若在每个改 `m_modified` 的地方手动 Enable/Disable 菜单项和工具栏按钮，状态同步会散落成灾。wx 的解法是 `wxEVT_UPDATE_UI`：

```cpp
// ═══ 2.8 UPDATE_UI 处理器：UI 状态的唯一权威来源 ═══
void MyFrame::OnUpdateSave(wxUpdateUIEvent& e)
{
    e.Enable(m_modified);        // 未修改时"保存"灰掉
    e.SetText(m_modified ? "&Save\tCtrl-S" : "&Save (nothing)");
}
```

处理器在**每次空闲拍**被框架调用（不点任何东西也在跑），集中读 `m_modified` 设置 UI——`Enable` 控灰、`SetText` 连标签一起换。注意它挂在 `Menu_File_Save` 一个 ID 上：菜单项与工具栏按钮同 ID，两边同时生效。这是保留模式框架的典型设计——状态变更与 UI 反馈解耦，你只声明"此刻该长什么样"，框架负责刷到每个入口。

## 2.6 右键菜单：PopupMenu

```cpp
// ═══ 2.9 栈上构造弹出菜单，模态等待 ═══
void MyFrame::OnRightUp(wxMouseEvent& event)
{
    wxMenu menu;
    menu.Append(Menu_File_New, "Popup: New");
    menu.Append(Menu_File_Open, "Popup: Open");
    menu.AppendSeparator();
    menu.Append(wxID_EXIT, "Popup: Exit");
    PopupMenu(&menu, event.GetPosition());
}
```

右键菜单就是普通 `wxMenu`：栈上构造、Append 复用命令号、`PopupMenu(&menu, 坐标)` 以窗口客户区坐标模态弹出——函数返回时菜单已关闭、选中项的 `wxEVT_MENU` 已派发，处理器一个字不用改。接线绑 `wxEVT_RIGHT_UP`：按下-抬起完整手势之后再弹，与桌面惯例一致；`event.GetPosition()` 给的正是客户区坐标，直接喂 `PopupMenu` 不用换算。

## 2.7 运行与输出

selftest 不点菜单也能验证一切：700ms 定时器到点后，处理器里程序化读结构计数、手工构造 `wxUpdateUIEvent` 直接喂给 UPDATE_UI 处理器、读回 radio 勾选态：

```cpp
// ═══ 2.10 selftest：结构计数 + UPDATE_UI 行为 + radio 状态 ═══
wxMenuBar* bar = GetMenuBar();
int menus = bar->GetMenuCount();
int fileItems = bar->GetMenu(0)->GetMenuItemCount();
Log("menubar menus=%d, file items=%d\n", menus, fileItems);

m_modified = true;
wxUpdateUIEvent e(Menu_File_Save);   // 直接喂一个 UPDATE_UI 事件
OnUpdateSave(e);
Log("UPDATE_UI with modified=true: enabled=%d\n", (int)e.GetEnabled());
m_modified = false;
wxUpdateUIEvent e2(Menu_File_Save);
OnUpdateSave(e2);
Log("UPDATE_UI with modified=false: enabled=%d\n", (int)e2.GetEnabled());
...
Log("toolbar tools=%d, status fields=%d\n",
    (int)GetToolBar()->GetToolsCount(), (int)GetStatusBar()->GetFieldsCount());
Close(true);
```

selftest 实测输出（sidecar 文件 `build/docs-ref/02_wx_menus.sidecar` 摘录一次运行，三次连跑逐字节一致）：

```text
==== 02 wx 菜单与工具栏 开始 ====
menubar menus=3, file items=9
UPDATE_UI with modified=true: enabled=1
UPDATE_UI with modified=false: enabled=0
radio mode2 checked=1, mode1 checked=0
toolbar tools=5, status fields=3
==== 02 wx 菜单与工具栏 结束 ====
```

逐行对应：`menus=3` 是 File/View/Help；`file items=9` = 5 个命令项 + 3 条分隔线 + 1 个子菜单（`GetMenuItemCount` 连分隔线一起数）；两行 `enabled=1/0` 正是手工喂事件后 `m_modified` 翻转前后的 Enable 结果——UPDATE_UI 逻辑被直接验证；`radio mode2 checked=1, mode1 checked=0` 说明构造期 `Check` 生效且互斥成立；`toolbar tools=5` = 4 按钮 + 1 分隔线，`status fields=3` 对应三格状态栏。

## 坑位清单

- **自定义命令号避开标准 ID**：枚举从 100 起号（源码注释明示），与 `wxID_EXIT`/`wxID_ABOUT` 撞号会让平台标准行为与你自己的处理器抢事件。故意挂靠标准 ID（如 About）是选择，不是事故。
- **AddTool 之后必须 Realize**：`wxToolBar` 是攒批 API，加完不调 `Realize()` 布局不落地，窗口里工具栏空白——源码注释"添加完必须 Realize"即此。
- **radio 组靠"连续 Append"成组**：`AppendRadioItem` 的互斥范围是同菜单内连续的 radio 项；中间插进一个普通项就把组切开，变成各自互斥的两组——排布菜单时留心。
- **中文一律 FromUTF8**：MSVC 下窄字面量按本地编码（GBK）解释，`SetStatusText("中文")` 直接乱码——本批实测坑位（04 章还有同款现场），本章所有中文串都走 `wxString::FromUTF8`。
- **UPDATE_UI 是空闲拍高频回调**：每拍都走，处理器里只读状态、设 Enable/Check/Text，别做重活或再触发刷新。
- **PopupMenu 坐标是客户区坐标**：鼠标事件的 `GetPosition()` 与 `PopupMenu` 恰好同坐标系，直接传即可；换成屏幕坐标来源（如另一窗口的位置）必须先换算。

---

上一章：[01 · wxWidgets 最小应用：保留模式与事件循环](01-wx-hello.md) ｜ 下一章：[03 · Sizer 布局：盒子、网格与弹性](03-wx-sizers.md) ｜ 返回：[README](../README.md)
