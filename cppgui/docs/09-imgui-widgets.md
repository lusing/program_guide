# 09 · 控件全集与 ID 机制：返回值即事件

> 对应示例：[examples/09_imgui_widgets.cpp](../examples/09_imgui_widgets.cpp)

## 9.1 从 08 章接过的骨架

08 章逐段走读的三段式骨架被折叠进共享头 [examples/imgui_dx11_app.h](../examples/imgui_dx11_app.h)（Win32+D3D11，09–13 章复用）。各章示例只剩三件事：填 `ImguiAppConfig`、写每帧调用的 `ui` 回调、可选的 `onInit`/`onExit` 钩子（12 章用 `onInit` 载字体，正好在 CreateContext 之后、首帧之前）：

```cpp
// ═══ 9.1 骨架复用：本章只写 UI 回调 ═══
cppgui::ImguiAppConfig cfg;
cfg.title = L"09 - widgets & ID";
cfg.selftest = selftest;
cfg.ui = &Ui;
cfg.onExit = [](int frames) {
    std::cout << frames << " frames rendered; final slider=" << g_slider ...
};
return cppgui::RunImguiApp(cfg);
```

本章主题在回调里：把常用控件全过一遍，读法只有一句——**每个控件函数每帧都调；"事件"就是这个函数在某一帧返回 true**。没有回调、没有监听器、没有控件对象。

## 9.2 控件清单：一屏走读

```cpp
// ═══ 9.2 布尔族：Checkbox / RadioButton（绑定 int）═══
if (ImGui::Checkbox("enable A", &g_check1)) { /* 本帧被切换 */ }
ImGui::SameLine();
if (ImGui::Checkbox("enable B", &g_check2)) { }
if (ImGui::RadioButton("low", &g_radio, 0)) { }
ImGui::SameLine();
if (ImGui::RadioButton("mid", &g_radio, 1)) { }
ImGui::SameLine();
if (ImGui::RadioButton("high", &g_radio, 2)) { }

// ═══ 9.3 数值与文本族：Slider / InputText ═══
ImGui::SeparatorText("numeric input");
if (ImGui::SliderFloat("float", &g_slider, 0.0f, 1.0f)) { }
if (ImGui::SliderInt("int", &g_slidint, 0, 10)) { }
if (ImGui::InputText("text", g_input, sizeof(g_input))) { }  // 每次编辑返回 true

// ═══ 9.4 选择族：Combo / ColorEdit3 / ProgressBar ═══
const char* items[] = { "apple", "banana", "cherry" };
if (ImGui::Combo("combo", &g_combo, items, IM_ARRAYSIZE(items))) { }
if (ImGui::ColorEdit3("color", g_color)) { }
if (ImGui::Button("click me")) g_clicks++;
ImGui::SameLine();
ImGui::Text("clicks = %d", g_clicks);
ImGui::ProgressBar(g_progress, ImVec2(-1, 0), "loading");
```

所有"有状态"的控件一律**传你自己变量的指针**：Checkbox 绑 bool、RadioButton 绑 int（第三参是本项的值）、Slider 绑 float/int、Combo 绑索引、ColorEdit3 绑 RGB 数组。框架不保存这些值，每帧只是读旧值画、写新值回——所以 `if (...) {}` 里甚至可以什么都不写（本例如此：状态已经在变量里了），返回值只在需要**副作用**（计数、触发动作）时才有用。这与 04 章 wx 控件的 `GetValue()/SetValue()` 形成鲜明对照：那里状态住在控件里、你是访客；这里状态住在你家、控件是过客。

`ProgressBar` 是少数无返回值的展示型控件（与 `Text` 同类）；`ImVec2(-1, 0)` 的 -1 表示宽度撑满可用区，这个约定贯穿 imgui 所有接受尺寸的接口。Combo 的数组项数用 `IM_ARRAYSIZE(items)` 宏取——imgui 自带的数组长度宏，比手写 `sizeof(items)/sizeof(items[0])` 顺手且不会忘。

## 9.3 状态外置：变量即模型

```cpp
// ═══ 9.5 应用状态：全部外置的普通变量（即时模式核心）═══
static bool  g_check1 = false, g_check2 = true;
static int   g_radio = 1;
static float g_slider = 0.5f;
static int   g_slidint = 3;
static char  g_input[128] = "hello";
static int   g_combo = 1;
static float g_color[3] = { 0.2f, 0.6f, 0.9f };
static int   g_clicks = 0;
```

这组 static 变量就是本示例的全部"模型"。窗口关掉再开，值不变（变量不随窗口生灭）；想把状态存盘，序列化这几个变量即可，没有控件树要遍历。窗口底部还有一行实时读数，把"模型"当帧回显：

```cpp
// ═══ 9.6 状态回显：UI 之外，变量随手可读 ═══
ImGui::Text("state: slider=%.2f slidint=%d combo=%d", g_slider, g_slidint, g_combo);
```

selftest 的证据也来自这里——`onExit` lambda 直接打印 `g_slider/g_combo/g_clicks` 的终值，40 帧无人操作后它们应保持初值（见 9.8 输出：`slider=0.5 combo=1 clicks=0`）。

## 9.4 ID 机制：字符串哈希定位控件

imgui 没有控件对象，那"哪个按钮被点了"怎么定位？答案：用 **ID**——窗口 ID 与控件标签字符串（经哈希）组成 `ImGuiID`。同一窗口内两个控件标签相同 → ID 相同 → imgui 分不清谁是谁。示例右侧说明窗口（`TextWrapped`）的原文是：

> Two widgets with the same label inside one window share the same ID: imgui logs 'ID collision' and their hover/active states interfere. Fix with ##suffix or PushID/PopID (see left).

复现方法很朴素：去掉后缀写两个 `ImGui::Button("reset")`，运行时 imgui 会打 ID collision 告警，且两个按钮的 hover 高亮/按下态互相串扰——因为它们在 imgui 眼里是同一个控件。

## 9.5 两种消歧解法：## 后缀与 PushID/PopID

```cpp
// ═══ 9.7 解法一："##id" 后缀——显示文本一致、ID 不同 ═══
if (ImGui::Button("reset##a")) g_clicks = 0;
ImGui::SameLine();
if (ImGui::Button("reset##b")) g_clicks = 100;

// ═══ 9.8 解法二：PushID/PopID 给一段控件加整数前缀（循环生成同名控件必用）═══
for (int i = 0; i < 3; ++i)
{
    ImGui::PushID(i);
    if (ImGui::Button("X")) g_clicks -= 1;
    ImGui::PopID();
    ImGui::SameLine();
}
ImGui::NewLine();
```

`##` 之后的文本只进 ID 不上屏：两个按钮都显示 "reset"，但 ID 分别是 `reset##a`/`reset##b`。`PushID(i)` 则把一个整数压进 **ID 栈**，此后到 `PopID()` 为止的控件 ID 都带上这个前缀——循环生成 N 行删除按钮（每行一个 "X"）是它的标准场景。两种解法等价，前者适合固定的一两个，后者适合批量。

## 9.6 排版初识：SameLine 与 Separator

```cpp
// ═══ 9.9 SameLine/SeparatorText：光标推进模型的全部 ═══
if (ImGui::Checkbox("enable A", &g_check1)) { /* 本帧被切换 */ }
ImGui::SameLine();
if (ImGui::Checkbox("enable B", &g_check2)) { }
...
ImGui::SeparatorText("numeric input");
```

每个控件函数执行完都会**推进排版光标**（默认换到下一行）。`SameLine()` 把光标折回上一项右侧；`Separator()` 画一条全宽横线强制换行，`SeparatorText("...")` 则是带小标题的分组线——一屏控件多起来之后，靠它划出"布尔族/数值族/选择族"的区块（本例四个分组全是它画的）。`NewLine()` 强制换到下一行（循环里 SameLine 之后的收尾用）。这是 imgui 唯一的布局机制——没有 sizer、没有网格、没有绝对定位（10 章展开这个心智模型）。

## 9.7 活字典：imgui_demo.cpp

本章控件清单远非全集（拖拽、列表框、树、颜色选择器、滑动小部件……都还没出场）。imgui 自带一部**活字典**：本地源码 `imgui_demo.cpp` 的 Widgets 节收录全部控件的用法、标志与组合形态，在你的程序里调一句 `ImGui::ShowDemoWindow()` 就能把整个演示窗口挂进去对照着看。本教程各章示例只取最常用的一层，遇到"某控件有没有某标志"的问题，顺序永远是：先翻 demo、再查 `imgui.h` 注释。

## 9.8 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 09_imgui_widgets
```

实测输出（`build/docs-ref/09_imgui_widgets.out`）：

```text
==== 09 ImGui 控件与 ID 开始 ====
40 frames rendered; final slider=0.5 combo=1 clicks=0
==== 09 ImGui 控件与 ID 结束 ====
```

终值即证据：40 帧里无人操作，外置状态保持初值（slider=0.5、combo=1、clicks=0）——控件函数每帧只是"路过"这些变量，没有碰它们。

## 坑位清单

- **同名控件 = 同 ID = 状态串扰**：imgui 用"窗口 ID + 标签哈希"定位控件，同一窗口里两个 `Button("reset")` 会在运行时打 "ID collision" 告警，hover/active 态互相干扰。固定场合用 `"reset##a"` 后缀（显示不变、ID 不同），循环批量场合用 `PushID(i)/PopID()`。
- **PushID/PopID 必须严格配对**：忘了 `PopID()`，ID 栈不平衡，此后本窗口所有控件 ID 带着残留前缀——与"看起来同名"的其他控件错位碰撞，症状诡异且报错不指名道姓。
- **返回值只在那一帧有效**：`Button` 的 true 只在被按下的当帧出现，下一帧就消失；不存在"事后查询按钮状态"的 API。同理 `SliderFloat` 拖动期间每帧 true、`InputText` 每次编辑每帧 true——把副作用写进 if 要意识到它可能连续触发几十帧（13 章字号滑条有正面处理）。
- **状态必须自己持有**：控件函数要传指针，`Checkbox("x", &v)` 的 `v` 得是你管理的变量。框架不替你保存任何应用状态，这是即时模式的本分而不是缺陷——换来的红利是关窗重开状态仍在、存档就是存这几个变量。
- **默认字体只有 ASCII**：内置 ProggyClean 是 13px 位图字体，仅覆盖 ASCII——中文显示为 "?"，必须自载字体（12 章）。本例 UI 文本全用英文正是这个原因；右侧说明窗口也用 `TextWrapped` 英文书写。

---

上一章：[08 · Dear ImGui 骨架：即时模式与双后端](08-imgui-hello.md) ｜ 下一章：[10 · 窗口系统：Begin/End、标志与子窗口](10-imgui-windows.md) ｜ 返回：[README](../README.md)
