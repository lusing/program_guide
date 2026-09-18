//! 21 · 测试 ⭐（入口演示）：跑一遍库函数，顺便展示 --nocapture 的输出

use testing_demo::{add, checked_div, div};

fn main() {
    println!("add(20, 22)  = {}", add(20, 22));
    println!("div(7, 2)    = {}", div(7, 2));
    println!("checked_div(1, 0) = {:?}", checked_div(1, 0));

    // cargo test -- --nocapture 能看到测试里的 stdout；
    // 默认情况下测试只有失败时才打印输出。
    println!("（这是 main 的输出，不受 --nocapture 影响）");
}
