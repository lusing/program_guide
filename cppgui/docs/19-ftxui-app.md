# 19 · FTXUI 综合实战：交互式待办管理器

> 对应示例：[examples/19_ftxui_app.cpp](../examples/19_ftxui_app.cpp)

## 19.1 状态模型与接线

14–18 的技术在此全部回收，做一个真用的东西：分类待办管理器——左侧分类 Menu，右侧任务 Checkbox 加删除，底部 Input 新增，Tab 切列表/统计双视图，清空前 Modal 确认，后台线程跑异步时钟。先看状态模型：

```cpp
// ═══ 19.1 业务状态：普通容器 + 普通标量，无一为 UI 而设 ═══
struct TodoItem { std::string text; bool done; };   // 避开 ftxui::Task（variant）

struct Category { std::string name; std::vector<TodoItem> tasks; };

...

std::vector<Category> cats = {
    { "工作", { { "写周报", false }, { "评审 PR", true } } },
    { "生活", { { "买牛奶", false } } },
    { "学习", { { "读 FTXUI 源码", false }, { "写小结", false } } },
};
int cat_sel = 0;
std::string input_text;
bool show_confirm = false;
int tab = 0;
```

这是教科书式的声明式建模：`vector<Category>` 加几个标量，组件通过指针接到这些变量上，整个 UI 是状态的投影。业务结构体起名 `TodoItem` 而不是 `Task`——`ftxui::Task` 已被 `Post` 通道占用（variant 类型），`using namespace ftxui` 之下撞名即歧义（坑位第 1 条）。

## 19.2 列表视图：任务行按数据重建

```cpp
// ═══ 19.2 任务行动态增删：DetachAllChildren + 按数据重建 ═══
auto task_row = Container::Vertical({});
auto refresh_rows = [&] {
    task_row->DetachAllChildren();
    for (size_t i = 0; i < tasks[cat_sel].tasks.size(); ++i)
    {
        auto& t = tasks[cat_sel].tasks[i];
        auto idx = i;
        auto row = Container::Horizontal({
            Checkbox(t.text, &t.done),
            Button("删", [&, idx] { tasks[cat_sel].tasks.erase(tasks[cat_sel].tasks.begin() + idx); }),
        });
        task_row->Add(row);
    }
};

...

// ═══ 19.3 菜单挂事件钩子：|= 原地装饰，return false 只观察 ═══
auto menu = Menu(&cat_names, &cat_sel);
menu |= CatchEvent([&](Event) { refresh_rows(); return false; });
```

两个细节值得驻足。其一，"增删控件"在声明式框架里就是"重建子树"：`DetachAllChildren` 清空容器，按当前数据重新 `Add`——删除按钮的 lambda 捕获的是**索引快照** `idx`（值捕获），vector 重排后旧按钮连同旧子树一起被丢弃，不存在悬空回调。其二，`menu |= CatchEvent(...)` 是组件版的原地装饰：给 Menu 挂一个事件观察钩子，`return false` 表示只看不拿——分类一变就刷新右侧任务行（与 15 章 CatchEvent 总闸的"吃掉"语义对照）。为演示从简，list_view 的 Renderer 里每帧也调一次 `refresh_rows()` 兜底同步（源码注释"演示从简"；量产做法是数据变更时才重建）。

## 19.3 底部输入与 Tab 双视图

```cpp
// ═══ 19.4 新增流：Input 文本 + Button 提交 ═══
auto input = Input(&input_text, "新任务…");
auto add_btn = Button("新增", [&] {
    if (!input_text.empty())
    {
        tasks[cat_sel].tasks.push_back({ input_text, false });
        input_text.clear();
        refresh_rows();
    }
});

...

// ═══ 19.5 空列表不硬凑：占位组件 + 三元选择 ═══
auto empty_hint = Renderer([] {
    return text("（空）按下方输入框新增任务") | dim | center;
});
auto list_body = cat.tasks.empty()
    ? empty_hint->Render()
    : task_row->Render();
```

列表视图的骨架是 `window(分类菜单) + separator + window(任务窗 + 底部输入行)` 的 hbox；空分类不硬凑空白——单参 `Renderer` 造一个 dim 居中的占位组件，按数据三元选择。统计视图把 14 章的 gauge 用回数据：每分类一行 `gauge(float(d) / std::max<size_t>(1, c.tasks.size()))`，除数 clamp 到至少 1 防 0/0（生活分类清空后显示 0/0）。两视图由 `Container::Tab` 切换，`tab` 仍是那个 int。

## 19.4 模态确认与事件总闸

```cpp
// ═══ 19.6 Modal 确认 + CatchEvent 一闸管四键 ═══
auto confirm = Renderer([] { return text("确认清空？(y/n)"); });
auto modal_box = Renderer(confirm, [=] {
    return confirm->Render() | border | color(Color::Red) | center;
});
auto app = Modal(main, modal_box, &show_confirm);

auto guarded = CatchEvent(app, [&](Event e) {
    if (e == Event::Character('q') || e == Event::Escape)
    { screen.Exit(); return true; }
    if (show_confirm && e == Event::Character('y'))
    { tasks[cat_sel].tasks.clear(); show_confirm = false; return true; }
    if (show_confirm && e == Event::Character('n'))
    { show_confirm = false; return true; }
    if (e == Event::Custom && selftest)
    { screen.Exit(); return true; }
    return false;
});
```

"清空当前分类"不直接执行——先置 `show_confirm = true` 让 18 章的 Modal 层接管（模态期间主界面收不到键），y 确认清空、n 取消。四种键全在一个最外层 CatchEvent 里分拣：q/Esc 退出、模态里的 y/n、selftest 的 `Event::Custom`——总闸模式贯穿 15–19。

## 19.5 异步时钟与无头自测

```cpp
// ═══ 19.7 时钟线程：计数值刻意不进输出 ═══
std::jthread clock_thread;
if (!selftest)
    clock_thread = std::jthread([&screen, &clock_ticks] {
        for (int i = 0; i < 100; ++i)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            screen.Post(Task{ Closure{ [&clock_ticks] { ++clock_ticks; } } });
        }
    });
```

交互模式跑一个 500ms 周期的时钟线程（18 章 `Post(Task{Closure})` 通路），标题栏"异步时钟运行中"是它存在的唯一提示——**计数值刻意不进画面**：帧内渲染时序数据会让两跑 stdout 必不一致（坑位第 2 条）。selftest 则完全不进终端循环：`Input` 的光标闪烁定时器会周期性触发整帧重绘，退出边界上"多一帧/少一帧"是时序竞态（坑位第 3 条）。改为无头驱动：手动喂 `guarded->OnEvent(Event::Character('y'))` 走完模态清空流，`add_btn->OnEvent(Event::Return)` 触发新增（Button 的触发键是 Return，坑位第 4 条），再对两个 tab 各拍一张 64 列快照——增删改查全链路的逻辑覆盖比盲跑 600 秒还完整。

## 19.6 运行与输出

构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 19_ftxui_app
```

selftest 实测输出（`build/docs-ref/19_ftxui_app.out`；剥行尾 CR 后原样引用）：

```text
==== 19 FTXUI 待办管理器 开始 ====
modal y 后生活分类任务数=0
新增后学习分类任务数=3
-- 统计视图快照 --
  列表   [统计] [2m（Tab 键切换；a 新增焦点在输入框）异步时钟运行中[22m
────────────────────────────────────────────────────────────────
╭──────────────────────────────────────────────────╮            
│工作    █████████████████████████              2/3│            
│生活                                           0/0│            
│学习                                           0/3│            
├──────────────────────────────────────────────────┤            
│总计: 2/6                                         │            
╰──────────────────────────────────────────────────╯            
退出；任务总数=6 已完成=2 分类数=3
==== 19 FTXUI 待办管理器 结束 ====
```

五行输出全部来自无头通路：第 2 行是模态流断言——cat_sel 切到"生活"、开确认、喂 'y'，任务数 1→0；第 3 行是新增流——切到"学习"、塞文本、喂 Return，任务数 2→3；第 4–13 行是统计视图快照（64 列栅格化，右侧尾随空格照留）："工作 2/3"的 gauge 按比例铺了三分之二格，"生活"清空后 0/0（除数 clamp 生效）、"学习"0/3，分隔线下总计 2/6；末行收尾核对。交互模式下的完整体验（菜单导航、双 Tab、拖拽输入、时钟走字）留给真实终端——selftest 只承诺逻辑正确。

至此 FTXUI 部分收束：14 章元素树打底，15 章组件与事件循环，16 章布局，17 章样式画布，18 章组合子——19 章一个应用全部回收。下一部分（20 章）换 tvision，看 1990 年 Borland IDE 风格的另一条 TUI 路线。

## 坑位清单

- **自定义业务结构别叫 Task**：`ftxui::Task` 是 `Post` 通道的 variant 类型，`using namespace ftxui` 下全局再定义 `Task` 即歧义编译错——本章数据结构因此得名 `TodoItem`（源码 19_ftxui_app.cpp 结构体行注释）。
- **帧内容不得依赖时序**：时钟计数若画进 UI，两跑 stdout 必漂移、build.ps1 的一致性判定必炸——异步线程可以跑，时序数据不进输出（源码【实测坑位】注释；提交 2472096）。
- **selftest 别进带 Input 的终端循环**：光标闪烁定时器周期性触发整帧重绘，退出边界"多一帧/少一帧"是竞态；无头驱动（手动 OnEvent + Render 快照）反而逻辑覆盖更完整（源码【实测坑位】注释；提交 2472096）。
- **无头触发 Button 要喂 `Event::Return`**：Button 的默认触发键是回车，喂字符或空格不会点按钮——`add_btn->OnEvent(Event::Return)` 才走回调（源码 selftest 段注释）。
- **`menu |= CatchEvent(...)` 与 `CatchEvent(menu, fn)` 是两种用法**：前者原地挂观察钩子（return false 只看不拿，事件继续正常路由），后者包新组件当闸（return true 吃掉）——本章两种都有实例（源码 menu 接线行与 guarded 总闸行）。

---

上一章：[18 · FTXUI 组合子代数与自定义组件](18-ftxui-composition.md) ｜ 下一章：[20 · tvision 应用骨架：桌面隐喻与事件循环](20-tv-hello.md) ｜ 返回：[README](../README.md)
