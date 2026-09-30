import Foundation
class Car {
    var colour = "Black"
    init(customerChosenColour: String) { colour = customerChosenColour }
}
let myCar = Car()
print(myCar.colour)
