//! report：二进制 crate——依赖同 workspace 的 geometry 库。

use geometry::{circle_area, rect_area};

fn main() {
    println!("== 几何报表（依赖 workspace 内的 geometry 库）==");
    println!("  圆 r=2        面积 {:.4}", circle_area(2.0));
    println!("  矩形 3×4      面积 {:.4}", rect_area(3.0, 4.0));

    // advanced feature 由本 crate 的依赖声明开启，编译期即可用
    let pentagon = [(0.0, 0.0), (2.0, 0.0), (3.0, 1.5), (1.0, 3.0), (-1.0, 1.5)];
    let area = geometry::advanced::polygon_area(&pentagon);
    println!("  五边形        面积 {:.4}（advanced feature）", area);

    // 编译期探测当前 profile：cargo run 是 debug，cargo run --release 是 release
    if cfg!(debug_assertions) {
        println!("  [debug 构建：未优化 + 调试断言全开]");
    } else {
        println!("  [release 构建：--release 产物]");
    }

    // 完整命令速记（docs/17-cargo.md 有详解）：
    //   cargo build -p geometry        只构建某个成员
    //   cargo test  --workspace        全部成员的测试
    //   cargo tree  -p report          依赖树
    //   cargo doc    --open            生成并浏览文档
    //   cargo build --release          发布构建（走 workspace 的 profile）
}
