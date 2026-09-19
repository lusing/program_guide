// 06_optionals 的 swift-testing 测试
import Testing

@testable import Ch06Optionals

@Test func 查找返回可选() {
    #expect(findStudent("小明")?.name == "小明")
    #expect(findStudent("小亮") == nil)
}

@Test func 可选链两级查找() {
    #expect(scoreOf("小明") == 92)
    #expect(scoreOf("小红") == nil)  // 学生在册但无成绩
    #expect(scoreOf("小亮") == nil)  // 学生不在册
}

@Test func guard解包出等级() {
    #expect(gradeOf("小明") == "及格")
    #expect(gradeOf("小刚") == "不及格")
    #expect(gradeOf("小红") == "无成绩")
    #expect(gradeOf("小亮") == "无成绩")
}

@Test func 构造器失败返回nil() {
    #expect(parseAge("42") == 42)
    #expect(parseAge(" 42 ") == nil)  // 有空格也不行——Int(String) 严格
    #expect(parseAge("4.2") == nil)
    #expect(parseAge("") == nil)
}

@Test func map与flatMap() {
    #expect(firstWord(of: "hello swift world") == "hello")
    #expect(firstWord(of: "") == nil)
    #expect(parseAge("21").map { $0 * 2 } == 42)
    #expect(parseAge("x").map { $0 * 2 } == nil)
    #expect(firstWord(of: "hello").flatMap { $0.first } == "h")
}

@Test func compactMap过滤nil() {
    #expect(allScores(Registry.roster) == [92, 58])
    #expect(allScores([]) == [])
}
