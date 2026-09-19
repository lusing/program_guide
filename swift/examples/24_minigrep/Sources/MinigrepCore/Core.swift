// MinigrepCore：全部可测逻辑（无 IO 的部分纯函数化，IO 部分薄封装）
import Foundation

// MARK: - 数据模型（报告即 Codable——20 章的落地）

public struct Match: Codable, Equatable, Sendable {
    public let path: String
    public let lineNumber: Int
    public let lineText: String

    public init(path: String, lineNumber: Int, lineText: String) {
        self.path = path
        self.lineNumber = lineNumber
        self.lineText = lineText
    }
}

public struct SearchReport: Codable, Equatable, Sendable {
    public let pattern: String
    public let caseInsensitive: Bool
    public let filesScanned: Int
    public let filesWithMatches: Int
    public let totalMatches: Int
    public let matches: [Match]

    public init(
        pattern: String, caseInsensitive: Bool, filesScanned: Int,
        filesWithMatches: Int, totalMatches: Int, matches: [Match]
    ) {
        self.pattern = pattern
        self.caseInsensitive = caseInsensitive
        self.filesScanned = filesScanned
        self.filesWithMatches = filesWithMatches
        self.totalMatches = totalMatches
        self.matches = matches
    }
}

// MARK: - 匹配逻辑（纯函数）

/// 一段文本里命中模式的所有行（行号从 1 起）
public func matchLines(in text: String, pattern: String, caseInsensitive: Bool) -> [(
    line: Int, text: String
)] {
    var hits: [(Int, String)] = []
    let needle = caseInsensitive ? pattern.lowercased() : pattern
    for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
    {
        let haystack = caseInsensitive ? line.lowercased() : String(line)
        if haystack.contains(needle) {
            hits.append((index + 1, String(line)))
        }
    }
    return hits
}

/// 单文件搜索（IO 边界：读文件 → 纯函数 → Match 列表）
public func searchFile(at url: URL, pattern: String, caseInsensitive: Bool) throws -> [Match] {
    let text = try String(contentsOf: url, encoding: .utf8)
    return matchLines(in: text, pattern: pattern, caseInsensitive: caseInsensitive)
        .map { Match(path: url.path, lineNumber: $0.line, lineText: $0.text) }
}

/// 递归收集文本文件（扩展名过滤；结果排序保证确定）
public func collectTextFiles(root: URL, extensions: [String]) throws -> [URL] {
    let wanted = Set(extensions)
    var files: [URL] = []
    guard
        let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles])
    else {
        return []
    }
    for case let url as URL in enumerator {
        let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
        guard values?.isRegularFile == true else { continue }
        if wanted.isEmpty || wanted.contains(url.pathExtension.lowercased()) {
            files.append(url)
        }
    }
    return files.sorted { $0.standardizedFileURL.path < $1.standardizedFileURL.path }
}

/// 聚合成报告（结果排序：路径 → 行号——并发完成顺序无关）
public func aggregate(
    pattern: String, caseInsensitive: Bool,
    fileResults: [(url: URL, matches: [Match])]
) -> SearchReport {
    let sorted = fileResults.sorted { $0.url.path < $1.url.path }
    let allMatches = sorted.flatMap(\.matches)
    return SearchReport(
        pattern: pattern,
        caseInsensitive: caseInsensitive,
        filesScanned: sorted.count,
        filesWithMatches: sorted.filter { !$0.matches.isEmpty }.count,
        totalMatches: allMatches.count,
        matches: allMatches)
}

// MARK: - 展示（纯函数）

/// ANSI 高亮：首个命中片段包红色加粗（31;1），0 复位。
/// 大小写不敏感用 range(of:options:) 原生支持——在原串上找，索引天然对齐。
public func highlighted(_ line: String, pattern: String, caseInsensitive: Bool) -> String {
    let options: String.CompareOptions = caseInsensitive ? [.caseInsensitive] : []
    guard let range = line.range(of: pattern, options: options) else {
        return line
    }
    return line[..<range.lowerBound] + "\u{1B}[31;1m" + line[range] + "\u{1B}[0m"
        + line[range.upperBound...]
}

/// 退出码约定（grep 家族惯例）：0 找到 / 1 没找到 / 2 用法错误
public func exitCode(for report: SearchReport) -> Int32 {
    report.totalMatches > 0 ? 0 : 1
}
