# 01 · wxWidgets 最小应用：保留模式与事件循环

> 对应示例：[examples/01_wx_hello.cpp](../examples/01_wx_hello.cpp)

## 1.1 本教程的四框架地图——从范式说起

本教程带你用四种 C++ GUI/TUI 框架各写一组能跑的程序，它们代表四种不同的 UI 编程范式。第一章先把地图摊开，后面每章开头都会回指这里：

| 部分 | 框架 | 范式 | 一句话画像 |
|---|---|---|---|
| 一（01–07） | wxWidgets | 保留模式（retained mode） | 常驻控件树 + 事件回调，经典桌面应用形态 |
| 二（08–13） | Dear ImGui | 即时模式（immediate mode） | 每帧重跑的 UI 代码，工具/调试面板之王 |
| 三（14–19） | FTXUI | 声明式组件树 | 不可变元素每帧重建 + diff，TUI 里的 React |
| 四（20–24） | tvision | 经典桌面隐喻（TUI） | 1990 年 Borland IDE 的复刻：菜单/桌面/状态栏 + 事件循环 |

**保留模式**（本章主角）：程序先构建一棵**控件对象树**——Frame 里挂菜单栏、状态栏、子控件——这些对象常驻内存、自带状态（位置、文本、选中态）。你的代码只做两件事：**建树**和**注册事件处理器**；事件（鼠标、键盘、定时器）到来时框架回调你的处理器去改状态，重绘由库负责。控件是"对话者"，不是每帧重跑的代码。

与之对照的**即时模式**（08 章展开）：没有常驻控件树，UI 是主循环里每帧重新执行的代码——`if (Button("点我")) counter++` 这一行同时完成"画按钮 + 检测点击"。状态在你手里，不在库里。

## 1.2 三件套：wxIMPLEMENT_APP / OnInit / 消息循环

```cpp
// ═══ 1.1 应用类与入口宏 ═══
class MyApp : public wxApp
{
public:
    virtual bool OnInit() override;
    virtual int  OnExit() override;   // 消息循环结束后、对象清理前调用
    ...
};

wxIMPLEMENT_APP(MyApp);   // 宏 = 真正的 main：创建 MyApp、初始化 wx、跑消息循环
```

每个 wx 程序一个应用类，`wxIMPLEMENT_APP` 生成平台相关的入口（Windows 上是 `WinMain`，所以 CMake 里 wx 示例都链接成 WIN32 子系统）。你只写 `OnInit()`——建主窗口、`Show(true)`、返回 true；返回 true 后框架进入 `OnRun()` 的消息循环（不需要自己写 while）。窗口全部关闭后循环退出，`OnExit()` 收尾。

## 1.3 窗口骨架：Frame + 菜单 + 状态栏

```cpp
// ═══ 1.2 主窗口构造：菜单栏与状态栏 ═══
MyFrame::MyFrame(const wxString& title, bool selftest)
    : wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, wxSize(640, 400))
    , m_selftestTimer(this)   // 定时器属主=本 frame → 事件回投给 frame
{
    wxMenu* fileMenu = new wxMenu;
    fileMenu->Append(Minimal_Quit, "E&xit\tAlt-X", "Quit this program");
    ...
    wxMenuBar* menuBar = new wxMenuBar();
    menuBar->Append(fileMenu, "&File");
    SetMenuBar(menuBar);

    CreateStatusBar(2);       // 两格状态栏
    SetStatusText(wxString::FromUTF8("欢迎使用 wxWidgets（保留模式）"), 0);
}
```

三个惯例：菜单助记符用 `&`（`"E&xit"` 里 x 带下划线），加速键写在标签尾部 `"\tAlt-X"`；`wxID_EXIT`/`wxID_ABOUT` 用标准 ID（macOS 上 About/Quit 会被特殊安置到系统菜单）；`frame->Show(true)` 必须显式调用——frame 建出来默认不可见。

中文字面量一律 `wxString::FromUTF8("...")`：MSVC 源码是 UTF-8 但执行字符集默认不是，直接构造 `wxString` 会按本地编码解释出乱码（坑位清单第 3 条）。

## 1.4 事件表：编译期接线

```cpp
// ═══ 1.3 静态事件表：把事件路由到成员函数 ═══
wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    EVT_MENU(Minimal_Quit,  MyFrame::OnQuit)
    EVT_MENU(Minimal_About, MyFrame::OnAbout)
    EVT_TIMER(wxID_ANY,     MyFrame::OnSelftestTimer)
wxEND_EVENT_TABLE()
```

事件表是 wx 的经典接线方式：在类里 `wxDECLARE_EVENT_TABLE()` 声明、类外用宏表把"事件类型 + ID"映射到成员函数，编译期展开成静态查找表。02 章起我们会混用运行期 `Bind()`——两者等价，Bind 更灵活（能接 lambda、跨对象），事件表更"声明式"。处理器签名是普通成员函数，不写 virtual。

## 1.5 命令行钩子与 --selftest

本教程所有示例都支持 `--selftest`：初始化后运行数百毫秒自动退出，供 `build.ps1` 自动验证。wx 的正道是重写两个命令行钩子：

```cpp
// ═══ 1.4 注册自定义开关 ═══
void MyApp::OnInitCmdLine(wxCmdLineParser& parser)
{
    wxApp::OnInitCmdLine(parser);   // 先保留标准选项（--help 等）
    parser.AddSwitch(wxEmptyString, "selftest", "...");
}
bool MyApp::OnCmdLineParsed(wxCmdLineParser& parser)
{
    m_selftest = parser.Found("selftest");
    return wxApp::OnCmdLineParsed(parser);
}
```

自动退出的实现：frame 里挂一个 `wxTimer`，`StartOnce(600)` 后 `EVT_TIMER` 触发 `Close(true)`——走的是**用户关窗的同一条路径**，事件循环自然退出（而不是 `exit()` 横刀截断）。GUI 子系统没有 stdout 管道，selftest 的运行证据写进 sidecar 文件（见下节输出块）。

## 1.6 构建与运行

```bash
# 本教程验证入口（首次自动预构建 wxWidgets 3.3.4 静态库，10–20 分钟）
cd cppgui
pwsh build.ps1 -Example 01_wx_hello    # 构建 + selftest 单例
pwsh build.ps1 -All                    # 全部示例
```

selftest 实测输出（sidecar 文件 `build/selftest-01_wx_hello.txt`）：

```text
==== 01 wx 最小应用 开始 ====
selftest：菜单/状态栏/主循环均已运行，定时器触发自动退出
主窗口已关闭，事件循环正常退出
==== 01 wx 最小应用 结束 ====
```

四行覆盖了完整生命周期：OnInit 建窗 → 600ms 定时器到点 → Close 走正常关窗 → OnExit 收尾。`build.ps1` 的判定标准即：退出码 0 + sidecar 含起止标记 + stderr 为空 + 连跑两次逐字节一致。

## 坑位清单

- **基类 OnInit 会吞掉未注册参数**：`wxApp::OnInit()` 用 `wxCmdLineParser` 解析命令行，任何未注册参数都让解析报错 → OnInit 返回 false → 程序以 **255** 退出。想让程序接受自己的参数，必须重写 `OnInitCmdLine`/`OnCmdLineParsed` 两个钩子，别的绕法（偷偷扫 argv）会跟基类解析打架。
- **AddSwitch 参数顺序坑**：第一个参数是**短名**（须单字符），第二个才是长名。写成 `AddSwitch("selftest", ...)` 时它被当成短名注册，`--selftest` 依旧解析报错——正确写法 `AddSwitch(wxEmptyString, "selftest", ...)`。
- **中文乱码**：MSVC 下执行字符集默认跟随系统，`wxString("中文")` 直接按本地编码解释。中文字面量一律 `wxString::FromUTF8(...)`；源文件本身保持 UTF-8。
- **wxTimer 必须有属主或得自己 Bind**：构造 `wxTimer(this)` 把事件回投给属主 frame，配合事件表正好接住；没有属主的定时器得手动 `Bind`。
- **退出码语义**：`Close(true)` 的 true 表示绕过关闭询问强制关——selftest 想要"无人值守"就该用它；默认 `Close()` 会触发 `wxEVT_QUERY_CLOSE` 询问链。

---

上一章：[README · C++ GUI 编程指南](../README.md) ｜ 下一章：[02 · 菜单、工具栏与命令](02-wx-menus.md) ｜ 返回：[README](../README.md)
