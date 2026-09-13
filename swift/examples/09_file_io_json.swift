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

