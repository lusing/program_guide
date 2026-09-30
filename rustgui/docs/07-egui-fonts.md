# 07 · egui 中文字体与主题样式

> 对应示例：[examples/07_egui_fonts](../examples/07_egui_fonts)

## 7.1 为什么前五章不敢用中文

egui 内置字体只有拉丁 + 少量符号，**没有 CJK 字形**。真窗口里 eframe 的 `system_font_fallback`（`NativeOptions` 默认开）会在运行时借用系统字体兜底，中文能显示；但 **kittest 无头通道没有这层兜底**——默认 `MissingGlyphPolicy::Panic` 在文本整形阶段遇到缺字形直接 panic。所以 02–06 章的 UI 文本全部 ASCII，本章把字体问题正面解决掉，之后各章放开中文。

两条路线：

| 路线 | 做法 | 适用 |
|---|---|---|
| 运行时加载系统字体（本例） | `std::fs::read` 系统字体 → `FontDefinitions` 换血 | 教程/工具：零字节入库、无许可问题、跨三平台 |
| 打包字体文件 | `include_bytes!("NotoSansSC-Regular.otf")` | 产品发布：字体随二进制走，绝对可控（OFL 等宽松许可） |

```rust
// ═══ 7.1 运行时找一枚系统中文字体 ═══
const CJK_CANDIDATES: &[&str] = &[
    "C:\\Windows\\Fonts\\simhei.ttf",     // Windows 黑体
    "C:\\Windows\\Fonts\\msyh.ttc",       // Windows 微软雅黑
    "/System/Library/Fonts/PingFang.ttc", // macOS
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", // Linux
];

fn load_cjk_font() -> Option<(&'static str, Vec<u8>)> {
    for path in CJK_CANDIDATES {
        if let Ok(bytes) = std::fs::read(path) {
            return Some((path.rsplit(['/', '\\']).next().unwrap_or(path), bytes));
        }
    }
    None
}
```

## 7.2 FontDefinitions 换血

0.36 的 `FontDefinitions` 就是两个 map，没有便捷的 `insert` 方法——直接操作：

```rust
// ═══ 7.2 注册到 Context（在 App::new 里做一次）═══
let mut fonts = egui::FontDefinitions::default();
// 注意 font_data 的值是 Arc<FontData>！
fonts.font_data
    .insert("cjk".into(), std::sync::Arc::new(egui::FontData::from_owned(bytes)));
// 插到 Proportional 家族队首 = 最高优先级，原拉丁字体垫后做回退
fonts.families
    .entry(egui::FontFamily::Proportional)
    .or_default()
    .insert(0, "cjk".into());
// 等宽家族追加在尾部（中文代码注释场景）
fonts.families
    .entry(egui::FontFamily::Monospace)
    .or_default()
    .push("cjk".into());
cc.egui_ctx.set_fonts(fonts);
```

要点：`font_data: BTreeMap<String, Arc<FontData>>` 的值是 **`Arc`**（旧教程写 `FontData` 裸值已过时）；`families` 里字体名是**优先级队列**——排前面的先被用，缺字形再往后找。所以 `insert(0, …)` 让中文优先、拉丁回退，两全。

## 7.3 主题与样式：Visuals 与 Style

主题 = `Visuals`（亮/暗、控件配色）+ `Style`（间距、字号、圆角）。它们都是**每帧可改的普通数据**：

```rust
// ═══ 7.3 主题切换 + 样式微调 ═══
if ui.button(if app.dark { "切换到亮色" } else { "切换到暗色" }).clicked() {
    app.dark = !app.dark;
    ui.ctx().set_visuals(if app.dark { egui::Visuals::dark() } else { egui::Visuals::light() });
}

// 局部样式：闭包内改，出闭包还原
ui.horizontal(|ui| {
    let style = ui.style_mut();
    style.spacing.item_spacing = egui::vec2(14.0, 10.0);
    style.visuals.widgets.inactive.corner_radius = egui::CornerRadius::same(12);
});
```

三层作用域：`ctx.set_style`（全局）→ `ui.style_mut()`（当前 Ui 及子树）→ 单个控件的 builder 参数。改完下一帧自动生效——即时模式没有"使样式失效"这种事。

## 7.4 无头断言：中文进树 = 字体成功

```rust
// ═══ 7.4 缺字形会 panic，所以"中文标签能查到"就是注册成功的证明 ═══
assert!(harness.query_by_label("中文字体与主题").is_some());

// 主题翻转的可观察证据：按钮文案换成了反向邀请
harness.get_by_label("切换到亮色").click();
harness.run();
assert!(harness.query_by_label("切换到暗色").is_some());
```

## 7.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 07_egui_fonts
```

实测输出（`build/07_egui_fonts.run.out`）：

```text
==== 07 egui 中文字体与主题 开始 ====
font=simhei.ttf dark=false
==== 07 egui 中文字体与主题 结束 ====
```

`font=simhei.ttf`：本机命中的字体文件（Windows 上是黑体；macOS/Linux 会命中各自候选）。真窗口里点按钮切换亮暗主题，看圆角按钮的样式变化。

## 坑位清单

- **kittest 见中文就 panic**：默认字体无 CJK，`MissingGlyphPolicy::Panic` 在整形阶段炸。要么先注册字体（本例），要么 `Harness::builder().allow_missing_glyphs()`（快而脏，断言不了中文标签）。eframe 的 `system_font_fallback` 只救真窗口，救不了无头测试。
- **`FontDefinitions.font_data` 的值是 `Arc<FontData>`**：旧教程的 `insert(name, FontData::from_static(..))` 编译不过；也没有 `FontDefinitions::insert` 这种便捷方法，直接操作两个 map。
- **github master ≠ crates.io**：本教程编写时 github 主线已把 `WidgetVisuals::rounding` 改名 `corner_radius` 相关重构（`Role` vs `WidgetType` 等），但**未发布**。以 docs.rs（= crates.io）和本机 registry 源码为准，别照 master 抄。
- **TTC 集合字体有兼容风险**：`.ttc` 是字体集合，解析器支持度不一；候选列表把单文件 `.ttf`（simhei）排在 `.ttc`（msyh）前面就是这个原因。
- **打包字体的许可**：`include_bytes!` 进二进制 = 分发字体文件，必须选 OFL/Apache 等可再分发许可（Noto/思源黑体系都行），微软系字体不可打包。

---

上一章：[06 · egui 表格、曲线图与图像](06-egui-tables.md) ｜ 下一章：[08 · egui 自定义控件、动画与持久化](08-egui-custom.md) ｜ 返回：[README](../README.md)
