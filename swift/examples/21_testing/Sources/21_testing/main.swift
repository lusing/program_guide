// 21 · 测试——swift-testing 深入（参数化/suite/tag）。本章的 Tests 目录本身就是教材！
// 运行方式：swift test --filter Ch21TestingTests；看 Tests/21_testingTests/TestingTests.swift

import Foundation

// ═══ 21.1 被测代码：成绩评级 + 罗马数字（参数化测试的好素材）
func letterGrade(_ score: Int) -> String {
    switch score {
    case ..<0: return "无效"
    case 0..<60: return "F"
    case 60..<70: return "D"
    case 70..<80: return "C"
    case 80..<90: return "B"
    case 90...100: return "A"
    default: return "无效"
    }
}

func romanNumeral(_ number: Int) -> String {
    precondition((1...3999).contains(number), "罗马数字范围 1...3999")
    let table: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]
    var remaining = number
    var result = ""
    for (value, symbol) in table where remaining > 0 {
        while remaining >= value {
            result += symbol
            remaining -= value
        }
    }
    return result
}

/// 纯函数 + 边界：回文检查（中文/英文/空白）
func isPalindromeWord(_ text: String) -> Bool {
    let chars = Array(text.lowercased().filter { $0.isLetter })  // 先转数组（14 章惯用法）
    return !chars.isEmpty && chars == chars.reversed()
}

// ═══ 21.2 演示输出（教学主体在测试文件里）
print("letterGrade(85) = \(letterGrade(85))")
precondition(letterGrade(85) == "B")
print("romanNumeral(2024) = \(romanNumeral(2024))")
precondition(romanNumeral(2024) == "MMXXIV")
print("isPalindromeWord(\"Level\") = \(isPalindromeWord("Level"))")
precondition(isPalindromeWord("Level") && !isPalindromeWord("Swift"))

print("==== 21 结束 ====")
