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

