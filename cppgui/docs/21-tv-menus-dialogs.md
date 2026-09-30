# 21 · 菜单树、命令分发与模态对话框

> 对应示例：[examples/21_tv_menus_dialogs.cpp](../examples/21_tv_menus_dialogs.cpp)

## 21.1 菜单树：operator+ 串接与命令号

```cpp
// ═══ 21.1 多菜单串接：TSubMenu 之间也用 operator+ ═══
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
```

菜单树是纯值链：`TSubMenu` 装 `TMenuItem`，`operator+` 把节点串成链（对 `new` 出的指针解引用再相加），`newLine()` 插分隔线。菜单与菜单之间同样用 `+` 拼进 TMenuBar——File 与 Options 两个下拉就这样长出来。注意两个细节：同一命令 `cmGreet` 可以挂多个菜单项（File 里一份、Options 里一份，殊途同归）；不需要加速键的项用 `kbNoKey` 占位。

命令号约定：框架保留 0–99（cmQuit/cmOK/...），自定义命令从 100 起——`cmGreet = 100`、`cmCount = 101`，与 20 章同款。

## 21.2 状态栏：TStatusDef 上下文段

```cpp
// ═══ 21.2 状态栏：每格 = 文本 + 键绑定 + 命令 ═══
TStatusLine* TDemoApp::initStatusLine(TRect r)
{
    r.a.y = r.b.y - 1;
    return new TStatusLine(r,
        *new TStatusDef(0, 0xFFFF) +
            *new TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit) +
            *new TStatusItem("~Ctrl-G~ Greet", kbCtrlG, cmGreet) +
            *new TStatusItem(0, kbF10, cmMenu));
}
```

TStatusDef(minHelpCtx, maxHelpCtx) 定义一个"帮助上下文段"——程序进入某段上下文时只显示该段的条目；本例全域一个段（0 到 0xFFFF）。段内多个 TStatusItem 各占状态栏一格，点击或按键即发对应命令，是"看得见的快捷键"。菜单加速键、状态栏绑定、handleEvent switch 三处引用同一组 cmXXX 常量——命令号是全程序的事件词汇表。

## 21.3 命令分发：handleEvent 的 switch

```cpp
// ═══ 21.3 命令分发：基类先行，switch 收尾 ═══
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
        ...
    }
}
```

三条入口殊途同归：菜单项 "Greeting..."、加速键 Ctrl-G、状态栏的 Ctrl-G 格——最终都变成 `evCommand + cmGreet` 落到这**同一个 switch**。这是命令号体制的好处：触发面可以随意增殖，处理器只有一个。cmCount 示范"命令不一定开窗口"——只往 sidecar 写一行日志（交互态点 Count 菜单即见 `greet count=N`）。timer 广播分支与 20 章同构，此处承载 selftest 探针（21.6 展开）。

## 21.4 表单对话框：TDialog + TInputLine + TLabel + TButton

```cpp
// ═══ 21.4 模态表单四件套与手工居中 ═══
explicit TGreetDialog()
    : TWindowInit(&TGreetDialog::initFrame)   // 虚基类：必须先于 TDialog
    , TDialog(TRect(20, 6, 58, 14), "Greeting")
    , m_input(nullptr)
{
    TRect r = getExtent();                     // 框架不会自动居中
    r.move((TProgram::deskTop->size.x - r.b.x) / 2,
           (TProgram::deskTop->size.y - r.b.y) / 2);
    changeBounds(r);

    m_input = new TInputLine(TRect(3, 3, 33, 4), 32, 0, ilMaxChars);
    insert(m_input);
    insert(new TStaticText(TRect(3, 2, 33, 3), "Enter your name:"));
    insert(new TButton(TRect(4, 6, 16, 8), "~O~K", cmOK, bfDefault));
    insert(new TButton(TRect(18, 6, 30, 8), "~C~ancel", cmCancel, bfNormal));
    m_input->focus();
}
```

四件套各司其职：TInputLine 是单行输入框——**TRect 高度恒为 1**（`(3,3,33,4)` 正是一行），构造参数给缓冲容量 32 与 `ilMaxChars` 长度约束；TStaticText 是静态标签（正式表单里应换 TLabel 做焦点联动，23 章用上）；TButton 用 `~O~K` 热键 + `cmOK`/`cmCancel` 命令，`bfDefault` 标默认按钮（回车触发）。坐标全部手工：tvision 没有 wx 的 sizer，一切靠 TRect 摆位——`getExtent → move → changeBounds` 三步手工居中。

## 21.5 execView 模态返回与 valid() 取数

```cpp
// ═══ 21.5 valid()：cmOK 落地时的取数钩子 ═══
Boolean valid(ushort command) override
{
    if (TDialog::valid(command) && command == cmOK && m_input)
        std::strncpy(m_buf, m_input->data, sizeof(m_buf) - 1);
    return True;
}

void TDemoApp::greeting()
{
    ++m_greetCount;
    TGreetDialog* d = new TGreetDialog();
    if (deskTop->execView(d) != cmCancel && d->m_buf[0])
        Log("greet #%d: name='%s'（execView 模态返回 cmOK）\n", m_greetCount, d->m_buf);
    TObject::destroy(d);
}
```

`deskTop->execView(d)` 模态执行对话框：内嵌一个事件循环，吃键盘焦点，直到某个按钮发 cmOK/cmCancel 才返回**该命令号**。取数走 `valid()` 钩子——对话框关闭前框架回调 valid(command)，我们在这里把 `m_input->data`（输入行的公共字符缓冲）拷进 `m_buf`；返回 True 放行关闭，返回 False 则拦截（23 章的表单校验正面用这招）。execView 返回后先判 `!= cmCancel` 再判缓冲非空，最后 `TObject::destroy(d)` 销毁——框架的统一销毁路径。

## 21.6 selftest：免模态直构取数

```cpp
// ═══ 21.6 不进模态：构造 → 填 data → valid(cmOK) 走同一条取数路径 ═══
auto* d = new TGreetDialog();
std::strncpy(d->m_input->data, "tvision", 32);   // 模拟输入
d->valid(cmOK);                                   // 走校验取数路径
Log("selftest dialog: data='%s'（不走 execView）\n", d->m_buf);
TObject::destroy(d);
message(this, evCommand, cmQuit, 0);
```

selftest 的矛盾：execView 等键盘输入，无人值守进去就挂死。解法是**免模态**：直接构造对话框对象（不 execView），往 `m_input->data` 填串模拟输入，手工调 `valid(cmOK)`——走的正是 21.5 的同一条校验取数路径，日志拿到 `m_buf` 后销毁、注入 cmQuit。模态 UI 与纯逻辑在这里解耦：取数逻辑可以在没有模态循环的情况下被完整验证。

## 21.7 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 21_tv_menus_dialogs
```

sidecar（`build/docs-ref/21_tv_menus_dialogs.sidecar`）：

```text
==== 21 tvision 菜单与对话框 开始 ====
selftest dialog: data='tvision'（不走 execView）
==== 21 tvision 菜单与对话框 结束 ====
```

中间一行是免模态通路的完整证据：`data='tvision'` 说明 `m_input->data`（手工填入）经 `valid(cmOK)` 正确落进了 `m_buf`——没进 execView，取数路径却被走到了。交互态另有两类日志（`greet #N: name='...'` 与 `greet count=N`）只在点菜单时产生，selftest 不经过。

## 坑位清单

- **虚基类 TWindowInit 必须列在基类列表最前**：TDialog 经 TWindow 继承虚基 TFrame，初始化列表必须先写 `TWindowInit(&X::initFrame)` 再写 `TDialog(...)`——虚基必须最先初始化，顺序反了编译器直接报错。
- **TInputLine 的 TRect 高度恒为 1**：`(3,3,33,4)` 才是一行输入框；给两行高它也只画一行，多余高度白给。容量与长度约束在构造参数（32 + ilMaxChars），不在 TRect。
- **对话框不会自动居中**：框架按你给的 TRect 原样落位，要居中得自己 `getExtent → move → changeBounds` 三步走。
- **execView 模态等输入，selftest 进去就挂死**：免模态取数法——new 对话框、填 `input->data`、调 `valid(cmOK)`，日志拿到再 destroy（见 21.6，sidecar 的 `data='tvision'` 即此产物）。
- **valid() 兼任取数钩子**：cmOK 落地时回调 valid(command)，在这里把 data 拷进外部缓冲最稳；它同时是唯一能在关闭前拦截的口（返回 False，23 章演示）。
- **销毁走 TObject::destroy 而非 delete**：框架统一销毁路径（先 shutDown 断链再析构），execView 返回后 `TObject::destroy(d)`。

---

上一章：[20 · tvision 应用骨架：桌面隐喻与事件循环](20-tv-hello.md) ｜ 下一章：[22 · 窗口体系：TWindow、TScroller 与自绘视图](22-tv-views.md) ｜ 返回：[README](../README.md)
