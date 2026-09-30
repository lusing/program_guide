// ============================================================
// 21_tv_menus_dialogs.cpp —— 菜单树 / 命令分发 / 模态对话框
//
// 要点：
//   * initMenuBar：TSubMenu+TMenuItem 用 operator+ 串成链，~X~ 热键，
//     kbXXX 加速键；自定义命令号从 cmUser 起
//   * handleEvent：先调基类（菜单/状态栏已由框架接好），再 switch
//     自己的 evCommand；处理完 clearEvent 防继续传播
//   * TStatusLine：底栏快捷键提示（TStatusDef 帮助上下文段）
//   * 对话框：TDialog + TInputLine（1 行高的 TRect + ilMaxChars）+
//     TStaticText 标签 + TButton(~热键~, cmOK/cmCancel, bfDefault)
//   * deskTop->execView(d)：模态执行；valid() 可拦截校验
// 官方参考：tvdemo/tvdemo3.cpp（菜单树）、tvdemo/backgrnd.cpp（输入框）
// ============================================================
#define Uses_TKeys
#define Uses_TApplication
#define Uses_TEvent
#define Uses_TRect
#define Uses_TDialog
#define Uses_TInputLine
#define Uses_TStaticText
#define Uses_TLabel
#define Uses_TButton
#define Uses_TMenuBar
#define Uses_TSubMenu
#define Uses_TMenuItem
#define Uses_TStatusLine
#define Uses_TStatusItem
#define Uses_TStatusDef
#define Uses_TDeskTop
#define Uses_MsgBox
#include <tvision/tv.h>

#include <cstdarg>
#include <cstdio>
#include <cstring>

// 自定义命令：框架保留 0..99（cmQuit/cmOK/...），用户命令从 100 起
const int cmGreet = 100;
const int cmCount = 101;

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-21_tv_menus_dialogs.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// ---------- 输入对话框：TDialog + TInputLine + 按钮 ----------
class TGreetDialog : public TDialog
{
public:
    explicit TGreetDialog()
        : TWindowInit(&TGreetDialog::initFrame)   // 虚基类：必须先于 TDialog
        , TDialog(TRect(20, 6, 58, 14), "Greeting")
        , m_input(nullptr)
    {
        // 居中到桌面（框架不会自动居中）
        TRect r = getExtent();
        r.move((TProgram::deskTop->size.x - r.b.x) / 2,
               (TProgram::deskTop->size.y - r.b.y) / 2);
        changeBounds(r);

        // TInputLine：TRect 高度恒为 1；参数=缓冲容量 + ilMaxChars
        m_input = new TInputLine(TRect(3, 3, 33, 4), 32, 0, ilMaxChars);
        insert(m_input);
        insert(new TStaticText(TRect(3, 2, 33, 3), "Enter your name:"));
        insert(new TButton(TRect(4, 6, 16, 8), "~O~K", cmOK, bfDefault));
        insert(new TButton(TRect(18, 6, 30, 8), "~C~ancel", cmCancel, bfNormal));
        m_input->focus();
    }

    char m_buf[33] = { 0 };

    Boolean valid(ushort command) override
    {
        if (TDialog::valid(command) && command == cmOK && m_input)
            std::strncpy(m_buf, m_input->data, sizeof(m_buf) - 1);
        return True;
    }

    TInputLine* m_input;
};

// ---------- 应用 ----------
class TDemoApp : public TApplication
{
public:
    TDemoApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);

    int m_greetCount = 0;

private:
    void greeting();
};

TDemoApp::TDemoApp()
    : TProgInit(&TDemoApp::initStatusLine,
                &TDemoApp::initMenuBar,
                &TDemoApp::initDeskTop)
{
    if (g_selftest) setTimer(600, -1);   // 一次性 → cmTimerExpired 广播
}

void TDemoApp::greeting()
{
    ++m_greetCount;
    TGreetDialog* d = new TGreetDialog();
    if (deskTop->execView(d) != cmCancel && d->m_buf[0])
        Log("greet #%d: name='%s'（execView 模态返回 cmOK）\n", m_greetCount, d->m_buf);
    TObject::destroy(d);
}

void TDemoApp::handleEvent(TEvent& event)
{
    TApplication::handleEvent(event);       // 基类先吃：菜单热键/标准命令
    if (event.what == evCommand)
    {
        switch (event.message.command)
        {
        case cmGreet:
            greeting();
            clearEvent(event);
            break;
        case cmCount:
            Log("greet count=%d\n", m_greetCount);
            clearEvent(event);
            break;
        default:
            break;
        }
    }
    else if (event.what == evBroadcast && event.message.command == cmTimerExpired)
    {
        if (g_selftest)
        {
            // selftest：不进模态（execView 等输入会挂死），改构造+取值
            auto* d = new TGreetDialog();
            std::strncpy(d->m_input->data, "tvision", 32);   // 模拟输入
            // d->m_input->selectAll(true);  // 签名带参，此处省略
            d->valid(cmOK);                                   // 走校验取数路径
            Log("selftest dialog: data='%s'（不走 execView）\n", d->m_buf);
            TObject::destroy(d);
            message(this, evCommand, cmQuit, 0);
            clearEvent(event);
        }
    }
}

// 菜单树：operator+ 串接；子菜单嵌套用 TSubMenu& 提升
TMenuBar* TDemoApp::initMenuBar(TRect r)
{
    TSubMenu& fileMenu =
        *new TSubMenu("~F~ile", kbAltF) +
          *new TMenuItem("~G~reeting...", cmGreet, kbCtrlG, hcNoContext, "Ctrl-G") +
          *new TMenuItem("~C~ount (log)", cmCount, kbNoKey) +
           newLine() +
          *new TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X");

    TSubMenu& optMenu =
        *new TSubMenu("~O~ptions", kbAltO) +
          *new TMenuItem("~G~reet again", cmGreet, kbNoKey);

    r.b.y = r.a.y + 1;
    return new TMenuBar(r, fileMenu + optMenu);
}

TStatusLine* TDemoApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem("~Ctrl-G~ Greet", kbCtrlG, cmGreet) +
            *new TStatusItem(0, kbF10, cmMenu));
}

int main(int argc, char** argv)
{
    g_selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (g_selftest)
        if (FILE* f = std::fopen("selftest-21_tv_menus_dialogs.txt", "w"))
            std::fprintf(f, "==== 21 tvision 菜单与对话框 开始 ====\n"), std::fclose(f);

    TDemoApp app;
    app.run();

    if (g_selftest)
        Log("==== 21 tvision 菜单与对话框 结束 ====\n");
    return 0;
}
