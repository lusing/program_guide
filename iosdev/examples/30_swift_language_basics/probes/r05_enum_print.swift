import Foundation
enum CarType { case sedan, coupe, hatchback }
enum Shape { case circle(CGFloat); case rect(w: CGFloat, h: CGFloat) }
print(CarType.coupe)
print("\(CarType.coupe)")
print(Shape.circle(3))
print("inter=\(Shape.rect(w: 1, h: 2))")
print(CarType.coupe == CarType.coupe)
