# 18 · FTXUI 组合子代数与自定义组件

> 对应示例：[examples/18_ftxui_composition.cpp](../examples/18_ftxui_composition.cpp)

## 18.1 组合子代数：把组件当值来算

到这里 FTXUI 的三层已齐：Element 管"某一帧长什么样"（14 章）、内置组件管"常见交互"（15 章）、布局管"怎么摆"（16–17 章）。本章是第四层：**组合子（combinator）**——不新造控件，用小函数把已有组件包装、聚合、删改出新的。`Component` 是 `shared_ptr<ComponentBase>`，是货真价实的值：能存进变量、塞进容器、当参数传、被装饰器层层包裹。

本章用到的组合清单：`Renderer(child, fn)` 换外观保交互、`Container::{Vertical,Horizontal,Tab}` 聚合加焦点导航、`Maybe` 条件渲染、`Modal` 模态层、`CatchEvent` 事件拦截、`Make<T>` 自定义组件工厂——外加继承 `ComponentBase` 手写组件的完整范式。

## 18.2 Renderer 双参：换壳不换芯

```cpp
// ═══ 18.1 fn 里嵌入 child->Render()，子组件才可见 ═══
auto tab0 = Renderer(buttons, [&] {
    return vbox({
        text("计数: " + std::to_string(count)),
        buttons->Render(),                // 保留交互性的"嵌入"
    }) | border;
});
```

15 章的回显面板故意不画 child；这里补上正写法：fn 里调 `buttons->Render()`，把子组件的**当前帧**嵌进自己的 Element 树。外观完全重排（加了计数行与边框），事件与焦点仍路由进 buttons——回车照样点按钮。这就是"换壳不换芯"：Renderer 负责"长什么样"，child 负责"能干什么"，两者正交组合。

## 18.3 Container::Tab 与 Maybe：切页与条件渲染

```cpp
// ═══ 18.2 Tab：一个 int 索引切换整页 ═══
auto tabs = Container::Tab({ tab0, tab1 }, &tab);
// Maybe(组件, 条件函数)：条件为真才渲染/参与交互
auto maybe_child = Renderer([] { return text("计数超过 3，Maybe 才渲染我") | bold | border; });
auto maybe_demo = Maybe(maybe_child, [&] { return count > 3; });
```

`Tab(组件向量, &int)` 在同一矩形里按索引二选一：`tab` 这个 int 就是全部状态，左右键改索引即换页——比 wx 的 Notebook 轻一个量级。`Maybe(child, 谓词)` 是**参数序敏感**的组合子：组件在前、谓词在后（坑位第 2 条）；条件为假时 child 不渲染，**也不进焦点环、不收事件**——渲染与交互性同生同灭，比"画不画"更彻底。

## 18.4 Modal：模态层

```cpp
// ═══ 18.3 Modal(主, 模态, &bool)：bool 为真时模态接管 ═══
auto modal_box = Renderer([] {
    return vbox({ text("模态框（按 h 开关）"), text("Esc/q 仍走外层退出") })
         | border | color(Color::Yellow);
});
auto app_comp = Modal(renderer, modal_box, &show_modal);
```

`Modal` 三参（坑位第 3 条）：主组件、模态组件、开关 bool 的指针。bool 为真时模态层叠在最上方（16 章 dbox 的语义），且**事件被模态层先吃**——主界面收不到键，直到 bool 关闭。业务键在模态里处理，Esc/q 这类总闸放更外层的 CatchEvent（15 章模式）——职责分明。19 章的"确认清空"就是这个骨架的实战版。

## 18.5 自定义组件：方向键移动的 @

```cpp
// ═══ 18.4 继承 ComponentBase：OnRender/OnEvent/Focusable 三件套 ═══
class MoverComponent : public ComponentBase
{
public:
    explicit MoverComponent(int w, int h) : m_w(w), m_h(h) {}

    Element OnRender() override
    {
        Elements map;
        for (int y = 0; y < m_h; ++y)
        {
            std::string row(m_w, '.');
            if (y == m_y) row[m_x] = '@';
            map.push_back(text(row));
        }
        return vbox(std::move(map)) | border;
    }

    bool OnEvent(Event e) override
    {
        if (e == Event::ArrowLeft)  { m_x = (m_x + m_w - 1) % m_w; return true; }
        if (e == Event::ArrowRight) { m_x = (m_x + 1) % m_w; return true; }
        if (e == Event::ArrowUp)    { m_y = (m_y + m_h - 1) % m_h; return true; }
        if (e == Event::ArrowDown)  { m_y = (m_y + 1) % m_h; return true; }
        return false;                      // 没吃掉 → 继续冒泡
    }

    bool Focusable() const override { return true; }
    ...
};
...
auto mover = Make<MoverComponent>(16, 5);          // 自定义组件
```

自定义组件就是继承 `ComponentBase` 手写三件套：`OnRender()` 出帧——注意虚函数名是 **OnRender** 不是 Render，后者是非虚的公共入口、内部调 OnRender（坑位第 1 条）；`OnEvent()` 吃键，返回 true 吃掉、false 冒泡；`Focusable()` 声明可聚焦，返回 false 连 Tab 环都进不去。状态 `m_x/m_y` 是普通成员——组件**可以**有状态，只是本教程风格尽量外置（对照 19 章：数据全在 main 的容器里）。环绕取模 `(m_x + m_w - 1) % m_w` 让 @ 从左边界绕到右边界。`Make<T>(args...)` 是官方工厂，等价 `make_shared` 再装箱。

## 18.6 异步：Post(Task{Closure}) 与无头自测

```cpp
// ═══ 18.5 Post(Task{Closure})：跨线程安全改 UI 状态 ═══
std::jthread worker([&screen] {
    for (int i = 0; i < 20; ++i)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        screen.Post(Task{ Closure{ [] { /* 主循环里安全改状态 */ } } });
    }
});
```

master 用 `Task` variant（内含 `Closure` 等形态）取代了旧的 `Sender/Receiver` 通道模型：后台线程 `screen.Post(Task{Closure{...}})` 把闭包投回主循环，闭包在**主循环线程**里执行——UI 状态永远只在循环线程被改，无锁亦无竞态（坑位第 4 条）。

selftest 不进终端循环，改**无头驱动**：直接 `mover->OnEvent(Event::ArrowRight)` 喂合成事件，再 `app_comp->Render()` 取 Element 渲染成字符串快照——事件逻辑真跑、输出确定（终端循环通路已由 15 章实证），这套手法 19 章继续加码。

## 18.7 运行与输出

构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 18_ftxui_composition
```

selftest 实测输出（`build/docs-ref/18_ftxui_composition.out`；剥行尾 CR 后原样引用）：

```text
==== 18 FTXUI 组合子与自定义组件 开始 ====
mover: (2,1) -> (2,2)（右+下+左 网络位移 = 下移一格）
-- Tab2 渲染快照（mover 页）--
 Tab1 [Tab2][2m  (左右键切 tab)[22m                
╭──────────────────────────────────────────╮
│方向键移动 @（自定义组件）                │
│╭────────────────────────────────────────╮│
││................                        ││
││................                        ││
││..@.............                        ││
││................                        ││
││................                        ││
│╰────────────────────────────────────────╯│
╰──────────────────────────────────────────╯
[2mq/Esc 退出                                  [22m
count=4 时 Maybe 分支出现：
╭──────────────────────────────────────────╮
│[1m计数超过 3，Maybe 才渲染我                [22m│
╰──────────────────────────────────────────╯
==== 18 FTXUI 组合子与自定义组件 结束 ====
```

输出三段全是无头驱动的产物：第 1 行是 MoverComponent 的位移断言——右、下、左三个合成事件的合成位移等于下移一格，`(2,1) -> (2,2)`，事件真的走了 `OnEvent` 逻辑；第 2 段是 Tab 切到 tab=1 后整棵组件树的渲染快照：标题行 `Tab1 [Tab2]` 高亮第二页、`dim` 提示的 `\x1b[2m...\x1b[22m`、双层 border 套着 16×5 的点阵、`@` 停在第 3 行第 3 列（坐标 (2,2)）——自定义组件的 Render 输出与内置组件无差别混排；第 3 段验证 Maybe：count 置 4 后条件分支出现（bold 转义包着文本框），count 归零后它连同交互性一起消失。

## 坑位清单

- **ComponentBase 的渲染虚函数叫 OnRender() 不是 Render()**：`Render()` 是非虚公共入口、内部调 OnRender——override Render 要么编不过、要么根本不被走；同族虚接口是 OnEvent/Focusable（源码 18_ftxui_composition.cpp【坑】注释；提交 2472096）。
- **Maybe 参数序：组件在前、谓词在后**：`Maybe(child, [&]{ return cond; })`——写反了类型不匹配，模板报错还相当难读（提交 2472096 实测收录）。
- **Modal 是三参签名**：`Modal(主组件, 模态组件, &bool)`——模态开关必须是你持有的 bool 指针，没有旧式的两参形态（提交 2472096 实测收录）。
- **跨线程改 UI 状态的正道是 `Post(Task{Closure})`**：master 已用 Task variant 取代 Sender/Receiver 通道；从 worker 线程直接改共享变量没有同步屏障，是数据竞态（源码头注释；提交 2472096）。

---

上一章：[17 · FTXUI 样式系统与 Canvas 画布](17-ftxui-style-canvas.md) ｜ 下一章：[19 · FTXUI 综合实战：交互式待办管理器](19-ftxui-app.md) ｜ 返回：[README](../README.md)
