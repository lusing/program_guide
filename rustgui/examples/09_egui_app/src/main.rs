// ============================================================
// 09_egui_app —— 综合实战：待办管理器
//
// 统一规格（09/16/23 三章同一应用）：
//   [1] 列表显示  [2] 文本输入添加  [3] 勾选完成
//   [4] 删除       [5] 综合组件（滚动列表）
// egui 特色亮点：完成趋势迷你图（egui_plot）
//              + 后台线程 mpsc + ctx.request_repaint 唤醒主线程
//
// 读法：
//   1. 业务状态全在 Todos 结构体——即时模式的"单一事实源"。
//   2. 后台线程把消息塞进 mpsc，主循环每帧 drain；
//      帧调度用 request_repaint_from / request_repaint 联动。
//   3. 趋势图数据 = 每次添加/完成后的历史快照，egui_plot 画线。
//
// 官方参考：https://github.com/emilk/egui（egui 的官方例子 todo 不存在，
//          这是本教程设计的跨框架对照应用，16/23 章是同一规格的另两实现）
// ============================================================

/// 一条待办
#[derive(Clone, PartialEq)]
struct Todo {
    text: String,
    done: bool,
}

/// 后台线程发给主循环的消息（"模拟加载数据"任务的进度块）
#[derive(Clone, Debug, PartialEq)]
enum WorkerMsg {
    Chunk(i64), // 第 n 块数据到了
    Done,
}

/// 供 selftest/文档引用的状态快照（mpsc::Receiver 不能 Clone，
/// 所以 Todos 整体不 derive Clone，改用显式快照）
#[derive(Clone)]
struct Snapshot {
    items: Vec<Todo>,
    trend_len: usize,
    loaded_chunks: usize,
    working: bool,
}

struct Todos {
    items: Vec<Todo>,
    input: String,
    /// 完成度历史：每发生一次添加/完成，记一笔 (序号, 已完成数)
    trend: Vec<[f64; 2]>,
    /// 后台任务的接收端（None = 没有任务在跑）
    worker_rx: Option<std::sync::mpsc::Receiver<WorkerMsg>>,
    /// 后台线程累计送达的数据块
    loaded_chunks: usize,
    /// selftest 模式下后台线程不 sleep（保证确定性）
    fast_worker: bool,
}

impl Default for Todos {
    fn default() -> Self {
        Self::new(false)
    }
}

impl Todos {
    fn new(fast_worker: bool) -> Self {
        Self {
            items: vec![
                Todo {
                    text: "读 egui 章节".into(),
                    done: true,
                },
                Todo {
                    text: "写第一个 egui 应用".into(),
                    done: false,
                },
            ],
            input: String::new(),
            trend: vec![[0.0, 0.0], [1.0, 1.0]],
            worker_rx: None,
            loaded_chunks: 0,
            fast_worker,
        }
    }

    fn done_count(&self) -> usize {
        self.items.iter().filter(|t| t.done).count()
    }

    fn snapshot(&self) -> Snapshot {
        Snapshot {
            items: self.items.clone(),
            trend_len: self.trend.len(),
            loaded_chunks: self.loaded_chunks,
            working: self.worker_rx.is_some(),
        }
    }

    fn record_trend(&mut self) {
        let x = self.trend.last().map(|p| p[0] + 1.0).unwrap_or(0.0);
        self.trend.push([x, self.done_count() as f64]);
    }

    fn add(&mut self) {
        let text = self.input.trim().to_owned();
        if text.is_empty() {
            return;
        }
        self.items.push(Todo { text, done: false });
        self.input.clear();
        self.record_trend();
    }

    /// 启动"后台加载"任务：worker 线程分 4 块送达数据。
    /// fast_worker=true（selftest）时不 sleep，保证帧序确定。
    fn start_worker(&mut self) {
        let (tx, rx) = std::sync::mpsc::channel::<WorkerMsg>();
        let fast = self.fast_worker;
        std::thread::spawn(move || {
            for i in 1..=4_i64 {
                if !fast {
                    std::thread::sleep(std::time::Duration::from_millis(60));
                }
                if tx.send(WorkerMsg::Chunk(i)).is_err() {
                    return; // 接收端没了，收工
                }
            }
            let _ = tx.send(WorkerMsg::Done);
        });
        self.worker_rx = Some(rx);
        self.loaded_chunks = 0;
    }

    /// 每帧排空通道：后台消息 -> 状态变更 -> （还有事就）请求下一帧。
    /// 借用拆分：先把通道里的消息收进 Vec（rx 只读借用），再动 &mut self。
    fn drain_worker(&mut self, ctx: &egui::Context) {
        let messages: Vec<WorkerMsg> = {
            let Some(rx) = &self.worker_rx else { return };
            let mut m = Vec::new();
            while let Ok(msg) = rx.try_recv() {
                m.push(msg);
            }
            m
        };
        for msg in messages {
            match msg {
                WorkerMsg::Chunk(n) => {
                    self.loaded_chunks = n as usize;
                    // 模拟"数据块"变成一条新待办
                    self.items.push(Todo {
                        text: format!("后台数据块 {n}"),
                        done: false,
                    });
                    self.record_trend();
                }
                WorkerMsg::Done => self.worker_rx = None,
            }
        }
        // 任务未结束：约下一帧继续 drain（另一路是 ctx.request_repaint_from，
        // 让 worker 线程发完消息主动唤醒 UI 线程——真项目两种都常见）
        if self.worker_rx.is_some() {
            ctx.request_repaint();
        }
    }

    fn ui_body(ui: &mut egui::Ui, app: &mut Todos) {
        // ---- 顶栏：输入 + 添加 + 后台任务 ----
        egui::Panel::top("input-bar")
            .exact_size(44.0)
            .show(ui, |ui| {
                ui.horizontal_centered(|ui| {
                    // hint_text/desired_width 是 TextEdit 构建器的链式方法，
                    // 要在 ui.add 之前链；add 返回的 Response 只有交互信息
                    let input_resp = ui.add(
                        egui::TextEdit::singleline(&mut app.input)
                            .hint_text("新待办…")
                            .desired_width(220.0),
                    );
                    let add =
                        input_resp.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter));
                    if add || ui.button("添加").clicked() {
                        app.add();
                    }
                    if app.worker_rx.is_none() {
                        if ui.button("后台加载").clicked() {
                            app.start_worker();
                        }
                    } else {
                        ui.spinner();
                        ui.label(format!("块 {}/4", app.loaded_chunks));
                    }
                });
            });

        // ---- 左侧栏：列表 ----
        egui::Panel::left("list")
            .resizable(false)
            .exact_size(300.0)
            .show(ui, |ui| {
                ui.heading(format!(
                    "待办（{}/{} 已完成）",
                    app.done_count(),
                    app.items.len()
                ));
                egui::ScrollArea::vertical().show(ui, |ui| {
                    // 倒着删安全：边遍历边删不会跳过元素。
                    // 复选框直接携带待办文本做无障碍标签（空标签过不了
                    // kittest 的 accessibility check，也点不准）。
                    for i in (0..app.items.len()).rev() {
                        let mut toggled = false;
                        let mut remove = false;
                        ui.horizontal(|ui| {
                            let todo = &mut app.items[i];
                            if ui.checkbox(&mut todo.done, todo.text.clone()).changed() {
                                toggled = true;
                            }
                            if ui.small_button("删").clicked() {
                                remove = true;
                            }
                        });
                        if toggled {
                            app.record_trend();
                        }
                        if remove {
                            app.items.remove(i);
                        }
                    }
                });
            });

        // ---- 中央区：趋势图 ----
        egui::CentralPanel::default().show(ui, |ui| {
            ui.heading("完成趋势");
            let line = egui_plot::Line::new("done", app.trend.clone());
            egui_plot::Plot::new("trend")
                .height(200.0)
                .show(ui, |plot| plot.line(line));
            ui.label(format!("已加载块数：{}", app.loaded_chunks));
        });

        // ---- 后台消息每帧排空（放在布局之后、帧尾） ----
        app.drain_worker(ui.ctx());
    }
}

impl eframe::App for Todos {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        Self::ui_body(ui, self);
    }
}

fn main() -> eframe::Result {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([720.0, 420.0]),
        ..Default::default()
    };
    eframe::run_native(
        "09_egui_app · 待办管理器",
        options,
        Box::new(|_cc| Ok(Box::new(Todos::new(false)))),
    )
}

/// 无头自检：添加→勾选→删除→后台任务排空→趋势断言。
fn selftest_body() -> Snapshot {
    use egui_kittest::kittest::{NodeT, Queryable};

    // fast_worker：worker 不 sleep，消息在帧间确定性送达
    let mut harness = egui_kittest::Harness::builder()
        .with_max_steps(32)
        .build_eframe(|_cc| Todos::new(true));
    harness.run();

    // [2] 输入 + 添加
    let input = harness.get_by_role(egui::accesskit::Role::TextInput);
    input.focus();
    harness.run();
    harness
        .get_by_role(egui::accesskit::Role::TextInput)
        .type_text("写综合实战");
    harness.run();
    harness.get_by_label("添加").click();
    harness.run();
    assert!(
        harness.query_by_label("写综合实战").is_some(),
        "新待办应出现在列表里"
    );

    // [3] 勾选完成：复选框以待办文本为无障碍标签，直接点名点击
    harness.get_by_label("写综合实战").click();
    harness.run();

    // [4] 删除"写综合实战"：相对查询——先定位条目（复选框），
    // 再到它的父行里找同一个 horizontal 内的"删"按钮。
    // 不依赖 get_all_by_label 的节点顺序（实测为逆文档序，last() 会删错行）。
    let cb = harness.get_by_label("写综合实战");
    let row = cb.parent().expect("条目应在一行（horizontal）里");
    let del = row.get_by_label("删");
    del.click();
    harness.run();
    assert!(
        harness.query_by_label("写综合实战").is_none(),
        "删除后应消失"
    );

    // [5] 后台任务：点击后 worker 4 块 + Done；drain 逻辑会 request_repaint 直到 Done
    harness.get_by_label("后台加载").click();
    harness.run(); // 跑到稳定（Done 后不再请求重绘）

    let app = harness.state().snapshot();
    assert_eq!(app.loaded_chunks, 4, "4 块数据应全部送达");
    assert!(!app.working, "任务应已结束");
    assert!(
        app.items.iter().any(|t| t.text == "后台数据块 4"),
        "数据块应变成待办条目"
    );
    app
}

fn run_selftest() {
    println!("==== 09 egui 待办管理器 开始 ====");
    let app = selftest_body();
    let done = app.items.iter().filter(|t| t.done).count();
    println!(
        "items={} done={} trend-points={} chunks={}",
        app.items.len(),
        done,
        app.trend_len,
        app.loaded_chunks
    );
    println!("==== 09 egui 待办管理器 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn todo_workflow_and_worker_complete() {
        let app = super::selftest_body();
        assert_eq!(app.loaded_chunks, 4);
        assert!(!app.working);
        assert!(app.items.iter().filter(|t| t.done).count() >= 1);
    }
}
