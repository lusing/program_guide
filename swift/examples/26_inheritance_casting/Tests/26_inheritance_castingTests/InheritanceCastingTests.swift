// 26_inheritance_casting 的 swift-testing 测试
import Testing

@testable import Ch26InheritanceCasting

@Test func 继承与重写() {
    let v = Vehicle()
    #expect(v.description() == "0 轮；最多 1 名乘客")

    let c = Car()
    #expect(c.numberOfWheels == 4)
    #expect(c.maxPassengers == 5)
    #expect(c.description() == "4 轮；最多 5 名乘客；时速 0.0 km/h")
}

@Test func 重写属性为计算属性() {
    let limited = SpeedLimitedCar()
    limited.speed = 60.0
    #expect(limited.speed == 40.0)
}

@Test func 重写属性观察器() {
    let auto = AutomaticCar()
    auto.speed = 35.0
    #expect(auto.gear == 4)
    auto.speed = 10.0
    #expect(auto.gear == 2)
}

@Test func 便利构造器默认参数() {
    let f = Food()
    #expect(f.name == "[未命名]")
    let named = Food(name: "培根")
    #expect(named.name == "培根")
}

@Test func 构造器继承与重写() {
    let one = RecipeIngredient()
    #expect(one.name == "[未命名]" && one.quantity == 1)

    let bacon = RecipeIngredient(name: "培根")
    #expect(bacon.quantity == 1)

    let six = RecipeIngredient(name: "培根", quantity: 6)
    #expect(six.quantity == 6)
}

@Test func 类型检测与条件转换() {
    let library: [MediaItem] = [
        Movie(name: "卡萨布兰卡", director: "Michael Curtiz"),
        Song(name: "Blue Suede Shoes", artist: "Elvis Presley"),
        Movie(name: "公民凯恩", director: "Orson Welles"),
        Song(name: "永不放弃你", artist: "Rick Astley"),
    ]

    #expect(library[0] is Movie)
    #expect(!(library[0] is Song))
    #expect(library[1] is Song)

    let m = library[0] as? Movie
    #expect(m?.director == "Michael Curtiz")

    let s = library[1] as? Song
    #expect(s?.artist == "Elvis Presley")

    // 转错类型 → nil，不崩
    #expect(library[0] as? Song == nil)

    // as! 强转：类型正确时直接拿到非可选值
    let forced: Movie = library[2] as! Movie
    #expect(forced.name == "公民凯恩")

    // 向上 as：子 → 父，编译期安全；动态类型仍是 Movie
    let media: MediaItem = Movie(name: "X", director: "Y") as MediaItem
    #expect(media is Movie)
}

@Test func Any数组与switch模式转型() {
    var things: [Any] = []
    things.append(0)
    things.append(0.0)
    things.append(42)
    things.append(3.14159)
    things.append("hello")
    things.append((3.0, 5.0))
    things.append(Movie(name: "捉鬼敢死队", director: "Ivan Reitman"))

    var sawIntZero = false
    var sawDoubleZero = false
    var sawInt = false
    var sawPosDouble = false
    var sawOtherDouble = false
    var sawString = false
    var sawTuple = false
    var sawMovie = false

    for thing in things {
        switch thing {
        case 0 as Int:
            sawIntZero = true
        case 0 as Double:
            sawDoubleZero = true
        case let someInt as Int:
            _ = someInt
            sawInt = true
        case let someDouble as Double where someDouble > 0:
            _ = someDouble
            sawPosDouble = true
        case is Double:
            sawOtherDouble = true
        case let someString as String:
            _ = someString
            sawString = true
        case let (x, y) as (Double, Double):
            _ = x
            _ = y
            sawTuple = true
        case let movie as Movie:
            _ = movie
            sawMovie = true
        default:
            break
        }
    }

    #expect(sawIntZero)
    #expect(sawDoubleZero)
    #expect(sawInt)
    #expect(sawPosDouble)
    #expect(!sawOtherDouble)  // 3.14159 > 0，走正浮点分支
    #expect(sawString)
    #expect(sawTuple)
    #expect(sawMovie)
}
