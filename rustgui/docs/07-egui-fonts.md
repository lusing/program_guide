# 07 · egui 中文字体与主题样式

> 对应示例：[examples/07_egui_fonts](../examples/07_egui_fonts)

## 7.1 为什么前五章不敢用中文

egui 内置字体只有拉丁 + 少量符号，**没有 CJK 字形**。缺字形的字符只会被画成替换符 ◻（豆腐块），而且**全程无报错**：kittest 无头通道只走无障碍树、从不光栅化字形；0.36.2 的 eframe 也没有系统字体回退（github master 已加入 `NativeOptions::system_font_fallback` 与 kittest 的 `MissingGlyphPolicy::Panic`，**都未发布**）。所以 02–06 章的 UI 文本全部 ASCII；本章注册字体正面解决，08/09 章复用本章方案。

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

## 7.4 无头断言的边界：进树 ≠ 有字形

```rust
// ═══ 7.4 标签查得到只证明文本进了无障碍树；字形画没画出来，无头通道看不见 ═══
assert!(harness.query_by_label("中文字体与主题").is_some());
```

要诚实面对边界：0.36.2 的 kittest 不光栅化任何像素，`query_by_label` 拿到的是原始字符串——**就算字体没注册，这条断言照样过**。selftest 里真正证明字体装上的是 `font=simhei.ttf` 那行输出（文件读到了、`set_fonts` 调了）；字形的最终裁决只能靠真窗口——本仓库 `tools/gui-shots.ps1` 逐例启动真窗口截图核对，08/09 章的豆腐块事故就是它抓到的。

主题翻转的证据链则完全无头可信（不涉及字形，只涉及文案换向）：

```rust
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

- **豆腐块在无头测试里隐形（08/09 章真实事故）**：缺字形不 panic、不报错——无头只查无障碍树，0.36.2 真窗口又没有系统字体回退。08/09 章初稿 UI 用了中文却没注册字体，`cargo test` 与 `--selftest` 全绿，真窗口截图（`tools/gui-shots.ps1`）才发现满屏 ◻。master 已加入 kittest 的 `MissingGlyphPolicy::Panic` 与 eframe 的 `system_font_fallback`，**均未发布**——这两条 API 曾以"master 事实"的身份混进本教程初稿，是断代期照 master 写文档的典型幻觉。
- **`FontDefinitions.font_data` 的值是 `Arc<FontData>`**：旧教程的 `insert(name, FontData::from_static(..))` 编译不过；也没有 `FontDefinitions::insert` 这种便捷方法，直接操作两个 map。
- **github master ≠ crates.io**：本教程编写时 github 主线已把 `WidgetVisuals::rounding` 改名 `corner_radius` 相关重构（`Role` vs `WidgetType` 等），但**未发布**。以 docs.rs（= crates.io）和本机 registry 源码为准，别照 master 抄。
- **TTC 集合字体有兼容风险**：`.ttc` 是字体集合，解析器支持度不一；候选列表把单文件 `.ttf`（simhei）排在 `.ttc`（msyh）前面就是这个原因。
- **打包字体的许可**：`include_bytes!` 进二进制 = 分发字体文件，必须选 OFL/Apache 等可再分发许可（Noto/思源黑体系都行），微软系字体不可打包。

---

上一章：[06 · egui 表格、曲线图与图像](06-egui-tables.md) ｜ 下一章：[08 · egui 自定义控件、动画与持久化](08-egui-custom.md) ｜ 返回：[README](../README.md)
