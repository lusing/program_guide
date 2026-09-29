// ============================================================
// 20_tv_hello.cpp —— tvision 应用骨架：TApplication 与桌面隐喻
//
// 经典桌面隐喻范式导读：
//   tvision 复刻 Borland Turbo Vision（1990s DOS IDE 的 UI 框架）：
//   应用 = TApplication，屏幕划分为 菜单栏 / 桌面(DeskTop) / 状态栏
//   三块；一切交互都是【事件】：键鼠(evKeyDown/evMouse)、命令
//   (evCommand + cmXXX 常量)、广播(evBroadcast)。run() 跑事件循环，
//   handleEvent 里 switch 分发——比 wx 的静态事件表更"手工"，但
//   模型同源（保留模式 + 事件驱动）。
// Uses_* 宏机制：tv.h 按 #define Uses_XXX 选择性展开类声明，
//   控制编译依赖（头文件巨大时的老派"预编译裁剪"）。
// 官方参考：tvision/examples/../hello.cpp（Borland 原版演示）
// ============================================================
#define Uses_TKeys
#define Uses_TApplication
#define Uses_TEvent
#define Uses_TRect
#define Uses_TDialog
#define Uses_TStaticText
#define Uses_TButton
#define Uses_TMenuBar
#define Uses_TSubMenu
#define Uses_TMenuItem
#define Uses_TStatusLine
#define Uses_TStatusItem
#define Uses_TStatusDef
#define Uses_TDeskTop
#include <tvision/tv.h>

#include <cstdio>
#include <cstring>

const int GreetThemCmd = 100;   // 自定义命令号从 100 起（cmUser 附近）

static bool g_selftest = false;
static void Log(const char* s)
{
    if (FILE* f = std::fopen("selftest-20_tv_hello.txt", "a"))
        std::fprintf(f, "%s\n", s), std::fclose(f);
}

class THelloApp : public TApplication
{
public:
    THelloApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);
    static TDeskTop* initDeskTop(TRect r) { return new TDeskTop(r); }

private:
    void greetingBox();
};

THelloApp::THelloApp()
    : TProgInit(&THelloApp::initStatusLine,
                &THelloApp::initMenuBar,
                &THelloApp::initDeskTop)
{
    // selftest：600ms 一次性定时器。到期后 TProgram 的定时器队列广播
    // evBroadcast + cmTimerExpired（见 source/tvision/tprogram.cpp:212），
    // 我们在 handleEvent 里接住并注入 cmQuit 优雅退出。
    if (g_selftest)
        setTimer(600, -1);   // periodMs=-1：一次性
}

void THelloApp::greetingBox()
{
    // 模态对话框：TRect 手工摆坐标（列,行）——经典 Turbo Vision 风格
    TDialog* d = new TDialog(TRect(25, 5, 55, 16), "Hello, World!");
    d->insert(new TStaticText(TRect(3, 5, 15, 6), "How are you?"));
    d->insert(new TButton(TRect(16, 2, 28, 4), "Terrific", cmCancel, bfNormal));
    d->insert(new TButton(TRect(16, 4, 28, 6), "Ok", cmCancel, bfNormal));
    d->insert(new TButton(TRect(16, 6, 28, 8), "Lousy", cmCancel, bfNormal));
    d->insert(new TButton(TRect(16, 8, 28, 10), "Cancel", cmCancel, bfNormal));
    deskTop->execView(d);    // execView = 模态执行
    destroy(d);
}

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
        default:
            break;
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

TMenuBar* THelloApp::initMenuBar(TRect r)
{
    r.b.y = r.a.y + 1;      // 菜单栏占屏幕第 1 行
    // ~X~ 表示 X 是热键；kbAltH/kbAltG 是加速键
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

int main(int argc, char** argv)
{
    g_selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (g_selftest)
    {
        if (FILE* f = std::fopen("selftest-20_tv_hello.txt", "w"))
            std::fprintf(f, "==== 20 tvision 骨架 开始 ====\n"), std::fclose(f);
    }

    THelloApp helloWorld;
    helloWorld.run();       // 事件循环：getEvent → handleEvent → ...

    if (g_selftest)
        Log("==== 20 tvision 骨架 结束 ====");
    return 0;
}
