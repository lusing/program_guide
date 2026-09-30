// ============================================================
// 13_iced_style —— 主题枚举、Catalog 闭包样式与自定义调色板
//
// 读法：
//   1. 0.13 起样式系统重构：旧 StyleSheet trait + Appearance 改为
//      Catalog trait + Style 结构体；日常写法是 .style(闭包)。
//   2. 内置 20+ 主题枚举（Theme::Light/Dark/Dracula/...），
//      application builder 的 .theme(fn(&State) -> Theme) 切换。
//   3. Theme::custom(name, Palette) 用六色调色板生成完整主题。
//
// 官方参考：https://docs.rs/iced/latest/iced/（theme 模块）
// ============================================================

use iced::widget::{button, column, row, text};
use iced::{Element, Theme};

/// 轮换演示的内置主题（Theme 枚举成员，非字符串）
const THEMES: [Theme; 4] = [Theme::Light, Theme::Dark, Theme::Dracula, Theme::Nord];

#[derive(Clone, Debug, PartialEq)]
enum Message {
    NextTheme,
    PrevTheme,
    DangerPressed,
}

#[derive(Clone)]
struct StyleLab {
    theme_idx: usize,
    danger_clicked: bool,
}

impl StyleLab {
    fn new() -> Self {
        Self {
            theme_idx: 1,
            danger_clicked: false,
        } // 默认 Dark
    }

    fn theme(&self) -> Theme {
        THEMES[self.theme_idx].clone()
    }

    /// Theme 枚举没有公开的 name()；Debug 格式化恰好给出变体名
    fn theme_debug(&self) -> String {
        format!("{:?}", self.theme())
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::NextTheme => self.theme_idx = (self.theme_idx + 1) % THEMES.len(),
            Message::PrevTheme => {
                self.theme_idx = (self.theme_idx + THEMES.len() - 1) % THEMES.len()
            }
            Message::DangerPressed => self.danger_clicked = true,
        }
    }

    fn view(&self) -> Element<'_, Message> {
        column![
            text(format!("当前主题：{}", self.theme_debug())).size(24),
            // 预置样式类：button 模块自带的语义色（primary/danger/...）
            row![
                button("上一主题").on_press(Message::PrevTheme),
                button("下一主题").on_press(Message::NextTheme),
            ]
            .spacing(8),
            // 闭包样式：按 (Theme, Status) 返回 Style——悬停/按下态都在这处理。
            // 样式逻辑抽成具名函数（见文件尾部）：纯函数才好测。
            button(text("危险操作").style(|t: &Theme| {
                let palette = t.extended_palette();
                text::Style {
                    color: Some(palette.danger.base.text),
                }
            }))
            .padding(8)
            .style(danger_button_style)
            .on_press(Message::DangerPressed),
            text(if self.danger_clicked {
                "已点击危险操作"
            } else {
                ""
            }),
        ]
        .spacing(16)
        .padding(24)
        .into()
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(StyleLab::new, StyleLab::update, StyleLab::view)
        .title("13 iced style")
        .theme(|state: &StyleLab| state.theme()) // 主题来自 State：随消息切换
        .window_size(iced::Size::new(420.0, 360.0))
        .run()
}

/// 无头自检：主题轮换 + 语义色按钮全链路（颜色无法无头断言——
/// 我们断言主题状态与样式函数对给定主题的返回值）。
fn selftest_body() -> Result<StyleLab, iced_test::Error> {
    use iced_test::simulator;

    let mut app = StyleLab::new();
    let mut ui = simulator(app.view());

    ui.click("下一主题")?; // Dark -> Dracula
    ui.click("下一主题")?; // Dracula -> Nord
    ui.click("上一主题")?; // Nord -> Dracula
    ui.click("危险操作")?;

    for m in ui.into_messages() {
        app.update(m);
    }

    // 样式函数的纯函数性：给定同一主题和状态，返回值确定
    let theme = app.theme();
    let danger_style = danger_button_style(&theme, iced::widget::button::Status::Active);
    assert!(
        danger_style.background.is_some(),
        "Active 态的危险按钮应有背景色"
    );

    Ok(app)
}

/// 危险按钮的样式函数抽出成具名函数——纯函数才好测
fn danger_button_style(
    theme: &Theme,
    status: iced::widget::button::Status,
) -> iced::widget::button::Style {
    use iced::widget::button::{self, Status};
    let palette = theme.extended_palette();
    match status {
        Status::Active | Status::Disabled => {
            button::Style::default().with_background(palette.danger.base.color)
        }
        Status::Hovered => button::Style::default().with_background(palette.danger.strong.color),
        Status::Pressed => button::Style::default().with_background(palette.danger.weak.color),
    }
}

fn run_selftest() {
    println!("==== 13 iced 主题与样式 开始 ====");
    let app = selftest_body().expect("iced_test 模拟交互失败");
    println!(
        "theme={} danger_clicked={}",
        app.theme_debug(),
        app.danger_clicked
    );
    assert_eq!(app.theme_debug(), "Dracula");
    assert!(app.danger_clicked);
    println!("==== 13 iced 主题与样式 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn theme_rotation_and_danger_button() {
        let app = super::selftest_body().expect("iced_test 失败");
        assert_eq!(app.theme_debug(), "Dracula");
        assert!(app.danger_clicked);
    }
}
