// ═══ 18.2 无头测试 shim：坐标注入 + ElementHandle 查询 ═══
// 两层能力拼成 slint 的无头通道：
//   1. i-slint-backend-testing 的注入函数（ffi feature 门控）
//   2. ElementHandle 元素查询（build.rs 的 with_debug_info 供数据）
// 组合套路：按 id 查到元素 → 拿它的真实几何 → 在几何中心注入点击。

use i_slint_backend_testing::ElementHandle;
use slint::ComponentHandle;

/// 在 (x, y) 坐标模拟一次鼠标点击（逻辑坐标）。
pub fn send_mouse_click<Component>(component: &Component, x: f32, y: f32)
where
    Component: ComponentHandle,
{
    let adapter = i_slint_core::window::WindowInner::from_pub(component.window()).window_adapter();
    i_slint_backend_testing::testing_backend::send_mouse_click(x, y, &adapter);
}

/// 按 .slint 里的元素 id 查询（build.rs 必须开 with_debug_info）。
pub fn element_by_id<Component>(component: &Component, id: &str) -> ElementHandle
where
    Component: ComponentHandle,
{
    ElementHandle::find_by_element_id(component, id)
        .next()
        .unwrap_or_else(|| panic!("找不到元素 id={id}（build.rs 开 with_debug_info 了吗？）"))
}

/// 点击一个元素：几何位置由查询结果给出，不再盲猜坐标。
pub fn click_element<Component>(component: &Component, element: &ElementHandle)
where
    Component: ComponentHandle,
{
    let pos = element.absolute_position();
    send_mouse_click(component, pos.x + 10.0, pos.y + 10.0);
}
