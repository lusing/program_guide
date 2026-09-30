import Foundation
enum E: Error { case bad }
func risky() throws -> Int { throw E.bad }
print("before")
let v = try! risky()
print("after \(v)")
