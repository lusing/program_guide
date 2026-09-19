import Foundation
// MinigrepCore 的 swift-testing 测试：匹配/聚合/高亮/退出码全覆盖
import Testing

@testable import MinigrepCore

let sampleText = """
    lorem ipsum dolor sit amet
    LOREM 大写开头也命中（-i 时）
    第二行没有目标词
    lorem 出现在句首
    尾行 ipsum lorem ipsum
    """

@Test func 行匹配() {
    let hits = matchLines(in: sampleText, pattern: "lorem", caseInsensitive: false)
    #expect(hits.map(\.line) == [1, 4, 5])  // 大写 LOREM 不命中
    let ci = matchLines(in: sampleText, pattern: "lorem", caseInsensitive: true)
    #expect(ci.map(\.line) == [1, 2, 4, 5])  // -i 时第 2 行也命中
}

@Test func 空文本无命中() {
    #expect(matchLines(in: "", pattern: "x", caseInsensitive: false).isEmpty)
    #expect(matchLines(in: sampleText, pattern: "不存在", caseInsensitive: false).isEmpty)
}

@Test func 单文件搜索() throws {
    let file = FileManager.default.temporaryDirectory
        .appendingPathComponent("mg-test-\(UUID().uuidString).txt")
    defer { try? FileManager.default.removeItem(at: file) }
    try sampleText.write(to: file, atomically: true, encoding: .utf8)
    let matches = try searchFile(at: file, pattern: "lorem", caseInsensitive: false)
    #expect(matches.count == 3)
    #expect(matches.first?.lineNumber == 1)
    #expect(matches.first?.lineText.contains("ipsum") == true)
}

@Test func 聚合排序与统计() {
    let fileA = URL(fileURLWithPath: "/tmp/b.txt")  // 注意：b < c，故意乱序输入
    let fileB = URL(fileURLWithPath: "/tmp/c.txt")
    let report = aggregate(
        pattern: "lorem", caseInsensitive: false,
        fileResults: [
            (
                fileB,
                [
                    Match(path: fileB.path, lineNumber: 1, lineText: "lorem x"),
                    Match(path: fileB.path, lineNumber: 2, lineText: "lorem y"),
                ]
            ),
            (fileA, []),
        ])
    #expect(report.filesScanned == 2)
    #expect(report.filesWithMatches == 1)
    #expect(report.totalMatches == 2)
    #expect(report.matches.map(\.path) == [fileB.path, fileB.path])  // 输入顺序无关
}

@Test func 高亮包裹首命中() {
    let line = "前缀 lorem 后缀"
    let marked = highlighted(line, pattern: "lorem", caseInsensitive: false)
    #expect(marked.contains("\u{1B}[31;1mlorem\u{1B}[0m"))
    #expect(marked.hasPrefix("前缀 \u{1B}[31;1m"))  // 前缀原样 + 紧接染色开始
    #expect(marked.hasSuffix("\u{1B}[0m 后缀"))
    #expect(highlighted(line, pattern: "zzz", caseInsensitive: false) == line)  // 无命中原样返回
}

@Test func 高亮大小写不敏感() {
    let marked = highlighted("LOREM", pattern: "lorem", caseInsensitive: true)
    #expect(marked.contains("\u{1B}[31;1mLOREM\u{1B}[0m"))
}

@Test func 退出码约定() {
    let found = SearchReport(
        pattern: "x", caseInsensitive: false, filesScanned: 1,
        filesWithMatches: 1, totalMatches: 3, matches: [])
    let none = SearchReport(
        pattern: "x", caseInsensitive: false, filesScanned: 1,
        filesWithMatches: 0, totalMatches: 0, matches: [])
    #expect(exitCode(for: found) == 0)
    #expect(exitCode(for: none) == 1)
}

@Test func 报告可JSON往返() throws {
    let report = SearchReport(
        pattern: "lorem", caseInsensitive: true, filesScanned: 2,
        filesWithMatches: 1, totalMatches: 1,
        matches: [Match(path: "a.txt", lineNumber: 3, lineText: "lorem")])
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let json = String(data: try encoder.encode(report), encoding: .utf8)!
    #expect(json.contains("\"total_matches\"") == false)  // 键名按字段名
    #expect(json.contains("\"totalMatches\":1"))
    let back = try JSONDecoder().decode(SearchReport.self, from: Data(json.utf8))
    #expect(back == report)
}
