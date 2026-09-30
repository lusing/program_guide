# 15 · FTXUI 组件体系与事件循环

> 对应示例：[examples/15_ftxui_components.cpp](../examples/15_ftxui_components.cpp)

## 15.1 从 Element 到 Component：App 与三种屏幕

14 章的 dom 层只管"画"；交互要靠 component 层。`Component` 是可聚焦、可收事件的节点（`ComponentBase` 的 `shared_ptr`），`Element` 只是它在某一帧的外观。驱动组件的循环壳在 master 里已从 `ScreenInteractive` **改名 `App`**——旧名只剩别名，老教程代码原样能编译，但新代码应写 `App`（坑位第 2 条）。三种屏幕形态按需选：

- `App::Fullscreen()`——备用屏独占整终端 + 鼠标序列，本章与 19 章用它；
- `App::TerminalOutput()`——在正常滚动的终端里就地打印；
- `App::FitComponent()`——屏幕尺寸贴着组件需求走，16 章 ResizableSplit 演示用。

## 15.2 内置组件全家：状态由你给指针

```cpp
// ═══ 15.1 状态在 main 栈上，组件拿指针共享 ═══
std::string input_text = "hello";
bool check1 = false, check2 = true;
int  radio_sel = 1;
int  menu_sel = 0;
int  slider_val = 50;
int  toggle_idx = 0;               // 【坑】Toggle 状态是 int(0/1)，不是 bool
...
// ═══ 15.2 Container::Vertical 聚合：子顺序 = Tab 顺序 ═══
auto container = Container::Vertical({
    Input(&input_text, "输入…"),
    Button("点我 +1", [&] { button_clicks++; }),
    Container::Horizontal({
        Checkbox("选项 A", &check1),
        Checkbox("选项 B", &check2),
    }),
    Radiobox(&radio_entries, &radio_sel),
    Toggle(&toggle_entries, &toggle_idx),
    Menu(&menu_entries, &menu_sel),
    Dropdown(&dropdown_entries, &dropdown_sel),
    Slider("数值:", &slider_val, 0, 100, 1),
});
```

八个内置组件一句话画像：`Input` 单行文本、`Button` 回调、`Checkbox` 开关、`Radiobox` 单选、`Toggle` 两态切换、`Menu` 竖排选择、`Dropdown` 下拉单选、`Slider` 数值滑杆。共同约定是**组件不拥有状态**：你把变量的地址交进去（`Input(&input_text, ...)`），组件改它、你随时读它；`entries` 向量同理共享。`Toggle` 的状态是 `int`——`toggle_entries` 的下标 0/1，不是 bool，按 bool 接会窄化出错（坑位第 1 条）。

## 15.3 Renderer 外壳：外观与交互分离

```cpp
// ═══ 15.3 Renderer(child, fn)：child 管交互，fn 管外观 ═══
auto renderer = Renderer(container, [&] {
    return vbox({
        hbox({ text("输入: ") | color(Color::Yellow), text(input_text) }),
        hbox({ text("点击次数: "), text(std::to_string(button_clicks)) | color(Color::Green) }),
        separator(),
        text("radiobox 选择: " + radio_entries[radio_sel]),
        text("menu 选择: " + menu_entries[menu_sel]),
        text("dropdown 选择: " + dropdown_entries[dropdown_sel]),
        text("slider 值: " + std::to_string(slider_val)),
        hbox({ text("toggle 状态: "),
               toggle_idx ? text("开") | color(Color::Green)
                          : text("关") | color(Color::Red) }),
        separator(),
        text("Tab/Shift+Tab 切焦点，q 或 Esc 退出") | dim,
    }) | border | size(WIDTH, LESS_THAN, 50);
});
```

双参 `Renderer(child, fn)` 是组合的基本手法：事件与焦点照常路由进 `child`，`Render()` 的产出改由 `fn` 决定。注意 fn 里**没有** `container->Render()`——交互组件不上屏，画面只是一块回显面板（各状态当前值的只读投影）。所以输出里看不到复选框和菜单的框线，但 Tab 仍能走进这些"隐身"组件改状态，回显随之变化（坑位第 3 条；18 章会看到 `buttons->Render()` 的可见嵌入正写法）。

## 15.4 焦点环与事件流

Tab/Shift-Tab 在 `Container` 的子组件间循环移动焦点——只有可聚焦的组件才进环（Input/Button/Checkbox 都行，`text` 回显不可）。事件从树根向下路由：组件的 `OnEvent` 返回 true 表示吃掉，返回 false 继续向兄弟/子级传播。最外层再包一个 `CatchEvent` 当总闸：

```cpp
// ═══ 15.4 CatchEvent 总闸：返回 true 才吃掉事件 ═══
auto app = CatchEvent(renderer, [&](Event e) {
    if (e == Event::Character('q') || e == Event::Escape)
    { screen.Exit(); return true; }
    if (e == Event::Custom && selftest)
    { screen.Exit(); return true; }
    return false;
});
```

`CatchEvent` 拿到事件先于所有子组件：q/Esc 在这里被认领并 `screen.Exit()`；返回 false 的键继续流向焦点组件——假如对 q 忘了返回 true，它会掉进焦点所在的 `Input`，变成正文里多出的一个字母 q（冒泡语义见 18 章 `MoverComponent::OnEvent` 末尾的 `return false` 注释）。

## 15.5 selftest 退出通路：jthread + PostEvent

无人值守退出走官方 `examples/component/custom_loop.cpp` 通路——后台线程投递自定义事件：

```cpp
// ═══ 15.5 PostEvent(Event::Custom)：从别的线程唤醒主循环 ═══
std::jthread t([&screen] {
    std::this_thread::sleep_for(std::chrono::milliseconds(600));
    screen.PostEvent(Event::Custom);
});
screen.Loop(app);
// jthread 析构自动 join
```

`PostEvent` 是线程安全的事件投递：主循环正阻塞在输入等待上，事件到达即唤醒——先重绘一帧，再把事件交给组件树，`CatchEvent` 认领 `Event::Custom` 后退出。输出里正好能看到两帧完全相同的画面：初始帧，加上 PostEvent 唤醒后的那一帧。

## 15.6 运行与输出

构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 15_ftxui_components
```

selftest 实测输出（`build/docs-ref/15_ftxui_components.out`；剥行尾 CR，NUL 与 ANSI 转义字节原样保留；其中可见符号 U+2400 代表实测输出里的 NUL 字节——转义序列两端的 NUL 原样入库会让 git 把整章当二进制，故代之）：

```text
==== 15 FTXUI 组件与事件循环 开始 ====
␀[?1049h[?7l[?1000h[?1003h[?1015h[?1006h␀[?25l╭──────────────────────────────────────────────────╮                            
│[33m[49m输入: [39m[49mhello                                       │                            
│点击次数: [32m[49m0[39m[49m                                       │                            
├──────────────────────────────────────────────────┤                            
│radiobox 选择: 中                                 │                            
│menu 选择: 文件                                   │                            
│dropdown 选择: 北京                               │                            
│slider 值: 50                                     │                            
│toggle 状态: [31m[49m关[39m[49m                                   │                            
├──────────────────────────────────────────────────┤                            
│[2mTab/Shift+Tab 切焦点，q 或 Esc 退出               [22m│                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
╰──────────────────────────────────────────────────╯                            ␀[?25l
[23A╭──────────────────────────────────────────────────╮                            
│[33m[49m输入: [39m[49mhello                                       │                            
│点击次数: [32m[49m0[39m[49m                                       │                            
├──────────────────────────────────────────────────┤                            
│radiobox 选择: 中                                 │                            
│menu 选择: 文件                                   │                            
│dropdown 选择: 北京                               │                            
│slider 值: 50                                     │                            
│toggle 状态: [31m[49m关[39m[49m                                   │                            
├──────────────────────────────────────────────────┤                            
│[2mTab/Shift+Tab 切焦点，q 或 Esc 退出               [22m│                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
│                                                  │                            
╰──────────────────────────────────────────────────╯                            ␀[?25h[?1006l[?1015l[?1003l[?1000l[?7h[?1049l␀
事件循环正常退出；末态 slider=50 toggle=0 radio=1 menu=0 dropdown=0
==== 15 FTXUI 组件与事件循环 结束 ====
```

这 49 行值得逐段读懂，它们是 Fullscreen 模式的完整字节协议：开头 `\x1b[?1049h` 切入备用屏，`\x1b[?1000h`/`\x1b[?1003h`/`\x1b[?1015h`/`\x1b[?1006h` 四条打开鼠标报告，`\x1b[?25l` 隐藏光标（NUL 字节是序列间的填充）。中段是两帧 23 行的回显面板：第二帧前的 `\x1b[23A` 把光标上移 23 行原地覆盖，正是 PostEvent 唤醒的那次重绘。结尾 `\x1b[?25h` 恢复光标、逐条撤销鼠标与备用屏，回主屏后打出末态行——所有组件状态原封未动（slider=50 toggle=0 radio=1 menu=0 dropdown=0），证明退出通路干净无副作用。面板内还看得到 `color(Color::Yellow)` 的 `\x1b[33m`、`dim` 的 `\x1b[2m` 等 SGR 转义：FTXUI 的"颜色"就是这些字节，17 章展开。

## 坑位清单

- **Toggle 的状态是 int 不是 bool**：它是 `toggle_entries` 的下标（0=关 1=开），按 bool 接指针会窄化、语义也错（源码 15_ftxui_components.cpp 状态区【坑】注释；FTXUI 批次提交 2472096 实测收录）。
- **ScreenInteractive 已改名 App**：master 里循环壳叫 `App`（`ftxui/component/app.hpp`），旧名只剩别名——照老教程抄 `ScreenInteractive::Fullscreen` 能编译，但新代码应统一写 `App::Fullscreen()`（源码头注释；提交 2472096）。
- **`Renderer(child, fn)` 的 fn 不会自动画出 child**：忘了在 fn 里调 `child->Render()`，交互件全部"隐身"——能 Tab 到、能改状态，就是看不见。本章输出即此形态（有意为之的回显面板），18 章 tab0 是嵌入写法。
- **CatchEvent 返回 true 才吃掉事件**：只观察不认领（return false），q 会继续流向焦点组件，被 `Input` 当正文吃掉——退出键的拦截必须 return true（事件冒泡语义，见 18 章自定义组件）。
- **TUI 启动会改控制台代码页，.NET 管道默认按控制台 CP 解码**：同批第二跑输出就变 UTF-8、两跑必不一致；build.ps1 显式钉死 `StandardOutputEncoding = UTF8` 按字节忠实回读（build.ps1 注释；提交 2472096）。副作用还有：备用屏/鼠标/Cursor 转义与 NUL 字节全都进了 stdout，逐字节引用时一个都不能少。

---

上一章：[14 · FTXUI 元素树：声明式范式与渲染到字符串](14-ftxui-dom.md) ｜ 下一章：[16 · FTXUI 布局进阶：约束、弹性与网格](16-ftxui-layout.md) ｜ 返回：[README](../README.md)
