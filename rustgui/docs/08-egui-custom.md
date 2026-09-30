# 08 · egui 自定义控件、动画辅助与持久化

> 对应示例：[examples/08_egui_custom](../examples/08_egui_custom)

## 8.1 自定义控件 = impl Widget

egui 的控件不是神秘黑盒——`Button`/`Slider` 自己就是 `impl Widget`。写一个 iOS 风格拨动开关，走完**布局、交互、动画、绘制、无障碍**五步：

```rust
// ═══ 8.1 ToggleSwitch：五步走完一个自定义控件 ═══
struct ToggleSwitch {
    on: bool,
    label: &'static str, // 无障碍标签——见 8.2 的坑
}

impl egui::Widget for ToggleSwitch {
    fn ui(self, ui: &mut egui::Ui) -> egui::Response {
        // 1) 布局：要一块 2:1 的矩形
        let height = ui.spacing().interact_size.y;
        let (rect, mut response) =
            ui.allocate_exact_size(egui::vec2(2.0 * height, height), egui::Sense::click());

        // 2) 交互：点击即报告 changed（状态仍归调用方！）
        if response.clicked() {
            response.mark_changed();
        }

        // 3) 动画：布尔缓动，egui 自动预约重绘
        let how_on = ui.ctx().animate_bool_with_time(response.id, self.on, 0.15);

        // 4) 绘制：底板圆角矩形 + 滑块圆
        //    （颜色手工插值——Color32 没有现成的 lerp_rgb）
        // 5) 无障碍：widget_info 报户口
        response.widget_info(|| {
            egui::WidgetInfo::selected(egui::WidgetType::Checkbox, ui.is_enabled(), self.on, self.label)
        });
        response
    }
}
```

调用方与控件的**状态契约**是即时模式的核心惯例：

```rust
let sw = ui.add(ToggleSwitch { on: app.state.lamp, label: "台灯开关" });
if sw.changed() {
    app.state.lamp = !app.state.lamp; // 控件只报告，翻转由我做
}
```

控件自己**不存状态**（`on` 是调用方借给它的一帧投影），`Response::changed()` 表示"用户表达了意图"。这与 03 章 `ui.button().clicked()` 完全同构——你现在能自己写 Button 了。

## 8.2 无障碍不是可选项

kittest 的 accessibility check **默认开启**：每个输入控件必须有可访问名，否则测试 panic。这不是 kittest 苛刻——读屏用户（NVDA/VoiceOver）靠这个名字才知道控件是什么。给自绘控件"报户口"用 `Response::widget_info`：

```rust
// 0.36.2 的类型是 egui::WidgetType（github master 已改 Role，未发布——别照 master 抄）
response.widget_info(|| {
    egui::WidgetInfo::selected(egui::WidgetType::Checkbox, ui.is_enabled(), self.on, self.label)
});
```

副作用红利：报了户口的控件**可以被 `get_by_label` 直接点名点击**——无障碍树就是我们的测试接口，可访问性和可测试性是同一件事。

## 8.3 动画辅助函数

| 函数 | 用途 |
|---|---|
| `ctx.animate_bool_with_time(id, target, 秒)` | 布尔过渡（0→1 缓动），本例滑块滑移 |
| `ctx.animate_value_with_time(id, target, 秒)` | 数值过渡（颜色/位置/透明度） |
| `ctx.animate_bool(id, target)` | 同上，用默认时长 |

它们按 `id` 记住动画进度、自动预约重绘，比 05 章的手工帧步进省事；代价是进度跟真实时间走——**kittest 里动画时长被置 0（瞬时到位）**，正好让断言确定。所以选择原则：交互反馈动画用辅助函数，业务进度（如进度环）用帧步进。

## 8.4 持久化：eframe 的 save 挂钩

开 `eframe` 的 `persistence` feature 后，退出（和每 30 秒）自动调用 `App::save`，把状态写进 app 数据目录；启动时从 `cc.storage` 恢复：

```rust
// ═══ 8.4 存/读一对挂钩 ═══
impl eframe::App for CustomApp {
    fn save(&mut self, storage: &mut dyn eframe::Storage) {
        storage.set_string(STORAGE_KEY,
            serde_json::to_string(&self.state).unwrap_or_default());
    }
    // ...
}

impl CustomApp {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let state = cc.storage                     // persistence 开启时才有
            .and_then(|s| s.get_string(STORAGE_KEY))
            .and_then(|json| serde_json::from_str(&json).ok())
            .unwrap_or_default();
        Self { state }
    }
}
```

egui 自己的窗口位置/面板宽度/展开状态也由 persistence 记住（挂在 `app_name` 下）——04 章拖过的侧栏宽度、03 章开过的浮动窗口，重开都在。

## 8.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 08_egui_custom
```

实测输出（`build/08_egui_custom.run.out`）：

```text
==== 08 egui 自定义控件 开始 ====
lamp=true clicks=1 roundtrip=true
==== 08 egui 自定义控件 结束 ====
```

`roundtrip=true`：状态 → JSON → 状态 的序列化往返一致（持久化的单元级证据）。真窗口里拨两下开关、关掉程序再开——clicks 还在。

## 坑位清单

- **空标签输入控件过不了 accessibility check**：kittest 默认查"每个输入控件有可访问名"。icon-only 按钮/空标签复选框必须补 `on_hover_text`、`accessible_name` 或 `widget_info`，否则测试 panic。
- **WidgetType ≠ Role**：0.36.2 的 `WidgetInfo::selected` 吃 `egui::WidgetType`；github master 已改成 `Role` 但未发布。报"expected WidgetType, found Role"就是抄了 master 的代码。
- **`Color32::lerp_rgb` 不存在**：颜色插值自己算三个分量，或用 `egui::Rgba` 转一手。
- **mpsc::Receiver 不能 Clone**：含通道的结构体别 derive Clone——给 selftest 单做一个 `snapshot()`（只装可 Clone 的字段），09 章就是这个模式。
- **persistence 只在真窗口生效**：kittest 的 `build_eframe` 给的 `cc.storage` 是 None——持久化路径无法无头验证，退而验证序列化往返（本例 `roundtrip` 断言）。
- **真窗口豆腐块：无头测试的字形盲区（本例真实踩过）**：0.36.2 没有系统字体回退，UI 用中文却没注册字体时，`cargo test`/`--selftest` 全绿（kittest 从不光栅化），真窗口里满屏 ◻。修法：`CustomApp::new` 里 `install_cjk_font`（07 章方案）。`tools/gui-shots.ps1` 逐例真窗口截图，这类问题才现形。

---

上一章：[07 · egui 中文字体与主题样式](07-egui-fonts.md) ｜ 下一章：[09 · egui 综合实战：待办管理器](09-egui-app.md) ｜ 返回：[README](../README.md)
