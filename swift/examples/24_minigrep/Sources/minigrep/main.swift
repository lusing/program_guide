// minigrep：CLI 薄壳——参数解析 → TaskGroup 并发搜索 → 展示/报告（逻辑全在 MinigrepCore）
import Foundation
import MinigrepCore

// ═══ 参数解析（用法：minigrep <pattern> [path] [--json] [-i] [-e 扩展名,…]）
let arguments = Array(CommandLine.arguments.dropFirst())
var pattern = ""
var root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var asJSON = false
var caseInsensitive = false
var extensions: [String] = ["txt", "md", "swift"]

var index = 0
while index < arguments.count {
    let arg = arguments[index]
    switch arg {
    case "--json":
        asJSON = true
    case "-i":
        caseInsensitive = true
    case "-e":
        index += 1
        guard index < arguments.count else {
            print("错误：-e 需要扩展名列表")
            exit(2)
        }
        extensions = arguments[index].split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
    default:
        if pattern.isEmpty {
            pattern = arg
        } else {
            root = URL(fileURLWithPath: arg)
        }
    }
    index += 1
}

guard !pattern.isEmpty else {
    print("用法：minigrep <pattern> [path] [--json] [-i] [-e txt,md,swift]")
    print("  搜索当前目录（或指定 path）下的文本文件，打印高亮命中行")
    print("  --json  输出 JSON 报告（20 章 Codable）")
    print("  -i      忽略大小写")
    print("  -e      扩展名过滤（默认 txt,md,swift）")
    print("退出码：0 找到 / 1 未找到 / 2 用法错误")
    exit(2)
}

// ═══ 收集文件 → TaskGroup 并发搜单文件 → 聚合（17/18 章落地）
// 顶层 var 是 MainActor 隔离的（06 章坑）——进并发闭包前拷贝成本地 let
let needle = pattern
let ignoreCase = caseInsensitive
let files = try collectTextFiles(root: root, extensions: extensions)

let fileResults: [(url: URL, matches: [Match])] = await withTaskGroup(
    of: (URL, [Match]).self
) { group in
    for file in files {
        group.addTask {
            let matches =
                (try? searchFile(at: file, pattern: needle, caseInsensitive: ignoreCase)) ?? []
            return (file, matches)
        }
    }
    var collected: [(URL, [Match])] = []
    for await result in group {
        collected.append(result)
    }
    return collected  // 完成顺序不定——aggregate 内部排序保确定
}

let report = aggregate(pattern: pattern, caseInsensitive: caseInsensitive, fileResults: fileResults)

// ═══ 输出：文本（高亮）或 JSON 报告
if asJSON {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .secondsSince1970
    let data = try encoder.encode(report)
    print(String(data: data, encoding: .utf8)!)
} else {
    for match in report.matches {
        print(
            "\(match.path):\(match.lineNumber): \(highlighted(match.lineText, pattern: pattern, caseInsensitive: caseInsensitive))"
        )
    }
    print("── \(report.totalMatches) 处命中 / \(report.filesWithMatches)/\(report.filesScanned) 个文件")
    print("==== 24 结束 ====")
}

exit(exitCode(for: report))
