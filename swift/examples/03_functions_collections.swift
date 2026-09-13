func square(_ x: Int) -> Int {
    x * x
}

let values = [1, 2, 3, 4, 5]
let squared = values.map(square)
let evens = values.filter { $0 % 2 == 0 }
let sum = values.reduce(0, +)

print("squared =", squared)
print("evens =", evens)
print("sum =", sum)

