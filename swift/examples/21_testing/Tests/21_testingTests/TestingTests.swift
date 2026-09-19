// 21_testing 的 swift-testing 测试——本章的"正文"就是这些测试的写法本身
// swift-testing 三板斧：@Test 宏、#expect/#require 宏、参数化
import Testing

@testable import Ch21Testing

// ═══ 21.1 基本：@Test + #expect
@Test func 基本断言() {
    #expect(letterGrade(85) == "B")
    #expect(1 + 1 == 2)
}

// ═══ 21.2 参数化：一个 @Test 跑一组用例（失败各自报告，不互相拖累）
@Test(
    "letterGrade 边界表",
    arguments: [
        (-1, "无效"), (0, "F"), (59, "F"), (60, "D"), (69, "D"),
        (70, "C"), (79, "C"), (80, "B"), (89, "B"), (90, "A"),
        (100, "A"), (101, "无效"),
    ])
func letterGrade边界(score: Int, expected: String) {
    #expect(letterGrade(score) == expected)
}

// ═══ 21.3 参数化的另一种形：zip 两个序列
@Test(arguments: zip(1...10, ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]))
func roman基础(number: Int, numeral: String) {
    #expect(romanNumeral(number) == numeral)
}

@Test(arguments: [4, 9, 40, 90, 400, 900])
func roman减法规则(number: Int) {
    let result = romanNumeral(number)
    #expect(!result.isEmpty)
    #expect(romanNumeral(number * 2).count >= result.count)
}

// ═══ 21.4 Suite：把一组测试打包（可挂 tags/特征、共享辅助函数）
@Suite("罗马数字全套")
struct RomanSuite {
    @Test func 千位() { #expect(romanNumeral(3999) == "MMMCMXCIX") }
    @Test func 一() { #expect(romanNumeral(1) == "I") }
    @Test func 年份() { #expect(romanNumeral(2024) == "MMXXIV") }
}

@Suite("回文检查")
struct PalindromeSuite {
    @Test("英文忽略大小写") func english() { #expect(isPalindromeWord("Level")) }
    @Test("中文") func chinese() { #expect(isPalindromeWord("上海自来水来自海上")) }
    @Test("非回文") func negative() { #expect(!isPalindromeWord("Swift")) }
    @Test("纯标点按空串处理") func punctuation() { #expect(!isPalindromeWord("!!")) }
}

// ═══ 21.5 throws 测试 + #require（失败即停，后续断言不再跑）
@Test func require失败即停() throws {
    let scores = [88, 92, 79]
    let first = try #require(scores.first)
    #expect(first == 88)
}

// ═══ 21.6 Tag：跨 suite 的分类标记（CI 里按 tag 挑跑/跳过）
@Suite struct TaggedSuite {
    @Test(.tags(.slow)) func 慢速用例() {
        var total = 0
        for i in 1...1000 { total += i }
        #expect(total == 500500)
    }

    @Test func 快速用例() { #expect(letterGrade(95) == "A") }
}

extension Tag {
    @Tag static var slow: Self
}

// ═══ 21.7 异步测试（17/18 章的测试都是这么写的）
@Test func 异步测试形态() async {
    let sum = await withTaskGroup(of: Int.self) { group in
        for i in 1...10 {
            group.addTask { i * i }
        }
        var total = 0
        for await value in group { total += value }
        return total
    }
    #expect(sum == 385)  // 1²+2²+…+10²
}
