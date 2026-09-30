import Foundation
enum CarType { case sedan, coupe, hatchback }
let t = CarType.coupe
switch t {
case .sedan: print("s")
}
