# 20 · tvision 应用骨架：桌面隐喻与事件循环

> 对应示例：[examples/20_tv_hello.cpp](../examples/20_tv_hello.cpp)

## 20.1 本部分范式导读：桌面隐喻与全书收束

tvision 是 Borland Turbo Vision 的现代 C++ 移植——1990 年前后 Turbo Pascal / Borland C++ 那套 DOS IDE 界面的框架原作，也是"桌面隐喻"在字符终端上的标准答案。它把一个应用定义为三块固定的屏幕不动产：

- **菜单栏**（第 1 行）：`Alt+字母` 拉下拉菜单，菜单项直接发命令；
- **桌面 DeskTop**（中间整块）：窗口、对话框、自绘视图全部住在上面；
- **状态栏**（最后 1 行）：快捷键提示条，F10 呼出菜单。

一切交互皆**事件**：键盘 `evKeyDown`、鼠标 `evMouse`、命令 `evCommand + cmXXX 常量`、广播 `evBroadcast`。`run()` 就是事件循环——`getEvent → handleEvent → ...` 循环往复，直到谁发出 `cmQuit`。

放到全书地图上收束：

| 框架 | 范式 | 接线方式 |
|---|---|---|
| wxWidgets | 保留模式 | 静态事件表（宏表展开成查找表）/ Bind |
| tvision | 保留模式 | handleEvent 虚函数链 + 手工 switch |
| Dear ImGui | 即时模式 | 每帧重跑的调用顺序即布局即路由 |
| FTXUI | 声明式 | 组件树每帧重建 + diff |

tvision 与 wx 同属**保留模式**——常驻视图树 + 事件回调，控件是对话者而非每帧重跑的代码；差别只在接线：wx 把路由表交给编译期宏，tvision 让你在 `handleEvent` 里自己 switch。imgui 是另一极（状态在你手里），FTXUI 居中（重建 + diff）。四种范式至此闭环，而 tvision 是"最老也最完整"的那一个——菜单、对话框、窗口管理、编辑器、调色板一应俱全，本部分五章就把这套家底逐层拆开。

## 20.2 Uses_* 宏：头文件的预编译裁剪

```cpp
// ═══ 20.2 tv.h 按 Uses_* 宏选择性展开类声明 ═══
#define Uses_TKeys          // kbXXX 键码常量
#define Uses_TApplication   // TApplication / TProgInit
#define Uses_TEvent         // TEvent
#define Uses_TRect          // TRect
#define Uses_TDialog        // 对话框 + 四件套控件
#define Uses_TStaticText
#define Uses_TButton
#define Uses_TMenuBar       // 菜单三件套
#define Uses_TSubMenu
#define Uses_TMenuItem
#define Uses_TStatusLine    // 状态栏三件套
#define Uses_TStatusItem
#define Uses_TStatusDef
#define Uses_TDeskTop
#include <tvision/tv.h>
```

tv.h 面向全量类声明，直接 include 会把上百个类都拉进编译单元；tvision 的老派解法是按 `#define Uses_TXXX` **选择性展开**——定义了哪些宏，tv.h 就只暴露哪些类。这是预处理时代的"前置声明裁剪"：编译快，代价是漏定义一个宏，对应类就整个不存在，用到即报"未声明的标识符"。所以每个示例开头的宏列表就是本文件的依赖购物清单，新加控件要同步补宏。

## 20.3 应用类与 TProgInit 三 init 函数

```cpp
// ═══ 20.3 TProgInit：三块屏幕不动产经静态函数指针注入 ═══
class THelloApp : public TApplication
{
public:
    THelloApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);
    static TDeskTop* initDeskTop(TRect r) { return new TDeskTop(r); }
};

THelloApp::THelloApp()
    : TProgInit(&THelloApp::initStatusLine,
                &THelloApp::initMenuBar,
                &THelloApp::initDeskTop)
{
    if (g_selftest)
        setTimer(600, -1);   // periodMs=-1：一次性
}
```

TApplication 不直接收菜单栏对象，而是经基类 TProgInit 收三个**静态函数指针**——initStatusLine / initMenuBar / initDeskTop——在应用构造早期回调它们，把三块不动产建出来。为什么是函数指针而不是虚函数？因为调用发生在基类构造期间，虚分派还到不了派生类；Turbo Vision 用"传静态函数指针"这一招让派生类在基类构造期就能注入自定义实现。本例桌面用缺省实现，后两章只覆写菜单与状态栏。

## 20.4 handleEvent：switch 就是事件表

```cpp
// ═══ 20.4 先基类后 switch，处理完 clearEvent ═══
void THelloApp::handleEvent(TEvent& event)
{
    TApplication::handleEvent(event);   // 先让基类处理（菜单/状态栏/快捷键）
    if (event.what == evCommand)
    {
        switch (event.message.command)
        {
        case GreetThemCmd:
            greetingBox();
            clearEvent(event);          // 已处理：吃掉事件防继续传播
            break;
        ...
        }
    }
    else if (event.what == evBroadcast && event.message.command == cmTimerExpired)
    {
        if (g_selftest)
        {
            Log("selftest：cmTimerExpired 到达，注入 cmQuit");
            message(this, evCommand, cmQuit, 0);   // 结束 run() 的模态循环
            clearEvent(event);
        }
    }
}
```

对照 wx 的 `EVT_MENU` 宏表：tvision 把"事件 → 处理器"的映射摊开成 switch 语句，一目了然但要自己维护 default。两个纪律：**先调基类**（菜单热键、标准命令由 TApplication 接走），**处理完 clearEvent**（吃掉事件，防止继续传播被二次处理）。模态对话框 `greetingBox()` 里是 `deskTop->execView(d)`——嵌套事件循环，跑到按钮点击才返回（21 章细说）。

## 20.5 菜单栏与状态栏：~X~ 热键与 kbXXX 加速键

```cpp
// ═══ 20.5 菜单树与状态栏条目 ═══
TMenuBar* THelloApp::initMenuBar(TRect r)
{
    r.b.y = r.a.y + 1;      // 菜单栏占屏幕第 1 行
    return new TMenuBar(r,
        *new TSubMenu("~H~ello", kbAltH) +
            *new TMenuItem("~G~reeting...", GreetThemCmd, kbAltG) +
            newLine() +
            *new TMenuItem("E~x~it", cmQuit, cmQuit, hcNoContext, "Alt-X"));
}

TStatusLine* THelloApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;      // 状态栏占屏幕最后 1 行
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem(0, kbF10, cmMenu));
}
```

文本里的 `~X~` 表示 X 是热键（`~H~ello` 里 H 高亮，Alt+H 拉开菜单）；`TSubMenu` 第二参 `kbAltH` 是拉菜单的加速键，`TMenuItem` 的 `kbAltG` 是不拉开菜单直接发命令的加速键；末参 `"Alt-X"` 是提示串，选中菜单项时显示在状态栏。状态栏一侧：`TStatusDef(0, 0xFFFF)` 定义帮助上下文区间（这里全域生效），`TStatusItem` 三件套 = 显示文本 + 键绑定 + 触发的命令；`TStatusItem(0, kbF10, cmMenu)` 文本为空、只绑定 F10 呼出菜单。菜单树用 `operator+` 把子菜单和菜单项串成链——21 章把它长成多菜单的大树。

## 20.6 selftest 通路：setTimer → cmTimerExpired → cmQuit

本教程所有示例都支持 `--selftest`：跑数百毫秒自动退出供 `build.ps1` 验证。tvision 的正道是 `setTimer(600, -1)`（600ms、periodMs=-1 一次性）。到期后 TProgram 的定时器队列**广播** `evBroadcast + cmTimerExpired`（见 source/tvision/tprogram.cpp:212），我们在 handleEvent 的广播分支里接住，再 `message(this, evCommand, cmQuit, 0)` 注入退出命令——走的是用户按 Alt-X 的**同一条退出路径**，run() 自然收尾，而不是 `exit()` 横刀截断。

注意关键字段：`event.what == evBroadcast`。cmTimerExpired 不走 evCommand，写进 evCommand 的 switch 里永远接不到（坑位清单第 3 条）。

## 20.7 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 20_tv_hello    # 构建 + selftest 单例
```

tvision 直写控制台（接管整个终端），没有可捕获的 stdout——selftest 的运行证据全部落在 sidecar 文件（`build/docs-ref/20_tv_hello.sidecar`）：

```text
==== 20 tvision 骨架 开始 ====
selftest：cmTimerExpired 到达，注入 cmQuit
==== 20 tvision 骨架 结束 ====
```

三行覆盖完整生命周期：构造（三 init 建好菜单栏/桌面/状态栏）→ 事件循环启动 → 600ms 定时器到期、tprogram.cpp:212 的广播被 handleEvent 接住并留下日志 → 注入 cmQuit → run() 干净退出写结束标记。`build.ps1` 的判定即：退出码 0 + sidecar 起止标记齐 + 两跑逐字节一致。

## 坑位清单

- **Uses_\* 宏必须写在 `#include <tvision/tv.h>` 之前**：tv.h 按这些宏选择性展开类声明，宏写在 include 之后等于没写——用到对应类直接报"未声明的标识符"。每个示例开头的宏列表就是依赖清单，加控件必须同步补宏。
- **自定义命令号从 100 起**：0–99 是框架保留号（cmQuit/cmOK/cmCancel/cmSave...），撞上保留号会被框架内置行为截胡——本例 `GreetThemCmd = 100` 即为此约定。
- **cmTimerExpired 是广播不是命令**：setTimer 到期发的是 `evBroadcast + cmTimerExpired`，写进 `evCommand` 的 switch 里永远接不到；必须另判 `event.what == evBroadcast` 分支（见 20.4 代码第二支）。
- **菜单栏/状态栏的 TRect 要自己剪成一行**：init 拿到的是应用全屏矩形，菜单栏必须 `r.b.y = r.a.y + 1`、状态栏对侧 `r.a.y = r.b.y - 1`——忘了剪，菜单栏会吃满整屏。
- **先调基类 handleEvent、处理完 clearEvent**：基类先吃菜单热键与标准命令，你的 switch 再补自定义命令；处理完 `clearEvent(event)` 防止事件继续传播被二次处理。两步少一步，事件就"漏"或"重"。
- **execView 是模态嵌套事件循环**：`greetingBox()` 里的 `deskTop->execView(d)` 要跑到按钮点击才返回——交互态没问题，无人值守（selftest）触发就是挂死。本例把 greetingBox 只接在菜单命令上、selftest 分支直接注入 cmQuit，正是绕开这条路（21 章正面解决"免模态取数"）。

---

上一章：[19 · FTXUI 综合实战：交互式待办管理器](19-ftxui-app.md) ｜ 下一章：[21 · 菜单树、命令分发与模态对话框](21-tv-menus-dialogs.md) ｜ 返回：[README](../README.md)
