# 25 · GTK 控件、信号与 Builder

> 对应示例：[examples/25_gtk_widgets_signals](../examples/25_gtk_widgets_signals)

## 25.1 控件全集：一张报名表单

本章与 11 章（iced 报名表单）同题对照：Entry 输入姓名、DropDown 选城市、
CheckButton 订阅、Switch 开关、Scale/SpinButton 调人数、ProgressBar 显示进度。
GTK 的控件构造有两套等价路数——**builder 链式**（`gtk::Entry::builder()
.placeholder_text("姓名").build()`）和 **Builder XML**；本章主用 XML，
因为它是 GTK 生态的通用语（Glade/Blueprint 编辑器、libadwaita 文档全用它）：

```xml
<!-- ═══ 25.1 ui/form.ui：界面即数据（属性名一律 kebab-case）═══ -->
<object class="GtkEntry" id="name-entry">
  <property name="placeholder-text">姓名</property>
</object>
<object class="GtkDropDown" id="city-dropdown"/>
<object class="GtkCheckButton" id="subscribe-check">
  <property name="label">订阅通知</property>
</object>
```

XML 经 `include_str!` 进二进制，运行时解析——不引入 gresource 编译步骤
（`glib-compile-resources.exe` 是进阶话题，教程保持零资源化）：

```rust
// ═══ 25.1 Builder 加载：一次加载连窗口一起交出 ═══
fn load() -> (Self, gtk::ApplicationWindow) {
    let b = gtk::Builder::from_string(include_str!("../ui/form.ui"));
    let get = |id: &str| -> glib::Object {
        b.object::<glib::Object>(id).unwrap_or_else(|| panic!("XML 里没有 id={id}"))
    };
    // get("name-entry").downcast::<gtk::Entry>().unwrap() ...
}
```

## 25.2 信号三范式

GTK 的事件通知有三个层次，本章各用一次：

| 层次 | 写法 | 何时触发 |
|---|---|---|
| 动作信号 | `connect_clicked` / `connect_toggled` / `connect_activate` | 用户交互 |
| 属性变更 | `connect_active_notify` / `connect_selected_notify` | 属性被改（GObject **保证**必发） |
| 声明式绑定 | `bind_property("value", &bar, "fraction")` | 源属性变化自动搬运 |

关键坑：**`set_active(true)` 不保证发 `toggled`**（那是用户点击的信号），但
**一定发 `notify::active`**——GObject 的属性通知是机制级保证。所以处理器一律
写成**幂等的绝对赋值**（每次重算整行汇总），用户路径与程序路径就都收敛：

```rust
// ═══ 25.2 幂等处理器：两路触发、同一状态 ═══
let f = self.clone();
self.check.connect_toggled(move |_| f.refresh());        // 用户点击
let f = self.clone();
self.check.connect_active_notify(move |_| f.refresh());  // 程序赋值
```

`connect_state_set` 是 Switch 特有的"可拦截"信号——返回
`glib::Propagation::Stop` 能否决这次翻转（确认弹窗的经典实现），本章不展开。

## 25.3 状态在模型：共享 Adjustment

Scale 和 SpinButton 各自都能显示一个数，但 GTK 的正解不是"谁改谁通知"，而是
**两个控件共享同一个 `Adjustment` 模型**——动滑块，数字框跟着动，反之亦然，
一行通知代码都不用写：

```rust
// ═══ 25.3 Adjustment：数值状态住在模型里，控件只是投影 ═══
let adj = gtk::Adjustment::new(0.0, 0.0, 100.0, 1.0, 10.0, 0.0);
//            value  lower upper  step  page  page_size
self.scale.set_adjustment(&adj);
self.spin.set_adjustment(&adj);

// 进度条不需要共享模型，用声明式绑定 + 换算（0..100 → 0..1）
self.adj
    .bind_property("value", &self.bar, "fraction")
    .transform_to(|_, v: &glib::Value| Some((v.get::<f64>().unwrap() / 100.0).to_value()))
    .sync_create()   // 建绑定时立即同步一次初值
    .build();
```

这是 GTK「模型/视图分离」的第一课——28 章的 GListModel/ListView 是它的完全体。

## 25.4 无头剧本：程序赋值与用户路径

```rust
// ═══ 25.4 填表全流程：set_* 驱动 → 排空 → 断言真相源 ═══
f.entry.set_text("李雷");          // EditableExt（不在 EntryExt！）
f.entry.emit_activate();           // 与按回车等价的"用户路径"
f.dropdown.set_selected(1);        // 上海
f.check.set_active(true);
f.dark_switch.set_active(true);
f.adj.set_value(55.0);             // 模型驱动：滑块/数字框/进度条三处同步
// 排空 → 断言 state_text() == "姓名：李雷 ｜ 城市：上海 ｜ 订阅：是 ｜ 深色：开 ｜ 人数：55"
```

断言打在**真相源**（`state_text()` 直读全部属性）而不是显示标签上，再用
`summary` 标签的 text 断言验证 notify 处理器确实把显示刷到位——两级断言，
状态与显示分开验。最后 `submit.emit_clicked()` 再走一遍，断言汇总不变
（幂等性本身的回归测试）。

## 25.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 25_gtk_widgets_signals
```

实测输出（`build/25_gtk_widgets_signals.run.out`）：

```text
==== 25 gtk 控件与信号 开始 ====
summary="姓名：李雷 ｜ 城市：上海 ｜ 订阅：是 ｜ 深色：开 ｜ 人数：55"
==== 25 gtk 控件与信号 结束 ====
```

真窗口（`cargo run`）：姓名占位、城市下拉默认北京、订阅复选框、深色开关、
滑块 0、数字框 0、进度条 0%、汇总"未提交"、"提交"按钮——真窗口截图逐项核对
一致（`build/gui-shots/25_gtk_widgets_signals.png`，448×485）。

## 坑位清单

- **Entry 的 `set_text`/`text` 在 `EditableExt` 不在 `EntryExt`**：prelude 都导出所以编译不炸，但按 C 名 `gtk_entry_set_text` 查文档会扑空（GTK4 把 Entry 拆成 Editable 接口承载文本）。
- **`CheckButton` 的 getter 是 `is_active()`**：写成 `.active()` 会撞 ComboBox 系同名方法的 E0599，报错提示还引导人去看 `IsA<ComboBox>`——别被带偏。
- **`set_active` 不保证发 `toggled`，但必发 `notify::active`**：处理器写成幂等绝对赋值，用户点击（toggled）与程序赋值（notify）两条路都稳；写成增量累加就会漏计/双计。
- **`builder.object::<T>("id")` 类型不符返回 `None` 不 panic**：静默 `unwrap` 或漏检，错误推迟到运行时深处。一律 `expect` 且带上 id 名，XML 改名时第一时间炸出来。
- **`transform_to` 闭包参数要显式标注**：`|_, v: &glib::Value|`——泛型推断在这里断链，裸 `|_, v|` 报 E0282。
- **XML 属性名是 kebab-case**：`placeholder-text`/`default-width`，写成 camelCase 不报错、静默不生效。

---

上一章：[24 · GTK4 最小应用](24-gtk-hello.md) ｜ 下一章：[26 · GTK 布局与 CSS](26-gtk-layout-css.md) ｜ 返回：[README](../README.md)
