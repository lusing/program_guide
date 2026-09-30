import XCTest
@testable import WeatherKit

/// 这个文件**不参与主线**：`swift build` 默认连 test target 都不编，
/// 要 `--build-tests` 才发射它（这一格由探针 s11 现跑现抄，它同时给出 `swift test` 的原文）。
/// 它留在包里的理由是「一个包里能放哪些源码」这件事只有真放一个测试 target 才量得出来；
/// 而 `@testable import` 让 `internalTag()` 在这里可见、在主线里不可见 ——
/// §7 那格的两半就在同一个包的两个目录里（@testable 不是权限关键字：e04）。
final class ForecastTests: XCTestCase {
    func testFahrenheitConversion() {
        XCTAssertEqual(fahrenheit(0), 32)
        XCTAssertEqual(internalTag(), "internal-tag")
    }
}
