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

