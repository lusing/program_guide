// ═══ 17.2 无头测试 shim：官方 internal_tests.rs 的同款桥接 ═══
//
// 官方 i-slint-backend-testing 的 internal feature 提供
// send_mouse_click(&component, x, y) 级别的封装，但 1.18.1 的发布包
// 因缺字体文件编译不过；这里照官方源码（internal_tests.rs）抄 4 行
// 桥接：从公开的 Window 拿内部 WindowAdapter，再调公开的注入函数。
// slint 升级后如果 internal 修好了，可直接换回官方封装。

/// 在 (x, y) 坐标模拟一次鼠标点击（逻辑坐标，测试窗口默认 800x600）。
pub fn send_mouse_click<Component>(component: &Component, x: f32, y: f32)
where
    Component: slint::ComponentHandle,
{
    let adapter = i_slint_core::window::WindowInner::from_pub(component.window()).window_adapter();
    i_slint_backend_testing::testing_backend::send_mouse_click(x, y, &adapter);
}
