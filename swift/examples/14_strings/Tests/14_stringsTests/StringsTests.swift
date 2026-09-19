// 14_strings 的 swift-testing 测试
import Testing

@testable import Ch14Strings

@Test func 回文判断() {
    #expect(isPalindrome("上海自来水来自海上"))
    #expect(isPalindrome("a b a"))
    #expect(!isPalindrome("Swift"))
    #expect(isPalindrome(""))
}

@Test func 姓名缩写() {
    #expect(initials("Donald Ervin Knuth") == "D.E.K")
    #expect(initials("李白") == "李")
    #expect(initials("a b") == "a.b")
}

@Test func 截断加省略号() {
    #expect(truncated("abcdef", to: 3) == "abc…")
    #expect(truncated("短", to: 3) == "短")
    #expect(truncated("", to: 0) == "")  // count(0) 不大于 limit(0)，原样返回
}

@Test func grapheme等价() {
    let cafeA = "cafe\u{301}"  // e + 组合音符（6 字节）
    let cafeB = "café"  // 预组合 é（5 字节）
    #expect(cafeA.count == cafeB.count)  // 都是 4 个字符
    #expect(cafeA == cafeB)  // 规范等价
    #expect(cafeA.utf8.count == 6)
    #expect(cafeB.utf8.count == 5)
    #expect("👨‍👩‍👧‍👦".count == 1)
    #expect("🇨🇳🇯🇵".count == 2)
}

@Test func stringIndex访问() {
    let poem = "海内存知己"
    let second = poem.index(poem.startIndex, offsetBy: 1)
    #expect(poem[second] == "内")
    #expect(String(poem.reversed()) == "己知存内海")
}

@Test func substring视图() {
    let sentence = "Swift 字符串"
    let first = sentence.prefix(5)
    #expect(first == "Swift")
    #expect(String(first) == "Swift")
    #expect(sentence.hasSuffix("字符串"))
}

@Test func regex匹配() {
    #expect(countMatches(of: /\d+/, in: "a1 b22 c333") == 3)
    #expect(extractYears("2019年与2024年") == [2019, 2024])
    #expect(extractYears("没有年份") == [])
    #expect("010-88886666".contains(/\d{3}-\d{8}/))
}
