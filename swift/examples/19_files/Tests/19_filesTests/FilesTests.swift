import Foundation
// 19_files 的 swift-testing 测试
import Testing

@testable import Ch19Files

@Test func 文本往返() throws {
    let file = makeScratchDir().appendingPathComponent("t.txt")
    defer { try? FileManager.default.removeItem(at: file) }
    try writeText("你好\nSwift", to: file)
    #expect(try readText(from: file) == "你好\nSwift")
    #expect(countLines("a\nb\nc") == 3)
    #expect(countLines("没有换行") == 1)
    #expect(countLines("") == 1)  // 实测：空串 split(omittingEmptySubsequences:false) 得 [""]，按一行计
}

@Test func 二进制往返() throws {
    let file = makeScratchDir().appendingPathComponent("b.bin")
    defer { try? FileManager.default.removeItem(at: file) }
    try writeBinary([1, 2, 3, 255], to: file)
    #expect(try Data(contentsOf: file) == Data([1, 2, 3, 255]))
    #expect(try Data(contentsOf: file).count == 4)
}

@Test func 目录列表() throws {
    let dir = makeScratchDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    try writeText("x", to: dir.appendingPathComponent("乙.txt"))
    try writeText("x", to: dir.appendingPathComponent("甲.txt"))
    try writeText("x", to: dir.appendingPathComponent("丙.dat"))
    #expect(try listFiles(in: dir, extension: "txt") == ["乙.txt", "甲.txt"])  // 排序后确定
    #expect(try listFiles(in: dir, extension: "dat") == ["丙.dat"])
    #expect(try listFiles(in: dir, extension: "none") == [])
}

@Test func 子目录创建() throws {
    let dir = makeScratchDir().appendingPathComponent("级1", isDirectory: true)
        .appendingPathComponent("级2", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: makeScratchDir()) }
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    #expect(FileManager.default.fileExists(atPath: dir.path))
}

@Test func url分解() {
    let url = URL(fileURLWithPath: "C:\\tmp").appendingPathComponent("报告.final.md")
    #expect(url.lastPathComponent == "报告.final.md")
    #expect(url.pathExtension == "md")
    #expect(url.isFileURL)
}

@Test func joinPath是纯字符串拼接() {
    #expect(joinPath(["a", "b"]) == "a/b")
    #expect(!joinPath(["C:", "x"]).hasPrefix("\\\\"))
}
