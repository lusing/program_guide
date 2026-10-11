// 26 · 继承与类型转换——override/super/final、指定与便利构造器、
//    is / as? / as! / as、Any 与 AnyObject、switch 模式匹配转型

import Foundation

// ═══ 26.1 继承语法：子类 : 父类（Swift 类只允许单继承）
class Vehicle {
    var numberOfWheels: Int
    var maxPassengers: Int

    init() {
        numberOfWheels = 0
        maxPassengers = 1
    }

    func description() -> String {
        "\(numberOfWheels) 轮；最多 \(maxPassengers) 名乘客"
    }
}

class Car: Vehicle {
    var speed: Double = 0.0

    // 子类构造器必须调用父类某个构造器（且只能调一次）
    override init() {
        super.init()          // 先让父类把它的存储属性初始化完
        maxPassengers = 5     // 然后才能改继承来的属性
        numberOfWheels = 4
    }

    // override 重写方法；super.xxx 调父类版本（可加可不加，语义自选）
    override func description() -> String {
        super.description() + "；时速 \(speed) km/h"
    }
}

let someVehicle = Vehicle()
print("Vehicle: \(someVehicle.description())")
let car = Car()
print("Car: \(car.description())")
precondition(car.description() == "4 轮；最多 5 名乘客；时速 0.0 km/h")

// ═══ 26.2 重写属性：存储 → 计算可以，反过来不行
class SpeedLimitedCar: Car {
    // 把父类的存储属性 speed 重写成计算属性：写入时夹到 40
    override var speed: Double {
        get { super.speed }
        set { super.speed = min(newValue, 40.0) }
    }
}

let limited = SpeedLimitedCar()
limited.speed = 60.0
print("SpeedLimitedCar 写入 60，实际 = \(limited.speed)")
precondition(limited.speed == 40.0)

// 重写属性观察器：给继承来的属性追加 didSet
class AutomaticCar: Car {
    var gear = 1

    override var speed: Double {
        didSet { gear = Int(speed / 10.0) + 1 }
    }

    override func description() -> String {
        super.description() + "；挡位 \(gear)"
    }
}

let automatic = AutomaticCar()
automatic.speed = 35.0
print("AutomaticCar: \(automatic.description())")
precondition(automatic.gear == 4)

// class NewSpeedLimitedCar: SpeedLimitedCar {
//     override var speed: Double = 3.2   // ❌ 计算属性不能被重写成存储属性
// }

// ═══ 26.3 final：禁止重写（类、方法、属性、下标都能标）
class FinalCar: Vehicle {
    final var speed: Double = 0.0       // 属性标 final：子类不能再 override

    final override func description() -> String {  // 方法标 final
        super.description() + "；时速 \(speed) km/h"
    }
}
// final class NoSubclass {}  // 整个类标 final：不允许有任何子类

// ═══ 26.4 指定构造器 vs 便利构造器；构造器的继承规则
class Food {
    var name: String

    // 指定构造器（designated）：负责完成本类所有存储属性的初始化
    init(name: String) {
        self.name = name
    }

    // 便利构造器（convenience）：必须横向调用本类的指定构造器
    convenience init() {
        self.init(name: "[未命名]")
    }
}

let namedMeat = Food(name: "培根")
let mysteryMeat = Food()
print("指定构造器：\(namedMeat.name)，便利构造器：\(mysteryMeat.name)")
precondition(mysteryMeat.name == "[未命名]")

// 规则：子类一旦实现了自己的指定构造器，就不再自动继承父类的构造器；
// 一个指定构造器都不写，则继承父类全部构造器（含便利构造器）。
class RecipeIngredient: Food {
    var quantity: Int

    init(name: String, quantity: Int) {
        self.quantity = quantity   // 先初始化本类属性
        super.init(name: name)     // 再向上委托
    }

    // 重写父类的指定构造器为便利构造器（override + convenience 同时标）
    override convenience init(name: String) {
        self.init(name: name, quantity: 1)
    }
}

let oneMysteryItem = RecipeIngredient()
let oneBacon = RecipeIngredient(name: "培根")
let sixBacon = RecipeIngredient(name: "培根", quantity: 6)
print("oneMysteryItem=\(oneMysteryItem.name)×\(oneMysteryItem.quantity) "
    + "oneBacon=\(oneBacon.name)×\(oneBacon.quantity) "
    + "sixBacon=\(sixBacon.name)×\(sixBacon.quantity)")
precondition(oneMysteryItem.quantity == 1 && sixBacon.quantity == 6)

// ═══ 26.5 类型检测 is 与转换 as? / as! / as
class MediaItem {
    var name: String
    init(name: String) { self.name = name }
}
class Movie: MediaItem {
    var director: String
    init(name: String, director: String) {
        self.director = director
        super.init(name: name)
    }
}
class Song: MediaItem {
    var artist: String
    init(name: String, artist: String) {
        self.artist = artist
        super.init(name: name)
    }
}

// 数组字面量混合 Movie 与 Song → 元素类型被推断为共同父类 MediaItem
let library: [MediaItem] = [
    Movie(name: "卡萨布兰卡", director: "Michael Curtiz"),
    Song(name: "Blue Suede Shoes", artist: "Elvis Presley"),
    Movie(name: "公民凯恩", director: "Orson Welles"),
    Song(name: "永不放弃你", artist: "Rick Astley"),
]

// is：类型检测（返回 Bool），不改类型
var movieCount = 0
var songCount = 0
for item in library where item is Movie { movieCount += 1 }
for item in library where item is Song { songCount += 1 }
print("曲库：\(movieCount) 部电影、\(songCount) 首歌")
precondition(movieCount == 2 && songCount == 2)

// as? 条件转换：失败返回 nil，配 if let 用（最常用、最安全的向下转型）
for item in library {
    if let movie = item as? Movie {
        print("电影《\(movie.name)》，导演 \(movie.director)")
    } else if let song = item as? Song {
        print("歌曲《\(song.name)》，歌手 \(song.artist)")
    }
}

// as! 强制转换：确定类型时少写一层 if let；错了就运行期崩溃
let firstMovie = library[0] as! Movie
print("as! 强转第一部：\(firstMovie.director)")
precondition(firstMovie.director == "Michael Curtiz")

// as（无条件）：编译器已知的向上转型（子 → 父）或桥接，不会失败
let media = Movie(name: "2001 太空漫游", director: "库布里克") as MediaItem
print("向上 as 转父类：静态类型 MediaItem，动态类型 \(type(of: media))")
precondition(media is Movie)  // 值本体仍是 Movie，只是静态类型被擦成父类

// 转换失败演示（as? 返回 nil，不会崩）
let notASong = library[0] as? Song
print("Movie as? Song = \(String(describing: notASong))（nil）")
precondition(notASong == nil)

// ═══ 26.6 Any 与 AnyObject：类型擦除的"万能口袋"
// AnyObject：任何类实例（等价 Objective-C 的 id，桥接老 API 才用）
// Any：几乎任何值（值类型、引用类型、元组、可选、函数类型除外）
var things: [Any] = []
things.append(0)
things.append(0.0)
things.append(42)
things.append(3.14159)
things.append("hello")
things.append((3.0, 5.0))
things.append(Movie(name: "捉鬼敢死队", director: "Ivan Reitman"))

// switch + is / as 模式：在 case 里直接绑定转型后的值（此处 as 不会失败）
for thing in things {
    switch thing {
    case 0 as Int:
        print("整数零")
    case 0 as Double:
        print("浮点零")
    case let someInt as Int:
        print("整数 \(someInt)")
    case let someDouble as Double where someDouble > 0:
        print("正浮点 \(someDouble)")
    case is Double:
        print("其它浮点（不想打印）")
    case let someString as String:
        print("字符串 \"\(someString)\"")
    case let (x, y) as (Double, Double):
        print("元组 (\(x), \(y))")
    case let movie as Movie:
        print("电影《\(movie.name)》")
    default:
        print("其它")
    }
}

// ⚠️ Any 口袋取出来的值要转回原类型才能用——能不用就不用：
// 优先用枚举关联值（08 章）或泛型（10 章）把类型留在编译期。

print("==== 26 结束 ====")
