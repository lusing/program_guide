// 13 · 集合——Array 深探（切片与索引坑）、Set、Dictionary、常用算法、COW

import Foundation

// ═══ 13.1 纯函数区（供测试）
func wordFrequency(_ text: String) -> [String: Int] {
    var counts: [String: Int] = [:]
    for word in text.split(whereSeparator: { $0.isWhitespace }) {
        counts[String(word), default: 0] += 1
    }
    return counts
}

func topWords(_ counts: [String: Int], limit: Int) -> [(word: String, count: Int)] {
    counts
        .sorted {
            $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key
        }  // 次数降序；同次数按字典序升序
        .prefix(limit)
        .map { (word: $0.key, count: $0.value) }
}

func uniqueSorted(_ numbers: [Int]) -> [Int] {
    Array(Set(numbers)).sorted()
}

func mergeCounts(_ a: [String: Int], _ b: [String: Int]) -> [String: Int] {
    var result = a
    for (key, value) in b {
        result[key, default: 0] += value
    }
    return result
}

extension Array {
    /// 把数组按固定大小分块（extension 能力的一个小样例，15 章专题）
    func chunked(by size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// ═══ 13.2 Array：值语义 + COW 的直观体验
var original = [1, 2, 3, 4, 5]
let copy = original  // O(1)：只共享缓冲 + 引用计数
original.append(6)  // 此刻才真正复制（COW 触发）
print("original=\(original) copy=\(copy)（拷贝没被追加污染）")
precondition(copy == [1, 2, 3, 4, 5])

// ═══ 13.3 切片：最大的索引坑
let slice = original[1..<4]  // [2, 3, 4]
print("slice=\(slice)")
precondition(slice.count == 3)
// slice[0]  // ❌ 崩溃！切片的 startIndex 不是 0，而是 1（继承原数组索引）
precondition(slice[slice.startIndex] == 2)  // ✅ 永远用 startIndex/indices 访问
precondition(Array(slice) == [2, 3, 4])  // 转正后索引重置
let fromZero = Array(slice)
precondition(fromZero[0] == 2)

// ═══ 13.4 Set：无序去重 + 集合代数
let primes: Set = [2, 3, 5, 7, 11]
let odds: Set = [1, 3, 5, 7, 9]
print("并集 \(primes.union(odds).sorted())")
print("交集 \(primes.intersection(odds).sorted())")
print("差集 \(primes.subtracting(odds).sorted())")
precondition(primes.union(odds).count == 7)
precondition(primes.intersection(odds) == [3, 5, 7])
precondition(primes.subtracting(odds) == [2, 11])
precondition(uniqueSorted([5, 3, 3, 1, 5, 2]) == [1, 2, 3, 5])
print("subset 检查：\(Set([3, 5]).isSubset(of: primes))")

// ═══ 13.5 Dictionary：键值对的默认值惯用法
let freq = wordFrequency("to be or not to be that is the question")
print("词频条数 \(freq.count)：to=\(freq["to"]!) be=\(freq["be"]!)")
precondition(freq["to"] == 2 && freq["be"] == 2 && freq["question"] == 1)
precondition(freq["swift"] == nil)  // 不存在的键返回 nil（不是崩溃）
let merged = mergeCounts(["a": 1, "b": 2], ["b": 3, "c": 4])
print("合并字典：\(merged.keys.sorted()) → \(merged["b"]!)")
precondition(merged == ["a": 1, "b": 5, "c": 4])

// 遍历无序，要序先排
for (word, count) in topWords(freq, limit: 3) {
    print("  高频：\(word) ×\(count)")
}
precondition(topWords(freq, limit: 1).first?.word == "be")  // be 与 to 同为 2 次，字典序 be < to

// ═══ 13.6 常用算法速览
var numbers = [5, 2, 8, 1, 9, 3]
numbers.sort()  // 原地排序（mutating）
precondition(numbers == [1, 2, 3, 5, 8, 9])
precondition(numbers.first == 1 && numbers.last == 9)
precondition(numbers.contains(8) && !numbers.contains(4))
precondition(numbers.min() == 1 && numbers.max() == 9)
precondition(numbers.firstIndex(of: 8) == 4)  // 数组下标是 Int
precondition(numbers.reversed().first == 9)
precondition(numbers.filter { $0 > 4 }.reduce(0, +) == 22)
let chunked = numbers.chunked(by: 4)
print("分块：\(chunked)")
precondition(chunked == [[1, 2, 3, 5], [8, 9]])

print("==== 13 结束 ====")
