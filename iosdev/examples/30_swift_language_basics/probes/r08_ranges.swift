import Foundation
var c1 = 0; for _ in 1...10 { c1 += 1 }
var c2 = 0; for _ in 1..<10 { c2 += 1 }
var evens: [Int] = []; for n in 1...10 where n % 2 == 0 { evens.append(n) }
var rev: [Int] = []; for n in (1...5).reversed() { rev.append(n) }
var sum = 0; for n in [1, 5, 2, 3, 10, 22, 32] { sum += n }
let r = 1...99
print("1...10 =\(c1)  1..<10 =\(c2)  where 偶数 =\(evens)")
print("reversed 前三个 =\(rev.prefix(3))  数组求和 =\(sum)")
print("range.contains(50)=\(r.contains(50))   lower/upper=\(r.lowerBound)/\(r.upperBound)  类型=\(type(of: r))")
print("reversed 类型=\(type(of: (1...5).reversed()))")
var st: [Int] = []; for n in stride(from: 10, through: 0, by: -2) { st.append(n) }
print("stride = \(st)")
// 「99...1 到底会怎样」不在这个探针里问：它是 r01_desc_range.swift 的崩溃现场，
// 这里只量一件事——区间可以直接 Array(...) 成数组，不用先写 for 循环。
print("Array(1...3) = \(Array(1...3))")

