import Foundation

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

