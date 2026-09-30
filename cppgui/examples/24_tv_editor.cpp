// ============================================================
// 24_tv_editor.cpp —— 迷你文本编辑器：TEditWindow / TFileEditor
//
// 要点：
//   * TEditWindow(bounds, fileName, number)：自带 TFileEditor +
//     两条滚动条 + 行列指示器（TIndicator，右上角）；fileName 为空
//     = 无名新档；非空则构造时 fexpand+loadFile 直接装盘上内容
//   * TEditor 缓冲 = gap buffer：curPtr 是缝隙位置；跨缝取字符用
//     bufChar(i)；行分隔 \r、\n、\r\n 通吃（edits.cpp countLines）
//   * 程序化编辑 API：insertText(文,长,allowUndo) / setCurPtr(p,0)
//     （同步维护 curPos 行列）/ modified 脏标志 / save()（fileName
//     为空会转 saveAs 弹框——程序化保存前必须先填 fileName）
//   * 命令接线三层：cmSave/cmSaveAs 由 TFileEditor::handleEvent 自接；
//     cmCut/cmCopy/cmPaste/cmUndo 由 TEditor 自接（无选区时自动禁用，
//     构造期 disableCommands 兜底）；cmNew/cmOpen 落到应用层
//   * TFileDialog(通配符, 标题, 输入框名, fdOpenButton, 历史id) +
//     execDialog（validView→setData→execView→getData 的标准包装）
//   * selftest：插文→验 bufLen/脏标志→挪光标验 curPos→存盘→回读
//     比对→第二窗 loadFile 同一文件验长度→quit
// 官方参考：examples/tvedit/tvedit{1,2,3}.cpp、editors.h
// ============================================================
#define Uses_TKeys
#define Uses_TApplication
#define Uses_TProgram
#define Uses_TDeskTop
#define Uses_TEvent
#define Uses_TRect
#define Uses_TObject
#define Uses_TEditWindow
#define Uses_TEditor
#define Uses_TFileEditor
#define Uses_TFileDialog
#define Uses_TDialog
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

static bool g_selftest = false;
static void Log(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    if (FILE* f = std::fopen("selftest-24_tv_editor.txt", "a"))
        std::vfprintf(f, fmt, ap), std::fclose(f);
    va_end(ap);
}

// 欢迎文本：程序化 insertText 灌进新档（交互/selftest 共用）
static const char* kWelcome =
    "== tvision 迷你编辑器 ==\n"
    "第二行：setCurPtr 挪光标，curPos 即时给行列。\n"
    "第三行：F2 存盘，F3 打开，Ctrl-Y 删行，编辑类命令随选区自动启停。\n"
    "END";

// tvedit2.cpp 同款：对话框标准执行包装（含数据双向搬运）
static ushort execDialog(TDialog* d, void* data)
{
    TView* p = TProgram::application->validView(d);
    if (p == 0)
        return cmCancel;
    if (data != 0)
        p->setData(data);
    ushort result = TProgram::deskTop->execView(p);
    if (result != cmCancel && data != 0)
        p->getData(data);
    TObject::destroy(p);
    return result;
}

class TEditorApp : public TApplication
{
public:
    TEditorApp();

    virtual void handleEvent(TEvent& event) override;
    static TMenuBar* initMenuBar(TRect);
    static TStatusLine* initStatusLine(TRect);

    TEditWindow* openEditor(const char* fileName);

private:
    void fileOpen();
    void selftestProbes();
};

TEditorApp::TEditorApp()
    : TProgInit(&TEditorApp::initStatusLine,
                &TEditorApp::initMenuBar,
                &TEditorApp::initDeskTop)
{
    // tvedit1.cpp 同款：先全禁编辑类命令——TEditor 的 updateCommands
    // 会在选区/撤销栈变化时自动逐个解禁（命令启停的权威在编辑器）
    TCommandSet ts;
    ts.enableCmd(cmSave);
    ts.enableCmd(cmSaveAs);
    ts.enableCmd(cmCut);
    ts.enableCmd(cmCopy);
    ts.enableCmd(cmPaste);
    ts.enableCmd(cmUndo);
    disableCommands(ts);

    // 开一个无名新档并灌入欢迎文本（selftest 也从这里起步）
    TEditWindow* w = openEditor(nullptr);
    if (w && w->editor)
        w->editor->insertText(kWelcome, (uint)std::strlen(kWelcome), False);

    if (g_selftest) setTimer(600, -1);
}

// tvedit1.cpp openEditor：桌面全幅 + validView 体检 + 插入桌面
TEditWindow* TEditorApp::openEditor(const char* fileName)
{
    TRect r = deskTop->getExtent();
    TView* p = validView(new TEditWindow(r, fileName ? fileName : "", wnNoNumber));
    deskTop->insert(p);
    return (TEditWindow*)p;
}

void TEditorApp::fileOpen()
{
    char fileName[MAXPATH];
    std::strcpy(fileName, "*.txt;*.md;*.cpp");
    if (execDialog(new TFileDialog("*.txt;*.md;*.cpp", "Open file",
                                   "~N~ame", fdOpenButton, 100),
                   fileName) != cmCancel)
        openEditor(fileName);
}

void TEditorApp::handleEvent(TEvent& event)
{
    TApplication::handleEvent(event);
    if (event.what != evCommand)
    {
        if (event.what == evBroadcast && event.message.command == cmTimerExpired
            && g_selftest)
        {
            selftestProbes();
            message(this, evCommand, cmQuit, 0);
            clearEvent(event);
        }
        return;
    }
    switch (event.message.command)
    {
    case cmNew:
        openEditor(nullptr);
        break;
    case cmOpen:
        fileOpen();
        break;
    default:
        return;             // cmSave/cmSaveAs/cmCut... 编辑器自己接
    }
    clearEvent(event);
}

// ---------- selftest：编辑器全链路程序化探针 ----------
void TEditorApp::selftestProbes()
{
    // 1) 当前活动窗口 = 构造期开的无名档（deskTop->current 即焦点窗）
    TEditWindow* w1 = (TEditWindow*)deskTop->current;
    if (!w1 || !w1->editor) { Log("没有编辑窗口\n"); return; }
    TFileEditor* e1 = w1->editor;
    Log("插入后 bufLen=%u（strlen=%u） modified=%d\n",
        e1->bufLen, (unsigned)std::strlen(kWelcome), e1->modified ? 1 : 0);

    // 2) 光标：setCurPtr 同步维护 curPos（setSelect 里逐段算行/列）
    e1->setCurPtr(0, 0);
    Log("光标@0 → curPos=(%d,%d)\n", e1->curPos.x, e1->curPos.y);
    uint p2 = e1->lineStart(e1->nextLine(0));     // 第二行行首
    e1->setCurPtr(p2, 0);
    Log("光标@第二行行首(%u) → curPos=(%d,%d)\n", p2, e1->curPos.x, e1->curPos.y);
    char head[9];
    for (int i = 0; i < 8; ++i) head[i] = e1->bufChar((uint)i);   // 跨 gap 取字符
    head[8] = '\0';
    Log("bufChar(0..7)='%s'\n", head);

    // 3) 存盘：先填 fileName（空名会转 saveAs 弹框，selftest 禁路）
    std::strcpy(e1->fileName, "selftest-24-edit.txt");
    Boolean saved = e1->save();
    Log("save()=%d 存盘后 modified=%d（存盘清脏标志）\n",
        saved ? 1 : 0, e1->modified ? 1 : 0);

    // 4) 回读比对（剥 \r 后应与插入文本一致）
    char disk[512] = { 0 };
    size_t got = 0;
    if (FILE* f = std::fopen("selftest-24-edit.txt", "rb"))
    {
        got = std::fread(disk, 1, sizeof disk - 1, f);
        std::fclose(f);
    }
    char flat[512];
    size_t n = 0;
    for (size_t i = 0; i < got; ++i)
        if (disk[i] != '\r') flat[n++] = disk[i];
    flat[n] = '\0';
    Log("回读 %zu 字节，剥 \\r 后 %zu 字节，与插入文本一致=%d\n",
        got, n, std::strcmp(flat, kWelcome) == 0 ? 1 : 0);

    // 5) 第二窗口：构造即 loadFile，长度应与第一窗口一致
    TEditWindow* w2 = openEditor("selftest-24-edit.txt");
    if (w2 && w2->editor)
        Log("第二窗 loadFile 后 bufLen=%u（第一窗 %u） modified=%d\n",
            w2->editor->bufLen, e1->bufLen, w2->editor->modified ? 1 : 0);
}

TMenuBar* TEditorApp::initMenuBar(TRect r)
{
    r.b.y = r.a.y + 1;
    TSubMenu& fileMenu =
        *new TSubMenu("~F~ile", kbAltF) +
          *new TMenuItem("~N~ew", cmNew, kbNoKey) +
          *new TMenuItem("~O~pen...", cmOpen, kbF3, hcNoContext, "F3") +
          newLine() +
          *new TMenuItem("~S~ave", cmSave, kbF2, hcNoContext, "F2") +
          *new TMenuItem("S~a~ve as...", cmSaveAs, kbNoKey) +
          newLine() +
          *new TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X");

    // 这些命令编辑器自接；菜单只是入口（启停状态由 updateCommands 管）
    TSubMenu& editMenu =
        *new TSubMenu("~E~dit", kbAltE) +
          *new TMenuItem("~U~ndo", cmUndo, kbNoKey) +
          newLine() +
          *new TMenuItem("Cu~t~", cmCut, kbNoKey) +
          *new TMenuItem("~C~opy", cmCopy, kbNoKey) +
          *new TMenuItem("~P~aste", cmPaste, kbNoKey);

    return new TMenuBar(r, fileMenu + editMenu);
}

TStatusLine* TEditorApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~F2~ Save", kbF2, cmSave) +
            *new TStatusItem("~F3~ Open", kbF3, cmOpen) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem(0, kbF10, cmMenu));
}

int main(int argc, char** argv)
{
    g_selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (g_selftest)
        if (FILE* f = std::fopen("selftest-24_tv_editor.txt", "w"))
            std::fprintf(f, "==== 24 tvision 编辑器 开始 ====\n"), std::fclose(f);

    TEditorApp app;
    app.run();

    if (g_selftest)
        Log("==== 24 tvision 编辑器 结束 ====\n");
    return 0;
}
