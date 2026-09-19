// 02 · 第一个程序——冒烟版（正文 Task 2 完善为教学全量）
// 三种运行形态见 docs/02-hello.md：REPL / swift 直接解释 / 编译运行

import Foundation

// ═══ 2.1 可测试的纯函数（Tests 目录会 @testable import 本模块）
func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

func greet(_ name: String) -> String {
    "你好，\(name)！"
}

// ═══ 2.2 演示输出 + 关键路径自检
precondition(add(2, 3) == 5, "add 断言失败")
print(greet("Swift"))
print("add(2, 3) = \(add(2, 3))")

print("==== 02 结束 ====")
