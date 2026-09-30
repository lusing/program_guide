// ============================================================
// 15_iced_canvas —— Canvas 自绘：第三只进度环
//
// 读法：
//   1. canvas 是 feature 门控件（默认不开）：canvas = ["iced_widget/canvas"]。
//   2. 自绘单元是 canvas::Program：type State（内部可变状态）+ draw()。
//      与 egui 的 Painter（每帧命令式）对照：iced 把"画什么"做成
//      一个返回 Geometry 列表的函数，配 Cache 做增量。
//   3. 这是 09/15/20 三章"同一只进度环"的 iced 版：三种自绘哲学。
//
// 官方参考：https://docs.rs/iced/latest/iced/widget/canvas/
// ============================================================

use iced::widget::{button, canvas, column, row, text};
use iced::{Color, Element, Rectangle, Subscription, Task, Theme};

#[derive(Clone, Debug)]
enum Message {
    Add(f32),
    Auto,
}

#[derive(Clone)]
struct RingApp {
    progress: f32,
    auto: bool,
    ticks: u64, // 自计数驱动自动播放（确定性，不存时间）
}

impl RingApp {
    fn new() -> Self {
        Self {
            progress: 0.3,
            auto: false,
            ticks: 0,
        }
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::Add(d) => {
                self.progress = (self.progress + d).clamp(0.0, 1.0);
                Task::none()
            }
            Message::Auto => {
                self.auto = !self.auto;
                self.ticks = 0;
                Task::none()
            }
        }
    }

    fn subscription(&self) -> Subscription<Message> {
        if self.auto {
            iced::time::every(iced::time::milliseconds(50)).map(|_| Message::Add(0.05))
        } else {
            Subscription::none()
        }
    }

    fn view(&self) -> Element<'_, Message> {
        let ring = canvas(Ring {
            progress: self.progress,
        })
        .width(iced::Length::Fixed(180.0))
        .height(iced::Length::Fixed(180.0));

        column![
            text("Canvas 进度环").size(24),
            ring,
            text(format!("{:.0}%", self.progress * 100.0)).size(28),
            row![
                button("-10%").on_press(Message::Add(-0.1)),
                button("+10%").on_press(Message::Add(0.1)),
                button(if self.auto { "停止" } else { "自动" }).on_press(Message::Auto),
            ]
            .spacing(8),
        ]
        .spacing(14)
        .padding(24)
        .align_x(iced::Center)
        .into()
    }
}

/// 进度环的绘制程序：draw 是纯函数（bounds + progress -> Geometry）
struct Ring {
    progress: f32,
}

impl<Message> canvas::Program<Message> for Ring {
    type State = ();

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &iced::Renderer,
        _theme: &Theme,
        bounds: Rectangle,
        _cursor: iced::mouse::Cursor,
    ) -> Vec<canvas::Geometry> {
        let center = bounds.center();
        let radius = bounds.width.min(bounds.height) / 2.0 - 10.0;

        // 底环：整圆描边
        let base = canvas::Path::circle(center, radius);

        // 进度弧：0.36 的 iced 同样没有现成 arc API——
        // 手算点列 + Stroke 折线（与 egui 05 章、slint 20 章同一思路）
        let start = 135.0_f32.to_radians();
        let sweep = 270.0_f32.to_radians() * self.progress.clamp(0.0, 1.0);
        let mut points = Vec::with_capacity(49);
        for i in 0..=48 {
            let angle = start + sweep * (i as f32 / 48.0);
            points.push(center + iced::Vector::new(angle.cos(), angle.sin()) * radius);
        }
        let arc = canvas::Path::new(|p| {
            p.move_to(points[0]);
            for pt in &points[1..] {
                p.line_to(*pt);
            }
        });

        // Frame：命令式画布，画完 into_geometry 交给框架
        let mut frame = canvas::Frame::new(renderer, bounds.size());
        frame.stroke(
            &base,
            canvas::Stroke::default()
                .with_width(10.0)
                .with_color(Color::from_rgb(0.25, 0.25, 0.25)),
        );
        frame.stroke(
            &arc,
            canvas::Stroke::default()
                .with_width(10.0)
                .with_color(Color::from_rgb(0.29, 0.62, 1.0)),
        );
        frame.fill_text(canvas::Text {
            content: format!("{:.0}%", self.progress * 100.0),
            position: center,
            color: Color::WHITE,
            size: 22.0.into(),
            ..Default::default()
        });

        vec![frame.into_geometry()]
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(RingApp::new, RingApp::update, RingApp::view)
        .title("15 iced canvas")
        .subscription(RingApp::subscription)
        .window_size(iced::Size::new(360.0, 480.0))
        .run()
}

/// 无头自检：canvas 内容无像素可断言（simulator 不执行 draw），
/// 状态机与消息环是可测的全部——按钮三连 + 消息单元测试。
fn selftest_body() -> Result<RingApp, iced_test::Error> {
    use iced_test::simulator;

    let mut app = RingApp::new();
    let mut ui = simulator(app.view());

    ui.click("+10%")?;
    ui.click("+10%")?;
    ui.click("-10%")?;
    for m in ui.into_messages() {
        let _ = app.update(m);
    }
    assert!(
        (app.progress - 0.4).abs() < 1e-6,
        "0.3 +0.1 +0.1 -0.1 = 0.4"
    );

    // 屏幕证据：百分比文本随状态重算（借用在块内结束，之后还能动 app）
    {
        let mut ui = simulator(app.view());
        ui.find("40%")?;
    }

    // 自动播放的消息路径（时间流照例走消息单元测试）
    let _ = app.update(Message::Auto);
    for _ in 0..4 {
        let _ = app.update(Message::Add(0.05));
    }
    assert!((app.progress - 0.6).abs() < 1e-6, "自动路径 4 步后 0.6");

    Ok(app)
}

fn run_selftest() {
    println!("==== 15 iced Canvas 进度环 开始 ====");
    let app = selftest_body().expect("iced_test 模拟交互失败");
    println!("progress={:.0}% auto={}", app.progress * 100.0, app.auto);
    assert!((app.progress - 0.6).abs() < 1e-6);
    println!("==== 15 iced Canvas 进度环 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn ring_progress_flow() {
        let app = super::selftest_body().expect("iced_test 失败");
        assert!((app.progress - 0.6).abs() < 1e-6);
    }
}
