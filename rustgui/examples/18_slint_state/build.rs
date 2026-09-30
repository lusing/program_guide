fn main() {
    // with_debug_info：编译期把元素 id/类型信息写进生成代码，
    // i-slint-backend-testing 的 ElementHandle 查询 API 依赖它
    let config = slint_build::CompilerConfiguration::new().with_debug_info(true);
    slint_build::compile_with_config("ui/unit.slint", config).expect("slint 编译失败");
}
