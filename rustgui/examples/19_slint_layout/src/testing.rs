// ═══ 19.2 无头测试 shim（18 章同款：坐标注入 + 元素查询）═══
use i_slint_backend_testing::ElementHandle;
use slint::ComponentHandle;

pub fn send_mouse_click<Component>(component: &Component, x: f32, y: f32)
where
    Component: ComponentHandle,
{
    let adapter = i_slint_core::window::WindowInner::from_pub(component.window()).window_adapter();
    i_slint_backend_testing::testing_backend::send_mouse_click(x, y, &adapter);
}

pub fn element_by_id<Component>(component: &Component, id: &str) -> ElementHandle
where
    Component: ComponentHandle,
{
    ElementHandle::find_by_element_id(component, id)
        .next()
        .unwrap_or_else(|| panic!("找不到元素 id={id}"))
}
