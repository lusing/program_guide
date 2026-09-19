// 19 · 文件与 IO——URL、Data、String 读写、FileManager、临时目录、Windows 路径坑

import Foundation

// ═══ 19.1 纯函数区（供测试）
func makeScratchDir() -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-guide-19", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

func writeText(_ text: String, to file: URL) throws {
    try text.write(to: file, atomically: true, encoding: .utf8)
}

func readText(from file: URL) throws -> String {
    try String(contentsOf: file, encoding: .utf8)
}

func writeBinary(_ bytes: [UInt8], to file: URL) throws {
    try Data(bytes).write(to: file)
}

func listFiles(in dir: URL, extension ext: String) throws -> [String] {
    let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    return
        urls
        .filter { $0.pathExtension == ext }
        .map(\.lastPathComponent)
        .sorted()
}

func countLines(_ text: String) -> Int {
    text.split(separator: "\n", omittingEmptySubsequences: false).count
}

func joinPath(_ parts: [String]) -> String {
    parts.joined(separator: "/")  // URL 会自动处理分隔符——见 19.5
}

// ═══ 19.2 URL：路径的强类型形态
let scratch = makeScratchDir()
let file = scratch.appendingPathComponent("笔记.txt")
print("① 临时文件路径：\(file.path)")
precondition(file.pathExtension == "txt")
precondition(file.lastPathComponent == "笔记.txt")
precondition(file.isFileURL)

// ═══ 19.3 文本读写：一行一个 API
let poem = "床前明月光\n疑是地上霜\n举头望明月\n低头思故乡"
try writeText(poem, to: file)
let loaded = try readText(from: file)
precondition(loaded == poem)
print("② 写入并读回 \(countLines(loaded)) 行（逐字节一致）")

// ═══ 19.4 二进制读写：Data 是字节袋
let bin = scratch.appendingPathComponent("数据.bin")
try writeBinary([0x48, 0x65, 0x6C, 0x6C, 0x6F], to: bin)
let data = try Data(contentsOf: bin)
precondition(data == Data("Hello".utf8))
print("③ 二进制 \(data.count) 字节 = \(String(data: data, encoding: .utf8)!)")

// ═══ 19.5 目录操作：遍历、创建、删除
for i in 1...3 {
    try writeText("第 \(i) 份", to: scratch.appendingPathComponent("报告-\(i).txt"))
}
let names = try listFiles(in: scratch, extension: "txt")
print("④ 目录里 \(names.count) 个 txt：\(names)")
precondition(names.contains("笔记.txt") && names.contains("报告-2.txt"))

let sub = scratch.appendingPathComponent("归档", isDirectory: true)
try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
precondition(FileManager.default.fileExists(atPath: sub.path))
try writeText("归档内容", to: sub.appendingPathComponent("旧档.txt"))
let nested = try listFiles(in: sub, extension: "txt")
precondition(nested == ["旧档.txt"])
print("⑤ 子目录创建 + 嵌套写入：\(nested)")

// ═══ 19.6 Windows 路径坑：分隔符交给 URL，别手拼
let manual = joinPath(["C:", "Users", "文档"])
print("⑥ 手拼路径（反斜杠才对）：\(manual) —— Windows 上不是合法路径")
precondition(manual.contains("/"))  // 字符串拼接不处理分隔符
let viaURL = URL(fileURLWithPath: "C:\\Users").appendingPathComponent("文档").path
print("   URL 拼接：\(viaURL) —— 自动用 \\ 且处理盘符")
precondition(viaURL.hasSuffix("文档"))

// ═══ 19.7 清理（教学纪律：示例不留垃圾）
try FileManager.default.removeItem(at: scratch)
precondition(!FileManager.default.fileExists(atPath: scratch.path))
print("⑦ 清理完成")

print("==== 19 结束 ====")
