# 13 · iced 主题与样式系统

> 对应示例：[examples/13_iced_style](../examples/13_iced_style)

## 13.1 主题是数据：Theme 枚举

iced 内置二十多个主题，是**普通的枚举值**——`Theme::Light/Dark/Dracula/Nord/…`。挂到 application builder 上，让"当前主题"成为 State 的一部分：

```rust
// ═══ 13.1 主题随 State 走 ═══
iced::application(StyleLab::new, StyleLab::update, StyleLab::view)
    .theme(|state: &StyleLab| state.theme()) // 闭包收 State，返回 Theme
    .run()
```

`.theme()` 也接受固定值（`.theme(Theme::Dark)`）；传闭包就能"点一下换主题"——update 改 `theme_idx`，下一帧 `.theme()` 返回新枚举，整个界面自动换装。与 egui 对照：egui 是 `ctx.set_visuals()` 命令式地"改全局"，iced 是"State 变了主题跟着变"。

自己配色的入口是 `Theme::custom(name, Palette)`——六色（background/text/primary/success/warning/danger）生成完整主题，其余梯度由 Oklch 色彩空间自动推导。

## 13.2 样式：Catalog + 闭包

0.13 的样式系统重构（旧 `StyleSheet` trait + `Appearance` 类型已废）：每种控件有自己的 **`Catalog`** trait 与 **`Style`** 结构体，日常写法只有两种——

**写法一：预置样式类**（模块级函数，`Fn(Theme, Status) -> Style` 的现成实现）：

```rust
use iced::widget::button;
button("提交").style(button::primary);   // primary/danger/success/secondary/text/…
```

**写法二：闭包**（拿 `(Theme, Status)` 现算）：

```rust
// ═══ 13.2 危险按钮：四态配色，色取自当前主题的扩展调色板 ═══
fn danger_button_style(theme: &Theme, status: button::Status) -> button::Style {
    let palette = theme.extended_palette();
    match status {
        button::Status::Active | button::Status::Disabled => {
            button::Style::default().with_background(palette.danger.base.color)
        }
        button::Status::Hovered => {
            button::Style::default().with_background(palette.danger.strong.color)
        }
        button::Status::Pressed => {
            button::Style::default().with_background(palette.danger.weak.color)
        }
    }
}

button(text("危险操作").style(|t: &Theme| {
    // 无状态控件（text）的样式闭包只收 Theme，没有 Status
    text::Style { color: Some(t.extended_palette().danger.base.text) }
}))
.style(danger_button_style)
```

要点：

- `Status` 枚举（Active/Hovered/Pressed/Disabled）让悬停/按下态**不用写事件代码**——样式函数按状态返回即可；
- `theme.extended_palette()` 是配色的正源：每种语义色（primary/danger/…）都有 base/weak/strong 三档，跟着主题自动换；
- **样式逻辑抽成具名函数**不只为整洁——纯函数 `(Theme, Status) -> Style` 才能被无头测试直接调用断言（见 13.4）。

## 13.3 样式能改什么

`button::Style` 的字段就是外观合同：`background`/`text_color`/`border`/`shadow`（还有像素对齐开关 `snap`）。其他控件各有各的 Style：`text::Style { color }`、`container::Style { background, border, shadow, text_color }`、`progress_bar::Style`……套路完全一致。对齐、间距、尺寸**不是样式**——它们是布局参数（12 章），这是 iced 与 CSS 的一个重要分野。

## 13.4 无头测试：颜色测不了，逻辑测得了

tiny-skia 无头通道不出像素，颜色本身无法断言。可测的是**样式逻辑**：

```rust
// ═══ 13.4 直接调用样式函数断言返回值 ═══
let danger_style = danger_button_style(&theme, button::Status::Active);
assert!(danger_style.background.is_some(), "Active 态的危险按钮应有背景色");
```

加上主题轮换的状态断言（`theme()` 返回值随 `theme_idx` 变），主题系统的行为就被钉住了。视觉回归（颜色渐变对不对）才需要快照基准图——本教程刻意不用（跨机器字体渲染差异会制造假红），留一句结论：**样式函数保持纯，逻辑进测试；颜色好不好看，人眼看了算**。

## 13.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 13_iced_style
```

实测输出（`build/13_iced_style.run.out`）：

```text
==== 13 iced 主题与样式 开始 ====
theme=Dracula danger_clicked=true
==== 13 iced 主题与样式 结束 ====
```

真窗口里轮换四个主题，看危险按钮的四态配色如何跟着主题换装——这就是"主题是数据"的含金量。

## 坑位清单

- **Theme 没有 `name()`**：公开 API 取不到主题名，`format!("{:?}", theme)` 的 Debug 输出恰好是变体名（"Dracula"），凑合能用；正式代码自己存索引/名字。
- **0.12 的 `impl button::StyleSheet` 全废**：0.13 起 `Appearance`→`Style`、`StyleSheet`→`Catalog`，旧代码整体重写成闭包或具名函数。
- **闭包签名看控件有无状态**：button 有 `(Theme, Status)`，text/container 只有 `(Theme)`——抄错签名编译器会教你。
- **颜色断言别硬来**：无头通道无像素，样式断言只测"函数返回的 Style 结构里有什么"，别把视觉验证塞进单测。
- **`selected` 样式不是主题**：`button::selected(bool)` 是控件级状态样式（11 章的选中态），与 Theme 换装是两个正交维度。

---

上一章：[12 · iced 布局：Length、Container 与坐标驱动](12-iced-layout.md) ｜ 下一章：[14 · iced 订阅与异步 Task](14-iced-subscription.md) ｜ 返回：[README](../README.md)
