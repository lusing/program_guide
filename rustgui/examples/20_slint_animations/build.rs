fn main() {
    let config = slint_build::CompilerConfiguration::new().with_debug_info(true);
    slint_build::compile_with_config("ui/anim.slint", config).expect("slint 编译失败");
}
