# 23 · 三级间接调色板、表单校验与滑块拼图

> 对应示例：[examples/23_tv_colors_forms.cpp](../examples/23_tv_colors_forms.cpp)

## 23.1 调色板：视图条目 = 属主调色板的下标

```cpp
// ═══ 23.1 视图调色板：值不是色号，是属主下标 ═══
#define cpSwatchView "\x06\x07\x09\x0A\x0B"
//   1→窗口第 6 项、2→第 7 项（蓝窗内置 8 项之内）
//   3→第 9 项、4→第 10 项（本窗口 getPalette 追加的自定义项）
//   5→第 11 项（追加值 0x88 越过应用调色板上限 → errorAttr）

TPalette& getPalette() const override
{
    static TPalette palette(cpSwatchView, sizeof(cpSwatchView) - 1);
    return palette;
}
```

tvision 的调色板是一张**三级间接的样式表**：视图调色板的条目值是"**属主调色板的下标**"——`\x06` 不是"棕字蓝底"，是"取我属主（所在窗口）调色板的第 6 项"。窗口条目又是应用调色板的下标；逐级上溯到 TApplication（无属主）才落地为真实 BIOS 色号。中间一环有特例：**TDeskTop 的调色板为空 = 直通**（mapcolor.cpp:20 的 else 分支），窗口里的视图查到桌面这级不作变换、继续向上。

取真色号的统一入口是 `getColor(i)`：把索引走完 视图→窗口→(桌面直通)→应用 的上溯链后返回色号——22 章说 TDrawBuffer 系只认真色号，原因就在这：它不经 mapColor，你得自己先上溯。

```cpp
// ═══ 23.1（续）色卡视图：解析出的真色号连数值带颜色一起画 ═══
void draw() override
{
    char line[80];
    for (int i = 1; i <= 5 && i <= size.y; ++i)
    {
        // getColor(i)：把索引走完 视图→窗口→(桌面直通)→应用 的上溯链
        TColorAttr attr = TColorAttr(getColor(ushort(i)));
        std::snprintf(line, sizeof line, " 调色板 %d 号 → 0x%02X", i, (unsigned)attr);
        TDrawBuffer b;
        b.moveStr(0, line, attr, ushort(size.x));   // 入缓冲的是真色号
        writeLine(0, short(i - 1), size.x, 1, b);
    }
}
```

色卡视图是"所见即链路"的自证：每行把自己的第 i 号索引解析成真色号，把十六进制数值打进文本、再用该色号给整行上色——屏幕上看到的颜色与行内数字严格一致（selftest 日志复刻了同一组数值，见 23.5）。

## 23.2 窗口级扩展与越界演示

```cpp
// ═══ 23.2 相邻字面量拼接：蓝窗 8 项 + 追加 3 项 ═══
#define cpSwatchWindow  "\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F"
#define cpSwatchExtra   "\x6F\x2A\x88"

TPalette& getPalette() const override
{
    static TPalette p(cpSwatchWindow cpSwatchExtra,
                      sizeof(cpSwatchWindow cpSwatchExtra) - 1);
    return p;
}
```

给窗口扩展颜色的官方技法（examples/palette/palette.cpp 同款）：getPalette 覆写时把蓝窗原 8 项**原样重抄**、再用相邻字符串字面量拼接追加新项——C/C++ 编译器自动把相邻字面量粘成一个，于是窗口调色板有 11 项，前 8 项照旧、9–11 项是自定义。最后一项 `\x88` 是故意的越界探针：应用调色板 cpAppColor 共 135 项、合法下标上限 0x87，0x88=136 超界——getColor 不报错，静默返回错误属性 errorAttr **0xCF**（白字红底）。

## 23.3 表单：TInputLine + TRangeValidator

```cpp
// ═══ 23.3 数值域：现成校验器一肩挑 ═══
m_age = new TInputLine(TRect(14, 4, 26, 5), 8, new TRangeValidator(1, 120));
insert(m_age);
insert(new TLabel(TRect(3, 4, 13, 5), "~A~ge:", m_age));   // 标签联动焦点

// 非空校验：子类化 valid()（tvforms/fields.cpp 技法）
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
```

TInputLine 的构造尾参挂 TValidator：`TRangeValidator(1, 120)` 同时管两件事——键入时过滤非法字符、确认时拦截越界值。TLabel 是"活的"标签：热键 Alt+N 点击即把焦点送到关联的输入行（21 章的 TStaticText 没有这层联动）。自定义校验走子类化 `valid()`：返回 False 拦截关闭、`select()` 把焦点钉回本输入行、messageBox 报错——**注意这条失败路径是模态弹框**，selftest 绝不能踩（坑位清单第 5 条）。

## 23.4 拼图：两色调色板与确定性验证

```cpp
// ═══ 23.4 确定性开局 + 固定步序，禁 rand ═══
const char* start = "ABCDEFGHIJKLMNO ";      // 不打乱——确定性开局
...
// selftest：两步打乱、验未解；两步复原、验已解
p->moveKey(kbDown);   // 按下=空格下方的块滑上来（原版语义）
p->moveKey(kbRight);
p->winCheck();
p->moveKey(kbLeft);
p->moveKey(kbUp);
p->winCheck();
```

拼图（tvdemo/puzzle.cpp 改编）自带一个两色调色板 `"\x06\x07"`——棋盘格用 1 号、活跃块用 2 号，印证"调色板随视图走"：每个视图可以有自己的下标空间，最终色号由所在链决定。交互态的 Scramble 用 `rand()` 打 500 步；selftest 则必须确定性——初始摆好、走固定四步（Down/Right 打乱两步，Left/Up 复原两步），这样两跑输出逐字节一致，过 build.ps1 的一致性判定。

```cpp
// ═══ 23.4（续）方向键语义：你指挥的是空格的对家 ═══
case kbDown: if (y > 0) { m_board[i] = m_board[i - 4]; m_board[i - 4] = ' '; ++m_moves; } break;
case kbUp:   if (y < 3) { m_board[i] = m_board[i + 4]; m_board[i + 4] = ' '; ++m_moves; } break;

TPuzzleWindow()
    : TWindowInit(&TPuzzleWindow::initFrame)
    , TWindow(TRect(5, 2, 25, 9), "Puzzle", wnNoNumber)
{
    flags &= ~(wfZoom | wfGrow);   // 原版同款：固定尺寸小窗
    growMode = 0;
    ...
}
```

方向键是原版的小机关：**按 kbUp 滑上来的是空格【下方】的块**——四条 case 都以空格位置 i 为基准取 i±4（上下）或 i±1（左右），玩家指挥的不是某块而是"空格的对家"。窗口侧示范 TWindow 的另一面：`flags &= ~(wfZoom | wfGrow)` 摘掉整屏切换与拖拽缩放能力、growMode 清零——拼图就该是颗钉死的小窗（22 章反着用 growMode 让读窗随桌面伸缩）。鼠标点击同权：`moveTile` 把点击格换算成相对空格的位移（−4/−1/1/4），落回四个方向。

## 23.5 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 23_tv_colors_forms
```

sidecar（`build/docs-ref/23_tv_colors_forms.sidecar`）：

```text
==== 23 tvision 调色板/表单/拼图 开始 ====
swatch 1 号解析色号 = 0x1E
swatch 2 号解析色号 = 0x71
swatch 3 号解析色号 = 0x70
swatch 4 号解析色号 = 0x2B
swatch 5 号解析色号 = 0xCF
合法路径 valid(cmOK)：name=1 age=1
初始数据回读：name='tvision' age='42'（data 即字符缓冲）
age isValid("42")=1 "999"=0 "abc"=0 "7x"=0
两步后棋盘='ABCDEFGHIJ KMNOL' moves=2 solved=0
复原后棋盘='ABCDEFGHIJKLMNO ' solved=1
==== 23 tvision 调色板/表单/拼图 结束 ====
```

前五行是三级链的完整解剖（视图条目 → 窗口下标 → 应用下标 → 真色号）：

- **1 号**：`\x06` → 窗口第 6 项 `\x0D` → 应用第 13 项 → **0x1E**（黄字蓝底）
- **2 号**：`\x07` → 窗口第 7 项 `\x0E` → 应用第 14 项 → **0x71**（蓝字灰底）
- **3 号**：`\x09` → 窗口第 9 项（追加区首项）`\x6F` → 应用第 111 项 → **0x70**（普通正文色）
- **4 号**：`\x0A` → 窗口第 10 项 `\x2A` → 应用第 42 项 → **0x2B**（亮青字绿底）
- **5 号**：`\x0B` → 窗口第 11 项 `\x88`=136 > 135（上限 0x87）→ 越界 → **errorAttr 0xCF**

同一个视图、五条链，两跑一致即调色板解析确定性的证据。表单两行：合法数据走完整 `valid(cmOK)` 好路径不弹框（name=1 age=1），`data` 即公共字符缓冲可直接回读。谓词行是**独立持有的** TRangeValidator：合法 "42" 过，越界 "999"、非数字 "abc"、混合 "7x" 全拦——不碰对话框就把校验逻辑单测了。拼图两行：Down+Right 后棋盘 `'ABCDEFGHIJ KMNOL'`（K 与空格换位、L 沉底）moves=2 solved=0；Left+Up 逆序走回 `'ABCDEFGHIJKLMNO '` solved=1——步序可复算，正是确定性验证的意义。

## 坑位清单

- **调色板三级间接，条目值是"属主下标"不是色号**：视图条目 `\x06` 的含义是"取属主第 6 项"，逐级上溯到应用才落地真色号；TDeskTop 空板直通（mapcolor.cpp:20 else 分支）。把 `\x06` 当 BIOS 色号理解，配色必然错。
- **越界下标不报错，返回 errorAttr 0xCF**：追加项 0x88=136 超过 cpAppColor 的 135 项（上限 0x87），getColor 静默返回错误属性白字红底——sidecar 第 5 号的实测值就是它。排查"某块颜色不对"时先查链上下标有没有越界。
- **窗口级覆写是整体替换**：getPalette 覆写后蓝窗原 8 项必须照抄再拼接追加项；少抄一项，其后所有下标整体漂移。
- **validator 是 TInputLine 的私有成员**：想单测校验逻辑从对话框外面摸不到——自己 new 一个 `TRangeValidator(1,120)` 持有，纯谓词 `isValid(...)` 随便测（sidecar 的 1/0/0/0 三档就是这么来的）。
- **valid(cmOK) 失败路径弹模态框**：TRequiredInputLine 校验失败会 messageBox——无人值守踩进去就挂死；selftest 只走谓词与合法数据路径（本例 sidecar 里 name=1 age=1）。
- **selftest 禁 rand**：Scramble 用 `rand()` 每跑不同，过不了两跑一致性判定——开局确定性摆好、走固定步序，验证结果可复算（' KMNOL' → 复原 solved=1）。

---

上一章：[22 · 窗口体系：TWindow、TScroller 与自绘视图](22-tv-views.md) ｜ 下一章：[24 · 迷你文本编辑器：TEditWindow 与 gap buffer（全书终章）](24-tv-editor.md) ｜ 返回：[README](../README.md)
