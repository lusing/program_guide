import Foundation

/// 包里对外只有 `public` 的那几个名字。`internal` 的那个换算函数在本文件里能用、
/// 主线里 import 不到 —— 这就是 §6 要量的那一格（默认访问级别在「跨模块」这一刻才咬人，
/// 三个 internal 名字逐条写出来的原文见探针 e03）。
public enum TemperatureUnit: String, CaseIterable {
    case celsius
    case fahrenheit

    public func convert(_ celsiusValue: Double) -> Double {
        switch self {
        case .celsius: return celsiusValue
        case .fahrenheit: return celsiusValue * 9 / 5 + 32
        }
    }
}

/// `internal`（写不写都一样，默认就是它）：主线看不见。
func hiddenOffset() -> Double { 32 }

/// 出厂身份。两个包各有一份，主线用它来确认「import 到的到底是哪一个模块」。
public let climateCoreID = "ClimateCore/1.0"

/// 一个只有包内可见的类型：主线连名字都写不出来。
struct InternalReading {
    var celsius: Double
}

public func averageCelsius(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    return values.reduce(0, +) / Double(values.count)
}
