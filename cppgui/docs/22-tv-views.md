# 22 · 窗口体系：TWindow、TScroller 与自绘视图

> 对应示例：[examples/22_tv_views.cpp](../examples/22_tv_views.cpp)

## 22.1 TWindow 派生两件套与 insertWindow

```cpp
// ═══ 22.1 虚基类 TWindowInit 在前，TWindow 构造在后 ═══
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
```

TWindow 本身不画正文：它是"边框（TFrame）+ 标题 + 窗口序号"的窗格容器，内容区再 insert 子视图。派生两件套是固定姿势——初始化列表第一项 `TWindowInit(&X::initFrame)`（虚基类，必须最前），第二项才是 `TWindow(bounds, title, number)`；`number > 0` 时标题栏显示窗口序号，`wnNoNumber` 不显示。两个属性位记住：`options |= ofTileable` 让窗口参与平铺，`growMode` 决定桌面缩放时窗口跟不跟着长。`standardScrollBar` 顺手把两条滚动条挂在窗口边框上（`sbHandleKeyboard` 让滚动条响应键盘）。

应用侧接桌面用 `insertWindow(new TReaderWindow(...))`——插入并返回 TWindow*，焦点自动落到新窗口。

## 22.2 TScroller：delta / limit 与滚动时序

```cpp
// ═══ 22.2 内容总量 limit 与按 delta 取行的 draw ═══
TReaderView(const TRect& bounds, std::vector<std::string> lines, ...)
    : TScroller(bounds, hsb, vsb), m_lines(std::move(lines))
{
    growMode = gfGrowHiX | gfGrowHiY;
    limit.x = 0;
    for (const auto& s : m_lines)
        limit.x = max(limit.x, strwidth(s));   // 按显示宽度计，CJK 算 2
    limit.y = (int)m_lines.size();
}

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

void setState(ushort aState, Boolean enable) override
{
    TScroller::setState(aState, enable);
    if (enable && (aState & sfExposed))
        setLimit(limit.x, limit.y);             // 暴露时才把总量告知滚动条
}
```

TScroller 解决"内容大于视图"：`delta` 是内容左上角当前的滚偏移，`limit` 是内容总量（列数 × 行数）。滚动链条是**滚动条挪动 → scrollTo → delta 变 → scrollDraw → draw 按 delta 重取可见行**——draw 里 `delta.y + i` 就是屏幕第 i 行对应的文本行号，`moveStr` 的末参 `delta.x` 顺手做水平裁剪。时序关键点：`setLimit` 要等 `setState(sfExposed)`——窗口暴露后再把总量告知滚动条（官方 fileview.cpp 同款时序），构造期过早设置会被后续状态切换冲掉。`strwidth` 按显示宽度计（CJK 每字 2 列），所以 limit.x 是"看得见的列数"而不是字节数。

## 22.3 自绘视图：两套绘制 API 的颜色语义

```cpp
// ═══ 22.3 writeChar/writeStr 的 color 参数是调色板下标 ═══
void draw() override
{
    for (short y = 0; y < size.y; ++y)          // 1 号色铺空格清屏
        writeChar(0, y, ' ', 1, size.x);
    writeStr(1, 0, m_title.c_str(), 3);         // 标题：3 号色
    writeChar(0, 1, '-', 2, size.x);            // 分隔线：2 号色连写
    ...
    writeStr(2, short(2 + i), rows[i], 1);      // 正文：1 号色
    writeStr(short(size.x - 12), short(size.y - 1), badge, 4);  // 角标：4 号
}

void handleEvent(TEvent& event) override
{
    TView::handleEvent(event);
    if (event.what == evBroadcast && event.message.command == cmTimerExpired)
    {
        ++m_blinks;                 // 收到定时广播就重绘一次
        drawView();
        // 【坑】广播不许 clearEvent：那会终止传播，应用层就收不到
        // cmTimerExpired、selftest 退出信号被吃——实测挂死 60s。
    }
}
```

TView 直绘两条正路：`writeChar/writeStr` 按**调色板下标**直写——color 参数是 1/2/3/4 这样的索引，经虚函数 mapColor 查本视图调色板换算成真色号（23 章拆这条链）；或像 22.2 那样 `TDrawBuffer` 组装整行后 `writeBuf/writeLine`——但 moveXXX 系吃的是**真色号**，得先 `getColor(i)` 上溯拿到。两条路最终都汇到 writeView 裁剪，写越界不炸、静默裁掉。

TBannerView 还演示了视图收事件的前提：`eventMask |= evKeyboard | evBroadcast`——TView 默认**只吃鼠标**，键盘和广播要显式开。它收到定时广播就 `drawView()` 重绘一次角标计数，但**绝不清事件**：广播的语义是"人人可见"，clearEvent 会终止传播把应用层的退出信号一起吃掉。

## 22.4 桌面管理与标准窗口命令

```cpp
// ═══ 22.4 Window 菜单：标准命令谁接谁 ═══
TSubMenu& winMenu =
    *new TSubMenu("~W~indow", kbAltW) +
      *new TMenuItem("~N~ext", cmNext, kbF6, hcNoContext, "F6") +
      *new TMenuItem("~T~ile", cmTile, kbNoKey) +
      *new TMenuItem("Cas~c~ade", cmCascade, kbNoKey);
```

标准窗口命令的接线分层：`cmZoom`（F5）/`cmClose`（Alt-F3）/`cmResize`（Ctrl-F5）由 **TWindow 自接**；`cmNext`（F6 轮换焦点）由 **TGroup** 接；`cmTile`（平铺）/`cmCascade`（级联）由 **TApplication** 统一接管。菜单只是入口，处理器全在框架里——应用层一个 case 都不用写。数桌面窗口则要自己走链表：`deskTop->first()` 起、`nextView()` 迭代，剔除 `deskTop->background`（背景视图不是窗口）。

## 22.5 selftest 探针：数窗、焦点、夹取、zoom

```cpp
// ═══ 22.5 scrollTo 越界夹取与程序化 zoom ═══
m_reader->scrollTo(8, 10);
Log("scrollTo(8,10) → delta=(%d,%d)\n", m_reader->delta.x, m_reader->delta.y);
m_reader->scrollTo(900, 900);
TPoint lim = m_reader->contentLimit();
Log("scrollTo(900,900) → delta=(%d,%d)（内容 limit=(%d,%d)）\n", ...);

TPoint before = m_bannerWin->size;
m_bannerWin->zoom();
Log("banner zoom：%dx%d → %dx%d（F5 同款路径）\n", ...);
```

四个探针各自验证一层数据：桌面直接子视图计数、`deskTop->current` 焦点窗口标题、TScroller 的滚偏移夹取、TWindow 的程序化缩放（zoom 走 sizeLimits → locate 重摆，与按 F5 完全同路）。

## 22.6 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 22_tv_views
```

sidecar（`build/docs-ref/22_tv_views.sidecar`）：

```text
==== 22 tvision 视图与窗口 开始 ====
桌面窗口数=3（背景视图另算，不占窗口数）
焦点窗口标题='自绘视图'
scrollTo(8,10) → delta=(0,8)
scrollTo(900,900) → delta=(0,8)（内容 limit=(62,22)）
banner zoom：28x8 → 120x28（F5 同款路径）
==== 22 tvision 视图与窗口 结束 ====
```

逐行解读：**窗口数=3**——两个读窗 + 一个横幅窗，背景视图被剔除不算；**焦点='自绘视图'**——最后 insertWindow 的横幅窗自动成为 current。**scrollTo(8,10) → delta=(0,8)** 是夹取的铁证：读窗内容 limit=(62,22)（最长行显示宽 62、共 22 行），而视图本身 90×14（桌面 120×28 − grow 左右各 14、上下各 6 − 边框 2），水平方向**视图比内容还宽**（62−90 为负），请求的 x=8 被夹回 0；垂直方向上限 = limit.y − size.y = 22−14 = 8，请求的 y=10 落到 8——而 scrollTo(900,900) 结果同样是 (0,8)，说明 900 这种荒唐值也被静默夹到末页。**zoom：28x8 → 120x28**——横幅窗原尺寸 28 列 × 8 行，zoom 后变桌面全幅 120×28，与按 F5 等效。

## 坑位清单

- **广播不许 clearEvent**：子视图 handleEvent 里处理完 `evBroadcast + cmTimerExpired` 若顺手 clearEvent，传播终止、应用层收不到退出信号——实测挂死 60s 被 build.ps1 超时杀。广播要"人人可见"，处理不清。
- **Uses_TBackground 不展开则指针比较编译不过**：数窗口时 `v != deskTop->background` 是 TView* 对 TBackground*；不 `#define Uses_TBackground`，TBackground 声明不展开，两个指针类型间无转换，直接编译错。
- **TView 默认不收键盘**：eventMask 缺省只含鼠标事件；要收 evKeyboard/evBroadcast 必须显式 `eventMask |=`（TBannerView 构造里那行）。
- **setLimit 时序：等 setState(sfExposed)**：构造期窗口尚未暴露，过早告知滚动条会被冲掉；标准写法是 setState 里见 sfExposed 使能才 setLimit（fileview.cpp 同款）。
- **两套绘制 API 的颜色参数语义相反**：`writeChar/writeStr` 吃**调色板下标**（mapColor 查表），`TDrawBuffer` 系 moveXXX 吃**真色号**（先 getColor 上溯）——搞混了就是把下标当色号用，画面直接错色。
- **scrollTo 静默夹取**：请求超出 `limit − size` 自动落到末页、不报错——sidecar 的 (8,10)→(0,8) 里 x 被夹成 0 正是"窗口宽于内容"的现场。别指望 scrollTo 失败报错，判断能不能滚要看 limit 与 size 的差。

---

上一章：[21 · 菜单树、命令分发与模态对话框](21-tv-menus-dialogs.md) ｜ 下一章：[23 · 三级间接调色板、表单校验与滑块拼图](23-tv-colors-forms.md) ｜ 返回：[README](../README.md)
