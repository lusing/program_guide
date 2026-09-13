let numbers: [Int] = [1, 2, 3, 4, 5]
let total = numbers.reduce(0, +)

let label = total > 10 ? "large" : "small"
print("total =", total, "label =", label)

for n in 1...5 {
    if n % 2 == 0 {
        print("\(n) is even")
    } else {
        print("\(n) is odd")
    }
}

