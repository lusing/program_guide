import Foundation
class Car { func drive() { print("开动") } }
class SelfDrivingCar: Car { func drive() { print("自动") } }
print(SelfDrivingCar())
