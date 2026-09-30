# 28 · GTK 模型与列表

> 对应示例：[examples/28_gtk_models](../examples/28_gtk_models)

## 28.1 状态在模型：GListModel 链

25 章的共享 Adjustment 是 GTK"状态与视图分离"的缩影，本章是它的完全体。列表
数据住在 **模型链**里，每层模型做一件事，视图只是链尾投影：

```rust
// ═══ 28.1 四层链：store → filter → sort → selection ═══
let store = gtk::StringList::new(CITIES);                    // 真相源
let filter = gtk::StringFilter::new(Some(expr.clone()));     // 子串过滤
let filter_model = gtk::FilterListModel::new(Some(store.clone()), Some(filter.clone()));
let sorter = gtk::StringSorter::new(Some(expr));             // collate 排序
let sort_model = gtk::SortListModel::new(Some(filter_model.clone()), None::<gtk::StringSorter>);
let selection = gtk::SingleSelection::new(Some(sort_model.clone())); // ListView 必须包
```

链上任何一层变化，下游与视图**自动**更新——增删只打真相源：

```rust
// ═══ 28.1 增删打 store，可见集合自动变 ═══
c.store.append("徐州");                       // store 8→9，可见 8→9
c.store.remove(0);                            // 删掉被过滤项，可见数不变
```

注意泛型形态的**两代并存**（0.11.5 实测）：新式构造器
（`FilterListModel/SortListModel/SingleSelection/ListView::new`）吃
`Option<impl IsA<..>>`——传**owned clone**；老式 `bind_model`/`set_sorter` 吃
`Option<&impl IsA<..>>`——传引用。传错形态就是一屏 `IsA not implemented
for &T`。

## 28.2 表达式：声明式取值

`PropertyExpression` 是"从某类对象取某属性"的声明——过滤器、排序器、标签
绑定共用同一个表达式，而且**不需要任何 UI 就能直接求值**（无头断言的中间层）：

```rust
// ═══ 28.2 表达式三用：过滤、排序、直接求值 ═══
let expr = gtk::PropertyExpression::new(
    gtk::StringObject::static_type(),
    None::<&gtk::PropertyExpression>,
    "string",
);
let v: String = expr.evaluate_as::<String, gtk::StringObject>(Some(&item)).unwrap();
assert_eq!(v, "北京");   // 零 UI 求值成功
```

## 28.3 两条视图路线

**ListBox + `bind_model`**——一行闭包造行，简单列表首选；**ListView +
`SignalListItemFactory`**——setup 造壳/bind 填数据两段式（可复用行、可上
表达式绑定，22 章同规格的 GTK 形态）：

```rust
// ═══ 28.3 factory 两段式：setup 造壳一次，bind 按条目反复 ═══
factory.connect_setup(|_, item| {
    let item = item.downcast_ref::<gtk::ListItem>().unwrap();
    let label = gtk::Label::new(None);
    item.set_child(Some(&label));
});
factory.connect_bind(move |_, item| {
    let item = item.downcast_ref::<gtk::ListItem>().unwrap();
    let so = item.item().unwrap().downcast::<gtk::StringObject>().unwrap();
    // ...label.set_text(&so.string()); log.push(text)
});
```

factory 的 **bind 由窗口 realize 驱动，纯无窗永远不触发**——这是 GTK 无头
测试最硬的一堵墙。解法是**隐形窗口**技巧：

```rust
// ═══ 28.3 隐形窗口：渲染上不可见，布局与 realize 照常发生 ═══
let ghost = gtk::Window::new();
ghost.set_child(Some(&row));      // 两个视图都装进去
ghost.set_opacity(0.0);           // 只影响渲染，不影响布局
ghost.present();
pump_until_binds(&c.bind_log, 3, &ghost);  // 条件排空（见下）
```

配合两个"查询接口"：`ListBox::row_at_index(i)`（行可枚举）与自建的
**bind 日志**（`Rc<RefCell<Vec<String>>>`，bind 一笔记一笔——GTK 没有遍历
ListView 已实现条目的公开 API）。条件排空替代 sleep：

```rust
// ═══ 28.3 pump_until：排空 + 推帧，直到条件满足（上限轮次兜底）═══
for _ in 0..100 {
    while ctx.pending() { ctx.iteration(false); }
    if log.borrow().len() >= want { return; }
    gtk::test_widget_wait_for_draw(win);   // 官方测试设施：推一帧
}
```

实测（本机 zh 环境）：过滤"州"+排序后，隐形窗口 realize 出的首行是**广州**
——`row_at_index(0)` 的文字与链尾第一项一致，双视图同源。

## 28.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 28_gtk_models
```

实测输出（`build/28_gtk_models.run.out`）：

```text
==== 28 gtk 模型与列表 开始 ====
expr=北京 filtered=杭州|广州|苏州 first_row=广州 store=8 selection=8
==== 28 gtk 模型与列表 结束 ====
```

`first_row=广州` 是 locale collation 的产物（同机稳定，跨机器可能不同——
所以断言只保证"是原集合的排列"，顺序交给同机重跑对账）。真窗口：左 ListBox
右 ListView 同源双视图，四个按钮（排序/过滤/加徐州/删第一项）实时联动。

## 坑位清单

- **factory bind 不开窗永不触发**：`connect_bind` 由 realize/allocate 驱动，纯模型断言测不到视图层。隐形窗口（opacity 0 + present + `test_widget_wait_for_draw` + 条件排空）是正解；`opacity(0.0)` 只关渲染、不关布局。
- **Option 泛型两代并存**：`ListView::new(Some(&selection), ..)` 编译报 `IsA<SelectionModel> is not implemented for &SingleSelection`——新式构造器要 owned（`Some(selection.clone())`），老式 `bind_model`/`set_sorter` 要引用。按报错方向换形态即可。
- **中文排序是 locale 的**：`StringSorter` 走 `g_utf8_collate`，顺序随系统 locale 变——断言写"排列等价"，别硬编码顺序（Rust 的 `str` 排序是码点序，与 collate 对不上）。
- **ListView 的 model 必须是 SelectionModel**：忘包 `SingleSelection` 编译期就拦住（类型即文档）；反过来看这也是设计——选择状态同样住模型里。
- **改 SortListModel 没有插入接口**：包装链是只读投影，增删只能打真相源 store——这正是"单向数据流"的 GTK 说法（对照 10 章 iced 的 model-update）。
- **`connect_bind` 收到的是 `&glib::Object`**：两跳 downcast（`ListItem` → `item().downcast::<StringObject>()`）才能读到字符串；漏一跳在运行时才炸。

---

上一章：[27 · GTK 自绘：cairo 进度环](27-gtk-drawing.md) ｜ 下一章：[29 · GTK 模板控件与异步](29-gtk-custom-async.md) ｜ 返回：[README](../README.md)
