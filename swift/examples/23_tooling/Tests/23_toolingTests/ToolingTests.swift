// 23_tooling 的 swift-testing 测试
import Testing
import WinSDK

@testable import Ch23Tooling

@Test func ucrt数学() {
    #expect(cSqrt(4) == 2)
    #expect(cSqrt(0) == 0)
    #expect(abs(cSqrt(2) - 1.4142135623730951) < 1e-15)
    #expect(abs(cSqrt(3) - 1.7320508075688772) < 1e-15)
}

@Test func 固定点确定() {
    let p = fixedPointFromC()
    #expect(abs(p.x - 1.4142135623730951) < 1e-15)
    #expect(abs(p.y - 1.7320508075688772) < 1e-15)
}

@Test func 系统目录非空() {
    let dir = systemDirectory()
    #expect(dir.count > 1)
    #expect(!dir.contains("\0"))  // C 字符串尾巴已被 String 转换吃掉
}

@Test func c类型映射() {
    let sizes = cTypeSizes()
    #expect(sizes["CChar(Int8)"] == 1)
    #expect(sizes["CInt(Int32)"] == 4)
    #expect(sizes["CLongLong(Int64)"] == 8)
    #expect(sizes["CFloat(Float32)"] == 4)
    #expect(sizes["WCHAR(UTF16)"] == 2)
}

@Test func winSDK常量() {
    #expect(MAX_PATH == 260)  // WinSDK 的宏常量直接可用
}
