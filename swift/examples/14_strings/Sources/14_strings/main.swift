// 14 · 字符串——grapheme cluster、String.Index、Substring、COW、Regex

import Foundation

// ═══ 14.1 纯函数区（供测试）
func isPalindrome(_ text: String) -> Bool {
    let chars = Array(text.filter { !$0.isWhitespace })
    return chars == chars.reversed()
}

func initials(_ name: String) -> String {
    name.split(separator: " ").compactMap(\.first).map(String.init).joined(separator: ".")
}

func truncated(_ text: String, to limit: Int) -> String {
    guard text.count > limit else { return text }
    return String(text.prefix(limit)) + "…"
}

func countMatches(of pattern: some RegexComponent, in text: String) -> Int {
    text.matches(of: pattern).count
}

func extractYears(_ text: String) -> [Int] {
    text.matches(of: /(\d{4})年/).compactMap { Int($0.1) }
}

// ═══ 14.2 grapheme cluster：Character 是"用户感知的字"
let cafeA = "cafe\u{301}"  // e + 组合音符 U+0301（两个标量合成一个 é 字位）
let cafeB = "café"  // 预组合的 é（单标量 U+00E9）
print("字节：\(cafeA.utf8.count) vs \(cafeB.utf8.count)，字符：\(cafeA.count) vs \(cafeB.count)")
precondition(cafeA.utf8.count == 6 && cafeB.utf8.count == 5)  // UTF-8 字节数不同
precondition(cafeA.count == cafeB.count)  // 字符数相同（4 个 grapheme）
precondition(cafeA == cafeB)  // 规范等价——字符串相等按 grapheme 判

let family = "👨‍👩‍👧‍👦"  // 一家四口 = 多个标量合成一个 Character
print("emoji 家庭：字节数 \(family.utf8.count)，字符数 \(family.count)")
precondition(family.count == 1)
precondition(family.unicodeScalars.count == 7)

let flags = "🇨🇳🇯🇵"
print("两面旗：字符数 \(flags.count)（每面旗是一个 Character）")
precondition(flags.count == 2)

// ═══ 14.3 String.Index：为什么下标不能用 Int
let poem = "海内存知己"
let second = poem.index(poem.startIndex, offsetBy: 1)
print("第二字：\(poem[second])")
precondition(poem[second] == "内")
// poem[1]  // ❌ 编译错误：String 的下标是 String.Index，不是 Int
let range = second..<poem.index(second, offsetBy: 2)
print("中间两字：\(poem[range])")
precondition(poem[range] == "内存")

// 遍历的惯用法
var collected = ""
for char in poem {
    collected.append(char)
}
precondition(collected == poem)
print("逐字累计：\(collected)")

// ═══ 14.4 Substring：零拷贝切片，用完即弃
let sentence = "Swift 字符串是值类型，但切片是视图"
let firstPart = sentence.prefix(5)  // Substring：共享原串缓冲
print("前 5 个字符：\(firstPart)")
precondition(firstPart == "Swift")
precondition(firstPart is Substring)  // 不是 String！
let converted = String(firstPart)  // 要长期持有就转正（O(n) 拷贝）
precondition(converted == "Swift" && converted is String)

// ═══ 14.5 常用 API 与多行/原始字符串
let raw = #"路径 "C:\tools" 里有 \d 个转义"#
print(#"原始字符串：\#(raw) 里的 \d 不被解释"#)
let multi = """
    第一行
    第二行缩进由结尾引号裁剪
    """
print(multi)
precondition(multi.hasPrefix("第一行") && multi.hasSuffix("裁剪"))

print("isPalindrome(\"上海自来水来自海上\") = \(isPalindrome("上海自来水来自海上"))")
precondition(isPalindrome("上海自来水来自海上"))
precondition(!isPalindrome("Swift"))
print("initials(\"Donald Ervin Knuth\") = \(initials("Donald Ervin Knuth"))")
precondition(initials("Donald Ervin Knuth") == "D.E.K")
print("truncated(\"绕口令吃葡萄不吐葡萄皮\", to: 4) = \(truncated("绕口令吃葡萄不吐葡萄皮", to: 4))")
precondition(truncated("abcdef", to: 3) == "abc…")

// ═══ 14.6 Regex：Swift 5.7 的字面量正则（编译期检查！）
let contact = "电话 010-88886666，邮编 100101，年份 2024年"
let phone = contact.firstMatch(of: /\d{3}-\d{8}/)
print("电话：\(phone?.0 ?? "无")")
precondition(phone?.0 == "010-88886666")
let years = extractYears(contact)
print("年份：\(years)")
precondition(years == [2024])
precondition(countMatches(of: /\d+/, in: "a1 b22 c333") == 3)

// Regex 也能用 try? 动态编译（字符串来源时）；匹配 API 在字符串一侧
if let dynamic = try? Regex("[0-9]+") {
    precondition("x9y".matches(of: dynamic).isEmpty == false)
}

print("==== 14 结束 ====")
