# 21 · Slint 组件复用与 Rust 深度集成

> 对应示例：[examples/21_slint_components](../examples/21_slint_components)

## 21.1 自定义组件：属性即接口

Slint 的组件像函数——**属性是参数表，回调是返回口**：

```slint
// ═══ 21.1 LabeledCounter：一个自足的可复用组件 ═══
component LabeledCounter {
    in property <string> label;      // 进：只读配置
    in-out property <int> value: 0;  // 进+出：状态（实例各自持有！）
    in property <int> step: 1;       // 进：行为参数
    callback bump();                 // 出：事件
    callback reset();

    HorizontalLayout {
        spacing: 8px;
        Text { text: root.label + "：" + root.value; vertical-alignment: center; }
        Button { text: "+";    clicked => { root.value += root.step; root.bump(); } }
        Button { text: "清零"; clicked => { root.value = 0; root.reset(); } }
    }
}

// 复用 ×2：同一组件、不同配置、状态彼此独立
counter-a := LabeledCounter { label: "A"; step: 1;  bump => { root.bump-a(); } }
counter-b := LabeledCounter { label: "B"; step: 10; bump => { root.bump-b(); } }
```

两个实例各持各的 `value`——A 点两次是 2、B 点一次是 10，无头测试直接钉死这个独立性（见 21.4）。

## 21.2 接口面：生成代码只暴露根

生成的 Rust 类型只长在**根组件**上。嵌套实例的属性/回调要过两道桥：

```slint
// ═══ 21.2 两道桥：回调转发出去 + 属性镜像上来 ═══
export component CompLab inherits Window {
    callback bump-a();  bump-a  => { root.bump-a(); }   // 桥一：转发回调
    out property <int> value-a: counter-a.value;          // 桥二：绑定镜像值
    // ...
}
```

- **回调桥**：根声明同名回调，实例的 `bump =>` 里 `root.bump-a()`；Rust 侧 `on_bump_a` 就能收到；
- **值桥**：根的 `out property` 绑定嵌套实例属性——根的绑定**看得见**树内一切，`get_value_a()` 直接读。

这是 Slint 封装的常规税：想要 Rust 摸到的东西，都得升到根接口。换来的是组件内部的绝对私有。

## 21.3 invoke_from_event_loop：后台线程摸 UI 的正解

UI 只能在 UI 线程动——后台线程的标准姿势是 **weak 句柄 + invoke**：

```rust
// ═══ 21.3 心跳线程：400ms 一跳，共 5 跳 ═══
let weak = app.as_weak();
std::thread::spawn(move || {
    for _ in 0..5 {
        std::thread::sleep(std::time::Duration::from_millis(400));
        let weak = weak.clone();
        let _ = slint::invoke_from_event_loop(move || {
            if let Some(app) = weak.upgrade() {       // 窗口还活着才动
                app.set_ticks(app.get_ticks() + 1);
            }
        });
    }
});
```

三件套缺一不可：`as_weak()`（不延长组件寿命）、`upgrade()`（组件可能已销毁）、`invoke_from_event_loop`（排队到 UI 线程执行）。这是三框架"异步腿"的 Slint 版：egui 是 `ctx.request_repaint_from`（09 章）、iced 是 `Task::perform` 回消息（14 章）、Slint 是直接在 UI 线程跑闭包。

## 21.4 无头测试：按类型名抓实例

```rust
// ═══ 21.4 实例独立性的机器判定 ═══
use i_slint_backend_testing::ElementRoot;

let counters = app.root_element().query_descendants()
    .match_type_name(String::from("LabeledCounter")).find_all();
assert_eq!(counters.len(), 2);                    // 两个实例都在树里

let buttons = app.root_element().query_descendants()
    .match_type_name(String::from("Button")).find_all();
// DFS 序：A+ A清零 B+ B清零——用回调日志钉死顺序假设
click(&buttons[0]); click(&buttons[0]); click(&buttons[2]);

assert_eq!(app.get_value_a(), 2);                 // 两次 +1
assert_eq!(app.get_value_b(), 10);                // 一次 +10（step 配置生效）
```

`match_type_name("LabeledCounter")` 连**自定义组件**都能按名搜——类型系统就是查询系统。DFS 顺序假设由回调日志（`["a+", "a+", "b+"]`）双重验证：假设错了测试会红。

## 21.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 21_slint_components
```

实测输出（`build/21_slint_components.run.out`）：

```text
==== 21 slint 组件与集成 开始 ====
value-a=2 value-b=10（同组件不同配置，状态独立）
callback log = ["a+", "a+", "b+"]
==== 21 slint 组件与集成 结束 ====
```

真窗口里看两个计数器独立行走；启动后 400ms 一次的"后台心跳"从 0 爬到 5（invoke_from_event_loop 在工作）。

## 坑位清单

- **invoke_from_event_loop 无头走不通**：`init_no_event_loop` 的 `threading: false`——没有事件循环可排队。跨线程路径留给真窗口；无头测可测的部分（组件独立性、回调链）用 21.4 的办法。
- **嵌套接口必须过桥**：Rust 摸不到 `counter-a.value`——回调转发 + out 属性镜像两道桥先架好。忘了架桥的迹象：生成代码里没有对应 get_/on_。
- **match_type_name 连自定义组件都能搜**：这不只是测试技巧——LSP 预览/调试也吃同一套查询。
- **DFS 序是假设不是合同**：`find_all` 的顺序当前是深度优先，但别裸信——像本例一样用回调日志或几何位置钉死你的顺序假设。
- **闭包里 upgrade 失败要静默**：组件销毁后 invoke 仍会执行（排队时还在），`if let Some` 分支就是它的全部体面。

---

上一章：[20 · Slint 状态动画与声明式自绘](20-slint-animations.md) ｜ 下一章：[22 · Slint 模型与 ListView](22-slint-models.md) ｜ 返回：[README](../README.md)
