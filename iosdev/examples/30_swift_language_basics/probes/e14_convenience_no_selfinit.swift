import Foundation
class Car {
    var colour = "Black"
    init() {}
    convenience init(c: String) {
        colour = c
    }
}
print(Car(c: "Red").colour)
