// 02 · 第一个程序——print、字符串插值、顶层代码、纯函数组织
// 本教程每个示例 = 一个 SPM 可执行目标；核心逻辑写成纯函数供 Tests 目录测试。

import Foundation

// ═══ 2.1 纯函数（教学惯例：能测的逻辑不写在语句里）
func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

func greet(_ name: String) -> String {
    "你好，\(name)！"
}

func farewell(_ name: String) -> String {
    """
    再见，\(name)。
    欢迎回来。
    """
}

// ═══ 2.2 print 与字符串插值：\(表达式) 可放任意表达式
precondition(add(2, 3) == 5, "add 断言失败")
print(greet("Swift"))
print("add(2, 3) = \(add(2, 3))，即插值里可以调用函数")

// ═══ 2.3 多行字符串字面量（三个引号，缩进按结尾引号对齐裁剪）
print(farewell("世界"))

// ═══ 2.4 Unicode 是一等公民（源码 UTF-8，字面量无需转义）
let emoji = "🚀"
print("Swift \(emoji) 一步一个脚印")
print("字符串插值支持转义：\(emoji) 制表符→\t行尾")

print("==== 02 结束 ====")
