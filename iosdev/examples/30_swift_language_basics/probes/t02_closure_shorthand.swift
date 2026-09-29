import Foundation
func calculator(n1: Int, n2: Int, operation: (Int, Int) -> Int) -> Int { return operation(n1, n2) }
func add(num1: Int, num2: Int) -> Int { return num1 + num2 }
func multiply(num1: Int, num2: Int) -> Int { return num1 * num2 }
print(calculator(n1: 3, n2: 6, operation: add))
print(calculator(n1: 4, n2: 7, operation: multiply))
print(calculator(n1: 4, n2: 7, operation: { (num1: Int, num2: Int) -> Int in return num1 * num2 }))
print(calculator(n1: 4, n2: 7, operation: { (num1: Int, num2: Int) -> Int in num1 * num2 }))
print(calculator(n1: 4, n2: 7, operation: { (num1, num2) in num1 * num2 }))
print(calculator(n1: 4, n2: 7, operation: { num1, num2 in num1 * num2 }))
print(calculator(n1: 4, n2: 7, operation: { $0 * $1 }))
print(calculator(n1: 4, n2: 7) { $0 * $1 })
print(calculator(n1: 4, n2: 7) { a, b in a - b })
let array = [2, 5, 3, 7, 23, 54]
func addOne(n1: Int) -> Int { return n1 + 1 }
print(array.map(addOne))
print(array.map { (n1) in n1 + 1 })
print(array.map { $0 + 1 })
print(array.filter { $0 > 5 }.map { $0 * 2 }.reduce(0, +))
print(array.sorted { $0 > $1 })
print(array.contains(where: { $0 == 7 }))
let evens = array.compactMap { $0 % 2 == 0 ? $0 : nil }
print(evens)
print(array.reduce(into: "") { acc, el in acc += "<\(el)>" })
