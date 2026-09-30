// ============================================================
// 23_slint_app —— 综合实战：待办管理器（Slint 版）
//
// 统一规格（09/16/23 三章同一应用）：
//   [1] 列表显示（ListView 虚拟化）
//   [2] 文本输入添加（LineEdit edited/accepted 双通道）
//   [3] 勾选完成（点行切换 + 划线过渡动画）
//   [4] 删除
//   [5] 综合组件（ListView + 状态栏计数）
// Slint 特色亮点：完成项划线宽度动画（states/animate 的实战）
//              + Rust 侧 serde 持久化（模型即数据源，序列化直给）
//
// 官方参考：https://docs.slint.dev/latest/docs/slint/
// ============================================================

use slint::{ComponentHandle, Model, ModelRc, VecModel};

slint::include_modules!();

/// 持久化载体的 serde 形态（slint 结构体也能 derive serde？不能——
/// 生成类型不带 derive，所以持久化用平行的 serde 结构）
#[derive(serde::Serialize, serde::Deserialize, Clone, PartialEq)]
struct TodoRow {
    text: String,
    done: bool,
}

impl From<&Todo> for TodoRow {
    fn from(t: &Todo) -> Self {
        Self {
            text: t.text.to_string(),
            done: t.done,
        }
    }
}

fn save(model: &VecModel<Todo>, path: &std::path::Path) -> usize {
    let rows: Vec<TodoRow> = model.iter().map(|t| (&t).into()).collect();
    match serde_json::to_string(&rows) {
        Ok(json) => match std::fs::write(path, &json) {
            Ok(()) => json.len(),
            Err(_) => 0,
        },
        Err(_) => 0,
    }
}

fn load(path: &std::path::Path) -> Vec<Todo> {
    std::fs::read_to_string(path)
        .ok()
        .and_then(|json| serde_json::from_str::<Vec<TodoRow>>(&json).ok())
        .map(|rows| {
            rows.into_iter()
                .map(|r| Todo {
                    text: r.text.into(),
                    done: r.done,
                })
                .collect()
        })
        .unwrap_or_default()
}

fn default_path() -> std::path::PathBuf {
    std::env::temp_dir().join("23_slint_todo.json")
}

fn refresh_count(app: &TodoApp, model: &VecModel<Todo>) {
    app.set_done_count(model.iter().filter(|t| t.done).count() as i32);
}

fn wire(app: &TodoApp, model: &std::rc::Rc<VecModel<Todo>>, path: std::path::PathBuf) {
    // add：Enter（accepted）与按钮共用一条路径
    {
        let model = model.clone();
        let app2 = app.as_weak();
        let path = path.clone();
        app.on_add(move |text| {
            let text = text.trim().to_owned();
            if text.is_empty() {
                return;
            }
            model.push(Todo {
                text: text.into(),
                done: false,
            });
            if let Some(app) = app2.upgrade() {
                refresh_count(&app, &model);
            }
            let _ = save(&model, &path);
        });
    }
    // toggle：set_row_data 触发该行重渲染（划线动画从这起步）
    {
        let model = model.clone();
        let app2 = app.as_weak();
        let path = path.clone();
        app.on_toggle(move |i| {
            if let Some(mut t) = model.row_data(i as usize) {
                t.done = !t.done;
                model.set_row_data(i as usize, t);
            }
            if let Some(app) = app2.upgrade() {
                refresh_count(&app, &model);
            }
            let _ = save(&model, &path);
        });
    }
    // remove
    {
        let model = model.clone();
        let app2 = app.as_weak();
        let path = path.clone();
        app.on_remove(move |i| {
            model.remove(i as usize);
            if let Some(app) = app2.upgrade() {
                refresh_count(&app, &model);
            }
            let _ = save(&model, &path);
        });
    }
    // persist：显式保存出口（本例各回调已即时保存，这里留作演示）
    {
        let model = model.clone();
        let path = path.clone();
        app.on_persist(move || {
            let _ = save(&model, &path);
        });
    }
}

fn main() -> Result<(), slint::PlatformError> {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let path = default_path();
    let app = TodoApp::new()?;
    let model = std::rc::Rc::new(VecModel::from(load(&path)));
    app.set_todos(ModelRc::from(model.clone()));
    refresh_count(&app, &model);
    wire(&app, &model, path);
    app.run()
}

/// 无头自检：a11y 输入添加 → 点行切换（划线动画的 done 态）→ 删 →
/// 持久化往返 → 重启读档。
fn selftest_body() -> (usize, i32, usize) {
    i_slint_backend_testing::init_no_event_loop();
    let app = TodoApp::new().expect("testing backend 下创建组件失败");

    let path = std::env::temp_dir().join("23_slint_todo_selftest.json");
    let _ = std::fs::remove_file(&path); // 干净起跑（两跑一致的根基）

    let model = std::rc::Rc::new(VecModel::from(vec![
        Todo {
            text: "读 slint 章节".into(),
            done: true,
        },
        Todo {
            text: "写第三个实战".into(),
            done: false,
        },
    ]));
    app.set_todos(ModelRc::from(model.clone()));
    refresh_count(&app, &model);
    wire(&app, &model, path.clone());

    // ---- [2] a11y 输入 + accepted（回车语义直接调 add）----
    use i_slint_backend_testing::ElementHandle;
    let input = ElementHandle::find_by_element_id(&app, "TodoApp::draft-input")
        .next()
        .expect("找输入框");
    input.set_accessible_value("写综合实战");
    app.invoke_add(app.get_draft()); // accepted 的 Rust 侧等价（回车走同一回调）

    assert_eq!(model.iter().count(), 3, "添加后应有三条");
    assert!(model.iter().any(|t| t.text == "写综合实战"));

    // ---- [3] 点"写综合实战"那行切换 done ----
    let row = ElementHandle::find_by_accessible_label(&app, "写综合实战")
        .next()
        .expect("找行文本");
    let rp = row.absolute_position();
    let adapter = i_slint_core::window::WindowInner::from_pub(app.window()).window_adapter();
    i_slint_backend_testing::testing_backend::send_mouse_click(rp.x + 10.0, rp.y + 5.0, &adapter);
    let toggled = model
        .iter()
        .find(|t| t.text == "写综合实战")
        .map(|t| t.done)
        .unwrap_or(false);
    assert!(toggled, "点行应切换 done=true（划线动画状态切换）");
    assert_eq!(app.get_done_count(), 2);

    // ---- [4] 删掉它：按类型名查"删"按钮，点对应行（最后一条）----
    use i_slint_backend_testing::ElementRoot;
    let dels = app
        .root_element()
        .query_descendants()
        .match_type_name(String::from("Button"))
        .find_all()
        .into_iter()
        .filter(|b| b.accessible_label().as_deref() == Some("删"))
        .collect::<Vec<_>>();
    assert_eq!(dels.len(), 3);
    let p = dels.last().unwrap().absolute_position();
    i_slint_backend_testing::testing_backend::send_mouse_click(p.x + 5.0, p.y + 5.0, &adapter);
    assert_eq!(model.iter().count(), 2, "删除后剩两条");

    // ---- [持久化] wire 里已即时保存：文件存在且往返一致 ----
    let saved_len = std::fs::read_to_string(&path).map(|s| s.len()).unwrap_or(0);
    assert!(saved_len > 0, "回调应已触发落盘");
    let reloaded = load(&path);
    assert_eq!(reloaded.len(), 2, "重启读档应拿到两条");

    let n = model.iter().count();
    let done_count = app.get_done_count();
    drop(app);
    (n, done_count, saved_len)
}

fn run_selftest() {
    println!("==== 23 slint 待办管理器 开始 ====");
    let (n, done, bytes) = selftest_body();
    println!("items={n} done={done} saved={bytes} bytes");
    println!("==== 23 slint 待办管理器 结束 ====");
}

#[cfg(test)]
mod tests {
    #[test]
    fn todo_journey_and_persistence() {
        let (n, done, bytes) = super::selftest_body();
        assert_eq!(n, 2);
        assert_eq!(done, 1);
        assert!(bytes > 0);
    }
}
