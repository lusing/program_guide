# 26 · 继承与类型转换

> 对应示例：`examples/26_inheritance_casting/`
> 运行：`swift run Ch26InheritanceCasting`，测试：`swift test --filter Ch26InheritanceCastingTests`

07 章对比了 struct 与 class，说过"class 有继承"。本章把继承讲透：重写方法与
属性、`final` 的封印、指定构造器与便利构造器的委托链；然后讲**类型转换**——
`is` 检测、`as?`/`as!`/`as` 转型，以及装任何值的 `Any`/`AnyObject` 口袋。

## 26.1 继承：语法与基本重写

Swift 的类只允许**单继承**（一个类只能有一个直接父类），语法是
`class 子类: 父类 { }`：

```swift
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

    override init() {
        super.init()          // 先让父类把它的存储属性初始化完
        maxPassengers = 5     // 然后才能改继承来的属性
        numberOfWheels = 4
    }

    override func description() -> String {
        super.description() + "；时速 \(speed) km/h"
    }
}

let car = Car()
print(car.description())  // 4 轮；最多 5 名乘客；时速 0.0 km/h
```

三个关键字：

- **无标记**：子类自动继承父类的所有属性和方法（除了 `private` 的和 `final` 的）。
- **`override`**：子类要**改写**继承来的方法/属性/构造器，必须显式标 `override`。
  忘了标 → 编译错误；父类根本没有这个方法却标了 `override` → 也编译错误。
  编译器强制你"知道自己在重写"。
- **`super`**：在子类体内访问父类版本。`super.description()` 调父类的方法，
  `super.init(...)` 调父类的构造器。重写方法里**可以**调 `super`（扩展功能），
  也**可以**不调（完全替换）——语义你自己定。

## 26.2 重写属性：三种形态

属性也能 `override`，规则比方法微妙：

### 存储属性 → 计算属性

子类可以把父类的存储属性重写为计算属性，在 `get`/`set` 里夹带逻辑：

```swift
class SpeedLimitedCar: Car {
    override var speed: Double {
        get { super.speed }
        set { super.speed = min(newValue, 40.0) }  // 限速 40
    }
}

let limited = SpeedLimitedCar()
limited.speed = 60.0
print(limited.speed)  // 40.0——写入被夹到 40
```

写入 60，读取时得到 40——`set` 里的 `min` 把超速部分截掉了。
注意 `get` 里用 `super.speed` 读的是父类的存储属性，形成"子类包装父类存储"
的结构。

### 给继承来的属性加观察者

父类的存储属性在子类里可以追加 `willSet`/`didSet`（07 章讲过观察者）：

```swift
class AutomaticCar: Car {
    var gear = 1

    override var speed: Double {
        didSet { gear = Int(speed / 10.0) + 1 }  // 速度变 → 挡位跟着变
    }
}

let automatic = AutomaticCar()
automatic.speed = 35.0
print(automatic.gear)  // 4
```

`speed` 是继承来的存储属性，子类不能改它的存储方式，但可以**观察**它的变化。

### 不能做什么

- **计算属性 → 存储属性**：不能把一个计算属性"降级"为存储属性。
  `override var speed: Double = 3.2` 在 `SpeedLimitedCar` 的子类里是编译错误。
- **同时重写 setter 和观察者**：给同一个属性既写 `set` 又写 `didSet` 不行——
  setter 里本来就能观察任何变化，两者职责重叠。
- **给只读属性加观察者**：没有 setter 的属性值不会变，加 `willSet`/`didSet`
  没有意义，编译器拒绝。

## 26.3 `final`：禁止重写

在类、方法、属性、下标前加 `final`，子类就不能再 `override`：

```swift
class FinalCar: Vehicle {
    final var speed: Double = 0.0  // 属性标 final：子类不能再 override speed

    final override func description() -> String {  // 方法标 final
        super.description() + "；时速 \(speed) km/h"
    }
}

// final class NoSubclass {}  // 整个类标 final：不允许有任何子类
```

`final` 的两个用途：一是**设计封印**——这个类/方法就是终点，不允许再被改写；
二是**性能提示**——编译器对 `final` 方法可以做静态派发（直接调用，不走虚函数表），
比动态派发快。Swift 的默认是"可被重写"（相当于 C++ 的 `virtual`），
想封死要显式标 `final`——与 C++/Java 的默认恰好相反。

## 26.4 构造器：指定 vs 便利，继承规则

Swift 的类构造器分两种，这是继承里最绕的部分。

### 指定构造器（designated initializer）

**每个类至少有一个指定构造器**（除非全用默认值且父类有合适的无参 init）。
它是"主力"构造器：负责完成**本类所有存储属性**的初始化，然后向上委托给
父类的指定构造器：

```swift
class Food {
    var name: String

    init(name: String) {   // 指定构造器
        self.name = name
    }
}
```

### 便利构造器（convenience initializer）

加 `convenience` 关键字的构造器。它**不能**直接初始化本类的存储属性，
必须**横向委托**给本类的某个指定构造器（`self.init(...)`）：

```swift
class Food {
    var name: String

    init(name: String) {
        self.name = name
    }

    convenience init() {        // 便利构造器
        self.init(name: "[未命名]")  // 横向委托给指定构造器
    }
}

let namedMeat = Food(name: "培根")
let mysteryMeat = Food()         // name 是 "[未命名]"
```

便利构造器的存在意义：**为指定构造器提供常用参数的默认值**。`Food()` 等价于
`Food(name: "[未命名]")`，但调用方不用记这个魔法字符串。

> 你可能会问：给参数加默认值 `init(name: String = "[未命名]")` 不就行了？
> 对，`Food` 这种简单场景确实不需要便利构造器。但 Swift 规定**指定构造器
> 之间不能互相调用**（`self.init` 只能在 `convenience` 里用），所以当默认
> 值逻辑复杂、或要复用另一个指定构造器的完整流程时，便利构造器是唯一选择。

### 委托规则（记一个"垂直、一个水平"）

- **指定构造器**：先初始化本类属性 → 再 `super.init` **向上**委托父类。
- **便利构造器**：必须 `self.init` **横向**委托本类指定构造器（只能调一次，
  且在引用 `self` 的任何属性/方法**之前**调用）。

### 构造器的继承规则

与 Java/C++ 很不一样：**默认不继承，除非你不写**。

- 子类**一个指定构造器都不实现** → 自动继承父类的**所有**构造器
  （指定 + 便利全继承）。
- 子类**实现了任何指定构造器** → 父类的构造器**全都不继承**。

```swift
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

let oneMysteryItem = RecipeIngredient()              // "[未命名]" × 1
let oneBacon = RecipeIngredient(name: "培根")          // "培根" × 1
let sixBacon = RecipeIngredient(name: "培根", quantity: 6)  // "培根" × 6
```

`RecipeIngredient` 实现了自己的指定构造器，所以父类构造器默认不继承——但
它用 `override convenience init(name:)` **手动重写**了父类的 `init(name:)`，
把它变成一个便利构造器（内部委托给自己的指定构造器）。而 `init()` 是
父类的**便利**构造器，按规则"重写父类指定构造器的子类会自动继承调用它的
便利构造器"——所以 `RecipeIngredient()` 也能用。

### 为什么子类构造器必须调 `super.init`

Java 里子类构造器不显式调 `super(...)` 时，编译器自动插入 `super()`。
Swift **不自动**——你必须手写，且只能调一次。

原因是 Swift 的**两段式初始化**安全机制：在 `super.init` 之前，子类只能
触碰**自己声明的存储属性**（且必须先初始化完）；父类的存储属性此时可能
还没初始化，访问它们是编译错误。`super.init` 是"父类部分已就绪"的分界线：

```swift
class BaseClass {
    var value: Int = 1
    init() { value = 2 }
}
class MyClass: BaseClass {
    init(value: Int) {
        // self.value = value   // ❌ 编译错误：父类属性还没初始化
        super.init()             // ✅ 现在可以访问继承来的属性了
        self.value = value
    }
}
```

编译器实际上在每个指定构造器的开头**自动插入**"初始化本类所有带默认值的
存储属性"的代码，然后才是你写的代码。`super.init` 之后父类的存储属性
也完成了初始化，此时整个对象才是"完全体"。

## 26.5 类型检测与转换：is / as? / as! / as

继承带来多态：一个 `MediaItem` 变量可能指向 `Movie`，也可能指向 `Song`。
**类型检测**（`is`）和**类型转换**（`as` 家族）让你能在运行时区分和处理。

### 准备示例

```swift
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
```

`library` 的静态类型是 `[MediaItem]`——编译器把混合数组向上收窄到
公共父类。这意味着你通过 `library[i]` 只能直接访问 `name`，访问不了
`director` 或 `artist`（它们不是 `MediaItem` 的成员）。要访问，得先**向下转型**。

### `is`：类型检测

`x is T` 返回 `Bool`：x 的运行时类型是 T（或 T 的子类）则为 `true`：

```swift
var movieCount = 0
var songCount = 0
for item in library {
    if item is Movie { movieCount += 1 }
    else if item is Song { songCount += 1 }
}
print("曲库：\(movieCount) 部电影、\(songCount) 首歌")  // 2 部、2 首
```

### `as?`：条件转换（最常用）

`x as? T` 尝试把 x 转成 T：**成功**返回 `T?`（有值），**失败**返回 `nil`。
配 `if let` 是向下转型的标准写法：

```swift
for item in library {
    if let movie = item as? Movie {
        print("电影《\(movie.name)》，导演 \(movie.director)")
    } else if let song = item as? Song {
        print("歌曲《\(song.name)》，歌手 \(song.artist)")
    }
}
```

`as?` 永远**不崩溃**——类型不匹配就静默走 nil 分支。不确定类型时用它。

### `as!`：强制转换

`x as! T` 直接返回 `T`（非可选）。**类型不对就运行期崩溃**——和 06 章的
强制解包 `!` 一个脾气：

```swift
let firstMovie = library[0] as! Movie
print(firstMovie.director)  // Michael Curtiz
```

只有**百分之百确定**类型时才用 `as!`。上面这行如果 `library[0]` 其实是
`Song`，程序当场崩。不确定就用 `as?`。

### `as`：无条件转换（编译期安全）

`as`（不带 `?`/`!`）用于**编译器已经知道不会失败**的转换：

- **向上转型**（子类 → 父类）：总是安全，编译器允许隐式或显式 `as`。
- **桥接**：`String as NSString`、`Array as NSArray` 等 Swift ↔ Objective-C
  类型转换。

```swift
let media = Movie(name: "2001 太空漫游", director: "库布里克") as MediaItem
// 向上转型：Movie → MediaItem，不可能失败
print(media is Movie)  // true——值本体仍是 Movie，只是静态类型擦成父类
```

注意 `media is Movie` 是 `true`——`as` 只改**静态类型**（编译期看到的类型），
不改**动态类型**（运行时实际的类型）。值仍然是那个 `Movie` 实例。

### 四种写法的选用

| 场景 | 写法 | 失败时 |
|---|---|---|
| 只是判断类型 | `is` | —（返回 Bool） |
| 不确定类型，要安全 | `as?` + `if let` | 走 nil 分支 |
| 百分百确定，要非可选值 | `as!` | 崩溃 |
| 子转父、语言桥接 | `as` | 编译期就不可能失败 |

## 26.6 `Any` 与 `AnyObject`：类型擦除口袋

Swift 是强类型语言，但有时候你确实需要"装任何东西的容器"。标准库提供两种
**类型擦除**类型：

- **`AnyObject`**：可以装**任何类实例**（等价 Objective-C 的 `id`）。
  只在桥接老 OC API 时才需要，新代码尽量不用。
- **`Any`**：可以装**几乎任何值**——值类型、引用类型、元组、可选、
  甚至别的 `Any`。（函数类型除外。）

```swift
var things: [Any] = []
things.append(0)           // Int
things.append(0.0)         // Double
things.append(42)          // Int
things.append(3.14159)     // Double
things.append("hello")     // String
things.append((3.0, 5.0))  // 元组
things.append(Movie(name: "捉鬼敢死队", director: "Ivan Reitman"))  // 类实例
```

`[Any]` 数组里每个元素的类型信息被擦掉了——编译器只知道"是个东西"。
取出来要转回原类型才能用，这时 `switch` + `is`/`as` 模式最顺手：

```swift
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
```

`case let x as T` 是模式匹配里的条件转型：匹配**且转型成功**才进入该分支，
`x` 直接绑定为转型后的 `T` 类型。`case is T` 只检测类型，不绑定值。
`case 0 as Int` 是"值匹配 + 类型匹配"的组合：先要求转型成功，再要求等于 0。

> ⚠️ `Any` 是**逃生舱**，不是日常工具。每次从 `Any` 取值都要转型，
> 转错了运行期才崩——编译器帮不上忙。**优先用枚举关联值（08 章）或
> 泛型（10 章）把类型信息留在编译期**。只有真正需要"异质集合"且类型集合
> 在编译期不确定时，才退而求其次用 `Any`。

## 26.7 坑位清单

1. **忘了标 `override`**：编译错误，不是警告。Swift 强制你意识到在重写。
2. **`override` 了父类没有的方法**：也是编译错误。拼写对不上、参数标签
   对不上都会触发——检查方法签名。
3. **构造器里访问 `self` 的属性/方法太早**：在 `self.init(...)`（便利）或
   `super.init(...)`（指定）之前，只能给本类的存储属性赋值，不能读任何属性、
   不能调任何方法（包括 `self.foo`）。编译器强制两段式初始化。
4. **`as!` 转错类型崩溃**：和强制解包一样，崩溃信息是
   `Could not cast value of type 'Movie' to 'Song'`。不确定就用 `as?`。
5. **`Any` 数组里 `0 as Int` 和 `0 as Double` 是两个分支**：字面量 0 默认
   推断为 `Int`，显式 `as Double` 才匹配浮点零。模式匹配里类型是区分键。
6. **协议类型不能 `as!` 强转到具体类型后调方法**：协议本身没有那些成员。
   先 `as?` 转成具体类型，再访问——或者更好的做法是用协议扩展提供默认实现
   （09 章）。
7. **`type(of:)` 返回动态类型**：`let m: MediaItem = Movie(...) as MediaItem;
   type(of: m)` 是 `Movie.self`，不是 `MediaItem.self`。要判断"是不是某个
   子类"用 `is`，别用 `type(of:) ==`。

上一章：[25 · 位运算、溢出与运算符重载](25-advanced-operators.md) ｜ 返回：[README](../README.md)
