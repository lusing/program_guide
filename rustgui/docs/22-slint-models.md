# 22 · Slint 模型与 ListView

> 对应示例：[examples/22_slint_models](../examples/22_slint_models)

## 22.1 模型：数据的家在 Rust

前几章的属性是单值；列表数据用**模型**——`VecModel<T>` 住在 Rust 侧，包成 `ModelRc` 塞给属性：

```rust
// ═══ 22.1 三步接线 ═══
let model = std::rc::Rc::new(VecModel::from(vec![
    Item { name: "第一条".into(), done: false },
    Item { name: "第二条".into(), done: true },
]));
app.set_items(ModelRc::from(model.clone()));  // ① 界面拿到的只是句柄

model.push(Item { name: "第三条".into(), done: false });  // ② 直改即通知
assert_eq!(app.get_item_count(), 3); // ③ 绑定立即反映——没有"刷新列表"
```

要点：

- `struct Item { name: string, done: bool }` 在 .slint 里声明并 `export`——Rust 侧生成同名结构体（`SharedString`/`bool` 字段）；
- **改模型 = 更新界面**：`push/remove/set_row_data` 发模型通知，界面增量更新对应行——"手动刷新"这个概念在 Slint 里不存在；
- `set_row_data(i, 新值)` 才是"改一行"的正道（取出→改→放回）；`.iter()` 可遍历读。

```slint
// ═══ 22.2 .slint 侧：模型属性 + for-in 渲染 ═══
in-out property <[Item]> items;                 // 模型属性：<[T]>
out property <int> item-count: root.items.length; // length 聚合内建

ListView {
    for item[i] in root.items: Rectangle {       // i 是行号（回调载荷）
        height: 44px;
        // item.name / item.done——每行拿到自己的数据
    }
}
```

## 22.2 ListView vs 普通 for：虚拟化的第三种形态

| | egui（06） | iced（12） | Slint ListView（本章） |
|---|---|---|---|
| 渲染模型 | TableBuilder 虚拟化行 | scrollable 急切布局 | **行模板复用**（视口外行连实例都不建） |
| 视口外 | 不进树 | 进树但被裁剪 | 不实例化（组件复用） |
| 行身份 | row.index() | 树中的候选 | `for item[i]` 的 i |

Slint 的 ListView 是真·虚拟化：模板只有视口内那么几份实例，滚动时**复用**并换数据。这带来一个测试语义：模型里有几条 ≠ 树里有几行（本例 3 条全可见所以 3 个删按钮都在；100 条就只有视口内那几行可点）。

## 22.3 行交互：索引回调 + 无障碍标签定位

```slint
// ═══ 22.3 行的两种出口：toggle(i) 与 remove(i) ═══
TouchArea {
    clicked => { root.toggle(i); }   // 点行切换完成
    Text { text: item.name; }
}
Button {
    text: "删";
    clicked => { root.remove(i); }   // 按钮带行号
}
```

```rust
// ═══ 22.4 Rust 半边 + 测试定位 ═══
app.on_toggle(move |i| {
    if let Some(mut it) = model.row_data(i as usize) {
        it.done = !it.done;
        model.set_row_data(i as usize, it);
    }
});

// 测试：按可访问标签找行文本（Text 的 label 就是内容），几何推导点击
let row_text = ElementHandle::find_by_accessible_label(&app, "第一条")
    .next().expect("行文本应可按标签找到");
let rp = row_text.absolute_position();
send_mouse_click(rp.x + 10.0, rp.y + 5.0);

// 删按钮：类型名查询 + 标签过滤
let dels = app.root_element().query_descendants()
    .match_type_name(String::from("Button")).find_all()
    .into_iter().filter(|b| b.accessible_label().as_deref() == Some("删"))
    .collect::<Vec<_>>();
```

模型即真相：点击后直接读 `model.row_data(0)` 断言 `done` 翻转——不依赖任何渲染细节。

## 22.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 22_slint_models
```

实测输出（`build/22_slint_models.run.out`）：

```text
==== 22 slint 模型与列表 开始 ====
final count=2 row0_was_toggled=true
==== 22 slint 模型与列表 结束 ====
```

真窗口里点"加一条"看列表增长（模型通知驱动）、点行看颜色切换、点"删"看行消失。

## 坑位清单

- **`%` 是单位不是取模**：斑马纹条件 `i % 2` 直接编译错（"Unexpected '%'"）——`Math.mod(i, 2)` 才对。% 后缀留给 `50%` 这种相对量。
- **ListView 要从 std-widgets 导入**：`import { ListView } from "std-widgets.slint";`——它不是内建元素。
- **`set_row_data` 别忘**：`row_data(i)` 拿到的是**副本**，改完必须放回去才有通知；只改本地副本界面纹丝不动。
- **selftest 记得接回调**：模型在测试里建好了，但 `on_toggle/on_remove` 没挂的话点击就是空操作（本例实测踩中）——测试路径要与 main 同款接线。
- **虚拟化下"每行一个"的断言要小心**：视口外的行不在树里，`find_all` 的数量是"可见行数"不是"模型条数"；数据侧断言用 `model.iter().count()`。

---

上一章：[21 · Slint 组件复用与 Rust 深度集成](21-slint-components.md) ｜ 下一章：[23 · Slint 综合实战：待办管理器](23-slint-app.md) ｜ 返回：[README](../README.md)
