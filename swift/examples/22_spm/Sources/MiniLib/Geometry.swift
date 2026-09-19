// MiniLib：22 章演示库——真实项目里"逻辑进库、壳做 CLI"的分工
import Foundation

public struct Rect: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public var area: Double { width * height }
    public var perimeter: Double { 2 * (width + height) }
    public var isSquare: Bool { width == height }
}

public enum GeometryError: Error, Equatable {
    case negativeDimension(name: String)
}

/// 带校验的工厂（12 章：可恢复错误走 throws）
public func makeRect(width: Double, height: Double) throws -> Rect {
    guard width >= 0 else { throw GeometryError.negativeDimension(name: "width") }
    guard height >= 0 else { throw GeometryError.negativeDimension(name: "height") }
    return Rect(width: width, height: height)
}

public func totalArea(_ rects: [Rect]) -> Double {
    rects.reduce(0) { $0 + $1.area }
}
