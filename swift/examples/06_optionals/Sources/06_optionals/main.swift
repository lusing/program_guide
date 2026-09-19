// 06 · 可选类型——?/!、解包四式、可选链、??、map/compactMap

import Foundation

// ═══ 6.1 纯函数区（供测试）：查找类操作天然返回可选
struct Student {
    let name: String
    let score: Int?
}

// Swift 6 严格并发：main.swift 顶层 let 是 MainActor 隔离的，非隔离函数不能引用。
// 全局常数的正身 = enum 命名空间 + static let（Sendable 值随处可用）。
enum Registry {
    static let roster = [
        Student(name: "小明", score: 92),
        Student(name: "小红", score: nil),
        Student(name: "小刚", score: 58),
    ]
}

func findStudent(_ name: String) -> Student? {
    Registry.roster.first { $0.name == name }
}

func scoreOf(_ name: String) -> Int? {
    findStudent(name)?.score  // 可选链：两级查找，任一环 nil 整条 nil
}

func gradeOf(_ name: String) -> String {
    guard let score = scoreOf(name) else { return "无成绩" }
    return score >= 60 ? "及格" : "不及格"
}

func parseAge(_ text: String) -> Int? {
    Int(text)
}

func firstWord(of sentence: String) -> String? {
    let words = sentence.split(separator: " ")
    return words.first.map(String.init)  // map：有值才变换
}

func allScores(_ students: [Student]) -> [Int] {
    students.compactMap(\.score)  // compactMap：过滤 nil 只留有值
}

func describe(_ value: Int?) -> String {
    value.map(String.init) ?? "nil"
}

// ═══ 6.2 解包四式：if let / guard let / ?? / 强制解包
if let score = scoreOf("小明") {
    print("if let：小明 \(score) 分")
}
print("?? 默认：小红 \(scoreOf("小红") ?? 0) 分")
print("强制解包（确知有值时才可）：小明 \(scoreOf("小明")!) 分")
precondition(scoreOf("小红") == nil, "nil 断言失败")

// ═══ 6.3 可选链：连环调用一处 nil 全链 nil
print("小明成绩等级：\(gradeOf("小明"))")
print("小红成绩等级：\(gradeOf("小红"))")
print("查无此人等级：\(gradeOf("小亮"))")

// ═══ 6.4 构造器返回可选（失败是正常业务，不是异常）
print("parseAge(\"42\") = \(parseAge("42") ?? -1)")
print("parseAge(\"四十二\") = \(parseAge("四十二") ?? -1)")
precondition(parseAge("abc") == nil)

// ═══ 6.5 map / flatMap（链式变换不塌陷）
print("firstWord(\"hello swift world\") = \(firstWord(of: "hello swift world") ?? "")")
let doubled = parseAge("21").map { $0 * 2 }  // map：Int? 变换后仍是 Int?（Optional(42)）
print("21.map ×2 = \(describe(doubled))")
let firstChar = firstWord(of: "hello world").flatMap { $0.first }
// flatMap：变换本身返回 Character?，结果摊平成 Character? 而非 Character??
print("首字符 = \(firstChar.map(String.init) ?? "无")")
precondition(firstChar == "h")

// ═══ 6.6 compactMap：把 [T?] 洗成 [T]
let scores = allScores(Registry.roster)
print("全部有效成绩：\(scores)（小红被过滤）")
precondition(scores == [92, 58])

print("==== 06 结束 ====")
