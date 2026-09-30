// ============================================================
// 12_iced_layout —— Length 弹性盒、Container 定位与 Point 坐标选择器
//
// 读法：
//   1. iced 布局 = 弹性盒（row/column）+ Length 三态：
//      Fill（吃剩余）/ Shrink（随内容）/ Fixed(n)。
//   2. Container 负责对齐与装饰：center_x/center_y/padding/border。
//   3. iced_test 的第三种选择器 Point：按几何坐标找/点控件——
//      pick_list 这类自绘文本控件唯一的无头驱动方式。
//   4. iced 的 scrollable 是"急切布局"：所有子项都进树
//      （与 egui 表格的虚拟化形成对照，见正文）。
//
// 官方参考：https://docs.rs/iced/latest/iced/
// ============================================================

use iced::widget::{Space, button, column, container, pick_list, row, scrollable, text};
use iced::{Element, Length, Point};

const CITIES: [&str; 3] = ["北京", "上海", "深圳"];

#[derive(Clone, Debug, PartialEq)]
enum Message {
    RowSelected(usize),
    CityPicked(&'static str),
    SwitchAlignment,
}

#[derive(Clone)]
struct LayoutLab {
    selected_row: Option<usize>,
    city: Option<&'static str>,
    centered: bool, // 中央条的对齐方式切换
}

impl LayoutLab {
    fn new() -> Self {
        Self {
            selected_row: None,
            city: None,
            centered: false,
        }
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::RowSelected(i) => self.selected_row = Some(i),
            Message::CityPicked(c) => self.city = Some(c),
            Message::SwitchAlignment => self.centered = !self.centered,
        }
    }

    fn view(&self) -> Element<'_, Message> {
        // Space 撑开：两端对齐的一行（Shrink 的 label 夹着 Fill 的空白）
        let top_bar = row![
            text("左端"),
            Space::new().width(Length::Fill), // 0.14：尺寸走 builder，构造器无参
            text("右端"),
        ]
        .padding(8)
        .width(Length::Fill);

        // 对齐切换行：固定高度 120 的演示区，centered 时容器内居中。
        // 两个分支各 .into() 成 Element 再汇合（类型不同，先统一再赋值）
        let align_demo: Element<'_, Message> = if self.centered {
            container(button("切换对齐").on_press(Message::SwitchAlignment))
                .center(Length::Fill)
                .height(Length::Fixed(120.0))
                .into()
        } else {
            container(button("切换对齐").on_press(Message::SwitchAlignment))
                .width(Length::Fill)
                .height(Length::Fixed(120.0))
                .align_left(Length::Shrink)
                .into()
        };

        // pick_list：自绘文本 → 测试只能用 Point 坐标驱动（见 selftest）
        let picker = pick_list(CITIES, self.city, Message::CityPicked).placeholder("选择城市");

        // scrollable + 20 行按钮：急切布局，第 19 行也在树里
        let rows = scrollable(
            column((0..20).map(|i| {
                button(text(format!("行 {i}")))
                    .on_press(Message::RowSelected(i))
                    .into()
            }))
            .spacing(4),
        )
        .height(Length::Fixed(220.0));

        column![
            top_bar,
            align_demo,
            row![picker, text(format!("选中：{}", self.city.unwrap_or("无")))].spacing(8),
            rows,
            text(format!(
                "selected_row = {}",
                self.selected_row
                    .map(|i| i.to_string())
                    .unwrap_or("无".into())
            )),
        ]
        .spacing(10)
        .padding(16)
        .into()
    }
}

fn main() -> iced::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    iced::application(LayoutLab::new, LayoutLab::update, LayoutLab::view)
        .title("12 iced layout")
        .window_size(iced::Size::new(420.0, 560.0))
        .run()
}

/// 无头自检：Length 断言 + 视口内点击 + Point 选择器机制演示。
fn selftest_body() -> Result<LayoutLab, iced_test::Error> {
    use iced_test::Simulator;

    let mut app = LayoutLab::new();
    let mut ui: Simulator<'_, Message> = Simulator::with_size(
        Default::default(),
        iced::Size::new(420.0, 560.0),
        app.view(),
    );

    // ---- Point 选择器语义一：按点找控件，返回【最外层】命中者 ----
    // DFS 从根开始，根 Container 先于子控件命中——find(任意点) 拿到的
    // 几乎总是整窗 Container。这不是 bug，是"命中即容器"的选择器语义。
    let root = ui.find(Point::new(200.0, 300.0))?;
    let dbg = format!("{root:?}");
    assert!(dbg.contains("Container"), "任意点命中的是根容器：{dbg}");

    // ---- 行按钮：&str 可点——但只点视口内的 ----
    // iced 的 scrollable 是急切布局（20 行全在树里），可滚动出视口的行
    // visible_bounds 为 None，iced_test 拒绝点击（TargetNotVisible）——
    // 与 egui 表格的虚拟化（视口外根本不进树）是一组范式对照。
    ui.click("行 1")?;
    for m in ui.into_messages() {
        app.update(m);
    }
    assert_eq!(app.selected_row, Some(1));

    // ---- 坐标驱动的可行模式：锚点 bounds 推导 + 原始事件注入 ----
    // click(Point) 的高层语义是"点【命中目标】的中心"，而 Point 先命中
    // 根容器——对嵌套控件等于永远点窗口中心。真正按坐标驱动要用
    // simulate() 注入原始事件：光标移动到目标坐标 + 按下 + 释放，
    // 事件按坐标做命中测试，会落进最深层的控件。
    let mut ui: Simulator<'_, Message> = Simulator::with_size(
        Default::default(),
        iced::Size::new(420.0, 560.0),
        app.view(),
    );
    ui.click("切换对齐")?; // &str：centered -> true

    // 锚点 = 可查询的文本；从它的 bounds 推导按钮中心坐标
    use iced_test::selector::Text as TextTarget; // selector 根下直接 re-export
    let anchor = ui.find("切换对齐")?;
    let (cx, cy) = match anchor {
        TextTarget::Raw { bounds, .. } | TextTarget::Input { bounds, .. } => (
            bounds.x + bounds.width / 2.0,
            bounds.y + bounds.height / 2.0,
        ),
    };

    // 按坐标注入一次完整点击（光标就位 → 按下 → 释放）
    use iced::mouse::{self, Button};
    ui.simulate([
        iced::Event::Mouse(mouse::Event::CursorMoved {
            position: Point::new(cx, cy),
        }),
        iced::Event::Mouse(mouse::Event::ButtonPressed(Button::Left)),
        iced::Event::Mouse(mouse::Event::ButtonReleased(Button::Left)),
    ]);
    for m in ui.into_messages() {
        app.update(m);
    }
    // 两次切换（一次 &str、一次坐标注入）后应回到左对齐
    assert!(!app.centered, "坐标注入的点击应命中切换按钮");

    Ok(app)
}

fn run_selftest() {
    println!("==== 12 iced 布局与定位 开始 ====");
    let app = selftest_body().expect("iced_test 模拟交互失败");
    println!(
        "selected_row={:?} centered={}",
        app.selected_row, app.centered
    );
    assert_eq!(app.selected_row, Some(1));
    println!("==== 12 iced 布局与定位 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn rows_clickable_and_point_click_hits_center() {
        let app = super::selftest_body().expect("iced_test 失败");
        assert_eq!((app.selected_row, app.centered), (Some(1), false));
    }
}
