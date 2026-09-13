# Swift 编程指南（Windows + swiftc）

本指南面向 Windows 环境，配套示例全部以独立 `.swift` 文件管理，并可通过 `build.ps1` 统一编译验证。  
示例目录：`examples/`，构建入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [第一个 Swift 程序](#第一个-swift-程序)
3. [类型与流程控制](#类型与流程控制)
4. [函数与集合](#函数与集合)
5. [结构体、枚举与协议](#结构体枚举与协议)
6. [泛型与扩展](#泛型与扩展)
7. [错误处理](#错误处理)
8. [Optional 与 Result](#optional-与-result)
9. [并发（async/await）](#并发asyncawait)
10. [文件与 JSON](#文件与-json)
11. [测试思维与命令行参数](#测试思维与命令行参数)
12. [统一编译验证](#统一编译验证)

---

## 环境准备

- Swift 根目录：`G:\scoop\apps\swift\current`
- 编译器：`G:\scoop\apps\swift\current\Toolchains\usr\bin\swiftc.exe`
- 教程目录：`G:\code\guide\swift`

可先验证编译器是否可用：

```powershell
G:\scoop\apps\swift\current\Toolchains\usr\bin\swiftc.exe --version
```

---

## 第一个 Swift 程序

源码：`examples/01_hello.swift`

```swift
print("Hello, Swift!")
```

要点：
- Swift 支持顶层语句，入门示例可直接 `print`

---

## 类型与流程控制

源码：`examples/02_types_control.swift`

```swift
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
```

要点：
- `let` 不可变，`var` 可变
- `1...5` 是闭区间
- 三元表达式可用于简单分支

---

## 函数与集合

源码：`examples/03_functions_collections.swift`

```swift
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
```

要点：
- 函数可以作为值传递
- `map/filter/reduce` 是集合处理核心能力

---

## 结构体、枚举与协议

源码：`examples/04_struct_enum_protocol.swift`

```swift
protocol Describable {
    func describe() -> String
}

struct Point: Describable {
    var x: Double
    var y: Double

    func describe() -> String {
        "Point(x: \(x), y: \(y))"
    }
}

enum TaskState: Describable {
    case todo
    case doing(progress: Int)
    case done

    func describe() -> String {
        switch self {
        case .todo:
            return "todo"
        case let .doing(progress):
            return "doing \(progress)%"
        case .done:
            return "done"
        }
    }
}

let p = Point(x: 3.5, y: 8.2)
let s: TaskState = .doing(progress: 60)
print(p.describe())
print(s.describe())
```

要点：
- 结构体是值类型
- 枚举可带关联值
- 协议用于抽象行为

---

## 泛型与扩展

源码：`examples/05_generics_extensions.swift`

```swift
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
```

要点：
- 泛型让容器复用类型逻辑
- `where` 子句约束扩展适用范围

---

## 错误处理

源码：`examples/06_error_handling.swift`

```swift
enum ParseError: Error {
    case emptyInput
    case invalidNumber(String)
    case notPositive(Int)
}

func parsePositiveInt(_ text: String) throws -> Int {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty {
        throw ParseError.emptyInput
    }
    guard let value = Int(t) else {
        throw ParseError.invalidNumber(t)
    }
    if value <= 0 {
        throw ParseError.notPositive(value)
    }
    return value
}

for input in ["42", "  ", "-3", "abc"] {
    do {
        let v = try parsePositiveInt(input)
        print("ok:", v)
    } catch {
        print("error for '\(input)':", error)
    }
}
```

要点：
- 用 `throws` 明确失败路径
- `do/try/catch` 处理可恢复错误

---

## Optional 与 Result

源码：`examples/07_optionals_result.swift`

```swift
enum MathError: Error {
    case divideByZero
}

func divide(_ a: Double, _ b: Double) -> Result<Double, MathError> {
    guard b != 0 else { return .failure(.divideByZero) }
    return .success(a / b)
}

let maybeName: String? = "swift"
let upper = maybeName?.uppercased() ?? "UNKNOWN"
print("upper =", upper)

switch divide(10, 2) {
case let .success(value):
    print("10 / 2 =", value)
case let .failure(err):
    print("failed:", err)
}
```

要点：
- Optional 处理“值可能缺失”
- Result 把成功/失败都表达为值

---

## 并发（async/await）

源码：`examples/08_concurrency_asyncawait.swift`

```swift
import Foundation

func delayedValue() async -> Int {
    try? await Task.sleep(nanoseconds: 150_000_000)
    return 2026
}

let semaphore = DispatchSemaphore(value: 0)

Task {
    async let a = delayedValue()
    async let b = delayedValue()
    let sum = await a + b
    print("sum =", sum)
    semaphore.signal()
}

semaphore.wait()
```

要点：
- `async let` 可并发等待多个异步任务
- `Task.sleep` 常用于演示异步流程

---

## 文件与 JSON

源码：`examples/09_file_io_json.swift`

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
}

let user = User(id: 1, name: "Alice")
let tempDir = FileManager.default.temporaryDirectory
let fileURL = tempDir.appendingPathComponent("swift_user.json")

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(user)
try data.write(to: fileURL)

let loaded = try Data(contentsOf: fileURL)
let decoded = try JSONDecoder().decode(User.self, from: loaded)
print("file =", fileURL.path)
print("decoded =", decoded.name, decoded.id)
```

要点：
- `Codable` 简化 JSON 编解码
- `FileManager.default.temporaryDirectory` 适合临时示例

---

## 测试思维与命令行参数

源码：`examples/10_testing_cli.swift`

```swift
func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

func runChecks() {
    precondition(add(1, 2) == 3, "add(1,2) should be 3")
    precondition(add(-1, 1) == 0, "add(-1,1) should be 0")
    print("checks passed")
}

runChecks()

let args = CommandLine.arguments
if args.count > 1 {
    print("extra args:", Array(args.dropFirst()))
} else {
    print("no extra args")
}
```

要点：
- `precondition` 可用于基础断言
- `CommandLine.arguments` 读取命令行参数

---

## 统一编译验证

在本目录执行：

```powershell
cd G:\code\guide\swift
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 09_file_io_json.swift
```

清理：

```powershell
.\build.ps1 -Clean
```

建议每次新增示例后都运行一次 `-All`，确保教程中的所有示例持续可编译。
