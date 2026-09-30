# 30 · GTK 综合实战：待办管理器

> 对应示例：[examples/30_gtk_app](../examples/30_gtk_app)

## 30.1 统一规格：第四份答卷

与 09（egui）、16（iced）、23（Slint）同一张考卷——六条共同规格（列表/
输入添加/勾选完成/删除/滚动列表/特色亮点）。GTK 的答卷拿出两样最能体现
retained 模式精髓的东西：**CSS 完成态**（.done 类划线 + 半透明，26 章
样式类的实战化）和 **Gio Action**（`<Ctrl>D` 清空，动作与快捷键的声明式
挂接）。31 章四框架并排时，这一份是"C 库 + GObject 属性系统"路线的代表。

## 30.2 模型：自定义 GObject 属性

29 章的子类化直接进阶——`#[derive(Properties)]` 让宏生成属性的 get/set/
notify 三件套，`TodoItem` 从此是个正经 GObject：

```rust
// ═══ 30.2 Properties derive：text/done 两个属性，宏管 get/set/notify ═══
#[derive(Properties, Default)]
#[properties(wrapper_type = super::TodoItem)]
pub struct TodoItem {
    #[property(name = "text", get, set)]
    pub text: RefCell<String>,
    #[property(name = "done", get, set)]
    pub done: RefCell<bool>,
}

#[glib::derived_properties]
impl ObjectImpl for TodoItem {}
```

模型容器用 `gio::ListStore`（注意 0.22 它**不带泛型**——`ListStore::new::<TodoItem>()`
的泛型在方法上，字段类型写裸 `ListStore`）。行由 `bind_model` 闭包制造，
行样式挂在 **item 的 notify::done** 上——属性变了行自动换装，这就是
"状态在模型"在样式层的延伸：

```rust
// ═══ 30.2 notify 驱动行样式：一个处理器同时刷划线与统计 ═══
item.connect_notify_local(Some("done"), move |it, _| {
    let done = it.downcast_ref::<TodoItem>().unwrap().done();
    apply_done_style(&label, done);              // .done 类开关（纯函数）
    Todos::refresh_stats_with(&stats, &store);
});
```

（`connect_notify` 的闭包要求 Send+Sync，`Label` 不是——UI 侧一律
`connect_notify_local`，与 25 章"两路信号"同一条纪律。）

## 30.3 特色亮点 A：CSS 完成态

```css
/* ═══ 30.3 .done 类：划线 + 半透明（26 章 .strike 的实战版）═══ */
.done { text-decoration: line-through; opacity: 0.55; }
```

样式开关抽成纯函数——"类挂没挂"是逻辑事实（无头断言），"渲成什么样"
归真窗口截图：实测截图里完成行灰字带删除线，三要素（勾选/灰/线）齐活。
GTK CSS 还支持 `transition` 做渐隐过渡，视觉层的效果交给真窗口体验。

## 30.4 特色亮点 B：Gio Action 与快捷键

动作是声明出来的对象：`SimpleAction::new("clear", None)` + `connect_activate`。
无头测试里 `action.activate(None)` 直接触发（不用跑 Application）：

```rust
// ═══ 30.4 动作机制无头直测 ═══
let clear = gtk::gio::SimpleAction::new("clear", None);
clear.connect_activate(move |_, _| {
    t.store.remove_all();
    Todos::refresh_stats_with(&t.stats, &t.store);
});
clear.activate(None);   // selftest：与用户按 <Ctrl>D 走同一条路

// 真窗口腿：挂到 Application 并绑快捷键（app 级命名空间）
app.add_action(&clear);
app.set_accels_for_action("app.clear", &["<Ctrl>D"]);
```

动作把"做什么"（handler）与"怎么触发"（按钮/菜单/快捷键/手势）解耦——
四种触发方式共享同一份代码，这是 GTK 桌面应用集成的标准姿势（菜单、
`accelerator` 都是它的下游）。

## 30.5 持久化：JSON 自己写

官方书的 GSettings/窗口状态方案在 Windows 是 **memory 后端不落盘**——
持久化直接 serde_json 落用户临时目录（对齐 16/23 的做法）：

```rust
// ═══ 30.5 平行 serde 结构 + 往返（GObject 不 derive serde）═══
let json = serde_json::to_string(&snap).unwrap_or_default();
std::fs::write(save_path(), json)          // temp/30_gtk_todo.json
// 读回：serde_json::from_str::<Snapshot> → 逐条 TodoItem::new 进 store
```

真窗口关闭时（`connect_close_request`）保存；再次启动 `load()` 恢复，
首次运行为空则种入两条样例。

## 30.6 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 30_gtk_app
```

实测输出（`build/30_gtk_app.run.out`）：

```text
==== 30 gtk 待办管理器 开始 ====
items=0 saved=50B roundtrip=1 action-clear=true style-done=ok
==== 30 gtk 待办管理器 结束 ====
```

数字对账：种 2 条 + 添加 1 条 − 删 1 条 = 3 → clear 动作清 0 → 再加 1 条
存盘 50 字节 → 读回 1 条文字与勾选态一致（roundtrip=1）。真窗口：
`待办 · 已完成 1/2` 统计、`新待办…` 输入、勾选行灰字划线、`Ctrl+D` 清空。

## 坑位清单

- **GSettings 在 Windows 是 memory 后端**：官方书第 7/8 章的 Settings/窗口状态方案在 Windows 不落盘（无 dconf）。持久化自己写 JSON——GObject 还不能 derive serde，平行快照结构是惯用解（23 章同款）。
- **`connect_notify` 要求闭包 Send+Sync**：捕获控件（Label 不是 Send）直接编译错——UI 侧用 `connect_notify_local`。选哪个版本看处理器要不要跨线程，跟 25 章 `emit`/`notify` 两路是同一门课。
- **`item()` 返回临时 owned Object**：`store.item(i).unwrap().downcast_ref::<TodoItem>()` 链到底再跨语句用会 E0716（引用悬在临时值上）。先 `let obj = ...` 绑定，或用 `downcast()`（owned）。
- **`gio::ListStore` 0.22 不带泛型**：字段写裸 `ListStore`，元素类型在 `ListStore::new::<TodoItem>()` 的方法泛型上；`find(&item)` 定位删除项（比手数下标稳）。
- **CSS 类开关要纯函数化**：划线逻辑抽 `apply_done_style(label, done)`，无头断言 `has_css_class("done")`（逻辑），渲染效果归截图层（视觉）——07 章"进树 ≠ 有字形"的样式版。

---

上一章：[29 · GTK 模板控件与异步](29-gtk-custom-async.md) ｜ 下一章：[31 · 四框架横评与选型](31-comparison.md) ｜ 返回：[README](../README.md)
