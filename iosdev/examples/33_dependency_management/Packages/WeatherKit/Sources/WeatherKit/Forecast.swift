import CLIBrain
import ClimateCore
import Foundation

/// 包里对外说好的身份。主线 §2 用它证明「绑的是这个包而不是 SDK 里那个同名框架」，
/// §4 再用它区分「product 名 / target 名 / module 名」：`import WeatherKit` 拿到的
/// 那个词是 **module 名**，而这三者在 Package.swift 里是三行不同的声明（拆开的现场在 s05）。
public let weatherKitID = "WeatherKit/1.0"

public struct Reading: Equatable {
    public let city: String
    public let celsius: Double

    public init(city: String, celsius: Double) {
        self.city = city
        self.celsius = celsius
    }
}

public enum ForecastError: Error, Equatable {
    case unknownCity(String)
}

/// 换算走 ClimateCore（传递依赖的那一层），露点走 CLIBrain（C 的那一层）。
/// 一个函数同时踩到两种依赖，§5/§8 才有东西可量。
public func report(for reading: Reading) -> String {
    let fahrenheit = TemperatureUnit.fahrenheit.convert(reading.celsius)
    let dewPoint = cliDewPoint(reading.celsius, 60.0)
    return "\(reading.city)：\(String(format: "%.1f", reading.celsius))°C / "
        + "\(String(format: "%.1f", fahrenheit))°F / 露点 \(String(format: "%.1f", dewPoint))°C"
}

/// `internal`：包外面写不出来，包内两个文件互相能用（§7 的两半）。
internal func internalTag() -> String { "internal-tag" }

public func tagLine() -> String { "\(internalTag())@\(climateCoreID)" }

public func fahrenheit(_ celsius: Double) -> Double {
    TemperatureUnit.fahrenheit.convert(celsius)
}

/// 公开 API 的**签名里带着别的模块的类型**：返回的是 ClimateCore 的 `TemperatureUnit`。
/// 这一行的用处全在主线之外 —— 探针 e06 量的是「只 `import WeatherKit`、不 import
/// ClimateCore，这个类型还能不能用」：能取值、能调方法，但**写不出类型的名字**。
/// 书 10.8 在同一个文件顶部写了四行 import（UIKit / CoreLocation / Alamofire / SwiftyJSON），
/// 而它要读的 Alamofire 文档只讲 Alamofire —— 「这个类型属于另一个模块」这件事
/// 书里没提，只在少写一行时报错。本章的两个半边就在这一行签名上：能取值，写不出类型名。
public func preferredUnit() -> TemperatureUnit { .fahrenheit }

public func brainVersion() -> String { String(cString: cliBrainVersion()) }
