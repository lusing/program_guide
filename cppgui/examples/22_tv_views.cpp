// ============================================================
// 22_tv_views.cpp —— TWindow 窗口体系：滚动视图 / 自绘视图 / 桌面管理
//
// 要点：
//   * TWindow 派生两件套：TWindowInit(&X::initFrame) 虚基类在前，
//     TWindow(bounds, title, number) 在后（number>0 显示窗口序号）
//   * TScroller 滚动视图：delta=当前滚偏移，limit=内容总量；
//     draw() 里自己按 delta 取行；setState(sfExposed) 时 setLimit
//     （fileview.cpp 同款时序）；scrollTo 越界自动夹取
//   * TView::draw 覆写两条路：writeChar/writeStr 按调色板索引直写
//     （color 参数=调色板下标，经 mapColor 查表）；
//     TDrawBuffer 组装整行后 writeBuf/writeLine（ascii.cpp 同款）
//   * 窗口管理：insertWindow 接入桌面；growMode 决定随桌面伸缩；
//     标准命令 cmNext/cmTile(cmCascade 由 TApplication 接)、
//     cmZoom(F5)/cmClose(Alt-F3)/cmResize(Ctrl-F5) 由 TWindow 自接
//   * selftest：数桌面窗口、焦点窗口标题、scrollTo 夹取、zoom 尺寸
// 官方参考：tvdemo/fileview.cpp（TScroller）、tvdemo/ascii.cpp（draw 直写）、
//           tvdemo/tvdemo3.cpp（Window 菜单 cmTile/cmCascade）
// ============================================================
#define Uses_TKeys
#define Uses_TApplication
#define Uses_TProgram
#define Uses_TDeskTop
#define Uses_TEvent
#define Uses_TRect
#define Uses_TView
#define Uses_TWindow
#define Uses_TFrame
#define Uses_TScroller
#define Uses_TScrollBar
#define Uses_TBackground
#define Uses_TDrawBuffer
#define Uses_TMenuBar
#define Uses_TSubMenu
#define Uses_TMenuItem
#define Uses_TStatusLine
#define Uses_TStatusItem
#define Uses_TStatusDef
#include <tvision/tv.h>

#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

const int cmOpenReader = 100;   // 自定义命令从 100 起

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-22_tv_views.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// ---------- 滚动文本视图：TScroller 派生（fileview.cpp 骨架）----------
class TReaderView : public TScroller
{
public:
    TReaderView(const TRect& bounds, std::vector<std::string> lines,
                TScrollBar* hsb, TScrollBar* vsb)
        : TScroller(bounds, hsb, vsb), m_lines(std::move(lines))
    {
        growMode = gfGrowHiX | gfGrowHiY;
        // 内容总量：x 取最长行宽（strwidth 按显示宽度计，CJK 算 2），
        // y 取行数——滚动条范围即由此而来
        limit.x = 0;
        for (const auto& s : m_lines)
            limit.x = max(limit.x, strwidth(s));
        limit.y = (int)m_lines.size();
    }

    TPoint contentLimit() const { return limit; }   // limit 是 protected，开个口给 selftest

    void draw() override
    {
        TColorAttr c = getColor(1);                 // 调色板 1 号 = 普通文本
        for (short i = 0; i < size.y; ++i)
        {
            TDrawBuffer b;
            b.moveChar(0, ' ', c, ushort(size.x));  // 先铺空格（清行）
            size_t idx = size_t(delta.y) + i;
            if (idx < m_lines.size())
                b.moveStr(0, m_lines[idx], c, ushort(size.x), ushort(delta.x));
            writeBuf(0, i, size.x, 1, b);           // 逐行写进视图
        }
    }

    void scrollDraw() override { TScroller::scrollDraw(); draw(); }

    void setState(ushort aState, Boolean enable) override
    {
        TScroller::setState(aState, enable);
        if (enable && (aState & sfExposed))
            setLimit(limit.x, limit.y);             // 暴露时才把总量告知滚动条
    }

private:
    std::vector<std::string> m_lines;
};

// ---------- 自绘视图：TView 派生，writeChar/writeStr 直写 ----------
// （writeChar/writeStr 的 color 参数是【调色板下标】，经虚函数
//   mapColor 查本视图调色板换算成真实颜色——不是 BIOS 色号）
class TBannerView : public TView
{
public:
    TBannerView(const TRect& bounds, std::string title)
        : TView(bounds), m_title(std::move(title)), m_blinks(0)
    {
        growMode = gfGrowHiX | gfGrowHiY;
        eventMask |= evKeyboard | evBroadcast;      // 默认只吃鼠标，键盘要显式开
    }

    void draw() override
    {
        for (short y = 0; y < size.y; ++y)          // 1 号色铺空格清屏
            writeChar(0, y, ' ', 1, size.x);
        writeStr(1, 0, m_title.c_str(), 3);         // 标题：3 号色
        writeChar(0, 1, '-', 2, size.x);            // 分隔线：2 号色连写
        const char* rows[] = {
            "writeChar/writeStr: 按调色板下标直写",
            "TDrawBuffer+writeBuf: 组装整行再写",
            "两条路最终都汇到 writeView 裁剪",
        };
        for (int i = 0; i < 3 && 2 + i < size.y; ++i)
            writeStr(2, short(2 + i), rows[i], 1);
        char badge[40];
        std::snprintf(badge, sizeof badge, "重绘 #%d", m_blinks);
        if (size.y > 2)
            writeStr(short(size.x - 12), short(size.y - 1), badge, 4);
    }

    void handleEvent(TEvent& event) override
    {
        TView::handleEvent(event);
        if (event.what == evBroadcast && event.message.command == cmTimerExpired)
        {
            ++m_blinks;                 // 收到定时广播就重绘一次（drawView 会裁剪不可见区）
            drawView();
            // 【坑】广播不许 clearEvent：那会终止传播，应用层就收不到
            // cmTimerExpired、selftest 退出信号被吃——实测挂死 60s。
        }
    }

private:
    std::string m_title;
    int m_blinks;
};

// ---------- 窗口两件套 ----------
class TReaderWindow : public TWindow
{
public:
    TReaderView* m_reader;

    TReaderWindow(const TRect& r, const char* title, short num,
                  std::vector<std::string> lines)
        : TWindowInit(&TReaderWindow::initFrame)    // 虚基类必须列在前面
        , TWindow(r, title, num)
        , m_reader(nullptr)
    {
        options |= ofTileable;                      // 参与 cmTile 平铺
        growMode = gfGrowHiX | gfGrowHiY;           // 随桌面右下角伸缩
        TRect inner = getExtent();
        inner.grow(-1, -1);                         // 让出边框
        m_reader = new TReaderView(inner, std::move(lines),
            standardScrollBar(sbHorizontal | sbHandleKeyboard),
            standardScrollBar(sbVertical | sbHandleKeyboard));
        insert(m_reader);
    }
};

class TBannerWindow : public TWindow
{
public:
    TBannerWindow(const TRect& r)
        : TWindowInit(&TBannerWindow::initFrame)
        , TWindow(r, "自绘视图", wnNoNumber)
    {
        growMode = gfGrowHiX | gfGrowHiY;
        TRect inner = getExtent();
        inner.grow(-1, -1);
        TBannerView* v = new TBannerView(inner, "== 直绘横幅 ==");
        insert(v);
    }
};

// ---------- 应用 ----------
static std::vector<std::string> makeReaderText();   // 定义在文件尾（内置读物）

class TViewsApp : public TApplication
{
public:
    TViewsApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);

    TReaderView* m_reader = nullptr;    // 第一个读窗口的视图（selftest 滚动用）
    TWindow* m_bannerWin = nullptr;

private:
    TReaderWindow* openReader(int slot);
};

TViewsApp::TViewsApp()
    : TProgInit(&TViewsApp::initStatusLine,
                &TViewsApp::initMenuBar,
                &TViewsApp::initDeskTop)
{
    // 三个窗口手工级联摆位（交互态用 Alt-F3/F5/Ctrl-F5 亲手玩）
    TReaderWindow* w1 = openReader(0);
    openReader(2);
    TRect r = TProgram::deskTop->getExtent();
    r = TRect(r.b.x - 30, r.a.y + 1, r.b.x - 2, r.a.y + 9);
    m_bannerWin = insertWindow(new TBannerWindow(r));
    if (w1) m_reader = w1->m_reader;

    if (g_selftest) setTimer(600, -1);  // 一次性定时器 → cmTimerExpired
}

TReaderWindow* TViewsApp::openReader(int slot)
{
    TRect r = TProgram::deskTop->getExtent();
    r.grow(-14, -6);
    r.move(short(2 * slot), short(slot));   // 级联偏移：右下错开
    return static_cast<TReaderWindow*>(
        insertWindow(new TReaderWindow(r, "滚动读窗", short(slot + 1),
                                       makeReaderText())));
}

void TViewsApp::handleEvent(TEvent& event)
{
    TApplication::handleEvent(event);   // 基类接：菜单/cmNext/cmTile/cmCascade...
    if (event.what == evCommand)
    {
        switch (event.message.command)
        {
        case cmOpenReader:
            openReader(4);
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
            // 1) 数桌面窗口：deskTop 的直接子视图 = 背景视图 + 各窗口
            //    （窗口的 frame 是窗口自己的子视图，不在这层）
            int n = 0;
            for (TView* v = TProgram::deskTop->first(); v; v = v->nextView())
                if (v != TProgram::deskTop->background) ++n;
            Log("桌面窗口数=%d（背景视图另算，不占窗口数）\n", n);

            // 2) 焦点窗口：deskTop->current 是被选中的直接子视图（即活动窗口）
            TWindow* cur = (TWindow*)TProgram::deskTop->current;
            Log("焦点窗口标题='%s'\n", cur && cur->title ? cur->title : "(无)");

            // 3) scrollTo 越界自动夹取：900 远超内容量，应落在末页
            if (m_reader)
            {
                m_reader->scrollTo(8, 10);
                Log("scrollTo(8,10) → delta=(%d,%d)\n",
                    m_reader->delta.x, m_reader->delta.y);
                m_reader->scrollTo(900, 900);
                TPoint lim = m_reader->contentLimit();
                Log("scrollTo(900,900) → delta=(%d,%d)（内容 limit=(%d,%d)）\n",
                    m_reader->delta.x, m_reader->delta.y, lim.x, lim.y);
            }

            // 4) zoom()：程序化调用安全（sizeLimits→locate 重摆），尺寸应变为桌面大小
            if (m_bannerWin)
            {
                TPoint before = m_bannerWin->size;
                m_bannerWin->zoom();
                Log("banner zoom：%dx%d → %dx%d（F5 同款路径）\n",
                    before.x, before.y, m_bannerWin->size.x, m_bannerWin->size.y);
            }

            message(this, evCommand, cmQuit, 0);
            clearEvent(event);
        }
    }
}

TMenuBar* TViewsApp::initMenuBar(TRect r)
{
    r.b.y = r.a.y + 1;
    TSubMenu& fileMenu =
        *new TSubMenu("~F~ile", kbAltF) +
          *new TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X");

    TSubMenu& viewMenu =
        *new TSubMenu("~V~iews", kbAltV) +
          *new TMenuItem("~O~pen reader", cmOpenReader, kbNoKey);

    // 标准窗口命令：cmNext 由 TGroup 接；cmTile/cmCascade 由 TApplication 接
    TSubMenu& winMenu =
        *new TSubMenu("~W~indow", kbAltW) +
          *new TMenuItem("~N~ext", cmNext, kbF6, hcNoContext, "F6") +
          *new TMenuItem("~T~ile", cmTile, kbNoKey) +
          *new TMenuItem("Cas~c~ade", cmCascade, kbNoKey);

    return new TMenuBar(r, fileMenu + viewMenu + winMenu);
}

TStatusLine* TViewsApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem("~F6~ Next", kbF6, cmNext) +
            *new TStatusItem("~F5~ Zoom", kbF5, cmZoom) +
            *new TStatusItem(0, kbF10, cmMenu));
}

// ---------- 内置读物（一段长行用于水平滚动演示）----------
static const char* kReaderLines[] = {
    "L01 TWindow 是 tvision 的窗格容器：边框(TFrame)+标题+序号，",
    "L02 内容区再 insert 子视图。窗口本身不画正文。",
    "L03",
    "L04 TScroller 解决『内容大于视图』：delta 是左上角滚偏移，",
    "L05 limit 是内容总量（列数 x 行数）。滚动条挪动 → scrollTo",
    "L06 → delta 变 → scrollDraw → draw 按 delta 重取可见行。",
    "L07",
    "L08 窗口布局三件交互（正文详述，亲手试）：",
    "L09   拖标题栏移动；拖右下角缩放（growMode 决定跟随桌面）；",
    "L10   F5 zoom 整屏切换；Alt-F3 关窗；Ctrl-F5 resize 模式。",
    "L11",
    "L12 桌面命令：F6/cmNext 轮换焦点；cmTile 平铺 cmCascade 级联",
    "L13 ——后者由 TApplication::handleEvent 统一接管。",
    "L14",
    "L15 自绘视图两条正路：writeChar/writeStr 按调色板下标直写；",
    "L16 或 TDrawBuffer 组整行后 writeBuf/writeLine。都过 writeView",
    "L17 裁剪，写越界不炸、静默裁掉。",
    "L18",
    "L19 这一行特别长——演示水平滚动：滚到底能看到句号。>>>>>>>",
    ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>（水平滚动演示行长行）",
    "L20",
    "L21 行末即读物的末尾：滚动到 delta=(limit-size) 处即为末页。",
};

static std::vector<std::string> makeReaderText()
{
    return std::vector<std::string>(std::begin(kReaderLines), std::end(kReaderLines));
}

int main(int argc, char** argv)
{
    g_selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (g_selftest)
        if (FILE* f = std::fopen("selftest-22_tv_views.txt", "w"))
            std::fprintf(f, "==== 22 tvision 视图与窗口 开始 ====\n"), std::fclose(f);

    TViewsApp app;
    app.run();

    if (g_selftest)
        Log("==== 22 tvision 视图与窗口 结束 ====\n");
    return 0;
}
