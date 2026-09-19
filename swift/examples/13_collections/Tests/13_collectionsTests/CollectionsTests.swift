// 13_collections 的 swift-testing 测试
import Testing

@testable import Ch13Collections

@Test func 词频统计() {
    let freq = wordFrequency("to be or not to be")
    #expect(freq["to"] == 2)
    #expect(freq["be"] == 2)
    #expect(freq["or"] == 1)
    #expect(freq.count == 4)
    #expect(wordFrequency("").isEmpty)
}

@Test func 高频词排序() {
    let freq = ["b": 2, "a": 2, "c": 5]
    let top = topWords(freq, limit: 2)
    #expect(top.first?.word == "c")
    #expect(top.map(\.word) == ["c", "a"])  // 同次数按字典序：a < b
    #expect(topWords(freq, limit: 10).count == 3)
}

@Test func set去重排序() {
    #expect(uniqueSorted([5, 3, 3, 1, 5, 2]) == [1, 2, 3, 5])
    #expect(uniqueSorted([]) == [])
    #expect(uniqueSorted([7, 7, 7]) == [7])
}

@Test func 字典合并() {
    let merged = mergeCounts(["a": 1, "b": 2], ["b": 3, "c": 4])
    #expect(merged == ["a": 1, "b": 5, "c": 4])
    #expect(mergeCounts([:], ["x": 1]) == ["x": 1])
}

@Test func 切片索引陷阱() {
    let numbers = [10, 20, 30, 40, 50]
    let slice = numbers[1..<4]
    #expect(slice.count == 3)
    #expect(slice.startIndex == 1)  // 切片继承原索引，不是 0！
    #expect(slice[slice.startIndex] == 20)
    #expect(Array(slice)[0] == 20)  // 转正后索引重置
}

@Test func 数组值语义() {
    var original = [1, 2, 3]
    let copy = original
    original.append(4)
    #expect(copy == [1, 2, 3])
    #expect(original == [1, 2, 3, 4])
}

@Test func chunked分块() {
    #expect([1, 2, 3, 4, 5].chunked(by: 2) == [[1, 2], [3, 4], [5]])
    #expect(Array(1...8).chunked(by: 4) == [[1, 2, 3, 4], [5, 6, 7, 8]])
    #expect([Int]().chunked(by: 3) == [])
}
