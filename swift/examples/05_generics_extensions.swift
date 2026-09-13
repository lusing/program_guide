struct Stack<Element> {
    private var storage: [Element] = []

    mutating func push(_ item: Element) {
        storage.append(item)
    }

    mutating func pop() -> Element? {
        storage.popLast()
    }
}

extension Array where Element: Numeric {
    func sum() -> Element {
        reduce(0, +)
    }
}

var stack = Stack<String>()
stack.push("Swift")
stack.push("Guide")
print(stack.pop() ?? "empty")

let arr = [1, 2, 3, 4]
print("sum =", arr.sum())

