import Foundation

// 书 9.3 的枚举写法原样搬过来：case 名首字母大写（case Sedan / Coupe / Hatchback）。
// Swift 6.0.3 对这种命名有没有意见？编一遍看日志。
enum CarType {
    case Sedan
    case Coupe
    case Hatchback
}
let t: CarType = .Coupe
switch t {
case .Sedan: print("普通轿车")
case .Coupe: print("双门轿车")
case .Hatchback: print("两厢轿车")
}
