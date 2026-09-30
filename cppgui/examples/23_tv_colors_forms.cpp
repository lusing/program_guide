// ============================================================
// 23_tv_colors_forms.cpp —— 调色板体系 / 表单校验 / 滑块拼图
//
// 三主题：
//   一、调色板：三级间接的"样式表"
//     * 视图调色板条目 = 【属主调色板的下标】，逐级上溯到
//       TApplication（无属主）才落地为真实 BIOS 色号；
//       TDeskTop 调色板为空 = 直通（mapcolor.cpp:20 的 else 分支）
//     * TDrawBuffer 系 moveXXX 吃【真实色号】——先 getColor(i)
//       走完上溯拿到色号再入缓冲；writeChar/writeStr 吃【索引】
//     * 窗口级扩展：getPalette() 覆写 = 蓝窗 8 项 + 追加若干项
//       （palette.cpp 的拼接技法）；追加项索引应用调色板
//       （cpAppColor 共 135 项，上限 0x87——越界返回 errorAttr
//       0xCF，本例第 5 色故意越界现场演示）
//   二、表单：TInputLine + TValidator（validate.h 现成校验器）
//     * TRangeValidator(1,120)：过滤非数字 + 越界拦截；
//       谓词 isValid() 纯函数可单测；valid(cmOK) 失败会弹
//       messageBox（模态）——selftest 只走谓词与合法路径
//     * 非空校验子类化 TInputLine::valid（tvforms/fields.cpp 技法）
//   三、拼图（tvdemo/puzzle.cpp 改编）：4×4 滑块，方向键/鼠标，
//     自带两色调色板覆写；selftest 走确定性步序（不打乱）
// 官方参考：examples/palette/（README.md 三级映射表）、
//           examples/tvforms/fields.cpp、tvdemo/puzzle.cpp
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
#define Uses_TPalette
#define Uses_TDrawBuffer
#define Uses_TDialog
#define Uses_TInputLine
#define Uses_TLabel
#define Uses_TButton
#define Uses_TMenuBar
#define Uses_TSubMenu
#define Uses_TMenuItem
#define Uses_TStatusLine
#define Uses_TStatusItem
#define Uses_TStatusDef
#define Uses_TFilterValidator
#define Uses_TRangeValidator
#define Uses_MsgBox
#include <tvision/tv.h>

#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>

// 自定义命令
const int cmShowSwatch  = 100;
const int cmShowPuzzle  = 101;
const int cmShowProfile = 102;
const int cmScramble    = 103;

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-23_tv_colors_forms.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// ============================================================
// 主题一：调色板演示视图（5 项自定义调色板）
// ============================================================
// 视图调色板：条目值 = 属主（窗口）调色板的下标。
//   1→窗口第 6 项、2→第 7 项（蓝窗内置 8 项之内）
//   3→第 9 项、4→第 10 项（本窗口 getPalette 追加的自定义项）
//   5→第 11 项（追加值 0x88 越过应用调色板上限 → errorAttr）
#define cpSwatchView "\x06\x07\x09\x0A\x0B"

class TSwatchView : public TView
{
public:
    explicit TSwatchView(const TRect& r) : TView(r)
    {
        growMode = gfGrowHiX | gfGrowHiY;
    }

    void draw() override
    {
        char line[80];
        for (int i = 1; i <= 5 && i <= size.y; ++i)
        {
            // getColor(i)：把索引走完 视图→窗口→(桌面直通)→应用 的
            // 上溯链，返回真实色号——TDrawBuffer 只认这种
            TColorAttr attr = TColorAttr(getColor(ushort(i)));
            std::snprintf(line, sizeof line, " 调色板 %d 号 → 0x%02X", i, (unsigned)attr);
            TDrawBuffer b;
            b.moveStr(0, line, attr, ushort(size.x));
            writeLine(0, short(i - 1), size.x, 1, b);
        }
    }

    TPalette& getPalette() const override
    {
        static TPalette palette(cpSwatchView, sizeof(cpSwatchView) - 1);
        return palette;
    }
};

// 窗口级扩展技法：蓝窗 8 项 + 追加 3 项（相邻字面量拼接，palette.cpp 同款）
#define cpSwatchWindow  "\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F"
#define cpSwatchExtra   "\x6F\x2A\x88"

class TSwatchWindow : public TWindow
{
public:
    TSwatchWindow()
        : TWindowInit(&TSwatchWindow::initFrame)
        , TWindow(TRect(3, 3, 43, 11), "调色板色卡", wnNoNumber)
    {
        TRect r = getExtent();
        r.grow(-1, -1);
        insert(new TSwatchView(r));
    }

    TPalette& getPalette() const override
    {
        static TPalette p(cpSwatchWindow cpSwatchExtra,
                          sizeof(cpSwatchWindow cpSwatchExtra) - 1);
        return p;
    }
};

// ============================================================
// 主题三：4×4 滑块拼图（tvdemo/puzzle.cpp 改编，确定性初始化）
// ============================================================
#define cpPuzzlePalette "\x06\x07"     // 原版同款：条目=窗口调色板下标

class TPuzzleView : public TView
{
public:
    explicit TPuzzleView(const TRect& r) : TView(r), m_moves(0), m_solved(False)
    {
        options |= ofSelectable;       // 可聚焦才能收键鼠
        eventMask |= evKeyboard;
        const char* start = "ABCDEFGHIJKLMNO ";
        for (int i = 0; i < 16; ++i) m_board[i] = start[i];
        m_board[16] = '\0';
        // 注意：不打乱——确定性开局；交互态用菜单 Scramble（rand）
    }

    void moveKey(int key);
    void winCheck();
    const char* board() const { return &m_board[0]; }
    int moves() const { return m_moves; }
    Boolean solved() const { return m_solved; }

    void draw() override
    {
        static const char map[15] = { 0,1,0,1, 1,0,1,0, 0,1,0,1, 1,0,1 };
        TColorAttr cBack = getColor(1);
        TColorAttr c[2] = { getColor(1), m_solved ? getColor(1) : getColor(2) };
        char tmp[8], num[8];
        for (short i = 0; i <= 3; ++i)
        {
            TDrawBuffer b;
            b.moveChar(0, ' ', cBack, 18);
            if (i == 1) b.moveStr(13, "Move", cBack);
            if (i == 2) { std::snprintf(num, sizeof num, "%d", m_moves); b.moveStr(14, num, cBack); }
            for (short j = 0; j <= 3; ++j)
            {
                std::strcpy(tmp, "   ");
                tmp[1] = m_board[i * 4 + j];
                if (tmp[1] == ' ')
                    b.moveStr(short(j * 3), tmp, c[0]);
                else
                    b.moveStr(short(j * 3), tmp, c[uchar(map[uchar(tmp[1] - 'A')])]);
            }
            writeLine(0, i, 18, 1, b);
        }
    }

    TPalette& getPalette() const override
    {
        static TPalette palette(cpPuzzlePalette, sizeof(cpPuzzlePalette) - 1);
        return palette;
    }

    void handleEvent(TEvent& event) override
    {
        TView::handleEvent(event);
        if (m_solved && (event.what & (evKeyboard | evMouse)))
        {
            scramble();
            clearEvent(event);
        }
        if (event.what == evKeyDown)
        {
            moveKey(event.keyDown.keyCode);
            winCheck();
            clearEvent(event);
        }
        else if (event.what == evMouseDown)
        {
            moveTile(event.mouse.where);
            winCheck();
            clearEvent(event);
        }
    }

    void scramble()
    {
        m_moves = 0;
        m_solved = False;
        int keys[4] = { kbUp, kbDown, kbLeft, kbRight };
        for (int i = 0; i < 500; ++i)
            moveKey(keys[(std::rand() >> 4) % 4]);
        m_moves = 0;
        drawView();
    }

private:
    void moveTile(TPoint global);

    char m_board[17];               // 16 格 + '\0'（log 用）
    int m_moves;
    Boolean m_solved;
};

void TPuzzleView::moveKey(int key)
{
    int i = 0;
    for (; i <= 15; ++i)
        if (m_board[i] == ' ') break;
    int x = i % 4, y = i / 4;
    // 方向键语义：按 kbUp = 【空格下方的块】滑上来（原版注释同款）
    switch (key)
    {
    case kbDown: if (y > 0) { m_board[i] = m_board[i - 4]; m_board[i - 4] = ' '; ++m_moves; } break;
    case kbUp:   if (y < 3) { m_board[i] = m_board[i + 4]; m_board[i + 4] = ' '; ++m_moves; } break;
    case kbRight:if (x > 0) { m_board[i] = m_board[i - 1]; m_board[i - 1] = ' '; ++m_moves; } break;
    case kbLeft: if (x < 3) { m_board[i] = m_board[i + 1]; m_board[i + 1] = ' '; ++m_moves; } break;
    default: return;                 // 非方向键：不动也不计步
    }
    drawView();
}

void TPuzzleView::moveTile(TPoint p)
{
    p = makeLocal(p);
    int i = 0;
    for (; i <= 15; ++i)
        if (m_board[i] == ' ') break;
    switch ((p.y / 1) * 4 + p.x / 3 - i)   // 点击格相对空格的位移
    {
    case -4: moveKey(kbDown);  break;
    case -1: moveKey(kbRight); break;
    case  1: moveKey(kbLeft);  break;
    case  4: moveKey(kbUp);    break;
    default: break;                     // 非相邻格：无效点击
    }
}

void TPuzzleView::winCheck()
{
    static const char* solution = "ABCDEFGHIJKLMNO ";
    m_solved = (std::strncmp(m_board, solution, 16) == 0);
    drawView();
}

class TPuzzleWindow : public TWindow
{
public:
    TPuzzleWindow()
        : TWindowInit(&TPuzzleWindow::initFrame)
        , TWindow(TRect(5, 2, 25, 9), "Puzzle", wnNoNumber)
    {
        flags &= ~(wfZoom | wfGrow);   // 原版同款：固定尺寸小窗
        growMode = 0;
        TRect r = getExtent();
        r.grow(-1, -1);
        m_view = new TPuzzleView(r);
        insert(m_view);
    }
    TPuzzleView* m_view;
};

// ============================================================
// 主题二：表单对话框（TInputLine + TValidator）
// ============================================================
// 非空校验：子类化 valid()（tvforms TKeyInputLine 技法）。
// 【坑】失败路径会 messageBox（模态）——selftest 不许踩这条路。
class TRequiredInputLine : public TInputLine
{
public:
    TRequiredInputLine(const TRect& r, int maxLen)
        : TInputLine(r, maxLen) {}

    Boolean valid(ushort command) override
    {
        if (command != cmCancel && command != cmValid && std::strlen(data) == 0)
        {
            select();
            messageBox("This field cannot be empty.", mfError | mfOKButton);
            return False;
        }
        return TInputLine::valid(command);
    }
};

class TProfileDialog : public TDialog
{
public:
    TProfileDialog()
        : TWindowInit(&TProfileDialog::initFrame)
        , TDialog(TRect(20, 4, 60, 14), "档案表单")
        , m_name(nullptr), m_age(nullptr)
    {
        TRect r = getExtent();
        r.move((TProgram::deskTop->size.x - r.b.x) / 2,
               (TProgram::deskTop->size.y - r.b.y) / 2);
        changeBounds(r);

        m_name = new TRequiredInputLine(TRect(14, 2, 36, 3), 24);
        insert(m_name);
        insert(new TLabel(TRect(3, 2, 13, 3), "~N~ame:", m_name));

        // 数值域：现成 TRangeValidator——字符过滤 + 范围拦截一肩挑
        m_age = new TInputLine(TRect(14, 4, 26, 5), 8,
                               new TRangeValidator(1, 120));
        insert(m_age);
        insert(new TLabel(TRect(3, 4, 13, 5), "~A~ge:", m_age));

        insert(new TButton(TRect(8, 7, 20, 9), "~O~K", cmOK, bfDefault));
        insert(new TButton(TRect(24, 7, 38, 9), "~C~ancel", cmCancel, bfNormal));
        m_name->focus();
    }

    TRequiredInputLine* m_name;
    TInputLine* m_age;
};

// ============================================================
// 应用
// ============================================================
// 视图级 getColor 包装（selftest 日志用）
static unsigned getColorOf(TView* v, int idx)
{
    return (unsigned)(ushort)v->getColor(ushort(idx));
}

class TDemoApp : public TApplication
{
public:
    TDemoApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);

    TPuzzleView* m_puzzle = nullptr;

private:
    void selftestProbes();
};

TDemoApp::TDemoApp()
    : TProgInit(&TDemoApp::initStatusLine,
                &TDemoApp::initMenuBar,
                &TDemoApp::initDeskTop)
{
    if (g_selftest) setTimer(600, -1);
}

void TDemoApp::handleEvent(TEvent& event)
{
    TApplication::handleEvent(event);
    if (event.what == evCommand)
    {
        switch (event.message.command)
        {
        case cmShowSwatch:
            insertWindow(new TSwatchWindow());
            clearEvent(event);
            break;
        case cmShowPuzzle:
        {
            TPuzzleWindow* w = static_cast<TPuzzleWindow*>(insertWindow(new TPuzzleWindow()));
            m_puzzle = w ? w->m_view : nullptr;
            clearEvent(event);
            break;
        }
        case cmShowProfile:
        {
            TProfileDialog* d = new TProfileDialog();
            deskTop->execView(d);
            TObject::destroy(d);
            clearEvent(event);
            break;
        }
        case cmScramble:
            if (m_puzzle) m_puzzle->scramble();
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
            selftestProbes();
            message(this, evCommand, cmQuit, 0);
            clearEvent(event);
        }
    }
}

// ---------- selftest：三主题程序化探针 ----------
void TDemoApp::selftestProbes()
{
    // 一、调色板：解析出的真实色号（两跑一致 = 调色板链确定性的证据）
    {
        TSwatchWindow* w = static_cast<TSwatchWindow*>(insertWindow(new TSwatchWindow()));
        if (w)
        {
            TSwatchView* v = static_cast<TSwatchView*>(w->first());
            if (v)
                for (int i = 1; i <= 5; ++i)
                    Log("swatch %d 号解析色号 = 0x%02X\n", i, (unsigned)getColorOf(v, i));
            // （getColorOf 见下：视图级 getColor 的直通包装）
        }
    }

    // 二、表单：谓词级校验（不触发模态）
    {
        TProfileDialog* d = new TProfileDialog();
        // 合法数据走完整 valid(cmOK)（内部 validator->validate，好路径不弹框）
        std::strcpy(d->m_name->data, "tvision");
        std::strcpy(d->m_age->data, "42");
        Log("合法路径 valid(cmOK)：name=%d age=%d\n",
            d->m_name->valid(cmOK) ? 1 : 0, d->m_age->valid(cmOK) ? 1 : 0);
        Log("初始数据回读：name='%s' age='%s'（data 即字符缓冲）\n",
            d->m_name->data, d->m_age->data);
        TObject::destroy(d);
        // 独立校验器谓词三档（validator 是 TInputLine 私有成员，
        // 想单测就自己持有一个 TRangeValidator）
        TRangeValidator* rv = new TRangeValidator(1, 120);
        Log("age isValid(\"42\")=%d \"999\"=%d \"abc\"=%d \"7x\"=%d\n",
            rv->isValid("42") ? 1 : 0, rv->isValid("999") ? 1 : 0,
            rv->isValid("abc") ? 1 : 0, rv->isValid("7x") ? 1 : 0);
        TObject::destroy(rv);
    }

    // 三、拼图：确定性步序——两步打乱、验未解、两步复原、验已解
    {
        TPuzzleWindow* w = static_cast<TPuzzleWindow*>(insertWindow(new TPuzzleWindow()));
        TPuzzleView* p = w ? w->m_view : nullptr;
        if (p)
        {
            p->moveKey(kbDown);
            p->moveKey(kbRight);
            p->winCheck();
            Log("两步后棋盘='%.16s' moves=%d solved=%d\n", p->board(), p->moves(), p->solved() ? 1 : 0);
            p->moveKey(kbLeft);
            p->moveKey(kbUp);
            p->winCheck();
            Log("复原后棋盘='%.16s' solved=%d\n", p->board(), p->solved() ? 1 : 0);
        }
    }
}

TMenuBar* TDemoApp::initMenuBar(TRect r)
{
    r.b.y = r.a.y + 1;
    TSubMenu& demoMenu =
        *new TSubMenu("~D~emo", kbAltD) +
          *new TMenuItem("色卡 ~S~watch", cmShowSwatch, kbNoKey) +
          *new TMenuItem("~P~uzzle 拼图", cmShowPuzzle, kbNoKey) +
          *new TMenuItem("Sc~r~amble 打乱", cmScramble, kbNoKey) +
          newLine() +
          *new TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X");
    TSubMenu& formMenu =
        *new TSubMenu("~F~orm", kbAltF) +
          *new TMenuItem("~档案~ Profile...", cmShowProfile, kbNoKey);
    return new TMenuBar(r, demoMenu + formMenu);
}

TStatusLine* TDemoApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem(0, kbF10, cmMenu));
}

int main(int argc, char** argv)
{
    g_selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (g_selftest)
        if (FILE* f = std::fopen("selftest-23_tv_colors_forms.txt", "w"))
            std::fprintf(f, "==== 23 tvision 调色板/表单/拼图 开始 ====\n"), std::fclose(f);

    TDemoApp app;
    app.run();

    if (g_selftest)
        Log("==== 23 tvision 调色板/表单/拼图 结束 ====\n");
    return 0;
}
