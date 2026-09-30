// ============================================================
// 22_slint_models —— VecModel、ModelRc 与 ListView 虚拟化
//
// 读法：
//   1. Rust 的 VecModel 是数据的家：push/remove/row_data 直接改，
//      界面经"模型通知"自动增量更新——没有"刷新列表"这回事。
//   2. .slint 的 for-in 吃模型；ListView 是虚拟化渲染（行复用），
//      普通 for 在布局里是急切实例化——大数据量必须 ListView。
//   3. 测试直接读 VecModel：数据侧断言 + 行交互的几何点击。
//
// 官方参考：https://docs.slint.dev/latest/docs/slint/
// ============================================================

use slint::{ComponentHandle, Model, ModelRc, VecModel};

slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let selftest = std::env::args().nth(1).is_some_and(|a| a == "--selftest");
    if selftest {
        run_selftest();
        return Ok(());
    }

    let app = ModelLab::new()?;

    // ---- 模型的家在 Rust：VecModel 包成 ModelRc 塞给属性 ----
    let model = std::rc::Rc::new(VecModel::from(vec![
        Item {
            name: "第一条".into(),
            done: false,
        },
        Item {
            name: "第二条".into(),
            done: true,
        },
    ]));
    app.set_items(ModelRc::from(model.clone()));

    // ---- 回调半边：改模型即可，界面自动跟上 ----
    {
        let model = model.clone();
        app.on_add_sample(move || {
            let n = model.iter().count() + 1;
            model.push(Item {
                name: format!("第{n}条").into(),
                done: false,
            });
        });
    }
    {
        let model = model.clone();
        app.on_toggle(move |i| {
            if let Some(mut it) = model.row_data(i as usize) {
                it.done = !it.done;
                model.set_row_data(i as usize, it); // 通知这一行更新
            }
        });
    }
    {
        let model = model.clone();
        app.on_remove(move |i| {
            model.remove(i as usize);
        });
    }

    app.run()
}

/// 无头自检：模型增删改（Rust 直改 + 几何点击行）、count 绑定联动。
fn selftest_body() -> (usize, bool) {
    i_slint_backend_testing::init_no_event_loop();
    let app = ModelLab::new().expect("testing backend 下创建组件失败");

    let model = std::rc::Rc::new(VecModel::from(vec![
        Item {
            name: "第一条".into(),
            done: false,
        },
        Item {
            name: "第二条".into(),
            done: true,
        },
    ]));
    app.set_items(ModelRc::from(model.clone()));

    // 回调接线与 main 相同（忘了这步，点击就是空操作——selftest 常见坑）
    {
        let model = model.clone();
        app.on_toggle(move |i| {
            if let Some(mut it) = model.row_data(i as usize) {
                it.done = !it.done;
                model.set_row_data(i as usize, it);
            }
        });
    }
    {
        let model = model.clone();
        app.on_remove(move |i| {
            model.remove(i as usize);
        });
    }

    // ---- Rust 侧直改模型：count 绑定应立即反映 ----
    model.push(Item {
        name: "第三条".into(),
        done: false,
    });
    assert_eq!(app.get_item_count(), 3, "模型 push 后 count 绑定应同步");

    // ---- 行交互：按可访问标签找行文本（几何推导点击）----
    use i_slint_backend_testing::{ElementHandle, ElementRoot};
    let row_text = ElementHandle::find_by_accessible_label(&app, "第一条")
        .next()
        .expect("行文本应可按标签找到");
    let rp = row_text.absolute_position();
    let adapter = i_slint_core::window::WindowInner::from_pub(app.window()).window_adapter();
    i_slint_backend_testing::testing_backend::send_mouse_click(rp.x + 10.0, rp.y + 5.0, &adapter);
    let row0_done = model.row_data(0).map(|r| r.done).unwrap_or(false);
    assert!(row0_done, "点击第一行文本应切换 done=true");

    // 删按钮：按类型名查 Button，按可访问标签过滤"删"，几何点击第一个
    let dels = app
        .root_element()
        .query_descendants()
        .match_type_name(String::from("Button"))
        .find_all()
        .into_iter()
        .filter(|b| b.accessible_label().as_deref() == Some("删"))
        .collect::<Vec<_>>();
    assert_eq!(dels.len(), 3, "三行各有一个删按钮（ListView 全可见）");
    let p = dels[0].absolute_position();
    i_slint_backend_testing::testing_backend::send_mouse_click(p.x + 5.0, p.y + 5.0, &adapter);
    assert_eq!(model.iter().count(), 2, "删除后模型应剩两条");

    let n = app.get_item_count() as usize;
    drop(app);
    (n, row0_done)
}

fn run_selftest() {
    println!("==== 22 slint 模型与列表 开始 ====");
    let (n, done) = selftest_body();
    println!("final count={n} row0_was_toggled={done}");
    assert_eq!(n, 2);
    println!("==== 22 slint 模型与列表 结束 ====");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn model_crud_and_row_interaction() {
        let (n, done) = selftest_body();
        assert_eq!(n, 2);
        assert!(done);
    }
}
